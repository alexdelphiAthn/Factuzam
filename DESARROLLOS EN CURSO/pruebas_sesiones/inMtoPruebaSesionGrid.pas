{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPruebaSesionGrid                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       0.1.0                                                         }
{   Fecha:       18/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Prueba 01 de la serie pruebas_sesiones: variante simplificada del Mto de  }
{    sesiones de compra. Una sola pestania de ficha con:                       }
{                                                                              }
{      - Cabecera: Empresa, Proveedor, Tarifa venta, Margen,                   }
{        Multiplo redondeo, Ajuste final.                                      }
{      - Grid de lineas (1 articulo = 1 linea) con Familia, Codigo articulo,   }
{        Descripcion, Color (libre), Color basico (selector paleta), Pr.       }
{        compra, Pr. venta (auto), Sistema tallas, Total tallas, Importe       }
{        total s/IVA.                                                          }
{      - Matriz de tallas debajo del grid (TGestorMatrizCompras).              }
{                                                                              }
{    Reutiliza:                                                                }
{      - TdmComprasSesiones (mapeado en fza_winforms).                         }
{      - inLibComprasSesiones.ResolverCodigoFamilia (atajo familia->codigo).   }
{      - inLibComprasSesiones.CalcularPrecioVenta (PVP propuesto al teclear    }
{        coste).                                                               }
{      - inLibComprasSesiones.TGestorMatrizCompras (matriz pivotada).          }
{      - inLibAtributosPaleta.SeleccionarAvConPaleta (selector de color       }
{        basico, mismo combo que el grid de inventarios).                      }
{      - TfrmModalSelFamilia (picker jerarquico, tecla F3).                    }
{                                                                              }
{    Documentado en                                                            }
{    DESARROLLOS EN CURSO/pruebas_sesiones/pruebas_sesiones.md.                }
{******************************************************************************}
unit inMtoPruebaSesionGrid;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.UITypes, System.Actions,
  Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni,
  cxClasses, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxDBEdit, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  cxDBNavigator, cxMemo, cxCheckBox, cxGroupBox, cxLocalization, cxGraphics,
  cxButtonEdit,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxSkinsDefaultPainters,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoGen,
  UniDataComprasSesiones;

