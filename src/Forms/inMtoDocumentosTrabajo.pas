{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDocumentosTrabajo                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de Documentos de Trabajo.                                   }
{******************************************************************************}
unit inMtoDocumentosTrabajo;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Types, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoGen, dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  Vcl.StdCtrls, cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls,
  cxSplitter, cxCurrencyEdit, cxCalendar, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, cxListView, cxMaskEdit,
  cxDropDownEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, UniDataDocumentosTrabajo,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridTallasInline,
  inLibArticulosAtributosIntf, inLibArticulosValidadorIntf,
  inLibComprasPantallaIntf, inLibDocumentosTrabajo,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibPermisosIntf,
  UniDataComprasPantallaComposicion,
  inLibCajasDefectoPersistenciaIntf,
  inLibCajaVentanasIntf;

const
  NOMBRE_PANTALLA_DOCUMENTOS_TRABAJO = 'frmMtoDocumentosTrabajo';

type
  TTipoEnvioNumeradoDocumentoTrabajo = (
    tenFacturaVenta,
    tenPedidoCompra
  );
  TfrmMtoDocumentosTrabajo = class(TfrmMtoGen)
    pcAmbitoDTR: TcxPageControl;
    tsAmbitoPropiosDTR: TcxTabSheet;
    tsAmbitoCompartidosDTR: TcxTabSheet;
    colDtrId: TcxGridDBColumn;
    colDtrTitulo: TcxGridDBColumn;
    colDtrTipo: TcxGridDBColumn;
    colDtrEstado: TcxGridDBColumn;
    colDtrUsuario: TcxGridDBColumn;
    colDtrInstante: TcxGridDBColumn;
    colDtrEmpresa: TcxGridDBColumn;
    colDtrAlmacen: TcxGridDBColumn;
    splLineasDTR: TcxSplitter;
    pnlLineasDTR: TPanel;
    pnlAccionesDTR: TPanel;
    lblLineasDTR: TcxLabel;
    btnListadoDTR: TcxButton;
    btnCargarFiltrosDTR: TcxButton;
    btnCompartirDTR: TcxButton;
    btnImprimirEtiquetasDTR: TcxButton;
    pcDetalleDTR: TcxPageControl;
    tsLineasDTR: TcxTabSheet;
    tsCompartirDTR: TcxTabSheet;
    cxgrdLineasDTR: TcxGrid;
    tvLineasDTR: TcxGridDBTableView;
    colDtlLinea: TcxGridDBColumn;
    colDtlArticulo: TcxGridDBColumn;
    colDtlSku: TcxGridDBColumn;
    colDtlAlmacen: TcxGridDBColumn;
    colDtlDescripcionArticulo: TcxGridDBColumn;
    colDtlModelo: TcxGridDBColumn;
    colDtlFamilia: TcxGridDBColumn;
    colDtlProveedor: TcxGridDBColumn;
    colDtlTemporada: TcxGridDBColumn;
    colDtlDescripcionSku: TcxGridDBColumn;
    colDtlCantidadStock: TcxGridDBColumn;
    colDtlCantidad: TcxGridDBColumn;
    colDtlOrigen: TcxGridDBColumn;
    colDtlInstanteStock: TcxGridDBColumn;
    glLineasDTR: TcxGridLevel;
    cxgrdCompartidosDTR: TcxGrid;
    tvCompartidosDTR: TcxGridDBTableView;
    colDtcTipoDestino: TcxGridDBColumn;
    colDtcUsuarioGrupo: TcxGridDBColumn;
    colDtcPermiso: TcxGridDBColumn;
    colDtcAlta: TcxGridDBColumn;
    glCompartidosDTR: TcxGridLevel;
    btnEnviarADTR: TcxButton;
    pmEnviarDTR: TPopupMenu;
    miEnviarAlbaranDTR: TMenuItem;
    miEnviarFacturaVentaDTR: TMenuItem;
    miEnviarTpvDTR: TMenuItem;
    miEnviarPedidoCompraDTR: TMenuItem;
    miEnviarTraspasoCajaDTR: TMenuItem;
    miEnviarPeticionTraspasoDTR: TMenuItem;
    miEnviarInventarioDTR: TMenuItem;
    miEnviarTarifasDTR: TMenuItem;
    procedure btnEnviarADTRClick(Sender: TObject);
    procedure miEnviarAlbaranDTRClick(Sender: TObject);
    procedure miEnviarFacturaVentaDTRClick(Sender: TObject);
    procedure miEnviarTpvDTRClick(Sender: TObject);
    procedure miEnviarPedidoCompraDTRClick(Sender: TObject);
    procedure miEnviarTraspasoCajaDTRClick(Sender: TObject);
    procedure miEnviarPeticionTraspasoDTRClick(Sender: TObject);
    procedure miEnviarInventarioDTRClick(Sender: TObject);
    procedure miEnviarTarifasDTRClick(Sender: TObject);
    procedure btnListadoDTRClick(Sender: TObject);
    procedure btnCargarFiltrosDTRClick(Sender: TObject);
    procedure btnCompartirDTRClick(Sender: TObject);
    procedure btnImprimirEtiquetasDTRClick(Sender: TObject);
    procedure pcAmbitoDTRChange(Sender: TObject);
  private
    FIdEtiquetasDTR: Int64;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal. El
    // Construir hace ClearItems: las columnas del dfm mueren y las
    // propias se recrean en runtime (patron de inMtoInventarios).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
  protected
    FLecturasDocumentosTrabajo: ILecturasDocumentosTrabajo;
    FMaterializacionDocumentosTrabajo:
      IMaterializacionDocumentosTrabajo;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributos: IArticulosAtributosLookup;
    FRepositorioCajasDefecto: IRepositorioCajasDefecto;
    FCargaMasiva: TServiciosCargaMasivaArticulos;
  private
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostDTR;
    procedure MostrarColumnasAtributoGlobalesDTR;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure GridLineasEnterDTR(Sender: TObject);
    // "Enviar a...": comprueba documento grabado con lineas y deja los
    // posts hechos; devuelve el ID_DTR o 0 si no procede.
    function PrepararEnvio: Int64;
    function SeleccionarUbicacionCaja(
      out AEmpresa, AAlmacen, ACaja: string): Boolean;
    procedure ConfigurarEnvioNumerado(
      ATipo: TTipoEnvioNumeradoDocumentoTrabajo;
      out ATitulo, ATipoContador, AMensajeError,
      AMensajeCreado: string);
    function ResolverNumeroEnvio(
      const ASerie, ANumero, ATipoContador, AEmpresa,
      AMensajeError: string): string;
    procedure EnviarDocumentoNumerado(
      ATipo: TTipoEnvioNumeradoDocumentoTrabajo);
    function CrearLineasCargaTraspaso: TLineasCargaTraspaso;
    procedure AbrirTraspasoCaja(AModo: TModoVentanaTraspaso);
    procedure AplicarEstadoAmbito;
    procedure CargarAlmacenesEtiquetasDTR(ALV: TcxListView);
    procedure CrearDataSetEtiquetasDTR(ADmArt: TObject;
                                       const ACodTarifa,
                                             AAlmacenesCsv: string;
                                       AFecha: TDateTime);
  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmDocumentosTrabajo: TdmDocumentosTrabajo;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

function CrearDocumentosTrabajoCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDocumentosTrabajoPantalla;
  const ACajasDefecto: IRepositorioCajasDefecto): TForm;

implementation

uses
  UniDataArticulos, inLibFotos, inLibGenBusq, inMtoModalEtiqArt,
  inMtoModalAddBlockDocumentoTrabajo,
  // Factoria del contrato + IdentidadSesion.Usuario para el gestor de tallas.
  inLibColumnasSku,
  UniDataModoTallas, UniDataColumnasSkuServicios,
  // Modal de destino (almacen/serie/numero) del "Enviar a...".
  inMtoModalEnviarDestino, inMtoModalCajDef,
  // Listado del documento con una foto de 300 x 300 por línea.
  inMtoPreviewExcel, inLibDocumentosTrabajoExcel, inLibWin,
  inLibMsgArticulos, inLibMsgCaja, inLibMsgComun, inLibMsgVentas;

{$R *.dfm}

type
  TfrmMtoDocumentosTrabajoInyectada = class(TfrmMtoDocumentosTrabajo)
  private
    FComponer: TComponerDocumentosTrabajoPantalla;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const AComponer: TComponerDocumentosTrabajoPantalla;
      const ACajasDefecto: IRepositorioCajasDefecto); reintroduce;
    procedure CrearTablaPrincipal; override;
  end;

procedure ForceReferenceToClass(C: TClass);
begin
end;

function CrearDocumentosTrabajoCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDocumentosTrabajoPantalla;
  const ACajasDefecto: IRepositorioCajasDefecto): TForm;
begin
  Result := TfrmMtoDocumentosTrabajoInyectada.Create(
    AOwner,
    AContexto,
    AComponer,
    ACajasDefecto);
end;

constructor TfrmMtoDocumentosTrabajoInyectada.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDocumentosTrabajoPantalla;
  const ACajasDefecto: IRepositorioCajasDefecto);
begin
  if not Assigned(AComponer) then
    raise EArgumentNilException.Create('AComponer');
  if not Assigned(ACajasDefecto) then
    raise EArgumentNilException.Create('ACajasDefecto');
  FComponer := AComponer;
  FRepositorioCajasDefecto := ACajasDefecto;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoDocumentosTrabajoInyectada.CrearTablaPrincipal;
var
  oContexto: TContextoDocumentosTrabajoCompraPantalla;
begin
  inherited;
  FComponer(
    dmmDocumentosTrabajo.unqryTablaG.Connection,
    oContexto);
  FLecturasDocumentosTrabajo := oContexto.Lecturas;
  FMaterializacionDocumentosTrabajo := oContexto.Materializacion;
  FValidadorArticulos := oContexto.ValidadorArticulos;
  FLookupAtributos := oContexto.LookupAtributos;
  FCargaMasiva := oContexto.CargaMasiva;
  FComponer := nil;
end;

procedure TfrmMtoDocumentosTrabajo.CrearTablaPrincipal;
begin
  inherited;
  dmmDocumentosTrabajo := tdmDataModule as TdmDocumentosTrabajo;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsTablaG.DataSet := dmmDocumentosTrabajo.unqryTablaG;
    tvLineasDTR.DataController.DataSource := dmmDocumentosTrabajo.dsLineas;
    tvCompartidosDTR.DataController.DataSource :=
      dmmDocumentosTrabajo.dsCompartidos;
    AplicarEstadoAmbito;
  end;
  pkFieldName := 'ID_DTR';
  // Contrato de entrada: Auto por defecto; se construye al entrar en
  // el grid de lineas (las lineas abren en detail del master).
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  cxgrdLineasDTR.OnEnter := GridLineasEnterDTR;
  btnListadoDTR.Visible := PuedeExportar;
