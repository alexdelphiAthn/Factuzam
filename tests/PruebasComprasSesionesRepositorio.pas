{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComprasSesionesRepositorio                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica los casos de uso de compras con repositorio en memoria.          }
{******************************************************************************}
unit PruebasComprasSesionesRepositorio;

interface

uses
  DUnitX.TestFramework,
  inLibComprasSesiones,
  inLibComprasSesionesIntf,
  DoblesComprasSesiones;

type
  [TestFixture]
  TPruebasComprasSesionesRepositorio = class
  private
    FContrato: IRepositorioComprasSesiones;
    FRepositorio: TRepositorioComprasSesionesMemoria;
    FServicio: TServicioComprasSesiones;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Liberar;
    [Test]
    procedure ResolverDuplicadoNormalizaEntradas;
    [Test]
    procedure CalcularPrecioVentaConservaFormula;
    [Test]
    procedure ValidarSesionDevuelveTodasLasIncidencias;
    [Test]
    procedure MaterializarDelegaSinConexion;
    [Test]
    procedure RevertirDelegaSinConexion;
  end;

implementation

uses
  System.Classes, System.SysUtils,
  inLibComprasSesionesMaterializar;

procedure TPruebasComprasSesionesRepositorio.Preparar;
begin
  FRepositorio := TRepositorioComprasSesionesMemoria.Create;
  FContrato := FRepositorio;
  FServicio := TServicioComprasSesiones.Create(FContrato);
end;

procedure TPruebasComprasSesionesRepositorio.Liberar;
begin
  FreeAndNil(FServicio);
  FContrato := nil;
  FRepositorio := nil;
end;

procedure TPruebasComprasSesionesRepositorio.ResolverDuplicadoNormalizaEntradas;
var
  oEsperado: TResolverDuplicadoSesion;
  oResultado: TResolverDuplicadoSesion;
begin
  oEsperado := Default(TResolverDuplicadoSesion);
  oEsperado.Encontrado := True;
  oEsperado.CodigoArt := 'ART-1';
  FRepositorio.Duplicado := oEsperado;
  oResultado := FServicio.ResolverDuplicado(
    '  ART-1  ',
    '  PRV-1  ',
    True,
    '  ART-PREF  ');
  Assert.IsTrue(oResultado.Encontrado);
  Assert.AreEqual('ART-1', oResultado.CodigoArt);
  Assert.AreEqual('ART-1', FRepositorio.CodigoBuscado);
  Assert.AreEqual('PRV-1', FRepositorio.CodigoProveedor);
  Assert.AreEqual('ART-PREF', FRepositorio.CodigoArticuloPreferido);
  Assert.IsTrue(FRepositorio.SoloRefProveedor);
end;

procedure TPruebasComprasSesionesRepositorio.
  CalcularPrecioVentaConservaFormula;
begin
  Assert.AreEqual(
    9.99, CalcularPrecioVenta(10, 100, 1, 0.01), 0.0001);
  Assert.AreEqual(
    14.99, CalcularPrecioVenta(10, 120, 5, 0.01), 0.0001);
  Assert.AreEqual(
    0.0, CalcularPrecioVenta(0, 100, 0, 0.01), 0.0001);
end;

procedure TPruebasComprasSesionesRepositorio.
  ValidarSesionDevuelveTodasLasIncidencias;
var
  oIncidencias: TStringList;
  oValores: TIncidenciasSesionCompra;
begin
  SetLength(oValores, 2);
  oValores[0] := 'Falta proveedor';
  oValores[1] := 'Falta almacén';
  FRepositorio.Incidencias := oValores;
  oIncidencias := TStringList.Create;
  try
    Assert.IsFalse(FServicio.ValidarSesionDetallado(oIncidencias));
    Assert.AreEqual(2, oIncidencias.Count);
    Assert.AreEqual('Falta proveedor', oIncidencias[0]);
    Assert.AreEqual('Falta almacén', oIncidencias[1]);
  finally
    FreeAndNil(oIncidencias);
  end;
end;

procedure TPruebasComprasSesionesRepositorio.MaterializarDelegaSinConexion;
var
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
  oEsperado: TResultadoMaterializacionSesion;
begin
  oParametros := Default(TParametrosMaterializacionSesion);
  oParametros.Usuario := 'PRUEBAS';
  oEsperado := Default(TResultadoMaterializacionSesion);
  oEsperado.SeriePedido := 'PC';
  oEsperado.NumeroPedido := '42';
  FRepositorio.ResultadoMaterializacion := oEsperado;
  FRepositorio.ResultadoMaterializacionOk := True;
  Assert.IsTrue(EjecutarMaterializacionSesion(
    FContrato,
    oParametros,
    oResultado));
  Assert.AreEqual(1, FRepositorio.Materializaciones);
  Assert.AreEqual('PC', oResultado.SeriePedido);
  Assert.AreEqual('42', oResultado.NumeroPedido);
end;

procedure TPruebasComprasSesionesRepositorio.RevertirDelegaSinConexion;
var
  sError: string;
begin
  FRepositorio.ResultadoReversionOk := False;
  FRepositorio.MensajeReversion := 'No se puede revertir';
  Assert.IsFalse(RevertirMaterializacion(
    FContrato,
    '  PRUEBAS  ',
    sError));
  Assert.AreEqual(1, FRepositorio.Reversiones);
  Assert.AreEqual('No se puede revertir', sError);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComprasSesionesRepositorio);

end.
