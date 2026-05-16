{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTarifas                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de tarifas de precios.                                      }
{    Define tarifas aplicables a articulos por cliente o zona.                 }
{******************************************************************************}
unit inMtoTarifas;

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
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataTarifas,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan,
  cxSplitter, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoTarifas = class(TfrmMtoGen)
    pnl1: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnl2: TPanel;
    pcPestana: TcxPageControl;
    tsArticulos: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    Panel1: TPanel;
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
    chkActivo: TcxDBCheckBox;
    txtNOMBRE_TARIFA: TcxDBTextEdit;
    txtCODIGO_TARIFA: TcxDBTextEdit;
    cxgrdbclmnGrdDBTabPrinCODIGO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIMP_INCL_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESDEFAULT_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxdbchckbxACTIVO_TARIFA: TcxDBCheckBox;
    pnl6: TPanel;
    btnIraArticulo: TcxButton;
    btnAddBlock: TcxButton;
    cxspltr1: TcxSplitter;
    pnlArticulos: TPanel;
    cxgrdArticulosTarifas: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdbclmnArticulosACTIVO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_ARTICULO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPOIVA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_DESDE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_HASTA_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIOFINAL: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOMODIF: TcxGridDBColumn;
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
    cxgrdlvlArticulosTarifas: TcxGridLevel;
    cxspltr2: TcxSplitter;
    cxspltr3: TcxSplitter;
    ActionListTarifas: TActionList;
    actArticulos: TAction;
    actFamilias: TAction;
    actProveedores: TAction;
    tvArticulosCODIGO_UNIDAD_TARIFA: TcxGridDBColumn;
    tvArticulosCODIGO_TARIFA: TcxGridDBColumn;
    tvArticulosNOMBRE_TARIFA: TcxGridDBColumn;
    tvArticulosCODIGO_UNICO_TARIFA_SKU: TcxGridDBColumn;
    tvArticulosCODIGO_UNICO_TARIFA_PADRE: TcxGridDBColumn;
    tvArticulosCODIGO_UNICO_TARIFA: TcxGridDBColumn;
    tvArticulosORIGEN_PRECIO: TcxGridDBColumn;
    tvArticulosPRECIOSALIDA_TARIFA: TcxGridDBColumn;
    tvArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn;
    tvArticulosPRECIO_DTO_TARIFA: TcxGridDBColumn;
    tvArticulosPORCEN_DTO_TARIFA: TcxGridDBColumn;
    tvArticulosESIMP_INCL_TARIFA: TcxGridDBColumn;
    tvArticulosESDEFAULT_TARIFA: TcxGridDBColumn;
    tvArticulosESVARIACION_ARTICULO: TcxGridDBColumn;
    tvArticulosTIPO_IVA_ARTICULO: TcxGridDBColumn;
    tvArticulosTIENE_SKU: TcxGridDBColumn;
    tvArticulosESACTIVO_SKU: TcxGridDBColumn;
    tvArticulosDESCRIPCION_SKU: TcxGridDBColumn;
    tvArticulosNUM_ATRIBUTOS_REQ: TcxGridDBColumn;
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actFamiliasExecute(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure btnAddBlockClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoTarifas: TfrmMtoTarifas;
  dmmTarifas : TdmTarifas;

implementation

uses
  inLibWin,
  inLibShowMto,
  inLibUser,
  inLibDevExp,
  inMtoArticulos,
  inMtoFamilias,
  inMtoProveedores, inMtoModalAddBlockTarifa, inMtoPrincipal;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoTarifas.actFamiliasExecute(Sender: TObject);
begin
  inherited;  //Control + N Familias
  with dmmTarifas.unqryArticulosTarifas do
  begin
    if (
        (pcPestana.ActivePage = tsArticulos) and
         (not(FieldByName('CODIGO_FAM_ART').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Familias',
              FieldByName('CODIGO_FAM_ART').AsString)
      else
        ShowMto(Self.Owner,
                'Familias');
  end;
end;

procedure TfrmMtoTarifas.actProveedoresExecute(Sender: TObject);
begin
  inherited; // Control + P Proveedores
  with dmmTarifas.unqryArticulosTarifas do
  begin
    if (
        (pcPestana.ActivePage = tsArticulos) and
        (not(FieldByName('CODIGO_PRV_PRV').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Proveedores',
              FieldByName('CODIGO_PRV_PRV').AsString)
      else
        ShowMto(Self.Owner,
                'Proveedores');
  end;
end;

procedure TfrmMtoTarifas.btnAddBlockClick(Sender: TObject);
var
  res        : TAddBlockTarifaResult;
  codigoTar  : string;
begin
  inherited;

  if (dsTablaG.DataSet = nil) or (dsTablaG.DataSet.IsEmpty) then
  begin
    ShowMessage('Selecciona primero una tarifa.');
    Exit;
  end;

  if dsTablaG.State in [dsInsert, dsEdit] then
  begin
    if MessageDlg(
      'La tarifa actual esta en edicion. Guardar antes de continuar?',
                  mtConfirmation, [mbYes, mbNo, mbCancel], 0) = mrYes then
      dsTablaG.DataSet.Post
    else
      Exit;
  end;

  codigoTar := dsTablaG.DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString;

  res := TfrmModalAddBlockTarifa.Ejecutar(
           Self,
           (dsTablaG.DataSet as TUniQuery).Connection,
           codigoTar);

  if res.Aceptado then
  begin
    dmmTarifas.unqryArticulosTarifas.Close;
    dmmTarifas.unqryArticulosTarifas.Open;
  end;
end;


procedure TfrmMtoTarifas.btnIraArticuloClick(Sender: TObject);
begin
  inherited;  //CONTROL + A Articulos
    with dmmTarifas.unqryArticulosTarifas do
  begin
    if (
        (pcPestana.ActivePage = tsArticulos) and
        (not(FieldByName('CODIGO_ART_ARTTAR').Isnull))
       ) then
      ShowMto(Self.Owner,
              'Articulos',
              FieldByName('CODIGO_ART_ARTTAR').AsString)
      else
        ShowMto(Self.Owner,
                'Articulos');
  end;
end;

procedure TfrmMtoTarifas.CrearTablaPrincipal;
begin
  inherited;
  dmmTarifas := tdmDataModule as TdmTarifas;
  tvArticulos.DataController.DataSource := dmmTarifas.dsArticulosTarifas;
  pkFieldName := 'CODIGO_TAR_ARTTAR';
end;

procedure TfrmMtoTarifas.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoTarifas.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_TARIFA.Enabled := True
  else
  begin
    txtCODIGO_TARIFA.Enabled := False;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoTarifas);
end.
