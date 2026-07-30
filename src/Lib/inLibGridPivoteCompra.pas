{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridPivoteCompra                                         }
{    Tipo:       Libreria (sin formulario)                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Orquestador del modo "Tallas en horizontal" para los Mto de               }
{    documentos de compra (albaranes y pedidos). Encapsula la logica que       }
{    antes vivia duplicada en inMtoAlbaranesCompra: cache de lineas            }
{    representantes por (articulo+color), filtrado en cliente, publicacion     }
{    de cantidades en columnas no-bound, sombreado de celdas fuera de          }
{    conjunto, intercambio Color<->Almacen, validacion previa.                 }
{                                                                              }
{    Se complementa con TGestorGridTallas (inLibGridTallasInline), que sigue   }
{    encargandose de calcular las posiciones del conjunto pivot, persistir     }
{    celdas y refrescar captions. Esta libreria opera SOBRE el gestor (le      }
{    consulta posiciones) pero NO duplica su rol.                              }
{                                                                              }
{    Uso desde el form:                                                        }
{      1. Crear TGestorGridTallas (igual que hoy).                             }
{      2. Construir un TGridPivoteCompraConfig con los nombres de campos y    }
{         tablas concretos del documento (ALBC vs PEDC).                       }
{      3. Crear TGridPivoteCompra(cfg). El form lo guarda y llama a sus       }
{         metodos desde sus handlers (Activar, Desactivar, RecargarPivote,    }
{         CustomDrawCellTalla, ColorCell, etc.).                               }
{                                                                              }
{    Limitacion: el cache se carga del propio documento (suma cantidades por  }
{    SKU). Si en el futuro el pedido necesita pintar cantidades distintas     }
{    (p.ej. recibidas vs pedidas), habra que ampliar la config para indicar   }
{    el campo cantidad a mostrar.                                             }
{******************************************************************************}
unit inLibGridPivoteCompra;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.StrUtils, System.Classes, System.Variants,
  System.UITypes, System.Generics.Collections, System.Types,
  Data.DB, DBAccess, Uni,
  Vcl.Controls, Vcl.Graphics,
  cxClasses, cxGraphics, cxControls, cxCustomData,
  cxEdit, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inLibGridTallasInline,
  inLibAtributosPaleta,
  inLibContextoSesionIntf;

