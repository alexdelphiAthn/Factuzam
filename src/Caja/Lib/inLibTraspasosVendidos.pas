{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraspasosVendidos                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reparte lo que la tienda destino ha vendido entre los traspasos TA que    }
{    le llegaron: por almacén destino y SKU, FIFO por fecha de traspaso y      }
{    nunca antes de que la mercancía saliera. Las devoluciones deshacen lo     }
{    facturado, primero lo asignado en esta misma pasada y después lo que ya   }
{    se facturó, al precio al que se facturó.                                  }
{    Sin VCL, datasets ni persistencia.                                        }
{******************************************************************************}
unit inLibTraspasosVendidos;

interface

uses
  inLibFacturasProformaIntf;

type
  TTipoAsignacionTraspasoVendido = (
    tatvVenta,
    tatvDevolucion
  );

  // Salida TA del almacén origen con unidades aún sin facturar.
  TTraspasoVendiblePendiente = record
    NumeroMovimiento  : string;
    IdOperacion       : Int64;
    NumeroOperacion   : string;
    Linea             : string;
    Fecha             : TDateTime;
    AlmacenOrigen     : string;
    AlmacenDestino    : string;
    CodigoArticulo    : string;
    CodigoUnidad      : string;
    Descripcion       : string;
    Cantidad          : Currency;
    // Neto ya imputado en pasadas anteriores (ventas menos devoluciones).
    CantidadFacturada : Currency;
    CosteMovimiento   : Currency;
    PrecioMedioEmpresa: Currency;
    PrecioUltimaCompra: Currency;
    AntiguedadMeses   : Integer;
    PrecioVentaDestino: Currency;
  end;

  TTraspasosVendiblesPendientes = array of TTraspasoVendiblePendiente;

  // Movimiento VE de la tienda destino: venta (salida) o devolución
  // (entrada). CantidadAsignada es lo que ya se facturó de él.
  TVentaDestinoPendiente = record
    NumeroMovimiento: string;
    Fecha           : TDateTime;
    Almacen         : string;
    CodigoUnidad    : string;
    Cantidad        : Currency;
    CantidadAsignada: Currency;
    EsDevolucion    : Boolean;
    // Precio unitario sin IVA de esa venta: el traspaso no puede
    // facturarse por encima de lo que la tienda cobró por esas unidades.
    PrecioVenta     : Currency;
  end;

  TVentasDestinoPendientes = array of TVentaDestinoPendiente;

  // Unidades de un traspaso ya facturadas a un precio dado, susceptibles de
  // revertirse si la tienda devuelve la mercancía.
  TFacturacionTraspasoPrevia = record
    NumeroMovimientoTraspaso: string;
    IdOperacion             : Int64;
    AlmacenOrigen           : string;
    AlmacenDestino          : string;
    CodigoArticulo          : string;
    CodigoUnidad            : string;
    Descripcion             : string;
    Precio                  : Currency;
    Cantidad                : Currency;
    Fecha                   : TDateTime;
    FechaTraspaso           : TDateTime;
  end;

  TFacturacionesTraspasoPrevias = array of TFacturacionTraspasoPrevia;

  // Unidades de un traspaso que se facturan (o se devuelven) por un
  // movimiento de venta concreto. IndiceTraspaso apunta a la lista de
  // traspasos pendientes e IndicePrevia a la de facturaciones anteriores;
  // sólo uno de los dos es >= 0. EsPrecioValorado indica que el precio lo
  // pone la valoración del usuario y no la facturación que se deshace.
  TAsignacionTraspasoVendido = record
    Tipo                    : TTipoAsignacionTraspasoVendido;
    IndiceTraspaso          : Integer;
    IndicePrevia            : Integer;
    NumeroMovimientoTraspaso: string;
    NumeroMovimientoVenta   : string;
    FechaVenta              : TDateTime;
    Cantidad                : Currency;
    Precio                  : Currency;
    EsPrecioValorado        : Boolean;
    // Tope de la línea: lo que se cobró en la venta que la origina (0 si
    // no consta o si es una devolución de algo ya facturado).
    PrecioVenta             : Currency;
  end;

  TAsignacionesTraspasoVendido = array of TAsignacionTraspasoVendido;

  // Asignación ya valorada, lista para facturar: una fila por movimiento de
  // venta y traspaso. Cantidad negativa = devolución.
  TFilaTraspasoVendido = record
    NumeroMovimientoTraspaso: string;
    NumeroMovimientoVenta   : string;
    IdOperacion             : Int64;
    AlmacenOrigen           : string;
    AlmacenDestino          : string;
    CodigoArticulo          : string;
    CodigoUnidad            : string;
    Cantidad                : Currency;
    Precio                  : Currency;
    FechaVenta              : TDateTime;
    FechaTraspaso           : TDateTime;
    EsDevolucion            : Boolean;
  end;

  TFilasTraspasoVendido = array of TFilaTraspasoVendido;

