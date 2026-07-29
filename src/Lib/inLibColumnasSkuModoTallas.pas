{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoTallas                                    }
{    Tipo:       Libreria                                                      }
{ Version:       0.3.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: implementacion de IModoEntradaGrid en modo        }
{    TALLAS EN HORIZONTAL (una fila por articulo+color y N columnas de         }
{    cantidad por talla, pivotadas por conjunto).                              }
{                                                                              }
{    Adaptador sobre TGestorGridTallas (inLibGridTallasInline, el pivote       }
{    ya en produccion en compras). CONSOLIDA: cada combinacion                 }
{    articulo+atributos no talla es UNA linea; una lectura con talla           }
{    (SKU/barras) suma +1 en la celda de su talla, como la caja pero en        }
{    horizontal. Las lineas heredadas de otros modos (SKU con talla +          }
{    cantidad) se convierten al construir: cantidad a su celda y               }
{    duplicados fusionados.                                                    }
{                                                                              }
{    REQUISITOS DEL HOST:                                                      }
{      - Tabla de celdas y campos de pivote (TGridTallasConfig).               }
{      - Master y lineas ABIERTOS antes de Construir.                          }
{      - Campos ATTRn definidos si hay atributos no talla (color).             }
{******************************************************************************}
unit inLibColumnasSkuModoTallas;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.StrUtils, System.Generics.Collections,
  Data.DB, Uni, Vcl.Controls, Vcl.Dialogs, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.Graphics,
  cxGraphics, dxCoreGraphics, cxEdit, cxTextEdit, cxDropDownEdit,
  cxCurrencyEdit,
  cxDataStorage, cxEditRepositoryItems, cxDBExtLookupComboBox, cxGrid,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibArticulosValidador,
  inLibArticulosAtributosLookup, inLibAtributosPaleta;

type
  TParametrosDistribuidorTallas = record
    Conexion: TUniConnection;
    Usuario: string;
    TablaCeldas: string;
    CampoSerie: string;
    CampoNumero: string;
    CampoLinea: string;
    CampoFila: string;
    CampoAlmacen: string;
    CampoAtributoValor: string;
    CampoCantidad: string;
    Serie: string;
    Numero: string;
    Linea: Integer;
    IdConjuntoPivot: Integer;
  end;

  TEjecutorDistribuidorTallas = class
  public
    class function Ejecutar(
      const AParametros: TParametrosDistribuidorTallas): Boolean;
      virtual; abstract;
  end;

  TClaseEjecutorDistribuidorTallas = class of TEjecutorDistribuidorTallas;

  TDistribuidorTallas = class
  private
    class var FClaseEjecutor: TClaseEjecutorDistribuidorTallas;
  public
    class procedure RegistrarEjecutor(
      AClase: TClaseEjecutorDistribuidorTallas);
    class function Ejecutar(
      const AParametros: TParametrosDistribuidorTallas): Boolean;
  end;

  // Valores / nombres de los 5 atributos posibles de una linea.
  TValoresAttrTallas = array[1..5] of string;

  TModoEntradaTallas = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConfig: TConfigColumnasSku;
    FCfgTallas: TGridTallasConfig;
    FGestor: TGestorGridTallas;
    FLookup: TArticulosAtributosLookup;
    FColArticulo: TcxGridDBColumn;
    // Columnas de atributos NO talla (color, temporada...).
    FColAtributo: array[1..5] of TcxGridDBColumn;
    FOnResuelto: TSkuResueltoEvent;
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    // Busqueda incremental en la celda de articulo: por SKU (que
    // empieza por el codigo de articulo), codigo de barras, modelo /
    // referencia de proveedor y contenido de la descripcion — misma
    // consulta UNION que inLibGridArticulos. Desplegable en runtime +
    // filtro en servidor (top-100) con debounce.
    FBusqQry: TUniQuery;
    FBusqDs: TDataSource;
    FBusqRepo: TcxGridViewRepository;
    FBusqView: TcxGridDBTableView;
    FBusqColSku: TcxGridDBColumn;
    // Columna OCULTA duplicada del SKU que actua de ListFieldItem del
    // combo, con todo el buscado/filtrado desactivado: el lookup no
    // tiene donde morder y no autocompleta ni deja la lista "pegada"
    // (patron inMtoCajaOpe: dbtvBusqINPUT_BUSQUEDA).
    FBusqColInput: TcxGridDBColumn;
    FEditRepo: TcxEditRepository;
    FRepCombo: TcxEditRepositoryExtLookupComboBoxItem;
    FTimerBusq: TTimer;
    FUltimoFiltro: string;
    // Resolucion diferida del Enter en la celda de articulo.
    FTimerResolve: TTimer;
    // Carga inicial de celdas DIFERIDA (timer 1ms): el host anyade sus
    // columnas DESPUES de Construir y crear columnas en el view resetea
    // los Values[] no-bound; cargando en el siguiente tick, todas las
    // columnas ya existen y las cantidades no se pierden.
    FTimerCarga: TTimer;
    FEntradaPend: string;
    // True si la ultima entrada traia talla (lectura de SKU/barras):
    // el foco vuelve al articulo para encadenar lecturas.
    FUltimaConTalla: Boolean;
    // Guardia de reentrada del modal distribuidor (OnEditing puede
    // dispararse varias veces mientras el modal se abre).
    FDistribAbierto: Boolean;
    // Hook AfterPost del cds (patron de inMtoComprasSesiones): el Post
    // implicito al cambiar de fila re-renderiza el grid y limpia los
    // Values[] no-bound; el hook recarga las celdas. FEnProceso lo
    // silencia durante las conversiones internas (rederivar, desmontar,
    // totales), que postean muchas veces.
    FAfterPostOrig: TDataSetNotifyEvent;
    FAfterScrollOrig: TDataSetNotifyEvent;
    FEnProceso: Boolean;
    // Posts silenciados durante una conversion interna: al cerrarla se
    // encadena el AfterPost del host UNA sola vez (totales, stock...).
    FPostsSilenciados: Integer;
    // Recarga de celdas DIFERIDA (1ms): post y scroll repintan el grid
    // DESPUES de sus eventos; recargando en el siguiente tick, la
    // recarga siempre es lo ultimo y no la pisa ningun repintado.
    FTimerRecarga: TTimer;
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    procedure SetAlmacenStock(const AValue: string);
    procedure EditorSalir(Sender: TObject);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                              AItem: TcxCustomGridTableItem;
                              AEdit: TcxCustomEdit; var Key: Word;
                              Shift: TShiftState);
    procedure CrearLookupBusqueda;
    procedure AbrirBusquedaFiltrada(const ATexto: string);
    // Limpia el filtro interno del desplegable (IncSearching + Filter
    // del DataController): sin esto la lista se queda "pegada" a la
    // fila autocompletada aunque la query traiga mas filas. Mismo
    // mecanismo que inMtoCajaOpe.tmrBusqTimer.
    procedure LimpiarFiltroDesplegable;
    // Clave de documento extra (TGridTallasConfig.CamposDocExtra*):
    // mismos helpers que el gestor, para los SQL propios del modo
    // contra la tabla de celdas. Arrays vacios = sin efecto.
    function WhereDocExtra: string;
    function ColsInsertDocExtra: string;
    function ValsInsertDocExtra: string;
    procedure ParamsDocExtra(AQuery: TUniQuery);
    // Par NUMERO opcional ('' = clave simple, p.ej. ID_DTR): mismos
    // helpers que el gestor para los SQL propios del modo.
    function WhereNumero(const APrefijo: string): string;
    function ColsInsertNumero: string;
    function ValsInsertNumero: string;
    procedure ParamNumero(AQuery: TUniQuery);
    function NumeroDocTallas: string;
    procedure ComboBusqInitPopup(Sender: TObject);
    procedure ComboBusqCloseUp(Sender: TObject);
    // Combo de busqueda SOLO en celda de articulo vacia y enfocada;
    // con articulo resuelto, texto plano (patron del modo SKU).
    procedure ArtGetProperties(Sender: TcxCustomGridTableItem;
                               ARecord: TcxCustomGridRecord;
                             var AProperties: TcxCustomEditProperties);
    procedure ArtChange(Sender: TObject);
    procedure TimerBusqTimer(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    procedure TimerCargaTimer(Sender: TObject);
    // Totales de TODAS las lineas desde la tabla de celdas (una sola
    // consulta agrupada). El gestor solo refresca la linea activa.
    procedure RefrescarTotalesTodasLineas;
    procedure EnfocarColumnaPorCampo(const ACampo: string);
    function EsAtributoTalla(const AAtrib: TArticuloAtributo): Boolean;
    procedure AtributoCustomDrawCell(Sender: TcxCustomGridTableView;
                                     ACanvas: TcxCanvas;
                                AViewInfo: TcxGridTableDataCellViewInfo;
                                     var ADone: Boolean);
    // Trocea un SKU cerrado ART/VAL1/VAL2 en sus valores; nil si el
    // SKU no pertenece al articulo o no tiene variacion.
    function PartesDeSku(const AArt, ASku: string): TArray<string>;
    // Calcula (SIN escribir en el cds) valores y nombres de atributos
    // no talla, el conjunto pivote y el indice del atributo talla.
    // APartes: valores que trajo el SKU (prioridad sobre la paleta).
    procedure CalcularAtributosLinea(const ACodArt: string;
                                     const APartes: TArray<string>;
                                     ASilencioso: Boolean;
                                     out AVal, ANom: TValoresAttrTallas;
                                     out AAcTalla, AOrdenTalla: Integer);
    // Escribe atributos + pivote en la linea actual y rotula/muestra
    // las columnas de atributo usadas.
    procedure EscribirAtributosLinea(const AVal, ANom: TValoresAttrTallas;
                                     AAcTalla: Integer);
    // Localiza la linea existente con mismo articulo, mismo almacen y
    // mismos atributos no talla (consolidacion). Mueve el cursor.
    function LocalizarLineaExistente(const ACodArt, AAlm: string;
                                 const AVal: TValoresAttrTallas;
                                 APrecio: Double;
                                 ATienePrecio: Boolean): Boolean;
    // Consolidacion clasica (sin precio): Locate por articulo +
    // almacen + atributos no talla.
    function LocalizarSinPrecio(const ACodArt, AAlm: string;
                                 const AVal: TValoresAttrTallas): Boolean;
    // ID_AV de la talla AValor del articulo (0 si no existe).
    function IdAvDeTalla(const ACodArt: string; AOrdenTalla: Integer;
                         const AValor: string): Integer;
    // Suma ACant a la celda (linea, almacen, AV) con upsert atomico.
    // AAlm: almacen de la celda ('' fuera del formato distribuido).
    // ARefrescar: recarga la fila enfocada y sus totales (False
    // durante las conversiones masivas).
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACant: Double;
                           const AAlm: string; ARefrescar: Boolean);
    // True si la linea ya tiene celdas en BBDD (convertida en una
    // entrada anterior al modo tallas).
    function LineaTieneCeldas(ALinea: Integer): Boolean;
    // Mueve las celdas de una linea duplicada a la maestra (upsert
    // sumando por talla/almacen) y las borra del origen.
    procedure MoverCeldasALinea(AOrigen, ADestino: Integer);
    // Lineas heredadas de otros modos: deriva pivote/atributos, vuelca
    // CANTIDAD del SKU con talla a su celda y fusiona duplicadas.
    procedure RederivarLineasExistentes;
    // Fallback de pivote: conjunto global MAS PEQUENYO que contiene
    // todos los AVs de talla del articulo. 0 si ninguno cubre.
    function BuscarConjuntoParaAvs(
      const AAvs: TArray<TArticuloAtributoValor>): Integer;
    // True si el conjunto AIdAc contiene TODOS los AVs indicados.
    // Detecta asignaciones desfasadas (conjunto de letras asignado a
    // un articulo cuyos SKUs llevan tallas numericas): con un pivote
    // que no contiene sus AVs, las celdas serian invisibles.
    function ConjuntoCubreAvs(AIdAc: Integer;
      const AAvs: TArray<TArticuloAtributoValor>): Boolean;
    // Formato distribuido: bloquea la edicion inline de las celdas de
    // talla y abre el distribuidor (mismo patron que sesiones).
    procedure ViewEditing(Sender: TcxCustomGridTableView;
                          AItem: TcxCustomGridTableItem;
                          var AAllow: Boolean);
    procedure AbrirDistribuidorLinea;
    // En distribuido SIEMPRE hay almacen por defecto: si el documento
    // no lo trae, se toma el primer almacen activo estandar de
    // fza_almacenes (avisando); sin almacenes definidos -> excepcion.
    procedure AsegurarAlmacenDefecto;
    // Al construir, unifica el origen de las cantidades segun el
    // formato: con distribuido, las celdas SIN almacen (tecleadas en
    // modo normal) migran al almacen por defecto del documento; sin
    // distribuido, las celdas por almacen se colapsan a almacen ''.
    // Siempre fusionando cantidades si la celda destino ya existe.
    procedure MigrarCeldasAlmacen;
    // Unidades totales del documento con formula estable en ambos
    // formatos: SUM(celdas) + CANTIDAD de las lineas SIN celdas. Las
    // lineas pivotadas no aportan su CANTIDAD (es un total derivado).
    // Es el invariante que toda conversion debe conservar.
    function UnidadesDocumento: Double;
    // Compara unidades antes/despues de una conversion y lanza
    // excepcion si no cuadran: el try/except del llamador hace
    // rollback y el documento queda intacto (cantidades desorbitadas
    // de pedidos de compra, 10/07/26).
    procedure ComprobarInvarianteUnidades(const AContexto: string;
                                          AAntes, ADespues: Double);
    procedure CeldaTallaCambiada(Sender: TObject);
    procedure FocoLineaCambiado(Sender: TcxCustomGridTableView;
                                APrevFocusedRecord,
                                AFocusedRecord: TcxCustomGridRecord;
                                ANewItemRecordFocusingChanged: Boolean);
    // Restaura el EnterAsTab al SALIR de la columna del combo: el
    // OnExit del editor in-place no es fiable con AlwaysShowEditor.
    procedure FocoItemCambiado(Sender: TcxCustomGridTableView;
                               APrevFocusedItem,
                               AFocusedItem: TcxCustomGridTableItem);
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
    procedure ArmarRecarga;
    procedure NotificarPostsSilenciados;
    procedure TimerRecargaTimer(Sender: TObject);
    // El gestor rotula las columnas sobrantes con el generico
    // 'Talla N': aqui se dejan con un punto — solo se pinta la talla.
    procedure LimpiarCaptionsGenericas;
    procedure PonerCampo(const ANombre, AValor: string);
    // Lectura defensiva de un campo del cds ('' si no definido).
    function LeerCampo(const ANombre: string): string;
    // SKU de una linea: articulo + atributos en su orden, con la talla
    // AtALLA insertada en la posicion AOrdTalla (0-based).
    function ComponerSkuLinea(const AArt: string;
                              const AVal: TValoresAttrTallas;
                              AOrdTalla: Integer;
                              const ATalla: string): string;
    procedure LogSes(const ATexto: string);
  public
    constructor Create(const AConfig: TConfigColumnasSku;
                       const ACfgTallas: TGridTallasConfig);
    destructor Destroy; override;
    procedure Construir;
    // Des-pivote al abandonar el modo: cada celda con cantidad pasa a
    // una linea por SKU (cantidad plana) y se limpian las celdas.
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