type
  // Config inmutable que el form construye una vez y pasa al constructor.
  // Todos los nombres de campo y tabla son strings para no acoplar la lib
  // a un esquema concreto: vale para ALBC y para PEDC con los mismos
  // metodos cambiando solo la config.
  TGridPivoteCompraConfig = record
    Conexion             : TUniConnection;
    ContextoSesion       : IContextoSesionAplicacion;
    Grid                 : TcxGridDBTableView;
    SourceMaster         : TDataSource;
    SourceLineas         : TUniQuery;
    Gestor               : TGestorGridTallas;
    // Columna no-bound del grid que mostrara el color BASICO con
    // cuadradito (p.ej. "VERDE" con swatch). El lib le publica el
    // valor leido de ATBC.NOMBRE_ATB.
    ColColorPivot        : TcxGridDBColumn;
    // Columna no-bound del grid para el COLOR DEL PROVEEDOR (texto
    // libre del proveedor, p.ej. "011" o "AZUL TURQUESA PROV-XYZ").
    // Si esta seteada, el lib le publica COLOR_TEXTO_PEDCLIN (o el
    // campo que indique FieldColorTexto). Sin cuadradito — es texto.
    ColColorProveedorPivot: TcxGridDBColumn;
    ColumnasTallas       : TArray<TcxGridDBColumn>;
    MaxColumnasTallas    : Integer;
    TablaLineas          : string;   // fza_albaranes_compra_lineas / pedidos
    FieldSerieMaster     : string;   // SERIE_ALBC / SERIE_PEDC
    FieldNumeroMaster    : string;   // NUMERO_ALBC / NUMERO_PEDC
    FieldSerieLin        : string;   // SERIE_ALBC_ALBCLIN / SERIE_PEDC_PEDCLIN
    FieldNumeroLin       : string;
    FieldLinea           : string;   // LINEA_ALBCLIN / LINEA_PEDCLIN
    FieldArt             : string;   // CODIGO_ART_ALBCLIN / _PEDCLIN
    FieldSku             : string;   // CODIGO_UNIDAD_ALBCLIN / _PEDCLIN
    FieldCantidad        : string;   // CANTIDAD_ALBCLIN / _PEDCLIN
    FieldPrecioBase      : string;   // PRECIO_COMPRA_SIVA_ARTICULO_*
    FieldTotalUds        : string;   // TOTAL_UNIDADES_*LIN
    FieldTotalLinea      : string;   // TOTAL_*LIN
    // Campo CANTIDAD_RECIBIDA por linea. Solo en pedidos; vacio para
    // albaranes (no tienen este concepto). Si esta vacio, el modo
    // "Expandir / recibidos" no aplica.
    FieldCantidadRecibida: string;
    FieldIdAcPivot       : string;   // ID_AC_PIVOT_ALBCLIN / _PEDCLIN
    FieldAlmacen         : string;   // CODIGO_ALMACEN_ALBCLIN / _PEDCLIN
    // Almacen por defecto del documento (en cabecera). Usado como
    // fallback cuando una linea no lleva almacen propio. Vacio si la
    // cabecera no expone almacen (no aplica fallback).
    FieldAlmacenMaster   : string;   // CODIGO_ALM_PEDC / CODIGO_ALM_ALBC
    // Campo de texto libre con el color del articulo del proveedor
    // (espejo de COLOR_TEXTO_SESLIN en sesiones). Si esta seteado, su
    // valor tiene PRIORIDAD sobre el nombre del atributo basico para la
    // columna Color del grid (el usuario quiere ver "AZUL TURQUESA
    // PROV-XYZ", no solo "Azul"). Vacio para albaranes (no tienen).
    FieldColorTexto      : string;   // COLOR_TEXTO_PEDCLIN
    CamposOcultosEnPivote: TArray<string>;
  end;

  // Resultado de IterarARecibirPorAlmacen. Cada record corresponde a una
  // celda de la matriz pivote (linea-representante x talla) con cantidad
  // "A recibir" > 0 cuyo almacen efectivo coincide con el elegido.
  TCeldaARecibir = record
    LineaPedido  : string;    // LINEA_PEDCLIN real de la fila origen
    CodigoSku    : string;
    CodigoAlmacen: string;
    Cantidad     : Double;
  end;

  TEstadoFilaRecibida = (efrIndefinido, efrNada, efrParcial, efrTotal);

  TGridPivoteCompra = class
  private
    FCfg              : TGridPivoteCompraConfig;
    FActivo           : Boolean;
    FExpandido        : Boolean;
    FActualizandoGrid : Boolean;
    FGuardandoCantidad: Boolean;
    FPivotLineasRepr  : TList<Integer>;
    FPivotCantidades  : TDictionary<Int64,Double>;
    FPivotCantidadesRecibidas: TDictionary<Int64,Double>;
    FPivotTotalPedido        : TDictionary<Integer,Double>;
    FPivotTotalRecibido      : TDictionary<Integer,Double>;
    // Mapeo celda -> SKU / almacen / linea_pedido para iterar la matriz
    // y mapear "A recibir" de vuelta a la linea concreta del pedido al
    // crear el albaran.
    FCeldaSku                : TDictionary<Int64,string>;
    FCeldaAlmacen            : TDictionary<Int64,string>;
    FCeldaLineaPedido        : TDictionary<Int64,string>;
    FCantidadesPendientes    : TDictionary<Int64,Double>;
    // Cantidades 'A recibir' tecleadas manualmente por el usuario en
    // la matriz pivote expandida. Persistencia en memoria porque
    // cxGrid borra DataController.Values[] de columnas no-bound al
    // navegar entre records. La key es linea*100000 + tallaAv.
    FARecibirManual          : TDictionary<Int64,Double>;
    FPivotColorTexto  : TDictionary<Integer,string>;
    // Texto libre del color del proveedor por linea representante
    // (poblado solo si la config trae FieldColorTexto, p. ej.
    // pedidos con COLOR_TEXTO_PEDCLIN). Vacio para albaranes.
    FPivotColorProveedor: TDictionary<Integer,string>;
    FPivotColorCodigo : TDictionary<Integer,string>;
    FPivotIdAc        : TDictionary<Integer,Integer>;
    FPivotArticulo    : TDictionary<Integer,string>;
    FPivotColorAv     : TDictionary<Integer,Integer>;
    FPivotAlmacen     : TDictionary<Integer,string>;
    FPivotSkuBase     : TDictionary<Integer,string>;
    FPivotSkuPrefijo  : TDictionary<Integer,string>;
    FPivotVarSku      : TDictionary<Integer,string>;
    FPivotSinTalla    : TDictionary<Integer,Boolean>;
    FPivotMaxAvTalla  : Integer;
    FOrigColIndexAlm     : Integer;
    FOrigColIndexCol     : Integer;
    FOrigColIndexColProv : Integer;
    FAlturaFilaOriginal  : Integer;
    procedure FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    function  GetSerieNumeroActivos(out ASerie, ANumero: string): Boolean;
    function  GetLineaActiva(out ALinea: Integer;
                             out ALineaTexto: string): Boolean;
    function  GetEstadoFila(iLinea: Integer): TEstadoFilaRecibida;
    function  GetColorEstadoFila(AEstado: TEstadoFilaRecibida): TColor;
    function  EsLineaSinTalla(iLinea: Integer): Boolean;
    function  ResolverAvColorBasico(const ACodigoAtbColor: string;
                out AIdAv: Integer; out AValorAv, ANombreColor,
                AMensaje: string): Boolean;
    procedure CapturarEditorActivo;
    procedure CapturarValoresVisibles;
    function  CampoLineaCopiable(const ANombre: string): Boolean;
    function  PrefijoSkuTalla(const ASku: string): string;
    function  ResolverSkuCelda(AKey: Int64; out ASku: string): Boolean;
    function  CrearLineaRealDesdeCelda(AKey: Int64;
                ACantidad: Double; out ALineaReal: string): Boolean;
    procedure LogSes(const ATexto: string);
  public
    constructor Create(const ACfg: TGridPivoteCompraConfig);
    destructor Destroy; override;
    function ValidarPivotePosible(var AMensaje: string): Boolean;
    procedure Activar;
    procedure Desactivar;
    procedure RecargarYRepublicar;
    property Activo: Boolean read FActivo;
    // True si la config trae campo de cantidad recibida (solo pedidos).
    function PuedeExpandir: Boolean;
    // Triple/cuadruple alto + pinta Pedida / Pte de recibir / Recibida /
    // A recibir (editable) en sub-segmentos verticales.
    procedure Expandir;
    procedure Contraer;
    property Expandido: Boolean read FExpandido;
    // Itera la matriz buscando celdas con cantidad "A recibir" > 0 cuyo
    // almacen efectivo coincida con ACodigoAlm. Lo usa el flujo "Crear
    // albaran" para saber que cantidades aplicar.
    function IterarARecibirPorAlmacen(
                                  const ACodigoAlm: string): TArray<TCeldaARecibir>;
    // Limpia las cantidades "A recibir" tecleadas en el grid para el
    // almacen indicado (las del resto se conservan). Se llama tras
    // crear el albaran para evitar que el usuario tenga que borrarlas
    // a mano antes de procesar otro almacen.
    procedure LimpiarARecibirParaAlmacen(const ACodigoAlm: string);
    procedure CustomDrawCellTalla(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure EditingCeldaTalla(Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure CustomDrawColorCell(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    // En modo pivote expandido, el editor inplace de las celdas talla
    // esta bloqueado para que no tape los sub-segmentos pintados
    // (Pedido / Recibida). La entrada de cantidades 'A recibir' se
    // captura desde OnKeyDown del grid via este metodo, que actualiza
    // Values[] y dispara repintado. Devuelve True si consumio la
    // tecla (digito, backspace, delete, esc).
    function ProcesarTeclaCeldaTalla(AKey: Word): Boolean;
    // Devuelve los valores Pedido / Recibida de la celda talla
    // focused actual (la que el usuario esta editando). Usado por el
    // form para alimentar el panel de contexto que muestra estas
    // cantidades fuera de la celda. Devuelve False si no hay celda
    // talla focused valida (no pivote, no expandido, no talla, fuera
    // de conjunto, etc).
    function GetInfoCeldaTallaActiva(out ATallaCaption: string;
                                      out APedido, ARecibida: Double): Boolean;
    // Rellena 'A recibir' con el pendiente (Pedido - Recibida) en
    // TODAS las celdas talla del conjunto de la fila focused. Para
    // tallas ya totalmente recibidas o sin Pedido no escribe nada.
    // Devuelve numero de celdas modificadas (0 si no aplica).
    function RecibirFilaEntera: Integer;
    // Como RecibirFilaEntera pero sobre TODAS las filas representantes
    // del grid (todo el pedido). Vuelca en 'A recibir' el pendiente
    // (Pedido - Recibida) de cada celda talla del conjunto. Lo usa el
    // boton "Recibir Todo". Devuelve el numero de celdas modificadas
    // (0 si no aplica o no queda nada pendiente).
    function RecibirTodo: Integer;
    // Captura el valor del editor inplace de una celda talla y lo
    // guarda en FARecibirManual. Se llama desde OnEditValueChanged
    // de las columnas talla. cxGrid borra DataController.Values[]
    // de columnas no-bound al hacer Post (que ocurre al navegar entre
    // records), por eso necesitamos un almacenamiento propio.
    procedure CapturarARecibirEditValueChanged(ASender: TObject);
    // En pivote horizontal normal, una celda talla apunta a una linea SKU
    // real que puede estar filtrada. Actualiza esa linea y deja que su
    // AfterPost recalcule la cabecera.
    procedure CapturarCantidadEditValueChanged(ASender: TObject);
    procedure PersistirCantidadEditValueChanged(ASender: TObject;
                                                AValorEditado: Variant);
    function PersistirCantidadesPendientes: Integer;
    function ColorCodigoLineaActiva: string;
    function CambiarColorLineaActiva(const ACodigoAtbColor: string;
                                      out AMensaje: string): Boolean;
    // Devuelve el almacen de la primera celda con cantidad 'A recibir'
    // > 0 (cualquiera vale; itera el dict en orden de insercion). Sin
    // entradas validas devuelve ''. Lo usa el form para precargar el
    // combo del modal Crear Albaran con el almacen mas probable.
    function PrimerAlmacenARecibir: string;
    // Suma las cantidades "A recibir" tecleadas en el pivote expandido.
    function TotalARecibir: Double;
    // Engancha al OnInitEdit del grid. Mantenido por compatibilidad,
    // ahora solo hace SelectAll estilo Excel — el ajuste de tamanyo
    // del editor en talla expandida ya no aplica porque el editor
    // queda bloqueado en EditingCeldaTalla.
    procedure InitEditCeldaTalla(Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
  private
    procedure CargarCachePivot;
    procedure PublicarCantidadesPivot;
    procedure AplicarVisibilidadColumnasPivot(AModoPivot: Boolean);
    procedure AplicarColumnaCantidadSinTalla;
    procedure IntercambiarPosicionColorAlmacen(AModoPivot: Boolean);
    procedure PintarCeldaTalla3Segmentos(
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                AColorFondo: TColor;
                APedida, ARecibida, ARecibir: Double);
    procedure DibujarBordeFocused(ACanvas: TcxCanvas; const ARect: TRect);
  end;

const
  ID_AV_SIN_TALLA : Integer = 0;
  // Colores pastel para estados de recepcion (BGR).
  COL_REC_NADA    : TColor = $0099FFFF;  // amarillo
  COL_REC_PARCIAL : TColor = $0099FF99;  // verde
  COL_REC_TOTAL   : TColor = $00FFCC99;  // azul claro
  // Altura por defecto de fila expandida (px). 3 sub-filas visibles:
  // Pedido / Recibido / A recibir. Cada una ~25 px para que se lean
  // bien las cantidades y haya hueco entre las lineas separadoras.
  ALTURA_FILA_EXPANDIDA = 75;

implementation

uses
  inLibLog, inLibMsgArticulos, inLibMsgCompras;

constructor TGridPivoteCompra.Create(const ACfg: TGridPivoteCompraConfig);
begin
  inherited Create;
  FCfg := ACfg;
  FActivo                  := False;
  FExpandido               := False;
  FPivotLineasRepr         := TList<Integer>.Create;
  FPivotCantidades         := TDictionary<Int64,Double>.Create;
  FPivotCantidadesRecibidas:= TDictionary<Int64,Double>.Create;
  FPivotTotalPedido        := TDictionary<Integer,Double>.Create;
  FPivotTotalRecibido      := TDictionary<Integer,Double>.Create;
  FCeldaSku                := TDictionary<Int64,string>.Create;
  FCeldaAlmacen            := TDictionary<Int64,string>.Create;
  FCeldaLineaPedido        := TDictionary<Int64,string>.Create;
  FCantidadesPendientes    := TDictionary<Int64,Double>.Create;
  FARecibirManual          := TDictionary<Int64,Double>.Create;
  FPivotColorTexto         := TDictionary<Integer,string>.Create;
  FPivotColorProveedor     := TDictionary<Integer,string>.Create;
  FPivotColorCodigo        := TDictionary<Integer,string>.Create;
  FPivotIdAc               := TDictionary<Integer,Integer>.Create;
  FPivotArticulo           := TDictionary<Integer,string>.Create;
  FPivotColorAv            := TDictionary<Integer,Integer>.Create;
  FPivotAlmacen            := TDictionary<Integer,string>.Create;
  FPivotSkuBase            := TDictionary<Integer,string>.Create;
  FPivotSkuPrefijo         := TDictionary<Integer,string>.Create;
  FPivotVarSku             := TDictionary<Integer,string>.Create;
  FPivotSinTalla           := TDictionary<Integer,Boolean>.Create;
  FPivotMaxAvTalla         := 0;
  FOrigColIndexAlm         := -1;
  FOrigColIndexCol         := -1;
  FOrigColIndexColProv     := -1;
  FAlturaFilaOriginal      := 0;
end;

procedure TGridPivoteCompra.LogSes(const ATexto: string);
begin
  if Assigned(FCfg.ContextoSesion) then
    FCfg.ContextoSesion.LogSesion(ATexto);
end;

destructor TGridPivoteCompra.Destroy;
begin
  FreeAndNil(FPivotLineasRepr);
  FreeAndNil(FPivotCantidades);
  FreeAndNil(FPivotCantidadesRecibidas);
  FreeAndNil(FPivotTotalPedido);
  FreeAndNil(FPivotTotalRecibido);
  FreeAndNil(FCeldaSku);
  FreeAndNil(FCeldaAlmacen);
  FreeAndNil(FCeldaLineaPedido);
  FreeAndNil(FCantidadesPendientes);
  FreeAndNil(FARecibirManual);
  FreeAndNil(FPivotColorTexto);
  FreeAndNil(FPivotColorProveedor);
  FreeAndNil(FPivotColorCodigo);
  FreeAndNil(FPivotIdAc);
  FreeAndNil(FPivotArticulo);
  FreeAndNil(FPivotColorAv);
  FreeAndNil(FPivotAlmacen);
  FreeAndNil(FPivotSkuBase);
  FreeAndNil(FPivotSkuPrefijo);
  FreeAndNil(FPivotVarSku);
  FreeAndNil(FPivotSinTalla);
  inherited;
end;

function TGridPivoteCompra.GetSerieNumeroActivos(out ASerie, ANumero: string): Boolean;
begin
  Result  := False;
  ASerie  := '';
  ANumero := '';
  if (FCfg.SourceMaster = nil) or (FCfg.SourceMaster.DataSet = nil) or
     (not FCfg.SourceMaster.DataSet.Active) or
     FCfg.SourceMaster.DataSet.IsEmpty then Exit;
  ASerie  := FCfg.SourceMaster.DataSet.FieldByName(FCfg.FieldSerieMaster).AsString;
  ANumero := FCfg.SourceMaster.DataSet.FieldByName(FCfg.FieldNumeroMaster).AsString;
  Result  := (ASerie <> '') and (ANumero <> '');
end;

function TGridPivoteCompra.GetLineaActiva(out ALinea: Integer;
                                          out ALineaTexto: string): Boolean;
var
  colLinea: TcxGridDBColumn;
  rec     : TcxCustomGridRecord;
  vLinea  : Variant;
begin
  Result := False;
  ALinea := 0;
  ALineaTexto := '';
  if FCfg.Grid <> nil then
  begin
    colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    rec := FCfg.Grid.Controller.FocusedRecord;
    if (colLinea <> nil) and (rec <> nil) then
    begin
      vLinea := FCfg.Grid.DataController.Values[rec.RecordIndex,
                                                colLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
      begin
        ALineaTexto := VarToStr(vLinea);
        ALinea := StrToIntDef(ALineaTexto, 0);
        Result := ALinea > 0;
      end;
    end;
  end;
end;

function TGridPivoteCompra.ResolverAvColorBasico(
  const ACodigoAtbColor: string; out AIdAv: Integer;
  out AValorAv, ANombreColor, AMensaje: string): Boolean;
var
  q      : TUniQuery;
  iIdAtb : Integer;
  sCodigo: string;
begin
  Result := False;
  AIdAv := 0;
  AValorAv := '';
  ANombreColor := '';
  AMensaje := '';
  sCodigo := Trim(ACodigoAtbColor);
  if sCodigo = '' then
    AMensaje := SErrorColorCompraNoSeleccionado
  else if FCfg.Conexion = nil then
    AMensaje := SErrorConexionResolverColorCompra
  else
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := FCfg.Conexion;
      q.SQL.Text :=
        'SELECT ID_ATB, NOMBRE_ATB ' +
        '  FROM fza_atributos_basicos ' +
        ' WHERE ID_VA_ATB = ''CO'' ' +
        '   AND CODIGO_ATB = :cod ' +
        '   AND COALESCE(ESACTIVO_ATB, ''S'') = ''S'' ' +
        ' LIMIT 1';
      q.ParamByName('cod').AsString := sCodigo;
      q.Open;
      if q.IsEmpty then
        AMensaje := Format(SErrorColorBasicoCompraNoExiste, [sCodigo])
      else
      begin
        iIdAtb := q.FieldByName('ID_ATB').AsInteger;
        ANombreColor := q.FieldByName('NOMBRE_ATB').AsString;
        AValorAv := sCodigo;
        q.Close;
        q.SQL.Text :=
          'SELECT ID_AV, ID_ATB_AV ' +
          '  FROM fza_atributos_valores ' +
          ' WHERE ID_VA_AV = ''CO'' ' +
          '   AND AV = :av ' +
          ' LIMIT 1';
        q.ParamByName('av').AsString := AValorAv;
        q.Open;
        if not q.IsEmpty then
        begin
          AIdAv := q.FieldByName('ID_AV').AsInteger;
          if q.FieldByName('ID_ATB_AV').IsNull and (iIdAtb > 0) then
          begin
            q.Close;
            q.SQL.Text :=
              'UPDATE fza_atributos_valores ' +
              '   SET ID_ATB_AV = :id_atb, INSTANTE_MODIF = NOW(), ' +
              '       USUARIO_MODIF = :usuario ' +
              ' WHERE ID_AV = :id_av';
            q.ParamByName('id_atb').AsInteger := iIdAtb;
            q.ParamByName('usuario').AsString :=
              FCfg.ContextoSesion.Identidad.Usuario;
            q.ParamByName('id_av').AsInteger := AIdAv;
            q.Execute;
          end;
        end
        else
        begin
          q.Close;
          q.SQL.Text :=
            'INSERT INTO fza_atributos_valores ' +
            '  (ID_VA_AV, AV, DESCRIPCION_AV, ID_ATB_AV, ESACTIVO_AV, ' +
            '   ORDEN_AV, INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
            '   USUARIO_MODIF) ' +
            'VALUES (''CO'', :av, :descripcion, :id_atb, ''S'', 0, ' +
            '        NOW(), :usuario, NOW(), :usuario)';
          q.ParamByName('av').AsString := AValorAv;
          q.ParamByName('descripcion').AsString := ANombreColor;
          q.ParamByName('id_atb').AsInteger := iIdAtb;
          q.ParamByName('usuario').AsString :=
            FCfg.ContextoSesion.Identidad.Usuario;
          q.Execute;
          q.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID_AV';
          q.Open;
          if not q.IsEmpty then
            AIdAv := q.FieldByName('ID_AV').AsInteger;
        end;
        Result := AIdAv > 0;
        if not Result then
          AMensaje := Format(SErrorResolverColorCompra, [sCodigo]);
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TGridPivoteCompra.ValidarPivotePosible(var AMensaje: string): Boolean;
var
  q           : TUniQuery;
  incidencias : TStringList;
  sSerie      : string;
  sNumero     : string;
begin
  Result   := True;
  AMensaje := '';
  if not GetSerieNumeroActivos(sSerie, sNumero) then Exit;
  incidencias := TStringList.Create;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    // 1. Articulos con talla real pero sin sistema de tallas asignado
    // en la linea. Los articulos con color y sin tallaje son pivotables:
    // se muestran en una unica columna "Cantidad".
    q.SQL.Text :=
      'SELECT DISTINCT L.' + FCfg.FieldArt + ' AS ART ' +
      '  FROM ' + FCfg.TablaLineas + ' L ' +
      ' WHERE L.' + FCfg.FieldSerieLin  + ' = :SERIE ' +
      '   AND L.' + FCfg.FieldNumeroLin + ' = :NUMERO ' +
      '   AND (L.' + FCfg.FieldIdAcPivot + ' IS NULL ' +
      '        OR L.' + FCfg.FieldIdAcPivot + ' = 0) ' +
      '   AND EXISTS ( ' +
      '         SELECT 1 FROM fza_atributos_sku SAT ' +
      '          JOIN fza_atributos_valores AVT ' +
      '            ON AVT.ID_AV = SAT.ID_AV_SA ' +
      '           AND AVT.ID_VA_AV = ''TAL'' ' +
      '         WHERE SAT.CODIGO_UNIDAD_SKU_SA = L.' + FCfg.FieldSku + ') ' +
      ' ORDER BY ART';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add(Format(SErrorArticuloSinSistemaTallasPivote,
        [q.FieldByName('ART').AsString]));
      q.Next;
    end;
    q.Close;
    // 2. Sistemas con mas valores que MaxColumnasTallas. Subquery escalar
    //    para evitar multiplicar al JOINear ACD directamente.
    q.SQL.Text :=
      'SELECT DISTINCT L.' + FCfg.FieldArt + ' AS ART, ' +
      '       AC.NOMBRE_AC AS SISTEMA, ' +
      '       (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
      '         WHERE ACD.ID_AC_ACD = L.' + FCfg.FieldIdAcPivot + ') AS N ' +
      '  FROM ' + FCfg.TablaLineas + ' L ' +
      '  JOIN fza_atributos_conjuntos AC ' +
      '    ON AC.ID_AC = L.' + FCfg.FieldIdAcPivot + ' ' +
      ' WHERE L.' + FCfg.FieldSerieLin  + ' = :SERIE ' +
      '   AND L.' + FCfg.FieldNumeroLin + ' = :NUMERO ' +
      '   AND L.' + FCfg.FieldIdAcPivot + ' > 0 ' +
      '   AND (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
      '         WHERE ACD.ID_AC_ACD = L.' + FCfg.FieldIdAcPivot + ') > :NMAX ' +
      ' ORDER BY ART';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.ParamByName('NMAX').AsInteger  := FCfg.MaxColumnasTallas;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add(Format(SErrorSistemaTallasSuperaMaximoPivote,
        [q.FieldByName('ART').AsString,
         q.FieldByName('SISTEMA').AsString,
         q.FieldByName('N').AsInteger,
         FCfg.MaxColumnasTallas]));
      q.Next;
    end;
    q.Close;
    // 3. SKUs con talla "huerfana" (TAL no presente en el sistema
    //    asignado a la linea).
    q.SQL.Text :=
      'SELECT DISTINCT L.' + FCfg.FieldSku + ' AS SKU, ' +
      '       L.' + FCfg.FieldArt + ' AS ART, AV.AV AS TALLA ' +
      '  FROM ' + FCfg.TablaLineas + ' L ' +
      '  JOIN fza_atributos_sku SAT ' +
      '    ON SAT.CODIGO_UNIDAD_SKU_SA = L.' + FCfg.FieldSku + ' ' +
      '  JOIN fza_atributos_valores AV ' +
      '    ON AV.ID_AV = SAT.ID_AV_SA ' +
      '   AND AV.ID_VA_AV = ''TAL'' ' +
      ' WHERE L.' + FCfg.FieldSerieLin  + ' = :SERIE ' +
      '   AND L.' + FCfg.FieldNumeroLin + ' = :NUMERO ' +
      '   AND L.' + FCfg.FieldIdAcPivot + ' > 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_atributos_conjuntos_det ACD ' +
      '          WHERE ACD.ID_AC_ACD = L.' + FCfg.FieldIdAcPivot + ' ' +
      '            AND ACD.ID_AV_ACD = SAT.ID_AV_SA) ' +
      ' ORDER BY ART, SKU';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add(Format(SErrorSkuFueraSistemaTallasPivote,
        [q.FieldByName('SKU').AsString,
         q.FieldByName('ART').AsString,
         q.FieldByName('TALLA').AsString]));
      q.Next;
    end;
    q.Close;
    if incidencias.Count > 0 then
    begin
      AMensaje := Format(SErrorActivarPivoteTallas, [incidencias.Text]);
      Result := False;
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(incidencias);
  end;
end;

procedure TGridPivoteCompra.Activar;
begin
  if FCfg.SourceLineas = nil then Exit;
  CargarCachePivot;
  FCfg.SourceLineas.OnFilterRecord := FilterRecord;
  FCfg.SourceLineas.Filtered       := True;
  AplicarVisibilidadColumnasPivot(True);
  // IMPORTANTE: RecalcularMaxColumnas pone Visible=True/False en las
  // columnas talla. Cambiar Visible de una columna no-bound en cxGrid
  // limpia su Values[] en el DataController. Por eso tiene que ir
  // ANTES de PublicarCantidadesPivot — si publicasemos primero y luego
  // ajustasemos visibilidad, los valores recien publicados se perderian
  // (asi se rompio cuando se introdujo esta libreria — antes el form
  // hacia Visibilidad -> Publicar y funcionaba; el orden hay que
  // respetarlo).
  if Assigned(FCfg.Gestor) then
  begin
    FCfg.Gestor.RecalcularMaxColumnas;
    FCfg.Gestor.ActualizarCaptionsLineaActiva;
  end;
  AplicarColumnaCantidadSinTalla;
  PublicarCantidadesPivot;
  FActivo := True;
end;

procedure TGridPivoteCompra.Desactivar;
var
  i: Integer;
begin
  // Si estamos expandidos, contraer primero para restaurar la altura
  // de fila antes de salir del modo pivote.
  if FExpandido then
    Contraer;
  if FCfg.SourceLineas <> nil then
  begin
    FCfg.SourceLineas.Filtered       := False;
    FCfg.SourceLineas.OnFilterRecord := nil;
  end;
  FPivotLineasRepr.Clear;
  FPivotCantidades.Clear;
  FPivotCantidadesRecibidas.Clear;
  FPivotTotalPedido.Clear;
  FPivotTotalRecibido.Clear;
  FCeldaSku.Clear;
  FCeldaAlmacen.Clear;
  FCeldaLineaPedido.Clear;
  FCantidadesPendientes.Clear;
  FARecibirManual.Clear;
  FPivotColorTexto.Clear;
  FPivotColorProveedor.Clear;
  FPivotColorCodigo.Clear;
  FPivotIdAc.Clear;
  FPivotArticulo.Clear;
  FPivotColorAv.Clear;
  FPivotAlmacen.Clear;
  FPivotSkuBase.Clear;
  FPivotSkuPrefijo.Clear;
  FPivotVarSku.Clear;
  FPivotSinTalla.Clear;
  AplicarVisibilidadColumnasPivot(False);
  // Ocultar todas las columnas talla al volver a vista plana.
  for i := 0 to High(FCfg.ColumnasTallas) do
    if FCfg.ColumnasTallas[i] <> nil then
      FCfg.ColumnasTallas[i].Visible := False;
  FActivo := False;
end;

function TGridPivoteCompra.PuedeExpandir: Boolean;
begin
  // Solo aplica si la config trae campo de cantidad recibida. Pedidos
  // lo trae; albaranes no (no manejan recibida).
  Result := FCfg.FieldCantidadRecibida <> '';
end;

// Activa el modo expandido: cuadruple altura de fila y deja que
// CustomDrawCellTalla pinte 4 sub-segmentos (Pedida / Pte de recibir /
// Recibida / A recibir). En este modo la columna talla pasa a ser
// EDITABLE y su Value es la cantidad "A recibir" tecleada por el
// usuario; la cantidad pedida deja de publicarse en Values[] (la
// dibuja la lib desde FPivotCantidades). Idempotente.
procedure TGridPivoteCompra.Expandir;
var
  i, recIdx: Integer;
begin
  if (not FActivo) or (not PuedeExpandir) or FExpandido then Exit;
  if FCfg.Grid = nil then Exit;
  FCfg.Grid.DataController.BeginUpdate;
  try
    // 1. Vaciar Values[] de columnas talla. Eran pedida (publicada por
    //    PublicarCantidadesPivot en modo plano pivote); ahora son el
    //    buffer "A recibir".
    for recIdx := 0 to FCfg.Grid.DataController.RecordCount - 1 do
      for i := 0 to High(FCfg.ColumnasTallas) do
        if FCfg.ColumnasTallas[i] <> nil then
          FCfg.Grid.DataController.Values[recIdx,
                                  FCfg.ColumnasTallas[i].Index] := Null;
    // 2. Hacer columnas talla editables.
    for i := 0 to High(FCfg.ColumnasTallas) do
      if FCfg.ColumnasTallas[i] <> nil then
        FCfg.ColumnasTallas[i].Options.Editing := True;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
  FAlturaFilaOriginal := FCfg.Grid.OptionsView.DataRowHeight;
  FCfg.Grid.OptionsView.DataRowHeight := ALTURA_FILA_EXPANDIDA;
  FExpandido := True;
end;

procedure TGridPivoteCompra.Contraer;
var
  i: Integer;
begin
  if not FExpandido then Exit;
  if FCfg.Grid <> nil then
  begin
    // Restaurar altura y desactivar la edicion de columnas talla.
    FCfg.Grid.OptionsView.DataRowHeight := FAlturaFilaOriginal;
    for i := 0 to High(FCfg.ColumnasTallas) do
      if FCfg.ColumnasTallas[i] <> nil then
        FCfg.ColumnasTallas[i].Options.Editing := False;
  end;
  FExpandido := False;
  // Re-publicar las cantidades pedidas en Values[] para que la vista
  // plana pivote vuelva a ensenarlas (en lugar de los Values[]=Null
  // que dejamos al expandir).
  PublicarCantidadesPivot;
end;

// Itera FARecibirManual (dict persistente con las cantidades 'A
// recibir' tecleadas por el usuario) y produce una TCeldaARecibir
// por entrada cuyo almacen mapeado coincida con ACodigoAlm. Antes
// iterabamos Values[] del grid, pero cxGrid borraba los Values[] de
// columnas no-bound al hacer Post entre navegaciones — el dict es
// inmune a eso.
function TGridPivoteCompra.IterarARecibirPorAlmacen(
                            const ACodigoAlm: string): TArray<TCeldaARecibir>;
var
  res    : TList<TCeldaARecibir>;
  pair   : TPair<Int64,Double>;
  sSku   : string;
  sAlm   : string;
  sLineaRaw: string;
  c      : TCeldaARecibir;
begin
  Result := nil;
  if (not FActivo) or (FCfg.Gestor = nil) then Exit;
  if FARecibirManual = nil then Exit;
  res := TList<TCeldaARecibir>.Create;
  try
    for pair in FARecibirManual do
    begin
      if pair.Value <= 0 then Continue;
      // Mapeo celda -> SKU/almacen/linea poblado en CargarCachePivot.
      if not FCeldaSku.TryGetValue(pair.Key, sSku) then Continue;
      if not FCeldaAlmacen.TryGetValue(pair.Key, sAlm) then Continue;
      if not FCeldaLineaPedido.TryGetValue(pair.Key, sLineaRaw) then Continue;
      if not SameText(sAlm, ACodigoAlm) then Continue;
      c.LineaPedido   := sLineaRaw;
      c.CodigoSku     := sSku;
      c.CodigoAlmacen := sAlm;
      c.Cantidad      := pair.Value;
      res.Add(c);
    end;
    Result := res.ToArray;
  finally
    FreeAndNil(res);
  end;
end;

// Limpia las entradas 'A recibir' del FARecibirManual cuyo almacen
// efectivo coincide con ACodigoAlm. Usado tras crear el albaran para
// que el usuario no tenga que borrar los valores procesados antes de
// recibir otro almacen. Tambien dispara invalidacion del grid para
// repintar las celdas afectadas con el segmento 'A recibir' vacio.
procedure TGridPivoteCompra.LimpiarARecibirParaAlmacen(const ACodigoAlm: string);
var
  pair  : TPair<Int64,Double>;
  sAlm  : string;
  aDel  : TList<Int64>;
  iKey  : Int64;
begin
  if FARecibirManual = nil then Exit;
  aDel := TList<Int64>.Create;
  try
    for pair in FARecibirManual do
    begin
      if not FCeldaAlmacen.TryGetValue(pair.Key, sAlm) then Continue;
      if SameText(sAlm, ACodigoAlm) then
        aDel.Add(pair.Key);
    end;
    for iKey in aDel do
      FARecibirManual.Remove(iKey);
  finally
    FreeAndNil(aDel);
  end;
  if Assigned(FCfg.Grid) and Assigned(FCfg.Grid.Site) then
    FCfg.Grid.Site.Invalidate;
end;

// Determina el estado de recepcion de una linea representante segun los
// totales acumulados en FPivotTotalPedido / FPivotTotalRecibido.
function TGridPivoteCompra.GetEstadoFila(iLinea: Integer): TEstadoFilaRecibida;
var
  rPedido, rRecibido: Double;
begin
  rPedido   := 0;
  rRecibido := 0;
  FPivotTotalPedido.TryGetValue(iLinea, rPedido);
  FPivotTotalRecibido.TryGetValue(iLinea, rRecibido);
  if rPedido <= 0 then
    Result := efrIndefinido
  else if rRecibido <= 0 then
    Result := efrNada
  else if rRecibido + 0.0001 >= rPedido then
    Result := efrTotal
  else
    Result := efrParcial;
end;

function TGridPivoteCompra.GetColorEstadoFila(
                                  AEstado: TEstadoFilaRecibida): TColor;
begin
  // Llamadores filtran efrIndefinido antes; aqui devolvemos amarillo
  // como fallback inocuo para evitar usar clNone (cuyo TColor varia
  // entre versiones de Delphi/VCL).
  case AEstado of
    efrParcial : Result := COL_REC_PARCIAL;
    efrTotal   : Result := COL_REC_TOTAL;
  else
    Result := COL_REC_NADA;
  end;
end;

procedure TGridPivoteCompra.RecargarYRepublicar;
var
  sSerie, sNumero, sMensaje: string;
begin
  if not FActivo then Exit;
  if FCfg.SourceLineas = nil then Exit;
  // Si el doc activo ya no es pivotable, auto-desactivamos.
  if not ValidarPivotePosible(sMensaje) then
  begin
    Desactivar;
    Exit;
  end;
  if not GetSerieNumeroActivos(sSerie, sNumero) then Exit;
  FCfg.SourceLineas.Filtered := False;
  CargarCachePivot;
  FCfg.SourceLineas.Filtered := True;
  // RecalcularMaxColumnas antes de PublicarCantidadesPivot por el motivo
  // explicado en Activar (cambiar Visible limpia Values[]).
  if Assigned(FCfg.Gestor) then
  begin
    FCfg.Gestor.InvalidarCache;
    FCfg.Gestor.RecalcularMaxColumnas;
    FCfg.Gestor.ActualizarCaptionsLineaActiva;
  end;
  AplicarColumnaCantidadSinTalla;
  PublicarCantidadesPivot;
end;

procedure TGridPivoteCompra.FilterRecord(DataSet: TDataSet;
                                          var Accept: Boolean);
var
  iLinea: Integer;
begin
  if FPivotLineasRepr = nil then begin Accept := True; Exit; end;
  iLinea := DataSet.FieldByName(FCfg.FieldLinea).AsInteger;
  Accept := FPivotLineasRepr.Contains(iLinea);
end;

procedure TGridPivoteCompra.CargarCachePivot;
var
  q          : TUniQuery;
  dictRepr   : TDictionary<string,Integer>;
  sSerie     : string;
  sNumero    : string;
  sArt       : string;
  sKey       : string;
  iLinea     : Integer;
  iAc        : Integer;
  iColorAv   : Integer;
  iTallaAv   : Integer;
  rCant      : Double;
  rRecibida  : Double;
  iLineaRepr : Integer;
  iKeyPivot  : Int64;
  sSelectRecibida: string;
  bTieneRecibida: Boolean;
  sSku, sAlmLin, sAlmCab, sAlmEfe, sLineaRaw, sVarSku: string;
begin
  FPivotLineasRepr.Clear;
  FPivotCantidades.Clear;
  FPivotCantidadesRecibidas.Clear;
  FPivotTotalPedido.Clear;
  FPivotTotalRecibido.Clear;
  FPivotColorTexto.Clear;
  FPivotColorProveedor.Clear;
  FPivotColorCodigo.Clear;
  FPivotIdAc.Clear;
  FPivotArticulo.Clear;
  FPivotColorAv.Clear;
  FPivotAlmacen.Clear;
  FPivotSkuBase.Clear;
  FPivotSkuPrefijo.Clear;
  FPivotVarSku.Clear;
  FPivotSinTalla.Clear;
  FPivotMaxAvTalla := 0;
  if not GetSerieNumeroActivos(sSerie, sNumero) then Exit;
  bTieneRecibida := FCfg.FieldCantidadRecibida <> '';
  if bTieneRecibida then
    sSelectRecibida := ', IFNULL(L.' + FCfg.FieldCantidadRecibida + ', 0) AS RECIBIDA '
  else
    sSelectRecibida := ', 0 AS RECIBIDA ';
  // Almacen de cabecera para fallback cuando la linea no lleva el suyo.
  sAlmCab := '';
  if (FCfg.FieldAlmacenMaster <> '') and Assigned(FCfg.SourceMaster) and
     Assigned(FCfg.SourceMaster.DataSet) and FCfg.SourceMaster.DataSet.Active
     and (not FCfg.SourceMaster.DataSet.IsEmpty) then
    sAlmCab := FCfg.SourceMaster.DataSet.FieldByName(FCfg.FieldAlmacenMaster).AsString;
  dictRepr := TDictionary<string,Integer>.Create;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    // JOINs directos a fza_atributos_sku/valores/basicos (la vista
    // vi_atributos_sku_basico es lenta por sus muchos LEFT JOIN).
    q.SQL.Text :=
      'SELECT L.' + FCfg.FieldLinea + ' AS LINEA, ' +
      '       L.' + FCfg.FieldArt + ' AS ART, ' +
      '       COALESCE(L.' + FCfg.FieldIdAcPivot + ', 0) AS ID_AC, ' +
      '       COALESCE(AVC.ID_AV, 0) AS COLOR_AV, ' +
      // COLOR_TXT: texto del COLOR DEL SKU (AVC.AV, p.ej. "VERDE"). El
      // cuadradito visual lo aporta CODIGO_ATB via lookup HEX. Asi el
      // usuario ve la etiqueta del SKU y a su lado el cuadradito del
      // basico que le aplica. Si no hay AV, fallback al nombre del
      // basico y luego al parseo del codigo SKU.
      '       COALESCE(NULLIF(AVC.AV, ''''), ATBC.NOMBRE_ATB, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.' + FCfg.FieldSku + ', ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_TXT, ' +
      // COLOR_PROV_TXT: el COLOR DEL PROVEEDOR (texto libre, p.ej. "011"
      // o "AZUL TURQUESA PROV-XYZ"). Solo se lee si la config trae
      // FieldColorTexto (pedidos lo tiene como COLOR_TEXTO_PEDCLIN).
      // Vacio para albaranes.
      IfThen(FCfg.FieldColorTexto <> '',
             '       COALESCE(NULLIF(L.' + FCfg.FieldColorTexto + ', ''''), '''') AS COLOR_PROV_TXT, ',
             '       '''' AS COLOR_PROV_TXT, ') +
      '       COALESCE(ATBC.CODIGO_ATB, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.' + FCfg.FieldSku + ', ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_COD, ' +
      '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
      '       L.' + FCfg.FieldCantidad + ' AS CANTIDAD, ' +
      '       L.' + FCfg.FieldSku + ' AS SKU, ' +
      '       COALESCE(SKU0.CODIGO_VAR_SKU, ''TC'') AS VAR_SKU, ' +
      '       L.' + FCfg.FieldAlmacen + ' AS ALM_LIN ' +
      sSelectRecibida +
      '  FROM ' + FCfg.TablaLineas + ' L ' +
      '  LEFT JOIN fza_articulos_skus SKU0 ' +
      '    ON SKU0.CODIGO_UNIDAD_SKU = L.' + FCfg.FieldSku + ' ' +
      // SAC: filtramos a la fila del atributo CO para que la fza_
      // atributos_sku no multiplique filas (un SKU tiene N atributos,
      // y sin filtro el resto del SELECT se replicaba N veces; las
      // sumas de CANTIDAD y RECIBIDA salian multiplicadas por N en el
      // cache de pivote y la matriz se veia duplicada).
      '  LEFT JOIN fza_atributos_sku SAC ' +
      '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.' + FCfg.FieldSku + ' ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
      '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
      '                  AND AV.ID_VA_AV = ''CO'') ' +
      '  LEFT JOIN fza_atributos_valores AVC ' +
      '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
      '   AND AVC.ID_VA_AV = ''CO'' ' +
      '  LEFT JOIN fza_atributos_basicos ATBC ' +
      '    ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
      '  LEFT JOIN fza_atributos_sku T ' +
      '    ON T.CODIGO_UNIDAD_SKU_SA = L.' + FCfg.FieldSku + ' ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVT ' +
      '                WHERE AVT.ID_AV = T.ID_AV_SA ' +
      '                  AND AVT.ID_VA_AV = ''TAL'') ' +
      ' WHERE L.' + FCfg.FieldSerieLin  + ' = :SERIE ' +
      '   AND L.' + FCfg.FieldNumeroLin + ' = :NUMERO ' +
      ' ORDER BY ART, COLOR_AV, L.' + FCfg.FieldLinea;
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      iLinea    := q.FieldByName('LINEA').AsInteger;
      sArt      := q.FieldByName('ART').AsString;
      iAc       := q.FieldByName('ID_AC').AsInteger;
      iColorAv  := q.FieldByName('COLOR_AV').AsInteger;
      iTallaAv  := q.FieldByName('TALLA_AV').AsInteger;
      rCant     := q.FieldByName('CANTIDAD').AsFloat;
      rRecibida := q.FieldByName('RECIBIDA').AsFloat;
      sSku      := q.FieldByName('SKU').AsString;
      sVarSku   := q.FieldByName('VAR_SKU').AsString;
      sAlmLin   := q.FieldByName('ALM_LIN').AsString;
      sLineaRaw := q.FieldByName('LINEA').AsString;
      // Almacen efectivo: el de la linea con fallback al de cabecera.
      if Trim(sAlmLin) <> '' then
        sAlmEfe := sAlmLin
      else
        sAlmEfe := sAlmCab;
      sKey := sArt + '|' + IntToStr(iColorAv);
      if not dictRepr.TryGetValue(sKey, iLineaRepr) then
      begin
        iLineaRepr := iLinea;
        dictRepr.Add(sKey, iLineaRepr);
        FPivotLineasRepr.Add(iLineaRepr);
        FPivotColorTexto.AddOrSetValue(iLineaRepr,
                                       q.FieldByName('COLOR_TXT').AsString);
        FPivotColorProveedor.AddOrSetValue(iLineaRepr,
                                       q.FieldByName('COLOR_PROV_TXT').AsString);
        FPivotColorCodigo.AddOrSetValue(iLineaRepr,
                                        q.FieldByName('COLOR_COD').AsString);
        FPivotIdAc.AddOrSetValue(iLineaRepr, iAc);
        FPivotArticulo.AddOrSetValue(iLineaRepr, sArt);
        FPivotColorAv.AddOrSetValue(iLineaRepr, iColorAv);
        FPivotAlmacen.AddOrSetValue(iLineaRepr, sAlmEfe);
        FPivotSkuBase.AddOrSetValue(iLineaRepr, sSku);
        FPivotSkuPrefijo.AddOrSetValue(iLineaRepr, PrefijoSkuTalla(sSku));
        FPivotVarSku.AddOrSetValue(iLineaRepr, sVarSku);
      end;
      // Totales por linea representante — alimentan el color de estado.
      if FPivotTotalPedido.ContainsKey(iLineaRepr) then
        FPivotTotalPedido[iLineaRepr] := FPivotTotalPedido[iLineaRepr] + rCant
      else
        FPivotTotalPedido.Add(iLineaRepr, rCant);
      if FPivotTotalRecibido.ContainsKey(iLineaRepr) then
        FPivotTotalRecibido[iLineaRepr] := FPivotTotalRecibido[iLineaRepr] + rRecibida
      else
        FPivotTotalRecibido.Add(iLineaRepr, rRecibida);
      if iTallaAv > 0 then
      begin
        iKeyPivot := Int64(iLineaRepr) * 100000 + iTallaAv;
        if FPivotCantidades.ContainsKey(iKeyPivot) then
          FPivotCantidades[iKeyPivot] := FPivotCantidades[iKeyPivot] + rCant
        else
          FPivotCantidades.Add(iKeyPivot, rCant);
        if FPivotCantidadesRecibidas.ContainsKey(iKeyPivot) then
          FPivotCantidadesRecibidas[iKeyPivot] :=
                                FPivotCantidadesRecibidas[iKeyPivot] + rRecibida
        else
          FPivotCantidadesRecibidas.Add(iKeyPivot, rRecibida);
        // Mapeo celda -> SKU concreto + almacen + linea_pedido. Cada
        // (repr, talla) corresponde a una unica linea de pedido (la del
        // SKU exacto), asi que aqui solo hay que setear (no acumular).
        FCeldaSku.AddOrSetValue(iKeyPivot, sSku);
        FCeldaAlmacen.AddOrSetValue(iKeyPivot, sAlmEfe);
        FCeldaLineaPedido.AddOrSetValue(iKeyPivot, sLineaRaw);
        if iTallaAv > FPivotMaxAvTalla then FPivotMaxAvTalla := iTallaAv;
      end;
      if (iTallaAv <= 0) and (iAc <= 0) then
      begin
        FPivotSinTalla.AddOrSetValue(iLineaRepr, True);
        iKeyPivot := Int64(iLineaRepr) * 100000 + ID_AV_SIN_TALLA;
        if FPivotCantidades.ContainsKey(iKeyPivot) then
          FPivotCantidades[iKeyPivot] := FPivotCantidades[iKeyPivot] + rCant
        else
          FPivotCantidades.Add(iKeyPivot, rCant);
        if FPivotCantidadesRecibidas.ContainsKey(iKeyPivot) then
          FPivotCantidadesRecibidas[iKeyPivot] :=
                                FPivotCantidadesRecibidas[iKeyPivot] + rRecibida
        else
          FPivotCantidadesRecibidas.Add(iKeyPivot, rRecibida);
        FCeldaSku.AddOrSetValue(iKeyPivot, sSku);
        FCeldaAlmacen.AddOrSetValue(iKeyPivot, sAlmEfe);
        FCeldaLineaPedido.AddOrSetValue(iKeyPivot, sLineaRaw);
      end;
      q.Next;
    end;
    q.Close;
  finally
    FreeAndNil(q);
    FreeAndNil(dictRepr);
  end;
end;

function TGridPivoteCompra.EsLineaSinTalla(iLinea: Integer): Boolean;
begin
  Result := (FPivotSinTalla <> nil) and FPivotSinTalla.ContainsKey(iLinea);
end;

procedure TGridPivoteCompra.AplicarColumnaCantidadSinTalla;
var
  i       : Integer;
  bVisible: Boolean;
begin
  if (FPivotSinTalla = nil) or (FPivotSinTalla.Count = 0) then Exit;
  if Length(FCfg.ColumnasTallas) = 0 then Exit;
  if FCfg.ColumnasTallas[0] = nil then Exit;
  bVisible := False;
  for i := 0 to High(FCfg.ColumnasTallas) do
    if (FCfg.ColumnasTallas[i] <> nil) and FCfg.ColumnasTallas[i].Visible then
      bVisible := True;
  if not bVisible then
  begin
    FCfg.ColumnasTallas[0].Visible := True;
    FCfg.ColumnasTallas[0].Caption := 'Cantidad';
  end;
end;

procedure TGridPivoteCompra.PublicarCantidadesPivot;
var
  colLinea : TcxGridDBColumn;
  recIdx   : Integer;
  vLinea   : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  i        : Integer;
  iKey     : Int64;
  rCant    : Double;
begin
  if FCfg.Gestor = nil then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  FActualizandoGrid := True;
  try
    FCfg.Grid.DataController.BeginUpdate;
    try
      for recIdx := 0 to FCfg.Grid.DataController.RecordCount - 1 do
      begin
        vLinea := FCfg.Grid.DataController.Values[recIdx, colLinea.Index];
        if VarIsNull(vLinea) or VarIsEmpty(vLinea) then Continue;
        // LINEA es varchar(4): forzamos StrToIntDef para que las keys casen.
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
        if iLinea <= 0 then Continue;
        if not FPivotIdAc.TryGetValue(iLinea, iAc) then Continue;
        if Assigned(FCfg.ColColorPivot) and Assigned(FPivotColorTexto) then
        begin
          if FPivotColorTexto.ContainsKey(iLinea) then
            FCfg.Grid.DataController.Values[recIdx,
                                  FCfg.ColColorPivot.Index] := FPivotColorTexto[iLinea];
        end;
        // Columna del color del proveedor (solo si se configuro).
        if Assigned(FCfg.ColColorProveedorPivot) and
           Assigned(FPivotColorProveedor) then
        begin
          if FPivotColorProveedor.ContainsKey(iLinea) then
            FCfg.Grid.DataController.Values[recIdx,
                    FCfg.ColColorProveedorPivot.Index] := FPivotColorProveedor[iLinea];
        end;
        if EsLineaSinTalla(iLinea) then
        begin
          if FExpandido then Continue;
          if (Length(FCfg.ColumnasTallas) > 0) and
             (FCfg.ColumnasTallas[0] <> nil) then
          begin
            iKey := Int64(iLinea) * 100000 + ID_AV_SIN_TALLA;
            if FPivotCantidades.TryGetValue(iKey, rCant) and
               (rCant <> 0) then
              FCfg.Grid.DataController.Values[recIdx,
                                    FCfg.ColumnasTallas[0].Index] := rCant
            else
              FCfg.Grid.DataController.Values[recIdx,
                                    FCfg.ColumnasTallas[0].Index] := Null;
          end;
          Continue;
        end;
        if iAc <= 0 then Continue;
        // En modo EXPANDIDO no publicamos pedida en Values[]: la pinta la
        // lib desde FPivotCantidades, y Values[] es el buffer "A recibir"
        // que el usuario teclea.
        if FExpandido then Continue;
        arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
        for i := 0 to High(arr) do
        begin
          if i >= FCfg.MaxColumnasTallas then Break;
          if (i >= Length(FCfg.ColumnasTallas)) or
             (FCfg.ColumnasTallas[i] = nil) then Continue;
          iKey := Int64(iLinea) * 100000 + arr[i].IdAv;
          if FPivotCantidades.TryGetValue(iKey, rCant) and (rCant <> 0) then
            FCfg.Grid.DataController.Values[recIdx,
                                  FCfg.ColumnasTallas[i].Index] := rCant
          else
            FCfg.Grid.DataController.Values[recIdx,
                                  FCfg.ColumnasTallas[i].Index] := Null;
        end;
      end;
    finally
      FCfg.Grid.DataController.EndUpdate;
    end;
  finally
    FActualizandoGrid := False;
  end;
end;

procedure TGridPivoteCompra.AplicarVisibilidadColumnasPivot(
                                                       AModoPivot: Boolean);
var
  i   : Integer;
  col : TcxGridColumn;
begin
  for i := 0 to High(FCfg.CamposOcultosEnPivote) do
  begin
    col := FCfg.Grid.GetColumnByFieldName(FCfg.CamposOcultosEnPivote[i]);
    if col <> nil then
      col.Visible := not AModoPivot;
  end;
  if Assigned(FCfg.ColColorPivot) then
    FCfg.ColColorPivot.Visible := AModoPivot;
  if Assigned(FCfg.ColColorProveedorPivot) then
    FCfg.ColColorProveedorPivot.Visible := AModoPivot;
  IntercambiarPosicionColorAlmacen(AModoPivot);
end;

// Coloca ACol inmediatamente ANTES de ARef en el orden de columnas del
// grid. Idempotente y valido venga ACol de antes o de despues de ARef:
// asignar Index reordena la coleccion, asi que hay que compensar el
// desplazamiento segun la direccion del movimiento (si ACol viene de un
// indice menor, al sacarla ARef baja una posicion -> destino ARef.Index-1).
procedure MoverColumnaJustoAntes(ACol, ARef: TcxGridColumn);
begin
  if (ACol <> nil) and (ARef <> nil) and (ACol <> ARef) then
  begin
    if ACol.Index < ARef.Index then
      ACol.Index := ARef.Index - 1
    else
      ACol.Index := ARef.Index;
  end;
end;

// Coloca ACol inmediatamente DESPUES de ARef. Misma compensacion que
// MoverColumnaJustoAntes pero al otro lado.
procedure MoverColumnaJustoDespues(ACol, ARef: TcxGridColumn);
begin
  if (ACol <> nil) and (ARef <> nil) and (ACol <> ARef) then
  begin
    if ACol.Index < ARef.Index then
      ACol.Index := ARef.Index
    else
      ACol.Index := ARef.Index + 1;
  end;
end;

procedure TGridPivoteCompra.IntercambiarPosicionColorAlmacen(
                                                       AModoPivot: Boolean);
var
  colAlm          : TcxGridDBColumn;
  colPrimeraTalla : TcxGridDBColumn;
  colUltimaTalla  : TcxGridDBColumn;
begin
  if not Assigned(FCfg.ColColorPivot) then Exit;
  if FCfg.FieldAlmacen = '' then Exit;
  colAlm := FCfg.Grid.GetColumnByFieldName(FCfg.FieldAlmacen);
  if colAlm = nil then Exit;
  if Length(FCfg.ColumnasTallas) = 0 then Exit;
  colPrimeraTalla := FCfg.ColumnasTallas[0];
  colUltimaTalla  := FCfg.ColumnasTallas[High(FCfg.ColumnasTallas)];
  if (colPrimeraTalla = nil) or (colUltimaTalla = nil) then Exit;
  if AModoPivot then
  begin
    // Guardamos las posiciones originales una sola vez para restaurarlas
    // al salir del pivote (vista plana).
    if FOrigColIndexAlm < 0 then FOrigColIndexAlm := colAlm.Index;
    if FOrigColIndexCol < 0 then FOrigColIndexCol := FCfg.ColColorPivot.Index;
    // 'Color' JUSTO ANTES de la primera columna talla. Antes esto se hacia
    // con un intercambio Color<->Almacen por indices, fragil: si la rutina
    // corria un numero PAR de veces (apertura por preferencia + toggles /
    // eventos del grid) el intercambio se deshacia y 'Color' reaparecia al
    // final del grid (tras el almacen). El posicionamiento idempotente lo
    // evita: llamarlo N veces deja siempre el mismo orden.
    MoverColumnaJustoAntes(FCfg.ColColorPivot, colPrimeraTalla);
    // Color del proveedor (si la config lo trae) pegado antes de 'Color'.
    if Assigned(FCfg.ColColorProveedorPivot) then
    begin
      if FOrigColIndexColProv < 0 then
        FOrigColIndexColProv := FCfg.ColColorProveedorPivot.Index;
      MoverColumnaJustoAntes(FCfg.ColColorProveedorPivot, FCfg.ColColorPivot);
    end;
    // 'Almacen' JUSTO DESPUES de la ultima columna talla (al final del
    // bloque de tallas).
    MoverColumnaJustoDespues(colAlm, colUltimaTalla);
  end
  else
  begin
    // Restaurar el orden original de la vista plana.
    if FOrigColIndexCol >= 0 then FCfg.ColColorPivot.Index := FOrigColIndexCol;
    if FOrigColIndexAlm >= 0 then colAlm.Index := FOrigColIndexAlm;
    if Assigned(FCfg.ColColorProveedorPivot) and
       (FOrigColIndexColProv >= 0) then
      FCfg.ColColorProveedorPivot.Index := FOrigColIndexColProv;
  end;
end;

// Pinta las celdas en modo pivote: (1) sombrea las celdas talla fuera
// del conjunto, (2) en modo expandido pinta el fondo de toda la fila
// con el color de estado de recepcion y dibuja pedido en mitad superior
// + recibida en mitad inferior dentro de las celdas talla. La edicion
// se bloquea en EditingCeldaTalla.
procedure TGridPivoteCompra.CustomDrawCellTalla(
            Sender: TcxCustomGridTableView;
            ACanvas: TcxCanvas;
            AViewInfo: TcxGridTableDataCellViewInfo;
            var ADone: Boolean);
var
  Col       : TcxGridColumn;
  colLinea  : TcxGridColumn;
  vLin      : Variant;
  iAc       : Integer;
  iLinea    : Integer;
  arr       : TArrPosConjunto;
  bEsTalla  : Boolean;
  estado    : TEstadoFilaRecibida;
  ColorFila : TColor;
  iTallaAv  : Integer;
  iKey      : Int64;
  rPedido   : Double;
  rRecibida : Double;
  rARecibir : Double;
  bSinTalla : Boolean;
begin
  if (not FActivo) or (FCfg.Gestor = nil) then Exit;
  if AViewInfo.GridRecord = nil then Exit;
  if not (AViewInfo.Item is TcxGridColumn) then Exit;
  Col := TcxGridColumn(AViewInfo.Item);
  bEsTalla := (Col.Tag >= 1) and (Col.Tag <= FCfg.MaxColumnasTallas) and
              (Col.Tag - 1 < Length(FCfg.ColumnasTallas)) and
              (Col = FCfg.ColumnasTallas[Col.Tag - 1]);

  // Obtener LINEA del record (siempre necesario para resolver iAc y
  // pintar). Si la columna LINEA no esta en el grid no podemos hacer
  // nada.
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := AViewInfo.GridRecord.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLinea := StrToIntDef(VarToStr(vLin), 0);
  if iLinea <= 0 then Exit;

  // iAc: lo leemos del cache FPivotIdAc (poblado en CargarCachePivot)
  // en vez de buscarlo en una columna ID_AC_PIVOT_* del grid — esa
  // columna puede no existir en el DFM y entonces iAc se quedaba a 0
  // y nunca pintabamos las cantidades.
  iAc := 0;
  if not FPivotIdAc.TryGetValue(iLinea, iAc) then iAc := 0;
  bSinTalla := EsLineaSinTalla(iLinea);

  // 1. GRAY-OUT de celdas talla fuera del conjunto pivot (no depende de
  //    modo expandido).
  if bEsTalla and bSinTalla and (Col.Tag > 1) then
  begin
    ACanvas.Brush.Color := $00E8E8E8;
    ACanvas.FillRect(AViewInfo.Bounds);
    ADone := True;
    Exit;
  end;
  if bEsTalla and (not bSinTalla) and (iAc > 0) then
  begin
    arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
    if Col.Tag > Length(arr) then
    begin
      ACanvas.Brush.Color := $00E8E8E8;
      ACanvas.FillRect(AViewInfo.Bounds);
      ADone := True;
      Exit;
    end;
  end;

  // 2. EXIT si no expandido. El resto del pintado solo aplica con
  //    pivote expandido.
  if not (FExpandido and PuedeExpandir) then Exit;

  estado    := GetEstadoFila(iLinea);
  if estado = efrIndefinido then Exit;
  ColorFila := GetColorEstadoFila(estado);
  // En celdas NO-talla cedemos el control a cxGrid cuando el record
  // esta seleccionado para que se respete el highlight de seleccion.
  // En celdas talla SIEMPRE pintamos las 3 sub-secciones (Pedido /
  // Recibida / A recibir) porque si no, al focusear / editar la fila
  // las cantidades pintadas desaparecen y el usuario pierde la
  // referencia visual mientras teclea las recepciones.
  if (not bEsTalla) and AViewInfo.GridRecord.Selected then Exit;

  if bEsTalla then
  begin
    // Celdas talla validas: 3 sub-segmentos verticales:
    //   1. Pedido    (gris)
    //   2. Recibido  (verde italic)
    //   3. A recibir (azul, negrita, EDITABLE)
    if bSinTalla then
    begin
      if Col.Tag <> 1 then Exit;
      iTallaAv := ID_AV_SIN_TALLA;
    end
    else
    begin
      if iAc <= 0 then Exit;
      arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
      if Col.Tag > Length(arr) then Exit;
      iTallaAv := arr[Col.Tag - 1].IdAv;
    end;
    iKey      := Int64(iLinea) * 100000 + iTallaAv;
    rPedido   := 0;
    rRecibida := 0;
    rARecibir := 0;
    FPivotCantidades.TryGetValue(iKey, rPedido);
    FPivotCantidadesRecibidas.TryGetValue(iKey, rRecibida);
    FARecibirManual.TryGetValue(iKey, rARecibir);
    PintarCeldaTalla3Segmentos(ACanvas, AViewInfo, ColorFila,
                                rPedido, rRecibida, rARecibir);
    // Resalte de celda focused: borde grueso navy sobre los 3 sub-
    // segmentos para que el usuario sepa donde esta tras Tab / flechas
    // sin tener que mirar el label de contexto.
    if (FCfg.Grid.Controller.FocusedRecord = AViewInfo.GridRecord) and
       (FCfg.Grid.Controller.FocusedItem   = AViewInfo.Item) then
      DibujarBordeFocused(ACanvas, AViewInfo.Bounds);
    ADone := True;
  end
  else
  begin
    // Celdas no-talla: solo fondo (el texto lo pinta cxGrid encima).
    ACanvas.Brush.Color := ColorFila;
    ACanvas.FillRect(AViewInfo.Bounds);
  end;
end;

// Pinta las 3 sub-secciones verticales de una celda talla en modo
// expandido: Pedido / Recibido / A recibir.
// El "A recibir" llega como parametro precalculado desde el caller
// (que lee FARecibirManual). Antes se leia de Values[], pero cxGrid
// borra los Values[] de columnas no-bound al hacer Post — la entrada
// quedaba volatil entre navegaciones.
procedure TGridPivoteCompra.PintarCeldaTalla3Segmentos(
                       ACanvas: TcxCanvas;
                       AViewInfo: TcxGridTableDataCellViewInfo;
                       AColorFondo: TColor;
                       APedida, ARecibida, ARecibir: Double);
var
  rARec     : Double;
  b: TRect;
  hSeg, top1, top2, top3: Integer;
  rect1, rect2, rect3: TRect;
  sPed, sRec, sARec: string;
begin
  rARec := ARecibir;
  // Mostramos las 3 sub-filas siempre, aunque la cantidad sea 0 (asi
  // el usuario ve claramente que la celda tiene 3 partes: Pedido /
  // Recibido / A recibir). Si Pedido es 0 dejamos en blanco para no
  // ensuciar las celdas talla que no pertenecen al conjunto (no
  // deberian llegar aqui pero por defensa).
  if APedida > 0 then
    sPed := IntToStr(Round(APedida))
  else
    sPed := '';
  sRec  := IntToStr(Round(ARecibida));
  if rARec > 0 then
    sARec := IntToStr(Round(rARec))
  else
    sARec := '';
  ACanvas.Brush.Color := AColorFondo;
  ACanvas.FillRect(AViewInfo.Bounds);
  b    := AViewInfo.Bounds;
  hSeg := (b.Bottom - b.Top) div 3;
  top1 := b.Top;
  top2 := b.Top + hSeg;
  top3 := b.Top + 2 * hSeg;
  rect1 := Rect(b.Left, top1, b.Right, top2);
  rect2 := Rect(b.Left, top2, b.Right, top3);
  rect3 := Rect(b.Left, top3, b.Right, b.Bottom);
  ACanvas.Brush.Style := bsClear;
  // Pedido: gris claro
  ACanvas.Font.Style  := [];
  ACanvas.Font.Color  := clGrayText;
  DrawText(ACanvas.Handle, PChar(sPed), Length(sPed), rect1,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  // Recibido: verde italic (siempre se muestra para que el usuario
  // distinga la fila incluso cuando recibido = 0).
  ACanvas.Font.Color := clGreen;
  ACanvas.Font.Style := [fsItalic];
  DrawText(ACanvas.Handle, PChar(sRec), Length(sRec), rect2,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  // A recibir: azul negrita (editable). Si esta vacio dejamos blanco
  // para no confundir con un valor real cero.
  ACanvas.Font.Color := clBlue;
  ACanvas.Font.Style := [fsBold];
  DrawText(ACanvas.Handle, PChar(sARec), Length(sARec), rect3,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  ACanvas.Font.Style := [];
  // Lineas separadoras horizontales finas entre las 3 sub-filas para
  // dejar claro al usuario que la celda tiene 3 areas diferentes.
  ACanvas.Pen.Color := clSilver;
  ACanvas.Pen.Width := 1;
  ACanvas.MoveTo(b.Left,  top2);
  ACanvas.LineTo(b.Right, top2);
  ACanvas.MoveTo(b.Left,  top3);
  ACanvas.LineTo(b.Right, top3);
  ACanvas.Brush.Style := bsSolid;
end;

// Dibuja un borde grueso navy sobre la celda focused para que el
// usuario sepa donde esta tras Tab / flechas. Se pinta encima de los
// sub-segmentos sin alterarlos.
procedure TGridPivoteCompra.DibujarBordeFocused(ACanvas: TcxCanvas;
                                                  const ARect: TRect);
var
  r: TRect;
begin
  r := ARect;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color   := clNavy;
  ACanvas.Pen.Width   := 2;
  ACanvas.Pen.Style   := psSolid;
  ACanvas.Rectangle(r.Left + 1, r.Top + 1, r.Right - 1, r.Bottom - 1);
  ACanvas.Pen.Width   := 1;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TGridPivoteCompra.EditingCeldaTalla(Sender: TcxCustomGridTableView;
                                               AItem: TcxCustomGridTableItem;
                                               var AAllow: Boolean);
var
  rec       : TcxCustomGridRecord;
  colLinea  : TcxGridColumn;
  vLinea    : Variant;
  fld       : TField;
  iAc       : Integer;
  arr       : TArrPosConjunto;
  iLinea    : Integer;
  bEsTalla  : Boolean;
begin
  bEsTalla := (AItem <> nil) and
              (AItem.Tag >= 1) and
              (AItem.Tag <= FCfg.MaxColumnasTallas) and
              (AItem.Tag - 1 < Length(FCfg.ColumnasTallas)) and
              (AItem = FCfg.ColumnasTallas[AItem.Tag - 1]);
  if bEsTalla then
  begin
    AAllow := False;
    if (not FExpandido) and
       (FCfg.Gestor <> nil) and
       (FCfg.SourceLineas <> nil) and
       (not FCfg.SourceLineas.IsEmpty) then
    begin
      rec := nil;
      if Sender <> nil then
        rec := Sender.Controller.FocusedRecord;
      colLinea := nil;
      if FCfg.Grid <> nil then
        colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
      iLinea := 0;
      if (rec <> nil) and (colLinea <> nil) then
      begin
        vLinea := rec.Values[colLinea.Index];
        if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
          iLinea := StrToIntDef(VarToStr(vLinea), 0);
      end;
      fld := FCfg.SourceLineas.FindField(FCfg.FieldLinea);
      if (iLinea <= 0) and (fld <> nil) then
        iLinea := fld.AsInteger;
      if iLinea > 0 then
      begin
        if EsLineaSinTalla(iLinea) then
          AAllow := AItem.Tag = 1
        else
        begin
          iAc := 0;
          if not FPivotIdAc.TryGetValue(iLinea, iAc) then
          begin
            fld := FCfg.SourceLineas.FindField(FCfg.FieldIdAcPivot);
            if fld <> nil then
              iAc := fld.AsInteger;
          end;
          if iAc > 0 then
          begin
            arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
            AAllow := AItem.Tag <= Length(arr);
          end;
        end;
      end;
    end;
  end;
end;

// Captura de teclas en modo pivote expandido. El editor inplace esta
// bloqueado en EditingCeldaTalla, asi que las pulsaciones del usuario
// llegan al OnKeyDown del grid y se redirigen aqui. Modifica Values[]
// de la celda focused y dispara repintado para que el nuevo valor
// aparezca en el sub-segmento "A recibir". Devuelve True si consumio
// la tecla.
function TGridPivoteCompra.ProcesarTeclaCeldaTalla(AKey: Word): Boolean;
var
  rec      : TcxCustomGridRecord;
  col      : TcxGridColumn;
  colLinea : TcxGridColumn;
  vLin     : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  bEsTalla : Boolean;
  vVal     : Variant;
  s        : string;
  recIdx   : Integer;
  colIdx   : Integer;
  ch       : Char;
begin
  Result := False;
  if not (FActivo and FExpandido and PuedeExpandir) then Exit;
  if FCfg.Grid = nil then Exit;
  rec := FCfg.Grid.Controller.FocusedRecord;
  col := FCfg.Grid.Controller.FocusedColumn;
  if (rec = nil) or (col = nil) then Exit;
  if (col.Tag < 1) or (col.Tag > FCfg.MaxColumnasTallas) then Exit;
  bEsTalla := (col.Tag - 1 < Length(FCfg.ColumnasTallas)) and
              (col = FCfg.ColumnasTallas[col.Tag - 1]);
  if not bEsTalla then Exit;
  // Solo celdas dentro del conjunto del articulo.
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := rec.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLinea := StrToIntDef(VarToStr(vLin), 0);
  if iLinea <= 0 then Exit;
  if not FPivotIdAc.TryGetValue(iLinea, iAc) then Exit;
  if iAc <= 0 then Exit;
  arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
  if col.Tag > Length(arr) then Exit;
  recIdx := rec.RecordIndex;
  colIdx := col.Index;
  vVal := FCfg.Grid.DataController.Values[recIdx, colIdx];
  if VarIsNull(vVal) or VarIsEmpty(vVal) then
    s := ''
  else
  begin
    if VarIsNumeric(vVal) then
      s := IntToStr(Round(Double(vVal)))
    else
      s := VarToStr(vVal);
  end;
  // VK_0..VK_9 no estan declarados en Winapi.Windows (Microsoft no
  // les puso nombre, son simplemente Ord('0')..Ord('9') = $30..$39).
  // Usamos los valores literales para el rango de digitos.
  case AKey of
    VK_BACK:
      if s <> '' then s := Copy(s, 1, Length(s) - 1);
    VK_DELETE, VK_ESCAPE:
      s := '';
    Ord('0')..Ord('9'):
      begin
        ch := Char(AKey);
        s := s + ch;
      end;
    VK_NUMPAD0..VK_NUMPAD9:
      begin
        ch := Char(Ord('0') + (AKey - VK_NUMPAD0));
        s := s + ch;
      end;
  else
    Exit;
  end;
  // BeginUpdate/EndUpdate envuelve el cambio para que cxGrid notifique
  // el repintado tras EndUpdate. Sin esto el nuevo valor en Values[]
  // no se refleja en el sub-segmento 'A recibir' hasta otro evento.
  FCfg.Grid.DataController.BeginUpdate;
  try
    if s = '' then
      FCfg.Grid.DataController.Values[recIdx, colIdx] := Null
    else
      FCfg.Grid.DataController.Values[recIdx, colIdx] := StrToIntDef(s, 0);
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
  Result := True;
end;

procedure TGridPivoteCompra.InitEditCeldaTalla(
                          Sender: TcxCustomGridTableView;
                          AItem: TcxCustomGridTableItem;
                          AEdit: TcxCustomEdit);
begin
  // Estilo Excel: seleccion total al entrar a la celda. En modo
  // expandido el editor de celdas talla esta bloqueado por
  // EditingCeldaTalla, asi que aqui solo aplica a celdas no-talla y
  // a modo vertical.
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

function TGridPivoteCompra.GetInfoCeldaTallaActiva(
                              out ATallaCaption: string;
                              out APedido, ARecibida: Double): Boolean;
var
  rec      : TcxCustomGridRecord;
  col      : TcxGridColumn;
  colLinea : TcxGridColumn;
  vLin     : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  iKey     : Int64;
  iTallaAv : Integer;
begin
  Result        := False;
  ATallaCaption := '';
  APedido       := 0;
  ARecibida     := 0;
  if not (FActivo and FExpandido and PuedeExpandir) then Exit;
  if FCfg.Grid = nil then Exit;
  rec := FCfg.Grid.Controller.FocusedRecord;
  col := FCfg.Grid.Controller.FocusedColumn;
  if (rec = nil) or (col = nil) then Exit;
  // Solo celdas talla (Tag positivo).
  if (col.Tag < 1) or (col.Tag > FCfg.MaxColumnasTallas) then Exit;
  if (col.Tag - 1 >= Length(FCfg.ColumnasTallas)) or
     (col <> FCfg.ColumnasTallas[col.Tag - 1]) then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := rec.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLinea := StrToIntDef(VarToStr(vLin), 0);
  if iLinea <= 0 then Exit;
  if not FPivotIdAc.TryGetValue(iLinea, iAc) then Exit;
  if iAc <= 0 then Exit;
  arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
  if col.Tag > Length(arr) then Exit;
  iTallaAv      := arr[col.Tag - 1].IdAv;
  ATallaCaption := arr[col.Tag - 1].Valor;
  iKey          := Int64(iLinea) * 100000 + iTallaAv;
  FPivotCantidades.TryGetValue(iKey, APedido);
  FPivotCantidadesRecibidas.TryGetValue(iKey, ARecibida);
  Result := True;
end;

function TGridPivoteCompra.RecibirFilaEntera: Integer;
var
  rec      : TcxCustomGridRecord;
  colLinea : TcxGridColumn;
  vLin     : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  i        : Integer;
  iKey     : Int64;
  rPed     : Double;
  rRec     : Double;
  rPdte    : Double;
  recIdx   : Integer;
  colTalla : TcxGridDBColumn;
begin
  Result := 0;
  if not (FActivo and FExpandido and PuedeExpandir) then Exit;
  if FCfg.Grid = nil then Exit;
  rec := FCfg.Grid.Controller.FocusedRecord;
  if rec = nil then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := rec.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLinea := StrToIntDef(VarToStr(vLin), 0);
  if iLinea <= 0 then Exit;
  if not FPivotIdAc.TryGetValue(iLinea, iAc) then Exit;
  if iAc <= 0 then Exit;
  arr    := FCfg.Gestor.GetPosicionesConjunto(iAc);
  recIdx := rec.RecordIndex;
  FCfg.Grid.DataController.BeginUpdate;
  try
    for i := 0 to High(arr) do
    begin
      if i >= FCfg.MaxColumnasTallas then Break;
      if (i >= Length(FCfg.ColumnasTallas)) or
         (FCfg.ColumnasTallas[i] = nil) then Continue;
      colTalla := FCfg.ColumnasTallas[i];
      iKey  := Int64(iLinea) * 100000 + arr[i].IdAv;
      rPed  := 0;
      rRec  := 0;
      FPivotCantidades.TryGetValue(iKey, rPed);
      FPivotCantidadesRecibidas.TryGetValue(iKey, rRec);
      rPdte := rPed - rRec;
      if rPdte <= 0 then Continue;
      FCfg.Grid.DataController.Values[recIdx, colTalla.Index] := rPdte;
      FARecibirManual.AddOrSetValue(iKey, rPdte);
      Inc(Result);
    end;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
end;

// Recorre todas las filas del grid (lineas representantes filtradas del
// pivote) y, para cada celda talla del conjunto con pendiente positivo,
// vuelca dicho pendiente en 'A recibir' (Values[] del grid para el
// repintado + FARecibirManual para la persistencia y el posterior
// IterarARecibirPorAlmacen). Misma logica que RecibirFilaEntera pero
// resolviendo la linea desde Values[] en vez del record focused.
function TGridPivoteCompra.RecibirTodo: Integer;
var
  colLinea : TcxGridColumn;
  vLin     : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  i        : Integer;
  iKey     : Int64;
  rPed     : Double;
  rRec     : Double;
  rPdte    : Double;
  recIdx   : Integer;
  colTalla : TcxGridDBColumn;
begin
  Result := 0;
  if not (FActivo and FExpandido and PuedeExpandir) then
    Exit;
  if FCfg.Grid = nil then
    Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then
    Exit;
  FCfg.Grid.DataController.BeginUpdate;
  try
    for recIdx := 0 to FCfg.Grid.DataController.RecordCount - 1 do
    begin
      vLin   := FCfg.Grid.DataController.Values[recIdx, colLinea.Index];
      iLinea := 0;
      if not (VarIsNull(vLin) or VarIsEmpty(vLin)) then
        iLinea := StrToIntDef(VarToStr(vLin), 0);
      iAc := 0;
      if iLinea > 0 then
        FPivotIdAc.TryGetValue(iLinea, iAc);
      if iAc > 0 then
      begin
        arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
        for i := 0 to High(arr) do
          if (i < FCfg.MaxColumnasTallas) and
             (i < Length(FCfg.ColumnasTallas)) and
             (FCfg.ColumnasTallas[i] <> nil) then
          begin
            colTalla := FCfg.ColumnasTallas[i];
            iKey := Int64(iLinea) * 100000 + arr[i].IdAv;
            rPed := 0;
            rRec := 0;
            FPivotCantidades.TryGetValue(iKey, rPed);
            FPivotCantidadesRecibidas.TryGetValue(iKey, rRec);
            rPdte := rPed - rRec;
            if rPdte > 0 then
            begin
              FCfg.Grid.DataController.Values[recIdx, colTalla.Index] := rPdte;
              FARecibirManual.AddOrSetValue(iKey, rPdte);
              Inc(Result);
            end;
          end;
      end;
    end;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
end;

procedure TGridPivoteCompra.PersistirCantidadEditValueChanged(
  ASender: TObject; AValorEditado: Variant);
var
  ed          : TcxCustomEdit;
  rec         : TcxCustomGridRecord;
  col         : TcxGridColumn;
  colLinea    : TcxGridColumn;
  vLin        : Variant;
  vEdit       : Variant;
  iLineaRepr  : Integer;
  iAc         : Integer;
  iTallaAv    : Integer;
  iKey        : Int64;
  arr         : TArrPosConjunto;
  sLineaReal  : string;
  sLineaFoco  : string;
  rCantidad   : Double;
  rPrecio     : Double;
  bFiltro     : Boolean;
  bCambiado   : Boolean;
begin
  if FActualizandoGrid or FGuardandoCantidad then
    Exit;
  if FExpandido then
  begin
    CapturarARecibirEditValueChanged(ASender);
    Exit;
  end;
  if not FActivo then Exit;
  if not (ASender is TcxCustomEdit) then Exit;
  if FCfg.Grid = nil then Exit;
  if FCfg.Gestor = nil then Exit;
  if FCfg.SourceLineas = nil then Exit;
  if not FCfg.SourceLineas.Active then Exit;
  FGuardandoCantidad := True;
  try
    ed := TcxCustomEdit(ASender);
    rec := FCfg.Grid.Controller.FocusedRecord;
    col := FCfg.Grid.Controller.FocusedColumn;
    if (rec = nil) or (col = nil) then Exit;
    if (col.Tag < 1) or (col.Tag > FCfg.MaxColumnasTallas) then Exit;
    if (col.Tag - 1 >= Length(FCfg.ColumnasTallas)) or
       (col <> FCfg.ColumnasTallas[col.Tag - 1]) then Exit;
    colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    if colLinea = nil then Exit;
    vLin := rec.Values[colLinea.Index];
    if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
    sLineaFoco := VarToStr(vLin);
    iLineaRepr := StrToIntDef(sLineaFoco, 0);
    if iLineaRepr <= 0 then Exit;
    if not FPivotIdAc.TryGetValue(iLineaRepr, iAc) then Exit;
    if iAc <= 0 then Exit;
    arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
    if col.Tag > Length(arr) then Exit;
    iTallaAv := arr[col.Tag - 1].IdAv;
    iKey := Int64(iLineaRepr) * 100000 + iTallaAv;
    if not FCeldaLineaPedido.TryGetValue(iKey, sLineaReal) then
    begin
      LogSes(Format(
        'PivoteCompra.PersistirCantidad: sin linea real repr=%d tallaAv=%d',
        [iLineaRepr, iTallaAv]));
      Exit;
    end;
    vEdit := AValorEditado;
    if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
      vEdit := ed.EditingValue;
    if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
      vEdit := ed.EditValue;
    if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
      vEdit := FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index];
    if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
      rCantidad := 0
    else if VarIsNumeric(vEdit) then
      rCantidad := vEdit
    else
      rCantidad := StrToFloatDef(VarToStr(vEdit), 0);
    FPivotCantidades.AddOrSetValue(iKey, rCantidad);
    bFiltro := FCfg.SourceLineas.Filtered;
    LogSes(Format(
      'PivoteCompra.PersistirCantidad: repr=%s linea=%s tallaAv=%d cantidad=%g',
      [sLineaFoco, sLineaReal, iTallaAv, rCantidad]));
    FCfg.SourceLineas.DisableControls;
    try
      if bFiltro then
        FCfg.SourceLineas.Filtered := False;
      if FCfg.SourceLineas.Locate(FCfg.FieldLinea, sLineaReal, []) then
      begin
        bCambiado := Abs(FCfg.SourceLineas.
          FieldByName(FCfg.FieldCantidad).AsFloat - rCantidad) > 0.000001;
        if bCambiado then
        begin
          if not (FCfg.SourceLineas.State in [dsEdit, dsInsert]) then
            FCfg.SourceLineas.Edit;
          FCfg.SourceLineas.FieldByName(FCfg.FieldCantidad).AsFloat :=
            rCantidad;
          if FCfg.FieldTotalUds <> '' then
            FCfg.SourceLineas.FieldByName(FCfg.FieldTotalUds).AsFloat :=
              rCantidad;
          if (FCfg.FieldPrecioBase <> '') and
             (FCfg.FieldTotalLinea <> '') then
          begin
            rPrecio := FCfg.SourceLineas.
              FieldByName(FCfg.FieldPrecioBase).AsFloat;
            FCfg.SourceLineas.FieldByName(FCfg.FieldTotalLinea).AsFloat :=
              rCantidad * rPrecio;
          end;
          FCfg.SourceLineas.Post;
        end
        else if FCfg.SourceLineas.State in dsEditModes then
        begin
          FCfg.SourceLineas.Post;
        end;
      end;
    finally
      if bFiltro then
        FCfg.SourceLineas.Filtered := True;
      if sLineaFoco <> '' then
        FCfg.SourceLineas.Locate(FCfg.FieldLinea, sLineaFoco, []);
      FCfg.SourceLineas.EnableControls;
    end;
  finally
    FGuardandoCantidad := False;
  end;
  PublicarCantidadesPivot;
end;

procedure TGridPivoteCompra.CapturarCantidadEditValueChanged(
                                                       ASender: TObject);
var
  ed         : TcxCustomEdit;
  rec        : TcxCustomGridRecord;
  col        : TcxGridColumn;
  colLinea   : TcxGridColumn;
  vLin       : Variant;
  vEdit      : Variant;
  iLineaRepr : Integer;
  iAc        : Integer;
  iTallaAv   : Integer;
  iKey       : Int64;
  arr        : TArrPosConjunto;
  rCantidad  : Double;
begin
  if FActualizandoGrid or FGuardandoCantidad then
    Exit;
  if not FActivo then Exit;
  if FExpandido then
  begin
    CapturarARecibirEditValueChanged(ASender);
    Exit;
  end;
  if not (ASender is TcxCustomEdit) then Exit;
  if FCfg.Grid = nil then Exit;
  if FCfg.Gestor = nil then Exit;
  ed := TcxCustomEdit(ASender);
  rec := FCfg.Grid.Controller.FocusedRecord;
  col := FCfg.Grid.Controller.FocusedColumn;
  if (rec = nil) or (col = nil) then Exit;
  if (col.Tag < 1) or (col.Tag > FCfg.MaxColumnasTallas) then Exit;
  if (col.Tag - 1 >= Length(FCfg.ColumnasTallas)) or
     (col <> FCfg.ColumnasTallas[col.Tag - 1]) then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := rec.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLineaRepr := StrToIntDef(VarToStr(vLin), 0);
  if iLineaRepr <= 0 then Exit;
  if not FPivotIdAc.TryGetValue(iLineaRepr, iAc) then Exit;
  if iAc <= 0 then Exit;
  arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
  if col.Tag > Length(arr) then Exit;
  iTallaAv := arr[col.Tag - 1].IdAv;
  iKey := Int64(iLineaRepr) * 100000 + iTallaAv;
  vEdit := ed.EditingValue;
  if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
    vEdit := ed.EditValue;
  if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
    vEdit := FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index];
  if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
    rCantidad := 0
  else if VarIsNumeric(vEdit) then
    rCantidad := vEdit
  else
    rCantidad := StrToFloatDef(VarToStr(vEdit), 0);
  FCantidadesPendientes.AddOrSetValue(iKey, rCantidad);
  FPivotCantidades.AddOrSetValue(iKey, rCantidad);
  LogSes(Format(
    'PivoteCompra.CapturarCantidad: repr=%d tallaAv=%d cantidad=%g',
    [iLineaRepr, iTallaAv, rCantidad]));
  FActualizandoGrid := True;
  try
    FCfg.Grid.DataController.BeginUpdate;
    try
      if rCantidad <> 0 then
        FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index] :=
          rCantidad
      else
        FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index] :=
          Null;
    finally
      FCfg.Grid.DataController.EndUpdate;
    end;
  finally
    FActualizandoGrid := False;
  end;
  PublicarCantidadesPivot;
end;

procedure TGridPivoteCompra.CapturarEditorActivo;
var
  ed: TcxCustomEdit;
begin
  if FCfg.Grid = nil then
    Exit;
  if FCfg.Grid.Controller.EditingController = nil then
    Exit;
  if not FCfg.Grid.Controller.EditingController.IsEditing then
    Exit;
  ed := FCfg.Grid.Controller.EditingController.Edit;
  if ed = nil then
    Exit;
  if FExpandido then
    CapturarARecibirEditValueChanged(ed)
  else
    CapturarCantidadEditValueChanged(ed);
  // Acepta el editor activo para que Grabar no dependa de cambiar de celda.
  try
    FCfg.Grid.Controller.EditingController.HideEdit(True);
  except
    on E: EInvalidOperation do
      // Ruido del editor inplace al aceptar el valor.
      if inLibLog.Log() <> nil then
        inLibLog.Log.LogWarning(
          'GridPivoteCompra.CapturarEditorActivo: HideEdit ' +
          'ignorado: ' + E.Message);
  end;
end;

procedure TGridPivoteCompra.CapturarValoresVisibles;
var
  colLinea   : TcxGridColumn;
  colTalla   : TcxGridDBColumn;
  recIdx     : Integer;
  i          : Integer;
  iLineaRepr : Integer;
  iAc        : Integer;
  iKey       : Int64;
  arr        : TArrPosConjunto;
  vLin       : Variant;
  vEdit      : Variant;
  rCantidad  : Double;
begin
  if FCfg.Grid = nil then Exit;
  if FCfg.Gestor = nil then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  for recIdx := 0 to FCfg.Grid.DataController.RecordCount - 1 do
  begin
    vLin := FCfg.Grid.DataController.Values[recIdx, colLinea.Index];
    if VarIsNull(vLin) or VarIsEmpty(vLin) or VarIsClear(vLin) then
      Continue;
    iLineaRepr := StrToIntDef(VarToStr(vLin), 0);
    if iLineaRepr <= 0 then Continue;
    if not FPivotIdAc.TryGetValue(iLineaRepr, iAc) then Continue;
    if EsLineaSinTalla(iLineaRepr) then
    begin
      if (Length(FCfg.ColumnasTallas) > 0) and
         (FCfg.ColumnasTallas[0] <> nil) then
      begin
        iKey := Int64(iLineaRepr) * 100000 + ID_AV_SIN_TALLA;
        if FCeldaLineaPedido.ContainsKey(iKey) then
        begin
          vEdit := FCfg.Grid.DataController.Values[recIdx,
                                  FCfg.ColumnasTallas[0].Index];
          if not (VarIsNull(vEdit) or VarIsEmpty(vEdit) or
                  VarIsClear(vEdit)) then
          begin
            if VarIsNumeric(vEdit) then
              rCantidad := vEdit
            else
              rCantidad := StrToFloatDef(VarToStr(vEdit), 0);
            FCantidadesPendientes.AddOrSetValue(iKey, rCantidad);
          end;
        end;
      end;
      Continue;
    end;
    if iAc <= 0 then Continue;
    arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
    for i := 0 to High(arr) do
    begin
      if i >= FCfg.MaxColumnasTallas then Break;
      if (i >= Length(FCfg.ColumnasTallas)) or
         (FCfg.ColumnasTallas[i] = nil) then Continue;
      colTalla := FCfg.ColumnasTallas[i];
      iKey := Int64(iLineaRepr) * 100000 + arr[i].IdAv;
      vEdit := FCfg.Grid.DataController.Values[recIdx, colTalla.Index];
      if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
        Continue;
      if VarIsNumeric(vEdit) then
        rCantidad := vEdit
      else
        rCantidad := StrToFloatDef(VarToStr(vEdit), 0);
      FCantidadesPendientes.AddOrSetValue(iKey, rCantidad);
    end;
  end;
end;

function TGridPivoteCompra.CampoLineaCopiable(
                                                   const ANombre: string): Boolean;
var
  sNombre: string;
begin
  sNombre := UpperCase(Trim(ANombre));
  Result := sNombre <> '';
  if Result then
    Result := not SameText(ANombre, FCfg.FieldSerieLin);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldNumeroLin);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldLinea);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldCantidad);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldTotalUds);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldTotalLinea);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldCantidadRecibida);
  if Result then
    Result := sNombre <> 'INSTANTE_ALTA';
  if Result then
    Result := sNombre <> 'INSTANTE_MODIF';
  if Result then
    Result := sNombre <> 'USUARIO_ALTA';
  if Result then
    Result := sNombre <> 'USUARIO_MODIF';
  if Result then
    Result := Pos('_PEDC_ALBCLIN', sNombre) = 0;
  if Result then
    Result := Pos('_FAC_ALBCLIN', sNombre) = 0;
  if Result then
    Result := sNombre <> 'ESFACTURADA_ALBCLIN';
