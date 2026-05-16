{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturas                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de facturas de venta.                                       }
{    Cabecera, lineas, impuestos y totales sobre fza_facturas.                 }
{******************************************************************************}
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
  cxSplitter, cxImage, cxDBEdit, cxPC, cxLabel,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxMemo, cxDBLookupComboBox,
  cxGridBandedTableView, cxGridDBBandedTableView, cxLocalization,
  cxGroupBox, DBCtrls, cxCurrencyEdit, Menus, cxButtons, cxButtonEdit,
  inlibDevExp, cxLookupEdit, cxDBLookupEdit, Uni, cxSpinEdit, cxCalc,
  cxDataControllerConditionalFormattingRulesManagerDialog, dxBevel,
  cxDBNavigator, dxNumericWheelPicker, dxDateRanges, cxDataUtils, cxVariants,
  cxDBLabel, dxGDIPlusClasses, dxSkinsForm, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, System.Actions, Vcl.ActnList,
  Vcl.ActnMan, Vcl.StdStyleActnCtrls, Vcl.AppEvnts,
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
    ctbCODIGO_UNIDAD_FACTURA_LINEA: TcxGridDBColumn;
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
    tsMovimientosFac: TcxTabSheet;
    cxGrdMovimientosFac: TcxGrid;
    tvMovimientosFac: TcxGridDBTableView;
    cxGrdMovimientosFacLevel: TcxGridLevel;
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
    cxLabel1: TcxLabel;
    cxDBTextEdit1: TcxDBTextEdit;
    cxLabel2: TcxLabel;
    cxDBTextEdit2: TcxDBTextEdit;
    cxDBTextEdit3: TcxDBTextEdit;
    cxLabel3: TcxLabel;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxDBCheckBox;
    chkESVENTA_ACTIVO_FIJO_FACTURA: TcxDBCheckBox;
    cxButton1: TcxButton;
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
    procedure cbbSerieFacturaPropertiesChange(Sender: TObject);
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
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup(
      Sender: TObject);
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
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
    procedure cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(Sender: TObject);
    procedure ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
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
  public
    dmmFacturas : TdmFacturas;
  end;

//var
//  //frmMtoFacturas: TfrmMtoFacturas;
//  dmmFacturas : TdmFacturas;

implementation

uses
  inLibWin,
  inLibMsg,
  inLibGenBusq,
  inLibShowMto,
  inLibFacturas,
  inLibDefaultValues,
  inLibArticulosValidador,
  inLibArticulosResolver,
  inMtoGenSearch,
  inMtoModalFacRec,
  inMtoModalImpRecFac,
  inMtoModalImpFac,
  inMtoPrincipal,
  inLibUser,
  inMtoArticulos,
  inMtoEmpresas,
  inMtoClientes,
  inLibGlobalVar,
  inLibtb;

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
      dsTablaG.Dataset.FindField('CODIGO_EMP_FAC').AsString :=
                                                     VarToStr(e.EditingValue);
      unqrySol := TUniQuery.Create(Self);
      unqrySol.Connection := oConn;
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM fza_empresas ' +
                           ' WHERE CODIGO_EMP_EMP = :empresa';
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
end;

procedure TfrmMtoFacturas.ResetForm;
begin
  inherited;
  if Assigned(dmmFacturas) and Assigned(pcCab) and Assigned(pcDetail) then
  begin
    pcCab.ActivePage := tsCabecera;
    pcDetail.ActivePage := tsLineasFactura;
  end;
end;

procedure TfrmMtoFacturas.btnUpdateClienteClick(Sender: TObject);
begin
  inherited;
  with dmmFacturas.unqryTablaG do
  begin
    if (FieldByName('CODIGO_CLI_FAC').AsString = '0') then
      dmmFacturas.GetCodigoAutoCliente;
    dmmFacturas.CrearCliente;
    ShowMessageFmt(SCliToTbl,
                   [FieldByName('CODIGO_CLI_FAC').AsString]);
  end;
end;