implementation

uses
  inLibMsg;

class procedure TDistribuidorTallas.RegistrarEjecutor(
  AClase: TClaseEjecutorDistribuidorTallas);
begin
  FClaseEjecutor := AClase;
end;

class function TDistribuidorTallas.Ejecutar(
  const AParametros: TParametrosDistribuidorTallas): Boolean;
begin
  if not Assigned(FClaseEjecutor) then
    raise Exception.Create(SErrorDistribuidorTallasNoRegistrado);
  Result := FClaseEjecutor.Ejecutar(AParametros);
end;

type
  // Acceso a OnExit (protegido en TWinControl) de los editores in-place.
  THackWinControl = class(TWinControl);

  // Celda con cantidad pendiente de expandir a linea propia al salir
  // del modo tallas (Desmontar). Alm: almacen de la celda (formato
  // distribuido); '' en celdas sin almacen.
  TCeldaExpansion = record
    Linea: Integer;
    Alm: string;
    ValorTalla: string;
    Cant: Double;
  end;

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

  TDesmontajeTallas = class
  private
    FModo: TModoEntradaTallas;
    FDataset: TDataSet;
    FCeldas: TList<TCeldaExpansion>;
    FOrdenTallaPorArticulo: TDictionary<string, Integer>;
    FNombreTallaPorArticulo: TDictionary<string, string>;
    FMaximaLinea: Integer;
    FUnidadesAntes: Double;
    FEnProcesoPrevio: Boolean;
    FTransaccionPropia: Boolean;
    FExpandio: Boolean;
    function LocalizarLinea(ALinea: Integer): Boolean;
    procedure PonerLineaNueva(ALinea: Integer);
    procedure CargarCeldas;
    procedure CalcularMaximaLinea;
    procedure CargarDatosLinea(ALinea: Integer;
      var ADatos: TDatosLineaExpansion);
    procedure ActualizarPrimeraLinea(const ACelda: TCeldaExpansion;
      var ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure CrearLinea(const ACelda: TCeldaExpansion;
      const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure AplicarCelda(const ACelda: TCeldaExpansion;
      var ADatos: TDatosLineaExpansion);
    procedure ExpandirCeldas;
    procedure BorrarCeldas;
  public
    constructor Create(AModo: TModoEntradaTallas);
    destructor Destroy; override;
    procedure Ejecutar;
  end;

constructor TDesmontajeTallas.Create(AModo: TModoEntradaTallas);
begin
  inherited Create;
  FModo := AModo;
  FDataset := FModo.FConfig.Cds;
  FCeldas := TList<TCeldaExpansion>.Create;
  FOrdenTallaPorArticulo := TDictionary<string, Integer>.Create;
  FNombreTallaPorArticulo := TDictionary<string, string>.Create;
end;

destructor TDesmontajeTallas.Destroy;
begin
  FreeAndNil(FNombreTallaPorArticulo);
  FreeAndNil(FOrdenTallaPorArticulo);
  FreeAndNil(FCeldas);
  inherited;
end;

function TDesmontajeTallas.LocalizarLinea(ALinea: Integer): Boolean;
begin
  Result := FDataset.Locate(FModo.FCfgTallas.FieldLinea, ALinea, []);
  if not Result then
  begin
    FDataset.First;
    while (not FDataset.Eof) and (not Result) do
    begin
      if FDataset.FieldByName(
           FModo.FCfgTallas.FieldLinea).AsInteger = ALinea then
        Result := True
      else
        FDataset.Next;
    end;
  end;
end;

procedure TDesmontajeTallas.PonerLineaNueva(ALinea: Integer);
var
  Campo: TField;
begin
  Campo := FDataset.FieldByName(FModo.FCfgTallas.FieldLinea);
  if Campo is TStringField then
    Campo.AsString := Format('%.*d', [Campo.Size, ALinea])
  else
    Campo.AsInteger := ALinea;
end;

procedure TDesmontajeTallas.CargarCeldas;
var
  Consulta: TUniQuery;
  Celda: TCeldaExpansion;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FModo.FConfig.Conexion;
    if FModo.FCfgTallas.FieldAlmacenCel <> '' then
      Consulta.SQL.Text :=
        'SELECT c.' + FModo.FCfgTallas.FieldLineaCel + ' AS LIN,' +
        ' c.' + FModo.FCfgTallas.FieldAlmacenCel + ' AS ALMC,' +
        ' AV.AV AS VALOR,' +
        ' SUM(c.' + FModo.FCfgTallas.FieldCantidadCel + ') AS CANT' +
        ' FROM ' + FModo.FCfgTallas.TablaCeldas + ' c' +
        ' JOIN fza_atributos_valores AV' +
        '   ON AV.ID_AV = c.' + FModo.FCfgTallas.FieldAvPivotCel +
        ' WHERE c.' + FModo.FCfgTallas.FieldSerieCel + ' = :s' +
        FModo.WhereNumero('c.') +
        FModo.WhereDocExtra +
        ' GROUP BY c.' + FModo.FCfgTallas.FieldLineaCel + ', c.' +
        FModo.FCfgTallas.FieldAlmacenCel + ', AV.AV' +
        ' HAVING SUM(c.' + FModo.FCfgTallas.FieldCantidadCel + ') > 0' +
        ' ORDER BY LIN, ALMC, VALOR'
    else
      Consulta.SQL.Text :=
        'SELECT c.' + FModo.FCfgTallas.FieldLineaCel + ' AS LIN,' +
        ' '''' AS ALMC,' +
        ' AV.AV AS VALOR,' +
        ' SUM(c.' + FModo.FCfgTallas.FieldCantidadCel + ') AS CANT' +
        ' FROM ' + FModo.FCfgTallas.TablaCeldas + ' c' +
        ' JOIN fza_atributos_valores AV' +
        '   ON AV.ID_AV = c.' + FModo.FCfgTallas.FieldAvPivotCel +
        ' WHERE c.' + FModo.FCfgTallas.FieldSerieCel + ' = :s' +
        FModo.WhereNumero('c.') +
        FModo.WhereDocExtra +
        ' GROUP BY c.' + FModo.FCfgTallas.FieldLineaCel + ', AV.AV' +
        ' HAVING SUM(c.' + FModo.FCfgTallas.FieldCantidadCel + ') > 0' +
        ' ORDER BY LIN, VALOR';
    Consulta.ParamByName('s').AsString :=
      FModo.FCfgTallas.SourceMaster.DataSet.FieldByName(
        FModo.FCfgTallas.FieldSerieMaster).AsString;
    FModo.ParamNumero(Consulta);
    FModo.ParamsDocExtra(Consulta);
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Celda.Linea := Consulta.FieldByName('LIN').AsInteger;
      Celda.Alm := Trim(Consulta.FieldByName('ALMC').AsString);
      Celda.ValorTalla := Trim(Consulta.FieldByName('VALOR').AsString);
      Celda.Cant := Consulta.FieldByName('CANT').AsFloat;
      FCeldas.Add(Celda);
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TDesmontajeTallas.CalcularMaximaLinea;
begin
  FMaximaLinea := 0;
  FDataset.First;
  while not FDataset.Eof do
  begin
    if FDataset.FieldByName(
         FModo.FCfgTallas.FieldLinea).AsInteger > FMaximaLinea then
      FMaximaLinea :=
        FDataset.FieldByName(FModo.FCfgTallas.FieldLinea).AsInteger;
    FDataset.Next;
  end;
end;

procedure TDesmontajeTallas.CargarDatosLinea(ALinea: Integer;
  var ADatos: TDatosLineaExpansion);
var
  Atributos: TArray<TArticuloAtributo>;
  Indice: Integer;
begin
  ADatos := Default(TDatosLineaExpansion);
  ADatos.Numero := ALinea;
  ADatos.Primera := True;
  ADatos.Encontrada := LocalizarLinea(ALinea);
  if ADatos.Encontrada then
  begin
    ADatos.Articulo := Trim(FDataset.FieldByName(
      FModo.FConfig.Campos.CodigoArt).AsString);
    ADatos.Descripcion :=
      FModo.LeerCampo(FModo.FConfig.Campos.Descripcion);
    ADatos.Almacen := FModo.LeerCampo(FModo.FConfig.Campos.Almacen);
    ADatos.Precio := 0;
    if (FModo.FCfgTallas.FieldPrecioBase <> '') and
       (FDataset.FindField(FModo.FCfgTallas.FieldPrecioBase) <> nil)
    then
      ADatos.Precio := FDataset.FieldByName(
        FModo.FCfgTallas.FieldPrecioBase).AsFloat;
    for Indice := 1 to 5 do
    begin
      ADatos.Valores[Indice] :=
        FModo.LeerCampo(FModo.FConfig.Campos.AttrValor[Indice]);
      ADatos.Nombres[Indice] :=
        FModo.LeerCampo(FModo.FConfig.Campos.AttrNombre[Indice]);
    end;
    if not FOrdenTallaPorArticulo.TryGetValue(
      ADatos.Articulo, ADatos.OrdenTalla) then
    begin
      ADatos.OrdenTalla := -1;
      ADatos.NombreTalla := '';
      Atributos := FModo.FLookup.ObtenerAtributos(ADatos.Articulo);
      for Indice := 0 to High(Atributos) do
      begin
        if FModo.EsAtributoTalla(Atributos[Indice]) then
        begin
          ADatos.OrdenTalla := Indice;
          ADatos.NombreTalla := Atributos[Indice].NombreAtributo;
        end;
      end;
      FOrdenTallaPorArticulo.Add(
        ADatos.Articulo, ADatos.OrdenTalla);
      FNombreTallaPorArticulo.Add(
        ADatos.Articulo, ADatos.NombreTalla);
    end
    else
      FNombreTallaPorArticulo.TryGetValue(
        ADatos.Articulo, ADatos.NombreTalla);
  end;
end;

procedure TDesmontajeTallas.ActualizarPrimeraLinea(
  const ACelda: TCeldaExpansion; var ADatos: TDatosLineaExpansion;
  const ASku, AAlmacen: string);
var
  Indice: Integer;
  NumeroAtributos: Integer;
begin
  if not (FDataset.State in [dsEdit, dsInsert]) then
    FDataset.Edit;
  FModo.PonerCampo(FModo.FConfig.Campos.CodigoUnidad, ASku);
  FModo.PonerCampo(FModo.FConfig.Campos.Almacen, AAlmacen);
  if (ADatos.OrdenTalla >= 0) and (ADatos.OrdenTalla < 5) then
  begin
    FModo.PonerCampo(
      FModo.FConfig.Campos.AttrValor[ADatos.OrdenTalla + 1],
      ACelda.ValorTalla);
    FModo.PonerCampo(
      FModo.FConfig.Campos.AttrNombre[ADatos.OrdenTalla + 1],
      ADatos.NombreTalla);
  end;
  NumeroAtributos := 0;
  for Indice := 1 to 5 do
  begin
    if ADatos.Nombres[Indice] <> '' then
      Inc(NumeroAtributos);
  end;
  if ADatos.OrdenTalla >= 0 then
    Inc(NumeroAtributos);
  FModo.PonerCampo(FModo.FConfig.Campos.NumAtributos,
    IntToStr(NumeroAtributos));
  if FDataset.FindField(FModo.FConfig.Campos.Cantidad) <> nil then
    FDataset.FieldByName(
      FModo.FConfig.Campos.Cantidad).AsFloat := ACelda.Cant;
  FDataset.FieldByName(
    FModo.FCfgTallas.FieldConjuntoPivot).AsInteger := 0;
  FDataset.Post;
  ADatos.Primera := False;
end;

procedure TDesmontajeTallas.CrearLinea(
  const ACelda: TCeldaExpansion; const ADatos: TDatosLineaExpansion;
  const ASku, AAlmacen: string);
var
  Indice: Integer;
  NumeroAtributos: Integer;
begin
  Inc(FMaximaLinea);
  FDataset.Append;
  PonerLineaNueva(FMaximaLinea);
  FModo.PonerCampo(
    FModo.FConfig.Campos.CodigoArt, ADatos.Articulo);
  FModo.PonerCampo(
    FModo.FConfig.Campos.Descripcion, ADatos.Descripcion);
  FModo.PonerCampo(FModo.FConfig.Campos.Almacen, AAlmacen);
  FModo.PonerCampo(FModo.FConfig.Campos.CodigoUnidad, ASku);
  if (FModo.FCfgTallas.FieldPrecioBase <> '') and
     (FDataset.FindField(FModo.FCfgTallas.FieldPrecioBase) <> nil)
  then
    FDataset.FieldByName(
      FModo.FCfgTallas.FieldPrecioBase).AsFloat := ADatos.Precio;
  NumeroAtributos := 0;
  for Indice := 1 to 5 do
  begin
    FModo.PonerCampo(FModo.FConfig.Campos.AttrValor[Indice],
      ADatos.Valores[Indice]);
    FModo.PonerCampo(FModo.FConfig.Campos.AttrNombre[Indice],
      ADatos.Nombres[Indice]);
    if ADatos.Nombres[Indice] <> '' then
      Inc(NumeroAtributos);
  end;
  if (ADatos.OrdenTalla >= 0) and (ADatos.OrdenTalla < 5) then
  begin
    FModo.PonerCampo(
      FModo.FConfig.Campos.AttrValor[ADatos.OrdenTalla + 1],
      ACelda.ValorTalla);
    FModo.PonerCampo(
      FModo.FConfig.Campos.AttrNombre[ADatos.OrdenTalla + 1],
      ADatos.NombreTalla);
  end;
  if ADatos.OrdenTalla >= 0 then
    Inc(NumeroAtributos);
  FModo.PonerCampo(FModo.FConfig.Campos.NumAtributos,
    IntToStr(NumeroAtributos));
  if FDataset.FindField(FModo.FConfig.Campos.Cantidad) <> nil then
    FDataset.FieldByName(
      FModo.FConfig.Campos.Cantidad).AsFloat := ACelda.Cant;
  FDataset.FieldByName(
    FModo.FCfgTallas.FieldConjuntoPivot).AsInteger := 0;
  FDataset.Post;
end;

procedure TDesmontajeTallas.AplicarCelda(
  const ACelda: TCeldaExpansion; var ADatos: TDatosLineaExpansion);
var
  Almacen: string;
  Sku: string;
begin
  if ADatos.Encontrada then
  begin
    Sku := FModo.ComponerSkuLinea(
      ADatos.Articulo, ADatos.Valores, ADatos.OrdenTalla,
      ACelda.ValorTalla);
    if ACelda.Alm <> '' then
      Almacen := ACelda.Alm
    else
      Almacen := ADatos.Almacen;
    if ADatos.Primera then
      ActualizarPrimeraLinea(ACelda, ADatos, Sku, Almacen)
    else
      CrearLinea(ACelda, ADatos, Sku, Almacen);
  end;
end;

procedure TDesmontajeTallas.ExpandirCeldas;
var
  Celda: TCeldaExpansion;
  Datos: TDatosLineaExpansion;
  Indice: Integer;
begin
  CalcularMaximaLinea;
  Datos := Default(TDatosLineaExpansion);
  for Indice := 0 to FCeldas.Count - 1 do
  begin
    Celda := FCeldas[Indice];
    if Celda.Linea <> Datos.Numero then
      CargarDatosLinea(Celda.Linea, Datos);
    AplicarCelda(Celda, Datos);
  end;
end;

procedure TDesmontajeTallas.BorrarCeldas;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FModo.FConfig.Conexion;
    Consulta.SQL.Text :=
      'DELETE FROM ' + FModo.FCfgTallas.TablaCeldas +
      ' WHERE ' + FModo.FCfgTallas.FieldSerieCel + ' = :s' +
      FModo.WhereNumero('') +
      FModo.WhereDocExtra;
    Consulta.ParamByName('s').AsString :=
      FModo.FCfgTallas.SourceMaster.DataSet.FieldByName(
        FModo.FCfgTallas.FieldSerieMaster).AsString;
    FModo.ParamNumero(Consulta);
    FModo.ParamsDocExtra(Consulta);
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TDesmontajeTallas.Ejecutar;
begin
  FEnProcesoPrevio := FModo.FEnProceso;
  FModo.FEnProceso := True;
  try
    FTransaccionPropia := not FModo.FConfig.Conexion.InTransaction;
    if FTransaccionPropia then
      FModo.FConfig.Conexion.StartTransaction;
    try
      FUnidadesAntes := FModo.UnidadesDocumento;
      CargarCeldas;
      if FCeldas.Count > 0 then
      begin
        ExpandirCeldas;
        BorrarCeldas;
        FModo.LogSes(Format(
          'ModoTallas.Desmontar: %d celdas expandidas a lineas',
          [FCeldas.Count]));
        FExpandio := True;
      end;
      FModo.FEnProceso := FEnProcesoPrevio;
      if FExpandio then
        FModo.ComprobarInvarianteUnidades(
          'Desmontar', FUnidadesAntes, FModo.UnidadesDocumento);
      if FTransaccionPropia then
        FModo.FConfig.Conexion.Commit;
    except
      if FTransaccionPropia then
        FModo.FConfig.Conexion.Rollback;
      raise;
    end;
  finally
    FModo.FEnProceso := FEnProcesoPrevio;
  end;
  FModo.NotificarPostsSilenciados;
end;

constructor TModoEntradaTallas.Create(const AConfig: TConfigColumnasSku;
                                      const ACfgTallas: TGridTallasConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FCfgTallas := ACfgTallas;
  FLookup := TArticulosAtributosLookup.Create(AConfig.Conexion);
  FTimerResolve := TTimer.Create(nil);
  FTimerResolve.Enabled := False;
  FTimerResolve.Interval := 1;
  FTimerResolve.OnTimer := TimerResolveTimer;
  FTimerBusq := TTimer.Create(nil);
  FTimerBusq.Enabled := False;
  FTimerBusq.Interval := 350;
  FTimerBusq.OnTimer := TimerBusqTimer;
  FTimerCarga := TTimer.Create(nil);
  FTimerCarga.Enabled := False;
  FTimerCarga.Interval := 1;
  FTimerCarga.OnTimer := TimerCargaTimer;
  FTimerRecarga := TTimer.Create(nil);
  FTimerRecarga.Enabled := False;
  FTimerRecarga.Interval := 1;
  FTimerRecarga.OnTimer := TimerRecargaTimer;
end;

procedure TModoEntradaTallas.LogSes(const ATexto: string);
begin
  if Assigned(FConfig.ContextoSesion) then
    FConfig.ContextoSesion.LogSesion(ATexto);
end;

destructor TModoEntradaTallas.Destroy;
begin
  // Desenganchar los eventos del REPOSITORIO antes de liberar nada:
  // liberar FBusqRepo dispara SetView(nil) en las properties del
  // combo, el editor cacheado del grid sincroniza su texto, salta su
  // Change y ArtChange tocaria FTimerBusq ya liberado (AV nil+$50;
  // visto en call stack real al cambiar de modo).
  if FRepCombo <> nil then
  begin
    FRepCombo.Properties.OnChange := nil;
    FRepCombo.Properties.OnInitPopup := nil;
    FRepCombo.Properties.OnCloseUp := nil;
  end;
  // Devolver los hooks del cds a su duenyo (solo si los enganchamos).
  if FGestor <> nil then
  begin
    FConfig.Cds.AfterPost := FAfterPostOrig;
    FConfig.Cds.AfterScroll := FAfterScrollOrig;
  end;
  FreeAndNil(FTimerRecarga);
  FreeAndNil(FTimerCarga);
  FreeAndNil(FTimerBusq);
  FreeAndNil(FTimerResolve);
  FreeAndNil(FEditRepo);
  FreeAndNil(FBusqRepo);
  FreeAndNil(FBusqDs);
  FreeAndNil(FBusqQry);
  FreeAndNil(FGestor);
  FreeAndNil(FLookup);
  inherited;
end;

function TModoEntradaTallas.GetModo: TModoColumnasSku;
begin
  Result := mcsTallasInline;
end;

function TModoEntradaTallas.GetOnResuelto: TSkuResueltoEvent;
begin
  Result := FOnResuelto;
end;

procedure TModoEntradaTallas.SetOnResuelto(const AValue: TSkuResueltoEvent);
begin
  FOnResuelto := AValue;
end;

function TModoEntradaTallas.GetOnEntrarEdicion: TNotifyEvent;
begin
  Result := FOnEntrarEdicion;
end;

procedure TModoEntradaTallas.SetOnEntrarEdicion(const AValue: TNotifyEvent);
begin
  FOnEntrarEdicion := AValue;
end;

function TModoEntradaTallas.GetOnSalirEdicion: TNotifyEvent;
begin
  Result := FOnSalirEdicion;
end;

procedure TModoEntradaTallas.SetOnSalirEdicion(const AValue: TNotifyEvent);
begin
  FOnSalirEdicion := AValue;
end;

procedure TModoEntradaTallas.SetAlmacenStock(const AValue: string);
begin
  // El stock del desplegable de busqueda depende del almacen: se
  // invalida el dataset y la proxima busqueda reconsulta.
  if FConfig.AlmacenStock <> AValue then
  begin
    FConfig.AlmacenStock := AValue;
    FUltimoFiltro := #1;
    if (FBusqQry <> nil) and FBusqQry.Active then
      FBusqQry.Close;
  end;
end;

procedure TModoEntradaTallas.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaTallas.Construir;
var
  i: Integer;
  Col: TcxGridDBColumn;
  bTxPropia: Boolean;
  rUdsAntes: Double;
begin
  // El desplegable de busqueda debe existir antes que su columna.
  CrearLookupBusqueda;
  FConfig.View.BeginUpdate;
  try
    FConfig.View.ClearItems;
    // Columna de articulo (bound); la resolucion va por el validador.
    FColArticulo := FConfig.View.CreateColumn;
    FColArticulo.Caption := 'Artículo';
    FColArticulo.DataBinding.FieldName := FConfig.Campos.CodigoArt;
    FColArticulo.Width := 140;
    // Sugerencias incrementales en la celda vacia y enfocada.
    FColArticulo.OnGetProperties := ArtGetProperties;
    // Columnas de atributos no talla (color...), ocultas hasta usarse.
    // Tag negativo para no chocar con las posiciones de talla.
    for i := 1 to 5 do
    begin
      FColAtributo[i] := nil;
      if FConfig.Campos.AttrValor[i] <> '' then
      begin
        FColAtributo[i] := FConfig.View.CreateColumn;
        FColAtributo[i].Tag := -i;
        FColAtributo[i].Caption := '-';
        FColAtributo[i].Visible := False;
        FColAtributo[i].Width := 90;
        FColAtributo[i].Options.Editing := False;
        FColAtributo[i].DataBinding.FieldName :=
          FConfig.Campos.AttrValor[i];
        FColAtributo[i].OnCustomDrawCell := AtributoCustomDrawCell;
      end;
    end;
    // N columnas de talla no-bound: Tag = posicion 1..N del conjunto.
    // MISMO mecanismo que sesiones de compra (CrearColumnasTallas):
    // ValueTypeClass float — sin el, una columna no-bound de un view DB
    // DESCARTA lo tecleado — y editor Currency con formato entero.
    SetLength(FCfgTallas.ColumnasTallas, FCfgTallas.MaxColumnas);
    for i := 1 to FCfgTallas.MaxColumnas do
    begin
      Col := FConfig.View.CreateColumn;
      Col.Tag := i;
      Col.Caption := '·';
      Col.Width := 46;
      Col.Visible := False;
      Col.DataBinding.ValueTypeClass := TcxFloatValueType;
      Col.PropertiesClass := TcxCurrencyEditProperties;
      with TcxCurrencyEditProperties(Col.Properties) do
      begin
        DisplayFormat := '#,##0';
        OnEditValueChanged := CeldaTallaCambiada;
      end;
      FCfgTallas.ColumnasTallas[i - 1] := Col;
    end;
    // Columnas OCULTAS bound a LINEA e ID_AC_PIVOT: el gestor las lee
    // del DataController (GetColumnByFieldName) para cargar las celdas
    // fila a fila. Sin ellas, la carga se salta en silencio.
    with FConfig.View.CreateColumn do
    begin
      DataBinding.FieldName := FCfgTallas.FieldLinea;
      Visible := False;
      Options.Editing := False;
    end;
    with FConfig.View.CreateColumn do
    begin
      DataBinding.FieldName := FCfgTallas.FieldConjuntoPivot;
      Visible := False;
      Options.Editing := False;
    end;
  finally
    FConfig.View.EndUpdate;
  end;
  FConfig.View.OnInitEdit := ViewInitEdit;
  FConfig.View.OnEditKeyDown := ViewEditKeyDown;
  FConfig.View.OnFocusedRecordChanged := FocoLineaCambiado;
  FConfig.View.OnFocusedItemChanged := FocoItemCambiado;
  // Formato distribuido: la edicion inline de celdas de talla se
  // bloquea y las cantidades entran por el modal distribuidor. El
  // almacen por defecto es OBLIGATORIO en este formato (si el
  // documento no lo trae, se resuelve o se aborta con excepcion).
  if FConfig.Distribuido then
  begin
    AsegurarAlmacenDefecto;
    FConfig.View.OnEditing := ViewEditing;
  end;
  FConfig.View.OptionsBehavior.GoToNextCellOnEnter := True;
  // El Tab (y el Enter convertido por EnterAsTab) avanza ENTRE CELDAS
  // del grid, no al siguiente control del form.
  FConfig.View.OptionsBehavior.FocusCellOnTab := True;
  FConfig.View.OptionsView.ColumnAutoWidth := False;
  FCfgTallas.Conexion := FConfig.Conexion;
  FCfgTallas.Grid := FConfig.View;
  // El gestor antes de la conversion: la conversion persiste celdas.
  FGestor := TGestorGridTallas.Create(FCfgTallas);
  // Hook AfterPost (como sesiones): recarga celdas tras el Post
  // implicito de cambiar de fila. Silenciado hasta acabar la carga
  // diferida (FEnProceso) para no recargar N veces en la conversion.
  FEnProceso := True;
  FAfterPostOrig := FConfig.Cds.AfterPost;
  FConfig.Cds.AfterPost := CdsAfterPost;
  FAfterScrollOrig := FConfig.Cds.AfterScroll;
  FConfig.Cds.AfterScroll := CdsAfterScroll;
  // Conversion ATOMICA: la fusion mezcla posts de dataset y SQL
  // directo (SumarEnCelda); interrumpida a medias dejaba celdas ya
  // sumadas con lineas sin fusionar y cada reentrada volvia a sumar
  // (cantidades duplicadas y pedida disparada).
  bTxPropia := not FConfig.Conexion.InTransaction;
  if bTxPropia then
    FConfig.Conexion.StartTransaction;
  try
    rUdsAntes := UnidadesDocumento;
    // Lineas heredadas de otros modos / documento reabierto: derivar
    // pivote y atributos, volcar cantidades y fusionar duplicadas.
    RederivarLineasExistentes;
    // Unificar celdas segun el formato (las heredadas se vuelcan a
    // almacen '', por eso la migracion va DESPUES del rederivar).
    MigrarCeldasAlmacen;
    // La fusion no puede perder ni duplicar unidades: si no cuadra,
    // excepcion y rollback (el host degrada a modo SKU con los datos
    // intactos).
    ComprobarInvarianteUnidades('Construir', rUdsAntes,
                                UnidadesDocumento);
    if bTxPropia then
      FConfig.Conexion.Commit;
  except
    if bTxPropia then
      FConfig.Conexion.Rollback;
    raise;
  end;
  // La carga visual (columnas visibles, cantidades y rotulos) se
  // DIFIERE un tick: el host anyade sus columnas tras Construir y eso
  // resetea los Values[] no-bound del DataController.
  FTimerCarga.Enabled := False;
  FTimerCarga.Enabled := True;
end;

// Unidades totales del documento: SUM(celdas) + CANTIDAD de las lineas
// sin celdas. Las lineas pivotadas NO aportan su CANTIDAD (total
// derivado que podria venir desincronizado): asi la medida no da
// falsos positivos con documentos ya tocados y detecta perdidas o
// duplicados reales de la conversion.
function TModoEntradaTallas.UnidadesDocumento: Double;
var
  Qry: TUniQuery;
  ds: TDataSet;
  ConCeldas: TDictionary<Integer, Boolean>;
  bk: TBookmark;
begin
  Result := 0;
  ds := FConfig.Cds;
  if (ds <> nil) and ds.Active then
  begin
    ConCeldas := TDictionary<Integer, Boolean>.Create;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN,' +
        ' COALESCE(SUM(' + FCfgTallas.FieldCantidadCel + '), 0)' +
        ' AS TOTAL' +
        ' FROM ' + FCfgTallas.TablaCeldas +
        ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
        WhereNumero('') +
        WhereDocExtra +
        ' GROUP BY ' + FCfgTallas.FieldLineaCel;
      Qry.ParamByName('s').AsString :=
        FCfgTallas.SourceMaster.DataSet.FieldByName(
          FCfgTallas.FieldSerieMaster).AsString;
      ParamNumero(Qry);
      ParamsDocExtra(Qry);
      Qry.Open;
      while not Qry.Eof do
      begin
        ConCeldas.AddOrSetValue(
          Qry.FieldByName('LIN').AsInteger, True);
        Result := Result + Qry.FieldByName('TOTAL').AsFloat;
        Qry.Next;
      end;
      // Lineas sin celdas (escalares o sin fusionar): su cantidad
      // vive en la propia linea.
      if (not ds.IsEmpty) and
         (ds.FindField(FConfig.Campos.Cantidad) <> nil) then
      begin
        bk := ds.GetBookmark;
        ds.DisableControls;
        try
          ds.First;
          while not ds.Eof do
          begin
            if not ConCeldas.ContainsKey(
                 ds.FieldByName(FCfgTallas.FieldLinea).AsInteger) then
              Result := Result +
                ds.FieldByName(FConfig.Campos.Cantidad).AsFloat;
            ds.Next;
          end;
          if ds.BookmarkValid(bk) then
            ds.GotoBookmark(bk);
        finally
          ds.FreeBookmark(bk);
          ds.EnableControls;
        end;
      end;
    finally
      FreeAndNil(Qry);
      FreeAndNil(ConCeldas);
    end;
  end;
end;

procedure TModoEntradaTallas.ComprobarInvarianteUnidades(
  const AContexto: string; AAntes, ADespues: Double);
begin
  if Abs(AAntes - ADespues) > 0.001 then
  begin
    LogSes(Format('ModoTallas.%s: INVARIANTE ROTO unidades ' +
                  'antes=%.4f despues=%.4f; se deshace la conversion',
                  [AContexto, AAntes, ADespues]));
    raise Exception.CreateFmt(SErrorInvarianteUnidadesTallas,
      [AContexto, AAntes, ADespues]);
  end;
end;

procedure TModoEntradaTallas.RefrescarTotalesTodasLineas;
var
  Qry: TUniQuery;
  ds: TDataSet;
  Tot: TDictionary<Integer, Double>;
  bk: TBookmark;
  iLinea: Integer;
  rTot, rPr: Double;
  bPivotada: Boolean;
begin
  ds := FConfig.Cds;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) and
     (ds.FindField(FCfgTallas.FieldTotalUds) <> nil) then
  begin
    Tot := TDictionary<Integer, Double>.Create;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN,' +
        ' COALESCE(SUM(' + FCfgTallas.FieldCantidadCel + '), 0)' +
        ' AS TOTAL' +
        ' FROM ' + FCfgTallas.TablaCeldas +
        ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
        WhereNumero('') +
        WhereDocExtra +
        ' GROUP BY ' + FCfgTallas.FieldLineaCel;
      Qry.ParamByName('s').AsString :=
        FCfgTallas.SourceMaster.DataSet.FieldByName(
          FCfgTallas.FieldSerieMaster).AsString;
      ParamNumero(Qry);
      ParamsDocExtra(Qry);
      Qry.Open;
      while not Qry.Eof do
      begin
        Tot.AddOrSetValue(Qry.FieldByName('LIN').AsInteger,
                          Qry.FieldByName('TOTAL').AsFloat);
        Qry.Next;
      end;
      bk := ds.GetBookmark;
      ds.DisableControls;
      try
        ds.First;
        while not ds.Eof do
        begin
          iLinea := ds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
          // Solo lineas PIVOTADAS: una linea sin conjunto pivote no
          // deberia tener celdas; si las hay a su numero son residuo
          // de una conversion rota y volcar su suma aqui machacaba la
          // cantidad real con basura (cantidades desorbitadas,
          // 10/07/26).
          bPivotada := (FCfgTallas.FieldConjuntoPivot = '') or
            (ds.FindField(FCfgTallas.FieldConjuntoPivot) = nil) or
            (ds.FieldByName(
               FCfgTallas.FieldConjuntoPivot).AsInteger > 0);
          if (not bPivotada) and Tot.ContainsKey(iLinea) then
            LogSes(Format('ModoTallas.RefrescarTotales: linea %d sin ' +
                   'pivote con celdas a su numero; se IGNORAN ' +
                   '(residuo de conversion rota)', [iLinea]));
          // Solo lineas CON celdas: las escalares (sin tallaje) llevan
          // su cantidad en la propia linea y este refresco las dejaba
          // a 0 (la clave no estaba en Tot y se posteaba el 0).
          if bPivotada and Tot.TryGetValue(iLinea, rTot) then
          begin
            rPr := 0;
            if ds.FindField(FCfgTallas.FieldPrecioBase) <> nil then
              rPr :=
                ds.FieldByName(FCfgTallas.FieldPrecioBase).AsFloat;
            if ds.FieldByName(
                 FCfgTallas.FieldTotalUds).AsFloat <> rTot then
            begin
              if not (ds.State in [dsEdit, dsInsert]) then
                ds.Edit;
              ds.FieldByName(FCfgTallas.FieldTotalUds).AsFloat := rTot;
              if ds.FindField(FCfgTallas.FieldTotalLinea) <> nil then
                ds.FieldByName(FCfgTallas.FieldTotalLinea).AsFloat :=
                  rTot * rPr;
              ds.Post;
            end;
          end;
          ds.Next;
        end;
        if ds.BookmarkValid(bk) then
          ds.GotoBookmark(bk);
      finally
        ds.FreeBookmark(bk);
        ds.EnableControls;
      end;
    finally
      FreeAndNil(Qry);
      FreeAndNil(Tot);
    end;
  end;
end;

procedure TModoEntradaTallas.TimerCargaTimer(Sender: TObject);
begin
  FTimerCarga.Enabled := False;
  if FGestor <> nil then
  begin
    FGestor.RecalcularMaxColumnas;
    // Totales ANTES de cargar celdas: escribirlos mueve el cursor y
    // repinta filas, lo que limpiaria los Values[] no-bound.
    RefrescarTotalesTodasLineas;
    // Reposicionar TAMBIEN antes de cargar: el scroll del First
    // resetea los Values[] no-bound igual que el EnableControls. El
    // foco tras construir suele quedar en la linea en blanco (pivote
    // 0) y los rotulos se quedarian en el generico 'Talla N'.
    if FConfig.Cds.FieldByName(
         FCfgTallas.FieldConjuntoPivot).AsInteger = 0 then
      FConfig.Cds.First;
    // La carga de celdas, SIEMPRE lo ultimo que toca el grid.
    FGestor.CargarCantidadesTodasLineas;
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
    // Conversion terminada: a partir de aqui el hook AfterPost recarga
    // las celdas tras cada Post del usuario.
    FEnProceso := False;
    NotificarPostsSilenciados;
  end;
end;

procedure TModoEntradaTallas.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  // EnterAsTab SOLO se desactiva en la celda de articulo (su Enter
  // resuelve la entrada). En las celdas de talla se deja ACTIVO: el
  // Enter actua como Tab y avanza de talla en talla mientras cada
  // salida de celda persiste su cantidad — igual que en sesiones de
  // compra (ActivarEnterComoTab).
  if AItem = FColArticulo then
  begin
    if Assigned(FOnEntrarEdicion) then
      FOnEntrarEdicion(AEdit);
    THackWinControl(AEdit).OnExit := EditorSalir;
    // Sugerencias en vivo: cada tecleo rearma el debounce que abre el
    // desplegable filtrado (articulo/SKU/barras/ref proveedor).
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange := ArtChange;
    LogSes('ModoTallas.InitEdit articulo: editor=' + AEdit.ClassName);
  end;
end;

procedure TModoEntradaTallas.ArtGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vVal: Variant;
  bVacia, bEnfocada: Boolean;
begin
  if (ARecord <> nil) and (FRepCombo <> nil) then
  begin
    vVal := ARecord.Values[Sender.Index];
    bVacia := VarIsNull(vVal) or (Trim(VarToStr(vVal)) = '');
    bEnfocada :=
      (FConfig.View.Controller.FocusedRecord = ARecord) and
      (FConfig.View.Controller.FocusedItem = Sender);
    if bVacia and bEnfocada then
      AProperties := FRepCombo.Properties;
  end;
end;

procedure TModoEntradaTallas.ArtChange(Sender: TObject);
begin
  // Guarda: el Change puede saltar en plena destruccion del modo.
  if FTimerBusq <> nil then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end;
end;

procedure TModoEntradaTallas.TimerBusqTimer(Sender: TObject);
var
  Edit: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  FTimerBusq.Enabled := False;
  if not FConfig.View.Controller.EditingController.IsEditing then
    LogSes('ModoTallas.Busq: sin editor activo')
  else
  begin
    Edit := FConfig.View.Controller.EditingController.Edit;
    if not (Edit is TcxExtLookupComboBox) then
      LogSes('ModoTallas.Busq: editor no es combo (' +
             Edit.ClassName + ')')
    else
    begin
      Combo := TcxExtLookupComboBox(Edit);
      // Text, no EditingValue (el texto libre no llega alli); y si el
      // combo autocompleto, lo tecleado es lo previo a la seleccion.
      sTexto := Combo.Text;
      if Combo.SelLength > 0 then
        sTexto := Copy(sTexto, 1, Combo.SelStart);
      sTexto := Trim(sTexto);
      LogSes('ModoTallas.Busq: texto="' + sTexto + '"');
      if Length(sTexto) >= 3 then
      begin
        AbrirBusquedaFiltrada(sTexto);
        LogSes(Format('ModoTallas.Busq: %d coincidencias',
                      [FBusqQry.RecordCount]));
        if not Combo.DroppedDown then
          Combo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.CrearLookupBusqueda;
begin
  if FBusqQry = nil then
  begin
    FBusqQry := TUniQuery.Create(nil);
    FBusqQry.Connection := FConfig.Conexion;
    FBusqDs := TDataSource.Create(nil);
    FBusqDs.DataSet := FBusqQry;
    FBusqRepo := TcxGridViewRepository.Create(nil);
    FBusqView := FBusqRepo.CreateItem(TcxGridDBTableView)
                   as TcxGridDBTableView;
    FBusqView.DataController.DataSource := FBusqDs;
    FBusqView.DataController.KeyFieldNames := 'SKU';
    FBusqView.DataController.DataModeController.GridMode := True;
    // Sin sincronizar el cursor del dataset con la fila enfocada del
    // desplegable (como dbtvBusq de caja).
    FBusqView.DataController.DataModeController.SyncMode := False;
    FBusqView.OptionsView.GroupByBox := False;
    FBusqView.OptionsSelection.CellSelect := False;
    FBusqView.OptionsBehavior.IncSearch := False;
    FBusqColSku := FBusqView.CreateColumn;
    FBusqColSku.Caption := 'SKU';
    FBusqColSku.DataBinding.FieldName := 'SKU';
    FBusqColSku.Width := 200;
    FBusqColInput := FBusqView.CreateColumn;
    FBusqColInput.DataBinding.FieldName := 'INPUT_BUSQUEDA';
    FBusqColInput.PropertiesClass := TcxTextEditProperties;
    TcxTextEditProperties(FBusqColInput.Properties).IncrementalSearch :=
      False;
    FBusqColInput.Visible := False;
    FBusqColInput.Options.Filtering := False;
    FBusqColInput.Options.FilteringPopup := False;
    FBusqColInput.Options.IncSearch := False;
    FBusqColInput.Options.Grouping := False;
    with FBusqView.CreateColumn do
    begin
      Caption := 'Descripción';
      DataBinding.FieldName := 'DESCRIPCION';
      Width := 220;
    end;
    with FBusqView.CreateColumn do
    begin
      Caption := 'Cód. barras';
      DataBinding.FieldName := 'CODBARRAS';
      // 130: un EAN13 completo (el reparto de DropDownAutoWidth podia
      // dejarla corta y el codigo parecia truncado).
      Width := 130;
    end;
    with FBusqView.CreateColumn do
    begin
      Caption := 'Ref. prov.';
      DataBinding.FieldName := 'REFPRV';
      Width := 110;
    end;
    with FBusqView.CreateColumn do
    begin
      Caption := 'Stock';
      DataBinding.FieldName := 'STOCK';
      Width := 60;
    end;
    FEditRepo := TcxEditRepository.Create(nil);
    FRepCombo := FEditRepo.CreateItem(
                   TcxEditRepositoryExtLookupComboBoxItem)
                   as TcxEditRepositoryExtLookupComboBoxItem;
    with FRepCombo.Properties do
    begin
      View := FBusqView;
      KeyFieldNames := 'SKU';
      ListFieldItem := FBusqColInput;
      DropDownListStyle := lsEditList;
      IncrementalFiltering := False;
      AutoSearchOnPopup := False;
      DropDownRows := 15;
      DropDownAutoWidth := True;
      ImmediateDropDownWhenKeyPressed := False;
      OnInitPopup := ComboBusqInitPopup;
      OnCloseUp := ComboBusqCloseUp;
      // En el repositorio: los clones de properties heredan el evento
      // (el hook por editor se pierde con AlwaysShowEditor).
      OnChange := ArtChange;
    end;
  end;
end;

// Consulta UNION de inLibGridArticulos: prefijo en SKU (que empieza
// por el codigo de articulo), codigo de barras y referencia / modelo
// de proveedor, y contenido en la descripcion. Barras, referencias y
// stock se calculan solo para las <=100 filas devueltas.
procedure TModoEntradaTallas.AbrirBusquedaFiltrada(const ATexto: string);
const
  SQL_CABECERA =
    'SELECT x.SKU,' +
    '       x.SKU AS INPUT_BUSQUEDA,' +
    '       x.DESCRIPCION,' +
    // CAST explicito: sin el, el metadato de longitud que MariaDB
    // declara para el subquery GROUP_CONCAT se queda corto y UniDAC
    // trunca los codigos (EAN13 recortados a 11 caracteres).
    '       CAST(COALESCE((SELECT GROUP_CONCAT(' +
    '                             DISTINCT cb.CODIGO_BARRAS_CB' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_codigos_barras cb' +
    '                  WHERE cb.CODIGO_UNIDAD_CB = x.SKU), '''')' +
    '            AS CHAR(120)) AS CODBARRAS,' +
    '       CAST(COALESCE((SELECT GROUP_CONCAT(' +
    '                             DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = x.ART' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL), '''')' +
    '            AS CHAR(120)) AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                  WHERE st.CODIGO_UNIDAD_STK = x.SKU' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM ';
  SQL_SIN_FILTRO =
    '(SELECT s.CODIGO_UNIDAD_SKU AS SKU, s.CODIGO_ART_SKU AS ART,' +
    '        a.DESCRIPCION_ART AS DESCRIPCION' +
    '   FROM fza_articulos_skus s' +
    '   JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '  WHERE s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '    AND a.TIPO_ART = ''ESTANDAR''' +
    '  ORDER BY s.CODIGO_UNIDAD_SKU LIMIT 100) x';
  SQL_CON_FILTRO =
    '((SELECT s.CODIGO_UNIDAD_SKU AS SKU, s.CODIGO_ART_SKU AS ART,' +
    '         a.DESCRIPCION_ART AS DESCRIPCION' +
    '    FROM fza_articulos_skus s' +
    '    JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '   WHERE s.CODIGO_UNIDAD_SKU LIKE :TPREF' +
    '     AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '     AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_articulos a' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '    WHERE a.DESCRIPCION_ART LIKE :TDESC' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_codigos_barras cb' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB' +
    '     JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '    WHERE cb.CODIGO_BARRAS_CB LIKE :TPREF' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_articulos_proveedores ap' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_ART_SKU = ap.CODIGO_ART_AP' +
    '     JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '    WHERE ap.REF_PROVEEDOR_AP LIKE :TPREF' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    ' ) x';
  SQL_ORDEN = ' ORDER BY STOCK DESC, x.SKU LIMIT 100';
