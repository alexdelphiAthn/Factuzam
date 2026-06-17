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
function LeerFormatoDocumentoEmpresa(const ACodigoEmpresa: string): string;
function FormatearDocumentoEmpresa(const ACodigoEmpresa, ASerie,
  ANumero: string): string;

implementation

uses
  System.SysUtils, Uni, inLibGlobalVar;

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

function BuscarCodigoEmpresa(ADataSet: TDataSet): string;
const
  CAMPOS_EMPRESA: array[0..7] of string = (
    'CODIGO_EMP_EMP',
    'CODIGO_EMP_FAC',
    'CODIGO_EMP_ALBC',
    'CODIGO_EMP_DEVC',
    'CODIGO_EMP_SES',
    'CODIGO_EMP_PEDC',
    'CODIGO_EMP_PED',
    'CODIGO_EMP_INV'
  );
var
  i: Integer;
begin
  Result := '';
  if ADataSet <> nil then
  begin
    i := Low(CAMPOS_EMPRESA);
    while (i <= High(CAMPOS_EMPRESA)) and (Result = '') do
    begin
      Result := CampoTexto(ADataSet, CAMPOS_EMPRESA[i]);
      Inc(i);
    end;
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
  sCodigoEmpresa: string;
  sFormato: string;
begin
  sFormato := CampoTexto(ADataSet, ACampoFormato);
  if sFormato = '' then
  begin
    sCodigoEmpresa := BuscarCodigoEmpresa(ADataSet);
    sFormato := LeerFormatoDocumentoEmpresa(sCodigoEmpresa);
  end;
  Result := FormatearDocumento(sFormato, CampoTexto(ADataSet, ACampoSerie),
    CampoTexto(ADataSet, ACampoNumero));
end;

function LeerFormatoDocumentoEmpresa(const ACodigoEmpresa: string): string;
var
  Qry: TUniQuery;
begin
  Result := FORMATO_DOCUMENTO_DEFECTO;
  if Trim(ACodigoEmpresa) <> '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      try
        Qry.Connection := oConn;
        Qry.SQL.Text :=
          'SELECT FORMATO_DOCUMENTO_EMP ' +
          '  FROM fza_empresas ' +
          ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
        Qry.ParamByName('CODIGO_EMP').AsString := ACodigoEmpresa;
        Qry.Open;
        if not Qry.Eof then
        begin
          if Trim(Qry.FieldByName('FORMATO_DOCUMENTO_EMP').AsString) <> '' then
            Result := Qry.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
        end;
      except
        Result := FORMATO_DOCUMENTO_DEFECTO;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function FormatearDocumentoEmpresa(const ACodigoEmpresa, ASerie,
  ANumero: string): string;
begin
  Result := FormatearDocumento(LeerFormatoDocumentoEmpresa(ACodigoEmpresa),
    ASerie, ANumero);
end;

end.