end;

function TGridPivoteCompra.PrefijoSkuTalla(const ASku: string): string;
var
  iPos: Integer;
begin
  Result := '';
  iPos := LastDelimiter('/', ASku);
  if iPos > 1 then
    Result := Copy(ASku, 1, iPos - 1);
end;

function TGridPivoteCompra.ResolverSkuCelda(AKey: Int64;
                                            out ASku: string): Boolean;
var
  q          : TUniQuery;
  iLineaRepr : Integer;
  iTallaAv   : Integer;
  iColorAv   : Integer;
  sArt       : string;
  sPrefijo   : string;
  sTalla     : string;
  sVarSku    : string;
begin
  Result := False;
  ASku := '';
  if FCeldaSku.TryGetValue(AKey, ASku) then
    Result := Trim(ASku) <> '';
  if Result then
    Exit;
  if FCfg.Conexion = nil then
    Exit;
  iLineaRepr := Integer(AKey div 100000);
  iTallaAv := Integer(AKey mod 100000);
  if iTallaAv <= 0 then
    Exit;
  if not FPivotArticulo.TryGetValue(iLineaRepr, sArt) then
    Exit;
  if not FPivotColorAv.TryGetValue(iLineaRepr, iColorAv) then
    iColorAv := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    if iColorAv > 0 then
      q.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :talla) ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :color) ' +
        ' LIMIT 1'
    else
      q.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :talla) ' +
        ' LIMIT 1';
    q.ParamByName('art').AsString := sArt;
    q.ParamByName('talla').AsInteger := iTallaAv;
    if iColorAv > 0 then
      q.ParamByName('color').AsInteger := iColorAv;
    q.Open;
    if not q.Eof then
      ASku := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    Result := Trim(ASku) <> '';
    if Result then
      Exit;
    q.Close;
    sPrefijo := '';
    FPivotSkuPrefijo.TryGetValue(iLineaRepr, sPrefijo);
    if sPrefijo = '' then
      sPrefijo := sArt;
    q.SQL.Text :=
      'SELECT AV ' +
      '  FROM fza_atributos_valores ' +
      ' WHERE ID_AV = :talla ' +
      ' LIMIT 1';
    q.ParamByName('talla').AsInteger := iTallaAv;
    q.Open;
    if not q.Eof then
      sTalla := q.FieldByName('AV').AsString
    else
      sTalla := '';
    q.Close;
    if Trim(sTalla) = '' then
      Exit;
    ASku := sPrefijo + '/' + sTalla;
    sVarSku := '';
    FPivotVarSku.TryGetValue(iLineaRepr, sVarSku);
    if sVarSku = '' then
      sVarSku := 'TC';
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:sku, :art, :varsku, ''S'', NOW(), :u, NOW(), :u)';
    q.ParamByName('sku').AsString := ASku;
    q.ParamByName('art').AsString := sArt;
    q.ParamByName('varsku').AsString := sVarSku;
    q.ParamByName('u').AsString :=
      FCfg.ContextoSesion.Identidad.Usuario;
    q.ExecSQL;
    if iColorAv > 0 then
    begin
      q.SQL.Text :=
        'INSERT IGNORE INTO fza_atributos_sku ' +
        '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
        '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
      q.ParamByName('sku').AsString := ASku;
      q.ParamByName('av').AsInteger := iColorAv;
      q.ParamByName('u').AsString :=
        FCfg.ContextoSesion.Identidad.Usuario;
      q.ExecSQL;
    end;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_sku ' +
      '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
      '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
    q.ParamByName('sku').AsString := ASku;
    q.ParamByName('av').AsInteger := iTallaAv;
    q.ParamByName('u').AsString :=
      FCfg.ContextoSesion.Identidad.Usuario;
    q.ExecSQL;
    Result := Trim(ASku) <> '';
    if (Result) and (inLibLog.Log() <> nil) then
      inLibLog.Log.LogInfo(Format(
        'PivoteCompra.ResolverSku: creado/asegurado sku=%s',
        [ASku]));
  finally
    FreeAndNil(q);
  end;
