{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoFacturas;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoGen,  cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,  System.StrUtils,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer, System.UITypes,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxSplitter, cxImage, cxDBEdit, dxBarBuiltInMenu, cxPC, cxLabel,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxMemo, cxDBLookupComboBox,
  cxGridBandedTableView, cxGridDBBandedTableView, cxLocalization,
  cxGroupBox, DBCtrls, cxCurrencyEdit, Menus, cxButtons, cxButtonEdit,
  inlibDevExp, cxLookupEdit, cxDBLookupEdit, Uni, cxSpinEdit, cxCalc,
  cxDataControllerConditionalFormattingRulesManagerDialog, dxBevel,
  cxDBNavigator, dxNumericWheelPicker, dxDateRanges, cxDataUtils, cxVariants,
  cxDBLabel, dxGDIPlusClasses, dxSkinsForm, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, System.Actions, Vcl.ActnList,
  IDETheme.ActnCtrls, Vcl.ActnMan, Vcl.StdStyleActnCtrls, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab, UniDataFacturas, dxShellDialogs, JvBaseDlg,
  JvCalc, dxDateTimeWheelPicker, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue;

type
  TfrmMtoFacturas = class(TfrmMtoGen)
    pnl1: TPanel;
    pcDetail: TcxPageControl;
    tsLineasFactura: TcxTabSheet;
    tsTotales: TcxTabSheet;
    lblTotalaPagar: TcxLabel;
    cxgrdLineasFactura: TcxGrid;
    tvLineasFactura: TcxGridDBTableView;
    cxgrdlvlLineasFactura: TcxGridLevel;
    curTotalAPagar: TcxDBCurrencyEdit;
    tsOtros: TcxTabSheet;
    lblComentarios: TcxLabel;
    cxgrdbclmnGrdDBTabPrinNRO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinSERIE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinFECHA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinFORMA_PAGO_FACTURA: TcxGridDBColumn;
    mmodbComentarios: TcxDBMemo;
    tsRecibos: TcxTabSheet;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    lblNroFactura: TcxLabel;
    lblFechaFactura: TcxLabel;
    dteFECHA_FACTURA: TcxDBDateEdit;
    lblSerieFactura: TcxLabel;
    btnCODIGO_CLIENTE: TcxDBButtonEdit;
    lblCodigoCliente: TcxLabel;
    lbldbRAZONSOCIAL_EMPRESA_FACTURA: TcxDBLabel;
    tsEmpresa: TcxTabSheet;
    grpEmpresa: TcxGroupBox;
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
    tsDatosCliente: TcxTabSheet;
    grpCliente: TcxGroupBox;
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
    btnUpdateCliente: TcxButton;
    curTOTAL_LIQUIDO_FACTURA: TcxDBCurrencyEdit;
    lblTotalRetencionFactura: TcxLabel;
    lblPorcRetencionFactura: TcxLabel;
    lbldbRAZONSOCIAL_CLIENTE_FACTURA: TcxDBLabel;
    btnCODIGO_EMPRESA_FACTURA: TcxDBButtonEdit;
    lblCodigoEmpresa: TcxLabel;
    btnUpdateEmpresa: TcxButton;
    cxgrdbclmnGrdDBTabPrinCODIGO_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCODIGO_ZONA_IVA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_IVAN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_REN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_REN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAR_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_IVAR_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_RER_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_RER_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_IVAS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_RES_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_RES_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_REE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_REE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_RETENCION_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_RETENCION_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNRO_FACTURA_ABONO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinSERIE_FACTURA_ABONO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDOCUMENTO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCOMENTARIOS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    chkESIVA_RECARGO_CLIENTE_FACTURA: TcxDBCheckBox;
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxDBCheckBox;
    chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox;
    chkRETENCIONES_EMPRESA_FACTURA3: TcxDBCheckBox;
    chkEXTRANJERO: TcxDBCheckBox;
    ctbCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbCANTIDAD_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbTOTAL_FACTURA_LINEA: TcxGridDBColumn;
    txtNRO_FACTURA: TcxDBTextEdit;
    cbbTARIFA_ARTICULOS_CLIENTES: TcxDBLookupComboBox;
    lblTarifaArticulosCliente: TcxLabel;
    ctbLINEA_FACTURA_LINEA: TcxGridDBColumn;
    spnRetencion: TcxDBSpinEdit;
    curTOTAL_RETENCION_FACTURA: TcxDBCurrencyEdit;
    lblTotalBaseImponible: TcxLabel;
    curTOTAL_BASES_FACTURA: TcxDBCurrencyEdit;
    lbl1TotalImpuestos: TcxLabel;
    chkRETENCION_EMPRESA_FACTURA: TcxDBCheckBox;
    ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    chkIVA_EXENTO_CLIENTE_FACTURA: TcxDBCheckBox;
    ctbIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxDBCheckBox;
    chkESVENTA_ACTIVO_FIJO_FACTURA: TcxDBCheckBox;
    cxGrdDBTabPrinGRUPO_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_IVA_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_BASES_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinCONTADOR_LINEAS_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn;
    splSplitterFicha: TcxSplitter;
    mPOBLACION_EMPRESA_FACTURA: TcxDBMemo;
    pnlRightRecibos: TPanel;
    pnlBodyRecibos: TPanel;
    cxgrdRecibos: TcxGrid;
    tvRecibos: TcxGridDBTableView;
    cxgrdlvlRecibos: TcxGridLevel;
    cxgrdbclmnRecibosNRO_FACTURA_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosSERIE_FACTURA_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosNRO_PLAZO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosEUROS_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosESTADO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFECHA_PAGO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO: TcxGridDBColumn;
    btnReciboDevuelto: TcxButton;
    btnImprimirRecibo: TcxButton;
    btnReciboEmitido: TcxButton;
    btnReciboPagado: TcxButton;
    pnlRightLineas: TPanel;
    chkFechaEntrega: TcxDBCheckBox;
    chkDescripcion_ampliada: TcxDBCheckBox;
    chkCrearArticulos: TcxDBCheckBox;
    cbbSerieFactura: TcxDBLookupComboBox;
    cxgrdbclmnGrdDBTabPrinESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA:
                                                                TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESCREARARTICULOS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESDESCRIPCIONES_AMP_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESFECHADEENTREGA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA:
                                                                TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn;
    lblFormadePago: TcxLabel;
    cbbFORMAPAGO: TcxDBLookupComboBox;
    btnGenerarRecibos: TcxButton;
    cbbCanalIVA: TcxDBLookupComboBox;
    lblCanalIVA: TcxLabel;
    ctbCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    ctbNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    ctbFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    btnExportarLineas: TcxButton;
    btnExportarRecibos: TcxButton;
    btnIraArticulo: TcxButton;
    btnIrAEmpresa: TcxButton;
    btnIrACliente: TcxButton;
    btnNuevaFactura: TcxButton;
    btnRectificar: TcxButton;
    btnImprimir: TcxButton;
    ActionListFacturas: TActionList;
    actArticulo: TAction;
    actEmpresa: TAction;
    actCliente: TAction;
    lbldbCODIGO_CLIENTE_FACTURA: TcxDBLabel;
    lbldbCODIGO_CLIENTE: TcxDBLabel;
    chkImpIncl: TcxDBCheckBox;
    ctbPRECIOSALIDA_FACTURA_LINEA: TcxGridDBColumn;
    ctbPORCEN_DTO_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIO_DTO_FACTURA_LINEA: TcxGridDBColumn;
    GroupBox1: TGroupBox;
    lblTotRE: TcxLabel;
    PorRE: TcxLabel;
    lblTotIVA: TcxLabel;
    lblPorIVA: TcxLabel;
    lblBaseNeta: TcxLabel;
    lblNormal: TcxLabel;
    lblReducido: TcxLabel;
    lblSReducido: TcxLabel;
    lblExento: TcxLabel;
    cxDBCurrencyEdit1: TcxDBCurrencyEdit;
    cxDBCurrencyEdit2: TcxDBCurrencyEdit;
    cxDBCurrencyEdit3: TcxDBCurrencyEdit;
    cxDBCurrencyEdit4: TcxDBCurrencyEdit;
    cxDBCurrencyEdit5: TcxDBCurrencyEdit;
    cxDBCurrencyEdit6: TcxDBCurrencyEdit;
    cxDBCurrencyEdit7: TcxDBCurrencyEdit;
    cxDBCurrencyEdit8: TcxDBCurrencyEdit;
    cxDBCurrencyEdit9: TcxDBCurrencyEdit;
    cxDBCurrencyEdit10: TcxDBCurrencyEdit;
    cxDBCurrencyEdit11: TcxDBCurrencyEdit;
    cxDBCurrencyEdit12: TcxDBCurrencyEdit;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;
    cxDBSpinEdit1: TcxDBSpinEdit;
    cxDBSpinEdit2: TcxDBSpinEdit;
    cxDBSpinEdit3: TcxDBSpinEdit;
    cxDBSpinEdit4: TcxDBSpinEdit;
    cxDBSpinEdit5: TcxDBSpinEdit;
    Shape6: TShape;
    cxDBSpinEdit7: TcxDBSpinEdit;
    cxDBSpinEdit8: TcxDBSpinEdit;
    cxDBSpinEdit9: TcxDBSpinEdit;
    ctbTOTAL_FACTURASIVA_LINEA: TcxGridDBColumn;
    ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA: TcxGridDBColumn;
    ctbCODIGO_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn;
    ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIO_ULT_COMPRA_FACTURA_LINEA: TcxGridDBColumn;
    JvCalculator1: TJvCalculator;
    btnCalculator: TcxButton;
    txtNOMBRE_PAIS_CLIENTE_FACTURA: TcxDBTextEdit;
    txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit;
    cbbPaisesCli: TcxDBLookupComboBox;
    cbbPaisesEmp: TcxDBLookupComboBox;
    chkConsolidada: TcxDBCheckBox;
    pnlUserInstantBottom: TPanel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    txtINSTANTEMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtINSTANTECONSOLIDACION: TcxDBTextEdit;
    btnConsolidar: TcxButton;
    dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    dbcGrdDBTabPrinESCONSOLIDADA_FACTURA: TcxGridDBColumn;
    dbcGrdDBTabPrinINSTANTECONSO_FACTURA: TcxGridDBColumn;
    tsVerifactu: TcxTabSheet;
    tsRegistro: TcxTabSheet;
    scrlbx1: TScrollBox;
    lbl18: TLabel;
    lbl17: TLabel;
    lbl13: TLabel;
    lbl12: TLabel;
    lbl11: TLabel;
    lbl10: TLabel;
    lbl9: TLabel;
    lbl8: TLabel;
    lbl7: TLabel;
    lbl6: TLabel;
    lbl: TLabel;
    lbl15: TLabel;
    lbl16: TLabel;
    btnReconsolidar: TSpeedButton;
    btnConsultarEstado: TSpeedButton;
    btnCancelarFactura: TSpeedButton;
    btnSubsanacion: TSpeedButton;
    spQUEUE_ID: TcxDBSpinEdit;
    cxdbmRESPUESTA_COMPLETA: TcxDBMemo;
    cxdbmQRCODE_BASE64: TcxDBMemo;
    cxdbmVERIFACTU_URL: TcxDBMemo;
    txtCHAIN_HASH: TcxDBTextEdit;
    txtCHAIN_NUMBER: TcxDBTextEdit;
    dteISSUED_TIME: TcxDBDateEdit;
    txtISSUER_IRS_ID: TcxDBTextEdit;
    imgQRCODE_PNG: TcxDBImage;
    txtREQUEST_ID: TcxDBTextEdit;
    spID_CONSOLIDACION: TcxDBSpinEdit;
    cxdbmPETICION_COMPLETA1: TcxDBMemo;
    dteFECHA_PROCESAMIENTO: TcxDBDateEdit;
    txtESTADO: TcxDBTextEdit;
    cxGrid1: TcxGrid;
    cxGridDBTableView1: TcxGridDBTableView;
    cxGridLevel1: TcxGridLevel;
    cxGridDBTableView1TIMESTAMP_LOG: TcxGridDBColumn;
    cxGridDBTableView1DESCRIPCION_LOG: TcxGridDBColumn;
    cxGridDBTableView1DATOS_ADICIONALES_LOG: TcxGridDBColumn;
    cxGridDBTableView1NRO_FACTURA_LOG: TcxGridDBColumn;
    cxGridDBTableView1SERIE_FACTURA_LOG: TcxGridDBColumn;
    procedure sbGrabarClick(Sender: TObject);
    procedure btnUpdateClienteClick(Sender: TObject);
    procedure sbNuevaFacturaClick(Sender: TObject);
//    procedure cxgrdbclmntv1CODIGO_ARTICULO_LINEAPropertiesEditValueChanged(
//      Sender: TObject);
    procedure btnCODIGO_CLIENTEPropertiesEditValueChanged(Sender: TObject);
    procedure tvLineasFacturaKeyDown(Sender: TObject;
                                     var Key: Word;
                                     Shift: TShiftState);
    procedure btnCODIGO_CLIENTEKeyUp( Sender: TObject;
                                      var Key: Word;
                                      Shift: TShiftState);
    procedure cbbSerieFacturaKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dteFECHA_FACTURAKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnCODIGO_CLIENTEPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnGenerarRecibosClick(Sender: TObject);
    procedure btnReciboPagadoClick(Sender: TObject);
    procedure btnReciboEmitidoClick(Sender: TObject);
    procedure btnReciboDevueltoClick(Sender: TObject);
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
   procedure btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnUpdateEmpresaClick(Sender: TObject);
    procedure cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
      Sender: TObject; AButtonIndex: Integer);
    procedure
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure sbRectificarClick(Sender: TObject);
    procedure sbImprimirClick(Sender: TObject);
    procedure chkESIVA_RECARGO_CLIENTE_FACTURAPropertiesChange(
      Sender: TObject);
    procedure btnImprimirReciboClick(Sender: TObject);
    procedure chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURAPropertiesChange(
      Sender: TObject);
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesChange(Sender: TObject);
    procedure dteFECHA_FACTURAPropertiesChange(Sender: TObject);
    procedure btnCODIGO_CLIENTEPropertiesChange(Sender: TObject);
    procedure cbbCanalIVAPropertiesChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure chkFechaEntregaPropertiesChange(Sender: TObject);
    procedure chkDescripcion_ampliadaPropertiesChange(Sender: TObject);
    procedure chkCrearArticulosPropertiesChange(Sender: TObject);
    procedure btNExportarLineasClick(Sender: TObject);
    procedure btnExportarRecibosClick(Sender: TObject);
    procedure actArticuloExecute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actClienteExecute(Sender: TObject);
    procedure actEmpresaExecute(Sender: TObject);
    procedure btnIrAClienteClick(Sender: TObject);
    procedure btnIrAEmpresaClick(Sender: TObject);
    procedure cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange(
      Sender: TObject);
    procedure tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure spnRetencionPropertiesEditValueChanged(Sender: TObject);
    procedure ctbCODIGO_FAMILIA_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure ctbCODIGO_PROVEEDOR_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnCalculatorClick(Sender: TObject);
    procedure chkConsolidadaPropertiesChange(Sender: TObject);
    procedure btnConsolidarClick(Sender: TObject);
