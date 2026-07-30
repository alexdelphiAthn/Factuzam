{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoInventarios                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de inventarios de almacen.                                  }
{    Recuento de stock por almacen y articulo con regularizacion.              }
{******************************************************************************}
unit inMtoInventarios;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  Data.DB, cxDBData, cxContainer, cxCheckBox, cxTextEdit, cxGridLevel,
  cxClasses, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxMaskEdit,
  cxDropDownEdit, cxDBEdit, cxLabel, cxGridBandedTableView,
  cxGridDBBandedTableView, cxLocalization, cxCurrencyEdit,
  dxBevel, cxDBNavigator, UniDataInventarios, cxGridExportLink,
  dxDateRanges, MemDS, DBAccess, Uni, inMtoGen, Vcl.Menus, cxButtons,
  cxMemo, cxSpinEdit, cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  System.Actions, Vcl.ActnList, cxButtonEdit, cxSplitter, cxRadioGroup,
  cxGroupBox, JvComponentBase, JvEnterTab, dxShellDialogs, system.UITypes,
  dxCoreGraphics, strUtils, cxCalc, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan, System.Generics.Collections, System.Types,
  dxSpreadSheet, dxSpreadSheetCore,
  // Contrato de entrada de articulos (ColumnSKUcxGrid, en src\Lib).
  inLibColumnasSkuIntf;

type
  TfrmMtoInventarios = class(TfrmMtoGen)
    dlgAbrir: TOpenDialog;
    // Columnas del grid de la pestana Lista (view heredado cxGrdDBTabPrin)
    colCODIGO_EMP_INV: TcxGridDBColumn;
    colCODIGO_ALM_INV: TcxGridDBColumn;
    colSERIE_INV: TcxGridDBColumn;
    colNUMERO_INV: TcxGridDBColumn;
    colFECHA_INV: TcxGridDBColumn;
    colESTADO_INV: TcxGridDBColumn;
    colDESCRIPCION_INV: TcxGridDBColumn;
    colTOT_UDS_DIF_INV: TcxGridDBColumn;
    colTOT_EUR_DIF_INV: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblEmpresa: TcxLabel;
    cbbCODIGO_EMPRESA_INVENTARIO: TcxDBLookupComboBox;
    lblAlmacen: TcxLabel;
    cbbCODIGO_ALMACEN_INVENTARIO: TcxDBLookupComboBox;
    lblSerie: TcxLabel;
    cbbSERIE_INVENTARIO: TcxDBLookupComboBox;
    lblNumero: TcxLabel;
    txtNRO_INVENTARIO: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dtFECHA_INVENTARIO: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_INVENTARIO: TcxDBTextEdit;
    btnAplicar: TcxButton;
    lblDescripcion: TcxLabel;
    txtDESCRIPCION_INVENTARIO: TcxDBTextEdit;
    btnCargar: TcxButton;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsDetalle: TcxTabSheet;
    pnlDetalleTop: TPanel;
    btnAnadirLinea: TcxButton;
    btnAnadirSkusArt: TcxButton;
    btnRecalcularDetalle: TcxButton;
    btnCargarExcel: TcxButton;
    btnExportarInv: TcxButton;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    tvLineasLINEA: TcxGridDBColumn;
    tvLineasARTICULO: TcxGridDBColumn;
    tvLineasUNIDAD: TcxGridDBColumn;
    tvLineasDESCRIPCION: TcxGridDBColumn;
    tvLineasSKU1: TcxGridDBColumn;
    tvLineasSKU2: TcxGridDBColumn;
    tvLineasSKU3: TcxGridDBColumn;
    tvLineasSKU4: TcxGridDBColumn;
    tvLineasSKU5: TcxGridDBColumn;
    tvLineasLOTE: TcxGridDBColumn;
    tvLineasCADUCIDAD: TcxGridDBColumn;
    tvLineasUDS_TEORICAS: TcxGridDBColumn;
    tvLineasUDS_FISICAS: TcxGridDBColumn;
    tvLineasPMP_ACTUAL: TcxGridDBColumn;
    tvLineasPMP_NUEVO: TcxGridDBColumn;
    tvLineasDIF_UNIDADES: TcxGridDBColumn;
    tvLineasDIF_COSTE: TcxGridDBColumn;
    tvLineasUDS_REGULARIZADAS: TcxGridDBColumn;
    tvLineasFECHA_RECUENTO: TcxGridDBColumn;
    tvLineasUSUARIO: TcxGridDBColumn;
    cxgrdlvlLineas: TcxGridLevel;
    tsMovsRegul: TcxTabSheet;
    pnlMovsTop: TPanel;
    lblInfoMovs: TcxLabel;
    btnEliminarRegularizacion: TcxButton;
    cxgrdMovs: TcxGrid;
    tvMovs: TcxGridDBTableView;
    tvMovsNUMERO: TcxGridDBColumn;
    tvMovsTIPO: TcxGridDBColumn;
    tvMovsARTICULO: TcxGridDBColumn;
    tvMovsUNIDAD: TcxGridDBColumn;
    tvMovsCANTIDAD: TcxGridDBColumn;
    tvMovsPRECIO: TcxGridDBColumn;
    tvMovsCOSTE: TcxGridDBColumn;
    tvMovsFECHA: TcxGridDBColumn;
    tvMovsACTIVO: TcxGridDBColumn;
    cxgrdlvlMovs: TcxGridLevel;
    tsCabecera: TcxTabSheet;
    pnlCabecera: TPanel;
    lblObservaciones: TcxLabel;
    mmoOBSERVACIONES_INVENTARIO: TcxDBMemo;
    pnlTotales: TGroupBox;
    lblTotalUnidades: TcxLabel;
    txtTOTAL_UNIDADES_DIFERENCIA: TcxDBTextEdit;
    lblTotalEuros: TcxLabel;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    curTOTAL_EUROS_DIFERENCIA_INV: TcxDBCurrencyEdit;
    btnIraArticulo: TcxButton;
    pnlBotonesAccion: TPanel;
    btnExportarExcel: TcxButton;
    btnIraArticuloMov: TcxButton;
    ActionList1: TActionList;
    actIraArticulo: TAction;
    chkVerColumnasAtributos: TcxCheckBox;
    btnEnviarRecuento: TcxButton;
    btnRecogerRecuento: TcxButton;

    // === EVENTOS ===
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AplicarEtiquetas; override;
    procedure pcDetailChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);

    // Cabecera
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);

    // Detalle
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnAnadirSkusArtClick(Sender: TObject);
    procedure btnEliminarLineaClick(Sender: TObject);
    procedure btnRecalcularDetalleClick(Sender: TObject);
    procedure cxgrdLineasEnter(Sender: TObject);
    procedure tvLineasArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure tvLineasSkuPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure tvLineasUdsFisicasPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasGetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
    procedure tvLineasFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvLineasInitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure tvLineasEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    procedure tvLineasCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure OnAtributoChanged(Sender: TObject);
    procedure ForzarDespliegue(Sender: TObject);

    // Movs Regularizados
    procedure btnEliminarRegularizacionClick(Sender: TObject);
    procedure btnExportarInvClick(Sender: TObject);
    procedure btnEnviarRecuentoClick(Sender: TObject);
    procedure btnRecogerRecuentoClick(Sender: TObject);

    // Cargas masivas
    procedure btnCargarPorFamiliaClick(Sender: TObject);
    procedure btnCargarPorProveedorClick(Sender: TObject);
    procedure btnCompletarClick(Sender: TObject);
    procedure btnCargarTodoClick(Sender: TObject);
    procedure btnCargarExcelClick(Sender: TObject);
    procedure edtRutaExcelPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnCargarClick(Sender: TObject);
    procedure cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnIraArticuloMovClick(Sender: TObject);
    procedure actIraArticuloExecute(Sender: TObject);
    procedure chkVerColumnasAtributosPropertiesChange(Sender: TObject);

  private
    FNumAtributosActual: Integer;
    FUltimoArticuloPadre: string;
    FProcesandoAtributo: Boolean;
    FInicializandoCombo: Boolean;
    FRefrescandoLookupsCabecera: Boolean;
    // Setting on/off para construir las columnas dinamicas de atributos.
    // Por defecto OFF: abrir un inventario solo pinta el grid base, sin
    // ejecutar la SQL de definicion de atributos ni el desempaquetado
    // SKU->ATTR1..ATTR5 (que requiere un Edit/Post por linea). El usuario
    // lo activa con chkVerColumnasAtributos cuando quiere editar.
    FMostrarColumnasAtributos: Boolean;
    // En modo "atributos en columna" las columnas (Talla, Color...) se calculan
    // a nivel de inventario (no por la fila enfocada) una sola vez por
    // inventario; este flag marca si ya estan aplicadas.
    FAtributosVistaAplicados: Boolean;
    // Umbral a partir del cual el desempaquetado merece un progressbar.
    // Por debajo, el cdsLineas con DisableControls va lo bastante rapido
    // como para no necesitar feedback visual.
    FUmbralProgresoDesempaquetado: Integer;
    // Bitmap reutilizable para pintar el cuadradito de color en el glyph
    // del boton [...] de las columnas SKU. Se repinta en cada InitEdit con
    // el color del AV actual; si no hay color, el boton vuelve a bkEllipsis.
    FBmpSwatchBoton: TBitmap;

    // === CONTRATO DE ENTRADA ColumnSKUcxGrid (prueba en Mto real) ===
    // F1 cicla Auto -> SKU -> Tallas horizontal. Auto resuelve a
    // desglose (el cds define ATTR1..5). El Construir del contrato
    // hace ClearItems: las columnas del dfm mueren en la primera
    // construccion y las numericas se recrean en runtime; las rutas
    // legacy de columnas quedan cortocircuitadas con
    // FColsModoConstruido.
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;

    // === LÓGICA DINÁMICA SKUs (mismo patrón que inMtoCajaOpe) ===
    procedure ActualizarColumnasDinamicas(const ArticuloPadre: string);
    procedure RellenarAtributosDesdeSku(const Sku: string);
    function ObtenerColumnaSkuPorTag(NumColumn: Integer): TcxGridDBColumn;
    function ObtenerNumAtributosArticulo(
      const ACodigoArticulo: string): Integer;
    // Modo "atributos en columna": con el toggle activo, la columna unificada
    // SKU/Articulo cede el sitio a la columna Articulo (que pasa a ser la
    // entrada inteligente) seguida de las columnas de atributos; con el toggle
    // inactivo se ve la unificada y Articulo/atributos quedan ocultas.
    procedure AplicarModoColumnasEntrada(AModoAtributos: Boolean);
    // Columna de entrada activa segun el modo: Articulo si atributos en
    // columna esta activo, si no la unificada SKU/Articulo.
    function ColumnaEntradaActiva: TcxGridDBColumn;
    // Calcula y pinta las columnas de atributo (Talla, Color...) a nivel de
    // inventario: numero maximo de atributos de todas las lineas y nombres
    // (en su ORDEN_VISUAL) del articulo que mas atributos tiene. Asi las
    // columnas son estables al navegar y aparecen aunque la fila enfocada sea
    // un articulo sin variaciones.
    procedure AplicarColumnasAtributosVista;
    // Asegura que cdsLineas tiene los ATTR1..ATTR5_VALOR rellenados
    // (idempotente: no hace nada si ya estan, ver dmm.LineasDesempaquetadas).
    // Si hay mas de FUmbralProgresoDesempaquetado lineas, muestra el overlay
    // de progreso heredado de TfrmMtoGen mientras corre el bucle.
    procedure AsegurarDesempaquetadoAtributos;
//    procedure ConstruirSkuDesdeAtributos;

    // === SELECTOR DE AV CON CUADRADITO DE PALETA ===
    // Carga los AVs validos para (articulo padre, posicion) — misma SQL que
    // antes usaba InitEdit para poblar el combo.
    procedure CargarAvsValidos(const ACodArt: string; AOrden: Integer;
                               var AAvs: TArray<string>);
    // Aplica AV al campo ATTRn_VALOR y dispara el rebuild del SKU + recalculo
    // de teorico/PMP si la fila queda completa. Es la version "sin editor"
    // del cuerpo de OnAtributoChanged.
    procedure RegistrarValorAtributo(AOrden: Integer; const AvNuevo: string);
    // Handler OnEnter de un sigle-shot que abre el popup en cuanto el cursor
    // entra en la celda (sustituye a ForzarDespliegue para los TcxButtonEdit).
    procedure AbrirPopupSkuEnEntrada(Sender: TObject);

    // === BUSQUEDA UNIFICADA DE ARTICULOS (codigo, SKU o codigo de barras) ===
    procedure ResolverInputArticulo(const AInput: string;
                                    out ACodigoPadre: string;
                                    out ACodigoSku: string;
                                    out ADescripcion: string;
                                    out ATipoArt: string;
                                    out AEncontrado: Boolean);
    procedure RellenarLineaDesdeBusqueda(const AInput: string;
                                         var AResolvedValue: string;
                                         var AError: Boolean;
                                         var AErrorText: TCaption);
    function BuscarArticuloDialog: string;
    function BuscarSkuDialog: string;

    // === ACTUALIZACIÓN UI SEGÚN ESTADO ===
    procedure ActualizarEstadoUI;
    procedure HabilitarEdicionLineas(Habilitado: Boolean);
    procedure RefrescarLookupsCabeceraEmpresa(const AEmpresa: string);

    // === HOOKS DATASET ===
    procedure cdsLineasAfterInsertHook(DataSet: TDataSet);

    // === HELPERS ===
    function ComprobarRecuentoRemotoDisponible: Boolean;
    function EstadoActual: string;
    function PuedeEditar: Boolean;
    function AsegurarCabeceraPersistidaParaLineas: Boolean;
    procedure AsegurarPrimeraLineaInventario;
    procedure CargarLineasYRefrescar;
    // === CONTRATO DE ENTRADA: construccion y enganches ===
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostInventario;
    // Las columnas de atributo del contrato nacen ocultas hasta que
    // se resuelve un articulo: precargarlas con los nombres globales
    // (mismo helper que el banco de pruebas) para verlas al entrar.
    procedure MostrarColumnasAtributoGlobales;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);

  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

  public
    dmmInventarios: TdmInventarios;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibWin,
  inLibUser,
  inLibFiltroUsuario,
  inLibShowMto,
  inLibDevExp,
  inLibGenBusq,

  inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibAtributosPaleta,
  inLibLog,
  inLibMsgArticulos,
  inLibInventarioExcel, inLibHojaCalculoDevEx,
  inLibInventarioNube,
  inMtoPreviewExcel,
  System.Diagnostics,
  inMtoModalAddBlockInventario,
  // Factoria del contrato de entrada (prueba ColumnSKUcxGrid).
  inLibColumnasSku, inLibColumnasDocumento, UniDataGen;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoInventarios }

