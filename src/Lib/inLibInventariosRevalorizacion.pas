{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventariosRevalorizacion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Calcula la simulación de apreciación o depreciación del PMP de las líneas }
{    de un inventario, sin VCL, datasets ni persistencia.                      }
{******************************************************************************}
unit inLibInventariosRevalorizacion;

interface

type
  TTipoRevalorizacionInventario = (
    triApreciacion,
    triDepreciacion
  );

  TLineaBaseRevalorizacionInventario = record
    Linea: string;
    CodigoArticulo: string;
    CodigoUnidad: string;
    Descripcion: string;
    CantidadTeorica: Currency;
    CantidadFisica: Currency;
    PrecioMedioActual: Currency;
    PrecioMedioNuevoAnterior: Currency;
    EsPrecioMedioCorregido: Boolean;
  end;

  TLineasBaseRevalorizacionInventario =
    array of TLineaBaseRevalorizacionInventario;

  TLineaSimulacionRevalorizacionInventario = record
    Base: TLineaBaseRevalorizacionInventario;
    PrecioMedioNuevo: Currency;
    ValorAnterior: Currency;
    ValorNuevo: Currency;
    DiferenciaUnidades: Currency;
    DiferenciaValor: Currency;
  end;

  TLineasSimulacionRevalorizacionInventario =
    array of TLineaSimulacionRevalorizacionInventario;

  TResumenSimulacionRevalorizacionInventario = record
    NumeroLineas: Integer;
    LineasConDiferenciaUnidades: Integer;
    LineasConPrecioCorregido: Integer;
    CantidadTeorica: Currency;
    CantidadFisica: Currency;
    ValorAnterior: Currency;
    ValorNuevo: Currency;
    DiferenciaValor: Currency;
  end;

  TSimulacionRevalorizacionInventario = record
    Tipo: TTipoRevalorizacionInventario;
    Porcentaje: Currency;
    Lineas: TLineasSimulacionRevalorizacionInventario;
    Resumen: TResumenSimulacionRevalorizacionInventario;
  end;

function PorcentajeRevalorizacionValido(
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Boolean;
function CalcularPrecioMedioRevalorizado(
  APrecioMedioActual: Currency;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Currency;
function SimularRevalorizacionInventario(
  const ALineas: TLineasBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): TSimulacionRevalorizacionInventario;

implementation

uses
  System.Math,
  System.SysUtils;

function PorcentajeRevalorizacionValido(
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Boolean;
begin
  Result := APorcentaje > 0;
  if ATipo = triDepreciacion then
    Result := Result and (APorcentaje <= 100);
end;

function CalcularPrecioMedioRevalorizado(
  APrecioMedioActual: Currency;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Currency;
var
  Factor: Extended;
begin
  if not PorcentajeRevalorizacionValido(ATipo, APorcentaje) then
    raise EArgumentOutOfRangeException.Create('APorcentaje');
  Factor := 1;
  if ATipo = triApreciacion then
    Factor := Factor + (Extended(APorcentaje) / 100)
  else
    Factor := Factor - (Extended(APorcentaje) / 100);
  Result := Currency(SimpleRoundTo(
    Extended(APrecioMedioActual) * Factor, -4));
end;

function CrearLineaSimulada(
  const ALinea: TLineaBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): TLineaSimulacionRevalorizacionInventario;
begin
  Result.Base := ALinea;
  Result.PrecioMedioNuevo := CalcularPrecioMedioRevalorizado(
    ALinea.PrecioMedioActual, ATipo, APorcentaje);
  Result.ValorAnterior :=
    ALinea.CantidadTeorica * ALinea.PrecioMedioActual;
  Result.ValorNuevo :=
    ALinea.CantidadFisica * Result.PrecioMedioNuevo;
  Result.DiferenciaUnidades :=
    ALinea.CantidadFisica - ALinea.CantidadTeorica;
  Result.DiferenciaValor :=
    Result.ValorNuevo - Result.ValorAnterior;
end;

procedure AcumularLineaEnResumen(
  const ALinea: TLineaSimulacionRevalorizacionInventario;
  var AResumen: TResumenSimulacionRevalorizacionInventario);
begin
  Inc(AResumen.NumeroLineas);
  AResumen.CantidadTeorica :=
    AResumen.CantidadTeorica + ALinea.Base.CantidadTeorica;
  AResumen.CantidadFisica :=
    AResumen.CantidadFisica + ALinea.Base.CantidadFisica;
  AResumen.ValorAnterior :=
    AResumen.ValorAnterior + ALinea.ValorAnterior;
  AResumen.ValorNuevo := AResumen.ValorNuevo + ALinea.ValorNuevo;
  AResumen.DiferenciaValor :=
    AResumen.DiferenciaValor + ALinea.DiferenciaValor;
  if ALinea.DiferenciaUnidades <> 0 then
    Inc(AResumen.LineasConDiferenciaUnidades);
  if ALinea.Base.EsPrecioMedioCorregido then
    Inc(AResumen.LineasConPrecioCorregido);
end;

function SimularRevalorizacionInventario(
  const ALineas: TLineasBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): TSimulacionRevalorizacionInventario;
var
  iLinea: Integer;
begin
  if not PorcentajeRevalorizacionValido(ATipo, APorcentaje) then
    raise EArgumentOutOfRangeException.Create('APorcentaje');
  Result := Default(TSimulacionRevalorizacionInventario);
  Result.Tipo := ATipo;
  Result.Porcentaje := APorcentaje;
  SetLength(Result.Lineas, Length(ALineas));
  for iLinea := 0 to High(ALineas) do
  begin
    Result.Lineas[iLinea] := CrearLineaSimulada(
      ALineas[iLinea], ATipo, APorcentaje);
    AcumularLineaEnResumen(
      Result.Lineas[iLinea], Result.Resumen);
  end;
end;

end.
