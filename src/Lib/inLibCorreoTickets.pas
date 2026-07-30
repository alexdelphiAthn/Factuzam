{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoTickets                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera los PDF asociados a una operación y los envía mediante el          }
{    servicio web de correo configurado para la instalación.                   }
{******************************************************************************}
unit inLibCorreoTickets;

interface

uses
  System.SysUtils, Uni, inLibParametrosIntf,
  inLibTraspasoTicketIntf;

type
  TDatosCorreoOperacion = record
    Encontrada: Boolean;
    EmailCliente: string;
    CodigoCliente: string;
    NombreEmpresa: string;
    TieneFactura: Boolean;
    TieneDepositos: Boolean;
    EsOperacionCaja: Boolean;
    EsTraspaso: Boolean;
  end;

function CorreoTicketsConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
function ObtenerDatosCorreoOperacion(AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string): TDatosCorreoOperacion;
function EnviarDocumentacionOperacion(
  const AParametrosApp: IParametrosAplicacion;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, ANumeroOperacion, AEmail: string;
  out AMensaje: string): Boolean;

implementation

uses
  System.Classes, System.JSON, System.Net.HttpClient, System.Net.Mime,
  inLibGenerarTicketBD, inLibGenerarTicketCaja,
  inLibTraspasoTicket, inLibLog, inLibFactuzamApi;

const
  cRutaCorreo = 'correo/enviar_ticket.php';

function CorreoTicketsConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
var
  Faltan: TStringList;
begin
  AMensaje := '';
  Faltan := TStringList.Create;
  try
    if TClienteFactuzamApi.UrlBase(AParametrosApp) = '' then
      Faltan.Add('  - URL general del servicio web');
    if TClienteFactuzamApi.Token(AParametrosApp) = '' then
      Faltan.Add('  - API key / token de la instalación');
    if TClienteFactuzamApi.Referencia(AParametrosApp) = '' then
      Faltan.Add('  - Referencia global de la instalación');
    Result := Faltan.Count = 0;
    if not Result then
      AMensaje := 'Configura primero estos parámetros (Parámetros de la ' +
        'aplicación -> Servicios web):' + sLineBreak + Faltan.Text;
  finally
    FreeAndNil(Faltan);
  end;
end;

function ObtenerDatosCorreoOperacion(AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string): TDatosCorreoOperacion;
var
  Qry: TUniQuery;
  sTipos: string;
