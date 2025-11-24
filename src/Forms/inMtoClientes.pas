{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoClientes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  Vcl.Menus, cxContainer, dxSkinsForm, cxClasses, cxLocalization, cxDBNavigator,
  cxLabel, Vcl.StdCtrls, cxButtons, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  Vcl.ExtCtrls, UniDataConn, UniDataClientes, dxBar,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, cxTextEdit, Vcl.Buttons, dxBevel,
  cxCurrencyEdit, cxCalendar, cxMaskEdit, cxDropDownEdit, cxDBEdit,
  dxGDIPlusClasses, cxImage, cxCustomListBox, cxCheckListBox, cxDBCheckListBox,
  cxCheckBox, cxMemo, inLibDevExp, inLibtb, cxBlobEdit, ClipBrd, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, dxScrollbarAnnotations, dxCore,
  cxSpinEdit,
  cxRadioGroup, cxGridExportLink,  System.UITypes, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, cxSplitter,
  cxDBExtLookupComboBox, cxGroupBox, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
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
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoClientes = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPAIS_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinOBSERVACIONES_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinREFERENCIA_CLIENTE: TcxGridDBColumn;
    pnl1: TPanel;
    pnl2: TPanel;
    pcPestanas: TcxPageControl;
    tsDomicilioFiscal: TcxTabSheet;
    tsMasDatos: TcxTabSheet;
    tsHistoriaFacturacion: TcxTabSheet;
    tsPresupuestos: TcxTabSheet;
    cxgrd3: TcxGrid;
    tv2: TcxGridDBTableView;
    cxgrdbclmn1: TcxGridDBColumn;
    cxgrdbclmn2: TcxGridDBColumn;
    cxgrdbclmn3: TcxGridDBColumn;
    cxgrdbclmn4: TcxGridDBColumn;
    cxgrdbclmn5: TcxGridDBColumn;
    cxgrdbclmn6: TcxGridDBColumn;
    cxgrdbclmn7: TcxGridDBColumn;
    cxgrdbclmn8: TcxGridDBColumn;
    cxgrdbclmn9: TcxGridDBColumn;
    cxgrdbclmn10: TcxGridDBColumn;
    cxgrdbclmn11: TcxGridDBColumn;
    cxgrdbclmn12: TcxGridDBColumn;
    cxgrdbclmn13: TcxGridDBColumn;
    cxgrdbclmn14: TcxGridDBColumn;
    cxgrdbclmn15: TcxGridDBColumn;
    cxgrdbclmn16: TcxGridDBColumn;
    cxgrdbclmn17: TcxGridDBColumn;
    tv3: TcxGridDBTableView;
    cxgrdbclmn18: TcxGridDBColumn;
    cxgrdbclmn19: TcxGridDBColumn;
    cxgrdbclmn20: TcxGridDBColumn;
    cxgrdbclmn21: TcxGridDBColumn;
    cxgrdbclmn22: TcxGridDBColumn;
    cxgrdbclmn23: TcxGridDBColumn;
    cxgrdbclmn24: TcxGridDBColumn;
    cxgrdbclmn25: TcxGridDBColumn;
    cxgrdlvl2: TcxGridLevel;
    cxgrdlvl3: TcxGridLevel;
    tsOtros: TcxTabSheet;
    pnlUserInstantBottom: TPanel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    txtINSTANTEMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRETENCIONES_CLIENTE: TcxGridDBColumn;
    mTEXTO_LEGAL_FACTURA_CLIENTE: TcxDBMemo;
    lblTextoLegal: TcxLabel;
    lblSerieDefault: TcxLabel;
    txtSERIE_CONTADOR: TcxDBTextEdit;
    btnNuevoCliente: TcxButton;
    cxGrdDBTabPrinESIVA_EXENTO_CLIENTE: TcxGridDBColumn;
    cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE: TcxGridDBColumn;
    cxGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_FORMA_PAGO_CLIENTE: TcxGridDBColumn;
    pnlFacturaCli: TPanel;
    cxgrdClientesFacturas: TcxGrid;
    tvFacturacion: TcxGridDBTableView;
    tvLineasFacturacion: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA:
                                                                TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA:
                                                                TcxGridDBColumn;
    tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA:
                                                                TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn;
    tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn;
    tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdClientesFacturasgrdlvlcxgrd1Level1: TcxGridLevel;
    cxgrdClientesFacturasgrdlvlcxgrd1Level2: TcxGridLevel;
    pnlFacturaOpts: TPanel;
    btnIraFactura: TcxButton;
    btnIraEmpresa: TcxButton;
    btnExportar: TcxButton;
    tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    tvFacturacionFECHA_FACTURA: TcxGridDBColumn;
    tvFacturacionNRO_FACTURA: TcxGridDBColumn;
    tvFacturacionSERIE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn;
    tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn;
    tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn;
    tvFacturacionESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_REN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RER_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn;
    cxspltr1: TcxSplitter;
    lblOrdenListado: TcxLabel;
    spORDEN_CLIENTE: TcxDBSpinEdit;
    btnIraArticulo: TcxButton;
    dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn;
    cxgrpbx1: TcxGroupBox;
    lblDireccion1: TcxLabel;
    txtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblDireccion2: TcxLabel;
    txtDIRECCION2_CLIENTE: TcxDBTextEdit;
    lblCodPostal: TcxLabel;
    txtCPOSTAL_CLIENTE: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    txtPOBLACION_CLIENTE: TcxDBTextEdit;
    lblProvincia: TcxLabel;
    txtPROVINCIA_CLIENTE: TcxDBTextEdit;
    lblPais: TcxLabel;
    txtPAIS_CLIENTE: TcxDBTextEdit;
    cxgrpbxTratamientoFiscal: TcxGroupBox;
    chkREGIMENAGRICOLA: TcxDBCheckBox;
    chkINTRACOMUNITARIO: TcxDBCheckBox;
    chkIVAEXENTO: TcxDBCheckBox;
    chkRECARGO_EQUIV: TcxDBCheckBox;
    chkRETENCIONES: TcxDBCheckBox;
    cxgrpbx3: TcxGroupBox;
    lblContacto: TcxLabel;
    txtCONTACTO_CLIENTE: TcxDBTextEdit;
    lblTelefonoContacto: TcxLabel;
    txtTELEFONO_CONTACTO_CLIENTE: TcxDBTextEdit;
    lblReferencia: TcxLabel;
    txtREFERENCIA_CLIENTE: TcxDBTextEdit;
    lblObservaciones: TcxLabel;
    cxdbmOBSERVACIONES_CLIENTE: TcxDBMemo;
    lblFormadePago: TcxLabel;
    cbbFORMAPAGO: TcxDBLookupComboBox;
    lblNroCuenta: TcxLabel;
    lblTextoLegal2: TcxLabel;
    cbbTARIFA: TcxDBLookupComboBox;
    txtTARIFA_ARTICULO_CLIENTE: TcxDBTextEdit;
    cxgrpbx4: TcxGroupBox;
    lblRazonSocial: TcxLabel;
    lblCodigoCliente: TcxLabel;
    txtCODIGO_CLIENTE: TcxDBTextEdit;
    txtRAZONSOCIAL_CLIENTE: TcxDBTextEdit;
    chkActivo: TcxDBCheckBox;
    lblEmail: TcxLabel;
    txtEMAIL_CLIENTE: TcxDBTextEdit;
    lblNif: TcxLabel;
    txtNIF_CLIENTE: TcxDBTextEdit;
    lblTelefonos: TcxLabel;
    txtMOVIL_CLIENTE: TcxDBTextEdit;
    txtTELEFONO_CLIENTE: TcxDBTextEdit;
    ActionListClientes: TActionList;
    actEmpresas: TAction;
    actFacturas: TAction;
    actArticulos: TAction;
    tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    tvFacturacionGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_IVA_FACTURA: TcxGridDBColumn;
    txtIBAN_CLIENTE: TcxDBMaskEdit;
    btnValidar: TcxButton;
    cxButton1: TcxButton;
    dxBarPopupMenu1: TdxBarPopupMenu;
    dxBarManager1: TdxBarManager;
    blbEtiqueta: TdxBarLargeButton;
    txtNOMBRE_PAIS_CLIENTE: TcxDBTextEdit;
    cbbPaises: TcxDBLookupComboBox;
    procedure btnGrabarClick(Sender: TObject);
    procedure btnNuevoClienteClick(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnIraEmpresaClick(Sender: TObject);
    procedure actEmpresasExecute(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
//    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnValidarClick(Sender: TObject);
    procedure blbEtiquetaClick(Sender: TObject);
    procedure txtNOMBRE_PAIS_CLIENTEPropertiesChange(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  dmmClientes: TDMClientes;
  frmMtoClientes: TfrmMtoClientes;

implementation

uses
  inLibWin,
  inLibUser,
  inLibShowMto,
  inMtoFacturas,
  inMtoEmpresas,
  inMtoArticulos,
  inMtoModalCliEti,
  inLibDir,
  inLibIBAN,
  inMtoPrincipal2;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoClientes.actArticulosExecute(Sender: TObject);
begin
  inherited;
  //Control + R
  if (
        (pcPestanas.ActivePage = tsHistoriaFacturacion)) then
       btnIraArticuloClick(Sender)
    else
      ShowMto(Self.Owner,
              'Articulos' );
end;

procedure TfrmMtoClientes.actEmpresasExecute(Sender: TObject);
begin
  //control + E -> Empresas
  inherited;
    if (
        (pcPestanas.ActivePage = tsHistoriaFacturacion)) then
      btnIraEmpresaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Empresas');
end;

procedure TfrmMtoClientes.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F
  if (
        (pcPestanas.ActivePage = tsHistoriaFacturacion)) then
      btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoClientes.blbEtiquetaClick(Sender: TObject);
var
  formulario : TfrmPrintCliEti;
begin
  inherited;
  formulario := TfrmPrintCliEti.Create(Application);
  try
    formulario.edtCodCli.Text :=
                        dsTablaG.Dataset.FieldByName('CODIGO_CLIENTE').AsString;
    formulario.ShowModal;
  finally
    FreeAndNil(formulario);
  end;
end;

procedure TfrmMtoClientes.btnExportarClick(Sender: TObject);
begin
  ExportarExcel(cxgrdClientesFacturas, 'Historico_Facturas_Cliente_' +
                       dsTablaG.Dataset.FieldByName('CODIGO_CLIENTE').AsString);
end;

procedure TfrmMtoClientes.btnIraEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          tvFacturacion.DataController.DataSet.FieldByName(
                                            'CODIGO_EMPRESA_FACTURA').AsString);
end;

procedure TfrmMtoClientes.btnIraFacturaClick(Sender: TObject);
var
  sNroFactura, sSerieFactura:String;
begin
  inherited;
  sNroFactura := tvFacturacion.DataController.DataSet.FieldByName(
                                                        'NRO_FACTURA').AsString;
  sSerieFactura := tvFacturacion.DataController.DataSet.FieldByName(
                                                      'SERIE_FACTURA').AsString;
  ShowMto(Self.Owner,
          'Facturas',
          sNroFactura+','+ sSerieFactura);
end;

procedure TfrmMtoClientes.btnGrabarClick(Sender: TObject);
begin
  //inherited;
  if (dsTablaG.DataSet <> nil) and
     ((dsTablaG.State = dsInsert) or
     (dsTablaG.State = dsEdit)) then
    dmmClientes.unqryTablaG.Post;
end;

procedure TfrmMtoClientes.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  with tvLineasFacturacion.DataController.DataSet do
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString);
end;

procedure TfrmMtoClientes.btnNuevoClienteClick(Sender: TObject);
begin
  inherited;
    if ( (dmmClientes.unqryTablaG.State = dsInsert) or
       (dmmClientes.unqryTablaG.State = dsEdit)) then
  begin
    dmmClientes.unqryTablaG.Post;
  end;
  dmmClientes.unqryTablaG.Insert;
  pcPantalla.Properties.ActivePage := tsFicha;
  tsFicha.SetFocus;
  pcPestanas.Properties.ActivePage := tsDomicilioFiscal;
  tsDomicilioFiscal.SetFocus;
  txtRAZONSOCIAL_CLIENTE.SetFocus;
end;

procedure TfrmMtoClientes.btnValidarClick(Sender: TObject);
var
  sIBAN, sPref, sPref4:String;
  iLen:Integer;
  sErr:String;
  EsIBANErr:boolean;
  stErr:TStringList;
begin
  inherited;
  EsIBANErr := False;
  stErr := TStringList.Create;
  sIBAN := StringReplace(dsTablaG.DataSet.FieldByName('IBAN_CLIENTE').Text,
                         ' ', '', [rfReplaceAll]);
  iLen := Length(sIBAN);
  sPref := (Copy(sIBAN, 1, 2));
  if ((sPref = 'ES') or (iLen = 20)) then
  begin
    TIBANUtils.IsValidDC(sIBAN, stErr);
    sErr := stErr.Text;
    if (sErr <> '') then
    begin
      ShowMessage(sErr);
      EsIBANErr := True;
    end;
  end;
  if ((iLen = 20) and
      (StrToIntDef(sPref, 0) <> 0) and
      not(EsIBANErr)) then
  begin
    sPref4 := TIBANUtils.GetIBAN('ES', sIBAN);
    if (dsTablaG.State = dsBrowse) then
      dsTablaG.DataSet.Edit;
    dsTablaG.DataSet.FieldByName('IBAN_CLIENTE').Text := sPref4 + sIBAN;
  end;
  if (not(EsIBANErr) and (StrToIntDef(sPref, 0) = 0)) then
  begin
    TIBANUtils.IsValidIBAN(sIBAN, stErr);
    sErr := stErr.Text;
    if (sErr <> '') then
    begin
      ShowMessage(sErr);
      EsIBANErr := True;
    end;
  end;
  if not(EsIBANErr) then
    ShowMessage('IBAN Validado OK');
  FreeAndNil(stErr);
end;

procedure TfrmMtoClientes.CrearTablaPrincipal;
begin
  inherited;
  dmmClientes := tdmDataModule as TdmClientes;
  tvFacturacion.DataController.DataSource := dmmClientes.dsFacturasClientes;
  tvLineasFacturacion.DataController.DataSource :=
                                           dmmClientes.dsFacturasLineasClientes;
  cbbFORMAPAGO.Properties.ListSource := dmmClientes.dsFormasPago;
  cbbTARIFA.Properties.ListSource := dmmClientes.dsTarifas;
  cbbPaises.Properties.ListSource := dmmClientes.dsPaises;
  pcPestanas.ActivePage := tsDomicilioFiscal;
  Self.pkFieldName := 'CODIGO_CLIENTE';
end;

procedure TfrmMtoClientes.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.state = dsInsert) then
    txtCODIGO_CLIENTE.Enabled := True
  else
    txtCODIGO_CLIENTE.Enabled := False;
end;

procedure TfrmMtoClientes.ResetForm;
begin
  inherited;
  pcPestanas.ActivePage := tsDomicilioFiscal;
end;

procedure TfrmMtoClientes.txtNOMBRE_PAIS_CLIENTEPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) or (dsTablaG.State = dsEdit) then
  begin
    dsTablaG.DataSet.FieldByName('NOMBRE_PAIS_CLIENTE').AsString :=
                         dmmClientes.unqryPaises.FieldByName('NOMBRE').AsString;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoClientes);
end.
