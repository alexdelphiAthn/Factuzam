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
{    artículo, color e índice. La subida se hace en un hilo de fondo y va      }
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
    FSubiendo: Boolean;
    function GetItems: TEnumerable<TFotoItem>;
    function SubirUno(const AItem: TFotoItem): Boolean;
    // Compatibilidad con los llamadores que no indican el índice: calcula
    // el siguiente índice libre tras el máximo de su grupo artículo+color.
    function CalcularIndice(const AItem: TFotoItem): string;
    procedure NotificarItem(const AProgreso: TProgresoFotoProc;
      const AItem: TFotoItem);
  public
    constructor Create;
    destructor Destroy; override;
    // La firma histórica conserva el índice correlativo automático.
    function Add(const AArchivo, AArticulo, AColor: string): TFotoItem;
      overload;
    // La app usa esta firma para conservar el índice elegido al capturar.
    function Add(const AArchivo, AArticulo, AColor: string;
      const AIndice: Integer): TFotoItem; overload;
    procedure Limpiar;
    function PendientesCount: Integer;
    // Sube en segundo plano todas las fotos no subidas. Notifica por
    // AProgreso cada cambio de estado y AFin al terminar el lote.
    procedure SubirTodasAsync(AProgreso: TProgresoFotoProc;
      AFin: TFinLoteProc);
    // Vista de solo lectura: las mutaciones deben pasar por Add/Limpiar para
    // respetar la guardia de una subida en curso.
    property Items: TEnumerable<TFotoItem> read GetItems;
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
  FSubiendo := False;
end;

destructor TColaFotos.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TColaFotos.Add(const AArchivo, AArticulo, AColor: string): TFotoItem;
begin
  if FSubiendo then
    raise Exception.Create('No se pueden añadir fotos durante una subida');
  Result := TFotoItem.Create;
  Result.Archivo := AArchivo;
  Result.Articulo := AArticulo;
  Result.Color := AColor;
  Result.Estado := esPendiente;
  FItems.Add(Result);
  Result.Indice := CalcularIndice(Result);
end;

function TColaFotos.GetItems: TEnumerable<TFotoItem>;
begin
  Result := FItems;
end;

function TColaFotos.Add(const AArchivo, AArticulo, AColor: string;
  const AIndice: Integer): TFotoItem;
var
  Otro: TFotoItem;
begin
  if FSubiendo then
    raise Exception.Create('No se pueden añadir fotos durante una subida');
  if AIndice < 1 then
    raise EArgumentException.Create('El índice de foto debe ser mayor o igual que 1');
  for Otro in FItems do
    if (Otro.Estado <> esOk) and
       SameText(Trim(Otro.Articulo), Trim(AArticulo)) and
       SameText(Trim(Otro.Color), Trim(AColor)) and
       (StrToIntDef(Otro.Indice, 0) = AIndice) then
      raise EArgumentException.CreateFmt(
        'Ya hay una foto pendiente para %s / %s / índice %d',
        [AArticulo, AColor, AIndice]);

  Result := TFotoItem.Create;
  Result.Archivo := AArchivo;
  Result.Articulo := AArticulo;
  Result.Color := AColor;
  Result.Indice := IntToStr(AIndice);
  Result.Estado := esPendiente;
  FItems.Add(Result);
end;

procedure TColaFotos.Limpiar;
begin
  if FSubiendo then
    raise Exception.Create('No se puede vaciar la cola durante una subida');
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
  IndiceOtro: Integer;
  Siguiente: Integer;
begin
  // Usar máximo+1 evita colisiones si un llamador histórico comparte cola
  // con fotos que ya traen índices explícitos o no correlativos.
  Siguiente := 1;
  for Otro in FItems do
    if (Otro <> AItem) and
       SameText(Trim(Otro.Articulo), Trim(AItem.Articulo)) and
       SameText(Trim(Otro.Color), Trim(AItem.Color)) then
    begin
      IndiceOtro := StrToIntDef(Otro.Indice, 0);
      if IndiceOtro >= Siguiente then
        Siguiente := IndiceOtro + 1;
    end;
  Result := IntToStr(Siguiente);
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
  // Los elementos nuevos ya traen el índice elegido en la interfaz. Este
  // fallback conserva la compatibilidad con colas creadas por código antiguo.
  if StrToIntDef(AItem.Indice, 0) < 1 then
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
var
  Lote: TArray<TFotoItem>;
begin
  if FSubiendo then
    raise Exception.Create('Ya hay una subida en curso');

  // La instantánea evita enumerar TObjectList desde el hilo mientras la UI
  // pudiera intentar modificarla. Los elementos siguen perteneciendo a
  // FItems y el formulario impide cerrarse hasta recibir AFin.
  Lote := FItems.ToArray;
  FSubiendo := True;
  // Hilo de fondo: la subida no debe bloquear la interfaz.
  try
    TThread.CreateAnonymousThread(
      procedure
      var
        Item: TFotoItem;
        TotalOk: Integer;
        TotalError: Integer;
      begin
        TotalOk := 0;
        TotalError := 0;
        try
          for Item in Lote do
          begin
            // Saltamos las que ya están subidas correctamente.
            if Item.Estado <> esOk then
            begin
              try
                Item.Estado := esSubiendo;
                NotificarItem(AProgreso, Item);
                if SubirUno(Item) then
                  Inc(TotalOk)
                else
                  Inc(TotalError);
              except
                on E: Exception do
                begin
                  Item.Estado := esError;
                  Item.Mensaje := E.Message;
                  Inc(TotalError);
                end;
              end;
              NotificarItem(AProgreso, Item);
            end;
          end;
        finally
          FSubiendo := False;
          if Assigned(AFin) then
            TThread.Queue(nil,
              procedure
              begin
                AFin(TotalOk, TotalError);
              end);
        end;
      end).Start;
  except
    FSubiendo := False;
    raise;
  end;
end;

end.
