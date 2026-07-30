{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTicketsCajaIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Read models para reimpresiones, resguardos y recordatorios de Caja.       }
{******************************************************************************}
unit inLibTicketsCajaIntf;

interface

uses
  System.SysUtils;

type
  TContextoOperacionTicketCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    Operacion: string;
  end;

  TEmpresaResguardoTicketCaja = record
    Encontrada: Boolean;
    RazonSocial: string;
  end;

  TFechaResguardoTicketCaja = record
    Encontrada: Boolean;
    FechaOperacion: TDateTime;
  end;

  TDepositoResguardoTicketCaja = record
    CodigoUnidad: string;
    Descripcion: string;
    CodigoCliente: string;
    TotalPvp: Currency;
  end;

  TEntregaResguardoTicketCaja = record
    TipoOperacion: string;
    Importe: Currency;
    DescripcionArticulo: string;
  end;

  TDevolucionEconomicaTicketCaja = record
    TipoOperacion: string;
    Importe: Currency;
  end;

  TCabeceraTicketCaja = record
    Encontrada: Boolean;
    TipoOperacion: string;
    FechaOperacion: TDateTime;
    InstanteAlta: TDateTime;
    CodigoEmpleado: string;
    DiminutivoVendedor: string;
    CodigoClienteOperacion: string;
    Concepto: string;
    ImporteOperacion: Currency;
    SerieFactura: string;
    NumeroFactura: string;
    FormatoDocumento: string;
    NifEmpresaFactura: string;
    FechaFactura: TDateTime;
    TotalLiquido: Currency;
    RazonSocialEmpresa: string;
    DireccionEmpresa: string;
    CodigoPostalEmpresa: string;
    PoblacionEmpresa: string;
    MovilEmpresa: string;
    TextoLegalEmpresa: string;
    CodigoClienteFactura: string;
    TotalIvaNormal: Currency;
    BaseIvaNormal: Currency;
    PorcentajeIvaNormal: Double;
    TotalIvaReducido: Currency;
    BaseIvaReducido: Currency;
    PorcentajeIvaReducido: Double;
  end;

  TLineaTicketCaja = record
    CodigoUnidad: string;
    TipoCantidad: string;
    Cantidad: Double;
    Total: Currency;
    Descripcion: string;
  end;

  TPagoTicketCaja = record
    CodigoFormaPago: string;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
  end;

  TValeTicketCaja = record
    Codigo: string;
    ImporteNominal: Currency;
  end;

  TEmpresaRecordatorioTicketCaja = record
    Encontrada: Boolean;
    Codigo: string;
    RazonSocial: string;
  end;

  TAnticipoRecordatorioTicketCaja = record
    TipoOperacion: string;
    Importe: Currency;
    FechaOperacion: TDateTime;
    Empresa: string;
    Almacen: string;
    Caja: string;
  end;

  TDepositoPendienteTicketCaja = record
    IdDeposito: string;
    CodigoUnidad: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    Descripcion: string;
    PrecioVenta: Currency;
    FechaCreacion: TDateTime;
    ImporteAnticipo: Currency;
    CantidadPendiente: Double;
    CodigoCliente: string;
    RazonSocialCliente: string;
  end;

  IRepositorioTicketsCaja = interface
    ['{CB27CE3E-B322-4473-B697-79A23C86729D}']
    function ObtenerEmpresaResguardo(
      const AEmpresa: string): TEmpresaResguardoTicketCaja;
    function ObtenerFechaResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TFechaResguardoTicketCaja;
    function ListarNuevosDepositosResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDepositoResguardoTicketCaja>;
    function ListarEntregasResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TEntregaResguardoTicketCaja>;
    function ListarDevolucionesEconomicasResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDevolucionEconomicaTicketCaja>;
    function ListarDepositosDevueltosResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDepositoResguardoTicketCaja>;
    function ObtenerTotalPagadoResguardo(
      const AContexto: TContextoOperacionTicketCaja): Currency;
    function ObtenerCabeceraTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TCabeceraTicketCaja;
    function ListarLineasTicket(
      const ASerie, ANumero: string): TArray<TLineaTicketCaja>;
    function ListarPagosTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TPagoTicketCaja>;
    function ListarValesTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TValeTicketCaja>;
    function ObtenerEmpresaRecordatorio(
      const AEmpresa: string): TEmpresaRecordatorioTicketCaja;
    function ListarAnticiposRecordatorio(
      const AIdDeposito: string):
      TArray<TAnticipoRecordatorioTicketCaja>;
    function ListarDepositosPendientesRecordatorio(
      const ACodigoCliente: string):
      TArray<TDepositoPendienteTicketCaja>;
    function ListarPieTicket(
      const AEmpresa: string): TArray<string>;
    function ObtenerCodigoBarrasTicket(
      const ASerie, ANumero: string): string;
  end;

implementation

end.
