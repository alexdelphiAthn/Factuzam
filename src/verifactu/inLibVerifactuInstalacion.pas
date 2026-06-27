{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuInstalacion                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Solicitud, persistencia y validación del NumeroInstalacion del SIF FZ.    }
{    El número lo devuelve el servicio del productor y se guarda por empresa.  }
{******************************************************************************}
unit inLibVerifactuInstalacion;

interface

uses
  System.SysUtils, Uni;

const
  cCodigoSifFactuzam = 'FZ';

type
  TEstadoInstalacionSif = record
    CodigoEmpresa: string;
    RazonSocial:   string;
    Nif:           string;
    Numero:        string;
    Version:       string;
    CodigoSif:     string;
    Instante:      TDateTime;
    EsValido:      Boolean;
    Mensaje:       string;
  end;

function ObtenerEmpresaInstalacionSif(AConn: TUniConnection;
                                      const ACodigoEmpresa: string;
                                      out AEstado: TEstadoInstalacionSif):
                                      Boolean;
function ObtenerEmpresaInstalacionSifDefecto(AConn: TUniConnection;
                                             out AEstado:
                                             TEstadoInstalacionSif): Boolean;
function GenerarInstalacionSifEmpresa(AConn: TUniConnection;
                                      const ACodigoEmpresa: string):
                                      TEstadoInstalacionSif;
procedure ValidarInstalacionSif(const ANumero, AVersion, ACodigoSif,
                                ANombreEmpresa, ANifEmpresa: string);

implementation

uses
  System.Classes, System.JSON, System.Net.HttpClient, System.Net.URLClient,
  Data.DB,
  inLibGlobalVar, inLibAppParam;

const
  cUrlInstalacionSif =
    'https://veryverifactu.com/api/instalacion.php';

