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

resourcestring
  SErrorModuloFacturasNoAsignado =
    'Data module de facturas no asignado.';

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
  Procedimiento: TUniStoredProc;
begin
  IsError := False;
  if not Assigned(dmFac) then
    raise EArgumentNilException.Create(
      SErrorModuloFacturasNoAsignado);
    if chkAbonar.Checked and not IsError then
    begin
      SavedCursor := Screen.Cursor;
      try
        Screen.Cursor:=crHourglass;
        begin
          Procedimiento := dmFac.unstrdprcCrearFacturaAbono;
             //connection.StartTransaction;
          Procedimiento.ParamByName('pidseriefactura').AsString :=
            edtSerieOrigen.Text;
          Procedimiento.ParamByName('pidnumfactura').AsString :=
            edtNumFacOrigen.Text;
          Procedimiento.ParamByName('pidcodigo_empresa').AsString :=
            dmFac.unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
          Procedimiento.ParamByName('pidseriefacturaabono').AsString :=
            cmbSerieFactura.Text;
          Procedimiento.ParamByName('pfechafacturaabono').AsDate :=
            dtFecha.Date;
          Procedimiento.ParamByName('pfechafacturaabono').AsDate :=
            dtFecha.Date;
          Procedimiento.ParamByName('pfechafacturaabono').AsDate :=
            dtFecha.Date;
          Procedimiento.ParamByName('pUSUARIO').AsString :=
            dmFac.IdentidadSesion.Usuario;
             //ParamByName('pINSTANTEMODIF').AsDateTime := Now;
          Procedimiento.ExecProc;
             //connection.Commit;
          edtSerieFacAbono.Text := Procedimiento.ParamByName(
            'pidseriefacturaabono').AsString;
          edtNumFacAbono.Text := Procedimiento.ParamByName(
            'pidnumfacturaabono').AsString;
             // Rectificativa Verifactu: marcar tipo, enlazar con la
             // original y encolar el registro R1/R5
             ServicioCola := CrearServicioVerifactuColaUniDAC(
               dmFac.ConexionPrincipal);
             Servicio := CrearServicioEmisionFiscal(
               dmFac.ParametrosApp,
               dmFac.ParametrosCaja,
               dmFac.ConexionPrincipal,
               ServicioCola);
             TVerifactuCola.EncolarRectificativa(dmFac.ParametrosApp,
               dmFac.ParametrosCaja, ServicioCola, Servicio,
               dmFac.IdentidadSesion.Usuario,
               edtSerieOrigen.Text, edtNumFacOrigen.Text,
               edtSerieFacAbono.Text, edtNumFacAbono.Text, 'I');
          dmFac.unqryTablaG.Refresh;
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
        Procedimiento := dmFac.unstrdprcDuplicarFactura;
        Procedimiento.ParamByName('pidseriefactura').AsString :=
          edtSerieOrigen.Text;
        Procedimiento.ParamByName('pidnumfactura').AsString :=
          edtNumFacOrigen.Text;
        Procedimiento.ParamByName('pidcodigo_empresa').AsString :=
          dmFac.unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
        Procedimiento.ParamByName('pUSUARIO').AsString :=
          dmFac.IdentidadSesion.Usuario;
        Procedimiento.ParamByName('pidseriefacturaabono').AsString :=
          cmbSerieFactura.Text;
        Procedimiento.ParamByName('pfechafacturaabono').AsDate :=
          dtFecha.Date;
        Procedimiento.ExecProc;
        edtSerieFacAbono.Text := Procedimiento.ParamByName(
          'pidseriefacturaabono').AsString;
        edtNumFacAbono.Text := Procedimiento.ParamByName(
          'pidnumfacturaabono').AsString;
        dmFac.unqryTablaG.Refresh;
      finally
        Screen.Cursor:=SavedCursor;
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
      SErrorModuloFacturasNoAsignado);
  dmFac := ADM;
  if not dmFac.unqrySeries.Active then
    dmFac.unqrySeries.Open;
  cmbSerieFactura.Properties.ListSource := dmFac.dsSeries;
  cmbSerieFactura.Text :=
    cmbSerieFactura.Properties.ListSource.DataSet.Fields[0].AsString;
  edtNumFacOrigen.Text :=
    dmFac.unqryTablaG.FieldByName('NUMERO_FAC').AsString;
  edtSerieOrigen.Text :=
    dmFac.unqryTablaG.FieldByName('SERIE_FAC').AsString;
end;

end.
