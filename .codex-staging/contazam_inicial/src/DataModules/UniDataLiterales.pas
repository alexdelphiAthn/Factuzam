{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLiterales                                            }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia parametrizada de literales traducibles de Contazam.         }
{******************************************************************************}
unit UniDataLiterales;

interface

uses
  Uni, inLibLiteralesIntf;

function CrearRepositorioLiterales(
  AConexion: TUniConnection): IRepositorioLiterales;

implementation

uses
  System.SysUtils, Data.DB;

type
  TRepositorioLiterales = class(
    TInterfacedObject,
    IRepositorioLiterales)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Buscar(
      const AContexto: string;
      const AClave: string;
      const AIdioma: string;
      out ATexto: string): Boolean;
  end;

function CrearRepositorioLiterales(
  AConexion: TUniConnection): IRepositorioLiterales;
begin
  Result := TRepositorioLiterales.Create(AConexion);
end;

constructor TRepositorioLiterales.Create(AConexion: TUniConnection);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioLiterales.Buscar(
  const AContexto: string;
  const AClave: string;
  const AIdioma: string;
  out ATexto: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  ATexto := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT TEXTO_LIT FROM cza_literales ' +
      'WHERE CONTEXTO_LIT = :CONTEXTO ' +
      'AND CLAVE_LIT = :CLAVE ' +
      'AND IDIOMA_LIT = :IDIOMA ' +
      'AND ESACTIVO_LIT = ''S'' LIMIT 1';
    oConsulta.ParamByName('CONTEXTO').AsString :=
      UpperCase(Trim(AContexto));
    oConsulta.ParamByName('CLAVE').AsString :=
      UpperCase(Trim(AClave));
    oConsulta.ParamByName('IDIOMA').AsString := Trim(AIdioma);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      ATexto := oConsulta.FieldByName('TEXTO_LIT').AsString;
      Result := True;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
