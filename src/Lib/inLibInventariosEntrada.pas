{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventariosEntrada                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decisiones y escritura de la entrada de artículos y SKU en inventarios.  }
{******************************************************************************}
unit inLibInventariosEntrada;

interface

uses
  Data.DB;

type
  TDecisionEntradaInventario = record
    CodigoUnidad: string;
    CargarStock: Boolean;
    RellenarAtributos: Boolean;
  end;

function ResolverEntradaInventario(
  const ACodigoArticulo, ACodigoSku: string;
  ANumeroAtributos: Integer): TDecisionEntradaInventario;
procedure EscribirArticuloLineaInventario(
  ALineas: TDataSet;
  const ACodigoArticulo, ADescripcion: string);
procedure EscribirStockLineaInventario(
  ALineas: TDataSet;
  const ACodigoUnidad: string;
  ACantidadTeorica, APrecioMedio: Currency);

implementation

function ResolverEntradaInventario(
  const ACodigoArticulo, ACodigoSku: string;
  ANumeroAtributos: Integer): TDecisionEntradaInventario;
begin
  Result.CodigoUnidad := ACodigoArticulo;
  Result.CargarStock := ANumeroAtributos = 0;
  Result.RellenarAtributos := False;
  if ACodigoSku <> '' then
  begin
    Result.CodigoUnidad := ACodigoSku;
    Result.CargarStock := True;
    Result.RellenarAtributos := True;
  end;
end;

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
