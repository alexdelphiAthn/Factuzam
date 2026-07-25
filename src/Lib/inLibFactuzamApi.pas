{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFactuzamApi                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente HTTP común para la API propia de Factuzam.                        }
{******************************************************************************}
unit inLibFactuzamApi;

interface

uses
  System.SysUtils, inLibParametrosIntf;

const
  cUrlFactuzamApiDefecto =
    'https://webservice.veryverifactu.com/api/v1/';

type
  TResultadoFactuzamApi = record
    Ok: Boolean;
    EstadoHttp: Integer;
    IdPeticion: string;
    Mensaje: string;
  end;

  TClienteFactuzamApi = class
  private
    class function LeerRespuesta(const AContenido: string;
      AEstadoHttp: Integer): TResultadoFactuzamApi; static;
  public
    class function UrlBase(
      const AParametrosApp: IParametrosAplicacion): string; static;
    class function Token(
      const AParametrosApp: IParametrosAplicacion): string; static;
    class function Referencia(
      const AParametrosApp: IParametrosAplicacion): string; static;
    class function ComponerUrl(
      const AParametrosApp: IParametrosAplicacion;
      const ARuta: string): string; static;
    class function Configurada(
      const AParametrosApp: IParametrosAplicacion): Boolean; static;
    class function EnviarJson(
      const AParametrosApp: IParametrosAplicacion;
      const ARuta, AContenido: string):
      TResultadoFactuzamApi; static;
  end;

implementation

uses
  System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient;

class function TClienteFactuzamApi.ComponerUrl(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta: string): string;
var
  sBase: string;
  sRuta: string;
begin
  sBase := UrlBase(AParametrosApp);
  if (sBase <> '') and (sBase[Length(sBase)] <> '/') then
    sBase := sBase + '/';
  sRuta := Trim(ARuta);
  while (sRuta <> '') and (sRuta[1] = '/') do
    Delete(sRuta, 1, 1);
  Result := sBase + sRuta;
end;

class function TClienteFactuzamApi.UrlBase(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := Trim(AParametrosApp.GetString('appApiUrl', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appFotosUrlDescarga', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appRecuentoUrl', ''));
  if Result = '' then
    Result := cUrlFactuzamApiDefecto;
end;

class function TClienteFactuzamApi.Token(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := Trim(AParametrosApp.GetString('appApiToken', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appFotosApiKey', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appRecuentoApiKey', ''));
end;

class function TClienteFactuzamApi.Referencia(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := Trim(AParametrosApp.GetString('appApiReferencia', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appFotosCarpetaCliente', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appRecuentoCarpetaCliente', ''));
end;

class function TClienteFactuzamApi.Configurada(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := (UrlBase(AParametrosApp) <> '') and
            (Token(AParametrosApp) <> '') and
            (Referencia(AParametrosApp) <> '');
end;

class function TClienteFactuzamApi.LeerRespuesta(
  const AContenido: string; AEstadoHttp: Integer): TResultadoFactuzamApi;
var
  oError: TJSONObject;
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result.Ok := (AEstadoHttp >= 200) and (AEstadoHttp < 300);
  Result.EstadoHttp := AEstadoHttp;
  Result.IdPeticion := '';
  Result.Mensaje := 'Respuesta HTTP ' + IntToStr(AEstadoHttp);
  oValor := TJSONObject.ParseJSONValue(AContenido);
  if oValor is TJSONObject then
  begin
    oJson := TJSONObject(oValor);
    try
      if Assigned(oJson.GetValue('id_peticion')) then
        Result.IdPeticion :=
          oJson.GetValue<string>('id_peticion');
      if Result.Ok then
        Result.Mensaje := 'Evento recibido correctamente.'
      else
      begin
        oError := oJson.GetValue('error') as TJSONObject;
        if Assigned(oError) and Assigned(oError.GetValue('mensaje')) then
          Result.Mensaje := oError.GetValue<string>('mensaje');
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else
    FreeAndNil(oValor);
end;

class function TClienteFactuzamApi.EnviarJson(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta, AContenido: string): TResultadoFactuzamApi;
var
  oCuerpo: TStringStream;
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sToken: string;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.IdPeticion := '';
  Result.Mensaje := '';
  if not Configurada(AParametrosApp) then
    Result.Mensaje := 'La API de Factuzam no está configurada.'
  else
  begin
    sToken := Token(AParametrosApp);
    oHttp := THTTPClient.Create;
    try
      oHttp.ConnectionTimeout := 10000;
      oHttp.ResponseTimeout := 60000;
      oHttp.CustomHeaders['Authorization'] := 'Bearer ' + sToken;
      oCuerpo := TStringStream.Create(AContenido, TEncoding.UTF8);
      try
        oRespuesta := oHttp.Post(
          ComponerUrl(AParametrosApp, ARuta), oCuerpo, nil,
          [TNetHeader.Create('Content-Type',
                             'application/json; charset=utf-8'),
           TNetHeader.Create('Accept', 'application/json')]);
        Result := LeerRespuesta(
          oRespuesta.ContentAsString(TEncoding.UTF8),
          oRespuesta.StatusCode);
      finally
        FreeAndNil(oCuerpo);
      end;
    finally
      FreeAndNil(oHttp);
    end;
  end;
end;

end.
