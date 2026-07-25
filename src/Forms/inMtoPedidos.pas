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
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoGen, dxSkinsCore, dxSkinBlue,
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
  inLibColumnasSkuIntf, inLibGridPivoteVenta;

type
  TfrmMtoPedidos = class(TfrmMtoGen)
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
    procedure AsegurarModoEntradaLineas(AMostrarEditor: Boolean);
    procedure ConstruirModoEntrada;
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
  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmPedidos: TdmPedidos;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoPedidos: TfrmMtoPedidos;

implementation

uses
  inMtoModalImportarPedidosPS, inLibFotos, inLibGridCantidad,
  inMtoModalSelAlmacenAlbaran, inMtoModalDocsCreados, inLibGenBusq,
  inLibShowMto, inLibFiltroUsuario, Uni, inLibArticulosResolver,
  inLibArticulosValidador, inLibVentasImpuestos, inLibtb,
  inLibGridTallasInline,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku;

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
    end;
    FModoEntrada := nil;
  end;
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
  CargarSeriesEmpresa(sEmpresa, 'PE', cbbSERIE_PED.Properties.Items);
  if cbbSERIE_PED.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de pedidos de venta mayor (tipo PE) ' +
                  'para la empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera de pedido. El articulo activo vive en
// la fila del sub-grid tvPedidosLineas (CODIGO_ART_PEDLIN /
// CODIGOPRODPS_PEDLIN, usado como SKU efectivo en venta mayor).
procedure TfrmMtoPedidos.ResolverArtSkuActivo(out ACodArt,
                                              ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvPedidosLineas.DataController.DataSource) then
  begin
    ds := tvPedidosLineas.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// pedido, ademas de dsTablaG (cabecera) enganchamos dsPedidosLineas.
function TfrmMtoPedidos.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmPedidos) then
    Result := [dsTablaG, dmmPedidos.dsPedidosLineas]
  else
    Result := [dsTablaG];
end;

function TfrmMtoPedidos.BuscarArticuloPedido: string;
var
  qry     : TUniQuery;
  Campo   : TField;
  sTarifa : string;
  dFecha  : TDateTime;
