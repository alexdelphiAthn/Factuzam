{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridTallasInline                                         }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       18/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Gestor reutilizable para grids cxGrid con tallas pivotadas inline. Los    }
{    clientes compran "en horizontal": una fila por articulo + N columnas de   }
{    cantidad por talla. Este patron aparece en todo el modulo de Compras      }
{    (Sesiones, Pedidos, Albaranes, Facturas) y esta libreria centraliza la    }
{    parte fragil para que cada Mto solo cuide su cabecera y sus campos        }
{    propios.                                                                  }
{                                                                              }
{    Lo que la libreria hace:                                                  }
{      - Cachea las posiciones (ID_AV, VALOR) de cada conjunto pivot.          }
{      - Calcula el numero maximo de columnas talla a mostrar a partir de los  }
{        sistemas referenciados por las lineas del documento.                  }
{      - Muestra / oculta columnas talla segun ese maximo                      }
{        (RecalcularMaxColumnas).                                              }
{      - Actualiza captions al sistema de la linea con foco                    }
{        (ActualizarCaptionsLineaActiva).                                      }
{      - Carga las cantidades desde la tabla de celdas a los Values[] de las   }
{        columnas no-bound del grid con DisableControls + bookmark             }
{        (CargarCantidadesTodasLineas / UnaLinea).                             }
{      - Persiste el cambio de una celda via UPSERT (DELETE si <= 0).          }
{      - Recalcula totales de la linea sumando la tabla de celdas              }
{        (RefrescarTotalesLinea).                                              }
{      - Valida que el sistema seleccionado no exceda Cfg.MaxColumnas y, si    }
{        lo excede, muestra mtError y limpia el campo                          }
{        (ValidarSistemaSeleccionado).                                         }
{                                                                              }
{    Lo que el Mto consumidor sigue cuidando:                                  }
{      - Cabecera y settings.                                                  }
{      - Crear las N columnas no-bound (Tag = 1..N) y pasarlas al gestor en    }
{        la inicializacion.                                                    }
{      - Handlers de F3/familia, color, PVP, etc.                              }
{      - Eventos del propio grid (OnFocusedRecordChanged, OnInitEdit,          }
{        OnEditKeyDown, OnCustomDrawCell, OnEditValueChanged).                 }
{                                                                              }
{    Parametrizacion via TGridTallasConfig: cada Mto carga su record con los   }
{    nombres de tabla / campos / sufijos especificos:                          }
{      Sesiones:   SESCEL / SESLIN / SES                                       }
{      Pedidos:    PEDCEL / PEDLIN / PED (cuando existan)                      }
{      Albaranes:  ALBCEL / ALBLIN / ALB (cuando existan)                      }
{      Facturas:   FACCEL / FACLIN / FAC (cuando existan)                      }
{                                                                              }
{    Documentacion: DESARROLLOS EN CURSO/pruebas_sesiones/pruebas_sesiones.md  }
{    seccion 12.                                                               }
{******************************************************************************}
unit inLibGridTallasInline;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.UITypes,
  Data.DB, DBAccess, Uni,
  cxControls, cxClasses, cxEdit, cxTextEdit, cxCurrencyEdit, cxCustomData,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  JvEnterTab;