// dsTablaG apunta a la cabecera del inventario. El articulo activo
// vive en la linea seleccionada del sub-grid tvLineas (CODIGO_ART_INVLIN
// / CODIGO_UNIDAD_INVLIN).
procedure TfrmMtoInventarios.ResolverArtSkuActivo(out ACodArt,
                                                  ACodSku: string);
begin
  ResolverArtSkuActivoDocumento(
    tvLineas, ACodArt, ACodSku);
end;

function TfrmMtoInventarios.DataSourcesParaFoto: TArray<TDataSource>;
begin
  Result := DataSourcesParaFotoDocumento(
    dsTablaG, tvLineas);
end;

function TfrmMtoInventarios.ComprobarRecuentoRemotoDisponible: Boolean;
begin
  Result := Assigned(dmmInventarios) and
            dmmInventarios.ColumnasRecuentoRemoto;
  if not Result then
    ShowMessage(SErrorMigracionRecuentoInventariosNoAplicada);
end;

function TfrmMtoInventarios.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroDocumento(
    ContextoSesion, ParametrosApp, 'INV');
end;

procedure TfrmMtoInventarios.CrearTablaPrincipal;
var
  emp: string;
begin
  dmmInventarios := nil;
  inherited;
  dmmInventarios := TdmInventarios(AsegurarDataModuleDocumento(
    Self, tdmDataModule, TdmInventarios));
  ConfigurarTablaPrincipalDocumento(
    dmmInventarios, dsTablaG, tvLineas, dmmInventarios.dsLineas,
    [], pkFieldName, '');
  emp := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
    emp := dsTablaG.DataSet.FieldByName('CODIGO_EMP_INV').AsString
  else if Trim(UbicacionSesion.Empresa) <> '' then
    emp := UbicacionSesion.Empresa;
  RefrescarLookupsCabeceraEmpresa(emp);
  // Datasources locales que apuntan a queries del data module.
  // El lookup de almacenes debe estar cargado antes de enlazarse, porque
  // DevExpress puede validar el valor actual y dejar la cabecera en dsEdit.
  FRefrescandoLookupsCabecera := True;
  try
    cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource :=
                                                      dmmInventarios.dsEmpresas;
    cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource :=
                                                     dmmInventarios.dsAlmacenes;
    cbbSERIE_INVENTARIO.Properties.ListSource := dmmInventarios.dsSeries;
  finally
    FRefrescandoLookupsCabecera := False;
  end;
  tvMovs.DataController.DataSource   := dmmInventarios.dsMovsRegul;
  dmmInventarios.cdsLineas.AfterInsert := cdsLineasAfterInsertHook;
end;

procedure TfrmMtoInventarios.FormCreate(Sender: TObject);
begin
  inherited;
//  pcDetail.ActivePage := tsCabecera;
  FNumAtributosActual := 0;
  FUltimoArticuloPadre := '';
  FProcesandoAtributo := False;
  FInicializandoCombo := False;
  FRefrescandoLookupsCabecera := False;
  // Por defecto OFF: la apertura de un inventario solo lee las lineas, sin
  // ejecutar la SQL de definicion de atributos ni el bucle de Edit/Post
  // sobre cada linea que rellena ATTR1..5_VALOR. El usuario lo activa con
  // chkVerColumnasAtributos cuando va a editar.
  FMostrarColumnasAtributos := False;
  // Contrato de entrada (prueba ColumnSKUcxGrid): Auto por defecto
  // (resuelve a desglose) y F1 cicla Auto -> SKU -> Tallas. El toggle
  // clasico queda oculto: el modo lo gobierna el contrato.
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  chkVerColumnasAtributos.Visible := False;
  // 150 lineas es el umbral empirico: por debajo el desempaquetado va
  // imperceptible aunque haga un Edit/Post por linea (DisableControls
  // suprime el repintado del grid). Por encima, el usuario nota la
  // espera, asi que mostramos el overlay con progressbar marquee.
  FUmbralProgresoDesempaquetado := 150;
  FBmpSwatchBoton := TBitmap.Create;
  // El TcxCheckBox arranca unchecked desde el DFM, alineado con
  // FMostrarColumnasAtributos := False. No tocamos .Checked aqui para
  // no disparar chkVerColumnasAtributosPropertiesChange en el create.
  // Inicialmente ocultas las columnas dinámicas
  ActualizarColumnasDinamicas('');
end;

procedure TfrmMtoInventarios.AplicarEtiquetas;
begin
  inherited;
  // La columna de entrada del articulo depende del modo "atributos en columna":
  // con el toggle activo es la columna Articulo (codigo), si no la unificada
  // SKU/Articulo. Dejamos que el modo gobierne la visibilidad en vez de forzar
  // Articulo siempre oculta.
  if FMostrarColumnasAtributos then
    AplicarModoColumnasEntrada(True)
  else
  begin
    FUltimoArticuloPadre := '__FORZAR__';
    ActualizarColumnasDinamicas('');
  end;
end;

procedure TfrmMtoInventarios.FormDestroy(Sender: TObject);
begin
  // Contrato de entrada: soltar eventos del view y liberar el modo
  // ANTES de que muera el form (evita punteros colgantes en el grid).
  if FModoEntrada <> nil then
  begin
    if Assigned(tvLineas) then
    begin
      tvLineas.OnInitEdit := nil;
      tvLineas.OnEditKeyDown := nil;
      tvLineas.OnEditing := nil;
      tvLineas.OnFocusedRecordChanged := nil;
      tvLineas.OnFocusedItemChanged := nil;
    end;
    FModoEntrada := nil;
  end;
  inherited;
  FreeAndNil(FBmpSwatchBoton);
  if Assigned(cbbCODIGO_EMPRESA_INVENTARIO) then
    cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource := nil;
  if Assigned(cbbCODIGO_ALMACEN_INVENTARIO) then
    cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource := nil;
  if Assigned(cbbSERIE_INVENTARIO) then
    cbbSERIE_INVENTARIO.Properties.ListSource := nil;
  if Assigned(tvLineas) then
    tvLineas.DataController.DataSource := nil;
  if Assigned(tvMovs) then
    tvMovs.DataController.DataSource := nil;
  dmmInventarios := nil;
end;

procedure TfrmMtoInventarios.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsDetalle;
end;

function TfrmMtoInventarios.AsegurarCabeceraPersistidaParaLineas: Boolean;
var
  dsCab: TDataSet;
begin
  Result := False;
  if Assigned(dmmInventarios) then
  begin
    dsCab := dmmInventarios.unqryTablaG;
    if (dsCab <> nil) and dsCab.Active and
       ((not dsCab.IsEmpty) or (dsCab.State in [dsInsert, dsEdit])) then
    begin
      Result := True;
      if dsCab.State in [dsInsert, dsEdit] then
      begin
        try
          dsCab.Post;
          CargarLineasYRefrescar;
        except
          on E: Exception do
          begin
            Result := False;
            ShowMessage(Format(
              SErrorGrabarCabeceraInventarioAutomaticamente,
              [E.Message]));
            pcDetail.ActivePage := tsCabecera;
          end;
        end;
      end
      else if not dmmInventarios.cdsLineas.Active then
        CargarLineasYRefrescar;
    end;
  end;
end;

procedure TfrmMtoInventarios.AsegurarPrimeraLineaInventario;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmInventarios) then
  begin
    dsCab := dmmInventarios.unqryTablaG;
    dsLin := dmmInventarios.cdsLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       ((not dsCab.IsEmpty) or (dsCab.State in [dsInsert, dsEdit])) then
    begin
      if AsegurarCabeceraPersistidaParaLineas then
      begin
        sNumero := Trim(dsCab.FieldByName('NUMERO_INV').AsString);
        sSerie  := Trim(dsCab.FieldByName('SERIE_INV').AsString);
        if (sNumero <> '') and (sNumero <> '0') and (sSerie <> '') then
        begin
          if not dsLin.Active then
            CargarLineasYRefrescar;
          if dsLin.Active and dsLin.IsEmpty and PuedeEditar and
             (not (dsLin.State in [dsEdit, dsInsert])) then
            btnAnadirLineaClick(cxgrdLineas);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoInventarios.cxgrdLineasEnter(Sender: TObject);
begin
  inherited;
  AsegurarPrimeraLineaInventario;
  // Red de seguridad: si el modo se construyo con el cds aun vacio
  // (la carga de lineas del data module no pasa por el form), las
  // lineas estan sin desempaquetar y los atributos se ven en blanco.
  // Reconstruir aqui, con las lineas ya cargadas, lo endereza.
  if (FModoEntrada <> nil) and (FModoEntradaSel <> mcsSku) and
     (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) and
     (not dmmInventarios.LineasDesempaquetadas) then
    ConstruirModoEntrada;
  // Contrato activo: al entrar en el grid, editor en la celda de
  // entrada del modo (sustituye al despliegue de la columna clasica).
  if (FModoEntrada <> nil) and PuedeEditar then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoInventarios.pcDetailChange(Sender: TObject);
var
  ds: TDataSet;
begin
  if pcDetail.ActivePage = tsDetalle then
  begin
    // Si la cabecera está sin grabar (dsInsert/dsEdit), la grabamos
    // automáticamente: las líneas referencian (EMP/ALM/SERIE/NRO) y el
    // número definitivo se asigna en unqryTablaGBeforePost desde
    // fza_contadores.
    ds := dsTablaG.DataSet;
    if (ds <> nil) and ds.Active and (ds.State in [dsInsert, dsEdit]) then
    begin
      try
        ds.Post;
      except
        on E: Exception do
        begin
          ShowMessage(Format(
            SErrorGrabarCabeceraInventarioAutomaticamenteDetalle,
            [E.Message]));
          pcDetail.ActivePage := tsCabecera;
          Exit;
        end;
      end;
    end;
    CargarLineasYRefrescar;
  end
  else if pcDetail.ActivePage = tsMovsRegul then
  begin
    ds := dsTablaG.DataSet;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
      dmmInventarios.SetClavesActivas(
        ds.FieldByName('CODIGO_EMP_INV').AsString,
        ds.FieldByName('CODIGO_ALM_INV').AsString,
        ds.FieldByName('SERIE_INV').AsString,
        ds.FieldByName('NUMERO_INV').AsString
      );
    dmmInventarios.CargarMovimientosRegularizacion;
  end;

  ActualizarEstadoUI;
end;

procedure TfrmMtoInventarios.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  ActualizarEstadoUI;
end;

procedure TfrmMtoInventarios.dsTablaGDataChange(Sender: TObject; Field: TField);
var
  emp: string;
begin
  inherited;
  if (csDestroying in ComponentState) then Exit;

  // Si cambia el registro activo, recargamos el lookup de almacenes
  if (Field = nil) or
     ((Field <> nil) and (Field.FieldName = 'CODIGO_EMP_INV')) then
  begin
    if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
       not dsTablaG.DataSet.IsEmpty then
    begin
      emp := dsTablaG.DataSet.FieldByName('CODIGO_EMP_INV').AsString;
      if dmmInventarios <> nil then
      begin
        RefrescarLookupsCabeceraEmpresa(emp);
      end;
    end;
  end;
  if Field = nil then
  begin
    ActualizarEstadoUI;
    // Recargar lineas cuando cambia el registro activo y la pestana
    // Detalle esta visible (navegacion entre inventarios desde la ficha
    // o entrada desde la lista).
    if pcDetail.ActivePage = tsDetalle then
      CargarLineasYRefrescar;
  end;
end;

function TfrmMtoInventarios.EstadoActual: string;
begin
  Result := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) then
    Result := dsTablaG.DataSet.FieldByName('ESTADO_INV').AsString;
end;

function TfrmMtoInventarios.PuedeEditar: Boolean;
begin
  Result := EstadoActual = 'ABIERTO';
end;

procedure TfrmMtoInventarios.ActualizarEstadoUI;
var
  Estado: string;
  Edicion: Boolean;
begin
  Estado := EstadoActual;
  Edicion := PuedeEditar;

  // Etiqueta visual del estado
  //lblEstadoDetalle.Caption := 'Estado del inventario: ' + Estado;

  // Botones de acciones globales
{  btnRecalcular.Enabled               := Edicion;
  btnAplicar.Enabled                  := Edicion;
  btnRecalcularDetalle.Enabled        := Edicion;
  btnAnadirLinea.Enabled              := Edicion;
  btnEliminarLinea.Enabled            := Edicion;
  btnCargarPorFamilia.Enabled         := Edicion;
  btnCargarPorProveedor.Enabled       := Edicion;
  btnCompletar.Enabled                := Edicion;
  btnCargarTodo.Enabled               := Edicion;
  btnCargarExcel.Enabled              := Edicion;
  btnEliminarRegularizacion.Enabled   := Estado = 'APLICADO';
 }
  HabilitarEdicionLineas(Edicion);
end;

procedure TfrmMtoInventarios.HabilitarEdicionLineas(Habilitado: Boolean);
begin
  // Si está APLICADO o CANCELADO, el grid de líneas es solo lectura
  tvLineas.OptionsData.Editing  := Habilitado;
  tvLineas.OptionsData.Inserting := Habilitado;
  tvLineas.OptionsData.Deleting := Habilitado;
end;

procedure TfrmMtoInventarios.RefrescarLookupsCabeceraEmpresa(
  const AEmpresa: string);
begin
  if dmmInventarios <> nil then
  begin
    FRefrescandoLookupsCabecera := True;
    try
      dmmInventarios.CargarAlmacenesPorEmpresa(AEmpresa);
    finally
      FRefrescandoLookupsCabecera := False;
    end;
  end;
end;

procedure TfrmMtoInventarios.CargarLineasYRefrescar;
var
  ds: TDataSet;