procedure TfrmMtoFacturas.btnUpdateEmpresaClick(Sender: TObject);
begin
  inherited;
  with dmmFacturas.unqryTablaG do
  begin
    if (FieldByName('CODIGO_EMP_FAC').AsString = '0') then
      dmmFacturas.GetCodigoAutoEmpresa;
    dmmFacturas.CrearEmpresa;
    ShowMessageFmt(SEmpToTbl,
              [FieldByName('CODIGO_EMP_FAC').AsString]);
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
      dsTablaG.DataSet.FindField('CODIGO_EMP_FAC').AsString :=
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
    form.dmFac := dmmFacturas;
    form.edtNroFac.Text := dsTablaG.DataSet.findField('NUMERO_FAC').AsString;
    form.edtSerie.Text := dsTablaG.DataSet.findField('SERIE_FAC').AsString;
    form.edtPlazoRecFac.Text :=
                dmmFacturas.unqryRecibos.FindField('NUMERO_PLAZO_REC').AsString;
    form.ShowModal;
  finally
    FreeAndNil(form);
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
    if ((pcDetail.ActivePage = tsLineasFactura)) then
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
    cbbSerieFactura.Properties.ListFieldNames := 'SERIE_CON';
    cbbSerieFactura.Properties.ListSource := dmmFacturas.dsSeriesEditCombo;
    cbbSerieFactura.Refresh;
    dmmFacturas.unqrySeriesEditCombo.First;
    dsTablaG.DataSet.FindField(fseriefac).AsString :=
          dmmFacturas.unqrySeriesEditCombo.FindField('SERIE_CON').AsString;
  end
  else
  begin
    cbbSerieFactura.properties.listsource := dmmFacturas.dsSeries;
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
begin
  if (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Clientes en Facturas',
                                       dmmFacturas.unqryCliDataFac,
                                       'frmMtoCliFacSearch') then
     begin
       dmmFacturas.CopiarClienteaFactura(dmmFacturas.unqryClidataFac);
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
begin
  if (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Empresas en Facturas',
                                       dmmFacturas.unqryEmpDataFac,
                                       'frmMtoEmpFacSearch') then
      dmmFacturas.CopiarEmpresaaFactura(dmmFacturas.unqryEmpDataFac);
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
  form: TfrmPrintFac;
begin
  inherited;
  form := TfrmPrintFac.Create(Application);  // Owner = Application
  try
    form.edtNroFac.Text := dsTablaG.DataSet.findField(fnrofac).AsString;
    form.edtSerie.Text := dsTablaG.DataSet.findField(fseriefac).AsString;
    form.dmFac := dmmFacturas;
    form.ShowModal;
  finally
    FreeAndNil(form);
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

procedure TfrmMtoFacturas.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup(
  Sender: TObject);
var
  Combo    : TcxComboBox;
  Resolver : TArticulosResolver;
  Skus     : TArray<TArticuloSkuItem>;
  Item     : TArticuloSkuItem;
  CodArt   : string;
begin
  inherited;
  if not (Sender is TcxComboBox) then Exit;
  Combo := Sender as TcxComboBox;

  // El combo se rellena en cada apertura con los SKUs del artículo de la
  // fila activa. dropDownListStyle=lsEditList permite también escribir un
  // valor que no esté en la lista (ej. SKU escaneado o tecleado a mano).
  CodArt := dmmFacturas.unqryLinFac.FindField('CODIGO_ART_FACLIN').AsString;
  Combo.Properties.Items.BeginUpdate;
  try
    Combo.Properties.Items.Clear;
    if CodArt = '' then Exit;
    Resolver := TArticulosResolver.Create(inLibGlobalVar.oConn);
    try
      Skus := Resolver.ListarSkus(CodArt);
      for Item in Skus do
        Combo.Properties.Items.Add(Item.CodigoSku);
    finally
      FreeAndNil(Resolver);
    end;
  finally
    Combo.Properties.Items.EndUpdate;
  end;
end;

procedure TfrmMtoFacturas.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
var
  e          : TcxCustomEdit;
  Lin        : TDataSet;
  Resolver   : TArticulosResolver;
  Datos      : TArticuloDatos;
  Precio     : TArticuloPrecio;
  CodTarifa  : string;
  FechaFac   : TDateTime;
  CodArt     : string;
  CodSku     : string;
  iPorcen    : Integer;
  fPorcen    : Currency;
  sTipoIVA   : string;
