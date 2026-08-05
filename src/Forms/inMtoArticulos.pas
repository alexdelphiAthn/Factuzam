{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoArticulos                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de articulos.                                               }
{    Gestion de articulos con variaciones, atributos, propiedades y tarifas.   }
{******************************************************************************}
unit inMtoArticulos;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer, Generics.Collections,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  inMtoModalArticulosPropiedades,
  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataArticulos, inLibPerfilesUsuarioIntf,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, Vcl.DBCtrls, cxCheckComboBox, cxDBCheckComboBox,
  cxGroupBox, cxCheckGroup, cxDBCheckGroup, cxRadioGroup,
  dxScrollbarAnnotations, dxCore, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, cxButtonEdit, cxSplitter,
  cxDBExtLookupComboBox, cxListView, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  cxDBLabel, dxShellDialogs, inLibArticulosVariaciones, inMtoModalAceptCancel,
  cxCustomListBox, cxCheckListBox, System.UITypes, System.Types,
  inLibArticulosGuardadoIntf,
  inLibArticulosInyeccion,
  inLibArticulosCodigosBarrasPersistenciaIntf,
  inLibArticulosPresentacionIntf,
  inLibArticulosVariacionesIntf,
  inLibDestinoFacturaPersistenciaIntf,
  inLibPermisosIntf,
  inMtoArticulosPresentacionAtributos,
  inMtoArticulosPresentacionStock,
  inMtoArticulosPresentacionTarifas,
  inMtoArticulosPresentacionFiltros;

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
    dbcTarifasMARGEN: TcxGridDBColumn;
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
    dbcDESCRIPCION_FAM: TcxDBLabel;
    dbcNOMBRE_FAM_FAM: TcxDBLabel;
    tsGeneral: TcxTabSheet;
    rgTipoIVA: TcxDBRadioGroup;
    cxGroupBox2: TcxGroupBox;
    lblNombre1: TcxLabel;
    cbbTipoCantidad: TcxDBLookupComboBox;
    lblTipoArticulo: TcxLabel;
    cbbTIPO_ART: TcxDBComboBox;
    tvProveedoresREF_PROVEEDOR: TcxGridDBColumn;
    chkESVARIACION_ART: TcxDBCheckBox;
    tsSkuMto: TcxTabSheet;
    pnlTopSkus: TPanel;
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
    splSkuAtributosBasicos: TcxSplitter;
    gbSkuAtributosBasicos: TcxGroupBox;
    cxgrdSkuAtributosBasicos: TcxGrid;
    tvSkuAtributosBasicos: TcxGridDBTableView;
    tvSkuAtributosBasicosID_VA_AV: TcxGridDBColumn;
    tvSkuAtributosBasicosNOMBRE_ATRIBUTO: TcxGridDBColumn;
    tvSkuAtributosBasicosVALOR_AV: TcxGridDBColumn;
    tvSkuAtributosBasicosID_ATB_AV: TcxGridDBColumn;
    tvSkuAtributosBasicosDESCRIPCION_AAB: TcxGridDBColumn;
    tvSkuAtributosBasicosNOMBRE_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosHEX_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosVALOR_NUM_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosUNIDAD_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosETIQUETA_BASICO: TcxGridDBColumn;
    tvSkuAtributosBasicosFUENTE_ATB: TcxGridDBColumn;
    cxgrdSkuAtributosBasicosLevel: TcxGridLevel;
    tsSKUs: TcxTabSheet;
    pnlBotonesCB: TPanel;
    btnExportarExcelCB: TcxButton;
    cxgrdSkus: TcxGrid;
    tvSkus: TcxGridDBTableView;
    tvSkusCODIGO_UNIDAD_SKU: TcxGridDBColumn;
    tvSkusCODIGO_ARTICULO_SKU: TcxGridDBColumn;
    tvSkusESACTIVO_SKU: TcxGridDBColumn;
    tvSkusINSTANTEMODIF: TcxGridDBColumn;
    tvSkusINSTANTEALTA: TcxGridDBColumn;
    tvSkusUSUARIOALTA: TcxGridDBColumn;
    tvSkusUSUARIOMODIF: TcxGridDBColumn;
    cxgrdlvlSkus: TcxGridLevel;
    cxTabSheet3: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tvSkusCODIGO_BARRAS_CB: TcxGridDBColumn;
    tvSkusTIPO_CODIGO_CB: TcxGridDBColumn;
    tvSkusESPRINCIPAL_CB: TcxGridDBColumn;
    tvSkusID_CB: TcxGridDBColumn;
    tvSkusSTOCK_TOTAL: TcxGridDBColumn;
    btnGenerarCB: TcxButton;
    btnVerificarCB: TcxButton;
    cxGrdStock: TcxGrid;
    tvStock: TcxGridDBTableView;
    cxgrdlvlStock: TcxGridLevel;
    pnlBotonesTarifas: TPanel;
    btnStockExportarExcel: TcxButton;
    btnReconstruirStock: TcxButton;
    btnImprimirEtiquetas: TcxButton;
    cxGrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxgrdlvlStockAlt: TcxGridLevel;
    pnlBotonesStock: TPanel;
    btnExportarExcelStock: TcxButton;
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
    chkESTRAZABLE_ART: TcxDBCheckBox;
    tvTarifasCODIGO_UNIDAD_TARIFA: TcxGridDBColumn;
    tvTarifasESVARIACION_ARTICULO: TcxGridDBColumn;
    tvTarifasNUM_ATRIBUTOS_REQ: TcxGridDBColumn;
    btnAddSKU: TcxButton;
    btnColorSkus: TcxButton;
    pmColorSkus: TPopupMenu;
    miActivarColor: TMenuItem;
    miDesactivarColor: TMenuItem;
    tvLinFacNOMBRE_TIPO_IVA_IVATIP: TcxGridDBColumn;
    tvLinFacCODIGO_TAR_FACLIN: TcxGridDBColumn;
    tvLinFacPRECIO_SALIDA_FACLIN: TcxGridDBColumn;
    tvLinFacPORCENTAJE_DTO_FACLIN: TcxGridDBColumn;
    tvLinFacPRECIO_DTO_FACLIN: TcxGridDBColumn;
    tvLinFacTOTAL_FAC_SIVA_FACLIN: TcxGridDBColumn;
    tvLinFacCODIGO_CLIENTE_FACTURA_LINEA: TcxGridDBColumn;
    tvLinFacCODIGO_EMP_FACLIN: TcxGridDBColumn;
    tvLinFacFECHA_FAC: TcxGridDBColumn;
    tvLinFacNUMERO_FAC: TcxGridDBColumn;
    tvLinFacSERIE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_LIQUIDO_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_RETENCION_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_RETENCION_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IMPUESTOS_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASES_FAC: TcxGridDBColumn;
    tvLinFacFORMA_PAGO_FAC: TcxGridDBColumn;
    tvLinFacDESCRIPCION_FORMA_PAGO_FP: TcxGridDBColumn;
    tvLinFacCODIGO_EMP_FAC: TcxGridDBColumn;
    tvLinFacRAZON_SOCIAL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacNIF_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacMOVIL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacEMAIL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION1_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION2_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacPOBLACION_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacPROVINCIA_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacNOMBRE_PAI_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_POSTAL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacESRETENCIONES_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacGRUPO_ZONA_IVA_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacESREGIMENESPECIALAGRICOLA_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_CLI_FAC: TcxGridDBColumn;
    tvLinFacRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacNIF_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacMOVIL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacEMAIL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION1_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION2_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacPOBLACION_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacPROVINCIA_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacNOMBRE_PAI_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIVA_RECARGO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIVA_EXENTO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESREGIMENESPECIALAGRICOLA_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESRETENCIONES_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacTARIFA_ARTICULO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIMP_INCL_TARIFA_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESINTRACOMUNITARIO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIRPF_IMP_INCL_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacESAPLICA_RE_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacESIVAAGRICOLA_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacPALABRA_REPORTS_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_IVA_FAC: TcxGridDBColumn;
    tvLinFacESVENTA_ACTIVO_FIJO_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAN_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAN_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_REN_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_REN_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAN_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAR_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAR_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_RER_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_RER_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAR_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAS_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAS_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_RES_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_RES_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAS_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAE_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_REE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_REE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAE_FAC: TcxGridDBColumn;
    pnlFiltrosArt: TPanel;
    btnToggleFiltrosArt: TcxButton;
    pnlContFiltrosArt: TPanel;
    lblFiltroEstadoArt: TcxLabel;
    cbbFiltroEstadoArt: TcxComboBox;
    chkFiltroConStockArt: TcxCheckBox;
    lblFiltroTemporadaArt: TcxLabel;
    ccbFiltroTemporadaArt: TcxCheckComboBox;
    btnCargarAhoraArt: TcxButton;
    btnGuardarPrecargaArt: TcxButton;
    actFamilias: TAction;
    procedure btnToggleFiltrosArtClick(Sender: TObject);
    procedure cbbFiltroEstadoArtPropertiesEditValueChanged(Sender: TObject);
    procedure chkFiltroConStockArtPropertiesEditValueChanged(Sender: TObject);
    procedure ccbFiltroTemporadaArtPropertiesCloseUp(Sender: TObject);
    procedure btnCargarAhoraArtClick(Sender: TObject);
    procedure btnGuardarPrecargaArtClick(Sender: TObject);
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
    procedure btnStockExportarExcelClick(Sender: TObject);
    procedure btnReconstruirStockClick(Sender: TObject);
    procedure btnImprimirEtiquetasClick(Sender: TObject);
    procedure btnGenerarCBClick(Sender: TObject);
    procedure btnVerificarCBClick(Sender: TObject);
    procedure dbcTarifasMARGENButtonClick(Sender: TObject;
                                          AButtonIndex: Integer);
    procedure dbcTarifasMARGENGetDisplayText(
      Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AText: string);
    procedure tvSkuAtributosBasicosHEX_ATBCustomDrawCell(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesInitPopup(
      Sender: TObject);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesCloseUp(
      Sender: TObject);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesValidate(
      Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    procedure tvSkuAtributosBasicosHEX_ATBPropertiesButtonClick(
      Sender: TObject; AButtonIndex: Integer);
    procedure tvSkuAtributosBasicosDblClick(Sender: TObject);
    procedure tvSkuAtributosBasicosFUENTE_ATBGetDisplayText(
      Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AText: string);
    procedure tvSkuAtributosBasicosNOMBRE_ATBPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosVALOR_NUM_ATBPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosUNIDAD_ATBPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnColorSkusClick(Sender: TObject);
    procedure miActivarColorClick(Sender: TObject);
    procedure miDesactivarColorClick(Sender: TObject);
    procedure tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tvStockGetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
  private
     procedure BuscarProveedores;
     // Carga perezosa de la pestaña Tarifas: vi_articulos_tarifas tarda
     // ~6s por subqueries DEPENDENT. La abrimos solo cuando el usuario
     // pasa a tsTarifas (ver dmmArticulos.AsegurarTarifasAbiertas).
     procedure PcDetailChange(Sender: TObject);
     procedure AsegurarStockAlDia;
     procedure CerrarSiNoVisible(qry: TUniQuery; ActivaTarget: TcxTabSheet);
  private
    function  ObtenerFacturaLineaActiva(out ANumero,
                                        ASerie: string): Boolean;
    procedure AbrirFacturaLineaActiva(const ANumero,
                                      ASerie: string);
  public
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure TrasPrecargaAsync; override;
  private
    // Stock: ultimo articulo para el que se cargo el grid pivotado. Asi
    // AsegurarStockAlDia evita reejecutar el SP si el articulo no ha
    // cambiado desde la ultima visita a la pestaña Stock.
    FStockArticuloCargado: string;
    FGestorProp  : TGestorPropiedades;
    FArticuloCargado: string;
    FScrollProp  : TScrollBox;
    FBtnAddProp  : TcxButton;
    FGestorVar      : TGestorVariaciones;
    FPnlTopVariaciones:TPanel;
    FScrollVarAtrib : TScrollBox;
    FCbbTipoVariacion   : TcxDBLookupComboBox;
    // Colaboradores de presentacion. Cada uno recibe solo los controles,
    // datasets y puertos que necesita; ninguno conoce el formulario.
    FPresAtributos: TPresentadorAtributosBasicosArticulo;
    FPresStock: TPresentadorStockArticulo;
    FPresTarifas: TPresentadorTarifasArticulo;
    FPresFiltros: TPresentadorFiltrosArticulos;
    FCodigosBarras: ILecturaCodigosBarrasArticulo;
    FAplicacionGuardado: IAplicacionGuardadoArticulo;
    FDependencias: TContextoDependenciasArticulos;
    FCodigosBarrasPersistencia: IArticulosCodigosBarrasPersistencia;
    FResolutorDestinoFactura: IResolutorDestinoFactura;
    procedure InicializarPestanyaVariaciones;
    procedure InicializarPestanyaPropiedades;
    procedure InicializarPresentadores;
    procedure OnAfterScrollArticulos(DataSet: TDataSet);
    procedure BtnAddPropClick(Sender: TObject);
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasArticulos); reintroduce;
      overload;
    procedure ActualizarVisibilidadVariaciones;
    procedure ActualizarVisibilidadColumnaSku;
    procedure AsegurarSkuArticuloSinVariaciones(const aCodArticulo: string);
    procedure AsegurarSkuArticulo(const aCodArticulo: string);
    procedure CrearTablaPrincipal; override;
    procedure ResetForm;  override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
    // Recorre las columnas de tvStock y, para las que contienen valores que
    // casan con la paleta basica del articulo, añade ANCHO_SWATCH_PX al
    // ancho — necesario porque ApplyBestFit mide solo el texto y no el
    // cuadradito que pinta tvStockCustomDrawCell.
    procedure EnsancharColumnasStockParaSwatch;
  public
    // Data module de ESTA instancia (campo de instancia, no variable
    // global, asi no se pisa cuando hay dos Mtos Articulos abiertos a
    // la vez). Mismo patron que TfrmMtoFacturasBase.dmmFacturas.
    dmmArticulos: TdmArticulos;
  end;

implementation

uses
  inLibWin,
  inLibUser,
  inLibDevExp,
  inLibShowMto,
  inLibFotos,
  inLibGenBusq,
  inMtoModalGenerarSKUs,
  inMtoModalEtiqArt,
  inLibArticulosCodigosBarras,
  inLibArticulosAtributosBasicos,
  inLibArticulosAtributosBasicosIntf,
  inMtoArticulosGuardadoVcl,
  inLibArticulosVisibilidad,
  inLibArticulosPresentacion,
  UniDataArticulosAtributosBasicosRepositorio,
  UniDataArticulosPresentacionRepositorio,
  UniDataArticulosCodigosBarrasRepositorio,
  UniDataDestinoFacturaRepositorio,
  UniDataFiltroArticulosRepositorio,
  System.Diagnostics,   // TStopwatch
  inLibMsgArticulos, inLibMsgComun;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoArticulos.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasArticulos);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure InicializarGuardadoArticuloVcl(AFormulario: TfrmMtoArticulos);