function ClaveTraspasoVendido(
  const AAlmacen: string;
  const ACodigoUnidad: string): string;
function AsignarVentasATraspasos(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AVentas: TVentasDestinoPendientes;
  const AFacturadas: TFacturacionesTraspasoPrevias
): TAsignacionesTraspasoVendido;
// Neto asignado a cada traspaso en esta pasada (positivos menos las
// devoluciones que deshacen lo asignado ahora mismo).
function CantidadNetaAsignadaTraspaso(
  const AAsignaciones: TAsignacionesTraspasoVendido;
  AIndiceTraspaso: Integer): Currency;
// Líneas a valorar: un renglón por traspaso con unidades netas vendidas.
function ResumirTraspasosVendidos(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AAsignaciones: TAsignacionesTraspasoVendido
): TLineasTraspasoPendientes;
// Traspasos con unidades vendidas que la valoración no trae (ventas o
// traspasos nuevos desde la simulación): con uno solo no se factura nada.
function ContarTraspasosVendidosSinValorar(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AAsignaciones: TAsignacionesTraspasoVendido;
  const AValoracion: TValoracionTraspasos): Integer;
// Filas a facturar: las ventas al precio valorado y las devoluciones al
// precio al que se facturó lo que deshacen.
function ConstruirFilasTraspasoVendido(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const APrevias: TFacturacionesTraspasoPrevias;
  const AAsignaciones: TAsignacionesTraspasoVendido;
  const AValoracion: TValoracionTraspasos): TFilasTraspasoVendido;
// Almacenes de origen presentes en las filas, en orden de aparición: cada
// uno tiene su serie de facturación y por tanto su factura.
function AlmacenesOrigenTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): TArray<string>;
function FilasTraspasoVendidoDeAlmacen(
  const AFilas: TFilasTraspasoVendido;
  const AAlmacenOrigen: string): TFilasTraspasoVendido;
// False si todo lo vendido se compensa con devoluciones del mismo traspaso
// y precio: no habría ninguna línea que facturar.
function HayImporteFacturableTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): Boolean;
function ContarOperacionesTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): Integer;
function ContarDevolucionesTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): Integer;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  inLibFacturasProformaValoracion,
  inLibMargenVinculadas;

type
  TRepartoTraspasosVendidos = class
  private
    FTraspasos   : TTraspasosVendiblesPendientes;
    FVentas      : TVentasDestinoPendientes;
    FPrevias     : TFacturacionesTraspasoPrevias;
    FPendientes  : TArray<Currency>;
    FRevertibles : TArray<Currency>;
    FRestos      : TArray<Currency>;
    FAsignaciones: TAsignacionesTraspasoVendido;
    FIndiceMovimiento: TDictionary<string, Integer>;
    FTraspasosPorClave: TObjectDictionary<string, TList<Integer>>;
    FPreviasPorClave  : TObjectDictionary<string, TList<Integer>>;
    procedure AgruparTraspasos;
    procedure AgruparPrevias;
    function OrdenVentas: TArray<Integer>;
    procedure AnotarAsignacion(
      const AAsignacion: TAsignacionTraspasoVendido);
    function RepartirVenta(
      AIndiceVenta: Integer;
      APendiente: Currency): Currency;
    function RevertirSobreAsignadas(
      AIndiceVenta: Integer;
      APendiente: Currency): Currency;
    function RevertirSobreFacturadas(
      AIndiceVenta: Integer;
      APendiente: Currency): Currency;
  public
    constructor Create(
      const ATraspasos: TTraspasosVendiblesPendientes;
      const AVentas: TVentasDestinoPendientes;
      const AFacturadas: TFacturacionesTraspasoPrevias);
    destructor Destroy; override;
    function Ejecutar: TAsignacionesTraspasoVendido;
  end;

