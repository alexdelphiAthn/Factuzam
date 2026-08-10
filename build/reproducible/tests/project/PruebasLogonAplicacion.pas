{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasLogonAplicacion                                        }
{    Tipo:       Pruebas DUnitX                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza los cuatro resultados posibles de autenticación.             }
{******************************************************************************}
unit PruebasLogonAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasLogonAplicacion = class
  public
    [Test]
    procedure CredencialesCorrectas_Autentica;
    [Test]
    procedure CredencialesInvalidas_ConservaClasificacion;
    [Test]
    procedure RepositorioNoDisponible_ClasificaIndisponibilidad;
    [Test]
    procedure ErrorRepositorio_ClasificaError;
    [Test]
    procedure ArranquePrincipal_EjecutaFasesEnOrden;
    [Test]
    procedure PreparacionLogon_EjecutaFasesEnOrden;
    [Test]
    procedure PreparacionLogon_SeDetieneAlRechazarUnaFase;
  end;

implementation

uses
  System.SysUtils,
  inLibArranqueAplicacion,
  inLibContextoSesionIntf,
  inLibLicenciaAplicacion,
  inLibLogonAplicacion,
  inLibLogonAplicacionIntf;

type
  TComportamientoRepositorioLogon = (
    crlAutenticar,
    crlCredencialesInvalidas,
    crlNoDisponible,
    crlError);

  TRepositorioLogonFalso = class(
    TInterfacedObject,
    IRepositorioLogon)
  private
    FComportamiento: TComportamientoRepositorioLogon;
  public
    constructor Create(AComportamiento: TComportamientoRepositorioLogon);
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
  end;

  TPasosArranqueFalsos = class(
    TInterfacedObject,
    IPasosArranqueAplicacion)
  private
    FTraza: string;
    procedure Anotar(const APaso: string);
  public
    procedure PrepararContextoAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      out AIdentidad: TIdentidadSesion;
      out AUbicacion: TUbicacionSesion);
    procedure MostrarSplashInicio;
    procedure CrearInfraestructuraAplicacion;
    procedure CargarServiciosAplicacion(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure ActivarAplicacion;
    procedure PresentarAplicacion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure FinalizarArranqueAplicacion;
    property Traza: string read FTraza;
  end;

  TPasosPreparacionLogonFalsos = class(
    TInterfacedObject,
    IPasosPreparacionLogon)
  private
    FDetenerEn: string;
    FTraza: string;
    procedure Anotar(const APaso: string);
    function Continuar(const APaso: string): Boolean;
  public
    constructor Create(const ADetenerEn: string);
    procedure PrepararLogon;
    function ConectarServidorLogon: Boolean;
    function ValidarEstructuraLogon: Boolean;
    function ConectarAplicacionLogon: Boolean;
    function PrepararLicenciaLogon: Boolean;
    procedure EjecutarAutenticacionAutomatica;
    property Traza: string read FTraza;
  end;

procedure TPasosArranqueFalsos.Anotar(const APaso: string);
begin
  if FTraza <> '' then
    FTraza := FTraza + '>';
  FTraza := FTraza + APaso;
end;

procedure TPasosArranqueFalsos.PrepararContextoAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  out AIdentidad: TIdentidadSesion;
  out AUbicacion: TUbicacionSesion);
begin
  Anotar('contexto');
  AIdentidad := Default(TIdentidadSesion);
  AUbicacion := Default(TUbicacionSesion);
end;

procedure TPasosArranqueFalsos.MostrarSplashInicio;
begin
  Anotar('splash');
end;

procedure TPasosArranqueFalsos.CrearInfraestructuraAplicacion;
begin
  Anotar('infraestructura');
end;

