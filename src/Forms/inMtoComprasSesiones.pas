{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComprasSesiones                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sesión de compra: crear artículos en lote y un pedido o un albarán        }
{    contra un proveedor. Variante grid plano con edición INLINE de            }
{    cantidades por talla.                                                     }
{                                                                              }
{      - Cabecera: Empresa, Proveedor, Tarifa venta, Margen,                   }
{        Multiplo redondeo, Ajuste final.                                      }
{      - Una linea = un articulo. Columnas: Familia (F3 -> picker),            }
{        Codigo articulo (editable; si lo tecleado coincide con una            }
{        familia con contador activo se expande a FAMILIA+RELLENO,             }
{        p. ej. '0101' -> '0101003'), Descripcion, Color (libre),              }
{        Color basico (selector paleta), Pr. compra, Pr. venta                 }
{        (propuesto al teclear coste), Sistema tallas, N columnas              }
{        TALLA inline, Total tallas, Importe s/IVA.                            }
{      - Boton 'Arbol familias' en la barra de lineas abre el mismo            }
{        modal jerarquico que F3 sobre la columna Familia.                     }
{                                                                              }
{    Las columnas TALLA son no-bound: su valor vive en                         }
{    tvLineas.DataController.Values y se sincroniza con                        }
{    fza_compras_sesiones_celdas via SQL. El numero de columnas visibles       }
{    = max valores entre los conjuntos referenciados en la sesion.             }
{    Los rotulos (captions) reflejan el sistema de la linea con foco.          }
{                                                                              }
{    El formulario recoge la entrada, delega en un colaborador y presenta      }
{    el resultado. Los colaboradores se inyectan por constructor con un        }
{    entorno explicito (datasets, columnas y callbacks); ninguno recibe        }
{    este formulario ni el contexto general de repositorios:                   }
{      - TCoordinadorTallasSesion   columnas inline, catalogo de sistemas,     }
{        selector, pintado, bloqueo y distribuidor por almacen.                }
{      - TBuscadorModeloProveedorSesion  busqueda incremental de modelos y     }
{        reutilizacion de articulos al teclear familia / codigo / modelo.      }
{      - TCoordinadorCopiaLineasSesion   "Otro color" / "Otro precio" y la     }
{        copia diferida al repetir un modelo.                                  }
{      - TCoordinadorProveedorSesion  ficha, defectos, kits y color basico.    }
{      - TCoordinadorFotosProvisionalesSesion  fotos de lineas y visor.        }
{      - TCoordinadorNavegacionComprasSesion  maestros y documentos.          }
{      - TCoordinadorImportacionPedidoOcr  valida, importa y archiva pedidos.  }
{      - TVisorPedidoOriginalSesion  navegacion, zoom y arrastre del TIFF.     }
{      - IAplicacionMaterializacionCompraSesion  orquesta la materializacion.  }
{    Los tiempos de espera (debounce y aperturas diferidas) viven en           }
{    IPlanificadorDiferido; aqui no queda ningun TTimer.                       }
{                                                                              }
{    Reutiliza:                                                                }
{      - TdmComprasSesiones (mapeado en fza_winforms).                         }
{      - inLibComprasSesiones.ResolverCodigoFamilia (atajo familia->codigo).   }
{      - inLibComprasSesiones.CalcularPrecioVenta (PVP propuesto).             }
{      - inLibAtributosPaleta.SeleccionarAvConPaleta (selector color           }
{        basico, mismo combo que el grid de inventarios).                      }
{      - TfrmModalSelFamilia (picker jerarquico, tecla F3).                    }
{                                                                              }
{    Documentado en DESARROLLOS EN CURSO/compras_sesiones.md.                  }
{******************************************************************************}
unit inMtoComprasSesiones;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils,
  System.Variants, System.types,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.UITypes, System.Actions,
  Vcl.ActnList, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  cxClasses, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxDBEdit, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  cxDBNavigator, cxMemo, cxCheckBox, cxGroupBox, cxLocalization, cxGraphics,
  cxButtonEdit, cxEditRepositoryItems, cxDBExtLookupComboBox,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxSkinsDefaultPainters,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoGen,
  inLibGridTallasInline,
  inLibComprasSesiones,
  inLibComprasSesionesAplicacionIntf,
  inLibComprasSesionesInyeccion,
  inLibPermisosIntf,
  inMtoComprasSesionesPresentacionCopiaLineas,
  inMtoComprasSesionesPresentacionFotos,
  inMtoComprasSesionesPresentacionImportacionOcr,
  inMtoComprasSesionesPresentacionModelo,
  inMtoComprasSesionesPresentacionNavegacion,
  inMtoComprasSesionesPresentacionPedidoOriginal,
  inMtoComprasSesionesPresentacionProveedor,
  inMtoComprasSesionesPresentacionTallas,
  UniDataComprasSesiones, cxBlobEdit, dxShellDialogs, cxRadioGroup, Vcl.Buttons,
  dxDateRanges, cxSplitter;

const
  NOMBRE_PANTALLA_COMPRAS_SESIONES = 'frmMtoComprasSesiones';
  // Numero maximo de columnas de talla inline. Subido a 20 a peticion
  // de un cliente con sistemas extensos (rangos de calzado largos,
  // tallas internacionales niño+adulto, etc.).
  CANT_TALLAS_MAX = 20;
  WM_RECARGAR_TALLAS_SESION = WM_APP + 247;