type
  TPosConjunto = record
    IdAv  : Integer;
    Valor : string;
  end;
  TArrPosConjunto = TArray<TPosConjunto>;

  // Configuracion del gestor. Cada Mto consumidor rellena su instancia
  // con los nombres de tabla / campos especificos antes de crear el
  // gestor. Todos los nombres son SQL crudos (no constantes f*).
  TGridTallasConfig = record
    // -- objetos del form --
    Conexion         : TUniConnection;
    Usuario          : string;
    Grid             : TcxGridDBTableView;
    SourceMaster     : TDataSource;       // cabecera del documento
    SourceLineas     : TDataSource;       // detalle (line items)
    ColumnasTallas   : TArray<TcxGridDBColumn>;
                       // las N columnas no-bound creadas por el form;
                       // Tag = posicion 1..N en el conjunto

    // -- campos del master (cabecera) --
    FieldSerieMaster  : string;   // 'SERIE_SES'
    FieldNumeroMaster : string;   // 'NUMERO_SES'

    // -- campos del detail (lineas) --
    FieldLinea        : string;   // 'LINEA_SESLIN'
    FieldConjuntoPivot: string;   // 'ID_AC_PIVOT_SESLIN'
    FieldPrecioBase   : string;   // 'PRECIO_COMPRA_SESLIN'
    FieldTotalUds     : string;   // 'TOTAL_UNIDADES_SESLIN'
    FieldTotalLinea   : string;   // 'TOTAL_LINEA_SESLIN'

    // -- tabla y campos de celdas --
    TablaCeldas      : string;    // 'fza_compras_sesiones_celdas'
    FieldSerieCel    : string;    // 'SERIE_SES_SESCEL'
    FieldNumeroCel   : string;    // 'NUMERO_SES_SESCEL'
    FieldLineaCel    : string;    // 'LINEA_SES_SESCEL'
    FieldFilaCel     : string;    // 'ID_FILA_SES_SESCEL'
    FieldAvPivotCel  : string;    // 'ID_AV_PIVOT_SESCEL'
    FieldCantidadCel : string;    // 'CANTIDAD_SESCEL'
    FieldAlmacenCel  : string;    // 'CODIGO_ALM_SESCEL' (puede ser '')
    IdFilaFijo       : Integer;   // 1 — la prueba/Mtos por ahora usan una
                                  // fila logica por linea

    // -- limites --
    MaxColumnas      : Integer;   // 20 por defecto
  end;

  TGestorGridTallas = class
  private
    FCfg         : TGridTallasConfig;
    FConjuntoPos : TDictionary<Integer, TArrPosConjunto>;
    function  Master: TDataSet;
    function  Lineas: TDataSet;
    function  SerieDoc: string;
    function  NumeroDoc: string;
  public
    constructor Create(const ACfg: TGridTallasConfig);
    destructor  Destroy; override;

    // Cache de posiciones por conjunto.
    function GetPosicionesConjunto(AIdAc: Integer): TArrPosConjunto;
    procedure InvalidarCache;

    // Maximo de valores entre los conjuntos referenciados por
    // alguna linea de la sesion (capado a Cfg.MaxColumnas).
    function MaxLongConjuntos: Integer;

    // Muestra Cfg.ColumnasTallas[0..N-1] segun el maximo del documento
    // y oculta el resto. Setea captions genericos "Talla N" — la
    // captura del sistema activo la hace ActualizarCaptionsLineaActiva.
    procedure RecalcularMaxColumnas;

    // Al cambiar de fila con foco, escribe los valores del conjunto
    // activo en las captions de las columnas talla. Las posiciones
    // que no aplican al conjunto actual quedan con "Talla N" generico.
    procedure ActualizarCaptionsLineaActiva;

    // Lee la tabla de celdas y vuelca CANTIDAD a los Values[] de las
    // columnas no-bound del grid. Usa DisableControls + bookmark para
    // no perder los Values al cambiar de record durante el bucle.
    procedure CargarCantidadesTodasLineas;
    procedure CargarCantidadesUnaLinea(ARecordIndex, ALinea: Integer);

    // Persiste una cantidad en la tabla de celdas (UPSERT si > 0,
    // DELETE si <= 0).
    procedure PersistirCantidad(ALinea, AIdAv: Integer; ACantidad: Double);

    // Recalcula totales de la linea actual: SUM(CANTIDAD) y
    // FieldTotalLinea = SUM * FieldPrecioBase. Solo actualiza el
    // dataset en memoria; el form decide cuando Postear.
    procedure RefrescarTotalesLineaActual;

    // Valida que el conjunto recien seleccionado no excede
    // Cfg.MaxColumnas. Si lo excede muestra mtError, limpia el campo
    // y devuelve False; True en caso correcto.
    function ValidarSistemaSeleccionado: Boolean;

    // Persiste el cambio de la celda talla activa en el grid.
    // Llamarlo desde el OnEditValueChanged de cada columna talla.
    procedure PersistirCeldaActiva(ASender: TObject);

    property Cfg: TGridTallasConfig read FCfg;
  end;

// =============================================================================
//   Helpers que no necesitan estado pero suelen ir junto al gestor
// =============================================================================

// Apaga / enciende todas las instancias de TJvEnterAsTab encontradas en
// AForm, AForm.Owner y Application.MainForm. Llamarlo desde
// cxGrid.OnEnter (apagar) / OnExit (encender) para que Enter navegue
// celda a celda dentro del grid en vez de saltar al siguiente control.
procedure ActivarEnterComoTab(AForm: TForm; AActivo: Boolean);

