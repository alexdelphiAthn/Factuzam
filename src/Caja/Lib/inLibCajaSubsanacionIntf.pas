{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaSubsanacionIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Corrección de importes y cobro conservando la identidad de la operación.  }
{******************************************************************************}
unit inLibCajaSubsanacionIntf;

interface

uses
  inLibCajaSubsanacion, inLibCorreccionPagoIntf;

type
  TClaveOperacionSubsanacionCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
    SerieFactura: string;
    NumeroFactura: string;
  end;

  // Cobro vigente o nuevo, neto de cambio, en euros.
  TPagoSubsanacionCaja = record
    FormaPago: string;
    Referencia: string;
    Importe: Currency;
  end;
  TPagosSubsanacionCaja = TArray<TPagoSubsanacionCaja>;

  TOperacionSubsanacionCaja = record
    Clave: TClaveOperacionSubsanacionCaja;
    FechaFactura: TDateTime;
    Lineas: TLineasSubsanacionCaja;
    Total: Currency;
    Pagos: TPagosSubsanacionCaja;
    Version: string;
  end;

  TSolicitudSubsanacionCaja = record
    Original: TOperacionSubsanacionCaja;
    Lineas: TLineasSubsanacionCaja;
    // Si difieren de Original.Pagos se compensan los vigentes y se dan de
    // alta estos, como en la corrección de forma de pago.
    Pagos: TPagosSubsanacionCaja;
    Motivo: string;
  end;

  TResultadoSubsanacionCaja = record
    Clave: TClaveOperacionSubsanacionCaja;
    Total: Currency;
    EncoladaVerifactu: Boolean;
    RegistradaNoVerifactu: Boolean;
  end;

  IServicioSubsanacionCaja = interface
    ['{FBC3BA3E-6AFA-4C39-A596-0C742E67A808}']
    function Cargar(const AClave: TClaveOperacionSubsanacionCaja):
      TOperacionSubsanacionCaja;
    function Medios: TArray<TMedioCorreccionPago>;
    function Guardar(const ASolicitud: TSolicitudSubsanacionCaja):
      TResultadoSubsanacionCaja;
  end;

implementation

end.
