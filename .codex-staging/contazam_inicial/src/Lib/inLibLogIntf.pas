{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLogIntf                                                  }
{    Tipo:       Interfaz                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de registro local inyectable para la aplicación Contazam.        }
{******************************************************************************}
unit inLibLogIntf;

interface

uses
  System.SysUtils;

type
  IRegistroLogContazam = interface
    ['{8C40EC4F-E027-419D-9A81-993BFA8699CC}']
    procedure RegistrarInformacion(const AMensaje: string);
    procedure RegistrarAviso(const AMensaje: string);
    procedure RegistrarError(const AMensaje: string);
    procedure RegistrarExcepcion(
      const AContexto: string;
      E: Exception);
    function RutaArchivo: string;
    function RutaCarpeta: string;
  end;

implementation

end.
