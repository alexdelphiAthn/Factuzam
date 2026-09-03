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
{    (ranking de ventas, FastReport). Sin agrupaciones muestra el artículo.    }
{    Con niveles sin ART, el último es el detalle agregado y los anteriores   }
{    son grupos exteriores. Si se marca ART conserva su desglose. Incluye las }
{    entradas y venta del periodo y los márgenes. Se apoya en                 }
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
    FConexionMovimientos: TUniConnection;
    FRepositorioMovimientos:
      IRepositorioInformeMovimientosVentasArticulo;
    FResultadoMovimientos: IResultadoInformeMovimientosVentasArticulo;
    FNivelDetalleAgrupacion: Integer;
    FResumenAgrupado: Boolean;
    FchkIniCompras: TcxCheckBox;   // activa la fecha inicial de las entradas
    // fecha desde la que se suman albaranes y, en modo local, traspasos
    FdteIniCompras: TcxDateEdit;
    FchkEntradasGlobales: TcxCheckBox;
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
    procedure IncluirDetalleOcultoEnAcumulados;
    procedure PrepararMovimientosEnSegundoPlano(
      const ACriterios: TCriteriosInformeMovimientosVentasArticulo);
    // Adapta el detalle a procedimientos antiguos sin color o talla.
    procedure ConfigurarDetalleArticuloAtributos;
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
  System.StrUtils, System.Threading, Vcl.ComCtrls,
  inMtoPreviewExcel, inLibMovVentasArtExcel, inLibMsgVentas,
  inLibMsgComun, inLibConexionesIntf,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx, dxSpreadSheet,
  inLibFotos,
  UniDataInformeMovimientosVentasArticuloRepositorio;

type
  TProcesarLoteEspera = reference to function: Boolean;

  TfrmEsperaMovVentas = class(TForm)
  private
    FError: string;
    FProcesarLote: TProcesarLoteEspera;
    FPuedeCerrar: Boolean;
    FTarea: ITask;
    FTemporizador: TTimer;
    procedure ComprobarCierre(Sender: TObject; var CanClose: Boolean);
    procedure ComprobarTrabajo(Sender: TObject);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Esperar(const ATarea: ITask);
    procedure EsperarPorLotes(
      const AProcesarLote: TProcesarLoteEspera);
    procedure Finalizar;
  end;

resourcestring
  STituloAgrupacionesMovimientosVentasArticulo = 'Agrupaciones';
  SCaptionAlmacenAgrupacionMovimientosVentas = 'Almacén';
  SCaptionProveedorAgrupacionMovimientosVentas = 'Proveedor';
  SCaptionFamiliaAgrupacionMovimientosVentas = 'Familia';
  SCaptionTemporadaAgrupacionMovimientosVentas = 'Temporada';
  SNombreArchivoMovimientosVentasArticulos =
    'Movimientos_ventas_articulos';

const
  DURACION_LOTE_EXCEL_MS = 150;
  FILAS_POR_PASO_EXCEL = 10;
  INTERVALO_LOTE_EXCEL_MS = 10;

{ TfrmEsperaMovVentas }

constructor TfrmEsperaMovVentas.Create(AOwner: TComponent);
var
  oBarra: TProgressBar;
  oTexto: TLabel;
begin
  inherited CreateNew(AOwner);
  BorderIcons := [];
  BorderStyle := bsDialog;
  Caption := SCaptionCargandoDatosEspere;
  ClientHeight := 100;
  ClientWidth := 420;
  Cursor := crHourGlass;
  FPuedeCerrar := False;
  Position := poOwnerFormCenter;
  OnCloseQuery := ComprobarCierre;
  oTexto := TLabel.Create(Self);
  oTexto.Parent := Self;
  oTexto.SetBounds(16, 16, ClientWidth - 32, 30);
  oTexto.Alignment := taCenter;
  oTexto.AutoSize := False;
  oTexto.Caption := SCaptionCargandoDatosEspere;
  oTexto.Cursor := crHourGlass;
  oTexto.Font.Style := [fsBold];
  oTexto.Layout := tlCenter;
  oBarra := TProgressBar.Create(Self);
  oBarra.Parent := Self;
  oBarra.SetBounds(60, 58, ClientWidth - 120, 18);
  oBarra.Cursor := crHourGlass;
  oBarra.MarqueeInterval := 30;
  oBarra.Style := pbstMarquee;
  FTemporizador := TTimer.Create(Self);
  FTemporizador.Enabled := False;
  FTemporizador.Interval := 50;
  FTemporizador.OnTimer := ComprobarTrabajo;
