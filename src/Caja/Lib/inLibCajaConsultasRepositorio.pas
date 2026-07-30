{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaConsultasRepositorio                                 }
{    Tipo:       Fachada                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada temporal del repositorio trasladado a persistencia de caja.       }
{******************************************************************************}
unit inLibCajaConsultasRepositorio;

interface

uses
  UniDataCajaConsultasRepositorio;

type
  TConsultaCaja =
    UniDataCajaConsultasRepositorio.TConsultaCaja;
  TRepositorioConsultasCaja =
    UniDataCajaConsultasRepositorio.TRepositorioConsultasCaja;

implementation

end.
