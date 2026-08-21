{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesMaterializacionRepositorio              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas UniDAC usadas durante materialización y reversión de sesiones.   }
{******************************************************************************}
unit UniDataComprasSesionesMaterializacionRepositorio;

interface

uses
  Uni,
  inLibCatalogoSqlIntf,
  inLibComprasSesionesLecturasIntf;

type
  TRepositorioLecturasMaterializacionComprasSesiones = class(
    TInterfacedObject,
    ILecturasArticulosMaterializacion,
    ILecturasDocumentosMaterializacion,
    ILecturasEstadoMaterializacion,
    ILecturasPendientesMaterializacion,
    ILecturasReversionMaterializacion)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function ConsultarReferenciasDocumento(
      const ADefinicion: TDefinicionSql;
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarDocumentos(
      const ADefinicion: TDefinicionSql;
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    function ObtenerSiguienteSecuenciaEan(
      const APrefijo: string;
      ALongitudSecuencia: Integer): Int64;
    function ObtenerIdColorBasico(
      const ACodigoColor: string): Integer;
    function BuscarValorColor(
      const AValor: string): TValorColorMaterializacion;
    function ObtenerColorLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TColorLineaMaterializacion;
    function ConsultarSkusSesion(
      const ASerie, ANumero: string;
      ALinea: Integer): TSkusSesionMaterializacion;
    function ExisteEan13Sku(
      const ACodigoSku: string): Boolean;
    function ExisteProveedorPrincipalDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): Boolean;
    function ObtenerCodigoUnicoTarifa(
      const ACodigoArticulo,
      ACodigoTarifa: string): Integer;
    function ResolverCodigoSku(
      const ACodigoArticulo: string;
      AIdAvPivot, AIdAvFila: Integer): string;
    function ConsultarLineasArticulos(
      const ASerie, ANumero: string):
      TLineasArticuloMaterializacion;
    function ConsultarLineasDocumento(
      const ASerie, ANumero, AAlmacenCabecera,
      AFiltroAlmacen: string):
      TLineasDocumentoCompraMaterializacion;
    function ConsultarAlmacenes(
      const ASerie, ANumero,
      AAlmacenCabecera: string): TArray<string>;
    function ConsultarPendientesRecibir(
      const ASerie, ANumero,
      AAlmacenCabecera: string):
      TPendientesRecibirMaterializacion;
    function ExisteTabla(
      const ATabla: string): Boolean;
    function ConsultarDocumentosSesion(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
    function ConsultarFacturasCompraAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarSalidasPosterioresAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarAlbaranesPedido(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibCatalogoSqlEjecucion;

const
  REPOSITORIO = 'RepositorioMaterializacionComprasSesiones';
  SQL_SIGUIENTE_SECUENCIA_EAN =
    'SELECT IFNULL(MAX(CAST(SUBSTRING(CODIGO_BARRAS_CB, :pl + 1, :lq) AS ' +
    'UNSIGNED)), 0) + 1 AS N ' +
    '  FROM fza_codigos_barras ' +
    ' WHERE CODIGO_BARRAS_CB LIKE :pat ' +
    '   AND TIPO_CODIGO_CB = ''EAN13''';
  SQL_ID_COLOR_BASICO =
    'SELECT ID_ATB FROM fza_atributos_basicos ' +
    ' WHERE ID_VA_ATB = ''CO'' AND CODIGO_ATB = :cod LIMIT 1';
  SQL_VALOR_COLOR =
    'SELECT ID_AV, ID_ATB_AV FROM fza_atributos_valores ' +
    ' WHERE ID_VA_AV = ''CO'' AND AV = :v LIMIT 1';
  SQL_COLOR_LINEA =
    'SELECT COLOR_TEXTO_SESLIN, CODIGO_ATB_COLOR_SESLIN ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND LINEA_SESLIN = :l';
  SQL_SKUS_SESION =
    'SELECT C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
    '       SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
    '       AVP.AV AS VAL_PIVOT, ' +
    '       (SELECT GROUP_CONCAT(AV2.AV SEPARATOR ''/'') ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '          JOIN fza_atributos_valores AV2 ' +
    '            ON AV2.ID_AV = FA.ID_AV_SESFILAT ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL) ' +
    '       AS VAL_FILA, ' +
    '       (SELECT MIN(FA.ID_AV_SESFILAT) ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL) ' +
    '       AS ID_AV_FILA ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    '  JOIN fza_atributos_valores AVP ' +
    '    ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.LINEA_SES_SESCEL = :l ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    ' GROUP BY C.SERIE_SES_SESCEL, C.NUMERO_SES_SESCEL, ' +
    '          C.LINEA_SES_SESCEL, C.ID_FILA_SES_SESCEL, ' +
    '          C.ID_AV_PIVOT_SESCEL, AVP.AV';
  SQL_EXISTE_EAN13_SKU =
    'SELECT COUNT(*) AS N FROM fza_codigos_barras ' +
    ' WHERE CODIGO_UNIDAD_CB = :sku ' +
    '   AND TIPO_CODIGO_CB = ''EAN13''';
  SQL_PROVEEDOR_PRINCIPAL_DISTINTO =
    'SELECT COUNT(*) AS N ' +
    '  FROM fza_articulos_proveedores ' +
    ' WHERE CODIGO_ART_AP = :art ' +
    '   AND CODIGO_PRV_AP <> :prv ' +
    '   AND ESPROVEEDORPRINCIPAL_AP = ''S''';
  SQL_CODIGO_UNICO_TARIFA =
    'SELECT CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas ' +
    ' WHERE CODIGO_ART_ARTTAR = :art ' +
    '   AND CODIGO_UNIDAD_ARTTAR = '''' ' +
    '   AND CODIGO_TAR_ARTTAR = :tar ' +
    ' LIMIT 1';
  SQL_RESOLVER_SKU_CON_FILA =
    'SELECT sk.CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus sk ' +
    ' WHERE sk.CODIGO_ART_SKU = :art ' +
    '   AND sk.ESACTIVO_SKU = ''S'' ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :pivot) ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :fila) ' +
    ' LIMIT 1';
  SQL_RESOLVER_SKU_SIN_FILA =
    'SELECT sk.CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus sk ' +
    ' WHERE sk.CODIGO_ART_SKU = :art ' +
    '   AND sk.ESACTIVO_SKU = ''S'' ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :pivot) ' +
    ' LIMIT 1';
  SQL_LINEAS_ARTICULOS =
    'SELECT L.LINEA_SESLIN, L.ACCION_DUPLICADO_SESLIN, ' +
    '       L.CODIGO_ART_REUSAR_SESLIN, ' +
    '       L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.TIPO_LINEA_SESLIN, L.REF_PRV_SESLIN, ' +
    '       L.PRECIO_VENTA_SESLIN, ' +
    ' CASE WHEN ' +
    'IFNULL(S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N'') <> ''S'' ' +
    ' AND IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
    ' IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')) = ''S'' ' +
    ' THEN L.PRECIO_COMPRA_SESLIN * ' +
    ' (1 + (CASE (CASE WHEN ' +
    ' IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    ' THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    ' NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    ' ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
    ' WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_IVA, 0) ' +
    ' WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_IVA, 0) ' +
    ' WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_IVA, 0) ' +
    ' WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_IVA, 0) ' +
    ' ELSE 0 END + CASE (CASE WHEN ' +
    ' IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    ' THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    ' NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    ' ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
    ' WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
    ' WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
    ' WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
    ' WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
    ' ELSE 0 END) / 100) ' +
    ' ELSE L.PRECIO_COMPRA_SESLIN END AS PRECIO_COSTE_PROVEEDOR ' +
    ' FROM fza_compras_sesiones_lineas L ' +
    ' JOIN fza_compras_sesiones S ' +
    ' ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    ' AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    ' LEFT JOIN fza_empresas E ' +
    ' ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
    ' LEFT JOIN vi_ivas_empresa V ' +
    ' ON V.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
    ' AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    ' AND L.NUMERO_SES_SESLIN = :n ' +
    ' ORDER BY L.LINEA_SESLIN';
  SQL_LINEAS_DOCUMENTO =
    'SELECT CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    '       THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    '       ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
    '       C.ID_AV_PIVOT_SESCEL, ' +
    '       IFNULL(L.ID_AC_PIVOT_SESLIN, 0) AS ID_AC_PIVOT, ' +
    '       IFNULL(L.CODIGO_ATB_COLOR_SESLIN, '''') AS COD_COLOR, ' +
    '       IFNULL(L.COLOR_TEXTO_SESLIN, '''') AS COLOR_TEXTO, ' +
    '       IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '              :alm_cab) AS ALM_EFE, ' +
    '       SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
    '       L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
    '       L.CODIGO_FAM_SESLIN, ' +
    '       CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    '       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    '                     NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       END AS TIPO_IVA, L.TIPO_LINEA_SESLIN, ' +
    '       IFNULL(L.REF_PRV_SESLIN, '''') AS REF_PRV ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL ' +
    '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
    '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    '   AND (:falm = '''' OR ' +
    '        IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '               :alm_cab) = :falm) ' +
    ' GROUP BY CODIGO_ART, C.ID_AV_PIVOT_SESCEL, ID_AC_PIVOT, ' +
    '          COD_COLOR, COLOR_TEXTO, ALM_EFE, ' +
    '          L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
    '          L.CODIGO_FAM_SESLIN, TIPO_IVA, ' +
    '          L.TIPO_LINEA_SESLIN, REF_PRV ' +
    ' ORDER BY CODIGO_ART, COD_COLOR, ' +
    '          C.ID_AV_PIVOT_SESCEL, ALM_EFE';
  SQL_ALMACENES =
    'SELECT DISTINCT IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '                       :alm_cab) AS ALM ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    ' ORDER BY ALM';
  SQL_PENDIENTES_RECIBIR =
    'SELECT C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
    '       C.CANTIDAD_SESCEL, ' +
    '       IFNULL(NULLIF(C.CODIGO_ALM_SESCEL,''''), ' +
    '              :alm_cab) AS ALM_EFE, ' +
    '       L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.CODIGO_ART_REUSAR_SESLIN, ' +
    '       L.ACCION_DUPLICADO_SESLIN, ' +
    '       CASE WHEN IFNULL(' +
    '         S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N'') <> ''S'' ' +
    '       AND IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
    '         IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')) = ''S'' ' +
    '       THEN L.PRECIO_COMPRA_SESLIN * ' +
    '       (1 + (CASE (CASE WHEN IFNULL(' +
    '         S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    '       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    '         NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
    '       WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_IVA, 0) ' +
    '       WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_IVA, 0) ' +
    '       WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_IVA, 0) ' +
    '       WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_IVA, 0) ' +
    '       ELSE 0 END + CASE (CASE WHEN IFNULL(' +
    '         S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    '       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    '         NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
    '       WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
    '       WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
    '       WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
    '       WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
    '       ELSE 0 END) / 100) ' +
    '       ELSE L.PRECIO_COMPRA_SESLIN END ' +
    '       AS PRECIO_COMPRA_SESLIN, ' +
    '       L.TIPO_LINEA_SESLIN, L.ID_VA_FILA_SESLIN ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL ' +
    '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
    '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    '  LEFT JOIN fza_empresas E ' +
    '    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
    '  LEFT JOIN vi_ivas_empresa V ' +
    '    ON V.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
    '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    ' ORDER BY C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL';
  SQL_EXISTE_TABLA =
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES ' +
    ' WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t';
  SQL_DOCUMENTOS_REVERSION =
    'SELECT TIPO_DOC_SESDOC, SERIE_SESDOC, NUMERO_SESDOC ' +
    '  FROM fza_compras_sesiones_documentos ' +
    ' WHERE SERIE_SES_SESDOC = :s ' +
    '   AND NUMERO_SES_SESDOC = :n ' +
    ' ORDER BY TIPO_DOC_SESDOC, SERIE_SESDOC, NUMERO_SESDOC, ' +
    '          CODIGO_ALM_SESDOC ' +
    ' FOR UPDATE';
  SQL_FACTURAS_COMPRA_ALBARAN =
    'SELECT DISTINCT I.DOCUMENTO ' +
    '  FROM ( ' +
    '    SELECT CASE WHEN IFNULL(H.SERIE_FAC_ALBC, '''') <> '''' ' +
    '                      OR IFNULL(H.NUMERO_FAC_ALBC, '''') <> '''' ' +
    '                THEN CONCAT(IFNULL(H.SERIE_FAC_ALBC, ''?''), ''/'', ' +
    '                            IFNULL(H.NUMERO_FAC_ALBC, ''?'')) ' +
    '                ELSE ''(marcado como facturado)'' END AS DOCUMENTO ' +
    '      FROM fza_albaranes_compra H ' +
    '     WHERE H.SERIE_ALBC = :s AND H.NUMERO_ALBC = :n ' +
    '       AND (H.ESTADO_ALBC = ''FACTURADO'' ' +
    '         OR IFNULL(H.SERIE_FAC_ALBC, '''') <> '''' ' +
    '         OR IFNULL(H.NUMERO_FAC_ALBC, '''') <> '''') ' +
    '    UNION ALL ' +
    '    SELECT CASE WHEN IFNULL(L.SERIE_FAC_ALBCLIN, '''') <> '''' ' +
    '                      OR IFNULL(L.NUMERO_FAC_ALBCLIN, '''') <> '''' ' +
    '                THEN CONCAT(IFNULL(L.SERIE_FAC_ALBCLIN, ''?''), ''/'', ' +
    '                            IFNULL(L.NUMERO_FAC_ALBCLIN, ''?'')) ' +
    '                ELSE ''(linea marcada como facturada)'' END ' +
    '      FROM fza_albaranes_compra_lineas L ' +
    '     WHERE L.SERIE_ALBC_ALBCLIN = :s ' +
    '       AND L.NUMERO_ALBC_ALBCLIN = :n ' +
    '       AND (IFNULL(L.ESFACTURADA_ALBCLIN, ''N'') = ''S'' ' +
    '         OR IFNULL(L.SERIE_FAC_ALBCLIN, '''') <> '''' ' +
    '         OR IFNULL(L.NUMERO_FAC_ALBCLIN, '''') <> '''') ' +
    '    UNION ALL ' +
    '    SELECT CONCAT(IFNULL(F.SERIE_FACC_FACCLIN, ''?''), ''/'', ' +
    '                  IFNULL(F.NUMERO_FACC_FACCLIN, ''?'')) ' +
    '      FROM fza_facturas_compra_lineas F ' +
    '     WHERE F.SERIE_ALBC_FACCLIN = :s ' +
    '       AND F.NUMERO_ALBC_FACCLIN = :n ' +
    '  ) I ' +
    ' ORDER BY I.DOCUMENTO LIMIT 10 FOR UPDATE';
  SQL_SALIDAS_POSTERIORES_ALBARAN =
    'SELECT DISTINCT CONCAT(V.TIPO_DOC_MOV, '' '', V.SERIE_DOC_MOV, ''/'', ' +
    '       V.NUMERO_DOC_MOV, '', SKU '', V.CODIGO_UNIDAD_MOV, ' +
    '       '', almacen '', V.CODIGO_ALM_MOV) AS DOCUMENTO ' +
    '  FROM fza_movimientos_almacen C ' +
    '  JOIN fza_movimientos_almacen V ' +
    '    ON V.CODIGO_EMP_MOV = C.CODIGO_EMP_MOV ' +
    '   AND V.CODIGO_ALM_MOV = C.CODIGO_ALM_MOV ' +
    '   AND V.CODIGO_UNIDAD_MOV = C.CODIGO_UNIDAD_MOV ' +
    ' WHERE C.TIPO_DOC_MOV = ''AC'' ' +
    '   AND C.TIPO_MOV = ''E'' ' +
    '   AND IFNULL(C.ESACTIVO_MOV, ''S'') = ''S'' ' +
    '   AND C.SERIE_DOC_MOV = :s AND C.NUMERO_DOC_MOV = :n ' +
    '   AND V.TIPO_MOV = ''S'' ' +
    '   AND IFNULL(V.ESACTIVO_MOV, ''S'') = ''S'' ' +
    '   AND COALESCE(V.FECHA_MOV, V.INSTANTE_ALTA) >= ' +
    '       COALESCE(C.FECHA_MOV, C.INSTANTE_ALTA) ' +
    ' ORDER BY DOCUMENTO LIMIT 10 FOR UPDATE';
  SQL_ALBARANES_PEDIDO =
    'SELECT DISTINCT I.TIPO_DOC_SESDOC, I.SERIE_SESDOC, ' +
    '       I.NUMERO_SESDOC ' +
    '  FROM ( ' +
    '    SELECT ''ALBC'' AS TIPO_DOC_SESDOC, ' +
    '           H.SERIE_ALBC AS SERIE_SESDOC, ' +
    '           H.NUMERO_ALBC AS NUMERO_SESDOC ' +
    '      FROM fza_albaranes_compra H ' +
    '     WHERE H.SERIE_PED_ALBC = :s AND H.NUMERO_PED_ALBC = :n ' +
    '    UNION ALL ' +
    '    SELECT ''ALBC'', L.SERIE_ALBC_ALBCLIN, ' +
    '           L.NUMERO_ALBC_ALBCLIN ' +
    '      FROM fza_albaranes_compra_lineas L ' +
    '     WHERE L.SERIE_PEDC_ALBCLIN = :s ' +
    '       AND L.NUMERO_PEDC_ALBCLIN = :n ' +
    '  ) I ' +
    ' WHERE IFNULL(I.SERIE_SESDOC, '''') <> '''' ' +
    '   AND IFNULL(I.NUMERO_SESDOC, '''') <> '''' ' +
    ' ORDER BY I.SERIE_SESDOC, I.NUMERO_SESDOC FOR UPDATE';

function Definicion(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    REPOSITORIO,
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionSiguienteSecuenciaEan: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerSiguienteSecuenciaEan',
    SQL_SIGUIENTE_SECUENCIA_EAN,
    'pl,lq,pat',
    'N');
end;

function DefinicionIdColorBasico: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerIdColorBasico',
    SQL_ID_COLOR_BASICO,
    'cod',
    'ID_ATB');
end;

function DefinicionValorColor: TDefinicionSql;
begin
  Result := Definicion(
    'BuscarValorColor',
    SQL_VALOR_COLOR,
    'v',
    'ID_AV,ID_ATB_AV');
end;

function DefinicionColorLinea: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerColorLinea',
    SQL_COLOR_LINEA,
    's,n,l',
    'COLOR_TEXTO_SESLIN,CODIGO_ATB_COLOR_SESLIN');
