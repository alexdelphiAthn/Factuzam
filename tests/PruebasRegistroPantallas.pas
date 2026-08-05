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
    procedure Compositor_SeResuelvePorLaCadenaDePropietarios;
    [Test]
    procedure FabricaInyectada_ConservaClaseYPropietario;
    [Test]
    procedure FabricaAusente_FallaDuranteLaCreacion;
  end;

implementation

uses
  System.SysUtils, System.Classes, Vcl.Forms,
  inLibRegistroPantallas, inLibRepositoriosPantallaIntf;

type
  TPantallaRegistroPrueba = class(TForm);
  TPantallaInyectadaRegistroPrueba = class(TForm);
  TPantallaSinFabricaRegistroPrueba = class(TForm);
  TDataModuleRegistroPrueba = class(TDataModule);
  TCompositorArticulosRegistroPrueba = class(
    TComponent,
    ICompositorArticulosPantalla)
  private
    FNombrePantalla: string;
  public
    function CrearRepositoriosArticulosPantalla(
      const ANombrePantalla: string): IRepositoriosArticulosPantalla;
    property NombrePantalla: string read FNombrePantalla;
  end;

function TCompositorArticulosRegistroPrueba.
  CrearRepositoriosArticulosPantalla(
  const ANombrePantalla: string): IRepositoriosArticulosPantalla;
begin
  FNombrePantalla := ANombrePantalla;
  Result := nil;
end;

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
  Compositor_SeResuelvePorLaCadenaDePropietarios;
var
  oCompositor: ICompositorArticulosPantalla;
  oHijo: TComponent;
  oRaiz: TCompositorArticulosRegistroPrueba;
begin
  oRaiz := TCompositorArticulosRegistroPrueba.Create(nil);
  try
    oHijo := TComponent.Create(oRaiz);
    oCompositor := ObtenerCompositorArticulosPantalla(oHijo);
    oCompositor.CrearRepositoriosArticulosPantalla(
      'frmPruebaComposicion');
    Assert.AreEqual('frmPruebaComposicion', oRaiz.NombrePantalla);
    oCompositor := nil;
  finally
    FreeAndNil(oRaiz);
  end;
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

initialization
  TDUnitX.RegisterTestFixture(TPruebasRegistroPantallas);

end.
