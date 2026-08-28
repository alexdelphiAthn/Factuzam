{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDocumentosTrabajoCargaOrigenSql                        }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    SQL fijo y parametrizado para cargar documentos origen en documentos de  }
{    trabajo.                                                                  }
{******************************************************************************}
unit UniDataDocumentosTrabajoCargaOrigenSql;

interface

uses
  inLibDocumentosTrabajo;

function NormalizarLimiteDocumentosOrigen(ALimite: Integer): Integer;
function SqlConsultarUltimosDocumentosOrigen: string;
function SqlCabecerasRecientesDocumentosOrigen: string;
function SqlTotalesUltimosDocumentosOrigen: string;
function SqlPrevisualizarLineasAlbaranVenta: string;
function SqlPrevisualizarLineasAlbaranCompra: string;
function SqlPrevisualizarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
function SqlBloquearDocumentoTrabajoCargaOrigen: string;
function SqlBloquearDocumentoOrigen(
  const ATipoDocumento: string): string;
function SqlContarLineasOrigenCargadas: string;
function SqlInsertarLineasOrigenAlbaranVenta: string;
function SqlInsertarLineasOrigenAlbaranCompra: string;
function SqlInsertarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
function SqlResumenCargaOrigenDocumento(
  const ATipoDocumento: string): string;
function SqlContarLineasOrigenSinSku(
  const ATipoDocumento: string): string;
procedure ValidarOrigenDocumentoTrabajo(
  const AOrigen: TDocumentoTrabajoOrigen);

implementation

uses
  System.SysUtils,
  inLibMsgVentas;

function NormalizarLimiteDocumentosOrigen(ALimite: Integer): Integer;
begin
  Result := ALimite;
  if Result <= 0 then
  begin
    Result := LIMITE_DOCUMENTOS_ORIGEN_DEFECTO;
  end;
  if Result > LIMITE_DOCUMENTOS_ORIGEN_MAXIMO then
  begin
    Result := LIMITE_DOCUMENTOS_ORIGEN_MAXIMO;
  end;
end;

function SqlSkuDirecto(const ACampoArticulo, ACampoSku: string): string;
begin
  Result :=
    'COALESCE((SELECT SK.CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus SK ' +
    ' WHERE SK.CODIGO_UNIDAD_SKU = NULLIF(TRIM(' + ACampoSku + '), '''') ' +
    '   AND SK.CODIGO_ART_SKU = ' + ACampoArticulo + ' ' +
    ' LIMIT 1), ' +
    '(SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '  FROM fza_articulos_skus SK ' +
    ' WHERE SK.CODIGO_ART_SKU = ' + ACampoArticulo + ' ' +
    '   AND SK.ESACTIVO_SKU = ''S'' HAVING COUNT(*) = 1))';
end;

function SqlCondicionSkuCelda(const ACampoArticulo, ACampoSkuBase,
  ACampoPivote: string): string;
begin
  Result :=
    'SK.CODIGO_ART_SKU = ' + ACampoArticulo + ' ' +
    'AND EXISTS (SELECT 1 FROM fza_atributos_sku SA ' +
    '         WHERE SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '           AND SA.ID_AV_SA = ' + ACampoPivote + ') ' +
    'AND NOT EXISTS (SELECT 1 ' +
    '         FROM fza_atributos_sku BASE ' +
    '         JOIN fza_atributos_valores COLOR ' +
    '           ON COLOR.ID_AV = BASE.ID_AV_SA ' +
    '          AND COLOR.ID_VA_AV = ''CO'' ' +
    '        WHERE BASE.CODIGO_UNIDAD_SKU_SA = ' + ACampoSkuBase + ' ' +
    '          AND NOT EXISTS (SELECT 1 FROM fza_atributos_sku DESTINO ' +
    '               WHERE DESTINO.CODIGO_UNIDAD_SKU_SA = ' +
    '                     SK.CODIGO_UNIDAD_SKU ' +
    '                 AND DESTINO.ID_AV_SA = BASE.ID_AV_SA))';
end;

function SqlSkuCelda(const ACampoArticulo, ACampoSkuBase,
  ACampoPivote: string): string;
var
  Condicion: string;
begin
  Condicion := SqlCondicionSkuCelda(
    ACampoArticulo, ACampoSkuBase, ACampoPivote);
  Result :=
    'COALESCE((SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '  FROM fza_articulos_skus SK WHERE ' + Condicion + ' ' +
    '   AND SK.ESACTIVO_SKU = ''S'' HAVING COUNT(*) = 1), ' +
    '(SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '  FROM fza_articulos_skus SK WHERE ' + Condicion + ' ' +
    ' HAVING COUNT(*) = 1))';
end;

function SqlDescripcionSku(const ACampoSku: string): string;
begin
  Result :=
    '(SELECT GROUP_CONCAT(AV.AV ORDER BY AV.ORDEN_AV SEPARATOR '' / '') ' +
    '   FROM fza_atributos_sku SA ' +
    '   JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    '  WHERE SA.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku + ')';
end;

function SqlLineasResueltas(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT B.EMPRESA_DOCUMENTO, B.TIPO_DOCUMENTO, ' +
    '       B.SERIE_DOCUMENTO, B.NUMERO_DOCUMENTO, ' +
    '       B.LINEA_DOCUMENTO, B.ORDEN_LINEA, B.ORDEN_FILA, ' +
    '       B.ORDEN_PIVOTE, B.ORDEN_ALMACEN, B.CODIGO_ARTICULO, ' +
    '       B.CODIGO_SKU, B.CODIGO_ALMACEN, B.LOTE, ' +
    '       B.FECHA_CADUCIDAD, B.DESCRIPCION_ARTICULO, ' +
    '       COALESCE(' + SqlDescripcionSku('B.CODIGO_SKU') +
    ', '''') AS DESCRIPCION_SKU, B.CANTIDAD ' +
    '  FROM (' + ASqlLineas + ') B';
