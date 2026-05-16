{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2026 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

unit inMtoComprasSesiones;

{
  Formulario principal: Sesiones de Compra (pre-pedidos / pre-albaranes).

  Ver DESARROLLOS EN CURSO/compras_sesiones.md para el diseño completo.

  Pestañas:
    tsLista         - lista de sesiones (heredada de TfrmMtoGen)
    tsFicha         - ficha con sub-PageControl pcSesion:
        tsCabecera - datos generales, plantilla precios, plantilla variación
        tsPlantilla       - propiedades fijas/variables + kits de cantidades
        tsLineas          - grid de líneas + detalle matriz pivotada
        tsMaterializacion - resumen y botón "Crear artículos y documentos"
        tsLog             - log de materialización

  Estados:
    BORRADOR - editable
    CERRADA  - sólo lectura; ya generó artículos y documento
    ANULADA  - sólo lectura

  Eventos clave:
    btnCrearMaterializarClick -> abre modal de confirmación que dispara
      inLibComprasSesionesMaterializar.MaterializarSesion(...)
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ExtCtrls, Vcl.Buttons, System.UITypes,
  System.Actions, Vcl.ActnList,
  inMtoGen,
  UniDataComprasSesiones,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, Uni,
  cxClasses, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxDBEdit, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, DB, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  cxDBNavigator, cxMemo, cxCheckBox, cxGroupBox, cxDBLabel, cxButtonEdit,
  cxRadioGroup, cxLocalization, cxBlobEdit, cxGraphics, cxImage,
  dxDateRanges, dxScrollbarAnnotations, dxBevel, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxSplitter;

type
  TfrmMtoComprasSesiones = class(TfrmMtoGen)
    // ------------------------------------------------------------------
    // Columnas grid lista
    // ------------------------------------------------------------------
    dbcSerieSes              : TcxGridDBColumn;
    dbcNumeroSes             : TcxGridDBColumn;
    dbcFechaSes              : TcxGridDBColumn;
    dbcEstadoSes             : TcxGridDBColumn;
    dbcCodigoPrvSes          : TcxGridDBColumn;
    dbcRefPrvSes             : TcxGridDBColumn;
    dbcCodigoFamSes          : TcxGridDBColumn;
    dbcTotalCompraSes        : TcxGridDBColumn;
    dbcUsuarioAltaSes        : TcxGridDBColumn;
    dbcInstanteAltaSes       : TcxGridDBColumn;

    // ------------------------------------------------------------------
    // Botones top
    // ------------------------------------------------------------------
    btnCrearMaterializar     : TcxButton;
    btnAnularSesion          : TcxButton;
    btnClonarSesion          : TcxButton;
    btnCerrarManual          : TcxButton;

    // ------------------------------------------------------------------
    // Page control de la ficha
    // ------------------------------------------------------------------
    pcSesion                 : TcxPageControl;
    tsCabecera               : TcxTabSheet;
    tsPlantilla              : TcxTabSheet;
    tsLineas                 : TcxTabSheet;
    tsMaterializacion        : TcxTabSheet;
    tsLog                    : TcxTabSheet;

    // ------------------------------------------------------------------
    // Pestaña Cabecera
    // ------------------------------------------------------------------
    gbDatosGen               : TcxGroupBox;
    lblSerie                 : TcxLabel;
    cbbSerie                 : TcxDBComboBox;
    lblNumero                : TcxLabel;
    txtNumero                : TcxDBTextEdit;
    lblFecha                 : TcxLabel;
    dteFecha                 : TcxDBDateEdit;
    lblEstado                : TcxLabel;
    txtEstado                : TcxDBTextEdit;
    lblEmpresa               : TcxLabel;
    cbbEmpresa               : TcxDBLookupComboBox;
    lblProveedor             : TcxLabel;
    cbbProveedor             : TcxDBLookupComboBox;
    lblRefPrv                : TcxLabel;
    txtRefPrv                : TcxDBTextEdit;
    lblAlmacen               : TcxLabel;
    cbbAlmacen               : TcxDBLookupComboBox;
    lblMoneda                : TcxLabel;
    txtMoneda                : TcxDBTextEdit;
    memoComentarios          : TcxDBMemo;
    lblComentarios           : TcxLabel;

    gbPrecios                : TcxGroupBox;
    lblTipoIva               : TcxLabel;
    cbbTipoIva               : TcxDBLookupComboBox;
    lblMargen                : TcxLabel;
    spnMargen                : TcxDBSpinEdit;
    lblTarifa                : TcxLabel;
    cbbTarifa                : TcxDBLookupComboBox;
    chkPreciosSinIva         : TcxDBCheckBox;
    chkRedondeoVenta         : TcxDBCheckBox;
    lblMultiploRedondeo      : TcxLabel;
    spnMultiploRedondeo      : TcxDBSpinEdit;
    lblAjusteFinal           : TcxLabel;
    spnAjusteFinal           : TcxDBSpinEdit;
    chkPrecioPorSku          : TcxDBCheckBox;

    gbVariacion              : TcxGroupBox;
    lblVariacion             : TcxLabel;
    cbbVariacion             : TcxDBLookupComboBox;
    lblConjPivot             : TcxLabel;
    cbbConjuntoPivot         : TcxDBLookupComboBox;
    lblConjFila              : TcxLabel;
    cbbConjuntoFila          : TcxDBLookupComboBox;
    chkVarFija               : TcxDBCheckBox;
    btnVistaPreviaMatriz     : TcxButton;

    // ------------------------------------------------------------------
    // Pestaña Plantilla
    // ------------------------------------------------------------------
    pcPlantilla              : TcxPageControl;
    tsPropiedades            : TcxTabSheet;
    tsKits                   : TcxTabSheet;

    cxgrdProps               : TcxGrid;
    tvProps                  : TcxGridDBTableView;
    glProps                  : TcxGridLevel;
    dbcPropsCodigo           : TcxGridDBColumn;
    dbcPropsNombre           : TcxGridDBColumn;
    dbcPropsTipo             : TcxGridDBColumn;
    dbcPropsFijo             : TcxGridDBColumn;
    dbcPropsValorDefecto     : TcxGridDBColumn;
    btnAddProp               : TcxButton;
    btnDelProp               : TcxButton;

    cxgrdKits                : TcxGrid;
    tvKits                   : TcxGridDBTableView;
    glKits                   : TcxGridLevel;
    dbcKitsCodigo            : TcxGridDBColumn;
    dbcKitsNombre            : TcxGridDBColumn;
    dbcKitsIdVaDestino       : TcxGridDBColumn;
    cxgrdKitsDet             : TcxGrid;
    tvKitsDet                : TcxGridDBTableView;
    glKitsDet                : TcxGridLevel;
    dbcKitsDetValor          : TcxGridDBColumn;
    dbcKitsDetCantidad       : TcxGridDBColumn;
    btnAddKit                : TcxButton;
    btnDelKit                : TcxButton;
    btnImportarKitPrv        : TcxButton;
    pnlLineasTop             : TPanel;
    pnlLineasBotones         : TPanel;
    pnlPropsTop              : TPanel;
    pnlKitsTop               : TPanel;
    cxgrdLineas              : TcxGrid;
    tvLineas                 : TcxGridDBTableView;
    glLineas                 : TcxGridLevel;
    dbcLinNumero             : TcxGridDBColumn;
    dbcLinTipo               : TcxGridDBColumn;
    dbcLinCodigoArt          : TcxGridDBColumn;
    dbcLinDescripcion        : TcxGridDBColumn;
    dbcLinFamilia            : TcxGridDBColumn;
    dbcLinRefPrv             : TcxGridDBColumn;
    dbcLinPrecioCompra       : TcxGridDBColumn;
    dbcLinMargen             : TcxGridDBColumn;
    dbcLinPrecioVenta        : TcxGridDBColumn;
    dbcLinTipoIva            : TcxGridDBColumn;
    dbcLinTotalUnidades      : TcxGridDBColumn;
    dbcLinTotalLinea         : TcxGridDBColumn;
    dbcLinDuplicado          : TcxGridDBColumn;
    btnAddLinea              : TcxButton;
    btnDupLinea              : TcxButton;
    btnDelLinea              : TcxButton;
    btnResolverDuplicado     : TcxButton;
    btnCalcularVenta         : TcxButton;

    pnlLineasDetalle         : TPanel;
    lblLineaActiva           : TcxLabel;
    gbMatriz                 : TcxGroupBox;

    // Sub-grid de precios por SKU (visible solo si ESPRECIO_POR_SKU_SES='S')
    splPreciosSku            : TcxSplitter;
    gbPreciosSku             : TcxGroupBox;
    cxgrdPreciosSku          : TcxGrid;
    tvPreciosSku             : TcxGridDBTableView;
    glPreciosSku             : TcxGridLevel;
    dbcPreciosSkuValFila     : TcxGridDBColumn;
    dbcPreciosSkuValPivot    : TcxGridDBColumn;
    dbcPreciosSkuPrecioCompra: TcxGridDBColumn;
    dbcPreciosSkuPrecioVenta : TcxGridDBColumn;

    // Panel scroll que aloja la matriz dinámica (construida en runtime
    // por inLibComprasSesiones a partir del eje pivot y fila).
    sbMatriz                 : TScrollBox;

    pnlMatrizBotones         : TPanel;
    pnlAlmacenSel            : TPanel;
    lblAlmacenSel            : TcxLabel;
    cbbAlmacenMatriz         : TcxLookupComboBox;
    lblTotalesPorAlm         : TcxLabel;
    lblKitSel                : TcxLabel;
    cbbKitAplicar            : TcxDBLookupComboBox;
    btnAplicarKitFila        : TcxButton;
    btnAplicarKitTodas       : TcxButton;
    btnAddFila               : TcxButton;
    btnDelFila               : TcxButton;
    btnAddColumna            : TcxButton;

    // ------------------------------------------------------------------
    // Pestaña Materialización
    // ------------------------------------------------------------------
    gbResumen                : TcxGroupBox;
    lblResNumArticulos       : TcxLabel;
    lblResNumSkus            : TcxLabel;
    lblResNumEan13           : TcxLabel;
    lblResNumPropiedades     : TcxLabel;
    lblResEnlacePrv          : TcxLabel;
    lblResConflictos         : TcxLabel;

    gbDocumento              : TcxGroupBox;
    chkGeneraPedido          : TcxDBCheckBox;
    chkGeneraAlbaran         : TcxDBCheckBox;
    lblPrefijoEan            : TcxLabel;
    txtPrefijoEan            : TcxDBTextEdit;

    cxgrdPreview             : TcxGrid;
    tvPreview                : TcxGridDBTableView;
    glPreview                : TcxGridLevel;
    dbcPrevLinea             : TcxGridDBColumn;
    dbcPrevCodigoArt         : TcxGridDBColumn;
    dbcPrevDescripcion       : TcxGridDBColumn;
    dbcPrevValorPivot        : TcxGridDBColumn;
    dbcPrevCantidad          : TcxGridDBColumn;
    dbcPrevPrecioCompra      : TcxGridDBColumn;
    dbcPrevPrecioVenta       : TcxGridDBColumn;

    btnValidarTodo           : TcxButton;
    btnDoMaterializar        : TcxButton;

    // ------------------------------------------------------------------
    // Pestaña Log
    // ------------------------------------------------------------------
    memoLog                  : TcxMemo;
    lblPedidoGenerado        : TcxLabel;
    lblAlbaranGenerado       : TcxLabel;
    lblMensajeError          : TcxDBLabel;

    // ------------------------------------------------------------------
    // Actions / shortcuts
    // ------------------------------------------------------------------
    alSesion                 : TActionList;
    actMaterializar          : TAction;     // F9
    actNuevaLinea            : TAction;     // Ins
    actBorrarLinea           : TAction;     // Ctrl+Del
    actDuplicarLinea         : TAction;     // Ctrl+D
    actAplicarKit            : TAction;     // F8
    actValidar               : TAction;
    Panel1: TPanel;     // Ctrl+V

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);

    procedure btnCrearMaterializarClick(Sender: TObject);
    procedure btnAnularSesionClick(Sender: TObject);
    procedure btnClonarSesionClick(Sender: TObject);
    procedure btnCerrarManualClick(Sender: TObject);

    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDupLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
    procedure btnResolverDuplicadoClick(Sender: TObject);

    procedure btnAddFilaClick(Sender: TObject);
    procedure btnDelFilaClick(Sender: TObject);
    procedure btnAddColumnaClick(Sender: TObject);

    procedure btnAddPropClick(Sender: TObject);
    procedure btnDelPropClick(Sender: TObject);
    procedure btnAddKitClick(Sender: TObject);
    procedure btnDelKitClick(Sender: TObject);
    procedure btnImportarKitPrvClick(Sender: TObject);

    procedure btnAplicarKitFilaClick(Sender: TObject);
    procedure btnAplicarKitTodasClick(Sender: TObject);
    procedure cbbAlmacenMatrizPropertiesChange(Sender: TObject);
    procedure cbbEmpresaPropertiesEditValueChanged(Sender: TObject);
    procedure chkPrecioPorSkuPropertiesEditValueChanged(Sender: TObject);
    procedure btnCalcularVentaClick(Sender: TObject);
    procedure dbcPreciosSkuPrecioCompraPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcPreciosSkuPrecioVentaPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnVistaPreviaMatrizClick(Sender: TObject);

    procedure btnValidarTodoClick(Sender: TObject);
    procedure btnDoMaterializarClick(Sender: TObject);

    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
    procedure tvLineasFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);

    procedure actMaterializarExecute(Sender: TObject);
    procedure actNuevaLineaExecute(Sender: TObject);
    procedure actBorrarLineaExecute(Sender: TObject);
    procedure actDuplicarLineaExecute(Sender: TObject);
    procedure actAplicarKitExecute(Sender: TObject);
    procedure actValidarExecute(Sender: TObject);
  private
    FGestorMatriz : TObject; // TGestorMatrizCompras (en inLibComprasSesiones)
    procedure ActualizarEstadoUI;
    procedure ReconstruirMatrizActual;
    procedure ReconstruirResumenMaterializacion;
    procedure HabilitarEdicion(AHabilitar: Boolean);
    function  EsSesionEditable: Boolean;
    procedure ActualizarVisibilidadPreciosSku;
    procedure UpsertPrecioSku(AField: string; ANuevo: Double);
    procedure RellenarItemsSerie;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoComprasSesiones: TfrmMtoComprasSesiones;