end;

function TGridPivoteCompra.CrearLineaRealDesdeCelda(AKey: Int64;
                ACantidad: Double; out ALineaReal: string): Boolean;
var
  valores     : TDictionary<string,Variant>;
  parValor    : TPair<string,Variant>;
  campo       : TField;
  i           : Integer;
  iLineaRepr  : Integer;
  iAc         : Integer;
  sLineaBase  : string;
  sSku        : string;
  sArt        : string;
  sAlm        : string;
  rPrecio     : Double;
  procedure PonerStringCampo(const ACampo, AValor: string);
  var
    oCampo: TField;
  begin
    oCampo := FCfg.SourceLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsString := AValor;
  end;
  procedure PonerFloatCampo(const ACampo: string; AValor: Double);
  var
    oCampo: TField;
  begin
    oCampo := FCfg.SourceLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsFloat := AValor;
  end;
  procedure PonerIntegerCampo(const ACampo: string; AValor: Integer);
  var
    oCampo: TField;
  begin
    oCampo := FCfg.SourceLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsInteger := AValor;
  end;
begin
  Result := False;
  ALineaReal := '';
  if ACantidad <= 0 then
    Exit;
  if FCfg.SourceLineas = nil then
    Exit;
  if not FCfg.SourceLineas.Active then
    Exit;
  iLineaRepr := Integer(AKey div 100000);
  sLineaBase := Format('%.4d', [iLineaRepr]);
  if not ResolverSkuCelda(AKey, sSku) then
  begin
    if inLibLog.Log() <> nil then
      inLibLog.Log.LogInfo(Format(
        'PivoteCompra.CrearLinea: sin SKU key=%d', [AKey]));
    Exit;
  end;
  if not FPivotArticulo.TryGetValue(iLineaRepr, sArt) then
    sArt := '';
  if not FPivotIdAc.TryGetValue(iLineaRepr, iAc) then
    iAc := 0;
  if not FPivotAlmacen.TryGetValue(iLineaRepr, sAlm) then
    sAlm := '';
  if not FCfg.SourceLineas.Locate(FCfg.FieldLinea, sLineaBase, []) then
  begin
    if inLibLog.Log() <> nil then
      inLibLog.Log.LogInfo(Format(
        'PivoteCompra.CrearLinea: sin linea base=%s', [sLineaBase]));
    Exit;
  end;
  valores := TDictionary<string,Variant>.Create;
  try
    for i := 0 to FCfg.SourceLineas.Fields.Count - 1 do
    begin
      campo := FCfg.SourceLineas.Fields[i];
      if (campo.FieldKind = fkData) and CampoLineaCopiable(campo.FieldName) then
        valores.Add(campo.FieldName, campo.Value);
    end;
    FCfg.SourceLineas.Append;
    try
      for parValor in valores do
      begin
        campo := FCfg.SourceLineas.FindField(parValor.Key);
        if (campo <> nil) and (campo.FieldKind = fkData) and
           (not campo.ReadOnly) then
          campo.Value := parValor.Value;
      end;
      if sArt <> '' then
        PonerStringCampo(FCfg.FieldArt, sArt);
      PonerStringCampo(FCfg.FieldSku, sSku);
      PonerFloatCampo(FCfg.FieldCantidad, ACantidad);
      PonerFloatCampo(FCfg.FieldTotalUds, ACantidad);
      PonerFloatCampo(FCfg.FieldCantidadRecibida, 0);
      if iAc > 0 then
        PonerIntegerCampo(FCfg.FieldIdAcPivot, iAc);
      if sAlm <> '' then
        PonerStringCampo(FCfg.FieldAlmacen, sAlm)
      else
      begin
        campo := FCfg.SourceLineas.FindField(FCfg.FieldAlmacen);
        if campo <> nil then
          sAlm := campo.AsString;
      end;
      rPrecio := 0;
      campo := FCfg.SourceLineas.FindField(FCfg.FieldPrecioBase);
      if campo <> nil then
        rPrecio := campo.AsFloat;
      PonerFloatCampo(FCfg.FieldTotalLinea, ACantidad * rPrecio);
      FCfg.SourceLineas.Post;
      ALineaReal := FCfg.SourceLineas.FieldByName(FCfg.FieldLinea).AsString;
    except
      if FCfg.SourceLineas.State in dsEditModes then
        FCfg.SourceLineas.Cancel;
      raise;
    end;
    FCeldaSku.AddOrSetValue(AKey, sSku);
    FCeldaAlmacen.AddOrSetValue(AKey, sAlm);
    FCeldaLineaPedido.AddOrSetValue(AKey, ALineaReal);
    FPivotCantidades.AddOrSetValue(AKey, ACantidad);
    FPivotCantidadesRecibidas.AddOrSetValue(AKey, 0);
    if FPivotTotalPedido.ContainsKey(iLineaRepr) then
      FPivotTotalPedido[iLineaRepr] :=
        FPivotTotalPedido[iLineaRepr] + ACantidad
    else
      FPivotTotalPedido.Add(iLineaRepr, ACantidad);
    Result := ALineaReal <> '';
    if (Result) and (inLibLog.Log() <> nil) then
      inLibLog.Log.LogInfo(Format(
        'PivoteCompra.CrearLinea: key=%d linea=%s sku=%s cantidad=%g',
        [AKey, ALineaReal, sSku, ACantidad]));
  finally
    FreeAndNil(valores);
  end;
