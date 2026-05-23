{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (flotante, fsStayOnTop)                            }
{ Version:       0.5.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Consulta de stock invocable con Ctrl+U desde cualquier mantenimiento      }
{    que herede de TfrmMtoGen. Al abrirse pre-carga el articulo / SKU activo   }
{    via TfrmMtoGen.ResolverArtSkuActivo.                                      }
{                                                                              }
{    Layout (estilo OdaGest+):                                                 }
{      - Cabecera (pnlCabecera): boton de busqueda de articulo + descripcion   }
{        + bloque de info (temporada, tarifas, proveedores) + foto.            }
{      - Filtros (pnlFiltros): combo "Estado del stock".                       }
{      - Cuerpo (pnlBody): split horizontal con un TSplitter.                  }
{        * pnlIzq (alLeft, 280px): pcFiltros con dos pestanas                  }
{            "1 Colores"   -> clbColores (checklist de AVs de color)           }
{            "2 Almacenes" -> clbAlmacenes (checklist de almacenes activos)    }
{        * pnlDer (alClient): pcVistas (alTop, 30px) con dos pestanas          }
{            "3 Por almacenes" -> grid con almacenes como filas                }
{            "4 Por colores"   -> grid con colores como filas                  }
{          y el TcxGrid (alClient) compartido. La pestana activa de pcVistas   }
{          determina el modo de pivote y se aplica como filtro cruzado el      }
{          checklist opuesto.                                                  }
{                                                                              }
{    v0.5: estado "Todo a la vez" en el combo + colores por estado. Cada      }
{    estado pinta las celdas de datos con un color distintivo (azul para      }
{    existencias, rojo para ventas, naranja para pte. recibir, etc.) y el     }
{    combo seleccionado refleja ese color. En modo "Todo a la vez" el grid    }
{    desdobla cada fila de grupo (almacen o color) en una fila por estado    }
{    con datos, pintando cada fila en el color de su estado.                  }
{    v0.4: split horizontal estilo OdaGest+ — checklist a la izquierda,        }
{    pestanas de vista pivote arriba del grid a la derecha. Tabs numeradas     }
{    1/2/3/4 como en el original.                                              }
{    v0.3: temporada en cabecera, formato de tarifas/proveedores depurado,     }
{    layout reorganizado: checklist de almacenes movido a la pestana Por       }
{    Almacen y checklist nuevo de colores en la pestana Por Color.             }
{    v0.2: pivote dinamico, colores con swatch en cabecera, panel de           }
{    precios/proveedores. Estado "Prestadas" sigue siendo stub.                }
{******************************************************************************}
unit inMtoStockConsulta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Data.DB, DBAccess, Uni,
  cxClasses, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxButtonEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCheckBox, cxCheckListBox, cxCustomData, cxStyles,
  cxCurrencyEdit,
  cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxGraphics, cxLocalization,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxScrollbarAnnotations,
  dxDateRanges, cxMemo, cxControls, dxCoreGraphics, cxCustomListBox;

type
  TEstadoStock = (
    esExistencias,
    esEntradas,
    esSalidas,
    esVentas,
    esRegularizadas,
    esPdteRecibir,
    esPdteServir,
    esPrestadas,
    esTodoAlaVez   // muestra todos los estados anteriores en filas separadas
  );

  TInfoColumna = record
    Codigo : string;     // CODIGO_ALM o AV del color
    Texto  : string;     // Caption a mostrar
    Hex    : string;     // HEX (solo para color, '' si no)
    EsColor: Boolean;
  end;

  TfrmStockConsulta = class(TForm)
    pnlCabecera   : TPanel;
      lblArt        : TcxLabel;
      btnArt        : TcxButtonEdit;
      lblDescr      : TcxLabel;
      lblInfo       : TcxLabel;
      imgFoto       : TImage;
    pnlFiltros    : TPanel;
      lblEstado     : TcxLabel;
      cbbEstado     : TcxComboBox;
    pnlBody       : TPanel;
      pnlIzq        : TPanel;
        pcFiltros     : TcxPageControl;
          tsColores     : TcxTabSheet;
            lblColores    : TcxLabel;
            clbColores    : TcxCheckListBox;
          tsAlmacenes   : TcxTabSheet;
            lblAlmacenes  : TcxLabel;
            clbAlmacenes  : TcxCheckListBox;
      splVert       : TSplitter;
      pnlDer        : TPanel;
        pcVistas      : TcxPageControl;
          tsPorAlmacen  : TcxTabSheet;
          tsPorColor    : TcxTabSheet;
        grdStock      : TcxGrid;
          tvStock       : TcxGridDBTableView;
          glStock       : TcxGridLevel;
    pnlLeyenda    : TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnArtPropertiesButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure btnArtPropertiesEditValueChanged(Sender: TObject);
    procedure cbbEstadoPropertiesEditValueChanged(Sender: TObject);
    procedure clbAlmacenesClickCheck(Sender: TObject; AIndex: Integer;
              APrevState, ANewState: TcxCheckBoxState);
    procedure clbColoresClickCheck(Sender: TObject; AIndex: Integer;
              APrevState, ANewState: TcxCheckBoxState);
    procedure pcVistasChange(Sender: TObject);
    procedure tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
              ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
              var ADone: Boolean);
  private
    FQry        : TUniQuery;
    FDs         : TDataSource;
    FCodArt     : string;
    FCodSku     : string;
    FColumnas   : TArray<TInfoColumna>;  // Tallas (columnas dinamicas)
    FColsDin    : TList<TcxGridDBColumn>;
    FColGrupo   : TcxGridDBColumn;       // nombre de la fila (color o alm)
    FColEstado  : TcxGridDBColumn;       // nombre del estado (solo en Todo a la vez)
    FEsModoColor: Boolean;
    FEsModoTodo : Boolean;               // estado=esTodoAlaVez en la ultima recarga
    procedure CargarAlmacenes;
    procedure CargarColores;
    procedure CargarFoto;
    procedure CargarInfoCabecera;
    procedure CrearLeyenda;
    function  EstadoActual: TEstadoStock;
    function  AlmacenesSeleccionadosSQL: string;  // 'CODA','CODB' o NULL
    function  AlmacenesSeleccionadosLista: TArray<string>;
    function  ColoresSeleccionadosSQL: string;    // 'CO1','CO2' o NULL
    function  ColoresSeleccionadosLista: TArray<string>;
    function  BuscarArticulo: string;
    function  TallasArticulo: TArray<TInfoColumna>;
    function  ConstruirSQLPivot(const ATallas: TArray<TInfoColumna>;
                                 AEsColor: Boolean): string;
    function  EstadoBaseSelect: string;  // CTE/source segun estado
    function  EstadoBaseSelectFor(AEstado: TEstadoStock): string;
    procedure ReconstruirColumnas(const ATallas: TArray<TInfoColumna>;
                                   AEsColor: Boolean);
    procedure RecargarConsulta;
  public
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
  end;

