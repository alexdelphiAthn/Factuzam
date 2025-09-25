unit inLibIBAN.Utils;

interface

uses
  System.Classes;

type
  TIBANUtils = class
  public
    // Genera un IBAN para una CCC. EJ: "ES17"
    class function GetIBAN(inSiglaPais, inCCC: string): string;
    // Genera un DC válido para CCC Español
    class function GetDC(inBanco, inCuenta:string):string;
    // Valida un IBAN (Generico todos los paises UE)
    class function IsValidIBAN(inFull: String;
                               Errores: TStringList = nil): Boolean;
    // Valida un CCC o IBAN Español
	  class function IsValidDC(inFull:String;
	                           Errores:TSTringList = nil):Boolean;
  end;
  function CalculaDC(Banco, Cuenta: string):integer;

implementation

uses
  System.SysUtils,
  inLibIBAN.Types;

function CalculaDC(Banco, Cuenta: string):integer;
const
	Pesos: array[0..9] of integer=(6,3,7,9,10,5,8,4,2,1);
var
	n      : byte;
	iTemp  : integer;
begin
	iTemp := 0;
	for n := 0 to 7 do
	  iTemp := iTemp + StrToInt(Copy(Banco, 8 - n, 1)) * Pesos[n];
	 Result := 11 - iTemp Mod 11;
	 if (Result > 9) then
	   Result:=1-Result mod 10;
	 iTemp:=0;
	 For n := 0 to 9 do
	 iTemp := iTemp + StrToInt(Copy(Cuenta, 10 - n, 1)) * Pesos[n];
	 iTemp := 11 - iTemp mod 11;
	 if (iTemp > 9) then
	   iTemp := 1 - iTemp mod 10;
	 Result := Result * 10 + iTemp;
end;


{ TIBANUtils }

class function TIBANUtils.GetDC(inBanco, inCuenta:string):string;
var
 iDC :Integer;
begin
  iDC := 0;
  if ((Length(inCuenta) = 10) and (Length(inBanco) = 8)) then
    iDC := CalculaDC(inBanco, inCuenta);
  Result := IntToStr(iDC);
end;

class function TIBANUtils.GetIBAN(inSiglaPais, inCCC: string): string;
var
  IBAN: TrBancoIBANInfo;
begin
  IBAN.Build(inSiglaPais, '00');
  IBAN.DC := IBAN.GetDigitoControl(inCCC);
  Result := IBAN.ToIBAN;
end;

class function TIBANUtils.IsValidDC(inFull: String;
                                    Errores: TSTringList = nil): Boolean;
var
  isValid, isSpanish, isNumeric :boolean;
  sBanco, sCta, sDC, sPref :String;
  iVal, iDC :Integer;
begin
  //Errores := TStringList.Create;
  isValid := False;
  isNumeric := False;
  sPref := (Copy(inFull, 1, 2));
  isSpanish := ((sPref = 'ES') or (StrToIntDef(sPref, 0) <> 0));
  if ((Length(inFull) = 24) and (isSpanish)) then
  begin
    isValid := True;
    sBanco := Copy(inFull, 5, 8);
    sDC := Copy(inFull, 13, 2);
    sCta := Copy(inFull, 15, 10);
  end
  else
    if (Length(inFull) = 20) then
    begin
      isValid := True;
      sBanco := Copy(inFull, 1, 8);
      sDC := Copy(inFull, 9, 2);
      sCta := Copy(inFull, 11, 10);
    end;
  if ((isSpanish) and (not isValid)) then
  begin
    if Assigned(Errores) then
      Errores.Add('Longitud de Número de Cuenta incorrecta');
  end;
  if ((isSpanish) and (isValid)) then
    isNumeric := ((TryStrToInt(sBanco, iVal)) and
                  (TryStrToInt(sDC, iVal)) and
                  (TryStrToInt(sCta, iVal)) );
  if ((isValid) and
      (isSpanish) and
      (isNumeric)) then
  begin
    iDC := CalculaDC(sBanco, sCta);
    if (iDC <> StrToInt(sDC)) then
    begin
      if Assigned(Errores) then
        Errores.Add(Format('DC Incorrecto, es %s y debería ser %d ', [sDC, iDC]));
      isValid := False;
    end;
  end
  else
  if ((isValid) and (isSpanish) and not(isNumeric)) then
  begin
    if Assigned(Errores) then
      Errores.Add('Número de Cuenta incorrecto');
    isValid := False;
  end;
  Result := isValid;
end;

class function TIBANUtils.IsValidIBAN(inFull: String;
                                      Errores: TStringList = nil): Boolean;
var
  Cuenta: TrBancoCuentaInfo;
  IBAN: TrBancoIBANInfo;
begin
  // Descomponemos la cuenta
  Cuenta.Build(inFull);
  // Descomponemos el IBAN
  IBAN.Build(Cuenta.IBAN);
  // Valida
  Result := IBAN.IsValid(Cuenta.CCC, Errores);
end;

end.
