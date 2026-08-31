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
  System.SysUtils, System.StrUtils, System.Diagnostics,
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
    FIndicesDiferidos: TStringList;
    FEsCopiaFactuzam: Boolean;
    FCopiaFactuzamConMarcadores: Boolean;
    FFinCopiaFactuzamDetectado: Boolean;
    FCabeceraLegacyDetectada: Boolean;
    FBaseDatosLegacyDetectada: Boolean;
    FHayDatosParaIndicesDiferidos: Boolean;
    FDatosDesdeDefinicionTabla: Boolean;
    FSavepointsActivos: TStringList;
    FTransaccionConSavepoints: Boolean;
    FBytesDatosSinConfirmar: Int64;
    FBytesEntreConfirmaciones: Int64;
    FLineasLeidas: Integer;
    procedure ComprobarCancelacion;
    procedure Inicializar(AFlujo: TStream);
    procedure DetectarCabeceraCopiaFactuzam(const ALinea: string);
    procedure DetectarFinCopiaFactuzam(const ALinea: string);
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
    procedure EjecutarEnPersistencia(
      const ASentencia: string;
      AContabilizar: Boolean = True);
    procedure ConfirmarDatosPendientes(AForzar: Boolean);
    procedure EjecutarIndicesDiferidos;
    procedure NormalizarColaciones;
    function EsLineaIgnorable(const ALinea: string): Boolean;
    function EsDirectivaDelimitador(
      const ALinea: string; out ADelimitador: string): Boolean;
    function EsComentarioLinea(
      const ALinea: string; AIndice: Integer): Boolean;
    function CoincideDelimitador(
      const ALinea: string; AIndice: Integer): Boolean;
    function EsCreacionVista(const ASentencia: string): Boolean;
    function EsInsercionDatos(const ASentencia: string): Boolean;
    function EsCreacionIndiceSecundario(
      const ASentencia: string): Boolean;
    function EsActivacionIndices(const ASentencia: string): Boolean;
    function EsControlIndicesVersionado(
      const ASentencia: string): Boolean;
    function EsInicioDefinicionTabla(
      const ASentencia: string): Boolean;
    function EsConfirmacionTransaccion(
      const ASentencia: string): Boolean;
    function EsReversionTransaccion(
      const ASentencia: string): Boolean;
    function EsReversionParcial(
      const ASentencia: string): Boolean;
    function EsCreacionSavepoint(
      const ASentencia: string): Boolean;
    function EsLiberacionSavepoint(
      const ASentencia: string): Boolean;
    function ExtraerNombreSavepoint(
      const ASentencia, APrefijo: string): string;
    function ExtraerNombreReversionParcial(
      const ASentencia: string): string;
  public
    constructor Create(
      const APersistencia: IPersistenciaRestauracionBackup;
      AComprobarCancelacion: TComprobarCancelacionBackupEvent;
      AOnProgreso: TProgresoRestauracionBackupEvent;
      ALog: TStrings;
      ABytesEntreConfirmaciones: Int64 = 64 * 1024 * 1024);
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
    procedure RegistrarFilaDatos;
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
  UniDataBackupRepositorio,
  Backup.LecturaDatos;

const
  BYTES_ENTRE_PROGRESO_RESTAURACION = 4 * 1024 * 1024;
  CABECERA_COPIA_FACTUZAM = '-- Backup generado:';
  CABECERA_BASE_DATOS_FACTUZAM = '-- Base de datos:';
  IDENTIFICADOR_COPIA_FACTUZAM = '-- FZAM_COPIA_SEGURIDAD_SQL';
  IDENTIFICADOR_FIN_COPIA_FACTUZAM = '-- FZAM_FIN_COPIA_SEGURIDAD';
  LINEAS_MAXIMAS_CABECERA_COPIA = 16;
  CONFIRMACION_TRANSACCION_SEGURA =
    'COMMIT AND NO CHAIN NO RELEASE';
  REVERSION_TRANSACCION_SEGURA =
    'ROLLBACK AND NO CHAIN NO RELEASE';

function AgruparCreacionesIndices(
  const AIndices: TStrings;
  out ASentencia: string): Boolean;
