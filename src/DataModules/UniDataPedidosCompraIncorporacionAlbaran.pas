{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraIncorporacionAlbaran                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Incorporación de pedidos en albaranes de compra existentes.             }
{******************************************************************************}
unit UniDataPedidosCompraIncorporacionAlbaran;

interface

uses
  Uni, inLibGridPivoteCompraTipos, inLibPedidosCompraIntf;

function CrearIncorporacionAlbaranPedidoCompraUniDAC(
  AConexion: TUniConnection): IIncorporacionAlbaranPedidoCompra;
function IncorporarAlbaranDesdePedidoInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
function IncorporarAlbaranDesdePedidoConCantidadesInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, inLibMsgCompras,
  UniDataPedidosCompraAlbaranComun;

type
  TIncorporacionAlbaranPedidoCompraUniDAC = class(
    TInterfacedObject, IIncorporacionAlbaranPedidoCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function IncorporarAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
      AIdPvTemporada: Integer;
      out AMensaje: string): Boolean;
    function IncorporarAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out AMensaje: string): Boolean;
  end;

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

function IncorporarAlbaranDesdePedidoInterno(AConn: TUniConnection;
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
  bValido: Boolean;
begin
  Result   := False;
  AMensaje := '';
  bValido := Trim(ACodigoAlm) <> '';
  if not bValido then
    AMensaje := SErrorAlmacenPedidoCompraNoSeleccionado;
  if bValido then
  begin
    bValido := (Trim(ASerieAlbcDestino) <> '') and
      (Trim(ANumAlbcDestino) <> '');
    if not bValido then
      AMensaje := SErrorAlbaranCompraDestinoNoSeleccionado;
  end;
  if bValido then
  begin
    // Comprobar pendientes para el almacén seleccionado.
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
        '   AND L.CANTIDAD_PEDCLIN - ' +
        '       IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0';
      q.ParamByName('s').AsString := ASeriePedc;
      q.ParamByName('n').AsString := ANumPedc;
      q.ParamByName('alm').AsString := ACodigoAlm;
      q.Open;
      iCount := q.FieldByName('N').AsInteger;
      q.Close;
      bValido := iCount > 0;
      if not bValido then
        AMensaje := Format(SErrorPedidoCompraSinPendientesAlmacen,
          [ACodigoAlm, ASeriePedc, ANumPedc]);
    finally
      FreeAndNil(q);
    end;
  end;
  if bValido then
  begin
    // Numeración continua desde el máximo existente en el albarán.
    iLineaAlbc := MaxLineaAlbaranCompra(
      AConn, ASerieAlbcDestino, ANumAlbcDestino);
    q := TUniQuery.Create(nil);
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
    RegenerarMovimientosYCerrarAlbaranCompra(AConn,
      ASerieAlbcDestino, ANumAlbcDestino, ASeriePedc, ANumPedc,
      AUsuario, AIdPvTemporada);
    AMensaje := Format(SInfoLineasIncorporadasAlbaranCompra,
      [ASerieAlbcDestino, ANumAlbcDestino]);
    Result := True;
  end;
end;

function IncorporarAlbaranDesdePedidoConCantidadesInterno(
                                  AConn: TUniConnection;
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
  bValido, bProcesar: Boolean;
begin
  Result   := False;
  AMensaje := '';
  bValido := Trim(ACodigoAlm) <> '';
  if not bValido then
    AMensaje := SErrorAlmacenPedidoCompraNoSeleccionado;
  if bValido then
  begin
    bValido := (Trim(ASerieAlbcDestino) <> '') and
      (Trim(ANumAlbcDestino) <> '');
    if not bValido then
      AMensaje := SErrorAlbaranCompraDestinoNoSeleccionado;
  end;
  if bValido then
  begin
    rTotalCeldas := 0;
    for c in ACeldas do
    begin
      if SameText(c.CodigoAlmacen, ACodigoAlm) and
         (c.Cantidad > 0) then
        rTotalCeldas := rTotalCeldas + c.Cantidad;
    end;
    bValido := rTotalCeldas > 0;
    if not bValido then
      AMensaje := Format(SErrorPedidoCompraSinCantidadesRecibir,
        [ACodigoAlm, ASeriePedc, ANumPedc]);
  end;
  if bValido then
  begin
    iLineaAlbc := MaxLineaAlbaranCompra(
      AConn, ASerieAlbcDestino, ANumAlbcDestino);
    iInsertadas := 0;
    q := TUniQuery.Create(nil);
    qIns := TUniQuery.Create(nil);
    dPdteLinea := TDictionary<string,Double>.Create;
    try
      q.Connection    := AConn;
      qIns.Connection := AConn;
      for c in ACeldas do
      begin
        bProcesar := SameText(c.CodigoAlmacen, ACodigoAlm) and
          (c.Cantidad > 0);
        if bProcesar then
        begin
          // Leer datos de la línea origen del pedido.
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
          if not q.Eof then
          begin
            // Limita la recepción al pendiente real de la línea.
            if not dPdteLinea.TryGetValue(
              c.LineaPedido, rPdteLin) then
            begin
              rPdteLin := q.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
                q.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
              if rPdteLin < 0 then
                rPdteLin := 0;
            end;
            rCantidad := c.Cantidad;
            if rCantidad > rPdteLin then
              rCantidad := rPdteLin;
            dPdteLinea.AddOrSetValue(
              c.LineaPedido, rPdteLin - rCantidad);
            if rCantidad > 0 then
            begin
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
              qIns.ParamByName('u').AsString := AUsuario;
              qIns.ParamByName('s').AsString := ASeriePedc;
              qIns.ParamByName('n').AsString := ANumPedc;
              qIns.ParamByName('l').AsString := c.LineaPedido;
              qIns.ExecSQL;
            end;
          end;
        end;
      end;
    finally
      FreeAndNil(q);
      FreeAndNil(qIns);
      FreeAndNil(dPdteLinea);
    end;
    if iInsertadas = 0 then
      AMensaje := SErrorIncorporarLineasAlbaranCompra
    else
    begin
      RegenerarMovimientosYCerrarAlbaranCompra(AConn,
        ASerieAlbcDestino, ANumAlbcDestino, ASeriePedc, ANumPedc,
        AUsuario, AIdPvTemporada);
      AMensaje := Format(
        SInfoLineasIncorporadasAlbaranCompraConCantidad,
        [ASerieAlbcDestino, ANumAlbcDestino, iInsertadas]);
      Result := True;
    end;
  end;
end;

// ===========================================================================
//   TIncorporacionAlbaranPedidoCompraUniDAC - adaptador del contrato
// ===========================================================================

constructor TIncorporacionAlbaranPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TIncorporacionAlbaranPedidoCompraUniDAC.
  IncorporarAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
begin
  Result := IncorporarAlbaranDesdePedidoInterno(
    FConexion, ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
    AIdPvTemporada, AMensaje);
end;

function TIncorporacionAlbaranPedidoCompraUniDAC.
  IncorporarAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Result := IncorporarAlbaranDesdePedidoConCantidadesInterno(
    FConexion, ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
    AIdPvTemporada, ACeldas, AMensaje);
end;

function CrearIncorporacionAlbaranPedidoCompraUniDAC(
  AConexion: TUniConnection): IIncorporacionAlbaranPedidoCompra;
begin
  Result := TIncorporacionAlbaranPedidoCompraUniDAC.Create(
    AConexion);
end;

end.