type
  // Los tipos TPosConjunto / TArrPosConjunto viven ahora en
  // inLibGridTallasInline (compartidos con futuros Mtos de Pedidos
  // / Albaranes / Facturas que reusen el patron).

  TfrmMtoComprasSesiones = class(TfrmMtoGen)
    // ------------------------------------------------------------------
    // Columnas grid lista (tsLista, heredada)
    // ------------------------------------------------------------------
    dbcSerieSes              : TcxGridDBColumn;
    dbcNumeroSes             : TcxGridDBColumn;
    dbcFechaSes              : TcxGridDBColumn;
    dbcTemporadaSes          : TcxGridDBColumn;
    dbcFechaEfectoStockSes   : TcxGridDBColumn;
    dbcFechaTopeRecepcionSes : TcxGridDBColumn;
    dbcTotalPrendasSes       : TcxGridDBColumn;
    dbcTotalLineasSes        : TcxGridDBColumn;
    dbcTotalDocumentoSes     : TcxGridDBColumn;
    dbcCantidadPedidaSes     : TcxGridDBColumn;
    dbcCantidadRecibidaSes   : TcxGridDBColumn;
    dbcCantidadPendienteSes  : TcxGridDBColumn;
    dbcEstadoSes             : TcxGridDBColumn;
    dbcCodigoEmpSes          : TcxGridDBColumn;
    dbcCodigoPrvSes          : TcxGridDBColumn;
    dbcRazonSocialPrvSes     : TcxGridDBColumn;
    dbcNombrePrvSes          : TcxGridDBColumn;
    dbcCodigoTarSes          : TcxGridDBColumn;
    dbcUsuarioAltaSes        : TcxGridDBColumn;
    dlgFoto                  : TOpenDialog;
    dlgImportarPedido        : TOpenDialog;
    btnImprimir: TcxButton;
    btnCrear: TcxButton;
    btnRevertir: TcxButton;
    btnImportarPedido: TcxButton;

    // ------------------------------------------------------------------
    // Navegacion rapida via TActionList. Los shortcuts SOLO disparan
    // cuando este form esta activo (cxTabSheet enfocada), asi evitamos
    // que un KeyDown se filtre a otra instancia abierta. Patron
    // recomendado en VCL frente a Form.OnKeyDown global.
    // ------------------------------------------------------------------
    alNavegacion         : TActionList;
    actIrArticulos       : TAction;
    actIrAlbaranesCompra : TAction;
    actIrPedidosCompra   : TAction;
    actIrProveedor       : TAction;
    pnlBottFich: TPanel;
    splSplitterFicha: TcxSplitter;
    cxPageControl2: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    dbcLinFamilia: TcxGridDBColumn;
    dbcLinCodArt: TcxGridDBColumn;
    dbcLinRefPrv: TcxGridDBColumn;
    dbcLinDescripcion: TcxGridDBColumn;
    dbcLinTipoIva: TcxGridDBColumn;
    dbcLinColor: TcxGridDBColumn;
    dbcLinColorBasico: TcxGridDBColumn;
    dbcLinPrecioCompra: TcxGridDBColumn;
    dbcLinPrecioVenta: TcxGridDBColumn;
    dbcLinTallas: TcxGridDBColumn;
    dbcLinTotalTallas: TcxGridDBColumn;
    dbcLinImporteTotal: TcxGridDBColumn;
    dbcLinNumero: TcxGridDBColumn;
    glLineas: TcxGridLevel;
    pnlLineasTop: TPanel;
    btnAddLinea: TcxButton;
    btnDelLinea: TcxButton;
    btnNuevoColor: TcxButton;
    btnOtroPrecio: TcxButton;
    btnFoto: TcxButton;
    btnArbolFamilias: TcxButton;
    btnDescargarFotos: TcxButton;
    lblHint: TcxLabel;
    tsTotales: TcxTabSheet;
    pnlTotales: TPanel;
    lblTotalBasesSes: TcxLabel;
    curTotalesTOTAL_BASES_SES: TcxDBCurrencyEdit;
    lblTotalImpuestosSes: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_SES: TcxDBCurrencyEdit;
    lblPorcRetencionSes: TcxLabel;
    spnTotalesPORCENTAJE_RETENCION_SES: TcxDBSpinEdit;
    lblTotalRetencionSes: TcxLabel;
    curTotalesTOTAL_RETENCION_SES: TcxDBCurrencyEdit;
    lblTotalLiquidoSes: TcxLabel;
    curTotalesTOTAL_LIQUIDO_SES: TcxDBCurrencyEdit;
    lblTotalesFormaPagoSes: TcxLabel;
    cbbTotalesFORMA_PAGO_SES: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_COMPRAS_SES: TcxDBCheckBox;
    lblDtoComercialSes: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_SES: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_SES: TcxDBCurrencyEdit;
    lblDtoFinancieroSes: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_SES: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_SES: TcxDBCurrencyEdit;
    grpDesgloseIvaSes: TGroupBox;
    lblTotSesBase: TcxLabel;
    lblTotSesPorIva: TcxLabel;
    lblTotSesTotalIva: TcxLabel;
    lblTotSesPorRe: TcxLabel;
    lblTotSesTotalRe: TcxLabel;
    lblTotSesIVAN: TcxLabel;
    lblTotSesIVAR: TcxLabel;
    lblTotSesIVAS: TcxLabel;
    lblTotSesIVAE: TcxLabel;
    curTotSesTOTAL_BASEI_IVAN_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_BASEI_IVAR_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_BASEI_IVAS_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_BASEI_IVAE_SES: TcxDBCurrencyEdit;
    spnTotSesPORCENTAJE_IVAN_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_IVAR_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_IVAS_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_IVAE_SES: TcxDBSpinEdit;
    curTotSesTOTAL_IVAN_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_IVAR_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_IVAS_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_IVAE_SES: TcxDBCurrencyEdit;
    spnTotSesPORCENTAJE_REN_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_RER_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_RES_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_REE_SES: TcxDBSpinEdit;
    curTotSesTOTAL_REN_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_RER_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_RES_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_REE_SES: TcxDBCurrencyEdit;
    tsDocumentos: TcxTabSheet;
    pnlDocsTop: TPanel;
    btnIrADoc: TcxButton;
    // Boton del lateral derecho: navega al pedido / albaran seleccionado
    // en la pestania Documentos (sustituye al antiguo atajo F12, que
    // chocaba con el F12 de grabar registro del Mto base).
    btnIrPedAlb: TcxButton;
    lblDocsInfo: TcxLabel;
    cxgrdDocs: TcxGrid;
    tvDocs: TcxGridDBTableView;
    dbcDocTipo: TcxGridDBColumn;
    dbcDocSerie: TcxGridDBColumn;
    dbcDocNumero: TcxGridDBColumn;
    dbcDocAlmacen: TcxGridDBColumn;
    dbcDocInstante: TcxGridDBColumn;
    dbcDocUsuario: TcxGridDBColumn;
    glDocs: TcxGridLevel;

    // ------------------------------------------------------------------
    // Pestaña Proveedor: ficha del proveedor de la sesion (solo lectura),
    // sus defectos (margen, sistema de tallas) y su biblioteca de kits.
    // ------------------------------------------------------------------
    tsProveedor          : TcxTabSheet;
    dsPrvFicha           : TDataSource;
    pnlProvIzq           : TPanel;
    gbProvFicha          : TcxGroupBox;
    lblProvCodigo        : TcxLabel;
    txtProvCodigo        : TcxDBTextEdit;
    lblProvNif           : TcxLabel;
    txtProvNif           : TcxDBTextEdit;
    lblProvRazon         : TcxLabel;
    txtProvRazon         : TcxDBTextEdit;
    lblProvNombre        : TcxLabel;
    txtProvNombre        : TcxDBTextEdit;
    lblProvTelefono      : TcxLabel;
    txtProvTelefono      : TcxDBTextEdit;
    lblProvMovil         : TcxLabel;
    txtProvMovil         : TcxDBTextEdit;
    lblProvEmail         : TcxLabel;
    txtProvEmail         : TcxDBTextEdit;
    lblProvDireccion     : TcxLabel;
    txtProvDireccion     : TcxDBTextEdit;
    lblProvPoblacion     : TcxLabel;
    txtProvPoblacion     : TcxDBTextEdit;
    lblProvProvincia     : TcxLabel;
    txtProvProvincia     : TcxDBTextEdit;
    lblProvCPostal       : TcxLabel;
    txtProvCPostal       : TcxDBTextEdit;
    lblProvPais          : TcxLabel;
    txtProvPais          : TcxDBTextEdit;
    lblProvContacto      : TcxLabel;
    txtProvContacto      : TcxDBTextEdit;
    lblProvTelContacto   : TcxLabel;
    txtProvTelContacto   : TcxDBTextEdit;
    lblProvMargen        : TcxLabel;
    txtProvMargen        : TcxDBTextEdit;
    btnIrProveedor       : TcxButton;
    gbProvKits           : TcxGroupBox;
    pnlProvKitsTop       : TPanel;
    btnAplicarKitProv    : TcxButton;
    lblProvKitsHint      : TcxLabel;
    cxgrdPrvKits         : TcxGrid;
    tvPrvKits            : TcxGridDBTableView;
    dbcPrvKitCodigo      : TcxGridDBColumn;
    dbcPrvKitNombre      : TcxGridDBColumn;
    dbcPrvKitSistema     : TcxGridDBColumn;
    glPrvKits            : TcxGridLevel;
    cxgrdPrvKitsDet      : TcxGrid;
    tvPrvKitsDet         : TcxGridDBTableView;
    dbcPrvKitDetValor    : TcxGridDBColumn;
    dbcPrvKitDetCantidad : TcxGridDBColumn;
    glPrvKitsDet         : TcxGridLevel;
    // Boton "Aplicar kit" de la barra de Lineas (popup con los kits del
    // proveedor; aplica sobre la linea con foco).
    btnAplicarKit        : TcxButton;
    // ------------------------------------------------------------------
    // Fotos provisionales: visor superior y detalle de asignaciones.
    // ------------------------------------------------------------------
    gbFotoProvisional              : TcxGroupBox;
    imgFotoProvisional             : TImage;
    lblFotoProvisionalAsignacion   : TcxLabel;
    tsFotosProvisionales           : TcxTabSheet;
    cxgrdFotosProvisionales        : TcxGrid;
    tvFotosProvisionales           : TcxGridDBTableView;
    dbcFotoLinea                   : TcxGridDBColumn;
    dbcFotoArticulo                : TcxGridDBColumn;
    dbcFotoModeloProveedor         : TcxGridDBColumn;
    dbcFotoDescripcion             : TcxGridDBColumn;
    dbcFotoColor                   : TcxGridDBColumn;
    dbcFotoUnidad                  : TcxGridDBColumn;
    dbcFotoFichero                 : TcxGridDBColumn;
    dbcFotoInstante                : TcxGridDBColumn;
    dbcFotoUsuario                 : TcxGridDBColumn;
    glFotosProvisionales           : TcxGridLevel;
    tsPedidoOriginal               : TcxTabSheet;
    pnlPedidoOriginalTop           : TPanel;
    btnPaginaAnteriorPedido        : TcxButton;
    btnPaginaSiguientePedido       : TcxButton;
    btnAlejarPedido                : TcxButton;
    btnAcercarPedido               : TcxButton;
    btnAjustarPedido               : TcxButton;
    btnZoomRealPedido              : TcxButton;
    lblPaginaPedido                : TcxLabel;
    scrPedidoOriginal              : TScrollBox;
    imgPedidoOriginal              : TImage;
    cxPageControl1: TcxPageControl;
    cxTabSheet2: TcxTabSheet;
    gbCabecera: TcxGroupBox;
    lblSerie: TcxLabel;
    cbbSerie: TcxDBComboBox;
    lblNumero: TcxLabel;
    txtNumero: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dteFecha: TcxDBDateEdit;
    lblFechaTopeRecepcion: TcxLabel;
    dteFechaTopeRecepcion: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtEstado: TcxDBTextEdit;
    lblEmpresa: TcxLabel;
    cbbEmpresa: TcxDBLookupComboBox;
    lblProveedor: TcxLabel;
    cbbProveedor: TcxDBLookupComboBox;
    lblRefPrv: TcxLabel;
    txtRefPrv: TcxDBTextEdit;
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxDBLookupComboBox;
    chkFormatoDistribuido: TcxDBCheckBox;
    lblProveedorNombre: TcxLabel;
    lblKitProv: TcxLabel;
    cbbKitProv: TcxLookupComboBox;
    btnAplicarKitCab: TcxButton;
    cxTabSheet3: TcxTabSheet;
    lblTemporada: TcxLabel;
    cbbTemporada: TcxDBLookupComboBox;
    cbbTarifa: TcxDBLookupComboBox;
    lblTarifa: TcxLabel;
    lblMargen: TcxLabel;
    spnMargen: TcxDBSpinEdit;
    lblMultiploRedondeo: TcxLabel;
    spnMultiploRedondeo: TcxDBSpinEdit;
    lblAjusteFinal: TcxLabel;
    spnAjusteFinal: TcxDBSpinEdit;
    chkVariosTiposIva: TcxDBCheckBox;
    lblTipoIvaDefecto: TcxLabel;
    cbbTipoIvaDefecto: TcxDBComboBox;
    chkCopiarDescripcionFamilia: TcxDBCheckBox;

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
    procedure btnNuevoColorClick(Sender: TObject);
    procedure btnOtroPrecioClick(Sender: TObject);
    procedure btnArbolFamiliasClick(Sender: TObject);
    procedure btnCrearClick(Sender: TObject);
    procedure btnRevertirClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure tvLineasEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);
    procedure tvLineasFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
    procedure tvLineasCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cbbProveedorPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbProveedorKeyUp(Sender: TObject; var Key: Word;
                                Shift: TShiftState);
    procedure btnAplicarKitClick(Sender: TObject);
    procedure btnAplicarKitCabClick(Sender: TObject);
    procedure btnAplicarKitProvClick(Sender: TObject);
    procedure tvPrvKitsDblClick(Sender: TObject);
    procedure dbcLinColorBasicoPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure dbcLinPrecioCompraPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinTallasPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure dbcLinFamiliaPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinCodArtPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinRefPrvPropertiesEditValueChanged(Sender: TObject);
    procedure cbbTipoIvaDefectoPropertiesChange(Sender: TObject);
    procedure chkVariosTiposIvaPropertiesChange(Sender: TObject);
    procedure chkRecargoComprasPropertiesChange(Sender: TObject);
    procedure cxgrdLineasEnter(Sender: TObject);
    procedure cxgrdLineasExit(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure cxPageControl1Change(Sender: TObject);
    procedure cxPageControl2Change(Sender: TObject);
    procedure btnImportarPedidoClick(Sender: TObject);
  private
    Dmm: TdmComprasSesiones;
    FServicioComprasSesiones: TServicioComprasSesiones;
    FDependencias: TContextoDependenciasComprasSesiones;
    FAplicacionMaterializacion:
      IAplicacionMaterializacionCompraSesion;
    FEstiloRecepcionVencida: TcxStyle;
    // Colaboradores de presentacion. Cada uno recibe por constructor
    // solo las capacidades que usa (datasets, columnas y callbacks);
    // ninguno conserva una referencia a este formulario completo.
    FTallas: TCoordinadorTallasSesion;
    FModeloPrv: TBuscadorModeloProveedorSesion;
    FCopiaLineas: TCoordinadorCopiaLineasSesion;
    FProveedor: TCoordinadorProveedorSesion;
    FFotos: TCoordinadorFotosProvisionalesSesion;
    FNavegacion: TCoordinadorNavegacionComprasSesion;
    FImportadorOcr: TCoordinadorImportacionPedidoOcr;
    FVisorPedidoOriginal: TVisorPedidoOriginalSesion;
    FAplicandoColorOcr: Boolean;
    FRecargaTallasPendiente: Boolean;
    function  GestorTallas: TGestorGridTallas;
    procedure RecargarTallasVisibles;
    procedure RecargarTallasDiferido;
    procedure RefrescarColumnasTallas;
    procedure ReconstruirTallas;
    procedure CrearColaboradorTallas;
    procedure CrearColaboradorMaterializacion;
    procedure CrearColaboradorCopiaLineas;
    procedure CrearColaboradorModelo;
    procedure CrearColaboradorProveedor;
    procedure CrearColaboradores;
    procedure CrearServicioSesion;
    procedure EnlazarListasCabecera;
    procedure EnlazarDetalleSesion;
    procedure EnlazarPestanaProveedor;
    procedure LogSes(const ATexto: string);
    procedure RefrescarVisibilidadTipoIva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure dsTablaGStateChangeHook(Sender: TObject);
    procedure GridListaGetContentStyle(Sender: TcxCustomGridTableView;
                ARecord: TcxCustomGridRecord;
                AItem: TcxCustomGridTableItem;
                var AStyle: TcxStyle);
    procedure dsSesionLinDataChangeHook(Sender: TObject; Field: TField);
    procedure unqrySesionLinBeforePostHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterPostHook(DataSet: TDataSet);
    procedure unqrySesionLinBeforeInsertHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterInsertHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterCancelHook(DataSet: TDataSet);
    procedure unqrySesionLinBeforeDeleteHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterDeleteHook(DataSet: TDataSet);
    procedure unqrySesionLinRecargarTallasHook(DataSet: TDataSet);
    function DirectorioFotosAplicacion: string;
    procedure ImportarPedidoOcr(const AFicheroJson: string);
    procedure WMRecargarTallasSesion(var AMensaje: TMessage);
      message WM_RECARGAR_TALLAS_SESION;
  protected
    // Interceptamos a nivel de form (KeyPreview heredado = True) para
    // que Ctrl+Enter abra el selector de la columna editbutton enfocada
    // ANTES de que la navegacion Enter->Tab del grid / FormKeyDown base
    // mueva el foco a otra pestania.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasComprasSesiones);
      reintroduce; overload;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibUser,
  inLibFiltroUsuario,
  inLibGenBusq,
  inLibShowMto,
  inLibFotos,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inMtoModalImpSesion,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibMsgArticulos, inLibMsgCompras,
  inLibContextoSesionIntf,
  inLibProcesoPedidoOcr,
  inLibComprasSesionesIntf,
  inLibDatasets,
  inLibMtoGenAplicacionIntf,
  UniDataGen,
  inMtoComprasSesionesPresentacionMaterializacion,
  UniDataComprasSesionesComposicion;

{$R *.dfm}

resourcestring
  SErrorImportarPedidoSesionCompra =
    'No se pudo importar el pedido: %s';
  SFiltroDocumentoPdfPedidoSesionCompra =
    'Documento PDF (*.pdf)|*.pdf';
  SErrorImportacionOcrSesionConLineas =
    'La importación OCR requiere una sesión sin líneas.';
  SErrorUsuarioSinEmpresaImportacionOcr =
    'El usuario actual no tiene empresa asignada.';
  SErrorUsuarioSinAlmacenImportacionOcr =
    'El usuario actual no tiene almacén asignado.';
  SErrorEmpresaSinSerieSesionesImportacionOcr =
    'La empresa %s no tiene una serie de sesiones configurada.';
  SErrorGuardarSesionAntesImportacionOcr =
    'No se pudo guardar la sesión antes de importar el pedido.';

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoComprasSesiones.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasComprasSesiones);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoComprasSesiones.LogSes(const ATexto: string);
begin
  if Assigned(ContextoSesion) then
    ContextoSesion.LogSesion(ATexto);
