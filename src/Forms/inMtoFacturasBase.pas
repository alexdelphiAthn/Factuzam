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
  Dialogs, inMtoDocumento, cxGraphics, cxControls, cxLookAndFeels,
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
  dxSkinWhiteprint, dxSkinXmas2008Blue,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridPivoteVenta,
  inLibFacturasServiciosIntf, inLibEmisionFiscalIntf,
  inLibDocumento, inLibDocumentoIntf,
  inLibFacturasColumnasPresentacion,
  inLibFacturasLineasEdicion;

type
  TfrmMtoFacturasBase = class;

  TControladorFacturas = class
  private
    FAnfitrion: TfrmMtoFacturasBase;
  public
    constructor Create(AAnfitrion: TfrmMtoFacturasBase);
    procedure ActualizarBloqueoEdicion;
    procedure ActualizarLabelPrendas;
    procedure ActivarSkuArticuloLinea(const ACodArt: string;
      AEnfocar: Boolean);
    procedure AplicarEdicionPreciosLinea(Sender: TObject);
    procedure AplicarOrigenCobros;
    procedure AplicarVisibilidadColumnasCreacion(ACrear: Boolean);
    function AsegurarCabeceraPersistidaParaLineas: Boolean;
    procedure AsegurarPrimeraLineaFacturaBorrador;
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnConsolidarClick(Sender: TObject);
    procedure btnGenerarRecibosClick(Sender: TObject);
    procedure btnReciboPagadoClick(Sender: TObject);
    procedure btnVolverBorradorClick(Sender: TObject);
    procedure cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(
      Sender: TObject);
    procedure chkDescripcion_ampliadaPropertiesChange(Sender: TObject);
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostFactura(AClasico: Boolean);
    procedure CrearTablaPrincipal;
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
    procedure dsTablaGStateChange(Sender: TObject);
    function EsVentaMayorNormal: Boolean;
    procedure EjecutarOperacionFiscal(
      const ATipoOperacion, AAccion: string);
    procedure GuardarPendienteAntesDeImprimir;
    function ModoCreacionActivo: Boolean;
    function ModoCreacionSolicitado: Boolean;
    function MostrarSkuArticulo(const ACodArt: string): Boolean;
    procedure NuevaFacturaDesdeInsert(Sender: TObject);
    function PuedeConsultarEstadoColaVerifactu: Boolean;
    function PrecioSkuTallas(const ACodigoArticulo,
      ACodigoSku: string): Double;
    procedure RecalcLineaFacturaSegura(Sender: TObject);
    procedure ReaplicarVisibilidadDetalle;
    procedure sbImprimirClick(Sender: TObject);
    procedure SenalarCampoValidacion(ACampo: TCampoValidacionFac);
    procedure SeriesCambiadasDesdeDM(Sender: TObject);
    procedure SincronizarColumnaSku;
    procedure SincronizarColumnasCreacion;
  end;

  TfrmMtoFacturasBase = class(TfrmMtoDocumento)
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
    lblAlmacenFactura: TcxLabel;
    cbbAlmacenFactura: TcxDBLookupComboBox;
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
    procedure cxgrdLineasFacturaEnter(Sender: TObject);
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
    procedure
      tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
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
    procedure ResetForm; override;
    procedure CambiarIVA;
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
    FEnterSkuActivo: Boolean;
    FEnterSkuAnterior: Boolean;
    FReaplicandoVisibilidadDetalle: Boolean;
    FActualizandoLabelPrendas: Boolean;
    FControlador: TControladorFacturas;
    FEditorLineas: TEditorLineasFactura;
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    FConstruyendoModo: Boolean;
    // La excepcion de dominio senala un campo logico; el form decide
    // como presentar el error y donde colocar el foco.
    procedure SenalarCampoValidacion(ACampo: TCampoValidacionFac);
    procedure MostrarResultadoOperacion(
      const AResultado: TResultadoOperacionFactura);
    procedure MostrarResultadoBorrado(
      const AResultado: TResultadoBorradoFactura);
    procedure MostrarAdvertenciaFactura(const AMensaje: string);
    procedure MostrarErrorValidacion(
      const AError: EValidacionFactura);
    function ConfirmarBorradoFactura(
      const ASerie, ANumero: string): Boolean;
    // Conmuta que precio es editable (s/IVA o c/IVA) segun la tarifa
    // de la linea. Antes vivia en TdmFacturas.dsLinFacStateChange.
    procedure AplicarEdicionPreciosLinea(Sender: TObject);
    procedure AplicarOrigenCobros;
    // Modo creacion de articulos de la cabecera (ESCREARARTICULOS_FAC='S').
    // Visibilidad de las columnas de creacion de articulos del detalle.
    // Solo se ven cuando la cabecera esta en modo "Crear/Act Articulo";
    // ocultas en caso contrario.
    // Regla de negocio del SKU en lineas: solo se muestra/edita cuando el
    // articulo tiene variacion (tallas/colores) o es nuevo (aun no existe
    // en la BBDD). Para articulos normales el SKU se autoresuelve y estorba.
    procedure ConsolidarSkuLinea(Sender: TObject);
    procedure DesactivarEnterSku(Sender: TObject);
    procedure RestaurarEnterSku(Sender: TObject);
    procedure SalirEditorSku(Sender: TObject);
    // La columna SKU completa se oculta si ninguna linea la necesita y no
    // hay modo creacion; dentro de una columna visible, las celdas que no
    // proceden se vacian (OnGetDataText) y se bloquean (OnEditing).
    // Reimpone TODA la visibilidad de columnas del detalle que controlamos
    // por logica de negocio. Necesario porque AplicarEtiquetas ->
    // PonerAnchosTitulos (inLibDevExp) repone la visibilidad desde el perfil
    // (por defecto visible) y pisa lo que fijamos en CrearTablaPrincipal.
    // Pinta lblTotalPrendasFactura con el total de prendas (suma de
    // CANTIDAD_FACLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
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
    // Ejecuta una ANULACION o SUBSANACION con la estrategia fiscal activa.
    procedure EjecutarOperacionFiscal(
      const ATipoOperacion, AAccion: string);
    // Carga perezosa de sub-pestañas detail. Cada pestaña se asegura de
    // que su query este abierta solo cuando el usuario la activa, evitando
    // refresh master/detail innecesario al cambiar de factura cuando la
    // pestaña no esta visible.
    procedure PcDetailChange(Sender: TObject);
    // Envuelve GridRecalc con try/except EInvalidOperation. El editor
    // inplace del cxGrid puede llegar sin Parent durante transiciones
    // de celda; mismo patron defensivo que en inMtoCajaOpe.
    procedure RecalcLineaFacturaSegura(Sender: TObject);
    procedure GuardarPendienteAntesDeImprimir;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal con las
    // lineas de la factura a la vista. El Construir hace ClearItems:
    // las columnas del dfm mueren y las propias se recrean en runtime
    // reasignando las referencias ctb* para que la logica existente
    // (visibilidad, ImpIncl, recalculo) siga funcionando (patron de
    // pedidos/inventarios). El modo tallas es inLibGridPivoteVenta con
    // BandaUnica: pivot SOLO visual, las lineas fiscales no se tocan.
    // Con el modo "Crear/Act Articulo" activo se reconstruye la
    // presentacion CLASICA (articulo + SKU con sus handlers legacy):
    // el contrato no cubre el alta de articulos inline.

    procedure ConstruirModoEntrada;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    // Aplica articulo/SKU a la linea activa con el flujo fiscal clasico
    // (tarifa del cliente, IVA, dtos, precios y recalculo de totales).
    // Es el nucleo compartido de ConsolidarSkuLinea y del OnResuelto.
    procedure AplicarArticuloFactura(const AEntrada: string);
    // Linea libre en venta mayor: codigo fuera de catalogo aceptado por
    // el modo (AceptarNoCatalogo). Sin SKU (no mueve stock); completa
    // la fiscalidad por defecto y deja descripcion/precio al usuario.
    procedure AplicarLineaNoCatalogo(const ACodArt: string);
    // Contrato ObtenerPrecioSku del modo tallas: PVP C/IVA que la
    // factura aplicaria al SKU, para que la consolidacion visual separe
    // filas por precio.
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmFacturas : TdmFacturas;
  end;

//var
//  //frmMtoFacturasBase: TfrmMtoFacturasBase;
//  dmmFacturas : TdmFacturas;

implementation

uses
  inLibWin,
  inLibMsgArticulos, inLibMsgComun, inLibMsgFacturas,
  inLibMsgVentas,
  inLibImpuestosComun,
  inLibFiltroUsuario,
  inLibGenBusq,
  inLibShowMto,
  inLibFacturas,
  inLibFacturasCobrosPresentacion,
  inLibFacturasEstadoFiscalPresentacion,
  inLibFacturasOperacionFiscal,
  inLibFacturasConsolidacionPresentacion,
  inLibGridCantidad,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibArticulosResolverIntf,
  inMtoGenSearch,
  inMtoModalFacRec,
  inMtoModalImpRecFac,
  inMtoModalImpFac,
  inMtoModalRegistrarPago,
  inMtoModalSeleccionarBanco,
  inLibUser,
  inLibVerifactu,
  inLibVerifactuTipos,
  inLibEmisionFiscal,
  UniDataVerifactuColaRepositorio,
  UniDataFacturasRepositorio,
  inLibFacturasMovimientos,
  inLibFacturasConsolidacion,
  inLibFacturasReapertura,
  inLibFacturasComposicion,
  inMtoModalFacturarTicket,
  inLibLog,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku, inLibColumnasDocumento, UniDataGen,
  inLibPresentacionDocumento,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TControladorFacturas.Create(
  AAnfitrion: TfrmMtoFacturasBase);
