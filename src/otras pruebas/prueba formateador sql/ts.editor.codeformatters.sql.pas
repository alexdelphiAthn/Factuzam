unit ts.Editor.CodeFormatters.SQL;

interface

uses
  System.Classes, System.SysUtils,
  ts.Core.SQLParser,
  ts.Core.SQLScanner,
  ts.Core.SQLTree,
  ts.Editor.CodeFormatters; // Aquí está la interfaz ICodeFormatter

type
  TSQLFormatter = class(TInterfacedObject, ICodeFormatter)
  protected
    // Nota: Hemos quitado FLineReader, FSQLParser, etc. porque ahora
    // se crean localmente dentro de la función Format.
    function Format(const AString: string): string;
  end;

implementation

{ TSQLFormatter }

function TSQLFormatter.Format(const AString: string): string;
var
  SS : TStringStream;
  LR : TStreamLineReader;
  P  : TSQLParser;
  S  : TSQLScanner;
  E  : TSQLElement;
begin
  Result := AString;
  // Si la cadena está vacía, salimos rápido
  if Trim(AString) = '' then Exit;

  // 1. Crear el stream con codificación UTF8 explícita
  SS := TStringStream.Create(AString, TEncoding.UTF8);

  // 2. Crear el lector de líneas (asegúrate que tu ts.Core.SQLScanner tenga la corrección de TStreamReader)
  LR := TStreamLineReader.Create(SS);

  // 3. Crear el Escáner y el Parser
  S  := TSQLScanner.Create(LR);
  P  := TSQLParser.Create(S);

  try
    try
      // Opciones del Scanner
      S.Options := [soBackslashEscapes, soBackQuoteIdentifier];

      // Intentar parsear
      E := P.Parse;
    except
      on Ex: Exception do
      begin
        // Si falla el parseo (SQL inválido), devolvemos el texto original sin tocar
        E := nil;
        Result := AString;
      end;
    end;

    // Si se creó el árbol de elementos (E), formateamos
    if Assigned(E) then
    begin
       // Aquí aplicas tus preferencias de formato definidas en ts.Core.SQLTree
       Result := E.GetAsSQL([
          sfoLowercaseKeyword,
          sfoOneFieldPerLine,
          sfoIndentFields,
          sfoOneTablePerLine,
          sfoIndentTables,
          sfoNoBracketRightJoin,
          sfoWhereOnSeparateLine,
          sfoIndentWhere,
          sfoOneGroupByFieldPerLine,
          sfoIndentGroupByFields,
          sfoHavingOnSeparateLine,
          sfoIndentHaving,
          sfoUnionOnSeparateLine,
          sfoOneOrderByFieldPerLine,
          sfoIndentOrderByFields,
          sfoOneLogicalPerLine,
          sfoListNoSpaceBeforeComma,
          sfoForceAscending
       ], 2); // Indentación de 2 espacios
    end;

  finally
    // Liberar memoria en orden inverso a creación
    if Assigned(E) then E.Free;
    P.Free;
    S.Free;
    LR.Free;
    SS.Free;
  end;
end;

end.
