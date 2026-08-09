{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDir                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Acceso centralizado a las carpetas locales usadas por Contazam.           }
{******************************************************************************}
unit inLibDir;

interface

function DirApp: string;
function GetLogFolder: string;

implementation

uses
  System.SysUtils, System.IOUtils, Vcl.Forms;

function DirApp: string;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

function GetLogFolder: string;
var
  sBaseLocal: string;
begin
  sBaseLocal := GetEnvironmentVariable('LOCALAPPDATA');
  if Trim(sBaseLocal) = '' then
  begin
    sBaseLocal := DirApp;
  end;
  Result := TPath.Combine(sBaseLocal, 'Contazam');
  Result := TPath.Combine(Result, 'log');
  ForceDirectories(TPath.Combine(Result, 'archive'));
  ForceDirectories(Result);
end;

end.
