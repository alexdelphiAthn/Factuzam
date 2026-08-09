{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSeguridadIntf                                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de autorización y auditoría sin dependencia de UniDAC.          }
{******************************************************************************}
unit inLibSeguridadIntf;

interface

uses
  System.SysUtils;

type
  EAccesoContazamDenegado = class(Exception);

  IServicioSeguridadContazam = interface
    ['{2C1E1A54-61B0-43ED-B7A5-F21F54BD9360}']
    function UsuarioActual: string;
    procedure ExigirPermiso(
      const ARecurso: string;
      const AAccion: string;
      const AEmpresa: string);
    procedure ExigirPermisoGlobal(
      const ARecurso: string;
      const AAccion: string);
    procedure RegistrarUsoListado(
      const ARecurso: string;
      const AAccion: string;
      const AEmpresa: string;
      AEjercicio: Integer;
      AFechaDesde: TDate;
      AFechaHasta: TDate;
      const ACuenta: string;
      ANumeroRegistros: Integer;
      const AArchivo: string);
  end;

implementation

end.
