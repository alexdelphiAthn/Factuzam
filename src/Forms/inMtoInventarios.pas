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
  inLibRegistroPantallas,
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
  inLibColumnasSkuIntf,
  inLibInventariosAplicacionIntf,
  inLibRepositoriosPantallaIntf,
  inMtoInventariosPresentacionColumnas,
  inMtoInventariosPresentacionEntrada;

type
  // Capacidades que la pantalla necesita del exterior. Se inyectan al
  // crear la tabla principal; la pantalla no las localiza por su cuenta.
  TContextoDependenciasInventario = record
    AplicacionEntrada: IAplicacionEntradaInventario;
    Busquedas: IBusquedasInventario;
    RecuentoRemoto: IRepositorioRecuentoRemotoInventario;
  end;

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
    FProcesandoAtributo: Boolean;
    FInicializandoCombo: Boolean;
    FRefrescandoLookupsCabecera: Boolean;
    // Numero de lineas a partir del cual el desempaquetado necesita
    // feedback visual (por debajo es imperceptible).
    FUmbralProgresoDesempaquetado: Integer;
    // Bitmap reutilizable del cuadradito de color del boton [...] de las
    // columnas SKU; sin color el boton vuelve a bkEllipsis.
    FBmpSwatchBoton: TBitmap;
    // Estado y pintado de las columnas de atributo del grid de lineas.
    FGestorColumnas: TGestorColumnasAtributosInventario;

    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto -> SKU. El Construir del contrato hace ClearItems:
    // las columnas del dfm mueren y las rutas legacy quedan
    // cortocircuitadas con FGestorColumnas.ContratoConstruido.
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FDependencias: TContextoDependenciasInventario;
    FRepositoriosArticulos: IRepositoriosArticulosPantalla;

    // === COLUMNAS DINÁMICAS DE ATRIBUTOS ===
    procedure ActualizarColumnasDinamicas(const ArticuloPadre: string);
    procedure RellenarAtributosDesdeSku(const Sku: string);
    // Lectura de la definicion de atributos del articulo. Es el unico
    // punto de la pantalla que toca unqryDefinicionArticulo.
    function NombresAtributosArticulo(
      const ACodigoArticulo: string): TArray<string>;
    // Dependencias que necesita la reconstruccion del SKU de la linea.
    function ContextoEscrituraAtributo: TEscrituraAtributoInventario;
    // Rellena ATTR1..ATTR5_VALOR en cdsLineas (idempotente) mostrando el
    // overlay de progreso si hay muchas lineas.
    procedure AsegurarDesempaquetadoAtributos;
    // Handler OnEnter single-shot que abre el popup del selector de AV.
    procedure AbrirPopupSkuEnEntrada(Sender: TObject);

    // Escritura de la linea con el articulo ya validado.
    procedure EscribirArticuloValidadoLinea(
      const ACodigoArticulo, ADescripcion: string;
      ANumAtributos: Integer);

    // === BUSQUEDA UNIFICADA DE ARTICULOS (codigo, SKU o codigo de barras) ===
    procedure RellenarLineaDesdeBusqueda(const AInput: string;
                                         var AResolvedValue: string;
                                         var AError: Boolean;
                                         var AErrorText: TCaption);

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
    function ClaveInventarioActual: TClaveInventario;
    // Recarga de grids tras aplicar el inventario en background.
    procedure RefrescarTrasAplicarInventario;
    function AsegurarCabeceraPersistidaParaLineas: Boolean;
    procedure AsegurarPrimeraLineaInventario;
    procedure CargarLineasYRefrescar;
    // Guion comun de las cargas masivas: confirmar, ejecutar y refrescar.
    procedure EjecutarCargaMasiva(const APregunta: string;
                                  const ACarga: TProc);
    // === IMPORTACIÓN DE RECUENTOS ===
    // Lector del fichero (hoja de calculo o CSV) a lineas de importacion.
    function LeerFicheroRecuento(
      const AArchivo: string;
      out ALineas: TLineasImportacionInventario;
      out AMensaje: string): Boolean;
    procedure ImportarRecuentoEnLineas(
      const ALineas: TLineasImportacionInventario;
      const AMensaje: string);
    // === CONTRATO DE ENTRADA: construccion y enganches ===
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostInventario;
    // Precarga los nombres globales de las columnas de atributo del
    // contrato, que nacen ocultas hasta resolver un articulo.
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

  inLibMsgArticulos,
  inLibInventarioExcel, inLibHojaCalculoDevEx,
  inLibInventarioNube,
  inLibInventariosEntradaDataSet,
  inLibInventariosAplicacion,
  inLibInventariosPresentacion,
  inLibInventariosPresentacionIntf,
  inMtoInventariosEntradaVcl,
  inMtoInventariosPresentacionBusquedas,
  inMtoPreviewExcel,
  System.Diagnostics,
  inMtoModalAddBlockInventario,
  // Factoria del contrato de entrada (prueba ColumnSKUcxGrid).
  inLibColumnasSku, inLibColumnasDocumento, UniDataGen,
  UniDataColumnasSkuServicios,
  // Adaptadores de persistencia propios de la pantalla.
  UniDataInventariosBusquedas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure InicializarEntradaInventarioVcl(
  AFormulario: TfrmMtoInventarios;
  const AValidador: IArticulosValidador);
var
  Callbacks: TCallbacksEntradaInventario;
  Operaciones: IOperacionesEntradaInventario;
