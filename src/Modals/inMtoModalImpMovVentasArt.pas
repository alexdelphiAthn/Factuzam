{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpMovVentasArt                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Movimientos de ventas por artículos y fechas"     }
{    (ranking de ventas, FastReport). Una fila por artículo/color cuando hay   }
{    color (o por artículo/color+almacén si se agrupa por almacén), con las    }
{    entradas y venta del periodo, margen 1 sobre el coste vendido y margen 2  }
{    sobre el importe de entradas. Mantiene la foto del artículo. Se apoya en  }
{    el SP PRC_GET_MOV_VENTAS_ART (ver                                         }
{    DESARROLLOS EN CURSO/movimientos_ventas_articulos.sql).                   }
{                                                                              }
{    Hereda de TfrmPrintMultiFiltro: reutiliza las pestañas de filtros         }
{    múltiples (almacenes / familias / proveedores / temporadas / artículos /  }
{    fechas) y la de agrupaciones. Añade "Inicio compras", la selección de     }
{    impuestos y la ordenación, además de la plantilla y la consulta.          }
{******************************************************************************}
unit inMtoModalImpMovVentasArt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxRadioGroup,
  cxCheckListBox, cxCheckBox, cxCustomListBox,
  cxClasses, dxSkinsForm, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab, cxLocalization,
  inLibInformeMovimientosVentasArticuloPersistenciaIntf;

type
  TfrmPrintMovVentasArt = class(TfrmPrintMultiFiltro)
    fxdsMovVentas: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FRepositorioMovimientos:
      IRepositorioInformeMovimientosVentasArticulo;
    FResultadoMovimientos: IResultadoInformeMovimientosVentasArticulo;
    FchkIniCompras: TcxCheckBox;   // activa el filtro de inicio de compras
    // fecha de primera compra a partir de la cual
    FdteIniCompras: TcxDateEdit;
    FchkSoloVentas: TcxCheckBox;   // 'solo artículos con ventas' en el periodo
    FchkConImpuestos: TcxCheckBox;
    FclbOrden: TcxCheckListBox;
    FrgSentidoOrden: TcxRadioGroup;
    // Crea el control de "Inicio compras" sobre la pestaña de fechas.
    procedure CrearControlesPropios;
    procedure CrearControlesOrdenacion;
    procedure chkIniComprasChange(Sender: TObject);
    procedure OrdenClickCheck(Sender: TObject; AIndex: Integer;
      APrevState, ANewState: TcxCheckBoxState);
    function OrdenSeleccionado(out AOrden: TOrdenMovVentasArt): Boolean;
    // Exportación a Excel propia (sustituye al export FastReport del base).
    procedure ExportarExcelMovVentas(Sender: TObject);
    // Handler de OnBeforePrint: fotos + ocultar bandas de grupo inactivas.
    procedure ReportBeforePrint(Component: TfrxReportComponent);
    procedure CompletarSubtotales;
    procedure ActualizarFormulasPorcentajes;
    // Adapta el detalle a procedimientos nuevos o antiguos sin campo color.
    procedure ConfigurarDetalleArticuloColor;
    // Precarga en bloque las fotos de los artículos del resultado (1 consulta).
    procedure PrecargarFotosArticulos;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure DoShow; override;
  public
    destructor Destroy; override;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

uses
  System.StrUtils, inMtoPreviewExcel, inLibMovVentasArtExcel,
  inLibMsgVentas,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx, dxSpreadSheet,
  inLibFotos, UniDataInformeMovimientosVentasArticuloRepositorio;

resourcestring
  STituloAgrupacionesMovimientosVentasArticulo = 'Agrupaciones';
  SCaptionAlmacenAgrupacionMovimientosVentas = 'Almacén';
  SCaptionProveedorAgrupacionMovimientosVentas = 'Proveedor';
  SCaptionFamiliaAgrupacionMovimientosVentas = 'Familia';
  SCaptionTemporadaAgrupacionMovimientosVentas = 'Temporada';
  SCaptionColorAgrupacionMovimientosVentas = 'Color';
  SNombreArchivoMovimientosVentasArticulos =
    'Movimientos_ventas_articulos';
  SCaptionConImpuestosMovimientosVentas = 'Precios con impuestos';
  STituloOrdenacionMovimientosVentas = 'Ordenación';
  SCaptionSentidoOrdenMovimientosVentas = ' Dirección ';
  SCaptionPeriodoOrdenMovimientosVentas =
    'Los criterios usan las ventas del periodo seleccionado.';
  SCaptionSeleccioneOrdenMovimientosVentas =
    'Seleccione un criterio de ordenación:';
  SHintOrdenDetalleMovimientosVentas =
    'Ordena cada agrupación por su subtotal y el detalle del último nivel.';
  SOrdenUnidadesVentaMovimientosVentas = 'Unidades vendidas';
  SOrdenImporteVentaMovimientosVentas = 'Importe vendido';
  SOrdenImporteCosteMovimientosVentas = 'Importe de coste';
  SOrdenBeneficioMovimientosVentas = 'Beneficio';
  SOrdenPorcentajeBeneficioMovimientosVentas = '% beneficio';
  SOrdenImporteVentaComprasMovimientosVentas =
    'Importe venta - compras';
  SOrdenAscendenteMovimientosVentas = 'Ascendente';
  SOrdenDescendenteMovimientosVentas = 'Descendente';

{ TfrmPrintMovVentasArt }

function TfrmPrintMovVentasArt.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas,
             frArticulos];