//    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    procedure ActualizarComboSeries;
    procedure CambiarEstadoRecibo(sEstado:String);
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure CambiarIVA;
    //procedure CalcularLinea;
  private
    procedure CheckConsolidacion;
    procedure AsignarControles;
  end;

var
  //frmMtoFacturas: TfrmMtoFacturas;
  dmmFacturas : TdmFacturas;

implementation

uses
  inLibWin,
  inLibMsg,
  inLibShowMto,
  inLibFacturas,
  inMtoGenSearch,
  inMtoModalFacRec,
  inMtoModalImpRecFac,
  inMtoModalImpFac,
  inMtoPrincipal2,
  inLibUser,
  inMtoArticulos,
  inMtoEmpresas,
  inMtoClientes,
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoFacturas.btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo:String;
  unqrySol:TUniQuery;
begin
  inherited;
  if Assigned(dsTablaG.DataSet) then
  if ((dsTablaG.DataSet.State = dsInsert) or
     (dsTablaG.Dataset.State = dsEdit))
       //and not dmmFacturas.bEsNuevaEmpresa
     then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := VarToStr(e.EditingValue);
    if ((sCodigo <> '') and (sCodigo <> '0')) then
    begin
      dsTablaG.Dataset.FindField('CODIGO_EMPRESA_FACTURA').AsString :=
                                                     VarToStr(e.EditingValue);
      unqrySol := TUniQuery.Create(Self);
      unqrySol.Connection := oConn;
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM fza_empresas ' +
                           ' WHERE CODIGO_EMPRESA = :empresa';
      unqrySol.ParamByName('empresa').AsString := VarToStr(e.EditingValue);
      unqrySol.Open;
      if unqrySol.RecordCount = 0 then
        Sleep(0)
        //MessageDlg('Empresa: #' + VarToStr(e.EditingValue) + '# no existe')
      else
        dmmFacturas.CopiarEmpresaaFactura(unqrySol);
      unqrySol.Close;
      FreeAndNil(unqrySol);
    end;
  end;
