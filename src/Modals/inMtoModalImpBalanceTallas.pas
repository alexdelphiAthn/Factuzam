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
    // Crea los radios de modo/detalle sobre la pestaña de fechas del base.
    procedure CrearControlesModo;
    procedure ActualizarHabilitacion;
    procedure rgModoChange(Sender: TObject);
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
  System.StrUtils, inLibAppParam;

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
    FrgModo.Left    := 210;
    FrgModo.Top     := 8;
    FrgModo.Width   := 190;
    FrgModo.Height  := 56;
    FrgModo.Caption := ' Modo ';
    FrgModo.Properties.Items.Add.Caption := 'Entre fechas';
    FrgModo.Properties.Items.Add.Caption := 'Por acumulados';
    FrgModo.ItemIndex := 0;
    FrgModo.Properties.OnEditValueChanged := rgModoChange;
    FrgDetalle := TcxRadioGroup.Create(Self);
    FrgDetalle.Parent  := TabFechas;
    FrgDetalle.Left    := 210;
    FrgDetalle.Top     := 70;
    FrgDetalle.Width   := 190;
    FrgDetalle.Height  := 56;
    FrgDetalle.Caption := ' Detalle (entre fechas) ';
    FrgDetalle.Properties.Items.Add.Caption := 'Simplificado';
    FrgDetalle.Properties.Items.Add.Caption := 'Desglosado';
    FrgDetalle.ItemIndex := 0;
  end;
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

procedure TfrmPrintBalanceTallas.rgModoChange(Sender: TObject);
begin
  ActualizarHabilitacion;
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
      ':pMODO, :pDESDE, :pHASTA, :pALM, :pFAM, :pPRV, :pTMP, :pTAR, :pDESG)';
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

end.
