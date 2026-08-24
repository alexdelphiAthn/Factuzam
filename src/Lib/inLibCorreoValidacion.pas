{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoValidacion                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación común de destinatarios de correo para cliente y transporte.    }
{******************************************************************************}
unit inLibCorreoValidacion;

interface

function EmailDocumentoValido(const AEmail: string): Boolean;

implementation

uses
  System.SysUtils;

function EsAlfanumericoAscii(ACaracter: Char): Boolean;
begin
  Result := ((ACaracter >= 'A') and (ACaracter <= 'Z')) or
            ((ACaracter >= 'a') and (ACaracter <= 'z')) or
            ((ACaracter >= '0') and (ACaracter <= '9'));
end;

function EsCaracterLocalEmail(ACaracter: Char): Boolean;
begin
  Result := EsAlfanumericoAscii(ACaracter) or
            CharInSet(
              ACaracter,
              ['!', '#', '$', '%', '&', '''', '*', '+', '-', '/', '=',
               '?', '^', '_', '`', '{', '|', '}', '~', '.']);
end;

function EtiquetaDominioValida(
  const ADominio: string;
  AInicio, AFin: Integer): Boolean;
var
  i: Integer;
  iLongitud: Integer;
begin
  Result := False;
  iLongitud := AFin - AInicio + 1;
  if (iLongitud < 1) or (iLongitud > 63) then
    Exit;
  if not EsAlfanumericoAscii(ADominio[AInicio]) then
    Exit;
  if not EsAlfanumericoAscii(ADominio[AFin]) then
    Exit;
  for i := AInicio to AFin do
  begin
    if not EsAlfanumericoAscii(ADominio[i]) and
       (ADominio[i] <> '-') then
      Exit;
  end;
  Result := True;
end;

function EmailDocumentoValido(const AEmail: string): Boolean;
var
  i: Integer;
  iArroba: Integer;
  iInicioEtiqueta: Integer;
  iPuntosDominio: Integer;
  sDominio: string;
  sEmail: string;
  sLocal: string;
begin
  Result := False;
  sEmail := Trim(AEmail);
  if (sEmail = '') or (Length(sEmail) > 254) then
    Exit;

  iArroba := Pos('@', sEmail);
  if iArroba <= 1 then
    Exit;
  if Pos('@', Copy(sEmail, iArroba + 1, MaxInt)) > 0 then
    Exit;

  sLocal := Copy(sEmail, 1, iArroba - 1);
  sDominio := Copy(sEmail, iArroba + 1, MaxInt);
  if Length(sLocal) > 64 then
    Exit;
  if (sDominio = '') or (Length(sDominio) > 253) then
    Exit;
  if (sLocal[1] = '.') or (sLocal[Length(sLocal)] = '.') or
     (Pos('..', sLocal) > 0) then
    Exit;
  for i := 1 to Length(sLocal) do
  begin
    if not EsCaracterLocalEmail(sLocal[i]) then
      Exit;
  end;

  if (sDominio[1] = '.') or
     (sDominio[Length(sDominio)] = '.') or
     (Pos('..', sDominio) > 0) then
    Exit;
  iInicioEtiqueta := 1;
  iPuntosDominio := 0;
  for i := 1 to Length(sDominio) do
  begin
    if sDominio[i] = '.' then
    begin
      if not EtiquetaDominioValida(
        sDominio,
        iInicioEtiqueta,
        i - 1) then
        Exit;
      Inc(iPuntosDominio);
      iInicioEtiqueta := i + 1;
    end;
  end;
  if not EtiquetaDominioValida(
    sDominio,
    iInicioEtiqueta,
    Length(sDominio)) then
    Exit;
  Result := iPuntosDominio > 0;
end;

end.