end;

function SqlLineasElegibles(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT E.* FROM (' + SqlLineasResueltas(ASqlLineas) + ') E ' +
    ' WHERE NULLIF(TRIM(E.CODIGO_SKU), '''') IS NOT NULL';
end;

function SqlBloquearDocumentoTrabajoCargaOrigen: string;
begin
  Result :=
    'SELECT USUARIO_DTR, ESTADO_DTR, CODIGO_EMP_DTR ' +
    '  FROM fza_documentos_trabajo ' +
    ' WHERE ID_DTR = :ID_DTR FOR UPDATE';
end;

function SqlContarLineasOrigenCargadas: string;
begin
  Result :=
    'SELECT COUNT(*) AS LINEAS_CARGADAS ' +
    '  FROM fza_documentos_trabajo_lineas ' +
    ' WHERE ID_DTR_DTL = :ID_DTR ' +
    '   AND CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '   AND TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '   AND SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '   AND NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO';
end;

function SqlLineasAlbaranVentaBase(
  const AFiltroCabecera: string): string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_ALB AS EMPRESA_DOCUMENTO, ' +
    '       ''AV'' AS TIPO_DOCUMENTO, ' +
    '       H.SERIE_ALB AS SERIE_DOCUMENTO, ' +
    '       H.NUMERO_ALB AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_ALBLIN) AS LINEA_DOCUMENTO, ' +
    '       CAST(L.LINEA_ALBLIN AS UNSIGNED) AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       '''' AS ORDEN_ALMACEN, L.CODIGO_ART_ALBLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_ALBLIN', 'L.CODIGO_UNIDAD_ALBLIN') +
    '         AS CODIGO_SKU, ' +
    '       COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '                H.CODIGO_ALM_ALB, '''') AS CODIGO_ALMACEN, ' +
    '       COALESCE(L.LOTE_ALBLIN, '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_ALBLIN AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_ALBLIN AS CANTIDAD ' +
    '  FROM fza_albaranes H ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = H.SERIE_ALB ' +
    '   AND L.NUMERO_ALB_ALBLIN = H.NUMERO_ALB ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_celdas C ' +
    '         WHERE C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '           AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '           AND C.LINEA_ALBCEL = CAST(L.LINEA_ALBLIN AS UNSIGNED) ' +
    '           AND C.CANTIDAD_ALBCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_ALB, ''AV'', H.SERIE_ALB, H.NUMERO_ALB, ' +
    '       CONCAT(''C:'', L.LINEA_ALBLIN, '':'', C.ID_FILA_ALBCEL, ' +
    '              '':'', C.ID_AV_PIVOT_ALBCEL, '':'', ' +
    '              COALESCE(C.CODIGO_ALM_ALBCEL, '''')), ' +
    '       CAST(L.LINEA_ALBLIN AS UNSIGNED), C.ID_FILA_ALBCEL, ' +
    '       C.ID_AV_PIVOT_ALBCEL, COALESCE(C.CODIGO_ALM_ALBCEL, ''''), ' +
    '       L.CODIGO_ART_ALBLIN, ' +
    '       ' + SqlSkuCelda(
      'L.CODIGO_ART_ALBLIN', 'L.CODIGO_UNIDAD_ALBLIN',
      'C.ID_AV_PIVOT_ALBCEL') + ', ' +
    '       COALESCE(NULLIF(C.CODIGO_ALM_ALBCEL, ''''), ' +
    '                NULLIF(L.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '                H.CODIGO_ALM_ALB, ''''), ' +
    '       COALESCE(L.LOTE_ALBLIN, ''''), L.FECHA_CADUCIDAD_ALBLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBLIN, ''''), ' +
    '       C.CANTIDAD_ALBCEL ' +
    '  FROM fza_albaranes H ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = H.SERIE_ALB ' +
    '   AND L.NUMERO_ALB_ALBLIN = H.NUMERO_ALB ' +
    '  JOIN fza_albaranes_celdas C ' +
    '    ON C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '   AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '   AND C.LINEA_ALBCEL = CAST(L.LINEA_ALBLIN AS UNSIGNED) ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCEL <> 0';
end;

function SqlLineasAlbaranVentaResueltas: string;
begin
  Result := SqlLineasResueltas(SqlLineasAlbaranVentaBase(
    'H.CODIGO_EMP_ALB = :EMPRESA ' +
    'AND H.SERIE_ALB = :SERIE AND H.NUMERO_ALB = :NUMERO'));
end;

function SqlLineasAlbaranVenta: string;
begin
  Result := SqlLineasElegibles(SqlLineasAlbaranVentaBase(
    'H.CODIGO_EMP_ALB = :EMPRESA ' +
    'AND H.SERIE_ALB = :SERIE AND H.NUMERO_ALB = :NUMERO'));
end;

function SqlLineasAlbaranCompraBase(
  const AFiltroCabecera: string): string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_ALBC AS EMPRESA_DOCUMENTO, ' +
    '       ''AB'' AS TIPO_DOCUMENTO, ' +
    '       H.SERIE_ALBC AS SERIE_DOCUMENTO, ' +
    '       H.NUMERO_ALBC AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_ALBCLIN) AS LINEA_DOCUMENTO, ' +
    '       L.LINEA_ALBCLIN AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       '''' AS ORDEN_ALMACEN, L.CODIGO_ART_ALBCLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_ALBCLIN', 'L.CODIGO_UNIDAD_ALBCLIN') +
    '         AS CODIGO_SKU, ' +
    '       COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    '                H.CODIGO_ALM_ALBC, '''') AS CODIGO_ALMACEN, ' +
    '       COALESCE(L.LOTE_ALBCLIN, '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_ALBCLIN AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBCLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_ALBCLIN AS CANTIDAD ' +
    '  FROM fza_albaranes_compra H ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBCLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_compra_celdas C ' +
    '         WHERE C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '           AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '           AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    '           AND C.CANTIDAD_ALBCCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_ALBC, ''AB'', H.SERIE_ALBC, H.NUMERO_ALBC, ' +
    '       CONCAT(''C:'', L.LINEA_ALBCLIN, '':'', ' +
    '              C.ID_FILA_ALBC_ALBCCEL, '':'', ' +
    '              C.ID_AV_PIVOT_ALBCCEL), ' +
    '       L.LINEA_ALBCLIN, ' +
    '       C.ID_FILA_ALBC_ALBCCEL, C.ID_AV_PIVOT_ALBCCEL, '''', ' +
    '       L.CODIGO_ART_ALBCLIN, ' +
    '       ' + SqlSkuCelda(
      'L.CODIGO_ART_ALBCLIN', 'L.CODIGO_UNIDAD_ALBCLIN',
      'C.ID_AV_PIVOT_ALBCCEL') + ', ' +
    '       COALESCE(NULLIF(C.CODIGO_ALM_ALBCCEL, ''''), ' +
    '                NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    '                H.CODIGO_ALM_ALBC, ''''), ' +
    '       COALESCE(L.LOTE_ALBCLIN, ''''), L.FECHA_CADUCIDAD_ALBCLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBCLIN, ''''), ' +
    '       C.CANTIDAD_ALBCCEL ' +
    '  FROM fza_albaranes_compra H ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC ' +
    '  JOIN fza_albaranes_compra_celdas C ' +
    '    ON C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '   AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '   AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCCEL <> 0';
