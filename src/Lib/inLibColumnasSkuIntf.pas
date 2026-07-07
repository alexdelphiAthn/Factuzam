{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuIntf                                          }
{    Tipo:       Libreria (interfaces)                                         }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: contratos (interfaces con GUID) para montar la    }
{    entrada de articulos sobre el cxGrid de CUALQUIER documento (pedido,      }
{    albaran, factura, traspaso...) en dos modos intercambiables:              }
{                                                                              }
{      - mcsSku:      articulo/color/talla en UNA columna (el SKU completo)    }
{                     con busqueda incremental por CODIGO_UNIDAD_SKU.          }
{      - mcsDesglose: columna de articulo + columnas de color y talla          }
{                     (delega en inLibGridArticulos, ya en produccion).        }
{                                                                              }
{    El documento no conoce la implementacion: recibe un IModoEntradaGrid de   }
{    la factoria (inLibColumnasSku) y trabaja contra el contrato.              }
{    Documentado en DESARROLLOS EN CURSO/ColumnSKUcxGrid/ColumnSKUcxGrid.md.   }
{******************************************************************************}
unit inLibColumnasSkuIntf;

interface

uses
  System.Classes, Data.DB, Uni, cxGridDBTableView;

type
  // Modo de entrada de articulos en el grid del documento.
  TModoColumnasSku = (
    mcsAuto,        // decidir segun los campos disponibles en el cds
    mcsSku,         // articulo/color/talla en UNA columna (SKU completo)
    mcsDesglose,    // columna articulo + columnas color / talla
    mcsTallasInline // articulo + N columnas de talla en horizontal
                    // (pivote estilo compras; requiere tabla de celdas
                    // y factoria propia: CrearModoEntradaGridTallas)
  );

  // Nombres de los campos del cds del documento. Cada documento rellena
  // los suyos (pedido: CODIGO_ART, CODIGO_UNIDAD, ...). AttrValor y
  // AttrNombre pueden quedar vacios si el documento no desglosa
  // atributos (modo SKU puro).
  TCamposColumnasSku = record
    CodigoArt: string;
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: string;
    // Almacen de la LINEA (modelo de compras: una fila horizontal por
    // articulo+color+almacen; la distribucion por almacen va por
    // lineas, no por celdas). Vacio si el documento no lo usa.
    Almacen: string;
    NumAtributos: string;
    AttrValor: array[1..5] of string;
    AttrNombre: array[1..5] of string;
  end;

  // Precio unitario que el documento aplicara al SKU (su tarifa, su
  // fecha). Lo usa el modo tallas para que la consolidacion del escaneo
  // NO fusione en una linea de precio distinto: una fila pivotada por
  // precio. Sin asignar, la consolidacion ignora el precio.
  TObtenerPrecioSkuEvent = function(const ACodigoArticulo,
                                    ACodigoSku: string): Double of object;

  // Todo lo que necesita un modo para montarse sobre el grid del documento.
  TConfigColumnasSku = record
    Conexion: TUniConnection;
    View: TcxGridDBTableView;
    Cds: TDataSet;
    Campos: TCamposColumnasSku;
    Modo: TModoColumnasSku;
    // Almacen cuyo stock se muestra en el buscador (vacio = sin stock).
    AlmacenStock: string;
    // Formato distribuido (solo modo tallas, como ESFORMATO_
    // DISTRIBUIDO_SES de sesiones): las cantidades se reparten por
    // almacen con el modal distribuidor; la edicion inline de celdas
    // de talla queda bloqueada y el grid muestra la SUMA por talla.
    Distribuido: Boolean;
    // Precio del SKU segun el documento (ver TObtenerPrecioSkuEvent).
    ObtenerPrecioSku: TObtenerPrecioSkuEvent;
  end;

  // Aviso al documento al resolver una entrada. ACompleto = SKU cerrado
  // (articulo sin variacion o con todos los atributos elegidos).
  TSkuResueltoEvent = procedure(const ACodArt, ASku, ADescripcion: string;
                                ACompleto: Boolean) of object;

  // Valores disponibles (colores, tallas, ...) de un articulo, para que
  // cualquier consumidor los muestre sin duplicar SQL. Implementado sobre
  // inLibArticulosAtributosLookup (desarrollo ya hecho).
  IProveedorValoresSku = interface
    ['{B4A7C9E1-3D52-4F60-8A17-59C2E6D0B833}']
    // Nombres de los atributos de variacion (Color, Talla, ...) en orden.
    function ObtenerNombresAtributos(const ACodigoArticulo: string)
                                                       : TArray<string>;
    // Valores del atributo AOrden (1..N) presentes en SKUs del articulo.
    function ObtenerValoresDisponibles(const ACodigoArticulo: string;
                                       AOrden: Integer): TArray<string>;
  end;

  // Contrato comun de los modos de entrada montados sobre el cxGrid.
  IModoEntradaGrid = interface
    ['{5E92D8F4-71A6-4BC3-9D08-E4F1A27C6B50}']
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    // Cambia el almacen del stock del buscador (invalida el desplegable).
    procedure SetAlmacenStock(const AValue: string);
    // Crea sus columnas sobre el View. El documento anade las suyas
    // (cantidad, precio, ...) DESPUES sobre el mismo View.
    procedure Construir;
    // Prepara el abandono del modo ANTES de reconstruir en otro. El
    // modo tallas des-pivota: expande cada celda con cantidad en una
    // linea por SKU (cantidad plana) y limpia su tabla de celdas, para
    // que SKU/Desglose muestren las mismas unidades. El resto de modos
    // no hace nada.
    procedure Desmontar;
    // Deja el editor de entrada abierto, listo para teclear o escanear.
    procedure MostrarEditor;
    // Resuelve una entrada (SKU, articulo, barras, ref proveedor) y
    // rellena la linea actual. False si no se encontro o se cancelo.
    function ResolverEntrada(const AEntrada: string): Boolean;
    // Modo EFECTIVO (nunca mcsAuto: la factoria ya decidio).
    property Modo: TModoColumnasSku read GetModo;
    property OnResuelto: TSkuResueltoEvent read GetOnResuelto
                                           write SetOnResuelto;
    // Entrada/salida de los editores in-place del modo (celda de SKU,
    // combos de atributo, desplegable incremental). Pensados para que un
    // host TfrmBase enganche DesactivarEnterAsTabTemporal /
    // RestaurarEnterAsTabTemporal y el Enter llegue a la celda en vez de
    // convertirse en Tab (TJvEnterAsTab de inMtoFrmBase).
    property OnEntrarEdicion: TNotifyEvent read GetOnEntrarEdicion
                                           write SetOnEntrarEdicion;
    property OnSalirEdicion: TNotifyEvent read GetOnSalirEdicion
                                          write SetOnSalirEdicion;
  end;

implementation

end.
