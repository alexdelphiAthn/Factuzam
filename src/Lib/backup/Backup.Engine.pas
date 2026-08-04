{******************************************************************************}
{                                                                              }
{  Módulo:       Backup.Engine                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Genera copias y ejecuta restauraciones SQL mediante contratos mínimos.    }
{******************************************************************************}
unit Backup.Engine;

interface

uses
  Core_Interfaces, Backup.Types, System.Classes,
  Data.DB, System.SysUtils, System.StrUtils, System.Diagnostics,
  inLibBackupPersistenciaIntf;

type
  // AEtapa: nombre de tabla o etapa actual
  // APaso, ATotal: progreso dentro de la etapa (tabla)
  // AFilaGlobal: filas procesadas acumuladas en todo el backup
  // AFilasGlobalTotal: total estimado de filas en todas las tablas
  TBackupProgressEvent = procedure(const AEtapa: string;
                                    APaso, ATotal: Integer;
                                    AFilaGlobal,
                                    AFilasGlobalTotal: Integer) of object;

  TComprobarCancelacionBackupEvent = procedure of object;
  TProgresoRestauracionBackupEvent = procedure(
    APosicion, ATotal, ASentencias: Integer) of object;

  TEjecutorRestauracionSQL = class
  private
    FPersistencia: IPersistenciaRestauracionBackup;
    FComprobarCancelacion: TComprobarCancelacionBackupEvent;
    FOnProgreso: TProgresoRestauracionBackupEvent;
    FLog: TStrings;
    FFlujo: TStream;
    FSentencia: TStringBuilder;
    FDelimitador: string;
    FCaracterCadena: Char;
    FEnCadena: Boolean;
    FEnComentarioBloque: Boolean;
    FTieneContenidoEjecutable: Boolean;
    FColacionesNormalizadas: Boolean;
    FSentenciasEjecutadas: Integer;
    FErrores: Integer;
    FPosicion: Integer;
    FTotal: Integer;
    FUltimaPosicionNotificada: Int64;
    FPrimerError: string;
    procedure ComprobarCancelacion;
    procedure Inicializar(AFlujo: TStream);
    procedure NotificarProgreso(AForzar: Boolean = False);
    procedure ProcesarLectura(ALector: TStreamReader);
    procedure ProcesarLinea(const ALinea: string);
    procedure ProcesarComentarioBloque(
      const ALinea: string; var AIndice: Integer);
    procedure ProcesarCadena(
      const ALinea: string; var AIndice: Integer);
    function ProcesarContenidoNormal(
      const ALinea: string; var AIndice: Integer): Boolean;
    procedure EjecutarSentenciaActual;
    procedure NormalizarColaciones;
    function EsLineaIgnorable(const ALinea: string): Boolean;
    function EsDirectivaDelimitador(
      const ALinea: string; out ADelimitador: string): Boolean;
    function EsComentarioLinea(
      const ALinea: string; AIndice: Integer): Boolean;
    function CoincideDelimitador(
      const ALinea: string; AIndice: Integer): Boolean;
    function EsCreacionVista(const ASentencia: string): Boolean;
  public
    constructor Create(
      const APersistencia: IPersistenciaRestauracionBackup;
      AComprobarCancelacion: TComprobarCancelacionBackupEvent;
      AOnProgreso: TProgresoRestauracionBackupEvent;
      ALog: TStrings);
    procedure Ejecutar(AFlujo: TStream);
    property SentenciasEjecutadas: Integer read FSentenciasEjecutadas;
    property Errores: Integer read FErrores;
    property PrimerError: string read FPrimerError;
  end;

  TDBBackupEngine = class
  private
    // El volcado solo conserva las vistas segregadas que usa (§14.2)
    FLecturas: TServiciosLecturaBBDD;
    FWriter: IScriptWriter;
    FValores: IGeneradorSqlValores;
    FCreacion: IGeneradorSqlCreacion;
    FEliminacion: IGeneradorSqlEliminacion;
    FOptions: TBackupOptions;
    FIncludeTables: TStringList;
    FExcludeTables: TStringList;
    FDataFilters: TStringList;
    FOnProgress: TBackupProgressEvent;
    FFilasGlobalTotal: Integer;
    FFilasProcesadas: Integer;
    procedure BackupTables;
    procedure BackupTable(const TableName: string);
    procedure BackupTableData(const TableName: string);
    procedure BackupViews;
    procedure BackupTriggers;
    procedure BackupProcedures;
    procedure BackupFunctions;
    function ShouldProcessTable(const TableName: string): Boolean;
    procedure DoProgress(const AEtapa: string; APaso, ATotal: Integer);
    procedure ContarFilasTotal;
  public
    constructor Create(const ALecturas: TServiciosLecturaBBDD;
                       Writer: IScriptWriter;
                       const ASql: TServiciosSqlBBDD;
                       Options: TBackupOptions;
                       IncludeTables, ExcludeTables: TStringList;
                       DataFilters: TStringList = nil);
    procedure GenerateBackup;
    property OnProgress: TBackupProgressEvent
      read FOnProgress write FOnProgress;
  end;