end;

// ===========================================================================
//   Colaboradores de presentacion
// ===========================================================================
// El formulario recoge la entrada, delega en el colaborador que
// corresponde y presenta el resultado. Estos accesores concentran el
// unico punto por el que se llega al gestor de tallas pivotadas.

function TfrmMtoComprasSesiones.GestorTallas: TGestorGridTallas;
begin
  Result := nil;
  if FTallas <> nil then
    Result := FTallas.Gestor;
end;

procedure TfrmMtoComprasSesiones.RecargarTallasVisibles;
begin
  if GestorTallas <> nil then
    GestorTallas.CargarCantidadesTodasLineas;
end;

// El DataController puede repintar la fila DESPUES del hook y borrar los
// Values[] no-bound recien cargados: la recarga diferida tiene la ultima
// palabra.
procedure TfrmMtoComprasSesiones.RecargarTallasDiferido;
begin
  // Un unico mensaje aplaza y agrupa los repintados que genera una misma
  // operacion Insert/Cancel/Post. Al destruir la ventana Windows descarta
  // el mensaje, evitando callbacks anonimos sobre un formulario liberado.
  if not FRecargaTallasPendiente then
  begin
    FRecargaTallasPendiente := True;
    PostMessage(Handle, WM_RECARGAR_TALLAS_SESION, 0, 0);
  end;
end;

procedure TfrmMtoComprasSesiones.WMRecargarTallasSesion(
  var AMensaje: TMessage);
begin
  FRecargaTallasPendiente := False;
  if not (csDestroying in ComponentState) then
  begin
    RecargarTallasVisibles;
    if GestorTallas <> nil then
      GestorTallas.ActualizarCaptionsLineaActiva;
  end;
  AMensaje.Result := 0;
end;

procedure TfrmMtoComprasSesiones.RefrescarColumnasTallas;
begin
  if GestorTallas <> nil then
  begin
    GestorTallas.RecalcularMaxColumnas;
    GestorTallas.CargarCantidadesTodasLineas;
    GestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoComprasSesiones.ReconstruirTallas;
begin
  if GestorTallas <> nil then
  begin
    GestorTallas.InvalidarCache;
    RefrescarColumnasTallas;
  end;
end;

// Se crea ANTES del inherited: el gestor de tallas necesita sus columnas
// creadas cuando el ancestro abre el detalle.
procedure TfrmMtoComprasSesiones.CrearColaboradorTallas;
var
  Entorno: TEntornoTallasSesion;
begin
  Entorno := Default(TEntornoTallasSesion);
  Entorno.Conexion := ConexionPrincipal;
  Entorno.ContextoSesion := ContextoSesion;
  Entorno.Usuario := IdentidadSesion.Usuario;
  Entorno.Contenedor := cxgrdLineas;
  Entorno.Vista := tvLineas;
  Entorno.ColumnaSelector := dbcLinTallas;
  Entorno.FuenteCabecera := dsTablaG;
  Entorno.MaxColumnas := CANT_TALLAS_MAX;
  Entorno.FijarTallajeDefecto :=
    procedure(AIdConjunto: Integer)
    begin
      if Dmm <> nil then
        Dmm.TallajeDefectoActual := AIdConjunto;
    end;
  Entorno.RefrescarTotalesSesion :=
    procedure
    begin
      if Dmm <> nil then
        Dmm.RefrescarTotalesSesion;
    end;
  Entorno.RepositorioDistribuidor := FDependencias.Distribuidor;
  FTallas := TCoordinadorTallasSesion.Create(Entorno);
end;

// El orden importa: el buscador de modelos pide copias de linea al
// coordinador de copia, y el de proveedor abre el distribuidor del de
// tallas (ya creado antes del inherited).
procedure TfrmMtoComprasSesiones.CrearColaboradores;
var
  EntornoFotos: TEntornoFotosProvisionalesSesion;
  EntornoImportacion: TEntornoImportacionPedidoOcr;
  EntornoNavegacion: TEntornoNavegacionComprasSesion;
  ConexionSeries: TUniConnection;
