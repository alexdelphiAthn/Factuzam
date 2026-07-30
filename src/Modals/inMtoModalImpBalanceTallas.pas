{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpBalanceTallas                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.2.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Balance de almacén por tallas" (FastReport).      }
{    Informe A4 horizontal con la foto del artículo, agrupado por familia y    }
{    artículo, con las tallas como columnas y los colores/estados como         }
{    bandas. Se apoya en el SP PRC_GET_BALANCE_ALMACEN_TALLAS (ver             }
{    DESARROLLOS EN CURSO/balance_almacen_tallas.sql).                         }
{                                                                              }
{    Hereda de TfrmPrintMultiFiltro, que aporta las pestañas de filtros        }
{    múltiples (almacenes, familias, proveedores, temporadas y fechas). Este   }
{    modal solo añade el modo (entre fechas / acumulados) y el nivel de        }
{    detalle (simplificado / desglosado) sobre la pestaña de fechas, y la      }
{    plantilla del informe + la consulta.                                      }
{******************************************************************************}
unit inMtoModalImpBalanceTallas;

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
  TfrmPrintBalanceTallas = class(TfrmPrintMultiFiltro)
    unqryBalancePrint: TUniQuery;
    fxdsBalance: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FrgModo: TcxRadioGroup;       // 0 = Entre fechas, 1 = Por acumulados
    FrgDetalle: TcxRadioGroup;    // 0 = Simplificado, 1 = Desglosado
    FclbBandas: TcxCheckListBox;  // qué bandas mostrar (sin marcar = todas)
    // Crea los radios de modo/detalle y la pestaña de bandas.
    procedure CrearControlesModo;
    procedure CargarBandas;
    procedure ActualizarHabilitacion;
    procedure rgConfigChange(Sender: TObject);
    // Exportación a Excel propia (sustituye al export FastReport del base).
    procedure ExportarExcelBalance(Sender: TObject);
    // Handler de OnBeforePrint del report: mantiene el refresco de fotos del
    // base y oculta las bandas de grupo de los niveles no usados.
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
  System.StrUtils, inMtoPreviewExcel,
  inLibBalanceTallasExcel,
  dxSpreadSheet, inLibFotos;

{ TfrmPrintBalanceTallas }

function TfrmPrintBalanceTallas.FiltrosUsados: TFiltrosReport;
begin
  // El balance usa todas las pestañas de filtro.
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas,
             frArticulos];
end;

procedure TfrmPrintBalanceTallas.DoShow;
begin
  inherited;
  // El base ya ha creado las pestañas de filtro (incluida Fechas). Añadimos
  // una sola vez los radios de modo/detalle sobre la pestaña de fechas.
  if not FInicializado then
  begin
    CrearControlesModo;
    // El botón Excel del base exporta el FastReport a XLSX (queda farragoso
    // con un informe agrupado). Lo redirigimos a una exportación limpia con
    // el mismo layout que el informe.
    btnExcel.OnClick := ExportarExcelBalance;
    FInicializado := True;
    ActualizarHabilitacion;
  end;
end;

