{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoModalFacRec;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, Menus,
  dxSkinsCore, dxSkinBlue, frxClass, frxDBSet, StdCtrls, cxButtons, DB,
  DBClient, cxControls, cxContainer, cxEdit, cxTextEdit, cxLabel,
  frxExportPDF, Uni,
  ExtCtrls, cxRadioGroup, cxGroupBox, cxDBEdit, cxCheckBox, cxMaskEdit,
  cxDropDownEdit, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  Vcl.ComCtrls, dxCore, cxDateUtils, cxCalendar, inMtoFrmBase, cxStyles,
  dxSkinsForm, cxClasses, cxLocalization, JvComponentBase, JvEnterTab,
  dxSkinBasic, dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinsDefaultPainters, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue;

type
  TfrmGenFacRec = class(TfrmBase)
    cxlbl1: TcxLabel;
    edtNumFacOrigen: TcxTextEdit;
    pnl1: TPanel;
    btn3: TcxButton;
    chkAbonar: TcxCheckBox;
    btnGenerar: TcxButton;
    cxgrpbx1: TcxGroupBox;
    edtNumFacAbono: TcxTextEdit;
    edtSerieOrigen: TcxTextEdit;
    edtSerieFacAbono: TcxTextEdit;
    chkDuplicar: TcxCheckBox;
    cxlbl8: TcxLabel;
    cmbSerieFactura: TcxLookupComboBox;
    cxlbl2: TcxLabel;
    dtFecha: TcxDateEdit;
//    procedure btn1Click(Sender: TObject);
//    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
//    procedure btn4Click(Sender: TObject);
   // procedure btnGenerarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnGenerarClick(Sender: TObject);
    procedure chkAbonarClick(Sender: TObject);
    procedure chkDuplicarClick(Sender: TObject);
  end;

var
  frmGenFacRec: TfrmGenFacRec;

implementation

uses
  inMtoFacturas,
  UniDataFacturas,
  inLibUser,
  inLibtb,
  inLibGlobalVar;

{$R *.dfm}

procedure TfrmGenFacRec.btn3Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmGenFacRec.btnGenerarClick(Sender: TObject);
var
  SavedCursor : TCursor;
  IsError : Boolean;
begin
  IsError := False;

  VAR ParentForm := TfrmMtoFacturas(Owner);
  with ParentForm.tdmDataModule as TdmFacturas do
  begin
//    if (ExisteSerieEmpresa(FieldByName('SERIE_FACTURA').AsString,
//                           FieldByName('CODIGO_EMPRESA_FACTURA').AsString,
//                           'FC')) then
//    begin
//      ShowMessage('Esta serie es usada por otra empresa.' +
//                  ' Debe cambiar la serie ');
//      IsError := True;
//    end;
    if ((chkAbonar.Checked = True) and (IsError = False)) then
    begin
      SavedCursor := Screen.Cursor;
      try
        Screen.Cursor:=crHourglass;
        begin
          with unstrdprcCrearFacturaAbono do
          begin
             //connection.StartTransaction;
             ParamByName('pidseriefactura').AsString :=  edtSerieOrigen.Text;
             ParamByName('pidnumfactura').AsString :=  edtNumFacOrigen.Text;
             ParamByName('pidcodigo_empresa').AsString :=
                     unqryTablaG.FieldByName('CODIGO_EMPRESA_FACTURA').AsString;
             ParamByName('pidseriefacturaabono').AsString :=
                                                           cmbSerieFactura.Text;
             ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
             ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
             ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
             ParamByName('pUSUARIO').AsString := oUser;
             //ParamByName('pINSTANTEMODIF').AsDateTime := Now;
             ExecProc;
             //connection.Commit;
             edtSerieFacAbono.Text :=
                                   ParamByName('pidseriefacturaabono').AsString;
             edtNumFacAbono.Text := ParamByName('pidnumfacturaabono').AsString;
             unqryTablaG.Refresh;
          end;
        end;
      finally
          Screen.Cursor := SavedCursor;
      end;
    end;
    if ((chkDuplicar.Checked = True) and (IsError = False)) then
    begin
      SavedCursor := Screen.Cursor;
      try
        Screen.Cursor:=crHourglass;
        with dmmFacturas.unstrdprcDuplicarFactura do
        begin
         ParamByName('pidseriefactura').AsString :=  edtSerieOrigen.Text;
         ParamByName('pidnumfactura').AsString :=  edtNumFacOrigen.Text;
         ParamByName('pidcodigo_empresa').AsString :=
                    unqryTablaG.FieldByName('CODIGO_EMPRESA_FACTURA').AsString;
         ParamByName('pUSUARIO').AsString := oUser;
         ParamByName('pidseriefacturaabono').AsString :=  cmbSerieFactura.Text;
         ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
         ExecProc;
         edtSerieFacAbono.Text := ParamByName('pidseriefacturaabono').AsString;
         edtNumFacAbono.Text := ParamByName('pidnumfacturaabono').AsString;
         dmmFacturas.unqryTablaG.Refresh;
        end;
      finally
        Screen.Cursor:=SavedCursor;
      end;
    end;
  end;
end;

procedure TfrmGenFacRec.chkAbonarClick(Sender: TObject);
begin
  if chkAbonar.Checked then
    chkDuplicar.Checked := False;
end;

procedure TfrmGenFacRec.chkDuplicarClick(Sender: TObject);
begin
  if chkDuplicar.Checked then
    chkAbonar.Checked := False;
end;

procedure TfrmGenFacRec.FormCreate(Sender: TObject);
begin
 if Owner is TfrmMtoFacturas then
  begin
    VAR ParentForm := TfrmMtoFacturas(Owner);
    with ParentForm.tdmDataModule as TdmFacturas do
    begin
      if unqrySeries.Active = False then
        unqrySeries.Open;
      cmbSerieFactura.Properties.ListSource := dsSeries;
      cmbSerieFactura.Text :=
              cmbSerieFactura.Properties.ListSource.DataSet.Fields[0].AsString;
      edtNumFacOrigen.Text := unqryTablaG.FieldByName('NRO_FACTURA').AsString;
    end;
    dtFecha.Date := Trunc(Now);
  end;
end;

end.