begin
  inherited Create;
  FAnfitrion := AAnfitrion;
end;

procedure TControladorFacturas.
  btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo:String;
  unqrySol:TUniQuery;
begin
  with FAnfitrion do
  begin
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
      unqrySol := TUniQuery.Create(FAnfitrion);
      unqrySol.Connection := ConexionPrincipal;
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
      dmmFacturas.RefrescarAlmacenes(sCodigo);
      unqrySol.Close;
      FreeAndNil(unqrySol);
    end;
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
  // El modo del contrato se libera ANTES del inherited: su teardown
  // (Desmontar/destructor) toca el view y el dataset de lineas, que
  // deben seguir vivos. Si se dejara a la finalizacion de la interfaz,
  // correria con el DM ya destruido.
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      // Teardown defensivo en cierre: nada que hacer si el grid ya
      // esta a medio destruir.
      on E: Exception do
        if inLibLog.Log() <> nil then
          inLibLog.Log.LogWarning(
            'FacturasBase.Destroy: Desmontar fallo: ' + E.Message);
    end;
    FModoEntrada := nil;
  end;
  RestaurarEnterSku(Self);
  FreeAndNil(FEditorLineas);
  FreeAndNil(FControlador);
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

function TControladorFacturas.EsVentaMayorNormal: Boolean;
begin
  with FAnfitrion do
  begin
  Result := SameText(TipoFacturaFiltro, 'NORMAL');
  end;
end;

procedure TControladorFacturas.AplicarOrigenCobros;
var
  Configuracion: TConfiguracionCobrosFactura;
  Controles: TControlesCobrosFactura;
begin
  with FAnfitrion do
  begin
  Configuracion := CrearConfiguracionCobrosFactura(TipoFacturaFiltro);
  Controles := Default(TControlesCobrosFactura);
  Controles.AplicarOrigenDatos := Assigned(dmmFacturas);
  Controles.Vista := tvRecibos;
  if Assigned(dmmFacturas) then
  begin
    Controles.DataSourceRecibos := dmmFacturas.dsRecibos;
    Controles.DataSourceEfectos := dmmFacturas.dsEfectosVenta;
  end;
  Controles.Pestana := tsRecibos;
  Controles.BotonGenerar := btnGenerarRecibos;
  Controles.BotonGenerarSecundario := btnGenerarRecibos2;
  Controles.BotonImprimir := btnImprimirRecibo;
  Controles.BotonPendiente := btnReciboEmitido;
  Controles.BotonCobrado := btnReciboPagado;
  Controles.BotonDevuelto := btnReciboDevuelto;
  Controles.Columnas[ccfNumeroFactura] :=
    cxgrdbclmnRecibosNRO_FACTURA_RECIBO;
  Controles.Columnas[ccfSerieFactura] :=
    cxgrdbclmnRecibosSERIE_FACTURA_RECIBO;
  Controles.Columnas[ccfNumeroPlazo] :=
    cxgrdbclmnRecibosNRO_PLAZO_RECIBO;
  Controles.Columnas[ccfFormaPago] :=
    cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO;
  Controles.Columnas[ccfDescripcionFormaPago] :=
    cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO;
  Controles.Columnas[ccfImporte] := cxgrdbclmnRecibosEUROS_RECIBO;
  Controles.Columnas[ccfEstado] := cxgrdbclmnRecibosESTADO_RECIBO;
  Controles.Columnas[ccfFechaExpedicion] :=
    cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO;
  Controles.Columnas[ccfFechaVencimiento] :=
    cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO;
  Controles.Columnas[ccfIban] := cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO;
  Controles.Columnas[ccfFechaPago] :=
    cxgrdbclmnRecibosFECHA_PAGO_RECIBO;
  Controles.Columnas[ccfLocalidad] :=
    cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO;
  Controles.Columnas[ccfCodigoCliente] :=
    cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO;
  Controles.Columnas[ccfRazonSocialCliente] :=
    cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO;
  Controles.Columnas[ccfDireccionCliente] :=
    cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO;
  Controles.Columnas[ccfPoblacionCliente] :=
    cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO;
  Controles.Columnas[ccfProvinciaCliente] :=
    cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO;
  Controles.Columnas[ccfCodigoPostalCliente] :=
    cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO;
  Controles.Columnas[ccfImporteLetra] :=
    cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO;
  TPresentacionCobrosFactura.Aplicar(Configuracion, Controles);
  end;
end;

procedure TfrmMtoFacturasBase.btnImprimirReciboClick(Sender: TObject);
var
  form:TfrmPrintRecFac;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if FControlador.EsVentaMayorNormal then
    ShowMessage(SInfoImpresionEfectosCobroEnRemesas)
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
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasFactura.DataController.DataSet, fcodart);
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
begin
  inherited;
  // Ctrl+M: ir al movimiento de almacen seleccionado en la pestaña
  // Movimientos. Navegamos a 'MovimientosAlmacen' por PK (NUMERO_MOV) via
  // ShowMto. Fuera de esa pestaña, abrimos el listado sin localizar.
  ds := nil;
  if (pcDetail.ActivePage = tsMovimientosFac) and
     Assigned(tvMovimientosFac.DataController.DataSet) then
    ds := tvMovimientosFac.DataController.DataSet;
  ShowMtoCodigoDataSet(Self.Owner, 'MovimientosAlmacen',
    ds, 'NUMERO_MOV');
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
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxGrdLineasFactura, 'Lineas_Borrador_' +
                dsTablaG.Dataset.FieldByName(fseriefac).AsString +
                '_' +
                dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturasBase.btnCalculatorClick(Sender: TObject);
