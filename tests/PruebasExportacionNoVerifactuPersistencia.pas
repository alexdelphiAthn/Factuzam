{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasExportacionNoVerifactuPersistencia                     }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la fábrica de lecturas para la exportación NO VERI*FACTU.        }
{******************************************************************************}
unit PruebasExportacionNoVerifactuPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasExportacionNoVerifactuPersistencia = class
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
  System.SysUtils, Uni, inLibVerifactuNoVerifactuExportIntf,
  UniDataVerifactuNoVerifactuExport;

var
  bFabricaInvocada: Boolean;

function CrearRepositorioExportacionNoVerifactuFalso(
  AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;
begin
  bFabricaInvocada := True;
  Result := nil;
end;

procedure TPruebasExportacionNoVerifactuPersistencia.Liberar;
begin
  TFabricaRepositorioExportacionNoVerifactu.Registrar(
    CrearRepositorioExportacionNoVerifactuUniDAC);
  bFabricaInvocada := False;
end;

procedure TPruebasExportacionNoVerifactuPersistencia.
  FabricaRegistrada_SeInvocaSinConexionReal;
var
  Repositorio: IRepositorioExportacionNoVerifactu;
begin
  bFabricaInvocada := False;
  TFabricaRepositorioExportacionNoVerifactu.Registrar(
    CrearRepositorioExportacionNoVerifactuFalso);
  Repositorio :=
    TFabricaRepositorioExportacionNoVerifactu.Crear(nil);
  Assert.IsTrue(bFabricaInvocada);
  Assert.IsFalse(Assigned(Repositorio));
end;

procedure TPruebasExportacionNoVerifactuPersistencia.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaRepositorioExportacionNoVerifactu.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      TFabricaRepositorioExportacionNoVerifactu.Crear(nil);
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasExportacionNoVerifactuPersistencia);

end.
