{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaCierreVenta                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina grabación, impresión y archivado del cierre de una venta.        }
{******************************************************************************}
unit inLibCajaCierreVenta;

interface

uses
  inLibParametrosIntf, inLibContextoSesionIntf,
  inLibCajaVentaIntf, inLibFacturasPersistenciaIntf,
  inLibVentasWsColaIntf, inLibLogIntf;

type
  TCasoUsoCierreVentaCaja = class(
    TInterfacedObject,
    ICasoUsoCierreVentaCaja)
  private
    FUnidadTrabajo: IUnidadTrabajoVentaCaja;
    FImpresor: IImpresorVenta;
    FParametrosCaja: IParametrosCaja;
    FContextoSesion: IContextoSesionAplicacion;
    FRepositorioPdf: IRepositorioPdfFactura;
    FRepositorioVentasWs: IRepositorioVentasWsCola;
    FRegistroLog: IRegistroLog;
    procedure ArchivarPdf(
      const ARutaPdf: string;
      const APersistencia: TResultadoPersistenciaVentaCaja);
    function PrepararImpresion(
      const ASolicitud: TSolicitudCierreVenta;
      const APersistencia: TResultadoPersistenciaVentaCaja
    ): TSolicitudImpresionVenta;
  public
    constructor Create(
      const AUnidadTrabajo: IUnidadTrabajoVentaCaja;
      const AImpresor: IImpresorVenta;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const ARepositorioPdf: IRepositorioPdfFactura;
      const ARepositorioVentasWs: IRepositorioVentasWsCola;
      const ARegistroLog: IRegistroLog = nil);
    function Ejecutar(
      const ASolicitud: TSolicitudCierreVenta
    ): TResultadoCierreVenta;
  end;

implementation

uses
  System.SysUtils, System.Classes, inLibVentasWsCola,
  inLibFacturaPdfBlob, inLibRegistroLogNulo;

constructor TCasoUsoCierreVentaCaja.Create(
  const AUnidadTrabajo: IUnidadTrabajoVentaCaja;
  const AImpresor: IImpresorVenta;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const ARepositorioPdf: IRepositorioPdfFactura;
  const ARepositorioVentasWs: IRepositorioVentasWsCola;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FUnidadTrabajo := AUnidadTrabajo;
  FImpresor := AImpresor;
  FParametrosCaja := AParametrosCaja;
  FContextoSesion := AContextoSesion;
  FRepositorioPdf := ARepositorioPdf;
  FRepositorioVentasWs := ARepositorioVentasWs;
  FRegistroLog := ARegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
end;

procedure TCasoUsoCierreVentaCaja.ArchivarPdf(
  const ARutaPdf: string;
  const APersistencia: TResultadoPersistenciaVentaCaja);
var
  sUsuario: string;
begin
  sUsuario := '';
  if Assigned(FContextoSesion) then
    sUsuario := FContextoSesion.Identidad.Usuario;
  TVentasWsCola.AdjuntarTicketPdfSeguro(
    FParametrosCaja,
    FRepositorioVentasWs,
    sUsuario,
    APersistencia.UltimaSerieFactura,
    APersistencia.UltimoNumeroFactura,
    ARutaPdf,
    FRegistroLog);
  GuardarPdfFacturaEnBlob(
    FRepositorioPdf,
    FContextoSesion,
    APersistencia.UltimaSerieFactura,
    APersistencia.UltimoNumeroFactura,
    ARutaPdf,
    'TicketTermico',
    FRegistroLog);
end;

function TCasoUsoCierreVentaCaja.PrepararImpresion(
  const ASolicitud: TSolicitudCierreVenta;
  const APersistencia: TResultadoPersistenciaVentaCaja
): TSolicitudImpresionVenta;
begin
  Result.TipoImpresion := ASolicitud.TipoImpresion;
  Result.CodigoEmpresa := ASolicitud.Grabacion.CodigoEmpresa;
  Result.CodigoAlmacen := ASolicitud.Grabacion.CodigoAlmacen;
  Result.CodigoCaja := ASolicitud.Grabacion.CodigoCaja;
  Result.NumeroOperacion := APersistencia.NumeroOperacion;
  Result.SerieFactura := APersistencia.SerieFacturaImpresion;
  Result.NumeroFactura := APersistencia.NumeroFacturaImpresion;
  Result.FechaOperacion := ASolicitud.Grabacion.FechaOperacion;
  Result.DatosCobro := ASolicitud.Grabacion.DatosCobro;
end;

function TCasoUsoCierreVentaCaja.Ejecutar(
  const ASolicitud: TSolicitudCierreVenta
): TResultadoCierreVenta;
var
  Impresion: TSolicitudImpresionVenta;
  Persistencia: TResultadoPersistenciaVentaCaja;
  RutasPdf: TStringList;
begin
  Result := Default(TResultadoCierreVenta);
  Persistencia := FUnidadTrabajo.Ejecutar(
    ASolicitud.Grabacion);
  Result.Grabada := Persistencia.Grabada;
  Result.NumeroGenerado := Persistencia.NumeroOperacion;
  Result.CodigoValeGenerado :=
    Persistencia.CodigoValeGenerado;
  if Result.Grabada then
  begin
    if Assigned(ASolicitud.Grabacion.DatosCobro) then
    begin
      ASolicitud.Grabacion.DatosCobro.CodigoValeEmitido :=
        Result.CodigoValeGenerado;
    end;
    RutasPdf := TStringList.Create;
    try
      Impresion := PrepararImpresion(
        ASolicitud,
        Persistencia);
      FImpresor.Imprimir(Impresion, RutasPdf);
      if RutasPdf.Count = 0 then
      begin
        try
          FImpresor.GenerarPdfRespaldo(Impresion, RutasPdf);
        except
          on E: Exception do
          begin
            FRegistroLog.RegistrarError(
              'No se pudo generar el PDF de respaldo del ticket ' +
              Persistencia.UltimaSerieFactura + '\' +
              Persistencia.UltimoNumeroFactura + ': ' +
              E.Message);
          end;
        end;
      end;
      if RutasPdf.Count > 0 then
        ArchivarPdf(
          RutasPdf[RutasPdf.Count - 1],
          Persistencia);
    finally
      FreeAndNil(RutasPdf);
    end;
  end;
end;

end.
