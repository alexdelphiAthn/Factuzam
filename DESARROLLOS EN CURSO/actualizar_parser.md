¡Excelente decisión! Ampliar el parser nativo es la mejor solución a largo plazo, ya que las CTEs (Common Table Expressions o cláusula `WITH`) son un estándar muy utilizado en SQL moderno.

Para lograrlo, necesitamos hacer modificaciones en dos de tus archivos: el Árbol Sintáctico (AST) para que pueda almacenar la estructura en memoria, y el Parser para que sepa cómo leer los tokens.

Sigue estos dos pasos:

### 1. Ampliar el Árbol Sintáctico (`ts.Core.SQLTree.pas`)

Primero debemos crear una clase que represente una CTE individual (ej. `unidades AS (SELECT...)`) y luego añadir una lista de estas CTEs a la sentencia `SELECT` general[cite: 3].

**En la sección `interface`**:
Busca la declaración de `TSQLSelectStatement` y añade la declaración de la nueva clase justo encima, así como la propiedad en el Select[cite: 3]:

```pascal
  { TSQLCommonTableExpression (CTE para soportar WITH) }
  TSQLCommonTableExpression = class(TSQLElement)
  private
    FName: TSQLIdentifierName;
    FFields: TSQLElementList;
    FSelect: TSQLSelectStatement;
  public
    constructor Create(AParent: TSQLElement); override;
    destructor Destroy; override;
    function GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType; override;
    property Name: TSQLIdentifierName read FName write FName;
    property Fields: TSQLElementList read FFields;
    property Select: TSQLSelectStatement read FSelect write FSelect;
  end;

  { TSQLSelectStatement }
  TSQLSelectStatement = class(TSQLDMLStatement)
  private
    FWithClause: TSQLElementList; // <-- NUEVO
    // ... resto de variables privadas originales ...
  public
    // ... constructores y propiedades originales ...
    property WithClause: TSQLElementList read FWithClause write FWithClause; // <-- NUEVO
  end;
```

**En la sección `implementation`**:
Añade la implementación de la nueva clase CTE y actualiza la creación/destrucción y formateo del `TSQLSelectStatement`[cite: 3]:

```pascal
{ TSQLCommonTableExpression }

constructor TSQLCommonTableExpression.Create(AParent: TSQLElement);
begin
  inherited Create(AParent);
  FFields := TSQLElementList.Create(True);
end;

destructor TSQLCommonTableExpression.Destroy;
begin
  FreeAndNil(FName);
  FreeAndNil(FFields);
  // Nota: No liberamos FSelect aquí si le pasamos AParent=Self durante la creación, 
  // pero para asegurar la limpieza manual:
  FreeAndNil(FSelect); 
  inherited Destroy;
end;

function TSQLCommonTableExpression.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
var
  I: Integer;
  S: string;
begin
  Result := '';
  if Assigned(FName) then
    Result := FName.GetAsSQL(Options, AIndent);

  if Assigned(FFields) and (FFields.Count > 0) then
  begin
    S := '';
    for I := 0 to FFields.Count - 1 do
    begin
      if S <> '' then S := S + ', ';
      S := S + FFields[I].GetAsSQL(Options, AIndent);
    end;
    Result := Result + '(' + S + ')';
  end;

  Result := Result + SQLKeyWord(' AS ', Options) + '(' + sLineBreak;
  if Assigned(FSelect) then
    Result := Result + FSelect.GetAsSQL(Options, AIndent + 2);
  Result := Result + sLineBreak + ')';
end;

{ TSQLSelectStatement - Modificaciones }

// Busca TSQLSelectStatement.Create y añade la creación de la lista:
constructor TSQLSelectStatement.Create(AParent: TSQLElement);
begin
  inherited Create(AParent);
  // ...
  FWithClause := TSQLElementList.Create(True); // <-- NUEVO
end;

// Busca TSQLSelectStatement.Destroy y libera la lista:
destructor TSQLSelectStatement.Destroy;
begin
  FreeAndNil(FWithClause); // <-- NUEVO
  // ... resto de FreeAndNil ...
end;

// En TSQLSelectStatement.GetAsSQL, justo al inicio añade la generación del WITH:
function TSQLSelectStatement.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
var
  NewLinePending: Boolean;
  I: Integer; // Añadir variable para el bucle
  // ...
begin
  Result := '';

  // --- INICIO NUEVO ---
  if Assigned(FWithClause) and (FWithClause.Count > 0) then
  begin
    Result := Result + SQLKeyWord('WITH ', Options);
    for I := 0 to FWithClause.Count - 1 do
    begin
      if I > 0 then Result := Result + ', ' + sLineBreak;
      Result := Result + FWithClause[I].GetAsSQL(Options, AIndent);
    end;
    Result := Result + sLineBreak;
  end;
  // --- FIN NUEVO ---

  Result := Result + SQLKeyWord('SELECT', Options); // Continúa el código original
  // ...
```