begin
  Callbacks := Default(TCallbacksEntradaInventario);
  Callbacks.MuestraAtributos :=
    function: Boolean
    begin
      Result := AFormulario.FGestorColumnas.MostrarAtributos;
    end;
  Callbacks.ObtenerNumeroAtributos :=
    function(const ACodigoArticulo: string): Integer
    begin
      Result := AFormulario.FGestorColumnas.NumeroAtributosArticulo(
        ACodigoArticulo);
    end;
  Callbacks.AsegurarEdicion :=
    function: TErrorEntradaInventario
    begin
      Result := eeiNinguno;
      if (AFormulario.dmmInventarios = nil) or
         (not AFormulario.dmmInventarios.cdsLineas.Active) then
        Result := eeiLineasNoAbiertas
      else
      begin
        if not (AFormulario.dmmInventarios.cdsLineas.State in
          [dsEdit, dsInsert]) then
          AFormulario.dmmInventarios.cdsLineas.Edit;
        if not (AFormulario.dmmInventarios.cdsLineas.State in
          [dsEdit, dsInsert]) then
          Result := eeiLineaNoEditable;
      end;
    end;
  Callbacks.EscribirArticulo :=
    procedure(const ACodigoArticulo, ADescripcion: string)
    begin
      EscribirArticuloLineaInventario(
        AFormulario.dmmInventarios.cdsLineas,
        ACodigoArticulo,
        ADescripcion);
    end;
  Callbacks.ActualizarColumnas :=
    procedure(const ACodigoArticulo: string)
    begin
      AFormulario.ActualizarColumnasDinamicas(ACodigoArticulo);
    end;
  Callbacks.NumeroAtributosActual :=
    function: Integer
    begin
      Result := AFormulario.FGestorColumnas.NumAtributosActual;
    end;
  Callbacks.EscribirUnidad :=
    procedure(const ACodigoUnidad: string)
    begin
      AFormulario.dmmInventarios.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_INVLIN').AsString := ACodigoUnidad;
    end;
  Callbacks.CargarStock :=
    procedure(const ACodigoUnidad: string)
    var
      CantidadTeorica: Currency;
      PrecioMedio: Currency;
    begin
      AFormulario.dmmInventarios.RellenarDatosSku(
        ACodigoUnidad,
        CantidadTeorica,
        PrecioMedio);
      EscribirStockLineaInventario(
        AFormulario.dmmInventarios.cdsLineas,
        ACodigoUnidad,
        CantidadTeorica,
        PrecioMedio);
      AFormulario.dmmInventarios.AsegurarFechaRecuentoLinea;
    end;
  Callbacks.RellenarAtributos :=
    procedure(const ACodigoSku: string)
    begin
      AFormulario.RellenarAtributosDesdeSku(ACodigoSku);
    end;
  Operaciones := TAdaptadorEntradaInventarioVcl.Create(Callbacks);
  AFormulario.FDependencias.AplicacionEntrada :=
    CrearAplicacionEntradaInventario(
    AValidador,
    Operaciones);
end;

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
  FRepositoriosArticulos := ObtenerCompositorArticulosPantalla(Self).
    CrearRepositoriosArticulosPantalla(Name);
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
  // El gestor de columnas ya puede leer lineas y definicion de atributos.
  FGestorColumnas.EstablecerOrigen(
    dmmInventarios.cdsLineas,
    CrearLookupAtributosInventario(
      function(const ACodigoArticulo: string): TArray<string>
      begin
        Result := NombresAtributosArticulo(ACodigoArticulo);
      end));
  FDependencias.Busquedas :=
    CrearBusquedasInventarioUniDAC(ConexionPrincipal);
  FDependencias.RecuentoRemoto :=
    CrearRepositorioRecuentoRemotoInventarioUniDAC(ConexionPrincipal);
  InicializarEntradaInventarioVcl(
    Self,
    FRepositoriosArticulos.CrearValidadorArticulos(ConexionPrincipal));
end;

procedure TfrmMtoInventarios.FormCreate(Sender: TObject);
var
  ColumnasSku: TColumnasSkuInventario;
begin
  ColumnasSku[1] := tvLineasSKU1;
  ColumnasSku[2] := tvLineasSKU2;
  ColumnasSku[3] := tvLineasSKU3;
  ColumnasSku[4] := tvLineasSKU4;
  ColumnasSku[5] := tvLineasSKU5;
  // Por defecto el gestor arranca sin atributos visibles: abrir un
  // inventario solo lee las lineas, sin consultar la definicion de
  // atributos ni desempaquetar SKU->ATTR1..5 (un Edit/Post por linea).
  FGestorColumnas := TGestorColumnasAtributosInventario.Create(
    tvLineas, ColumnasSku, tvLineasARTICULO, tvLineasUNIDAD);
  inherited;
  FProcesandoAtributo := False;
  FInicializandoCombo := False;
  FRefrescandoLookupsCabecera := False;
  // Contrato de entrada (prueba ColumnSKUcxGrid): Auto por defecto
  // (resuelve a desglose) y F1 cicla Auto -> SKU. El toggle clasico
  // queda oculto: el modo lo gobierna el contrato.
  FModoEntradaSel := mcsAuto;
  chkVerColumnasAtributos.Visible := False;
  // 150 lineas es el umbral empirico: por debajo el desempaquetado va
  // imperceptible aunque haga un Edit/Post por linea (DisableControls
  // suprime el repintado del grid). Por encima, el usuario nota la
  // espera, asi que mostramos el overlay con progressbar marquee.
  FUmbralProgresoDesempaquetado := 150;
  FBmpSwatchBoton := TBitmap.Create;
  // El TcxCheckBox arranca unchecked desde el DFM, alineado con
  // el estado inicial del gestor. No tocamos .Checked aqui para
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
  if FGestorColumnas.MostrarAtributos then
    FGestorColumnas.AplicarModoEntrada(True)
  else
  begin
    FGestorColumnas.UltimoArticuloPadre := '__FORZAR__';
    ActualizarColumnasDinamicas('');
  end;
end;

procedure TfrmMtoInventarios.FormDestroy(Sender: TObject);
begin
  FDependencias := Default(TContextoDependenciasInventario);
  FRepositoriosArticulos := nil;
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
  FreeAndNil(FGestorColumnas);
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
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  // AsegurarCabeceraPersistidaParaLineas ya descarta data module nulo y
  // cabecera vacia o cerrada.
  if AsegurarCabeceraPersistidaParaLineas then
  begin
    dsLin := dmmInventarios.cdsLineas;
    sNumero := Trim(dmmInventarios.unqryTablaG.FieldByName(
      'NUMERO_INV').AsString);
    sSerie := Trim(dmmInventarios.unqryTablaG.FieldByName(
      'SERIE_INV').AsString);
    if (dsLin <> nil) and (sNumero <> '') and (sNumero <> '0') and
       (sSerie <> '') then
    begin
      if not dsLin.Active then
        CargarLineasYRefrescar;
      if dsLin.Active and dsLin.IsEmpty and PuedeEditar and
         (not (dsLin.State in [dsEdit, dsInsert])) then
        btnAnadirLineaClick(cxgrdLineas);
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
  bCabeceraLista: Boolean;
