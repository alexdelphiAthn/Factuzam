{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTicketsCajaRepositorio                                 }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de reimpresiones, resguardos y recordatorios de Caja.        }
{******************************************************************************}
unit UniDataTicketsCajaRepositorio;

interface

uses
  System.SysUtils, Uni, inLibCatalogoSqlIntf, inLibTicketsCajaIntf;

type
  TRepositorioTicketsCaja = class(
    TInterfacedObject,
    IRepositorioResguardosCaja,
    IRepositorioTicketsVentaCaja,
    IRepositorioRecordatoriosCaja)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function AbrirConsulta(
      AIndiceDefinicion: Integer;
      const AConfigurar: TProc<TUniQuery>): TUniQuery;
    procedure ConfigurarOperacion(
      AQuery: TUniQuery;
      const AContexto: TContextoOperacionTicketCaja);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function ObtenerEmpresaResguardo(
      const AEmpresa: string): TEmpresaResguardoTicketCaja;
    function ObtenerFechaResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TFechaResguardoTicketCaja;
    function ListarNuevosDepositosResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDepositoResguardoTicketCaja>;
    function ListarEntregasResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TEntregaResguardoTicketCaja>;
    function ListarDevolucionesEconomicasResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDevolucionEconomicaTicketCaja>;
    function ListarDepositosDevueltosResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDepositoResguardoTicketCaja>;
    function ObtenerTotalPagadoResguardo(
      const AContexto: TContextoOperacionTicketCaja): Currency;
    function ObtenerCabeceraTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TCabeceraTicketCaja;
    function ListarLineasTicket(
      const ASerie, ANumero: string): TArray<TLineaTicketCaja>;
    function ListarPagosTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TPagoTicketCaja>;
    function ListarValesTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TValeTicketCaja>;
    function ObtenerEmpresaRecordatorio(
      const AEmpresa: string): TEmpresaRecordatorioTicketCaja;
    function ListarAnticiposRecordatorio(
      const AIdDeposito: string):
      TArray<TAnticipoRecordatorioTicketCaja>;
    function ListarDepositosPendientesRecordatorio(
      const ACodigoCliente: string):
      TArray<TDepositoPendienteTicketCaja>;
    function ListarPieTicket(
      const AEmpresa: string): TArray<string>;
    function ObtenerCodigoBarrasTicket(
      const ASerie, ANumero: string): string;
  end;

function CrearRepositoriosTicketsCaja(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql = nil;
  const AIncidenciasSql: IRegistroIncidenciasSql = nil):
  TRepositoriosTicketsCaja;

implementation

uses
  System.Generics.Collections, Data.DB,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion,
  UniDataGenerarTicketRepositorio;