type
  TfrmMtoPruebaSesionGrid = class(TfrmMtoGen)
    // ------------------------------------------------------------------
    // Columnas grid lista (tsLista, heredada)
    // ------------------------------------------------------------------
    dbcSerieSes              : TcxGridDBColumn;
    dbcNumeroSes             : TcxGridDBColumn;
    dbcFechaSes              : TcxGridDBColumn;
    dbcEstadoSes             : TcxGridDBColumn;
    dbcCodigoEmpSes          : TcxGridDBColumn;
    dbcCodigoPrvSes          : TcxGridDBColumn;
    dbcCodigoTarSes          : TcxGridDBColumn;
    dbcUsuarioAltaSes        : TcxGridDBColumn;

    // ------------------------------------------------------------------
    // Ficha — cabecera (settings)
    // ------------------------------------------------------------------
    gbCabecera               : TcxGroupBox;
    lblSerie                 : TcxLabel;
    txtSerie                 : TcxDBTextEdit;
    lblNumero                : TcxLabel;
    txtNumero                : TcxDBTextEdit;
    lblEstado                : TcxLabel;
    txtEstado                : TcxDBTextEdit;
    lblEmpresa               : TcxLabel;
    cbbEmpresa               : TcxDBLookupComboBox;
    lblProveedor             : TcxLabel;
    cbbProveedor             : TcxDBLookupComboBox;
    lblTarifa                : TcxLabel;
    cbbTarifa                : TcxDBLookupComboBox;
    lblMargen                : TcxLabel;
    spnMargen                : TcxDBSpinEdit;
    lblMultiploRedondeo      : TcxLabel;
    spnMultiploRedondeo      : TcxDBSpinEdit;
    lblAjusteFinal           : TcxLabel;
    spnAjusteFinal           : TcxDBSpinEdit;

    // ------------------------------------------------------------------
    // Ficha — botones de linea
    // ------------------------------------------------------------------
    pnlLineasTop             : TPanel;
    btnAddLinea              : TcxButton;
    btnDelLinea              : TcxButton;
    lblHint                  : TcxLabel;

    // ------------------------------------------------------------------
    // Ficha — grid de lineas
    // ------------------------------------------------------------------
    cxgrdLineas              : TcxGrid;
    tvLineas                 : TcxGridDBTableView;
    glLineas                 : TcxGridLevel;
    dbcLinFamilia            : TcxGridDBColumn;
    dbcLinCodArt             : TcxGridDBColumn;
    dbcLinDescripcion        : TcxGridDBColumn;
    dbcLinColor              : TcxGridDBColumn;
    dbcLinColorBasico        : TcxGridDBColumn;
    dbcLinPrecioCompra       : TcxGridDBColumn;
    dbcLinPrecioVenta        : TcxGridDBColumn;
    dbcLinTallas             : TcxGridDBColumn;
    dbcLinTotalTallas        : TcxGridDBColumn;
    dbcLinImporteTotal       : TcxGridDBColumn;

    // ------------------------------------------------------------------
    // Ficha — matriz de tallas dinamica
    // ------------------------------------------------------------------
    pnlMatrizCab             : TPanel;
    lblMatriz                : TcxLabel;
    sbMatriz                 : TScrollBox;

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
    procedure tvLineasEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);
    procedure tvLineasFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
    procedure tvLineasCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure dbcLinColorBasicoPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure dbcLinPrecioCompraPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinTallasPropertiesEditValueChanged(Sender: TObject);
  private
    FGestorMatriz   : TObject;            // TGestorMatrizCompras
    FLineaCargada   : Integer;
    FBasicosColor   : TArray<string>;     // CODIGO_ATB de los colores activos
    FBmpSwatch      : TBitmap;            // Glyph reutilizable del boton
    function  Dmm: TdmComprasSesiones;
    procedure CargarBasicosColor;
    procedure ReconstruirMatrizActual;
    procedure AsegurarFilaUnicaDeLinea(ALinea: Integer);
    procedure RefrescarTotalesLinea;
    procedure ProponerPrecioVenta;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoPruebaSesionGrid: TfrmMtoPruebaSesionGrid;

implementation

uses
  System.Generics.Collections,
  inLibGlobalVar,
  inLibUser,
  inLibComprasSesiones,
  inLibAtributosPaleta,
  inMtoModalSelFamilia;

const
  fIdVaColor = 'CO';

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// ===========================================================================
//   Bootstrapping
// ===========================================================================

function TfrmMtoPruebaSesionGrid.Dmm: TdmComprasSesiones;
begin
  Result := tdmDataModule as TdmComprasSesiones;
end;

procedure TfrmMtoPruebaSesionGrid.CrearTablaPrincipal;
begin
  inherited;
  if tdmDataModule = nil then Exit;
  pkFieldName := 'SERIE_SES;NUMERO_SES';

  // Lookups de cabecera (las listas las trae el DM compartido).
  cbbEmpresa.Properties.ListSource   := Dmm.dsEmpresas;
  cbbProveedor.Properties.ListSource := Dmm.dsProveedores;
  cbbTarifa.Properties.ListSource    := Dmm.dsTarifas;

  // Lookup del grid: Sistema tallas (conjunto de atributos pivot).
  TcxLookupComboBoxProperties(dbcLinTallas.Properties).ListSource :=
                                                    Dmm.dsAtributosConjuntos;

  // Master/detail de lineas (TfrmMtoGen no lo cablea desde el DFM del DM).
  with Dmm do
  begin
    unqrySesionLin.MasterFields := 'SERIE_SES;NUMERO_SES';
    unqrySesionLin.MasterSource := dsTablaG;
    if not unqrySesionLin.Active then unqrySesionLin.Open;
    if not unqrySesionFil.Active then unqrySesionFil.Open;
    if not unqrySesionCel.Active then unqrySesionCel.Open;
  end;
  tvLineas.DataController.DataSource := Dmm.dsSesionLin;
end;

procedure TfrmMtoPruebaSesionGrid.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoPruebaSesionGrid.FormCreate(Sender: TObject);
begin
  inherited;
  FLineaCargada := -1;
  FBmpSwatch    := TBitmap.Create;
  CargarBasicosColor;
  FGestorMatriz := TGestorMatrizCompras.Create(sbMatriz, Dmm, oUser);
