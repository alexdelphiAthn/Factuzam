{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGeneracionSkusPersistenciaIntf                          }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos para configurar atributos y generar SKU de un articulo.   }
{******************************************************************************}
unit inLibGeneracionSkusPersistenciaIntf;

interface

uses
  Data.DB;

type
  TConjuntoAtributoSku = record
    Id: Integer;
    Nombre: string;
  end;

  IDatosGeneracionSkus = interface
    ['{E5ABFF18-260A-4F89-888D-A9DDBBF4EDB9}']
    function Maestro: TDataSet;
    function Detalle: TDataSet;
    procedure RecargarMaestro;
  end;

  IRepositorioGeneracionSkus = interface
    ['{FE2C3C4D-444A-4E62-9793-48DDA7BA067C}']
    function PrepararDatos(
      const ACodigoArticulo: string;
      const ATipoVariacion: string
    ): IDatosGeneracionSkus;
    function ObtenerConjuntoAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string
    ): TConjuntoAtributoSku;
    function CalcularSiguienteOrdenValor(
      const AIdAtributo: string;
      AIdConjunto: Integer
    ): Integer;
    function AsegurarValor(
      const AIdAtributo: string;
      const ANombre: string;
      AOrden: Integer
    ): Integer;
    procedure GuardarValorEnConjunto(
      AIdConjunto: Integer;
      AIdValor: Integer;
      AOrden: Integer);
    procedure GuardarSku(
      const ACodigoSku: string;
      const ACodigoArticulo: string;
      const ATipoVariacion: string;
      const AIdsValores: TArray<Integer>);
    procedure GuardarOrdenAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string;
      AOrden: Integer);
    function ObtenerNombreConjunto(
      const ACodigoArticulo: string;
      const AIdAtributo: string
    ): string;
    procedure GuardarOrdenValor(
      AIdValor: Integer;
      AOrden: Integer);
  end;

implementation

end.
