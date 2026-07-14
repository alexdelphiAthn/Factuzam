{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlbaranes                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de albaranes de venta.                                      }
{    Cabecera, lineas y datos fiscales sobre fza_albaranes.                    }
{******************************************************************************}
unit inMtoAlbaranes;

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
  cxSpinEdit, cxCurrencyEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, System.Generics.Collections,
  cxGridBandedTableView, cxGridDBBandedTableView, UniDataAlbaranes,
  System.Actions, Vcl.ActnList,
  inLibColumnasSkuIntf, inLibGridTallasInline;

type
  TfrmMtoAlbaranes = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    tsEmpresa: TcxTabSheet;
    tsDatosCliente: TcxTabSheet;
    tsEnvio: TcxTabSheet;
    pnlBotonesAcciones: TPanel;
    pnlBodyFicha: TPanel;
    pcAlbaran: TcxPageControl;
    tsLineasAlbaran: TcxTabSheet;
    tsFacturas: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tsObservaciones: TcxTabSheet;
    pnlBottomTotales: TPanel;
    cxgrdLineasAlbaran: TcxGrid;
    tvLineasAlbaran: TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    cxGrdFacturas: TcxGrid;
    tvFacturas: TcxGridDBTableView;
    cxGrdFacturasLevel: TcxGridLevel;
    cxGrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxGrdMovimientosLevel: TcxGridLevel;

    // Cabecera
    lblNroAlbaran: TcxLabel;
    txtNUMERO_ALB: TcxDBTextEdit;
    lblSerieAlbaran: TcxLabel;
    cbbSERIE_ALB: TcxDBComboBox;
    lblFechaAlbaran: TcxLabel;
    dteFECHA_ALB: TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_ALB: TcxDBTextEdit;
    lblPedidoOrigen: TcxLabel;
    txtNUMERO_PED_ALB: TcxDBTextEdit;
    txtSERIE_PED_ALB: TcxDBTextEdit;
    lblFacturaDestino: TcxLabel;
    txtNUMERO_FAC_ALB: TcxDBTextEdit;
    txtSERIE_FAC_ALB: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel;
    lblCodigoAlmacen: TcxLabel;
    cbbCODIGO_ALM_ALB: TcxDBLookupComboBox;
    lblCodigoCliente: TcxLabel;
    btnCODIGO_CLI_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel;
    lblTarifaAlbaran: TcxLabel;
    cbbTarifaAlbaran: TcxDBLookupComboBox;
    chkTarifaImpuestosIncluidosAlbaran: TcxDBCheckBox;

    // Empresa
    grpEmpresa: TcxGroupBox;
    lblNIFEmp: TcxLabel;
    txtNIF_EMPRESA_ALB: TcxDBTextEdit;
    lblMovEmp: TcxLabel;
    txtMOVIL_EMPRESA_ALB: TcxDBTextEdit;
    lblEmailEmp: TcxLabel;
    txtEMAIL_EMPRESA_ALB: TcxDBTextEdit;
    txtDIRECCION1_EMPRESA_ALB: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_ALB: TcxDBTextEdit;
    txtPOBLACION_EMPRESA_ALB: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_EMPRESA_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_EMPRESA_ALB: TcxDBTextEdit;

    // Cliente fiscal
    grpClienteFiscal: TcxGroupBox;
    txtRAZON_SOCIAL_CLIENTE_ALB: TcxDBTextEdit;
    txtNIF_CLIENTE_ALB: TcxDBTextEdit;
    txtEMAIL_CLIENTE_ALB: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ALB: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ALB: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ALB: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ALB: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ALB: TcxDBTextEdit;

    // Cliente envío
    grpClienteEnvio: TcxGroupBox;
    txtNOMBRE_CLI_ENVIO_ALB: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ENVIO_ALB: TcxDBTextEdit;

    // Totales
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    tsTotales: TcxTabSheet;
    scrTotales: TScrollBox;
    lblTotalesTotalBase: TcxLabel;
    curTotalesTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalesTotalImpuestos: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalesTotalPagar: TcxLabel;
    curTotalesTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_ALB: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_CLIENTE_ALB: TcxDBCheckBox;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasAlb: TcxLabel;
    grpDesgloseImpuestos: TGroupBox;
    lblTotalesPorIva: TcxLabel;
    lblTotalesTotalIva: TcxLabel;
    lblTotalesIVAN: TcxLabel;
    lblTotalesIVAR: TcxLabel;
    lblTotalesIVAS: TcxLabel;
    lblTotalesIVAE: TcxLabel;
    spnTotalesPORCENTAJE_IVAN_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_ALB: TcxDBSpinEdit;
    curTotalesTOTAL_IVAN_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAR_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAS_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAE_ALB: TcxDBCurrencyEdit;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de acción
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    btnFacturarSeleccionadas: TcxButton;
    btnFacturarTodo: TcxButton;
    btnFacturarPorFechas: TcxButton;
    // Boton + accion para saltar al pedido de venta de origen del
    // albaran (atajo Ctrl+May+A via actIrDocumento).
    btnIrDocumento: TcxButton;
    btnIrFacturaCreada: TcxButton;
    ActionList1: TActionList;
    actIrDocumento: TAction;
    actIrFacturaCreada: TAction;
    btnImprimir: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnFacturarSeleccionadasClick(Sender: TObject);
    procedure btnFacturarTodoClick(Sender: TObject);
    procedure btnFacturarPorFechasClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrFacturaCreadaExecute(Sender: TObject);
    procedure cbbSERIE_ALBPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_ALBPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_CLI_ALBPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_EMP_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_ALM_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure cbbTarifaAlbaranPropertiesChange(Sender: TObject);
    procedure btnCODIGO_CLI_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_ALBKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure btnCODIGO_CLI_ALBKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure cxgrdcArtAlbPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure cxgrdcArtAlbPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure cxgrdcArtAlbSkuPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure cxgrdLineasAlbaranEnter(Sender: TObject);
  private
    FBuscandoDatosCabecera: Boolean;
    FAplicandoArticulo: Boolean;
    // Handlers originales de unqryAlbaranesLineas.AfterPost/AfterDelete
    // (los que trae el DM) guardados para no perder su logica al
    // encadenar el refresco del label de prendas. Ver
    // unqryLineasAfterPostHook / unqryLineasAfterDeleteHook.
    FOldLineasAfterPost: TDataSetNotifyEvent;
    FOldLineasAfterDelete: TDataSetNotifyEvent;
    FOldLineasDataChange: TDataChangeEvent;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid (patron pedidos) ===
    // Modo seleccionado por el usuario (F1 cicla Auto/SKU/Tallas) y
    // modo montado sobre tvLineasAlbaran. FColsModoConstruido marca
    // que las columnas del dfm murieron en el ClearItems del contrato
    // y las rutas legacy no deben tocarlas.
    FModoEntradaSel: TModoColumnasSku;
    FModoEntrada: IModoEntradaGrid;
    FColsModoConstruido: Boolean;
    function BuscarArticuloAlbaran: string;
    function BuscarSkuAlbaran(const ACodigoArt: string): string;
    function ArticuloLineaActivaAlbaran: string;
    procedure AplicarArticuloAlbaran(const ACodigoArt: string);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaAlbaran;
    procedure cxgrdcArtAlbSkuPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure ActualizarColumnasOpcionalesLinea;
    // Pinta lblTotalPrendasAlb con el total de prendas (suma de
    // CANTIDAD_ALBLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterDeleteHook(DataSet: TDataSet);
    // Contrato ColumnSKUcxGrid: construccion del modo de entrada y
    // columnas propias del albaran tras el ClearItems del contrato.
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostAlbaran;
    procedure MostrarColumnasAtributoGlobalesAlb;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                ADescripcion: string; ACompleto: Boolean);
    // Porcentaje de IVA de la cabecera para un tipo (N/R/S/E).
    function PorcentajeIvaAlbaran(const ATipoIva: string): Double;
    // Contrato ObtenerPrecioSku del modo tallas: PVP C/IVA del SKU con
    // la tarifa de cabecera y la fecha del albaran.
    function PrecioSkuTallasAlb(const ACodigoArticulo,
                                ACodigoSku: string): Double;
    // Al salir del grid se cancela la linea vacia auto-anadida: si
    // quedara en dsInsert, cualquier Edit de la cabecera la postearia
    // via master-detail (leccion de pedidos).
    procedure cxgrdLineasAlbaranExit(Sender: TObject);
    // Hook OnDataChange de dsTablaG: al navegar entre albaranes
    // (Field=nil) hay que recalcular el total de prendas con las lineas
    // del albaran recien enfocado.
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure dsLineasDataChangeHook(Sender: TObject; Field: TField);
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
  protected
    // F1 alterna Auto (desglose) -> SKU -> Tallas horizontal con las
    // lineas del albaran a la vista.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmAlbaranes: TdmAlbaranes;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoAlbaranes: TfrmMtoAlbaranes;

