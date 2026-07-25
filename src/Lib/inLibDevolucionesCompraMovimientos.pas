{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDevolucionesCompraMovimientos                               }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Generacion y reversion de movimientos de almacen para devoluciones a      }
{    proveedor. Espejo de inLibAlbaranesCompraMovimientos pero generando       }
{    movimientos de SALIDA (TIPO_MOV='S') en vez de entrada: la cantidad       }
{    del documento va en positivo y el movimiento RESTA del stock, porque      }
{    la mercancia sale del almacen de vuelta al proveedor.                     }
{                                                                              }
{    Usa el procedimiento almacenado PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT,       }
{    que es el unico que toca stock real (fza_articulos_stockactual). El       }
{    signo lo pone el propio SP segun TIPO_MOV ('S' => resta CANTIDAD_STK      }
{    y VALOR_TOTAL_STK). El codigo de documento de los movimientos es 'DC'.    }
{    La reversion borra los movimientos por (TIPO_DOC='DC' + SERIE + NUMERO)   }
{    y recalcula PMP + stock de los SKUs afectados via                         }
{    SP_RECALCULAR_PMP_LOTE_ALMACEN.                                           }
{                                                                              }
{    Fuente de datos para los movimientos:                                     }
{      - fza_devoluciones_compra_celdas si la linea tiene celdas con           }
{        cantidad > 0 (caso edicion manual con tallas).                        }
{      - fza_devoluciones_compra_lineas en caso contrario, una salida por      }
{        linea con CANTIDAD_DEVCLIN.                                           }
{                                                                              }
{    Limitacion conocida: ambos caminos asumen que el SKU de la linea          }
{    (CODIGO_UNIDAD_DEVCLIN) es el correcto. No resolvemos un SKU              }
{    distinto por celda; cuando se permita en un hito futuro habra que         }
{    ampliar ResolverSkuCelda en el bucle de celdas.                           }
{******************************************************************************}
unit inLibDevolucionesCompraMovimientos;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, DBAccess, Uni;

// Genera movimientos de salida (TIPO_DOC_MOV='DC', TIPO_MOV='S') para
// todas las celdas con cantidad > 0 de la devolucion, o para sus lineas
// cuando no haya celdas. AConn debe estar viva; la transaccion la
// gestiona el llamante (este procedimiento no abre ni cierra
// transacciones).
procedure GenerarMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                               const ASerieDevc, ANumDevc,
                                                     AUsuario: string);

// Revierte los movimientos creados por GenerarMovimientosDesdeDevolucionCompra.
// Borra fza_movimientos_almacen con TIPO_DOC='DC' + SERIE/NUMERO y
// recalcula el stock/PMP de los SKUs afectados via
// SP_RECALCULAR_PMP_LOTE_ALMACEN para cada (empresa, almacen) tocado.
// Es idempotente: si no hay movimientos, no hace nada.
procedure RevertirMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                                const ASerieDevc, ANumDevc,
                                                      AUsuario: string);

implementation

uses
  inLibtb;

// Carga los datos minimos del devolucion necesarios para construir los
// movimientos: empresa (para el parametro p_CODIGO_EMPRESA_MOV) y
// almacen por defecto de la cabecera (fallback cuando linea/celda no
// llevan almacen propio).
procedure LeerCabeceraDevolucion(AConn: TUniConnection;
                              const ASerieDevc, ANumDevc: string;
                              out ACodigoEmp, ACodigoAlmCab: string);
var
  q: TUniQuery;
begin
  ACodigoEmp    := '';
  ACodigoAlmCab := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT CODIGO_EMP_DEVC, CODIGO_ALM_DEVC ' +
      '  FROM fza_devoluciones_compra ' +
      ' WHERE SERIE_DEVC = :s AND NUMERO_DEVC = :n';
    q.ParamByName('s').AsString := ASerieDevc;
    q.ParamByName('n').AsString := ANumDevc;
    q.Open;
    if q.Eof then
      raise Exception.CreateFmt(
        'Devolucion de compra %s/%s no encontrada para generar movimientos.',
        [ASerieDevc, ANumDevc]);
    ACodigoEmp    := q.FieldByName('CODIGO_EMP_DEVC').AsString;
    ACodigoAlmCab := q.FieldByName('CODIGO_ALM_DEVC').AsString;
  finally
    FreeAndNil(q);
  end;
