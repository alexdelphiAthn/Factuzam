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
    tvTarifas: TcxGridDBTableView;
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
    btnCrearTarifa: TcxButton;
    btnExportarTarifa: TcxButton;
    btnIraCliente: TcxButton;
    cxgrdbclmnProveedoresRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    btnAddProveedor: TcxButton;
    cxgrdbclmnProveedoresESPROVEEDORPRINCIPAL: TcxGridDBColumn;
    splSplitterFicha: TcxSplitter;
    cxgrdbclmnTarifasCODIGO_ARTICULO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasTIPO_IVA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasACTIVO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasCODIGO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasFECHA_DESDE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasFECHA_HASTA_TARIFA: TcxGridDBColumn;
    dbcTarifasPRECIOFINAL: TcxGridDBColumn;
    dbcTarifasPRECIOSALIDA: TcxGridDBColumn;
    dbcTarifasPORCEN_DTO_TARIFA: TcxGridDBColumn;
    dbcTarifasPRECIO_DTO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnTarifasRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnTarifasPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnTarifasFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnTarifasCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnTarifasINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnTarifasINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnTarifasUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnTarifasUSUARIOMODIF: TcxGridDBColumn;
    cxgrdbclmnTarifasNOMBRE_TARIFA: TcxGridDBColumn;
    lblTextoLegal11: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevoArticulo: TcxButton;
    ActionListArticulos: TActionList;
    actEmpresas: TAction;
    actFacturas: TAction;
    actClientes: TAction;
    actProveedores: TAction;
    actTarifas: TAction;
    dbcTarifasCODIGO_UNICO_TARIFA: TcxGridDBColumn;
    dbcTarifasESIMP_INCL_TARIFA: TcxGridDBColumn;
    dbcTarifasESDEFAULT_TARIFA: TcxGridDBColumn;
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
    tsSKUs: TcxTabSheet;
    Panel1: TPanel;
    cxButton2: TcxButton;
    addSkuAll: TcxButton;
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
    tvSkusSTOCK_TOTAL: TcxGridDBColumn;
    cxButton1: TcxButton;
    cxButton5: TcxButton;
    cxGrid5: TcxGrid;
    tvStock: TcxGridDBTableView;
    cxGridLevel4: TcxGridLevel;
    Panel2: TPanel;
    cxButton6: TcxButton;
    cxButton7: TcxButton;
    cxButton8: TcxButton;
    cxButton9: TcxButton;
    cxButton10: TcxButton;
    cxGrid6: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxGridLevel5: TcxGridLevel;
    Panel3: TPanel;
    cxButton11: TcxButton;
    cxButton12: TcxButton;
    cxButton13: TcxButton;
    cxButton14: TcxButton;
    cxButton15: TcxButton;
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
    tvTarifasCODIGO_UNIDAD_TARIFA: TcxGridDBColumn;
    tvTarifasESVARIACION_ARTICULO: TcxGridDBColumn;
    tvTarifasNUM_ATRIBUTOS_REQ: TcxGridDBColumn;
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
    procedure cbbFamiliaPropertiesEditValueChanged(Sender: TObject);
    procedure addSkuAllClick(Sender: TObject);
    procedure btnAddSKUClick(Sender: TObject);
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
  inMtoModalGenerarSKUs;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoArticulos.ActualizarVisibilidadVariaciones;
var
  HayVars: Boolean;
begin
  if Assigned(dmmArticulos) and (dmmArticulos.unqryTablaG.Active = True) then
    HayVars := dmmArticulos.unqryTablaG.FieldByName(
                                     'ESVARIACION_ARTICULO').AsWideString = 'S';
  FPnlTopVariaciones.Visible := HayVars;
  FScrollVarAtrib.Visible := HayVars;
  tsSKUS.TabVisible := HayVars;
end;

procedure TfrmMtoArticulos.addSkuAllClick(Sender: TObject);
var
  CodArticulo, TipoVariacion: string;