end;

procedure TfrmMtoFacturas.btnConsolidarClick(Sender: TObject);
begin
  inherited;
  with dmmFacturas.unqryTablaG do
  begin
    if Active = True then
    if (FieldByName('ESCONSOLIDADA_FACTURA').AsString <> 'S') then
    begin
      if ((dsTablaG.State <> dsEdit) and (dsTablaG.State <> dsInsert)) then
        dmmFacturas.unqryTablaG.Edit;
      FieldByName('ESCONSOLIDADA_FACTURA').AsString := 'S';
      FieldByName('INSTANTECONSO_FACTURA').AsDateTime := Now;
      Post;
    end;
  end;
end;


procedure TfrmMtoFacturas.ResetForm;
begin
  inherited;
  pcCab.ActivePage := tsCabecera;
  pcDetail.ActivePage := tsLineasFactura;
end;

procedure TfrmMtoFacturas.btnUpdateClienteClick(Sender: TObject);
begin
  inherited;
  with dmmFacturas.unqryTablaG do
  begin
    if (FieldByName('CODIGO_CLIENTE_FACTURA').AsString = '0') then
      dmmFacturas.GetCodigoAutoCliente;
    dmmFacturas.CrearCliente;
    ShowMessageFmt(SCliToTbl,
                   [FieldByName('CODIGO_CLIENTE_FACTURA').AsString]);
  end;
end;

