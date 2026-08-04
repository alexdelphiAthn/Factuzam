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
  inLibTraspasoTicketIntf, inLibTicketsCajaIntf,
  inLibUnidadesMedida, inLibPreviewTicket, inLibLogIntf;

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
function EnviarDocumentacionOperacion(
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  const ARepositorioTicketsCaja: TRepositoriosTicketsCaja;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  const ADatos: TDatosCorreoOperacion;
  const AEmpresa, AAlmacen, ACaja, ANumeroOperacion, AEmail: string;
  out AMensaje: string): Boolean;

implementation

uses
  System.Classes, System.JSON, System.Net.HttpClient, System.Net.Mime,
  inLibGenerarTicketBD, inLibGenerarTicketCaja,
  inLibTraspasoTicket, inLibFactuzamApi;

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
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  const ARepositorioTicketsCaja: TRepositoriosTicketsCaja;
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string; const ADatos: TDatosCorreoOperacion;
  ARutasPDF: TStrings);
begin
  if ADatos.EsTraspaso then
    TTraspasoTicket.ImprimirTraspasoDesdeBD(
      APreviewTicket,
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
      ImprimirTicketDesdeBD(
        AParametrosApp,
        APreviewTicket,
        AUnidades,
        ARepositorioTicketsCaja.Tickets,
        AEmpresa,
        AAlmacen,
        ACaja,
        ANumeroOperacion,
        'DEBUG',
        ARutasPDF,
        True);
    if ADatos.TieneDepositos then
      ImprimirResguardoDeposito(
        APreviewTicket,
        ARepositorioTicketsCaja.Resguardos,
        AEmpresa,
        AAlmacen,
        ACaja,
        ANumeroOperacion,
        'DEBUG',
        ARutasPDF,
        True);
    if ADatos.EsOperacionCaja then
      ImprimirTicketOperacionCaja(
        APreviewTicket, AConexion, ARepositorioTicketsCaja.Impresion,
        AEmpresa, AAlmacen, ACaja,
        ANumeroOperacion, 'DEBUG', ARutasPDF, True);
    if (ARutasPDF.Count > 0) and (Trim(ADatos.CodigoCliente) <> '') then
      ImprimirRecordatorio(
        APreviewTicket,
        ARepositorioTicketsCaja.Recordatorios,
        AEmpresa,
        ADatos.CodigoCliente,
        'DEBUG',
        ARutasPDF,
        True);
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
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  const ARepositorioTicketsCaja: TRepositoriosTicketsCaja;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  const ADatos: TDatosCorreoOperacion;
  const AEmpresa, AAlmacen, ACaja, ANumeroOperacion, AEmail: string;
  out AMensaje: string): Boolean;
var
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
      if not ADatos.Encontrada then
        AMensaje := 'No se ha encontrado la operación seleccionada.'
      else
      begin
        RutasPDF := TStringList.Create;
        try
          try
            GenerarDocumentos(
              AParametrosApp,
              APreviewTicket,
              AUnidades,
              ARepositorioTraspaso,
              ARepositorioTicketsCaja,
              AConexion,
              AEmpresa,
              AAlmacen,
              ACaja,
              ANumeroOperacion,
              ADatos,
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
                ANumeroOperacion, ADatos.NombreEmpresa, Trim(AEmail),
                RutasPDF, AMensaje);
            end;
          except
            on E: Exception do
            begin
              AMensaje := 'No se pudo enviar la documentación: ' + E.Message;
              ARegistroLog.RegistrarError(
                'Correo de operación ' + ANumeroOperacion + ': ' +
                E.Message);
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
