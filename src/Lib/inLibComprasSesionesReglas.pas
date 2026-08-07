{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesReglas                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de compra reutilizables que no dependen de formularios ni del      }
{    módulo de datos de sesiones.                                              }
{******************************************************************************}
unit inLibComprasSesionesReglas;

interface

function SanearColorSku(const ATexto: string): string;
function ResolverCodigoColorBasico(
  const ALiteral: string;
  const ACodigos, ANombres: array of string;
  out ACodigo: string): Boolean;

implementation

uses
  System.SysUtils;

function SanearColorSku(const ATexto: string): string;
var
  cCaracter: Char;
  i: Integer;
  sParcial: string;
begin
  sParcial := UpperCase(Trim(ATexto));
  Result := '';
  for i := 1 to Length(sParcial) do
  begin
    cCaracter := sParcial[i];
    if cCaracter = ' ' then
      Result := Result + '-'
    else if CharInSet(
      cCaracter, ['A'..'Z', '0'..'9', '-', '_']) then
      Result := Result + cCaracter;
  end;
  while Pos('--', Result) > 0 do
    Result := StringReplace(Result, '--', '-', [rfReplaceAll]);
  while Pos('__', Result) > 0 do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);
  while (Result <> '') and
        CharInSet(Result[1], ['-', '_']) do
    Delete(Result, 1, 1);
  while (Result <> '') and
        CharInSet(Result[Length(Result)], ['-', '_']) do
    Delete(Result, Length(Result), 1);
end;

function ResolverCodigoColorBasico(
  const ALiteral: string;
  const ACodigos, ANombres: array of string;
  out ACodigo: string): Boolean;
var
  i: Integer;
  sLiteral: string;
begin
  Result := False;
  ACodigo := '';
  sLiteral := SanearColorSku(ALiteral);
  if sLiteral <> '' then
  begin
    // El codigo tiene prioridad sobre el nombre si una configuracion
    // excepcional hiciera que ambos textos coincidiesen con basicos
    // distintos.
    for i := 0 to High(ACodigos) do
      if SameText(sLiteral, SanearColorSku(ACodigos[i])) then
      begin
        ACodigo := ACodigos[i];
        Exit(True);
      end;
    for i := 0 to High(ACodigos) do
      if (i <= High(ANombres)) and
         SameText(sLiteral, SanearColorSku(ANombres[i])) then
      begin
        ACodigo := ACodigos[i];
        Exit(True);
      end;
  end;
end;

end.
