{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasInteraccionFiltrosMto                                  }
{    Tipo:       Pruebas DUnitX                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Prueba la traduccion y el contrato de la interaccion VCL de filtros.      }
{******************************************************************************}
unit PruebasInteraccionFiltrosMto;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInteraccionFiltrosMto = class
  public
    [Test]
    procedure GuardadoAceptadoConservaDatos;
    [Test]
    procedure GuardadoCanceladoConservaEstado;
    [Test]
    procedure GestionAplicadaConservaFiltro;
    [Test]
    procedure GestionNoAplicadaConservaEstado;
    [Test]
    procedure ConstructorSinVistaFallaRapido;
  end;

implementation

uses
  System.SysUtils,
  inLibGestorFiltrosMto,
  inMtoGenPresentacionFiltrosVcl;

procedure TPruebasInteraccionFiltrosMto.GuardadoAceptadoConservaDatos;
var
  Datos: TDatosGuardadoFiltroMto;
begin
  Datos := CrearDatosGuardadoFiltroMto(
    True,
    'Pendientes',
    'Solo documentos pendientes');
  Assert.IsTrue(Datos.Aceptado);
  Assert.AreEqual('Pendientes', Datos.Nombre);
  Assert.AreEqual('Solo documentos pendientes', Datos.Descripcion);
end;

procedure TPruebasInteraccionFiltrosMto.GuardadoCanceladoConservaEstado;
var
  Datos: TDatosGuardadoFiltroMto;
begin
  Datos := CrearDatosGuardadoFiltroMto(False, '', '');
  Assert.IsFalse(Datos.Aceptado);
  Assert.AreEqual('', Datos.Nombre);
  Assert.AreEqual('', Datos.Descripcion);
end;

procedure TPruebasInteraccionFiltrosMto.GestionAplicadaConservaFiltro;
var
  Resultado: TResultadoGestionFiltroMto;
begin
  Resultado := CrearResultadoGestionFiltroMto(True, 'QUJD');
  Assert.IsTrue(Resultado.Aplicado);
  Assert.AreEqual('QUJD', Resultado.FiltroBase64);
end;

procedure TPruebasInteraccionFiltrosMto.
  GestionNoAplicadaConservaEstado;
var
  Resultado: TResultadoGestionFiltroMto;
begin
  Resultado := CrearResultadoGestionFiltroMto(False, '');
  Assert.IsFalse(Resultado.Aplicado);
  Assert.AreEqual('', Resultado.FiltroBase64);
end;

procedure TPruebasInteraccionFiltrosMto.
  ConstructorSinVistaFallaRapido;
var
  Interaccion: TInteraccionFiltrosMtoVcl;
  FalloEsperado: Boolean;
begin
  Interaccion := nil;
  FalloEsperado := False;
  try
    Interaccion := TInteraccionFiltrosMtoVcl.Create(
      nil,
      '',
      '',
      nil,
      nil);
  except
    on E: EArgumentNilException do
      FalloEsperado := True;
  end;
  Interaccion.Free;
  Assert.IsTrue(FalloEsperado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInteraccionFiltrosMto);

end.