const
  SQL_EMPRESA_RESGUARDO =
    'SELECT RAZON_SOCIAL_EMP ' +
    'FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :EMP';
  SQL_FECHA_RESGUARDO =
    'SELECT FECHA_OPERACION_OPCAJA ' +
    'FROM fza_caja_operaciones ' +
    'WHERE CODIGO_EMP_OPCAJA = :EMP ' +
    'AND CODIGO_ALM_OPCAJA = :ALM ' +
    'AND CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND NUMERO_OPERACION_OPCAJA = :OP';
  SQL_NUEVOS_DEPOSITOS_RESGUARDO =
    'SELECT d.CODIGO_UNIDAD_DEP, a.DESCRIPCION_ART, ' +
    'd.CODIGO_CLI_DEP, ' +
    '(d.PRECIO_VENTA_DEP * d.CANTIDAD_PENDIENTE_DEP) AS TOTAL_PVP ' +
    'FROM fza_depositos_cliente d ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
    'WHERE d.CODIGO_EMP_DEP = :EMP ' +
    'AND d.CODIGO_ALM_DEP = :ALM ' +
    'AND d.CODIGO_CAJA_DEP = :CAJA ' +
    'AND d.NUMERO_OPERACION_DEP = :OP';
  SQL_ENTREGAS_RESGUARDO =
    'SELECT o.TIPO_OPERACION_OPCAJA, o.IMPORTE_TOTAL_OPCAJA, ' +
    'a.DESCRIPCION_ART ' +
    'FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_depositos_cliente d ' +
    'ON d.ID_DEPOSITO_DEP = o.ID_DEPOSITO_OPCAJA ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :EMP ' +
    'AND o.CODIGO_ALM_OPCAJA = :ALM ' +
    'AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND o.NUMERO_OPERACION_OPCAJA = :OP ' +
    'AND o.TIPO_OPERACION_OPCAJA IN (''CB'', ''DE'') ' +
    'AND o.IMPORTE_TOTAL_OPCAJA > 0';
  SQL_DEVOLUCIONES_ECONOMICAS_RESGUARDO =
    'SELECT TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA ' +
    'FROM fza_caja_operaciones ' +
    'WHERE CODIGO_EMP_OPCAJA = :EMP ' +
    'AND CODIGO_ALM_OPCAJA = :ALM ' +
    'AND CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND NUMERO_OPERACION_OPCAJA = :OP ' +
    'AND TIPO_OPERACION_OPCAJA IN (''DV'')';
  SQL_DEPOSITOS_DEVUELTOS_RESGUARDO =
    'SELECT d.CODIGO_UNIDAD_DEP, a.DESCRIPCION_ART, ' +
    'd.CODIGO_CLI_DEP, ' +
    '(d.PRECIO_VENTA_DEP * d.CANTIDAD_PENDIENTE_DEP) AS TOTAL_PVP ' +
    'FROM fza_depositos_cliente d ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
    'WHERE d.EMPRESA_CANCEL_DEP = :EMP ' +
    'AND d.ALMACEN_CANCEL_DEP = :ALM ' +
    'AND d.CAJA_CANCEL_DEP = :CAJA ' +
    'AND d.NUMERO_OPERACION_CANCEL_DEP = :OP';
  SQL_TOTAL_PAGADO_RESGUARDO =
    'SELECT SUM(IMPORTE_ENTREGADO_PAGO - ' +
    'IMPORTE_CAMBIO_PAGO) AS TOTAL ' +
    'FROM fza_caja_pagos ' +
    'WHERE CODIGO_EMP_PAGO = :EMP ' +
    'AND CODIGO_ALM_PAGO = :ALM ' +
    'AND CODIGO_CAJA_PAGO = :CAJA ' +
    'AND NUMERO_OPERACION_PAGO = :OP';
  SQL_CABECERA_TICKET =
    'SELECT o.TIPO_OPERACION_OPCAJA, o.FECHA_OPERACION_OPCAJA, ' +
    'o.INSTANTE_ALTA AS INSTANTE_ALTA_OPCAJA, ' +
    'o.CODIGO_EMPLEADO_OPCAJA, o.CODIGO_CLI_OPCAJA, ' +
    'o.CONCEPTO_GASTO_INGRESO_OPCAJA, o.IMPORTE_TOTAL_OPCAJA, ' +
    'f.SERIE_FAC, f.NUMERO_FAC, f.NIF_EMPRESA_FAC, f.FECHA_FAC, ' +
    'f.TOTAL_LIQUIDO_FAC, f.RAZON_SOCIAL_EMPRESA_FAC, ' +
    'f.DIRECCION1_EMPRESA_FAC, f.CODIGO_POSTAL_EMPRESA_FAC, ' +
    'f.POBLACION_EMPRESA_FAC, f.MOVIL_EMPRESA_FAC, ' +
    'f.TEXTO_LEGAL_EMPRESA_FAC, f.CODIGO_CLI_FAC, ' +
    'f.TOTAL_IVAN_FAC, f.TOTAL_BASEI_IVAN_FAC, ' +
    'f.PORCENTAJE_IVAN_FAC, f.TOTAL_IVAR_FAC, ' +
    'f.TOTAL_BASEI_IVAR_FAC, f.PORCENTAJE_IVAR_FAC, ' +
    'COALESCE(emp.FORMATO_DOCUMENTO_EMP, ' +
    '''Serie.NroDocumento'') AS FORMATO_DOCUMENTO_EMP, ' +
    'COALESCE(NULLIF(TRIM(empl.DIMINUTIVO_TICKET_EMPL), ''''), ' +
    'o.CODIGO_EMPLEADO_OPCAJA) AS DIMINUTIVO_TICKET_EMPL ' +
    'FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_facturas f ' +
    'ON f.SERIE_FAC = o.SERIE_FAC_OPCAJA ' +
    'AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA ' +
    'LEFT JOIN fza_empleados empl ' +
    'ON empl.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :EMP ' +
    'AND o.CODIGO_ALM_OPCAJA = :ALM ' +
    'AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND o.NUMERO_OPERACION_OPCAJA = :OP';
  SQL_LINEAS_TICKET =
    'SELECT CODIGO_UNIDAD_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'TOTAL_FACLIN, DESCRIPCION_ARTICULO_FACLIN ' +
    'FROM fza_facturas_lineas ' +
    'WHERE SERIE_FAC_FACLIN = :SERIE ' +
    'AND NUMERO_FAC_FACLIN = :NRO ' +
    'ORDER BY LINEA_FACLIN';
  SQL_PAGOS_TICKET =
    'SELECT CODIGO_FP_CFP, IMPORTE_ENTREGADO_PAGO, ' +
    'IMPORTE_CAMBIO_PAGO ' +
    'FROM fza_caja_pagos ' +
    'WHERE CODIGO_EMP_PAGO = :EMP ' +
    'AND CODIGO_ALM_PAGO = :ALM ' +
    'AND CODIGO_CAJA_PAGO = :CAJA ' +
    'AND NUMERO_OPERACION_PAGO = :OP ' +
    'ORDER BY NUMERO_LINEA_PAGO';
  SQL_VALES_TICKET =
    'SELECT CODIGO_VL, IMPORTE_NOMINAL_VL ' +
    'FROM fza_caja_vales ' +
    'WHERE CODIGO_EMP_EMI_VL = :EMP ' +
    'AND CODIGO_ALM_EMI_VL = :ALM ' +
    'AND CODIGO_CAJA_EMI_VL = :CAJA ' +
    'AND NUMERO_OPERACION_EMI_VL = :OP ' +
    'ORDER BY CODIGO_VL';
  SQL_EMPRESA_RECORDATORIO =
    'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP ' +
    'FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :EMP';
  SQL_ANTICIPOS_RECORDATORIO =
    'SELECT o.TIPO_OPERACION_OPCAJA, o.IMPORTE_TOTAL_OPCAJA, ' +
    'o.FECHA_OPERACION_OPCAJA, o.CODIGO_EMP_OPCAJA, ' +
    'o.CODIGO_ALM_OPCAJA, o.CODIGO_CAJA_OPCAJA ' +
    'FROM fza_caja_operaciones o ' +
    'WHERE o.TIPO_OPERACION_OPCAJA IN (''CB'', ''DE'') ' +
    'AND o.IMPORTE_TOTAL_OPCAJA > 0 ' +
    'AND o.ID_DEPOSITO_OPCAJA = :IDDEP ' +
    'ORDER BY o.FECHA_OPERACION_OPCAJA';
  SQL_DEPOSITOS_PENDIENTES_RECORDATORIO =
    'SELECT dep.ID_DEPOSITO_DEP, dep.CODIGO_UNIDAD_DEP, ' +
    'dep.CODIGO_EMP_DEP, dep.CODIGO_ALM_DEP, dep.CODIGO_CAJA_DEP, ' +
    'a.DESCRIPCION_ART, dep.PRECIO_VENTA_DEP, ' +
    'dep.FECHA_CREACION_DEP, dep.IMPORTE_ANTICIPO_DEP, ' +
    'dep.CANTIDAD_PENDIENTE_DEP, cli.CODIGO_CLI_CLI, ' +
    'cli.RAZON_SOCIAL_CLI ' +
    'FROM fza_depositos_cliente dep ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = dep.CODIGO_ART_DEP ' +
    'LEFT JOIN fza_clientes cli ' +
    'ON cli.CODIGO_CLI_CLI = dep.CODIGO_CLI_DEP ' +
    'WHERE dep.CODIGO_CLI_DEP = :CLI ' +
    'AND dep.ESTADO_DEP = ''PENDIENTE'' ' +
    'ORDER BY dep.FECHA_CREACION_DEP';
  SQL_COMPROBAR_PIE_TICKET =
    'SELECT COUNT(*) AS N ' +
    'FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = ''fza_empresas'' ' +
    'AND COLUMN_NAME IN (''TEXTO_PIE_TICKET_CAJA_1_EMP'', ' +
    '''TEXTO_PIE_TICKET_CAJA_2_EMP'', ' +
    '''TEXTO_PIE_TICKET_CAJA_3_EMP'', ' +
    '''TEXTO_PIE_TICKET_CAJA_4_EMP'')';
  SQL_PIE_TICKET =
    'SELECT TEXTO_PIE_TICKET_CAJA_1_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_2_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_3_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_4_EMP ' +
    'FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :EMP';

function DefinicionSql(
  const AOperacion, ASql, AParametros, ACampos: string;
  APolitica: TPoliticaEjecucionSql =
    pesPerfilLecturaConFallback): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioTicketsCaja',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    APolitica);
end;

class function TRepositorioTicketsCaja.DefinicionesSql:
  TDefinicionesSql;
const
  PARAMETROS_OPERACION = 'EMP,ALM,CAJA,OP';
begin
  SetLength(Result, 16);
  Result[0] := DefinicionSql(
    'ObtenerEmpresaResguardo',
    SQL_EMPRESA_RESGUARDO,
    'EMP',
    'RAZON_SOCIAL_EMP');
  Result[1] := DefinicionSql(
    'ObtenerFechaResguardo',
    SQL_FECHA_RESGUARDO,
    PARAMETROS_OPERACION,
    'FECHA_OPERACION_OPCAJA');
  Result[2] := DefinicionSql(
    'ListarNuevosDepositosResguardo',
    SQL_NUEVOS_DEPOSITOS_RESGUARDO,
    PARAMETROS_OPERACION,
    'CODIGO_UNIDAD_DEP,DESCRIPCION_ART,CODIGO_CLI_DEP,TOTAL_PVP');
  Result[3] := DefinicionSql(
    'ListarEntregasResguardo',
    SQL_ENTREGAS_RESGUARDO,
    PARAMETROS_OPERACION,
    'TIPO_OPERACION_OPCAJA,IMPORTE_TOTAL_OPCAJA,DESCRIPCION_ART');
  Result[4] := DefinicionSql(
    'ListarDevolucionesEconomicasResguardo',
    SQL_DEVOLUCIONES_ECONOMICAS_RESGUARDO,
    PARAMETROS_OPERACION,
    'TIPO_OPERACION_OPCAJA,IMPORTE_TOTAL_OPCAJA');
  Result[5] := DefinicionSql(
    'ListarDepositosDevueltosResguardo',
    SQL_DEPOSITOS_DEVUELTOS_RESGUARDO,
    PARAMETROS_OPERACION,
    'CODIGO_UNIDAD_DEP,DESCRIPCION_ART,CODIGO_CLI_DEP,TOTAL_PVP');
  Result[6] := DefinicionSql(
    'ObtenerTotalPagadoResguardo',
    SQL_TOTAL_PAGADO_RESGUARDO,
    PARAMETROS_OPERACION,
    'TOTAL');
  Result[7] := DefinicionSql(
    'ObtenerCabeceraTicket',
    SQL_CABECERA_TICKET,
    PARAMETROS_OPERACION,
    'TIPO_OPERACION_OPCAJA,FECHA_OPERACION_OPCAJA,' +
    'INSTANTE_ALTA_OPCAJA,CODIGO_EMPLEADO_OPCAJA,' +
    'CODIGO_CLI_OPCAJA,CONCEPTO_GASTO_INGRESO_OPCAJA,' +
    'IMPORTE_TOTAL_OPCAJA,SERIE_FAC,NUMERO_FAC,NIF_EMPRESA_FAC,' +
    'FECHA_FAC,TOTAL_LIQUIDO_FAC,RAZON_SOCIAL_EMPRESA_FAC,' +
    'DIRECCION1_EMPRESA_FAC,CODIGO_POSTAL_EMPRESA_FAC,' +
    'POBLACION_EMPRESA_FAC,MOVIL_EMPRESA_FAC,TEXTO_LEGAL_EMPRESA_FAC,' +
    'CODIGO_CLI_FAC,TOTAL_IVAN_FAC,TOTAL_BASEI_IVAN_FAC,' +
    'PORCENTAJE_IVAN_FAC,TOTAL_IVAR_FAC,TOTAL_BASEI_IVAR_FAC,' +
    'PORCENTAJE_IVAR_FAC,FORMATO_DOCUMENTO_EMP,' +
    'DIMINUTIVO_TICKET_EMPL');
  Result[8] := DefinicionSql(
    'ListarLineasTicket',
    SQL_LINEAS_TICKET,
    'SERIE,NRO',
    'CODIGO_UNIDAD_FACLIN,TIPO_CANTIDAD_ARTICULO_FACLIN,' +
    'CANTIDAD_FACLIN,TOTAL_FACLIN,DESCRIPCION_ARTICULO_FACLIN');
  Result[9] := DefinicionSql(
    'ListarPagosTicket',
    SQL_PAGOS_TICKET,
    PARAMETROS_OPERACION,
    'CODIGO_FP_CFP,IMPORTE_ENTREGADO_PAGO,IMPORTE_CAMBIO_PAGO');
  Result[10] := DefinicionSql(
    'ListarValesTicket',
    SQL_VALES_TICKET,
    PARAMETROS_OPERACION,
    'CODIGO_VL,IMPORTE_NOMINAL_VL');
  Result[11] := DefinicionSql(
    'ObtenerEmpresaRecordatorio',
    SQL_EMPRESA_RECORDATORIO,
    'EMP',
    'CODIGO_EMP_EMP,RAZON_SOCIAL_EMP');
  Result[12] := DefinicionSql(
    'ListarAnticiposRecordatorio',
    SQL_ANTICIPOS_RECORDATORIO,
    'IDDEP',
    'TIPO_OPERACION_OPCAJA,IMPORTE_TOTAL_OPCAJA,' +
    'FECHA_OPERACION_OPCAJA,CODIGO_EMP_OPCAJA,' +
    'CODIGO_ALM_OPCAJA,CODIGO_CAJA_OPCAJA');
  Result[13] := DefinicionSql(
    'ListarDepositosPendientesRecordatorio',
    SQL_DEPOSITOS_PENDIENTES_RECORDATORIO,
    'CLI',
    'ID_DEPOSITO_DEP,CODIGO_UNIDAD_DEP,CODIGO_EMP_DEP,' +
    'CODIGO_ALM_DEP,CODIGO_CAJA_DEP,DESCRIPCION_ART,' +
    'PRECIO_VENTA_DEP,FECHA_CREACION_DEP,IMPORTE_ANTICIPO_DEP,' +
    'CANTIDAD_PENDIENTE_DEP,CODIGO_CLI_CLI,RAZON_SOCIAL_CLI');
  Result[14] := DefinicionSql(
    'ComprobarPieTicketDisponible',
    SQL_COMPROBAR_PIE_TICKET,
    '',
    'N',
    pesSoloBase);
  Result[15] := DefinicionSql(
    'ListarPieTicket',
    SQL_PIE_TICKET,
    'EMP',
    'TEXTO_PIE_TICKET_CAJA_1_EMP,TEXTO_PIE_TICKET_CAJA_2_EMP,' +
    'TEXTO_PIE_TICKET_CAJA_3_EMP,TEXTO_PIE_TICKET_CAJA_4_EMP');
end;

function CrearRepositoriosTicketsCaja(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql):
  TRepositoriosTicketsCaja;
var
  Repositorio: TRepositorioTicketsCaja;
begin
  Result := Default(TRepositoriosTicketsCaja);
  Repositorio := TRepositorioTicketsCaja.Create(
    AConexion, ACatalogoSql, AIncidenciasSql);
  Result.Resguardos := Repositorio;
  Result.Tickets := Repositorio;
  Result.Recordatorios := Repositorio;
  Result.Impresion := CrearLecturasImpresionTicket(AConexion);
end;

constructor TRepositorioTicketsCaja.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

function TRepositorioTicketsCaja.AbrirConsulta(
  AIndiceDefinicion: Integer;
  const AConfigurar: TProc<TUniQuery>): TUniQuery;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  oDefinicion := DefinicionesSql[AIndiceDefinicion];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        AConfigurar(oQuery);
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result := oQuery;
  except
    FreeAndNil(oQuery);
    raise;
  end;
end;

procedure TRepositorioTicketsCaja.ConfigurarOperacion(
  AQuery: TUniQuery;
  const AContexto: TContextoOperacionTicketCaja);
begin
  AQuery.ParamByName('EMP').AsString := AContexto.Empresa;
  AQuery.ParamByName('ALM').AsString := AContexto.Almacen;
  AQuery.ParamByName('CAJA').AsString := AContexto.Caja;
  AQuery.ParamByName('OP').AsString := AContexto.Operacion;
end;

function TRepositorioTicketsCaja.ObtenerEmpresaResguardo(
  const AEmpresa: string): TEmpresaResguardoTicketCaja;
var
  sEmpresa: string;
  oQuery: TUniQuery;
begin
  Result.Encontrada := False;
  sEmpresa := AEmpresa;
  oQuery := AbrirConsulta(
    0,
    procedure(AConsulta: TUniQuery)
    begin
      AConsulta.ParamByName('EMP').AsString := sEmpresa;
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrada := True;
      Result.RazonSocial :=
        oQuery.FieldByName('RAZON_SOCIAL_EMP').AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTicketsCaja.ObtenerFechaResguardo(
  const AContexto: TContextoOperacionTicketCaja):
  TFechaResguardoTicketCaja;
var
  oContexto: TContextoOperacionTicketCaja;
  oQuery: TUniQuery;
begin
  Result.Encontrada := False;
  oContexto := AContexto;
  oQuery := AbrirConsulta(
    1,
    procedure(AConsulta: TUniQuery)
    begin
      ConfigurarOperacion(AConsulta, oContexto);
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrada := True;
      Result.FechaOperacion :=
        oQuery.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTicketsCaja.ListarNuevosDepositosResguardo(
  const AContexto: TContextoOperacionTicketCaja):
  TArray<TDepositoResguardoTicketCaja>;
var
  oContexto: TContextoOperacionTicketCaja;
  oDeposito: TDepositoResguardoTicketCaja;
  oLista: TList<TDepositoResguardoTicketCaja>;
  oQuery: TUniQuery;
begin
  oContexto := AContexto;
  oLista := TList<TDepositoResguardoTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      2,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(AConsulta, oContexto);
      end);
    try
      while not oQuery.Eof do
      begin
        oDeposito.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        oDeposito.Descripcion :=
          oQuery.FieldByName('DESCRIPCION_ART').AsString;
        oDeposito.CodigoCliente :=
          oQuery.FieldByName('CODIGO_CLI_DEP').AsString;
        oDeposito.TotalPvp :=
          oQuery.FieldByName('TOTAL_PVP').AsCurrency;
        oLista.Add(oDeposito);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarEntregasResguardo(
  const AContexto: TContextoOperacionTicketCaja):
  TArray<TEntregaResguardoTicketCaja>;
var
  oContexto: TContextoOperacionTicketCaja;
  oEntrega: TEntregaResguardoTicketCaja;
  oLista: TList<TEntregaResguardoTicketCaja>;
  oQuery: TUniQuery;
begin
  oContexto := AContexto;
  oLista := TList<TEntregaResguardoTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      3,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(AConsulta, oContexto);
      end);
    try
      while not oQuery.Eof do
      begin
        oEntrega.TipoOperacion :=
          oQuery.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
        oEntrega.Importe :=
          oQuery.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
        oEntrega.DescripcionArticulo :=
          oQuery.FieldByName('DESCRIPCION_ART').AsString;
        oLista.Add(oEntrega);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarDevolucionesEconomicasResguardo(
  const AContexto: TContextoOperacionTicketCaja):
  TArray<TDevolucionEconomicaTicketCaja>;
var
  oContexto: TContextoOperacionTicketCaja;
  oDevolucion: TDevolucionEconomicaTicketCaja;
  oLista: TList<TDevolucionEconomicaTicketCaja>;
  oQuery: TUniQuery;
begin
  oContexto := AContexto;
  oLista := TList<TDevolucionEconomicaTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      4,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(AConsulta, oContexto);
      end);
    try
      while not oQuery.Eof do
      begin
        oDevolucion.TipoOperacion :=
          oQuery.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
        oDevolucion.Importe :=
          oQuery.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
        oLista.Add(oDevolucion);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarDepositosDevueltosResguardo(
  const AContexto: TContextoOperacionTicketCaja):
  TArray<TDepositoResguardoTicketCaja>;
var
  oContexto: TContextoOperacionTicketCaja;
  oDeposito: TDepositoResguardoTicketCaja;
  oLista: TList<TDepositoResguardoTicketCaja>;
  oQuery: TUniQuery;
begin
  oContexto := AContexto;
  oLista := TList<TDepositoResguardoTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      5,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(AConsulta, oContexto);
      end);
    try
      while not oQuery.Eof do
      begin
        oDeposito.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        oDeposito.Descripcion :=
          oQuery.FieldByName('DESCRIPCION_ART').AsString;
        oDeposito.CodigoCliente :=
          oQuery.FieldByName('CODIGO_CLI_DEP').AsString;
        oDeposito.TotalPvp :=
          oQuery.FieldByName('TOTAL_PVP').AsCurrency;
        oLista.Add(oDeposito);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ObtenerTotalPagadoResguardo(
  const AContexto: TContextoOperacionTicketCaja): Currency;
var
  oContexto: TContextoOperacionTicketCaja;
  oQuery: TUniQuery;
begin
  Result := 0;
  oContexto := AContexto;
  oQuery := AbrirConsulta(
    6,
    procedure(AConsulta: TUniQuery)
    begin
      ConfigurarOperacion(AConsulta, oContexto);
    end);
  try
    if not oQuery.IsEmpty then
      Result := oQuery.FieldByName('TOTAL').AsCurrency;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTicketsCaja.ObtenerCabeceraTicket(
  const AContexto: TContextoOperacionTicketCaja):
  TCabeceraTicketCaja;
var
  oContexto: TContextoOperacionTicketCaja;
  oQuery: TUniQuery;
begin
  Result.Encontrada := False;
  oContexto := AContexto;
  oQuery := AbrirConsulta(
    7,
    procedure(AConsulta: TUniQuery)
    begin
      ConfigurarOperacion(AConsulta, oContexto);
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrada := True;
      Result.TipoOperacion :=
        oQuery.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
      Result.FechaOperacion :=
        oQuery.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
      Result.InstanteAlta :=
        oQuery.FieldByName('INSTANTE_ALTA_OPCAJA').AsDateTime;
      Result.CodigoEmpleado :=
        oQuery.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString;
      Result.DiminutivoVendedor :=
        oQuery.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString;
      Result.CodigoClienteOperacion :=
        oQuery.FieldByName('CODIGO_CLI_OPCAJA').AsString;
      Result.Concepto :=
        oQuery.FieldByName(
          'CONCEPTO_GASTO_INGRESO_OPCAJA').AsString;
      Result.ImporteOperacion :=
        oQuery.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
      Result.SerieFactura :=
        oQuery.FieldByName('SERIE_FAC').AsString;
      Result.NumeroFactura :=
        oQuery.FieldByName('NUMERO_FAC').AsString;
      Result.FormatoDocumento :=
        oQuery.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
      Result.NifEmpresaFactura :=
        oQuery.FieldByName('NIF_EMPRESA_FAC').AsString;
      Result.FechaFactura :=
        oQuery.FieldByName('FECHA_FAC').AsDateTime;
      Result.TotalLiquido :=
        oQuery.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
      Result.RazonSocialEmpresa :=
        oQuery.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString;
      Result.DireccionEmpresa :=
        oQuery.FieldByName('DIRECCION1_EMPRESA_FAC').AsString;
      Result.CodigoPostalEmpresa :=
        oQuery.FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString;
      Result.PoblacionEmpresa :=
        oQuery.FieldByName('POBLACION_EMPRESA_FAC').AsString;
      Result.MovilEmpresa :=
        oQuery.FieldByName('MOVIL_EMPRESA_FAC').AsString;
      Result.TextoLegalEmpresa :=
        oQuery.FieldByName('TEXTO_LEGAL_EMPRESA_FAC').AsString;
      Result.CodigoClienteFactura :=
        oQuery.FieldByName('CODIGO_CLI_FAC').AsString;
      Result.TotalIvaNormal :=
        oQuery.FieldByName('TOTAL_IVAN_FAC').AsCurrency;
      Result.BaseIvaNormal :=
        oQuery.FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency;
      Result.PorcentajeIvaNormal :=
        oQuery.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat;
      Result.TotalIvaReducido :=
        oQuery.FieldByName('TOTAL_IVAR_FAC').AsCurrency;
      Result.BaseIvaReducido :=
        oQuery.FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency;
      Result.PorcentajeIvaReducido :=
        oQuery.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTicketsCaja.ListarLineasTicket(
  const ASerie, ANumero: string): TArray<TLineaTicketCaja>;
var
  sNumero: string;
  sSerie: string;
  oLinea: TLineaTicketCaja;
  oLista: TList<TLineaTicketCaja>;
  oQuery: TUniQuery;
begin
  sSerie := ASerie;
  sNumero := ANumero;
  oLista := TList<TLineaTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      8,
      procedure(AConsulta: TUniQuery)
      begin
        AConsulta.ParamByName('SERIE').AsString := sSerie;
        AConsulta.ParamByName('NRO').AsString := sNumero;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
        oLinea.TipoCantidad :=
          oQuery.FieldByName(
            'TIPO_CANTIDAD_ARTICULO_FACLIN').AsString;
        oLinea.Cantidad :=
          oQuery.FieldByName('CANTIDAD_FACLIN').AsFloat;
        oLinea.Total :=
          oQuery.FieldByName('TOTAL_FACLIN').AsCurrency;
        oLinea.Descripcion :=
          oQuery.FieldByName(
            'DESCRIPCION_ARTICULO_FACLIN').AsString;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarPagosTicket(
  const AContexto: TContextoOperacionTicketCaja):
  TArray<TPagoTicketCaja>;
var
  oContexto: TContextoOperacionTicketCaja;
  oPago: TPagoTicketCaja;
  oLista: TList<TPagoTicketCaja>;
  oQuery: TUniQuery;
begin
  oContexto := AContexto;
  oLista := TList<TPagoTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      9,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(AConsulta, oContexto);
      end);
    try
      while not oQuery.Eof do
      begin
        oPago.CodigoFormaPago :=
          oQuery.FieldByName('CODIGO_FP_CFP').AsString;
        oPago.ImporteEntregado :=
          oQuery.FieldByName('IMPORTE_ENTREGADO_PAGO').AsCurrency;
        oPago.ImporteCambio :=
          oQuery.FieldByName('IMPORTE_CAMBIO_PAGO').AsCurrency;
        oLista.Add(oPago);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarValesTicket(
  const AContexto: TContextoOperacionTicketCaja):
  TArray<TValeTicketCaja>;
var
  oContexto: TContextoOperacionTicketCaja;
  oVale: TValeTicketCaja;
  oLista: TList<TValeTicketCaja>;
  oQuery: TUniQuery;
begin
  oContexto := AContexto;
  oLista := TList<TValeTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      10,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(AConsulta, oContexto);
      end);
    try
      while not oQuery.Eof do
      begin
        oVale.Codigo :=
          oQuery.FieldByName('CODIGO_VL').AsString;
        oVale.ImporteNominal :=
          oQuery.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency;
        oLista.Add(oVale);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ObtenerEmpresaRecordatorio(
  const AEmpresa: string): TEmpresaRecordatorioTicketCaja;
var
  sEmpresa: string;
  oQuery: TUniQuery;
begin
  Result.Encontrada := False;
  sEmpresa := AEmpresa;
  oQuery := AbrirConsulta(
    11,
    procedure(AConsulta: TUniQuery)
    begin
      AConsulta.ParamByName('EMP').AsString := sEmpresa;
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrada := True;
      Result.Codigo :=
        oQuery.FieldByName('CODIGO_EMP_EMP').AsString;
      Result.RazonSocial :=
        oQuery.FieldByName('RAZON_SOCIAL_EMP').AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTicketsCaja.ListarAnticiposRecordatorio(
  const AIdDeposito: string):
  TArray<TAnticipoRecordatorioTicketCaja>;
var
  sIdDeposito: string;
  oAnticipo: TAnticipoRecordatorioTicketCaja;
  oLista: TList<TAnticipoRecordatorioTicketCaja>;
  oQuery: TUniQuery;
begin
  sIdDeposito := AIdDeposito;
  oLista := TList<TAnticipoRecordatorioTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      12,
      procedure(AConsulta: TUniQuery)
      begin
        AConsulta.ParamByName('IDDEP').AsString := sIdDeposito;
      end);
    try
      while not oQuery.Eof do
      begin
        oAnticipo.TipoOperacion :=
          oQuery.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
        oAnticipo.Importe :=
          oQuery.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
        oAnticipo.FechaOperacion :=
          oQuery.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
        oAnticipo.Empresa :=
          oQuery.FieldByName('CODIGO_EMP_OPCAJA').AsString;
        oAnticipo.Almacen :=
          oQuery.FieldByName('CODIGO_ALM_OPCAJA').AsString;
        oAnticipo.Caja :=
          oQuery.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
        oLista.Add(oAnticipo);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarDepositosPendientesRecordatorio(
  const ACodigoCliente: string):
  TArray<TDepositoPendienteTicketCaja>;
var
  sCodigoCliente: string;
  oDeposito: TDepositoPendienteTicketCaja;
  oLista: TList<TDepositoPendienteTicketCaja>;
  oQuery: TUniQuery;
begin
  sCodigoCliente := ACodigoCliente;
  oLista := TList<TDepositoPendienteTicketCaja>.Create;
  try
    oQuery := AbrirConsulta(
      13,
      procedure(AConsulta: TUniQuery)
      begin
        AConsulta.ParamByName('CLI').AsString := sCodigoCliente;
      end);
    try
      while not oQuery.Eof do
      begin
        oDeposito.IdDeposito :=
          oQuery.FieldByName('ID_DEPOSITO_DEP').AsString;
        oDeposito.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        oDeposito.Empresa :=
          oQuery.FieldByName('CODIGO_EMP_DEP').AsString;
        oDeposito.Almacen :=
          oQuery.FieldByName('CODIGO_ALM_DEP').AsString;
        oDeposito.Caja :=
          oQuery.FieldByName('CODIGO_CAJA_DEP').AsString;
        oDeposito.Descripcion :=
          oQuery.FieldByName('DESCRIPCION_ART').AsString;
        oDeposito.PrecioVenta :=
          oQuery.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
        oDeposito.FechaCreacion :=
          oQuery.FieldByName('FECHA_CREACION_DEP').AsDateTime;
        oDeposito.ImporteAnticipo :=
          oQuery.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
        oDeposito.CantidadPendiente :=
          oQuery.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
        oDeposito.CodigoCliente :=
          oQuery.FieldByName('CODIGO_CLI_CLI').AsString;
        oDeposito.RazonSocialCliente :=
          oQuery.FieldByName('RAZON_SOCIAL_CLI').AsString;
        oLista.Add(oDeposito);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioTicketsCaja.ListarPieTicket(
  const AEmpresa: string): TArray<string>;
var
  i: Integer;
  sEmpresa: string;
  sLinea: string;
  oDefinicion: TDefinicionSql;
  oLista: TList<string>;
  oQuery: TUniQuery;
begin
  SetLength(Result, 0);
  sEmpresa := AEmpresa;
  oDefinicion := DefinicionesSql[14];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    if Assigned(FCatalogoSql) then
      oQuery.SQL.Text := FCatalogoSql.Resolver(
        oDefinicion).Texto
    else
      oQuery.SQL.Text := oDefinicion.SqlBase;
    oQuery.Open;
    ValidarCamposResultadoSql(
      oDefinicion,
      oQuery);
    if oQuery.FieldByName('N').AsInteger = 4 then
    begin
      oLista := TList<string>.Create;
      try
        FreeAndNil(oQuery);
        oQuery := AbrirConsulta(
          15,
          procedure(AConsulta: TUniQuery)
          begin
            AConsulta.ParamByName('EMP').AsString := sEmpresa;
          end);
        if not oQuery.IsEmpty then
        begin
          i := 1;
          while i <= 4 do
          begin
            sLinea := Trim(
              oQuery.FieldByName(
                'TEXTO_PIE_TICKET_CAJA_' +
                IntToStr(i) + '_EMP').AsString);
            if sLinea <> '' then
              oLista.Add(sLinea);
            Inc(i);
          end;
        end;
        Result := oLista.ToArray;
      finally
        FreeAndNil(oLista);
      end;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTicketsCaja.ObtenerCodigoBarrasTicket(
  const ASerie, ANumero: string): string;
var
  oQuery: TUniQuery;
begin
  // EAN-13 del ticket ('' si la factura no lo tiene o si la columna
  // aún no existe: script codigo_barras_ticket.sql sin aplicar).
  Result := '';
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    oQuery := TUniQuery.Create(nil);
    try
      oQuery.Connection := FConexion;
      oQuery.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = ''fza_facturas'' ' +
        '   AND COLUMN_NAME = ''CODIGO_BARRAS_FAC''';
      oQuery.Open;
      if oQuery.FieldByName('N').AsInteger > 0 then
      begin
        oQuery.Close;
        oQuery.SQL.Text :=
          'SELECT CODIGO_BARRAS_FAC ' +
          '  FROM fza_facturas ' +
          ' WHERE SERIE_FAC = :SERIE ' +
          '   AND NUMERO_FAC = :NUMERO';
        oQuery.ParamByName('SERIE').AsString := ASerie;
        oQuery.ParamByName('NUMERO').AsString := ANumero;
        oQuery.Open;
        if not oQuery.IsEmpty then
          Result := Trim(
            oQuery.FieldByName('CODIGO_BARRAS_FAC').AsString);
      end;
    finally
      FreeAndNil(oQuery);
    end;
  end;
end;

end.
