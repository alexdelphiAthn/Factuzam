{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasBase                                             }
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
unit inMtoFacturasBase;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoGen,  cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,  System.StrUtils,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer, System.UITypes,
  System.Generics.Collections,
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
  TfrmMtoFacturasBase = class(TfrmMtoGen)
    pnlVerifactu: TPanel;
    cxgrdbclmnGrdDBTabPrinESTADO_VERIFACTU: TcxGridDBColumn;
    pcDetail: TcxPageControl;
    tsLineasFactura: TcxTabSheet;
    tsTotales: TcxTabSheet;
    scrTotales: TScrollBox;
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
    lblTipoOperVerifactu: TcxLabel;
    cbbTipoOperVerifactu: TcxDBLookupComboBox;
    lblTipoOperVerifactuAyuda: TcxLabel;
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
    lblExtra6: TcxLabel;
    lblExtra13: TcxLabel;
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
    actMovimiento: TAction;
    lbldbCODIGO_CLIENTE_FACTURA: TcxDBLabel;
    lbldbCODIGO_CLIENTE: TcxDBLabel;
    chkImpIncl: TcxDBCheckBox;
    ctbPRECIOSALIDA_FACTURA_LINEA: TcxGridDBColumn;
    ctbPORCEN_DTO_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIO_DTO_FACTURA_LINEA: TcxGridDBColumn;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasFactura: TcxLabel;
    grpDesgloseImpuestos: TGroupBox;
    lblTotRE: TcxLabel;
    PorRE: TcxLabel;
    lblTotIVA: TcxLabel;
    lblPorIVA: TcxLabel;
    lblBaseNeta: TcxLabel;
    lblNormal: TcxLabel;
    lblReducido: TcxLabel;
    lblSReducido: TcxLabel;
    lblExento: TcxLabel;
    curTOTAL_BASEI_IVAN_FAC: TcxDBCurrencyEdit;
    curTOTAL_BASEI_IVAR_FAC: TcxDBCurrencyEdit;
    curTOTAL_BASEI_IVAS_FAC: TcxDBCurrencyEdit;
    curTOTAL_BASEI_IVAE_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAN_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAR_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAS_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAE_FAC: TcxDBCurrencyEdit;
    curTOTAL_REN_FAC: TcxDBCurrencyEdit;
    curTOTAL_RER_FAC: TcxDBCurrencyEdit;
    curTOTAL_RES_FAC: TcxDBCurrencyEdit;
    curTOTAL_REE_FAC: TcxDBCurrencyEdit;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;
    spnPORCENTAJE_IVAN_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_IVAR_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_IVAS_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_IVAE_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_RER_FAC: TcxDBSpinEdit;
    shpSeparador6: TShape;
    spnPORCENTAJE_REN_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_RES_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_REE_FAC: TcxDBSpinEdit;
    ctbTOTAL_FACTURASIVA_LINEA: TcxGridDBColumn;
    ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA: TcxGridDBColumn;
    ctbCODIGO_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn;
    ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIO_ULT_COMPRA_FACTURA_LINEA: TcxGridDBColumn;
    jvcalcAux: TJvCalculator;
    btnCalculator: TcxButton;
    txtNOMBRE_PAIS_CLIENTE_FACTURA: TcxDBTextEdit;
    txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit;
    cbbPaisesCli: TcxDBLookupComboBox;
    cbbPaisesEmp: TcxDBLookupComboBox;
    chkConsolidada: TcxDBCheckBox;
    chkMueveStock: TcxDBCheckBox;
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
    scrlbxVerifactu: TScrollBox;
    lblPETICION_COMPLETA: TLabel;
    lblRESPUESTA_COMPLETA: TLabel;
    lblQRCODE_BASE64: TLabel;
    lblVERIFACTU_URL: TLabel;
    lblCHAIN_HASH: TLabel;
    lblCHAIN_NUMBER: TLabel;
    lblISSUED_TIME: TLabel;
    lblISSUER_IRS_ID: TLabel;
    lblQUEUE_ID: TLabel;
    lblREQUEST_ID: TLabel;
    lbl: TLabel;
    lblFECHA_PROCESAMIENTO: TLabel;
    lblESTADO: TLabel;
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
    cxdbmPETICION_COMPLETA_FACCON: TcxDBMemo;
    dteFECHA_PROCESAMIENTO: TcxDBDateEdit;
    txtESTADO: TcxDBTextEdit;
    cxgrdLogVerifactu: TcxGrid;
    tvLogVerifactu: TcxGridDBTableView;
    cxgrdlvlLogVerifactu: TcxGridLevel;
    tvLogVerifactuTIMESTAMP_LOG: TcxGridDBColumn;
    tvLogVerifactuDESCRIPCION_LOG: TcxGridDBColumn;
    tvLogVerifactuDATOS_ADICIONALES_LOG: TcxGridDBColumn;
    tvLogVerifactuNRO_FACTURA_LOG: TcxGridDBColumn;
    tvLogVerifactuSERIE_FACTURA_LOG: TcxGridDBColumn;
    lblTipoFactura: TcxLabel;
    txtTIPO_FAC: TcxDBTextEdit;
    lblVendedorFactura: TcxLabel;
    txtCODIGO_CAJERO_FAC: TcxDBTextEdit;
    txtFASE_FAC: TcxDBTextEdit;
    lblFaseFactura: TcxLabel;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxDBCheckBox;
    chkESVENTA_ACTIVO_FIJO_FACTURA: TcxDBCheckBox;
    btnGenerarRecibos2: TcxButton;
    btnVerifactuAnular: TcxButton;
    btnVerifactuFacturar: TcxButton;
    btnVolverBorrador: TcxButton;
    procedure sbGrabarClick(Sender: TObject);
    procedure btnUpdateClienteClick(Sender: TObject);
    procedure sbNuevaFacturaClick(Sender: TObject);
