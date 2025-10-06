{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoModalImpFac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxClass,
  frxExportBaseDialog, frxExportPDF, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls,
  cxControls, cxContainer, cxEdit, Vcl.ComCtrls, dxCore, cxDateUtils,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxRadioGroup, cxGroupBox, cxLabel,
  cxTextEdit, UniDataFacturas, inMtoFacturas, DB, frxExportXLSX, MemDS,
  DBAccess, Uni, frxDesgn, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  dxSkinsCore, dxSkinBlue, JvComponentBase, JvEnterTab, dxSkinBasic,
  dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue;

type
  TfrmPrintFac = class(TfrmPrint)
    edtNroFac: TcxTextEdit;
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbRangoFechas: TcxRadioButton;
    dedDesde: TcxDateEdit;
    dedHasta: TcxDateEdit;
    lblcxlbl2: TcxLabel;
    lblcxlbl3: TcxLabel;
    procedure rbRangoFechasClick(Sender: TObject);
    procedure rbActualClick(Sender: TObject);
  public
    procedure preparar_consulta; override;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrintFac: TfrmPrintFac;

implementation

{$R *.dfm}

{ TfrmPrintFac }

procedure TfrmPrintFac.preparar_consulta;
begin
  if rbActual.Checked = true then
  begin
    with dmmFacturas.unqryFacPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT *  ' +
                  '       FROM vi_FACTURAS_print f' +
                  '      WHERE NRO_FACTURA = :numfac' +
                  '        AND SERIE_FACTURA = :serie';
      Params.ParamByName('numfac').Value := edtNroFac.text;
      Params.ParamByName('serie').Value := edtSerie.text;
    end;
    dmmFacturas.unqryFacPrint.Open;
    //dmmFacturas.fxdsPrintFac.OpenDataSource;
    dmmFacturas.fxdsPrintFac.UpdateBounds;
    with dmmFacturas.unqryLinFacPrint do
    begin
      Params.Clear;
      SQL.Text := '       SELECT * ' +
                  '         FROM vi_FACTURAS_LINEAS_print V  ' +
                  '        WHERE V.NRO_FACTURA_LINEA = :numfac' +
                  '          AND V.SERIE_FACTURA_LINEA = :serie ' +
                  '     order by V.LINEA_FACTURA_LINEA';
      Params.ParamByName('numfac').Value := edtNroFac.text;
      Params.ParamByName('serie').Value := edtSerie.text;
      end;
    dmmFacturas.unqryLinFacPrint.MasterSource := dmmFacturas.dsFacPrint;
    dmmFacturas.unqryLinFacPrint.Open;
    //dmmFacturas.fxdstPrintLinFac.OpenDataSource;
    dmmFacturas.fxdstPrintLinFac.UpdateBounds;
  end;

  if rbRangoFechas.Checked = true then
  begin
    with dmmFacturas.unqryFacPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT *  ' +
                  '       FROM VI_FACTURAS_PRINT' +
                  '      WHERE FECHA_FACTURA >= :fecha_ini ' +
                  '        AND  FECHA_FACTURA <= :fecha_fin ' +
                  '   order by NRO_FACTURA';
      Params.ParamByName('fecha_ini').Value := dedDesde.Date;
      Params.ParamByName('fecha_fin').Value := dedHasta.Date;
    end;
    dmmFacturas.unqryFacPrint.Open;
    //dmmFacturas.fxdsPrintFac.OpenDataSource;
    dmmFacturas.fxdsPrintFac.UpdateBounds;
    with dmmFacturas.unqryLinFacPrint do
    begin
      Params.Clear;
      SQL.Text := '    SELECT *  ' +
                  '      FROM vi_FACTURAS_LINEAS_print L ' +
                  'INNER JOIN vi_FACTURAS_print F ' +
                  '        ON F.NRO_FACTURA = L.NRO_FACTURA_LINEA ' +
                  '       AND F.SERIE_FACTURA = L.SERIE_FACTURA_LINEA ' +
                  '     WHERE F.fecha_FACTURA >= :fecha_ini ' +
                  '       AND  F.fecha_FACTURA <= :fecha_fin ' +
                  '  order by L.NRO_FACTURA_LINEA, ' +
                  '           L.SERIE_FACTURA_LINEA, ' +
                  '           L.LINEA_FACTURA_LINEA';
      Params.ParamByName('fecha_ini').DataType := ftDate;
      Params.ParamByName('fecha_ini').Value := dedDesde.date;
      Params.ParamByName('fecha_fin').DataType := ftDate;
      Params.ParamByName('fecha_fin').Value := dedHasta.date;
      end;
    dmmFacturas.unqryLinFacPrint.Open;
    dmmFacturas.fxdstPrintLinFac.UpdateBounds;
  end;
end;

procedure TfrmPrintFac.rbActualClick(Sender: TObject);
begin
  inherited;
   dedDesde.Enabled := false;
   dedHasta.Enabled := false;
end;

procedure TfrmPrintFac.rbRangoFechasClick(Sender: TObject);
begin
  inherited;
  dedDesde.Enabled := true;
  dedHasta.Enabled := true;
end;

end.