end;

destructor TfrmMtoDocumentosTrabajo.Destroy;
begin
  FCargaMasiva.Consultas := nil;
  FCargaMasiva.Inserciones := nil;
  FLookupAtributos := nil;
  FValidadorArticulos := nil;
  FMaterializacionDocumentosTrabajo := nil;
  FLecturasDocumentosTrabajo := nil;
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.GridLineasEnterDTR(Sender: TObject);
begin
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if (FModoEntrada <> nil) and
     (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.Ambito = dtaPropios) then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoDocumentosTrabajo.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  // F1: alterna Auto (desglose) -> SKU -> Tallas horizontal con las
  // lineas a la vista.
  if (Key = VK_F1) and (Shift = []) and
     (pcDetalleDTR.ActivePage = tsLineasDTR) then
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

procedure TfrmMtoDocumentosTrabajo.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgT: TGridTallasConfig;
  i: Integer;
  ds: TDataSet;
begin
  if (dmmDocumentosTrabajo <> nil) and
     not (csDestroying in ComponentState) then
  begin
    ds := dmmDocumentosTrabajo.unqryLineas;
    if ds.Active then
    begin
  // Teardown del modo anterior (patron inventarios).
  if tvLineasDTR.Controller.EditingController.IsEditing then
    try
      tvLineasDTR.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        // Ruido del editor inplace; queda constancia en el log.
        RegistroLog.RegistrarAviso(
          'DocumentosTrabajo.ConstruirModoEntrada: HideEdit ' +
          'ignorado: ' + E.Message);
    end;
  if ds.State in [dsEdit, dsInsert] then
    ds.Cancel;
  if FModoEntrada <> nil then
    FModoEntrada.Desmontar;
  tvLineasDTR.OnInitEdit := nil;
  tvLineasDTR.OnEditKeyDown := nil;
  tvLineasDTR.OnEditing := nil;
  tvLineasDTR.OnFocusedRecordChanged := nil;
  tvLineasDTR.OnFocusedItemChanged := nil;
  // Las columnas del modo saliente guardan handlers (OnGetProperties,
  // OnCustomDrawCell...) del objeto que se libera en la linea de abajo:
  // se eliminan ANTES de soltarlo para que ningun repintado llame a un
  // modo muerto (mismo AV que pedidos, 07/07/2026).
  tvLineasDTR.ClearItems;
  FModoEntrada := nil;
  // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
  // (columnas reales _DTL; idempotente por linea).
  if FModoEntradaSel <> mcsSku then
    dmmDocumentosTrabajo.DesempaquetarAtributosLineas;
  Cfg := Default(TConfigColumnasSku);
  Cfg.RegistroLog := RegistroLog;
  Cfg.Servicios := CrearServiciosColumnasSkuUniDAC(
    dmmDocumentosTrabajo.unqryTablaG.Connection);
  Cfg.ContextoSesion := ContextoSesion;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FValidadorArticulos;
  Cfg.LookupAtributos := FLookupAtributos;
  Cfg.View := tvLineasDTR;
  Cfg.Cds := ds;
  Cfg.Modo := FModoEntradaSel;
  Cfg.AlmacenStock :=
    dsTablaG.DataSet.FieldByName('CODIGO_ALM_DTR').AsString;
  Cfg.Distribuido := False;
  Cfg.Campos.CodigoArt := 'CODIGO_ART_DTL';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD_DTL';
  Cfg.Campos.Descripcion := 'DESCRIPCION_ARTICULO_DTL';
  Cfg.Campos.Cantidad := 'CANTIDAD_DTL';
  Cfg.Campos.Almacen := 'CODIGO_ALM_DTL';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_DTL';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR_DTL';
    Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE_DTL';
  end;
  if FModoEntradaSel = mcsTallasInline then
  begin
    CfgT := Default(TGridTallasConfig);
    CfgT.Conexion := dmmDocumentosTrabajo.unqryTablaG.Connection;
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasDTR;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmDocumentosTrabajo.dsLineas;
    // Clave SIMPLE del documento: ID_DTR hace de "serie" y el par
    // NUMERO queda vacio (soporte de numero opcional del gestor).
    CfgT.FieldSerieMaster := 'ID_DTR';
    CfgT.FieldNumeroMaster := '';
    CfgT.FieldLinea := 'LINEA_DTL';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_DTL';
    // Sin precio por linea: solo total de unidades (CANTIDAD_DTL).
    CfgT.FieldPrecioBase := '';
    CfgT.FieldTotalUds := 'CANTIDAD_DTL';
    CfgT.FieldTotalLinea := '';
    CfgT.TablaCeldas := 'fza_documentos_trabajo_celdas';
    CfgT.FieldSerieCel := 'ID_DTR_DTRCEL';
    CfgT.FieldNumeroCel := '';
    CfgT.FieldLineaCel := 'LINEA_DTRCEL';
    CfgT.FieldFilaCel := 'ID_FILA_DTRCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_DTRCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_DTRCEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := 20;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  // El flag ANTES del Construir: si aborta a medias, nadie debe tocar
  // las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  FModoEntrada.Construir(
    ModoEntradaResuelto,
    DesactivarEnterAsTabTemporal,
    RestaurarEnterAsTabTemporal);
  CrearColumnasHostDTR;
  case DetectarModoColumnasSku(Cfg) of
    mcsSku: tsLineasDTR.Caption := SCaptionLineasSku;
    mcsTallasInline:
      tsLineasDTR.Caption := SCaptionLineasTallasHoriz;
  else
    begin
      tsLineasDTR.Caption := SCaptionLineasDesglose;
      MostrarColumnasAtributoGlobalesDTR;
    end;
  end;
  // El guardian de ambito (solo propietario edita) se conserva.
  AplicarEstadoAmbito;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CrearColumnasHostDTR;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineasDTR.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
