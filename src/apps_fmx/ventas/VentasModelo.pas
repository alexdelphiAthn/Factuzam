{******************************************************************************}
{                                                                              }
{  Módulo:       VentasModelo                                                  }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Estructuras del listado de ventas. Calcan la respuesta de                 }
{    ventas/lineas.php, sin lógica ni dependencias de UI.                      }
{******************************************************************************}
unit VentasModelo;

interface

type
  TLineaVenta = record
    Anulada: Boolean;
    Cantidad: Double;
    ImporteDescuento: Double;
    PorcentajeDescuento: Double;
    PrecioConDescuento: Double;
    PrecioCoste: Double;
    PrecioVenta: Double;
    Pvp: Double;
    TotalCoste: Double;
    TotalLinea: Double;
    TotalLineaSiva: Double;
    Articulo: string;
    CodigoFamilia: string;
    CodigoProveedor: string;
    Color: string;
    Descripcion: string;
    Empresa: string;
    Familia: string;
    Fecha: string;
    FotoRuta: string;
    Hora: string;
    Linea: string;
    Numero: string;
    Proveedor: string;
    Serie: string;
    Sku: string;
    Temporada: string;
    Variacion: string;
    function ClaveFoto: string;
    function Documento: string;
    function TituloLinea: string;
  end;

  TArrLineaVenta = TArray<TLineaVenta>;

  TTotalesVenta = record
    Lineas: Integer;
    PorcentajeMargen: Double;
    TotalCoste: Double;
    TotalDescuento: Double;
    TotalMargen: Double;
    TotalVenta: Double;
    TotalVentaSiva: Double;
    Unidades: Double;
    Fecha: string;
  end;

  TArrTotalesVenta = TArray<TTotalesVenta>;

  TRespuestaLineas = record
    Devueltas: Integer;
    TotalLineas: Integer;
    Desde: string;
    Hasta: string;
    Lineas: TArrLineaVenta;
    Totales: TTotalesVenta;
    TotalesDia: TArrTotalesVenta;
  end;

  TFiltroLineas = record
    Limite: Integer;
    Empresa: string;
    Familia: string;
    Fecha: string;
    Proveedor: string;
    Temporada: string;
    Texto: string;
  end;

implementation

uses
  System.SysUtils;

{ La clave lleva el SKU completo porque el servidor resuelve la foto con
  fallback (SKU, color, artículo) y dos tallas del mismo color pueden acabar
  en fotos distintas si alguna tiene la suya propia. }
function TLineaVenta.ClaveFoto: string;
begin
  Result := Articulo + '|' + Sku;
end;

function TLineaVenta.Documento: string;
begin
  Result := Serie + '/' + Numero;
end;

function TLineaVenta.TituloLinea: string;
begin
  Result := Descripcion;
  if Trim(Variacion) <> '' then
    Result := Result + '  ·  ' + Variacion;
  if Trim(Result) = '' then
    Result := Sku;
end;

end.