begin
  // 1. Nos aseguramos de que el artículo no esté a medias de editar
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  // 2. Leemos los datos clave del dataset principal
  CodArticulo   := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString;
  TipoVariacion := dmmArticulos.unqryTablaG.FieldByName('TIPO_VARIACION_ARTICULO').AsString;

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
    // Si la pantalla devuelve True (es decir, el usuario le dio a "Generar" y se guardaron los SKUs),
    // refrescamos el dataset que alimenta el Grid de SKUs para que aparezcan al instante.

    // Asumiendo que el nombre de tu query es este según tu nomenclatura:
//    dmmArticulos.unqryVariacionesArticulos.Close;
//    dmmArticulos.unqryVariacionesArticulos.Open;
  end;
  dmmArticulos.unqryVariacionesArticulos.Refresh;
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
        (not(FieldByName('CODIGO_EMPRESA_FACTURA_LINEA').IsNull))
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
        (not(FieldByName('NRO_FACTURA_LINEA').IsNull))  and
        (not(FieldByName('SERIE_FACTURA_LINEA').IsNull))
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
    if ((not(FieldByName('CODIGO_FAMILIA_ARTICULO').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Familias',
              FieldByName('CODIGO_FAMILIA_ARTICULO').AsString)
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
        (not(FieldByName('CODIGO_PROVEEDOR').IsNull))
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
        (not(FieldByName('CODIGO_TARIFA').IsNull))
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
  codArticulo:String;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  CodArticulo := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString;
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
      qryTodasTarifas.SQL.Text := 'SELECT CODIGO_TARIFA FROM fza_tarifas WHERE ACTIVO_TARIFA = ''S'' ORDER BY ORDEN_TARIFA';
      qryTodasTarifas.Open;

      while not qryTodasTarifas.Eof do
      begin
        chkTarifas.Items.Add.Text := qryTodasTarifas.FieldByName('CODIGO_TARIFA').AsString;
        qryTodasTarifas.Next;
      end;
    finally
      qryTodasTarifas.Free;
    end;

    // Mostramos tu modal
    frmSel.ShowModal;

    // Si el usuario aceptó
    if frmSel.sFicha = 'S' then
    begin
      // Leemos las fechas seleccionadas por el usuario en el formulario
      UserDesde := dtpDesde.Date;
      TieneUserHasta := not VarIsNull(dtpHasta.EditValue);
      if TieneUserHasta then UserHasta := dtpHasta.Date;

      dmmArticulos.unqryTarifasArticulos.DisableControls;

      TarifasActivas := TStringList.Create;
      TarifasActivas.Sorted := True;
      TarifasActivas.Duplicates := dupIgnore;

      try
        // ====================================================================
        // 1. PRE-ESCANEO: Comprobación matemática de solapamiento de rangos
        // ====================================================================
        Bkm := dmmArticulos.unqryTarifasArticulos.GetBookmark;

        dmmArticulos.unqryTarifasArticulos.First;
        while not dmmArticulos.unqryTarifasArticulos.Eof do
        begin
          // Leemos el rango de fechas de la tarifa en base de datos
          DbDesde := dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_DESDE_TARIFA').AsDateTime;
          DbHastaIsNull := dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_HASTA_TARIFA').IsNull;
          if not DbHastaIsNull then
            DbHasta := dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_HASTA_TARIFA').AsDateTime;

          // Lógica de solapamiento: (InicioA <= FinB) Y (InicioB <= FinA)
          // Si alguno de los fines es nulo, se considera infinito.
          Cond1 := (not TieneUserHasta) or (DbDesde <= UserHasta);
          Cond2 := DbHastaIsNull or (UserDesde <= DbHasta);

          HaySolapamiento := Cond1 and Cond2;

          if HaySolapamiento then
          begin
            LlaveUnica := dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_TARIFA').AsString + '|' +
                          dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_TARIFA').AsString;
            TarifasActivas.Add(LlaveUnica); // Marcamos combinación como ocupada en estas fechas
          end;

          dmmArticulos.unqryTarifasArticulos.Next;
        end;
        if dmmArticulos.unqryTarifasArticulos.BookmarkValid(Bkm) then
          dmmArticulos.unqryTarifasArticulos.GotoBookmark(Bkm);
        dmmArticulos.unqryTarifasArticulos.FreeBookmark(Bkm);

        // ====================================================================
        // 2. INSERCIÓN SEGURA (Ignorando solapamientos)
        // ====================================================================
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
                    dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_TARIFA').AsString := ''
                  else
                    dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_TARIFA').AsString := chkSkus.Items[i].Text;

                  dmmArticulos.unqryTarifasArticulos.FieldByName('CODIGO_TARIFA').AsString := chkTarifas.Items[j].Text;
                  dmmArticulos.unqryTarifasArticulos.FieldByName('ACTIVO_TARIFA').AsString := 'S';
                  dmmArticulos.unqryTarifasArticulos.FieldByName('PRECIOSALIDA_TARIFA').AsFloat := 0;
                  dmmArticulos.unqryTarifasArticulos.FieldByName('PRECIOFINAL_TARIFA').AsFloat := 0;

                  // Aplicamos las fechas que eligió el usuario
                  dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_DESDE_TARIFA').AsDateTime := UserDesde;
                  if TieneUserHasta then
                    dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_HASTA_TARIFA').AsDateTime := UserHasta
                  else
                    dmmArticulos.unqryTarifasArticulos.FieldByName('FECHA_HASTA_TARIFA').Clear;

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
//      pcDetail.ActivePage := tsTarifas;
//      if tvTarifas.CanFocus then tvTarifas.SetFocus;
    end;

  finally
    frmSel.Free;
  end;
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
                dsTablaG.Dataset.FieldByName('CODIGO_ARTICULO').AsString);
end;

procedure TfrmMtoArticulos.btnExportarTarifaClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxGrdTarifas, 'Historico_Tarifas_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ARTICULO').AsString);
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
                                      'CODIGO_EMPRESA_FACTURA_LINEA').AsString);