begin
  FreeAndNil(FFotos);
  EntornoFotos := Default(TEntornoFotosProvisionalesSesion);
  EntornoFotos.Propietario := Self;
  EntornoFotos.AccionFoto := actFotoArticulo;
  EntornoFotos.BotonAsignar := btnFoto;
  EntornoFotos.BotonDescargar := btnDescargarFotos;
  EntornoFotos.DialogoFoto := dlgFoto;
  EntornoFotos.GrupoCabecera := gbCabecera;
  EntornoFotos.GrupoFoto := gbFotoProvisional;
  EntornoFotos.Imagen := imgFotoProvisional;
  EntornoFotos.Etiqueta := lblFotoProvisionalAsignacion;
  EntornoFotos.PaginasFicha := cxPageControl1;
  EntornoFotos.PaginaPedidoOriginal := tsPedidoOriginal;
  EntornoFotos.PaginasDetalle := cxPageControl2;
  EntornoFotos.PaginaFotos := tsFotosProvisionales;
  EntornoFotos.VistaFotos := tvFotosProvisionales;
  EntornoFotos.FuenteCabecera := dsTablaG;
  EntornoFotos.FuenteLineas := Dmm.dsSesionLin;
  EntornoFotos.FuenteFotos := Dmm.dsSesionFotos;
  EntornoFotos.Parametros := ParametrosApp;
  EntornoFotos.Fotos := FotosArticulos;
  EntornoFotos.Usuario := IdentidadSesion.Usuario;
  FFotos := TCoordinadorFotosProvisionalesSesion.Create(
    EntornoFotos);
  FreeAndNil(FNavegacion);
  ConexionSeries := ConexionPrincipal;
  EntornoNavegacion := TEntornoNavegacionComprasSesion.Crear(
    Self.Owner,
    actIrArticulos,
    actIrAlbaranesCompra,
    actIrPedidosCompra,
    actIrProveedor,
    btnIrADoc,
    btnIrPedAlb,
    btnIrProveedor,
    tvDocs,
    cbbSerie,
    Dmm.unqrySesDocs,
    Dmm.unqrySesionLin,
    Dmm.unqryTablaG,
    UbicacionSesion.Empresa,
    procedure(const AEmpresa: string; AItems: TStrings)
    begin
      CargarSeriesEmpresa(
        ConexionSeries,
        AEmpresa,
        'SE',
        AItems);
    end);
  FNavegacion := TCoordinadorNavegacionComprasSesion.Create(
    EntornoNavegacion);
  CrearColaboradorMaterializacion;
  CrearColaboradorCopiaLineas;
  CrearColaboradorModelo;
  CrearColaboradorProveedor;
  FreeAndNil(FImportadorOcr);
  EntornoImportacion := Default(TEntornoImportacionPedidoOcr);
  EntornoImportacion.Conexion := ConexionTrabajo;
  EntornoImportacion.Datos := Dmm;
  EntornoImportacion.Vista := tvLineas;
  EntornoImportacion.Usuario := IdentidadSesion.Usuario;
  EntornoImportacion.MaximoTallas := CANT_TALLAS_MAX;
  EntornoImportacion.ObtenerDirectorioFotos :=
    function: string
    begin
      Result := DirectorioFotosAplicacion;
    end;
  EntornoImportacion.AplicarDuplicado :=
    procedure(const AResultado: TResolverDuplicadoSesion)
    begin
      FServicioComprasSesiones.AplicarDuplicadoEnLinea(AResultado);
    end;
  EntornoImportacion.CambiarEstadoColor :=
    procedure(AAplicando: Boolean)
    begin
      FAplicandoColorOcr := AAplicando;
    end;
  EntornoImportacion.AsignarColorLiteral :=
    procedure(const ALiteral: string)
    begin
      if FProveedor <> nil then
        FProveedor.AsignarColorBasicoLiteral(ALiteral);
    end;
  EntornoImportacion.AsignarColorCoincidente :=
    procedure
    begin
      if FProveedor <> nil then
        FProveedor.AsignarColorBasicoCoincidente;
    end;
  EntornoImportacion.PuedeGuardarFotos :=
    function: Boolean
    begin
      Result := Assigned(FotosArticulos);
    end;
  EntornoImportacion.GuardarFotos :=
    procedure(const ASerie, ANumero: string;
      const ASolicitudes: TSolicitudesFotosSesion;
      const AUsuario: string)
    begin
      FotosArticulos.Sesion.GuardarNuevasLote(
        ASerie,
        ANumero,
        ASolicitudes,
        AUsuario);
    end;
  FImportadorOcr := TCoordinadorImportacionPedidoOcr.Create(
    EntornoImportacion);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorMaterializacion;
var
  EntornoMaterializacion: TEntornoMaterializacionCompraSesion;
begin
  EntornoMaterializacion :=
    Default(TEntornoMaterializacionCompraSesion);
  EntornoMaterializacion.Propietario := Self;
  EntornoMaterializacion.Conexion := ConexionTrabajo;
  EntornoMaterializacion.Servicio := FServicioComprasSesiones;
  EntornoMaterializacion.Usuario := IdentidadSesion.Usuario;
  EntornoMaterializacion.Cabecera := Dmm.unqryTablaG;
  EntornoMaterializacion.Lineas := Dmm.unqrySesionLin;
  EntornoMaterializacion.Documentos := Dmm.unqrySesDocs;
  EntornoMaterializacion.FuenteAlmacenes := Dmm.dsAlmacenes;
  EntornoMaterializacion.FuenteTarifas := Dmm.dsTarifas;
  EntornoMaterializacion.FuenteTemporadas := Dmm.dsTemporadas;
  EntornoMaterializacion.Registrar :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  EntornoMaterializacion.RefrescarFotos :=
    procedure
    begin
      if FFotos <> nil then
        FFotos.RefrescarLista;
    end;
  FAplicacionMaterializacion :=
    CrearAplicacionMaterializacionCompraSesionVcl(EntornoMaterializacion);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorCopiaLineas;
var
  EntornoCopia: TEntornoCopiaLineasSesion;
begin
  // CrearTablaPrincipal puede repetirse al reprocesar perfiles.
  FreeAndNil(FCopiaLineas);
  EntornoCopia := Default(TEntornoCopiaLineasSesion);
  EntornoCopia.Propietario := Self;
  EntornoCopia.Servicio := FServicioComprasSesiones;
  EntornoCopia.Usuario := IdentidadSesion.Usuario;
  EntornoCopia.Cabecera := Dmm.unqryTablaG;
  EntornoCopia.Lineas := Dmm.unqrySesionLin;
  EntornoCopia.Vista := tvLineas;
  EntornoCopia.ColumnasTallas := FTallas.Columnas;
  EntornoCopia.ColumnaColor := dbcLinColor;
  EntornoCopia.ColumnaPrecioCompra := dbcLinPrecioCompra;
  EntornoCopia.ObtenerGestorTallas :=
    function: TGestorGridTallas
    begin
      Result := GestorTallas;
    end;
  EntornoCopia.RefrescarTotalesSesion :=
    procedure
    begin
      Dmm.RefrescarTotalesSesion;
    end;
  EntornoCopia.RegistrarAviso :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  FCopiaLineas := TCoordinadorCopiaLineasSesion.Create(EntornoCopia);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorModelo;
var
  EntornoModelo: TEntornoModeloProveedorSesion;
begin
  FreeAndNil(FModeloPrv);
  EntornoModelo := Default(TEntornoModeloProveedorSesion);
  EntornoModelo.Propietario := Self;
  EntornoModelo.Conexion := ConexionTrabajo;
  EntornoModelo.Servicio := FServicioComprasSesiones;
  EntornoModelo.Usuario := IdentidadSesion.Usuario;
  EntornoModelo.Cabecera := Dmm.unqryTablaG;
  EntornoModelo.Lineas := Dmm.unqrySesionLin;
  EntornoModelo.Vista := tvLineas;
  EntornoModelo.ColumnaModelo := dbcLinRefPrv;
  EntornoModelo.RefrescarTallas :=
    procedure
    begin
      if GestorTallas <> nil then
      begin
        GestorTallas.RecalcularMaxColumnas;
        GestorTallas.ActualizarCaptionsLineaActiva;
      end;
    end;
  EntornoModelo.FijarTallajeDefecto :=
    procedure(AIdConjunto: Integer)
    begin
      Dmm.TallajeDefectoActual := AIdConjunto;
    end;
  EntornoModelo.SolicitarCopiaLinea :=
    procedure(const AModelo: string; ALineaOrigen: Integer;
      const AColorTexto: string; const AColorBasico: string;
      AMargen: Double)
    begin
      FCopiaLineas.PrepararCopiaPendiente(
        AModelo, ALineaOrigen, AColorTexto, AColorBasico, AMargen);
    end;
  EntornoModelo.RegistrarAviso :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  FModeloPrv := TBuscadorModeloProveedorSesion.Create(EntornoModelo);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorProveedor;
var
  EntornoProveedor: TEntornoProveedorSesion;
begin
  FreeAndNil(FProveedor);
  EntornoProveedor := Default(TEntornoProveedorSesion);
  EntornoProveedor.Conexion := ConexionTrabajo;
  EntornoProveedor.Servicio := FServicioComprasSesiones;
  EntornoProveedor.Datos := Dmm;
  EntornoProveedor.BusquedaVisual := BusquedaVisual;
  EntornoProveedor.Vista := tvLineas;
  EntornoProveedor.ColumnaColorBasico := dbcLinColorBasico;
  EntornoProveedor.BotonKits := btnAplicarKit;
  EntornoProveedor.ObtenerGestorTallas :=
    function: TGestorGridTallas
    begin
      Result := GestorTallas;
    end;
  EntornoProveedor.MostrarNombreProveedor :=
    procedure(ATexto: string)
    begin
      lblProveedorNombre.Caption := ATexto;
    end;
  EntornoProveedor.RefrescarVisibilidadTipoIva :=
    procedure
    begin
      RefrescarVisibilidadTipoIva;
    end;
  EntornoProveedor.AbrirDistribuidor :=
    procedure(ACodigoKit: string)
    begin
      FTallas.AbrirDistribuidor(ACodigoKit);
    end;
  EntornoProveedor.Registrar :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  FProveedor := TCoordinadorProveedorSesion.Create(EntornoProveedor);
