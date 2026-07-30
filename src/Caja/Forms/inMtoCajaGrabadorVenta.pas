{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaGrabadorVenta                                        }
{    Tipo:       Adaptador de datos                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta el data module de caja al contrato de grabación de una venta.       }
{******************************************************************************}
unit inMtoCajaGrabadorVenta;

interface

uses
  Data.DB, UniDataCaja, inLibCajaVentaIntf;

type
  TGrabadorVentaCaja = class(TInterfacedObject, IGrabadorVentaCaja)
  private
    FDatosCaja: TdmCajaOpe;
  public
    constructor Create(ADatosCaja: TdmCajaOpe);
    function GrabarVenta(
      const ASolicitud: TSolicitudGrabacionVenta;
      out ANumeroGenerado, ACodigoValeGenerado: string
    ): Boolean;
    function UltimaSerieFacturaGrabada: string;
    function UltimoNumeroFacturaGrabada: string;
    function SerieFacturaImpresion: string;
    function NumeroFacturaImpresion: string;
  end;

implementation

constructor TGrabadorVentaCaja.Create(ADatosCaja: TdmCajaOpe);
begin
  inherited Create;
  FDatosCaja := ADatosCaja;
end;

function TGrabadorVentaCaja.GrabarVenta(
  const ASolicitud: TSolicitudGrabacionVenta;
  out ANumeroGenerado, ACodigoValeGenerado: string
): Boolean;
begin
  Result := FDatosCaja.GrabarFacturaSimplificada(
    ASolicitud.CodigoEmpresa,
    ASolicitud.CodigoAlmacen,
    ASolicitud.CodigoCaja,
    ASolicitud.SerieDocumento,
    ASolicitud.DatosCobro,
    ASolicitud.SerieDocumento,
    ANumeroGenerado,
    ACodigoValeGenerado,
    ASolicitud.TipoFactura,
    ASolicitud.FechaFactura,
    ASolicitud.FechaOperacion,
    ASolicitud.NumeroManual,
    ASolicitud.TipoRectificativa,
    ASolicitud.SerieRectificada,
    ASolicitud.NumeroRectificado,
    ASolicitud.TratamientoMovimientos,
    ASolicitud.MotivoDevolucion,
    ASolicitud.SerieOrigenDevolucion,
    ASolicitud.NumeroOrigenDevolucion,
    ASolicitud.EmpresaOrigenDevolucion,
    ASolicitud.AlmacenOrigenDevolucion);
end;

function TGrabadorVentaCaja.UltimaSerieFacturaGrabada: string;
begin
  Result := FDatosCaja.UltSerieFacturaGrabada;
end;

function TGrabadorVentaCaja.UltimoNumeroFacturaGrabada: string;
begin
  Result := FDatosCaja.UltNumeroFacturaGrabada;
end;

function TGrabadorVentaCaja.SerieFacturaImpresion: string;
begin
  Result := '';
  if FDatosCaja.cdsCabecera.Active and
     (not FDatosCaja.cdsCabecera.IsEmpty) then
  begin
    Result :=
      FDatosCaja.cdsCabecera.FieldByName('SERIE_FAC').AsString;
  end;
end;

function TGrabadorVentaCaja.NumeroFacturaImpresion: string;
begin
  Result := '';
  if FDatosCaja.cdsCabecera.Active and
     (not FDatosCaja.cdsCabecera.IsEmpty) then
  begin
    Result :=
      FDatosCaja.cdsCabecera.FieldByName('NUMERO_FAC').AsString;
  end;
end;

end.