begin
  ds := dsTablaG.DataSet;
  if pcDetail.ActivePage = tsDetalle then
  begin
    // Cabecera sin grabar: se graba automaticamente porque las lineas
    // referencian (EMP/ALM/SERIE/NRO) y el numero definitivo lo asigna
    // unqryTablaGBeforePost desde fza_contadores.
    bCabeceraLista := True;
    if (ds <> nil) and ds.Active and (ds.State in [dsInsert, dsEdit]) then
    begin
      try
        ds.Post;
      except
        on E: Exception do
        begin
          bCabeceraLista := False;
          ShowMessage(Format(
            SErrorGrabarCabeceraInventarioAutomaticamenteDetalle,
            [E.Message]));
          pcDetail.ActivePage := tsCabecera;
        end;
      end;
    end;
    if bCabeceraLista then
      CargarLineasYRefrescar;
  end
  else if pcDetail.ActivePage = tsMovsRegul then
  begin
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
      dmmInventarios.SetClavesActivas(
        ds.FieldByName('CODIGO_EMP_INV').AsString,
        ds.FieldByName('CODIGO_ALM_INV').AsString,
        ds.FieldByName('SERIE_INV').AsString,
        ds.FieldByName('NUMERO_INV').AsString);
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
begin
  // Con el inventario APLICADO o CANCELADO el grid es solo lectura.
  HabilitarEdicionLineas(PuedeEditar);
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
  FGestorColumnas.VistaAplicada := False;
  if dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
  begin
    // CargarLineasInventario ha reseteado LineasDesempaquetadas. Si el
    // usuario tiene el toggle activo, hay que volver a desempaquetar
    // antes de pintar las columnas (con barra de progreso si >150 lineas).
    if FGestorColumnas.MostrarAtributos and
       (not dmmInventarios.LineasDesempaquetadas) then
      AsegurarDesempaquetadoAtributos;
    // El ultimo padre puede coincidir con el de la cabecera anterior;
    // lo limpiamos para forzar la reconstruccion de captions.
    FGestorColumnas.UltimoArticuloPadre := '';
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
  // Conversion en marcha: BeforePost no debe exigir SKU cerrado a los
  // Posts intermedios del pivote/des-pivote (lineas consolidadas o
  // con unidad=padre).
  dmmInventarios.ModoPivoteActivo := True;
  DesmontarModoEntradaDocumento(tvLineas,
    dmmInventarios.cdsLineas, FModoEntrada);
  // Desglose ensenya atributos: desempaquetar SKU->ATTR ahora Y en
  // cada recarga de lineas (DesempaquetarAlCargar: las recargas del
  // data module que no pasan por el form barrian los ATTR in-memory
  // y los atributos se veian en blanco hasta reconstruir).
  FGestorColumnas.MostrarAtributos :=
    MuestraAtributosEnModoInventario(FModoEntradaSel);
  dmmInventarios.DesempaquetarAlCargar :=
    DesempaquetarAlCargarEnModoInventario(FModoEntradaSel);
  if FGestorColumnas.MostrarAtributos then
    AsegurarDesempaquetadoAtributos;
  Cfg := CrearConfigColumnasSkuDocumento(
    CrearServiciosColumnasSkuUniDAC(ConexionPrincipal),
    ContextoSesion, tvLineas,
    dmmInventarios.cdsLineas, FModoEntradaSel,
    dsTablaG.DataSet.FieldByName(
      'CODIGO_ALM_INV').AsString, 'INVLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos :=
    FRepositoriosArticulos.CrearValidadorArticulos(ConexionPrincipal);
  Cfg.LookupAtributos :=
    FRepositoriosArticulos.CrearLookupAtributosArticulos(
      ConexionPrincipal);
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
  FGestorColumnas.ContratoConstruido := True;
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
  tsDetalle.Caption := CaptionDetalleInventario(
    DetectarModoColumnasSku(Cfg));
  // Conversion terminada: el guardian de BeforePost vuelve a aplicar.
  dmmInventarios.ModoPivoteActivo := False;
  if PuedeEditar then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoInventarios.CrearColumnasHostInventario;
begin
  // Columnas propias del documento tras el ClearItems del contrato
  // (equivalente runtime de las del dfm; LOTE/CADUCIDAD/USUARIO, que
  // iban ocultas, quedan fuera de la prueba).
  CrearColumnasDocumentoInventario(
    tvLineas, tvLineasUdsFisicasPropertiesValidate);
end;

procedure TfrmMtoInventarios.MostrarColumnasAtributoGlobales;
begin
  MostrarColumnasAtributoGlobalesDocumento(
    ConexionPrincipal, tvLineas);
  // Las columnas de atributo del contrato nacen con el ancho por defecto
  // y AZUL_CIELO quedaba ilegible: el gestor las ensancha segun el valor
  // mas largo cargado, sin pisar anchos tocados a mano.
  FGestorColumnas.AjustarAnchosAtributos(cxgrdLineas.Font);
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
    EscribirStockLineaInventario(
      dmmInventarios.cdsLineas, ASku, CantTeo, PMPAct);
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

function TfrmMtoInventarios.NombresAtributosArticulo(
  const ACodigoArticulo: string): TArray<string>;
var
  iNombre: Integer;
begin
  // Unico punto de la pantalla que recorre la definicion de atributos.
  SetLength(Result, 0);
  if (dmmInventarios <> nil) and (Trim(ACodigoArticulo) <> '') then
  begin
    dmmInventarios.unqryDefinicionArticulo.Close;
    dmmInventarios.unqryDefinicionArticulo.ParamByName(
      'ARTICULO').AsString := ACodigoArticulo;
    dmmInventarios.unqryDefinicionArticulo.Open;
    while not dmmInventarios.unqryDefinicionArticulo.Eof do
    begin
      iNombre := Length(Result);
      SetLength(Result, iNombre + 1);
      Result[iNombre] :=
        dmmInventarios.unqryDefinicionArticulo.FieldByName(
          'NOMBRE_ATRIBUTO').AsString;
      dmmInventarios.unqryDefinicionArticulo.Next;
    end;
  end;
end;

function TfrmMtoInventarios.ContextoEscrituraAtributo:
  TEscrituraAtributoInventario;
begin
  Result.Lineas := dmmInventarios.cdsLineas;
  Result.GenerarSku :=
    function(const ACodigoArticulo: string): string
    begin
      Result := dmmInventarios.GenerarSkuFinal(ACodigoArticulo);
    end;
  Result.RellenarStock :=
    procedure(const ACodigoUnidad: string)
    var
      CantidadTeorica: Currency;
      PrecioMedio: Currency;
    begin
      dmmInventarios.RellenarDatosSku(
        ACodigoUnidad, CantidadTeorica, PrecioMedio);
      EscribirStockLineaInventario(
        dmmInventarios.cdsLineas, ACodigoUnidad,
        CantidadTeorica, PrecioMedio);
      dmmInventarios.AsegurarFechaRecuentoLinea;
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
begin
  // Toda la decision (contrato activo, memoizacion por articulo padre,
  // columnas del articulo o de la vista) vive en el gestor de columnas.
  FGestorColumnas.Actualizar(ArticuloPadre);
end;

procedure TfrmMtoInventarios.AsegurarDesempaquetadoAtributos;
var
  HayMuchasLineas: Boolean;
begin
  // No se toca el cds en edicion: el bucle Edit/Post por linea
  // corromperia el estado y haria saltar "RecordIndex out of range" en el
  // tvLineas al siguiente Append. El data module ya corto-circuita si el
  // desempaquetado esta hecho; se filtra aqui para no mostrar el overlay.
  if (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) and
     (not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert])) and
     (not dmmInventarios.LineasDesempaquetadas) then
  begin
    HayMuchasLineas := dmmInventarios.cdsLineas.RecordCount >
      FUmbralProgresoDesempaquetado;
    if HayMuchasLineas then
      BloquearTabPorOcupado(True);
    try
      dmmInventarios.DesempaquetarAtributosDesdeSku;
    finally
      if HayMuchasLineas then
        BloquearTabPorOcupado(False);
    end;
  end;
