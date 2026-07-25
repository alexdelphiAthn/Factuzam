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
  cxCustomListBox, cxCheckListBox, System.UITypes, System.Types;

type
  // Ambito que elige el usuario cuando hay que crear un atributo basico
  // nuevo desde el helper del SKU. Global = compartido entre articulos;
  // ad-hoc = exclusivo de este articulo (CODIGO_ATB con prefijo AD_).
  TAmbitoBasico = (abCancelar, abGlobal, abAdHoc);

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
     procedure IncorporarTarifas;
     procedure IterateCheckedListArt(lst:TcxListView);
     // Carga perezosa de la pestaña Tarifas: vi_articulos_tarifas tarda
     // ~6s por subqueries DEPENDENT. La abrimos solo cuando el usuario
     // pasa a tsTarifas (ver dmmArticulos.AsegurarTarifasAbiertas).
     procedure PcDetailChange(Sender: TObject);
     // Stock: ultimo articulo para el que se cargo el grid pivotado.
     // Asi AsegurarStockAlDia evita reejecutar el SP si el artículo
     // no ha cambiado desde la ultima visita a la pestaña Stock.

     procedure AsegurarStockAlDia;
     procedure CerrarSiNoVisible(qry: TUniQuery; ActivaTarget: TcxTabSheet);
  private
    // Filtros de carga del Mto Articulos. Definen el SQL de la lista
    // principal (vi_articulos) y se reaplican en cada cambio. Los
    // valores activos solo se persisten en fza_usuarios_perfiles cuando
    // el usuario pulsa "Grabar Grid" (sbGrabarGridClick), siguiendo el
    // mismo patron que el resto de preferencias del Mto. Claves:
    // oFiltroEstado, oFiltroConStock, oFiltroTemporadas.
    FFiltrosArtCargando: Boolean;
    // Filtros adicionales que aporta el dialogo de precarga (proveedor y
    // familia). Son de sesion: arrancan vacios en cada apertura del Mto y
    // no se persisten en el perfil (a diferencia de estado/stock/temporada).
    // CSV separado por ';' alineado con la convencion de oFiltroTemporadas.
    FFiltroProvCsv: string;
    FFiltroFamCsv: string;
    // True cuando CrearTablaPrincipal detecta que la lista con los filtros
    // por defecto (solo activos) supera UMBRAL_PRECARGA y, en
    // vez de abrir el set completo, abre la lista vacia (LIMIT 0). Lo
    // consume TrasPrecargaAsync para lanzar el dialogo de filtrado y
    // reabrir ya acotado, sin congelar la apertura del Mto.
    FPrecargaPendiente: Boolean;
    procedure CargarTemporadasFiltro;
    procedure LeerFiltrosPerfil;
    // Construye el WHERE de vi_articulos a partir de los controles de
    // estado/stock y de los CSV de temporada/proveedor/familia recibidos.
    // Lo comparten ConstruirSqlArticulos (SELECT) y ContarArticulos (COUNT)
    // para que la cuenta y la carga apliquen exactamente el mismo filtro.
    function  ConstruirWhereArticulos(const aTempCsv, aPrvCsv,
                                      aFamCsv: string): string;
    function  ConstruirSqlArticulos: string;
    // Convierte un CSV ';' en lista IN (...) ya entrecomillada, o '' si
    // viene vacio.
    function  CsvAInList(const aCsv: string): string;
    // Lee/escribe el estado marcado del ccbFiltroTemporadaArt como CSV ';'.
    function  CsvTemporadasControl: string;
    procedure MarcarTemporadasControl(const aCsv: string);
    // COUNT(*) sobre vi_articulos con el mismo WHERE que la carga. Devuelve
    // el numero de articulos que saldrian con esos filtros.
    function  ContarArticulos(const aTempCsv, aPrvCsv,
                              aFamCsv: string): Integer;
    // Reabre unqryTablaG con el SQL filtrado actual. aVacia=True añade
    // LIMIT 0 (apertura instantanea para el caso "demasiados articulos").
    procedure AbrirListaArticulos(aVacia: Boolean = False);
    // Carga propiedades/variaciones/atributos del articulo en foco tras
    // (re)abrir la lista. Equivale a la cola de CrearTablaPrincipal.
    procedure CargarArticuloActual;
    // Muestra el dialogo modal de filtrado (temporada/proveedor/familia) y
    // vuelca la seleccion del usuario a los filtros del Mto.
    procedure MostrarDialogoRefinar;
    procedure AplicarFiltrosArticulos;
    function  ObtenerFacturaLineaActiva(out ANumero,
                                        ASerie: string): Boolean;
    procedure AbrirFacturaLineaActiva(const ANumero,
                                      ASerie: string);
  public
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure TrasPrecargaAsync; override;
  private
    FStockArticuloCargado: string;
    FGestorProp  : TGestorPropiedades;
    FArticuloCargado: string;
    FScrollProp  : TScrollBox;
    FBtnAddProp  : TcxButton;
    FGestorVar      : TGestorVariaciones;
    FPnlTopVariaciones:TPanel;
    FScrollVarAtrib : TScrollBox;
    FCbbTipoVariacion   : TcxDBLookupComboBox;
    // NOMBRE_ATRIBUTO (uppercase) -> ID_ATRIBUTO del articulo actual. Lo usa
    // tvStock para colorear el nombre del atributo segun la paleta basica.
    FAtributosStock : TDictionary<string, string>;
    function AsegurarBasicoFilaActual: Integer;
    function AsegurarFilaSA(const ACodSKU, AIdVaAv,
                            AValorAv: string): Integer;
    function PreguntarAmbitoBasico(const ACodArt,
                                   AValorAv: string): TAmbitoBasico;
    // Resuelve el color (atributo 'CO') del SKU seleccionado leyendo el
    // detalle de atributos del SKU en foco. Devuelve False si no hay color.
    function ObtenerColorSkuActual(out aCodArt, aColor: string): Boolean;
    // Activa ('S') o desactiva ('N') en bloque todos los SKU del articulo
    // que comparten el color del SKU seleccionado.
    procedure CambiarActivoColorSkus(const aActivo: string);
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

var
  frmMtoArticulos: TfrmMtoArticulos;

implementation

uses
  inLibWin,
  inLibUser,
  inLibDevExp,
  inLibShowMto,
  inLibFotos,
  inLibGenBusq,
  inMtoProveedores,
  inMtoPrincipal,
  inMtoTarifas,
  inMtoFamilias,
  inMtoEmpresas,
  inMtoFacturasBase,
  inMtoModalArtTar,
  inMtoModalGenerarSKUs,
  inMtoModalAddPreciosTar,
  inMtoModalCalcularMargen,
  inMtoModalEtiqArt,
  inMtoModalFiltroArt,
  inMtoModalGenImpSave, // dialogo de ambito para "Guardar precarga"
  inLibEAN13,
  inLibAtributosPaleta,
  inLibLog,             // Log.LogPerf para cronometros del AfterScroll
  System.Diagnostics,   // TStopwatch
  inLibtb;

{$R *.dfm}

