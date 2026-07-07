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
    procedure btnImprimirClick(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure cbbSERIE_PEDPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMPPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure btnCODIGO_CLIPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure btnCODIGO_EMPPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_ALM_PEDPropertiesEditValueChanged(Sender: TObject);
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
    // Handler original de unqryPedidosLineas.AfterPost (el que traia el DM)
    // guardado para no perder su logica al encadenar el refresco del label
    // de prendas. Ver unqryLineasAfterPostHook.
    FOldLineasAfterPost: TDataSetNotifyEvent;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal; Auto por
    // defecto. El Construir hace ClearItems: las columnas del dfm
    // mueren y las propias se recrean en runtime (patron de DTR e
    // inventarios).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
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
    // pedido aplicaria al SKU (tarifa del cliente, fecha del pedido),
    // para que la consolidacion del escaneo separe lineas por precio.
    function PrecioSkuTallas(const ACodigoArticulo,
                             ACodigoSku: string): Double;
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaPedido;
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
  inLibShowMto, inLibGlobalVar, inLibFiltroUsuario, Uni, inLibArticulosResolver,
  inLibArticulosValidador, inLibVentasImpuestos, inLibtb,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

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
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
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
  rPrecioSiva: Double;
  rPorIva    : Double;

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

  function PorcentajeIva(const ATipoIva: string): Double;
  var
    sTipo: string;
  begin
    sTipo := UpperCase(Trim(ATipoIva));
    if sTipo = 'R' then
      Result := dmmPedidos.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAR_PED').AsFloat
    else if sTipo = 'S' then
      Result := dmmPedidos.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAS_PED').AsFloat
    else if sTipo = 'E' then
      Result := dmmPedidos.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAE_PED').AsFloat
    else
      Result := dmmPedidos.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAN_PED').AsFloat;
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
            rPorIva := PorcentajeIva(Datos.TipoIVA);
            rPrecioSiva := Precio.PrecioFinal;
            if Precio.EsImpIncl and ((1 + rPorIva / 100) <> 0) then
              rPrecioSiva := Precio.PrecioFinal / (1 + rPorIva / 100);
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
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 0)
            else
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', rPrecioSiva);
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
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipoIva));
  if sTipo = 'R' then
    Result := dmmPedidos.unqryTablaG.
                FieldByName('PORCENTAJE_IVAR_PED').AsFloat
  else if sTipo = 'S' then
    Result := dmmPedidos.unqryTablaG.
                FieldByName('PORCENTAJE_IVAS_PED').AsFloat
  else if sTipo = 'E' then
    Result := dmmPedidos.unqryTablaG.
                FieldByName('PORCENTAJE_IVAE_PED').AsFloat
  else
    Result := dmmPedidos.unqryTablaG.
                FieldByName('PORCENTAJE_IVAN_PED').AsFloat;
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
  if ABanda = bpvEntregada then
    tsLineasPedido.Caption := '&1_Líneas [Tallas horiz. entregada]'
  else
    tsLineasPedido.Caption := '&1_Líneas [Tallas horiz. pedida]';
end;

procedure TfrmMtoPedidos.FormCreate(Sender: TObject);
var
  colEnt, colPend, colSku: TcxGridDBColumn;
  stEnt, stPend: TcxStyle;
begin
  inherited;
  // Contrato de entrada ColumnSKUcxGrid: Auto por defecto (resuelve a
  // desglose); F1 cicla los modos con las lineas a la vista.
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
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_PED', 'CODIGO_ALM_PED', '');
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
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PED);
  dmmPedidos.unqryPedidosLineas.MasterSource := dsTablaG;
  dmmPedidos.unqryAlbaranes.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_PED;NUMERO_PED';
  // Total de prendas (pestana Totales): se recalcula tras cada Post de
  // linea y al navegar entre pedidos. Se conserva el handler original
  // (el que trae el DM) encadenandolo desde unqryLineasAfterPostHook.
  FOldLineasAfterPost := dmmPedidos.unqryPedidosLineas.AfterPost;
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
    ActualizarLabelPrendas;
    // Contrato de entrada: al navegar de pedido, las lineas llegan
    // recargadas por el master-detail SIN atributos desempaquetados
    // (misma leccion que inventarios: si no, Color/Talla en blanco).
    if FColsModoConstruido and (FModoEntradaSel <> mcsSku) and
       (dmmPedidos <> nil) then
      dmmPedidos.DesempaquetarAtributosLineas;
  end;
