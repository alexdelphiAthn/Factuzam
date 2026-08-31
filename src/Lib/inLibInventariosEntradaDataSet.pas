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
procedure AsegurarIdPivoteLineaInventario(ALineas: TDataSet);

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
  ALineas.FieldByName(
    'ESPRECIO_MEDIO_CORREGIDO_INVLIN').AsString := 'N';
end;

procedure AsegurarIdPivoteLineaInventario(ALineas: TDataSet);
var
  CampoIdPivote: TField;
begin
  CampoIdPivote := ALineas.FindField('ID_AC_PIVOT_INVLIN');
  if (CampoIdPivote <> nil) and CampoIdPivote.IsNull then
    CampoIdPivote.AsInteger := 0;
end;

end.
