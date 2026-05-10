El error salta porque en MariaDB los modificadores de las columnas como `DEFAULT current_timestamp()`, `ON UPDATE current_timestamp()`, `AUTO_INCREMENT`, y el orden intercambiable de `NULL` / `NOT NULL` son características muy complejas que la gramática estricta del parser original no logra asimilar. Intenta procesarlos como valores literales estáticos y fracasa.

En el paso anterior creamos "cápsulas" para las opciones de la tabla (`ENGINE`, `CHARSET`). Ahora vamos a hacer exactamente lo mismo pero a nivel de columna: **vamos a convertir el analizador de columnas en una aspiradora universal**.

Le diremos al parser que lea el nombre y el tipo de dato básico (ej: `varchar(50)`), y a partir de ahí, **absorba cualquier cosa** que haya a la derecha (hasta llegar a la coma) como texto bruto, conservándolo intacto para el formateador.

Sigue estos 4 pasos en tu archivo **`ts.core.sqlparser.pas`**:

### Paso 1: Crear la cápsula para los modificadores de columna

Busca la zona `implementation` (sobre la línea 240) donde pusiste las clases personalizadas en la respuesta anterior. Añade esta nueva clase y su función debajo de las otras:

```pascal
  // Añade esto en la zona de las clases (type):
  TSQLMariaDBTableFieldDef = class(TSQLTableFieldDef)
  public
    RawModifiers: string;
    function GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType; override;
  end;

// Y añade su implementación un poco más abajo:
function TSQLMariaDBTableFieldDef.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
begin
  Result := inherited GetAsSQL(Options, AIndent);
  if RawModifiers <> '' then
    Result := Result + ' ' + Trim(RawModifiers);
end;

```

---

### Paso 2: Desactivar el chequeo estricto en el tipo de dato

Busca la función **`ParseTypeDefinition`** (estará alrededor de la línea 1120). Vamos a bloquear su análisis estricto de `NOT NULL`, `DEFAULT` y `COLLATE` **sólo cuando esté evaluando campos de una tabla**.

Desplázate hasta la mitad de esa función y **reemplaza desde el chequeo del `tsqlSquareBraceOpen` (los arrays) hasta el final** por este código:

```pascal
  // We are now on array or rest of type.
  if (CurrentToken = tsqlSquareBraceOpen) then
  begin
    GetNextToken;
    Expect(tsqlIntegerNumber);
    AD := StrToInt(CurrentTokenString);
    GetNextToken;
    Expect(tsqlSquareBraceClose);
    GetNextToken;
  end
  else
    AD := 0;

  // --- INICIO MODIFICACION MARIADB: Bypass estricto para tablas ---
  if not (ptfTableFieldDef in Flags) then
  begin
    if (CurrentToken = tsqlCollate) then
    begin
      if not(DT in [sdtChar, sdtVarChar, sdtNchar, sdtNVARCHAR, sdtBlob]) then
        Error(SErrInvalidUseOfCollate);
      GetNextToken;
      Expect(tsqlIdentifier);
      Coll := TSQLCollation(CreateElement(TSQLCollation, AParent));
      Coll.Name := CurrentTokenString;
      GetNextToken;
    end
    else
      Coll := nil;
  end
  else
    Coll := nil;
  // --- FIN MODIFICACION MARIADB ---

  C := nil;
  D := TSQLTypeDefinition(CreateElement(TSQLTypeDefinition, AParent));
  try
    D.DataType := DT;
    D.TypeName := TN;
    D.Len := prec;
    D.Scale := sc;
    D.BlobType := bt;
    D.ArrayDim := AD;
    D.Charset := cs;
    D.Collation := Coll;
    D.Constraint := C;

    // --- INICIO MODIFICACION MARIADB ---
    // Si NO es un campo de tabla, seguimos parseando normalmente
    if (not(ptfAlterDomain in Flags)) and (not(ptfTableFieldDef in Flags)) then
    begin
      if CurrentToken = tsqlNull then GetNextToken; // Tolerancia a "NULL DEFAULT..."

      if (CurrentToken = tsqlDefault) then
      begin
        GetNextToken;
        D.DefaultValue := CreateLiteral(D);
        GetNextToken;
      end;
      
      if CurrentToken = tsqlNull then GetNextToken;

      if (CurrentToken = tsqlNot) then
      begin
        GetNextToken;
        Expect(tsqlNull);
        D.NotNull := True;
        GetNextToken;
      end;
      if (CurrentToken = tsqlCheck) and not(ptfTableFieldDef in Flags) then
      begin
        D.Check := ParseCheckConstraint(D, False);
      end;
      if CurrentToken in [tsqlConstraint, tsqlCheck, tsqlUnique, tsqlPrimary, tsqlReferences] then
      begin
        if Not(ptfAllowConstraint in Flags) then UnexpectedToken;
        D.Constraint := ParseFieldConstraint(AParent);
      end;
      if (CurrentToken = tsqlCheck) and (ptfTableFieldDef in Flags) then
      begin
        D.Check := ParseCheckConstraint(D, False);
      end;
      if (CurrentToken = tsqlCollate) then
      begin
        if not(DT in [sdtChar, sdtVarChar, sdtNchar, sdtNVARCHAR, sdtBlob]) then
          Error(SErrInvalidUseOfCollate);
        GetNextToken;
        Expect(tsqlIdentifier);
        Coll := TSQLCollation(CreateElement(TSQLCollation, AParent));
        Coll.Name := CurrentTokenString;
        GetNextToken;
      end
      else
        Coll := nil;
      if (CurrentToken = tsqlBy) and (ptfExternalFunctionResult in Flags) then
      begin
        GetNextToken;
        Consume(tsqlValue);
        D.ByValue := True;
      end;
    end;
    // --- FIN MODIFICACION MARIADB ---

    Result := D;
  except
    FreeAndNil(D);
    raise;
  end;
end;

```