end;

procedure TfrmMtoPruebaSesionGrid.FormDestroy(Sender: TObject);
begin
  if Assigned(FGestorMatriz) then FreeAndNil(FGestorMatriz);
  FreeAndNil(FBmpSwatch);
  inherited;
end;

procedure TfrmMtoPruebaSesionGrid.CargarBasicosColor;
var
  q : TUniQuery;
  i : Integer;
begin
  // Carga al vuelo los CODIGO_ATB de los basicos del eje CO (colores).
  // Es el conjunto de "colores basicos" del catalogo, identico al que
  // alimenta el selector del grid de inventarios. Cachear aqui evita
  // un round-trip por cada apertura del picker.
  SetLength(FBasicosColor, 0);
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ATB FROM fza_atributos_basicos ' +
      ' WHERE ID_VA_ATB = :va AND ESACTIVO_ATB = ''S'' ' +
      ' ORDER BY ORDEN_ATB, NOMBRE_ATB';
    q.ParamByName('va').AsString := fIdVaColor;
    q.Open;
    SetLength(FBasicosColor, q.RecordCount);
    i := 0;
    while not q.Eof do
    begin
      FBasicosColor[i] := q.FieldByName('CODIGO_ATB').AsString;
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

// ===========================================================================
//   Lineas — alta, baja, navegacion
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.btnAddLineaClick(Sender: TObject);
begin
  inherited;
  // La cabecera debe estar grabada antes de poder anadir lineas: si no
  // tenemos NUMERO_SES, el master/detail no sabra a que sesion enlazar.
  if Dmm.unqryTablaG.IsEmpty then
  begin
    MessageDlg('Crea y graba la cabecera de la sesion antes de anadir lineas.',
               mtInformation, [mbOk], 0);
    Exit;
  end;
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
  Dmm.unqrySesionLin.Insert;
end;