end;

function TGridPivoteCompra.PersistirCantidadesPendientes: Integer;
var
  par        : TPair<Int64,Double>;
  sLineaReal : string;
  sLineaFoco : string;
  rCantidad  : Double;
  rPrecio    : Double;
  bFiltro    : Boolean;
  bCambiado  : Boolean;
begin
  Result := 0;
  if inLibLog.Log() <> nil then
    inLibLog.Log.LogInfo('PivoteCompra.PersistirPendiente: INICIO');
  if FGuardandoCantidad then
    Exit;
  if not FActivo then Exit;
  if FExpandido then Exit;
  CapturarEditorActivo;
  CapturarValoresVisibles;
  if inLibLog.Log() <> nil then
    inLibLog.Log.LogInfo(Format(
      'PivoteCompra.PersistirPendiente: pendientes=%d',
      [FCantidadesPendientes.Count]));
  if FCantidadesPendientes.Count = 0 then
    Exit;
  if FCfg.SourceLineas = nil then Exit;
  if not FCfg.SourceLineas.Active then Exit;
  sLineaFoco := '';
  if (not FCfg.SourceLineas.IsEmpty) and
     (FCfg.SourceLineas.FindField(FCfg.FieldLinea) <> nil) then
    sLineaFoco := FCfg.SourceLineas.FieldByName(FCfg.FieldLinea).AsString;
  bFiltro := FCfg.SourceLineas.Filtered;
  FGuardandoCantidad := True;
  FCfg.SourceLineas.DisableControls;
  try
    if bFiltro then
      FCfg.SourceLineas.Filtered := False;
    for par in FCantidadesPendientes do
    begin
      rCantidad := par.Value;
      if not FCeldaLineaPedido.TryGetValue(par.Key, sLineaReal) then
      begin
        if CrearLineaRealDesdeCelda(par.Key, rCantidad, sLineaReal) then
          Inc(Result)
        else
          if inLibLog.Log() <> nil then
            inLibLog.Log.LogInfo(Format(
              'PivoteCompra.PersistirPendiente: sin linea real key=%d',
              [par.Key]));
        Continue;
      end;
      if inLibLog.Log() <> nil then
        inLibLog.Log.LogInfo(Format(
          'PivoteCompra.PersistirPendiente: linea=%s cantidad=%g',
          [sLineaReal, rCantidad]));
      FPivotCantidades.AddOrSetValue(par.Key, rCantidad);
      if FCfg.SourceLineas.Locate(FCfg.FieldLinea, sLineaReal, []) then
      begin
        bCambiado := Abs(FCfg.SourceLineas.
          FieldByName(FCfg.FieldCantidad).AsFloat - rCantidad) > 0.000001;
        if bCambiado then
        begin
          if not (FCfg.SourceLineas.State in [dsEdit, dsInsert]) then
            FCfg.SourceLineas.Edit;
          FCfg.SourceLineas.FieldByName(FCfg.FieldCantidad).AsFloat :=
            rCantidad;
          if FCfg.FieldTotalUds <> '' then
            FCfg.SourceLineas.FieldByName(FCfg.FieldTotalUds).AsFloat :=
              rCantidad;
          if (FCfg.FieldPrecioBase <> '') and
             (FCfg.FieldTotalLinea <> '') then
          begin
            rPrecio := FCfg.SourceLineas.
              FieldByName(FCfg.FieldPrecioBase).AsFloat;
            FCfg.SourceLineas.FieldByName(FCfg.FieldTotalLinea).AsFloat :=
              rCantidad * rPrecio;
          end;
          FCfg.SourceLineas.Post;
          Inc(Result);
        end
        else if FCfg.SourceLineas.State in dsEditModes then
        begin
          FCfg.SourceLineas.Post;
          Inc(Result);
        end;
      end
      else
        if inLibLog.Log() <> nil then
          inLibLog.Log.LogInfo(Format(
            'PivoteCompra.PersistirPendiente: no localizada linea=%s',
            [sLineaReal]));
    end;
    FCantidadesPendientes.Clear;
  finally
    if bFiltro then
      FCfg.SourceLineas.Filtered := True;
    if sLineaFoco <> '' then
      FCfg.SourceLineas.Locate(FCfg.FieldLinea, sLineaFoco, []);
    FCfg.SourceLineas.EnableControls;
    FGuardandoCantidad := False;
    if inLibLog.Log() <> nil then
      inLibLog.Log.LogInfo(Format(
        'PivoteCompra.PersistirPendiente: FIN guardadas=%d',
        [Result]));
  end;
