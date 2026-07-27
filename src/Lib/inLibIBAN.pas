{******************************************************************************}
{                                                                              }
{  Módulo:       inLibIBAN                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validador y generador de cuentas IBAN.                                    }
{    Cálculo del dígito de control, validación de CCC y formateo en papel.     }
{******************************************************************************}
unit inLibIBAN;

{******************************************************************************}
{* Librería de validación y generación de IBAN                               *}
{*                                                                            *}
{* Esta unidad consolida todas las funcionalidades relacionadas con IBAN:    *}
{* - Validación de IBAN internacional                                        *}
{* - Validación de CCC español                                               *}
{* - Generación de dígitos de control                                        *}
{* - Conversión y formateo de cuentas bancarias                              *}
{******************************************************************************}

interface

uses
  System.Classes, System.SysUtils;

type
  {****************************************************************************}
  {* TIBAN - Clase principal para trabajar con IBAN                           *}
  {****************************************************************************}
  TIBAN = class
  public
    {** Validación **}
    // Valida un IBAN completo (formato internacional)
    class function ValidarIBAN(const IBAN: string;
                               Errores: TStringList = nil): Boolean;
    // Valida un CCC español (con o sin IBAN)
    class function ValidarCCC(const CCC: string;
                              Errores: TStringList = nil): Boolean;

    {** Generación **}
    // Genera el IBAN completo a partir de país y CCC
    class function GenerarIBAN(const Pais, CCC: string): string;
    // Genera el DC (dígito de control) para CCC español
    class function GenerarDC(const Banco, Cuenta: string): string;
    // Calcula el dígito de control del IBAN
    class function CalcularDCIBAN(const Pais, CCC: string): string;

    {** Formateo **}
    // Formatea IBAN para papel (con espacios): "IBAN ES76 1234 5678..."
    class function FormatearPapel(const IBAN: string): string;
    // Formatea IBAN para electrónico (sin espacios): "ES7612345678..."
    class function FormatearElectronico(const IBAN: string): string;

    {** Extracción de componentes **}
    // Extrae el país del IBAN: "ES"
    class function ExtraerPais(const IBAN: string): string;
    // Extrae el DC del IBAN: "76"
    class function ExtraerDCIBAN(const IBAN: string): string;
    // Extrae el CCC del IBAN: "12345678901234567890"
    class function ExtraerCCC(const IBAN: string): string;

    {** Para CCC español **}
    // Descompone CCC español: devuelve Banco(8) + DC(2) + Cuenta(10)
    class function DescomponerCCC(const CCC: string;
                                  out Banco, DC, Cuenta: string): Boolean;
  end;

  {******************************************************************************}
  {* Tipos de registro para información estructurada (compatibilidad)          *}
  {******************************************************************************}

  { Info Bancaria de la Cuenta. Genérico para UE }
  TrBancoCuentaInfo = record
    IBAN: string; // Código del País + Dígito verificador (4 caracteres)
    CCC: string;  // Código Cuenta Cliente (varía según país)

    function ToFull(Sep: string = ''): string;
    function ToFormatPapel: string;
    function ToFormatElect: string;

    constructor Build(const inIBAN, inCCC: string); overload;
    constructor Build(const inFull: string); overload;
  end;

  { Info Bancaria del Código del País (IBAN) }
  TrBancoIBANInfo = record
    Pais: string;
    DC: string;

    function ToIBAN: string;
    function GetDigitoControl(const inCCC: string): string;
    function IsValid(const inCCC: String; Errores: TStringList = nil): Boolean;

    constructor Build(const inPais, inDC: string); overload;
    constructor Build(const inIBAN: string); overload;
  end;

  { Info del CCC = "Código Cuenta Cliente" Española }
  TrBancoCCCInfoESP = record
    Entidad: string;
    Oficina: string;
    DC: string;
    Cuenta: string;

    function ToCCC(Sep: string = ''): string;
    constructor Build(const inEntidad,
                            inOficina,
                            inDC,
                            inCuenta: string); overload;
    constructor Build(const inCCC: string); overload;
  end;

implementation

uses
  inLibMsg;

