{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPedidosCompra                                            }
{    Tipo:       Libreria (sin formulario)                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Logica de negocio del Mto de Pedidos de Compra. Tres funciones:           }
{                                                                              }
{    1. GenerarPdteRecibirDesdePedido — sincroniza el contenido de             }
{       fza_articulos_pdte_recibir con las lineas del pedido. Se llama         }
{       en AfterPost de la cabecera (DM): primero borra las filas del          }
{       pedido y luego reinserta una por linea con cantidad pendiente > 0.     }
{                                                                              }
{    2. BorrarPdteRecibirDesdePedido — limpia fza_articulos_pdte_recibir       }
{       para un pedido concreto. Se llama en BeforeDelete (DM).                }
{                                                                              }
{    3. CrearAlbaranDesdePedido — genera un albaran de compra para un          }
{       almacen concreto a partir del pedido. Incrementa                       }
{       CANTIDAD_RECIBIDA_PEDCLIN, recalcula ESTADO_PEDC, dispara los          }
{       movimientos via inLibAlbaranesCompraMovimientos al cerrar el           }
{       albaran. Devuelve la serie / numero del albaran generado.              }
{                                                                              }
{    Las operaciones de bajo nivel esperan una transaccion del llamador.       }
{    EjecutarRecepcionPedidoCompra es el caso de uso transaccional para UI.    }
{******************************************************************************}
unit inLibPedidosCompra;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, Uni,
  inLibGridPivoteCompra;

type
  TParametrosRecepcionPedidoCompra = record
    SeriePedido: string;
    NumeroPedido: string;
    CodigoAlmacen: string;
    SerieAlbaran: string;
    SerieAlbaranDestino: string;
    NumeroAlbaranDestino: string;
    Usuario: string;
    ReferenciaProveedor: string;
    FechaRecepcion: TDateTime;
    IdPvTemporada: Integer;
    Incorporar: Boolean;
    Celdas: TArray<TCeldaARecibir>;
  end;

  TResultadoRecepcionPedidoCompra = record
    SerieAlbaran: string;
    NumeroAlbaran: string;
    Mensaje: string;
  end;

// Sincroniza fza_articulos_pdte_recibir con las lineas del pedido:
// borra todas las filas del pedido y reinserta una por linea con
// cantidad pendiente > 0. Se llama tras Post de la cabecera para
// reflejar el ultimo estado del pedido.
procedure GenerarPdteRecibirDesdePedido(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc,
                                               AUsuario: string);

// Borra todas las filas de fza_articulos_pdte_recibir asociadas al
// pedido. Se llama en BeforeDelete de la cabecera (para no dejar
// huerfanas) y al borrar una linea concreta tambien hay que pasar
// ALinea para borrar solo esa.
procedure BorrarPdteRecibirDesdePedido(AConn: TUniConnection;
                                        const ASeriePedc, ANumPedc: string;
                                        const ALinea: string = '');

// Crea un albaran de compra a partir de las lineas del pedido cuyo
// CODIGO_ALMACEN_PEDCLIN coincide con ACodigoAlm y cuya cantidad
// pendiente (CANTIDAD - CANTIDAD_RECIBIDA) sea > 0. El albaran nace
// cerrado para que se disparen los movimientos via
// inLibAlbaranesCompraMovimientos. Actualiza CANTIDAD_RECIBIDA_PEDCLIN
// y recalcula ESTADO_PEDC.
//
// Devuelve True si el albaran se creo. Si no habia lineas pendientes
// para el almacen, devuelve False y AMensaje explica el motivo.
// Implementada como caso particular de ...ConCantidades: construye una
// celda por linea pendiente y delega (un solo camino de codigo).
//
// Los parametros ARefPrv, AFechaRecepcion y AIdPvTemporada vienen del
// modal "Crear albaran" y sobreescriben los defaults del pedido
// (REF_PROVEEDOR_PEDC, FECHA_PEDC, etc). Si ARefPrv='' se usa el del
// pedido; si AFechaRecepcion=0 se usa la del pedido; si
// AIdPvTemporada=0 no se aplica temporada explicita.
function CrearAlbaranDesdePedido(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm, ASerieAlbc,
                                        AUsuario: string;
                                  const ARefPrv: string;
                                  AFechaRecepcion: TDateTime;
                                  AIdPvTemporada: Integer;
                                  out ANumAlbc: string;
                                  out AMensaje: string): Boolean;

// Variante de CrearAlbaranDesdePedido que NO toma todas las lineas
// pendientes del almacen, sino solo las cantidades explicitas que
// el usuario ha tecleado celda a celda (ACeldas). Cada celda lleva
// SKU + LINEA_PEDCLIN + Cantidad. Se filtran por ACodigoAlm (la celda
// tiene que coincidir con el almacen elegido) y por Cantidad > 0.
// El resto del flujo (cabecera, movimientos, totales, pendientes,
// temporada) es identico al CrearAlbaranDesdePedido clasico.
function CrearAlbaranDesdePedidoConCantidades(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm, ASerieAlbc,
                                        AUsuario: string;
                                  const ARefPrv: string;
                                  AFechaRecepcion: TDateTime;
                                  AIdPvTemporada: Integer;
                                  const ACeldas: TArray<TCeldaARecibir>;
                                  out ANumAlbc: string;
                                  out AMensaje: string): Boolean;

// Devuelve la cantidad pendiente de recibir total del pedido (suma de
// CANTIDAD - CANTIDAD_RECIBIDA por linea, sin importar almacen). Util
// para refrescar el estado en pantalla sin recargar el dataset.
function CalcularPendienteTotal(AConn: TUniConnection;
                                 const ASeriePedc, ANumPedc: string): Double;

// Incorpora las lineas pendientes de un almacen a un albaran de compra
// que YA EXISTE del mismo pedido (en lugar de crear uno nuevo). Anade las
// lineas continuando la numeracion, revierte los movimientos del albaran
// y los regenera para TODO el albaran: asi entra el stock de las lineas
// nuevas sin chocar con el guard anti-doble-generacion. El albaran sigue
// CERRADO. ASerieAlbcDestino / ANumAlbcDestino identifican el albaran.
function IncorporarAlbaranDesdePedido(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm,
                                        ASerieAlbcDestino, ANumAlbcDestino,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer;
                                  out AMensaje: string): Boolean;

// Variante por celdas (cantidades tecleadas) de IncorporarAlbaranDesdePedido.
function IncorporarAlbaranDesdePedidoConCantidades(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm,
                                        ASerieAlbcDestino, ANumAlbcDestino,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer;
                                   const ACeldas: TArray<TCeldaARecibir>;
                                   out AMensaje: string): Boolean;