var
  frmStockConsulta: TfrmStockConsulta;

/// Abre (o trae al frente) la consulta de stock con el (articulo, sku)
/// indicado. Mismo patron que inMtoFotoArticulo.MostrarFotoFlotante.
procedure MostrarStockConsulta(AOwner: TComponent;
                               const ACodArt, ACodSku: string);

implementation

uses
  System.StrUtils,
  inLibGlobalVar, inLibFotos, inLibAtributosPaleta, inLibGenBusq;

{$R *.dfm}

// ---------------------------------------------------------------------------
//  Colores por estado del stock (texto en las celdas / combo seleccionado)
// ---------------------------------------------------------------------------
// Misma idea que la leyenda inferior de OdaGest+: cada estado tiene un
// color distintivo. Las celdas de datos del grid se pintan con el color
// del estado activo, y en modo "Todo a la vez" cada fila se colorea con
// el color de su estado. Los valores BGR siguen el orden de Delphi
// ($00BBGGRR), por eso el naranja sale como $000080FF.
function ColorEstado(AEstado: TEstadoStock): TColor;
begin
  case AEstado of
    esExistencias:    Result := clNavy;        // azul oscuro - disponible
    esEntradas:       Result := clGreen;       // verde - entradas
    esSalidas:        Result := clMaroon;      // rojo oscuro - salidas
    esVentas:         Result := clRed;         // rojo brillante - ventas
    esRegularizadas:  Result := clPurple;      // morado - regularizadas
    esPdteRecibir:    Result := $000080FF;     // naranja - pte. recibir
    esPdteServir:     Result := clTeal;        // turquesa - pte. servir
    esPrestadas:      Result := clGray;        // gris - prestadas
  else
    Result := clBlack;                          // esTodoAlaVez -> sin color uniforme
  end;
end;

function NombreEstadoCorto(AEstado: TEstadoStock): string;
begin
  case AEstado of
    esExistencias:    Result := 'Existencias';
    esEntradas:       Result := 'Entradas';
    esSalidas:        Result := 'Salidas';
    esVentas:         Result := 'Ventas';
    esRegularizadas:  Result := 'Regulariz.';
    esPdteRecibir:    Result := 'Pte. recibir';
    esPdteServir:     Result := 'Pte. servir';
    esPrestadas:      Result := 'Prestadas';
  else
    Result := '';
  end;
end;

// ---------------------------------------------------------------------------
//  Funcion publica de apertura
// ---------------------------------------------------------------------------
procedure MostrarStockConsulta(AOwner: TComponent;
                               const ACodArt, ACodSku: string);
var
  hwndPrev: HWND;
begin
  hwndPrev := GetForegroundWindow;
  if frmStockConsulta = nil then
    frmStockConsulta := TfrmStockConsulta.Create(Application);
  frmStockConsulta.SetArticuloSku(ACodArt, ACodSku);
  if not frmStockConsulta.Visible then
  begin
    ShowWindow(frmStockConsulta.Handle, SW_SHOWNOACTIVATE);
    frmStockConsulta.Visible := True;
  end;
  if hwndPrev <> 0 then SetForegroundWindow(hwndPrev);
end;

// ---------------------------------------------------------------------------
//  Form
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.FormCreate(Sender: TObject);
begin
  Self.Position := poDesigned;
  Self.FormStyle := fsStayOnTop;

  FQry := TUniQuery.Create(Self);
  FQry.Connection := inLibGlobalVar.oConn;
  FDs  := TDataSource.Create(Self);
  FDs.DataSet := FQry;
  tvStock.DataController.DataSource := FDs;
  FColsDin := TList<TcxGridDBColumn>.Create;
  // Custom-draw para pintar el cuadradito del color basico en la celda
  // del color, via la libreria inLibAtributosPaleta (que se encarga del
  // lookup contra fza_atributos_basicos por texto/codigo y la cache).
  tvStock.OnCustomDrawCell := tvStockCustomDrawCell;

  // Combo de estados
  cbbEstado.Properties.Items.Clear;
  cbbEstado.Properties.Items.Add('Existencias');
  cbbEstado.Properties.Items.Add('Entradas');
  cbbEstado.Properties.Items.Add('Salidas');
  cbbEstado.Properties.Items.Add('Ventas');
  cbbEstado.Properties.Items.Add('Regularizadas');
  cbbEstado.Properties.Items.Add('Pdte. de recibir');
  cbbEstado.Properties.Items.Add('Pdte. de servir');
  cbbEstado.Properties.Items.Add('Prestadas');
  cbbEstado.Properties.Items.Add('Todo a la vez');
  cbbEstado.ItemIndex := 0;
  cbbEstado.Style.TextColor := ColorEstado(esExistencias);

  pcVistas.ActivePage := tsPorAlmacen;
  pcFiltros.ActivePage := tsColores;
  CrearLeyenda;
  CargarAlmacenes;
end;

// ---------------------------------------------------------------------------
//  Leyenda al pie del formulario: nombre de cada estado en su color, igual
//  que la leyenda inferior de OdaGest+. Se construye dinamicamente con
//  TLabels para que añadir un estado nuevo se reduzca a tocar ColorEstado
//  y NombreEstadoCorto.
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CrearLeyenda;
const
  ESTADOS_LEYENDA: array[0..7] of TEstadoStock = (
    esExistencias, esEntradas, esSalidas, esVentas, esRegularizadas,
    esPdteRecibir, esPdteServir, esPrestadas);
var
  i: Integer;
  lbl: TLabel;
  x: Integer;
begin
  x := 8;
  for i := Low(ESTADOS_LEYENDA) to High(ESTADOS_LEYENDA) do
  begin
    lbl := TLabel.Create(pnlLeyenda);
    lbl.Parent     := pnlLeyenda;
    lbl.AutoSize   := True;
    lbl.Font.Color := ColorEstado(ESTADOS_LEYENDA[i]);
    lbl.Font.Style := [fsBold];
    lbl.Caption    := NombreEstadoCorto(ESTADOS_LEYENDA[i]);
    lbl.Top        := 5;
    lbl.Left       := x;
    x := x + lbl.Width + 14;
  end;
end;

procedure TfrmStockConsulta.FormDestroy(Sender: TObject);
begin
  if Assigned(FQry) then
  begin
    if FQry.Active then FQry.Close;
    FreeAndNil(FQry);
  end;
  FreeAndNil(FDs);
  FreeAndNil(FColsDin);
