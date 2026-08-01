{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpDocsProveedor                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Listado de documentos proveedor". Lista           }
{    cabeceras de pedidos, albaranes, facturas y devoluciones de compra,       }
{    con filtros de fechas, almacén destino, temporada, proveedor, tipo y      }
{    serie de documento. La temporada se toma solo de cabeceras de pedido o    }
{    de la sesión de compra que generó el documento; no se consulta la ficha   }
{    ni las propiedades del artículo.                                          }
{******************************************************************************}
unit inMtoModalImpDocsProveedor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel,
  cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses, dxSkinsForm,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization,
  frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab,
  cxLocalization;

type
  TfrmPrintDocsProveedor = class(TfrmPrintMultiFiltro)
    unqryDocsProveedorPrint: TUniQuery;
    fxdsDocsProveedor: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FclbTipos: TcxCheckListBox;
    FclbSeries: TcxCheckListBox;
    procedure CrearControlesPropios;
    procedure CargarTiposDocumento;
    procedure CargarSeriesDocumento;
    function CSVTipos: string;
    function CSVSeries: string;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    function SQLFiltroProveedores: string; override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  UniDataDocsProveedorSql, UniDataDocsProveedor;

{$R *.dfm}

{ TfrmPrintDocsProveedor }

function TfrmPrintDocsProveedor.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frProveedores, frTemporadas];
end;

function TfrmPrintDocsProveedor.SQLFiltroProveedores: string;
begin
  Result := SqlFiltroProveedoresDocumentosCompra;
end;

procedure TfrmPrintDocsProveedor.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    FInicializado := True;
  end;
end;

procedure TfrmPrintDocsProveedor.CrearControlesPropios;
begin
  FclbTipos := CrearTabChecklist('Tipos doc.');
  CargarTiposDocumento;
  FclbSeries := CrearTabChecklist('Series doc.');
  CargarSeriesDocumento;
end;

procedure TfrmPrintDocsProveedor.CargarTiposDocumento;

  procedure Agregar(const ACodigo, AEtiqueta: string);
  var
    oElemento: TcxCheckListBoxItem;
  begin
    oElemento := FclbTipos.Items.Add;
    oElemento.Text := ACodigo + ' - ' + AEtiqueta;
    oElemento.State := cbsUnchecked;
  end;

begin
  if FclbTipos <> nil then
  begin
    FclbTipos.Items.Clear;
    Agregar('PED', 'Pedidos');
    Agregar('ALB', 'Albaranes');
    Agregar('FAC', 'Facturas');
    Agregar('DEV', 'Devoluciones');
  end;
end;

procedure TfrmPrintDocsProveedor.CargarSeriesDocumento;
var
  aSeries: TArray<string>;
  oElemento: TcxCheckListBoxItem;
  sSerie: string;
begin
  if FclbSeries <> nil then
  begin
    FclbSeries.Items.Clear;
    aSeries := ListarSeriesDocumentosCompra(ConexionPrincipal);
    for sSerie in aSeries do
    begin
      oElemento := FclbSeries.Items.Add;
      oElemento.Text := sSerie;
      oElemento.State := cbsUnchecked;
    end;
  end;
end;

function TfrmPrintDocsProveedor.CSVSeries: string;
begin
  Result := SeleccionadosCSV(FclbSeries);
end;

function TfrmPrintDocsProveedor.CSVTipos: string;
begin
  Result := SeleccionadosCSV(FclbTipos);
end;

procedure TfrmPrintDocsProveedor.preparar_consulta;
begin
  inherited;
  with unqryDocsProveedorPrint do
  begin
    Close;
    Connection := ConexionPrincipal;
    SQL.Text := SqlListadoDocumentosProveedor;
    ParamByName('pDESDE').AsDateTime := FechaDesde;
    ParamByName('pHASTA').AsDateTime := FechaHasta;
    ParamByName('pALM').AsString := CSVAlmacenes;
    ParamByName('pPRV').AsString := CSVProveedores;
    ParamByName('pTMP').AsString := CSVTemporadas;
    ParamByName('pTIP').AsString := CSVTipos;
    ParamByName('pSER').AsString := CSVSeries;
    Open;
  end;
  fxdsDocsProveedor.UpdateBounds;
end;

procedure TfrmPrintDocsProveedor.AfterReportLoaded;
begin
  inherited;
  fxdsDocsProveedor.DataSet := unqryDocsProveedorPrint;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsDocsProveedor);
end;

end.
