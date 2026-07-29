{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlValidacion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación estática de SQL configurable y sus parámetros UniDAC.          }
{******************************************************************************}
unit inLibCatalogoSqlValidacion;

interface

uses
  inLibCatalogoSqlIntf;

function ValidarSql(
  const ADefinicion: TDefinicionSql;
  const ASql: string): TResultadoValidacionSql;
function CalcularHuellaSql(const ASql: string): string;

implementation

uses
  System.SysUtils, System.Classes, System.Hash;

function EsInicioIdentificador(ACaracter: Char): Boolean;
begin
  Result := CharInSet(
    ACaracter, ['A'..'Z', 'a'..'z', '_']);
end;

function EsCaracterIdentificador(ACaracter: Char): Boolean;
begin
  Result := EsInicioIdentificador(ACaracter) or
    CharInSet(ACaracter, ['0'..'9']);
end;

function TextoSinLiterales(const ASql: string): string;
var
  bEnLiteral: Boolean;
  iIndice: Integer;
begin
  Result := ASql;
  bEnLiteral := False;
  iIndice := 1;
  while iIndice <= Length(Result) do
  begin
    if Result[iIndice] = '''' then
    begin
      if bEnLiteral and
         (iIndice < Length(Result)) and
         (Result[iIndice + 1] = '''') then
      begin
        Result[iIndice] := ' ';
        Result[iIndice + 1] := ' ';
        Inc(iIndice);
      end
      else
      begin
        bEnLiteral := not bEnLiteral;
        Result[iIndice] := ' ';
      end;
    end
    else if bEnLiteral then
      Result[iIndice] := ' ';
    Inc(iIndice);
  end;
end;

function ExtraerParametros(const ASql: string): TStringList;
var
  iFin: Integer;
  iInicio: Integer;
  iIndice: Integer;
  sSinLiterales: string;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  Result.Sorted := True;
  sSinLiterales := TextoSinLiterales(ASql);
  iIndice := 1;
  while iIndice <= Length(sSinLiterales) do
  begin
    if (sSinLiterales[iIndice] = ':') and
       (iIndice < Length(sSinLiterales)) and
       EsInicioIdentificador(sSinLiterales[iIndice + 1]) then
    begin
      iInicio := iIndice + 1;
      iFin := iInicio;
      while (iFin <= Length(sSinLiterales)) and
            EsCaracterIdentificador(sSinLiterales[iFin]) do
        Inc(iFin);
      Result.Add(
        LowerCase(Copy(sSinLiterales, iInicio, iFin - iInicio)));
      iIndice := iFin;
    end
    else
      Inc(iIndice);
  end;
end;

function ParametrosEsperados(
  const AParametros: string): TStringList;
var
  iIndice: Integer;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  Result.StrictDelimiter := True;
  Result.Delimiter := ',';
  Result.DelimitedText := LowerCase(AParametros);
  for iIndice := Result.Count - 1 downto 0 do
  begin
    Result[iIndice] := Trim(Result[iIndice]);
    if Result[iIndice] = '' then
      Result.Delete(iIndice);
  end;
  Result.Sorted := True;
end;

function NombreTipoSentencia(
  ATipo: TTipoSentenciaSql): string;
begin
  case ATipo of
    tssSelect:
      Result := 'SELECT';
    tssInsert:
      Result := 'INSERT';
    tssUpdate:
      Result := 'UPDATE';
    tssDelete:
      Result := 'DELETE';
    tssCall:
      Result := 'CALL';
  else
    Result := '';
  end;
end;

function PrimerToken(const ASql: string): string;
var
  iFin: Integer;
  iInicio: Integer;
  sTexto: string;
begin
  Result := '';
  sTexto := TrimLeft(ASql);
  iInicio := 1;
  iFin := iInicio;
  while (iFin <= Length(sTexto)) and
        EsCaracterIdentificador(sTexto[iFin]) do
    Inc(iFin);
  if iFin > iInicio then
    Result := UpperCase(
      Copy(sTexto, iInicio, iFin - iInicio));
end;

function ContienePalabra(
  const ATexto, APalabra: string): Boolean;
var
  iFin: Integer;
  iInicio: Integer;
  sTexto: string;
begin
  Result := False;
  sTexto := UpperCase(TextoSinLiterales(ATexto));
  iInicio := 1;
  while (iInicio <= Length(sTexto)) and (not Result) do
  begin
    while (iInicio <= Length(sTexto)) and
          (not EsInicioIdentificador(sTexto[iInicio])) do
      Inc(iInicio);
    iFin := iInicio;
    while (iFin <= Length(sTexto)) and
          EsCaracterIdentificador(sTexto[iFin]) do
      Inc(iFin);
    if iFin > iInicio then
      Result := Copy(
        sTexto, iInicio, iFin - iInicio) = APalabra;
    iInicio := iFin + 1;
  end;
end;

function TieneVariasSentencias(const ASql: string): Boolean;
var
  sTexto: string;
begin
  sTexto := TrimRight(TextoSinLiterales(ASql));
  if (sTexto <> '') and
     (sTexto[Length(sTexto)] = ';') then
    Delete(sTexto, Length(sTexto), 1);
  Result := Pos(';', sTexto) > 0;
end;

function ListasIguales(
  APrimera, ASegunda: TStringList): Boolean;
var
  iIndice: Integer;
begin
  Result := APrimera.Count = ASegunda.Count;
  iIndice := 0;
  while Result and (iIndice < APrimera.Count) do
  begin
    Result := SameText(
      APrimera[iIndice], ASegunda[iIndice]);
    Inc(iIndice);
  end;
end;

function CalcularHuellaSql(const ASql: string): string;
begin
  Result := THashSHA2.GetHashString(ASql);
end;

function ValidarSql(
  const ADefinicion: TDefinicionSql;
  const ASql: string): TResultadoValidacionSql;
var
  oEsperados: TStringList;
  oEncontrados: TStringList;
  sTipoEsperado: string;
begin
  Result.EsValido := False;
  Result.Mensaje := '';
  Result.Huella := CalcularHuellaSql(ASql);
  if Trim(ASql) = '' then
    Result.Mensaje := 'El SQL está vacío.'
  else if TieneVariasSentencias(ASql) then
    Result.Mensaje := 'Solo se admite una sentencia SQL.'
  else if ContienePalabra(ASql, 'DROP') or
          ContienePalabra(ASql, 'ALTER') or
          ContienePalabra(ASql, 'TRUNCATE') then
    Result.Mensaje := 'El SQL contiene una operación DDL no permitida.'
  else
  begin
    sTipoEsperado := NombreTipoSentencia(
      ADefinicion.TipoSentencia);
    if PrimerToken(ASql) <> sTipoEsperado then
      Result.Mensaje := Format(
        'Se esperaba una sentencia %s.', [sTipoEsperado])
    else
    begin
      oEsperados := ParametrosEsperados(
        ADefinicion.Parametros);
      oEncontrados := ExtraerParametros(ASql);
      try
        if ListasIguales(oEsperados, oEncontrados) then
          Result.EsValido := True
        else
          Result.Mensaje := Format(
            'Parámetros esperados [%s], encontrados [%s].',
            [oEsperados.CommaText, oEncontrados.CommaText]);
      finally
        FreeAndNil(oEncontrados);
        FreeAndNil(oEsperados);
      end;
    end;
  end;
end;

end.
