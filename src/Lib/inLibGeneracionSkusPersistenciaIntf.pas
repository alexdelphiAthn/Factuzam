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

  // Valor de un atributo tal como está guardado (el nombre puede diferir
  // del tecleado: sin barras y con la caja original). Id = 0: no existe.
  TValorAtributoSku = record
    Id: Integer;
    Nombre: string;
  end;

  // Maestro: dimensiones del artículo. Detalle: valores de la dimensión
  // activa del maestro, con ASIGNADO editable solo en memoria.
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
    // Solo consulta: no crea nada. Id = 0 si el atributo no tiene ese valor.
    function BuscarValor(
      const AIdAtributo, ANombre: string): TValorAtributoSku;
    // Devuelve el valor existente o lo crea con el orden indicado.
    function AsegurarValor(
      const AIdAtributo, ANombre: string;
      AOrden: Integer): TValorAtributoSku;
    procedure GuardarValorEnConjunto(
      AIdConjunto: Integer;
      AIdValor: Integer;
      AOrden: Integer);
    function ObtenerCodigosSku(
      const ACodigoArticulo: string): TArray<string>;
    // True si el SKU no existía y se ha creado con sus atributos. Un SKU
    // que ya existía no se toca y devuelve False.
    function GuardarSku(
      const ACodigoSku, ACodigoArticulo, ATipoVariacion: string;
      const AIdsValores: TArray<Integer>): Boolean;
    procedure GuardarOrdenAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string;
      AOrden: Integer);
    procedure GuardarOrdenValor(
      AIdValor: Integer;
      AOrden: Integer);
  end;

implementation

end.
