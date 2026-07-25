{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoFalsoTests                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del doble en memoria TEscritorHojaCalculoFalso. Verifican que     }
{    registra fielmente lo que recibe por los puertos (contrato que usarán     }
{    las pruebas de snapshot de los exportadores en Fase 2).                   }
{******************************************************************************}
unit inLibHojaCalculoFalsoTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasHojaCalculoFalso = class
  private
    FFalso: TObject;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure NuevaHoja_RegistraNombreYLimpia;
    [Test]
    procedure Escribir_RegistraValorNegritaYAlineacion;
    [Test]
    procedure EscribirFormula_MarcaFormulaYFormato;
    [Test]
    procedure Combinar_SeRegistra;
    [Test]
    procedure DibujarCuadro_SeRegistra;
    [Test]
    procedure Guardar_RecuerdaRuta;
    [Test]
    procedure Lectura_UltimaFilaYColumna;
    [Test]
    procedure Lectura_CeldaVaciaEsNula;
    [Test]
    procedure Precargar_PermiteLeer;
  end;

implementation

uses
  System.SysUtils, System.Variants, inLibHojaCalculoIntf,
  inLibHojaCalculoFalso;

procedure TPruebasHojaCalculoFalso.Preparar;
begin
  FFalso := TEscritorHojaCalculoFalso.Create;
end;

procedure TPruebasHojaCalculoFalso.Limpiar;
begin
  FreeAndNil(FFalso);
end;

procedure TPruebasHojaCalculoFalso.NuevaHoja_RegistraNombreYLimpia;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.Escribir(0, 0, 'viejo');
  oFalso.NuevaHoja('Inventario');
  Assert.AreEqual('Inventario', oFalso.HojaActual);
  Assert.AreEqual(1, oFalso.NumHojas);
  Assert.IsFalse(oFalso.TieneCelda(0, 0));
end;

procedure TPruebasHojaCalculoFalso.Escribir_RegistraValorNegritaYAlineacion;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.Escribir(2, 3, 'Hola', True, acDerecha);
  Assert.AreEqual('Hola', VarToStr(oFalso.Valor(2, 3)));
  Assert.IsTrue(oFalso.EsNegrita(2, 3));
  Assert.AreEqual(Ord(acDerecha), Ord(oFalso.Alineacion(2, 3)));
end;

procedure TPruebasHojaCalculoFalso.EscribirFormula_MarcaFormulaYFormato;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.EscribirFormula(4, 1, '=SUMA(A1;A2)', '#,##0.00');
  Assert.IsTrue(oFalso.EsFormula(4, 1));
  Assert.AreEqual('=SUMA(A1;A2)', oFalso.Formula(4, 1));
  Assert.AreEqual('#,##0.00', oFalso.Formato(4, 1));
end;

procedure TPruebasHojaCalculoFalso.Combinar_SeRegistra;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.Combinar(0, 0, 1, 4);
  Assert.AreEqual(1, oFalso.NumCombinaciones);
end;

procedure TPruebasHojaCalculoFalso.DibujarCuadro_SeRegistra;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.DibujarCuadro(1, 1, 5, 8, ebFino);
  Assert.AreEqual(1, oFalso.NumCuadros);
end;

procedure TPruebasHojaCalculoFalso.Guardar_RecuerdaRuta;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.Guardar('C:\temp\salida.xlsx');
  Assert.AreEqual('C:\temp\salida.xlsx', oFalso.RutaGuardada);
end;

procedure TPruebasHojaCalculoFalso.Lectura_UltimaFilaYColumna;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.Escribir(5, 2, 10);
  oFalso.Escribir(1, 7, 20);
  Assert.AreEqual(5, oFalso.UltimaFila);
  Assert.AreEqual(7, oFalso.UltimaColumna);
end;

procedure TPruebasHojaCalculoFalso.Lectura_CeldaVaciaEsNula;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  Assert.IsTrue(VarIsNull(oFalso.LeerCelda(9, 9)));
end;

procedure TPruebasHojaCalculoFalso.Precargar_PermiteLeer;
var
  oFalso: TEscritorHojaCalculoFalso;
begin
  oFalso := TEscritorHojaCalculoFalso(FFalso);
  oFalso.Precargar(3, 3, 'X');
  Assert.AreEqual('X', VarToStr(oFalso.LeerCelda(3, 3)));
end;

end.
