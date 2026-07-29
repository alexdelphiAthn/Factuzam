{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasServicios                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de resultados y validaciones de servicios de facturas.            }
{******************************************************************************}
unit PruebasFacturasServicios;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasServicios = class
  public
    [Test]
    procedure Borrado_BorradorSinCobrosPermitido;
    [Test]
    procedure Borrado_FacturaFiscalDenegada;
    [Test]
    procedure Borrado_EfectosCobradosDenegado;
    [Test]
    procedure Validacion_ConservaCampoYMensaje;
  end;

implementation

uses
  inLibFacturasServiciosIntf;

procedure TPruebasFacturasServicios.
  Borrado_BorradorSinCobrosPermitido;
var
  Resultado: TResultadoBorradoFactura;
begin
  Resultado := EvaluarBorradoFactura('BORRADOR', False);
  Assert.IsTrue(Resultado.Permitido);
  Assert.AreEqual('', Resultado.Mensaje);
end;

procedure TPruebasFacturasServicios.
  Borrado_FacturaFiscalDenegada;
var
  Resultado: TResultadoBorradoFactura;
begin
  Resultado := EvaluarBorradoFactura('REGISTRADA', False);
  Assert.IsFalse(Resultado.Permitido);
  Assert.IsNotEmpty(Resultado.Mensaje);
end;

procedure TPruebasFacturasServicios.
  Borrado_EfectosCobradosDenegado;
var
  Resultado: TResultadoBorradoFactura;
begin
  Resultado := EvaluarBorradoFactura('BORRADOR', True);
  Assert.IsFalse(Resultado.Permitido);
  Assert.IsNotEmpty(Resultado.Mensaje);
end;

procedure TPruebasFacturasServicios.
  Validacion_ConservaCampoYMensaje;
var
  Error: EValidacionFactura;
begin
  Error := EValidacionFactura.Create('NIF incorrecto', cvfNifCliente);
  try
    Assert.AreEqual(cvfNifCliente, Error.Campo);
    Assert.AreEqual('NIF incorrecto', Error.Message);
  finally
    Error.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasServicios);

end.