//    procedure cxgrdbclmntv1CODIGO_ARTICULO_LINEAPropertiesEditValueChanged(
//      Sender: TObject);
    procedure btnCODIGO_CLIENTEPropertiesEditValueChanged(Sender: TObject);
    procedure tvLineasFacturaKeyDown(Sender: TObject;
                                     var Key: Word;
                                     Shift: TShiftState);
    procedure tvLineasFacturaInitEdit(Sender: TcxCustomGridTableView;
                                      AItem: TcxCustomGridTableItem;
                                      AEdit: TcxCustomEdit);
    procedure tvLineasFacturaEditKeyDown(Sender: TcxCustomGridTableView;
                                      AItem: TcxCustomGridTableItem;
                                      AEdit: TcxCustomEdit;
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
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesCloseUp(
      Sender: TObject);
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure sbRectificarClick(Sender: TObject);
    procedure sbImprimirClick(Sender: TObject);
    procedure btnImprimirReciboClick(Sender: TObject);
    procedure chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURAPropertiesChange(
      Sender: TObject);
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesChange(Sender: TObject);
    procedure dteFECHA_FACTURAPropertiesChange(Sender: TObject);
    procedure btnCODIGO_CLIENTEPropertiesChange(Sender: TObject);
    procedure cbbCanalIVAPropertiesChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
    procedure btnConsolidarClick(Sender: TObject);
    procedure btnVolverBorradorClick(Sender: TObject);
    procedure chkFechaEntregaPropertiesChange(Sender: TObject);
    procedure chkDescripcion_ampliadaPropertiesChange(Sender: TObject);
    procedure chkCrearArticulosPropertiesChange(Sender: TObject);
    procedure btnExportarLineasClick(Sender: TObject);
    procedure btnVerifactuAnularClick(Sender: TObject);
    procedure btnVerifactuFacturarClick(Sender: TObject);
    procedure btnExportarRecibosClick(Sender: TObject);
    procedure actArticuloExecute(Sender: TObject);
    procedure actMovimientoExecute(Sender: TObject);
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
    procedure cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(Sender: TObject);
    procedure ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
//    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    destructor Destroy; override;
    procedure AplicarEtiquetas; override;
    procedure ActualizarComboSeries;
    procedure CambiarEstadoRecibo(sEstado:String);
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén/caja del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
    procedure CambiarIVA;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
    function  ContarHijosActivos: Integer; override;
    function  DescripcionHijos: string; override;
    // Nombre de la vista SQL a consultar en el listado principal.
    // La filtra el propio motor de BD (vi_facturas_normales /
    // vi_facturas_simplificadas), no toca al codigo.
    function NombreVistaListado: string; virtual;
    // TIPO_FAC que el descendiente quiere por defecto en los inserts
    function TipoFacturaFiltro: string; virtual;
    // Si el descendiente precarga la lista con filtros propios (p.ej.
    // simplificadas por año/almacen), devuelve False para que
    // CrearTablaPrincipal NO abra la vista completa; el descendiente la
    // abre ya filtrada y con barra de progreso en ResetForm.
    function AbrirListadoAlCrear: Boolean; virtual;
    //procedure CalcularLinea;
  private
    // Cache CODIGO_ART_ART -> mostrar SKU en la linea. Evita reconsultar
    // fza_articulos en cada repintado del grid. Se rellena perezosamente
    // (y desde el resolver al teclear el articulo) y se vacia al recrear
    // la tabla principal.
    FArtMostrarSku: TDictionary<string, Boolean>;
    FEnterSkuActivo: Boolean;
    FEnterSkuAnterior: Boolean;
    FConsolidandoSku: Boolean;
    FReaplicandoVisibilidadDetalle: Boolean;
    FActualizandoLabelPrendas: Boolean;
    function  EsVentaMayorNormal: Boolean;
    function  TextoCobroPlural: string;
    function  PrefijoExportCobros: string;
    procedure AplicarTerminologiaCobros;
    procedure AplicarOrigenCobros;
    procedure ConfigurarColumnasRecibos;
    procedure ConfigurarColumnasEfectosVenta;
    // Modo creacion de articulos de la cabecera (ESCREARARTICULOS_FAC='S').
    function  ModoCreacionActivo: Boolean;
    // Visibilidad de las columnas de creacion de articulos del detalle.
    // Solo se ven cuando la cabecera esta en modo "Crear/Act Articulo";
    // ocultas en caso contrario.
    procedure AplicarVisibilidadColumnasCreacion(bCrear: Boolean);
    procedure SincronizarColumnasCreacion;
    // Regla de negocio del SKU en lineas: solo se muestra/edita cuando el
    // articulo tiene variacion (tallas/colores) o es nuevo (aun no existe
    // en la BBDD). Para articulos normales el SKU se autoresuelve y estorba.
    function  MostrarSkuArticulo(const ACodArt: string): Boolean;
    procedure ActivarSkuArticuloLinea(const ACodArt: string;
                                      bEnfocar: Boolean);
    procedure ConsolidarSkuLinea(Sender: TObject);
    procedure DesactivarEnterSku(Sender: TObject);
    procedure RestaurarEnterSku(Sender: TObject);
    procedure SalirEditorSku(Sender: TObject);
    // La columna SKU completa se oculta si ninguna linea la necesita y no
    // hay modo creacion; dentro de una columna visible, las celdas que no
    // proceden se vacian (OnGetDataText) y se bloquean (OnEditing).
    procedure SincronizarColumnaSku;
    // Reimpone TODA la visibilidad de columnas del detalle que controlamos
    // por logica de negocio. Necesario porque AplicarEtiquetas ->
    // PonerAnchosTitulos (inLibDevExp) repone la visibilidad desde el perfil
    // (por defecto visible) y pisa lo que fijamos en CrearTablaPrincipal.
    procedure ReaplicarVisibilidadDetalle;
    // Pinta lblTotalPrendasFactura con el total de prendas (suma de
    // CANTIDAD_FACLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure dsLinFacDataChange(Sender: TObject; Field: TField);
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAGetDataText(
      Sender: TcxCustomGridTableItem; ARecordIndex: Integer; var AText: string);
    procedure tvLineasFacturaEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    // Bloqueo por fase fiscal: una factura solo es editable (cabecera,
    // líneas y borrado) mientras FASE_FAC='BORRADOR'. Al lanzarla pasa
    // a una fase fiscal cerrada y solo caben Anular o Rectificar.
    procedure ActualizarBloqueoEdicion;
    procedure AsignarControles;
    // Encola en fza_verifactu_cola una ANULACION o SUBSANACION de la
    // factura seleccionada en la lista; el hilo Verifactu la envía
    procedure EncolarOperacionVerifactu(const ATipoOperacion,
                                        AAccion: string);
    // Carga perezosa de sub-pestañas detail. Cada pestaña se asegura de
    // que su query este abierta solo cuando el usuario la activa, evitando
    // refresh master/detail innecesario al cambiar de factura cuando la
    // pestaña no esta visible.
    procedure PcDetailChange(Sender: TObject);
    function PuedeConsultarEstadoColaVerifactu: Boolean;
    // Envuelve GridRecalc con try/except EInvalidOperation. El editor
    // inplace del cxGrid puede llegar sin Parent durante transiciones
    // de celda; mismo patron defensivo que en inMtoCajaOpe.
    procedure RecalcLineaFacturaSegura(Sender: TObject);
    procedure GuardarPendienteAntesDeImprimir;
  public
    dmmFacturas : TdmFacturas;
  end;

//var
//  //frmMtoFacturasBase: TfrmMtoFacturasBase;
//  dmmFacturas : TdmFacturas;

implementation

uses
  inLibWin,
  inLibMsg,
  inLibFiltroUsuario,
  inLibGenBusq,
  inLibShowMto,
  inLibFacturas,
  inLibGridCantidad,
  inLibFotos,
  inLibDefaultValues,
  inLibArticulosValidador,
  inLibArticulosResolver,
  inMtoGenSearch,
  inMtoModalFacRec,
  inMtoModalImpRecFac,
  inMtoModalImpFac,
  inMtoModalRegistrarPago,
  inMtoModalSeleccionarBanco,
  inMtoPrincipal,
  inLibUser,
  inLibVerifactu,
  inLibVerifactuCola,
  inMtoModalFacturarTicket,
  inMtoArticulos,
  inMtoEmpresas,
  inMtoClientes,
  inLibGlobalVar,
  inLibLog,
  inLibtb;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoFacturasBase.btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
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
                           ' WHERE CODIGO_EMP_EMP = :EMPRESA';
      unqrySol.ParamByName('EMPRESA').AsString := VarToStr(e.EditingValue);
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

procedure TfrmMtoFacturasBase.ResetForm;
begin
  inherited;
  if Assigned(dmmFacturas) and Assigned(pcCab) and Assigned(pcDetail) then
  begin
    pcCab.ActivePage := tsCabecera;
    pcDetail.ActivePage := tsLineasFactura;
  end;
end;

destructor TfrmMtoFacturasBase.Destroy;
begin
  RestaurarEnterSku(Self);
  FreeAndNil(FArtMostrarSku);
  inherited;
end;

procedure TfrmMtoFacturasBase.btnUpdateClienteClick(Sender: TObject);
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

procedure TfrmMtoFacturasBase.btnUpdateEmpresaClick(Sender: TObject);
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

procedure TfrmMtoFacturasBase.sbNuevaFacturaClick(Sender: TObject);
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

function TfrmMtoFacturasBase.EsVentaMayorNormal: Boolean;
begin
  Result := SameText(TipoFacturaFiltro, 'NORMAL');
end;

function TfrmMtoFacturasBase.TextoCobroPlural: string;
begin
  if EsVentaMayorNormal then
    Result := 'efectos de cobro'
  else
    Result := 'recibos';
end;

function TfrmMtoFacturasBase.PrefijoExportCobros: string;
begin
  if EsVentaMayorNormal then
    Result := 'EfectosCobro_Borrador_'
  else
    Result := 'Recibos_Borrador_';
end;

procedure TfrmMtoFacturasBase.ConfigurarColumnasRecibos;
begin
  tvRecibos.DataController.DataSource := dmmFacturas.dsRecibos;
  tvRecibos.OptionsData.Appending := True;
  tvRecibos.OptionsData.Deleting := True;
  tvRecibos.OptionsData.Editing := True;
  tvRecibos.OptionsData.Inserting := True;
  tvRecibos.Navigator.Buttons.Insert.Visible := True;
  tvRecibos.Navigator.Buttons.Delete.Visible := True;
  tvRecibos.Navigator.Buttons.Post.Visible := True;
  tvRecibos.Navigator.Buttons.Cancel.Visible := True;
  cxgrdbclmnRecibosNRO_FACTURA_RECIBO.DataBinding.FieldName :=
    'NUMERO_FAC_REC';
  cxgrdbclmnRecibosSERIE_FACTURA_RECIBO.DataBinding.FieldName :=
    'SERIE_FAC_REC';
  cxgrdbclmnRecibosNRO_PLAZO_RECIBO.DataBinding.FieldName :=
    'NUMERO_PLAZO_REC';
  cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO.DataBinding.FieldName :=
    'FORMA_PAGO_ORIGEN_RECIBO_REC';
  cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO.DataBinding.FieldName :=
    'FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC';
  cxgrdbclmnRecibosEUROS_RECIBO.DataBinding.FieldName :=
    'EUROS_RECIBO_REC';
  cxgrdbclmnRecibosESTADO_RECIBO.DataBinding.FieldName :=
    'ESTADO_RECIBO_REC';
  cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO.DataBinding.FieldName :=
    'FECHA_EXPEDICION_RECIBO_REC';
  cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO.DataBinding.FieldName :=
    'FECHA_VENCIMIENTO_RECIBO_REC';
  cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO.DataBinding.FieldName :=
    'IBAN_CLI_REC';
  cxgrdbclmnRecibosFECHA_PAGO_RECIBO.DataBinding.FieldName :=
    'FECHA_PAGO_RECIBO_REC';
  cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO.DataBinding.FieldName :=
    'LOCALIDAD_EXPEDICION_RECIBO_REC';
  cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO.DataBinding.FieldName :=
    'CODIGO_CLI_REC';
  cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO.DataBinding.FieldName :=
    'RAZON_SOCIAL_CLI_REC';
  cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO.DataBinding.FieldName :=
    'DIRECCION1_CLIENTE_RECIBO_REC';
  cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO.DataBinding.FieldName :=
    'POBLACION_CLI_REC';
  cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO.DataBinding.FieldName :=
    'PROVINCIA_CLI_REC';
  cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO.DataBinding.FieldName :=
    'CODIGO_POSTAL_CLI_REC';
  cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO.DataBinding.FieldName :=
    'IMPORTE_LETRA_RECIBO_REC';
  cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO.Visible := True;
  cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO.Visible := True;
  cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO.Visible := True;
  cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO.Visible := True;
  cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO.Visible := True;
  cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO.Visible := True;
end;

procedure TfrmMtoFacturasBase.ConfigurarColumnasEfectosVenta;
begin
  tvRecibos.DataController.DataSource := dmmFacturas.dsEfectosVenta;
  tvRecibos.OptionsData.Appending := False;
  tvRecibos.OptionsData.Deleting := False;
  tvRecibos.OptionsData.Editing := False;
  tvRecibos.OptionsData.Inserting := False;
  tvRecibos.Navigator.Buttons.Insert.Visible := False;
  tvRecibos.Navigator.Buttons.Delete.Visible := False;
  tvRecibos.Navigator.Buttons.Post.Visible := False;
  tvRecibos.Navigator.Buttons.Cancel.Visible := False;
  cxgrdbclmnRecibosNRO_FACTURA_RECIBO.DataBinding.FieldName :=
    'NUMERO_FAC_EFV';
  cxgrdbclmnRecibosSERIE_FACTURA_RECIBO.DataBinding.FieldName :=
    'SERIE_FAC_EFV';
  cxgrdbclmnRecibosNRO_PLAZO_RECIBO.DataBinding.FieldName := 'NUMERO_EFV';
  cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO.DataBinding.FieldName :=
    'CODIGO_TEFE_EFV';
  cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO.DataBinding.FieldName :=
    'DESCRIPCION_TEFE_VIEW_EFV';
  cxgrdbclmnRecibosEUROS_RECIBO.DataBinding.FieldName := 'IMPORTE_EFV';
  cxgrdbclmnRecibosESTADO_RECIBO.DataBinding.FieldName := 'ESTADO_EFV';
  cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO.DataBinding.FieldName :=
    'FECHA_EMISION_EFV';
  cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO.DataBinding.FieldName :=
    'FECHA_VENCIMIENTO_EFV';
  cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO.DataBinding.FieldName := 'IBAN_EFV';
  cxgrdbclmnRecibosFECHA_PAGO_RECIBO.DataBinding.FieldName :=
    'FECHA_COBRO_EFV';
  cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO.DataBinding.FieldName :=
    'REFERENCIA_DOCUMENTO_EFV';
  cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO.DataBinding.FieldName :=
    'CODIGO_CLI_EFV';
  cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO.DataBinding.FieldName :=
    'RAZON_SOCIAL_CLI_EFV';
  cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO.DataBinding.FieldName :=
    'OBSERVACIONES_EFV';
  cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO.DataBinding.FieldName :=
    'OBSERVACIONES_EFV';
  cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO.DataBinding.FieldName :=
    'OBSERVACIONES_EFV';
  cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO.DataBinding.FieldName :=
    'OBSERVACIONES_EFV';
  cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO.DataBinding.FieldName :=
    'OBSERVACIONES_EFV';
  cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO.Visible := True;
  cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO.Visible := False;
  cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO.Visible := False;
  cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO.Visible := False;
  cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO.Visible := False;
  cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO.Visible := False;
end;

procedure TfrmMtoFacturasBase.AplicarOrigenCobros;
begin
  if Assigned(dmmFacturas) then
  begin
    if EsVentaMayorNormal then
      ConfigurarColumnasEfectosVenta
    else
      ConfigurarColumnasRecibos;
  end;
  AplicarTerminologiaCobros;
end;

procedure TfrmMtoFacturasBase.AplicarTerminologiaCobros;
begin
  if EsVentaMayorNormal then
  begin
    tsRecibos.Caption := '&3_Efectos';
    btnGenerarRecibos.Caption := 'Generar efectos';
    btnGenerarRecibos2.Caption := 'Generar efectos';
    btnImprimirRecibo.Caption := 'Imprimir efecto';
    btnImprimirRecibo.Visible := False;
    btnReciboEmitido.Caption := '&Pendiente';
    btnReciboPagado.Caption := '&Cobrado';
    btnReciboDevuelto.Caption := '&Devuelto';
    cxgrdbclmnRecibosNRO_FACTURA_RECIBO.Caption :=
      'Nro Borrador Efecto';
    cxgrdbclmnRecibosSERIE_FACTURA_RECIBO.Caption :=
      'Serie Borrador Efecto';
    cxgrdbclmnRecibosNRO_PLAZO_RECIBO.Caption := 'Efecto';
    cxgrdbclmnRecibosEUROS_RECIBO.Caption := 'Total efecto';
    cxgrdbclmnRecibosESTADO_RECIBO.Caption := 'Estado efecto';
    cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO.Caption :=
      'Fecha emisión efecto';
    cxgrdbclmnRecibosFECHA_PAGO_RECIBO.Caption := 'Fecha cobro';
    cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO.Caption :=
      'Referencia';
  end
  else
  begin
    tsRecibos.Caption := '&3_Recibos';
    btnGenerarRecibos.Caption := 'Generar &Recibo/s';
    btnGenerarRecibos2.Caption := 'Generar &Recibo/s';
    btnImprimirRecibo.Caption := 'Imprimir &Recibo';
    btnImprimirRecibo.Visible := True;
    btnReciboEmitido.Caption := '&Emitido';
    btnReciboPagado.Caption := '&Pagado';
    btnReciboDevuelto.Caption := '&Devuelto';
    cxgrdbclmnRecibosNRO_FACTURA_RECIBO.Caption :=
      'Nro Borrador Recibo';
    cxgrdbclmnRecibosSERIE_FACTURA_RECIBO.Caption :=
      'Serie Borrador Recibo';
    cxgrdbclmnRecibosNRO_PLAZO_RECIBO.Caption := 'Nro Plazo';
    cxgrdbclmnRecibosEUROS_RECIBO.Caption := 'Total Recibo';
    cxgrdbclmnRecibosESTADO_RECIBO.Caption := 'Estado Recibo';
    cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO.Caption :=
      'Fecha Expedición Recibo';
    cxgrdbclmnRecibosFECHA_PAGO_RECIBO.Caption := 'Fecha Pago Recibo';
    cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO.Caption :=
      'Localidad Expedición';
  end;
end;

procedure TfrmMtoFacturasBase.btnImprimirReciboClick(Sender: TObject);
var
  form:TfrmPrintRecFac;
begin
  inherited;
  if EsVentaMayorNormal then
    ShowMessage('La impresión de efectos de cobro se gestiona desde ' +
                'Remesas de Cobro.')
  else
  begin
    form := TfrmPrintRecFac.Create(Application);
    try
      form.dmFac := dmmFacturas;
      form.edtNroFac.Text :=
        dsTablaG.DataSet.findField('NUMERO_FAC').AsString;
      form.edtSerie.Text := dsTablaG.DataSet.findField('SERIE_FAC').AsString;
      form.edtPlazoRecFac.Text :=
        dmmFacturas.unqryRecibos.FindField('NUMERO_PLAZO_REC').AsString;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoFacturasBase.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  with tvLineasFactura.DataController.DataSet do
  ShowMto(Self.Owner,
          'Articulos',
          FieldByName(fcodart).AsString);
end;

procedure TfrmMtoFacturasBase.actArticuloExecute(Sender: TObject);
begin
  inherited;
    if ((pcDetail.ActivePage = tsLineasFactura)) then
       btnIraArticuloClick(Sender)
    else
      ShowMto(Self.Owner, 'Articulos');
end;

procedure TfrmMtoFacturasBase.actClienteExecute(Sender: TObject);
begin
  inherited;
  btnIraClienteClick(Sender);
end;

procedure TfrmMtoFacturasBase.actEmpresaExecute(Sender: TObject);
begin
  inherited;
  btnIrAEmpresaClick(Sender);
end;

procedure TfrmMtoFacturasBase.actMovimientoExecute(Sender: TObject);
var
  ds: TDataSet;
  sNumMov: string;
begin
  inherited;
  // Ctrl+M: ir al movimiento de almacen seleccionado en la pestaña
  // Movimientos. Navegamos a 'MovimientosAlmacen' por PK (NUMERO_MOV) via
  // ShowMto. Fuera de esa pestaña, abrimos el listado sin localizar.
  sNumMov := '';
  if (pcDetail.ActivePage = tsMovimientosFac) and
     Assigned(tvMovimientosFac.DataController.DataSet) then
  begin
    ds := tvMovimientosFac.DataController.DataSet;
    if ds.Active and (not ds.IsEmpty) then
      sNumMov := Trim(ds.FieldByName('NUMERO_MOV').AsString);
  end;
  if sNumMov <> '' then
    ShowMto(Self.Owner, 'MovimientosAlmacen', sNumMov)
  else
    ShowMto(Self.Owner, 'MovimientosAlmacen');
end;

procedure TfrmMtoFacturasBase.ActualizarComboSeries;
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

procedure TfrmMtoFacturasBase.btnExportarLineasClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxGrdLineasFactura, 'Lineas_Borrador_' +
                dsTablaG.Dataset.FieldByName(fseriefac).AsString +
                '_' +
                dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturasBase.btnCalculatorClick(Sender: TObject);
begin
  inherited;
  jvcalcAux.Execute;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEKeyUp(Sender: TObject; var Key: Word;
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

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesButtonClick(
                                                         Sender: TObject;
                                                         AButtonIndex: Integer);
begin
  if SinVerifactuActivo or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Clientes en Borradores',
                                       dmmFacturas.unqryCliDataFac,
                                       'frmMtoCliFacSearch') then
     begin
       dmmFacturas.CopiarClienteaFactura(dmmFacturas.unqryClidataFac);
     end;
  end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesChange(Sender: TObject);
begin
  inherited;
  //ActualizarComboSeries;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesEditValueChanged(
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

procedure TfrmMtoFacturasBase.btnCODIGO_EMPRESA_FACTURAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if SinVerifactuActivo or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Empresas en Borradores',
                                       dmmFacturas.unqryEmpDataFac,
                                       'frmMtoEmpFacSearch') then
      dmmFacturas.CopiarEmpresaaFactura(dmmFacturas.unqryEmpDataFac);
  end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_EMPRESA_FACTURAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  //ActualizarComboSeries;
