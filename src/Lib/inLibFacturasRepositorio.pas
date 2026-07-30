{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasRepositorio                                      }
{    Tipo:       Fachada                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada temporal del repositorio trasladado a persistencia.               }
{******************************************************************************}
unit inLibFacturasRepositorio;

interface

uses
  UniDataFacturasRepositorio;

type
  TRepositorioFacturas =
    UniDataFacturasRepositorio.TRepositorioFacturas;

implementation

end.
