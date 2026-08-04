{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormatoDocumentoLecturasIntf                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para leer el formato documental de una empresa.                  }
{******************************************************************************}
unit inLibFormatoDocumentoLecturasIntf;

interface

type
  IFormatoDocumentoLecturas = interface
    ['{6B4887F6-110B-4F95-A67A-9E3D8C225C1A}']
    function LeerFormatoEmpresa(
      const ACodigoEmpresa: string): string;
  end;

implementation

end.
