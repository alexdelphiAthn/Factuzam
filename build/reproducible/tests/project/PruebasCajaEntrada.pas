{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCajaEntrada                                            }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la aplicación de entrada de artículos en caja.                  }
{******************************************************************************}
unit PruebasCajaEntrada;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCajaEntrada = class
  public
    [Test]
    procedure CodigoValido_AplicaYPreparaSiguiente;
    [Test]
    procedure SinVendedor_NoResuelveCodigo;
    [Test]
    procedure CodigoInexistente_MuestraErrorSinAplicar;
  end;

implementation

uses
  inLibArticulosValidadorIntf,
  inLibCajaEntrada,
  inLibCajaEntradaIntf;

type
  TValidadorEntradaCajaPrueba = class(
    TInterfacedObject,
    IArticulosValidador)
  private
    FInvocado: Boolean;
    FResolucion: TArtResolucionEntrada;
  public
    function Resolver(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverCodigoBarras(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverConSku(
      const AEntrada, ACodigoSkuPreferido: string
    ): TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    property Invocado: Boolean read FInvocado;
    property Resolucion: TArtResolucionEntrada
      read FResolucion write FResolucion;
  end;
  TOperacionesEntradaCajaPrueba = class(
    TInterfacedObject,
    IOperacionesEntradaCaja)
  private
    FAplicado: Boolean;
    FDisponible: Boolean;
    FFinalizada: Boolean;
    FIniciada: Boolean;
    FVendedorAsignado: Boolean;
  public
    function Disponible: Boolean;
    function VendedorAsignado: Boolean;
    function PermitirSku(const ACodigoSku: string): Boolean;
    procedure PrepararLinea;
    function ConsolidarSku(const ACodigoSku: string): Boolean;
    procedure AplicarCodigo(
      const ACodigo, ACodigoSku, ACodigoArticulo: string);
    procedure Iniciar;
    procedure Finalizar;
    property Aplicado: Boolean read FAplicado;
    property DisponibleRespuesta: Boolean
      read FDisponible write FDisponible;
    property Finalizada: Boolean read FFinalizada;
    property Iniciada: Boolean read FIniciada;
    property VendedorRespuesta: Boolean
      read FVendedorAsignado write FVendedorAsignado;
  end;
  TVistaEntradaCajaPrueba = class(
    TInterfacedObject,
    IVistaEntradaCaja)
  private
    FError: string;
    FEnfocoVendedor: Boolean;
    FPreparoSiguiente: Boolean;
  public
    procedure MostrarError(const AMensaje: string);
    procedure EnfocarVendedor;
    procedure PrepararLectura;
    procedure RefrescarConsolidacion;
    procedure PrepararSiguiente;
    property EnfocoVendedor: Boolean read FEnfocoVendedor;
    property Error: string read FError;
    property PreparoSiguiente: Boolean read FPreparoSiguiente;
  end;

function TValidadorEntradaCajaPrueba.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaCajaPrueba.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  FInvocado := True;
  Result := FResolucion;
end;

function TValidadorEntradaCajaPrueba.ResolverConSku(
  const AEntrada, ACodigoSkuPreferido: string
): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaCajaPrueba.EsValido(
  const AEntrada: string): Boolean;
begin
  Result := FResolucion.Encontrado;
end;

function TValidadorEntradaCajaPrueba.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FResolucion.SkuActivo;
end;

function TOperacionesEntradaCajaPrueba.Disponible: Boolean;
begin
  Result := FDisponible;
end;

function TOperacionesEntradaCajaPrueba.VendedorAsignado: Boolean;
begin
  Result := FVendedorAsignado;
end;

function TOperacionesEntradaCajaPrueba.PermitirSku(
  const ACodigoSku: string): Boolean;
begin
  Result := True;
end;

procedure TOperacionesEntradaCajaPrueba.PrepararLinea;
begin
end;

function TOperacionesEntradaCajaPrueba.ConsolidarSku(
  const ACodigoSku: string): Boolean;
begin
  Result := False;
end;

procedure TOperacionesEntradaCajaPrueba.AplicarCodigo(
  const ACodigo, ACodigoSku, ACodigoArticulo: string);
begin
  FAplicado := True;
end;

procedure TOperacionesEntradaCajaPrueba.Iniciar;
begin
  FIniciada := True;
end;

procedure TOperacionesEntradaCajaPrueba.Finalizar;
begin
  FFinalizada := True;
end;

procedure TVistaEntradaCajaPrueba.MostrarError(
  const AMensaje: string);
begin
  FError := AMensaje;
end;

procedure TVistaEntradaCajaPrueba.EnfocarVendedor;
begin
  FEnfocoVendedor := True;
end;

procedure TVistaEntradaCajaPrueba.PrepararLectura;
begin
end;

procedure TVistaEntradaCajaPrueba.RefrescarConsolidacion;
begin
end;

procedure TVistaEntradaCajaPrueba.PrepararSiguiente;
begin
  FPreparoSiguiente := True;
end;

procedure TPruebasCajaEntrada.CodigoValido_AplicaYPreparaSiguiente;
var
  Aplicacion: IAplicacionEntradaCaja;
  Operaciones: TOperacionesEntradaCajaPrueba;
  Resolucion: TArtResolucionEntrada;
  Validador: TValidadorEntradaCajaPrueba;
  Vista: TVistaEntradaCajaPrueba;
begin
  Operaciones := TOperacionesEntradaCajaPrueba.Create;
  Operaciones.DisponibleRespuesta := True;
  Operaciones.VendedorRespuesta := True;
  Validador := TValidadorEntradaCajaPrueba.Create;
  Resolucion := Default(TArtResolucionEntrada);
  Resolucion.Encontrado := True;
  Resolucion.CodigoArticulo := 'ART';
  Resolucion.CodigoSku := 'ART/ROJO/M';
  Validador.Resolucion := Resolucion;
  Vista := TVistaEntradaCajaPrueba.Create;
  Aplicacion := CrearAplicacionEntradaCaja(
    Validador,
    Operaciones,
    Vista);
  Aplicacion.Procesar('843000000001');
  Assert.IsTrue(Validador.Invocado);
  Assert.IsTrue(Operaciones.Iniciada);
  Assert.IsTrue(Operaciones.Aplicado);
  Assert.IsTrue(Operaciones.Finalizada);
  Assert.IsTrue(Vista.PreparoSiguiente);
end;

procedure TPruebasCajaEntrada.SinVendedor_NoResuelveCodigo;
var
  Aplicacion: IAplicacionEntradaCaja;
  Operaciones: TOperacionesEntradaCajaPrueba;
  Validador: TValidadorEntradaCajaPrueba;
  Vista: TVistaEntradaCajaPrueba;
begin
  Operaciones := TOperacionesEntradaCajaPrueba.Create;
  Operaciones.DisponibleRespuesta := True;
  Operaciones.VendedorRespuesta := False;
  Validador := TValidadorEntradaCajaPrueba.Create;
  Vista := TVistaEntradaCajaPrueba.Create;
  Aplicacion := CrearAplicacionEntradaCaja(
    Validador,
    Operaciones,
    Vista);
  Aplicacion.Procesar('843000000001');
  Assert.IsFalse(Validador.Invocado);
  Assert.IsTrue(Vista.EnfocoVendedor);
  Assert.IsNotEmpty(Vista.Error);
  Assert.IsTrue(Operaciones.Finalizada);
end;

procedure TPruebasCajaEntrada.CodigoInexistente_MuestraErrorSinAplicar;
var
  Aplicacion: IAplicacionEntradaCaja;
  Operaciones: TOperacionesEntradaCajaPrueba;
  Resolucion: TArtResolucionEntrada;
  Validador: TValidadorEntradaCajaPrueba;
  Vista: TVistaEntradaCajaPrueba;
begin
  Operaciones := TOperacionesEntradaCajaPrueba.Create;
  Operaciones.DisponibleRespuesta := True;
  Operaciones.VendedorRespuesta := True;
  Validador := TValidadorEntradaCajaPrueba.Create;
  Resolucion := Default(TArtResolucionEntrada);
  Resolucion.Encontrado := False;
  Validador.Resolucion := Resolucion;
  Vista := TVistaEntradaCajaPrueba.Create;
  Aplicacion := CrearAplicacionEntradaCaja(
    Validador,
    Operaciones,
    Vista);
  Aplicacion.Procesar('NO_EXISTE');
  Assert.IsFalse(Operaciones.Aplicado);
  Assert.IsNotEmpty(Vista.Error);
  Assert.IsTrue(Vista.PreparoSiguiente);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCajaEntrada);

end.
