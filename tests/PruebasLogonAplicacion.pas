{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasLogonAplicacion                                        }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica los límites de la recuperación administrativa del logon.         }
{******************************************************************************}
unit PruebasLogonAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasLogonAplicacion = class
  private
    FAplicacion: IInterface;
    FRepositorio: TObject;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure DelegaRecuperacionDelAdministrador;
    [Test]
    procedure DelegaRestriccionDePrimeraDemo;
    [Test]
    procedure RechazaRecuperacionDeOtroUsuario;
    [Test]
    procedure RechazaContrasenaNuevaNoValida;
  end;

implementation

uses
  System.SysUtils,
  inLibLogonAplicacion,
  inLibLogonAplicacionIntf,
  inLibNuevoEquipo;

type
  TRepositorioLogonFalso = class(TInterfacedObject, IRepositorioLogon)
  private
    FContrasena: string;
    FExigirContrasenaDemoInicial: Boolean;
    FNumeroRestablecimientos: Integer;
    FUsuario: string;
  public
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
    procedure EstablecerContrasenaNuevoEquipo(
      const AUsuario, AContrasenaNueva: string;
      AExigirContrasenaDemoInicial: Boolean = False);
    property Contrasena: string read FContrasena;
    property NumeroRestablecimientos: Integer
      read FNumeroRestablecimientos;
    property ExigirContrasenaDemoInicial: Boolean
      read FExigirContrasenaDemoInicial;
    property Usuario: string read FUsuario;
  end;

function TRepositorioLogonFalso.Autenticar(
  const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
begin
  Result := TResultadoAutenticacionLogon.Crear(
    ealCredencialesInvalidas,
    'No usado por estas pruebas.');
end;

procedure TRepositorioLogonFalso.EstablecerContrasenaNuevoEquipo(
  const AUsuario, AContrasenaNueva: string;
  AExigirContrasenaDemoInicial: Boolean);
begin
  Inc(FNumeroRestablecimientos);
  FUsuario := AUsuario;
  FContrasena := AContrasenaNueva;
  FExigirContrasenaDemoInicial := AExigirContrasenaDemoInicial;
end;

procedure TPruebasLogonAplicacion.Preparar;
var
  oRepositorio: TRepositorioLogonFalso;
  oAplicacion: IAplicacionLogon;
begin
  oRepositorio := TRepositorioLogonFalso.Create;
  oAplicacion := CrearAplicacionLogon(oRepositorio);
  FRepositorio := oRepositorio;
  FAplicacion := oAplicacion;
end;

procedure TPruebasLogonAplicacion.DelegaRestriccionDePrimeraDemo;
var
  oAplicacion: IAplicacionLogon;
  oRepositorio: TRepositorioLogonFalso;
begin
  oAplicacion := FAplicacion as IAplicacionLogon;
  oRepositorio := TRepositorioLogonFalso(FRepositorio);

  oAplicacion.EstablecerContrasenaNuevoEquipo(
    USUARIO_INICIAL_NUEVO_EQUIPO,
    'Nueva demo #2026',
    True);

  Assert.IsTrue(oRepositorio.ExigirContrasenaDemoInicial);
end;

procedure TPruebasLogonAplicacion.Limpiar;
begin
  FAplicacion := nil;
  FRepositorio := nil;
end;

procedure TPruebasLogonAplicacion.DelegaRecuperacionDelAdministrador;
var
  oAplicacion: IAplicacionLogon;
  oRepositorio: TRepositorioLogonFalso;
begin
  oAplicacion := FAplicacion as IAplicacionLogon;
  oRepositorio := TRepositorioLogonFalso(FRepositorio);
  oAplicacion.EstablecerContrasenaNuevoEquipo(
    USUARIO_INICIAL_NUEVO_EQUIPO,
    'Nueva #2026');

  Assert.AreEqual(1, oRepositorio.NumeroRestablecimientos);
  Assert.AreEqual(
    USUARIO_INICIAL_NUEVO_EQUIPO,
    oRepositorio.Usuario);
  Assert.AreEqual('Nueva #2026', oRepositorio.Contrasena);
end;

procedure TPruebasLogonAplicacion.RechazaRecuperacionDeOtroUsuario;
var
  oAplicacion: IAplicacionLogon;
  oRepositorio: TRepositorioLogonFalso;
begin
  oAplicacion := FAplicacion as IAplicacionLogon;
  oRepositorio := TRepositorioLogonFalso(FRepositorio);
  Assert.WillRaise(
    procedure
    begin
      oAplicacion.EstablecerContrasenaNuevoEquipo(
        'OtroUsuario',
        'Nueva #2026');
    end,
    EArgumentException);
  Assert.AreEqual(0, oRepositorio.NumeroRestablecimientos);
end;

procedure TPruebasLogonAplicacion.RechazaContrasenaNuevaNoValida;
var
  oAplicacion: IAplicacionLogon;
  oRepositorio: TRepositorioLogonFalso;
begin
  oAplicacion := FAplicacion as IAplicacionLogon;
  oRepositorio := TRepositorioLogonFalso(FRepositorio);
  Assert.WillRaise(
    procedure
    begin
      oAplicacion.EstablecerContrasenaNuevoEquipo(
        USUARIO_INICIAL_NUEVO_EQUIPO,
        '');
    end,
    EContrasenaNuevoEquipoNoValida);
  Assert.WillRaise(
    procedure
    begin
      oAplicacion.EstablecerContrasenaNuevoEquipo(
        USUARIO_INICIAL_NUEVO_EQUIPO,
        StringOfChar(
          'x',
          LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO + 1));
    end,
    EContrasenaNuevoEquipoNoValida);
  Assert.AreEqual(0, oRepositorio.NumeroRestablecimientos);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasLogonAplicacion);

end.
