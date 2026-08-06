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
    [Test]
    procedure Volcado_TablaVacia_NoEscribeDatos;
    [Test]
    procedure Volcado_LoteGrande_ConservaLotesAcotados;
    [Test]
    procedure Volcado_Cancelacion_NoVuelcaLoteParcial;
    [Test]
    procedure Volcado_DependenciaMalformada_FallaTemprano;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  Data.DB,
  Datasnap.DBClient,
  Backup.Engine,
  Backup.LecturaDatos,
  Backup.Types,
  Core_Interfaces,
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
  TEsquemaVolcadoFalso = class(
    TInterfacedObject,
    ILectorEsquemaBBDD)
  private
    FAutoincremento: Boolean;
  public
    constructor Create(AAutoincremento: Boolean);
    function GetDatabaseName: string;
    function GetTables: TStringList;
    function GetTableStructure(const TableName: string): TTableInfo;
    function GetTableIndexes(
      const TableName: string): TArray<TIndexInfo>;
  end;
  TDatosVolcadoFalso = class(
    TInterfacedObject,
    ILectorDatosBBDD)
  private
    FFilas: Integer;
  public
    constructor Create(AFilas: Integer);
    function GetData(
      const TableName: string;
      const Filter: string = ''): TDataSet;
    function GetRowCount(
      const TableName: string;
      const Filter: string = ''): Integer;
  end;
  TEscritorVolcadoFalso = class(
    TInterfacedObject,
    IScriptWriter)
  private
    FComentarios: TStringList;
    FComandos: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddComment(const Text: string);
    procedure AddCommand(const SQL: string);
    function GetScript: string;
    function ContarComandos(const AInicio: string): Integer;
    property Comentarios: TStringList read FComentarios;
    property Comandos: TStringList read FComandos;
  end;
  TValoresVolcadoFalso = class(
    TInterfacedObject,
    IGeneradorSqlValores)
  public
    function QuoteIdentifier(const Identifier: string): string;
    function ValueToSQL(const Field: TField): string;
    function GenerateInsertSQL(
      const TableName: string;
      Fields, Values: TStringList;
      const HasIdentity: Boolean = False): string;
  end;
  TObservadorVolcadoFalso = class
  private
    FCancelarEnPaso: Integer;
    FEtapa: string;
    FFilasLeidas: Integer;
    FPaso: Integer;
    FTotal: Integer;
  public
    constructor Create(ACancelarEnPaso: Integer = 0);
    procedure Progreso(
      const AEtapa: string; APaso, ATotal: Integer);
    procedure FilaLeida;
    property Etapa: string read FEtapa;
    property FilasLeidas: Integer read FFilasLeidas;
    property Paso: Integer read FPaso;
    property Total: Integer read FTotal;
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

constructor TEsquemaVolcadoFalso.Create(AAutoincremento: Boolean);
begin
  inherited Create;
  FAutoincremento := AAutoincremento;
end;

function TEsquemaVolcadoFalso.GetDatabaseName: string;
begin
  Result := 'PRUEBA';
end;

function TEsquemaVolcadoFalso.GetTables: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('TABLA');
end;

function TEsquemaVolcadoFalso.GetTableStructure(
  const TableName: string): TTableInfo;
var
  oColumna: TColumnInfo;
begin
  Result := TTableInfo.Create;
  Result.TableName := TableName;
  oColumna := Default(TColumnInfo);
  oColumna.ColumnName := 'ID';
  if FAutoincremento then
  begin
    oColumna.Extra := 'auto_increment';
  end;
  Result.Columns.Add(oColumna);
end;

function TEsquemaVolcadoFalso.GetTableIndexes(
  const TableName: string): TArray<TIndexInfo>;
begin
  Result := nil;
end;

constructor TDatosVolcadoFalso.Create(AFilas: Integer);
begin
  inherited Create;
  FFilas := AFilas;
end;

function TDatosVolcadoFalso.GetData(
  const TableName, Filter: string): TDataSet;
var
  I: Integer;
  oDatos: TClientDataSet;
begin
  oDatos := TClientDataSet.Create(nil);
  oDatos.FieldDefs.Add('ID', ftInteger);
  oDatos.CreateDataSet;
  for I := 1 to FFilas do
  begin
    oDatos.AppendRecord([I]);
  end;
  oDatos.First;
  Result := oDatos;
end;

function TDatosVolcadoFalso.GetRowCount(
  const TableName, Filter: string): Integer;