function CrearFabricaPersistenciaBackupPredeterminada:
  IFabricaPersistenciaBackup;

implementation

uses
  UniDataBackupRepositorio;

const
  MAX_BYTES_LOTE_EXTENDIDO = 1024 * 1024;
  BYTES_ENTRE_PROGRESO_RESTAURACION = 4 * 1024 * 1024;

constructor TEjecutorRestauracionSQL.Create(
  const APersistencia: IPersistenciaRestauracionBackup;
  AComprobarCancelacion: TComprobarCancelacionBackupEvent;
  AOnProgreso: TProgresoRestauracionBackupEvent;
  ALog: TStrings);
begin
  inherited Create;
  if not Assigned(APersistencia) then
  begin
    raise EArgumentNilException.Create('APersistencia');
  end;
  FPersistencia := APersistencia;
  FComprobarCancelacion := AComprobarCancelacion;
  FOnProgreso := AOnProgreso;
  FLog := ALog;
end;

procedure TEjecutorRestauracionSQL.ComprobarCancelacion;
begin
  if Assigned(FComprobarCancelacion) then
  begin
    FComprobarCancelacion;
  end;
end;

procedure TEjecutorRestauracionSQL.Inicializar(AFlujo: TStream);
begin
  FFlujo := AFlujo;
  FDelimitador := ';';
  FCaracterCadena := #0;
  FEnCadena := False;
  FEnComentarioBloque := False;
  FTieneContenidoEjecutable := False;
  FColacionesNormalizadas := False;
  FSentenciasEjecutadas := 0;
  FErrores := 0;
  FPrimerError := '';
  FUltimaPosicionNotificada := 0;
  FTotal := Integer(FFlujo.Size div 1024);
  if FTotal <= 0 then
  begin
    FTotal := 1;
  end;
  FPosicion := 0;
  if Assigned(FLog) then
  begin
    FLog.Add(
      ' -- El DDL de MariaDB puede confirmar cambios de forma implícita;');
    FLog.Add(' -- la restauración no promete rollback transaccional.');
  end;
end;

procedure TEjecutorRestauracionSQL.NotificarProgreso(AForzar: Boolean);
begin
  if Assigned(FFlujo) then
  begin
    FPosicion := Integer(FFlujo.Position div 1024);
    if FPosicion > FTotal then
    begin
      FPosicion := FTotal;
    end;
    if AForzar or
       (FFlujo.Position - FUltimaPosicionNotificada >=
        BYTES_ENTRE_PROGRESO_RESTAURACION) then
    begin
      if Assigned(FOnProgreso) then
      begin
        FOnProgreso(
          FPosicion,
          FTotal,
          FSentenciasEjecutadas);
      end;
      FUltimaPosicionNotificada := FFlujo.Position;
    end;
  end;
end;

function TEjecutorRestauracionSQL.EsLineaIgnorable(
  const ALinea: string): Boolean;
var
  sLinea: string;
begin
  sLinea := Trim(ALinea);
  Result := (sLinea = '') or
            StartsText('--', sLinea) or
            StartsText('#', sLinea);
end;

function TEjecutorRestauracionSQL.EsDirectivaDelimitador(
  const ALinea: string; out ADelimitador: string): Boolean;
const
  DIRECTIVA_DELIMITADOR = 'DELIMITER';
var
  sLinea: string;
