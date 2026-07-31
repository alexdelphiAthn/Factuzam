{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFotosPersistencia                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el registro de persistencia y los prefijos de fotos sin BBDD.    }
{******************************************************************************}
unit PruebasFotosPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFotosPersistencia = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure FabricaRegistrada_SeInvocaSinConexionReal;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
    [Test]
    procedure PrefijosSku_OrdenaDeMasAMenosEspecifico;
  end;

implementation

uses
  System.SysUtils, Uni, inLibFotosPersistenciaIntf,
  UniDataFotosRepositorio, inLibFotos;

var
  bFabricaInvocada: Boolean;

function FabricaFotosFalsa(
  AConexion: TUniConnection): IRepositorioFotos;
begin
  bFabricaInvocada := True;
  Result := nil;
end;

procedure TPruebasFotosPersistencia.Liberar;
begin
  TFabricaRepositorioFotos.Registrar(CrearRepositorioFotosUniDAC);
  bFabricaInvocada := False;
end;

procedure TPruebasFotosPersistencia.
  FabricaRegistrada_SeInvocaSinConexionReal;
var
  Repositorio: IRepositorioFotos;
begin
  bFabricaInvocada := False;
  TFabricaRepositorioFotos.Registrar(FabricaFotosFalsa);
  Repositorio := TFabricaRepositorioFotos.Crear(nil);
  Assert.IsTrue(bFabricaInvocada);
  Assert.IsFalse(Assigned(Repositorio));
end;

procedure TPruebasFotosPersistencia.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaRepositorioFotos.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      TFabricaRepositorioFotos.Crear(nil);
    end,
    Exception);
end;

procedure TPruebasFotosPersistencia.
  PrefijosSku_OrdenaDeMasAMenosEspecifico;
var
  Prefijos: TArray<string>;
begin
  Prefijos := GenerarPrefijosSku('BLUS-SEDA/BLANCO/L');
  Assert.AreEqual(2, Integer(Length(Prefijos)));
  Assert.AreEqual('BLUS-SEDA/BLANCO/L', Prefijos[0]);
  Assert.AreEqual('BLUS-SEDA/BLANCO', Prefijos[1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosPersistencia);

end.
