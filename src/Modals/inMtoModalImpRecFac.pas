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
  frxExportBaseImageSettingsDialog, frCoreClasses;

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
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    { Private declarations }
  public
    dmFac: TdmFacturas;
    { Public declarations }
  end;

var
  frmPrintRecFac: TfrmPrintRecFac;

implementation

uses
  inLibFormatoDocumento;

{$R *.dfm}

{ TfrmPrintRecFac }

procedure TfrmPrintRecFac.AfterReportLoaded;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
end;

procedure TfrmPrintRecFac.preparar_consulta;
begin
  inherited;
  with dmFac do
  begin
  if rbActual.Checked = true then
  begin
    with unqryRecibosPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT r.*, ' +
                  ExpresionSqlFormatoDocumento(
                    'emp.FORMATO_DOCUMENTO_EMP',
                    'r.SERIE_FAC_REC',
                    'r.NUMERO_FAC_REC') +
                  ' AS DOCUMENTO_FACTURA_FORMATO ' +
                  '       FROM vi_recibos r ' +
                  '  LEFT JOIN fza_facturas fac ' +
                  '         ON fac.SERIE_FAC = r.SERIE_FAC_REC ' +
                  '        AND fac.NUMERO_FAC = r.NUMERO_FAC_REC ' +
                  '  LEFT JOIN fza_empresas emp ' +
                  '         ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC ' +
                  '      WHERE NUMERO_FAC_REC = :numfac ' +
                  '        AND SERIE_FAC_REC = :serie ' +
                  '        AND NUMERO_PLAZO_REC = :recibo ';
      Params.ParamByName('numfac').AsString := edtNroFac.text;
      Params.ParamByName('serie').AsString := edtSerie.text;
      Params.ParamByName('recibo').AsString := edtPlazoRecFac.text;
    end;
    unqryRecibosPrint.Open;
    fxdsRecibos.UpdateBounds;
  end;
  if rbRangoFechas.Checked = true then
  begin
    with unqryRecibosPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT r.*, ' +
                  ExpresionSqlFormatoDocumento(
                    'emp.FORMATO_DOCUMENTO_EMP',
                    'r.SERIE_FAC_REC',
                    'r.NUMERO_FAC_REC') +
                  ' AS DOCUMENTO_FACTURA_FORMATO ' +
                  '       FROM vi_recibos r ' +
                  '  LEFT JOIN fza_facturas fac ' +
                  '         ON fac.SERIE_FAC = r.SERIE_FAC_REC ' +
                  '        AND fac.NUMERO_FAC = r.NUMERO_FAC_REC ' +
                  '  LEFT JOIN fza_empresas emp ' +
                  '         ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC ' +
                  '      WHERE NUMERO_FAC_REC = :numfac ' +
                  '        AND SERIE_FAC_REC = :serie ' ;
      Params.ParamByName('numfac').AsString := edtNroFac.text;
      Params.ParamByName('serie').AsString := edtSerie.text;
    end;
    unqryRecibosPrint.Open;
    fxdsRecibos.UpdateBounds;
  end;
  end;
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
