{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacRec                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de recibos de facturas.                                }
{    Selecciona la factura y genera el recibo correspondiente.                 }
{******************************************************************************}
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
  UniDataFacturas,  dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSeven,
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
    procedure btn3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnGenerarClick(Sender: TObject);
    procedure chkAbonarClick(Sender: TObject);
    procedure chkDuplicarClick(Sender: TObject);
  public
    dmFac : TdmFacturas;
    procedure Preparar(ADM: TdmFacturas);
  end;

implementation

uses

  inLibUser,
  inLibVerifactuCola,
  inLibVerifactuColaIntf,
  inLibEmisionFiscalIntf,
  inLibEmisionFiscal,
  UniDataVerifactuColaRepositorio;

{$R *.dfm}

procedure TfrmGenFacRec.btn3Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmGenFacRec.btnGenerarClick(Sender: TObject);
var
  SavedCursor : TCursor;
  IsError : Boolean;
  Servicio: IServicioEmisionFiscal;
  ServicioCola: IServicioVerifactuCola;
begin
  IsError := False;
  if not Assigned(dmFac) then
    raise EArgumentNilException.Create(
      'Data module de facturas no asignado.');
  with dmFac do
  begin
    if chkAbonar.Checked and not IsError then
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
                     unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
             ParamByName('pidseriefacturaabono').AsString :=
                                                           cmbSerieFactura.Text;
             ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
             ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
             ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
             ParamByName('pUSUARIO').AsString := IdentidadSesion.Usuario;
             //ParamByName('pINSTANTEMODIF').AsDateTime := Now;
             ExecProc;
             //connection.Commit;
             edtSerieFacAbono.Text :=
                                   ParamByName('pidseriefacturaabono').AsString;
             edtNumFacAbono.Text := ParamByName('pidnumfacturaabono').AsString;
             // Rectificativa Verifactu: marcar tipo, enlazar con la
             // original y encolar el registro R1/R5
             ServicioCola := CrearServicioVerifactuColaUniDAC(
               ConexionPrincipal);
             Servicio := CrearServicioEmisionFiscal(
               ParametrosApp,
               ParametrosCaja,
               ConexionPrincipal,
               ServicioCola);
             TVerifactuCola.EncolarRectificativa(ParametrosApp,
               ParametrosCaja, ServicioCola, Servicio,
               IdentidadSesion.Usuario,
               edtSerieOrigen.Text, edtNumFacOrigen.Text,
               edtSerieFacAbono.Text, edtNumFacAbono.Text, 'I');
             unqryTablaG.Refresh;
          end;
        end;
      finally
          Screen.Cursor := SavedCursor;
      end;
    end;
    if chkDuplicar.Checked and not IsError then
    begin
      SavedCursor := Screen.Cursor;
      try
        Screen.Cursor:=crHourglass;
        with dmFac.unstrdprcDuplicarFactura do
        begin
         ParamByName('pidseriefactura').AsString :=  edtSerieOrigen.Text;
         ParamByName('pidnumfactura').AsString :=  edtNumFacOrigen.Text;
         ParamByName('pidcodigo_empresa').AsString :=
                    unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
         ParamByName('pUSUARIO').AsString := IdentidadSesion.Usuario;
         ParamByName('pidseriefacturaabono').AsString :=  cmbSerieFactura.Text;
         ParamByName('pfechafacturaabono').AsDate :=  dtFecha.Date;
         ExecProc;
         edtSerieFacAbono.Text := ParamByName('pidseriefacturaabono').AsString;
         edtNumFacAbono.Text := ParamByName('pidnumfacturaabono').AsString;
         dmFac.unqryTablaG.Refresh;
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
  dtFecha.Date := Trunc(Now);
end;

procedure TfrmGenFacRec.Preparar(ADM: TdmFacturas);
begin
  if not Assigned(ADM) then
    raise EArgumentNilException.Create(
      'Data module de facturas no asignado.');
  dmFac := ADM;
  with dmFac do
  begin
    if not unqrySeries.Active then
      unqrySeries.Open;
    cmbSerieFactura.Properties.ListSource := dsSeries;
    cmbSerieFactura.Text :=
      cmbSerieFactura.Properties.ListSource.DataSet.Fields[0].AsString;
    edtNumFacOrigen.Text := unqryTablaG.FieldByName('NUMERO_FAC').AsString;
    edtSerieOrigen.Text := unqryTablaG.FieldByName('SERIE_FAC').AsString;
  end;
end;

end.
