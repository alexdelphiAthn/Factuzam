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
  inLibFacturasProformaIntf;

type
  TRepositorioFacturasProformaUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturasProforma)
  private
    FConexion: TUniConnection;
    procedure AsignarSolicitud(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja);
    function ContarCandidatasVenta(
      const ASolicitud: TSolicitudFacturacionCaja): Integer;
    function GenerarFacturaTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
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
  public
    constructor Create(AConexion: TUniConnection);
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
  System.Generics.Collections,
  Data.DB;

const
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
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'') ' +
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
    ' (''RECTIFICADA'', ''CANCELADA'') ' +
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
    'NUMERO_PROCAJ, SERIE_PROCAJ, FECHA_PROCAJ, ' +
    'FECHA_DESDE_PROCAJ, FECHA_HASTA_PROCAJ, TIPO_PROCAJ, ' +
    'ESTADO_PROCAJ, CODIGO_EMP_PROCAJ, ' +
    'RAZON_SOCIAL_EMPRESA_PROCAJ, NIF_EMPRESA_PROCAJ, ' +
    'DIRECCION1_EMPRESA_PROCAJ, DIRECCION2_EMPRESA_PROCAJ, ' +
    'CODIGO_POSTAL_EMPRESA_PROCAJ, POBLACION_EMPRESA_PROCAJ, ' +
    'PROVINCIA_EMPRESA_PROCAJ, CODIGO_PAI_EMPRESA_PROCAJ, ' +
    'NOMBRE_PAI_EMPRESA_PROCAJ, CODIGO_CLI_PROCAJ, ' +
    'RAZON_SOCIAL_CLIENTE_PROCAJ, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :HASTA, :DESDE, :HASTA, ''VE'', ' +
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
    'INSERT INTO fza_proformas_caja_lineas (' +
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
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = O.SERIE_FAC_OPCAJA ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = O.NUMERO_FAC_OPCAJA) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas P ' +
    ' WHERE P.ID_OPCAJA_PROCLIN = O.ID_OPCAJA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'') ' +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, L.LINEA_FACLIN';
  SQL_INSERTAR_AJUSTES_VENTA =
    'INSERT INTO fza_proformas_caja_lineas (' +
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
    ' (''RECTIFICADA'', ''CANCELADA'') ' +
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
    'MIN(O.CODIGO_ALM_OPCAJA) AS ALMACEN ' +
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
    'GROUP BY O.CODIGO_EMP_OPCAJA ' +
    'ORDER BY O.CODIGO_EMP_OPCAJA';
  SQL_OBTENER_SERIE_FACTURA =
    'SELECT S.EMPSER FROM vi_empresas_series S ' +
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
    'SELECT SERIE_CON FROM fza_contadores ' +
    'WHERE TIPO_DOC_CON = ''FC'' AND EMPRESA_CON = :ORIGEN ' +
    'AND ESACTIVO_CON = ''S'' ' +
    'ORDER BY (DEFAULT_CON = ''S'') DESC, SERIE_CON LIMIT 1';
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
    'COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART), ''N'', ' +
    'M.PRECIO_COSTE_UNITARIO_MOV, COALESCE(A.TIPO_IVA_ART, ''N''), ' +
    'CASE COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END, ' +
    'M.PRECIO_COSTE_UNITARIO_MOV * (1 + (CASE ' +
    'COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END) / 100), ' +
    'M.TOTAL_COSTE_MOV * (1 + (CASE COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END) / 100), ' +
    'M.TOTAL_COSTE_MOV, NOW(), NOW(), :USUARIO, :USUARIO, ' +
    'O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
    'O.NUMERO_OPERACION_OPCAJA, M.NUMERO_MOV ' +
    'FROM fza_caja_operaciones O ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = :SERIE ' +
    ' AND F.NUMERO_FAC = :NUMERO ' +
    'JOIN fza_ivas I ON I.CODIGO_IVA = F.CODIGO_IVA_FAC ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, M.LINEA_MOV';
  SQL_ENLAZAR_OPERACIONES_TA =
    'INSERT INTO fza_facturas_operaciones_caja (' +
    'ID_OPCAJA_FACOP, SERIE_FAC_FACOP, NUMERO_FAC_FACOP, ' +
    'CODIGO_EMP_ORIGEN_FACOP, CODIGO_EMP_DESTINO_FACOP, ' +
    'NUMERO_OPERACION_FACOP, FECHA_OPERACION_FACOP, ' +
    'IMPORTE_OPERACION_FACOP, ESTADO_FACOP, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT O.ID_OPCAJA, :SERIE, :NUMERO, O.CODIGO_EMP_OPCAJA, ' +
    'O.CODIGO_EMP_CONTRA_OPCAJA, O.NUMERO_OPERACION_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)), ' +
    'O.IMPORTE_TOTAL_OPCAJA, ''FACTURADA'', NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_caja_operaciones O ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
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

