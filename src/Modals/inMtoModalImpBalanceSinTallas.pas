{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpBalanceSinTallas                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Balance de almacén SIN tallas" (FastReport).      }
{    Variante vertical del balance por tallas: una fila por (artículo, color,  }
{    banda) con Cantidad / Precio / Importe, sin las columnas de talla, por lo }
{    que incluye TODOS los artículos (también los no tallables). Mantiene la   }
{    foto del artículo. Se apoya en el SP PRC_GET_BALANCE_ALMACEN_SIN_TALLAS   }
{    (ver DESARROLLOS EN CURSO/balance_almacen_sin_tallas.sql).                }
{                                                                              }
{    Hereda de TfrmPrintMultiFiltro (filtros múltiples + agrupaciones). Solo   }
{    añade el modo (entre fechas / acumulados), el detalle (simplificado /     }
{    desglosado), la pestaña de bandas, la plantilla del informe y la consulta.}
{******************************************************************************}
unit inMtoModalImpBalanceSinTallas;

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
  inLibInformeBalanceSinTallasPersistenciaIntf;

type
  TfrmPrintBalanceSinTallas = class(TfrmPrintMultiFiltro)
    fxdsBalance: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FRepositorioBalance: IRepositorioInformeBalanceSinTallas;
    FResultadoBalance: IResultadoInformeBalanceSinTallas;
    FrgModo: TcxRadioGroup;       // 0 = Entre fechas, 1 = Por acumulados
    FrgDetalle: TcxRadioGroup;    // 0 = Simplificado, 1 = Desglosado
    FclbBandas: TcxCheckListBox;  // qué bandas mostrar (sin marcar = todas)
    procedure CrearControlesModo;
    procedure CargarBandas;
    procedure ActualizarHabilitacion;
    procedure rgConfigChange(Sender: TObject);
    // Exportación a Excel propia (sustituye al export FastReport del base).
    procedure ExportarExcelBalance(Sender: TObject);
    // Handler de OnBeforePrint: fotos + ocultar bandas de grupo inactivas.
    procedure ReportBeforePrint(Component: TfrxReportComponent);
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
  System.StrUtils, inMtoPreviewExcel, inLibMsgArticulos,
  inLibBalanceSinTallasExcel,
  dxSpreadSheet, inLibFotos,
  UniDataInformeBalanceSinTallasRepositorio;

resourcestring
  SNombreArchivoBalanceAlmacenSinTallas =
    'Balance_almacen_sin_tallas';
  SCaptionBandasBalanceSinTallas = 'Bandas';
  SCaptionAgrupacionesBalanceSinTallas = 'Agrupaciones';
  SCaptionAlmacenBalanceSinTallas = 'Almacén';
  SCaptionProveedorBalanceSinTallas = 'Proveedor';
  SCaptionFamiliaBalanceSinTallas = 'Familia';
  SCaptionTemporadaBalanceSinTallas = 'Temporada';
  SCaptionEntradasBalanceSinTallas = 'Entradas';
  SCaptionVentasBalanceSinTallas = 'Ventas';
  SCaptionExistenciasFinalesBalanceSinTallas = 'Existencias finales';
  SCaptionExistenciasInicialesBalanceSinTallas = 'Existencias iniciales';
  SCaptionEntradaCompraBalanceSinTallas = 'Ent. compra';
  SCaptionAlbaranEntradaBalanceSinTallas = 'Alb. entrada';
  SCaptionTraspasosBalanceSinTallas = 'Traspasos (neto)';
  SCaptionDepositosBalanceSinTallas = 'Depósitos (neto)';
  SCaptionRegularizacionesBalanceSinTallas = 'Regulariz.';
  SCaptionAlbaranVentaBalanceSinTallas = 'Alb. venta';

{ TfrmPrintBalanceSinTallas }

function TfrmPrintBalanceSinTallas.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas,
             frArticulos];
end;

procedure TfrmPrintBalanceSinTallas.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesModo;
    // El botón Excel del base exporta el FastReport a XLSX (farragoso); lo
    // redirigimos a una exportación limpia con el mismo layout que el informe.
    btnExcel.OnClick := ExportarExcelBalance;
    FInicializado := True;
    ActualizarHabilitacion;
  end;
end;

