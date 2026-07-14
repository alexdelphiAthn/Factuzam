{******************************************************************************}
{                                                                              }
{  Módulo:       inLibClienteApi                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Solicita al webservice una credencial API mediante petición firmada.      }
{******************************************************************************}

unit inLibClienteApi;

interface

uses
  System.SysUtils,
  inLibFirmaApi;

type
  TResultCrearApi = record
    Creada: Boolean;
    IdApi: Int64;
    Referencia: string;
    Token: string;
    Mensaje: string;
  end;

  TClienteApi = class
  private
    class function CrearCuerpo(const AReferencia,
      AAmbitos: string): TBytes; static;
    class function MensajeCanonico(const ATimestamp, ANonce,
      AHashCuerpo: string): TBytes; static;
    class function LeerRespuesta(const ATexto: string;
      AEstadoHttp: Integer): TResultCrearApi; static;
  public
    class function CrearApi(const AUrl, AReferencia, AAmbitos: string;
      const AIdentidad: TIdentidadEmisora): TResultCrearApi; static;
  end;

implementation

uses
  System.Classes, System.DateUtils, System.JSON, System.Net.HttpClient,
  System.Net.URLClient;

class function TClienteApi.CrearCuerpo(
  const AReferencia, AAmbitos: string): TBytes;
var
  i: Integer;
  oAmbitos: TJSONArray;
  oJson: TJSONObject;
  stAmbitos: TStringList;
  sAmbito: string;
begin
  oJson := TJSONObject.Create;
  try
    oAmbitos := TJSONArray.Create;
    stAmbitos := TStringList.Create;
    try
      stAmbitos.StrictDelimiter := True;
      stAmbitos.Delimiter := ',';
      stAmbitos.DelimitedText := StringReplace(AAmbitos, ';', ',',
                                               [rfReplaceAll]);
      for i := 0 to stAmbitos.Count - 1 do
      begin
        sAmbito := Trim(stAmbitos[i]);
        if sAmbito <> '' then
          oAmbitos.Add(sAmbito);
      end;
      oJson.AddPair('referencia', Trim(AReferencia));
      oJson.AddPair('ambitos', oAmbitos);
      Result := TEncoding.UTF8.GetBytes(oJson.ToJSON);
    finally
      FreeAndNil(stAmbitos);
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

class function TClienteApi.MensajeCanonico(
  const ATimestamp, ANonce, AHashCuerpo: string): TBytes;
var
  sMensaje: string;
begin
  sMensaje := 'FZAM-API-CREAR-V1' + #10 +
              ATimestamp + #10 +
              ANonce + #10 +
              LowerCase(AHashCuerpo);
  Result := TEncoding.UTF8.GetBytes(sMensaje);
end;

class function TClienteApi.LeerRespuesta(
  const ATexto: string; AEstadoHttp: Integer): TResultCrearApi;
var
  oDatos: TJSONObject;
  oError: TJSONObject;
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result.Creada := False;
  Result.IdApi := 0;
  Result.Referencia := '';
  Result.Token := '';
  Result.Mensaje := 'Respuesta HTTP ' + IntToStr(AEstadoHttp);
  oValor := TJSONObject.ParseJSONValue(ATexto);
  if oValor is TJSONObject then
  begin
    oJson := TJSONObject(oValor);
    try
      if (AEstadoHttp >= 200) and (AEstadoHttp < 300) then
      begin
        oDatos := oJson.GetValue('datos') as TJSONObject;
        if Assigned(oDatos) then
        begin
          Result.Creada := True;
          Result.IdApi := oDatos.GetValue<Int64>('id_api');
          Result.Referencia := oDatos.GetValue<string>('referencia');
          Result.Token := oDatos.GetValue<string>('token');
          Result.Mensaje := 'Credencial creada correctamente.';
        end;
      end
      else
      begin
        oError := oJson.GetValue('error') as TJSONObject;
        if Assigned(oError) then
          Result.Mensaje := oError.GetValue<string>('mensaje');
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else
    FreeAndNil(oValor);
end;

class function TClienteApi.CrearApi(
  const AUrl, AReferencia, AAmbitos: string;
  const AIdentidad: TIdentidadEmisora): TResultCrearApi;
var
  aCuerpo: TBytes;
  aFirma: TBytes;
  aMensaje: TBytes;
  dtUtc: TDateTime;
  oCuerpo: TBytesStream;
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sHash: string;
  sNonce: string;
  sTimestamp: string;
begin
  Result.Creada := False;
  Result.Mensaje := '';
  aCuerpo := CrearCuerpo(AReferencia, AAmbitos);
  sHash := TFirmaApi.HashSha256Hex(aCuerpo);
  sNonce := TFirmaApi.GenerarNonce;
  dtUtc := TTimeZone.Local.ToUniversalTime(Now);
  sTimestamp := IntToStr(DateTimeToUnix(dtUtc, True));
  aMensaje := MensajeCanonico(sTimestamp, sNonce, sHash);
  try
    aFirma := TFirmaApi.Firmar(AIdentidad, aMensaje);
    try
      oHttp := THTTPClient.Create;
      try
        oHttp.ConnectionTimeout := 10000;
        oHttp.ResponseTimeout := 30000;
        oHttp.CustomHeaders['X-FZ-Key-Id'] := AIdentidad.IdClave;
        oHttp.CustomHeaders['X-FZ-Timestamp'] := sTimestamp;
        oHttp.CustomHeaders['X-FZ-Nonce'] := sNonce;
        oHttp.CustomHeaders['X-FZ-Signature'] :=
          TFirmaApi.Base64UrlCodificar(aFirma);
        oCuerpo := TBytesStream.Create(aCuerpo);
        try
          oRespuesta := oHttp.Post(
            Trim(AUrl), oCuerpo, nil,
            [TNameValuePair.Create('Content-Type',
                                   'application/json; charset=utf-8')]);
          Result := LeerRespuesta(
            oRespuesta.ContentAsString(TEncoding.UTF8),
            oRespuesta.StatusCode);
        finally
          FreeAndNil(oCuerpo);
        end;
      finally
        FreeAndNil(oHttp);
      end;
    finally
      TFirmaApi.Limpiar(aFirma);
    end;
  finally
    TFirmaApi.Limpiar(aMensaje);
    TFirmaApi.Limpiar(aCuerpo);
  end;
end;

end.
