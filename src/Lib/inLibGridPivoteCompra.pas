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
  System.SysUtils, System.Classes, System.Variants, System.UITypes,
  System.Generics.Collections, System.Types,
  Data.DB, DBAccess, Uni,
  Vcl.Controls, Vcl.Graphics,
  cxClasses, cxGraphics, cxControls, cxCustomData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inLibGridTallasInline,
  inLibAtributosPaleta;

type
  // Config inmutable que el form construye una vez y pasa al constructor.
  // Todos los nombres de campo y tabla son strings para no acoplar la lib
  // a un esquema concreto: vale para ALBC y para PEDC con los mismos
  // metodos cambiando solo la config.
  TGridPivoteCompraConfig = record
    Conexion             : TUniConnection;
    Grid                 : TcxGridDBTableView;
    SourceMaster         : TDataSource;
    SourceLineas         : TUniQuery;
    Gestor               : TGestorGridTallas;
    ColColorPivot        : TcxGridDBColumn;
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
    // Campo CANTIDAD_RECIBIDA por linea. Solo en pedidos; vacio para
    // albaranes (no tienen este concepto). Si esta vacio, el modo
    // "Expandir / recibidos" no aplica.
    FieldCantidadRecibida: string;
    FieldIdAcPivot       : string;   // ID_AC_PIVOT_ALBCLIN / _PEDCLIN
    FieldAlmacen         : string;   // CODIGO_ALMACEN_ALBCLIN / _PEDCLIN
    CamposOcultosEnPivote: TArray<string>;
  end;

  TEstadoFilaRecibida = (efrIndefinido, efrNada, efrParcial, efrTotal);

  TGridPivoteCompra = class
  private
    FCfg              : TGridPivoteCompraConfig;
    FActivo           : Boolean;
    FExpandido        : Boolean;
    FPivotLineasRepr  : TList<Integer>;
    FPivotCantidades  : TDictionary<Int64,Double>;
    FPivotCantidadesRecibidas: TDictionary<Int64,Double>;
    FPivotTotalPedido        : TDictionary<Integer,Double>;
    FPivotTotalRecibido      : TDictionary<Integer,Double>;
    FPivotColorTexto  : TDictionary<Integer,string>;
    FPivotColorCodigo : TDictionary<Integer,string>;
    FPivotIdAc        : TDictionary<Integer,Integer>;
    FPivotMaxAvTalla  : Integer;
    FOrigColIndexAlm  : Integer;
    FOrigColIndexCol  : Integer;
    FAlturaFilaOriginal : Integer;
    procedure FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    function  GetSerieNumeroActivos(out ASerie, ANumero: string): Boolean;
    function  GetEstadoFila(iLinea: Integer): TEstadoFilaRecibida;
    function  GetColorEstadoFila(AEstado: TEstadoFilaRecibida): TColor;
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
    // Doble alto + pinta recibidos en mitad inferior con color de estado.
    procedure Expandir;
    procedure Contraer;
    property Expandido: Boolean read FExpandido;
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
  private
    procedure CargarCachePivot;
    procedure PublicarCantidadesPivot;
    procedure AplicarVisibilidadColumnasPivot(AModoPivot: Boolean);
    procedure IntercambiarPosicionColorAlmacen(AModoPivot: Boolean);
  end;

const
  // Colores pastel para estados de recepcion (BGR).
  COL_REC_NADA    : TColor = $0099FFFF;  // amarillo
  COL_REC_PARCIAL : TColor = $0099FF99;  // verde
  COL_REC_TOTAL   : TColor = $00FFCC99;  // azul claro
  // Altura por defecto de fila expandida (px). Permite ver 2 numeros.
  ALTURA_FILA_EXPANDIDA = 42;

implementation

uses
  inLibGlobalVar;

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
  FPivotColorTexto         := TDictionary<Integer,string>.Create;
  FPivotColorCodigo        := TDictionary<Integer,string>.Create;
  FPivotIdAc               := TDictionary<Integer,Integer>.Create;
  FPivotMaxAvTalla         := 0;
  FOrigColIndexAlm         := -1;
  FOrigColIndexCol         := -1;
  FAlturaFilaOriginal      := 0;
end;