var
  Callbacks: TCallbacksGuardadoArticulo;
  Operaciones: IOperacionesGuardadoArticulo;
begin
  Callbacks := Default(TCallbacksGuardadoArticulo);
  Callbacks.ValidarPropiedades :=
    function: string
    begin
      Result := '';
      if Assigned(AFormulario.FGestorProp) then
        Result := AFormulario.FGestorProp.Validar;
    end;
  Callbacks.GuardarPropiedades :=
    function(out AMensajeError: string): Boolean
    begin
      Result := True;
      AMensajeError := '';
      if Assigned(AFormulario.FGestorProp) then
      begin
        try
          AFormulario.FGestorProp.GuardarPropiedades;
        except
          on E: Exception do
          begin
            Result := False;
            AMensajeError := E.Message;
          end;
        end;
      end;
    end;
  Callbacks.GuardarEdicionesPendientes :=
    procedure
    begin
      if AFormulario.dmmArticulos.unqryProveedoresArticulos.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryProveedoresArticulos.Post;
      if AFormulario.dmmArticulos.unqryTarifasArticulos.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryTarifasArticulos.Post;
      if AFormulario.dmmArticulos.unqryVariacionesArticulos.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryVariacionesArticulos.Post;
      if AFormulario.dmmArticulos.unqrySkus.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqrySkus.Post;
      if AFormulario.dmmArticulos.unqryTablaG.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryTablaG.Post;
    end;
  Callbacks.GuardarVariaciones :=
    function(out AMensajeError: string): Boolean
    begin
      Result := True;
      AMensajeError := '';
      if Assigned(AFormulario.FGestorVar) then
      begin
        try
          AFormulario.FGestorVar.GuardarVariaciones;
        except
          on E: Exception do
          begin
            Result := False;
            AMensajeError := E.Message;
          end;
        end;
      end;
    end;
  Operaciones := TAdaptadorGuardadoArticuloVcl.Create(Callbacks);
  AFormulario.FAplicacionGuardado :=
    AFormulario.FDependencias.CrearGuardado(Operaciones);
