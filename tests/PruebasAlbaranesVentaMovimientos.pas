{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasAlbaranesVentaMovimientos                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Prueba la atomicidad de movimientos de albarán sin VCL ni BBDD.           }
{******************************************************************************}
unit PruebasAlbaranesVentaMovimientos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasAlbaranesVentaMovimientos = class
  public
    [Test]
    procedure Sincronizar_ExitoConfirmaYConservaOrden;
    [Test]
    procedure Sincronizar_FalloRevierteYPropaga;
    [Test]
    procedure Sincronizar_RespetaTransaccionExterior;
    [Test]
    procedure Sincronizar_FalloExteriorNoRevierteTransaccionAjena;
    [Test]
    procedure GenerarFaltantes_FalloRevierteTodoElLote;
  end;

implementation

uses
  System.SysUtils,
  inLibAlbaranesVentaPresentacionMovimientos;

type
  TPersistenciaMovimientosAlbaranVentaFalsa = class(
    TInterfacedObject, IPersistenciaMovimientosAlbaranVenta)
  public
    FallarGeneracion: Boolean;
    Llamadas: string;
    procedure PrepararLineas(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    procedure Borrar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    function Generar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
  end;
  TUnidadTrabajoMovimientosAlbaranVentaFalsa = class(
    TInterfacedObject, IUnidadTrabajoMovimientosAlbaranVenta)
  public
    Activa: Boolean;
    Confirmaciones: Integer;
    Inicios: Integer;
    Reversiones: Integer;
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

procedure TPersistenciaMovimientosAlbaranVentaFalsa.PrepararLineas(
  const ADocumento: TDocumentoMovimientosAlbaranVenta);
begin
  Llamadas := Llamadas + 'P';
end;

procedure TPersistenciaMovimientosAlbaranVentaFalsa.Borrar(
  const ADocumento: TDocumentoMovimientosAlbaranVenta);
begin
  Llamadas := Llamadas + 'B';
end;

function TPersistenciaMovimientosAlbaranVentaFalsa.Generar(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
begin
  Llamadas := Llamadas + 'G';
  if FallarGeneracion then
    raise Exception.Create('FALLO DE MOVIMIENTO');
  Result := 3;
end;

function TUnidadTrabajoMovimientosAlbaranVentaFalsa.EstaActiva: Boolean;
begin
  Result := Activa;
end;

procedure TUnidadTrabajoMovimientosAlbaranVentaFalsa.Iniciar;
begin
  Activa := True;
  Inc(Inicios);
end;

procedure TUnidadTrabajoMovimientosAlbaranVentaFalsa.Confirmar;
begin
  Activa := False;
  Inc(Confirmaciones);
end;

procedure TUnidadTrabajoMovimientosAlbaranVentaFalsa.Revertir;
begin
  Activa := False;
  Inc(Reversiones);
end;

function CrearDocumentoPrueba: TDocumentoMovimientosAlbaranVenta;
begin
  Result := Default(TDocumentoMovimientosAlbaranVenta);
  Result.Serie := 'AV';
  Result.Numero := '35';
  Result.Almacen := 'GEN';
end;

procedure TPruebasAlbaranesVentaMovimientos.
  Sincronizar_ExitoConfirmaYConservaOrden;
var
  oFalsa: TPersistenciaMovimientosAlbaranVentaFalsa;
  oPersistencia: IPersistenciaMovimientosAlbaranVenta;
  oUnidad: TUnidadTrabajoMovimientosAlbaranVentaFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosAlbaranVenta;
  oOperacion: IOperacionMovimientosAlbaranVenta;
begin
  oFalsa := TPersistenciaMovimientosAlbaranVentaFalsa.Create;
  oPersistencia := oFalsa;
  oUnidad := TUnidadTrabajoMovimientosAlbaranVentaFalsa.Create;
  oUnidadInterfaz := oUnidad;
  oOperacion := CrearOperacionMovimientosAlbaranVenta(
    oPersistencia, oUnidadInterfaz);
  Assert.AreEqual(3, oOperacion.Sincronizar(CrearDocumentoPrueba));
  Assert.AreEqual('PBG', oFalsa.Llamadas);
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(1, oUnidad.Confirmaciones);
  Assert.AreEqual(0, oUnidad.Reversiones);
end;

procedure TPruebasAlbaranesVentaMovimientos.
  Sincronizar_FalloRevierteYPropaga;
var
  oFalsa: TPersistenciaMovimientosAlbaranVentaFalsa;
  oPersistencia: IPersistenciaMovimientosAlbaranVenta;
  oUnidad: TUnidadTrabajoMovimientosAlbaranVentaFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosAlbaranVenta;
  oOperacion: IOperacionMovimientosAlbaranVenta;
begin
  oFalsa := TPersistenciaMovimientosAlbaranVentaFalsa.Create;
  oFalsa.FallarGeneracion := True;
  oPersistencia := oFalsa;
  oUnidad := TUnidadTrabajoMovimientosAlbaranVentaFalsa.Create;
  oUnidadInterfaz := oUnidad;
  oOperacion := CrearOperacionMovimientosAlbaranVenta(
    oPersistencia, oUnidadInterfaz);
  Assert.WillRaise(
    procedure
    begin
      oOperacion.Sincronizar(CrearDocumentoPrueba);
    end,
    Exception);
  Assert.AreEqual('PBG', oFalsa.Llamadas);
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(1, oUnidad.Reversiones);
end;

procedure TPruebasAlbaranesVentaMovimientos.
  Sincronizar_RespetaTransaccionExterior;
var
  oFalsa: TPersistenciaMovimientosAlbaranVentaFalsa;
  oPersistencia: IPersistenciaMovimientosAlbaranVenta;
  oUnidad: TUnidadTrabajoMovimientosAlbaranVentaFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosAlbaranVenta;
  oOperacion: IOperacionMovimientosAlbaranVenta;
begin
  oFalsa := TPersistenciaMovimientosAlbaranVentaFalsa.Create;
  oPersistencia := oFalsa;
  oUnidad := TUnidadTrabajoMovimientosAlbaranVentaFalsa.Create;
  oUnidad.Activa := True;
  oUnidadInterfaz := oUnidad;
  oOperacion := CrearOperacionMovimientosAlbaranVenta(
    oPersistencia, oUnidadInterfaz);
  Assert.AreEqual(3, oOperacion.Sincronizar(CrearDocumentoPrueba));
  Assert.AreEqual(0, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(0, oUnidad.Reversiones);
  Assert.IsTrue(oUnidad.Activa);
end;

procedure TPruebasAlbaranesVentaMovimientos.
  GenerarFaltantes_FalloRevierteTodoElLote;
var
  oFalsa: TPersistenciaMovimientosAlbaranVentaFalsa;
  oPersistencia: IPersistenciaMovimientosAlbaranVenta;
  oUnidad: TUnidadTrabajoMovimientosAlbaranVentaFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosAlbaranVenta;
  oOperacion: IOperacionMovimientosAlbaranVenta;
begin
  oFalsa := TPersistenciaMovimientosAlbaranVentaFalsa.Create;
  oFalsa.FallarGeneracion := True;
  oPersistencia := oFalsa;
  oUnidad := TUnidadTrabajoMovimientosAlbaranVentaFalsa.Create;
  oUnidadInterfaz := oUnidad;
  oOperacion := CrearOperacionMovimientosAlbaranVenta(
    oPersistencia, oUnidadInterfaz);
  Assert.WillRaise(
    procedure
    begin
      oOperacion.GenerarFaltantes(CrearDocumentoPrueba);
    end,
    Exception);
  Assert.AreEqual('G', oFalsa.Llamadas);
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(1, oUnidad.Reversiones);
end;

procedure TPruebasAlbaranesVentaMovimientos.
  Sincronizar_FalloExteriorNoRevierteTransaccionAjena;
var
  oFalsa: TPersistenciaMovimientosAlbaranVentaFalsa;
  oPersistencia: IPersistenciaMovimientosAlbaranVenta;
  oUnidad: TUnidadTrabajoMovimientosAlbaranVentaFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosAlbaranVenta;
  oOperacion: IOperacionMovimientosAlbaranVenta;
begin
  oFalsa := TPersistenciaMovimientosAlbaranVentaFalsa.Create;
  oFalsa.FallarGeneracion := True;
  oPersistencia := oFalsa;
  oUnidad := TUnidadTrabajoMovimientosAlbaranVentaFalsa.Create;
  oUnidad.Activa := True;
  oUnidadInterfaz := oUnidad;
  oOperacion := CrearOperacionMovimientosAlbaranVenta(
    oPersistencia, oUnidadInterfaz);
  Assert.WillRaise(
    procedure
    begin
      oOperacion.Sincronizar(CrearDocumentoPrueba);
    end,
    Exception);
  Assert.AreEqual(0, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(0, oUnidad.Reversiones);
  Assert.IsTrue(oUnidad.Activa);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasAlbaranesVentaMovimientos);

end.