implementation

uses
  inMtoModalFacturarAlbaranesFechas, inLibFotos, inLibGridCantidad,
  inLibGenBusq, inLibShowMto, inLibGlobalVar, inLibFiltroUsuario, Uni,
  inLibArticulosResolver, inLibArticulosValidador, inLibVentasImpuestos,
  inLibtb, inLibUser, inLibColumnasSku;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoAlbaranes.cbbSERIE_ALBPropertiesInitPopup(Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmAlbaranes <> nil) and dmmAlbaranes.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmAlbaranes.unqryTablaG.
                       FieldByName('CODIGO_EMP_ALB').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
  end;
  CargarSeriesEmpresa(sEmpresa, 'AV', cbbSERIE_ALB.Properties.Items);
  if cbbSERIE_ALB.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de albaranes de venta mayor (tipo AV) ' +
                  'para la empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera de albaran. El articulo activo vive en
// la fila del sub-grid tvLineasAlbaran (CODIGO_ART_ALBLIN /
// CODIGO_UNIDAD_ALBLIN).
procedure TfrmMtoAlbaranes.ResolverArtSkuActivo(out ACodArt,
                                                ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasAlbaran.DataController.DataSource) then
  begin
    ds := tvLineasAlbaran.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// albaran, ademas de dsTablaG (cabecera) enganchamos dsAlbaranesLineas.
function TfrmMtoAlbaranes.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmAlbaranes) then
    Result := [dsTablaG, dmmAlbaranes.dsAlbaranesLineas]
  else
    Result := [dsTablaG];
end;

function TfrmMtoAlbaranes.BuscarArticuloAlbaran: string;
var
  qry     : TUniQuery;
  Campo   : TField;
  sTarifa : string;
  dFecha  : TDateTime;
begin
  Result := '';
  if Assigned(dmmAlbaranes) then
  begin
    sTarifa := dmmAlbaranes.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    dFecha := Date;
    if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      dFecha := dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').AsDateTime;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmAlbaranes.unqryTablaG.Connection;
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
           'Búsqueda de Artículos en Líneas de Albarán',
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

function TfrmMtoAlbaranes.ArticuloLineaActivaAlbaran: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmAlbaranes) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_ALBLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString);
  end;
end;

function TfrmMtoAlbaranes.BuscarSkuAlbaran(
  const ACodigoArt: string): string;