end;

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
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  if Assigned(dmmArticulos) then
  begin
    Visibilidad := EvaluarVisibilidadColumnasArticulo(
      dmmArticulos.unqryTarifasArticulos,
      dmmArticulos.unqrySkus);
    tvTarifasCODIGO_UNIDAD_TARIFA.Visible :=
      Visibilidad.MostrarSkuTarifa;
    tvSkuMtoPRECIO_ULT_COMPRA_SKUC.Visible :=
      Visibilidad.MostrarCompraSku;
    tvSkuMtoFECHA_ULT_COMPRA_SKUC.Visible :=
      Visibilidad.MostrarCompraSku;
  end;
end;

procedure TfrmMtoArticulos.AsegurarSkuArticuloSinVariaciones(
  const aCodArticulo: string);
begin
  inLibArticulosVariaciones.AsegurarSkuArticuloSinVariaciones(
    FDependencias.Variaciones,
    aCodArticulo, IdentidadSesion.Usuario);
end;
procedure TfrmMtoArticulos.AsegurarSkuArticulo(
  const aCodArticulo: string);
begin
  inLibArticulosVariaciones.AsegurarSkuArticuloActivo(
    FDependencias.Variaciones,
    aCodArticulo, IdentidadSesion.Usuario);
end;
procedure TfrmMtoArticulos.addSkuAllClick(Sender: TObject);
var
  CodArticulo, TipoVariacion: string;
begin
  // 1. Nos aseguramos de que el artículo no esté a medias de editar
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  // 2. Leemos los datos clave del dataset principal
  CodArticulo   :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  TipoVariacion :=
    dmmArticulos.unqryTablaG.FieldByName('TIPO_VARIACION_ART').AsString;

  // 3. Validamos que haya un esquema de variación asignado
  if (CodArticulo = '') or (TipoVariacion = '') then
  begin
    ShowMessage(SErrorArticuloSinTipoVariacion);
    // Mandamos al usuario al combo para que lo elija
    FCbbTipoVariacion.SetFocus;
  end;
  if (CodArticulo <> '') and (TipoVariacion <> '') then
  begin
    TfrmMtoModalGenerarSKUs.Ejecutar(CodArticulo, TipoVariacion);
    dmmArticulos.unqrySkus.Close;
    dmmArticulos.unqrySkus.Open;
    dmmArticulos.unqryVariacionesArticulos.Close;
    dmmArticulos.unqryVariacionesArticulos.Open;
  end;
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
  // Ctrl+Alt+E -> Empresas.
    if (
        (pcDetail.ActivePage = tsLineasFactura)        and
        (not(tvLinFac.DataController.DataSet.FieldByName(
          'CODIGO_EMP_FACLIN').IsNull))
       ) then
      btnIraEmpresaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Empresas');
end;

function TfrmMtoArticulos.ObtenerFacturaLineaActiva(out ANumero,
  ASerie: string): Boolean;
