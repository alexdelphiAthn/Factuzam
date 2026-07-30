{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosAtributosLookup                                 }
{    Tipo:       Fachada                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada temporal del contrato de atributos de artículos.                  }
{******************************************************************************}
unit inLibArticulosAtributosLookup;

interface

uses
  Uni,
  inLibArticulosAtributosIntf,
  UniDataArticulosAtributosRepositorio;

type
  TTipoValorPropiedad =
    inLibArticulosAtributosIntf.TTipoValorPropiedad;
  TArticuloAtributoValor =
    inLibArticulosAtributosIntf.TArticuloAtributoValor;
  TArticuloAtributo =
    inLibArticulosAtributosIntf.TArticuloAtributo;
  TArticuloPropiedad =
    inLibArticulosAtributosIntf.TArticuloPropiedad;
  IArticulosAtributosLookup =
    inLibArticulosAtributosIntf.IArticulosAtributosLookup;
  TArticulosAtributosLookup =
    UniDataArticulosAtributosRepositorio.
      TRepositorioArticulosAtributos;

function CrearLookupAtributosArticulosBase(
  AConexion: TUniConnection): IArticulosAtributosLookup;

implementation

function CrearLookupAtributosArticulosBase(
  AConexion: TUniConnection): IArticulosAtributosLookup;
begin
  Result := TRepositorioArticulosAtributos.Create(
    AConexion);
end;

end.