end;

// ===========================================================================
//   TJvEnterAsTab — apagar mientras el grid tiene foco
// ===========================================================================
// TJvEnterAsTab heredado de TfrmBase convierte VK_RETURN en VK_TAB a nivel
// de mensaje. Lo apagamos al entrar al grid y reactivamos al salir, asi
// Enter navega celda a celda (combinado con FocusCellOnTab del grid).
// La logica vive en inLibGridTallasInline.ActivarEnterComoTab — funciona
// igual para cualquier Mto que use el patron.
procedure TfrmMtoComprasSesiones.cxgrdLineasEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;
procedure TfrmMtoComprasSesiones.cxgrdLineasExit(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoComprasSesiones.btnGrabarClick(Sender: TObject);
begin
  LogSes('btnGrabarClick INICIO (delega al inherited)');
  inherited;
  LogSes('btnGrabarClick FIN. master/detail han hecho Post.');
  // Tras Grabar, cxGrid limpia los Values[] no-bound al redibujar la
  // fila (los Posts del master/detail provocan re-fetch).
  RecargarTallasVisibles;
  RecargarTallasDiferido;
end;

// ===========================================================================
//   Bootstrapping
// ===========================================================================

//function TfrmMtoComprasSesiones.Dmm: TdmComprasSesiones;
//begin
//  Result := tdmDataModule as TdmComprasSesiones;
//end;

// La foto sigue al articulo de la linea activa de la sesion
// (CODIGO_ART_TENTATIVO_SESLIN; las sesiones trabajan a nivel articulo,
// sin SKU). Las fotos propias de la sesion se guardan en
// fza_compras_sesiones_fotos y Ctrl+F abre su visor grande editable.
procedure TfrmMtoComprasSesiones.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineas.DataController.DataSource) then
  begin
    ds := tvLineas.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Ademas de dsTablaG (cabecera de sesion) enganchamos dsSesionLin para
// que la foto flotante refresque al moverse entre lineas.
function TfrmMtoComprasSesiones.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmm) then
    Result := [dsTablaG, dmm.dsSesionLin]
  else
    Result := [dsTablaG];
end;

function TfrmMtoComprasSesiones.DirectorioFotosAplicacion: string;
begin
  Result := '';
  if Assigned(ParametrosApp) then
    Result := Trim(ParametrosApp.GetPath('appDirFotos'));
end;

procedure TfrmMtoComprasSesiones.ImportarPedidoOcr(
  const AFicheroJson: string);
var
  Resultado: TResultadoImportacionPedidoOcr;
begin
  Resultado := FImportadorOcr.Ejecutar(AFicheroJson);
  Dmm.unqrySesionLin.Refresh;
  Dmm.RefrescarTotalesSesion;
  ReconstruirTallas;
  if FFotos <> nil then
    FFotos.RefrescarLista;
  FVisorPedidoOriginal.Cargar;
  Resultado.Paginas := FVisorPedidoOriginal.CantidadPaginas;
  cxPageControl1.ActivePage := tsPedidoOriginal;
  cxPageControl1Change(cxPageControl1);
  ShowMessage(FormatearResultadoImportacionPedidoOcr(Resultado));
end;
procedure TfrmMtoComprasSesiones.btnImportarPedidoClick(
  Sender: TObject);
var
  CasoGuardado: ICasoUsoGuardadoMtoGen;
  ResultadoOcr: TResultadoProcesoPedidoOcr;
  ResultadoGuardado: TResultadoGuardadoMtoGen;
  sAlmacen: string;
  sEmpresa: string;
  sSerie: string;
begin
  inherited;
  dlgImportarPedido.Filter := SFiltroDocumentoPdfPedidoSesionCompra;
  dlgImportarPedido.Options := dlgImportarPedido.Options +
    [ofPathMustExist, ofFileMustExist];
  if dlgImportarPedido.Execute then
  begin
    if (Dmm = nil) or Dmm.unqryTablaG.IsEmpty then
      raise Exception.Create(SErrorSesionCompraNoActiva);
    if not Dmm.unqrySesionLin.IsEmpty then
      raise Exception.Create(
        SErrorImportacionOcrSesionConLineas);
    if Dmm.unqryTablaG.State = dsInsert then
    begin
      sEmpresa := Trim(UbicacionSesion.Empresa);
      sAlmacen := Trim(UbicacionSesion.Almacen);
      if sEmpresa = '' then
        raise Exception.Create(
          SErrorUsuarioSinEmpresaImportacionOcr);
      if sAlmacen = '' then
        raise Exception.Create(
          SErrorUsuarioSinAlmacenImportacionOcr);
      sSerie := ObtenerSerieDefecto(
        ConexionTrabajo,
        sEmpresa,
        'SE');
      if sSerie = '' then
        raise Exception.CreateFmt(
          SErrorEmpresaSinSerieSesionesImportacionOcr,
          [sEmpresa]);
      Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString :=
        sEmpresa;
      Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString :=
        sAlmacen;
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString := sSerie;
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').Clear;
    end;
    if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
    begin
      CasoGuardado := CrearCasoUsoGuardadoMtoGenUniDAC(
        ConexionTrabajo);
      ResultadoGuardado := CasoGuardado.Ejecutar(
        procedure
        begin
          GrabarDatasets(Dmm);
        end);
      if ResultadoGuardado = rgmAbortado then
        raise Exception.Create(
          SErrorGuardarSesionAntesImportacionOcr);
    end;
    Screen.Cursor := crHourGlass;
    btnImportarPedido.Enabled := False;
    try
      try
        ResultadoOcr := TProcesoPedidoOcr.Ejecutar(
          dlgImportarPedido.FileName,
          procedure
          begin
            Application.ProcessMessages;
          end);
        try
          ImportarPedidoOcr(ResultadoOcr.FicheroJson);
        finally
          TProcesoPedidoOcr.EliminarTrabajo(
            ResultadoOcr.DirectorioTrabajo);
        end;
      except
        on E: Exception do
          ShowMessage(Format(SErrorImportarPedidoSesionCompra, [E.Message]));
      end;
    finally
      btnImportarPedido.Enabled := True;
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.cxPageControl2Change(Sender: TObject);
begin
  if FFotos <> nil then
    FFotos.ActualizarPaginaDetalle;
  if cxPageControl2.ActivePage = cxTabSheet1 then
  begin
    // Las tallas son columnas no-bound. Al volver a Lineas se publican
    // de nuevo por si un cambio de estado de la cabecera limpio Values[].
    RecargarTallasVisibles;
    RecargarTallasDiferido;
  end;
end;

procedure TfrmMtoComprasSesiones.cxPageControl1Change(Sender: TObject);
begin
  if FFotos <> nil then
    FFotos.ActualizarPaginaFicha;
  if cxPageControl1.ActivePage = tsPedidoOriginal then
  begin
    FVisorPedidoOriginal.CargarSiVacio;
    // Si la imagen ya esta cargada se conserva la vista actual: pagina,
    // zoom y desplazamiento. Solo se reajusta al cargar o al pulsar el boton.
  end
  else
  begin
    // Cancelar una linea puede reconstruir el DataController mientras se
    // consulta el documento. Al volver se restauran los Values[] de tallas.
    RecargarTallasDiferido;
  end;
end;

function TfrmMtoComprasSesiones.SqlRestriccionUsuario: string;
begin
  // Sesiones de compra: empresa y almacén destino (no llevan caja)
  Result := SqlFiltroEmpAlmCaja(
    ContextoSesion,
    ParametrosApp,
    'CODIGO_EMP_SES',
    'CODIGO_ALM_SES',
    '');
end;

procedure TfrmMtoComprasSesiones.CrearTablaPrincipal;
begin
  FDependencias.Validar;
  inherited;
  if tdmDataModule <> nil then
  begin
    Dmm := tdmDataModule as TdmComprasSesiones;
    CrearServicioSesion;
    CrearColaboradores;
    EnlazarListasCabecera;
    EnlazarDetalleSesion;
    EnlazarPestanaProveedor;
  end;
end;

procedure TfrmMtoComprasSesiones.CrearServicioSesion;
begin
  FreeAndNil(FServicioComprasSesiones);
  FServicioComprasSesiones := CrearServicioComprasSesiones(
    ConexionTrabajo, Dmm, FotosArticulos,
    FDependencias.CatalogoSql,
    FDependencias.IncidenciasSql);
  pkFieldName := 'SERIE_SES;NUMERO_SES';
end;

procedure TfrmMtoComprasSesiones.EnlazarListasCabecera;
begin
  cbbEmpresa.Properties.ListSource   := Dmm.dsEmpresas;
  cbbAlmacen.Properties.ListSource   := Dmm.dsAlmacenes;
  cbbTarifa.Properties.ListSource    := Dmm.dsTarifas;
  cbbTemporada.Properties.ListSource := Dmm.dsTemporadas;
  cbbTotalesFORMA_PAGO_SES.Properties.ListSource := Dmm.dsFormasPago;
  // ListSource del combo de proveedor (busqueda incremental por nombre).
  // Reutiliza el lookup Dmm.unqryProveedores, ya cargado para el rotulo.
  cbbProveedor.Properties.ListSource := Dmm.dsProveedores;
end;

