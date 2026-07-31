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
  end;

implementation

uses
  Vcl.Forms, inLibArticulosVariacionesIntf,
  inLibArticulosVariaciones;

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

procedure PrepararServicioFalso;
begin
  oGestorFalso := TGestorArticulosVariacionesFalso.Create;
  oServicioGestorFalso := oGestorFalso;
  oFalso := TArticulosVariacionesFalso.Create;
  oServicioFalso := oFalso;
end;

procedure TPruebasArticulosVariaciones.Liberar;
begin
  oServicioFalso := nil;
  oFalso := nil;
  oServicioGestorFalso := nil;
  oGestorFalso := nil;
end;

procedure TPruebasArticulosVariaciones.
  AsegurarSinVariaciones_DelegaEnElServicio;
begin
  PrepararServicioFalso;
  AsegurarSkuArticuloSinVariaciones(
    oServicioFalso, 'ART-1', 'PRUEBAS');
  Assert.AreEqual(oavAsegurarSinVariaciones, oFalso.Operacion);
  Assert.AreEqual('ART-1', oFalso.CodigoArticulo);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasArticulosVariaciones.
  AsegurarActivo_DelegaEnElServicio;
begin
  PrepararServicioFalso;
  AsegurarSkuArticuloActivo(oServicioFalso, 'ART-2', 'PRUEBAS');
  Assert.AreEqual(oavAsegurarActivo, oFalso.Operacion);
  Assert.AreEqual('ART-2', oFalso.CodigoArticulo);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasArticulosVariaciones.
  TieneSkuActivo_DevuelveElResultadoDelServicio;
begin
  PrepararServicioFalso;
  oFalso.ResultadoTieneSku := True;
  Assert.IsTrue(ArticuloTieneSkuActivo(oServicioFalso, 'ART-3'));
  Assert.AreEqual(oavTieneSkuActivo, oFalso.Operacion);
  Assert.AreEqual('ART-3', oFalso.CodigoArticulo);
end;

procedure TPruebasArticulosVariaciones.
  Gestor_DelegaOperacionesYPropiedades;
var
  Gestor: TGestorVariaciones;
begin
  PrepararServicioFalso;
  oGestorFalso.CodigoArticulo := 'ART-4';
  oGestorFalso.Modificado := True;
  oGestorFalso.ResultadoGuardar := False;
  oGestorFalso.ResultadoValidar := 'VALIDACION';
  Gestor := TGestorVariaciones.Create(
    nil, oServicioFalso, 'PRUEBAS');
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

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosVariaciones);

end.