implementation

uses
  inLibWin,
  inLibUser,
  inLibShowMto,
  inMtoPrincipal,
  inLibComprasSesiones,
  inLibComprasSesionesMaterializar,
  inMtoModalSesionMaterializar,
  inMtoModalSesionDuplicado,
  inMtoModalSelFamilia,
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoComprasSesiones.CrearTablaPrincipal;
begin
  inherited;
  if tdmDataModule = nil then Exit;
  dmComprasSesiones := tdmDataModule as TdmComprasSesiones;
  pkFieldName := 'SERIE_SES;NUMERO_SES';

  // Wire de los lookups de cabecera contra los DataSource auxiliares del DM.
  // Sin esto los combos quedan vacios al pulsar "+" porque el DFM no puede
  // resolver dmComprasSesiones.dsXxx en tiempo de streaming (la global aun
  // es nil); por eso lo asignamos aqui, igual que cbbAlmacenMatriz.
  cbbEmpresa.Properties.ListSource       := dmComprasSesiones.dsEmpresas;
  cbbProveedor.Properties.ListSource     := dmComprasSesiones.dsProveedores;
  cbbAlmacen.Properties.ListSource       := dmComprasSesiones.dsAlmacenes;
  cbbTipoIva.Properties.ListSource       := dmComprasSesiones.dsIvas;
  cbbTarifa.Properties.ListSource        := dmComprasSesiones.dsTarifas;
  cbbVariacion.Properties.ListSource     := dmComprasSesiones.dsVariaciones;
  cbbConjuntoPivot.Properties.ListSource := dmComprasSesiones.dsAtributosConjuntos;
  cbbConjuntoFila.Properties.ListSource  := dmComprasSesiones.dsAtributosConjuntos;

  // El DataSource heredado de TfrmMtoGen solo trae OnStateChange wireado en
  // su DFM. Enganchamos aqui el OnDataChange para que al cambiar CODIGO_EMP_SES
  // se refresque el dropdown de cbbSerie (RellenarItemsSerie).
  dsTablaG.OnDataChange := dsTablaGDataChange;

  // Master-detail: dsTablaG vive en el form, no en el DM, asi que el DFM del
  // DM no puede declararlo. Sin esto unqrySesionLin queda cerrado y
  // btnAddLinea lanza 'Cannot perform this operation on a closed dataset'.
  with dmComprasSesiones do
  begin
    unqrySesionLin.MasterFields   := 'SERIE_SES;NUMERO_SES';
    unqrySesionLin.MasterSource   := dsTablaG;
    unqrySesionProps.MasterFields := 'SERIE_SES;NUMERO_SES';
    unqrySesionProps.MasterSource := dsTablaG;
    unqrySesionKits.MasterFields  := 'SERIE_SES;NUMERO_SES';
    unqrySesionKits.MasterSource  := dsTablaG;

    // Abrimos toda la cadena: lineas -> filas/celdas/props_linea, kits -> det.
    if not unqrySesionLin.Active      then unqrySesionLin.Open;
    if not unqrySesionFil.Active      then unqrySesionFil.Open;
    if not unqrySesionCel.Active      then unqrySesionCel.Open;
    if not unqrySesionProps.Active    then unqrySesionProps.Open;
    if not unqrySesionLinProps.Active then unqrySesionLinProps.Open;
    if not unqrySesionKits.Active     then unqrySesionKits.Open;
    if not unqrySesionKitsDet.Active  then unqrySesionKitsDet.Open;
  end;