procedure TfrmMtoFacturas.btnUpdateEmpresaClick(Sender: TObject);
begin
  inherited;
  with dmmFacturas.unqryTablaG do
  begin
    if (FieldByName('CODIGO_EMPRESA_FACTURA').AsString = '0') then
      dmmFacturas.GetCodigoAutoEmpresa;
    dmmFacturas.CrearEmpresa;
    ShowMessageFmt(SEmpToTbl,
              [FieldByName('CODIGO_EMPRESA_FACTURA').AsString]);
  end;
 end;

procedure TfrmMtoFacturas.sbNuevaFacturaClick(Sender: TObject);
var
  sEmpresaDef:String;
begin
  inherited;
  dmmFacturas.unqryTablaG.ReadOnly := False;
  if (dmmFacturas.unqryTablaG.State <> dsEdit) then
  begin
    if (dmmFacturas.unqryTablaG.State <> dsInsert) then
    begin
      dmmFacturas.unqryTablaG.Insert;
    end;
    txtNRO_FACTURA.Properties.ReadOnly := False;
    cbbSerieFactura.Properties.ReadOnly := False;
    cbbTARIFA_ARTICULOS_CLIENTES.Properties.ReadOnly := False;
    cbbCanalIVA.Properties.ReadOnly := False;
    Self.ResetForm;
    pcPantalla.ActivePage := tsFicha;
    pcCab.ActivePage := tsCabecera;
    btnCODIGO_EMPRESA_FACTURA.SetFocus;
    sEmpresaDef := dmmFacturas.GetUserEmpresaDef;
    if (sEmpresaDef <> '') then
    begin
      dsTablaG.DataSet.FindField('CODIGO_EMPRESA_FACTURA').AsString :=
                                                                    sEmpresaDef;
    end;
  end;
end;

procedure TfrmMtoFacturas.btnImprimirReciboClick(Sender: TObject);
var
  form:TfrmPrintRecFac;
begin
  inherited;
  form := TfrmPrintRecFac.Create(Application);
  try
    form.edtNroFac.Text := dsTablaG.DataSet.findField('NRO_FACTURA').AsString;
    form.edtSerie.Text := dsTablaG.DataSet.findField('SERIE_FACTURA').AsString;
    form.edtPlazoRecFac.Text :=
                dmmFacturas.unqryRecibos.FindField('NRO_PLAZO_RECIBO').AsString;
    form.ShowModal;
  finally
    form.Free;
  end;
end;

procedure TfrmMtoFacturas.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  with tvLineasFactura.DataController.DataSet do
  ShowMto(Self.Owner,
          'Articulos',
          FieldByName(fcodart).AsString);
end;

procedure TfrmMtoFacturas.actArticuloExecute(Sender: TObject);
begin
  inherited;
    if (
        (pcDetail.ActivePage = tsLineasFactura)) then
       btnIraArticuloClick(Sender)
    else
      ShowMto(Self.Owner, 'Articulos');
end;

procedure TfrmMtoFacturas.actClienteExecute(Sender: TObject);
begin
  inherited;
  btnIraClienteClick(Sender);
end;

procedure TfrmMtoFacturas.actEmpresaExecute(Sender: TObject);
begin
  inherited;
  btnIrAEmpresaClick(Sender);
end;

procedure TfrmMtoFacturas.ActualizarComboSeries;
begin
  if ((dsTablaG.State = dsInsert)) then
  begin
    dmmFacturas.CrearTablaSeries(
                dsTablaG.DataSet.FindField(fcodemp).AsString,
                dsTablaG.DataSet.FindField(fcodcli).AsString,
                dsTablaG.DataSet.FindField(ffechfac).AsDateTime);
    cbbSerieFactura.Properties.ListFieldNames := 'SERIE_CONTADOR';
    cbbSerieFactura.Properties.ListSource := dmmFacturas.dsSeriesEditCombo;
    cbbSerieFactura.Refresh;
    dmmFacturas.unqrySeriesEditCombo.First;
    dsTablaG.DataSet.FindField(fseriefac).AsString :=
          dmmFacturas.unqrySeriesEditCombo.FindField('SERIE_CONTADOR').AsString;
  end;
end;

procedure TfrmMtoFacturas.btNExportarLineasClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxGrdLineasFactura, 'Lineas_Factura_' +
                dsTablaG.Dataset.FieldByName(fseriefac).AsString +
                '_' +
                dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturas.btnCalculatorClick(Sender: TObject);
begin
  inherited;
  jvCalculator1.Execute;
end;

procedure TfrmMtoFacturas.btnCODIGO_CLIENTEKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
//  if ((Key = VK_RETURN) and (Shift = [ssCtrl])) then
//    btnBuscar_Clientes_ActivosClick(nil);
  if (Key = VK_RETURN) then
  begin
    //bKeyCODIGO_CLIENTEStroked := True;
  end;
end;

procedure TfrmMtoFacturas.btnCODIGO_CLIENTEPropertiesButtonClick(
                                                         Sender: TObject;
                                                         AButtonIndex: Integer);
var
  formulario : TfrmMtoSearch;