var
  iIndice: Integer;
  iPosicion: Integer;
  iPosicionUnico: Integer;
  sActual: string;
  sClausulas: string;
  sPrefijo: string;
  sPrefijoActual: string;
begin
  ASentencia := '';
  Result := Assigned(AIndices) and (AIndices.Count > 0);
  iIndice := 0;
  sClausulas := '';
  sPrefijo := '';
  while Result and (iIndice < AIndices.Count) do
  begin
    sActual := Trim(AIndices[iIndice]);
    if EndsText(';', sActual) then
      Delete(sActual, Length(sActual), 1);
    iPosicion := Pos(' ADD INDEX ', sActual);
    iPosicionUnico := Pos(' ADD UNIQUE INDEX ', sActual);
    if (iPosicion = 0) or
       ((iPosicionUnico > 0) and
        (iPosicionUnico < iPosicion)) then
    begin
      iPosicion := iPosicionUnico;
    end;
    Result := (iPosicion > 0) and
      StartsText('ALTER TABLE ', sActual);
    if Result then
    begin
      sPrefijoActual := Trim(Copy(sActual, 1, iPosicion - 1));
      if sPrefijo = '' then
        sPrefijo := sPrefijoActual
      else
        Result := SameText(sPrefijo, sPrefijoActual);
    end;
    if Result then
    begin
      if sClausulas <> '' then
        sClausulas := sClausulas + ',' + sLineBreak + '  ';
      sClausulas := sClausulas +
        Trim(Copy(sActual, iPosicion + 1, MaxInt));
    end;
    Inc(iIndice);
  end;
  if Result then
    ASentencia := sPrefijo + ' ' + sClausulas;
end;

function QuitarComentariosInicialesNoEjecutables(
  const ASentencia: string): string;
var
  bHayComentario: Boolean;
  iFinComentario: Integer;
begin
  Result := TrimLeft(ASentencia);
  bHayComentario :=
    StartsText('/*', Result) and
    not StartsText('/*!', Result) and
    not StartsText('/*M!', Result);
  while bHayComentario do
  begin
    iFinComentario := Pos('*/', Result);
    if iFinComentario > 0 then
    begin
      Result := TrimLeft(
        Copy(Result, iFinComentario + 2, MaxInt));
      bHayComentario :=
        StartsText('/*', Result) and
        not StartsText('/*!', Result) and
        not StartsText('/*M!', Result);
    end
    else
    begin
      bHayComentario := False;
    end;
  end;
end;