begin
  inherited;
  Lin := dmmFacturas.unqryLinFac;
  if not (Lin.State in [dsInsert, dsEdit]) then Exit;

  e      := Sender as TcxCustomEdit;
  CodSku := Trim(VarToStr(e.EditingValue));
  CodArt := Lin.FindField('CODIGO_ART_FACLIN').AsString;
  if (CodSku = '') or (CodArt = '') then Exit;

  CodTarifa := dmmFacturas.unqryTablaG.FindField(
                                       'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
  FechaFac  := dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime;

  Resolver := TArticulosResolver.Create(inLibGlobalVar.oConn);
  try
    Datos  := Resolver.ResolverDatos(CodArt, CodSku, CodTarifa, FechaFac);
    Precio := Datos.PrecioPedido;
    // Si el SKU tecleado a mano no pertenece al artículo, ResolverDatos lo
    // ignora y deja CodigoSku vacío. En ese caso no tocamos el precio.
    if Datos.CodigoSku = '' then Exit;

    if Assigned(Lin.FindField('CODIGO_UNIDAD_FACLIN')) then
      Lin.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := Datos.CodigoSku;
    if Assigned(Lin.FindField('DESCRIPCION_VARIACION_FACLIN')) then
      Lin.FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString :=
        Datos.DescripcionSku;

    Lin.FindField('PRECIO_SALIDA_FACLIN').AsFloat   := Precio.PrecioSalida;
    Lin.FindField('PORCENTAJE_DTO_FACLIN').AsFloat  := Precio.PorcentajeDto;
    Lin.FindField('PRECIO_DTO_FACLIN').AsFloat      := Precio.PrecioDto;
    Lin.FindField('ESIMP_INCL_TARIFA_FACLIN').AsString :=
                                          IfThen(Precio.EsImpIncl, 'S', 'N');

    sTipoIVA := Datos.TipoIVA;
    iPorcen  := 0;
    case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
      0: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAN_FAC').AsInteger;
      1: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAR_FAC').AsInteger;
      2: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAS_FAC').AsInteger;
      3: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAE_FAC').AsInteger;
    end;
    fPorcen := iPorcen / 100;
    if Precio.EsImpIncl then
    begin
      Lin.FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
        Precio.PrecioFinal;
      if (1 + fPorcen) <> 0 then
        Lin.FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
                                                  Precio.PrecioFinal / (
                                                    1 + fPorcen);
    end
    else
    begin
      Lin.FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
        Precio.PrecioFinal;
      Lin.FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
                                                  Precio.PrecioFinal * (
                                                    1 + fPorcen);
    end;
  finally
    FreeAndNil(Resolver);
  end;
end;

procedure TfrmMtoFacturas.sbRectificarClick(Sender: TObject);
var
  form:TfrmGenFacRec;
begin
  inherited;
   form := TfrmGenFacRec.Create(Self);
   try
     form.dmFac := dmmFacturas;
     form.ShowModal;
   finally
     FreeAndNil(form);
   end;
end;

procedure TfrmMtoFacturas.CambiarEstadoRecibo(sEstado: string);
begin
  with dmmFacturas.unqryRecibos do
  begin
    if not((State = dsEdit) or (State = dsInsert)) then
      Edit;
    FieldByName('ESTADO_RECIBO_REC').AsString := sEstado;
    if sEstado = 'Pagado' then
       FieldByNAme('FECHA_PAGO_RECIBO_REC').AsDateTime := Trunc(Now)
    else
      if ((sEstado = 'Emitido') or (sEstado='Devuelto')) then
        FieldByNAme('FECHA_PAGO_RECIBO_REC').AsVariant := null;
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
      dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString :=
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

procedure TfrmMtoFacturas.cbbSerieFacturaPropertiesChange(Sender: TObject);
var
  sSubtipo: string;
begin
  inherited;
  if ((dsTablaG.DataSet.State <> dsEdit) and
      (dsTablaG.DataSet.State <> dsInsert)) then
    Exit;
  sSubtipo := dmmFacturas.GetSubtipoSerieEmpresa(
                dsTablaG.DataSet.FindField(fseriefac).AsString,
                dsTablaG.DataSet.FindField(fcodemp).AsString,
                dsTablaG.DataSet.FindField(ffechfac).AsDateTime);
  if (sSubtipo = '') then
    sSubtipo := 'NORMAL';
  dsTablaG.DataSet.FindField(ftipofac).AsString := sSubtipo;
end;

procedure TfrmMtoFacturas.cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sTarifa: string;
begin
  inherited;
  if ((dsTablaG.DataSet.State = dsInsert)) then
  begin
    e := Sender as TcxCustomEdit;
    sTarifa := VarToStr(e.EditingValue);
    // Verificar que hay una tarifa seleccionada
    if (sTarifa <> '') then
    begin
      // Localizar la tarifa en el dataset
      if dmmFacturas.unqryTarifas.Locate('CODIGO_TAR_ARTTAR', sTarifa, []) then
      begin
        dsTablaG.DataSet.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
          dmmFacturas.unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString;
        // Opcional: Mostrar mensaje de confirmación
        // ShowMessage('IVA incluido: ' +
        //   IfThen(dmmFacturas.unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString = 'S',
        //          'SÍ', 'NO'));
      end
      else
      begin
        ShowMessage('No se encontró la tarifa seleccionada');
      end;
    end;
  end;
end;

procedure TfrmMtoFacturas.CheckConsolidacion;
begin
(*  if Assigned(dmmFacturas) and
     Assigned(dsTablaG.Dataset) and
     Assigned(dmmFacturas.unqryTablaG) and
     Assigned(self.tdmDataModule) then
       if dsTablaG.Dataset.FieldByName(fescon).AsString ='S' then
       begin
         dmmFacturas.unqryTablaG.ReadOnly := True;
         dmmFacturas.unqryLinFac.ReadOnly := True;
         if Assigned(tvLineasFactura) then
         begin
           tvLineasFactura.optionsData.Editing := False;
           tvLineasFactura.optionsData.Deleting := False;
           tvLineasFactura.optionsData.Inserting := False;
         end;
         btnGenerarRecibos.Enabled := False;
         btnConsolidar.Enabled := False;
    //     tvRecibos.optionsData.Editing := False;
    //     tvRecibos.optionsData.Deleting := False;
    //     tvRecibos.optionsData.Inserting := False;
       end
        else
        begin
          dmmFacturas.unqryTablaG.ReadOnly := False;
          dmmFacturas.unqryLinFac.ReadOnly := False;
          if Assigned(tvLineasFactura) then
          begin
            tvLineasFactura.optionsData.Editing := True;
            tvLineasFactura.optionsData.Deleting := True;
            tvLineasFactura.optionsData.Inserting := True;
          end;
          btnGenerarRecibos.Enabled := True;
          btnConsolidar.Enabled := True;
    //      tvRecibos.optionsData.Editing := True;
    //      tvRecibos.optionsData.Deleting := True;
    //      tvRecibos.optionsData.Inserting := True;

        end;  *)
end;

procedure TfrmMtoFacturas.CrearTablaPrincipal;
begin
  inherited;
  dmmFacturas := (tdmDataModule as TdmFacturas);
  if not Assigned(dmmFacturas) then
    dmmFacturas := TdmFacturas.Create(Self);
  cbbSerieFactura.Properties.ListSource := dmmFacturas.dsSeries;
  cbbCanalIVA.Properties.ListSource := dmmFacturas.dsIvas;
  cbbFORMAPAGO.Properties.ListSource := dmmFacturas.dsFormasPago;
  tvLineasFactura.DataController.DataSource := dmmFacturas.dsLinFac;
  cbbTARIFA_ARTICULOS_CLIENTES.Properties.ListSource := dmmFacturas.dsTarifas;
  tvRecibos.DataController.DataSource := dmmFacturas.dsRecibos;
  tvMovimientosFac.DataController.DataSource := dmmFacturas.dsMovimientosFac;
  cbbPaisesEmp.Properties.ListSource := dmmFacturas.dsPaisesEmp;
  cbbPaisesCli.Properties.ListSource := dmmFacturas.dsPaisesCli;
  //tvIVA.DataController.DataSource := dsTablaG;
  (ctbTIPOIVA_ARTICULO_FACTURA_LINEA.Properties as
             TcxLookupComboBoxProperties).ListSource := dmmFacturas.dsIvasTipos;
  Self.pkFieldName := 'NUMERO_FAC; SERIE_FAC';
  AsignarControles;
  dmmFacturas.OpenTables;
  CheckConsolidacion;
end;

procedure TfrmMtoFacturas.chkConsolidadaPropertiesChange(Sender: TObject);
begin
  inherited;
//  if Assigned(dmmFacturas) then
//    if (Assigned(dmmFacturas.unqryTablaG)) then
//      if (Assigned(dsTablaG.DataSet)) then
//        CheckConsolidacion;
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
    //                      'ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString := 'S';
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
      dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime :=
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
          FieldByName('CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoFacturas.btnIrAEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          cxGrdDBTabPrin.DataController.DataSet.FieldByName(
                                            'CODIGO_EMP_FAC').AsString);
