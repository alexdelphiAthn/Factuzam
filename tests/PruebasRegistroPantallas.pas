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
    [Test]
    procedure Call_SubclaseInyectadaResuelveAncestroRegistrado;
    [Test]
    procedure DataModule_SubclaseInyectadaResuelveAncestroRegistrado;
    [Test]
    procedure Jerarquia_PriorizaRegistroMasCercano;
    [Test]
    procedure FrmBase_ConstructoresHeredanMismoRegistro;
  end;

implementation

uses
  System.SysUtils, System.Classes, Vcl.Forms,
  inLibAnfitrionMtoIntf, inLibLogIntf,
  inLibRegistroLogNulo, inLibRegistroPantallas,
  inMtoFrmBase;

const
  CALL_BASE_JERARQUIA = 'DocumentosTrabajo';
  CALL_CERCANO_JERARQUIA = 'DocumentosTrabajoDecorado';
  DATAMODULE_BASE_JERARQUIA =
    'UniDataDocumentosTrabajo.TdmDocumentosTrabajo';
  DATAMODULE_CERCANO_JERARQUIA =
    'UniDataDocumentosTrabajoDecorado.TdmDocumentosTrabajoDecorado';

type
  TPantallaRegistroPrueba = class(TForm);
  TPantallaInyectadaRegistroPrueba = class(TForm);
  TPantallaSinFabricaRegistroPrueba = class(TForm);
  TDataModuleRegistroPrueba = class(TDataModule);
  TPantallaBaseJerarquiaPrueba = class(TForm);
  TPantallaIntermediaJerarquiaPrueba = class(
    TPantallaBaseJerarquiaPrueba);
  TPantallaInyectadaJerarquiaPrueba = class(
    TPantallaIntermediaJerarquiaPrueba);

  TPropietarioRegistroPrueba = class(
    TComponent,
    IProveedorRegistroLog)
  private
    FRegistroLog: IRegistroLog;
    function GetRegistroLog: IRegistroLog;
  public
    constructor Create(
      AOwner: TComponent;
      const ARegistroLog: IRegistroLog); reintroduce;
  end;

  TAnfitrionJerarquiaPrueba = class(
    TInterfacedObject, IAnfitrionMantenimiento)
  private
    FUnidadBase: string;
    FUnidadCercana: string;
  public
    constructor Create(AClaseBase, AClaseCercana: TClass);
    function ResolverCallPantalla(
      const AUnidadClase: string): string;
    function ResolverDataModulePantalla(
      const AUnidadClase: string): string;
    procedure CancelarEdicionesPantallas;
    procedure VincularFotoMantenimiento(AMantenimiento: TObject);
    function CrearCopiaPreviaScriptSoporte: Boolean;
  end;