destructor TGridPivoteCompra.Destroy;
begin
  FreeAndNil(FPivotLineasRepr);
  FreeAndNil(FPivotCantidades);
  FreeAndNil(FPivotCantidadesRecibidas);
  FreeAndNil(FPivotTotalPedido);
  FreeAndNil(FPivotTotalRecibido);
  FreeAndNil(FPivotColorTexto);
  FreeAndNil(FPivotColorCodigo);
  FreeAndNil(FPivotIdAc);
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
    // 1. Articulos sin sistema de tallas asignado en la linea.
    q.SQL.Text :=
      'SELECT DISTINCT L.' + FCfg.FieldArt + ' AS ART ' +
      '  FROM ' + FCfg.TablaLineas + ' L ' +
      ' WHERE L.' + FCfg.FieldSerieLin  + ' = :SERIE ' +
      '   AND L.' + FCfg.FieldNumeroLin + ' = :NUMERO ' +
      '   AND (L.' + FCfg.FieldIdAcPivot + ' IS NULL ' +
      '        OR L.' + FCfg.FieldIdAcPivot + ' = 0) ' +
      ' ORDER BY ART';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add('- Articulo SIN sistema de tallas: ' +
                      q.FieldByName('ART').AsString);
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
      incidencias.Add(Format(
        '- Articulo %s: sistema "%s" con %d tallas (maximo %d).',
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
      incidencias.Add(Format(
        '- SKU %s (art %s): talla "%s" fuera del sistema asignado.',
        [q.FieldByName('SKU').AsString,
         q.FieldByName('ART').AsString,
         q.FieldByName('TALLA').AsString]));
      q.Next;
    end;
    q.Close;
    if incidencias.Count > 0 then
    begin
      AMensaje := 'No se puede activar el modo pivote por tallas:' +
                  sLineBreak + sLineBreak +
                  incidencias.Text + sLineBreak +
                  'Se mantiene la vista plana (linea por SKU).';
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
  FPivotColorTexto.Clear;
  FPivotColorCodigo.Clear;
  FPivotIdAc.Clear;
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

// Activa el modo expandido: duplica la altura de fila y deja que
// CustomDrawCellTalla pinte pedido en mitad superior + recibida en
// mitad inferior con color de estado. Idempotente.
procedure TGridPivoteCompra.Expandir;
begin
  if (not FActivo) or (not PuedeExpandir) or FExpandido then Exit;
  if FCfg.Grid = nil then Exit;
  FAlturaFilaOriginal := FCfg.Grid.OptionsView.DataRowHeight;
  // Cambiar DataRowHeight dispara la actualizacion del layout del cxGrid
  // automaticamente: las filas pasan a tener la nueva altura y se
  // repintan invocando OnCustomDrawCell.
  FCfg.Grid.OptionsView.DataRowHeight := ALTURA_FILA_EXPANDIDA;
  FExpandido := True;
end;

procedure TGridPivoteCompra.Contraer;
begin
  if not FExpandido then Exit;
  if FCfg.Grid <> nil then
    FCfg.Grid.OptionsView.DataRowHeight := FAlturaFilaOriginal;
  FExpandido := False;
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
  iColorAv   : Integer;
  iTallaAv   : Integer;
  rCant      : Double;
  rRecibida  : Double;
  iLineaRepr : Integer;
  iKeyPivot  : Int64;
  sSelectRecibida: string;
  bTieneRecibida: Boolean;
begin
  FPivotLineasRepr.Clear;
  FPivotCantidades.Clear;
  FPivotCantidadesRecibidas.Clear;
  FPivotTotalPedido.Clear;
  FPivotTotalRecibido.Clear;
  FPivotColorTexto.Clear;
  FPivotColorCodigo.Clear;
  FPivotIdAc.Clear;
  FPivotMaxAvTalla := 0;
  if not GetSerieNumeroActivos(sSerie, sNumero) then Exit;
  bTieneRecibida := FCfg.FieldCantidadRecibida <> '';
  if bTieneRecibida then
    sSelectRecibida := ', IFNULL(L.' + FCfg.FieldCantidadRecibida + ', 0) AS RECIBIDA '
  else
    sSelectRecibida := ', 0 AS RECIBIDA ';
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
      '       COALESCE(ATBC.NOMBRE_ATB, AVC.AV, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.' + FCfg.FieldSku + ', ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_TXT, ' +
      '       COALESCE(ATBC.CODIGO_ATB, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.' + FCfg.FieldSku + ', ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_COD, ' +
      '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
      '       L.' + FCfg.FieldCantidad + ' AS CANTIDAD ' +
      sSelectRecibida +
      '  FROM ' + FCfg.TablaLineas + ' L ' +
      '  LEFT JOIN fza_atributos_sku SAC ' +
      '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.' + FCfg.FieldSku + ' ' +
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
      iColorAv  := q.FieldByName('COLOR_AV').AsInteger;
      iTallaAv  := q.FieldByName('TALLA_AV').AsInteger;
      rCant     := q.FieldByName('CANTIDAD').AsFloat;
      rRecibida := q.FieldByName('RECIBIDA').AsFloat;
      sKey := sArt + '|' + IntToStr(iColorAv);
      if not dictRepr.TryGetValue(sKey, iLineaRepr) then
      begin
        iLineaRepr := iLinea;
        dictRepr.Add(sKey, iLineaRepr);
        FPivotLineasRepr.Add(iLineaRepr);
        FPivotColorTexto.AddOrSetValue(iLineaRepr,
                                       q.FieldByName('COLOR_TXT').AsString);
        FPivotColorCodigo.AddOrSetValue(iLineaRepr,
                                        q.FieldByName('COLOR_COD').AsString);
        FPivotIdAc.AddOrSetValue(iLineaRepr,
                                 q.FieldByName('ID_AC').AsInteger);
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
        if iTallaAv > FPivotMaxAvTalla then FPivotMaxAvTalla := iTallaAv;
      end;
      q.Next;
    end;
    q.Close;
  finally
    FreeAndNil(q);
    FreeAndNil(dictRepr);
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
      if iAc <= 0 then Continue;
      if Assigned(FCfg.ColColorPivot) and Assigned(FPivotColorTexto) then
      begin
        if FPivotColorTexto.ContainsKey(iLinea) then
          FCfg.Grid.DataController.Values[recIdx,
                                FCfg.ColColorPivot.Index] := FPivotColorTexto[iLinea];
      end;
      arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
      for i := 0 to High(arr) do
      begin
        if i >= FCfg.MaxColumnasTallas then Break;
        if (i >= Length(FCfg.ColumnasTallas)) or
           (FCfg.ColumnasTallas[i] = nil) then Continue;
        iKey := Int64(iLinea) * 100000 + arr[i].IdAv;
        if FPivotCantidades.TryGetValue(iKey, rCant) and (rCant <> 0) then
          FCfg.Grid.DataController.Values[recIdx,
                                FCfg.ColumnasTallas[i].Index] := rCant;
      end;
    end;
  finally
    FCfg.Grid.DataController.EndUpdate;
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
  IntercambiarPosicionColorAlmacen(AModoPivot);
end;

procedure TGridPivoteCompra.IntercambiarPosicionColorAlmacen(
                                                       AModoPivot: Boolean);
var
  colAlm : TcxGridDBColumn;
  iTmp   : Integer;
begin
  if not Assigned(FCfg.ColColorPivot) then Exit;
  if FCfg.FieldAlmacen = '' then Exit;
  colAlm := FCfg.Grid.GetColumnByFieldName(FCfg.FieldAlmacen);
  if colAlm = nil then Exit;
  if AModoPivot then
  begin
    if FOrigColIndexAlm < 0 then FOrigColIndexAlm := colAlm.Index;
    if FOrigColIndexCol < 0 then FOrigColIndexCol := FCfg.ColColorPivot.Index;
    iTmp := colAlm.Index;
    colAlm.Index := FCfg.ColColorPivot.Index;
    FCfg.ColColorPivot.Index := iTmp;
  end
  else
  begin
    if FOrigColIndexAlm >= 0 then colAlm.Index := FOrigColIndexAlm;
    if FOrigColIndexCol >= 0 then FCfg.ColColorPivot.Index := FOrigColIndexCol;
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
  colAc     : TcxGridColumn;
  colLinea  : TcxGridColumn;
  vAc, vLin : Variant;
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
  sPedido   : string;
  sRecibida : string;
  rectTop, rectBot : TRect;
  iMid : Integer;
begin
  if (not FActivo) or (FCfg.Gestor = nil) then Exit;
  if AViewInfo.GridRecord = nil then Exit;
  if not (AViewInfo.Item is TcxGridColumn) then Exit;
  Col := TcxGridColumn(AViewInfo.Item);
  bEsTalla := (Col.Tag >= 1) and (Col.Tag <= FCfg.MaxColumnasTallas) and
              (Col.Tag - 1 < Length(FCfg.ColumnasTallas)) and
              (Col = FCfg.ColumnasTallas[Col.Tag - 1]);

  // 1. GRAY-OUT de celdas talla fuera del conjunto pivot (no depende de
  //    modo expandido).
  if bEsTalla then
  begin
    colAc := FCfg.Grid.GetColumnByFieldName(FCfg.FieldIdAcPivot);
    if colAc <> nil then
    begin
      vAc := AViewInfo.GridRecord.Values[colAc.Index];
      if (not VarIsNull(vAc)) and (not VarIsEmpty(vAc)) and VarIsNumeric(vAc) then
      begin
        iAc := vAc;
        if iAc > 0 then
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
      end;
    end;
  end;

  // 2. Modo EXPANDIDO: fondo de fila con color de estado y pintado
  //    pedido / recibida en mitades para celdas talla.
  if not (FExpandido and PuedeExpandir) then Exit;
  // Resolver linea del record para consultar los totales.
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;
  vLin := AViewInfo.GridRecord.Values[colLinea.Index];
  if VarIsNull(vLin) or VarIsEmpty(vLin) then Exit;
  iLinea := StrToIntDef(VarToStr(vLin), 0);
  if iLinea <= 0 then Exit;
  estado    := GetEstadoFila(iLinea);
  if estado = efrIndefinido then Exit;
  ColorFila := GetColorEstadoFila(estado);
  // Respetar el highlight de seleccion: si el record esta seleccionado,
  // no sobreescribimos su color natural.
  if AViewInfo.GridRecord.Selected then Exit;
  if bEsTalla then
  begin
    // Para celdas talla validas: pintamos fondo + pedido (top) + recibida (bot).
    colAc := FCfg.Grid.GetColumnByFieldName(FCfg.FieldIdAcPivot);
    iAc   := 0;
    if colAc <> nil then
    begin
      vAc := AViewInfo.GridRecord.Values[colAc.Index];
      if (not VarIsNull(vAc)) and (not VarIsEmpty(vAc)) and VarIsNumeric(vAc) then
        iAc := vAc;
    end;
    if iAc <= 0 then Exit;
    arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
    if Col.Tag > Length(arr) then Exit;
    iTallaAv  := arr[Col.Tag - 1].IdAv;
    iKey      := Int64(iLinea) * 100000 + iTallaAv;
    rPedido   := 0;
    rRecibida := 0;
    FPivotCantidades.TryGetValue(iKey, rPedido);
    FPivotCantidadesRecibidas.TryGetValue(iKey, rRecibida);
    if rPedido <> 0 then
      sPedido := IntToStr(Round(rPedido))
    else
      sPedido := '';
    if rRecibida <> 0 then
      sRecibida := IntToStr(Round(rRecibida))
    else
      sRecibida := '';
    // Fondo color de estado
    ACanvas.Brush.Color := ColorFila;
    ACanvas.FillRect(AViewInfo.Bounds);
    // Texto pedido en mitad superior (negro normal)
    iMid    := (AViewInfo.Bounds.Top + AViewInfo.Bounds.Bottom) div 2;
    rectTop := Rect(AViewInfo.Bounds.Left, AViewInfo.Bounds.Top,
                    AViewInfo.Bounds.Right, iMid);
    rectBot := Rect(AViewInfo.Bounds.Left, iMid,
                    AViewInfo.Bounds.Right, AViewInfo.Bounds.Bottom);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color  := clBlack;
    ACanvas.Font.Style  := [];
    DrawText(ACanvas.Handle, PChar(sPedido), Length(sPedido), rectTop,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    // Texto recibida en mitad inferior (azul oscuro, italic)
    ACanvas.Font.Color := clNavy;
    ACanvas.Font.Style := [fsItalic];
    DrawText(ACanvas.Handle, PChar(sRecibida), Length(sRecibida), rectBot,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    ACanvas.Brush.Style := bsSolid;
    ADone := True;
  end
  else
  begin
    // Para celdas no-talla: pintamos solo el fondo con color de estado.
    // Dejamos ADone := False para que cxGrid dibuje el texto encima.
    ACanvas.Brush.Color := ColorFila;
    ACanvas.FillRect(AViewInfo.Bounds);
  end;
end;

procedure TGridPivoteCompra.EditingCeldaTalla(Sender: TcxCustomGridTableView;
                                               AItem: TcxCustomGridTableItem;
                                               var AAllow: Boolean);
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  if AItem = nil then Exit;
  if (AItem.Tag < 1) or (AItem.Tag > FCfg.MaxColumnasTallas) then Exit;
  if FCfg.Gestor = nil then Exit;
  if (FCfg.SourceLineas = nil) or FCfg.SourceLineas.IsEmpty then Exit;
  iAc := FCfg.SourceLineas.FieldByName(FCfg.FieldIdAcPivot).AsInteger;
  if iAc <= 0 then Exit;
  arr := FCfg.Gestor.GetPosicionesConjunto(iAc);
  if AItem.Tag > Length(arr) then
    AAllow := False;
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
  Info     : TInfoBasico;
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
  FPivotColorCodigo.TryGetValue(iLinea, sCodigo);
  FPivotColorTexto.TryGetValue(iLinea, sTexto);
  if (sCodigo = '') then Exit;
  Info := Default(TInfoBasico);
  if not ObtenerInfoBasico('CO', sCodigo, Info) then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info, sTexto) then
    ADone := True;
end;

end.
