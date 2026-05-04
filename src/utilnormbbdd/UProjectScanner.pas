unit UProjectScanner;

{
  Escanea carpetas con código Delphi (.pas, .dfm) buscando ocurrencias de
  nombres de columnas y, opcionalmente, las reemplaza creando un backup .bak.

  Reglas:
   - La búsqueda es CASE-SENSITIVE (los nombres de columna van en MAYÚSCULAS).
   - Solo matchea como "palabra completa" (boundary = no letras/dígitos/_ a
     izq/dcha). Esto evita que NIF_CLI machaque NIF_CLIENTE si quedara alguno.
   - Procesamos primero los nombres más largos para evitar reemplazos parciales
     en nombres compuestos (ej: CODIGO_ARTICULO_TARIFA antes que CODIGO_ARTICULO).
   - Antes de modificar un fichero se crea backup .bak (si no existe ya).
}

interface

uses
  System.Classes, System.SysUtils, System.IOUtils,  System.Generics.Defaults,
  System.Generics.Collections, System.RegularExpressions;

type
  TFileMatch = record
    FilePath:   string;
    LineNumber: Integer;
    LineText:   string;
    ColumnOld:  string;   // nombre antiguo
    ColumnNew:  string;   // nombre nuevo (para preview)
  end;

  TFileMatchList = TList<TFileMatch>;

  { Resultado de la pasada B (auditoría laxa).
    Recoge ocurrencias donde el nombre antiguo aparece pegado a un identificador
    (prefijo o sufijo con letras/dígitos/_), que la pasada estricta NO toca.
    Es solo informativo: ScanLooseAudit no modifica ficheros. }
  TLooseMatch = record
    FilePath:    string;
    LineNumber:  Integer;
    LineText:    string;
    ColumnOld:   string;   // nombre antiguo encontrado
    ColumnNew:   string;   // a qué se renombraría si se hiciera (referencia)
    Context:     string;   // identificador completo, p.ej. ":Old_CODIGO_ARTICULO"
    Reason:      string;   // 'prefijo', 'sufijo' o 'prefijo+sufijo'
  end;

  TLooseMatchList = TList<TLooseMatch>;

  TFileChangeStat = record
    FilePath:    string;
    Replacements: Integer;
    Backup:      string;  // ruta del .bak creado, '' si no se hizo
  end;

  TFileChangeList = TList<TFileChangeStat>;

  TPlanPair = record
    OldName: string;
    NewName: string;
    constructor Create(const AOld, ANew: string);
  end;

  TPlanPairList = TList<TPlanPair>;

  TProjectScanner = class
  private
    FFolders:     TStringList;
    FExtensions:  TStringList;
    FRenamePlan:  TPlanPairList;
    FOnLog:       TProc<string>;

    procedure Log(const S: string);
    function  CollectFiles: TArray<string>;
    function  IsBoundary(C: Char): Boolean;
    function  IsIdentChar(C: Char): Boolean;
    function  ExtractFullIdent(const Line: string; AMatchPos, AMatchLen: Integer): string;
    procedure SortPlanByLengthDesc;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure AddFolder(const Path: string);
    procedure ClearFolders;
    procedure SetExtensions(const Exts: array of string);

    procedure SetRenamePlan(APlan: TPlanPairList);

    {
      Solo busca y devuelve los matches. No modifica nada.
    }
    procedure Scan(AOutMatches: TFileMatchList);

    {
      Pasada B (auditoría). NO modifica nada. Recorre los mismos ficheros
      buscando ocurrencias del nombre antiguo donde el carácter de antes
      o de después es letra/dígito/_ (es decir, casos que la pasada estricta
      descarta por boundary). Útil para detectar :OLD_CODIGO_ARTICULO,
      vCODIGO_ARTICULO, MI_CODIGO_ARTICULO, etc.
    }
    procedure ScanLooseAudit(AOutMatches: TLooseMatchList);

    {
      Busca y aplica los reemplazos. Crea backup .bak antes de modificar.
      Devuelve estadísticas por fichero.
    }
    procedure ApplyReplacements(AStats: TFileChangeList);

    property OnLog: TProc<string> read FOnLog write FOnLog;
    property Folders: TStringList read FFolders;
  end;

implementation

{ TPlanPair }

constructor TPlanPair.Create(const AOld, ANew: string);
begin
  OldName := AOld;
  NewName := ANew;
end;

{ TProjectScanner }

constructor TProjectScanner.Create;
begin
  inherited Create;
  FFolders     := TStringList.Create;
  FExtensions  := TStringList.Create;
  FRenamePlan  := TPlanPairList.Create;

  // Por defecto: .pas y .dfm
  SetExtensions(['.pas', '.dfm']);
end;

destructor TProjectScanner.Destroy;
begin
  FFolders.Free;
  FExtensions.Free;
  FRenamePlan.Free;
  inherited;
end;

procedure TProjectScanner.Log(const S: string);
begin
  if Assigned(FOnLog) then FOnLog(S);
end;

procedure TProjectScanner.AddFolder(const Path: string);
begin
  if (Path <> '') and DirectoryExists(Path) and (FFolders.IndexOf(Path) < 0) then
    FFolders.Add(Path);