end;

procedure TfrmEsperaMovVentas.ComprobarCierre(
  Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FPuedeCerrar;
end;

procedure TfrmEsperaMovVentas.ComprobarTrabajo(Sender: TObject);
var
  bFinalizado: Boolean;
begin
  FTemporizador.Enabled := False;
  try
    if Assigned(FTarea) then
    begin
      if FTarea.Status in [
         TTaskStatus.Completed,
         TTaskStatus.Canceled,
         TTaskStatus.Exception] then
        Finalizar;
    end
    else if Assigned(FProcesarLote) then
    begin
      try
        bFinalizado := FProcesarLote();
        if bFinalizado then
          Finalizar;
      except
        on E: Exception do
        begin
          FError := E.Message;
          if FError = '' then
            FError := E.ClassName;
          Finalizar;
        end;
      end;
    end;
  finally
    if not FPuedeCerrar then
      FTemporizador.Enabled := True;
  end;
end;

procedure TfrmEsperaMovVentas.DoShow;
begin
  inherited;
  Screen.Cursor := crHourGlass;
end;

procedure TfrmEsperaMovVentas.Esperar(const ATarea: ITask);
begin
  FError := '';
  FProcesarLote := nil;
  FPuedeCerrar := False;
  FTarea := ATarea;
  FTemporizador.Interval := 50;
  FTemporizador.Enabled := True;
  try
    ShowModal;
  finally
    FTemporizador.Enabled := False;
    FTarea := nil;
  end;
end;

procedure TfrmEsperaMovVentas.EsperarPorLotes(
  const AProcesarLote: TProcesarLoteEspera);
var
  sError: string;
begin
  FError := '';
  FProcesarLote := AProcesarLote;
  FPuedeCerrar := False;
  FTarea := nil;
  FTemporizador.Interval := INTERVALO_LOTE_EXCEL_MS;
  FTemporizador.Enabled := True;
  try
    ShowModal;
  finally
    FTemporizador.Enabled := False;
    FProcesarLote := nil;
    sError := FError;
    FError := '';
  end;
  if sError <> '' then
    raise Exception.Create(sError);
end;

procedure TfrmEsperaMovVentas.Finalizar;
begin
  FTemporizador.Enabled := False;
  FPuedeCerrar := True;
  ModalResult := mrOk;
end;

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
    // "Inicio compras" limita la fecha desde la que se suman las entradas.
    // Desmarcado conserva todo el histórico de entradas.
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
    // Global: albaranes AC/AE de toda la empresa. Local: albaranes y
    // traspasos de entrada de los almacenes seleccionados.
    FchkEntradasGlobales := TcxCheckBox.Create(Self);
    FchkEntradasGlobales.Parent := TabFechas;
    FchkEntradasGlobales.Left := FchkIniCompras.Left;
    FchkEntradasGlobales.Top := 72;
    FchkEntradasGlobales.Width := 210;
    FchkEntradasGlobales.Caption :=
      SCaptionEntradasGlobalesMovimientosVentas;
    FchkEntradasGlobales.Checked := True;
    // "Solo artículos con ventas": oculta los que solo tienen entradas (lo
    // típico de un ranking de ventas). Arranca DESMARCADO = salen todos.
    FchkSoloVentas := TcxCheckBox.Create(Self);
    FchkSoloVentas.Parent  := TabFechas;
    FchkSoloVentas.Left    := FchkEntradasGlobales.Left;
    FchkSoloVentas.Top     := FchkEntradasGlobales.Top +
      FchkEntradasGlobales.Height + 8;
    FchkSoloVentas.Width   := 210;
    FchkSoloVentas.Caption := SCaptionSoloArticulosConVentas;
    FchkConImpuestos := TcxCheckBox.Create(Self);
    FchkConImpuestos.Parent := TabFechas;
    FchkConImpuestos.Left := FchkSoloVentas.Left;
    FchkConImpuestos.Top :=
      FchkSoloVentas.Top + FchkSoloVentas.Height + 8;
    FchkConImpuestos.Width := 210;
    FchkConImpuestos.Caption := SCaptionConImpuestosMovimientosVentas;
    FchkConImpuestos.Checked := True;
  end;
  CrearControlesOrdenacion;
  // Agrupaciones reordenables, incluidos los desgloses por color y talla.
  // + spin de nivel de familia (igual que el balance de almacén).
  CrearTabAgrupacion(STituloAgrupacionesMovimientosVentasArticulo,
    ['ALM', 'PRV', 'FAM', 'TMP', 'ART', 'COL', 'TAL'],
    [SCaptionAlmacenAgrupacionMovimientosVentas,
     SCaptionProveedorAgrupacionMovimientosVentas,
     SCaptionFamiliaAgrupacionMovimientosVentas,
     SCaptionTemporadaAgrupacionMovimientosVentas,
     SCaptionArticuloAgrupacionMovimientosVentas,
     SCaptionColorAgrupacionMovimientosVentas,
     SCaptionTallaAgrupacionMovimientosVentas], True);
end;

procedure TfrmPrintMovVentasArt.CrearControlesOrdenacion;
var
  lblPeriodo: TcxLabel;
  oItem: TcxCheckListBoxItem;
begin
  FclbOrden := CrearTabChecklist(STituloOrdenacionMovimientosVentas,
    SCaptionSeleccioneOrdenMovimientosVentas);
  FclbOrden.Align := alNone;
  FclbOrden.SetBounds(16, 40, 360, 330);
  FclbOrden.EditValueFormat := cvfIndices;
  FclbOrden.IntegralHeight := False;
  FclbOrden.AllowGrayed := False;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenArticuloDescripcionMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenUnidadesEntradaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteEntradaMovimientosVentas;
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
  oItem.Text := SOrdenVentaEntradaMovimientosVentas;
  oItem.Checked := True;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeVentaEntradaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenMargen1MovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenMargen2MovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeVendidoMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeVentasMovimientosVentas;
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
  criterios.EntradasGlobales := (FchkEntradasGlobales = nil) or
    FchkEntradasGlobales.Checked;
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
  PrepararMovimientosEnSegundoPlano(criterios);
  fxdsMovVentas.UpdateBounds;
end;

procedure TfrmPrintMovVentasArt.PrepararMovimientosEnSegundoPlano(
  const ACriterios: TCriteriosInformeMovimientosVentasArticulo);
var
  crCursorAnterior: TCursor;
  oConexionNueva: TUniConnection;
  oConexiones: IServicioConexiones;
  oEspera: TfrmEsperaMovVentas;
  oRepositorioNuevo: IRepositorioInformeMovimientosVentasArticulo;
  oResultadoNuevo: IResultadoInformeMovimientosVentasArticulo;
  oTarea: ITask;
  iNumeroFilas: Integer;
  nInicioCarga: UInt64;
  nTiempoCarga: Int64;
  sError: string;
begin
  oConexiones := Conexiones;
  if not Assigned(oConexiones) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
  oConexionNueva := nil;
  oEspera := TfrmEsperaMovVentas.Create(Self);
  try
    crCursorAnterior := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    try
      oTarea := TTask.Run(
        procedure
        begin
          try
            nInicioCarga := GetTickCount64;
            oConexionNueva := oConexiones.CrearConexion(
              nil, uctSegundoPlano);
            oRepositorioNuevo :=
              CrearRepositorioInformeMovimientosVentasArticuloUniDAC(
                oConexionNueva);
            oResultadoNuevo := oRepositorioNuevo.Preparar(ACriterios);
            iNumeroFilas := oResultadoNuevo.DataSet.RecordCount;
            nTiempoCarga := Int64(GetTickCount64 - nInicioCarga);
          except
            on E: Exception do
            begin
              sError := E.Message;
              if sError = '' then
                sError := E.ClassName;
              oResultadoNuevo := nil;
              oRepositorioNuevo := nil;
              FreeAndNil(oConexionNueva);
            end;
          end;
        end);
      try
        oEspera.Esperar(oTarea);
      finally
        TTask.WaitForAll([oTarea]);
      end;
    finally
      Screen.Cursor := crCursorAnterior;
    end;
    if sError <> '' then
      raise Exception.Create(sError);
    if not Assigned(oResultadoNuevo) then
      raise Exception.Create(SCaptionCargandoDatosEspere);
    RegistroLog.RegistrarRendimiento(
      'MovVentasArt.Carga',
      Format('filas=%d; resultado completo', [iNumeroFilas]),
      nTiempoCarga);
    fxdsMovVentas.DataSet := nil;
    FResultadoMovimientos := nil;
    FRepositorioMovimientos := nil;
    FreeAndNil(FConexionMovimientos);
    FConexionMovimientos := oConexionNueva;
    oConexionNueva := nil;
    FRepositorioMovimientos := oRepositorioNuevo;
    FResultadoMovimientos := oResultadoNuevo;
  finally
    FreeAndNil(oEspera);
    oResultadoNuevo := nil;
    oRepositorioNuevo := nil;
    FreeAndNil(oConexionNueva);
  end;
end;

procedure TfrmPrintMovVentasArt.AfterReportLoaded;
begin
  inherited;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsMovVentas.DataSet := FResultadoMovimientos.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsMovVentas);
  ConfigurarDetalleArticuloAtributos;
  CompletarSubtotales;
  ActualizarFormulasPorcentajes;
  IncluirDetalleOcultoEnAcumulados;
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