begin
  inherited;
  jvcalcAux.Execute;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEKeyUp(
  Sender: TObject; var Key: Word; Shift: TShiftState);
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
  if SinVerifactuActivo(ParametrosApp) or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if TBusquedaUtils.EjecutarBusqueda(
      ConexionPrincipal,
      'Búsqueda de Clientes en Borradores',
                                       dmmFacturas.unqryCliDataFac,
                                       'frmMtoCliFacSearch') then
     begin
       dmmFacturas.CopiarClienteaFactura(dmmFacturas.unqryClidataFac);
     end;
  end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesChange(
  Sender: TObject);
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
  if SinVerifactuActivo(ParametrosApp) or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if TBusquedaUtils.EjecutarBusqueda(
      ConexionPrincipal,
      'Búsqueda de Empresas en Borradores',
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
var
  Configuracion: TConfiguracionCobrosFactura;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  Configuracion := CrearConfiguracionCobrosFactura(TipoFacturaFiltro);
  ExportarExcel(
    ParametrosApp,
    cxgrdRecibos,
    Configuracion.PrefijoExportacion +
      dsTablaG.Dataset.FieldByName(fseriefac).AsString + '_' +
      dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TControladorFacturas.btnGenerarRecibosClick(Sender: TObject);
var
  bReemplazar:Boolean;
  Configuracion: TConfiguracionCobrosFactura;
  iRes: Integer;
  qCobros: TDataSet;
  sMensaje: string;
  sEmp, sCli, sPref: string;
  selBanco: TSeleccionBancoResult;
begin
  with FAnfitrion do
  begin
  bReemplazar := True;
  Configuracion := CrearConfiguracionCobrosFactura(TipoFacturaFiltro);
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
    sMensaje := Format(
      SPreguntaReemplazarCobros,
      [Configuracion.TextoPlural]);
    if ( Application.MessageBox( PChar(sMensaje),
                                 PChar(STituloMensajeAdvertencia),
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
    selBanco := TfrmModalSeleccionarBanco.Ejecutar(
      FAnfitrion,
      ConexionPrincipal,
                                                   sEmp, ubeCobro, sPref);
    if not selBanco.Aceptado then
      ShowMessage(
        Format(
          SInfoGeneracionCobrosCancelada,
          [Configuracion.TextoPlural]))
    else
    begin
      if EsVentaMayorNormal then
      begin
        iRes := dmmFacturas.GenerarEfectosVenta(selBanco.CodigoEmpban,
                                                selBanco.Iban);
        if iRes > 0 then
          ShowMessage(Format(SInfoEfectosCobroGenerados, [iRes]))
        else if iRes = 0 then
          ShowMessage(SAvisoEfectosCobroNoGenerados)
        else
          ShowMessage(SErrorGenerarEfectosCobroSinBorrador);
      end
      else
      begin
        with dmmFacturas.unstrdprcGetRecibos do
        begin
          ParamByName('pNRO_FACTURA').AsString :=
                               dsTablaG.DataSet.FieldByName(fnrofac).AsString;
          ParamByName('pSERIE_FACTURA').AsString :=
                             dsTablaG.DataSet.FieldByName(fseriefac).AsString;
          ParamByName('pUSUARIO').AsString := IdentidadSesion.Usuario;
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
end;

procedure TControladorFacturas.sbImprimirClick(Sender: TObject);
var
  form:  TfrmPrintFac;
  sFase: string;
begin
  with FAnfitrion do
  begin
  if not PuedeImprimir then
    Abort;
  // En modo SIN el borrador se imprime directamente, sin consolidar. Si
  // se estaba editando, se graban antes los cambios para que la copia
  // impresa refleje el estado actual del borrador.
  if SinVerifactuActivo(ParametrosApp) then
    GuardarPendienteAntesDeImprimir;
  // El QR tributario nace al consolidar el registro fiscal: en BORRADOR
  // no hay registro de facturación y no se puede imprimir.
  sFase := dsTablaG.DataSet.FieldByName(ffasefac).AsString;
  if ((sFase = '') or SameText(sFase, 'BORRADOR')) and
     (dsTablaG.DataSet.FieldByName(fescon).AsString <> 'S') and
     (ModoVerifactu(ParametrosApp) <> mvSinVerifactu) then
  begin
    ShowMessage(SAvisoBorradorPendienteImpresionFiscal);
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
end;

procedure TControladorFacturas.GuardarPendienteAntesDeImprimir;
var
  ConnGrabar: TUniConnection;
begin
  with FAnfitrion do
  begin
  if Assigned(dmmFacturas) then
  begin
    ConnGrabar := dmmFacturas.unqryTablaG.Connection;
    try
      inLibFacturas.GuardarCambiosPendientesFactura(
        ConnGrabar,
        dmmFacturas.unqryTablaG,
        dmmFacturas.unqryLinFac,
        dmmFacturas.unqryRecibos);
    except
      on E: Exception do
        raise Exception.Create(Format(SErrorGuardarFacturaAntesImprimir,
                                     [E.Message]));
    end;
  end;
end;
end;

procedure TfrmMtoFacturasBase.btnReciboDevueltoClick(Sender: TObject);
begin
  inherited;
  if FControlador.EsVentaMayorNormal then
  begin
    dmmFacturas.AsegurarEfectosVentaAbierta;
    if dmmFacturas.CambiarEstadoEfectoVenta('DEVUELTO') then
      ShowMessage(SInfoEfectoMarcadoDevuelto)
    else
      ShowMessage(SErrorMarcarEfectoDevuelto);
  end
  else
    CambiarEstadoRecibo('Devuelto');
end;

procedure TfrmMtoFacturasBase.btnReciboEmitidoClick(Sender: TObject);
begin
  inherited;
  if FControlador.EsVentaMayorNormal then
  begin
    dmmFacturas.AsegurarEfectosVentaAbierta;
    if dmmFacturas.CambiarEstadoEfectoVenta('PENDIENTE') then
      ShowMessage(SInfoEfectoMarcadoPendiente)
    else
      ShowMessage(SErrorMarcarEfectoPendiente);
  end
  else
    CambiarEstadoRecibo('Emitido');
end;

procedure TControladorFacturas.btnReciboPagadoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe: Integer;
  iRes: Integer;
  fPend: Double;
begin
  with FAnfitrion do
  begin
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
        ShowMessage(SErrorEfectoSinImportePendiente)
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
              ShowMessage(SInfoEfectoConciliado)
            else
              ShowMessage(SErrorConciliarEfecto);
          end;
        finally
          frm.Free;
        end;
      end;
    end
    else
      ShowMessage(SErrorEfectoNoSeleccionado);
  end
  else
    CambiarEstadoRecibo('Pagado');
  end;
  end;

function TControladorFacturas.MostrarSkuArticulo(
  const ACodArt: string): Boolean;
begin
  with FAnfitrion do
  begin
  Result := Assigned(FEditorLineas) and
    FEditorLineas.DebeMostrarSku(ACodArt);
  end;
end;

procedure TControladorFacturas.ActivarSkuArticuloLinea(
  const ACodArt: string; AEnfocar: Boolean);
var
  oCampoSku: TField;
begin
  with FAnfitrion do
  begin
  // Con un modo del contrato construido, la columna SKU es del modo
  // (o no existe): la eleccion de color/talla la resuelve su paleta.
  if FModoEntrada <> nil then
    Exit;
  if MostrarSkuArticulo(ACodArt) then
  begin
    ctbCODIGO_UNIDAD_FACTURA_LINEA.Visible := True;
    if AEnfocar and Assigned(dmmFacturas) and
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
            FAnfitrion.DesactivarEnterSku(
              FAnfitrion.tvLineasFactura);
            FAnfitrion.tvLineasFactura.Controller.FocusedColumn :=
              FAnfitrion.ctbCODIGO_UNIDAD_FACTURA_LINEA;
            FAnfitrion.tvLineasFactura.Controller.
              EditingController.ShowEdit;
            Edit := FAnfitrion.tvLineasFactura.Controller.
              EditingController.Edit;
            if Edit is TcxComboBox then
              (Edit as TcxComboBox).DroppedDown := True;
          end);
      end;
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
  if not FControlador.MostrarSkuArticulo(sArt) then
    AText := '';
end;

procedure TfrmMtoFacturasBase.tvLineasFacturaEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  // El SKU solo es editable cuando procede mostrarlo (variacion o nuevo).
  if (AItem = ctbCODIGO_UNIDAD_FACTURA_LINEA) and Assigned(dmmFacturas) then
  begin
    AAllow := FControlador.MostrarSkuArticulo(
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
  Resolver : IArticulosResolver;
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
    Resolver := CrearResolverArticulos(
      ConexionPrincipal);
    try
      Skus := Resolver.ListarSkus(CodArt);
      for Item in Skus do
        Combo.Properties.Items.Add(Item.CodigoSku);
    finally
      Resolver := nil;
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
  CodigoSku: string;
  Editor: TcxCustomEdit;
  Resultado: TResultadoEdicionLineaFactura;
begin
  if Assigned(FEditorLineas) and (Sender is TcxCustomEdit) then
  begin
    Editor := TcxCustomEdit(Sender);
    CodigoSku := Trim(VarToStr(Editor.EditingValue));
    if (CodigoSku = '') and (Editor is TcxCustomTextEdit) then
      CodigoSku := Trim(TcxCustomTextEdit(Editor).Text);
    if CodigoSku = '' then
      CodigoSku := Trim(VarToStr(Editor.EditValue));
    Resultado := FEditorLineas.AplicarEntrada(CodigoSku);
    if Resultado.Aplicado and (Resultado.CodigoSku <> '') and
       (VarToStr(Editor.EditValue) <> Resultado.CodigoSku) then
      Editor.EditValue := Resultado.CodigoSku;
    if Resultado.Aplicado then
      FControlador.ActivarSkuArticuloLinea(
        Resultado.CodigoArticulo,
        False);
  end;
end;

procedure TfrmMtoFacturasBase.
  ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
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
     form.Preparar(dmmFacturas);
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

procedure TfrmMtoFacturasBase.cbbSerieFacturaKeyUp(
  Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TControladorFacturas.cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sTarifa: string;
begin
  with FAnfitrion do
  begin
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
      end
      else
      begin
        ShowMessage(SErrorTarifaSeleccionadaNoEncontrada);
      end;
    end;
  end;
  end;
end;

procedure TControladorFacturas.ActualizarBloqueoEdicion;
var
  CampoFase: TField;
  Configuracion: TConfiguracionEstadoFiscalFactura;
  Controles: TControlesEstadoFiscalFactura;
begin
  with FAnfitrion do
  begin
  if Assigned(dmmFacturas) and
     (dsTablaG.DataSet <> nil) and
     dsTablaG.DataSet.Active then
  begin
    CampoFase := dsTablaG.DataSet.FindField(ffasefac);
    if CampoFase <> nil then
    begin
      Configuracion := CrearConfiguracionEstadoFiscalFactura(
        CampoFase.AsString,
        dsTablaG.DataSet.FieldByName(fescon).AsString = 'S',
        SinVerifactuActivo(ParametrosApp),
        dsTablaG.DataSet.IsEmpty,
        dsTablaG.DataSet.State);
      dmmFacturas.unqryLinFac.ReadOnly := not Configuracion.Editable;
      Controles := Default(TControlesEstadoFiscalFactura);
      Controles.DataSourceCabecera := dsTablaG;
      Controles.VistaLineas := tvLineasFactura;
      Controles.BotonConsolidar := btnConsolidar;
      Controles.BotonImprimir := btnImprimir;
      TPresentacionEstadoFiscalFactura.Aplicar(
        Configuracion,
        Controles);
    end;
  end;
  end;
end;

// dsTablaG apunta a la cabecera de factura, que no tiene CODIGO_ART_*.
// El articulo activo vive en la linea seleccionada del sub-grid
// tvLineasFactura. Leemos de ahi para que Ctrl+F muestre la foto
// de la linea actual.
function TfrmMtoFacturasBase.ContarHijosActivos: Integer;
var
  sNum, sSerie: string;
begin
  Result := 0;
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
    Exit;
  sNum   := dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  sSerie := dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  Result := inLibFacturas.ContarLineasFactura(
    ConexionPrincipal, sSerie, sNum);
end;

function TfrmMtoFacturasBase.DescripcionHijos: string;
begin
  Result := 'líneas de borrador';
end;

function TControladorFacturas.PuedeConsultarEstadoColaVerifactu: Boolean;
var
  Qry: TUniQuery;
begin
  with FAnfitrion do
  begin
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := ConexionPrincipal;
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
end;

procedure TControladorFacturas.CrearTablaPrincipal;
var
  sVista: string;
begin
  with FAnfitrion do
  begin
  dmmFacturas := TdmFacturas(AsegurarDataModuleDocumento(
    FAnfitrion, tdmDataModule, TdmFacturas));
  dmmFacturas.ConfigurarServicios(
    CrearServiciosFactura(
      ConexionPrincipal,
      TRepositorioFacturas.Create(
        ConexionPrincipal,
        CatalogoSqlAplicacion,
        IncidenciasSqlAplicacion),
      CrearResolverArticulos(ConexionPrincipal),
      CrearServicioVerifactuColaUniDAC(ConexionPrincipal)));
  dmmFacturas.OnResultadoOperacion := MostrarResultadoOperacion;
  dmmFacturas.OnResultadoBorrado := MostrarResultadoBorrado;
  dmmFacturas.OnAdvertencia := MostrarAdvertenciaFactura;
  dmmFacturas.OnValidacion := MostrarErrorValidacion;
  dmmFacturas.OnConfirmarBorrado := ConfirmarBorradoFactura;
  dmmFacturas.OnNuevaFactura := NuevaFacturaDesdeInsert;
  dmmFacturas.OnSeriesCambiadas := SeriesCambiadasDesdeDM;
  dmmFacturas.OnLinFacEstado := AplicarEdicionPreciosLinea;
  dmmFacturas.TipoFacturaDefecto := TipoFacturaFiltro;
  FreeAndNil(FEditorLineas);
  FEditorLineas := TEditorLineasFactura.Create(
    ConexionPrincipal,
    dmmFacturas.unqryTablaG,
    dmmFacturas.unqryLinFac,
    CrearValidadorArticulos(ConexionPrincipal),
    CrearResolverArticulos(ConexionPrincipal));
  ConfigurarTablaPrincipalDocumento(
    dmmFacturas, dsTablaG, tvLineasFactura,
    dmmFacturas.dsLinFac, [], pkFieldName,
    'NUMERO_FAC; SERIE_FAC');
  cbbSerieFactura.Properties.ListSource := dmmFacturas.dsSeries;
  cbbCanalIVA.Properties.ListSource := dmmFacturas.dsIvas;
  cbbFORMAPAGO.Properties.ListSource := dmmFacturas.dsFormasPago;
  cxgrdLineasFactura.OnEnter := cxgrdLineasFacturaEnter;
  // Contrato de entrada ColumnSKUcxGrid: Auto (desglose) por defecto;
  // F1 cicla los modos. La primera construccion se hace al abrir la
  // pantalla (antes era al entrar en el grid y hasta entonces se veian
  // las columnas del dfm).
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  FConstruyendoModo := False;
  if Assigned(dmmFacturas) and dmmFacturas.unqryLinFac.Active then
    ConstruirModoEntrada;
  cbbTARIFA_ARTICULOS_CLIENTES.Properties.ListSource := dmmFacturas.dsTarifas;
  cbbAlmacenFactura.Properties.ListSource := dmmFacturas.dsAlmacenesFac;
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
  FEditorLineas.VaciarCache;
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
          ' FROM ' + sVista + ' v ' +
          ' ORDER BY v.FECHA_FAC DESC, v.NUMERO_FAC DESC'
      else
        SQL.Text :=
          'SELECT v.*, '''' AS ESTADO_VFCOLA ' +
          ' FROM ' + sVista + ' v ' +
          ' ORDER BY v.FECHA_FAC DESC, v.NUMERO_FAC DESC';
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
end;

function TfrmMtoFacturasBase.NombreVistaListado: string;
begin
  Result := 'vi_facturas';
end;

procedure TControladorFacturas.EjecutarOperacionFiscal(
  const ATipoOperacion, AAccion: string);
var
  Contexto: TContextoOperacionFiscalFactura;
  Preparacion: TPreparacionOperacionFiscalFactura;
  Solicitud: TSolicitudEmisionFiscal;
  Resultado: TResultadoEmisionFiscal;
  Servicio: IServicioEmisionFiscal;
begin
  with FAnfitrion do
  begin
  Contexto := Default(TContextoOperacionFiscalFactura);
  Contexto.Serie :=
    dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  Contexto.Numero :=
    dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  Contexto.TipoFactura :=
    dsTablaG.DataSet.FieldByName(ftipofac).AsString;
  Contexto.TipoOperacion := ATipoOperacion;
  Contexto.Accion := AAccion;
  Contexto.Usuario := IdentidadSesion.Usuario;
  Contexto.Consolidada := dsTablaG.DataSet.FieldByName(
    'ESCONSOLIDADA_FAC').AsString = 'S';
  Preparacion := PrepararOperacionFiscalFactura(Contexto);
  if not Preparacion.EsValida then
    ShowMessage(Preparacion.MensajeError)
  else if MessageDlg(
            Preparacion.PreguntaConfirmacion,
            mtConfirmation,
            [mbYes, mbNo],
            0) = mrYes then
  begin
    Solicitud := CrearSolicitudOperacionFiscalFactura(Contexto);
    Servicio := CrearServicioEmisionFiscal(
      ParametrosApp,
      ParametrosCaja,
      ConexionPrincipal,
      CrearServicioVerifactuColaUniDAC(ConexionPrincipal));
    Resultado := Servicio.Emitir(Solicitud);
    ShowMessage(Resultado.Mensaje);
    dsTablaG.DataSet.Refresh;
  end;
  end;
end;

procedure TControladorFacturas.btnConsolidarClick(Sender: TObject);
var
  bConsolidada: Boolean;
  sSerie: string;
  sNumero: string;
  Preparacion: TPreparacionConsolidacionFactura;
  Resultado: TResultadoConsolidacionFactura;
  Validacion: TResultadoOperacionFactura;
  Servicio: IServicioConsolidacionFactura;
  ServicioEmision: IServicioEmisionFiscal;
  ServicioMovimientos: IServicioMovimientosFactura;
begin
  with FAnfitrion do
  begin
  bConsolidada := False;
  if (dsTablaG.DataSet = nil) or
     (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage(SErrorBorradorListaNoSeleccionado);
    Abort;
  end;
  sSerie  := dsTablaG.DataSet.FieldByName(fseriefac).AsString;
  sNumero := dsTablaG.DataSet.FieldByName(fnrofac).AsString;
  ServicioEmision := CrearServicioEmisionFiscal(
    ParametrosApp,
    ParametrosCaja,
    ConexionPrincipal, CrearServicioVerifactuColaUniDAC(ConexionPrincipal));
  ServicioMovimientos :=
    TServicioMovimientosFactura.Create(ConexionPrincipal);
  Servicio := CrearServicioConsolidacionFactura(
    ConexionPrincipal,
    ServicioEmision,
    ServicioMovimientos);
  Validacion := Servicio.Validar(sSerie, sNumero);
  Preparacion := PrepararConsolidacionFactura(
    Validacion,
    sSerie,
    sNumero);
  if not Preparacion.EsValida then
    ShowMessage(Preparacion.MensajeError)
  else if MessageDlg(Preparacion.PreguntaConfirmacion, mtConfirmation,
                     [mbYes, mbNo], 0) =
          mrYes then
  begin
    try
      Resultado := Servicio.Consolidar(
        sSerie,
        sNumero,
        IdentidadSesion.Usuario);
      bConsolidada := True;
    except
      on E: EConsolidacionFactura do
        ShowMessage(E.Message);
    end;
    if bConsolidada then
    begin
      dsTablaG.DataSet.Refresh;
      if dmmFacturas.unqryMovimientosFac.Active then
        dmmFacturas.unqryMovimientosFac.Refresh;
      try
        TfrmPrintFac.ArchivarFacturaConsolidada(
          dmmFacturas,
          sSerie,
          sNumero);
      except
        on E: Exception do
          Log.LogError('No se pudo archivar el PDF al consolidar ' +
            sSerie + '\' + sNumero + ': ' + E.Message);
      end;
      ShowMessage(Resultado.MensajeFiscal);
    end;
  end;
  end;
end;

procedure TControladorFacturas.btnVolverBorradorClick(Sender: TObject);
var
  sSerie: string;
  sNumero: string;
  Validacion: TResultadoOperacionFactura;
  Servicio: IServicioReaperturaBorrador;
begin
  with FAnfitrion do
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
    ShowMessage(SErrorBorradorListaNoSeleccionado);
    Abort;
  end;
  sSerie  := dsTablaG.DataSet.FieldByName(fseriefac).AsString;
  sNumero := dsTablaG.DataSet.FieldByName(fnrofac).AsString;
  Servicio := CrearServicioReaperturaBorrador(
    ParametrosApp,
    ParametrosCaja,
    ConexionPrincipal);
  Validacion := Servicio.Validar(sSerie, sNumero);
  if not Validacion.Exito then
    ShowMessage(Validacion.Mensaje)
  else if MessageDlg(Format(SPreguntaDevolverBorrador, [sSerie, sNumero]),
                     mtConfirmation, [mbYes, mbNo], 0) =
          mrYes then
  begin
    try
      Servicio.Reabrir(
        sSerie,
        sNumero,
        IdentidadSesion.Usuario);
      dsTablaG.DataSet.Refresh;
      ShowMessage(Format(SInfoBorradorReabierto, [sSerie, sNumero]));
    except
      on E: EReaperturaBorrador do
        ShowMessage(E.Message);
    end;
  end;
  end;
end;

procedure TfrmMtoFacturasBase.btnVerifactuAnularClick(Sender: TObject);
begin
  // Anulación fiscal de la factura activa según modo Verifactu.
  EjecutarOperacionFiscal('ANULACION', 'Anulación');
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
    ShowMessage(SErrorBorradorListaNoSeleccionado)
  else if not SameText(dsTablaG.DataSet.FieldByName(
                         'TIPO_FAC').AsString, 'SIMPLIFICADA') then
    ShowMessage(SErrorFacturarTicketRequiereSimplificado)
  else
  begin
    oRes := TfrmModalFacturarTicket.Ejecutar(Self, sSerie, sNumero,
              dsTablaG.DataSet.FieldByName('CODIGO_EMP_FAC').AsString,
              dsTablaG.DataSet.FieldByName('CODIGO_ALM_FAC').AsString,
              dsTablaG.DataSet.FieldByName('FECHA_FAC').AsDateTime);
    if oRes.Aceptado then
    begin
      ShowMessage(Format(SInfoBorradorSustitucionTicketCreado,
                         [oRes.SerieNueva, oRes.NumeroNueva,
                          sSerie, sNumero,
                          ModoVerifactuTexto(ParametrosApp)]));
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

procedure TControladorFacturas.AplicarVisibilidadColumnasCreacion(
  ACrear: Boolean);
begin
  with FAnfitrion do
  begin
  ctbCODIGO_FAMILIA_FACTURA_LINEA.Visible        := ACrear;
  ctbNOMBRE_FAMILIA_FACTURA_LINEA.Visible        := ACrear;
  ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA.Visible  := ACrear;
  ctbCODIGO_PROVEEDOR_FACTURA_LINEA.Visible      := ACrear;
  ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA.Visible := ACrear;
  ctbPRECIO_ULT_COMPRA_FACTURA_LINEA.Visible     := ACrear;
  end;
end;

function TControladorFacturas.ModoCreacionActivo: Boolean;
begin
  with FAnfitrion do
  begin
  // El modo creacion vive en la cabecera (ESCREARARTICULOS_FAC). Se lee del
  // dataset activo para que cada factura tenga el suyo, no el ultimo check.
  Result := (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
            (dsTablaG.DataSet.FindField(fcreart) <> nil) and
            (dsTablaG.DataSet.FieldByName(fcreart).AsString = 'S');
  end;
end;

procedure TControladorFacturas.SincronizarColumnasCreacion;
begin
  AplicarVisibilidadColumnasCreacion(ModoCreacionActivo);
end;

procedure TControladorFacturas.SincronizarColumnaSku;
var
  i        : Integer;
  dc       : TcxCustomDataController;
  bMostrar : Boolean;
begin
  with FAnfitrion do
  begin
  // Con un modo del contrato construido, la columna SKU es del modo.
  if FModoEntrada <> nil then
    Exit;
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
end;

procedure TControladorFacturas.ReaplicarVisibilidadDetalle;
begin
  with FAnfitrion do
  begin
  // Durante la reconstruccion del modo las columnas ctb* estan muertas
  // (ClearItems) hasta que CrearColumnasHostFactura las reasigna.
  if FConstruyendoModo then
    Exit;
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
end;

procedure TControladorFacturas.ActualizarLabelPrendas;
begin
  with FAnfitrion do
  begin
  if not FActualizandoLabelPrendas then
  begin
    FActualizandoLabelPrendas := True;
    try
      if Assigned(dmmFacturas) then
        lblTotalPrendasFactura.Caption := TextoTotalPrendasDocumento(
          dmmFacturas.unqryTablaG, dmmFacturas.TotalPrendasFactura)
      else
        lblTotalPrendasFactura.Caption := '0';
    finally
      FActualizandoLabelPrendas := False;
    end;
  end;
  end;
end;

procedure TfrmMtoFacturasBase.AplicarEtiquetas;
begin
  inherited;
  // inherited -> PonerAnchosTitulos repuso la visibilidad de las columnas
  // desde el perfil (por defecto visibles). Reimponemos nuestras reglas.
  FControlador.ReaplicarVisibilidadDetalle;
  AplicarOrigenCobros;
end;

procedure TfrmMtoFacturasBase.dsLinFacDataChange(Sender: TObject;
                                                 Field: TField);
begin
  // Field = nil: cambio de registro de linea, recarga del detalle (al navegar
  // de factura) o alta/baja de linea. Re-evaluamos la visibilidad del detalle.
  if Field = nil then
  begin
    FControlador.ReaplicarVisibilidadDetalle;
    // Alta/baja/edicion de linea cambia el total de prendas. Con la
    // linea a medio insertar/editar no se recalcula (el recorrido esta
    // ademas vetado en TotalPrendasLineasVenta): se refresca en el
    // DataChange del Post.
    if (dmmFacturas = nil) or
       (not (dmmFacturas.unqryLinFac.State in dsEditModes)) then
      FControlador.ActualizarLabelPrendas;
  end;
end;

procedure TfrmMtoFacturasBase.chkCrearArticulosPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if FConstruyendoModo then
    Exit;
  // Con la presentacion reconstruida, alternar el modo creacion cambia
  // entre la presentacion CLASICA (alta de articulos inline) y el
  // contrato: se reconstruye entera.
  if FColsModoConstruido then
  begin
    ConstruirModoEntrada;
    Exit;
  end;
  FControlador.AplicarVisibilidadColumnasCreacion(
    chkCrearArticulos.Checked);
  // En modo creacion el SKU hace falta para los articulos nuevos: lo
  // mostramos ya. Al desactivarlo, recalculamos por si alguna linea con
  // variacion lo sigue necesitando.
  if chkCrearArticulos.Checked then
    ctbCODIGO_UNIDAD_FACTURA_LINEA.Visible := True
  else
    FControlador.SincronizarColumnaSku;
end;

procedure TControladorFacturas.chkDescripcion_ampliadaPropertiesChange(
  Sender: TObject);
begin
  with FAnfitrion do
  begin
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

procedure TControladorFacturas.dsTablaGStateChange(Sender: TObject);
begin
  with FAnfitrion do
  begin
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
      btnImprimir.Enabled := SinVerifactuActivo(ParametrosApp);
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
end;

procedure TControladorFacturas.dsTablaGDataChange(Sender: TObject;
                                                 Field: TField);
var
  bClasicoNecesario: Boolean;
  bClasicoConstruido: Boolean;
begin
  with FAnfitrion do
  begin
  if ((Field = nil) or SameText(Field.FieldName, 'CODIGO_EMP_FAC')) and
     Assigned(dmmFacturas) and dmmFacturas.unqryTablaG.Active and
     (not dmmFacturas.unqryTablaG.IsEmpty) then
    dmmFacturas.RefrescarAlmacenes(
      dmmFacturas.unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString);
  // Field = nil: cambio de registro (scroll) o refresco completo
  if Field = nil then
  begin
    ActualizarBloqueoEdicion;
    // Cada factura lleva su propio modo creacion: re-evaluamos al navegar.
    ReaplicarVisibilidadDetalle;
    // Al navegar entre facturas hay que recalcular el total de prendas:
    // las lineas cargadas son las de la factura recien enfocada.
    ActualizarLabelPrendas;
    // Contrato de entrada: al navegar de factura, las lineas llegan
    // recargadas por el master-detail. Se reconstruye si cambia la
    // necesidad de presentacion clasica (modo creacion por cabecera) o
    // si el modo tallas debe re-pivotar su cache; en desglose basta
    // desempaquetar SKU->ATTR (leccion de inventarios/pedidos).
    if (not FConstruyendoModo) and
       Assigned(dmmFacturas) and dmmFacturas.unqryLinFac.Active and
       (not (dsTablaG.State in dsEditModes)) then
    begin
      // Red de seguridad: con la apertura asincrona el detail aun no
      // estaba abierto en el FormCreate y la construccion inicial se
      // saltaba; el desglose por defecto (mcsAuto) no aparecia hasta
      // pisar el grid o pulsar F1. La primera navegacion construye.
      if not FColsModoConstruido then
        ConstruirModoEntrada
      else
      begin
        bClasicoNecesario := ModoCreacionSolicitado;
        bClasicoConstruido := FModoEntrada = nil;
        if (bClasicoNecesario <> bClasicoConstruido) or
           ((not bClasicoNecesario) and
            (FModoEntradaSel = mcsTallasHorPed)) then
          ConstruirModoEntrada
        else if (FModoEntrada <> nil) and (FModoEntradaSel <> mcsSku)
        then
          dmmFacturas.DesempaquetarAtributosLineas;
      end;
    end;
  end;
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
  ShowMtoCodigoDataSet(Self.Owner, 'Clientes',
    cxGrdDBTabPrin.DataController.DataSet,
    'CODIGO_CLI_FAC');
end;

procedure TfrmMtoFacturasBase.btnIrAEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Empresas',
    cxGrdDBTabPrin.DataController.DataSet,
    'CODIGO_EMP_FAC');
end;

procedure TfrmMtoFacturasBase.
                cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  inherited;
  if SinVerifactuActivo(ParametrosApp) or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    dmmFacturas.unqryArtDataLinFac.ParamByName('TARIFA').AsString :=
                                              dmmFacturas.unqryTablaG.FindField(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    dmmFacturas.unqryArtDataLinFac.ParamByName('FECHA_FAC').AsDateTime :=
                  dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime;
    if TBusquedaUtils.EjecutarBusqueda(
      ConexionPrincipal,
      'Búsqueda de Artículos en Lineas de ' +
                                                                   'Borradores',
                                       dmmFacturas.unqryArtDataLinFac,
                                       'frmMtoArtFacSearch') then
    begin
      dmmFacturas.CopiarArticuloaLinea(dmmFacturas.unqryArtDataLinFac);
      FControlador.ActivarSkuArticuloLinea(
        dmmFacturas.unqryLinFac.FieldByName('CODIGO_ART_FACLIN').AsString,
        True);
    end;
  end;
end;

procedure TfrmMtoFacturasBase.
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
var
  Edit: TcxCustomEdit;
  Input: string;
  Resultado: TResultadoEdicionLineaFactura;
begin
  inherited;
  if Assigned(FEditorLineas) and (Sender is TcxCustomEdit) then
  begin
    Edit := TcxCustomEdit(Sender);
    Input := Trim(VarToStr(Edit.EditingValue));
    if Input <> '' then
    begin
      Resultado := FEditorLineas.AplicarDesdeEditor(Input);
      if Resultado.Aplicado then
      begin
        FControlador.ActivarSkuArticuloLinea(
          Resultado.CodigoArticulo,
          Resultado.RequiereSku);
        if Resultado.RecalcularDesdeEditor then
          RecalcLineaFacturaSegura(Sender);
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.sbGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    CrearValidadorArticulos(
      dmmFacturas.unqryTablaG.Connection),
    dmmFacturas.unqryLinFac, 'FACLIN');
  if (sLineasSinSku <> '') and
     (MessageDlg(Format(SPreguntaGrabarFacturaVentaSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  inLibFacturas.GuardarCambiosPendientesFactura(
    dmmFacturas.unqryTablaG.Connection,
    dmmFacturas.unqryTablaG,
    dmmFacturas.dsLinFac.DataSet,
    dmmFacturas.dsRecibos.DataSet);
  if dmmFacturas.dsRecibos.DataSet.Active then
    dmmFacturas.dsRecibos.DataSet.Refresh;
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
            ShowMessage(Format(SErrorCompletarDatosBorrador, [E.Message]));
            Exit;
          end;
        end;
      end;
      tvLineasFactura.DataController.Insert;
    end;
  except
    on E: EInvalidOperation do
      // Solo el caso del editor inplace sin Parent; queda en el log.
      inLibLog.Log.LogWarning(
        'FacturasBase.tvLineasFacturaKeyDown: EInvalidOperation ' +
        'ignorada: ' + E.Message);
  end;
end;

function TControladorFacturas.AsegurarCabeceraPersistidaParaLineas: Boolean;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
begin
  with FAnfitrion do
  begin
  Result := False;
  if Assigned(dmmFacturas) then
  begin
    dsCab := dmmFacturas.unqryTablaG;
    dsLin := dmmFacturas.unqryLinFac;
    if (dsCab <> nil) and dsCab.Active and
       ((not dsCab.IsEmpty) or (dsCab.State in dsEditModes)) then
    begin
      Result := True;
      if dsCab.State in dsEditModes then
      begin
        try
          dsCab.Post;
        except
          on E: Exception do
          begin
            Result := False;
            ShowMessage(Format(SErrorCompletarDatosBorrador, [E.Message]));
          end;
        end;
      end;
      if Result and Assigned(dsLin) and dsLin.Active and
         (not (dsLin.State in dsEditModes)) then
      begin
        dsLin.Close;
        dsLin.Open;
      end;
    end;
  end;
  end;
end;

procedure TControladorFacturas.AsegurarPrimeraLineaFacturaBorrador;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
  sFase: string;
begin
  with FAnfitrion do
  begin
  if not Assigned(dmmFacturas) then
    Exit;
  dsCab := dmmFacturas.unqryTablaG;
  dsLin := dmmFacturas.unqryLinFac;
  if (dsCab = nil) or (dsLin = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    Exit;
  if not AsegurarCabeceraPersistidaParaLineas then
    Exit;
  sNumero := Trim(dsCab.FieldByName('NUMERO_FAC').AsString);
  sSerie  := Trim(dsCab.FieldByName('SERIE_FAC').AsString);
  if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
    Exit;
  sFase := '';
  if dsCab.FindField('FASE_FAC') <> nil then
    sFase := Trim(dsCab.FieldByName('FASE_FAC').AsString);
  if (sFase <> '') and (not SameText(sFase, 'BORRADOR')) then
    Exit;
  if dsCab.State in dsEditModes then
    Exit;
  if not dsLin.Active then
    dsLin.Open;
  if dsLin.IsEmpty and (not (dsLin.State in dsEditModes)) then
    dsLin.Append;
end;

end;

procedure TfrmMtoFacturasBase.cxgrdLineasFacturaEnter(Sender: TObject);
begin
  FControlador.AsegurarPrimeraLineaFacturaBorrador;
  // Contrato de entrada: primera construccion al entrar en el grid (las
  // lineas ya estan abiertas como detail de la factura). El teardown
  // cancela la linea vacia auto-anadida: se recrea despues.
  if not FColsModoConstruido then
  begin
    ConstruirModoEntrada;
    FControlador.AsegurarPrimeraLineaFacturaBorrador;
  end;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoFacturasBase.CambiarIVA;
begin
  if (dsTablaG.DataSet.State = dsInsert) then
    dmmFacturas.AsignarIVA(
        dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString,
        dmmFacturas.unqryTablaG);
end;

procedure TControladorFacturas.RecalcLineaFacturaSegura(Sender: TObject);
begin
  with FAnfitrion do
  begin
  try
    GridRecalc(ConexionPrincipal, Sender,
               tvLineasFactura,
               dmmFacturas.unqryLinFac,
               dmmFacturas.unqryTablaG,
               nil,
               arfSoloLinea);
    dmmFacturas.MarcarRecalculoFacturaPendiente;
  except
    on E: EInvalidOperation do
      // Editor inplace de cxGrid sin Parent durante transicion de celda.
      // GridRecalc ya valida Edit.Parent, pero el FocusedColumn / refresh
      // posterior puede disparar el mismo error en carrera.
      inLibLog.Log.LogWarning(
        'FacturasBase.RecalcLineaFacturaSegura: EInvalidOperation ' +
        'ignorada: ' + E.Message);
  end;
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

procedure TfrmMtoFacturasBase.
  tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
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

procedure TfrmMtoFacturasBase.
  ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
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

// ===========================================================================
// CONTRATO DE ENTRADA ColumnSKUcxGrid (Auto / SKU / Tallas horizontal + F1)
// ===========================================================================

function TControladorFacturas.ModoCreacionSolicitado: Boolean;
begin
  with FAnfitrion do
  begin
  // El alta de articulos inline (Crear/Act Articulo) necesita la
  // presentacion clasica: el contrato rechaza articulos inexistentes.
  Result := ModoCreacionActivo or
            (Assigned(chkCrearArticulos) and chkCrearArticulos.Checked);
  end;
end;

procedure TfrmMtoFacturasBase.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcPantalla.ActivePage = tsFicha) and
    (pcDetail.ActivePage = tsLineasFactura) and
    (not FControlador.ModoCreacionSolicitado), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasHorPed], ConstruirModoEntrada);
  inherited;
end;

procedure TControladorFacturas.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  ds: TDataSet;
  bClasico: Boolean;
begin
  with FAnfitrion do
  begin
  if (dmmFacturas = nil) or (csDestroying in ComponentState) then
    Exit;
  ds := dmmFacturas.unqryLinFac;
  if not ds.Active then
    Exit;
  bClasico := ModoCreacionSolicitado;
  FConstruyendoModo := True;
  // dsLinFacStateChange (DM) y dsLinFacDataChange tocan columnas ctb*
  // que mueren en el ClearItems: se desenganchan durante el rebuild.
  dmmFacturas.dsLinFac.OnStateChange := nil;
  dmmFacturas.dsLinFac.OnDataChange := nil;
  try
    DesmontarModoEntradaDocumento(tvLineasFactura, ds, FModoEntrada);
    // El flag ANTES del Construir: si algo aborta a medias, nadie debe
    // tocar las columnas del dfm, muertas en el ClearItems.
    FColsModoConstruido := True;
    if bClasico then
    begin
      // Presentacion CLASICA (modo creacion de articulos): articulo +
      // SKU con sus handlers legacy + columnas propias del documento.
      CrearColumnasHostFactura(True);
      tvLineasFactura.OnInitEdit := tvLineasFacturaInitEdit;
      tvLineasFactura.OnEditKeyDown := tvLineasFacturaEditKeyDown;
      tvLineasFactura.OnEditing := tvLineasFacturaEditing;
      tsLineasFactura.Caption := SCaptionTabLineasBorradorClasico;
    end
    else
    begin
      // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
      // (columnas reales _FACLIN; idempotente por linea).
      if FModoEntradaSel <> mcsSku then
        dmmFacturas.DesempaquetarAtributosLineas;
      Cfg := CrearConfigColumnasSkuDocumento(
        dmmFacturas.unqryTablaG.Connection, ContextoSesion,
        tvLineasFactura, ds, FModoEntradaSel, '', 'FACLIN');
      Cfg.ValidadorArticulos :=
        CrearValidadorArticulos(Cfg.Conexion);
      Cfg.LookupAtributos :=
        CrearLookupAtributosArticulos(Cfg.Conexion);
      if dmmFacturas.unqryTablaG.FindField(
        'CODIGO_ALM_FAC') <> nil then
        Cfg.AlmacenStock := Trim(
          dmmFacturas.unqryTablaG.FieldByName(
            'CODIGO_ALM_FAC').AsString);
      // La venta mayor factura tambien articulos fuera de catalogo:
      // el modo acepta el codigo tecleado como linea libre (sin SKU).
      Cfg.AceptarNoCatalogo := EsVentaMayorNormal;
      Cfg.Campos.Almacen := '';
      // Precio por SKU para la consolidacion VISUAL del modo tallas:
      // filas con precio distinto no fusionan.
      Cfg.ObtenerPrecioSku := PrecioSkuTallas;
      if FModoEntradaSel = mcsTallasHorPed then
      begin
        CfgPV := Default(TGridPivoteVentaConfig);
        CfgPV.Conexion := dmmFacturas.unqryTablaG.Connection;
        CfgPV.Usuario := IdentidadSesion.Usuario;
        CfgPV.SourceMaster := dsTablaG;
        CfgPV.SourceLineas := dmmFacturas.dsLinFac;
        CfgPV.FieldSerieMaster := 'SERIE_FAC';
        CfgPV.FieldNumeroMaster := 'NUMERO_FAC';
        CfgPV.FieldLinea := 'LINEA_FACLIN';
        CfgPV.FieldArt := 'CODIGO_ART_FACLIN';
        CfgPV.FieldSku := 'CODIGO_UNIDAD_FACLIN';
        CfgPV.FieldDescripcion := 'DESCRIPCION_ARTICULO_FACLIN';
        CfgPV.FieldTipoCantidad := 'TIPO_CANTIDAD_ARTICULO_FACLIN';
        // Factura: UNA sola cantidad por linea -> banda unica.
        CfgPV.FieldCantidadPedida := 'CANTIDAD_FACLIN';
        CfgPV.FieldCantidadEntregada := '';
        CfgPV.FieldCantidadAAlbaranar := '';
        CfgPV.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN';
        CfgPV.FieldAlmacen := '';
        CfgPV.FieldAlmacenMaster := '';
        CfgPV.MaxColumnas := 20;
        CfgPV.BandaUnica := True;
        CfgPV.Repositorio := CrearRepositorioPivoteVenta(
                               CfgPV.Conexion, CfgPV.Usuario);
        CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
        CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
        FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
      end
      else
        FModoEntrada := CrearModoEntradaGrid(Cfg);
      // SIEMPRE primero el bloque del modo (articulo/color/tallas o
      // SKU) y detras las columnas del documento: queda Nro | Articulo
      // | Color | Cantidad/tallas | Descripcion | precios | totales.
      // El pivote publica sus Values[] no-bound en diferido, asi que
      // crear las columnas del host despues no los pisa.
      ConstruirModoEntradaDocumento(FModoEntrada, ModoEntradaResuelto,
        DesactivarEnterAsTabTemporal, RestaurarEnterAsTabTemporal,
        FModoEntradaSel, [], '');
      CrearColumnasHostFactura(False);
      case DetectarModoColumnasSku(Cfg) of
        mcsSku:
          tsLineasFactura.Caption := SCaptionTabLineasBorradorSku;
        mcsTallasHorPed:
          PivoteVentaBandaCambiada(bpvPedida);
      else
        begin
          tsLineasFactura.Caption :=
            SCaptionTabLineasBorradorDesglose;
          MostrarColumnasAtributoGlobalesDocumento(
            dmmFacturas.unqryTablaG.Connection,
            tvLineasFactura);
        end;
      end;
    end;
  finally
    FConstruyendoModo := False;
    dmmFacturas.dsLinFac.OnDataChange := dsLinFacDataChange;
    dmmFacturas.dsLinFac.OnStateChange := dmmFacturas.dsLinFacStateChange;
  end;
  // Reglas de visibilidad e ImpIncl sobre las columnas recreadas.
  ReaplicarVisibilidadDetalle;
  dmmFacturas.dsLinFacStateChange(dmmFacturas.dsLinFac);
  end;
end;

procedure TControladorFacturas.CrearColumnasHostFactura(AClasico: Boolean);
var
  Columnas: TColumnasFactura;
  Configuracion: TConfiguracionColumnasFactura;
begin
  with FAnfitrion do
  begin
  Configuracion := Default(TConfiguracionColumnasFactura);
  Configuracion.Vista := tvLineasFactura;
  Configuracion.DataSourceIvas := dmmFacturas.dsIvasTipos;
  Configuracion.Clasico := AClasico;
  Configuracion.Tallas :=
    (not AClasico) and (FModoEntradaSel = mcsTallasHorPed);
  Configuracion.Simplificada :=
    SameText(TipoFacturaFiltro, 'SIMPLIFICADA');
  Configuracion.CrearArticulos := ModoCreacionSolicitado;
  Configuracion.DescripcionAmpliada :=
    chkDescripcion_ampliada.Checked;
  Configuracion.MostrarFechaEntrega := chkFechaEntrega.Checked;
  Columnas := CrearColumnasFactura(Configuracion);
  ctbLINEA_FACTURA_LINEA := Columnas.Linea;
  ctbCODIGO_ARTICULO_FACTURA_LINEA := Columnas.Articulo;
  ctbCODIGO_UNIDAD_FACTURA_LINEA := Columnas.Sku;
  ctbCODIGO_FAMILIA_FACTURA_LINEA := Columnas.CodigoFamilia;
  ctbNOMBRE_FAMILIA_FACTURA_LINEA := Columnas.NombreFamilia;
  ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA :=
    Columnas.EsProveedorPrincipal;
  ctbCODIGO_PROVEEDOR_FACTURA_LINEA := Columnas.CodigoProveedor;
  ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA :=
    Columnas.RazonSocialProveedor;
  ctbPRECIO_ULT_COMPRA_FACTURA_LINEA := Columnas.PrecioUltimaCompra;
  ctbDESCRIPCION_ARTICULO_FACTURA_LINEA :=
    Columnas.DescripcionArticulo;
  ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA := Columnas.TipoCantidad;
  ctbCANTIDAD_FACTURA_LINEA := Columnas.Cantidad;
  ctbPRECIOSALIDA_FACTURA_LINEA := Columnas.PrecioSalida;
  ctbPORCEN_DTO_FACTURA_LINEA := Columnas.PorcentajeDescuento;
  ctbPRECIO_DTO_FACTURA_LINEA := Columnas.PrecioDescuento;
  ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA :=
    Columnas.PrecioVentaSinIva;
  ctbIMP_INCL_TARIFA_FACTURA_LINEA := Columnas.ImpuestosIncluidos;
  ctbTIPOIVA_ARTICULO_FACTURA_LINEA := Columnas.TipoIva;
  ctbPORCEN_IVA_FACTURA_LINEA := Columnas.PorcentajeIva;
  ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA :=
    Columnas.PrecioVentaConIva;
  ctbTOTAL_FACTURA_LINEA := Columnas.TotalConIva;
  ctbTOTAL_FACTURASIVA_LINEA := Columnas.TotalSinIva;
  ctbFECHA_ENTREGA_FACTURA_LINEA := Columnas.FechaEntrega;
  if AClasico then
  begin
    with TcxButtonEditProperties(
      ctbCODIGO_ARTICULO_FACTURA_LINEA.Properties) do
    begin
      OnButtonClick :=
        cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick;
      OnEditValueChanged :=
        cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged;
    end;
    with TcxComboBoxProperties(
      ctbCODIGO_UNIDAD_FACTURA_LINEA.Properties) do
    begin
      OnInitPopup := ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup;
      OnCloseUp := ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesCloseUp;
      OnEditValueChanged :=
        ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged;
    end;
    ctbCODIGO_UNIDAD_FACTURA_LINEA.OnGetDataText :=
      ctbCODIGO_UNIDAD_FACTURA_LINEAGetDataText;
  end;
  if Assigned(ctbCANTIDAD_FACTURA_LINEA) then
    TcxSpinEditProperties(ctbCANTIDAD_FACTURA_LINEA.Properties).
      OnEditValueChanged :=
        cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(ctbPRECIOSALIDA_FACTURA_LINEA.Properties).
    OnEditValueChanged :=
      tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged;
  TcxSpinEditProperties(ctbPORCEN_DTO_FACTURA_LINEA.Properties).
    OnEditValueChanged :=
      tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(ctbPRECIO_DTO_FACTURA_LINEA.Properties).
    OnEditValueChanged :=
      tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(
    ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA.Properties).
      OnEditValueChanged :=
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxLookupComboBoxProperties(ctbTIPOIVA_ARTICULO_FACTURA_LINEA.Properties).
    OnChange :=
      cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange;
  TcxCurrencyEditProperties(
    ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA.Properties).
      OnEditValueChanged :=
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(ctbTOTAL_FACTURASIVA_LINEA.Properties).
    OnEditValueChanged :=
      ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged;
  end;
end;

procedure TfrmMtoFacturasBase.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo fiscal clasico de la factura (tarifa del cliente, IVA,
  // dtos, precios y totales) se reaprovecha tal cual:
  // AplicarArticuloFactura acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloFactura(ASku)
  else if ACompleto and (ACodArt <> '') then
    // ASku vacio con resolucion completa = codigo fuera de catalogo
    // aceptado por el modo (AceptarNoCatalogo): linea libre.
    AplicarLineaNoCatalogo(ACodArt);
end;

procedure TfrmMtoFacturasBase.AplicarArticuloFactura(
  const AEntrada: string);
begin
  if Assigned(FEditorLineas) then
    FEditorLineas.AplicarEntrada(AEntrada);
end;

procedure TfrmMtoFacturasBase.AplicarLineaNoCatalogo(const ACodArt: string);
begin
  if Assigned(FEditorLineas) then
    FEditorLineas.AplicarLineaNoCatalogo(ACodArt);
end;

procedure TfrmMtoFacturasBase.MostrarResultadoOperacion(
  const AResultado: TResultadoOperacionFactura);
begin
  if (not AResultado.Exito) and
     (AResultado.Mensaje <> '') then
  begin
    ShowMessage(AResultado.Mensaje);
  end;
end;

procedure TfrmMtoFacturasBase.MostrarResultadoBorrado(
  const AResultado: TResultadoBorradoFactura);
begin
  if (not AResultado.Permitido) and
     (AResultado.Mensaje <> '') then
  begin
    ShowMessage(AResultado.Mensaje);
  end;
end;

procedure TfrmMtoFacturasBase.MostrarAdvertenciaFactura(
  const AMensaje: string);
begin
  if AMensaje <> '' then
    ShowMessage(AMensaje);
end;

function TfrmMtoFacturasBase.ConfirmarBorradoFactura(
  const ASerie, ANumero: string): Boolean;
begin
  Result :=
    MessageDlg(
      Format(SPreguntaBorrarFactura, [ASerie, ANumero]),
      mtConfirmation,
      [mbYes, mbNo],
      0) = mrYes;
end;

procedure TfrmMtoFacturasBase.MostrarErrorValidacion(
  const AError: EValidacionFactura);
begin
  ShowMessage(AError.Message);
  SenalarCampoValidacion(AError.Campo);
end;

procedure TControladorFacturas.SenalarCampoValidacion(
  ACampo: TCampoValidacionFac);
begin
  with FAnfitrion do
  begin
  case ACampo of
    cvfNinguno:
    begin
    end;
    cvfSerie:
    begin
      pcCab.ActivePage := tsCabecera;
      if cbbSerieFactura.CanFocus then
        cbbSerieFactura.SetFocus;
    end;
    cvfRazonSocialCliente:
    begin
      pcCab.ActivePage := tsDatosCliente;
      if txtRAZONSOCIAL_CLIENTE_FACTURA.CanFocus then
        txtRAZONSOCIAL_CLIENTE_FACTURA.SetFocus;
    end;
    cvfRazonSocialEmpresa:
    begin
      pcCab.ActivePage := tsEmpresa;
      if txtRAZONSOCIAL_EMPRESA_FACTURA.CanFocus then
        txtRAZONSOCIAL_EMPRESA_FACTURA.SetFocus;
    end;
    cvfFecha:
      pcCab.ActivePage := tsCabecera;
    cvfNifCliente:
    begin
      pcCab.ActivePage := tsDatosCliente;
      if txtNIF_CLIENTE_FACTURA.CanFocus then
        txtNIF_CLIENTE_FACTURA.SetFocus;
    end;
    cvfNifEmpresa:
    begin
      pcCab.ActivePage := tsEmpresa;
      if txtNIF_EMPRESA_FACTURA.CanFocus then
        txtNIF_EMPRESA_FACTURA.SetFocus;
    end;
    cvfPais:
    begin
      pcCab.ActivePage := tsDatosCliente;
      if txtPAIS_CLIENTE_FACTURA1.CanFocus then
        txtPAIS_CLIENTE_FACTURA1.SetFocus;
    end;
    cvfOperacionFiscal:
    begin
      pcCab.ActivePage := tsCabecera;
      if cbbTipoOperVerifactu.CanFocus then
        cbbTipoOperVerifactu.SetFocus;
    end;
    cvfTipoIva:
      pcDetail.ActivePage := tsLineasFactura;
  end;
  end;
end;

procedure TControladorFacturas.NuevaFacturaDesdeInsert(Sender: TObject);
begin
  with FAnfitrion do
  begin
  sbNuevaFacturaClick(Sender);
  end;
end;

procedure TControladorFacturas.SeriesCambiadasDesdeDM(Sender: TObject);
begin
  with FAnfitrion do
  begin
  ActualizarComboSeries;
  end;
end;

procedure TControladorFacturas.AplicarEdicionPreciosLinea(Sender: TObject);
begin
  with FAnfitrion do
  begin
  if not Assigned(dmmFacturas) then
    Exit;
  with dmmFacturas.dsLinFac do
  begin
    if ((State = dsEdit) or (State = dsInsert) or (State = dsBrowse)) then
    begin
      // Factura con impuestos incluidos: solo es editable el c/IVA.
      if SameText(DataSet.FieldByName(fimpcl).AsString, 'S') then
      begin
        ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
          True;
        ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
          False;
        ctbTOTAL_FACTURASIVA_LINEA.Visible := False;
        ctbTOTAL_FACTURA_LINEA.Visible := True;
      end
      else
      begin
        ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
          True;
        ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
          False;
        ctbTOTAL_FACTURASIVA_LINEA.Visible := True;
        ctbTOTAL_FACTURA_LINEA.Visible := False;
      end;
    end;
  end;
  end;
end;

function TControladorFacturas.PrecioSkuTallas(const ACodigoArticulo,
  ACodigoSku: string): Double;
begin
  with FAnfitrion do
  begin
  Result := 0;
  if Assigned(FEditorLineas) then
    Result := FEditorLineas.PrecioSku(
      ACodigoArticulo,
      ACodigoSku);
  end;
end;

procedure TfrmMtoFacturasBase.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloFactura(ACodigoSku);
end;

procedure TfrmMtoFacturasBase.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  tsLineasFactura.Caption := SCaptionTabLineasBorradorTallasHoriz;
end;

procedure TfrmMtoFacturasBase.ActualizarBloqueoEdicion;
begin
  FControlador.ActualizarBloqueoEdicion;
end;

procedure TfrmMtoFacturasBase.AplicarEdicionPreciosLinea(
  Sender: TObject);
begin
  FControlador.AplicarEdicionPreciosLinea(Sender);
end;

procedure TfrmMtoFacturasBase.AplicarOrigenCobros;
begin
  FControlador.AplicarOrigenCobros;
end;

procedure TfrmMtoFacturasBase.
  btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FControlador.
    btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(Sender);
end;

procedure TfrmMtoFacturasBase.btnConsolidarClick(Sender: TObject);
begin
  FControlador.btnConsolidarClick(Sender);
end;

procedure TfrmMtoFacturasBase.btnGenerarRecibosClick(Sender: TObject);
begin
  inherited;
  FControlador.btnGenerarRecibosClick(Sender);
end;

procedure TfrmMtoFacturasBase.btnReciboPagadoClick(Sender: TObject);
begin
  inherited;
  FControlador.btnReciboPagadoClick(Sender);
end;

procedure TfrmMtoFacturasBase.btnVolverBorradorClick(Sender: TObject);
begin
  FControlador.btnVolverBorradorClick(Sender);
end;

procedure TfrmMtoFacturasBase.cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(
  Sender: TObject);
begin
  inherited;
  FControlador.cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(Sender);
end;

procedure TfrmMtoFacturasBase.chkDescripcion_ampliadaPropertiesChange(
  Sender: TObject);
begin
  inherited;
  FControlador.chkDescripcion_ampliadaPropertiesChange(Sender);
end;

procedure TfrmMtoFacturasBase.ConstruirModoEntrada;
begin
  FControlador.ConstruirModoEntrada;
end;

procedure TfrmMtoFacturasBase.CrearTablaPrincipal;
begin
  if not Assigned(FControlador) then
    FControlador := TControladorFacturas.Create(Self);
  InicializarDocumento(
    CrearConfiguracionDocumento(tdFactura, sdVenta));
  AsignarVistaLineasDocumento(tvLineasFactura);
  inherited;
  FControlador.CrearTablaPrincipal;
end;

procedure TfrmMtoFacturasBase.dsTablaGDataChange(
  Sender: TObject; Field: TField);
begin
  FControlador.dsTablaGDataChange(Sender, Field);
end;

procedure TfrmMtoFacturasBase.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  FControlador.dsTablaGStateChange(Sender);
end;

procedure TfrmMtoFacturasBase.EjecutarOperacionFiscal(
  const ATipoOperacion, AAccion: string);
begin
  FControlador.EjecutarOperacionFiscal(
    ATipoOperacion,
    AAccion);
end;

procedure TfrmMtoFacturasBase.GuardarPendienteAntesDeImprimir;
begin
  FControlador.GuardarPendienteAntesDeImprimir;
end;

procedure TfrmMtoFacturasBase.RecalcLineaFacturaSegura(
  Sender: TObject);
begin
  FControlador.RecalcLineaFacturaSegura(Sender);
end;

procedure TfrmMtoFacturasBase.sbImprimirClick(Sender: TObject);
begin
  inherited;
  FControlador.sbImprimirClick(Sender);
end;

procedure TfrmMtoFacturasBase.SenalarCampoValidacion(
  ACampo: TCampoValidacionFac);
begin
  FControlador.SenalarCampoValidacion(ACampo);
end;

procedure TfrmMtoFacturasBase.PcDetailChange(Sender: TObject);
begin
  if not Assigned(dmmFacturas) then Exit;
  // Despachador: cada sub-pestaña detail tiene su query lazy. Solo se
  // abre al activarse. Lineas (tsLineasFactura) se abre desde
  // AbrirDetalles por ser la pestaña por defecto y la mas usada.
  if pcDetail.ActivePage = tsRecibos then
  begin
    if FControlador.EsVentaMayorNormal then
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