procedure TfrmPrintBalanceTallas.CrearControlesModo;
begin
  if TabFechas <> nil then
  begin
    FrgModo := TcxRadioGroup.Create(Self);
    FrgModo.Parent  := TabFechas;
    FrgModo.Left    := 220;
    FrgModo.Top     := 12;
    FrgModo.Width   := 210;
    FrgModo.Height  := 80;
    FrgModo.Caption := ' Modo ';
    FrgModo.Properties.Items.Add.Caption := 'Entre fechas';
    FrgModo.Properties.Items.Add.Caption := 'Por acumulados';
    FrgModo.ItemIndex := 0;
    FrgModo.Properties.OnEditValueChanged := rgConfigChange;
    FrgDetalle := TcxRadioGroup.Create(Self);
    FrgDetalle.Parent  := TabFechas;
    FrgDetalle.Left    := 220;
    FrgDetalle.Top     := 100;
    FrgDetalle.Width   := 210;
    FrgDetalle.Height  := 80;
    FrgDetalle.Caption := ' Detalle ';
    FrgDetalle.Properties.Items.Add.Caption := 'Simplificado';
    FrgDetalle.Properties.Items.Add.Caption := 'Desglosado';
    FrgDetalle.ItemIndex := 0;
    FrgDetalle.Properties.OnEditValueChanged := rgConfigChange;
  end;
  // Pestaña "Bandas": qué bandas mostrar. Se rellena según modo/detalle y se
  // refresca al cambiarlos (las bandas disponibles cambian).
  FclbBandas := CrearTabChecklist('Bandas');
  CargarBandas;
  // Pestaña "Agrupaciones": agrupa (con resumen por grupo) por almacén,
  // proveedor, familia y/o temporada, en el orden elegido. El spin de nivel de
  // familia permite agrupar por la familia raíz o por un nivel intermedio.
  CrearTabAgrupacion('Agrupaciones',
    ['ALM', 'PRV', 'FAM', 'TMP'],
    ['Almac' + #233 + 'n', 'Proveedor', 'Familia', 'Temporada'], True);
end;

procedure TfrmPrintBalanceTallas.ActualizarHabilitacion;
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

procedure TfrmPrintBalanceTallas.rgConfigChange(Sender: TObject);
begin
  ActualizarHabilitacion;
  CargarBandas;
end;

procedure TfrmPrintBalanceTallas.CargarBandas;

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

procedure TfrmPrintBalanceTallas.preparar_consulta;
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
  // Niveles de agrupación marcados (en el orden elegido) y nivel de familia.
  niveles := NivelesAgrupacion;
  // Llamada al SP con los filtros múltiples (CSV) del base y el modo/detalle
  // propios. La tarifa de valoración es la tarifa por defecto del entorno.
  with unqryBalancePrint do
  begin
    Close;
    Connection := ConexionPrincipal;
    SQL.Text :=
      'CALL PRC_GET_BALANCE_ALMACEN_TALLAS(' +
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

procedure TfrmPrintBalanceTallas.AfterReportLoaded;
begin
  inherited;
  // El TfrxDBDataset debe enlazar la query por DataSet directo (no por
  // DataSource): la resolución de la foto lee TfrxDBDataset.DataSet en
  // inLibFotos.ObtenerDataSetDeBandaPadre, que es nil si solo se fija el
  // DataSource. Reafirmamos el enlace y el registro en el report.
  fxdsBalance.DataSet := unqryBalancePrint;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsBalance);
  // El base ha enganchado el OnBeforePrint a las fotos. Lo sustituimos por el
  // nuestro, que encadena las fotos y además oculta las bandas de grupo de los
  // niveles inactivos (sin esto, FastReport pinta una banda vacía por nivel).
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  // Precarga de fotos a nivel artículo en UNA consulta: el handler de fotos
  // (oFotos.Resolver) las toma de la caché y no hace un SELECT por artículo
  // (antes era un N+1 con muchas fotos).
  PrecargarFotosArticulos;
end;

destructor TfrmPrintBalanceTallas.Destroy;
begin
  // Vaciar la caché de precarga de fotos (vive durante el modal).
  oFotos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintBalanceTallas.PrecargarFotosArticulos;
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

procedure TfrmPrintBalanceTallas.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  sNom : string;
  nivel: Integer;
begin
  // 1) Mantener el refresco de la foto del artículo (foto300/600/real) que
  //    hace el base a través de oFotos.
  oFotos.HandlerReportBeforePrint(Component);
  // 2) Ocultar las bandas de grupo (cabecera y pie) cuyo nivel no está activo:
  //    el SP devuelve GRUPOn_ETIQ vacío para los niveles no usados. Como los
  //    niveles inactivos van siempre al final (el modal los manda compactados),
  //    su condición es constante y FastReport pintaría una banda vacía.
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
      // 3) La familia NO agrupa por sí sola: solo se agrupa por familia si se
      //    elige FAM en la pestaña Agrupaciones (sale como "Familia: ..."). La
      //    cabecera fija de familia queda siempre oculta.
      TfrxBand(Component).Visible := False;
  end;
end;

procedure TfrmPrintBalanceTallas.ExportarExcelBalance(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
begin
  // Ejecuta el SP con los filtros actuales y vuelca el resultado en una hoja
  // con el mismo layout que el informe (familia / artículo / tallas en
  // columnas / bandas en filas). El visor permite guardar a .xlsx. Como el
  // modal es fsStayOnTop, nos ocultamos mientras se muestra el visor.
  preparar_consulta;
  Self.Hide;
  try
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName := 'Balance_almacen_tallas';
      ExportarBalanceTallasExcel(fPreview.dxSpreadSheet1, unqryBalancePrint);
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
