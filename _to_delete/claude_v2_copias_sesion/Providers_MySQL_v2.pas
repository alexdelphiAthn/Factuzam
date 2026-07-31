unit Providers_MySQL;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Core_Interfaces, Backup.Types, Uni,
  MySQLUniProvider, system.StrUtils, System.Generics.Collections,
  Providers_MySQL_Helpers, Core_Helpers;

const
    SCHEMADB = 'information_schema';
type
  TMySQLMetadataProvider = class(TInterfacedObject, IDBMetadataProvider)
  private
    FConn: TUniConnection;
    FDBName: string;
    FHost: string;
    FPort: Integer;
    FUser: string;
    FPassword: string;
    FOwnsConnection: Boolean;
    procedure OrdenarVistasPorDependencias(Vistas: TStringList);
    function DDLReferenciaVista(const DDL, Vista: string): Boolean;
    function ContieneIdentificadorSQL(const Texto,
                                      Identificador: string): Boolean;
    function EsCaracterIdentificadorSQL(Caracter: Char): Boolean;
  public
    constructor Create(Conn: TUniConnection; const DBName: string); overload;
    constructor Create(const Host: string;
                       Port: Integer;
                       const Database,
                       User,
                       Password: string); overload;
    destructor Destroy; override;
    // Métodos de conexión
    procedure Connect;
    procedure Disconnect;
    function GetDatabaseName: string;
    // Implementación de la interfaz
    function GetTables: TStringList;
    function GetTableStructure(const TableName: string): TTableInfo;
    function GetTableIndexes(const TableName: string): TArray<TIndexInfo>;
    function GetTriggers: TArray<TTriggerInfo>;
    function GetTriggerDefinition(const TriggerName: string): string;
    function GetViews:TStringList;
    function GetViewDefinition(const ViewName:string):string;
    function GetProcedures:TStringList;
    function GetFunctions:TStringList;
    function GetSequences:TSTringList;
    function GetProcedureDefinition(const ProcedureName:string):string;
    function GetFunctionDefinition(const FunctionName:string):string;
    function GetData(const TableName: string;
                     const Filter: string = ''): TDataSet;
    function GetRowCount(const TableName: string;
                         const Filter: string = ''): Integer;
  private
    function StripDefiner(const SQL: string): string;
  end;

implementation

{ TMySQLMetadataProvider }

function TMySQLMetadataProvider.GetSequences: TStringList;
begin
  // MySQL no tiene secuencias independientes, devolvemos lista vacía.
  Result := TStringList.Create;
end;

function TMySQLMetadataProvider.GetData(const TableName: string;
                                        const Filter: string = ''): TDataSet;
var
  Query: TUniQuery;
  function QuoteIdentifier(const Identifier: string): string;
  begin
    Result := '`' + Identifier + '`';
  end;
begin
  Query := TUniQuery.Create(nil);
  Query.Connection := FConn;
  FConn.Database := FDBName;
  Query.SQL.Text := 'SELECT * FROM ' + QuoteIdentifier(TableName);
  if Filter <> '' then
    Query.SQL.Add('WHERE ' + Filter);
  Query.Open;
  Result := Query;
end;

function TMySQLMetadataProvider.GetRowCount(
  const TableName, Filter: string): Integer;
var
  Query: TUniQuery;
begin
  Result := 0;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    if Filter = '' then
      Query.SQL.Text :=
        'SELECT TABLE_ROWS' +
        '  FROM INFORMATION_SCHEMA.TABLES' +
        ' WHERE TABLE_SCHEMA = ' + QuotedStr(FDBName) +
        '   AND TABLE_NAME = ' + QuotedStr(TableName)
    else
      Query.SQL.Text :=
        'SELECT COUNT(*)' +
        '  FROM `' + TableName + '`' +
        ' WHERE ' + Filter;
    Query.Open;
    if not Query.Eof then
      Result := Query.Fields[0].AsInteger;
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetFunctionDefinition(
  const FunctionName: string): string;
var
  Query: TUniQuery;
  DBPrefix: string;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    Query.Connection.Database := FDBName;
    Query.SQL.Text := 'SHOW CREATE FUNCTION `' + FunctionName + '`'; //
    Query.Open;
    Result := Query.Fields[2].AsString; //
    Result := StripDefiner(Result); //
    DBPrefix := '`' + FDBName + '`.';
    Result := StringReplace(Result, DBPrefix, '', [rfReplaceAll, rfIgnoreCase]);
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetFunctions: TStringList;
var
  Query: TUniQuery;
begin
  Result := TStringList.Create;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
