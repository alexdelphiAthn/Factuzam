unit inLibFormatoDocumento;

interface

uses
  Data.DB;

const
  FORMATO_DOCUMENTO_DEFECTO = 'Serie.NroDocumento';

function FormatearDocumento(const AFormato, ASerie, ANumero: string): string;
function FormatearDocumentoDataSet(ADataSet: TDataSet;
  const ACampoSerie, ACampoNumero: string;
  const ACampoFormato: string = 'FORMATO_DOCUMENTO_EMP'): string;

implementation

uses
  System.SysUtils;

function CampoTexto(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if ADataSet <> nil then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.AsString;
  end;
end;

function TieneTokenDocumento(const AFormato: string): Boolean;
begin
  Result := (Pos('Serie', AFormato) > 0)
    or (Pos('serie', AFormato) > 0)
    or (Pos('SERIE', AFormato) > 0)
    or (Pos('NroDocumento', AFormato) > 0)
    or (Pos('NroDoc', AFormato) > 0)
    or (Pos('NroFactura', AFormato) > 0)
    or (Pos('NumeroDocumento', AFormato) > 0)
    or (Pos('Numero', AFormato) > 0)
    or (Pos('NúmeroDocumento', AFormato) > 0)
    or (Pos('Número', AFormato) > 0);
end;

function ReemplazarTokens(const AFormato, ASerie, ANumero: string): string;
begin
  Result := AFormato;
  Result := StringReplace(Result, 'NroDocumento', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NumeroDocumento', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NúmeroDocumento', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NroFactura', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NroDoc', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Numero', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Número', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Serie', ASerie,
    [rfReplaceAll, rfIgnoreCase]);
end;

function FormatearDocumento(const AFormato, ASerie, ANumero: string): string;
var
  sFormato: string;
  sNumero: string;
  sSerie: string;
begin
  sSerie := Trim(ASerie);
  sNumero := Trim(ANumero);
  if sSerie = '' then
    Result := sNumero
  else
  begin
    if sNumero = '' then
      Result := sSerie
    else
    begin
      sFormato := Trim(AFormato);
      if (sFormato = '') or not TieneTokenDocumento(sFormato) then
        sFormato := FORMATO_DOCUMENTO_DEFECTO;
      Result := ReemplazarTokens(sFormato, sSerie, sNumero);
    end;
  end;
end;

function FormatearDocumentoDataSet(ADataSet: TDataSet;
  const ACampoSerie, ACampoNumero: string;
  const ACampoFormato: string): string;
var
  sFormato: string;
begin
  sFormato := CampoTexto(ADataSet, ACampoFormato);
  Result := FormatearDocumento(sFormato, CampoTexto(ADataSet, ACampoSerie),
    CampoTexto(ADataSet, ACampoNumero));
end;

end.
