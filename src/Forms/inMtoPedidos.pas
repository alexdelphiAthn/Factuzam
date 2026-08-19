{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPedidos                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de pedidos de venta.                                        }
{    Cabecera, lineas y datos fiscales sobre fza_pedidos.                      }
{******************************************************************************}
unit inMtoPedidos;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoDocumento, dxSkinsCore, dxSkinBlue,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsForm, cxLabel, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB,
  cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxSpinEdit, cxCurrencyEdit, UniDataPedidos, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, System.Generics.Collections,
  cxGridBandedTableView, cxGridDBBandedTableView,
  System.Actions, Vcl.ActnList,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridPivoteVenta,
  inLibDocumento, inLibDocumentoIntf,
  inLibVentasPantallaIntf, inLibVentasPantallaCrearAlbaran,
  inLibPedidosVentaPresentacionReglas, inLibArticulosResolverIntf;

type
  TfrmMtoPedidos = class(TfrmMtoDocumento)
    pnlTopFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    tsEmpresa: TcxTabSheet;
    tsDatosCliente: TcxTabSheet;
    tsEnvio: TcxTabSheet;
    pnlBodyFicha: TPanel;
    pcPedido: TcxPageControl;
    tsLineasPedido: TcxTabSheet;
    tsAlbaranes: TcxTabSheet;
    tsMensajes: TcxTabSheet;
    tsObservaciones: TcxTabSheet;
    pnlBottomTotales: TPanel;
    cxGrdPedidosLineas: TcxGrid;
    tvPedidosLineas: TcxGridDBTableView;
    cxGrdPedidosLineasLevel1: TcxGridLevel;
    cxGrdAlbaranes: TcxGrid;
    tvAlbaranes: TcxGridDBTableView;
    cxGrdAlbaranesLevel: TcxGridLevel;
    cxGrdMensajes: TcxGrid;
    tvMensajes: TcxGridDBTableView;
    cxGrdMensajesLevel: TcxGridLevel;

    // Cabecera
    lblNroPedido: TcxLabel;
    txtNUMERO_PED: TcxDBTextEdit;
    lblSerie: TcxLabel;
    cbbSERIE_PED: TcxDBComboBox;
    lblFecha: TcxLabel;
    dteFECHA_PED: TcxDBDateEdit;
    lblFechaEntrega: TcxLabel;
    dteFECHA_ENTREGA_PED: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_PED: TcxDBTextEdit;
    lblIDPS: TcxLabel;
    txtIDPS_PED: TcxDBTextEdit;
    lblRefPS: TcxLabel;
    txtREFERENCIAPS_PED: TcxDBTextEdit;

    btnCODIGO_EMP: TcxDBButtonEdit;
    lblCodigoEmpresa: TcxLabel;
    cxdblblRAZON_SOCIAL_EMPRESA_PED: TcxDBLabel;
    lblCodigoAlmacen: TcxLabel;
    cbbCODIGO_ALM_PED: TcxDBLookupComboBox;
    btnCODIGO_CLI: TcxDBButtonEdit;
    lblCodigoCliente: TcxLabel;
    cxdblblRAZON_SOCIAL_CLIENTE_PED: TcxDBLabel;
    lblTarifaPedido: TcxLabel;
    cbbTarifaPedido: TcxDBLookupComboBox;
    chkTarifaImpuestosIncluidosPedido: TcxDBCheckBox;

    // Empresa
    grpEmpresa: TcxGroupBox;
    txtNIF_EMPRESA_PED: TcxDBTextEdit;
    lblNIFEmp: TcxLabel;
    txtMOVIL_EMPRESA_PED: TcxDBTextEdit;
    lblMovEmp: TcxLabel;
    txtEMAIL_EMPRESA_PED: TcxDBTextEdit;
    lblEmailEmp: TcxLabel;
    txtDIRECCION1_EMPRESA_PED: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_PED: TcxDBTextEdit;
    txtPOBLACION_EMPRESA_PED: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_PED: TcxDBTextEdit;
    txtCODIGO_POSTAL_EMPRESA_PED: TcxDBTextEdit;
    txtNOMBRE_PAI_EMPRESA_PED: TcxDBTextEdit;

    // Cliente fiscal
    grpClienteFiscal: TcxGroupBox;
    txtRAZON_SOCIAL_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtNIF_CLIENTE_PED: TcxDBTextEdit;
    txtEMAIL_CLIENTE_PED: TcxDBTextEdit;
    txtMOVIL_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_FISCAL_PED: TcxDBTextEdit;

    // Cliente envío
    grpClienteEnvio: TcxGroupBox;
    txtNOMBRE_CLI_ENVIO_PED: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ENVIO_PED: TcxDBTextEdit;

    // Totales
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_PED: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit;
    tsTotales: TcxTabSheet;
    scrTotales: TScrollBox;
    lblTotalesTotalBase: TcxLabel;
    curTotalesTOTAL_BASES_PED: TcxDBCurrencyEdit;
    lblTotalesTotalImpuestos: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit;
    lblTotalesPorcRetencion: TcxLabel;
    spnTotalesPORCENTAJE_RETENCION_PED: TcxDBSpinEdit;
    lblTotalesTotalRetencion: TcxLabel;
    curTotalesTOTAL_RETENCION_PED: TcxDBCurrencyEdit;
    lblTotalesTotalPagar: TcxLabel;
    curTotalesTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_PED: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_CLIENTE_PED: TcxDBCheckBox;
    chkTotalesESRETENCIONES_CLIENTE_PED: TcxDBCheckBox;
    chkTotalesESRETENCIONES_EMPRESA_PED: TcxDBCheckBox;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasPed: TcxLabel;
    grpDesgloseImpuestos: TGroupBox;
    lblTotalesBaseNeta: TcxLabel;
    lblTotalesPorIva: TcxLabel;
    lblTotalesTotalIva: TcxLabel;
    lblTotalesPorRe: TcxLabel;
    lblTotalesTotalRe: TcxLabel;
    lblTotalesIVAN: TcxLabel;
    lblTotalesIVAR: TcxLabel;
    lblTotalesIVAS: TcxLabel;
    lblTotalesIVAE: TcxLabel;
    curTotalesTOTAL_BASEI_IVAN_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAR_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAS_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAE_PED: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_IVAN_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_PED: TcxDBSpinEdit;
    curTotalesTOTAL_IVAN_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAR_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAS_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAE_PED: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_REN_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_PED: TcxDBSpinEdit;
    curTotalesTOTAL_REN_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_RER_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_RES_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_REE_PED: TcxDBCurrencyEdit;

    // Botones de acción
    pnlBotonesAcciones: TPanel;
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    btnEntregarTodo: TcxButton;
    btnCrearAlbaran: TcxButton;
    btnImportarPS: TcxButton;
    btnExpandirFilas: TcxButton;

    // Observaciones
    memObservaciones: TcxDBMemo;
    // Atajo Ctrl+May+A en la pestania Albaranes: abre el albaran de venta
    // seleccionado en la rejilla.
    ActionList1: TActionList;
    actIrDocumento: TAction;
    btnImprimir: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnEntregarTodoClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
    procedure btnImportarPSClick(Sender: TObject);
    procedure btnExpandirFilasClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure cbbSERIE_PEDPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMPPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure btnCODIGO_CLIPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure btnCODIGO_EMPPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_ALM_PEDPropertiesEditValueChanged(Sender: TObject);
    procedure cbbTarifaPedidoPropertiesChange(Sender: TObject);
    procedure btnCODIGO_CLIPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMPKeyUp(Sender: TObject; var Key: Word;
                                 Shift: TShiftState);
    procedure btnCODIGO_CLIKeyUp(Sender: TObject; var Key: Word;
                                 Shift: TShiftState);
    procedure cxgrdcPedLinARTPropertiesButtonClick(Sender: TObject;
                                                   AButtonIndex: Integer);
    procedure cxgrdcPedLinARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure cxgrdcPedLinSKUPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure cxGrdPedidosLineasEnter(Sender: TObject);
    procedure cxGrdPedidosLineasExit(Sender: TObject);
  private
    FBuscandoDatosCabecera: Boolean;
    FAplicandoArticulo: Boolean;
    // Handlers originales de unqryPedidosLineas guardados para no perder
    // la logica del DM al encadenar montaje de columnas y totales.
    FOldLineasAfterOpen: TDataSetNotifyEvent;
    FOldLineasAfterPost: TDataSetNotifyEvent;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal. Para alta de
    // lineas Auto es el modo operativo para buscar articulo/SKU.
    // El Construir hace ClearItems: las columnas del dfm mueren y las
    // propias se recrean en runtime (patron de DTR e inventarios).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    // Capacidades del modo actual (solo el pivote de tallas las
    // implementa). Se descubren UNA vez al montar el modo (patron 5.3)
    // y se limpian en cada teardown ANTES de soltar FModoEntrada.
    FPivoteAlbaranar: IPivoteVentaAlbaranar;
    FPivoteBorrarGrupo: IPivoteVentaBorrarGrupo;
    FContextoVentas: TContextoPedidosVentasPantalla;
    procedure AsegurarModoEntradaLineas(AMostrarEditor: Boolean);
    procedure ConstruirModoEntrada;
    function PuedeConstruirModoEntrada(
      out ADataSet: TDataSet): Boolean;
    function CrearPlanModoEntrada:
      TPlanModoEntradaPedidoVenta;
    function CrearPlanModoResuelto(
      AModo: TModoColumnasSku): TPlanModoEntradaPedidoVenta;
    procedure OcultarEditorModoEntrada;
    procedure SoltarFocoModoEntrada;
    procedure DesmontarModoAnterior;
    procedure DesvincularOrigenLineas;
    procedure LimpiarVistaModoEntrada;
    procedure RetirarModoEntrada(ADataSet: TDataSet);
    function CrearConfiguracionModoEntrada(
      ADataSet: TDataSet): TConfigColumnasSku;
    function CrearConfiguracionPivoteVenta:
      TGridPivoteVentaConfig;
    procedure CrearModoEntradaSeleccionado(
      const AConfiguracion: TConfigColumnasSku);
    procedure MontarColumnasModoEntrada(
      const APlan: TPlanModoEntradaPedidoVenta);
    procedure AplicarPresentacionModoEntrada(
      const AConfiguracion: TConfigColumnasSku);
    procedure CrearColumnasHostPedido;
    procedure MostrarColumnasAtributoGlobalesPed;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    function BuscarArticuloPedido: string;
    function BuscarSkuPedido(const ACodigoArt: string): string;
    function ArticuloLineaActivaPedido: string;
    procedure AplicarArticuloPedido(const ACodigoArt: string);
    // Porcentaje de IVA de la cabecera para un tipo (N/R/S/E).
    function PorcentajeIvaPedido(const ATipoIva: string): Double;
    // Contrato ObtenerPrecioSku del modo tallas: PVP C/IVA que el
    // pedido aplicaria al SKU (tarifa de cabecera, fecha del pedido),
    // para que la consolidacion del escaneo separe lineas por precio.
    function PrecioSkuTallas(const ACodigoArticulo,
                             ACodigoSku: string): Double;
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    procedure ValidarClienteParaLineas;
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaPedido;
    procedure PrepararModoAltaLineas;
    procedure cxgrdcPedLinSKUPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure RellenarLineasAlEntregarTodo;
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
    // Pinta lblTotalPrendasPed con el total de prendas (suma de
    // CANTIDAD_PEDLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    // Hook AfterPost de las lineas: conserva el calculo de totales que
    // hacia el DM (CalcularTotalesPedido) y anade el refresco del label.
    procedure unqryLineasAfterOpenHook(DataSet: TDataSet);
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    // Hook OnDataChange de dsTablaG: al navegar entre pedidos (Field=nil)
    // hay que recalcular el total de prendas con las lineas del pedido
    // recien enfocado.
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    function LeerLineasParaAlbaran(
      ADataSet: TDataSet): TLineasPedidoParaAlbaran;
    function PrepararEntregasAlbaran(
      ADataSet: TDataSet): TPreparacionAlbaranPedido;
    function PuedeCrearAlbaran(ADataSet: TDataSet): Boolean;
    function EjecutarCreacionAlbaran(
      const APreparacion: TPreparacionAlbaranPedido;
      const ACodigoAlmacen: string;
      AEsExistente: Boolean;
      const ASerieExistente, ANumeroExistente: string):
      TResultadoCreacionAlbaranPedido;
    procedure LimpiarCantidadesAAlbaranar(ADataSet: TDataSet);
    procedure MostrarAlbaranCreado(
      const AResultado: TResultadoCreacionAlbaranPedido;
      AEsExistente: Boolean;
      const ACodigoAlmacen: string);
    procedure CrearAlbaranDesdePedidoActivo;
  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmPedidos: TdmPedidos;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
  end;

