{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosVariaciones                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada de variaciones de artículos sin usar BBDD.         }
{******************************************************************************}
unit PruebasArticulosVariaciones;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosVariaciones = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure AsegurarSinVariaciones_DelegaEnElServicio;
    [Test]
    procedure AsegurarActivo_DelegaEnElServicio;
    [Test]
    procedure TieneSkuActivo_DevuelveElResultadoDelServicio;
    [Test]
    procedure Gestor_DelegaOperacionesYPropiedades;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, Uni,
  inLibArticulosVariacionesIntf, inLibArticulosVariaciones,
  UniDataArticulosVariaciones;

type
  TOperacionArticulosVariacionesFalsa = (
    oavNinguna,
    oavAsegurarSinVariaciones,
    oavAsegurarActivo,
    oavTieneSkuActivo,
    oavCrearGestor);
  TGestorArticulosVariacionesFalso = class(
    TInterfacedObject,
    IGestorArticulosVariaciones)
  public
    CodigoArticulo: string;
    CodigoCargado: string;
    Modificado: Boolean;
    ResultadoGuardar: Boolean;
    ResultadoValidar: string;
    procedure CargarVariaciones(const ACodigoArticulo: string);
    function GuardarVariaciones: Boolean;
    function Validar: string;
    function ObtenerCodigoArticulo: string;
    function EstaModificado: Boolean;
  end;
  TArticulosVariacionesFalso = class(
    TInterfacedObject,
    IArticulosVariaciones)
  public
    CodigoArticulo: string;
    Operacion: TOperacionArticulosVariacionesFalsa;
    ResultadoTieneSku: Boolean;
    Usuario: string;
    UsuarioGestor: string;
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function CrearGestor(
      APanelAtributos: TScrollBox;
      const AUsuario: string): IGestorArticulosVariaciones;
  end;

var
  oServicioFalso: IArticulosVariaciones;
  oServicioGestorFalso: IGestorArticulosVariaciones;
  oFalso: TArticulosVariacionesFalso;
  oGestorFalso: TGestorArticulosVariacionesFalso;

procedure TGestorArticulosVariacionesFalso.CargarVariaciones(
  const ACodigoArticulo: string);
begin
  CodigoCargado := ACodigoArticulo;
end;

function TGestorArticulosVariacionesFalso.GuardarVariaciones: Boolean;
begin
  Result := ResultadoGuardar;
end;

function TGestorArticulosVariacionesFalso.Validar: string;
begin
  Result := ResultadoValidar;
end;

function TGestorArticulosVariacionesFalso.ObtenerCodigoArticulo: string;
begin
  Result := CodigoArticulo;
end;

function TGestorArticulosVariacionesFalso.EstaModificado: Boolean;
begin
  Result := Modificado;
end;

procedure TArticulosVariacionesFalso.AsegurarSkuSinVariaciones(
  const ACodigoArticulo, AUsuario: string);
begin
  Operacion := oavAsegurarSinVariaciones;
  CodigoArticulo := ACodigoArticulo;
  Usuario := AUsuario;
end;

procedure TArticulosVariacionesFalso.AsegurarSkuActivo(
  const ACodigoArticulo, AUsuario: string);
begin
  Operacion := oavAsegurarActivo;
  CodigoArticulo := ACodigoArticulo;
  Usuario := AUsuario;
end;

function TArticulosVariacionesFalso.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Operacion := oavTieneSkuActivo;
  CodigoArticulo := ACodigoArticulo;
  Result := ResultadoTieneSku;
end;

function TArticulosVariacionesFalso.CrearGestor(
  APanelAtributos: TScrollBox;
  const AUsuario: string): IGestorArticulosVariaciones;
begin
  Operacion := oavCrearGestor;
  UsuarioGestor := AUsuario;
  Result := oServicioGestorFalso;
end;

function FabricaFalsa(
  AConexion: TUniConnection): IArticulosVariaciones;
begin
  Result := oServicioFalso;
end;

procedure PrepararFabricaFalsa;
begin
  oGestorFalso := TGestorArticulosVariacionesFalso.Create;
  oServicioGestorFalso := oGestorFalso;
  oFalso := TArticulosVariacionesFalso.Create;
  oServicioFalso := oFalso;
  TFabricaArticulosVariaciones.Registrar(FabricaFalsa);
end;

procedure TPruebasArticulosVariaciones.Liberar;
begin
  TFabricaArticulosVariaciones.Registrar(
    CrearArticulosVariacionesUniDAC);
  oServicioFalso := nil;
  oFalso := nil;
  oServicioGestorFalso := nil;
  oGestorFalso := nil;
end;

procedure TPruebasArticulosVariaciones.
  AsegurarSinVariaciones_DelegaEnElServicio;
begin
  PrepararFabricaFalsa;
  AsegurarSkuArticuloSinVariaciones(nil, 'ART-1', 'PRUEBAS');
  Assert.AreEqual(oavAsegurarSinVariaciones, oFalso.Operacion);
  Assert.AreEqual('ART-1', oFalso.CodigoArticulo);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasArticulosVariaciones.
  AsegurarActivo_DelegaEnElServicio;
begin
  PrepararFabricaFalsa;
  AsegurarSkuArticuloActivo(nil, 'ART-2', 'PRUEBAS');
  Assert.AreEqual(oavAsegurarActivo, oFalso.Operacion);
  Assert.AreEqual('ART-2', oFalso.CodigoArticulo);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasArticulosVariaciones.
  TieneSkuActivo_DevuelveElResultadoDelServicio;
begin
  PrepararFabricaFalsa;
  oFalso.ResultadoTieneSku := True;
  Assert.IsTrue(ArticuloTieneSkuActivo(nil, 'ART-3'));
  Assert.AreEqual(oavTieneSkuActivo, oFalso.Operacion);
  Assert.AreEqual('ART-3', oFalso.CodigoArticulo);
end;

procedure TPruebasArticulosVariaciones.
  Gestor_DelegaOperacionesYPropiedades;
var
  Gestor: TGestorVariaciones;
begin
  PrepararFabricaFalsa;
  oGestorFalso.CodigoArticulo := 'ART-4';
  oGestorFalso.Modificado := True;
  oGestorFalso.ResultadoGuardar := False;
  oGestorFalso.ResultadoValidar := 'VALIDACION';
  Gestor := TGestorVariaciones.Create(nil, nil, 'PRUEBAS');
  try
    Gestor.CargarVariaciones('ART-CARGADO');
    Assert.AreEqual(oavCrearGestor, oFalso.Operacion);
    Assert.AreEqual('PRUEBAS', oFalso.UsuarioGestor);
    Assert.AreEqual('ART-CARGADO', oGestorFalso.CodigoCargado);
    Assert.IsFalse(Gestor.GuardarVariaciones);
    Assert.AreEqual('VALIDACION', Gestor.Validar);
    Assert.AreEqual('ART-4', Gestor.CodigoArticulo);
    Assert.IsTrue(Gestor.Modificado);
  finally
    Gestor.Free;
  end;
end;

procedure TPruebasArticulosVariaciones.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaArticulosVariaciones.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      ArticuloTieneSkuActivo(nil, 'ART-5');
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosVariaciones);

end.