begin
  if (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    formulario := TfrmMtoSearch.Create(Self.Owner);
    formulario.Name := 'frmMtoCliFacSearch';
    formulario.Caption := 'Búsqueda de Clientes en Facturas';
    try
      formulario.dsTablaG.DataSet := dmmFacturas.unqryCliDataFac;
      formulario.dsTablaG.DataSet.Open;
      formulario.ProcesarPerfiles;  //debe ir después de abrir el dataset
      formulario.ShowModal;
    finally
        inherited;
        if formulario.sFicha = 'S' then
          dmmFacturas.CopiarClienteaFactura(dmmFacturas.unqryClidataFac);
        formulario.dsTablaG.DataSet.Close;
        FreeAndNil(formulario);
    end;
  end;
end;

procedure TfrmMtoFacturas.btnCODIGO_CLIENTEPropertiesChange(Sender: TObject);
begin
  inherited;
  //ActualizarComboSeries;
end;

procedure TfrmMtoFacturas.btnCODIGO_CLIENTEPropertiesEditValueChanged(
  Sender: TObject);
  var
    e: TcxCustomEdit;
    sCodigo:String;
begin
  inherited;
  if (Assigned(dsTablaG.DataSet)) then
    if (        ((dsTablaG.DataSet.State = dsInsert) or
                 (dsTablaG.Dataset.State = dsEdit))
       ) then
    begin
      e := Sender as TcxCustomEdit;
      sCodigo := VarToStr(e.EditingValue);
      if ((sCodigo <> '') and (sCodigo <> '0')) then
      begin
        dmmFacturas.BuscarCliente(VarToStr(e.EditingValue));
      end;
    end;
end;

procedure TfrmMtoFacturas.btnCODIGO_EMPRESA_FACTURAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  formulario : TfrmMtoSearch;
begin
  if (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    formulario := TfrmMtoSearch.Create(Self.Owner);
    formulario.Name := 'frmMtoEmpFacSearch';
    formulario.Caption := 'Búsqueda de Empresas en Facturas';
    try
      formulario.dsTablaG.DataSet := dmmFacturas.unqryEmpDataFac;
      formulario.dsTablaG.DataSet.Open;
      formulario.ProcesarPerfiles;
      formulario.ShowModal;
    finally
        if formulario.sFicha = 'S' then
          dmmFacturas.CopiarEmpresaaFactura(dmmFacturas.unqryEmpDataFac);
        formulario.dsTablaG.DataSet.Close;
        FreeAndNil(formulario);
    end;
  end;
end;

procedure TfrmMtoFacturas.btnCODIGO_EMPRESA_FACTURAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  //ActualizarComboSeries;
end;

procedure TfrmMtoFacturas.btnExportarRecibosClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxGrdLineasFactura, 'Recibos_Factura_' +
                      dsTablaG.Dataset.FieldByName(fseriefac).AsString +
                      '_' +
                      dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturas.btnGenerarRecibosClick(Sender: TObject);
var
  bReemplazar:Boolean;
begin
  inherited;
  bReemplazar := True;
  with dmmFacturas.unqryTablaG do
  begin
    if ((State = dsEdit) or (State = dsInsert)) then
      Post;
  end;
  if (dmmFacturas.unqryRecibos.RecordCount > 0) then
  begin
    if ( Application.MessageBox( 'Hay recibos creados, ¿desea reemplazarlos?',
                                 'Mensaje Advertencia',
                                 MB_YESNO ) = ID_YES ) then
      bReemplazar := True
    else
      bReemplazar := False;
  end;
  if bReemplazar = True then
  begin
    with dmmFacturas.unstrdprcGetRecibos do
    begin
      ParamByName('pNRO_FACTURA').AsString :=
                           dsTablaG.DataSet.FieldByName(fnrofac).AsString;
      ParamByName('pSERIE_FACTURA').AsString :=
                         dsTablaG.DataSet.FieldByName(fseriefac).AsString;
      //ParamByName('pINSTANTEMODIF').AsDateTime := Now;
      ParamByName('pUSUARIO').AsString := oUser;
      ExecProc;
      dmmFacturas.unqryRecibos.Close;
      dmmFacturas.unqryRecibos.Open;
    end;
  end;
end;

procedure TfrmMtoFacturas.sbImprimirClick(Sender: TObject);
var
  form:TfrmPrintFac;
begin
  inherited;
  form := TfrmPrintFac.Create(Self);
  try
    form.edtNroFac.Text := dsTablaG.DataSet.findField(fnrofac).AsString;
    form.edtSerie.Text := dsTablaG.DataSet.findField(fseriefac).AsString;
    form.ShowModal;
  finally
    form.Free;
  end;
end;

procedure TfrmMtoFacturas.btnReciboDevueltoClick(Sender: TObject);
begin
  inherited;
  CambiarEstadoRecibo('Devuelto');
end;

procedure TfrmMtoFacturas.btnReciboEmitidoClick(Sender: TObject);
begin
  inherited;
  CambiarEstadoRecibo('Emitido');
end;

procedure TfrmMtoFacturas.btnReciboPagadoClick(Sender: TObject);
begin
  inherited;
  CambiarEstadoRecibo('Pagado');
end;

procedure TfrmMtoFacturas.sbRectificarClick(Sender: TObject);
var
  form:TfrmGenFacRec;
begin
  inherited;
   form := TfrmGenFacRec.Create(Self);
   try
     form.ShowModal;
   finally
     form.Free;
   end;
end;

procedure TfrmMtoFacturas.CambiarEstadoRecibo(sEstado: string);
begin
  with dmmFacturas.unqryRecibos do
  begin
    if not((State = dsEdit) or (State = dsInsert)) then
      Edit;
    FieldByName('STADO_RECIBO').AsString := sEstado;
    if sEstado = 'Pagado' then
       FieldByNAme('FECHA_PAGO_RECIBO').AsDateTime := Trunc(Now)
    else
      if ((sEstado = 'Emitido') or (sEstado='Devuelto')) then
        FieldByNAme('FECHA_PAGO_RECIBO').AsVariant := null;
    Post;
  end;
end;

procedure TfrmMtoFacturas.cbbCanalIVAPropertiesChange(Sender: TObject);
var
 Edit: TcxCustomEdit;
 NewValue: Variant;
begin
  inherited;
  Edit := Sender as TcxCustomEdit;
  NewValue := Edit.EditingValue;
  if (NewValue <> null) then
  begin
    if ((dsTablaG.DataSet.State = dsEdit) or
        (dsTablaG.DataSet.State = dsInsert)) then
    begin
      dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FACTURA').AsString :=
                                                             VarToStr(NewValue);
      CambiarIVA;
    end;
  end;
end;

procedure TfrmMtoFacturas.cbbSerieFacturaKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_DOWN) and (Shift = [ssShift])) then
    cbbSerieFactura.DroppedDown := True;
end;

procedure TfrmMtoFacturas.CheckConsolidacion;
begin
  if Assigned(dmmFacturas) then
   if dmmFacturas.unqryTablaG.FieldByName(fescon).AsString ='S' then
    begin
      dmmFacturas.unqryTablaG.ReadOnly := True;
      dmmFacturas.unqryLinFac.ReadOnly := True;
      tvLineasFactura.optionsData.Editing := False;
      tvLineasFactura.optionsData.Deleting := False;
      tvLineasFactura.optionsData.Inserting := False;
      btnGenerarRecibos.Enabled := False;
      btnConsolidar.Enabled := False;