procedure TPasosArranqueFalsos.CargarServiciosAplicacion(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  Anotar('servicios');
end;

procedure TPasosArranqueFalsos.ActivarAplicacion;
begin
  Anotar('activar');
end;

procedure TPasosArranqueFalsos.PresentarAplicacion(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
begin
  Anotar('presentar');
end;

procedure TPasosArranqueFalsos.FinalizarArranqueAplicacion;
begin
  Anotar('finalizar');
end;

constructor TPasosPreparacionLogonFalsos.Create(
  const ADetenerEn: string);
begin
  inherited Create;
  FDetenerEn := ADetenerEn;
end;

procedure TPasosPreparacionLogonFalsos.Anotar(
  const APaso: string);
begin
  if FTraza <> '' then
    FTraza := FTraza + '>';
  FTraza := FTraza + APaso;
end;

function TPasosPreparacionLogonFalsos.Continuar(
  const APaso: string): Boolean;
begin
  Anotar(APaso);
  Result := not SameText(APaso, FDetenerEn);
end;

procedure TPasosPreparacionLogonFalsos.PrepararLogon;
begin
  Anotar('preparar');
end;

function TPasosPreparacionLogonFalsos.ConectarServidorLogon: Boolean;
begin
  Result := Continuar('servidor');
end;

function TPasosPreparacionLogonFalsos.ValidarEstructuraLogon: Boolean;
begin
  Result := Continuar('estructura');
end;

function TPasosPreparacionLogonFalsos.ConectarAplicacionLogon: Boolean;
begin
  Result := Continuar('aplicacion');
end;

function TPasosPreparacionLogonFalsos.PrepararLicenciaLogon: Boolean;
begin
  Result := Continuar('licencia');
end;

procedure TPasosPreparacionLogonFalsos.
  EjecutarAutenticacionAutomatica;
begin
  Anotar('autenticacion');
end;

constructor TRepositorioLogonFalso.Create(
  AComportamiento: TComportamientoRepositorioLogon);
begin
  inherited Create;
  FComportamiento := AComportamiento;
end;

function TRepositorioLogonFalso.Autenticar(
  const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
begin
  case FComportamiento of
    crlAutenticar:
    begin
      Result := TResultadoAutenticacionLogon.Crear(
        ealAutenticado,
        'Correcto');
      Result.Usuario := AUsuario;
      Result.Grupo := 'ADMIN';
    end;
    crlCredencialesInvalidas:
      Result := TResultadoAutenticacionLogon.Crear(
        ealCredencialesInvalidas,
        'Credenciales inválidas');
    crlNoDisponible:
      raise ERepositorioLogonNoDisponible.Create(
        'Servidor no disponible');
  else
    raise ERepositorioLogonError.Create('Consulta fallida');
  end;
end;

function Ejecutar(
  AComportamiento: TComportamientoRepositorioLogon):
  TResultadoAutenticacionLogon;
var
  oAplicacion: IAplicacionLogon;
begin
  oAplicacion := CrearAplicacionLogon(
    TRepositorioLogonFalso.Create(AComportamiento));
  Result := oAplicacion.Autenticar('usuario', 'clave');
end;

procedure TPruebasLogonAplicacion.CredencialesCorrectas_Autentica;
var
  Resultado: TResultadoAutenticacionLogon;
begin
  Resultado := Ejecutar(crlAutenticar);
  Assert.AreEqual(Ord(ealAutenticado), Ord(Resultado.Estado));
  Assert.AreEqual('usuario', Resultado.Usuario);
  Assert.AreEqual('ADMIN', Resultado.Grupo);
end;

procedure TPruebasLogonAplicacion.
  CredencialesInvalidas_ConservaClasificacion;
var
  Resultado: TResultadoAutenticacionLogon;
begin
  Resultado := Ejecutar(crlCredencialesInvalidas);
  Assert.AreEqual(
    Ord(ealCredencialesInvalidas),
    Ord(Resultado.Estado));
end;

procedure TPruebasLogonAplicacion.
  RepositorioNoDisponible_ClasificaIndisponibilidad;
var
  Resultado: TResultadoAutenticacionLogon;
begin
  Resultado := Ejecutar(crlNoDisponible);
  Assert.AreEqual(Ord(ealNoDisponible), Ord(Resultado.Estado));
  Assert.AreEqual('Servidor no disponible', Resultado.Mensaje);
end;

procedure TPruebasLogonAplicacion.ErrorRepositorio_ClasificaError;
var
  Resultado: TResultadoAutenticacionLogon;
begin
  Resultado := Ejecutar(crlError);
  Assert.AreEqual(Ord(ealError), Ord(Resultado.Estado));
  Assert.AreEqual('Consulta fallida', Resultado.Mensaje);
end;

procedure TPruebasLogonAplicacion.
  ArranquePrincipal_EjecutaFasesEnOrden;
var
  CasoUso: ICasoUsoArranqueAplicacion;
  Pasos: TPasosArranqueFalsos;
  ResultadoLicencia: TResultadoLicenciaAplicacion;
begin
  Pasos := TPasosArranqueFalsos.Create;
  CasoUso := CrearCasoUsoArranqueAplicacion(Pasos);
  ResultadoLicencia := Default(TResultadoLicenciaAplicacion);
  CasoUso.Ejecutar(nil, ResultadoLicencia);
  Assert.AreEqual(
    'contexto>splash>infraestructura>servicios>' +
    'activar>presentar>finalizar',
    Pasos.Traza);
end;

procedure TPruebasLogonAplicacion.
  PreparacionLogon_EjecutaFasesEnOrden;
var
  CasoUso: ICasoUsoPreparacionLogon;
  Pasos: TPasosPreparacionLogonFalsos;
begin
  Pasos := TPasosPreparacionLogonFalsos.Create('');
  CasoUso := CrearCasoUsoPreparacionLogon(Pasos);
  CasoUso.Ejecutar;
  Assert.AreEqual(
    'preparar>servidor>estructura>aplicacion>' +
    'licencia>autenticacion',
    Pasos.Traza);
end;

procedure TPruebasLogonAplicacion.
  PreparacionLogon_SeDetieneAlRechazarUnaFase;
var
  CasoUso: ICasoUsoPreparacionLogon;
  Pasos: TPasosPreparacionLogonFalsos;
begin
  Pasos := TPasosPreparacionLogonFalsos.Create('estructura');
  CasoUso := CrearCasoUsoPreparacionLogon(Pasos);
  CasoUso.Ejecutar;
  Assert.AreEqual(
    'preparar>servidor>estructura',
    Pasos.Traza);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasLogonAplicacion);

end.