begin
  if FBusqQry <> nil then
  begin
    // Siempre: aunque la query ya este abierta con el mismo filtro,
    // el desplegable puede tener filtro interno pegado (autocompletado).
    LimpiarFiltroDesplegable;
    if not (FBusqQry.Active and (FUltimoFiltro = ATexto)) then
    begin
      Screen.Cursor := crHourGlass;
      FBusqView.BeginUpdate;
      try
        // Desenganchar la vista mientras se recambia la query evita
        // que reaplique su filtro sobre el dataset a medio abrir.
        FBusqView.DataController.DataSource := nil;
        if FBusqQry.Active then
          FBusqQry.Close;
        if ATexto = '' then
          FBusqQry.SQL.Text := SQL_CABECERA + SQL_SIN_FILTRO + SQL_ORDEN
        else
        begin
          FBusqQry.SQL.Text := SQL_CABECERA + SQL_CON_FILTRO + SQL_ORDEN;
          FBusqQry.ParamByName('TPREF').AsString := ATexto + '%';
          FBusqQry.ParamByName('TDESC').AsString := '%' + ATexto + '%';
        end;
        FBusqQry.ParamByName('ALM').AsString :=
          Trim(FConfig.AlmacenStock);
        FBusqQry.Open;
        FUltimoFiltro := ATexto;
        FBusqView.DataController.DataSource := FBusqDs;
        FBusqView.DataController.Refresh;
      finally
        FBusqView.EndUpdate;
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