function EsComentarioEjecutableInicial(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := TrimLeft(ASentencia);
  Result := StartsText('/*!', sInicio) or
    StartsText('/*M!', sInicio);
end;

function TotalProgresoRestauracion(ATotalBytes: Int64): Integer;
var
  iTotalKb: Int64;
begin
  if ATotalBytes <= 0 then
    Result := 1
  else
  begin
    iTotalKb := 1 + ((ATotalBytes - 1) div 1024);
    if iTotalKb > MaxInt then
      Result := MaxInt
    else
      Result := Integer(iTotalKb);
  end;
end;

function PosicionProgresoRestauracion(
  APosicionBytes, ATotalBytes: Int64;
  ATotalProgreso: Integer): Integer;
var
  iTotalKb: Int64;
begin
  if (APosicionBytes <= 0) or (ATotalBytes <= 0) then
    Result := 0
  else if APosicionBytes >= ATotalBytes then
    Result := ATotalProgreso
  else
  begin
    iTotalKb := 1 + ((ATotalBytes - 1) div 1024);
    if iTotalKb <= MaxInt then
      Result := Integer(APosicionBytes div 1024)
    else
      Result := Trunc(
        (APosicionBytes / ATotalBytes) * ATotalProgreso);
  end;
end;

constructor TEjecutorRestauracionSQL.Create(
  const APersistencia: IPersistenciaRestauracionBackup;
  AComprobarCancelacion: TComprobarCancelacionBackupEvent;
  AOnProgreso: TProgresoRestauracionBackupEvent;
  ALog: TStrings;
  ABytesEntreConfirmaciones: Int64);
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
  if ABytesEntreConfirmaciones <= 0 then
  begin
    raise EArgumentOutOfRangeException.Create(
      'ABytesEntreConfirmaciones');
  end;
  FBytesEntreConfirmaciones := ABytesEntreConfirmaciones;
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
  FEsCopiaFactuzam := False;
  FCopiaFactuzamConMarcadores := False;
  FFinCopiaFactuzamDetectado := False;
  FCabeceraLegacyDetectada := False;
  FBaseDatosLegacyDetectada := False;
  FHayDatosParaIndicesDiferidos := False;
  FDatosDesdeDefinicionTabla := False;
  FTransaccionConSavepoints := False;
  FBytesDatosSinConfirmar := 0;
  FLineasLeidas := 0;
  FTotal := TotalProgresoRestauracion(FFlujo.Size);
  FPosicion := 0;
  if Assigned(FLog) then
  begin
    FLog.Add(
      ' -- El DDL de MariaDB puede confirmar cambios de forma implícita;');
    FLog.Add(' -- la restauración no promete rollback transaccional.');
  end;
end;

procedure TEjecutorRestauracionSQL.DetectarCabeceraCopiaFactuzam(
  const ALinea: string);
var
  sLinea: string;
begin
  if not FEsCopiaFactuzam and
     (FLineasLeidas <= LINEAS_MAXIMAS_CABECERA_COPIA) and
     (FSentenciasEjecutadas = 0) and
     Assigned(FSentencia) and
     (FSentencia.Length = 0) and
     not FEnCadena and
     not FEnComentarioBloque and
     not FTieneContenidoEjecutable then
  begin
    sLinea := Trim(ALinea);
    if SameText(IDENTIFICADOR_COPIA_FACTUZAM, sLinea) then
    begin
      FEsCopiaFactuzam := True;
      FCopiaFactuzamConMarcadores := True;
    end
    else
    begin
      if StartsText(CABECERA_COPIA_FACTUZAM, sLinea) then
        FCabeceraLegacyDetectada := True;
      if StartsText(CABECERA_BASE_DATOS_FACTUZAM, sLinea) then
        FBaseDatosLegacyDetectada := True;
      FEsCopiaFactuzam :=
        FCabeceraLegacyDetectada and
        FBaseDatosLegacyDetectada;
    end;
  end;
end;

procedure TEjecutorRestauracionSQL.NotificarProgreso(AForzar: Boolean);
begin
  if Assigned(FFlujo) then
  begin
    FPosicion := PosicionProgresoRestauracion(
      FFlujo.Position,
      FFlujo.Size,
      FTotal);
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

function TEjecutorRestauracionSQL.EsInsercionDatos(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := Trim(Copy(ASentencia, 1, 32));
  Result := StartsText('INSERT INTO ', sInicio);
end;

function TEjecutorRestauracionSQL.EsCreacionIndiceSecundario(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 512)));
  sInicio := StringReplace(sInicio, #13, ' ', [rfReplaceAll]);
  sInicio := StringReplace(sInicio, #10, ' ', [rfReplaceAll]);
  Result := StartsText('ALTER TABLE ', sInicio) and
    ((Pos(' ADD INDEX ', sInicio) > 0) or
     (Pos(' ADD UNIQUE INDEX ', sInicio) > 0));
end;

function TEjecutorRestauracionSQL.EsActivacionIndices(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 512)));
  Result := StartsText('/*!40000 ALTER TABLE ', sInicio) and
    (Pos(' ENABLE KEYS */', sInicio) > 0);
end;

function TEjecutorRestauracionSQL.EsInicioDefinicionTabla(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := Trim(Copy(ASentencia, 1, 64));
  Result := StartsText('DROP TABLE ', sInicio) or
    StartsText('CREATE TABLE ', sInicio);
end;

function TEjecutorRestauracionSQL.EsConfirmacionTransaccion(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 64)));
  Result := SameText('COMMIT', sInicio) or
    StartsText('COMMIT ', sInicio);
end;