end;

procedure TGridPivoteCompra.CapturarARecibirEditValueChanged(
                                                       ASender: TObject);
var
  ed       : TcxCustomEdit;
  rec      : TcxCustomGridRecord;
  col      : TcxGridColumn;
  colLinea : TcxGridColumn;
  vLin     : Variant;
  vEdit    : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  iKey     : Int64;
  iTallaAv : Integer;
  rValor   : Double;
  rPed     : Double;
  rRec     : Double;
  rPdte    : Double;
begin
  if FActualizandoGrid then
    Exit;
  if not (FActivo and FExpandido and PuedeExpandir) then Exit;
  if not (ASender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(ASender);
  ed.PostEditValue;
  if FCfg.Grid = nil then Exit;
  rec := FCfg.Grid.Controller.FocusedRecord;
  col := FCfg.Grid.Controller.FocusedColumn;
  if (rec = nil) or (col = nil) then Exit;
  if (col.Tag < 1) or (col.Tag > FCfg.MaxColumnasTallas) then Exit;
  if (col.Tag - 1 >= Length(FCfg.ColumnasTallas)) or
     (col <> FCfg.ColumnasTallas[col.Tag - 1]) then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := rec.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLinea := StrToIntDef(VarToStr(vLin), 0);
  if iLinea <= 0 then Exit;
  if not FPivotIdAc.TryGetValue(iLinea, iAc) then Exit;
  if iAc <= 0 then Exit;
  arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
  if col.Tag > Length(arr) then Exit;
  iTallaAv := arr[col.Tag - 1].IdAv;
  iKey     := Int64(iLinea) * 100000 + iTallaAv;
  vEdit := ed.EditingValue;
  if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
    vEdit := ed.EditValue;
  if VarIsNull(vEdit) or VarIsEmpty(vEdit) or VarIsClear(vEdit) then
    vEdit := FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index];
  if VarIsNull(vEdit) or VarIsEmpty(vEdit) then
    rValor := 0
  else if VarIsNumeric(vEdit) then
    rValor := vEdit
  else
    rValor := StrToFloatDef(VarToStr(vEdit), 0);
  rPed := 0;
  rRec := 0;
  FPivotCantidades.TryGetValue(iKey, rPed);
  FPivotCantidadesRecibidas.TryGetValue(iKey, rRec);
  rPdte := rPed - rRec;
  if rPdte < 0 then
    rPdte := 0;
  if rValor > rPdte then
  begin
    rValor := rPdte;
    MessageBeep(MB_ICONWARNING);
    FActualizandoGrid := True;
    try
      if rValor > 0 then
        ed.EditValue := rValor
      else
        ed.EditValue := Null;
      FCfg.Grid.DataController.BeginUpdate;
      try
        if rValor > 0 then
          FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index] := rValor
        else
          FCfg.Grid.DataController.Values[rec.RecordIndex, col.Index] := Null;
      finally
        FCfg.Grid.DataController.EndUpdate;
      end;
    finally
      FActualizandoGrid := False;
    end;
  end;
  if rValor <= 0 then
    FARecibirManual.Remove(iKey)
  else
    FARecibirManual.AddOrSetValue(iKey, rValor);