function ClaveTraspasoVendido(
  const AAlmacen: string;
  const ACodigoUnidad: string): string;
begin
  Result := UpperCase(Trim(AAlmacen)) + '|' + UpperCase(Trim(ACodigoUnidad));
end;

function MenorCantidad(AUno: Currency; AOtro: Currency): Currency;
begin
  if AUno < AOtro then
    Result := AUno
  else
    Result := AOtro;
end;

constructor TRepartoTraspasosVendidos.Create(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AVentas: TVentasDestinoPendientes;
  const AFacturadas: TFacturacionesTraspasoPrevias);
var
  iIndice: Integer;
begin
  inherited Create;
  FTraspasos := ATraspasos;
  FVentas := AVentas;
  FPrevias := AFacturadas;
  SetLength(FPendientes, Length(FTraspasos));
  SetLength(FRevertibles, Length(FPrevias));
  FIndiceMovimiento := TDictionary<string, Integer>.Create;
  FTraspasosPorClave := TObjectDictionary<string, TList<Integer>>.Create(
    [doOwnsValues]);
  FPreviasPorClave := TObjectDictionary<string, TList<Integer>>.Create(
    [doOwnsValues]);
  for iIndice := 0 to High(FTraspasos) do
  begin
    FPendientes[iIndice] :=
      FTraspasos[iIndice].Cantidad - FTraspasos[iIndice].CantidadFacturada;
    FIndiceMovimiento.AddOrSetValue(
      UpperCase(Trim(FTraspasos[iIndice].NumeroMovimiento)), iIndice);
  end;
  for iIndice := 0 to High(FPrevias) do
  begin
    FRevertibles[iIndice] := FPrevias[iIndice].Cantidad;
  end;
end;

destructor TRepartoTraspasosVendidos.Destroy;
begin
  FreeAndNil(FPreviasPorClave);
  FreeAndNil(FTraspasosPorClave);
  FreeAndNil(FIndiceMovimiento);
  inherited;
end;

procedure TRepartoTraspasosVendidos.AgruparTraspasos;
var
  iIndice: Integer;
  sClave : string;
  oLista : TList<Integer>;
begin
  for iIndice := 0 to High(FTraspasos) do
  begin
    sClave := ClaveTraspasoVendido(
      FTraspasos[iIndice].AlmacenDestino,
      FTraspasos[iIndice].CodigoUnidad);
    if not FTraspasosPorClave.TryGetValue(sClave, oLista) then
    begin
      oLista := TList<Integer>.Create;
      FTraspasosPorClave.Add(sClave, oLista);
    end;
    oLista.Add(iIndice);
  end;
  for oLista in FTraspasosPorClave.Values do
  begin
    oLista.Sort(TComparer<Integer>.Construct(
      function(const AUno, AOtro: Integer): Integer
      begin
        Result := CompareDateTime(
          FTraspasos[AUno].Fecha, FTraspasos[AOtro].Fecha);
        if Result = 0 then
          Result := CompareText(
            FTraspasos[AUno].NumeroMovimiento,
            FTraspasos[AOtro].NumeroMovimiento);
      end));
  end;
end;

procedure TRepartoTraspasosVendidos.AgruparPrevias;
var
  iIndice: Integer;
  sClave : string;
  oLista : TList<Integer>;
begin
  for iIndice := 0 to High(FPrevias) do
  begin
    sClave := ClaveTraspasoVendido(
      FPrevias[iIndice].AlmacenDestino,
      FPrevias[iIndice].CodigoUnidad);
    if not FPreviasPorClave.TryGetValue(sClave, oLista) then
    begin
      oLista := TList<Integer>.Create;
      FPreviasPorClave.Add(sClave, oLista);
    end;
    oLista.Add(iIndice);
  end;
  for oLista in FPreviasPorClave.Values do
  begin
    oLista.Sort(TComparer<Integer>.Construct(
      function(const AUno, AOtro: Integer): Integer
      begin
        Result := CompareDateTime(
          FPrevias[AUno].Fecha, FPrevias[AOtro].Fecha);
        if Result = 0 then
          Result := CompareText(
            FPrevias[AUno].NumeroMovimientoTraspaso,
            FPrevias[AOtro].NumeroMovimientoTraspaso);
      end));
  end;
