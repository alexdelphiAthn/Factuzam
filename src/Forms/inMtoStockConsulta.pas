{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (flotante, alStayOnTop opcional)                   }
{ Version:       0.1.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Consulta de stock invocable con Ctrl+U desde cualquier mantenimiento      }
{    que herede de TfrmMtoGen. Al abrirse pre-carga el articulo / SKU activo   }
{    via TfrmMtoGen.ResolverArtSkuActivo. Pantalla pensada como referencia     }
{    rapida (similar a inMtoFotoArticulo).                                     }
{                                                                              }
{      - Cabecera: campo Articulo (texto + busqueda), descripcion, foto.       }
{      - Combo "Estado del stock": Existencias / Entradas / Salidas /          }
{        Ventas / Regularizadas / Pdte. recibir / Pdte. servir / Prestadas.    }
{      - Pestanas Por Color / Por Almacen para alternar eje de filas.          }
{      - Check-list de almacenes (default los TIPO_USO 'ESTANDAR').            }
{                                                                              }
{    v0.1: solo estado "Existencias" implementado contra                       }
{    fza_articulos_stockactual. Grid plano (sin pivot de tallas). El pivot     }
{    estilo caja y los demas estados quedan para iteracion siguiente.          }
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
  dxDateRanges;

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

  TfrmStockConsulta = class(TForm)
    pnlCabecera   : TPanel;
      lblArt        : TcxLabel;
      btnArt        : TcxButtonEdit;
      lblDescr      : TcxLabel;
      imgFoto       : TImage;
    pnlFiltros    : TPanel;
      lblEstado     : TcxLabel;
      cbbEstado     : TcxComboBox;
    grdStock      : TcxGrid;
      tvStock       : TcxGridDBTableView;
      glStock       : TcxGridLevel;
      colSku        : TcxGridDBColumn;
      colColorAv    : TcxGridDBColumn;
      colTallaAv    : TcxGridDBColumn;
      colAlmacen    : TcxGridDBColumn;
      colCantidad   : TcxGridDBColumn;
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
  private
    FQry        : TUniQuery;
    FDs         : TDataSource;
    FCodArt     : string;
    FCodSku     : string;
    procedure CargarAlmacenes;
    procedure CargarFoto;
    function  EstadoActual: TEstadoStock;
    procedure RecargarConsulta;
    function  AlmacenesSeleccionados: string;  // 'CODA','CODB',...
  public
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
  end;

var
  frmStockConsulta: TfrmStockConsulta;

/// Abre (o trae al frente) la consulta de stock con el (articulo, sku)
/// indicado. Si la ventana ya existe la reutiliza. Mismo patron que
/// inMtoFotoArticulo.MostrarFotoFlotante.
procedure MostrarStockConsulta(AOwner: TComponent;
                               const ACodArt, ACodSku: string);

implementation

uses
  inLibGlobalVar, inLibFotos;

{$R *.dfm}

const
  cTallaInactiva = $00E8E8E8;

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

  // Combo de estados — orden y captions a mostrar
  cbbEstado.Properties.Items.Clear;
  cbbEstado.Properties.Items.Add('Existencias');
  cbbEstado.Properties.Items.Add('Entradas');
  cbbEstado.Properties.Items.Add('Salidas');
  cbbEstado.Properties.Items.Add('Ventas');
  cbbEstado.Properties.Items.Add('Regularizadas');
  cbbEstado.Properties.Items.Add('Pdte. de recibir');
  cbbEstado.Properties.Items.Add('Pdte. de servir');
  cbbEstado.Properties.Items.Add('Prestadas');
  cbbEstado.ItemIndex := 0;  // Existencias por defecto

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
end;

