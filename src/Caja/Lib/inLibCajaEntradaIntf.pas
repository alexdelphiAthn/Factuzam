{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaEntradaIntf                                          }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de entrada de artículos de caja sin dependencias visuales.     }
{******************************************************************************}
unit inLibCajaEntradaIntf;

interface

type
  IVistaEntradaCaja = interface
    ['{71358C32-91A4-4F6B-A6DD-632B54A9C878}']
    procedure MostrarError(const AMensaje: string);
    procedure EnfocarVendedor;
    procedure PrepararLectura;
    procedure RefrescarConsolidacion;
    procedure PrepararSiguiente;
  end;
  IOperacionesEntradaCaja = interface
    ['{0BF2715C-D462-4497-92B8-967134BD55CD}']
    function Disponible: Boolean;
    function VendedorAsignado: Boolean;
    function PermitirSku(const ACodigoSku: string): Boolean;
    procedure PrepararLinea;
    function ConsolidarSku(const ACodigoSku: string): Boolean;
    procedure AplicarCodigo(
      const ACodigo, ACodigoSku, ACodigoArticulo: string);
    procedure Iniciar;
    procedure Finalizar;
  end;
  IAplicacionEntradaCaja = interface
    ['{C7776D8B-602D-42E9-BCB3-43D6A78EE0E6}']
    procedure Procesar(const ACodigo: string);
  end;

implementation

end.
