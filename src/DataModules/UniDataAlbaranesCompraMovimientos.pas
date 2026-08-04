{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesCompraMovimientos                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de los movimientos de almacén de albaranes de            }
{    compra. Implementa IMovimientosAlbaranCompra y se registra en la          }
{    fábrica del contrato en su initialization.                                }
{                                                                              }
{    Usa el procedimiento almacenado PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT,       }
{    que es el único que toca stock real (fza_articulos_stockactual). La       }
{    reversión borra los movimientos por (TIPO_DOC='AC' + SERIE + NUMERO)      }
{    y recalcula PMP + stock de los SKUs afectados vía                         }
{    SP_RECALCULAR_PMP_LOTE_ALMACEN.                                           }
{                                                                              }
{    Fuente de datos para los movimientos:                                     }
{      - fza_albaranes_compra_celdas si la línea tiene celdas con              }
{        cantidad > 0 (caso edición manual con tallas).                        }
{      - fza_albaranes_compra_lineas en caso contrario, una entrada por        }
{        línea con CANTIDAD_ALBCLIN (caso materialización de sesión).          }
{                                                                              }
{    Limitación conocida: ambos caminos asumen que el SKU de la línea          }
{    (CODIGO_UNIDAD_ALBCLIN) es el correcto. No resolvemos un SKU              }
{    distinto por celda; cuando se permita en un hito futuro habrá que         }
{    ampliar ResolverSkuCelda en el bucle de celdas.                           }
{******************************************************************************}
unit UniDataAlbaranesCompraMovimientos;
interface
uses
  Uni, inLibAlbaranesCompraMovimientosIntf;
function CrearMovimientosAlbaranCompraUniDAC(
  AConexion: TUniConnection): IMovimientosAlbaranCompra;
implementation
uses
  System.SysUtils, Data.DB, inLibDocumento, inLibDocumentoIntf,
  UniDataValoresAutomaticosRepositorio, inLibMsgCompras,
  UniDataAlbaranesCompraMovimientosSql,
  UniDataMovimientosAlmacenRecalculo;
