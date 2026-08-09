{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLiteralesIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos independientes para recuperar y resolver textos traducibles.    }
{******************************************************************************}
unit inLibLiteralesIntf;

interface

type
  IRepositorioLiterales = interface
    ['{EF85C7A4-F081-455A-B829-7AA11231FECB}']
    function Buscar(
      const AContexto: string;
      const AClave: string;
      const AIdioma: string;
      out ATexto: string): Boolean;
  end;

  IServicioLiterales = interface
    ['{2FF9BC00-52E5-40EF-A648-346B31735567}']
    function IdiomaActual: string;
    function Resolver(
      const AContexto: string;
      const AClave: string;
      const ATextoPorDefecto: string = ''): string;
  end;

implementation

end.
