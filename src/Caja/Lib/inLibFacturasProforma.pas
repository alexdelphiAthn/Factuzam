{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasProforma                                         }
{    Tipo:       Servicio de aplicación                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida y dirige la generación VE o TA al repositorio correspondiente.    }
{******************************************************************************}
unit inLibFacturasProforma;

interface

uses
  System.SysUtils,
  inLibFacturasProformaIntf;

type
  TFacturadorOperacionesCaja = class
  private
    FRepositorio: IRepositorioFacturasProforma;
    procedure ValidarModalidad(
      AModalidad: TModalidadFacturacionCaja);
    procedure ValidarSolicitud(
      const ASolicitud: TSolicitudFacturacionCaja);
  public
    constructor Create(
      const ARepositorio: IRepositorioFacturasProforma);
    function Ejecutar(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
  end;

resourcestring
  SErrorRepositorioFacturacionCajaNoDisponible =
    'No está disponible el repositorio de facturación de caja.';
  SErrorPeriodoFacturacionCajaObligatorio =
    'Debe indicar las fechas inicial y final del periodo.';
  SErrorPeriodoFacturacionCajaInvalido =
    'La fecha inicial no puede ser posterior a la fecha final.';
  SErrorEmpresaDestinoFacturacionCajaObligatoria =
    'Debe seleccionar una empresa destino.';
  SErrorUsuarioFacturacionCajaObligatorio =
    'No se ha podido identificar al usuario que genera los documentos.';
  SErrorModalidadFacturacionCajaInvalida =
    'La modalidad de facturación de caja no es válida.';

implementation

constructor TFacturadorOperacionesCaja.Create(
  const ARepositorio: IRepositorioFacturasProforma);
begin
  inherited Create;
  if ARepositorio = nil then
    raise EArgumentNilException.Create(
      SErrorRepositorioFacturacionCajaNoDisponible);
  FRepositorio := ARepositorio;
end;

procedure TFacturadorOperacionesCaja.ValidarSolicitud(
  const ASolicitud: TSolicitudFacturacionCaja);
begin
  if (ASolicitud.FechaDesde = 0) or
     (ASolicitud.FechaHasta = 0) then
    raise EArgumentException.Create(
      SErrorPeriodoFacturacionCajaObligatorio);
  if Trunc(ASolicitud.FechaDesde) > Trunc(ASolicitud.FechaHasta) then
    raise EArgumentException.Create(
      SErrorPeriodoFacturacionCajaInvalido);
  if Trim(ASolicitud.CodigoEmpresaDestino) = '' then
    raise EArgumentException.Create(
      SErrorEmpresaDestinoFacturacionCajaObligatoria);
  if Trim(ASolicitud.Usuario) = '' then
    raise EArgumentException.Create(
      SErrorUsuarioFacturacionCajaObligatorio);
end;

procedure TFacturadorOperacionesCaja.ValidarModalidad(
  AModalidad: TModalidadFacturacionCaja);
begin
  if not (AModalidad in [mfcVenta, mfcTraspaso]) then
    raise EArgumentOutOfRangeException.Create(
      SErrorModalidadFacturacionCajaInvalida);
end;

function TFacturadorOperacionesCaja.Ejecutar(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
begin
  ValidarSolicitud(ASolicitud);
  ValidarModalidad(AModalidad);
  case AModalidad of
    mfcVenta:
      Result := FRepositorio.GenerarVenta(ASolicitud);
    mfcTraspaso:
      Result := FRepositorio.GenerarTraspasos(ASolicitud);
  end;
end;

function TFacturadorOperacionesCaja.RevisarPeriodo(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TRevisionPeriodoFacturacionCaja;
begin
  ValidarSolicitud(ASolicitud);
  ValidarModalidad(AModalidad);
  Result := FRepositorio.RevisarPeriodo(AModalidad, ASolicitud);
end;

end.
