{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMetadatosBBDDIntf                                        }
{    Tipo:       Contrato                                                     }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de acceso al catálogo de metadatos de la base de datos.          }
{******************************************************************************}
unit inLibMetadatosBBDDIntf;

interface

type
  ICatalogoMetadatosBBDD = interface
    ['{FC7B838D-A10A-4772-B0D6-C70BD1F4B12B}']
    procedure Refrescar(const ABaseDatos: string);
    function CargarEstructura(
      const ATipo, ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
  end;

implementation

end.