var
  Columna: TcxGridDBColumn;
begin
  // Columnas propias del documento tras el ClearItems del contrato.
  Col('Almacén', 'CODIGO_ALM_DTL', 70, True);
  Col('Descripción', 'DESCRIPCION_ARTICULO_DTL', 200, False);
  Col('Modelo', 'REF_PROVEEDOR', 120, False);
  Col('Familia', 'DESCRIPCION_FAM', 160, False);
  Col('Proveedor', 'NOMBRE_PRV', 180, False);
  Col('Temporada', 'TEMPORADA_ART', 110, False);
  Columna := Col('Stock', 'CANTIDAD_STOCK_DTL', 80, False);
  Columna.HeaderAlignmentHorz := taRightJustify;
  Columna := Col('Cantidad', 'CANTIDAD_DTL', 80,
    FModoEntradaSel <> mcsTallasInline);
  Columna.HeaderAlignmentHorz := taRightJustify;
  Col('Origen', 'ORIGEN_DTL', 80, False);
  Col('Instante stock', 'INSTANTE_STOCK_DTL', 120, False);
end;

procedure TfrmMtoDocumentosTrabajo.MostrarColumnasAtributoGlobalesDTR;
var
  Nombres: TNombresAtributosDocumentoTrabajo;
  Nombre: string;
  i, iOrden: Integer;
  Col: TcxGridColumn;
begin
  // Nombres globales de atributos para ver Color/Talla desde el
  // principio (mismo helper que inventarios / banco de pruebas).
  Nombres := FLecturasDocumentosTrabajo.ListarNombresAtributos;
  iOrden := 1;
  for Nombre in Nombres do
  begin
    if iOrden <= 5 then
    begin
      for i := 0 to tvLineasDTR.ColumnCount - 1 do
      begin
        Col := tvLineasDTR.Columns[i];
        if Col.Tag = iOrden then
        begin
          Col.Caption := Nombre;
          Col.Visible := True;
        end;
      end;
      Inc(iOrden);
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ModoEntradaResuelto(const ACodArt,
  ASku, ADescripcion: string; ACompleto: Boolean);
begin
  // El BeforePost del data module rellena LINEA e INSTANTE_STOCK; la
  // cantidad por defecto de una lectura es 1 si venia a 0.
  if ACompleto and
     (dmmDocumentosTrabajo.unqryLineas.State in [dsEdit, dsInsert]) and
     (dmmDocumentosTrabajo.unqryLineas.FieldByName(
        'CANTIDAD_DTL').AsFloat = 0) and
     (FModoEntradaSel <> mcsTallasInline) then
    dmmDocumentosTrabajo.unqryLineas.FieldByName(
      'CANTIDAD_DTL').AsFloat := 1;
end;

procedure TfrmMtoDocumentosTrabajo.AplicarEstadoAmbito;
var
  bPropios: Boolean;
begin
  bPropios := True;
  if dmmDocumentosTrabajo <> nil then
  begin
    bPropios := dmmDocumentosTrabajo.Ambito = dtaPropios;
  end;
  cxGrdDBTabPrin.OptionsData.Editing := bPropios;
  tvLineasDTR.OptionsData.Editing := bPropios;
  tvCompartidosDTR.OptionsData.Editing := bPropios;
  btnCargarFiltrosDTR.Enabled := bPropios;
  btnCompartirDTR.Enabled := bPropios;
end;

