{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteVentaIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia del pivote de venta (fascículo V2 del anexo        }
{    SRP). Devuelve records de SKU, atributos y conjuntos; no cruza            }
{    TDataSet, TUniQuery ni TUniConnection. La implementación UniDAC vive      }
{    en UniDataPivoteVenta.                                                    }
{******************************************************************************}
unit inLibPivoteVentaIntf;

interface

type
  // Atributos de variación de un SKU: color (id y textos) y talla.
  TInfoSkuPivoteVenta = record
    Encontrado : Boolean;
    ColorAv    : Integer;
    TallaAv    : Integer;
    ColorTexto : string;
    ColorCodigo: string;
    VarSku     : string;
  end;
  // Posición (id de talla, valor visible) dentro de un conjunto pivot.
  TValorTallaPivoteVenta = record
    IdAv : Integer;
    Valor: string;
  end;
  TValoresTallaPivoteVenta = TArray<TValorTallaPivoteVenta>;
  // Operaciones con nombre del caso de uso del pivote de venta. El
  // adaptador parametriza y ejecuta SQL; no decide qué banda corresponde
  // ni cómo se agrupan las líneas.
  IRepositorioPivoteVenta = interface
    ['{1E7D0B7C-52A9-4A45-B7D0-6C41E9AD83F2}']
    function ObtenerInfoSku(const ACodigoSku: string)
                            : TInfoSkuPivoteVenta;
    function ResolverSkuDesdeCodigoBarras(
      const ACodigoBarras: string): string;
    // SKU único activo del artículo; '' si tiene cero o varios.
    function ResolverSkuUnicoArticulo(
      const ACodigoArticulo: string): string;
    // Conjunto real más ajustado que cubre todas las tallas; 0 si no
    // existe ninguno.
    function BuscarConjuntoQueCubre(
      const AIdsTalla: TArray<Integer>): Integer;
    // Posiciones ordenadas (ORDEN_ACD) de un conjunto real.
    function PosicionesConjunto(AIdAc: Integer)
                                : TValoresTallaPivoteVenta;
    // Tallas presentes en los SKUs del artículo, por ORDEN_AV.
    function TallasDeArticulo(const ACodigoArticulo: string)
                              : TValoresTallaPivoteVenta;
    // Valores de talla concretos por id, por ORDEN_AV.
    function TallasPorIds(const AIdsTalla: TArray<Integer>)
                          : TValoresTallaPivoteVenta;
    function DescripcionTalla(AIdAvTalla: Integer): string;
    // SKU activo del artículo con esa talla (y color, si > 0).
    function BuscarSkuActivoPorAtributos(
      const ACodigoArticulo: string;
      ATallaAv, AColorAv: Integer): string;
    // Alta idempotente del SKU y sus atributos de color y talla.
    procedure CrearSkuConAtributos(const ACodigoSku, ACodigoArticulo,
                                   AVariacionSku: string;
                                   AColorAv, ATallaAv: Integer);
    // Abre el buscador de artículos (stock del almacén indicado) y
    // devuelve el artículo elegido; False si el usuario cancela.
    function ElegirArticuloDesdeBusqueda(const AAlmacenStock: string;
                                         out ACodigoArticulo: string)
                                         : Boolean;
  end;

implementation

end.
