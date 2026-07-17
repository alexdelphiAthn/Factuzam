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
  System.SysUtils;

type
  TResultadoFactuzamApi = record
    Ok: Boolean;
    EstadoHttp: Integer;
    IdPeticion: string;
    Mensaje: string;
  end;

  TClienteFactuzamApi = class
  private
    class function ComponerUrl(const ARuta: string): string; static;
    class function LeerRespuesta(const AContenido: string;
      AEstadoHttp: Integer): TResultadoFactuzamApi; static;
  public
    class function Configurada: Boolean; static;
    class function EnviarJson(const ARuta, AContenido: string):
      TResultadoFactuzamApi; static;
  end;

implementation

uses
  System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient,
  inLibAppParam;

class function TClienteFactuzamApi.ComponerUrl(
  const ARuta: string): string;
var
  sBase: string;
  sRuta: string;
begin
  sBase := Trim(oAppParams.GetString('appApiUrl', ''));
  if sBase = '' then
    sBase := Trim(oAppParams.GetString('appFotosUrlDescarga', ''));
  if (sBase <> '') and (sBase[Length(sBase)] <> '/') then
    sBase := sBase + '/';
  sRuta := Trim(ARuta);
  while (sRuta <> '') and (sRuta[1] = '/') do
    Delete(sRuta, 1, 1);
  Result := sBase + sRuta;
end;

class function TClienteFactuzamApi.Configurada: Boolean;
var
  sReferencia: string;
  sToken: string;
begin
  sToken := Trim(oAppParams.GetString('appApiToken', ''));
  if sToken = '' then
    sToken := Trim(oAppParams.GetString('appFotosApiKey', ''));
  sReferencia := Trim(oAppParams.GetString('appApiReferencia', ''));
  if sReferencia = '' then
    sReferencia := Trim(oAppParams.GetString(
      'appFotosCarpetaCliente', ''));
  Result := (ComponerUrl('') <> '') and (sToken <> '') and
            (sReferencia <> '');
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
  if not Configurada then
    Result.Mensaje := 'La API de Factuzam no está configurada.'
  else
  begin
    sToken := Trim(oAppParams.GetString('appApiToken', ''));
    if sToken = '' then
      sToken := Trim(oAppParams.GetString('appFotosApiKey', ''));
    oHttp := THTTPClient.Create;
    try
      oHttp.ConnectionTimeout := 10000;
      oHttp.ResponseTimeout := 60000;
      oHttp.CustomHeaders['Authorization'] := 'Bearer ' + sToken;
      oCuerpo := TStringStream.Create(AContenido, TEncoding.UTF8);
      try
        oRespuesta := oHttp.Post(
          ComponerUrl(ARuta), oCuerpo, nil,
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