end;

procedure TProjectScanner.ClearFolders;
begin
  FFolders.Clear;
end;

procedure TProjectScanner.SetExtensions(const Exts: array of string);
var
  S: string;
begin
  FExtensions.Clear;
  for S in Exts do
    FExtensions.Add(S.ToLower);
end;

procedure TProjectScanner.SetRenamePlan(APlan: TPlanPairList);
var
  P: TPlanPair;
begin
  FRenamePlan.Clear;
  for P in APlan do
    if P.OldName <> P.NewName then
      FRenamePlan.Add(P);
  SortPlanByLengthDesc;
end;

procedure TProjectScanner.SortPlanByLengthDesc;
begin
  // Ordenar el plan: nombres viejos más largos primero, así evitamos que
  // un reemplazo corto rompa uno largo.
  FRenamePlan.Sort(TComparer<TPlanPair>.Construct(
    function(const L, R: TPlanPair): Integer
    begin
      Result := Length(R.OldName) - Length(L.OldName);
      if Result = 0 then
        Result := CompareStr(L.OldName, R.OldName);
    end));
end;

function TProjectScanner.CollectFiles: TArray<string>;
var
  Folder, Ext, F: string;
  All: TStringList;
  Files: TArray<string>;
begin
  All := TStringList.Create;
  try
    All.Sorted := True;
    All.Duplicates := dupIgnore;
    for Folder in FFolders do
    begin
      if not DirectoryExists(Folder) then
      begin
        Log(Format('[WARN] Carpeta no existe: %s', [Folder]));
        Continue;
      end;
      for Ext in FExtensions do
      begin
        Files := TDirectory.GetFiles(Folder, '*' + Ext, TSearchOption.soAllDirectories);
        for F in Files do
          All.Add(F);
      end;
    end;
    Result := All.ToStringArray;
  finally
    All.Free;
  end;
end;

function TProjectScanner.IsBoundary(C: Char): Boolean;
begin
  Result := not (CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '_']));
end;

function TProjectScanner.IsIdentChar(C: Char): Boolean;
begin
  Result := CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function TProjectScanner.ExtractFullIdent(const Line: string;
  AMatchPos, AMatchLen: Integer): string;
var
  Lo, Hi: Integer;
begin
  // Expande hacia izquierda y derecha mientras los caracteres formen identificador.
  Lo := AMatchPos;
  while (Lo > 1) and IsIdentChar(Line[Lo - 1]) do
    Dec(Lo);
  Hi := AMatchPos + AMatchLen - 1;
  while (Hi < Length(Line)) and IsIdentChar(Line[Hi + 1]) do
    Inc(Hi);
  Result := Copy(Line, Lo, Hi - Lo + 1);
end;

procedure TProjectScanner.Scan(AOutMatches: TFileMatchList);
var
  Files:    TArray<string>;
  F:        string;
  Lines:    TStringList;
  Pair:     TPlanPair;
  i:        Integer;
  Line:     string;
  iPos:     Integer;
  Pre, Post: Char;
  M:        TFileMatch;
  TotalMatches: Integer;