var
  oDataSet: TDataSet;
  oCampoNumero: TField;
  oCampoSerie: TField;
begin
  Result := False;
  ANumero := '';
  ASerie := '';
  oDataSet := nil;
  if Assigned(tvLinFac) and
     Assigned(tvLinFac.DataController) and
     Assigned(tvLinFac.DataController.DataSource) then
    oDataSet := tvLinFac.DataController.DataSource.DataSet;
  if Assigned(oDataSet) and oDataSet.Active and (not oDataSet.IsEmpty) then
  begin
    oCampoNumero := oDataSet.FindField('NUMERO_FAC_FACLIN');
    oCampoSerie := oDataSet.FindField('SERIE_FAC_FACLIN');
    if Assigned(oCampoNumero) and Assigned(oCampoSerie) and
       (not oCampoNumero.IsNull) and (not oCampoSerie.IsNull) then
    begin
      ANumero := Trim(oCampoNumero.AsString);
      ASerie := Trim(oCampoSerie.AsString);
      Result := (ANumero <> '') and (ASerie <> '');
    end;
  end;
end;

procedure TfrmMtoArticulos.AbrirFacturaLineaActiva(const ANumero,
  ASerie: string);
begin
  ShowMto(Self.Owner,
          ResolverCallFactura(
            FResolutorDestinoFactura,
            ANumero,
            ASerie),
          ANumero + ',' + ASerie);
end;

procedure TfrmMtoArticulos.actFacturasExecute(Sender: TObject);
var
  sNum: string;
  sSer: string;
begin
  inherited;
  //Control + F   -> Facturas
  if (pcDetail.ActivePage = tsLineasFactura) and
     ObtenerFacturaLineaActiva(sNum, sSer) then
    AbrirFacturaLineaActiva(sNum, sSer)
  else
    ShowMto(Self.Owner,
            'Facturas');
end;

