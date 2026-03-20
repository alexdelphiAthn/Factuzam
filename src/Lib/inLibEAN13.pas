unit inLibEAN13;

interface

uses
  SysUtils;

// Calcula el dígito de control a partir de los primeros 7 dígitos
function CalcularDigitoEAN8(const Codigo7: string): Char;

// Valida si un código EAN-8 completo (8 dígitos) es correcto
function EsEAN8Valido(const Codigo: string): Boolean;

// Calcula el dígito de control a partir de los primeros 12 dígitos
function CalcularDigitoEAN13(const Codigo12: string): Char;

// Valida si un código EAN-13 completo (13 dígitos) es correcto
function EsEAN13Valido(const Codigo: string): Boolean;

implementation

function CalcularDigitoEAN8(const Codigo7: string): Char;
var
  i, SumaImpares, SumaPares, Total, Resto, DigitoControl: Integer;
begin
  // Validamos que al menos tenga 7 caracteres
  if Length(Codigo7) < 7 then
    raise Exception.Create('El código debe tener al menos 7 dígitos para calcular el control.');

  SumaImpares := 0;
  SumaPares := 0;

  for i := 1 to 7 do
  begin
    // Validación de seguridad para asegurar que son solo números
    if not (Codigo7[i] in ['0'..'9']) then
      raise Exception.Create('El código de barras contiene caracteres no numéricos.');

    // OJO a la diferencia con EAN-13:
    // En EAN-8, las posiciones IMPARES se multiplican por 3
    if (i mod 2) <> 0 then
      SumaImpares := SumaImpares + ((Ord(Codigo7[i]) - Ord('0')) * 3)
    else
      SumaPares := SumaPares + (Ord(Codigo7[i]) - Ord('0'));
  end;

  Total := SumaImpares + SumaPares;

  Resto := Total mod 10;

  if Resto = 0 then
    DigitoControl := 0
  else
    DigitoControl := 10 - Resto;

  // Devolvemos el dígito calculado como Char
  Result := Chr(DigitoControl + Ord('0'));
end;

function EsEAN8Valido(const Codigo: string): Boolean;
begin
  // Un EAN-8 estándar tiene exactamente 8 caracteres
  if Length(Codigo) <> 8 then
    Exit(False);

  try
    // Calculamos el dígito sobre los primeros 7 y comparamos con el 8º
    Result := (CalcularDigitoEAN8(Copy(Codigo, 1, 7)) = Codigo[8]);
  except
    // Si hay letras o caracteres raros, devolvemos False
    Result := False;
  end;
end;

function CalcularDigitoEAN13(const Codigo12: string): Char;
var
  i, SumaImpares, SumaPares, Total, Resto, DigitoControl: Integer;
begin
  // Validamos que al menos tenga 12 caracteres para evitar Access Violations
  if Length(Codigo12) < 12 then
    raise Exception.Create('El código debe tener al menos 12 dígitos para calcular el control.');

  SumaImpares := 0;
  SumaPares := 0;

  // Los strings en Delphi empiezan en el índice 1
  for i := 1 to 12 do
  begin
    // Validación de seguridad por si el string trae letras o basura
    if not (Codigo12[i] in ['0'..'9']) then
      raise Exception.Create('El código de barras contiene caracteres no numéricos.');

    // Convertimos el char a entero restando el valor ASCII del '0'
    if (i mod 2) <> 0 then
      SumaImpares := SumaImpares + (Ord(Codigo12[i]) - Ord('0')) // Posiciones impares (1, 3, 5...)
    else
      SumaPares := SumaPares + (Ord(Codigo12[i]) - Ord('0'));    // Posiciones pares (2, 4, 6...)
  end;

  // La regla EAN-13 dice que las posiciones pares se multiplican por 3
  Total := SumaImpares + (SumaPares * 3);

  // Sacamos el resto de dividir entre 10
  Resto := Total mod 10;

  if Resto = 0 then
    DigitoControl := 0
  else
    DigitoControl := 10 - Resto;

  // Devolvemos el dígito calculado como Char
  Result := Chr(DigitoControl + Ord('0'));
end;

function EsEAN13Valido(const Codigo: string): Boolean;
begin
  // Un EAN-13 estándar tiene exactamente 13 caracteres
  if Length(Codigo) <> 13 then
    Exit(False);

  try
    // Calculamos el dígito sobre los primeros 12 y comparamos con el 13º
    Result := (CalcularDigitoEAN13(Copy(Codigo, 1, 12)) = Codigo[13]);
  except
    // Si contiene caracteres no numéricos y lanza la excepción, no es válido
    Result := False;
  end;
end;

end.
