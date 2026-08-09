{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPerfilesVentanaTipos                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de datos para personalizar ventanas y columnas por usuario.     }
{******************************************************************************}
unit inLibPerfilesVentanaTipos;

interface

type
  TPerfilVentanaContazam = record
    Nombre: string;
    PosicionIzquierda: Integer;
    PosicionSuperior: Integer;
    Ancho: Integer;
    Alto: Integer;
    Estado: string;
    PestanaActiva: string;
  end;

  TPerfilColumnaContazam = record
    Grid: string;
    Campo: string;
    Nombre: string;
    Orden: Integer;
    EsVisible: Boolean;
    Ancho: Integer;
  end;

  TPerfilesColumnasContazam = TArray<TPerfilColumnaContazam>;

implementation

end.
