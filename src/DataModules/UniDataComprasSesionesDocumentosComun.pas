{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesDocumentosComun                        }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta común de líneas para documentos de compra materializados.        }
{******************************************************************************}
unit UniDataComprasSesionesDocumentosComun;

interface

uses
  inLibComprasSesionesLecturasIntf;

function ConsultarLineasDocumentoCompra(
  const ALecturas: ILecturasDocumentosMaterializacion;
  const ASerieSesion, ANumeroSesion, AAlmacenCabecera,
  AFiltroAlmacen: string): TLineasDocumentoCompraMaterializacion;

implementation
function ConsultarLineasDocumentoCompra(
  const ALecturas: ILecturasDocumentosMaterializacion;
  const ASerieSesion, ANumeroSesion, AAlmacenCabecera,
  AFiltroAlmacen: string): TLineasDocumentoCompraMaterializacion;
begin
  Result := ALecturas.ConsultarLineasDocumento(
    ASerieSesion,
    ANumeroSesion,
    AAlmacenCabecera,
    AFiltroAlmacen);
end;


end.