begin
  Result := '';
  if Assigned(dmmPedidos) then
  begin
    sTarifa := dmmPedidos.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_PED').AsString;
    dFecha := Date;
    if not dmmPedidos.unqryTablaG.FieldByName('FECHA_PED').IsNull then
      dFecha := dmmPedidos.unqryTablaG.FieldByName('FECHA_PED').AsDateTime;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmPedidos.unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT * ' +
        '  FROM vi_art_busquedas ' +
        ' WHERE (CODIGO_TAR_ARTTAR = :tarifa ' +
        '    OR CODIGO_TAR_ARTTAR IS NULL) ' +
        '   AND FECHA_DESDE_ARTTAR < :fecha ' +
        '   AND (FECHA_HASTA_ARTTAR IS NULL ' +
        '        OR FECHA_HASTA_ARTTAR > :fecha)';
      qry.ParamByName('tarifa').AsString := sTarifa;
      qry.ParamByName('fecha').AsDateTime := dFecha;
      if TBusquedaUtils.EjecutarBusqueda(
           'Búsqueda de Artículos en Líneas de Pedido',
           qry,
           'frmMtoArtFacSearch',
           Self) then
      begin
        Campo := qry.FindField('CODIGO_ART_ART');
        if Campo = nil then
          Campo := qry.FindField('CODIGO_ART');
        if Campo <> nil then
          Result := Campo.AsString;
      end;
    finally
      FreeAndNil(qry);
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
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmPedidos) then
    MessageDlg('No está abierto el pedido de venta.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmPedidos.unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU, ' +
        '       GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
        '                    AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS ' +
        '  FROM fza_articulos_skus SK ' +
        '  LEFT JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  LEFT JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = SA.ID_AV_SA ' +
        '  LEFT JOIN fza_variaciones_atributos VA ' +
        '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
        '   AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
        ' WHERE SK.CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU ' +
        ' ORDER BY SK.CODIGO_UNIDAD_SKU';
      qry.ParamByName('art').AsString := sArt;
      if TBusquedaUtils.EjecutarBusqueda(
           'SKUs del artículo ' + sArt,
           qry,
           'frmMtoPedSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoPedidos.AplicarArticuloPedido(const ACodigoArt: string);
var
  ds         : TDataSet;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
  Datos      : TArticuloDatos;
  Precio     : TArticuloPrecio;
  sInput     : string;
  sTarifa    : string;
  dFecha     : TDateTime;

  procedure PonerString(const ACampo, AValor: string);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;

  procedure PonerFloat(const ACampo: string; AValor: Double);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsFloat := AValor;
  end;

  procedure EnfocarSku(AAbrirBusqueda: Boolean);
  var
    ColSku: TcxGridDBColumn;
  begin
    ColSku := tvPedidosLineas.GetColumnByFieldName('CODIGOPRODPS_PEDLIN');
    if ColSku <> nil then
    begin
      ColSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvPedidosLineas.Controller.FocusedColumn := ColSku;
          tvPedidosLineas.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            cxgrdcPedLinSKUPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmPedidos) and
     (not FAplicandoArticulo) then
  begin
    ds := dmmPedidos.unqryPedidosLineas;
    if Assigned(ds) and ds.Active then
    begin
      FAplicandoArticulo := True;
      Validador := nil;
      Resolver := nil;
      try
        if ds.IsEmpty then
          ds.Append;
        if not (ds.State in dsEditModes) then
          ds.Edit;
        sTarifa := dmmPedidos.unqryTablaG.
                     FieldByName('TARIFA_ARTICULO_CLIENTE_PED').AsString;
        dFecha := Date;
        if not dmmPedidos.unqryTablaG.FieldByName('FECHA_PED').IsNull then
          dFecha := dmmPedidos.unqryTablaG.
                      FieldByName('FECHA_PED').AsDateTime;
        Validador := TArticulosValidador.Create(
                       dmmPedidos.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmPedidos.unqryTablaG.Connection);
        Resolucion := Validador.Resolver(sInput);
        if Resolucion.Encontrado then
        begin
          Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo,
                                          Resolucion.CodigoSku,
                                          sTarifa,
                                          dFecha);
          if Datos.Encontrado then
          begin
            if Datos.RequiereSku then
              Precio := Resolver.ResolverPrecio(Datos.CodigoArticulo, '',
                                                sTarifa, dFecha)
            else
              Precio := Datos.PrecioPedido;
            PonerString('CODIGO_ART_PEDLIN', Datos.CodigoArticulo);
            PonerString('CODIGOPRODPS_PEDLIN', Datos.CodigoSku);
            if Resolucion.CodigoBarrasMatch <> '' then
              PonerString('CODBAR_ART_PEDLIN', Resolucion.CodigoBarrasMatch);
            PonerString('CODIGO_FAM_PEDLIN', Datos.CodigoFamilia);
            PonerString('NOMBRE_FAM_PEDLIN', Datos.DescripcionFamilia);
            PonerString('DESCRIPCION_ARTICULO_PEDLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_PEDLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_PEDLIN', Datos.TipoIVA);
            PonerString('CODIGO_TAR_PEDLIN', sTarifa);
            if Precio.EsImpIncl then
              PonerString('ESIMP_INCL_TARIFA_PEDLIN', 'S')
            else
              PonerString('ESIMP_INCL_TARIFA_PEDLIN', 'N');
            if Datos.RequiereSku then
            begin
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 0);
              PonerFloat('PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 0);
            end
            else if Precio.EsImpIncl then
            begin
              // La rutina fiscal toma este PVP bruto como precio maestro.
              PonerFloat('PRECIO_VENTA_CIVA_ARTICULO_PEDLIN',
                         Precio.PrecioFinal);
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 0);
            end
            else
            begin
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN',
                         Precio.PrecioFinal);
              PonerFloat('PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 0);
            end;
            PrepararLineaFiscalVenta(dmmPedidos.unqryTablaG.Connection,
              dmmPedidos.unqryTablaG, ds, 'PED', 'PEDLIN', 'TOTAL_PEDLIN');
            if Datos.RequiereSku then
              EnfocarSku(True);
          end
          else if Datos.Mensaje <> '' then
            MessageDlg(Datos.Mensaje, mtWarning, [mbOk], 0);
        end
        else if Resolucion.Mensaje <> '' then
          MessageDlg(Resolucion.Mensaje, mtWarning, [mbOk], 0);
      finally
        FreeAndNil(Resolver);
        FreeAndNil(Validador);
        FAplicandoArticulo := False;
      end;
    end;
  end;
end;

function TfrmMtoPedidos.PorcentajeIvaPedido(const ATipoIva: string): Double;
begin
  Result := PorcentajeIvaDocumentoVenta(
    dmmPedidos.unqryTablaG.Connection, dmmPedidos.unqryTablaG,
    'PED', ATipoIva);
end;

function TfrmMtoPedidos.PrecioSkuTallas(const ACodigoArticulo,
  ACodigoSku: string): Double;
var
  Resolver: TArticulosResolver;
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
    Resolver := TArticulosResolver.Create(
                  dmmPedidos.unqryTablaG.Connection);
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
      FreeAndNil(Resolver);
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
  colEnt, colPend, colSku: TcxGridDBColumn;
  stEnt, stPend: TcxStyle;
begin
  inherited;
  // Contrato de entrada ColumnSKUcxGrid: Auto por defecto; F1 permite
  // pasar a SKU o a tallas horizontales cuando el pedido ya esta en SKU.
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  tsTotales.TabVisible := True;
  tsTotales.Enabled := True;
  if Trim(tsTotales.Caption) = '' then
    tsTotales.Caption := '&2_Totales';
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvPedidosLineas.GetColumnByFieldName('CANTIDAD_PEDLIN'),
    tvPedidosLineas.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_PEDLIN'));
  colSku := tvPedidosLineas.GetColumnByFieldName('CODIGOPRODPS_PEDLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := cxgrdcPedLinSKUPropertiesButtonClick;
      OnValidate := cxgrdcPedLinSKUPropertiesValidate;
    end;
  end;

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

function TfrmMtoPedidos.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroEmpAlmCaja(ContextoSesion, 'CODIGO_EMP_PED', 'CODIGO_ALM_PED', '');
end;

procedure TfrmMtoPedidos.CrearTablaPrincipal;
begin
  inherited;
  // Tomamos la instancia creada por TfrmMtoGen.CrearTablaPrincipal. Antes
  // este form creaba otro TdmPedidos en FormCreate; la carga async abria el
  // DM del padre y el grid quedaba enlazado al segundo DM, con las lineas
  // cerradas al pulsar "Añadir linea".
  dmmPedidos := (tdmDataModule as TdmPedidos);
  if not Assigned(dmmPedidos) then
  begin
    dmmPedidos := TdmPedidos.Create(Self);
    dsTablaG.DataSet := dmmPedidos.unqryTablaG;
    tdmDataModule := dmmPedidos;
  end;
  tvPedidosLineas.DataController.DataSource := dmmPedidos.dsPedidosLineas;
  cxGrdPedidosLineas.OnEnter := cxGrdPedidosLineasEnter;
  cxGrdPedidosLineas.OnExit := cxGrdPedidosLineasExit;
  tvAlbaranes.DataController.DataSource := dmmPedidos.dsAlbaranes;
  tvMensajes.DataController.DataSource := dmmPedidos.dsMensajes;
  cbbTotalesFORMA_PAGO_PED.Properties.ListSource := dmmPedidos.dsFormasPago;
  cbbCODIGO_ALM_PED.Properties.ListSource := dmmPedidos.dsAlmacenesPed;
  cbbTarifaPedido.Properties.ListSource := dmmPedidos.dsTarifas;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PED);
  DesactivarEnterAsTabEnCombo(cbbTarifaPedido);
  dmmPedidos.unqryPedidosLineas.MasterSource := dsTablaG;
  dmmPedidos.unqryAlbaranes.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_PED;NUMERO_PED';
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
  if (dmmPedidos <> nil) and Assigned(dmmPedidos.unqryTablaG) and
     dmmPedidos.unqryTablaG.Active and (not dmmPedidos.unqryTablaG.IsEmpty) then
    lblTotalPrendasPed.Caption :=
      FormatFloat('#,##0', dmmPedidos.TotalPrendasPedido)
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
    dmmPedidos.unqryTablaG.Connection,
    dmmPedidos.unqryPedidosLineas, 'PEDLIN');
  if (sLineasSinSku = '') or
     (MessageDlg('Las líneas ' + sLineasSinSku + ' tienen artículos ' +
                 'con variaciones sin SKU asignado. ' +
                 '¿Grabar de todas formas?',
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
      if TBusquedaUtils.EjecutarBusqueda(
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
      if TBusquedaUtils.EjecutarBusqueda(
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

procedure TfrmMtoPedidos.AsegurarCabeceraPersistidaParaLineas;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sCliente: string;
  sNumero: string;
  bReAppend: Boolean;

  function ValorLinea(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := dsLin.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function LineaActualVacia: Boolean;
  begin
    Result := (ValorLinea('CODIGO_ART_PEDLIN') = '') and
              (ValorLinea('CODIGOPRODPS_PEDLIN') = '');
  end;

  procedure SincronizarCabeceraEnLinea;
  begin
    if Assigned(dsLin) and dsLin.Active and
       (dsLin.State in dsEditModes) then
    begin
      if dsLin.FindField('NUMERO_PED_PEDLIN') <> nil then
        dsLin.FieldByName('NUMERO_PED_PEDLIN').AsString :=
          dsCab.FieldByName('NUMERO_PED').AsString;
      if dsLin.FindField('SERIE_PED_PEDLIN') <> nil then
        dsLin.FieldByName('SERIE_PED_PEDLIN').AsString :=
          dsCab.FieldByName('SERIE_PED').AsString;
    end;
  end;

begin
  if not Assigned(dmmPedidos) then
    raise Exception.Create('No esta inicializado el pedido.')
  else
  begin
    dsCab := dmmPedidos.unqryTablaG;
    dsLin := dmmPedidos.unqryPedidosLineas;
    if (dsCab = nil) or (not dsCab.Active) or
       (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
      raise Exception.Create(
        'Crea o selecciona un pedido antes de anadir lineas.');
    sCliente := Trim(dsCab.FieldByName('CODIGO_CLI_PED').AsString);
    if not dmmPedidos.ClienteExiste(sCliente) then
    begin
      if (sCliente = '') or (sCliente = '0') then
        MessageDlg('Debe seleccionar un cliente antes de añadir líneas.',
                   mtWarning, [mbOk], 0)
      else
        MessageDlg('El cliente ' + sCliente + ' no existe. Seleccione un ' +
                   'cliente válido antes de añadir líneas.',
                   mtWarning, [mbOk], 0);
      pcCab.ActivePage := tsCabecera;
      if btnCODIGO_CLI.CanFocus then
        btnCODIGO_CLI.SetFocus;
      Abort;
    end;
    sNumero := Trim(dsCab.FieldByName('NUMERO_PED').AsString);
    // La linea vacia en insercion (auto-anadida al entrar al grid) se
    // cancela SOLO si hay que postear la cabecera: ese Post arrastra
    // el suyo via CheckBrowseMode y choca con la guarda de linea sin
    // articulo. Se RECREA al final para que al usuario no le
    // "desaparezca" la linea que acababa de anadir.
    bReAppend := False;
    if (dsCab.State in dsEditModes) or (sNumero = '') or
       (sNumero = '0') then
    begin
      if Assigned(dsLin) and dsLin.Active and
         (dsLin.State = dsInsert) and LineaActualVacia then
      begin
        dsLin.Cancel;
        bReAppend := True;
      end;
      if not (dsCab.State in dsEditModes) then
        dsCab.Edit;
      dsCab.Post;
    end;
    SincronizarCabeceraEnLinea;
    if Assigned(dsLin) and dsLin.Active and
       (not (dsLin.State in dsEditModes)) then
    begin
      dsLin.Close;
      dsLin.Open;
    end;
    if bReAppend and Assigned(dsLin) and dsLin.Active and
       (not (dsLin.State in dsEditModes)) then
      dsLin.Append;
  end;
end;

procedure TfrmMtoPedidos.AsegurarPrimeraLineaPedido;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if not Assigned(dmmPedidos) then
    Exit;
  dsCab := dmmPedidos.unqryTablaG;
  dsLin := dmmPedidos.unqryPedidosLineas;
  if (dsCab = nil) or (dsLin = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    Exit;
  AsegurarCabeceraPersistidaParaLineas;
  sNumero := Trim(dsCab.FieldByName('NUMERO_PED').AsString);
  sSerie  := Trim(dsCab.FieldByName('SERIE_PED').AsString);
  if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
    Exit;
  if not dsLin.Active then
    dmmPedidos.AbrirDetalles;
  if dsLin.Active and dsLin.IsEmpty and
     (not (dsLin.State in dsEditModes)) then
  begin
    PrepararModoAltaLineas;
    dsLin.Append;
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
  // (AsegurarPrimeraLineaPedido) se cancela. Si quedara en dsInsert,
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
  // F1: alterna Tallas horizontal -> Auto (desglose) -> SKU con las
  // lineas del pedido a la vista.
  if (Key = VK_F1) and (Shift = []) and
     (pcPedido.ActivePage = tsLineasPedido) then
  begin
    Key := 0;
    case FModoEntradaSel of
      mcsAuto: FModoEntradaSel := mcsSku;
      mcsSku: FModoEntradaSel := mcsTallasHorPed;
    else
      FModoEntradaSel := mcsAuto;
    end;
    ConstruirModoEntrada;
  end;
  inherited;
end;

// "Expandir Filas" activa la vista de tres bandas por artículo:
// Pedido / A albaranar / Pendiente.
procedure TfrmMtoPedidos.btnExpandirFilasClick(Sender: TObject);
begin
  inherited;
  if (dmmPedidos <> nil) and (FModoEntradaSel <> mcsTallasHorPed) then
  begin
    FModoEntradaSel := mcsTallasHorPed;
    ConstruirModoEntrada;
  end;
end;

procedure TfrmMtoPedidos.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  i: Integer;
  ds: TDataSet;
begin
  if (dmmPedidos = nil) or (csDestroying in ComponentState) then
    Exit;
  ds := dmmPedidos.unqryPedidosLineas;
  if not ds.Active then
    Exit;
  // Teardown del modo anterior (patron DTR/inventarios).
  tvPedidosLineas.BeginUpdate;
  try
    if tvPedidosLineas.Controller.EditingController.IsEditing then
      try
        tvPedidosLineas.Controller.EditingController.HideEdit(False);
      except
        on E: Exception do
          ;
      end;
    try
      tvPedidosLineas.Controller.FocusedItem := nil;
    except
      on E: Exception do
        ;
    end;
    if FModoEntrada <> nil then
      try
        FModoEntrada.Desmontar;
      except
        on E: Exception do
          ;
      end;
    try
      tvPedidosLineas.DataController.DataSource := nil;
    except
      on E: Exception do
        ;
    end;
    if ds.State in dsEditModes then
      ds.Cancel;
    tvPedidosLineas.OnInitEdit := nil;
    tvPedidosLineas.OnEditKeyDown := nil;
    tvPedidosLineas.OnEditing := nil;
    tvPedidosLineas.OnFocusedRecordChanged := nil;
    tvPedidosLineas.OnFocusedItemChanged := nil;
    tvPedidosLineas.OnCustomDrawCell := nil;
    // Las columnas del modo saliente guardan handlers (OnGetProperties,
    // OnCustomDrawCell...) del objeto que se libera en la linea de abajo.
    // Se eliminan ANTES: el repintado que provoca DesempaquetarAtributos-
    // Lineas llamaria a un modo muerto (AV en ArtGetProperties 07/07/26).
    tvPedidosLineas.ClearItems;
    FModoEntrada := nil;
  finally
    try
      tvPedidosLineas.DataController.DataSource :=
        dmmPedidos.dsPedidosLineas;
    except
      on E: Exception do
        ;
    end;
    tvPedidosLineas.EndUpdate;
  end;
  // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
  // (columnas reales _PEDLIN; idempotente por linea).
  if FModoEntradaSel <> mcsSku then
    dmmPedidos.DesempaquetarAtributosLineas;
  Cfg := Default(TConfigColumnasSku);
  Cfg.Conexion := dmmPedidos.unqryTablaG.Connection;
  Cfg.View := tvPedidosLineas;
  Cfg.Cds := ds;
  Cfg.Modo := FModoEntradaSel;
  Cfg.AlmacenStock :=
    dmmPedidos.unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString;
  Cfg.Distribuido := False;
  Cfg.Campos.CodigoArt := 'CODIGO_ART_PEDLIN';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD_PEDLIN';
  Cfg.Campos.Descripcion := 'DESCRIPCION_ARTICULO_PEDLIN';
  Cfg.Campos.Cantidad := 'CANTIDAD_PEDLIN';
  Cfg.Campos.Almacen := 'CODIGO_ALMACEN_PEDLIN';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_PEDLIN';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR_PEDLIN';
    Cfg.Campos.AttrNombre[i] :=
      'ATTR' + IntToStr(i) + '_NOMBRE_PEDLIN';
  end;
  // Precio por SKU para la consolidacion del modo tallas: lineas con
  // precio distinto no fusionan.
  Cfg.ObtenerPrecioSku := PrecioSkuTallas;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := Default(TGridPivoteVentaConfig);
    CfgPV.Conexion := dmmPedidos.unqryTablaG.Connection;
    CfgPV.Usuario := IdentidadSesion.Usuario;
    CfgPV.SourceMaster := dsTablaG;
    CfgPV.SourceLineas := dmmPedidos.dsPedidosLineas;
    CfgPV.FieldSerieMaster := 'SERIE_PED';
    CfgPV.FieldNumeroMaster := 'NUMERO_PED';
    CfgPV.FieldLinea := 'LINEA_PEDLIN';
    CfgPV.FieldArt := 'CODIGO_ART_PEDLIN';
    CfgPV.FieldSku := 'CODIGO_UNIDAD_PEDLIN';
    CfgPV.FieldDescripcion := 'DESCRIPCION_ARTICULO_PEDLIN';
    CfgPV.FieldTipoCantidad := 'TIPO_CANTIDAD_ARTICULO_PEDLIN';
    CfgPV.FieldCantidadPedida := 'CANTIDAD_PEDLIN';
    CfgPV.FieldCantidadEntregada := 'CANTIDAD_ENTREGADA_PEDLIN';
    CfgPV.FieldCantidadAAlbaranar := 'CANTIDAD_A_ALBARANAR_PEDLIN';
    CfgPV.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN';
    CfgPV.FieldAlmacen := 'CODIGO_ALMACEN_PEDLIN';
    CfgPV.FieldAlmacenMaster := 'CODIGO_ALM_PED';
    CfgPV.MaxColumnas := 20;
    CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
    CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  FModoEntrada.OnResuelto := ModoEntradaResuelto;
  FModoEntrada.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FModoEntrada.OnSalirEdicion := RestaurarEnterAsTabTemporal;
  // El flag ANTES del Construir: si aborta a medias, nadie debe tocar
  // las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CrearColumnasHostPedido;
    FModoEntrada.Construir;
  end
  else
  begin
    FModoEntrada.Construir;
    CrearColumnasHostPedido;
  end;
  // Navegación tipo Excel en todos los modos de presentación.
  tvPedidosLineas.OptionsBehavior.GoToNextCellOnEnter := True;
  tvPedidosLineas.OptionsBehavior.FocusCellOnTab := True;
  tvPedidosLineas.OptionsBehavior.FocusCellOnCycle := True;
  case DetectarModoColumnasSku(Cfg) of
    mcsSku: tsLineasPedido.Caption := '&1_Líneas [SKU]';
    mcsTallasHorPed:
      PivoteVentaBandaCambiada(bpvPedida);
  else
    begin
      tsLineasPedido.Caption := '&1_Líneas [Desglose]';
      MostrarColumnasAtributoGlobalesPed;
    end;
  end;
end;

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
  begin
    ACol.PropertiesClass := TcxCurrencyEditProperties;
    with TcxCurrencyEditProperties(ACol.Properties) do
    begin
      DisplayFormat := '0.00 ' + #8364;
      UseDisplayFormatWhenEditing := True;
    end;
  end;
var
  ColCant, ColTipo, ColLinea, ColAAlbaranar, ColImpIncl: TcxGridDBColumn;
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
    VincularCantidadGrid(ColCant, ColTipo);
    ColAAlbaranar := Col('A albaranar', 'CANTIDAD_A_ALBARANAR_PEDLIN',
                         95, True);
    VincularCantidadGrid(ColAAlbaranar, ColTipo);
    Col('Pendiente', 'CANTIDAD_PENDIENTE_A_ALBARANAR_PEDLIN', 90, False);
  end;
  FormatearMoneda(Col('PVP S/IVA',
                      'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 90, True));
  FormatearMoneda(Col('PVP C/IVA',
                      'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 90, True));
  Col('Tarifa', 'CODIGO_TAR_PEDLIN', 70, False);
  ColImpIncl := Col('Imp. incl.', 'ESIMP_INCL_TARIFA_PEDLIN', 75, False);
  ColImpIncl.PropertiesClass := TcxCheckBoxProperties;
  with TcxCheckBoxProperties(ColImpIncl.Properties) do
  begin
    ReadOnly := True;
    ValueChecked := 'S';
    ValueUnchecked := 'N';
  end;
  FormatearMoneda(Col('Total', 'TOTAL_PEDLIN', 95, False));
  Col('Almacén', 'CODIGO_ALMACEN_PEDLIN', 75, True);
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
end;

procedure TfrmMtoPedidos.MostrarColumnasAtributoGlobalesPed;
var
  Qry: TUniQuery;
  i, iOrden: Integer;
  Col: TcxGridColumn;
begin
  // Nombres globales de atributos para ver Color/Talla desde el
  // principio (mismo helper que inventarios / DTR).
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := dmmPedidos.unqryTablaG.Connection;
    Qry.SQL.Text :=
      'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE,' +
      '       MIN(ORDEN_VA) AS ORDEN' +
      '  FROM fza_variaciones_atributos' +
      ' GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA)' +
      ' ORDER BY ORDEN, NOMBRE LIMIT 5';
    Qry.Open;
    iOrden := 1;
    while (not Qry.Eof) and (iOrden <= 5) do
    begin
      for i := 0 to tvPedidosLineas.ColumnCount - 1 do
      begin
        Col := tvPedidosLineas.Columns[i];
        if Col.Tag = iOrden then
        begin
          Col.Caption := Qry.FieldByName('NOMBRE').AsString;
          Col.Visible := True;
        end;
      end;
      Inc(iOrden);
      Qry.Next;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TfrmMtoPedidos.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo fiscal clasico del pedido (tarifa de cabecera, IVA,
  // precios, total y CODIGOPRODPS para el albaraneado) se reaprovecha
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
var
  BorradorGrupo: IPivoteVentaBorrarGrupo;
begin
  inherited;
  // En modo tallas horizontales la fila del grid es un GRUPO
  // (articulo+color+precio) con una linea SKU real por talla: hay que
  // borrarlas TODAS via el pivote. Borrar solo el registro actual del
  // dataset dejaba vivas las demas tallas y la linea "reaparecia" al
  // refrescar (bug 09/07/26).
  if Supports(FModoEntrada, IPivoteVentaBorrarGrupo, BorradorGrupo) then
  begin
    if MessageDlg('¿Está seguro de que desea eliminar esta línea ' +
                  '(todas sus tallas)?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      BorradorGrupo.BorrarGrupoActual;
  end
  else if MessageDlg('¿Está seguro de que desea eliminar esta línea?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    dmmPedidos.unqryPedidosLineas.Delete;
end;

procedure TfrmMtoPedidos.RellenarLineasAlEntregarTodo;
var
  ds: TDataSet;
  ModoAlbaranar: IPivoteVentaAlbaranar;
  fCant, fEntr, fAAlbaranar: Double;
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  if Supports(FModoEntrada, IPivoteVentaAlbaranar, ModoAlbaranar) then
    ModoAlbaranar.MarcarTodoAAlbaranar
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
  if MessageDlg('Marcar todas las líneas pendientes para albaranar?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    RellenarLineasAlEntregarTodo;
end;

procedure TfrmMtoPedidos.btnCrearAlbaranClick(Sender: TObject);
var
  ds: TDataSet;
  lst: TList<TPair<string, Currency>>;
  par: TPair<string, Currency>;
  ModoAlbaranar: IPivoteVentaAlbaranar;
  fEntrPend, fEntregadaReal: Double;
  sNumeroAlb, sSerieAlb: string;
  sEmpresa, sSerie, sNumero, sAlm, sAlmComun, sAlmDefecto: string;
  EsAlmacenUnico, bAlmInit: Boolean;
  res: TSelAlmacenAlbaranResult;
  frmDocs: TfrmModalDocsCreados;
  bFiltrado, bOk: Boolean;
  bUsaPivoteAlbaranar: Boolean;
  sLineaFoco: string;
  sLineasSinSku: string;
begin
  inherited;
  // Antes de crear, asegurar que el pedido esté guardado
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  ds := dmmPedidos.unqryPedidosLineas;
  if not ds.Active or (ds.RecordCount = 0) then
  begin
    ShowMessage('El pedido no tiene líneas');
    Exit;
  end;
  // Aviso: lineas con articulo con variaciones y sin SKU asignado no
  // pueden mover stock (los movimientos las saltan).
  sLineasSinSku := LineasSinSkuRequerido(
    dmmPedidos.unqryTablaG.Connection, ds, 'PEDLIN');
  if (sLineasSinSku <> '') and
     (MessageDlg('Las líneas ' + sLineasSinSku + ' tienen artículos ' +
                 'con variaciones sin SKU asignado y no moverán stock. ' +
                 '¿Crear el albarán de todas formas?',
                 mtWarning, [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  lst := TList<TPair<string, Currency>>.Create;
  try
    // Mientras recogemos las líneas a entregar, vamos comprobando si
    // todas comparten almacén (CODIGO_ALMACEN_PEDLIN).
    EsAlmacenUnico := True;
    bAlmInit       := False;
    sAlmComun      := '';
    bUsaPivoteAlbaranar :=
      Supports(FModoEntrada, IPivoteVentaAlbaranar, ModoAlbaranar);
    if bUsaPivoteAlbaranar then
      ModoAlbaranar.VolcarAAlbaranar(lst, sAlmComun, EsAlmacenUnico)
    else
    begin
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
            // Cantidad marcada para servir desde la pantalla. El proc
            // calcula la diferencia real frente a lo ya albaranado.
            if ds.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
              fEntrPend := ds.FieldByName(
                'CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat
            else
              fEntrPend := 0;
            if fEntrPend > 0 then
            begin
              fEntregadaReal :=
                ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
              par.Key   := ds.FieldByName('LINEA_PEDLIN').AsString;
              par.Value := fEntregadaReal + fEntrPend;
              lst.Add(par);
              sAlm := Trim(ds.FieldByName('CODIGO_ALMACEN_PEDLIN').AsString);
              if not bAlmInit then
              begin
                sAlmComun := sAlm;
                bAlmInit  := True;
              end
              else if sAlm <> sAlmComun then
                EsAlmacenUnico := False;
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
    end;
    if lst.Count = 0 then
      ShowMessage(
        'No hay líneas con cantidad a albaranar para crear el albarán.')
    else
    begin
      sSerie  := dmmPedidos.unqryTablaG.FieldByName('SERIE_PED').AsString;
      sNumero := dmmPedidos.unqryTablaG.FieldByName('NUMERO_PED').AsString;
      sEmpresa := dmmPedidos.unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString;
      // Si todas las líneas a entregar son del mismo almacén, ese sale
      // preseleccionado en el modal; si no, el combo va vacío y obliga
      // a elegir el almacén del albarán.
      if EsAlmacenUnico and (Trim(sAlmComun) <> '') then
        sAlmDefecto := sAlmComun
      else
        sAlmDefecto := '';
      res := TfrmModalSelAlmacenAlbaran.Ejecutar(Self, sSerie, sNumero,
                                                 sEmpresa, sAlmDefecto);
      if res.Aceptado then
      begin
        // Segun lo elegido en el modal: crear albaran nuevo o anadir las
        // lineas a un albaran ya existente del propio pedido.
        if res.EsExistente then
          bOk := dmmPedidos.CrearAlbaranDesdePedido(sNumeroAlb, sSerieAlb,
                                                    lst, res.CodigoAlmacen,
                                                    res.NumeroAlb,
                                                    res.SerieAlb)
        else
          bOk := dmmPedidos.CrearAlbaranDesdePedido(sNumeroAlb, sSerieAlb,
                                                    lst, res.CodigoAlmacen);
        if bOk then
        begin
          if bUsaPivoteAlbaranar then
            ModoAlbaranar.LimpiarAAlbaranar
          else if ds.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
          begin
            bFiltrado := ds.Filtered;
            sLineaFoco := '';
            if (not ds.IsEmpty) and
               (ds.FindField('LINEA_PEDLIN') <> nil) then
              sLineaFoco := ds.FieldByName('LINEA_PEDLIN').AsString;
            ds.DisableControls;
            try
              ds.Filtered := False;
              ds.First;
              while not ds.Eof do
              begin
                if ds.FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat <>
                   0 then
                begin
                  ds.Edit;
                  ds.FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat := 0;
                  ds.Post;
                end;
                ds.Next;
              end;
              ds.Filtered := bFiltrado;
              if sLineaFoco <> '' then
                ds.Locate('LINEA_PEDLIN', sLineaFoco, []);
            finally
              ds.EnableControls;
            end;
          end;
          // Mostrar el albaran creado / ampliado en un modal estilo
          // Sesiones, con boton "Ir a documento" para abrir su ficha.
          frmDocs := TfrmModalDocsCreados.Create(Self);
          // Bloqueamos el caFree del ancestro (FormClose lo pone) para
          // poder leer Confirmado tras ShowModal y liberarlo nosotros.
          frmDocs.OnClose := nil;
          try
            if res.EsExistente then
              frmDocs.lblTitulo.Caption :=
                Format('Lineas anadidas al albaran desde el pedido %s/%s',
                       [sSerie, sNumero])
            else
              frmDocs.lblTitulo.Caption :=
                Format('Albaran creado desde el pedido %s/%s',
                       [sSerie, sNumero]);
            frmDocs.Agregar('Albaran', sSerieAlb, sNumeroAlb,
                            res.CodigoAlmacen);
            frmDocs.ShowModal;
            if frmDocs.Confirmado then
              ShowMto(Self.Owner, 'Albaranes', sSerieAlb + ',' + sNumeroAlb);
          finally
            FreeAndNil(frmDocs);
          end;
        end
        else if res.EsExistente then
          ShowMessage('No se pudo anadir al albaran.')
        else
          ShowMessage('No se pudo crear el albaran.');
      end;
    end;
  finally
    FreeAndNil(lst);
  end;
end;

procedure TfrmMtoPedidos.btnImportarPSClick(Sender: TObject);
var
  form: TfrmModalImportarPedidosPS;
begin
  inherited;
  form := TfrmModalImportarPedidosPS.Create(Self);
  try
    form.dmPedidos := dmmPedidos;
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
var
  sSerie, sNumero: string;
begin
  inherited;
  if (pcPedido.ActivePage = tsAlbaranes) and
     (dmmPedidos <> nil) and
     dmmPedidos.unqryAlbaranes.Active and
     (not dmmPedidos.unqryAlbaranes.IsEmpty) then
  begin
    sSerie  := Trim(dmmPedidos.unqryAlbaranes.FieldByName(
                    'SERIE_ALB').AsString);
    sNumero := Trim(dmmPedidos.unqryAlbaranes.FieldByName(
                    'NUMERO_ALB').AsString);
    if (sSerie <> '') and (sNumero <> '') then
      ShowMto(Self.Owner, 'Albaranes', sSerie + ',' + sNumero);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoPedidos);

end.