// Ejecuta la recepcion completa dentro de una unica transaccion. Decide
// entre crear o incorporar y entre recibir cantidades explicitas o todo
// lo pendiente del almacen.
function EjecutarRecepcionPedidoCompra(AConn: TUniConnection;
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;

implementation

uses
  inLibValoresAutomaticos,
  inLibAlbaranesCompraMovimientos,
  inLibMsg;

function EjecutarRecepcionPedidoCompra(AConn: TUniConnection;
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
var
  bTxOwned: Boolean;
  bUsarCeldas: Boolean;
begin
  AResultado.SerieAlbaran := '';
  AResultado.NumeroAlbaran := '';
  AResultado.Mensaje := '';
  bUsarCeldas := Length(AParametros.Celdas) > 0;
  bTxOwned := not AConn.InTransaction;
  if bTxOwned then
    AConn.StartTransaction;
  try
    if AParametros.Incorporar then
    begin
      AResultado.SerieAlbaran := AParametros.SerieAlbaranDestino;
      AResultado.NumeroAlbaran := AParametros.NumeroAlbaranDestino;
      if bUsarCeldas then
        Result := IncorporarAlbaranDesdePedidoConCantidades(
          AConn,
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaranDestino,
          AParametros.NumeroAlbaranDestino,
          AParametros.Usuario,
          AParametros.IdPvTemporada,
          AParametros.Celdas,
          AResultado.Mensaje)
      else
        Result := IncorporarAlbaranDesdePedido(
          AConn,
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaranDestino,
          AParametros.NumeroAlbaranDestino,
          AParametros.Usuario,
          AParametros.IdPvTemporada,
          AResultado.Mensaje);
    end
    else
    begin
      AResultado.SerieAlbaran := AParametros.SerieAlbaran;
      if bUsarCeldas then
        Result := CrearAlbaranDesdePedidoConCantidades(
          AConn,
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaran,
          AParametros.Usuario,
          AParametros.ReferenciaProveedor,
          AParametros.FechaRecepcion,
          AParametros.IdPvTemporada,
          AParametros.Celdas,
          AResultado.NumeroAlbaran,
          AResultado.Mensaje)
      else
        Result := CrearAlbaranDesdePedido(
          AConn,
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaran,
          AParametros.Usuario,
          AParametros.ReferenciaProveedor,
          AParametros.FechaRecepcion,
          AParametros.IdPvTemporada,
          AResultado.NumeroAlbaran,
          AResultado.Mensaje);
    end;
    if Result then
    begin
      if bTxOwned and AConn.InTransaction then
        AConn.Commit;
    end
    else if bTxOwned and AConn.InTransaction then
      AConn.Rollback;
  except
    if bTxOwned and AConn.InTransaction then
      AConn.Rollback;
    raise;
  end;
end;

// Recalcula ESTADO_PEDC en funcion de la cantidad pendiente total.
// Reglas:
//   * Pedido sin lineas o cancelado por el usuario: no se toca.
//   * Total recibido == total pedido (pendiente <= 0): RECIBIDO.
//   * Algo recibido pero no todo: PARCIAL.
//   * Nada recibido: ABIERTO.
procedure RecalcularEstadoPedido(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        AUsuario: string);
var
  q: TUniQuery;
  rPedida, rRecibida: Double;
  sEstado, sEstadoActual: string;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(SUM(CANTIDAD_PEDCLIN),0)           AS PEDIDA, ' +
      '       IFNULL(SUM(CANTIDAD_RECIBIDA_PEDCLIN),0)  AS RECIBIDA ' +
      '  FROM fza_pedidos_compra_lineas ' +
      ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND NUMERO_PEDC_PEDCLIN = :n';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    rPedida   := q.FieldByName('PEDIDA').AsFloat;
    rRecibida := q.FieldByName('RECIBIDA').AsFloat;
    q.Close;
    q.SQL.Text :=
      'SELECT ESTADO_PEDC FROM fza_pedidos_compra ' +
      ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    if q.Eof then Exit;
    sEstadoActual := UpperCase(Trim(q.FieldByName('ESTADO_PEDC').AsString));
    q.Close;
    // Si el usuario lo cancelo explicitamente, no lo reescribimos.
    if sEstadoActual = 'CANCELADO' then Exit;
    if rPedida <= 0 then
      sEstado := 'ABIERTO'
    else if rRecibida + 0.000001 >= rPedida then
      sEstado := 'RECIBIDO'
    else if rRecibida > 0 then
      sEstado := 'PARCIAL'
    else
      sEstado := 'ABIERTO';
    if sEstado = sEstadoActual then Exit;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra ' +
      '   SET ESTADO_PEDC    = :e, ' +
      '       USUARIO_MODIF  = :u, ' +
      '       INSTANTE_MODIF = NOW() ' +
      ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n';
    q.ParamByName('e').AsString := sEstado;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure BorrarPdteRecibirDesdePedido(AConn: TUniConnection;
                                        const ASeriePedc, ANumPedc: string;
                                        const ALinea: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    if ALinea = '' then
    begin
      q.SQL.Text :=
        'DELETE FROM fza_articulos_pdte_recibir ' +
        ' WHERE SERIE_DOC_PDR  = :s ' +
        '   AND NUMERO_DOC_PDR = :n';
      q.ParamByName('s').AsString := ASeriePedc;
      q.ParamByName('n').AsString := ANumPedc;
    end
    else
    begin
      q.SQL.Text :=
        'DELETE FROM fza_articulos_pdte_recibir ' +
        ' WHERE SERIE_DOC_PDR  = :s ' +
        '   AND NUMERO_DOC_PDR = :n ' +
        '   AND LINEA_PDR      = :l';
      q.ParamByName('s').AsString  := ASeriePedc;
      q.ParamByName('n').AsString  := ANumPedc;
      q.ParamByName('l').AsInteger := StrToIntDef(ALinea, 0);
    end;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure GenerarPdteRecibirDesdePedido(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc,
                                               AUsuario: string);
var
  q, qIns: TUniQuery;
  sSku, sArt, sAlm, sPrv, sEmp: string;
  rPendiente, rPrecio: Double;
  iLinea: Integer;
  dFechaPed, dFechaPrev: TDateTime;
  bFechaPrevNull: Boolean;
begin
  // Borramos todo lo que habia y reinsertamos. Mucho mas simple que un
  // diff y los pedidos no suelen tener mas de unas decenas de lineas.
  BorrarPdteRecibirDesdePedido(AConn, ASeriePedc, ANumPedc);

  q    := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    dFechaPrev := 0;
    q.Connection    := AConn;
    qIns.Connection := AConn;
    q.SQL.Text :=
      'SELECT L.LINEA_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
      '       L.CODIGO_ART_PEDCLIN, ' +
      '       IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) AS ALM_EFE, ' +
      '       L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) AS PENDIENTE, ' +
      '       CASE WHEN IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' ' +
      '             AND IFNULL(P.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' ' +
      '            THEN L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN * ' +
      '              (1 + (IFNULL(L.PORCENTAJE_IVA_PEDCLIN, 0) + ' +
      '                CASE IFNULL(L.TIPO_IVA_ARTICULO_PEDCLIN, ''N'') ' +
      '                  WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
      '                  WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                  WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                  WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
      '                  ELSE 0 END) / 100) ' +
      '            ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN END * ' +
      '       CASE WHEN IFNULL(P.TOTAL_BRUTO_PEDC, 0) > 0 THEN ' +
      '              GREATEST(0, 1 - CASE ' +
      '                WHEN IFNULL(P.TOTAL_DTO_COMERCIAL_PEDC, 0) <> 0 ' +
      '                THEN IFNULL(P.TOTAL_DTO_COMERCIAL_PEDC, 0) / P.TOTAL_BRUTO_PEDC ' +
      '                ELSE IFNULL(P.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100 END) ' +
      '            ELSE GREATEST(0, 1 - IFNULL(P.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) ' +
      '       END AS PRECIO, ' +
      '       P.CODIGO_PRV_PEDC, P.CODIGO_EMP_PEDC, ' +
      '       P.FECHA_PEDC, P.FECHA_PREVISTA_PEDC ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '  LEFT JOIN fza_ivas V ON V.CODIGO_IVA = P.CODIGO_IVA_PEDC ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND L.CODIGO_UNIDAD_PEDCLIN IS NOT NULL ' +
      '   AND L.CODIGO_UNIDAD_PEDCLIN <> '''' ' +
      '   AND L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    while not q.Eof do
    begin
      iLinea     := StrToIntDef(q.FieldByName('LINEA_PEDCLIN').AsString, 0);
      sSku       := q.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
      sArt       := q.FieldByName('CODIGO_ART_PEDCLIN').AsString;
      sAlm       := q.FieldByName('ALM_EFE').AsString;
      rPendiente := q.FieldByName('PENDIENTE').AsFloat;
      rPrecio    := q.FieldByName('PRECIO').AsFloat;
      sPrv       := q.FieldByName('CODIGO_PRV_PEDC').AsString;
      sEmp       := q.FieldByName('CODIGO_EMP_PEDC').AsString;
      // Fecha pedido: si la cabecera no tiene fecha, usamos hoy.
      if q.FieldByName('FECHA_PEDC').IsNull then
        dFechaPed := Date
      else
        dFechaPed := q.FieldByName('FECHA_PEDC').AsDateTime;
      bFechaPrevNull := q.FieldByName('FECHA_PREVISTA_PEDC').IsNull;
      if not bFechaPrevNull then
        dFechaPrev := q.FieldByName('FECHA_PREVISTA_PEDC').AsDateTime;
      // Defensa: sin almacen no podemos enganchar el compromiso a ningun
      // sitio. Saltamos esa linea — el usuario corrige y vuelve a grabar.
      if (sSku = '') or (sAlm = '') or (rPendiente <= 0) then
      begin
        q.Next;
        Continue;
      end;
      qIns.SQL.Text :=
        'INSERT INTO fza_articulos_pdte_recibir ' +
        '  (CODIGO_UNIDAD_PDR, CODIGO_ALM_PDR, SERIE_DOC_PDR, NUMERO_DOC_PDR, ' +
        '   LINEA_PDR, CODIGO_ART_PDR, CODIGO_PRV_PDR, CODIGO_EMP_PDR, ' +
        '   CANTIDAD_PDR, PRECIO_COMPRA_PDR, FECHA_PEDIDO_PDR, ' +
        '   FECHA_PREVISTA_PDR, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :alm, :s, :n, :l, :art, :prv, :emp, ' +
        '        :qty, :pre, :fped, :fprev, NOW(), :u, NOW(), :u) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  CANTIDAD_PDR        = :qty, ' +
        '  PRECIO_COMPRA_PDR   = :pre, ' +
        '  FECHA_PEDIDO_PDR    = :fped, ' +
        '  FECHA_PREVISTA_PDR  = :fprev, ' +
        '  INSTANTE_MODIF      = NOW(), ' +
        '  USUARIO_MODIF       = :u';
      qIns.ParamByName('sku').AsString := sSku;
      qIns.ParamByName('alm').AsString := sAlm;
      qIns.ParamByName('s').AsString   := ASeriePedc;
      qIns.ParamByName('n').AsString   := ANumPedc;
      qIns.ParamByName('l').AsInteger  := iLinea;
      qIns.ParamByName('art').AsString := sArt;
      qIns.ParamByName('prv').AsString := sPrv;
      qIns.ParamByName('emp').AsString := sEmp;
      qIns.ParamByName('qty').AsFloat  := rPendiente;
      qIns.ParamByName('pre').AsFloat  := rPrecio;
      qIns.ParamByName('fped').AsDateTime := dFechaPed;
      if bFechaPrevNull then
        qIns.ParamByName('fprev').Clear
      else
        qIns.ParamByName('fprev').AsDateTime := dFechaPrev;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ExecSQL;
      q.Next;
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(qIns);
  end;
end;

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
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_E, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_E, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_N, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_R, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_S, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_E, ' +
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
      '   SET C.TOTAL_BASEI_IVAN_ALBC = T.BASE_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAR_ALBC = T.BASE_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAS_ALBC = T.BASE_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAE_ALBC = T.BASE_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAN_ALBC = T.IVA_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAR_ALBC = T.IVA_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAS_ALBC = T.IVA_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAE_ALBC = T.IVA_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REN_ALBC = T.RE_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RER_ALBC = T.RE_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RES_ALBC = T.RE_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REE_ALBC = T.RE_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BRUTO_ALBC = T.BASE, ' +
      '       C.TOTAL_DTO_COMERCIAL_ALBC = T.BASE - T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_DTO_FINANCIERO_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
      '       C.TOTAL_BASES_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RETENCION_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100, ' +
      '       C.TOTAL_IMPUESTOS_ALBC = (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_LIQUIDO_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '+ (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) - T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100 - T.BASE ' +
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

function CrearAlbaranDesdePedido(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm, ASerieAlbc,
                                        AUsuario: string;
                                  const ARefPrv: string;
                                  AFechaRecepcion: TDateTime;
                                  AIdPvTemporada: Integer;
                                  out ANumAlbc: string;
                                  out AMensaje: string): Boolean;
var
  q: TUniQuery;
  oCeldas: TList<TCeldaARecibir>;
  rCelda: TCeldaARecibir;
begin
  Result   := False;
  ANumAlbc := '';
  AMensaje := '';
  // Construye una celda por linea pendiente del almacen y delega en
  // CrearAlbaranDesdePedidoConCantidades: un unico camino de codigo
  // para el flujo "todo lo pendiente" y el flujo celda a celda del
  // pivote. Antes eran dos funciones gemelas de ~350 lineas cada una.
  oCeldas := TList<TCeldaARecibir>.Create;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT L.LINEA_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
      '       L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) ' +
      '         AS PENDIENTE ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) = :alm ' +
      '   AND L.CANTIDAD_PEDCLIN - ' +
      '       IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0 ' +
      ' ORDER BY L.LINEA_PEDCLIN';
    q.ParamByName('s').AsString   := ASeriePedc;
    q.ParamByName('n').AsString   := ANumPedc;
    q.ParamByName('alm').AsString := ACodigoAlm;
    q.Open;
    while not q.Eof do
    begin
      rCelda.LineaPedido   := q.FieldByName('LINEA_PEDCLIN').AsString;
      rCelda.CodigoSku     :=
        q.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
      rCelda.CodigoAlmacen := ACodigoAlm;
      rCelda.Cantidad      := q.FieldByName('PENDIENTE').AsFloat;
      oCeldas.Add(rCelda);
      q.Next;
    end;
    q.Close;
    if oCeldas.Count = 0 then
      AMensaje := Format(SErrorPedidoCompraSinPendientesAlmacen,
        [ACodigoAlm, ASeriePedc, ANumPedc])
    else
      Result := CrearAlbaranDesdePedidoConCantidades(AConn, ASeriePedc,
        ANumPedc, ACodigoAlm, ASerieAlbc, AUsuario, ARefPrv,
        AFechaRecepcion, AIdPvTemporada, oCeldas.ToArray, ANumAlbc,
        AMensaje);
  finally
    FreeAndNil(q);
    FreeAndNil(oCeldas);
  end;
end;

function CalcularTotalCeldasRecepcion(
  const ACeldas: TArray<TCeldaARecibir>;
  const ACodigoAlmacen: string): Double;
var
  Celda: TCeldaARecibir;
begin
  Result := 0;
  for Celda in ACeldas do
  begin
    if SameText(Celda.CodigoAlmacen, ACodigoAlmacen) and
       (Celda.Cantidad > 0) then
      Result := Result + Celda.Cantidad;
  end;
end;

function ValidarSolicitudRecepcionCeldas(
  const ASeriePedido, ANumeroPedido, ACodigoAlmacen: string;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Result := False;
  if Trim(ACodigoAlmacen) = '' then
    AMensaje := SErrorAlmacenPedidoCompraNoSeleccionado
  else if CalcularTotalCeldasRecepcion(
    ACeldas, ACodigoAlmacen) <= 0 then
    AMensaje := Format(
      SErrorPedidoCompraSinCantidadesRecibir,
      [ACodigoAlmacen, ASeriePedido, ANumeroPedido])
  else
    Result := True;
end;

function ReservarNumeroAlbaranCompra(
  AConexion: TUniConnection;
  const AUsuario: string;
  out ANumeroAlbaran, AMensaje: string): Boolean;
begin
  ANumeroAlbaran := ObtenerSiguienteContador(
    AConexion, 'AB', AUsuario);
  Result := Trim(ANumeroAlbaran) <> '';
  if not Result then
    AMensaje := SErrorContadorAlbaranCompraNoDisponible;
end;

procedure PrepararInsercionCabeceraAlbaranPedido(
  AQuery: TUniQuery);
begin
  AQuery.SQL.Text :=
    'INSERT INTO fza_albaranes_compra ' +
    '  (NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC, ' +
    '   NUMERO_PED_ALBC, SERIE_PED_ALBC, ' +
    '   CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, ' +
    '   NIF_EMPRESA_ALBC, MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, ' +
    '   DIRECCION1_EMPRESA_ALBC, DIRECCION2_EMPRESA_ALBC, ' +
    '   POBLACION_EMPRESA_ALBC, PROVINCIA_EMPRESA_ALBC, ' +
    '   CODIGO_PAI_EMPRESA_ALBC, NOMBRE_PAI_EMPRESA_ALBC, ' +
    '   CODIGO_POSTAL_EMPRESA_ALBC, ' +
    '   CODIGO_IVA_ALBC, ESIVA_RECARGO_COMPRAS_ALBC, ' +
    '   ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
    '   PORCENTAJE_IVAN_ALBC, PORCENTAJE_IVAR_ALBC, ' +
    '   PORCENTAJE_IVAS_ALBC, PORCENTAJE_IVAE_ALBC, ' +
    '   PORCENTAJE_REN_ALBC, PORCENTAJE_RER_ALBC, ' +
    '   PORCENTAJE_RES_ALBC, PORCENTAJE_REE_ALBC, ' +
    '   PORCENTAJE_RETENCION_ALBC, ' +
    '   CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC, ' +
    '   MOVIL_PRV_ALBC, EMAIL_PRV_ALBC, ' +
    '   DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, ' +
    '   POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC, ' +
    '   CODIGO_POSTAL_PRV_ALBC, ' +
    '   REF_PROVEEDOR_ALBC, FORMA_PAGO_ALBC, ' +
    '   ID_PV_TEMPORADA_ALBC, CODIGO_ALM_ALBC, ' +
    '   TOTAL_BRUTO_ALBC, PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
    '   TOTAL_DTO_COMERCIAL_ALBC, PORCENTAJE_DTO_FINANCIERO_ALBC, ' +
    '   TOTAL_DTO_FINANCIERO_ALBC, TOTAL_BASES_ALBC, ' +
    '   TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC, ' +
    '   CONTADOR_LINEAS_ALBC, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   INSTANTE_MODIF, USUARIO_MODIF) ' +
    'SELECT :nalbc, :salbc, ' +
    '       CASE WHEN :usar_fecha = ''S'' THEN :freal ' +
    '            ELSE IFNULL(P.FECHA_PEDC, CURDATE()) END, ' +
    '       ''ABIERTO'', P.NUMERO_PEDC, P.SERIE_PEDC, ' +
    '       P.CODIGO_EMP_PEDC, P.RAZON_SOCIAL_EMPRESA_PEDC, ' +
    '       P.NIF_EMPRESA_PEDC, P.MOVIL_EMPRESA_PEDC, ' +
    '       P.EMAIL_EMPRESA_PEDC, P.DIRECCION1_EMPRESA_PEDC, ' +
    '       P.DIRECCION2_EMPRESA_PEDC, P.POBLACION_EMPRESA_PEDC, ' +
    '       P.PROVINCIA_EMPRESA_PEDC, P.CODIGO_PAI_EMPRESA_PEDC, ' +
    '       P.NOMBRE_PAI_EMPRESA_PEDC, P.CODIGO_POSTAL_EMPRESA_PEDC, ' +
    '       P.CODIGO_IVA_PEDC, ' +
    '       IFNULL(P.ESIVA_RECARGO_COMPRAS_PEDC, ''N''), ' +
    '       IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N''), ' +
    '       P.PORCENTAJE_IVAN_PEDC, P.PORCENTAJE_IVAR_PEDC, ' +
    '       P.PORCENTAJE_IVAS_PEDC, P.PORCENTAJE_IVAE_PEDC, ' +
    '       P.PORCENTAJE_REN_PEDC, P.PORCENTAJE_RER_PEDC, ' +
    '       P.PORCENTAJE_RES_PEDC, P.PORCENTAJE_REE_PEDC, ' +
    '       P.PORCENTAJE_RETENCION_PEDC, ' +
    '       P.CODIGO_PRV_PEDC, P.RAZON_SOCIAL_PRV_PEDC, ' +
    '       P.NIF_PRV_PEDC, P.MOVIL_PRV_PEDC, P.EMAIL_PRV_PEDC, ' +
    '       P.DIRECCION1_PRV_PEDC, P.DIRECCION2_PRV_PEDC, ' +
    '       P.POBLACION_PRV_PEDC, P.PROVINCIA_PRV_PEDC, ' +
    '       P.CODIGO_POSTAL_PRV_PEDC, ' +
    '       IFNULL(NULLIF(:rprv, ''''), P.REF_PROVEEDOR_PEDC), ' +
    '       NULLIF(P.FORMA_PAGO_PEDC, ''''), NULLIF(:pv, 0), :alm, ' +
    '       0, IFNULL(P.PORCENTAJE_DTO_COMERCIAL_PEDC, 0), ' +
    '       0, IFNULL(P.PORCENTAJE_DTO_FINANCIERO_PEDC, 0), ' +
    '       0, 0, 0, 0, ''0'', NOW(), :u, NOW(), :u ' +
    '  FROM fza_pedidos_compra P ' +
    ' WHERE P.SERIE_PEDC = :s AND P.NUMERO_PEDC = :n';
end;

procedure AsignarParametrosCabeceraAlbaranPedido(
  AQuery: TUniQuery;
  const ASeriePedido, ANumeroPedido, ACodigoAlmacen,
    ASerieAlbaran, ANumeroAlbaran, AReferenciaProveedor,
    AUsuario: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer);
begin
  AQuery.ParamByName('nalbc').AsString := ANumeroAlbaran;
  AQuery.ParamByName('salbc').AsString := ASerieAlbaran;
  AQuery.ParamByName('alm').AsString := ACodigoAlmacen;
  AQuery.ParamByName('rprv').AsString := AReferenciaProveedor;
  AQuery.ParamByName('pv').AsInteger := AIdPvTemporada;
  if AFechaRecepcion > 0 then
  begin
    AQuery.ParamByName('usar_fecha').AsString := 'S';
    AQuery.ParamByName('freal').AsDateTime := AFechaRecepcion;
  end
  else
  begin
    AQuery.ParamByName('usar_fecha').AsString := 'N';
    AQuery.ParamByName('freal').Clear;
  end;
  AQuery.ParamByName('s').AsString := ASeriePedido;
  AQuery.ParamByName('n').AsString := ANumeroPedido;
  AQuery.ParamByName('u').AsString := AUsuario;
end;

procedure CrearCabeceraAlbaranPedido(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ACodigoAlmacen,
    ASerieAlbaran, ANumeroAlbaran, AReferenciaProveedor,
    AUsuario: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer);
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConexion;
    PrepararInsercionCabeceraAlbaranPedido(Query);
    AsignarParametrosCabeceraAlbaranPedido(
      Query, ASeriePedido, ANumeroPedido, ACodigoAlmacen,
      ASerieAlbaran, ANumeroAlbaran, AReferenciaProveedor,
      AUsuario, AFechaRecepcion, AIdPvTemporada);
    Query.ExecSQL;
  finally
    FreeAndNil(Query);
  end;
end;

procedure PrepararConsultaLineaPedidoRecepcion(
  AQuery: TUniQuery);
begin
  AQuery.SQL.Text :=
    'SELECT L.CODIGO_ART_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
    '       L.REF_PRV_PEDCLIN, L.ID_AC_PIVOT_PEDCLIN, ' +
    '       L.CODIGO_FAM_PEDCLIN, L.NOMBRE_FAM_PEDCLIN, ' +
    '       L.DESCRIPCION_ARTICULO_PEDCLIN, ' +
    '       L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
    '       L.TIPO_IVA_ARTICULO_PEDCLIN, ' +
    '       L.PORCENTAJE_IVA_PEDCLIN, ' +
    '       IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') ' +
    '         AS EXENTO_INTRACOM, ' +
    '       L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
    '       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
    '       L.CANTIDAD_PEDCLIN, L.CANTIDAD_RECIBIDA_PEDCLIN ' +
    '  FROM fza_pedidos_compra_lineas L ' +
    '  JOIN fza_pedidos_compra P ' +
    '    ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
    '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
    ' WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
    '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
    '   AND L.LINEA_PEDCLIN = :l';
end;

function CargarLineaPedidoRecepcion(
  AQuery: TUniQuery;
  const ASeriePedido, ANumeroPedido,
    ALineaPedido: string): Boolean;
begin
  AQuery.Close;
  AQuery.ParamByName('s').AsString := ASeriePedido;
  AQuery.ParamByName('n').AsString := ANumeroPedido;
  AQuery.ParamByName('l').AsString := ALineaPedido;
  AQuery.Open;
  Result := not AQuery.Eof;
end;

function CalcularCantidadRecepcion(
  AQuery: TUniQuery;
  APendientePorLinea: TDictionary<string, Double>;
  const ACelda: TCeldaARecibir): Double;
var
  Pendiente: Double;
begin
  if not APendientePorLinea.TryGetValue(
    ACelda.LineaPedido, Pendiente) then
  begin
    Pendiente :=
      AQuery.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
      AQuery.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
    if Pendiente < 0 then
      Pendiente := 0;
  end;
  Result := ACelda.Cantidad;
  if Result > Pendiente then
    Result := Pendiente;
  APendientePorLinea.AddOrSetValue(
    ACelda.LineaPedido, Pendiente - Result);
end;

procedure PrepararInsercionLineaAlbaranPedido(
  AQuery: TUniQuery);
begin
  AQuery.SQL.Text :=
    'INSERT INTO fza_albaranes_compra_lineas ' +
    '  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
    '   NUMERO_PEDC_ALBCLIN, SERIE_PEDC_ALBCLIN, LINEA_PEDC_ALBCLIN, ' +
    '   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN, ' +
    '   ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, ' +
    '   NOMBRE_FAM_ALBCLIN, DESCRIPCION_ARTICULO_ALBCLIN, ' +
    '   TIPO_CANTIDAD_ARTICULO_ALBCLIN, CANTIDAD_ALBCLIN, ' +
    '   TOTAL_UNIDADES_ALBCLIN, TIPO_IVA_ARTICULO_ALBCLIN, ' +
    '   PORCENTAJE_IVA_ALBCLIN, ' +
    '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
    '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
    '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
    '   ESFACTURADA_ALBCLIN, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:nalbc, :salbc, :lalbc, :npedc, :spedc, :lpedc, ' +
    '        :art, :sku, :refprv, :acpivot, :fam, :nfam, ' +
    '        :desc, :tipcant, :cant, :cant, :tiva, :piva, ' +
    '        :pre, :preciva, :cant * :pre, :alm, ''N'', ' +
    '        NOW(), :u, NOW(), :u)';
end;

procedure AsignarParametrosLineaAlbaranPedido(
  AQueryDestino, AQueryOrigen: TUniQuery;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
    ANumeroAlbaran, ALineaAlbaran, ALineaPedido,
    ACodigoSku, ACodigoAlmacen, AUsuario: string;
  ACantidad: Double);
begin
  AQueryDestino.ParamByName('nalbc').AsString := ANumeroAlbaran;
  AQueryDestino.ParamByName('salbc').AsString := ASerieAlbaran;
  AQueryDestino.ParamByName('lalbc').AsString := ALineaAlbaran;
  AQueryDestino.ParamByName('npedc').AsString := ANumeroPedido;
  AQueryDestino.ParamByName('spedc').AsString := ASeriePedido;
  AQueryDestino.ParamByName('lpedc').AsString := ALineaPedido;
  AQueryDestino.ParamByName('art').AsString :=
    AQueryOrigen.FieldByName('CODIGO_ART_PEDCLIN').AsString;
  AQueryDestino.ParamByName('sku').AsString := ACodigoSku;
  AQueryDestino.ParamByName('refprv').AsString :=
    AQueryOrigen.FieldByName('REF_PRV_PEDCLIN').AsString;
  if AQueryOrigen.FieldByName('ID_AC_PIVOT_PEDCLIN').IsNull then
    AQueryDestino.ParamByName('acpivot').Clear
  else
    AQueryDestino.ParamByName('acpivot').AsInteger :=
      AQueryOrigen.FieldByName('ID_AC_PIVOT_PEDCLIN').AsInteger;
  AQueryDestino.ParamByName('fam').AsString :=
    AQueryOrigen.FieldByName('CODIGO_FAM_PEDCLIN').AsString;
  AQueryDestino.ParamByName('nfam').AsString :=
    AQueryOrigen.FieldByName('NOMBRE_FAM_PEDCLIN').AsString;
  AQueryDestino.ParamByName('desc').AsString :=
    AQueryOrigen.FieldByName(
      'DESCRIPCION_ARTICULO_PEDCLIN').AsString;
  AQueryDestino.ParamByName('tipcant').AsString :=
    AQueryOrigen.FieldByName(
      'TIPO_CANTIDAD_ARTICULO_PEDCLIN').AsString;
  AQueryDestino.ParamByName('cant').AsFloat := ACantidad;
  if AQueryOrigen.FieldByName('EXENTO_INTRACOM').AsString = 'S' then
  begin
    AQueryDestino.ParamByName('tiva').AsString := 'E';
    AQueryDestino.ParamByName('piva').AsFloat := 0;
  end
  else
  begin
    AQueryDestino.ParamByName('tiva').AsString :=
      AQueryOrigen.FieldByName(
        'TIPO_IVA_ARTICULO_PEDCLIN').AsString;
    AQueryDestino.ParamByName('piva').AsFloat :=
      AQueryOrigen.FieldByName('PORCENTAJE_IVA_PEDCLIN').AsFloat;
  end;
  AQueryDestino.ParamByName('pre').AsFloat :=
    AQueryOrigen.FieldByName(
      'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
  AQueryDestino.ParamByName('preciva').AsFloat :=
    AQueryOrigen.FieldByName(
      'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN').AsFloat;
  AQueryDestino.ParamByName('alm').AsString := ACodigoAlmacen;
  AQueryDestino.ParamByName('u').AsString := AUsuario;
end;

procedure InsertarLineaAlbaranPedido(
  AQueryDestino, AQueryOrigen: TUniQuery;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
    ANumeroAlbaran, ALineaAlbaran, ALineaPedido,
    ACodigoSku, ACodigoAlmacen, AUsuario: string;
  ACantidad: Double);
begin
  AQueryDestino.Close;
  PrepararInsercionLineaAlbaranPedido(AQueryDestino);
  AsignarParametrosLineaAlbaranPedido(
    AQueryDestino, AQueryOrigen, ASeriePedido, ANumeroPedido,
    ASerieAlbaran, ANumeroAlbaran, ALineaAlbaran,
    ALineaPedido, ACodigoSku, ACodigoAlmacen, AUsuario,
    ACantidad);
  AQueryDestino.ExecSQL;
end;

procedure ActualizarCantidadRecibidaPedido(
  AQuery: TUniQuery;
  const ASeriePedido, ANumeroPedido, ALineaPedido,
    AUsuario: string;
  ACantidad: Double);
begin
  AQuery.Close;
  AQuery.SQL.Text :=
    'UPDATE fza_pedidos_compra_lineas ' +
    '   SET CANTIDAD_RECIBIDA_PEDCLIN = ' +
    '         IFNULL(CANTIDAD_RECIBIDA_PEDCLIN, 0) + :qty, ' +
    '       USUARIO_MODIF = :u, INSTANTE_MODIF = NOW() ' +
    ' WHERE SERIE_PEDC_PEDCLIN = :s ' +
    '   AND NUMERO_PEDC_PEDCLIN = :n ' +
    '   AND LINEA_PEDCLIN = :l';
  AQuery.ParamByName('qty').AsFloat := ACantidad;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ParamByName('s').AsString := ASeriePedido;
  AQuery.ParamByName('n').AsString := ANumeroPedido;
  AQuery.ParamByName('l').AsString := ALineaPedido;
  AQuery.ExecSQL;
end;

function ProcesarCeldasRecepcionPedido(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ACodigoAlmacen,
    ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
  const ACeldas: TArray<TCeldaARecibir>;
  var ALineaAlbaran: Integer): Integer;
var
  QueryOrigen: TUniQuery;
  QueryDestino: TUniQuery;
  PendientePorLinea: TDictionary<string, Double>;
  Celda: TCeldaARecibir;
  Cantidad: Double;
  LineaAlbaran: string;
begin
  Result := 0;
  QueryOrigen := TUniQuery.Create(nil);
  QueryDestino := TUniQuery.Create(nil);
  PendientePorLinea := TDictionary<string, Double>.Create;
  try
    QueryOrigen.Connection := AConexion;
    QueryDestino.Connection := AConexion;
    PrepararConsultaLineaPedidoRecepcion(QueryOrigen);
    for Celda in ACeldas do
    begin
      if SameText(Celda.CodigoAlmacen, ACodigoAlmacen) and
         (Celda.Cantidad > 0) and
         CargarLineaPedidoRecepcion(
           QueryOrigen, ASeriePedido, ANumeroPedido,
           Celda.LineaPedido) then
      begin
        Cantidad := CalcularCantidadRecepcion(
          QueryOrigen, PendientePorLinea, Celda);
        if Cantidad > 0 then
        begin
          Inc(ALineaAlbaran, 10);
          LineaAlbaran := Format('%.4d', [ALineaAlbaran]);
          InsertarLineaAlbaranPedido(
            QueryDestino, QueryOrigen, ASeriePedido,
            ANumeroPedido, ASerieAlbaran, ANumeroAlbaran,
            LineaAlbaran, Celda.LineaPedido, Celda.CodigoSku,
            ACodigoAlmacen, AUsuario, Cantidad);
          ActualizarCantidadRecibidaPedido(
            QueryDestino, ASeriePedido, ANumeroPedido,
            Celda.LineaPedido, AUsuario, Cantidad);
          Inc(Result);
        end;
      end;
    end;
  finally
    FreeAndNil(QueryOrigen);
    FreeAndNil(QueryDestino);
    FreeAndNil(PendientePorLinea);
  end;
end;

procedure BorrarCabeceraAlbaranCompra(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran: string);
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConexion;
    Query.SQL.Text :=
      'DELETE FROM fza_albaranes_compra ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    Query.ParamByName('s').AsString := ASerieAlbaran;
    Query.ParamByName('n').AsString := ANumeroAlbaran;
    Query.ExecSQL;
  finally
    FreeAndNil(Query);
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
      AConexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  CerrarAlbaranCompra(
    AConexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  GenerarPdteRecibirDesdePedido(
    AConexion, ASeriePedido, ANumeroPedido, AUsuario);
  RecalcularEstadoPedido(
    AConexion, ASeriePedido, ANumeroPedido, AUsuario);
  AplicarTemporadaArticulosAlbaran(
    AConexion, ASerieAlbaran, ANumeroAlbaran,
    AUsuario, AIdPvTemporada);
end;

function CrearAlbaranDesdePedidoConCantidades(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm, ASerieAlbc,
                                        AUsuario: string;
                                  const ARefPrv: string;
                                  AFechaRecepcion: TDateTime;
                                  AIdPvTemporada: Integer;
                                  const ACeldas: TArray<TCeldaARecibir>;
                                  out ANumAlbc: string;
                                  out AMensaje: string): Boolean;
var
  iLineaAlbc: Integer;
  iLineasCreadas: Integer;
begin
  Result := False;
  AMensaje := '';
  ANumAlbc := '';
  if ValidarSolicitudRecepcionCeldas(
    ASeriePedc, ANumPedc, ACodigoAlm,
    ACeldas, AMensaje) and
    ReservarNumeroAlbaranCompra(
      AConn, AUsuario, ANumAlbc, AMensaje) then
  begin
    CrearCabeceraAlbaranPedido(
      AConn, ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbc, ANumAlbc, ARefPrv, AUsuario,
      AFechaRecepcion, AIdPvTemporada);
    iLineaAlbc := 0;
    iLineasCreadas := ProcesarCeldasRecepcionPedido(
      AConn, ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbc, ANumAlbc, AUsuario, ACeldas,
      iLineaAlbc);
    if iLineasCreadas = 0 then
    begin
      AMensaje := SErrorCrearLineasAlbaranCompra;
      BorrarCabeceraAlbaranCompra(
        AConn, ASerieAlbc, ANumAlbc);
    end
    else
    begin
      FinalizarAlbaranCreado(
        AConn, ASeriePedc, ANumPedc, ASerieAlbc,
        ANumAlbc, AUsuario, AIdPvTemporada);
      AMensaje := Format(
        SInfoAlbaranCompraCreado,
        [ASerieAlbc, ANumAlbc, iLineasCreadas]);
      Result := True;
    end;
  end;
end;

function CalcularPendienteTotal(AConn: TUniConnection;
                                 const ASeriePedc, ANumPedc: string): Double;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(SUM(CANTIDAD_PEDCLIN - ' +
      '              IFNULL(CANTIDAD_RECIBIDA_PEDCLIN,0)),0) AS PEND ' +
      '  FROM fza_pedidos_compra_lineas ' +
      ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND NUMERO_PEDC_PEDCLIN = :n';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    Result := q.FieldByName('PEND').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;

// Mayor numero de linea (LINEA_ALBCLIN) ya presente en un albaran de
// compra; 0 si no tiene lineas. Sirve para continuar la numeracion al
// incorporar lineas a un albaran existente.
function MaxLineaAlbaranCompra(AConn: TUniConnection;
                               const ASerieAlbc, ANumAlbc: string): Integer;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(MAX(CAST(LINEA_ALBCLIN AS UNSIGNED)),0) AS MAXLIN ' +
      '  FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
      '   AND NUMERO_ALBC_ALBCLIN = :n';
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ParamByName('n').AsString := ANumAlbc;
    q.Open;
    Result := q.FieldByName('MAXLIN').AsInteger;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;

// Cierre comun tras anadir lineas a un albaran existente: recalcula
// totales sobre todas las lineas, revierte los movimientos previos
// (no-op si no hay) y los regenera para todas las lineas (asi entra el
// stock de las nuevas sin chocar con el guard anti-doble-generacion),
// deja el albaran CERRADO, resincroniza pendientes / estado del pedido y
// aplica la temporada si procede.
procedure RegenerarMovimientosYCerrarAlbaranCompra(AConn: TUniConnection;
                                  const ASerieAlbc, ANumAlbc,
                                        ASeriePedc, ANumPedc,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer);
var
  qIns: TUniQuery;
begin
  // 1. Recalcular totales del albaran sobre TODAS sus lineas.
  RecalcularTotalesAlbaranCompra(AConn, ASerieAlbc, ANumAlbc, AUsuario);
  // 2. Revertir movimientos previos (no-op si no hay) y regenerarlos
  //    para TODAS las lineas (viejas + nuevas).
  inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
    AConn, ASerieAlbc, ANumAlbc, AUsuario);
  inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
    AConn, ASerieAlbc, ANumAlbc, AUsuario);
  // 3. Asegurar estado CERRADO.
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := AConn;
    qIns.SQL.Text :=
      'UPDATE fza_albaranes_compra ' +
      '   SET ESTADO_ALBC    = ''CERRADO'', ' +
      '       USUARIO_MODIF  = :u, ' +
      '       INSTANTE_MODIF = NOW() ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    qIns.ParamByName('s').AsString := ASerieAlbc;
    qIns.ParamByName('n').AsString := ANumAlbc;
    qIns.ParamByName('u').AsString := AUsuario;
    qIns.ExecSQL;
  finally
    FreeAndNil(qIns);
  end;
  // 4. Resincronizar pendientes + recalcular estado del pedido.
  GenerarPdteRecibirDesdePedido(AConn, ASeriePedc, ANumPedc, AUsuario);
  RecalcularEstadoPedido(AConn, ASeriePedc, ANumPedc, AUsuario);
  // 5. Temporada explicita del modal (si la hay).
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
    qIns := TUniQuery.Create(nil);
    try
      qIns.Connection := AConn;
      qIns.SQL.Text :=
        'INSERT INTO fza_articulos_propiedades ' +
        '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
        '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'SELECT DISTINCT L.CODIGO_ART_ALBCLIN, ''TEMPORADA'', :pv, ' +
        '       NULL, NOW(), :u ' +
        '  FROM fza_albaranes_compra_lineas L ' +
        ' WHERE L.SERIE_ALBC_ALBCLIN  = :s ' +
        '   AND L.NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND L.CODIGO_ART_ALBCLIN IS NOT NULL ' +
        '   AND L.CODIGO_ART_ALBCLIN <> '''' ' +
        'ON DUPLICATE KEY UPDATE ID_PV_ARTPROP = :pv';
      qIns.ParamByName('pv').AsInteger := AIdPvTemporada;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ParamByName('s').AsString   := ASerieAlbc;
      qIns.ParamByName('n').AsString   := ANumAlbc;
      qIns.ExecSQL;
    finally
      FreeAndNil(qIns);
    end;
  end;
end;

function IncorporarAlbaranDesdePedido(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm,
                                        ASerieAlbcDestino, ANumAlbcDestino,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer;
                                  out AMensaje: string): Boolean;
var
  q, qIns: TUniQuery;
  iCount, iLineaAlbc: Integer;
  sLineaAlbc: string;
begin
  Result   := False;
  AMensaje := '';
  if Trim(ACodigoAlm) = '' then
  begin
    AMensaje := SErrorAlmacenPedidoCompraNoSeleccionado;
    Exit;
  end;
  if (Trim(ASerieAlbcDestino) = '') or (Trim(ANumAlbcDestino) = '') then
  begin
    AMensaje := SErrorAlbaranCompraDestinoNoSeleccionado;
    Exit;
  end;
  // 1. Comprobar pendientes para ese almacen.
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) = :alm ' +
      '   AND L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0';
    q.ParamByName('s').AsString   := ASeriePedc;
    q.ParamByName('n').AsString   := ANumPedc;
    q.ParamByName('alm').AsString := ACodigoAlm;
    q.Open;
    iCount := q.FieldByName('N').AsInteger;
    q.Close;
    if iCount = 0 then
    begin
      AMensaje := Format(SErrorPedidoCompraSinPendientesAlmacen,
        [ACodigoAlm, ASeriePedc, ANumPedc]);
      Exit;
    end;
  finally
    FreeAndNil(q);
  end;
  // 2. Numeracion continua desde el maximo ya existente en el albaran.
  iLineaAlbc := MaxLineaAlbaranCompra(AConn, ASerieAlbcDestino, ANumAlbcDestino);
  // 3. Insertar las lineas pendientes en el albaran destino.
  q    := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    q.Connection    := AConn;
    qIns.Connection := AConn;
    q.SQL.Text :=
      'SELECT L.LINEA_PEDCLIN, L.CODIGO_ART_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
      '       L.REF_PRV_PEDCLIN, L.ID_AC_PIVOT_PEDCLIN, ' +
      '       L.CODIGO_FAM_PEDCLIN, L.NOMBRE_FAM_PEDCLIN, ' +
      '       L.DESCRIPCION_ARTICULO_PEDCLIN, ' +
      '       L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
      '       L.TIPO_IVA_ARTICULO_PEDCLIN, L.PORCENTAJE_IVA_PEDCLIN, ' +
      '       IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') AS EXENTO_INTRACOM, ' +
      '       L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
      '       L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) AS PENDIENTE ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) = :alm ' +
      '   AND L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0 ' +
      ' ORDER BY L.LINEA_PEDCLIN';
    q.ParamByName('s').AsString   := ASeriePedc;
    q.ParamByName('n').AsString   := ANumPedc;
    q.ParamByName('alm').AsString := ACodigoAlm;
    q.Open;
    while not q.Eof do
    begin
      Inc(iLineaAlbc, 10);
      sLineaAlbc := Format('%.4d', [iLineaAlbc]);
      qIns.SQL.Text :=
        'INSERT INTO fza_albaranes_compra_lineas ' +
        '  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
        '   NUMERO_PEDC_ALBCLIN, SERIE_PEDC_ALBCLIN, LINEA_PEDC_ALBCLIN, ' +
        '   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN, ' +
        '   ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
        '   DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN, ' +
        '   CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN, ' +
        '   TIPO_IVA_ARTICULO_ALBCLIN, ' +
        '   PORCENTAJE_IVA_ALBCLIN, ' +
        '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
        '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
        '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ESFACTURADA_ALBCLIN, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:nalbc, :salbc, :lalbc, :npedc, :spedc, :lpedc, ' +
        '        :art, :sku, :refprv, :acpivot, :fam, :nfam, ' +
        '        :desc, :tipcant, ' +
        '        :cant, :cant, :tiva, :piva, :pre, :preciva, ' +
        '        :cant * :pre, :alm, ''N'', ' +
        '        NOW(), :u, NOW(), :u)';
      qIns.ParamByName('nalbc').AsString  := ANumAlbcDestino;
      qIns.ParamByName('salbc').AsString  := ASerieAlbcDestino;
      qIns.ParamByName('lalbc').AsString  := sLineaAlbc;
      qIns.ParamByName('npedc').AsString  := ANumPedc;
      qIns.ParamByName('spedc').AsString  := ASeriePedc;
      qIns.ParamByName('lpedc').AsString  := q.FieldByName('LINEA_PEDCLIN').AsString;
      qIns.ParamByName('art').AsString    := q.FieldByName('CODIGO_ART_PEDCLIN').AsString;
      qIns.ParamByName('sku').AsString    := q.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
      qIns.ParamByName('refprv').AsString := q.FieldByName('REF_PRV_PEDCLIN').AsString;
      if q.FieldByName('ID_AC_PIVOT_PEDCLIN').IsNull then
        qIns.ParamByName('acpivot').Clear
      else
        qIns.ParamByName('acpivot').AsInteger :=
          q.FieldByName('ID_AC_PIVOT_PEDCLIN').AsInteger;
      qIns.ParamByName('fam').AsString    := q.FieldByName('CODIGO_FAM_PEDCLIN').AsString;
      qIns.ParamByName('nfam').AsString   := q.FieldByName('NOMBRE_FAM_PEDCLIN').AsString;
      qIns.ParamByName('desc').AsString   :=
        q.FieldByName('DESCRIPCION_ARTICULO_PEDCLIN').AsString;
      qIns.ParamByName('tipcant').AsString :=
        q.FieldByName('TIPO_CANTIDAD_ARTICULO_PEDCLIN').AsString;
      qIns.ParamByName('cant').AsFloat    := q.FieldByName('PENDIENTE').AsFloat;
      if q.FieldByName('EXENTO_INTRACOM').AsString = 'S' then
      begin
        qIns.ParamByName('tiva').AsString := 'E';
        qIns.ParamByName('piva').AsFloat := 0;
      end
      else
      begin
        qIns.ParamByName('tiva').AsString :=
          q.FieldByName('TIPO_IVA_ARTICULO_PEDCLIN').AsString;
        qIns.ParamByName('piva').AsFloat :=
          q.FieldByName('PORCENTAJE_IVA_PEDCLIN').AsFloat;
      end;
      qIns.ParamByName('pre').AsFloat     :=
        q.FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
      qIns.ParamByName('preciva').AsFloat :=
        q.FieldByName('PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN').AsFloat;
      qIns.ParamByName('alm').AsString    := ACodigoAlm;
      qIns.ParamByName('u').AsString      := AUsuario;
      qIns.ExecSQL;
      // Aumentar CANTIDAD_RECIBIDA del pedido por la cantidad albaraneada.
      qIns.SQL.Text :=
        'UPDATE fza_pedidos_compra_lineas ' +
        '   SET CANTIDAD_RECIBIDA_PEDCLIN = ' +
        '         IFNULL(CANTIDAD_RECIBIDA_PEDCLIN,0) + :qty, ' +
        '       USUARIO_MODIF  = :u, ' +
        '       INSTANTE_MODIF = NOW() ' +
        ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
        '   AND NUMERO_PEDC_PEDCLIN = :n ' +
        '   AND LINEA_PEDCLIN       = :l';
      qIns.ParamByName('qty').AsFloat  := q.FieldByName('PENDIENTE').AsFloat;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ParamByName('s').AsString   := ASeriePedc;
      qIns.ParamByName('n').AsString   := ANumPedc;
      qIns.ParamByName('l').AsString   := q.FieldByName('LINEA_PEDCLIN').AsString;
      qIns.ExecSQL;
      q.Next;
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(qIns);
  end;
  // 4. Totales + movimientos (revert/regenera) + CERRADO + pendientes.
  RegenerarMovimientosYCerrarAlbaranCompra(AConn,
    ASerieAlbcDestino, ANumAlbcDestino, ASeriePedc, ANumPedc,
    AUsuario, AIdPvTemporada);
  AMensaje := Format(SInfoLineasIncorporadasAlbaranCompra,
                     [ASerieAlbcDestino, ANumAlbcDestino]);
  Result := True;
end;

function IncorporarAlbaranDesdePedidoConCantidades(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        ACodigoAlm,
                                        ASerieAlbcDestino, ANumAlbcDestino,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer;
                                  const ACeldas: TArray<TCeldaARecibir>;
                                  out AMensaje: string): Boolean;
var
  q, qIns: TUniQuery;
  c: TCeldaARecibir;
  iLineaAlbc, iInsertadas: Integer;
  sLineaAlbc: string;
  rTotalCeldas: Double;
  dPdteLinea: TDictionary<string,Double>;
  rCantidad, rPdteLin: Double;
begin
  Result   := False;
  AMensaje := '';
  if Trim(ACodigoAlm) = '' then
  begin
    AMensaje := SErrorAlmacenPedidoCompraNoSeleccionado;
    Exit;
  end;
  if (Trim(ASerieAlbcDestino) = '') or (Trim(ANumAlbcDestino) = '') then
  begin
    AMensaje := SErrorAlbaranCompraDestinoNoSeleccionado;
    Exit;
  end;
  // Filtra y suma celdas validas (cantidad > 0, almacen coincide).
  rTotalCeldas := 0;
  for c in ACeldas do
    if SameText(c.CodigoAlmacen, ACodigoAlm) and (c.Cantidad > 0) then
      rTotalCeldas := rTotalCeldas + c.Cantidad;
  if rTotalCeldas <= 0 then
  begin
    AMensaje := Format(SErrorPedidoCompraSinCantidadesRecibir,
      [ACodigoAlm, ASeriePedc, ANumPedc]);
    Exit;
  end;
  // Numeracion continua desde el maximo ya existente en el albaran.
  iLineaAlbc  := MaxLineaAlbaranCompra(AConn, ASerieAlbcDestino, ANumAlbcDestino);
  iInsertadas := 0;
  q    := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  dPdteLinea := TDictionary<string,Double>.Create;
  try
    q.Connection    := AConn;
    qIns.Connection := AConn;
    for c in ACeldas do
    begin
      if not SameText(c.CodigoAlmacen, ACodigoAlm) then Continue;
      if c.Cantidad <= 0 then Continue;
      // Leer datos de la linea origen del pedido.
      q.Close;
      q.SQL.Text :=
        'SELECT L.CODIGO_ART_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
        '       L.REF_PRV_PEDCLIN, L.ID_AC_PIVOT_PEDCLIN, ' +
        '       L.CODIGO_FAM_PEDCLIN, L.NOMBRE_FAM_PEDCLIN, ' +
        '       L.DESCRIPCION_ARTICULO_PEDCLIN, ' +
        '       L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
        '       L.TIPO_IVA_ARTICULO_PEDCLIN, L.PORCENTAJE_IVA_PEDCLIN, ' +
        '       IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') AS EXENTO_INTRACOM, ' +
        '       L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
        '       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
        '       L.CANTIDAD_PEDCLIN, L.CANTIDAD_RECIBIDA_PEDCLIN ' +
        '  FROM fza_pedidos_compra_lineas L ' +
        '  JOIN fza_pedidos_compra P ' +
        '    ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
        '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
        ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
        '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
        '   AND L.LINEA_PEDCLIN       = :l';
      q.ParamByName('s').AsString := ASeriePedc;
      q.ParamByName('n').AsString := ANumPedc;
      q.ParamByName('l').AsString := c.LineaPedido;
      q.Open;
      if q.Eof then Continue;
      // Tope de seguridad: no recibir mas que el pendiente real de la
      // linea (CANTIDAD - RECIBIDA). El dict reparte el pendiente entre
      // varias celdas de la misma linea (una por talla en el pivote).
      if not dPdteLinea.TryGetValue(c.LineaPedido, rPdteLin) then
      begin
        rPdteLin := q.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
                    q.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
        if rPdteLin < 0 then
          rPdteLin := 0;
      end;
      rCantidad := c.Cantidad;
      if rCantidad > rPdteLin then
        rCantidad := rPdteLin;
      dPdteLinea.AddOrSetValue(c.LineaPedido, rPdteLin - rCantidad);
      if rCantidad <= 0 then
      begin
        q.Close;
        Continue;
      end;
      Inc(iLineaAlbc, 10);
      sLineaAlbc := Format('%.4d', [iLineaAlbc]);
      qIns.Close;
      qIns.SQL.Text :=
        'INSERT INTO fza_albaranes_compra_lineas ' +
        '  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
        '   NUMERO_PEDC_ALBCLIN, SERIE_PEDC_ALBCLIN, LINEA_PEDC_ALBCLIN, ' +
        '   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN, ' +
        '   ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
        '   DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN, ' +
        '   CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN, ' +
        '   TIPO_IVA_ARTICULO_ALBCLIN, ' +
        '   PORCENTAJE_IVA_ALBCLIN, ' +
        '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
        '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
        '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ESFACTURADA_ALBCLIN, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:nalbc, :salbc, :lalbc, :npedc, :spedc, :lpedc, ' +
        '        :art, :sku, :refprv, :acpivot, :fam, :nfam, ' +
        '        :desc, :tipcant, ' +
        '        :cant, :cant, :tiva, :piva, :pre, :preciva, ' +
        '        :cant * :pre, :alm, ''N'', ' +
        '        NOW(), :u, NOW(), :u)';
      qIns.ParamByName('nalbc').AsString  := ANumAlbcDestino;
      qIns.ParamByName('salbc').AsString  := ASerieAlbcDestino;
      qIns.ParamByName('lalbc').AsString  := sLineaAlbc;
      qIns.ParamByName('npedc').AsString  := ANumPedc;
      qIns.ParamByName('spedc').AsString  := ASeriePedc;
      qIns.ParamByName('lpedc').AsString  := c.LineaPedido;
      qIns.ParamByName('art').AsString    := q.FieldByName('CODIGO_ART_PEDCLIN').AsString;
      qIns.ParamByName('sku').AsString    := c.CodigoSku;
      qIns.ParamByName('refprv').AsString := q.FieldByName('REF_PRV_PEDCLIN').AsString;
      if q.FieldByName('ID_AC_PIVOT_PEDCLIN').IsNull then
        qIns.ParamByName('acpivot').Clear
      else
        qIns.ParamByName('acpivot').AsInteger :=
          q.FieldByName('ID_AC_PIVOT_PEDCLIN').AsInteger;
      qIns.ParamByName('fam').AsString  := q.FieldByName('CODIGO_FAM_PEDCLIN').AsString;
      qIns.ParamByName('nfam').AsString := q.FieldByName('NOMBRE_FAM_PEDCLIN').AsString;
      qIns.ParamByName('desc').AsString :=
        q.FieldByName('DESCRIPCION_ARTICULO_PEDCLIN').AsString;
      qIns.ParamByName('tipcant').AsString :=
        q.FieldByName('TIPO_CANTIDAD_ARTICULO_PEDCLIN').AsString;
      qIns.ParamByName('cant').AsFloat := rCantidad;
      if q.FieldByName('EXENTO_INTRACOM').AsString = 'S' then
      begin
        qIns.ParamByName('tiva').AsString := 'E';
        qIns.ParamByName('piva').AsFloat := 0;
      end
      else
      begin
        qIns.ParamByName('tiva').AsString :=
          q.FieldByName('TIPO_IVA_ARTICULO_PEDCLIN').AsString;
        qIns.ParamByName('piva').AsFloat :=
          q.FieldByName('PORCENTAJE_IVA_PEDCLIN').AsFloat;
      end;
      qIns.ParamByName('pre').AsFloat :=
        q.FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
      qIns.ParamByName('preciva').AsFloat :=
        q.FieldByName('PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN').AsFloat;
      qIns.ParamByName('alm').AsString := ACodigoAlm;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ExecSQL;
      q.Close;
      Inc(iInsertadas);
      // UPDATE pedido linea: aumentar CANTIDAD_RECIBIDA.
      qIns.Close;
      qIns.SQL.Text :=
        'UPDATE fza_pedidos_compra_lineas ' +
        '   SET CANTIDAD_RECIBIDA_PEDCLIN = ' +
        '         IFNULL(CANTIDAD_RECIBIDA_PEDCLIN,0) + :qty, ' +
        '       USUARIO_MODIF  = :u, ' +
        '       INSTANTE_MODIF = NOW() ' +
        ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
        '   AND NUMERO_PEDC_PEDCLIN = :n ' +
        '   AND LINEA_PEDCLIN       = :l';
      qIns.ParamByName('qty').AsFloat := rCantidad;
      qIns.ParamByName('u').AsString  := AUsuario;
      qIns.ParamByName('s').AsString  := ASeriePedc;
      qIns.ParamByName('n').AsString  := ANumPedc;
      qIns.ParamByName('l').AsString  := c.LineaPedido;
      qIns.ExecSQL;
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(qIns);
    FreeAndNil(dPdteLinea);
  end;
  if iInsertadas = 0 then
  begin
    AMensaje := SErrorIncorporarLineasAlbaranCompra;
    Exit;
  end;
  RegenerarMovimientosYCerrarAlbaranCompra(AConn,
    ASerieAlbcDestino, ANumAlbcDestino, ASeriePedc, ANumPedc,
    AUsuario, AIdPvTemporada);
  AMensaje := Format(SInfoLineasIncorporadasAlbaranCompraConCantidad,
                     [ASerieAlbcDestino, ANumAlbcDestino, iInsertadas]);
  Result := True;
end;

end.