end;

function DefinicionSkusSesion: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarSkusSesion',
    SQL_SKUS_SESION,
    's,n,l',
    'ID_FILA_SES_SESCEL,ID_AV_PIVOT_SESCEL,CANTIDAD_TOTAL,' +
    'VAL_PIVOT,VAL_FILA,ID_AV_FILA');
end;

function DefinicionExisteEan13Sku: TDefinicionSql;
begin
  Result := Definicion(
    'ExisteEan13Sku',
    SQL_EXISTE_EAN13_SKU,
    'sku',
    'N');
end;

function DefinicionProveedorPrincipalDistinto: TDefinicionSql;
begin
  Result := Definicion(
    'ExisteProveedorPrincipalDistinto',
    SQL_PROVEEDOR_PRINCIPAL_DISTINTO,
    'art,prv',
    'N');
end;

function DefinicionCodigoUnicoTarifa: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerCodigoUnicoTarifa',
    SQL_CODIGO_UNICO_TARIFA,
    'art,tar',
    'CODIGO_UNICO_ARTTAR');
end;

function DefinicionResolverSkuConFila: TDefinicionSql;
begin
  Result := Definicion(
    'ResolverCodigoSkuConFila',
    SQL_RESOLVER_SKU_CON_FILA,
    'art,pivot,fila',
    'CODIGO_UNIDAD_SKU');
