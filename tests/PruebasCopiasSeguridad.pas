{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCopiasSeguridad                                        }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de la política de protección y restauración de copias.            }
{******************************************************************************}
unit PruebasCopiasSeguridad;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCopiasSeguridad = class
  public
    [Test]
    procedure Administrador_CreaTextoPlano;
    [Test]
    procedure Usuario_CreaCifrada;
    [Test]
    procedure Administrador_RestauraSqlYCifrada;
    [Test]
    procedure Usuario_SoloRestauraCifrada;
    [Test]
    procedure Coordinador_CopiaSincrona_NotificaPresentacion;
    [Test]
    procedure Coordinador_Cancelacion_EsIdempotente;
    [Test]
    procedure Coordinador_CancelacionTipada_NoNecesitaTexto;
    [Test]
    procedure Coordinador_FalloTipado_NoInterpretaTexto;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  inLibCopiasSeguridadIntf,
  inLibCopiasSeguridadReglas,
  inLibOperacionesAplicacionIntf,
  inLibCoordinadorOperacionesAplicacion;

type
  TServicioCopiasFalso = class(
    TInterfacedObject,
    IServicioCopiasSeguridad)
  private
    FResultado: TResultadoCopiaSeguridad;
    FFinalizarAlIniciar: Boolean;
    FError: string;
  public
    constructor Create(
      AResultado: TResultadoCopiaSeguridad;
      AFinalizarAlIniciar: Boolean = False;
      const AError: string = '');
    function ModoCreacion: TModoProteccionCopia;
    function ExtensionCreacion: string;
    function PuedeRestaurar(const ARutaFichero: string): Boolean;
    function RequiereContrasena(
      const ARutaFichero: string): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    function CrearCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string): TResultadoCopiaSeguridad;
    function CrearCopiaProtegida(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string): TResultadoCopiaSeguridad;
  end;
  TPresentacionOperacionesFalsa = class(
    TInterfacedObject,
    IPresentacionOperacionesAplicacion)
  private
    FMostrada: Boolean;
    FCancelando: Boolean;
    FFinalizada: Boolean;
    FResultado: TResultadoCopiaSeguridad;
    FTipo: TTipoOperacionAplicacion;
  public
    procedure MostrarOperacion;
    procedure ActualizarProgreso(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure MostrarCancelando;
    procedure FinalizarOperacion(
      ATipo: TTipoOperacionAplicacion;
      AResultado: TResultadoCopiaSeguridad;
      const AError: string;
      ALogBuffer: TStringList);
    property Mostrada: Boolean read FMostrada;
    property Cancelando: Boolean read FCancelando;
    property Finalizada: Boolean read FFinalizada;
    property Resultado: TResultadoCopiaSeguridad read FResultado;
    property Tipo: TTipoOperacionAplicacion read FTipo;
  end;

constructor TServicioCopiasFalso.Create(
  AResultado: TResultadoCopiaSeguridad;
  AFinalizarAlIniciar: Boolean;
  const AError: string);
begin
  inherited Create;
  FResultado := AResultado;
  FFinalizarAlIniciar := AFinalizarAlIniciar;
  FError := AError;
end;

function TServicioCopiasFalso.ModoCreacion: TModoProteccionCopia;
begin
  Result := mpcCifrada;
end;

function TServicioCopiasFalso.ExtensionCreacion: string;
begin
  Result := '.crypt';
end;

function TServicioCopiasFalso.PuedeRestaurar(
  const ARutaFichero: string): Boolean;
begin
  Result := ARutaFichero <> '';
end;

function TServicioCopiasFalso.RequiereContrasena(
  const ARutaFichero: string): Boolean;
begin
  Result := True;
end;

procedure TServicioCopiasFalso.IniciarCopia(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
begin
  AWorker := nil;
  if FFinalizarAlIniciar and Assigned(AOnFinalizar) then
    AOnFinalizar(FResultado, FError, nil);
end;

procedure TServicioCopiasFalso.IniciarRestauracion(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
begin
  AWorker := nil;
  if FFinalizarAlIniciar and Assigned(AOnFinalizar) then
    AOnFinalizar(FResultado, FError, nil);
end;

function TServicioCopiasFalso.CrearCopia(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
begin
  AError := FError;
  if Assigned(AOnProgreso) then
    AOnProgreso('Copia', 1, 1, 1, 1);
  Result := FResultado;
end;

function TServicioCopiasFalso.CrearCopiaProtegida(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
begin
  AError := FError;
  if Assigned(AOnProgreso) then
    AOnProgreso('Copia protegida', 1, 1, 1, 1);
  Result := FResultado;
end;

procedure TPresentacionOperacionesFalsa.MostrarOperacion;
begin
  FMostrada := True;
end;

procedure TPresentacionOperacionesFalsa.ActualizarProgreso(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
end;

procedure TPresentacionOperacionesFalsa.MostrarCancelando;
begin
  FCancelando := True;
end;

procedure TPresentacionOperacionesFalsa.FinalizarOperacion(
  ATipo: TTipoOperacionAplicacion;
  AResultado: TResultadoCopiaSeguridad;
  const AError: string;
  ALogBuffer: TStringList);
begin
  FFinalizada := True;
  FResultado := AResultado;
  FTipo := ATipo;
  FreeAndNil(ALogBuffer);
end;

procedure TPruebasCopiasSeguridad.Administrador_CreaTextoPlano;
begin
  Assert.AreEqual(
    Integer(mpcTextoPlano),
    Integer(
      TPoliticaCopiasSeguridad.ModoCreacion(True)));
  Assert.AreEqual(
    '.sql',
    TPoliticaCopiasSeguridad.ExtensionCreacion(True));
end;

procedure TPruebasCopiasSeguridad.Usuario_CreaCifrada;
begin
  Assert.AreEqual(
    Integer(mpcCifrada),
    Integer(
      TPoliticaCopiasSeguridad.ModoCreacion(False)));
  Assert.AreEqual(
    '.crypt',
    TPoliticaCopiasSeguridad.ExtensionCreacion(False));
end;

procedure TPruebasCopiasSeguridad.
  Administrador_RestauraSqlYCifrada;
begin
  Assert.IsTrue(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      True,
      'copia.sql'));
  Assert.IsTrue(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      True,
      'copia.crypt'));
end;

procedure TPruebasCopiasSeguridad.
  Usuario_SoloRestauraCifrada;
begin
  Assert.IsFalse(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      False,
      'copia.sql'));
  Assert.IsTrue(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      False,
      'copia.crypt'));
end;

procedure TPruebasCopiasSeguridad.
  Coordinador_CopiaSincrona_NotificaPresentacion;
var
  oCoordinador: ICoordinadorOperacionesAplicacion;
  oPresentacion: TPresentacionOperacionesFalsa;
begin
  oPresentacion := TPresentacionOperacionesFalsa.Create;
  oCoordinador := TCoordinadorOperacionesAplicacion.Create(
    TServicioCopiasFalso.Create(rcsCompletada),
    oPresentacion);
  Assert.IsTrue(oCoordinador.CrearCopia('copia.crypt', 'clave'));
  Assert.IsTrue(oPresentacion.Mostrada);
  Assert.IsTrue(oPresentacion.Finalizada);
  Assert.AreEqual(
    Integer(rcsCompletada),
    Integer(oPresentacion.Resultado));
  Assert.AreEqual(
    Integer(toaCopiaSeguridad),
    Integer(oPresentacion.Tipo));
  Assert.IsFalse(oCoordinador.EnCurso);
end;

procedure TPruebasCopiasSeguridad.
  Coordinador_Cancelacion_EsIdempotente;
var
  oCoordinador: ICoordinadorOperacionesAplicacion;
  oPresentacion: TPresentacionOperacionesFalsa;
begin
  oPresentacion := TPresentacionOperacionesFalsa.Create;
  oCoordinador := TCoordinadorOperacionesAplicacion.Create(
    TServicioCopiasFalso.Create(rcsCompletada),
    oPresentacion);
  oCoordinador.IniciarCopia('copia.crypt', 'clave');
  Assert.IsTrue(oCoordinador.EnCurso);
  Assert.IsTrue(oCoordinador.SolicitarCancelacion);
  Assert.IsFalse(oCoordinador.SolicitarCancelacion);
  Assert.IsTrue(oPresentacion.Cancelando);
end;

procedure TPruebasCopiasSeguridad.
  Coordinador_CancelacionTipada_NoNecesitaTexto;
var
  oCoordinador: ICoordinadorOperacionesAplicacion;
  oPresentacion: TPresentacionOperacionesFalsa;
begin
  oPresentacion := TPresentacionOperacionesFalsa.Create;
  oCoordinador := TCoordinadorOperacionesAplicacion.Create(
    TServicioCopiasFalso.Create(
      rcsCancelada,
      True,
      'Interrumpida por el usuario'),
    oPresentacion);
  oCoordinador.IniciarCopia('copia.crypt', 'clave');
  Assert.AreEqual(
    Integer(rcsCancelada),
    Integer(oPresentacion.Resultado));
  Assert.IsFalse(oCoordinador.EnCurso);
end;

procedure TPruebasCopiasSeguridad.
  Coordinador_FalloTipado_NoInterpretaTexto;
var
  oCoordinador: ICoordinadorOperacionesAplicacion;
  oPresentacion: TPresentacionOperacionesFalsa;
begin
  oPresentacion := TPresentacionOperacionesFalsa.Create;
  oCoordinador := TCoordinadorOperacionesAplicacion.Create(
    TServicioCopiasFalso.Create(
      rcsFallida,
      True,
      'La conexión fue cancelada por el servidor'),
    oPresentacion);
  oCoordinador.IniciarCopia('copia.crypt', 'clave');
  Assert.AreEqual(
    Integer(rcsFallida),
    Integer(oPresentacion.Resultado));
  Assert.IsFalse(oCoordinador.EnCurso);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasCopiasSeguridad);

end.
