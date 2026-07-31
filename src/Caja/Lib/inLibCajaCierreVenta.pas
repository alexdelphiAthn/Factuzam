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
  inLibVentasWsColaIntf;

type
  TServicioCierreVenta = class(TInterfacedObject, IServicioCierreVenta)
  private
    FGrabador: IGrabadorVentaCaja;
    FImpresor: IImpresorVenta;
    FParametrosCaja: IParametrosCaja;
    FContextoSesion: IContextoSesionAplicacion;
    FRepositorioPdf: IRepositorioPdfFactura;
    FRepositorioVentasWs: IRepositorioVentasWsCola;
    procedure ArchivarPdf(
      const ARutaPdf: string);
    function PrepararImpresion(
      const ASolicitud: TSolicitudCierreVenta;
      const ANumeroGenerado: string
    ): TSolicitudImpresionVenta;
  public
    constructor Create(
      const AGrabador: IGrabadorVentaCaja;
      const AImpresor: IImpresorVenta;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const ARepositorioPdf: IRepositorioPdfFactura;
      const ARepositorioVentasWs: IRepositorioVentasWsCola);
    function Ejecutar(
      const ASolicitud: TSolicitudCierreVenta
    ): TResultadoCierreVenta;
  end;

implementation

uses
  System.SysUtils, System.Classes, inLibVentasWsCola,
  inLibFacturaPdfBlob, inLibLog;

constructor TServicioCierreVenta.Create(
  const AGrabador: IGrabadorVentaCaja;
  const AImpresor: IImpresorVenta;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const ARepositorioPdf: IRepositorioPdfFactura;
  const ARepositorioVentasWs: IRepositorioVentasWsCola);
begin
  inherited Create;
  FGrabador := AGrabador;
  FImpresor := AImpresor;
  FParametrosCaja := AParametrosCaja;
  FContextoSesion := AContextoSesion;
  FRepositorioPdf := ARepositorioPdf;
  FRepositorioVentasWs := ARepositorioVentasWs;
end;

procedure TServicioCierreVenta.ArchivarPdf(
  const ARutaPdf: string);
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
    FGrabador.UltimaSerieFacturaGrabada,
    FGrabador.UltimoNumeroFacturaGrabada,
    ARutaPdf);
  GuardarPdfFacturaEnBlob(
    FRepositorioPdf,
    FContextoSesion,
    FGrabador.UltimaSerieFacturaGrabada,
    FGrabador.UltimoNumeroFacturaGrabada,
    ARutaPdf,
    'TicketTermico');
end;

function TServicioCierreVenta.PrepararImpresion(
  const ASolicitud: TSolicitudCierreVenta;
  const ANumeroGenerado: string
): TSolicitudImpresionVenta;
begin
  Result.TipoImpresion := ASolicitud.TipoImpresion;
  Result.CodigoEmpresa := ASolicitud.Grabacion.CodigoEmpresa;
  Result.CodigoAlmacen := ASolicitud.Grabacion.CodigoAlmacen;
  Result.CodigoCaja := ASolicitud.Grabacion.CodigoCaja;
  Result.NumeroOperacion := ANumeroGenerado;
  Result.SerieFactura := FGrabador.SerieFacturaImpresion;
  Result.NumeroFactura := FGrabador.NumeroFacturaImpresion;
  Result.FechaOperacion := ASolicitud.Grabacion.FechaOperacion;
  Result.DatosCobro := ASolicitud.Grabacion.DatosCobro;
end;

function TServicioCierreVenta.Ejecutar(
  const ASolicitud: TSolicitudCierreVenta
): TResultadoCierreVenta;
var
  Impresion: TSolicitudImpresionVenta;
  RutasPdf: TStringList;
begin
  Result := Default(TResultadoCierreVenta);
  Result.Grabada := FGrabador.GrabarVenta(
    ASolicitud.Grabacion,
    Result.NumeroGenerado,
    Result.CodigoValeGenerado);
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
        Result.NumeroGenerado);
      FImpresor.Imprimir(Impresion, RutasPdf);
      if RutasPdf.Count = 0 then
      begin
        try
          FImpresor.GenerarPdfRespaldo(Impresion, RutasPdf);
        except
          on E: Exception do
          begin
            Log.LogError(
              'No se pudo generar el PDF de respaldo del ticket ' +
              FGrabador.UltimaSerieFacturaGrabada + '\' +
              FGrabador.UltimoNumeroFacturaGrabada + ': ' +
              E.Message);
          end;
        end;
      end;
      if RutasPdf.Count > 0 then
        ArchivarPdf(RutasPdf[RutasPdf.Count - 1]);
    finally
      FreeAndNil(RutasPdf);
    end;
  end;
end;

end.
