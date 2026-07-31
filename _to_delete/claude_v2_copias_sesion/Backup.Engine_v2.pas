unit Backup.Engine;

interface

uses
  Core_Interfaces, Backup.Types, System.Classes, Core_Helpers,
  Data.DB, System.SysUtils, Core_Engine, system.StrUtils;

type
  // AEtapa: nombre de tabla o etapa actual
  // APaso, ATotal: progreso dentro de la etapa (tabla)
  // AFilaGlobal: filas procesadas acumuladas en todo el backup
  // AFilasGlobalTotal: total estimado de filas en todas las tablas
  TBackupProgressEvent = procedure(const AEtapa: string;
                                    APaso, ATotal: Integer;
                                    AFilaGlobal,
                                    AFilasGlobalTotal: Integer) of object;

  TDBBackupEngine = class
  private
    FProvider: IDBMetadataProvider;
    FWriter: IScriptWriter;
    FHelpers: IDBHelpers;
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
    constructor Create(Provider: IDBMetadataProvider;
                       Writer: IScriptWriter;
                       Helpers: IDBHelpers;
                       Options: TBackupOptions;
                       IncludeTables, ExcludeTables: TStringList;
                       DataFilters: TStringList = nil);
    procedure GenerateBackup;
    property OnProgress: TBackupProgressEvent
      read FOnProgress write FOnProgress;
  end;

implementation

const
  MAX_BYTES_LOTE_EXTENDIDO = 1024 * 1024;

constructor TDBBackupEngine.Create(Provider: IDBMetadataProvider;
                                   Writer: IScriptWriter;
                                   Helpers: IDBHelpers;
                                   Options: TBackupOptions;
                                   IncludeTables, ExcludeTables: TStringList;
                                   DataFilters: TStringList = nil);
begin
  FProvider := Provider;
  FWriter := Writer;
  FHelpers := Helpers;
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
  Tables := FProvider.GetTables;
  try
    for i := 0 to Tables.Count - 1 do
    begin
      if ShouldProcessTable(Tables[i]) then
      begin
        sFilter := '';
        if Assigned(FDataFilters) then
          sFilter := FDataFilters.Values[Tables[i]];
        FFilasGlobalTotal := FFilasGlobalTotal +
          FProvider.GetRowCount(Tables[i], sFilter);
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
  FWriter.AddComment('Base de datos: ' + FProvider.GetDatabaseName);
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
  
  Tables := FProvider.GetTables;
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
                              [FHelpers.QuoteIdentifier(TableName)]));
  end;
  
  // Obtener estructura
  TableInfo := FProvider.GetTableStructure(TableName);
  Indexes := FProvider.GetTableIndexes(TableName);
  try
    // Crear tabla
    FWriter.AddCommand(FHelpers.GenerateCreateTableSQL(TableInfo, Indexes));
    
    // Crear índices secundarios (los que no son PK)
    for Idx in Indexes do
    begin
      if not Idx.IsPrimary then
        FWriter.AddCommand(FHelpers.GenerateIndexDefinition(TableName, Idx));
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
  TableInfo := FProvider.GetTableStructure(TableName);
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
  Data := FProvider.GetData(TableName, sFilter);
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
                                  [FHelpers.QuoteIdentifier(TableName)]));
      while not Data.Eof do
      begin
        Inc(RowCount);
        Inc(FFilasProcesadas);
        Fields.Clear;
        Values.Clear;
        for i := 0 to Data.FieldCount - 1 do
        begin
          Fields.Add(FHelpers.QuoteIdentifier(Data.Fields[i].FieldName));
          Values.Add(FHelpers.ValueToSQL(Data.Fields[i]));
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
            FieldList := 'INSERT INTO ' + FHelpers.QuoteIdentifier(TableName) +
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
            FHelpers.GenerateInsertSQL(TableName, Fields, Values, HasIdentity));
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
                                  [FHelpers.QuoteIdentifier(TableName)]));
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
  Views := FProvider.GetViews;
  try
    if Views.Count = 0 then
      Exit;
      
    FWriter.AddComment('');
    FWriter.AddComment('========================================');
    FWriter.AddComment('VISTAS');
    FWriter.AddComment('========================================');
    FWriter.AddCommand('');
    
    FWriter.AddComment('Limpieza de vistas');
    for i := Views.Count - 1 downto 0 do
      FWriter.AddCommand(FHelpers.GenerateDropView(Views[i]));
    FWriter.AddCommand('');
    for i := 0 to Views.Count - 1 do
    begin
      FWriter.AddComment('Vista: ' + Views[i]);
      // Obtener definición y crear
      ViewDef := FProvider.GetViewDefinition(Views[i]);
      FWriter.AddCommand(FHelpers.GenerateCreateViewSQL(ViewDef));
      FWriter.AddCommand('');
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
  Triggers := FProvider.GetTriggers;

  // Al ser un Array Dinámico, usamos Length() en lugar de .Count
  if Length(Triggers) = 0 then
    Exit;

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
    FWriter.AddCommand(FHelpers.GenerateDropTrigger(Triggers[i].TriggerName));

    // Obtener definición y crear
    TriggerDef := FProvider.GetTriggerDefinition(Triggers[i].TriggerName);
    FWriter.AddCommand(FHelpers.GenerateCreateTriggerSQL(TriggerDef));
    FWriter.AddCommand('');
  end;
end;

procedure TDBBackupEngine.BackupProcedures;
var
  Procedures: TStringList;
  i: Integer;
  ProcDef: string;
begin
  Procedures := FProvider.GetProcedures;
  try
    if Procedures.Count = 0 then
      Exit;
      
    FWriter.AddComment('');
    FWriter.AddComment('========================================');
    FWriter.AddComment('PROCEDIMIENTOS ALMACENADOS');
    FWriter.AddComment('========================================');
    FWriter.AddCommand('');
    
    for i := 0 to Procedures.Count - 1 do
    begin
      FWriter.AddComment('Procedimiento: ' + Procedures[i]);
      
      // Drop procedure si existe
      FWriter.AddCommand(FHelpers.GenerateDropProcedure(Procedures[i]));
      
      // Obtener definición y crear
      ProcDef := FProvider.GetProcedureDefinition(Procedures[i]);
      FWriter.AddCommand(FHelpers.GenerateCreateProcedureSQL(ProcDef));
      FWriter.AddCommand('');
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
  Functions := FProvider.GetFunctions;
  try
    if Functions.Count = 0 then
      Exit;
      
    FWriter.AddComment('');
    FWriter.AddComment('========================================');
    FWriter.AddComment('FUNCIONES');
    FWriter.AddComment('========================================');
    FWriter.AddCommand('');
    
    for i := 0 to Functions.Count - 1 do
    begin
      FWriter.AddComment('Función: ' + Functions[i]);
      
      // Drop function si existe
      FWriter.AddCommand(FHelpers.GenerateDropFunction(Functions[i]));
      
      // Obtener definición y crear
      FuncDef := FProvider.GetFunctionDefinition(Functions[i]);
      FWriter.AddCommand(FHelpers.GenerateCreateFunctionSQL(FuncDef));
      FWriter.AddCommand('');
    end;
  finally
    Functions.Free;
  end;
end;

end.