var
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmAlbaranes) then
    MessageDlg('No está abierto el albarán de venta.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmAlbaranes.unqryTablaG.Connection;
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
           'frmMtoAlbSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoAlbaranes.AplicarArticuloAlbaran(const ACodigoArt: string);
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

  procedure LimpiarCampo(const ACampo: string);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.Clear;
  end;

  procedure EnfocarSku(AAbrirBusqueda: Boolean);
  var
    ColSku: TcxGridDBColumn;
  begin
    ColSku := tvLineasAlbaran.GetColumnByFieldName('CODIGO_UNIDAD_ALBLIN');
    if ColSku <> nil then
    begin
      ColSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasAlbaran.Controller.FocusedColumn := ColSku;
          tvLineasAlbaran.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            cxgrdcArtAlbSkuPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmAlbaranes) and
     (not FAplicandoArticulo) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
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
        sTarifa := dmmAlbaranes.unqryTablaG.
                     FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
        dFecha := Date;
        if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
          dFecha := dmmAlbaranes.unqryTablaG.
                      FieldByName('FECHA_ALB').AsDateTime;
        Validador := TArticulosValidador.Create(
                       dmmAlbaranes.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmAlbaranes.unqryTablaG.Connection);
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
            PonerString('CODIGO_ART_ALBLIN', Datos.CodigoArticulo);
            PonerString('CODIGO_UNIDAD_ALBLIN', Datos.CodigoSku);
            PonerString('DESCRIPCION_VARIACION_ALBLIN',
                        Datos.DescripcionSku);
            if not Datos.EsVariacion then
              LimpiarCampo('DESCRIPCION_VARIACION_ALBLIN');
            if not Datos.EsTrazable then
            begin
              LimpiarCampo('LOTE_ALBLIN');
              LimpiarCampo('FECHA_CADUCIDAD_ALBLIN');
            end;
            PonerString('CODIGO_FAM_ALBLIN', Datos.CodigoFamilia);
            PonerString('NOMBRE_FAM_ALBLIN', Datos.DescripcionFamilia);
            PonerString('DESCRIPCION_ARTICULO_ALBLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_ALBLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_ALBLIN', Datos.TipoIVA);
            PonerString('CODIGO_TAR_ALBLIN', sTarifa);
            if Precio.EsImpIncl then
              PonerString('ESIMP_INCL_TARIFA_ALBLIN', 'S')
            else
              PonerString('ESIMP_INCL_TARIFA_ALBLIN', 'N');
            if Datos.RequiereSku then
            begin
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN', 0);
              PonerFloat('PRECIO_VENTA_CIVA_ARTICULO_ALBLIN', 0);
            end
            else if Precio.EsImpIncl then
            begin
              // La rutina fiscal toma este PVP bruto como precio maestro.
              PonerFloat('PRECIO_VENTA_CIVA_ARTICULO_ALBLIN',
                         Precio.PrecioFinal);
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN', 0);
            end
            else
            begin
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN',
                         Precio.PrecioFinal);
              PonerFloat('PRECIO_VENTA_CIVA_ARTICULO_ALBLIN', 0);
            end;
            PrepararLineaFiscalVenta(dmmAlbaranes.unqryTablaG.Connection,
              dmmAlbaranes.unqryTablaG, ds, 'ALB', 'ALBLIN', 'TOTAL_ALBLIN');
            ActualizarColumnasOpcionalesLinea;
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

