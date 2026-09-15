{******************************************************************************}
{                                                                              }
{                        Módulo: inLibPresupuestosIntf                         }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibPresupuestosIntf;

interface

uses
  inLibDocumentoIntf;

type
  TDestinoPresupuesto = (dpPedido, dpAlbaran, dpFactura);

  TSolicitudConversionPresupuesto = record
    Destino: TDestinoPresupuesto;
    Serie: string;
    Numero: string;
    Usuario: string;
  end;

  TResultadoConversionPresupuesto = record
    TipoDocumento: TTipoDocumento;
    Pantalla: string;
    Serie: string;
    Numero: string;
  end;

function CrearSolicitudConversionPresupuesto(
  ADestino: TDestinoPresupuesto;
  const ASerie, ANumero, AUsuario: string):
  TSolicitudConversionPresupuesto;
function TipoDestinoPresupuesto(ADestino: TDestinoPresupuesto):
  TTipoDocumento;
function PantallaDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;

implementation

function CrearSolicitudConversionPresupuesto(
  ADestino: TDestinoPresupuesto;
  const ASerie, ANumero, AUsuario: string):
  TSolicitudConversionPresupuesto;
begin
  Result.Destino := ADestino;
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Usuario := AUsuario;
end;

function TipoDestinoPresupuesto(ADestino: TDestinoPresupuesto):
  TTipoDocumento;
const
  TIPOS: array[TDestinoPresupuesto] of TTipoDocumento =
    (tdPedido, tdAlbaran, tdFactura);
begin
  Result := TIPOS[ADestino];
end;

function PantallaDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;
const
  PANTALLAS: array[TDestinoPresupuesto] of string =
    ('Pedidos', 'Albaranes', 'Facturas');
begin
  Result := PANTALLAS[ADestino];
end;

end.