end;

function DefinicionResolverSkuSinFila: TDefinicionSql;
begin
  Result := Definicion(
    'ResolverCodigoSkuSinFila',
    SQL_RESOLVER_SKU_SIN_FILA,
    'art,pivot',
    'CODIGO_UNIDAD_SKU');
end;

function DefinicionLineasArticulos: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarLineasArticulos',
    SQL_LINEAS_ARTICULOS,
    's,n',
    'LINEA_SESLIN,ACCION_DUPLICADO_SESLIN,' +
    'CODIGO_ART_REUSAR_SESLIN,CODIGO_ART_TENTATIVO_SESLIN,' +
    'TIPO_LINEA_SESLIN,REF_PRV_SESLIN,PRECIO_VENTA_SESLIN,' +
    'PRECIO_COSTE_PROVEEDOR');
end;

function DefinicionLineasDocumento: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarLineasDocumento',
    SQL_LINEAS_DOCUMENTO,
    'alm_cab,falm,s,n',
    'CODIGO_ART,ID_AV_PIVOT_SESCEL,ID_AC_PIVOT,COD_COLOR,' +
    'COLOR_TEXTO,ALM_EFE,CANTIDAD_TOTAL,PRECIO_COMPRA_SESLIN,' +
    'DESCRIPCION_SESLIN,CODIGO_FAM_SESLIN,TIPO_IVA,' +
    'TIPO_LINEA_SESLIN,REF_PRV');