end;

function TRepartoTraspasosVendidos.OrdenVentas: TArray<Integer>;
var
  iIndice: Integer;
begin
  SetLength(Result, Length(FVentas));
  for iIndice := 0 to High(FVentas) do
  begin
    Result[iIndice] := iIndice;
  end;
  TArray.Sort<Integer>(Result, TComparer<Integer>.Construct(
    function(const AUno, AOtro: Integer): Integer
    begin
      Result := CompareDateTime(FVentas[AUno].Fecha, FVentas[AOtro].Fecha);
      if Result = 0 then
        Result := CompareText(
          FVentas[AUno].NumeroMovimiento, FVentas[AOtro].NumeroMovimiento);
    end));
end;

procedure TRepartoTraspasosVendidos.AnotarAsignacion(
  const AAsignacion: TAsignacionTraspasoVendido);
begin
  SetLength(FAsignaciones, Length(FAsignaciones) + 1);
  FAsignaciones[High(FAsignaciones)] := AAsignacion;
  SetLength(FRestos, Length(FAsignaciones));
  if AAsignacion.Tipo = tatvVenta then
    FRestos[High(FRestos)] := AAsignacion.Cantidad
  else
    FRestos[High(FRestos)] := 0;
end;

function TRepartoTraspasosVendidos.RepartirVenta(
  AIndiceVenta: Integer;
  APendiente: Currency): Currency;
var
  oLista     : TList<Integer>;
  iPosicion  : Integer;
  iTraspaso  : Integer;
  cCantidad  : Currency;
  oAsignacion: TAsignacionTraspasoVendido;
begin
  Result := APendiente;
  if FTraspasosPorClave.TryGetValue(
       ClaveTraspasoVendido(
         FVentas[AIndiceVenta].Almacen,
         FVentas[AIndiceVenta].CodigoUnidad), oLista) then
  begin
    for iPosicion := 0 to oLista.Count - 1 do
    begin
      iTraspaso := oLista[iPosicion];
      if (Result > 0) and (FPendientes[iTraspaso] > 0) and
         (Trunc(FTraspasos[iTraspaso].Fecha) <=
          Trunc(FVentas[AIndiceVenta].Fecha)) then
      begin
        cCantidad := MenorCantidad(Result, FPendientes[iTraspaso]);
        oAsignacion := Default(TAsignacionTraspasoVendido);
        oAsignacion.Tipo := tatvVenta;
        oAsignacion.IndiceTraspaso := iTraspaso;
        oAsignacion.IndicePrevia := -1;
        oAsignacion.NumeroMovimientoTraspaso :=
          FTraspasos[iTraspaso].NumeroMovimiento;
        oAsignacion.NumeroMovimientoVenta :=
          FVentas[AIndiceVenta].NumeroMovimiento;
        oAsignacion.FechaVenta := FVentas[AIndiceVenta].Fecha;
        oAsignacion.Cantidad := cCantidad;
        oAsignacion.EsPrecioValorado := True;
        oAsignacion.PrecioVenta := FVentas[AIndiceVenta].PrecioVenta;
        AnotarAsignacion(oAsignacion);
        FPendientes[iTraspaso] := FPendientes[iTraspaso] - cCantidad;
        Result := Result - cCantidad;
      end;
    end;
  end;
end;

function TRepartoTraspasosVendidos.RevertirSobreAsignadas(
  AIndiceVenta: Integer;
  APendiente: Currency): Currency;
var
  iPosicion  : Integer;
  iTraspaso  : Integer;
  cCantidad  : Currency;
  sClave     : string;
  oAsignacion: TAsignacionTraspasoVendido;