end;

function SqlLineasAlbaranCompraResueltas: string;
begin
  Result := SqlLineasResueltas(SqlLineasAlbaranCompraBase(
    'H.CODIGO_EMP_ALBC = :EMPRESA ' +
    'AND H.SERIE_ALBC = :SERIE AND H.NUMERO_ALBC = :NUMERO'));
end;

function SqlLineasAlbaranCompra: string;
begin
  Result := SqlLineasElegibles(SqlLineasAlbaranCompraBase(
    'H.CODIGO_EMP_ALBC = :EMPRESA ' +
    'AND H.SERIE_ALBC = :SERIE AND H.NUMERO_ALBC = :NUMERO'));
end;

function SqlInstanteOrden(const ACampoInstante,
  ACampoFecha: string): string;
begin
  Result :=
    'CASE WHEN ' + ACampoInstante + ' IS NULL ' +
    'OR ' + ACampoInstante + ' < ''1000-01-01 00:00:00'' ' +
    'THEN CAST(' + ACampoFecha + ' AS DATETIME) ' +
    'ELSE ' + ACampoInstante + ' END';
end;

function SqlCabecerasRecientesDocumentosOrigen: string;
begin
  Result :=
    'SELECT VA.* FROM (SELECT ''AV'' AS TIPO_DOCUMENTO, ' +
    '       H.CODIGO_EMP_ALB AS EMPRESA_DOCUMENTO, ' +
    '       H.SERIE_ALB AS SERIE, H.NUMERO_ALB AS NUMERO, ' +
    '       H.FECHA_ALB AS FECHA, H.INSTANTE_ALTA, ' +
    '       H.ESTADO_ALB AS ESTADO, ' +
    '       COALESCE(NULLIF(H.RAZON_SOCIAL_CLIENTE_ALB, ''''), ' +
    '                H.CODIGO_CLI_ALB, '''') AS TERCERO ' +
    '  FROM fza_albaranes H ' +
    ' WHERE H.CODIGO_EMP_ALB = :EMPRESA_AV ' +
    ' ORDER BY ' + SqlInstanteOrden(
      'H.INSTANTE_ALTA', 'H.FECHA_ALB') + ' DESC, ' +
    '          H.SERIE_ALB, H.NUMERO_ALB ' +
    ' LIMIT :LIMITE_AV) VA ' +
    'UNION ALL ' +
    'SELECT AB.* FROM (SELECT ''AB'' AS TIPO_DOCUMENTO, ' +
    '       H.CODIGO_EMP_ALBC AS EMPRESA_DOCUMENTO, ' +
    '       H.SERIE_ALBC AS SERIE, H.NUMERO_ALBC AS NUMERO, ' +
    '       H.FECHA_ALBC AS FECHA, H.INSTANTE_ALTA, ' +
    '       H.ESTADO_ALBC AS ESTADO, ' +
    '       COALESCE(NULLIF(H.RAZON_SOCIAL_PRV_ALBC, ''''), ' +
    '                H.CODIGO_PRV_ALBC, '''') AS TERCERO ' +
    '  FROM fza_albaranes_compra H ' +
    ' WHERE H.CODIGO_EMP_ALBC = :EMPRESA_AB ' +
    ' ORDER BY ' + SqlInstanteOrden(
      'H.INSTANTE_ALTA', 'H.FECHA_ALBC') + ' DESC, ' +
    '          H.SERIE_ALBC, H.NUMERO_ALBC ' +
    ' LIMIT :LIMITE_AB) AB';