const
  // Tope de filas para la precarga de la lista de articulos. Si con los
  // filtros por defecto (solo activos) salen mas, no se carga
  // el set completo: aparece el dialogo de filtrado por temporada/
  // proveedor/familia para acotar antes de abrir la lista.
  UMBRAL_PRECARGA = 50000;

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
//
// Además ocultamos las columnas "Precio Últ Compra" y "Fecha Últ Compra"
// del grid de SKUs cuando ningún SKU tiene precio asignado: dan ruido
// visual cuando todos los costes viven a nivel de artículo padre.
var
  ds  : TDataSet;
  fld : TField;
  bm  : TBookmark;
  hay : Boolean;
  fldPrecio: TField;
  hayPrecioSku: Boolean;
  dsSkus: TDataSet;
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

  // Columnas de precio/fecha de última compra del grid de SKUs
  dsSkus := dmmArticulos.unqrySkus;
  hayPrecioSku := False;
  if (dsSkus <> nil) and dsSkus.Active then
  begin
    fldPrecio := dsSkus.FindField('PRECIO_ULT_COMPRA_SKUC');
    if fldPrecio <> nil then
    begin
      dsSkus.DisableControls;
      bm := dsSkus.GetBookmark;
      try
        dsSkus.First;
        while not dsSkus.Eof do
        begin
          if (not fldPrecio.IsNull) and (fldPrecio.AsFloat <> 0) then
          begin
            hayPrecioSku := True;
            Break;
          end;
          dsSkus.Next;
        end;
      finally
        if dsSkus.BookmarkValid(bm) then dsSkus.GotoBookmark(bm);
        dsSkus.FreeBookmark(bm);
        dsSkus.EnableControls;
      end;
    end;
  end;
  tvSkuMtoPRECIO_ULT_COMPRA_SKUC.Visible := hayPrecioSku;
  tvSkuMtoFECHA_ULT_COMPRA_SKUC.Visible  := hayPrecioSku;
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
    qry.Connection := ConexionPrincipal;

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
    qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
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
    qry.Connection := ConexionPrincipal;

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
      qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
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
    qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
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
  CodArticulo   :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  TipoVariacion :=
    dmmArticulos.unqryTablaG.FieldByName('TIPO_VARIACION_ART').AsString;

  // 3. Validamos que haya un esquema de variación asignado
  if (CodArticulo = '') or (TipoVariacion = '') then
  begin
    ShowMessage(
      'El artículo debe tener asignado un "Tipo de variación" y estar ' +
      'guardado para poder generar SKUs.');
    // Mandamos al usuario al combo para que lo elija
    FCbbTipoVariacion.SetFocus;
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
  // Ctrl+Alt+E -> Empresas.
   with tvLinFac.DataController.DataSet do
    if (
        (pcDetail.ActivePage = tsLineasFactura)        and
        (not(FieldByName('CODIGO_EMP_FACLIN').IsNull))
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
          ResolverCallFactura(ConexionPrincipal, ANumero, ASerie),
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
  frmSel: TfrmMtoModalAddPreciosTar;
  i, j: Integer;
  qryTodasTarifas: TUniQuery;
  qrySkus: TUniQuery;
  ListaSkus, ListaTarifas: TStringList;
  SkusSel, TarifasSel: TStringList;
  // --- VARIABLES PARA CONTROL DE VIGENCIA ---
  TarifasActivas: TStringList;
  Bkm: TBookmark;
  LlaveUnica: string;
  HaySolapamiento, TieneUserHasta, DbHastaIsNull: Boolean;
  UserDesde, UserHasta, DbDesde, DbHasta: TDate;
  Cond1, Cond2: Boolean;
  codArticulo: String;
  PrecioPadre: Double;
  sSku: string;
begin
  inherited;
  UserHasta := 0;
  DbHasta := 0;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  CodArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;

  frmSel := TfrmMtoModalAddPreciosTar.Create(Self);
  // evitamos el caFree heredado para poder hacer Free manual
  frmSel.OnClose := nil;
  ListaSkus    := TStringList.Create;
  ListaTarifas := TStringList.Create;
  SkusSel      := TStringList.Create;
  TarifasSel   := TStringList.Create;
  try
    // --- CARGA DE SKUs ---
    ListaSkus.Add('ARTÍCULO');
    qrySkus := TUniQuery.Create(nil);
    try
      qrySkus.Connection := dmmArticulos.unqryTablaG.Connection;
      qrySkus.SQL.Text :=
        'SELECT CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus ' +
        ' WHERE CODIGO_ART_SKU = :ART ' +
        ' ORDER BY CODIGO_UNIDAD_SKU';
      qrySkus.ParamByName('ART').AsString := CodArticulo;
      qrySkus.Open;
      while not qrySkus.Eof do
      begin
        sSku := Trim(qrySkus.FieldByName('CODIGO_UNIDAD_SKU').AsString);
        if sSku <> '' then
          ListaSkus.Add(sSku);
        qrySkus.Next;
      end;
    finally
      FreeAndNil(qrySkus);
    end;
    frmSel.CargarSkus(ListaSkus);

    // --- CARGA DE TARIFAS ACTIVAS ---
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
        ListaTarifas.Add(
                     qryTodasTarifas.FieldByName('CODIGO_TAR_ARTTAR').AsString);
        qryTodasTarifas.Next;
      end;
    finally
      FreeAndNil(qryTodasTarifas);
    end;
    frmSel.CargarTarifas(ListaTarifas);

    frmSel.ShowModal;
    if frmSel.sFicha <> 'S' then Exit;

    frmSel.ObtenerSkusSeleccionados(SkusSel);
    frmSel.ObtenerTarifasSeleccionadas(TarifasSel);
    UserDesde      := frmSel.FechaDesde;
    TieneUserHasta := frmSel.TieneFechaHasta;
    if TieneUserHasta then UserHasta := frmSel.FechaHasta;

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
          LlaveUnica := dmmArticulos.unqryTarifasArticulos.FieldByName(
            'CODIGO_UNIDAD_ARTTAR').AsString + '|' +
                        dmmArticulos.unqryTarifasArticulos.FieldByName(
                          'CODIGO_TAR_ARTTAR').AsString;
          // Marcamos combinación como ocupada en estas fechas
          TarifasActivas.Add(LlaveUnica);
        end;
        dmmArticulos.unqryTarifasArticulos.Next;
      end;
      if dmmArticulos.unqryTarifasArticulos.BookmarkValid(Bkm) then
        dmmArticulos.unqryTarifasArticulos.GotoBookmark(Bkm);
      dmmArticulos.unqryTarifasArticulos.FreeBookmark(Bkm);

      for i := 0 to SkusSel.Count - 1 do
      begin
        for j := 0 to TarifasSel.Count - 1 do
        begin
          if SkusSel[i] = 'ARTÍCULO' then
            LlaveUnica := '|' + TarifasSel[j]
          else
            LlaveUnica := SkusSel[i] + '|' + TarifasSel[j];

          if TarifasActivas.IndexOf(LlaveUnica) <> -1 then Continue;

          dmmArticulos.unqryTarifasArticulos.Append;
          if SkusSel[i] = 'ARTÍCULO' then
            dmmArticulos.unqryTarifasArticulos.FieldByName(
              'CODIGO_UNIDAD_ARTTAR').AsString := ''
          else
            dmmArticulos.unqryTarifasArticulos.FieldByName(
              'CODIGO_UNIDAD_ARTTAR').AsString := SkusSel[i];

          dmmArticulos.unqryTarifasArticulos.FieldByName(
            'CODIGO_TAR_ARTTAR').AsString := TarifasSel[j];

          // Para filas de SKU heredamos el precio del padre (fila del
          // artículo en la misma tarifa) si existe; si no, queda a 0.
          if SkusSel[i] = 'ARTÍCULO' then
            PrecioPadre := 0
          else
            PrecioPadre := dmmArticulos.ObtenerPrecioTarifaPadre(
                                                       codArticulo,
                                                       TarifasSel[j]);

          dmmArticulos.unqryTarifasArticulos.FieldByName(
            'PRECIO_SALIDA_ARTTAR').AsFloat := PrecioPadre;
          dmmArticulos.unqryTarifasArticulos.FieldByName(
            'PRECIO_FINAL_ARTTAR').AsFloat  := PrecioPadre;
          if PrecioPadre > 0 then
            dmmArticulos.unqryTarifasArticulos.FieldByName(
              'ESACTIVO_ARTTAR').AsString := 'S'
          else
            dmmArticulos.unqryTarifasArticulos.FieldByName(
              'ESACTIVO_ARTTAR').AsString := 'N';

          dmmArticulos.unqryTarifasArticulos.FieldByName(
            'FECHA_DESDE_ARTTAR').AsDateTime := UserDesde;
          if TieneUserHasta then
            dmmArticulos.unqryTarifasArticulos.FieldByName(
              'FECHA_HASTA_ARTTAR').AsDateTime := UserHasta
          else
            dmmArticulos.unqryTarifasArticulos.FieldByName(
              'FECHA_HASTA_ARTTAR').Clear;

          dmmArticulos.unqryTarifasArticulos.Post;
          TarifasActivas.Add(LlaveUnica);
        end;
      end;
    finally
      FreeAndNil(TarifasActivas);
      dmmArticulos.unqryTarifasArticulos.EnableControls;
    end;
    dmmArticulos.unqryTarifasArticulos.Refresh;
    ActualizarVisibilidadColumnaSku;
  finally
    FreeAndNil(SkusSel);
    FreeAndNil(TarifasSel);
    FreeAndNil(ListaSkus);
    FreeAndNil(ListaTarifas);
    FreeAndNil(frmSel);
  end;
end;

procedure TfrmMtoArticulos.dbcTarifasMARGENButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  ds         : TDataSet;
  unicoFld   : TField;
  unico      : Integer;
  codigounidad : string;
  codigoArt  : string;
  descArt    : string;
  codigoTar  : string;
  nombreTar  : string;
  descSku    : string;
  coste      : Double;
  precSalida : Double;
  res        : TCalcularMargenResult;
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
  if ds.FindField('CODIGO_UNIDAD_ARTTAR') <> nil then
    codigoUnidad := ds.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
  codigoArt  := ds.FieldByName('CODIGO_ART_ARTTAR').AsString;
  if ds.FindField('DESCRIPCION_ART') <> nil then
    descArt := ds.FieldByName('DESCRIPCION_ART').AsString;
  codigoTar  := ds.FieldByName('CODIGO_TAR_ARTTAR').AsString;
  if ds.FindField('NOMBRE_TAR_TAR') <> nil then
    nombreTar := ds.FieldByName('NOMBRE_TAR_TAR').AsString;
  if ds.FindField('DESCRIPCION_SKU') <> nil then
    descSku := ds.FieldByName('DESCRIPCION_SKU').AsString;
  coste      := ds.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
  precSalida := ds.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;

  res := TfrmModalCalcularMargen.Ejecutar(
    Self,
    (ds as TUniQuery).Connection,
    unico,
    codigoArt,
    codigoUnidad,
    descArt,
    codigoTar,
    nombreTar,
    descSku,
    coste,
    precSalida);
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
  if not PuedeExportar then
    Abort;
  ExportarExcel(cxgrdProveedores, 'Historico_Proveedores_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnExportarTarifaClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
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
  // Delegar en base: transacción + mensaje de confirmación
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
  ExportarExcel(cxgrdStock, 'Stock_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnReconstruirStockClick(Sender: TObject);
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

procedure TfrmMtoArticulos.btnImprimirEtiquetasClick(Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if (not dsTablaG.Dataset.Active) or dsTablaG.Dataset.IsEmpty then
  begin
    ShowMessage('Seleccione primero un artículo para imprimir sus etiquetas.');
    Exit;
  end;
  formulario := TfrmPrintEtiqArt.Create(Application);
  try
    // Pasamos el DM de ESTA instancia al modal (campo de instancia,
    // no global, asi funciona aunque haya dos Mtos abiertos).
    formulario.DM := dmmArticulos;
    formulario.edtCodArt.Text :=
                        dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString;
    formulario.ShowModal;
  finally
    FreeAndNil(formulario);
  end;
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

  CodArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if CodArticulo = '' then
  begin
    ShowMessage(
      'Seleccione o guarde un artículo antes de generar códigos de barras.');
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
  try
    qrySkus.Connection   := ConexionPrincipal;
    qryInsert.Connection := ConexionPrincipal;
    qryDel.Connection    := ConexionPrincipal;

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
          sCounter := ObtenerSiguienteContador(
            ConexionPrincipal,
            CB_TIPO_DOC,
            IdentidadSesion.Usuario);
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
          qryInsert.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
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
          qryInsert.ParamByName('USR').AsString := IdentidadSesion.Usuario;
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
    ShowMessage(Format('Generación finalizada.' + sLineBreak +
                       '- EAN-13 internos creados: %d' + sLineBreak +
                       '- Filas vacías de fabricante creadas: %d' + sLineBreak +
                       '- SKUs ya completos (saltados): %d' + sLineBreak +
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

  CodArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
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
    qry.Connection := ConexionPrincipal;
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
  try
    formulario.Name := 'frmMtoModalArtTar';
    formulario.Caption := 'Seleccione Tarifas a incorporar al artículo';
    dmmArticulos.FillTarifas(formulario.lstTarifas);
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
      IterateCheckedListArt(formulario.lstTarifas);
  finally
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
        // Evita duplicar: el modal consulta la BBDD y no ve las tarifas aun
        // pendientes de grabar, asi que en cada clic volvia a ofrecer (y
        // anadir) la misma. Si el articulo ya tiene esa tarifa a nivel padre
        // (CODIGO_UNIDAD_ARTTAR vacio), incluso pendiente, no la insertamos.
        if not Locate('CODIGO_TAR_ARTTAR;CODIGO_UNIDAD_ARTTAR',
                      VarArrayOf([item.Caption, '']),
                      [loCaseInsensitive]) then
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
    end;
    Refresh;
  end;
  if bAdded then
    dbcTarifasPRECIOSALIDA.FocusWithSelection;
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
    if not Assigned(AGrid.DataController.DataSource) then Exit;
    ds := AGrid.DataController.DataSource.DataSet;
    // Reutilizamos la lista canonica de aliases (CODIGO_UNIDAD_*).
    var sArt: string := '';
    inLibFotos.LeerArtSkuDeDataSet(ds, sArt, Result);
  end;

begin
  inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  // Si el inherited ya devolvio SKU (improbable en este Mto), no
  // tocamos. Si no, miramos la pestana activa.
  if ACodSku <> '' then Exit;
  if pcDetail.ActivePage = tsSkuMto then
    ACodSku := LeerSkuDeGrid(tvSkuMto)
  else if pcDetail.ActivePage = cxTabSheet3 then       // 8_Stock
    ACodSku := LeerSkuDeGrid(tvStock)
  else if pcDetail.ActivePage = tsMovimientos then     // 9_Movimientos
    ACodSku := LeerSkuDeGrid(tvMovimientos);
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
  if TBusquedaUtils.EjecutarBusqueda(
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
  inherited;
  if FAtributosStock = nil then
    FAtributosStock := TDictionary<string, string>.Create;
  dmmArticulos := tdmDataModule as TdmArticulos;
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
  tvMovimientos.DataController.DataSource := dmmArticulos.dsMovimientosArticulos;
  pkFieldName := 'CODIGO_ART_ART';
  dmmArticulos.unqryTablaG.AfterScroll := OnAfterScrollArticulos;
  // Carga perezosa de Tarifas: solo abrir unqryTarifasArticulos cuando
  // el usuario pase a esa pestaña. Asi quitamos los ~6s de la
  // apertura inicial del Mto.
  pcDetail.OnChange := PcDetailChange;
  InicializarPestanyaPropiedades;
  InicializarPestanyaVariaciones;
  // Filtros de carga (estado, stock, temporadas): poblar la lista de
  // temporadas, leer las preferencias guardadas por usuario y aplicar
  // el filtro reescribiendo el SQL de unqryTablaG antes de que el
  // resto de la rutina lea FArticuloCargado / el primer registro.
  // La persiana se deja desplegada en el .dfm para poder editarla en
  // diseño; al arrancar el form la colapsamos.
  pnlContFiltrosArt.Visible := False;
  pnlFiltrosArt.Height := 22;
  btnToggleFiltrosArt.Caption := #9654'  Filtros de carga';
  CargarTemporadasFiltro;
  LeerFiltrosPerfil;
  // Filtros de sesion del dialogo de precarga (proveedor/familia): arrancan
  // vacios en cada apertura del Mto.
  FFiltroProvCsv := '';
  FFiltroFamCsv  := '';
  FPrecargaPendiente := False;
  // Precarga: DE MOMENTO sin dialogo de acotado. Dejamos la lista CERRADA
  // con el SQL filtrado (por defecto solo activos) y que la
  // carga la haga AbrirTablaPrincipalAsync en segundo plano, mostrando el
  // overlay "Cargando datos..." con barra de progreso. Asi se cargan TODOS
  // los articulos del filtro sin congelar la apertura ni interrumpir con un
  // aviso. (El gate por umbral + dialogo queda en el codigo, desactivado.)
  if Assigned(dmmArticulos) and (dmmArticulos.unqryTablaG <> nil) then
  begin
    dmmArticulos.unqryTablaG.Close;
    dmmArticulos.unqryTablaG.SQL.Text := ConstruirSqlArticulos;
  end;
end;

procedure TfrmMtoArticulos.CargarTemporadasFiltro;
var
  qry: TUniQuery;
  item: TcxCheckComboBoxItem;
begin
  // Lista de temporadas activas para el filtro multi-seleccion. Se
  // resuelve contra fza_propiedades_valores (las mismas que ofrece la
  // ficha del articulo en la pestanya Propiedades para CODIGO_PROP_ARTPROP
  // = 'TEMPORADA').
  ccbFiltroTemporadaArt.Properties.Items.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT PV FROM fza_propiedades_valores ' +
      ' WHERE ID_PROP_PV = ''TEMPORADA'' AND ESACTIVO_PV = ''S'' ' +
      ' ORDER BY PV';
    qry.Open;
    while not qry.Eof do
    begin
      item := ccbFiltroTemporadaArt.Properties.Items.Add;
      item.Description := qry.FieldByName('PV').AsString;
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoArticulos.LeerFiltrosPerfil;
var
  sEstado, sStock, sTempCsv: string;
  lst: TStringList;
  i, idx: Integer;
begin
  // FFiltrosArtCargando bloquea el OnEditValueChanged de los controles
  // mientras los inicializamos: sin esta guarda cada AsignacionCargaria
  // disparara una reaplicacion del SQL (3 Closes/Opens en cadena al
  // abrir el Mto).
  FFiltrosArtCargando := True;
  try
    // Precarga por defecto: solo activos ('S'), sin exigir stock ('N').
    // Asi las altas nuevas aparecen en el listado aunque aun no tengan
    // movimientos ni existencias.
    sEstado  := Trim(GetPerfilValueDef(oPerfilDic, 'oFiltroEstado',     'S'));
    sStock   := Trim(GetPerfilValueDef(oPerfilDic, 'oFiltroConStock',   'N'));
    sTempCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroTemporadas', '');

    if SameText(sEstado, 'T') then
      cbbFiltroEstadoArt.ItemIndex := 0
    else if SameText(sEstado, 'N') then
      cbbFiltroEstadoArt.ItemIndex := 2
    else
      cbbFiltroEstadoArt.ItemIndex := 1; // 'S' o cualquier valor desconocido

    chkFiltroConStockArt.Checked := SameText(sStock, 'S');

    // Marcamos las temporadas previamente seleccionadas. Si una temporada
    // guardada ya no existe (se desactivo en propiedades), simplemente se
    // ignora — el filtro no la incluira en el IN.
    lst := TStringList.Create;
    try
      lst.Delimiter := ';';
      lst.StrictDelimiter := True;
      lst.DelimitedText := sTempCsv;
      for i := 0 to ccbFiltroTemporadaArt.Properties.Items.Count - 1 do
      begin
        idx := lst.IndexOf(
                         ccbFiltroTemporadaArt.Properties.Items[i].Description);
        if idx >= 0 then
          ccbFiltroTemporadaArt.States[i] := cbsChecked
        else
          ccbFiltroTemporadaArt.States[i] := cbsUnchecked;
      end;
    finally
      FreeAndNil(lst);
    end;
  finally
    FFiltrosArtCargando := False;
  end;
end;

procedure TfrmMtoArticulos.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                     const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sEstado, sTemporadas: string;
begin
  // Volcamos los filtros de carga al batch del sbGrabarGridClick, asi se
  // graban junto con el resto de preferencias del Mto y respetan el
  // ambito (sPermisos) elegido por el usuario en el dialogo de grabar.
  if not Assigned(cbbFiltroEstadoArt) then Exit;

  item.UserGroup := sPermisos;
  item.KeyPerfil := Self.Name;

  // Estado: T=Todos, S=Solo activos, N=Solo inactivos
  case cbbFiltroEstadoArt.ItemIndex of
    0: sEstado := 'T';
    2: sEstado := 'N';
  else
    sEstado := 'S';
  end;
  item.SubKey := 'oFiltroEstado';
  item.Value  := sEstado;
  oList.Add(item);

  item.SubKey := 'oFiltroConStock';
  if chkFiltroConStockArt.Checked then
    item.Value := 'S'
  else
    item.Value := 'N';
  oList.Add(item);

  // Temporadas: CSV con ';' como separador (StrictDelimiter al leer).
  sTemporadas := '';
  for i := 0 to ccbFiltroTemporadaArt.Properties.Items.Count - 1 do
    if ccbFiltroTemporadaArt.States[i] = cbsChecked then
    begin
      if sTemporadas <> '' then sTemporadas := sTemporadas + ';';
      sTemporadas := sTemporadas +
                       ccbFiltroTemporadaArt.Properties.Items[i].Description;
    end;
  item.SubKey := 'oFiltroTemporadas';
  item.Value  := sTemporadas;
  oList.Add(item);
end;

function TfrmMtoArticulos.CsvAInList(const aCsv: string): string;
var
  lst: TStringList;
  i: Integer;
begin
  // CSV ';' -> 'a', 'b', 'c'  (entrecomillado para el IN). Vacio si no hay
  // nada. Duplicamos comillas via QuotedStr aunque los valores vengan de
  // listas controladas (temporadas/codigos), por higiene anti-inyeccion.
  Result := '';
  if Trim(aCsv) = '' then Exit;
  lst := TStringList.Create;
  try
    lst.Delimiter := ';';
    lst.StrictDelimiter := True;
    lst.DelimitedText := aCsv;
    for i := 0 to lst.Count - 1 do
      if Trim(lst[i]) <> '' then
      begin
        if Result <> '' then Result := Result + ', ';
        Result := Result + QuotedStr(Trim(lst[i]));
      end;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmMtoArticulos.CsvTemporadasControl: string;
var
  i: Integer;
begin
  // Estado marcado del ccbFiltroTemporadaArt como CSV ';'.
  Result := '';
  for i := 0 to ccbFiltroTemporadaArt.Properties.Items.Count - 1 do
    if ccbFiltroTemporadaArt.States[i] = cbsChecked then
    begin
      if Result <> '' then Result := Result + ';';
      Result := Result + ccbFiltroTemporadaArt.Properties.Items[i].Description;
    end;
end;

procedure TfrmMtoArticulos.MarcarTemporadasControl(const aCsv: string);
var
  lst: TStringList;
  i: Integer;
begin
  // Marca en el ccbFiltroTemporadaArt las temporadas presentes en aCsv. No
  // dispara la reaplicacion (FFiltrosArtCargando) porque el llamador ya
  // controla el ciclo de reapertura.
  FFiltrosArtCargando := True;
  lst := TStringList.Create;
  try
    lst.Delimiter := ';';
    lst.StrictDelimiter := True;
    lst.DelimitedText := aCsv;
    for i := 0 to ccbFiltroTemporadaArt.Properties.Items.Count - 1 do
      if lst.IndexOf(
              ccbFiltroTemporadaArt.Properties.Items[i].Description) >= 0 then
        ccbFiltroTemporadaArt.States[i] := cbsChecked
      else
        ccbFiltroTemporadaArt.States[i] := cbsUnchecked;
  finally
    FreeAndNil(lst);
    FFiltrosArtCargando := False;
  end;
end;

function TfrmMtoArticulos.ConstruirWhereArticulos(const aTempCsv, aPrvCsv,
                                                  aFamCsv: string): string;
var
  sb: TStringBuilder;
  sEstado, sIn: string;
begin
  sb := TStringBuilder.Create;
  try
    sb.AppendLine('WHERE 1 = 1');
    // Filtro estado: ItemIndex 0=Todos, 1=Solo activos, 2=Solo inactivos
    case cbbFiltroEstadoArt.ItemIndex of
      1: sEstado := 'S';
      2: sEstado := 'N';
    else
      sEstado := '';
    end;
    if sEstado <> '' then
      sb.AppendLine('  AND vi_articulos.ESACTIVO_ART = ' + QuotedStr(sEstado));
    // Filtro stock: existencia > 0 en al menos un SKU/almacen
    if chkFiltroConStockArt.Checked then
      sb.AppendLine(
        '  AND EXISTS (SELECT 1 FROM fza_articulos_skus sk ' +
                      ' JOIN fza_articulos_stockactual stk ' +
                      '   ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU ' +
                      ' WHERE sk.CODIGO_ART_SKU = vi_articulos.CODIGO_ART_ART ' +
                      '   AND stk.CANTIDAD_STK > 0)');
    // Filtro temporadas (CSV del control o del dialogo)
    sIn := CsvAInList(aTempCsv);
    if sIn <> '' then
      sb.AppendLine('  AND vi_articulos.TEMPORADA_ART IN (' + sIn + ')');
    // Filtro proveedores (codigo del proveedor principal del articulo)
    sIn := CsvAInList(aPrvCsv);
    if sIn <> '' then
      sb.AppendLine('  AND vi_articulos.CODIGO_PRV_AP IN (' + sIn + ')');
    // Filtro familias
    sIn := CsvAInList(aFamCsv);
    if sIn <> '' then
      sb.AppendLine('  AND vi_articulos.CODIGO_FAM_ART IN (' + sIn + ')');
    Result := sb.ToString;
  finally
    FreeAndNil(sb);
  end;
end;

function TfrmMtoArticulos.ConstruirSqlArticulos: string;
begin
  Result := 'SELECT * FROM vi_articulos' + sLineBreak +
            ConstruirWhereArticulos(CsvTemporadasControl,
                                    FFiltroProvCsv, FFiltroFamCsv) +
            'ORDER BY vi_articulos.ORDEN_ART';
end;

function TfrmMtoArticulos.ContarArticulos(const aTempCsv, aPrvCsv,
                                          aFamCsv: string): Integer;
var
  qry: TUniQuery;
  cn: TUniConnection;
begin
  Result := 0;
  if not Assigned(dmmArticulos) or (dmmArticulos.unqryTablaG = nil) then Exit;
  // Misma conexion (propia del Mto) que usara la carga real.
  cn := dmmArticulos.unqryTablaG.Connection;
  if cn = nil then
    cn := ConexionPrincipal;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := cn;
    qry.SQL.Text := 'SELECT COUNT(*) AS N FROM vi_articulos ' +
                    ConstruirWhereArticulos(aTempCsv, aPrvCsv, aFamCsv);
    qry.Open;
    Result := qry.FieldByName('N').AsInteger;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoArticulos.AbrirListaArticulos(aVacia: Boolean = False);
var
  qry: TUniQuery;
  sSql: string;
begin
  if not Assigned(dmmArticulos) then Exit;
  qry := dmmArticulos.unqryTablaG;
  if qry = nil then Exit;
  sSql := ConstruirSqlArticulos;
  // aVacia: apertura instantanea (sin traer filas) para el caso
  // "demasiados articulos"; el dialogo de filtrado la reabrira acotada.
  if aVacia then
    sSql := sSql + ' LIMIT 0';
  qry.DisableControls;
  try
    qry.Close;
    qry.SQL.Text := sSql;
    qry.Open;
  finally
    qry.EnableControls;
  end;
end;

procedure TfrmMtoArticulos.CargarArticuloActual;
begin
  // Cola comun tras (re)abrir la lista: resolver el articulo en foco y
  // cargar su ficha (propiedades, variaciones, mapa de atributos y stock
  // si la pestaña Stock esta activa). Defensivo ante lista cerrada/vacia.
  FArticuloCargado := '';
  if dmmArticulos.unqryTablaG.Active
     and (not dmmArticulos.unqryTablaG.IsEmpty)
     and (dmmArticulos.unqryTablaG.FindField('CODIGO_ART_ART') <> nil) then
    FArticuloCargado :=
      dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if Assigned(FGestorProp) then
    FGestorProp.CargarPropiedades(FArticuloCargado);
  if Assigned(FGestorVar) then
    FGestorVar.CargarVariaciones(FArticuloCargado);
  ActualizarVisibilidadVariaciones;
  ActualizarVisibilidadColumnaSku;
  if (FAtributosStock <> nil) and (FArticuloCargado <> '') then
    CargarMapaAtributosArticulo(
      ConexionPrincipal,
      FArticuloCargado,
      FAtributosStock);
  if (FArticuloCargado <> '') and Assigned(dmmArticulos)
     and (pcDetail.ActivePage = cxTabSheet3) then
  begin
    dmmArticulos.unqryStockArticulosAfterScroll(dmmArticulos.unqryTablaG);
    FStockArticuloCargado := FArticuloCargado;
  end;
end;

procedure TfrmMtoArticulos.MostrarDialogoRefinar;
var
  cn: TUniConnection;
  sTempIn, sPrvIn, sFamIn, sTempOut, sPrvOut, sFamOut: string;
begin
  if not Assigned(dmmArticulos) or (dmmArticulos.unqryTablaG = nil) then Exit;
  cn := dmmArticulos.unqryTablaG.Connection;
  if cn = nil then
    cn := ConexionPrincipal;
  sTempIn := CsvTemporadasControl;
  sPrvIn  := FFiltroProvCsv;
  sFamIn  := FFiltroFamCsv;
  // El dialogo se invoca tambien desde TrasPrecargaAsync (callback async),
  // donde una excepcion se tragaria dejando la lista en blanco sin aviso.
  // Lo blindamos: si el dialogo falla, se loguea y el llamador sigue con
  // AbrirListaArticulos, asi nunca queda una lista vacia silenciosa.
  try
    if TfrmModalFiltroArt.Ejecutar(Self, cn, UMBRAL_PRECARGA,
         sTempIn, sPrvIn, sFamIn,
         function(const t, p, f: string): Integer
         begin
           Result := ContarArticulos(t, p, f);
         end,
         sTempOut, sPrvOut, sFamOut) then
    begin
      MarcarTemporadasControl(sTempOut);
      FFiltroProvCsv := sPrvOut;
      FFiltroFamCsv  := sFamOut;
    end;
  except
    on E: Exception do
      inLibLog.Log.LogError('[Articulos.MostrarDialogoRefinar] ' +
        E.ClassName + ': ' + E.Message);
  end;
end;

procedure TfrmMtoArticulos.AplicarFiltrosArticulos;
begin
  // Cambio manual de filtros (estado/stock/temporadas) o boton "Cargar
  // ahora". DE MOMENTO sin dialogo: se recarga TODA la lista con el filtro
  // elegido, en segundo plano y con el overlay "Cargando datos..." + barra
  // de progreso (via la carga async).
  if Assigned(dmmArticulos) and (dmmArticulos.unqryTablaG <> nil) then
  begin
    dmmArticulos.unqryTablaG.Close;
    dmmArticulos.unqryTablaG.SQL.Text := ConstruirSqlArticulos;
    AbrirTablaPrincipalAsync;
  end;
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
var
  i: Integer;
begin
  // Búsqueda externa (Ctrl+A desde otro Mto): sin filtros de carga
  // para que salgan todos los artículos. Resetear controles y SQL
  // antes de que inherited añada el WHERE de búsqueda vía parser.
  FFiltrosArtCargando := True;
  try
    cbbFiltroEstadoArt.ItemIndex := 0;
    chkFiltroConStockArt.Checked := False;
    for i := 0 to ccbFiltroTemporadaArt.Properties.Items.Count - 1 do
      ccbFiltroTemporadaArt.States[i] := cbsUnchecked;
  finally
    FFiltrosArtCargando := False;
  end;
  // Tambien los filtros de sesion del dialogo y la bandera de precarga: la
  // busqueda externa va sin acotar (el WHERE lo impone el parser de Ctrl+A).
  FFiltroProvCsv := '';
  FFiltroFamCsv  := '';
  FPrecargaPendiente := False;
  if Assigned(dmmArticulos) and (dmmArticulos.unqryTablaG <> nil) then
  begin
    dmmArticulos.unqryTablaG.Close;
    dmmArticulos.unqryTablaG.SQL.Text := ConstruirSqlArticulos;
  end;
  pnlContFiltrosArt.Visible := False;
  pnlFiltrosArt.Height := 22;
  btnToggleFiltrosArt.Caption := #9654'  Filtros de carga';
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
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 44;
begin
  // Persiana: arranca cerrada (Visible=False en el DFM) y al pulsar la
  // cabecera alternamos visibilidad y altura del contenedor padre.
  pnlContFiltrosArt.Visible := not pnlContFiltrosArt.Visible;
  if pnlContFiltrosArt.Visible then
  begin
    pnlFiltrosArt.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltrosArt.Caption := #9660'  Filtros de carga';
  end
  else
  begin
    pnlFiltrosArt.Height := ALTO_CABECERA;
    btnToggleFiltrosArt.Caption := #9654'  Filtros de carga';
  end;
end;

procedure TfrmMtoArticulos.cbbFiltroEstadoArtPropertiesEditValueChanged(
                                                              Sender: TObject);
begin
  // Aplicamos el filtro inmediatamente, pero NO persistimos: la grabacion
  // a fza_usuarios_perfiles se hace explicitamente desde sbGrabarGridClick
  // (mismo patron que el resto de ajustes del Mto: ancho de columnas,
  // captions, etc.).
  if FFiltrosArtCargando then Exit;
  AplicarFiltrosArticulos;
end;

procedure TfrmMtoArticulos.chkFiltroConStockArtPropertiesEditValueChanged(
                                                              Sender: TObject);
begin
  if FFiltrosArtCargando then Exit;
  AplicarFiltrosArticulos;
end;

procedure TfrmMtoArticulos.ccbFiltroTemporadaArtPropertiesCloseUp(
                                                              Sender: TObject);
begin
  if FFiltrosArtCargando then Exit;
  AplicarFiltrosArticulos;
end;

procedure TfrmMtoArticulos.btnCargarAhoraArtClick(Sender: TObject);
begin
  // Dispara la carga de la lista con los filtros actuales del panel
  // (estado/stock/temporadas) de forma explicita, sin depender del
  // auto-aplicado al cerrar el desplegable de temporadas.
  AplicarFiltrosArticulos;
end;

procedure TfrmMtoArticulos.btnGuardarPrecargaArtClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
  oList: TPerfilList;
begin
  // Guarda SOLO los filtros de carga (estado/stock/temporadas) en el perfil.
  // El cambio ya se aplica en caliente al marcar/desmarcar; este boton lo
  // hace permanente sin pasar por "Grabar Grid" (que ademas reescribe anchos
  // de columna y captions). Se pregunta el ambito como en Grabar Grid.
  sPermisos := '';
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text   := Self.Name;
    formulario.edtDescripcion.Text    := 'Guardar precarga';
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
      sPermisos := formulario.cbbPermisos.Text;
  finally
    FreeAndNil(formulario);
  end;
  // Solo persistimos si el usuario confirmo el ambito en el dialogo.
  if sPermisos <> '' then
  begin
    Screen.Cursor := crHourGlass;
    oList := TPerfilList.Create;
    try
      // Mismo volcado de filtros que usa Grabar Grid; el upsert de
      // GrabarPerfiles sobrescribe los valores previos del ámbito.
      RecogerPerfilesParticulares(oList, sPermisos);
      ConexionPrincipal.StartTransaction;
      try
        PerfilesUsuario.GrabarPerfiles(oList);
        ConexionPrincipal.Commit;
      except
        ConexionPrincipal.Rollback;
        raise;
      end;
    finally
      FreeAndNil(oList);
      Screen.Cursor := crDefault;
    end;
    ShowMessage('Precarga guardada.');
  end;
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
    ConexionPrincipal,   // <-- ajusta al nombre real de tu TUniConnection
    IdentidadSesion.Usuario               // <-- ajusta a tu función/variable de usuario
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
    ConexionPrincipal,
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
begin
  if DataSet.ControlsDisabled then
    Exit;
  if dmmArticulos.unqrySkus.Active = False then
    Exit;
  // 1. Si estamos creando un artículo nuevo, limpiamos la pantalla una sola vez
  // y salimos
  if DataSet.State = dsInsert then
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
    Exit;
  end;

  // 2. Si estamos editando, ignoramos los scrolls fantasma
  if DataSet.State = dsEdit then Exit;

  CodArticulo := DataSet.FieldByName('CODIGO_ART_ART').AsString;

  // 3. EL ESCUDO: Si el artículo es exactamente el mismo que ya está dibujado,
  // ¡no hagas nada!
  if FArticuloCargado = CodArticulo then
    Exit;

  // Actualizamos nuestra memoria
  FArticuloCargado := CodArticulo;

  // [PERF] Cronometros por tramo. Este handler es el sospechoso principal
  // de los gaps de 5s que se ven al abrir/navegar Articulos. Cada
  // sub-tarea se mide independientemente y se vuelca al log+memo SQL.
  swTotal := TStopwatch.StartNew;
  msCargarProp := 0;
  msCargarVar := 0;
  msActVisVar := 0;
  msAseguraSku := 0;
  msRefSkus := 0;
  msRefVarArt := 0;
  msMapaAtr := 0;
  msStockAS := 0;
  msActVisCol := 0;

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
  if FAtributosStock <> nil then
  begin
    swTramo := TStopwatch.StartNew;
    CargarMapaAtributosArticulo(
      ConexionPrincipal,
      CodArticulo,
      FAtributosStock);
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

  inLibLog.Log.LogPerf('Articulos.AfterScroll',
    Format('art=%s | Prop=%d | Var=%d | ActVar=%d | Sku=%d | RefSkus=%d | ' +
           'RefVarArt=%d | MapaAtr=%d | StockAS=%d | ActColSku=%d',
           [CodArticulo, msCargarProp, msCargarVar, msActVisVar,
            msAseguraSku, msRefSkus, msRefVarArt, msMapaAtr, msStockAS,
            msActVisCol]),
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoArticulos.cxButton11Click(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(cxGrdMovimientos, 'Movimientos_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.cxDBComboBox1PropertiesEditValueChanged(
  Sender: TObject);
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

procedure TfrmMtoArticulos.cxDBCheckBox1PropertiesEditValueChanged(
  Sender: TObject);
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
                                FindField(
                                  'PORCENTAJE_DTO_ARTTAR').AsFloat / 100));
        FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
                                    ( FindField(
                                      'PRECIO_SALIDA_ARTTAR').AsFloat -
                                      FindField('PRECIO_DTO_ARTTAR').AsFloat
                                    );
      end;
    end;
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOFINALPropertiesEditValueChanged(
  Sender: TObject);
var
    e: TcxCustomEdit;
    pct: Double;
  begin
  inherited;
  if (dmmArticulos <> nil) then
    with dmmArticulos.unqryTarifasArticulos do
    begin
      if ((State = dsInsert) or (State = dsEdit)) then
      begin
        e := Sender as TcxCustomEdit;
        FindField('PRECIO_FINAL_ARTTAR').AsString := VarToStr(e.EditingValue);
        pct := FindField('PORCENTAJE_DTO_ARTTAR').AsFloat;
        // Mantener el % fijo: salida = final / (1 - pct/100). Con pct
        // fuera de (0,100) no se puede derivar la salida (división por
        // cero o salida negativa): se trata como fila sin descuento.
        if (pct > 0) and (pct < 100) then
        begin
          FindField('PRECIO_SALIDA_ARTTAR').AsFloat :=
                              (FindField('PRECIO_FINAL_ARTTAR').AsFloat /
                               (1 - (pct / 100)));
          FindField('PRECIO_DTO_ARTTAR').AsFloat :=
                              (FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
                               FindField('PRECIO_FINAL_ARTTAR').AsFloat);
        end
        else
        begin
          FindField('PRECIO_SALIDA_ARTTAR').AsString :=
                                       FindField(
                                         'PRECIO_FINAL_ARTTAR').AsString;
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
                                    ( FindField(
                                      'PRECIO_SALIDA_ARTTAR').AsFloat -
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
                               FindField(
                                 'PRECIO_SALIDA_ARTTAR').AsFloat) * 100);
          FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
                                    ( FindField(
                                      'PRECIO_SALIDA_ARTTAR').AsFloat -
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
    FCbbTipoVariacion.Properties.ReadOnly := not (dsTablaG.State in
                                                  [dsInsert, dsEdit]);
end;

procedure TfrmMtoArticulos.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FGestorProp) then
    FreeAndNil(FGestorProp);
  if Assigned(FGestorVar) then
    FreeAndNil(FGestorVar);
  FreeAndNil(FAtributosStock);
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
  // 'A' = override por artículo, 'C' = conjunto del artículo, 'G' = global
  if AText = 'A' then AText := 'Artículo'
  else if AText = 'C' then AText := 'Conjunto'
  else if AText = 'G' then AText := 'Global'
  else AText := '';
end;

function TfrmMtoArticulos.PreguntarAmbitoBasico(
  const ACodArt, AValorAv: string): TAmbitoBasico;
// Cuando el helper del SKU tiene que CREAR un atributo basico nuevo
// (porque la fila aun no tiene ninguno) preguntamos al usuario que
// tipo quiere: global (compartido entre articulos) o ad-hoc (exclusivo
// con prefijo AD_<articulo>_). Si elige cancelar, no se crea nada y
// la edicion se descarta.
//
// MB_YESNOCANCEL nos da 3 botones de serie:
//   Si       -> Global (Recommended por defecto)
//   No       -> Ad-hoc (compatibilidad con comportamiento previo)
//   Cancelar -> abCancelar
var
  CodGlobal, CodAdHoc, Texto: string;
begin
  CodGlobal := StringReplace(Trim(AValorAv), ' ', '_', [rfReplaceAll]);
  if CodGlobal = '' then CodGlobal := '(sin valor)';
  CodAdHoc  := Format('AD_%s_%s', [ACodArt, CodGlobal]);

  Texto :=
    'Este SKU todavia no tiene un atributo basico asignado para ' +
    'este valor.' + #13#10#13#10 +
    'Si       -> Crear basico GLOBAL "' + CodGlobal + '"' + #13#10 +
    '            (compartido con otros articulos que usen ese valor)' +
    #13#10#13#10 +
    'No       -> Crear basico AD-HOC "' + CodAdHoc + '"' + #13#10 +
    '            (exclusivo de este articulo)' +
    #13#10#13#10 +
    'Cancelar -> No crear nada por ahora.';

  case Application.MessageBox(
         PChar(Texto),
         'Como crear el atributo basico',
         MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON1) of
    ID_YES : Result := abGlobal;
    ID_NO  : Result := abAdHoc;
  else
    Result := abCancelar;
  end;
end;

function TfrmMtoArticulos.AsegurarFilaSA(
  const ACodSKU, AIdVaAv, AValorAv: string): Integer;
// Materializa una fila virtual del UNION de vi_atributos_sku_basico:
//   1) busca o crea el AV (par ID_VA_AV + AV de fza_atributos_valores)
//   2) inserta el bridge fza_atributos_sku (SKU <-> AV) si no existe
//   3) devuelve el ID_AV resultante para que el llamante pueda colgar
//      ya el atributo basico del articulo
// Sin esto, los SKUs huerfanos (sin filas en SA) salen como meras filas
// informativas en el grid y editar el basico no tiene donde aterrizar.
var
  qry: TUniQuery;
begin
  Result := 0;
  if (ACodSKU = '') or (AIdVaAv = '') then Exit;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    // 1) Buscar AV existente para esta variacion + valor.
    qry.SQL.Text :=
      'SELECT ID_AV FROM fza_atributos_valores '   +
      ' WHERE ID_VA_AV = :IDVA AND AV = :VAL '     +
      ' LIMIT 1';
    qry.ParamByName('IDVA').AsString := AIdVaAv;
    qry.ParamByName('VAL').AsString  := AValorAv;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('ID_AV').AsInteger;
    qry.Close;

    // 2) Si no existia, crearlo.
    if Result = 0 then
    begin
      qry.SQL.Text :=
        'INSERT INTO fza_atributos_valores '                             +
        '   (ID_VA_AV, AV, ORDEN_AV, '                                   +
        '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '               +
        'VALUES (:IDVA, :VAL, 0, NOW(), :USR, :USR)';
      qry.ParamByName('IDVA').AsString := AIdVaAv;
      qry.ParamByName('VAL').AsString  := AValorAv;
      qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
      qry.Execute;

      qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
      qry.Open;
      Result := qry.FieldByName('ID').AsInteger;
      qry.Close;
    end;

    if Result = 0 then Exit;

    // 3) Enlazar SKU <-> AV en la tabla puente (idempotente).
    qry.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_sku '                            +
      '   (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, '                             +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '                 +
      'VALUES (:SKU, :AV, NOW(), :USR, :USR)';
    qry.ParamByName('SKU').AsString  := ACodSKU;
    qry.ParamByName('AV').AsInteger  := Result;
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

function TfrmMtoArticulos.AsegurarBasicoFilaActual: Integer;
// Devuelve el ID_ATB del básico aplicable a la fila activa del detalle
// de SKUs. Si la fila no tiene básico (override blocked o nada heredado)
// crea uno ad-hoc en fza_atributos_basicos con el VALOR_AV como nombre,
// y persiste el override per-artículo apuntando a él. Así, cuando el
// usuario edita Nombre/Valor/Unidad sin haber elegido básico, tenemos
// un registro donde grabarlo.
//
// Devuelve 0 si la fila no es válida (sin SKU activo, etc.).
var
  ds      : TDataSet;
  qry     : TUniQuery;
  CodArt  : string;
  IdAv    : Integer;
  IdVaAv  : string;
  ValorAv : string;
  Codigo  : string;
begin
  Result := 0;
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryDetallesAtributos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;

  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;

  if not ds.FieldByName('ID_ATB_AV').IsNull then
  begin
    Result := ds.FieldByName('ID_ATB_AV').AsInteger;
    Exit;
  end;

  CodArt  := ds.FieldByName('CODIGO_ART_SKU').AsString;
  IdVaAv  := ds.FieldByName('ID_VA_AV').AsString;
  ValorAv := ds.FieldByName('VALOR_AV').AsString;
  // Fila virtual del UNION de vi_atributos_sku_basico: el SKU no tenia
  // todavia su atributo enlazado en fza_atributos_sku. Materializamos
  // (AV + bridge SA) para tener un ID_AV real al que colgar el basico.
  if ds.FieldByName('ID_AV').IsNull then
    IdAv := AsegurarFilaSA(ds.FieldByName('CODIGO_UNIDAD_SKU').AsString,
                           IdVaAv, ValorAv)
  else
    IdAv := ds.FieldByName('ID_AV').AsInteger;
  if (CodArt = '') or (IdAv = 0) or (IdVaAv = '') then Exit;

  // CODIGO_ATB unico en su variacion (UQ ID_VA_ATB+CODIGO_ATB).
  // Si el valor esta vacio caemos al ID interno como fallback para
  // evitar colisiones. Si hay valor, preguntamos al usuario si quiere
  // un basico GLOBAL (compartido, CODIGO_ATB = valor) o AD-HOC (con
  // prefijo AD_<articulo>_, exclusivo del articulo). De esta forma
  // dejamos de imponer el prefijo AD_ sin preguntar.
  if Trim(ValorAv) = '' then
    Codigo := Format('AD_%s_%d', [CodArt, IdAv])
  else
  begin
    case PreguntarAmbitoBasico(CodArt, ValorAv) of
      abCancelar: Exit;
      abGlobal  : Codigo := StringReplace(Trim(ValorAv), ' ', '_',
                                          [rfReplaceAll]);
      abAdHoc   : Codigo := Format('AD_%s_%s',
                                   [CodArt,
                                    StringReplace(Trim(ValorAv), ' ', '_',
                                                  [rfReplaceAll])]);
    end;
  end;
  // CODIGO_ATB es varchar(100): truncamos por si el articulo + valor
  // se nos van de largo.
  if Length(Codigo) > 100 then
    Codigo := Copy(Codigo, 1, 100);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    // 1) Insertar (o reutilizar) básico ad-hoc.
    qry.SQL.Text :=
      'INSERT INTO fza_atributos_basicos '              +
      '   (ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, '         +
      '    ESACTIVO_ATB, '                              +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '+
      'VALUES (:IDVA, :COD, :NOM, ''S'', '              +
      '        NOW(), :USR, :USR) '                     +
      'ON DUPLICATE KEY UPDATE '                        +
      '   USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    qry.ParamByName('IDVA').AsString := IdVaAv;
    qry.ParamByName('COD').AsString  := Codigo;
    qry.ParamByName('NOM').AsString  := ValorAv;
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.Execute;

    // 2) Leer el ID resultante (sea recién creado o ya existente).
    qry.SQL.Text :=
      'SELECT ID_ATB FROM fza_atributos_basicos '       +
      ' WHERE ID_VA_ATB  = :IDVA '                      +
      '   AND CODIGO_ATB = :COD';
    qry.ParamByName('IDVA').AsString := IdVaAv;
    qry.ParamByName('COD').AsString  := Codigo;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('ID_ATB').AsInteger;
    qry.Close;
    if Result = 0 then Exit;

    // 3) Override per-artículo apuntando al nuevo básico.
    qry.SQL.Text :=
      'INSERT INTO fza_articulos_atributos_basicos '   +
      '   (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, '    +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '+
      'VALUES (:ART, :AV, :ATB, NOW(), :USR, :USR) '   +
      'ON DUPLICATE KEY UPDATE '                       +
      '   ID_ATB_AAB    = VALUES(ID_ATB_AAB), '        +
      '   USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    qry.ParamByName('ART').AsString  := CodArt;
    qry.ParamByName('AV').AsInteger  := IdAv;
    qry.ParamByName('ATB').AsInteger := Result;
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosNOMBRE_ATBPropertiesEditValueChanged(
  Sender: TObject);
var
  qry  : TUniQuery;
  ds   : TDataSet;
  vNew : Variant;
  IdAtb: Integer;
begin
  if (not Assigned(dmmArticulos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  // Si la fila no tiene básico aún (bloqueado o heredado=NULL), creamos
  // uno ad-hoc para que la edición tenga un destino.
  IdAtb := AsegurarBasicoFilaActual;
  if IdAtb = 0 then
  begin
    if ds.State in [dsEdit, dsInsert] then ds.Cancel;
    Exit;
  end;
  vNew := (Sender as TcxCustomEdit).EditingValue;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_atributos_basicos '   +
      '   SET NOMBRE_ATB    = :VAL, '   +
      '       USUARIO_MODIF = :USR '    +
      ' WHERE ID_ATB = :ID';
    qry.ParamByName('VAL').AsString  := VarToStr(vNew);
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.ParamByName('ID').AsInteger  := IdAtb;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  if ds.State in [dsEdit, dsInsert] then ds.Cancel;
  ds.Refresh;
  if Assigned(dmmArticulos.unqryAtributosBasicosLookup) then
    dmmArticulos.unqryAtributosBasicosLookup.Refresh;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosVALOR_NUM_ATBPropertiesEditValueChanged(
  Sender: TObject);
var
  qry  : TUniQuery;
  ds   : TDataSet;
  vNew : Variant;
  IdAtb: Integer;
begin
  if (not Assigned(dmmArticulos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  IdAtb := AsegurarBasicoFilaActual;
  if IdAtb = 0 then
  begin
    if ds.State in [dsEdit, dsInsert] then ds.Cancel;
    Exit;
  end;
  vNew := (Sender as TcxCustomEdit).EditingValue;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_atributos_basicos '   +
      '   SET VALOR_NUM_ATB = :VAL, '   +
      '       USUARIO_MODIF = :USR '    +
      ' WHERE ID_ATB = :ID';
    if VarIsNull(vNew) or (VarToStr(vNew) = '') then
      qry.ParamByName('VAL').Clear
    else
      qry.ParamByName('VAL').AsFloat := Double(vNew);
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.ParamByName('ID').AsInteger  := IdAtb;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  if ds.State in [dsEdit, dsInsert] then ds.Cancel;
  ds.Refresh;
  if Assigned(dmmArticulos.unqryAtributosBasicosLookup) then
    dmmArticulos.unqryAtributosBasicosLookup.Refresh;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosUNIDAD_ATBPropertiesEditValueChanged(
  Sender: TObject);
var
  qry  : TUniQuery;
  ds   : TDataSet;
  vNew : Variant;
  IdAtb: Integer;
begin
  if (not Assigned(dmmArticulos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  IdAtb := AsegurarBasicoFilaActual;
  if IdAtb = 0 then
  begin
    if ds.State in [dsEdit, dsInsert] then ds.Cancel;
    Exit;
  end;
  vNew := (Sender as TcxCustomEdit).EditingValue;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_atributos_basicos '   +
      '   SET UNIDAD_ATB    = :VAL, '   +
      '       USUARIO_MODIF = :USR '    +
      ' WHERE ID_ATB = :ID';
    qry.ParamByName('VAL').AsString  := VarToStr(vNew);
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.ParamByName('ID').AsInteger  := IdAtb;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  if ds.State in [dsEdit, dsInsert] then ds.Cancel;
  ds.Refresh;
  if Assigned(dmmArticulos.unqryAtributosBasicosLookup) then
    dmmArticulos.unqryAtributosBasicosLookup.Refresh;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged(
  Sender: TObject);
// Descripcion del color POR ARTICULO: vive en
// fza_articulos_atributos_basicos.DESCRIPCION_AAB (PK CODIGO_ART_AAB+ID_AV_AAB),
// distinta para cada articulo. Si la fila override aun no existe la creamos
// sembrando ID_ATB_AAB con el basico ya resuelto (ID_ATB_AV de la vista) para
// NO alterar el color mostrado: una fila con ID_ATB_AAB NULL significa
// "bloqueo / sin basico". El ON DUPLICATE KEY UPDATE toca solo la descripcion,
// asi que descripcion y basico se editan de forma independiente.
var
  qry   : TUniQuery;
  ds    : TDataSet;
  IdAv  : Integer;
  CodArt: string;
  vNew  : Variant;
  fldAtb: TField;
begin
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryDetallesAtributos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  CodArt := ds.FieldByName('CODIGO_ART_SKU').AsString;
  // Fila virtual del UNION: materializamos AV+SA para tener un ID_AV real.
  if ds.FieldByName('ID_AV').IsNull then
    IdAv := AsegurarFilaSA(ds.FieldByName('CODIGO_UNIDAD_SKU').AsString,
                           ds.FieldByName('ID_VA_AV').AsString,
                           ds.FieldByName('VALOR_AV').AsString)
  else
    IdAv := ds.FieldByName('ID_AV').AsInteger;
  if (CodArt = '') or (IdAv = 0) then Exit;
  vNew := (Sender as TcxCustomEdit).EditingValue;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'INSERT INTO fza_articulos_atributos_basicos '          +
      '   (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, '           +
      '    DESCRIPCION_AAB, '                                 +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '      +
      'VALUES (:ART, :AV, :ATB, :DESC, NOW(), :USR, :USR) '   +
      'ON DUPLICATE KEY UPDATE '                              +
      '   DESCRIPCION_AAB = VALUES(DESCRIPCION_AAB), '        +
      '   USUARIO_MODIF   = VALUES(USUARIO_MODIF)';
    qry.ParamByName('ART').AsString := CodArt;
    qry.ParamByName('AV').AsInteger := IdAv;
    // Semilla del basico al crear la fila: el resuelto actual, para que la
    // descripcion no cambie el color mostrado.
    fldAtb := ds.FindField('ID_ATB_AV');
    if (fldAtb <> nil) and (not fldAtb.IsNull) then
      qry.ParamByName('ATB').AsInteger := fldAtb.AsInteger
    else
      qry.ParamByName('ATB').Clear;
    if VarIsNull(vNew) or (VarToStr(vNew) = '') then
      qry.ParamByName('DESC').Clear
    else
      qry.ParamByName('DESC').AsString := VarToStr(vNew);
    qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  // Cancel + Refresh: la rejilla cuelga de una vista de solo lectura; tras
  // grabar a mano, recargamos para que la descripcion persistida se vea.
  if ds.State in [dsEdit, dsInsert] then ds.Cancel;
  ds.Refresh;
end;

function TfrmMtoArticulos.ObtenerColorSkuActual(out aCodArt,
  aColor: string): Boolean;
// Busca en el detalle de atributos del SKU seleccionado la fila del atributo
// de color ('CO') y devuelve el codigo de articulo y el texto del color. El
// detalle ya esta master-detalleado al SKU en foco, asi que recorrerlo da los
// atributos de ese SKU (una fila CO, una TAL, ...).
var
  ds : TDataSet;
  bm : TBookmark;
begin
  Result  := False;
  aCodArt := '';
  aColor  := '';
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryDetallesAtributos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  ds.DisableControls;
  bm := ds.GetBookmark;
  try
    ds.First;
    while (not ds.Eof) and (not Result) do
    begin
      if SameText(ds.FieldByName('ID_VA_AV').AsString, 'CO') and
         (ds.FieldByName('VALOR_AV').AsString <> '') then
      begin
        aCodArt := ds.FieldByName('CODIGO_ART_SKU').AsString;
        aColor  := ds.FieldByName('VALOR_AV').AsString;
        Result  := True;
      end;
      if not Result then
        ds.Next;
    end;
  finally
    if ds.BookmarkValid(bm) then ds.GotoBookmark(bm);
    ds.FreeBookmark(bm);
    ds.EnableControls;
  end;
end;

procedure TfrmMtoArticulos.CambiarActivoColorSkus(const aActivo: string);
// Activa/desactiva en bloque todos los SKU del articulo que comparten el color
// del SKU seleccionado. Lo invocan tanto el menu de boton derecho como el
// boton lateral.
var
  CodArt, Color, sInf, sPP: string;
  nAfectados: Integer;
begin
  if not ObtenerColorSkuActual(CodArt, Color) then
  begin
    MessageDlg('Seleccione un SKU con color para activar o desactivar ' +
               'todos los SKU de ese color.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if aActivo = 'S' then
    sInf := 'activar'
  else
    sInf := 'desactivar';
  if MessageDlg(Format('Va a %s TODOS los SKU del color "%s" de este ' +
                       'articulo. Continuar?', [sInf, Color]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  nAfectados := dmmArticulos.ActualizarSkusColorActivo(CodArt, Color, aActivo);
  // Refrescamos el grid de SKU para reflejar el nuevo estado de ESACTIVO_SKU.
  if Assigned(dmmArticulos.unqrySkus) and dmmArticulos.unqrySkus.Active then
    dmmArticulos.unqrySkus.Refresh;
  if aActivo = 'S' then
    sPP := 'activado'
  else
    sPP := 'desactivado';
  MessageDlg(Format('%d SKU del color "%s" se han %s.',
                    [nAfectados, Color, sPP]), mtInformation, [mbOK], 0);
end;

procedure TfrmMtoArticulos.btnColorSkusClick(Sender: TObject);
// Despliega el mismo menu (activar/desactivar color) que el clic derecho sobre
// el panel de atributos, anclado bajo el boton lateral.
var
  pt: TPoint;
begin
  pt := btnColorSkus.ClientToScreen(Point(0, btnColorSkus.Height));
  pmColorSkus.Popup(pt.X, pt.Y);
end;

procedure TfrmMtoArticulos.miActivarColorClick(Sender: TObject);
begin
  CambiarActivoColorSkus('S');
end;

procedure TfrmMtoArticulos.miDesactivarColorClick(Sender: TObject);
begin
  CambiarActivoColorSkus('N');
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesInitPopup(
  Sender: TObject);
// Antes de mostrar el desplegable, filtramos el lookup por ID_VA_ATB para
// que un atributo CO sólo vea atributos básicos de color, un atributo TAL
// vea sólo tallas, etc.
var
  ds : TDataSet;
  IdVa: string;
begin
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryAtributosBasicosLookup)) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then Exit;
  IdVa := ds.FieldByName('ID_VA_AV').AsString;
  with dmmArticulos.unqryAtributosBasicosLookup do
  begin
    if IdVa = '' then
    begin
      Filter   := '';
      Filtered := False;
    end
    else
    begin
      Filter   := 'ID_VA_ATB = ' + QuotedStr(IdVa);
      Filtered := True;
    end;
  end;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesCloseUp(
  Sender: TObject);
// Tras cerrar el desplegable, limpiamos el filtro del lookup. Si lo
// dejamos puesto (ej. ID_VA_ATB = 'TAL') la grilla no puede resolver
// el CODIGO_ATB de las filas con otro tipo de atributo (CO, MAT, ...)
// y la columna "Basico" se ve vacia para esas filas. OnInitPopup
// vuelve a aplicar el filtro la proxima vez que se abra el desplegable.
begin
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryAtributosBasicosLookup)) then Exit;
  with dmmArticulos.unqryAtributosBasicosLookup do
  begin
    if Filtered then
    begin
      Filter   := '';
      Filtered := False;
    end;
  end;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
// El combo "Basico" es un TcxLookupComboBox de seleccion estricta. Si el
// usuario teclea un texto y pulsa Enter/Tab sin elegir nada del desple-
// gable, ese texto cae aqui en DisplayValue. Aprovechamos para:
//   1) Buscar match exacto (CODIGO_ATB o NOMBRE_ATB) entre los basicos
//      de la misma variacion. Si lo hay, devolvemos el CODIGO_ATB y el
//      combo lo resuelve a su ID via OnEditValueChanged.
//   2) Si no hay match, preguntamos al usuario Global/Ad-hoc/Cancelar
//      (PreguntarAmbitoBasico), creamos el basico nuevo en
//      fza_atributos_basicos y refrescamos el lookup. Luego ponemos
//      DisplayValue := CODIGO_ATB nuevo para que el combo lo seleccione
//      y dispare el override automaticamente.
//   3) Si cancela, marcamos Error para que el combo no asuma el texto
//      tecleado como un ID huerfano.
var
  Texto, IdVaAv, CodArt: string;
  ds                  : TDataSet;
  qry                 : TUniQuery;
  IdAtbExistente      : Integer;
  CodigoExistente     : string;
  Ambito              : TAmbitoBasico;
  CodigoNuevo, NombreNuevo: string;
begin
  Error := False;
  Texto := Trim(VarToStr(DisplayValue));
  if Texto = '' then Exit;
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryDetallesAtributos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;

  IdVaAv := ds.FieldByName('ID_VA_AV').AsString;
  CodArt := ds.FieldByName('CODIGO_ART_SKU').AsString;
  if (IdVaAv = '') or (CodArt = '') then Exit;

  // 1) Buscar match exacto en fza_atributos_basicos para este tipo de
  //    atributo. Damos prioridad a CODIGO_ATB exacto sobre NOMBRE_ATB.
  IdAtbExistente  := 0;
  CodigoExistente := '';
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT ID_ATB, CODIGO_ATB FROM fza_atributos_basicos '          +
      ' WHERE ID_VA_ATB = :IDVA '                                      +
      '   AND ESACTIVO_ATB = ''S'' '                                   +
      '   AND (CODIGO_ATB = :T OR NOMBRE_ATB = :T) '                   +
      ' ORDER BY (CODIGO_ATB = :T) DESC '                              +
      ' LIMIT 1';
    qry.ParamByName('IDVA').AsString := IdVaAv;
    qry.ParamByName('T').AsString    := Texto;
    qry.Open;
    if not qry.IsEmpty then
    begin
      IdAtbExistente  := qry.FieldByName('ID_ATB').AsInteger;
      CodigoExistente := qry.FieldByName('CODIGO_ATB').AsString;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;

  if IdAtbExistente > 0 then
  begin
    // Ya existe: devolvemos el CODIGO_ATB para que el combo resuelva
    // a su ID_ATB via su mecanismo interno de lookup.
    DisplayValue := CodigoExistente;
    Exit;
  end;

  // 2) No existe — preguntar al usuario que quiere crear.
  Ambito := PreguntarAmbitoBasico(CodArt, Texto);
  if Ambito = abCancelar then
  begin
    Error     := True;
    ErrorText := 'Sin asignar.';
    Exit;
  end;

  // 3) Crear el basico nuevo con el codigo que toque segun el ambito.
  NombreNuevo := Texto;
  case Ambito of
    abGlobal: CodigoNuevo := StringReplace(NombreNuevo, ' ', '_',
                                           [rfReplaceAll]);
    abAdHoc : CodigoNuevo := Format('AD_%s_%s',
                                    [CodArt,
                                     StringReplace(NombreNuevo, ' ', '_',
                                                   [rfReplaceAll])]);
  end;
  if Length(CodigoNuevo) > 100 then
    CodigoNuevo := Copy(CodigoNuevo, 1, 100);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'INSERT INTO fza_atributos_basicos '              +
      '   (ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, '         +
      '    ESACTIVO_ATB, '                              +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '+
      'VALUES (:IDVA, :COD, :NOM, ''S'', '              +
      '        NOW(), :USR, :USR) '                     +
      'ON DUPLICATE KEY UPDATE '                        +
      '   USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    qry.ParamByName('IDVA').AsString := IdVaAv;
    qry.ParamByName('COD').AsString  := CodigoNuevo;
    qry.ParamByName('NOM').AsString  := NombreNuevo;
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;

  // 4) Refrescar lookup para que el combo lo encuentre al resolver.
  if Assigned(dmmArticulos.unqryAtributosBasicosLookup) then
    dmmArticulos.unqryAtributosBasicosLookup.Refresh;

  // 5) Devolver el CODIGO_ATB nuevo para que el combo lo seleccione.
  //    Esto disparara OnEditValueChanged y se grabara el override.
  DisplayValue := CodigoNuevo;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged(
  Sender: TObject);
// Cuando el usuario elige otro atributo básico desde el SKU del artículo
// estamos en el contexto de ESTE artículo concreto. Persistimos un
// override per-artículo en fza_articulos_atributos_basicos: ID_ATB_AAB.
// La vista resuelve mediante COALESCE(override, conjunto, global) y la
// elección aquí no contamina ni el conjunto ni el default global.
//
// Si el usuario limpia el lookup, BORRAMOS la fila de override (la
// resolución cae al conjunto del artículo o, en su defecto, al global).
var
  qry   : TUniQuery;
  ds    : TDataSet;
  IdAv  : Integer;
  vNew  : Variant;
  CodArt: string;
begin
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryDetallesAtributos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;

  ds   := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  CodArt := ds.FieldByName('CODIGO_ART_SKU').AsString;
  // Fila virtual: materializamos AV+SA antes de poder asignar override.
  if ds.FieldByName('ID_AV').IsNull then
    IdAv := AsegurarFilaSA(ds.FieldByName('CODIGO_UNIDAD_SKU').AsString,
                           ds.FieldByName('ID_VA_AV').AsString,
                           ds.FieldByName('VALOR_AV').AsString)
  else
    IdAv := ds.FieldByName('ID_AV').AsInteger;
  if (CodArt = '') or (IdAv = 0) then Exit;
  vNew   := (Sender as TcxCustomEdit).EditingValue;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    // UPSERT del override per-artículo. Si vNew es NULL/'' guardamos
    // un BLOQUEO: la fila existe con ID_ATB_AAB = NULL para indicar que
    // este artículo no quiere básico para este valor (la vista da
    // preferencia a la existencia de la fila override sobre el conjunto
    // o el global; sin esto, vaciar la celda volvería a heredar y el
    // básico reaparecería). Para volver a heredar hay que eliminar la
    // fila a mano vía SQL u otra acción dedicada.
    qry.SQL.Text :=
      'INSERT INTO fza_articulos_atributos_basicos ' +
      '   (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, '  +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:ART, :AV, :ATB, NOW(), :USR, :USR) ' +
      'ON DUPLICATE KEY UPDATE '                     +
      '   ID_ATB_AAB    = VALUES(ID_ATB_AAB), '      +
      '   USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    qry.ParamByName('ART').AsString  := CodArt;
    qry.ParamByName('AV').AsInteger  := IdAv;
    if VarIsNull(vNew) or (VarToStr(vNew) = '') then
      qry.ParamByName('ATB').Clear
    else
      qry.ParamByName('ATB').AsInteger := Integer(vNew);
    qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  // Refrescamos la vista para repintar NOMBRE_ATB, HEX_ATB, VALOR_NUM_ATB,
  // FUENTE_ATB (pasa a 'A') y ETIQUETA_BASICO.
  if ds.State in [dsEdit, dsInsert] then ds.Cancel;
  ds.Refresh;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosHEX_ATBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  tvSkuAtributosBasicosDblClick(Sender);
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosDblClick(Sender: TObject);
// Abre el selector de color sobre el atributo básico de la fila activa.
// Si la fila no tiene atributo básico aún, lo creamos al vuelo (ad-hoc
// per-artículo) para que el usuario pueda asignarle un HEX directamente.
var
  ds : TDataSet;
  IdAtb: Integer;
  Dlg: TColorDialog;
  LHex: string;
  qry: TUniQuery;
begin
  if (not Assigned(dmmArticulos)) or
     (not Assigned(dmmArticulos.unqryDetallesAtributos)) or
     (not dmmArticulos.unqryDetallesAtributos.Active) then Exit;
  ds := dmmArticulos.unqryDetallesAtributos;
  if ds.IsEmpty then Exit;
  IdAtb := AsegurarBasicoFilaActual;
  if IdAtb = 0 then Exit;

  Dlg := TColorDialog.Create(Self);
  try
    Dlg.Options := [cdFullOpen, cdAnyColor];
    LHex := Trim(ds.FieldByName('HEX_ATB').AsString);
    if (Length(LHex) = 7) and (LHex[1] = '#') then
    try
      Dlg.Color := RGB(
        StrToInt('$' + Copy(LHex, 2, 2)),
        StrToInt('$' + Copy(LHex, 4, 2)),
        StrToInt('$' + Copy(LHex, 6, 2)));
    except
      Dlg.Color := clWhite;
    end
    else
      Dlg.Color := clWhite;

    if not Dlg.Execute then Exit;

    LHex := Format('#%.2X%.2X%.2X',
                   [GetRValue(Dlg.Color),
                    GetGValue(Dlg.Color),
                    GetBValue(Dlg.Color)]);

    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'UPDATE fza_atributos_basicos '   +
        '   SET HEX_ATB       = :HEX, '   +
        '       USUARIO_MODIF = :USR '    +
        ' WHERE ID_ATB = :ID';
      qry.ParamByName('HEX').AsString  := LHex;
      qry.ParamByName('USR').AsString  := IdentidadSesion.Usuario;
      qry.ParamByName('ID').AsInteger  := IdAtb;
      qry.Execute;
    finally
      FreeAndNil(qry);
    end;
    if ds.State in [dsEdit, dsInsert] then ds.Cancel;
    ds.Refresh;
    // El lookup tiene cacheado el HEX viejo: refrescamos también.
    if Assigned(dmmArticulos.unqryAtributosBasicosLookup) then
      dmmArticulos.unqryAtributosBasicosLookup.Refresh;
  finally
    FreeAndNil(Dlg);
  end;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosHEX_ATBCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  LHex: string;
  LColor: TColor;
  LRect: TRect;
  LR, LG, LB: Integer;
  LBrillo: Double;
begin
  ADone := False;
  if AViewInfo = nil then Exit;
  LHex := Trim(AViewInfo.GridRecord.DisplayTexts[AViewInfo.Item.Index]);
  if (Length(LHex) <> 7) or (LHex[1] <> '#') then Exit;

  try
    LR := StrToInt('$' + Copy(LHex, 2, 2));
    LG := StrToInt('$' + Copy(LHex, 4, 2));
    LB := StrToInt('$' + Copy(LHex, 6, 2));
    LColor := RGB(LR, LG, LB);
  except
    Exit;
  end;

  // Fondo de celda (mantiene la selección/zebra del grid).
  ACanvas.FillRect(AViewInfo.Bounds, AViewInfo.Params.Color);

  // Cuadrado de paleta con el color real.
  LRect := AViewInfo.Bounds;
  InflateRect(LRect, -3, -3);
  ACanvas.Brush.Color := LColor;
  ACanvas.Pen.Color   := clBlack;
  ACanvas.Rectangle(LRect);

  // Etiqueta del HEX encima, con texto blanco o negro segun luminancia.
  LBrillo := (LR * 0.299 + LG * 0.587 + LB * 0.114);
  ACanvas.Brush.Style := bsClear;
  if LBrillo < 128 then
    ACanvas.Font.Color := clWhite
  else
    ACanvas.Font.Color := clBlack;
  ACanvas.DrawText(LHex, LRect, cxAlignCenter or cxAlignVCenter);

  ADone := True;
end;

procedure TfrmMtoArticulos.tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  Info : TInfoBasico;
  IdVa : string;
begin
  if (AViewInfo = nil) or (FAtributosStock = nil) then Exit;
  if FAtributosStock.Count = 0 then Exit;
  // El handler se dispara en TODAS las celdas (almacen, tallas, total).
  // Solo nos interesa pintar swatch en las columnas que mapean a un
  // atributo del articulo (p.ej. Color), no en las de cantidad. El
  // nombre de campo casa con NOMBRE_VA — clave en FAtributosStock —
  // porque el SP de stock pivotado etiqueta la fila desglosada con ese
  // mismo nombre. Las columnas pivote (S, M, 3, 5, ...) no estan en el
  // diccionario, asi que no entran aqui.
  if not FAtributosStock.TryGetValue(
       UpperCase(Trim(GetItemFieldName(AViewInfo.Item))), IdVa) then Exit;
  if not ObtenerInfoBasico(
    ConexionPrincipal,
    IdVa,
    AViewInfo.Text,
    Info) then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info) then
    ADone := True;
end;

procedure TfrmMtoArticulos.PcDetailChange(Sender: TObject);
begin
  if not Assigned(dmmArticulos) then Exit;
  // Al entrar a Tarifas: abrir (lazy).
  if pcDetail.ActivePage = tsTarifas then
    dmmArticulos.AsegurarTarifasAbiertas
  else
    // Si saliendo de Tarifas, cerrar la query. Asi el siguiente cambio
    // de articulo (master/detail) no dispara un refresh innecesario de
    // ~2s sobre vi_articulos_tarifas. Reabrira cuando el usuario vuelva
    // a la pestaña.
    CerrarSiNoVisible(dmmArticulos.unqryTarifasArticulos, tsTarifas);

  // Stock: si activan la pestaña, refrescar (solo si cambio el articulo).
  if pcDetail.ActivePage = cxTabSheet3 then
    AsegurarStockAlDia;
end;

procedure TfrmMtoArticulos.AsegurarStockAlDia;
begin
  if not Assigned(dmmArticulos) then Exit;
  if FArticuloCargado = '' then Exit;
  // Si el stock ya esta cargado para el articulo activo, nada que hacer.
  if (FStockArticuloCargado = FArticuloCargado)
     and dmmArticulos.unqryStockArticulos.Active then Exit;
  // unqryStockArticulosAfterScroll cierra, recarga el SP y reconstruye
  // las columnas dinamicas del cxGrid tvStock. Ya esta instrumentado
  // con LogPerf ([PERF:Articulos.StockAfterScroll]).
  dmmArticulos.unqryStockArticulosAfterScroll(dmmArticulos.unqryTablaG);
  FStockArticuloCargado := FArticuloCargado;
end;

procedure TfrmMtoArticulos.CerrarSiNoVisible(qry: TUniQuery;
  ActivaTarget: TcxTabSheet);
begin
  // Solo cerrar si la pestaña target NO esta visible. Util para queries
  // master/detail que se reabren automaticamente al cambiar el master:
  // mientras no se esta viendo, mejor cerrada para ahorrar el refresh.
  if (qry = nil) or not qry.Active then Exit;
  if pcDetail.ActivePage = ActivaTarget then Exit;
  qry.Close;
end;

procedure TfrmMtoArticulos.EnsancharColumnasStockParaSwatch;
var
  i : Integer;
begin
  if (tvStock = nil) or (FAtributosStock = nil) then Exit;
  if FAtributosStock.Count = 0 then Exit;
  // Solo ensanchamos las columnas que efectivamente van a pintar swatch
  // (las que mapean a un atributo del articulo). Antes se llamaba a
  // AjustarAnchoColumnaParaSwatch sobre todas las columnas; si una
  // talla numerica casaba por coincidencia con un basico HEX, se
  // ensanchaba en balde.
  for i := 0 to tvStock.ColumnCount - 1 do
    if FAtributosStock.ContainsKey(
         UpperCase(Trim(GetItemFieldName(tvStock.Columns[i])))) then
      AjustarAnchoColumnaParaSwatch(
        ConexionPrincipal,
        tvStock.Columns[i],
        FAtributosStock);
end;

procedure TfrmMtoArticulos.tvStockGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
var
  Info : TInfoBasico;
  IdVa : string;
begin
  if (ACellViewInfo = nil) or (FAtributosStock = nil) then Exit;
  if FAtributosStock.Count = 0 then Exit;
  if not FAtributosStock.TryGetValue(
       UpperCase(Trim(GetItemFieldName(ACellViewInfo.Item))), IdVa) then Exit;
  if ObtenerInfoBasico(ConexionPrincipal, IdVa, ACellViewInfo.Text, Info) then
    AHintText := Info.Nombre;
end;

initialization
  ForceReferenceToClass(TfrmMtoArticulos);
end.