end;

procedure TfrmMtoInventarios.chkVerColumnasAtributosPropertiesChange(
  Sender: TObject);
var
  CodArt: string;
begin
  // Sincroniza el gestor con la checkbox y refresca las columnas. Al
  // activarse desempaqueta antes SKU->ATTR (con barra de progreso si hay
  // muchas lineas); al desactivarse solo oculta, sin tocar la BBDD.
  // Con el contrato activo el modo lo gobierna F1 y el check no aplica.
  if (not (csLoading in ComponentState)) and
     (not FGestorColumnas.ContratoConstruido) then
  begin
    FGestorColumnas.MostrarAtributos := chkVerColumnasAtributos.Checked;
    // Conmuta ya la columna de entrada aunque el inventario este vacio:
    // Actualizar puede cortocircuitar por memoizacion sin articulo padre.
    FGestorColumnas.AplicarModoEntrada(FGestorColumnas.MostrarAtributos);
    if FGestorColumnas.MostrarAtributos then
      AsegurarDesempaquetadoAtributos;
    // Forzar el rebuild ignorando la memoizacion del ultimo padre.
    FGestorColumnas.UltimoArticuloPadre := '';
    FGestorColumnas.VistaAplicada := False;
    CodArt := '';
    if (dmmInventarios <> nil) and
       dmmInventarios.cdsLineas.Active and
       not dmmInventarios.cdsLineas.IsEmpty then
      CodArt := dmmInventarios.cdsLineas.FieldByName(
        'CODIGO_ART_INVLIN').AsString;
    ActualizarColumnasDinamicas(CodArt);
  end;
end;

procedure TfrmMtoInventarios.RellenarAtributosDesdeSku(const Sku: string);
begin
  // Los valores del SKU van a ATTR1..ATTR5 mapeados por
  // ORDEN_VISUAL_ATRIBUTO (= ORDEN_VA del atributo).
  RellenarAtributosDesdeSkuInventario(
    FRepositoriosArticulos.CrearLookupAtributosArticulos(
      ConexionPrincipal),
    dmmInventarios.cdsLineas, Sku);
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
begin
  // Columnas SKU1..SKU5: glyph con el cuadradito del color del AV actual
  // y apertura automatica del selector cuando la celda esta vacia.
  ConfigurarEditorAtributoInventario(
    ConexionPrincipal, dmmInventarios.cdsLineas, AItem.Tag,
    AEdit, FBmpSwatchBoton, AbrirPopupSkuEnEntrada);
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
  if (Key = VK_RETURN) and (AItem.Tag >= 1) and
     (AItem.Tag <= MAX_ATRIBUTOS_INVENTARIO) and
     (AEdit is TcxComboBox) then
  begin
    Combo := TcxComboBox(AEdit);
    if (Combo.ItemIndex = -1) and (Trim(Combo.Text) = '') and
       (Combo.Properties.Items.Count > 0) then
      Combo.ItemIndex := 0;
    if Combo.DroppedDown then
      Combo.DroppedDown := False;
    Combo.PostEditValue;
  end;
end;

procedure TfrmMtoInventarios.ForzarDespliegue(Sender: TObject);
var
  Combo: TcxComboBox;
begin
  // El guard FInicializandoCombo evita que OnAtributoChanged recalcule
  // un SKU intermedio antes de que el usuario confirme.
  if Sender is TcxComboBox then
  begin
    Combo := TcxComboBox(Sender);
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
end;

procedure TfrmMtoInventarios.OnAtributoChanged(Sender: TObject);
var
  Edit: TcxCustomEdit;
  ColIdx: Integer;
begin
  // Al elegir un valor en una columna de atributo se reconstruye el SKU
  // (CODIGO_ART/ATTR1/ATTR2/...). Si el SKU queda cerrado, la
  // reconstruccion recalcula teorico y PMP de la linea.
  if (not FInicializandoCombo) and (not FProcesandoAtributo) and
     (Sender is TcxCustomEdit) and
     dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) then
  begin
    Edit := TcxCustomEdit(Sender);
    // El TcxComboBox del cxGrid puede disparar OnEditValueChanged con el
    // dataset en dsBrowse: forzamos la transicion a dsEdit.
    if dmmInventarios.cdsLineas.State = dsBrowse then
      dmmInventarios.cdsLineas.Edit;
    if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      Edit.PostEditValue;
      // Defensa: la DataLink no siempre sincroniza ATTRn_VALOR antes de
      // que se lea para generar el SKU.
      if Edit is TcxComboBox then
      begin
        ColIdx := TcxComboBox(Edit).Tag;
        if (ColIdx >= 1) and (ColIdx <= MAX_ATRIBUTOS_INVENTARIO) then
          dmmInventarios.cdsLineas.FieldByName(
            'ATTR' + IntToStr(ColIdx) + '_VALOR').AsString :=
            VarToStr(TcxComboBox(Edit).EditValue);
      end;
      ReconstruirSkuLineaInventario(ContextoEscrituraAtributo);
    end;
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

      if FGestorColumnas.MostrarAtributos and
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
  if CodArticulo <> '' then
  begin
    dmmInventarios.RellenarDatosArticulo(
      CodArticulo, Descripcion, NumAtr, TipoArt);
    Error := Descripcion = '';
    if Error then
      ErrorText := SErrorArticuloInventarioNoExiste
    else
      EscribirArticuloValidadoLinea(CodArticulo, Descripcion, NumAtr);
  end;
end;

procedure TfrmMtoInventarios.EscribirArticuloValidadoLinea(
  const ACodigoArticulo, ADescripcion: string; ANumAtributos: Integer);
var
  CantTeo, PMPAct: Currency;
