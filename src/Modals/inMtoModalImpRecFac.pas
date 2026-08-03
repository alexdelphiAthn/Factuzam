{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpRecFac                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de recibos de facturas.                                }
{    Soporta seleccion por factura actual o por rango de fechas.               }
{******************************************************************************}
unit inMtoModalImpRecFac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxDesgn, Data.DB, MemDS,
  DBAccess, Uni, frxExportXLSX, frxClass, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  Vcl.ComCtrls, dxCore, cxDateUtils, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxRadioGroup, cxGroupBox, cxTextEdit, cxLabel, UniDataFacturas,
  cxStyles, dxSkinsForm, cxClasses, cxLocalization, JvComponentBase, JvEnterTab,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization, frLanguageSpanish,
  frxExportBaseImageSettingsDialog, frCoreClasses,
  inLibInformeRecibosFacturaPersistenciaIntf;

type
  TfrmPrintRecFac = class(TfrmPrint)
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    edtNroFac: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbRangoFechas: TcxRadioButton;
    edtPlazoRecFac: TcxTextEdit;
    procedure rbActualClick(Sender: TObject);
    procedure rbRangoFechasClick(Sender: TObject);
  private
    FPreparadorInforme: IPreparadorInformeRecibosFactura;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    { Private declarations }
  public
    dmFac: TdmFacturas;
    { Public declarations }
  end;

implementation

uses
  UniDataInformeRecibosFacturaRepositorio;

{$R *.dfm}

{ TfrmPrintRecFac }

procedure TfrmPrintRecFac.AfterReportLoaded;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
end;

procedure TfrmPrintRecFac.preparar_consulta;
var
  criterios: TCriteriosInformeRecibosFactura;
begin
  inherited;
  criterios.ReciboActual := rbActual.Checked;
  criterios.Serie := edtSerie.Text;
  criterios.NumeroFactura := edtNroFac.Text;
  criterios.NumeroRecibo := edtPlazoRecFac.Text;
  if FPreparadorInforme = nil then
    FPreparadorInforme := CrearPreparadorInformeRecibosFacturaUniDAC(
      dmFac.unqryRecibosPrint);
  FPreparadorInforme.Preparar(criterios);
  dmFac.fxdsRecibos.UpdateBounds;
end;

procedure TfrmPrintRecFac.rbActualClick(Sender: TObject);
begin
   inherited;
//   dedDesde.Enabled := false;
//   dedHasta.Enabled := false;
end;

procedure TfrmPrintRecFac.rbRangoFechasClick(Sender: TObject);
begin
  inherited;
  //dedDesde.Enabled := true;
  //dedHasta.Enabled := true;
end;

end.