const
  PREFIJO_PAPEL_IBAN = 'IBAN';

{******************************************************************************}
{* Funciones auxiliares internas                                              *}
{******************************************************************************}

// Extrae solo números de una cadena
function GetNumbersOnly(const value: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(value) do
  begin
    c := value[i];
    if CharInSet(c, ['0'..'9']) then
      Result := Result + c;
  end;
end;

// Extrae solo caracteres alfanuméricos
function GetAlphaNumericsOnly(const value: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(value) do
  begin
    c := value[i];
    if CharInSet(c, ['A'..'Z', 'a'..'z', '0'..'9']) then
      Result := Result + c;
  end;
end;

// Calcula módulo 97 para validación IBAN
function Mod97(value: String): Integer;
begin
  Result := 0;
  while Length(value) > 0 do
  begin
    Result := StrToIntDef(IntToStr(Result) + Copy(value, 1, 6), 0) mod 97;
    Delete(value, 1, 6);
  end;
end;

// Convierte caracteres a dígitos según tabla IBAN (A=10, B=11, etc.)
function CharToDigitTable(const Value: Char): string;
const
  Initial_A: char = 'A';
var
  iValue: byte;
begin
  Result := Value;
  if CharInSet(Value, ['A'..'Z']) then
  begin
    iValue := (byte(Value) - byte(Initial_A)) + 10;
    Result := IntToStr(iValue);
  end;
end;

// Convierte cadena de país a números según tabla IBAN
function PaisToIBANTable(const inPais: string): string;
var
  i: Integer;
  Pais: string;
begin
  Result := '';
  Pais := AnsiUpperCase(inPais);
  for i := 1 to Length(Pais) do
    Result := Result + CharToDigitTable(Pais[i]);
end;

// Calcula DC para CCC español
function CalculaDC(const Banco, Cuenta: string): Integer;
const
  Pesos: array[0..9] of integer = (6, 3, 7, 9, 10, 5, 8, 4, 2, 1);
var
  n: byte;
  iTemp: integer;
begin
  iTemp := 0;
  for n := 0 to 7 do
    iTemp := iTemp + StrToInt(Copy(Banco, 8 - n, 1)) * Pesos[n];
  Result := 11 - iTemp Mod 11;
  if (Result > 9) then
    Result := 1 - Result mod 10;
  iTemp := 0;
  For n := 0 to 9 do
    iTemp := iTemp + StrToInt(Copy(Cuenta, 10 - n, 1)) * Pesos[n];
  iTemp := 11 - iTemp mod 11;
  if (iTemp > 9) then
    iTemp := 1 - iTemp mod 10;
  Result := Result * 10 + iTemp;
end;

// Añade mensaje a lista si no es nil
procedure AddError(const msg: string; Lista: TStringList);
begin
  if Assigned(Lista) then
    Lista.Add(msg);
end;

{******************************************************************************}
{* TIBAN - Implementación                                                     *}
{******************************************************************************}

class function TIBAN.ValidarIBAN(const IBAN: string;
                                 Errores: TStringList): Boolean;
var
  Cuenta: TrBancoCuentaInfo;
  IBANInfo: TrBancoIBANInfo;
begin
  Cuenta.Build(IBAN);
  IBANInfo.Build(Cuenta.IBAN);
  Result := IBANInfo.IsValid(Cuenta.CCC, Errores);
end;

class function TIBAN.ValidarCCC(const CCC: string;
                                Errores: TStringList): Boolean;
var
  isValid, isSpanish, isNumeric: Boolean;
  sBanco, sCta, sDC, sPref: String;
  iVal, iDC: Integer;
  CCCClean: string;
begin
  CCCClean := GetAlphaNumericsOnly(CCC);
  isValid := False;
  isNumeric := False;

  sPref := Copy(CCCClean, 1, 2);
  isSpanish := ((sPref = 'ES') or (StrToIntDef(sPref, 0) <> 0));

  // IBAN español completo (24 caracteres)
  if ((Length(CCCClean) = 24) and (isSpanish)) then
  begin
    isValid := True;
    sBanco := Copy(CCCClean, 5, 8);
    sDC := Copy(CCCClean, 13, 2);
    sCta := Copy(CCCClean, 15, 10);
  end
  // CCC español sin IBAN (20 caracteres)
  else if (Length(CCCClean) = 20) then
  begin
    isValid := True;
    sBanco := Copy(CCCClean, 1, 8);
    sDC := Copy(CCCClean, 9, 2);
    sCta := Copy(CCCClean, 11, 10);
  end;

  if ((isSpanish) and (not isValid)) then
  begin
    AddError(SErrorLongitudCuentaBancariaInvalida, Errores);
    Exit(False);
  end;

  if ((isSpanish) and (isValid)) then
  begin
    isNumeric := ((TryStrToInt(sBanco, iVal)) and
                  (TryStrToInt(sDC, iVal)) and
                  (TryStrToInt(sCta, iVal)));
  end;

  if ((isValid) and (isSpanish) and (isNumeric)) then
  begin
    iDC := CalculaDC(sBanco, sCta);
    if (iDC <> StrToInt(sDC)) then
    begin
      AddError(Format(SErrorDigitoControlCuentaBancaria,
        [sDC, IntToStr(iDC)]), Errores);
      Exit(False);
    end;
  end
  else if ((isValid) and (isSpanish) and not(isNumeric)) then
  begin
    AddError(SErrorCuentaBancariaInvalida, Errores);
    Exit(False);
  end;

  Result := isValid;
end;

class function TIBAN.GenerarIBAN(const Pais, CCC: string): string;
var
  IBANInfo: TrBancoIBANInfo;
begin
  IBANInfo.Build(Pais, '00');
  IBANInfo.DC := IBANInfo.GetDigitoControl(CCC);
  Result := IBANInfo.ToIBAN + CCC;
end;

class function TIBAN.GenerarDC(const Banco, Cuenta: string): string;
var
  iDC: Integer;
begin
  iDC := 0;
  if ((Length(Cuenta) = 10) and (Length(Banco) = 8)) then
    iDC := CalculaDC(Banco, Cuenta);
  Result := Format('%.2d', [iDC]);
end;

class function TIBAN.CalcularDCIBAN(const Pais, CCC: string): string;
var
  IBANInfo: TrBancoIBANInfo;
begin
  IBANInfo.Build(Pais, '00');
  Result := IBANInfo.GetDigitoControl(CCC);
end;

class function TIBAN.FormatearPapel(const IBAN: string): string;
var
  Clean: string;
begin
  Clean := GetAlphaNumericsOnly(IBAN);
  Result := PREFIJO_PAPEL_IBAN + ' ' + Clean;
end;

class function TIBAN.FormatearElectronico(const IBAN: string): string;
begin
  Result := GetAlphaNumericsOnly(IBAN);
end;

class function TIBAN.ExtraerPais(const IBAN: string): string;
var
  Clean: string;
begin
  Clean := GetAlphaNumericsOnly(IBAN);
  Result := Copy(Clean, 1, 2);
end;

class function TIBAN.ExtraerDCIBAN(const IBAN: string): string;
var
  Clean: string;
begin
  Clean := GetAlphaNumericsOnly(IBAN);
  Result := Copy(Clean, 3, 2);
end;

class function TIBAN.ExtraerCCC(const IBAN: string): string;
var
  Clean: string;
begin
  Clean := GetAlphaNumericsOnly(IBAN);
  Result := Copy(Clean, 5, Length(Clean) - 4);
end;

class function TIBAN.DescomponerCCC(const CCC: string;
                                    out Banco, DC, Cuenta: string): Boolean;
var
  CCCClean: string;
begin
  CCCClean := GetNumbersOnly(CCC);
  Result := Length(CCCClean) = 20;

  if Result then
  begin
    Banco := Copy(CCCClean, 1, 8);
    DC := Copy(CCCClean, 9, 2);
    Cuenta := Copy(CCCClean, 11, 10);
  end
  else
  begin
    Banco := '';
    DC := '';
    Cuenta := '';
  end;
end;

{******************************************************************************}
{* TrBancoCuentaInfo - Implementación                                         *}
{******************************************************************************}

function TrBancoCuentaInfo.ToFull(Sep: string): string;
begin
  Result := Trim(Self.IBAN) + Sep + Trim(Self.CCC);
end;

function TrBancoCuentaInfo.ToFormatElect: string;
begin
  Result := Self.ToFull;
end;

function TrBancoCuentaInfo.ToFormatPapel: string;
begin
  Result := PREFIJO_PAPEL_IBAN + ' ' + Self.ToFull(' ');
end;

constructor TrBancoCuentaInfo.Build(const inIBAN, inCCC: string);
begin
  Self.IBAN := inIBAN;
  Self.CCC := inCCC;
end;

constructor TrBancoCuentaInfo.Build(const inFull: string);
var
  Value: string;
begin
  Value := GetAlphaNumericsOnly(inFull);
  Value := StringReplace(Value, PREFIJO_PAPEL_IBAN, '', [rfIgnoreCase]);

  Self.IBAN := Copy(Value, 1, 4);
  Self.CCC := Copy(Value, 5, Length(Value));
end;

{******************************************************************************}
{* TrBancoIBANInfo - Implementación                                           *}
{******************************************************************************}

function TrBancoIBANInfo.ToIBAN: string;
begin
  Result := Self.Pais + Self.DC;
end;

function TrBancoIBANInfo.GetDigitoControl(const inCCC: string): string;
var
  AValidar: string;
  iValue, NewDV: Integer;
begin
  // Cadena a validar: CCC + País en tabla + "00"
  AValidar := Trim(inCCC) + PaisToIBANTable(Self.Pais) + '00';

  iValue := Mod97(AValidar);
  NewDV := 98 - iValue;

  Result := Format('%.2d', [NewDV]);
end;

function TrBancoIBANInfo.IsValid(const inCCC: String;
                                  Errores: TStringList): Boolean;
var
  AValidar: string;
begin
  // Validar estructura básica
  Result := True;

  if ((Self.Pais.IsEmpty) or (Self.Pais.Length < 2)) then
  begin
    AddError(SErrorPaisIbanInvalido, Errores);
    Result := False;
  end;

  if ((Self.DC.IsEmpty) or (Self.DC.Length < 2) or
      (StrToIntDef(Self.DC, -1) = -1)) then
  begin
    AddError(SErrorDigitoControlIbanInvalido, Errores);
    Result := False;
  end;

  if not Result then
    Exit;

  // Validar dígito de control
  AValidar := Trim(inCCC) + PaisToIBANTable(Self.Pais) + Self.DC;
  Result := Mod97(AValidar) = 1;

  if not Result then
    AddError(SErrorIbanInvalido, Errores);
end;

constructor TrBancoIBANInfo.Build(const inPais, inDC: string);
begin
  Self.Pais := inPais;
  Self.DC := inDC;
end;

constructor TrBancoIBANInfo.Build(const inIBAN: string);
begin
  Self.Pais := Copy(inIBAN, 1, 2);
  Self.DC := Copy(inIBAN, 3, 2);
end;

{******************************************************************************}
{* TrBancoCCCInfoESP - Implementación                                         *}
{******************************************************************************}

function TrBancoCCCInfoESP.ToCCC(Sep: string): string;
begin
  Result := Self.Entidad + Sep + Self.Oficina + Sep +
            Self.DC + Sep + Self.Cuenta;
end;

constructor TrBancoCCCInfoESP.Build(const inEntidad, inOficina, inDC,
                                     inCuenta: string);
begin
  Self.Entidad := inEntidad;
  Self.Oficina := inOficina;
  Self.DC := inDC;
  Self.Cuenta := inCuenta;
end;

constructor TrBancoCCCInfoESP.Build(const inCCC: string);
var
  Value: string;
begin
  Value := GetNumbersOnly(inCCC);

  Self.Entidad := Copy(Value, 1, 4);
  Self.Oficina := Copy(Value, 5, 4);
  Self.DC := Copy(Value, 9, 2);
  Self.Cuenta := Copy(Value, 11, Length(Value));
end;

end.
