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
{    mediante una fábrica falsa, sin BBDD.                                     }
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
    procedure Generar_DelegaEnElServicioRegistrado;
    [Test]
    procedure Revertir_DelegaEnElServicioRegistrado;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Uni, inLibDevolucionesCompraMovimientosIntf,
  inLibDevolucionesCompraMovimientos,
  UniDataDevolucionesCompraMovimientos;

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

function FabricaFalsa(
  AConexion: TUniConnection): IMovimientosDevolucionCompra;
begin
  Result := oServicioFalso;
end;

procedure PrepararFabricaFalsa;
begin
  oFalso := TMovimientosDevolucionCompraFalso.Create;
  oServicioFalso := oFalso;
  TFabricaMovimientosDevolucionCompra.Registrar(FabricaFalsa);
end;

procedure TPruebasDevolucionesCompraMovimientos.Liberar;
begin
  // Restaura la implementación UniDAC real registrada por el adaptador.
  TFabricaMovimientosDevolucionCompra.Registrar(
    CrearMovimientosDevolucionCompraUniDAC);
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Generar_DelegaEnElServicioRegistrado;
begin
  PrepararFabricaFalsa;
  GenerarMovimientosDesdeDevolucionCompra(
    nil,
    'DC',
    '77',
    'PRUEBAS');
  Assert.AreEqual(omfGenerar, oFalso.Operacion);
  Assert.AreEqual('DC', oFalso.Serie);
  Assert.AreEqual('77', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Revertir_DelegaEnElServicioRegistrado;
begin
  PrepararFabricaFalsa;
  RevertirMovimientosDesdeDevolucionCompra(
    nil,
    'DC',
    '78',
    'PRUEBAS');
  Assert.AreEqual(omfRevertir, oFalso.Operacion);
  Assert.AreEqual('DC', oFalso.Serie);
  Assert.AreEqual('78', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaMovimientosDevolucionCompra.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      GenerarMovimientosDesdeDevolucionCompra(
        nil,
        'DC',
        '79',
        'PRUEBAS');
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasDevolucionesCompraMovimientos);

end.
