{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCopiasSeguridad                                        }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
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
    [Test]
    procedure Streaming_RespetaDelimitadores;
    [Test]
    procedure Streaming_RespetaComentarios;
    [Test]
    procedure Streaming_EjecutaSentenciaParcialFinal;
    [Test]
    procedure Streaming_CancelacionDetieneSentencias;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  Backup.Engine,
  inLibBackupPersistenciaIntf,
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
  TPersistenciaRestauracionFalsa = class(
    TInterfacedObject,
    IPersistenciaRestauracionBackup)
  private
    FSentencias: TStringList;
    FTablasNormalizadas: TStringList;
    FPreparada: Boolean;
    FValidada: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PrepararDestino;
    procedure EjecutarSentencia(const ASentencia: string);
    procedure NormalizarBaseDatos;
    function ObtenerTablasConColacionNoValida: TArray<string>;
    procedure NormalizarTabla(const ANombreTabla: string);
    procedure ValidarEstructura;
    property Sentencias: TStringList read FSentencias;
    property Preparada: Boolean read FPreparada;
    property Validada: Boolean read FValidada;
  end;
  TCancelacionStreamingFalsa = class
  private
    FPersistencia: TPersistenciaRestauracionFalsa;
  public
    constructor Create(APersistencia: TPersistenciaRestauracionFalsa);
    procedure Comprobar;
  end;

procedure EjecutarSQLDePrueba(
  const ASQL: string;
  const APersistencia: IPersistenciaRestauracionBackup;
  AComprobarCancelacion: TComprobarCancelacionBackupEvent = nil);
var
  oEjecutor: TEjecutorRestauracionSQL;
  oFlujo: TStringStream;
  oLog: TStringList;
begin
  oFlujo := TStringStream.Create(ASQL, TEncoding.UTF8);
  try
    oLog := TStringList.Create;
    try
      oEjecutor := TEjecutorRestauracionSQL.Create(
        APersistencia,
        AComprobarCancelacion,
        nil,
        oLog);
      try
        oEjecutor.Ejecutar(oFlujo);
      finally
        FreeAndNil(oEjecutor);
      end;
    finally
      FreeAndNil(oLog);
    end;
  finally
    FreeAndNil(oFlujo);
  end;
end;

constructor TPersistenciaRestauracionFalsa.Create;
begin
  inherited Create;
  FSentencias := TStringList.Create;
  FTablasNormalizadas := TStringList.Create;
end;

destructor TPersistenciaRestauracionFalsa.Destroy;
begin
  FreeAndNil(FTablasNormalizadas);
  FreeAndNil(FSentencias);
  inherited Destroy;
end;

procedure TPersistenciaRestauracionFalsa.PrepararDestino;
begin
  FPreparada := True;
end;

procedure TPersistenciaRestauracionFalsa.EjecutarSentencia(
  const ASentencia: string);
begin
  FSentencias.Add(Trim(ASentencia));
end;

procedure TPersistenciaRestauracionFalsa.NormalizarBaseDatos;
begin
end;

function TPersistenciaRestauracionFalsa.
  ObtenerTablasConColacionNoValida: TArray<string>;
begin
  Result := nil;
end;

procedure TPersistenciaRestauracionFalsa.NormalizarTabla(
  const ANombreTabla: string);
begin
  FTablasNormalizadas.Add(ANombreTabla);
end;

procedure TPersistenciaRestauracionFalsa.ValidarEstructura;
begin
  FValidada := True;
end;

constructor TCancelacionStreamingFalsa.Create(
  APersistencia: TPersistenciaRestauracionFalsa);
begin
  inherited Create;
  FPersistencia := APersistencia;
end;

procedure TCancelacionStreamingFalsa.Comprobar;
begin
  if FPersistencia.Sentencias.Count >= 1 then
  begin
    raise EAbort.Create('Cancelada por la prueba');
  end;
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

procedure TPruebasCopiasSeguridad.Streaming_RespetaDelimitadores;
var
  oPersistencia: IPersistenciaRestauracionBackup;
  oPersistenciaFalsa: TPersistenciaRestauracionFalsa;
  sSQL: string;