begin
  Result := Default(TDatosCorreoOperacion);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS NUM_FILAS,' +
      '       MAX(COALESCE(NULLIF(f.CODIGO_CLI_FAC, ''''),' +
      '                    NULLIF(o.CODIGO_CLI_OPCAJA, ''''))) ' +
      '         AS CODIGO_CLIENTE,' +
      '       MAX(cli.EMAIL_CLI) AS EMAIL_CLIENTE,' +
      '       MAX(emp.RAZON_SOCIAL_EMP) AS NOMBRE_EMPRESA,' +
      '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA ' +
      '         SEPARATOR '','') AS TIPOS_OPERACION,' +
      '       SUM(CASE WHEN f.NUMERO_FAC IS NULL THEN 0 ELSE 1 END) ' +
      '         AS NUM_FACTURAS,' +
      '       (SELECT COUNT(*) FROM fza_caja_depositos_view d' +
      '         WHERE d.CODIGO_EMPRESA_OP = :EMP' +
      '           AND d.CODIGO_ALMACEN_OP = :ALM' +
      '           AND d.CODIGO_CAJA_OP = :CAJA' +
      '           AND d.NUMERO_OPERACION_OP = :OPERACION) ' +
      '         AS NUM_DEPOSITOS' +
      '  FROM fza_caja_operaciones o' +
      '  LEFT JOIN fza_facturas f' +
      '    ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA' +
      '   AND ((TRIM(COALESCE(o.SERIE_FAC_OPCAJA, '''')) <> ''''' +
      '         AND TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, '''')) <> ''''' +
      '         AND f.SERIE_FAC = o.SERIE_FAC_OPCAJA' +
      '         AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA)' +
      '     OR ((TRIM(COALESCE(o.SERIE_FAC_OPCAJA, '''')) = ''''' +
      '          OR TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, '''')) = '''')' +
      '         AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA' +
      '         AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA' +
      '         AND f.NUMERO_OPERACION_FAC = ' +
      '             o.NUMERO_OPERACION_OPCAJA))' +
      '  LEFT JOIN fza_clientes cli' +
      '    ON cli.CODIGO_CLI_CLI = COALESCE(NULLIF(f.CODIGO_CLI_FAC, ''''),' +
      '                                      o.CODIGO_CLI_OPCAJA)' +
      '  LEFT JOIN fza_empresas emp' +
      '    ON emp.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA' +
      ' WHERE o.CODIGO_EMP_OPCAJA = :EMP' +
      '   AND o.CODIGO_ALM_OPCAJA = :ALM' +
      '   AND o.CODIGO_CAJA_OPCAJA = :CAJA' +
      '   AND o.NUMERO_OPERACION_OPCAJA = :OPERACION';
    Qry.ParamByName('EMP').AsString := AEmpresa;
    Qry.ParamByName('ALM').AsString := AAlmacen;
    Qry.ParamByName('CAJA').AsString := ACaja;
    Qry.ParamByName('OPERACION').AsString := ANumeroOperacion;
    Qry.Open;
    Result.Encontrada := Qry.FieldByName('NUM_FILAS').AsInteger > 0;
    if Result.Encontrada then
    begin
      Result.CodigoCliente :=
        Qry.FieldByName('CODIGO_CLIENTE').AsString;
      Result.EmailCliente := Trim(
        Qry.FieldByName('EMAIL_CLIENTE').AsString);
      Result.NombreEmpresa := Trim(
        Qry.FieldByName('NOMBRE_EMPRESA').AsString);
      Result.TieneFactura :=
        Qry.FieldByName('NUM_FACTURAS').AsInteger > 0;
      Result.TieneDepositos :=
        Qry.FieldByName('NUM_DEPOSITOS').AsInteger > 0;
      sTipos := ',' + Qry.FieldByName('TIPOS_OPERACION').AsString + ',';
      Result.EsOperacionCaja := (Pos(',EC,', sTipos) > 0) or
        (Pos(',GC,', sTipos) > 0);
      Result.EsTraspaso := (Pos(',TR,', sTipos) > 0) or
        (Pos(',TA,', sTipos) > 0);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function MensajeRespuestaServidor(const ATexto: string;
  AEstado: Integer): string;
var
  Json: TJSONValue;
  Valor: TJSONValue;
begin
  Result := '';
  Json := TJSONObject.ParseJSONValue(ATexto);
  try
    if Assigned(Json) then
    begin
      Valor := Json.FindValue('error.mensaje');
      if Assigned(Valor) then
        Result := Valor.Value;
      if Result = '' then
      begin
        Valor := Json.FindValue('message');
        if Assigned(Valor) then
          Result := Valor.Value;
      end;
    end;
  finally
    FreeAndNil(Json);
  end;
  if Result = '' then
    Result := Format('El servidor respondió con código %d.', [AEstado]);
end;

procedure GenerarDocumentos(
  const AParametrosApp: IParametrosAplicacion;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string; const ADatos: TDatosCorreoOperacion;
  ARutasPDF: TStrings);
begin
  if ADatos.EsTraspaso then
    TTraspasoTicket.ImprimirTraspasoDesdeBD(
      ARepositorioTraspaso,
      AEmpresa,
      AAlmacen,
      ACaja,
      ANumeroOperacion,
      'DEBUG',
      ARutasPDF,
      True)
  else
  begin
    if ADatos.TieneFactura then
      ImprimirTicketDesdeBD(AParametrosApp, AConexion, AEmpresa, AAlmacen,
        ACaja,
        ANumeroOperacion, 'DEBUG', ARutasPDF, True);
    if ADatos.TieneDepositos then
      ImprimirResguardoDeposito(AConexion, AEmpresa, AAlmacen, ACaja,
        ANumeroOperacion, 'DEBUG', ARutasPDF, True);
    if ADatos.EsOperacionCaja then
      ImprimirTicketOperacionCaja(AConexion, AEmpresa, AAlmacen, ACaja,
        ANumeroOperacion, 'DEBUG', ARutasPDF, True);
    if (ARutasPDF.Count > 0) and (Trim(ADatos.CodigoCliente) <> '') then
      ImprimirRecordatorio(AConexion, AEmpresa, ADatos.CodigoCliente, 'DEBUG',
        ARutasPDF, True);
  end;
end;

function EnviarAlServicio(const AUrl, AApiKey, AReferencia, AOperacion,
  AEmpresa, AEmail: string; ARutasPDF: TStrings;
  out AMensaje: string): Boolean;
var
  Http: THTTPClient;
  Formulario: TMultipartFormData;
  Respuesta: TStringStream;
  ResultadoHttp: IHTTPResponse;
  i: Integer;
begin
  Http := THTTPClient.Create;
  Formulario := TMultipartFormData.Create;
  Respuesta := TStringStream.Create('', TEncoding.UTF8);
  try
    Http.ConnectionTimeout := 15000;
    Http.ResponseTimeout := 60000;
    Http.CustomHeaders['X-API-Key'] := AApiKey;
    Formulario.AddField('referencia', AReferencia);
    Formulario.AddField('destinatario', AEmail);
    Formulario.AddField('operacion', AOperacion);
    Formulario.AddField('nombre_empresa', AEmpresa);
    for i := 0 to ARutasPDF.Count - 1 do
      Formulario.AddFile('documentos[]', ARutasPDF[i], 'application/pdf');
    ResultadoHttp := Http.Post(AUrl, Formulario, Respuesta);
    Result := ResultadoHttp.StatusCode = 200;
    if Result then
      AMensaje := Format('Correo enviado a %s con %d documento(s).',
        [AEmail, ARutasPDF.Count])
    else
      AMensaje := MensajeRespuestaServidor(Respuesta.DataString,
        ResultadoHttp.StatusCode);
  finally
    FreeAndNil(Respuesta);
    FreeAndNil(Formulario);
    FreeAndNil(Http);
  end;
end;

function EnviarDocumentacionOperacion(
  const AParametrosApp: IParametrosAplicacion;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, ANumeroOperacion, AEmail: string;
  out AMensaje: string): Boolean;
var
  Datos: TDatosCorreoOperacion;
  RutasPDF: TStringList;
  sUrl: string;
  sApiKey: string;
  sReferencia: string;
  i: Integer;
begin
  Result := False;
  AMensaje := '';
  if CorreoTicketsConfigurado(AParametrosApp, AMensaje) then
  begin
    if Trim(AEmail) = '' then
      AMensaje := 'Indique una dirección de correo electrónico.'
    else
    begin
      Datos := ObtenerDatosCorreoOperacion(AConexion, AEmpresa, AAlmacen, ACaja,
        ANumeroOperacion);
      if not Datos.Encontrada then
        AMensaje := 'No se ha encontrado la operación seleccionada.'
      else
      begin
        RutasPDF := TStringList.Create;
        try
          try
            GenerarDocumentos(
              AParametrosApp,
              ARepositorioTraspaso,
              AConexion,
              AEmpresa,
              AAlmacen,
              ACaja,
              ANumeroOperacion,
              Datos,
              RutasPDF);
            if RutasPDF.Count = 0 then
              AMensaje := 'La operación no tiene documentación asociada.'
            else
            begin
              sUrl := TClienteFactuzamApi.ComponerUrl(
                AParametrosApp,
                cRutaCorreo);
              sApiKey := TClienteFactuzamApi.Token(AParametrosApp);
              sReferencia :=
                TClienteFactuzamApi.Referencia(AParametrosApp);
              Result := EnviarAlServicio(sUrl, sApiKey, sReferencia,
                ANumeroOperacion, Datos.NombreEmpresa, Trim(AEmail),
                RutasPDF, AMensaje);
            end;
          except
            on E: Exception do
            begin
              AMensaje := 'No se pudo enviar la documentación: ' + E.Message;
              if Log() <> nil then
                Log.LogError('Correo de operación ' + ANumeroOperacion +
                  ': ' + E.Message);
            end;
          end;
        finally
          for i := 0 to RutasPDF.Count - 1 do
          begin
            if FileExists(RutasPDF[i]) then
              DeleteFile(RutasPDF[i]);
          end;
          FreeAndNil(RutasPDF);
        end;
      end;
    end;
  end;
end;

end.