end;

function DefinicionAlmacenes: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarAlmacenes',
    SQL_ALMACENES,
    'alm_cab,s,n',
    'ALM');
end;

function DefinicionPendientesRecibir: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarPendientesRecibir',
    SQL_PENDIENTES_RECIBIR,
    'alm_cab,s,n',
    'LINEA_SES_SESCEL,ID_AV_PIVOT_SESCEL,CANTIDAD_SESCEL,' +
    'ALM_EFE,CODIGO_ART_TENTATIVO_SESLIN,' +
    'CODIGO_ART_REUSAR_SESLIN,ACCION_DUPLICADO_SESLIN,' +
    'PRECIO_COMPRA_SESLIN,TIPO_LINEA_SESLIN,ID_VA_FILA_SESLIN');
end;

function DefinicionExisteTabla: TDefinicionSql;
begin
  Result := Definicion(
    'ExisteTabla',
    SQL_EXISTE_TABLA,
    't',
    'N');
end;

function DefinicionDocumentosReversion: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarDocumentosSesion',
    SQL_DOCUMENTOS_REVERSION,
    's,n',
    'TIPO_DOC_SESDOC,SERIE_SESDOC,NUMERO_SESDOC');
end;

function DefinicionFacturasCompraAlbaran: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarFacturasCompraAlbaran',
    SQL_FACTURAS_COMPRA_ALBARAN,
    's,n',
    'DOCUMENTO');