//      tvRecibos.optionsData.Editing := False;
//      tvRecibos.optionsData.Deleting := False;
//      tvRecibos.optionsData.Inserting := False;
    end
    else
    begin
      dmmFacturas.unqryTablaG.ReadOnly := False;
      dmmFacturas.unqryLinFac.ReadOnly := False;
      tvLineasFactura.optionsData.Editing := True;
      tvLineasFactura.optionsData.Deleting := True;
      tvLineasFactura.optionsData.Inserting := True;
      btnGenerarRecibos.Enabled := True;
      btnConsolidar.Enabled := True;
//      tvRecibos.optionsData.Editing := True;
//      tvRecibos.optionsData.Deleting := True;
//      tvRecibos.optionsData.Inserting := True;

    end;
end;

procedure TfrmMtoFacturas.CrearTablaPrincipal;
begin
  inherited;
  dmmFacturas := (tdmDataModule as TdmFacturas);
  cbbSerieFactura.Properties.ListSource := dmmFacturas.dsSeries;
  cbbCanalIVA.Properties.ListSource := dmmFacturas.dsIvas;
  cbbFORMAPAGO.Properties.ListSource := dmmFacturas.dsFormasPago;
  tvLineasFactura.DataController.DataSource := dmmFacturas.dsLinFac;
  cbbTARIFA_ARTICULOS_CLIENTES.Properties.ListSource := dmmFacturas.dsTarifas;
  tvRecibos.DataController.DataSource := dmmFacturas.dsRecibos;
  cbbPaisesEmp.Properties.ListSource := dmmFacturas.dsPaisesEmp;
  cbbPaisesCli.Properties.ListSource := dmmFacturas.dsPaisesCli;
  //tvIVA.DataController.DataSource := dsTablaG;
  (ctbTIPOIVA_ARTICULO_FACTURA_LINEA.Properties as
             TcxLookupComboBoxProperties).ListSource := dmmFacturas.dsIvasTipos;
  Self.pkFieldName := 'NRO_FACTURA; SERIE_FACTURA';
  CheckConsolidacion;
  AsignarControles;
end;

procedure TfrmMtoFacturas.chkConsolidadaPropertiesChange(Sender: TObject);
begin
  inherited;
  if ( (dmmFacturas <> nil) and
       (dmmFacturas.unqryTablaG <> nil) and
       (dmmFacturas.unqryTablaG.Disconnected = false)) then
     CheckConsolidacion;
end;

procedure TfrmMtoFacturas.chkCrearArticulosPropertiesChange(Sender: TObject);
begin
  inherited;
  if (chkCrearArticulos.Checked = True) then
  begin
    ctbCODIGO_FAMILIA_FACTURA_LINEA.Visible := True;
    ctbNOMBRE_FAMILIA_FACTURA_LINEA.Visible := True;
    ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA.Visible := True;
    ctbCODIGO_PROVEEDOR_FACTURA_LINEA.Visible := True;
    ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA.Visible := True;
    ctbPRECIO_ULT_COMPRA_FACTURA_LINEA.Visible := True;
  end
  else
  begin
    ctbCODIGO_FAMILIA_FACTURA_LINEA.Visible := False;
    ctbNOMBRE_FAMILIA_FACTURA_LINEA.Visible := False;
    ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA.Visible := False;
    ctbCODIGO_PROVEEDOR_FACTURA_LINEA.Visible := False;
    ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA.Visible := False;
    ctbPRECIO_ULT_COMPRA_FACTURA_LINEA.Visible := False;
  end;
end;

procedure TfrmMtoFacturas.chkDescripcion_ampliadaPropertiesChange(
  Sender: TObject);
begin
  inherited;
  with ctbDESCRIPCION_ARTICULO_FACTURA_LINEA do
  begin
    if (chkDescripcion_ampliada.Checked = True) then
    begin
      begin
        PropertiesClassName := 'TcxMemoProperties';
      with TcxMemoProperties(Properties) do
      begin
        VisibleLineCount := 3;
        MaxLength := 1000;
        ScrollBars := ssBoth;
      end
      end
    end
    else
    begin
      ctbDESCRIPCION_ARTICULO_FACTURA_LINEA.PropertiesClassName :=
                                                        'TcxTextEditProperties';
    end;
  end;
end;

procedure TfrmMtoFacturas.chkESIVA_RECARGO_CLIENTE_FACTURAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if chkESIVA_RECARGO_CLIENTE_FACTURA.Checked = True then
  begin
//    dbcPORCEN_REN_FACTURA.Visible := True;
//    dbcTOTAL_REN_FACTURA.Visible := True;
//    dbcPORCEN_RER_FACTURA.Visible := True;
//    dbcTOTAL_RER_FACTURA.Visible := True;
//    dbcPORCEN_RES_FACTURA.Visible := True;
//    dbcTOTAL_RES_FACTURA.Visible := True;
//    dbcPORCEN_REE_FACTURA.Visible := True;
//    dbcTOTAL_REE_FACTURA.Visible := True;
  end
  else
  begin
//    dbcPORCEN_REN_FACTURA.Visible := False;
//    dbcTOTAL_REN_FACTURA.Visible := False;
//    dbcPORCEN_RER_FACTURA.Visible := False;
//    dbcTOTAL_RER_FACTURA.Visible := False;
//    dbcPORCEN_RES_FACTURA.Visible := False;
//    dbcTOTAL_RES_FACTURA.Visible := False;
//    dbcPORCEN_REE_FACTURA.Visible := False;
//    dbcTOTAL_REE_FACTURA.Visible := False;
  end;
end;

procedure TfrmMtoFacturas.
                   chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA.Checked = True then
  begin
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA.Visible := True;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA.Visible := True;
    //dsTablaG.DataSet.FieldByName(
    //                      'ESIRPF_IMP_INCL_ZONA_IVA_FACTURA').AsString := 'S';
    chkESVENTA_ACTIVO_FIJO_FACTURA.Visible := True;
  end
  else
  begin
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA.Visible := False;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA.Visible := False;
    chkESVENTA_ACTIVO_FIJO_FACTURA.Visible := False;
  end;
end;

procedure TfrmMtoFacturas.chkFechaEntregaPropertiesChange(Sender: TObject);
begin
  inherited;
  if (chkFechaEntrega.Checked = True) then
    ctbFECHA_ENTREGA_FACTURA_LINEA.Visible := True
  else
    ctbFECHA_ENTREGA_FACTURA_LINEA.Visible := False;
end;