end;

procedure TfrmMtoComprasSesiones.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoComprasSesiones.FormCreate(Sender: TObject);
begin
  inherited;
  tvLineas.DataController.DataSource         := dmComprasSesiones.dsSesionLin;
  tvProps.DataController.DataSource          := dmComprasSesiones.dsSesionProps;
  tvKits.DataController.DataSource           := dmComprasSesiones.dsSesionKits;
  tvKitsDet.DataController.DataSource := dmComprasSesiones.dsSesionKitsDet;
  tvPreview.DataController.DataSource        := dmComprasSesiones.dsPreviewSkus;
  tvPreciosSku.DataController.DataSource     := dmComprasSesiones.dsLineaSkusPrecios;

  // Selector de alm. para la matriz: alimenta de la lista global de almacenes.
  cbbAlmacenMatriz.Properties.ListSource     := dmComprasSesiones.dsAlmacenes;
  // cbbSerie es ahora TcxDBTextEdit (texto libre). El usuario puede
  // teclear cualquier serie; al grabar, BeforePost asegura que esa
  // serie exista en fza_empresas_series (la crea si no existe) y luego
  // pide el contador.

  pcSesion.ActivePage := tsCabecera;
  FGestorMatriz := TGestorMatrizCompras.Create(sbMatriz,
                                                dmComprasSesiones,
                                                oUser);