//    FConn.Database := SCHEMADB;
    Query.SQL.Text := '   SELECT ROUTINE_NAME '+
                      '     FROM INFORMATION_SCHEMA.ROUTINES ' +
                      '    WHERE ROUTINE_SCHEMA = ' + QuotedStr(FDBName) +
                      '      AND ROUTINE_TYPE = '+ QuotedStr('FUNCTION') +
                      ' ORDER BY ROUTINE_NAME';
    Query.Open;
    while not Query.Eof do
    begin
      Result.Add(Query.FieldByName('ROUTINE_NAME').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

constructor TMySQLMetadataProvider.Create(Conn: TUniConnection;
  const DBName: string);
begin
  FDBName := DBName;
  Fconn := Conn;
  FConn.ProviderName := 'MySQL';
  FConn.Connected := True;
  FOwnsConnection := False;
end;

constructor TMySQLMetadataProvider.Create(const Host: string; Port: Integer;
  const Database, User, Password: string);
begin
  FHost := Host;
  FPort := Port;
  FDBName := Database;
  FUser := User;
  FPassword := Password;
  FOwnsConnection := True;
  
  FConn := TUniConnection.Create(nil);
  FConn.ProviderName := 'MySQL';
  FConn.Server := FHost;
  FConn.Port := FPort;
  FConn.Database := FDBName;
  FConn.Username := FUser;
  FConn.Password := FPassword;
end;

procedure TMySQLMetadataProvider.Connect;
begin
  if not FConn.Connected then
    FConn.Connected := True;
end;

procedure TMySQLMetadataProvider.Disconnect;
begin
  if FConn.Connected then
    FConn.Connected := False;
end;

function TMySQLMetadataProvider.GetDatabaseName: string;
begin
  Result := FDBName;
end;

destructor TMySQLMetadataProvider.Destroy;
begin
  if FOwnsConnection then
    FConn.Free;
  inherited;
end;

function TMySQLMetadataProvider.GetProcedureDefinition(
  const ProcedureName:string): string;
var
  Query: TUniQuery;
  DBPrefix: string;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    Query.Connection.Database := FDBName;
    Query.SQL.Text := 'SHOW CREATE PROCEDURE `' + ProcedureName + '`'; //
    Query.Open;
    Result := Query.Fields[2].AsString; //
    Result := StripDefiner(Result); //
    DBPrefix := '`' + FDBName + '`.';
    Result := StringReplace(Result, DBPrefix, '', [rfReplaceAll, rfIgnoreCase]);
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetProcedures: TStringList;
var
  Query: TUniQuery;
begin
  Result := TStringList.Create;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
//    FConn.Database := SCHEMADB;
    Query.SQL.Text := '   SELECT ROUTINE_NAME '+
                      '     FROM INFORMATION_SCHEMA.ROUTINES ' +
                      '    WHERE ROUTINE_SCHEMA = ' + QuotedStr(FDBName) +
                      '      AND ROUTINE_TYPE = '+ QuotedStr('PROCEDURE') +
                      ' ORDER BY ROUTINE_NAME';
    Query.Open;
    while not Query.Eof do
    begin
      Result.Add(Query.FieldByName('ROUTINE_NAME').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetTableIndexes(
  const TableName: string): TArray<TIndexInfo>;
var
  Query: TUniQuery;
  IndexList: TList<TIndexInfo>;
  CurrentIndex: TIndexInfo;
  LastIndexName: string;
  ColList: TList<TIndexColumn>;
  IndexCol: TIndexColumn;
begin
  IndexList := TList<TIndexInfo>.Create;
  ColList := TList<TIndexColumn>.Create;
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FConn;
//      FConn.Database := SCHEMADB;
      Query.SQL.Text :=
        'SELECT INDEX_NAME, ' +
        '       NON_UNIQUE, ' +
        '       COLUMN_NAME, ' +
        '       SEQ_IN_INDEX ' +
        '  FROM INFORMATION_SCHEMA.STATISTICS ' +
        ' WHERE TABLE_SCHEMA = ' + QuotedStr(FDBName) +
        '   AND TABLE_NAME = ' + QuotedStr(TableName) + ' ' +
        'ORDER BY INDEX_NAME, SEQ_IN_INDEX';
      Query.Open;
      LastIndexName := '';
      while not Query.Eof do
      begin
        // Nuevo índice detectado
        if not SameText(Query.FieldByName('INDEX_NAME').AsString,
                        LastIndexName) then
        begin
          // Guardar el índice anterior si existe
          if not SameText(LastIndexName, '') then
          begin
            CurrentIndex.Columns := ColList.ToArray;
            IndexList.Add(CurrentIndex);
            ColList.Clear;
          end;
          // Iniciar nuevo índice
          LastIndexName := Query.FieldByName('INDEX_NAME').AsString;
          CurrentIndex.IndexName := LastIndexName;
          CurrentIndex.IsPrimary := SameText(LastIndexName, 'PRIMARY');
          CurrentIndex.IsUnique :=
            (Query.FieldByName('NON_UNIQUE').AsInteger = 0);
        end;
        // Agregar columna al índice actual
        IndexCol.ColumnName := Query.FieldByName('COLUMN_NAME').AsString;
        IndexCol.SeqInIndex := Query.FieldByName('SEQ_IN_INDEX').AsInteger;
        ColList.Add(IndexCol);
        Query.Next;
      end;
      // Guardar el último índice
      if not SameText(LastIndexName, '') then
      begin
        CurrentIndex.Columns := ColList.ToArray;
        IndexList.Add(CurrentIndex);
      end;
    finally
      Query.Free;
    end;
    Result := IndexList.ToArray;
  finally
    IndexList.Free;
    ColList.Free;
  end;
end;

function TMySQLMetadataProvider.GetTables: TStringList;
var
  Query: TUniQuery;
begin
  Result := TStringList.Create;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    Query.SQL.Text := 'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ' +
                      'WHERE TABLE_SCHEMA = ' + QuotedStr(FDBName) +
                      '  AND TABLE_TYPE = ''BASE TABLE'' ' +
                      'ORDER BY TABLE_NAME';
    Query.Open;
    while (not(Query.Eof)) do
    begin
      Result.Add(Query.FieldByName('TABLE_NAME').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetTableStructure(
  const TableName: string): TTableInfo;
var
  Query: TUniQuery;
  Col: TColumnInfo;
begin
  // 1. Inicializamos el resultado y la consulta
  Result := TTableInfo.Create;
  Result.TableName := TableName;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    // 2. Consulta a INFORMATION_SCHEMA optimizada y parametrizada
    Query.SQL.Text := 'SELECT COLUMN_NAME, ' +
                      '       COLUMN_TYPE, ' +
                      '       IS_NULLABLE, ' +
                      '       COLUMN_KEY, ' +
                      '       EXTRA, ' +
                      '       COLUMN_DEFAULT, ' +
                      '       CHARACTER_MAXIMUM_LENGTH, ' +
                      '       COLUMN_COMMENT ' +
                      '  FROM INFORMATION_SCHEMA.COLUMNS ' +
                      ' WHERE TABLE_SCHEMA = :DbName ' +
                      '   AND TABLE_NAME = :TbName ' +
                      ' ORDER BY ORDINAL_POSITION';
    // Asignamos los parámetros para seguridad y robustez
    Query.ParamByName('DbName').AsString := FDBName;
    Query.ParamByName('TbName').AsString := TableName;
    Query.Open;
    // 3. Iteramos por las columnas encontradas
    while not Query.Eof do
    begin
      // IMPORTANTE: Si TColumnInfo es una CLASE, descomenta la línea de abajo.
      // Si es un RECORD, déjala comentada.
      // Col := TColumnInfo.Create;
      // Lectura de campos básicos
      Col.ColumnName := Query.FieldByName('COLUMN_NAME').AsString;
      Col.DataType   := Query.FieldByName('COLUMN_TYPE').AsString;
      // 'YES' o 'NO'
      Col.IsNullable := Query.FieldByName('IS_NULLABLE').AsString;
      // 'PRI', 'UNI', etc.
      Col.ColumnKey  := Query.FieldByName('COLUMN_KEY').AsString;
      // 'auto_increment', etc.
      Col.Extra      := Query.FieldByName('EXTRA').AsString;
      // --- Lógica CRÍTICA para el Valor por Defecto (Solución Error 1067) ---
      if Query.FieldByName('COLUMN_DEFAULT').IsNull then
      begin
        // Si es nulo en la BD, usamos una marca especial interna.
        // NOTA: Tu generador de SQL debe saber que '<NULL>' significa
        // sin default .
        Col.ColumnDefault := '<NULL>';
      end
      else
      begin
        // Si tiene un valor real (incluso cadena vacía ''), lo tomamos tal
        // cual.
        Col.ColumnDefault := Query.FieldByName('COLUMN_DEFAULT').AsString;
      end;
      // Manejo de longitud máxima
      if not Query.FieldByName('CHARACTER_MAXIMUM_LENGTH').IsNull then
        Col.CharMaxLength :=
          Query.FieldByName('CHARACTER_MAXIMUM_LENGTH').AsString
      else
        Col.CharMaxLength := '0';
      // Manejo de comentarios
      if not Query.FieldByName('COLUMN_COMMENT').IsNull then
        Col.ColumnComment := Query.FieldByName('COLUMN_COMMENT').AsString
      else
        Col.ColumnComment := '';
      // Agregamos la columna a la lista
      Result.Columns.Add(Col);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetTriggerDefinition(
  const TriggerName: string): string;
var
  Query: TUniQuery;
  DBPrefix: string;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    FConn.Database := FDBName;
    Query.SQL.Text := 'SHOW CREATE TRIGGER `' + TriggerName + '`'; //
    Query.Open;
    Result := Query.Fields[2].AsString; //
    Result := StripDefiner(Result); //
    DBPrefix := '`' + FDBName + '`.';
    Result := StringReplace(Result, DBPrefix, '', [rfReplaceAll, rfIgnoreCase]);
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetTriggers: TArray<TTriggerInfo>;
var
  Query: TUniQuery;
  TriggerList: TList<TTriggerInfo>;
  Trigger: TTriggerInfo;
begin
  TriggerList := TList<TTriggerInfo>.Create;
  try
    Query := TUniQuery.Create(nil);
    try
//      FConn.Database := SCHEMADB;
      Query.Connection := FConn;
      // CORRECCIÓN: Concatenación y espacios
      Query.SQL.Text :=
        'SELECT TRIGGER_NAME, ' +
        '       EVENT_MANIPULATION, ' +
        '       ACTION_TIMING, ' +
        '       ACTION_STATEMENT, ' +
        '       EVENT_OBJECT_TABLE ' +
        '  FROM INFORMATION_SCHEMA.TRIGGERS ' +
        ' WHERE TRIGGER_SCHEMA = ' + QuotedStr(FDBName) + ' ' +
        'ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME';
      Query.Open;
      while not Query.Eof do
      begin
        Trigger.TriggerName := Query.FieldByName('TRIGGER_NAME').AsString;
        Trigger.EventManipulation :=
                               Query.FieldByName('EVENT_MANIPULATION').AsString;
        Trigger.ActionTiming := Query.FieldByName('ACTION_TIMING').AsString;
        Trigger.ActionStatement :=
                                 Query.FieldByName('ACTION_STATEMENT').AsString;
        Trigger.EventObjectTable :=
                               Query.FieldByName('EVENT_OBJECT_TABLE').AsString;
        TriggerList.Add(Trigger);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    Result := TriggerList.ToArray;
  finally
    TriggerList.Free;
  end;
end;

function TMySQLMetadataProvider.GetViewDefinition(
  const ViewName: string): string;
var
  Query: TUniQuery;
  DBPrefix: string;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    FConn.Database := FDBName;
    Query.SQL.Text := 'SHOW CREATE VIEW `' + ViewName + '`';
    Query.Open;
    Result := Query.Fields[1].AsString;
    Result := StripDefiner(Result);
    DBPrefix := '`' + FDBName + '`.';
    Result := StringReplace(Result, DBPrefix, '', [rfReplaceAll, rfIgnoreCase]);
  finally
    Query.Free;
  end;
end;

function TMySQLMetadataProvider.GetViews: TStringList;
var
  Query: TUniQuery;
begin
  Result := TStringList.Create;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConn;
    Fconn.Database := SCHEMADB;
    Query.SQL.Text := 'SELECT TABLE_NAME' +
                      '  FROM INFORMATION_SCHEMA.VIEWS ' +
                      ' WHERE TABLE_SCHEMA = ' + QuotedStr(FDBName) + ' ' +
                      'ORDER BY TABLE_NAME';
    Query.Open;
    while not Query.Eof do
    begin
      Result.Add(Query.FieldByName('TABLE_NAME').AsString);
      Query.Next;
    end;
    OrdenarVistasPorDependencias(Result);
  finally
    Query.Free;
  end;
end;

procedure TMySQLMetadataProvider.OrdenarVistasPorDependencias(
  Vistas: TStringList);
var
  oDDL: TDictionary<string, string>;
  oOrdenadas: TStringList;
  oPendientes: TStringList;
  bAgregado: Boolean;
  bDepende: Boolean;
  sNombre: string;
  sDep: string;
  sDDL: string;
  i, j: Integer;
begin
  oDDL := TDictionary<string, string>.Create;
  oOrdenadas := TStringList.Create;
  oPendientes := TStringList.Create;
  try
    for i := 0 to Vistas.Count - 1 do
      oDDL.Add(Vistas[i], GetViewDefinition(Vistas[i]));
    oPendientes.Assign(Vistas);
    oPendientes.Sort;
    while oPendientes.Count > 0 do
    begin
      bAgregado := False;
      i := 0;
      while i < oPendientes.Count do
      begin
        sNombre := oPendientes[i];
        bDepende := False;
        if oDDL.TryGetValue(sNombre, sDDL) then
        begin
          for j := 0 to oPendientes.Count - 1 do
          begin
            sDep := oPendientes[j];
            if not SameText(sDep, sNombre) then
            begin
              if DDLReferenciaVista(sDDL, sDep) then
                bDepende := True;
            end;
          end;
        end;
        if not bDepende then
        begin
          oOrdenadas.Add(sNombre);
          oPendientes.Delete(i);
          bAgregado := True;
        end
        else
          Inc(i);
      end;
      if not bAgregado then
      begin
        oOrdenadas.Add(oPendientes[0]);
        oPendientes.Delete(0);
      end;
    end;
    Vistas.Assign(oOrdenadas);
  finally
    oDDL.Free;
    oOrdenadas.Free;
    oPendientes.Free;
  end;
end;

function TMySQLMetadataProvider.DDLReferenciaVista(const DDL,
  Vista: string): Boolean;
begin
  Result := ContainsText(DDL, '`' + Vista + '`') or
            ContainsText(DDL, '"' + Vista + '"') or
            ContieneIdentificadorSQL(DDL, Vista);
end;

function TMySQLMetadataProvider.ContieneIdentificadorSQL(const Texto,
  Identificador: string): Boolean;
var
  TextoNorm: string;
  IdNorm: string;
  Posicion: Integer;
  LenId: Integer;
  Inicio: Boolean;
  Fin: Boolean;
begin
  Result := False;
  TextoNorm := LowerCase(Texto);
  IdNorm := LowerCase(Identificador);
  LenId := Length(IdNorm);
  Posicion := PosEx(IdNorm, TextoNorm, 1);
  while Posicion > 0 do
  begin
    Inicio := (Posicion = 1) or
      (not EsCaracterIdentificadorSQL(TextoNorm[Posicion - 1]));
    Fin := (Posicion + LenId > Length(TextoNorm)) or
      (not EsCaracterIdentificadorSQL(TextoNorm[Posicion + LenId]));
    if Inicio and Fin then
      Result := True;
    if not Result then
      Posicion := PosEx(IdNorm, TextoNorm, Posicion + LenId)
    else
      Posicion := 0;
  end;
end;

function TMySQLMetadataProvider.EsCaracterIdentificadorSQL(
  Caracter: Char): Boolean;
begin
  Result := ((Caracter >= 'a') and (Caracter <= 'z')) or
            ((Caracter >= 'A') and (Caracter <= 'Z')) or
            ((Caracter >= '0') and (Caracter <= '9')) or
            (Caracter = '_');
end;

function TMySQLMetadataProvider.StripDefiner(const SQL: string): string;
var
  PosDefiner, PosEnd: Integer;
  UpperSQL: string;
begin
  Result := SQL;
  UpperSQL := UpperCase(SQL);
  PosDefiner := Pos('DEFINER=', UpperSQL);
  if PosDefiner > 0 then
  begin
    PosEnd := 0;
    // 1. Buscar PROCEDURE (Prioridad alta para evitar error
    //    con SQLEXCEPTION en el cuerpo)
    if (PosEnd = 0) then PosEnd := PosEx('PROCEDURE', UpperSQL, PosDefiner);
    // 2. Buscar TRIGGER
    if (PosEnd = 0) then PosEnd := PosEx('TRIGGER', UpperSQL, PosDefiner);
    // 3. Buscar FUNCTION
    if (PosEnd = 0) then PosEnd := PosEx('FUNCTION', UpperSQL, PosDefiner);
    // 4. Buscar VIEW (Esto limpiará también el
    //    'SQL SECURITY' si está antes del VIEW)
    if (PosEnd = 0) then PosEnd := PosEx('VIEW', UpperSQL, PosDefiner);
    // NOTA: Hemos eliminado la búsqueda genérica de 'SQL' porque causaba
    // falsos positivos con variables o handlers como 'SQLEXCEPTION'.
    if (PosEnd > 0) then
    begin
      // Cortamos desde el inicio del DEFINER hasta justo antes del
      // tipo de objeto Y Agregamos un espacio por seguridad para evitar
      // concatenaciones tipo "UNDEFINEDVIEW"
      Result := Trim(Copy(Result, 1, PosDefiner - 1) + ' ' +
                     Copy(Result, PosEnd, Length(Result)));
    end;
  end;
end;


end.