end;

procedure TfrmMtoFacturasBase.btnExportarRecibosClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxgrdRecibos, PrefijoExportCobros +
                      dsTablaG.Dataset.FieldByName(fseriefac).AsString +
                      '_' +
                      dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturasBase.btnGenerarRecibosClick(Sender: TObject);
var
  bReemplazar:Boolean;
  iRes: Integer;
  qCobros: TDataSet;
  sMensaje: string;
  sEmp, sCli, sPref: string;
  selBanco: TSeleccionBancoResult;
begin
  inherited;
  bReemplazar := True;
  with dmmFacturas.unqryTablaG do
  begin
    if ((State = dsEdit) or (State = dsInsert)) then
      Post;
  end;
  if EsVentaMayorNormal then
    dmmFacturas.AsegurarEfectosVentaAbierta
  else
    dmmFacturas.AsegurarRecibosAbierta;
  if EsVentaMayorNormal then
    qCobros := dmmFacturas.unqryEfectosVenta
  else
    qCobros := dmmFacturas.unqryRecibos;
  if (qCobros <> nil) and (qCobros.RecordCount > 0) then
  begin
    sMensaje := 'Hay ' + TextoCobroPlural +
                ' creados, ¿desea reemplazarlos?';
    if ( Application.MessageBox( PChar(sMensaje),
                                 'Mensaje Advertencia',
                                 MB_YESNO ) = ID_YES ) then
      bReemplazar := True
    else
      bReemplazar := False;
  end;
  if bReemplazar = True then
  begin
    // Cuenta de la empresa (ingreso) para el cobro: eleccion manual, con el
    // banco por defecto del cliente pre-seleccionado si lo tiene.
    sEmp  := dsTablaG.DataSet.FieldByName('CODIGO_EMP_FAC').AsString;
    sCli  := dsTablaG.DataSet.FieldByName('CODIGO_CLI_FAC').AsString;
    sPref := dmmFacturas.GetBancoDefectoCliente(sCli);
    selBanco := TfrmModalSeleccionarBanco.Ejecutar(Self, inLibGlobalVar.oConn,
                                                   sEmp, ubeCobro, sPref);
    if not selBanco.Aceptado then
      ShowMessage('Generación de ' + TextoCobroPlural + ' cancelada.')
    else
    begin
      if EsVentaMayorNormal then
      begin
        iRes := dmmFacturas.GenerarEfectosVenta(selBanco.CodigoEmpban,
                                                selBanco.Iban);
        if iRes > 0 then
          ShowMessage(Format('Generados %d efecto(s) de cobro.', [iRes]))
        else if iRes = 0 then
          ShowMessage('No se generaron efectos. Revisa que el borrador ' +
                      'tenga forma de pago y total, y que no tenga efectos ' +
                      'cobrados o remesados.')
        else
          ShowMessage('No hay borrador activo o no se pudieron generar ' +
                      'efectos.');
      end
      else
      begin
        with dmmFacturas.unstrdprcGetRecibos do
        begin
          ParamByName('pNRO_FACTURA').AsString :=
                               dsTablaG.DataSet.FieldByName(fnrofac).AsString;
          ParamByName('pSERIE_FACTURA').AsString :=
                             dsTablaG.DataSet.FieldByName(fseriefac).AsString;
          ParamByName('pUSUARIO').AsString := oUser;
          ExecProc;
          dmmFacturas.unqryRecibos.Close;
          dmmFacturas.unqryRecibos.Open;
        end;
        // Estampar la cuenta de la empresa (ingreso) en los recibos.
        if selBanco.CodigoEmpban <> '' then
          dmmFacturas.EstamparBancoRecibos(
            dsTablaG.DataSet.FieldByName(fseriefac).AsString,
            dsTablaG.DataSet.FieldByName(fnrofac).AsString,
            selBanco.CodigoEmpban, selBanco.Iban);
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.sbImprimirClick(Sender: TObject);
var
  form:  TfrmPrintFac;
  sFase: string;
begin
  inherited;
  // En modo SIN el borrador se imprime directamente, sin consolidar. Si
  // se estaba editando, se graban antes los cambios para que la copia
  // impresa refleje el estado actual del borrador.
  if SinVerifactuActivo then
    GuardarPendienteAntesDeImprimir;
  // El QR tributario nace al consolidar el registro fiscal: en BORRADOR
  // no hay registro de facturación y no se puede imprimir.
  sFase := dsTablaG.DataSet.FieldByName(ffasefac).AsString;
  if ((sFase = '') or SameText(sFase, 'BORRADOR')) and
     (dsTablaG.DataSet.FieldByName(fescon).AsString <> 'S') and
     (ModoVerifactu <> mvSinVerifactu) then
  begin
    ShowMessage('El borrador está pendiente: use el botón Consolidar ' +
                'antes de imprimirlo en este modo fiscal.');
    Abort;
  end;
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

procedure TfrmMtoFacturasBase.GuardarPendienteAntesDeImprimir;
var
  ConnGrabar: TUniConnection;
  bTransaccionPropia: Boolean;

  procedure PostearSiPendiente(ADataSet: TDataSet);
  begin
    if Assigned(ADataSet) and ADataSet.Active and
       (ADataSet.State in [dsEdit, dsInsert]) then
    begin
      if (ADataSet.State = dsInsert) or ADataSet.Modified then
        ADataSet.Post
      else
        ADataSet.Cancel;
    end;
  end;

