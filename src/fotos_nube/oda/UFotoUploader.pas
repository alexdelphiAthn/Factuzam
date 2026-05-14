unit UFotoUploader;

// ----------------------------------------------------------------------
// UFotoUploader
// Lógica de subida de UNA foto al servidor PHP. Sin VCL.
// Pensado para correr dentro de tareas OmniThreadLibrary: cada llamada
// crea su propio THTTPClient (cada hilo SU instancia).
//
// La decisión de "saltar si ya existe" se toma ANTES de llamar aquí,
// usando el inventario que devuelve listar_fotos.php (ver UPrincipal).
// Este worker solo sube.
// ----------------------------------------------------------------------

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.JSON,
  System.Net.HttpClient, System.Net.URLClient, System.Net.Mime;

type
  TFotoUploadStatus = (fusOK, fusError);

  TFotoUploadResult = record
    Articulo  : string;
    Color     : string;
    Indice    : Integer;
    Archivo   : string;
    Status    : TFotoUploadStatus;
    Mensaje   : string;
    SHA1Local : string;   // SHA1 del archivo local original
    SHA1Server: string;   // SHA1 del PNG _real procesado por el servidor
  end;

  TFotoUploadConfig = record
    UrlUpload      : string;
    ApiKey         : string;
    CarpetaCliente : string;
    PrefijoLocal   : string;
  end;

function CalcularSHA1Archivo(const FileName: string): string;

function SubirFoto(const Cfg: TFotoUploadConfig;
                   const Articulo, Color: string;
                   Indice: Integer;
                   const NombreArchivoSinPrefijo: string;
                   const SHA1LocalYaCalculado: string = ''): TFotoUploadResult;

implementation

// ----------------------------------------------------------------------
function CalcularSHA1Archivo(const FileName: string): string;
const
  BUFFER_SIZE = 64 * 1024;
var
  Hash: THashSHA1;
  Stream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Hash := THashSHA1.Create;
  SetLength(Buffer, BUFFER_SIZE);
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    repeat
      BytesRead := Stream.Read(Buffer[0], BUFFER_SIZE);
      if BytesRead > 0 then
        Hash.Update(Buffer[0], BytesRead);
    until BytesRead = 0;
  finally
    Stream.Free;
  end;
  Result := LowerCase(Hash.HashAsString);
end;

// ----------------------------------------------------------------------
type
  TCertHelper = class
    procedure Accept(const Sender: TObject; const ARequest: TURLRequest;
      const Certificate: TCertificate; var Accepted: Boolean);
  end;

procedure TCertHelper.Accept(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

// ----------------------------------------------------------------------
function SubirFoto(const Cfg: TFotoUploadConfig;
                   const Articulo, Color: string;
                   Indice: Integer;
                   const NombreArchivoSinPrefijo: string;
                   const SHA1LocalYaCalculado: string): TFotoUploadResult;
var
  FileName: string;
  HTTP    : THTTPClient;
  Helper  : TCertHelper;
  Form    : TMultipartFormData;
  Res     : IHTTPResponse;
  Response: TStringStream;
  J       : TJSONObject;
  V       : TJSONValue;
  StatusV : string;
begin
  Result := Default(TFotoUploadResult);
  Result.Articulo := Articulo;
  Result.Color    := Color;
  Result.Indice   := Indice;
  Result.Status   := fusError;

  // Componer ruta local con prefijo
  FileName := Cfg.PrefijoLocal;
  if (FileName <> '') and (FileName[Length(FileName)] <> PathDelim) then
    FileName := FileName + PathDelim;
  FileName := FileName + NombreArchivoSinPrefijo;
  Result.Archivo := FileName;

  if not FileExists(FileName) then
  begin
    Result.Mensaje := 'Archivo local no encontrado';
    Exit;
  end;

  // SHA1 local (usar el ya calculado si nos lo pasaron, evita recalcular)
  if SHA1LocalYaCalculado <> '' then
    Result.SHA1Local := LowerCase(SHA1LocalYaCalculado)
  else
  begin
    try
      Result.SHA1Local := CalcularSHA1Archivo(FileName);
    except
      on E: Exception do
      begin
        Result.Mensaje := 'SHA1 local: ' + E.Message;
        Exit;
      end;
    end;
  end;

  // ---- Subir ----
  HTTP     := THTTPClient.Create;
  Helper   := TCertHelper.Create;
  Form     := TMultipartFormData.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := Helper.Accept;
    HTTP.CustomHeaders['X-API-Key']  := Cfg.ApiKey;
    HTTP.ConnectionTimeout := 30000;
    HTTP.ResponseTimeout   := 120000;

    Form.AddField('articulo',        Articulo);
    Form.AddField('color',           Color);
    Form.AddField('indice',          IntToStr(Indice));
    Form.AddField('carpeta_cliente', Cfg.CarpetaCliente);
    Form.AddField('osha1',           Result.SHA1Local);
    Form.AddFile ('imagen',          FileName);

    try
      Res := HTTP.Post(Cfg.UrlUpload, Form, Response);
    except
      on E: Exception do
      begin
        Result.Mensaje := 'Upload error: ' + E.Message;
        Exit;
      end;
    end;

    if Res.StatusCode <> 200 then
    begin
      Result.Mensaje := Format('Upload HTTP %d: %s',
                       [Res.StatusCode, Copy(Response.DataString, 1, 500)]);
      Exit;
    end;

    J := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
    if J = nil then
    begin
      Result.Mensaje := 'Upload: JSON inválido';
      Exit;
    end;
    try
      V := J.GetValue('status');
      if V = nil then
      begin
        Result.Mensaje := 'Upload: sin status';
        Exit;
      end;
      StatusV := V.Value;
      if StatusV <> 'success' then
      begin
        V := J.GetValue('message');
        if V <> nil then
          Result.Mensaje := 'Upload: ' + V.Value
        else
          Result.Mensaje := 'Upload: status=' + StatusV;
        Exit;
      end;
      V := J.GetValue('sha1');
      if V <> nil then
        Result.SHA1Server := LowerCase(V.Value);
    finally
      J.Free;
    end;
  finally
    Response.Free;
    Form.Free;
    Helper.Free;
    HTTP.Free;
  end;

  Result.Status  := fusOK;
  Result.Mensaje := 'Subida OK';
end;

end.