end;

procedure TfrmMtoArticulos.btnIraFacturaClick(Sender: TObject);
begin
  inherited;
  with tvLinFac.DataController.DataSource.DataSet do
  ShowMto(Self.Owner,
          'Facturas',
          FieldByName('NRO_FACTURA_LINEA').AsString + ',' +
          FieldByName('SERIE_FACTURA_LINEA').AsString);
end;

procedure TfrmMtoArticulos.btnIraProveedorClick(Sender: TObject);
begin
  inherited;
    ShowMto(Self.Owner,
    'Proveedores',
    tvProveedores.DataController.DataSet.FieldByName(
                                                  'CODIGO_PROVEEDOR').AsString);
end;

procedure TfrmMtoArticulos.btnIraTarifaClick(Sender: TObject);
begin
  inherited;
    ShowMto(Self.Owner,
            'Tarifas',
                 dmmArticulos.unqryTarifasArticulos.FieldByName(
                                                     'CODIGO_TARIFA').AsString);
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
        FieldByName('CODIGO_TARIFA').AsString := item.Caption;
        FieldByName('ACTIVO_TARIFA').AsString := 'S';
        FieldByName('FECHA_DESDE_TARIFA').AsDateTime := Now;
        FieldByName('PRECIOSALIDA_TARIFA').AsInteger := 0;
        FieldByName('PRECIOFINAL_TARIFA').AsInteger := 0;
        FieldByName('CODIGO_UNIDAD_TARIFA').AsString := '';
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
  //pcDetail.ActivePage := tsTarifas;
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
  pkFieldName := 'CODIGO_ARTICULO';
  dmmArticulos.unqryTablaG.AfterScroll := OnAfterScrollArticulos;
  InicializarPestanyaPropiedades;
  InicializarPestanyaVariaciones;
  if dmmArticulos.unqryTablaG.Active and (dmmArticulos.unqryTablaG.RecordCount > 0) then
  begin
    FArticuloCargado := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString;
    FGestorProp.CargarPropiedades(FArticuloCargado);
  end else
    FArticuloCargado := ''; // Por si acaso arranca vacío
  FGestorVar.CargarVariaciones(                // [AÑADIR]
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString);
  ActualizarVisibilidadVariaciones;
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

  // Combo enlazado al campo TIPO_VARIACION_ARTICULO del dataset principal
  FCbbTipoVariacion := TcxDBLookupComboBox.Create(Self);
  FCbbTipoVariacion.Parent          := FPnlTopVariaciones;
  FCbbTipoVariacion.Left            := 170;
  FCbbTipoVariacion.Top             := 6;
  FCbbTipoVariacion.Width           := 260;
  FCbbTipoVariacion.Height          := 26;
  FCbbTipoVariacion.DataBinding.DataSource := dsTablaG;
  FCbbTipoVariacion.DataBinding.DataField  := 'TIPO_VARIACION_ARTICULO';
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

  CodArticulo := DataSet.FieldByName('CODIGO_ARTICULO').AsString;

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
  dmmArticulos.unqryStockArticulosAfterScroll(DataSet);
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

  if dmmArticulos.unqryTablaG.IsEmpty then Exit;
  if dmmArticulos.unqryTablaG.ControlsDisabled then Exit;
  if not dmmArticulos.unqryTablaG.Active then Exit;

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
        FindField('PORCEN_DTO_TARIFA').AsString := VarToStr(e.EditingValue);
        FindField('PRECIO_DTO_TARIFA').AsFloat :=
                               (FindField('PRECIOSALIDA_TARIFA').AsFloat * (
                                FindField('PORCEN_DTO_TARIFA').AsFloat / 100));
        FindField('PRECIOFINAL_TARIFA').AsFloat :=
                                    ( FindField('PRECIOSALIDA_TARIFA').AsFloat -
                                      FindField('PRECIO_DTO_TARIFA').AsFloat
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
        FindField('PRECIOFINAL_TARIFA').AsString := VarToStr(e.EditingValue);
        if (FindField('PORCEN_DTO_TARIFA').AsFloat <> 0) then
        begin
          FindField('PRECIO_DTO_TARIFA').AsFloat :=
                                (FindField('PRECIOFINAL_TARIFA').AsFloat * (
                                 FindField('PORCEN_DTO_TARIFA').AsFloat / 100));
          FindField('PRECIOSALIDA_TARIFA').AsFloat :=
                                        FindField('PRECIOFINAL_TARIFA').AsFloat
                                       - FindField('PRECIO_DTO_TARIFA').AsFloat;
        end
        else
        begin
          FindField('PRECIOSALIDA_TARIFA').AsString :=
                                       FindField('PRECIOFINAL_TARIFA').AsString;
          FindField('PRECIO_DTO_TARIFA').AsFloat := 0;
          FindField('PORCEN_DTO_TARIFA').AsFloat := 0;
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
        FindField('PRECIOSALIDA_TARIFA').AsString := VarToStr(e.EditingValue);
        FindField('PRECIOFINAL_TARIFA').AsFloat :=
                                    ( FindField('PRECIOSALIDA_TARIFA').AsFloat -
                                      FindField('PRECIO_DTO_TARIFA').AsFloat
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
        FindField('PRECIO_DTO_TARIFA').AsString := VarToStr(e.EditingValue);
        if (FindField('PRECIOSALIDA_TARIFA').AsFloat <> 0) then
        begin
          FindField('PORCEN_DTO_TARIFA').AsFloat :=
                             ((FindField('PRECIO_DTO_TARIFA').AsFloat /
                               FindField('PRECIOSALIDA_TARIFA').AsFloat) * 100);
          FindField('PRECIOFINAL_TARIFA').AsFloat :=
                                    ( FindField('PRECIOSALIDA_TARIFA').AsFloat -
                                      FindField('PRECIO_DTO_TARIFA').AsFloat);
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