end;

function TGridPivoteCompra.PrimerAlmacenARecibir: string;
var
  pair : TPair<Int64,Double>;
  sAlm : string;
begin
  Result := '';
  if FARecibirManual = nil then Exit;
  for pair in FARecibirManual do
  begin
    if pair.Value <= 0 then Continue;
    if not FCeldaAlmacen.TryGetValue(pair.Key, sAlm) then Continue;
    if Trim(sAlm) = '' then Continue;
    Result := sAlm;
    Exit;
  end;
end;

function TGridPivoteCompra.TotalARecibir: Double;
var
  pair: TPair<Int64,Double>;
begin
  Result := 0;
  if FARecibirManual <> nil then
  begin
    for pair in FARecibirManual do
    begin
      if pair.Value > 0 then
        Result := Result + pair.Value;
    end;
  end;
end;

function TGridPivoteCompra.ColorCodigoLineaActiva: string;
var
  iLinea    : Integer;
  sLinea    : string;
begin
  Result := '';
  if GetLineaActiva(iLinea, sLinea) and (FPivotColorCodigo <> nil) then
    FPivotColorCodigo.TryGetValue(iLinea, Result);
end;

function TGridPivoteCompra.CambiarColorLineaActiva(
  const ACodigoAtbColor: string; out AMensaje: string): Boolean;
