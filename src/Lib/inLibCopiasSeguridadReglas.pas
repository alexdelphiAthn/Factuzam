{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCopiasSeguridadReglas                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Política de protección y restauración según el grupo del usuario.         }
{******************************************************************************}
unit inLibCopiasSeguridadReglas;

interface

uses
  inLibCopiasSeguridadIntf;

type
  TPoliticaCopiasSeguridad = class sealed
  public
    class function ModoCreacion(
      AEsAdministrador: Boolean
    ): TModoProteccionCopia; static;
    class function ExtensionCreacion(
      AEsAdministrador: Boolean
    ): string; static;
    class function EsCopiaCifrada(
      const ARutaFichero: string
    ): Boolean; static;
    class function PuedeRestaurar(
      AEsAdministrador: Boolean;
      const ARutaFichero: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TPoliticaCopiasSeguridad.ModoCreacion(
  AEsAdministrador: Boolean): TModoProteccionCopia;
begin
  if AEsAdministrador then
    Result := mpcTextoPlano
  else
    Result := mpcCifrada;
end;

class function TPoliticaCopiasSeguridad.ExtensionCreacion(
  AEsAdministrador: Boolean): string;
begin
  if ModoCreacion(AEsAdministrador) = mpcTextoPlano then
    Result := '.sql'
  else
    Result := '.crypt';
end;

class function TPoliticaCopiasSeguridad.EsCopiaCifrada(
  const ARutaFichero: string): Boolean;
begin
  Result := SameText(
    ExtractFileExt(ARutaFichero),
    '.crypt');
end;

class function TPoliticaCopiasSeguridad.PuedeRestaurar(
  AEsAdministrador: Boolean;
  const ARutaFichero: string): Boolean;
var
  sExtension: string;
begin
  sExtension := ExtractFileExt(ARutaFichero);
  Result := EsCopiaCifrada(ARutaFichero);
  if AEsAdministrador and SameText(sExtension, '.sql') then
    Result := True;
end;

end.
