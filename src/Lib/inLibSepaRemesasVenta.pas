{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSepaRemesasVenta                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación de órdenes SEPA 19.14 para remesas de venta.                  }
{******************************************************************************}
unit inLibSepaRemesasVenta;

interface

uses
  System.SysUtils, Data.DB, Uni;

type
  TResultadoSepaRemesaVenta = record
    Archivo: string;
    NumCobros: Integer;
    Total: Currency;
  end;

function GenerarSepaRemesaVenta(AConn: TUniConnection; const ASerie,
  ANumero, AArchivo: string): TResultadoSepaRemesaVenta;

implementation

uses
  inLibDocumentoFiscal, inLibIBAN, uDJMSepa1914XML;

function SoloAlfanumerico(const AValor: string): string;
var
  i: Integer;
  sValor: string;
begin
  Result := '';
  sValor := UpperCase(Trim(AValor));
  for i := 1 to Length(sValor) do
  begin
    if CharInSet(sValor[i], ['A'..'Z', '0'..'9']) then
      Result := Result + sValor[i];
  end;
end;

function ValorCampoStr(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := Trim(oCampo.AsString);
end;

function ValorCampoFecha(ADataSet: TDataSet; const ACampo: string;
  ADefecto: TDateTime): TDateTime;
var
  oCampo: TField;
begin
  Result := ADefecto;
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsDateTime;
end;

function NormalizarIban(const AIban, ATexto: string): string;
begin
  Result := UpperCase(TIBAN.FormatearElectronico(AIban));
  if Result = '' then
    raise Exception.Create(ATexto + ' sin IBAN.');
  if not TIBAN.ValidarIBAN(Result) then
    raise Exception.Create(ATexto + ' con IBAN no válido: ' + Result);
end;

function CadenaSepaADigitos(const AValor: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := AValor[i];
    if CharInSet(c, ['0'..'9']) then
      Result := Result + c
    else if CharInSet(c, ['A'..'Z']) then
      Result := Result + IntToStr(Ord(c) - Ord('A') + 10);
  end;
end;

function Modulo97(const AValor: string): Integer;
var
  sValor: string;
begin
  Result := 0;
  sValor := AValor;
  while sValor <> '' do
  begin
    Result := StrToIntDef(IntToStr(Result) + Copy(sValor, 1, 6), 0) mod 97;
    Delete(sValor, 1, 6);
  end;
end;

function DosDigitos(AValor: Integer): string;
begin
  Result := IntToStr(AValor);
  while Length(Result) < 2 do
    Result := '0' + Result;
end;

function IdentificadorAcreedorEspanol(const ANif: string): string;
var
  iDc: Integer;
  sNif: string;
  sBase: string;
begin
  sNif := LimpiarDocumentoFiscal(ANif);
  if not DocumentoFiscalValido(sNif) then
    raise Exception.Create('NIF de empresa no válido para acreedor SEPA: ' +
      ANif);
  sBase := '000' + sNif + 'ES00';
  iDc := 98 - Modulo97(CadenaSepaADigitos(sBase));
  Result := 'ES' + DosDigitos(iDc) + '000' + sNif;
end;

function CrearConsulta(AConn: TUniConnection): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := AConn;
end;

function CrearIdCobro(AEfecto: TDataSet): string;
begin
  Result := 'REMV-' +
    SoloAlfanumerico(ValorCampoStr(AEfecto, 'SERIE_FAC_EFV')) + '-' +
    SoloAlfanumerico(ValorCampoStr(AEfecto, 'NUMERO_FAC_EFV')) + '-' +
    IntToStr(AEfecto.FieldByName('NUMERO_EFV').AsInteger);
end;

function CrearIdMandato(AEfecto: TDataSet): string;
begin
  Result := 'CLI-' + SoloAlfanumerico(ValorCampoStr(AEfecto,
    'CODIGO_CLI_EFV'));
  if Result = 'CLI-' then
    Result := CrearIdCobro(AEfecto);
end;

function CrearConcepto(AEfecto: TDataSet): string;
begin
  Result := ValorCampoStr(AEfecto, 'REFERENCIA_DOCUMENTO_EFV');
  if Result = '' then
    Result := 'Factura ' + ValorCampoStr(AEfecto, 'SERIE_FAC_EFV') + '/' +
      ValorCampoStr(AEfecto, 'NUMERO_FAC_EFV') + ' efecto ' +
      AEfecto.FieldByName('NUMERO_EFV').AsString;
end;

procedure AbrirCabecera(AQry: TUniQuery; const ASerie, ANumero: string);
begin
  AQry.SQL.Text :=
    'SELECT r.SERIE_REMV, r.NUMERO_REMV, r.FECHA_REMV, ' +
    '       r.FECHA_CARGO_REMV, r.IBAN_REMV, r.CODIGO_EMP_REMV, ' +
    '       emp.RAZON_SOCIAL_EMP, emp.NIF_EMP ' +
    '  FROM fza_remesas_venta r ' +
    '  LEFT JOIN fza_empresas emp ' +
    '    ON emp.CODIGO_EMP_EMP = r.CODIGO_EMP_REMV ' +
    ' WHERE r.SERIE_REMV = :serie ' +
    '   AND r.NUMERO_REMV = :numero';
  AQry.ParamByName('serie').AsString := ASerie;
  AQry.ParamByName('numero').AsString := ANumero;
  AQry.Open;
end;

procedure AbrirBanco(AQry: TUniQuery; const ACodigoEmp, AIban: string);
begin
  AQry.SQL.Text :=
    'SELECT COALESCE(NULLIF(BIC_EMPBAN, ''''), ' +
    '                NULLIF(BIC_BAN_VIEW_EMPBAN, ''''), '''') AS BIC ' +
    '  FROM vi_empresas_bancos ' +
    ' WHERE CODIGO_EMP_EMPBAN = :empresa ' +
    '   AND IBAN_EMPBAN = :iban ' +
    ' LIMIT 1';
  AQry.ParamByName('empresa').AsString := ACodigoEmp;
  AQry.ParamByName('iban').AsString := AIban;
  AQry.Open;
end;

procedure AbrirEfectos(AQry: TUniQuery; const ASerie, ANumero: string);
begin
  AQry.SQL.Text :=
    'SELECT e.SERIE_FAC_EFV, e.NUMERO_FAC_EFV, e.NUMERO_EFV, ' +
    '       e.CODIGO_CLI_EFV, e.FECHA_EMISION_EFV, ' +
    '       COALESCE(NULLIF(e.RAZON_SOCIAL_CLI_EFV, ''''), ' +
    '                cli.RAZON_SOCIAL_CLI, e.CODIGO_CLI_EFV) AS NOMBRE_CLI, ' +
    '       COALESCE(NULLIF(e.IBAN_EFV, ''''), cli.IBAN_CLI) AS IBAN_CLI, ' +
    '       COALESCE(e.IMPORTE_PENDIENTE_EFV, e.IMPORTE_EFV, 0) AS IMPORTE, ' +
    '       e.REFERENCIA_DOCUMENTO_EFV ' +
    '  FROM fza_efectos_venta e ' +
    '  LEFT JOIN fza_clientes cli ' +
    '    ON cli.CODIGO_CLI_CLI = e.CODIGO_CLI_EFV ' +
    ' WHERE e.SERIE_REMV_EFV = :serie ' +
    '   AND e.NUMERO_REMV_EFV = :numero ' +
    '   AND COALESCE(e.IMPORTE_PENDIENTE_EFV, e.IMPORTE_EFV, 0) > 0 ' +
    ' ORDER BY e.FECHA_VENCIMIENTO_EFV, e.SERIE_FAC_EFV, ' +
    '          e.NUMERO_FAC_EFV, e.NUMERO_EFV';
  AQry.ParamByName('serie').AsString := ASerie;
  AQry.ParamByName('numero').AsString := ANumero;
  AQry.Open;
end;

function GenerarSepaRemesaVenta(AConn: TUniConnection; const ASerie,
  ANumero, AArchivo: string): TResultadoSepaRemesaVenta;
var
  bFicheroAbierto: Boolean;
  dFechaCargo: TDateTime;
  dFechaFirma: TDateTime;
  qBanco: TUniQuery;
  qCabecera: TUniQuery;
  qEfectos: TUniQuery;
  oSepa: TDJMNorma1914XML;
  sArchivo: string;
  sBicEmpresa: string;
  sCarpeta: string;
  sCodigoEmp: string;
  sIdAcreedor: string;
  sIbanCliente: string;
  sIbanEmpresa: string;
  sNombreCliente: string;
  sNombreEmpresa: string;
begin
  Result.Archivo := Trim(AArchivo);
  Result.NumCobros := 0;
  Result.Total := 0;
  if AConn = nil then
    raise Exception.Create('No hay conexión para generar la remesa SEPA.');
  sArchivo := Result.Archivo;
  if sArchivo = '' then
    raise Exception.Create('Indica el archivo de salida SEPA.');
  sCarpeta := ExtractFilePath(sArchivo);
  if (sCarpeta <> '') and (not DirectoryExists(sCarpeta)) then
    ForceDirectories(sCarpeta);
  qCabecera := CrearConsulta(AConn);
  qBanco := CrearConsulta(AConn);
  qEfectos := CrearConsulta(AConn);
  oSepa := TDJMNorma1914XML.Create;
  try
    AbrirCabecera(qCabecera, ASerie, ANumero);
    if qCabecera.IsEmpty then
      raise Exception.Create('No se encuentra la remesa de venta.');
    sCodigoEmp := ValorCampoStr(qCabecera, 'CODIGO_EMP_REMV');
    sNombreEmpresa := ValorCampoStr(qCabecera, 'RAZON_SOCIAL_EMP');
    if sNombreEmpresa = '' then
      sNombreEmpresa := sCodigoEmp;
    sIbanEmpresa := NormalizarIban(ValorCampoStr(qCabecera, 'IBAN_REMV'),
      'Banco de cobro de la remesa');
    sIdAcreedor := IdentificadorAcreedorEspanol(ValorCampoStr(qCabecera,
      'NIF_EMP'));
    dFechaCargo := ValorCampoFecha(qCabecera, 'FECHA_CARGO_REMV', 0);
    if dFechaCargo <= 0 then
      raise Exception.Create('La remesa no tiene fecha de cobro.');
    AbrirBanco(qBanco, sCodigoEmp, sIbanEmpresa);
    sBicEmpresa := '';
    if not qBanco.IsEmpty then
      sBicEmpresa := UpperCase(ValorCampoStr(qBanco, 'BIC'));
    oSepa.SetInfoPresentador(Now, sNombreEmpresa, sIdAcreedor, dFechaCargo);
    oSepa.AddOrdenante('REMV-' + SoloAlfanumerico(ASerie) + '-' +
      SoloAlfanumerico(ANumero), sNombreEmpresa, sIbanEmpresa, sBicEmpresa,
      sIdAcreedor);
    AbrirEfectos(qEfectos, ASerie, ANumero);
    while not qEfectos.Eof do
    begin
      sNombreCliente := ValorCampoStr(qEfectos, 'NOMBRE_CLI');
      if sNombreCliente = '' then
        raise Exception.Create('Efecto sin nombre de cliente.');
      sIbanCliente := NormalizarIban(ValorCampoStr(qEfectos, 'IBAN_CLI'),
        'Cliente ' + sNombreCliente);
      dFechaFirma := ValorCampoFecha(qEfectos, 'FECHA_EMISION_EFV',
        ValorCampoFecha(qCabecera, 'FECHA_REMV', Date));
      oSepa.AddCobro(CrearIdCobro(qEfectos),
        qEfectos.FieldByName('IMPORTE').AsCurrency, CrearIdMandato(qEfectos),
        dFechaFirma, '', sNombreCliente, sIbanCliente, CrearConcepto(qEfectos),
        sIbanEmpresa);
      Inc(Result.NumCobros);
      Result.Total := Result.Total + qEfectos.FieldByName('IMPORTE')
        .AsCurrency;
      qEfectos.Next;
    end;
    if Result.NumCobros = 0 then
      raise Exception.Create('La remesa no tiene efectos pendientes.');
    bFicheroAbierto := False;
    try
      oSepa.CreateFile(sArchivo);
      bFicheroAbierto := True;
    finally
      if bFicheroAbierto then
        oSepa.CloseFile;
    end;
  finally
    FreeAndNil(oSepa);
    FreeAndNil(qEfectos);
    FreeAndNil(qBanco);
    FreeAndNil(qCabecera);
  end;
end;

end.
