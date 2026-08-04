{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasProformaIntf                                     }
{    Tipo:       Contrato de aplicación                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para generar documentos desde operaciones de caja.             }
{******************************************************************************}
unit inLibFacturasProformaIntf;

interface

uses
  System.SysUtils;

type
  TModalidadFacturacionCaja = (
    mfcVenta,
    mfcTraspaso
  );

  TSolicitudFacturacionCaja = record
    FechaDesde          : TDateTime;
    FechaHasta          : TDateTime;
    CodigoEmpresaDestino: string;
    Usuario             : string;
  end;

  TResultadoFacturacionCaja = record
    CantidadDocumentos : Integer;
    CantidadOperaciones: Integer;
    CantidadAjustes    : Integer;
    Descripcion        : string;
  end;

  IRepositorioFacturasProforma = interface
    ['{374AE17A-F446-4AB7-9527-1911DB4047D6}']
    function GenerarVenta(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function GenerarTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
  end;

implementation

end.