procedure TfrmMtoAlbaranes.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo fiscal clasico del albaran (tarifa de cabecera, IVA,
  // precios, total) se reaprovecha tal cual: AplicarArticuloAlbaran
  // acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloAlbaran(ASku);
end;

function TfrmMtoAlbaranes.PorcentajeIvaAlbaran(
  const ATipoIva: string): Double;
begin
  Result := PorcentajeIvaDocumentoVenta(
    dmmAlbaranes.unqryTablaG.Connection, dmmAlbaranes.unqryTablaG,
    'ALB', ATipoIva);
end;

function TfrmMtoAlbaranes.PrecioSkuTallasAlb(const ACodigoArticulo,
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
  if Assigned(dmmAlbaranes) and dmmAlbaranes.unqryTablaG.Active then
  begin
    sTarifa := dmmAlbaranes.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    dFecha := Date;
    if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      dFecha := dmmAlbaranes.unqryTablaG.
                  FieldByName('FECHA_ALB').AsDateTime;
    Resolver := TArticulosResolver.Create(
                  dmmAlbaranes.unqryTablaG.Connection);
    try
      Datos := Resolver.ResolverDatos(ACodigoArticulo, ACodigoSku,
                                      sTarifa, dFecha);
      if Datos.Encontrado then
      begin
        Precio := Datos.PrecioPedido;
        rPorIva := PorcentajeIvaAlbaran(Datos.TipoIVA);
        // FieldPrecioBase del albaran es el PVP C/IVA de la linea.
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

procedure TfrmMtoAlbaranes.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // F1: alterna Auto (desglose) -> SKU -> Tallas horizontal con las
  // lineas del albaran a la vista.
  if (Key = VK_F1) and (Shift = []) and
     (pcAlbaran.ActivePage = tsLineasAlbaran) then
  begin
    Key := 0;
    case FModoEntradaSel of
      mcsAuto: FModoEntradaSel := mcsSku;
      mcsSku: FModoEntradaSel := mcsTallasInline;
    else
      FModoEntradaSel := mcsAuto;
    end;
    ConstruirModoEntrada;
  end;
  inherited;
end;

procedure TfrmMtoAlbaranes.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgT: TGridTallasConfig;
  i: Integer;
  ds: TDataSet;
begin
  if (dmmAlbaranes = nil) or (csDestroying in ComponentState) then
    Exit;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  if not ds.Active then
    Exit;
  // Teardown del modo anterior (patron pedidos).
  if tvLineasAlbaran.Controller.EditingController.IsEditing then
    try
      tvLineasAlbaran.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        ;
    end;
  if ds.State in dsEditModes then
    ds.Cancel;
  if FModoEntrada <> nil then
    FModoEntrada.Desmontar;
  tvLineasAlbaran.OnInitEdit := nil;
  tvLineasAlbaran.OnEditKeyDown := nil;
  tvLineasAlbaran.OnEditing := nil;
  tvLineasAlbaran.OnFocusedRecordChanged := nil;
  tvLineasAlbaran.OnFocusedItemChanged := nil;
  // Las columnas del modo saliente guardan handlers del objeto que se
  // libera abajo: se eliminan ANTES para que ningun repintado llame a
  // un modo muerto (leccion de pedidos, AV 07/07/2026).
  tvLineasAlbaran.ClearItems;
  FModoEntrada := nil;
  // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
  // (columnas reales _ALBLIN; idempotente por comparacion).
  if FModoEntradaSel <> mcsSku then
    dmmAlbaranes.DesempaquetarAtributosLineas;
  Cfg := Default(TConfigColumnasSku);
  Cfg.Conexion := dmmAlbaranes.unqryTablaG.Connection;
  Cfg.View := tvLineasAlbaran;
  Cfg.Cds := ds;
  Cfg.Modo := FModoEntradaSel;
  Cfg.AlmacenStock :=
    dmmAlbaranes.unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString;
  Cfg.Distribuido := False;
  Cfg.Campos.CodigoArt := 'CODIGO_ART_ALBLIN';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD_ALBLIN';
  Cfg.Campos.Descripcion := 'DESCRIPCION_ARTICULO_ALBLIN';
  Cfg.Campos.Cantidad := 'CANTIDAD_ALBLIN';
  Cfg.Campos.Almacen := 'CODIGO_ALMACEN_ALBLIN';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_ALBLIN';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR_ALBLIN';
    Cfg.Campos.AttrNombre[i] :=
      'ATTR' + IntToStr(i) + '_NOMBRE_ALBLIN';
  end;
  // Precio por SKU para la consolidacion del modo tallas: lineas con
  // precio distinto no fusionan.
  Cfg.ObtenerPrecioSku := PrecioSkuTallasAlb;
  if FModoEntradaSel = mcsTallasInline then
  begin
    CfgT := Default(TGridTallasConfig);
    CfgT.Usuario := oUser;
    CfgT.Grid := tvLineasAlbaran;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmAlbaranes.dsAlbaranesLineas;
    CfgT.FieldSerieMaster := 'SERIE_ALB';
    CfgT.FieldNumeroMaster := 'NUMERO_ALB';
    CfgT.FieldLinea := 'LINEA_ALBLIN';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_ALBLIN';
    CfgT.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN';
    CfgT.FieldTotalUds := 'CANTIDAD_ALBLIN';
    CfgT.FieldTotalLinea := 'TOTAL_ALBLIN';
    CfgT.TablaCeldas := 'fza_albaranes_celdas';
    CfgT.FieldSerieCel := 'SERIE_ALB_ALBCEL';
    CfgT.FieldNumeroCel := 'NUMERO_ALB_ALBCEL';
    CfgT.FieldLineaCel := 'LINEA_ALBCEL';
    CfgT.FieldFilaCel := 'ID_FILA_ALBCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_ALBCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_ALBCEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := 20;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  FModoEntrada.OnResuelto := ModoEntradaResuelto;
  FModoEntrada.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FModoEntrada.OnSalirEdicion := RestaurarEnterAsTabTemporal;
  // El flag ANTES del Construir: si aborta a medias, nadie debe tocar
  // las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  FModoEntrada.Construir;
  CrearColumnasHostAlbaran;
  case DetectarModoColumnasSku(Cfg) of
    mcsSku: tsLineasAlbaran.Caption := 'Líneas [SKU]';
    mcsTallasInline:
      tsLineasAlbaran.Caption := 'Líneas [Tallas horiz.]';
  else
    begin
      tsLineasAlbaran.Caption := 'Líneas [Desglose]';
      MostrarColumnasAtributoGlobalesAlb;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.CrearColumnasHostAlbaran;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineasAlbaran.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
var
  ColCant, ColTipo, ColLinea, ColLote, ColCad: TcxGridDBColumn;
  ColImpIncl: TcxGridDBColumn;
  bHayTrazables: Boolean;
  ds: TDataSet;
  Bm: TBookmark;
begin
  // Columnas propias del albaran tras el ClearItems del contrato.
  ColLinea := Col('Línea', 'LINEA_ALBLIN', 60, False);
  Col('Descripción', 'DESCRIPCION_ARTICULO_ALBLIN', 220, False);
  ColCant := Col('Cantidad', 'CANTIDAD_ALBLIN', 80,
                 FModoEntradaSel <> mcsTallasInline);
  ColTipo := Col('', 'TIPO_CANTIDAD_ARTICULO_ALBLIN', 20, False);
  ColTipo.Visible := False;
  ColTipo.VisibleForCustomization := False;
  // Decimales de la cantidad segun la unidad de la linea (metros...).
  VincularCantidadGrid(ColCant, ColTipo);
  Col('PVP S/IVA', 'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN', 90, True);
  Col('PVP C/IVA', 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN', 90, True);
  Col('Tarifa', 'CODIGO_TAR_ALBLIN', 70, False);
  ColImpIncl := Col('Imp. incl.', 'ESIMP_INCL_TARIFA_ALBLIN', 75, False);
  ColImpIncl.PropertiesClass := TcxCheckBoxProperties;
  with TcxCheckBoxProperties(ColImpIncl.Properties) do
  begin
    ReadOnly := True;
    ValueChecked := 'S';
    ValueUnchecked := 'N';
  end;
  Col('Total', 'TOTAL_ALBLIN', 95, False);
  Col('Almacén', 'CODIGO_ALMACEN_ALBLIN', 75, True);
  ColLote := Col('Lote', 'LOTE_ALBLIN', 80, True);
  ColCad := Col('F. Caducidad', 'FECHA_CADUCIDAD_ALBLIN', 90, True);
  Col('Facturada', 'ESFACTURADA_ALBLIN', 60, False);
  // Lote / caducidad solo aplican a articulos trazables y el DM los
  // limpia en el resto: se muestran unicamente si alguna linea del
  // albaran trae valor (siguen disponibles en la personalizacion).
  bHayTrazables := False;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  if ds.Active and (not ds.IsEmpty) and
     (ds.FindField('LOTE_ALBLIN') <> nil) then
  begin
    Bm := ds.GetBookmark;
    ds.DisableControls;
    try
      ds.First;
      while (not ds.Eof) and (not bHayTrazables) do
      begin
        if (Trim(ds.FieldByName('LOTE_ALBLIN').AsString) <> '') or
           (not ds.FieldByName('FECHA_CADUCIDAD_ALBLIN').IsNull) then
          bHayTrazables := True;
        ds.Next;
      end;
      if ds.BookmarkValid(Bm) then
        ds.GotoBookmark(Bm);
    finally
      ds.EnableControls;
      ds.FreeBookmark(Bm);
    end;
  end;
  ColLote.Visible := bHayTrazables;
  ColCad.Visible := bHayTrazables;
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
end;

procedure TfrmMtoAlbaranes.MostrarColumnasAtributoGlobalesAlb;
var
  Qry: TUniQuery;
  i, iOrden: Integer;
  Col: TcxGridColumn;
begin
  // Nombres globales de atributos para ver Color/Talla desde el
  // principio (mismo helper que pedidos / inventarios).
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := dmmAlbaranes.unqryTablaG.Connection;
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
      for i := 0 to tvLineasAlbaran.ColumnCount - 1 do
      begin
        Col := tvLineasAlbaran.Columns[i];
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

procedure TfrmMtoAlbaranes.cxgrdLineasAlbaranExit(Sender: TObject);
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
  // (AsegurarPrimeraLineaAlbaran) se cancela: si quedara en dsInsert,
  // cualquier Edit de la cabecera la postearia via CheckBrowseMode del
  // master-detail y chocaria con la guarda de linea sin articulo.
  if Assigned(dmmAlbaranes) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if Assigned(ds) and ds.Active and (ds.State = dsInsert) then
    begin
      bVacia := CampoVacio('CODIGO_ART_ALBLIN') and
                CampoVacio('CODIGO_UNIDAD_ALBLIN');
      if bVacia then
        ds.Cancel;
    end;
  end;
end;

function TfrmMtoAlbaranes.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_ALB', 'CODIGO_ALM_ALB', '');
end;

procedure TfrmMtoAlbaranes.CrearTablaPrincipal;
begin
  inherited;
  // Reutilizar la instancia de data module creada por
  // TfrmMtoGen.CrearTablaPrincipal (tdmDataModule). Antes este form creaba
  // OTRO TdmAlbaranes en FormCreate y enganchaba los grids a ese segundo DM,
  // cuyas queries de detalle nunca se abren (la carga async abre las del DM
  // del padre): las pestanas de lineas, facturas y movimientos salian vacias.
  dmmAlbaranes := (tdmDataModule as TdmAlbaranes);
  if not Assigned(dmmAlbaranes) then
  begin
    dmmAlbaranes := TdmAlbaranes.Create(Self);
    dsTablaG.DataSet := dmmAlbaranes.unqryTablaG;
    tdmDataModule := dmmAlbaranes;
  end;
  tvLineasAlbaran.DataController.DataSource := dmmAlbaranes.dsAlbaranesLineas;
  cxgrdLineasAlbaran.OnEnter := cxgrdLineasAlbaranEnter;
  cxgrdLineasAlbaran.OnExit := cxgrdLineasAlbaranExit;
  tvFacturas.DataController.DataSource      := dmmAlbaranes.dsFacturas;
  tvMovimientos.DataController.DataSource   := dmmAlbaranes.dsMovimientosAlb;
  cbbTotalesFORMA_PAGO_ALB.Properties.ListSource := dmmAlbaranes.dsFormasPago;
  cbbCODIGO_ALM_ALB.Properties.ListSource := dmmAlbaranes.dsAlmacenesAlb;
  cbbTarifaAlbaran.Properties.ListSource := dmmAlbaranes.dsTarifas;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_ALB);
  DesactivarEnterAsTabEnCombo(cbbTarifaAlbaran);
  // Master-detail: enganchar las queries de detalle a la cabecera (dsTablaG)
  // para que lineas, facturas y movimientos sigan al albaran seleccionado.
  dmmAlbaranes.unqryAlbaranesLineas.MasterSource := dsTablaG;
  dmmAlbaranes.unqryFacturas.MasterSource        := dsTablaG;
  dmmAlbaranes.unqryMovimientosAlb.MasterSource  := dsTablaG;
  // Clave de localizacion para ShowMto (p.ej. "Ir a documento" desde el
  // pedido de venta o navegacion hacia su pedido de origen).
  pkFieldName := 'SERIE_ALB;NUMERO_ALB';
  // Total de prendas (pestana Totales): se recalcula tras cada Post/Delete
  // de linea y al navegar entre albaranes. Se conservan los handlers
  // originales (los que trae el DM) encadenandolos desde los hooks.
  FOldLineasAfterPost   := dmmAlbaranes.unqryAlbaranesLineas.AfterPost;
  FOldLineasAfterDelete := dmmAlbaranes.unqryAlbaranesLineas.AfterDelete;
  FOldLineasDataChange  := dmmAlbaranes.dsAlbaranesLineas.OnDataChange;
  dmmAlbaranes.unqryAlbaranesLineas.AfterPost   := unqryLineasAfterPostHook;
  dmmAlbaranes.unqryAlbaranesLineas.AfterDelete := unqryLineasAfterDeleteHook;
  dmmAlbaranes.dsAlbaranesLineas.OnDataChange := dsLineasDataChangeHook;
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  ActualizarColumnasOpcionalesLinea;
  ActualizarLabelPrendas;
  // Primera construccion del contrato al abrir la pantalla: sin ella,
  // hasta entrar en el grid se veian las columnas del dfm.
  if dmmAlbaranes.unqryAlbaranesLineas.Active then
    ConstruirModoEntrada;
end;

procedure TfrmMtoAlbaranes.ActualizarLabelPrendas;
begin
  if (dmmAlbaranes <> nil) and Assigned(dmmAlbaranes.unqryTablaG) and
     dmmAlbaranes.unqryTablaG.Active and (not dmmAlbaranes.unqryTablaG.IsEmpty) then
    lblTotalPrendasAlb.Caption :=
      FormatFloat('#,##0', dmmAlbaranes.TotalPrendasAlbaran)
  else
    lblTotalPrendasAlb.Caption := '0';
end;

procedure TfrmMtoAlbaranes.ActualizarColumnasOpcionalesLinea;
var
  ds: TDataSet;
  q: TUniQuery;
  sArticulo: string;
  bTrazable: Boolean;
  bVariacion: Boolean;
  iSkus: Integer;

  procedure PonerVisibleCampo(const ACampo: string; AVisible: Boolean);
  var
    Col: TcxGridDBColumn;
  begin
    Col := tvLineasAlbaran.GetColumnByFieldName(ACampo);
    if Col <> nil then
      Col.Visible := AVisible;
  end;

begin
  // Con el contrato construido, las columnas del dfm que esta rutina
  // muestra/oculta han muerto en el ClearItems: las gestiona el modo.
  if FColsModoConstruido then
    Exit;
  sArticulo := '';
  bTrazable := False;
  bVariacion := False;
  iSkus := 0;
  if (dmmAlbaranes <> nil) and
     Assigned(dmmAlbaranes.unqryAlbaranesLineas) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_ALBLIN') <> nil) then
      sArticulo := Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString);
  end;
  if (sArticulo <> '') and Assigned(dmmAlbaranes) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := dmmAlbaranes.unqryTablaG.Connection;
      q.SQL.Text :=
        'SELECT a.ESTRAZABLE_ART, a.ESVARIACION_ART, ' +
        '       (SELECT COUNT(*) ' +
        '          FROM fza_articulos_skus sk ' +
        '         WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
        '           AND COALESCE(sk.ESACTIVO_SKU, ''S'') = ''S'') AS NUM_SKUS ' +
        '  FROM fza_articulos a ' +
        ' WHERE a.CODIGO_ART_ART = :art';
      q.ParamByName('art').AsString := sArticulo;
      q.Open;
      if not q.IsEmpty then
      begin
        bTrazable := q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
        bVariacion := q.FieldByName('ESVARIACION_ART').AsString = 'S';
        iSkus := q.FieldByName('NUM_SKUS').AsInteger;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
  PonerVisibleCampo('LOTE_ALBLIN', bTrazable);
  PonerVisibleCampo('FECHA_CADUCIDAD_ALBLIN', bTrazable);
  PonerVisibleCampo('CODIGO_UNIDAD_ALBLIN', bVariacion or (iSkus > 1));
  PonerVisibleCampo('DESCRIPCION_VARIACION_ALBLIN',
                    bVariacion or (iSkus > 1));
  PonerVisibleCampo('CODIGO_ALMACEN_ALBLIN', False);
end;

procedure TfrmMtoAlbaranes.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterPost) then
    FOldLineasAfterPost(DataSet);
  ActualizarLabelPrendas;
