{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRepositoriosPantallaComposicion                       }
{    Tipo:       Pruebas                                                      }
{ Versión:       1.0.0                                                        }
{   Fecha:       03/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.    }
{                                                                              }
{  Descripción:                                                               }
{    Verifica que los adaptadores generales y de caja estén segregados.       }
{******************************************************************************}
unit PruebasRepositoriosPantallaComposicion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRepositoriosPantallaComposicion = class
  public
    [Test]
    procedure General_NoImplementaLasSeisFamiliasExtraidas;
    [Test]
    procedure Caja_YTicketsPublicanCapacidadesSeparadas;
  end;

implementation

uses
  System.SysUtils, inLibRepositoriosPantallaIntf,
  UniDataRepositoriosCajaPantalla,
  UniDataRepositoriosGeneralesPantalla,
  UniDataRepositoriosTicketsCajaPantalla;

procedure TPruebasRepositoriosPantallaComposicion.
  General_NoImplementaLasSeisFamiliasExtraidas;
var
  oAdaptador: IInterface;
begin
  oAdaptador := TAdaptadorRepositoriosPantallaUniDAC.Create(nil, nil, nil);
  Assert.IsFalse(Supports(oAdaptador, IRepositoriosArticulosPantalla));
  Assert.IsFalse(Supports(oAdaptador, IRepositoriosConfiguracionPantalla));
  Assert.IsFalse(Supports(oAdaptador, IRepositoriosDocumentosPantalla));
  Assert.IsFalse(Supports(oAdaptador, IRepositoriosRemesasPantalla));
  Assert.IsFalse(Supports(oAdaptador, IRepositoriosOperacionesPantalla));
  Assert.IsFalse(Supports(oAdaptador, IRepositoriosVentasPantalla));
end;

procedure TPruebasRepositoriosPantallaComposicion.
  Caja_YTicketsPublicanCapacidadesSeparadas;
var
  oCaja: IRepositoriosCajaPantalla;
  oTickets: IRepositoriosTicketsCajaPantalla;
begin
  oCaja := TRepositoriosCajaPantallaUniDAC.Create(nil, nil, nil);
  oTickets := TRepositoriosTicketsCajaPantallaUniDAC.Create(
    nil, nil, nil, nil, nil, nil, nil);
  Assert.IsFalse(Supports(oCaja, IRepositoriosTicketsCajaPantalla));
  Assert.IsFalse(Supports(oTickets, IRepositoriosCajaPantalla));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasRepositoriosPantallaComposicion);

end.