procedure TfrmMtoPruebaSesionGrid.btnDelLineaClick(Sender: TObject);
begin
  inherited;
  if Dmm.unqrySesionLin.IsEmpty then Exit;
  if MessageDlg('Borrar la linea seleccionada?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Dmm.unqrySesionLin.Delete;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  frmSel : TfrmModalSelFamilia;
  ds     : TDataSet;
begin
  inherited;
  // F3 sobre la columna Familia abre el selector jerarquico. Al aceptar,
  // pega el CODIGO_FAM y prerellena la descripcion. El BeforePost del DM
  // expande despues el codigo familia -> CODIGO_ART_TENTATIVO usando
  // inLibComprasSesiones.ResolverCodigoFamilia.
  if (Key <> VK_F3) or (Shift <> []) then Exit;
  if not Assigned(AItem) then Exit;
  if AItem <> dbcLinFamilia then Exit;

  frmSel := TfrmModalSelFamilia.Create(Self);
  try
    if frmSel.ShowModal = mrOk then
    begin
      ds := Dmm.unqrySesionLin;
      if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
      ds.FieldByName('CODIGO_FAM_SESLIN').AsString := frmSel.CodigoFamilia;
      // CODIGO_ART_TENTATIVO se rellena en BeforePost por ResolverCodigoFamilia
      // pero ponemos aqui el codigo de familia tecleado para que el chequeo
      // de duplicados de la propia BeforePost tenga input.
      if ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString = '' then
        ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString :=
                                                          frmSel.CodigoFamilia;
      if ds.FieldByName('DESCRIPCION_SESLIN').AsString = '' then
        ds.FieldByName('DESCRIPCION_SESLIN').AsString := frmSel.NombreFamilia;
    end;
  finally
    FreeAndNil(frmSel);
  end;
  Key := 0;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ReconstruirMatrizActual;
end;

// ===========================================================================
//   Color basico — selector con paleta (clon del de inventarios)
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.tvLineasInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  BE       : TcxButtonEdit;
  Btn      : TcxEditButton;
  AvActual : string;
  Info     : TInfoBasico;
begin
  inherited;
  // Al entrar a editar la celda Color basico:
  //   - Pinta el glyph del boton con un cuadradito del color actual (si
  //     el AV elegido tiene HEX_ATB definido en la paleta).
  //   - Si la celda esta vacia, autoabre el picker en cuanto el editor
  //     reciba foco (replica el patron de inMtoInventarios).
  if AItem <> dbcLinColorBasico then Exit;
  if not (AEdit is TcxButtonEdit) then Exit;
  BE := TcxButtonEdit(AEdit);
  if BE.Properties.Buttons.Count = 0 then Exit;
  Btn := BE.Properties.Buttons[0];

  AvActual := '';
  if Dmm.unqrySesionLin.Active and (not Dmm.unqrySesionLin.IsEmpty) then
    AvActual := Dmm.unqrySesionLin.FieldByName(
                                       'CODIGO_ATB_COLOR_SESLIN').AsString;

  Info := Default(TInfoBasico);
  if Trim(AvActual) <> '' then
    ObtenerInfoBasico(fIdVaColor, AvActual, Info);

  if Info.EsValido and PintarSwatchEnBitmap(FBmpSwatch, Info, 14) then
  begin
    Btn.Glyph.Assign(FBmpSwatch);
    Btn.Kind := bkGlyph;
  end
  else
    Btn.Kind := bkEllipsis;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Col      : TcxGridColumn;
  Info     : TInfoBasico;
  AvActual : string;
begin
  inherited;
  // Pinta el cuadradito de color a la izquierda del texto cuando la
  // celda corresponde a la columna Color basico. Reutiliza el helper
  // PintarCeldaConCuadradoColor de inLibAtributosPaleta — mismo aspecto
  // que el grid de inventarios.
  Col := nil;
  if AViewInfo.GridRecord = nil then Exit;
  if AViewInfo.Item is TcxGridColumn then
    Col := TcxGridColumn(AViewInfo.Item);
  if Col <> dbcLinColorBasico then Exit;

  AvActual := VarToStr(AViewInfo.GridRecord.Values[Col.Index]);
  if Trim(AvActual) = '' then Exit;

  Info := Default(TInfoBasico);
  if not ObtenerInfoBasico(fIdVaColor, AvActual, Info) then Exit;
  if not Info.EsValido then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info) then
    ADone := True;
end;

procedure TfrmMtoPruebaSesionGrid.dbcLinColorBasicoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  AvActual : string;
  AvNuevo  : string;
  ds       : TDataSet;
  Edit     : TWinControl;
  ScrPt    : TPoint;
  WidHint  : Integer;
begin
  // Mismo flujo que tvLineasSkuPropertiesButtonClick del Mto de inventarios:
  // abre el dropdown owner-drawn de la paleta basica, lee la seleccion y
  // la persiste en el dataset.
  if Length(FBasicosColor) = 0 then
  begin
    MessageDlg('No hay colores basicos cargados en fza_atributos_basicos ' +
               'para ID_VA=''CO''. Carga la paleta antes de usar el selector.',
               mtInformation, [mbOk], 0);
    Exit;
  end;

  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  AvActual := ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;

  ScrPt.X := -1; ScrPt.Y := -1;
  WidHint := 160;
  if Sender is TWinControl then
  begin
    Edit    := TWinControl(Sender);
    ScrPt   := Edit.ClientToScreen(Point(0, Edit.Height));
    WidHint := Edit.Width;
  end;

  if not SeleccionarAvConPaleta(fIdVaColor, FBasicosColor, AvActual,
                                AvNuevo, ScrPt.X, ScrPt.Y, WidHint) then
    Exit;

  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString := AvNuevo;
  // Reflejar al editor para que la celda se vea actualizada al instante,
  // sin esperar al refresh del DataLink (mismo patron que inventarios).
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).EditValue := AvNuevo;
end;

// ===========================================================================
//   Auto-PVP al teclear coste
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.dbcLinPrecioCompraPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  // Forzar que el valor tecleado pase al dataset antes de leerlo.
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).PostEditValue;
  ProponerPrecioVenta;
end;

procedure TfrmMtoPruebaSesionGrid.ProponerPrecioVenta;
var
  rCoste, rMargen, rMultiplo, rAjuste, rVenta : Double;
  ds                                          : TDataSet;
