{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactu                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Núcleo del subsistema Verifactu (AEAT). Construcción de la URL de         }
{    cotejo del QR tributario (Orden HAC/1177/2024), helpers de formato y      }
{    registro de eventos encadenados por hash en fza_verifactu_eventos.        }
{******************************************************************************}
unit inLibVerifactu;

interface

uses
  System.SysUtils, Uni, frxClass, Data.DB, inLibParametrosIntf,
  inLibVerifactuTipos;

const
  cModoVerifactuSin = 'SIN';
  cModoVerifactuVerifactu = 'VERIFACTU';
  cModoVerifactuNoVerifactu = 'NO_VERIFACTU';
  cFaseFacturaBorrador = 'BORRADOR';
  cFaseFacturaSinVerifactu = 'SIN_VERIFACTU';
  cFaseFacturaSinVerifactuAnulada = 'SIN_VERIF_ANULADA';
  cFaseFacturaVerifactuPendiente = 'VERIFACTU_PENDIENTE';
  cFaseFacturaVerifactuOk = 'VERIFACTU_OK';
  cFaseFacturaVerifactuError = 'VERIFACTU_ERROR';
  cFaseFacturaVerifactuAnulada = 'VERIFACTU_ANULADA';
  cFaseFacturaNoVerifactuOk = 'NOVERIFACTU_OK';
  cFaseFacturaNoVerifactuAnulada = 'NOVERIFACTU_ANULADA';
  // URLs oficiales del servicio de cotejo del QR tributario. Se pueden
  // sobreescribir con los parámetros app*UrlQRPre / app*UrlQRPro.
  cVerifactuUrlQRPre =
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR';
  cVerifactuUrlQRPro =
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR';
  cNoVerifactuUrlQRPre =
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQRNoVerifactu';
  cNoVerifactuUrlQRPro =
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/' +
    'ValidarQRNoVerifactu';
  // Tipos de evento para TIPO_EVENTO_LOG de fza_verifactu_eventos.
  // Pendiente de unificar con el catálogo de tipos de OdaVeriFactu.
  cEventoVerifactuInfo       = 1;
  cEventoVerifactuEncolado   = 2;
  cEventoVerifactuEnvioOk    = 3;
  cEventoVerifactuEnvioError = 4;
  cEventoNoVerifactuInicio       = 101;
  cEventoNoVerifactuFin          = 102;
  cEventoNoVerifactuCambioConfig = 103;
  cEventoNoVerifactuExportFact   = 108;
  cEventoNoVerifactuExportEventos = 109;
  cEventoNoVerifactuIncidenciaCert = 110;
  cEventoNoVerifactuIncidenciaReloj = 111;

// Modo fiscal activo: SIN, VERIFACTU o NO_VERIFACTU.
// appVerifactuActivo=False fuerza SIN como interruptor maestro.
function ModoVerifactu(
  const AParametrosApp: IParametrosAplicacion): TModoVerifactu;
function ModoVerifactuTexto(
  const AParametrosApp: IParametrosAplicacion): string;