implementation

uses
  inMtoModalImportarPedidosPS, inLibGridCantidad,
  inMtoModalSelAlmacenAlbaran, inMtoModalDocsCreados, inLibGenBusq,
  inLibShowMto, inLibFiltroUsuario,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inLibGridTallasInline,
  inLibEntradaAlbaranVentaPersistenciaIntf,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku, inLibColumnasDocumento,
  UniDataColumnasDocumentoRepositorio, UniDataGen,
  inLibValidacionDocumento, inLibPresentacionDocumento,
  inLibMsgArticulos, inLibMsgVentas, inLibMsgConfiguracion,
  inLibPermisosIntf,
  inMtoPedidosPresentacionArticuloVcl,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta, UniDataVentasPantallaComposicion;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

destructor TfrmMtoPedidos.Destroy;
begin
  // El modo del contrato se libera ANTES del inherited: su teardown
  // (Desmontar/destructor) toca el view y el dataset de lineas, que
  // deben seguir vivos. Dejarlo a la finalizacion de la interfaz en
  // CleanupInstance corria con el grid ya destruido (AV en GetProvider
  // al cerrar la pestania, 08/07/26).
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      // Teardown defensivo en cierre: nada que hacer si el grid ya
      // esta a medio destruir.
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'Pedidos.Destroy: Desmontar fallo: ' + E.Message);
    end;
    // Las capacidades sostienen la misma instancia: soltar tambien.
    FPivoteAlbaranar := nil;
    FPivoteBorrarGrupo := nil;
    FModoEntrada := nil;
  end;
  FContextoVentas := Default(TContextoPedidosVentasPantalla);
  inherited;
end;

