{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLogIntf                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato mínimo de registro para colaboradores de la aplicación.         }
{******************************************************************************}
unit inLibLogIntf;

interface

type
  IRegistroLog = interface
    ['{97324860-FA85-460F-92D2-9B0E1C95588C}']
    procedure RegistrarInformacion(const AMensaje: string);
    procedure RegistrarAviso(const AMensaje: string);
    procedure RegistrarError(const AMensaje: string);
    procedure RegistrarRendimiento(
      const AEtiqueta, ADetalle: string;
      ADuracionMs: Int64);
  end;

implementation

end.
