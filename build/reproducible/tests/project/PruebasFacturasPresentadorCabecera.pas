{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasPresentadorCabecera                            }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza el bloqueo de controles de la cabecera de factura.            }
{******************************************************************************}
unit PruebasFacturasPresentadorCabecera;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasPresentadorCabecera = class
  public
    [Test]
    procedure Navegando_HabilitaNuevaYRectificar;
    [Test]
    procedure Navegando_DelegaImprimirYConsolidarEnLaFaseFiscal;
    [Test]
    procedure Insertando_PermiteTeclearNumeroYSerie;
    [Test]
    procedure Insertando_BloqueaLasAccionesDeDocumento;
    [Test]
    procedure Editando_BloqueaNumeroSerieTarifaYCanal;
    [Test]
    procedure EdicionSinVerifactu_PermiteImprimir;
    [Test]
    procedure EdicionConVerifactu_NoPermiteImprimir;
  end;

implementation

uses
  inLibFacturasPresentadorCabecera;

procedure TPruebasFacturasPresentadorCabecera.
  Navegando_HabilitaNuevaYRectificar;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfNavegando, False));
  Assert.IsFalse(Controles.EnEdicion);
  Assert.IsTrue(Controles.PuedeNuevaFactura);
  Assert.IsTrue(Controles.PuedeRectificar);
end;

procedure TPruebasFacturasPresentadorCabecera.
  Navegando_DelegaImprimirYConsolidarEnLaFaseFiscal;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfNavegando, True));
  Assert.IsTrue(Controles.RevisarFaseFiscal);
  Assert.IsFalse(Controles.NumeroSerieEditables);
  Assert.IsTrue(Controles.BloquearTarifaCanal);
end;

procedure TPruebasFacturasPresentadorCabecera.
  Insertando_PermiteTeclearNumeroYSerie;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfInsertando, False));
  Assert.IsTrue(Controles.NumeroSerieEditables);
  Assert.IsFalse(Controles.BloquearTarifaCanal);
end;

procedure TPruebasFacturasPresentadorCabecera.
  Insertando_BloqueaLasAccionesDeDocumento;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfInsertando, False));
  Assert.IsTrue(Controles.EnEdicion);
  Assert.IsFalse(Controles.PuedeNuevaFactura);
  Assert.IsFalse(Controles.PuedeRectificar);
  Assert.IsFalse(Controles.PuedeConsolidar);
  Assert.IsFalse(Controles.RevisarFaseFiscal);
end;

procedure TPruebasFacturasPresentadorCabecera.
  Editando_BloqueaNumeroSerieTarifaYCanal;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfEditando, False));
  Assert.IsFalse(Controles.NumeroSerieEditables);
  Assert.IsTrue(Controles.BloquearTarifaCanal);
  Assert.IsTrue(Controles.EnEdicion);
end;

procedure TPruebasFacturasPresentadorCabecera.
  EdicionSinVerifactu_PermiteImprimir;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfEditando, True));
  Assert.IsTrue(Controles.PuedeImprimir);
end;

procedure TPruebasFacturasPresentadorCabecera.
  EdicionConVerifactu_NoPermiteImprimir;
var
  Controles: TControlesCabeceraFactura;
begin
  Controles := CalcularControlesCabeceraFactura(
    CrearSituacionCabeceraFactura(ecfEditando, False));
  Assert.IsFalse(Controles.PuedeImprimir);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasFacturasPresentadorCabecera);

end.