begin
  ds := dsTablaG.DataSet;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
    Exit;

  // IMPORTANTE: tras un Post de cabecera nueva, AfterScroll NO siempre se
  // dispara (no hay cambio de registro real). Si no resincronizamos las
  // claves del data module con los valores actuales de la cabecera, las
  // líneas recién insertadas por la modal de carga no se ven, porque
  // unqryLineas se reabre con parámetros desactualizados.
  dmmInventarios.SetClavesActivas(
    ds.FieldByName('CODIGO_EMP_INV').AsString,
    ds.FieldByName('CODIGO_ALM_INV').AsString,
    ds.FieldByName('SERIE_INV').AsString,
    ds.FieldByName('NUMERO_INV').AsString
  );
  dmmInventarios.CargarLineasInventario;
  // Inventario recargado: las columnas de atributo (vista) se recalculan para
  // las lineas nuevas.
  FAtributosVistaAplicados := False;
  if dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
  begin
    // CargarLineasInventario ha reseteado LineasDesempaquetadas. Si el
    // usuario tiene el toggle activo, hay que volver a desempaquetar
    // antes de pintar las columnas (con barra de progreso si >150 lineas).
    if FMostrarColumnasAtributos and
       (not dmmInventarios.LineasDesempaquetadas) then
      AsegurarDesempaquetadoAtributos;
    // FUltimoArticuloPadre puede coincidir con el de la cabecera anterior;
    // lo limpiamos para forzar la reconstruccion de captions/SQL.
    FUltimoArticuloPadre := '';
    ActualizarColumnasDinamicas(dmmInventarios.cdsLineas.FieldByName(
                                                 'CODIGO_ART_INVLIN').AsString);
  end;
  // En modo DisconnectedMode + Pooling el cxGrid no siempre resincroniza su
  // DataController solo con el Open de cdsLineas, y las lineas recien cargadas
  // (carga masiva, Excel, familia/proveedor) no se ven hasta salir y volver a
  // entrar. Forzamos el refresco del grid para que aparezcan al momento.
  if Assigned(tvLineas) then
    tvLineas.DataController.Refresh;
  // Contrato de entrada (ColumnSKUcxGrid): reconstruye sus columnas
  // sobre las lineas recien cargadas (modo elegido con F1).
  ConstruirModoEntrada;
end;

procedure TfrmMtoInventarios.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  i: Integer;
begin
  if (dmmInventarios = nil) or
     (not dmmInventarios.cdsLineas.Active) or
     (csDestroying in ComponentState) then
    Exit;
  // Diagnostico temporal de la prueba: con que estado del cds se
  // construye cada vez (persigue el "atributos vacios al entrar").
  inLibLog.Log.LogInfo(Format(
    '[ConstruirModoEntrada] modo=%d filas=%d desempaquetadas=%s ' +
    'estado=%d attr1_fila1="%s"',
    [Ord(FModoEntradaSel), dmmInventarios.cdsLineas.RecordCount,
     BoolToStr(dmmInventarios.LineasDesempaquetadas, True),
     Ord(dmmInventarios.cdsLineas.State),
     dmmInventarios.cdsLineas.FieldByName('ATTR1_VALOR').AsString]));
  // Conversion en marcha: BeforePost no debe exigir SKU cerrado a los
  // Posts intermedios del pivote/des-pivote (lineas consolidadas o
  // con unidad=padre). Al final del metodo queda True solo en tallas.
  dmmInventarios.ModoPivoteActivo := True;
  DesmontarModoEntradaDocumento(tvLineas,
    dmmInventarios.cdsLineas, FModoEntrada);
  // Desglose ensenya atributos: desempaquetar SKU->ATTR ahora Y en
  // cada recarga de lineas (DesempaquetarAlCargar: las recargas del
  // data module que no pasan por el form barrian los ATTR in-memory
  // y los atributos se veian en blanco hasta reconstruir).
  if FModoEntradaSel = mcsSku then
  begin
    FMostrarColumnasAtributos := False;
    dmmInventarios.DesempaquetarAlCargar := False;
  end
  else
  begin
    FMostrarColumnasAtributos := True;
    dmmInventarios.DesempaquetarAlCargar := True;
    AsegurarDesempaquetadoAtributos;
  end;
  Cfg := CrearConfigColumnasSkuDocumento(
    ConexionPrincipal, ContextoSesion, tvLineas,
    dmmInventarios.cdsLineas, FModoEntradaSel,
    dsTablaG.DataSet.FieldByName(
      'CODIGO_ALM_INV').AsString, 'INVLIN');
  Cfg.ValidadorArticulos :=
    CrearValidadorArticulos(Cfg.Conexion);
  Cfg.LookupAtributos :=
    CrearLookupAtributosArticulos(Cfg.Conexion);
  Cfg.Campos.Cantidad := 'CANTIDAD_FISICA_INVLIN';
  // El almacen es de CABECERA en inventario: sin columna de linea.
  Cfg.Campos.Almacen := '';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_REQ_INV_LINEA';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR';
    Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE';
  end;
  // NOTA: el modo tallas en horizontal quedo DESCARTADO en
  // inventarios: cada linea lleva DOS cantidades (teorica y recuento)
  // y una celda de pivote solo puede representar una. Se probo y se
  // retiro (queda la infraestructura de celdas por si se retoma).
  FModoEntrada := CrearModoEntradaGrid(Cfg);
  // Construir hace ClearItems: mueren las columnas del dfm (primera
  // vez) y nacen las del contrato; despues remontamos las numericas.
  // El flag va ANTES: si Construir aborta a medias (validaciones de
  // BeforePost, SQL...), las rutas legacy ya no deben tocar las
  // columnas del dfm, que han muerto en el ClearItems.
  FColsModoConstruido := True;
  ConstruirModoEntradaDocumento(FModoEntrada, ModoEntradaResuelto,
    DesactivarEnterAsTabTemporal, RestaurarEnterAsTabTemporal,
    FModoEntradaSel, [], '');
  CrearColumnasHostInventario;
  // En desglose, las columnas de atributo del contrato nacen ocultas
  // (cada articulo re-rotula las suyas al resolver): precargar los
  // nombres globales para que Color/Talla se vean desde el principio.
  if DetectarModoColumnasSku(Cfg) = mcsDesglose then
    MostrarColumnasAtributoGlobales;
  // El guardian de estado (PuedeEditar) se conserva: los modos no
  // enganchan OnEditing salvo tallas distribuido (aqui no aplica).
  tvLineas.OnEditing := tvLineasEditing;
  // Mantener el acelerador del caption original ('&1. Detalle...').
  if DetectarModoColumnasSku(Cfg) = mcsSku then
    tsDetalle.Caption := SCaptionTabDetalleInventarioSku
  else
    tsDetalle.Caption := SCaptionTabDetalleInventarioDesglose;
  // Conversion terminada: el guardian de BeforePost vuelve a aplicar.
  dmmInventarios.ModoPivoteActivo := False;
  // Diagnostico temporal: estado al terminar de construir.
  inLibLog.Log.LogInfo(Format(
    '[ConstruirModoEntrada] FIN filas=%d desempaquetadas=%s ' +
    'attr1_fila_activa="%s"',
    [dmmInventarios.cdsLineas.RecordCount,
     BoolToStr(dmmInventarios.LineasDesempaquetadas, True),
     dmmInventarios.cdsLineas.FieldByName('ATTR1_VALOR').AsString]));
  if PuedeEditar then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoInventarios.CrearColumnasHostInventario;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineas.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
    Result.HeaderAlignmentHorz := taRightJustify;
  end;
var
  ColRec: TcxGridDBColumn;
begin
  // Columnas propias del documento tras el ClearItems del contrato
  // (equivalente runtime de las del dfm; LOTE/CADUCIDAD/USUARIO, que
  // iban ocultas, quedan fuera de la prueba).
  with Col('Descripción', 'DESCRIPCION_ARTICULO_INVLIN', 200, False) do
    HeaderAlignmentHorz := taLeftJustify;
  Col('Uds. teóricas', 'CANTIDAD_TEORICA_INVLIN', 90, False);
  ColRec := Col('Recuento', 'CANTIDAD_FISICA_INVLIN', 90, True);
  ColRec.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(ColRec.Properties).OnValidate :=
    tvLineasUdsFisicasPropertiesValidate;
  Col('PMP actual', 'PRECIO_MEDIO_INVLIN', 85, False);
  Col('PMP nuevo', 'PRECIO_MEDIO_NUEVO_INVLIN', 85, True);
  Col('Dif. uds.', 'CANTIDAD_DIFERENCIA_INVLIN', 80, False);
  Col('Dif. coste', 'TOTAL_COSTE_DIFERENCIA_INVLIN', 90, False);
  Col('Uds. regul.', 'UDS_REGULARIZADAS', 80, False);
  Col('Hora recuento', 'FECHA_RECUENTO_INVLIN', 120, False);
end;

procedure TfrmMtoInventarios.MostrarColumnasAtributoGlobales;
var
  i, j, iAncho: Integer;
  Col: TcxGridColumn;
  cds: TDataSet;
  Bm: TBookmark;
  AnchoMax: array[1..5] of Integer;
begin
  MostrarColumnasAtributoGlobalesDocumento(
    ConexionPrincipal, tvLineas);
  // Ancho segun el VALOR mas largo cargado + margen del swatch (44 =
  // cuadrado 18 + separacion 6 + margenes 10 + aire 10): AZUL_CIELO
  // quedaba ilegible con el ancho por defecto. Solo crece, como en el
  // modo tallas, para no pisar anchos tocados a mano.
  cds := dmmInventarios.cdsLineas;
  if cds.Active and (not cds.IsEmpty) then
  begin
    for i := 1 to 5 do
      AnchoMax[i] := 0;
    Bm := cds.GetBookmark;
    cds.DisableControls;
    try
      cds.First;
      while not cds.Eof do
      begin
        for i := 1 to 5 do
        begin
          iAncho := cxTextWidth(cxgrdLineas.Font,
            Trim(cds.FieldByName(
              'ATTR' + IntToStr(i) + '_VALOR').AsString));
          if iAncho > AnchoMax[i] then
            AnchoMax[i] := iAncho;
        end;
        cds.Next;
      end;
      if cds.BookmarkValid(Bm) then
        cds.GotoBookmark(Bm);
    finally
      cds.EnableControls;
      cds.FreeBookmark(Bm);
    end;
    for j := 0 to tvLineas.ColumnCount - 1 do
    begin
      Col := tvLineas.Columns[j];
      if (Col.Tag >= 1) and (Col.Tag <= 5) and Col.Visible and
         (Col.Width < AnchoMax[Col.Tag] + 44) then
        Col.Width := AnchoMax[Col.Tag] + 44;
    end;
  end;
end;

procedure TfrmMtoInventarios.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
var
  CantTeo, PMPAct: Currency;
