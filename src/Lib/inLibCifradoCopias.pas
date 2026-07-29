{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCifradoCopias                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cifrado autenticado y versionado para copias de seguridad.                }
{******************************************************************************}
unit inLibCifradoCopias;

interface

uses
  System.SysUtils;

type
  ECifradoCopia = class(Exception);

function EsFormatoCifradoActual(const ADatos: string): Boolean;
function CifrarCopiaSeguridad(
  const ADatos, AContrasena: string
): string;
function DescifrarCopiaSeguridad(
  const ADatos, AContrasena: string
): string;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.Hash,
  System.NetEncoding,
  System.StrUtils,
  DCPcrypt2,
  DCPrijndael,
  inLibCifrado;

const
  CABECERA_CIFRADO = 'FZAM_COPIA_CIFRADA_V2';
  ITERACIONES_PBKDF2 = 100000;
  LONGITUD_SAL = 16;
  LONGITUD_VECTOR = 16;
  LONGITUD_CLAVE = 32;
  LONGITUD_CLAVES = 64;
  LONGITUD_BLOQUE_AES = 16;
  PROVEEDOR_RSA_AES = 24;
  VERIFICAR_CONTEXTO = $F0000000;

function FzaCryptAcquireContextW(
  var AProveedor: NativeUInt;
  AContenedor, AProveedorNombre: PWideChar;
  ATipoProveedor, AFlags: DWORD
): BOOL; stdcall; external 'advapi32.dll' name 'CryptAcquireContextW';
function FzaCryptReleaseContext(
  AProveedor: NativeUInt;
  AFlags: DWORD
): BOOL; stdcall; external 'advapi32.dll' name 'CryptReleaseContext';
function FzaCryptGenRandom(
  AProveedor: NativeUInt;
  ALongitud: DWORD;
  ABuffer: PByte
): BOOL; stdcall; external 'advapi32.dll' name 'CryptGenRandom';

function ConcatenarBytes(
  const APrimero, ASegundo: TBytes
): TBytes;
var
  iLongitudPrimero: Integer;
begin
  iLongitudPrimero := Length(APrimero);
  SetLength(Result, iLongitudPrimero + Length(ASegundo));
  if iLongitudPrimero > 0 then
  begin
    Move(
      APrimero[0],
      Result[0],
      iLongitudPrimero);
  end;
  if Length(ASegundo) > 0 then
  begin
    Move(
      ASegundo[0],
      Result[iLongitudPrimero],
      Length(ASegundo));
  end;
end;

function EnteroBigEndian(AValor: Integer): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := Byte((AValor shr 24) and $FF);
  Result[1] := Byte((AValor shr 16) and $FF);
  Result[2] := Byte((AValor shr 8) and $FF);
  Result[3] := Byte(AValor and $FF);
end;

function DerivarClavePBKDF2(
  const AContrasena: string;
  const ASal: TBytes;
  AIteraciones, ALongitud: Integer
): TBytes;
var
  aClaveContrasena: TBytes;
  aDatosBloque: TBytes;
  aU: TBytes;
  aT: TBytes;
  iBloque: Integer;
  iBloques: Integer;
  iDestino: Integer;
  iIndice: Integer;
  iIteracion: Integer;
  iCopiar: Integer;
begin
  aClaveContrasena := TEncoding.UTF8.GetBytes(AContrasena);
  iBloques := (ALongitud + LONGITUD_CLAVE - 1) div LONGITUD_CLAVE;
  SetLength(Result, ALongitud);
  iDestino := 0;
  for iBloque := 1 to iBloques do
  begin
    aDatosBloque := ConcatenarBytes(
      ASal,
      EnteroBigEndian(iBloque));
    aU := THashSHA2.GetHMACAsBytes(
      aDatosBloque,
      aClaveContrasena);
    aT := Copy(aU, 0, Length(aU));
    for iIteracion := 2 to AIteraciones do
    begin
      aU := THashSHA2.GetHMACAsBytes(
        aU,
        aClaveContrasena);
      for iIndice := 0 to High(aT) do
        aT[iIndice] := aT[iIndice] xor aU[iIndice];
    end;
    iCopiar := Length(aT);
    if iDestino + iCopiar > ALongitud then
      iCopiar := ALongitud - iDestino;
    Move(
      aT[0],
      Result[iDestino],
      iCopiar);
    Inc(iDestino, iCopiar);
  end;
end;

function GenerarBytesAleatorios(ALongitud: Integer): TBytes;
var
  hProveedor: NativeUInt;
