{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaSubsanacion                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Valida y reparte importes de una subsanación de caja sin modificar datos. }
{******************************************************************************}
unit inLibCajaSubsanacion;

interface

type
  TLineaSubsanacionCaja = record
    Numero: string;
    Descripcion: string;
    Cantidad: Double;
    ImporteOriginal: Currency;
    Importe: Currency;
  end;
  TLineasSubsanacionCaja = TArray<TLineaSubsanacionCaja>;

function TotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja): Currency;
procedure ValidarImportesSubsanacion(
  const ALineas: TLineasSubsanacionCaja);
function RepartirTotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja;
  ATotal: Currency): TLineasSubsanacionCaja;
function CalcularPrecioSubsanacion(
  const ALinea: TLineaSubsanacionCaja): Currency;

implementation

uses
  System.Math, System.SysUtils,
  inLibMsgSubsanacionCaja;

function TieneDecimalesDeCentimo(AImporte: Currency): Boolean;
var
  iDiezmilesimas: Int64;
begin
  // Currency almacena diezmilésimas; el módulo evita errores binarios.
  Move(AImporte, iDiezmilesimas, SizeOf(iDiezmilesimas));
  Result := (iDiezmilesimas mod 100) <> 0;
end;

procedure ValidarImporteLinea(const ALinea: TLineaSubsanacionCaja);
begin
  if IsNan(ALinea.Cantidad) or IsInfinite(ALinea.Cantidad) then
    raise EArgumentException.CreateFmt(
      SSubsanacionCantidadInvalida, [ALinea.Numero]);
  if TieneDecimalesDeCentimo(ALinea.Importe) then
    raise EArgumentException.CreateFmt(
      SSubsanacionDecimalesLinea, [ALinea.Numero]);
  if (ALinea.Cantidad = 0) and (ALinea.Importe <> 0) then
    raise EArgumentException.CreateFmt(
      SSubsanacionCantidadCero, [ALinea.Numero]);
  if ((ALinea.Cantidad > 0) and (ALinea.Importe < 0)) or
     ((ALinea.Cantidad < 0) and (ALinea.Importe > 0)) then
    raise EArgumentException.CreateFmt(
      SSubsanacionSignoLinea, [ALinea.Numero]);
end;

function CalcularPrecioSubsanacion(
  const ALinea: TLineaSubsanacionCaja): Currency;
var
  dImporteReconstruido: Currency;
begin
  ValidarImporteLinea(ALinea);
  Result := 0;
  if ALinea.Cantidad <> 0 then
  begin
    Result := ALinea.Importe / ALinea.Cantidad;
    dImporteReconstruido := SimpleRoundTo(
      Result * ALinea.Cantidad, -2);
    if dImporteReconstruido <> ALinea.Importe then
      raise EArgumentException.CreateFmt(
        SSubsanacionPrecisionLinea, [ALinea.Numero]);
  end;
end;

function TotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja): Currency;
var
  rLinea: TLineaSubsanacionCaja;
begin
  Result := 0;
  for rLinea in ALineas do
    Result := Result + rLinea.Importe;
end;

procedure ValidarImportesSubsanacion(
  const ALineas: TLineasSubsanacionCaja);
var
  rLinea: TLineaSubsanacionCaja;
begin
  if Length(ALineas) = 0 then
    raise EArgumentException.Create(SSubsanacionSinLineas);
  for rLinea in ALineas do
    CalcularPrecioSubsanacion(rLinea);
end;

procedure RepartirDesdeCero(var ALineas: TLineasSubsanacionCaja;
  ATotal: Currency);
var
  i: Integer;
  iLineaConCantidad: Integer;
  iLineasConCantidad: Integer;
begin
  iLineaConCantidad := -1;
  iLineasConCantidad := 0;
  for i := 0 to High(ALineas) do
  begin
    if ALineas[i].Cantidad <> 0 then
    begin
      iLineaConCantidad := i;
      Inc(iLineasConCantidad);
    end;
  end;
  if iLineasConCantidad <> 1 then
    raise EArgumentException.Create(SSubsanacionTotalInicialCero);
  ALineas[iLineaConCantidad].Importe := ATotal;
end;

procedure RepartirProporcionalmente(var ALineas: TLineasSubsanacionCaja;
  ATotalActual, ATotalNuevo: Currency);
var
  i: Integer;
  dBaseAcumulada: Currency;
  dImporteAcumulado: Currency;
  dImporteHastaLinea: Currency;
begin
  if ((ATotalActual > 0) and (ATotalNuevo < 0)) or
     ((ATotalActual < 0) and (ATotalNuevo > 0)) then
    raise EArgumentException.Create(SSubsanacionSignoTotal);
  dBaseAcumulada := 0;
  dImporteAcumulado := 0;
  for i := 0 to High(ALineas) do
  begin
    dBaseAcumulada := dBaseAcumulada + ALineas[i].Importe;
    // Redondear acumulados conserva céntimos y el signo de cada línea.
    if i = High(ALineas) then
      dImporteHastaLinea := ATotalNuevo
    else
      dImporteHastaLinea := SimpleRoundTo(
        ATotalNuevo * (dBaseAcumulada / ATotalActual), -2);
    ALineas[i].Importe := dImporteHastaLinea - dImporteAcumulado;
    dImporteAcumulado := dImporteHastaLinea;
  end;
end;

function RepartirTotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja;
  ATotal: Currency): TLineasSubsanacionCaja;
var
  dTotalActual: Currency;
begin
  ValidarImportesSubsanacion(ALineas);
  if TieneDecimalesDeCentimo(ATotal) then
    raise EArgumentException.Create(SSubsanacionDecimalesTotal);
  Result := Copy(ALineas);
  dTotalActual := TotalSubsanacion(ALineas);
  if dTotalActual = 0 then
    RepartirDesdeCero(Result, ATotal)
  else
    RepartirProporcionalmente(Result, dTotalActual, ATotal);
  ValidarImportesSubsanacion(Result);
end;

end.