// SelectAll en el editor si soporta seleccion de texto. Estilo Excel.
// Llamarlo desde tvLineas.OnInitEdit para que al entrar a una celda
// el contenido quede seleccionado.
procedure SeleccionarTodoEnEditor(AEdit: TcxCustomEdit);

implementation

uses
  System.Math;

{ TGestorGridTallas }

constructor TGestorGridTallas.Create(const ACfg: TGridTallasConfig);
begin
  inherited Create;
  FCfg := ACfg;
  if FCfg.MaxColumnas <= 0 then FCfg.MaxColumnas := 20;
  if FCfg.IdFilaFijo  <= 0 then FCfg.IdFilaFijo  := 1;
  FConjuntoPos := TDictionary<Integer, TArrPosConjunto>.Create;
end;

destructor TGestorGridTallas.Destroy;
begin
  FreeAndNil(FConjuntoPos);
  inherited;
end;

function TGestorGridTallas.Master: TDataSet;
begin
  if Assigned(FCfg.SourceMaster) then
    Result := FCfg.SourceMaster.DataSet
  else
    Result := nil;
end;

function TGestorGridTallas.Lineas: TDataSet;
begin
  if Assigned(FCfg.SourceLineas) then
    Result := FCfg.SourceLineas.DataSet
  else
    Result := nil;
end;

function TGestorGridTallas.SerieDoc: string;
var
  ds : TDataSet;
begin
  Result := '';
  ds := Master;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    Result := ds.FieldByName(FCfg.FieldSerieMaster).AsString;
end;

function TGestorGridTallas.NumeroDoc: string;
var
  ds : TDataSet;
begin
  Result := '';
  ds := Master;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    Result := ds.FieldByName(FCfg.FieldNumeroMaster).AsString;
end;

procedure TGestorGridTallas.InvalidarCache;
begin
  if FConjuntoPos <> nil then FConjuntoPos.Clear;
end;

function TGestorGridTallas.GetPosicionesConjunto(AIdAc: Integer)
                                                : TArrPosConjunto;
var
  q      : TUniQuery;
  arr    : TArrPosConjunto;
  i      : Integer;
  posReg : TPosConjunto;
begin
  // Devuelve la lista ordenada de (ID_AV, VALOR) del conjunto pivot
  // indicado. Cacheado en FConjuntoPos para no re-consultar por cada
  // refresco / edicion.
  Result := nil;
  if AIdAc <= 0 then Exit;
  if FConjuntoPos = nil then Exit;
  if FConjuntoPos.TryGetValue(AIdAc, Result) then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    q.SQL.Text :=
      'SELECT ACD.ID_AV_ACD, AV.AV AS VALOR ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      ' WHERE ACD.ID_AC_ACD = :p ' +
      ' ORDER BY ACD.ORDEN_ACD, AV.AV';
    q.ParamByName('p').AsInteger := AIdAc;
    q.Open;
    SetLength(arr, q.RecordCount);
    i := 0;
    while not q.Eof do
    begin
      posReg.IdAv  := q.FieldByName('ID_AV_ACD').AsInteger;
      posReg.Valor := q.FieldByName('VALOR').AsString;
      arr[i] := posReg;
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
  FConjuntoPos.Add(AIdAc, arr);
  Result := arr;
end;

function TGestorGridTallas.MaxLongConjuntos: Integer;
var
  ds     : TDataSet;
  bk     : TBookmark;
  vistos : TList<Integer>;
  iAc    : Integer;
  arr    : TArrPosConjunto;
begin
  // Recorre el dataset de lineas en memoria, recoge los ID_AC pivot
  // distintos y devuelve el tamano del conjunto mas grande. Iterar
  // el dataset abierto (con DisableControls + bookmark) es mucho mas
  // robusto que reformular el SQL — funciona para cualquier query y
  // no asume nombres de parametros del master.
  Result := 0;
  ds := Lineas;
  if (ds = nil) or not ds.Active or ds.IsEmpty then Exit;

  vistos := TList<Integer>.Create;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      iAc := ds.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
      if (iAc > 0) and (not vistos.Contains(iAc)) then
      begin
        vistos.Add(iAc);
        arr := GetPosicionesConjunto(iAc);
        if Length(arr) > Result then Result := Length(arr);
      end;
      ds.Next;
    end;
  finally
    if Assigned(bk) then
    begin
      if ds.BookmarkValid(bk) then ds.GotoBookmark(bk);
      ds.FreeBookmark(bk);
    end;
    ds.EnableControls;
    FreeAndNil(vistos);
  end;
  if Result > FCfg.MaxColumnas then Result := FCfg.MaxColumnas;