end;

procedure TfrmStockConsulta.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

// ---------------------------------------------------------------------------
//  Almacenes (check-list)
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CargarAlmacenes;
var
  q   : TUniQuery;
  item: TcxCheckListBoxItem;
  bStd: Boolean;
begin
  clbAlmacenes.Items.Clear;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, TIPO_USO_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    q.Open;
    while not q.Eof do
    begin
      item := clbAlmacenes.Items.Add;
      item.Text := q.FieldByName('CODIGO_ALM_ALM').AsString + ' - ' +
                   q.FieldByName('NOMBRE_ALM_ALM').AsString;
      bStd := (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDAR') or
              (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDARD');
      if bStd then item.State := cbsChecked else item.State := cbsUnchecked;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmStockConsulta.AlmacenesSeleccionadosLista: TArray<string>;
var
  i, p: Integer;
  s, sCod: string;
begin
  SetLength(Result, 0);
  for i := 0 to clbAlmacenes.Items.Count - 1 do
    if clbAlmacenes.Items[i].State = cbsChecked then
    begin
      s := clbAlmacenes.Items[i].Text;
      p := Pos(' - ', s);
      if p > 0 then sCod := Copy(s, 1, p - 1) else sCod := s;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := sCod;
    end;
end;

function TfrmStockConsulta.AlmacenesSeleccionadosSQL: string;
var
  alms: TArray<string>;
  i: Integer;
begin
  alms := AlmacenesSeleccionadosLista;
  if Length(alms) = 0 then
  begin
    Result := 'NULL';
    Exit;
  end;
  Result := '';
  for i := 0 to High(alms) do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + QuotedStr(alms[i]);
  end;
end;

// ---------------------------------------------------------------------------
//  Colores del articulo (check-list de la pestana "Por Color")
// ---------------------------------------------------------------------------
// Carga los AVs distintos de color (ID_VA_AV='CO') que aparecen en los SKUs
// activos del articulo. Por defecto todos marcados; el usuario puede
// desmarcar para filtrar las filas (modo Por Color) o las cantidades
// agregadas (modo Por Almacen).
procedure TfrmStockConsulta.CargarColores;
var
  q   : TUniQuery;
  item: TcxCheckListBoxItem;
begin
  clbColores.Items.Clear;
  if Trim(FCodArt) = '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // GROUP BY AV.AV para deduplicar por nombre de color: en
    // fza_atributos_valores puede haber varios ID_AV con el mismo texto
    // (ej. NEGRO con ID_AV=100 y otro NEGRO con otro ID_AV/ORDEN_AV).
    // En el checklist y en el grid los queremos como UNA sola entrada.
    q.SQL.Text :=
      'SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_atributos_sku SA ' +
      '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      ' WHERE SKU.CODIGO_ART_SKU = :art ' +
      '   AND AV.ID_VA_AV = ''CO'' ' +
      ' GROUP BY AV.AV ' +
      ' ORDER BY MIN(AV.ORDEN_AV), AV.AV';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    while not q.Eof do
    begin
      item := clbColores.Items.Add;
      item.Text  := q.FieldByName('AV').AsString;
      item.State := cbsChecked;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmStockConsulta.ColoresSeleccionadosLista: TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, 0);
  for i := 0 to clbColores.Items.Count - 1 do
    if clbColores.Items[i].State = cbsChecked then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := clbColores.Items[i].Text;
    end;
end;

function TfrmStockConsulta.ColoresSeleccionadosSQL: string;
var
  cols: TArray<string>;
  i: Integer;
begin
  cols := ColoresSeleccionadosLista;
  if Length(cols) = 0 then
  begin
    Result := 'NULL';
    Exit;
  end;
  Result := '';
  for i := 0 to High(cols) do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + QuotedStr(cols[i]);
  end;
end;

// ---------------------------------------------------------------------------
//  Carga de articulo / SKU + foto + info de precios
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.SetArticuloSku(const ACodArt, ACodSku: string);
var
  q: TUniQuery;
begin
  FCodArt := ACodArt;
  FCodSku := ACodSku;
  btnArt.Text := ACodArt;

  lblDescr.Caption := '';
  if Trim(ACodArt) <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := inLibGlobalVar.oConn;
      q.SQL.Text :=
        'SELECT DESCRIPCION_ART FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :p';
      q.ParamByName('p').AsString := ACodArt;
      q.Open;
      if not q.IsEmpty then
        lblDescr.Caption := q.FieldByName('DESCRIPCION_ART').AsString;
    finally
      FreeAndNil(q);
    end;
  end;

  CargarFoto;
  CargarInfoCabecera;
  CargarColores;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.CargarFoto;
var
  info: TFotoInfo;
  ruta: string;
  png : TPngImage;
begin
  imgFoto.Picture.Assign(nil);
  if Trim(FCodArt) = '' then Exit;
  info := inLibFotos.oFotos.Resolver(FCodArt, FCodSku);
  ruta := inLibFotos.oFotos.RutaFoto(info, frPx300);
  if ruta = '' then Exit;
  png := TPngImage.Create;
  try
    png.LoadFromFile(ruta);
    imgFoto.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

// Pinta el bloque de info de la cabecera (temporada + tarifas + proveedores).
// Las tarifas se listan de la por defecto a las demas (ORDER BY ESDEFAULT
// DESC, ORDEN_TAR con NULLs al final). Los proveedores van con el principal
// primero. Se ignoran tarifas/proveedores con SKU especifico — aqui solo
// mostramos el dato a nivel de articulo.
procedure TfrmStockConsulta.CargarInfoCabecera;
var
  q : TUniQuery;
  sb: TStringList;
begin
  lblInfo.Caption := '';
  if Trim(FCodArt) = '' then Exit;

  sb := TStringList.Create;
  q  := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;

    // ---- Temporada (fza_articulos_propiedades, prop TEMPORADA) ----
    q.SQL.Text :=
      'SELECT PV.PV ' +
      '  FROM fza_articulos_propiedades AP ' +
      '  LEFT JOIN fza_propiedades_valores PV ' +
      '    ON PV.ID_PV_ARTPROP = AP.ID_PV_ARTPROP ' +
      ' WHERE AP.CODIGO_ART_ART = :art ' +
      '   AND AP.CODIGO_PROP_ARTPROP = ''TEMPORADA''';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    if (not q.IsEmpty) and (Trim(q.FieldByName('PV').AsString) <> '') then
      sb.Add('Temporada: ' + q.FieldByName('PV').AsString);
    q.Close;

    // ---- Tarifas del articulo (sin SKU especifico) ----
    q.SQL.Text :=
      'SELECT AT.CODIGO_TAR_ARTTAR, T.NOMBRE_TAR_TAR, T.ESDEFAULT_TAR, ' +
      '       AT.PRECIO_FINAL_ARTTAR ' +
      '  FROM fza_articulos_tarifas AT ' +
      '  LEFT JOIN fza_tarifas T ' +
      '    ON T.CODIGO_TAR_ARTTAR = AT.CODIGO_TAR_ARTTAR ' +
      ' WHERE AT.CODIGO_ART_ARTTAR = :art ' +
      '   AND IFNULL(AT.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
      '   AND AT.ESACTIVO_ARTTAR = ''S'' ' +
      ' ORDER BY T.ESDEFAULT_TAR DESC, ' +
      '          COALESCE(T.ORDEN_TAR, 999999), T.NOMBRE_TAR_TAR';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    if not q.IsEmpty then
      sb.Add('');
    while not q.Eof do
    begin
      sb.Add(Format('%s%s: %s',
        [IfThen(q.FieldByName('ESDEFAULT_TAR').AsString = 'S',
                'Tarifa por defecto - ', ''),
         IfThen(Trim(q.FieldByName('NOMBRE_TAR_TAR').AsString) <> '',
                q.FieldByName('NOMBRE_TAR_TAR').AsString,
                q.FieldByName('CODIGO_TAR_ARTTAR').AsString),
         FormatFloat('#,##0.00', q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat)
         + ' '#8364]));
      q.Next;
    end;
    q.Close;

    // ---- Proveedores ----
    q.SQL.Text :=
      'SELECT AP.CODIGO_PRV_AP, P.RAZON_SOCIAL_PRV, ' +
      '       AP.REF_PROVEEDOR_AP, AP.PRECIO_ULT_COMPRA_AP, ' +
      '       AP.ESPROVEEDORPRINCIPAL_AP ' +
      '  FROM fza_articulos_proveedores AP ' +
      '  LEFT JOIN fza_proveedores P ' +
      '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
      ' WHERE AP.CODIGO_ART_AP = :art ' +
      ' ORDER BY AP.ESPROVEEDORPRINCIPAL_AP DESC, P.RAZON_SOCIAL_PRV';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    if not q.IsEmpty then
      sb.Add('');
    while not q.Eof do
    begin
      sb.Add(Format('%s%s%s: %s',
        [IfThen(q.FieldByName('ESPROVEEDORPRINCIPAL_AP').AsString = 'S',
                'Proveedor ppal. - ', 'Proveedor - '),
         IfThen(Trim(q.FieldByName('RAZON_SOCIAL_PRV').AsString) <> '',
                q.FieldByName('RAZON_SOCIAL_PRV').AsString,
                q.FieldByName('CODIGO_PRV_AP').AsString),
         IfThen(Trim(q.FieldByName('REF_PROVEEDOR_AP').AsString) <> '',
                ' (ref ' + q.FieldByName('REF_PROVEEDOR_AP').AsString + ')',
                ''),
         FormatFloat('#,##0.00',
                     q.FieldByName('PRECIO_ULT_COMPRA_AP').AsFloat) + ' '#8364
        ]));
      q.Next;
    end;

    lblInfo.Caption := sb.Text;
  finally
    FreeAndNil(q);
    FreeAndNil(sb);
  end;
end;

// ---------------------------------------------------------------------------
//  Estado: base SELECT (que va dentro del SUM(CASE WHEN ...))
// ---------------------------------------------------------------------------
// Devuelve un subselect que produce filas (CODIGO_UNIDAD_SKU, COLOR,
// TALLA, ALM, CANTIDAD). El pivote SQL exterior agrupa por TALLA y mete
// CASE-WHEN por COLOR o ALM en cada columna.
// Subselect base parametrizado por estado. Cada bloque devuelve filas con
// el mismo shape (CODIGO_UNIDAD_SKU, COLOR_AV, TALLA_AV, ORDEN_TALLA, ALM,
// CANTIDAD) + un literal ESTADO_NUM que identifica el estado origen para
// que en modo "Todo a la vez" podamos hacer UNION ALL y agrupar tambien
// por ESTADO_NUM en el pivote exterior.
function TfrmStockConsulta.EstadoBaseSelectFor(AEstado: TEstadoStock): string;
var
  sAlms, sEstadoNum: string;
begin
  sAlms      := AlmacenesSeleccionadosSQL;
  sEstadoNum := IntToStr(Ord(AEstado));
  case AEstado of
    esExistencias:
      Result :=
        'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
        '       (SELECT AV.AV FROM fza_atributos_sku SC ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SC.ID_AV_SA ' +
        '         WHERE SC.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV = ''CO'' LIMIT 1) AS COLOR_AV, ' +
        '       (SELECT AV.AV FROM fza_atributos_sku ST ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
        '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS TALLA_AV, ' +
        '       (SELECT AV.ORDEN_AV FROM fza_atributos_sku ST ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
        '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS ORDEN_TALLA, ' +
        '       STK.CODIGO_ALM_STK AS ALM, ' +
        '       SUM(STK.CANTIDAD_STK) AS CANTIDAD, ' +
        '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_articulos_stockactual STK ' +
        '    ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND STK.CODIGO_ALM_STK IN (' + sAlms + ') ' +
        ' GROUP BY SKU.CODIGO_UNIDAD_SKU, STK.CODIGO_ALM_STK';
    esPdteRecibir:
      Result :=
        'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
        '       (SELECT AV.AV FROM fza_atributos_sku SC ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SC.ID_AV_SA ' +
        '         WHERE SC.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV = ''CO'' LIMIT 1) AS COLOR_AV, ' +
        '       (SELECT AV.AV FROM fza_atributos_sku ST ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
        '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS TALLA_AV, ' +
        '       (SELECT AV.ORDEN_AV FROM fza_atributos_sku ST ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
        '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS ORDEN_TALLA, ' +
        '       PDR.CODIGO_ALM_PDR AS ALM, ' +
        '       SUM(PDR.CANTIDAD_PDR) AS CANTIDAD, ' +
        '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_articulos_pdte_recibir PDR ' +
        '    ON PDR.CODIGO_UNIDAD_PDR = SKU.CODIGO_UNIDAD_SKU ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND PDR.CODIGO_ALM_PDR IN (' + sAlms + ') ' +
        ' GROUP BY SKU.CODIGO_UNIDAD_SKU, PDR.CODIGO_ALM_PDR';
    esPdteServir:
      Result :=
        'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
        '       (SELECT AV.AV FROM fza_atributos_sku SC ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SC.ID_AV_SA ' +
        '         WHERE SC.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV = ''CO'' LIMIT 1) AS COLOR_AV, ' +
        '       (SELECT AV.AV FROM fza_atributos_sku ST ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
        '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS TALLA_AV, ' +
        '       (SELECT AV.ORDEN_AV FROM fza_atributos_sku ST ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
        '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS ORDEN_TALLA, ' +
        '       STK.CODIGO_ALM_STK AS ALM, ' +
        '       SUM(STK.CANTIDAD_PTE_SERVIR_STK) AS CANTIDAD, ' +
        '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_articulos_stockactual STK ' +
        '    ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND STK.CODIGO_ALM_STK IN (' + sAlms + ') ' +
        ' GROUP BY SKU.CODIGO_UNIDAD_SKU, STK.CODIGO_ALM_STK';
    esEntradas, esSalidas, esVentas, esRegularizadas:
      begin
        Result :=
          'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
          '       (SELECT AV.AV FROM fza_atributos_sku SC ' +
          '          JOIN fza_atributos_valores AV ON AV.ID_AV = SC.ID_AV_SA ' +
          '         WHERE SC.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
          '           AND AV.ID_VA_AV = ''CO'' LIMIT 1) AS COLOR_AV, ' +
          '       (SELECT AV.AV FROM fza_atributos_sku ST ' +
          '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
          '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
          '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS TALLA_AV, ' +
          '       (SELECT AV.ORDEN_AV FROM fza_atributos_sku ST ' +
          '          JOIN fza_atributos_valores AV ON AV.ID_AV = ST.ID_AV_SA ' +
          '         WHERE ST.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
          '           AND AV.ID_VA_AV <> ''CO'' LIMIT 1) AS ORDEN_TALLA, ' +
          '       M.CODIGO_ALM_MOV AS ALM, ' +
          '       SUM(M.CANTIDAD_MOV) AS CANTIDAD, ' +
          '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
          '  FROM fza_articulos_skus SKU ' +
          '  JOIN fza_movimientos_almacen M ' +
          '    ON M.CODIGO_UNIDAD_MOV = SKU.CODIGO_UNIDAD_SKU ' +
          ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
          '   AND M.CODIGO_ALM_MOV IN (' + sAlms + ') ' +
          '   AND M.ESACTIVO_MOV   = ''S'' ';
        case AEstado of
          esEntradas:      Result := Result + '   AND M.TIPO_MOV = ''E'' ';
          esSalidas:       Result := Result + '   AND M.TIPO_MOV = ''S'' ' +
                                              '   AND M.TIPO_DOC_MOV IN (''TR'',''AT'') ';
          esVentas:        Result := Result + '   AND M.TIPO_DOC_MOV = ''VE'' ';
          esRegularizadas: Result := Result + '   AND M.TIPO_DOC_MOV = ''IN'' ';
        end;
        Result := Result +
          ' GROUP BY SKU.CODIGO_UNIDAD_SKU, M.CODIGO_ALM_MOV';
      end;
  else
    // esPrestadas / esTodoAlaVez no se construyen aqui directamente:
    // - esPrestadas: stub vacio (queda para futura iteracion).
    // - esTodoAlaVez: lo agrega EstadoBaseSelect como UNION ALL.
    Result :=
      'SELECT ''''       AS CODIGO_UNIDAD_SKU, ' +
      '       NULL       AS COLOR_AV, ' +
      '       NULL       AS TALLA_AV, ' +
      '       0          AS ORDEN_TALLA, ' +
      '       ''''       AS ALM, ' +
      '       0          AS CANTIDAD, ' +
      '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
      '  FROM dual WHERE 0';
  end;
end;

// En modo "Todo a la vez" hace UNION ALL de los 7 estados con datos
// reales (existencias, entradas, salidas, ventas, regularizadas, pte.
// recibir, pte. servir). esPrestadas queda fuera por ser stub.
function TfrmStockConsulta.EstadoBaseSelect: string;
const
  ESTADOS_TODO: array[0..6] of TEstadoStock = (
    esExistencias, esEntradas, esSalidas, esVentas, esRegularizadas,
    esPdteRecibir, esPdteServir);
var
  i: Integer;
begin
  if EstadoActual <> esTodoAlaVez then
  begin
    Result := EstadoBaseSelectFor(EstadoActual);
    Exit;
  end;
  Result := '';
  for i := Low(ESTADOS_TODO) to High(ESTADOS_TODO) do
  begin
    if Result <> '' then Result := Result + ' UNION ALL ';
    Result := Result + '(' + EstadoBaseSelectFor(ESTADOS_TODO[i]) + ')';
  end;
end;

// ---------------------------------------------------------------------------
//  Build SQL pivote: rows=almacenes o colores, cols=tallas
// ---------------------------------------------------------------------------
// Las TALLAS van SIEMPRE como columnas dinamicas (T0..Tn-1). Las filas son
// almacenes marcados en clbAlmacenes (modo Por Almacen) o colores marcados
// en clbColores (modo Por Color). El filtro de la dimension "no activa" se
// aplica como filtro adicional sobre B:
//   * Por Color  -> almacenes se filtran ya en EstadoBaseSelect.
//   * Por Almacen-> los colores marcados se filtran en el JOIN ON B.COLOR_AV.
// HEX viaja en la columna de filas para que el custom-draw del cuadradito
// pinte el swatch en modo Por Color; en Por Almacen queda vacio.
function TfrmStockConsulta.ConstruirSQLPivot(
  const ATallas: TArray<TInfoColumna>; AEsColor: Boolean): string;
var
  sBase, sCols, sOuter, sJoin, sGroup, sOrder, sWhere: string;
  sFiltroColores: string;
  sExtraSel, sExtraGroup, sExtraOrder: string;
  bEsTodo: Boolean;
  i: Integer;
  alms: TArray<string>;
begin
  sBase   := EstadoBaseSelect;
  bEsTodo := EstadoActual = esTodoAlaVez;
  sCols   := '';
  for i := 0 to High(ATallas) do
    sCols := sCols + Format(', SUM(CASE WHEN B.TALLA_AV = %s THEN B.CANTIDAD ELSE 0 END) AS T%d',
                            [QuotedStr(ATallas[i].Codigo), i]);
  sFiltroColores := ColoresSeleccionadosSQL;

  // En modo "Todo a la vez" el pivote agrupa ademas por ESTADO_NUM:
  // cada fila de grupo (almacen o color) se desdobla en una fila por
  // estado con datos. Los grupos sin ningun dato (LEFT JOIN sin match)
  // se descartan filtrando B.ESTADO_NUM IS NOT NULL — sino saldria una
  // fila con ESTADO_NUM=NULL por cada grupo vacio.
  if bEsTodo then
  begin
    sExtraSel   := ', B.ESTADO_NUM AS ESTADO_NUM';
    sExtraGroup := ', B.ESTADO_NUM';
    sExtraOrder := ', B.ESTADO_NUM';
  end
  else
  begin
    sExtraSel   := '';
    sExtraGroup := '';
    sExtraOrder := '';
  end;

  if AEsColor then
  begin
    // Filas = colores marcados en clbColores. Dedupe por AV.AV (varios
    // ID_AV pueden compartir el mismo nombre de color).
    sOuter :=
      '(SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV, ' +
      '        MIN(AV.ID_ATB_AV) AS ID_ATB_AV ' +
      '   FROM fza_articulos_skus SKU ' +
      '   JOIN fza_atributos_sku SA ' +
      '     ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '   JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      '  WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
      '    AND AV.ID_VA_AV = ''CO''' +
      '    AND AV.AV IN (' + sFiltroColores + ') ' +
      '  GROUP BY AV.AV) C';
    sJoin :=
      ' LEFT JOIN fza_atributos_basicos ATB ON ATB.ID_ATB = C.ID_ATB_AV ' +
      ' LEFT JOIN (' + sBase + ') B ON B.COLOR_AV = C.AV';
    if bEsTodo then
      sWhere := ' WHERE B.ESTADO_NUM IS NOT NULL '
    else
      sWhere := '';
    sGroup := ' GROUP BY C.AV, ATB.HEX_ATB, C.ORDEN_AV' + sExtraGroup;
    sOrder := ' ORDER BY C.ORDEN_AV, C.AV' + sExtraOrder;
    Result :=
      'SELECT C.AV AS GRUPO, COALESCE(ATB.HEX_ATB, '''') AS HEX, ' +
      '       C.ORDEN_AV AS ORDEN' + sExtraSel + sCols +
      ', SUM(B.CANTIDAD) AS TOTAL ' +
      '  FROM ' + sOuter + sJoin + sWhere + sGroup + sOrder;
  end
  else
  begin
    // Filas = almacenes marcados. Filtro de colores se aplica al
    // subselect B via JOIN ON.
    alms := AlmacenesSeleccionadosLista;
    if Length(alms) = 0 then
    begin
      Result := 'SELECT '''' AS GRUPO, '''' AS HEX, 0 AS ORDEN' +
                IfThen(bEsTodo, ', 0 AS ESTADO_NUM', '') +
                sCols + ', 0 AS TOTAL FROM dual WHERE 0';
      Exit;
    end;
    Result :=
      'SELECT ALM.CODIGO_ALM_ALM AS GRUPO, '''' AS HEX, ' +
      '       ALM.ORDEN_ALM AS ORDEN' + sExtraSel + sCols +
      ', SUM(B.CANTIDAD) AS TOTAL ' +
      '  FROM fza_almacenes ALM ' +
      '  LEFT JOIN (' + sBase + ') B ' +
      '    ON B.ALM = ALM.CODIGO_ALM_ALM ' +
      '   AND B.COLOR_AV IN (' + sFiltroColores + ') ' +
      ' WHERE ALM.CODIGO_ALM_ALM IN (' + AlmacenesSeleccionadosSQL + ') ' +
      IfThen(bEsTodo, '   AND B.ESTADO_NUM IS NOT NULL ', '') +
      ' GROUP BY ALM.CODIGO_ALM_ALM, ALM.ORDEN_ALM' + sExtraGroup + ' ' +
      ' ORDER BY ALM.ORDEN_ALM, ALM.CODIGO_ALM_ALM' + sExtraOrder;
  end;
end;

// ---------------------------------------------------------------------------
//  Reconstruir columnas dinamicas del grid
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
//  Tallas del articulo (columnas dinamicas del grid)
// ---------------------------------------------------------------------------
function TfrmStockConsulta.TallasArticulo: TArray<TInfoColumna>;
var
  q: TUniQuery;
  inf: TInfoColumna;
  iAcPivot: Integer;
begin
  SetLength(Result, 0);
  if Trim(FCodArt) = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;

    // 1. Conjunto pivot (tallas) asignado al articulo. Si la asignacion
    //    tiene varios candidatos no-color, cogemos el primero por
    //    ID_VA_ACA. Si el articulo no tiene asignacion, fallback en (2).
    q.SQL.Text :=
      'SELECT ID_AC_ACA FROM fza_articulos_conjuntos_asign ' +
      ' WHERE CODIGO_ART_ACA = :art ' +
      '   AND ID_VA_ACA <> ''CO'' ' +
      ' ORDER BY ID_VA_ACA LIMIT 1';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    iAcPivot := 0;
    if not q.IsEmpty then iAcPivot := q.FieldByName('ID_AC_ACA').AsInteger;
    q.Close;

    if iAcPivot > 0 then
    begin
      // 1b. Todas las tallas del conjunto, en orden. Salen TODAS aunque
      //     algunas no tengan SKUs/stock — el pivote las muestra a 0.
      q.SQL.Text :=
        'SELECT AV.AV, AV.ORDEN_AV ' +
        '  FROM fza_atributos_conjuntos_det ACD ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
        ' WHERE ACD.ID_AC_ACD = :ac ' +
        ' ORDER BY ACD.ORDEN_ACD, AV.AV';
      q.ParamByName('ac').AsInteger := iAcPivot;
    end
    else
    begin
      // 2. Fallback: tallas presentes en SKUs del articulo (puede ser
      //    incompleto pero al menos muestra lo que hay).
      q.SQL.Text :=
        'SELECT DISTINCT AV.AV, AV.ORDEN_AV ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        ' WHERE SKU.CODIGO_ART_SKU = :art ' +
        '   AND AV.ID_VA_AV <> ''CO'' ' +
        ' ORDER BY AV.ORDEN_AV, AV.AV';
      q.ParamByName('art').AsString := FCodArt;
    end;
    q.Open;
    while not q.Eof do
    begin
      inf := Default(TInfoColumna);
      inf.Codigo  := q.FieldByName('AV').AsString;
      inf.Texto   := q.FieldByName('AV').AsString;
      inf.Hex     := '';
      inf.EsColor := False;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := inf;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function HexAColor(const AHex: string; out AColor: TColor): Boolean;
var
  s: string;
begin
  Result := False;
  AColor := clBlack;
  s := AHex;
  if (Length(s) > 0) and (s[1] = '#') then Delete(s, 1, 1);
  if Length(s) <> 6 then Exit;
  AColor := RGB(StrToIntDef('$' + Copy(s, 1, 2), 0),
                StrToIntDef('$' + Copy(s, 3, 2), 0),
                StrToIntDef('$' + Copy(s, 5, 2), 0));
  Result := True;
end;

procedure TfrmStockConsulta.ReconstruirColumnas(
  const ATallas: TArray<TInfoColumna>; AEsColor: Boolean);
var
  i: Integer;
  col, colTotal: TcxGridDBColumn;
begin
  // Borrar columnas dinamicas anteriores (no hay columnas fijas: todo
  // se crea en este metodo y se libera al volver a llamar).
  for i := FColsDin.Count - 1 downto 0 do
    FColsDin[i].Free;
  FColsDin.Clear;
  FColGrupo    := nil;
  FColEstado   := nil;
  FEsModoColor := AEsColor;
  FEsModoTodo  := EstadoActual = esTodoAlaVez;

  // Columna principal de fila: nombre del color o codigo del almacen.
  // En modo Por Color, tvStockCustomDrawCell pinta el cuadradito del
  // color basico a la izquierda del texto, via inLibAtributosPaleta.
  // En modo Por Almacen, se muestra el codigo del almacen plano.
  FColGrupo := tvStock.CreateColumn;
  if AEsColor then FColGrupo.Caption := 'Color'
  else             FColGrupo.Caption := 'Almacén';
  FColGrupo.DataBinding.FieldName := 'GRUPO';
  if AEsColor then
    FColGrupo.Width := 150  // espacio extra para el cuadradito
  else
    FColGrupo.Width := 130;
  FColGrupo.HeaderAlignmentHorz := taLeftJustify;
  FColGrupo.Options.Sorting := False;
  FColsDin.Add(FColGrupo);

  // Columna "Estado" — solo en modo Todo a la vez. Bindeada al campo
  // numerico ESTADO_NUM pero el texto visible lo pinta el OnCustomDrawCell
  // a traves de NombreEstadoCorto (asi evitamos meter strings en el SQL).
  if FEsModoTodo then
  begin
    FColEstado := tvStock.CreateColumn;
    FColEstado.Caption := 'Estado';
    FColEstado.DataBinding.FieldName := 'ESTADO_NUM';
    FColEstado.Width := 110;
    FColEstado.HeaderAlignmentHorz := taLeftJustify;
    FColEstado.Options.Sorting := False;
    FColsDin.Add(FColEstado);
  end;

  // Tallas: columnas dinamicas T0..Tn-1.
  for i := 0 to High(ATallas) do
  begin
    col := tvStock.CreateColumn;
    col.Caption := ATallas[i].Texto;
    col.DataBinding.FieldName := Format('T%d', [i]);
    col.PropertiesClassName := 'TcxCurrencyEditProperties';
    TcxCurrencyEditProperties(col.Properties).DisplayFormat := '#,##0.##;-#,##0.##;0';
    TcxCurrencyEditProperties(col.Properties).UseDisplayFormatWhenEditing := True;
    col.HeaderAlignmentHorz := taCenter;
    col.Width := 60;
    col.Options.Editing := False;
    col.Options.Sorting := False;
    FColsDin.Add(col);
  end;

  // Total al final.
  colTotal := tvStock.CreateColumn;
  colTotal.Caption := 'Total';
  colTotal.DataBinding.FieldName := 'TOTAL';
  colTotal.PropertiesClassName := 'TcxCurrencyEditProperties';
  TcxCurrencyEditProperties(colTotal.Properties).DisplayFormat := '#,##0.##;-#,##0.##;0';
  TcxCurrencyEditProperties(colTotal.Properties).UseDisplayFormatWhenEditing := True;
  colTotal.HeaderAlignmentHorz := taCenter;
  colTotal.Width := 70;
  colTotal.Options.Editing := False;
  colTotal.Options.Sorting := False;
  FColsDin.Add(colTotal);

  FColumnas := Copy(ATallas);
end;

// ---------------------------------------------------------------------------
//  Custom-draw de la columna Color en modo Por Color: delega en la libreria
//  inLibAtributosPaleta.PintarCeldaSwatchSiAplica, que ya hace el lookup
//  contra fza_atributos_basicos (incluido el matching por texto cuando el
//  AV no tiene ID_ATB_AV) y pinta el cuadradito a la izquierda + el texto
//  desplazado a la derecha. Misma libreria que usa caja/inventarios.
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.tvStockCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  vEstNum   : Variant;
  iEstNum   : Integer;
  estadoCol : TEstadoStock;
begin
  ADone := False;
  if not (AViewInfo.Item is TcxGridDBColumn) then Exit;

  // Estado correspondiente a la fila:
  //  - En modo "Todo a la vez" lo lee del campo ESTADO_NUM de la fila.
  //  - En cualquier otro modo es EstadoActual (todas las filas comparten).
  estadoCol := EstadoActual;
  if FEsModoTodo and (FColEstado <> nil) and (AViewInfo.GridRecord <> nil) then
  begin
    vEstNum := AViewInfo.GridRecord.Values[FColEstado.Index];
    iEstNum := StrToIntDef(VarToStr(vEstNum), -1);
    if (iEstNum >= Ord(Low(TEstadoStock))) and
       (iEstNum <= Ord(High(TEstadoStock))) then
      estadoCol := TEstadoStock(iEstNum);
  end;

  if AViewInfo.Item = FColGrupo then
  begin
    // Columna de filas (Color/Almacen): swatch en modo Por Color.
    if FEsModoColor then
      if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
        ADone := True;
    Exit;
  end;

  // Columna Estado: mostramos el nombre corto en lugar del numero.
  if FEsModoTodo and (FColEstado <> nil) and (AViewInfo.Item = FColEstado) then
  begin
    AViewInfo.Params.Text      := NombreEstadoCorto(estadoCol);
    AViewInfo.Params.TextColor := ColorEstado(estadoCol);
    Exit;
  end;

  // Resto de columnas (T0..Tn y TOTAL): pinta el numero en el color del
  // estado de la fila (en modo normal todas las filas tienen el mismo
  // estado activo; en modo Todo a la vez cada fila lleva su color).
  AViewInfo.Params.TextColor := ColorEstado(estadoCol);
end;

// ---------------------------------------------------------------------------
//  Cuadradito de color en la cabecera: pintamos las celdas de datos de
//  la columna con el HEX como background (sustituye al custom-draw del
//  header, que dependia de un API de DevExpress no portable). El
//  usuario reconoce el color por la franja de fondo de su columna.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
//  RecargarConsulta
// ---------------------------------------------------------------------------
function TfrmStockConsulta.EstadoActual: TEstadoStock;
begin
  case cbbEstado.ItemIndex of
    0: Result := esExistencias;
    1: Result := esEntradas;
    2: Result := esSalidas;
    3: Result := esVentas;
    4: Result := esRegularizadas;
    5: Result := esPdteRecibir;
    6: Result := esPdteServir;
    7: Result := esPrestadas;
    8: Result := esTodoAlaVez;
  else
    Result := esExistencias;
  end;
end;

procedure TfrmStockConsulta.RecargarConsulta;
var
  tallas  : TArray<TInfoColumna>;
  bEsColor: Boolean;
begin
  if FQry.Active then FQry.Close;
  bEsColor := pcVistas.ActivePage = tsPorColor;

  if Trim(FCodArt) = '' then
  begin
    ReconstruirColumnas([], bEsColor);
    FQry.SQL.Text := 'SELECT '''' AS GRUPO, '''' AS HEX, 0 AS ORDEN, ' +
                     '0 AS TOTAL FROM dual WHERE 0';
    FQry.Open;
    Exit;
  end;

  tallas := TallasArticulo;
  ReconstruirColumnas(tallas, bEsColor);
  FQry.SQL.Text := ConstruirSQLPivot(tallas, bEsColor);
  FQry.Open;
end;

// ---------------------------------------------------------------------------
//  Busqueda de articulos (popup del boton "...")
// ---------------------------------------------------------------------------
// Lanza TfrmMtoSearch (via TBusquedaUtils.EjecutarBusqueda) listando los
// articulos activos con columnas Codigo / Descripcion / Familia / Temporada
// / Proveedor ppal. / PVP. El PVP se calcula con una correlated subquery
// para garantizar UNA fila por articulo (en vez de unirse a
// fza_articulos_tarifas que da N filas si el articulo tiene varias
// tarifas). Mismo patron que TfrmMtoOpeCaja.BuscarArticulo pero sin filtro
// por tarifa/fecha (la consulta de stock es generica). Layout persistido
// bajo el Name 'frmMtoArtStockSearch' (independiente del de caja).
function TfrmStockConsulta.BuscarArticulo: string;

  procedure ConfigCampo(F: TField; const ALabel, AFormat: string);
  begin
    if F = nil then Exit;
    if ALabel <> '' then F.DisplayLabel := ALabel;
    if AFormat = '' then Exit;
    if F is TFloatField then
      TFloatField(F).DisplayFormat := AFormat
    else if F is TBCDField then
      TBCDField(F).DisplayFormat := AFormat
    else if F is TFMTBCDField then
      TFMTBCDField(F).DisplayFormat := AFormat;
  end;

var
  q: TUniQuery;
begin
  Result := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT'                                                       + sLineBreak +
      '    a.CODIGO_ART_ART,'                                        + sLineBreak +
      '    a.DESCRIPCION_ART,'                                       + sLineBreak +
      '    f.DESCRIPCION_FAM,'                                       + sLineBreak +
      '    pv.PV                      AS TEMPORADA,'                 + sLineBreak +
      '    p.RAZON_SOCIAL_PRV         AS PROVEEDOR,'                 + sLineBreak +
      '    (SELECT t.PRECIO_FINAL_ARTTAR'                            + sLineBreak +
      '       FROM fza_articulos_tarifas t'                          + sLineBreak +
      '       JOIN fza_tarifas tt'                                   + sLineBreak +
      '         ON tt.CODIGO_TAR_ARTTAR = t.CODIGO_TAR_ARTTAR'       + sLineBreak +
      '      WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART'           + sLineBreak +
      '        AND IFNULL(t.CODIGO_UNIDAD_ARTTAR, '''') = '''''      + sLineBreak +
      '        AND t.ESACTIVO_ARTTAR = ''S'''                        + sLineBreak +
      '        AND tt.ESDEFAULT_TAR = ''S'''                         + sLineBreak +
      '      LIMIT 1)                 AS PRECIO_PVP'                 + sLineBreak +
      'FROM fza_articulos a'                                         + sLineBreak +
      'LEFT JOIN fza_articulos_familias f'                           + sLineBreak +
      '       ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART'                + sLineBreak +
      'LEFT JOIN fza_articulos_propiedades ap'                       + sLineBreak +
      '       ON ap.CODIGO_ART_ART = a.CODIGO_ART_ART'               + sLineBreak +
      '      AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'''             + sLineBreak +
      'LEFT JOIN fza_propiedades_valores pv'                         + sLineBreak +
      '       ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'                + sLineBreak +
      'LEFT JOIN fza_articulos_proveedores aprv'                     + sLineBreak +
      '       ON aprv.CODIGO_ART_AP = a.CODIGO_ART_ART'              + sLineBreak +
      '      AND aprv.ESPROVEEDORPRINCIPAL_AP = ''S'''               + sLineBreak +
      'LEFT JOIN fza_proveedores p'                                  + sLineBreak +
      '       ON p.CODIGO_PRV_PRV = aprv.CODIGO_PRV_AP'              + sLineBreak +
      'WHERE a.ESACTIVO_ART = ''S'''                                 + sLineBreak +
      'ORDER BY a.CODIGO_ART_ART';

    q.Open;
    ConfigCampo(q.FindField('CODIGO_ART_ART'),  'Código',      '');
    ConfigCampo(q.FindField('DESCRIPCION_ART'), 'Descripción', '');
    ConfigCampo(q.FindField('DESCRIPCION_FAM'), 'Familia',     '');
    ConfigCampo(q.FindField('TEMPORADA'),       'Temporada',   '');
    ConfigCampo(q.FindField('PROVEEDOR'),       'Proveedor',   '');
    ConfigCampo(q.FindField('PRECIO_PVP'),      'PVP',         '#,##0.00 €');

    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos',
                                       q,
                                       'frmMtoArtStockSearch') then
      Result := q.FieldByName('CODIGO_ART_ART').AsString;
  finally
    FreeAndNil(q);
  end;
end;

// ---------------------------------------------------------------------------
//  Events
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.btnArtPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  sCodigo: string;
begin
  sCodigo := BuscarArticulo;
  if sCodigo <> '' then
    SetArticuloSku(sCodigo, '');
end;

procedure TfrmStockConsulta.btnArtPropertiesEditValueChanged(Sender: TObject);
begin
  SetArticuloSku(Trim(btnArt.Text), '');
end;

procedure TfrmStockConsulta.cbbEstadoPropertiesEditValueChanged(Sender: TObject);
begin
  cbbEstado.Style.TextColor := ColorEstado(EstadoActual);
  RecargarConsulta;
end;

procedure TfrmStockConsulta.clbAlmacenesClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.clbColoresClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.pcVistasChange(Sender: TObject);
begin
  RecargarConsulta;
end;

initialization
  frmStockConsulta := nil;

end.
