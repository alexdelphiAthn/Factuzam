{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturaePersistencia                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la fábrica del repositorio Facturae sin acceso a BBDD.           }
{******************************************************************************}
unit PruebasFacturaePersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturaePersistencia = class
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
  System.SysUtils, Uni, inLibFacturaePersistenciaIntf,
  UniDataFacturaeRepositorio;

var
  bFabricaInvocada: Boolean;

function CrearRepositorioFacturaeFalso(
  AConexion: TUniConnection): IRepositorioFacturae;
begin
  bFabricaInvocada := True;
  Result := nil;
end;

procedure TPruebasFacturaePersistencia.Liberar;
begin
  TFabricaRepositorioFacturae.Registrar(
    CrearRepositorioFacturaeUniDAC);
  bFabricaInvocada := False;
end;

procedure TPruebasFacturaePersistencia.
  FabricaRegistrada_SeInvocaSinConexionReal;
var
  Repositorio: IRepositorioFacturae;
begin
  bFabricaInvocada := False;
  TFabricaRepositorioFacturae.Registrar(
    CrearRepositorioFacturaeFalso);
  Repositorio := TFabricaRepositorioFacturae.Crear(nil);
  Assert.IsTrue(bFabricaInvocada);
  Assert.IsFalse(Assigned(Repositorio));
end;

procedure TPruebasFacturaePersistencia.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaRepositorioFacturae.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      TFabricaRepositorioFacturae.Crear(nil);
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturaePersistencia);

end.