end;

procedure TfrmMtoAlbaranes.unqryLineasAfterDeleteHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterDelete) then
    FOldLineasAfterDelete(DataSet);
  ActualizarLabelPrendas;
end;

procedure TfrmMtoAlbaranes.dsTablaGDataChangeHook(Sender: TObject;
                                                   Field: TField);
begin
  if (Field = nil) and Assigned(dmmAlbaranes) and
     dmmAlbaranes.unqryTablaG.Active and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
    dmmAlbaranes.RefrescarAlmacenes(
      dmmAlbaranes.unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString);
  if Field = nil then
    ActualizarLabelPrendas;
  // Al navegar de albaran: si la construccion inicial no pudo hacerse
  // (el detail aun no estaba abierto), se construye aqui. En desglose
  // ademas se desempaqueta SKU->ATTR: Color y Talla llegaban vacios en
  // lineas creadas en modo SKU, que no persiste los ATTR (es
  // idempotente por comparacion: sin cambios no postea nada).
  if (Field = nil) and
     Assigned(dmmAlbaranes) and
     dmmAlbaranes.unqryAlbaranesLineas.Active and
     (not (dsTablaG.State in dsEditModes)) then
  begin
    if not FColsModoConstruido then
      ConstruirModoEntrada
    else if FModoEntradaSel = mcsAuto then
      dmmAlbaranes.DesempaquetarAtributosLineas;
  end;