end;

procedure TGestorGridTallas.RecalcularMaxColumnas;
var
  i, iMax : Integer;
begin
  iMax := MaxLongConjuntos;
  for i := 0 to High(FCfg.ColumnasTallas) do
  begin
    if FCfg.ColumnasTallas[i] = nil then Continue;
    FCfg.ColumnasTallas[i].Visible := (i < iMax);
    if i < iMax then
      FCfg.ColumnasTallas[i].Caption := 'Talla ' + IntToStr(i + 1);
  end;
end;

procedure TGestorGridTallas.ActualizarCaptionsLineaActiva;
var
  ds   : TDataSet;
  iAc  : Integer;
  arr  : TArrPosConjunto;
  i    : Integer;
begin
  ds := Lineas;
  if (ds = nil) or not ds.Active or ds.IsEmpty then Exit;
  iAc := ds.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  arr := GetPosicionesConjunto(iAc);
  for i := 0 to High(FCfg.ColumnasTallas) do
  begin
    if FCfg.ColumnasTallas[i] = nil then Continue;
    if not FCfg.ColumnasTallas[i].Visible then Continue;
    if i < Length(arr) then
      FCfg.ColumnasTallas[i].Caption := arr[i].Valor
    else
      FCfg.ColumnasTallas[i].Caption := 'Talla ' + IntToStr(i + 1);
  end;
end;

procedure TGestorGridTallas.CargarCantidadesTodasLineas;
var
  i, iLinea : Integer;
  colLinea  : TcxGridDBColumn;
  vLinea    : Variant;
begin
  // Estrategia correcta para columnas no-bound en cxGridDBTableView:
  // iterar el DataController del propio grid, NO el dataset subyacente.
  //   - ds.DisableControls/EnableControls sobre el dataset hace que
  //     cxGrid limpie los Values[] no-bound al EnableControls (resetea
  //     el DataController desde cero).
  //   - DataController.BeginUpdate/EndUpdate suspende solo el cxGrid
  //     sin tocar el dataset; al EndUpdate el grid repinta de una vez
  //     con todos los Values[] que hayamos asignado en memoria.
  //   - Leer LINEA por Values[recordIdx, colLinea.Index] saca el dato
  //     sin tocar el cursor del dataset y sin disparar refrescos.
  if (Lineas = nil) or not Lineas.Active or Lineas.IsEmpty then Exit;
  if SerieDoc = '' then Exit;

  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;

  FCfg.Grid.DataController.BeginUpdate;
  try
    for i := 0 to FCfg.Grid.DataController.RecordCount - 1 do
    begin
      vLinea := FCfg.Grid.DataController.Values[i, colLinea.Index];
      if VarIsNull(vLinea) or VarIsEmpty(vLinea) then Continue;
      iLinea := vLinea;
      if iLinea > 0 then
        CargarCantidadesUnaLinea(i, iLinea);
    end;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
end;

procedure TGestorGridTallas.CargarCantidadesUnaLinea(ARecordIndex,
                                                    ALinea: Integer);
var
  q     : TUniQuery;
  iAc   : Integer;
  arr   : TArrPosConjunto;
  i     : Integer;
  iIdAv : Integer;
  rCant : Double;
  colAc : TcxGridDBColumn;
  vAc   : Variant;