procedure TfrmPrintMovVentasArt.IncluirDetalleOcultoEnAcumulados;
const
  SReferenciaDetalle = ',MasterData1)';
  SReferenciaDetalleOculto = ',MasterData1,1)';
var
  iComponente: Integer;
  oMemo: TfrxMemoView;
begin
  if FResumenAgrupado then
  begin
    for iComponente := 0 to frxrprt1.AllObjects.Count - 1 do
    begin
      if TObject(frxrprt1.AllObjects[iComponente]) is TfrxMemoView then
      begin
        oMemo := TfrxMemoView(frxrprt1.AllObjects[iComponente]);
        oMemo.Memo.Text := StringReplace(
          oMemo.Memo.Text, SReferenciaDetalle,
          SReferenciaDetalleOculto, [rfReplaceAll, rfIgnoreCase]);
      end;
    end;
  end;
end;

procedure TfrmPrintMovVentasArt.ConfigurarDetalleArticuloAtributos;
var
  aNiveles: TArray<string>;
  bAgruparArticulo: Boolean;
  bMostrarColor: Boolean;
  bMostrarTalla: Boolean;
  iNivel: Integer;
  iNivelArticulo: Integer;
  oComponente: TfrxComponent;
  sCampoColor: string;
  sCampoTalla: string;
  sDetalle: string;
  function TituloDetalle: string;
  var
    sNivel: string;
  begin
    Result := SCaptionArticuloAgrupacionMovimientosVentas;
    if FResumenAgrupado then
    begin
      sNivel := aNiveles[FNivelDetalleAgrupacion - 1];
      if SameText(sNivel, 'ALM') then
        Result := SCaptionAlmacenAgrupacionMovimientosVentas
      else if SameText(sNivel, 'PRV') then
        Result := SCaptionProveedorAgrupacionMovimientosVentas
      else if SameText(sNivel, 'FAM') then
        Result := SCaptionFamiliaAgrupacionMovimientosVentas
      else if SameText(sNivel, 'TMP') then
        Result := SCaptionTemporadaAgrupacionMovimientosVentas
      else if SameText(sNivel, 'COL') then
        Result := SCaptionColorAgrupacionMovimientosVentas
      else if SameText(sNivel, 'TAL') then
        Result := SCaptionTallaAgrupacionMovimientosVentas;
    end;
  end;
  procedure AnadirFragmento(const AFragmento: string);
  begin
    if AFragmento <> '' then
    begin
      if sDetalle <> '' then
        sDetalle := sDetalle + '  ';
      sDetalle := sDetalle + AFragmento;
    end;
  end;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active then
  begin
    aNiveles := NivelesAgrupacion;
    FNivelDetalleAgrupacion := Length(aNiveles);
    iNivelArticulo := IndexText('ART', aNiveles) + 1;
    bAgruparArticulo := iNivelArticulo > 0;
    FResumenAgrupado :=
      (FNivelDetalleAgrupacion > 0) and (not bAgruparArticulo);
    bMostrarColor := MatchText('COL', aNiveles);
    bMostrarTalla := MatchText('TAL', aNiveles);
    sCampoColor := '';
    if bMostrarColor and
       (FResultadoMovimientos.DataSet.FindField('COLOR_ETIQUETA') <> nil) then
      sCampoColor := 'COLOR_ETIQUETA'
    else if bMostrarColor and
            (FResultadoMovimientos.DataSet.FindField('COLOR') <> nil) then
      sCampoColor := 'COLOR';
    sCampoTalla := '';
    if bMostrarTalla and
       (FResultadoMovimientos.DataSet.FindField('TALLA_ETIQUETA') <> nil) then
      sCampoTalla := 'TALLA_ETIQUETA'
    else if bMostrarTalla and
            (FResultadoMovimientos.DataSet.FindField('TALLA') <> nil) then
      sCampoTalla := 'TALLA';
    for iNivel := 1 to 3 do
    begin
      oComponente := frxrprt1.FindObject(
        Format('MemoGF%dLbl', [iNivel]));
      if oComponente is TfrxMemoView then
      begin
        if FResumenAgrupado and
           (iNivel = FNivelDetalleAgrupacion) then
          TfrxMemoView(oComponente).Memo.Text := Format(
            '[MovVentas."GRUPO%d_ETIQ"]', [iNivel])
        else
          TfrxMemoView(oComponente).Memo.Text := Format(
            'TOTAL [MovVentas."GRUPO%d_ETIQ"]', [iNivel]);
      end;
    end;
    if bAgruparArticulo then
    begin
      oComponente := frxrprt1.FindObject(
        Format('MemoGF%dLbl', [iNivelArticulo]));
      if oComponente is TfrxMemoView then
        TfrxMemoView(oComponente).Memo.Text := Format(
          'TOTAL ARTÍCULO [MovVentas."GRUPO%d_COD"]',
          [iNivelArticulo]);
    end;
    oComponente := frxrprt1.FindObject('MemoHDesc');
    if oComponente is TfrxMemoView then
      TfrxMemoView(oComponente).Memo.Text := TituloDetalle;
    oComponente := frxrprt1.FindObject('MemoArtDesc');
    if oComponente is TfrxMemoView then
    begin
      sDetalle := '';
      if not bAgruparArticulo then
        AnadirFragmento('[MovVentas."CODIGO_ART_ART"]');
      if sCampoColor <> '' then
        AnadirFragmento('[MovVentas."' + sCampoColor + '"]');
      if sCampoTalla <> '' then
        AnadirFragmento(
          'Talla: [MovVentas."' + sCampoTalla + '"]');
      if not bAgruparArticulo then
        sDetalle := sDetalle + sLineBreak +
          '[MovVentas."DESCRIPCION_ART"]';
      TfrxMemoView(oComponente).Memo.Text := sDetalle;
    end;
  end;