procedure TfrmMtoPedidos.cbbSERIE_PEDPropertiesInitPopup(Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmPedidos <> nil) and dmmPedidos.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmPedidos.unqryTablaG.
                       FieldByName('CODIGO_EMP_PED').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
  end;
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_PED.Properties.Items);
  if cbbSERIE_PED.Properties.Items.Count = 0 then
  begin
    if MessageDlg(Format(SPreguntaAbrirSeriesPedidoVenta, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera de pedido. El articulo activo vive en
// la fila del sub-grid tvPedidosLineas (CODIGO_ART_PEDLIN /
// CODIGOPRODPS_PEDLIN, usado como SKU efectivo en venta mayor).
function TfrmMtoPedidos.BuscarArticuloPedido: string;
var
  oConsulta: IConsultaEntradaAlbaranVenta;
  oDatos: TDataSet;
  oCampo: TField;
  sTarifa: string;
  dFecha: TDateTime;
begin
  Result := '';
  if Assigned(dmmPedidos) then
  begin
    sTarifa := dmmPedidos.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_PED').AsString;
    dFecha := Date;
    if not dmmPedidos.unqryTablaG.FieldByName('FECHA_PED').IsNull then
      dFecha := dmmPedidos.unqryTablaG.FieldByName('FECHA_PED').AsDateTime;
    oConsulta := FContextoVentas.EntradaArticulos.ConsultarArticulos(
      sTarifa,
      dFecha);
    oDatos := oConsulta.DataSet;
    if BusquedaVisual.EjecutarBusquedaDataSet(
        'Búsqueda de Artículos en Líneas de Pedido',
        oDatos,
        'frmMtoArtFacSearch',
        Self) then
    begin
      oCampo := oDatos.FindField('CODIGO_ART_ART');
      if oCampo = nil then
        oCampo := oDatos.FindField('CODIGO_ART');
      if oCampo <> nil then
        Result := oCampo.AsString;
    end;
  end;
end;

function TfrmMtoPedidos.ArticuloLineaActivaPedido: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmPedidos) then
  begin
    ds := dmmPedidos.unqryPedidosLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_PEDLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_PEDLIN').AsString);
  end;
end;

function TfrmMtoPedidos.BuscarSkuPedido(const ACodigoArt: string): string;
var
  oConsulta: IConsultaEntradaAlbaranVenta;
  oDatos: TDataSet;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmPedidos) then
    MessageDlg(SErrorPedidoVentaNoAbierto,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg(SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta,
               mtInformation, [mbOk], 0)
  else
  begin
    oConsulta := FContextoVentas.EntradaArticulos.ConsultarSkus(sArt);
    oDatos := oConsulta.DataSet;
    if BusquedaVisual.EjecutarBusquedaDataSet(
        'SKUs del artículo ' + sArt,
        oDatos,
        'frmMtoPedSkuSearch',
        Self) and (oDatos.FindField('CODIGO_UNIDAD_SKU') <> nil) then
      Result := oDatos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  end;
end;

procedure TfrmMtoPedidos.AplicarArticuloPedido(const ACodigoArt: string);
var
  oContexto: TContextoArticuloPedidoVcl;
  oDataSet: TDataSet;
  sEntrada: string;
begin
  sEntrada := Trim(ACodigoArt);
  if (sEntrada <> '') and Assigned(dmmPedidos) and
     (not FAplicandoArticulo) then
  begin
    oDataSet := dmmPedidos.unqryPedidosLineas;
    if Assigned(oDataSet) and oDataSet.Active then
    begin
      FAplicandoArticulo := True;
      try
        oContexto := Default(TContextoArticuloPedidoVcl);
        oContexto.Cabecera := dmmPedidos.unqryTablaG;
        oContexto.Lineas := oDataSet;
        oContexto.Conexion := dmmPedidos.unqryTablaG.Connection;
        oContexto.VistaLineas := tvPedidosLineas;
        oContexto.Resolver := FContextoVentas.ResolverArticulos;
        oContexto.Validador := FContextoVentas.ValidadorArticulos;
        oContexto.AbrirBusquedaSku :=
          procedure
          begin
            cxgrdcPedLinSKUPropertiesButtonClick(nil, 0);
          end;
        AplicarArticuloPedidoVcl(oContexto, sEntrada);
      finally
        FAplicandoArticulo := False;
      end;
    end;
  end;
end;

function TfrmMtoPedidos.PorcentajeIvaPedido(const ATipoIva: string): Double;
begin
  Result := PorcentajeIvaDocumentoVenta(CrearLecturasImpuestos(
    dmmPedidos.unqryTablaG.Connection), dmmPedidos.unqryTablaG,
    'PED', ATipoIva);
end;

function TfrmMtoPedidos.PrecioSkuTallas(const ACodigoArticulo,
  ACodigoSku: string): Double;
var
  Resolver: IArticulosResolver;
  Datos: TArticuloDatos;
  Precio: TArticuloPrecio;
  sTarifa: string;
  dFecha: TDateTime;
  rPorIva: Double;
begin
  Result := 0;
  if Assigned(dmmPedidos) and dmmPedidos.unqryTablaG.Active then
  begin
    sTarifa := dmmPedidos.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_PED').AsString;
    dFecha := Date;
    if not dmmPedidos.unqryTablaG.FieldByName('FECHA_PED').IsNull then
      dFecha := dmmPedidos.unqryTablaG.
                  FieldByName('FECHA_PED').AsDateTime;
    Resolver := FContextoVentas.ResolverArticulos;
    try
      Datos := Resolver.ResolverDatos(ACodigoArticulo, ACodigoSku,
                                      sTarifa, dFecha);
      if Datos.Encontrado then
      begin
        Precio := Datos.PrecioPedido;
        rPorIva := PorcentajeIvaPedido(Datos.TipoIVA);
        // FieldPrecioBase del pedido es el PVP C/IVA de la linea:
        // misma conversion que AplicarArticuloPedido pero a la inversa.
        if Precio.EsImpIncl then
          Result := Precio.PrecioFinal
        else
          Result := Precio.PrecioFinal * (1 + rPorIva / 100);
      end;
    finally
      Resolver := nil;
    end;
  end;
end;

procedure TfrmMtoPedidos.PivoteVentaCrearLineaSku(const ACodigoSku: string);
begin
  AplicarArticuloPedido(ACodigoSku);
end;

procedure TfrmMtoPedidos.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  tsLineasPedido.Caption := '&1_Líneas [Tallas horiz. 3 filas]';
end;

procedure TfrmMtoPedidos.FormCreate(Sender: TObject);
var
  colEnt, colPend: TcxGridDBColumn;
  stEnt, stPend: TcxStyle;
begin
  inherited;
  // Contrato de entrada ColumnSKUcxGrid: Auto por defecto; F1 permite
  // pasar a SKU o a tallas horizontales cuando el pedido ya esta en SKU.
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  btnImportarPS.Enabled := PuedeAccionMto(apmInsertar);
  tsTotales.TabVisible := True;
  tsTotales.Enabled := True;
  if Trim(tsTotales.Caption) = '' then
    tsTotales.Caption := '&2_Totales';
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvPedidosLineas.GetColumnByFieldName('CANTIDAD_PEDLIN'),
    tvPedidosLineas.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_PEDLIN'),
    UnidadesMedida);
  ConfigurarColumnaBusquedaDocumento(
    tvPedidosLineas, 'CODIGOPRODPS_PEDLIN',
    cxgrdcPedLinSKUPropertiesButtonClick,
    cxgrdcPedLinSKUPropertiesValidate);

  colEnt  := tvPedidosLineas.GetColumnByFieldName('CANTIDAD_ENTREGADA_PEDLIN');
  colPend := tvPedidosLineas.GetColumnByFieldName('CANTIDAD_PENDIENTE_PEDLIN');
  if colEnt <> nil then
  begin
    stEnt := TcxStyle.Create(Self);
    stEnt.AssignedValues := [svColor];
    stEnt.Color := $00E0FFE0;
    colEnt.Styles.Content := stEnt;
  end;
  if colPend <> nil then
  begin
    stPend := TcxStyle.Create(Self);
    stPend.AssignedValues := [svColor];
    stPend.Color := $00C4E1FF;
    colPend.Styles.Content := stPend;
  end;
end;

procedure TfrmMtoPedidos.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdPedido, sdVenta));
  AsignarVistaLineasDocumento(tvPedidosLineas);
  inherited;
  dmmPedidos := TdmPedidos(AsegurarDataModuleDocumento(
    Self, tdmDataModule, TdmPedidos));
  CrearContextoVentasPantalla(
    dmmPedidos.unqryTablaG.Connection,
    ParametrosCaja,
    CrearServiciosSqlVentasPantalla(
      Self.Name,
      PerfilesLectura,
      PerfilesEscritura,
      RegistroLog),
    dmmPedidos,
    FContextoVentas);
  ConfigurarTablaPrincipalDocumento(
    dmmPedidos, dsTablaG, tvPedidosLineas,
    dmmPedidos.dsPedidosLineas,
    [dmmPedidos.unqryPedidosLineas, dmmPedidos.unqryAlbaranes],
    pkFieldName, 'SERIE_PED;NUMERO_PED');
  cxGrdPedidosLineas.OnEnter := cxGrdPedidosLineasEnter;
  cxGrdPedidosLineas.OnExit := cxGrdPedidosLineasExit;
  tvAlbaranes.DataController.DataSource := dmmPedidos.dsAlbaranes;
  tvMensajes.DataController.DataSource := dmmPedidos.dsMensajes;
  cbbTotalesFORMA_PAGO_PED.Properties.ListSource := dmmPedidos.dsFormasPago;
  cbbCODIGO_ALM_PED.Properties.ListSource := dmmPedidos.dsAlmacenesPed;
  cbbTarifaPedido.Properties.ListSource := dmmPedidos.dsTarifas;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PED);
  DesactivarEnterAsTabEnCombo(cbbTarifaPedido);
  // Total de prendas y columnas: se encadenan los handlers originales
  // del DM para no perder su logica propia.
  FOldLineasAfterOpen := dmmPedidos.unqryPedidosLineas.AfterOpen;
  FOldLineasAfterPost := dmmPedidos.unqryPedidosLineas.AfterPost;
  dmmPedidos.unqryPedidosLineas.AfterOpen := unqryLineasAfterOpenHook;
  dmmPedidos.unqryPedidosLineas.AfterPost := unqryLineasAfterPostHook;
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  ActualizarLabelPrendas;
end;