end;

function DefinicionSalidasPosterioresAlbaran: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarSalidasPosterioresAlbaran',
    SQL_SALIDAS_POSTERIORES_ALBARAN,
    's,n',
    'DOCUMENTO');
end;

function DefinicionAlbaranesPedido: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarAlbaranesPedido',
    SQL_ALBARANES_PEDIDO,
    's,n',
    'TIPO_DOC_SESDOC,SERIE_SESDOC,NUMERO_SESDOC');
end;

constructor TRepositorioLecturasMaterializacionComprasSesiones.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioLecturasMaterializacionComprasSesiones.
  DefinicionesSql: TDefinicionesSql;
begin
  SetLength(Result, 19);
  Result[0] := DefinicionSiguienteSecuenciaEan;
  Result[1] := DefinicionIdColorBasico;
  Result[2] := DefinicionValorColor;
  Result[3] := DefinicionColorLinea;
  Result[4] := DefinicionSkusSesion;
  Result[5] := DefinicionExisteEan13Sku;
  Result[6] := DefinicionProveedorPrincipalDistinto;
  Result[7] := DefinicionCodigoUnicoTarifa;
  Result[8] := DefinicionResolverSkuConFila;
  Result[9] := DefinicionResolverSkuSinFila;
  Result[10] := DefinicionLineasArticulos;
  Result[11] := DefinicionLineasDocumento;
  Result[12] := DefinicionAlmacenes;
  Result[13] := DefinicionPendientesRecibir;
  Result[14] := DefinicionExisteTabla;
  Result[15] := DefinicionDocumentosReversion;
  Result[16] := DefinicionFacturasCompraAlbaran;
  Result[17] := DefinicionSalidasPosterioresAlbaran;
  Result[18] := DefinicionAlbaranesPedido;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerSiguienteSecuenciaEan(
  const APrefijo: string;
  ALongitudSecuencia: Integer): Int64;