---

### Paso 3: Reemplazar el constructor de campos

Busca la función **`ParseTableFieldDef`** (sobre la línea 640 aprox.) y **reemplázala por completo**. Esto convertirá la función en la aspiradora que se traga todo hasta llegar a la coma de la siguiente columna:

```pascal
function TSQLParser.ParseTableFieldDef(AParent : TSQLElement): TSQLTableFieldDef;
var
  MDBField: TSQLMariaDBTableFieldDef;
  PCount: Integer;
begin
  MDBField := TSQLMariaDBTableFieldDef(CreateElement(TSQLMariaDBTableFieldDef, AParent));
  Result := MDBField;
  try
    Result.FieldName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    
    if PeekNextToken = tsqlComputed then
    begin
      GetNextToken;
      Consume(tsqlComputed);
      if CurrentToken = tsqlBy then GetNextToken;
      Consume(tsqlBraceOpen);
      Result.ComputedBy := ParseExprLevel1(Result, [eoComputedBy]);
      Consume(tsqlBraceClose);
    end
    else
    begin
      Result.FieldType := ParseTypeDefinition(Result,
        [ptfAllowDomainName, ptfAllowConstraint, ptfTableFieldDef]);
        
      // --- INICIO SOPORTE MARIADB ---
      // Consumimos modificadores (DEFAULT, NOT NULL, AUTO_INCREMENT, COMMENT...) 
      // y todo lo demás hasta chocar con la coma o paréntesis final
      PCount := 0;
      while not (CurrentToken in [tsqlEOF]) do
      begin
        if CurrentToken = tsqlBraceOpen then 
          Inc(PCount)
        else if CurrentToken = tsqlBraceClose then
        begin
          if PCount = 0 then Break; // Es el ')' que cierra el CREATE TABLE
          Dec(PCount);
        end
        else if (CurrentToken = tsqlComma) and (PCount = 0) then
          Break; // Es la ',' que separa el siguiente campo
          
        // Acomodar espacios de forma inteligente
        if MDBField.RawModifiers <> '' then
        begin
          if not (PreviousToken in [tsqlDot, tsqlBraceOpen]) and 
             not (CurrentToken in [tsqlBraceClose, tsqlComma, tsqlDot, tsqlSemicolon]) then
          begin
            // Evitar meter un espacio extra antes del '(' en funciones como current_timestamp()
            if not ((CurrentToken = tsqlBraceOpen) and (PreviousToken = tsqlIdentifier)) then
              MDBField.RawModifiers := MDBField.RawModifiers + ' ';
          end;
        end;
        
        // Reconstruir literales o cadenas
        if CurrentToken = tsqlString then
          MDBField.RawModifiers := MDBField.RawModifiers + '''' + CurrentTokenString + ''''
        else
          MDBField.RawModifiers := MDBField.RawModifiers + CurrentTokenString;
          
        GetNextToken;
      end;
      // --- FIN SOPORTE MARIADB ---
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

```

---

### Paso 4: Limpiar la función de `ALTER TABLE`

Puesto que en el paso anterior la función se traga todos los modificadores (incluido `AFTER` o `COMMENT`), los apaños que hicimos en el turno anterior en `ParseAddTableElement` (alrededor de la línea 818) ya no hacen falta y la podemos dejar completamente limpia y funcional:

