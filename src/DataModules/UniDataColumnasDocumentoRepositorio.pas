{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataColumnasDocumentoRepositorio                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de nombres de atributos globales de documentos.          }
{******************************************************************************}
unit UniDataColumnasDocumentoRepositorio;

interface

uses
  Uni, inLibColumnasDocumentoLecturasIntf;

function CrearColumnasDocumentoLecturas(
  AConexion: TUniConnection): IColumnasDocumentoLecturas;

implementation

uses
  System.SysUtils;

type
  TColumnasDocumentoLecturas = class(
    TInterfacedObject,
    IColumnasDocumentoLecturas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarNombresAtributosGlobales: TArray<string>;
  end;

function CrearColumnasDocumentoLecturas(
  AConexion: TUniConnection): IColumnasDocumentoLecturas;
begin
  Result := TColumnasDocumentoLecturas.Create(AConexion);
end;

constructor TColumnasDocumentoLecturas.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TColumnasDocumentoLecturas.
  ListarNombresAtributosGlobales: TArray<string>;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE,' +
      '       MIN(ORDEN_VA) AS ORDEN' +
      '  FROM fza_variaciones_atributos' +
      ' GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA)' +
      ' ORDER BY ORDEN, NOMBRE LIMIT 5';
    oConsulta.Open;
    while (not oConsulta.Eof) and (Length(Result) < 5) do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice] := oConsulta.FieldByName('NOMBRE').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