begin
  if Dmm.unqryTablaG.IsEmpty then Exit;
  if Dmm.unqrySesionLin.IsEmpty then Exit;

  ds := Dmm.unqrySesionLin;
  rCoste    := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  rMargen   := Dmm.unqryTablaG.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat;
  rMultiplo := Dmm.unqryTablaG.FieldByName('MULTIPLO_REDONDEO_SES').AsFloat;
  rAjuste   := Dmm.unqryTablaG.FieldByName('AJUSTE_FINAL_SES').AsFloat;

  rVenta := CalcularPrecioVenta(rCoste, rMargen, rMultiplo, rAjuste);
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := rVenta;
end;

// ===========================================================================
//   Conjunto de tallas (Sistema tallas) -> reconstruir matriz
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.dbcLinTallasPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).PostEditValue;
  // Forzar Post para que el nuevo pivot quede grabado antes de pintar la
  // matriz; si no, ID_AC_PIVOT_SESLIN seguiria con el valor anterior
  // cuando el gestor lo lea.
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;
  ReconstruirMatrizActual;
end;

procedure TfrmMtoPruebaSesionGrid.ReconstruirMatrizActual;
var
  iLinea : Integer;
begin
  if FGestorMatriz = nil then Exit;
  if Dmm.unqrySesionLin.IsEmpty then
  begin
    TGestorMatrizCompras(FGestorMatriz).ReconstruirMatriz(0);
    FLineaCargada := -1;
    Exit;
  end;
  iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  // Una fila por linea: la creamos si todavia no existe en SESFIL para
  // que TGestorMatrizCompras tenga sobre que dibujar.
  AsegurarFilaUnicaDeLinea(iLinea);
  TGestorMatrizCompras(FGestorMatriz).ReconstruirMatriz(iLinea);
  FLineaCargada := iLinea;
  RefrescarTotalesLinea;
end;

procedure TfrmMtoPruebaSesionGrid.AsegurarFilaUnicaDeLinea(ALinea: Integer);
var
  q   : TUniQuery;
  sSerie, sNumero, sEtq : string;
begin
  // INSERT idempotente de UNA fila SESFIL (ID_FILA=1) por linea. La
  // etiqueta de la fila se sincroniza con COLOR_TEXTO_SESLIN para que la
  // tira de la matriz muestre lo que el usuario tecleo en el grid.
  if Dmm.unqryTablaG.IsEmpty then Exit;
  sSerie  := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sEtq    := Dmm.unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_lineas_filas ' +
      '  (SERIE_SES_SESFIL, NUMERO_SES_SESFIL, LINEA_SES_SESFIL, ' +
      '   ID_FILA_SESFIL, ORDEN_SESFIL, ETIQUETA_TEXTO_SESFIL, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:s, :n, :l, 1, 10, :t, NOW(), :u) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  ETIQUETA_TEXTO_SESFIL = VALUES(ETIQUETA_TEXTO_SESFIL)';
    q.ParamByName('s').AsString  := sSerie;
    q.ParamByName('n').AsString  := sNumero;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('t').AsString  := sEtq;
    q.ParamByName('u').AsString  := oUser;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoPruebaSesionGrid.RefrescarTotalesLinea;
var
  q     : TUniQuery;
  rTot  : Double;
  rPr   : Double;
  ds    : TDataSet;
begin
  // Recalcula TOTAL_UNIDADES + TOTAL_LINEA sumando las celdas de la linea
  // actual. El DM principal tiene esta operacion como TODO; aqui la
  // implementamos para que la prueba refleje totales reales.
  if Dmm.unqrySesionLin.IsEmpty then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) AS TOTAL ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    q.ParamByName('s').AsString  :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger :=
      Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    q.Open;
    rTot := q.FieldByName('TOTAL').AsFloat;
  finally
    FreeAndNil(q);
  end;
  ds := Dmm.unqrySesionLin;
  rPr := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := rTot;
  ds.FieldByName('TOTAL_LINEA_SESLIN').AsFloat    := rTot * rPr;
  ds.Post;
end;

initialization
  ForceReferenceToClass(TfrmMtoPruebaSesionGrid);
end.