type
  TMovimientosAlbaranCompraUniDAC = class(
    TInterfacedObject,
    IMovimientosAlbaranCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure GenerarDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
    procedure RevertirDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
  end;
function EstrategiaAlbaranCompra: IEstrategiaDocumento;
begin
  Result := CrearEstrategiaDocumento(
    CrearConfiguracionDocumento(tdAlbaran, sdCompra));
end;
// Carga empresa, fecha y almacén de respaldo para los movimientos.
// El almacén de línea o celda siempre tiene prioridad.
procedure LeerCabeceraAlbaran(AConn: TUniConnection;
                              const ASerieAlbc, ANumAlbc: string;
                              out ACodigoEmp, ACodigoAlmCab: string;
                              out AFechaAlbc: TDateTime);
var
  q: TUniQuery;
begin
  ACodigoEmp    := '';
  ACodigoAlmCab := '';
  AFechaAlbc    := Date;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT CODIGO_EMP_ALBC, CODIGO_ALM_ALBC, FECHA_ALBC ' +
      '  FROM fza_albaranes_compra ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ParamByName('n').AsString := ANumAlbc;
    q.Open;
    if q.Eof then
      raise Exception.CreateFmt(SErrorAlbaranCompraMovimientosNoEncontrado,
        [ASerieAlbc, ANumAlbc]);
    ACodigoEmp    := q.FieldByName('CODIGO_EMP_ALBC').AsString;
    ACodigoAlmCab := q.FieldByName('CODIGO_ALM_ALBC').AsString;
    if not q.FieldByName('FECHA_ALBC').IsNull then
      AFechaAlbc := q.FieldByName('FECHA_ALBC').AsDateTime;
  finally
    FreeAndNil(q);
  end;
end;
procedure ActualizarArticulosProveedorDesdeAlbaranCompra(
                                               AConn: TUniConnection;
                                               const ASerieAlbc, ANumAlbc,
                                                     AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_proveedores ' +
      '  (CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
      '   PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ' +
      '   ESPROVEEDORPRINCIPAL_AP, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT X.CODIGO_PRV, X.CODIGO_ART, NULLIF(X.REF_PRV, ''''), ' +
      '       X.PRECIO, X.FECHA_ALBC, ' +
      '       CASE WHEN EXISTS ( ' +
      '              SELECT 1 FROM fza_articulos_proveedores AP2 ' +
      '               WHERE AP2.CODIGO_ART_AP = X.CODIGO_ART ' +
      '                 AND AP2.CODIGO_PRV_AP <> X.CODIGO_PRV ' +
      '                 AND AP2.ESPROVEEDORPRINCIPAL_AP = ''S'') ' +
      '            THEN ''N'' ELSE ''S'' END, ' +
      '       NOW(), :u1, NOW(), :u2 ' +
      '  FROM ( ' +
      '        SELECT A.CODIGO_PRV_ALBC AS CODIGO_PRV, ' +
      '               L.CODIGO_ART_ALBCLIN AS CODIGO_ART, ' +
      '               COALESCE(A.FECHA_ALBC, CURRENT_DATE) AS FECHA_ALBC, ' +
      '               COALESCE(TRIM(L.REF_PRV_ALBCLIN), '''') AS REF_PRV, ' +
      '               CASE WHEN IFNULL(A.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '''N'') <> ''S'' ' +
      '                     AND IFNULL(A.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') ' +
      '= ''S'' ' +
      '                    THEN L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
      '                      (1 + (IFNULL(L.PORCENTAJE_IVA_ALBCLIN, 0) + ' +
      '                        CASE IFNULL(L.TIPO_IVA_ARTICULO_ALBCLIN, ''N'') '
        +
      '                          WHEN ''N'' THEN ' +
      'IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
      '                          WHEN ''R'' THEN ' +
      'IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                          WHEN ''S'' THEN ' +
      'IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                          WHEN ''E'' THEN ' +
      'IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
      '                          ELSE 0 END) / 100) ' +
      '                    ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN END * ' +
      '               CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
      '                      GREATEST(0, 1 - CASE ' +
      '                        WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 '
        +
      '                        THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
      'A.TOTAL_BRUTO_ALBC ' +
      '                        ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      '0) / 100 END) ' +
      '                    ELSE GREATEST(0, 1 - ' +
      'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '               END AS PRECIO ' +
      '          FROM fza_albaranes_compra_lineas L ' +
      '          JOIN fza_albaranes_compra A ' +
      '            ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '           AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '          LEFT JOIN fza_ivas V ON V.CODIGO_IVA = A.CODIGO_IVA_ALBC ' +
      '         WHERE L.SERIE_ALBC_ALBCLIN  = :s ' +
      '           AND L.NUMERO_ALBC_ALBCLIN = :n ' +
      '           AND COALESCE(TRIM(A.CODIGO_PRV_ALBC), '''') <> '''' ' +
      '           AND COALESCE(TRIM(A.CODIGO_PRV_ALBC), '''') <> ''0'' ' +
      '           AND COALESCE(TRIM(L.CODIGO_ART_ALBCLIN), '''') <> '''' ' +
      '           AND (IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                OR EXISTS ( ' +
      '                   SELECT 1 FROM fza_albaranes_compra_celdas C ' +
      '                    WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN '
        +
      '                      AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN '
        +
      '                      AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
      '                          = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
      '                      AND C.CANTIDAD_ALBCCEL > 0)) ' +
      '           AND NOT EXISTS ( ' +
      '                 SELECT 1 FROM fza_albaranes_compra_lineas L2 ' +
      '                  WHERE L2.SERIE_ALBC_ALBCLIN  = L.SERIE_ALBC_ALBCLIN ' +
      '                    AND L2.NUMERO_ALBC_ALBCLIN = L.NUMERO_ALBC_ALBCLIN '
        +
      '                    AND L2.CODIGO_ART_ALBCLIN  = L.CODIGO_ART_ALBCLIN ' +
      '                    AND (IFNULL(L2.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                         OR EXISTS ( ' +
      '                            SELECT 1 FROM fza_albaranes_compra_celdas ' +
      'C2 ' +
      '                             WHERE C2.SERIE_ALBC_ALBCCEL  = ' +
      'L2.SERIE_ALBC_ALBCLIN ' +
      '                               AND C2.NUMERO_ALBC_ALBCCEL = ' +
      'L2.NUMERO_ALBC_ALBCLIN ' +
      '                               AND CAST(C2.LINEA_ALBC_ALBCCEL AS ' +
      'UNSIGNED) ' +
      '                                   = CAST(L2.LINEA_ALBCLIN AS UNSIGNED) '
        +
      '                               AND C2.CANTIDAD_ALBCCEL > 0)) ' +
      '                    AND L2.LINEA_ALBCLIN > L.LINEA_ALBCLIN) ' +
      '       ) X ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_AP = IF(VALUES(FECHA_VALIDEZ_AP) >= ' +
      '    IFNULL(FECHA_VALIDEZ_AP, ''1000-01-01''), ' +
      '    VALUES(PRECIO_ULT_COMPRA_AP), PRECIO_ULT_COMPRA_AP), ' +
      '  REF_PROVEEDOR_AP = IF(VALUES(FECHA_VALIDEZ_AP) >= ' +
      '    IFNULL(FECHA_VALIDEZ_AP, ''1000-01-01''), ' +
      '    COALESCE(VALUES(REF_PROVEEDOR_AP), REF_PROVEEDOR_AP), ' +
      '    REF_PROVEEDOR_AP), ' +
      '  FECHA_VALIDEZ_AP = GREATEST(IFNULL(FECHA_VALIDEZ_AP, ' +
      '    ''1000-01-01''), VALUES(FECHA_VALIDEZ_AP)), ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u3';
    q.ParamByName('s').AsString  := ASerieAlbc;
    q.ParamByName('n').AsString  := ANumAlbc;
    q.ParamByName('u1').AsString := AUsuario;
    q.ParamByName('u2').AsString := AUsuario;
    q.ParamByName('u3').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure ActualizarCostesSkuDesdeAlbaranCompra(AConn: TUniConnection;
                                               const ASerieAlbc, ANumAlbc,
                                                     AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_skus_costes ' +
      '  (CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, ' +
      '   FECHA_ULT_COMPRA_SKUC, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT X.CODIGO_SKU, X.PRECIO, X.FECHA_ALBC, ' +
      '       NOW(), :u1, NOW(), :u2 ' +
      '  FROM ( ' +
      '        SELECT L.CODIGO_UNIDAD_ALBCLIN AS CODIGO_SKU, ' +
      '               COALESCE(A.FECHA_ALBC, CURRENT_DATE) AS FECHA_ALBC, ' +
      '               CASE WHEN IFNULL(A.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '''N'') <> ''S'' ' +
      '                     AND IFNULL(A.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') ' +
      '= ''S'' ' +
      '                    THEN L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
      '                      (1 + (IFNULL(L.PORCENTAJE_IVA_ALBCLIN, 0) + ' +
      '                        CASE IFNULL(L.TIPO_IVA_ARTICULO_ALBCLIN, ''N'') '
        +
      '                          WHEN ''N'' THEN ' +
      'IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
      '                          WHEN ''R'' THEN ' +
      'IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                          WHEN ''S'' THEN ' +
      'IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                          WHEN ''E'' THEN ' +
      'IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
      '                          ELSE 0 END) / 100) ' +
      '                    ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN END * ' +
      '               CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
      '                      GREATEST(0, 1 - CASE ' +
      '                        WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 '
        +
      '                        THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
      'A.TOTAL_BRUTO_ALBC ' +
      '                        ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      '0) / 100 END) ' +
      '                    ELSE GREATEST(0, 1 - ' +
      'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '               END AS PRECIO ' +
      '          FROM fza_albaranes_compra_lineas L ' +
      '          JOIN fza_albaranes_compra A ' +
      '            ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '           AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '          LEFT JOIN fza_ivas V ON V.CODIGO_IVA = A.CODIGO_IVA_ALBC ' +
      '         WHERE L.SERIE_ALBC_ALBCLIN  = :s ' +
      '           AND L.NUMERO_ALBC_ALBCLIN = :n ' +
      '           AND COALESCE(TRIM(L.CODIGO_UNIDAD_ALBCLIN), '''') <> '''' ' +
      '           AND (IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                OR EXISTS ( ' +
      '                   SELECT 1 FROM fza_albaranes_compra_celdas C ' +
      '                    WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN '
        +
      '                      AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN '
        +
      '                      AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
      '                          = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
      '                      AND C.CANTIDAD_ALBCCEL > 0)) ' +
      '           AND NOT EXISTS ( ' +
      '                 SELECT 1 FROM fza_albaranes_compra_lineas L2 ' +
      '                  WHERE L2.SERIE_ALBC_ALBCLIN  = L.SERIE_ALBC_ALBCLIN ' +
      '                    AND L2.NUMERO_ALBC_ALBCLIN = L.NUMERO_ALBC_ALBCLIN '
        +
      '                    AND L2.CODIGO_UNIDAD_ALBCLIN = ' +
      'L.CODIGO_UNIDAD_ALBCLIN ' +
      '                    AND (IFNULL(L2.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                         OR EXISTS ( ' +
      '                            SELECT 1 FROM fza_albaranes_compra_celdas ' +
      'C2 ' +
      '                             WHERE C2.SERIE_ALBC_ALBCCEL  = ' +
      'L2.SERIE_ALBC_ALBCLIN ' +
      '                               AND C2.NUMERO_ALBC_ALBCCEL = ' +
      'L2.NUMERO_ALBC_ALBCLIN ' +
      '                               AND CAST(C2.LINEA_ALBC_ALBCCEL AS ' +
      'UNSIGNED) ' +
      '                                   = CAST(L2.LINEA_ALBCLIN AS UNSIGNED) '
        +
      '                               AND C2.CANTIDAD_ALBCCEL > 0)) ' +
      '                    AND L2.LINEA_ALBCLIN > L.LINEA_ALBCLIN) ' +
      '       ) X ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_SKUC = IF(VALUES(FECHA_ULT_COMPRA_SKUC) >= ' +
      '    IFNULL(FECHA_ULT_COMPRA_SKUC, ''1000-01-01''), ' +
      '    VALUES(PRECIO_ULT_COMPRA_SKUC), PRECIO_ULT_COMPRA_SKUC), ' +
      '  FECHA_ULT_COMPRA_SKUC = GREATEST(' +
      '    IFNULL(FECHA_ULT_COMPRA_SKUC, ''1000-01-01''), ' +
      '    VALUES(FECHA_ULT_COMPRA_SKUC)), ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u3';
    q.ParamByName('s').AsString  := ASerieAlbc;
    q.ParamByName('n').AsString  := ANumAlbc;
    q.ParamByName('u1').AsString := AUsuario;
    q.ParamByName('u2').AsString := AUsuario;
    q.ParamByName('u3').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