function TModoEntradaTallas.NumeroDocTallas: string;
begin
  Result := '';
  if FCfgTallas.FieldNumeroMaster <> '' then
    Result := FCfgTallas.SourceMaster.DataSet.FieldByName(
      FCfgTallas.FieldNumeroMaster).AsString;
end;

function TModoEntradaTallas.WhereNumero(const APrefijo: string): string;
begin
  // APrefijo: alias de la tabla de celdas ('c.' en el des-pivote).
  Result := '';
  if FCfgTallas.FieldNumeroCel <> '' then
    Result := ' AND ' + APrefijo + FCfgTallas.FieldNumeroCel + ' = :n';
end;

function TModoEntradaTallas.ColsInsertNumero: string;
begin
  Result := '';
  if FCfgTallas.FieldNumeroCel <> '' then
    Result := FCfgTallas.FieldNumeroCel + ', ';
end;

function TModoEntradaTallas.ValsInsertNumero: string;
begin
  Result := '';
  if FCfgTallas.FieldNumeroCel <> '' then
    Result := ':n, ';
end;

procedure TModoEntradaTallas.ParamNumero(AQuery: TUniQuery);
begin
  if FCfgTallas.FieldNumeroCel <> '' then
    AQuery.ParamByName('n').AsString := NumeroDocTallas;
