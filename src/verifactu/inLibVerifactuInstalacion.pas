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
procedure SincronizarVersionInstalacionesSif(AConn: TUniConnection);
function DescargarDeclaracionResponsableSif(const AVersion: string): string;
procedure ValidarInstalacionSif(const ANumero, AVersion, ACodigoSif,
                                ANombreEmpresa, ANifEmpresa: string);

implementation

uses
  System.Classes, System.JSON, System.Net.HttpClient, System.Net.URLClient,
  Data.DB,
  inLibGlobalVar, inLibAppParam;

const
  cUrlServicios = 'https://webservice.veryverifactu.com/api/v1/';
  cRutaInstalacionSif = 'sif/instalacion.php';
  cRutaDeclaracionSif = 'sif/declaracion.php';

function NifSoloDigitos(const AValor: string): Boolean;
var
  i: Integer;
begin
  Result := AValor <> '';
  i := 1;
  while (i <= Length(AValor)) and Result do
  begin
    if not CharInSet(AValor[i], ['0'..'9']) then
      Result := False;
    Inc(i);
  end;
end;

function NormalizarNifInstalacion(const AValor: string): string;
var
  i:       Integer;
  c:       Char;
  cLetra:  Char;
  sNumero: string;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := UpCase(AValor[i]);
    if CharInSet(c, ['0'..'9', 'A'..'Z']) then
      Result := Result + c;
  end;
  // Un DNI español tiene 8 dígitos + letra de control (9 caracteres). Si el
  // primer dígito es 0 suele perderse al almacenarlo o teclearlo, dejando el
  // NIF en 8 caracteres (p. ej. "9675172S" en vez de "09675172S"). Cuando
  // detectamos esa forma (solo dígitos + letra final y menos de 9 caracteres)
  // rellenamos con ceros por la izquierda para devolver el NIF canónico. Los
  // NIE y CIF empiezan por letra, así que esta corrección no les afecta.
  if (Length(Result) >= 2) and (Length(Result) < 9) and
     CharInSet(Result[Length(Result)], ['A'..'Z']) then
  begin
    cLetra := Result[Length(Result)];
    sNumero := Copy(Result, 1, Length(Result) - 1);
    if NifSoloDigitos(sNumero) then
    begin
      while Length(sNumero) < 8 do
        sNumero := '0' + sNumero;
      Result := sNumero + cLetra;
    end;
  end;
end;

function UrlServicioSif(const ARuta: string): string;
begin
  Result := Trim(oAppParams.GetString('appFotosUrlDescarga',
                                      cUrlServicios));
  if Result = '' then
    Result := cUrlServicios;
  if not Result.EndsWith('/') then
    Result := Result + '/';
  Result := Result + ARuta;
end;

function UrlServicioInstalacionSif: string;
begin
  Result := UrlServicioSif(cRutaInstalacionSif);
end;

function UrlServicioDeclaracionSif: string;
begin
  Result := UrlServicioSif(cRutaDeclaracionSif);
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
  oError: TJSONValue;
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
        oError := TJSONObject(oJson).GetValue('error');
        if oError <> nil then
        begin
          oValor := oError.FindValue('mensaje');
          if oValor <> nil then
            Result := Trim(oValor.Value);
        end;
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
  oDatos:    TJSONValue;
  oCuerpo:   TStringStream;
  oResp:     IHTTPResponse;
  sRespuesta:string;
  sReferencia:string;
  sToken:    string;
begin
  Result := '';
  oHttp := THTTPClient.Create;
  oReqJson := TJSONObject.Create;
  try
    oReqJson.AddPair('version', AVersion);
    oReqJson.AddPair('razon_social', ARazonSocial);
    oReqJson.AddPair('nif', ANif);
    oReqJson.AddPair('sif', ACodigoSif);
    sReferencia := Trim(oAppParams.GetString('appFotosCarpetaCliente'));
    sToken := Trim(oAppParams.GetString('appFotosApiKey'));
    if sReferencia = '' then
      raise Exception.Create('Falta la referencia global de la instalación.');
    if sToken = '' then
      raise Exception.Create('Falta la API key de la instalación.');
    oReqJson.AddPair('referencia', sReferencia);
    oCuerpo := TStringStream.Create(oReqJson.ToString, TEncoding.UTF8);
    try
      oHttp.ConnectionTimeout := 15000;
      oHttp.ResponseTimeout := 30000;
      oHttp.CustomHeaders['X-API-Key'] := sToken;
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
        oDatos := TJSONObject(oRespJson).GetValue('datos');
        if oDatos is TJSONObject then
          Result := JsonString(TJSONObject(oDatos), 'numero_instalacion');
        if Result = '' then
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