procedure TfrmMtoPedidos.ActualizarLabelPrendas;
begin
  if Assigned(dmmPedidos) then
    lblTotalPrendasPed.Caption := TextoTotalPrendasDocumento(
      dmmPedidos.unqryTablaG, dmmPedidos.TotalPrendasPedido)
  else
    lblTotalPrendasPed.Caption := '0';
end;

procedure TfrmMtoPedidos.AsegurarModoEntradaLineas(
  AMostrarEditor: Boolean);
begin
  if (dmmPedidos <> nil) and dmmPedidos.unqryPedidosLineas.Active then
  begin
    if FModoEntrada = nil then
      ConstruirModoEntrada;
    if AMostrarEditor and (FModoEntrada <> nil) then
      FModoEntrada.MostrarEditor;
  end;
end;

procedure TfrmMtoPedidos.unqryLineasAfterOpenHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterOpen) then
    FOldLineasAfterOpen(DataSet);
  AsegurarModoEntradaLineas(False);
  ActualizarLabelPrendas;
end;

// Hook AfterPost de unqryPedidosLineas: encadena el handler original del
// DM (que ya calcula los totales fiscales) y anade el refresco del
// label de prendas, sin perder la logica original.
procedure TfrmMtoPedidos.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterPost) then
    FOldLineasAfterPost(DataSet);
  ActualizarLabelPrendas;
end;

// Hook OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field=nil) que se dispara al cambiar de pedido activo.
procedure TfrmMtoPedidos.dsTablaGDataChangeHook(Sender: TObject;
                                                Field: TField);
begin
  if Field = nil then
  begin
    if Assigned(dmmPedidos) and dmmPedidos.unqryTablaG.Active and
       (not dmmPedidos.unqryTablaG.IsEmpty) then
      dmmPedidos.RefrescarAlmacenes(dmmPedidos.unqryTablaG.FieldByName(
        'CODIGO_EMP_PED').AsString);
    ActualizarLabelPrendas;
    // Contrato de entrada: al navegar de pedido, las lineas llegan
    // recargadas por el master-detail SIN atributos desempaquetados
    // (misma leccion que inventarios: si no, Color/Talla en blanco).
    if dmmPedidos <> nil then
    begin
      if FModoEntrada = nil then
        AsegurarModoEntradaLineas(False)
      else if FColsModoConstruido and (FModoEntradaSel <> mcsSku) then
        dmmPedidos.DesempaquetarAtributosLineas;
    end;
  end;
end;

procedure TfrmMtoPedidos.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidos.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (quedan sin precio y no moveran stock al albaranar).
  sLineasSinSku := LineasSinSkuRequerido(
    FContextoVentas.ValidadorArticulos,
    dmmPedidos.unqryPedidosLineas, 'PEDLIN');
  if (sLineasSinSku = '') or
     (MessageDlg(Format(SPreguntaGrabarPedidoVentaSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmPedidos.CalcularTotalesPedido;
      dsTablaG.DataSet.Post;
    end;
  end;
end;

procedure TfrmMtoPedidos.btnCODIGO_EMPPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmPedidos) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if BusquedaVisual.EjecutarBusqueda(
        ConexionPrincipal,
        'Búsqueda de Empresas en Pedidos',
           dmmPedidos.unqryEmpDataPedido,
           'frmMtoEmpFacSearch',
           Self) then
      begin
        dmmPedidos.CopiarEmpresaaPedido(dmmPedidos.unqryEmpDataPedido);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoPedidos.btnCODIGO_CLIPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmPedidos) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if BusquedaVisual.EjecutarBusqueda(
        ConexionPrincipal,
        'Búsqueda de Clientes en Pedidos',
           dmmPedidos.unqryCliDataPedido,
           'frmMtoCliFacSearch',
           Self) then
      begin
        dmmPedidos.CopiarClienteaPedido(dmmPedidos.unqryCliDataPedido);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoPedidos.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoPedidos.btnCODIGO_EMPPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmPedidos) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if (sCodigo <> '') and (sCodigo <> '0') then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmPedidos.BuscarEmpresa(sCodigo);
        dmmPedidos.RefrescarAlmacenes('');
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidos.cbbCODIGO_ALM_PEDPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmPedidos) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if sCodigo <> '' then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmPedidos.BuscarAlmacen(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidos.cbbTarifaPedidoPropertiesChange(Sender: TObject);
var
  Editor: TcxCustomEdit;
  sTarifa: string;
begin
  inherited;
  if Assigned(dmmPedidos) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) then
  begin
    Editor := Sender as TcxCustomEdit;
    sTarifa := Trim(VarToStr(Editor.EditingValue));
    dmmPedidos.ActualizarImpuestosTarifaCabecera(sTarifa);
  end;
end;

procedure TfrmMtoPedidos.btnCODIGO_CLIPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmPedidos) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if (sCodigo <> '') and (sCodigo <> '0') then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmPedidos.BuscarCliente(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidos.btnCODIGO_EMPKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMPPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPedidos.btnCODIGO_CLIKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_CLIPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPedidos.cxgrdcPedLinARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloPedido;
  if sCodigo <> '' then
    AplicarArticuloPedido(sCodigo);
end;

procedure TfrmMtoPedidos.cxgrdcPedLinARTPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloPedido(sCodigo);
      if Assigned(dmmPedidos) and dmmPedidos.unqryPedidosLineas.Active and
         (dmmPedidos.unqryPedidosLineas.
            FindField('CODIGO_ART_PEDLIN') <> nil) then
        DisplayValue := dmmPedidos.unqryPedidosLineas.
                          FieldByName('CODIGO_ART_PEDLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPedidos.cxgrdcPedLinSKUPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloPedido(sCodigo);
      if Assigned(dmmPedidos) and dmmPedidos.unqryPedidosLineas.Active and
         (dmmPedidos.unqryPedidosLineas.
            FindField('CODIGOPRODPS_PEDLIN') <> nil) then
        DisplayValue := dmmPedidos.unqryPedidosLineas.
                          FieldByName('CODIGOPRODPS_PEDLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPedidos.cxgrdcPedLinSKUPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaPedido;
  sSku := BuscarSkuPedido(sArt);
  if sSku <> '' then
    AplicarArticuloPedido(sSku);
end;

procedure TfrmMtoPedidos.ValidarClienteParaLineas;
var
  sCliente: string;
begin
  sCliente := Trim(dmmPedidos.unqryTablaG.FieldByName(
    'CODIGO_CLI_PED').AsString);
  if not dmmPedidos.ClienteExiste(sCliente) then
  begin
    if (sCliente = '') or (sCliente = '0') then
      MessageDlg(SErrorClienteNoSeleccionadoPedidoVenta,
        mtWarning, [mbOk], 0)
    else
      MessageDlg(Format(SErrorClientePedidoVentaNoExiste, [sCliente]),
        mtWarning, [mbOk], 0);
    pcCab.ActivePage := tsCabecera;
    if btnCODIGO_CLI.CanFocus then
      btnCODIGO_CLI.SetFocus;
    Abort;
  end;
end;

procedure TfrmMtoPedidos.AsegurarCabeceraPersistidaParaLineas;
var
  oConfiguracion: TConfiguracionDocumento;
begin
  if not Assigned(dmmPedidos) then
    raise Exception.Create(SErrorPedidoVentaNoInicializado)
  else
  begin
    oConfiguracion := ConfiguracionPersistenciaDocumento(
      SErrorCrearSeleccionarPedidoAntesLineas);
    oConfiguracion.CampoProductoLinea :=
      'CODIGOPRODPS_PEDLIN';
    oConfiguracion.RecrearLineaVacia := True;
    AsegurarCabeceraPersistidaDocumento(
      dmmPedidos.unqryTablaG, dmmPedidos.unqryPedidosLineas,
      oConfiguracion, ValidarClienteParaLineas);
  end;
end;

procedure TfrmMtoPedidos.AsegurarPrimeraLineaPedido;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmPedidos) then
  begin
    dsCab := dmmPedidos.unqryTablaG;
    dsLin := dmmPedidos.unqryPedidosLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_PED').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_PED').AsString);
      if (sNumero <> '') and (sNumero <> '0') and (sSerie <> '') then
      begin
        if not dsLin.Active then
          dmmPedidos.AbrirDetalles;
        if dsLin.Active and dsLin.IsEmpty and
           not (dsLin.State in dsEditModes) then
        begin
          PrepararModoAltaLineas;
          dsLin.Append;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidos.PrepararModoAltaLineas;