end;

function TModoEntradaTallas.WhereDocExtra: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(FCfgTallas.CamposDocExtraCel) do
    Result := Result + ' AND ' + FCfgTallas.CamposDocExtraCel[i] +
              ' = :x' + IntToStr(i) + ' ';
end;

function TModoEntradaTallas.ColsInsertDocExtra: string;
var
  i: Integer;
begin
  // 'CAMPO, ' por cada clave extra, para intercalar tras SERIE/NUMERO
  // en la lista de columnas del INSERT.
  Result := '';
  for i := 0 to High(FCfgTallas.CamposDocExtraCel) do
    Result := Result + FCfgTallas.CamposDocExtraCel[i] + ', ';
end;

function TModoEntradaTallas.ValsInsertDocExtra: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(FCfgTallas.CamposDocExtraCel) do
    Result := Result + ':x' + IntToStr(i) + ', ';
end;

procedure TModoEntradaTallas.ParamsDocExtra(AQuery: TUniQuery);
var
  ds: TDataSet;
  i: Integer;
begin
  ds := FCfgTallas.SourceMaster.DataSet;
  if ds <> nil then
    for i := 0 to High(FCfgTallas.CamposDocExtraMaster) do
      AQuery.ParamByName('x' + IntToStr(i)).AsString :=
        ds.FieldByName(FCfgTallas.CamposDocExtraMaster[i]).AsString;
end;

procedure TModoEntradaTallas.LimpiarFiltroDesplegable;
begin
  if FBusqView <> nil then
  begin
    FBusqView.BeginUpdate;
    try
      FBusqView.Controller.IncSearchingText := '';
      FBusqView.DataController.Filter.Clear;
      FBusqView.DataController.Filter.Active := False;
      FBusqView.DataController.Filter.AutoDataSetFilter := False;
      // RESET imprescindible: sin Refresh la vista sigue mostrando el
      // conjunto filtrado viejo aunque el filtro ya este vacio (caja
      // lo hace en repComboBoxPropertiesInitPopup).
      FBusqView.DataController.Refresh;
    finally
      FBusqView.EndUpdate;
    end;
  end;
end;

procedure TModoEntradaTallas.ComboBusqInitPopup(Sender: TObject);
var
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  sTexto := '';
  if Sender is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(Sender);
    // Si el combo autocompleto, lo tecleado es lo previo a la seleccion.
    sTexto := Combo.Text;
    if Combo.SelLength > 0 then
      sTexto := Copy(sTexto, 1, Combo.SelStart);
    sTexto := Trim(sTexto);
  end;
  // Con el desplegable abierto, el Enter elige fila (no Tab).
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
  AbrirBusquedaFiltrada(sTexto);
end;

procedure TModoEntradaTallas.ComboBusqCloseUp(Sender: TObject);
begin
  LimpiarFiltroDesplegable;
  // NO se restaura aqui el EnterAsTab: el foco sigue en la celda y el
  // siguiente Enter debe llegar al grid (mismo arreglo que
  // inLibGridArticulos). Restauran EditorSalir / FocoItemCambiado.
  // Resolver el SKU elegido de forma diferida (mismo timer que el
  // Enter): consolida la linea y suma la talla en su celda.
  if Sender is TcxCustomEdit then
  begin
    FEntradaPend := Trim(VarToStr(TcxCustomEdit(Sender).EditValue));
    if FEntradaPend <> '' then
    begin
      FTimerResolve.Enabled := False;
      FTimerResolve.Enabled := True;
    end;
  end;
end;