---

### 2. Modificar el Parser (`ts.Core.SQLParser.pas`)

Ahora le enseñaremos al parser a leer los tokens cuando se tope con un `WITH`[cite: 1]. 

Busca la función `ParseSelectStatement` y modifícala para que intercepte y construya el `WITH` justo antes del `SELECT`[cite: 1]:

```pascal
function TSQLParser.ParseSelectStatement(AParent: TSQLElement;
  Flags : TSelectFlags = []): TSQLSelectStatement;
var
  CTE: TSQLCommonTableExpression; // <-- Añadir variable
begin
  Result := TSQLSelectStatement(CreateElement(TSQLSelectStatement, AParent));
  try
    // --- INICIO SOPORTE WITH ---
    if CurrentToken = tsqlWith then
    begin
      GetNextToken; // Consumir palabra 'WITH'
      repeat
        CTE := TSQLCommonTableExpression(CreateElement(TSQLCommonTableExpression, Result));
        Result.WithClause.Add(CTE);

        Expect(tsqlIdentifier); // Nombre de la CTE (ej. "unidades")
        CTE.Name := CreateIdentifier(CTE, CurrentTokenString);
        GetNextToken;

        // ¿Tiene lista de campos explícitos? Ej: CTE (campo1, campo2) AS ...
        if CurrentToken = tsqlBraceOpen then
        begin
          GetNextToken;
          ParseIdentifierList(CTE, CTE.Fields); // Esto ya consume el cierre ')'
        end;

        Consume(tsqlAs);
        Consume(tsqlBraceOpen);
        CTE.Select := ParseSelectStatement(CTE, [sfSingleTon]); // Parsear consulta interna
        Consume(tsqlBraceClose);

        // Si hay una coma, viene otra CTE (ej. "WITH cte1 AS (...), cte2 AS (...)")
        if CurrentToken = tsqlComma then
          GetNextToken
        else
          Break;
      until False;
    end;
    // --- FIN SOPORTE WITH ---

    // On entry, we're on the SELECT keyword
    Expect(tsqlSelect); 
    
    // ... resto del código original que procesa TransactionName, Fields, etc ...
```

Finalmente, un pequeño ajuste en la función `Parse` principal (cerca de la línea 1935 en el original). El parser debe saber que una consulta de máximo nivel puede empezar tanto por `SELECT` como por `WITH`[cite: 1]:

Busca este bloque:
```pascal
  case CurrentToken of
    tsqlSelect :
      Result := ParseSelectStatement(nil, []);
    tsqlUpdate :
```

Y cámbialo a:
```pascal
  case CurrentToken of
    tsqlSelect, tsqlWith :  // <-- AÑADIR tsqlWith
      Result := ParseSelectStatement(nil, []);
    tsqlUpdate :
```

### ¿Por qué funcionará esto?
Al añadirlo de esta manera, cualquier sentencia `CREATE VIEW` (la cual llama a `ParseSelectStatement`) también tolerará automáticamente sentencias que empiecen por `WITH` en lugar de sólo por `SELECT`. El árbol de memoria procesará las CTE recursivamente. No tendrás que cambiar el formato original de tu consulta de la base de datos nunca más.