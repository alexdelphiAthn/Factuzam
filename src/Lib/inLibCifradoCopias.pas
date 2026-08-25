{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCifradoCopias                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Cifrado autenticado, comprimido y versionado para copias de seguridad.    }
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
function CifrarCopiaSeguridadComprimida(
  const ADatos, AContrasena: string
): string;
function EmpaquetarCopiaSeguridadZip(
  const ADatos: TBytes
): TBytes;
function DesempaquetarCopiaSeguridadZip(
  const ADatos: TBytes
): TBytes;
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
  System.Zip,
  System.ZLib,
  DCPcrypt2,
  DCPrijndael,
  inLibCifrado;

resourcestring
  SErrorInicializarGeneradorCriptografico =
    'No se pudo inicializar el generador criptográfico.';
  SErrorGenerarDatosAleatoriosSeguros =
    'No se pudieron generar datos aleatorios seguros.';
  SErrorContenidoCifradoLongitudInvalida =
    'El contenido cifrado no tiene una longitud válida.';
  SErrorRellenoCopiaCifradaInvalido =
    'El relleno de la copia cifrada no es válido.';
  SErrorRellenoCopiaCifradaDanado =
    'El relleno de la copia cifrada está dañado.';
  SErrorBase64CopiaCifradaInvalido =
    'La copia cifrada contiene Base64 no válido: %s';
  SErrorScriptComprimirVacio =
    'El script que se va a comprimir está vacío.';
  SErrorCopiaDescomprimidaTamanoMaximo =
    'La copia descomprimida supera el tamaño permitido.';
  SErrorZipCopiaUnicoArchivo =
    'El ZIP de la copia debe contener un único archivo.';
  SErrorZipCopiaSinScript =
    'El ZIP de la copia no contiene el script esperado.';
  SErrorScriptZipVacio =
    'El script contenido en el ZIP está vacío.';
  SErrorZipCopiaInvalido =
    'El ZIP de la copia no es válido: %s';
  SErrorFormatoCopiaNoValido =
    'El formato solicitado para la copia no es válido.';
  SErrorContrasenaCopiaVacia =
    'La contraseña de la copia no puede estar vacía.';
  SErrorCabeceraCopiaCifradaIncompleta =
    'La cabecera de la copia cifrada está incompleta.';
  SErrorVersionCopiaCifradaIncompatible =
    'La versión de la copia cifrada no es compatible.';
  SErrorIteracionesCopiaNoValido =
    'El número de iteraciones de la copia no es válido.';
  SErrorMetadatosCopiaCifradaInvalidos =
    'Los metadatos de la copia cifrada no son válidos.';
  SErrorContrasenaIncorrectaOCopiaDanada =
    'La contraseña no es correcta o la copia está dañada.';
  SErrorIndicarContrasenaCopia =
    'Debe indicar la contraseña de la copia.';
  SErrorAbrirCopiaCifradaHistorica =
    'No se pudo abrir la copia cifrada histórica.';

const
  CABECERA_CIFRADO = 'FZAM_COPIA_CIFRADA_V2';
  CABECERA_CIFRADO_ZLIB = 'FZAM_COPIA_CIFRADA_V3';
  CABECERA_CIFRADO_ZIP = 'FZAM_COPIA_CIFRADA_V3_ZIP';
  NOMBRE_ENTRADA_ZIP = 'copia.sql';
  ITERACIONES_PBKDF2 = 100000;
  LONGITUD_SAL = 16;
  LONGITUD_VECTOR = 16;
  LONGITUD_CLAVE = 32;
  LONGITUD_CLAVES = 64;
  LONGITUD_BLOQUE_AES = 16;
  PROVEEDOR_RSA_AES = 24;
  VERIFICAR_CONTEXTO = $F0000000;
  MAXIMO_DATOS_DESCOMPRIMIDOS = 1024 * 1024 * 1024;

