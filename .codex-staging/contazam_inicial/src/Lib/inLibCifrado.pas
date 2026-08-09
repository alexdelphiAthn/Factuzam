{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCifrado                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Cifrado AES compatible con las credenciales de Factuzam.                 }
{******************************************************************************}
unit inLibCifrado;

interface

function CifrarAES(const ADatos: string): string;
function DescifrarAES(const ADatos: string): string;
function EsCifradoAESValido(const ADatos: string): Boolean;

implementation

uses
  System.NetEncoding, System.SysUtils, Winapi.Windows;

type
  TCabeceraClave = packed record
    Tipo: Byte;
    Version: Byte;
    Reservado: Word;
    Algoritmo: Cardinal;
  end;

const
  PROVEEDOR_AES =
    'Microsoft Enhanced RSA and AES Cryptographic Provider';
  TIPO_PROVEEDOR_AES = 24;
  VERIFICAR_CONTEXTO = $F0000000;
  TIPO_CLAVE_PLANA = 8;
  VERSION_BLOB_CLAVE = 2;
  ALGORITMO_AES_256 = $00006610;
  PARAMETRO_VECTOR = 1;
  PARAMETRO_MODO = 4;
  MODO_CBC = 1;
  TAMANO_BLOQUE_AES = 16;
  CLAVE_AES_PREDETERMINADA =
    'Key1234567890-1234567890-1234567';
  VECTOR_AES_PREDETERMINADO = '1234567890123456';

function AdquirirContextoCriptografico(
  AProveedor: PNativeUInt;
  AContenedor: PWideChar;
  AProveedorNombre: PWideChar;
  ATipoProveedor: Cardinal;
  AOpciones: Cardinal): BOOL; stdcall;
  external advapi32 name 'CryptAcquireContextW';

function ImportarClaveCriptografica(
  AProveedor: NativeUInt;
  ADatos: PByte;
  ATamanoDatos: Cardinal;
  AClavePublica: NativeUInt;
  AOpciones: Cardinal;
  AClave: PNativeUInt): BOOL; stdcall;
  external advapi32 name 'CryptImportKey';

function EstablecerParametroClave(
  AClave: NativeUInt;
  AParametro: Cardinal;
  AValor: PByte;
  AOpciones: Cardinal): BOOL; stdcall;
  external advapi32 name 'CryptSetKeyParam';

function CifrarDatos(
  AClave: NativeUInt;
  AHash: NativeUInt;
  AEsFinal: BOOL;
  AOpciones: Cardinal;
  ADatos: PByte;
  ATamanoDatos: PCardinal;
  ATamanoBuffer: Cardinal): BOOL; stdcall;
  external advapi32 name 'CryptEncrypt';

function DescifrarDatos(
  AClave: NativeUInt;
  AHash: NativeUInt;
  AEsFinal: BOOL;
  AOpciones: Cardinal;
  ADatos: PByte;
  ATamanoDatos: PCardinal): BOOL; stdcall;
  external advapi32 name 'CryptDecrypt';

function DestruirClaveCriptografica(
  AClave: NativeUInt): BOOL; stdcall;
  external advapi32 name 'CryptDestroyKey';

function LiberarContextoCriptografico(
  AProveedor: NativeUInt;
  AOpciones: Cardinal): BOOL; stdcall;
  external advapi32 name 'CryptReleaseContext';

procedure LimpiarBytes(var ADatos: TBytes);
begin
  if Length(ADatos) > 0 then
  begin
    FillChar(ADatos[0], Length(ADatos), 0);
  end;
  ADatos := nil;
end;

function CrearBlobClave: TBytes;
var
  aClave: TBytes;
  oCabecera: TCabeceraClave;
  iTamanoClave: Cardinal;
begin
  aClave := TEncoding.ASCII.GetBytes(CLAVE_AES_PREDETERMINADA);
  try
    oCabecera.Tipo := TIPO_CLAVE_PLANA;
    oCabecera.Version := VERSION_BLOB_CLAVE;
    oCabecera.Reservado := 0;
    oCabecera.Algoritmo := ALGORITMO_AES_256;
    iTamanoClave := Length(aClave);
    SetLength(
      Result,
      SizeOf(oCabecera) + SizeOf(iTamanoClave) + iTamanoClave);
    Move(oCabecera, Result[0], SizeOf(oCabecera));
    Move(
      iTamanoClave,
      Result[SizeOf(oCabecera)],
      SizeOf(iTamanoClave));
    Move(
      aClave[0],
      Result[SizeOf(oCabecera) + SizeOf(iTamanoClave)],
      iTamanoClave);
  finally
    LimpiarBytes(aClave);
  end;