end;

procedure TfrmPrintMovVentasArt.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    // El botón Excel del base exporta el FastReport a XLSX (farragoso); lo
    // redirigimos a una exportación limpia con el mismo layout que el informe.
    btnExcel.OnClick := ExportarExcelMovVentas;
    FInicializado := True;
  end;
end;

procedure TfrmPrintMovVentasArt.CrearControlesPropios;
begin
  if TabFechas <> nil then
  begin
    // Por defecto el ranking mira las ventas del AÑO en curso (no del mes):
    // las entradas son de siempre, así que un periodo corto deja casi todo a
    // cero. El base pone el 1 del mes; aquí lo ampliamos al 1 de enero.
    if DteDesde <> nil then
      DteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
    // "Inicio compras": filtra los artículos por su primera entrada (AC/AE).
    // El check permite desactivarlo (sin filtro = todos los que tengan
    // actividad). Arranca DESMARCADO para no ocultar artículos sin querer.
    FchkIniCompras := TcxCheckBox.Create(Self);
    FchkIniCompras.Parent    := TabFechas;
    FchkIniCompras.Left      := 220;
    FchkIniCompras.Top       := 16;
    FchkIniCompras.Width     := 210;
    FchkIniCompras.Caption   := SCaptionFiltrarInicioCompras;
    FchkIniCompras.Properties.OnEditValueChanged := chkIniComprasChange;
    FdteIniCompras := TcxDateEdit.Create(Self);
    FdteIniCompras.Parent  := TabFechas;
    FdteIniCompras.Left    := 220;
    FdteIniCompras.Top     := 40;
    FdteIniCompras.Width   := 160;
    FdteIniCompras.Date    := EncodeDate(YearOf(Date), 1, 1);
    FdteIniCompras.Enabled := False;
    // "Solo artículos con ventas": oculta los que solo tienen entradas (lo
    // típico de un ranking de ventas). Arranca DESMARCADO = salen todos.
    FchkSoloVentas := TcxCheckBox.Create(Self);
    FchkSoloVentas.Parent  := TabFechas;
    FchkSoloVentas.Left    := 220;
    FchkSoloVentas.Top     := 72;
    FchkSoloVentas.Width   := 210;
    FchkSoloVentas.Caption := SCaptionSoloArticulosConVentas;
    FchkConImpuestos := TcxCheckBox.Create(Self);
    FchkConImpuestos.Parent := TabFechas;
    FchkConImpuestos.Left := 460;
    FchkConImpuestos.Top := 16;
    FchkConImpuestos.Width := 210;
    FchkConImpuestos.Caption := SCaptionConImpuestosMovimientosVentas;
    FchkConImpuestos.Checked := True;
  end;
  CrearControlesOrdenacion;
  // Pestaña "Agrupaciones": almacén/proveedor/familia/temporada/color.
  // + spin de nivel de familia (igual que el balance de almacén).
  CrearTabAgrupacion(STituloAgrupacionesMovimientosVentasArticulo,
    ['ALM', 'PRV', 'FAM', 'TMP', 'COL'],
    [SCaptionAlmacenAgrupacionMovimientosVentas,
     SCaptionProveedorAgrupacionMovimientosVentas,
     SCaptionFamiliaAgrupacionMovimientosVentas,
     SCaptionTemporadaAgrupacionMovimientosVentas,
     SCaptionColorAgrupacionMovimientosVentas], True);