var
  iResultado: Int64;
  oDefinicion: TDefinicionSql;
begin
  iResultado := 0;
  oDefinicion := DefinicionSiguienteSecuenciaEan;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('pl').AsInteger := Length(APrefijo);
        oConsulta.ParamByName('lq').AsInteger :=
          ALongitudSecuencia;
        oConsulta.ParamByName('pat').AsString := APrefijo + '%';
        oConsulta.Open;
        iResultado := oConsulta.FieldByName('N').AsLargeInt;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := iResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerIdColorBasico(
  const ACodigoColor: string): Integer;
var
  iResultado: Integer;
  oDefinicion: TDefinicionSql;
begin
  iResultado := 0;
  oDefinicion := DefinicionIdColorBasico;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('cod').AsString := ACodigoColor;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          iResultado :=
            oConsulta.FieldByName('ID_ATB').AsInteger;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := iResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  BuscarValorColor(
  const AValor: string): TValorColorMaterializacion;
var
  oDefinicion: TDefinicionSql;
  oResultado: TValorColorMaterializacion;
begin
  oResultado := Default(TValorColorMaterializacion);
  oDefinicion := DefinicionValorColor;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('v').AsString := AValor;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
        begin
          oResultado.IdValor :=
            oConsulta.FieldByName('ID_AV').AsInteger;
          oResultado.TieneColorBasico :=
            not oConsulta.FieldByName('ID_ATB_AV').IsNull;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerColorLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TColorLineaMaterializacion;
var
  oDefinicion: TDefinicionSql;
  oResultado: TColorLineaMaterializacion;
begin
  oResultado := Default(TColorLineaMaterializacion);
  oDefinicion := DefinicionColorLinea;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.ParamByName('l').AsInteger := ALinea;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
        begin
          oResultado.Texto :=
            oConsulta.FieldByName(
              'COLOR_TEXTO_SESLIN').AsString;
          oResultado.CodigoBasico :=
            oConsulta.FieldByName(
              'CODIGO_ATB_COLOR_SESLIN').AsString;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarSkusSesion(
  const ASerie, ANumero: string;
  ALinea: Integer): TSkusSesionMaterializacion;
var
  aResultado: TSkusSesionMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionSkusSesion;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.ParamByName('l').AsInteger := ALinea;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].IdFila :=
            oConsulta.FieldByName(
              'ID_FILA_SES_SESCEL').AsInteger;
          aResultado[iIndice].IdAvPivot :=
            oConsulta.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger;
          aResultado[iIndice].CantidadTotal :=
            oConsulta.FieldByName('CANTIDAD_TOTAL').AsFloat;
          aResultado[iIndice].ValorPivot :=
            oConsulta.FieldByName('VAL_PIVOT').AsString;
          aResultado[iIndice].ValorFila :=
            oConsulta.FieldByName('VAL_FILA').AsString;
          aResultado[iIndice].IdAvFila :=
            oConsulta.FieldByName('ID_AV_FILA').AsInteger;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ExisteEan13Sku(
  const ACodigoSku: string): Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionExisteEan13Sku;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('sku').AsString := ACodigoSku;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ExisteProveedorPrincipalDistinto(
  const ACodigoArticulo,
  ACodigoProveedor: string): Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionProveedorPrincipalDistinto;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArticulo;
        oConsulta.ParamByName('prv').AsString :=
          ACodigoProveedor;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerCodigoUnicoTarifa(
  const ACodigoArticulo,
  ACodigoTarifa: string): Integer;