// Genera movimientos de entrada (TIPO_DOC_MOV='AC', TIPO_MOV='E') para
// todas las celdas con cantidad > 0 del albaran, o para sus lineas
// cuando no haya celdas. AConn debe estar viva; la transaccion la
// gestiona el llamante (este procedimiento no abre ni cierra
// transacciones).
procedure GenerarMovimientosDesdeAlbaranCompra(AConn: TUniConnection;
                                               const ASerieAlbc, ANumAlbc,
                                                     AUsuario: string);
var
  qSrc, qChk: TUniQuery;
  spIns: TUniStoredProc;
  sCodigoEmp, sCodigoAlmCab, sCodigoAlm, sCodigoSku, sCodigoArt,
  sNumeroMov, sLinea: string;
  dFechaAlbc: TDateTime;
  iCount: Integer;
  rCantidad, rPrecio, rTotal: Double;
begin
  LeerCabeceraAlbaran(AConn, ASerieAlbc, ANumAlbc, sCodigoEmp, sCodigoAlmCab,
                      dFechaAlbc);
  // Defensa: si el albaran no tiene almacen ni en cabecera ni en
  // lineas/celdas, no podemos generar movimientos. Lo detectamos linea
  // a linea (mas abajo) para no abortar el resto.
  // Sanidad: bloquear doble generacion. Si ya hay movs del albaran, no
  // generamos otra vez. La reversion debe llamarse explicita antes.
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := AConn;
    qChk.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = :t ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n';
    qChk.ParamByName('t').AsString :=
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
    qChk.ParamByName('s').AsString := ASerieAlbc;
    qChk.ParamByName('n').AsString := ANumAlbc;
    qChk.Open;
    if qChk.FieldByName('N').AsInteger > 0 then
      raise Exception.CreateFmt(SErrorAlbaranCompraMovimientosYaGenerados,
                                [ASerieAlbc, ANumAlbc]);
  finally
    FreeAndNil(qChk);
  end;
  qSrc := TUniQuery.Create(nil);
  spIns := TUniStoredProc.Create(nil);
  try
    qSrc.Connection := AConn;
    // Union de dos selects:
    //   A) Lineas SIN celdas con cantidad > 0: una entrada por linea.
    //   B) Celdas con cantidad > 0: una entrada por celda.
    // Asi cubrimos el flujo de materializacion (que solo escribe
    // lineas) y el de edicion manual con tallas (que escribe celdas).
    qSrc.SQL.Text :=
      'SELECT L.LINEA_ALBCLIN                     AS LINEA, ' +
      '       L.CODIGO_UNIDAD_ALBCLIN             AS SKU, ' +
      '       L.CODIGO_ART_ALBCLIN                AS ARTICULO, ' +
      '       L.CANTIDAD_ALBCLIN                  AS CANTIDAD, ' +
      '       CASE WHEN IFNULL(A.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') ' +
      '<> ''S'' ' +
      '             AND IFNULL(A.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' ' +
      '            THEN L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
      '              (1 + (IFNULL(L.PORCENTAJE_IVA_ALBCLIN, 0) + ' +
      '                CASE IFNULL(L.TIPO_IVA_ARTICULO_ALBCLIN, ''N'') ' +
      '                  WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) '
        +
      '                  WHEN ''R'' THEN ' +
      'IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                  WHEN ''S'' THEN ' +
      'IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                  WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) '
        +
      '                  ELSE 0 END) / 100) ' +
      '            ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN END * ' +
      '       CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
      '              GREATEST(0, 1 - CASE ' +
      '                WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 ' +
      '                THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
      'A.TOTAL_BRUTO_ALBC ' +
      '                ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100 ' +
      'END) ' +
      '            ELSE GREATEST(0, 1 - ' +
      'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '       END AS PRECIO, ' +
      '       IFNULL(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), :alm_cab1) AS ' +
      'ALMACEN ' +
      '  FROM fza_albaranes_compra_lineas L ' +
      '  JOIN fza_albaranes_compra A ' +
      '    ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '   AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '  LEFT JOIN fza_ivas V ON V.CODIGO_IVA = A.CODIGO_IVA_ALBC ' +
      ' WHERE L.SERIE_ALBC_ALBCLIN  = :s1 ' +
      '   AND L.NUMERO_ALBC_ALBCLIN = :n1 ' +
      '   AND IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_albaranes_compra_celdas C ' +
      '          WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN ' +
      '            AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
      '            AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
      '                = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
      '            AND C.CANTIDAD_ALBCCEL    > 0) ' +
      SqlOrigenCeldasAlbaranCompra;
    qSrc.ParamByName('s1').AsString      := ASerieAlbc;
    qSrc.ParamByName('n1').AsString      := ANumAlbc;
    qSrc.ParamByName('alm_cab1').AsString := sCodigoAlmCab;
    qSrc.ParamByName('s2').AsString      := ASerieAlbc;
    qSrc.ParamByName('n2').AsString      := ANumAlbc;
    qSrc.ParamByName('alm_cab2').AsString := sCodigoAlmCab;
    qSrc.Open;
    // Stored proc reutilizable: declaramos params una vez y reasignamos
    // los valores en cada vuelta para no crear/destruir N veces.
    spIns.Connection := AConn;
    spIns.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    spIns.Params.Clear;
    spIns.Params.CreateParam(ftString, 'p_NUMERO_MOV',                ptInput);
    spIns.Params.CreateParam(ftString, 'p_TIPO_DOC_MOV',              ptInput);
    spIns.Params.CreateParam(ftString, 'p_SERIE_DOC_MOV',             ptInput);
    spIns.Params.CreateParam(ftString, 'p_NRO_DOC_MOV',               ptInput);
    spIns.Params.CreateParam(ftString, 'p_LINEA_MOV',                 ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV',        ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV',        ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_CONTRA_MOV', ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV',         ptInput);
    spIns.Params.CreateParam(ftString, 'p_TIPO_MOVIMIENTO_MOV',       ptInput);
    spIns.Params.CreateParam(ftBCD,    'p_CANTIDAD_MOV',              ptInput);
    spIns.Params.CreateParam(ftBCD,    'p_PRECIO_MEDIO_MOV',          ptInput);
    spIns.Params.CreateParam(ftBCD,    'p_TOTAL_COSTE_MOV',           ptInput);
    spIns.Params.CreateParam(ftString, 'p_USUARIO',                   ptInput);
    spIns.Params.CreateParam(ftString, 'p_ALMACEN_DOC',               ptInput);
    spIns.Params.CreateParam(ftString, 'p_NUMOP_DOC',                 ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODIGO_CAJA_DOC_MOV',       ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODCLIENTE',                ptInput);
    spIns.Params.CreateParam(ftString, 'p_CODARTICULO',               ptInput);
    iCount := 0;
    while not qSrc.Eof do
    begin
      sCodigoSku := qSrc.FieldByName('SKU').AsString;
      sCodigoArt := qSrc.FieldByName('ARTICULO').AsString;
      sCodigoAlm := qSrc.FieldByName('ALMACEN').AsString;
      rCantidad  := qSrc.FieldByName('CANTIDAD').AsFloat;
      rPrecio    := qSrc.FieldByName('PRECIO').AsFloat;
      rTotal     := rCantidad * rPrecio;
      // Lineas sin SKU no pueden mover stock; las saltamos. No es
      // fatal porque pueden ser lineas de servicio o lineas en
      // construccion. Lo mismo para sin almacen efectivo.
      if (sCodigoSku <> '') and (sCodigoAlm <> '') then
      begin
        sNumeroMov := ObtenerSiguienteContador(
          AConn, 'MV', AUsuario);
      // LINEA_ALBCLIN ya viene en formato '0010', '0020', etc. Lo
      // reusamos tal cual como LINEA_MOV.
      sLinea := qSrc.FieldByName('LINEA').AsString;
      spIns.ParamByName('p_NUMERO_MOV').AsString          := sNumeroMov;
      spIns.ParamByName('p_TIPO_DOC_MOV').AsString :=
        EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
      spIns.ParamByName('p_SERIE_DOC_MOV').AsString       := ASerieAlbc;
      spIns.ParamByName('p_NRO_DOC_MOV').AsString         := ANumAlbc;
      spIns.ParamByName('p_LINEA_MOV').AsString           := sLinea;
      spIns.ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sCodigoEmp;
      spIns.ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sCodigoAlm;
      spIns.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
      spIns.ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sCodigoSku;
      spIns.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString :=
        EstrategiaAlbaranCompra.TipoMovimientoStock;
      spIns.ParamByName('p_CANTIDAD_MOV').AsFloat         := rCantidad;
      spIns.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat     := rPrecio;
      spIns.ParamByName('p_TOTAL_COSTE_MOV').AsFloat      := rTotal;
      spIns.ParamByName('p_USUARIO').AsString             := AUsuario;
      spIns.ParamByName('p_ALMACEN_DOC').AsString         := sCodigoAlm;
      spIns.ParamByName('p_NUMOP_DOC').AsString           := '';
      spIns.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
      spIns.ParamByName('p_CODCLIENTE').AsString          := '';
      spIns.ParamByName('p_CODARTICULO').AsString         := sCodigoArt;
      spIns.ExecProc;
        Inc(iCount);
      end;
      qSrc.Next;
    end;
    if iCount = 0 then
      raise Exception.CreateFmt(
        SErrorAlbaranCompraSinCantidadParaMovimientos,
        [ASerieAlbc, ANumAlbc]);
    ActualizarArticulosProveedorDesdeAlbaranCompra(AConn, ASerieAlbc,
      ANumAlbc, AUsuario);
    ActualizarCostesSkuDesdeAlbaranCompra(AConn, ASerieAlbc, ANumAlbc,
      AUsuario);
    FecharYRecalcularMovimientosDocumento(
      AConn,
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock,
      ASerieAlbc,
      ANumAlbc,
      dFechaAlbc);
  finally
    FreeAndNil(qSrc);
    FreeAndNil(spIns);
  end;