end;

procedure TfrmPrintMovVentasArt.CrearControlesOrdenacion;
var
  lblPeriodo: TcxLabel;
  oItem: TcxCheckListBoxItem;
begin
  FclbOrden := CrearTabChecklist(STituloOrdenacionMovimientosVentas,
    SCaptionSeleccioneOrdenMovimientosVentas);
  FclbOrden.Align := alNone;
  FclbOrden.SetBounds(16, 40, 360, 190);
  FclbOrden.EditValueFormat := cvfIndices;
  FclbOrden.IntegralHeight := False;
  FclbOrden.AllowGrayed := False;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenUnidadesVentaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteVentaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteCosteMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenBeneficioMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeBeneficioMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteVentaComprasMovimientosVentas;
  oItem.Checked := True;
  FclbOrden.OnClickCheck := OrdenClickCheck;
  FclbOrden.Hint := SHintOrdenDetalleMovimientosVentas;
  FclbOrden.ShowHint := True;
  FrgSentidoOrden := TcxRadioGroup.Create(Self);
  FrgSentidoOrden.Parent := FclbOrden.Parent;
  FrgSentidoOrden.SetBounds(410, 40, 210, 90);
  FrgSentidoOrden.Caption := SCaptionSentidoOrdenMovimientosVentas;
  FrgSentidoOrden.Properties.Items.Add.Caption :=
    SOrdenDescendenteMovimientosVentas;
  FrgSentidoOrden.Properties.Items.Add.Caption :=
    SOrdenAscendenteMovimientosVentas;
  FrgSentidoOrden.ItemIndex := 0;
  FrgSentidoOrden.Hint := SHintOrdenDetalleMovimientosVentas;
  FrgSentidoOrden.ShowHint := True;
  lblPeriodo := TcxLabel.Create(Self);
  lblPeriodo.Parent := FclbOrden.Parent;
  lblPeriodo.SetBounds(410, 142, 330, 44);
  lblPeriodo.AutoSize := False;
  lblPeriodo.Properties.WordWrap := True;
  lblPeriodo.Transparent := True;
  lblPeriodo.Caption := SCaptionPeriodoOrdenMovimientosVentas;
end;

procedure TfrmPrintMovVentasArt.OrdenClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
var
  iOrden: Integer;
begin
  if (FclbOrden <> nil) and (ANewState = cbsChecked) then
    for iOrden := 0 to FclbOrden.Items.Count - 1 do
      if iOrden <> AIndex then
        FclbOrden.Items[iOrden].State := cbsUnchecked;
end;

procedure TfrmPrintMovVentasArt.chkIniComprasChange(Sender: TObject);
begin
  if FdteIniCompras <> nil then
    FdteIniCompras.Enabled := (FchkIniCompras <> nil)
      and (FchkIniCompras.Checked);
end;

function TfrmPrintMovVentasArt.OrdenSeleccionado(
  out AOrden: TOrdenMovVentasArt): Boolean;
var
  iOrden: Integer;
begin
  Result := False;
  AOrden := Low(TOrdenMovVentasArt);
  if FclbOrden <> nil then
    for iOrden := Ord(Low(TOrdenMovVentasArt)) to
      Ord(High(TOrdenMovVentasArt)) do
      if (not Result) and FclbOrden.Items[iOrden].Checked then
      begin
        AOrden := TOrdenMovVentasArt(iOrden);
        Result := True;
      end;
end;

procedure TfrmPrintMovVentasArt.preparar_consulta;
var
  criterios: TCriteriosInformeMovimientosVentasArticulo;
  niveles: TArray<string>;
  function NivelN(idx: Integer): string;
  begin
    if (idx >= 0) and (idx < Length(niveles)) then
      Result := niveles[idx]
    else
      Result := '';
  end;