var
  ds: TDataSet;
  function CampoVacio(const ACampo: string): Boolean;
  begin
    Result := Trim(ds.FieldByName(ACampo).AsString) = '';
  end;
  function LineaActualVacia: Boolean;
  begin
    Result := True;
    if (ds <> nil) and ds.Active then
      Result := CampoVacio('CODIGO_ART_PEDLIN') and
                CampoVacio('CODIGO_UNIDAD_PEDLIN') and
                CampoVacio('CODIGOPRODPS_PEDLIN');
  end;
begin
  ds := nil;
  if Assigned(dmmPedidos) then
    ds := dmmPedidos.unqryPedidosLineas;
  if (ds <> nil) and ds.Active and (ds.State = dsEdit) then
    ds.Post
  else if (ds <> nil) and ds.Active and (ds.State = dsInsert) and
          (not LineaActualVacia) then
    ds.Post;
  if FModoEntradaSel <> mcsAuto then
  begin
    FModoEntradaSel := mcsAuto;
    if FModoEntrada <> nil then
    begin
      ConstruirModoEntrada;
    end;
  end
  else if FModoEntrada = nil then
  begin
    ConstruirModoEntrada;
  end;
end;

procedure TfrmMtoPedidos.cxGrdPedidosLineasEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
  AsegurarPrimeraLineaPedido;
  AsegurarModoEntradaLineas(True);
end;

procedure TfrmMtoPedidos.cxGrdPedidosLineasExit(Sender: TObject);
var
  ds: TDataSet;
  bVacia: Boolean;
  function CampoVacio(const ANombre: string): Boolean;
  var
    Campo: TField;
  begin
    Result := True;
    Campo := ds.FindField(ANombre);
    if Campo <> nil then
      Result := Trim(Campo.AsString) = '';
  end;
begin
  inherited;
  // Al salir del grid hacia la cabecera, la linea vacia auto-anadida
  // (AsegurarPrimeraLineaPedido) se cancela. Si quedara en dsInsert,//
  // cualquier Edit de la cabecera (p.ej. elegir almacen) fuerza su Post
  // via CheckBrowseMode del master-detail y choca con la guarda de
  // linea sin articulo (bucle contador del 07/07/2026).
  if Assigned(dmmPedidos) then
  begin
    ds := dmmPedidos.unqryPedidosLineas;
    if Assigned(ds) and ds.Active and (ds.State = dsInsert) then
    begin
      bVacia := CampoVacio('CODIGO_ART_PEDLIN') and
                CampoVacio('CODIGO_UNIDAD_PEDLIN') and
                CampoVacio('CODIGOPRODPS_PEDLIN') and
                CampoVacio('CODBAR_ART_PEDLIN');
      if bVacia then
        ds.Cancel;
    end;
  end;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoPedidos.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, pcPedido.ActivePage = tsLineasPedido,
    FModoEntradaSel, [mcsAuto, mcsSku, mcsTallasHorPed],
    ConstruirModoEntrada);
  inherited;
end;

// "Expandir Filas" activa la vista de tres bandas por artículo:
// Pedido / A albaranar / Pendiente.
procedure TfrmMtoPedidos.btnExpandirFilasClick(Sender: TObject);
begin
  inherited;
  if dmmPedidos <> nil then
    CambiarModoEntradaDocumento(
      FModoEntradaSel, mcsTallasHorPed, ConstruirModoEntrada);
end;

procedure TfrmMtoPedidos.ConstruirModoEntrada;
var
  oConfiguracion: TConfigColumnasSku;
  oDataSet: TDataSet;
  oPlan: TPlanModoEntradaPedidoVenta;
begin
  if PuedeConstruirModoEntrada(oDataSet) then
  begin
    oPlan := CrearPlanModoEntrada;
    RetirarModoEntrada(oDataSet);
    if oPlan.DesempaquetarAtributos then
      dmmPedidos.DesempaquetarAtributosLineas;
    oConfiguracion := CrearConfiguracionModoEntrada(oDataSet);
    CrearModoEntradaSeleccionado(oConfiguracion);
    Supports(FModoEntrada, IPivoteVentaAlbaranar, FPivoteAlbaranar);
    Supports(FModoEntrada, IPivoteVentaBorrarGrupo, FPivoteBorrarGrupo);
    FColsModoConstruido := True;
    MontarColumnasModoEntrada(oPlan);
    AplicarPresentacionModoEntrada(oConfiguracion);
  end;
end;

function TfrmMtoPedidos.PuedeConstruirModoEntrada(
  out ADataSet: TDataSet): Boolean;
begin
  ADataSet := nil;
  Result := (dmmPedidos <> nil) and
    not (csDestroying in ComponentState);
  if Result then
  begin
    ADataSet := dmmPedidos.unqryPedidosLineas;
    Result := ADataSet.Active;
  end;
end;

function TfrmMtoPedidos.CrearPlanModoEntrada:
  TPlanModoEntradaPedidoVenta;
begin
  Result := CrearPlanModoResuelto(FModoEntradaSel);
end;

function TfrmMtoPedidos.CrearPlanModoResuelto(
  AModo: TModoColumnasSku): TPlanModoEntradaPedidoVenta;
var
  eModo: TModoPresentacionPedidoVenta;
begin
  case AModo of
    mcsSku:
      eModo := mpvSku;
    mcsTallasHorPed:
      eModo := mpvTallas;
    mcsDesglose:
      eModo := mpvDesglose;
  else
    eModo := mpvAutomatico;
  end;
  Result := CrearPlanModoEntradaPedidoVenta(eModo);
end;

procedure TfrmMtoPedidos.OcultarEditorModoEntrada;
begin
  if tvPedidosLineas.Controller.EditingController.IsEditing then
  begin
    try
      tvPedidosLineas.Controller.EditingController.HideEdit(False);
    except
      on E: Exception do
        RegistroLog.RegistrarAviso(
          'Pedidos.ConstruirModoEntrada: HideEdit ignorado: ' +
          E.Message);
    end;
  end;
end;

procedure TfrmMtoPedidos.SoltarFocoModoEntrada;
begin
  try
    tvPedidosLineas.Controller.FocusedItem := nil;
  except
    on E: Exception do
      RegistroLog.RegistrarAviso(
        'Pedidos.ConstruirModoEntrada: soltar FocusedItem ' +
        'fallo: ' + E.Message);
  end;
end;

procedure TfrmMtoPedidos.DesmontarModoAnterior;
begin
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      on E: Exception do
        RegistroLog.RegistrarAviso(
          'Pedidos.ConstruirModoEntrada: Desmontar fallo: ' +
          E.Message);
    end;
  end;
end;

procedure TfrmMtoPedidos.DesvincularOrigenLineas;
begin
  try
    tvPedidosLineas.DataController.DataSource := nil;
  except
    on E: Exception do
      RegistroLog.RegistrarAviso(
        'Pedidos.ConstruirModoEntrada: soltar DataSource ' +
        'fallo: ' + E.Message);
  end;
end;