// True si el modo fiscal activo es VERIFACTU
function VerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// True si el modo fiscal activo es NO_VERIFACTU
function NoVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// True si el modo fiscal activo es SIN
function SinVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// True si se firman registros y eventos con certificado de empresa
function VerifactuFirmaCertificado(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// Impide emitir en modo fiscal si faltan el SIF o el certificado.
procedure ValidarRequisitosFiscalesEmision(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const ASerie, ANumero: string);
// 'PRE' (pruebas) o 'PRO' (producción) según appVerifactuEntorno
function VerifactuEntorno(
  const AParametrosApp: IParametrosAplicacion): string;
// Identificador serie+número que se comunica a la AEAT. DEBE coincidir
// con el NumSerieFactura del registro de facturación que se envíe.
function ComponerNumSerieFactura(const ASerie, ANumero: string): string;
// Importe con 2 decimales y punto como separador (formato QR y registro)
function FormatearImporteVerifactu(AImporte: Currency): string;
// NIF normalizado para Verifactu: solo letras y dígitos, en mayúsculas.
// El MISMO valor debe viajar en el QR y en el registro de facturación.
function NormalizarNifVerifactu(const AValor: string): string;
// URL completa de cotejo para el QR tributario del ticket / factura
function ConstruirUrlQR(
                        const AParametrosApp: IParametrosAplicacion;
                        const ANif, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
// PNG del QR tributario (ISO/IEC 18004:2015, corrección M) como bytes.
// Sin canvas ni handles GDI compartidos: usable desde el hilo de envío.
function GenerarQRPngVerifactu(const AUrl: string;
                               AEscala: Integer = 4): TBytes;
// FastReport: rellena el TfrxPictureView llamado 'qrverifactu' con el
// QR tributario de la factura del registro activo de su banda (campos
// NIF_EMPRESA_FAC, SERIE_FAC, NUMERO_FAC, FECHA_FAC,
// TOTAL_LIQUIDO_FAC). Encadenar desde TfrxReport.OnBeforePrint.
procedure SustituirQRVerifactuEnReport(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
// FastReport: si el formato cargado no trae un TfrxPictureView llamado
// 'qrverifactu', lo crea (30 mm, arriba a la derecha) dentro de la
// cabecera de página; los objetos sueltos en la página no reciben
// OnBeforePrint y el hueco quedaba sin rellenar. Si el diseñador ya lo
// colocó, se respeta su posición.
procedure AsegurarQRVerifactuEnReport(AReport: TfrxReport);
// FastReport: ajusta el memo de título de los formatos de factura
// ('FACTURA') al tipo del registro activo: FACTURA SIMPLIFICADA /
// FACTURA RECTIFICATIVA / FACTURA. Encadenar desde OnBeforePrint.
// Requiere que el dataset de cabecera lleve TIPO_FAC.
procedure SustituirTituloFacturaEnReport(Component: TfrxReportComponent);
// FastReport: vía fiable. En esta versión el OnBeforePrint NO llega a
// los objetos sueltos de las bandas estáticas (cabecera/pie/título de
// página), solo a las bandas y a los objetos de bandas de datos. El QR
// y el título 'FACTURA' viven en la cabecera de página, así que cuando
// se dispara una banda recorremos sus hijos y rellenamos el QR y el
// título con el registro de factura activo. Encadenar desde
// OnBeforePrint además de las dos anteriores.
procedure AplicarVerifactuEnBanda(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
// FastReport: rellena directamente (sin esperar a OnBeforePrint) el QR
// y el título de TODO el informe con el registro de ADataSet. Para una
// sola factura, llamar tras cargar el formato y antes de PrepareReport:
// el QR sale por defecto aunque el hueco quede suelto en la página.
procedure AplicarVerifactuEnReportDirecto(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          AReport: TfrxReport;
                                          ADataSet: TDataSet);
// FastReport (impresión de factura): fuerza, sea cual sea el formato
// cargado (base del .dfm o copia guardada en el diseñador), que el QR
// 'qrverifactu' viva en la banda de datos MasterData (visible) y lo
// rellena ahí. Un TfrxPictureView en una banda estática (cabecera de
// página) no se dibuja aunque se rellene; en banda de datos sí (igual
// que las fotos). Ajusta también el título por tipo.
procedure PrepararImpresionFacturaVerifactu(
                                            const AParametrosApp:
                                            IParametrosAplicacion;
                                            AReport: TfrxReport;
                                            ADataSet: TDataSet);
// Registra un evento en fza_verifactu_eventos manteniendo la cadena de
// hashes (HASH_ANTERIOR -> HASH_PROPIO). AConn puede ser la conexión
// global o la propia del hilo de la cola.
procedure RegistrarEventoVerifactu(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   AConn: TUniConnection;
                                   const AUsuario: string;
                                   ATipoEvento: Integer;
                                   const ADescripcion: string;
                                   const ADatosAdicionales: string = '';
                                   const ASerieFac: string = '';
                                   const ANumeroFac: string = '');

implementation

uses
  System.Classes, System.Hash, System.StrUtils,
  Vcl.Imaging.pngimage,
  DelphiZXIngQRCode, frxDBSet,
  inLibGlobalVar, inLibFotos, inLibXades,
  inLibMsgFacturas, inLibMsgVerifactu,
  inLibRelojFiscal, inLibVerifactuInstalacion,
  inLibVerifactuRegistroEventos;

type
  TRepositorioRegistroEventosUniDAC = class(
    TInterfacedObject,
    IRepositorioRegistroEventosVerifactu)
  private
    FParametrosApp: IParametrosAplicacion;
    FConexion: TUniConnection;
    procedure InicializarEmpresa(
      out ADatos: TEmpresaRegistroEventoVerifactu);
    procedure ConsultarEmpresa(
      var ADatos: TEmpresaRegistroEventoVerifactu);
    procedure ValidarEmpresa(
      const ADatos: TEmpresaRegistroEventoVerifactu);
    procedure PrepararSqlGuardar(
      AQry: TUniQuery;
      ATieneColumnasFirma: Boolean);
    procedure AsignarParametrosGuardar(
      AQry: TUniQuery;
      const ARegistro: TRegistroEventoVerifactu);
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      AConexion: TUniConnection);
    function TieneColumnasFirma: Boolean;
    function CargarEmpresa: TEmpresaRegistroEventoVerifactu;
    function CargarAnterior: TEventoAnteriorVerifactu;
    procedure Guardar(const ARegistro: TRegistroEventoVerifactu);
  end;

  TValidadorRelojRegistroEventos = class(
    TInterfacedObject,
    IValidadorRelojRegistroEventosVerifactu)
  private
    FParametrosApp: IParametrosAplicacion;
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion);
    procedure ExigirRelojFiscal;
  end;

  TFirmadorRegistroEventos = class(
    TInterfacedObject,
    IFirmadorRegistroEventosVerifactu)
  public
    function Firmar(
      const AXml, AHuella, ASerieCertificado,
      ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
  end;

function ExtraerEtiquetaXml(const AXml, AEtiqueta: string): string;
var
  iIni: Integer;
  iFin: Integer;
  sApertura: string;
  sCierre: string;
begin
  Result := '';
  sApertura := '<' + AEtiqueta + '>';
  sCierre := '</' + AEtiqueta + '>';
  iIni := Pos(sApertura, AXml);
  if iIni > 0 then
  begin
    iIni := iIni + Length(sApertura);
    iFin := PosEx(sCierre, AXml, iIni);
    if iFin > iIni then
      Result := Copy(AXml, iIni, iFin - iIni);
  end;
end;

constructor TRepositorioRegistroEventosUniDAC.Create(
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FConexion := AConexion;
end;

function TRepositorioRegistroEventosUniDAC.TieneColumnasFirma: Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_verifactu_eventos'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_LOG'', ' +
      '       ''FIRMA_XADES_LOG'', ''SERIE_CERTIFICADO_LOG'', ' +
      '       ''TITULAR_CERTIFICADO_LOG'', ''HUELLA_CERTIFICADO_LOG'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.InicializarEmpresa(
  out ADatos: TEmpresaRegistroEventoVerifactu);
begin
  ADatos := Default(TEmpresaRegistroEventoVerifactu);
  ADatos.NifProductor := NormalizarNifVerifactu(
    FParametrosApp.GetString('appVerifactuSifNif', ''));
  ADatos.NombreProductor := FParametrosApp.GetString(
    'appVerifactuSifNombreRazon', 'Alejandro Laorden Hidalgo');
  ADatos.EsMultiOt := 'N';
  if Length(ADatos.NifProductor) <> 9 then
    raise Exception.CreateFmt(
      SErrorNifProductorEventoVerifactuInvalido,
      [ADatos.NifProductor]);
end;

procedure TRepositorioRegistroEventosUniDAC.ConsultarEmpresa(
  var ADatos: TEmpresaRegistroEventoVerifactu);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT RAZON_SOCIAL_EMP, NIF_EMP, CODIGO_CERTIFICADO_EMP, ' +
      '        TITULAR_CERTIFICADO_EMP, NUMERO_INSTALACION_EMP, ' +
      '        VERSION_INSTALACION_EMP, CODIGO_SIF_INSTALACION_EMP, ' +
      '        (SELECT COUNT(*) FROM fza_empresas ' +
      '          WHERE ESACTIVO_EMP = ''S'') AS NUM_EMP ' +
      ' FROM fza_empresas ' +
      ' ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, ' +
      '          CODIGO_EMP_EMP ' +
      ' LIMIT 1';
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.Create(SErrorEmpresaEventosVerifactuNoConfigurada);
    ADatos.NombreObligado :=
      Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
    ADatos.NifObligado := NormalizarNifVerifactu(
      Qry.FieldByName('NIF_EMP').AsString);
    ADatos.SerialCertificado :=
      Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
    ADatos.TitularCertificado :=
      Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    ADatos.IdInstalacion :=
      Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
    ADatos.VersionInstalacion :=
      Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
    ADatos.CodigoSifInstalacion :=
      Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
    if Qry.FieldByName('NUM_EMP').AsInteger > 1 then
      ADatos.EsMultiOt := 'S';
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.ValidarEmpresa(
  const ADatos: TEmpresaRegistroEventoVerifactu);
begin
  if Length(ADatos.NifObligado) <> 9 then
    raise Exception.CreateFmt(SErrorNifEmisorEventoNoVerifactuInvalido,
      [ADatos.NifObligado]);
  ValidarInstalacionSif(ADatos.IdInstalacion,
                        ADatos.VersionInstalacion,
                        ADatos.CodigoSifInstalacion,
                        ADatos.NombreObligado,
                        ADatos.NifObligado);
end;

function TRepositorioRegistroEventosUniDAC.CargarEmpresa:
  TEmpresaRegistroEventoVerifactu;
begin
  InicializarEmpresa(Result);
  ConsultarEmpresa(Result);
  ValidarEmpresa(Result);
end;

function TRepositorioRegistroEventosUniDAC.CargarAnterior:
  TEventoAnteriorVerifactu;
var
  Qry: TUniQuery;
begin
  Result := Default(TEventoAnteriorVerifactu);
  Result.EsPrimero := True;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT TIPO_EVENTO_LOG, TIMESTAMP_LOG, HASH_PROPIO_LOG ' +
      ' FROM fza_verifactu_eventos ' +
      ' ORDER BY ID_LOG DESC ' +
      ' LIMIT 1';
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.EsPrimero := False;
      Result.TipoEvento :=
        Qry.FieldByName('TIPO_EVENTO_LOG').AsInteger;
      Result.Instante := Qry.FieldByName('TIMESTAMP_LOG').AsDateTime;
      Result.Huella := Qry.FieldByName('HASH_PROPIO_LOG').AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.PrepararSqlGuardar(
  AQry: TUniQuery;
  ATieneColumnasFirma: Boolean);
begin
  if ATieneColumnasFirma then
    AQry.SQL.Text :=
      ' INSERT INTO fza_verifactu_eventos ' +
      ' (TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, VERSION_LOG, ' +
      '  DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, HASH_ANTERIOR_LOG, ' +
      '  HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, NUMERO_FAC_LOG, ' +
      '  SERIE_FAC_LOG, REGISTRO_XML_LOG, FIRMA_XADES_LOG, ' +
      '  SERIE_CERTIFICADO_LOG, TITULAR_CERTIFICADO_LOG, ' +
      '  HUELLA_CERTIFICADO_LOG) VALUES ' +
      ' (:INSTANTE, :TIPO, :USUARIO, :VERSION, :DESCRIPCION, ' +
      '  NULLIF(:DATOS, ''''), :HASHANT, :HASHPROPIO, :FIRMA, ' +
      '  NULLIF(:NUMERO, ''''), NULLIF(:SERIE, ''''), :XML, ' +
      '  NULLIF(:FIRMAXADES, ''''), NULLIF(:SERIECERT, ''''), ' +
      '  NULLIF(:TITULARCERT, ''''), NULLIF(:HUELLACERT, ''''))'
  else
    AQry.SQL.Text :=
      ' INSERT INTO fza_verifactu_eventos ' +
      ' (TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, VERSION_LOG, ' +
      '  DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, HASH_ANTERIOR_LOG, ' +
      '  HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, NUMERO_FAC_LOG, ' +
      '  SERIE_FAC_LOG) VALUES ' +
      ' (:INSTANTE, :TIPO, :USUARIO, :VERSION, :DESCRIPCION, ' +
      '  NULLIF(:DATOS, ''''), :HASHANT, :HASHPROPIO, :FIRMA, ' +
      '  NULLIF(:NUMERO, ''''), NULLIF(:SERIE, ''''))';
end;

procedure TRepositorioRegistroEventosUniDAC.AsignarParametrosGuardar(
  AQry: TUniQuery;
  const ARegistro: TRegistroEventoVerifactu);
begin
  AQry.ParamByName('INSTANTE').AsString := ARegistro.Instante;
  AQry.ParamByName('TIPO').AsInteger := ARegistro.TipoEvento;
  AQry.ParamByName('USUARIO').AsString := ARegistro.Usuario;
  AQry.ParamByName('VERSION').AsString := ARegistro.Version;
  AQry.ParamByName('DESCRIPCION').AsString := ARegistro.Descripcion;
  AQry.ParamByName('DATOS').AsString := ARegistro.DatosAdicionales;
  AQry.ParamByName('HASHANT').AsString := ARegistro.HashAnterior;
  AQry.ParamByName('HASHPROPIO').AsString := ARegistro.HashPropio;
  AQry.ParamByName('FIRMA').AsString := ARegistro.FirmaDigital;
  AQry.ParamByName('NUMERO').AsString := ARegistro.NumeroFactura;
  AQry.ParamByName('SERIE').AsString := ARegistro.SerieFactura;
  if ARegistro.TieneColumnasFirma then
  begin
    AQry.ParamByName('XML').AsString := ARegistro.Xml;
    AQry.ParamByName('FIRMAXADES').AsString := ARegistro.FirmaXades;
    AQry.ParamByName('SERIECERT').AsString :=
      ARegistro.SerieCertificado;
    AQry.ParamByName('TITULARCERT').AsString :=
      ARegistro.TitularCertificado;
    AQry.ParamByName('HUELLACERT').AsString :=
      ARegistro.HuellaCertificado;
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.Guardar(
  const ARegistro: TRegistroEventoVerifactu);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    PrepararSqlGuardar(Qry, ARegistro.TieneColumnasFirma);
    AsignarParametrosGuardar(Qry, ARegistro);
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

constructor TValidadorRelojRegistroEventos.Create(
  const AParametrosApp: IParametrosAplicacion);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
end;

procedure TValidadorRelojRegistroEventos.ExigirRelojFiscal;
begin
  inLibRelojFiscal.ExigirRelojFiscal(
    FParametrosApp, 'Evento NO VERI*FACTU');
end;

function TFirmadorRegistroEventos.Firmar(
  const AXml, AHuella, ASerieCertificado,
  ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
var
  oDatosCertificado: TXadesDatosCertificado;
  oOpciones: TXadesOpciones;
begin
  oOpciones := OpcionesXadesNoVerifactu('FZ-EVENTO-' + AHuella);
  oOpciones.NombreNodoInsercionFirma := 'sf:Evento';
  oOpciones.FirmaSilenciosa := False;
  Result.XmlFirmado := FirmarXmlXadesEnveloped(
    AXml, ASerieCertificado, ATitularCertificado, oOpciones,
    oDatosCertificado);
  Result.FirmaXades := ExtraerEtiquetaXml(
    Result.XmlFirmado, 'ds:SignatureValue');
  Result.FirmaDigital := UpperCase(
    THashSHA2.GetHashString(Result.FirmaXades));
  Result.SerieCertificado := oDatosCertificado.NumeroSerie;
  Result.TitularCertificado := oDatosCertificado.Titular;
  Result.HuellaCertificado := oDatosCertificado.HuellaSha1;
end;

// True si el dataset tiene los campos de cabecera de factura que
// necesitan el QR y el título (vi_facturas / vi_facturas_print)
function TieneCamposFactura(ADataSet: TDataSet): Boolean;
begin
  Result := (ADataSet <> nil) and
            (ADataSet.FindField('NIF_EMPRESA_FAC') <> nil) and
            (ADataSet.FindField('SERIE_FAC') <> nil) and
            (ADataSet.FindField('NUMERO_FAC') <> nil) and
            (ADataSet.FindField('FECHA_FAC') <> nil) and
            (ADataSet.FindField('TOTAL_LIQUIDO_FAC') <> nil);
end;

// Dataset de cabecera de factura para un objeto del report: primero la
// banda padre; si el objeto cuelga de una banda sin datos (cabecera de
// página) o de la propia página, se busca entre los datasets del
// report el que tenga los campos de factura.
function DataSetFacturaDeReport(AObj: TfrxComponent): TDataSet;
var
  oReport: TfrxReport;
  oDs:     TDataSet;
  i:       Integer;
begin
  Result := ObtenerDataSetDeBandaPadre(AObj);
  if not TieneCamposFactura(Result) then
  begin
    Result := nil;
    oReport := AObj.Report;
    if oReport <> nil then
    begin
      for i := 0 to oReport.Datasets.Count - 1 do
      begin
        if (Result = nil) and
           (oReport.Datasets[i].DataSet is TfrxDBDataset) then
        begin
          oDs := TfrxDBDataset(oReport.Datasets[i].DataSet).DataSet;
          if TieneCamposFactura(oDs) then
            Result := oDs;
        end;
      end;
    end;
  end;
end;

function ModoVerifactuTexto(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if not AParametrosApp.GetBool('appVerifactuActivo', False) then
    Result := cModoVerifactuSin
  else
  begin
    Result := UpperCase(Trim(
      AParametrosApp.GetString('appVerifactuModo', '')));
    if Result = '' then
      Result := cModoVerifactuVerifactu
    else if (Result <> cModoVerifactuVerifactu) and
            (Result <> cModoVerifactuNoVerifactu) then
      Result := cModoVerifactuSin;
  end;
end;

function ModoVerifactu(
  const AParametrosApp: IParametrosAplicacion): TModoVerifactu;
var
  sModo: string;
begin
  sModo := ModoVerifactuTexto(AParametrosApp);
  if sModo = cModoVerifactuVerifactu then
    Result := mvVerifactu
  else if sModo = cModoVerifactuNoVerifactu then
    Result := mvNoVerifactu
  else
    Result := mvSinVerifactu;
end;

function VerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvVerifactu;
end;

function NoVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvNoVerifactu;
end;

function SinVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvSinVerifactu;
end;

function VerifactuFirmaCertificado(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result :=
    AParametrosApp.GetBool('appVerifactuFirmaCertificado', False);
end;

procedure ValidarRequisitosFiscalesEmision(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
  sCodigoEmpresa: string;
  sCodigoSif: string;
  sNombreEmpresa: string;
  sNifEmpresa: string;
  sNifProductor: string;
  sNumeroInstalacion: string;
  sSerialCertificado: string;
  sTitularCertificado: string;
  sVersionInstalacion: string;
begin
  if not SinVerifactuActivo(AParametrosApp) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' SELECT f.CODIGO_EMP_FAC, e.RAZON_SOCIAL_EMP, e.NIF_EMP, ' +
        '        e.NUMERO_INSTALACION_EMP, e.VERSION_INSTALACION_EMP, ' +
        '        e.CODIGO_SIF_INSTALACION_EMP, ' +
        '        e.CODIGO_CERTIFICADO_EMP, e.TITULAR_CERTIFICADO_EMP ' +
        ' FROM fza_facturas f ' +
        ' LEFT JOIN fza_empresas e ' +
        '   ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
        ' WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Open;
      if Qry.IsEmpty then
        raise Exception.CreateFmt(SErrorFacturaRequisitosFiscalesNoExiste,
          [ASerie, ANumero]);
      sCodigoEmpresa :=
        Trim(Qry.FieldByName('CODIGO_EMP_FAC').AsString);
      sNombreEmpresa :=
        Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
      sNifEmpresa := NormalizarNifVerifactu(
        Qry.FieldByName('NIF_EMP').AsString);
      sNumeroInstalacion :=
        Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
      sVersionInstalacion :=
        Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
      sCodigoSif :=
        Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
      sSerialCertificado :=
        Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
      sTitularCertificado :=
        Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    finally
      FreeAndNil(Qry);
    end;
    if sNombreEmpresa = '' then
      sNombreEmpresa := sCodigoEmpresa;
    if Length(sNifEmpresa) <> 9 then
      raise Exception.CreateFmt(SErrorEmpresaSinNifEmisionFiscal,
        [sNombreEmpresa]);
    sNifProductor := NormalizarNifVerifactu(
      AParametrosApp.GetString('appVerifactuSifNif', ''));
    if Length(sNifProductor) <> 9 then
      raise Exception.Create(SErrorNifProductorVerifactuInvalido);
    ValidarInstalacionSif(sNumeroInstalacion, sVersionInstalacion,
      sCodigoSif, sNombreEmpresa, sNifEmpresa);
    try
      ValidarCertificadoXades(sSerialCertificado,
        sTitularCertificado);
    except
      on E: Exception do
        raise Exception.CreateFmt(SErrorCertificadoFiscalEmpresaNoUtilizable,
          [sNombreEmpresa, E.Message]);
    end;
    if NoVerifactuActivo(AParametrosApp) and
       (not VerifactuFirmaCertificado(AParametrosApp)) then
      raise Exception.Create(SErrorFirmaCertificadoNoVerifactuDesactivada);
  end;
end;

function VerifactuEntorno(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := UpperCase(Trim(
    AParametrosApp.GetString('appVerifactuEntorno', 'PRE')));
  if Result <> 'PRO' then
    Result := 'PRE';
end;

function ComponerNumSerieFactura(const ASerie, ANumero: string): string;
begin
  // Concatenación simple serie+número. Si OdaVeriFactu compone distinto
  // el identificador, ajustar SOLO aquí: el QR y el registro enviado a
  // la AEAT deben llevar exactamente el mismo valor.
  Result := Trim(ASerie) + Trim(ANumero);
end;

function FormatearImporteVerifactu(AImporte: Currency): string;
var
  oFmt: TFormatSettings;
begin
  oFmt := TFormatSettings.Create;
  oFmt.DecimalSeparator  := '.';
  oFmt.ThousandSeparator := #0;
  Result := FormatFloat('0.00', AImporte, oFmt);
end;

function NormalizarNifVerifactu(const AValor: string): string;
var
  cActual: Char;
begin
  Result := '';
  for cActual in UpperCase(Trim(AValor)) do
  begin
    if ((cActual >= 'A') and (cActual <= 'Z')) or
       ((cActual >= '0') and (cActual <= '9')) then
      Result := Result + cActual;
  end;
end;

// Percent-encode de un valor de parámetro de URL (RFC 3986): solo quedan
// sin codificar los caracteres no reservados.
function CodificarParametroURL(const AValor: string): string;
var
  aBytes:   TBytes;
  iOcteto:  Byte;
  oSalida:  TStringBuilder;
begin
  oSalida := TStringBuilder.Create;
  try
    aBytes := TEncoding.UTF8.GetBytes(AValor);
    for iOcteto in aBytes do
    begin
      if ((iOcteto >= Ord('A')) and (iOcteto <= Ord('Z'))) or
         ((iOcteto >= Ord('a')) and (iOcteto <= Ord('z'))) or
         ((iOcteto >= Ord('0')) and (iOcteto <= Ord('9'))) or
         (iOcteto = Ord('-')) or (iOcteto = Ord('.')) or
         (iOcteto = Ord('_')) or (iOcteto = Ord('~')) then
        oSalida.Append(Char(iOcteto))
      else
        oSalida.Append('%' + IntToHex(iOcteto, 2));
    end;
    Result := oSalida.ToString;
  finally
    FreeAndNil(oSalida);
  end;
end;

function ConstruirUrlQR(
                        const AParametrosApp: IParametrosAplicacion;
                        const ANif, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
var
  sBase: string;
begin
  if VerifactuEntorno(AParametrosApp) = 'PRO' then
  begin
    if NoVerifactuActivo(AParametrosApp) then
      sBase := AParametrosApp.GetString('appNoVerifactuUrlQRPro',
                                    cNoVerifactuUrlQRPro)
    else
      sBase := AParametrosApp.GetString('appVerifactuUrlQRPro',
                                    cVerifactuUrlQRPro);
  end
  else
  begin
    if NoVerifactuActivo(AParametrosApp) then
      sBase := AParametrosApp.GetString('appNoVerifactuUrlQRPre',
                                    cNoVerifactuUrlQRPre)
    else
      sBase := AParametrosApp.GetString('appVerifactuUrlQRPre',
                                    cVerifactuUrlQRPre);
  end;
  // Formato fijado por la AEAT (documento técnico del QR tributario):
  // nif, numserie, fecha dd-mm-aaaa e importe total con punto decimal
  Result := sBase +
    '?nif='      + CodificarParametroURL(NormalizarNifVerifactu(ANif)) +
    '&numserie=' + CodificarParametroURL(
                     ComponerNumSerieFactura(ASerie, ANumero)) +
    '&fecha='    + CodificarParametroURL(
                     FormatDateTime('dd-mm-yyyy', AFecha)) +
    '&importe='  + CodificarParametroURL(
                     FormatearImporteVerifactu(AImporteTotal));
end;

function GenerarQRPngVerifactu(const AUrl: string;
                               AEscala: Integer = 4): TBytes;
var
  oQR:     TDelphiZXIngQRCode;
  oPng:    TPngImage;
  oStream: TMemoryStream;
  iX:      Integer;
  iY:      Integer;
  pLinea:  PByteArray;
begin
  SetLength(Result, 0);
  if (Trim(AUrl) <> '') and (AEscala >= 1) then
  begin
    oQR     := TDelphiZXIngQRCode.Create;
    oPng    := nil;
    oStream := nil;
    try
      oQR.ErrorCorrectionLevel := qreM;
      oQR.Encoding             := qrUTF8NoBOM;
      oQR.QuietZone            := 4;
      oQR.Data                 := AUrl;
      // RGB (24 bits), no escala de grises: el TfrxPictureView de
      // FastReport y la hoja dxSpreadSheet pintan PNG RGB con fiabilidad
      // (las fotos, que sí se ven, son RGB); el gris se mostraba bien
      // solo en el visor VCL (TcxDBImage de la ficha) pero no en el A4.
      oPng := TPngImage.CreateBlank(COLOR_RGB, 8,
                                    oQR.Columns * AEscala,
                                    oQR.Rows * AEscala);
      for iY := 0 to oPng.Height - 1 do
      begin
        pLinea := oPng.Scanline[iY];
        for iX := 0 to oPng.Width - 1 do
        begin
          if oQR.IsBlack[iY div AEscala, iX div AEscala] then
          begin
            pLinea[iX * 3]     := 0;
            pLinea[iX * 3 + 1] := 0;
            pLinea[iX * 3 + 2] := 0;
          end
          else
          begin
            pLinea[iX * 3]     := 255;
            pLinea[iX * 3 + 1] := 255;
            pLinea[iX * 3 + 2] := 255;
          end;
        end;
      end;
      oStream := TMemoryStream.Create;
      oPng.SaveToStream(oStream);
      SetLength(Result, oStream.Size);
      if oStream.Size > 0 then
        Move(oStream.Memory^, Result[0], oStream.Size);
    finally
      FreeAndNil(oStream);
      FreeAndNil(oPng);
      FreeAndNil(oQR);
    end;
  end;
end;

// Rellena un TfrxPictureView con el QR tributario de la factura del
// dataset dado (vacío en modo SIN o si faltan datos)
procedure RellenarQRPicture(
  const AParametrosApp: IParametrosAplicacion;
  APic: TfrxPictureView;
  ADataSet: TDataSet);
var
  aPng:    TBytes;
  oPng:    TPngImage;
  oStream: TBytesStream;
  sUrl:    string;
begin
  sUrl := '';
  if (not SinVerifactuActivo(AParametrosApp)) and
     TieneCamposFactura(ADataSet) and
     (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') then
    sUrl := ConstruirUrlQR(
              AParametrosApp,
              ADataSet.FieldByName('NIF_EMPRESA_FAC').AsString,
              ADataSet.FieldByName('SERIE_FAC').AsString,
              ADataSet.FieldByName('NUMERO_FAC').AsString,
              ADataSet.FieldByName('FECHA_FAC').AsDateTime,
              ADataSet.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency);
  if sUrl = '' then
    APic.Picture.Assign(nil)
  else
  begin
    aPng := GenerarQRPngVerifactu(sUrl);
    oPng := TPngImage.Create;
    oStream := TBytesStream.Create(aPng);
    try
      oPng.LoadFromStream(oStream);
      APic.Picture.Assign(oPng);
    finally
      FreeAndNil(oStream);
      FreeAndNil(oPng);
    end;
  end;
end;

// Ajusta el memo de título 'FACTURA' al tipo del dataset (SIMPLIFICADA
// / RECTIFICATIVA / normal). Solo actúa sobre el memo de título.
procedure AjustarTituloMemo(AMemo: TfrxMemoView; ADataSet: TDataSet);
var
  sTexto: string;
  sTipo:  string;
begin
  sTexto := UpperCase(Trim(AMemo.Text));
  if ((sTexto = 'FACTURA') or
      (sTexto = 'FACTURA SIMPLIFICADA') or
      (sTexto = 'FACTURA RECTIFICATIVA')) and
     (ADataSet <> nil) and
     (ADataSet.FindField('TIPO_FAC') <> nil) then
  begin
    sTipo := UpperCase(Trim(ADataSet.FieldByName('TIPO_FAC').AsString));
    if sTipo = 'SIMPLIFICADA' then
      AMemo.Text := 'FACTURA SIMPLIFICADA'
    else if sTipo = 'RECTIFICATIVA' then
      AMemo.Text := 'FACTURA RECTIFICATIVA'
    else
      AMemo.Text := 'FACTURA';
  end;
end;

procedure SustituirQRVerifactuEnReport(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
begin
  if (Component is TfrxPictureView) and
     SameText(Component.Name, 'qrverifactu') then
    RellenarQRPicture(AParametrosApp, TfrxPictureView(Component),
                      DataSetFacturaDeReport(Component));
end;

// Memo de título 'FACTURA' en cualquier nivel del árbol (recursivo)
function BuscarMemoTitulo(AComp: TfrxComponent): TfrxMemoView;
var
  i: Integer;
  s: string;
begin
  Result := nil;
  if AComp <> nil then
  begin
    if AComp is TfrxMemoView then
    begin
      s := UpperCase(Trim(TfrxMemoView(AComp).Text));
      if (s = 'FACTURA') or
         (s = 'FACTURA SIMPLIFICADA') or
         (s = 'FACTURA RECTIFICATIVA') then
        Result := TfrxMemoView(AComp);
    end;
    if Result = nil then
    begin
      for i := 0 to AComp.Objects.Count - 1 do
      begin
        if Result = nil then
          Result := BuscarMemoTitulo(TfrxComponent(AComp.Objects[i]));
      end;
    end;
  end;
end;

// Primera banda de un tipo concreto entre los hijos directos de la página
function PrimeraBanda(APage: TfrxReportPage; AClase: TClass): TfrxBand;
var
  j: Integer;
begin
  Result := nil;
  for j := 0 to APage.Objects.Count - 1 do
  begin
    if (Result = nil) and (TObject(APage.Objects[j]).InheritsFrom(AClase)) then
      Result := TfrxBand(APage.Objects[j]);
  end;
end;

procedure AsegurarQRVerifactuEnReport(AReport: TfrxReport);
var
  i:      Integer;
  oPage:  TfrxReportPage;
  oBanda: TfrxBand;
  oMemo:  TfrxMemoView;
  oParent: TfrxComponent;
  oPic:   TfrxPictureView;
  dLado:  Extended;
  dBase:  Extended;
begin
  if (AReport <> nil) and (AReport.FindObject('qrverifactu') = nil) then
  begin
    oPage := nil;
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if (oPage = nil) and (AReport.Pages[i] is TfrxReportPage) then
        oPage := TfrxReportPage(AReport.Pages[i]);
    end;
    if oPage <> nil then
    begin
      // El QR debe alojarse DENTRO de una banda imprimible. La más
      // segura es la del memo de título 'FACTURA' (existe y se imprime);
      // si no, cabecera de página / título de informe / banda de datos.
      oBanda := nil;
      oMemo  := BuscarMemoTitulo(oPage);
      if oMemo <> nil then
      begin
        oParent := oMemo.Parent;
        while (oParent <> nil) and (not (oParent is TfrxBand)) do
          oParent := oParent.Parent;
        if oParent is TfrxBand then
          oBanda := TfrxBand(oParent);
      end;
      if oBanda = nil then
        oBanda := PrimeraBanda(oPage, TfrxPageHeader);
      if oBanda = nil then
        oBanda := PrimeraBanda(oPage, TfrxReportTitle);
      if oBanda = nil then
        oBanda := PrimeraBanda(oPage, TfrxDataBand);
      // 30 mm (mínimo AEAT 30x30). fr01cm = 1 mm en unidades del informe.
      dLado := 30 * fr01cm;
      if oBanda <> nil then
      begin
        oPic := TfrxPictureView.Create(oBanda);
        // CLAVE: sin Parent, FastReport NO dibuja el objeto aunque
        // exista (el memo de título sí se dibuja porque ya lo trae)
        oPic.Parent := oBanda;
        dBase := oBanda.Width;
        if dBase <= 0 then
          dBase := oPage.Width;
        if oBanda.Height < dLado then
          oBanda.Height := dLado;
      end
      else
      begin
        oPic := TfrxPictureView.Create(oPage);
        oPic.Parent := oPage;
        dBase := oPage.Width;
      end;
      oPic.Name    := 'qrverifactu';
      oPic.SetBounds(dBase - dLado, 0, dLado, dLado);
      oPic.Center  := True;
      oPic.KeepAspectRatio := True;
    end;
  end;
end;

procedure SustituirTituloFacturaEnReport(Component: TfrxReportComponent);
begin
  if Component is TfrxMemoView then
    AjustarTituloMemo(TfrxMemoView(Component),
                      DataSetFacturaDeReport(Component));
end;

// Recorre recursivamente los hijos de una banda aplicando el QR y el
// título a los que correspondan, con el registro de factura activo
procedure AplicarVerifactuARama(
  const AParametrosApp: IParametrosAplicacion;
  AComp: TfrxComponent;
  ADataSet: TDataSet);
var
  i:    Integer;
  oPic: TfrxPictureView;
begin
  if AComp <> nil then
  begin
    if AComp is TfrxPictureView then
    begin
      oPic := TfrxPictureView(AComp);
      if SameText(oPic.Name, 'qrverifactu') then
        RellenarQRPicture(AParametrosApp, oPic, ADataSet);
      // Los formatos antiguos enlazan el QR almacenado directamente al
      // campo QRCODE_PNG_FACCON. Al reimprimir, FastReport vuelve a cargar
      // ese PNG aunque el SIF esté desactivado. Se elimina también el enlace
      // para que la preparación posterior del informe no lo reponga.
      if SinVerifactuActivo(AParametrosApp) and
         SameText(oPic.DataField, 'QRCODE_PNG_FACCON') then
      begin
        oPic.Visible := False;
        oPic.DataField := '';
        oPic.DataSet := nil;
        oPic.Picture.Assign(nil);
      end;
    end;
    if AComp is TfrxMemoView then
      AjustarTituloMemo(TfrxMemoView(AComp), ADataSet);
    for i := 0 to AComp.Objects.Count - 1 do
      AplicarVerifactuARama(
        AParametrosApp,
        TfrxComponent(AComp.Objects[i]),
        ADataSet);
  end;
end;

procedure AplicarVerifactuEnBanda(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
var
  oDataSet: TDataSet;
begin
  if Component is TfrxBand then
  begin
    oDataSet := DataSetFacturaDeReport(Component);
    if TieneCamposFactura(oDataSet) then
      AplicarVerifactuARama(AParametrosApp, Component, oDataSet);
  end;
end;

procedure AplicarVerifactuEnReportDirecto(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          AReport: TfrxReport;
                                          ADataSet: TDataSet);
var
  i:    Integer;
  oObj: TfrxComponent;
begin
  // Relleno directo, sin esperar a OnBeforePrint. Para una sola factura
  // (vista previa / impresión / PDF) el QR y el título salen por defecto.
  if (AReport <> nil) and TieneCamposFactura(ADataSet) then
  begin
    // El QR por nombre (FindObject recorre todo el informe; más fiable
    // que la jerarquía Objects para un objeto recién cargado)
    oObj := AReport.FindObject('qrverifactu');
    if oObj is TfrxPictureView then
      RellenarQRPicture(
        AParametrosApp,
        TfrxPictureView(oObj),
        ADataSet);
    // El título recorriendo los memos de cada página
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if AReport.Pages[i] is TfrxReportPage then
        AplicarVerifactuARama(
          AParametrosApp,
          TfrxReportPage(AReport.Pages[i]),
          ADataSet);
    end;
  end;
end;

procedure PrepararImpresionFacturaVerifactu(
                                            const AParametrosApp:
                                            IParametrosAplicacion;
                                            AReport: TfrxReport;
                                            ADataSet: TDataSet);
var
  oPage:  TfrxReportPage;
  oBanda: TfrxBand;
  oComp:  TfrxComponent;
  oQr:    TfrxPictureView;
  i:      Integer;
  dLado:  Extended;
begin
  if (AReport <> nil) and TieneCamposFactura(ADataSet) then
  begin
    oPage := nil;
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if (oPage = nil) and (AReport.Pages[i] is TfrxReportPage) then
        oPage := TfrxReportPage(AReport.Pages[i]);
    end;
    if oPage <> nil then
    begin
      // Banda de DATOS donde el picture sí se dibuja (MasterData =
      // una sola salida por factura). La hacemos visible por si el
      // formato la trae oculta (caso del .dfm original).
      oBanda := PrimeraBanda(oPage, TfrxMasterData);
      dLado  := 30 * fr01cm;
      if oBanda <> nil then
      begin
        oBanda.Visible := True;
        if oBanda.Height < dLado then
          oBanda.Height := dLado;
        // El QR puede venir en otra banda (cabecera) si se cargó una
        // copia guardada: lo reubicamos a la banda de datos.
        oComp := AReport.FindObject('qrverifactu');
        if oComp is TfrxPictureView then
          oQr := TfrxPictureView(oComp)
        else
        begin
          oQr := TfrxPictureView.Create(oBanda);
          oQr.Name := 'qrverifactu';
        end;
        oQr.Parent := oBanda;
        oQr.SetBounds(oBanda.Width - dLado, 0, dLado, dLado);
        oQr.Stretched := True;
        RellenarQRPicture(AParametrosApp, oQr, ADataSet);
      end;
    end;
    // Título por tipo (recorre los memos de todas las páginas)
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if AReport.Pages[i] is TfrxReportPage then
        AplicarVerifactuARama(
          AParametrosApp,
          TfrxReportPage(AReport.Pages[i]),
          ADataSet);
    end;
  end;
end;

procedure RegistrarEventoVerifactu(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   AConn: TUniConnection;
                                   const AUsuario: string;
                                   ATipoEvento: Integer;
                                   const ADescripcion: string;
                                   const ADatosAdicionales: string;
                                   const ASerieFac: string;
                                   const ANumeroFac: string);
var
  oFirmador: IFirmadorRegistroEventosVerifactu;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: IRepositorioRegistroEventosVerifactu;
  oValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
begin
  oSolicitud.EsNoVerifactu := NoVerifactuActivo(AParametrosApp);
  oSolicitud.FirmarCertificado :=
    VerifactuFirmaCertificado(AParametrosApp);
  oSolicitud.InstanteRegistro := Now;
  oSolicitud.InstanteEvento := Now;
  oSolicitud.Version := oVersion;
  oSolicitud.Usuario := AUsuario;
  oSolicitud.TipoEvento := ATipoEvento;
  oSolicitud.Descripcion := ADescripcion;
  oSolicitud.DatosAdicionales := ADatosAdicionales;
  oSolicitud.SerieFactura := ASerieFac;
  oSolicitud.NumeroFactura := ANumeroFac;
  oRepositorio := TRepositorioRegistroEventosUniDAC.Create(
    AParametrosApp, AConn);
  oValidadorReloj := TValidadorRelojRegistroEventos.Create(
    AParametrosApp);
  oFirmador := TFirmadorRegistroEventos.Create;
  oRegistro := CrearRegistroEventosVerifactu(
    oRepositorio, oValidadorReloj, oFirmador);
  oRegistro.Registrar(oSolicitud);
end;

end.