function TEjecutorRestauracionSQL.EsReversionTransaccion(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 64)));
  sInicio := StringReplace(sInicio, #13, ' ', [rfReplaceAll]);
  sInicio := StringReplace(sInicio, #10, ' ', [rfReplaceAll]);
  sInicio := StringReplace(sInicio, #9, ' ', [rfReplaceAll]);
  Result :=
    (SameText('ROLLBACK', sInicio) or
     StartsText('ROLLBACK ', sInicio)) and
    not EsReversionParcial(ASentencia);
end;

function TEjecutorRestauracionSQL.EsReversionParcial(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 128)));
  sInicio := StringReplace(sInicio, #13, ' ', [rfReplaceAll]);
  sInicio := StringReplace(sInicio, #10, ' ', [rfReplaceAll]);
  sInicio := StringReplace(sInicio, #9, ' ', [rfReplaceAll]);
  Result := StartsText('ROLLBACK ', sInicio) and
    (Pos(' TO ', ' ' + sInicio + ' ') > 0);
end;

function TEjecutorRestauracionSQL.EsControlIndicesVersionado(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 512)));
  Result := StartsText('/*!40000 ALTER TABLE ', sInicio) and
    ((Pos(' ENABLE KEYS */', sInicio) > 0) or
     (Pos(' DISABLE KEYS */', sInicio) > 0));
end;

function TEjecutorRestauracionSQL.EsCreacionSavepoint(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 64)));
  Result := StartsText('SAVEPOINT ', sInicio);
end;

function TEjecutorRestauracionSQL.EsLiberacionSavepoint(
  const ASentencia: string): Boolean;
var
  sInicio: string;
begin
  sInicio := UpperCase(Trim(Copy(ASentencia, 1, 64)));
  Result := StartsText('RELEASE SAVEPOINT ', sInicio);
end;

function TEjecutorRestauracionSQL.ExtraerNombreSavepoint(
  const ASentencia, APrefijo: string): string;
begin
  Result := Trim(Copy(ASentencia, Length(APrefijo) + 1, MaxInt));
end;

function TEjecutorRestauracionSQL.ExtraerNombreReversionParcial(
  const ASentencia: string): string;
var
  iPosicion: Integer;
  sNormalizada: string;