procedure TfrmMtoPedidos.LimpiarVistaModoEntrada;
begin
  tvPedidosLineas.OnInitEdit := nil;
  tvPedidosLineas.OnEditKeyDown := nil;
  tvPedidosLineas.OnEditing := nil;
  tvPedidosLineas.OnFocusedRecordChanged := nil;
  tvPedidosLineas.OnFocusedItemChanged := nil;
  tvPedidosLineas.OnCustomDrawCell := nil;
  tvPedidosLineas.ClearItems;
  FPivoteAlbaranar := nil;
  FPivoteBorrarGrupo := nil;
  FModoEntrada := nil;
end;

procedure TfrmMtoPedidos.RetirarModoEntrada(ADataSet: TDataSet);
begin
  tvPedidosLineas.BeginUpdate;
  try
    OcultarEditorModoEntrada;
    SoltarFocoModoEntrada;
    DesmontarModoAnterior;
    DesvincularOrigenLineas;
    if ADataSet.State in dsEditModes then
      ADataSet.Cancel;
    LimpiarVistaModoEntrada;
  finally
    try
      tvPedidosLineas.DataController.DataSource :=
        dmmPedidos.dsPedidosLineas;
    except
      on E: Exception do
        // Sin DataSource el grid queda vacio: hay que saberlo.
        RegistroLog.RegistrarAviso(
          'Pedidos.ConstruirModoEntrada: restaurar DataSource ' +
          'fallo: ' + E.Message);
    end;
    tvPedidosLineas.EndUpdate;
  end;
end;

function TfrmMtoPedidos.CrearConfiguracionModoEntrada(
  ADataSet: TDataSet): TConfigColumnasSku;
begin
  Result := CrearConfigColumnasSkuDocumento(
    FContextoVentas.ColumnasSku, ContextoSesion,
    tvPedidosLineas, ADataSet, FModoEntradaSel,
    dmmPedidos.unqryTablaG.FieldByName(
      'CODIGO_ALM_PED').AsString, 'PEDLIN');
  Result.RegistroLog := RegistroLog;
  Result.BusquedaVisual := BusquedaVisual;
  Result.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Result.ValidadorArticulos := FContextoVentas.ValidadorArticulos;
  Result.LookupAtributos := FContextoVentas.AtributosArticulos;
  Result.ObtenerPrecioSku := PrecioSkuTallas;
end;

function TfrmMtoPedidos.CrearConfiguracionPivoteVenta:
  TGridPivoteVentaConfig;
begin
  Result := Default(TGridPivoteVentaConfig);
  Result.Conexion := dmmPedidos.unqryTablaG.Connection;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.SourceMaster := dsTablaG;
  Result.SourceLineas := dmmPedidos.dsPedidosLineas;
  Result.FieldSerieMaster := 'SERIE_PED';
  Result.FieldNumeroMaster := 'NUMERO_PED';
  Result.FieldLinea := 'LINEA_PEDLIN';
  Result.FieldArt := 'CODIGO_ART_PEDLIN';
  Result.FieldSku := 'CODIGO_UNIDAD_PEDLIN';
  Result.FieldDescripcion := 'DESCRIPCION_ARTICULO_PEDLIN';
  Result.FieldTipoCantidad := 'TIPO_CANTIDAD_ARTICULO_PEDLIN';
  Result.FieldCantidadPedida := 'CANTIDAD_PEDLIN';
  Result.FieldCantidadEntregada := 'CANTIDAD_ENTREGADA_PEDLIN';
  Result.FieldCantidadAAlbaranar := 'CANTIDAD_A_ALBARANAR_PEDLIN';
  Result.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN';
  Result.FieldAlmacen := 'CODIGO_ALMACEN_PEDLIN';
  Result.FieldAlmacenMaster := 'CODIGO_ALM_PED';
  Result.MaxColumnas := 20;
  Result.Repositorios := CrearRepositorioPivoteVenta(
    Result.Conexion, Result.Usuario, BusquedaVisual);
  Result.OnCrearLineaSku := PivoteVentaCrearLineaSku;
  Result.OnBandaCambiada := PivoteVentaBandaCambiada;
end;

procedure TfrmMtoPedidos.CrearModoEntradaSeleccionado(
  const AConfiguracion: TConfigColumnasSku);
var
  oConfiguracionPivote: TGridPivoteVentaConfig;
begin
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    oConfiguracionPivote := CrearConfiguracionPivoteVenta;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(
      AConfiguracion, oConfiguracionPivote);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(AConfiguracion);
end;

procedure TfrmMtoPedidos.MontarColumnasModoEntrada(
  const APlan: TPlanModoEntradaPedidoVenta);
begin
  if APlan.CrearColumnasAntes then
    CrearColumnasHostPedido;
  ConstruirModoEntradaDocumento(FModoEntrada, ModoEntradaResuelto,
    DesactivarEnterAsTabTemporal, RestaurarEnterAsTabTemporal,
    FModoEntradaSel, [], '');
  if not APlan.CrearColumnasAntes then
    CrearColumnasHostPedido;
end;

procedure TfrmMtoPedidos.AplicarPresentacionModoEntrada(
  const AConfiguracion: TConfigColumnasSku);
var
  oPlan: TPlanModoEntradaPedidoVenta;
begin
  tvPedidosLineas.OptionsBehavior.GoToNextCellOnEnter := True;
  tvPedidosLineas.OptionsBehavior.FocusCellOnTab := True;
  tvPedidosLineas.OptionsBehavior.FocusCellOnCycle := True;
  oPlan := CrearPlanModoResuelto(
    DetectarModoColumnasSku(AConfiguracion));
  if oPlan.TituloLineas <> '' then
    tsLineasPedido.Caption := oPlan.TituloLineas;
  if oPlan.MostrarBandaPedida then
    PivoteVentaBandaCambiada(bpvPedida)
  else if oPlan.MostrarAtributos then
    MostrarColumnasAtributoGlobalesPed;
end;

{
  El orden de montaje es deliberado: el pivote necesita las columnas del
  pedido antes de construir sus bandas; los modos planos las añaden después.
}
procedure TfrmMtoPedidos.CrearColumnasHostPedido;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvPedidosLineas.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
  procedure FormatearMoneda(ACol: TcxGridDBColumn);
  var
    Propiedades: TcxCurrencyEditProperties;
  begin
    ACol.PropertiesClass := TcxCurrencyEditProperties;
    Propiedades := TcxCurrencyEditProperties(ACol.Properties);
    Propiedades.DisplayFormat := '0.00 ' + #8364;
    Propiedades.UseDisplayFormatWhenEditing := True;
  end;
var
  ColCant, ColTipo, ColLinea, ColAAlbaranar, ColImpIncl: TcxGridDBColumn;
  PropiedadesCheck: TcxCheckBoxProperties;