begin
  // Leemos ID_AC_PIVOT del DataController (no del cursor del dataset:
  // la iteracion de CargarCantidadesTodasLineas no mueve el cursor,
  // asi que FieldByName devolveria siempre el conjunto de la linea
  // con foco, no el de la linea ARecordIndex).
  colAc := FCfg.Grid.GetColumnByFieldName(FCfg.FieldConjuntoPivot);
  if colAc = nil then Exit;
  vAc := FCfg.Grid.DataController.Values[ARecordIndex, colAc.Index];
  if VarIsNull(vAc) or VarIsEmpty(vAc) then Exit;
  iAc := vAc;

  arr := GetPosicionesConjunto(iAc);
  if Length(arr) = 0 then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    q.SQL.Text :=
      'SELECT ' + FCfg.FieldAvPivotCel + ', ' +
      '       SUM(' + FCfg.FieldCantidadCel + ') AS TOTAL ' +
      '  FROM ' + FCfg.TablaCeldas + ' ' +
      ' WHERE ' + FCfg.FieldSerieCel  + ' = :s ' +
      '   AND ' + FCfg.FieldNumeroCel + ' = :n ' +
      '   AND ' + FCfg.FieldLineaCel  + ' = :l ' +
      ' GROUP BY ' + FCfg.FieldAvPivotCel;
    q.ParamByName('s').AsString  := SerieDoc;
    q.ParamByName('n').AsString  := NumeroDoc;
    q.ParamByName('l').AsInteger := ALinea;
    q.Open;
    while not q.Eof do
    begin
      iIdAv := q.FieldByName(FCfg.FieldAvPivotCel).AsInteger;
      rCant := q.FieldByName('TOTAL').AsFloat;
      for i := 0 to High(arr) do
        if arr[i].IdAv = iIdAv then
        begin
          if (i <= High(FCfg.ColumnasTallas)) and
             (FCfg.ColumnasTallas[i] <> nil) then
            FCfg.Grid.DataController.Values[
              ARecordIndex, FCfg.ColumnasTallas[i].Index] := rCant;
          Break;
        end;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TGestorGridTallas.PersistirCantidad(ALinea, AIdAv: Integer;
                                              ACantidad: Double);
var
  q : TUniQuery;
begin
  // Upsert / delete sobre la tabla de celdas para (linea, fila=fijo,
  // pivot, almacen=vacio).
  if (ALinea <= 0) or (AIdAv <= 0) then Exit;
  if SerieDoc = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    if ACantidad <= 0 then
    begin
      q.SQL.Text :=
        'DELETE FROM ' + FCfg.TablaCeldas + ' ' +
        ' WHERE ' + FCfg.FieldSerieCel   + ' = :s ' +
        '   AND ' + FCfg.FieldNumeroCel  + ' = :n ' +
        '   AND ' + FCfg.FieldLineaCel   + ' = :l ' +
        '   AND ' + FCfg.FieldFilaCel    + ' = :f ' +
        '   AND ' + FCfg.FieldAvPivotCel + ' = :p ' +
        '   AND ' + FCfg.FieldAlmacenCel + ' = :a';
    end
    else
    begin
      q.SQL.Text :=
        'INSERT INTO ' + FCfg.TablaCeldas + ' (' +
        FCfg.FieldSerieCel   + ', ' +
        FCfg.FieldNumeroCel  + ', ' +
        FCfg.FieldLineaCel   + ', ' +
        FCfg.FieldFilaCel    + ', ' +
        FCfg.FieldAvPivotCel + ', ' +
        FCfg.FieldAlmacenCel + ', ' +
        FCfg.FieldCantidadCel +
        ', INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:s, :n, :l, :f, :p, :a, :c, NOW(), :u) ' +
        'ON DUPLICATE KEY UPDATE ' +
        FCfg.FieldCantidadCel + ' = :c, ' +
        'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
      q.ParamByName('c').AsFloat  := ACantidad;
      q.ParamByName('u').AsString := FCfg.Usuario;
    end;
    q.ParamByName('s').AsString  := SerieDoc;
    q.ParamByName('n').AsString  := NumeroDoc;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('f').AsInteger := FCfg.IdFilaFijo;
    q.ParamByName('p').AsInteger := AIdAv;
    q.ParamByName('a').AsString  := '';
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TGestorGridTallas.RefrescarTotalesLineaActual;
var
  q     : TUniQuery;
  rTot  : Double;
  rPr   : Double;
  ds    : TDataSet;
  iLinea: Integer;
