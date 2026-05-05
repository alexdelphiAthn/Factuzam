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
   - En .dfm, ANTES de buscar, unimos las cadenas Pascal continuadas con +
     ('FOO_EM' + 'PRESA' -> 'FOO_EMPRESA') para que los nombres partidos por
     el formateo de Delphi sí se detecten y reemplacen.
   - Antes de modificar un fichero se crea backup .bak (si no existe ya).
}

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.Generics.Defaults,
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
    function  ExtractFullIdent(const Line: string;
                               AMatchPos, AMatchLen: Integer): string;
    procedure SortPlanByLengthDesc;
    procedure DoScanJoinedDfm(const FilePath, RawText: string;
                              AOutMatches: TFileMatchList;
                              var TotalMatches: Integer);
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

{
  Une cadenas Pascal continuadas con '+' a través de varias líneas en una
  sola cadena lógica.

  Ejemplo de entrada (.dfm con SQL multilínea):
      '  (CODIGO_EMP, RAZON_SOCIAL_EM' +
      'PRESA, NIF_EMP)'
  Salida:
      '  (CODIGO_EMP, RAZON_SOCIAL_EMPRESA, NIF_EMP)'

  Reglas:
   - SOLO concatena cuando hay un SALTO DE LÍNEA entre las dos cadenas.
     Patrón: ' (espacios opcionales) + (espacios opcionales) \r?\n (espacios) '
     Las concatenaciones en LA MISMA línea como  'foo' + 'bar'  o  'a' + var + 'b'
     NO se tocan, porque suelen ser código Pascal embebido en scripts
     FastReport, eventos OnBeforePrint, etc., donde el '+' es semántico.
   - Las cadenas que se ponen una detrás de otra SIN '+' (Strings.Add)
     NO se unen — son entradas distintas en la lista.
   - Importante: este patrón es el típico de Delphi al guardar un .dfm con
     una cadena demasiado larga (Delphi la corta con  '...' +\n      '...').
}
function JoinPascalStringContinuations(const Source: string): string;
const
  // ' [espacios/tabs opcionales] + [espacios/tabs opcionales] \r?\n [espacios/tabs] '
  PATTERN = '''[ \t]*\+[ \t]*\r?\n[ \t]*''';
var
  Re: TRegEx;
begin
  Re := TRegEx.Create(PATTERN);
  Result := Re.Replace(Source, '');
end;

{
  Re-empaqueta cadenas Pascal demasiado largas en .dfm.

  Tras unir las cadenas continuadas y aplicar los reemplazos, una sola línea
  puede contener varios miles de caracteres. RLINK32 (el compilador de
  recursos de Delphi) falla con líneas DFM mayores de ~4096 chars y reporta
  un error engañoso: "Unsupported 16bit resource".

  Esta función localiza cualquier línea de la forma:
      <espacios> ' contenido sin saltos ' [opcional + contenido siguiente...]
  y, si supera MaxLen, la parte en trozos del estilo Delphi:

      <indent>'<trozo1>' +
      <indent>'<trozo2>' +
      <indent>'<trozoN>'

  Sólo opera sobre líneas que son STRING LITERAL completo (empiezan con
  espacios opcionales + apóstrofo y acaban con apóstrofo, posiblemente con
  ',' o ')' detrás). Esto evita tocar líneas con sintaxis DFM normal
  (asignaciones, propiedades, objetos, etc.).
}
function RewrapLongDfmStrings(const Source: string;
                              MaxChunkLen: Integer = 200): string;
var
  Lines:    TArray<string>;
  Out_:     TStringBuilder;
  Line:     string;
  i, j:     Integer;
  Indent:   string;
  Body:     string;     // contenido entre las primeras y últimas comillas
  Tail:     string;     // lo que viene tras la última comilla (',' o ')' o vacío)
  Trim:     string;
  ApPos1, ApPosN: Integer;
  ChunkLen: Integer;
  ChunkStart, ChunkEnd: Integer;