procedure TModoEntradaTallas.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  sEntrada: string;
begin
  // F3 en la celda de articulo: despliega la busqueda incremental
  // filtrada por lo tecleado.
  if (AItem = FColArticulo) and (Key = VK_F3) then
  begin
    Key := 0;
    if AEdit is TcxCustomDropDownEdit then
      TcxCustomDropDownEdit(AEdit).DroppedDown := True;
  end
  // Teclas de texto en la celda de articulo: rearman el debounce de
  // la busqueda incremental. El OnChange del lookup NO es fiable
  // (deja de disparar tras el primer autocompletado); el KeyDown del
  // grid llega SIEMPRE, tecla a tecla.
  else if (AItem = FColArticulo) and
          ((Key = VK_BACK) or (Key = VK_DELETE) or
           ((Key >= Ord('0')) and
            not ((Key >= VK_F1) and (Key <= VK_F24)))) then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end
  // Enter en la celda de articulo (tecleo o lector Codigo+CR).
  else if (AItem = FColArticulo) and (Key = VK_RETURN) then
  begin
    // Si el desplegable esta abierto, cerrarlo elige la fila y el
    // Enter no se queda consumido en el dropdown.
    if (AEdit is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      sEntrada := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      sEntrada := Trim(VarToStr(AEdit.EditValue));
    if sEntrada <> '' then
    begin
      Key := 0;
      LogSes('ModoTallas.EditKeyDown: Enter con "' + sEntrada + '"');
      FEntradaPend := sEntrada;
      FTimerResolve.Enabled := False;
      FTimerResolve.Enabled := True;
    end;
  end;
end;

procedure TModoEntradaTallas.EnfocarColumnaPorCampo(
  const ACampo: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  if ACampo <> '' then
    for i := 0 to FConfig.View.ColumnCount - 1 do
    begin
      Col := FConfig.View.Columns[i];
      if SameText(Col.DataBinding.FieldName, ACampo) then
        Col.Focused := True;
    end;
end;

procedure TModoEntradaTallas.TimerResolveTimer(Sender: TObject);
var
  sEntrada: string;
  iAc: Integer;
begin
  FTimerResolve.Enabled := False;
  sEntrada := FEntradaPend;
  FEntradaPend := '';
  if sEntrada <> '' then
  begin
    if ResolverEntrada(sEntrada) then
    begin
      if FConfig.View.Controller.EditingController.IsEditing then
        try
          FConfig.View.Controller.EditingController.HideEdit(False);
        except
          on E: EInvalidOperation do
            ;
        end;
      // Resuelto y editor cerrado: se restaura el EnterAsTab (si el
      // foco vuelve a la celda del combo, InitEdit lo desactiva).
      if Assigned(FOnSalirEdicion) then
        FOnSalirEdicion(nil);
      if FUltimaConTalla then
      begin
        // Lectura con talla (SKU/barras): la cantidad ya se sumo en su
        // celda. Volvemos a la linea en blanco (si la hay) y dejamos
        // el editor de articulo listo para encadenar lecturas.
        FConfig.Cds.Locate(FConfig.Campos.CodigoArt, '', []);
        MostrarEditor;
      end
      else
      begin
        // Sin talla en la entrada: si la linea tiene sistema, foco a
        // la primera celda de talla; si no (servicios, gastos...), a
        // la columna de cantidad del documento.
        iAc := 0;
        if FConfig.Cds.FindField(FCfgTallas.FieldConjuntoPivot) <> nil
        then
          iAc := FConfig.Cds.FieldByName(
                   FCfgTallas.FieldConjuntoPivot).AsInteger;
        if (iAc > 0) and (Length(FCfgTallas.ColumnasTallas) > 0) and
           (FCfgTallas.ColumnasTallas[0] <> nil) and
           FCfgTallas.ColumnasTallas[0].Visible then
          FCfgTallas.ColumnasTallas[0].Focused := True
        else
          EnfocarColumnaPorCampo(FConfig.Campos.Cantidad);
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.AsegurarAlmacenDefecto;
var
  Qry: TUniQuery;
begin
  if Trim(FConfig.AlmacenStock) = '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      // Mismo criterio de almacenes que el distribuidor.
      Qry.SQL.Text :=
        'SELECT CODIGO_ALM_ALM FROM fza_almacenes' +
        ' WHERE ESACTIVO_ALM = ''S''' +
        '   AND TIPO_USO_ALM IN (''ESTANDAR'', ''ESTANDARD'')' +
        ' ORDER BY CODIGO_ALM_ALM LIMIT 1';
      Qry.Open;
      if Qry.Eof then
        raise Exception.Create(SErrorAlmacenDistribucionTallasNoDisponible);
      FConfig.AlmacenStock := Qry.Fields[0].AsString;
      LogSes('ModoTallas: sin almacen por defecto; se asume "' +
             FConfig.AlmacenStock + '" (primer almacen activo)');
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TModoEntradaTallas.MigrarCeldasAlmacen;
var
  Qry, QIns: TUniQuery;
  dsM: TDataSet;
  sAlmDef, sSerie, sNumero: string;
  iMigradas: Integer;
begin
  if FCfgTallas.FieldAlmacenCel <> '' then
  begin
    sAlmDef := Trim(FConfig.AlmacenStock);
    if FConfig.Distribuido and (sAlmDef = '') then
      // No deberia ocurrir (AsegurarAlmacenDefecto corre antes); se
      // deja tal cual y el grid seguira mostrando la suma correcta.
      LogSes('ModoTallas.MigrarCeldas: sin almacen por defecto; las ' +
             'celdas sin almacen no se migran')
    else
    begin
      dsM := FCfgTallas.SourceMaster.DataSet;
      sSerie := dsM.FieldByName(FCfgTallas.FieldSerieMaster).AsString;
      sNumero := NumeroDocTallas;
      Qry := TUniQuery.Create(nil);
      QIns := TUniQuery.Create(nil);
      try
        Qry.Connection := FConfig.Conexion;
        QIns.Connection := FConfig.Conexion;
        // Celdas ORIGEN a migrar. Nota: nada de INSERT..SELECT sobre
        // la misma tabla — el ON DUPLICATE sobre la columna cantidad
        // resulta ambiguo en MariaDB (#23000). Se leen las celdas y
        // se upsertea fila a fila con parametros, como el gestor.
        if FConfig.Distribuido then
          // Tecleadas en modo normal: almacen '' -> almacen defecto.
          Qry.SQL.Text :=
            'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN, ' +
            FCfgTallas.FieldFilaCel + ' AS FILA, ' +
            FCfgTallas.FieldAvPivotCel + ' AS IDAV, ' +
            FCfgTallas.FieldCantidadCel + ' AS CANT' +
            ' FROM ' + FCfgTallas.TablaCeldas +
            ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
            WhereNumero('') +
            ' AND ' + FCfgTallas.FieldAlmacenCel + ' = ''''' +
            WhereDocExtra
        else
          // Vuelta a formato normal: colapsar almacenes en ''.
          Qry.SQL.Text :=
            'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN, ' +
            FCfgTallas.FieldFilaCel + ' AS FILA, ' +
            FCfgTallas.FieldAvPivotCel + ' AS IDAV, ' +
            'SUM(' + FCfgTallas.FieldCantidadCel + ') AS CANT' +
            ' FROM ' + FCfgTallas.TablaCeldas +
            ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
            WhereNumero('') +
            ' AND ' + FCfgTallas.FieldAlmacenCel + ' <> ''''' +
            WhereDocExtra +
            ' GROUP BY ' + FCfgTallas.FieldLineaCel + ', ' +
            FCfgTallas.FieldFilaCel + ', ' +
            FCfgTallas.FieldAvPivotCel;
        Qry.ParamByName('s').AsString := sSerie;
        ParamNumero(Qry);
        ParamsDocExtra(Qry);
        Qry.Open;
        // Upsert por parametros: cantidad destino = existente + origen.
        QIns.SQL.Text :=
          'INSERT INTO ' + FCfgTallas.TablaCeldas + ' (' +
          FCfgTallas.FieldSerieCel + ', ' +
          ColsInsertNumero +
          ColsInsertDocExtra +
          FCfgTallas.FieldLineaCel + ', ' +
          FCfgTallas.FieldFilaCel + ', ' +
          FCfgTallas.FieldAlmacenCel + ', ' +
          FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldCantidadCel + ',' +
          ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
          ' USUARIO_MODIF)' +
          ' VALUES (:s, ' + ValsInsertNumero + ValsInsertDocExtra +
          ':l, :f, :a, :p, :c,' +
          ' NOW(), :u, NOW(), :u)' +
          ' ON DUPLICATE KEY UPDATE ' +
          FCfgTallas.FieldCantidadCel + ' = ' +
          FCfgTallas.FieldCantidadCel + ' + :c,' +
          ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
        iMigradas := 0;
        while not Qry.Eof do
        begin
          QIns.ParamByName('s').AsString := sSerie;
          ParamNumero(QIns);
          ParamsDocExtra(QIns);
          QIns.ParamByName('l').AsInteger :=
            Qry.FieldByName('LIN').AsInteger;
          QIns.ParamByName('f').AsInteger :=
            Qry.FieldByName('FILA').AsInteger;
          if FConfig.Distribuido then
            QIns.ParamByName('a').AsString := sAlmDef
          else
            QIns.ParamByName('a').AsString := '';
          QIns.ParamByName('p').AsInteger :=
            Qry.FieldByName('IDAV').AsInteger;
          QIns.ParamByName('c').AsFloat :=
            Qry.FieldByName('CANT').AsFloat;
          QIns.ParamByName('u').AsString := FCfgTallas.Usuario;
          QIns.ExecSQL;
          Inc(iMigradas);
          Qry.Next;
        end;
        Qry.Close;
        if iMigradas > 0 then
        begin
          LogSes(Format('ModoTallas.MigrarCeldas: %d celdas ' +
                        'unificadas (distribuido=%s)',
                        [iMigradas,
                         BoolToStr(FConfig.Distribuido, True)]));
          // Origen migrado: fuera las celdas del formato anterior.
          if FConfig.Distribuido then
            QIns.SQL.Text :=
              'DELETE FROM ' + FCfgTallas.TablaCeldas +
              ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
              WhereNumero('') +
              ' AND ' + FCfgTallas.FieldAlmacenCel + ' = ''''' +
              WhereDocExtra
          else
            QIns.SQL.Text :=
              'DELETE FROM ' + FCfgTallas.TablaCeldas +
              ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
              WhereNumero('') +
              ' AND ' + FCfgTallas.FieldAlmacenCel + ' <> ''''' +
              WhereDocExtra;
          QIns.ParamByName('s').AsString := sSerie;
          ParamNumero(QIns);
          ParamsDocExtra(QIns);
          QIns.ExecSQL;
        end;
      finally
        FreeAndNil(QIns);
        FreeAndNil(Qry);
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.ViewEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  // Celdas de talla en distribuido: sin edicion inline; el reparto por
  // almacen entra por el distribuidor. El grid muestra la SUMA (la
  // carga del gestor agrupa por talla sin filtrar almacen).
  if (AItem <> nil) and (AItem.Tag >= 1) and
     (AItem.Tag <= FCfgTallas.MaxColumnas) then
  begin
    AAllow := False;
    if not FDistribAbierto then
      AbrirDistribuidorLinea;
  end;
end;

procedure TModoEntradaTallas.AbrirDistribuidorLinea;
var
  Parametros: TParametrosDistribuidorTallas;
  dsM: TDataSet;
  iLinea, iAc, idxRec: Integer;
begin
  iLinea :=
    FConfig.Cds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
  iAc :=
    FConfig.Cds.FieldByName(FCfgTallas.FieldConjuntoPivot).AsInteger;
  if (iLinea > 0) and (iAc > 0) and (FGestor <> nil) then
  begin
    if FConfig.Cds.State in [dsEdit, dsInsert] then
      FConfig.Cds.Post;
    dsM := FCfgTallas.SourceMaster.DataSet;
    Parametros := Default(TParametrosDistribuidorTallas);
    Parametros.Conexion := FConfig.Conexion;
    Parametros.Usuario := FCfgTallas.Usuario;
    Parametros.TablaCeldas := FCfgTallas.TablaCeldas;
    Parametros.CampoSerie := FCfgTallas.FieldSerieCel;
    Parametros.CampoNumero := FCfgTallas.FieldNumeroCel;
    Parametros.CampoLinea := FCfgTallas.FieldLineaCel;
    Parametros.CampoFila := FCfgTallas.FieldFilaCel;
    Parametros.CampoAlmacen := FCfgTallas.FieldAlmacenCel;
    Parametros.CampoAtributoValor := FCfgTallas.FieldAvPivotCel;
    Parametros.CampoCantidad := FCfgTallas.FieldCantidadCel;
    Parametros.Serie := dsM.FieldByName(
      FCfgTallas.FieldSerieMaster).AsString;
    Parametros.Numero := dsM.FieldByName(
      FCfgTallas.FieldNumeroMaster).AsString;
    Parametros.Linea := iLinea;
    Parametros.IdConjuntoPivot := iAc;
    FDistribAbierto := True;
    try
      if TDistribuidorTallas.Ejecutar(Parametros) then
      begin
        // Mismo orden que PersistirCeldaActiva: totales de la linea y
        // recarga de sus celdas, con la carga como ultimo toque.
        FGestor.RefrescarTotalesLineaActual;
        idxRec := FCfgTallas.Grid.Controller.FocusedRecordIndex;
        if idxRec >= 0 then
          FGestor.CargarCantidadesUnaLinea(idxRec, iLinea);
        if Assigned(FCfgTallas.Grid.Site) then
          FCfgTallas.Grid.Site.Invalidate;
      end;
    finally
      FDistribAbierto := False;
    end;
  end;
end;

procedure TModoEntradaTallas.CeldaTallaCambiada(Sender: TObject);
begin
  if FGestor <> nil then
    FGestor.PersistirCeldaActiva(Sender);
end;

procedure TModoEntradaTallas.FocoItemCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  // El EnterAsTab solo esta desactivado MIENTRAS la celda del combo
  // (articulo) tiene el foco; al pasar a cualquier otra columna se
  // restaura y el Enter vuelve a cambiar de control.
  if (APrevFocusedItem = FColArticulo) and
     Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaTallas.FocoLineaCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  if FGestor <> nil then
  begin
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
  end;
end;

procedure TModoEntradaTallas.LimpiarCaptionsGenericas;
var
  i: Integer;
begin
  // Solo se pinta la TALLA en el caption: las columnas que exceden el
  // conjunto de la linea activa (el gestor las rotula 'Talla N')
  // quedan con un punto neutro.
  for i := 0 to High(FCfgTallas.ColumnasTallas) do
  begin
    if (FCfgTallas.ColumnasTallas[i] <> nil) and
       StartsText('Talla ', FCfgTallas.ColumnasTallas[i].Caption) then
      FCfgTallas.ColumnasTallas[i].Caption := '·';
  end;
end;

procedure TModoEntradaTallas.CdsAfterPost(DataSet: TDataSet);
begin
  // Conversion interna en curso (rederivar, totales, expansion): los
  // posts son masivos y encadenar el AfterPost del host en cada uno
  // dispara totales/movimientos en cascada; ademas sus repintados
  // borran los Values[] no-bound recien cargados. Se cuenta y se
  // notifica UNA sola vez al cerrar (NotificarPostsSilenciados).
  if FEnProceso then
    Inc(FPostsSilenciados)
  else
  begin
    if Assigned(FAfterPostOrig) then
      FAfterPostOrig(DataSet);
    // Post (implicito al cambiar de fila o del usuario): el re-render
    // posterior limpia los Values[] no-bound. Recarga diferida.
    ArmarRecarga;
  end;
end;

procedure TModoEntradaTallas.CdsAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FAfterScrollOrig) then
    FAfterScrollOrig(DataSet);
  // La navegacion tambien puede repintar y limpiar los Values[].
  ArmarRecarga;
end;

procedure TModoEntradaTallas.ArmarRecarga;
begin
  if (FGestor <> nil) and (not FEnProceso) then
  begin
    FTimerRecarga.Enabled := False;
    FTimerRecarga.Enabled := True;
  end;
end;

procedure TModoEntradaTallas.TimerRecargaTimer(Sender: TObject);
begin
  FTimerRecarga.Enabled := False;
  if (FGestor <> nil) and (not FEnProceso) then
  begin
    FGestor.CargarCantidadesTodasLineas;
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
  end;
end;

// Cierre de una conversion interna: si se silenciaron posts, encadena
// UNA sola vez el AfterPost del host (totales, movimientos, pendientes
// de recibir...) y rearma la recarga de celdas para que lo ultimo que
// toque el grid sea la republicacion de los Values[] no-bound.
procedure TModoEntradaTallas.NotificarPostsSilenciados;
begin
  if (FPostsSilenciados > 0) and (not FEnProceso) then
  begin
    FPostsSilenciados := 0;
    if Assigned(FAfterPostOrig) and (FConfig.Cds <> nil) and
       FConfig.Cds.Active then
      FAfterPostOrig(FConfig.Cds);
    ArmarRecarga;
  end;
end;

function TModoEntradaTallas.LeerCampo(const ANombre: string): string;
var
  Campo: TField;
begin
  Result := '';
  if ANombre <> '' then
  begin
    Campo := FConfig.Cds.FindField(ANombre);
    if Campo <> nil then
      Result := Campo.AsString;
  end;
end;

function TModoEntradaTallas.ComponerSkuLinea(const AArt: string;
  const AVal: TValoresAttrTallas; AOrdTalla: Integer;
  const ATalla: string): string;
var
  i: Integer;
begin
  Result := AArt;
  for i := 1 to 5 do
  begin
    if (i - 1) = AOrdTalla then
      Result := Result + '/' + ATalla
    else if AVal[i] <> '' then
      Result := Result + '/' + AVal[i];
  end;
end;

procedure TModoEntradaTallas.Desmontar;
var
  Desmontaje: TDesmontajeTallas;
begin
  if (FConfig.Cds <> nil) and FConfig.Cds.Active then
  begin
    Desmontaje := TDesmontajeTallas.Create(Self);
    try
      Desmontaje.Ejecutar;
    finally
      FreeAndNil(Desmontaje);
    end;
  end;
end;


procedure TModoEntradaTallas.PonerCampo(const ANombre, AValor: string);
var
  Campo: TField;
begin
  if ANombre <> '' then
  begin
    Campo := FConfig.Cds.FindField(ANombre);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;
end;

function TModoEntradaTallas.EsAtributoTalla(
  const AAtrib: TArticuloAtributo): Boolean;
begin
  // Por nombre (Talla...) o por id (TAL): el nombre puede venir nulo.
  Result := ContainsText(AAtrib.NombreAtributo, 'TALLA') or
            StartsText('TAL', AAtrib.IdAtributo);
end;

procedure TModoEntradaTallas.AtributoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  ColArticulo: TcxGridDBColumn;
  sArticulo, sTexto: string;
begin
  sArticulo := '';
  sTexto := '';
  if (AViewInfo <> nil) and (AViewInfo.GridRecord <> nil) then
  begin
    ColArticulo := FConfig.View.GetColumnByFieldName(
      FConfig.Campos.CodigoArt);
    if ColArticulo <> nil then
      sArticulo := VarToStr(
        AViewInfo.GridRecord.Values[ColArticulo.Index]);
    sTexto := AViewInfo.Text;
  end;
  if PintarCeldaSwatchArticuloSiAplica(
       FConfig.Conexion, ACanvas, AViewInfo, sArticulo, sTexto, nil) then
    ADone := True;
end;

function TModoEntradaTallas.PartesDeSku(const AArt,
                                        ASku: string): TArray<string>;
begin
  Result := nil;
  if (ASku <> '') and StartsText(AArt + '/', ASku) then
    Result := Copy(ASku, Length(AArt) + 2, MaxInt).Split(['/']);
end;

function TModoEntradaTallas.BuscarConjuntoParaAvs(
  const AAvs: TArray<TArticuloAtributoValor>): Integer;
var
  Qry: TUniQuery;
  sIds: string;
  i: Integer;
begin
  Result := 0;
  if Length(AAvs) > 0 then
  begin
    // Lista IN de enteros construida en memoria (IdValor es Integer).
    sIds := '';
    for i := 0 to High(AAvs) do
    begin
      if sIds <> '' then
        sIds := sIds + ',';
      sIds := sIds + IntToStr(AAvs[i].IdValor);
    end;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT d.ID_AC_ACD AS ID_AC' +
        '  FROM fza_atributos_conjuntos_det d' +
        ' WHERE d.ID_AV_ACD IN (' + sIds + ')' +
        ' GROUP BY d.ID_AC_ACD' +
        ' HAVING COUNT(DISTINCT d.ID_AV_ACD) = ' +
                IntToStr(Length(AAvs)) +
        ' ORDER BY (SELECT COUNT(*)' +
        '             FROM fza_atributos_conjuntos_det t' +
        '            WHERE t.ID_AC_ACD = d.ID_AC_ACD)' +
        ' LIMIT 1';
      Qry.Open;
      if not Qry.Eof then
        Result := Qry.Fields[0].AsInteger;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TModoEntradaTallas.ConjuntoCubreAvs(AIdAc: Integer;
  const AAvs: TArray<TArticuloAtributoValor>): Boolean;
var
  Qry: TUniQuery;
  sIds: string;
  i: Integer;
begin
  Result := True;
  if (AIdAc > 0) and (Length(AAvs) > 0) then
  begin
    // Lista IN de enteros construida en memoria (IdValor es Integer).
    sIds := '';
    for i := 0 to High(AAvs) do
    begin
      if sIds <> '' then
        sIds := sIds + ',';
      sIds := sIds + IntToStr(AAvs[i].IdValor);
    end;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT COUNT(DISTINCT d.ID_AV_ACD) AS N' +
        '  FROM fza_atributos_conjuntos_det d' +
        ' WHERE d.ID_AC_ACD = ' + IntToStr(AIdAc) +
        '   AND d.ID_AV_ACD IN (' + sIds + ')';
      Qry.Open;
      Result := Qry.Fields[0].AsInteger = Length(AAvs);
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TModoEntradaTallas.CalcularAtributosLinea(const ACodArt: string;
  const APartes: TArray<string>; ASilencioso: Boolean;
  out AVal, ANom: TValoresAttrTallas; out AAcTalla, AOrdenTalla: Integer);
var
  Atribs: TArray<TArticuloAtributo>;
  Avs: TArray<TArticuloAtributoValor>;
  AvsStr: TArray<string>;
  Mapa: TDictionary<string, string>;
  sIdVa, sAvNuevo: string;
  i, j, iAcAlt: Integer;
begin
  for i := 1 to 5 do
  begin
    AVal[i] := '';
    ANom[i] := '';
  end;
  AAcTalla := 0;
  AOrdenTalla := -1;
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  for i := 0 to High(Atribs) do
  begin
    if EsAtributoTalla(Atribs[i]) then
    begin
      AOrdenTalla := i;
      // Pivote = conjunto asignado al articulo; fallback: el conjunto
      // global mas pequenyo que cubre las tallas de sus SKUs.
      AAcTalla := Atribs[i].IdConjunto;
      Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
      // Asignacion desfasada (p.ej. conjunto de LETRAS asignado y SKUs
      // con tallas NUMERICAS): las celdas no mapearian a ninguna
      // columna del pivote y las cantidades quedarian invisibles. Si
      // el asignado no cubre las tallas reales, se busca el que si;
      // si ninguno las cubre todas, se conserva el asignado (mejor un
      // pivote parcial que perderlo).
      if (AAcTalla > 0) and (Length(Avs) > 0) and
         (not ConjuntoCubreAvs(AAcTalla, Avs)) then
      begin
        iAcAlt := BuscarConjuntoParaAvs(Avs);
        LogSes(Format('ModoTallas.CalcularAtributos: conjunto ' +
               'asignado %d NO cubre las tallas de %s; fallback=%d',
               [AAcTalla, ACodArt, iAcAlt]));
        if iAcAlt > 0 then
          AAcTalla := iAcAlt;
      end;
      if AAcTalla = 0 then
        AAcTalla := BuscarConjuntoParaAvs(Avs);
    end
    else
    begin
      sAvNuevo := '';
      // Prioridad 1: el valor vino en el SKU leido.
      if (i <= High(APartes)) and (Trim(APartes[i]) <> '') then
        sAvNuevo := Trim(APartes[i])
      else
      begin
        // Prioridad 2: unico valor posible se fija solo; si hay
        // varios y no vamos en silencio, paleta de swatches.
        Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
        if Length(Avs) = 1 then
          sAvNuevo := Avs[0].Valor
        else if (Length(Avs) > 1) and (not ASilencioso) then
        begin
          SetLength(AvsStr, Length(Avs));
          for j := 0 to High(Avs) do
            AvsStr[j] := Avs[j].Valor;
          sIdVa := '';
          Mapa := ObtenerMapaAtributosGlobal(FConfig.Conexion);
          if Mapa <> nil then
            Mapa.TryGetValue(UpperCase(Trim(Atribs[i].NombreAtributo)),
                             sIdVa);
          if not SeleccionarAvConPaleta(FConfig.Conexion, sIdVa, AvsStr, '',
                                        sAvNuevo,
                                        -1, -1, 160) then
            sAvNuevo := '';
        end;
      end;
      if i < 5 then
      begin
        AVal[i + 1] := sAvNuevo;
        ANom[i + 1] := Atribs[i].NombreAtributo;
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.EscribirAtributosLinea(const AVal,
  ANom: TValoresAttrTallas; AAcTalla: Integer);
var
  i, iAncho: Integer;
begin
  for i := 1 to 5 do
  begin
    PonerCampo(FConfig.Campos.AttrValor[i], AVal[i]);
    PonerCampo(FConfig.Campos.AttrNombre[i], ANom[i]);
    if (FColAtributo[i] <> nil) and (ANom[i] <> '') then
    begin
      FColAtributo[i].Caption := ANom[i];
      FColAtributo[i].Visible := True;
      // Ancho SOLO creciente para que el valor quepa con su swatch.
      // BestFit no sirve aqui: mide sin el cuadrado del custom draw
      // y con el grid a medio pintar ENCOGE la columna. 44 = swatch
      // (18) + separacion (6) + margenes de celda (10) + aire (10).
      iAncho := cxTextWidth(TcxGrid(FConfig.View.Control).Font,
                            AVal[i]) + 44;
      if FColAtributo[i].Width < iAncho then
        FColAtributo[i].Width := iAncho;
    end;
  end;
  if FConfig.Cds.FindField(FCfgTallas.FieldConjuntoPivot) <> nil then
    FConfig.Cds.FieldByName(FCfgTallas.FieldConjuntoPivot).AsInteger :=
      AAcTalla;
end;

function TModoEntradaTallas.LocalizarLineaExistente(const ACodArt,
  AAlm: string; const AVal: TValoresAttrTallas; APrecio: Double;
  ATienePrecio: Boolean): Boolean;
  // Coincidencia manual de la fila actual con la clave completa,
  // PRECIO incluido (Locate no compara floats con tolerancia y debe
  // encontrarse la linea del MISMO precio aunque exista otra igual
  // con precio distinto).
  function FilaCoincide: Boolean;
  var
    j: Integer;
  begin
    Result := SameText(Trim(FConfig.Cds.FieldByName(
                FConfig.Campos.CodigoArt).AsString), Trim(ACodArt));
    if Result and (FConfig.Campos.Almacen <> '') and
       (not FConfig.Distribuido) then
      Result := SameText(Trim(FConfig.Cds.FieldByName(
                  FConfig.Campos.Almacen).AsString), Trim(AAlm));
    for j := 1 to 5 do
      if Result and (FConfig.Campos.AttrValor[j] <> '') then
        Result := SameText(Trim(FConfig.Cds.FieldByName(
                    FConfig.Campos.AttrValor[j]).AsString),
                    Trim(AVal[j]));
    if Result then
      Result := Abs(FConfig.Cds.FieldByName(
                  FCfgTallas.FieldPrecioBase).AsFloat - APrecio) < 0.005;
  end;
begin
  if ATienePrecio and (FCfgTallas.FieldPrecioBase <> '') and
     (FConfig.Cds.FindField(FCfgTallas.FieldPrecioBase) <> nil) then
  begin
    Result := False;
    FConfig.Cds.First;
    while (not FConfig.Cds.Eof) and (not Result) do
    begin
      if FilaCoincide then
        Result := True
      else
        FConfig.Cds.Next;
    end;
  end
  else
    Result := LocalizarSinPrecio(ACodArt, AAlm, AVal);
end;

function TModoEntradaTallas.LocalizarSinPrecio(const ACodArt,
  AAlm: string; const AVal: TValoresAttrTallas): Boolean;
var
  sCampos: string;
  vVals: Variant;
  i, n: Integer;
begin
  // Clave de consolidacion: articulo + almacen de la linea + valores
  // de atributos no talla. En DISTRIBUIDO el almacen NO forma parte
  // de la clave: la linea es unica por articulo+color y el reparto
  // por almacen vive en las celdas (modelo sesiones).
  sCampos := FConfig.Campos.CodigoArt;
  n := 1;
  if (FConfig.Campos.Almacen <> '') and
     (not FConfig.Distribuido) then
    Inc(n);
  for i := 1 to 5 do
    if FConfig.Campos.AttrValor[i] <> '' then
      Inc(n);
  vVals := VarArrayCreate([0, n - 1], varVariant);
  vVals[0] := ACodArt;
  n := 1;
  if (FConfig.Campos.Almacen <> '') and
     (not FConfig.Distribuido) then
  begin
    sCampos := sCampos + ';' + FConfig.Campos.Almacen;
    vVals[n] := AAlm;
    Inc(n);
  end;
  for i := 1 to 5 do
    if FConfig.Campos.AttrValor[i] <> '' then
    begin
      sCampos := sCampos + ';' + FConfig.Campos.AttrValor[i];
      vVals[n] := AVal[i];
      Inc(n);
    end;
  Result := FConfig.Cds.Locate(sCampos, vVals, []);
end;

function TModoEntradaTallas.IdAvDeTalla(const ACodArt: string;
  AOrdenTalla: Integer; const AValor: string): Integer;
var
  Avs: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  Result := 0;
  if (AOrdenTalla >= 0) and (AValor <> '') then
  begin
    Avs := FLookup.ObtenerAvsEnSkus(ACodArt, AOrdenTalla + 1);
    for i := 0 to High(Avs) do
      if SameText(Avs[i].Valor, AValor) then
        Result := Avs[i].IdValor;
  end;
end;

// True si la linea ya tiene celdas de talla en BBDD: fue convertida en
// una entrada anterior al modo tallas y su cantidad vive en celdas.
function TModoEntradaTallas.LineaTieneCeldas(ALinea: Integer): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  if ALinea > 0 then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT 1 FROM ' + FCfgTallas.TablaCeldas +
        ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
        WhereNumero('') +
        WhereDocExtra +
        ' AND ' + FCfgTallas.FieldLineaCel + ' = :l' +
        ' LIMIT 1';
      Qry.ParamByName('s').AsString :=
        FCfgTallas.SourceMaster.DataSet.FieldByName(
          FCfgTallas.FieldSerieMaster).AsString;
      ParamNumero(Qry);
      ParamsDocExtra(Qry);
      Qry.ParamByName('l').AsInteger := ALinea;
      Qry.Open;
      Result := not Qry.Eof;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

// Fusion de una duplicada que YA tiene celdas: mueve sus celdas a la
// linea maestra (upsert sumando por talla y almacen) y las borra del
// origen. Mover su CANTIDAD en su lugar duplicaria: es el total que
// mantiene RefrescarTotalesTodasLineas, no una cantidad por talla.
procedure TModoEntradaTallas.MoverCeldasALinea(AOrigen,
  ADestino: Integer);
var
  Qry: TUniQuery;
  sSerie: string;
begin
  if (AOrigen > 0) and (ADestino > 0) and (AOrigen <> ADestino) then
  begin
    sSerie := FCfgTallas.SourceMaster.DataSet.FieldByName(
      FCfgTallas.FieldSerieMaster).AsString;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      if FCfgTallas.FieldAlmacenCel <> '' then
        Qry.SQL.Text :=
          'SELECT ' + FCfgTallas.FieldAvPivotCel + ' AS IDAV,' +
          ' ' + FCfgTallas.FieldAlmacenCel + ' AS ALMC,' +
          ' SUM(' + FCfgTallas.FieldCantidadCel + ') AS CANT' +
          ' FROM ' + FCfgTallas.TablaCeldas +
          ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
          WhereNumero('') +
          WhereDocExtra +
          ' AND ' + FCfgTallas.FieldLineaCel + ' = :l' +
          ' GROUP BY ' + FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldAlmacenCel
      else
        Qry.SQL.Text :=
          'SELECT ' + FCfgTallas.FieldAvPivotCel + ' AS IDAV,' +
          ' '''' AS ALMC,' +
          ' SUM(' + FCfgTallas.FieldCantidadCel + ') AS CANT' +
          ' FROM ' + FCfgTallas.TablaCeldas +
          ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
          WhereNumero('') +
          WhereDocExtra +
          ' AND ' + FCfgTallas.FieldLineaCel + ' = :l' +
          ' GROUP BY ' + FCfgTallas.FieldAvPivotCel;
      Qry.ParamByName('s').AsString := sSerie;
      ParamNumero(Qry);
      ParamsDocExtra(Qry);
      Qry.ParamByName('l').AsInteger := AOrigen;
      Qry.Open;
      while not Qry.Eof do
      begin
        SumarEnCelda(ADestino,
                     Qry.FieldByName('IDAV').AsInteger,
                     Qry.FieldByName('CANT').AsFloat,
                     Qry.FieldByName('ALMC').AsString,
                     False);
        Qry.Next;
      end;
      Qry.Close;
      // Origen fusionado: fuera sus celdas.
      Qry.SQL.Text :=
        'DELETE FROM ' + FCfgTallas.TablaCeldas +
        ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
        WhereNumero('') +
        WhereDocExtra +
        ' AND ' + FCfgTallas.FieldLineaCel + ' = :l';
      Qry.ParamByName('s').AsString := sSerie;
      ParamNumero(Qry);
      ParamsDocExtra(Qry);
      Qry.ParamByName('l').AsInteger := AOrigen;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
    LogSes(Format('ModoTallas.MoverCeldas: linea %d -> %d',
                  [AOrigen, ADestino]));
  end;
end;

procedure TModoEntradaTallas.SumarEnCelda(ALinea, AIdAv: Integer;
  ACant: Double; const AAlm: string; ARefrescar: Boolean);
var
  Qry: TUniQuery;
  dsM: TDataSet;
  idxRec: Integer;
begin
  LogSes(Format('ModoTallas.SumarEnCelda: linea=%d idAv=%d alm="%s" +%g',
                [ALinea, AIdAv, AAlm, ACant]));
  if (ALinea > 0) and (AIdAv > 0) and (FGestor <> nil) then
  begin
    // Upsert ATOMICO (cantidad = cantidad + :c), respetando el almacen
    // de la celda cuando el documento lo usa (formato distribuido).
    dsM := FCfgTallas.SourceMaster.DataSet;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      if FCfgTallas.FieldAlmacenCel <> '' then
      begin
        Qry.SQL.Text :=
          'INSERT INTO ' + FCfgTallas.TablaCeldas + ' (' +
          FCfgTallas.FieldSerieCel + ', ' +
          ColsInsertNumero +
          ColsInsertDocExtra +
          FCfgTallas.FieldLineaCel + ', ' +
          FCfgTallas.FieldFilaCel + ', ' +
          FCfgTallas.FieldAlmacenCel + ', ' +
          FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldCantidadCel + ',' +
          ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
          ' USUARIO_MODIF)' +
          ' VALUES (:s, ' + ValsInsertNumero + ValsInsertDocExtra +
          ':l, :f, :a, :p, :c,' +
          ' NOW(), :u, NOW(), :u)' +
          ' ON DUPLICATE KEY UPDATE ' +
          FCfgTallas.FieldCantidadCel + ' = ' +
          FCfgTallas.FieldCantidadCel + ' + :c,' +
          ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
        Qry.ParamByName('a').AsString := AAlm;
      end
      else
        Qry.SQL.Text :=
          'INSERT INTO ' + FCfgTallas.TablaCeldas + ' (' +
          FCfgTallas.FieldSerieCel + ', ' +
          ColsInsertNumero +
          ColsInsertDocExtra +
          FCfgTallas.FieldLineaCel + ', ' +
          FCfgTallas.FieldFilaCel + ', ' +
          FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldCantidadCel + ',' +
          ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
          ' USUARIO_MODIF)' +
          ' VALUES (:s, ' + ValsInsertNumero + ValsInsertDocExtra +
          ':l, :f, :p, :c,' +
          ' NOW(), :u, NOW(), :u)' +
          ' ON DUPLICATE KEY UPDATE ' +
          FCfgTallas.FieldCantidadCel + ' = ' +
          FCfgTallas.FieldCantidadCel + ' + :c,' +
          ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
      Qry.ParamByName('s').AsString :=
        dsM.FieldByName(FCfgTallas.FieldSerieMaster).AsString;
      ParamNumero(Qry);
      Qry.ParamByName('l').AsInteger := ALinea;
      Qry.ParamByName('f').AsInteger := FCfgTallas.IdFilaFijo;
      Qry.ParamByName('p').AsInteger := AIdAv;
      Qry.ParamByName('c').AsFloat := ACant;
      Qry.ParamByName('u').AsString := FCfgTallas.Usuario;
      ParamsDocExtra(Qry);
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
    if ARefrescar then
    begin
      idxRec := FCfgTallas.Grid.Controller.FocusedRecordIndex;
      if idxRec >= 0 then
        FGestor.CargarCantidadesUnaLinea(idxRec, ALinea);
      FGestor.RefrescarTotalesLineaActual;
    end;
  end;
end;

procedure TModoEntradaTallas.RederivarLineasExistentes;
var
  ds: TDataSet;
  Dict: TDictionary<string, Integer>;
  Val, Nom: TValoresAttrTallas;
  Partes: TArray<string>;
  sArt, sSku, sTallaVal, sClave, sAlmLin, sAlmCel: string;
  iAc, iOrdT, idAv, iLinea, iLineaMaster, i, iPos: Integer;
  rCant: Double;
  CampoCant: TField;
  EvBorrado: TDataSetNotifyEvent;
  bBorrada: Boolean;
  bYaConvertida: Boolean;
begin
  ds := FConfig.Cds;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
  begin
    Dict := TDictionary<string, Integer>.Create;
    ds.DisableControls;
    try
      // Recorrido por RecNo, NO con while-not-Eof: al borrar el ULTIMO
      // registro el cursor cae en el anterior (no en Eof) y el bucle
      // reprocesaria lineas ya vistas, que estarian en el diccionario
      // como maestras de si mismas y se borrarian como "duplicadas"
      // (borrado total del documento).
      iPos := 1;
      while iPos <= ds.RecordCount do
      begin
        ds.RecNo := iPos;
        bBorrada := False;
        sArt := Trim(ds.FieldByName(FConfig.Campos.CodigoArt).AsString);
        if sArt <> '' then
        begin
          // Valores heredados: SKU con talla + CANTIDAD del otro modo.
          sSku :=
            Trim(ds.FieldByName(FConfig.Campos.CodigoUnidad).AsString);
          Partes := PartesDeSku(sArt, sSku);
          // Silencioso: sin paleta durante la conversion masiva.
          CalcularAtributosLinea(sArt, Partes, True, Val, Nom,
                                 iAc, iOrdT);
          sTallaVal := '';
          if (iOrdT >= 0) and (iOrdT <= High(Partes)) then
            sTallaVal := Trim(Partes[iOrdT]);
          idAv := IdAvDeTalla(sArt, iOrdT, sTallaVal);
          rCant := 0;
          CampoCant := ds.FindField(FConfig.Campos.Cantidad);
          if CampoCant <> nil then
            rCant := CampoCant.AsFloat;
          // Almacen EFECTIVO de la linea (fallback de cabecera, como
          // albaranes): las lineas sin almacen asumen el del documento
          // y asi fusionan con las que ya lo llevan puesto.
          sAlmLin := '';
          if (FConfig.Campos.Almacen <> '') and
             (ds.FindField(FConfig.Campos.Almacen) <> nil) then
          begin
            sAlmLin := Trim(
              ds.FieldByName(FConfig.Campos.Almacen).AsString);
            if sAlmLin = '' then
              sAlmLin := Trim(FConfig.AlmacenStock);
          end;
          // En DISTRIBUIDO el almacen vive en las CELDAS (modelo
          // sesiones): la linea es unica por articulo+color y las
          // lineas por almacen FUSIONAN, yendo cada cantidad a la
          // celda de su almacen. Sin distribuido, una linea por
          // almacen (modelo albaranes).
          if FConfig.Distribuido then
            sClave := sArt + '|'
          else
            sClave := sArt + '|' + UpperCase(sAlmLin);
          for i := 1 to 5 do
            sClave := sClave + '|' + UpperCase(Val[i]);
          // El PRECIO forma parte de la clave: dos lineas del mismo
          // articulo+color con precio distinto NO fusionan (queda una
          // fila pivotada por precio y el des-pivote conserva el
          // precio de cada una). Sin esto un precio machacaba al otro.
          if (FCfgTallas.FieldPrecioBase <> '') and
             (ds.FindField(FCfgTallas.FieldPrecioBase) <> nil) then
            sClave := sClave + '|' + FloatToStrF(
              ds.FieldByName(FCfgTallas.FieldPrecioBase).AsFloat,
              ffGeneral, 15, 4);
          // Destino de las cantidades heredadas: en distribuido, el
          // almacen efectivo de la linea; si no, celda sin almacen.
          if FConfig.Distribuido then
            sAlmCel := sAlmLin
          else
            sAlmCel := '';
          if Dict.TryGetValue(sClave, iLineaMaster) then
          begin
            // Duplicada (mismo articulo+color): su cantidad se vuelca
            // a la celda de talla de la linea maestra y se elimina.
            // Si la duplicada YA tiene celdas (era otro master), se
            // mueven SUS celdas: su CANTIDAD es el total mantenido
            // por RefrescarTotalesTodasLineas y sumarla duplicaria.
            if LineaTieneCeldas(
                 ds.FieldByName(FCfgTallas.FieldLinea).AsInteger) then
              MoverCeldasALinea(
                ds.FieldByName(FCfgTallas.FieldLinea).AsInteger,
                iLineaMaster)
            else if (idAv > 0) and (rCant > 0) then
              SumarEnCelda(iLineaMaster, idAv, rCant, sAlmCel,
                           False);
            LogSes(Format('ModoTallas.Rederivar: BORRA linea=%d ' +
                   '(dup de %d) art=%s clave=%s',
                   [ds.FieldByName(FCfgTallas.FieldLinea).AsInteger,
                    iLineaMaster, sArt, sClave]));
            // Borrado PROGRAMATICO de la fusion: sin el guardian de
            // confirmacion que TfrmMtoGen engancha en BeforeDelete del
            // dataset principal (preguntaria al usuario por cada
            // duplicada durante Construir).
            EvBorrado := ds.BeforeDelete;
            ds.BeforeDelete := nil;
            try
              ds.Delete;
            finally
              ds.BeforeDelete := EvBorrado;
            end;
            bBorrada := True;
          end
          else
          begin
            iLinea :=
              ds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
            Dict.Add(sClave, iLinea);
            LogSes(Format('ModoTallas.Rederivar: MASTER linea=%d ' +
                   'art=%s clave=%s', [iLinea, sArt, sClave]));
            if not (ds.State in [dsEdit, dsInsert]) then
              ds.Edit;
            // Persistir el almacen efectivo en la linea (el fallback
            // de cabecera deja de ser implicito). En distribuido la
            // linea es multi-almacen: queda el del documento.
            if FConfig.Distribuido then
              PonerCampo(FConfig.Campos.Almacen,
                         Trim(FConfig.AlmacenStock))
            else
              PonerCampo(FConfig.Campos.Almacen, sAlmLin);
            EscribirAtributosLinea(Val, Nom, iAc);
            // Master YA convertido (tiene celdas): su CANTIDAD es el
            // total que mantiene RefrescarTotalesTodasLineas; volver
            // a volcarla DUPLICABA las celdas en cada reentrada al
            // modo (cantidades dobladas sin tocar nada).
            bYaConvertida := LineaTieneCeldas(iLinea);
            // La cantidad del SKU con talla pasa a su celda; la
            // columna Cantidad queda para lineas sin tallas.
            if (not bYaConvertida) and (idAv > 0) and (rCant > 0) and
               (CampoCant <> nil) then
              CampoCant.AsFloat := 0;
            ds.Post;
            if (not bYaConvertida) and (idAv > 0) and (rCant > 0) then
              SumarEnCelda(iLinea, idAv, rCant, sAlmCel, False);
          end;
        end;
        // Tras un Delete NO se avanza: el registro iPos ya es otro.
        if not bBorrada then
          Inc(iPos);
      end;
      ds.First;
    finally
      FreeAndNil(Dict);
      ds.EnableControls;
    end;
  end;
end;

procedure TModoEntradaTallas.MostrarEditor;
begin
  if (FConfig.View <> nil) and (FColArticulo <> nil) then
  begin
    FColArticulo.Focused := True;
    try
      FConfig.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        ;
    end;
  end;
end;

function TModoEntradaTallas.ResolverEntrada(
  const AEntrada: string): Boolean;
var
  Val: TArticulosValidador;
  R: TArtResolucionEntrada;
  Vals, Noms: TValoresAttrTallas;
  Partes: TArray<string>;
  sTallaVal, sAlm: string;
  iAcTalla, iOrdT, idAv, iLinea: Integer;
  rPrecioSku: Double;
  bConPrecio: Boolean;
begin
  Result := False;
  FUltimaConTalla := False;
  if Trim(AEntrada) <> '' then
  begin
    Val := TArticulosValidador.Create(FConfig.Conexion);
    try
      R := Val.Resolver(Trim(AEntrada));
    finally
      FreeAndNil(Val);
    end;
    LogSes(Format('ModoTallas.Resolver: "%s" encontrado=%s sku="%s"',
                  [Trim(AEntrada), BoolToStr(R.Encontrado, True),
                   R.CodigoSku]));
    if R.Encontrado then
    begin
      // Si la entrada trajo un SKU cerrado (barras / SKU completo),
      // sus valores mandan: color de la linea y talla de la celda.
      Partes := PartesDeSku(R.CodigoArticulo, R.CodigoSku);
      CalcularAtributosLinea(R.CodigoArticulo, Partes, False,
                             Vals, Noms, iAcTalla, iOrdT);
      sTallaVal := '';
      if (iOrdT >= 0) and (iOrdT <= High(Partes)) then
        sTallaVal := Trim(Partes[iOrdT]);
      LogSes(Format(
        'ModoTallas.Resolver: pivote=%d ordTalla=%d talla="%s"',
        [iAcTalla, iOrdT, sTallaVal]));
      // Almacen destino = el de la linea donde se tecleo (default: el
      // del documento, puesto al crear la linea en blanco). Se captura
      // ANTES del Cancel, que descartaria un cambio a medio editar.
      sAlm := '';
      if (FConfig.Campos.Almacen <> '') and
         (FConfig.Cds.FindField(FConfig.Campos.Almacen) <> nil) then
      begin
        sAlm := Trim(FConfig.Cds.FieldByName(
                  FConfig.Campos.Almacen).AsString);
        // Fallback de cabecera (como albaranes de compra): la linea
        // sin almacen asume el almacen por defecto del documento.
        if sAlm = '' then
          sAlm := Trim(FConfig.AlmacenStock);
      end;
      // CONSOLIDACION: una linea por articulo+almacen+atributos no
      // talla Y PRECIO (si el documento expone ObtenerPrecioSku). La
      // fila donde se tecleo (normalmente la vacia) se descarta si ya
      // existe linea para esa combinacion.
      rPrecioSku := 0;
      bConPrecio := False;
      if Assigned(FConfig.ObtenerPrecioSku) then
      begin
        rPrecioSku := FConfig.ObtenerPrecioSku(R.CodigoArticulo,
                                               R.CodigoSku);
        bConPrecio := True;
      end;
      if FConfig.Cds.State in [dsEdit, dsInsert] then
        FConfig.Cds.Cancel;
      if LocalizarLineaExistente(R.CodigoArticulo, sAlm, Vals,
                                 rPrecioSku, bConPrecio) then
        LogSes(Format('ModoTallas.Resolver: consolidada en linea %d ' +
               'alm="%s" precio=%g',
               [FConfig.Cds.FieldByName(
                  FCfgTallas.FieldLinea).AsInteger, sAlm, rPrecioSku]))
      else
      begin
        LogSes(Format('ModoTallas.Resolver: linea nueva alm="%s" ' +
               'precio=%g', [sAlm, rPrecioSku]));
        FConfig.Cds.Edit;
        PonerCampo(FConfig.Campos.CodigoArt, R.CodigoArticulo);
        PonerCampo(FConfig.Campos.Descripcion, R.DescripcionArticulo);
        PonerCampo(FConfig.Campos.Almacen, sAlm);
        EscribirAtributosLinea(Vals, Noms, iAcTalla);
        // El precio se fija YA en la linea nueva: su clave de
        // consolidacion vale desde el primer momento (el host lo
        // re-aplicara igual via OnResuelto).
        if bConPrecio and (FCfgTallas.FieldPrecioBase <> '') and
           (FConfig.Cds.FindField(FCfgTallas.FieldPrecioBase) <> nil)
        then
          FConfig.Cds.FieldByName(FCfgTallas.FieldPrecioBase).AsFloat :=
            rPrecioSku;
      end;
      if FConfig.Cds.State in [dsEdit, dsInsert] then
        FConfig.Cds.Post;
      // Lectura con talla: +1 en la celda de esa talla (como caja).
      // En formato distribuido NO se suma en linea: el reparto por
      // almacen entra por el distribuidor (como sesiones).
      if sTallaVal <> '' then
      begin
        if FConfig.Distribuido then
          LogSes('ModoTallas.Resolver: distribuido, cantidades via ' +
                 'distribuidor')
        else
        begin
          idAv := IdAvDeTalla(R.CodigoArticulo, iOrdT, sTallaVal);
          iLinea :=
            FConfig.Cds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
          if idAv > 0 then
          begin
            SumarEnCelda(iLinea, idAv, 1, '', True);
            FUltimaConTalla := True;
          end;
        end;
      end;
      // Tope de tallas (20): si el sistema excede MaxColumnas el
      // gestor avisa y limpia el pivot (no pasa a horizontal).
      if FGestor <> nil then
      begin
        if FGestor.ValidarSistemaSeleccionado then
        begin
          FGestor.RecalcularMaxColumnas;
          FGestor.ActualizarCaptionsLineaActiva;
        end;
      end;
      if Assigned(FOnResuelto) then
      begin
        if R.CodigoSku <> '' then
          FOnResuelto(R.CodigoArticulo, R.CodigoSku,
                      R.DescripcionArticulo, True)
        else
          FOnResuelto(R.CodigoArticulo, R.CodigoArticulo,
                      R.DescripcionArticulo, True);
      end;
      Result := True;
    end
    else
      // Feedback como el desglose: sin aviso parecia que el Enter no
      // hacia nada cuando la entrada no existe (SKU no dado de alta).
      ShowMessage(Format(SErrorArticuloSkuNoEncontrado, [Trim(AEntrada)]));
  end;
end;

end.
