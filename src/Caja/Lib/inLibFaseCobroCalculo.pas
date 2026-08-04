{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFaseCobroCalculo                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Calcula totales y distribuye cobros parciales sin depender de datasets.   }
{******************************************************************************}
unit inLibFaseCobroCalculo;

interface

type
  TEntradaTotalesCobro = record
    ImporteBruto: Currency;
    DescuentoLineal: Currency;
    PorcentajeDescuento: Currency;
    ImporteDejarCuenta: Currency;
    ImporteValeEmitido: Currency;
    TotalEntregado: Currency;
    TotalValesRecogidos: Currency;
    TotalEntregadoConCambio: Currency;
  end;
  TResultadoTotalesCobro = record
    ImporteDescuentoGlobal: Currency;
    ImporteTotalPagar: Currency;
    ImporteEntregado: Currency;
    ImportePendiente: Currency;
    ImporteCambio: Currency;
    ImporteValeRecogido: Currency;
    ImporteValeEmitido: Currency;
  end;
  TLineaCobroParcial = record
    IdDeposito: string;
    VieneDeDeposito: string;
    AccionDeposito: string;
    Descripcion: string;
    Total: Currency;
    AnticipoPrevio: Currency;
    PorcentajeIva: Currency;
    PrecioOriginal: Currency;
    PrecioSalida: Currency;
    PrecioConIva: Currency;
    PrecioSinIva: Currency;
    TotalSinIva: Currency;
    Modificada: Boolean;
    Eliminar: Boolean;
  end;
  TCalculadorFaseCobro = class
  private
    class function CalcularDescuento(
      ABase, APorcentaje: Currency): Currency; static;
    class procedure CalcularDevolucion(
      const AEntrada: TEntradaTotalesCobro;
      var AResultado: TResultadoTotalesCobro); static;
    class procedure CalcularVenta(
      const AEntrada: TEntradaTotalesCobro;
      var AResultado: TResultadoTotalesCobro); static;
  public
    class function CalcularTotales(
      const AEntrada: TEntradaTotalesCobro): TResultadoTotalesCobro; static;
  end;
  TCalculadorCobroParcial = class
  private
    class function EsDepositoPendiente(
      const ALinea: TLineaCobroParcial): Boolean; static;
    class function EsPrendaNueva(
      const ALinea: TLineaCobroParcial): Boolean; static;
    class procedure MarcarAbonoParaEliminar(
      var ALineas: TArray<TLineaCobroParcial>;
      const AIdDeposito: string); static;
    class procedure ConvertirEnDeposito(
      var ALineas: TArray<TLineaCobroParcial>;
      AIndice: Integer;
      var ADineroDisponible: Currency); static;
    class procedure ProcesarDepositosPendientes(
      var ALineas: TArray<TLineaCobroParcial>;
      var ADineroDisponible: Currency); static;
    class procedure ProcesarPrendasNuevas(
      var ALineas: TArray<TLineaCobroParcial>;
      var ADineroDisponible: Currency); static;
    class function CalcularDineroDisponible(
      const ALineas: TArray<TLineaCobroParcial>;
      ADineroEntregado: Currency): Currency; static;
  public
    class procedure Transformar(
      var ALineas: TArray<TLineaCobroParcial>;
      ADineroEntregado: Currency); static;
  end;

implementation

uses
  System.Math, System.SysUtils;

class function TCalculadorFaseCobro.CalcularDescuento(
  ABase, APorcentaje: Currency): Currency;
begin
  if Abs(APorcentaje) > 0.001 then
    Result := ABase * (APorcentaje / 100)
  else
    Result := 0;
end;

class procedure TCalculadorFaseCobro.CalcularDevolucion(
  const AEntrada: TEntradaTotalesCobro;
  var AResultado: TResultadoTotalesCobro);
var
  dDevueltoPorFormas: Currency;
  dImporteADevolver: Currency;
  dRestante: Currency;
begin
  AResultado.ImporteEntregado := 0;
  AResultado.ImporteCambio := 0;
  dImporteADevolver := Abs(AResultado.ImporteTotalPagar);
  dDevueltoPorFormas := 0;
  if AEntrada.TotalEntregado < -0.001 then
    dDevueltoPorFormas := Abs(AEntrada.TotalEntregado);
  dRestante := dImporteADevolver - dDevueltoPorFormas;
  if dRestante <= 0 then
  begin
    AResultado.ImporteValeEmitido := 0;
    AResultado.ImportePendiente := 0;
  end
  else if AEntrada.ImporteValeEmitido >= dRestante then
    AResultado.ImportePendiente := 0
  else
    AResultado.ImportePendiente :=
      dRestante - AEntrada.ImporteValeEmitido;