function NormalizarNifInstalacion(const AValor: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := UpCase(AValor[i]);
    if CharInSet(c, ['0'..'9', 'A'..'Z']) then
      Result := Result + c;
  end;
end;

function UrlServicioInstalacionSif: string;
begin
  Result := Trim(oAppParams.GetString('appVerifactuInstalacionUrl',
                                      cUrlInstalacionSif));
  if Result = '' then
    Result := cUrlInstalacionSif;
end;

function JsonString(AObj: TJSONObject; const AClave: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  oValor := AObj.GetValue(AClave);
  if oValor <> nil then
    Result := Trim(oValor.Value);
end;

function MensajeErrorServicio(const ACuerpo: string;
                              AEstadoHttp: Integer): string;
var
  oJson:  TJSONValue;
  oValor: TJSONValue;
begin
  Result := '';
  oJson := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if oJson is TJSONObject then
    begin
      oValor := TJSONObject(oJson).GetValue('message');
      if oValor <> nil then
        Result := Trim(oValor.Value);
      if Result = '' then
      begin
        oValor := TJSONObject(oJson).GetValue('error');
        if oValor <> nil then
          Result := Trim(oValor.Value);
      end;
    end;
  finally
    FreeAndNil(oJson);
  end;
  if Result = '' then
    Result := Format('El servicio respondió con HTTP %d.', [AEstadoHttp]);
end;

function PedirNumeroInstalacionServicio(const AVersion, ARazonSocial,
                                        ANif, ACodigoSif: string): string;
var
  oHttp:     THTTPClient;
  oReqJson:  TJSONObject;
  oRespJson: TJSONValue;
  oCuerpo:   TStringStream;
  oResp:     IHTTPResponse;
  sRespuesta:string;
begin
  Result := '';
  oHttp := THTTPClient.Create;
  oReqJson := TJSONObject.Create;
  try
    oReqJson.AddPair('version', AVersion);
    oReqJson.AddPair('razon_social', ARazonSocial);
    oReqJson.AddPair('nif', ANif);
    oReqJson.AddPair('sif', ACodigoSif);
    oCuerpo := TStringStream.Create(oReqJson.ToString, TEncoding.UTF8);
    try
      oHttp.ConnectionTimeout := 15000;
      oHttp.ResponseTimeout := 30000;
      oResp := oHttp.Post(UrlServicioInstalacionSif, oCuerpo, nil,
        [TNetHeader.Create('Content-Type', 'application/json; charset=utf-8')]);
      sRespuesta := oResp.ContentAsString(TEncoding.UTF8);
      if oResp.StatusCode <> 200 then
        raise Exception.Create(MensajeErrorServicio(sRespuesta,
                              oResp.StatusCode));
      oRespJson := TJSONObject.ParseJSONValue(sRespuesta);
      try
        if not (oRespJson is TJSONObject) then
          raise Exception.Create('El servicio no devolvió JSON válido.');
        Result := JsonString(TJSONObject(oRespJson), 'numero_instalacion');
        if Result = '' then
          Result := JsonString(TJSONObject(oRespJson), 'numeroInstalacion');
        if Result = '' then
          Result := JsonString(TJSONObject(oRespJson), 'NumeroInstalacion');
        if Result = '' then
          raise Exception.Create('El servicio no devolvió NumeroInstalacion.');
      finally
        FreeAndNil(oRespJson);
      end;
    finally
      FreeAndNil(oCuerpo);
    end;
  finally
    FreeAndNil(oReqJson);
    FreeAndNil(oHttp);
  end;
end;

procedure VaciarEstado(var AEstado: TEstadoInstalacionSif);
begin
  AEstado.CodigoEmpresa := '';
  AEstado.RazonSocial := '';
  AEstado.Nif := '';
  AEstado.Numero := '';
  AEstado.Version := '';
  AEstado.CodigoSif := '';
  AEstado.Instante := 0;
  AEstado.EsValido := False;
  AEstado.Mensaje := '';
end;

procedure ActualizarValidez(var AEstado: TEstadoInstalacionSif);
begin
  AEstado.EsValido := False;
  if Trim(AEstado.Numero) = '' then
    AEstado.Mensaje := 'Pendiente de generar desde el servicio.'
  else if not SameText(Trim(AEstado.CodigoSif), cCodigoSifFactuzam) then
    AEstado.Mensaje := 'El SIF guardado no coincide con FZ.'
  else if not SameText(Trim(AEstado.Version), oVersion) then
    AEstado.Mensaje := 'El número corresponde a la versión ' +
                       Trim(AEstado.Version) +
                       ' y debe regenerarse para ' + oVersion + '.'
  else
  begin
    AEstado.EsValido := True;
    AEstado.Mensaje := 'Válido para la versión actual.';
  end;
end;

function ObtenerEmpresaInstalacionSif(AConn: TUniConnection;
                                      const ACodigoEmpresa: string;
                                      out AEstado: TEstadoInstalacionSif):
                                      Boolean;
var
  Qry: TUniQuery;
begin
  VaciarEstado(AEstado);
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ' +
      '        NUMERO_INSTALACION_EMP, VERSION_INSTALACION_EMP, ' +
      '        CODIGO_SIF_INSTALACION_EMP, INSTANTE_INSTALACION_EMP ' +
      ' FROM fza_empresas ';
    if Trim(ACodigoEmpresa) <> '' then
      Qry.SQL.Text := Qry.SQL.Text +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP ';
    Qry.SQL.Text := Qry.SQL.Text +
      ' ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, ' +
      '          CODIGO_EMP_EMP ' +
      ' LIMIT 1';
    if Trim(ACodigoEmpresa) <> '' then
      Qry.ParamByName('CODIGO_EMP').AsString := Trim(ACodigoEmpresa);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result := True;
      AEstado.CodigoEmpresa :=
        Trim(Qry.FieldByName('CODIGO_EMP_EMP').AsString);
      AEstado.RazonSocial :=
        Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
      AEstado.Nif :=
        NormalizarNifInstalacion(Qry.FieldByName('NIF_EMP').AsString);
      AEstado.Numero :=
        Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
      AEstado.Version :=
        Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
      AEstado.CodigoSif :=
        Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
      if not Qry.FieldByName('INSTANTE_INSTALACION_EMP').IsNull then
        AEstado.Instante :=
          Qry.FieldByName('INSTANTE_INSTALACION_EMP').AsDateTime;
      ActualizarValidez(AEstado);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function ObtenerEmpresaInstalacionSifDefecto(AConn: TUniConnection;
                                             out AEstado:
                                             TEstadoInstalacionSif): Boolean;
begin
  Result := ObtenerEmpresaInstalacionSif(AConn, '', AEstado);
end;

function GenerarInstalacionSifEmpresa(AConn: TUniConnection;
                                      const ACodigoEmpresa: string):
                                      TEstadoInstalacionSif;
var
  Qry:    TUniQuery;
  sNumero:string;
begin
  if not ObtenerEmpresaInstalacionSif(AConn, ACodigoEmpresa, Result) then
    raise Exception.Create('No hay empresa configurada para solicitar el ' +
      'número de instalación SIF.');
  if Result.EsValido then
  begin
    sNumero := Trim(Result.Numero);
  end
  else
  begin
    sNumero := '';
  end;
  if Trim(Result.RazonSocial) = '' then
    raise Exception.Create('La empresa no tiene razón social.');
  if Length(Result.Nif) <> 9 then
    raise Exception.Create('El NIF de la empresa no es válido: "' +
      Result.Nif + '".');
  if sNumero = '' then
  begin
    sNumero := PedirNumeroInstalacionServicio(oVersion, Result.RazonSocial,
                                              Result.Nif, cCodigoSifFactuzam);
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' UPDATE fza_empresas ' +
        '    SET NUMERO_INSTALACION_EMP = :NUMERO, ' +
        '        VERSION_INSTALACION_EMP = :VERSION, ' +
        '        CODIGO_SIF_INSTALACION_EMP = :CODIGO_SIF, ' +
        '        INSTANTE_INSTALACION_EMP = NOW(), ' +
        '        INSTANTE_MODIF = NOW(), ' +
        '        USUARIO_MODIF = :USUARIO ' +
        '  WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      Qry.ParamByName('NUMERO').AsString := sNumero;
      Qry.ParamByName('VERSION').AsString := oVersion;
      Qry.ParamByName('CODIGO_SIF').AsString := cCodigoSifFactuzam;
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('CODIGO_EMP').AsString := Result.CodigoEmpresa;
      Qry.Execute;
    finally
      FreeAndNil(Qry);
    end;
    ObtenerEmpresaInstalacionSif(AConn, Result.CodigoEmpresa, Result);
  end;
end;

procedure ValidarInstalacionSif(const ANumero, AVersion, ACodigoSif,
                                ANombreEmpresa, ANifEmpresa: string);
var
  sNumero: string;
  sVersion:string;
  sSif:    string;
begin
  sNumero := Trim(ANumero);
  sVersion := Trim(AVersion);
  sSif := Trim(ACodigoSif);
  if sNumero = '' then
    raise Exception.Create('La empresa ' + Trim(ANombreEmpresa) + ' (' +
      Trim(ANifEmpresa) + ') no tiene número de instalación SIF. ' +
      'Genéralo desde Archivo > Empresas.');
  if not SameText(sSif, cCodigoSifFactuzam) then
    raise Exception.Create('El número de instalación SIF de la empresa ' +
      Trim(ANombreEmpresa) + ' no corresponde al SIF FZ.');
  if sVersion = '' then
    raise Exception.Create('El número de instalación SIF de la empresa ' +
      Trim(ANombreEmpresa) + ' no tiene versión asociada. Genéralo de ' +
      'nuevo desde Archivo > Empresas.');
  if not SameText(sVersion, oVersion) then
    raise Exception.Create('El número de instalación SIF de la empresa ' +
      Trim(ANombreEmpresa) + ' fue generado para la versión ' + sVersion +
      ' y la versión actual es ' + oVersion + '. Genéralo de nuevo desde ' +
      'Archivo > Empresas.');
end;

end.