procedure TfrmMtoComprasSesiones.EnlazarDetalleSesion;
begin
  Dmm.unqrySesionLin.MasterFields := 'SERIE_SES;NUMERO_SES';
  Dmm.unqrySesionLin.MasterSource := dsTablaG;
  // Hooks del detalle: al cambiar de fila el dataset hace Post
  // automatico, cxGrid repinta desde el dataset y pierde los Values[]
  // no-bound de las tallas; hay que volver a publicarlos.
  Dmm.unqrySesionLin.BeforePost   := unqrySesionLinBeforePostHook;
  Dmm.unqrySesionLin.AfterPost    := unqrySesionLinAfterPostHook;
  Dmm.unqrySesionLin.BeforeInsert := unqrySesionLinBeforeInsertHook;
  Dmm.unqrySesionLin.AfterInsert  := unqrySesionLinAfterInsertHook;
  Dmm.unqrySesionLin.AfterCancel  := unqrySesionLinAfterCancelHook;
  Dmm.unqrySesionLin.BeforeDelete := unqrySesionLinBeforeDeleteHook;
  Dmm.unqrySesionLin.AfterDelete  := unqrySesionLinAfterDeleteHook;
  // Cualquier re-fetch (Refresh explicito, master/detail, navegador)
  // resetea los Values[] no-bound: se recargan tras el re-fetch.
  Dmm.unqrySesionLin.AfterRefresh := unqrySesionLinRecargarTallasHook;
  Dmm.unqrySesionLin.AfterOpen    := unqrySesionLinRecargarTallasHook;
  if not Dmm.unqrySesionLin.Active then
    Dmm.unqrySesionLin.Open;
  if not Dmm.unqrySesionCel.Active then
    Dmm.unqrySesionCel.Open;
  // Master/detail de la pestania 'Documentos'.
  Dmm.unqrySesDocs.MasterFields := 'SERIE_SES;NUMERO_SES';
  Dmm.unqrySesDocs.MasterSource := dsTablaG;
  if not Dmm.unqrySesDocs.Active then
    Dmm.unqrySesDocs.Open;
  // Master/detail de la pestania de fotos provisionales.
  Dmm.unqrySesionFotos.MasterFields := 'SERIE_SES;NUMERO_SES';
  Dmm.unqrySesionFotos.MasterSource := dsTablaG;
  if not Dmm.unqrySesionFotos.Active then
    Dmm.unqrySesionFotos.Open;
  tvLineas.DataController.DataSource := Dmm.dsSesionLin;
  Dmm.dsSesionLin.OnDataChange := dsSesionLinDataChangeHook;
  tvDocs.DataController.DataSource := Dmm.dsSesDocs;
  tvFotosProvisionales.DataController.DataSource := Dmm.dsSesionFotos;
  // Las lineas son una hoja de edicion: al teclear en Modelo prov. la
  // tecla debe entrar al editor/lookup, no a la navegacion incremental.
  tvLineas.OptionsBehavior.AlwaysShowEditor := True;
  tvLineas.OptionsBehavior.IncSearch := False;
  FTallas.ConfigurarDatos(
    Dmm.unqryTablaG,
    Dmm.unqrySesionLin,
    Dmm.dsSesionLin);
  FModeloPrv.RecargarModelos;
  // Al navegar de una sesion a otra hay que recargar las cantidades de
  // tallas: sin esto las celdas no-bound quedan vacias.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  dsTablaG.OnStateChange := dsTablaGStateChangeHook;
  RefrescarColumnasTallas;
end;

procedure TfrmMtoComprasSesiones.EnlazarPestanaProveedor;
begin
  dsPrvFicha.DataSet := Dmm.unqryPrvFicha;
  tvPrvKits.DataController.DataSource    := Dmm.dsPrvKits;
  tvPrvKitsDet.DataController.DataSource := Dmm.dsPrvKitsDet;
  // Desplegable de kits de la cabecera: etiqueta descriptiva por kit.
  cbbKitProv.Properties.ListSource := Dmm.dsPrvKitsCombo;
  FProveedor.ActualizarRotuloProveedor;
  FProveedor.RecargarProveedorSesion;
  RefrescarVisibilidadTipoIva;
  if FFotos <> nil then
    FFotos.Refrescar;
end;

procedure TfrmMtoComprasSesiones.dsTablaGDataChangeHook(Sender: TObject;
                                                          Field: TField);