constructor TPropietarioRegistroPrueba.Create(
  AOwner: TComponent;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create(AOwner);
  FRegistroLog := ARegistroLog;
end;

function TPropietarioRegistroPrueba.GetRegistroLog: IRegistroLog;
begin
  Result := FRegistroLog;
end;

function NombreCualificadoClase(AClase: TClass): string;
begin
  Result := AClase.UnitName + '.' + AClase.ClassName;
end;

constructor TAnfitrionJerarquiaPrueba.Create(
  AClaseBase, AClaseCercana: TClass);
begin
  inherited Create;
  FUnidadBase := NombreCualificadoClase(AClaseBase);
  if Assigned(AClaseCercana) then
    FUnidadCercana := NombreCualificadoClase(AClaseCercana)
  else
    FUnidadCercana := '';
end;

function TAnfitrionJerarquiaPrueba.ResolverCallPantalla(
  const AUnidadClase: string): string;
begin
  if (FUnidadCercana <> '') and
     SameText(AUnidadClase, FUnidadCercana) then
    Result := CALL_CERCANO_JERARQUIA
  else if SameText(AUnidadClase, FUnidadBase) then
    Result := CALL_BASE_JERARQUIA
  else
    Result := '';
end;

function TAnfitrionJerarquiaPrueba.ResolverDataModulePantalla(
  const AUnidadClase: string): string;
begin
  if (FUnidadCercana <> '') and
     SameText(AUnidadClase, FUnidadCercana) then
    Result := DATAMODULE_CERCANO_JERARQUIA
  else if SameText(AUnidadClase, FUnidadBase) then
    Result := DATAMODULE_BASE_JERARQUIA
  else
    Result := '';
end;

procedure TAnfitrionJerarquiaPrueba.CancelarEdicionesPantallas;
begin
end;

procedure TAnfitrionJerarquiaPrueba.VincularFotoMantenimiento(
  AMantenimiento: TObject);
begin
end;

function TAnfitrionJerarquiaPrueba.
  CrearCopiaPreviaScriptSoporte: Boolean;
begin
  Result := False;
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

procedure TPruebasRegistroPantallas.
  Call_SubclaseInyectadaResuelveAncestroRegistrado;
var
  oAnfitrion: IAnfitrionMantenimiento;
begin
  oAnfitrion := TAnfitrionJerarquiaPrueba.Create(
    TPantallaBaseJerarquiaPrueba, nil);
  Assert.AreEqual(
    CALL_BASE_JERARQUIA,
    ResolverCallPantallaPorJerarquia(
      oAnfitrion,
      TPantallaInyectadaJerarquiaPrueba));
end;

procedure TPruebasRegistroPantallas.
  DataModule_SubclaseInyectadaResuelveAncestroRegistrado;
var
  oAnfitrion: IAnfitrionMantenimiento;
begin
  oAnfitrion := TAnfitrionJerarquiaPrueba.Create(
    TPantallaBaseJerarquiaPrueba, nil);
  Assert.AreEqual(
    DATAMODULE_BASE_JERARQUIA,
    ResolverDataModulePantallaPorJerarquia(
      oAnfitrion,
      TPantallaInyectadaJerarquiaPrueba));
end;

procedure TPruebasRegistroPantallas.
  Jerarquia_PriorizaRegistroMasCercano;
var
  oAnfitrion: IAnfitrionMantenimiento;
begin
  oAnfitrion := TAnfitrionJerarquiaPrueba.Create(
    TPantallaBaseJerarquiaPrueba,
    TPantallaIntermediaJerarquiaPrueba);
  Assert.AreEqual(
    CALL_CERCANO_JERARQUIA,
    ResolverCallPantallaPorJerarquia(
      oAnfitrion,
      TPantallaInyectadaJerarquiaPrueba));
  Assert.AreEqual(
    DATAMODULE_CERCANO_JERARQUIA,
    ResolverDataModulePantallaPorJerarquia(
      oAnfitrion,
      TPantallaInyectadaJerarquiaPrueba));
end;

procedure TPruebasRegistroPantallas.
  FrmBase_ConstructoresHeredanMismoRegistro;
var
  Formulario: TfrmBase;
  Propietario: TPropietarioRegistroPrueba;
  Proveedor: IProveedorRegistroLog;
  RegistroEsperado: IRegistroLog;
begin
  RegistroEsperado := CrearRegistroLogNulo;
  Propietario := TPropietarioRegistroPrueba.Create(
    nil,
    RegistroEsperado);
  try
    Formulario := TfrmBase.Create(Propietario);
    try
      Assert.IsTrue(Supports(
        Formulario,
        IProveedorRegistroLog,
        Proveedor));
      Assert.IsTrue(Proveedor.RegistroLog = RegistroEsperado);
      Proveedor := nil;
    finally
      FreeAndNil(Formulario);
    end;
    Formulario := TfrmBase.Create(Propietario, nil);
    try
      Assert.IsTrue(Supports(
        Formulario,
        IProveedorRegistroLog,
        Proveedor));
      Assert.IsTrue(Proveedor.RegistroLog = RegistroEsperado);
      Proveedor := nil;
    finally
      FreeAndNil(Formulario);
    end;
  finally
    FreeAndNil(Propietario);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasRegistroPantallas);

end.
