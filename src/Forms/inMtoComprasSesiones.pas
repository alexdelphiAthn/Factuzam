{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesiones                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       21/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Sesion de compra: crear articulos en lote y un pedido o un albaran        }
{    contra un proveedor. Variante grid plano con edicion INLINE de            }
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
  inMtoModalCrearAlbaranSesion,
  inLibGridTallasInline,
  UniDataComprasSesiones, cxBlobEdit, dxShellDialogs, cxRadioGroup, Vcl.Buttons,
  dxDateRanges, cxSplitter;

const
  // Numero maximo de columnas de talla inline. Subido a 20 a peticion
  // de un cliente con sistemas extensos (rangos de calzado largos,
  // tallas internacionales niño+adulto, etc.).
  CANT_TALLAS_MAX = 20;

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
    btnImprimir: TcxButton;
    btnCrear: TcxButton;
    btnRevertir: TcxButton;

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

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
    procedure btnNuevoColorClick(Sender: TObject);
    procedure btnFotoClick(Sender: TObject);
    procedure btnArbolFamiliasClick(Sender: TObject);
    procedure btnCrearClick(Sender: TObject);
    procedure btnRevertirClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnLogClearClick(Sender: TObject);
    procedure btnLogCopyClick(Sender: TObject);
    procedure btnIrADocClick(Sender: TObject);
    procedure tvDocsDblClick(Sender: TObject);
    procedure cbbSeriePropertiesInitPopup(Sender: TObject);
    procedure actIrArticulosExecute(Sender: TObject);
    procedure actIrAlbaranesCompraExecute(Sender: TObject);
    procedure actIrPedidosCompraExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure btnDescargarFotosClick(Sender: TObject);
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
    // ACodigoKit <> '' abre el distribuidor en modo kit (formato
    // distribuido): botones aplicar/limpiar por almacen + aplicar a todos.
    procedure AbrirDistribuidor(const ACodigoKit: string = '');
    procedure CopiarCeldasDistribuidasOtroColor(ALineaOrigen,
                                                 ALineaDestino: Integer);
    procedure cbbProveedorPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbProveedorKeyUp(Sender: TObject; var Key: Word;
                                Shift: TShiftState);
    procedure btnAplicarKitClick(Sender: TObject);
    procedure btnAplicarKitCabClick(Sender: TObject);
    procedure btnAplicarKitProvClick(Sender: TObject);
    procedure btnIrProveedorClick(Sender: TObject);
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
  private
    FGestorTallas : TGestorGridTallas;     // mueve toda la logica reusable
                                           // de tallas pivotadas a la lib
    FTallaColumns : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FBasicosColor : TArray<string>;
    FQryConjuntosTallas : TUniQuery;
    // Opciones del selector "Sistema tallas" (listbox 3 columnas, mismo
    // patron que el de color basico) y diccionario ID_AC -> NOMBRE_AC
    // que usa el CustomDrawCell para pintar el nombre en vez del ID crudo.
    FOpcionesTallas  : TArray<TOpcionConjuntoTalla>;
    FNombresConjunto : TDictionary<Integer, string>;
    FBmpSwatch    : TBitmap;
    Dmm: TdmComprasSesiones;
    // --- Busqueda incremental in-cell de la columna "Modelo prov." ---
    // Desplegable (ExtLookupComboBox) que lista los modelos
    // (REF_PROVEEDOR_AP) ya existentes del proveedor de la cabecera cuyo
    // comienzo coincide con lo tecleado. Al elegir uno, la linea se marca
    // REUSAR del articulo correspondiente: el sistema de tallas queda fijo y
    // solo se incorporan colores/tallas nuevos al materializar. Mismo patron
    // runtime que inLibGridArticulos (la lib/form no tiene estos objetos en
    // el dfm). FModeloPrvCargado guarda el proveedor con el que se cargo la
    // lista para no relanzar el query si no cambia; FModeloRefPend y
    // FModeloCodArtPend guardan la fila elegida pendiente de resolver.
    FModeloBusqQry      : TUniQuery;
    FModeloBusqDs       : TDataSource;
    FModeloRepo         : TcxGridViewRepository;
    FModeloView         : TcxGridDBTableView;
    FModeloColRef       : TcxGridDBColumn;
    FModeloColCodArt    : TcxGridDBColumn;
    FModeloEditRepo     : TcxEditRepository;
    FModeloCombo        : TcxEditRepositoryExtLookupComboBoxItem;
    FModeloTimerBusq    : TTimer;
    FModeloTimerResolve : TTimer;
    FModeloPrvCargado   : string;
    FModeloRefPend      : string;
    FModeloCodArtPend   : string;
    // --- Pestaña Proveedor + kits ---
    // FPrvFichaCargado evita reabrir la ficha/kits si el proveedor no ha
    // cambiado al navegar. FMenuKits es el popup del boton "Aplicar kit"
    // de la barra de Lineas; FMenuKitsCodigos guarda el CODIGO_PRVKIT de
    // cada item (el Tag indexa este array).
    FPrvFichaCargado    : string;
    FMenuKits           : TPopupMenu;
    FMenuKitsCodigos    : TArray<string>;
    FEstiloRecepcionVencida: TcxStyle;
    procedure CargarBasicosColor;
    procedure CargarConjuntosTallas;
    procedure BuscarProveedor;
    procedure ActualizarLabelProveedor;
    procedure RecargarProveedorSesion;
    procedure CopiarDefectosProveedor;
    procedure AplicarKitALineaActual(const ACodigoKit: string);
    procedure MenuKitItemClick(Sender: TObject);
    function  AplicarDuplicadoDeSesion(const AModelo,
                ACodigoArt: string): Boolean;
    function  DispararEditButtonLineaActiva: Boolean;
    function  TextoBusquedaTallaje(Key: Word; Shift: TShiftState): string;
    procedure AbrirSelectorTallas(Sender: TObject;
                const ABusquedaInicial: string = '');
    procedure CrearColumnasTallas;
    procedure InicializarGestorTallas;
    procedure RefrescarVisibilidadTipoIva;
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure GridListaGetContentStyle(Sender: TcxCustomGridTableView;
                ARecord: TcxCustomGridRecord;
                AItem: TcxCustomGridTableItem;
                var AStyle: TcxStyle);
    procedure unqrySesionLinAfterPostHook(DataSet: TDataSet);
    procedure unqrySesionLinBeforeInsertHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterInsertHook(DataSet: TDataSet);
    procedure unqrySesionLinBeforeDeleteHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterDeleteHook(DataSet: TDataSet);
    procedure unqrySesionLinRecargarTallasHook(DataSet: TDataSet);
    procedure ExpandirCodigoFamiliaActiva(const ACodigoFam: string;
                const ANombreFam: string = '');
    procedure ProponerPrecioVenta;
    procedure LogMsg(const S: string);
    function MaterializarSesionConTx(AFrmSet: TfrmModalCrearAlbaranSesion;
                                      const AUsuario: string;
                                      AListaDocs: TStringList;
                                      out ASerPed, ANumPed,
                                          ASerAlb, ANumAlb,
                                          AErr: string): Boolean;
    // Busqueda incremental in-cell de modelos del proveedor (columna
    // "Modelo prov."): crea el desplegable, lo recarga al cambiar de
    // proveedor y resuelve la eleccion como linea REUSAR.
    procedure CrearLookupModelo;
    procedure RecargarModelos;
    procedure ModeloGetProperties(Sender: TcxCustomGridTableItem;
                ARecord: TcxCustomGridRecord;
                var AProperties: TcxCustomEditProperties);
    procedure ModeloComboChange(Sender: TObject);
    procedure ModeloComboCloseUp(Sender: TObject);
    procedure ModeloTimerBusqTimer(Sender: TObject);
    procedure ModeloTimerResolveTimer(Sender: TObject);
  protected
    // Interceptamos a nivel de form (KeyPreview heredado = True) para
    // que Ctrl+Enter abra el selector de la columna editbutton enfocada
    // ANTES de que la navegacion Enter->Tab del grid / FormKeyDown base
    // mueva el foco a otra pestania.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoComprasSesiones: TfrmMtoComprasSesiones;

implementation

uses
  inLibGlobalVar,
  inLibUser,
  inLibFiltroUsuario,
  inLibGenBusq,
  inLibComprasSesiones,
  inMtoModalDistribuidor,
  inMtoModalDocsCreados,
  inLibShowMto, inMtoPrincipal,
  inLibComprasSesionesMaterializar,
  Vcl.Clipbrd,
  inLibAtributosPaleta,
  inLibFotos,
  inLibtb,
  inMtoModalSelFamilia,
  inMtoModalImpSesion,
  inMtoModalIncidencias,
  inLibFotosNube,
  inLibComprasImpuestos;

const
  fIdVaColor = 'CO';

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

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
var
  bPopupAbierto: Boolean;
begin
  inherited;

//  bPopupAbierto := False;
//  if (tvLineas.Controller.EditingController <> nil) and
//     (tvLineas.Controller.EditingController.Edit <> nil) and
//     (tvLineas.Controller.EditingController.Edit is TcxCustomDropDownEdit) then
//  begin
//    bPopupAbierto := TcxCustomDropDownEdit(tvLineas.Controller.EditingController.Edit).DroppedDown;
//  end;
//
//  // Si salimos del grid porque se ha abierto el popup del combo de tallas,
//  // NO reactivamos el EnterAsTab. Así permitimos que el Enter nativo llegue al combo
//  // para confirmar la selección.
//  if not bPopupAbierto then
//    inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoComprasSesiones.btnGrabarClick(Sender: TObject);
begin
  LogSes('btnGrabarClick INICIO (delega al inherited)');
  inherited;
  LogSes('btnGrabarClick FIN. master/detail han hecho Post.');
  // Tras Grabar, cxGrid limpia los Values[] no-bound al redibujar el
  // row (los Posts del master/detail provocan re-fetch). Recargamos
  // las cantidades desde la tabla de celdas para que las celdas
  // talla vuelvan a mostrar lo que el usuario tecleo.
  if Assigned(FGestorTallas) then FGestorTallas.CargarCantidadesTodasLineas;
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
// sin SKU). Las fotos propias de la sesion -mientras el articulo aun no
// se ha materializado- se asignan con el boton "Foto" y viven en
// fza_compras_sesiones_fotos; Ctrl+F muestra la foto estandar del
// articulo si ya existe en fza_articulos_fotos.
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

function TfrmMtoComprasSesiones.SqlRestriccionUsuario: string;
begin
  // Sesiones de compra: empresa y almacén destino (no llevan caja)
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_SES', 'CODIGO_ALM_SES', '');
end;

procedure TfrmMtoComprasSesiones.CrearTablaPrincipal;
begin
  inherited;
  if tdmDataModule = nil then Exit;
  dmm := tdmDataModule as TdmComprasSesiones;
  pkFieldName := 'SERIE_SES;NUMERO_SES';

  cbbEmpresa.Properties.ListSource   := Dmm.dsEmpresas;
  cbbAlmacen.Properties.ListSource   := Dmm.dsAlmacenes;
  cbbTarifa.Properties.ListSource    := Dmm.dsTarifas;
  cbbTemporada.Properties.ListSource := Dmm.dsTemporadas;
  cbbTotalesFORMA_PAGO_SES.Properties.ListSource := Dmm.dsFormasPago;
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup Dmm.unqryProveedores, ya cargado para el rotulo.
  cbbProveedor.Properties.ListSource := Dmm.dsProveedores;

  with Dmm do
  begin
    unqrySesionLin.MasterFields := 'SERIE_SES;NUMERO_SES';
    unqrySesionLin.MasterSource := dsTablaG;
    // Hook AfterPost: cuando el usuario cambia de fila el dataset
    // hace Post automatico y cxGrid repinta la fila desde el dataset,
    // limpiando los Values[] no-bound. Re-publicamos las cantidades
    // de todas las lineas desde la cache de SESCEL.
    unqrySesionLin.AfterPost    := unqrySesionLinAfterPostHook;
    unqrySesionLin.BeforeInsert := unqrySesionLinBeforeInsertHook;
    unqrySesionLin.AfterInsert  := unqrySesionLinAfterInsertHook;
    unqrySesionLin.BeforeDelete := unqrySesionLinBeforeDeleteHook;
    unqrySesionLin.AfterDelete  := unqrySesionLinAfterDeleteHook;
    // Hook AfterRefresh / AfterOpen: cualquier re-fetch de unqrySesionLin
    // (Refresh explicito, re-fetch master/detail tras cambios en el master,
    // navegacion entre sesiones, etc.) resetea los Values[] no-bound del
    // cxGrid. Sin esta recarga las celdas talla quedan en blanco aunque el
    // SELECT de CargarCantidadesTodasLineas se haya ejecutado antes.
    unqrySesionLin.AfterRefresh := unqrySesionLinRecargarTallasHook;
    unqrySesionLin.AfterOpen    := unqrySesionLinRecargarTallasHook;
    if not unqrySesionLin.Active then unqrySesionLin.Open;
    if not unqrySesionCel.Active then unqrySesionCel.Open;
    // Master/detail de la pestania 'Documentos'. Mismo patron que
    // unqrySesionLin: declaramos MasterSource aqui (no en el dfm).
    unqrySesDocs.MasterFields := 'SERIE_SES;NUMERO_SES';
    unqrySesDocs.MasterSource := dsTablaG;
    if not unqrySesDocs.Active then unqrySesDocs.Open;
  end;
  tvLineas.DataController.DataSource := Dmm.dsSesionLin;
  tvDocs.DataController.DataSource := Dmm.dsSesDocs;
  // Las lineas son una hoja de edicion: al teclear en Modelo prov. la
  // tecla debe entrar al editor/lookup, no a la navegacion incremental.
  tvLineas.OptionsBehavior.AlwaysShowEditor := True;
  tvLineas.OptionsBehavior.IncSearch := False;

  InicializarGestorTallas;

  // Desplegable in-cell de busqueda de modelos del proveedor sobre la
  // columna "Modelo prov." (se crea una vez; se recarga al posicionarse
  // en una sesion / cambiar de proveedor en dsTablaGDataChangeHook).
  if FModeloCombo = nil then CrearLookupModelo;
  RecargarModelos;

  // Hook OnDataChange del master: cuando el usuario navega de una
  // sesion a otra (o se posiciona en la primera tras abrir el form),
  // re-cargamos las cantidades de tallas. Sin esto, las celdas no-bound
  // quedan vacias hasta que se Postea una linea, aunque los totales
  // (TOTAL_UNIDADES_SESLIN, bound) si se ven correctos.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;

  if Assigned(FGestorTallas) then
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.CargarCantidadesTodasLineas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
  // Pestaña Proveedor: ficha (solo lectura) + kits del proveedor.
  dsPrvFicha.DataSet := Dmm.unqryPrvFicha;
  tvPrvKits.DataController.DataSource    := Dmm.dsPrvKits;
  tvPrvKitsDet.DataController.DataSource := Dmm.dsPrvKitsDet;
  // Desplegable de kits de la cabecera: muestra una etiqueta descriptiva
  // por kit (nombre + sistema + primera/ultima talla con cantidad).
  cbbKitProv.Properties.ListSource := Dmm.dsPrvKitsCombo;
  // Pintar el rotulo del proveedor de la sesion enfocada al abrir el form.
  ActualizarLabelProveedor;
  RecargarProveedorSesion;
  RefrescarVisibilidadTipoIva;
end;

procedure TfrmMtoComprasSesiones.dsTablaGDataChangeHook(Sender: TObject;
                                                          Field: TField);