begin
  // Rama CodSku<>'' del flujo clasico (RellenarLineaDesdeBusqueda):
  // teorico y PMP de la unidad resuelta.
  if ACompleto and (ASku <> '') then
  begin
    if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
      dmmInventarios.cdsLineas.Edit;
    dmmInventarios.RellenarDatosSku(ASku, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := PMPAct;
    dmmInventarios.AsegurarFechaRecuentoLinea;
  end;
end;

procedure TfrmMtoInventarios.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, pcDetail.ActivePage = tsDetalle,
    FModoEntradaSel, [mcsAuto, mcsSku], ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoInventarios.
  cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged(Sender: TObject);
var
  emp: string;
begin
  // Guards: este evento puede dispararse durante el cierre de la ventana
  // (cuando el manager hace AForm.Hide y AForm.Parent := nil), antes y después
  // de FormDestroy. Si el ciclo de vida ha desmontado el dataset principal
  // o el data module, no podemos tocar el data module.
  if not (csDestroying in ComponentState) and
     (dmmInventarios <> nil) and
     (dsTablaG <> nil) and
     (dsTablaG.DataSet <> nil) and
     (not FRefrescandoLookupsCabecera) then
  begin
    emp := VarToStr(cbbCODIGO_EMPRESA_INVENTARIO.EditValue);
    RefrescarLookupsCabeceraEmpresa(emp);
    // Si el usuario cambia manualmente de empresa, el almacén elegido
    // anteriormente ya no es fiable. Los refrescos internos no deben borrarlo.
    if cbbCODIGO_EMPRESA_INVENTARIO.Focused and
       (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
      dsTablaG.DataSet.FieldByName('CODIGO_ALM_INV').Clear;
  end;
end;

// ============================================================================
//   GESTIÓN DE COLUMNAS DINÁMICAS DE SKU (mismo patrón que inMtoCajaOpe)
// ============================================================================

function TfrmMtoInventarios.ObtenerColumnaSkuPorTag(
  NumColumn: Integer): TcxGridDBColumn;
begin
  case NumColumn of
    1: Result := tvLineasSKU1;
    2: Result := tvLineasSKU2;
    3: Result := tvLineasSKU3;
    4: Result := tvLineasSKU4;
    5: Result := tvLineasSKU5;
  else
    Result := nil;
  end;
end;

function TfrmMtoInventarios.ColumnaEntradaActiva: TcxGridDBColumn;
begin
  if FMostrarColumnasAtributos then
    Result := tvLineasARTICULO
  else
    Result := tvLineasUNIDAD;
end;

procedure TfrmMtoInventarios.AplicarModoColumnasEntrada(AModoAtributos: Boolean);
begin
  // Contrato activo: la entrada es del contrato; columnas dfm muertas.
  if FColsModoConstruido then
    Exit;
  if Assigned(tvLineasARTICULO) and Assigned(tvLineasUNIDAD) then
  begin
    tvLineas.BeginUpdate;
    try
      if AModoAtributos then
      begin
        // Atributos en columna: la entrada es la columna Articulo (codigo) y
        // la unificada SKU/Articulo se oculta. Color/Talla/... van en
        // tvLineasSKU1..5 y la Descripcion queda detras (orden de la DFM).
        tvLineasARTICULO.Visible         := True;
        tvLineasARTICULO.Options.Editing := True;
        tvLineasUNIDAD.Visible           := False;
      end
      else
      begin
        // Modo normal: una unica columna de entrada, la unificada SKU/Articulo.
        tvLineasUNIDAD.Visible   := True;
        tvLineasARTICULO.Visible := False;
      end;
    finally
      tvLineas.EndUpdate;
    end;
  end;
end;

function TfrmMtoInventarios.ObtenerNumAtributosArticulo(
  const ACodigoArticulo: string): Integer;
begin
  Result := 0;
  if (dmmInventarios = nil) or (Trim(ACodigoArticulo) = '') then
    Exit;
  dmmInventarios.unqryDefinicionArticulo.Close;
  dmmInventarios.unqryDefinicionArticulo.ParamByName('ARTICULO').AsString :=
    ACodigoArticulo;
  dmmInventarios.unqryDefinicionArticulo.Open;
  while not dmmInventarios.unqryDefinicionArticulo.Eof do
  begin
    Inc(Result);
    dmmInventarios.unqryDefinicionArticulo.Next;
  end;
end;

procedure TfrmMtoInventarios.AplicarColumnasAtributosVista;
var
  cds        : TDataSet;
  Bm         : TBookmark;
  MaxAtr, n, i: Integer;
  ArtRepr    : string;
  Nombres    : TStringList;
  Col        : TcxGridDBColumn;
begin
  // Contrato activo: sus columnas de atributo, no las del dfm.
  if FColsModoConstruido then
    Exit;
  if dmmInventarios = nil then Exit;
  cds := dmmInventarios.cdsLineas;
  if not cds.Active then Exit;
  // 1. Recorremos las lineas: numero maximo de atributos del inventario y el
  //    articulo que lo alcanza (de el sacamos los nombres en su orden).
  MaxAtr  := 0;
  ArtRepr := '';
  if not cds.IsEmpty then
  begin
    Bm := cds.GetBookmark;
    cds.DisableControls;
    try
      cds.First;
      while not cds.Eof do
      begin
        n := cds.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
        if n > MaxAtr then
        begin
          MaxAtr  := n;
          ArtRepr := cds.FieldByName('CODIGO_ART_INVLIN').AsString;
        end;
        cds.Next;
      end;
    finally
      if cds.BookmarkValid(Bm) then
        cds.GotoBookmark(Bm);
      cds.FreeBookmark(Bm);
      cds.EnableControls;
    end;
  end;
  if MaxAtr > 5 then
    MaxAtr := 5;
  FNumAtributosActual := MaxAtr;
  // 2. Nombres de los atributos (Talla, Color...) en su ORDEN_VISUAL, tomados
  //    del articulo representativo.
  Nombres := TStringList.Create;
  try
    if (MaxAtr > 0) and (ArtRepr <> '') then
    begin
      dmmInventarios.unqryDefinicionArticulo.Close;
      dmmInventarios.unqryDefinicionArticulo.ParamByName('ARTICULO').AsString :=
        ArtRepr;
      dmmInventarios.unqryDefinicionArticulo.Open;
      while not dmmInventarios.unqryDefinicionArticulo.Eof do
      begin
        Nombres.Add(dmmInventarios.unqryDefinicionArticulo.FieldByName(
          'NOMBRE_ATRIBUTO').AsString);
        dmmInventarios.unqryDefinicionArticulo.Next;
      end;
    end;
    // 3. SKU1..MaxAtr visibles con su nombre; el resto, ocultas.
    tvLineas.BeginUpdate;
    try
      for i := 1 to 5 do
      begin
        Col := ObtenerColumnaSkuPorTag(i);
        if Col <> nil then
        begin
          if i <= MaxAtr then
          begin
            if i <= Nombres.Count then
              Col.Caption := Nombres[i - 1]
            else
              Col.Caption := Format(SCaptionAtributoN, [i]);
            Col.Visible := True;
            Col.Options.Editing := True;
          end
          else
          begin
            Col.Visible := False;
            Col.Options.Editing := False;
            Col.Caption := '-';
          end;
        end;
      end;
    finally
      tvLineas.EndUpdate;
    end;
  finally
    FreeAndNil(Nombres);
  end;
end;

procedure TfrmMtoInventarios.actIraArticuloExecute(Sender: TObject);
begin
  inherited;
  if pcDetail.ActivePage = tsDetalle then
    ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
      tvLineas.DataController.DataSet,
      'CODIGO_ART_INVLIN')
  else
    ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
      tvMovs.DataController.DataSet,
      'CODIGO_ART_MOV');
end;

procedure TfrmMtoInventarios.ActualizarColumnasDinamicas(
  const ArticuloPadre: string);