end;

function SqlLineasTotalesUltimosAlbaranesVenta: string;
begin
  Result :=
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, ' +
    '       U.SERIE AS SERIE_DOCUMENTO, ' +
    '       U.NUMERO AS NUMERO_DOCUMENTO, L.CANTIDAD_ALBLIN AS CANTIDAD ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = U.SERIE ' +
    '   AND L.NUMERO_ALB_ALBLIN = U.NUMERO ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AV'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_celdas C ' +
    '         WHERE C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '           AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '           AND C.LINEA_ALBCEL = CAST(L.LINEA_ALBLIN AS UNSIGNED) ' +
    '           AND C.CANTIDAD_ALBCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, U.SERIE, U.NUMERO, ' +
    '       C.CANTIDAD_ALBCEL ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = U.SERIE ' +
    '   AND L.NUMERO_ALB_ALBLIN = U.NUMERO ' +
    '  JOIN fza_albaranes_celdas C ' +
    '    ON C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '   AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '   AND C.LINEA_ALBCEL = CAST(L.LINEA_ALBLIN AS UNSIGNED) ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AV'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCEL <> 0';
end;

function SqlLineasTotalesUltimosAlbaranesCompra: string;
begin
  Result :=
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, ' +
    '       U.SERIE AS SERIE_DOCUMENTO, ' +
    '       U.NUMERO AS NUMERO_DOCUMENTO, L.CANTIDAD_ALBCLIN AS CANTIDAD ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = U.SERIE ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = U.NUMERO ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AB'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBCLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_compra_celdas C ' +
    '         WHERE C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '           AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '           AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    '           AND C.CANTIDAD_ALBCCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, U.SERIE, U.NUMERO, ' +
    '       C.CANTIDAD_ALBCCEL ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = U.SERIE ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = U.NUMERO ' +
    '  JOIN fza_albaranes_compra_celdas C ' +
    '    ON C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '   AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '   AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AB'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCCEL <> 0';
