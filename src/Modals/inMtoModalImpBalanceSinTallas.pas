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
  frLocalization, frLanguageSpanish, frCoreClasses;

type
  TfrmPrintBalanceSinTallas = class(TfrmPrintMultiFiltro)
    unqryBalancePrint: TUniQuery;
    fxdsBalance: TfrxDBDataset;
  private
    FInicializado: Boolean;
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
  dxSpreadSheet, inLibFotos;

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
  FclbBandas := CrearTabChecklist('Bandas');
  CargarBandas;
  // Pestaña "Agrupaciones": almacén/proveedor/familia/temporada reordenables
  // + spin de nivel de familia.
  CrearTabAgrupacion('Agrupaciones',
    ['ALM', 'PRV', 'FAM', 'TMP'],
    ['Almac' + #233 + 'n', 'Proveedor', 'Familia', 'Temporada'], True);
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
      Agregar('ENT',    'Entradas');
      Agregar('VEN',    'Ventas');
      Agregar('EXIFIN', 'Existencias finales');
    end
    else if (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
    begin
      // Entre fechas, desglosado (subtipos Ctrl+U; traspasos/depósitos netos,
      // sin bandas de salida salvo alb. venta).
      Agregar('EXIINI', 'Existencias iniciales');
      Agregar('ENTCMP', 'Ent. compra');
      Agregar('ENTALB', 'Alb. entrada');
      Agregar('ENTTRA', 'Traspasos (neto)');
      Agregar('ENTDEP', string('Dep'#243'sitos (neto)'));
      Agregar('ENTREG', 'Regulariz.');
      Agregar('SALALB', 'Alb. venta');
      Agregar('VEN',    'Ventas');
      Agregar('EXIFIN', 'Existencias finales');
    end
    else
    begin
      // Entre fechas, simplificado (sin Salidas).
      Agregar('EXIINI', 'Existencias iniciales');
      Agregar('ENT',    'Entradas');
      Agregar('VEN',    'Ventas');
      Agregar('EXIFIN', 'Existencias finales');
    end;
  end;
end;

procedure TfrmPrintBalanceSinTallas.preparar_consulta;
var
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
  with unqryBalancePrint do
  begin
    Close;
    Connection := ConexionPrincipal;
    SQL.Text :=
      'CALL PRC_GET_BALANCE_ALMACEN_SIN_TALLAS(' +
      ':pMODO, :pDESDE, :pHASTA, :pALM, :pFAM, :pPRV, :pTMP, :pART, :pTAR, ' +
      ':pDESG, :pBND, :pN1, :pN2, :pN3, :pNFAM)';
    if (FrgModo <> nil) and (FrgModo.ItemIndex = 1) then
      ParamByName('pMODO').AsString := 'A'
    else
      ParamByName('pMODO').AsString := 'F';
    ParamByName('pDESDE').AsDateTime := FechaDesde;
    ParamByName('pHASTA').AsDateTime := FechaHasta;
    ParamByName('pALM').AsString := CSVAlmacenes;
    ParamByName('pFAM').AsString := CSVFamilias;
    ParamByName('pPRV').AsString := CSVProveedores;
    ParamByName('pTMP').AsString := CSVTemporadas;
    // Filtro de artículos (CSV; vacío = todos), nuevo en la pestaña Artículos.
    ParamByName('pART').AsString := CSVArticulos;
    ParamByName('pTAR').AsString := ParametrosCaja.TarifaDefecto;
    if (FrgModo <> nil) and (FrgModo.ItemIndex = 0) and
       (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
      ParamByName('pDESG').AsString := 'S'
    else
      ParamByName('pDESG').AsString := 'N';
    ParamByName('pBND').AsString := SeleccionadosCSV(FclbBandas);
    ParamByName('pN1').AsString := NivelN(0);
    ParamByName('pN2').AsString := NivelN(1);
    ParamByName('pN3').AsString := NivelN(2);
    ParamByName('pNFAM').AsInteger := NivelFamilia;
    Open;
  end;
  fxdsBalance.UpdateBounds;
end;

procedure TfrmPrintBalanceSinTallas.AfterReportLoaded;
begin
  inherited;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsBalance.DataSet := unqryBalancePrint;
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
  oFotos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintBalanceSinTallas.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if unqryBalancePrint.Active and (not unqryBalancePrint.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      unqryBalancePrint.DisableControls;
      try
        unqryBalancePrint.First;
        while not unqryBalancePrint.Eof do
        begin
          slCod.Add(unqryBalancePrint.FieldByName('CODIGO_ART_ART').AsString);
          unqryBalancePrint.Next;
        end;
      finally
        unqryBalancePrint.EnableControls;
      end;
      oFotos.PrecargarFotosLote(slCod.ToStringArray);
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
  oFotos.HandlerReportBeforePrint(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if (Pos('GroupHeaderG', sNom) = 1) or (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and unqryBalancePrint.Active then
      TfrxBand(Component).Visible :=
        unqryBalancePrint.FieldByName(
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
      fPreview.DialogoGuardar.FileName := 'Balance_almacen_sin_tallas';
      ExportarBalanceSinTallasExcel(fPreview.dxSpreadSheet1, unqryBalancePrint);
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