var
  iResultado: Integer;
  oDefinicion: TDefinicionSql;
begin
  iResultado := 0;
  oDefinicion := DefinicionCodigoUnicoTarifa;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArticulo;
        oConsulta.ParamByName('tar').AsString :=
          ACodigoTarifa;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          iResultado := oConsulta.FieldByName(
            'CODIGO_UNICO_ARTTAR').AsInteger;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := iResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ResolverCodigoSku(
  const ACodigoArticulo: string;
  AIdAvPivot, AIdAvFila: Integer): string;
var
  oDefinicion: TDefinicionSql;
  sResultado: string;
begin
  sResultado := '';
  if AIdAvFila > 0 then
    oDefinicion := DefinicionResolverSkuConFila
  else
    oDefinicion := DefinicionResolverSkuSinFila;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArticulo;
        oConsulta.ParamByName('pivot').AsInteger := AIdAvPivot;
        if AIdAvFila > 0 then
          oConsulta.ParamByName('fila').AsInteger := AIdAvFila;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          sResultado := oConsulta.FieldByName(
            'CODIGO_UNIDAD_SKU').AsString;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := sResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarLineasArticulos(
  const ASerie, ANumero: string):
  TLineasArticuloMaterializacion;
var
  aResultado: TLineasArticuloMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionLineasArticulos;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Linea :=
            oConsulta.FieldByName('LINEA_SESLIN').AsInteger;
          aResultado[iIndice].PrecioCosteProveedor :=
            oConsulta.FieldByName(
              'PRECIO_COSTE_PROVEEDOR').AsFloat;
          aResultado[iIndice].AccionDuplicado :=
            oConsulta.FieldByName(
              'ACCION_DUPLICADO_SESLIN').AsString;
          aResultado[iIndice].CodigoArticuloReusar :=
            oConsulta.FieldByName(
              'CODIGO_ART_REUSAR_SESLIN').AsString;
          aResultado[iIndice].CodigoArticuloTentativo :=
            oConsulta.FieldByName(
              'CODIGO_ART_TENTATIVO_SESLIN').AsString;
          aResultado[iIndice].TipoLinea :=
            oConsulta.FieldByName(
              'TIPO_LINEA_SESLIN').AsString;
          aResultado[iIndice].ReferenciaProveedor :=
            oConsulta.FieldByName('REF_PRV_SESLIN').AsString;
          aResultado[iIndice].PrecioVenta :=
            oConsulta.FieldByName(
              'PRECIO_VENTA_SESLIN').AsFloat;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarLineasDocumento(
  const ASerie, ANumero, AAlmacenCabecera,
  AFiltroAlmacen: string):
  TLineasDocumentoCompraMaterializacion;
var
  aResultado: TLineasDocumentoCompraMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionLineasDocumento;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('alm_cab').AsString :=
          AAlmacenCabecera;
        oConsulta.ParamByName('falm').AsString :=
          AFiltroAlmacen;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].CodigoArticulo :=
            oConsulta.FieldByName('CODIGO_ART').AsString;
          aResultado[iIndice].IdAvPivot :=
            oConsulta.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger;
          aResultado[iIndice].IdAcPivot :=
            oConsulta.FieldByName('ID_AC_PIVOT').AsInteger;
          aResultado[iIndice].CodigoColor :=
            oConsulta.FieldByName('COD_COLOR').AsString;
          aResultado[iIndice].ColorTexto :=
            oConsulta.FieldByName('COLOR_TEXTO').AsString;
          aResultado[iIndice].Almacen :=
            oConsulta.FieldByName('ALM_EFE').AsString;
          aResultado[iIndice].Cantidad :=
            oConsulta.FieldByName('CANTIDAD_TOTAL').AsFloat;
          aResultado[iIndice].PrecioCompra :=
            oConsulta.FieldByName(
              'PRECIO_COMPRA_SESLIN').AsFloat;
          aResultado[iIndice].Descripcion :=
            oConsulta.FieldByName(
              'DESCRIPCION_SESLIN').AsString;
          aResultado[iIndice].CodigoFamilia :=
            oConsulta.FieldByName(
              'CODIGO_FAM_SESLIN').AsString;
          aResultado[iIndice].TipoIva :=
            oConsulta.FieldByName('TIPO_IVA').AsString;
          aResultado[iIndice].TipoLinea :=
            oConsulta.FieldByName(
              'TIPO_LINEA_SESLIN').AsString;
          aResultado[iIndice].ReferenciaProveedor :=
            oConsulta.FieldByName('REF_PRV').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarAlmacenes(
  const ASerie, ANumero,
  AAlmacenCabecera: string): TArray<string>;
