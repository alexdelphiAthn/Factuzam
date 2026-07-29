{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMotorFiscalVenta                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Núcleo puro para calcular bases, impuestos y retenciones de venta.        }
{******************************************************************************}
unit inLibMotorFiscalVenta;

interface

uses
  System.SysUtils;

type
  TLineaMotorFiscalVenta = record
    TipoIva: string;
    Base: Double;
    TotalConIva: Double;
    PorcentajeIva: Double;
    PorcentajeRecargo: Double;
    Bruto: Double;
    Descuento: Double;
    Cantidad: Double;
    ImpuestosIncluidos: Boolean;
  end;

  TLineasMotorFiscalVenta = TArray<TLineaMotorFiscalVenta>;

  TConfiguracionMotorFiscalVenta = record
    RedondearPorLinea: Boolean;
    CalcularIvaIncluidoPorDiferencia: Boolean;
    AplicaRecargo: Boolean;
    AplicaRetencion: Boolean;
    EsFacturaSimplificada: Boolean;
    ClienteConDatosFiscales: Boolean;
    RetencionIncluyeImpuestos: Boolean;
    PorcentajeRetencion: Double;
  end;

  TResultadoTipoIvaVenta = record
    Base: Double;
    PorcentajeIva: Double;
    ImporteIva: Double;
    PorcentajeRecargo: Double;
    ImporteRecargo: Double;
  end;

  TResultadoMotorFiscalVenta = record
    Normal: TResultadoTipoIvaVenta;
    Reducido: TResultadoTipoIvaVenta;
    SuperReducido: TResultadoTipoIvaVenta;
    Exento: TResultadoTipoIvaVenta;
    TotalBases: Double;
    TotalIva: Double;
    TotalRecargo: Double;
    TotalImpuestos: Double;
    TotalRetencion: Double;
    TotalConImpuestos: Double;
    TotalLiquido: Double;
    TotalBruto: Double;
    TotalDescuentos: Double;
    TotalCantidades: Double;
    TieneImportesNegativos: Boolean;
  end;

function CalcularTotalesMotorFiscalVenta(
  const ALineas: TLineasMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta):
  TResultadoMotorFiscalVenta;

implementation

uses
  System.Math;

function NormalizarTipoIvaMotor(const ATipoIva: string): string;
begin
  if SameText(Trim(ATipoIva), 'R') then
    Result := 'R'
  else if SameText(Trim(ATipoIva), 'S') then
    Result := 'S'
  else if SameText(Trim(ATipoIva), 'E') then
    Result := 'E'
  else
    Result := 'N';
end;

function RedondearImporteMotor(
  AImporte: Double;
  ARedondear: Boolean): Double;
begin
  Result := AImporte;
  if ARedondear then
    Result := SimpleRoundTo(AImporte, -2);
end;

