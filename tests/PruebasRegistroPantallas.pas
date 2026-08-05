{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRegistroPantallas                                     }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del registro compartido de pantallas y data modules.             }
{******************************************************************************}
unit PruebasRegistroPantallas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRegistroPantallas = class
  public
    [Test]
    procedure Pantalla_SeResuelvePorNombreCualificado;
    [Test]
    procedure DataModule_SeResuelveIgnorandoEspaciosYMayusculas;
    [Test]
    procedure FabricaInyectada_ConservaClaseYPropietario;
    [Test]
    procedure FabricaAusente_FallaDuranteLaCreacion;
    [Test]
    procedure FabricaRetirada_EliminaElCanalInyectado;
  end;

implementation

uses
  System.SysUtils, System.Classes, Vcl.Forms,
  inLibRegistroPantallas;

type
  TPantallaRegistroPrueba = class(TForm);
  TPantallaInyectadaRegistroPrueba = class(TForm);
  TPantallaSinFabricaRegistroPrueba = class(TForm);
  TDataModuleRegistroPrueba = class(TDataModule);

procedure TPruebasRegistroPantallas.
  Pantalla_SeResuelvePorNombreCualificado;
var
  sNombre: string;
begin
  RegistrarPantalla(TPantallaRegistroPrueba);
  sNombre := TPantallaRegistroPrueba.QualifiedClassName;
  Assert.IsTrue(
    ClasePantalla(sNombre) = TPantallaRegistroPrueba);
end;

procedure TPruebasRegistroPantallas.
  DataModule_SeResuelveIgnorandoEspaciosYMayusculas;
var
  sNombre: string;
begin
  RegistrarDataModule(TDataModuleRegistroPrueba);
  sNombre := '  ' + LowerCase(
    TDataModuleRegistroPrueba.QualifiedClassName) + '  ';
  Assert.IsTrue(
    ClaseDataModule(sNombre) = TDataModuleRegistroPrueba);
end;

procedure TPruebasRegistroPantallas.
  FabricaInyectada_ConservaClaseYPropietario;
var
  bFabricaInvocada: Boolean;
  oOwner: TComponent;
  oPantalla: TForm;
begin
  bFabricaInvocada := False;
  oOwner := TComponent.Create(nil);
  RegistrarFabricaPantalla(
    TPantallaInyectadaRegistroPrueba,
    function(AOwner: TComponent): TForm
    begin
      bFabricaInvocada := True;
      Result := TPantallaInyectadaRegistroPrueba.CreateNew(AOwner);
    end);
  try
    oPantalla := CrearPantallaInyectada(
      TPantallaInyectadaRegistroPrueba,
      oOwner);
    Assert.IsTrue(bFabricaInvocada);
    Assert.IsTrue(
      oPantalla is TPantallaInyectadaRegistroPrueba);
    Assert.IsTrue(oPantalla.Owner = oOwner);
  finally
    RetirarFabricaPantalla(TPantallaInyectadaRegistroPrueba);
    FreeAndNil(oOwner);
  end;
end;

procedure TPruebasRegistroPantallas.
  FabricaAusente_FallaDuranteLaCreacion;
begin
  RetirarFabricaPantalla(TPantallaSinFabricaRegistroPrueba);
  Assert.WillRaise(
    procedure
    begin
      CrearPantallaInyectada(
        TPantallaSinFabricaRegistroPrueba,
        nil);
    end,
    EFabricaPantallaNoRegistrada);
end;

procedure TPruebasRegistroPantallas.
  FabricaRetirada_EliminaElCanalInyectado;
begin
  RegistrarFabricaPantalla(
    TPantallaInyectadaRegistroPrueba,
    function(AOwner: TComponent): TForm
    begin
      Result := TPantallaInyectadaRegistroPrueba.CreateNew(AOwner);
    end);
  RetirarFabricaPantalla(TPantallaInyectadaRegistroPrueba);
  Assert.WillRaise(
    procedure
    begin
      CrearPantallaInyectada(
        TPantallaInyectadaRegistroPrueba,
        nil);
    end,
    EFabricaPantallaNoRegistrada);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasRegistroPantallas);

end.