end;

destructor TfrmPrintMovVentasArt.Destroy;
begin
  FotosArticulos.LimpiarPrecargaFotos;
  fxdsMovVentas.DataSet := nil;
  FResultadoMovimientos := nil;
  FRepositorioMovimientos := nil;
  FreeAndNil(FConexionMovimientos);
  inherited Destroy;
end;

procedure TfrmPrintMovVentasArt.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active and
     (not FResumenAgrupado) and
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
    if sNom = 'MasterData1' then
      TfrxBand(Component).Visible := not FResumenAgrupado
    else if (Pos('GroupHeaderG', sNom) = 1) or
            (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       (FResultadoMovimientos <> nil) and
       FResultadoMovimientos.DataSet.Active then
    begin
      TfrxBand(Component).Visible :=
        FResultadoMovimientos.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> '';
      if FResumenAgrupado and
         (nivel = FNivelDetalleAgrupacion) and
         (Pos('GroupHeaderG', sNom) = 1) then
        TfrxBand(Component).Visible := False;
    end
    else if (sNom = 'GroupHeaderFam') or (sNom = 'GroupFooterFam') then
      // La familia NO agrupa por sí sola: solo se agrupa por familia si se
      // elige FAM en la pestaña Agrupaciones (sale como "Familia: ...").
      TfrxBand(Component).Visible := False;
  end;
end;

procedure TfrmPrintMovVentasArt.ExportarExcelMovVentas(Sender: TObject);
var
  crCursorAnterior: TCursor;
  fPreview: TfrmMtoPreviewExcel;
  iLotesExcel: Integer;
  iNumeroFilas: Integer;
  nInicioExportacion: UInt64;
  nInicioLote: UInt64;
  nTiempoTrabajoExcel: UInt64;
  oEspera: TfrmEsperaMovVentas;
  oExportacion: IExportacionMovVentasArtPorLotes;
  oServiciosHoja: TServiciosHojaCalculo;
begin
  crCursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    preparar_consulta;
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName :=
        SNombreArchivoMovimientosVentasArticulos;
      oServiciosHoja := CrearServiciosHojaCalculoDevEx(
        fPreview.dxSpreadSheet1);
      oExportacion := CrearExportacionMovVentasArtExcelPorLotes(
        oServiciosHoja.Escritor,
        oServiciosHoja.Formateador,
        FResultadoMovimientos.DataSet,
        NivelesAgrupacion);
      iLotesExcel := 0;
      iNumeroFilas := FResultadoMovimientos.DataSet.RecordCount;
      nInicioExportacion := GetTickCount64;
      nTiempoTrabajoExcel := 0;
      oEspera := TfrmEsperaMovVentas.Create(Self);
      try
        oEspera.EsperarPorLotes(
          function: Boolean
          begin
            Inc(iLotesExcel);
            nInicioLote := GetTickCount64;
            repeat
              Result := oExportacion.ProcesarLote(
                FILAS_POR_PASO_EXCEL);
            until Result or
              (GetTickCount64 - nInicioLote >=
               DURACION_LOTE_EXCEL_MS);
            Inc(nTiempoTrabajoExcel,
              GetTickCount64 - nInicioLote);
          end);
      finally
        FreeAndNil(oEspera);
      end;
      RegistroLog.RegistrarRendimiento(
        'MovVentasArt.Excel',
        Format(
          'filas=%d; lotes=%d; trabajo=%d ms',
          [iNumeroFilas, iLotesExcel, nTiempoTrabajoExcel]),
        GetTickCount64 - nInicioExportacion);
      oExportacion := nil;
      Self.Hide;
      try
        fPreview.ShowModal;
      finally
        Self.Show;
      end;
    finally
      oExportacion := nil;
      FreeAndNil(fPreview);
    end;
  finally
    Screen.Cursor := crCursorAnterior;
  end;
end;

end.