begin
  if ((Field = nil) or SameText(Field.FieldName, 'CODIGO_EMP_SES')) and
     (Dmm <> nil) and Dmm.unqryTablaG.Active and
     (not Dmm.unqryTablaG.IsEmpty) then
    Dmm.RefrescarAlmacenes(
      Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  // Refrescar el rotulo del proveedor al navegar entre sesiones (Field=nil)
  // o al cambiar CODIGO_PRV_SES tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_SES') then
  begin
    FProveedor.ActualizarRotuloProveedor;
    // Lista de modelos del desplegable "Modelo prov." acotada al proveedor.
    FModeloPrv.RecargarModelos;
    // Pestana Proveedor: ficha + kits del proveedor de la sesion.
    FProveedor.RecargarProveedorSesion;
    // Defectos del proveedor (margen %, sistema de tallas) solo cuando el
    // usuario esta cambiando el proveedor en la cabecera, no al navegar.
    if (Field <> nil) and (Dmm <> nil) and
       (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
    begin
      FProveedor.CopiarDefectosProveedor;
      RefrescarVisibilidadTipoIva;
    end;
  end;
  if (Field <> nil) and SameText(Field.FieldName, 'CODIGO_EMP_SES') and
     (Dmm <> nil) and (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    AplicarRecargoComprasEmpresa(
      CrearLecturasImpuestos(ConexionPrincipal), Dmm.unqryTablaG,
      'CODIGO_EMP_SES', 'ESIVA_RECARGO_COMPRAS_SES');
    Dmm.RefrescarTotalesSesion;
  end;
  if (Field <> nil) and
     (SameText(Field.FieldName, 'TIPO_IVA_SES') or
      SameText(Field.FieldName, 'ESIVA_RECARGO_COMPRAS_SES')) and
     (Dmm <> nil) then
  begin
    Dmm.RefrescarTotalesSesion;
    RefrescarVisibilidadTipoIva;
  end;
  if (Field <> nil) and SameText(Field.FieldName,
     'ESVARIOS_TIPOS_IVA_SES') then
    RefrescarVisibilidadTipoIva;
  // FIX: El formato distribuido solo se puede cambiar al crear la sesión.
  // Si el estado no es dsInsert, ponemos el check como ReadOnly.
  if (Field = nil) and (Dmm <> nil) and (Dmm.unqryTablaG <> nil) then
    chkFormatoDistribuido.Properties.ReadOnly :=
                                            (Dmm.unqryTablaG.State <> dsInsert);
  // Field = nil => cambio de record activo en el master (no es un cambio
  // puntual de un campo del registro actual). Es el momento de
  // recalcular columnas y volver a publicar las cantidades de las
  // lineas de esta sesion.
  if Field = nil then
  begin
    RefrescarVisibilidadTipoIva;
    if FFotos <> nil then
      FFotos.Refrescar;
    FVisorPedidoOriginal.Cargar;
    ReconstruirTallas;
  end;
end;

procedure TfrmMtoComprasSesiones.dsTablaGStateChangeHook(Sender: TObject);
begin
  // Conserva la gestion de botones y el rotulo Editando/Navegando del
  // mantenimiento base.
  inherited dsTablaGStateChange(Sender);
  if (Dmm <> nil) and Dmm.unqrySesionLin.Active and
     not Dmm.unqrySesionLin.IsEmpty then
  begin
    // Edit/Insert/Post del maestro resincroniza el detalle en cxGrid y
    // borra las columnas no-bound aunque las cantidades sigan en SESCEL.
    RecargarTallasVisibles;
    RecargarTallasDiferido;
  end;
end;

procedure TfrmMtoComprasSesiones.RefrescarVisibilidadTipoIva;
var
  sVarios : string;
begin
  if dbcLinTipoIva <> nil then
  begin
    dbcLinTipoIva.Visible := False;
    if (Dmm <> nil) and Dmm.unqryTablaG.Active and
       (Dmm.unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_SES') <> nil) then
    begin
      sVarios := UpperCase(Trim(
        Dmm.unqryTablaG.FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString));
      dbcLinTipoIva.Visible := sVarios = 'S';
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.cbbTipoIvaDefectoPropertiesChange(
  Sender: TObject);
begin
  inherited;
  RefrescarVisibilidadTipoIva;
  if Dmm <> nil then
    Dmm.RefrescarTotalesSesion;
end;

procedure TfrmMtoComprasSesiones.chkVariosTiposIvaPropertiesChange(
  Sender: TObject);
begin
  inherited;
  RefrescarVisibilidadTipoIva;
end;

procedure TfrmMtoComprasSesiones.chkRecargoComprasPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if Dmm <> nil then
    Dmm.RefrescarTotalesSesion;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterPostHook(
                                                      DataSet: TDataSet);
begin
  Dmm.unqrySesionLinAfterPost(DataSet);
  RefrescarVisibilidadTipoIva;
  // Al cambiar de fila el dataset hace Post automatico y cxGrid repinta
  // la fila abandonada, borrando sus Values[] no-bound.
  RecargarTallasVisibles;
  RecargarTallasDiferido;
end;

procedure TfrmMtoComprasSesiones.dsSesionLinDataChangeHook(
  Sender: TObject; Field: TField);
begin
  if (Field <> nil) and
     SameText(Field.FieldName, 'COLOR_TEXTO_SESLIN') and
     (not FAplicandoColorOcr) and
     (FProveedor <> nil) then
    FProveedor.AsignarColorBasicoCoincidente;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforePostHook(
  DataSet: TDataSet);
begin
  // Respaldo para cambios programaticos o controles que no hayan publicado
  // un DataChange antes de confirmar el registro.
  if (FProveedor <> nil) and (not FAplicandoColorOcr) then
    FProveedor.AsignarColorBasicoCoincidente;
  Dmm.unqrySesionLinBeforePost(DataSet);
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinRecargarTallasHook(
                                                      DataSet: TDataSet);
begin
  // AfterRefresh / AfterOpen comparten handler. La tabla de celdas ya
  // tiene la cantidad correcta: lo unico que falta es volver a pintarla
  // DESPUES de que el DataController procese el re-fetch.
  TThread.ForceQueue(nil,
    TThreadProcedure(
    procedure
    begin
      RecargarTallasVisibles;
      RefrescarVisibilidadTipoIva;
    end));
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforeInsertHook(
  DataSet: TDataSet);
begin
  // Preparar master antes de insertar en el detail. Dispara tanto
  // desde btnAddLinea / btnNuevoColor como desde el navigator del grid.
  if Dmm.unqryTablaG.IsEmpty then
  begin
    MessageDlg(SErrorCabeceraSesionAntesLineas,
               mtInformation, [mbOk], 0);
    Abort;
  end;
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
  if Dmm.unqryTablaG.State = dsBrowse then
    Dmm.unqryTablaG.Edit;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterInsertHook(
  DataSet: TDataSet);
begin
  // Delegar al handler del DM (asigna FKs y numero de linea)
  Dmm.unqrySesionLinAfterInsert(DataSet);
  // Foco en Modelo prov. (primer campo de la linea)
  tvLineas.Controller.FocusedColumn := dbcLinRefPrv;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterCancelHook(
  DataSet: TDataSet);
begin
  // Cancel elimina el registro de insercion y cxGrid vuelve a construir su
  // buffer. Las cantidades persisten en SESCEL, pero hay que republicarlas.
  RecargarTallasDiferido;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforeDeleteHook(
  DataSet: TDataSet);
var
  iLinea : Integer;
begin
  // Limpiar SESCEL de la linea ANTES del delete. No hay FK cascade
  // en BBDD; el patron es delete-on-app. Idempotente.
  iLinea := DataSet.FieldByName('LINEA_SESLIN').AsInteger;
  if iLinea > 0 then
  begin
    LogSes(Format('BeforeDelete: limpiando SESCEL linea=%d', [iLinea]));
    FServicioComprasSesiones.BorrarCeldasLinea(
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString,
      iLinea);
  end;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterDeleteHook(
  DataSet: TDataSet);
begin
  LogSes('AfterDelete: RefrescarTotalesSesion + RecalcularMaxColumnas');
  Dmm.RefrescarTotalesSesion;
  RefrescarVisibilidadTipoIva;
  // Tras el delete el grid se repinta y borra los Values[] no ligados:
  // hay que recalcular columnas, cantidades y captions de lo que queda.
  ReconstruirTallas;
end;

procedure TfrmMtoComprasSesiones.ResetForm;
begin
  inherited;
  FVisorPedidoOriginal.Cargar;
end;

procedure TfrmMtoComprasSesiones.FormCreate(Sender: TObject);
var
  EntornoVisor: TEntornoVisorPedidoOriginalSesion;
  GestorContexto: IGestorContextoSesion;
  i, IdxBase: Integer;
begin
  // OJO: TODO lo que vaya a usar el `inherited` (que ejecuta
  // ProcesarPerfiles -> CrearTablaPrincipal -> abre unqrySesionLin -> el
  // grid dispara OnFocusedRecordChanged sobre el gestor de tallas) tiene
  // que estar creado ANTES del inherited. Las columnas de talla se crean
  // aqui: si no existen, el recalculo del gestor seria un no-op.
  EntornoVisor := Default(TEntornoVisorPedidoOriginalSesion);
  EntornoVisor.Contenedor := scrPedidoOriginal;
  EntornoVisor.Imagen := imgPedidoOriginal;
  EntornoVisor.EtiquetaPagina := lblPaginaPedido;
  EntornoVisor.BotonAnterior := btnPaginaAnteriorPedido;
  EntornoVisor.BotonSiguiente := btnPaginaSiguientePedido;
  EntornoVisor.BotonAlejar := btnAlejarPedido;
  EntornoVisor.BotonAcercar := btnAcercarPedido;
  EntornoVisor.BotonAjustar := btnAjustarPedido;
  EntornoVisor.BotonZoomReal := btnZoomRealPedido;
  EntornoVisor.ObtenerDirectorio :=
    function: string
    begin
      Result := DirectorioFotosAplicacion;
    end;
  EntornoVisor.ObtenerSesion :=
    function(out ASerie, ANumero: string): Boolean
    begin
      ASerie := '';
      ANumero := '';
      Result := (Dmm <> nil) and Dmm.unqryTablaG.Active and
        (not Dmm.unqryTablaG.IsEmpty);
      if Result then
      begin
        ASerie := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
        ANumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
      end;
    end;
  FVisorPedidoOriginal := TVisorPedidoOriginalSesion.Create(
    EntornoVisor);
  CrearColaboradorTallas;
  FTallas.CrearColumnas;
  inherited;
  ConfigurarBotonBusquedaDesplegable(
    cbbProveedor,
    cbbProveedorPropertiesButtonClick);
  FFotos.ConfigurarCabecera;
  cxPageControl2.OnChange := cxPageControl2Change;
  FEstiloRecepcionVencida := TcxStyle.Create(Self);
  FEstiloRecepcionVencida.AssignedValues := [svTextColor];
  FEstiloRecepcionVencida.TextColor := clRed;
  for i := 0 to cxGrdDBTabPrin.ItemCount - 1 do
    cxGrdDBTabPrin.Items[i].Styles.OnGetContentStyle :=
      GridListaGetContentStyle;
  // Orden visual fijo de las columnas de lineas. Se hace DESPUES del
  // inherited porque el ancestro restaura el layout guardado y podria
  // alterar los Index. El bloque de tallas queda contiguo tras "Sistema
  // tallas"; totales y nro de linea al final.
  dbcLinRefPrv.Index       := 0;  // Modelo prov.
  dbcLinCodArt.Index       := 1;  // Codigo de articulo
  dbcLinFamilia.Index      := 2;  // Familia
  dbcLinDescripcion.Index  := 3;  // Descripcion
  dbcLinColor.Index        := 4;  // Color
  dbcLinColorBasico.Index  := 5;  // Color basico
  dbcLinPrecioCompra.Index := 6;  // Precio de compra
  dbcLinPrecioVenta.Index  := 7;  // Precio de venta
  dbcLinTallas.Index       := 8;  // Sistema de tallas
  IdxBase := dbcLinTallas.Index;
  FTallas.ReindexarColumnas(IdxBase);
  // Totales y nro de linea, tras el bloque de tallas pivotadas.
  dbcLinTotalTallas.Index  := IdxBase + CANT_TALLAS_MAX + 1;
  dbcLinImporteTotal.Index := IdxBase + CANT_TALLAS_MAX + 2;
  dbcLinNumero.Index       := IdxBase + CANT_TALLAS_MAX + 3;
  if FProveedor <> nil then
    FProveedor.CargarBasicosColor;
  // El contexto distribuye el log de la sesion sin estado global mutable.
  if Supports(ContextoSesion, IGestorContextoSesion, GestorContexto) then
    GestorContexto.AsignarLogSesion(nil);
end;

procedure TfrmMtoComprasSesiones.GridListaGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  colFecha: TcxGridDBColumn;
  colPdte : TcxGridDBColumn;
  vFecha  : Variant;
  vPdte   : Variant;
  dFecha  : TDateTime;
  rPdte   : Double;
begin
  if (ARecord <> nil) and (Sender is TcxGridDBTableView) then
  begin
    colFecha :=
      TcxGridDBTableView(Sender).GetColumnByFieldName(
        'FECHA_TOPE_RECEPCION_SES');
    colPdte :=
      TcxGridDBTableView(Sender).GetColumnByFieldName(
        'CANTIDAD_PENDIENTE_RECEPCION_SES');
    if (colFecha <> nil) and (colPdte <> nil) then
    begin
      vFecha := ARecord.Values[colFecha.Index];
      vPdte := ARecord.Values[colPdte.Index];
      if not (VarIsNull(vFecha) or VarIsEmpty(vFecha) or
              VarIsNull(vPdte) or VarIsEmpty(vPdte)) then
      begin
        dFecha := VarToDateTime(vFecha);
        if VarIsNumeric(vPdte) then
          rPdte := vPdte
        else
          rPdte := StrToFloatDef(VarToStr(vPdte), 0);
        if (rPdte > 0) and (Trunc(dFecha) < Date) then
          AStyle := FEstiloRecepcionVencida;
      end;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.FormDestroy(Sender: TObject);
var
  GestorContexto: IGestorContextoSesion;
begin
  if Dmm <> nil then
  begin
    if Assigned(Dmm.dsSesionLin) then
      Dmm.dsSesionLin.OnDataChange := nil;
  end;
  // Desenganchar el log antes de soltar los colaboradores que lo usan.
  if Supports(ContextoSesion, IGestorContextoSesion, GestorContexto) then
    GestorContexto.AsignarLogSesion(nil);
  FAplicacionMaterializacion := nil;
  FDependencias.Liberar;
  // Orden inverso al de creacion: primero los que consultan el gestor de
  // tallas y el servicio, despues sus proveedores. Los colaboradores
  // cierran sus propios cursores antes de que TfrmMtoGen.FormDestroy
  // libere el data module y deje la conexion inactiva.
  FreeAndNil(FNavegacion);
  FreeAndNil(FFotos);
  FreeAndNil(FVisorPedidoOriginal);
  FreeAndNil(FImportadorOcr);
  FreeAndNil(FCopiaLineas);
  FreeAndNil(FModeloPrv);
  FreeAndNil(FProveedor);
  FreeAndNil(FTallas);
  FreeAndNil(FServicioComprasSesiones);
  inherited;
end;

// ===========================================================================
//   Proveedor y kits — delegacion en TCoordinadorProveedorSesion
// ===========================================================================

procedure TfrmMtoComprasSesiones.cbbProveedorPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if (AButtonIndex >= 0) and
     (AButtonIndex < cbbProveedor.Properties.Buttons.Count) and
     (cbbProveedor.Properties.Buttons[
        AButtonIndex].Kind = bkEllipsis) then
    FProveedor.BuscarProveedor;
end;

procedure TfrmMtoComprasSesiones.cbbProveedorKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    FProveedor.BuscarProveedor;
  end;
end;

// ===========================================================================
//   Pestaña Proveedor — ficha, defectos y kits de cantidades por talla
// ===========================================================================

procedure TfrmMtoComprasSesiones.btnAplicarKitClick(Sender: TObject);
begin
  inherited;
  // Popup con los kits del proveedor de la sesion; el elegido se aplica
  // sobre la linea con foco del grid de articulos.
  FProveedor.MostrarMenuKits;
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitCabClick(Sender: TObject);
var
  sKit : string;
begin
  inherited;
  // El EditValue del desplegable de la cabecera es el CODIGO_PRVKIT.
  if VarIsNull(cbbKitProv.EditValue) or VarIsClear(cbbKitProv.EditValue) then
    sKit := ''
  else
    sKit := Trim(VarToStr(cbbKitProv.EditValue));
  if sKit = '' then
    MessageDlg(SErrorKitProveedorDesplegableNoSeleccionado,
               mtInformation, [mbOk], 0)
  else
    FProveedor.AplicarKitALineaActual(sKit);
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitProvClick(Sender: TObject);
begin
  inherited;
  // Aplica el kit seleccionado en el grid de la pestana Proveedor sobre
  // la linea con foco del grid de articulos.
  if (not Dmm.unqryPrvKits.Active) or Dmm.unqryPrvKits.IsEmpty then
    MessageDlg(SErrorProveedorSesionSinKits,
               mtInformation, [mbOk], 0)
  else
    FProveedor.AplicarKitALineaActual(
      Dmm.unqryPrvKits.FieldByName('CODIGO_PRVKIT').AsString);
end;

procedure TfrmMtoComprasSesiones.tvPrvKitsDblClick(Sender: TObject);
begin
  btnAplicarKitProvClick(Sender);
end;

// ===========================================================================
//   Lineas — alta, baja, navegacion
// ===========================================================================

procedure TfrmMtoComprasSesiones.btnAddLineaClick(Sender: TObject);
begin
  inherited;
  // BeforeInsert se encarga de preparar el master (Post si pendiente,// Edit si
  // Browse,Abort si IsEmpty).
  LogSes('btnAddLineaClick: detail.Insert');
  Dmm.unqrySesionLin.Insert;
  LogSes(Format('btnAddLineaClick FIN. LINEA_SESLIN=%d',
                [Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
end;

procedure TfrmMtoComprasSesiones.btnDelLineaClick(Sender: TObject);
begin
  inherited;
  if Dmm.unqrySesionLin.IsEmpty then
    LogSes('btnDelLineaClick: detail vacio, salida')
  else if MessageDlg(SPreguntaBorrarLineaSesionCompra,
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    LogSes('btnDelLineaClick: cancelado por el usuario')
  else
  begin
    LogSes(Format('btnDelLineaClick: linea=%d',
      [Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
    // BeforeDelete limpia SESCEL, AfterDelete recalcula columnas y totales
    Dmm.unqrySesionLin.Delete;
    LogSes('btnDelLineaClick FIN');
  end;
end;

procedure TfrmMtoComprasSesiones.btnCrearClick(Sender: TObject);
begin
  inherited;
  if Assigned(FAplicacionMaterializacion) then
    FAplicacionMaterializacion.Ejecutar;
end;


procedure TfrmMtoComprasSesiones.btnRevertirClick(Sender: TObject);
var
  sErr: string;
begin
  inherited;
  LogSes('btnRevertirClick INICIO');
  if Dmm.unqryTablaG.IsEmpty then
  begin
    LogSes('  cabecera vacia, salida');
    ShowMessage(SErrorSesionCompraNoActiva);
  end
  else if Dmm.unqryTablaG.FieldByName(
    'ESTADO_SES').AsString <> 'CERRADA' then
  begin
    LogSes('  sesion no esta CERRADA, abortar');
    ShowMessage(SErrorSesionNoCerradaParaReversion);
  end
  else if MessageDlg(SPreguntaRevertirSesionCompra,
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    LogSes('  cancelado por el usuario')
  else
  begin
    LogSes('  RevertirMaterializacion');
    Screen.Cursor := crHourGlass;
    try
      if FServicioComprasSesiones.RevertirMaterializacion(
        IdentidadSesion.Usuario, sErr) then
      begin
        LogSes('  reversion OK, master.Refresh');
        ShowMessage(SInfoSesionRevertida);
        Dmm.unqryTablaG.Refresh;
      end
      else
      begin
        LogSes('  reversion KO: ' + sErr);
        ShowMessage(Format(SErrorRevertirSesionCompra, [sErr]));
      end;
    finally
      Screen.Cursor := crDefault;
    end;
    LogSes('btnRevertirClick FIN');
  end;
end;

procedure TfrmMtoComprasSesiones.btnImprimirClick(Sender: TObject);
var
  form     : TfrmPrintSesion;
  sSerie   : string;
  sNumero  : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if Dmm.unqryTablaG.IsEmpty then
    ShowMessage(SErrorSesionActivaImprimirNoDisponible)
  else
  begin
    // Persistir cualquier edicion pendiente para que el informe la vea.
    if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
      Dmm.unqryTablaG.Post;
    if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
      Dmm.unqrySesionLin.Post;
    sSerie := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    form := TfrmPrintSesion.Create(Application);
    try
      form.dmSesion := Dmm;
      form.edtSerie.Text := sSerie;
      form.edtNumero.Text := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.btnNuevoColorClick(Sender: TObject);
begin
  inherited;
  FCopiaLineas.DuplicarLineaActiva('C');
end;

procedure TfrmMtoComprasSesiones.btnOtroPrecioClick(Sender: TObject);
begin
  inherited;
  FCopiaLineas.DuplicarLineaActiva('P');
end;

// 1. Declaramos la clase cracker para acceder al popup interno

procedure TfrmMtoComprasSesiones.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
begin
  inherited;
  // El selector de tallaje y el Ctrl+Enter sobre columnas editbutton los
  // atiende el coordinador de tallas. F3 sobre Familia / Cod. articulo
  // abre el picker jerarquico de familias.
  if not FTallas.ProcesarTeclaEditor(AItem, AEdit, Key, Shift) then
  begin
    if (Key = VK_F3) and (Shift = []) and
       ((AItem = dbcLinFamilia) or (AItem = dbcLinCodArt)) then
    begin
      FModeloPrv.ElegirFamiliaConModal;
      Key := 0;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // KeyPreview heredado = True: este KeyDown corre antes que la
  // navegacion Enter->Tab del grid y que el FormKeyDown base.
  if not FTallas.ProcesarTeclaFormulario(Key, Shift) then
    inherited KeyDown(Key, Shift);
end;

procedure TfrmMtoComprasSesiones.dbcLinTallasPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FTallas.AbrirSelector(Sender, '');
end;

procedure TfrmMtoComprasSesiones.btnArbolFamiliasClick(Sender: TObject);
begin
  inherited;
  // Mismo modal jerarquico que F3 sobre la columna Familia. Operamos
  // sobre la linea con foco; si no hay ninguna, avisamos.
  if Dmm.unqrySesionLin.IsEmpty then
    MessageDlg(SErrorLineaSesionAsignarFamiliaNoSeleccionada,
               mtInformation, [mbOk], 0)
  else
    FModeloPrv.ElegirFamiliaConModal;
end;

procedure TfrmMtoComprasSesiones.dbcLinFamiliaPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FModeloPrv.ResolverFamiliaTecleada(Sender);
end;

procedure TfrmMtoComprasSesiones.dbcLinCodArtPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FModeloPrv.ResolverCodigoTecleado(Sender);
end;

procedure TfrmMtoComprasSesiones.dbcLinRefPrvPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FModeloPrv.ResolverReferenciaTecleada(Sender);
end;

procedure TfrmMtoComprasSesiones.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if GestorTallas <> nil then
    GestorTallas.ActualizarCaptionsLineaActiva;
  if FFotos <> nil then
    FFotos.Refrescar;
end;

// ===========================================================================
//   Color basico — selector con paleta
// ===========================================================================

procedure TfrmMtoComprasSesiones.tvLineasInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  inherited;
  // Estilo Excel: al entrar a una celda el contenido queda seleccionado.
  SeleccionarTodoEnEditor(AEdit);
  // 'Modelo prov.': si el editor es el desplegable de busqueda
  // incremental, el buscador engancha su debounce. En otro caso puede
  // ser la celda de color basico, que pinta el swatch en su boton.
  if (FModeloPrv <> nil) and (FProveedor <> nil) and
     (not FModeloPrv.EngancharEditor(AItem, AEdit)) then
    FProveedor.PrepararEditorColorBasico(AItem, AEdit);
end;

procedure TfrmMtoComprasSesiones.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  // El sombreado de tallas fuera del conjunto y el nombre del sistema
  // los pinta el coordinador de tallas; el swatch, el de proveedor.
  if (FTallas <> nil) and FTallas.DibujarCelda(ACanvas, AViewInfo) then
    ADone := True
  else if (FProveedor <> nil) and
          FProveedor.DibujarCeldaColor(ACanvas, AViewInfo) then
    ADone := True;
end;

procedure TfrmMtoComprasSesiones.tvLineasEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  FTallas.AjustarPermisoEdicion(AItem, AAllow);
end;

procedure TfrmMtoComprasSesiones.dbcLinColorBasicoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FProveedor.ElegirColorBasico(Sender);
end;

// ===========================================================================
//   Auto-PVP
// ===========================================================================

procedure TfrmMtoComprasSesiones.dbcLinPrecioCompraPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).PostEditValue;
  FModeloPrv.ProponerPrecioVenta;
end;

initialization
  RegistrarPantalla(TfrmMtoComprasSesiones);
  ForceReferenceToClass(TfrmMtoComprasSesiones);
end.
