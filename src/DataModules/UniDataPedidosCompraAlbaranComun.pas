{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraAlbaranComun                              }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operaciones comunes para finalizar albaranes originados en pedidos.      }
{******************************************************************************}
unit UniDataPedidosCompraAlbaranComun;
interface
uses
  Uni;
procedure RecalcularTotalesAlbaranCompra(AConn: TUniConnection;
  const ASerieAlbc, ANumAlbc, AUsuario: string);
procedure CerrarAlbaranCompra(AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string);
procedure AplicarTemporadaArticulosAlbaran(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
procedure FinalizarAlbaranCreado(AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
    ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
procedure RegenerarMovimientosYCerrarAlbaranCompra(
  AConn: TUniConnection;
  const ASerieAlbc, ANumAlbc, ASeriePedc, ANumPedc,
    AUsuario: string; AIdPvTemporada: Integer);
implementation
uses
  System.SysUtils, Data.DB, DBAccess,
  inLibAlbaranesCompraMovimientos,
  UniDataAlbaranesCompraMovimientos,
  UniDataPedidosCompraPendientes;
procedure RecalcularTotalesAlbaranCompra(AConn: TUniConnection;
                                  const ASerieAlbc, ANumAlbc,
                                        AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra C ' +
      '  JOIN ( ' +
      '       SELECT L.NUMERO_ALBC_ALBCLIN, L.SERIE_ALBC_ALBCLIN, ' +
      '              IFNULL(SUM(L.TOTAL_ALBCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''N'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''R'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''S'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''E'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_E, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''N'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''R'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''S'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''E'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_E, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) / 100 ELSE 0 ' +
      'END), 0) AS RE_N, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) / 100 ELSE ' +
      '0 END), 0) AS RE_R, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) / 100 ' +
      'ELSE 0 END), 0) AS RE_S, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) / 100 ELSE 0 ' +
      'END), 0) AS RE_E, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_albaranes_compra_lineas L ' +
      '         JOIN fza_albaranes_compra H ' +
      '           ON H.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '          AND H.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
      '         LEFT JOIN fza_ivas V ON V.CODIGO_IVA = H.CODIGO_IVA_ALBC ' +
      '        WHERE L.NUMERO_ALBC_ALBCLIN = :n ' +
      '          AND L.SERIE_ALBC_ALBCLIN = :s ' +
      '        GROUP BY L.NUMERO_ALBC_ALBCLIN, L.SERIE_ALBC_ALBCLIN) T ' +
      '    ON T.NUMERO_ALBC_ALBCLIN = C.NUMERO_ALBC ' +
      '   AND T.SERIE_ALBC_ALBCLIN = C.SERIE_ALBC ' +
      '   SET C.TOTAL_BASEI_IVAN_ALBC = T.BASE_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAR_ALBC = T.BASE_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAS_ALBC = T.BASE_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAE_ALBC = T.BASE_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAN_ALBC = T.IVA_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAR_ALBC = T.IVA_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAS_ALBC = T.IVA_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAE_ALBC = T.IVA_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REN_ALBC = T.RE_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RER_ALBC = T.RE_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RES_ALBC = T.RE_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REE_ALBC = T.RE_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BRUTO_ALBC = T.BASE, ' +
      '       C.TOTAL_DTO_COMERCIAL_ALBC = T.BASE - T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_DTO_FINANCIERO_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
      '       C.TOTAL_BASES_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RETENCION_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100, ' +
      '       C.TOTAL_IMPUESTOS_ALBC = (T.IVA_N + T.IVA_R + T.IVA_S + ' +
      'T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_LIQUIDO_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '+ (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + ' +
      'T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) - T.BASE * ' +
      'GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100 - T.BASE ' +
      '* GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
      '       C.CONTADOR_LINEAS_ALBC = LPAD(T.NLIN * 10, 8, ''0''), ' +
      '       C.USUARIO_MODIF = :u, ' +
      '       C.INSTANTE_MODIF = NOW() ' +
      ' WHERE C.SERIE_ALBC = :s AND C.NUMERO_ALBC = :n';
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure CerrarAlbaranCompra(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string);
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConexion;
    Query.SQL.Text :=
      'UPDATE fza_albaranes_compra ' +
      '   SET ESTADO_ALBC = ''CERRADO'', ' +
      '       USUARIO_MODIF = :u, INSTANTE_MODIF = NOW() ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    Query.ParamByName('s').AsString := ASerieAlbaran;
    Query.ParamByName('n').AsString := ANumeroAlbaran;
    Query.ParamByName('u').AsString := AUsuario;
    Query.ExecSQL;
  finally
    FreeAndNil(Query);
  end;
end;
procedure AplicarTemporadaArticulosAlbaran(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
var
  Query: TUniQuery;
begin
  if AIdPvTemporada > 0 then
  begin
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := AConexion;
      Query.SQL.Text :=
        'INSERT INTO fza_articulos_propiedades ' +
        '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
        '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'SELECT DISTINCT L.CODIGO_ART_ALBCLIN, ' +
        '       ''TEMPORADA'', :pv, NULL, NOW(), :u ' +
        '  FROM fza_albaranes_compra_lineas L ' +
        ' WHERE L.SERIE_ALBC_ALBCLIN = :s ' +
        '   AND L.NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND L.CODIGO_ART_ALBCLIN IS NOT NULL ' +
        '   AND L.CODIGO_ART_ALBCLIN <> '''' ' +
        'ON DUPLICATE KEY UPDATE ID_PV_ARTPROP = :pv';
      Query.ParamByName('pv').AsInteger := AIdPvTemporada;
      Query.ParamByName('u').AsString := AUsuario;
      Query.ParamByName('s').AsString := ASerieAlbaran;
      Query.ParamByName('n').AsString := ANumeroAlbaran;
      Query.ExecSQL;
    finally
      FreeAndNil(Query);
    end;
  end;
end;
procedure FinalizarAlbaranCreado(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
    ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
begin
  RecalcularTotalesAlbaranCompra(
    AConexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  inLibAlbaranesCompraMovimientos.
    GenerarMovimientosDesdeAlbaranCompra(
      CrearMovimientosAlbaranCompraUniDAC(AConexion),
      ASerieAlbaran, ANumeroAlbaran, AUsuario);
  CerrarAlbaranCompra(
    AConexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  GenerarPdteRecibirDesdePedidoInterno(
    AConexion, ASeriePedido, ANumeroPedido, AUsuario);
  RecalcularEstadoPedido(
    AConexion, ASeriePedido, ANumeroPedido, AUsuario);
  AplicarTemporadaArticulosAlbaran(
    AConexion, ASerieAlbaran, ANumeroAlbaran,
    AUsuario, AIdPvTemporada);
end;
procedure RegenerarMovimientosYCerrarAlbaranCompra(AConn: TUniConnection;
                                  const ASerieAlbc, ANumAlbc,
                                        ASeriePedc, ANumPedc,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer);
var
  qIns: TUniQuery;
begin
  RecalcularTotalesAlbaranCompra(AConn, ASerieAlbc, ANumAlbc, AUsuario);
  inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
    CrearMovimientosAlbaranCompraUniDAC(AConn),
    ASerieAlbc, ANumAlbc, AUsuario);
  inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
    CrearMovimientosAlbaranCompraUniDAC(AConn),
    ASerieAlbc, ANumAlbc, AUsuario);
  CerrarAlbaranCompra(AConn, ASerieAlbc, ANumAlbc, AUsuario);
  GenerarPdteRecibirDesdePedidoInterno(
    AConn, ASeriePedc, ANumPedc, AUsuario);
  RecalcularEstadoPedido(AConn, ASeriePedc, ANumPedc, AUsuario);
  if AIdPvTemporada > 0 then
  begin
    qIns := TUniQuery.Create(nil);
    try
      qIns.Connection := AConn;
      qIns.SQL.Text :=
        'UPDATE fza_albaranes_compra ' +
        '   SET ID_PV_TEMPORADA_ALBC = :pv ' +
        ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
      qIns.ParamByName('pv').AsInteger := AIdPvTemporada;
      qIns.ParamByName('s').AsString := ASerieAlbc;
      qIns.ParamByName('n').AsString := ANumAlbc;
      qIns.ExecSQL;
    finally
      FreeAndNil(qIns);
    end;
    AplicarTemporadaArticulosAlbaran(
      AConn, ASerieAlbc, ANumAlbc, AUsuario, AIdPvTemporada);
  end;
end;
end.
