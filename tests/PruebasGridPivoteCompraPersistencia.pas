{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGridPivoteCompraPersistencia                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el registro del repositorio del pivote sin BBDD. }
{******************************************************************************}
unit PruebasGridPivoteCompraPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasGridPivoteCompraPersistencia = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure FabricaRegistrada_SeInvocaSinConexionReal;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Uni, inLibGridPivoteCompraPersistenciaIntf,
  UniDataGridPivoteCompraRepositorio;

var
  bFabricaInvocada: Boolean;

function FabricaGridPivoteCompraFalsa(
  AConexion: TUniConnection): IRepositorioGridPivoteCompra;
begin
  bFabricaInvocada := True;
  Result := nil;
end;

procedure TPruebasGridPivoteCompraPersistencia.Liberar;
begin
  TFabricaRepositorioGridPivoteCompra.Registrar(
    CrearRepositorioGridPivoteCompraUniDAC);
  bFabricaInvocada := False;
end;

procedure TPruebasGridPivoteCompraPersistencia.
  FabricaRegistrada_SeInvocaSinConexionReal;
var
  Repositorio: IRepositorioGridPivoteCompra;
begin
  bFabricaInvocada := False;
  TFabricaRepositorioGridPivoteCompra.Registrar(
    FabricaGridPivoteCompraFalsa);
  Repositorio := TFabricaRepositorioGridPivoteCompra.Crear(nil);
  Assert.IsTrue(bFabricaInvocada);
  Assert.IsFalse(Assigned(Repositorio));
end;

procedure TPruebasGridPivoteCompraPersistencia.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaRepositorioGridPivoteCompra.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      TFabricaRepositorioGridPivoteCompra.Crear(nil);
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasGridPivoteCompraPersistencia);

end.
