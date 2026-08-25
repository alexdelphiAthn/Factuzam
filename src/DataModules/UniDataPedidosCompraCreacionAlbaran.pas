{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraCreacionAlbaran                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Creación de albaranes nuevos desde pedidos de compra.                    }
{******************************************************************************}
unit UniDataPedidosCompraCreacionAlbaran;

interface

uses
  Uni, inLibGridPivoteCompraTipos, inLibPedidosCompraIntf;

function CrearCreacionAlbaranPedidoCompraUniDAC(
  AConexion: TUniConnection): ICreacionAlbaranPedidoCompra;
function CrearAlbaranDesdePedidoInterno(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime; AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;
function CrearAlbaranDesdePedidoConCantidadesInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, UniDataValoresAutomaticosRepositorio, inLibMsgCompras,
  UniDataPedidosCompraAlbaranComun, UniDataPedidosCompraPendientes,
  inLibPrestaShopColaSenal;

type
  TCreacionAlbaranPedidoCompraUniDAC = class(
    TInterfacedObject, ICreacionAlbaranPedidoCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CrearAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      out ANumAlbc, AMensaje: string): Boolean;
    function CrearAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out ANumAlbc, AMensaje: string): Boolean;
  end;

function CrearAlbaranDesdePedidoInterno(AConn: TUniConnection;
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
  // La lectura de pendientes debe hacerse despues del mismo bloqueo que usa
  // la reversion; asi no fija una instantanea anterior a otra recepcion.
  if not BloquearPedidoCompra(AConn, ASeriePedc, ANumPedc) then
  begin
    AMensaje := SErrorPedidoCompraNoActivoCrearAlbaran;
    Exit;
  end;
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
      Result := CrearAlbaranDesdePedidoConCantidadesInterno(
        AConn, ASeriePedc,
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

procedure PrepararInsercionCabeceraAlbaranPedido(AQuery: TUniQuery);
begin
  AQuery.SQL.Text :=
    'INSERT INTO fza_albaranes_compra ' +
    '  (NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, INSTANTE_MOVIMIENTO_ALBC, ' +
    '   ESTADO_ALBC, ' +
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
    '       CASE WHEN :usar_fecha = ''S'' THEN :freal ELSE ' +
    '       TIMESTAMP(IFNULL(P.FECHA_PEDC, CURDATE()), CURRENT_TIME) END, ' +
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
  const ACeldas: TArray<TCeldaARecibir>): Integer;
var
  QueryOrigen: TUniQuery;
  QueryDestino: TUniQuery;
  PendientePorLinea: TDictionary<string, Double>;
  Celda: TCeldaARecibir;
  Cantidad: Double;
  NumeroLineaAlbaran: Integer;
  LineaAlbaran: string;
begin
  Result := 0;
  NumeroLineaAlbaran := 0;
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
          Inc(NumeroLineaAlbaran, 10);
          LineaAlbaran := Format('%.4d', [NumeroLineaAlbaran]);
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

function CrearAlbaranDesdePedidoConCantidadesInterno(
                                  AConn: TUniConnection;
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
  iLineasCreadas: Integer;
begin
  Result := False;
  AMensaje := '';
  ANumAlbc := '';
  if ValidarSolicitudRecepcionCeldas(
    ASeriePedc, ANumPedc, ACodigoAlm,
    ACeldas, AMensaje) then
  begin
    if not BloquearPedidoCompra(AConn, ASeriePedc, ANumPedc) then
      AMensaje := SErrorPedidoCompraNoActivoCrearAlbaran
    else if ReservarNumeroAlbaranCompra(
      AConn, AUsuario, ANumAlbc, AMensaje) then
    begin
      CrearCabeceraAlbaranPedido(
        AConn, ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbc, ANumAlbc, ARefPrv, AUsuario,
        AFechaRecepcion, AIdPvTemporada);
      iLineasCreadas := ProcesarCeldasRecepcionPedido(
        AConn, ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbc, ANumAlbc, AUsuario, ACeldas);
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
end;


constructor TCreacionAlbaranPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TCreacionAlbaranPedidoCompraUniDAC.CrearAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;
var
  EsTransaccionPropia: Boolean;
begin
  EsTransaccionPropia := not FConexion.InTransaction;
  if EsTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := CrearAlbaranDesdePedidoInterno(
      FConexion, ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
      AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
      ANumAlbc, AMensaje);
    if EsTransaccionPropia then
    begin
      if Result then
      begin
        FConexion.Commit;
        SolicitarProcesadoPrestaShop;
      end
      else
        FConexion.Rollback;
    end;
  except
    if EsTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function TCreacionAlbaranPedidoCompraUniDAC.
  CrearAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;
var
  EsTransaccionPropia: Boolean;
begin
  EsTransaccionPropia := not FConexion.InTransaction;
  if EsTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := CrearAlbaranDesdePedidoConCantidadesInterno(
      FConexion, ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
      AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
      ACeldas, ANumAlbc, AMensaje);
    if EsTransaccionPropia then
    begin
      if Result then
      begin
        FConexion.Commit;
        SolicitarProcesadoPrestaShop;
      end
      else
        FConexion.Rollback;
    end;
  except
    if EsTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function CrearCreacionAlbaranPedidoCompraUniDAC(
  AConexion: TUniConnection): ICreacionAlbaranPedidoCompra;
begin
  Result := TCreacionAlbaranPedidoCompraUniDAC.Create(AConexion);
end;

end.