begin
  hProveedor := 0;
  SetLength(Result, ALongitud);
  if not FzaCryptAcquireContextW(
    hProveedor,
    nil,
    nil,
    PROVEEDOR_RSA_AES,
    VERIFICAR_CONTEXTO) then
  begin
    raise ECifradoCopia.Create(
      'No se pudo inicializar el generador criptográfico.');
  end;
  try
    if not FzaCryptGenRandom(
      hProveedor,
      DWORD(ALongitud),
      @Result[0]) then
    begin
      raise ECifradoCopia.Create(
        'No se pudieron generar datos aleatorios seguros.');
    end;
  finally
    FzaCryptReleaseContext(hProveedor, 0);
  end;
end;

function CifrarAESBytes(
  const ADatos, AClave, AVector: TBytes
): TBytes;
var
  aOrigen: TBytes;
  iIndice: Integer;
  iLongitud: Integer;
  iRelleno: Integer;
  oCifrador: TDCP_rijndael;
begin
  aOrigen := Copy(ADatos, 0, Length(ADatos));
  iLongitud := Length(aOrigen);
  iRelleno := LONGITUD_BLOQUE_AES -
    (iLongitud mod LONGITUD_BLOQUE_AES);
  SetLength(aOrigen, iLongitud + iRelleno);
  for iIndice := iLongitud to High(aOrigen) do
    aOrigen[iIndice] := Byte(iRelleno);
  SetLength(Result, Length(aOrigen));
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    oCifrador.Init(
      AClave[0],
      256,
      @AVector[0]);
    oCifrador.Encrypt(
      aOrigen[0],
      Result[0],
      Length(aOrigen));
  finally
    FreeAndNil(oCifrador);
  end;
end;

function DescifrarAESBytes(
  const ADatos, AClave, AVector: TBytes
): TBytes;
var
  iIndice: Integer;
  iRelleno: Integer;
  oCifrador: TDCP_rijndael;
begin
  if (Length(ADatos) = 0) or
     ((Length(ADatos) mod LONGITUD_BLOQUE_AES) <> 0) then
  begin
    raise ECifradoCopia.Create(
      'El contenido cifrado no tiene una longitud válida.');
  end;
  SetLength(Result, Length(ADatos));
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    oCifrador.Init(
      AClave[0],
      256,
      @AVector[0]);
    oCifrador.Decrypt(
      ADatos[0],
      Result[0],
      Length(ADatos));
  finally
    FreeAndNil(oCifrador);
  end;
  iRelleno := Result[High(Result)];
  if (iRelleno < 1) or
     (iRelleno > LONGITUD_BLOQUE_AES) then
  begin
    raise ECifradoCopia.Create(
      'El relleno de la copia cifrada no es válido.');
  end;
  for iIndice := Length(Result) - iRelleno to High(Result) do
  begin
    if Result[iIndice] <> Byte(iRelleno) then
    begin
      raise ECifradoCopia.Create(
        'El relleno de la copia cifrada está dañado.');
    end;
  end;
  SetLength(Result, Length(Result) - iRelleno);
end;

function CodificarBase64(const ABytes: TBytes): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(ABytes);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function DecodificarBase64(const ATexto: string): TBytes;
begin
  try
    Result := TNetEncoding.Base64.DecodeStringToBytes(ATexto);
  except
    on E: Exception do
    begin
      raise ECifradoCopia.Create(
        'La copia cifrada contiene Base64 no válido: ' +
        E.Message);
    end;
  end;
end;

function CrearDatosAutenticados(
  AIteraciones: Integer;
  const ASal, AVector, ACifrado: TBytes
): TBytes;
begin
  Result := TEncoding.ASCII.GetBytes(
    IntToStr(AIteraciones));
  Result := ConcatenarBytes(Result, ASal);
  Result := ConcatenarBytes(Result, AVector);
  Result := ConcatenarBytes(Result, ACifrado);
end;

function ComparacionConstante(
  const APrimero, ASegundo: TBytes
): Boolean;
var
  iDiferencia: Byte;
  iIndice: Integer;
begin
  Result := Length(APrimero) = Length(ASegundo);
  iDiferencia := 0;
  if Result then
  begin
    for iIndice := 0 to High(APrimero) do
      iDiferencia := iDiferencia xor
        (APrimero[iIndice] xor ASegundo[iIndice]);
    Result := iDiferencia = 0;
  end;
end;

function EsFormatoCifradoActual(const ADatos: string): Boolean;
begin
  Result := StartsText(
    CABECERA_CIFRADO,
    TrimLeft(ADatos));
end;

function CifrarCopiaSeguridad(
  const ADatos, AContrasena: string): string;