begin
  // Refrescar el rotulo del proveedor al navegar entre sesiones (Field=nil)
  // o al cambiar CODIGO_PRV_SES tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_SES') then
  begin
    ActualizarLabelProveedor;
    // Lista de modelos del desplegable "Modelo prov." acotada al proveedor.
    RecargarModelos;
    // Pestaña Proveedor: ficha + kits del proveedor de la sesion.
    RecargarProveedorSesion;
    // Defectos del proveedor (margen %, sistema de tallas) solo cuando el
    // usuario esta cambiando el proveedor en la cabecera, no al navegar.
    if (Field <> nil) and (Dmm <> nil) and
       (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
    begin
      CopiarDefectosProveedor;
      RefrescarVisibilidadTipoIva;
    end;
  end;
  if (Field <> nil) and SameText(Field.FieldName, 'CODIGO_EMP_SES') and
     (Dmm <> nil) and (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, Dmm.unqryTablaG,
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
    if FGestorTallas <> nil then
    begin
      FGestorTallas.InvalidarCache;
      FGestorTallas.RecalcularMaxColumnas;
      FGestorTallas.CargarCantidadesTodasLineas;
      FGestorTallas.ActualizarCaptionsLineaActiva;
    end;
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
  // Cuando el usuario cambia de fila el dataset hace Post automatico:
  // cxGrid reacciona repintando la fila desde el dataset y eso borra
  // los Values[] no-bound (tallas) de la fila que abandona. Re-cargamos
  // las cantidades de todas las lineas desde SESCEL — el SELECT
  // agregado es barato y el BeginUpdate/EndUpdate del DataController
  // lo deja en una sola pasada.
  if Assigned(FGestorTallas) then
    FGestorTallas.CargarCantidadesTodasLineas;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinRecargarTallasHook(
                                                      DataSet: TDataSet);
begin
  // AfterRefresh / AfterOpen comparten handler. Cualquier re-fetch del
  // dataset de lineas (Refresh explicito en btnCrearClick / Distribuidor,
  // re-fetch master/detail al cambiar de cabecera o al Postear el master,
  // boton Refresh del navegador) borra los Values[] no-bound de las
  // columnas talla. El SELECT que CargarCantidadesUnaLinea hace para
  // recuperarlos solo funciona si se ejecuta DESPUES del re-fetch — y la
  // tabla `fza_compras_sesiones_celdas` ya tiene la cantidad correcta, lo
  // unico que falta es volver a pintar el grid.
  // Diferimos con ForceQueue para que el DataController de cxGrid termine
  // de procesar la notificacion del re-fetch antes de tocar Values[].
  TThread.ForceQueue(nil,
    procedure
    begin
      if Assigned(FGestorTallas) then
        FGestorTallas.CargarCantidadesTodasLineas;
      RefrescarVisibilidadTipoIva;
    end);
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforeInsertHook(
  DataSet: TDataSet);
begin
  // Preparar master antes de insertar en el detail. Dispara tanto
  // desde btnAddLinea / btnNuevoColor como desde el navigator del grid.
  if Dmm.unqryTablaG.IsEmpty then
  begin
    MessageDlg('Crea y graba la cabecera de la sesion antes de anadir lineas.',
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

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforeDeleteHook(
  DataSet: TDataSet);
var
  iLinea : Integer;
begin
  // Limpiar SESCEL de la linea ANTES del delete. No hay FK cascade
  // en BBDD; el patron es delete-on-app. Idempotente.
  iLinea := DataSet.FieldByName('LINEA_SESLIN').AsInteger;
  if iLinea <= 0 then
    Exit;
  LogSes(Format('BeforeDelete: limpiando SESCEL linea=%d', [iLinea]));
  with TUniQuery.Create(nil) do
  try
    Connection := inLibGlobalVar.oConn;
    SQL.Text :=
      'DELETE FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    ParamByName('s').AsString :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    ParamByName('n').AsString :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    ParamByName('l').AsInteger := iLinea;
    ExecSQL;
    LogSes(Format('  SESCEL borradas (filas=%d)', [RowsAffected]));
  finally
    Free;
  end;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterDeleteHook(
  DataSet: TDataSet);
begin
  // Sustituye el handler del DM (que solo llamaba RefrescarTotalesSesion)
  // y anade la recalculacion de columnas de talla del grid.
  LogSes('AfterDelete: RefrescarTotalesSesion + RecalcularMaxColumnas');
  Dmm.RefrescarTotalesSesion;
  RefrescarVisibilidadTipoIva;
  if Assigned(FGestorTallas) then
    FGestorTallas.RecalcularMaxColumnas;
end;

procedure TfrmMtoComprasSesiones.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoComprasSesiones.FormCreate(Sender: TObject);
var
  i, IdxBase : Integer;
begin
  // OJO: TODO lo que vaya a usar el `inherited` (que ejecuta
  // ProcesarPerfiles -> CrearTablaPrincipal -> abre unqrySesionLin -> el
  // grid dispara OnFocusedRecordChanged sobre el gestor de tallas) tiene
  // que estar creado ANTES del inherited.
  FBmpSwatch := TBitmap.Create;
  FNombresConjunto := TDictionary<Integer, string>.Create;
  // Query que alimenta el selector "Sistema tallas": solo conjuntos del
  // atributo pivot (ID_VA_AC = 'TAL'), no colores ni otros ejes. Trae
  // ademas primera y ultima talla (ordenadas por ORDEN_ACD) para
  // mostrarlas como rango (columnas 'Desde' / 'Hasta') en el listbox.
  FQryConjuntosTallas := TUniQuery.Create(Self);
  FQryConjuntosTallas.Connection := inLibGlobalVar.oConn;
  FQryConjuntosTallas.SQL.Text :=
    'SELECT AC.ID_AC, AC.NOMBRE_AC, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD, AV.AV LIMIT 1) AS PRIMERA, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD DESC, AV.AV DESC LIMIT 1) AS ULTIMA ' +
    '  FROM fza_atributos_conjuntos AC ' +
    ' WHERE AC.ESACTIVO_AC = ''S'' ' +
    '   AND AC.ID_VA_AC = ''TAL'' ' +
    ' ORDER BY AC.NOMBRE_AC';
  FQryConjuntosTallas.Open;
  // Volcar la query a la lista de opciones del selector y al diccionario
  // ID_AC -> NOMBRE_AC (lo usa CustomDrawCell para mostrar el nombre).
  CargarConjuntosTallas;

  // CrearColumnasTallas debe correr antes de inherited (CrearTablaPrincipal,
  // lanzada desde inherited, llama a RecalcularMaxColumnas y
  // CargarCantidadesTodasLineas del gestor; si las columnas no existen
  // todavia ambos son no-op).
  CrearColumnasTallas;

  inherited;

  FEstiloRecepcionVencida := TcxStyle.Create(Self);
  FEstiloRecepcionVencida.AssignedValues := [svTextColor];
  FEstiloRecepcionVencida.TextColor := clRed;
  for i := 0 to cxGrdDBTabPrin.ItemCount - 1 do
    cxGrdDBTabPrin.Items[i].Styles.OnGetContentStyle :=
      GridListaGetContentStyle;

  // Forzar orden visual de las columnas de lineas (orden fijo pedido por
  // el usuario). Se hace DESPUES del inherited porque el ancestro restaura
  // el layout guardado y podria alterar los Index. El bloque de tallas
  // queda contiguo tras "Sistema tallas"; totales y nro de linea al final.
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
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    if Assigned(FTallaColumns[i]) then
      FTallaColumns[i].Index := IdxBase + i + 1;
  end;
  // Totales y nro de linea, tras el bloque de tallas pivotadas.
  dbcLinTotalTallas.Index  := IdxBase + CANT_TALLAS_MAX + 1;  // Total tallas
  dbcLinImporteTotal.Index := IdxBase + CANT_TALLAS_MAX + 2;  // Total importe
  dbcLinNumero.Index       := IdxBase + CANT_TALLAS_MAX + 3;  // Nro de linea

  CargarBasicosColor;

  // Enganchar el callback de log: cualquier punto del DM o de la lib
  // que llame a LogSes(...) vuelca aqui. Se desengancha en FormDestroy.
  inLibGlobalVar.oLogSesion := Self.LogMsg;
  LogMsg('Form abierto. version=' + inLibGlobalVar.oVersion);
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

procedure TfrmMtoComprasSesiones.LogMsg(const S: string);
begin
  // Vuelca al memo de la pestania 'Log'. Limite blando de 5000 lineas
  // para que el memo no engorde indefinidamente en sesiones largas;
  // cuando se pasa, se recorta la mitad inicial.
//  if not Assigned(mLog) then Exit;
//  mLog.Lines.BeginUpdate;
//  try
//    mLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' ' + S);
//    if mLog.Lines.Count > 5000 then
//      while mLog.Lines.Count > 2500 do
//        mLog.Lines.Delete(0);
//  finally
//    mLog.Lines.EndUpdate;
//  end;
end;

procedure TfrmMtoComprasSesiones.btnLogClearClick(Sender: TObject);
begin
//  if Assigned(mLog) then mLog.Lines.Clear;
end;

procedure TfrmMtoComprasSesiones.btnLogCopyClick(Sender: TObject);
begin
//  if Assigned(mLog) then Clipboard.AsText := mLog.Lines.Text;
end;

procedure TfrmMtoComprasSesiones.btnIrADocClick(Sender: TObject);
var
  sTipo, sSerie, sNumero: string;
begin
  // Navega al documento seleccionado en la pestania Documentos. La
  // query unqrySesDocs es master/detail con unqryTablaG (cabecera de
  // sesion); siempre lista los docs de la sesion enfocada. Tambien lo
  // dispara el boton lateral "Ir a Ped / Alb" desde cualquier pestania.
  if (Dmm.unqrySesDocs = nil) or Dmm.unqrySesDocs.IsEmpty then
    ShowMessage('La sesion no tiene documentos creados.')
  else
  begin
    sTipo   := Dmm.unqrySesDocs.FieldByName('TIPO').AsString;
    sSerie  := Dmm.unqrySesDocs.FieldByName('SERIE').AsString;
    sNumero := Dmm.unqrySesDocs.FieldByName('NUMERO').AsString;
    // ALBC = albaran de compra, PEDC = pedido de compra (ambos con Mto
    // registrado en fza_winforms; la busqueda es SERIE,NUMERO).
    if SameText(sTipo, 'ALBC') then
      ShowMto(frmMtoPrincipal, 'AlbaranesCompra', sSerie + ',' + sNumero)
    else if SameText(sTipo, 'PEDC') then
      ShowMto(frmMtoPrincipal, 'PedidosCompra', sSerie + ',' + sNumero)
    else
      ShowMessage(Format(
        'No hay mantenimiento disponible para el tipo de documento "%s".',
        [sTipo]));
  end;
end;

// Combo de serie de la cabecera: al desplegar se recargan las series
// 'SE' vigentes de la empresa de la sesion. Si la empresa no tiene
// ninguna, se avisa y se ofrece ir a Empresas -> Series a crearlas.
procedure TfrmMtoComprasSesiones.cbbSeriePropertiesInitPopup(Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (Dmm <> nil) and Dmm.unqryTablaG.Active then
    sEmpresa := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
  CargarSeriesEmpresa(sEmpresa, 'SE', cbbSerie.Properties.Items);
  if cbbSerie.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de sesiones de compra (tipo SE) para la ' +
                  'empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ShowMto(frmMtoPrincipal, 'Empresas');
  end;
end;

procedure TfrmMtoComprasSesiones.tvDocsDblClick(Sender: TObject);
begin
  btnIrADocClick(Sender);
end;

procedure TfrmMtoComprasSesiones.actIrArticulosExecute(Sender: TObject);
begin
  // ShortCut Ctrl+A. El TActionList scope a este form garantiza que el
  // shortcut solo se procesa cuando esta pestania esta activa; otras
  // instancias o Mtos abiertos no reciben el evento.
  with tvLineas.DataController.DataSet do
  ShowMto(Self.Owner,
          'Articulos',
          FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString);
end;

procedure TfrmMtoComprasSesiones.actIrAlbaranesCompraExecute(Sender: TObject);
begin
  // ShortCut Ctrl+Shift+A.
  ShowMto(frmMtoPrincipal, 'AlbaranesCompra');
end;

procedure TfrmMtoComprasSesiones.actIrPedidosCompraExecute(Sender: TObject);
begin
  // ShortCut Ctrl+Shift+P. El Mto de pedidos de compra ya existe
  // (CALL_WINF='PedidosCompra' en fza_winforms).
  ShowMto(frmMtoPrincipal, 'PedidosCompra');
end;

procedure TfrmMtoComprasSesiones.actIrProveedorExecute(Sender: TObject);
begin
  // ShortCut Ctrl+P: abre la ficha del proveedor de la cabecera.
  btnIrProveedorClick(Sender);
end;

procedure TfrmMtoComprasSesiones.btnDescargarFotosClick(Sender: TObject);
var
  sSerie, sNumero, sCodArt, sMsg, sFile: string;
  iLinea  : Integer;
  archivos: TArray<string>;
  bOK     : Boolean;
begin
  inherited;
  // Boton "Bajar fotos": descarga del servidor las fotos del articulo de
  // la linea activa, las descomprime en appDirFotos y borra el ZIP.
  // Integra ademas una foto representativa en la linea de la sesion, igual
  // que "+ Foto" (oFotos.GuardarSesion con CODIGO_UNIDAD = ''). El atajo
  // global Ctrl+F abre la foto flotante de esa misma linea.
  if Dmm.unqryTablaG.IsEmpty then
    ShowMessage('No hay sesion activa.')
  else if Dmm.unqrySesionLin.IsEmpty then
    ShowMessage('Selecciona o crea una linea antes de descargar fotos.')
  else
  begin
    if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
      Dmm.unqryTablaG.Post;
    if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
      Dmm.unqrySesionLin.Post;
    sSerie  := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    iLinea  := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    sCodArt := Trim(Dmm.unqrySesionLin.FieldByName(
                      'CODIGO_ART_TENTATIVO_SESLIN').AsString);
    if sCodArt = '' then
      ShowMessage('La linea activa no tiene codigo de articulo.')
    else
    begin
      Screen.Cursor := crHourGlass;
      try
        bOK := DescargarFotosArticulo(sCodArt, archivos, sMsg);
      finally
        Screen.Cursor := crDefault;
      end;
      if not bOK then
        ShowMessage('No se pudieron descargar las fotos del articulo ' +
                    sCodArt + ':' + sLineBreak + sMsg)
      else
      begin
        sFile := ElegirFotoRepresentativa(archivos);
        if sFile <> '' then
          oFotos.GuardarSesion(sSerie, sNumero, iLinea, sCodArt, '', sFile);
        // Borrar los PNG temporales extraidos (no dejar huerfanos).
        LimpiarDescargaTemporal(archivos);
        ShowMessage(Format('Descargadas %d foto(s) del articulo %s.',
          [Length(archivos), sCodArt]));
      end;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.FormDestroy(Sender: TObject);
begin
  // Cerrar la query del lookup y soltar la connection ANTES del
  // inherited: TfrmMtoGen.FormDestroy libera el DataModule y, por
  // los caminos de UniDAC, la oConn global puede quedar en estado
  // 'not connected' antes de que esta query (Owner=Self) sea
  // destruida automaticamente al final del proceso. Si la
  // destrucion automatica encuentra Active=True intenta cerrar el
  // cursor contra una conexion ya inactiva -> "Connection is not
  // connected".
  if Assigned(FQryConjuntosTallas) then
  begin
    try
      if FQryConjuntosTallas.Active then FQryConjuntosTallas.Close;
    except
      // Si la conexion ya cayo no podemos hacer nada util aqui.
    end;
    FQryConjuntosTallas.Connection := nil;
    FreeAndNil(FQryConjuntosTallas);
  end;
  // Desenganchar el log antes del inherited (que libera el form): si
  // algun chivato disparara LogSes durante la destruccion del DM no
  // queremos que intente escribir en mLog ya liberado.
  inLibGlobalVar.oLogSesion := nil;
  FreeAndNil(FNombresConjunto);
  FreeAndNil(FGestorTallas);
  FreeAndNil(FBmpSwatch);
  // Objetos runtime del desplegable "Modelo prov." (orden inverso a su
  // creacion en CrearLookupModelo).
  FreeAndNil(FModeloTimerResolve);
  FreeAndNil(FModeloTimerBusq);
  FreeAndNil(FModeloEditRepo);
  FreeAndNil(FModeloRepo);
  FreeAndNil(FModeloBusqDs);
  FreeAndNil(FModeloBusqQry);
  inherited;
end;

procedure TfrmMtoComprasSesiones.CargarBasicosColor;
var
  q : TUniQuery;
  i : Integer;
begin
  SetLength(FBasicosColor, 0);
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ATB FROM fza_atributos_basicos ' +
      ' WHERE ID_VA_ATB = :va AND ESACTIVO_ATB = ''S'' ' +
      ' ORDER BY ORDEN_ATB, NOMBRE_ATB';
    q.ParamByName('va').AsString := fIdVaColor;
    q.Open;
    SetLength(FBasicosColor, q.RecordCount);
    i := 0;
    while not q.Eof do
    begin
      FBasicosColor[i] := q.FieldByName('CODIGO_ATB').AsString;
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

// ===========================================================================
//   Proveedor — busqueda (inMtoGenSearch sobre vi_proveedores) y rotulo
// ===========================================================================
// Sustituye al antiguo combo de proveedores por un ButtonEdit que abre el
// buscador generico (TfrmMtoSearch / inMtoGenSearch) sobre vi_proveedores y
// un rotulo que muestra nombre + razon social del proveedor seleccionado.

procedure TfrmMtoComprasSesiones.cbbProveedorPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarProveedor;
end;

procedure TfrmMtoComprasSesiones.cbbProveedorKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    BuscarProveedor;
  end;
end;

procedure TfrmMtoComprasSesiones.BuscarProveedor;
var
  sCodigo : string;
begin
  // Abre inMtoGenSearch sobre vi_proveedores y vuelca el CODIGO_PRV_PRV
  // elegido en CODIGO_PRV_SES de la cabecera de la sesion.
  if Dmm.unqryTablaG.IsEmpty then
    MessageDlg('Crea o selecciona una sesion antes de elegir el proveedor.',
               mtInformation, [mbOk], 0)
  else if TBusquedaUtils.EjecutarBusqueda(
            'Busqueda de proveedores',
            'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
            'CODIGO_PRV_PRV', sCodigo, 'frmMtoSesProvSearch') then
  begin
    if not (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
      Dmm.unqryTablaG.Edit;
    Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString := sCodigo;
    ActualizarLabelProveedor;
  end;
end;

procedure TfrmMtoComprasSesiones.ActualizarLabelProveedor;
var
  sCodigo : string;
  sNombre : string;
  sRazon  : string;
begin
  // Resuelve NOMBRE_PRV + RAZON_SOCIAL_PRV (via el lookup unqryProveedores) y
  // los pinta en el rotulo para que se vea con claridad quien es el proveedor.
  // Se antepone el nombre comercial (NOMBRE_PRV): es el que el usuario
  // reconoce a simple vista; la razon social solo se anade entre parentesis
  // como referencia si difiere.
  sCodigo := '';
  if (Dmm <> nil) and Assigned(Dmm.unqryTablaG) and Dmm.unqryTablaG.Active and
     (not Dmm.unqryTablaG.IsEmpty) then
    sCodigo := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  if sCodigo = '' then
    lblProveedorNombre.Caption := ''
  else if (Dmm.unqryProveedores <> nil) and Dmm.unqryProveedores.Active and
          Dmm.unqryProveedores.Locate('CODIGO_PRV_PRV', sCodigo, []) then
  begin
    sRazon  := Dmm.unqryProveedores.FieldByName('RAZON_SOCIAL_PRV').AsString;
    sNombre := Dmm.unqryProveedores.FieldByName('NOMBRE_PRV').AsString;
    // Si no hay nombre comercial cargado, caemos a la razon social como
    // rotulo principal. Si hay nombre y difiere de la razon social, la
    // razon social se anade entre parentesis como referencia.
    if Trim(sNombre) = '' then
      lblProveedorNombre.Caption := sCodigo + ' - ' + sRazon
    else if not SameText(Trim(sNombre), Trim(sRazon)) then
      lblProveedorNombre.Caption :=
        sCodigo + ' - ' + sNombre + '  (' + sRazon + ')'
    else
      lblProveedorNombre.Caption := sCodigo + ' - ' + sNombre;
  end
  else
    lblProveedorNombre.Caption := sCodigo + ' - (proveedor no encontrado)';
end;

// ===========================================================================
//   Pestaña Proveedor — ficha, defectos y kits de cantidades por talla
// ===========================================================================

procedure TfrmMtoComprasSesiones.RecargarProveedorSesion;
var
  sPrv : string;
begin
  // Reabre la ficha y los kits solo si el proveedor cambia (o si la query
  // quedo cerrada tras un ResetForm). Se invoca al navegar de sesion y al
  // cambiar CODIGO_PRV_SES.
  sPrv := '';
  if (Dmm <> nil) and Assigned(Dmm.unqryTablaG) and Dmm.unqryTablaG.Active and
     (not Dmm.unqryTablaG.IsEmpty) then
    sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  if (Dmm <> nil) and
     ((not SameText(sPrv, FPrvFichaCargado)) or
      ((sPrv <> '') and (not Dmm.unqryPrvFicha.Active))) then
  begin
    FPrvFichaCargado := sPrv;
    Dmm.RecargarProveedorSesion(sPrv);
  end;
end;

procedure TfrmMtoComprasSesiones.CopiarDefectosProveedor;
begin
  // Copia a la cabecera los defectos de compras del proveedor recien
  // elegido. El margen solo pisa cuando el proveedor tiene valor.
  if (Dmm <> nil) and Dmm.unqryPrvFicha.Active and
     (not Dmm.unqryPrvFicha.IsEmpty) then
  begin
    if Dmm.unqryPrvFicha.FieldByName('PORCENTAJE_MARGEN_PRV').AsFloat > 0 then
    begin
      if not (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
        Dmm.unqryTablaG.Edit;
      Dmm.unqryTablaG.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat :=
        Dmm.unqryPrvFicha.FieldByName('PORCENTAJE_MARGEN_PRV').AsFloat;
    end;
    // Sistema de tallas por defecto del proveedor: NO se copia a ningun
    // campo de cabecera (la sesion no tiene columna para eso), solo fija
    // el tallaje-defecto-del-documento en memoria (Dmm.TallajeDefectoActual)
    // que unqrySesionLinAfterInsert propone a la siguiente linea nueva.
    if (Dmm.unqryPrvFicha.FindField('ID_AC_TALLAS_PRV') <> nil) and
       (Dmm.unqryPrvFicha.FieldByName('ID_AC_TALLAS_PRV').AsInteger > 0) then
      Dmm.TallajeDefectoActual :=
        Dmm.unqryPrvFicha.FieldByName('ID_AC_TALLAS_PRV').AsInteger;
    if (Dmm.unqryPrvFicha.FindField('CODIGO_FP_PRV') <> nil) and
       (Dmm.unqryTablaG.FindField('FORMA_PAGO_SES') <> nil) and
       (Trim(Dmm.unqryTablaG.FieldByName('FORMA_PAGO_SES').AsString) = '') and
       (Trim(Dmm.unqryPrvFicha.FieldByName('CODIGO_FP_PRV').AsString) <> '') then
    begin
      if not (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
        Dmm.unqryTablaG.Edit;
      Dmm.unqryTablaG.FieldByName('FORMA_PAGO_SES').AsString :=
        Trim(Dmm.unqryPrvFicha.FieldByName('CODIGO_FP_PRV').AsString);
    end;
    if (Dmm.unqryPrvFicha.FindField(
       'ESVARIOS_TIPOS_IVA_PRV') <> nil) and
       (Dmm.unqryTablaG.FindField(
       'ESVARIOS_TIPOS_IVA_SES') <> nil) then
    begin
      if not (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
        Dmm.unqryTablaG.Edit;
      Dmm.unqryTablaG.FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString :=
        UpperCase(Trim(
          Dmm.unqryPrvFicha.FieldByName(
            'ESVARIOS_TIPOS_IVA_PRV').AsString));
      if Dmm.unqryTablaG.FieldByName(
         'ESVARIOS_TIPOS_IVA_SES').AsString = '' then
        Dmm.unqryTablaG.FieldByName(
          'ESVARIOS_TIPOS_IVA_SES').AsString := 'N';
      RefrescarVisibilidadTipoIva;
    end;
    if (Dmm.unqryPrvFicha.FindField(
       'ESIVA_EXENTO_INTRACOMUNITARIO_PRV') <> nil) and
       (Dmm.unqryTablaG.FindField(
       'ESIVA_EXENTO_INTRACOMUNITARIO_SES') <> nil) then
    begin
      if not (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
        Dmm.unqryTablaG.Edit;
      Dmm.unqryTablaG.FieldByName(
        'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString :=
        UpperCase(Trim(Dmm.unqryPrvFicha.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_PRV').AsString));
      if Dmm.unqryTablaG.FieldByName(
         'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString = '' then
        Dmm.unqryTablaG.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString := 'N';
      Dmm.RefrescarTotalesSesion;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.AplicarKitALineaActual(
  const ACodigoKit: string);
var
  sPrv     : string;
  sResumen : string;
  iLinea   : Integer;
  idxRec   : Integer;
begin
  sPrv := '';
  if not Dmm.unqryTablaG.IsEmpty then
    sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  // Formato distribuido: las cantidades viven por almacen, asi que el kit
  // se aplica desde la matriz de almacenes (distribuidor en modo kit, con
  // botones aplicar/limpiar por almacen y aplicar en todos). Validamos
  // antes el tallaje con la misma regla que el modo simple.
  if (not Dmm.unqryTablaG.IsEmpty) and
     (Dmm.unqryTablaG.FieldByName(
                            'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S') then
  begin
    if ValidarKitSobreLineaActual(Dmm, sPrv, ACodigoKit, sResumen) then
    begin
      LogSes(Format('AplicarKit %s -> distribuidor (formato distribuido)',
                    [ACodigoKit]));
      AbrirDistribuidor(ACodigoKit);
    end
    else
      MessageDlg(sResumen, mtWarning, [mbOk], 0);
  end
  // Formato simple: vuelca las cantidades del kit sobre la linea con foco
  // y repinta la fila igual que tras teclear a mano (totales + no-bound).
  else if AplicarKitProveedorALinea(Dmm, FGestorTallas, sPrv, ACodigoKit,
                                    sResumen) then
  begin
    iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    if Assigned(FGestorTallas) then
    begin
      FGestorTallas.RefrescarTotalesLineaActual;
      idxRec := tvLineas.Controller.FocusedRecordIndex;
      if idxRec >= 0 then
        FGestorTallas.CargarCantidadesUnaLinea(idxRec, iLinea);
    end;
    if Assigned(Dmm) then
      Dmm.RefrescarTotalesSesion;
    LogSes(Format('AplicarKit %s sobre linea %d', [ACodigoKit, iLinea]));
    // Aviso solo si alguna talla del kit no caso con el sistema de la linea.
    if sResumen <> '' then
      MessageDlg(sResumen, mtInformation, [mbOk], 0);
  end
  else
    MessageDlg(sResumen, mtWarning, [mbOk], 0);
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitClick(Sender: TObject);
var
  oItem : TMenuItem;
  pt    : TPoint;
begin
  inherited;
  // Popup con los kits del proveedor de la sesion; el elegido se aplica
  // sobre la linea con foco del grid de articulos.
  if Dmm.unqrySesionLin.IsEmpty then
    MessageDlg('Selecciona o crea una linea de articulo primero.',
               mtInformation, [mbOk], 0)
  else if (not Dmm.unqryPrvKits.Active) or Dmm.unqryPrvKits.IsEmpty then
    MessageDlg('El proveedor de la sesion no tiene kits definidos. Se ' +
               'crean en Proveedores, pestaña Compras.',
               mtInformation, [mbOk], 0)
  else
  begin
    if FMenuKits = nil then
      FMenuKits := TPopupMenu.Create(Self);
    FMenuKits.Items.Clear;
    SetLength(FMenuKitsCodigos, 0);
    Dmm.unqryPrvKits.DisableControls;
    try
      Dmm.unqryPrvKits.First;
      while not Dmm.unqryPrvKits.Eof do
      begin
        oItem := TMenuItem.Create(FMenuKits);
        oItem.Caption := StringReplace(
          Dmm.unqryPrvKits.FieldByName('CODIGO_PRVKIT').AsString + ' - ' +
          Dmm.unqryPrvKits.FieldByName('NOMBRE_PRVKIT').AsString,
          '&', '&&', [rfReplaceAll]);
        oItem.Tag     := Length(FMenuKitsCodigos);
        oItem.OnClick := MenuKitItemClick;
        FMenuKits.Items.Add(oItem);
        SetLength(FMenuKitsCodigos, Length(FMenuKitsCodigos) + 1);
        FMenuKitsCodigos[High(FMenuKitsCodigos)] :=
          Dmm.unqryPrvKits.FieldByName('CODIGO_PRVKIT').AsString;
        Dmm.unqryPrvKits.Next;
      end;
      Dmm.unqryPrvKits.First;
    finally
      Dmm.unqryPrvKits.EnableControls;
    end;
    pt := btnAplicarKit.ClientToScreen(Point(0, btnAplicarKit.Height));
    FMenuKits.Popup(pt.X, pt.Y);
  end;
end;

procedure TfrmMtoComprasSesiones.MenuKitItemClick(Sender: TObject);
begin
  if Sender is TMenuItem then
  begin
    if (TMenuItem(Sender).Tag >= 0) and
       (TMenuItem(Sender).Tag <= High(FMenuKitsCodigos)) then
      AplicarKitALineaActual(FMenuKitsCodigos[TMenuItem(Sender).Tag]);
  end;
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitCabClick(Sender: TObject);
var
  sKit : string;
begin
  inherited;
  // Aplica el kit elegido en el desplegable de la cabecera sobre la linea
  // con foco. El EditValue del lookup es el CODIGO_PRVKIT.
  if VarIsNull(cbbKitProv.EditValue) or VarIsClear(cbbKitProv.EditValue) then
    sKit := ''
  else
    sKit := Trim(VarToStr(cbbKitProv.EditValue));
  if sKit = '' then
    MessageDlg('Elige un kit del proveedor en el desplegable.',
               mtInformation, [mbOk], 0)
  else
    AplicarKitALineaActual(sKit);
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitProvClick(Sender: TObject);
begin
  inherited;
  // Aplica el kit seleccionado en el grid de la pestaña Proveedor sobre
  // la linea con foco del grid de articulos.
  if (not Dmm.unqryPrvKits.Active) or Dmm.unqryPrvKits.IsEmpty then
    MessageDlg('El proveedor de la sesion no tiene kits definidos. Se ' +
               'crean en Proveedores, pestaña Compras.',
               mtInformation, [mbOk], 0)
  else
    AplicarKitALineaActual(
      Dmm.unqryPrvKits.FieldByName('CODIGO_PRVKIT').AsString);
end;

procedure TfrmMtoComprasSesiones.tvPrvKitsDblClick(Sender: TObject);
begin
  btnAplicarKitProvClick(Sender);
end;

procedure TfrmMtoComprasSesiones.btnIrProveedorClick(Sender: TObject);
var
  sPrv : string;
begin
  inherited;
  sPrv := '';
  if not Dmm.unqryTablaG.IsEmpty then
    sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  if sPrv = '' then
    ShowMto(Self.Owner, 'Proveedores')
  else
    ShowMto(Self.Owner, 'Proveedores', sPrv);
end;

// ===========================================================================
//   Creacion y cache de columnas de talla
// ===========================================================================

procedure TfrmMtoComprasSesiones.CargarConjuntosTallas;
var
  iId : Integer;
  k   : Integer;
begin
  // Vuelca FQryConjuntosTallas a FOpcionesTallas (lo consume el selector
  // listbox de 3 columnas) y a FNombresConjunto (ID_AC -> NOMBRE_AC, lo
  // usa tvLineasCustomDrawCell para mostrar el nombre del sistema en la
  // celda en vez del ID numerico que esta bound).
  SetLength(FOpcionesTallas, 0);
  if Assigned(FNombresConjunto) then
    FNombresConjunto.Clear;
  if (FQryConjuntosTallas = nil) or (not FQryConjuntosTallas.Active) then Exit;
  SetLength(FOpcionesTallas, FQryConjuntosTallas.RecordCount);
  k := 0;
  FQryConjuntosTallas.First;
  while not FQryConjuntosTallas.Eof do
  begin
    iId := FQryConjuntosTallas.FieldByName('ID_AC').AsInteger;
    FOpcionesTallas[k].IdAc    := iId;
    FOpcionesTallas[k].Nombre  := FQryConjuntosTallas.FieldByName('NOMBRE_AC').AsString;
    FOpcionesTallas[k].Primera := FQryConjuntosTallas.FieldByName('PRIMERA').AsString;
    FOpcionesTallas[k].Ultima  := FQryConjuntosTallas.FieldByName('ULTIMA').AsString;
    if Assigned(FNombresConjunto) then
      FNombresConjunto.AddOrSetValue(iId, FOpcionesTallas[k].Nombre);
    Inc(k);
    FQryConjuntosTallas.Next;
  end;
end;

procedure TfrmMtoComprasSesiones.CrearColumnasTallas;
var
  i          : Integer;
  Col        : TcxGridDBColumn;
  IndiceBase : Integer;
begin
  // Crea CANT_TALLAS_MAX columnas inline entre dbcLinTallas y
  // dbcLinTotalTallas. Patron heredado de inMtoCajaOpe.ConstruirColumnasDinamicas:
  // BeginUpdate + CreateColumn + asignar Col.Index al final con
  // IndiceBase = dbcLinTallas.Index. Esto garantiza orden visual
  // contiguo (predefinirlas en DFM disparaba RLINK32 'Unsupported 16bit
  // resource' al compilar los descendientes).
  IndiceBase := dbcLinTallas.Index;
  tvLineas.BeginUpdate;
  try
    for i := 0 to CANT_TALLAS_MAX - 1 do
    begin
      Col := tvLineas.CreateColumn;
      Col.Name    := Format('dbcLinTalla%2.2d', [i + 1]);
      Col.Tag     := i + 1;
      Col.Caption := '';
      Col.Visible := False;
      Col.Width   := 50;
      Col.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(Col.Properties).DisplayFormat := '#,##0';
      // Cuadrar texto: cabecera y contenido centrados.
      Col.HeaderAlignmentHorz := taCenter;
      TcxCurrencyEditProperties(Col.Properties).Alignment.Horz := taCenter;
      // ValueTypeClass solo se puede asignar a runtime (no serializable
      // en DFM: dispara EReadError 'Property ValueTypeClass does not
      // exist' al cargar el form).
      Col.DataBinding.ValueTypeClass := TcxFloatValueType;
      Col.Index := IndiceBase + i + 1;
      FTallaColumns[i] := Col;
    end;
  finally
    tvLineas.EndUpdate;
  end;
end;

procedure TfrmMtoComprasSesiones.InicializarGestorTallas;
var
  cfg     : TGridTallasConfig;
  i       : Integer;
  arrCols : TArray<TcxGridDBColumn>;
begin
  // Cablea el gestor de tallas pivotadas (libreria reutilizable) con
  // los nombres de tabla/campos especificos de Sesiones de compra.
  // Si en el futuro se reusa este patron para Pedidos / Albaranes /
  // Facturas, basta crear otro form con los sufijos PEDLIN/PEDCEL,
  // ALBLIN/ALBCEL, etc. y la libreria hace lo mismo sin cambios.
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if Dmm = nil then Exit;

  SetLength(arrCols, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arrCols[i] := FTallaColumns[i];

  cfg := Default(TGridTallasConfig);
  cfg.Conexion           := inLibGlobalVar.oConn;
  cfg.Usuario            := oUser;
  cfg.Grid               := tvLineas;
  cfg.SourceMaster       := dsTablaG;
  cfg.SourceLineas       := Dmm.dsSesionLin;
  cfg.ColumnasTallas     := arrCols;
  cfg.FieldSerieMaster   := 'SERIE_SES';
  cfg.FieldNumeroMaster  := 'NUMERO_SES';
  cfg.FieldLinea         := 'LINEA_SESLIN';
  cfg.FieldConjuntoPivot := 'ID_AC_PIVOT_SESLIN';
  cfg.FieldPrecioBase    := 'PRECIO_COMPRA_SESLIN';
  cfg.FieldTotalUds      := 'TOTAL_UNIDADES_SESLIN';
  cfg.FieldTotalLinea    := 'TOTAL_LINEA_SESLIN';
  cfg.TablaCeldas        := 'fza_compras_sesiones_celdas';
  cfg.FieldSerieCel      := 'SERIE_SES_SESCEL';
  cfg.FieldNumeroCel     := 'NUMERO_SES_SESCEL';
  cfg.FieldLineaCel      := 'LINEA_SES_SESCEL';
  cfg.FieldFilaCel       := 'ID_FILA_SES_SESCEL';
  cfg.FieldAvPivotCel    := 'ID_AV_PIVOT_SESCEL';
  cfg.FieldCantidadCel   := 'CANTIDAD_SESCEL';
  cfg.FieldAlmacenCel    := 'CODIGO_ALM_SESCEL';
  cfg.IdFilaFijo         := 1;
  cfg.MaxColumnas        := CANT_TALLAS_MAX;

  FGestorTallas := TGestorGridTallas.Create(cfg);

  // Hookear cada talla al form para recalcular linea y cabecera.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).OnEditValueChanged
                                       := TallaEditValueChangedHook;
end;

procedure TfrmMtoComprasSesiones.TallaEditValueChangedHook(Sender: TObject);
begin
  if Assigned(FGestorTallas) then
  begin
    FGestorTallas.PersistirCeldaActiva(Sender);
    if Assigned(Dmm) then
      Dmm.RefrescarTotalesSesion;
  end;
end;

// ===========================================================================
//   Busqueda incremental de modelos del proveedor (columna "Modelo prov.")
// ===========================================================================
// Monta en runtime un ExtLookupComboBox in-cell (mismo patron probado en
// inLibGridArticulos) que, al teclear en "Modelo prov.", lista los modelos
// (REF_PROVEEDOR_AP) ya existentes del proveedor de la cabecera cuyo
// comienzo coincide. Al elegir uno, la linea se marca REUSAR del articulo:
// el sistema de tallas queda fijo y al materializar solo se incorporan los
// colores/tallas nuevos (los precios anteriores se proponen como referencia).
procedure TfrmMtoComprasSesiones.CrearLookupModelo;
begin
  // 1. Query con un modelo por fila: descripcion, sistema de tallas, colores
  //    ya dados de alta y ultimo precio de compra (referencia visible). El
  //    filtrado "empieza por" mientras tecleas lo hace IncrementalFiltering
  //    en cliente; :prv lo fija RecargarModelos.
  FModeloBusqQry := TUniQuery.Create(nil);
  FModeloBusqQry.Connection := inLibGlobalVar.oConn;
  FModeloBusqQry.SQL.Text :=
    'SELECT ap.REF_PROVEEDOR_AP AS REFPRV,' +
    '       ap.CODIGO_ART_AP    AS CODART,' +
    '       a.DESCRIPCION_ART   AS DESCRIPCION,' +
    '       ap.PRECIO_ULT_COMPRA_AP AS PCOMPRA,' +
    '       COALESCE((SELECT acn.NOMBRE_AC' +
    '                   FROM fza_articulos_conjuntos_asign aca' +
    '                   JOIN fza_atributos_conjuntos acn' +
    '                     ON acn.ID_AC = aca.ID_AC_ACA' +
    '                  WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART' +
    '                    AND aca.ID_VA_ACA = ''TAL''' +
    '                  ORDER BY aca.ID_VA_ACA LIMIT 1), '''') AS SISTEMA,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT av.AV ORDER BY av.AV' +
    '                                     SEPARATOR '', '')' +
    '                   FROM fza_articulos_skus sk' +
    '                   JOIN fza_atributos_sku sa' +
    '                     ON sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU' +
    '                   JOIN fza_atributos_valores av' +
    '                     ON av.ID_AV = sa.ID_AV_SA AND av.ID_VA_AV = ''CO''' +
    '                  WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '                    AND sk.ESACTIVO_SKU = ''S''), '''') AS COLORES' +
    '  FROM fza_articulos_proveedores ap' +
    '  JOIN fza_articulos a ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP' +
    '                       AND a.ESACTIVO_ART = ''S''' +
    ' WHERE ap.CODIGO_PRV_AP = :prv' +
    '   AND ap.REF_PROVEEDOR_AP IS NOT NULL' +
    '   AND ap.REF_PROVEEDOR_AP <> ''''' +
    ' GROUP BY ap.REF_PROVEEDOR_AP, ap.CODIGO_ART_AP, a.DESCRIPCION_ART,' +
    '          ap.PRECIO_ULT_COMPRA_AP' +
    ' ORDER BY ap.REF_PROVEEDOR_AP';
  FModeloBusqDs := TDataSource.Create(nil);
  FModeloBusqDs.DataSet := FModeloBusqQry;
  // 2. View del desplegable, en su propio repositorio (no en pantalla).
  FModeloRepo := TcxGridViewRepository.Create(nil);
  FModeloView := FModeloRepo.CreateItem(TcxGridDBTableView)
                   as TcxGridDBTableView;
  FModeloView.DataController.DataSource := FModeloBusqDs;
  FModeloView.DataController.KeyFieldNames := 'REFPRV';
  FModeloView.OptionsView.GroupByBox := False;
  FModeloView.OptionsSelection.CellSelect := False;
  FModeloView.OptionsBehavior.IncSearch := False;
  FModeloColRef := FModeloView.CreateColumn;
  FModeloColRef.Caption := 'Modelo';
  FModeloColRef.DataBinding.FieldName := 'REFPRV';
  FModeloColRef.Width := 130;
  FModeloColCodArt := FModeloView.CreateColumn;
  FModeloColCodArt.Caption := 'Codigo';
  FModeloColCodArt.DataBinding.FieldName := 'CODART';
  FModeloColCodArt.Width := 110;
  with FModeloView.CreateColumn do
  begin
    Caption := 'Descripcion';
    DataBinding.FieldName := 'DESCRIPCION';
    Width := 220;
  end;
  with FModeloView.CreateColumn do
  begin
    Caption := 'Tallas';
    DataBinding.FieldName := 'SISTEMA';
    Width := 110;
  end;
  with FModeloView.CreateColumn do
  begin
    Caption := 'Colores';
    DataBinding.FieldName := 'COLORES';
    Width := 180;
  end;
  with FModeloView.CreateColumn do
  begin
    Caption := 'Ult. compra';
    DataBinding.FieldName := 'PCOMPRA';
    Width := 80;
  end;
  // 3. Item de edicion ExtLookupComboBox que usa ese view.
  FModeloEditRepo := TcxEditRepository.Create(nil);
  FModeloCombo := FModeloEditRepo.CreateItem(
                    TcxEditRepositoryExtLookupComboBoxItem)
                    as TcxEditRepositoryExtLookupComboBoxItem;
  with FModeloCombo.Properties do
  begin
    View := FModeloView;
    KeyFieldNames := 'REFPRV';
    ListFieldItem := FModeloColRef;
    DropDownListStyle := lsEditList;     // permite teclear modelos nuevos
    IncrementalFiltering := True;        // por defecto filtra "empieza por"
    DropDownRows := 15;
    DropDownAutoWidth := True;
    // No abrir el desplegable en cada tecla: lo abre el debounce ya filtrado.
    ImmediateDropDownWhenKeyPressed := False;
    OnCloseUp := ModeloComboCloseUp;
  end;
  // 4. La columna "Modelo prov." usa el desplegable solo en celda vacia y
  //    enfocada; con valor escrito usa el editor de texto del dfm (que
  //    conserva el match exacto en OnEditValueChanged).
  dbcLinRefPrv.OnGetProperties := ModeloGetProperties;
  // 5. Timers: debounce para abrir el desplegable al teclear y resolucion
  //    diferida al elegir (no tocar el dataset mientras se cierra el editor).
  FModeloTimerBusq := TTimer.Create(nil);
  FModeloTimerBusq.Enabled := False;
  FModeloTimerBusq.Interval := 350;
  FModeloTimerBusq.OnTimer := ModeloTimerBusqTimer;
  FModeloTimerResolve := TTimer.Create(nil);
  FModeloTimerResolve.Enabled := False;
  FModeloTimerResolve.Interval := 1;
  FModeloTimerResolve.OnTimer := ModeloTimerResolveTimer;
  // Sentinela que no casa con ningun proveedor real: fuerza la 1a carga.
  FModeloPrvCargado := #1;
end;

// (Re)abre el query del desplegable acotado al proveedor de la cabecera.
// Solo relanza si cambia el proveedor (o aun no se habia abierto).
procedure TfrmMtoComprasSesiones.RecargarModelos;
var
  sPrv: string;
begin
  if FModeloBusqQry = nil then Exit;
  sPrv := '';
  if (Dmm <> nil) and (Dmm.unqryTablaG <> nil) and
     (not Dmm.unqryTablaG.IsEmpty) then
    sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  if (sPrv = FModeloPrvCargado) and FModeloBusqQry.Active then Exit;
  FModeloPrvCargado := sPrv;
  if FModeloBusqQry.Active then FModeloBusqQry.Close;
  FModeloBusqQry.ParamByName('prv').AsString := sPrv;
  FModeloBusqQry.Open;
end;

// Editor por celda: celda vacia y enfocada -> ExtLookupComboBox (busqueda
// incremental); en otro caso, el editor de texto por defecto de la columna.
procedure TfrmMtoComprasSesiones.ModeloGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vVal: Variant;
  bVacia, bEnfocada: Boolean;
begin
  if (ARecord = nil) or (FModeloCombo = nil) then Exit;
  vVal := ARecord.Values[Sender.Index];
  bVacia := VarIsNull(vVal) or (Trim(VarToStr(vVal)) = '');
  bEnfocada := (tvLineas.Controller.FocusedRecord = ARecord) and
               (tvLineas.Controller.FocusedItem = Sender);
  if bVacia and bEnfocada then
    AProperties := FModeloCombo.Properties;
end;

// OnChange del editor del combo: rearma el debounce que abre el desplegable
// filtrado por lo tecleado (se engancha en tvLineasInitEdit).
procedure TfrmMtoComprasSesiones.ModeloComboChange(Sender: TObject);
begin
  FModeloTimerBusq.Enabled := False;
  FModeloTimerBusq.Enabled := True;
end;

// Al saltar el debounce abre el desplegable ya filtrado por lo tecleado,
// como inLibGridArticulos.TimerBusqTimer.
procedure TfrmMtoComprasSesiones.ModeloTimerBusqTimer(Sender: TObject);
var
  Edit  : TcxCustomEdit;
  Combo : TcxExtLookupComboBox;
begin
  FModeloTimerBusq.Enabled := False;
  if not tvLineas.Controller.EditingController.IsEditing then Exit;
  Edit := tvLineas.Controller.EditingController.Edit;
  if not (Edit is TcxExtLookupComboBox) then Exit;
  Combo := TcxExtLookupComboBox(Edit);
  if (Trim(VarToStr(Combo.EditingValue)) <> '') and
     (not Combo.DroppedDown) then
    Combo.DroppedDown := True;
end;

// Al cerrar el desplegable con una eleccion: guardamos el modelo y diferimos
// la resolucion (timer 1ms) para no tocar el dataset mientras se cierra el
// editor in-place.
procedure TfrmMtoComprasSesiones.ModeloComboCloseUp(Sender: TObject);
var
  Rec : TcxCustomGridRecord;
begin
  if not (Sender is TcxCustomEdit) then
    Exit;
  FModeloRefPend := VarToStr(TcxCustomEdit(Sender).EditValue);
  FModeloCodArtPend := '';
  if (FModeloView <> nil) and (FModeloColCodArt <> nil) then
  begin
    Rec := FModeloView.Controller.FocusedRecord;
    if Rec <> nil then
      FModeloCodArtPend := VarToStr(
                            Rec.Values[FModeloColCodArt.Index]);
  end;
  if Trim(FModeloRefPend) <> '' then
  begin
    FModeloTimerResolve.Enabled := False;
    FModeloTimerResolve.Enabled := True;
  end;
end;

function TfrmMtoComprasSesiones.AplicarDuplicadoDeSesion(const AModelo,
  ACodigoArt: string): Boolean;
var
  rDup    : TResolverDuplicadoSesion;
  sSerie  : string;
  sNumero : string;
  iLinea  : Integer;
begin
  Result := False;
  if Dmm = nil then
    Exit;
  if Dmm.unqryTablaG.IsEmpty then
    Exit;
  if Dmm.unqrySesionLin.IsEmpty then
    Exit;
  sSerie := Trim(Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString);
  sNumero := Trim(Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString);
  iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  rDup := ResolverDuplicadoIntraSesion(inLibGlobalVar.oConn, sSerie, sNumero,
                                       iLinea, AModelo, ACodigoArt);
  if not rDup.Encontrado then
    Exit;
  if not (Dmm.unqrySesionLin.State in [dsEdit, dsInsert]) then
    Dmm.unqrySesionLin.Edit;
  AplicarDuplicadoEnLinea(Dmm, rDup);
  if rDup.IdAcPivot > 0 then
    Dmm.TallajeDefectoActual := rDup.IdAcPivot;
  if Assigned(FGestorTallas) then
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
  Result := True;
end;

// Resuelve el modelo elegido. El valor es un REF_PROVEEDOR existente del
// proveedor: ResolverDuplicadoSesion lo localiza por su rama REF y
// AplicarDuplicadoEnLinea marca la linea REUSAR + precarga descripcion,
// familia, sistema de tallas (fijo), coste y PVP de referencia. Si no casa
// (modelo nuevo tecleado a mano) se deja como linea normal (alta nueva).
procedure TfrmMtoComprasSesiones.ModeloTimerResolveTimer(Sender: TObject);
var
  sRef, sPrv : string;
  sCodArt    : string;
  rDup       : TResolverDuplicadoSesion;
  ds         : TDataSet;
begin
  FModeloTimerResolve.Enabled := False;
  sRef := Trim(FModeloRefPend);
  sCodArt := Trim(FModeloCodArtPend);
  FModeloRefPend := '';
  FModeloCodArtPend := '';
  if sRef = '' then
    Exit;
  if Dmm.unqryTablaG.IsEmpty then
    Exit;
  sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  if sPrv = '' then
    Exit;
  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then
    Exit;
  if AplicarDuplicadoDeSesion(sRef, sCodArt) then
  begin
    if tvLineas.Controller.EditingController.IsEditing then
      try
        tvLineas.Controller.EditingController.HideEdit(True);
      except
        on E: EInvalidOperation do
          ;
      end;
    Exit;
  end;
  rDup := ResolverDuplicadoSesion(inLibGlobalVar.oConn, sRef, sPrv,
                                  True, sCodArt);
  if not rDup.Encontrado then
    Exit;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  // El modelo tecleado se conserva como REF de la linea (rama REF no la toca).
  ds.FieldByName('REF_PRV_SESLIN').AsString := sRef;
  AplicarDuplicadoEnLinea(Dmm, rDup);
  if Assigned(FGestorTallas) then
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
  // Cierra el editor para que la celda muestre el modelo resuelto.
  if tvLineas.Controller.EditingController.IsEditing then
    try
      tvLineas.Controller.EditingController.HideEdit(True);
    except
      on E: EInvalidOperation do
        ;
    end;
end;

// Toda la logica reusable de tallas pivotadas (cache de conjuntos,
// maximo del documento, recalcular columnas, captions dinamicas,
// carga / persistencia de celdas, refresco de totales y validacion)
// vive ahora en inLibGridTallasInline.TGestorGridTallas — ver
// InicializarGestorTallas mas abajo. El form solo delega y mantiene
// la cabecera y los handlers especificos (familia, color, PVP).

// ===========================================================================
//   Lineas — alta, baja, navegacion
// ===========================================================================

procedure TfrmMtoComprasSesiones.btnAddLineaClick(Sender: TObject);
begin
  inherited;
  // BeforeInsert se encarga de preparar el master (Post si pendiente,
  // Edit si Browse, Abort si IsEmpty).
  LogSes('btnAddLineaClick: detail.Insert');
  Dmm.unqrySesionLin.Insert;
  LogSes(Format('btnAddLineaClick FIN. LINEA_SESLIN=%d',
                [Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
end;

procedure TfrmMtoComprasSesiones.btnDelLineaClick(Sender: TObject);
begin
  inherited;
  if Dmm.unqrySesionLin.IsEmpty then
  begin
    LogSes('btnDelLineaClick: detail vacio, salida');
    Exit;
  end;
  if MessageDlg('Borrar la linea seleccionada?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    LogSes('btnDelLineaClick: cancelado por el usuario');
    Exit;
  end;
  LogSes(Format('btnDelLineaClick: linea=%d',
                [Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
  // BeforeDelete limpia SESCEL, AfterDelete recalcula columnas y totales
  Dmm.unqrySesionLin.Delete;
  LogSes('btnDelLineaClick FIN');
end;

procedure TfrmMtoComprasSesiones.btnFotoClick(Sender: TObject);
var
  sSerie, sNumero, sCodArt: string;
  iLinea: Integer;
  info  : TFotoInfo;
begin
  inherited;
  // Sube una foto y la asocia a la linea activa de la sesion (a nivel
  // articulo padre — CODIGO_UNIDAD = ''). Ctrl+F + frmFotoArticulo
  // muestra la foto estandar del articulo de la linea (si existe en
  // fza_articulos_fotos). Al materializar, MigrarFotosSesion pasa esta
  // foto de sesion a fza_articulos_fotos.
  if Dmm.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay sesion activa.');
    Exit;
  end;
  if Dmm.unqrySesionLin.IsEmpty then
  begin
    ShowMessage('Selecciona o crea una linea antes de asignar foto.');
    Exit;
  end;
  if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
    Dmm.unqryTablaG.Post;
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;

  sSerie  := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  iLinea  := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  sCodArt := Dmm.unqrySesionLin.FieldByName(
                                  'CODIGO_ART_TENTATIVO_SESLIN').AsString;

  if not Assigned(dlgFoto) then
    dlgFoto := TOpenDialog.Create(Self);
  dlgFoto.Filter := 'Imagenes (*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp)|' +
                    '*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp';
  dlgFoto.Options := dlgFoto.Options + [ofFileMustExist];
  if not dlgFoto.Execute then Exit;

  try
    info := inLibFotos.oFotos.GuardarSesion(sSerie, sNumero, iLinea,
                                            sCodArt, '', dlgFoto.FileName);
    if info.Encontrada then
      ShowMessage('Foto asignada a la linea ' + IntToStr(iLinea) + '.')
    else
      ShowMessage('No se pudo asignar la foto.');
  except
    on E: Exception do
      ShowMessage('Error guardando foto: ' + E.Message);
  end;
end;

procedure TfrmMtoComprasSesiones.btnCrearClick(Sender: TObject);
var
  bOK    : Boolean;
  sSerPed, sNumPed, sSerAlb, sNumAlb, sErr: string;
  incidencias : TStringList;
  frmInc      : TfrmModalIncidencias;
  frmSet      : TfrmModalCrearAlbaranSesion;
  iAutoFix    : Integer;
  iIdPvTemp   : Integer;
  oListaDocs  : TStringList;
  frmDocs     : TfrmModalDocsCreados;
  i           : Integer;
  sLin        : string;
  arrPart     : TArray<string>;
begin
  inherited;
  // Flujo:
  //   1. Postear cualquier edicion en curso.
  //   2. ValidarSesionDetallado: si hay incidencias, mostrar modal con la
  //      lista y abortar.
  //   3. Modal de settings (serie / fecha / almacen / tarifa / temporada
  //      / flags). Si Salir, abortar.
  //   4. MaterializarSesion con los settings elegidos.
  LogSes('btnCrearClick INICIO');
  if Dmm.unqryTablaG.IsEmpty then
  begin
    LogSes('  cabecera vacia, salida');
    ShowMessage('No hay sesion activa.');
    Exit;
  end;
  LogSes(Format('  sesion=%s/%s, estado=%s, lineas master.CONTADOR=%d',
                [Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
                 Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString,
                 Dmm.unqryTablaG.FieldByName('ESTADO_SES').AsString,
                 Dmm.unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger]));
  if Dmm.unqryTablaG.FieldByName('ESTADO_SES').AsString = 'CERRADA' then
  begin
    LogSes('  sesion ya CERRADA, abortar');
    ShowMessage('La sesion ya esta cerrada. No se puede materializar dos ' +
                'veces.');
    Exit;
  end;
  if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
  begin
    LogSes('  master.Post pendiente');
    Dmm.unqryTablaG.Post;
  end;
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
  begin
    LogSes('  detail.Post pendiente');
    Dmm.unqrySesionLin.Post;
  end;

  // ---- 1b. Normalizar duplicados intra-sesion ----
  // Si hay varias lineas con el mismo CODIGO_ART_TENTATIVO_SESLIN sin
  // resolver, la materializacion reventaria con Duplicate entry en
  // fza_articulos (PK CODIGO_ART_ART). Las marcamos automaticamente
  // como REUSAR (la primera por LINEA crea el articulo, las demas son
  // variantes — color/SKU — del mismo articulo). El boton "+ color
  // (mismo articulo)" ya lo deja marcado desde su creacion; esto es
  // para sesiones que ya tenian duplicados sin marcar.
  iAutoFix := NormalizarDuplicadosIntraSesion(
                inLibGlobalVar.oConn, oUser,
                Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
                Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString);
  if iAutoFix > 0 then
  begin
    LogSes(Format('  NormalizarDuplicadosIntraSesion: %d linea(s) marcadas REUSAR',
                  [iAutoFix]));
    ShowMessage(Format(
      'Se han detectado y marcado %d linea(s) como REUSAR de codigos ' +
      'repetidos dentro de esta sesion (variantes color/SKU del mismo ' +
      'articulo). La materializacion crea el articulo una sola vez.',
      [iAutoFix]));
    Dmm.unqrySesionLin.Refresh;
  end;

  // ---- 2. Validador detallado ----
  LogSes('  ValidarSesionDetallado');
  incidencias := TStringList.Create;
  try
    if not ValidarSesionDetallado(Dmm, incidencias) then
    begin
      frmInc := TfrmModalIncidencias.Create(Self);
      try
        frmInc.SetIncidencias(
          'Hay incidencias que impiden materializar la sesion:', incidencias);
        frmInc.ShowModal;
      finally
        // FormClose pone Action := caFree, no liberamos a mano.
      end;
      Exit;
    end;
  finally
    FreeAndNil(incidencias);
  end;

  // ---- 3. Modal de settings ----
  iIdPvTemp := 0;
  if not Dmm.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').IsNull then
    iIdPvTemp :=
      Dmm.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').AsInteger;

  frmSet := TfrmModalCrearAlbaranSesion.Create(Self);
  try
    frmSet.ConfigurarLookups(Dmm.dsAlmacenes, Dmm.dsTarifas,
                              Dmm.dsTemporadas);
    // Combos de serie: todas las series de la empresa por tipo de
    // documento. El modal propone la serie que lleve el almacen
    // elegido (CODIGO_ALM_EMPSER) y re-propone al cambiar de almacen.
    frmSet.CargarSeries(
      Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
    // Series por defecto (fallback si el almacen no lleva serie propia
    // ni la empresa una generica): buscar en Empresas->Series por tipo
    var sSerieAlbDef := ObtenerSerieDefecto(
          Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString, 'AB');
    if sSerieAlbDef = '' then
      sSerieAlbDef := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    var sSeriePedDef := ObtenerSerieDefecto(
          Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString, 'PC');
    if sSeriePedDef = '' then
      sSeriePedDef := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    frmSet.SetDefecto(
      sSerieAlbDef,
      sSeriePedDef,
      Date,
      Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString,
      Dmm.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString,
      iIdPvTemp,
      Dmm.unqryTablaG.FieldByName('ESGENERA_PEDIDO_SES').AsString = 'S',
      // Por defecto generamos albaran si la cabecera trae almacen
      // (escenario tipico de muestrarios).
      (Dmm.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S')
        or (Trim(Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString)
            <> ''),
      Dmm.unqryTablaG.FieldByName('REF_PRV_SES').AsString);
    // Mostrar la opcion 'agrupar / un doc por almacen' solo cuando la
    // cabecera tenga el formato distribuido activo. En modo clasico no
    // tiene sentido — solo hay un almacen efectivo.
    frmSet.MostrarOpcionAgrupacion(
      Dmm.unqryTablaG.FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
    frmSet.ShowModal;
    if not frmSet.Confirmado then Exit;

    // Aplicar a la cabecera los settings elegidos para que la
    // materializacion los vea: almacen, tarifa, temporada, flags. Las
    // series elegidas (albaran / pedido) viajan como parametros a
    // MaterializarSesion, no se persisten en la cabecera porque pueden
    // ser distintas en cada materializacion.
    Dmm.unqryTablaG.Edit;
    Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString := frmSet.Almacen;
    Dmm.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString := frmSet.Tarifa;
    if frmSet.Temporada > 0 then
      Dmm.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').AsInteger :=
                                                          frmSet.Temporada
    else
      Dmm.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').Clear;
    Dmm.unqryTablaG.FieldByName('ESGENERA_PEDIDO_SES').AsString :=
                            IfThen(frmSet.GenPedido, 'S', 'N');
    Dmm.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString :=
                            IfThen(frmSet.GenAlbaran, 'S', 'N');
    // Ref. del documento del proveedor: viaja a REF_PROVEEDOR_ALBC en la
    // cabecera del albaran (via InsertarAlbaranCompraCabecera, que ya lee
    // S.REF_PRV_SES). Lo persistimos antes de materializar.
    Dmm.unqryTablaG.FieldByName('REF_PRV_SES').AsString := frmSet.RefPrv;
    Dmm.unqryTablaG.Post;
  finally
    // FormClose libera el modal
  end;

  // ---- 4. Materializar ----
  LogSes(Format('  MaterializarSesion(genPed=%s, genAlb=%s, serieAlb=%s, seriePed=%s)',
                [Dmm.unqryTablaG.FieldByName('ESGENERA_PEDIDO_SES').AsString,
                 Dmm.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString,
                 frmSet.SerieAlb, frmSet.SeriePed]));
  oListaDocs := TStringList.Create;
  try
    Screen.Cursor := crHourGlass;
    try
      bOK := MaterializarSesionConTx(frmSet, oUser, oListaDocs,
                                     sSerPed, sNumPed,
                                     sSerAlb, sNumAlb, sErr);
    finally
      Screen.Cursor := crDefault;
    end;
    LogSes(Format('  MaterializarSesion -> bOK=%s, pedido=%s/%s, albaran=%s/%s, err=%s',
                  [BoolToStr(bOK, True), sSerPed, sNumPed, sSerAlb, sNumAlb, sErr]));
    if bOK then
    begin
      LogSes('  master.Refresh');
      Dmm.unqryTablaG.Refresh;
      if Dmm.unqrySesDocs.Active then
        Dmm.unqrySesDocs.Refresh
      else
        Dmm.unqrySesDocs.Open;
      // Mostrar todos los docs creados con boton "Ir a documento". En
      // modo distribuido salen N albaranes (uno por almacen); en modo
      // clasico solo uno. Sin docs (caso 'sin albaran ni pedido') no
      // abrimos modal: simple ShowMessage.
      if oListaDocs.Count = 0 then
        ShowMessage('Sesion materializada (sin documentos).')
      else
      begin
        frmDocs := TfrmModalDocsCreados.Create(Self);
        // Bloqueamos caFree del ancestro para liberarlo nosotros aqui.
        frmDocs.OnClose := nil;
        try
          for i := 0 to oListaDocs.Count - 1 do
          begin
            sLin := oListaDocs[i];
            arrPart := sLin.Split(['|']);
            if Length(arrPart) = 4 then
              frmDocs.Agregar(arrPart[0], arrPart[1], arrPart[2], arrPart[3]);
          end;
          frmDocs.ShowModal;
          if frmDocs.Confirmado then
          begin
            // Tanto Albaran como Pedido tienen Mto propio. BuscarTabla
            // en inLibShowMto soporta PK compuesta separada por coma.
            if SameText(frmDocs.SeleccionadoTipo, 'Albaran') then
              ShowMto(frmMtoPrincipal, 'AlbaranesCompra',
                      frmDocs.SeleccionadoSerie + ',' +
                      frmDocs.SeleccionadoNumero)
            else if SameText(frmDocs.SeleccionadoTipo, 'Pedido') then
              ShowMto(frmMtoPrincipal, 'PedidosCompra',
                      frmDocs.SeleccionadoSerie + ',' +
                      frmDocs.SeleccionadoNumero);
          end;
        finally
          FreeAndNil(frmDocs);
        end;
      end;
    end
    else
    begin
      // Mostrar el error de materializacion tambien en modal de
      // incidencias para que se vea bien aunque sea largo.
      incidencias := TStringList.Create;
      try
        incidencias.Add('[MATERIALIZAR] ' + sErr);
        frmInc := TfrmModalIncidencias.Create(Self);
        frmInc.SetIncidencias(
          'No se pudo materializar la sesion:', incidencias);
        frmInc.ShowModal;
      finally
        FreeAndNil(incidencias);
      end;
    end;
  finally
    FreeAndNil(oListaDocs);
  end;
  LogSes('btnCrearClick FIN');
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
    ShowMessage('No hay sesion activa.');
    Exit;
  end;
  if Dmm.unqryTablaG.FieldByName('ESTADO_SES').AsString <> 'CERRADA' then
  begin
    LogSes('  sesion no esta CERRADA, abortar');
    ShowMessage('La sesion no esta CERRADA. Solo se pueden revertir ' +
                'sesiones materializadas.');
    Exit;
  end;
  if MessageDlg('Se borraran los movimientos de almacen creados por esta ' +
                'sesion y volvera a BORRADOR.' + sLineBreak + sLineBreak +
                'Los articulos / SKUs / codigos de barras se conservan ' +
                '(re-materializar es idempotente).' + sLineBreak +
                sLineBreak + 'Continuar?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    LogSes('  cancelado por el usuario');
    Exit;
  end;

  LogSes('  RevertirMaterializacion');
  Screen.Cursor := crHourGlass;
  try
    if RevertirMaterializacion(Dmm, oUser, sErr) then
    begin
      LogSes('  reversion OK, master.Refresh');
      ShowMessage('Sesion revertida. Estado: BORRADOR.');
      Dmm.unqryTablaG.Refresh;
    end
    else
    begin
      LogSes('  reversion KO: ' + sErr);
      ShowMessage('No se pudo revertir la sesion:' + sLineBreak + sErr);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  LogSes('btnRevertirClick FIN');
end;

procedure TfrmMtoComprasSesiones.btnImprimirClick(Sender: TObject);
var
  form     : TfrmPrintSesion;
  sSerie   : string;
  sNumero  : string;
begin
  inherited;
  if Dmm.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay sesion activa que imprimir.');
    Exit;
  end;
  // Persistir cualquier edicion pendiente para que el report vea los
  // ultimos cambios (los TfrxDBDataset leen directamente de las vistas SQL).
  if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
    Dmm.unqryTablaG.Post;
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;

  sSerie  := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  form := TfrmPrintSesion.Create(Application);
  try
    form.dmSesion       := Dmm;
    form.edtSerie.Text  := sSerie;
    form.edtNumero.Text := sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoComprasSesiones.btnNuevoColorClick(Sender: TObject);
var
  ds                 : TDataSet;
  sFam, sCodArt      : string;
  sRefPrv, sDescr    : string;
  rPrCompra, rPrVenta: Double;
  iAcPivot           : Integer;
  rMargen            : Double;
  sTipoIva           : string;
  iSrcLinea, iNewLinea, iSiguiente : Integer;
  cantidades         : TArray<Double>;
  i, iSrcIdx         : Integer;
  arr                : TArrPosConjunto;
  v                  : Variant;
  q                  : TUniQuery;
begin
  inherited;
  // Duplica la linea activa con todos los datos comerciales (codigo,
  // familia, modelo prov., descripcion, precios, sistema de tallas) y
  // sus cantidades por talla, dejando vacios COLOR_TEXTO_SESLIN y
  // CODIGO_ATB_COLOR_SESLIN. Util cuando el cliente compra el mismo
  // articulo en varios colores: clic, cambias color, terminas.
  if FGestorTallas = nil then Exit;
  ds := Dmm.unqrySesionLin;
  if (ds = nil) or ds.IsEmpty then Exit;
  if Dmm.unqryTablaG.IsEmpty then Exit;

  // 1. Snapshot de los campos de la linea origen (incluido el record
  //    idx del cxGrid antes de mover nada).
  iSrcIdx    := tvLineas.Controller.FocusedRecordIndex;
  iSrcLinea  := ds.FieldByName('LINEA_SESLIN').AsInteger;
  sFam       := ds.FieldByName('CODIGO_FAM_SESLIN').AsString;
  sCodArt    := ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
  sRefPrv    := ds.FieldByName('REF_PRV_SESLIN').AsString;
  sDescr     := ds.FieldByName('DESCRIPCION_SESLIN').AsString;
  rPrCompra  := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  rPrVenta   := ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
  iAcPivot   := ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  rMargen    := ds.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  sTipoIva   := ds.FieldByName('TIPO_IVA_SESLIN').AsString;

  // 1b. Buscar la siguiente linea (LINEA_SESLIN minimo > origen). Si
  //     existe y hay hueco (>1), la nueva linea ira con el LINEA
  //     intermedio para quedar justo a continuacion en el grid (que
  //     ordena por LINEA). Si la origen es la ultima, dejamos el
  //     LINEA por defecto del AfterInsert (CONTADOR+10).
  iSiguiente := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT MIN(LINEA_SESLIN) AS SIGUIENTE ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN > :l';
    q.ParamByName('s').AsString  :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := iSrcLinea;
    q.Open;
    if not q.FieldByName('SIGUIENTE').IsNull then
      iSiguiente := q.FieldByName('SIGUIENTE').AsInteger;
  finally
    FreeAndNil(q);
  end;

  // 2. Snapshot de cantidades por talla desde Values[] del cxGrid.
  SetLength(cantidades, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    cantidades[i] := 0;
    if FTallaColumns[i] = nil then Continue;
    if iSrcIdx < 0 then Continue;
    v := tvLineas.DataController.Values[iSrcIdx, FTallaColumns[i].Index];
    if (not VarIsNull(v)) and (not VarIsEmpty(v)) and VarIsNumeric(v) then
      cantidades[i] := v;
  end;

  // 3. Postear lo en edicion antes del Insert (mismo patron que
  //    btnAddLineaClick para no romper el master-detail).
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
  if ds.State in [dsEdit, dsInsert] then ds.Post;
  Dmm.unqryTablaG.Edit;

  // 4. Insert + asignacion de campos copiados (excepto color).
  ds.Insert;
  ds.FieldByName('CODIGO_FAM_SESLIN').AsString          := sFam;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := sCodArt;
  ds.FieldByName('REF_PRV_SESLIN').AsString             := sRefPrv;
  ds.FieldByName('DESCRIPCION_SESLIN').AsString         := sDescr;
  ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat        := rPrCompra;
  ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat         := rPrVenta;
  if iAcPivot > 0 then
    ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := iAcPivot;
  if rMargen > 0 then
    ds.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat := rMargen;
  if sTipoIva <> '' then
    ds.FieldByName('TIPO_IVA_SESLIN').AsString := sTipoIva;
  // Color y color basico se quedan vacios — los rellena el usuario.
  ds.FieldByName('COLOR_TEXTO_SESLIN').Clear;
  ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
  // Marcar como duplicado intra-sesion para que la materializacion no
  // intente INSERT del articulo dos veces (la linea origen crea
  // CODIGO_ART_ART; esta variante - mismo codigo, distinto color/SKU -
  // lo REUSA). Sin este marcado, ambas lineas irian a InsertarArticulo
  // y la segunda fallaria con 'Duplicate entry' en fza_articulos.
  ds.FieldByName('ESDUPLICADO_SESLIN').AsString       := 'S';
  ds.FieldByName('ACCION_DUPLICADO_SESLIN').AsString  := 'REUSAR';
  ds.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString := sCodArt;
  // Sobreescribir LINEA_SESLIN si hay hueco para colocarse justo
  // detras de la origen (mantener cohesion visual entre las variantes
  // de color del mismo articulo).
  if (iSiguiente > 0) and ((iSiguiente - iSrcLinea) > 1) then
    ds.FieldByName('LINEA_SESLIN').AsInteger :=
      (iSrcLinea + iSiguiente) div 2;
  // (si la origen es la ultima, mantenemos el LINEA secuencial que
  //  asigno el AfterInsert del DM — CONTADOR_LINEAS_SES + 10).
  ds.Post;
  iNewLinea := ds.FieldByName('LINEA_SESLIN').AsInteger;

  // 5. Persistir cantidades para la nueva linea (mismo conjunto pivot).
  //    En modo distribuido copiamos celda a celda preservando
  //    CODIGO_ALM_SESCEL — el cuadrante almacen x talla del proveedor
  //    se conserva. En modo clasico usamos los Values[] del grid
  //    (que YA llevan el agregado correcto, una sola celda con
  //    almacen vacio = el de cabecera).
  if Dmm.unqryTablaG.FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString = 'S' then
  begin
    CopiarCeldasDistribuidasOtroColor(iSrcLinea, iNewLinea);
    // El INSERT-SELECT y el UPDATE de totales viven fuera del cds —
    // refrescamos para que el grid principal vea los TOTAL_UNIDADES /
    // TOTAL_LINEA actualizados de la nueva linea (sin refresh, el cds
    // mantiene los valores de su Insert + Post iniciales, ambos 0).
    ds.Refresh;
    ds.Locate('LINEA_SESLIN', iNewLinea, []);
  end
  else if iAcPivot > 0 then
  begin
    arr := FGestorTallas.GetPosicionesConjunto(iAcPivot);
    for i := 0 to High(arr) do
      if (i <= High(cantidades)) and (cantidades[i] > 0) then
        FGestorTallas.PersistirCantidad(iNewLinea, arr[i].IdAv, cantidades[i]);
  end;
  if Assigned(FGestorTallas) then
    FGestorTallas.RefrescarTotalesLineaActual;
  if Assigned(Dmm) then
    Dmm.RefrescarTotalesSesion;

  // 6. Refrescar Values[] de TODAS las lineas (incluida la nueva).
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.CargarCantidadesTodasLineas;

  // 7. Foco en la celda Color de la nueva linea.
  if ds.Locate('LINEA_SESLIN', iNewLinea, []) then
    tvLineas.Controller.FocusedRecordIndex := ds.RecNo - 1;
  tvLineas.Controller.FocusedColumn := dbcLinColor;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

// 1. Declaramos la clase cracker para acceder al popup interno

function TfrmMtoComprasSesiones.TextoBusquedaTallaje(Key: Word;
  Shift: TShiftState): string;
begin
  Result := '';
  if not ((ssCtrl in Shift) or (ssAlt in Shift)) then
  begin
    if (Key >= Ord('A')) and (Key <= Ord('Z')) then
      Result := Chr(Key)
    else if (Key >= Ord('0')) and (Key <= Ord('9')) then
      Result := Chr(Key)
    else if (Key >= VK_NUMPAD0) and (Key <= VK_NUMPAD9) then
      Result := Chr(Ord('0') + Key - VK_NUMPAD0)
    else if Key = VK_SPACE then
      Result := ' ';
  end;
end;

procedure TfrmMtoComprasSesiones.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  frmSel : TfrmModalSelFamilia;
  props  : TcxButtonEditProperties;
  sBusq  : string;
begin
  inherited;
  sBusq := TextoBusquedaTallaje(Key, Shift);
  if (AItem = dbcLinTallas) and (sBusq <> '') then
  begin
    AbrirSelectorTallas(AEdit, sBusq);
    Key := 0;
  end
  // Ctrl+Enter sobre cualquier columna 'editbutton' (color basico,
  // sistema tallas, ...) dispara el click de su primer boton, igual que
  // pulsar el ellipsis '...'. Generico: invoca el OnButtonClick cableado
  // en esa columna pasando AEdit (el editor en edicion) como Sender.
  // Normalmente lo atrapa antes el KeyDown del form (KeyPreview); esto es
  // la red por si la pulsacion llega ya dentro del editor inline.
  else if (Key = VK_RETURN) and (Shift = [ssCtrl]) and
          (AItem is TcxGridDBColumn) and
          (TcxGridDBColumn(AItem).Properties is TcxButtonEditProperties) then
  begin
    props := TcxButtonEditProperties(TcxGridDBColumn(AItem).Properties);
    if (props.Buttons.Count > 0) and Assigned(props.OnButtonClick) then
    begin
      props.OnButtonClick(AEdit, 0);
      Key := 0;
    end;
  end
  // F3 sobre Familia / Codigo articulo abre el picker jerarquico de familia.
  else if (Key = VK_F3) and (Shift = []) and
          ((AItem = dbcLinFamilia) or (AItem = dbcLinCodArt)) then
  begin
    frmSel := TfrmModalSelFamilia.Create(Self);
    try
      if frmSel.ShowModal = mrOk then
        ExpandirCodigoFamiliaActiva(frmSel.CodigoFamilia, frmSel.NombreFamilia);
    finally
      FreeAndNil(frmSel);
    end;
    Key := 0;
  end;
end;

function TfrmMtoComprasSesiones.DispararEditButtonLineaActiva: Boolean;
var
  ac     : TWinControl;
  enGrid : Boolean;
  col    : TcxGridColumn;
  props  : TcxButtonEditProperties;
  ed     : TcxCustomEdit;
begin
  Result := False;
  // Solo actuamos si el foco esta dentro del grid de lineas (la celda o
  // su editor inline). Asi Ctrl+Enter en la cabecera u otra pestania no
  // dispara nada y sigue su curso normal. Usamos Screen.ActiveControl
  // (foco real a nivel aplicacion) para que funcione tambien con el Mto
  // embebido.
  ac     := Screen.ActiveControl;
  enGrid := (ac <> nil) and
            ((ac = cxgrdLineas) or cxgrdLineas.ContainsControl(ac));
  if enGrid then
    col := tvLineas.Controller.FocusedColumn
  else
    col := nil;
  if (col <> nil) and (col.Properties is TcxButtonEditProperties) then
  begin
    props := TcxButtonEditProperties(col.Properties);
    if (props.Buttons.Count > 0) and Assigned(props.OnButtonClick) then
    begin
      // Garantizar editor activo en la celda para posicionar el popup
      // justo debajo (si la celda estaba solo enfocada, ShowEdit lo crea).
      ed := nil;
      if tvLineas.Controller.EditingController <> nil then
      begin
        tvLineas.Controller.EditingController.ShowEdit;
        ed := tvLineas.Controller.EditingController.Edit;
      end;
      props.OnButtonClick(ed, 0);
      Result := True;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.KeyDown(var Key: Word; Shift: TShiftState);
var
  ac     : TWinControl;
  col    : TcxGridColumn;
  ed     : TcxCustomEdit;
  enGrid : Boolean;
  sBusq  : string;
begin
  ac     := Screen.ActiveControl;
  enGrid := (ac <> nil) and
            ((ac = cxgrdLineas) or cxgrdLineas.ContainsControl(ac));
  if enGrid then
    col := tvLineas.Controller.FocusedColumn
  else
    col := nil;
  sBusq := TextoBusquedaTallaje(Key, Shift);
  if (sBusq <> '') and (col = dbcLinTallas) then
  begin
    ed := nil;
    if tvLineas.Controller.EditingController <> nil then
    begin
      tvLineas.Controller.EditingController.ShowEdit;
      ed := tvLineas.Controller.EditingController.Edit;
    end;
    if ed <> nil then
      AbrirSelectorTallas(ed, sBusq)
    else
      AbrirSelectorTallas(ac, sBusq);
    Key := 0;
  end
  // Ctrl+Enter sobre una columna editbutton del grid de lineas abre su
  // selector (paleta de color / sistema tallas / ...), igual que pulsar
  // el ellipsis. Con KeyPreview heredado=True este KeyDown corre antes
  // que la navegacion Enter->Tab del grid y que el FormKeyDown base, que
  // si no sacarian el foco a la pestania Documentos. Solo lo consumimos
  // cuando de verdad se ha disparado el selector.
  else if (Key = VK_RETURN) and (Shift = [ssCtrl]) and
          DispararEditButtonLineaActiva then
    Key := 0
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmMtoComprasSesiones.AbrirSelectorTallas(Sender: TObject;
  const ABusquedaInicial: string);
var
  ds       : TDataSet;
  Edit     : TWinControl;
  ScrPt    : TPoint;
  WidHint  : Integer;
  IdActual : Integer;
  IdNuevo  : Integer;
begin
  // Mismo patron que el selector de color basico: el ellipsis abre un
  // listbox owner-drawn sin marco (SeleccionarConjuntoTalla) con las tres
  // columnas Sistema / Desde / Hasta. Sustituye al antiguo
  // TcxLookupComboBox (que daba guerra con Enter/Tab/auto-dropdown dentro
  // del grid). Un click selecciona y cierra; Esc o click fuera cancelan.
  if Length(FOpcionesTallas) = 0 then
  begin
    MessageDlg('No hay sistemas de tallas activos en ' +
               'fza_atributos_conjuntos (ID_VA_AC=''TAL'').',
               mtInformation, [mbOk], 0);
    Exit;
  end;
  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  // Al reusar un modelo ya existente el sistema de tallas queda fijado al
  // del articulo: cambiarlo descuadraria los SKUs ya creados. Solo se
  // permite anadir colores o tallas nuevos sobre ese mismo sistema.
  if SameText(ds.FieldByName('ACCION_DUPLICADO_SESLIN').AsString, 'REUSAR') then
  begin
    MessageDlg('El sistema de tallas no se puede cambiar en un modelo que ' +
               'ya existe: queda fijado al del articulo. Solo puedes anadir ' +
               'colores o tallas nuevos.', mtInformation, [mbOk], 0);
    Exit;
  end;
  IdActual := ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  // Posicionar el popup justo debajo del editor (igual que color basico).
  ScrPt.X := -1;
  ScrPt.Y := -1;
  WidHint := 380;
  if Sender is TWinControl then
  begin
    Edit    := TWinControl(Sender);
    ScrPt   := Edit.ClientToScreen(Point(0, Edit.Height));
    WidHint := Edit.Width;
    if WidHint < 380 then WidHint := 380;
  end;
  if not SeleccionarConjuntoTalla(FOpcionesTallas, IdActual, IdNuevo,
                                  ScrPt.X, ScrPt.Y, WidHint,
                                  ABusquedaInicial) then
    Exit;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := IdNuevo;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).EditValue := IdNuevo;
  // El usuario acaba de elegir el sistema de tallas a mano en esta linea:
  // pasa a ser el defecto del DOCUMENTO (no el del proveedor) para la
  // proxima linea nueva que se anada.
  if Assigned(Dmm) then Dmm.TallajeDefectoActual := IdNuevo;
  // Validar contra el maximo de columnas inline. Si el conjunto excede
  // CANT_TALLAS_MAX, el gestor avisa y limpia el campo; reflejamos el
  // borrado en el editor. Si es valido, recolocar columnas y captions.
  if Assigned(FGestorTallas) then
  begin
    if FGestorTallas.ValidarSistemaSeleccionado then
    begin
      FGestorTallas.RecalcularMaxColumnas;
      FGestorTallas.ActualizarCaptionsLineaActiva;
    end
    else if Sender is TcxCustomEdit then
      TcxCustomEdit(Sender).EditValue := Null;
  end;
end;

procedure TfrmMtoComprasSesiones.dbcLinTallasPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  AbrirSelectorTallas(Sender, '');
end;

procedure TfrmMtoComprasSesiones.btnArbolFamiliasClick(Sender: TObject);
var
  frmSel : TfrmModalSelFamilia;
begin
  inherited;
  // Mismo modal jerarquico que F3 sobre la columna Familia. Operamos sobre
  // la linea con foco; si no hay (sesion sin lineas) avisamos.
  if Dmm.unqrySesionLin.IsEmpty then
  begin
    MessageDlg('Anade una linea (o ponte sobre una) para asignarle familia.',
               mtInformation, [mbOk], 0);
    Exit;
  end;
  frmSel := TfrmModalSelFamilia.Create(Self);
  try
    if frmSel.ShowModal = mrOk then
      ExpandirCodigoFamiliaActiva(frmSel.CodigoFamilia, frmSel.NombreFamilia);
  finally
    FreeAndNil(frmSel);
  end;
end;

procedure TfrmMtoComprasSesiones.dbcLinFamiliaPropertiesEditValueChanged(
  Sender: TObject);
var
  ed       : TcxCustomEdit;
  sNuevo   : string;
  sTent    : string;
  sPrv     : string;
  rDup     : TResolverDuplicadoSesion;
begin
  inherited;
  if not (Sender is TcxCustomEdit) then
    Exit;
  ed := TcxCustomEdit(Sender);
  ed.PostEditValue;

  sNuevo := Trim(Dmm.unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString);
  if sNuevo = '' then Exit;

  // 1. Reusar datos de otra linea del mismo documento.
  if AplicarDuplicadoDeSesion('', sNuevo) then
    Exit;

  // 2. Reusar articulo existente: si lo tecleado coincide con un
  //    CODIGO_ART_ART, marcamos REUSAR y prerellenamos descripcion,
  //    familia, sistema de tallas, color base y coste sugerido. Asi el
  //    usuario solo tiene que poner el color nuevo y las cantidades.
  sPrv := '';
  if not Dmm.unqryTablaG.IsEmpty then
    sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  rDup := ResolverDuplicadoSesion(inLibGlobalVar.oConn, sNuevo, sPrv);
  if rDup.Encontrado then
  begin
    AplicarDuplicadoEnLinea(Dmm, rDup);
    if Assigned(FGestorTallas) then
    begin
      FGestorTallas.RecalcularMaxColumnas;
      FGestorTallas.ActualizarCaptionsLineaActiva;
    end;
    Exit;
  end;

  // 3. Si no es un CODIGO_ART existente, probar como CODIGO_FAM:
  //    ResolverCodigoFamilia genera CODIGO_FAM+RELLENO si la familia
  //    tiene contador activo. Salvaguarda: si ya hay un codigo
  //    tentativo expandido para la misma familia (p.ej. 'BOLSOS00001'
  //    cuando sNuevo='BOLSOS'), no consumimos otro contador.
  sTent  := Dmm.unqrySesionLin.FieldByName(
                                    'CODIGO_ART_TENTATIVO_SESLIN').AsString;
  if (sTent <> '') and (Length(sTent) > Length(sNuevo))
     and SameText(Copy(sTent, 1, Length(sNuevo)), sNuevo) then
    Exit; // ya parece expandido para la familia actual
  ExpandirCodigoFamiliaActiva(sNuevo);
end;

procedure TfrmMtoComprasSesiones.dbcLinCodArtPropertiesEditValueChanged(
  Sender: TObject);
var
  ed         : TcxCustomEdit;
  sTecleado  : string;
  sExpandido : string;
  ds         : TDataSet;
  q          : TUniQuery;
  sNombre    : string;
begin
  inherited;
  // Permitimos teclear el codigo directamente en la celda 'Cod. articulo'.
  // Si lo tecleado coincide con una familia con contador activo, se expande
  // a FAMILIA+RELLENO igual que cuando se teclea en la columna Familia
  // (p. ej. '0101' con contador 3 -> '0101003'). Si no es familia, se queda
  // tal cual (codigo manual) y no se toca CODIGO_FAM_SESLIN.
  if not (Sender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(Sender);
  ed.PostEditValue;

  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  sTecleado := Trim(ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString);
  if sTecleado = '' then Exit;

  if AplicarDuplicadoDeSesion('', sTecleado) then
    Exit;

  // ResolverCodigoFamilia incrementa el contador como efecto colateral si
  // resuelve: solo se llama una vez por edicion de celda. Si devuelve False
  // no consume nada y dejamos el codigo manual sin tocar.
  if not ResolverCodigoFamilia(inLibGlobalVar.oConn, sTecleado, oUser,
                               sExpandido) then Exit;

  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('CODIGO_FAM_SESLIN').AsString          := sTecleado;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := sExpandido;
  ed.EditValue := sExpandido;

  // Pre-rellenar descripcion con NOMBRE_FAM_FAM si esta vacia (mismo
  // comportamiento que ExpandirCodigoFamiliaActiva por simetria con F3
  // / tipeo en la columna Familia).
  if ds.FieldByName('DESCRIPCION_SESLIN').AsString <> '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT NOMBRE_FAM_FAM FROM fza_articulos_familias ' +
      ' WHERE CODIGO_FAM_FAM = :p';
    q.ParamByName('p').AsString := sTecleado;
    q.Open;
    if not q.IsEmpty then
    begin
      sNombre := q.FieldByName('NOMBRE_FAM_FAM').AsString;
      if sNombre <> '' then
        ds.FieldByName('DESCRIPCION_SESLIN').AsString := sNombre;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoComprasSesiones.dbcLinRefPrvPropertiesEditValueChanged(
  Sender: TObject);
var
  ed   : TcxCustomEdit;
  sRef : string;
  sPrv : string;
  rDup : TResolverDuplicadoSesion;
begin
  inherited;
  if not (Sender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(Sender);
  ed.PostEditValue;

  // Si la cabecera no tiene proveedor todavia no podemos identificar
  // un duplicado por referencia: salimos en silencio.
  if Dmm.unqryTablaG.IsEmpty then
    Exit;
  sPrv := Trim(Dmm.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString);
  if sPrv = '' then
    Exit;
  if Dmm.unqrySesionLin.IsEmpty then
    Exit;

  sRef := Trim(Dmm.unqrySesionLin.FieldByName('REF_PRV_SESLIN').AsString);
  if sRef = '' then
    Exit;

  if AplicarDuplicadoDeSesion(sRef, '') then
    Exit;

  // Buscamos por REF_PROVEEDOR del proveedor de la cabecera. Si match,
  // marcamos REUSAR (la helper rellena el resto de campos de la linea).
  rDup := ResolverDuplicadoSesion(inLibGlobalVar.oConn, sRef, sPrv, True);
  if not rDup.Encontrado then
    Exit;
  AplicarDuplicadoEnLinea(Dmm, rDup);
  if Assigned(FGestorTallas) then
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoComprasSesiones.ExpandirCodigoFamiliaActiva(
  const ACodigoFam: string; const ANombreFam: string);
var
  ds         : TDataSet;
  sExpandido : string;
  sTentativo : string;
  sNombre    : string;
  q          : TUniQuery;
begin
  // Helper compartido por F3 y OnEditValueChanged de la columna Familia:
  // pone CODIGO_FAM_SESLIN, intenta expandir a CODIGO_ART_TENTATIVO via
  // ResolverCodigoFamilia (incrementa CONTADOR_ART_FAM) y prerellena la
  // descripcion con NOMBRE_FAM_FAM si esta vacia.
  if Trim(ACodigoFam) = '' then Exit;
  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('CODIGO_FAM_SESLIN').AsString := ACodigoFam;
  sTentativo := ACodigoFam;
  if ResolverCodigoFamilia(inLibGlobalVar.oConn, ACodigoFam, oUser,
                           sExpandido) then
    sTentativo := sExpandido;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := sTentativo;

  // Descripcion: si esta vacia, copiar NOMBRE_FAM_FAM. Si venimos del
  // modal F3 ya lo recibimos en ANombreFam (sin query). Si venimos de
  // tipeo manual la consulta puntual a fza_articulos_familias trae
  // el nombre para esta linea.
  if ds.FieldByName('DESCRIPCION_SESLIN').AsString = '' then
  begin
    sNombre := ANombreFam;
    if sNombre = '' then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := inLibGlobalVar.oConn;
        q.SQL.Text :=
          'SELECT NOMBRE_FAM_FAM FROM fza_articulos_familias ' +
          ' WHERE CODIGO_FAM_FAM = :p';
        q.ParamByName('p').AsString := ACodigoFam;
        q.Open;
        if not q.IsEmpty then
          sNombre := q.FieldByName('NOMBRE_FAM_FAM').AsString;
      finally
        FreeAndNil(q);
      end;
    end;
    if sNombre <> '' then
      ds.FieldByName('DESCRIPCION_SESLIN').AsString := sNombre;
  end;
end;

procedure TfrmMtoComprasSesiones.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if Assigned(FGestorTallas) then FGestorTallas.ActualizarCaptionsLineaActiva;
end;

// ===========================================================================
//   Color basico — selector con paleta
// ===========================================================================

procedure TfrmMtoComprasSesiones.tvLineasInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  BE       : TcxButtonEdit;
  Btn      : TcxEditButton;
  AvActual : string;
  Info     : TInfoBasico;
begin
  inherited;
  // Estilo Excel: al entrar a una celda el contenido queda seleccionado,
  // asi una pulsacion lo sustituye y Tab/Enter lo deja como esta.
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
  // 'Modelo prov.': cuando el editor es el desplegable de busqueda
  // incremental (celda vacia), enganchamos OnChange para abrir el
  // desplegable filtrado al teclear (debounce), igual que inLibGridArticulos.
  if (AItem = dbcLinRefPrv) and (AEdit is TcxExtLookupComboBox) then
  begin
    TcxExtLookupComboBox(AEdit).Properties.OnChange := ModeloComboChange;
    Exit;
  end;
  // 'Sistema tallas' ya no es un combo: es un TcxButtonEdit con ellipsis
  // que abre el listbox de 3 columnas (dbcLinTallasPropertiesButtonClick),
  // igual que el selector de color basico. No hay popup que auto-desplegar
  // ni guerra con JvEnterAsTab/DroppedDown dentro del grid.
  if AItem <> dbcLinColorBasico then Exit;
  if not (AEdit is TcxButtonEdit) then Exit;
  BE := TcxButtonEdit(AEdit);
  if BE.Properties.Buttons.Count = 0 then Exit;
  Btn := BE.Properties.Buttons[0];

  AvActual := '';
  if Dmm.unqrySesionLin.Active and (not Dmm.unqrySesionLin.IsEmpty) then
    AvActual := Dmm.unqrySesionLin.FieldByName(
                                       'CODIGO_ATB_COLOR_SESLIN').AsString;

  Info := Default(TInfoBasico);
  if Trim(AvActual) <> '' then
    ObtenerInfoBasico(fIdVaColor, AvActual, Info);

  if Info.EsValido and PintarSwatchEnBitmap(FBmpSwatch, Info, 14) then
  begin
    Btn.Glyph.Assign(FBmpSwatch);
    Btn.Kind := bkGlyph;
  end
  else
    Btn.Kind := bkEllipsis;
end;

procedure TfrmMtoComprasSesiones.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Col      : TcxGridColumn;
  Info     : TInfoBasico;
  AvActual : string;
  colAc    : TcxGridColumn;
  vAc      : Variant;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  TxtRect  : TRect;
begin
  inherited;
  Col := nil;
  if AViewInfo.GridRecord = nil then Exit;
  if AViewInfo.Item is TcxGridColumn then
    Col := TcxGridColumn(AViewInfo.Item);
  if Col = nil then Exit;

  // ---- Sombreado celdas talla fuera del conjunto de la fila ----
  // Cada fila puede tener un sistema de tallaje distinto. Las celdas
  // talla cuyo Tag (posicion 1..N) excede el tamanyo del conjunto pivot
  // de esa fila no aplican — las pintamos con un sombreado claro para
  // que el usuario vea que no son editables. El bloqueo de edicion
  // efectivo se hace en tvLineasEditing.
  if (Col.Tag >= 1) and (Col.Tag <= CANT_TALLAS_MAX) and
     (Col = FTallaColumns[Col.Tag - 1]) then
  begin
    colAc := tvLineas.GetColumnByFieldName('ID_AC_PIVOT_SESLIN');
    if colAc <> nil then
    begin
      vAc := AViewInfo.GridRecord.Values[colAc.Index];
      if (not VarIsNull(vAc)) and (not VarIsEmpty(vAc)) and VarIsNumeric(vAc) then
      begin
        iAc := vAc;
        if (iAc > 0) and Assigned(FGestorTallas) then
        begin
          arr := FGestorTallas.GetPosicionesConjunto(iAc);
          if Col.Tag > Length(arr) then
          begin
            // Posicion fuera del conjunto de esta fila → sombrear.
            ACanvas.Brush.Color := $00E8E8E8;  // gris claro
            ACanvas.FillRect(AViewInfo.Bounds);
            ADone := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  // ---- Nombre del sistema de tallas (columna selector) ----
  // dbcLinTallas esta bound al ID numerico (ID_AC_PIVOT_SESLIN); pintamos
  // el NOMBRE_AC del conjunto para que la celda muestre el nombre legible
  // y no el ID crudo. El editor (ellipsis) solo aparece al entrar a la
  // celda; el resto del tiempo manda este pintado.
  if Col = dbcLinTallas then
  begin
    AvActual := '';
    vAc := AViewInfo.GridRecord.Values[Col.Index];
    if (not VarIsNull(vAc)) and (not VarIsEmpty(vAc)) and VarIsNumeric(vAc) then
    begin
      iAc := vAc;
      if (iAc <= 0) or (FNombresConjunto = nil) or
         (not FNombresConjunto.TryGetValue(iAc, AvActual)) then
        AvActual := '';
    end;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AViewInfo.Params.Color;
    ACanvas.FillRect(AViewInfo.Bounds);
    if AvActual <> '' then
    begin
      TxtRect := AViewInfo.Bounds;
      Inc(TxtRect.Left, 4);
      ACanvas.Font.Assign(AViewInfo.Params.Font);
      ACanvas.Font.Color := AViewInfo.Params.TextColor;
      ACanvas.Brush.Style := bsClear;
      ACanvas.DrawText(AvActual, TxtRect,
                       DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
      ACanvas.Brush.Style := bsSolid;
    end;
    ADone := True;
    Exit;
  end;

  // ---- Swatch de color basico ----
  if Col <> dbcLinColorBasico then Exit;
  AvActual := VarToStr(AViewInfo.GridRecord.Values[Col.Index]);
  if Trim(AvActual) = '' then Exit;
  Info := Default(TInfoBasico);
  if not ObtenerInfoBasico(fIdVaColor, AvActual, Info) then Exit;
  if not Info.EsValido then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info) then
    ADone := True;
end;

procedure TfrmMtoComprasSesiones.tvLineasEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  inherited;
  // Si la celda es una talla cuya posicion (Tag) excede el tamanyo
  // del conjunto pivot de la linea con foco, no permitir edicion. Asi
  // el usuario no puede teclear cantidades en celdas que no aplican
  // al sistema de tallaje de esa linea.
  if AItem = nil then Exit;
  if (AItem.Tag < 1) or (AItem.Tag > CANT_TALLAS_MAX) then Exit;
  if FGestorTallas = nil then Exit;
  if Dmm.unqrySesionLin.IsEmpty then Exit;

  iAc := Dmm.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  if iAc <= 0 then Exit;
  arr := FGestorTallas.GetPosicionesConjunto(iAc);
  if AItem.Tag > Length(arr) then
  begin
    AAllow := False;
    Exit;
  end;
  // Modo 'Formato distribuido': bloquear edicion inline y disparar el
  // modal de distribuidor (que reparte cantidades por almacen). El
  // grid principal mostrara la SUMA de almacenes por talla — la query
  // del gestor ya agrupa por pivot sin filtrar por almacen, asi que
  // solo hay que refrescar despues.
  if (not Dmm.unqryTablaG.IsEmpty) and
     (Dmm.unqryTablaG.FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString = 'S') then
  begin
    AAllow := False;
    AbrirDistribuidor;
  end;
end;

function TfrmMtoComprasSesiones.MaterializarSesionConTx(
                  AFrmSet: TfrmModalCrearAlbaranSesion;
                  const AUsuario: string;
                  AListaDocs: TStringList;
                  out ASerPed, ANumPed, ASerAlb, ANumAlb, AErr: string): Boolean;
var
  oConn      : TUniConnection;
  bTxOwned   : Boolean;
  oQry       : TUniQuery;
  bGenPed    : Boolean;
  bGenAlb    : Boolean;
  bUnPorAlm  : Boolean;
  bPrimera   : Boolean;
  sAlm       : string;
  sEmpresa   : string;
  sSerieAlbAlm : string;
  sSeriePedAlm : string;
  sSerPedTmp : string;
  sNumPedTmp : string;
  sSerAlbTmp : string;
  sNumAlbTmp : string;
begin
  // Envolvemos el flujo en una transaccion explicita: si cualquier
  // iteracion (creacion pedido/albaran, generacion movimientos, marcar
  // sesion) falla, hacemos rollback completo y la BBDD queda como
  // antes. Sin esto un fallo a mitad dejaba albaranes huerfanos con
  // ESTADO_ALBC='ABIERTO' y total 0 (visto en debug).
  Result    := False;
  ASerPed   := ''; ANumPed := '';
  ASerAlb   := ''; ANumAlb := '';
  AErr      := '';
  bGenPed   := Dmm.unqryTablaG.FieldByName('ESGENERA_PEDIDO_SES').AsString = 'S';
  bGenAlb   := Dmm.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S';
  bUnPorAlm := AFrmSet.UnDocPorAlmacen;
  sEmpresa  := Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  oConn     := inLibGlobalVar.oConn;
  bTxOwned  := not oConn.InTransaction;
  if bTxOwned then oConn.StartTransaction;
  try
    if bUnPorAlm then
    begin
      // Iteramos los almacenes distintos que aparecen en celdas con
      // cantidad > 0. MaterializarSesion filtra por cada uno con
      // AFiltroAlmacen y crea un albaran/pedido independiente por
      // almacen. La cabecera de sesion queda con el ULTIMO doc (la
      // lista completa vive en fza_compras_sesiones_documentos).
      oQry := TUniQuery.Create(nil);
      try
        oQry.Connection := oConn;
        oQry.SQL.Text :=
          'SELECT DISTINCT IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
          '                       :alm_cab) AS ALM ' +
          '  FROM fza_compras_sesiones_celdas C ' +
          ' WHERE C.SERIE_SES_SESCEL = :s AND C.NUMERO_SES_SESCEL = :n ' +
          '   AND C.CANTIDAD_SESCEL > 0 ' +
          ' ORDER BY ALM';
        oQry.ParamByName('alm_cab').AsString :=
          Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
        oQry.ParamByName('s').AsString :=
          Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
        oQry.ParamByName('n').AsString :=
          Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
        oQry.Open;
        bPrimera := True;
        // Solo la PRIMERA iteracion crea articulos / SKUs / barras /
        // tarifas; las siguientes pasan ASoloDocumentos=True y solo
        // crean el pedido/albaran de su almacen. Asi evitamos
        // re-procesar los mismos articulos N veces (rendimiento +
        // limpieza, no solo evitar duplicados via INSERT IGNORE).
        while not oQry.Eof do
        begin
          sAlm := oQry.FieldByName('ALM').AsString;
          // La serie acompanya al almacen: si el almacen lleva serie
          // propia (fza_empresas_series.CODIGO_ALM_EMPSER) el documento
          // de ese almacen sale con ella; si no, con la elegida en el
          // modal (que el usuario pudo cambiar en el combo).
          sSerieAlbAlm := ObtenerSeriePropiaAlmacen(sEmpresa, 'AB', sAlm);
          if sSerieAlbAlm = '' then
            sSerieAlbAlm := AFrmSet.SerieAlb;
          sSeriePedAlm := ObtenerSeriePropiaAlmacen(sEmpresa, 'PC', sAlm);
          if sSeriePedAlm = '' then
            sSeriePedAlm := AFrmSet.SeriePed;
          if not MaterializarSesion(Dmm, bGenPed, bGenAlb, AUsuario,
                                     sSerieAlbAlm, sSeriePedAlm,
                                     sSerPedTmp, sNumPedTmp,
                                     sSerAlbTmp, sNumAlbTmp, AErr,
                                     sAlm, not bPrimera) then
            raise Exception.Create(AErr);
          bPrimera := False;
          // Conservamos el primer resultado para retro-compat (callers
          // que solo miran ASerAlb / ANumAlb). La lista completa va en
          // AListaDocs.
          if ASerAlb = '' then begin ASerAlb := sSerAlbTmp; ANumAlb := sNumAlbTmp; end;
          if ASerPed = '' then begin ASerPed := sSerPedTmp; ANumPed := sNumPedTmp; end;
          // Acumulamos albaranes y pedidos generados en la lista. Ambos
          // tipos tienen Mto propio (AlbaranesCompra / PedidosCompra) y
          // el modal frmDocs sabe dispatchar a uno u otro segun el
          // primer campo. Antes solo se anyadian albaranes, lo que
          // hacia que materializar solo pedido mostrase 'sin documentos'.
          if Assigned(AListaDocs) and bGenAlb and (sSerAlbTmp <> '') then
            AListaDocs.Add(Format('Albaran|%s|%s|%s',
                                  [sSerAlbTmp, sNumAlbTmp, sAlm]));
          if Assigned(AListaDocs) and bGenPed and (sSerPedTmp <> '') then
            AListaDocs.Add(Format('Pedido|%s|%s|%s',
                                  [sSerPedTmp, sNumPedTmp, sAlm]));
          oQry.Next;
        end;
      finally
        FreeAndNil(oQry);
      end;
    end
    else
    begin
      if not MaterializarSesion(Dmm, bGenPed, bGenAlb, AUsuario,
                                 AFrmSet.SerieAlb, AFrmSet.SeriePed,
                                 ASerPed, ANumPed, ASerAlb, ANumAlb, AErr) then
        raise Exception.Create(AErr);
      sAlm := Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
      if Assigned(AListaDocs) and bGenAlb and (ASerAlb <> '') then
        AListaDocs.Add(Format('Albaran|%s|%s|%s',
                              [ASerAlb, ANumAlb, sAlm]));
      if Assigned(AListaDocs) and bGenPed and (ASerPed <> '') then
        AListaDocs.Add(Format('Pedido|%s|%s|%s',
                              [ASerPed, ANumPed, sAlm]));
    end;
    if bTxOwned then oConn.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      if bTxOwned and oConn.InTransaction then oConn.Rollback;
      if AErr = '' then AErr := E.Message;
      Result := False;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.CopiarCeldasDistribuidasOtroColor(
                                  ALineaOrigen, ALineaDestino: Integer);
var
  oQry : TUniQuery;
  sSer, sNum, sAlmCab : string;
begin
  // Replica las celdas (almacen, talla, cantidad) de la linea origen
  // en la linea destino. NORMALIZA CODIGO_ALM_SESCEL: si la celda
  // origen lo tiene vacio (residuo de cuando la sesion era no
  // distribuida), la copia con el CODIGO_ALM_SES de cabecera. Sin esta
  // normalizacion, el modal distribuidor de la linea nueva no veria
  // esas celdas (las ignora por sCod='') y los totales del grid no
  // cuadrarian con el cuadrante que el usuario ve.
  sSer    := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNum    := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sAlmCab := Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := inLibGlobalVar.oConn;
    oQry.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_celdas ' +
      '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, LINEA_SES_SESCEL, ' +
      '   ID_FILA_SES_SESCEL, CODIGO_ALM_SESCEL, ID_AV_PIVOT_SESCEL, ' +
      '   CANTIDAD_SESCEL, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT SERIE_SES_SESCEL, NUMERO_SES_SESCEL, :ldst, ' +
      '       ID_FILA_SES_SESCEL, ' +
      '       IFNULL(NULLIF(CODIGO_ALM_SESCEL, ''''), :alm_cab), ' +
      '       ID_AV_PIVOT_SESCEL, ' +
      '       CANTIDAD_SESCEL, NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL  = :s ' +
      '   AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL  = :lsrc ' +
      '   AND CANTIDAD_SESCEL   > 0';
    oQry.ParamByName('s').AsString    := sSer;
    oQry.ParamByName('n').AsString    := sNum;
    oQry.ParamByName('lsrc').AsInteger := ALineaOrigen;
    oQry.ParamByName('ldst').AsInteger := ALineaDestino;
    oQry.ParamByName('alm_cab').AsString := sAlmCab;
    oQry.ParamByName('u').AsString    := oUser;
    oQry.ExecSQL;
    // Tras copiar, refrescar totales de la linea destino para que
    // TOTAL_UNIDADES_SESLIN y TOTAL_LINEA_SESLIN cuadren con la suma
    // de celdas (si no, las columnas Uds/Total del grid principal
    // salen a 0 para la nueva linea aunque las cantidades por talla
    // esten bien).
    oQry.SQL.Text :=
      'UPDATE fza_compras_sesiones_lineas ' +
      '   SET TOTAL_UNIDADES_SESLIN = ' +
      '         (SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) ' +
      '            FROM fza_compras_sesiones_celdas ' +
      '           WHERE SERIE_SES_SESCEL  = :s ' +
      '             AND NUMERO_SES_SESCEL = :n ' +
      '             AND LINEA_SES_SESCEL  = :l), ' +
      '       TOTAL_LINEA_SESLIN    = ' +
      '         (SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) ' +
      '            FROM fza_compras_sesiones_celdas ' +
      '           WHERE SERIE_SES_SESCEL  = :s ' +
      '             AND NUMERO_SES_SESCEL = :n ' +
      '             AND LINEA_SES_SESCEL  = :l) * ' +
      '         PRECIO_COMPRA_SESLIN, ' +
      '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
      ' WHERE SERIE_SES_SESLIN  = :s ' +
      '   AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN      = :l';
    oQry.ParamByName('s').AsString  := sSer;
    oQry.ParamByName('n').AsString  := sNum;
    oQry.ParamByName('l').AsInteger := ALineaDestino;
    oQry.ParamByName('u').AsString  := oUser;
    oQry.ExecSQL;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TfrmMtoComprasSesiones.AbrirDistribuidor(
  const ACodigoKit: string);
var
  oForm  : TfrmModalDistribuidor;
  iLinea : Integer;
  iAc    : Integer;
begin
  if Dmm.unqrySesionLin.IsEmpty then Exit;
  iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  iAc    := Dmm.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  if (iLinea <= 0) or (iAc <= 0) then Exit;
  // Persistir cualquier edicion pendiente para que el modal vea el
  // estado consistente de la linea (en particular ID_AC_PIVOT_SESLIN).
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;
  oForm := TfrmModalDistribuidor.Create(Application);
  // Evitamos el caFree heredado de TfrmModalAceptCancel para poder hacer
  // FreeAndNil manual en el finally sin riesgo de doble liberacion.
  oForm.OnClose := nil;
  try
    oForm.Preparar(inLibGlobalVar.oConn, oUser,
                    Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
                    Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString,
                    iLinea, iAc,
                    Trim(Dmm.unqryTablaG.FieldByName(
                                              'CODIGO_PRV_SES').AsString),
                    ACodigoKit);
    oForm.ShowModal;
    if oForm.Confirmado then
    begin
      // ORDEN CRITICO. El Refresh del dataset resetea el DataController
      // del cxGrid y borra los Values[] de las columnas no-bound (las
      // tallas), asi que CargarCantidadesTodasLineas TIENE que ir
      // DESPUES del Refresh. Si va antes (como estaba), las celdas talla
      // se pintan y luego el Refresh las deja en blanco.
      //   1) RefrescarTotalesLineaActual: Edit en memoria sobre la linea
      //      activa, actualiza TOTAL_UNIDADES_SESLIN / TOTAL_LINEA_SESLIN.
      //   2) Refresh: posttea el Edit (UPDATE SQL) y re-fetchea -> reset
      //      del DataController, pierde las tallas no-bound.
      //   3) InvalidarCache + CargarCantidadesTodasLineas: re-pinta las
      //      tallas YA con los Values[] correctos, leyendo SUM(CANTIDAD)
      //      desde fza_compras_sesiones_celdas.
      if Assigned(FGestorTallas) then
        FGestorTallas.RefrescarTotalesLineaActual;
      Dmm.unqrySesionLin.Refresh;
      if Assigned(FGestorTallas) then
      begin
        FGestorTallas.InvalidarCache;
        FGestorTallas.CargarCantidadesTodasLineas;
      end;
      if Assigned(Dmm) then
        Dmm.RefrescarTotalesSesion;
    end;
  finally
    FreeAndNil(oForm);
  end;
end;

procedure TfrmMtoComprasSesiones.dbcLinColorBasicoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  AvActual : string;
  AvNuevo  : string;
  ds       : TDataSet;
  Edit     : TWinControl;
  ScrPt    : TPoint;
  WidHint  : Integer;
begin
  if Length(FBasicosColor) = 0 then
  begin
    MessageDlg('No hay colores basicos cargados en fza_atributos_basicos ' +
               'para ID_VA=''CO''.', mtInformation, [mbOk], 0);
    Exit;
  end;

  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  AvActual := ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;

  ScrPt.X := -1; ScrPt.Y := -1;
  WidHint := 160;
  if Sender is TWinControl then
  begin
    Edit    := TWinControl(Sender);
    ScrPt   := Edit.ClientToScreen(Point(0, Edit.Height));
    WidHint := Edit.Width;
  end;

  if not SeleccionarAvConPaleta(fIdVaColor, FBasicosColor, AvActual,
                                AvNuevo, ScrPt.X, ScrPt.Y, WidHint) then
    Exit;

  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString := AvNuevo;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).EditValue := AvNuevo;
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
  ProponerPrecioVenta;
end;

procedure TfrmMtoComprasSesiones.ProponerPrecioVenta;
var
  rCoste, rMargen, rMultiplo, rAjuste, rVenta : Double;
  ds                                          : TDataSet;
begin
  if Dmm.unqryTablaG.IsEmpty then Exit;
  if Dmm.unqrySesionLin.IsEmpty then Exit;

  ds := Dmm.unqrySesionLin;
  rCoste    := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  rMargen   := Dmm.unqryTablaG.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat;
  rMultiplo := Dmm.unqryTablaG.FieldByName('MULTIPLO_REDONDEO_SES').AsFloat;
  rAjuste   := Dmm.unqryTablaG.FieldByName('AJUSTE_FINAL_SES').AsFloat;

  rVenta := CalcularPrecioVenta(rCoste, rMargen, rMultiplo, rAjuste);
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := rVenta;
end;

// ===========================================================================
//   Conjunto de tallas (Sistema tallas) cambia -> rebuild de cabeceras
// ===========================================================================

// La edicion de celdas talla (antiguo TallaCellEditValueChanged) se
// extrajo a TGestorGridTallas.PersistirCeldaActiva; el handler se
// engancha automaticamente en InicializarGestorTallas.

initialization
  ForceReferenceToClass(TfrmMtoComprasSesiones);
end.