begin
  AOutMatches.Clear;
  if FRenamePlan.Count = 0 then
  begin
    Log('[WARN] No hay plan de renombrado cargado.');
    Exit;
  end;

  Files := CollectFiles;
  Log(Format('Escaneando %d ficheros…', [Length(Files)]));
  TotalMatches := 0;

  for F in Files do
  begin
    Lines := TStringList.Create;
    try
      try
        Lines.LoadFromFile(F, TEncoding.ANSI);
      except
        // Reintentar con UTF-8
        try
          Lines.LoadFromFile(F, TEncoding.UTF8);
        except
          on E: Exception do
          begin
            Log(Format('[ERROR] No se pudo leer %s: %s', [F, E.Message]));
            Continue;
          end;
        end;
      end;

      for i := 0 to Lines.Count - 1 do
      begin
        Line := Lines[i];
        for Pair in FRenamePlan do
        begin
          iPos := 1;
          while iPos > 0 do
          begin
            iPos := System.Pos(Pair.OldName, Line, iPos);
            if iPos = 0 then Break;
            // Comprobar boundary
            if iPos = 1 then
              Pre := #0
            else
              Pre := Line[iPos - 1];
            if iPos + Length(Pair.OldName) > Length(Line) then
              Post := #0
            else
              Post := Line[iPos + Length(Pair.OldName)];

            if ((Pre = #0) or IsBoundary(Pre)) and
               ((Post = #0) or IsBoundary(Post)) then
            begin
              M.FilePath   := F;
              M.LineNumber := i + 1;
              M.LineText   := Line;
              M.ColumnOld  := Pair.OldName;
              M.ColumnNew  := Pair.NewName;
              AOutMatches.Add(M);
              Inc(TotalMatches);
            end;
            Inc(iPos, Length(Pair.OldName));
          end;
        end;
      end;
    finally
      Lines.Free;
    end;
  end;

  Log(Format('Escaneo completado: %d coincidencias en %d ficheros revisados.',
    [TotalMatches, Length(Files)]));
end;

procedure TProjectScanner.ScanLooseAudit(AOutMatches: TLooseMatchList);
var
  Files:           TArray<string>;
  F:               string;
  Lines:           TStringList;
  Pair:            TPlanPair;
  i:               Integer;
  Line:            string;
  iPos:            Integer;
  HasPre, HasPost: Boolean;
  M:               TLooseMatch;
  TotalMatches:    Integer;
begin
  AOutMatches.Clear;
  if FRenamePlan.Count = 0 then
  begin
    Log('[WARN] Auditoría: no hay plan de renombrado cargado.');
    Exit;
  end;

  Files := CollectFiles;
  Log(Format('Auditoría laxa: escaneando %d ficheros…', [Length(Files)]));
  TotalMatches := 0;

  for F in Files do
  begin
    Lines := TStringList.Create;
    try
      try
        Lines.LoadFromFile(F, TEncoding.ANSI);
      except
        try
          Lines.LoadFromFile(F, TEncoding.UTF8);
        except
          on E: Exception do
          begin
            Log(Format('[ERROR] No se pudo leer %s: %s', [F, E.Message]));
            Continue;
          end;
        end;
      end;

      for i := 0 to Lines.Count - 1 do
      begin
        Line := Lines[i];
        for Pair in FRenamePlan do
        begin
          iPos := 1;
          while iPos > 0 do
          begin
            iPos := System.Pos(Pair.OldName, Line, iPos);
            if iPos = 0 then Break;

            // ¿Hay carácter de identificador pegado a izq/dcha?
            HasPre  := (iPos > 1) and IsIdentChar(Line[iPos - 1]);
            HasPost := (iPos + Length(Pair.OldName) <= Length(Line))
                       and IsIdentChar(Line[iPos + Length(Pair.OldName)]);

            // Solo nos interesan los casos que la pasada estricta NO trataría:
            // al menos un lado pegado a un identificador.
            if HasPre or HasPost then
            begin
              M.FilePath   := F;
              M.LineNumber := i + 1;
              M.LineText   := Line;
              M.ColumnOld  := Pair.OldName;
              M.ColumnNew  := Pair.NewName;
              M.Context    := ExtractFullIdent(Line, iPos, Length(Pair.OldName));
              if HasPre and HasPost then
                M.Reason := 'prefijo+sufijo'
              else if HasPre then
                M.Reason := 'prefijo'
              else
                M.Reason := 'sufijo';
              AOutMatches.Add(M);
              Inc(TotalMatches);
            end;
            Inc(iPos, Length(Pair.OldName));
          end;
        end;
      end;
    finally
      Lines.Free;
    end;
  end;

  Log(Format('Auditoría completada: %d ocurrencias sospechosas en %d ficheros revisados.',
    [TotalMatches, Length(Files)]));
end;

procedure TProjectScanner.ApplyReplacements(AStats: TFileChangeList);
var
  Files:    TArray<string>;
  F:        string;
  Original, Modified: string;
  Pair:     TPlanPair;
  Pat:      string;
  Replacements: Integer;
  Stat:     TFileChangeStat;
  BackupPath: string;
begin
  AStats.Clear;
  if FRenamePlan.Count = 0 then
  begin
    Log('[WARN] No hay plan de renombrado cargado.');
    Exit;
  end;

  Files := CollectFiles;
  Log(Format('Aplicando reemplazos en %d ficheros…', [Length(Files)]));

  for F in Files do
  begin
    try
      Original := TFile.ReadAllText(F);
    except
      on E: Exception do
      begin
        Log(Format('[ERROR] Lectura %s: %s', [F, E.Message]));
        Continue;
      end;
    end;

    Modified := Original;
    Replacements := 0;

    // Aplicamos los reemplazos del plan, ordenados de más largo a más corto.
    for Pair in FRenamePlan do
    begin
      Pat := '(?<![A-Za-z0-9_])' + TRegEx.Escape(Pair.OldName) + '(?![A-Za-z0-9_])';
      // Contar matches antes de reemplazar
      Inc(Replacements, TRegEx.Matches(Modified, Pat).Count);
      Modified := TRegEx.Replace(Modified, Pat, Pair.NewName);
    end;

    if Modified <> Original then
    begin
      // Crear backup
      BackupPath := F + '.bak';
      if not FileExists(BackupPath) then
      begin
        try
          TFile.Copy(F, BackupPath, False);
        except
          on E: Exception do
          begin
            Log(Format('[ERROR] No se pudo crear backup de %s: %s', [F, E.Message]));
            Continue;
          end;
        end;
      end;

      try
        TFile.WriteAllText(F, Modified);
        Stat.FilePath     := F;
        Stat.Replacements := Replacements;
        Stat.Backup       := BackupPath;
        AStats.Add(Stat);
        Log(Format('  Modificado: %s (%d reemplazos, backup: %s)',
          [F, Replacements, BackupPath]));
      except
        on E: Exception do
          Log(Format('[ERROR] Escritura %s: %s', [F, E.Message]));
      end;
    end;
  end;

  Log(Format('Reemplazos aplicados a %d ficheros.', [AStats.Count]));
end;

end.