begin
  inherited;
  niveles := NivelesAgrupacion;
  criterios.FechaDesde := FechaDesde;
  criterios.FechaHasta := FechaHasta;
  criterios.UsarInicioCompras := (FchkIniCompras <> nil) and
    FchkIniCompras.Checked and (FdteIniCompras <> nil);
  if criterios.UsarInicioCompras then
    criterios.InicioCompras := FdteIniCompras.Date;
  criterios.Almacenes := CSVAlmacenes;
  criterios.Familias := CSVFamilias;
  criterios.Proveedores := CSVProveedores;
  criterios.Temporadas := CSVTemporadas;
  criterios.Articulos := CSVArticulos;
  criterios.Nivel1 := NivelN(0);
  criterios.Nivel2 := NivelN(1);
  criterios.Nivel3 := NivelN(2);
  criterios.NivelFamilia := NivelFamilia;
  criterios.SoloVentas := (FchkSoloVentas <> nil) and
    FchkSoloVentas.Checked;
  criterios.ConImpuestos := (FchkConImpuestos <> nil) and
    FchkConImpuestos.Checked;
  criterios.UsarOrden := OrdenSeleccionado(criterios.Orden);
  criterios.OrdenDescendente := (FrgSentidoOrden <> nil) and
    (FrgSentidoOrden.ItemIndex = 0);
  if FRepositorioMovimientos = nil then
    FRepositorioMovimientos :=
      CrearRepositorioInformeMovimientosVentasArticuloUniDAC(
        ConexionPrincipal);
  FResultadoMovimientos := FRepositorioMovimientos.Preparar(criterios);
  fxdsMovVentas.UpdateBounds;
end;

procedure TfrmPrintMovVentasArt.AfterReportLoaded;
begin
  inherited;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsMovVentas.DataSet := FResultadoMovimientos.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsMovVentas);
  ConfigurarDetalleArticuloColor;
  CompletarSubtotales;
  ActualizarFormulasPorcentajes;
  // Sustituimos el OnBeforePrint del base (fotos) por el nuestro, que encadena
  // las fotos y oculta las bandas de grupo de los niveles inactivos.
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  // Precarga de fotos a nivel artículo en UNA consulta (evita el N+1).
  PrecargarFotosArticulos;
end;

procedure TfrmPrintMovVentasArt.CompletarSubtotales;
const
  Sufijos: array[0..6] of string = (
    'UniEnt', 'UdsVta', 'ImpCos', 'PctBnf', 'VentEnt',
    'PctVdto', 'PctVlast');
var
  iNivel: Integer;
  iSufijo: Integer;
  oDestino: TfrxComponent;
  oOrigen: TfrxComponent;
  oPie: TfrxComponent;
  sNombreDestino: string;
  sPrefijoOrigen: string;
begin
  for iNivel := 1 to 2 do
  begin
    if iNivel = 1 then
      sPrefijoOrigen := 'MemoRS'
    else
      sPrefijoOrigen := 'MemoGF3';
    oPie := frxrprt1.FindObject(Format('GroupFooterG%d', [iNivel]));
    if oPie <> nil then
      for iSufijo := Low(Sufijos) to High(Sufijos) do
      begin
        sNombreDestino := Format(
          'MemoGF%d%s', [iNivel, Sufijos[iSufijo]]);
        oDestino := frxrprt1.FindObject(sNombreDestino);
        oOrigen := frxrprt1.FindObject(sPrefijoOrigen + Sufijos[iSufijo]);
        if (oDestino = nil) and (oOrigen is TfrxMemoView) then
        begin
          oDestino := TfrxMemoView.Create(oPie);
          oDestino.Assign(oOrigen);
          oDestino.Parent := oPie;
          oDestino.Name := sNombreDestino;
        end;
      end;
  end;
end;

procedure TfrmPrintMovVentasArt.ActualizarFormulasPorcentajes;
const
  DenominadorVentas: array[1..3] of string = (
    'UDS_VENTA_GLOBAL', 'UDS_VENTA_G1', 'UDS_VENTA_G2');
var
  iNivel: Integer;
  sPrefijo: string;
  function Suma(const ACampo: string): string;
  begin
    Result := Format('SUM(<MovVentas."%s">,MasterData1)', [ACampo]);
  end;
  function Maximo(const ACampo: string): string;
  begin
    Result := Format('MAX(<MovVentas."%s">,MasterData1)', [ACampo]);
  end;
  function Porcentaje(const ANumerador, ADenominador: string): string;
  begin
    Result := Format('[IIF(%s<>0,%s/%s*100,0)]',
      [ADenominador, ANumerador, ADenominador]);
  end;
  procedure PonerFormula(const ANombre, AFormula: string);
  var
    oComponente: TfrxComponent;
  begin
    oComponente := frxrprt1.FindObject(ANombre);
    if oComponente is TfrxMemoView then
      TfrxMemoView(oComponente).Memo.Text := AFormula;
  end;
  procedure PonerFormulas(const APrefijo: string);
  begin
    PonerFormula(APrefijo + 'PctBnf',
      Porcentaje(Suma('BENEFICIO'), Suma('IMP_VENTA')));
    PonerFormula(APrefijo + 'VentEnt',
      Porcentaje(Suma('IMP_VENTA'), Suma('IMP_ENT_TOT')));
    PonerFormula(APrefijo + 'Marg1',
      Porcentaje(Suma('BENEFICIO'), Suma('IMP_COSTE')));
    PonerFormula(APrefijo + 'Marg2',
      Porcentaje(Suma('VENTA_ENT'), Suma('IMP_ENT_TOT')));
  end;
