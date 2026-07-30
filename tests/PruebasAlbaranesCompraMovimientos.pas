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
{    mediante una fábrica falsa, sin BBDD.                                     }
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
    procedure Generar_DelegaEnElServicioRegistrado;
    [Test]
    procedure Revertir_DelegaEnElServicioRegistrado;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Uni, inLibAlbaranesCompraMovimientosIntf,
  inLibAlbaranesCompraMovimientos, UniDataAlbaranesCompraMovimientos;

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

function FabricaFalsa(
  AConexion: TUniConnection): IMovimientosAlbaranCompra;
begin
  Result := oServicioFalso;
end;

procedure PrepararFabricaFalsa;
begin
  oFalso := TMovimientosAlbaranCompraFalso.Create;
  oServicioFalso := oFalso;
  TFabricaMovimientosAlbaranCompra.Registrar(FabricaFalsa);
end;

procedure TPruebasAlbaranesCompraMovimientos.Liberar;
begin
  // Restaura la implementación UniDAC real registrada en la
  // initialization del adaptador.
  TFabricaMovimientosAlbaranCompra.Registrar(
    CrearMovimientosAlbaranCompraUniDAC);
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasAlbaranesCompraMovimientos.
  Generar_DelegaEnElServicioRegistrado;
begin
  PrepararFabricaFalsa;
  GenerarMovimientosDesdeAlbaranCompra(
    nil,
    'AC',
    '77',
    'PRUEBAS');
  Assert.AreEqual(omfGenerar, oFalso.Operacion);
  Assert.AreEqual('AC', oFalso.Serie);
  Assert.AreEqual('77', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasAlbaranesCompraMovimientos.
  Revertir_DelegaEnElServicioRegistrado;
begin
  PrepararFabricaFalsa;
  RevertirMovimientosDesdeAlbaranCompra(
    nil,
    'AC',
    '78',
    'PRUEBAS');
  Assert.AreEqual(omfRevertir, oFalso.Operacion);
  Assert.AreEqual('AC', oFalso.Serie);
  Assert.AreEqual('78', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasAlbaranesCompraMovimientos.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaMovimientosAlbaranCompra.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      GenerarMovimientosDesdeAlbaranCompra(
        nil,
        'AC',
        '79',
        'PRUEBAS');
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasAlbaranesCompraMovimientos);

end.