type
  TFormatoCifradoCopia = (
    fccDesconocido,
    fccV2,
    fccV3ZLib,
    fccV3Zip
  );
  TSobreCifradoCopia = record
    Cabecera: string;
    Iteraciones: Integer;
    Sal: TBytes;
    Vector: TBytes;
    Mac: TBytes;
    Cifrado: TBytes;
  end;

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
    raise ECifradoCopia.Create(SErrorInicializarGeneradorCriptografico);
  end;
  try
    if not FzaCryptGenRandom(
      hProveedor,
      DWORD(ALongitud),
      @Result[0]) then
    begin
      raise ECifradoCopia.Create(SErrorGenerarDatosAleatoriosSeguros);
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
    raise ECifradoCopia.Create(SErrorContenidoCifradoLongitudInvalida);
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
    raise ECifradoCopia.Create(SErrorRellenoCopiaCifradaInvalido);
  end;
  for iIndice := Length(Result) - iRelleno to High(Result) do
  begin
    if Result[iIndice] <> Byte(iRelleno) then
    begin
      raise ECifradoCopia.Create(SErrorRellenoCopiaCifradaDanado);
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
      raise ECifradoCopia.CreateFmt(
        SErrorBase64CopiaCifradaInvalido,
        [E.Message]);
    end;
  end;
end;

