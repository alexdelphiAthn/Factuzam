{******************************************************************************}
{                                                                              }
{  Módulo:       UColaFotosNube                                                }
{    Tipo:       Librería (FMX, Android)                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de subida por lotes de fotos al webservice de Factuzam              }
{    (API v1 /fotos/subir.php). Cada foto se identifica por código de         }
{    artículo y color; si hay más de una foto del mismo artículo+color se les  }
{    asigna un índice correlativo. La subida se hace en un hilo de fondo y va  }
{    notificando el estado de cada elemento a la interfaz. Mismo contrato      }
{    multipart que el cliente VCL existente (UFotoUploader).                   }
{******************************************************************************}
unit UColaFotosNube;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Hash,
  System.Generics.Collections, System.Net.HttpClient, System.Net.Mime,
  System.Net.URLClient;

type
  // Estado de cada foto dentro de la cola.
  TEstadoSubida = (esPendiente, esSubiendo, esOk, esError);

  // Un elemento de la cola: la foto local, su identificación de negocio
  // (artículo + color) y el resultado del servidor.
  TFotoItem = class
  public
    Archivo: string;
    Articulo: string;
    Color: string;
    Indice: string;
    Hash: string;
    Mensaje: string;
    Estado: TEstadoSubida;
  end;

  // Callbacks de progreso (por foto) y de fin de lote. Se invocan ya en
  // el hilo principal, listos para tocar la interfaz.
  TProgresoFotoProc = reference to procedure(const AItem: TFotoItem);
  TFinLoteProc = reference to procedure(const AOk, AError: Integer);

  // Cola de fotos pendientes de subir al webservice.
  TColaFotos = class
  private
    FItems: TObjectList<TFotoItem>;
    FUrl: string;
    FApiKey: string;
    FCarpetaCliente: string;
    function SubirUno(const AItem: TFotoItem): Boolean;
    // Índice correlativo (1..n) de la foto dentro de su grupo
    // artículo+color. Se envía siempre porque el webservice exige
    // articulo+color+indice no vacíos para nombrar el fichero; cuando
    // sólo hay una foto del grupo el índice es 1.
    function CalcularIndice(const AItem: TFotoItem): string;
    procedure NotificarItem(const AProgreso: TProgresoFotoProc;
      const AItem: TFotoItem);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AArchivo, AArticulo, AColor: string): TFotoItem;
    procedure Limpiar;
    function PendientesCount: Integer;
    // Sube en segundo plano todas las fotos no subidas. Notifica por
    // AProgreso cada cambio de estado y AFin al terminar el lote.
    procedure SubirTodasAsync(AProgreso: TProgresoFotoProc;
      AFin: TFinLoteProc);
    property Items: TObjectList<TFotoItem> read FItems;
    property Url: string read FUrl write FUrl;
    property ApiKey: string read FApiKey write FApiKey;
    property CarpetaCliente: string read FCarpetaCliente
      write FCarpetaCliente;
  end;

// Texto legible para un estado (para pintarlo en la lista).
function EstadoTexto(const AEstado: TEstadoSubida): string;

implementation

function EstadoTexto(const AEstado: TEstadoSubida): string;
begin
  case AEstado of
    esPendiente: Result := 'Pendiente';
    esSubiendo:  Result := 'Subiendo...';
    esOk:        Result := 'Subida OK';
    esError:     Result := 'Error';
  else
    Result := '';
  end;
end;

{ TColaFotos }

constructor TColaFotos.Create;
begin
  inherited Create;
  FItems := TObjectList<TFotoItem>.Create(True);
end;

destructor TColaFotos.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TColaFotos.Add(const AArchivo, AArticulo, AColor: string): TFotoItem;
begin
  Result := TFotoItem.Create;
  Result.Archivo := AArchivo;
  Result.Articulo := AArticulo;
  Result.Color := AColor;
  Result.Estado := esPendiente;
  FItems.Add(Result);
end;

procedure TColaFotos.Limpiar;
begin
  FItems.Clear;
end;

function TColaFotos.PendientesCount: Integer;
var
  Item: TFotoItem;
begin
  Result := 0;
  for Item in FItems do
    if Item.Estado <> esOk then
      Inc(Result);
end;

function TColaFotos.CalcularIndice(const AItem: TFotoItem): string;
var
  Otro: TFotoItem;
  Ordinal: Integer;
  Encontrado: Boolean;
begin
  // Posición (1..n) de esta foto dentro de su grupo artículo+color, en
  // el orden de la cola. Siempre >= 1: el webservice nombra el fichero
  // como ARTICULO_COLOR_INDICE y exige el índice no vacío.
  Ordinal := 0;
  Encontrado := False;
  for Otro in FItems do
  begin
    if (not Encontrado) and
       SameText(Otro.Articulo, AItem.Articulo) and
       SameText(Otro.Color, AItem.Color) then
    begin
      Inc(Ordinal);
      if Otro = AItem then
        Encontrado := True;
    end;
  end;
  Result := IntToStr(Ordinal);