end;

procedure TfrmMtoComprasSesiones.cbbAlmacenMatrizPropertiesChange(
  Sender: TObject);
var
  sCodigoAlm: string;
begin
  inherited;
  if FGestorMatriz = nil then Exit;
  sCodigoAlm := VarToStr(cbbAlmacenMatriz.EditValue);
  TGestorMatrizCompras(FGestorMatriz).AlmacenActual := sCodigoAlm;
  ReconstruirMatrizActual;
end;

procedure TfrmMtoComprasSesiones.cbbEmpresaPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if (dmComprasSesiones = nil) or
     (dmComprasSesiones.unqryTablaG = nil) or
     (not dmComprasSesiones.unqryTablaG.Active) then Exit;

  // Refresca el dropdown del combo Serie con las series de la nueva empresa
  RellenarItemsSerie;

  // Auto-primera: si la sesion esta en alta o edicion y SERIE_SES esta vacia,
  // asigna la primera serie disponible. El usuario sigue pudiendo cambiarla
  // tecleando o desplegando el combo.
  if not (dmComprasSesiones.unqryTablaG.State in [dsEdit, dsInsert]) then Exit;
  if dmComprasSesiones.unqryTablaG.FieldByName('SERIE_SES').AsString <> '' then Exit;
  if cbbSerie.Properties.Items.Count > 0 then
    dmComprasSesiones.unqryTablaG.FieldByName('SERIE_SES').AsString :=
      cbbSerie.Properties.Items[0];
end;

procedure TfrmMtoComprasSesiones.RellenarItemsSerie;
var
  q    : TUniQuery;
  sEmp : string;
begin
  // Vuelca en cbbSerie.Properties.Items la lista de series de la empresa
  // actual con TIPO_DOC_EMPSER='SE' vigentes. Si el usuario teclea una
  // serie nueva que no este en la lista, el BeforePost la crea al vuelo
  // en fza_empresas_series.
  if not Assigned(cbbSerie) then Exit;
  cbbSerie.Properties.Items.Clear;
  if (dmComprasSesiones = nil) or
     (dmComprasSesiones.unqryTablaG = nil) or
     (not dmComprasSesiones.unqryTablaG.Active) then Exit;
  if dmComprasSesiones.unqryTablaG.IsEmpty and
     (dmComprasSesiones.unqryTablaG.State = dsBrowse) then Exit;

  sEmp := dmComprasSesiones.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  if Trim(sEmp) = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT EMPSER FROM fza_empresas_series ' +
      ' WHERE TIPO_DOC_EMPSER = ''SE'' ' +
      '   AND CODIGO_EMP_EMPSER = :emp ' +
      '   AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
      ' ORDER BY EMPSER';
    q.ParamByName('emp').AsString := sEmp;
    q.Open;
    while not q.Eof do
    begin
      cbbSerie.Properties.Items.Add(q.FieldByName('EMPSER').AsString);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoComprasSesiones.FormDestroy(Sender: TObject);
begin
  if Assigned(FGestorMatriz) then FreeAndNil(FGestorMatriz);
  FGestorMatriz := nil;
  // Anular la global ANTES de que el destructor heredado libere el DM.
  // Si no la global queda dangling y al abrir Sesiones por segunda vez
  // dsTablaGStateChange (que se dispara antes que CrearTablaPrincipal
  // reasigne la global) leeria memoria liberada -> AV.
  if dmComprasSesiones = tdmDataModule then
    dmComprasSesiones := nil;
  inherited;
end;

procedure TfrmMtoComprasSesiones.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcSesion.ActivePage := tsCabecera;
  cbbProveedor.SetFocus;
end;

procedure TfrmMtoComprasSesiones.btnGrabarClick(Sender: TObject);
begin
  if (dsTablaG.State in dsEditModes) then
  begin
    if dmComprasSesiones.DetectarConflictoConcurrencia then
    begin
      if MessageDlg(
        'Otro usuario ha modificado esta sesión mientras la editabas.' +
                    sLineBreak
                      + '¿Deseas forzar la grabación (sobreescribir) o ' +
                    'cancelar y recargar?', mtWarning, [mbYes, mbCancel],
                    0) <> mrYes then
      begin
        dsTablaG.DataSet.Cancel;
        dsTablaG.DataSet.Refresh;
        Exit;
      end;
    end;
    dsTablaG.DataSet.Post;
  end;
  inherited;
end;

procedure TfrmMtoComprasSesiones.btnCrearMaterializarClick(Sender: TObject);
begin
  inherited;
  if not EsSesionEditable then Exit;

  // Asegurar grabado antes de materializar
  if dsTablaG.State in dsEditModes then dsTablaG.DataSet.Post;

  pcSesion.ActivePage := tsMaterializacion;
  ReconstruirResumenMaterializacion;
end;

