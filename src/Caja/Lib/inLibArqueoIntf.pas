{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoIntf                                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato del read model utilizado para calcular el arqueo de caja.        }
{******************************************************************************}
unit inLibArqueoIntf;

interface

const
  TipoOpVenta = 'VE';
  TipoOpDevolucion = 'DV';
  TipoOpCobroCuenta = 'CB';
  TipoOpEntradaCambio = 'EC';
  TipoOpGastoCaja = 'GC';
  TipoOpDeposito = 'DE';
  TipoOpValeRedimido = 'VR';
  EstadoDepositoAbierto = 'PENDIENTE';

type
  TArqueoPagoForma = record
    Codigo: string;
    Descripcion: string;
    EsEfectivo: Boolean;
    Importe: Currency;
  end;

  TArqueoCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDate;
    FechaHasta: TDate;
    CantidadVentas: Integer;
    CantidadOperaciones: Integer;
    BrutoLineas: Currency;
    DescuentosLineas: Currency;
    NetoLineas: Currency;
    BrutoOperaciones: Currency;
    DescuentosOperaciones: Currency;
    Neto: Currency;
    Prestamos: Currency;
    Devoluciones: Currency;
    VentasNormales: Currency;
    VentasPrestamos: Currency;
    TotalVentas: Currency;
    ValesRecogidos: Currency;
    ValesEmitidos: Currency;
    CobrosClientes: Currency;
    PendienteCobro: Currency;
    IngresosCaja: Currency;
    EfectivoIngresos: Currency;
    EfectivoEntradas: Currency;
    EfectivoSalidas: Currency;
    EfectivoAnterior: Currency;
    EfectivoCaja: Currency;
    OtrosIngresos: Currency;
    SaldoRecontar: Currency;
    PagosPorForma: TArray<TArqueoPagoForma>;
  end;

  IRepositorioArqueoCaja = interface
    ['{AA6EF4A7-3BC0-4ED3-95C4-E2473B29ACF7}']
    function Calcular(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate): TArqueoCaja;
  end;

implementation

end.
