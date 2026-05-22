{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (flotante, fsStayOnTop)                            }
{ Version:       0.2.0                                                         }
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
{    Layout:                                                                   }
{      - Cabecera: Articulo + descripcion + bloque de precios (PVP / otras     }
{        tarifas / coste / proveedor[es]) + foto a la derecha.                 }
{      - Filtros: combo "Estado del stock".                                    }
{      - Grid pivot: tallas en filas, almacenes o colores en columnas. Las     }
{        columnas de color llevan un cuadradito HEX al lado del nombre.        }
{      - Eje: pestanas "Por Color" / "Por Almacen" (default Almacen) + lista   }
{        de almacenes (TIPO_USO='ESTANDAR' marcados por defecto).              }
{                                                                              }
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
  cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxGraphics, cxLocalization,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxScrollbarAnnotations,
  dxDateRanges, cxMemo;

type
  TEstadoStock = (
    esExistencias,
    esEntradas,
    esSalidas,
    esVentas,
    esRegularizadas,
    esPdteRecibir,
    esPdteServir,
    esPrestadas
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
    grdStock      : TcxGrid;
      tvStock       : TcxGridDBTableView;
      glStock       : TcxGridLevel;
      colTalla      : TcxGridDBColumn;
    pnlEjes       : TPanel;
      pcEje         : TcxPageControl;
        tsPorColor    : TcxTabSheet;
        tsPorAlmacen  : TcxTabSheet;
      lblAlmacenes  : TcxLabel;
      clbAlmacenes  : TcxCheckListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnArtPropertiesButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure btnArtPropertiesEditValueChanged(Sender: TObject);
    procedure cbbEstadoPropertiesEditValueChanged(Sender: TObject);
    procedure clbAlmacenesClickCheck(Sender: TObject; AIndex: Integer;
              APrevState, ANewState: TcxCheckBoxState);
    procedure pcEjeChange(Sender: TObject);
    procedure tvStockCustomDrawColumnHeader(Sender: TcxGridTableView;
              ACanvas: TcxCanvas; AViewInfo: TcxGridColumnHeaderViewInfo;
              var ADone: Boolean);
  private
    FQry        : TUniQuery;
    FDs         : TDataSource;
    FCodArt     : string;
    FCodSku     : string;
    FColumnas   : TArray<TInfoColumna>;  // Codigo + Texto + Hex por columna
    FColsDin    : TList<TcxGridDBColumn>;
    procedure CargarAlmacenes;
    procedure CargarFoto;
    procedure CargarInfoPrecios;
    function  EstadoActual: TEstadoStock;
    function  AlmacenesSeleccionadosSQL: string;  // 'CODA','CODB' o NULL
    function  AlmacenesSeleccionadosLista: TArray<string>;
    function  ColoresArticulo: TArray<TInfoColumna>;
    function  ConstruirSQLPivot(const AColumnas: TArray<TInfoColumna>;
                                 AEsColor: Boolean): string;
    function  EstadoBaseSelect: string;  // CTE/source segun estado
    procedure ReconstruirColumnas(const AColumnas: TArray<TInfoColumna>);
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
  inLibGlobalVar, inLibFotos;

{$R *.dfm}

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
  cbbEstado.ItemIndex := 0;

  pcEje.ActivePage := tsPorAlmacen;
  CargarAlmacenes;
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
  CargarInfoPrecios;
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

procedure TfrmStockConsulta.CargarInfoPrecios;
var
  q   : TUniQuery;
  sb  : TStringList;
  hayDef: Boolean;
begin
  lblInfo.Caption := '';
  if Trim(FCodArt) = '' then Exit;

  sb := TStringList.Create;
  q  := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;

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
      ' ORDER BY T.ESDEFAULT_TAR DESC, T.ORDEN_TAR, T.NOMBRE_TAR_TAR';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    hayDef := False;
    while not q.Eof do
    begin
      if (not hayDef) and (q.FieldByName('ESDEFAULT_TAR').AsString = 'S') then
      begin
        sb.Add(Format('PVP (%s): %s',
          [q.FieldByName('NOMBRE_TAR_TAR').AsString,
           FormatFloat('#,##0.00', q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat)
           + ' '#8364]));
        hayDef := True;
      end
      else
        sb.Add(Format('  %s: %s',
          [q.FieldByName('NOMBRE_TAR_TAR').AsString,
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
      sb.Add(Format('%s %s%s: %s',
        [IfThen(q.FieldByName('ESPROVEEDORPRINCIPAL_AP').AsString = 'S',
                'Proveedor ppal.', 'Proveedor'),
         q.FieldByName('RAZON_SOCIAL_PRV').AsString,
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
//  Colores del articulo (para "Por Color")
// ---------------------------------------------------------------------------
function TfrmStockConsulta.ColoresArticulo: TArray<TInfoColumna>;
var
  q: TUniQuery;
  inf: TInfoColumna;
begin
  SetLength(Result, 0);
  if Trim(FCodArt) = '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // Distintos AV de color de los SKUs activos del articulo, con el
    // HEX_ATB del basico asociado (si lo hay) para pintar el cuadradito.
    q.SQL.Text :=
      'SELECT DISTINCT AV.AV, AV.ORDEN_AV, ATB.HEX_ATB ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_atributos_sku SA ' +
      '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      '  LEFT JOIN fza_atributos_basicos ATB ON ATB.ID_ATB = AV.ID_ATB_AV ' +
      ' WHERE SKU.CODIGO_ART_SKU = :art ' +
      '   AND AV.ID_VA_AV = ''CO'' ' +
      ' ORDER BY AV.ORDEN_AV, AV.AV';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    while not q.Eof do
    begin
      inf := Default(TInfoColumna);
      inf.Codigo  := q.FieldByName('AV').AsString;
      inf.Texto   := q.FieldByName('AV').AsString;
      inf.Hex     := q.FieldByName('HEX_ATB').AsString;
      inf.EsColor := True;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := inf;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

// ---------------------------------------------------------------------------
//  Estado: base SELECT (que va dentro del SUM(CASE WHEN ...))
// ---------------------------------------------------------------------------
// Devuelve un subselect que produce filas (CODIGO_UNIDAD_SKU, COLOR,
// TALLA, ALM, CANTIDAD). El pivote SQL exterior agrupa por TALLA y mete
// CASE-WHEN por COLOR o ALM en cada columna.
function TfrmStockConsulta.EstadoBaseSelect: string;
var
  est: TEstadoStock;
  sAlms: string;
begin
  est   := EstadoActual;
  sAlms := AlmacenesSeleccionadosSQL;
  case est of
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
        '       SUM(STK.CANTIDAD_STK) AS CANTIDAD ' +
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
        '       SUM(PDR.CANTIDAD_PDR) AS CANTIDAD ' +
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
        '       SUM(STK.CANTIDAD_PTE_SERVIR_STK) AS CANTIDAD ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_articulos_stockactual STK ' +
        '    ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND STK.CODIGO_ALM_STK IN (' + sAlms + ') ' +
        ' GROUP BY SKU.CODIGO_UNIDAD_SKU, STK.CODIGO_ALM_STK';
    esEntradas, esSalidas, esVentas, esRegularizadas:
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
        '       SUM(M.CANTIDAD_MOV) AS CANTIDAD ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_movimientos_almacen M ' +
        '    ON M.CODIGO_UNIDAD_MOV = SKU.CODIGO_UNIDAD_SKU ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND M.CODIGO_ALM_MOV IN (' + sAlms + ') ' +
        '   AND M.ESACTIVO_MOV   = ''S'' ';
      case est of
        esEntradas:      Result := Result + '   AND M.TIPO_MOV = ''E'' ';
        esSalidas:       Result := Result + '   AND M.TIPO_MOV = ''S'' ' +
                                            '   AND M.TIPO_DOC_MOV IN (''TR'',''AT'') ';
        esVentas:        Result := Result + '   AND M.TIPO_DOC_MOV = ''VE'' ';
        esRegularizadas: Result := Result + '   AND M.TIPO_DOC_MOV = ''IN'' ';
      end;
      Result := Result +
        ' GROUP BY SKU.CODIGO_UNIDAD_SKU, M.CODIGO_ALM_MOV';
  else
    // esPrestadas y otros: stub vacio
    Result :=
      'SELECT ''''       AS CODIGO_UNIDAD_SKU, ' +
      '       NULL       AS COLOR_AV, ' +
      '       NULL       AS TALLA_AV, ' +
      '       0          AS ORDEN_TALLA, ' +
      '       ''''       AS ALM, ' +
      '       0          AS CANTIDAD ' +
      '  FROM dual WHERE 0';
  end;
end;

// ---------------------------------------------------------------------------
//  Build SQL pivote: rows=talla, cols=almacenes o colores
// ---------------------------------------------------------------------------
function TfrmStockConsulta.ConstruirSQLPivot(
  const AColumnas: TArray<TInfoColumna>; AEsColor: Boolean): string;
var
  sBase, sCols, sCampoFiltro: string;
  i: Integer;
begin
  sBase := EstadoBaseSelect;
  if AEsColor then sCampoFiltro := 'COLOR_AV'
  else             sCampoFiltro := 'ALM';

  sCols := '';
  for i := 0 to High(AColumnas) do
  begin
    sCols := sCols + Format(', SUM(CASE WHEN B.%s = %s THEN B.CANTIDAD ELSE 0 END) AS C%d',
                            [sCampoFiltro, QuotedStr(AColumnas[i].Codigo), i]);
  end;

  Result :=
    'SELECT B.TALLA_AV AS TALLA, COALESCE(B.ORDEN_TALLA, 0) AS ORDEN' +
    sCols + ', SUM(B.CANTIDAD) AS TOTAL ' +
    '  FROM (' + sBase + ') B ' +
    ' WHERE B.TALLA_AV IS NOT NULL ' +
    ' GROUP BY B.TALLA_AV, COALESCE(B.ORDEN_TALLA, 0) ' +
    ' ORDER BY COALESCE(B.ORDEN_TALLA, 0), B.TALLA_AV';
end;

// ---------------------------------------------------------------------------
//  Reconstruir columnas dinamicas del grid
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.ReconstruirColumnas(
  const AColumnas: TArray<TInfoColumna>);
var
  i: Integer;
  col: TcxGridDBColumn;
  colTotal: TcxGridDBColumn;
begin
  // Borrar columnas dinamicas anteriores
  for i := FColsDin.Count - 1 downto 0 do
    FColsDin[i].Free;
  FColsDin.Clear;

  for i := 0 to High(AColumnas) do
  begin
    col := tvStock.CreateColumn;
    col.Caption := AColumnas[i].Texto;
    col.DataBinding.FieldName := Format('C%d', [i]);
    col.PropertiesClassName := 'TcxCurrencyEditProperties';
    col.HeaderAlignmentHorz := taCenter;
    col.Width := 90;
    col.Options.Editing := False;
    col.Options.Sorting := False;
    col.Tag := i;
    FColsDin.Add(col);
  end;

  // Columna Total al final
  colTotal := tvStock.CreateColumn;
  colTotal.Caption := 'Total';
  colTotal.DataBinding.FieldName := 'TOTAL';
  colTotal.PropertiesClassName := 'TcxCurrencyEditProperties';
  colTotal.HeaderAlignmentHorz := taCenter;
  colTotal.Width := 90;
  colTotal.Options.Editing := False;
  colTotal.Options.Sorting := False;
  colTotal.Tag := -1;  // marca Total para que no se dibuje swatch
  FColsDin.Add(colTotal);

  FColumnas := Copy(AColumnas);
end;

// ---------------------------------------------------------------------------
//  Header custom-draw: cuadradito de color al lado del nombre
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.tvStockCustomDrawColumnHeader(
  Sender: TcxGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridColumnHeaderViewInfo; var ADone: Boolean);
var
  col   : TcxGridDBColumn;
  idx   : Integer;
  inf   : TInfoColumna;
  rSwatch, rTexto : TRect;
  cFill : TColor;
  s     : string;
begin
  ADone := False;
  if not (AViewInfo.Item is TcxGridDBColumn) then Exit;
  col := TcxGridDBColumn(AViewInfo.Item);
  idx := col.Tag;
  if (idx < 0) or (idx > High(FColumnas)) then Exit;
  inf := FColumnas[idx];
  if (not inf.EsColor) or (inf.Hex = '') then Exit;

  // Fondo de cabecera + linea separadora inferior. Imitacion sencilla del
  // header standard del cxGrid; no usamos el LookAndFeelPainter porque
  // su API ha cambiado entre versiones de DevExpress.
  ACanvas.Brush.Color := $00F2F2F2;
  ACanvas.FillRect(AViewInfo.Bounds);
  ACanvas.Pen.Color := clBtnShadow;
  ACanvas.MoveTo(AViewInfo.Bounds.Left, AViewInfo.Bounds.Bottom - 1);
  ACanvas.LineTo(AViewInfo.Bounds.Right, AViewInfo.Bounds.Bottom - 1);

  // Cuadradito (14 x 14) centrado verticalmente, pegado a la izquierda.
  rSwatch := AViewInfo.Bounds;
  rSwatch.Left   := rSwatch.Left + 6;
  rSwatch.Right  := rSwatch.Left + 14;
  rSwatch.Top    := (AViewInfo.Bounds.Top + AViewInfo.Bounds.Bottom - 14)
                    div 2;
  rSwatch.Bottom := rSwatch.Top + 14;

  // HEX (#RRGGBB o RRGGBB) -> TColor (BBGGRR)
  s := inf.Hex;
  if (Length(s) > 0) and (s[1] = '#') then Delete(s, 1, 1);
  if Length(s) = 6 then
  begin
    cFill := RGB(StrToIntDef('$' + Copy(s, 1, 2), 0),
                 StrToIntDef('$' + Copy(s, 3, 2), 0),
                 StrToIntDef('$' + Copy(s, 5, 2), 0));
    ACanvas.Brush.Color := cFill;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.FillRect(rSwatch);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := clBlack;
    ACanvas.Rectangle(rSwatch);
    ACanvas.Brush.Style := bsSolid;
  end;

  // Texto a la derecha del cuadradito
  rTexto := AViewInfo.Bounds;
  rTexto.Left := rSwatch.Right + 4;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Assign(AViewInfo.Font);
  ACanvas.Font.Color := clBlack;
  DrawText(ACanvas.Handle, PChar(inf.Texto), Length(inf.Texto), rTexto,
           DT_VCENTER or DT_LEFT or DT_SINGLELINE);
  ACanvas.Brush.Style := bsSolid;

  ADone := True;
end;

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
  else
    Result := esExistencias;
  end;
end;

procedure TfrmStockConsulta.RecargarConsulta;
var
  cols  : TArray<TInfoColumna>;
  alms  : TArray<string>;
  i     : Integer;
  inf   : TInfoColumna;
  bEsColor: Boolean;
begin
  if FQry.Active then FQry.Close;
  if Trim(FCodArt) = '' then
  begin
    ReconstruirColumnas([]);
    FQry.SQL.Text := 'SELECT '''' AS TALLA, 0 AS ORDEN, 0 AS TOTAL FROM dual ' +
                     'WHERE 0';
    FQry.Open;
    Exit;
  end;

  bEsColor := pcEje.ActivePage = tsPorColor;
  if bEsColor then
    cols := ColoresArticulo
  else
  begin
    SetLength(cols, 0);
    alms := AlmacenesSeleccionadosLista;
    for i := 0 to High(alms) do
    begin
      inf := Default(TInfoColumna);
      inf.Codigo  := alms[i];
      inf.Texto   := alms[i];
      inf.Hex     := '';
      inf.EsColor := False;
      SetLength(cols, Length(cols) + 1);
      cols[High(cols)] := inf;
    end;
  end;

  ReconstruirColumnas(cols);
  FQry.SQL.Text := ConstruirSQLPivot(cols, bEsColor);
  FQry.Open;
end;

// ---------------------------------------------------------------------------
//  Events
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.btnArtPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  // TODO: picker de articulos con F3 (siguiente iteracion).
end;

procedure TfrmStockConsulta.btnArtPropertiesEditValueChanged(Sender: TObject);
begin
  SetArticuloSku(Trim(btnArt.Text), '');
end;

procedure TfrmStockConsulta.cbbEstadoPropertiesEditValueChanged(Sender: TObject);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.clbAlmacenesClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.pcEjeChange(Sender: TObject);
begin
  RecargarConsulta;
end;

initialization

finalization
  if Assigned(frmStockConsulta) then
    FreeAndNil(frmStockConsulta);

end.