function CrearDatosAutenticados(
  AIteraciones: Integer;
  const ASal, AVector, ACifrado: TBytes;
  const ACabeceraAutenticada: string
): TBytes;
begin
  Result := nil;
  if ACabeceraAutenticada <> '' then
  begin
    Result := TEncoding.ASCII.GetBytes(
      ACabeceraAutenticada + #0);
  end;
  Result := ConcatenarBytes(
    Result,
    TEncoding.ASCII.GetBytes(IntToStr(AIteraciones)));
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

function EmpaquetarCopiaSeguridadZip(
  const ADatos: TBytes): TBytes;
var
  oDestino: TMemoryStream;
  oZip: TZipFile;
begin
  if Length(ADatos) = 0 then
  begin
    raise ECifradoCopia.Create(SErrorScriptComprimirVacio);
  end;
  if UInt64(Length(ADatos)) >
     UInt64(MAXIMO_DATOS_DESCOMPRIMIDOS) then
  begin
    raise ECifradoCopia.Create(SErrorCopiaDescomprimidaTamanoMaximo);
  end;
  oDestino := TMemoryStream.Create;
  oZip := TZipFile.Create;
  try
    oZip.Open(oDestino, zmWrite);
    try
      oZip.Add(
        ADatos,
        NOMBRE_ENTRADA_ZIP,
        zcDeflate);
    finally
      oZip.Close;
    end;
    SetLength(Result, oDestino.Size);
    oDestino.Position := 0;
    if oDestino.Size > 0 then
      oDestino.ReadBuffer(Result[0], oDestino.Size);
  finally
    FreeAndNil(oZip);
    FreeAndNil(oDestino);
  end;
end;

function DescomprimirZLibBytes(const ADatos: TBytes): TBytes;
var
  Buffer: TBytes;
  Destino: TMemoryStream;
  Descompresor: TZDecompressionStream;
  Leidos: Integer;
  Origen: TBytesStream;
begin
  Origen := TBytesStream.Create(ADatos);
  Destino := TMemoryStream.Create;
  try
    Descompresor := TZDecompressionStream.Create(Origen);
    try
      SetLength(Buffer, 65536);
      Leidos := Descompresor.Read(Buffer[0], Length(Buffer));
      while Leidos > 0 do
      begin
        if Destino.Size + Leidos > MAXIMO_DATOS_DESCOMPRIMIDOS then
        begin
          raise ECifradoCopia.Create(SErrorCopiaDescomprimidaTamanoMaximo);
        end;
        Destino.WriteBuffer(Buffer[0], Leidos);
        Leidos := Descompresor.Read(Buffer[0], Length(Buffer));
      end;
    finally
      FreeAndNil(Descompresor);
    end;
    SetLength(Result, Destino.Size);
    Destino.Position := 0;
    if Destino.Size > 0 then
      Destino.ReadBuffer(Result[0], Destino.Size);
  finally
    FreeAndNil(Destino);
    FreeAndNil(Origen);
  end;
end;

function DesempaquetarCopiaSeguridadZip(
  const ADatos: TBytes): TBytes;
var
  oCabecera: TZipHeader;
  oOrigen: TBytesStream;
  oZip: TZipFile;
begin
  oOrigen := TBytesStream.Create(ADatos);
  oZip := TZipFile.Create;
  try
    try
      oZip.Open(oOrigen, zmRead);
      if oZip.FileCount <> 1 then
      begin
        raise ECifradoCopia.Create(SErrorZipCopiaUnicoArchivo);
      end;
      if not SameText(
        oZip.FileName[0],
        NOMBRE_ENTRADA_ZIP) then
      begin
        raise ECifradoCopia.Create(SErrorZipCopiaSinScript);
      end;
      oCabecera := oZip.FileInfo[0];
      if oCabecera.UncompressedSize64 = 0 then
      begin
        raise ECifradoCopia.Create(SErrorScriptZipVacio);
      end;
      if oCabecera.UncompressedSize64 >
         UInt64(MAXIMO_DATOS_DESCOMPRIMIDOS) then
      begin
        raise ECifradoCopia.Create(SErrorCopiaDescomprimidaTamanoMaximo);
      end;
      oZip.Read(0, Result);
    except
      on E: EZipException do
      begin
        raise ECifradoCopia.CreateFmt(
          SErrorZipCopiaInvalido,
          [E.Message]);
      end;
    end;
  finally
    FreeAndNil(oZip);
    FreeAndNil(oOrigen);
  end;
end;

function ObtenerCabeceraCifrado(const ADatos: string): string;
var
  iFinCabecera: Integer;
begin
  Result := TrimLeft(ADatos);
  iFinCabecera := Pos(#10, Result);
  if iFinCabecera = 0 then
    iFinCabecera := Pos(#13, Result);
  if iFinCabecera > 0 then
    Result := Copy(Result, 1, iFinCabecera - 1);
  Result := Trim(Result);
end;

function ResolverFormatoCifrado(
  const ADatos: string
): TFormatoCifradoCopia;
var
  sCabecera: string;
begin
  sCabecera := ObtenerCabeceraCifrado(ADatos);
  if SameText(CABECERA_CIFRADO, sCabecera) then
    Result := fccV2
  else if SameText(CABECERA_CIFRADO_ZLIB, sCabecera) then
    Result := fccV3ZLib
  else if SameText(CABECERA_CIFRADO_ZIP, sCabecera) then
    Result := fccV3Zip
  else
    Result := fccDesconocido;
end;

function EsFormatoCifradoActual(const ADatos: string): Boolean;
begin
  Result := ResolverFormatoCifrado(ADatos) <>
    fccDesconocido;
end;

procedure PrepararOrigenCifrado(
  const ADatos: string;
  AFormato: TFormatoCifradoCopia;
  out AOrigen: TBytes;
  out ACabecera: string);
begin
  AOrigen := TEncoding.UTF8.GetBytes(ADatos);
  case AFormato of
    fccV2:
      ACabecera := CABECERA_CIFRADO;
    fccV3Zip:
    begin
      AOrigen := EmpaquetarCopiaSeguridadZip(AOrigen);
      ACabecera := CABECERA_CIFRADO_ZIP;
    end;
  else
    raise ECifradoCopia.Create(SErrorFormatoCopiaNoValido);
  end;
end;

function CifrarCopiaSeguridadInterna(
  const ADatos, AContrasena: string;
  AFormato: TFormatoCifradoCopia): string;
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
  sCabecera: string;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(SErrorContrasenaCopiaVacia);
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
  PrepararOrigenCifrado(
    ADatos,
    AFormato,
    aOrigen,
    sCabecera);
  aCifrado := CifrarAESBytes(
    aOrigen,
    aClaveCifrado,
    aVector);
  aDatosAutenticados := CrearDatosAutenticados(
    ITERACIONES_PBKDF2,
    aSal,
    aVector,
    aCifrado,
    IfThen(AFormato = fccV3Zip, sCabecera, ''));
  aMac := THashSHA2.GetHMACAsBytes(
    aDatosAutenticados,
    aClaveMac);
  Result := sCabecera + sLineBreak +
    IntToStr(ITERACIONES_PBKDF2) + sLineBreak +
    CodificarBase64(aSal) + sLineBreak +
    CodificarBase64(aVector) + sLineBreak +
    CodificarBase64(aMac) + sLineBreak +
    CodificarBase64(aCifrado);
end;

function CifrarCopiaSeguridad(
  const ADatos, AContrasena: string): string;
begin
  Result := CifrarCopiaSeguridadInterna(
    ADatos,
    AContrasena,
    fccV2);
end;

function CifrarCopiaSeguridadComprimida(
  const ADatos, AContrasena: string): string;
begin
  Result := CifrarCopiaSeguridadInterna(
    ADatos,
    AContrasena,
    fccV3Zip);
end;

function LeerSobreCifrado(
  const ADatos: string;
  AFormato: TFormatoCifradoCopia): TSobreCifradoCopia;
var
  oLineas: TStringList;
begin
  Result := Default(TSobreCifradoCopia);
  oLineas := TStringList.Create;
  try
    oLineas.Text := ADatos;
    if oLineas.Count < 6 then
    begin
      raise ECifradoCopia.Create(SErrorCabeceraCopiaCifradaIncompleta);
    end;
    Result.Cabecera := Trim(oLineas[0]);
    if ResolverFormatoCifrado(Result.Cabecera) <> AFormato then
    begin
      raise ECifradoCopia.Create(SErrorVersionCopiaCifradaIncompatible);
    end;
    Result.Iteraciones := StrToIntDef(
      Trim(oLineas[1]),
      0);
    if (Result.Iteraciones < 10000) or
       (Result.Iteraciones > 1000000) then
    begin
      raise ECifradoCopia.Create(SErrorIteracionesCopiaNoValido);
    end;
    Result.Sal := DecodificarBase64(Trim(oLineas[2]));
    Result.Vector := DecodificarBase64(Trim(oLineas[3]));
    Result.Mac := DecodificarBase64(Trim(oLineas[4]));
    Result.Cifrado := DecodificarBase64(Trim(oLineas[5]));
  finally
    FreeAndNil(oLineas);
  end;
end;

procedure ValidarDimensionesSobre(
  const ASobre: TSobreCifradoCopia);
begin
  if (Length(ASobre.Sal) <> LONGITUD_SAL) or
     (Length(ASobre.Vector) <> LONGITUD_VECTOR) or
     (Length(ASobre.Mac) <> LONGITUD_CLAVE) then
  begin
    raise ECifradoCopia.Create(SErrorMetadatosCopiaCifradaInvalidos);
  end;
end;

function ObtenerClaveCifradoValidada(
  const ASobre: TSobreCifradoCopia;
  const AContrasena: string;
  AFormato: TFormatoCifradoCopia): TBytes;
var
  aClaveMac: TBytes;
  aClaves: TBytes;
  aDatosAutenticados: TBytes;
  aMacCalculado: TBytes;
begin
  aClaves := DerivarClavePBKDF2(
    AContrasena,
    ASobre.Sal,
    ASobre.Iteraciones,
    LONGITUD_CLAVES);
  Result := Copy(aClaves, 0, LONGITUD_CLAVE);
  aClaveMac := Copy(
    aClaves,
    LONGITUD_CLAVE,
    LONGITUD_CLAVE);
  aDatosAutenticados := CrearDatosAutenticados(
    ASobre.Iteraciones,
    ASobre.Sal,
    ASobre.Vector,
    ASobre.Cifrado,
    IfThen(AFormato = fccV3Zip, ASobre.Cabecera, ''));
  aMacCalculado := THashSHA2.GetHMACAsBytes(
    aDatosAutenticados,
    aClaveMac);
  if not ComparacionConstante(aMacCalculado, ASobre.Mac) then
  begin
    raise ECifradoCopia.Create(SErrorContrasenaIncorrectaOCopiaDanada);
  end;
end;

function DescifrarFormatoActual(
  const ADatos, AContrasena: string;
  AFormato: TFormatoCifradoCopia
): string;
var
  aClaveCifrado: TBytes;
  aPlano: TBytes;
  Sobre: TSobreCifradoCopia;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(SErrorIndicarContrasenaCopia);
  end;
  Sobre := LeerSobreCifrado(ADatos, AFormato);
  ValidarDimensionesSobre(Sobre);
  aClaveCifrado := ObtenerClaveCifradoValidada(
    Sobre,
    AContrasena,
    AFormato);
  aPlano := DescifrarAESBytes(
    Sobre.Cifrado,
    aClaveCifrado,
    Sobre.Vector);
  case AFormato of
    fccV3ZLib:
      aPlano := DescomprimirZLibBytes(aPlano);
    fccV3Zip:
      aPlano := DesempaquetarCopiaSeguridadZip(aPlano);
  end;
  Result := TEncoding.UTF8.GetString(aPlano);
end;

function DescifrarCopiaSeguridad(
  const ADatos, AContrasena: string): string;
var
  Formato: TFormatoCifradoCopia;
begin
  Formato := ResolverFormatoCifrado(ADatos);
  if Formato <> fccDesconocido then
  begin
    Result := DescifrarFormatoActual(
      ADatos,
      AContrasena,
      Formato);
  end
  else
  begin
    Result := DescifrarAESConContrasena(
      ADatos,
      AnsiString(AContrasena));
    if Trim(Result) = '' then
    begin
      raise ECifradoCopia.Create(SErrorAbrirCopiaCifradaHistorica);
    end;
  end;
end;

end.
