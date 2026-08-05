{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasProformaRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Materializa proformas VE y facturas fiscales por traspasos TA.           }
{******************************************************************************}
unit UniDataFacturasProformaRepositorio;

interface

uses
  Uni,
  inLibParametrosIntf,
  inLibFacturasProformaIntf;

type
  TRepositorioFacturasProformaUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturasProforma)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    procedure ActualizarPeriodo(
      AIdPeriodo: Int64;
      const AEstado: string;
      const AResultado: TResultadoFacturacionCaja;
      const AUsuario: string);
    procedure AsignarSolicitud(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja);
    function ContarCandidatasVenta(
      const ASolicitud: TSolicitudFacturacionCaja): Integer;
    function ContarLineasTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string): Integer;
    function ContarLineasFacturaTraspaso(
      const ASerie: string;
      const ANumero: string): Integer;
    function CrearBorradorFacturaTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const ASerie: string;
      const ANumero: string): Integer;
    function CrearPeriodo(
      const AModalidad: string;
      const ASolicitud: TSolicitudFacturacionCaja): Int64;
    function GenerarFacturaTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string): Integer;
    function ObtenerIdentidad: Int64;
    function ObtenerNumeroDocumento(
      const ASerie: string;
      const ATipoDocumento: string;
      const AEmpresa: string;
      const AUsuario: string): string;
    function ObtenerSerieFactura(
      const AEmpresa: string;
      const AAlmacen: string;
      const AFecha: TDateTime): string;
    procedure InsertarLineasFacturaTraspaso(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const ASerie: string;
      const ANumero: string);
    function ReservarOperacionesTraspaso(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const ASerie: string;
      const ANumero: string): Integer;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion);
    destructor Destroy; override;
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
    function GenerarVenta(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function GenerarTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibVerifactu;

const
  SQL_REVISAR_PERIODO =
    'SELECT COALESCE(SUM(CASE WHEN FECHA_DESDE_FACPER = :DESDE ' +
    'AND FECHA_HASTA_FACPER = :HASTA THEN 1 ELSE 0 END), 0) ' +
    'AS DUPLICADOS, COUNT(*) AS SOLAPADOS ' +
    'FROM fza_facturacion_caja_periodos ' +
    'WHERE MODALIDAD_FACPER = :MODALIDAD ' +
    'AND CODIGO_EMP_DESTINO_FACPER = :EMPRESA ' +
    'AND FECHA_DESDE_FACPER <= :HASTA ' +
    'AND FECHA_HASTA_FACPER >= :DESDE';
  SQL_INSERTAR_PERIODO =
    'INSERT INTO fza_facturacion_caja_periodos (' +
    'MODALIDAD_FACPER, CODIGO_EMP_DESTINO_FACPER, ' +
    'FECHA_DESDE_FACPER, FECHA_HASTA_FACPER, ESTADO_FACPER, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:MODALIDAD, :EMPRESA, :DESDE, :HASTA, ''ABIERTO'', ' +
    'NOW(), NOW(), :USUARIO, :USUARIO)';
  SQL_ACTUALIZAR_PERIODO =
    'UPDATE fza_facturacion_caja_periodos SET ESTADO_FACPER = :ESTADO, ' +
    'CANTIDAD_DOCUMENTOS_FACPER = :DOCUMENTOS, ' +
    'CANTIDAD_OPERACIONES_FACPER = :OPERACIONES, ' +
    'CANTIDAD_AJUSTES_FACPER = :AJUSTES, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE ID_FACPER = :ID_PERIODO';
  SQL_CONTAR_CANDIDATAS_VENTA =
    'SELECT COUNT(*) AS CANTIDAD FROM (' +
    'SELECT O.ID_OPCAJA FROM fza_caja_operaciones O ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = O.SERIE_FAC_OPCAJA ' +
    ' AND F.NUMERO_FAC = O.NUMERO_FAC_OPCAJA ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND F.TIPO_FAC = ''SIMPLIFICADA'' ' +
    ' AND F.ESCONSOLIDADA_FAC = ''S'' ' +
    ' AND COALESCE(NULLIF(TRIM(F.CODIGO_CLI_FAC), ''0''), '''') = '''' ' +
    ' AND COALESCE(TRIM(F.NIF_CLIENTE_FAC), '''') = '''' ' +
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = O.SERIE_FAC_OPCAJA ' +
    ' AND V.NUMERO_FAC_VFCOLA = O.NUMERO_FAC_OPCAJA ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = O.SERIE_FAC_OPCAJA ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = O.NUMERO_FAC_OPCAJA) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas P ' +
    ' WHERE P.ID_OPCAJA_PROCLIN = O.ID_OPCAJA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'') ' +
    'UNION ALL ' +
    'SELECT DISTINCT P.ID_OPCAJA_PROCLIN ' +
    'FROM fza_proformas_caja_lineas P ' +
    'JOIN fza_proformas_caja H ' +
    ' ON H.ID_PROCAJ = P.ID_PROCAJ_PROCLIN ' +
    'LEFT JOIN fza_facturas F ' +
    ' ON F.SERIE_FAC = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND F.NUMERO_FAC = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    'WHERE H.CODIGO_EMP_PROCAJ = :EMPRESA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'' ' +
    ' AND (F.NUMERO_FAC IS NULL ' +
    ' OR F.TIPO_FAC <> ''SIMPLIFICADA'' ' +
    ' OR COALESCE(F.FASE_FAC, '''') IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND V.NUMERO_FAC_VFCOLA = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN)) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas A ' +
    ' WHERE A.ID_OPCAJA_PROCLIN = P.ID_OPCAJA_PROCLIN ' +
    ' AND A.TIPO_VINCULO_PROCLIN = ''AJUSTE'' ' +
    ' AND A.SERIE_FAC_ORIGEN_PROCLIN = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND A.NUMERO_FAC_ORIGEN_PROCLIN = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND A.LINEA_FAC_ORIGEN_PROCLIN = ' +
    ' P.LINEA_FAC_ORIGEN_PROCLIN)) X';
  SQL_INSERTAR_PROFORMA =
    'INSERT INTO fza_proformas_caja (' +
    'ID_FACPER_PROCAJ, NUMERO_PROCAJ, SERIE_PROCAJ, FECHA_PROCAJ, ' +
    'FECHA_DESDE_PROCAJ, FECHA_HASTA_PROCAJ, TIPO_PROCAJ, ' +
    'ESTADO_PROCAJ, CODIGO_EMP_PROCAJ, ' +
    'RAZON_SOCIAL_EMPRESA_PROCAJ, NIF_EMPRESA_PROCAJ, ' +
    'DIRECCION1_EMPRESA_PROCAJ, DIRECCION2_EMPRESA_PROCAJ, ' +
    'CODIGO_POSTAL_EMPRESA_PROCAJ, POBLACION_EMPRESA_PROCAJ, ' +
    'PROVINCIA_EMPRESA_PROCAJ, CODIGO_PAI_EMPRESA_PROCAJ, ' +
    'NOMBRE_PAI_EMPRESA_PROCAJ, CODIGO_CLI_PROCAJ, ' +
    'RAZON_SOCIAL_CLIENTE_PROCAJ, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_PERIODO, :NUMERO, :SERIE, :HASTA, :DESDE, :HASTA, ''VE'', ' +
    '''EMITIDA'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
    'E.DIRECCION1_EMP, E.DIRECCION2_EMP, E.CODIGO_POSTAL_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, ''0'', ''VENTA CONTADO'', NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMPRESA';
  SQL_INICIAR_LINEA_PROFORMA = 'SET @linea_proforma := 0';
  SQL_CONTINUAR_LINEA_PROFORMA =
    'SET @linea_proforma := (SELECT COALESCE(' +
    'MAX(CAST(LINEA_PROCLIN AS UNSIGNED)), 0) ' +
    'FROM fza_proformas_caja_lineas WHERE ID_PROCAJ_PROCLIN = :ID)';
  SQL_INSERTAR_LINEAS_VENTA =
    'INSERT IGNORE INTO fza_proformas_caja_lineas (' +
    'ID_PROCAJ_PROCLIN, LINEA_PROCLIN, ID_OPCAJA_PROCLIN, ' +
    'TIPO_VINCULO_PROCLIN, SERIE_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_FAC_ORIGEN_PROCLIN, LINEA_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_OPERACION_PROCLIN, FECHA_OPERACION_PROCLIN, ' +
    'CODIGO_ART_PROCLIN, CODIGO_UNIDAD_PROCLIN, ' +
    'DESCRIPCION_ARTICULO_PROCLIN, TIPO_IVA_PROCLIN, ' +
    'CANTIDAD_PROCLIN, PRECIO_SIVA_PROCLIN, ' +
    'PORCENTAJE_IVA_PROCLIN, TOTAL_SIVA_PROCLIN, TOTAL_PROCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID, LPAD((@linea_proforma := @linea_proforma + 10), ' +
    '8, ''0''), O.ID_OPCAJA, ''ORIGEN'', F.SERIE_FAC, ' +
    'F.NUMERO_FAC, L.LINEA_FACLIN, O.NUMERO_OPERACION_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)), ' +
    'L.CODIGO_ART_FACLIN, L.CODIGO_UNIDAD_FACLIN, ' +
    'L.DESCRIPCION_ARTICULO_FACLIN, L.TIPO_IVA_ARTICULO_FACLIN, ' +
    'L.CANTIDAD_FACLIN, L.PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'L.PORCENTAJE_IVA_FACLIN, COALESCE(L.TOTAL_FAC_SIVA_FACLIN, ' +
    'L.CANTIDAD_FACLIN * L.PRECIO_VENTA_SIVA_ARTICULO_FACLIN), ' +
    'L.TOTAL_FACLIN, NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_caja_operaciones O ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = O.SERIE_FAC_OPCAJA ' +
    ' AND F.NUMERO_FAC = O.NUMERO_FAC_OPCAJA ' +
    'JOIN fza_facturas_lineas L ' +
    ' ON L.SERIE_FAC_FACLIN = F.SERIE_FAC ' +
    ' AND L.NUMERO_FAC_FACLIN = F.NUMERO_FAC ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND F.TIPO_FAC = ''SIMPLIFICADA'' ' +
    ' AND F.ESCONSOLIDADA_FAC = ''S'' ' +
    ' AND COALESCE(NULLIF(TRIM(F.CODIGO_CLI_FAC), ''0''), '''') = '''' ' +
    ' AND COALESCE(TRIM(F.NIF_CLIENTE_FAC), '''') = '''' ' +
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = O.SERIE_FAC_OPCAJA ' +
    ' AND V.NUMERO_FAC_VFCOLA = O.NUMERO_FAC_OPCAJA ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = O.SERIE_FAC_OPCAJA ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = O.NUMERO_FAC_OPCAJA) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas P ' +
    ' WHERE P.ID_OPCAJA_PROCLIN = O.ID_OPCAJA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'') ' +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, L.LINEA_FACLIN';
  SQL_INSERTAR_AJUSTES_VENTA =
    'INSERT IGNORE INTO fza_proformas_caja_lineas (' +
    'ID_PROCAJ_PROCLIN, LINEA_PROCLIN, ID_OPCAJA_PROCLIN, ' +
    'TIPO_VINCULO_PROCLIN, ID_PROCAJ_ORIGEN_PROCLIN, ' +
    'LINEA_PROCAJ_ORIGEN_PROCLIN, SERIE_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_FAC_ORIGEN_PROCLIN, LINEA_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_OPERACION_PROCLIN, FECHA_OPERACION_PROCLIN, ' +
    'CODIGO_ART_PROCLIN, CODIGO_UNIDAD_PROCLIN, ' +
    'DESCRIPCION_ARTICULO_PROCLIN, TIPO_IVA_PROCLIN, ' +
    'CANTIDAD_PROCLIN, PRECIO_SIVA_PROCLIN, ' +
    'PORCENTAJE_IVA_PROCLIN, TOTAL_SIVA_PROCLIN, TOTAL_PROCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID, LPAD((@linea_proforma := @linea_proforma + 10), ' +
    '8, ''0''), P.ID_OPCAJA_PROCLIN, ''AJUSTE'', ' +
    'P.ID_PROCAJ_PROCLIN, P.LINEA_PROCLIN, ' +
    'P.SERIE_FAC_ORIGEN_PROCLIN, P.NUMERO_FAC_ORIGEN_PROCLIN, ' +
    'P.LINEA_FAC_ORIGEN_PROCLIN, P.NUMERO_OPERACION_PROCLIN, ' +
    'P.FECHA_OPERACION_PROCLIN, P.CODIGO_ART_PROCLIN, ' +
    'P.CODIGO_UNIDAD_PROCLIN, ' +
    'CONCAT(''AJUSTE: '', P.DESCRIPCION_ARTICULO_PROCLIN), ' +
    'P.TIPO_IVA_PROCLIN, -P.CANTIDAD_PROCLIN, ' +
    'P.PRECIO_SIVA_PROCLIN, P.PORCENTAJE_IVA_PROCLIN, ' +
    '-P.TOTAL_SIVA_PROCLIN, -P.TOTAL_PROCLIN, NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_proformas_caja_lineas P ' +
    'JOIN fza_proformas_caja H ' +
    ' ON H.ID_PROCAJ = P.ID_PROCAJ_PROCLIN ' +
    'LEFT JOIN fza_facturas F ' +
    ' ON F.SERIE_FAC = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND F.NUMERO_FAC = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    'WHERE H.CODIGO_EMP_PROCAJ = :EMPRESA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'' ' +
    ' AND (F.NUMERO_FAC IS NULL ' +
    ' OR F.TIPO_FAC <> ''SIMPLIFICADA'' ' +
    ' OR COALESCE(F.FASE_FAC, '''') IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND V.NUMERO_FAC_VFCOLA = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN)) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas A ' +
    ' WHERE A.ID_OPCAJA_PROCLIN = P.ID_OPCAJA_PROCLIN ' +
    ' AND A.TIPO_VINCULO_PROCLIN = ''AJUSTE'' ' +
    ' AND A.SERIE_FAC_ORIGEN_PROCLIN = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND A.NUMERO_FAC_ORIGEN_PROCLIN = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND A.LINEA_FAC_ORIGEN_PROCLIN = ' +
    ' P.LINEA_FAC_ORIGEN_PROCLIN) ' +
    'ORDER BY P.FECHA_OPERACION_PROCLIN, P.ID_OPCAJA_PROCLIN, ' +
    'P.LINEA_PROCLIN';
  SQL_ACTUALIZAR_TOTALES_PROFORMA =
    'UPDATE fza_proformas_caja H SET ' +
    'H.TOTAL_BASE_PROCAJ = (SELECT COALESCE(SUM(L.TOTAL_SIVA_PROCLIN), 0) ' +
    ' FROM fza_proformas_caja_lineas L ' +
    ' WHERE L.ID_PROCAJ_PROCLIN = H.ID_PROCAJ), ' +
    'H.TOTAL_PROCAJ = (SELECT COALESCE(SUM(L.TOTAL_PROCLIN), 0) ' +
    ' FROM fza_proformas_caja_lineas L ' +
    ' WHERE L.ID_PROCAJ_PROCLIN = H.ID_PROCAJ), ' +
    'H.TOTAL_IMPUESTOS_PROCAJ = (SELECT COALESCE(' +
    'SUM(L.TOTAL_PROCLIN - L.TOTAL_SIVA_PROCLIN), 0) ' +
    ' FROM fza_proformas_caja_lineas L ' +
    ' WHERE L.ID_PROCAJ_PROCLIN = H.ID_PROCAJ), ' +
    'H.INSTANTE_MODIF = NOW(), H.USUARIO_MODIF = :USUARIO ' +
    'WHERE H.ID_PROCAJ = :ID';
  SQL_CONTAR_PROFORMA =
    'SELECT COUNT(DISTINCT ID_OPCAJA_PROCLIN) AS OPERACIONES, ' +
    'COUNT(DISTINCT CASE WHEN TIPO_VINCULO_PROCLIN = ''AJUSTE'' ' +
    'THEN ID_OPCAJA_PROCLIN END) AS AJUSTES ' +
    'FROM fza_proformas_caja_lineas WHERE ID_PROCAJ_PROCLIN = :ID';
  SQL_GRUPOS_TRASPASO =
    'SELECT O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    'O.CODIGO_ALM_OPCAJA AS ALMACEN ' +
    'FROM fza_caja_operaciones O ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA ' +
    ' AND O.CODIGO_EMP_OPCAJA <> :EMPRESA ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    ' AND EXISTS (SELECT 1 FROM fza_movimientos_almacen M ' +
    ' WHERE M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA) ' +
    'GROUP BY O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA ' +
    'ORDER BY O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA';
  SQL_CONTAR_LINEAS_TRASPASO =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_caja_operaciones O ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA)';
  SQL_CONTAR_LINEAS_FACTURA_TA =
    'SELECT COUNT(*) AS CANTIDAD ' +
    'FROM fza_facturas_operaciones_caja X ' +
    'JOIN fza_caja_operaciones O ON O.ID_OPCAJA = X.ID_OPCAJA_FACOP ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'WHERE X.SERIE_FAC_FACOP = :SERIE ' +
    ' AND X.NUMERO_FAC_FACOP = :NUMERO ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S''';
  SQL_OBTENER_SERIE_FACTURA =
    'SELECT S.EMPSER FROM vi_empresas_series S ' +
    'JOIN fza_contadores C ON C.TIPO_DOC_CON = ''FC'' ' +
    ' AND C.EMPRESA_CON = S.CODIGO_EMP_EMPSER ' +
    ' AND C.SERIE_CON = S.EMPSER AND C.ESACTIVO_CON = ''S'' ' +
    'WHERE S.CODIGO_EMP_EMPSER = :ORIGEN ' +
    ' AND S.TIPO_DOC_EMPSER = ''FC'' ' +
    ' AND S.SUBTIPO_EMPSER = ''NORMAL'' ' +
    ' AND (S.CODIGO_ALM_EMPSER = :ALMACEN ' +
    ' OR S.CODIGO_ALM_EMPSER IS NULL OR S.CODIGO_ALM_EMPSER = '''') ' +
    ' AND (S.FECHA_DESDE_EMPSER IS NULL ' +
    ' OR S.FECHA_DESDE_EMPSER <= :FECHA) ' +
    ' AND (S.FECHA_HASTA_EMPSER IS NULL ' +
    ' OR S.FECHA_HASTA_EMPSER >= :FECHA) ' +
    'ORDER BY (S.CODIGO_ALM_EMPSER = :ALMACEN) DESC, ' +
    'S.FECHA_DESDE_EMPSER DESC LIMIT 1';
  SQL_OBTENER_SERIE_CONTADOR =
    'SELECT S.EMPSER FROM vi_empresas_series S ' +
    'JOIN fza_contadores C ON C.TIPO_DOC_CON = ''FC'' ' +
    ' AND C.EMPRESA_CON = S.CODIGO_EMP_EMPSER ' +
    ' AND C.SERIE_CON = S.EMPSER AND C.ESACTIVO_CON = ''S'' ' +
    'WHERE S.CODIGO_EMP_EMPSER = :ORIGEN ' +
    ' AND S.TIPO_DOC_EMPSER = ''FC'' ' +
    ' AND S.SUBTIPO_EMPSER = ''NORMAL'' ' +
    ' AND (S.FECHA_DESDE_EMPSER IS NULL ' +
    ' OR S.FECHA_DESDE_EMPSER <= :FECHA) ' +
    ' AND (S.FECHA_HASTA_EMPSER IS NULL ' +
    ' OR S.FECHA_HASTA_EMPSER >= :FECHA) ' +
    'ORDER BY (C.DEFAULT_CON = ''S'') DESC, ' +
    'S.FECHA_DESDE_EMPSER DESC, S.EMPSER LIMIT 1';
  SQL_INSERTAR_FACTURA_TA =
    'INSERT INTO fza_facturas (' +
    'NUMERO_FAC, SERIE_FAC, FECHA_FAC, ESCONSOLIDADA_FAC, ' +
    'TIPO_FAC, ESMUEVE_STOCK_FAC, FASE_FAC, CODIGO_EMP_FAC, ' +
    'RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
    'MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC, ' +
    'DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC, ' +
    'PROVINCIA_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC, ' +
    'ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, CODIGO_CLI_FAC, ' +
    'RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, MOVIL_CLIENTE_FAC, ' +
    'EMAIL_CLIENTE_FAC, DIRECCION1_CLIENTE_FAC, ' +
    'DIRECCION2_CLIENTE_FAC, POBLACION_CLIENTE_FAC, ' +
    'PROVINCIA_CLIENTE_FAC, CODIGO_POSTAL_CLIENTE_FAC, ' +
    'CODIGO_PAI_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
    'CODIGO_IVA_FAC, ESIVA_RECARGO_CLIENTE_FAC, ' +
    'ESIVA_EXENTO_CLIENTE_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    'ESRETENCIONES_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
    'ESINTRACOMUNITARIO_CLIENTE_FAC, ESIRPF_IMP_INCL_ZONA_IVA_FAC, ' +
    'ESAPLICA_RE_ZONA_IVA_FAC, ESIVAAGRICOLA_ZONA_IVA_FAC, ' +
    'PALABRA_REPORTS_ZONA_IVA_FAC, PORCENTAJE_IVAN_FAC, ' +
    'PORCENTAJE_REN_FAC, PORCENTAJE_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'PORCENTAJE_IVAS_FAC, PORCENTAJE_RES_FAC, PORCENTAJE_IVAE_FAC, ' +
    'PORCENTAJE_REE_FAC, FORMA_PAGO_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
    'COMENTARIOS_FAC, CONTADOR_LINEAS_FAC, ESCREARARTICULOS_FAC, ' +
    'ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :HASTA, ''N'', ''NORMAL'', ''N'', ' +
    '''BORRADOR'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
    'E.MOVIL_EMP, E.EMAIL_EMP, E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, E.ESRETENCIONES_EMP, ' +
    'E.GRUPO_ZONA_IVA_EMP, E.ESREGIMENESPECIALAGRICOLA_EMP, ' +
    'CONCAT(''EMPRESA:'', D.CODIGO_EMP_EMP), D.RAZON_SOCIAL_EMP, ' +
    'D.NIF_EMP, D.MOVIL_EMP, D.EMAIL_EMP, D.DIRECCION1_EMP, ' +
    'D.DIRECCION2_EMP, D.POBLACION_EMP, D.PROVINCIA_EMP, ' +
    'D.CODIGO_POSTAL_EMP, D.CODIGO_PAI_EMP, D.NOMBRE_PAI_EMP, ' +
    'I.CODIGO_IVA, ''N'', ''N'', D.ESREGIMENESPECIALAGRICOLA_EMP, ' +
    'D.ESRETENCIONES_EMP, ''N'', ''N'', ' +
    'COALESCE(G.ESIRPF_IMP_INCL_IVA_IVAGRP, ''N''), ' +
    'COALESCE(G.ESAPLICA_RE_IVA_IVAGRP, ''S''), ' +
    'COALESCE(G.ESIVAAGRICOLA_IVA_IVAGRP, ''N''), ' +
    'COALESCE(G.PALABRA_REPORTS_IVA_IVAGRP, ''IVA''), ' +
    'I.PORCENTAJE_NORMAL_IVA, I.PORCENTAJE_NORMAL_RE_IVA, ' +
    'I.PORCENTAJE_REDUCIDO_IVA, I.PORCENTAJE_REDUCIDO_RE_IVA, ' +
    'I.PORCENTAJE_SUPERREDUCIDO_IVA, ' +
    'I.PORCENTAJE_SUPERREDUCIDO_RE_IVA, I.PORCENTAJE_EXENTO_IVA, ' +
    'I.PORCENTAJE_EXENTO_RE_IVA, ''CONTADO'', ' +
    'E.TEXTO_LEGAL_FACTURA_EMP, ' +
    'CONCAT(''Factura interna TA. Periodo '', :DESDE, '' a '', :HASTA), ' +
    '''0000'', ''N'', ''S'', ''N'', NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_empresas E JOIN fza_empresas D ' +
    ' ON D.CODIGO_EMP_EMP = :EMPRESA ' +
    'JOIN fza_ivas I ON I.IVA_IVAGRP = E.GRUPO_ZONA_IVA_EMP ' +
    ' AND I.FECHA_DESDE_IVA <= :HASTA ' +
    ' AND (I.FECHA_HASTA_IVA IS NULL OR I.FECHA_HASTA_IVA >= :HASTA) ' +
    'LEFT JOIN fza_ivas_grupos G ON G.IVA_IVAGRP = I.IVA_IVAGRP ' +
    'WHERE E.CODIGO_EMP_EMP = :ORIGEN ' +
    'ORDER BY I.FECHA_DESDE_IVA DESC LIMIT 1';
  SQL_INICIAR_LINEA_FACTURA = 'SET @linea_factura_ta := 0';
  SQL_INSERTAR_LINEAS_TA =
    'INSERT INTO fza_facturas_lineas (' +
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    'CODIGO_FAM_FACLIN, TIPO_ARTICULO_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF, CODIGO_ALM_FACLIN, ' +
    'CODIGO_CAJA_FACLIN, NUMERO_OPERACION_FACLIN, NUMERO_MOV_FACLIN) ' +
    'SELECT :NUMERO, :SERIE, :ORIGEN, ' +
    'LPAD((@linea_factura_ta := @linea_factura_ta + 1), 4, ''0''), ' +
    'M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, A.CODIGO_FAM_ART, ' +
    'COALESCE(A.TIPO_ART, ''ESTANDAR''), ' +
    'COALESCE(A.TIPO_CANTIDAD_ART, ''Uds''), M.CANTIDAD_MOV, ' +
    'LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART), ' +
    '100), ''N'', COALESCE(M.PRECIO_COSTE_UNITARIO_MOV, 0), ' +
    'COALESCE(A.TIPO_IVA_ART, ''N''), ' +
    'CASE COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END, ' +
    'COALESCE(M.PRECIO_COSTE_UNITARIO_MOV, 0) * (1 + (CASE ' +
    'COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END) / 100), ' +
    'COALESCE(M.TOTAL_COSTE_MOV, M.CANTIDAD_MOV * ' +
    'M.PRECIO_COSTE_UNITARIO_MOV, 0) * (1 + (CASE ' +
    'COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END) / 100), ' +
    'COALESCE(M.TOTAL_COSTE_MOV, M.CANTIDAD_MOV * ' +
    'M.PRECIO_COSTE_UNITARIO_MOV, 0), NOW(), NOW(), ' +
    ':USUARIO, :USUARIO, ' +
    'O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
    'O.NUMERO_OPERACION_OPCAJA, M.NUMERO_MOV ' +
    'FROM fza_facturas_operaciones_caja X ' +
    'JOIN fza_caja_operaciones O ON O.ID_OPCAJA = X.ID_OPCAJA_FACOP ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = :SERIE ' +
    ' AND F.NUMERO_FAC = :NUMERO ' +
    'JOIN fza_ivas I ON I.CODIGO_IVA = F.CODIGO_IVA_FAC ' +
    'WHERE X.SERIE_FAC_FACOP = :SERIE ' +
    ' AND X.NUMERO_FAC_FACOP = :NUMERO ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, M.LINEA_MOV';
  SQL_ENLAZAR_OPERACIONES_TA =
    'INSERT IGNORE INTO fza_facturas_operaciones_caja (' +
    'ID_FACPER_FACOP, ID_OPCAJA_FACOP, SERIE_FAC_FACOP, ' +
    'NUMERO_FAC_FACOP, ' +
    'CODIGO_EMP_ORIGEN_FACOP, CODIGO_EMP_DESTINO_FACOP, ' +
    'NUMERO_OPERACION_FACOP, FECHA_OPERACION_FACOP, ' +
    'IMPORTE_OPERACION_FACOP, ESTADO_FACOP, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_PERIODO, O.ID_OPCAJA, :SERIE, :NUMERO, ' +
    'O.CODIGO_EMP_OPCAJA, ' +
    'O.CODIGO_EMP_CONTRA_OPCAJA, O.NUMERO_OPERACION_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)), ' +
    'O.IMPORTE_TOTAL_OPCAJA, ''FACTURADA'', NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_caja_operaciones O ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    ' AND EXISTS (SELECT 1 FROM fza_movimientos_almacen M ' +
    ' WHERE M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA)';
  SQL_RECALCULAR_FACTURA =
    'CALL PRC_CALCULAR_FACTURA_NETOS(:SERIE, :NUMERO)';
  SQL_CONTAR_OPERACIONES_FACTURA =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_facturas_operaciones_caja ' +
    'WHERE SERIE_FAC_FACOP = :SERIE AND NUMERO_FAC_FACOP = :NUMERO';
  SQL_ACTUALIZAR_CONTADOR_LINEAS_FACTURA =
    'UPDATE fza_facturas SET CONTADOR_LINEAS_FAC = LPAD(:LINEAS, 4, ''0'') ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';

type
  TGrupoTraspaso = record
    Empresa: string;
    Almacen: string;
  end;

constructor TRepositorioFacturasProformaUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion);
begin
  inherited Create;
  if not Assigned(AConexion) then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  if not Assigned(AParametrosApp) then
  begin
    raise EArgumentNilException.Create('AParametrosApp');
  end;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
end;

destructor TRepositorioFacturasProformaUniDAC.Destroy;
begin
  FParametrosApp := nil;
  inherited;
end;

procedure TRepositorioFacturasProformaUniDAC.ActualizarPeriodo(
  AIdPeriodo: Int64;
  const AEstado: string;
  const AResultado: TResultadoFacturacionCaja;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ACTUALIZAR_PERIODO;
    oConsulta.ParamByName('ID_PERIODO').AsLargeInt := AIdPeriodo;
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    oConsulta.ParamByName('DOCUMENTOS').AsInteger :=
      AResultado.CantidadDocumentos;
    oConsulta.ParamByName('OPERACIONES').AsInteger :=
      AResultado.CantidadOperaciones;
    oConsulta.ParamByName('AJUSTES').AsInteger :=
      AResultado.CantidadAjustes;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioFacturasProformaUniDAC.AsignarSolicitud(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionCaja);
begin
  if AConsulta.Params.FindParam('DESDE') <> nil then
  begin
    AConsulta.ParamByName('DESDE').AsDate := Trunc(ASolicitud.FechaDesde);
  end;
  if AConsulta.Params.FindParam('HASTA') <> nil then
  begin
    AConsulta.ParamByName('HASTA').AsDate := Trunc(ASolicitud.FechaHasta);
  end;
  if AConsulta.Params.FindParam('EMPRESA') <> nil then
  begin
    AConsulta.ParamByName('EMPRESA').AsString :=
      ASolicitud.CodigoEmpresaDestino;
  end;
  if AConsulta.Params.FindParam('USUARIO') <> nil then
  begin
    AConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarCandidatasVenta(
  const ASolicitud: TSolicitudFacturacionCaja): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_CANDIDATAS_VENTA;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.CrearPeriodo(
  const AModalidad: string;
  const ASolicitud: TSolicitudFacturacionCaja): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_INSERTAR_PERIODO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('MODALIDAD').AsString := AModalidad;
    oConsulta.Execute;
    Result := ObtenerIdentidad;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.RevisarPeriodo(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TRevisionPeriodoFacturacionCaja;
var
  sModalidad: string;
  iDuplicados: Integer;
  iSolapados: Integer;
  oConsulta: TUniQuery;
begin
  Result := Default(TRevisionPeriodoFacturacionCaja);
  if AModalidad = mfcVenta then
  begin
    sModalidad := 'VE';
  end
  else
  begin
    sModalidad := 'TA';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_REVISAR_PERIODO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('MODALIDAD').AsString := sModalidad;
    oConsulta.Open;
    iDuplicados := oConsulta.FieldByName('DUPLICADOS').AsInteger;
    iSolapados := oConsulta.FieldByName('SOLAPADOS').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
  Result.EsDuplicado := iDuplicados > 0;
  Result.EsSolapado := iSolapados > iDuplicados;
  if Result.EsDuplicado then
  begin
    Result.Descripcion :=
      'Ya existe una generación con el mismo periodo y modalidad.';
  end
  else if Result.EsSolapado then
  begin
    Result.Descripcion :=
      'El periodo se solapa con una generación anterior.';
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarLineasTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_LINEAS_TRASPASO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacenOrigen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarLineasFacturaTraspaso(
  const ASerie: string;
  const ANumero: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_LINEAS_FACTURA_TA;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerIdentidad: Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerNumeroDocumento(
  const ASerie: string;
  const ATipoDocumento: string;
  const AEmpresa: string;
  const AUsuario: string): string;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('pserie').AsString := ASerie;
    oProcedimiento.ParamByName('pTipoDoc').AsString := ATipoDocumento;
    oProcedimiento.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    oProcedimiento.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    oProcedimiento.Execute;
    Result := oProcedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerSerieFactura(
  const AEmpresa: string;
  const AAlmacen: string;
  const AFecha: TDateTime): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_OBTENER_SERIE_FACTURA;
    oConsulta.ParamByName('ORIGEN').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('EMPSER').AsString;
    end;
    oConsulta.Close;
    if Result = '' then
    begin
      oConsulta.SQL.Text := SQL_OBTENER_SERIE_CONTADOR;
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresa;
      oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        Result := oConsulta.FieldByName('EMPSER').AsString;
      end;
    end;
    if Result = '' then
    begin
      raise Exception.CreateFmt(
        'No existe una serie FC NORMAL activa para la empresa %s.',
        [AEmpresa]);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarVenta(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
var
  iIdPeriodo: Int64;
  iIdProforma: Int64;
  sNumero: string;
  sSerie: string;
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoFacturacionCaja);
  iIdPeriodo := CrearPeriodo('VE', ASolicitud);
  try
    if ContarCandidatasVenta(ASolicitud) > 0 then
    begin
      sSerie := 'PVE-' + FormatDateTime('yyyy', ASolicitud.FechaHasta);
      sNumero := ObtenerNumeroDocumento(
        sSerie,
        'PF',
        ASolicitud.CodigoEmpresaDestino,
        ASolicitud.Usuario);
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        FConexion.StartTransaction;
        try
          oConsulta.SQL.Text := SQL_INSERTAR_PROFORMA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID_PERIODO').AsLargeInt := iIdPeriodo;
          oConsulta.ParamByName('SERIE').AsString := sSerie;
          oConsulta.ParamByName('NUMERO').AsString := sNumero;
          oConsulta.Execute;
          if oConsulta.RowsAffected = 0 then
          begin
            raise Exception.Create(
              'No se pudo crear la cabecera de la proforma de caja.');
          end;
          iIdProforma := ObtenerIdentidad;
          oConsulta.SQL.Text := SQL_INICIAR_LINEA_PROFORMA;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_INSERTAR_LINEAS_VENTA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_CONTINUAR_LINEA_PROFORMA;
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_INSERTAR_AJUSTES_VENTA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_ACTUALIZAR_TOTALES_PROFORMA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_CONTAR_PROFORMA;
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Open;
          Result.CantidadOperaciones :=
            oConsulta.FieldByName('OPERACIONES').AsInteger;
          Result.CantidadAjustes :=
            oConsulta.FieldByName('AJUSTES').AsInteger;
          oConsulta.Close;
          if Result.CantidadOperaciones > 0 then
          begin
            Result.CantidadDocumentos := 1;
            Result.Descripcion := Format(
              'Proforma %s/%s generada con %d operaciones y %d ajustes.',
              [sSerie, sNumero, Result.CantidadOperaciones,
               Result.CantidadAjustes]);
            ActualizarPeriodo(
              iIdPeriodo,
              'CERRADO',
              Result,
              ASolicitud.Usuario);
            FConexion.Commit;
          end
          else
          begin
            FConexion.Rollback;
          end;
        except
          if FConexion.InTransaction then
          begin
            FConexion.Rollback;
          end;
          raise;
        end;
      except
        FreeAndNil(oConsulta);
        raise;
      end;
      FreeAndNil(oConsulta);
    end;
    if Result.CantidadDocumentos = 0 then
    begin
      ActualizarPeriodo(
        iIdPeriodo,
        'SIN_DOCUMENTOS',
        Result,
        ASolicitud.Usuario);
    end;
  except
    ActualizarPeriodo(
      iIdPeriodo,
      'ERROR',
      Result,
      ASolicitud.Usuario);
    raise;
  end;
end;

function TRepositorioFacturasProformaUniDAC.ReservarOperacionesTraspaso(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const ASerie: string;
  const ANumero: string): Integer;
begin
  AConsulta.SQL.Text := SQL_ENLAZAR_OPERACIONES_TA;
  AsignarSolicitud(AConsulta, ASolicitud);
  AConsulta.ParamByName('ID_PERIODO').AsLargeInt := AIdPeriodo;
  AConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
  AConsulta.ParamByName('ALMACEN').AsString := AAlmacenOrigen;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  AConsulta.SQL.Text := SQL_CONTAR_OPERACIONES_FACTURA;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Open;
  Result := AConsulta.FieldByName('CANTIDAD').AsInteger;
  AConsulta.Close;
end;

procedure TRepositorioFacturasProformaUniDAC.InsertarLineasFacturaTraspaso(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionCaja;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const ASerie: string;
  const ANumero: string);
var
  iLineas: Integer;
begin
  iLineas := ContarLineasFacturaTraspaso(ASerie, ANumero);
  if iLineas > 9999 then
  begin
    raise Exception.CreateFmt(
      'La factura TA de %s/%s tendría %d líneas; el máximo es 9999.',
      [AEmpresaOrigen, AAlmacenOrigen, iLineas]);
  end;
  if iLineas = 0 then
  begin
    raise Exception.Create(
      'Las operaciones TA reservadas no tienen líneas activas.');
  end;
  AConsulta.SQL.Text := SQL_INICIAR_LINEA_FACTURA;
  AConsulta.Execute;
  AConsulta.SQL.Text := SQL_INSERTAR_LINEAS_TA;
  AsignarSolicitud(AConsulta, ASolicitud);
  AConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
  AConsulta.ParamByName('ALMACEN').AsString := AAlmacenOrigen;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> iLineas then
  begin
    raise Exception.CreateFmt(
      'Se esperaban %d líneas TA y se han generado %d.',
      [iLineas, AConsulta.RowsAffected]);
  end;
  AConsulta.SQL.Text := SQL_ACTUALIZAR_CONTADOR_LINEAS_FACTURA;
  AConsulta.ParamByName('LINEAS').AsInteger := iLineas;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  AConsulta.SQL.Text := SQL_RECALCULAR_FACTURA;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  ValidarRequisitosFiscalesEmision(
    FParametrosApp,
    FConexion,
    ASerie,
    ANumero);
end;

function TRepositorioFacturasProformaUniDAC.CrearBorradorFacturaTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const ASerie: string;
  const ANumero: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text := SQL_INSERTAR_FACTURA_TA;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.Execute;
      if oConsulta.RowsAffected = 0 then
      begin
        raise Exception.CreateFmt(
          'No se pudo crear la factura TA de la empresa %s.',
          [AEmpresaOrigen]);
      end;
      Result := ReservarOperacionesTraspaso(
        oConsulta,
        ASolicitud,
        AIdPeriodo,
        AEmpresaOrigen,
        AAlmacenOrigen,
        ASerie,
        ANumero);
      if Result > 0 then
      begin
        InsertarLineasFacturaTraspaso(
          oConsulta,
          ASolicitud,
          AEmpresaOrigen,
          AAlmacenOrigen,
          ASerie,
          ANumero);
        FConexion.Commit;
      end
      else
      begin
        FConexion.Rollback;
      end;
    except
      if FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarFacturaTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string): Integer;
var
  iLineas: Integer;
  sNumero: string;
  sSerie: string;
begin
  Result := 0;
  iLineas := ContarLineasTraspaso(ASolicitud, AEmpresaOrigen,
    AAlmacenOrigen);
  if iLineas > 9999 then
  begin
    raise Exception.CreateFmt(
      'La factura TA de %s/%s tendría %d líneas; el máximo es 9999.',
      [AEmpresaOrigen, AAlmacenOrigen, iLineas]);
  end;
  if iLineas > 0 then
  begin
    sSerie := ObtenerSerieFactura(AEmpresaOrigen, AAlmacenOrigen,
      ASolicitud.FechaHasta);
    sNumero := ObtenerNumeroDocumento(
      sSerie,
      'FC',
      AEmpresaOrigen,
      ASolicitud.Usuario);
    Result := CrearBorradorFacturaTraspaso(
      ASolicitud,
      AIdPeriodo,
      AEmpresaOrigen,
      AAlmacenOrigen,
      sSerie,
      sNumero);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarTraspasos(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
var
  iIdPeriodo: Int64;
  iIndice: Integer;
  iOperaciones: Integer;
  aGrupos: TArray<TGrupoTraspaso>;
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoFacturacionCaja);
  iIdPeriodo := CrearPeriodo('TA', ASolicitud);
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_GRUPOS_TRASPASO;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        SetLength(aGrupos, Length(aGrupos) + 1);
        aGrupos[High(aGrupos)].Empresa :=
          oConsulta.FieldByName('EMPRESA').AsString;
        aGrupos[High(aGrupos)].Almacen :=
          oConsulta.FieldByName('ALMACEN').AsString;
        oConsulta.Next;
      end;
      oConsulta.Close;
    finally
      FreeAndNil(oConsulta);
    end;
    for iIndice := 0 to High(aGrupos) do
    begin
      iOperaciones := GenerarFacturaTraspaso(
        ASolicitud,
        iIdPeriodo,
        aGrupos[iIndice].Empresa,
        aGrupos[iIndice].Almacen);
      if iOperaciones > 0 then
      begin
        Inc(Result.CantidadDocumentos);
        Inc(Result.CantidadOperaciones, iOperaciones);
      end;
    end;
    if Result.CantidadDocumentos > 0 then
    begin
      Result.Descripcion := Format(
        '%d borradores de facturas TA con %d operaciones.',
        [Result.CantidadDocumentos, Result.CantidadOperaciones]);
      ActualizarPeriodo(
        iIdPeriodo,
        'CERRADO',
        Result,
        ASolicitud.Usuario);
    end
    else
    begin
      ActualizarPeriodo(
        iIdPeriodo,
        'SIN_DOCUMENTOS',
        Result,
        ASolicitud.Usuario);
    end;
  except
    ActualizarPeriodo(
      iIdPeriodo,
      'ERROR',
      Result,
      ASolicitud.Usuario);
    raise;
  end;
end;

end.