begin
  Result := APendiente;
  sClave := ClaveTraspasoVendido(
    FVentas[AIndiceVenta].Almacen,
    FVentas[AIndiceVenta].CodigoUnidad);
  for iPosicion := High(FAsignaciones) downto 0 do
  begin
    iTraspaso := FAsignaciones[iPosicion].IndiceTraspaso;
    if (Result > 0) and (FRestos[iPosicion] > 0) and (iTraspaso >= 0) and
       SameText(sClave, ClaveTraspasoVendido(
         FTraspasos[iTraspaso].AlmacenDestino,
         FTraspasos[iTraspaso].CodigoUnidad)) then
    begin
      cCantidad := MenorCantidad(Result, FRestos[iPosicion]);
      oAsignacion := Default(TAsignacionTraspasoVendido);
      oAsignacion.Tipo := tatvDevolucion;
      oAsignacion.IndiceTraspaso := iTraspaso;
      oAsignacion.IndicePrevia := -1;
      oAsignacion.NumeroMovimientoTraspaso :=
        FTraspasos[iTraspaso].NumeroMovimiento;
      oAsignacion.NumeroMovimientoVenta :=
        FVentas[AIndiceVenta].NumeroMovimiento;
      oAsignacion.FechaVenta := FVentas[AIndiceVenta].Fecha;
      oAsignacion.Cantidad := -cCantidad;
      oAsignacion.EsPrecioValorado := True;
      oAsignacion.PrecioVenta := FAsignaciones[iPosicion].PrecioVenta;
      FRestos[iPosicion] := FRestos[iPosicion] - cCantidad;
      AnotarAsignacion(oAsignacion);
      FPendientes[iTraspaso] := FPendientes[iTraspaso] + cCantidad;
      Result := Result - cCantidad;
    end;
  end;
end;

function TRepartoTraspasosVendidos.RevertirSobreFacturadas(
  AIndiceVenta: Integer;
  APendiente: Currency): Currency;
var
  oLista     : TList<Integer>;
  iPosicion  : Integer;
  iPrevia    : Integer;
  iTraspaso  : Integer;
  cCantidad  : Currency;
  oAsignacion: TAsignacionTraspasoVendido;
begin
  Result := APendiente;
  if FPreviasPorClave.TryGetValue(
       ClaveTraspasoVendido(
         FVentas[AIndiceVenta].Almacen,
         FVentas[AIndiceVenta].CodigoUnidad), oLista) then
  begin
    for iPosicion := oLista.Count - 1 downto 0 do
    begin
      iPrevia := oLista[iPosicion];
      if (Result > 0) and (FRevertibles[iPrevia] > 0) then
      begin
        cCantidad := MenorCantidad(Result, FRevertibles[iPrevia]);
        oAsignacion := Default(TAsignacionTraspasoVendido);
        oAsignacion.Tipo := tatvDevolucion;
        oAsignacion.IndiceTraspaso := -1;
        oAsignacion.IndicePrevia := iPrevia;
        oAsignacion.NumeroMovimientoTraspaso :=
          FPrevias[iPrevia].NumeroMovimientoTraspaso;
        oAsignacion.NumeroMovimientoVenta :=
          FVentas[AIndiceVenta].NumeroMovimiento;
        oAsignacion.FechaVenta := FVentas[AIndiceVenta].Fecha;
        oAsignacion.Cantidad := -cCantidad;
        oAsignacion.Precio := FPrevias[iPrevia].Precio;
        oAsignacion.EsPrecioValorado := False;
        AnotarAsignacion(oAsignacion);
        FRevertibles[iPrevia] := FRevertibles[iPrevia] - cCantidad;
        Result := Result - cCantidad;
        if FIndiceMovimiento.TryGetValue(
             UpperCase(Trim(FPrevias[iPrevia].NumeroMovimientoTraspaso)),
             iTraspaso) then
          FPendientes[iTraspaso] := FPendientes[iTraspaso] + cCantidad;
      end;
    end;
  end;
end;

function TRepartoTraspasosVendidos.Ejecutar: TAsignacionesTraspasoVendido;
var
  aOrden    : TArray<Integer>;
  iPosicion : Integer;
  iVenta    : Integer;
  cPendiente: Currency;
