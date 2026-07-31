{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDevolucionesCompraMovimientos                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada de movimientos de devoluciones de compra           }
{    mediante una dependencia falsa inyectada, sin BBDD.                      }
{******************************************************************************}
unit PruebasDevolucionesCompraMovimientos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasDevolucionesCompraMovimientos = class
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
  inLibDevolucionesCompraMovimientosIntf,
  inLibDevolucionesCompraMovimientos;

type
  TOperacionMovimientosFalsa = (
    omfNinguna,
    omfGenerar,
    omfRevertir);
  TMovimientosDevolucionCompraFalso = class(
    TInterfacedObject,
    IMovimientosDevolucionCompra)
  public
    Numero: string;
    Operacion: TOperacionMovimientosFalsa;
    Serie: string;
    Usuario: string;
    procedure GenerarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure RevertirDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
  end;

var
  oServicioFalso: IMovimientosDevolucionCompra;
  oFalso: TMovimientosDevolucionCompraFalso;

procedure TMovimientosDevolucionCompraFalso.GenerarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  Operacion := omfGenerar;
  Serie := ASerieDevc;
  Numero := ANumDevc;
  Usuario := AUsuario;
end;

procedure TMovimientosDevolucionCompraFalso.RevertirDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  Operacion := omfRevertir;
  Serie := ASerieDevc;
  Numero := ANumDevc;
  Usuario := AUsuario;
end;

procedure PrepararServicioFalso;
begin
  oFalso := TMovimientosDevolucionCompraFalso.Create;
  oServicioFalso := oFalso;
end;

procedure TPruebasDevolucionesCompraMovimientos.Liberar;
begin
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Generar_DelegaEnElServicioInyectado;
begin
  PrepararServicioFalso;
  GenerarMovimientosDesdeDevolucionCompra(
    oServicioFalso,
    'DC',
    '77',
    'PRUEBAS');
  Assert.AreEqual(omfGenerar, oFalso.Operacion);
  Assert.AreEqual('DC', oFalso.Serie);
  Assert.AreEqual('77', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Revertir_DelegaEnElServicioInyectado;
begin
  PrepararServicioFalso;
  RevertirMovimientosDesdeDevolucionCompra(
    oServicioFalso,
    'DC',
    '78',
    'PRUEBAS');
  Assert.AreEqual(omfRevertir, oFalso.Operacion);
  Assert.AreEqual('DC', oFalso.Serie);
  Assert.AreEqual('78', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasDevolucionesCompraMovimientos);

end.
