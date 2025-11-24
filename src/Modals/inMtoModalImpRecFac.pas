{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
  cxRadioGroup, cxGroupBox, cxTextEdit, cxLabel, UniDataFacturas, inMtoFacturas,
  cxStyles, dxSkinsForm, cxClasses, cxLocalization, JvComponentBase, JvEnterTab;

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
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrintRecFac: TfrmPrintRecFac;

implementation

{$R *.dfm}

{ TfrmPrintRecFac }

procedure TfrmPrintRecFac.preparar_consulta;
begin
  inherited;
  if rbActual.Checked = true then
  begin
    with dmmFacturas.unqryRecibosPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT *  ' +
                  '       FROM vi_recibos' +
                  '      WHERE NRO_FACTURA_RECIBO = :numfac ' +
                  '        AND SERIE_FACTURA_RECIBO = :serie ' +
                  '        AND NRO_PLAZO_RECIBO = :recibo ';
      Params.ParamByName('numfac').AsString := edtNroFac.text;
      Params.ParamByName('serie').AsString := edtSerie.text;
      Params.ParamByName('recibo').AsString := edtPlazoRecFac.text;
    end;
    dmmFacturas.unqryRecibosPrint.Open;
    dmmFacturas.fxdsRecibos.UpdateBounds;
  end;
  if rbRangoFechas.Checked = true then
  begin
    with dmmFacturas.unqryRecibosPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT *  ' +
                  '       FROM vi_recibos ' +
                  '      WHERE NRO_FACTURA_RECIBO = :numfac ' +
                  '        AND SERIE_FACTURA_RECIBO = :serie ' ;
      Params.ParamByName('numfac').AsString := edtNroFac.text;
      Params.ParamByName('serie').AsString := edtSerie.text;
    end;
    dmmFacturas.unqryRecibosPrint.Open;
    dmmFacturas.fxdsRecibos.UpdateBounds;
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