var
  q            : TUniQuery;
  ds           : TDataSet;
  Campo        : TField;
  bLineaActual : Boolean;
  iLinea       : Integer;
  iIdAv        : Integer;
  sLinea       : string;
  sLineaLocate : string;
  sLineaDs     : string;
  sArt         : string;
  sSkuColor    : string;
  sVarSku      : string;
  sValorAv     : string;
  sNombreColor : string;
  rTotal       : Double;
begin
  Result := False;
  AMensaje := '';
  rTotal := 0;
  if not FActivo then
    AMensaje := SErrorActivarTallasHorizontalesParaColor
  else if not GetLineaActiva(iLinea, sLinea) then
    AMensaje := SErrorLineaActivaColorNoDisponible
  else if FPivotTotalPedido.TryGetValue(iLinea, rTotal) and
          (Abs(rTotal) > 0.000001) then
    AMensaje := SErrorColorCompraConCantidades
  else if ResolverAvColorBasico(ACodigoAtbColor, iIdAv, sValorAv,
                                sNombreColor, AMensaje) then
  begin
    if (FCfg.SourceLineas = nil) or (not FCfg.SourceLineas.Active) then
      AMensaje := SErrorConsultaLineasCompraNoAbierta
    else
    begin
      ds := FCfg.SourceLineas;
      sLineaLocate := sLinea;
      if StrToIntDef(sLineaLocate, 0) > 0 then
        sLineaLocate := Format('%.4d', [StrToIntDef(sLineaLocate, 0)]);
      bLineaActual := False;
      if (not ds.IsEmpty) and (ds.FindField(FCfg.FieldLinea) <> nil) then
      begin
        sLineaDs := Trim(ds.FieldByName(FCfg.FieldLinea).AsString);
        if StrToIntDef(sLineaDs, 0) > 0 then
          sLineaDs := Format('%.4d', [StrToIntDef(sLineaDs, 0)]);
        bLineaActual := SameText(sLineaDs, sLineaLocate);
      end;
      if (not bLineaActual) and
         (not ds.Locate(FCfg.FieldLinea, sLineaLocate, [])) then
        AMensaje := SErrorLineaActivaColorNoEncontrada
      else
      begin
        sArt := Trim(ds.FieldByName(FCfg.FieldArt).AsString);
        if sArt = '' then
          AMensaje := SErrorLineaActivaCompraSinArticulo
        else
        begin
          sVarSku := '';
          FPivotVarSku.TryGetValue(iLinea, sVarSku);
          if sVarSku = '' then
          begin
            q := TUniQuery.Create(nil);
            try
              q.Connection := FCfg.Conexion;
              q.SQL.Text :=
                'SELECT COALESCE(NULLIF(TIPO_VARIACION_ART, ''''), ''TC'') ' +
                '       AS VARSKU ' +
                '  FROM fza_articulos ' +
                ' WHERE CODIGO_ART_ART = :art ' +
                ' LIMIT 1';
              q.ParamByName('art').AsString := sArt;
              q.Open;
              if not q.IsEmpty then
                sVarSku := q.FieldByName('VARSKU').AsString;
            finally
              FreeAndNil(q);
            end;
          end;
          if sVarSku = '' then
            sVarSku := 'TC';
          sSkuColor := sArt + '/' + sValorAv;
          q := TUniQuery.Create(nil);
          try
            q.Connection := FCfg.Conexion;
            q.SQL.Text :=
              'INSERT INTO fza_articulos_skus ' +
              '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
              '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
              '   INSTANTE_MODIF, USUARIO_MODIF) ' +
              'VALUES (:sku, :art, :varsku, ''S'', NOW(), :usuario, ' +
              '        NOW(), :usuario) ' +
              'ON DUPLICATE KEY UPDATE ESACTIVO_SKU = ''S'', ' +
              '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :usuario';
            q.ParamByName('sku').AsString := sSkuColor;
            q.ParamByName('art').AsString := sArt;
            q.ParamByName('varsku').AsString := sVarSku;
            q.ParamByName('usuario').AsString :=
              FCfg.ContextoSesion.Identidad.Usuario;
            q.Execute;
            q.SQL.Text :=
              'INSERT IGNORE INTO fza_atributos_sku ' +
              '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
              '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
              'VALUES (:sku, :av, NOW(), :usuario, NOW(), :usuario)';
            q.ParamByName('sku').AsString := sSkuColor;
            q.ParamByName('av').AsInteger := iIdAv;
            q.ParamByName('usuario').AsString :=
              FCfg.ContextoSesion.Identidad.Usuario;
            q.Execute;
          finally
            FreeAndNil(q);
          end;
          if not (ds.State in dsEditModes) then
            ds.Edit;
          ds.FieldByName(FCfg.FieldSku).AsString := sSkuColor;
          if FCfg.FieldColorTexto <> '' then
          begin
            Campo := ds.FindField(FCfg.FieldColorTexto);
            if Campo <> nil then
              Campo.AsString := sValorAv;
          end;
          ds.Post;
          FPivotColorCodigo.AddOrSetValue(iLinea, ACodigoAtbColor);
          FPivotColorTexto.AddOrSetValue(iLinea, sValorAv);
          FPivotColorAv.AddOrSetValue(iLinea, iIdAv);
          FPivotSkuBase.AddOrSetValue(iLinea, sSkuColor);
          FPivotSkuPrefijo.AddOrSetValue(iLinea, sSkuColor);
          FPivotVarSku.AddOrSetValue(iLinea, sVarSku);
          Result := True;
        end;
      end;
    end;
  end;
end;

procedure TGridPivoteCompra.CustomDrawColorCell(
            Sender: TcxCustomGridTableView;
            ACanvas: TcxCanvas;
            AViewInfo: TcxGridTableDataCellViewInfo;
            var ADone: Boolean);
var
  colLinea : TcxGridDBColumn;
  vLinea   : Variant;
  iLinea   : Integer;
  recIdx   : Integer;
  sCodigo  : string;
  sTexto   : string;
  sArticulo: string;
begin
  ADone := False;
  if FPivotColorCodigo = nil then Exit;
  if AViewInfo.GridRecord = nil then Exit;
  recIdx := AViewInfo.GridRecord.RecordIndex;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLinea := FCfg.Grid.DataController.Values[recIdx, colLinea.Index];
  if VarIsNull(vLinea) or VarIsEmpty(vLinea) then Exit;
  iLinea := StrToIntDef(VarToStr(vLinea), 0);
  if iLinea <= 0 then Exit;
  sCodigo := '';
  sTexto  := '';
  sArticulo := '';
  FPivotColorCodigo.TryGetValue(iLinea, sCodigo);
  FPivotColorTexto.TryGetValue(iLinea, sTexto);
  FPivotArticulo.TryGetValue(iLinea, sArticulo);
  if sTexto = '' then
    sTexto := sCodigo;
  if PintarCeldaSwatchArticuloSiAplica(
       FCfg.Conexion, ACanvas, AViewInfo, sArticulo, sTexto, nil) then
    ADone := True;
end;

end.