end;

procedure TfrmMtoAlbaranes.dsLineasDataChangeHook(Sender: TObject;
                                                   Field: TField);
begin
  if Assigned(FOldLineasDataChange) then
    FOldLineasDataChange(Sender, Field);
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_ART_ALBLIN') or
     SameText(Field.FieldName, 'CODIGO_UNIDAD_ALBLIN') then
    ActualizarColumnasOpcionalesLinea;
end;

procedure TfrmMtoAlbaranes.FormCreate(Sender: TObject);
var
  colFact, colSku: TcxGridDBColumn;
  stFact: TcxStyle;
begin
  inherited;
  // Contrato de entrada ColumnSKUcxGrid: Auto por defecto (resuelve a
  // desglose); F1 cicla los modos con las lineas a la vista.
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvLineasAlbaran.GetColumnByFieldName('CANTIDAD_ALBLIN'),
    tvLineasAlbaran.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_ALBLIN'));
  colSku := tvLineasAlbaran.GetColumnByFieldName('CODIGO_UNIDAD_ALBLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := cxgrdcArtAlbSkuPropertiesButtonClick;
      OnValidate := cxgrdcArtAlbSkuPropertiesValidate;
    end;
  end;
  // Resaltar la columna ESFACTURADA_ALBLIN cuando exista (S/N).
  colFact := tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN');
  if colFact <> nil then
  begin
    stFact := TcxStyle.Create(Self);
    stFact.AssignedValues := [svColor];
    stFact.Color := $00C4E1FF;
    colFact.Styles.Content := stFact;
  end;
  ActualizarColumnasOpcionalesLinea;
end;

procedure TfrmMtoAlbaranes.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoAlbaranes.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    dmmAlbaranes.unqryTablaG.Connection,
    dmmAlbaranes.unqryAlbaranesLineas, 'ALBLIN');
  if (sLineasSinSku = '') or
     (MessageDlg('Las líneas ' + sLineasSinSku + ' tienen artículos ' +
                 'con variaciones sin SKU asignado. ' +
                 '¿Grabar de todas formas?',
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmAlbaranes.CalcularTotalesAlbaran;
      dsTablaG.DataSet.Post;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmAlbaranes) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if TBusquedaUtils.EjecutarBusqueda(
           'Búsqueda de Empresas en Albaranes',
           dmmAlbaranes.unqryEmpDataAlb,
           'frmMtoEmpFacSearch',
           Self) then
      begin
        dmmAlbaranes.CopiarEmpresaaAlbaran(dmmAlbaranes.unqryEmpDataAlb);
        dmmAlbaranes.RefrescarAlmacenes(
          dmmAlbaranes.unqryEmpDataAlb.FieldByName(
            'CODIGO_EMP_EMP').AsString);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmAlbaranes) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if TBusquedaUtils.EjecutarBusqueda(
           'Búsqueda de Clientes en Albaranes',
           dmmAlbaranes.unqryCliDataAlb,
           'frmMtoCliFacSearch',
           Self) then
      begin
        dmmAlbaranes.CopiarClienteaAlbaran(dmmAlbaranes.unqryCliDataAlb);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
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
        dmmAlbaranes.BuscarEmpresa(sCodigo);
        dmmAlbaranes.RefrescarAlmacenes(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoAlbaranes.cbbCODIGO_ALM_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
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
        dmmAlbaranes.BuscarAlmacen(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.cbbTarifaAlbaranPropertiesChange(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
  sTarifa: string;
begin
  inherited;
  if Assigned(dmmAlbaranes) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) then
  begin
    Editor := Sender as TcxCustomEdit;
    sTarifa := Trim(VarToStr(Editor.EditingValue));
    dmmAlbaranes.ActualizarImpuestosTarifaCabecera(sTarifa);
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
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
        dmmAlbaranes.BuscarCliente(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_ALBPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_CLI_ALBPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloAlbaran;
  if sCodigo <> '' then
    AplicarArticuloAlbaran(sCodigo);
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbPropertiesValidate(Sender: TObject;
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
      AplicarArticuloAlbaran(sCodigo);
      if Assigned(dmmAlbaranes) and
         dmmAlbaranes.unqryAlbaranesLineas.Active and
         (dmmAlbaranes.unqryAlbaranesLineas.
            FindField('CODIGO_ART_ALBLIN') <> nil) then
        DisplayValue := dmmAlbaranes.unqryAlbaranesLineas.
                          FieldByName('CODIGO_ART_ALBLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbSkuPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaAlbaran;
  sSku := BuscarSkuAlbaran(sArt);
  if sSku <> '' then
    AplicarArticuloAlbaran(sSku);
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbSkuPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
begin
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloAlbaran(sCodigo);
      if Assigned(dmmAlbaranes) and
         dmmAlbaranes.unqryAlbaranesLineas.Active and
         (dmmAlbaranes.unqryAlbaranesLineas.
            FindField('CODIGO_UNIDAD_ALBLIN') <> nil) then
        DisplayValue := dmmAlbaranes.unqryAlbaranesLineas.
                          FieldByName('CODIGO_UNIDAD_ALBLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.AsegurarCabeceraPersistidaParaLineas;
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
    Result := (ValorLinea('CODIGO_ART_ALBLIN') = '') and
              (ValorLinea('CODIGO_UNIDAD_ALBLIN') = '');
  end;

  procedure SincronizarCabeceraEnLinea;
  begin
    if Assigned(dsLin) and dsLin.Active and
       (dsLin.State in dsEditModes) then
    begin
      if dsLin.FindField('NUMERO_ALB_ALBLIN') <> nil then
        dsLin.FieldByName('NUMERO_ALB_ALBLIN').AsString :=
          dsCab.FieldByName('NUMERO_ALB').AsString;
      if dsLin.FindField('SERIE_ALB_ALBLIN') <> nil then
        dsLin.FieldByName('SERIE_ALB_ALBLIN').AsString :=
          dsCab.FieldByName('SERIE_ALB').AsString;
    end;
  end;

begin
  if not Assigned(dmmAlbaranes) then
    raise Exception.Create('No esta inicializado el albaran.')
  else
  begin
    dsCab := dmmAlbaranes.unqryTablaG;
    dsLin := dmmAlbaranes.unqryAlbaranesLineas;
    if (dsCab = nil) or (not dsCab.Active) or
       (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
      raise Exception.Create(
        'Crea o selecciona un albaran antes de anadir lineas.');
    sNumero := Trim(dsCab.FieldByName('NUMERO_ALB').AsString);
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

procedure TfrmMtoAlbaranes.AsegurarPrimeraLineaAlbaran;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if not Assigned(dmmAlbaranes) then
    Exit;
  dsCab := dmmAlbaranes.unqryTablaG;
  dsLin := dmmAlbaranes.unqryAlbaranesLineas;
  if (dsCab = nil) or (dsLin = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    Exit;
  AsegurarCabeceraPersistidaParaLineas;
  sNumero := Trim(dsCab.FieldByName('NUMERO_ALB').AsString);
  sSerie  := Trim(dsCab.FieldByName('SERIE_ALB').AsString);
  if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
    Exit;
  if not dsLin.Active then
    dsLin.Open;
  if dsLin.IsEmpty and (not (dsLin.State in dsEditModes)) then
    dsLin.Append;
end;

procedure TfrmMtoAlbaranes.cxgrdLineasAlbaranEnter(Sender: TObject);
begin
  AsegurarPrimeraLineaAlbaran;
  // Contrato de entrada: primera construccion al entrar en el grid
  // (las lineas ya estan abiertas como detail del albaran).
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoAlbaranes.btnAnadirLineaClick(Sender: TObject);
var
  ds: TDataSet;
  bVaciaEnInsercion: Boolean;
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  // Si ya hay una linea vacia en insercion (la auto-anadida al entrar
  // al grid o la recreada por AsegurarCabecera), se REUTILIZA: otro
  // Append postearia la vacia via CheckBrowseMode contra la guarda de
  // linea sin articulo.
  bVaciaEnInsercion := ds.Active and (ds.State = dsInsert) and
    (Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString) = '') and
    (Trim(ds.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString) = '');
  if not bVaciaEnInsercion then
    ds.Append;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoAlbaranes.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('¿Está seguro de que desea eliminar esta línea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmAlbaranes.unqryAlbaranesLineas.Delete;
end;

procedure TfrmMtoAlbaranes.btnFacturarSeleccionadasClick(Sender: TObject);
var
  ds: TDataSet;
  lst: TList<string>;
  sNumFac, sSerFac, sLinea, sFacturada: string;
  i, iLineaCol, iFactCol: Integer;
  rec: TcxCustomGridRecord;
begin
  inherited;
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  if not ds.Active or (ds.RecordCount = 0) then
  begin
    ShowMessage('El albarán no tiene líneas.');
    Exit;
  end;
  if tvLineasAlbaran.Controller.SelectedRowCount = 0 then
  begin
    ShowMessage('Seleccione las líneas para crear borrador en la rejilla ' +
                '(Ctrl+click para selección múltiple).');
    Exit;
  end;
  lst := TList<string>.Create;
  try
    iLineaCol := -1;
    iFactCol  := -1;
    if tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBLIN') <> nil then
      iLineaCol := tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBLIN').Index;
    if tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN') <> nil then
      iFactCol :=
        tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN').Index;
    if iLineaCol < 0 then Exit;

    for i := 0 to tvLineasAlbaran.Controller.SelectedRowCount - 1 do
    begin
      rec := tvLineasAlbaran.Controller.SelectedRows[i];
      sLinea := VarToStr(rec.Values[iLineaCol]);
      if iFactCol >= 0 then
        sFacturada := VarToStr(rec.Values[iFactCol])
      else
        sFacturada := 'N';
      if (sLinea <> '') and (sFacturada <> 'S') then
        lst.Add(sLinea);
    end;

    if lst.Count = 0 then
    begin
      ShowMessage('Las líneas seleccionadas ya tienen borrador.');
      Exit;
    end;
    if MessageDlg(Format('¿Generar borrador con %d línea(s) del albarán?',
                         [lst.Count]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    if dmmAlbaranes.CrearFacturaDesdeAlbaran(sNumFac, sSerFac, lst) then
      ShowMessageFmt('Borrador creado: %s / %s', [sSerFac, sNumFac])
    else
      ShowMessage('No se pudo crear el borrador.');
  finally
    FreeAndNil(lst);
  end;
end;

procedure TfrmMtoAlbaranes.btnFacturarTodoClick(Sender: TObject);
var
  sNumFac, sSerFac: string;
begin
  inherited;
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  if not dmmAlbaranes.unqryAlbaranesLineas.Active or
     (dmmAlbaranes.unqryAlbaranesLineas.RecordCount = 0) then
  begin
    ShowMessage('El albarán no tiene líneas.');
    Exit;
  end;
  if MessageDlg('¿Crear borrador con todas las líneas pendientes del albarán?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  if dmmAlbaranes.CrearFacturaDesdeAlbaran(sNumFac, sSerFac, nil) then
    ShowMessageFmt('Borrador creado: %s / %s', [sSerFac, sNumFac])
  else
    ShowMessage('No se pudo crear el borrador.');
end;

procedure TfrmMtoAlbaranes.btnFacturarPorFechasClick(Sender: TObject);
var
  form: TfrmModalFacturarAlbaranesFechas;
begin
  inherited;
  form := TfrmModalFacturarAlbaranesFechas.Create(Self);
  try
    form.dmmAlbaranes := dmmAlbaranes;
    form.ShowModal;
    dmmAlbaranes.unqryTablaG.Close;
    dmmAlbaranes.unqryTablaG.Open;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoAlbaranes.btnImprimirClick(Sender: TObject);
begin
  inherited;
  // Hook FastReport: cargar fxdsPrintAlb / fxdstPrintLinAlb y mostrar.
end;

// "Ir a documento" (Ctrl+May+A): salta al pedido de venta del que nace
// el albaran (SERIE_PED_ALB / NUMERO_PED_ALB). Si el albaran se creo a
// mano y no procede de ningun pedido, avisamos en lugar de abrir un Mto
// vacio.
procedure TfrmMtoAlbaranes.actIrDocumentoExecute(Sender: TObject);
var
  sSeriePed, sNumeroPed: string;
begin
  inherited;
  if (dmmAlbaranes <> nil) and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
  begin
    sSeriePed  := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('SERIE_PED_ALB').AsString);
    sNumeroPed := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('NUMERO_PED_ALB').AsString);
    if (sSeriePed <> '') and (sNumeroPed <> '') then
      ShowMto(Self.Owner, 'Pedidos', sSeriePed + ',' + sNumeroPed)
    else
      ShowMessage('Este albaran no procede de ningun pedido de venta.');
  end;
end;

procedure TfrmMtoAlbaranes.actIrFacturaCreadaExecute(Sender: TObject);
var
  sSerieFac, sNumeroFac: string;
  sCallFactura: string;
begin
  inherited;
  if (dmmAlbaranes <> nil) and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
  begin
    sSerieFac  := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('SERIE_FAC_ALB').AsString);
    sNumeroFac := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('NUMERO_FAC_ALB').AsString);
    if (sSerieFac <> '') and (sNumeroFac <> '') then
    begin
      sCallFactura := ResolverCallFactura(sNumeroFac, sSerieFac);
      ShowMto(Self.Owner, sCallFactura, sSerieFac + ',' + sNumeroFac);
    end
    else
      ShowMessage('Este albaran no tiene borrador creado.');
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoAlbaranes);

end.