var
  swTotal: TStopwatch;

  procedure OcultarTodasLasColumnasSku;
  var
    j: Integer;
    C: TcxGridDBColumn;
  begin
    if Assigned(tvLineas) then
    begin
      tvLineas.BeginUpdate;
      try
        for j := 1 to 5 do
        begin
          C := ObtenerColumnaSkuPorTag(j);
          if C <> nil then
          begin
            C.Visible := False;
            C.Options.Editing := False;
            C.Caption := '-';
          end;
        end;
        // En modo normal la entrada es la columna unificada SKU/Articulo.
        AplicarModoColumnasEntrada(False);
      finally
        tvLineas.EndUpdate;
      end;
    end;
  end;

  procedure AplicarColumnasArticulo(const ACodigoArticulo: string);
  var
    i: Integer;
    Col: TcxGridDBColumn;
    NombresAtributos: TStringList;
  begin
    NombresAtributos := TStringList.Create;
    try
      if Trim(ACodigoArticulo) <> '' then
      begin
        dmmInventarios.unqryDefinicionArticulo.Close;
        dmmInventarios.unqryDefinicionArticulo.ParamByName(
          'ARTICULO').AsString := ACodigoArticulo;
        dmmInventarios.unqryDefinicionArticulo.Open;
        while not dmmInventarios.unqryDefinicionArticulo.Eof do
        begin
          NombresAtributos.Add(
            dmmInventarios.unqryDefinicionArticulo.FieldByName(
              'NOMBRE_ATRIBUTO').AsString);
          dmmInventarios.unqryDefinicionArticulo.Next;
        end;
      end;
      FNumAtributosActual := NombresAtributos.Count;
      if dmmInventarios.cdsLineas.Active and
         (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
        dmmInventarios.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger :=
          FNumAtributosActual;
      tvLineas.BeginUpdate;
      try
        for i := 1 to 5 do
        begin
          Col := ObtenerColumnaSkuPorTag(i);
          if Col <> nil then
          begin
            if i <= NombresAtributos.Count then
            begin
              Col.Caption := NombresAtributos[i - 1];
              Col.Visible := True;
              Col.Options.Editing := True;
            end
            else
            begin
              Col.Visible := False;
              Col.Options.Editing := False;
              Col.Caption := '-';
            end;
          end;
        end;
        AplicarModoColumnasEntrada(True);
      finally
        tvLineas.EndUpdate;
      end;
    finally
      FreeAndNil(NombresAtributos);
    end;
  end;

begin
  // Contrato de entrada activo: las columnas de atributo son SUYAS
  // (las del dfm ya no existen tras el ClearItems del Construir).
  if FColsModoConstruido then
    Exit;
  swTotal := TStopwatch.StartNew;
  // En modo SKU, el check apagado manda siempre. Esto corrige disposiciones
  // guardadas del grid que puedan reactivar Color/Talla al abrir la ficha.
  if not FMostrarColumnasAtributos then
  begin
    FNumAtributosActual := 0;
    FUltimoArticuloPadre := ArticuloPadre;
    OcultarTodasLasColumnasSku;
    Exit;
  end;
  if dmmInventarios = nil then
  begin
    OcultarTodasLasColumnasSku;
    Exit;
  end;
  if dmmInventarios.cdsLineas.Active and
     (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
  begin
    FUltimoArticuloPadre := ArticuloPadre;
    AplicarColumnasArticulo(ArticuloPadre);
    Exit;
  end;
  // Optimización: si es el mismo padre, no repintamos
  if SameText(ArticuloPadre, FUltimoArticuloPadre) then
  begin
    inLibLog.Log.LogPerf('ActualizarColumnasDinamicas(memoizado)',
      Format('articulo=%s', [ArticuloPadre]),
      swTotal.ElapsedMilliseconds);
    Exit;
  end;
  FUltimoArticuloPadre := ArticuloPadre;

  if FMostrarColumnasAtributos then
  begin
    if not FAtributosVistaAplicados then
    begin
      AplicarColumnasAtributosVista;
      FAtributosVistaAplicados := True;
    end;
    AplicarModoColumnasEntrada(True);
    Exit;
  end;

end;

procedure TfrmMtoInventarios.AsegurarDesempaquetadoAtributos;
var
  HayMuchasLineas: Boolean;
begin
  if dmmInventarios = nil then Exit;
  if not dmmInventarios.cdsLineas.Active then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;
  // No tocar el cds si esta en edicion: el bucle Edit/Post sobre cada
  // linea corromperia el estado y haria saltar
  // "EcxInvalidDataControllerOperation: RecordIndex out of range"
  // en el tvLineas al siguiente Append/refocus.
  if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then Exit;
  // El propio data module corto-circuita si ya esta hecho, pero filtramos
  // tambien aqui para no entrar en el overlay si no toca.
  if dmmInventarios.LineasDesempaquetadas then Exit;

  HayMuchasLineas :=
    dmmInventarios.cdsLineas.RecordCount > FUmbralProgresoDesempaquetado;

  if HayMuchasLineas then
    BloquearTabPorOcupado(True);
  try
    dmmInventarios.DesempaquetarAtributosDesdeSku;
  finally
    if HayMuchasLineas then
      BloquearTabPorOcupado(False);
  end;
end;

procedure TfrmMtoInventarios.chkVerColumnasAtributosPropertiesChange(
  Sender: TObject);
var
  CodArt: string;
begin
  // Sincroniza el flag interno con el estado de la checkbox y refresca
  // las columnas. Si se acaba de activar, antes desempaqueta SKU->ATTR
  // (con barra de progreso si hay mas de FUmbralProgresoDesempaquetado
  // lineas). Si se desactiva, ocultamos sin tocar la BBDD.
  if csLoading in ComponentState then Exit;
  // Contrato activo: el modo lo gobierna F1; el check queda oculto y
  // sin efecto (se conserva por si se desactiva la prueba).
  if FColsModoConstruido then Exit;
  FMostrarColumnasAtributos := chkVerColumnasAtributos.Checked;
  // Conmuta ya la columna de entrada (Articulo <-> SKU/Articulo) aunque el
  // inventario este vacio: ActualizarColumnasDinamicas puede cortocircuitar
  // por memoizacion cuando no hay articulo padre.
  AplicarModoColumnasEntrada(FMostrarColumnasAtributos);

  if FMostrarColumnasAtributos then
    AsegurarDesempaquetadoAtributos;

  // Forzar el rebuild ignorando la memoizacion FUltimoArticuloPadre. Al
  // cambiar el toggle recalculamos tambien las columnas de atributo de vista.
  FUltimoArticuloPadre := '';
  FAtributosVistaAplicados := False;

  CodArt := '';
  if (dmmInventarios <> nil) and
     dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
    CodArt :=
      dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;
  ActualizarColumnasDinamicas(CodArt);
end;

procedure TfrmMtoInventarios.RellenarAtributosDesdeSku(const Sku: string);
var
  Lookup  : IArticulosAtributosLookup;
  Valores : TArray<TArticuloAtributoValor>;
  V       : TArticuloAtributoValor;
  i       : Integer;
  swTotal, swCreate, swObtener, swSet: TStopwatch;
  msCreate, msObtener, msSet: Int64;
begin
  // Carga los valores de cada atributo del SKU en las columnas ATTR1..ATTR5,
  // mapeadas por ORDEN_VISUAL_ATRIBUTO (= ORDEN_VA del atributo).
  if Sku = '' then Exit;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  swTotal := TStopwatch.StartNew;

  swCreate := TStopwatch.StartNew;
  Lookup := CrearLookupAtributosArticulos(ConexionPrincipal);
  msCreate := swCreate.ElapsedMilliseconds;
  try
    swObtener := TStopwatch.StartNew;
    Valores := Lookup.ObtenerAtributosDeSku(Sku);
    msObtener := swObtener.ElapsedMilliseconds;

    swSet := TStopwatch.StartNew;
    for V in Valores do
    begin
      i := V.Orden;
      if (i >= 1) and (i <= 5) then
        dmmInventarios.cdsLineas.FieldByName('ATTR' + IntToStr(
          i) + '_VALOR').AsString
                                                                       := V.Valor;
    end;
    msSet := swSet.ElapsedMilliseconds;
  finally
    Lookup := nil;
  end;

  inLibLog.Log.LogPerf('RellenarAtributosDesdeSku',
    Format('sku=%s nVals=%d | Create=%d ObtenerAtributosDeSku=%d SetFields=%d',
           [Sku, Length(Valores), msCreate, msObtener, msSet]),
    swTotal.ElapsedMilliseconds);
end;


// ============================================================================
//   EVENTOS DE EDICIÓN DEL GRID DE LÍNEAS
// ============================================================================

procedure TfrmMtoInventarios.tvLineasEditing(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
begin
  if not PuedeEditar then
  begin
    AAllow := False;
    ShowMessage(SErrorInventarioNoAbiertoEditar);
  end;
end;

procedure TfrmMtoInventarios.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  if PintarCeldaSwatchSiAplica(ConexionPrincipal, ACanvas, AViewInfo, nil) then
    ADone := True;
end;

procedure TfrmMtoInventarios.tvLineasInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
var
  BE        : TcxButtonEdit;
  AvActual  : string;
  NombreAtb : string;
  IdVa      : string;
  Mapa      : TDictionary<string, string>;
  Info      : TInfoBasico;
  Btn       : TcxEditButton;
begin
  // Columnas SKU1..SKU5 — TcxButtonEdit. Configuramos:
  //   (1) Glyph del boton = cuadradito del color del AV actual (si esta en
  //       la paleta basica). Si no, el boton vuelve a su look [...].
  //   (2) Si la celda esta VACIA, auto-abrimos el selector al entrar
  //       (sustituye a ForzarDespliegue del antiguo combo). Si ya tiene
  //       valor, el usuario ve el cuadradito y clica si quiere cambiar.
  if (AItem.Tag < 1) or (AItem.Tag > 5) then Exit;
  if not (AEdit is TcxButtonEdit) then Exit;
  BE := TcxButtonEdit(AEdit);
  if BE.Properties.Buttons.Count = 0 then Exit;
  Btn := BE.Properties.Buttons[0];

  AvActual  := '';
  NombreAtb := '';
  if dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) then
  begin
    AvActual  := dmmInventarios.cdsLineas.FieldByName(
                   'ATTR' + IntToStr(AItem.Tag) + '_VALOR').AsString;
    NombreAtb := dmmInventarios.cdsLineas.FieldByName(
                   'ATTR' + IntToStr(AItem.Tag) + '_NOMBRE').AsString;
  end;

  IdVa := '';
  Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
  if Mapa <> nil then
    Mapa.TryGetValue(UpperCase(Trim(NombreAtb)), IdVa);

  Info := Default(TInfoBasico);
  if (IdVa <> '') and (Trim(AvActual) <> '') then
    ObtenerInfoBasico(ConexionPrincipal, IdVa, AvActual, Info);

  if Info.EsValido and
     PintarSwatchEnBitmap(FBmpSwatchBoton, Info, 14) then
  begin
    Btn.Glyph.Assign(FBmpSwatchBoton);
    Btn.Kind := bkGlyph;
  end
  else
    Btn.Kind := bkEllipsis;

  if Trim(AvActual) = '' then
    BE.OnEnter := AbrirPopupSkuEnEntrada
  else
    BE.OnEnter := nil;
end;

procedure TfrmMtoInventarios.tvLineasEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  Combo: TcxComboBox;
begin
  // Pulsar Enter en una columna de atributo (Color, Talla, ...) sin valor
  // seleccionado debe coger la primera opcion de la lista, igual que en
  // inMtoCajaOpe. Sin esto, el usuario que da Enter encadenado por las
  // celdas se queda con los atributos vacios y la linea no se puede grabar.
  if Key <> VK_RETURN then Exit;
  if (AItem.Tag < 1) or (AItem.Tag > 5) then Exit;
  if not (AEdit is TcxComboBox) then Exit;
  Combo := TcxComboBox(AEdit);
  if (Combo.ItemIndex = -1) and (Trim(Combo.Text) = '') and
     (Combo.Properties.Items.Count > 0) then
    Combo.ItemIndex := 0;
  if Combo.DroppedDown then
    Combo.DroppedDown := False;
  Combo.PostEditValue;
end;

procedure TfrmMtoInventarios.ForzarDespliegue(Sender: TObject);
var
  Combo: TcxComboBox;
begin
  if not (Sender is TcxComboBox) then Exit;
  Combo := TcxComboBox(Sender);
  // Reasignamos ItemIndex con el guard FInicializandoCombo para que
  // OnAtributoChanged no recalcule un SKU intermedio antes de que el usuario
  // confirme.
  FInicializandoCombo := True;
  try
    if Combo.Properties.Items.Count > 0 then
      Combo.ItemIndex := 0;
  finally
    FInicializandoCombo := False;
  end;
  if not Combo.DroppedDown then
    Combo.DroppedDown := True;
  Combo.OnEnter := nil;
end;

procedure TfrmMtoInventarios.OnAtributoChanged(Sender: TObject);
var
  Edit: TcxCustomEdit;
  SkuNuevo: string;
  CantTeo, PMPAct: Currency;
  NumAtributosRequeridos, NumSeparadores, i: Integer;
begin
  // Cada vez que se selecciona un valor en una columna de atributo (Color,
  // Talla, ...) reconstruimos el SKU (CODIGO_ART/ATTR1/ATTR2/...). Si tras
  // la edicion el SKU es ya completo (tantos '/' como atributos requeridos)
  // disparamos el recalculo teorico/PMP de la linea automaticamente.
  if FInicializandoCombo or FProcesandoAtributo then Exit;
  if not (Sender is TcxCustomEdit) then Exit;
  Edit := TcxCustomEdit(Sender);
  if not dmmInventarios.cdsLineas.Active then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;
  // El TcxComboBox de cxGrid puede disparar OnEditValueChanged mientras el
  // dataset sigue en dsBrowse (al cambiar de valor en una línea ya guardada).
  // Forzamos la transición a dsEdit para que PostEditValue/escritura de campos
  // y el rebuild del SKU se realicen sobre un registro editable.
  if dmmInventarios.cdsLineas.State = dsBrowse then
    dmmInventarios.cdsLineas.Edit;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  Edit.PostEditValue;

  // Defensa: aseguramos que el campo ATTRn_VALOR tiene el valor del editor.
  // Aunque la DataLink deberia hacerlo, en algunos casos no se sincroniza
  // antes de que GenerarSkuFinal lea, dejando el SKU sin atributos.
  if (Edit is TcxComboBox) then
  begin
    var ColIdx := TcxComboBox(Edit).Tag;
    if (ColIdx >= 1) and (ColIdx <= 5) then
      dmmInventarios.cdsLineas.FieldByName(
        'ATTR' + IntToStr(ColIdx) + '_VALOR').AsString :=
                                          VarToStr(TcxComboBox(Edit).EditValue);
  end;

  SkuNuevo := dmmInventarios.GenerarSkuFinal(
                dmmInventarios.cdsLineas.FieldByName(
                  'CODIGO_ART_INVLIN').AsString);
  // Si por algun motivo el SKU sale vacio (no deberia), nos quedamos con
  // el codigo del articulo. CODIGO_UNIDAD_INVLIN es NOT NULL en BD y dejarlo
  // vacio dispararia "Field value required" al hacer Post.
  if Trim(SkuNuevo) = '' then
    SkuNuevo :=
      dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;
  dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
    SkuNuevo;

  NumAtributosRequeridos :=
        dmmInventarios.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  NumSeparadores := 0;
  for i := 1 to Length(SkuNuevo) do
    if SkuNuevo[i] = '/' then
      Inc(NumSeparadores);

  if (NumAtributosRequeridos > 0)
     and (NumSeparadores = NumAtributosRequeridos) then
  begin
    dmmInventarios.RellenarDatosSku(SkuNuevo, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.AsegurarFechaRecuentoLinea;
  end;
end;

procedure TfrmMtoInventarios.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  ArtPadre: string;
begin
  if (AFocusedRecord = nil) or (dmmInventarios = nil) or
     (not dmmInventarios.cdsLineas.Active) or
     dmmInventarios.cdsLineas.IsEmpty then
    Exit;

  ArtPadre :=
    dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;

  // PREVENCION DEL ERROR FATAL DEL CXGRID:
  // DevExpress lanza "RecordIndex out of range" si modificamos la
  // visibilidad de las columnas (BeginUpdate/EndUpdate sobre el view) o
  // iteramos el dataset (First/Next) durante el OnFocusedRecordChanged,
  // porque el grid esta calculando indices internos en ese instante.
  // Posponemos las dos operaciones a la cola del main thread con
  // TThread.ForceQueue para que se ejecuten justo cuando el grid ya ha
  // terminado de cambiar de fila.
  TThread.ForceQueue(nil,
    procedure
    begin
      // Salvaguarda por si el form se cierra antes de que el queue corra.
      if (Self = nil) or (csDestroying in ComponentState) then Exit;
      if (dmmInventarios = nil) or (not dmmInventarios.cdsLineas.Active) then
        Exit;

      if FMostrarColumnasAtributos and
         (not dmmInventarios.LineasDesempaquetadas) then
        AsegurarDesempaquetadoAtributos;

      ActualizarColumnasDinamicas(ArtPadre);
    end);
end;


procedure TfrmMtoInventarios.tvLineasArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodArticulo, Descripcion, TipoArt: string;
  NumAtr: Integer;
begin
  Error := False;
  CodArticulo := Trim(VarToStr(DisplayValue));
  if CodArticulo = '' then Exit;

  dmmInventarios.RellenarDatosArticulo(CodArticulo,
                                       Descripcion,
                                       NumAtr,
                                       TipoArt);

  if Descripcion = '' then
  begin
    Error := True;
    ErrorText := SErrorArticuloInventarioNoExiste;
    Exit;
  end;

  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  dmmInventarios.cdsLineas.FieldByName(
    'DESCRIPCION_ARTICULO_INVLIN').AsString := Descripcion;
  dmmInventarios.cdsLineas.FieldByName(
    'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := NumAtr;

  // Refrescar columnas SKU dinámicas
  ActualizarColumnasDinamicas(CodArticulo);

  // Si no hay atributos (artículo sin SKUs), el SKU = código artículo
  if NumAtr = 0 then
  begin
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodArticulo;
    // Y rellenamos teóricas y PMP directamente
    var CantTeo, PMPAct: Currency;
    dmmInventarios.RellenarDatosSku(CodArticulo, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency := CantTeo;
    // por defecto
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency       := PMPAct;
    // por defecto
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := PMPAct;
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Input, Resolved: string;
begin
  Error := False;
  Input := Trim(VarToStr(DisplayValue));
  if Input = '' then Exit;
  Resolved := Input;
  RellenarLineaDesdeBusqueda(Input, Resolved, Error, ErrorText);
  if not Error then
  begin
    // En la columna Articulo mostramos el codigo del articulo; en la unificada,
    // el SKU resuelto. RellenarLineaDesdeBusqueda ya fijo CODIGO_ART_INVLIN.
    if (tvLineas.Controller.FocusedColumn = tvLineasARTICULO) and
       Assigned(dmmInventarios) then
      DisplayValue := dmmInventarios.cdsLineas.FieldByName(
                        'CODIGO_ART_INVLIN').AsString
    else
      DisplayValue := Resolved;
  end;
end;

procedure TfrmMtoInventarios.CargarAvsValidos(const ACodArt: string;
  AOrden: Integer; var AAvs: TArray<string>);
var
  Lookup : IArticulosAtributosLookup;
  Vals   : TArray<TArticuloAtributoValor>;
  i      : Integer;
begin
  // La consulta vive ahora en inLibArticulosAtributosIntf, que ordena
  // por ORDEN_AV (S=10, M=20, L=30, ...). Antes ordenaba alfabetico, lo
  // que mostraba L,M,S,XL,XXXL en el dropdown.
  SetLength(AAvs, 0);
  if Trim(ACodArt) = '' then Exit;
  if (AOrden < 1) or (AOrden > 5) then Exit;
  Lookup := CrearLookupAtributosArticulos(ConexionPrincipal);
  try
    Vals := Lookup.ObtenerAvsEnSkus(ACodArt, AOrden);
  finally
    Lookup := nil;
  end;
  SetLength(AAvs, Length(Vals));
  for i := 0 to High(Vals) do
    AAvs[i] := Vals[i].Valor;
end;

procedure TfrmMtoInventarios.RegistrarValorAtributo(AOrden: Integer;
  const AvNuevo: string);
var
  SkuNuevo: string;
  CantTeo, PMPAct: Currency;
  NumAtributosRequeridos, NumSeparadores, i: Integer;
begin
  if (AOrden < 1) or (AOrden > 5) then Exit;
  if not dmmInventarios.cdsLineas.Active then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;

  if dmmInventarios.cdsLineas.State = dsBrowse then
    dmmInventarios.cdsLineas.Edit;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  dmmInventarios.cdsLineas.FieldByName(
    'ATTR' + IntToStr(AOrden) + '_VALOR').AsString := AvNuevo;

  SkuNuevo := dmmInventarios.GenerarSkuFinal(
                dmmInventarios.cdsLineas.FieldByName(
                  'CODIGO_ART_INVLIN').AsString);
  if Trim(SkuNuevo) = '' then
    SkuNuevo := dmmInventarios.cdsLineas.FieldByName(
                  'CODIGO_ART_INVLIN').AsString;
  dmmInventarios.cdsLineas.FieldByName(
    'CODIGO_UNIDAD_INVLIN').AsString := SkuNuevo;

  NumAtributosRequeridos :=
        dmmInventarios.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  NumSeparadores := 0;
  for i := 1 to Length(SkuNuevo) do
    if SkuNuevo[i] = '/' then
      Inc(NumSeparadores);

  if (NumAtributosRequeridos > 0)
     and (NumSeparadores = NumAtributosRequeridos) then
  begin
    dmmInventarios.RellenarDatosSku(SkuNuevo, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.AsegurarFechaRecuentoLinea;
  end;
end;

procedure TfrmMtoInventarios.tvLineasSkuPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Col: TcxGridColumn;
  Orden: Integer;
  ArtPadre, NombreAtb, IdVa, AvActual, AvNuevo: string;
  Avs: TArray<string>;
  Mapa: TDictionary<string, string>;
  EditCtrl: TWinControl;
  ScrPt: TPoint;
  WidHint: Integer;
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioNoAbiertoEditar);
    Exit;
  end;
  Col := tvLineas.Controller.FocusedColumn;
  if Col = nil then Exit;
  Orden := Col.Tag;
  if (Orden < 1) or (Orden > 5) then Exit;
  if not dmmInventarios.cdsLineas.Active then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;

  ArtPadre := dmmInventarios.cdsLineas.FieldByName(
                'CODIGO_ART_INVLIN').AsString;
  AvActual := dmmInventarios.cdsLineas.FieldByName(
                'ATTR' + IntToStr(Orden) + '_VALOR').AsString;
  NombreAtb := dmmInventarios.cdsLineas.FieldByName(
                'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString;

  CargarAvsValidos(ArtPadre, Orden, Avs);
  if Length(Avs) = 0 then
  begin
    ShowMessage(SErrorValoresAtributoNoDefinidos);
    Exit;
  end;

  IdVa := '';
  Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
  if Mapa <> nil then
    Mapa.TryGetValue(UpperCase(Trim(NombreAtb)), IdVa);

  // Posicion donde sale el "desplegable": justo debajo del editor.
  ScrPt.X := -1; ScrPt.Y := -1;
  WidHint := 120;
  if Sender is TWinControl then
  begin
    EditCtrl := TWinControl(Sender);
    ScrPt    := EditCtrl.ClientToScreen(Point(0, EditCtrl.Height));
    WidHint  := EditCtrl.Width;
  end;

  if not SeleccionarAvConPaleta(ConexionPrincipal, IdVa, Avs, AvActual, AvNuevo,
                                ScrPt.X, ScrPt.Y, WidHint) then
    Exit;

  RegistrarValorAtributo(Orden, AvNuevo);

  // Reflejamos el valor en el editor actual para que la celda muestre el AV
  // elegido al instante (sin esperar al refresh de la DataLink).
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).EditValue := AvNuevo;
end;

procedure TfrmMtoInventarios.AbrirPopupSkuEnEntrada(Sender: TObject);
var
  BE: TcxCustomEdit;
begin
  // OnEnter single-shot: dispara el click del boton para abrir el selector
  // automaticamente al entrar en la celda (sustituye a ForzarDespliegue).
  if not (Sender is TcxCustomEdit) then Exit;
  BE := TcxCustomEdit(Sender);
  BE.OnEnter := nil;
  // Convocamos directamente el handler. AButtonIndex = 0 (unico boton).
  tvLineasSkuPropertiesButtonClick(BE, 0);
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesButtonClick(
  Sender: TObject;
  AButtonIndex: Integer);
var
  Edit: TcxCustomEdit;
  Codigo, Resolved: string;
  ErrText: TCaption;
  Err: Boolean;
  swTotal, swDialog, swRellenar, swReflect, swFocus: TStopwatch;
  msDialog, msRellenar, msReflect, msFocus: Int64;
begin
  swTotal := TStopwatch.StartNew;

  swDialog := TStopwatch.StartNew;
  if FMostrarColumnasAtributos then
    Codigo := BuscarArticuloDialog
  else
    Codigo := BuscarSkuDialog;
  msDialog := swDialog.ElapsedMilliseconds;
  if Codigo = '' then
  begin
    inLibLog.Log.LogPerf('UnidadButtonClick(cancelado)',
      Format('BuscarArticuloDialog=%d', [msDialog]),
      swTotal.ElapsedMilliseconds);
    Exit;
  end;
  Resolved := Codigo;
  Err := False;
  ErrText := '';

  swRellenar := TStopwatch.StartNew;
  RellenarLineaDesdeBusqueda(Codigo, Resolved, Err, ErrText);
  msRellenar := swRellenar.ElapsedMilliseconds;

  if Err then
  begin
    ShowMessage(ErrText);
    Exit;
  end;
  // Reflejamos el SKU resuelto en el editor en pantalla
  swReflect := TStopwatch.StartNew;
  if Sender is TcxCustomEdit then
  begin
    Edit := TcxCustomEdit(Sender);
    // Igual que en el Validate: la celda Articulo muestra el codigo de
    // articulo; la unificada, el SKU resuelto.
    if (tvLineas.Controller.FocusedColumn = tvLineasARTICULO) and
       Assigned(dmmInventarios) then
      Edit.EditValue := dmmInventarios.cdsLineas.FieldByName(
                          'CODIGO_ART_INVLIN').AsString
    else
      Edit.EditValue := Resolved;
  end;
  msReflect := swReflect.ElapsedMilliseconds;
  // Si el articulo tiene variaciones (NUM_ATRIBUTOS > 0), movemos el foco
  // al primer atributo dinamico para que el usuario pueda elegir
  // Color/Talla/... directamente.
  swFocus := TStopwatch.StartNew;
  if (dmmInventarios.cdsLineas.FieldByName(
       'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger > 0) and
     Assigned(tvLineasSKU1) and tvLineasSKU1.Visible then
  begin
    tvLineas.Controller.FocusedColumn := tvLineasSKU1;
    if tvLineas.Controller.EditingController <> nil then
      tvLineas.Controller.EditingController.ShowEdit;
  end;
  msFocus := swFocus.ElapsedMilliseconds;

  inLibLog.Log.LogPerf('UnidadButtonClick(total)',
    Format('codigo=%s resolved=%s | BuscarDialog=%d RellenarLinea=%d ' +
           'EditValue=%d FocusSKU1=%d',
           [Codigo, Resolved, msDialog, msRellenar, msReflect, msFocus]),
    swTotal.ElapsedMilliseconds);
end;

function TfrmMtoInventarios.BuscarArticuloDialog: string;
  // Fija DisplayLabel y formato de un campo para que la grilla
  // genérica muestre cabeceras legibles sin layout guardado.
  procedure ConfigCampo(F: TField; const ALabel, AFormat: string);
  begin
    if F = nil then Exit;
    F.DisplayLabel := ALabel;
    if AFormat = '' then Exit;
    if F is TFloatField then
      TFloatField(F).DisplayFormat := AFormat
    else if F is TBCDField then
      TBCDField(F).DisplayFormat := AFormat
    else if F is TSQLTimeStampField then
      TSQLTimeStampField(F).DisplayFormat := AFormat;
  end;
var
  unqryBusq: TUniQuery;
begin
  Result := '';
  unqryBusq := TUniQuery.Create(nil);
  try
    unqryBusq.Connection := ConexionPrincipal;
    unqryBusq.SQL.Text :=
      'SELECT'                                                      + sLineBreak +
      '    v.CODIGO_ART_ART,'                                       + sLineBreak +
      '    v.DESCRIPCION_ART,'                                      + sLineBreak +
      '    v.DESCRIPCION_FAM,'                                      + sLineBreak +
      '    pv.PV                       AS TEMPORADA,'               + sLineBreak +
      '    v.RAZON_SOCIAL_PROVEEDOR,'                               + sLineBreak +
      '    v.REF_PROVEEDOR,'                                        + sLineBreak +
      '    v.PRECIO_ULT_COMPRA,'                                    + sLineBreak +
      '    v.PRECIO_FINAL_ARTTAR,'                                  + sLineBreak +
      '    v.TIPO_CANTIDAD_ART'                                     + sLineBreak +
      'FROM vi_art_busquedas v'                                     + sLineBreak +
      'LEFT JOIN fza_articulos_propiedades ap'                      + sLineBreak +
      '       ON ap.CODIGO_ART_ART = v.CODIGO_ART_ART'             + sLineBreak +
      '      AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'''            + sLineBreak +
      // Nivel articulo: evita duplicar el articulo por temporadas de color
      '      AND ap.CODIGO_UNIDAD_ARTPROP = '''''                   + sLineBreak +
      'LEFT JOIN fza_propiedades_valores pv'                        + sLineBreak +
      '       ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'              + sLineBreak +
      'ORDER BY v.CODIGO_ART_ART';
    unqryBusq.Open;
    ConfigCampo(unqryBusq.FindField('CODIGO_ART_ART'),
                'Código',                '');
    ConfigCampo(unqryBusq.FindField('DESCRIPCION_ART'),
                'Descripción',           '');
    ConfigCampo(unqryBusq.FindField('DESCRIPCION_FAM'),
                'Familia',               '');
    ConfigCampo(unqryBusq.FindField('TEMPORADA'),
                'Temporada',             '');
    ConfigCampo(unqryBusq.FindField('RAZON_SOCIAL_PROVEEDOR'),
                'Proveedor',             '');
    ConfigCampo(unqryBusq.FindField('REF_PROVEEDOR'),
                'Ref. proveedor',        '');
    ConfigCampo(unqryBusq.FindField('PRECIO_ULT_COMPRA'),
                'P. compra',             '#,##0.00 €');
    ConfigCampo(unqryBusq.FindField('PRECIO_FINAL_ARTTAR'),
                'P. venta',              '#,##0.00 €');
    ConfigCampo(unqryBusq.FindField('TIPO_CANTIDAD_ART'),
                'Tipo cant.',            '');
    if TBusquedaUtils.EjecutarBusqueda(ConexionPrincipal,
         'Búsqueda de Artículos',
         unqryBusq,
         'frmMtoArtInvSearch') then
      Result := unqryBusq.FieldByName('CODIGO_ART_ART').AsString;
  finally
    FreeAndNil(unqryBusq);
  end;
end;

function TfrmMtoInventarios.BuscarSkuDialog: string;
  procedure ConfigCampo(F: TField; const ALabel, AFormat: string);
  begin
    if F = nil then
      Exit;
    F.DisplayLabel := ALabel;
    if AFormat = '' then
      Exit;
    if F is TFloatField then
      TFloatField(F).DisplayFormat := AFormat
    else if F is TBCDField then
      TBCDField(F).DisplayFormat := AFormat
    else if F is TSQLTimeStampField then
      TSQLTimeStampField(F).DisplayFormat := AFormat;
  end;
var
  unqryBusq: TUniQuery;
begin
  Result := '';
  unqryBusq := TUniQuery.Create(nil);
  try
    unqryBusq.Connection := ConexionPrincipal;
    unqryBusq.SQL.Text :=
      'SELECT SK.CODIGO_UNIDAD_SKU,'                         + sLineBreak +
      '       SK.CODIGO_ART_SKU,'                            + sLineBreak +
      '       A.DESCRIPCION_ART,'                            + sLineBreak +
      '       GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
      '                    AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS,' +
                                                               sLineBreak +
      '       IFNULL(STK.CANTIDAD_STK, 0) AS CANTIDAD_STK,'  + sLineBreak +
      '       IFNULL(STK.PRECIO_MEDIO_STK, 0) AS PRECIO_MEDIO_STK ' +
                                                               sLineBreak +
      '  FROM fza_articulos_skus SK'                         + sLineBreak +
      '  JOIN fza_articulos A'                               + sLineBreak +
      '    ON A.CODIGO_ART_ART = SK.CODIGO_ART_SKU'          + sLineBreak +
      '  LEFT JOIN ('                                        + sLineBreak +
      '       SELECT CODIGO_UNIDAD_STK,'                     + sLineBreak +
      '              SUM(CANTIDAD_STK) AS CANTIDAD_STK,'     + sLineBreak +
      '              CASE WHEN SUM(CANTIDAD_STK) <> 0'       + sLineBreak +
      '                   THEN SUM(VALOR_TOTAL_STK) / SUM(CANTIDAD_STK)' +
                                                               sLineBreak +
      '                   ELSE MAX(PRECIO_MEDIO_STK)'        + sLineBreak +
      '              END AS PRECIO_MEDIO_STK'                + sLineBreak +
      '         FROM fza_articulos_stockactual'              + sLineBreak +
      '        WHERE CODIGO_ALM_STK = :ALMACEN'              + sLineBreak +
      '        GROUP BY CODIGO_UNIDAD_STK'                   + sLineBreak +
      '       ) STK'                                         + sLineBreak +
      '    ON STK.CODIGO_UNIDAD_STK = SK.CODIGO_UNIDAD_SKU'  + sLineBreak +
      '  LEFT JOIN fza_atributos_sku SA'                     + sLineBreak +
      '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU' + sLineBreak +
      '  LEFT JOIN fza_atributos_valores AV'                 + sLineBreak +
      '    ON AV.ID_AV = SA.ID_AV_SA'                        + sLineBreak +
      '  LEFT JOIN fza_variaciones_atributos VA'             + sLineBreak +
      '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU'              + sLineBreak +
      '   AND VA.ID_ATB_VA = AV.ID_VA_AV'                    + sLineBreak +
      ' WHERE COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'''      + sLineBreak +
      '   AND A.TIPO_ART = ''ESTANDAR'''                     + sLineBreak +
      ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU,'   + sLineBreak +
      '          A.DESCRIPCION_ART, STK.CANTIDAD_STK,'       + sLineBreak +
      '          STK.PRECIO_MEDIO_STK'                       + sLineBreak +
      ' ORDER BY SK.CODIGO_UNIDAD_SKU';
    if dmmInventarios <> nil then
      unqryBusq.ParamByName('ALMACEN').AsString :=
        dmmInventarios.CodigoAlmacen
    else
      unqryBusq.ParamByName('ALMACEN').AsString := '';
    unqryBusq.Open;
    ConfigCampo(unqryBusq.FindField('CODIGO_UNIDAD_SKU'),
                'SKU',                   '');
    ConfigCampo(unqryBusq.FindField('CODIGO_ART_SKU'),
                'Artículo',              '');
    ConfigCampo(unqryBusq.FindField('DESCRIPCION_ART'),
                'Descripción',           '');
    ConfigCampo(unqryBusq.FindField('ATRIBUTOS'),
                'Atributos',             '');
    ConfigCampo(unqryBusq.FindField('CANTIDAD_STK'),
                'Stock',                 '#,##0.00');
    ConfigCampo(unqryBusq.FindField('PRECIO_MEDIO_STK'),
                'PMP',                   '#,##0.0000');
    if TBusquedaUtils.EjecutarBusqueda(ConexionPrincipal,
         'Búsqueda de SKUs',
         unqryBusq,
         'frmMtoInvSkuSearch',
         Self) then
      Result := unqryBusq.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  finally
    FreeAndNil(unqryBusq);
  end;
end;

procedure TfrmMtoInventarios.ResolverInputArticulo(const AInput: string;
                                                  out ACodigoPadre: string;
                                                  out ACodigoSku: string;
                                                  out ADescripcion: string;
                                                  out ATipoArt: string;
                                                  out AEncontrado: Boolean);
var
  Validador  : IArticulosValidador;
  Resolucion : TArtResolucionEntrada;
begin
  ACodigoPadre := '';
  ACodigoSku   := '';
  ADescripcion := '';
  ATipoArt     := '';
  AEncontrado  := False;
  if Trim(AInput) = '' then Exit;

  Validador := CrearValidadorArticulos(ConexionPrincipal);
  try
    Resolucion := Validador.Resolver(AInput);
    if not Resolucion.Encontrado then Exit;
    ACodigoPadre := Resolucion.CodigoArticulo;
    ACodigoSku   := Resolucion.CodigoSku;
    ADescripcion := Resolucion.DescripcionArticulo;
    ATipoArt     := Resolucion.TipoArticulo;
    AEncontrado  := True;
  finally
    Validador := nil;
  end;
end;

procedure TfrmMtoInventarios.RellenarLineaDesdeBusqueda(const AInput: string;
                                                       var AResolvedValue: string;
                                                       var AError: Boolean;
                                                       var AErrorText: TCaption);
var
  CodPadre, CodSku, Desc, TipoArt: string;
  Encontrado: Boolean;
  CantTeo, PMPAct: Currency;
  NumAtr: Integer;
  swTotal, swTramo: TStopwatch;
  msResolver, msSetFieldsCabecera, msActColsDin,
  msSetFieldsSku, msRellenarDatosSku, msSetFieldsImporte,
  msRellenarAtributos: Int64;

  function AsegurarEdicionLinea: Boolean;
  begin
    Result := False;
    if (dmmInventarios = nil) or
       (not dmmInventarios.cdsLineas.Active) then
    begin
      AError := True;
      AErrorText := SErrorLineasInventarioNoAbiertas;
      Exit;
    end;
    if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
      dmmInventarios.cdsLineas.Edit;
    if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    begin
      AError := True;
      AErrorText := SErrorLineaInventarioNoEditable;
      Exit;
    end;
    Result := True;
  end;
begin
  AError := False;
  AErrorText := '';

  // [PERF:RellenarLineaBusqueda] Cronometros por tramo. El usuario reporta
  // ~10 s entre elegir un articulo con SKU y ver el color. Necesitamos saber
  // si el coste vive en ResolverInputArticulo, en RellenarDatosArticulo,
  // en la SQL de columnas dinamicas, en RellenarDatosSku o en
  // RellenarAtributosDesdeSku. Cada Lookup arranca una conexion / ejecuta
  // queries, asi que aqui se ve el reparto.
//  msSetFieldsCabecera     := 0;
//  msActColsDin            := 0;
//  msSetFieldsSku          := 0;
  msRellenarDatosSku      := 0;
  msSetFieldsImporte      := 0;
  msRellenarAtributos     := 0;
  swTotal := TStopwatch.StartNew;

  swTramo := TStopwatch.StartNew;
  ResolverInputArticulo(AInput, CodPadre, CodSku, Desc, TipoArt, Encontrado);
  msResolver := swTramo.ElapsedMilliseconds;

  if not Encontrado then
  begin
    AError := True;
    AErrorText := SErrorArticuloInventarioNoEncontrado;
    inLibLog.Log.LogPerf('RellenarLineaDesdeBusqueda(NO ENCONTRADO)',
      Format('input=%s | Resolver=%d', [AInput, msResolver]),
      swTotal.ElapsedMilliseconds);
    Exit;
  end;

  // Solo se admiten artículos físicos (TIPO_ART='ESTANDAR') en inventarios.
  // SERVICIO/KIT no llevan stock, así que no tiene sentido recontarlos.
  if not SameText(TipoArt, 'ESTANDAR') then
  begin
    AError := True;
    AErrorText := Format(SErrorArticuloInventarioTipoSinStock,
                         [CodPadre, TipoArt]);
    Exit;
  end;
  NumAtr := 0;
  if (not FMostrarColumnasAtributos) and (CodSku = '') then
  begin
    NumAtr := ObtenerNumAtributosArticulo(CodPadre);
    if NumAtr > 0 then
    begin
      AError := True;
      AErrorText := Format(SErrorArticuloInventarioAtributosSinSku,
        [CodPadre]);
      Exit;
    end;
  end;

  if not AsegurarEdicionLinea then
    Exit;

  // Resolver ya nos dio Desc y TipoArt: NO volvemos a llamar a
  // RellenarDatosArticulo (que abria unqryArticulo + unqryDefinicionArticulo)
  // porque la SQL de vi_atributos_nombres es justo la que ActualizarColumnasDinamicas
  // va a ejecutar a continuacion. Antes esa SQL se lanzaba dos veces para
  // el mismo articulo y se comia 12 s (6+6).
  swTramo := TStopwatch.StartNew;
  dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString          :=
    CodPadre;
  dmmInventarios.cdsLineas.FieldByName(
    'DESCRIPCION_ARTICULO_INVLIN').AsString := Desc;
  msSetFieldsCabecera := swTramo.ElapsedMilliseconds;

  // ActualizarColumnasDinamicas hace el unico hit a vi_atributos_nombres,
  // pinta los captions de SKU1..5 y, dentro, asigna FNumAtributosActual y
  // NUM_ATRIBUTOS_REQ_INV_LINEA del cds. Usamos FNumAtributosActual como
  // valor de NumAtr para la rama de SKU posterior.
  swTramo := TStopwatch.StartNew;
  ActualizarColumnasDinamicas(CodPadre);
  msActColsDin := swTramo.ElapsedMilliseconds;
  if FMostrarColumnasAtributos then
    NumAtr := FNumAtributosActual;
  if not AsegurarEdicionLinea then
    Exit;

  if CodSku <> '' then
  begin
    // Match por SKU o codigo de barras: ya tenemos el SKU concreto
    swTramo := TStopwatch.StartNew;
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodSku;
    AResolvedValue := CodSku;
    msSetFieldsSku := swTramo.ElapsedMilliseconds;

    swTramo := TStopwatch.StartNew;
    dmmInventarios.RellenarDatosSku(CodSku, CantTeo, PMPAct);
    msRellenarDatosSku := swTramo.ElapsedMilliseconds;

    swTramo := TStopwatch.StartNew;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.AsegurarFechaRecuentoLinea;
    msSetFieldsImporte := swTramo.ElapsedMilliseconds;

    swTramo := TStopwatch.StartNew;
    RellenarAtributosDesdeSku(CodSku);
    msRellenarAtributos := swTramo.ElapsedMilliseconds;
  end
  else if NumAtr = 0 then
  begin
    // Articulo sin variaciones: SKU = codigo articulo
    swTramo := TStopwatch.StartNew;
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodPadre;
    AResolvedValue := CodPadre;
    msSetFieldsSku := swTramo.ElapsedMilliseconds;

    swTramo := TStopwatch.StartNew;
    dmmInventarios.RellenarDatosSku(CodPadre, CantTeo, PMPAct);
    msRellenarDatosSku := swTramo.ElapsedMilliseconds;

    swTramo := TStopwatch.StartNew;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.AsegurarFechaRecuentoLinea;
    msSetFieldsImporte := swTramo.ElapsedMilliseconds;
  end
  else
  begin
    // Articulo padre con variaciones: el SKU empieza siendo el codigo del
    // articulo (sin atributos todavia) para que el usuario tenga referencia
    // visual de la linea. Cada vez que rellene un atributo, OnAtributoChanged
    // reconstruira el SKU concatenando los valores.
    swTramo := TStopwatch.StartNew;
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodPadre;
    AResolvedValue := CodPadre;
    msSetFieldsSku := swTramo.ElapsedMilliseconds;
  end;

  inLibLog.Log.LogPerf('RellenarLineaDesdeBusqueda',
    Format('input=%s padre=%s sku=%s NumAtr=%d | Resolver=%d ' +
           'SetFieldsCab=%d ActColsDin=%d ' +
           'SetFieldsSku=%d RellenarDatosSku=%d SetFieldsImporte=%d ' +
           'RellenarAtributos=%d',
           [AInput, CodPadre, CodSku, NumAtr,
            msResolver, msSetFieldsCabecera,
            msActColsDin, msSetFieldsSku, msRellenarDatosSku,
            msSetFieldsImporte, msRellenarAtributos]),
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoInventarios.tvLineasUdsFisicasPropertiesValidate(
  Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Fis, Teo, PMPAct, PMPNue, DifUds, DifCoste: Currency;
begin
  Error := False;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  Fis    := StrToCurrDef(VarToStr(DisplayValue), 0);
  Teo    :=
    dmmInventarios.cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency;
  PMPAct :=
    dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency;
  PMPNue := dmmInventarios.cdsLineas.FieldByName(
    'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency;

  DifUds   := Fis - Teo;
  DifCoste := (Fis * PMPNue) - (Teo * PMPAct);

  dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_DIFERENCIA_INVLIN').AsCurrency := DifUds;
  dmmInventarios.cdsLineas.FieldByName(
    'TOTAL_COSTE_DIFERENCIA_INVLIN').AsCurrency           := DifCoste;
  dmmInventarios.AsegurarFechaRecuentoLinea;
end;

procedure TfrmMtoInventarios.tvLineasGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
begin
  // Tooltip explicativo en columnas clave
  if ACellViewInfo.Item = tvLineasUDS_TEORICAS then
    AHintText := 'Stock que el sistema cree que hay en el almacén'
  else if ACellViewInfo.Item = tvLineasUDS_FISICAS then
    AHintText := 'Lo que realmente has contado'
  else if ACellViewInfo.Item = tvLineasPMP_NUEVO then
    AHintText := 'Precio Medio que tendrá el SKU tras aplicar el inventario'
  else if ACellViewInfo.Item = tvLineasUDS_REGULARIZADAS then
    AHintText := 'Solo se rellena cuando el inventario está APLICADO';
end;

// ============================================================================
//   BOTONES DE PESTAÑA CABECERA
// ============================================================================

procedure TfrmMtoInventarios.btnRecalcularClick(Sender: TObject);
begin
  if MessageDlg(SPreguntaRecalcularInventario,
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.RecalcularTeorico;
    ShowMessage(SInfoRecalculoInventario);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnAplicarClick(Sender: TObject);
begin
  if MessageDlg(SPreguntaAplicarInventario,
       mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  // Fase 2: el regularizar se parte en 3 tramos. (1) validacion +
  // ApplyUpdates aqui (main thread, toca grid de lineas). (2) SP en
  // background (solo BBDD, otros tabs siguen interactivos). (3) recarga
  // de grids en el callback main-thread.
  try
    dmmInventarios.PreAplicarValidaciones;
  except
    on E: Exception do
    begin
      ShowMessage(Format(SErrorAplicarInventario, [E.Message]));
      Exit;
    end;
  end;

  EjecutarEnBackground(
    procedure
    begin
      dmmInventarios.EjecutarSPAplicar;
    end,
    procedure(ErrMsg: string)
    begin
      if ErrMsg <> '' then
      begin
        ShowMessage(Format(SErrorAplicacionInventario, [ErrMsg]));
        Exit;
      end;
      try
        dmmInventarios.RefrescarTrasAplicar;
      except
        on E: Exception do
        begin
          ShowMessage(Format(SErrorRefrescarInventarioAplicado,
                             [E.Message]));
          Exit;
        end;
      end;
      ShowMessage(SInfoInventarioAplicado);
      pcDetail.ActivePage := tsMovsRegul;
    end);
end;

procedure TfrmMtoInventarios.btnRecalcularDetalleClick(Sender: TObject);
begin
  btnRecalcularClick(Sender);
end;

// ============================================================================
//   HOOK: foco en SKU/Articulo tras insertar desde el navigator
// ============================================================================

procedure TfrmMtoInventarios.cdsLineasAfterInsertHook(DataSet: TDataSet);
begin
  // Foco en la columna de entrada activa (Articulo o SKU/Articulo) tras insertar
  tvLineas.Controller.FocusedColumn := ColumnaEntradaActiva;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

// ============================================================================
//   BOTONES DE PESTAÑA DETALLE
// ============================================================================

procedure TfrmMtoInventarios.btnAnadirLineaClick(Sender: TObject);
var
  Estado: string;
begin
  // Diagnostico: si por algun motivo no se puede editar (cabecera no
  // ABIERTO, dsTablaG vacio, etc.) el botón quedaba en exit silencioso y
  // el usuario veia "no pasa nada al pulsar". Damos feedback explicito.
  if not PuedeEditar then
  begin
    Estado := EstadoActual;
    if Estado = '' then
      ShowMessage(SErrorInventarioNoSeleccionadoAnadirLineas)
    else
      ShowMessage(Format(SErrorAnadirLineasInventarioEstado, [Estado]));
    Exit;
  end;

  // 1. Resolver el estado actual de edicion ANTES de tocar variables o
  // atributos. Si la linea actual es un placeholder sin articulo,
  // cancelamos para no arrastrarla. Hacer esto primero deja el cds en
  // estado browse, lo que vuelve seguro recorrerlo en el siguiente paso.
  if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    if Trim(dmmInventarios.cdsLineas.FieldByName(
                                'CODIGO_ART_INVLIN').AsString) = '' then
      dmmInventarios.cdsLineas.Cancel
    else
      dmmInventarios.cdsLineas.Post;
  end;

  // 2. Respetamos el modo elegido. En modo SKU las columnas de atributos
  // permanecen ocultas; para editar por Color/Talla se activa el check.
  if not FMostrarColumnasAtributos then
  begin
    FUltimoArticuloPadre := '__FORZAR__';
    ActualizarColumnasDinamicas('');
  end;

  // 3. Anadir la nueva linea
  dmmInventarios.cdsLineas.Append;

  // 4. Foco en la columna de entrada activa (Articulo o SKU/Articulo)
  tvLineas.Controller.FocusedColumn := ColumnaEntradaActiva;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoInventarios.btnAnadirSkusArtClick(Sender: TObject);
var
  CodigoArticulo: string;
  Insertados: Integer;
begin
  if not PuedeEditar then Exit;

  if dmmInventarios.cdsLineas.IsEmpty then
  begin
    ShowMessage(SErrorLineaInventarioNoSeleccionadaParaSkus);
    Exit;
  end;

  // Comprobar el artículo ANTES de intentar postear: si la línea actual es
  // un placeholder sin artículo, postear lanzaría cdsLineasBeforePost.
  CodigoArticulo := Trim(dmmInventarios.cdsLineas.FieldByName(
                          'CODIGO_ART_INVLIN').AsString);
  if CodigoArticulo = '' then
  begin
    ShowMessage(SErrorLineaInventarioSinArticulo);
    Exit;
  end;

  if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
    dmmInventarios.cdsLineas.Post;

  Screen.Cursor := crHourGlass;
  try
    try
      Insertados := dmmInventarios.CargarSkusConMovimientosArticulo(
                                                              CodigoArticulo);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        ShowMessage(Format(SErrorAnadirSkusInventario, [E.Message]));
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if Insertados = 0 then
    ShowMessage(Format(SInfoSinSkusAnadidosInventario, [CodigoArticulo]))
  else
    ShowMessage(Format(SInfoSkusAnadidosInventario,
                       [Insertados, CodigoArticulo]));
end;

procedure TfrmMtoInventarios.btnEliminarLineaClick(Sender: TObject);
begin
  if not PuedeEditar then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;

  if MessageDlg(SPreguntaEliminarLineaInventario,
       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    dmmInventarios.cdsLineas.Delete;
    dmmInventarios.cdsLineas.ApplyUpdates(0);
  end;
end;

// ============================================================================
//   BOTONES DE PESTAÑA MOVIMIENTOS REGULARIZADOS
// ============================================================================

procedure TfrmMtoInventarios.btnEliminarRegularizacionClick(Sender: TObject);
begin
  if EstadoActual <> 'APLICADO' then
  begin
    ShowMessage(SErrorEliminarRegularizacionInventarioEstado);
    Exit;
  end;

  if MessageDlg(SPreguntaEliminarRegularizacionInventario,
       mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.EliminarRegularizacion;
    ShowMessage(SInfoRegularizacionInventarioEliminada);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnExportarInvClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
begin
  if not PuedeExportar then
    Abort;
  if dmmInventarios.unqryTablaG.IsEmpty then
  begin
    ShowMessage(SErrorInventarioNoActivo);
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    // Solo recargar si no estan ya abiertas (evitar re-query de 4 s)
    if not dmmInventarios.cdsLineas.Active then
      dmmInventarios.CargarLineasInventario;
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.PopupParent := Self;
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName :=
        'Inventario_' +
        dmmInventarios.unqryTablaG.FieldByName('SERIE_INV').AsString + '_' +
        dmmInventarios.unqryTablaG.FieldByName('NUMERO_INV').AsString;
      ExportarInventarioExcel(
        fPreview.dxSpreadSheet1,
        dmmInventarios.unqryTablaG,
        dmmInventarios.cdsLineas);
    finally
      Screen.Cursor := crDefault;
    end;
    fPreview.ShowModal;
  finally
    FreeAndNil(fPreview);
  end;
end;

procedure TfrmMtoInventarios.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  actIraArticuloExecute(Self);
end;

procedure TfrmMtoInventarios.btnIraArticuloMovClick(Sender: TObject);
begin
  inherited;
  actIraArticuloExecute(Self);
end;

// ============================================================================
//   BOTONES DE PESTAÑA CARGAS MASIVAS
// ============================================================================

procedure TfrmMtoInventarios.btnCargarPorFamiliaClick(Sender: TObject);
var
  Familia: string;
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioDebeEstarAbierto); Exit;
  end;

  Familia :=
    dmmInventarios.unqryFamilias.FieldByName('CODIGO_FAM_FAM').AsString;
  if Familia = '' then
  begin
    ShowMessage(SErrorFamiliaInventarioNoSeleccionada); Exit;
  end;

  if MessageDlg(
       Format(SPreguntaCargarFamiliaInventario, [Familia]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CargarPorFamilia(Familia);
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnCargarPorProveedorClick(Sender: TObject);
var
  Proveedor: string;
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioDebeEstarAbierto); Exit;
  end;

  Proveedor :=
    dmmInventarios.unqryProveedores.FieldByName('CODIGO_PRV_PRV').AsString;
  if Proveedor = '' then
  begin
    ShowMessage(SErrorProveedorInventarioNoSeleccionado); Exit;
  end;

  if MessageDlg(
       Format(SPreguntaCargarProveedorInventario, [Proveedor]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CargarPorProveedor(Proveedor);
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnCompletarClick(Sender: TObject);
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioDebeEstarAbierto); Exit;
  end;

  if MessageDlg(SPreguntaCompletarInventario,
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CompletarUnidadesNoLeidas;
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnCargarTodoClick(Sender: TObject);
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioDebeEstarAbierto); Exit;
  end;

  if MessageDlg(SPreguntaCargarTodoInventario,
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CargarTodosArticulosConStock;
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.edtRutaExcelPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  dlgAbrir.Filter := 'Archivos Excel (*.xlsx;*.xls)|*.xlsx;*.xls|' +
                     'Archivos CSV (*.csv;*.txt)|*.csv;*.txt|' +
                     'Todos|*.*';
//  if dlgAbrir.Execute then
//    edtRutaExcel.Text := dlgAbrir.FileName;
end;

procedure TfrmMtoInventarios.btnCargarClick(Sender: TObject);
var
  res: TAddBlockInventarioResult;
  ds : TDataSet;
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioDebeEstarAbierto);
    Exit;
  end;

  ds := dsTablaG.DataSet;
  if (ds = nil) or ds.IsEmpty then
  begin
    ShowMessage(SErrorInventarioNoSeleccionado);
    Exit;
  end;

  if ds.State in [dsInsert, dsEdit] then
  begin
    if MessageDlg(SPreguntaGuardarInventarioEnEdicion,
                  mtConfirmation, [mbYes, mbNo, mbCancel], 0) = mrYes then
      ds.Post
    else
      Exit;
  end;

  res := TfrmModalAddBlockInventario.Ejecutar(
           Self,
           (ds as TUniQuery).Connection,
           ds.FieldByName('CODIGO_EMP_INV').AsString,
           ds.FieldByName('CODIGO_ALM_INV').AsString,
           ds.FieldByName('SERIE_INV').AsString,
           ds.FieldByName('NUMERO_INV').AsString);

  if res.Aceptado then
  begin
    // Refrescar el grid de lineas y proponer recalcular
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;

    if MessageDlg(
         Format(SPreguntaRecalcularTrasCargarBloqueInventario,
                [res.NumLineas, res.NumArticulos]),
         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      btnRecalcularDetalleClick(nil);
  end;
end;

procedure TfrmMtoInventarios.btnCargarExcelClick(Sender: TObject);
var
  Lista: TStringList;
  Lineas: TLineasImportadas;
  ListaNuevos: TStringList;
  Archivo, sMsg: string;
  Sheet: TdxSpreadSheet;
  i, iActualizados, iNuevos: Integer;
begin
  if not PuedeEditar then
  begin
    ShowMessage(SErrorInventarioDebeEstarAbierto);
    Exit;
  end;
  dlgAbrir.Filter :=
    'Excel (*.xlsx)|*.xlsx|CSV (*.csv;*.txt)|*.csv;*.txt|Todos (*.*)|*.*';
  dlgAbrir.DefaultExt := 'xlsx';
  if not dlgAbrir.Execute then
    Exit;
  Archivo := dlgAbrir.FileName;
  if not FileExists(Archivo) then
  begin
    ShowMessage(SErrorArchivoImportacionInventarioNoExiste);
    Exit;
  end;
  Lista := nil;
  SetLength(Lineas, 0);
  if SameText(ExtractFileExt(Archivo), '.xlsx') or
     SameText(ExtractFileExt(Archivo), '.xls') then
  begin
    Sheet := TdxSpreadSheet.Create(nil);
    try
      Sheet.LoadFromFile(Archivo);
      ImportarInventarioDesdeSheet(CrearLectorDevEx(Sheet),
        Lineas, Lista, sMsg);
    finally
      FreeAndNil(Sheet);
    end;
  end
  else
  begin
    Lista := TStringList.Create;
    Lista.LoadFromFile(Archivo);
    for i := 0 to Lista.Count - 1 do
      Lista[i] := StringReplace(Lista[i], ';', '=', [rfReplaceAll]);
    sMsg := Format(SInfoLineasCsvInventarioLeidas, [Lista.Count]);
  end;
  if (Lista = nil) or (Lista.Count = 0) then
  begin
    if sMsg <> '' then
      ShowMessage(sMsg)
    else
      ShowMessage(SErrorImportacionInventarioSinDatos);
    FreeAndNil(Lista);
    Exit;
  end;
  // Existentes: actualizar cantidad y PMP. Nuevos: insertar via DM.
  Screen.Cursor := crHourGlass;
  ListaNuevos := TStringList.Create;
  try
    iActualizados := 0;
    iNuevos := 0;
    dmmInventarios.cdsLineas.DisableControls;
    try
      // Ruta Excel: tenemos el array con PMP
      if Length(Lineas) > 0 then
      begin
        for i := 0 to High(Lineas) do
        begin
          if Lineas[i].Sku = '' then
            Continue;
          if dmmInventarios.cdsLineas.Locate(
               'CODIGO_UNIDAD_INVLIN', Lineas[i].Sku, [loCaseInsensitive]) then
          begin
            dmmInventarios.cdsLineas.Edit;
            dmmInventarios.cdsLineas.FieldByName(
              'CANTIDAD_FISICA_INVLIN').AsFloat := Lineas[i].Cantidad;
            if Lineas[i].TienePmp then
              dmmInventarios.cdsLineas.FieldByName(
                'PRECIO_MEDIO_NUEVO_INVLIN').AsFloat := Lineas[i].PmpNuevo;
            dmmInventarios.AsegurarFechaRecuentoLinea;
            dmmInventarios.cdsLineas.Post;
            Inc(iActualizados);
          end
          else
          begin
            ListaNuevos.Add(Lista[i]);
            Inc(iNuevos);
          end;
        end;
      end
      else
      begin
        // Ruta CSV: solo SKU=Cantidad, sin PMP
        for i := 0 to Lista.Count - 1 do
        begin
          var sSku := Lista.Names[i];
          if sSku = '' then
            Continue;
          if dmmInventarios.cdsLineas.Locate(
               'CODIGO_UNIDAD_INVLIN', sSku, [loCaseInsensitive]) then
          begin
            dmmInventarios.cdsLineas.Edit;
            dmmInventarios.cdsLineas.FieldByName(
              'CANTIDAD_FISICA_INVLIN').AsFloat :=
              StrToFloatDef(Lista.ValueFromIndex[i], 1);
            dmmInventarios.AsegurarFechaRecuentoLinea;
            dmmInventarios.cdsLineas.Post;
            Inc(iActualizados);
          end
          else
          begin
            ListaNuevos.Add(Lista[i]);
            Inc(iNuevos);
          end;
        end;
      end;
      if iActualizados > 0 then
        dmmInventarios.cdsLineas.ApplyUpdates(0);
    finally
      dmmInventarios.cdsLineas.EnableControls;
    end;
    if ListaNuevos.Count > 0 then
      dmmInventarios.CargarDesdeListaSkus(ListaNuevos);
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
    ShowMessage(Format(SInfoImportacionInventario,
                       [sMsg, iActualizados, iNuevos]));
  finally
    Screen.Cursor := crDefault;
    FreeAndNil(Lista);
    FreeAndNil(ListaNuevos);
  end;
end;

// ============================================================================
//   RECUENTO REMOTO CON LA APP (servidor PHP, ver inLibInventarioNube)
// ============================================================================

procedure TfrmMtoInventarios.btnEnviarRecuentoClick(Sender: TObject);
var
  sEmp, sAlm, sSerie, sNumero, sDesc, sMsg: string;
  idRec: Int64;
begin
  if dmmInventarios.unqryTablaG.IsEmpty then
  begin
    ShowMessage(SErrorInventarioNoActivo);
    Exit;
  end;
  if dmmInventarios.unqryTablaG.FieldByName('ESTADO_INV').AsString <>
     'ABIERTO' then
  begin
    ShowMessage(SErrorEnviarRecuentoInventarioNoAbierto);
    Exit;
  end;
  if not ComprobarRecuentoRemotoDisponible then
    Exit;
  sEmp    := dmmInventarios.unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString;
  sAlm    := dmmInventarios.unqryTablaG.FieldByName('CODIGO_ALM_INV').AsString;
  sSerie  := dmmInventarios.unqryTablaG.FieldByName('SERIE_INV').AsString;
  sNumero := dmmInventarios.unqryTablaG.FieldByName('NUMERO_INV').AsString;
  sDesc   := dmmInventarios.unqryTablaG.FieldByName('DESCRIPCION_INV').AsString;
  if MessageDlg(SPreguntaEnviarRecuentoInventario,
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    if EnviarInventario(
      ParametrosApp,
      ConexionPrincipal,
      sEmp,
      sAlm,
      sSerie,
      sNumero,
                        sDesc, 'DIRIGIDO', idRec, sMsg) then
    begin
      ConexionPrincipal.ExecSQL(
        ' UPDATE fza_inventarios SET ESRECUENTO_REMOTO_INV = ''S'',' +
        '   INSTANTE_ENVIO_RECUENTO_INV = NOW(),' +
        '   ID_RECUENTO_REMOTO_INV = :ID' +
        ' WHERE CODIGO_EMP_INV = :E AND CODIGO_ALM_INV = :A' +
        '   AND SERIE_INV = :S AND NUMERO_INV = :N',
        [IntToStr(idRec), sEmp, sAlm, sSerie, sNumero]);
      dmmInventarios.unqryTablaG.Refresh;
      ShowMessage(Format(SInfoInventarioEnviadoRecuento, [idRec]));
    end
    else
      ShowMessage(Format(SErrorEnviarRecuentoInventario, [sMsg]));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnRecogerRecuentoClick(Sender: TObject);
var
  sEmp, sAlm, sSerie, sNumero, sMsg: string;
  idRec: Int64;
  Lista: TStringList;
  iNumEv: Integer;
begin
  if dmmInventarios.unqryTablaG.IsEmpty then
  begin
    ShowMessage(SErrorInventarioNoActivo);
    Exit;
  end;
  if not ComprobarRecuentoRemotoDisponible then
    Exit;
  idRec := StrToInt64Def(dmmInventarios.unqryTablaG.FieldByName(
                           'ID_RECUENTO_REMOTO_INV').AsString, 0);
  if idRec <= 0 then
  begin
    ShowMessage(SErrorInventarioNoEnviadoRecuento);
    Exit;
  end;
  if dmmInventarios.unqryTablaG.FieldByName('ESTADO_INV').AsString <>
     'ABIERTO' then
  begin
    ShowMessage(SErrorRecogerRecuentoInventarioNoAbierto);
    Exit;
  end;
  sEmp    := dmmInventarios.unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString;
  sAlm    := dmmInventarios.unqryTablaG.FieldByName('CODIGO_ALM_INV').AsString;
  sSerie  := dmmInventarios.unqryTablaG.FieldByName('SERIE_INV').AsString;
  sNumero := dmmInventarios.unqryTablaG.FieldByName('NUMERO_INV').AsString;
  Screen.Cursor := crHourGlass;
  Lista := TStringList.Create;
  try
    if RecogerRecuento(
      ParametrosApp,
      ConexionPrincipal,
      sEmp,
      sAlm,
      sSerie,
      sNumero,
                       IdentidadSesion.Usuario, idRec, Lista, iNumEv,
                       sMsg) then
    begin
      // Volcamos el agregado SKU=CANTIDAD a las físicas, igual que el Excel.
      if Lista.Count > 0 then
        dmmInventarios.CargarDesdeListaSkus(Lista);
      ConexionPrincipal.ExecSQL(
        ' UPDATE fza_inventarios SET INSTANTE_RECOGIDA_RECUENTO_INV = NOW()' +
        ' WHERE CODIGO_EMP_INV = :E AND CODIGO_ALM_INV = :A' +
        '   AND SERIE_INV = :S AND NUMERO_INV = :N',
        [sEmp, sAlm, sSerie, sNumero]);
      dmmInventarios.CargarLineasInventario;
      // Igual que en la carga masiva: forzamos el refresco del grid para que
      // las lecturas recogidas se vean sin salir y volver a entrar.
      if Assigned(tvLineas) then
        tvLineas.DataController.Refresh;
      dmmInventarios.unqryTablaG.Refresh;
      ShowMessage(Format(SInfoRecuentoInventarioRecogido,
        [iNumEv, Lista.Count]));
    end
    else
      ShowMessage(Format(SErrorRecogerRecuentoInventario, [sMsg]));
  finally
    FreeAndNil(Lista);
    Screen.Cursor := crDefault;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoInventarios);

end.