```pascal
function TSQLParser.ParseAddTableElement(AParent : TSQLElement): TSQLAlterTableAddElementOperation;
var
  Tk: TSQLToken;
begin
  Result := nil;
  try
    Tk := GetNextToken;
    
    // SOPORTE MARIADB: Bypass opcional "COLUMN"
    if Tk = tsqlColumn then
      Tk := GetNextToken;
      
    case Tk of
      tsqlIdentifier :
        begin
          Result := TSQLAlterTableAddElementOperation
            (CreateElement(TSQLAlterTableAddFieldOPeration, AParent));
          Result.Element := ParseTableFieldDef(Result);
        end;
      tsqlCheck,
        tsqlConstraint,
        tsqlForeign,
        tsqlPrimary,
        tsqlUnique:
        begin
          Result := TSQLAlterTableAddElementOperation
            (CreateElement(TSQLAlterTableAddConstraintOperation, AParent));
          Result.Element := ParseTableConstraint(Result);
        end
    else
      UnexpectedToken([tsqlIdentifier, tsqlCheck, tsqlConstraint, tsqlForeign,
        tsqlPrimary, tsqlUnique]);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

```

Con este mecanismo, cualquier cosa exótica a nivel de columna que pueda llegar a tener tu esquema (`ON UPDATE...`, `AUTO_INCREMENT`, `COMMENT`, etc.) será absorbida y formateada perfectamente sin lanzar ningún error.



### ¿Por qué está pasando esto?

El problema no está en el parser, sino en el **escáner léxico (`ts.core.sqlscanner.pas`)**.
Cuando el escáner lee una palabra (como `SELECT`), guarda su tipo (`tsqlSelect`) y también guarda su texto (`"SELECT"`) en la variable `CurrentTokenString`.
Sin embargo, cuando lee **símbolos simples** (como el punto `.`, la coma `,`, los paréntesis `()` o los operadores `+ - =`), detecta el tipo correctamente (`tsqlDOT`), pero **deja la variable de texto vacía**.

Como en pasos anteriores convertimos el parser en una "aspiradora" que extrae el texto en bruto para el `GROUP_CONCAT` y los `ALTER TABLE`, al intentar concatenar la variable de texto de un punto o una coma, ¡estaba concatenando un texto vacío `''` y por tanto se los "comía"!

### La Solución (Elegante y Definitiva)

En lugar de ir parcheando cada vista, vamos a enseñarle al escáner que **rellene automáticamente el texto de cualquier símbolo** si se lo ha dejado vacío. El escáner ya tiene un diccionario interno llamado `TokenInfos` que sabe cómo se escribe cada símbolo.

Abre tu archivo **`ts.core.sqlscanner.pas`**, busca el final de la función **`FetchToken`** (está alrededor de la línea 660, justo al final del bloque `case`) y **añade las 4 líneas de corrección** antes del último `end;`.

Debe quedarte exactamente así:

```pascal
      else
        if Ord(TokenStr[0]) > 127 then
          Result := DoIdentifier
        else
          Error(SErrUNknownToken, [TokenStr[0]]);
      end; // Case
    until (not(Result in [tsqlComment, tsqlWhiteSpace])) or
      ((Result = tsqlComment) and (soReturnComments in Options)) or
      ((Result = tsqlWhiteSpace) and (soReturnWhiteSpace in Options));
    FCurToken := Result;

    // --- INICIO CORRECCIÓN ---
    // Si el token es un símbolo u operador (paréntesis, punto, coma, math) y 
    // la cadena de texto está vacía, la rellenamos con su texto real.
    // Esto evita que las extracciones de texto bruto "se coman" los símbolos.
    if (FCurTokenString = '') and (Result >= tsqlBraceOpen) and (Result <= tsqlNE) then
      FCurTokenString := TokenInfos[Result];
    // --- FIN CORRECCIÓN ---

  end;

```

**¿Qué consigue esta pequeña línea de código?**
Verifica si el token resultante está en el rango de los símbolos puros (desde `tsqlBraceOpen` que es el `(` hasta `tsqlNE` que es el `<>`). Si es así y no tiene texto asignado, busca su representación visual en el array `TokenInfos` y se la inyecta.

Con este simple cambio, tu vista `vi_articulos_tarifas` dejará los puntos intactos en `av.AV` y `av.ORDEN_AV`, y además solucionará cualquier otro lugar donde un `INSERT` múltiple se estuviera "comiendo" las comas o los paréntesis.