begin
  SetLength(FAsignaciones, 0);
  SetLength(FRestos, 0);
  AgruparTraspasos;
  AgruparPrevias;
  aOrden := OrdenVentas;
  for iPosicion := 0 to High(aOrden) do
  begin
    iVenta := aOrden[iPosicion];
    cPendiente :=
      FVentas[iVenta].Cantidad - FVentas[iVenta].CantidadAsignada;
    if cPendiente > 0 then
    begin
      if FVentas[iVenta].EsDevolucion then
      begin
        cPendiente := RevertirSobreAsignadas(iVenta, cPendiente);
        RevertirSobreFacturadas(iVenta, cPendiente);
      end
      else
        RepartirVenta(iVenta, cPendiente);
    end;
  end;
  Result := FAsignaciones;
end;

function AsignarVentasATraspasos(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AVentas: TVentasDestinoPendientes;
  const AFacturadas: TFacturacionesTraspasoPrevias
): TAsignacionesTraspasoVendido;
var
  oReparto: TRepartoTraspasosVendidos;
begin
  oReparto := TRepartoTraspasosVendidos.Create(
    ATraspasos, AVentas, AFacturadas);
  try
    Result := oReparto.Ejecutar;
  finally
    FreeAndNil(oReparto);
  end;
end;

function NetosPorTraspaso(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AAsignaciones: TAsignacionesTraspasoVendido): TArray<Currency>;
var
  iIndice  : Integer;
  iTraspaso: Integer;
begin
  SetLength(Result, Length(ATraspasos));
  for iIndice := 0 to High(Result) do
  begin
    Result[iIndice] := 0;
  end;
  for iIndice := 0 to High(AAsignaciones) do
  begin
    iTraspaso := AAsignaciones[iIndice].IndiceTraspaso;
    if (iTraspaso >= 0) and (iTraspaso <= High(Result)) then
      Result[iTraspaso] := Result[iTraspaso] + AAsignaciones[iIndice].Cantidad;
  end;
end;

function PreciosValorados(
  const AValoracion: TValoracionTraspasos): TDictionary<string, Currency>;
var
  iIndice: Integer;
begin
  Result := TDictionary<string, Currency>.Create;
  for iIndice := 0 to High(AValoracion) do
  begin
    Result.AddOrSetValue(
      UpperCase(Trim(AValoracion[iIndice].NumeroMovimiento)),
      AValoracion[iIndice].Precio);
  end;
end;

function ClaveLineaFactura(
  const ANumeroMovimiento: string;
  APrecio: Currency): string;
begin
  Result := UpperCase(Trim(ANumeroMovimiento)) + '|' +
    IntToStr(Round(APrecio * 10000));
end;

function CantidadNetaAsignadaTraspaso(
  const AAsignaciones: TAsignacionesTraspasoVendido;
  AIndiceTraspaso: Integer): Currency;
var
  iIndice: Integer;
begin
  Result := 0;
  for iIndice := 0 to High(AAsignaciones) do
  begin
    if AAsignaciones[iIndice].IndiceTraspaso = AIndiceTraspaso then
      Result := Result + AAsignaciones[iIndice].Cantidad;
  end;
end;

function ContarTraspasosVendidosSinValorar(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AAsignaciones: TAsignacionesTraspasoVendido;
  const AValoracion: TValoracionTraspasos): Integer;
var
  oPrecios: TDictionary<string, Currency>;
  aNetos  : TArray<Currency>;
  iIndice : Integer;
  cPrecio : Currency;
begin
  Result := 0;
  aNetos := NetosPorTraspaso(ATraspasos, AAsignaciones);
  oPrecios := PreciosValorados(AValoracion);
  try
    for iIndice := 0 to High(ATraspasos) do
    begin
      if (aNetos[iIndice] > 0) and
         (not oPrecios.TryGetValue(
            UpperCase(Trim(ATraspasos[iIndice].NumeroMovimiento)),
            cPrecio)) then
        Inc(Result);
    end;
  finally
    FreeAndNil(oPrecios);
  end;
end;

function ConstruirFilasTraspasoVendido(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const APrevias: TFacturacionesTraspasoPrevias;
  const AAsignaciones: TAsignacionesTraspasoVendido;
  const AValoracion: TValoracionTraspasos): TFilasTraspasoVendido;
var
  oPrecios : TDictionary<string, Currency>;
  iIndice  : Integer;
  iTraspaso: Integer;
  iPrevia  : Integer;
  cPrecio  : Currency;