procedure TfrmMtoDocumentosTrabajo.CargarAlmacenesEtiquetasDTR(
  ALV: TcxListView);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CargarAlmacenesEtiquetasDoc(FIdEtiquetasDTR, ALV);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CrearDataSetEtiquetasDTR(ADmArt: TObject;
  const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CrearDataSetEtiquetasDoc(ADmArt,
                                                  FIdEtiquetasDTR,
                                                  ACodTarifa,
                                                  AAlmacenesCsv,
                                                  AFecha);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnListadoDTRClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  dsCabecera: TDataSet;
  sId: string;
  sTitulo: string;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsCabecera := dmmDocumentosTrabajo.unqryTablaG;
    if (not dsCabecera.Active) or dsCabecera.IsEmpty then
    begin
      ShowMessage(SErrorDocumentoTrabajoNoSeleccionadoListado);
    end
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dsCabecera.State in dsEditModes then
      begin
        dsCabecera.Post;
      end;
      if dsCabecera.FieldByName('ID_DTR').IsNull then
      begin
        ShowMessage(SErrorDocumentoTrabajoSinGrabarListado);
      end
      else if dmmDocumentosTrabajo.unqryLineas.IsEmpty then
      begin
        ShowMessage(SErrorDocumentoTrabajoSinLineasListado);
      end
      else
      begin
        sId := dsCabecera.FieldByName('ID_DTR').AsString;
        sTitulo := Copy(dsCabecera.FieldByName('TITULO_DTR').AsString,
                        1, 60);
        fPreview := TfrmMtoPreviewExcel.Create(Self);
        try
          fPreview.PopupParent := Self;
          fPreview.DialogoGuardar.InitialDir :=
            ParametrosApp.GetPath('appDirExcel');
          fPreview.DialogoGuardar.FileName := SanitizeFileName(
            'Documento_trabajo_' + sId + '_' + sTitulo);
          Screen.Cursor := crHourGlass;
          try
            ExportarDocumentoTrabajoExcel(
              fPreview.dxSpreadSheet1,
              dsCabecera,
              dmmDocumentosTrabajo.unqryLineas,
              FotosArticulos);
          finally
            Screen.Cursor := crDefault;
          end;
          fPreview.ShowModal;
        finally
          FreeAndNil(fPreview);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnCargarFiltrosDTRClick(Sender: TObject);
var
  ds: TDataSet;
  res: TAddBlockDocumentoTrabajoResult;
  sAlmacen: string;
  sTitulo: string;
begin
  inherited;
  if dmmDocumentosTrabajo <> nil then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    if (not ds.Active) or ds.IsEmpty then
    begin
      ShowMessage(SErrorDocumentoTrabajoNoSeleccionadoCargar);
    end
    else if dmmDocumentosTrabajo.Ambito <> dtaPropios then
    begin
      ShowMessage(SErrorCargarDocumentoTrabajoNoPropietario);
    end
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if ds.State in dsEditModes then
      begin
        ds.Post;
      end;
      if ds.FieldByName('ID_DTR').IsNull then
      begin
        ShowMessage(SErrorDocumentoTrabajoSinGrabarCargar);
      end
      else
      begin
        sAlmacen := ds.FieldByName('CODIGO_ALM_DTR').AsString;
        sTitulo := ds.FieldByName('TITULO_DTR').AsString;
        res := TfrmModalAddBlockDocumentoTrabajo.Ejecutar(
          Self,
          ds.FieldByName('ID_DTR').AsLargeInt,
          sAlmacen,
          sTitulo,
          FCargaMasiva);
        if res.Aceptado then
        begin
          pcDetalleDTR.ActivePage := tsLineasDTR;
          if dmmDocumentosTrabajo.unqryLineas.Active then
          begin
            dmmDocumentosTrabajo.unqryLineas.Close;
          end;
          dmmDocumentosTrabajo.unqryLineas.Open;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnCompartirDTRClick(Sender: TObject);
var
  Consulta: IConsultaDocumentoTrabajo;
  Datos: TDataSet;
  sDestino: string;
  sTipo: string;
begin
  inherited;
  if dmmDocumentosTrabajo <> nil then
  begin
    if (not dmmDocumentosTrabajo.unqryTablaG.Active) or
       (dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      ShowMessage(SErrorDocumentoTrabajoNoSeleccionadoCompartir);
    end
    else
    begin
      Consulta :=
        FLecturasDocumentosTrabajo.ConsultarDestinosCompartir;
      Datos := Consulta.DataSet;
      try
        if BusquedaVisual.EjecutarBusquedaDataSet(
          'Compartir Documento de Trabajo',
          Datos,
          'frmBuscarCompartirDTR',
          Self) then
        begin
          sTipo := Datos.FieldByName('TIPO').AsString;
          sDestino := Datos.FieldByName('DESTINO').AsString;
          if dmmDocumentosTrabajo.CompartirDocumentoActual(sDestino,
                                                           sTipo) then
          begin
            ShowMessage(SInfoDocumentoTrabajoCompartido);
          end
          else
          begin
            ShowMessage(SInfoDocumentoTrabajoYaCompartido);
          end;
          pcDetalleDTR.ActivePage := tsCompartirDTR;
        end;
      finally
        Consulta := nil;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnImprimirEtiquetasDTRClick(
  Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
  dmArt: TdmArticulos;
  sTitulo: string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDocumentosTrabajo <> nil then
  begin
    if (dmmDocumentosTrabajo.unqryTablaG.Active) and
       (not dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dmmDocumentosTrabajo.unqryTablaG.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryTablaG.Post;
      end;
      if not dmmDocumentosTrabajo.unqryTablaG.FieldByName('ID_DTR').IsNull then
      begin
        FIdEtiquetasDTR := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'ID_DTR').AsLargeInt;
        sTitulo := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'TITULO_DTR').AsString;
        dmArt := TdmArticulos.Create(nil);
        try
          formulario := TfrmPrintEtiqArt.Create(Application);
          try
            formulario.DM := dmArt;
            formulario.Caption := STituloImpresionEtiquetasDTR;
            formulario.TextoOrigenExterno := sTitulo;
            formulario.CargarAlmacenesExterno := CargarAlmacenesEtiquetasDTR;
            formulario.CrearDataSetExterno := CrearDataSetEtiquetasDTR;
            formulario.ShowModal;
          finally
            FreeAndNil(formulario);
          end;
        finally
          FreeAndNil(dmArt);
        end;
      end
      else
      begin
        ShowMessage(SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas);
      end;
    end
    else
    begin
      ShowMessage(SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas);
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.PrepararEnvio: Int64;
var
  ds: TDataSet;
begin
  Result := 0;
  if dmmDocumentosTrabajo <> nil then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    if (not ds.Active) or ds.IsEmpty then
      ShowMessage(SErrorDocumentoTrabajoNoSeleccionadoEnviar)
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
        dmmDocumentosTrabajo.unqryLineas.Post;
      if ds.State in dsEditModes then
        ds.Post;
      if ds.FieldByName('ID_DTR').IsNull then
        ShowMessage(SErrorDocumentoTrabajoSinGrabarEnviar)
      else if dmmDocumentosTrabajo.unqryLineas.IsEmpty then
        ShowMessage(SErrorDocumentoTrabajoSinLineasEnviar)
      else
        Result := ds.FieldByName('ID_DTR').AsLargeInt;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnEnviarADTRClick(Sender: TObject);
var
  pt: TPoint;
begin
  // El area principal del boton tambien despliega el menu.
  pt := btnEnviarADTR.ClientToScreen(Point(0, btnEnviarADTR.Height));
  pmEnviarDTR.Popup(pt.X, pt.Y);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarAlbaranDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  iLineas: Integer;
  ds: TDataSet;
  sEmp, sAlm, sSerie, sNumero: string;
  bContinuar: Boolean;
begin
  idDtr := PrepararEnvio;
  bContinuar := idDtr > 0;
  if bContinuar then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    sEmp := ds.FieldByName('CODIGO_EMP_DTR').AsString;
    sAlm := ds.FieldByName('CODIGO_ALM_DTR').AsString;
    sSerie := '';
    sNumero := '0';
    bContinuar := TfrmModalEnviarDestino.Ejecutar(
      Self, dmmDocumentosTrabajo.unqryTablaG.Connection,
      'Enviar a albarán de venta', sEmp, 'AV',
      sAlm, sSerie, sNumero);
    if bContinuar and (sNumero = '0') then
    begin
      sNumero := FMaterializacionDocumentosTrabajo.SiguienteContador(
        sSerie, 'AV', sEmp, IdentidadSesion.Usuario);
      bContinuar := (sNumero <> '') and (sNumero <> '0');
      if not bContinuar then
        ShowMessage(Format(
          SErrorContadorAlbaranDocumentoTrabajo, [sSerie]));
    end;
    if bContinuar then
    begin
      iLineas := FMaterializacionDocumentosTrabajo.CrearAlbaran(
        idDtr, sEmp, sAlm, sSerie, sNumero,
        IdentidadSesion.Usuario);
      ShowMessage(Format(SInfoAlbaranDocumentoTrabajoCreado,
        [sSerie, sNumero, iLineas]));
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ConfigurarEnvioNumerado(
  ATipo: TTipoEnvioNumeradoDocumentoTrabajo;
  out ATitulo, ATipoContador, AMensajeError,
  AMensajeCreado: string);
begin
  case ATipo of
    tenFacturaVenta:
    begin
      ATitulo := STituloEnviarFacturaVentaDocumentoTrabajo;
      ATipoContador := 'FC';
      AMensajeError := SErrorContadorFacturaVentaDocumentoTrabajo;
      AMensajeCreado := SInfoFacturaVentaDocumentoTrabajoCreada;
    end;
    tenPedidoCompra:
    begin
      ATitulo := STituloEnviarPedidoCompraDocumentoTrabajo;
      ATipoContador := 'PC';
      AMensajeError := SErrorContadorPedidoCompraDocumentoTrabajo;
      AMensajeCreado := SInfoPedidoCompraDocumentoTrabajoCreado;
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.ResolverNumeroEnvio(
  const ASerie, ANumero, ATipoContador, AEmpresa,
  AMensajeError: string): string;
begin
  Result := ANumero;
  if Result = '0' then
  begin
    Result := FMaterializacionDocumentosTrabajo.SiguienteContador(
      ASerie,
      ATipoContador,
      AEmpresa,
      IdentidadSesion.Usuario);
    if (Result = '') or (Result = '0') then
    begin
      ShowMessage(Format(AMensajeError, [ASerie]));
      Result := '';
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.EnviarDocumentoNumerado(
  ATipo: TTipoEnvioNumeradoDocumentoTrabajo);
var
  idDtr: Int64;
  iLineas: Integer;
  ds: TDataSet;
  sEmp, sAlm, sSerie, sNumero: string;
  sTitulo, sTipoContador, sMensajeError, sMensajeCreado: string;
begin
  ConfigurarEnvioNumerado(
    ATipo,
    sTitulo,
    sTipoContador,
    sMensajeError,
    sMensajeCreado);
  idDtr := PrepararEnvio;
  if idDtr > 0 then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    sEmp := ds.FieldByName('CODIGO_EMP_DTR').AsString;
    sAlm := ds.FieldByName('CODIGO_ALM_DTR').AsString;
    sSerie := '';
    sNumero := '0';
    if TfrmModalEnviarDestino.Ejecutar(
         Self,
         dmmDocumentosTrabajo.unqryTablaG.Connection,
         sTitulo,
         sEmp,
         sTipoContador,
         sAlm,
         sSerie,
         sNumero) then
    begin
      sNumero := ResolverNumeroEnvio(
        sSerie,
        sNumero,
        sTipoContador,
        sEmp,
        sMensajeError);
      if sNumero <> '' then
      begin
        iLineas := 0;
        case ATipo of
          tenFacturaVenta:
            iLineas :=
              FMaterializacionDocumentosTrabajo.CrearFacturaVenta(
              idDtr, sEmp, sAlm, sSerie, sNumero,
              IdentidadSesion.Usuario);
          tenPedidoCompra:
            iLineas :=
              FMaterializacionDocumentosTrabajo.CrearPedidoCompra(
              idDtr, sEmp, sAlm, sSerie, sNumero,
              IdentidadSesion.Usuario);
        end;
        ShowMessage(Format(
          sMensajeCreado,
          [sSerie, sNumero, iLineas]));
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarFacturaVentaDTRClick(
  Sender: TObject);
begin
  EnviarDocumentoNumerado(tenFacturaVenta);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTpvDTRClick(Sender: TObject);
var
  idDtr: Int64;
  ds: TDataSet;
  Bm: TBookmark;
  iOk, iMal: Integer;
  oAnfitrion: IAnfitrionCajaVentanas;
  oOperacionCaja: IOperacionCaja;
  oFormularioCaja: TCustomForm;
  sEmpresa, sAlmacen, sCaja: string;
begin
  idDtr := PrepararEnvio;
  if (idDtr > 0) and
     SeleccionarUbicacionCaja(sEmpresa, sAlmacen, sCaja) then
  begin
    oOperacionCaja := BuscarOperacionCajaVacia;
    if oOperacionCaja = nil then
    begin
      oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
      oOperacionCaja :=
        oAnfitrion.CrearOperacionCaja(Application, Permisos);
    end;
    oFormularioCaja := oOperacionCaja.FormularioCaja;
    try
      oFormularioCaja.PopupParent := Self;
      if oFormularioCaja.Tag <= 0 then
        oFormularioCaja.Tag := 1;
      oFormularioCaja.Caption := Format(
        STituloOperacionNCajaReal,
        [oFormularioCaja.Tag, sCaja]);
      oOperacionCaja.PrepararValores(
        sEmpresa, sAlmacen, sCaja, Now);
      // CargarSkuExterno deja preparada la siguiente linea y le da foco.
      // La venta debe estar visible antes de empezar a volcar los SKU.
      oFormularioCaja.Show;
      if oFormularioCaja.WindowState = wsMinimized then
        oFormularioCaja.WindowState := wsNormal;
      oFormularioCaja.BringToFront;
      ds := dmmDocumentosTrabajo.unqryLineas;
      iOk := 0;
      iMal := 0;
      Bm := ds.GetBookmark;
      ds.DisableControls;
      try
        ds.First;
        while not ds.Eof do
        begin
          if oOperacionCaja.CargarSkuExterno(
               ds.FieldByName('CODIGO_UNIDAD_DTL').AsString,
               ds.FieldByName('CANTIDAD_DTL').AsFloat) then
            Inc(iOk)
          else
            Inc(iMal);
          ds.Next;
        end;
        if ds.BookmarkValid(Bm) then
          ds.GotoBookmark(Bm);
      finally
        ds.EnableControls;
        ds.FreeBookmark(Bm);
      end;
      if iMal = 0 then
        ShowMessage(Format(
          SInfoLineasDocumentoTrabajoVolcadasTpv,
          [iOk]))
      else
        ShowMessage(Format(
          SAvisoLineasDocumentoTrabajoNoVolcadasTpv,
          [iOk, iMal]));
    except
      FreeAndNil(oFormularioCaja);
      raise;
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.SeleccionarUbicacionCaja(
  out AEmpresa, AAlmacen, ACaja: string): Boolean;
var
  oSelector: TfrmMtoModalCajDef;
begin
  AEmpresa := UbicacionSesion.Empresa;
  AAlmacen := UbicacionSesion.Almacen;
  ACaja := UbicacionSesion.Caja;
  Result := not ParametrosCaja.GetBool(
    'vgerShowCajaSelection', True);
  if not Result then
  begin
    oSelector := TfrmMtoModalCajDef.Create(
      Self,
      FRepositorioCajasDefecto);
    try
      oSelector.sEmpresa := AEmpresa;
      oSelector.sAlmacen := AAlmacen;
      oSelector.sCaja := ACaja;
      oSelector.ShowModal;
      Result := oSelector.sFicha = 'S';
      if Result then
      begin
        AEmpresa := oSelector.EmpresaSeleccionada;
        AAlmacen := oSelector.AlmacenSeleccionado;
        ACaja := oSelector.CajaSeleccionada;
      end;
    finally
      FreeAndNil(oSelector);
    end;
  end;
  if Result and
     ((AEmpresa = '') or (AAlmacen = '') or (ACaja = '')) then
  begin
    ShowMessage(SErrorAsignarUbicacionCaja);
    Result := False;
  end;
end;

function TfrmMtoDocumentosTrabajo.CrearLineasCargaTraspaso:
  TLineasCargaTraspaso;
var
  ds: TDataSet;
  Marcador: TBookmark;
  PartesSku: TArray<string>;
  iAtributo: Integer;
  iLinea: Integer;
begin
  ds := dmmDocumentosTrabajo.unqryLineas;
  SetLength(Result, ds.RecordCount);
  iLinea := 0;
  Marcador := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      Result[iLinea].CodigoArticulo :=
        ds.FieldByName('CODIGO_ART_DTL').AsString;
      Result[iLinea].CodigoSku :=
        ds.FieldByName('CODIGO_UNIDAD_DTL').AsString;
      PartesSku := Result[iLinea].CodigoSku.Split(['/']);
      Result[iLinea].Descripcion :=
        ds.FieldByName('DESCRIPCION_ARTICULO_DTL').AsString;
      Result[iLinea].Cantidad :=
        ds.FieldByName('CANTIDAD_DTL').AsFloat;
      Result[iLinea].NumeroAtributos :=
        ds.FieldByName('NUM_ATRIBUTOS_DTL').AsInteger;
      if Result[iLinea].NumeroAtributos < Length(PartesSku) - 1 then
        Result[iLinea].NumeroAtributos := Length(PartesSku) - 1;
      if Result[iLinea].NumeroAtributos > 5 then
        Result[iLinea].NumeroAtributos := 5;
      for iAtributo := 1 to 5 do
      begin
        Result[iLinea].ValoresAtributos[iAtributo] :=
          ds.FieldByName(Format(
            'ATTR%d_VALOR_DTL',
            [iAtributo])).AsString;
        if (Result[iLinea].ValoresAtributos[iAtributo] = '') and
           (iAtributo < Length(PartesSku)) then
          Result[iLinea].ValoresAtributos[iAtributo] :=
            PartesSku[iAtributo];
        Result[iLinea].NombresAtributos[iAtributo] :=
          ds.FieldByName(Format(
            'ATTR%d_NOMBRE_DTL',
            [iAtributo])).AsString;
      end;
      Inc(iLinea);
      ds.Next;
    end;
    if ds.BookmarkValid(Marcador) then
      ds.GotoBookmark(Marcador);
  finally
    ds.EnableControls;
    ds.FreeBookmark(Marcador);
  end;
  SetLength(Result, iLinea);
end;

procedure TfrmMtoDocumentosTrabajo.AbrirTraspasoCaja(
  AModo: TModoVentanaTraspaso);
var
  idDtr: Int64;
  oAnfitrion: IAnfitrionCajaVentanas;
  oTraspaso: ITraspasoCaja;
  oFormulario: TCustomForm;
  sEmp, sAlm, sCaja: string;
begin
  idDtr := PrepararEnvio;
  if (idDtr > 0) and
     SeleccionarUbicacionCaja(sEmp, sAlm, sCaja) then
  begin
    oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
    oTraspaso := oAnfitrion.CrearTraspasoCaja(Application, Permisos);
    oFormulario := oTraspaso.FormularioTraspaso;
    try
      oFormulario.PopupParent := Self;
      oFormulario.Caption := Format(
        STituloTraspasosAlmacenCaja,
        [sAlm, sCaja]);
      oTraspaso.PrepararCargaExterna(
        AModo,
        sEmp,
        sAlm,
        sCaja,
        Date,
        CrearLineasCargaTraspaso);
      oFormulario.Show;
    except
      FreeAndNil(oFormulario);
      raise;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarPedidoCompraDTRClick(
  Sender: TObject);
begin
  EnviarDocumentoNumerado(tenPedidoCompra);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTraspasoCajaDTRClick(
  Sender: TObject);
begin
  AbrirTraspasoCaja(mvtTraspaso);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarPeticionTraspasoDTRClick(
  Sender: TObject);
begin
  AbrirTraspasoCaja(mvtPeticion);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarInventarioDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  iLineas: Integer;
  ds: TDataSet;
  sEmp, sAlm, sSerie, sNumero: string;
  bContinuar: Boolean;
begin
  idDtr := PrepararEnvio;
  bContinuar := idDtr > 0;
  if bContinuar then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    sEmp := ds.FieldByName('CODIGO_EMP_DTR').AsString;
    sAlm := ds.FieldByName('CODIGO_ALM_DTR').AsString;
    sSerie := '';
    sNumero := '0';
    bContinuar := TfrmModalEnviarDestino.Ejecutar(
      Self, dmmDocumentosTrabajo.unqryTablaG.Connection,
      'Enviar a inventario', sEmp, 'IN', sAlm, sSerie, sNumero);
    if bContinuar and (sNumero = '0') then
    begin
      sNumero := FMaterializacionDocumentosTrabajo.SiguienteContador(
        sSerie, 'IN', sEmp, IdentidadSesion.Usuario);
      bContinuar := (sNumero <> '') and (sNumero <> '0');
      if not bContinuar then
        ShowMessage(Format(
          SErrorContadorInventarioDocumentoTrabajo, [sSerie]));
    end;
    if bContinuar then
    begin
      iLineas := FMaterializacionDocumentosTrabajo.CrearInventario(
        idDtr, sEmp, sAlm, sSerie, sNumero,
        IdentidadSesion.Usuario);
      ShowMessage(Format(SInfoInventarioDocumentoTrabajoCreado,
        [sSerie, sNumero, sAlm, iLineas]));
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTarifasDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  idTarc: Int64;
begin
  idDtr := PrepararEnvio;
  if idDtr > 0 then
  begin
    idTarc := FMaterializacionDocumentosTrabajo.CrearSesionTarifa(
      idDtr, IdentidadSesion.Usuario);
    ShowMessage(Format(SInfoCambioTarifasDocumentoTrabajoCreado,
      [idTarc]));
  end;
end;

procedure TfrmMtoDocumentosTrabajo.pcAmbitoDTRChange(Sender: TObject);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    if pcAmbitoDTR.ActivePage = tsAmbitoCompartidosDTR then
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaCompartidos);
    end
    else
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaPropios);
    end;
    AplicarEstadoAmbito;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.ResolverArtSkuActivo(out ACodArt,
  ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) and
     (dmmDocumentosTrabajo.dsLineas.DataSet <> nil) then
  begin
    inLibFotos.LeerArtSkuDeDataSet(dmmDocumentosTrabajo.dsLineas.DataSet,
                                   ACodArt, ACodSku);
  end;
  if ACodArt = '' then
  begin
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  end;
end;

function TfrmMtoDocumentosTrabajo.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) then
  begin
    Result := [dsTablaG, dmmDocumentosTrabajo.dsLineas];
  end
  else
  begin
    Result := inherited DataSourcesParaFoto;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoDocumentosTrabajo);
  ForceReferenceToClass(TfrmMtoDocumentosTrabajo);
end.
