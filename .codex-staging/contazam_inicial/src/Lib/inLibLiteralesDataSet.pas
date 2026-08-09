{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLiteralesDataSet                                       }
{    Tipo:       Adaptador                                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Aplica textos comprensibles a los campos de un conjunto de datos.         }
{******************************************************************************}
unit inLibLiteralesDataSet;

interface

uses
  Data.DB, inLibLiteralesIntf;

procedure AplicarEtiquetasLiterales(
  ADatos: TDataSet;
  const AContexto: string;
  const AServicio: IServicioLiterales);

implementation

uses
  System.SysUtils, inLibLiterales;

procedure AplicarEtiquetasLiterales(
  ADatos: TDataSet;
  const AContexto: string;
  const AServicio: IServicioLiterales);
var
  oCampo: TField;
begin
  if ADatos = nil then
  begin
    raise EArgumentNilException.Create('ADatos');
  end;
  if AServicio = nil then
  begin
    raise EArgumentNilException.Create('AServicio');
  end;
  for oCampo in ADatos.Fields do
  begin
    oCampo.DisplayLabel := AServicio.Resolver(
      AContexto,
      oCampo.FieldName,
      TextoCampoAmigable(oCampo.FieldName));
  end;
end;

end.