procedure TfrmMtoFacturas.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if Assigned(dsTablaG.DataSet) then
  begin
    if (dsTablaG.State = dsInsert) then
    begin
      txtNRO_FACTURA.Properties.ReadOnly := False;
      cbbSerieFactura.Properties.ReadOnly := False;
    end;
    if (dsTablaG.DataSet.State <> dsInsert) then
    begin
      txtNRO_FACTURA.Properties.ReadOnly := True;
      cbbSerieFactura.Properties.ReadOnly := True;
      cbbTARIFA_ARTICULOS_CLIENTES.Properties.ReadOnly := True;
      cbbCanalIVA.Properties.ReadOnly := True;
    end;
    if ((dsTablaG.DataSet.State = dsInsert) or
        (dsTablaG.DataSet.State = dsEdit)) then
    begin
      btnNuevaFactura.Enabled := False;
      btnRectificar.Enabled := False;
      btnImprimir.Enabled := False;
    end
    else
    begin
      btnNuevaFactura.Enabled := True;
      btnRectificar.Enabled := True;
      btnImprimir.Enabled := True;
    end;
  end;
end;

procedure TfrmMtoFacturas.dteFECHA_FACTURAKeyUp(Sender: TObject;
                                                     var Key: Word;
                                                     Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_DOWN) and (Shift = [ssShift])) then
    dteFECHA_FACTURA.DroppedDown := True;
end;

procedure TfrmMtoFacturas.dteFECHA_FACTURAPropertiesChange(Sender: TObject);
var
  e: TcxCustomEdit;
  NewValue : Variant;
begin
  inherited;
  if Assigned(dsTablaG.DataSet) then
  if ((dsTablaG.DataSet.State = dsInsert) or
      (dsTablaG.DataSet.State = dsEdit)
     ) then
  begin
    e := Sender as TcxCustomEdit;
    NewValue := e.EditingValue;
    if (NewValue <> null) then
    begin
      dmmFacturas.unqryTablaG.FindField('FECHA_FACTURA').AsDateTime :=
                                                      VarToDateTime(NewValue);
      CambiarIVA;
      dmmFacturas.CalcularRetencionesEmpresa;
      if (dsTablaG.DataSet.State = dsInsert) then
        ActualizarComboSeries;
    end;
  end;
end;

procedure TfrmMtoFacturas.btnIrAClienteClick(Sender: TObject);
begin
  inherited;
    with cxGrdDBTabPrin.DataController.DataSet do
  ShowMto(Self.Owner,
          'Clientes',
          FieldByName('CODIGO_CLIENTE_FACTURA').AsString);
end;

procedure TfrmMtoFacturas.btnIrAEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          cxGrdDBTabPrin.DataController.DataSet.FieldByName(
                                            'CODIGO_EMPRESA_FACTURA').AsString);
end;

procedure TfrmMtoFacturas.
                cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  formulario : TfrmMtoSearch;
begin
  inherited;
  if (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    formulario := TfrmMtoSearch.Create(Self.Owner);
    try
      formulario.Name := 'frmMtoArtFacSearch';
      dmmFacturas.unqryArtDataLinFac.ParamByName('TARIFA').AsString :=
        dmmFacturas.unqryTablaG.FindField(
                                      'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
      dmmFacturas.unqryArtDataLinFac.ParamByName('FECHA_FACTURA').AsDateTime :=
                    dmmFacturas.unqryTablaG.FindField('FECHA_FACTURA').AsDateTime;
      formulario.dsTablaG.DataSet := dmmFacturas.unqryArtDataLinFac;
      formulario.dsTablaG.DataSet.Open;
      formulario.ProcesarPerfiles;
      formulario.Caption := 'Búsqueda de Artículos en Lineas de Facturas';
      formulario.ShowModal;
     if (formulario.sFicha = 'S') then
          dmmFacturas.CopiarArticuloaLinea(dmmFacturas.unqryArtDataLinFac);
     formulario.dsTablaG.DataSet.Close;
    finally
     FreeAndNil(formulario);
    end;
  end;
end;

procedure TfrmMtoFacturas.
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
 var
    e: TcxCustomEdit;
    sCodigo:String;
    unqrySol:TUniQuery;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
    if (((State = dsInsert) or
         (State = dsEdit))
       ) then
    begin
      e := Sender as TcxCustomEdit;
      sCodigo := VarToStr(e.EditingValue);
      if ((sCodigo <> '') ) then
      begin
        dmmFacturas.unqryLinFac.FindField(
                                  'CODIGO_ARTICULO_FACTURA_LINEA').AsString :=
                                                     VarToStr(e.EditingValue);
        unqrySol := TUniQuery.Create(Self);
        unqrySol.Connection := inLibGlobalVar.oConn;
        unqrySol.SQL.Text := 'SELECT * ' +
                             '  FROM vi_art_busquedas ' +
                             ' WHERE CODIGO_TARIFA = :tarifa ' +
                             '   AND CODIGO_ARTICULO = :articulo ' +
                             '   AND FECHA_DESDE_TARIFA < :FECHA_FACTURA ' +
                             '   AND (FECHA_HASTA_TARIFA IS NULL ' +
                             '        OR FECHA_HASTA_TARIFA > :FECHA_FACTURA)';
        unqrySol.ParamByName('articulo').AsString := VarToStr(e.EditingValue);
        unqrySol.ParamByName('tarifa').AsString :=
          dmmFacturas.unqryTablaG.FindField(
                                    'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
        unqrySol.ParamByName('FECHA_FACTURA').AsDateTime :=
                  dmmFacturas.unqryTablaG.FindField('FECHA_FACTURA').AsDateTime;
        unqrySol.Open;
        if (unqrySol.RecordCount = 0) then
          Sleep(0) //si no existe artículo y tarifa, no hago nada
         else
           dmmFacturas.CopiarArticuloaLinea(unqrySol);
        unqrySol.Close;
        FreeAndNil(unqrySol);
      end;
    end;
  end;
end;

procedure TfrmMtoFacturas.sbGrabarClick(Sender: TObject);
begin
  with dmmFacturas do
  begin
    if ((unqryTablaG.State = dsInsert) or
        (unqryTablaG.State = dsEdit)) then
    begin
      unqryTablaG.Post;
      //unqryTablaG.Refresh;
    end;
    if ((dsLinFac.Dataset.State = dsInsert) or
        (dsLinFac.Dataset.State = dsEdit)) then
    begin
      dsLinFac.Dataset.Post;
    end;
    if ((dsRecibos.Dataset.State = dsInsert) or
        (dsRecibos.Dataset.State = dsEdit)) then
    begin
      dsRecibos.Dataset.Post;
      dsRecibos.Dataset.Refresh;
    end;
  end;
end;

procedure TfrmMtoFacturas.tvLineasFacturaKeyDown(Sender: TObject;
                                                 var Key: Word;
                                                 Shift: TShiftState);
begin
  inherited;
  if (Shift <> [ssCtrl]) then
    if ((Key = VK_RETURN) and
        (dmmFacturas.dsLinFac.DataSet.RecordCount = 0)
       ) then
      tvLineasFactura.DataController.Insert;
end;

procedure TfrmMtoFacturas.CambiarIVA;
begin
  if ( ((dsTablaG.DataSet.State = dsEdit) or
        (dsTablaG.DataSet.State = dsInsert) ) ) then
    dmmFacturas.AsignarIVA(
        dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FACTURA').AsString,
        dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
              tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
    if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      var  oLinFac:TLinFac;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG, true);
      oLinFac.PorDto := StrToCurrDef(VarToStr(e.EditingValue), 0);
      FreeAndNil(oLinFac);
      var factotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);
      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);
    end;
  end;
end;

procedure TfrmMtoFacturas.
            tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
    if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      var  oLinFac:TLinFac;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG, true);
      oLinFac.PrecioSal := StrToCurrDef(VarToStr(e.EditingValue), 0);
      FreeAndNil(oLinFac);
      var factotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);

      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);
    end;
  end;