begin
  SetLength(Result, Length(AAsignaciones));
  oPrecios := PreciosValorados(AValoracion);
  try
    for iIndice := 0 to High(AAsignaciones) do
    begin
      Result[iIndice] := Default(TFilaTraspasoVendido);
      Result[iIndice].NumeroMovimientoTraspaso :=
        AAsignaciones[iIndice].NumeroMovimientoTraspaso;
      Result[iIndice].NumeroMovimientoVenta :=
        AAsignaciones[iIndice].NumeroMovimientoVenta;
      Result[iIndice].Cantidad := AAsignaciones[iIndice].Cantidad;
      Result[iIndice].FechaVenta := AAsignaciones[iIndice].FechaVenta;
      Result[iIndice].EsDevolucion :=
        AAsignaciones[iIndice].Tipo = tatvDevolucion;
      Result[iIndice].Precio := AAsignaciones[iIndice].Precio;
      iTraspaso := AAsignaciones[iIndice].IndiceTraspaso;
      iPrevia := AAsignaciones[iIndice].IndicePrevia;
      if (iTraspaso >= 0) and (iTraspaso <= High(ATraspasos)) then
      begin
        Result[iIndice].IdOperacion := ATraspasos[iTraspaso].IdOperacion;
        Result[iIndice].AlmacenOrigen := ATraspasos[iTraspaso].AlmacenOrigen;
        Result[iIndice].AlmacenDestino :=
          ATraspasos[iTraspaso].AlmacenDestino;
        Result[iIndice].CodigoArticulo :=
          ATraspasos[iTraspaso].CodigoArticulo;
        Result[iIndice].CodigoUnidad := ATraspasos[iTraspaso].CodigoUnidad;
        Result[iIndice].FechaTraspaso := ATraspasos[iTraspaso].Fecha;
        if oPrecios.TryGetValue(
             UpperCase(Trim(ATraspasos[iTraspaso].NumeroMovimiento)),
             cPrecio) then
          Result[iIndice].Precio := cPrecio
        else
          Result[iIndice].Precio := PrecioBaseTraspaso(
            ATraspasos[iTraspaso].PrecioMedioEmpresa,
            ATraspasos[iTraspaso].CosteMovimiento);
      end
      else if (iPrevia >= 0) and (iPrevia <= High(APrevias)) then
      begin
        Result[iIndice].IdOperacion := APrevias[iPrevia].IdOperacion;
        Result[iIndice].AlmacenOrigen := APrevias[iPrevia].AlmacenOrigen;
        Result[iIndice].AlmacenDestino := APrevias[iPrevia].AlmacenDestino;
        Result[iIndice].CodigoArticulo := APrevias[iPrevia].CodigoArticulo;
        Result[iIndice].CodigoUnidad := APrevias[iPrevia].CodigoUnidad;
        Result[iIndice].FechaTraspaso := APrevias[iPrevia].FechaTraspaso;
        Result[iIndice].Precio := APrevias[iPrevia].Precio;
      end;
      // Ni lo valorado ni el precio base pueden superar lo que la tienda
      // cobró por esas unidades.
      Result[iIndice].Precio := PrecioConTopeVenta(
        Result[iIndice].Precio, AAsignaciones[iIndice].PrecioVenta);
    end;
  finally
    FreeAndNil(oPrecios);
  end;
end;

function AlmacenesOrigenTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): TArray<string>;
var
  oVistos: TDictionary<string, Integer>;
  iIndice: Integer;
  sClave : string;
begin
  SetLength(Result, 0);
  oVistos := TDictionary<string, Integer>.Create;
  try
    for iIndice := 0 to High(AFilas) do
    begin
      sClave := UpperCase(Trim(AFilas[iIndice].AlmacenOrigen));
      if not oVistos.ContainsKey(sClave) then
      begin
        oVistos.Add(sClave, iIndice);
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := AFilas[iIndice].AlmacenOrigen;
      end;
    end;
  finally
    FreeAndNil(oVistos);
  end;
end;

function FilasTraspasoVendidoDeAlmacen(
  const AFilas: TFilasTraspasoVendido;
  const AAlmacenOrigen: string): TFilasTraspasoVendido;
var
  iIndice: Integer;
  iFila  : Integer;