end;

class procedure TCalculadorFaseCobro.CalcularVenta(
  const AEntrada: TEntradaTotalesCobro;
  var AResultado: TResultadoTotalesCobro);
var
  dCambioCalculado: Currency;
begin
  AResultado.ImporteEntregado :=
    AEntrada.TotalEntregado + AEntrada.TotalValesRecogidos;
  if AResultado.ImporteEntregado >=
     AResultado.ImporteTotalPagar - 0.001 then
  begin
    AResultado.ImportePendiente := 0;
    dCambioCalculado := AResultado.ImporteEntregado -
      AResultado.ImporteTotalPagar;
    if Abs(dCambioCalculado) < 0.01 then
      dCambioCalculado := 0;
    if dCambioCalculado > AEntrada.TotalEntregadoConCambio then
    begin
      AResultado.ImporteCambio := AEntrada.TotalEntregadoConCambio;
      AResultado.ImporteValeEmitido :=
        dCambioCalculado - AEntrada.TotalEntregadoConCambio;
    end
    else
    begin
      AResultado.ImporteCambio := dCambioCalculado;
      AResultado.ImporteValeEmitido := 0;
    end;
  end
  else
  begin
    AResultado.ImportePendiente := AResultado.ImporteTotalPagar -
      AResultado.ImporteEntregado - AEntrada.ImporteDejarCuenta;
    if Abs(AResultado.ImportePendiente) < 0.01 then
      AResultado.ImportePendiente := 0;
    AResultado.ImporteCambio := 0;
    AResultado.ImporteValeEmitido := 0;
  end;
end;

class function TCalculadorFaseCobro.CalcularTotales(
  const AEntrada: TEntradaTotalesCobro): TResultadoTotalesCobro;
var
  dBase: Currency;
begin
  Result := Default(TResultadoTotalesCobro);
  dBase := AEntrada.ImporteBruto - AEntrada.DescuentoLineal;
  Result.ImporteDescuentoGlobal := CalcularDescuento(
    dBase,
    AEntrada.PorcentajeDescuento);
  Result.ImporteTotalPagar := dBase - Result.ImporteDescuentoGlobal;
  Result.ImporteValeRecogido := AEntrada.TotalValesRecogidos;
  Result.ImporteValeEmitido := AEntrada.ImporteValeEmitido;
  if Result.ImporteTotalPagar < -0.001 then
    CalcularDevolucion(AEntrada, Result)
  else
    CalcularVenta(AEntrada, Result);
end;

class function TCalculadorCobroParcial.EsDepositoPendiente(
  const ALinea: TLineaCobroParcial): Boolean;
begin
  Result := (ALinea.VieneDeDeposito = 'S') and
    (ALinea.AccionDeposito = 'COBRAR') and
    (ALinea.Total > 0);
end;

class function TCalculadorCobroParcial.EsPrendaNueva(
  const ALinea: TLineaCobroParcial): Boolean;
begin
  Result := (ALinea.VieneDeDeposito <> 'S') and
    (ALinea.VieneDeDeposito <> 'A') and
    ((ALinea.AccionDeposito = 'COBRAR') or
     (ALinea.AccionDeposito = '')) and
    (ALinea.Total > 0);
end;

class procedure TCalculadorCobroParcial.MarcarAbonoParaEliminar(
  var ALineas: TArray<TLineaCobroParcial>;
  const AIdDeposito: string);
var
  bEncontrado: Boolean;
  i: Integer;
begin
  bEncontrado := False;
  i := 0;
  while (i <= High(ALineas)) and not bEncontrado do
  begin
    if (Trim(AIdDeposito) <> '') and
       (ALineas[i].VieneDeDeposito = 'A') and
       (ALineas[i].IdDeposito = AIdDeposito) then
    begin
      ALineas[i].Eliminar := True;
      bEncontrado := True;
    end;
    Inc(i);
  end;
end;

class procedure TCalculadorCobroParcial.ConvertirEnDeposito(
  var ALineas: TArray<TLineaCobroParcial>;
  AIndice: Integer;
  var ADineroDisponible: Currency);
