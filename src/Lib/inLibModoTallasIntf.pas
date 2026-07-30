{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasIntf                                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y tipos del modo de entrada de tallas en horizontal. No usa     }
{    UniDAC, VCL ni DevExpress: el dominio y sus pruebas trabajan aquí.        }
{******************************************************************************}
unit inLibModoTallasIntf;

interface

uses
  System.SysUtils, Data.DB, Uni;

type
  // Valores / nombres de los 5 atributos posibles de una linea.
  TValoresAttrTallas = array[1..5] of string;
  // Unidades acumuladas en las celdas de una linea del documento.
  TTotalLineaTallas = record
    Linea: Integer;
    Total: Double;
  end;
  // Cantidad viva en la propia linea (la que no tiene celdas).
  TCantidadLineaTallas = record
    Linea: Integer;
    Cantidad: Double;
  end;
  // Celda de talla agrupada. Almacen '' fuera del formato distribuido.
  TCeldaTallas = record
    Linea: Integer;
    Almacen: string;
    IdAv: Integer;
    ValorTalla: string;
    Cantidad: Double;
  end;
  // Linea de origen durante el des-pivote. OrdenTalla y NombreTalla los
  // rellena el caso de uso con el modelo; el puerto de lineas no conoce
  // el catalogo de atributos.
  TDatosLineaExpansion = record
    Numero: Integer;
    Encontrada: Boolean;
    Primera: Boolean;
    Articulo: string;
    Descripcion: string;
    Almacen: string;
    NombreTalla: string;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    OrdenTalla: Integer;
    Precio: Double;
  end;
  // Atributos calculados de una linea, SIN escribir en el dataset.
  TAtributosLineaTallas = record
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    OrdenTalla: Integer;
  end;
  // Lectura de la linea sobre la que trabaja la rederivacion.
  TLineaDocumentoTallas = record
    Numero: Integer;
    Articulo: string;
    Sku: string;
    Almacen: string;
    Cantidad: Double;
    Precio: Double;
    TieneAlmacen: Boolean;
    TienePrecio: Boolean;
    TieneCantidad: Boolean;
  end;
  // Escritura de la linea maestra tras rederivarla.
  TEscrituraLineaTallas = record
    Almacen: string;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    PonerCantidadCero: Boolean;
  end;
  // Alta o consolidacion de la linea que resuelve una entrada.
  TAltaLineaTallas = record
    Articulo: string;
    Descripcion: string;
    Almacen: string;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    Precio: Double;
    TienePrecio: Boolean;
  end;
  // Aviso de que una linea ha quedado con estos atributos, para que la
  // presentacion rotule y muestre sus columnas.
  TAtributosEscritosTallas = procedure(
    const AValores, ANombres: TValoresAttrTallas) of object;
  // Nombres de los campos del cds que necesita el adaptador de lineas.
  TCamposLineasTallas = record
    CodigoArt: string;
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: string;
    Almacen: string;
    NumAtributos: string;
    AttrValor: TValoresAttrTallas;
    AttrNombre: TValoresAttrTallas;
    Linea: string;
    ConjuntoPivot: string;
    PrecioBase: string;
    TotalUds: string;
    TotalLinea: string;
  end;
  // Traza de sesion; el dominio no conoce el contexto de la aplicacion.
  TRegistroTallas = procedure(const ATexto: string) of object;
  // Entrada elegida en el desplegable o tecleada con Enter.
  TEntradaElegidaTallas = procedure(const AEntrada: string) of object;
  // Eleccion visual de un valor de atributo cuando hay varios posibles.
  // La implementacion vive en la capa de presentacion (paleta).
  ISelectorValorAtributo = interface
    ['{0B0D6F1E-6C4B-4E42-9B2A-3F71C0A5D914}']
    function Seleccionar(const ANombreAtributo: string;
      const AValores: TArray<string>; out AValor: string): Boolean;
  end;
  // Puerto de persistencia del modo tallas: la tabla de celdas, los
  // conjuntos de atributos, los almacenes y la unidad de trabajo. Las
  // operaciones se nombran por caso de uso; no se expone SQL.
  IPersistenciaModoTallas = interface
    ['{4A1E8C33-5D07-4B96-8E45-2C6F90B7A1D2}']
    function ConsultarTotalesPorLinea: TArray<TTotalLineaTallas>;
    function ConsultarCeldasDocumento: TArray<TCeldaTallas>;
    function ConsultarCeldasLinea(ALinea: Integer): TArray<TCeldaTallas>;
    function LineaTieneCeldas(ALinea: Integer): Boolean;
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACantidad: Double;
      const AAlmacen: string);
    procedure MoverCeldasALinea(AOrigen, ADestino: Integer);
    function MigrarCeldasFormato(ADistribuido: Boolean;
      const AAlmacenDefecto: string): Integer;
    procedure BorrarCeldasDocumento;
    function BuscarConjuntoParaAvs(
      const AIdsValores: TArray<Integer>): Integer;
    function ConjuntoCubreAvs(AIdConjunto: Integer;
      const AIdsValores: TArray<Integer>): Boolean;
    function PrimerAlmacenEstandar: string;
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  // Puerto de acceso a las lineas del documento. Lo implementa un
  // adaptador sobre el cds; el caso de uso de des-pivote no toca
  // controles ni datasets.
  ILineasDocumentoTallas = interface
    ['{7F3C2A55-91B4-4C08-A6D3-58E0B4F27C61}']
    function HayLineas: Boolean;
    function MaximaLinea: Integer;
    function LeerDatosLinea(ALinea: Integer): TDatosLineaExpansion;
    function CantidadesPorLinea: TArray<TCantidadLineaTallas>;
    procedure ActualizarLineaExpandida(const ACelda: TCeldaTallas;
      const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure CrearLineaExpandida(ANuevaLinea: Integer;
      const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
      const ASku, AAlmacen: string);
    // Recorrido por posicion para la rederivacion. Tras borrar la linea
    // activa NO se avanza: la posicion ya apunta a otra linea.
    function ContarLineas: Integer;
    procedure PosicionarEn(APosicion: Integer);
    function LeerLineaActual: TLineaDocumentoTallas;
    procedure EscribirLineaActual(const ADatos: TEscrituraLineaTallas);
    procedure BorrarLineaActual;
    procedure IrAlPrimero;
    procedure SuspenderRefrescoVisual;
    procedure ReanudarRefrescoVisual;
    // Resolucion de una entrada: consolidacion y alta de la linea.
    procedure CancelarEdicionPendiente;
    procedure ConfirmarEdicionPendiente;
    function LocalizarLineaConsolidable(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
      APrecio: Double): Boolean;
    procedure AltaLineaResuelta(const ADatos: TAltaLineaTallas);
    function NumeroLineaActual: Integer;
    function AlmacenLineaActual(const ADefecto: string): string;
    function ConjuntoPivotActual: Integer;
    procedure IrALineaEnBlanco;
    // Vuelca a cada linea PIVOTADA el total de sus celdas y el total de
    // linea derivado del precio base.
    procedure RefrescarTotales(
      const ATotales: TArray<TTotalLineaTallas>);
    procedure IniciarProceso;
    procedure TerminarProceso;
    procedure NotificarPostsSilenciados;
  end;
  // Desplegable de busqueda incremental de SKUs. Devuelve un TDataSet
  // porque el lookup de DevExpress necesita un origen vivo; el SQL vive
  // en el adaptador UniData*, nunca en el modo de entrada.
  IBusquedaSkusTallas = interface
    ['{2D94B71A-8E36-4F5D-B0C7-16A9E3852F40}']
    function Dataset: TDataSet;
    procedure Aplicar(const ATexto, AAlmacenStock: string);
    procedure Invalidar;
  end;
  // Coordenadas del documento y de su tabla de celdas. El adaptador
  // UniData* lee serie, numero y clave extra del master en cada
  // operacion, como hacia el modo antes de extraer el SQL.
  TConfigPersistenciaTallas = record
    Conexion: TUniConnection;
    Master: TDataSet;
    Usuario: string;
    CampoSerieMaster: string;
    CampoNumeroMaster: string;
    CamposDocExtraMaster: TArray<string>;
    TablaCeldas: string;
    CampoSerieCel: string;
    CampoNumeroCel: string;
    CampoLineaCel: string;
    CampoFilaCel: string;
    CampoAvPivotCel: string;
    CampoCantidadCel: string;
    CampoAlmacenCel: string;
    CamposDocExtraCel: TArray<string>;
    IdFilaFijo: Integer;
  end;
  TFabricaPersistenciaTallas = function(
    const ACfg: TConfigPersistenciaTallas): IPersistenciaModoTallas;
  TFabricaBusquedaTallas = function(
    AConexion: TUniConnection): IBusquedaSkusTallas;
  // Registro de la implementacion de persistencia. La unidad UniData*
  // se registra en su initialization; el dominio no la conoce.
  TFabricaModoTallas = class
  private
    class var FPersistencia: TFabricaPersistenciaTallas;
    class var FBusqueda: TFabricaBusquedaTallas;
  public
    class procedure Registrar(APersistencia: TFabricaPersistenciaTallas;
      ABusqueda: TFabricaBusquedaTallas);
    class function CrearPersistencia(
      const ACfg: TConfigPersistenciaTallas): IPersistenciaModoTallas;
    class function CrearBusqueda(
      AConexion: TUniConnection): IBusquedaSkusTallas;
  end;

implementation

uses
  inLibMsgArticulos;

class procedure TFabricaModoTallas.Registrar(
  APersistencia: TFabricaPersistenciaTallas;
  ABusqueda: TFabricaBusquedaTallas);
begin
  FPersistencia := APersistencia;
  FBusqueda := ABusqueda;
end;

class function TFabricaModoTallas.CrearPersistencia(
  const ACfg: TConfigPersistenciaTallas): IPersistenciaModoTallas;
begin
  if not Assigned(FPersistencia) then
    raise Exception.Create(SErrorPersistenciaTallasNoRegistrada);
  Result := FPersistencia(ACfg);
end;

class function TFabricaModoTallas.CrearBusqueda(
  AConexion: TUniConnection): IBusquedaSkusTallas;
begin
  if not Assigned(FBusqueda) then
    raise Exception.Create(SErrorPersistenciaTallasNoRegistrada);
  Result := FBusqueda(AConexion);
end;

end.