end;

procedure TfrmMtoPedidos.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidos.btnGrabarClick(Sender: TObject);
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmPedidos.CalcularTotalesPedido;
    dsTablaG.DataSet.Post;
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
    dsLin.Append;
end;

procedure TfrmMtoPedidos.cxGrdPedidosLineasEnter(Sender: TObject);
begin
  AsegurarPrimeraLineaPedido;
  // Contrato de entrada: primera construccion al entrar en el grid
  // (las lineas ya estan abiertas como detail del pedido).
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
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
end;

procedure TfrmMtoPedidos.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // F1: alterna Auto (desglose) -> SKU -> Tallas horizontal con las
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
  if tvPedidosLineas.Controller.EditingController.IsEditing then
    try
      tvPedidosLineas.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        ;
    end;
  if ds.State in dsEditModes then
    ds.Cancel;
  if FModoEntrada <> nil then
    FModoEntrada.Desmontar;
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
    CfgPV.Usuario := oUser;
    CfgPV.SourceMaster := dsTablaG;
    CfgPV.SourceLineas := dmmPedidos.dsPedidosLineas;
    CfgPV.FieldSerieMaster := 'SERIE_PED';
    CfgPV.FieldNumeroMaster := 'NUMERO_PED';
    CfgPV.FieldLinea := 'LINEA_PEDLIN';
    CfgPV.FieldArt := 'CODIGO_ART_PEDLIN';
    CfgPV.FieldSku := 'CODIGO_UNIDAD_PEDLIN';
    CfgPV.FieldDescripcion := 'DESCRIPCION_ARTICULO_PEDLIN';
    CfgPV.FieldCantidadPedida := 'CANTIDAD_PEDLIN';
    CfgPV.FieldCantidadEntregada := 'CANTIDAD_ENTREGADA_PEDLIN';
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
var
  ColCant, ColTipo, ColLinea: TcxGridDBColumn;
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
    Col('Entregada', 'CANTIDAD_ENTREGADA_PEDLIN', 90, False);
    Col('Pendiente', 'CANTIDAD_PENDIENTE_PEDLIN', 90, False);
  end;
  Col('PVP S/IVA', 'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 90, True);
  Col('PVP C/IVA', 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 90, True);
  Col('Total', 'TOTAL_PEDLIN', 95, False);
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
  // El flujo fiscal clasico del pedido (tarifa del cliente, IVA,
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
  if MessageDlg('¿Está seguro de que desea eliminar esta línea?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    dmmPedidos.unqryPedidosLineas.Delete;
end;

procedure TfrmMtoPedidos.RellenarLineasAlEntregarTodo;
var
  ds: TDataSet;
  fCant, fEntr: Double;
  bFiltrado: Boolean;
  sLineaFoco: string;
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
          if fEntr < fCant then
          begin
            ds.Edit;
            ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := fCant;
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

procedure TfrmMtoPedidos.btnEntregarTodoClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Marcar todas las líneas como entregadas en su totalidad?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    RellenarLineasAlEntregarTodo;
end;

procedure TfrmMtoPedidos.btnCrearAlbaranClick(Sender: TObject);
var
  ds: TDataSet;
  lst: TList<TPair<string, Currency>>;
  par: TPair<string, Currency>;
  fEntrPend: Double;
  sNumeroAlb, sSerieAlb: string;
  sEmpresa, sSerie, sNumero, sAlm, sAlmComun, sAlmDefecto: string;
  EsAlmacenUnico, bAlmInit: Boolean;
  res: TSelAlmacenAlbaranResult;
  frmDocs: TfrmModalDocsCreados;
  bFiltrado, bOk: Boolean;
  sLineaFoco: string;
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
  lst := TList<TPair<string, Currency>>.Create;
  try
    // Mientras recogemos las líneas a entregar, vamos comprobando si
    // todas comparten almacén (CODIGO_ALMACEN_PEDLIN).
    EsAlmacenUnico := True;
    bAlmInit       := False;
    sAlmComun      := '';
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
          fEntrPend := ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
          if fEntrPend > 0 then
          begin
            par.Key   := ds.FieldByName('LINEA_PEDLIN').AsString;
            par.Value := fEntrPend;
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
    if lst.Count = 0 then
      ShowMessage(
        'No hay líneas con cantidad entregada para crear el albarán.')
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