end;

function CrearClaveAES(
  const AProveedor: NativeUInt): NativeUInt;
var
  aBlob: TBytes;
  aVector: TBytes;
  iModo: Cardinal;
begin
  Result := 0;
  aBlob := CrearBlobClave;
  aVector := TEncoding.ASCII.GetBytes(VECTOR_AES_PREDETERMINADO);
  try
    try
      if not ImportarClaveCriptografica(
        AProveedor,
        @aBlob[0],
        Length(aBlob),
        0,
        0,
        @Result) then
      begin
        RaiseLastOSError;
      end;
      if not EstablecerParametroClave(
        Result,
        PARAMETRO_VECTOR,
        @aVector[0],
        0) then
      begin
        RaiseLastOSError;
      end;
      iModo := MODO_CBC;
      if not EstablecerParametroClave(
        Result,
        PARAMETRO_MODO,
        PByte(@iModo),
        0) then
      begin
        RaiseLastOSError;
      end;
    except
      if Result <> 0 then
      begin
        DestruirClaveCriptografica(Result);
        Result := 0;
      end;
      raise;
    end;
  finally
    LimpiarBytes(aVector);
    LimpiarBytes(aBlob);
  end;
end;

function ProcesarAES(
  const ADatos: TBytes;
  const ACifrar: Boolean): TBytes;
var
  hProveedor: NativeUInt;
  hClave: NativeUInt;
  iLongitud: Cardinal;
begin
  hProveedor := 0;
  hClave := 0;
  if not AdquirirContextoCriptografico(
    @hProveedor,
    nil,
    PWideChar(PROVEEDOR_AES),
    TIPO_PROVEEDOR_AES,
    VERIFICAR_CONTEXTO) then
  begin
    RaiseLastOSError;
  end;
  try
    hClave := CrearClaveAES(hProveedor);
    if ACifrar then
    begin
      SetLength(Result, Length(ADatos) + TAMANO_BLOQUE_AES);
    end
    else
    begin
      Result := Copy(ADatos);
    end;
    if Length(ADatos) > 0 then
    begin
      Move(ADatos[0], Result[0], Length(ADatos));
    end;
    iLongitud := Length(ADatos);
    if ACifrar then
    begin
      if not CifrarDatos(
        hClave,
        0,
        True,
        0,
        @Result[0],
        @iLongitud,
        Length(Result)) then
      begin
        RaiseLastOSError;
      end;
    end
    else if not DescifrarDatos(
      hClave,
      0,
      True,
      0,
      @Result[0],
      @iLongitud) then
    begin
      RaiseLastOSError;
    end;
    SetLength(Result, iLongitud);
  finally
    if hClave <> 0 then
    begin
      DestruirClaveCriptografica(hClave);
    end;
    LiberarContextoCriptografico(hProveedor, 0);
  end;
end;

function CifrarAES(const ADatos: string): string;
var
  aCifrado: TBytes;
  aOriginal: TBytes;
begin
  aOriginal := TEncoding.UTF8.GetBytes(ADatos);
  try
    aCifrado := ProcesarAES(aOriginal, True);
    try
      Result := TNetEncoding.Base64.EncodeBytesToString(aCifrado);
    finally
      LimpiarBytes(aCifrado);
    end;
  finally
    LimpiarBytes(aOriginal);
  end;
end;

function DescifrarAES(const ADatos: string): string;
var
  aCifrado: TBytes;
  aOriginal: TBytes;
begin
  Result := '';
  try
    aCifrado := TNetEncoding.Base64.DecodeStringToBytes(ADatos);
    try
      if Length(aCifrado) > 0 then
      begin
        aOriginal := ProcesarAES(aCifrado, False);
        try
          Result := TEncoding.UTF8.GetString(aOriginal);
        finally
          LimpiarBytes(aOriginal);
        end;
      end;
    finally
      LimpiarBytes(aCifrado);
    end;
  except
    Result := '';
  end;
end;

function EsCifradoAESValido(const ADatos: string): Boolean;
var
  sDescifrado: string;
begin
  Result := Trim(ADatos) <> '';
  if Result then
  begin
    sDescifrado := DescifrarAES(ADatos);
    Result := CifrarAES(sDescifrado) = ADatos;
  end;
end;

end.