var
  aCifrado: TBytes;
  aClaveCifrado: TBytes;
  aClaveMac: TBytes;
  aClaves: TBytes;
  aDatosAutenticados: TBytes;
  aMac: TBytes;
  aOrigen: TBytes;
  aSal: TBytes;
  aVector: TBytes;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(
      'La contraseña de la copia no puede estar vacía.');
  end;
  aSal := GenerarBytesAleatorios(LONGITUD_SAL);
  aVector := GenerarBytesAleatorios(LONGITUD_VECTOR);
  aClaves := DerivarClavePBKDF2(
    AContrasena,
    aSal,
    ITERACIONES_PBKDF2,
    LONGITUD_CLAVES);
  aClaveCifrado := Copy(aClaves, 0, LONGITUD_CLAVE);
  aClaveMac := Copy(
    aClaves,
    LONGITUD_CLAVE,
    LONGITUD_CLAVE);
  aOrigen := TEncoding.UTF8.GetBytes(ADatos);
  aCifrado := CifrarAESBytes(
    aOrigen,
    aClaveCifrado,
    aVector);
  aDatosAutenticados := CrearDatosAutenticados(
    ITERACIONES_PBKDF2,
    aSal,
    aVector,
    aCifrado);
  aMac := THashSHA2.GetHMACAsBytes(
    aDatosAutenticados,
    aClaveMac);
  Result := CABECERA_CIFRADO + sLineBreak +
    IntToStr(ITERACIONES_PBKDF2) + sLineBreak +
    CodificarBase64(aSal) + sLineBreak +
    CodificarBase64(aVector) + sLineBreak +
    CodificarBase64(aMac) + sLineBreak +
    CodificarBase64(aCifrado);
end;

function DescifrarFormatoActual(
  const ADatos, AContrasena: string
): string;
var
  aCifrado: TBytes;
  aClaveCifrado: TBytes;
  aClaveMac: TBytes;
  aClaves: TBytes;
  aDatosAutenticados: TBytes;
  aMacCalculado: TBytes;
  aMacGuardado: TBytes;
  aPlano: TBytes;
  aSal: TBytes;
  aVector: TBytes;
  iIteraciones: Integer;
  oLineas: TStringList;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(
      'Debe indicar la contraseña de la copia.');
  end;
  oLineas := TStringList.Create;
  try
    oLineas.Text := ADatos;
    if oLineas.Count < 6 then
    begin
      raise ECifradoCopia.Create(
        'La cabecera de la copia cifrada está incompleta.');
    end;
    if not SameText(
      Trim(oLineas[0]),
      CABECERA_CIFRADO) then
    begin
      raise ECifradoCopia.Create(
        'La versión de la copia cifrada no es compatible.');
    end;
    iIteraciones := StrToIntDef(
      Trim(oLineas[1]),
      0);
    if (iIteraciones < 10000) or
       (iIteraciones > 1000000) then
    begin
      raise ECifradoCopia.Create(
        'El número de iteraciones de la copia no es válido.');
    end;
    aSal := DecodificarBase64(Trim(oLineas[2]));
    aVector := DecodificarBase64(Trim(oLineas[3]));
    aMacGuardado := DecodificarBase64(Trim(oLineas[4]));
    aCifrado := DecodificarBase64(Trim(oLineas[5]));
  finally
    FreeAndNil(oLineas);
  end;
  if (Length(aSal) <> LONGITUD_SAL) or
     (Length(aVector) <> LONGITUD_VECTOR) or
     (Length(aMacGuardado) <> LONGITUD_CLAVE) then
  begin
    raise ECifradoCopia.Create(
      'Los metadatos de la copia cifrada no son válidos.');
  end;
  aClaves := DerivarClavePBKDF2(
    AContrasena,
    aSal,
    iIteraciones,
    LONGITUD_CLAVES);
  aClaveCifrado := Copy(aClaves, 0, LONGITUD_CLAVE);
  aClaveMac := Copy(
    aClaves,
    LONGITUD_CLAVE,
    LONGITUD_CLAVE);
  aDatosAutenticados := CrearDatosAutenticados(
    iIteraciones,
    aSal,
    aVector,
    aCifrado);
  aMacCalculado := THashSHA2.GetHMACAsBytes(
    aDatosAutenticados,
    aClaveMac);
  if not ComparacionConstante(
    aMacCalculado,
    aMacGuardado) then
  begin
    raise ECifradoCopia.Create(
      'La contraseña no es correcta o la copia está dañada.');
  end;
  aPlano := DescifrarAESBytes(
    aCifrado,
    aClaveCifrado,
    aVector);
  Result := TEncoding.UTF8.GetString(aPlano);
end;

function DescifrarCopiaSeguridad(
  const ADatos, AContrasena: string): string;
begin
  if EsFormatoCifradoActual(ADatos) then
  begin
    Result := DescifrarFormatoActual(
      ADatos,
      AContrasena);
  end
  else
  begin
    Result := DescifrarAESConContrasena(
      ADatos,
      AnsiString(AContrasena));
    if Trim(Result) = '' then
    begin
      raise ECifradoCopia.Create(
        'No se pudo abrir la copia cifrada histórica.');
    end;
  end;
end;

end.
