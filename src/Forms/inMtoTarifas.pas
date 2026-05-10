{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
  dxBevel, cxDBNavigator, inMtoPrincipal, UniDataTarifas,
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
    btAddBlock: TcxButton;
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
    btnCalcMargen: TcxButton;
    lblMargenTarifa: TcxLabel;
    lblMultiploTarifa: TcxLabel;
    lblMenosTarifa: TcxLabel;
    txtPORCENTAJE_MARGEN_TAR: TcxDBCurrencyEdit;
    txtVALOR_MULTIPLO_AJUSTE_TAR: TcxDBCurrencyEdit;
    txtVALOR_MENOS_AJUSTE_TAR: TcxDBCurrencyEdit;
    tvArticulosPORCENTAJE_MARGEN_ARTTAR: TcxGridDBColumn;
    tvArticulosVALOR_MULTIPLO_AJUSTE_ARTTAR: TcxGridDBColumn;
    tvArticulosVALOR_MENOS_AJUSTE_ARTTAR: TcxGridDBColumn;
    tvArticulosPORCENTAJE_MARGEN_EFECTIVO: TcxGridDBColumn;
    tvArticulosVALOR_MULTIPLO_AJUSTE_EFECTIVO: TcxGridDBColumn;
    tvArticulosVALOR_MENOS_AJUSTE_EFECTIVO: TcxGridDBColumn;
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actFamiliasExecute(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure btAddBlockClick(Sender: TObject);
    procedure btnCalcMargenClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure tvArticulosFocusedRecordChanged(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
  private
    procedure ActualizarVisibilidadColumnaSKU;
  public
    procedure CrearTablaPrincipal; override;
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
  inMtoProveedores, inMtoModalAddBlockTarifa, inMtoModalCalcularMargen;

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

procedure TfrmMtoTarifas.btAddBlockClick(Sender: TObject);
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
    if MessageDlg('La tarifa actual esta en edicion. Guardar antes de continuar?',
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
  ActualizarVisibilidadColumnaSKU;
end;

procedure TfrmMtoTarifas.ActualizarVisibilidadColumnaSKU;
var
  ds: TDataSet;
  fldTieneSku: TField;
begin
  if dmmTarifas = nil then Exit;
  ds := dmmTarifas.unqryArticulosTarifas;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
  begin
    tvArticulosCODIGO_UNICO_TARIFA_SKU.Visible := True;
    Exit;
  end;
  fldTieneSku := ds.FindField('TIENE_SKU');
  if fldTieneSku = nil then
    Exit;
  tvArticulosCODIGO_UNICO_TARIFA_SKU.Visible :=
    SameText(fldTieneSku.AsString, 'S');
end;

procedure TfrmMtoTarifas.tvArticulosFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarVisibilidadColumnaSKU;
end;

procedure TfrmMtoTarifas.btnCalcMargenClick(Sender: TObject);
var
  ds         : TDataSet;
  res        : TCalcularMargenResult;
  unicoFld   : TField;
  codigoArt  : string;
  descArt    : string;
  codigoTar  : string;
  nombreTar  : string;
  descSku    : string;
  coste      : Double;
  precSalida : Double;
  margenIni  : Double;
  multIni    : Double;
  menosIni   : Double;
  unico      : Integer;
begin
  inherited;
  ds := dmmTarifas.unqryArticulosTarifas;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
  begin
    ShowMessage('Selecciona primero un artículo de la tarifa.');
    Exit;
  end;

  unicoFld := ds.FindField('CODIGO_UNICO_ARTTAR');
  if (unicoFld = nil) or unicoFld.IsNull then
  begin
    ShowMessage('Este artículo aún no tiene precio en la tarifa. ' +
                'Añádelo primero (botón "Añadir Bloque") y luego calcula el margen.');
    Exit;
  end;
  unico := unicoFld.AsInteger;

  codigoArt  := ds.FieldByName('CODIGO_ART_ARTTAR').AsString;
  descArt    := ds.FieldByName('DESCRIPCION_ART').AsString;
  codigoTar  := ds.FieldByName('CODIGO_TAR_ARTTAR').AsString;
  nombreTar  := ds.FieldByName('NOMBRE_TAR_TAR').AsString;
  descSku    := ds.FieldByName('DESCRIPCION_SKU').AsString;
  coste      := ds.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
  precSalida := ds.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
  margenIni  := ds.FieldByName('PORCENTAJE_MARGEN_EFECTIVO').AsFloat;
  multIni    := ds.FieldByName('VALOR_MULTIPLO_AJUSTE_EFECTIVO').AsFloat;
  menosIni   := ds.FieldByName('VALOR_MENOS_AJUSTE_EFECTIVO').AsFloat;

  if coste <= 0 then
  begin
    ShowMessage('El artículo no tiene precio de coste (precio última compra). ' +
                'No se puede calcular el margen comercial.');
    Exit;
  end;

  res := TfrmModalCalcularMargen.Ejecutar(
    Self,
    (ds as TUniQuery).Connection,
    unico,
    codigoArt, descArt,
    codigoTar, nombreTar,
    descSku,
    coste, precSalida,
    margenIni, multIni, menosIni);

  if res.Aceptado then
  begin
    ds.Close;
    ds.Open;
    ActualizarVisibilidadColumnaSKU;
  end;
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