end;

procedure GenerarMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                               const ASerieDevc, ANumDevc,
                                                     AUsuario: string);
var
  qSrc, qChk: TUniQuery;
  spIns: TUniStoredProc;
  sCodigoEmp, sCodigoAlmCab, sCodigoAlm, sCodigoSku, sCodigoArt,
  sNumeroMov, sLinea: string;
  iCount: Integer;
  rCantidad, rPrecio, rTotal: Double;
begin
  LeerCabeceraDevolucion(AConn, ASerieDevc, ANumDevc, sCodigoEmp, sCodigoAlmCab);
  // Defensa: si la devolucion no tiene almacen ni en cabecera ni en
  // lineas/celdas, no podemos generar movimientos. Lo detectamos linea
  // a linea (mas abajo) para no abortar el resto.
  // Sanidad: bloquear doble generacion. Si ya hay movs de la devolucion, no
  // generamos otra vez. La reversion debe llamarse explicita antes.
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := AConn;
    qChk.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = ''DC'' ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n';
    qChk.ParamByName('s').AsString := ASerieDevc;
    qChk.ParamByName('n').AsString := ANumDevc;
    qChk.Open;
    if qChk.FieldByName('N').AsInteger > 0 then
      raise Exception.CreateFmt(
        'La devolucion %s/%s ya tiene movimientos generados. Revierte antes de ' +
        'volver a generar.', [ASerieDevc, ANumDevc]);
  finally
    FreeAndNil(qChk);
  end;
  qSrc := TUniQuery.Create(nil);
  spIns := TUniStoredProc.Create(nil);
  try
    qSrc.Connection := AConn;
    // Union de dos selects:
    //   A) Lineas SIN celdas con cantidad > 0: una salida por linea.
    //   B) Celdas con cantidad > 0: una salida por celda.
    // Asi cubrimos el flujo de materializacion (que solo escribe
    // lineas) y el de edicion manual con tallas (que escribe celdas).
    qSrc.SQL.Text :=
      'SELECT L.LINEA_DEVCLIN                     AS LINEA, ' +
      '       L.CODIGO_UNIDAD_DEVCLIN             AS SKU, ' +
      '       L.CODIGO_ART_DEVCLIN                AS ARTICULO, ' +
      '       L.CANTIDAD_DEVCLIN                  AS CANTIDAD, ' +
      '       L.PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN * ' +
      '       CASE WHEN IFNULL(A.TOTAL_BRUTO_DEVC, 0) > 0 THEN ' +
      '              GREATEST(0, 1 - CASE ' +
      '                WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) <> 0 ' +
      '                THEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) / A.TOTAL_BRUTO_DEVC ' +
      '                ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100 END) ' +
      '            ELSE GREATEST(0, 1 - IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100) ' +
      '       END AS PRECIO, ' +
      '       IFNULL(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''), :alm_cab1) AS ALMACEN ' +
      '  FROM fza_devoluciones_compra_lineas L ' +
      '  JOIN fza_devoluciones_compra A ' +
      '    ON A.SERIE_DEVC = L.SERIE_DEVC_DEVCLIN ' +
      '   AND A.NUMERO_DEVC = L.NUMERO_DEVC_DEVCLIN ' +
      ' WHERE L.SERIE_DEVC_DEVCLIN  = :s1 ' +
      '   AND L.NUMERO_DEVC_DEVCLIN = :n1 ' +
      '   AND IFNULL(L.CANTIDAD_DEVCLIN, 0) > 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_devoluciones_compra_celdas C ' +
      '          WHERE C.SERIE_DEVC_DEVCCEL  = L.SERIE_DEVC_DEVCLIN ' +
      '            AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
      '            AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
      '                = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
      '            AND C.CANTIDAD_DEVCCEL    > 0) ' +
      'UNION ALL ' +
      'SELECT L.LINEA_DEVCLIN                     AS LINEA, ' +
      '       L.CODIGO_UNIDAD_DEVCLIN             AS SKU, ' +
      '       L.CODIGO_ART_DEVCLIN                AS ARTICULO, ' +
      '       C.CANTIDAD_DEVCCEL                  AS CANTIDAD, ' +
      '       L.PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN * ' +
      '       CASE WHEN IFNULL(A.TOTAL_BRUTO_DEVC, 0) > 0 THEN ' +
      '              GREATEST(0, 1 - CASE ' +
      '                WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) <> 0 ' +
      '                THEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) / A.TOTAL_BRUTO_DEVC ' +
      '                ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100 END) ' +
      '            ELSE GREATEST(0, 1 - IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100) ' +
      '       END AS PRECIO, ' +
      '       IFNULL(NULLIF(C.CODIGO_ALM_DEVCCEL, ''''), ' +
      '              IFNULL(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''), :alm_cab2)) AS ALMACEN ' +
      '  FROM fza_devoluciones_compra_lineas L ' +
      '  JOIN fza_devoluciones_compra A ' +
      '    ON A.SERIE_DEVC = L.SERIE_DEVC_DEVCLIN ' +
      '   AND A.NUMERO_DEVC = L.NUMERO_DEVC_DEVCLIN ' +
      '  JOIN fza_devoluciones_compra_celdas C ' +
      '    ON C.SERIE_DEVC_DEVCCEL  = L.SERIE_DEVC_DEVCLIN ' +
      '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
      '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
      '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
      ' WHERE L.SERIE_DEVC_DEVCLIN  = :s2 ' +
      '   AND L.NUMERO_DEVC_DEVCLIN = :n2 ' +
      '   AND C.CANTIDAD_DEVCCEL    > 0 ' +
      ' ORDER BY LINEA';
    qSrc.ParamByName('s1').AsString      := ASerieDevc;
    qSrc.ParamByName('n1').AsString      := ANumDevc;
    qSrc.ParamByName('alm_cab1').AsString := sCodigoAlmCab;
    qSrc.ParamByName('s2').AsString      := ASerieDevc;
    qSrc.ParamByName('n2').AsString      := ANumDevc;
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
      if (sCodigoSku = '') or (sCodigoAlm = '') then
      begin
        qSrc.Next;
        Continue;
      end;
      sNumeroMov := inLibtb.ObtenerSiguienteContador(AConn, 'MV', AUsuario);
      // LINEA_DEVCLIN ya viene en formato '0010', '0020', etc. Lo
      // reusamos tal cual como LINEA_MOV.
      sLinea := qSrc.FieldByName('LINEA').AsString;
      spIns.ParamByName('p_NUMERO_MOV').AsString          := sNumeroMov;
      spIns.ParamByName('p_TIPO_DOC_MOV').AsString        := 'DC';
      spIns.ParamByName('p_SERIE_DOC_MOV').AsString       := ASerieDevc;
      spIns.ParamByName('p_NRO_DOC_MOV').AsString         := ANumDevc;
      spIns.ParamByName('p_LINEA_MOV').AsString           := sLinea;
      spIns.ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sCodigoEmp;
      spIns.ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sCodigoAlm;
      spIns.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
      spIns.ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sCodigoSku;
      spIns.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := 'S';
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
      qSrc.Next;
    end;
    if iCount = 0 then
      raise Exception.CreateFmt(
        'La devolucion %s/%s no tiene ninguna linea o celda con cantidad > 0 ' +
        'para generar movimientos.', [ASerieDevc, ANumDevc]);
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

procedure RevertirMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                                const ASerieDevc, ANumDevc,
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
      ' WHERE TIPO_DOC_MOV   = ''DC'' ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n';
    qPares.ParamByName('s').AsString := ASerieDevc;
    qPares.ParamByName('n').AsString := ANumDevc;
    qPares.Open;
    if qPares.Eof then
      Exit;  // nada que revertir
    // 2. Borrar los movimientos llamando al SP, que decrementa
    //    CANTIDAD_STK + acumuladores por subtipo en una transacción.
    qExec.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    qExec.ParamByName('t').AsString := 'DC';
    qExec.ParamByName('s').AsString := ASerieDevc;
    qExec.ParamByName('n').AsString := ANumDevc;
    qExec.ExecSQL;
    // 3. Para cada par (empresa, almacen): poblar la temp tmp_skus_recalc
    //    con los SKUs que estuvieron en ese almacen (antes los teniamos
    //    en movimientos, pero como ya borramos, los sacamos de las
    //    lineas/celdas del propio devolucion) y llamar al SP de recalculo.
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
      // SKUs distintos del devolucion asociados a este almacen. Cubrimos
      // ambas fuentes (celda con almacen propio y linea con almacen
      // de cabecera) con el mismo IFNULL de antes.
      qExec.SQL.Text :=
        'INSERT INTO tmp_skus_recalc (sku) ' +
        'SELECT DISTINCT L.CODIGO_UNIDAD_DEVCLIN ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        ' WHERE L.SERIE_DEVC_DEVCLIN  = :s1 ' +
        '   AND L.NUMERO_DEVC_DEVCLIN = :n1 ' +
        '   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''), ' +
        '              (SELECT CODIGO_ALM_DEVC FROM fza_devoluciones_compra ' +
        '                WHERE SERIE_DEVC = :s1b AND NUMERO_DEVC = :n1b)) = :alm1 ' +
        '   AND L.CODIGO_UNIDAD_DEVCLIN IS NOT NULL ' +
        '   AND L.CODIGO_UNIDAD_DEVCLIN <> '''' ' +
        'UNION ' +
        'SELECT DISTINCT L.CODIGO_UNIDAD_DEVCLIN ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        '  JOIN fza_devoluciones_compra_celdas C ' +
        '    ON C.SERIE_DEVC_DEVCCEL  = L.SERIE_DEVC_DEVCLIN ' +
        '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
        '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
      '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
        ' WHERE L.SERIE_DEVC_DEVCLIN  = :s2 ' +
        '   AND L.NUMERO_DEVC_DEVCLIN = :n2 ' +
        '   AND IFNULL(NULLIF(C.CODIGO_ALM_DEVCCEL, ''''), ' +
        '              IFNULL(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''), ' +
        '                    (SELECT CODIGO_ALM_DEVC FROM fza_devoluciones_compra ' +
        '                      WHERE SERIE_DEVC = :s2b AND NUMERO_DEVC = :n2b))) = :alm2 ' +
        '   AND L.CODIGO_UNIDAD_DEVCLIN IS NOT NULL ' +
        '   AND L.CODIGO_UNIDAD_DEVCLIN <> '''' ';
      qExec.ParamByName('s1').AsString    := ASerieDevc;
      qExec.ParamByName('n1').AsString    := ANumDevc;
      qExec.ParamByName('s1b').AsString   := ASerieDevc;
      qExec.ParamByName('n1b').AsString   := ANumDevc;
      qExec.ParamByName('alm1').AsString  := sAlm;
      qExec.ParamByName('s2').AsString    := ASerieDevc;
      qExec.ParamByName('n2').AsString    := ANumDevc;
      qExec.ParamByName('s2b').AsString   := ASerieDevc;
      qExec.ParamByName('n2b').AsString   := ANumDevc;
      qExec.ParamByName('alm2').AsString  := sAlm;
      qExec.ExecSQL;
      // Recalcular PMP+stock del almacen para todos los SKUs en la temp.
      RecalcularPmpAlmacen(AConn, sEmp, sAlm);
      // Limpieza
      qExec.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc';
      qExec.ExecSQL;
      qPares.Next;
    end;
  finally
    FreeAndNil(qPares);
    FreeAndNil(qSkus);
    FreeAndNil(qExec);
  end;
end;

end.