procedure TfrmPrintBalanceSinTallas.CrearControlesModo;
begin
  if TabFechas <> nil then
  begin
    FrgModo := TcxRadioGroup.Create(Self);
    FrgModo.Parent  := TabFechas;
    FrgModo.Left    := 220;
    FrgModo.Top     := 12;
    FrgModo.Width   := 210;
    FrgModo.Height  := 80;
    FrgModo.Caption := SCaptionGrupoModo;
    FrgModo.Properties.Items.Add.Caption := SCaptionModoEntreFechas;
    FrgModo.Properties.Items.Add.Caption := SCaptionModoPorAcumulados;
    FrgModo.ItemIndex := 0;
    FrgModo.Properties.OnEditValueChanged := rgConfigChange;
    FrgDetalle := TcxRadioGroup.Create(Self);
    FrgDetalle.Parent  := TabFechas;
    FrgDetalle.Left    := 220;
    FrgDetalle.Top     := 100;
    FrgDetalle.Width   := 210;
    FrgDetalle.Height  := 80;
    FrgDetalle.Caption := SCaptionGrupoDetalle;
    FrgDetalle.Properties.Items.Add.Caption := SCaptionModoSimplificado;
    FrgDetalle.Properties.Items.Add.Caption := SCaptionModoDesglosado;
    FrgDetalle.ItemIndex := 0;
    FrgDetalle.Properties.OnEditValueChanged := rgConfigChange;
  end;
  // Pestaña "Bandas": qué bandas mostrar (según modo/detalle).
  FclbBandas := CrearTabChecklist(SCaptionBandasBalanceSinTallas);
  CargarBandas;
  // Pestaña "Agrupaciones": almacén/proveedor/familia/temporada reordenables
  // + spin de nivel de familia.
  CrearTabAgrupacion(SCaptionAgrupacionesBalanceSinTallas,
    ['ALM', 'PRV', 'FAM', 'TMP'],
    [SCaptionAlmacenBalanceSinTallas,
     SCaptionProveedorBalanceSinTallas,
     SCaptionFamiliaBalanceSinTallas,
     SCaptionTemporadaBalanceSinTallas], True);
end;

procedure TfrmPrintBalanceSinTallas.ActualizarHabilitacion;
var
  bFechas: Boolean;
begin
  bFechas := (FrgModo = nil) or (FrgModo.ItemIndex = 0);
  if DteDesde <> nil then
    DteDesde.Enabled := bFechas;
  if DteHasta <> nil then
    DteHasta.Enabled := bFechas;
  if FrgDetalle <> nil then
    FrgDetalle.Enabled := bFechas;
end;

procedure TfrmPrintBalanceSinTallas.rgConfigChange(Sender: TObject);
begin
  ActualizarHabilitacion;
  CargarBandas;
end;

procedure TfrmPrintBalanceSinTallas.CargarBandas;

  procedure Agregar(const ACod, AEtiq: string);
  var
    item: TcxCheckListBoxItem;
  begin
    item := FclbBandas.Items.Add;
    item.Text  := ACod + ' - ' + AEtiq;
    item.State := cbsUnchecked;
  end;

