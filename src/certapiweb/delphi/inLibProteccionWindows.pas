{******************************************************************************}
{                                                                              }
{  Módulo:       inLibProteccionWindows                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Protege la clave privada mediante DPAPI del usuario actual de Windows.    }
{******************************************************************************}

unit inLibProteccionWindows;

interface

uses
  System.SysUtils;

type
  TProteccionWindows = class
  public
    class function Proteger(const ADatos: TBytes): TBytes; static;
    class function Desproteger(const ADatos: TBytes): TBytes; static;
  end;

implementation

uses
  Winapi.Windows;

const
  CRYPTPROTECT_UI_FORBIDDEN = $00000001;

type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

function CryptProtectData(
  pDataIn: PDataBlob;
  szDataDescr: LPCWSTR;
  pOptionalEntropy: PDataBlob;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';

function CryptUnprotectData(
  pDataIn: PDataBlob;
  ppszDataDescr: PLPWSTR;
  pOptionalEntropy: PDataBlob;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';

procedure PrepararBlob(const ADatos: TBytes; out ABlob: TDataBlob);
begin
  FillChar(ABlob, SizeOf(ABlob), 0);
  ABlob.cbData := Length(ADatos);
  if Length(ADatos) > 0 then
    ABlob.pbData := @ADatos[0];
end;

function CopiarBlob(const ABlob: TDataBlob): TBytes;
begin
  SetLength(Result, ABlob.cbData);
  if ABlob.cbData > 0 then
    Move(ABlob.pbData^, Result[0], ABlob.cbData);
end;

class function TProteccionWindows.Proteger(
  const ADatos: TBytes): TBytes;
var
  oEntrada: TDataBlob;
  oSalida: TDataBlob;
begin
  if Length(ADatos) = 0 then
    raise Exception.Create('No hay datos privados que proteger.');
  PrepararBlob(ADatos, oEntrada);
  FillChar(oSalida, SizeOf(oSalida), 0);
  if not CryptProtectData(@oEntrada, 'CertApiWeb', nil, nil, nil,
                          CRYPTPROTECT_UI_FORBIDDEN, @oSalida) then
    RaiseLastOSError;
  try
    Result := CopiarBlob(oSalida);
  finally
    if oSalida.pbData <> nil then
      LocalFree(HLOCAL(oSalida.pbData));
  end;
end;

class function TProteccionWindows.Desproteger(
  const ADatos: TBytes): TBytes;
var
  oEntrada: TDataBlob;
  oSalida: TDataBlob;
begin
  if Length(ADatos) = 0 then
    raise Exception.Create('El almacén privado está vacío.');
  PrepararBlob(ADatos, oEntrada);
  FillChar(oSalida, SizeOf(oSalida), 0);
  if not CryptUnprotectData(@oEntrada, nil, nil, nil, nil,
                            CRYPTPROTECT_UI_FORBIDDEN, @oSalida) then
    RaiseLastOSError;
  try
    Result := CopiarBlob(oSalida);
  finally
    if oSalida.pbData <> nil then
    begin
      if oSalida.cbData > 0 then
        FillChar(oSalida.pbData^, oSalida.cbData, 0);
      LocalFree(HLOCAL(oSalida.pbData));
    end;
  end;
end;

end.