begin
  Result := '';
  sNormalizada := UpperCase(ASentencia);
  sNormalizada := StringReplace(
    sNormalizada, #13, ' ', [rfReplaceAll]);
  sNormalizada := StringReplace(
    sNormalizada, #10, ' ', [rfReplaceAll]);
  sNormalizada := StringReplace(
    sNormalizada, #9, ' ', [rfReplaceAll]);
  iPosicion := Pos(' TO ', sNormalizada);
  if iPosicion > 0 then
  begin
    Result := Trim(Copy(ASentencia, iPosicion + 4, MaxInt));
    if StartsText('SAVEPOINT ', Result) then
    begin
      Result := Trim(Copy(Result, Length('SAVEPOINT') + 1, MaxInt));
    end;
  end;
end;

procedure TEjecutorRestauracionSQL.DetectarFinCopiaFactuzam(
  const ALinea: string);
begin
  if FCopiaFactuzamConMarcadores and
     Assigned(FSentencia) and
     (FSentencia.Length = 0) and
     not FEnCadena and
     not FEnComentarioBloque and
     not FTieneContenidoEjecutable and
     SameText(IDENTIFICADOR_FIN_COPIA_FACTUZAM, Trim(ALinea)) then
  begin
    FFinCopiaFactuzamDetectado := True;
  end;
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

procedure TEjecutorRestauracionSQL.EjecutarEnPersistencia(
  const ASentencia: string;
  AContabilizar: Boolean);
var
  oReloj: TStopwatch;
  sResumen: string;
begin
  ComprobarCancelacion;
  if AContabilizar then
    Inc(FSentenciasEjecutadas);
  oReloj := TStopwatch.StartNew;
  try
    if EsCreacionVista(ASentencia) then
      NormalizarColaciones;
    FPersistencia.EjecutarSentencia(ASentencia);
    if AContabilizar and Assigned(FLog) and
       ((FSentenciasEjecutadas mod 250) = 0) then
    begin
      FLog.Add(Format(
        ' -- [OK] Sentencias ejecutadas: %d | progreso %d / %d',
        [FSentenciasEjecutadas, FPosicion, FTotal]));
    end;
  except
    on E: Exception do
    begin
      Inc(FErrores);
      if FPrimerError = '' then
        FPrimerError := E.Message;
      sResumen := ASentencia;
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

procedure TEjecutorRestauracionSQL.ConfirmarDatosPendientes(
  AForzar: Boolean);
begin
  if FEsCopiaFactuzam and
     not FTransaccionConSavepoints and
     (not Assigned(FSavepointsActivos) or
      (FSavepointsActivos.Count = 0)) and
     (FBytesDatosSinConfirmar > 0) and
     (AForzar or
      (FBytesDatosSinConfirmar >= FBytesEntreConfirmaciones)) then
  begin
    EjecutarEnPersistencia(CONFIRMACION_TRANSACCION_SEGURA, False);
    FBytesDatosSinConfirmar := 0;
  end;
end;

procedure TEjecutorRestauracionSQL.EjecutarIndicesDiferidos;
var
  iIndice: Integer;
  sIndicesAgrupados: string;
begin
  if Assigned(FIndicesDiferidos) and
     (FIndicesDiferidos.Count > 0) and
     not FTransaccionConSavepoints and
     (not Assigned(FSavepointsActivos) or
      (FSavepointsActivos.Count = 0)) then
  begin
    ConfirmarDatosPendientes(True);
    if AgruparCreacionesIndices(
         FIndicesDiferidos,
         sIndicesAgrupados) then
    begin
      EjecutarEnPersistencia(sIndicesAgrupados);
    end
    else
    begin
      for iIndice := 0 to FIndicesDiferidos.Count - 1 do
      begin
        EjecutarEnPersistencia(FIndicesDiferidos[iIndice]);
      end;
    end;
    if Assigned(FLog) then
    begin
      FLog.Add(Format(
        ' -- Índices secundarios creados tras cargar datos: %d',
        [FIndicesDiferidos.Count]));
    end;
    FIndicesDiferidos.Clear;
    FHayDatosParaIndicesDiferidos := False;
  end;
end;

procedure TEjecutorRestauracionSQL.EjecutarSentenciaActual;
var
  bActivacionIndices: Boolean;
  bConfirmacion: Boolean;
  bControlIndicesVersionado: Boolean;
  bCreacionSavepoint: Boolean;
  bCreacionIndice: Boolean;
  bInicioTabla: Boolean;
  bInsercionDatos: Boolean;
  bReversion: Boolean;
  bReversionParcial: Boolean;
  bLiberacionSavepoint: Boolean;
  iSavepoint: Integer;
  sNombreSavepoint: string;
  sSentencia: string;
  sSentenciaClasificada: string;
begin
  sSentencia := Trim(FSentencia.ToString);
  FSentencia.Clear;
  if FFinCopiaFactuzamDetectado and
     FTieneContenidoEjecutable then
  begin
    raise EInvalidOperation.Create(
      'La copia SQL contiene datos después de su marcador final');
  end;
  if FTieneContenidoEjecutable and (sSentencia <> '') then
  begin
    sSentenciaClasificada :=
      QuitarComentariosInicialesNoEjecutables(sSentencia);
    bInsercionDatos := EsInsercionDatos(sSentenciaClasificada);
    bCreacionIndice :=
      EsCreacionIndiceSecundario(sSentenciaClasificada);
    bActivacionIndices :=
      EsActivacionIndices(sSentenciaClasificada);
    bControlIndicesVersionado :=
      EsControlIndicesVersionado(sSentenciaClasificada);
    bInicioTabla := EsInicioDefinicionTabla(sSentenciaClasificada);
    bConfirmacion :=
      EsConfirmacionTransaccion(sSentenciaClasificada);
    bReversion := EsReversionTransaccion(sSentenciaClasificada);
    bReversionParcial := EsReversionParcial(sSentenciaClasificada);
    bCreacionSavepoint := EsCreacionSavepoint(sSentenciaClasificada);
    bLiberacionSavepoint :=
      EsLiberacionSavepoint(sSentenciaClasificada);
    if FEsCopiaFactuzam and
       EsComentarioEjecutableInicial(sSentenciaClasificada) and
       not bControlIndicesVersionado then
    begin
      raise EInvalidOperation.Create(
        'La copia SQL contiene un comentario ejecutable no admitido');
    end;
    if FEsCopiaFactuzam and bCreacionIndice and
       not FDatosDesdeDefinicionTabla then
    begin
      FIndicesDiferidos.Add(sSentencia);
    end
    else
    begin
      if FEsCopiaFactuzam and not bInsercionDatos then
      begin
        if not bConfirmacion and
           not bReversion and
           not bReversionParcial and
           not bCreacionSavepoint and
           not bLiberacionSavepoint then
          ConfirmarDatosPendientes(True);
        if Assigned(FIndicesDiferidos) and
           (FIndicesDiferidos.Count > 0) and
           (bInicioTabla or
             (FHayDatosParaIndicesDiferidos and
              not bActivacionIndices and
              not bConfirmacion and
              not bReversion and
              not bReversionParcial and
              not bCreacionSavepoint and
              not bLiberacionSavepoint and
              (not Assigned(FSavepointsActivos) or
               (FSavepointsActivos.Count = 0)))) then
        begin
          EjecutarIndicesDiferidos;
        end;
      end;
      if FEsCopiaFactuzam and bConfirmacion and
         (SameText('COMMIT', Trim(sSentenciaClasificada)) or
          SameText('COMMIT WORK', Trim(sSentenciaClasificada))) then
      begin
        sSentencia := CONFIRMACION_TRANSACCION_SEGURA;
      end;
      if FEsCopiaFactuzam and bReversion and
         (SameText('ROLLBACK', Trim(sSentenciaClasificada)) or
          SameText('ROLLBACK WORK', Trim(sSentenciaClasificada))) then
      begin
        sSentencia := REVERSION_TRANSACCION_SEGURA;
      end;
      EjecutarEnPersistencia(sSentencia);
      if bConfirmacion or bReversion then
      begin
        FBytesDatosSinConfirmar := 0;
        FTransaccionConSavepoints := False;
        if Assigned(FSavepointsActivos) then
          FSavepointsActivos.Clear;
      end;
      if bCreacionSavepoint and Assigned(FSavepointsActivos) then
      begin
        sNombreSavepoint := ExtraerNombreSavepoint(
          sSentenciaClasificada,
          'SAVEPOINT');
        iSavepoint := FSavepointsActivos.IndexOf(sNombreSavepoint);
        if iSavepoint >= 0 then
          FSavepointsActivos.Delete(iSavepoint);
        FSavepointsActivos.Add(sNombreSavepoint);
        FTransaccionConSavepoints := True;
      end;
      if bLiberacionSavepoint and Assigned(FSavepointsActivos) then
      begin
        sNombreSavepoint := ExtraerNombreSavepoint(
          sSentenciaClasificada,
          'RELEASE SAVEPOINT');
        iSavepoint := FSavepointsActivos.IndexOf(sNombreSavepoint);
        if iSavepoint >= 0 then
          FSavepointsActivos.Delete(iSavepoint);
      end;
      if bReversionParcial and Assigned(FSavepointsActivos) then
      begin
        sNombreSavepoint :=
          ExtraerNombreReversionParcial(sSentenciaClasificada);
        iSavepoint := FSavepointsActivos.IndexOf(sNombreSavepoint);
        if iSavepoint >= 0 then
        begin
          while FSavepointsActivos.Count > iSavepoint + 1 do
            FSavepointsActivos.Delete(FSavepointsActivos.Count - 1);
        end;
      end;
      if bInicioTabla then
        FDatosDesdeDefinicionTabla := False;
      if FEsCopiaFactuzam and bInsercionDatos then
      begin
        FDatosDesdeDefinicionTabla := True;
        if Assigned(FIndicesDiferidos) and
           (FIndicesDiferidos.Count > 0) then
        begin
          FHayDatosParaIndicesDiferidos := True;
        end;
        Inc(
          FBytesDatosSinConfirmar,
          TEncoding.UTF8.GetByteCount(sSentencia));
        ConfirmarDatosPendientes(False);
      end;
      if FEsCopiaFactuzam and
         (bActivacionIndices or bConfirmacion or bReversion) and
         Assigned(FIndicesDiferidos) and
         (FIndicesDiferidos.Count > 0) then
      begin
        EjecutarIndicesDiferidos;
      end;
    end;
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
    Inc(FLineasLeidas);
    DetectarCabeceraCopiaFactuzam(sLinea);
    DetectarFinCopiaFactuzam(sLinea);
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
  FIndicesDiferidos := nil;
  FSavepointsActivos := nil;
  FSentencia := nil;
  try
    FIndicesDiferidos := TStringList.Create;
    FSavepointsActivos := TStringList.Create;
    FSentencia := TStringBuilder.Create;
    oLector := TStreamReader.Create(AFlujo, TEncoding.UTF8, True);
    try
      NotificarProgreso(True);
      ProcesarLectura(oLector);
      ComprobarCancelacion;
      EjecutarSentenciaActual;
      if FCopiaFactuzamConMarcadores and
         not FFinCopiaFactuzamDetectado then
      begin
        raise EInvalidOperation.Create(
          'La copia SQL está incompleta: falta el marcador final');
      end;
      if FEsCopiaFactuzam and
         (FSavepointsActivos.Count > 0) then
      begin
        raise EInvalidOperation.Create(
          'La copia SQL termina con savepoints activos');
      end;
      if FEsCopiaFactuzam and
         FTransaccionConSavepoints then
      begin
        raise EInvalidOperation.Create(
          'La copia SQL no cierra la transacción con savepoints');
      end;
      EjecutarIndicesDiferidos;
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
    FreeAndNil(FSavepointsActivos);
    FreeAndNil(FIndicesDiferidos);
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

procedure TDBBackupEngine.RegistrarFilaDatos;
begin
  Inc(FFilasProcesadas);
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
  FWriter.AddComment('FZAM_COPIA_SEGURIDAD_SQL');
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
  if FOptions.UseTransactions then
    FWriter.AddCommand('SET AUTOCOMMIT=0;')
  else
    FWriter.AddCommand('SET AUTOCOMMIT=1;');
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
    FWriter.AddCommand(CONFIRMACION_TRANSACCION_SEGURA + ';');
  end;
  
  FWriter.AddCommand('');
  FWriter.AddComment('Backup completado: ' + DateTimeToStr(Now));
  FWriter.AddComment(IDENTIFICADOR_FIN_COPIA_FACTUZAM);
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
  sIndicesSecundarios: string;
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
  try
    Indexes := FLecturas.Esquema.GetTableIndexes(TableName);
    // Crear tabla
    FWriter.AddCommand(FCreacion.GenerateCreateTableSQL(TableInfo, Indexes));
    
    // Volcar datos si está habilitado
    if FOptions.WithData then
    begin
      BackupTableData(TableName);
      if FOptions.UseTransactions then
        FWriter.AddCommand(CONFIRMACION_TRANSACCION_SEGURA + ';');
    end;

    // En InnoDB, cargar primero evita mantener cada árbol secundario fila
    // a fila cuando la tabla deja de caber en el buffer pool.
    sIndicesSecundarios := FCreacion.GenerarIndicesSecundarios(
      TableName,
      Indexes);
    if sIndicesSecundarios <> '' then
      FWriter.AddCommand(sIndicesSecundarios);

    FWriter.AddCommand('');

  finally
    TableInfo.Free;
  end;
end;

procedure TDBBackupEngine.BackupTableData(const TableName: string);
var
  sFilter: string;
  oLector: TLecturaDatosTablaBackup;
begin
  sFilter := '';
  if Assigned(FDataFilters) then
  begin
    sFilter := FDataFilters.Values[TableName];
  end;
  oLector := TLecturaDatosTablaBackup.Create(
    TDependenciasLecturaDatosBackup.Crear(
      FLecturas.Esquema,
      FLecturas.Datos,
      FWriter,
      FValores),
    TConfiguracionLecturaDatosBackup.Crear(
      FOptions.ExtendedInsert,
      FOptions.ExtendedInsertRows),
    DoProgress,
    RegistrarFilaDatos);
  try
    oLector.Ejecutar(TableName, sFilter);
  finally
    FreeAndNil(oLector);
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