function DescargarDeclaracionResponsableSif(const AVersion: string): string;
var
  oHttp:       THTTPClient;
  oReqJson:    TJSONObject;
  oRespJson:   TJSONValue;
  oDatos:      TJSONValue;
  oCuerpo:     TStringStream;
  oResp:       IHTTPResponse;
  sCodigoSif:  string;
  sReferencia: string;
  sRespuesta:  string;
  sToken:      string;
  sVersion:    string;
begin
  Result := '';
  sReferencia := Trim(oAppParams.GetString('appFotosCarpetaCliente'));
  sToken := Trim(oAppParams.GetString('appFotosApiKey'));
  if sReferencia = '' then
    raise Exception.Create('Falta la referencia global de la instalación.');
  if sToken = '' then
    raise Exception.Create('Falta la API key de la instalación.');
  oHttp := THTTPClient.Create;
  oReqJson := TJSONObject.Create;
  try
    oReqJson.AddPair('version', AVersion);
    oReqJson.AddPair('sif', cCodigoSifFactuzam);
    oReqJson.AddPair('referencia', sReferencia);
    oCuerpo := TStringStream.Create(oReqJson.ToString, TEncoding.UTF8);
    try
      oHttp.ConnectionTimeout := 15000;
      oHttp.ResponseTimeout := 30000;
      oHttp.CustomHeaders['X-API-Key'] := sToken;
      oResp := oHttp.Post(UrlServicioDeclaracionSif, oCuerpo, nil,
        [TNetHeader.Create('Content-Type',
                           'application/json; charset=utf-8')]);
      sRespuesta := oResp.ContentAsString(TEncoding.UTF8);
      if oResp.StatusCode <> 200 then
        raise Exception.Create(MensajeErrorServicio(sRespuesta,
                              oResp.StatusCode));
      oRespJson := TJSONObject.ParseJSONValue(sRespuesta);
      try
        if not (oRespJson is TJSONObject) then
          raise Exception.Create('El servicio no devolvió JSON válido.');
        oDatos := TJSONObject(oRespJson).GetValue('datos');
        if not (oDatos is TJSONObject) then
          raise Exception.Create('El servicio no devolvió los datos de la ' +
                                 'declaración responsable.');
        sVersion := JsonString(TJSONObject(oDatos), 'version');
        sCodigoSif := JsonString(TJSONObject(oDatos), 'sif');
        if not SameText(sVersion, AVersion) then
          raise Exception.Create('La declaración recibida no corresponde ' +
                                 'a la versión solicitada.');
        if not SameText(sCodigoSif, cCodigoSifFactuzam) then
          raise Exception.Create('La declaración recibida no corresponde ' +
                                 'al SIF FZ.');
        Result := JsonString(TJSONObject(oDatos), 'contenido_html');
        if Trim(Result) = '' then
          raise Exception.Create('La declaración descargada está vacía.');
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
    AEstado.Mensaje := 'Pendiente de registrar la versión ' + oVersion +
                       ' en la instalación SIF.'
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

procedure SincronizarVersionInstalacionesSif(AConn: TUniConnection);
var
  oEstado: TEstadoInstalacionSif;
  Qry:     TUniQuery;
begin
  oEstado := GenerarInstalacionSifEmpresa(AConn, '');
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
      '  WHERE COALESCE(NUMERO_INSTALACION_EMP, '''') <> :NUMERO ' +
      '     OR COALESCE(VERSION_INSTALACION_EMP, '''') <> :VERSION ' +
      '     OR COALESCE(CODIGO_SIF_INSTALACION_EMP, '''') <> :CODIGO_SIF';
    Qry.ParamByName('NUMERO').AsString := oEstado.Numero;
    Qry.ParamByName('VERSION').AsString := oVersion;
    Qry.ParamByName('CODIGO_SIF').AsString := cCodigoSifFactuzam;
    Qry.ParamByName('USUARIO').AsString := oUser;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
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