procedure AcumularTipoIva(
  var AResultado: TResultadoTipoIvaVenta;
  const ALinea: TLineaMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  Base: Double;
  ImporteIva: Double;
  ImporteRecargo: Double;
  TotalConIva: Double;
  PuedeAplicarRecargo: Boolean;
begin
  Base := RedondearImporteMotor(
    ALinea.Base, AConfiguracion.RedondearPorLinea);
  TotalConIva := RedondearImporteMotor(
    ALinea.TotalConIva, AConfiguracion.RedondearPorLinea);
  if ALinea.ImpuestosIncluidos and
     AConfiguracion.CalcularIvaIncluidoPorDiferencia then
    ImporteIva := TotalConIva - Base
  else
    ImporteIva := Base * ALinea.PorcentajeIva / 100;
  ImporteIva := RedondearImporteMotor(
    ImporteIva, AConfiguracion.RedondearPorLinea);
  PuedeAplicarRecargo :=
    AConfiguracion.AplicaRecargo and
    not AConfiguracion.EsFacturaSimplificada and
    AConfiguracion.ClienteConDatosFiscales;
  ImporteRecargo := 0;
  if PuedeAplicarRecargo then
    ImporteRecargo :=
      Base * ALinea.PorcentajeRecargo / 100;
  ImporteRecargo := RedondearImporteMotor(
    ImporteRecargo, AConfiguracion.RedondearPorLinea);
  AResultado.Base := AResultado.Base + Base;
  AResultado.PorcentajeIva := ALinea.PorcentajeIva;
  AResultado.ImporteIva := AResultado.ImporteIva + ImporteIva;
  AResultado.PorcentajeRecargo := ALinea.PorcentajeRecargo;
  AResultado.ImporteRecargo :=
    AResultado.ImporteRecargo + ImporteRecargo;
end;

procedure AcumularLinea(
  var AResultado: TResultadoMotorFiscalVenta;
  const ALinea: TLineaMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  TipoIva: string;
begin
  TipoIva := NormalizarTipoIvaMotor(ALinea.TipoIva);
  if TipoIva = 'R' then
    AcumularTipoIva(AResultado.Reducido, ALinea, AConfiguracion)
  else if TipoIva = 'S' then
    AcumularTipoIva(AResultado.SuperReducido, ALinea, AConfiguracion)
  else if TipoIva = 'E' then
    AcumularTipoIva(AResultado.Exento, ALinea, AConfiguracion)
  else
    AcumularTipoIva(AResultado.Normal, ALinea, AConfiguracion);
  AResultado.TotalBruto := AResultado.TotalBruto + ALinea.Bruto;
  AResultado.TotalDescuentos :=
    AResultado.TotalDescuentos + ALinea.Descuento;
  AResultado.TotalCantidades :=
    AResultado.TotalCantidades + ALinea.Cantidad;
  if (ALinea.Base < 0) or (ALinea.Cantidad < 0) then
    AResultado.TieneImportesNegativos := True;
end;

procedure CalcularResumen(
  var AResultado: TResultadoMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  BaseRetencion: Double;
  PuedeAplicarRetencion: Boolean;
begin
  AResultado.TotalBases :=
    AResultado.Normal.Base +
    AResultado.Reducido.Base +
    AResultado.SuperReducido.Base +
    AResultado.Exento.Base;
  AResultado.TotalIva :=
    AResultado.Normal.ImporteIva +
    AResultado.Reducido.ImporteIva +
    AResultado.SuperReducido.ImporteIva +
    AResultado.Exento.ImporteIva;
  AResultado.TotalRecargo :=
    AResultado.Normal.ImporteRecargo +
    AResultado.Reducido.ImporteRecargo +
    AResultado.SuperReducido.ImporteRecargo +
    AResultado.Exento.ImporteRecargo;
  AResultado.TotalImpuestos :=
    AResultado.TotalIva + AResultado.TotalRecargo;
  PuedeAplicarRetencion :=
    AConfiguracion.AplicaRetencion and
    not AConfiguracion.EsFacturaSimplificada and
    AConfiguracion.ClienteConDatosFiscales;
  if PuedeAplicarRetencion then
  begin
    BaseRetencion := AResultado.TotalBases;
    if AConfiguracion.RetencionIncluyeImpuestos then
      BaseRetencion :=
        BaseRetencion + AResultado.TotalImpuestos;
    AResultado.TotalRetencion :=
      BaseRetencion * AConfiguracion.PorcentajeRetencion / 100;
  end;
  AResultado.TotalConImpuestos :=
    AResultado.TotalBases + AResultado.TotalImpuestos;
  AResultado.TotalLiquido :=
    AResultado.TotalConImpuestos - AResultado.TotalRetencion;
end;

function CalcularTotalesMotorFiscalVenta(
  const ALineas: TLineasMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta):
  TResultadoMotorFiscalVenta;
var
  Indice: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for Indice := Low(ALineas) to High(ALineas) do
    AcumularLinea(Result, ALineas[Indice], AConfiguracion);
  CalcularResumen(Result, AConfiguracion);
end;

end.
