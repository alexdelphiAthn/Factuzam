{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaUnidadTrabajo                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta la transacción UniDAC de caja a la unidad de trabajo de venta.     }
{******************************************************************************}
unit UniDataCajaUnidadTrabajo;

interface

uses
  Data.DB, UniDataCaja, inLibCajaVentaIntf;

type
  TUnidadTrabajoVentaCajaUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoVentaCaja)
  private
    FDatosCaja: TdmCajaOpe;
  public
    constructor Create(ADatosCaja: TdmCajaOpe);
    function Ejecutar(
      const ASolicitud: TSolicitudGrabacionVenta
    ): TResultadoPersistenciaVentaCaja;
  end;

implementation

uses
  System.SysUtils;

constructor TUnidadTrabajoVentaCajaUniDAC.Create(
  ADatosCaja: TdmCajaOpe);
begin
  inherited Create;
  if not Assigned(ADatosCaja) then
    raise EArgumentNilException.Create('Falta el data module de caja.');
  FDatosCaja := ADatosCaja;
end;

function TUnidadTrabajoVentaCajaUniDAC.Ejecutar(
  const ASolicitud: TSolicitudGrabacionVenta
): TResultadoPersistenciaVentaCaja;
begin
  Result := Default(TResultadoPersistenciaVentaCaja);
  Result.Grabada := FDatosCaja.GrabarFacturaSimplificada(
    ASolicitud.CodigoEmpresa,
    ASolicitud.CodigoAlmacen,
    ASolicitud.CodigoCaja,
    ASolicitud.SerieDocumento,
    ASolicitud.DatosCobro,
    ASolicitud.SerieDocumento,
    Result.NumeroOperacion,
    Result.CodigoValeGenerado,
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
  if Result.Grabada then
  begin
    Result.UltimaSerieFactura :=
      FDatosCaja.UltSerieFacturaGrabada;
    Result.UltimoNumeroFactura :=
      FDatosCaja.UltNumeroFacturaGrabada;
    if FDatosCaja.cdsCabecera.Active and
       (not FDatosCaja.cdsCabecera.IsEmpty) then
    begin
      Result.SerieFacturaImpresion :=
        FDatosCaja.cdsCabecera.FieldByName('SERIE_FAC').AsString;
      Result.NumeroFacturaImpresion :=
        FDatosCaja.cdsCabecera.FieldByName('NUMERO_FAC').AsString;
    end;
  end;
end;

end.
