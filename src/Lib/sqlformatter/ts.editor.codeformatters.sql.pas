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
  FormattedSQL: string;
begin
  Result := AString;
  if Trim(AString) = '' then Exit;

  SS := TStringStream.Create(AString, TEncoding.UTF8);
  LR := TStreamLineReader.Create(SS);
  S  := TSQLScanner.Create(LR);
  P  := TSQLParser.Create(S);

  try
    try
      S.Options := [soBackslashEscapes, soBackQuoteIdentifier];
      FormattedSQL := '';

      // Bucle para parsear y formatear TODOS los comandos del script
      repeat
        E := P.Parse; // Leemos un comando

        if Assigned(E) then
        begin
          // Si ya hay comandos acumulados, le ponemos un punto y coma y salto de línea
          if FormattedSQL <> '' then
            FormattedSQL := FormattedSQL + ';' + sLineBreak + sLineBreak;

          // Acumulamos el comando formateado
          FormattedSQL := FormattedSQL + E.GetAsSQL([
            sfoLowercaseKeyword, sfoOneFieldPerLine, sfoIndentFields,
            sfoOneTablePerLine, sfoIndentTables, sfoWhereOnSeparateLine,
            sfoIndentWhere // (Pon aquí las opciones que usabas)
          ]);

          E.Free; // Importante: liberar la memoria del nodo que ya hemos usado
        end;
      until (E = nil); // Repetimos hasta que el parser no devuelva nada (fin del texto)

      // Si logramos formatear algo, le añadimos el punto y coma final
      if FormattedSQL <> '' then
        Result := FormattedSQL + ';';

    except
      on Ex: Exception do
      begin
        // Si CUALQUIER comando del bloque da error, devolvemos el texto original
        // intacto con el comentario de error arriba para no perder código.
        Result := '/* ERROR DEL PARSER: ' + Ex.Message + ' */' + sLineBreak + AString;
      end;
    end;
  finally
    P.Free;
    S.Free;
    LR.Free;
    SS.Free;
  end;
end;

end.