end;

procedure TfrmMtoFacturas.tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
  if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      var  oLinFac:TLinFac;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG, true);
      oLinFac.Dto := StrToCurrDef(VarToStr(e.EditingValue), 0);
      FreeAndNil(oLinFac);
      var factotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);
      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);
    end;
  end;
end;

procedure TfrmMtoFacturas.
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
var
  e: TcxCustomEdit;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
  if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      var  oLinFac:TLinFac;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG, true);
      oLinFac.PreCiva := StrToCurrDef(VarToStr(e.EditingValue), 0);
      FreeAndNil(oLinFac);
      var factotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);
      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);

    end;
  end;
end;

procedure TfrmMtoFacturas.
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
var
  e: TcxCustomEdit;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
    if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      var  oLinFac:TLinFac;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG, true);
      oLinFac.PreSiva := StrToCurrDef(VarToStr(e.EditingValue), 0);
      FreeAndNil(oLinFac);
      var factotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);
      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);
    end;
  end;
end;

procedure TfrmMtoFacturas.
                    cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange(
                                                               Sender: TObject);
var
  e: TcxCustomEdit;
  facTotales : TFacturaTotales;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
    if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      var  oLinFac:TLinFac;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG, true);
      oLinFac.TipoIVA := VarToStr(e.EditingValue);
      FreeAndNil(oLinFac);
      facTotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);
      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);
    end;
  end;
end;

procedure TfrmMtoFacturas.
                      ctbCODIGO_FAMILIA_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  //rellenar nombrefamilia

end;

procedure TfrmMtoFacturas.
                    ctbCODIGO_PROVEEDOR_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  //rellenar razon social proveedor y precio de coste
end;

procedure TfrmMtoFacturas.
                  cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
var
  e : TcxCustomEdit;
  oLinFac:TLinFac;
  facTotales : TFacturaTotales;
begin
  inherited;
  with dmmFacturas.unqryLinFac do
  begin
    if ((State = dsInsert) or (State = dsEdit)) then
    begin
      e := Sender as TcxCustomEdit;
      oLinFac := TLinFac.Create(dmmFacturas.unqryLinFac,
                                dmmFacturas.unqryTablaG);
      oLinFac.Cant := StrToCurrDef(VarToStr(e.EditingValue), 1);
      FreeAndNil(oLinFac);
      facTotales := TFacturaTotales.Create(dmmFacturas.unqryTablaG,
                                           dmmFacturas.unqryLinFac);
      facTotales.ProcesarFacturaCompleta;//(oLinFac);
      FreeAndNil(facTotales);

    end;
  end;
end;

procedure TfrmMtoFacturas.AsignarControles;
begin
  with dmmFacturas do
  begin
    spID_CONSOLIDACION.DataBinding.DataSource := dsConsolidacion;
    txtESTADO.DataBinding.DataSource := dsConsolidacion;
    cxdbmRESPUESTA_COMPLETA.DataBinding.DataSource := dsConsolidacion;
    imgQRCODE_PNG.DataBinding.DataSource := dsConsolidacion;
    spQUEUE_ID.DataBinding.DataSource := dsConsolidacion;
    dteFECHA_PROCESAMIENTO.DataBinding.DataSource := dsConsolidacion;
    txtISSUER_IRS_ID.DataBinding.DataSource := dsConsolidacion;
    dteISSUED_TIME.DataBinding.DataSource := dsConsolidacion;
    txtCHAIN_NUMBER.DataBinding.DataSource := dsConsolidacion;
    txtCHAIN_HASH.DataBinding.DataSource := dsConsolidacion;
    cxdbmVERIFACTU_URL.DataBinding.DataSource := dsConsolidacion;
    cxdbmQRCODE_BASE64.DataBinding.DataSource := dsConsolidacion;
    cxdbmPETICION_COMPLETA1.DataBinding.DataSource := dsConsolidacion;
  end;
end;


procedure TfrmMtoFacturas.spnRetencionPropertiesEditValueChanged(
  Sender: TObject);
//var
//  e : TcxCustomEdit;
begin
  inherited;
//  with dsTablaG do
//  if ((State = dsInsert) or (State = dsEdit)) then
//  begin
//    e := Sender as TcxCustomEdit;
//
//  end;
end;

(*-AÑADIR CAMPO EN FACTURAS
-AÑADIR EL CAMPO EN FZA_FACTURAS
-AÑADIR EN LA VISTA VI_FACTURAS
-REVISAR EL DATASET EN UNIDATAFACTURAS
-REVISAR LOS PROCEDIMIENTOS ABONAR Y DUPLICAR
-REVISAR EL AFTERINSERT PARA PONER UN VALOR POR DEFECTO*)

initialization
  ForceReferenceToClass(TfrmMtoFacturas);
end.