begin
  // Columnas propias del pedido tras el ClearItems del contrato.
  ColLinea := Col('Línea', 'LINEA_PEDLIN', 60, False);
  Col('Descripción', 'DESCRIPCION_ARTICULO_PEDLIN', 220, False);
  if FModoEntradaSel <> mcsTallasHorPed then
  begin
    ColCant := Col('Pedida', 'CANTIDAD_PEDLIN', 80, True);
    ColTipo := Col('', 'TIPO_CANTIDAD_ARTICULO_PEDLIN', 20, False);
    ColTipo.Visible := False;
    ColTipo.VisibleForCustomization := False;
    // Decimales de la cantidad segun la unidad de la linea (metros...).
    VincularCantidadGrid(ColCant, ColTipo, UnidadesMedida);
    ColAAlbaranar := Col('A albaranar', 'CANTIDAD_A_ALBARANAR_PEDLIN',
                         95, True);
    VincularCantidadGrid(ColAAlbaranar, ColTipo, UnidadesMedida);
    Col('Pendiente', 'CANTIDAD_PENDIENTE_A_ALBARANAR_PEDLIN', 90, False);
  end;
  FormatearMoneda(Col('PVP S/IVA',
                      'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 90, True));
  FormatearMoneda(Col('PVP C/IVA',
                      'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 90, True));
  Col('Tarifa', 'CODIGO_TAR_PEDLIN', 70, False);
  ColImpIncl := Col('Imp. incl.', 'ESIMP_INCL_TARIFA_PEDLIN', 75, False);
  ColImpIncl.PropertiesClass := TcxCheckBoxProperties;
  PropiedadesCheck := TcxCheckBoxProperties(ColImpIncl.Properties);
  PropiedadesCheck.ReadOnly := True;
  PropiedadesCheck.ValueChecked := 'S';
  PropiedadesCheck.ValueUnchecked := 'N';
  FormatearMoneda(Col('Total', 'TOTAL_PEDLIN', 95, False));
  Col('Almacén', 'CODIGO_ALMACEN_PEDLIN', 75, True);
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
end;

procedure TfrmMtoPedidos.MostrarColumnasAtributoGlobalesPed;
begin
  AplicarNombresAtributosGlobalesDocumento(tvPedidosLineas,
    CrearColumnasDocumentoLecturas(
      dmmPedidos.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoPedidos.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo fiscal clasico del pedido (tarifa de cabecera,IVA,// precios,total
  // y CODIGOPRODPS para el albaraneado) se reaprovecha
  // tal cual: AplicarArticuloPedido acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloPedido(ASku);
end;

procedure TfrmMtoPedidos.btnAnadirLineaClick(Sender: TObject);
var
  ds: TDataSet;
  bVaciaEnInsercion: Boolean;
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  if not dmmPedidos.unqryPedidosLineas.Active then
    dmmPedidos.AbrirDetalles;
  ds := dmmPedidos.unqryPedidosLineas;
  PrepararModoAltaLineas;
  // Si ya hay una linea vacia en insercion (la auto-anadida al entrar
  // al grid o la recreada por AsegurarCabecera), se REUTILIZA: otro
  // Append postearia la vacia via CheckBrowseMode contra la guarda de
  // linea sin articulo.
  bVaciaEnInsercion := ds.Active and (ds.State = dsInsert) and
    (Trim(ds.FieldByName('CODIGO_ART_PEDLIN').AsString) = '') and
    (Trim(ds.FieldByName('CODIGO_UNIDAD_PEDLIN').AsString) = '') and
    (Trim(ds.FieldByName('CODIGOPRODPS_PEDLIN').AsString) = '');
  if not bVaciaEnInsercion then
    ds.Append;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoPedidos.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  // En modo tallas horizontales la fila del grid es un GRUPO
  // (articulo+color+precio) con una linea SKU real por talla: hay que
  // borrarlas TODAS via el pivote. Borrar solo el registro actual del
  // dataset dejaba vivas las demas tallas y la linea "reaparecia" al
  // refrescar (bug 09/07/26).
  if Assigned(FPivoteBorrarGrupo) then
  begin
    if MessageDlg(SPreguntaEliminarLineaPedidoVentaConTallas,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      FPivoteBorrarGrupo.BorrarGrupoActual;
  end
  else if MessageDlg(SPreguntaEliminarLineaPedidoVenta,
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    dmmPedidos.unqryPedidosLineas.Delete;
end;

procedure TfrmMtoPedidos.RellenarLineasAlEntregarTodo;
var
  ds: TDataSet;
  fCant, fEntr, fAAlbaranar: Double;
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  if Assigned(FPivoteAlbaranar) then
    FPivoteAlbaranar.MarcarTodoAAlbaranar
  else
  begin
    ds := dmmPedidos.unqryPedidosLineas;
    if not ds.Active then
      dmmPedidos.AbrirDetalles;
    if ds.Active then
    begin
      if ds.State in dsEditModes then
        ds.Post;
      bFiltrado := ds.Filtered;
      sLineaFoco := '';
      if (not ds.IsEmpty) and (ds.FindField('LINEA_PEDLIN') <> nil) then
        sLineaFoco := ds.FieldByName('LINEA_PEDLIN').AsString;
      ds.DisableControls;
      try
        try
          ds.Filtered := False;
          ds.First;
          while not ds.Eof do
          begin
            fCant := ds.FieldByName('CANTIDAD_PEDLIN').AsFloat;
            fEntr := ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
            fAAlbaranar := fCant - fEntr;
            if fAAlbaranar < 0 then
              fAAlbaranar := 0;
            if ds.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
            begin
              ds.Edit;
              ds.FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat :=
                fAAlbaranar;
              ds.Post;
            end;
            ds.Next;
          end;
        finally
          ds.Filtered := bFiltrado;
          if sLineaFoco <> '' then
            ds.Locate('LINEA_PEDLIN', sLineaFoco, []);
        end;
      finally
        ds.EnableControls;
      end;
      if Assigned(dmmPedidos) then
      begin
        dmmPedidos.CalcularTotalesPedido;
        ActualizarLabelPrendas;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidos.btnEntregarTodoClick(Sender: TObject);
begin
  inherited;
  if MessageDlg(SPreguntaMarcarLineasPendientesAlbaranar,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    RellenarLineasAlEntregarTodo;
end;

function TfrmMtoPedidos.LeerLineasParaAlbaran(
  ADataSet: TDataSet): TLineasPedidoParaAlbaran;
var
  bFiltrado: Boolean;
  iLinea: Integer;
  sLineaFoco: string;
begin
  SetLength(Result, 0);
  bFiltrado := ADataSet.Filtered;
  sLineaFoco := '';
  if (not ADataSet.IsEmpty) and
     (ADataSet.FindField('LINEA_PEDLIN') <> nil) then
    sLineaFoco := ADataSet.FieldByName('LINEA_PEDLIN').AsString;
  ADataSet.DisableControls;
  try
    try
      ADataSet.Filtered := False;
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        iLinea := Length(Result);
        SetLength(Result, iLinea + 1);
        Result[iLinea].Linea :=
          ADataSet.FieldByName('LINEA_PEDLIN').AsString;
        Result[iLinea].CodigoAlmacen :=
          ADataSet.FieldByName('CODIGO_ALMACEN_PEDLIN').AsString;
        Result[iLinea].CantidadEntregada :=
          ADataSet.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsCurrency;
        if ADataSet.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
          Result[iLinea].CantidadAAlbaranar := ADataSet.FieldByName(
            'CANTIDAD_A_ALBARANAR_PEDLIN').AsCurrency;
        ADataSet.Next;
      end;
    finally
      ADataSet.Filtered := bFiltrado;
      if sLineaFoco <> '' then
        ADataSet.Locate('LINEA_PEDLIN', sLineaFoco, []);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

function TfrmMtoPedidos.PrepararEntregasAlbaran(
  ADataSet: TDataSet): TPreparacionAlbaranPedido;
var
  EsAlmacenUnico: Boolean;
  iEntrega: Integer;
  oEntregas: TList<TPair<string, Currency>>;
  sAlmacenComun: string;
begin
  if Assigned(FPivoteAlbaranar) then
  begin
    Result := Default(TPreparacionAlbaranPedido);
    oEntregas := TList<TPair<string, Currency>>.Create;
    try
      EsAlmacenUnico := True;
      sAlmacenComun := '';
      FPivoteAlbaranar.VolcarAAlbaranar(
        oEntregas,
        sAlmacenComun,
        EsAlmacenUnico);
      SetLength(Result.Entregas, oEntregas.Count);
      for iEntrega := 0 to oEntregas.Count - 1 do
      begin
        Result.Entregas[iEntrega].Linea := oEntregas[iEntrega].Key;
        Result.Entregas[iEntrega].CantidadTotalEntregada :=
          oEntregas[iEntrega].Value;
      end;
      Result.AlmacenComun := sAlmacenComun;
      Result.EsAlmacenUnico := EsAlmacenUnico;
    finally
      FreeAndNil(oEntregas);
    end;
  end
  else
    Result := TPreparadorAlbaranPedido.Preparar(
      LeerLineasParaAlbaran(ADataSet));
end;

function TfrmMtoPedidos.PuedeCrearAlbaran(
  ADataSet: TDataSet): Boolean;
var
  sLineasSinSku: string;
begin
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  Result := Assigned(ADataSet) and ADataSet.Active and
    (ADataSet.RecordCount > 0);
  if not Result then
    ShowMessage(SErrorPedidoVentaSinLineas)
  else
  begin
    sLineasSinSku := LineasSinSkuRequerido(
      FContextoVentas.ValidadorArticulos,
      ADataSet,
      'PEDLIN');
    if sLineasSinSku <> '' then
      Result := MessageDlg(
        Format(SPreguntaCrearAlbaranPedidoVentaSinSku, [sLineasSinSku]),
        mtWarning,
        [mbYes, mbNo],
        0) = mrYes;
  end;
end;

function TfrmMtoPedidos.EjecutarCreacionAlbaran(
  const APreparacion: TPreparacionAlbaranPedido;
  const ACodigoAlmacen: string;
  AEsExistente: Boolean;
  const ASerieExistente, ANumeroExistente: string):
  TResultadoCreacionAlbaranPedido;
var
  Solicitud: TSolicitudCreacionAlbaranPedido;
begin
  Solicitud := Default(TSolicitudCreacionAlbaranPedido);
  Solicitud.SeriePedido := dmmPedidos.unqryTablaG.
    FieldByName('SERIE_PED').AsString;
  Solicitud.NumeroPedido := dmmPedidos.unqryTablaG.
    FieldByName('NUMERO_PED').AsString;
  Solicitud.CodigoAlmacen := ACodigoAlmacen;
  Solicitud.EsAlbaranExistente := AEsExistente;
  Solicitud.SerieAlbaranExistente := ASerieExistente;
  Solicitud.NumeroAlbaranExistente := ANumeroExistente;
  Solicitud.Entregas := APreparacion.Entregas;
  Result := FContextoVentas.CrearAlbaran.Ejecutar(Solicitud);
end;

procedure TfrmMtoPedidos.LimpiarCantidadesAAlbaranar(
  ADataSet: TDataSet);
var
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  if Assigned(FPivoteAlbaranar) then
    FPivoteAlbaranar.LimpiarAAlbaranar
  else if ADataSet.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
  begin
    bFiltrado := ADataSet.Filtered;
    sLineaFoco := '';
    if (not ADataSet.IsEmpty) and
       (ADataSet.FindField('LINEA_PEDLIN') <> nil) then
      sLineaFoco := ADataSet.FieldByName('LINEA_PEDLIN').AsString;
    ADataSet.DisableControls;
    try
      try
        ADataSet.Filtered := False;
        ADataSet.First;
        while not ADataSet.Eof do
        begin
          if ADataSet.FieldByName(
               'CANTIDAD_A_ALBARANAR_PEDLIN').AsCurrency <> 0 then
          begin
            ADataSet.Edit;
            ADataSet.FieldByName(
              'CANTIDAD_A_ALBARANAR_PEDLIN').AsCurrency := 0;
            ADataSet.Post;
          end;
          ADataSet.Next;
        end;
      finally
        ADataSet.Filtered := bFiltrado;
        if sLineaFoco <> '' then
          ADataSet.Locate('LINEA_PEDLIN', sLineaFoco, []);
      end;
    finally
      ADataSet.EnableControls;
    end;
  end;
end;

procedure TfrmMtoPedidos.MostrarAlbaranCreado(
  const AResultado: TResultadoCreacionAlbaranPedido;
  AEsExistente: Boolean;
  const ACodigoAlmacen: string);
var
  frmDocs: TfrmModalDocsCreados;
  sNumeroPedido: string;
  sSeriePedido: string;
begin
  sSeriePedido := dmmPedidos.unqryTablaG.
    FieldByName('SERIE_PED').AsString;
  sNumeroPedido := dmmPedidos.unqryTablaG.
    FieldByName('NUMERO_PED').AsString;
  frmDocs := TfrmModalDocsCreados.Create(Self);
  frmDocs.OnClose := nil;
  try
    if AEsExistente then
      frmDocs.lblTitulo.Caption := Format(
        'Líneas añadidas al albarán desde el pedido %s/%s',
        [sSeriePedido, sNumeroPedido])
    else
      frmDocs.lblTitulo.Caption := Format(
        'Albarán creado desde el pedido %s/%s',
        [sSeriePedido, sNumeroPedido]);
    frmDocs.Agregar(
      'Albarán',
      AResultado.Serie,
      AResultado.Numero,
      ACodigoAlmacen);
    frmDocs.ShowModal;
    if frmDocs.Confirmado then
      ShowMto(
        Self.Owner,
        'Albaranes',
        AResultado.Serie + ',' + AResultado.Numero);
  finally
    FreeAndNil(frmDocs);
  end;
end;

procedure TfrmMtoPedidos.CrearAlbaranDesdePedidoActivo;
var
  APreparacion: TPreparacionAlbaranPedido;
  ResultadoModal: TSelAlmacenAlbaranResult;
  ResultadoCreacion: TResultadoCreacionAlbaranPedido;
  ds: TDataSet;
  sEmpresa: string;
  sNumero: string;
  sSerie: string;
begin
  ds := dmmPedidos.unqryPedidosLineas;
  if PuedeCrearAlbaran(ds) then
  begin
    APreparacion := PrepararEntregasAlbaran(ds);
    if not APreparacion.TieneEntregas then
      ShowMessage(SErrorPedidoVentaSinCantidadAlbaranar)
    else
    begin
      sSerie := dmmPedidos.unqryTablaG.FieldByName('SERIE_PED').AsString;
      sNumero := dmmPedidos.unqryTablaG.FieldByName('NUMERO_PED').AsString;
      sEmpresa := dmmPedidos.unqryTablaG.
        FieldByName('CODIGO_EMP_PED').AsString;
      ResultadoModal := TfrmModalSelAlmacenAlbaran.Ejecutar(
        Self,
        sSerie,
        sNumero,
        sEmpresa,
        APreparacion.AlmacenDefecto);
      if ResultadoModal.Aceptado then
      begin
        ResultadoCreacion := EjecutarCreacionAlbaran(
          APreparacion,
          ResultadoModal.CodigoAlmacen,
          ResultadoModal.EsExistente,
          ResultadoModal.SerieAlb,
          ResultadoModal.NumeroAlb);
        if ResultadoCreacion.Creado then
        begin
          LimpiarCantidadesAAlbaranar(ds);
          MostrarAlbaranCreado(
            ResultadoCreacion,
            ResultadoModal.EsExistente,
            ResultadoModal.CodigoAlmacen);
        end
        else if ResultadoModal.EsExistente then
          ShowMessage(SErrorAnadirAlbaranDesdePedidoVenta)
        else
          ShowMessage(SErrorCrearAlbaranDesdePedidoVenta);
      end;
    end;
  end;
end;

procedure TfrmMtoPedidos.btnCrearAlbaranClick(Sender: TObject);
begin
  inherited;
  CrearAlbaranDesdePedidoActivo;
end;

procedure TfrmMtoPedidos.btnImportarPSClick(Sender: TObject);
var
  form: TfrmModalImportarPedidosPS;
begin
  inherited;
  if not PuedeAccionMto(apmInsertar) then
  begin
    ShowMessage(SErrorPermisoInsertarRegistro);
    Exit;
  end;
  form := TfrmModalImportarPedidosPS.Create(Self);
  try
    form.Configurar(dmmPedidos);
    form.ShowModal;
    dmmPedidos.unqryTablaG.Close;
    dmmPedidos.unqryTablaG.Open;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoPedidos.btnImprimirClick(Sender: TObject);
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Hook FastReport
end;

// "Ir a documento" (Ctrl+May+A) desde la pestania Albaranes del pedido:
// abre la ficha del albaran de venta seleccionado en la rejilla. Solo
// actua si esa pestania esta activa y hay un albaran en la fila actual.
procedure TfrmMtoPedidos.actIrDocumentoExecute(Sender: TObject);
begin
  inherited;
  if (pcPedido.ActivePage = tsAlbaranes) and
     (dmmPedidos <> nil) and
     dmmPedidos.unqryAlbaranes.Active and
     (not dmmPedidos.unqryAlbaranes.IsEmpty) then
    ShowMtoDocumentoDataSet(Self.Owner, 'Albaranes',
      dmmPedidos.unqryAlbaranes,
      'SERIE_ALB', 'NUMERO_ALB');
end;

initialization
  RegistrarPantalla(TfrmMtoPedidos);
  ForceReferenceToClass(TfrmMtoPedidos);

end.