begin
  if Assigned(dmmFacturas) then
  begin
    ConnGrabar := dmmFacturas.unqryTablaG.Connection;
    bTransaccionPropia := not ConnGrabar.InTransaction;
    try
      if bTransaccionPropia then
        ConnGrabar.StartTransaction;
      if dmmFacturas.unqryTablaG.State = dsInsert then
        PostearSiPendiente(dmmFacturas.unqryTablaG);
      PostearSiPendiente(dmmFacturas.unqryLinFac);
      PostearSiPendiente(dmmFacturas.unqryRecibos);
      PostearSiPendiente(dmmFacturas.unqryTablaG);
      if bTransaccionPropia and ConnGrabar.InTransaction then
        ConnGrabar.Commit;
    except
      on E: Exception do
      begin
        if bTransaccionPropia and ConnGrabar.InTransaction then
          ConnGrabar.Rollback;
        raise Exception.Create('No se pudo guardar la factura antes de ' +
                               'imprimir: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.btnReciboDevueltoClick(Sender: TObject);
begin
  inherited;
  if EsVentaMayorNormal then
  begin
    dmmFacturas.AsegurarEfectosVentaAbierta;
    if dmmFacturas.CambiarEstadoEfectoVenta('DEVUELTO') then
      ShowMessage('Efecto marcado como devuelto.')
    else
      ShowMessage('No se pudo marcar el efecto como devuelto.');
  end
  else
    CambiarEstadoRecibo('Devuelto');
end;

procedure TfrmMtoFacturasBase.btnReciboEmitidoClick(Sender: TObject);
begin
  inherited;
  if EsVentaMayorNormal then
  begin
    dmmFacturas.AsegurarEfectosVentaAbierta;
    if dmmFacturas.CambiarEstadoEfectoVenta('PENDIENTE') then
      ShowMessage('Efecto marcado como pendiente.')
    else
      ShowMessage('No se pudo marcar el efecto como pendiente.');
  end
  else
    CambiarEstadoRecibo('Emitido');
end;

procedure TfrmMtoFacturasBase.btnReciboPagadoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe: Integer;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if EsVentaMayorNormal then
  begin
    dmmFacturas.AsegurarEfectosVentaAbierta;
    if (dmmFacturas.unqryEfectosVenta <> nil) and
       dmmFacturas.unqryEfectosVenta.Active and
       (not dmmFacturas.unqryEfectosVenta.IsEmpty) then
    begin
      q := dmmFacturas.unqryEfectosVenta;
      iEfe := q.FieldByName('NUMERO_EFV').AsInteger;
      fPend := q.FieldByName('IMPORTE_PENDIENTE_EFV').AsFloat;
      if fPend <= 0.0001 then
        ShowMessage('El efecto seleccionado no tiene importe pendiente.')
      else
      begin
        frm := TfrmModalRegistrarPago.Create(nil);
        try
          frm.SetDatos(
            Format('Efecto %d - vto %s - pendiente %.2f',
              [iEfe,
               FormatDateTime('dd/mm/yyyy',
                 q.FieldByName('FECHA_VENCIMIENTO_EFV').AsDateTime),
               fPend]),
            fPend);
          if frm.ShowModal = mrOk then
          begin
            iRes := dmmFacturas.RegistrarCobroEfectoVenta(iEfe, frm.Fecha,
                      frm.Importe, frm.Tipo, frm.Referencia);
            if iRes > 0 then
              ShowMessage('Efecto conciliado.')
            else
              ShowMessage('No se pudo conciliar el efecto.');
          end;
        finally
          frm.Free;
        end;
      end;
    end
    else
      ShowMessage('Selecciona un efecto en la rejilla.');
  end
  else
    CambiarEstadoRecibo('Pagado');
end;

function TfrmMtoFacturasBase.MostrarSkuArticulo(const ACodArt: string): Boolean;
var
  q        : TUniQuery;
  bMostrar : Boolean;
begin
  // Por defecto mostramos (no bloquear): linea sin articulo o fallo de BD.
  bMostrar := True;
  if (ACodArt <> '') and Assigned(FArtMostrarSku) then
  begin
    if not FArtMostrarSku.TryGetValue(ACodArt, bMostrar) then
    begin
      try
        q := TUniQuery.Create(nil);
        try
          q.Connection := inLibGlobalVar.oConn;
          q.SQL.Text :=
            'SELECT a.ESVARIACION_ART, ' +
            '       (SELECT COUNT(*) FROM fza_articulos_skus s ' +
            '         WHERE s.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
            '           AND s.ESACTIVO_SKU  = ''S'') AS NSKU ' +
            '  FROM fza_articulos a ' +
            ' WHERE a.CODIGO_ART_ART = :art LIMIT 1';
          q.ParamByName('art').AsString := ACodArt;
          q.Open;
          // Sin fila: el articulo aun no existe (nuevo) -> mostrar SKU.
          // Con fila: solo si es de variacion (tallas/colores) o tiene
          // varios SKUs activos a elegir.
          bMostrar := q.IsEmpty or
                      (q.FieldByName('ESVARIACION_ART').AsString = 'S') or
                      (q.FieldByName('NSKU').AsInteger > 1);
        finally
          FreeAndNil(q);
        end;
        FArtMostrarSku.AddOrSetValue(ACodArt, bMostrar);
      except
        // Ante cualquier fallo de BD mostramos el SKU y no cacheamos, para
        // reintentar en el siguiente repintado.
        bMostrar := True;
      end;
    end;
  end;
  Result := bMostrar;
end;

procedure TfrmMtoFacturasBase.ActivarSkuArticuloLinea(const ACodArt: string;
                                                      bEnfocar: Boolean);
var
  oCampoSku: TField;
begin
  if MostrarSkuArticulo(ACodArt) then
  begin
    ctbCODIGO_UNIDAD_FACTURA_LINEA.Visible := True;
    if bEnfocar and Assigned(dmmFacturas) and
       dmmFacturas.unqryLinFac.Active and
       (dmmFacturas.unqryLinFac.State in [dsInsert, dsEdit]) then
    begin
      oCampoSku := dmmFacturas.unqryLinFac.FindField('CODIGO_UNIDAD_FACLIN');
      if (oCampoSku <> nil) and (Trim(oCampoSku.AsString) = '') then
      begin
        TThread.ForceQueue(nil,
          procedure
          var
            Edit: TcxCustomEdit;
          begin
            DesactivarEnterSku(tvLineasFactura);
            tvLineasFactura.Controller.FocusedColumn :=
              ctbCODIGO_UNIDAD_FACTURA_LINEA;
            tvLineasFactura.Controller.EditingController.ShowEdit;
            Edit := tvLineasFactura.Controller.EditingController.Edit;
            if Edit is TcxComboBox then
              (Edit as TcxComboBox).DroppedDown := True;
          end);
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.DesactivarEnterSku(Sender: TObject);
begin
  if not FEnterSkuActivo then
  begin
    FEnterSkuAnterior :=
      tvLineasFactura.OptionsBehavior.GoToNextCellOnEnter;
    FEnterSkuActivo := True;
  end;
  tvLineasFactura.OptionsBehavior.GoToNextCellOnEnter := False;
  DesactivarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoFacturasBase.RestaurarEnterSku(Sender: TObject);
begin
  if FEnterSkuActivo then
  begin
    tvLineasFactura.OptionsBehavior.GoToNextCellOnEnter :=
      FEnterSkuAnterior;
    FEnterSkuActivo := False;
  end;
  RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoFacturasBase.SalirEditorSku(Sender: TObject);
begin
  ConsolidarSkuLinea(Sender);
  RestaurarEnterSku(Sender);
end;

procedure TfrmMtoFacturasBase.ctbCODIGO_UNIDAD_FACTURA_LINEAGetDataText(
  Sender: TcxCustomGridTableItem; ARecordIndex: Integer; var AText: string);
var
  sArt: string;
begin
  // Vaciamos el texto del SKU en las lineas cuyo articulo no es de variacion
  // ni es nuevo. El valor sigue en el dataset; solo se oculta visualmente.
  sArt := VarToStr(tvLineasFactura.DataController.GetValue(
                     ARecordIndex, ctbCODIGO_ARTICULO_FACTURA_LINEA.Index));
  if not MostrarSkuArticulo(sArt) then
    AText := '';
end;

procedure TfrmMtoFacturasBase.tvLineasFacturaEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  // El SKU solo es editable cuando procede mostrarlo (variacion o nuevo).
  if (AItem = ctbCODIGO_UNIDAD_FACTURA_LINEA) and Assigned(dmmFacturas) then
  begin
    AAllow := MostrarSkuArticulo(
      dmmFacturas.unqryLinFac.FieldByName('CODIGO_ART_FACLIN').AsString);
    if AAllow then
      DesactivarEnterSku(Sender)
    else
      RestaurarEnterSku(Sender);
  end
  else
    RestaurarEnterSku(Sender);
end;

procedure TfrmMtoFacturasBase.tvLineasFacturaInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  if AItem = ctbCODIGO_UNIDAD_FACTURA_LINEA then
  begin
    AEdit.OnEnter := DesactivarEnterSku;
    AEdit.OnExit := SalirEditorSku;
    DesactivarEnterSku(AEdit);
  end;
end;

procedure TfrmMtoFacturasBase.tvLineasFacturaEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
begin
  if AItem = ctbCODIGO_UNIDAD_FACTURA_LINEA then
    DesactivarEnterSku(AEdit);
end;

procedure TfrmMtoFacturasBase.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup(
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
  DesactivarEnterSku(Sender);

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

procedure TfrmMtoFacturasBase.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesCloseUp(
  Sender: TObject);
begin
  // CloseUp se dispara dentro de la misma tecla Enter que debe seleccionar el
  // item; si restauramos aqui, TJvEnterAsTab puede convertirla en Tab.
  ConsolidarSkuLinea(Sender);
  DesactivarEnterSku(Sender);
end;

procedure TfrmMtoFacturasBase.ConsolidarSkuLinea(Sender: TObject);
var
  e          : TcxCustomEdit;
  Lin        : TDataSet;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
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
  if FConsolidandoSku then
    Exit;
  if not (Sender is TcxCustomEdit) then
    Exit;
  FConsolidandoSku := True;
  Validador := nil;
  Resolver := nil;
  Lin := dmmFacturas.unqryLinFac;
  try
    if (Lin = nil) or (not Lin.Active) then
      Exit;
    if not (Lin.State in [dsInsert, dsEdit]) then
    begin
      if Lin.CanModify then
        Lin.Edit;
    end;
    if not (Lin.State in [dsInsert, dsEdit]) then
      Exit;
    e      := Sender as TcxCustomEdit;
    CodSku := Trim(VarToStr(e.EditingValue));
    if (CodSku = '') and (e is TcxCustomTextEdit) then
      CodSku := Trim(TcxCustomTextEdit(e).Text);
    if CodSku = '' then
      CodSku := Trim(VarToStr(e.EditValue));
    CodArt := Lin.FindField('CODIGO_ART_FACLIN').AsString;
    if CodSku = '' then
      Exit;

    CodTarifa := dmmFacturas.unqryTablaG.FindField(
                                       'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    FechaFac  := dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime;

    Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
    Resolver := TArticulosResolver.Create(inLibGlobalVar.oConn);
    Resolucion := Validador.Resolver(CodSku);
    if Resolucion.Encontrado and (Resolucion.CodigoSku <> '') then
    begin
      CodArt := Resolucion.CodigoArticulo;
      CodSku := Resolucion.CodigoSku;
    end
    else if CodArt = '' then
      Exit;
    Datos  := Resolver.ResolverDatos(CodArt, CodSku, CodTarifa, FechaFac);
    Precio := Datos.PrecioPedido;
    // Si el SKU tecleado a mano no pertenece al artículo, ResolverDatos lo
    // ignora y deja CodigoSku vacío. En ese caso no tocamos el precio.
    if Datos.CodigoSku = '' then Exit;

    if Assigned(FArtMostrarSku) then
    begin
      FArtMostrarSku.AddOrSetValue(Datos.CodigoArticulo,
                                   Datos.EsVariacion or Datos.RequiereSku);
    end;
    ActivarSkuArticuloLinea(Datos.CodigoArticulo, False);
    Lin.FindField('CODIGO_ART_FACLIN').AsString := Datos.CodigoArticulo;
    if Assigned(Lin.FindField('CODIGO_UNIDAD_FACLIN')) then
      Lin.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := Datos.CodigoSku;
    if VarToStr(e.EditValue) <> Datos.CodigoSku then
      e.EditValue := Datos.CodigoSku;
    if Assigned(Lin.FindField('DESCRIPCION_VARIACION_FACLIN')) then
      Lin.FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString :=
        Datos.DescripcionSku;
    Lin.FindField('DESCRIPCION_ARTICULO_FACLIN').AsString :=
      Datos.DescripcionArticulo;
    if Assigned(Lin.FindField('TIPO_ARTICULO_FACLIN')) then
      Lin.FindField('TIPO_ARTICULO_FACLIN').AsString := Datos.TipoArticulo;
    Lin.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
      Datos.TipoCantidad;
    Lin.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := Datos.TipoIVA;
    Lin.FindField('CODIGO_FAM_FACLIN').AsString := Datos.CodigoFamilia;
    Lin.FindField('NOMBRE_FAM_FACLIN').AsString := Datos.DescripcionFamilia;
    Lin.FindField('CODIGO_TAR_FACLIN').AsString := CodTarifa;

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
    FreeAndNil(Validador);
    FreeAndNil(Resolver);
    FConsolidandoSku := False;
  end;
end;

procedure TfrmMtoFacturasBase.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  ConsolidarSkuLinea(Sender);
end;

procedure TfrmMtoFacturasBase.sbRectificarClick(Sender: TObject);
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

procedure TfrmMtoFacturasBase.CambiarEstadoRecibo(sEstado: string);
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

procedure TfrmMtoFacturasBase.cbbCanalIVAPropertiesChange(Sender: TObject);
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

procedure TfrmMtoFacturasBase.cbbSerieFacturaKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_DOWN) and (Shift = [ssShift])) then
    cbbSerieFactura.DroppedDown := True;
end;

procedure TfrmMtoFacturasBase.cbbSerieFacturaPropertiesChange(Sender: TObject);
var
  sSubtipo: string;
  sFiltro: string;
begin
  inherited;
  if (dsTablaG.Dataset = nil) then
    Exit;
  if ((dsTablaG.DataSet.State <> dsEdit) and
      (dsTablaG.DataSet.State <> dsInsert)) then
    Exit;
  // El descendiente (Normal / Simplif) fija el TIPO_FAC del formulario
  // y manda sobre el SUBTIPO_EMPSER de la serie: una factura abierta en
  // "Ventas Mayor > Facturas" debe ser NORMAL aunque la serie por
  // defecto esté marcada como SIMPLIFICADA en fza_empresas_series.
  sFiltro := TipoFacturaFiltro;
  if (sFiltro <> '') then
    sSubtipo := sFiltro
  else
  begin
    sSubtipo := dmmFacturas.GetSubtipoSerieEmpresa(
                  dsTablaG.DataSet.FindField(fseriefac).AsString,
                  dsTablaG.DataSet.FindField(fcodemp).AsString,
                  dsTablaG.DataSet.FindField(ffechfac).AsDateTime);
    if (sSubtipo = '') then
      sSubtipo := 'NORMAL';
  end;
  dsTablaG.DataSet.FindField(ftipofac).AsString := sSubtipo;
end;

procedure TfrmMtoFacturasBase.cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(
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

procedure TfrmMtoFacturasBase.ActualizarBloqueoEdicion;
var
  oCampo:    TField;
  sFase:     string;
  bEditable: Boolean;
  bBorrador: Boolean;
begin
  if Assigned(dmmFacturas) and
     (dsTablaG.DataSet <> nil) and
     dsTablaG.DataSet.Active then
  begin
    oCampo := dsTablaG.DataSet.FindField(ffasefac);
    if oCampo <> nil then
    begin
      sFase := oCampo.AsString;
      // Borrador sin cerrar: sin fase (facturas antiguas) o BORRADOR y
      // todavía sin consolidar (candado del flujo antiguo). Solo un
      // borrador así admite el botón Consolidar.
      bBorrador := ((sFase = '') or SameText(sFase, 'BORRADOR')) and
                   (dsTablaG.DataSet.FieldByName(fescon).AsString <> 'S');
      // Editable = borrador. En modo SIN la consolidación no cierra
      // fiscalmente: el documento emitido sin Verifactu (SIN_VERIFACTU)
      // y la marca de consolidación no bloquean la edición; solo los
      // estados terminales (anulada/rectificada) quedan bloqueados. Un
      // alta nueva (dsInsert) tampoco tiene fase y debe poder grabarse.
      bEditable := bBorrador;
      if SinVerifactuActivo and
         ((sFase = '') or SameText(sFase, 'BORRADOR') or
          SameText(sFase, cFaseFacturaSinVerifactu)) then
        bEditable := True;
      if dsTablaG.DataSet.State = dsInsert then
        bEditable := True;
      dsTablaG.AutoEdit := bEditable;
      dmmFacturas.unqryLinFac.ReadOnly := not bEditable;
      tvLineasFactura.OptionsData.Editing   := bEditable;
      tvLineasFactura.OptionsData.Inserting := bEditable;
      tvLineasFactura.OptionsData.Deleting  := bEditable;
      // Consolidar lanza el registro a Verifactu: solo tiene sentido
      // en borrador. Imprimir, al revés: solo tras lanzarla. En modo
      // SIN no hay cierre fiscal (ni registro SIF ni cola AEAT): la
      // consolidación no aplica, así que se permite imprimir el
      // borrador directamente sin obligar a consolidarlo antes.
      if dsTablaG.DataSet.State = dsBrowse then
      begin
        btnConsolidar.Enabled := bBorrador and
                                 (not dsTablaG.DataSet.IsEmpty);
        if SinVerifactuActivo then
          btnImprimir.Enabled := not dsTablaG.DataSet.IsEmpty
        else
          btnImprimir.Enabled := not bEditable;
      end;
    end;
  end;
end;

// dsTablaG apunta a la cabecera de factura, que no tiene CODIGO_ART_*.
// El articulo activo vive en la linea seleccionada del sub-grid
// tvLineasFactura. Leemos de ahi para que Ctrl+F muestre la foto
// de la linea actual.
procedure TfrmMtoFacturasBase.ResolverArtSkuActivo(out ACodArt,
                                                   ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasFactura.DataController.DataSource) then
  begin
    ds := tvLineasFactura.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

function TfrmMtoFacturasBase.DataSourcesParaFoto: TArray<TDataSource>;
begin
  // dsTablaG es la cabecera (no tiene articulo). El articulo activo
  // viene de la linea seleccionada en tvLineasFactura, cuyo
  // DataSource es dmmFacturas.dsLinFac. Lo anadimos al hook para que
  // la pantalla flotante refresque al cambiar de linea.
  if Assigned(dmmFacturas) then
    Result := [dsTablaG, dmmFacturas.dsLinFac]
  else
    Result := [dsTablaG];
end;

function TfrmMtoFacturasBase.ContarHijosActivos: Integer;
var
  q: TUniQuery;
  sNum, sSerie: string;
begin
  Result := 0;
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
    Exit;
  sNum   := dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  sSerie := dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :pNum ' +
      '   AND SERIE_FAC_FACLIN  = :pSer';
    q.ParamByName('pNum').AsString := sNum;
    q.ParamByName('pSer').AsString := sSerie;
    q.Open;
    Result := q.FieldByName('N').AsInteger;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmMtoFacturasBase.DescripcionHijos: string;
begin
  Result := 'líneas de borrador';
end;

function TfrmMtoFacturasBase.PuedeConsultarEstadoColaVerifactu: Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := inLibGlobalVar.oConn;
      Qry.SQL.Text :=
        ' SELECT COUNT(*) AS N ' +
        '   FROM INFORMATION_SCHEMA.COLUMNS ' +
        '  WHERE TABLE_SCHEMA = DATABASE() ' +
        '    AND TABLE_NAME = ''fza_verifactu_cola'' ' +
        '    AND COLUMN_NAME IN (''ID_VFCOLA'', ' +
        '                        ''SERIE_FAC_VFCOLA'', ' +
        '                        ''NUMERO_FAC_VFCOLA'', ' +
        '                        ''ESTADO_VFCOLA'')';
      Qry.Open;
      Result := Qry.FieldByName('N').AsInteger = 4;
      if not Result then
        inLibLog.Log.LogWarning('Facturas: esquema de cola Verifactu ' +
          'incompleto; se abre listado sin estado de cola.');
    except
      on E: Exception do
      begin
        Result := False;
        inLibLog.Log.LogWarning('Facturas: no se pudo comprobar cola ' +
          'Verifactu; se abre listado sin estado de cola. ' + E.Message);
      end;
    end;
  finally
    Qry.Free;
  end;
end;

function TfrmMtoFacturasBase.SqlRestriccionUsuario: string;
begin
  // Con appRestringirEmpAlmCaja activo, el usuario solo consulta las
  // facturas de su empresa/almacén/caja (fza_usuarios). Aplica a las
  // dos variantes; simplificadas además lo integra en su
  // ConstruirWhereFacturas al recomponer la SQL con filtros propios.
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_FAC',
                                'CODIGO_ALM_FAC',
                                'CODIGO_CAJA_FAC');
end;

procedure TfrmMtoFacturasBase.CrearTablaPrincipal;
var
  sVista: string;
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
  AplicarOrigenCobros;
  btnReciboEmitido.OnClick := btnReciboEmitidoClick;
  btnReciboDevuelto.OnClick := btnReciboDevueltoClick;
  tvMovimientosFac.DataController.DataSource := dmmFacturas.dsMovimientosFac;
  cbbPaisesEmp.Properties.ListSource := dmmFacturas.dsPaisesEmp;
  cbbPaisesCli.Properties.ListSource := dmmFacturas.dsPaisesCli;
  cbbTipoOperVerifactu.Properties.ListSource := dmmFacturas.dsVerifactuOpe;
  //tvIVA.DataController.DataSource := dsTablaG;
  (ctbTIPOIVA_ARTICULO_FACTURA_LINEA.Properties as
             TcxLookupComboBoxProperties).ListSource := dmmFacturas.dsIvasTipos;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(ctbCANTIDAD_FACTURA_LINEA,
                       ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA);
  // Regla del SKU por linea: no se puede ocultar una columna por fila, asi
  // que se vacia su texto (OnGetDataText) y se bloquea su edicion (OnEditing)
  // segun el articulo de cada linea. El cache evita reconsultar fza_articulos
  // en cada repintado.
  if not Assigned(FArtMostrarSku) then
    FArtMostrarSku := TDictionary<string, Boolean>.Create;
  FArtMostrarSku.Clear;
  ctbCODIGO_UNIDAD_FACTURA_LINEA.OnGetDataText :=
                                  ctbCODIGO_UNIDAD_FACTURA_LINEAGetDataText;
  with TcxComboBoxProperties(ctbCODIGO_UNIDAD_FACTURA_LINEA.Properties) do
  begin
    ImmediatePost := True;
    PostPopupValueOnTab := True;
    OnCloseUp := ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesCloseUp;
  end;
  tvLineasFactura.OnInitEdit := tvLineasFacturaInitEdit;
  tvLineasFactura.OnEditKeyDown := tvLineasFacturaEditKeyDown;
  tvLineasFactura.OnEditing := tvLineasFacturaEditing;
  // La visibilidad del detalle se recalcula cuando cambian/recargan lineas.
  dmmFacturas.dsLinFac.OnDataChange := dsLinFacDataChange;
  // Estado inicial: Variacion oculta, creacion/SKU segun cab/lineas.
  ReaplicarVisibilidadDetalle;
  ActualizarLabelPrendas;
  Self.pkFieldName := 'NUMERO_FAC; SERIE_FAC';
  AsignarControles;
  // El check de mover stock solo aplica a facturas NORMAL: en SIMPLIFICADA
  // se generan movimientos siempre. Lo ocultamos para que el descendiente
  // simplificado no muestre la opcion.
  chkMueveStock.Visible := SameText(TipoFacturaFiltro, 'NORMAL');
  // Convertir en normal solo aplica a facturas simplificadas (F3 AEAT)
  btnVerifactuFacturar.Visible :=
                              SameText(TipoFacturaFiltro, 'SIMPLIFICADA');
  AplicarOrigenCobros;
  // Carga perezosa de sub-pestañas detail (Recibos, Consolidacion,
  // Errores, Movimientos). Solo se abren al activar su pestaña.
  pcDetail.OnChange := PcDetailChange;
  // Bloqueo por fase al movernos de registro (la base solo engancha
  // OnStateChange; OnDataChange queda libre para este form)
  dsTablaG.OnDataChange := dsTablaGDataChange;
  // OpenTables ya no se llama aqui: TfrmMtoGen.AbrirTablaPrincipalAsync
  // (llamado desde inLibShowMto tras el EmbedForm) invoca
  // dmmFacturas.AbrirDetalles en el callback main thread con overlay
  // visible, lo que evita congelar la UI durante la apertura.
  // Cada descendiente apunta a su propia vista de BD: el filtrado por
  // TIPO_FAC vive en la vista, no en el form. Si el descendiente devuelve
  // una vista distinta a vi_facturas, recargamos unqryTablaG con la nueva
  // SQL.
  sVista := NombreVistaListado;
  with dmmFacturas.unqryTablaG do
  begin
    DisableControls;
    try
      Close;
      // Columna Cola Verifactu: último estado en fza_verifactu_cola de
      // cada factura (PENDIENTE/PROCESANDO/ENVIADA/ERROR; NULL si no
      // se ha encolado nunca). Se recompone siempre el SELECT para que
      // las tres variantes (vi_facturas/normales/simplificadas) la
      // lleven, pisando el SQL guardado en perfiles.
      if PuedeConsultarEstadoColaVerifactu then
        SQL.Text :=
          'SELECT v.*, ' +
          '       (SELECT c.ESTADO_VFCOLA ' +
          '          FROM fza_verifactu_cola c ' +
          '         WHERE c.SERIE_FAC_VFCOLA  = v.SERIE_FAC ' +
          '           AND c.NUMERO_FAC_VFCOLA = v.NUMERO_FAC ' +
          '         ORDER BY c.ID_VFCOLA DESC ' +
          '         LIMIT 1) AS ESTADO_VFCOLA ' +
          ' FROM ' + sVista + ' v'
      else
        SQL.Text :=
          'SELECT v.*, '''' AS ESTADO_VFCOLA ' +
          ' FROM ' + sVista + ' v';
      // Los descendientes que precargan con filtros propios devuelven
      // False y abren ellos la lista (filtrada, con progreso) en
      // ResetForm; asi evitamos el SELECT completo de la vista. La
      // base (vi_facturas) tampoco abre aqui: lo hace el open asíncrono
      // de TfrmMtoGen con overlay.
      if AbrirListadoAlCrear and (not SameText(sVista, 'vi_facturas')) then
        Open;
    finally
      EnableControls;
    end;
  end;
  ActualizarBloqueoEdicion;
end;

function TfrmMtoFacturasBase.NombreVistaListado: string;
begin
  Result := 'vi_facturas';
end;

procedure TfrmMtoFacturasBase.EncolarOperacionVerifactu(
  const ATipoOperacion, AAccion: string);
var
  Qry:     TUniQuery;
  sSerie:  string;
  sNumero: string;
begin
  sSerie  := dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  sNumero := dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  if Trim(sNumero) = '' then
    ShowMessage('Seleccione un borrador en la lista.')
  else if dsTablaG.DataSet.FieldByName(
            'ESCONSOLIDADA_FAC').AsString <> 'S' then
    ShowMessage('El borrador ' + sSerie + '\' + sNumero + ' aún no está ' +
                'cerrado fiscalmente: no se puede ' +
                LowerCase(AAccion) + '.')
  else if MessageDlg('¿' + AAccion + ' fiscalmente el borrador ' +
                     sSerie + '\' + sNumero + '?', mtConfirmation,
                     [mbYes, mbNo], 0) = mrYes then
  begin
      Qry := TUniQuery.Create(nil);
      try
        Qry.Connection := inLibGlobalVar.oConn;
      case ModoVerifactu of
        mvVerifactu:
          TVerifactuCola.EncolarFactura(Qry, sSerie, sNumero,
                                        ATipoOperacion);
        mvNoVerifactu:
          TVerifactuCola.RegistrarFacturaNoVerifactu(Qry, sSerie, sNumero,
                                                     ATipoOperacion);
      else
        TVerifactuCola.MarcarFacturaSinVerifactu(Qry, sSerie, sNumero,
                                                 ATipoOperacion);
      end;
    finally
      FreeAndNil(Qry);
    end;
    if VerifactuActivo then
    begin
      RegistrarEventoVerifactu(inLibGlobalVar.oConn,
        cEventoVerifactuEncolado,
        AAccion + ' encolada desde Borradores', '', sSerie, sNumero);
      ShowMessage(AAccion + ' encolada: el hilo Verifactu la enviará en ' +
                  'el próximo ciclo. Puede seguirla en la columna ' +
                  '"Cola Verifactu" y en Verifactu - Cola de Envíos.');
    end
    else if NoVerifactuActivo then
    begin
      ShowMessage(AAccion + ' registrada y firmada en NO VERI*FACTU.');
    end
    else
      ShowMessage(AAccion + ' registrada en modo SIN VERIFACTU.');
    dsTablaG.DataSet.Refresh;
  end;
end;

procedure TfrmMtoFacturasBase.btnConsolidarClick(Sender: TObject);
var
  Qry:     TUniQuery;
  sSerie:  string;
  sNumero: string;
  sFase:   string;
begin
  // Lanzamiento manual de una factura en borrador. La fase final depende
  // del modo fiscal: SIN, VERIFACTU o NO_VERIFACTU.
  if (dsTablaG.DataSet = nil) or
     (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage('Seleccione un borrador en la lista.');
    Abort;
  end;
  sSerie  := dsTablaG.DataSet.FieldByName(fseriefac).AsString;
  sNumero := dsTablaG.DataSet.FieldByName(fnrofac).AsString;
  sFase   := dsTablaG.DataSet.FieldByName(ffasefac).AsString;
  if (sFase <> '') and (not SameText(sFase, 'BORRADOR')) then
    ShowMessage('El borrador ' + sSerie + '\' + sNumero +
                ' ya se lanzó fiscalmente (fase ' + sFase + ').')
  else if ContarHijosActivos = 0 then
    ShowMessage('El borrador no tiene líneas: no se puede lanzar.')
  else if SameText(dsTablaG.DataSet.FieldByName(ftipofac).AsString,
                   'NORMAL') and
          (Trim(dsTablaG.DataSet.FieldByName(
                  'NIF_CLIENTE_FAC').AsString) = '') then
    ShowMessage('Un borrador NORMAL necesita el NIF del cliente para ' +
                'el registro fiscal. Complete los datos del cliente.')
  else if MessageDlg('¿Lanzar fiscalmente el borrador ' + sSerie + '\' +
                     sNumero + '? Dejará de estar en borrador y de ser ' +
                     'editable.', mtConfirmation, [mbYes, mbNo], 0) =
          mrYes then
  begin
      Qry := TUniQuery.Create(nil);
      try
        Qry.Connection := inLibGlobalVar.oConn;
      case ModoVerifactu of
        mvVerifactu:
          TVerifactuCola.EncolarFactura(Qry, sSerie, sNumero);
        mvNoVerifactu:
          TVerifactuCola.RegistrarFacturaNoVerifactu(Qry, sSerie, sNumero);
      else
        TVerifactuCola.MarcarFacturaSinVerifactu(Qry, sSerie, sNumero);
      end;
    finally
      FreeAndNil(Qry);
    end;
    if VerifactuActivo then
      RegistrarEventoVerifactu(inLibGlobalVar.oConn,
        cEventoVerifactuEncolado,
        'Lanzamiento manual (Consolidar) desde Borradores', '',
        sSerie, sNumero);
    dsTablaG.DataSet.Refresh;
    if VerifactuActivo then
      ShowMessage('Borrador ' + sSerie + '\' + sNumero +
                  ' en VERIFACTU_PENDIENTE: el QR ya puede imprimirse ' +
                  'y el envío a la AEAT queda en la cola Verifactu.')
    else if NoVerifactuActivo then
      ShowMessage('Borrador ' + sSerie + '\' + sNumero +
                  ' registrado y firmado en NO VERI*FACTU.')
    else
      ShowMessage('Borrador ' + sSerie + '\' + sNumero +
                  ' emitido en modo SIN VERIFACTU.');
  end;
end;

procedure TfrmMtoFacturasBase.btnVolverBorradorClick(Sender: TObject);
var
  Qry:     TUniQuery;
  sSerie:  string;
  sNumero: string;
  sFase:   string;
  sEstado: string;
begin
  // Deshace un lanzamiento que la AEAT aún NO ha aceptado (p. ej. NIF
  // erróneo detectado tras Consolidar): aparca la fila ALTA de la cola
  // y devuelve la factura a BORRADOR para poder corregirla y relanzar.
  // Si el alta ya fue aceptada (consolidada/ENVIADA) no hay vuelta
  // atrás: el registro existe en la AEAT y solo cabe Anular o
  // Rectificar.
  if (dsTablaG.DataSet = nil) or
     (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage('Seleccione un borrador en la lista.');
    Abort;
  end;
  sSerie  := dsTablaG.DataSet.FieldByName(fseriefac).AsString;
  sNumero := dsTablaG.DataSet.FieldByName(fnrofac).AsString;
  sFase   := dsTablaG.DataSet.FieldByName(ffasefac).AsString;
  if dsTablaG.DataSet.FieldByName(fescon).AsString = 'S' then
    ShowMessage('El borrador ' + sSerie + '\' + sNumero + ' ya está ' +
                'consolidado en la AEAT: no puede volver a borrador. ' +
                'Use Anular fiscal o emita una rectificativa.')
  else if (sFase = '') or SameText(sFase, 'BORRADOR') then
    ShowMessage('El borrador ya está en BORRADOR.')
  else if MessageDlg('¿Devolver a BORRADOR el documento ' + sSerie +
                     '\' + sNumero + ' y anular su envío pendiente a ' +
                     'la AEAT?', mtConfirmation, [mbYes, mbNo], 0) =
          mrYes then
  begin
    Qry := TUniQuery.Create(nil);
    try
      inLibGlobalVar.oConn.StartTransaction;
      try
        Qry.Connection := inLibGlobalVar.oConn;
        // Bloquear la fila ALTA de la cola: si el hilo la está
        // enviando (PROCESANDO) o ya la envió (ENVIADA) no se puede
        // deshacer
        Qry.SQL.Text :=
          ' SELECT ESTADO_VFCOLA ' +
          '   FROM fza_verifactu_cola ' +
          '  WHERE SERIE_FAC_VFCOLA  = :SERIE ' +
          '    AND NUMERO_FAC_VFCOLA = :NUMERO ' +
          '    AND TIPO_OPERACION_VFCOLA = ''ALTA'' ' +
          '  FOR UPDATE';
        Qry.ParamByName('SERIE').AsString  := sSerie;
        Qry.ParamByName('NUMERO').AsString := sNumero;
        Qry.Open;
        if Qry.IsEmpty then
          sEstado := ''
        else
          sEstado := Qry.FieldByName('ESTADO_VFCOLA').AsString;
        Qry.Close;
        if SameText(sEstado, 'ENVIADA') then
          raise Exception.Create('El alta ya fue aceptada por la ' +
            'AEAT: no se puede volver a borrador. Use Anular ' +
            'fiscal o emita una rectificativa.');
        if SameText(sEstado, 'PROCESANDO') then
          raise Exception.Create('El hilo Verifactu está enviando ' +
            'este borrador ahora mismo. Espere unos segundos y ' +
            'vuelva a intentarlo.');
        if sEstado <> '' then
        begin
          // Aparcar: ERROR con intentos al tope para que el hilo no
          // la reprocese. Un Consolidar posterior la reactiva
          // (ON DUPLICATE la devuelve a PENDIENTE con intentos a 0).
          Qry.SQL.Text :=
            ' UPDATE fza_verifactu_cola ' +
            '    SET ESTADO_VFCOLA = ''ERROR'', ' +
            '        CONTADOR_INTENTOS_VFCOLA = 999999, ' +
            '        MENSAJE_ERROR_VFCOLA = ''Lanzamiento anulado ' +
            'por el usuario: borrador devuelto a BORRADOR'', ' +
            '        INSTANTE_MODIF = NOW(), ' +
            '        USUARIO_MODIF  = :USUARIO ' +
            '  WHERE SERIE_FAC_VFCOLA  = :SERIE ' +
            '    AND NUMERO_FAC_VFCOLA = :NUMERO ' +
            '    AND TIPO_OPERACION_VFCOLA = ''ALTA''';
          Qry.ParamByName('SERIE').AsString   := sSerie;
          Qry.ParamByName('NUMERO').AsString  := sNumero;
          Qry.ParamByName('USUARIO').AsString := oUser;
          Qry.Execute;
        end;
        Qry.SQL.Text :=
          ' UPDATE fza_facturas ' +
          '    SET FASE_FAC = ''BORRADOR'', ' +
          '        INSTANTE_MODIF = NOW(), ' +
          '        USUARIO_MODIF  = :USUARIO ' +
          '  WHERE SERIE_FAC  = :SERIE ' +
          '    AND NUMERO_FAC = :NUMERO ' +
          '    AND ESCONSOLIDADA_FAC <> ''S''';
        Qry.ParamByName('SERIE').AsString   := sSerie;
        Qry.ParamByName('NUMERO').AsString  := sNumero;
        Qry.ParamByName('USUARIO').AsString := oUser;
        Qry.Execute;
        inLibGlobalVar.oConn.Commit;
      except
        on E: Exception do
        begin
          inLibGlobalVar.oConn.Rollback;
          ShowMessage(E.Message);
          Abort;
        end;
      end;
    finally
      FreeAndNil(Qry);
    end;
    RegistrarEventoVerifactu(inLibGlobalVar.oConn,
      cEventoVerifactuInfo,
      'Lanzamiento anulado: borrador devuelto a BORRADOR', '',
      sSerie, sNumero);
    dsTablaG.DataSet.Refresh;
    ShowMessage('Borrador ' + sSerie + '\' + sNumero + ' de nuevo en ' +
                'BORRADOR. Corrija los datos (si el error es de la ' +
                'empresa, arréglelo en Empresas y use "Dar de Alta o ' +
                'Actualizar Empresa" en la pestaña Datos Empresa ' +
                'Emisora para refrescar la copia del borrador) y ' +
                'pulse Consolidar para relanzarla.');
  end;
end;

procedure TfrmMtoFacturasBase.btnVerifactuAnularClick(Sender: TObject);
begin
  // Anulación fiscal de la factura activa según modo Verifactu.
  EncolarOperacionVerifactu('ANULACION', 'Anulación');
end;

procedure TfrmMtoFacturasBase.btnVerifactuFacturarClick(Sender: TObject);
var
  oRes:    TFacturarTicketResult;
  sSerie:  string;
  sNumero: string;
begin
  //Factura completa (F3) en sustitución del ticket seleccionado
  sSerie  := dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  sNumero := dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  if Trim(sNumero) = '' then
    ShowMessage('Seleccione un borrador en la lista.')
  else if not SameText(dsTablaG.DataSet.FieldByName(
                         'TIPO_FAC').AsString, 'SIMPLIFICADA') then
    ShowMessage('Solo se crea un borrador normal desde un borrador ' +
                'SIMPLIFICADO (ticket).')
  else
  begin
    oRes := TfrmModalFacturarTicket.Ejecutar(Self, sSerie, sNumero,
              dsTablaG.DataSet.FieldByName('CODIGO_EMP_FAC').AsString,
              dsTablaG.DataSet.FieldByName('CODIGO_ALM_FAC').AsString,
              dsTablaG.DataSet.FieldByName('FECHA_FAC').AsDateTime);
    if oRes.Aceptado then
    begin
      ShowMessage('Creado el borrador ' + oRes.SerieNueva + '\' +
                  oRes.NumeroNueva + ' en sustitución del ticket ' +
                  sSerie + '\' + sNumero + ' en modo fiscal ' +
                  ModoVerifactuTexto + ' (F3).');
      dsTablaG.DataSet.Refresh;
    end;
  end;
end;

function TfrmMtoFacturasBase.TipoFacturaFiltro: string;
begin
  Result := '';
end;

function TfrmMtoFacturasBase.AbrirListadoAlCrear: Boolean;
begin
  Result := True;
end;

procedure TfrmMtoFacturasBase.AplicarVisibilidadColumnasCreacion(
  bCrear: Boolean);
begin
  ctbCODIGO_FAMILIA_FACTURA_LINEA.Visible        := bCrear;
  ctbNOMBRE_FAMILIA_FACTURA_LINEA.Visible        := bCrear;
  ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA.Visible  := bCrear;
  ctbCODIGO_PROVEEDOR_FACTURA_LINEA.Visible      := bCrear;
  ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA.Visible := bCrear;
  ctbPRECIO_ULT_COMPRA_FACTURA_LINEA.Visible     := bCrear;
end;

function TfrmMtoFacturasBase.ModoCreacionActivo: Boolean;
begin
  // El modo creacion vive en la cabecera (ESCREARARTICULOS_FAC). Se lee del
  // dataset activo para que cada factura tenga el suyo, no el ultimo check.
  Result := (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
            (dsTablaG.DataSet.FindField(fcreart) <> nil) and
            (dsTablaG.DataSet.FieldByName(fcreart).AsString = 'S');
end;

procedure TfrmMtoFacturasBase.SincronizarColumnasCreacion;
begin
  AplicarVisibilidadColumnasCreacion(ModoCreacionActivo);
end;

procedure TfrmMtoFacturasBase.SincronizarColumnaSku;
var
  i        : Integer;
  dc       : TcxCustomDataController;
  bMostrar : Boolean;
begin
  // La columna SKU solo aparece si alguna linea la necesita (articulo con
  // variacion / varios SKUs / nuevo) o si la cabecera esta en modo creacion.
  bMostrar := ModoCreacionActivo;
  if not bMostrar then
  begin
    dc := tvLineasFactura.DataController;
    i  := 0;
    while (not bMostrar) and (i < dc.RecordCount) do
    begin
      bMostrar := MostrarSkuArticulo(VarToStr(dc.GetValue(
                    i, ctbCODIGO_ARTICULO_FACTURA_LINEA.Index)));
      Inc(i);
    end;
  end;
  if ctbCODIGO_UNIDAD_FACTURA_LINEA.Visible <> bMostrar then
    ctbCODIGO_UNIDAD_FACTURA_LINEA.Visible := bMostrar;
end;

procedure TfrmMtoFacturasBase.ReaplicarVisibilidadDetalle;
begin
  if not FReaplicandoVisibilidadDetalle then
  begin
    FReaplicandoVisibilidadDetalle := True;
    try
      // - Variacion: nunca visible.
      // - Columnas de creacion: solo en modo creacion de la cabecera.
      // - SKU: solo si alguna linea lo necesita (variacion / varios SKUs /
      //   nuevo) o hay modo creacion.
      // Estas reglas mandan sobre el perfil de usuario (PonerAnchosTitulos).
//      if ctbDESCRIPCION_VARIACION_FACTURA_LINEA.Visible then
//        ctbDESCRIPCION_VARIACION_FACTURA_LINEA.Visible := False;
      SincronizarColumnasCreacion;
      SincronizarColumnaSku;
    finally
      FReaplicandoVisibilidadDetalle := False;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.ActualizarLabelPrendas;
begin
  if not FActualizandoLabelPrendas then
  begin
    FActualizandoLabelPrendas := True;
    try
      if (dmmFacturas <> nil) and Assigned(dmmFacturas.unqryTablaG) and
         dmmFacturas.unqryTablaG.Active and
         (not dmmFacturas.unqryTablaG.IsEmpty) then
        lblTotalPrendasFactura.Caption :=
          FormatFloat('#,##0', dmmFacturas.TotalPrendasFactura)
      else
        lblTotalPrendasFactura.Caption := '0';
    finally
      FActualizandoLabelPrendas := False;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.AplicarEtiquetas;
begin
  inherited;
  // inherited -> PonerAnchosTitulos repuso la visibilidad de las columnas
  // desde el perfil (por defecto visibles). Reimponemos nuestras reglas.
  ReaplicarVisibilidadDetalle;
  AplicarOrigenCobros;
end;

procedure TfrmMtoFacturasBase.dsLinFacDataChange(Sender: TObject;
  Field: TField);
begin
  // Field = nil: cambio de registro de linea, recarga del detalle (al navegar
  // de factura) o alta/baja de linea. Re-evaluamos la visibilidad del detalle.
  if Field = nil then
  begin
    ReaplicarVisibilidadDetalle;
    // Alta/baja/edicion de linea cambia el total de prendas.
    ActualizarLabelPrendas;
  end;
end;

procedure TfrmMtoFacturasBase.chkCrearArticulosPropertiesChange(Sender: TObject);
begin
  inherited;
  AplicarVisibilidadColumnasCreacion(chkCrearArticulos.Checked);
  // En modo creacion el SKU hace falta para los articulos nuevos: lo
  // mostramos ya. Al desactivarlo, recalculamos por si alguna linea con
  // variacion lo sigue necesitando.
  if chkCrearArticulos.Checked then
    ctbCODIGO_UNIDAD_FACTURA_LINEA.Visible := True
  else
    SincronizarColumnaSku;
end;

procedure TfrmMtoFacturasBase.chkDescripcion_ampliadaPropertiesChange(
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

procedure TfrmMtoFacturasBase.
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

procedure TfrmMtoFacturasBase.chkFechaEntregaPropertiesChange(Sender: TObject);
begin
  inherited;
  if (chkFechaEntrega.Checked = True) then
    ctbFECHA_ENTREGA_FACTURA_LINEA.Visible := True
  else
    ctbFECHA_ENTREGA_FACTURA_LINEA.Visible := False;
end;

procedure TfrmMtoFacturasBase.dsTablaGStateChange(Sender: TObject);
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
      btnConsolidar.Enabled := False;
      // En modo SIN el borrador se puede imprimir aunque se esté
      // editando o dando de alta: al pulsar Imprimir se graban antes los
      // cambios. En el resto de modos, durante la edición no se imprime.
      btnImprimir.Enabled := SinVerifactuActivo;
    end
    else
    begin
      btnNuevaFactura.Enabled := True;
      btnRectificar.Enabled := True;
      // Imprimir y Consolidar dependen de la fase Verifactu del
      // registro activo, no solo del estado del dataset
      ActualizarBloqueoEdicion;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.dsTablaGDataChange(Sender: TObject;
                                                 Field: TField);
begin
  // Field = nil: cambio de registro (scroll) o refresco completo
  if Field = nil then
  begin
    ActualizarBloqueoEdicion;
    // Cada factura lleva su propio modo creacion: re-evaluamos al navegar.
    ReaplicarVisibilidadDetalle;
    // Al navegar entre facturas hay que recalcular el total de prendas:
    // las lineas cargadas son las de la factura recien enfocada.
    ActualizarLabelPrendas;
  end;
end;

procedure TfrmMtoFacturasBase.dteFECHA_FACTURAKeyUp(Sender: TObject;
                                                     var Key: Word;
                                                     Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_DOWN) and (Shift = [ssShift])) then
    dteFECHA_FACTURA.DroppedDown := True;
end;

procedure TfrmMtoFacturasBase.dteFECHA_FACTURAPropertiesChange(Sender: TObject);
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

procedure TfrmMtoFacturasBase.btnIrAClienteClick(Sender: TObject);
begin
  inherited;
    with cxGrdDBTabPrin.DataController.DataSet do
  ShowMto(Self.Owner,
          'Clientes',
          FieldByName('CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoFacturasBase.btnIrAEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          cxGrdDBTabPrin.DataController.DataSet.FieldByName(
                                            'CODIGO_EMP_FAC').AsString);
end;

procedure TfrmMtoFacturasBase.
                cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  inherited;
  if SinVerifactuActivo or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    dmmFacturas.unqryArtDataLinFac.ParamByName('TARIFA').AsString :=
                                              dmmFacturas.unqryTablaG.FindField(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    dmmFacturas.unqryArtDataLinFac.ParamByName('FECHA_FAC').AsDateTime :=
                  dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime;
    //      TLibDefaults.Configurar(formulario, esArticulo, True);
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos en Lineas de ' +
                                                                   'Borradores',
                                       dmmFacturas.unqryArtDataLinFac,
                                       'frmMtoArtFacSearch') then
    begin
      dmmFacturas.CopiarArticuloaLinea(dmmFacturas.unqryArtDataLinFac);
      ActivarSkuArticuloLinea(
        dmmFacturas.unqryLinFac.FieldByName('CODIGO_ART_FACLIN').AsString,
        True);
    end;
  end;
end;

procedure TfrmMtoFacturasBase.
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
var
  e          : TcxCustomEdit;
  sInput     : string;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
  Datos      : TArticuloDatos;
  DatosSku   : TArticuloDatos;
  Precio     : TArticuloPrecio;
  Lin        : TDataSet;
  CodTarifa  : string;
  FechaFac   : TDateTime;
  SkuAnterior: string;
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
  SkuAnterior := '';
  if Assigned(Lin.FindField('CODIGO_UNIDAD_FACLIN')) then
    SkuAnterior := Trim(Lin.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);

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
    if Datos.RequiereSku and (Resolucion.CodigoSku = '') and
       (SkuAnterior <> '') then
    begin
      DatosSku := Resolver.ResolverDatos(Resolucion.CodigoArticulo,
                                         SkuAnterior,
                                         CodTarifa,
                                         FechaFac);
      if DatosSku.Encontrado and (DatosSku.CodigoSku <> '') then
        Datos := DatosSku;
    end;
    // Pre-cargamos la regla del SKU de este articulo (ya existe): se mostrara
    // si es de variacion o tiene varios SKUs. Evita reconsultar en el pintado.
    if Assigned(FArtMostrarSku) then
    begin
      FArtMostrarSku.AddOrSetValue(Datos.CodigoArticulo,
                                   Datos.EsVariacion or Datos.RequiereSku);
    end;
    // Si el articulo recien tecleado necesita SKU, mostramos ya la columna
    // (el rescan al postear/navegar la ocultara de nuevo si procede).
    ActivarSkuArticuloLinea(Datos.CodigoArticulo, Datos.RequiereSku);

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
    // TIPO_ARTICULO_FACLIN existe en la tabla base pero vi_facturas_lineas no
    // lo expone: asignacion defensiva (mismo motivo que CODIGO_UNIDAD_FACLIN).
    if Assigned(Lin.FindField('TIPO_ARTICULO_FACLIN')) then
      Lin.FindField('TIPO_ARTICULO_FACLIN').AsString     := Datos.TipoArticulo;
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
    // Disparamos el recalculo para que TOTAL_FACLIN y TOTAL_FAC_SIVA_FACLIN
    // se vuelquen al dataset. Si el usuario se va de la fila sin tocar
    // otros campos, sin esto los totales quedaban a 0 en el INSERT.
    RecalcLineaFacturaSegura(Sender);
  finally
    FreeAndNil(Validador);
    FreeAndNil(Resolver);
  end;
end;

procedure TfrmMtoFacturasBase.sbGrabarClick(Sender: TObject);
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

procedure TfrmMtoFacturasBase.tvLineasFacturaKeyDown(Sender: TObject;
                                                 var Key: Word;
                                                 Shift: TShiftState);
begin
  inherited;
  // Defensa: el editor inplace del cxGrid puede llegar sin Parent durante
  // transiciones de celda; tocar Insert/Post sobre el datacontroller puede
  // disparar EInvalidOperation "no tiene ventana principal" via refresh de
  // controles ligados. Mismo patron que en inMtoCajaOpe.
  try
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
            ShowMessage('Debe completar los datos del borrador: ' + E.Message);
            Exit;
          end;
        end;
      end;
      tvLineasFactura.DataController.Insert;
    end;
  except
    on E: EInvalidOperation do
      // Tragamos solo el caso del editor inplace sin Parent. El handler
      // global AppException ya filtra y registra como warning.
      ;
  end;
end;

procedure TfrmMtoFacturasBase.CambiarIVA;
begin
  if (dsTablaG.DataSet.State = dsInsert) then
    dmmFacturas.AsignarIVA(
        dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString,
        dmmFacturas.unqryTablaG);
end;

procedure TfrmMtoFacturasBase.RecalcLineaFacturaSegura(Sender: TObject);
begin
  try
    GridRecalc(Sender,
               tvLineasFactura,
               dmmFacturas.unqryLinFac,
               dmmFacturas.unqryTablaG);
  except
    on E: EInvalidOperation do
      // Editor inplace de cxGrid sin Parent durante transicion de celda.
      // GridRecalc ya valida Edit.Parent, pero el FocusedColumn / refresh
      // posterior puede disparar el mismo error en carrera. AppException
      // lo registrara como warning si llega tan arriba.
      ;
  end;
end;

procedure TfrmMtoFacturasBase.
              tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.
            tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.
                    cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange(
                                                               Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.
                      ctbCODIGO_FAMILIA_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  //rellenar nombrefamilia

end;

procedure TfrmMtoFacturasBase.
                    ctbCODIGO_PROVEEDOR_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  //rellenar razon social proveedor y precio de coste
end;

procedure TfrmMtoFacturasBase.ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.
                  cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.AsignarControles;
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
    cxdbmPETICION_COMPLETA_FACCON.DataBinding.DataSource := dsConsolidacion;
    txtREQUEST_ID.DataBinding.DataSource := dsConsolidacion;
    // El dfm ata este grid a dmFacturas.dsErrores por NOMBRE GLOBAL:
    // con dos ventanas de Facturas abiertas (normales + simplificadas)
    // resolvía al datamodule de la primera y la pestaña 6_Registro
    // mostraba los eventos de la factura activa en la OTRA ventana.
    // Reatamos al datamodule de esta instancia, como el resto.
    tvLogVerifactu.DataController.DataSource := dsErrores;
  end;
end;


procedure TfrmMtoFacturasBase.spnRetencionPropertiesEditValueChanged(
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

procedure TfrmMtoFacturasBase.PcDetailChange(Sender: TObject);
begin
  if not Assigned(dmmFacturas) then Exit;
  // Despachador: cada sub-pestaña detail tiene su query lazy. Solo se
  // abre al activarse. Lineas (tsLineasFactura) se abre desde
  // AbrirDetalles por ser la pestaña por defecto y la mas usada.
  if pcDetail.ActivePage = tsRecibos then
  begin
    if EsVentaMayorNormal then
      dmmFacturas.AsegurarEfectosVentaAbierta
    else
      dmmFacturas.AsegurarRecibosAbierta;
  end
  else if pcDetail.ActivePage = tsVerifactu then
    dmmFacturas.AsegurarConsolidacionAbierta
  else if pcDetail.ActivePage = tsRegistro then
    dmmFacturas.AsegurarErroresAbierta
  else if pcDetail.ActivePage = tsMovimientosFac then
    dmmFacturas.AsegurarMovimientosFacAbierta;
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasBase);
end.


