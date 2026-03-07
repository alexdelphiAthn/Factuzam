unit inMtoPedidos;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoGen, dxSkinsCore, dxSkinBlue, dxSkinsdxBarPainter, dxBar,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsForm, cxLabel, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons, dxBarExtItems, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxSpinEdit, cxCurrencyEdit, UniDataPedidos, dxBarBuiltInMenu, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit;

type
  TfrmMtoPedidos = class(TfrmMtoGen)
    pnlTopPedido: TPanel;
    pcPedido: TcxPageControl;
    tsLineasPedido: TcxTabSheet;
    cxGrdPedidosLineas: TcxGrid;
    tvPedidosLineas: TcxGridDBTableView;
    cxGrdPedidosLineasLevel1: TcxGridLevel;
    dbcGrdDBTabPrinNRO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMPRESA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinNIF_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinEMAIL_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinREFERENCIAPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinIDPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHAPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinFORMAPAGOPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    dbcGrdDBTabPrinTRANSPORTISTAPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADOPEDIDOPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADOMENSAJEPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinIDHILOPS_MENSAJES_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinMOVIL_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION1_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION2_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPOBLACION_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPROVINCIA_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCPOSTAL_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_PAIS_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinRAZONSOCIAL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinMOVIL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinEMAIL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION1_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION2_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPOBLACION_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPROVINCIA_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCPOSTAL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_PAIS_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESIVA_RECARGO_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESIVA_EXENTO_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESRETENCIONES_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTARIFA_ARTICULO_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESIMP_INCL_TARIFA_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESAPLICA_RE_ZONA_IVA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_IVA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESVENTA_ACTIVO_FIJO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_IVAN_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_IVAN_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_REN_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_REN_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_BASEI_IVAN_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_IVAR_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_IVAR_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_RER_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_RER_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_BASEI_IVAR_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_IVAS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_IVAS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_RES_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_RES_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_BASEI_IVAS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_IVAE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_IVAE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_REE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_REE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_BASEI_IVAE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_BASES_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_IMPUESTOS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinFORMA_PAGO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinPORCEN_RETENCION_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_RETENCION_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_LIQUIDO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_PAGADOREALPS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinNRO_PEDIDO_ABONO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_PEDIDO_ABONO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTEXTO_LEGAL_PEDIDO_CLIENTE_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinTEXTO_LEGAL_PEDIDO_EMPRESA_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinDOCUMENTO_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCOMENTARIOS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinCONTADOR_LINEAS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESCREARARTICULOS_PEDIDO: TcxGridDBColumn;
    dbcGrdDBTabPrinESDESCRIPCIONES_AMP_PEDIDO: TcxGridDBColumn;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    lblNroFactura: TcxLabel;
    lblFechaFactura: TcxLabel;
    dteFECHA_FACTURA: TcxDBDateEdit;
    lblSerieFactura: TcxLabel;
    btnCODIGO_CLIENTE: TcxDBButtonEdit;
    lblCodigoCliente: TcxLabel;
    cxdblblRAZONSOCIAL_EMPRESA_FACTURA: TcxDBLabel;
    cxdblblRAZONSOCIAL_CLIENTE_FACTURA: TcxDBLabel;
    btnCODIGO_EMPRESA_FACTURA: TcxDBButtonEdit;
    lblCodigoEmpresa: TcxLabel;
    txtNRO_FACTURA: TcxDBTextEdit;
    cbbSerieFactura: TcxDBLookupComboBox;
    tsEmpresa: TcxTabSheet;
    cxgrpbxEmpresa: TcxGroupBox;
    txtDIRECCION1_EMPRESA_FACTURA: TcxDBTextEdit;
    txtCPOSTAL_EMPRESA_FACTURA: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_FACTURA: TcxDBTextEdit;
    txtPAIS_EMPRESA_FACTURA: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_FACTURA: TcxDBTextEdit;
    lblProvinciaEmpresa: TcxLabel;
    lblPaisEmpresa: TcxLabel;
    txtRAZONSOCIAL_EMPRESA_FACTURA: TcxDBTextEdit;
    txtNIF_EMPRESA_FACTURA: TcxDBTextEdit;
    lblNIFEmpresa: TcxLabel;
    lblMovilEmpresa: TcxLabel;
    txtMOVIL_EMPRESA_FACTURA: TcxDBTextEdit;
    txtEMAIL_EMPRESA_FACTURA: TcxDBTextEdit;
    lblEmailEmpresa: TcxLabel;
    chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox;
    chkRETENCION_EMPRESA_FACTURA: TcxDBCheckBox;
    cxdbmPOBLACION_EMPRESA_FACTURA: TcxDBMemo;
    cbbCanalIVA: TcxDBLookupComboBox;
    lblCanalIVA: TcxLabel;
    txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit;
    btnUpdateEmpresa: TcxButton;
    btnIrAEmpresa: TcxButton;
    cxdblblCODIGO_EMPRESA_FACTURA: TcxDBLabel;
    tsDatosCliente: TcxTabSheet;
    cxgrpbxCliente: TcxGroupBox;
    txtDIRECCION1_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtCPOSTAL_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtPAIS_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_FACTURA1: TcxDBTextEdit;
    lblcxlbl6: TcxLabel;
    lblcxlbl13: TcxLabel;
    txtRAZONSOCIAL_CLIENTE_FACTURA: TcxDBTextEdit;
    txtNIF_CLIENTE_FACTURA: TcxDBTextEdit;
    lblNif: TcxLabel;
    lblTelefonoMovil: TcxLabel;
    txtMOVIL_CLIENTE_FACTURA: TcxDBTextEdit;
    txtEMAIL_CLIENTE_FACTURA: TcxDBTextEdit;
    lblEmail: TcxLabel;
    chkESIVA_RECARGO_CLIENTE_FACTURA: TcxDBCheckBox;
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxDBCheckBox;
    chkRETENCIONES_EMPRESA_FACTURA3: TcxDBCheckBox;
    chkEXTRANJERO: TcxDBCheckBox;
    cbbTARIFA_ARTICULOS_CLIENTES: TcxDBLookupComboBox;
    lblTarifaArticulosCliente: TcxLabel;
    chkIVA_EXENTO_CLIENTE_FACTURA: TcxDBCheckBox;
    chkImpIncl: TcxDBCheckBox;
    txtCODIGO_PAIS_CLIENTE_FACTURA: TcxDBTextEdit;
    btnUpdateCliente: TcxButton;
    btnIrACliente: TcxButton;
    cxdblblCODIGO_CLIENTE_FACTURA: TcxDBLabel;
    procedure btnGrabarClick(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMtoPedidos: TfrmMtoPedidos;
  dmmPedidos:TdmPedidos;
implementation

{$R *.dfm}

procedure TfrmMtoPedidos.FormCreate(Sender: TObject);
begin
  inherited;
  dmmPedidos := TdmPedidos.Create(Self);
  dsTablaG.DataSet := dmmPedidos.unqryTablaG;
  tvPedidosLineas.DataController.DataSource := dmmPedidos.dsPedidosLineas;
end;

procedure TfrmMtoPedidos.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcPedido.ActivePage := tsLineasPedido;
  //cxdbtNRO_PEDIDO.SetFocus;
end;

procedure TfrmMtoPedidos.btnGrabarClick(Sender: TObject);
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmPedidos.CalcularTotalesPedido;
    dsTablaG.DataSet.Post;
  end;
end;

procedure TfrmMtoPedidos.btnAnadirLineaClick(Sender: TObject);
begin
  dmmPedidos.unqryPedidosLineas.Append;
end;

procedure TfrmMtoPedidos.btnBorrarLineaClick(Sender: TObject);
begin
  if MessageDlg('¿Está seguro de que desea eliminar esta línea?',
                mtConfirmation,
                [mbYes, mbNo],
                0 ) = mrYes then
  begin
    dmmPedidos.unqryPedidosLineas.Delete;
  end;
end;

end.