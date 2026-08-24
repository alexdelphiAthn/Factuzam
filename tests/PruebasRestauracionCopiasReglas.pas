{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRestauracionCopiasReglas                              }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica que la restauración sin sesión sólo acepte copias cifradas y     }
{    que los formatos en texto queden reservados al rol administrador.         }
{******************************************************************************}
unit PruebasRestauracionCopiasReglas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRestauracionCopiasReglas = class
  public
    [Test]
    procedure AdministradorPuedeRestaurarTodosLosFormatosSoportados;
    [Test]
    procedure NoAdministradorSoloPuedeRestaurarCopiaCifrada;
    [Test]
    procedure CasoUsoConexionRechazaTextoAntesDeDelegar;
    [Test]
    procedure CasoUsoConexionDelegaCopiaCifrada;
  end;

implementation

uses
  System.SysUtils,
  inLibCopiasSeguridadIntf,
  inLibCopiasSeguridadReglas,
  inLibRestauracionCopiasConexion,
  inLibRestauracionCopiasConexionIntf;

type
  TRepositorioRestauracionFalso = class(
    TInterfacedObject,
    IRepositorioRestauracionConexion)
  private
    FNumeroInicios: Integer;
  public
    procedure Iniciar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
    property NumeroInicios: Integer read FNumeroInicios;
  end;

function SolicitudValida(
  const ARutaFichero: string): TSolicitudRestauracionConexion;
begin
  Result := Default(TSolicitudRestauracionConexion);
  Result.Host := 'localhost';
  Result.Puerto := 3306;
  Result.BaseDatos := 'factuzam_pruebas';
  Result.Usuario := 'usuario_pruebas';
  Result.RutaFichero := ARutaFichero;
end;

procedure TRepositorioRestauracionFalso.Iniciar(
  const ASolicitud: TSolicitudRestauracionConexion;
  AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent);
begin
  Inc(FNumeroInicios);
end;

procedure TPruebasRestauracionCopiasReglas.
  AdministradorPuedeRestaurarTodosLosFormatosSoportados;
begin
  Assert.IsTrue(TPoliticaCopiasSeguridad.PuedeRestaurar(
    True, 'copia.sql'));
  Assert.IsTrue(TPoliticaCopiasSeguridad.PuedeRestaurar(
    True, 'copia.zip'));
  Assert.IsTrue(TPoliticaCopiasSeguridad.PuedeRestaurar(
    True, 'copia.crypt'));
end;

procedure TPruebasRestauracionCopiasReglas.
  NoAdministradorSoloPuedeRestaurarCopiaCifrada;
begin
  Assert.IsFalse(TPoliticaCopiasSeguridad.PuedeRestaurar(
    False, 'copia.sql'));
  Assert.IsFalse(TPoliticaCopiasSeguridad.PuedeRestaurar(
    False, 'copia.zip'));
  Assert.IsFalse(TPoliticaCopiasSeguridad.PuedeRestaurar(
    False, 'copia.txt'));
  Assert.IsTrue(TPoliticaCopiasSeguridad.PuedeRestaurar(
    False, 'copia.CRYPT'));
end;

procedure TPruebasRestauracionCopiasReglas.
  CasoUsoConexionRechazaTextoAntesDeDelegar;
var
  CasoUso: ICasoUsoRestauracionConexion;
  Rechazada: Boolean;
  Repositorio: TRepositorioRestauracionFalso;
begin
  Repositorio := TRepositorioRestauracionFalso.Create;
  CasoUso := CrearCasoUsoRestauracionConexion(Repositorio);
  Rechazada := False;
  try
    CasoUso.Ejecutar(
      SolicitudValida('copia.sql'),
      nil,
      nil,
      nil);
  except
    on E: EArgumentException do
    begin
      Rechazada := True;
      Assert.IsTrue(Pos('administradores', LowerCase(E.Message)) > 0);
    end;
  end;

  Assert.IsTrue(Rechazada);
  Assert.AreEqual(0, Repositorio.NumeroInicios);
end;

procedure TPruebasRestauracionCopiasReglas.
  CasoUsoConexionDelegaCopiaCifrada;
var
  CasoUso: ICasoUsoRestauracionConexion;
  Repositorio: TRepositorioRestauracionFalso;
begin
  Repositorio := TRepositorioRestauracionFalso.Create;
  CasoUso := CrearCasoUsoRestauracionConexion(Repositorio);
  CasoUso.Ejecutar(
    SolicitudValida('copia.crypt'),
    nil,
    nil,
    nil);

  Assert.AreEqual(1, Repositorio.NumeroInicios);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasRestauracionCopiasReglas);

end.
