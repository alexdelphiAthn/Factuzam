{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConfiguracionIni                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura, escritura y resolución del INI principal de la aplicación.       }
{******************************************************************************}
unit inLibConfiguracionIni;

interface

function ConstruirRutaIni(
  const ADirectorio: string;
  const AEjecutable: string;
  const AParametro: string): string;
function RutaIniAplicacion(
  const ADirectorio: string): string;
function LeerCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValorPredeterminado: string;
  const ADirectorio: string): string;
procedure EscribirCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValor: string;
  const ADirectorio: string);

implementation

uses
  System.IniFiles, System.SysUtils;

function ConstruirRutaIni(
  const ADirectorio: string;
  const AEjecutable: string;
  const AParametro: string): string;
var
  sParametro: string;
  sNombreFichero: string;
begin
  sParametro := Trim(AParametro);
  if (sParametro <> '') and
     CharInSet(sParametro[1], ['/', '-']) then
    sParametro := '';
  if sParametro = '' then
    sNombreFichero := ChangeFileExt(
      ExtractFileName(AEjecutable),
      '.ini')
  else
    sNombreFichero := sParametro;
  Result := ADirectorio + sNombreFichero;
end;

function RutaIniAplicacion(
  const ADirectorio: string): string;
begin
  Result := ConstruirRutaIni(
    ADirectorio,
    ParamStr(0),
    ParamStr(1));
end;

procedure EscribirCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValor: string;
  const ADirectorio: string);
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(
    RutaIniAplicacion(ADirectorio));
  try
    oIni.WriteString(
      ASeccion,
      AClave,
      AValor);
  finally
    FreeAndNil(oIni);
  end;
end;

function LeerCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValorPredeterminado: string;
  const ADirectorio: string): string;
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(
    RutaIniAplicacion(ADirectorio));
  try
    Result := oIni.ReadString(
      ASeccion,
      AClave,
      AValorPredeterminado);
    if Result = AValorPredeterminado then
    begin
      EscribirCadenaIni(
        ASeccion,
        AClave,
        AValorPredeterminado,
        ADirectorio);
    end;
  finally
    FreeAndNil(oIni);
  end;
end;

end.