begin
  if FclbBandas <> nil then
  begin
    FclbBandas.Items.Clear;
    if (FrgModo <> nil) and (FrgModo.ItemIndex = 1) then
    begin
      // Por acumulados (sin Salidas: traspasos neteados en Entradas).
      Agregar('ENT',    SCaptionEntradasBalanceSinTallas);
      Agregar('VEN',    SCaptionVentasBalanceSinTallas);
      Agregar('EXIFIN', SCaptionExistenciasFinalesBalanceSinTallas);
    end
    else if (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
    begin
      // Entre fechas, desglosado (subtipos Ctrl+U; traspasos/depósitos netos,
      // sin bandas de salida salvo alb. venta).
      Agregar('EXIINI', SCaptionExistenciasInicialesBalanceSinTallas);
      Agregar('ENTCMP', SCaptionEntradaCompraBalanceSinTallas);
      Agregar('ENTALB', SCaptionAlbaranEntradaBalanceSinTallas);
      Agregar('ENTTRA', SCaptionTraspasosBalanceSinTallas);
      Agregar('ENTDEP', SCaptionDepositosBalanceSinTallas);
      Agregar('ENTREG', SCaptionRegularizacionesBalanceSinTallas);
      Agregar('SALALB', SCaptionAlbaranVentaBalanceSinTallas);
      Agregar('VEN',    SCaptionVentasBalanceSinTallas);
      Agregar('EXIFIN', SCaptionExistenciasFinalesBalanceSinTallas);
    end
    else
    begin
      // Entre fechas, simplificado (sin Salidas).
      Agregar('EXIINI', SCaptionExistenciasInicialesBalanceSinTallas);
      Agregar('ENT',    SCaptionEntradasBalanceSinTallas);
      Agregar('VEN',    SCaptionVentasBalanceSinTallas);
      Agregar('EXIFIN', SCaptionExistenciasFinalesBalanceSinTallas);
    end;
  end;
end;

procedure TfrmPrintBalanceSinTallas.preparar_consulta;
var
  criterios: TCriteriosInformeBalanceSinTallas;
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
  if (FrgModo <> nil) and (FrgModo.ItemIndex = 1) then
    criterios.Modo := 'A'
  else
    criterios.Modo := 'F';
  criterios.FechaDesde := FechaDesde;
  criterios.FechaHasta := FechaHasta;
  criterios.Almacenes := CSVAlmacenes;
  criterios.Familias := CSVFamilias;
  criterios.Proveedores := CSVProveedores;
  criterios.Temporadas := CSVTemporadas;
  criterios.Articulos := CSVArticulos;
  criterios.Tarifa := ParametrosCaja.TarifaDefecto;
  if (FrgModo <> nil) and (FrgModo.ItemIndex = 0) and
     (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
    criterios.Desglosado := 'S'
  else
    criterios.Desglosado := 'N';
  criterios.Bandas := SeleccionadosCSV(FclbBandas);
  criterios.Nivel1 := NivelN(0);
  criterios.Nivel2 := NivelN(1);
  criterios.Nivel3 := NivelN(2);
  criterios.NivelFamilia := NivelFamilia;
  if FRepositorioBalance = nil then
    FRepositorioBalance := CrearRepositorioInformeBalanceSinTallasUniDAC(
      ConexionPrincipal);
  FResultadoBalance := FRepositorioBalance.Preparar(criterios);
  fxdsBalance.UpdateBounds;
end;

procedure TfrmPrintBalanceSinTallas.AfterReportLoaded;
begin
  inherited;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsBalance.DataSet := FResultadoBalance.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsBalance);
  // Sustituimos el OnBeforePrint del base (fotos) por el nuestro, que encadena
  // las fotos y oculta las bandas de grupo de los niveles inactivos.
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  // Precarga de fotos a nivel artículo en UNA consulta (evita el N+1).
  PrecargarFotosArticulos;
end;

destructor TfrmPrintBalanceSinTallas.Destroy;
begin
  FotosArticulos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintBalanceSinTallas.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active and
     (not FResultadoBalance.DataSet.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      FResultadoBalance.DataSet.DisableControls;
      try
        FResultadoBalance.DataSet.First;
        while not FResultadoBalance.DataSet.Eof do
        begin
          slCod.Add(FResultadoBalance.DataSet.FieldByName(
            'CODIGO_ART_ART').AsString);
          FResultadoBalance.DataSet.Next;
        end;
      finally
        FResultadoBalance.DataSet.EnableControls;
      end;
      FotosArticulos.PrecargarFotosLote(slCod.ToStringArray);
    finally
      FreeAndNil(slCod);
    end;
  end;
end;

procedure TfrmPrintBalanceSinTallas.ReportBeforePrint(
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
       (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active then
      TfrxBand(Component).Visible :=
        FResultadoBalance.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> ''
    else if (sNom = 'GroupHeaderFam') or (sNom = 'GroupFooterFam') then
      // La familia NO agrupa por sí sola: solo se agrupa por familia si se
      // elige FAM en la pestaña Agrupaciones (sale como "Familia: ..."). La
      // cabecera fija de familia queda siempre oculta.
      TfrxBand(Component).Visible := False;
  end;
end;

procedure TfrmPrintBalanceSinTallas.ExportarExcelBalance(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
begin
  preparar_consulta;
  Self.Hide;
  try
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName :=
        SNombreArchivoBalanceAlmacenSinTallas;
      ExportarBalanceSinTallasExcel(
        fPreview.dxSpreadSheet1, FResultadoBalance.DataSet, FotosArticulos);
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
