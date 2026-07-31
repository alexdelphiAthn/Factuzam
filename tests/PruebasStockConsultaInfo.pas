{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasStockConsultaInfo                                      }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del resumen de cabecera de la consulta de stock.                  }
{******************************************************************************}
unit PruebasStockConsultaInfo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasStockConsultaInfo = class
  public
    [Test]
    procedure Propiedades_FormateaListaBooleanoYTexto;
    [Test]
    procedure Tarifas_DestacaLaPredeterminada;
    [Test]
    procedure Proveedores_OcultaOMuestraElCoste;
  end;

implementation

uses
  System.SysUtils,
  inLibStockConsultaInfo;

procedure TPruebasStockConsultaInfo.
  Propiedades_FormateaListaBooleanoYTexto;
var
  Info: TInfoCabeceraStock;
  sTexto: string;
begin
  Info := Default(TInfoCabeceraStock);
  SetLength(Info.Propiedades, 3);
  Info.Propiedades[0].Nombre := 'Material';
  Info.Propiedades[0].TipoValor := 'LISTA';
  Info.Propiedades[0].ValorLista := 'Algodón';
  Info.Propiedades[1].Nombre := 'Lavable';
  Info.Propiedades[1].TipoValor := 'BOOLEANO';
  Info.Propiedades[1].ValorLibre := 'S';
  Info.Propiedades[2].Nombre := 'Nota';
  Info.Propiedades[2].TipoValor := 'TEXTO';
  Info.Propiedades[2].ValorLibre := 'Ligero';
  sTexto := FormatearInfoCabeceraStock(Info, 'PVP', False);
  Assert.IsTrue(Pos('Material: Algodón', sTexto) > 0);
  Assert.IsTrue(Pos('Lavable: Sí', sTexto) > 0);
  Assert.IsTrue(Pos('Nota: Ligero', sTexto) > 0);
end;

procedure TPruebasStockConsultaInfo.Tarifas_DestacaLaPredeterminada;
var
  Info: TInfoCabeceraStock;
  sTexto: string;
begin
  Info := Default(TInfoCabeceraStock);
  SetLength(Info.Tarifas, 1);
  Info.Tarifas[0].Codigo := 'PVP';
  Info.Tarifas[0].Nombre := 'Venta';
  Info.Tarifas[0].PrecioFinal := 25;
  sTexto := FormatearInfoCabeceraStock(Info, 'PVP', False);
  Assert.IsTrue(Pos('Tarifa por defecto - Venta', sTexto) > 0);
end;

procedure TPruebasStockConsultaInfo.Proveedores_OcultaOMuestraElCoste;
var
  Info: TInfoCabeceraStock;
  sConCoste: string;
  sCoste: string;
  sSinCoste: string;
begin
  Info := Default(TInfoCabeceraStock);
  SetLength(Info.Proveedores, 1);
  Info.Proveedores[0].Codigo := 'P1';
  Info.Proveedores[0].RazonSocial := 'Proveedor Uno';
  Info.Proveedores[0].Referencia := 'R-1';
  Info.Proveedores[0].PrecioUltimaCompra := 10;
  Info.Proveedores[0].EsPrincipal := True;
  sCoste := FormatFloat('#,##0.00', 10);
  sSinCoste := FormatearInfoCabeceraStock(Info, 'PVP', False);
  sConCoste := FormatearInfoCabeceraStock(Info, 'PVP', True);
  Assert.IsTrue(Pos('Proveedor ppal. - Proveedor Uno (ref R-1)',
                    sSinCoste) > 0);
  Assert.IsFalse(Pos(sCoste, sSinCoste) > 0);
  Assert.IsTrue(Pos(sCoste, sConCoste) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaInfo);

end.