begin
  oPersistenciaFalsa := TPersistenciaRestauracionFalsa.Create;
  oPersistencia := oPersistenciaFalsa;
  sSQL :=
    'DELIMITER $$' + sLineBreak +
    'CREATE PROCEDURE PRUEBA()' + sLineBreak +
    'BEGIN' + sLineBreak +
    '  SELECT ''texto;$$'';' + sLineBreak +
    'END$$' + sLineBreak +
    'DELIMITER ;' + sLineBreak +
    'INSERT INTO TABLA VALUES (1);';
  EjecutarSQLDePrueba(sSQL, oPersistencia);
  Assert.AreEqual(2, oPersistenciaFalsa.Sentencias.Count);
  Assert.Contains(
    oPersistenciaFalsa.Sentencias[0],
    'CREATE PROCEDURE PRUEBA()');
  Assert.Contains(
    oPersistenciaFalsa.Sentencias[0],
    'SELECT ''texto;$$'';');
  Assert.AreEqual(
    'INSERT INTO TABLA VALUES (1)',
    oPersistenciaFalsa.Sentencias[1]);
  Assert.IsTrue(oPersistenciaFalsa.Preparada);
  Assert.IsTrue(oPersistenciaFalsa.Validada);
end;

procedure TPruebasCopiasSeguridad.Streaming_RespetaComentarios;
var
  oPersistencia: IPersistenciaRestauracionBackup;
  oPersistenciaFalsa: TPersistenciaRestauracionFalsa;
  sSQL: string;
begin
  oPersistenciaFalsa := TPersistenciaRestauracionFalsa.Create;
  oPersistencia := oPersistenciaFalsa;
  sSQL :=
    '-- comentario inicial ;' + sLineBreak +
    '/* comentario de bloque ; */' + sLineBreak +
    'CREATE TABLE TABLA (ID INTEGER); -- comentario ;' + sLineBreak +
    '# comentario entre sentencias ;' + sLineBreak +
    '/*!40000 ALTER TABLE TABLA DISABLE KEYS */;' + sLineBreak +
    'INSERT INTO TABLA VALUES (1);';
  EjecutarSQLDePrueba(sSQL, oPersistencia);
  Assert.AreEqual(3, oPersistenciaFalsa.Sentencias.Count);
  Assert.Contains(
    oPersistenciaFalsa.Sentencias[0],
    'CREATE TABLE TABLA');
  Assert.AreEqual(
    '/*!40000 ALTER TABLE TABLA DISABLE KEYS */',
    oPersistenciaFalsa.Sentencias[1]);
  Assert.AreEqual(
    'INSERT INTO TABLA VALUES (1)',
    oPersistenciaFalsa.Sentencias[2]);
end;

procedure TPruebasCopiasSeguridad.
  Streaming_EjecutaSentenciaParcialFinal;
var
  oPersistencia: IPersistenciaRestauracionBackup;
  oPersistenciaFalsa: TPersistenciaRestauracionFalsa;
begin
  oPersistenciaFalsa := TPersistenciaRestauracionFalsa.Create;
  oPersistencia := oPersistenciaFalsa;
  EjecutarSQLDePrueba(
    'INSERT INTO TABLA VALUES (1)',
    oPersistencia);
  Assert.AreEqual(1, oPersistenciaFalsa.Sentencias.Count);
  Assert.AreEqual(
    'INSERT INTO TABLA VALUES (1)',
    oPersistenciaFalsa.Sentencias[0]);
end;

procedure TPruebasCopiasSeguridad.
  Streaming_CancelacionDetieneSentencias;
var
  bCancelada: Boolean;
  oCancelacion: TCancelacionStreamingFalsa;
  oPersistencia: IPersistenciaRestauracionBackup;
  oPersistenciaFalsa: TPersistenciaRestauracionFalsa;
begin
  oPersistenciaFalsa := TPersistenciaRestauracionFalsa.Create;
  oPersistencia := oPersistenciaFalsa;
  oCancelacion := TCancelacionStreamingFalsa.Create(oPersistenciaFalsa);
  try
    bCancelada := False;
    try
      EjecutarSQLDePrueba(
        'INSERT INTO TABLA VALUES (1);' + sLineBreak +
        'INSERT INTO TABLA VALUES (2);',
        oPersistencia,
        oCancelacion.Comprobar);
    except
      on E: EAbort do
        bCancelada := True;
    end;
    Assert.IsTrue(bCancelada);
    Assert.AreEqual(1, oPersistenciaFalsa.Sentencias.Count);
  finally
    FreeAndNil(oCancelacion);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasCopiasSeguridad);

end.