begin
  ds := Lineas;
  if (ds = nil) or ds.IsEmpty then Exit;
  iLinea := ds.FieldByName(FCfg.FieldLinea).AsInteger;
  if iLinea <= 0 then Exit;
  if SerieDoc = '' then Exit;

  rTot := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FCfg.Conexion;
    q.SQL.Text :=
      'SELECT COALESCE(SUM(' + FCfg.FieldCantidadCel + '), 0) AS TOTAL ' +
      '  FROM ' + FCfg.TablaCeldas + ' ' +
      ' WHERE ' + FCfg.FieldSerieCel  + ' = :s ' +
      '   AND ' + FCfg.FieldNumeroCel + ' = :n ' +
      '   AND ' + FCfg.FieldLineaCel  + ' = :l';
    q.ParamByName('s').AsString  := SerieDoc;
    q.ParamByName('n').AsString  := NumeroDoc;
    q.ParamByName('l').AsInteger := iLinea;
    q.Open;
    rTot := q.FieldByName('TOTAL').AsFloat;
  finally
    FreeAndNil(q);
  end;
  rPr := ds.FieldByName(FCfg.FieldPrecioBase).AsFloat;
  // BeginUpdate/EndUpdate del DataController para que el cxGrid no
  // re-renderice la fila tras el ds.Edit y las asignaciones de campos
  // bound — el re-render limpia los Values[] no-bound de TODAS las
  // celdas talla de TODAS las lineas. Sin esta envoltura, en cuanto el
  // usuario teclea una cantidad y disparamos RefrescarTotales, las
  // tallas se borran visualmente (los datos siguen bien en SESCEL).
  FCfg.Grid.DataController.BeginUpdate;
  try
    if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
    ds.FieldByName(FCfg.FieldTotalUds).AsFloat   := rTot;
    ds.FieldByName(FCfg.FieldTotalLinea).AsFloat := rTot * rPr;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
  // Sin Post — lo decide el Mto cuando el usuario Graba o cambia
  // de fila.
end;

function TGestorGridTallas.ValidarSistemaSeleccionado: Boolean;
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  Result := True;
  if Lineas = nil then Exit;
  if Lineas.IsEmpty then Exit;
  iAc := Lineas.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  if iAc <= 0 then Exit;
  arr := GetPosicionesConjunto(iAc);
  if Length(arr) <= FCfg.MaxColumnas then Exit;

  MessageDlg(Format(
    'El sistema de tallas seleccionado tiene %d valores; el ' +
    'maximo admitido es %d. Elige un sistema con menos tallas ' +
    'o reduce el conjunto antes de usarlo aqui.',
    [Length(arr), FCfg.MaxColumnas]),
    mtError, [mbOk], 0);
  if not (Lineas.State in [dsEdit, dsInsert]) then Lineas.Edit;
  Lineas.FieldByName(FCfg.FieldConjuntoPivot).Clear;
  Result := False;
end;

procedure TGestorGridTallas.PersistirCeldaActiva(ASender: TObject);
var
  ed     : TcxCustomEdit;
  item   : TcxCustomGridTableItem;
  iPos   : Integer;
  iLinea : Integer;
  iAc    : Integer;
  arr    : TArrPosConjunto;
  rCant  : Double;
  vEdit  : Variant;
begin
  if not (ASender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(ASender);
  ed.PostEditValue;

  // El FocusedItem del grid (TcxCustomGridTableItem) es la base de
  // todas las columnas; nos basta su Tag para identificar la posicion
  // de la celda. Asi evitamos depender del tipo concreto TcxGridColumn /
  // TcxGridDBColumn (que en este build no resuelve desde la libreria
  // por algun fallo de scope incluso con cxGridTableView en uses).
  item := FCfg.Grid.Controller.FocusedItem;
  if item = nil then Exit;
  iPos := item.Tag;
  if (iPos < 1) or (iPos > FCfg.MaxColumnas) then Exit;
  if Lineas = nil then Exit;
  if Lineas.IsEmpty then Exit;

  iLinea := Lineas.FieldByName(FCfg.FieldLinea).AsInteger;
  iAc    := Lineas.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  arr    := GetPosicionesConjunto(iAc);
  if iPos > Length(arr) then Exit;     // posicion fuera del sistema

  vEdit := ed.EditValue;
  if VarIsNull(vEdit) or VarIsClear(vEdit) then
    rCant := 0
  else
    rCant := vEdit;

  PersistirCantidad(iLinea, arr[iPos - 1].IdAv, rCant);
  RefrescarTotalesLineaActual;
end;

// =============================================================================
//   Helpers libres
// =============================================================================

procedure ActivarEnterComoTab(AForm: TForm; AActivo: Boolean);
  procedure CambiarEn(AOwner: TComponent);
  var
    i : Integer;
  begin
    if not Assigned(AOwner) then Exit;
    for i := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[i] is TJvEnterAsTab then
        TJvEnterAsTab(AOwner.Components[i]).EnterAsTab := AActivo;
  end;
begin
  CambiarEn(AForm);
  if Assigned(AForm) then CambiarEn(AForm.Owner);
  CambiarEn(Application.MainForm);
end;

procedure SeleccionarTodoEnEditor(AEdit: TcxCustomEdit);
begin
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

end.
