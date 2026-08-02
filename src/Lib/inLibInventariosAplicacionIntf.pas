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
{    Puertos puros para resolver y aplicar una entrada de articulo o SKU,      }
{    importar un recuento y publicarlo en el recuento remoto.                  }
{******************************************************************************}
unit inLibInventariosAplicacionIntf;

interface

uses
  Data.DB;

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

  // === IMPORTACION DE RECUENTOS (Excel / CSV / app remota) ===
  TLineaImportacionInventario = record
    CodigoUnidad: string;
    Cantidad: Double;
    PrecioMedioNuevo: Double;
    TienePrecioMedio: Boolean;
    TextoOriginal: string;
  end;

  TLineasImportacionInventario = TArray<TLineaImportacionInventario>;

  TResumenImportacionInventario = record
    Actualizadas: Integer;
    Nuevas: Integer;
  end;

  // Escrituras que la importacion necesita sobre las lineas ya cargadas.
  // La implementacion real trabaja sobre el cds del data module.
  IOperacionesImportacionInventario = interface
    ['{0C6E7A2D-3B2F-4A8B-9E45-1D1F53C0B7A2}']
    function LocalizarUnidad(const ACodigoUnidad: string): Boolean;
    procedure IniciarEdicionLinea;
    procedure EscribirCantidadFisica(ACantidad: Double);
    procedure EscribirPrecioMedioNuevo(APrecio: Double);
    procedure ConfirmarLinea;
    procedure ConsolidarCambios;
    procedure AnadirUnidadPendiente(const ATextoOriginal: string);
  end;

  // === RECUENTO REMOTO ===
  TClaveInventario = record
    Empresa: string;
    Almacen: string;
    Serie: string;
    Numero: string;
  end;

  IRepositorioRecuentoRemotoInventario = interface
    ['{2A4B9C31-7D18-4C0E-8F6A-53B7E0D9C114}']
    procedure MarcarEnviado(
      const AClave: TClaveInventario; AIdRecuento: Int64);
    procedure MarcarRecogido(const AClave: TClaveInventario);
  end;

  // === BUSQUEDAS VISUALES ===
  // Envuelve el dataset abierto por el adaptador de persistencia para que
  // la pantalla no cree ni libere consultas.
  IResultadoConsultaInventario = interface
    ['{9B3D6E70-42A1-4F1D-B6C8-2E7A0F4D5C63}']
    function DataSet: TDataSet;
  end;

  IBusquedasInventario = interface
    ['{D5A1F082-6C39-4B7E-A0D2-8F41C6B93E57}']
    function ConsultarArticulos: IResultadoConsultaInventario;
    function ConsultarSkus(
      const ACodigoAlmacen: string): IResultadoConsultaInventario;
  end;

implementation

end.
