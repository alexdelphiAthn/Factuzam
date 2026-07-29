{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaVentaIntf                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de validación, descuento, impresión y cierre de ventas de caja. }
{******************************************************************************}
unit inLibCajaVentaIntf;

interface

uses
  System.Classes, inLibCajaTipos, inLibFaseCobro;

type
  TMotivoStockVenta = (
    msvNinguno,
    msvSkuNoExiste,
    msvSkuInactivo,
    msvSinStock);
  TEntradaPoliticaStockVenta = record
    VerificarExistencia: Boolean;
    Existe: Boolean;
    Activo: Boolean;
    VerificarStock: Boolean;
    BloquearSinStock: Boolean;
    CantidadDisponible: Double;
  end;
  TResultadoPoliticaStockVenta = record
    Permitida: Boolean;
    Motivo: TMotivoStockVenta;
    Mensaje: string;
  end;
  IPoliticaStockVenta = interface
    ['{D2A29706-51CA-48BA-B1AA-BCA539E8D89F}']
    function Validar(
      const ACodigoSku, ACodigoAlmacen: string
    ): TResultadoPoliticaStockVenta;
  end;
  TLineaRepartoDescuento = record
    Cantidad: Double;
    PrecioSalida: Currency;
  end;
  TResultadoLineaDescuento = record
    ImporteDescuento: Currency;
    PrecioConDescuento: Currency;
    PorcentajeDescuento: Double;
  end;
  IRepartidorDescuento = interface
    ['{6D3299DA-C682-4D6E-9B72-D94C5F8547F3}']
    function Repartir(
      const ALineas: TArray<TLineaRepartoDescuento>;
      AImporteDescuento: Currency
    ): TArray<TResultadoLineaDescuento>;
  end;
  TSolicitudImpresionVenta = record
    TipoImpresion: TTipoImpresionVenta;
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    NumeroOperacion: string;
    SerieFactura: string;
    NumeroFactura: string;
    FechaOperacion: TDateTime;
    DatosCobro: TDatosFaseCobro;
  end;
  IImpresorVenta = interface
    ['{77199D03-7606-4B57-A046-BBBEC3E7D60A}']
    procedure Imprimir(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
    procedure GenerarPdfRespaldo(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
  end;
  TSolicitudGrabacionVenta = record
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    SerieDocumento: string;
    TipoFactura: string;
    FechaFactura: TDateTime;
    FechaOperacion: TDateTime;
    NumeroManual: string;
    TipoRectificativa: TTipoRectificativaCaja;
    SerieRectificada: string;
    NumeroRectificado: string;
    TratamientoMovimientos:
      TTratamientoMovimientosRectificativa;
    DatosCobro: TDatosFaseCobro;
  end;
  IGrabadorVentaCaja = interface
    ['{B5A33934-55EC-41B1-83B2-AEB0FBAA07BD}']
    function GrabarVenta(
      const ASolicitud: TSolicitudGrabacionVenta;
      out ANumeroGenerado, ACodigoValeGenerado: string
    ): Boolean;
    function UltimaSerieFacturaGrabada: string;
    function UltimoNumeroFacturaGrabada: string;
    function SerieFacturaImpresion: string;
    function NumeroFacturaImpresion: string;
  end;
  TSolicitudCierreVenta = record
    Grabacion: TSolicitudGrabacionVenta;
    TipoImpresion: TTipoImpresionVenta;
  end;
  TResultadoCierreVenta = record
    Grabada: Boolean;
    NumeroGenerado: string;
    CodigoValeGenerado: string;
  end;
  IServicioCierreVenta = interface
    ['{78B5CC6D-7852-4944-995D-F6ED0EFA7B58}']
    function Ejecutar(
      const ASolicitud: TSolicitudCierreVenta
    ): TResultadoCierreVenta;
  end;

function EvaluarPoliticaStockVenta(
  const AEntrada: TEntradaPoliticaStockVenta
): TResultadoPoliticaStockVenta;

implementation

function EvaluarPoliticaStockVenta(
  const AEntrada: TEntradaPoliticaStockVenta
): TResultadoPoliticaStockVenta;
begin
  Result.Permitida := True;
  Result.Motivo := msvNinguno;
  Result.Mensaje := '';
  if AEntrada.VerificarExistencia and (not AEntrada.Existe) then
  begin
    Result.Permitida := False;
    Result.Motivo := msvSkuNoExiste;
  end
  else if AEntrada.VerificarExistencia and (not AEntrada.Activo) then
  begin
    Result.Permitida := False;
    Result.Motivo := msvSkuInactivo;
  end
  else if AEntrada.VerificarStock and
          (AEntrada.CantidadDisponible <= 0) then
  begin
    Result.Permitida := not AEntrada.BloquearSinStock;
    Result.Motivo := msvSinStock;
  end;
end;

end.
