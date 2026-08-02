{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosAplicacionIntf                                }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos puros para resolver y aplicar una entrada de articulo o SKU.      }
{******************************************************************************}
unit inLibInventariosAplicacionIntf;

interface

type
  TErrorEntradaInventario = (
    eeiNinguno,
    eeiArticuloNoEncontrado,
    eeiTipoArticuloSinStock,
    eeiAtributosRequierenSku,
    eeiLineasNoAbiertas,
    eeiLineaNoEditable);

  TResultadoEntradaInventario = record
    Error: TErrorEntradaInventario;
    CodigoArticulo: string;
    CodigoSku: string;
    CodigoUnidad: string;
    Descripcion: string;
    TipoArticulo: string;
  end;

  IOperacionesEntradaInventario = interface
    ['{A4D98BCD-1A17-4AE0-A72A-21EECCF45B9D}']
    function MuestraAtributos: Boolean;
    function ObtenerNumeroAtributos(
      const ACodigoArticulo: string): Integer;
    function AsegurarEdicion: TErrorEntradaInventario;
    procedure EscribirArticulo(
      const ACodigoArticulo, ADescripcion: string);
    procedure ActualizarColumnas(const ACodigoArticulo: string);
    function NumeroAtributosActual: Integer;
    procedure EscribirUnidad(const ACodigoUnidad: string);
    procedure CargarStock(const ACodigoUnidad: string);
    procedure RellenarAtributos(const ACodigoSku: string);
  end;

  IAplicacionEntradaInventario = interface
    ['{022E8C10-F491-40D1-914D-62AA09DB8D58}']
    function Procesar(
      const AEntrada: string): TResultadoEntradaInventario;
  end;

implementation

end.