end;
// Recalcula PMP+stock para un (empresa, almacen) usando la temp table
// global tmp_skus_recalc que el llamante debe haber poblado con los
// SKUs afectados. Encapsula la llamada al SP del sistema.
procedure RecalcularPmpAlmacen(AConn: TUniConnection;
                               const ACodigoEmp, ACodigoAlm: string);
var
  spRecalc: TUniStoredProc;
begin
  spRecalc := TUniStoredProc.Create(nil);
  try
    spRecalc.Connection := AConn;
    spRecalc.StoredProcName := 'SP_RECALCULAR_PMP_LOTE_ALMACEN';
    spRecalc.Params.Clear;
    spRecalc.Params.CreateParam(ftString, 'p_EMPRESA', ptInput);
    spRecalc.Params.CreateParam(ftString, 'p_ALMACEN', ptInput);
    spRecalc.ParamByName('p_EMPRESA').AsString := ACodigoEmp;
    spRecalc.ParamByName('p_ALMACEN').AsString := ACodigoAlm;
    spRecalc.ExecProc;
  finally
    FreeAndNil(spRecalc);
  end;
end;
procedure RevertirMovimientosDesdeAlbaranCompra(AConn: TUniConnection;
                                                const ASerieAlbc, ANumAlbc,
                                                      AUsuario: string);
