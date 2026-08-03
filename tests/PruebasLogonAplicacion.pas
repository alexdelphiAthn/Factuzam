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
  end;

implementation

uses
  System.SysUtils,
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

initialization
  TDUnitX.RegisterTestFixture(TPruebasLogonAplicacion);

end.