procedure TfrmMtoComprasSesiones.btnDoMaterializarClick(Sender: TObject);
var
  frmConfirm : TfrmModalSesionMaterializar;
  bOk        : Boolean;
  sMsgError  : string;
  sSeriePed, sNumPed, sSerieAlb, sNumAlb: string;
begin
  inherited;
  if not EsSesionEditable then Exit;

  frmConfirm := TfrmModalSesionMaterializar.Create(Self);
  try
    frmConfirm.ESGeneraPedido  := dmComprasSesiones.unqryTablaG
                                    .FieldByName(
                                      'ESGENERA_PEDIDO_SES').AsString = 'S';
    frmConfirm.ESGeneraAlbaran := dmComprasSesiones.unqryTablaG
                                    .FieldByName(
                                      'ESGENERA_ALBARAN_SES').AsString = 'S';
    if frmConfirm.ShowModal <> mrOk then Exit;

    bOk := inLibComprasSesionesMaterializar.MaterializarSesion(
             dmComprasSesiones,
             frmConfirm.ESGeneraPedido,
             frmConfirm.ESGeneraAlbaran,
             oUser,
             sSeriePed, sNumPed, sSerieAlb, sNumAlb, sMsgError);

    if bOk then
    begin
      memoLog.Lines.Add('==> Materialización OK ' + DateTimeToStr(Now));
      if sNumPed   <> '' then memoLog.Lines.Add(
        '  Pedido generado : ' + sSeriePed + '-' + sNumPed);
      if sNumAlb   <> '' then memoLog.Lines.Add(
        '  Albarán generado: ' + sSerieAlb + '-' + sNumAlb);
      dsTablaG.DataSet.Refresh;
      pcSesion.ActivePage := tsLog;
    end
    else
    begin
      memoLog.Lines.Add('==> ERROR: ' + sMsgError);
      MessageDlg('La materialización ha fallado:' + sLineBreak + sMsgError,
                 mtError, [mbOk], 0);
    end;
  finally
    FreeAndNil(frmConfirm);
  end;
end;