var
  dDineroReal: Currency;
  dTotal: Currency;
begin
  dTotal := ALineas[AIndice].Total;
  dDineroReal := ADineroDisponible + ALineas[AIndice].AnticipoPrevio;
  if dDineroReal >= dTotal then
    ADineroDisponible := ADineroDisponible -
      (dTotal - ALineas[AIndice].AnticipoPrevio)
  else
  begin
    if ALineas[AIndice].VieneDeDeposito = 'S' then
      ALineas[AIndice].AccionDeposito := 'AUMENTAR_DEP'
    else
      ALineas[AIndice].AccionDeposito := 'NUEVO_DEP';
    if Pos('Abono ', ALineas[AIndice].Descripcion) <> 1 then
      ALineas[AIndice].Descripcion :=
        'Abono a cuenta ' + ALineas[AIndice].Descripcion;
    ALineas[AIndice].PrecioOriginal := dTotal;
    ALineas[AIndice].PrecioSalida := ADineroDisponible;
    ALineas[AIndice].PrecioConIva := ADineroDisponible;
    if ALineas[AIndice].PorcentajeIva = 0 then
      ALineas[AIndice].PrecioSinIva := ADineroDisponible
    else
      ALineas[AIndice].PrecioSinIva := ADineroDisponible /
        (1 + (ALineas[AIndice].PorcentajeIva / 100));
    ALineas[AIndice].TotalSinIva := ALineas[AIndice].PrecioSinIva;
    ALineas[AIndice].Total := ADineroDisponible;
    ALineas[AIndice].Modificada := True;
    MarcarAbonoParaEliminar(ALineas, ALineas[AIndice].IdDeposito);
    ADineroDisponible := 0;
  end;
end;

class procedure TCalculadorCobroParcial.ProcesarDepositosPendientes(
  var ALineas: TArray<TLineaCobroParcial>;
  var ADineroDisponible: Currency);
var
  i: Integer;
begin
  for i := 0 to High(ALineas) do
  begin
    if EsDepositoPendiente(ALineas[i]) then
      ConvertirEnDeposito(ALineas, i, ADineroDisponible);
  end;
end;

class procedure TCalculadorCobroParcial.ProcesarPrendasNuevas(
  var ALineas: TArray<TLineaCobroParcial>;
  var ADineroDisponible: Currency);
var
  i: Integer;
begin
  for i := 0 to High(ALineas) do
  begin
    if EsPrendaNueva(ALineas[i]) then
    begin
      if ADineroDisponible > 0 then
        ConvertirEnDeposito(ALineas, i, ADineroDisponible)
      else
      begin
        ALineas[i].AccionDeposito := 'NUEVO_DEP';
        ALineas[i].PrecioOriginal := ALineas[i].Total;
        ALineas[i].PrecioSalida := 0;
        ALineas[i].PrecioConIva := 0;
        ALineas[i].PrecioSinIva := 0;
        ALineas[i].TotalSinIva := 0;
        ALineas[i].Total := 0;
        ALineas[i].Modificada := True;
      end;
    end;
  end;
end;

class function TCalculadorCobroParcial.CalcularDineroDisponible(
  const ALineas: TArray<TLineaCobroParcial>;
  ADineroEntregado: Currency): Currency;
var
  i: Integer;
begin
  Result := ADineroEntregado;
  for i := 0 to High(ALineas) do
  begin
    if (ALineas[i].Total < 0) and
       (ALineas[i].VieneDeDeposito <> 'A') then
      Result := Result - ALineas[i].Total;
    if (ALineas[i].VieneDeDeposito = 'S') and
       (ALineas[i].AccionDeposito = 'CANCELAR') and
       (ALineas[i].AnticipoPrevio > 0) then
      Result := Result + ALineas[i].AnticipoPrevio;
  end;
end;

class procedure TCalculadorCobroParcial.Transformar(
  var ALineas: TArray<TLineaCobroParcial>;
  ADineroEntregado: Currency);
var
  dDineroDisponible: Currency;
begin
  dDineroDisponible := CalcularDineroDisponible(
    ALineas,
    ADineroEntregado);
  ProcesarDepositosPendientes(ALineas, dDineroDisponible);
  ProcesarPrendasNuevas(ALineas, dDineroDisponible);
end;

end.
