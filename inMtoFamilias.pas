{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoFamilias;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
   cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  dxBarBuiltInMenu, cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, inMtoPrincipal2, UniDataFamilias,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxSplitter, System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan, JvComponentBase, JvEnterTab, cxDBLabel, dxShellDialogs;

type
  TfrmMtoFamilias = class(TfrmMtoGen)
    pnl1: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnlDetailFich: TPanel;
    pcDetail: TcxPageControl;
    tsMasDatos: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    pnlCabFich: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    tsOtros: TcxTabSheet;
    pnl3: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    lblDescripcion: TcxLabel;
    chkActivo: TcxDBCheckBox;
    cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn;
    txtCODIGO_FAMILIA: TcxDBTextEdit;
    txtNOMBRE_FAMILIA: TcxDBTextEdit;
    mDESCRIPCION_FAMILIA: TcxDBMemo;
    cxgrdbclmnGrdDBTabPrinACTIVO_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinORDEN_FAMILIA: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    cxspltr1: TcxSplitter;
    cxgrdArticulosFamilias: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    tvLineasFacturacion: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlArticulosFamilias: TcxGridLevel;
    cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_PROVEEDOR_PRINCIPAL: TcxGridDBColumn;
    cxgrdbclmnArticulosRAZON_SOCIAL_PROVEEDOR_PRINCIPAL: TcxGridDBColumn;
    cxgrdbclmnArticulosNOMBRE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosESIMP_INCL_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosNOMBRE_TIPO_IVA: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn;
    lblOrden: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevaFamilia: TcxButton;
    dbcGrdDBTabPrinESDEFAULT_FAMILIA: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_SUBFAMILIA: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_SUBFAMILIA: TcxGridDBColumn;
    cbbFamilia: TcxDBLookupComboBox;
    cxlbllbl1: TcxLabel;
    chkDEFAULT_FAMILIA: TcxDBCheckBox;
    ActionListFamilias: TActionList;
    actArticulo: TAction;
    actProveedores: TAction;
    actTarifas: TAction;
    procedure btnGrabarClick(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure actTarifasExecute(Sender: TObject);
    procedure btnNuevaFamiliaClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;
const
  pkFieldName = 'CODIGO_FAMILIA';

var
  frmMtoFamilias: TfrmMtoFamilias;
  dmmFamilias : TdmFamilias;

implementation

uses
  inLibWin,
  inLibUser,
  inLibDevExp,
  inMtoArticulos,
  inLibShowMto,
  inMtoProveedores,
  inMtoTarifas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoFamilias.actArticulosExecute(Sender: TObject);
begin
  inherited;
  //Control + A --Artículos
  with dmmFamilias.dsArticulosFamilias.DataSet do
  if (
      (pcDetail.ActivePage = tsArticulos) and
      (not(FieldByName('CODIGO_ARTICULO').isNull))) then
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ARTICULO').AsString)
  else
    ShowMto(Self.Owner,
            'Articulos' );
end;

procedure TfrmMtoFamilias.actProveedoresExecute(Sender: TObject);
begin
  inherited;
  // Control + P-> Proveedores
  with dmmFamilias.dsArticulosFamilias.DataSet do
  if (
      (pcDetail.ActivePage = tsArticulos) and
      (not(FieldByName('CODIGO_PROVEEDOR_PRINCIPAL').isNull))) then
    ShowMto (Self.Owner,
             'Proveedores',
             FieldByName('CODIGO_PROVEEDOR_PRINCIPAL').AsString)
  else
    ShowMto(Self.Owner,
            'Proveedores');
end;

procedure TfrmMtoFamilias.actTarifasExecute(Sender: TObject);
begin
  inherited;
  //Control + T -> Tarifas
  with dmmFamilias.dsArticulosFamilias.DataSet do
  if (
      (pcDetail.ActivePage = tsArticulos) and
      (not(FieldByName('CODIGO_TARIFA').isNull))) then
    ShowMto(Self.Owner,
            'Tarifas',
            FieldByName('CODIGO_TARIFA').AsString)
  else
    ShowMto(Self.Owner,
            'Tarifas');
end;

procedure TfrmMtoFamilias.btnGrabarClick(Sender: TObject);
begin
  if ( (dsTablaG.DataSet.State = dsInsert) or
       (dsTablaG.DataSet.State = dsEdit)) then
  begin
    dsTablaG.DataSet.Post;
  end;
end;

procedure TfrmMtoFamilias.btnNuevaFamiliaClick(Sender: TObject);
begin
  inherited;
  if ( (dmmFamilias.unqryTablaG.State = dsInsert) or
       (dmmFamilias.unqryTablaG.State = dsEdit)) then
  begin
    dmmFamilias.unqryTablaG.Post;
  end;
  dmmFamilias.unqryTablaG.Insert;
  pcPantalla.Properties.ActivePage := tsFicha;
  tsFicha.SetFocus;
  ResetForm;
  txtNOMBRE_FAMILIA.SetFocus;
end;

procedure TfrmMtoFamilias.CrearTablaPrincipal;
begin
  inherited;
  dmmFamilias := tdmDataModule as tdmFamilias;

  tvArticulos.DataController.DataSource := dmmFamilias.dsArticulosFamilias;
  cbbFamilia.Properties.ListSource := dmmFamilias.dsSubfamilias;
  ResetForm;
  pkFieldName := 'CODIGO_FAMILIA';
end;

procedure TfrmMtoFamilias.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
    txtCODIGO_FAMILIA.Enabled := True
  else
  begin
    txtCODIGO_FAMILIA.Enabled := False;
  end;
end;

procedure TfrmMtoFamilias.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsMasDatos;
end;

initialization
  ForceReferenceToClass(TfrmMtoFamilias);
end.