type
  TGrupoTraspaso = record
    Empresa: string;
    Almacen: string;
  end;

constructor TRepositorioFacturasProformaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
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
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        Result := oConsulta.FieldByName('SERIE_CON').AsString;
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
  iIdProforma: Int64;
  sNumero: string;
  sSerie: string;
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoFacturacionCaja);
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
        if Result.CantidadOperaciones = 0 then
        begin
          raise Exception.Create(
            'Las operaciones ya habían sido procesadas por otra sesión.');
        end;
        FConexion.Commit;
        Result.CantidadDocumentos := 1;
        Result.Descripcion := Format(
          'Proforma %s/%s generada con %d operaciones y %d ajustes.',
          [sSerie, sNumero, Result.CantidadOperaciones,
           Result.CantidadAjustes]);
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
end;

function TRepositorioFacturasProformaUniDAC.GenerarFacturaTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string): Integer;
var
  iLineas: Integer;
  sNumero: string;
  sSerie: string;
  oConsulta: TUniQuery;
begin
  Result := 0;
  sSerie := ObtenerSerieFactura(
    AEmpresaOrigen,
    AAlmacenOrigen,
    ASolicitud.FechaHasta);
  sNumero := ObtenerNumeroDocumento(
    sSerie,
    'FC',
    AEmpresaOrigen,
    ASolicitud.Usuario);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text := SQL_INSERTAR_FACTURA_TA;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Execute;
      if oConsulta.RowsAffected = 0 then
      begin
        raise Exception.CreateFmt(
          'No se pudo crear la factura TA de la empresa %s.',
          [AEmpresaOrigen]);
      end;
      oConsulta.SQL.Text := SQL_INICIAR_LINEA_FACTURA;
      oConsulta.Execute;
      oConsulta.SQL.Text := SQL_INSERTAR_LINEAS_TA;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Execute;
      iLineas := oConsulta.RowsAffected;
      if iLineas = 0 then
      begin
        raise Exception.CreateFmt(
          'No hay líneas TA pendientes para la empresa %s.',
          [AEmpresaOrigen]);
      end;
      oConsulta.SQL.Text := SQL_ENLAZAR_OPERACIONES_TA;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Execute;
      oConsulta.SQL.Text := SQL_CONTAR_OPERACIONES_FACTURA;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Open;
      Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
      oConsulta.Close;
      if Result = 0 then
      begin
        raise Exception.Create(
          'No se pudo enlazar ninguna operación TA con la factura.');
      end;
      oConsulta.SQL.Text := SQL_RECALCULAR_FACTURA;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Execute;
      if FConexion.InTransaction then
      begin
        FConexion.Commit;
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

function TRepositorioFacturasProformaUniDAC.GenerarTraspasos(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
var
  iIndice: Integer;
  iOperaciones: Integer;
  aGrupos: TArray<TGrupoTraspaso>;
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoFacturacionCaja);
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
      aGrupos[iIndice].Empresa,
      aGrupos[iIndice].Almacen);
    Inc(Result.CantidadDocumentos);
    Inc(Result.CantidadOperaciones, iOperaciones);
  end;
  if Result.CantidadDocumentos > 0 then
  begin
    Result.Descripcion := Format(
      '%d facturas TA generadas en borrador con %d operaciones.',
      [Result.CantidadDocumentos, Result.CantidadOperaciones]);
  end;
end;

end.
