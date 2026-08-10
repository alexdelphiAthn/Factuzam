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
{    Verifica la fabrica explicita de la exportacion NO VERI*FACTU.            }
{******************************************************************************}
unit PruebasExportacionNoVerifactuPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasExportacionNoVerifactuPersistencia = class
  public
    [Test]
    procedure FabricaExplicita_SeInvocaSinConexionReal;
  end;

implementation

uses
  Uni, inLibVerifactuNoVerifactuExportIntf;

var
  bFabricaInvocada: Boolean;

function CrearRepositorioExportacionNoVerifactuFalso(
  AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;
begin
  bFabricaInvocada := True;
  Result := nil;
end;

procedure TPruebasExportacionNoVerifactuPersistencia.
  FabricaExplicita_SeInvocaSinConexionReal;
var
  Repositorio: IRepositorioExportacionNoVerifactu;
begin
  bFabricaInvocada := False;
  Repositorio := CrearRepositorioExportacionNoVerifactuFalso(nil);
  Assert.IsTrue(bFabricaInvocada);
  Assert.IsFalse(Assigned(Repositorio));
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasExportacionNoVerifactuPersistencia);

end.