end;

function TColaFotos.SubirUno(const AItem: TFotoItem): Boolean;
var
  HTTP: THTTPClient;
  Form: TMultipartFormData;
  Res: IHTTPResponse;
  Json: TJSONValue;
  Obj: TJSONObject;
  Datos: TJSONObject;
  ErrorObj: TJSONObject;
  Valor: TJSONValue;
  OkApi: Boolean;
  Cuerpo: string;
begin
  Result := False;
  AItem.Indice := CalcularIndice(AItem);
  HTTP := THTTPClient.Create;
  try
    Form := TMultipartFormData.Create;
    try
      // Campos del contrato moderno POST /api/v1/fotos/subir.php.
      Form.AddField('articulo', AItem.Articulo);
      Form.AddField('color', AItem.Color);
      Form.AddField('indice', AItem.Indice);
      Form.AddField('referencia', FCarpetaCliente);
      Form.AddField('nombre_original', ExtractFileName(AItem.Archivo));
      // SHA1 del fichero local para verificación extremo a extremo.
      Form.AddField('osha1',
        LowerCase(THashSHA1.GetHashStringFromFile(AItem.Archivo)));
      Form.AddFile('imagen', AItem.Archivo);
      HTTP.CustomHeaders['Authorization'] := 'Bearer ' + FApiKey;
      Res := HTTP.Post(FUrl, Form, nil);
      Cuerpo := Res.ContentAsString;
      // API v1: {ok, datos:{sha256_real,...}, error:{mensaje,...}}.
      // Se analiza tambien el cuerpo de error para mostrar el mensaje real.
      OkApi := False;
      AItem.Hash := '';
      AItem.Mensaje := Cuerpo;
      Json := TJSONObject.ParseJSONValue(Cuerpo);
      try
        if Json is TJSONObject then
        begin
          Obj := TJSONObject(Json);
          Valor := Obj.GetValue('ok');
          if Valor <> nil then
            OkApi := SameText(Valor.Value, 'true');
          if Obj.GetValue('datos') is TJSONObject then
          begin
            Datos := TJSONObject(Obj.GetValue('datos'));
            Valor := Datos.GetValue('sha256_real');
            if Valor <> nil then
              AItem.Hash := Valor.Value;
          end;
          if Obj.GetValue('error') is TJSONObject then
          begin
            ErrorObj := TJSONObject(Obj.GetValue('error'));
            Valor := ErrorObj.GetValue('mensaje');
            if Valor <> nil then
              AItem.Mensaje := Valor.Value;
          end;
        end;
      finally
        Json.Free;
      end;
      if (Res.StatusCode >= 200) and (Res.StatusCode < 300) and OkApi then
      begin
        AItem.Estado := esOk;
        Result := True;
      end
      else
      begin
        AItem.Estado := esError;
        // Si el servidor no dio un mensaje util, dejamos el codigo HTTP.
        if AItem.Mensaje = Cuerpo then
          AItem.Mensaje := Format('HTTP %d: %s', [Res.StatusCode, Cuerpo]);
      end;
    finally
      Form.Free;
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TColaFotos.NotificarItem(const AProgreso: TProgresoFotoProc;
  const AItem: TFotoItem);
begin
  // AItem es parámetro para capturarlo por valor en cada llamada y evitar
  // el problema de captura de la variable de bucle en los anónimos.
  if Assigned(AProgreso) then
    TThread.Queue(nil,
      procedure
      begin
        AProgreso(AItem);
      end);
end;

procedure TColaFotos.SubirTodasAsync(AProgreso: TProgresoFotoProc;
  AFin: TFinLoteProc);
begin
  // Hilo de fondo: la subida no debe bloquear la interfaz.
  TThread.CreateAnonymousThread(
    procedure
    var
      Item: TFotoItem;
      TotalOk: Integer;
      TotalError: Integer;
    begin
      TotalOk := 0;
      TotalError := 0;
      for Item in FItems do
      begin
        // Saltamos las que ya están subidas correctamente.
        if Item.Estado <> esOk then
        begin
          Item.Estado := esSubiendo;
          NotificarItem(AProgreso, Item);
          if SubirUno(Item) then
            Inc(TotalOk)
          else
            Inc(TotalError);
          NotificarItem(AProgreso, Item);
        end;
      end;
      if Assigned(AFin) then
        TThread.Queue(nil,
          procedure
          begin
            AFin(TotalOk, TotalError);
          end);
    end).Start;
end;

end.