begin
  for iNivel := 1 to 3 do
  begin
    sPrefijo := Format('MemoGF%d', [iNivel]);
    PonerFormulas(sPrefijo);
    PonerFormula(sPrefijo + 'PctVlast',
      Porcentaje(Suma('UDS_VENTA'),
        Maximo(DenominadorVentas[iNivel])));
  end;
  PonerFormulas('MemoRS');
  PonerFormula('MemoRSPctVlast',
    Format('[IIF(%s<>0,100,0)]', [Suma('UDS_VENTA')]));
  PonerFormula('MemoHPctVdto', '% Vdo');
  PonerFormula('MemoHPctVlast', '% Vtas');
end;

procedure TfrmPrintMovVentasArt.ConfigurarDetalleArticuloColor;
var
  oComponente: TfrxComponent;
  sCampoColor: string;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active then
  begin
    sCampoColor := '';
    if FResultadoMovimientos.DataSet.FindField('COLOR_ETIQUETA') <> nil then
      sCampoColor := 'COLOR_ETIQUETA'
    else if FResultadoMovimientos.DataSet.FindField('COLOR') <> nil then
      sCampoColor := 'COLOR';
    oComponente := frxrprt1.FindObject('MemoArtDesc');
    if oComponente is TfrxMemoView then
    begin
      if sCampoColor <> '' then
        TfrxMemoView(oComponente).Memo.Text :=
          '[MovVentas."CODIGO_ART_ART"]  [MovVentas."' + sCampoColor + '"]' +
          sLineBreak + '[MovVentas."DESCRIPCION_ART"]'
      else
        TfrxMemoView(oComponente).Memo.Text :=
          '[MovVentas."CODIGO_ART_ART"]' + sLineBreak +
          '[MovVentas."DESCRIPCION_ART"]';
    end;
  end;
end;

destructor TfrmPrintMovVentasArt.Destroy;
begin
  FotosArticulos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintMovVentasArt.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active and
     (not FResultadoMovimientos.DataSet.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      FResultadoMovimientos.DataSet.DisableControls;
      try
        FResultadoMovimientos.DataSet.First;
        while not FResultadoMovimientos.DataSet.Eof do
        begin
          slCod.Add(FResultadoMovimientos.DataSet.FieldByName(
            'CODIGO_ART_ART').AsString);
          FResultadoMovimientos.DataSet.Next;
        end;
      finally
        FResultadoMovimientos.DataSet.EnableControls;
      end;
      FotosArticulos.PrecargarFotosLote(slCod.ToStringArray);
    finally
      FreeAndNil(slCod);
    end;
  end;
end;

procedure TfrmPrintMovVentasArt.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  sNom : string;
  nivel: Integer;
begin
  FotosArticulos.HandlerReportBeforePrint(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if (Pos('GroupHeaderG', sNom) = 1) or (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       (FResultadoMovimientos <> nil) and
       FResultadoMovimientos.DataSet.Active then
      TfrxBand(Component).Visible :=
        FResultadoMovimientos.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> ''
    else if (sNom = 'GroupHeaderFam') or (sNom = 'GroupFooterFam') then
      // La familia NO agrupa por sí sola: solo se agrupa por familia si se
      // elige FAM en la pestaña Agrupaciones (sale como "Familia: ...").
      TfrxBand(Component).Visible := False;
  end;
end;

procedure TfrmPrintMovVentasArt.ExportarExcelMovVentas(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  oServiciosHoja: TServiciosHojaCalculo;
begin
  preparar_consulta;
  Self.Hide;
  try
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName :=
        SNombreArchivoMovimientosVentasArticulos;
      oServiciosHoja := CrearServiciosHojaCalculoDevEx(
        fPreview.dxSpreadSheet1);
      ExportarMovVentasArtExcel(
        oServiciosHoja.Escritor,
        oServiciosHoja.Formateador,
        FResultadoMovimientos.DataSet);
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