end;

procedure TfrmMtoFacturas.
                cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  inherited;
  if (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    dmmFacturas.unqryArtDataLinFac.ParamByName('TARIFA').AsString :=
                                              dmmFacturas.unqryTablaG.FindField(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    dmmFacturas.unqryArtDataLinFac.ParamByName('FECHA_FAC').AsDateTime :=
                  dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime;
    //      TLibDefaults.Configurar(formulario, esArticulo, True);
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos en Lineas de ' +
                                                                     'Facturas',
                                       dmmFacturas.unqryArtDataLinFac,
                                       'frmMtoArtFacSearch') then
      dmmFacturas.CopiarArticuloaLinea(dmmFacturas.unqryArtDataLinFac);
  end;
end;

procedure TfrmMtoFacturas.
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
var
  e          : TcxCustomEdit;
  sInput     : string;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
  Datos      : TArticuloDatos;
  Precio     : TArticuloPrecio;
  Lin        : TDataSet;
  CodTarifa  : string;
  FechaFac   : TDateTime;
  iPorcen    : Integer;
  fPorcen    : Currency;
  sTipoIVA   : string;
begin
  inherited;
  Lin := dmmFacturas.unqryLinFac;
  if not (Lin.State in [dsInsert, dsEdit]) then Exit;

  e      := Sender as TcxCustomEdit;
  sInput := Trim(VarToStr(e.EditingValue));
  if sInput = '' then Exit;

  CodTarifa := dmmFacturas.unqryTablaG.FindField(
                                       'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
  FechaFac  := dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime;

  Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
  Resolver  := TArticulosResolver.Create(inLibGlobalVar.oConn);
  try
    Resolucion := Validador.Resolver(sInput);
    if not Resolucion.Encontrado then Exit;

    // Datos básicos del artículo + SKU (si lo hay) + precio en la tarifa.
    Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo,
                                    Resolucion.CodigoSku,
                                    CodTarifa, FechaFac);
    if not Datos.Encontrado then Exit;

    // Si el padre tiene varios SKUs y aún no hay SKU, ResolverDatos no calcula
    // precio. Pedimos el del padre para arrastrar IVA y % DTO (mismo patrón
    // que en caja); PRECIO_SALIDA queda a 0 hasta que se elija el SKU.
    if Datos.RequiereSku then
      Precio := Resolver.ResolverPrecio(Resolucion.CodigoArticulo, '',
                                        CodTarifa, FechaFac)
    else
      Precio := Datos.PrecioPedido;

    Lin.FindField('CODIGO_ART_FACLIN').AsString := Datos.CodigoArticulo;
    // CODIGO_UNIDAD_FACLIN y DESCRIPCION_VARIACION_FACLIN ya existen en la
    // tabla base, pero la vista vi_facturas_lineas sólo los expone tras la
    // migración 2026-05-10. Asignación defensiva por si aún no se aplicó.
    if Assigned(Lin.FindField('CODIGO_UNIDAD_FACLIN')) then
      Lin.FieldByName('CODIGO_UNIDAD_FACLIN').AsString   := Datos.CodigoSku;
    if Assigned(Lin.FindField('DESCRIPCION_VARIACION_FACLIN')) then
      Lin.FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString :=
        Datos.DescripcionSku;
    Lin.FindField('DESCRIPCION_ARTICULO_FACLIN').AsString :=
      Datos.DescripcionArticulo;
    Lin.FindField('TIPO_ARTICULO_FACLIN').AsString       := Datos.TipoArticulo;
    Lin.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
      Datos.TipoCantidad;
    Lin.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString   := Datos.TipoIVA;
    Lin.FindField('CODIGO_FAM_FACLIN').AsString          := Datos.CodigoFamilia;
    Lin.FindField('NOMBRE_FAM_FACLIN').AsString := Datos.DescripcionFamilia;
    Lin.FindField('CODIGO_TAR_FACLIN').AsString          := CodTarifa;
    Lin.FindField('ESIMP_INCL_TARIFA_FACLIN').AsString   :=
                                          IfThen(Precio.EsImpIncl, 'S', 'N');
    Lin.FindField('PORCENTAJE_DTO_FACLIN').AsFloat := Precio.PorcentajeDto;
    Lin.FindField('PRECIO_DTO_FACLIN').AsFloat           := Precio.PrecioDto;

    if Datos.UltimoCoste.Encontrado then
    begin
      Lin.FindField('ESPROVEEDORPRINCIPAL_FACLIN').AsString :=
                          IfThen(Datos.UltimoCoste.EsProveedorPrincipal,
                                 'S',
                                 'N');
      Lin.FindField('CODIGO_PRV_FACLIN').AsString    :=
        Datos.UltimoCoste.CodigoProveedor;
      Lin.FindField('RAZON_SOCIAL_PROVEEDOR_FACLIN').AsString :=
                                              Datos.UltimoCoste.RazonSocialProveedor;
      Lin.FindField('PRECIO_ULT_COMPRA_FACLIN').AsFloat :=
                                              Datos.UltimoCoste.PrecioUltCompra;
    end;

    // Si el padre tiene varios SKUs aún sin elegir, dejamos PRECIO_SALIDA y
    // PRECIO_VENTA_*_FACLIN a 0 hasta que el usuario complete el SKU. Movemos
    // el foco a la columna SKU y abrimos su dropdown automáticamente.
    if Datos.RequiereSku then
    begin
      Lin.FindField('PRECIO_SALIDA_FACLIN').AsFloat := 0;
      Lin.FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat := 0;
      Lin.FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat := 0;
      // Diferimos para que termine el ciclo de edición actual antes de
      // saltar a la celda contigua.
      TThread.ForceQueue(nil,
        procedure
        var Edit: TcxCustomEdit;
        begin
          tvLineasFactura.Controller.FocusedColumn :=
            ctbCODIGO_UNIDAD_FACTURA_LINEA;
          tvLineasFactura.Controller.EditingController.ShowEdit;
          Edit := tvLineasFactura.Controller.EditingController.Edit;
          if Edit is TcxComboBox then
            (Edit as TcxComboBox).DroppedDown := True;
        end);
      Exit;
    end;

    Lin.FindField('PRECIO_SALIDA_FACLIN').AsFloat := Precio.PrecioSalida;

    // Reproducimos la conversión IVA inc./exc. que hacía CopiarArticuloaLinea
    sTipoIVA := Datos.TipoIVA;
    iPorcen  := 0;
    case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
      0: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAN_FAC').AsInteger;
      1: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAR_FAC').AsInteger;
      2: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAS_FAC').AsInteger;
      3: iPorcen :=
        dmmFacturas.unqryTablaG.FindField('PORCENTAJE_IVAE_FAC').AsInteger;
    end;
    fPorcen := iPorcen / 100;
    if Precio.EsImpIncl then
    begin
      Lin.FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
        Precio.PrecioFinal;
      if (1 + fPorcen) <> 0 then
        Lin.FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
                                                  Precio.PrecioFinal / (
                                                    1 + fPorcen);
    end
    else
    begin
      Lin.FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
        Precio.PrecioFinal;
      Lin.FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
                                                  Precio.PrecioFinal * (
                                                    1 + fPorcen);
    end;
  finally
    FreeAndNil(Validador);
    FreeAndNil(Resolver);
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
  // Antes de insertar nueva línea, asegurar que la cabecera está grabada
  if (Key = VK_RETURN) and (Shift <> [ssCtrl]) and
     (dmmFacturas.dsLinFac.DataSet.RecordCount = 0) then
  begin
    if dmmFacturas.unqryTablaG.State in [dsInsert, dsEdit] then
    begin
      try
        dmmFacturas.unqryTablaG.Post;
      except
        on E: Exception do
        begin
          ShowMessage('Debe completar los datos de la factura: ' + E.Message);
          Exit;
        end;
      end;
    end;
    tvLineasFactura.DataController.Insert;
  end;
end;

procedure TfrmMtoFacturas.CambiarIVA;
begin
  if (dsTablaG.DataSet.State = dsInsert) then
    dmmFacturas.AsignarIVA(
        dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString,
        dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
              tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
            tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
//var
//  e: TcxCustomEdit;
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
                    cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange(
                                                               Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
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

procedure TfrmMtoFacturas.ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturas.
                  cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  GridRecalc(Sender,
             tvLineasFactura,
             dmmFacturas.unqryLinFac,
             dmmFacturas.unqryTablaG);
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


