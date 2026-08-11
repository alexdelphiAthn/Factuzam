{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFacturacionTicketRepositorio                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para sustituir tickets por facturas normales.         }
{******************************************************************************}
unit UniDataFacturacionTicketRepositorio;

interface

uses
  Uni, inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibVerifactuColaIntf, inLibFacturacionTicketPersistenciaIntf;

function CrearServicioFacturacionTicketUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioCola: IServicioVerifactuCola
): IServicioFacturacionTicket;

implementation

uses
  System.SysUtils, Data.DB, inLibVerifactu, inLibMsgFacturas;

const
  SQL_CONSULTAR_CLIENTES =
    'SELECT CODIGO_CLI_CLI AS `Código`, ' +
    'RAZON_SOCIAL_CLI AS `Razón Social`, NIF_CLI AS `NIF Cliente`, ' +
    'MOVIL_CLI AS `Teléfono Cliente`, POBLACION_CLI AS `Población` ' +
    'FROM fza_clientes WHERE ESACTIVO_CLI = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_CLI';
  SQL_CONSULTAR_CLIENTE =
    'SELECT RAZON_SOCIAL_CLI, NIF_CLI, CODIGO_PAI_CLI, NOMBRE_PAI_CLI ' +
    'FROM fza_clientes WHERE CODIGO_CLI_CLI = :CLIENTE';
  SQL_INSERTAR_CABECERA =
    'INSERT INTO fza_facturas ' +
    '(NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, FASE_FAC, ' +
    'ESCONSOLIDADA_FAC, CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, ' +
    'NIF_EMPRESA_FAC, MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, ' +
    'DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC, ' +
    'POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'CODIGO_POSTAL_EMPRESA_FAC, ESRETENCIONES_EMPRESA_FAC, ' +
    'GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
    'CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, ' +
    'MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC, ' +
    'DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
    'POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, ' +
    'CODIGO_POSTAL_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
    'CODIGO_PAI_CLIENTE_FAC, CODIGO_OFICINA_CONTABLE_FAC, ' +
    'CODIGO_ORGANO_GESTOR_FAC, CODIGO_UNIDAD_TRAMITADORA_FAC, ' +
    'ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    'ESRETENCIONES_CLIENTE_FAC, TARIFA_ARTICULO_CLIENTE_FAC, ' +
    'ESIMP_INCL_TARIFA_CLIENTE_FAC, ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC, ESAPLICA_RE_ZONA_IVA_FAC, ' +
    'ESIVAAGRICOLA_ZONA_IVA_FAC, PALABRA_REPORTS_ZONA_IVA_FAC, ' +
    'CODIGO_IVA_FAC, ESVENTA_ACTIVO_FIJO_FAC, ' +
    'PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, ' +
    'TOTAL_REN_FAC, TOTAL_BASEI_IVAN_FAC, ' +
    'PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC, ' +
    'PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, ' +
    'TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC, ' +
    'PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, PORCENTAJE_REE_FAC, ' +
    'TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
    'TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, FORMA_PAGO_FAC, ' +
    'PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC, TOTAL_LIQUIDO_FAC, ' +
    'TEXTO_LEGAL_CLIENTE_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
    'COMENTARIOS_FAC, CONTADOR_LINEAS_FAC, ESCREARARTICULOS_FAC, ' +
    'ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC, ' +
    'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA, ''NORMAL'', ''BORRADOR'', ''N'', ' +
    't.CODIGO_EMP_FAC, t.RAZON_SOCIAL_EMPRESA_FAC, t.NIF_EMPRESA_FAC, ' +
    't.MOVIL_EMPRESA_FAC, t.EMAIL_EMPRESA_FAC, ' +
    't.DIRECCION1_EMPRESA_FAC, t.DIRECCION2_EMPRESA_FAC, ' +
    't.POBLACION_EMPRESA_FAC, t.PROVINCIA_EMPRESA_FAC, ' +
    't.NOMBRE_PAI_EMPRESA_FAC, t.CODIGO_PAI_EMPRESA_FAC, ' +
    't.CODIGO_POSTAL_EMPRESA_FAC, t.ESRETENCIONES_EMPRESA_FAC, ' +
    't.GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    't.ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
    'c.CODIGO_CLI_CLI, c.RAZON_SOCIAL_CLI, c.NIF_CLI, c.MOVIL_CLI, ' +
    'c.EMAIL_CLI, c.DIRECCION1_CLI, c.DIRECCION2_CLI, ' +
    'c.POBLACION_CLI, c.PROVINCIA_CLI, c.CODIGO_POSTAL_CLI, ' +
    'c.NOMBRE_PAI_CLI, c.CODIGO_PAI_CLI, ' +
    'c.CODIGO_OFICINA_CONTABLE_CLI, c.CODIGO_ORGANO_GESTOR_CLI, ' +
    'c.CODIGO_UNIDAD_TRAMITADORA_CLI, ' +
    't.ESIVA_RECARGO_CLIENTE_FAC, t.ESIVA_EXENTO_CLIENTE_FAC, ' +
    't.ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    't.ESRETENCIONES_CLIENTE_FAC, t.TARIFA_ARTICULO_CLIENTE_FAC, ' +
    't.ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
    't.ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
    't.ESIRPF_IMP_INCL_ZONA_IVA_FAC, t.ESAPLICA_RE_ZONA_IVA_FAC, ' +
    't.ESIVAAGRICOLA_ZONA_IVA_FAC, t.PALABRA_REPORTS_ZONA_IVA_FAC, ' +
    't.CODIGO_IVA_FAC, t.ESVENTA_ACTIVO_FIJO_FAC, ' +
    't.PORCENTAJE_IVAN_FAC, t.TOTAL_IVAN_FAC, ' +
    't.PORCENTAJE_REN_FAC, t.TOTAL_REN_FAC, t.TOTAL_BASEI_IVAN_FAC, ' +
    't.PORCENTAJE_IVAR_FAC, t.TOTAL_IVAR_FAC, ' +
    't.PORCENTAJE_RER_FAC, t.TOTAL_RER_FAC, t.TOTAL_BASEI_IVAR_FAC, ' +
    't.PORCENTAJE_IVAS_FAC, t.TOTAL_IVAS_FAC, ' +
    't.PORCENTAJE_RES_FAC, t.TOTAL_RES_FAC, t.TOTAL_BASEI_IVAS_FAC, ' +
    't.PORCENTAJE_IVAE_FAC, t.TOTAL_IVAE_FAC, ' +
    't.PORCENTAJE_REE_FAC, t.TOTAL_REE_FAC, t.TOTAL_BASEI_IVAE_FAC, ' +
    't.TOTAL_BASES_FAC, t.TOTAL_IMPUESTOS_FAC, t.FORMA_PAGO_FAC, ' +
    't.PORCENTAJE_RETENCION_FAC, t.TOTAL_RETENCION_FAC, ' +
    't.TOTAL_LIQUIDO_FAC, t.TEXTO_LEGAL_CLIENTE_FAC, ' +
    't.TEXTO_LEGAL_EMPRESA_FAC, ' +
    'TRIM(CONCAT(IFNULL(t.COMENTARIOS_FAC, ''''), :COMENTARIO)), ' +
    't.CONTADOR_LINEAS_FAC, t.ESCREARARTICULOS_FAC, ' +
    't.ESDESCRIPCIONES_AMP_FAC, t.ESFECHADEENTREGA_FAC, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO FROM fza_facturas t ' +
    'JOIN fza_clientes c ON c.CODIGO_CLI_CLI = :CLIENTE ' +
    'WHERE t.SERIE_FAC = :STICKET AND t.NUMERO_FAC = :NTICKET';
  SQL_INSERTAR_LINEAS =
    'INSERT INTO fza_facturas_lineas ' +
    '(NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
    'CODIGO_ART_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    'ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
    'TOTAL_FAC_SIVA_FACLIN, ' +
    'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, LINEA_FACLIN, CODIGO_ART_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'TIPO_IVA_ARTICULO_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'CANTIDAD_FACLIN, PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN = :STICKET ' +
    'AND NUMERO_FAC_FACLIN = :NTICKET';
  SQL_ENLAZAR_TICKET =
    'UPDATE fza_facturas SET SERIE_FAC_ABONO_FAC = :SERIE, ' +
    'NUMERO_FAC_ABONO_FAC = :NUMERO, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE SERIE_FAC = :STICKET ' +
    'AND NUMERO_FAC = :NTICKET';
type
  TConsultaClientesFacturacionTicketUniDAC = class(
    TInterfacedObject,
    IConsultaClientesFacturacionTicket)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TServicioFacturacionTicketUniDAC = class(
    TInterfacedObject,
    IServicioFacturacionTicket)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FServicioEmision: IServicioEmisionFiscal;
    FServicioCola: IServicioVerifactuCola;
    function ObtenerNumero(
      const ASolicitud: TSolicitudFacturacionTicket): string;
    procedure EjecutarSqlFactura(
      AConsulta: TUniQuery;
      const ASql: string;
      const ASolicitud: TSolicitudFacturacionTicket;
      const ANumero: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AServicioEmision: IServicioEmisionFiscal;
      const AServicioCola: IServicioVerifactuCola);
    destructor Destroy; override;
    function ConsultarClientes: IConsultaClientesFacturacionTicket;
    function ConsultarCliente(
      const ACodigoCliente: string): TClienteFacturacionTicket;
    function CrearFactura(
      const ASolicitud: TSolicitudFacturacionTicket): string;
  end;

constructor TConsultaClientesFacturacionTicketUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaClientesFacturacionTicketUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaClientesFacturacionTicketUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TServicioFacturacionTicketUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioCola: IServicioVerifactuCola);
begin
  inherited Create;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FServicioEmision := AServicioEmision;
  FServicioCola := AServicioCola;
end;

destructor TServicioFacturacionTicketUniDAC.Destroy;
begin
  FServicioCola := nil;
  FServicioEmision := nil;
  FParametrosApp := nil;
  inherited;
end;

function TServicioFacturacionTicketUniDAC.ConsultarClientes:
  IConsultaClientesFacturacionTicket;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_CLIENTES;
    oConsulta.Open;
    Result := TConsultaClientesFacturacionTicketUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioFacturacionTicketUniDAC.ConsultarCliente(
  const ACodigoCliente: string): TClienteFacturacionTicket;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TClienteFacturacionTicket);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_CLIENTE;
    oConsulta.ParamByName('CLIENTE').AsString := ACodigoCliente;
    oConsulta.Open;
    Result.Existe := not oConsulta.IsEmpty;
    if Result.Existe then
    begin
      Result.RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      Result.Nif := oConsulta.FieldByName('NIF_CLI').AsString;
      Result.CodigoPais :=
        oConsulta.FieldByName('CODIGO_PAI_CLI').AsString;
      Result.NombrePais :=
        oConsulta.FieldByName('NOMBRE_PAI_CLI').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionTicketUniDAC.ObtenerNumero(
  const ASolicitud: TSolicitudFacturacionTicket): string;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('pserie').AsString := ASolicitud.SerieNueva;
    oProcedimiento.ParamByName('pTipoDoc').AsString := 'FC';
    oProcedimiento.ParamByName('pEMPRESA_CONTADOR').AsString :=
      ASolicitud.Empresa;
    oProcedimiento.ParamByName('pUSUARIOMODIF').AsString :=
      ASolicitud.Usuario;
    oProcedimiento.Execute;
    Result := oProcedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.EjecutarSqlFactura(
  AConsulta: TUniQuery;
  const ASql: string;
  const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero: string);
begin
  AConsulta.SQL.Text := ASql;
  if AConsulta.Params.FindParam('NUMERO') <> nil then
  begin
    AConsulta.ParamByName('NUMERO').AsString := ANumero;
  end;
  if AConsulta.Params.FindParam('SERIE') <> nil then
  begin
    AConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
  end;
  if AConsulta.Params.FindParam('FECHA') <> nil then
  begin
    AConsulta.ParamByName('FECHA').AsDate := ASolicitud.Fecha;
  end;
  if AConsulta.Params.FindParam('USUARIO') <> nil then
  begin
    AConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
  end;
  if AConsulta.Params.FindParam('CLIENTE') <> nil then
  begin
    AConsulta.ParamByName('CLIENTE').AsString := ASolicitud.Cliente;
  end;
  if AConsulta.Params.FindParam('STICKET') <> nil then
  begin
    AConsulta.ParamByName('STICKET').AsString := ASolicitud.SerieTicket;
  end;
  if AConsulta.Params.FindParam('NTICKET') <> nil then
  begin
    AConsulta.ParamByName('NTICKET').AsString := ASolicitud.NumeroTicket;
  end;
  if AConsulta.Params.FindParam('COMENTARIO') <> nil then
  begin
    AConsulta.ParamByName('COMENTARIO').AsString :=
      ' ESTA FACTURA SE EMITE EN SUSTITUCIÓN DE LA FACTURA SIMPLIFICADA ' +
      ASolicitud.SerieTicket + '\' + ASolicitud.NumeroTicket;
  end;
  AConsulta.Execute;
end;

function TServicioFacturacionTicketUniDAC.CrearFactura(
  const ASolicitud: TSolicitudFacturacionTicket): string;
var
  oConsulta: TUniQuery;
  oSolicitudEmision: TSolicitudEmisionFiscal;
begin
  FConexion.StartTransaction;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      Result := ObtenerNumero(ASolicitud);
      oConsulta.Connection := FConexion;
      EjecutarSqlFactura(
        oConsulta,
        SQL_INSERTAR_CABECERA,
        ASolicitud,
        Result);
      if oConsulta.RowsAffected = 0 then
      begin
        raise Exception.Create(SErrorCrearBorradorFacturarTicket);
      end;
      EjecutarSqlFactura(
        oConsulta,
        SQL_INSERTAR_LINEAS,
        ASolicitud,
        Result);
      EjecutarSqlFactura(
        oConsulta,
        SQL_ENLAZAR_TICKET,
        ASolicitud,
        Result);
      // La sustitucion conserva exactamente los importes del ticket. La
      // cabecera y las lineas ya copian el desglose economico original.
      ValidarRequisitosFiscalesEmision(
        FParametrosApp,
        FConexion,
        ASolicitud.SerieNueva,
        Result);
      FServicioCola.RegistrarRelacionFactura(
        ASolicitud.Usuario,
        ASolicitud.SerieNueva,
        Result,
        ASolicitud.SerieTicket,
        ASolicitud.NumeroTicket,
        'SUSTITUYE');
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
    oSolicitudEmision := TSolicitudEmisionFiscal.ParaAlta(
      ASolicitud.SerieNueva,
      Result,
      ASolicitud.Usuario,
      'Borrador en sustitución del ticket ' + ASolicitud.SerieTicket + '\' +
      ASolicitud.NumeroTicket + ' encolada');
    FServicioEmision.Emitir(oSolicitudEmision);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearServicioFacturacionTicketUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioCola: IServicioVerifactuCola
): IServicioFacturacionTicket;
begin
  Result := TServicioFacturacionTicketUniDAC.Create(
    AConexion,
    AParametrosApp,
    AServicioEmision,
    AServicioCola);
end;

end.