end;

function SqlTotalesUltimosDocumentosOrigen: string;
begin
  Result :=
    'SELECT X.TIPO_DOCUMENTO, X.EMPRESA_DOCUMENTO, ' +
    '       X.SERIE_DOCUMENTO, X.NUMERO_DOCUMENTO, ' +
    '       COUNT(*) AS NUMERO_LINEAS, ' +
    '       COALESCE(SUM(X.CANTIDAD), 0) AS TOTAL_UNIDADES ' +
    '  FROM (' +
    SqlLineasTotalesUltimosAlbaranesVenta +
    ' UNION ALL ' +
    SqlLineasTotalesUltimosAlbaranesCompra +
    ') X ' +
    ' GROUP BY X.TIPO_DOCUMENTO, X.EMPRESA_DOCUMENTO, ' +
    '          X.SERIE_DOCUMENTO, X.NUMERO_DOCUMENTO';
end;

function SqlConsultarUltimosDocumentosOrigen: string;
begin
  Result :=
    'WITH CANDIDATOS AS (' +
    SqlCabecerasRecientesDocumentosOrigen +
    '), ULTIMOS AS (SELECT C.* FROM CANDIDATOS C ' +
    ' ORDER BY ' + SqlInstanteOrden(
      'C.INSTANTE_ALTA', 'C.FECHA') + ' DESC, ' +
    '          C.TIPO_DOCUMENTO, C.SERIE, C.NUMERO ' +
    ' LIMIT :LIMITE_GLOBAL) ' +
    'SELECT D.TIPO_DOCUMENTO, D.SERIE, D.NUMERO, D.FECHA, ' +
    '       D.INSTANTE_ALTA, D.ESTADO, D.TERCERO, ' +
    '       COALESCE(T.NUMERO_LINEAS, 0) AS NUMERO_LINEAS, ' +
    '       COALESCE(T.TOTAL_UNIDADES, 0) AS TOTAL_UNIDADES ' +
    '  FROM ULTIMOS D ' +
    '  LEFT JOIN (' + SqlTotalesUltimosDocumentosOrigen + ') T ' +
    '    ON T.TIPO_DOCUMENTO = D.TIPO_DOCUMENTO ' +
    '   AND T.EMPRESA_DOCUMENTO = D.EMPRESA_DOCUMENTO ' +
    '   AND T.SERIE_DOCUMENTO = D.SERIE ' +
    '   AND T.NUMERO_DOCUMENTO = D.NUMERO ' +
    ' ORDER BY ' + SqlInstanteOrden(
      'D.INSTANTE_ALTA', 'D.FECHA') + ' DESC, ' +
    '          D.TIPO_DOCUMENTO, D.SERIE, D.NUMERO';