var
  aResultado: TArray<string>;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionAlmacenes;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('alm_cab').AsString :=
          AAlmacenCabecera;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice] :=
            oConsulta.FieldByName('ALM').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarPendientesRecibir(
  const ASerie, ANumero,
  AAlmacenCabecera: string):
  TPendientesRecibirMaterializacion;
var
  aResultado: TPendientesRecibirMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionPendientesRecibir;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('alm_cab').AsString :=
          AAlmacenCabecera;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Linea :=
            oConsulta.FieldByName(
              'LINEA_SES_SESCEL').AsInteger;
          aResultado[iIndice].IdAvPivot :=
            oConsulta.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger;
          aResultado[iIndice].Cantidad :=
            oConsulta.FieldByName('CANTIDAD_SESCEL').AsFloat;
          aResultado[iIndice].Almacen :=
            oConsulta.FieldByName('ALM_EFE').AsString;
          aResultado[iIndice].CodigoArticuloTentativo :=
            oConsulta.FieldByName(
              'CODIGO_ART_TENTATIVO_SESLIN').AsString;
          aResultado[iIndice].CodigoArticuloReusar :=
            oConsulta.FieldByName(
              'CODIGO_ART_REUSAR_SESLIN').AsString;
          aResultado[iIndice].AccionDuplicado :=
            oConsulta.FieldByName(
              'ACCION_DUPLICADO_SESLIN').AsString;
          aResultado[iIndice].PrecioCompra :=
            oConsulta.FieldByName(
              'PRECIO_COMPRA_SESLIN').AsFloat;
          aResultado[iIndice].TipoLinea :=
            oConsulta.FieldByName(
              'TIPO_LINEA_SESLIN').AsString;
          aResultado[iIndice].IdAvFila := 0;
          if not oConsulta.FieldByName(
            'ID_VA_FILA_SESLIN').IsNull then
            aResultado[iIndice].IdAvFila := StrToIntDef(
              oConsulta.FieldByName(
                'ID_VA_FILA_SESLIN').AsString,
              0);
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ExisteTabla(
  const ATabla: string): Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionExisteTabla;
  // Las guardas destructivas deben usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    nil,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('t').AsString := ATabla;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarDocumentos(
  const ADefinicion: TDefinicionSql;
  const ASerie, ANumero: string):
  TDocumentosReversionMaterializacion;
var
  aResultado: TDocumentosReversionMaterializacion;
begin
  aResultado := nil;
  // Las guardas destructivas deben usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    ADefinicion,
    nil,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Tipo :=
            oConsulta.FieldByName('TIPO_DOC_SESDOC').AsString;
          aResultado[iIndice].Serie :=
            oConsulta.FieldByName('SERIE_SESDOC').AsString;
          aResultado[iIndice].Numero :=
            oConsulta.FieldByName('NUMERO_SESDOC').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarDocumentosSesion(
  const ASerie, ANumero: string):
  TDocumentosReversionMaterializacion;
begin
  Result := ConsultarDocumentos(
    DefinicionDocumentosReversion,
    ASerie,
    ANumero);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarReferenciasDocumento(
  const ADefinicion: TDefinicionSql;
  const ASerie, ANumero: string): TArray<string>;
var
  aResultado: TArray<string>;
begin
  aResultado := nil;
  // Las guardas destructivas deben usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    ADefinicion,
    nil,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice] :=
            oConsulta.FieldByName('DOCUMENTO').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarFacturasCompraAlbaran(
  const ASerie, ANumero: string): TArray<string>;
begin
  Result := ConsultarReferenciasDocumento(
    DefinicionFacturasCompraAlbaran,
    ASerie,
    ANumero);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarSalidasPosterioresAlbaran(
  const ASerie, ANumero: string): TArray<string>;
begin
  Result := ConsultarReferenciasDocumento(
    DefinicionSalidasPosterioresAlbaran,
    ASerie,
    ANumero);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarAlbaranesPedido(
  const ASerie, ANumero: string):
  TDocumentosReversionMaterializacion;
begin
  Result := ConsultarDocumentos(
    DefinicionAlbaranesPedido,
    ASerie,
    ANumero);
end;

end.