begin
  Result := FFilas;
end;

constructor TEscritorVolcadoFalso.Create;
begin
  inherited Create;
  FComentarios := TStringList.Create;
  FComandos := TStringList.Create;
end;

destructor TEscritorVolcadoFalso.Destroy;
begin
  FreeAndNil(FComandos);
  FreeAndNil(FComentarios);
  inherited Destroy;
end;

procedure TEscritorVolcadoFalso.AddComment(const Text: string);
begin
  FComentarios.Add(Text);
end;

procedure TEscritorVolcadoFalso.AddCommand(const SQL: string);
begin
  FComandos.Add(SQL);
end;

function TEscritorVolcadoFalso.GetScript: string;
begin
  Result := FComandos.Text;
end;

function TEscritorVolcadoFalso.ContarComandos(
  const AInicio: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FComandos.Count - 1 do
  begin
    if StartsText(AInicio, FComandos[I]) then
    begin
      Inc(Result);
    end;
  end;
end;

function TValoresVolcadoFalso.QuoteIdentifier(
  const Identifier: string): string;
begin
  Result := '`' + Identifier + '`';
end;

function TValoresVolcadoFalso.ValueToSQL(const Field: TField): string;
begin
  if Field.IsNull then
  begin
    Result := 'NULL';
  end
  else
  begin
    Result := Field.AsString;
  end;
end;

function UnirValoresVolcado(APartes: TStrings): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to APartes.Count - 1 do
  begin
    if I > 0 then
    begin
      Result := Result + ', ';
    end;
    Result := Result + APartes[I];
  end;
end;

function TValoresVolcadoFalso.GenerateInsertSQL(
  const TableName: string;
  Fields, Values: TStringList;
  const HasIdentity: Boolean): string;
begin
  Result := 'INSERT INTO ' + QuoteIdentifier(TableName) +
    ' (' + UnirValoresVolcado(Fields) + ') VALUES (' +
    UnirValoresVolcado(Values) + ');';
end;

constructor TObservadorVolcadoFalso.Create(ACancelarEnPaso: Integer);
begin
  inherited Create;
  FCancelarEnPaso := ACancelarEnPaso;
end;

procedure TObservadorVolcadoFalso.Progreso(
  const AEtapa: string; APaso, ATotal: Integer);
begin
  FEtapa := AEtapa;
  FPaso := APaso;
  FTotal := ATotal;
  if (FCancelarEnPaso > 0) and (APaso >= FCancelarEnPaso) then
  begin
    raise EAbort.Create('Cancelada por la prueba de volcado');
  end;
end;

procedure TObservadorVolcadoFalso.FilaLeida;
begin
  Inc(FFilasLeidas);
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

procedure TPruebasCopiasSeguridad.
  Volcado_TablaVacia_NoEscribeDatos;
var
  iDatos: ILectorDatosBBDD;
  iEsquema: ILectorEsquemaBBDD;
  iEscritor: IScriptWriter;
  iValores: IGeneradorSqlValores;
  oEscritor: TEscritorVolcadoFalso;
  oLector: TLecturaDatosTablaBackup;
  oObservador: TObservadorVolcadoFalso;
begin
  iEsquema := TEsquemaVolcadoFalso.Create(False);
  iDatos := TDatosVolcadoFalso.Create(0);
  oEscritor := TEscritorVolcadoFalso.Create;
  iEscritor := oEscritor;
  iValores := TValoresVolcadoFalso.Create;
  oObservador := TObservadorVolcadoFalso.Create;
  oLector := TLecturaDatosTablaBackup.Create(
    TDependenciasLecturaDatosBackup.Crear(
      iEsquema, iDatos, iEscritor, iValores),
    TConfiguracionLecturaDatosBackup.Crear(True, 500),
    oObservador.Progreso,
    oObservador.FilaLeida);
  try
    oLector.Ejecutar('TABLA', '');
    Assert.AreEqual(0, oEscritor.Comentarios.Count);
    Assert.AreEqual(0, oEscritor.Comandos.Count);
    Assert.AreEqual(0, oObservador.FilasLeidas);
    Assert.AreEqual('TABLA (datos)', oObservador.Etapa);
    Assert.AreEqual(0, oObservador.Total);
  finally
    FreeAndNil(oLector);
    FreeAndNil(oObservador);
  end;
end;

procedure TPruebasCopiasSeguridad.
  Volcado_LoteGrande_ConservaLotesAcotados;
var
  iDatos: ILectorDatosBBDD;
  iEsquema: ILectorEsquemaBBDD;
  iEscritor: IScriptWriter;
  iValores: IGeneradorSqlValores;
  oEscritor: TEscritorVolcadoFalso;
  oLector: TLecturaDatosTablaBackup;
  oObservador: TObservadorVolcadoFalso;
begin
  iEsquema := TEsquemaVolcadoFalso.Create(True);
  iDatos := TDatosVolcadoFalso.Create(1201);
  oEscritor := TEscritorVolcadoFalso.Create;
  iEscritor := oEscritor;
  iValores := TValoresVolcadoFalso.Create;
  oObservador := TObservadorVolcadoFalso.Create;
  oLector := TLecturaDatosTablaBackup.Create(
    TDependenciasLecturaDatosBackup.Crear(
      iEsquema, iDatos, iEscritor, iValores),
    TConfiguracionLecturaDatosBackup.Crear(True, 500),
    oObservador.Progreso,
    oObservador.FilaLeida);
  try
    oLector.Ejecutar('TABLA', '');
    Assert.AreEqual(3, oEscritor.ContarComandos('INSERT INTO'));
    Assert.IsTrue(
      oEscritor.Comentarios.IndexOf('Datos de TABLA') >= 0);
    Assert.IsTrue(
      oEscritor.Comentarios.IndexOf(
        '1201 registros exportados') >= 0);
    Assert.AreEqual(1201, oObservador.FilasLeidas);
    Assert.AreEqual('TABLA OK', oObservador.Etapa);
    Assert.AreEqual(1201, oObservador.Paso);
  finally
    FreeAndNil(oLector);
    FreeAndNil(oObservador);
  end;
end;

procedure TPruebasCopiasSeguridad.
  Volcado_Cancelacion_NoVuelcaLoteParcial;
var
  bCancelada: Boolean;
  iDatos: ILectorDatosBBDD;
  iEsquema: ILectorEsquemaBBDD;
  iEscritor: IScriptWriter;
  iValores: IGeneradorSqlValores;
  oEscritor: TEscritorVolcadoFalso;
  oLector: TLecturaDatosTablaBackup;
  oObservador: TObservadorVolcadoFalso;
begin
  iEsquema := TEsquemaVolcadoFalso.Create(False);
  iDatos := TDatosVolcadoFalso.Create(1200);
  oEscritor := TEscritorVolcadoFalso.Create;
  iEscritor := oEscritor;
  iValores := TValoresVolcadoFalso.Create;
  oObservador := TObservadorVolcadoFalso.Create(12);
  oLector := TLecturaDatosTablaBackup.Create(
    TDependenciasLecturaDatosBackup.Crear(
      iEsquema, iDatos, iEscritor, iValores),
    TConfiguracionLecturaDatosBackup.Crear(True, 500),
    oObservador.Progreso,
    oObservador.FilaLeida);
  try
    bCancelada := False;
    try
      oLector.Ejecutar('TABLA', '');
    except
      on E: EAbort do
      begin
        bCancelada := True;
      end;
    end;
    Assert.IsTrue(bCancelada);
    Assert.AreEqual(12, oObservador.FilasLeidas);
    Assert.AreEqual(0, oEscritor.ContarComandos('INSERT INTO'));
  finally
    FreeAndNil(oLector);
    FreeAndNil(oObservador);
  end;
end;

procedure TPruebasCopiasSeguridad.
  Volcado_DependenciaMalformada_FallaTemprano;
var
  bExcepcionCapturada: Boolean;
  iEsquema: ILectorEsquemaBBDD;
  oDependencias: TDependenciasLecturaDatosBackup;
  oLector: TLecturaDatosTablaBackup;
begin
  iEsquema := TEsquemaVolcadoFalso.Create(False);
  oDependencias := TDependenciasLecturaDatosBackup.Crear(
    iEsquema,
    nil,
    nil,
    nil);
  oLector := nil;
  bExcepcionCapturada := False;
  try
    try
      oLector := TLecturaDatosTablaBackup.Create(
        oDependencias,
        TConfiguracionLecturaDatosBackup.Crear(True, 500),
        nil,
        nil);
    except
      on E: EArgumentNilException do
      begin
        bExcepcionCapturada := True;
        Assert.Contains(E.Message, 'ADependencias.Datos');
      end;
    end;
    Assert.IsTrue(bExcepcionCapturada);
  finally
    FreeAndNil(oLector);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasCopiasSeguridad);

end.