procedure TfrmMtoArticulos.actFamiliasExecute(Sender: TObject);
begin
  inherited;
  //Control + N     -> Familias
    if ((not(dsTablaG.DataSet.FieldByName('CODIGO_FAM_ART').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Familias',
              dsTablaG.DataSet.FieldByName('CODIGO_FAM_ART').AsString)
    else
      ShowMto(Self.Owner,
              'Familias');
end;

procedure TfrmMtoArticulos.actProveedoresExecute(Sender: TObject);
begin  //control + P -> proveedores
  inherited;
    if (
        (pcDetail.ActivePage = tsProveedores) and
        (not(tvProveedores.DataController.DataSet.FieldByName(
          'CODIGO_PRV_PRV').IsNull))
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
    if (
        (pcDetail.ActivePage = tsTarifas) and
        (not(tvTarifas.DataController.DataSet.FieldByName(
          'CODIGO_TAR_ARTTAR').IsNull))
       ) then
      btnIraTarifaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Tarifas');
end;

procedure TfrmMtoArticulos.btnAddProveedorClick(Sender: TObject);
begin
  if (dmmArticulos.unqryTablaG.State = dsInsert) or
     (dmmArticulos.unqryTablaG.State = dsEdit) then
    dmmArticulos.unqryTablaG.Post;
  BuscarProveedores;
end;

procedure TfrmMtoArticulos.btnAddSKUClick(Sender: TObject);
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;
  FPresTarifas.AltaMasivaPrecios(Self,
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.dbcTarifasMARGENButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  inherited;
  FPresTarifas.AbrirCalculadoraMargen(Self);
end;

procedure TfrmMtoArticulos.dbcTarifasMARGENGetDisplayText(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  FPresTarifas.MostrarMargen(ARecord, AText);
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
  FPresTarifas.IncorporarTarifas(Self.Owner);
end;

procedure TfrmMtoArticulos.btnExportarProveedorClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxgrdProveedores,
                'Historico_Proveedores_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnExportarTarifaClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxGrdTarifas,
                'Historico_Tarifas_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnIraClienteClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Clientes',
          tvLinFac.DataController.DataSet.FieldByName(
            'CODIGO_CLIENTE_FACTURA_LINEA').AsString);
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
var
  sNum, sSer: string;
begin
  inherited;
  if ObtenerFacturaLineaActiva(sNum, sSer) then
    AbrirFacturaLineaActiva(sNum, sSer)
  else
    ShowMto(Self.Owner,
            'Facturas');
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
  Resultado: TResultadoGuardadoArticulo;
begin
  Resultado := FAplicacionGuardado.Ejecutar;
  case Resultado.Error of
    egaRevisionPropiedades:
      begin
        ShowMessage(Format(SAvisoRevisionArticulo, [Resultado.Mensaje]));
        pcDetail.ActivePage := tsPropiedades;
      end;
    egaGuardadoPropiedades:
      ShowMessage(Format(
        SErrorGuardarPropiedadesArticulo,
        [Resultado.Mensaje]));
    egaGuardadoVariaciones:
      ShowMessage(Format(
        SErrorGuardarVariacionesArticulo,
        [Resultado.Mensaje]));
  end;
  if Resultado.Error = egaNinguno then
    inherited;
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

procedure TfrmMtoArticulos.btnStockExportarExcelClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxgrdStock, 'Stock_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnReconstruirStockClick(Sender: TObject);
var
  sMensaje: string;
  bReconstruido: Boolean;
begin
  inherited;
  if Application.MessageBox(
       PChar(SPreguntaReconstruirStock),
       PChar(STituloReconstruirStock),
       MB_YESNO + MB_ICONQUESTION) = ID_YES then
  begin
    bReconstruido := True;
    Screen.Cursor := crHourGlass;
    try
      try
        sMensaje := dmmArticulos.ReconstruirStock;
        if dmmArticulos.unqryTablaG.Active and
           not dmmArticulos.unqryTablaG.IsEmpty then
          dmmArticulos.unqryStockArticulosAfterScroll(
            dmmArticulos.unqryTablaG);
      except
        on E: Exception do
        begin
          bReconstruido := False;
          ShowMessage(Format(SErrorReconstruirStock, [E.Message]));
        end;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
    if bReconstruido then
    begin
      if sMensaje = '' then
        sMensaje := SInfoStockReconstruido;
      ShowMessage(sMensaje);
    end;
  end;
end;

procedure TfrmMtoArticulos.btnImprimirEtiquetasClick(Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if (not dsTablaG.Dataset.Active) or dsTablaG.Dataset.IsEmpty then
    ShowMessage(SErrorArticuloNoSeleccionadoImprimirEtiquetas)
  else
  begin
    formulario := TfrmPrintEtiqArt.Create(Application);
    try
      formulario.DM := dmmArticulos;
      formulario.edtCodArt.Text := dsTablaG.Dataset.FieldByName(
        'CODIGO_ART_ART').AsString;
      formulario.ShowModal;
    finally
      FreeAndNil(formulario);
    end;
  end;
end;

procedure TfrmMtoArticulos.btnGenerarCBClick(Sender: TObject);
var
  sCodigoArticulo: string;
  bGenerado: Boolean;
  Resultado: TResultadoCodigosBarrasArticulo;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;
  sCodigoArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if sCodigoArticulo = '' then
    ShowMessage(SErrorArticuloNoSeleccionadoGenerarCodigos)
  else if MessageDlg(
    Format(SPreguntaGenerarCodigosBarras, ['21']),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      bGenerado := GenerarCodigosBarrasArticulo(
        FCodigosBarrasPersistencia,
        FDependencias.Variaciones,
        sCodigoArticulo,
        IdentidadSesion.Usuario,
        Resultado);
    finally
      Screen.Cursor := crDefault;
    end;
    if not bGenerado then
      ShowMessage(SErrorArticuloSinSkusActivosGenerarCodigos)
    else
    begin
      dmmArticulos.unqryVariacionesArticulos.Close;
      dmmArticulos.unqryVariacionesArticulos.Open;
      ActualizarVisibilidadVariaciones;
      ShowMessage(Format(
        SInfoGeneracionCodigosBarras,
        [Resultado.PrincipalesGenerados,
         Resultado.FilasFabricanteCreadas,
         Resultado.SkusSinCambios,
         Resultado.MarcadoresAntiguosEliminados]));
    end;
  end;
end;
procedure TfrmMtoArticulos.btnVerificarCBClick(Sender: TObject);
var
  sCodArticulo: string;
  oResumen: TResumenCodigosBarrasArticulo;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;
  sCodArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if sCodArticulo = '' then
    ShowMessage(SErrorArticuloNoSeleccionadoVerificarCodigos)
  else
  begin
    AsegurarSkuArticulo(sCodArticulo);
    oResumen := VerificarCodigosBarrasArticulo(
      FCodigosBarras.ListarCodigosBarras(sCodArticulo));
    if oResumen.Invalidos = 0 then
      ShowMessage(Format(SInfoVerificacionCodigosBarrasCorrecta,
        [oResumen.Ean13Correctos, oResumen.Ean8Correctos,
         oResumen.Omitidos]))
    else
      ShowMessage(Format(SAvisoVerificacionCodigosBarras,
        [oResumen.Ean13Correctos, oResumen.Ean8Correctos,
         oResumen.Invalidos, oResumen.Omitidos,
         oResumen.DetalleErrores]));
  end;
end;

// El articulo activo siempre viene de dsTablaG (CODIGO_ART_ART). El
// SKU activo depende de la pestana visible: cuando el usuario esta en
// la pestana 2_SKUs, 8_Stock o 9_Movimientos, la fila activa del
// sub-grid correspondiente lleva el CODIGO_UNIDAD_*; en otras pestanas
// no hay SKU activo y se trabaja a nivel articulo.
procedure TfrmMtoArticulos.ResolverArtSkuActivo(out ACodArt,
                                                ACodSku: string);

  function LeerSkuDeGrid(AGrid: TcxGridDBTableView): string;
  var
    ds: TDataSet;
  begin
    Result := '';
    if Assigned(AGrid.DataController.DataSource) then
    begin
      ds := AGrid.DataController.DataSource.DataSet;
      // Reutilizamos la lista canonica de aliases (CODIGO_UNIDAD_*).
      var sArt: string := '';
      inLibFotos.LeerArtSkuDeDataSet(ds, sArt, Result);
    end;
  end;

begin
  inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  // Si el inherited ya devolvio SKU (improbable en este Mto), no
  // tocamos. Si no, miramos la pestana activa.
  if ACodSku = '' then
  begin
    if pcDetail.ActivePage = tsSkuMto then
      ACodSku := LeerSkuDeGrid(tvSkuMto)
    else if pcDetail.ActivePage = cxTabSheet3 then
      ACodSku := LeerSkuDeGrid(tvStock)
    else if pcDetail.ActivePage = tsMovimientos then
      ACodSku := LeerSkuDeGrid(tvMovimientos);
  end;
end;

function TfrmMtoArticulos.DataSourcesParaFoto: TArray<TDataSource>;
begin
  // El articulo viene de dsTablaG; el SKU puede venir de cualquiera
  // de los tres sub-grids segun la pestana activa. Enganchamos los
  // cuatro DataSources para que la pantalla flotante refresque al
  // navegar en cualquiera de ellos.
  Result := [dsTablaG,
             dmmArticulos.dsSkus,            // pestaña 2_SKUs
             dmmArticulos.dsStockArticulos,  // pestaña 8_Stock
             dmmArticulos.dsMovimientosArticulos]; // pestaña 9_Movimientos
end;


procedure TfrmMtoArticulos.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsGeneral;
end;

procedure TfrmMtoArticulos.BuscarProveedores;
begin
  if BusquedaVisual.EjecutarBusqueda(
    ConexionPrincipal,
    'Búsqueda de Proveedores en Articulos',
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
  FDependencias.Validar;
  inherited;
  dmmArticulos := tdmDataModule as TdmArticulos;
  FCodigosBarrasPersistencia :=
    CrearArticulosCodigosBarrasPersistenciaUniDAC(ConexionPrincipal);
  FResolutorDestinoFactura :=
    CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal);
  // La vista de stock se empuja al DM (ya no la busca con GetOwnerForm).
  dmmArticulos.AsignarVistaStock(tvStock);
  cbbFamilia.Properties.ListSource := dmmArticulos.dsFamiliaArticulos;
  cbbTipoCantidad.Properties.ListSource := dmmArticulos.dsUnidadesMedidaLookup;
  tvTarifas.DataController.DataSource := dmmArticulos.dsTarifasArticulos;
  tvProveedores.DataController.DataSource :=
                                            dmmArticulos.dsProveedoresArticulos;
  tvLinFac.DataController.DataSource := dmmArticulos.dsLinFacturasArticulos;
  tvSkus.DataController.DataSource := dmmArticulos.dsVariacionesArticulos;
  tvStock.DataController.DataSource := dmmArticulos.dsStockArticulos;
  // Estos cuatro grids/lookup vienen cableados en el DFM contra el componente
  // 'dmArticulos'. Con varias pestañas de Articulos abiertas la VCL resuelve
  // ese nombre al PRIMER data module creado, asi que la segunda pestaña
  // mostraba los SKUs / atributos / movimientos del articulo de la primera.
  // Los rebindeamos a la instancia local del Mto.
  tvSkuMto.DataController.DataSource := dmmArticulos.dsSkus;
  tvSkuAtributosBasicos.DataController.DataSource :=
                                            dmmArticulos.dsDetallesAtributos;
  (tvSkuAtributosBasicosID_ATB_AV.Properties as TcxLookupComboBoxProperties)
                          .ListSource := dmmArticulos.dsAtributosBasicosLookup;
  tvMovimientos.DataController.DataSource :=
    dmmArticulos.dsMovimientosArticulos;
  pkFieldName := 'CODIGO_ART_ART';
  dmmArticulos.unqryTablaG.AfterScroll := OnAfterScrollArticulos;
  // Carga perezosa de Tarifas: solo abrir unqryTarifasArticulos cuando
  // el usuario pase a esa pestaña. Asi quitamos los ~6s de la
  // apertura inicial del Mto.
  pcDetail.OnChange := PcDetailChange;
  InicializarPestanyaPropiedades;
  InicializarPestanyaVariaciones;
  InicializarPresentadores;
  InicializarGuardadoArticuloVcl(Self);
  // Filtros de carga (estado, stock, temporadas): poblar la lista de
  // temporadas, leer las preferencias guardadas por usuario y aplicar
  // el filtro parametrizado antes de que el resto de
  // la rutina lea FArticuloCargado / el primer registro.
  FPresFiltros.Colapsar;
  FPresFiltros.CargarTemporadas;
  FPresFiltros.LeerPerfil(oPerfilDic);
  // Precarga: DE MOMENTO sin dialogo de acotado. Dejamos la lista CERRADA
  // con el filtro aplicado (por defecto solo activos) y que la carga la haga
  // AbrirTablaPrincipalAsync en segundo plano, mostrando el overlay
  // "Cargando datos..." con barra de progreso.
  FPresFiltros.AplicarFiltroEnLista;
end;

procedure TfrmMtoArticulos.InicializarPresentadores;
// Raiz de composicion de la pantalla: aqui se resuelven los adaptadores
// UniDAC y se inyectan a cada colaborador. Las lambdas capturan el data
// module (oDatos), no el formulario, salvo los dos avisos de vista.
var
  oControlesFiltro: TControlesFiltroCargaArticulos;
  oDatos: TdmArticulos;
begin
  oDatos := dmmArticulos;
  FCodigosBarras :=
    CrearLecturaCodigosBarrasArticuloUniDAC(ConexionPrincipal);
  FPresAtributos := TPresentadorAtributosBasicosArticulo.Create(
    oDatos.unqryDetallesAtributos,
    oDatos.unqryAtributosBasicosLookup,
    oDatos.unqrySkus,
    TGestorAtributosBasicosSku.Create(
      TRepositorioAtributosBasicosSku.Create(ConexionPrincipal)),
    IdentidadSesion.Usuario,
    function(const ACodArt, AColor, AActivo: string): Integer
    begin
      Result := oDatos.ActualizarSkusColorActivo(ACodArt, AColor, AActivo);
    end);
  FPresStock := TPresentadorStockArticulo.Create(tvStock,
    ConexionPrincipal);
  FPresTarifas := TPresentadorTarifasArticulo.Create(
    oDatos.unqryTarifasArticulos,
    tvTarifas,
    dbcTarifasPRECIOSALIDA,
    ConexionPrincipal,
    CrearCatalogoAltaTarifasArticuloUniDAC(ConexionPrincipal),
    function(const ACodArt, ACodTar: string): Double
    begin
      Result := oDatos.ObtenerPrecioTarifaPadre(ACodArt, ACodTar);
    end,
    procedure(ALista: TcxListView)
    begin
      oDatos.FillTarifas(ALista);
    end,
    procedure
    begin
      ActualizarVisibilidadColumnaSku;
    end);
  oControlesFiltro.Estado := cbbFiltroEstadoArt;
  oControlesFiltro.ConStock := chkFiltroConStockArt;
  oControlesFiltro.Temporadas := ccbFiltroTemporadaArt;
  oControlesFiltro.Persiana := pnlFiltrosArt;
  oControlesFiltro.Contenido := pnlContFiltrosArt;
  oControlesFiltro.Cabecera := btnToggleFiltrosArt;
  FPresFiltros := TPresentadorFiltrosArticulos.Create(
    oControlesFiltro,
    CrearRepositorioFiltroArticulosUniDAC(ConexionPrincipal),
    CrearListaArticulosPantallaUniDAC(oDatos.unqryTablaG),
    CrearEscrituraPrecargaArticulosUniDAC(
      ConexionPrincipal, PerfilesEscritura),
    procedure
    begin
      AbrirTablaPrincipalAsync;
    end);
end;

procedure TfrmMtoArticulos.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                     const sPermisos: string);
begin
  // Los filtros de carga se vuelcan al batch del sbGrabarGridClick para
  // grabarse junto con el resto de preferencias del Mto.
  if Assigned(FPresFiltros) then
    FPresFiltros.VolcarPerfil(oList, sPermisos, Self.Name);
end;

procedure TfrmMtoArticulos.TrasPrecargaAsync;
begin
  inherited;
  // Dialogo de precarga DESACTIVADO de momento: la lista se carga entera
  // (overlay con barra de progreso). El Open async corre con
  // DisableControls (el AfterScroll en el hilo de trabajo se autoexcluye),
  // asi que este es el punto canonico donde queda cargada la ficha del
  // registro actual. El escudo de OnAfterScrollArticulos evita recargarla
  // si RestaurarFocoGrid ya la fijo o si el articulo no cambio.
  if dmmArticulos.unqryTablaG.Active
     and (not dmmArticulos.unqryTablaG.IsEmpty) then
    OnAfterScrollArticulos(dmmArticulos.unqryTablaG);
end;

procedure TfrmMtoArticulos.PrepararBusquedaExterna(const ABusq: string);
begin
  // Búsqueda externa (Ctrl+A desde otro Mto): sin filtros de carga
  // para que salgan todos los artículos. Resetear controles y SQL
  // antes de que inherited añada el WHERE de búsqueda vía parser.
  if Assigned(FPresFiltros) then
    FPresFiltros.ReiniciarParaBusquedaExterna;
  inherited;
end;

procedure TfrmMtoArticulos.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  // Precarga: oculta el panel de Filtros de carga (cabecera + contenido).
  // En instancia 1 ya viene precargado el articulo concreto de la busqueda,
  // no tiene sentido permitir reabrir la lista con otros filtros.
  pnlFiltrosArt.Visible := False;
end;

procedure TfrmMtoArticulos.btnToggleFiltrosArtClick(Sender: TObject);
begin
  FPresFiltros.AlternarPersiana;
end;

procedure TfrmMtoArticulos.cbbFiltroEstadoArtPropertiesEditValueChanged(
                                                              Sender: TObject);
begin
  // Aplicamos el filtro inmediatamente, pero NO persistimos: la grabacion
  // a fza_usuarios_perfiles se hace explicitamente desde sbGrabarGridClick
  // (mismo patron que el resto de ajustes del Mto: ancho de columnas,
  // captions, etc.).
  if not FPresFiltros.Cargando then
    FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.chkFiltroConStockArtPropertiesEditValueChanged(
                                                              Sender: TObject);
begin
  if not FPresFiltros.Cargando then
    FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.ccbFiltroTemporadaArtPropertiesCloseUp(
                                                              Sender: TObject);
begin
  if not FPresFiltros.Cargando then
    FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.btnCargarAhoraArtClick(Sender: TObject);
begin
  // Dispara la carga de la lista con los filtros actuales del panel
  // (estado/stock/temporadas) de forma explicita, sin depender del
  // auto-aplicado al cerrar el desplegable de temporadas.
  FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.btnGuardarPrecargaArtClick(Sender: TObject);
begin
  FPresFiltros.GuardarPrecarga(Application, Self.Name);
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
  FBtnAddProp.Caption := SCaptionAnadirPropiedad;
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
    FDependencias.Propiedades,
    IdentidadSesion.Usuario
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
  lbl.Transparent := True;
  lbl.Left    := 8;
  lbl.Top     := 10;
  lbl.Caption := SCaptionTipoVariacion;
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
  // por defecto solo lectura
  FCbbTipoVariacion.Properties.ReadOnly       := True;
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


  FGestorVar := TGestorVariaciones.Create(
    FScrollVarAtrib,
//    FScrollVarSkus,
    FDependencias.Variaciones,
    IdentidadSesion.Usuario
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
  swTotal, swTramo: TStopwatch;
  msCargarProp, msCargarVar, msActVisVar, msAseguraSku,
  msRefSkus, msRefVarArt, msMapaAtr, msStockAS, msActVisCol: Int64;
  bProcesar: Boolean;
begin
  bProcesar := not DataSet.ControlsDisabled and
    dmmArticulos.unqrySkus.Active;
  // 1. Si estamos creando un artículo nuevo, limpiamos la pantalla una sola vez
  // y salimos
  if bProcesar and (DataSet.State = dsInsert) then
  begin
    if FArticuloCargado <> '' then
    begin
      FArticuloCargado := ''; // Marcamos como vacío
      if Assigned(FGestorProp) then
        FGestorProp.CargarPropiedades('');
      if Assigned(FGestorVar) then
        FGestorVar.CargarVariaciones('');
      ActualizarVisibilidadVariaciones;
    end;
    bProcesar := False;
  end;
  // 2. Si estamos editando, ignoramos los scrolls fantasma
  if bProcesar and (DataSet.State = dsEdit) then
    bProcesar := False;
  CodArticulo := '';
  if bProcesar then
    CodArticulo := DataSet.FieldByName('CODIGO_ART_ART').AsString;
  // 3. EL ESCUDO: Si el artículo es exactamente el mismo que ya está dibujado,
  // ¡no hagas nada!
  if bProcesar and (FArticuloCargado = CodArticulo) then
    bProcesar := False;
  if bProcesar then
  begin
  // Actualizamos nuestra memoria
  FArticuloCargado := CodArticulo;

  // [PERF] Cronometros por tramo. Este handler es el sospechoso principal
  // de los gaps de 5s que se ven al abrir/navegar Articulos. Cada
  // sub-tarea se mide independientemente y se vuelca al log+memo SQL.
  swTotal := TStopwatch.StartNew;
  msCargarProp := 0;
  msCargarVar := 0;
  msMapaAtr := 0;

  // 4. Ahora sí, cargamos la interfaz visual de forma segura
  if Assigned(FGestorProp) then
  begin
    swTramo := TStopwatch.StartNew;
    FGestorProp.CargarPropiedades(CodArticulo);
    msCargarProp := swTramo.ElapsedMilliseconds;
  end;

  if Assigned(FGestorVar) then
  begin
    swTramo := TStopwatch.StartNew;
    FGestorVar.CargarVariaciones(CodArticulo);
    msCargarVar := swTramo.ElapsedMilliseconds;
  end;

  swTramo := TStopwatch.StartNew;
  ActualizarVisibilidadVariaciones;
  msActVisVar := swTramo.ElapsedMilliseconds;

  // Si el artículo no tiene variaciones, garantizamos un SKU = código artículo
  // para que la rejilla SKUs y CB tenga al menos una fila editable
  swTramo := TStopwatch.StartNew;
  AsegurarSkuArticuloSinVariaciones(CodArticulo);
  msAseguraSku := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  dmmArticulos.unqrySkus.Refresh;
  msRefSkus := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  dmmArticulos.unqryVariacionesArticulos.Refresh;
  msRefVarArt := swTramo.ElapsedMilliseconds;

  // Refrescamos el mapa NOMBRE_ATRIBUTO -> ID_VA ANTES de
  // unqryStockArticulosAfterScroll: el bestfit que hace ese metodo necesita
  // saber qué columnas pintaran swatch para reservarles el ancho del
  // cuadradito.
  if Assigned(FPresStock) then
  begin
    swTramo := TStopwatch.StartNew;
    FPresStock.CargarMapaArticulo(CodArticulo);
    msMapaAtr := swTramo.ElapsedMilliseconds;
  end;

  // Stock perezoso: solo recargar el SP si la pestaña Stock esta
  // visible. AsegurarStockAlDia ademas evita reejecutar si el articulo
  // no ha cambiado.
  swTramo := TStopwatch.StartNew;
  if pcDetail.ActivePage = cxTabSheet3 then
    AsegurarStockAlDia;
  msStockAS := swTramo.ElapsedMilliseconds;

  // Tarifas perezoso: si la pestaña Tarifas NO esta visible, cerrar
  // unqryTarifasArticulos. Asi el master/detail no dispara el refresh
  // de ~2s (vi_articulos_tarifas con subqueries DEPENDENT). Cuando el
  // usuario vuelva a Tarifas, PcDetailChange la reabre con el filtro
  // del articulo actual.
  CerrarSiNoVisible(dmmArticulos.unqryTarifasArticulos, tsTarifas);

  swTramo := TStopwatch.StartNew;
  ActualizarVisibilidadColumnaSku;
  msActVisCol := swTramo.ElapsedMilliseconds;

  RegistroLog.RegistrarRendimiento('Articulos.AfterScroll',
    Format('art=%s | Prop=%d | Var=%d | ActVar=%d | Sku=%d | RefSkus=%d | ' +
           'RefVarArt=%d | MapaAtr=%d | StockAS=%d | ActColSku=%d',
           [CodArticulo, msCargarProp, msCargarVar, msActVisVar,
            msAseguraSku, msRefSkus, msRefVarArt, msMapaAtr, msStockAS,
            msActVisCol]),
    swTotal.ElapsedMilliseconds);
  end;
end;

procedure TfrmMtoArticulos.cxButton11Click(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxGrdMovimientos,
                'Movimientos_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.cxDBComboBox1PropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) and Assigned(dmmArticulos) and
     Assigned(dmmArticulos.unqryTablaG) and
     dmmArticulos.unqryTablaG.Active then
    ActualizarVisibilidadVariaciones;
end;

procedure TfrmMtoArticulos.cxDBCheckBox1PropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) and Assigned(dmmArticulos) and
     Assigned(dmmArticulos.unqryTablaG) and
     dmmArticulos.unqryTablaG.Active and
     not dmmArticulos.unqryTablaG.IsEmpty and
     not dmmArticulos.unqryTablaG.ControlsDisabled and
     (dmmArticulos.unqryTablaG.State in [dsEdit, dsInsert]) then
  begin
    // El Focus garantiza que el evento lo ha disparado el usuario y no un
    // refresco del dataset
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
begin
  inherited;
  FPresTarifas.RecalcularDesdePorcentajeDto(Sender);
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOFINALPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePrecioFinal(Sender);
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOSALIDAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePrecioSalida(Sender);
end;

procedure TfrmMtoArticulos.
                          dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePrecioDto(Sender);
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
    FCbbTipoVariacion.Properties.ReadOnly := not (dsTablaG.State in
                                                  [dsInsert, dsEdit]);
end;

procedure TfrmMtoArticulos.FormDestroy(Sender: TObject);
begin
  FAplicacionGuardado := nil;
  FCodigosBarrasPersistencia := nil;
  FResolutorDestinoFactura := nil;
  FDependencias.Liberar;
  FCodigosBarras := nil;
  inherited;
  if Assigned(FGestorProp) then
    FreeAndNil(FGestorProp);
  if Assigned(FGestorVar) then
    FreeAndNil(FGestorVar);
  FreeAndNil(FPresFiltros);
  FreeAndNil(FPresTarifas);
  FreeAndNil(FPresStock);
  FreeAndNil(FPresAtributos);
  dmmArticulos := nil;
end;

procedure TfrmMtoArticulos.FormShow(Sender: TObject);
begin
  inherited;
  ResetForm;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosFUENTE_ATBGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  FPresAtributos.MostrarFuente(AText);
end;

procedure TfrmMtoArticulos.
              tvSkuAtributosBasicosNOMBRE_ATBPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarNombre(Sender);
end;

procedure TfrmMtoArticulos.
           tvSkuAtributosBasicosVALOR_NUM_ATBPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarValorNumerico(Sender);
end;

procedure TfrmMtoArticulos.
              tvSkuAtributosBasicosUNIDAD_ATBPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarUnidad(Sender);
end;

procedure TfrmMtoArticulos.
         tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarDescripcion(Sender);
end;

procedure TfrmMtoArticulos.btnColorSkusClick(Sender: TObject);
// Despliega el mismo menu (activar/desactivar color) que el clic derecho
// sobre el panel de atributos, anclado bajo el boton lateral.
var
  pt: TPoint;
begin
  pt := btnColorSkus.ClientToScreen(Point(0, btnColorSkus.Height));
  pmColorSkus.Popup(pt.X, pt.Y);
end;

procedure TfrmMtoArticulos.miActivarColorClick(Sender: TObject);
begin
  FPresAtributos.CambiarActivoColorSkus('S');
end;

procedure TfrmMtoArticulos.miDesactivarColorClick(Sender: TObject);
begin
  FPresAtributos.CambiarActivoColorSkus('N');
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesInitPopup(
  Sender: TObject);
begin
  FPresAtributos.AbrirDesplegableBasico;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesCloseUp(
  Sender: TObject);
begin
  FPresAtributos.CerrarDesplegableBasico;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  FPresAtributos.ValidarBasico(DisplayValue, ErrorText, Error);
end;

procedure TfrmMtoArticulos.
             tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarBasico(Sender);
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosHEX_ATBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FPresAtributos.ElegirColor;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosDblClick(Sender: TObject);
begin
  FPresAtributos.ElegirColor;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosHEX_ATBCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FPresAtributos.PintarCeldaHex(ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoArticulos.tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  FPresStock.PintarCelda(ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoArticulos.PcDetailChange(Sender: TObject);
begin
  if Assigned(dmmArticulos) then
  begin
    // Al entrar a Tarifas: abrir (lazy). Al salir, cerrar la query para
    // que el siguiente cambio de articulo (master/detail) no dispare un
    // refresh innecesario de ~2s sobre vi_articulos_tarifas.
    if pcDetail.ActivePage = tsTarifas then
      dmmArticulos.AsegurarTarifasAbiertas
    else
      CerrarSiNoVisible(dmmArticulos.unqryTarifasArticulos, tsTarifas);
    // Stock: si activan la pestaña, refrescar solo si cambio el articulo.
    if pcDetail.ActivePage = cxTabSheet3 then
      AsegurarStockAlDia;
  end;
end;

procedure TfrmMtoArticulos.AsegurarStockAlDia;
var
  bAlDia: Boolean;
begin
  if Assigned(dmmArticulos) and (FArticuloCargado <> '') then
  begin
    // Si el stock ya esta cargado para el articulo activo, nada que hacer.
    bAlDia := (FStockArticuloCargado = FArticuloCargado) and
              dmmArticulos.unqryStockArticulos.Active;
    if not bAlDia then
    begin
      // unqryStockArticulosAfterScroll cierra, recarga el SP y reconstruye
      // las columnas dinamicas del cxGrid tvStock.
      dmmArticulos.unqryStockArticulosAfterScroll(dmmArticulos.unqryTablaG);
      FStockArticuloCargado := FArticuloCargado;
    end;
  end;
end;

procedure TfrmMtoArticulos.CerrarSiNoVisible(qry: TUniQuery;
  ActivaTarget: TcxTabSheet);
begin
  // Solo cerrar si la pestaña target NO esta visible. Util para queries
  // master/detail que se reabren automaticamente al cambiar el master:
  // mientras no se esta viendo, mejor cerrada para ahorrar el refresh.
  if (qry <> nil) and qry.Active and
     (pcDetail.ActivePage <> ActivaTarget) then
    qry.Close;
end;

procedure TfrmMtoArticulos.EnsancharColumnasStockParaSwatch;
begin
  FPresStock.EnsancharColumnasParaSwatch;
end;

procedure TfrmMtoArticulos.tvStockGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
var
  sHint: string;
begin
  if FPresStock.ObtenerHint(ACellViewInfo, sHint) then
    AHintText := sHint;
end;

initialization
  RegistrarPantalla(TfrmMtoArticulos);
  ForceReferenceToClass(TfrmMtoArticulos);
end.
