{******************************************************************************}
{                                                                              }
{  Módulo:       UColaFotosNube                                                }
{    Tipo:       Librería (FMX, multiplataforma)                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de subida por lotes de fotos al webservice de Factuzam              }
{    (upload_foto.php / fotosnube). Cada foto se sube por multipart con los    }
{    campos cliente, sku, api_key e imagen. La subida se hace en un hilo de    }
{    fondo y va notificando el estado de cada elemento a la interfaz.          }
{    Mismo contrato que el cliente VCL existente (TFotoUploader).              }
{******************************************************************************}
unit UColaFotosNube;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  System.Generics.Collections, System.Net.HttpClient, System.Net.Mime,
  System.Net.URLClient;

type
  // Estado de cada foto dentro de la cola.
  TEstadoSubida = (esPendiente, esSubiendo, esOk, esError);

  // Un elemento de la cola: la foto local y el resultado del servidor.
  TFotoItem = class
  public
    Archivo: string;
    Sku: string;
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
    FCliente: string;
    function SubirUno(const AItem: TFotoItem): Boolean;
    // Notifica el estado de un item en el hilo principal. AItem es
    // parámetro para capturarlo por valor en cada llamada y evitar el
    // problema de captura de la variable de bucle en anónimos.
    procedure NotificarItem(const AProgreso: TProgresoFotoProc;
      const AItem: TFotoItem);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AArchivo, ASku: string): TFotoItem;
    procedure Limpiar;
    function PendientesCount: Integer;
    // Sube en segundo plano todas las fotos no subidas. Notifica por
    // AProgreso cada vez que cambia el estado de una y AFin al terminar.
    procedure SubirTodasAsync(AProgreso: TProgresoFotoProc;
      AFin: TFinLoteProc);
    property Items: TObjectList<TFotoItem> read FItems;
    property Url: string read FUrl write FUrl;
    property ApiKey: string read FApiKey write FApiKey;
    property Cliente: string read FCliente write FCliente;
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

function TColaFotos.Add(const AArchivo, ASku: string): TFotoItem;
begin
  Result := TFotoItem.Create;
  Result.Archivo := AArchivo;
  Result.Sku := ASku;
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

function TColaFotos.SubirUno(const AItem: TFotoItem): Boolean;
var
  HTTP: THTTPClient;
  Form: TMultipartFormData;
  Res: IHTTPResponse;
  Json: TJSONValue;
  Obj: TJSONObject;
  Valor: TJSONValue;
  EsOk: Boolean;
  Cuerpo: string;
begin
  Result := False;
  HTTP := THTTPClient.Create;
  try
    Form := TMultipartFormData.Create;
    try
      // Mismos campos que espera upload_foto.php.
      Form.AddField('cliente', FCliente);
      Form.AddField('sku', AItem.Sku);
      Form.AddField('api_key', FApiKey);
      Form.AddFile('imagen', AItem.Archivo);
      // La clave también por cabecera (el servidor admite ambas).
      HTTP.CustomHeaders['X-API-Key'] := FApiKey;
      Res := HTTP.Post(FUrl, Form, nil);
      Cuerpo := Res.ContentAsString;
      if Res.StatusCode <> 200 then
      begin
        AItem.Estado := esError;
        AItem.Mensaje := Format('HTTP %d: %s', [Res.StatusCode, Cuerpo]);
      end
      else
      begin
        // Respuesta JSON { ok, mensaje, hash, url }.
        EsOk := False;
        AItem.Hash := '';
        AItem.Mensaje := Cuerpo;
        Json := TJSONObject.ParseJSONValue(Cuerpo);
        try
          if Json is TJSONObject then
          begin
            Obj := TJSONObject(Json);
            Valor := Obj.GetValue('ok');
            if Valor is TJSONBool then
              EsOk := TJSONBool(Valor).AsBoolean;
            Valor := Obj.GetValue('hash');
            if Valor <> nil then
              AItem.Hash := Valor.Value;
            Valor := Obj.GetValue('mensaje');
            if Valor <> nil then
              AItem.Mensaje := Valor.Value;
          end;
        finally
          Json.Free;
        end;
        if EsOk then
        begin
          AItem.Estado := esOk;
          Result := True;
        end
        else
          AItem.Estado := esError;
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