begin
  Result := False;
  ADelimitador := '';
  sLinea := Trim(ALinea);
  if Length(sLinea) >= Length(DIRECTIVA_DELIMITADOR) then
  begin
    Result := SameText(
      Copy(sLinea, 1, Length(DIRECTIVA_DELIMITADOR)),
      DIRECTIVA_DELIMITADOR);
    if Result and (Length(sLinea) > Length(DIRECTIVA_DELIMITADOR)) then
    begin
      Result := CharInSet(
        sLinea[Length(DIRECTIVA_DELIMITADOR) + 1],
        [' ', #9]);
    end;
    if Result then
    begin
      ADelimitador := Trim(
        Copy(sLinea, Length(DIRECTIVA_DELIMITADOR) + 1, MaxInt));
      if ADelimitador = '' then
      begin
        ADelimitador := ';';
      end;
    end;
  end;
end;

function TEjecutorRestauracionSQL.EsComentarioLinea(
  const ALinea: string; AIndice: Integer): Boolean;
var
  bEsDobleGuion: Boolean;
begin
  bEsDobleGuion :=
    (AIndice < Length(ALinea)) and
    (ALinea[AIndice] = '-') and
    (ALinea[AIndice + 1] = '-');
  Result := False;
  if bEsDobleGuion then
  begin
    Result := AIndice + 1 = Length(ALinea);
    if not Result then
    begin
      Result := CharInSet(
        ALinea[AIndice + 2],
        [' ', #9, #13, #10]);
    end;
  end;
  if not Result then
  begin
    Result := ALinea[AIndice] = '#';
  end;
end;

function TEjecutorRestauracionSQL.CoincideDelimitador(
  const ALinea: string; AIndice: Integer): Boolean;
begin
  Result :=
    (FDelimitador <> '') and
    (Copy(ALinea, AIndice, Length(FDelimitador)) = FDelimitador);
end;

function TEjecutorRestauracionSQL.EsCreacionVista(
  const ASentencia: string): Boolean;
var
  sSentencia: string;
begin
  sSentencia := UpperCase(ASentencia);
  sSentencia := StringReplace(sSentencia, #13, ' ', [rfReplaceAll]);
  sSentencia := StringReplace(sSentencia, #10, ' ', [rfReplaceAll]);
  Result :=
    (Pos('CREATE ', sSentencia) > 0) and
    (Pos(' VIEW ', sSentencia) > 0);
end;

procedure TEjecutorRestauracionSQL.ProcesarComentarioBloque(
  const ALinea: string; var AIndice: Integer);
begin
  FSentencia.Append(ALinea[AIndice]);
  if (ALinea[AIndice] = '*') and (AIndice < Length(ALinea)) and
     (ALinea[AIndice + 1] = '/') then
  begin
    FSentencia.Append(ALinea[AIndice + 1]);
    FEnComentarioBloque := False;
    Inc(AIndice, 2);
  end
  else
  begin
    Inc(AIndice);
  end;
end;

procedure TEjecutorRestauracionSQL.ProcesarCadena(
  const ALinea: string; var AIndice: Integer);
begin
  FSentencia.Append(ALinea[AIndice]);
  if (ALinea[AIndice] = '\') and (AIndice < Length(ALinea)) then
  begin
    FSentencia.Append(ALinea[AIndice + 1]);
    Inc(AIndice, 2);
  end
  else if ALinea[AIndice] = FCaracterCadena then
  begin
    if (AIndice < Length(ALinea)) and
       (ALinea[AIndice + 1] = FCaracterCadena) then
    begin
      FSentencia.Append(ALinea[AIndice + 1]);
      Inc(AIndice, 2);
    end
    else
    begin
      FEnCadena := False;
      Inc(AIndice);
    end;
  end
  else
  begin
    Inc(AIndice);
  end;
end;

function TEjecutorRestauracionSQL.ProcesarContenidoNormal(
  const ALinea: string; var AIndice: Integer): Boolean;
var
  sResto: string;
begin
  Result := False;
  if CoincideDelimitador(ALinea, AIndice) then
  begin
    EjecutarSentenciaActual;
    Inc(AIndice, Length(FDelimitador));
    sResto := Trim(Copy(ALinea, AIndice, MaxInt));
    Result :=
      (sResto = '') or
      StartsText('--', sResto) or
      StartsText('#', sResto);
  end
  else if (ALinea[AIndice] = '/') and
          (AIndice < Length(ALinea)) and
          (ALinea[AIndice + 1] = '*') then
  begin
    if (AIndice + 1 < Length(ALinea)) and
       (ALinea[AIndice + 2] = '!') then
    begin
      FTieneContenidoEjecutable := True;
    end;
    FSentencia.Append(ALinea[AIndice]);
    FSentencia.Append(ALinea[AIndice + 1]);
    FEnComentarioBloque := True;
    Inc(AIndice, 2);
  end
  else if EsComentarioLinea(ALinea, AIndice) then
  begin
    FSentencia.Append(Copy(ALinea, AIndice, MaxInt));
    AIndice := Length(ALinea) + 1;
    Result := True;
  end
  else if CharInSet(ALinea[AIndice], ['''', '"', '`']) then
  begin
    FCaracterCadena := ALinea[AIndice];
    FEnCadena := True;
    FTieneContenidoEjecutable := True;
    FSentencia.Append(ALinea[AIndice]);
    Inc(AIndice);
  end
  else
  begin
    if not CharInSet(ALinea[AIndice], [' ', #9, #13, #10]) then
    begin
      FTieneContenidoEjecutable := True;
    end;
    FSentencia.Append(ALinea[AIndice]);
    Inc(AIndice);
  end;
end;

procedure TEjecutorRestauracionSQL.ProcesarLinea(
  const ALinea: string);
var
  bFinalizarLinea: Boolean;
  iIndice: Integer;
begin
  iIndice := 1;
  bFinalizarLinea := False;
  while (iIndice <= Length(ALinea)) and not bFinalizarLinea do
  begin
    if FEnComentarioBloque then
    begin
      ProcesarComentarioBloque(ALinea, iIndice);
    end
    else if FEnCadena then
    begin
      ProcesarCadena(ALinea, iIndice);
    end
    else
    begin
      bFinalizarLinea := ProcesarContenidoNormal(ALinea, iIndice);
    end;
  end;
  if FSentencia.Length > 0 then
  begin
    FSentencia.AppendLine;
  end;
end;

procedure TEjecutorRestauracionSQL.NormalizarColaciones;
var
  aTablas: TArray<string>;
  iTabla: Integer;
begin
  if not FColacionesNormalizadas then
  begin
    if Assigned(FLog) then
    begin
      FLog.Add(' -- Normalizando colaciones antes de crear vistas');
    end;
    FPersistencia.NormalizarBaseDatos;
    aTablas := FPersistencia.ObtenerTablasConColacionNoValida;
    for iTabla := Low(aTablas) to High(aTablas) do
    begin
      ComprobarCancelacion;
      FPersistencia.NormalizarTabla(aTablas[iTabla]);
    end;
    if Assigned(FLog) and (Length(aTablas) > 0) then
    begin
      FLog.Add(
        Format(' -- Tablas normalizadas: %d', [Length(aTablas)]));
    end;
    FColacionesNormalizadas := True;
  end;
end;

procedure TEjecutorRestauracionSQL.EjecutarSentenciaActual;
var
  oReloj: TStopwatch;
  sResumen: string;
  sSentencia: string;
begin
  sSentencia := Trim(FSentencia.ToString);
  FSentencia.Clear;
  if FTieneContenidoEjecutable and (sSentencia <> '') then
  begin
    ComprobarCancelacion;
    Inc(FSentenciasEjecutadas);
    oReloj := TStopwatch.StartNew;
    try
      if EsCreacionVista(sSentencia) then
      begin
        NormalizarColaciones;
      end;
      FPersistencia.EjecutarSentencia(sSentencia);
      if Assigned(FLog) and ((FSentenciasEjecutadas mod 250) = 0) then
      begin
        FLog.Add(Format(
          ' -- [OK] Sentencias ejecutadas: %d | %d / %d KB',
          [FSentenciasEjecutadas, FPosicion, FTotal]));
      end;
    except
      on E: Exception do
      begin
        Inc(FErrores);
        if FPrimerError = '' then
        begin
          FPrimerError := E.Message;
        end;
        sResumen := sSentencia;
        if Length(sResumen) > 4000 then
        begin
          sResumen := Copy(sResumen, 1, 4000) + sLineBreak + '...';
        end;
        if Assigned(FLog) then
        begin
          FLog.Add(Format(
            ' -- [ERROR] Sentencia %d: %s | Tiempo: %d ms',
            [FSentenciasEjecutadas, E.Message,
             oReloj.ElapsedMilliseconds]));
          FLog.Add(sResumen);
          FLog.Add('--------------------------------------------------');
        end;
        raise;
      end;
    end;
    ComprobarCancelacion;
  end;
  FTieneContenidoEjecutable := False;
end;

procedure TEjecutorRestauracionSQL.ProcesarLectura(
  ALector: TStreamReader);
var
  sLinea: string;
  sNuevoDelimitador: string;
begin
  while not ALector.EndOfStream do
  begin
    ComprobarCancelacion;
    sLinea := ALector.ReadLine;
    if (FSentencia.Length = 0) and
       (not FEnCadena) and
       (not FEnComentarioBloque) and
       EsDirectivaDelimitador(sLinea, sNuevoDelimitador) then
    begin
      FDelimitador := sNuevoDelimitador;
    end
    else if not ((FSentencia.Length = 0) and
                 EsLineaIgnorable(sLinea)) then
    begin
      ProcesarLinea(sLinea);
    end;
    NotificarProgreso;
  end;
end;

procedure TEjecutorRestauracionSQL.Ejecutar(AFlujo: TStream);
var
  oLector: TStreamReader;
begin
  if not Assigned(AFlujo) then
  begin
    raise EArgumentNilException.Create('AFlujo');
  end;
  ComprobarCancelacion;
  FPersistencia.PrepararDestino;
  Inicializar(AFlujo);
  FSentencia := TStringBuilder.Create;
  try
    oLector := TStreamReader.Create(AFlujo, TEncoding.UTF8, True);
    try
      NotificarProgreso(True);
      ProcesarLectura(oLector);
      ComprobarCancelacion;
      EjecutarSentenciaActual;
      FPersistencia.ValidarEstructura;
      FPosicion := FTotal;
      NotificarProgreso(True);
      if Assigned(FLog) then
      begin
        FLog.Add(Format(
          ' -- Restauración SQL completada. Sentencias ejecutadas: %d',
          [FSentenciasEjecutadas]));
      end;
    finally
      FreeAndNil(oLector);
    end;
  finally
    FreeAndNil(FSentencia);
  end;
end;

function CrearFabricaPersistenciaBackupPredeterminada:
  IFabricaPersistenciaBackup;
begin
  Result := CrearFabricaPersistenciaBackupUniDAC;
end;

constructor TDBBackupEngine.Create(const ALecturas: TServiciosLecturaBBDD;
                                   Writer: IScriptWriter;
                                   const ASql: TServiciosSqlBBDD;
                                   Options: TBackupOptions;
                                   IncludeTables, ExcludeTables: TStringList;
                                   DataFilters: TStringList = nil);
begin
  FLecturas := ALecturas;
  FWriter := Writer;
  // De los helpers SQL, el volcado no usa comparación ni modificación
  FValores := ASql.Valores;
  FCreacion := ASql.Creacion;
  FEliminacion := ASql.Eliminacion;
  FOptions := Options;
  FIncludeTables := IncludeTables;
  FExcludeTables := ExcludeTables;
  FDataFilters := DataFilters;
end;

procedure TDBBackupEngine.DoProgress(const AEtapa: string;
                                     APaso, ATotal: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(AEtapa, APaso, ATotal,
                FFilasProcesadas, FFilasGlobalTotal);
end;

procedure TDBBackupEngine.ContarFilasTotal;
var
  Tables: TStringList;
  i: Integer;
  sFilter: string;
begin
  FFilasGlobalTotal := 0;
  Tables := FLecturas.Esquema.GetTables;
  try
    for i := 0 to Tables.Count - 1 do
    begin
      if ShouldProcessTable(Tables[i]) then
      begin
        sFilter := '';
        if Assigned(FDataFilters) then
          sFilter := FDataFilters.Values[Tables[i]];
        FFilasGlobalTotal := FFilasGlobalTotal +
          FLecturas.Datos.GetRowCount(Tables[i], sFilter);
      end;
    end;
  finally
    Tables.Free;
  end;
end;

function TDBBackupEngine.ShouldProcessTable(const TableName: string): Boolean;
begin
  Result := True;
  
  // Si hay lista de inclusión, la tabla debe estar en ella
  if (FIncludeTables.Count > 0) and 
     (FIncludeTables.IndexOf(TableName) = -1) then
    Result := False;
    
  // Si está en la lista de exclusión, no procesarla
  if FExcludeTables.IndexOf(TableName) >= 0 then
    Result := False;
end;

procedure TDBBackupEngine.GenerateBackup;
begin
  FFilasProcesadas := 0;
  if FOptions.WithData then
    ContarFilasTotal;
  FWriter.AddComment('========================================');
  FWriter.AddComment('Backup generado: ' + DateTimeToStr(Now));
  FWriter.AddComment('Base de datos: ' + FLecturas.Esquema.GetDatabaseName);
  FWriter.AddComment('========================================');
  FWriter.AddCommand('');
  FWriter.AddCommand('SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci;');
  FWriter.AddCommand('');
  
  if FOptions.UseTransactions then
  begin
    FWriter.AddCommand('START TRANSACTION;');
    FWriter.AddCommand('');
  end;
  
  // Deshabilitar checks para importar más rápido
  FWriter.AddCommand('SET FOREIGN_KEY_CHECKS=0;');
  FWriter.AddCommand('SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";');
  FWriter.AddCommand('SET AUTOCOMMIT=0;');
  FWriter.AddCommand('');
  
  // Backup de tablas (estructura y datos)
  BackupTables;
  
  // Backup de vistas
  if FOptions.WithViews then
    BackupViews;
    
  // Backup de procedures
  if FOptions.WithProcedures then
    BackupProcedures;
    
  // Backup de funciones
  if FOptions.WithFunctions then
    BackupFunctions;
    
  // Backup de triggers (al final porque dependen de las tablas)
  if FOptions.WithTriggers then
    BackupTriggers;
  
  // Restaurar checks
  FWriter.AddCommand('');
  FWriter.AddCommand('SET FOREIGN_KEY_CHECKS=1;');
  
  if FOptions.UseTransactions then
  begin
    FWriter.AddCommand('COMMIT;');
  end;
  
  FWriter.AddCommand('');
  FWriter.AddComment('Backup completado: ' + DateTimeToStr(Now));
end;

procedure TDBBackupEngine.BackupTables;
var
  Tables: TStringList;
  i: Integer;
begin
  FWriter.AddComment('');
  FWriter.AddComment('========================================');
  FWriter.AddComment('TABLAS');
  FWriter.AddComment('========================================');
  FWriter.AddCommand('');
  
  Tables := FLecturas.Esquema.GetTables;
  try
    for i := 0 to Tables.Count - 1 do
    begin
      if ShouldProcessTable(Tables[i]) then
      begin
        DoProgress(Tables[i], i + 1, Tables.Count);
        BackupTable(Tables[i]);
      end;
    end;
  finally
    Tables.Free;
  end;
end;

procedure TDBBackupEngine.BackupTable(const TableName: string);
var
  TableInfo: TTableInfo;
  Indexes: TArray<TIndexInfo>;
  Idx: TIndexInfo;
begin
  FWriter.AddComment('');
  FWriter.AddComment('Tabla: ' + TableName);
  FWriter.AddComment('');
  
  // Drop table si se especificó
  if FOptions.DropTablesFirst then
  begin
    FWriter.AddCommand(Format('DROP TABLE IF EXISTS %s;', 
                              [FValores.QuoteIdentifier(TableName)]));
  end;
  
  // Obtener estructura
  TableInfo := FLecturas.Esquema.GetTableStructure(TableName);
  Indexes := FLecturas.Esquema.GetTableIndexes(TableName);
  try
    // Crear tabla
    FWriter.AddCommand(FCreacion.GenerateCreateTableSQL(TableInfo, Indexes));
    
    // Crear índices secundarios (los que no son PK)
    for Idx in Indexes do
    begin
      if not Idx.IsPrimary then
        FWriter.AddCommand(FCreacion.GenerateIndexDefinition(TableName, Idx));
    end;
    
    FWriter.AddCommand('');
    
    // Volcar datos si está habilitado
    if FOptions.WithData then
      BackupTableData(TableName);

  finally
    TableInfo.Free;
  end;
end;

procedure TDBBackupEngine.BackupTableData(const TableName: string);
var
  Data: TDataSet;
  Fields, Values: TStringList;
  i: Integer;
  RowCount: Integer;
  TableInfo: TTableInfo;
  HasIdentity: Boolean;
  // Para extended insert
  FieldList: string;       // La parte INSERT INTO `tabla` (`col1`,`col2`)
  ValueRows: TStringList;  // Acumula los VALUE(...) de cada fila
  RowsInBatch: Integer;
  BatchSize: Integer;
  iBytesFila: Integer;
  iBytesLote: Integer;
  iFrecuenciaProgreso: Integer;
  sParteCampos: string;
  sFilter: string;
  sValoresFila: string;
  // Escribe el INSERT acumulado y vacía el buffer
  procedure FlushExtendedInsert;
  var
    j: Integer;
    oSQL: TStringBuilder;
  begin
    if ValueRows.Count > 0 then
    begin
      oSQL := TStringBuilder.Create(
        Length(FieldList) + iBytesLote + (ValueRows.Count * 8));
      try
        oSQL.Append(FieldList);
        oSQL.Append(sLineBreak);
        for j := 0 to ValueRows.Count - 1 do
        begin
          oSQL.Append('  (');
          oSQL.Append(ValueRows[j]);
          if j < ValueRows.Count - 1 then
          begin
            oSQL.Append('),');
            oSQL.Append(sLineBreak);
          end
          else
            oSQL.Append(');');
        end;
        FWriter.AddCommand(oSQL.ToString);
      finally
        FreeAndNil(oSQL);
      end;
      ValueRows.Clear;
      RowsInBatch := 0;
      iBytesLote := 0;
    end;
  end;
begin
  // Verificar si tiene columna de autoincremento
  TableInfo := FLecturas.Esquema.GetTableStructure(TableName);
  try
    HasIdentity := False;
    for i := 0 to TableInfo.Columns.Count - 1 do
    begin
      if ContainsText(TableInfo.Columns[i].Extra, 'auto_increment') then
      begin
        HasIdentity := True;
        Break;
      end;
    end;
  finally
    TableInfo.Free;
  end;
  sFilter := '';
  if Assigned(FDataFilters) then
    sFilter := FDataFilters.Values[TableName];
  Data := FLecturas.Datos.GetData(TableName, sFilter);
  Fields  := TStringList.Create;
  Values  := TStringList.Create;
  ValueRows := TStringList.Create;
  try
    RowCount    := 0;
    // Notificar inicio con total de filas (si el dataset lo soporta)
    DoProgress(TableName + ' (datos)', 0, Data.RecordCount);
    RowsInBatch := 0;
    iBytesLote := 0;
    FieldList   := '';
    BatchSize   := FOptions.ExtendedInsertRows; // 0 = sin límite
    iFrecuenciaProgreso := Data.RecordCount div 100;
    if iFrecuenciaProgreso < 1 then
      iFrecuenciaProgreso := 1;
    if not Data.IsEmpty then
    begin
      FWriter.AddComment(Format('Datos de %s', [TableName]));
      if HasIdentity then
        FWriter.AddCommand(Format('/*!40000 ALTER TABLE %s DISABLE KEYS */;',
                                  [FValores.QuoteIdentifier(TableName)]));
      while not Data.Eof do
      begin
        Inc(RowCount);
        Inc(FFilasProcesadas);
        Fields.Clear;
        Values.Clear;
        for i := 0 to Data.FieldCount - 1 do
        begin
          Fields.Add(FValores.QuoteIdentifier(Data.Fields[i].FieldName));
          Values.Add(FValores.ValueToSQL(Data.Fields[i]));
        end;
        if FOptions.ExtendedInsert then
        begin
          // Construir la cabecera una sola vez
          if FieldList = '' then
          begin
            sParteCampos := '';
            for i := 0 to Fields.Count - 1 do
            begin
              if i > 0 then
                sParteCampos := sParteCampos + ', ';
              sParteCampos := sParteCampos + Fields[i];
            end;
            FieldList := 'INSERT INTO ' + FValores.QuoteIdentifier(TableName) +
                         ' (' + sParteCampos + ') VALUES';
          end;
          sValoresFila := '';
          for i := 0 to Values.Count - 1 do
          begin
            if i > 0 then
              sValoresFila := sValoresFila + ', ';
            sValoresFila := sValoresFila + Values[i];
          end;
          iBytesFila := TEncoding.UTF8.GetByteCount(sValoresFila);
          if (iBytesLote > 0) and
             ((iBytesLote + iBytesFila) > MAX_BYTES_LOTE_EXTENDIDO) then
            FlushExtendedInsert;
          ValueRows.Add(sValoresFila);
          Inc(RowsInBatch);
          Inc(iBytesLote, iBytesFila);
          if (BatchSize > 0) and (RowsInBatch >= BatchSize) then
            FlushExtendedInsert;
        end
        else
        begin
          // ── Modo clásico: un INSERT por fila ───────────────────────────
          FWriter.AddCommand(
            FValores.GenerateInsertSQL(TableName, Fields, Values, HasIdentity));
        end;
        Data.Next;
        if ((RowCount mod iFrecuenciaProgreso) = 0) or Data.Eof then
          DoProgress(TableName + ' (datos)', RowCount, Data.RecordCount);
      end;
      if FOptions.ExtendedInsert then
        FlushExtendedInsert;
      DoProgress(TableName + ' OK', RowCount, RowCount);
      if HasIdentity then
        FWriter.AddCommand(Format('/*!40000 ALTER TABLE %s ENABLE KEYS */;',
                                  [FValores.QuoteIdentifier(TableName)]));
      FWriter.AddComment(Format('%d registros exportados', [RowCount]));
      FWriter.AddCommand('');
    end;
  finally
    Data.Free;
    Fields.Free;
    Values.Free;
    ValueRows.Free;
  end;
end;

procedure TDBBackupEngine.BackupViews;
var
  Views: TStringList;
  i: Integer;
  ViewDef: string;
begin
  Views := FLecturas.Objetos.GetViews;
  try
    if Views.Count > 0 then
    begin
    FWriter.AddComment('');
    FWriter.AddComment('========================================');
    FWriter.AddComment('VISTAS');
    FWriter.AddComment('========================================');
    FWriter.AddCommand('');
    
    FWriter.AddComment('Limpieza de vistas');
    for i := Views.Count - 1 downto 0 do
      FWriter.AddCommand(FEliminacion.GenerateDropView(Views[i]));
    FWriter.AddCommand('');
    for i := 0 to Views.Count - 1 do
    begin
      FWriter.AddComment('Vista: ' + Views[i]);
      // Obtener definición y crear
      ViewDef := FLecturas.Objetos.GetViewDefinition(Views[i]);
      FWriter.AddCommand(FCreacion.GenerateCreateViewSQL(ViewDef));
      FWriter.AddCommand('');
    end;
    end;
  finally
    Views.Free;
  end;
end;

procedure TDBBackupEngine.BackupTriggers;
var
  Triggers: TArray<TTriggerInfo>; // <-- Cambiado a TArray
  i: Integer;
  TriggerDef: string;
begin
  Triggers := FLecturas.Objetos.GetTriggers;

  // Al ser un Array Dinámico, usamos Length() en lugar de .Count
  if Length(Triggers) > 0 then
  begin
  FWriter.AddComment('');
  FWriter.AddComment('========================================');
  FWriter.AddComment('TRIGGERS');
  FWriter.AddComment('========================================');
  FWriter.AddCommand('');

  // Usamos Low() y High() para recorrer arrays
  for i := Low(Triggers) to High(Triggers) do
  begin
    FWriter.AddComment('Trigger: ' + Triggers[i].TriggerName);

    // Drop trigger si existe (accediendo a .TriggerName)
    FWriter.AddCommand(
      FEliminacion.GenerateDropTrigger(Triggers[i].TriggerName));

    // Obtener definición y crear
    TriggerDef := FLecturas.Objetos.GetTriggerDefinition(
      Triggers[i].TriggerName);
    FWriter.AddCommand(FCreacion.GenerateCreateTriggerSQL(TriggerDef));
    FWriter.AddCommand('');
  end;
  end;
end;

procedure TDBBackupEngine.BackupProcedures;
var
  Procedures: TStringList;
  i: Integer;
  ProcDef: string;
begin
  Procedures := FLecturas.Objetos.GetProcedures;
  try
    if Procedures.Count > 0 then
    begin
    FWriter.AddComment('');
    FWriter.AddComment('========================================');
    FWriter.AddComment('PROCEDIMIENTOS ALMACENADOS');
    FWriter.AddComment('========================================');
    FWriter.AddCommand('');
    
    for i := 0 to Procedures.Count - 1 do
    begin
      FWriter.AddComment('Procedimiento: ' + Procedures[i]);
      
      // Drop procedure si existe
      FWriter.AddCommand(FEliminacion.GenerateDropProcedure(Procedures[i]));
      
      // Obtener definición y crear
      ProcDef := FLecturas.Objetos.GetProcedureDefinition(Procedures[i]);
      FWriter.AddCommand(FCreacion.GenerateCreateProcedureSQL(ProcDef));
      FWriter.AddCommand('');
    end;
    end;
  finally
    Procedures.Free;
  end;
end;

procedure TDBBackupEngine.BackupFunctions;
var
  Functions: TStringList;
  i: Integer;
  FuncDef: string;
begin
  Functions := FLecturas.Objetos.GetFunctions;
  try
    if Functions.Count > 0 then
    begin
    FWriter.AddComment('');
    FWriter.AddComment('========================================');
    FWriter.AddComment('FUNCIONES');
    FWriter.AddComment('========================================');
    FWriter.AddCommand('');
    
    for i := 0 to Functions.Count - 1 do
    begin
      FWriter.AddComment('Función: ' + Functions[i]);
      
      // Drop function si existe
      FWriter.AddCommand(FEliminacion.GenerateDropFunction(Functions[i]));
      
      // Obtener definición y crear
      FuncDef := FLecturas.Objetos.GetFunctionDefinition(Functions[i]);
      FWriter.AddCommand(FCreacion.GenerateCreateFunctionSQL(FuncDef));
      FWriter.AddCommand('');
    end;
    end;
  finally
    Functions.Free;
  end;
end;

end.
