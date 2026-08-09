{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContadoresIntf                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato mínimo de numeración documental para los casos de uso.           }
{******************************************************************************}
unit inLibContadoresIntf;

interface

type
  IContadorDocumentos = interface
    ['{D2199B24-EF62-49F5-BFD6-53DD1039F86F}']
    function SiguienteNumero(
      const AEmpresa: string;
      AEjercicio: Integer;
      const ATipoDocumento: string;
      const ASerie: string): Int64;
  end;

implementation

end.