begin
  if MaxChunkLen < 40 then
    MaxChunkLen := 40;

  Lines := Source.Split([#13#10, #10], TStringSplitOptions.None);
  Out_ := TStringBuilder.Create(Length(Source));
  try
    for i := 0 to High(Lines) do
    begin
      Line := Lines[i];

      // ¿Necesita partirse?
      if Length(Line) <= MaxChunkLen + 32 then
      begin
        if i > 0 then Out_.Append(#13#10);
        Out_.Append(Line);
        Continue;
      end;

      // Calcular indentación (espacios al inicio)
      j := 1;
      while (j <= Length(Line)) and (Line[j] = ' ') do
        Inc(j);
      Indent := Copy(Line, 1, j - 1);
      Trim   := Copy(Line, j, MaxInt);

      // ¿Empieza con apóstrofo y acaba con apóstrofo (posiblemente +
      // un terminador de DFM ',' o ')' o nada)?
      if (Length(Trim) < 2) or (Trim[1] <> '''') then
      begin
        if i > 0 then Out_.Append(#13#10);
        Out_.Append(Line);
        Continue;
      end;

      ApPos1 := 1;  // primera comilla está en la posición 1 de Trim
      // Buscar la última comilla.  Trim puede acabar en  '   o   ',   o   ')
      ApPosN := Length(Trim);
      while (ApPosN > ApPos1) and (Trim[ApPosN] <> '''') do
        Dec(ApPosN);
      if ApPosN <= ApPos1 then
      begin
        if i > 0 then Out_.Append(#13#10);
        Out_.Append(Line);
        Continue;
      end;

      Body := Copy(Trim, ApPos1 + 1, ApPosN - ApPos1 - 1);
      Tail := Copy(Trim, ApPosN + 1, MaxInt);  // '', ',' o ')' o ',)' etc.

      // Si después de extraer el body la cosa no es razonable
      // (p.ej. el body contiene saltos de línea, cosa imposible aquí)
      // dejamos la línea tal cual.
      if (Body = '') then
      begin
        if i > 0 then Out_.Append(#13#10);
        Out_.Append(Line);
        Continue;
      end;

      // El body puede contener '' (apóstrofos escapados Pascal). Para no
      // partir un '' por la mitad, el chunker avanza saltando '' como pareja.
      ChunkStart := 1;
      if i > 0 then Out_.Append(#13#10);
      while ChunkStart <= Length(Body) do
      begin
        ChunkEnd := ChunkStart + MaxChunkLen - 1;
        if ChunkEnd > Length(Body) then
          ChunkEnd := Length(Body)
        else
        begin
          // Si justo en ChunkEnd estamos en medio de un '' (apóstrofo doble)
          // movemos hacia atrás 1 para no partirlo.
          if (ChunkEnd > ChunkStart) and (Body[ChunkEnd] = '''')
             and (ChunkEnd + 1 <= Length(Body)) and (Body[ChunkEnd + 1] = '''') then
            Inc(ChunkEnd);  // incluimos los dos juntos
        end;

        ChunkLen := ChunkEnd - ChunkStart + 1;
        Out_.Append(Indent);
        Out_.Append('''');
        Out_.Append(Copy(Body, ChunkStart, ChunkLen));
        Out_.Append('''');

        ChunkStart := ChunkEnd + 1;
        if ChunkStart <= Length(Body) then
        begin
          // Hay más trozos: continuamos con +
          Out_.Append(' +');
          Out_.Append(#13#10);
        end
        else
        begin
          // Último trozo: añadimos el Tail (',' o ')' o vacío)
          Out_.Append(Tail);
        end;
      end;
    end;
    Result := Out_.ToString;
  finally
    Out_.Free;
  end;
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

{
  Detecta matches "partidos" por la concatenación Pascal en .dfm.
  Une el texto, busca matches en la versión unida, y registra los que no
  encontramos en el escaneo línea-a-línea (LineNumber = -1).
}
procedure TProjectScanner.DoScanJoinedDfm(const FilePath, RawText: string;
  AOutMatches: TFileMatchList; var TotalMatches: Integer);
var
  Joined:        string;
  Pair:          TPlanPair;
  Pat:           string;
  Mt:            TMatch;
  M:             TFileMatch;
  CountInLines:  Integer;
  CountInJoined: Integer;
  Diff:          Integer;
  Lines:         TArray<string>;
  Line:          string;
begin
  Joined := JoinPascalStringContinuations(RawText);
  Lines  := RawText.Split([#13#10, #10], TStringSplitOptions.None);

  for Pair in FRenamePlan do
  begin
    Pat := '(?<![A-Za-z0-9_])' + TRegEx.Escape(Pair.OldName) + '(?![A-Za-z0-9_])';

    // Matches en el texto unido (incluye los partidos). Case-insensitive.
    CountInJoined := TRegEx.Matches(Joined, Pat, [roIgnoreCase]).Count;
    if CountInJoined = 0 then
      Continue;

    // Matches por línea (los normales que ya hemos contado)
    CountInLines := 0;
    for Line in Lines do
      Inc(CountInLines, TRegEx.Matches(Line, Pat, [roIgnoreCase]).Count);

    Diff := CountInJoined - CountInLines;
    if Diff <= 0 then
      Continue;

    // Hay 'Diff' matches que solo aparecen al unir las cadenas: están
    // partidos. Los registramos con LineNumber = -1.
    for Mt in TRegEx.Matches(Joined, Pat, [roIgnoreCase]) do
    begin
      M.FilePath   := FilePath;
      M.LineNumber := -1;  // partido entre líneas
      M.LineText   := '(string Pascal continuado entre varias líneas)';
      M.ColumnOld  := Pair.OldName;
      M.ColumnNew  := Pair.NewName;
      AOutMatches.Add(M);
      Inc(TotalMatches);
      Dec(Diff);
      if Diff = 0 then Break;
    end;
  end;
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
        // Para búsqueda case-insensitive: comparamos con todo en mayúsculas.
        // Mantenemos Line original para poder reportar el texto exacto.
        for Pair in FRenamePlan do
        begin
          iPos := 1;
          while iPos > 0 do
          begin
            // Búsqueda CASE-INSENSITIVE: comparamos con UpperCase de la línea
            // pero usamos posiciones de la línea original para el reporte.
            iPos := System.Pos(UpperCase(Pair.OldName), UpperCase(Line), iPos);
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

      // Para .dfm: detectar también matches que estén PARTIDOS por la
      // concatenación de strings Pascal ('foo' + 'bar'). Hacemos una
      // pasada extra sobre el texto unido y reportamos los matches que solo
      // aparecen al unir (con LineNumber = -1 para indicar "partido").
      if SameText(ExtractFileExt(F), '.dfm') then
        DoScanJoinedDfm(F, Lines.Text, AOutMatches, TotalMatches);
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

{
  Hace un reemplazo CASE-INSENSITIVE pero preserva el case del match:
   - Si el match está todo en MAYÚSCULAS → escribe NewName en MAYÚSCULAS
   - Si el match está todo en minúsculas → escribe NewName en minúsculas
   - Cualquier otra cosa (mezcla, capitalizado, etc.) → escribe NewName tal cual

  Devuelve además el número de reemplazos hechos en MatchCount.

  Necesario para Factuzam: los nombres de columna en código Delphi y SQL
  pueden aparecer en MAYÚSCULAS (DataBinding.FieldName, INSERT/UPDATE)
  o en minúsculas (SELECT en algunas vistas). MySQL en Linux es
  case-sensitive con nombres de columna, así que un 'orden_empresa' que
  no se reemplazara seguía mandándose literal y fallando.
}
function CaseAwareReplace(const Source, OldName, NewName: string;
                          out MatchCount: Integer): string;
var
  Pat:    string;
  Re:     TRegEx;
  Mt:     TMatch;
  SB:     TStringBuilder;
  Pos_:   Integer;
  Matched: string;
  Repl:   string;
  IsAllUpper, IsAllLower: Boolean;
  i:      Integer;
  C:      Char;
begin
  MatchCount := 0;
  Pat := '(?<![A-Za-z0-9_])' + TRegEx.Escape(OldName) + '(?![A-Za-z0-9_])';
  Re  := TRegEx.Create(Pat, [roIgnoreCase]);

  SB := TStringBuilder.Create(Length(Source));
  try
    Pos_ := 1;
    for Mt in Re.Matches(Source) do
    begin
      // Mt.Index es 1-based (TRegEx en Delphi)
      // Copiar texto previo intacto
      if Mt.Index > Pos_ then
        SB.Append(Copy(Source, Pos_, Mt.Index - Pos_));

      Matched := Mt.Value;

      // Determinar el case del match
      IsAllUpper := True;
      IsAllLower := True;
      for i := 1 to Length(Matched) do
      begin
        C := Matched[i];
        if CharInSet(C, ['A'..'Z']) then IsAllLower := False
        else if CharInSet(C, ['a'..'z']) then IsAllUpper := False;
      end;

      if IsAllUpper then
        Repl := UpperCase(NewName)
      else if IsAllLower then
        Repl := LowerCase(NewName)
      else
        Repl := NewName;

      SB.Append(Repl);
      Pos_ := Mt.Index + Mt.Length;
      Inc(MatchCount);
    end;
    // Lo que quede tras el último match
    if Pos_ <= Length(Source) then
      SB.Append(Copy(Source, Pos_, MaxInt));
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TProjectScanner.ApplyReplacements(AStats: TFileChangeList);
var
  Files:    TArray<string>;
  F:        string;
  Original, Modified: string;
  Pair:     TPlanPair;
  Replacements: Integer;
  MatchCount: Integer;
  Stat:     TFileChangeStat;
  BackupPath: string;
  Bytes:    TBytes;
  DetectedEnc: TEncoding;
  HasBOM:   Boolean;
  BOMSize:  Integer;
  PreambleBOM: TBytes;
  NewBuf:   TBytes;
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
    DetectedEnc := nil;
    try
      // Leer como bytes y detectar la codificación a partir del BOM o
      // del contenido. Esto es CRÍTICO en .dfm: si el archivo está en
      // UTF-8 con BOM y lo reescribimos sin BOM, RLINK32 no entiende
      // los caracteres > 0x7F y falla con "Unsupported 16bit resource".
      Bytes := TFile.ReadAllBytes(F);

      // Detectar BOM
      HasBOM  := False;
      BOMSize := 0;
      if (Length(Bytes) >= 3)
         and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
      begin
        DetectedEnc := TEncoding.UTF8;
        HasBOM := True;
        BOMSize := 3;
      end
      else if (Length(Bytes) >= 2)
              and (Bytes[0] = $FF) and (Bytes[1] = $FE) then
      begin
        DetectedEnc := TEncoding.Unicode;  // UTF-16 LE
        HasBOM := True;
        BOMSize := 2;
      end
      else if (Length(Bytes) >= 2)
              and (Bytes[0] = $FE) and (Bytes[1] = $FF) then
      begin
        DetectedEnc := TEncoding.BigEndianUnicode;
        HasBOM := True;
        BOMSize := 2;
      end
      else
      begin
        // Sin BOM: probar UTF-8. Si la decodificación produce caracteres
        // de reemplazo (U+FFFD), significa que había bytes inválidos UTF-8;
        // entonces tratamos el archivo como ANSI (Windows-1252).
        try
          Original := TEncoding.UTF8.GetString(Bytes);
          if Pos(#$FFFD, Original) > 0 then
            DetectedEnc := TEncoding.ANSI
          else
            DetectedEnc := TEncoding.UTF8;
        except
          DetectedEnc := TEncoding.ANSI;
        end;
      end;

      // Decodificar el contenido (saltando el BOM si lo hay)
      if HasBOM then
        Original := DetectedEnc.GetString(Bytes, BOMSize, Length(Bytes) - BOMSize)
      else
        Original := DetectedEnc.GetString(Bytes);
    except
      on E: Exception do
      begin
        Log(Format('[ERROR] Lectura %s: %s', [F, E.Message]));
        Continue;
      end;
    end;

    // Para .dfm: unimos las cadenas continuadas con + antes de buscar.
    // Esto convierte 'FOO_EM' + 'PRESA' en 'FOO_EMPRESA' y evita que un
    // nombre cortado en mitad por el formateo de Delphi se quede sin
    // renombrar. En .pas NO lo hacemos: ahí la concatenación con + suele
    // ser semántica del programador.
    if SameText(ExtractFileExt(F), '.dfm') then
      Modified := JoinPascalStringContinuations(Original)
    else
      Modified := Original;

    Replacements := 0;

    // Aplicamos los reemplazos del plan, ordenados de más largo a más corto.
    // CaseAwareReplace hace case-insensitive y preserva el case del match
    // (UPPER -> UPPER, lower -> lower, mixed -> NewName tal cual).
    for Pair in FRenamePlan do
    begin
      Modified := CaseAwareReplace(Modified, Pair.OldName, Pair.NewName, MatchCount);
      Inc(Replacements, MatchCount);
    end;

    // Para .dfm: tras unir y reemplazar, repartimos las cadenas largas en
    // trozos del estilo Delphi ('foo' + 'bar' + 'baz') porque RLINK32 falla
    // con líneas DFM que superan los ~4096 chars. Lo dejamos en chunks de
    // 200 chars para que el resultado sea legible y compatible.
    if SameText(ExtractFileExt(F), '.dfm') then
      Modified := RewrapLongDfmStrings(Modified, 200);

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
        // Escribimos preservando la codificación detectada Y el BOM original.
        // Esto es CRÍTICO para .dfm con caracteres acentuados: RLINK32 NO
        // acepta UTF-8 sin BOM en .dfm.

        // Salvaguarda extra: si es .dfm UTF-8 SIN BOM detectado, forzar
        // que se escriba CON BOM. RLINK32 falla con UTF-8 sin BOM cuando
        // el .dfm contiene caracteres > 0x7F (acentos, eñes...).
        if SameText(ExtractFileExt(F), '.dfm')
           and (DetectedEnc = TEncoding.UTF8) and (not HasBOM) then
          HasBOM := True;

        // Codificar el contenido. Si la codificación detectada NO puede
        // representar algún carácter Unicode (caso típico: detectamos ANSI
        // pero el contenido tiene caracteres especiales que CP1252 no soporta),
        // caemos a UTF-8 con BOM, que es seguro para cualquier contenido.
        try
          Bytes := DetectedEnc.GetBytes(Modified);
        except
          on E: Exception do
          begin
            Log(Format('  [INFO] %s no se puede guardar en %s; convertido a UTF-8 BOM (%s)',
              [ExtractFileName(F), DetectedEnc.EncodingName, E.Message]));
            DetectedEnc := TEncoding.UTF8;
            HasBOM      := True;
            Bytes       := DetectedEnc.GetBytes(Modified);
          end;
        end;

        if HasBOM then
        begin
          PreambleBOM := DetectedEnc.GetPreamble;
          // Concatenar BOM + Bytes en un buffer nuevo para evitar overlaps
          if Length(PreambleBOM) > 0 then
          begin
            SetLength(NewBuf, Length(PreambleBOM) + Length(Bytes));
            Move(PreambleBOM[0], NewBuf[0], Length(PreambleBOM));
            if Length(Bytes) > 0 then
              Move(Bytes[0], NewBuf[Length(PreambleBOM)], Length(Bytes));
            Bytes := NewBuf;
          end;
        end;
        TFile.WriteAllBytes(F, Bytes);

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
