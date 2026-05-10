{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoArticulos;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer, Generics.Collections,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel, inLibArticulosPropiedades,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataArticulos,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, Vcl.DBCtrls, cxCheckComboBox, cxDBCheckComboBox,
  cxGroupBox, cxCheckGroup, cxDBCheckGroup, cxRadioGroup,
  dxScrollbarAnnotations, dxCore, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, cxButtonEdit, cxSplitter,
  cxDBExtLookupComboBox, cxListView, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  cxDBLabel, dxShellDialogs, inLibArticulosVariaciones, inMtoModalAceptCancel,
  cxCustomListBox, cxCheckListBox;

type
  TfrmMtoArticulos = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    txtDESCRIPCION_ARTICULO: TcxDBTextEdit;
    txtCODIGO_ARTICULO: TcxDBTextEdit;
    pnlBodyFicha: TPanel;
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
    cbbFamilia: TcxDBLookupComboBox;
    lblFamilia: TcxLabel;
    tsTarifas: TcxTabSheet;
    cxgrdbclmnGrdDBTabPrinCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTIPOIVA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdTarifas: TcxGrid;
    tvTarifas: TcxGridDBBandedTableView;
    cxgrdlvlTarifas: TcxGridLevel;
    chkACTIVO_ARTICULO: TcxDBCheckBox;
    tsProveedores: TcxTabSheet;
    tsLineasFactura: TcxTabSheet;
    cxgrdProveedores: TcxGrid;
    tvProveedores: TcxGridDBTableView;
    cxgrdlvlProveedores: TcxGridLevel;
    cxgrdLinFac: TcxGrid;
    tvLinFac: TcxGridDBTableView;
    cxgrdlvlLinFac: TcxGridLevel;
    cxgrdbclmnProveedoresCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnProveedoresCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnProveedoresPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnProveedoresFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnProveedoresINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnProveedoresINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnProveedoresUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnProveedoresUSUARIOMODIF: TcxGridDBColumn;
    cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn;
    pnlFacturaOpts: TPanel;
    btnIraFactura: TcxButton;
    btnIraEmpresa: TcxButton;
    btnExportarLineas: TcxButton;
    pnlFacturaOpts1: TPanel;
    btnIraProveedor: TcxButton;
    btnExportarProveedor: TcxButton;
    pnlFacturaOpts2: TPanel;
    btnIraTarifa: TcxButton;
    btnExportarTarifa: TcxButton;
    btnIraCliente: TcxButton;
    cxgrdbclmnProveedoresRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    btnAddProveedor: TcxButton;
    cxgrdbclmnProveedoresESPROVEEDORPRINCIPAL: TcxGridDBColumn;
    splSplitterFicha: TcxSplitter;
    cxgrdbclmnTarifasCODIGO_ARTICULO_TARIFA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasDESCRIPCION_ARTICULO: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasTIPO_CANTIDAD_ARTICULO: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasTIPO_IVA_ARTICULO: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasACTIVO_TARIFA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasCODIGO_TARIFA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasFECHA_DESDE_TARIFA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasFECHA_HASTA_TARIFA: TcxGridDBBandedColumn;
    dbcTarifasPRECIOFINAL: TcxGridDBBandedColumn;
    dbcTarifasMARGEN: TcxGridDBBandedColumn;
    dbcTarifasPRECIOSALIDA: TcxGridDBBandedColumn;
    dbcTarifasPORCEN_DTO_TARIFA: TcxGridDBBandedColumn;
    dbcTarifasPRECIO_DTO_TARIFA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasCODIGO_PROVEEDOR: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasRAZONSOCIAL_PROVEEDOR: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasPRECIO_ULT_COMPRA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasFECHA_VALIDEZ: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasCODIGO_FAMILIA_ARTICULO: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasDESCRIPCION_FAMILIA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasINSTANTEALTA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasINSTANTEMODIF: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasUSUARIOALTA: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasUSUARIOMODIF: TcxGridDBBandedColumn;
    cxgrdbclmnTarifasNOMBRE_TARIFA: TcxGridDBBandedColumn;
    lblTextoLegal11: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevoArticulo: TcxButton;
    ActionListArticulos: TActionList;
    actEmpresas: TAction;
    actFacturas: TAction;
    actClientes: TAction;
    actProveedores: TAction;
    actTarifas: TAction;
    dbcTarifasCODIGO_UNICO_TARIFA: TcxGridDBBandedColumn;
    dbcTarifasESIMP_INCL_TARIFA: TcxGridDBBandedColumn;
    dbcTarifasESDEFAULT_TARIFA: TcxGridDBBandedColumn;
    cxDBLabel1: TcxDBLabel;
    cxDBLabel2: TcxDBLabel;
    tsGeneral: TcxTabSheet;
    rgTipoIVA: TcxDBRadioGroup;
    cxGroupBox2: TcxGroupBox;
    lblNombre1: TcxLabel;
    cxdbtxtdtTIPO_CANTIDAD_ARTICULO: TcxDBTextEdit;
    cxLabel2: TcxLabel;
    cxDBComboBox1: TcxDBComboBox;
    tvProveedoresColumn1: TcxGridDBColumn;
    cxDBCheckBox1: TcxDBCheckBox;
    tsSkuMto: TcxTabSheet;
    pnlSkuMto: TPanel;
    addSkuAll: TcxButton;
    cxgrdSkuMto: TcxGrid;
    tvSkuMto: TcxGridDBTableView;
    tvSkuMtoCODIGO_UNIDAD_SKU: TcxGridDBColumn;
    tvSkuMtoCODIGO_VAR_SKU: TcxGridDBColumn;
    tvSkuMtoESACTIVO_SKU: TcxGridDBColumn;
    tvSkuMtoCODIGO_ART_SKU: TcxGridDBColumn;
    tvSkuMtoPRECIO_ULT_COMPRA_SKUC: TcxGridDBColumn;
    tvSkuMtoFECHA_ULT_COMPRA_SKUC: TcxGridDBColumn;
    cxgrdSkuMtoLevel: TcxGridLevel;
    tsSKUs: TcxTabSheet;
    Panel1: TPanel;
    cxButton2: TcxButton;
    cxGrid2: TcxGrid;
    tvSkus: TcxGridDBTableView;
    tvSkusCODIGO_UNIDAD_SKU: TcxGridDBColumn;
    tvSkusCODIGO_ARTICULO_SKU: TcxGridDBColumn;
    tvSkusESACTIVO_SKU: TcxGridDBColumn;
    tvSkusINSTANTEMODIF: TcxGridDBColumn;
    tvSkusINSTANTEALTA: TcxGridDBColumn;
    tvSkusUSUARIOALTA: TcxGridDBColumn;
    tvSkusUSUARIOMODIF: TcxGridDBColumn;
    cxGridLevel1: TcxGridLevel;
    cxTabSheet3: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tvSkusCODIGO_BARRAS_CB: TcxGridDBColumn;
    tvSkusTIPO_CODIGO_CB: TcxGridDBColumn;
    tvSkusESPRINCIPAL_CB: TcxGridDBColumn;
    tvSkusID_CB: TcxGridDBColumn;
    tvSkusSTOCK_TOTAL: TcxGridDBColumn;
    cxButton1: TcxButton;
    cxButton5: TcxButton;
    cxGrdStock: TcxGrid;
    tvStock: TcxGridDBTableView;
    cxGridLevel4: TcxGridLevel;
    Panel2: TPanel;
    btStockExportarExcel: TcxButton;
    btReconstruirStock: TcxButton;
    cxGrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxGridLevel5: TcxGridLevel;
    Panel3: TPanel;
    cxButton11: TcxButton;
    tvStockAlmacen: TcxGridDBColumn;
    tvStockColor: TcxGridDBColumn;
    tvStockDBColumn42: TcxGridDBColumn;
    tvStockDBColumn43: TcxGridDBColumn;
    tvStockTotal: TcxGridDBColumn;
    tvMovimientosNUMERO_MOV: TcxGridDBColumn;
    tvMovimientosTIPO_DOC_MOV: TcxGridDBColumn;
    tvMovimientosSERIE_DOC_MOV: TcxGridDBColumn;
    tvMovimientosNRO_DOC_MOV: TcxGridDBColumn;
    tvMovimientosLINEA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_EMPRESA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALMACEN_MOV: TcxGridDBColumn;
    tvMovimientosFECHA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ARTICULO_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_UNIDAD_MOV: TcxGridDBColumn;
    tvMovimientosDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn;
    tvMovimientosTIPO_MOVIMIENTO_MOV: TcxGridDBColumn;
    tvMovimientosCANTIDAD_MOV: TcxGridDBColumn;
    tvMovimientosPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn;
    tvMovimientosTOTAL_COSTE_MOV: TcxGridDBColumn;
    tvMovimientosPRECIO_MEDIO_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_CLIENTE_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_PROVEEDOR_MOV: TcxGridDBColumn;
    tvMovimientosESACTIVO_MOV: TcxGridDBColumn;
    tvMovimientosINSTANTEMODIF: TcxGridDBColumn;
    tvMovimientosINSTANTEALTA: TcxGridDBColumn;
    tvMovimientosUSUARIOALTA: TcxGridDBColumn;
    tvMovimientosUSUARIOMODIF: TcxGridDBColumn;
    tvMovimientosTIPO_DOC_REF_MOV: TcxGridDBColumn;
    tvMovimientosSERIE_DOC_REF_MOV: TcxGridDBColumn;
    tvMovimientosNRO_DOC_REF_MOV: TcxGridDBColumn;
    tvMovimientosLINEA_REF_MOV: TcxGridDBColumn;
    tvMovimientosLOTE_MOV: TcxGridDBColumn;
    tvMovimientosFECHA_CADUCIDAD_MOV: TcxGridDBColumn;
    tvMovimientosNOMBRE_ALMACEN_ORIGEN: TcxGridDBColumn;
    tvMovimientosNOMBRE_ALMACEN_DESTINO: TcxGridDBColumn;
    tvMovimientosDESCRIPCION_TIPODOCUMENTO: TcxGridDBColumn;
    tvMovimientosRAZONSOCIAL_CLIENTE: TcxGridDBColumn;
    tvMovimientosRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    tsPropiedades: TcxTabSheet;
    cxDBCheckBox2: TcxDBCheckBox;
    tvTarifasCODIGO_UNIDAD_TARIFA: TcxGridDBBandedColumn;
    tvTarifasESVARIACION_ARTICULO: TcxGridDBBandedColumn;
    tvTarifasNUM_ATRIBUTOS_REQ: TcxGridDBBandedColumn;
    btnAddSKU: TcxButton;
    procedure btnAddProveedorClick(Sender: TObject);
    procedure cxgrdbclmnProveedoresCODIGO_PROVEEDORPropertiesButtonClick(
      Sender: TObject; AButtonIndex: Integer);
    procedure btnIraProveedorClick(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure actTarifasExecute(Sender: TObject);
    procedure btnNuevoArticuloClick(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure actFamiliasExecute(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnIraEmpresaClick(Sender: TObject);
    procedure btnCrearTarifaClick(Sender: TObject);
    procedure btnExportarTarifaClick(Sender: TObject);
    procedure btnExportarProveedorClick(Sender: TObject);
    procedure btnIraTarifaClick(Sender: TObject);
    procedure dbcTarifasPORCEN_DTO_TARIFAPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcTarifasPRECIOSALIDAPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcTarifasPRECIOFINALPropertiesEditValueChanged(
      Sender: TObject);
    procedure actEmpresasExecute(Sender: TObject);
    procedure actClientesExecute(Sender: TObject);
    procedure btnIraClienteClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cxDBCheckBox1PropertiesEditValueChanged(Sender: TObject);
    procedure cxDBComboBox1PropertiesEditValueChanged(Sender: TObject);
    procedure cbbFamiliaPropertiesEditValueChanged(Sender: TObject);
    procedure addSkuAllClick(Sender: TObject);
    procedure btnAddSKUClick(Sender: TObject);
    procedure cxButton11Click(Sender: TObject);
    procedure btStockExportarExcelClick(Sender: TObject);
    procedure btReconstruirStockClick(Sender: TObject);
    procedure btnGenerarCBClick(Sender: TObject);
    procedure btnVerificarCBClick(Sender: TObject);
    procedure dbcTarifasMARGENButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure dbcTarifasMARGENGetDisplayText(
      Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AText: string);
  private
     procedure BuscarProveedores;
     procedure IncorporarTarifas;
     procedure IterateCheckedListArt(lst:TcxListView);
  private
    FGestorProp  : TGestorPropiedades;
    FArticuloCargado: string;
    FScrollProp  : TScrollBox;
    FBtnAddProp  : TcxButton;
    FGestorVar      : TGestorVariaciones;
    FPnlTopVariaciones:TPanel;
    FScrollVarAtrib : TScrollBox;
    FCbbTipoVariacion   : TcxDBLookupComboBox;
    procedure InicializarPestanyaVariaciones;
    procedure InicializarPestanyaPropiedades;
    procedure OnAfterScrollArticulos(DataSet: TDataSet);
    procedure BtnAddPropClick(Sender: TObject);
  public
    procedure ActualizarVisibilidadVariaciones;
    procedure ActualizarVisibilidadColumnaSku;
    procedure AsegurarSkuArticuloSinVariaciones(const aCodArticulo: string);
    procedure AsegurarSkuArticulo(const aCodArticulo: string);
    procedure CrearTablaPrincipal; override;
    procedure ResetForm;  override;
  end;

var
  frmMtoArticulos: TfrmMtoArticulos;
  dmmArticulos : TdmArticulos;

implementation

uses
  inLibWin,
  inLibUser,
  inLibDevExp,
  inLibShowMto,
  inLibGenBusq,
  inMtoProveedores,
  inMtoPrincipal,
  inMtoTarifas,
  inMtoFamilias,
  inMtoEmpresas,
  inMtoFacturas,
  inMtoModalArtTar,
  inLibGlobalVar,
  inMtoModalGenerarSKUs,
  inMtoModalCalcularMargen,
  inLibEAN13,
  inLibtb;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoArticulos.ActualizarVisibilidadVariaciones;
var
  HayVars, EsEstandar: Boolean;
  Tipo: string;
begin
  HayVars := False;
  EsEstandar := True;
  if Assigned(dmmArticulos) and (dmmArticulos.unqryTablaG.Active = True) and
     (not dmmArticulos.unqryTablaG.IsEmpty) then
  begin
    HayVars := dmmArticulos.unqryTablaG.FieldByName(
                                     'ESVARIACION_ART').AsWideString = 'S';
    Tipo := Trim(dmmArticulos.unqryTablaG.FieldByName('TIPO_ART').AsString);
    // Por defecto se considera ESTANDAR si está vacío (compat. con altas)
    EsEstandar := (Tipo = '') or SameText(Tipo, 'ESTANDAR');
  end;
  FPnlTopVariaciones.Visible := HayVars;
  FScrollVarAtrib.Visible := HayVars;
  // Pestaña "Códigos de Barras" siempre visible (incluso para artículos
  // sin variaciones, con un único SKU = código del artículo).
  tsSKUS.TabVisible  := True;
  // Pestaña dedicada a SKUs sólo si el artículo usa variaciones.
  tsSkuMto.TabVisible := HayVars;
  // Generación masiva de SKUs únicamente con variaciones.
  addSkuAll.Visible  := HayVars;
  // Stock y movimientos sólo aplican a artículos físicos (ESTANDAR)
  tvSkusSTOCK_TOTAL.Visible := EsEstandar;
  tsMovimientos.TabVisible  := EsEstandar;
  cxTabSheet3.TabVisible    := EsEstandar; // pestaña Stock
end;

procedure TfrmMtoArticulos.ActualizarVisibilidadColumnaSku;
// Si ninguna fila del grid de tarifas tiene CODIGO_UNIDAD_ARTTAR rellenado
// (es decir, todos los precios son a nivel de artículo padre), oculta la
// columna SKU. En cuanto se añade un precio para un SKU concreto vuelve a
// mostrarse.
var
  ds  : TDataSet;
  fld : TField;
  bm  : TBookmark;
  hay : Boolean;
begin
  if not Assigned(dmmArticulos) then Exit;
  ds := dmmArticulos.unqryTarifasArticulos;
  if (ds = nil) or (not ds.Active) then
  begin
    tvTarifasCODIGO_UNIDAD_TARIFA.Visible := False;
    Exit;
  end;
  fld := ds.FindField('CODIGO_UNIDAD_ARTTAR');
  if fld = nil then Exit;

  hay := False;
  ds.DisableControls;
  bm := ds.GetBookmark;
  try
    ds.First;
    while not ds.Eof do
    begin
      if (not fld.IsNull) and (Trim(fld.AsString) <> '') then
      begin
        hay := True;
        Break;
      end;
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bm) then ds.GotoBookmark(bm);
    ds.FreeBookmark(bm);
    ds.EnableControls;
  end;

  tvTarifasCODIGO_UNIDAD_TARIFA.Visible := hay;
end;

procedure TfrmMtoArticulos.AsegurarSkuArticuloSinVariaciones(
                                                     const aCodArticulo: string);
var
  qry: TUniQuery;
  bTieneVar: Boolean;
begin
  if aCodArticulo = '' then Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;

    // 1) ¿El artículo tiene variaciones? Si las tiene, no hacemos nada
    qry.SQL.Text := 'SELECT ESVARIACION_ART FROM fza_articulos ' +
                    ' WHERE CODIGO_ART_ART = :C';
    qry.ParamByName('C').AsString := aCodArticulo;
    qry.Open;
    bTieneVar := (not qry.IsEmpty) and
                 (qry.FieldByName('ESVARIACION_ART').AsString = 'S');
    qry.Close;
    if bTieneVar then Exit;

    // 2) ¿Existe ya algún SKU para este artículo?
    qry.SQL.Text := 'SELECT 1 FROM fza_articulos_skus ' +
                    ' WHERE CODIGO_ART_SKU = :C LIMIT 1';
    qry.ParamByName('C').AsString := aCodArticulo;
    qry.Open;
    if not qry.IsEmpty then Exit;
    qry.Close;

    // 3) Insertamos un SKU "fantasma" con CODIGO_UNIDAD_SKU = código artículo
    qry.SQL.Text :=
      'INSERT INTO fza_articulos_skus '                                     +
      '   (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU,' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '                    +
      'VALUES (:SKU, :ART, ''-'', ''S'', CURRENT_TIMESTAMP, :USR, :USR)';
    qry.ParamByName('SKU').AsString := aCodArticulo;
    qry.ParamByName('ART').AsString := aCodArticulo;
    qry.ParamByName('USR').AsString := oUser;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoArticulos.AsegurarSkuArticulo(const aCodArticulo: string);
var
  qry: TUniQuery;
  bExisteFantasma: Boolean;
begin
  // Variante "fuerte" para acciones explícitas del usuario sobre códigos de
  // barras: si el artículo no tiene NINGÚN SKU activo (incluyendo artículos
  // con variaciones cuyas combinaciones aún no se han generado), creamos —o
  // reactivamos— un SKU "fantasma" con CODIGO_UNIDAD_SKU = código artículo
  // para que la generación/verificación nunca falle por "no hay SKUs activos".
  if aCodArticulo = '' then Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;

    // 1) ¿Ya existe algún SKU activo para este artículo? Nada que hacer.
    qry.SQL.Text := 'SELECT 1 FROM fza_articulos_skus '       +
                    ' WHERE CODIGO_ART_SKU = :C '             +
                    '   AND ESACTIVO_SKU = ''S'' LIMIT 1';
    qry.ParamByName('C').AsString := aCodArticulo;
    qry.Open;
    if not qry.IsEmpty then
    begin
      qry.Close;
      Exit;
    end;
    qry.Close;

    // 2) ¿Hay un SKU fantasma previo (mismo código que el artículo) inactivo?
    //    Si existe lo reactivamos en vez de insertar otro nuevo (PK colisiona).
    qry.SQL.Text := 'SELECT 1 FROM fza_articulos_skus '       +
                    ' WHERE CODIGO_UNIDAD_SKU = :SKU LIMIT 1';
    qry.ParamByName('SKU').AsString := aCodArticulo;
    qry.Open;
    bExisteFantasma := not qry.IsEmpty;
    qry.Close;

    if bExisteFantasma then
    begin
      qry.SQL.Text :=
        'UPDATE fza_articulos_skus '                                        +
        '   SET ESACTIVO_SKU = ''S'', '                                     +
        '       INSTANTE_MODIF = CURRENT_TIMESTAMP, '                       +
        '       USUARIO_MODIF = :USR '                                      +
        ' WHERE CODIGO_UNIDAD_SKU = :SKU';
      qry.ParamByName('SKU').AsString := aCodArticulo;
      qry.ParamByName('USR').AsString := oUser;
      qry.ExecSQL;
      Exit;
    end;

    // 3) Insertamos el SKU "fantasma" con CODIGO_UNIDAD_SKU = código artículo
    qry.SQL.Text :=
      'INSERT INTO fza_articulos_skus '                                     +
      '   (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU,' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '                    +
      'VALUES (:SKU, :ART, ''-'', ''S'', CURRENT_TIMESTAMP, :USR, :USR)';
    qry.ParamByName('SKU').AsString := aCodArticulo;
    qry.ParamByName('ART').AsString := aCodArticulo;
    qry.ParamByName('USR').AsString := oUser;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoArticulos.addSkuAllClick(Sender: TObject);
var
  CodArticulo, TipoVariacion: string;
begin
  // 1. Nos aseguramos de que el artículo no esté a medias de editar
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  // 2. Leemos los datos clave del dataset principal
  CodArticulo   := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  TipoVariacion := dmmArticulos.unqryTablaG.FieldByName('TIPO_VARIACION_ART').AsString;

  // 3. Validamos que haya un esquema de variación asignado
  if (CodArticulo = '') or (TipoVariacion = '') then
  begin
    ShowMessage('El artículo debe tener asignado un "Tipo de variación" y estar guardado para poder generar SKUs.');
    FCbbTipoVariacion.SetFocus; // Mandamos al usuario al combo para que lo elija
    Exit;
  end;

  // 4. Llamamos a nuestra pantalla mágica
  if TfrmMtoModalGenerarSKUs.Ejecutar(CodArticulo, TipoVariacion) then
  begin
    // Si la pantalla devuelve True, refrescamos los datasets afectados.
  end;
  dmmArticulos.unqrySkus.Close;
  dmmArticulos.unqrySkus.Open;
  dmmArticulos.unqryVariacionesArticulos.Close;
  dmmArticulos.unqryVariacionesArticulos.Open;
end;

procedure TfrmMtoArticulos.actClientesExecute(Sender: TObject);
begin
  inherited;
  //Control + K
  //https://stackoverflow.com/questions/2317208/
  //how-to-fire-keypreview-event-when-form-has-a-tactionmainmenubar
  if ((pcDetail.ActivePage = tsLineasFactura)
     ) then
       btnIraClienteClick(Sender)
  else
    ShowMto(Self.Owner,
            'Clientes');
end;

procedure TfrmMtoArticulos.actEmpresasExecute(Sender: TObject);
begin
  inherited;
  //Control + E   -> Empresas
   with tvLinFac.DataController.DataSet do
    if (
        (pcDetail.ActivePage = tsLineasFactura)        and
        (not(FieldByName('CODIGO_EMP_FACLIN').IsNull))
       ) then
      btnIraEmpresaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoArticulos.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F   -> Facturas
   with tvLinFac.DataController.DataSet do
    if (
        (pcDetail.ActivePage = tsLineasFactura)        and
        (not(FieldByName('NUMERO_FAC_FACLIN').IsNull))  and
        (not(FieldByName('SERIE_FAC_FACLIN').IsNull))
       ) then
      btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoArticulos.actFamiliasExecute(Sender: TObject);
begin
  inherited;
  //Control + N     -> Familias
  with dsTablaG.DataSet do
    if ((not(FieldByName('CODIGO_FAM_ART').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Familias',
              FieldByName('CODIGO_FAM_ART').AsString)
    else
      ShowMto(Self.Owner,
              'Familias');
end;

procedure TfrmMtoArticulos.actProveedoresExecute(Sender: TObject);
begin  //control + P -> proveedores
  inherited;
  with tvProveedores.DataController.DataSet do
    if (
        (pcDetail.ActivePage = tsProveedores) and
        (not(FieldByName('CODIGO_PRV_PRV').IsNull))
       ) then
      btnIraProveedorClick(Sender)
    else
      ShowMto(Self.Owner,
              'Proveedores');
end;

procedure TfrmMtoArticulos.actTarifasExecute(Sender: TObject);
begin
  inherited;
  //Control + T -> Tarifas
  with tvTarifas.DataController.DataSet do
    if (
        (pcDetail.ActivePage = tsTarifas) and
        (not(FieldByName('CODIGO_TAR_ARTTAR').IsNull))
       ) then
      btnIraTarifaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Tarifas');
end;

procedure TfrmMtoArticulos.btnAddProveedorClick(Sender: TObject);
begin
  with dmmArticulos do
    if ((unqryTablaG.State = dsInsert) or (unqryTablaG.State = dsEdit)) then
    unqryTablaG.Post;
  BuscarProveedores;
end;

procedure TfrmMtoArticulos.btnAddSKUClick(Sender: TObject);
var
  frmSel: TfrmModalAceptCancel;
  lblSkus, lblTarifas, lblDesde, lblHasta: TLabel;
  chkSkus, chkTarifas: TcxCheckListBox;
  pnlFechas: TPanel;
  dtpDesde, dtpHasta: TcxDateEdit;
  i, j: Integer;
  qryTodasTarifas: TUniQuery;
  // --- VARIABLES PARA CONTROL DE VIGENCIA ---
  TarifasActivas: TStringList;
  Bkm: TBookmark;
  LlaveUnica: string;
  HaySolapamiento, TieneUserHasta, DbHastaIsNull: Boolean;
  UserDesde, UserHasta, DbDesde, DbHasta: TDate;
  Cond1, Cond2: Boolean;
  codArticulo: String;
  PrecioPadre: Double;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  CodArticulo := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
//  if dmmArticulos.unqryVariacionesArticulos.IsEmpty then
//  begin
//    ShowMessage('No hay SKUs generados para este artículo.');
//    Exit;
//  end;

  // Instanciamos tu modal base
  frmSel := TfrmModalAceptCancel.Create(Self);
  try
    frmSel.OnClose := nil;
    frmSel.Caption := 'Añadir SKUs a Tarifas';
    frmSel.Width := 550;
    frmSel.Height := 600;

    // --- SECCIÓN FECHAS (NUEVO) ---
    pnlFechas := TPanel.Create(frmSel);
    pnlFechas.Parent := frmSel.pnlBody;
    pnlFechas.Align := alTop;
    pnlFechas.Height := 50;
    pnlFechas.Top := 500; // Lo primero de todo
    pnlFechas.BevelOuter := bvNone;

    lblDesde := TLabel.Create(frmSel);
    lblDesde.Parent := pnlFechas;
    lblDesde.Caption := 'Vigente Desde:';
    lblDesde.Left := 10;
    lblDesde.Top := 16;
    lblDesde.Font.Style := [fsBold];

    dtpDesde := TcxDateEdit.Create(frmSel);
    dtpDesde.Parent := pnlFechas;
    dtpDesde.Left := 150;  // <-- Aún más a la derecha (antes 130)
    dtpDesde.Top := 13;
    dtpDesde.Width := 110;
    dtpDesde.Date := Date; // Por defecto hoy

    lblHasta := TLabel.Create(frmSel);
    lblHasta.Parent := pnlFechas;
    lblHasta.Caption := 'Hasta (Opcional):';
    lblHasta.Left := 280;  // <-- Aún más a la derecha (antes 260)
    lblHasta.Top := 16;

    dtpHasta := TcxDateEdit.Create(frmSel);
    dtpHasta.Parent := pnlFechas;
    dtpHasta.Left := 410;  // <-- Aún más a la derecha (antes 380)
    dtpHasta.Top := 13;
    dtpHasta.Width := 110;

    // --- SECCIÓN SKUs ---
    lblSkus := TLabel.Create(frmSel);
    lblSkus.Parent := frmSel.pnlBody;
    lblSkus.Caption := ' 1. Seleccione los SKUs:';
    lblSkus.Font.Style := [fsBold];
    lblSkus.AlignWithMargins := True;
    lblSkus.Top := 1000;
    lblSkus.Align := alTop;

    chkSkus := TcxCheckListBox.Create(frmSel);
    chkSkus.Parent := frmSel.pnlBody;
    chkSkus.Height := 170;
    chkSkus.AlignWithMargins := True;
    chkSkus.Top := 2000;
    chkSkus.Align := alTop;
    chkSkus.Items.Add.Text := 'ARTÍCULO';
    if dmmArticulos.unqryVariacionesArticulos.Active = False then
      dmmArticulos.unqryVariacionesArticulos.Open;
    with dmmArticulos.unqryVariacionesArticulos do
    begin
      DisableControls;
      First;
      while not Eof do
      begin
        chkSkus.Items.Add.Text := FieldByName('CODIGO_UNIDAD_SKU').AsString;
        Next;
      end;
      EnableControls;
    end;

    // --- SECCIÓN TARIFAS ---
    lblTarifas := TLabel.Create(frmSel);
    lblTarifas.Parent := frmSel.pnlBody;
    lblTarifas.Caption := ' 2. Seleccione las Tarifas:';
    lblTarifas.Font.Style := [fsBold];
    lblTarifas.AlignWithMargins := True;
    lblTarifas.Top := 3000;
    lblTarifas.Align := alTop;

    chkTarifas := TcxCheckListBox.Create(frmSel);
    chkTarifas.Parent := frmSel.pnlBody;
    chkTarifas.AlignWithMargins := True;
    chkTarifas.Align := alClient;

    // Consultamos TODAS las tarifas activas
    qryTodasTarifas := TUniQuery.Create(nil);
    try
      qryTodasTarifas.Connection := dmmArticulos.unqryTablaG.Connection;
      qryTodasTarifas.SQL.Text := '  SELECT CODIGO_TAR_ARTTAR ' +
                                  '    FROM fza_tarifas ' +
                                  '   WHERE ESACTIVO_ARTTAR = ''S'' ' +
                                  'ORDER BY ORDEN_TAR';
      qryTodasTarifas.Open;

      while not qryTodasTarifas.Eof do
      begin
        chkTarifas.Items.Add.Text :=
                      qryTodasTarifas.FieldByName('CODIGO_TAR_ARTTAR').AsString;
        qryTodasTarifas.Next;
      end;
    finally
      qryTodasTarifas.Free;
    end;
    frmSel.ShowModal;
    if frmSel.sFicha = 'S' then
    begin
      UserDesde := dtpDesde.Date;
      TieneUserHasta := not VarIsNull(dtpHasta.EditValue);
      if TieneUserHasta then UserHasta := dtpHasta.Date;
      dmmArticulos.unqryTarifasArticulos.DisableControls;
      TarifasActivas := TStringList.Create;
      TarifasActivas.Sorted := True;
      TarifasActivas.Duplicates := dupIgnore;
      try
        Bkm := dmmArticulos.unqryTarifasArticulos.GetBookmark;
        dmmArticulos.unqryTarifasArticulos.First;
        while not dmmArticulos.unqryTarifasArticulos.Eof do
        begin
          DbDesde := dmmArticulos.unqryTarifasArticulos.FieldByName(
                                               'FECHA_DESDE_ARTTAR').AsDateTime;
          DbHastaIsNull := dmmArticulos.unqryTarifasArticulos.FieldByName(
                                                   'FECHA_HASTA_ARTTAR').IsNull;
          if not DbHastaIsNull then
            DbHasta := dmmArticulos.unqryTarifasArticulos.FieldByName(
                                               'FECHA_HASTA_ARTTAR').AsDateTime;
          Cond1 := (not TieneUserHasta) or (DbDesde <= UserHasta);
          Cond2 := DbHastaIsNull or (UserDesde <= DbHasta);
          HaySolapamiento := Cond1 and Cond2;
          if HaySolapamiento then
          begin
            LlaveUnica := dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString + '|' +
                          dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_TAR_ARTTAR').AsString;
            TarifasActivas.Add(LlaveUnica); // Marcamos combinación como ocupada en estas fechas
          end;
          dmmArticulos.unqryTarifasArticulos.Next;
        end;
        if dmmArticulos.unqryTarifasArticulos.BookmarkValid(Bkm) then
          dmmArticulos.unqryTarifasArticulos.GotoBookmark(Bkm);
        dmmArticulos.unqryTarifasArticulos.FreeBookmark(Bkm);
        for i := 0 to chkSkus.Items.Count - 1 do
        begin
          if chkSkus.Items[i].Checked then
          begin
            for j := 0 to chkTarifas.Items.Count - 1 do
            begin
              if chkTarifas.Items[j].Checked then
              begin
                // EVALUAMOS QUÉ GUARDAR SI ES "GENERAL"
                if chkSkus.Items[i].Text = 'ARTÍCULO' then
                begin
                  // Opción recomendada: lo dejamos en blanco para que sea la tarifa global del artículo
                  LlaveUnica := '' + '|' + chkTarifas.Items[j].Text;
                end
                else
                begin
                  LlaveUnica := chkSkus.Items[i].Text + '|' + chkTarifas.Items[j].Text;
                end;

                // Solo insertamos si la combinación NO choca en fechas
                if TarifasActivas.IndexOf(LlaveUnica) = -1 then
                begin
                  dmmArticulos.unqryTarifasArticulos.Append;

                  // Asignamos el valor correspondiente al campo SKU
                  if chkSkus.Items[i].Text = 'ARTÍCULO' then
                    dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := ''
                  else
                    dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := chkSkus.Items[i].Text;

                  dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_TAR_ARTTAR').AsString := chkTarifas.Items[j].Text;

                  // Para filas de SKU heredamos el precio del padre (fila del
                  // artículo en la misma tarifa) si existe; si no, queda a 0.
                  if chkSkus.Items[i].Text = 'ARTÍCULO' then
                    PrecioPadre := 0
                  else
                    PrecioPadre := dmmArticulos.ObtenerPrecioTarifaPadre(
                                                 codArticulo,
                                                 chkTarifas.Items[j].Text);

                  dmmArticulos.unqryTarifasArticulos.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat := PrecioPadre;
                  dmmArticulos.unqryTarifasArticulos.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat  := PrecioPadre;
                  // Si arranca a 0 la tarifa nace inactiva (sin preguntar);
                  // BeforePost se encarga de las transiciones posteriores.
                  if PrecioPadre > 0 then
                    dmmArticulos.unqryTarifasArticulos.FieldByName('ESACTIVO_ARTTAR').AsString := 'S'
                  else
                    dmmArticulos.unqryTarifasArticulos.FieldByName('ESACTIVO_ARTTAR').AsString := 'N';

                  // Aplicamos las fechas que eligió el usuario
                  dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime := UserDesde;
                  if TieneUserHasta then
                    dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime := UserHasta
                  else
                    dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_HASTA_ARTTAR').Clear;

                  dmmArticulos.unqryTarifasArticulos.Post;

                  // Blindamos la memoria por si acaso
                  TarifasActivas.Add(LlaveUnica);
                end;
              end;
            end;
          end;
        end;
      finally
        TarifasActivas.Free;
        dmmArticulos.unqryTarifasArticulos.EnableControls;
      end;
      dmmArticulos.unqryTarifasArticulos.Refresh;
      ActualizarVisibilidadColumnaSku;
//      pcDetail.ActivePage := tsTarifas;
//      if tvTarifas.CanFocus then tvTarifas.SetFocus;
    end;

  finally
    frmSel.Free;
  end;
end;

procedure TfrmMtoArticulos.dbcTarifasMARGENButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  ds           : TDataSet;
  unicoFld     : TField;
  unico        : Integer;
  codigoArt    : string;
  codigoUnidad : string;
  descArt      : string;
  codigoTar    : string;
  nombreTar    : string;
  descSku      : string;
  coste        : Double;
  precSalida   : Double;
  res          : TCalcularMargenResult;
begin
  inherited;
  ds := dmmArticulos.unqryTarifasArticulos;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
  begin
    ShowMessage('Selecciona primero un precio de tarifa.');
    Exit;
  end;

  unicoFld := ds.FindField('CODIGO_UNICO_ARTTAR');
  if (unicoFld = nil) or unicoFld.IsNull then
  begin
    ShowMessage('Esta fila aún no tiene precio guardado en la tarifa. ' +
                'Pulsa primero "Añadir precio" para crear el registro.');
    Exit;
  end;
  unico := unicoFld.AsInteger;

  codigoArt  := ds.FieldByName('CODIGO_ART_ARTTAR').AsString;
  if ds.FindField('DESCRIPCION_ART') <> nil then
    descArt := ds.FieldByName('DESCRIPCION_ART').AsString;
  codigoTar  := ds.FieldByName('CODIGO_TAR_ARTTAR').AsString;
  if ds.FindField('NOMBRE_TAR_TAR') <> nil then
    nombreTar := ds.FieldByName('NOMBRE_TAR_TAR').AsString;
  if ds.FindField('DESCRIPCION_SKU') <> nil then
    descSku := ds.FieldByName('DESCRIPCION_SKU').AsString;
  if ds.FindField('CODIGO_UNIDAD_ARTTAR') <> nil then
    codigoUnidad := ds.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString
  else
    codigoUnidad := '';
  coste      := ds.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
  precSalida := ds.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;

  res := TfrmModalCalcularMargen.Ejecutar(
    Self,
    (ds as TUniQuery).Connection,
    unico,
    codigoArt, codigoUnidad,
    descArt,
    codigoTar, nombreTar,
    descSku,
    coste, precSalida);

  if res.Aceptado then
  begin
    ds.Refresh;
    ActualizarVisibilidadColumnaSku;
  end;
end;

procedure TfrmMtoArticulos.dbcTarifasMARGENGetDisplayText(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AText: string);
var
  DC                 : TcxCustomDataController;
  RecordIndex        : Integer;
  ItemCoste, ItemSalida: TcxCustomGridTableItem;
  vCoste, vSalida    : Variant;
  coste, salida      : Double;
begin
  AText := '';
  RecordIndex := ARecord.RecordIndex;
  if RecordIndex < 0 then Exit;
  DC := tvTarifas.DataController;
  if DC = nil then Exit;
  ItemCoste  := tvTarifas.GetColumnByFieldName('PRECIO_ULT_COMPRA');
  ItemSalida := tvTarifas.GetColumnByFieldName('PRECIO_SALIDA_ARTTAR');
  if (ItemCoste = nil) or (ItemSalida = nil) then Exit;
  vCoste  := DC.Values[RecordIndex, ItemCoste.Index];
  vSalida := DC.Values[RecordIndex, ItemSalida.Index];
  if VarIsNull(vCoste) or VarIsEmpty(vCoste) then Exit;
  if VarIsNull(vSalida) or VarIsEmpty(vSalida) then Exit;
  try
    coste  := vCoste;
    salida := vSalida;
  except
    Exit;
  end;
  if coste > 0 then
    AText := FormatFloat('0.00" %"', (salida / coste) * 100);
end;

procedure TfrmMtoArticulos.btnBuscarClick(Sender: TObject);
begin
  inherited;
  sleep(0);
end;

procedure TfrmMtoArticulos.btnCrearTarifaClick(Sender: TObject);
begin
  inherited;
  if ( (dmmArticulos.unqryTablaG.State = dsInsert) or
       (dmmArticulos.unqryTablaG.State = dsEdit)) then
    dmmArticulos.unqryTablaG.Post;
  if ( (dmmArticulos.unqryTarifasArticulos.State = dsInsert) or
       (dmmArticulos.unqryTarifasArticulos.State = dsEdit)) then
  begin
    dmmArticulos.unqryTarifasArticulos.Post;
  end;
  //dmmArticulos.unqryTarifasArticulos.Insert;
  IncorporarTarifas;
end;

procedure TfrmMtoArticulos.btnExportarProveedorClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxgrdProveedores, 'Historico_Proveedores_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnExportarTarifaClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxGrdTarifas, 'Historico_Tarifas_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnIraClienteClick(Sender: TObject);
begin
  inherited;
    with tvLinFac.DataController.DataSet do
  ShowMto(Self.Owner,
          'Clientes',
          FieldByName('CODIGO_CLIENTE_FACTURA_LINEA').AsString);
end;

procedure TfrmMtoArticulos.btnIraEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          tvLinfac.DataController.DataSet.FieldByName(
                                      'CODIGO_EMP_FACLIN').AsString);
end;

procedure TfrmMtoArticulos.btnIraFacturaClick(Sender: TObject);
begin
  inherited;
  with tvLinFac.DataController.DataSource.DataSet do
  ShowMto(Self.Owner,
          'Facturas',
          FieldByName('NUMERO_FAC_FACLIN').AsString + ',' +
          FieldByName('SERIE_FAC_FACLIN').AsString);
end;

procedure TfrmMtoArticulos.btnIraProveedorClick(Sender: TObject);
begin
  inherited;
    ShowMto(Self.Owner,
    'Proveedores',
    tvProveedores.DataController.DataSet.FieldByName(
                                                  'CODIGO_PRV_PRV').AsString);
end;

procedure TfrmMtoArticulos.btnIraTarifaClick(Sender: TObject);
begin
  inherited;
    ShowMto(Self.Owner,
            'Tarifas',
                 dmmArticulos.unqryTarifasArticulos.FieldByName(
                                                     'CODIGO_TAR_ARTTAR').AsString);
end;

procedure TfrmMtoArticulos.btnGrabarClick(Sender: TObject);
var
  sErrorProp: string;
begin
  if Assigned(FGestorProp) then
  begin
    sErrorProp := FGestorProp.Validar;
    if sErrorProp <> '' then
    begin
      ShowMessage('Revisión requerida: ' + sErrorProp);
      pcDetail.ActivePage := tsPropiedades;
      Exit;
    end;
    try
      FGestorProp.GuardarPropiedades;
    except
      on E: Exception do
      begin
        ShowMessage('Error al guardar propiedades: ' + E.Message);
        Exit;
      end;
    end;
  end;
  if ( (dmmArticulos.unqryProveedoresArticulos.State = dsInsert) or
       (dmmArticulos.unqryProveedoresArticulos.State = dsEdit)) then
  begin
    dmmArticulos.unqryProveedoresArticulos.Post;
  end;
  if ( (dmmArticulos.unqryTarifasArticulos.State = dsInsert) or
       (dmmArticulos.unqryTarifasArticulos.State = dsEdit)) then
  begin
    dmmArticulos.unqryTarifasArticulos.Post;
  end;
  if ( (dmmArticulos.unqryVariacionesArticulos.State = dsInsert) or
       (dmmArticulos.unqryVariacionesArticulos.State = dsEdit)) then
  begin
    dmmArticulos.unqryVariacionesArticulos.Post;
  end;
  if ( (dmmArticulos.unqrySkus.State = dsInsert) or
       (dmmArticulos.unqrySkus.State = dsEdit)) then
  begin
    dmmArticulos.unqrySkus.Post;
  end;
  if ( (dmmArticulos.unqryTablaG.State = dsInsert) or
       (dmmArticulos.unqryTablaG.State = dsEdit)) then
  begin
    dmmArticulos.unqryTablaG.Post;
  end;
  if Assigned(FGestorVar) then
  try
    FGestorVar.GuardarVariaciones;
  except
    on E: Exception do
    begin
      ShowMessage('Error al guardar variaciones: ' + E.Message);
      Exit;
    end;
  end;
end;

procedure TfrmMtoArticulos.btnNuevoArticuloClick(Sender: TObject);
begin
  inherited;
  if ( (dmmArticulos.unqryTablaG.State = dsInsert) or
       (dmmArticulos.unqryTablaG.State = dsEdit)) then
  begin
    dmmArticulos.unqryTablaG.Post;
  end;
  dmmArticulos.unqryTablaG.Insert;
  pcPantalla.Properties.ActivePage := tsFicha;
  tsFicha.SetFocus;
  txtDESCRIPCION_ARTICULO.SetFocus;
end;

procedure TfrmMtoArticulos.btStockExportarExcelClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxgrdStock, 'Stock_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btReconstruirStockClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if Application.MessageBox(
       '¿Desea reconstruir la tabla de stock a partir de los movimientos de ' +
       'almacén? Esta operación borrará el stock actual y lo regenerará.',
       'Reconstruir Stock',
       MB_YESNO + MB_ICONQUESTION) <> ID_YES then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      sMensaje := dmmArticulos.ReconstruirStock;
      if dmmArticulos.unqryTablaG.Active and
         (not dmmArticulos.unqryTablaG.IsEmpty) then
        dmmArticulos.unqryStockArticulosAfterScroll(dmmArticulos.unqryTablaG);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        ShowMessage('Error al reconstruir el stock: ' + E.Message);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if sMensaje = '' then
    sMensaje := 'Stock reconstruido.';
  ShowMessage(sMensaje);
end;

procedure TfrmMtoArticulos.btnGenerarCBClick(Sender: TObject);
const
  // EAN-13 interno para artículos: prefijo '21' + 10 dígitos contador + control
  CB_TIPO_DOC    = 'BA';
  CB_PREFIJO     = '21';
  CB_NUM_DIGITOS = 10;
  CB_TIPO_INT    = 'EAN13';
var
  qrySkus, qryInsert, qryDel: TUniQuery;
  CodArticulo, sSku, sCounter, sCodigo12, sCodigoCB: string;
  iGenerados, iVacios, iSaltados, iLimpiados: Integer;
begin
  inherited;
  // 1) Asegurar que el artículo está guardado
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  CodArticulo := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if CodArticulo = '' then
  begin
    ShowMessage('Seleccione o guarde un artículo antes de generar códigos de barras.');
    Exit;
  end;

  // Garantizamos que el artículo tenga al menos un SKU activo (= código
  // artículo) aunque tenga variaciones sin combinaciones generadas aún.
  AsegurarSkuArticulo(CodArticulo);

  qrySkus   := TUniQuery.Create(nil);
  qryInsert := TUniQuery.Create(nil);
  qryDel    := TUniQuery.Create(nil);
  iGenerados := 0;
  iVacios    := 0;
  iSaltados  := 0;
  iLimpiados := 0;
  try
    qrySkus.Connection   := oConn;
    qryInsert.Connection := oConn;
    qryDel.Connection    := oConn;

    // 2) Limpieza: placeholders _FAB_ residuales de versiones anteriores.
    qryDel.SQL.Text :=
      'DELETE cb FROM fza_codigos_barras cb '                          +
      '  JOIN fza_articulos_skus sku '                                 +
      '    ON sku.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB '            +
      ' WHERE sku.CODIGO_ART_SKU = :ART '                              +
      '   AND LEFT(cb.CODIGO_BARRAS_CB, 5) = ''_FAB_''';
    qryDel.ParamByName('ART').AsString := CodArticulo;
    qryDel.ExecSQL;
    iLimpiados := qryDel.RowsAffected;

    // 3) Botón progresivo, idempotente. Por cada SKU activo:
    //      Fase A: si aún no tiene principal (ESPRINCIPAL_CB='S') →
    //              crear EAN-13 interno como principal.
    //      Fase B: si ya tiene principal pero no tiene fila vacía →
    //              crear fila vacía (CODIGO_BARRAS_CB='') para el código
    //              del fabricante (a rellenar manualmente).
    //      Fase C: si ya tiene principal y vacía → no hacer nada.
    //    Pulsando dos veces el usuario obtiene primero los principales
    //    y luego los huecos para los códigos de fabricante.
    qrySkus.SQL.Text :=
      'SELECT sku.CODIGO_UNIDAD_SKU, '                                 +
      '       (SELECT COUNT(*) FROM fza_codigos_barras p '             +
      '         WHERE p.CODIGO_UNIDAD_CB = sku.CODIGO_UNIDAD_SKU '     +
      '           AND p.ESPRINCIPAL_CB = ''S'') AS NUM_PRIN, '         +
      '       (SELECT COUNT(*) FROM fza_codigos_barras v '             +
      '         WHERE v.CODIGO_UNIDAD_CB = sku.CODIGO_UNIDAD_SKU '     +
      '           AND COALESCE(v.CODIGO_BARRAS_CB, '''') = '''') '     +
      '              AS NUM_EMPTY '                                    +
      '  FROM fza_articulos_skus sku '                                 +
      ' WHERE sku.CODIGO_ART_SKU = :ART '                              +
      '   AND sku.ESACTIVO_SKU = ''S''';
    qrySkus.ParamByName('ART').AsString := CodArticulo;
    qrySkus.Open;

    if qrySkus.RecordCount = 0 then
    begin
      qrySkus.Close;
      if iLimpiados = 0 then
        ShowMessage('El artículo no tiene SKUs activos.');
      Exit;
    end;

    if MessageDlg(
         '¿Generar códigos de barras pendientes?'           + sLineBreak +
         sLineBreak +
         'Para cada SKU activo:'                            + sLineBreak +
         '  · Si no tiene principal: se genera un EAN-13 ' +
                'interno (prefijo "' + CB_PREFIJO + '").'   + sLineBreak +
         '  · Si tiene principal pero no fila vacía: se ' +
                'crea una fila vacía para el código del '   +
                'fabricante (a rellenar manualmente).'     + sLineBreak +
         '  · Si ya tiene ambos, se respeta.'                + sLineBreak +
         sLineBreak +
         'Pulse Sí para continuar.',
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      qrySkus.Close;
      Exit;
    end;

    Screen.Cursor := crHourGlass;
    try
      qrySkus.First;
      while not qrySkus.Eof do
      begin
        sSku := qrySkus.FieldByName('CODIGO_UNIDAD_SKU').AsString;

        if qrySkus.FieldByName('NUM_PRIN').AsInteger = 0 then
        begin
          // Fase A: principal con contador EAN-13
          sCounter := ObtenerSiguienteContador(CB_TIPO_DOC);
          if Length(sCounter) > CB_NUM_DIGITOS then
            sCounter := Copy(sCounter, Length(sCounter) - CB_NUM_DIGITOS + 1,
                             CB_NUM_DIGITOS)
          else
            sCounter := StringOfChar('0', CB_NUM_DIGITOS - Length(sCounter)) +
                        sCounter;
          sCodigo12 := CB_PREFIJO + sCounter;
          sCodigoCB := sCodigo12 + CalcularDigitoEAN13(sCodigo12);

          qryInsert.SQL.Text :=
            'INSERT INTO fza_codigos_barras '                          +
            '   (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
            '    ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
            'VALUES (:CB, :SKU, :TIPO, ''S'', '                        +
            '        CURRENT_TIMESTAMP, :USR, :USR)';
          qryInsert.ParamByName('CB').AsString   := sCodigoCB;
          qryInsert.ParamByName('SKU').AsString  := sSku;
          qryInsert.ParamByName('TIPO').AsString := CB_TIPO_INT;
          qryInsert.ParamByName('USR').AsString  := oUser;
          qryInsert.ExecSQL;
          Inc(iGenerados);
        end
        else if qrySkus.FieldByName('NUM_EMPTY').AsInteger = 0 then
        begin
          // Fase B: fila vacía para el código del fabricante
          qryInsert.SQL.Text :=
            'INSERT INTO fza_codigos_barras '                          +
            '   (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
            '    ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
            'VALUES ('''', :SKU, ''EAN13'', ''N'', '                   +
            '        CURRENT_TIMESTAMP, :USR, :USR)';
          qryInsert.ParamByName('SKU').AsString := sSku;
          qryInsert.ParamByName('USR').AsString := oUser;
          qryInsert.ExecSQL;
          Inc(iVacios);
        end
        else
          Inc(iSaltados);

        qrySkus.Next;
      end;
    finally
      Screen.Cursor := crDefault;
      qrySkus.Close;
    end;

    // Close+Open en lugar de Refresh: las filas recién insertadas necesitan
    // que el dataset reabra la vista para que ID_CB aparezca en la rejilla
    // (Refresh sobre detail master/detail no siempre repuebla los IDs).
    dmmArticulos.unqryVariacionesArticulos.Close;
    dmmArticulos.unqryVariacionesArticulos.Open;
    ActualizarVisibilidadVariaciones;
    ShowMessage(Format('Generación finalizada.'                       + sLineBreak +
                       '- EAN-13 internos creados: %d'                 + sLineBreak +
                       '- Filas vacías de fabricante creadas: %d'      + sLineBreak +
                       '- SKUs ya completos (saltados): %d'            + sLineBreak +
                       '- Placeholders _FAB_ obsoletos eliminados: %d',
                       [iGenerados, iVacios, iSaltados, iLimpiados]));
  finally
    FreeAndNil(qryInsert);
    FreeAndNil(qrySkus);
    FreeAndNil(qryDel);
  end;
end;

procedure TfrmMtoArticulos.btnVerificarCBClick(Sender: TObject);
var
  qry: TUniQuery;
  CodArticulo, sCodigo, sSku, sTipo, sErrores: string;
  iOk13, iOk8, iKo, iSkip: Integer;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  CodArticulo := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if CodArticulo = '' then
  begin
    ShowMessage('Seleccione o guarde un artículo antes de verificar.');
    Exit;
  end;

  AsegurarSkuArticulo(CodArticulo);

  qry := TUniQuery.Create(nil);
  iOk13 := 0;
  iOk8  := 0;
  iKo   := 0;
  iSkip := 0;
  sErrores := '';
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT cb.CODIGO_BARRAS_CB, cb.CODIGO_UNIDAD_CB, cb.TIPO_CODIGO_CB ' +
      '  FROM fza_codigos_barras cb '                                       +
      '  JOIN fza_articulos_skus sku '                                      +
      '    ON sku.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB '                 +
      ' WHERE sku.CODIGO_ART_SKU = :CODIGO_ART_ART';
    qry.ParamByName('CODIGO_ART_ART').AsString := CodArticulo;
    qry.Open;
    while not qry.Eof do
    begin
      sCodigo := qry.FieldByName('CODIGO_BARRAS_CB').AsString;
      sSku    := qry.FieldByName('CODIGO_UNIDAD_CB').AsString;
      sTipo   := qry.FieldByName('TIPO_CODIGO_CB').AsString;

      // Saltamos los placeholders pendientes de rellenar
      if (sCodigo = '') or (Pos('_FAB_', sCodigo) = 1) then
        Inc(iSkip)
      else if (Length(sCodigo) = 13) and EsEAN13Valido(sCodigo) then
        Inc(iOk13)
      else if (Length(sCodigo) = 8) and EsEAN8Valido(sCodigo) then
        Inc(iOk8)
      else
      begin
        Inc(iKo);
        sErrores := sErrores + sLineBreak + '  ' + sCodigo + '  (SKU ' + sSku +
                    ', Tipo ' + sTipo + ', Long ' + IntToStr(Length(sCodigo)) +
                    ')';
      end;
      qry.Next;
    end;
    qry.Close;

    if iKo = 0 then
      ShowMessage(Format('Verificación OK.' + sLineBreak +
                         '- EAN-13 válidos: %d' + sLineBreak +
                         '- EAN-8  válidos: %d' + sLineBreak +
                         '- Pendientes (placeholder/vacío): %d',
                         [iOk13, iOk8, iSkip]))
    else
      ShowMessage(Format('Verificación con incidencias.' + sLineBreak +
                         '- EAN-13 válidos: %d' + sLineBreak +
                         '- EAN-8  válidos: %d' + sLineBreak +
                         '- NO válidos: %d' + sLineBreak +
                         '- Pendientes: %d' + sLineBreak +
                         'Códigos no válidos:%s',
                         [iOk13, iOk8, iKo, iSkip, sErrores]));
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoArticulos.IncorporarTarifas;
var
  formulario : TfrmMtoModalArtTar;
begin
  formulario := TfrmMtoModalArtTar.Create(Self.Owner);
  formulario.Name := 'frmMtoModalArtTar';
  formulario.Caption := 'Seleccione Tarifas a incorporar al artículo';
  try
    dmmArticulos.FillTarifas(formulario.lstTarifas);
    formulario.ShowModal;
  finally
      inherited;
      if formulario.sFicha = 'S' then
      begin
        IterateCheckedListArt(formulario.lstTarifas);
      end;
      FreeAndNil(formulario);
  end;
end;

procedure TfrmMtoArticulos.IterateCheckedListArt(lst: TcxListView);
var
  bAdded:Boolean;
  i: Integer;
  item: TListItem;
begin
  bAdded := False;
  with dmmArticulos.unqryTarifasArticulos do
  begin
    for i := 0 to lst.Items.Count - 1 do
    begin
      item := lst.Items[i];
      if item.Checked then
      begin
        Insert;
        FieldByName('CODIGO_TAR_ARTTAR').AsString := item.Caption;
        FieldByName('ESACTIVO_ARTTAR').AsString := 'S';
        FieldByName('FECHA_DESDE_ARTTAR').AsDateTime := Now;
        FieldByName('PRECIO_SALIDA_ARTTAR').AsInteger := 0;
        FieldByName('PRECIO_FINAL_ARTTAR').AsInteger := 0;
        FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := '';
        Post;
        bAdded := True;
      end;
    end;
    Refresh;
  end;
  if bAdded then
    dbcTarifasPRECIOSALIDA.FocusWithSelection;
end;

procedure TfrmMtoArticulos.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsGeneral;
end;

procedure TfrmMtoArticulos.BuscarProveedores;
begin
  if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Proveedores en Articulos',
                                     dmmArticulos.unqryProveedores,
                                     'frmMtoArtProvSearch') then
    dmmArticulos.CopiarProveedoraArticulo(dmmArticulos.unqryProveedores);
end;

procedure TfrmMtoArticulos.cbbFamiliaPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  // Verificamos que el gestor esté creado y estemos en modo inserción o edición
  if Assigned(FGestorProp) and
     (dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    // Forzamos a que el control actualice su EditValue
    cbbFamilia.PostEditValue;
    if not VarIsNull(cbbFamilia.EditValue) then
      FGestorProp.CargarPropiedadesPorFamilia(VarToStr(cbbFamilia.EditValue));
  end;
end;

procedure TfrmMtoArticulos.CrearTablaPrincipal;
begin
  inherited;
  dmmArticulos := tdmDataModule as TdmArticulos;
  cbbFamilia.Properties.ListSource := dmmArticulos.dsFamiliaArticulos;
  tvTarifas.DataController.DataSource := dmmArticulos.dsTarifasArticulos;
  tvProveedores.DataController.DataSource :=
                                            dmmArticulos.dsProveedoresArticulos;
  tvLinFac.DataController.DataSource := dmmArticulos.dsLinFacturasArticulos;
  tvSkus.DataController.DataSource := dmmArticulos.dsVariacionesArticulos;
  tvStock.DataController.DataSource := dmmArticulos.dsStockArticulos;
  pkFieldName := 'CODIGO_ART_ART';
  dmmArticulos.unqryTablaG.AfterScroll := OnAfterScrollArticulos;
  InicializarPestanyaPropiedades;
  InicializarPestanyaVariaciones;
  if dmmArticulos.unqryTablaG.Active and (dmmArticulos.unqryTablaG.RecordCount > 0) then
  begin
    FArticuloCargado := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    FGestorProp.CargarPropiedades(FArticuloCargado);
  end else
    FArticuloCargado := ''; // Por si acaso arranca vacío
  FGestorVar.CargarVariaciones(                // [AÑADIR]
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString);
  ActualizarVisibilidadVariaciones;
  ActualizarVisibilidadColumnaSku;
end;

procedure TfrmMtoArticulos.InicializarPestanyaPropiedades;
var
  pnlTop: TPanel;
begin
  // Ocultar el grid estático si existe en el DFM

  // Panel superior con botón "+ Añadir propiedad"
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent     := tsPropiedades;
  pnlTop.Align      := alTop;
  pnlTop.Height     := 36;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color      := tsPropiedades.Color;

  FBtnAddProp := TcxButton.Create(Self);
  FBtnAddProp.Parent  := pnlTop;
  FBtnAddProp.Caption := '+ Añadir propiedad';
  FBtnAddProp.Left    := 8;
  FBtnAddProp.Top     := 4;
  FBtnAddProp.Width   := 200;
  FBtnAddProp.Height  := 26;
  FBtnAddProp.OnClick := BtnAddPropClick;   // ver punto 7

  // ScrollBox que ocupa el resto de la pestaña
  FScrollProp := TScrollBox.Create(Self);
  FScrollProp.Parent      := tsPropiedades;
  FScrollProp.Align       := alClient;
  FScrollProp.BorderStyle := bsNone;
  FScrollProp.Color       := clWindow;

  // Crear el gestor
  FGestorProp := TGestorPropiedades.Create(
    FScrollProp,
    oConn,   // <-- ajusta al nombre real de tu TUniConnection
    oUser               // <-- ajusta a tu función/variable de usuario
  );
end;

procedure TfrmMtoArticulos.InicializarPestanyaVariaciones;
var
//  pnlTop  : TPanel;
  lbl     : TcxLabel;
//  splitter: TSplitter;
begin

  // ── Panel superior con label + combo de tipo variación ──
  FPnlTopVariaciones := TPanel.Create(Self);
  FPnlTopVariaciones.Parent     := tsGeneral;
  FPnlTopVariaciones.Align      := alBottom;
  FPnlTopVariaciones.Height     := 40;
  FPnlTopVariaciones.BevelOuter := bvNone;
  FPnlTopVariaciones.Caption    := '';

  lbl := TcxLabel.Create(Self);
  lbl.Parent  := FPnlTopVariaciones;
  lbl.Left    := 8;
  lbl.Top     := 10;
  lbl.Caption := 'Tipo de variación: ';
  lbl.AutoSize:= True;

  // Combo enlazado al campo TIPO_VARIACION_ART del dataset principal
  FCbbTipoVariacion := TcxDBLookupComboBox.Create(Self);
  FCbbTipoVariacion.Parent          := FPnlTopVariaciones;
  FCbbTipoVariacion.Left            := 170;
  FCbbTipoVariacion.Top             := 6;
  FCbbTipoVariacion.Width           := 260;
  FCbbTipoVariacion.Height          := 26;
  FCbbTipoVariacion.DataBinding.DataSource := dsTablaG;
  FCbbTipoVariacion.DataBinding.DataField  := 'TIPO_VARIACION_ART';
  // ListSource apunta a un dataset con las variaciones activas
  FCbbTipoVariacion.Properties.ListSource     := dmmArticulos.dsVariaciones;
  FCbbTipoVariacion.Properties.KeyFieldNames  := 'CODIGO_VAR';
  FCbbTipoVariacion.Properties.ListFieldNames := 'NOMBRE_VAR';
  FCbbTipoVariacion.Properties.ReadOnly       := True;  // por defecto solo lectura
  FCbbTipoVariacion.Properties.ListOptions.ShowHeader := False;
  // ── Zona atributos (scroll) ──
  FScrollVarAtrib := TScrollBox.Create(Self);
  FScrollVarAtrib.Parent      := tsGeneral;
  FScrollVarAtrib.Align       := alBottom;
  FScrollVarAtrib.Height      := 120;
  FScrollVarAtrib.BorderStyle := bsNone;
  FScrollVarAtrib.Color       := clWindow;
  FScrollVarAtrib.AutoScroll  := True;

//  splitter := TSplitter.Create(Self);
//  splitter.Parent := tsVariaciones;
//  splitter.Align  := alTop;
//  splitter.Height := 5;

//  // ── Zona SKUs (scroll) ──
//  FScrollVarSkus := TScrollBox.Create(Self);
//  FScrollVarSkus.Parent      := tsVariaciones;
//  FScrollVarSkus.Align       := alClient;
//  FScrollVarSkus.BorderStyle := bsNone;
//  FScrollVarSkus.Color       := clWindow;
//  FScrollVarSkus.AutoScroll  := True;

  FGestorVar := TGestorVariaciones.Create(
    FScrollVarAtrib,
//    FScrollVarSkus,
    oConn,
    oUser
  );
end;

procedure TfrmMtoArticulos.BtnAddPropClick(Sender: TObject);
begin
  // Si hay cambios no guardados en el artículo, grabar primero
  if (dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit]) then
    dmmArticulos.unqryTablaG.Post;

  if Assigned(FGestorProp) then
    FGestorProp.AbrirSelectorPropiedades;
end;

procedure TfrmMtoArticulos.OnAfterScrollArticulos(DataSet: TDataSet);
var
  CodArticulo: string;
begin
  if DataSet.ControlsDisabled then Exit;
  // 1. Si estamos creando un artículo nuevo, limpiamos la pantalla una sola vez y salimos
  if DataSet.State = dsInsert then
  begin
    if FArticuloCargado <> '' then
    begin
      FArticuloCargado := ''; // Marcamos como vacío
      if Assigned(FGestorProp) then FGestorProp.CargarPropiedades('');
      if Assigned(FGestorVar) then FGestorVar.CargarVariaciones('');
      ActualizarVisibilidadVariaciones;
    end;
    Exit;
  end;

  // 2. Si estamos editando, ignoramos los scrolls fantasma
  if DataSet.State = dsEdit then Exit;

  CodArticulo := DataSet.FieldByName('CODIGO_ART_ART').AsString;

  // 3. EL ESCUDO: Si el artículo es exactamente el mismo que ya está dibujado, ¡no hagas nada!
  if FArticuloCargado = CodArticulo then Exit;

  // Actualizamos nuestra memoria
  FArticuloCargado := CodArticulo;

  // 4. Ahora sí, cargamos la interfaz visual de forma segura
  if Assigned(FGestorProp) then
    FGestorProp.CargarPropiedades(CodArticulo);

  if Assigned(FGestorVar) then
    FGestorVar.CargarVariaciones(CodArticulo);

  ActualizarVisibilidadVariaciones;
  // Si el artículo no tiene variaciones, garantizamos un SKU = código artículo
  // para que la rejilla SKUs y CB tenga al menos una fila editable
  AsegurarSkuArticuloSinVariaciones(CodArticulo);
  dmmArticulos.unqrySkus.Refresh;
  dmmArticulos.unqryVariacionesArticulos.Refresh;
  dmmArticulos.unqryStockArticulosAfterScroll(DataSet);
  ActualizarVisibilidadColumnaSku;
end;

procedure TfrmMtoArticulos.cxButton11Click(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxGrdMovimientos, 'Movimientos_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.cxDBComboBox1PropertiesEditValueChanged(Sender: TObject);
begin
  inherited;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if not Assigned(dmmArticulos) or not Assigned(dmmArticulos.unqryTablaG) then
    Exit;
  if not dmmArticulos.unqryTablaG.Active then
    Exit;
  // Refrescamos visibilidad de stock/movimientos según el nuevo TIPO_ART
  ActualizarVisibilidadVariaciones;
end;

procedure TfrmMtoArticulos.cxDBCheckBox1PropertiesEditValueChanged(Sender: TObject);
begin
  inherited;
  // 1. Comprobaciones básicas del estado del formulario
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  // 2. Asegurar que los objetos de datos existen
  if not Assigned(dmmArticulos) or not Assigned(dmmArticulos.unqryTablaG) then
    Exit;
  // 3. Comprobar que el dataset está activo, no está vacío y no está bloqueado
  if dmmArticulos.unqryTablaG.IsEmpty then
    Exit;
  if dmmArticulos.unqryTablaG.ControlsDisabled then
    Exit;
  if not dmmArticulos.unqryTablaG.Active then
    Exit;
  // 4. Validar el estado de edición y la interacción REAL del usuario
  if (dmmArticulos.unqryTablaG.State in [dsEdit, dsInsert]) then
  begin
    // El Focus garantiza que el evento lo ha disparado el usuario y no un refresco del dataset
    if (Sender as TcxDBCheckBox).Focused then
    begin
      (Sender as TcxDBCheckBox).PostEditValue;
      ActualizarVisibilidadVariaciones;
    end;
  end;
end;

procedure
    TfrmMtoArticulos.cxgrdbclmnProveedoresCODIGO_PROVEEDORPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  inherited;
  BuscarProveedores;
end;

procedure TfrmMtoArticulos.
                          dbcTarifasPORCEN_DTO_TARIFAPropertiesEditValueChanged(
  Sender: TObject);
var
    e: TcxCustomEdit;
begin
  inherited;
  if (dmmArticulos <> nil) then
    with dmmArticulos.unqryTarifasArticulos do
    begin
      if ((State = dsInsert) or (State = dsEdit)) then
      begin
        e := Sender as TcxCustomEdit;
        FindField('PORCENTAJE_DTO_ARTTAR').AsString := VarToStr(e.EditingValue);
        FindField('PRECIO_DTO_ARTTAR').AsFloat :=
                               (FindField('PRECIO_SALIDA_ARTTAR').AsFloat * (
                                FindField('PORCENTAJE_DTO_ARTTAR').AsFloat / 100));
        FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
                                    ( FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
                                      FindField('PRECIO_DTO_ARTTAR').AsFloat
                                    );
      end;
    end;
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOFINALPropertiesEditValueChanged(
  Sender: TObject);
var
    e: TcxCustomEdit;
  begin
  inherited;
  if (dmmArticulos <> nil) then
    with dmmArticulos.unqryTarifasArticulos do
    begin
      if ((State = dsInsert) or (State = dsEdit)) then
      begin
        e := Sender as TcxCustomEdit;
        FindField('PRECIO_FINAL_ARTTAR').AsString := VarToStr(e.EditingValue);
        if (FindField('PORCENTAJE_DTO_ARTTAR').AsFloat <> 0) then
        begin
          FindField('PRECIO_DTO_ARTTAR').AsFloat :=
                                (FindField('PRECIO_FINAL_ARTTAR').AsFloat * (
                                 FindField('PORCENTAJE_DTO_ARTTAR').AsFloat / 100));
          FindField('PRECIO_SALIDA_ARTTAR').AsFloat :=
                                        FindField('PRECIO_FINAL_ARTTAR').AsFloat
                                       - FindField('PRECIO_DTO_ARTTAR').AsFloat;
        end
        else
        begin
          FindField('PRECIO_SALIDA_ARTTAR').AsString :=
                                       FindField('PRECIO_FINAL_ARTTAR').AsString;
          FindField('PRECIO_DTO_ARTTAR').AsFloat := 0;
          FindField('PORCENTAJE_DTO_ARTTAR').AsFloat := 0;
        end;
      end;
    end;
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOSALIDAPropertiesEditValueChanged(
  Sender: TObject);
var
    e: TcxCustomEdit;
begin
  inherited;
  if (dmmArticulos <> nil) then
    with dmmArticulos.unqryTarifasArticulos do
    begin
    if ((State = dsInsert) or (State = dsEdit)) then
      begin
        e := Sender as TcxCustomEdit;
        FindField('PRECIO_SALIDA_ARTTAR').AsString := VarToStr(e.EditingValue);
        FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
                                    ( FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
                                      FindField('PRECIO_DTO_ARTTAR').AsFloat
                                    );
      end;
    end;
end;

procedure TfrmMtoArticulos.
                          dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged(
  Sender: TObject);
var
    e: TcxCustomEdit;
begin
  inherited;
  if (dmmArticulos <> nil) then
    with dmmArticulos.unqryTarifasArticulos do
    begin
      if ((State = dsInsert) or (State = dsEdit)) then
      begin
        e := Sender as TcxCustomEdit;
        FindField('PRECIO_DTO_ARTTAR').AsString := VarToStr(e.EditingValue);
        if (FindField('PRECIO_SALIDA_ARTTAR').AsFloat <> 0) then
        begin
          FindField('PORCENTAJE_DTO_ARTTAR').AsFloat :=
                             ((FindField('PRECIO_DTO_ARTTAR').AsFloat /
                               FindField('PRECIO_SALIDA_ARTTAR').AsFloat) * 100);
          FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
                                    ( FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
                                      FindField('PRECIO_DTO_ARTTAR').AsFloat);
        end;
      end;
    end;
end;

procedure TfrmMtoArticulos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.state = dsInsert) then
    txtCODIGO_ARTICULO.Properties.ReadOnly := False
  else
  begin
    txtCODIGO_ARTICULO.Properties.ReadOnly := True;
  end;
  if Assigned(FCbbTipoVariacion) then
    FCbbTipoVariacion.Properties.ReadOnly := not (dsTablaG.State in [dsInsert]);
end;

procedure TfrmMtoArticulos.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FGestorProp) then
    FreeAndNil(FGestorProp);
  if Assigned(FGestorVar) then
    FreeAndNil(FGestorVar);
  dmmArticulos := nil;
end;

procedure TfrmMtoArticulos.FormShow(Sender: TObject);
begin
  inherited;
  ResetForm;
end;

initialization
  ForceReferenceToClass(TfrmMtoArticulos);
end.