begin
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;
  EscribirArticuloLineaInventario(
    dmmInventarios.cdsLineas, ACodigoArticulo, ADescripcion);
  dmmInventarios.cdsLineas.FieldByName(
    'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := ANumAtributos;
  // Refrescar columnas SKU dinamicas del articulo resuelto.
  ActualizarColumnasDinamicas(ACodigoArticulo);
  // Sin atributos (articulo sin SKUs) el SKU es el codigo de articulo y
  // las teoricas y el PMP se rellenan directamente.
  if ANumAtributos = 0 then
  begin
    dmmInventarios.RellenarDatosSku(ACodigoArticulo, CantTeo, PMPAct);
    EscribirStockLineaInventario(
      dmmInventarios.cdsLineas, ACodigoArticulo, CantTeo, PMPAct);
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Input, Resolved: string;
begin
  Error := False;
  Input := Trim(VarToStr(DisplayValue));
  Resolved := Input;
  if Input <> '' then
    RellenarLineaDesdeBusqueda(Input, Resolved, Error, ErrorText);
  if (Input <> '') and (not Error) then
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

procedure TfrmMtoInventarios.tvLineasSkuPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Col: TcxGridColumn;
  Orden: Integer;
  Avs: TArray<string>;
  AvNuevo: string;
begin
  Orden := 0;
  Col := tvLineas.Controller.FocusedColumn;
  if Col <> nil then
    Orden := Col.Tag;
  if not PuedeEditar then
    ShowMessage(SErrorInventarioNoAbiertoEditar)
  else if (Orden >= 1) and (Orden <= MAX_ATRIBUTOS_INVENTARIO) and
          dmmInventarios.cdsLineas.Active and
          (not dmmInventarios.cdsLineas.IsEmpty) then
  begin
    Avs := ValoresAtributoInventario(
      FRepositoriosArticulos.CrearLookupAtributosArticulos(
        ConexionPrincipal),
      dmmInventarios.cdsLineas.FieldByName(
        'CODIGO_ART_INVLIN').AsString, Orden);
    if Length(Avs) = 0 then
      ShowMessage(SErrorValoresAtributoNoDefinidos)
    else if SeleccionarValorAtributoInventario(
              ConexionPrincipal, dmmInventarios.cdsLineas, Orden,
              Avs, Sender, AvNuevo) then
    begin
      EscribirValorAtributoInventario(
        ContextoEscrituraAtributo, Orden, AvNuevo);
      // Reflejamos el valor en el editor para que la celda muestre el AV
      // elegido al instante, sin esperar al refresh de la DataLink.
      if Sender is TcxCustomEdit then
        TcxCustomEdit(Sender).EditValue := AvNuevo;
    end;
  end;
end;

procedure TfrmMtoInventarios.AbrirPopupSkuEnEntrada(Sender: TObject);
begin
  // OnEnter single-shot: abre el selector al entrar en la celda.
  if Sender is TcxCustomEdit then
  begin
    TcxCustomEdit(Sender).OnEnter := nil;
    tvLineasSkuPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesButtonClick(
  Sender: TObject;
  AButtonIndex: Integer);
var
  Codigo, Resolved, Almacen: string;
  ErrText: TCaption;
  Err: Boolean;
begin
  Almacen := '';
  if dmmInventarios <> nil then
    Almacen := dmmInventarios.CodigoAlmacen;
  if FGestorColumnas.MostrarAtributos then
    Codigo := BuscarArticuloInventario(
      FDependencias.Busquedas, BusquedaVisual, nil)
  else
    Codigo := BuscarSkuInventario(
      FDependencias.Busquedas, BusquedaVisual, Almacen, Self);
  if Codigo <> '' then
  begin
    Resolved := Codigo;
    Err := False;
    ErrText := '';
    RellenarLineaDesdeBusqueda(Codigo, Resolved, Err, ErrText);
    if Err then
      ShowMessage(ErrText)
    else
    begin
      // La celda Articulo muestra el codigo de articulo; la unificada, el
      // SKU resuelto.
      if Sender is TcxCustomEdit then
      begin
        if (tvLineas.Controller.FocusedColumn = tvLineasARTICULO) and
           Assigned(dmmInventarios) then
          TcxCustomEdit(Sender).EditValue :=
            dmmInventarios.cdsLineas.FieldByName(
              'CODIGO_ART_INVLIN').AsString
        else
          TcxCustomEdit(Sender).EditValue := Resolved;
      end;
      // Con variaciones movemos el foco al primer atributo dinamico para
      // que el usuario elija Color/Talla directamente.
      if (dmmInventarios.cdsLineas.FieldByName(
            'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger > 0) and
         Assigned(tvLineasSKU1) and tvLineasSKU1.Visible then
      begin
        tvLineas.Controller.FocusedColumn := tvLineasSKU1;
        if tvLineas.Controller.EditingController <> nil then
          tvLineas.Controller.EditingController.ShowEdit;
      end;
    end;
  end;
end;

procedure TfrmMtoInventarios.RellenarLineaDesdeBusqueda(
  const AInput: string;
  var AResolvedValue: string;
  var AError: Boolean;
  var AErrorText: TCaption);
var
  Resultado: TResultadoEntradaInventario;
  Cronometro: TStopwatch;
begin
  Cronometro := TStopwatch.StartNew;
  Resultado := FDependencias.AplicacionEntrada.Procesar(AInput);
  AResolvedValue := Resultado.CodigoUnidad;
  AError := Resultado.Error <> eeiNinguno;
  AErrorText := MensajeErrorEntradaInventario(Resultado);
  RegistroLog.RegistrarRendimiento('RellenarLineaDesdeBusqueda',
    Format(
      'input=%s padre=%s sku=%s unidad=%s error=%d',
      [AInput, Resultado.CodigoArticulo, Resultado.CodigoSku,
       Resultado.CodigoUnidad, Ord(Resultado.Error)]),
    Cronometro.ElapsedMilliseconds);
end;

procedure TfrmMtoInventarios.tvLineasUdsFisicasPropertiesValidate(
  Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Fis, Teo, PMPAct, PMPNue: Currency;
begin
  Error := False;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;
  Fis := StrToCurrDef(VarToStr(DisplayValue), 0);
  Teo := dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_TEORICA_INVLIN').AsCurrency;
  PMPAct := dmmInventarios.cdsLineas.FieldByName(
    'PRECIO_MEDIO_INVLIN').AsCurrency;
  PMPNue := dmmInventarios.cdsLineas.FieldByName(
    'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency;
  dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_DIFERENCIA_INVLIN').AsCurrency :=
    DiferenciaUnidadesInventario(Fis, Teo);
  dmmInventarios.cdsLineas.FieldByName(
    'TOTAL_COSTE_DIFERENCIA_INVLIN').AsCurrency :=
    DiferenciaCosteInventario(Fis, Teo, PMPNue, PMPAct);
  dmmInventarios.AsegurarFechaRecuentoLinea;
end;

procedure TfrmMtoInventarios.tvLineasGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
begin
  // Tooltip por campo: sigue vivo tras el ClearItems del contrato de
  // entrada, que destruye las columnas del dfm.
  if ACellViewInfo.Item is TcxGridDBColumn then
    AHintText := HintCeldaInventario(
      TcxGridDBColumn(ACellViewInfo.Item).DataBinding.FieldName);
end;

// ============================================================================
//   BOTONES DE PESTAÑA CABECERA
// ============================================================================

procedure TfrmMtoInventarios.btnRecalcularClick(Sender: TObject);
begin
  if MessageDlg(SPreguntaRecalcularInventario,
       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      dmmInventarios.RecalcularTeorico;
      ShowMessage(SInfoRecalculoInventario);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoInventarios.RefrescarTrasAplicarInventario;
begin
  try
    dmmInventarios.RefrescarTrasAplicar;
    ShowMessage(SInfoInventarioAplicado);
    pcDetail.ActivePage := tsMovsRegul;
  except
    on E: Exception do
      ShowMessage(Format(SErrorRefrescarInventarioAplicado,
        [E.Message]));
  end;
end;

procedure TfrmMtoInventarios.btnAplicarClick(Sender: TObject);
var
  bAplicable: Boolean;
begin
  // El regularizar se parte en tres tramos: (1) validacion aqui, en el
  // hilo principal porque toca el grid de lineas; (2) SP en background,
  // solo BBDD; (3) recarga de grids en el callback del hilo principal.
  bAplicable := MessageDlg(SPreguntaAplicarInventario,
    mtWarning, [mbYes, mbNo], 0) = mrYes;
  if bAplicable then
  begin
    try
      dmmInventarios.PreAplicarValidaciones;
    except
      on E: Exception do
      begin
        bAplicable := False;
        ShowMessage(Format(SErrorAplicarInventario, [E.Message]));
      end;
    end;
  end;
  if bAplicable then
    EjecutarEnBackground(
      procedure
      begin
        dmmInventarios.EjecutarSPAplicar;
      end,
      procedure(ErrMsg: string)
      begin
        if ErrMsg <> '' then
          ShowMessage(Format(SErrorAplicacionInventario, [ErrMsg]))
        else
          RefrescarTrasAplicarInventario;
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
  // Foco en la columna de entrada activa tras insertar la linea.
  tvLineas.Controller.FocusedColumn :=
    FGestorColumnas.ColumnaEntradaActiva;
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
  // Sin poder editar (cabecera no ABIERTO, dsTablaG vacio...) el boton
  // quedaba en salida silenciosa: damos feedback explicito.
  Estado := EstadoActual;
  if not PuedeEditar then
  begin
    if Estado = '' then
      ShowMessage(SErrorInventarioNoSeleccionadoAnadirLineas)
    else
      ShowMessage(Format(SErrorAnadirLineasInventarioEstado, [Estado]));
  end
  else
  begin
    // 1. Resolver el estado de edicion ANTES de tocar nada mas: si la
    // linea actual es un placeholder sin articulo se cancela para no
    // arrastrarla, y el cds queda en browse (seguro de recorrer).
    if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      if Trim(dmmInventarios.cdsLineas.FieldByName(
                'CODIGO_ART_INVLIN').AsString) = '' then
        dmmInventarios.cdsLineas.Cancel
      else
        dmmInventarios.cdsLineas.Post;
    end;
    // 2. Respetamos el modo elegido: en modo SKU los atributos siguen
    // ocultos y para editar por Color/Talla se activa el check.
    if not FGestorColumnas.MostrarAtributos then
    begin
      FGestorColumnas.UltimoArticuloPadre := '__FORZAR__';
      ActualizarColumnasDinamicas('');
    end;
    // 3. Anadir la nueva linea y enfocar la columna de entrada activa.
    dmmInventarios.cdsLineas.Append;
    tvLineas.Controller.FocusedColumn :=
      FGestorColumnas.ColumnaEntradaActiva;
    if tvLineas.Controller.EditingController <> nil then
      tvLineas.Controller.EditingController.ShowEdit;
  end;
end;

procedure TfrmMtoInventarios.btnAnadirSkusArtClick(Sender: TObject);
var
  CodigoArticulo: string;
  Insertados: Integer;
begin
  // El articulo se comprueba ANTES de postear: si la linea actual es un
  // placeholder sin articulo, el Post lanzaria cdsLineasBeforePost.
  CodigoArticulo := '';
  if not dmmInventarios.cdsLineas.IsEmpty then
    CodigoArticulo := Trim(dmmInventarios.cdsLineas.FieldByName(
      'CODIGO_ART_INVLIN').AsString);
  if PuedeEditar and dmmInventarios.cdsLineas.IsEmpty then
    ShowMessage(SErrorLineaInventarioNoSeleccionadaParaSkus)
  else if PuedeEditar and (CodigoArticulo = '') then
    ShowMessage(SErrorLineaInventarioSinArticulo)
  else if PuedeEditar then
  begin
    if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
      dmmInventarios.cdsLineas.Post;
    Screen.Cursor := crHourGlass;
    try
      Insertados := dmmInventarios.CargarSkusConMovimientosArticulo(
        CodigoArticulo);
    except
      on E: Exception do
      begin
        Insertados := -1;
        Screen.Cursor := crDefault;
        ShowMessage(Format(SErrorAnadirSkusInventario, [E.Message]));
      end;
    end;
    Screen.Cursor := crDefault;
    if Insertados = 0 then
      ShowMessage(Format(SInfoSinSkusAnadidosInventario, [CodigoArticulo]))
    else if Insertados > 0 then
      ShowMessage(Format(SInfoSkusAnadidosInventario,
        [Insertados, CodigoArticulo]));
  end;
end;

procedure TfrmMtoInventarios.btnEliminarLineaClick(Sender: TObject);
begin
  if PuedeEditar and (not dmmInventarios.cdsLineas.IsEmpty) and
     (MessageDlg(SPreguntaEliminarLineaInventario,
        mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
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
    ShowMessage(SErrorEliminarRegularizacionInventarioEstado)
  else if MessageDlg(SPreguntaEliminarRegularizacionInventario,
            mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      dmmInventarios.EliminarRegularizacion;
      ShowMessage(SInfoRegularizacionInventarioEliminada);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnExportarInvClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
begin
  if not PuedeExportar then
    Abort;
  if dmmInventarios.unqryTablaG.IsEmpty then
    ShowMessage(SErrorInventarioNoActivo)
  else
  begin
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
        fPreview.DialogoGuardar.FileName := 'Inventario_' +
          dmmInventarios.unqryTablaG.FieldByName('SERIE_INV').AsString +
          '_' +
          dmmInventarios.unqryTablaG.FieldByName('NUMERO_INV').AsString;
        ExportarInventarioExcel(fPreview.dxSpreadSheet1,
          dmmInventarios.unqryTablaG, dmmInventarios.cdsLineas);
      finally
        Screen.Cursor := crDefault;
      end;
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
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

procedure TfrmMtoInventarios.EjecutarCargaMasiva(const APregunta: string;
                                                 const ACarga: TProc);
begin
  // Guion comun de las cuatro cargas masivas: confirmar, ejecutar con el
  // cursor de espera y volver al detalle recargado.
  if MessageDlg(APregunta, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      ACarga();
      pcDetail.ActivePage := tsDetalle;
      CargarLineasYRefrescar;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnCargarPorFamiliaClick(Sender: TObject);
var
  Familia: string;
begin
  if not PuedeEditar then
    ShowMessage(SErrorInventarioDebeEstarAbierto)
  else
  begin
    Familia := dmmInventarios.unqryFamilias.FieldByName(
      'CODIGO_FAM_FAM').AsString;
    if Familia = '' then
      ShowMessage(SErrorFamiliaInventarioNoSeleccionada)
    else
      EjecutarCargaMasiva(
        Format(SPreguntaCargarFamiliaInventario, [Familia]),
        procedure
        begin
          dmmInventarios.CargarPorFamilia(Familia);
        end);
  end;
end;

procedure TfrmMtoInventarios.btnCargarPorProveedorClick(Sender: TObject);
var
  Proveedor: string;
begin
  if not PuedeEditar then
    ShowMessage(SErrorInventarioDebeEstarAbierto)
  else
  begin
    Proveedor := dmmInventarios.unqryProveedores.FieldByName(
      'CODIGO_PRV_PRV').AsString;
    if Proveedor = '' then
      ShowMessage(SErrorProveedorInventarioNoSeleccionado)
    else
      EjecutarCargaMasiva(
        Format(SPreguntaCargarProveedorInventario, [Proveedor]),
        procedure
        begin
          dmmInventarios.CargarPorProveedor(Proveedor);
        end);
  end;
end;

procedure TfrmMtoInventarios.btnCompletarClick(Sender: TObject);
begin
  if not PuedeEditar then
    ShowMessage(SErrorInventarioDebeEstarAbierto)
  else
    EjecutarCargaMasiva(SPreguntaCompletarInventario,
      procedure
      begin
        dmmInventarios.CompletarUnidadesNoLeidas;
      end);
end;

procedure TfrmMtoInventarios.btnCargarTodoClick(Sender: TObject);
begin
  if not PuedeEditar then
    ShowMessage(SErrorInventarioDebeEstarAbierto)
  else
    EjecutarCargaMasiva(SPreguntaCargarTodoInventario,
      procedure
      begin
        dmmInventarios.CargarTodosArticulosConStock;
      end);
end;

procedure TfrmMtoInventarios.edtRutaExcelPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  dlgAbrir.Filter := 'Archivos Excel (*.xlsx;*.xls)|*.xlsx;*.xls|' +
                     'Archivos CSV (*.csv;*.txt)|*.csv;*.txt|' +
                     'Todos|*.*';
end;

procedure TfrmMtoInventarios.btnCargarClick(Sender: TObject);
var
  res: TAddBlockInventarioResult;
  ds : TDataSet;
  bContinuar: Boolean;
begin
  ds := dsTablaG.DataSet;
  bContinuar := PuedeEditar and (ds <> nil) and (not ds.IsEmpty);
  if not PuedeEditar then
    ShowMessage(SErrorInventarioDebeEstarAbierto)
  else if (ds = nil) or ds.IsEmpty then
    ShowMessage(SErrorInventarioNoSeleccionado)
  else if ds.State in [dsInsert, dsEdit] then
  begin
    // Cabecera en edicion: se graba antes de abrir la modal del bloque.
    bContinuar := MessageDlg(SPreguntaGuardarInventarioEnEdicion,
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) = mrYes;
    if bContinuar then
      ds.Post;
  end;
  if bContinuar then
  begin
    res := TfrmModalAddBlockInventario.Ejecutar(Self,
      ds.FieldByName('CODIGO_EMP_INV').AsString,
      ds.FieldByName('CODIGO_ALM_INV').AsString,
      ds.FieldByName('SERIE_INV').AsString,
      ds.FieldByName('NUMERO_INV').AsString);
    if res.Aceptado then
    begin
      // Refrescar el grid de lineas y proponer recalcular.
      pcDetail.ActivePage := tsDetalle;
      CargarLineasYRefrescar;
      if MessageDlg(
           Format(SPreguntaRecalcularTrasCargarBloqueInventario,
             [res.NumLineas, res.NumArticulos]),
           mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        btnRecalcularDetalleClick(nil);
    end;
  end;
end;

function TfrmMtoInventarios.LeerFicheroRecuento(
  const AArchivo: string;
  out ALineas: TLineasImportacionInventario;
  out AMensaje: string): Boolean;
var
  Lista: TStringList;
  LineasExcel: TLineasImportadas;
  Textos: TArray<string>;
  Hoja: TdxSpreadSheet;
  iLinea: Integer;
begin
  // Lector del recuento: hoja de calculo con PMP o CSV "SKU;CANTIDAD".
  SetLength(ALineas, 0);
  AMensaje := '';
  Lista := nil;
  SetLength(LineasExcel, 0);
  try
    if SameText(ExtractFileExt(AArchivo), '.xlsx') or
       SameText(ExtractFileExt(AArchivo), '.xls') then
    begin
      Hoja := TdxSpreadSheet.Create(nil);
      try
        Hoja.LoadFromFile(AArchivo);
        ImportarInventarioDesdeSheet(CrearLectorDevEx(Hoja),
          LineasExcel, Lista, AMensaje);
      finally
        FreeAndNil(Hoja);
      end;
      SetLength(ALineas, Length(LineasExcel));
      for iLinea := 0 to High(LineasExcel) do
      begin
        ALineas[iLinea].CodigoUnidad := LineasExcel[iLinea].Sku;
        ALineas[iLinea].Cantidad := LineasExcel[iLinea].Cantidad;
        ALineas[iLinea].PrecioMedioNuevo := LineasExcel[iLinea].PmpNuevo;
        ALineas[iLinea].TienePrecioMedio := LineasExcel[iLinea].TienePmp;
        ALineas[iLinea].TextoOriginal := '';
        if (Lista <> nil) and (iLinea < Lista.Count) then
          ALineas[iLinea].TextoOriginal := Lista[iLinea];
      end;
    end
    else
    begin
      Lista := TStringList.Create;
      Lista.LoadFromFile(AArchivo);
      SetLength(Textos, Lista.Count);
      for iLinea := 0 to Lista.Count - 1 do
        Textos[iLinea] := Lista[iLinea];
      ALineas := LeerLineasImportacionCsvInventario(Textos);
      AMensaje := Format(SInfoLineasCsvInventarioLeidas, [Lista.Count]);
    end;
    Result := (Lista <> nil) and (Lista.Count > 0);
  finally
    FreeAndNil(Lista);
  end;
end;

procedure TfrmMtoInventarios.ImportarRecuentoEnLineas(
  const ALineas: TLineasImportacionInventario;
  const AMensaje: string);
var
  ListaNuevos: TStringList;
  Resumen: TResumenImportacionInventario;
begin
  // Existentes: actualizar cantidad y PMP. Nuevos: insertar via DM.
  Screen.Cursor := crHourGlass;
  ListaNuevos := TStringList.Create;
  try
    dmmInventarios.cdsLineas.DisableControls;
    try
      Resumen := AplicarImportacionInventario(
        ALineas,
        CrearOperacionesImportacionInventario(
          dmmInventarios.cdsLineas, ListaNuevos,
          procedure
          begin
            dmmInventarios.AsegurarFechaRecuentoLinea;
          end,
          procedure
          begin
            dmmInventarios.cdsLineas.ApplyUpdates(0);
          end));
    finally
      dmmInventarios.cdsLineas.EnableControls;
    end;
    if ListaNuevos.Count > 0 then
      dmmInventarios.CargarDesdeListaSkus(ListaNuevos);
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
    ShowMessage(Format(SInfoImportacionInventario,
      [AMensaje, Resumen.Actualizadas, Resumen.Nuevas]));
  finally
    Screen.Cursor := crDefault;
    FreeAndNil(ListaNuevos);
  end;
end;

procedure TfrmMtoInventarios.btnCargarExcelClick(Sender: TObject);
var
  Lineas: TLineasImportacionInventario;
  sMsg: string;
begin
  dlgAbrir.Filter :=
    'Excel (*.xlsx)|*.xlsx|CSV (*.csv;*.txt)|*.csv;*.txt|Todos (*.*)|*.*';
  dlgAbrir.DefaultExt := 'xlsx';
  if not PuedeEditar then
    ShowMessage(SErrorInventarioDebeEstarAbierto)
  else if dlgAbrir.Execute then
  begin
    if not FileExists(dlgAbrir.FileName) then
      ShowMessage(SErrorArchivoImportacionInventarioNoExiste)
    else if LeerFicheroRecuento(dlgAbrir.FileName, Lineas, sMsg) then
      ImportarRecuentoEnLineas(Lineas, sMsg)
    else if sMsg <> '' then
      ShowMessage(sMsg)
    else
      ShowMessage(SErrorImportacionInventarioSinDatos);
  end;
end;

// ============================================================================
//   RECUENTO REMOTO CON LA APP (servidor PHP, ver inLibInventarioNube)
// ============================================================================

function TfrmMtoInventarios.ClaveInventarioActual: TClaveInventario;
begin
  Result.Empresa := dmmInventarios.unqryTablaG.FieldByName(
    'CODIGO_EMP_INV').AsString;
  Result.Almacen := dmmInventarios.unqryTablaG.FieldByName(
    'CODIGO_ALM_INV').AsString;
  Result.Serie := dmmInventarios.unqryTablaG.FieldByName(
    'SERIE_INV').AsString;
  Result.Numero := dmmInventarios.unqryTablaG.FieldByName(
    'NUMERO_INV').AsString;
end;

procedure TfrmMtoInventarios.btnEnviarRecuentoClick(Sender: TObject);
var
  Clave: TClaveInventario;
  sDesc, sMsg: string;
  idRec: Int64;
begin
  if dmmInventarios.unqryTablaG.IsEmpty then
    ShowMessage(SErrorInventarioNoActivo)
  else if dmmInventarios.unqryTablaG.FieldByName(
            'ESTADO_INV').AsString <> 'ABIERTO' then
    ShowMessage(SErrorEnviarRecuentoInventarioNoAbierto)
  else if ComprobarRecuentoRemotoDisponible and
          (MessageDlg(SPreguntaEnviarRecuentoInventario,
             mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    Clave := ClaveInventarioActual;
    sDesc := dmmInventarios.unqryTablaG.FieldByName(
      'DESCRIPCION_INV').AsString;
    Screen.Cursor := crHourGlass;
    try
      if EnviarInventario(ParametrosApp, ConexionPrincipal,
           Clave.Empresa, Clave.Almacen, Clave.Serie, Clave.Numero,
           sDesc, 'DIRIGIDO', idRec, sMsg) then
      begin
        FDependencias.RecuentoRemoto.MarcarEnviado(Clave, idRec);
        dmmInventarios.unqryTablaG.Refresh;
        ShowMessage(Format(SInfoInventarioEnviadoRecuento, [idRec]));
      end
      else
        ShowMessage(Format(SErrorEnviarRecuentoInventario, [sMsg]));
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnRecogerRecuentoClick(Sender: TObject);
var
  Clave: TClaveInventario;
  sMsg: string;
  idRec: Int64;
  Lista: TStringList;
  iNumEv: Integer;
  bSeguir: Boolean;
begin
  // ID_RECUENTO_REMOTO_INV solo se lee tras comprobar que la migracion
  // del recuento remoto esta aplicada: si no, la columna no existe.
  idRec := 0;
  bSeguir := not dmmInventarios.unqryTablaG.IsEmpty;
  if not bSeguir then
    ShowMessage(SErrorInventarioNoActivo)
  else
    bSeguir := ComprobarRecuentoRemotoDisponible;
  if bSeguir then
    idRec := StrToInt64Def(dmmInventarios.unqryTablaG.FieldByName(
      'ID_RECUENTO_REMOTO_INV').AsString, 0);
  if bSeguir and (idRec <= 0) then
  begin
    bSeguir := False;
    ShowMessage(SErrorInventarioNoEnviadoRecuento);
  end;
  if bSeguir and (dmmInventarios.unqryTablaG.FieldByName(
       'ESTADO_INV').AsString <> 'ABIERTO') then
  begin
    bSeguir := False;
    ShowMessage(SErrorRecogerRecuentoInventarioNoAbierto);
  end;
  if bSeguir then
  begin
    Clave := ClaveInventarioActual;
    Screen.Cursor := crHourGlass;
    Lista := TStringList.Create;
    try
      if RecogerRecuento(ParametrosApp, ConexionPrincipal,
           Clave.Empresa, Clave.Almacen, Clave.Serie, Clave.Numero,
           IdentidadSesion.Usuario, idRec, Lista, iNumEv, sMsg) then
      begin
        // Volcamos el agregado SKU=CANTIDAD a las fisicas, como el Excel.
        if Lista.Count > 0 then
          dmmInventarios.CargarDesdeListaSkus(Lista);
        FDependencias.RecuentoRemoto.MarcarRecogido(Clave);
        dmmInventarios.CargarLineasInventario;
        // Igual que en la carga masiva: forzamos el refresco del grid
        // para ver las lecturas recogidas sin salir y volver a entrar.
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
end;

initialization
  RegistrarPantalla(TfrmMtoInventarios);
  ForceReferenceToClass(TfrmMtoInventarios);

end.