var
  qPares, qSkus, qExec: TUniQuery;
  sEmp, sAlm: string;
begin
  qPares := TUniQuery.Create(nil);
  qSkus  := TUniQuery.Create(nil);
  qExec  := TUniQuery.Create(nil);
  try
    qPares.Connection := AConn;
    qSkus.Connection  := AConn;
    qExec.Connection  := AConn;
    // 1. Pares (empresa, almacen) afectados ANTES de borrar nada.
    qPares.SQL.Text :=
      'SELECT DISTINCT CODIGO_EMP_MOV, CODIGO_ALM_MOV ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = :t ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n';
    qPares.ParamByName('t').AsString :=
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
    qPares.ParamByName('s').AsString := ASerieAlbc;
    qPares.ParamByName('n').AsString := ANumAlbc;
    qPares.Open;
    if not qPares.Eof then
    begin
    // 2. Borrar los movimientos llamando al SP, que decrementa
    //    CANTIDAD_STK + acumuladores por subtipo en una transacción.
    qExec.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    qExec.ParamByName('t').AsString :=
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
    qExec.ParamByName('s').AsString := ASerieAlbc;
    qExec.ParamByName('n').AsString := ANumAlbc;
    qExec.ExecSQL;
    // 3. Para cada par (empresa, almacen): poblar la temp tmp_skus_recalc
    //    con los SKUs que estuvieron en ese almacen (antes los teniamos
    //    en movimientos, pero como ya borramos, los sacamos de las
    //    lineas/celdas del propio albaran) y llamar al SP de recalculo.
    qPares.First;
    while not qPares.Eof do
    begin
      sEmp := qPares.FieldByName('CODIGO_EMP_MOV').AsString;
      sAlm := qPares.FieldByName('CODIGO_ALM_MOV').AsString;
      // Reset de la temp (la conexion es persistente entre statements
      // pero la temp puede no existir aun la primera vuelta).
      qExec.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc';
      qExec.ExecSQL;
      qExec.SQL.Text :=
        'CREATE TEMPORARY TABLE tmp_skus_recalc (' +
        '  sku VARCHAR(50) NOT NULL PRIMARY KEY) ENGINE=InnoDB';
      qExec.ExecSQL;
      // SKUs distintos del albaran asociados a este almacen. Cubrimos
      // ambas fuentes (celda con almacen propio y linea con almacen
      // de cabecera) con el mismo IFNULL de antes.
      qExec.SQL.Text :=
        'INSERT INTO tmp_skus_recalc (sku) ' +
        'SELECT DISTINCT L.CODIGO_UNIDAD_ALBCLIN ' +
        '  FROM fza_albaranes_compra_lineas L ' +
        ' WHERE L.SERIE_ALBC_ALBCLIN  = :s1 ' +
        '   AND L.NUMERO_ALBC_ALBCLIN = :n1 ' +
        '   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
        '              (SELECT CODIGO_ALM_ALBC FROM fza_albaranes_compra ' +
        '                WHERE SERIE_ALBC = :s1b AND NUMERO_ALBC = :n1b)) = ' +
        ':alm1 ' +
        '   AND L.CODIGO_UNIDAD_ALBCLIN IS NOT NULL ' +
        '   AND L.CODIGO_UNIDAD_ALBCLIN <> '''' ' +
        'UNION ' +
        'SELECT DISTINCT L.CODIGO_UNIDAD_ALBCLIN ' +
        '  FROM fza_albaranes_compra_lineas L ' +
        '  JOIN fza_albaranes_compra_celdas C ' +
        '    ON C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN ' +
        '   AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
        '   AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
        '       = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
        ' WHERE L.SERIE_ALBC_ALBCLIN  = :s2 ' +
        '   AND L.NUMERO_ALBC_ALBCLIN = :n2 ' +
        '   AND IFNULL(NULLIF(C.CODIGO_ALM_ALBCCEL, ''''), ' +
        '              IFNULL(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
        '                    (SELECT CODIGO_ALM_ALBC FROM fza_albaranes_compra '
          +
        '                      WHERE SERIE_ALBC = :s2b AND NUMERO_ALBC = ' +
        ':n2b))) = :alm2 ' +
        '   AND L.CODIGO_UNIDAD_ALBCLIN IS NOT NULL ' +
        '   AND L.CODIGO_UNIDAD_ALBCLIN <> '''' ';
      qExec.ParamByName('s1').AsString    := ASerieAlbc;
      qExec.ParamByName('n1').AsString    := ANumAlbc;
      qExec.ParamByName('s1b').AsString   := ASerieAlbc;
      qExec.ParamByName('n1b').AsString   := ANumAlbc;
      qExec.ParamByName('alm1').AsString  := sAlm;
      qExec.ParamByName('s2').AsString    := ASerieAlbc;
      qExec.ParamByName('n2').AsString    := ANumAlbc;
      qExec.ParamByName('s2b').AsString   := ASerieAlbc;
      qExec.ParamByName('n2b').AsString   := ANumAlbc;
      qExec.ParamByName('alm2').AsString  := sAlm;
      qExec.ExecSQL;
      // Recalcular PMP+stock del almacen para todos los SKUs en la temp.
      RecalcularPmpAlmacen(AConn, sEmp, sAlm);
      // Limpieza
      qExec.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc';
      qExec.ExecSQL;
      qPares.Next;
    end;
    end;
  finally
    FreeAndNil(qPares);
    FreeAndNil(qSkus);
    FreeAndNil(qExec);
  end;
end;
constructor TMovimientosAlbaranCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;
procedure TMovimientosAlbaranCompraUniDAC.GenerarDesdeAlbaran(
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  GenerarMovimientosDesdeAlbaranCompra(
    FConexion, ASerieAlbc, ANumAlbc, AUsuario);
end;
procedure TMovimientosAlbaranCompraUniDAC.RevertirDesdeAlbaran(
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  RevertirMovimientosDesdeAlbaranCompra(
    FConexion, ASerieAlbc, ANumAlbc, AUsuario);
end;
function CrearMovimientosAlbaranCompraUniDAC(
  AConexion: TUniConnection): IMovimientosAlbaranCompra;
begin
  Result := TMovimientosAlbaranCompraUniDAC.Create(AConexion);
end;
end.
