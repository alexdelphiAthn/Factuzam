{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaImpresorVenta                                        }
{    Tipo:       Adaptador visual                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador VCL para imprimir tickets y facturas de una venta de caja.      }
{******************************************************************************}
unit inMtoCajaImpresorVenta;

interface

uses
  System.Classes, Uni, inLibParametrosIntf, inLibPermisosIntf,
  inLibCajaTipos, inLibCajaVentaIntf, inLibTicketsCajaIntf;

type
  TImpresorVentaVcl = class(TInterfacedObject, IImpresorVenta)
  private
    FPropietario: TComponent;
    FParametrosApp: IParametrosAplicacion;
    FConexion: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    FPermisos: IPermisosAplicacion;
    FRepositorioTicketsCaja: IRepositorioTicketsCaja;
    procedure ImprimirFacturaA4(
      const ASerie, ANumero: string);
  public
    constructor Create(
      APropietario: TComponent;
      const AParametrosApp: IParametrosAplicacion;
      AConexion: TUniConnection;
      const AParametrosCaja: IParametrosCaja;
      const APermisos: IPermisosAplicacion;
      const ARepositorioTicketsCaja: IRepositorioTicketsCaja);
    procedure Imprimir(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
    procedure GenerarPdfRespaldo(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, UniDataFacturas, inMtoModalImpFac,
  inLibGenerarTicket, inLibGenerarTicketBD, inLibGenerarTicketCaja,
  inLibDir, inLibFacturasComposicion,
  // Raiz de composicion de este servicio: los adaptadores UniData* se
  // construyen aqui y se inyectan en la factoria de dominio.
  UniDataFacturasRepositorio,
  UniDataArticulosResolverRepositorio,
  UniDataVerifactuColaRepositorio;

constructor TImpresorVentaVcl.Create(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const ARepositorioTicketsCaja: IRepositorioTicketsCaja);
begin
  inherited Create;
  FPropietario := APropietario;
  FParametrosApp := AParametrosApp;
  FConexion := AConexion;
  FParametrosCaja := AParametrosCaja;
  FPermisos := APermisos;
  FRepositorioTicketsCaja := ARepositorioTicketsCaja;
end;

procedure TImpresorVentaVcl.ImprimirFacturaA4(
  const ASerie, ANumero: string);
var
  DatosFactura: TdmFacturas;
  Formulario: TfrmPrintFac;
  sRutaPdf: string;
begin
  DatosFactura := TdmFacturas.Create(FPropietario);
  DatosFactura.ConfigurarServicios(
    CrearServiciosFactura(
      FConexion,
      TRepositorioFacturas.Create(FConexion),
      TRepositorioArticulosResolver.Create(
        FConexion,
        FParametrosCaja),
      CrearServicioVerifactuColaUniDAC(FConexion)));
  Formulario := nil;
  try
    Formulario := TfrmPrintFac.Create(Application);
    Formulario.edtSerie.Text := ASerie;
    Formulario.edtNroFac.Text := ANumero;
    Formulario.dmFac := DatosFactura;
    Formulario.ShowModal;
    if not FileExists(Formulario.UltimaRutaPdf) then
    begin
      sRutaPdf := GetUserFolderTickets + 'Factura_' +
        FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.pdf';
      Formulario.ExportarPdfActual(sRutaPdf);
    end;
  finally
    FreeAndNil(Formulario);
    FreeAndNil(DatosFactura);
  end;
end;

procedure TImpresorVentaVcl.Imprimir(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings);
begin
  case ASolicitud.TipoImpresion of
    tiConTicket:
      begin
        ImprimirT(
          FParametrosApp,
          FConexion,
          ASolicitud.CodigoEmpresa,
          ASolicitud.CodigoAlmacen,
          ASolicitud.CodigoCaja,
          ASolicitud.NumeroOperacion,
          ASolicitud.DatosCobro,
          FParametrosCaja.ImpresoraCaja,
          False,
          ASolicitud.FechaOperacion,
          ARutasPdf,
          FParametrosCaja.GetBool(
            'vgerImprimirCodBarrasTicket', False));
      end;
    tiFactura:
      begin
        ImprimirFacturaA4(
          ASolicitud.SerieFactura,
          ASolicitud.NumeroFactura);
      end;
    tiTicketRegalo:
      begin
        ImprimirT(
          FParametrosApp,
          FConexion,
          ASolicitud.CodigoEmpresa,
          ASolicitud.CodigoAlmacen,
          ASolicitud.CodigoCaja,
          ASolicitud.NumeroOperacion,
          ASolicitud.DatosCobro,
          FParametrosCaja.ImpresoraCaja,
          True,
          ASolicitud.FechaOperacion,
          nil,
          FParametrosCaja.GetBool(
            'vgerImprimirCodBarrasTicket', False));
        ImprimirT(
          FParametrosApp,
          FConexion,
          ASolicitud.CodigoEmpresa,
          ASolicitud.CodigoAlmacen,
          ASolicitud.CodigoCaja,
          ASolicitud.NumeroOperacion,
          ASolicitud.DatosCobro,
          FParametrosCaja.ImpresoraCaja,
          False,
          ASolicitud.FechaOperacion,
          ARutasPdf,
          FParametrosCaja.GetBool(
            'vgerImprimirCodBarrasTicket', False));
      end;
    tiSinTicket:
      begin
        AbrirCajonSinVenta(FPermisos, FParametrosCaja);
      end;
  end;
end;

procedure TImpresorVentaVcl.GenerarPdfRespaldo(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings);
begin
  ImprimirTicketDesdeBD(
    FParametrosApp,
    FRepositorioTicketsCaja,
    ASolicitud.CodigoEmpresa,
    ASolicitud.CodigoAlmacen,
    ASolicitud.CodigoCaja,
    ASolicitud.NumeroOperacion,
    'DEBUG',
    ARutasPdf,
    True,
    FParametrosCaja.GetBool(
      'vgerImprimirCodBarrasTicket', False));
end;

end.