procedure TfrmMtoComprasSesiones.btnAnularSesionClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('¿Anular la sesión? Esta acción no se puede deshacer.',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  dsTablaG.DataSet.Edit;
  dmComprasSesiones.unqryTablaG.FieldByName('ESTADO_SES').AsString := 'ANULADA';
  dsTablaG.DataSet.Post;
  ActualizarEstadoUI;
end;

procedure TfrmMtoComprasSesiones.btnClonarSesionClick(Sender: TObject);
begin
  inherited;
  // Clonar = INSERT en cabecera con datos copiados + INSERT de
  // lineas/filas/celdas
  // bajo nuevo NUMERO_SES. Implementación detallada en inLibComprasSesiones.
  inLibComprasSesiones.ClonarSesion(dmComprasSesiones, oUser);
end;

procedure TfrmMtoComprasSesiones.btnCerrarManualClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Marcar la sesión como CERRADA sin materializar. ¿Continuar?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  dsTablaG.DataSet.Edit;
  dmComprasSesiones.unqryTablaG.FieldByName('ESTADO_SES').AsString := 'CERRADA';
  dsTablaG.DataSet.Post;
  ActualizarEstadoUI;
end;

procedure TfrmMtoComprasSesiones.btnAddLineaClick(Sender: TObject);
begin
  inherited;
  if not EsSesionEditable then Exit;
  dmComprasSesiones.unqrySesionLin.Append;
end;

procedure TfrmMtoComprasSesiones.btnDupLineaClick(Sender: TObject);
begin
  inherited;
  if not EsSesionEditable then Exit;
  inLibComprasSesiones.DuplicarLineaActual(dmComprasSesiones, oUser);
end;

procedure TfrmMtoComprasSesiones.btnDelLineaClick(Sender: TObject);
begin
  inherited;
  if not EsSesionEditable then Exit;
  if MessageDlg('¿Borrar la línea seleccionada (y sus celdas)?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  inLibComprasSesiones.BorrarLineaConCascada(dmComprasSesiones);
end;

procedure TfrmMtoComprasSesiones.btnResolverDuplicadoClick(Sender: TObject);
var
  frmDup : TfrmModalSesionDuplicado;
  qL     : TUniQuery;
begin
  inherited;
  if not EsSesionEditable then Exit;
  qL := dmComprasSesiones.unqrySesionLin;
  if qL.IsEmpty then Exit;
  if qL.FieldByName('ESDUPLICADO_SESLIN').AsString <> 'S' then Exit;

  frmDup := TfrmModalSesionDuplicado.Create(Self);
  try
    frmDup.CodigoArt := qL.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
    if frmDup.ShowModal <> mrOk then Exit;
    if frmDup.Accion = '' then Exit;     // por si acaso se cerro con Esc

    if not (qL.State in [dsEdit, dsInsert]) then
      qL.Edit;

    qL.FieldByName('ACCION_DUPLICADO_SESLIN').AsString := frmDup.Accion;

    if frmDup.Accion = 'REUSAR' then
    begin
      // El codigo a reutilizar es el que el usuario tenia tecleado:
      // mantenemos el TENTATIVO y guardamos el REUSAR para que la
      // materializacion enlace al articulo existente en vez de crear uno.
      qL.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString := frmDup.CodigoArt;
    end
    else if frmDup.Accion = 'RENOMBRAR' then
    begin
      // El usuario tecleo un codigo nuevo: pegarlo al tentativo y limpiar
      // cualquier 'reusar' anterior. El BeforePost del dataset volvera a
      // chequear duplicados con el nuevo codigo y reseteara
      // ESDUPLICADO_SESLIN si ya no hay choque.
      qL.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := frmDup.CodigoArt;
      qL.FieldByName('CODIGO_ART_REUSAR_SESLIN').Clear;
    end;

    qL.Post;
  finally
    FreeAndNil(frmDup);
  end;
end;

procedure TfrmMtoComprasSesiones.btnCalcularVentaClick(Sender: TObject);
var
  iSel  : Integer;
  aRecs : array of Integer;
  i, iLin : Integer;
begin
  inherited;
  if not EsSesionEditable then Exit;
  if dmComprasSesiones.unqrySesionLin.IsEmpty then Exit;

  // Si hay multi-seleccion en el grid, aplicar a todas; si no, solo a la actual.
  iSel := tvLineas.Controller.SelectedRecordCount;
  if iSel > 1 then
  begin
    SetLength(aRecs, iSel);
    for i := 0 to iSel - 1 do
    begin
      iLin := tvLineas.Controller.SelectedRecords[i]
                .Values[dbcLinNumero.Index];
      aRecs[i] := iLin;
    end;
    inLibComprasSesiones.CalcularPrecioVentaLineas(
      dmComprasSesiones, oUser, aRecs);
  end
  else
  begin
    inLibComprasSesiones.CalcularPrecioVentaLinea(
      dmComprasSesiones, oUser);
    dmComprasSesiones.unqrySesionLin.Refresh;
  end;
end;

procedure TfrmMtoComprasSesiones.chkPrecioPorSkuPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  // Refresca visibilidad del sub-grid de precios SKU.
  ActualizarVisibilidadPreciosSku;
end;

procedure TfrmMtoComprasSesiones.btnAddFilaClick(Sender: TObject);
begin
  inherited;
  TGestorMatrizCompras(FGestorMatriz).AddFila;
end;

procedure TfrmMtoComprasSesiones.btnDelFilaClick(Sender: TObject);
begin
  inherited;
  TGestorMatrizCompras(FGestorMatriz).DelFilaSeleccionada;
end;

procedure TfrmMtoComprasSesiones.btnAddColumnaClick(Sender: TObject);
begin
  inherited;
  if not EsSesionEditable then Exit;
  TGestorMatrizCompras(FGestorMatriz).AddColumna;
end;

procedure TfrmMtoComprasSesiones.btnAddPropClick(Sender: TObject);
begin
  inherited;
  dmComprasSesiones.unqrySesionProps.Append;
end;

procedure TfrmMtoComprasSesiones.btnDelPropClick(Sender: TObject);
begin
  inherited;
  if dmComprasSesiones.unqrySesionProps.IsEmpty then Exit;
  if MessageDlg('¿Borrar la propiedad?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    dmComprasSesiones.unqrySesionProps.Delete;
end;

procedure TfrmMtoComprasSesiones.btnAddKitClick(Sender: TObject);
begin
  inherited;
  dmComprasSesiones.unqrySesionKits.Append;
end;

procedure TfrmMtoComprasSesiones.btnDelKitClick(Sender: TObject);
begin
  inherited;
  if dmComprasSesiones.unqrySesionKits.IsEmpty then Exit;
  if MessageDlg('¿Borrar el kit?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    dmComprasSesiones.unqrySesionKits.Delete;
end;

procedure TfrmMtoComprasSesiones.btnImportarKitPrvClick(Sender: TObject);
begin
  inherited;
  inLibComprasSesiones.ImportarKitsDeProveedor(dmComprasSesiones, oUser);
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitFilaClick(Sender: TObject);
var
  sKit : string;
  nLin, nFil: Integer;
begin
  inherited;
  sKit := cbbKitAplicar.Text;
  if sKit = '' then Exit;
  nLin :=
    dmComprasSesiones.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  nFil := TGestorMatrizCompras(FGestorMatriz).FilaSeleccionada;
  dmComprasSesiones.AplicarKitAFila(sKit, nLin, nFil);
  ReconstruirMatrizActual;
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitTodasClick(Sender: TObject);
var
  sKit : string;
  nLin : Integer;
begin
  inherited;
  sKit := cbbKitAplicar.Text;
  if sKit = '' then Exit;
  nLin :=
    dmComprasSesiones.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  dmComprasSesiones.AplicarKitATodasFilas(sKit, nLin);
  ReconstruirMatrizActual;
end;

procedure TfrmMtoComprasSesiones.btnVistaPreviaMatrizClick(Sender: TObject);
begin
  inherited;
  pcSesion.ActivePage := tsLineas;
  ReconstruirMatrizActual;
end;

procedure TfrmMtoComprasSesiones.btnValidarTodoClick(Sender: TObject);
var
  sError: string;
begin
  inherited;
  if inLibComprasSesiones.ValidarSesion(dmComprasSesiones, sError) then
    MessageDlg('Sesión validada correctamente.', mtInformation, [mbOk], 0)
  else
    MessageDlg('Validación FALLIDA:' + sLineBreak + sError,
               mtWarning,
               [mbOk],
               0);
end;

procedure TfrmMtoComprasSesiones.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  ActualizarEstadoUI;
end;

procedure TfrmMtoComprasSesiones.dsTablaGDataChange(Sender: TObject;
  Field: TField);
begin
  inherited;
  ActualizarEstadoUI;
  ActualizarVisibilidadPreciosSku;
  // Si el cambio es porque navegamos a otra sesion (Field = nil) o porque
  // cambia CODIGO_EMP_SES, refrescar el dropdown del combo de serie.
  if (Field = nil) or
     ((Field <> nil) and (UpperCase(Field.FieldName) = 'CODIGO_EMP_SES')) then
    RellenarItemsSerie;
end;

procedure TfrmMtoComprasSesiones.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  frmSel : TfrmModalSelFamilia;
begin
  inherited;
  // F3 sobre la columna Codigo articulo abre el arbol selector de familias.
  // Al aceptar, se pega el CODIGO_FAM_FAM al campo y el BeforePost del
  // dataset llama a ResolverCodigoFamilia para expandir al siguiente codigo
  // de la serie (ver §2.4-bis del manual de Sesiones).
  if (Key <> VK_F3) or (Shift <> []) then Exit;
  if not Assigned(AItem) then Exit;
  if AItem <> dbcLinCodigoArt then Exit;
  if not EsSesionEditable then Exit;

  frmSel := TfrmModalSelFamilia.Create(Self);
  try
    if frmSel.ShowModal = mrOk then
    begin
      if not (dmComprasSesiones.unqrySesionLin.State in [dsEdit, dsInsert]) then
        dmComprasSesiones.unqrySesionLin.Edit;
      dmComprasSesiones.unqrySesionLin
        .FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString
          := frmSel.CodigoFamilia;
      // Si la descripcion esta vacia, prerellenarla con el nombre de la
      // familia para que la linea quede minimamente identificada hasta
      // que el usuario teclee algo mas concreto.
      if dmComprasSesiones.unqrySesionLin
           .FieldByName('DESCRIPCION_SESLIN').AsString = '' then
        dmComprasSesiones.unqrySesionLin
          .FieldByName('DESCRIPCION_SESLIN').AsString
            := frmSel.NombreFamilia;
      // El Post real lo dispara el usuario al moverse de fila; cuando lo haga
      // BeforePost del dataset expandira al codigo autogenerado.
    end;
  finally
    FreeAndNil(frmSel);
  end;
  Key := 0;
end;

procedure TfrmMtoComprasSesiones.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ReconstruirMatrizActual;
  // Refrescar sub-grid de precios SKU para la nueva linea
  if Assigned(dmComprasSesiones) and
     Assigned(dmComprasSesiones.unqryLineaSkusPrecios) and
     dmComprasSesiones.unqryLineaSkusPrecios.Active then
    dmComprasSesiones.unqryLineaSkusPrecios.Refresh;
end;

procedure TfrmMtoComprasSesiones.ActualizarEstadoUI;
var
  bEditable : Boolean;
begin
  // Defensivo: los botones top-bar pueden no estar creados todavia
  // (la primera vez se llama desde dsTablaGStateChange durante el Open
  //  inicial de unqryTablaG, antes de que el .dfm termine de construir
  //  la jerarquia de controles de la ficha).
  if (csDestroying in ComponentState) then Exit;
  bEditable := EsSesionEditable;
  HabilitarEdicion(bEditable);
  if Assigned(btnCrearMaterializar) then btnCrearMaterializar.Enabled :=
    bEditable;
  if Assigned(btnAnularSesion) then btnAnularSesion.Enabled := bEditable;
  if Assigned(btnCerrarManual) then btnCerrarManual.Enabled := bEditable;
  if Assigned(btnClonarSesion)      then btnClonarSesion.Enabled      := True;
end;

procedure TfrmMtoComprasSesiones.HabilitarEdicion(AHabilitar: Boolean);
begin
  if Assigned(cbbProveedor)     then cbbProveedor.Enabled     := AHabilitar;
  if Assigned(cbbEmpresa)       then cbbEmpresa.Enabled       := AHabilitar;
  if Assigned(txtRefPrv)        then txtRefPrv.Enabled        := AHabilitar;
  if Assigned(cbbAlmacen)       then cbbAlmacen.Enabled       := AHabilitar;
  if Assigned(cbbVariacion)     then cbbVariacion.Enabled     := AHabilitar;
  if Assigned(cbbConjuntoPivot) then cbbConjuntoPivot.Enabled := AHabilitar;
  if Assigned(cbbConjuntoFila)  then cbbConjuntoFila.Enabled  := AHabilitar;
  if Assigned(btnAddLinea)      then btnAddLinea.Enabled      := AHabilitar;
  if Assigned(btnDelLinea)      then btnDelLinea.Enabled      := AHabilitar;
  if Assigned(btnDupLinea)      then btnDupLinea.Enabled      := AHabilitar;
  if Assigned(btnAddFila)       then btnAddFila.Enabled       := AHabilitar;
  if Assigned(btnDelFila)       then btnDelFila.Enabled       := AHabilitar;
  if Assigned(btnAddColumna)    then btnAddColumna.Enabled    := AHabilitar;
  if Assigned(btnAddProp)       then btnAddProp.Enabled       := AHabilitar;
  if Assigned(btnDelProp)       then btnDelProp.Enabled       := AHabilitar;
  if Assigned(btnAddKit)        then btnAddKit.Enabled        := AHabilitar;
  if Assigned(btnDelKit)        then btnDelKit.Enabled        := AHabilitar;
end;

function TfrmMtoComprasSesiones.EsSesionEditable: Boolean;
var
  dm : TdmComprasSesiones;
begin
  // Usamos tdmDataModule (propiedad del form, vida ligada al form) en vez
  // de la variable global dmComprasSesiones, que puede quedar dangling al
  // cerrar y reabrir la pantalla y provocar AV en GetActive.
  Result := False;
  if not Assigned(tdmDataModule) then Exit;
  if not (tdmDataModule is TdmComprasSesiones) then Exit;
  dm := TdmComprasSesiones(tdmDataModule);
  if dm.unqryTablaG = nil then Exit;
  if not dm.unqryTablaG.Active then Exit;
  // En insercion siempre editable: el state change se dispara antes de
  // que AfterInsert ponga ESTADO_SES='BORRADOR', por lo que sin esta
  // guarda los controles quedarian disabled durante el alta.
  if dm.unqryTablaG.State = dsInsert then Exit(True);
  if dm.unqryTablaG.IsEmpty then Exit;
  Result := dm.unqryTablaG.FieldByName('ESTADO_SES').AsString = 'BORRADOR';
end;

procedure TfrmMtoComprasSesiones.ReconstruirMatrizActual;
var
  sAlmCab : string;
begin
  if dmComprasSesiones.unqrySesionLin.IsEmpty then Exit;

  // Si el combo de almacen está vacio, inicializarlo con el almacen de
  // cabecera para que la matriz arranque editando ese.
  if (VarToStr(cbbAlmacenMatriz.EditValue) = '') and
     (not dmComprasSesiones.unqryTablaG.IsEmpty) then
  begin
    sAlmCab := dmComprasSesiones.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
    if sAlmCab <> '' then
    begin
      cbbAlmacenMatriz.EditValue := sAlmCab;
      TGestorMatrizCompras(FGestorMatriz).AlmacenActual := sAlmCab;
    end;
  end;
  TGestorMatrizCompras(FGestorMatriz).ReconstruirMatriz(
    dmComprasSesiones.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger);
end;

procedure TfrmMtoComprasSesiones.ReconstruirResumenMaterializacion;
var
  iArts, iSkus : Integer;
  rTotal       : Double;
begin
  iArts  := inLibComprasSesiones.ContarArticulosNuevos(dmComprasSesiones);
  iSkus  := inLibComprasSesiones.ContarSkusPotenciales(dmComprasSesiones);
  rTotal := inLibComprasSesiones.CalcularTotalCompra(dmComprasSesiones);
  lblResNumArticulos.Caption := Format('► %d artículos nuevos en fza_articulos',
                                                                       [iArts]);
  lblResNumSkus.Caption := Format('► %d SKUs en fza_articulos_skus', [iSkus]);
  lblResNumEan13.Caption     :=
    Format('► %d EAN13 a generar en fza_codigos_barras', [iSkus]);
  lblResNumPropiedades.Caption :=
    '► Propiedades fijas heredadas a cada artículo';
  lblResEnlacePrv.Caption    :=
    '► 1 enlace artículo↔proveedor en fza_articulos_proveedores';
  lblResConflictos.Caption   := Format('► Total compra: %.2f €', [rTotal]);
end;

// ------------------- Actions / shortcuts -----------------------------------

procedure TfrmMtoComprasSesiones.actMaterializarExecute(Sender: TObject);
begin
  inherited;
  btnCrearMaterializarClick(Sender);
end;

procedure TfrmMtoComprasSesiones.actNuevaLineaExecute(Sender: TObject);
begin
  inherited;
  if pcSesion.ActivePage = tsLineas then btnAddLineaClick(Sender);
end;

procedure TfrmMtoComprasSesiones.actBorrarLineaExecute(Sender: TObject);
begin
  inherited;
  if pcSesion.ActivePage = tsLineas then btnDelLineaClick(Sender);
end;

procedure TfrmMtoComprasSesiones.actDuplicarLineaExecute(Sender: TObject);
begin
  inherited;
  if pcSesion.ActivePage = tsLineas then btnDupLineaClick(Sender);
end;

procedure TfrmMtoComprasSesiones.actAplicarKitExecute(Sender: TObject);
begin
  inherited;
  if pcSesion.ActivePage = tsLineas then btnAplicarKitFilaClick(Sender);
end;

procedure TfrmMtoComprasSesiones.actValidarExecute(Sender: TObject);
begin
  inherited;
  btnValidarTodoClick(Sender);
end;

// ---------------------------------------------------------------------------
// Sub-grid de precios por SKU
// ---------------------------------------------------------------------------

procedure TfrmMtoComprasSesiones.ActualizarVisibilidadPreciosSku;
var
  bVisible : Boolean;
begin
  if (dmComprasSesiones = nil) or
     (dmComprasSesiones.unqryTablaG = nil) or
     (not dmComprasSesiones.unqryTablaG.Active) then Exit;
  bVisible := (not dmComprasSesiones.unqryTablaG.IsEmpty) and
              (dmComprasSesiones.unqryTablaG.FieldByName(
                                        'ESPRECIO_POR_SKU_SES').AsString = 'S');
  if Assigned(gbPreciosSku)   then
    gbPreciosSku.Visible   := bVisible;
  if Assigned(splPreciosSku)  then
    splPreciosSku.Visible  := bVisible;
  if bVisible and Assigned(dmComprasSesiones.unqryLineaSkusPrecios) then
  begin
    if not dmComprasSesiones.unqryLineaSkusPrecios.Active then
      dmComprasSesiones.unqryLineaSkusPrecios.Open
    else
      dmComprasSesiones.unqryLineaSkusPrecios.Refresh;
  end;
end;

procedure TfrmMtoComprasSesiones.UpsertPrecioSku(AField: string;
                                                 ANuevo: Double);
var
  q : TUniQuery;
  qSrc : TUniQuery;
begin
  if dmComprasSesiones.unqryLineaSkusPrecios.IsEmpty then Exit;
  qSrc := dmComprasSesiones.unqryLineaSkusPrecios;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_lineas_skus_precios ' +
      '  (SERIE_SES_SESLINSKU, NUMERO_SES_SESLINSKU, LINEA_SES_SESLINSKU, ' +
      '   ID_FILA_SES_SESLINSKU, ID_AV_PIVOT_SESLINSKU, ' +
      '   ' + AField + ', INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:s, :n, :l, :f, :p, :v, NOW(), :u, NOW(), :u) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  ' + AField + ' = :v, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
    q.ParamByName('s').AsString :=
                dmComprasSesiones.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
               dmComprasSesiones.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger :=
         dmComprasSesiones.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    q.ParamByName('f').AsInteger := qSrc.FieldByName('ID_FILA').AsInteger;
    q.ParamByName('p').AsInteger := qSrc.FieldByName('ID_AV_PIVOT').AsInteger;
    if ANuevo = 0 then
      q.ParamByName('v').Clear
    else
      q.ParamByName('v').AsFloat := ANuevo;
    q.ParamByName('u').AsString := oUser;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoComprasSesiones.dbcPreciosSkuPrecioCompraPropertiesEditValueChanged(
  Sender: TObject);
var
  edt : TcxCustomEdit;
  v   : Double;
begin
  inherited;
  edt := Sender as TcxCustomEdit;
  edt.PostEditValue;
  v := dmComprasSesiones.unqryLineaSkusPrecios
         .FieldByName('PRECIO_COMPRA_SESLINSKU').AsFloat;
  UpsertPrecioSku('PRECIO_COMPRA_SESLINSKU', v);
end;

procedure TfrmMtoComprasSesiones.
            dbcPreciosSkuPrecioVentaPropertiesEditValueChanged(Sender: TObject);
var
  edt : TcxCustomEdit;
  v   : Double;
begin
  inherited;
  edt := Sender as TcxCustomEdit;
  edt.PostEditValue;
  v := dmComprasSesiones.unqryLineaSkusPrecios
         .FieldByName('PRECIO_VENTA_SESLINSKU').AsFloat;
  UpsertPrecioSku('PRECIO_VENTA_SESLINSKU', v);
end;

initialization
  ForceReferenceToClass(TfrmMtoComprasSesiones);
end.
