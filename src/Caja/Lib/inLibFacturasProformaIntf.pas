{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasProformaIntf                                     }
{    Tipo:       Contrato de aplicación                                        }
{ Versión:       1.2.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para generar documentos desde operaciones de caja. Las         }
{    facturas de traspasos TA se generan con una valoración por línea         }
{    (precio con margen) que el usuario simula antes de generar. La           }
{    modalidad TV factura sólo lo que la tienda destino ya ha vendido.        }
{******************************************************************************}
unit inLibFacturasProformaIntf;

interface

uses
  System.SysUtils;

type
  TModalidadFacturacionCaja = (
    mfcVenta,
    mfcTraspaso,
    // Traspasados y vendidos: sólo las unidades traspasadas a la tienda
    // destino que ésta ha vendido dentro del periodo.
    mfcTraspasoVendido
  );

  TSolicitudFacturacionCaja = record
    FechaDesde          : TDateTime;
    FechaHasta          : TDateTime;
    CodigoEmpresaOrigen : string;
    CodigoEmpresaDestino: string;
    Usuario             : string;
  end;

  TResultadoFacturacionCaja = record
    CantidadDocumentos : Integer;
    CantidadOperaciones: Integer;
    CantidadAjustes    : Integer;
    Descripcion        : string;
  end;

  TRevisionPeriodoFacturacionCaja = record
    EsDuplicado: Boolean;
    EsSolapado : Boolean;
    Descripcion: string;
  end;

  // Línea de traspaso TA pendiente de facturar, con los precios de
  // referencia para valorarla: el coste con el que salió del almacén, el PMP
  // actual de la empresa emisora y la última compra del SKU o artículo.
  TLineaTraspasoPendiente = record
    NumeroMovimiento  : string;
    NumeroOperacion   : string;
    FechaOperacion    : TDateTime;
    Linea             : string;
    CodigoArticulo    : string;
    CodigoUnidad      : string;
    Descripcion       : string;
    Cantidad          : Currency;
    CosteMovimiento   : Currency;
    PrecioMedioEmpresa: Currency;
    PrecioUltimaCompra: Currency;
    // Meses desde la última compra del SKU: el margen mínimo exigible baja
    // por tramos porque el género de temporadas pasadas vale menos.
    AntiguedadMeses   : Integer;
    // Precio medio real sin IVA al que la tienda destino lo ha vendido en
    // el periodo; 0 en la modalidad TA, que no mira ventas.
    PrecioVentaDestino: Currency;
  end;

  TLineasTraspasoPendientes = array of TLineaTraspasoPendiente;

  // Precio unitario sin IVA con el que se facturará cada movimiento.
  TValoracionLineaTraspaso = record
    NumeroMovimiento: string;
    Precio          : Currency;
  end;

  TValoracionTraspasos = array of TValoracionLineaTraspaso;

  IRepositorioFacturasProforma = interface
    ['{FD7857C4-8634-4C19-84F4-BBD9AE6EB082}']
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
    function GenerarVenta(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    // Líneas TA que GenerarTraspasos facturaría con la misma solicitud.
    function ObtenerLineasTraspasoPendientes(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TLineasTraspasoPendientes;
    // Toda línea pendiente debe figurar en la valoración; si alguna falta
    // (p. ej. traspasos nuevos desde la simulación) no se genera nada.
    function GenerarTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AValoracion: TValoracionTraspasos
    ): TResultadoFacturacionCaja;
    // Traspasos TA con unidades vendidas en la tienda destino dentro del
    // periodo y todavía sin facturar; la cantidad de cada línea son las
    // unidades vendidas que se le imputan, no las que salieron del almacén.
    function ObtenerLineasTraspasoVendidoPendientes(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TLineasTraspasoPendientes;
    // El reparto se vuelve a calcular al generar: si aparecen traspasos con
    // unidades vendidas que no figuran en la valoración no se genera nada.
    function GenerarTraspasosVendidos(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AValoracion: TValoracionTraspasos
    ): TResultadoFacturacionCaja;
  end;

implementation

end.
