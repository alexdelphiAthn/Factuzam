{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpBalanceTallas                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.1.0                                                         }
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
  frLocalization, frLanguageSpanish, frCoreClasses, inLibGlobalVar;

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
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

var
  frmPrintBalanceTallas: TfrmPrintBalanceTallas;

implementation

{$R *.dfm}

uses
  System.StrUtils, inLibAppParam, inMtoPreviewExcel, inLibBalanceTallasExcel,
  dxSpreadSheet;

{ TfrmPrintBalanceTallas }

function TfrmPrintBalanceTallas.FiltrosUsados: TFiltrosReport;
begin
  // El balance usa todas las pestañas de filtro.
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas];
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
      // Por acumulados.
      Agregar('ENT',    'Entradas');
      Agregar('SAL',    'Salidas');
      Agregar('VEN',    'Ventas');
      Agregar('EXIFIN', 'Existencias finales');
    end
    else if (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
    begin
      // Entre fechas, desglosado (subtipos de la consulta Ctrl+U).
      Agregar('EXIINI', 'Existencias iniciales');
      Agregar('ENTCMP', 'Ent. compra');
      Agregar('ENTALB', 'Alb. entrada');
      Agregar('ENTTRA', 'Ent. traspaso');
      Agregar('ENTDEP', 'Ent. dep'#243'sito');
      Agregar('ENTREG', 'Regulariz.');
      Agregar('SALTRA', 'Sal. traspaso');
      Agregar('SALDEP', 'Sal. dep'#243'sito');
      Agregar('SALALB', 'Alb. venta');
      Agregar('VEN',    'Ventas');
      Agregar('EXIFIN', 'Existencias finales');
    end
    else
    begin
      // Entre fechas, simplificado.
      Agregar('EXIINI', 'Existencias iniciales');
      Agregar('ENT',    'Entradas');
      Agregar('SAL',    'Salidas');
      Agregar('VEN',    'Ventas');
      Agregar('EXIFIN', 'Existencias finales');
    end;
  end;
end;

procedure TfrmPrintBalanceTallas.preparar_consulta;
begin
  inherited;
  // Llamada al SP con los filtros múltiples (CSV) del base y el modo/detalle
  // propios. La tarifa de valoración es la tarifa por defecto del entorno.
  with unqryBalancePrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      'CALL PRC_GET_BALANCE_ALMACEN_TALLAS(' +
      ':pMODO, :pDESDE, :pHASTA, :pALM, :pFAM, :pPRV, :pTMP, :pTAR, ' +
      ':pDESG, :pBND)';
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
    ParamByName('pTAR').AsString :=
      oAppParams.GetString('appTarifaDefecto', 'PVP');
    if (FrgModo <> nil) and (FrgModo.ItemIndex = 0) and
       (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
      ParamByName('pDESG').AsString := 'S'
    else
      ParamByName('pDESG').AsString := 'N';
    ParamByName('pBND').AsString := SeleccionadosCSV(FclbBandas);
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
      fPreview.DialogoGuardar.InitialDir := oAppParams.GetPath('appDirExcel');
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