begin
  SetLength(Result, 0);
  iFila := 0;
  for iIndice := 0 to High(AFilas) do
  begin
    if SameText(
         Trim(AFilas[iIndice].AlmacenOrigen), Trim(AAlmacenOrigen)) then
    begin
      SetLength(Result, iFila + 1);
      Result[iFila] := AFilas[iIndice];
      Inc(iFila);
    end;
  end;
end;

function HayImporteFacturableTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): Boolean;
var
  oNetos   : TDictionary<string, Currency>;
  iIndice  : Integer;
  sClave   : string;
  cAcumulado: Currency;
begin
  Result := False;
  oNetos := TDictionary<string, Currency>.Create;
  try
    for iIndice := 0 to High(AFilas) do
    begin
      sClave := ClaveLineaFactura(
        AFilas[iIndice].NumeroMovimientoTraspaso, AFilas[iIndice].Precio);
      if not oNetos.TryGetValue(sClave, cAcumulado) then
        cAcumulado := 0;
      oNetos.AddOrSetValue(sClave, cAcumulado + AFilas[iIndice].Cantidad);
    end;
    for cAcumulado in oNetos.Values do
    begin
      if cAcumulado <> 0 then
        Result := True;
    end;
  finally
    FreeAndNil(oNetos);
  end;
end;

function ContarOperacionesTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): Integer;
var
  oVistas: TDictionary<Int64, Integer>;
  iIndice: Integer;
begin
  oVistas := TDictionary<Int64, Integer>.Create;
  try
    for iIndice := 0 to High(AFilas) do
    begin
      if not oVistas.ContainsKey(AFilas[iIndice].IdOperacion) then
        oVistas.Add(AFilas[iIndice].IdOperacion, iIndice);
    end;
    Result := oVistas.Count;
  finally
    FreeAndNil(oVistas);
  end;
end;

function ContarDevolucionesTraspasoVendido(
  const AFilas: TFilasTraspasoVendido): Integer;
var
  iIndice: Integer;
begin
  Result := 0;
  for iIndice := 0 to High(AFilas) do
  begin
    if AFilas[iIndice].EsDevolucion then
      Inc(Result);
  end;
end;

function ResumirTraspasosVendidos(
  const ATraspasos: TTraspasosVendiblesPendientes;
  const AAsignaciones: TAsignacionesTraspasoVendido
): TLineasTraspasoPendientes;
var
  aNetos   : TArray<Currency>;
  iIndice  : Integer;
  iLinea   : Integer;
  cCantidad: Currency;
begin
  SetLength(Result, 0);
  aNetos := NetosPorTraspaso(ATraspasos, AAsignaciones);
  iLinea := 0;
  for iIndice := 0 to High(ATraspasos) do
  begin
    cCantidad := aNetos[iIndice];
    if cCantidad > 0 then
    begin
      SetLength(Result, iLinea + 1);
      Result[iLinea] := Default(TLineaTraspasoPendiente);
      Result[iLinea].NumeroMovimiento := ATraspasos[iIndice].NumeroMovimiento;
      Result[iLinea].NumeroOperacion := ATraspasos[iIndice].NumeroOperacion;
      Result[iLinea].FechaOperacion := ATraspasos[iIndice].Fecha;
      Result[iLinea].Linea := ATraspasos[iIndice].Linea;
      Result[iLinea].CodigoArticulo := ATraspasos[iIndice].CodigoArticulo;
      Result[iLinea].CodigoUnidad := ATraspasos[iIndice].CodigoUnidad;
      Result[iLinea].Descripcion := ATraspasos[iIndice].Descripcion;
      Result[iLinea].Cantidad := cCantidad;
      Result[iLinea].CosteMovimiento := ATraspasos[iIndice].CosteMovimiento;
      Result[iLinea].PrecioMedioEmpresa :=
        ATraspasos[iIndice].PrecioMedioEmpresa;
      Result[iLinea].PrecioUltimaCompra :=
        ATraspasos[iIndice].PrecioUltimaCompra;
      Result[iLinea].AntiguedadMeses :=
        ATraspasos[iIndice].AntiguedadMeses;
      Result[iLinea].PrecioVentaDestino :=
        ATraspasos[iIndice].PrecioVentaDestino;
      Inc(iLinea);
    end;
  end;
end;

end.
