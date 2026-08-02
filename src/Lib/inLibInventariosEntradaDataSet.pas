{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosEntradaDataSet                                }
{    Tipo:       Adaptador                                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Escritura de la entrada de inventario sobre el dataset de lineas.         }
{******************************************************************************}
unit inLibInventariosEntradaDataSet;

interface

uses
  Data.DB;

procedure EscribirArticuloLineaInventario(
  ALineas: TDataSet;
  const ACodigoArticulo, ADescripcion: string);
procedure EscribirStockLineaInventario(
  ALineas: TDataSet;
  const ACodigoUnidad: string;
  ACantidadTeorica, APrecioMedio: Currency);

implementation

procedure EscribirArticuloLineaInventario(
  ALineas: TDataSet;
  const ACodigoArticulo, ADescripcion: string);
begin
  ALineas.FieldByName('CODIGO_ART_INVLIN').AsString := ACodigoArticulo;
  ALineas.FieldByName(
    'DESCRIPCION_ARTICULO_INVLIN').AsString := ADescripcion;
end;

procedure EscribirStockLineaInventario(
  ALineas: TDataSet;
  const ACodigoUnidad: string;
  ACantidadTeorica, APrecioMedio: Currency);
begin
  ALineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
    ACodigoUnidad;
  ALineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency :=
    ACantidadTeorica;
  ALineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency :=
    ACantidadTeorica;
  ALineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency :=
    APrecioMedio;
  ALineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
    APrecioMedio;
end;

end.
