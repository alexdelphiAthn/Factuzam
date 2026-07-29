{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de persistencia del agregado de sesiones de compra.             }
{******************************************************************************}
unit inLibComprasSesionesIntf;

interface

type
  TCantidadPivotSesion = record
    IdValorPivot: Integer;
    Cantidad: Double;
  end;
  TCantidadesPivotSesion = array of TCantidadPivotSesion;
  IRepositorioComprasSesiones = interface
    ['{85E32940-2F4B-4FF5-B802-9169FD111B88}']
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
  end;

implementation

end.
