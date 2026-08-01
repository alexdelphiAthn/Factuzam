{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasAlbaranesCompraMovimientos                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada de movimientos de albaranes de compra              }
{    mediante una dependencia falsa inyectada, sin BBDD.                      }
{******************************************************************************}
unit PruebasAlbaranesCompraMovimientos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasAlbaranesCompraMovimientos = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure Generar_DelegaEnElServicioInyectado;
    [Test]
    procedure Revertir_DelegaEnElServicioInyectado;
  end;

implementation

uses
  inLibAlbaranesCompraMovimientosIntf,
  inLibAlbaranesCompraMovimientos;

type
  TOperacionMovimientosFalsa = (
    omfNinguna,
    omfGenerar,
    omfRevertir);
  TMovimientosAlbaranCompraFalso = class(
    TInterfacedObject,
    IMovimientosAlbaranCompra)
  public
    Numero: string;
    Operacion: TOperacionMovimientosFalsa;
    Serie: string;
    Usuario: string;
    procedure GenerarDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
    procedure RevertirDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
  end;

var
  oServicioFalso: IMovimientosAlbaranCompra;
  oFalso: TMovimientosAlbaranCompraFalso;

procedure TMovimientosAlbaranCompraFalso.GenerarDesdeAlbaran(
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  Operacion := omfGenerar;
  Serie := ASerieAlbc;
  Numero := ANumAlbc;
  Usuario := AUsuario;
end;

procedure TMovimientosAlbaranCompraFalso.RevertirDesdeAlbaran(
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  Operacion := omfRevertir;
  Serie := ASerieAlbc;
  Numero := ANumAlbc;
  Usuario := AUsuario;
end;

procedure PrepararServicioFalso;
begin
  oFalso := TMovimientosAlbaranCompraFalso.Create;
  oServicioFalso := oFalso;
end;

procedure TPruebasAlbaranesCompraMovimientos.Liberar;
begin
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasAlbaranesCompraMovimientos.
  Generar_DelegaEnElServicioInyectado;
begin
  PrepararServicioFalso;
  GenerarMovimientosDesdeAlbaranCompra(
    oServicioFalso,
    'AC',
    '77',
    'PRUEBAS');
  Assert.AreEqual(omfGenerar, oFalso.Operacion);
  Assert.AreEqual('AC', oFalso.Serie);
  Assert.AreEqual('77', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasAlbaranesCompraMovimientos.
  Revertir_DelegaEnElServicioInyectado;
begin
  PrepararServicioFalso;
  RevertirMovimientosDesdeAlbaranCompra(
    oServicioFalso,
    'AC',
    '78',
    'PRUEBAS');
  Assert.AreEqual(omfRevertir, oFalso.Operacion);
  Assert.AreEqual('AC', oFalso.Serie);
  Assert.AreEqual('78', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasAlbaranesCompraMovimientos);

end.
