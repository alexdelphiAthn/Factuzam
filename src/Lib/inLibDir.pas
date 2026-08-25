{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDir                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Acceso a las carpetas de Windows utilizadas por la aplicación.            }
{******************************************************************************}
unit inLibDir;

interface

const
  CSIDL_MYDOCUMENTS = $000C;
  CSIDL_DESKTOPDIRECTORY = $0010;
  CSIDL_LOCAL_APPDATA = $001C;

function DirApp: String;
function GetSpecialFolderPath(ACarpetaCSIDL: Integer): string;
function GetUserFolder: String;
function GetUserDeskFolder: String;
function GetLogFolder: String;
function GetUserFolderTickets: String;

implementation

uses
  Forms, ShlObj, SysUtils, Windows;

function GetSpecialFolderPath(
  ACarpetaCSIDL: Integer): string;
var
  aRuta: array [0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(
       0,
       ACarpetaCSIDL,
       0,
       0,
       aRuta) = S_OK then
    Result := aRuta
  else
    Result := '';
end;

function GetUserFolderTickets: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_LOCAL_APPDATA) +
    '\factuzam\tickets\';
  ForceDirectories(Result);
end;

function GetUserFolder: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_LOCAL_APPDATA) +
    '\factuzam\';
  ForceDirectories(Result);
end;

function GetLogFolder: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_LOCAL_APPDATA) +
    '\factuzam\log\';
  ForceDirectories(
    Result + 'archive\');
  ForceDirectories(Result);
end;

function GetUserDeskFolder: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_DESKTOPDIRECTORY);
end;

function DirApp: String;
begin
  Result := ExtractFilePath(
    Application.ExeName);
end;

end.