end;

function SqlPrevisualizar(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT X.LINEA_DOCUMENTO, X.CODIGO_ARTICULO, X.CODIGO_SKU, ' +
    '       X.CODIGO_ALMACEN, X.LOTE, X.FECHA_CADUCIDAD, ' +
    '       X.DESCRIPCION_ARTICULO, X.DESCRIPCION_SKU, X.CANTIDAD ' +
    '  FROM (' + ASqlLineas + ') X ' +
    ' ORDER BY X.ORDEN_LINEA, X.ORDEN_FILA, X.ORDEN_PIVOTE, ' +
    '          X.ORDEN_ALMACEN';
end;

function SqlPrevisualizarLineasAlbaranVenta: string;
begin
  Result := SqlPrevisualizar(SqlLineasAlbaranVentaResueltas);
end;

function SqlPrevisualizarLineasAlbaranCompra: string;
begin
  Result := SqlPrevisualizar(SqlLineasAlbaranCompraResueltas);
end;

function SqlInsertarLineasOrigen(const ASqlLineas: string): string;
begin
  Result :=
    'INSERT INTO fza_documentos_trabajo_lineas ' +
    '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    '   ORIGEN_DTL, CODIGO_EMP_ORIGEN_DTL, ' +
    '   TIPO_DOCUMENTO_ORIGEN_DTL, SERIE_DOCUMENTO_ORIGEN_DTL, ' +
    '   NUMERO_DOCUMENTO_ORIGEN_DTL, LINEA_DOCUMENTO_ORIGEN_DTL, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_DTR, ' +
    '       LPAD(CAST(:PRIMERA_LINEA AS UNSIGNED) + ' +
    '         ROW_NUMBER() OVER (ORDER BY X.ORDEN_LINEA, X.ORDEN_FILA, ' +
    '           X.ORDEN_PIVOTE, X.ORDEN_ALMACEN) - 1, 8, ''0''), ' +
    '       X.CODIGO_ARTICULO, X.CODIGO_SKU, X.CODIGO_ALMACEN, ' +
    '       X.LOTE, X.FECHA_CADUCIDAD, X.DESCRIPCION_ARTICULO, ' +
    '       X.DESCRIPCION_SKU, 0, X.CANTIDAD, NOW(), ' +
    '       :ETIQUETA_ORIGEN, :EMPRESA, :TIPO_DOCUMENTO, :SERIE, ' +
    '       :NUMERO, X.LINEA_DOCUMENTO, NOW(), :USUARIO, :USUARIO ' +
    '  FROM (' + ASqlLineas + ') X ' +
    ' WHERE NOT EXISTS (SELECT 1 ' +
    '         FROM fza_documentos_trabajo_lineas D ' +
    '        WHERE D.ID_DTR_DTL = :ID_DTR ' +
    '          AND D.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '          AND D.TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '          AND D.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '          AND D.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO ' +
    '          AND D.LINEA_DOCUMENTO_ORIGEN_DTL = X.LINEA_DOCUMENTO) ' +
    ' ORDER BY X.ORDEN_LINEA, X.ORDEN_FILA, X.ORDEN_PIVOTE, ' +
    '          X.ORDEN_ALMACEN';
end;

function SqlInsertarLineasOrigenAlbaranVenta: string;
begin
  Result := SqlInsertarLineasOrigen(SqlLineasAlbaranVenta);
end;

function SqlInsertarLineasOrigenAlbaranCompra: string;
begin
  Result := SqlInsertarLineasOrigen(SqlLineasAlbaranCompra);
end;

function SqlLineasSegunTipo(const ATipoDocumento: string): string;
begin
  if SameText(Trim(ATipoDocumento),
              TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA) then
  begin
    Result := SqlLineasAlbaranVenta;
  end
  else if SameText(Trim(ATipoDocumento),
                   TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA) then
  begin
    Result := SqlLineasAlbaranCompra;
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlLineasResueltasSegunTipo(
  const ATipoDocumento: string): string;
begin
  if SameText(Trim(ATipoDocumento),
              TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA) then
  begin
    Result := SqlLineasAlbaranVentaResueltas;
  end
  else if SameText(Trim(ATipoDocumento),
                   TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA) then
  begin
    Result := SqlLineasAlbaranCompraResueltas;
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlContarLineasOrigenSinSku(
  const ATipoDocumento: string): string;
begin
  Result :=
    'SELECT COUNT(*) AS LINEAS_SIN_SKU ' +
    '  FROM (' + SqlLineasResueltasSegunTipo(ATipoDocumento) + ') X ' +
    ' WHERE NULLIF(TRIM(X.CODIGO_SKU), '''') IS NULL';
end;

function SqlResumenCargaOrigen(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT COUNT(*) AS LINEAS_ENCONTRADAS, ' +
    '       COALESCE(SUM(CASE WHEN EXISTS (SELECT 1 ' +
    '         FROM fza_documentos_trabajo_lineas D ' +
    '        WHERE D.ID_DTR_DTL = :ID_DTR ' +
    '          AND D.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '          AND D.TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '          AND D.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '          AND D.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO ' +
    '          AND D.LINEA_DOCUMENTO_ORIGEN_DTL = X.LINEA_DOCUMENTO) ' +
    '         THEN 1 ELSE 0 END), 0) AS LINEAS_OMITIDAS, ' +
    '       COALESCE(SUM(CASE WHEN NOT EXISTS (SELECT 1 ' +
    '         FROM fza_documentos_trabajo_lineas D ' +
    '        WHERE D.ID_DTR_DTL = :ID_DTR ' +
    '          AND D.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '          AND D.TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '          AND D.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '          AND D.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO ' +
    '          AND D.LINEA_DOCUMENTO_ORIGEN_DTL = X.LINEA_DOCUMENTO) ' +
    '         THEN X.CANTIDAD ELSE 0 END), 0) AS TOTAL_UNIDADES ' +
    '  FROM (' + ASqlLineas + ') X';
end;

procedure ValidarOrigenDocumentoTrabajo(
  const AOrigen: TDocumentoTrabajoOrigen);
var
  TipoDocumento: string;
begin
  if (Trim(AOrigen.Empresa) = '') or
     (Trim(AOrigen.TipoDocumento) = '') or
     (Trim(AOrigen.Serie) = '') or
     (Trim(AOrigen.Numero) = '') then
  begin
    raise EArgumentException.Create(SErrorDocumentoOrigenIncompleto);
  end;
  TipoDocumento := UpperCase(Trim(AOrigen.TipoDocumento));
  if (TipoDocumento <> TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA) and
     (TipoDocumento <> TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA) then
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [AOrigen.TipoDocumento]);
  end;
end;

function SqlPrevisualizarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
begin
  if SameText(Trim(ATipoDocumento),
              TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA) then
  begin
    Result := SqlPrevisualizarLineasAlbaranVenta;
  end
  else if SameText(Trim(ATipoDocumento),
                   TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA) then
  begin
    Result := SqlPrevisualizarLineasAlbaranCompra;
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlBloquearDocumentoOrigen(
  const ATipoDocumento: string): string;
begin
  if SameText(Trim(ATipoDocumento),
              TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA) then
  begin
    Result :=
      'SELECT ESTADO_ALB AS ESTADO ' +
      '  FROM fza_albaranes ' +
      ' WHERE CODIGO_EMP_ALB = :EMPRESA ' +
      '   AND SERIE_ALB = :SERIE AND NUMERO_ALB = :NUMERO FOR UPDATE';
  end
  else if SameText(Trim(ATipoDocumento),
                   TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA) then
  begin
    Result :=
      'SELECT ESTADO_ALBC AS ESTADO ' +
      '  FROM fza_albaranes_compra ' +
      ' WHERE CODIGO_EMP_ALBC = :EMPRESA ' +
      '   AND SERIE_ALBC = :SERIE AND NUMERO_ALBC = :NUMERO FOR UPDATE';
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlInsertarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
begin
  if SameText(Trim(ATipoDocumento),
              TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA) then
  begin
    Result := SqlInsertarLineasOrigenAlbaranVenta;
  end
  else if SameText(Trim(ATipoDocumento),
                   TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA) then
  begin
    Result := SqlInsertarLineasOrigenAlbaranCompra;
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlResumenCargaOrigenDocumento(
  const ATipoDocumento: string): string;
begin
  Result := SqlResumenCargaOrigen(
    SqlLineasSegunTipo(ATipoDocumento));
end;

end.
