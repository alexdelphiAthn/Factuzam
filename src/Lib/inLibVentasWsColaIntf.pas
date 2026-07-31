{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsColaIntf                                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia de la cola transaccional de eventos de venta       }
{    para el webservice de respaldo.                                           }
{******************************************************************************}
unit inLibVentasWsColaIntf;

interface

uses
  Uni;

type
  TFilaVentasWsCola = record
    IdEvento: string;
    Empresa: string;
    Serie: string;
    Numero: string;
    TipoEvento: string;
    Intentos: Integer;
    Contenido: string;
  end;
  IRepositorioVentasWsCola = interface
    ['{3F278436-0936-47F8-B8DD-D024273A4851}']
    function Encolar(
      const AIdEvento, ATipoEvento, ASerie, ANumero,
        AUsuario: string): Int64;
    function ActualizarPdfVentaPendiente(
      AEsFactura: Boolean;
      const ASerie, ANumero, ARutaPdf, AUsuario: string): Boolean;
    procedure ActualizarPdfPorId(
      AEsFactura: Boolean;
      AIdCola: Int64;
      const ARutaPdf, AUsuario: string);
    procedure ReencolarProcesandoCaducadas;
    function BuscarPendientes(
      AMaximo: Integer): TArray<Int64>;
    function MarcarProcesando(
      AIdCola: Int64;
      const AUsuario: string): Boolean;
    function LeerFila(
      AIdCola: Int64): TFilaVentasWsCola;
    procedure GuardarContenido(
      AIdCola: Int64;
      const AContenido, AHuella: string);
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AIdPeticion, AUsuario: string);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string);
  end;
  TFabricaCrearRepositorioVentasWsCola = function(
    AConexion: TUniConnection): IRepositorioVentasWsCola;

implementation
end.
