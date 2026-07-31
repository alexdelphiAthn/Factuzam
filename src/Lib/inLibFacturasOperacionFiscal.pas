{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasOperacionFiscal                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara operaciones fiscales y construye su solicitud de emisión.         }
{******************************************************************************}
unit inLibFacturasOperacionFiscal;

interface

uses
  inLibEmisionFiscalIntf;

type
  TContextoOperacionFiscalFactura = record
    Serie: string;
    Numero: string;
    TipoFactura: string;
    TipoOperacion: string;
    Accion: string;
    Usuario: string;
    Consolidada: Boolean;
  end;
  TPreparacionOperacionFiscalFactura = record
    EsValida: Boolean;
    MensajeError: string;
    PreguntaConfirmacion: string;
    SolicitaDecisionBorrarMovimientos: Boolean;
    PreguntaBorrarMovimientos: string;
  end;

function PrepararOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura
): TPreparacionOperacionFiscalFactura;
function CrearSolicitudOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura;
  ABorrarMovimientos: Boolean
): TSolicitudEmisionFiscal;

implementation

uses
  System.SysUtils, inLibMsgFacturas;

function PrepararOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura
): TPreparacionOperacionFiscalFactura;
begin
  Result := Default(TPreparacionOperacionFiscalFactura);
  if Trim(AContexto.Numero) = '' then
  begin
    Result.MensajeError := SErrorBorradorListaNoSeleccionado;
  end
  else if not AContexto.Consolidada then
  begin
    Result.MensajeError := Format(
      SErrorBorradorNoCerradoAccionFiscal,
      [AContexto.Serie,
       AContexto.Numero,
       LowerCase(AContexto.Accion)]);
  end
  else
  begin
    Result.EsValida := True;
    Result.PreguntaConfirmacion := Format(
      SPreguntaAccionFiscalBorrador,
      [AContexto.Accion,
       AContexto.Serie,
       AContexto.Numero]);
    Result.SolicitaDecisionBorrarMovimientos :=
      SameText(AContexto.TipoOperacion, 'ANULACION') and
      SameText(AContexto.TipoFactura, 'SIMPLIFICADA');
    if Result.SolicitaDecisionBorrarMovimientos then
    begin
      Result.PreguntaBorrarMovimientos := Format(
        SPreguntaBorrarMovimientosTicketAnulado,
        [AContexto.Serie,
         AContexto.Numero]);
    end;
  end;
end;

function CrearSolicitudOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura;
  ABorrarMovimientos: Boolean
): TSolicitudEmisionFiscal;
begin
  Result := TSolicitudEmisionFiscal.ParaOperacion(
    AContexto.Serie,
    AContexto.Numero,
    AContexto.Usuario,
    AContexto.TipoOperacion,
    AContexto.Accion,
    ABorrarMovimientos);
end;

end.