procedure TfrmStockConsulta.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // No liberamos: la ventana sobrevive entre invocaciones (igual que
  // la foto flotante). Solo ocultamos.
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
      // Los almacenes ESTANDAR (admitimos 'ESTANDAR' y 'ESTANDARD' por
      // datos historicos) van marcados por defecto. Depositos, transitos
      // y otros tipos especiales quedan sin marcar.
      bStd := (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDAR') or
              (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDARD');
      item.State := TcxCheckBoxState(Ord(bStd));
      // Guardamos el codigo del almacen en Tag para no parsearlo del texto
      item.Tag := 0;  // tag entero, no nos sirve para string
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmStockConsulta.AlmacenesSeleccionados: string;
var
  i  : Integer;
  s, sCod: string;
  p  : Integer;
begin
  Result := '';
  for i := 0 to clbAlmacenes.Items.Count - 1 do
    if clbAlmacenes.Items[i].State = cbsChecked then
    begin
      // El texto es "CODIGO - NOMBRE": el codigo es el prefijo hasta " - "
      s := clbAlmacenes.Items[i].Text;
      p := Pos(' - ', s);
      if p > 0 then sCod := Copy(s, 1, p - 1) else sCod := s;
      if Result <> '' then Result := Result + ',';
      Result := Result + '''' + sCod + '''';
    end;
end;

// ---------------------------------------------------------------------------
//  Carga de articulo / SKU + foto
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.SetArticuloSku(const ACodArt, ACodSku: string);
var
  q: TUniQuery;
begin
  FCodArt := ACodArt;
  FCodSku := ACodSku;
  btnArt.Text := ACodArt;

  // Descripcion del articulo
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

// ---------------------------------------------------------------------------
//  Estado del stock + consulta SQL
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
  sAlms, sSQL: string;
  est: TEstadoStock;
begin
  if FQry.Active then FQry.Close;
  if Trim(FCodArt) = '' then
  begin
    FQry.SQL.Text := 'SELECT 1 WHERE 0';
    FQry.Open;
    Exit;
  end;
  sAlms := AlmacenesSeleccionados;
  if sAlms = '' then sAlms := 'NULL';
  est := EstadoActual;

  case est of
    esExistencias:
      // Lectura directa de la tabla agregada de stock. Sumamos por
      // (SKU, ALM) ignorando lotes.
      sSQL :=
        'SELECT STK.CODIGO_UNIDAD_STK AS CODIGO_UNIDAD_SKU, ' +
        '       STK.CODIGO_ALM_STK   AS CODIGO_ALM_ALM, ' +
        '       (SELECT GROUP_CONCAT(AV.AV ORDER BY AV.ID_VA_AV SEPARATOR '' / '') ' +
        '          FROM fza_atributos_sku SA ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        '         WHERE SA.CODIGO_UNIDAD_SKU_SA = STK.CODIGO_UNIDAD_STK ' +
        '           AND AV.ID_VA_AV = ''CO'')                  AS COLOR_AV, ' +
        '       (SELECT GROUP_CONCAT(AV.AV ORDER BY AV.ID_VA_AV SEPARATOR '' / '') ' +
        '          FROM fza_atributos_sku SA ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        '         WHERE SA.CODIGO_UNIDAD_SKU_SA = STK.CODIGO_UNIDAD_STK ' +
        '           AND AV.ID_VA_AV <> ''CO'')                 AS TALLA_AV, ' +
        '       SUM(STK.CANTIDAD_STK)                          AS CANTIDAD ' +
        '  FROM fza_articulos_stockactual STK ' +
        '  JOIN fza_articulos_skus SKU ' +
        '    ON SKU.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND STK.CODIGO_ALM_STK IN (' + sAlms + ') ' +
        ' GROUP BY STK.CODIGO_UNIDAD_STK, STK.CODIGO_ALM_STK ' +
        ' ORDER BY STK.CODIGO_UNIDAD_STK, STK.CODIGO_ALM_STK';
    esPdteRecibir:
      // Suma desde fza_articulos_pdte_recibir (nueva tabla) o desde
      // fza_articulos_stockactual.CANTIDAD_PTE_RECIBIR_STK. Usamos la
      // tabla nueva porque tiene granularidad por documento.
      sSQL :=
        'SELECT P.CODIGO_UNIDAD_PDR AS CODIGO_UNIDAD_SKU, ' +
        '       P.CODIGO_ALM_PDR   AS CODIGO_ALM_ALM, ' +
        '       (SELECT GROUP_CONCAT(AV.AV ORDER BY AV.ID_VA_AV SEPARATOR '' / '') ' +
        '          FROM fza_atributos_sku SA ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        '         WHERE SA.CODIGO_UNIDAD_SKU_SA = P.CODIGO_UNIDAD_PDR ' +
        '           AND AV.ID_VA_AV = ''CO'') AS COLOR_AV, ' +
        '       (SELECT GROUP_CONCAT(AV.AV ORDER BY AV.ID_VA_AV SEPARATOR '' / '') ' +
        '          FROM fza_atributos_sku SA ' +
        '          JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        '         WHERE SA.CODIGO_UNIDAD_SKU_SA = P.CODIGO_UNIDAD_PDR ' +
        '           AND AV.ID_VA_AV <> ''CO'') AS TALLA_AV, ' +
        '       SUM(P.CANTIDAD_PDR) AS CANTIDAD ' +
        '  FROM fza_articulos_pdte_recibir P ' +
        ' WHERE P.CODIGO_ART_PDR = ' + QuotedStr(FCodArt) +
        '   AND P.CODIGO_ALM_PDR IN (' + sAlms + ') ' +
        ' GROUP BY P.CODIGO_UNIDAD_PDR, P.CODIGO_ALM_PDR';
    esPdteServir:
      sSQL :=
        'SELECT STK.CODIGO_UNIDAD_STK AS CODIGO_UNIDAD_SKU, ' +
        '       STK.CODIGO_ALM_STK   AS CODIGO_ALM_ALM, ' +
        '       NULL AS COLOR_AV, NULL AS TALLA_AV, ' +
        '       SUM(STK.CANTIDAD_PTE_SERVIR_STK) AS CANTIDAD ' +
        '  FROM fza_articulos_stockactual STK ' +
        '  JOIN fza_articulos_skus SKU ' +
        '    ON SKU.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK ' +
        ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
        '   AND STK.CODIGO_ALM_STK IN (' + sAlms + ') ' +
        ' GROUP BY STK.CODIGO_UNIDAD_STK, STK.CODIGO_ALM_STK';
    esEntradas, esSalidas, esVentas, esRegularizadas:
      // Sumamos cantidades sobre fza_movimientos_almacen filtrando por
      // TIPO_DOC / TIPO_MOV. Para entradas miramos todos los E (compras,
      // traspasos entrantes, regularizaciones positivas). Salidas /
      // ventas / regularizadas son distintos TIPO_DOC.
      sSQL :=
        'SELECT M.CODIGO_UNIDAD_MOV AS CODIGO_UNIDAD_SKU, ' +
        '       M.CODIGO_ALM_MOV   AS CODIGO_ALM_ALM, ' +
        '       NULL AS COLOR_AV, NULL AS TALLA_AV, ' +
        '       SUM(M.CANTIDAD_MOV) AS CANTIDAD ' +
        '  FROM fza_movimientos_almacen M ' +
        ' WHERE M.CODIGO_ART_MOV = ' + QuotedStr(FCodArt) +
        '   AND M.CODIGO_ALM_MOV IN (' + sAlms + ') ' +
        '   AND M.ESACTIVO_MOV   = ''S'' ' +
        (function: string
         begin
           case est of
             esEntradas:      Result := '   AND M.TIPO_MOV = ''E'' ';
             esSalidas:       Result := '   AND M.TIPO_MOV = ''S'' ' +
                                        '   AND M.TIPO_DOC_MOV IN (''TR'',''AT'') ';
             esVentas:        Result := '   AND M.TIPO_DOC_MOV = ''VE'' ';
             esRegularizadas: Result := '   AND M.TIPO_DOC_MOV = ''IN'' ';
           else Result := '';
           end;
         end)() +
        ' GROUP BY M.CODIGO_UNIDAD_MOV, M.CODIGO_ALM_MOV';
    esPrestadas:
      // TODO: depende de tabla / flujo de prestamos. De momento devuelve
      // vacio para no enganarse con datos.
      sSQL := 'SELECT NULL AS CODIGO_UNIDAD_SKU, NULL AS CODIGO_ALM_ALM, ' +
              '       NULL AS COLOR_AV, NULL AS TALLA_AV, ' +
              '       0 AS CANTIDAD FROM dual WHERE 0';
  end;

  FQry.SQL.Text := sSQL;
  FQry.Open;
end;

// ---------------------------------------------------------------------------
//  Events
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.btnArtPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  // TODO: abrir picker de articulos. Por ahora solo se acepta el texto
  // que el usuario teclee como CODIGO_ART y se recarga al cambiar.
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
  // El cambio de pestana solo afecta a la presentacion (agrupacion del
  // grid) — los datos de fondo son los mismos. v0.1 no agrupa todavia.
  RecargarConsulta;
end;

initialization

finalization
  if Assigned(frmStockConsulta) then
    FreeAndNil(frmStockConsulta);

end.
