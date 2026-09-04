{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraspasoOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de traspasos entre almacenes (TPV, F3 del menú de caja).        }
{    Cuatro modos: Traspaso, Solicitar, Atender y Reposiciones automáticas.    }
{    F12 emite con ticket; F11 queda para los traspasos que lo permiten.       }
{    Ver DESARROLLOS EN CURSO/traspasos_caja.md.                               }
{******************************************************************************}
unit inMtoTraspasoOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, inMtoFrmBase, cxGraphics,
  cxControls,
  cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit,
  cxButtonEdit, cxSpinEdit, cxCurrencyEdit, cxDropDownEdit, cxButtons,
  cxClasses, cxGridLevel, cxGridCustomTableView, cxGridCustomView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxSplitter,
  Vcl.Imaging.PngImage, System.Generics.Collections,
  Data.DB, Datasnap.DBClient, UniDataTraspaso,
  inLibTraspasoTicket, inLibGridArticulos, inLibArticulosValidadorIntf,
  inLibPermisosIntf, inLibGenBusq, inLibFotos, inLibAtributosPaleta,
  Vcl.Menus, dxCoreGraphics, JvComponentBase, JvEnterTab,
  cxLocalization, inLibLectorScanner, cxStyles, cxDBData, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges, cxCalendar,
  dxScrollbarAnnotations, inLibCajaVentaIntf, inLibCajaVentanasIntf,
  inLibTraspasoOpePersistenciaIntf, inLibArticulosAtributosIntf,
  inLibTraspasoTicketIntf, inLibCajaPantallaInyeccion,
  inLibColumnasSkuIntf, inLibColumnasSkuModoSku;

const
  WM_REVISAR_ENTER_AS_TAB_TRASPASO = WM_APP + 109;

type
  TfrmMtoOpeTraspaso = class(TfrmBase, ITraspasoCaja)
    pnlModos: TPanel;
    btnModoTraspaso: TcxButton;
    btnModoReposicion: TcxButton;
    btnModoSolicitar: TcxButton;
    btnModoAtender: TcxButton;
    btnMisPeticiones: TcxButton;
    pnlTop: TPanel;
    lblOrigen: TcxLabel;
    txtOrigen: TcxTextEdit;
    lblDestino: TcxLabel;
    cboDestino: TcxComboBox;
    lblEmpleado: TcxLabel;
    txtEmpleado: TcxButtonEdit;
    lblEmpleadoNombre: TcxLabel;
    lblVentasDesde: TcxLabel;
    dteVentasDesde: TcxDateEdit;
    lblVentasHasta: TcxLabel;
    dteVentasHasta: TcxDateEdit;
    btnCargarVentas: TcxButton;
    pnlCentro: TPanel;
    pnlBottom: TPanel;
    lblTotal: TcxLabel;
    btnF8: TcxButton;
    btnF11: TcxButton;
    btnF12: TcxButton;
    // Rejillas y panel de stock sacados al dfm (antes se creaban en codigo):
    // la rejilla de lineas (FGrid/FView) y la de stock pivotado
    // (FStockGrid/FStockView) dentro de FStockPanel, con la foto del articulo
    // (FFotoImg) y los splitters. Las columnas siguen creandose en runtime.
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    lvlLineas: TcxGridLevel;
    FStockPanel: TPanel;
    FFotoPanel: TPanel;
    FFotoImg: TImage;
    FFotoSplitter: TcxSplitter;
    FStockGrid: TcxGrid;
    FStockView: TcxGridDBTableView;
    lvlStock: TcxGridLevel;
    FStockSplitter: TcxSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btnModoClick(Sender: TObject);
    procedure btnF8Click(Sender: TObject);
    procedure btnF11Click(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure txtEmpleadoExit(Sender: TObject);
    procedure txtEmpleadoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure cboDestinoPropertiesChange(Sender: TObject);
    procedure dteVentasPropertiesChange(Sender: TObject);
    procedure btnCargarVentasClick(Sender: TObject);
    procedure btnMisPeticionesClick(Sender: TObject);
  private
    FDatos: TdmTraspaso;
    FGridCtrl: TGridArticulosLineas;
    FModoSku: TModoEntradaSku;
    FModoEntradaSel: TModoColumnasSku;
    FComboCodigos: TStringList;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFecha: TDateTime;
    FModo: TModoTraspaso;
    FVerCoste: Boolean;
    FStockDatos: TDataSet;
    FStockDs: TDataSource;
    FNavDs: TDataSource;
    FColUds: TcxGridDBColumn;
    FColStockDestino: TcxGridDBColumn;
    FColPedidas: TcxGridDBColumn;
    FColMotivo: TcxGridDBColumn;
    FQModalSolic: TDataSet;
    FConsultaStock: IResultadoConsultaCaja;
    FRepositorioConsultas: IRepositorioConsultasCaja;
    FRepositorioPersistencia: IRepositorioTraspasoOpe;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributosArticulos: IArticulosAtributosLookup;
    FRepositorioTraspasoTicket: IRepositorioTraspasoTicket;
    FReposicionCargada: Boolean;
    FCargandoVentasReposicion: Boolean;
    FEmpleadoConsultado: Boolean;
    FEmpleadoValidoConsultado: Boolean;
    FEntradaEmpleadoConsultada: string;
    FCodigoEmpleadoConsultado: string;
    FNombreEmpleadoConsultado: string;
    // Lectura con pistola a nivel de FORMULARIO (igual que inMtoCajaOpe): la
    // mecanica (trama STX/ETX + rafaga por velocidad) la lleva TLectorScanner.
    // En modo "consumir" y pasivo dentro de la rejilla (ahi resuelve la celda
    // via inLibGridArticulos); el detector por velocidad cubre el foco fuera.
    FLector: TLectorScanner;
    procedure ValidarDependencias;
    procedure AgregarLineaExterna(
      const ALinea: TLineaCargaTraspaso;
      var ANumeroLinea: Integer);
    procedure CargarLineasExternas(
      const ALineas: TLineasCargaTraspaso);
    procedure LectorCodigoLeido(Sender: TObject; const ACodigo: string);
    function  LectorEsControlRejilla(AControl: TControl): Boolean;
    procedure ProcesarLecturaScanner(const ACodigo: string);
    function ConsolidarSiExiste(const ASku: string): Boolean;
    procedure ConstruirGrid;
    function CrearCamposGrid: TCamposGridArt;
    procedure ConfigurarVistaGrid;
    procedure ConstruirEntradaSku(const ACampos: TCamposGridArt);
    procedure ConstruirEntradaDesglosada(const ACampos: TCamposGridArt);
    procedure CrearColumnasTraspaso;
    procedure CrearColumnaSeparacionDerecha(
      AVista: TcxGridDBTableView);
    procedure LiberarModoEntrada;
    procedure ConfigurarGridSegunModo;
    function ModoPermiteCargaManual: Boolean;
    function ModoPermiteAltaManual: Boolean;
    function PuedeBorrarLinea: Boolean;
    procedure AlternarModoEntrada;
    // Los combos de atributo del desglose desactivan el EnterAsTab del
    // formulario mientras editan; al salir se restaura y, en diferido,
    // se vuelve a desactivar si el foco sigue en la rejilla (mismo
    // patron que los documentos de venta y compra).
    procedure GridLineasEnter(Sender: TObject);
    procedure GridLineasExit(Sender: TObject);
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabTraspaso(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_TRASPASO;
    function ResolverEntradaModo(const AEntrada: string): Boolean;
    procedure MostrarEditorModo;
    procedure BuscarContextual;
    procedure GridResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
    procedure AsegurarLineaNueva;
    procedure EnfocarSegunModo;
    procedure AbrirModalSolicitudes;
    procedure ConfigurarModalSolicitudes(ADialogo: TForm);
    function CrearPanelBotonesSolicitudes(
      ADialogo: TForm): TPanel;
    function CrearRejillaSolicitudes(
      ADialogo: TForm): TcxGrid;
    function CrearRejillaDatos(
      ADialogo: TForm;
      AParent: TWinControl;
      ADatos: TDataSet;
      out AFuente: TDataSource;
      out AVista: TcxGridDBTableView): TcxGrid;
    procedure TitularColumnasSolicitudes(
      AVista: TcxGridDBTableView);
    procedure TitularColumnasLineasSolicitud(
      AVista: TcxGridDBTableView);
    procedure CrearBotonesSolicitudes(
      ADialogo: TForm;
      APanel: TPanel);
    procedure ModalSolicitudesKeyDown(
      Sender: TObject;
      var Key: Word;
      Shift: TShiftState);
    function MostrarModalSolicitudes(
      out ANumero, ASerie: string): Integer;
    procedure PonerCantidadesSolicitudACero;
    procedure AplicarSolicitudSeleccionada(
      const ANumero, ASerie: string;
      AResultadoModal: Integer);
    procedure ModalImprimirClick(Sender: TObject);
    procedure ConfigurarModalMisPeticiones(
      ADialogo: TForm;
      const ATitulo: string);
    procedure CrearBotonesMisPeticiones(
      ADialogo: TForm;
      APanel: TPanel);
    procedure MostrarModalMisPeticiones(const ATitulo: string);
    procedure ModalReimprimirClick(Sender: TObject);
    procedure ImprimirSolicitudModal(ADuplicado: Boolean);
    procedure CerrarSolicitudCargada;
    procedure DenegarSolicitudCargada;
    procedure AbrirHistoricoSolicitudes(
      const AAlmacen, ATitulo: string);
    procedure AbrirMisPeticiones;
    procedure AplicarModo(AModo: TModoTraspaso);
    procedure ConfigurarControlesReposicion;
    procedure InicializarRangoVentasReposicion;
    procedure InvalidarVentasReposicion;
    function FechaEditada(AEdit: TcxDateEdit): TDateTime;
    function ObtenerOrigenReposicion(out AOrigen: string): Boolean;
    function ObtenerRangoReposicion(
      out ADesde, AHasta: TDateTime): Boolean;
    procedure CargarVentasReposicion;
    procedure EmitirReposicion;
    procedure EmitirReposicionInterna;
    procedure CargarCombo;
    procedure CargarAlmacenesDestino;
    function DestinoSeleccionado: string;
    procedure ActualizarTotal;
    procedure QuitarLinea;
    procedure EjecutarTraspaso(AConTicket: Boolean);
    procedure EjecutarTraspasoInterno(AConTicket: Boolean);
    procedure AvisarStockSolicitud(const AAlmacenOrigen: string);
    procedure EnviarSolicitud;
    function ValidarEmpleadoActual(
      out ACodigo, ANombre: string): Boolean;
    function EmpleadoValido: Boolean;
    procedure BuscarEmpleado;
    // Consulta rapida de stock (banda inferior, igual que inMtoCajaOpe): una
    // rejilla pivotada (almacenes en filas, tallas en columnas) + foto del
    // articulo enfocado. Se refresca al resolver un SKU o al cambiar de linea.
    procedure ConstruirPanelStock;
    procedure ConsultarStock(const ACodigo: string);
    procedure RefrescarFotoStock(const ACodArt, ACodSku: string);
    procedure ActualizarStockYFoto;
    procedure NavDataChange(Sender: TObject; Field: TField);
    procedure StockViewCustomDrawCell(Sender: TcxCustomGridTableView;
              ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
              var ADone: Boolean);
  protected
    // Override como en documentos: F1 debe llegar antes que el editor inplace
    // de DevExpress, que puede consumirlo como tecla de ayuda.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion); reintroduce; overload;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion;
      const ADependencias: TDependenciasTraspasoCaja); reintroduce;
      overload;
    function FormularioTraspaso: TCustomForm;
    procedure PrepararValores(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                               ACaja: string; AFecha: TDateTime);
    procedure PrepararCargaExterna(
      AModo: TModoVentanaTraspaso;
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime;
      const ALineas: TLineasCargaTraspaso);
    procedure MostrarHistoricoSolicitudes(
      const AAlmacen, ATitulo: string);
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCaja, inLibMsgComun,
  UniDataGridArticulosRepositorio, UniDataColumnasSkuServicios,
  UniDataColumnasDocumentoRepositorio, inLibColumnasDocumento,
  inLibMsgArticulos;

const
  ALTO_CABECERA_NORMAL_96_DPI = 89;
  ALTO_CABECERA_REPOSICION_96_DPI = 128;
  ANCHO_MIN_A_PEDIR_96_DPI = 70;
  ANCHO_MIN_STOCK_DESTINO_96_DPI = 105;
  ANCHO_MIN_STOCK_ORIGEN_96_DPI = 100;
  ANCHO_SEPARADOR_DERECHO_GRID_96_DPI = 10;

resourcestring
  STituloMisPeticionesTraspaso =
    'Mis peticiones';
  SInfoSinPeticionesTraspaso =
    'No hay peticiones realizadas para este almacén.';
  SCaptionArticulosPeticionTraspaso =
    'Artículos de la petición';
  SCaptionPeticionesRealizadasTraspaso =
    'Peticiones realizadas';
  SCaptionAlmacenSolicitadoTraspaso =
    'Solicitado a (almacén)';
  SCaptionLineasPendientesTraspaso =
    'Líneas pendientes';
  SCaptionLineaPeticionTraspaso =
    'Línea';
  SCaptionServidasPeticionTraspaso =
    'Servidas';
  SCaptionNoServidasPeticionTraspaso =
    'No servidas';
  STituloBusquedaEmpleadoTraspaso =
    'Buscar empleado';

function TextoBotonConAtajo(
  const ACaption, AAtajo: string): string;
var
  iSeparador: Integer;
  sTexto: string;
begin
  sTexto := Trim(ACaption);
  if (Length(sTexto) >= 2) and
     (UpCase(sTexto[1]) = 'F') and
     CharInSet(sTexto[2], ['0'..'9']) then
  begin
    iSeparador := Pos(' ', sTexto);
    if iSeparador > 0 then
      Delete(sTexto, 1, iSeparador)
    else
      sTexto := '';
  end;
  Result := AAtajo + ' ' + TrimLeft(sTexto);
end;

constructor TfrmMtoOpeTraspaso.Create(AOwner: TComponent);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de traspasos de Caja');
end;

constructor TfrmMtoOpeTraspaso.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de traspasos de Caja');
end;

constructor TfrmMtoOpeTraspaso.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasTraspasoCaja);
begin
  ADependencias.Validar;
  FRepositorioConsultas := ADependencias.Consultas;
  FRepositorioPersistencia := ADependencias.Persistencia;
  FValidadorArticulos := ADependencias.ValidadorArticulos;
  FLookupAtributosArticulos := ADependencias.AtributosArticulos;
  FRepositorioTraspasoTicket := ADependencias.Ticket;
  inherited Create(AOwner, APermisos);
end;

procedure TfrmMtoOpeTraspaso.ValidarDependencias;
var
  Dependencias: TDependenciasTraspasoCaja;
begin
  Dependencias.Consultas := FRepositorioConsultas;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.ValidadorArticulos := FValidadorArticulos;
  Dependencias.AtributosArticulos := FLookupAtributosArticulos;
  Dependencias.Ticket := FRepositorioTraspasoTicket;
  Dependencias.Validar;
end;

procedure TfrmMtoOpeTraspaso.FormCreate(Sender: TObject);
begin
  inherited;
  // El catálogo instalado puede conservar los atajos anteriores. Se mantiene
  // el texto traducido y se impone el mapa funcional vigente.
  btnModoReposicion.Caption := SCaptionModoReposiciones;
  btnModoSolicitar.Caption :=
    TextoBotonConAtajo(btnModoSolicitar.Caption, 'F6');
  btnModoAtender.Caption :=
    TextoBotonConAtajo(btnModoAtender.Caption, 'F7');
  btnF8.Caption := 'F8 ' + Trim(
    StringReplace(SCaptionMenuBorrarLinea, '&', '', [rfReplaceAll]));
  lblVentasDesde.Caption := SCaptionVentasDesdeReposicion;
  lblVentasHasta.Caption := SCaptionVentasHastaReposicion;
  btnCargarVentas.Caption := SCaptionCargarVentasReposicion;
  ValidarDependencias;
  KeyPreview := True;
  // Detector del lector de codigo de barras (trama STX/ETX + rafaga por
  // velocidad). Modo "consumir" y pasivo en la rejilla: la lectura en la celda
  // de articulo la resuelve inLibGridArticulos; el detector por velocidad solo
  // actua con el foco fuera de la rejilla.
  FLector := TLectorScanner.Create;
  FLector.ConsumirRafaga := True;
  FLector.OmitirEnRejilla := True;
  FLector.OnCodigoLeido := LectorCodigoLeido;
  FLector.OnEsControlRejilla := LectorEsControlRejilla;
  FComboCodigos := TStringList.Create;
  FDatos := TdmTraspaso.Create(Self, ConexionPrincipal);
  // La entrada detallada es el modo inicial de traspasos. F1 alterna con la
  // entrada por SKU completo en una sola columna, como en documentos.
  FModoEntradaSel := mcsDesglose;
  // Coste/importe solo para administrador: TienePermiso devuelve True siempre a
  // admin; al resto, oculto por defecto (default False) salvo permiso explicito
  // 'caja.verCoste'. Sin sistema de permisos, oculto.
  FVerCoste := Assigned(Permisos) and
               Permisos.TienePermiso(
                 PERMISO_CAJA_VER_COSTE,
                 paDenegar);
  // Los labels los pone transparentes TfrmBase.FormCreate (via inherited).
  // El EnterAsTab de TfrmBase se suspende mientras el foco esta en la
  // rejilla: Intro lo gestiona el propio grid (GoToNextCellOnEnter) y
  // los combos de atributo lo necesitan para confirmar el valor.
  FGrid.OnEnter := GridLineasEnter;
  FGrid.OnExit := GridLineasExit;
  ConstruirGrid;
  ConstruirPanelStock;
  // Elegir una solicitud en el desplegable (modo Atender) la carga sola.
  cboDestino.Properties.OnChange := cboDestinoPropertiesChange;
end;

procedure TfrmMtoOpeTraspaso.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLector);
  // Evitar callbacks de stock/foto durante el desmontaje.
  if Assigned(FNavDs) then
    FNavDs.OnDataChange := nil;
  if Assigned(FStockDs) then
    FStockDs.DataSet := nil;
  FStockDatos := nil;
  FConsultaStock := nil;
  FRepositorioTraspasoTicket := nil;
  FLookupAtributosArticulos := nil;
  FValidadorArticulos := nil;
  FRepositorioConsultas := nil;
  FRepositorioPersistencia := nil;
  LiberarModoEntrada;
  FreeAndNil(FComboCodigos);
  // FDatos y los componentes runtime (grid/foto/datasources) los libera el
  // Owner (Self) automáticamente.
  inherited;
end;

procedure TfrmMtoOpeTraspaso.FormShow(Sender: TObject);
begin
  // Foco inicial segun el modo. En Traspaso dejamos el grid en modo edicion
  // (editor de articulo abierto) para poder escanear directamente sin pulsar
  // Enter; el almacen destino trae su valor por defecto y se valida al grabar.
  EnfocarSegunModo;
end;

function TfrmMtoOpeTraspaso.CrearCamposGrid: TCamposGridArt;
var
  Indice: Integer;
begin
  Result := Default(TCamposGridArt);
  Result.CodigoArt := 'CODIGO_ART';
  Result.CodigoUnidad := 'CODIGO_UNIDAD';
  Result.Descripcion := 'DESCRIPCION';
  Result.Cantidad := 'CANTIDAD';
  Result.NumAtributos := 'NUM_ATRIBUTOS';
  for Indice := 1 to 5 do
  begin
    Result.AttrValor[Indice] :=
      'ATTR' + IntToStr(Indice) + '_VALOR';
    Result.AttrNombre[Indice] :=
      'ATTR' + IntToStr(Indice) + '_NOMBRE';
  end;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarVistaGrid;
begin
  FView.DataController.DataSource := FDatos.dsLineas;
  FView.OptionsData.Editing := True;
  FView.OptionsData.Inserting := True;
  FView.OptionsData.Deleting := True;
  FView.OptionsBehavior.FocusCellOnCycle := True;
  FView.OptionsView.GroupByBox := False;
  FView.OptionsView.ColumnAutoWidth := True;
  FView.OptionsView.NoDataToDisplayInfoText := SCaptionSinArticulos;
  FView.Navigator.Visible := True;
end;

procedure TfrmMtoOpeTraspaso.ConstruirEntradaSku(
  const ACampos: TCamposGridArt);
var
  CamposSku: TCamposColumnasSku;
  Configuracion: TConfigColumnasSku;
  Indice: Integer;
begin
  CamposSku := Default(TCamposColumnasSku);
  CamposSku.CodigoArt := ACampos.CodigoArt;
  CamposSku.CodigoUnidad := ACampos.CodigoUnidad;
  CamposSku.Descripcion := ACampos.Descripcion;
  CamposSku.Cantidad := ACampos.Cantidad;
  CamposSku.NumAtributos := ACampos.NumAtributos;
  for Indice := 1 to 5 do
  begin
    CamposSku.AttrValor[Indice] := ACampos.AttrValor[Indice];
    CamposSku.AttrNombre[Indice] := ACampos.AttrNombre[Indice];
  end;
  Configuracion := Default(TConfigColumnasSku);
  Configuracion.Servicios :=
    CrearServiciosColumnasSkuUniDAC(ConexionPrincipal);
  Configuracion.ContextoSesion := ContextoSesion;
  Configuracion.RegistroLog := RegistroLog;
  Configuracion.ValidadorArticulos := FValidadorArticulos;
  Configuracion.LookupAtributos := FLookupAtributosArticulos;
  Configuracion.BusquedaVisual := BusquedaVisual;
  Configuracion.View := FView;
  Configuracion.Cds := FDatos.cdsLineas;
  Configuracion.Campos := CamposSku;
  Configuracion.Modo := mcsSku;
  Configuracion.AlmacenStock :=
    FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  FModoSku := TModoEntradaSku.Create(Configuracion);
  FModoSku.Construir(GridResuelto, DesactivarEnterAsTabTemporal,
    SalirEdicionModoEntrada);
end;

procedure TfrmMtoOpeTraspaso.ConstruirEntradaDesglosada(
  const ACampos: TCamposGridArt);
var
  Columna: TcxGridDBColumn;
  NombresAtributos: TArray<string>;
begin
  FGridCtrl := TGridArticulosLineas.Create(
    ConexionPrincipal,
    FView,
    FDatos.cdsLineas,
    ACampos,
    ContextoSesion,
    BusquedaVisual,
    // Desplegable incremental por articulo padre: una fila por modelo;
    // color y talla se eligen despues en sus combos (patron ventas).
    CrearBusquedaArticulosPadreGridUniDAC(ConexionPrincipal),
    CrearConsultaArticulosGridUniDAC(ConexionPrincipal),
    FValidadorArticulos,
    FLookupAtributosArticulos,
    RegistroLog,
    True);
  FGridCtrl.AlmacenStock :=
    FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  FGridCtrl.OnResuelto := GridResuelto;
  // Selector de atributos en combo fijo con filtrado, en vez de la
  // paleta emergente.
  FGridCtrl.UsarCombosAtributos := True;
  FGridCtrl.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FGridCtrl.OnSalirEdicion := SalirEdicionModoEntrada;
  if FModo = mtReposicion then
    FGridCtrl.MaximoAtributosVisibles := 2;
  FGridCtrl.Construir;
  Columna := FView.GetColumnByFieldName('CODIGO_ART');
  if Assigned(Columna) then
    Columna.Caption := SCaptionColArticulo;
  NombresAtributos := CrearColumnasDocumentoLecturas(
    ConexionPrincipal).ListarNombresAtributosGlobales;
  if Length(NombresAtributos) = 0 then
    NombresAtributos := TArray<string>.Create('Color', 'Talla')
  else if Length(NombresAtributos) = 1 then
  begin
    SetLength(NombresAtributos, 2);
    NombresAtributos[1] := 'Talla';
  end
  else if Length(NombresAtributos) > 2 then
    SetLength(NombresAtributos, 2);
  AplicarNombresAtributosGlobalesDocumento(
    FView, NombresAtributos);
end;

procedure TfrmMtoOpeTraspaso.CrearColumnasTraspaso;
var
  Columna: TcxGridDBColumn;
begin
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColDescripcionTraspaso;
  Columna.DataBinding.FieldName := 'DESCRIPCION';
  Columna.Options.Editing := False;
  Columna.Width := 200;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColUdsTraspaso;
  Columna.DataBinding.FieldName := 'CANTIDAD';
  Columna.Width := 50;
  FColUds := Columna;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColCosteTraspaso;
  Columna.DataBinding.FieldName := 'PRECIO_COSTE';
  Columna.Options.Editing := False;
  Columna.Width := 70;
  Columna.Visible := FVerCoste and (FModo <> mtReposicion);
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColStockDestinoTraspaso;
  Columna.DataBinding.FieldName := 'STOCK_DESTINO';
  Columna.Options.Editing := False;
  Columna.HeaderAlignmentHorz := taCenter;
  Columna.Width := 90;
  Columna.Visible := FModo = mtReposicion;
  if FModo = mtReposicion then
    Columna.MinWidth := MulDiv(
      ANCHO_MIN_STOCK_DESTINO_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  FColStockDestino := Columna;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColStockOrigenTraspaso;
  Columna.DataBinding.FieldName := 'STOCK_ORIGEN';
  Columna.Options.Editing := False;
  Columna.HeaderAlignmentHorz := taCenter;
  Columna.Width := 90;
  if FModo = mtReposicion then
    Columna.MinWidth := MulDiv(
      ANCHO_MIN_STOCK_ORIGEN_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColPedidasTraspaso;
  Columna.DataBinding.FieldName := 'CANTIDAD_PEDIDA';
  Columna.Options.Editing := False;
  Columna.Width := 60;
  Columna.Visible := False;
  FColPedidas := Columna;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColMotivoRechazoTraspaso;
  Columna.DataBinding.FieldName := 'MOTIVO';
  Columna.Width := 180;
  Columna.Visible := False;
  FColMotivo := Columna;
end;

procedure TfrmMtoOpeTraspaso.CrearColumnaSeparacionDerecha(
  AVista: TcxGridDBTableView);
var
  Columna: TcxGridDBColumn;
  iAncho: Integer;
begin
  if Assigned(AVista) then
  begin
    iAncho := MulDiv(
      ANCHO_SEPARADOR_DERECHO_GRID_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    Columna := AVista.CreateColumn;
    Columna.Caption := '';
    Columna.DataBinding.ValueTypeClass := TcxStringValueType;
    Columna.Width := iAncho;
    Columna.MinWidth := iAncho;
    Columna.Options.AutoWidthSizable := False;
    Columna.Options.Editing := False;
    Columna.Options.Filtering := False;
    Columna.Options.Focusing := False;
    Columna.Options.Grouping := False;
    Columna.Options.HorzSizing := False;
    Columna.Options.Moving := False;
    Columna.Options.ShowCaption := False;
    Columna.Options.Sorting := False;
    Columna.VisibleForCustomization := False;
  end;
end;

procedure TfrmMtoOpeTraspaso.ConstruirGrid;
var
  Campos: TCamposGridArt;
begin
  // Los dos modos comparten el cds. Solo se reconstruye la presentacion:
  // desglose = Articulo/Color/Talla; SKU = una columna con el codigo completo.
  LiberarModoEntrada;
  ConfigurarVistaGrid;
  Campos := CrearCamposGrid;
  if FModoEntradaSel = mcsSku then
    ConstruirEntradaSku(Campos)
  else
    ConstruirEntradaDesglosada(Campos);
  CrearColumnasTraspaso;
  ConfigurarGridSegunModo;
  CrearColumnaSeparacionDerecha(FView);
end;

procedure TfrmMtoOpeTraspaso.LiberarModoEntrada;
begin
  if Assigned(FView) and
     FView.Controller.EditingController.IsEditing then
    FView.Controller.EditingController.HideEdit(False);
  if Assigned(FModoSku) then
    FModoSku.Desmontar;
  FreeAndNil(FModoSku);
  FreeAndNil(FGridCtrl);
  FColUds := nil;
  FColStockDestino := nil;
  FColPedidas := nil;
  FColMotivo := nil;
end;

procedure TfrmMtoOpeTraspaso.GridLineasEnter(Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoOpeTraspaso.GridLineasExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  // Un combo de atributo desplegado mantiene el EnterAsTab desactivado
  // hasta cerrarse: se restaura sobre el editor y no sobre la rejilla.
  Editor := nil;
  if Assigned(FView) and
     Assigned(FView.Controller.EditingController) and
     FView.Controller.EditingController.IsEditing then
    Editor := FView.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoOpeTraspaso.SalirEdicionModoEntrada(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_TRASPASO, 0, 0);
end;

procedure TfrmMtoOpeTraspaso.WMRevisarEnterAsTabTraspaso(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and Assigned(FGrid) and
     ((ControlActivo = FGrid) or FGrid.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

procedure TfrmMtoOpeTraspaso.ConfigurarGridSegunModo;
var
  i: Integer;
  sCampo: string;
begin
  FView.OptionsData.Inserting := ModoPermiteAltaManual;
  FView.OptionsData.Deleting := ModoPermiteCargaManual;
  FView.OptionsData.Editing := True;
  for i := 0 to FView.ColumnCount - 1 do
  begin
    if FModo = mtAtender then
      FView.Columns[i].Options.Editing :=
        (FView.Columns[i] = FColUds) or
        (FView.Columns[i] = FColMotivo)
    else if FModo = mtReposicion then
    begin
      sCampo := FView.Columns[i].DataBinding.FieldName;
      FView.Columns[i].Options.Editing :=
        SameText(sCampo, 'CODIGO_ART') or
        SameText(sCampo, 'CODIGO_UNIDAD') or
        SameText(sCampo, 'CANTIDAD') or
        ((Length(sCampo) = 11) and
         SameText(Copy(sCampo, 1, 4), 'ATTR') and
         CharInSet(sCampo[5], ['1'..'5']) and
         SameText(Copy(sCampo, 6, 6), '_VALOR'));
    end
    else
      FView.Columns[i].Options.Editing := True;
  end;
  if Assigned(FColPedidas) then
    FColPedidas.Visible := FModo = mtAtender;
  if Assigned(FColMotivo) then
    FColMotivo.Visible := FModo = mtAtender;
  if Assigned(FColUds) then
  begin
    if FModo = mtAtender then
      FColUds.Caption := SCaptionColSirvoTraspaso
    else if FModo = mtReposicion then
    begin
      FColUds.Caption := SCaptionColAPedirReposicion;
      FColUds.MinWidth := MulDiv(
        ANCHO_MIN_A_PEDIR_96_DPI,
        CurrentPPI,
        USER_DEFAULT_SCREEN_DPI);
    end
    else
      FColUds.Caption := SCaptionColUdsTraspaso;
  end;
end;

function TfrmMtoOpeTraspaso.ModoPermiteCargaManual: Boolean;
begin
  Result := FModo in [mtTraspaso, mtSolicitar];
end;

function TfrmMtoOpeTraspaso.ModoPermiteAltaManual: Boolean;
begin
  Result := FModo in [mtTraspaso, mtSolicitar, mtReposicion];
end;

function TfrmMtoOpeTraspaso.PuedeBorrarLinea: Boolean;
begin
  Result := ModoPermiteCargaManual or
    ((FModo = mtReposicion) and
     Assigned(FDatos) and
     Assigned(FDatos.cdsLineas) and
     FDatos.cdsLineas.Active and
     (not FDatos.cdsLineas.IsEmpty));
end;

procedure TfrmMtoOpeTraspaso.AlternarModoEntrada;
var
  sArticulo: string;
begin
  if FModoEntradaSel = mcsSku then
    FModoEntradaSel := mcsDesglose
  else
    FModoEntradaSel := mcsSku;
  ConstruirGrid;
  if Assigned(FGridCtrl) and not FDatos.cdsLineas.IsEmpty then
  begin
    sArticulo := Trim(
      FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString);
    if sArticulo <> '' then
      FGridCtrl.MostrarColumnasAtributosArticulo(sArticulo);
  end;
  if ModoPermiteCargaManual then
    AsegurarLineaNueva;
  if Showing and FGrid.CanFocus then
  begin
    FGrid.SetFocus;
    if ModoPermiteCargaManual then
      MostrarEditorModo;
  end;
end;

function TfrmMtoOpeTraspaso.ResolverEntradaModo(
  const AEntrada: string): Boolean;
begin
  Result := False;
  if Assigned(FModoSku) then
    Result := FModoSku.ResolverEntrada(AEntrada)
  else if Assigned(FGridCtrl) then
    Result := FGridCtrl.ResolverEntrada(AEntrada);
end;

procedure TfrmMtoOpeTraspaso.MostrarEditorModo;
begin
  if Assigned(FModoSku) then
    FModoSku.MostrarEditor
  else if Assigned(FGridCtrl) then
    FGridCtrl.MostrarEditorArticulo;
end;

procedure TfrmMtoOpeTraspaso.BuscarContextual;
var
  ControlActivo: TWinControl;
  bFocoEmpleado: Boolean;
begin
  ControlActivo := Screen.ActiveControl;
  bFocoEmpleado := ControlActivo = txtEmpleado;
  if Assigned(ControlActivo) and not bFocoEmpleado then
    bFocoEmpleado := txtEmpleado.ContainsControl(ControlActivo);
  if bFocoEmpleado then
    BuscarEmpleado
  else if ModoPermiteAltaManual then
  begin
    if (FModo = mtReposicion) or Assigned(FModoSku) then
      AsegurarLineaNueva;
    if FGrid.CanFocus then
      FGrid.SetFocus;
    if (FModo = mtReposicion) and
       (Trim(FDatos.cdsLineas.FieldByName(
         'CODIGO_ART').AsString) = '') then
      MostrarEditorModo;
    if Assigned(FModoSku) then
      FModoSku.BuscarArticulo
    else if Assigned(FGridCtrl) then
      FGridCtrl.BuscarContextual;
  end;
end;

procedure TfrmMtoOpeTraspaso.ConstruirPanelStock;
begin
  // El panel de stock, los splitters, la foto y la rejilla pivotada viven ya en
  // el dfm (FStockPanel/FFotoPanel/FFotoImg/FStockGrid/FStockView). Aqui solo
  // queda lo que no se puede fijar en diseno: las opciones de la vista, el
  // dibujo del swatch y el cableado de datos (la rejilla cuelga de una query y
  // un data module creados en runtime).
  FStockView.OptionsData.Editing := False;
  FStockView.OptionsData.Inserting := False;
  FStockView.OptionsData.Deleting := False;
  FStockView.OptionsSelection.CellSelect := False;
  FStockView.OptionsView.GroupByBox := False;
  FStockView.OptionsView.ColumnAutoWidth := True;
  FStockView.OptionsCustomize.ColumnFiltering := False;
  FStockView.OnCustomDrawCell := StockViewCustomDrawCell;
  FStockDs := TDataSource.Create(Self);
  FStockView.DataController.DataSource := FStockDs;
  // Refrescar stock+foto al moverse por las lineas (cambio de registro).
  FNavDs := TDataSource.Create(Self);
  FNavDs.DataSet := FDatos.cdsLineas;
  FNavDs.OnDataChange := NavDataChange;
end;

procedure TfrmMtoOpeTraspaso.ConsultarStock(const ACodigo: string);
var
  i: Integer;
  Mapa: TDictionary<string, string>;
  Fld: TField;
  bTodoCero: Boolean;
begin
  // Misma logica que inMtoCajaOpe.ConsultarStock: abrir el SP, construir las
  // columnas dinamicas, alinear cabeceras y ajustar anchos (con swatch en la
  // primera columna). Se omiten los cronometros de perf.
  if (ACodigo <> '') and Assigned(FStockView) then
  begin
    FStockDs.DataSet := nil;
    FConsultaStock := FRepositorioConsultas.ConsultarStock(ACodigo);
    FStockDatos := FConsultaStock.DataSet;
    FStockDs.DataSet := FStockDatos;
    FStockView.BeginUpdate;
    try
      FStockView.ClearItems;
      if not FStockDatos.IsEmpty then
      begin
        FStockView.DataController.CreateAllItems;
        for i := 0 to FStockView.ColumnCount - 1 do
        begin
          if i <= 1 then
            FStockView.Columns[i].HeaderAlignmentHorz := taLeftJustify
          else
            FStockView.Columns[i].HeaderAlignmentHorz := taRightJustify;
        end;
      end;
    finally
      FStockView.EndUpdate;
    end;
    if FStockDatos.Active and (not FStockDatos.IsEmpty) then
    begin
      FStockView.BeginUpdate;
      try
        try
          FStockView.ApplyBestFit;
        except
          // ApplyBestFit puede fallar si no hay columnas; lo ignoramos.
          on E: Exception do
            RegistroLog.RegistrarAviso(
              'TraspasoOpe: ApplyBestFit del stock ignorado: ' +
              E.Message);
        end;
        // La primera columna (codigo CODART/COLOR) lleva swatch de color: le
        // sumamos el ancho del cuadradito para que no recorte el texto.
        Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
        if (Mapa <> nil) and (Mapa.Count > 0) and
           (FStockView.ColumnCount > 0) then
          AjustarAnchoColumnaParaSwatch(
            ConexionPrincipal,
            FStockView.Columns[0],
            Mapa);
        // Mostrar solo las tallas con existencias: ocultamos las columnas de
        // talla que esten a cero en todos los almacenes (el SP devuelve una
        // columna por cada talla del articulo, tenga o no stock). No se tocan
        // Codigo/Almacen (texto) ni el Total.
        FStockDatos.DisableControls;
        try
          for i := 0 to FStockView.ColumnCount - 1 do
          begin
            Fld := FStockDatos.FindField(
              FStockView.Columns[i].DataBinding.FieldName);
            if (Fld <> nil) and
               (Fld.DataType in [ftSmallint, ftInteger, ftWord, ftLargeint,
                ftFloat, ftCurrency, ftBCD, ftFMTBcd]) and
               (not SameText(Fld.FieldName, 'Total')) and
               (not SameText(Fld.FieldName, 'Stock_Total')) and
               (not SameText(Fld.FieldName, 'Stock Total')) then
            begin
              bTodoCero := True;
              FStockDatos.First;
              while (not FStockDatos.Eof) and bTodoCero do
              begin
                if Fld.AsFloat <> 0 then
                  bTodoCero := False;
                FStockDatos.Next;
              end;
              if bTodoCero then
                FStockView.Columns[i].Visible := False;
            end;
          end;
          FStockDatos.First;
        finally
          FStockDatos.EnableControls;
        end;
        CrearColumnaSeparacionDerecha(FStockView);
      finally
        FStockView.EndUpdate;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.RefrescarFotoStock(const ACodArt, ACodSku: string);
var
  info: TFotoInfo;
  sRuta: string;
  png: TPngImage;
begin
  if Assigned(FFotoImg) then
  begin
    FFotoImg.Picture.Assign(nil);
    if ACodArt <> '' then
    begin
      info := FotosArticulos.Resolver(ACodArt, ACodSku);
      sRuta := FotosArticulos.RutaFoto(info, frPx300);
      if sRuta <> '' then
      begin
        png := TPngImage.Create;
        try
          png.LoadFromFile(sRuta);
          FFotoImg.Picture.Assign(png);
        finally
          FreeAndNil(png);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ActualizarStockYFoto;
var
  sArt, sSku: string;
begin
  if (FDatos = nil) or (FDatos.cdsLineas = nil) or
     (not FDatos.cdsLineas.Active) or FDatos.cdsLineas.IsEmpty then
  begin
    // Sin lineas: vaciar stock y foto.
    RefrescarFotoStock('', '');
    if Assigned(FStockDs) then
      FStockDs.DataSet := nil;
    FStockDatos := nil;
    FConsultaStock := nil;
    if Assigned(FStockView) then
      FStockView.ClearItems;
  end
  else
  begin
    sArt := Trim(FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // Consultamos por el articulo padre para ver todas las tallas/colores en
    // todos los almacenes; la foto usa el SKU concreto si existe. Si la linea
    // esta en blanco (linea nueva tras resolver) dejamos lo ultimo mostrado en
    // vez de parpadear a vacio.
    if sArt <> '' then
    begin
      ConsultarStock(sArt);
      RefrescarFotoStock(sArt, sSku);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.NavDataChange(Sender: TObject; Field: TField);
begin
  if FModo = mtReposicion then
    btnF8.Enabled := PuedeBorrarLinea;
  // Solo al cambiar de registro (Field = nil), no en cada cambio de columna.
  if (Field = nil) and not FCargandoVentasReposicion then
    ActualizarStockYFoto;
end;

procedure TfrmMtoOpeTraspaso.StockViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // El swatch de color solo aplica a la primera columna visible (Codigo, que
  // lleva "CODART/COLOR"). En las demas (almacen, tallas) el texto — p.ej. el
  // "0" de una talla — podia colar como valor de atributo y pintar cuadraditos
  // donde no toca. Mismo criterio que la rejilla de stock de caja.
  if (AViewInfo <> nil) and (AViewInfo.Item <> nil) and
     (AViewInfo.Item.VisibleIndex = 0) and
     PintarCeldaSwatchSiAplica(ConexionPrincipal,ACanvas, AViewInfo, nil) then
    ADone := True;
end;

procedure TfrmMtoOpeTraspaso.GridResuelto(const ACodArt, ASku,
                                          ADescripcion: string;
                                          ACompleto: Boolean);
var
  sAlmacenOrigen, sKey: string;
begin
  if not ACompleto then
    ActualizarTotal
  else
  begin
    // Punto comun de resolucion (escaneo Codigo+CR via celda, STX/ETX o
    // teclado). Si la SKU/articulo ya esta en otra linea, sumamos alli y
    // descartamos esta (consolidacion, como en caja). La clave es lo que se
    // acaba de guardar en CODIGO_UNIDAD de la linea actual.
    sKey := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    if (sKey <> '') and ConsolidarSiExiste(sKey) then
    begin
      // Descartamos la linea recien resuelta para no duplicar. Cancel si sigue
      // en edicion; si el clon ya la dejo grabada con esa misma SKU, la
      // borramos (mismo patron que caja). Luego garantizamos una linea blanca.
      if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
        FDatos.cdsLineas.Cancel;
      if (not FDatos.cdsLineas.IsEmpty) and
         (Trim(FDatos.cdsLineas.FieldByName(
           'CODIGO_UNIDAD').AsString) = sKey) then
        FDatos.cdsLineas.Delete;
      if ModoPermiteCargaManual then
        AsegurarLineaNueva;
      ActualizarTotal;
    end
    else
    begin
      if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
      begin
        if FModo = mtReposicion then
        begin
          sAlmacenOrigen := DestinoSeleccionado;
          FDatos.cdsLineas.FieldByName('STOCK_DESTINO').AsFloat :=
            FDatos.ObtenerStock(ASku, FAlmacen);
          if sAlmacenOrigen <> '' then
            FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
              FDatos.ObtenerStock(ASku, sAlmacenOrigen);
        end
        else
        begin
          sAlmacenOrigen :=
            FDatos.cdsCabecera.FieldByName(
              'CODIGO_ALM_ORIGEN').AsString;
          FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
            FDatos.ObtenerCosteMedio(ASku, sAlmacenOrigen);
          FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
            FDatos.ObtenerStock(ASku, sAlmacenOrigen);
        end;
      end;
      ActualizarTotal;
      ConsultarStock(ACodArt);
      RefrescarFotoStock(ACodArt, ASku);
      // Otra linea en blanco para seguir metiendo (solo traspaso/solicitar).
      if ModoPermiteCargaManual then
        AsegurarLineaNueva;
    end;
    if FModo = mtReposicion then
    begin
      FReposicionCargada := True;
      btnF8.Enabled := PuedeBorrarLinea;
      btnF12.Enabled := True;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.PrepararValores(AModo: TModoTraspaso;
                          const AEmpresa, AAlmacen, ACaja: string;
                          AFecha: TDateTime);
begin
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFecha := AFecha;
  // Cada entrada nueva en Traspasos empieza en Articulo/Color/Talla. F1 puede
  // cambiar a SKU durante la sesion, pero esa preferencia no se arrastra a la
  // siguiente apertura de la operativa.
  FModoEntradaSel := mcsDesglose;
  AplicarModo(AModo);
  // Empleado responsable por defecto desde parametros de caja (igual que
  // inMtoCajaOpe): si esta activado, se rellena al abrir la pantalla.
  if Assigned(ParametrosCaja) and
     ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False) then
  begin
    txtEmpleado.Text :=
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', '');
    if Trim(txtEmpleado.Text) <> '' then
      txtEmpleadoExit(nil);
  end;
end;

function TfrmMtoOpeTraspaso.FormularioTraspaso: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmMtoOpeTraspaso.AgregarLineaExterna(
  const ALinea: TLineaCargaTraspaso;
  var ANumeroLinea: Integer);
var
  iAtributo: Integer;
  sAlmacenOrigen: string;
begin
  if (Trim(ALinea.CodigoSku) <> '') and
     FDatos.cdsLineas.Locate(
       'CODIGO_UNIDAD',
       ALinea.CodigoSku,
       []) then
  begin
    FDatos.cdsLineas.Edit;
    FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat + ALinea.Cantidad;
    FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
      FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
    FDatos.cdsLineas.Post;
  end
  else
  begin
    Inc(ANumeroLinea, 10);
    sAlmacenOrigen :=
      FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    FDatos.cdsLineas.Append;
    FDatos.cdsLineas.FieldByName('LINEA').AsString :=
      Format('%.4d', [ANumeroLinea]);
    FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString :=
      ALinea.CodigoArticulo;
    FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
      ALinea.CodigoSku;
    FDatos.cdsLineas.FieldByName('DESCRIPCION').AsString :=
      ALinea.Descripcion;
    FDatos.cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger :=
      ALinea.NumeroAtributos;
    for iAtributo := 1 to 5 do
    begin
      FDatos.cdsLineas.FieldByName(
        Format('ATTR%d_VALOR', [iAtributo])).AsString :=
        ALinea.ValoresAtributos[iAtributo];
      FDatos.cdsLineas.FieldByName(
        Format('ATTR%d_NOMBRE', [iAtributo])).AsString :=
        ALinea.NombresAtributos[iAtributo];
    end;
    FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := ALinea.Cantidad;
    FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
      FDatos.ObtenerCosteMedio(ALinea.CodigoSku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
      FDatos.ObtenerStock(ALinea.CodigoSku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
      FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
    FDatos.cdsLineas.Post;
  end;
end;

procedure TfrmMtoOpeTraspaso.CargarLineasExternas(
  const ALineas: TLineasCargaTraspaso);
var
  Linea: TLineaCargaTraspaso;
  NumeroLinea: Integer;
  iMaxAtributos: Integer;
  sArticuloAtributos: string;
begin
  NumeroLinea := 0;
  iMaxAtributos := 0;
  sArticuloAtributos := '';
  FDatos.cdsLineas.EmptyDataSet;
  FDatos.cdsLineas.DisableControls;
  try
    for Linea in ALineas do
    begin
      AgregarLineaExterna(Linea, NumeroLinea);
      if Linea.NumeroAtributos > iMaxAtributos then
      begin
        iMaxAtributos := Linea.NumeroAtributos;
        sArticuloAtributos := Linea.CodigoArticulo;
      end;
    end;
  finally
    FDatos.cdsLineas.EnableControls;
  end;
  if (iMaxAtributos > 0) and Assigned(FGridCtrl) then
    FGridCtrl.MostrarColumnasAtributosArticulo(sArticuloAtributos);
  AsegurarLineaNueva;
  ActualizarTotal;
end;

procedure TfrmMtoOpeTraspaso.PrepararCargaExterna(
  AModo: TModoVentanaTraspaso;
  const AEmpresa, AAlmacen, ACaja: string;
  AFecha: TDateTime;
  const ALineas: TLineasCargaTraspaso);
var
  ModoTraspaso: TModoTraspaso;
begin
  if AModo = mvtPeticion then
    ModoTraspaso := mtSolicitar
  else
    ModoTraspaso := mtTraspaso;
  PrepararValores(
    ModoTraspaso,
    AEmpresa,
    AAlmacen,
    ACaja,
    AFecha);
  CargarLineasExternas(ALineas);
end;

procedure TfrmMtoOpeTraspaso.AplicarModo(AModo: TModoTraspaso);
begin
  FModo := AModo;
  // El lector no tiene destino funcional en reposicion ni al atender. Evita
  // que el tecleo rapido en fechas o combos se confunda con una rafaga.
  FLector.Activo := ModoPermiteCargaManual;
  FReposicionCargada := False;
  FDatos.PrepararNuevo(AModo, FEmpresa, FAlmacen, FCaja, FFecha);
  txtOrigen.Text := FAlmacen;
  // La reconstruccion conserva el modo F1 y actualiza el almacen de stock del
  // buscador tras cambiar de modo.
  ConstruirGrid;
  btnF11.Visible := AModo in [mtTraspaso, mtAtender];
  btnF8.Enabled := PuedeBorrarLinea;
  // Captions con tilde en literal: este .pas va en UTF-8 con BOM (igual que
  // inMtoCajaMenu.pas) para que el compilador las lea bien.
  case AModo of
    mtTraspaso:
    begin
      lblOrigen.Caption := SCaptionAlmacenOrigen;
      lblDestino.Caption := SCaptionAlmacenDestino;
      btnF12.Caption := SCaptionF12ConTicket;
    end;
    mtSolicitar:
    begin
      lblOrigen.Caption := SCaptionAlmacenDestino;
      lblDestino.Caption := SCaptionAlmacenOrigen;
      btnF12.Caption := SCaptionF12EnviarSolicitud;
    end;
    mtReposicion:
    begin
      lblOrigen.Caption := SCaptionAlmacenDestino;
      lblDestino.Caption := SCaptionAlmacenOrigen;
      btnF12.Caption := SCaptionF12EmitirReposicion;
    end;
    mtAtender:
    begin
      lblOrigen.Caption := SCaptionAlmacenOrigen;
      lblDestino.Caption := SCaptionAlmacenDestino;
      btnF12.Caption := SCaptionF12ServirConTicket;
    end;
  end;
  ConfigurarControlesReposicion;
  CargarCombo;
  cboDestino.ItemIndex := -1;
  cboDestino.Text := '';
  cboDestino.Properties.ReadOnly := AModo = mtAtender;
  // Sin NewItemRow: dejamos una linea en blanco para teclear (estilo Excel);
  // al completar un SKU el grid anyade otra (GridResuelto). Al atender no.
  if ModoPermiteCargaManual then
    AsegurarLineaNueva;
  ActualizarTotal;
  EnfocarSegunModo;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarControlesReposicion;
var
  bReposicion: Boolean;
begin
  bReposicion := FModo = mtReposicion;
  lblVentasDesde.Visible := bReposicion;
  dteVentasDesde.Visible := bReposicion;
  lblVentasHasta.Visible := bReposicion;
  dteVentasHasta.Visible := bReposicion;
  btnCargarVentas.Visible := bReposicion;
  if bReposicion then
  begin
    pnlTop.Height := MulDiv(
      ALTO_CABECERA_REPOSICION_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    InicializarRangoVentasReposicion;
  end
  else
    pnlTop.Height := MulDiv(
      ALTO_CABECERA_NORMAL_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  btnF12.Enabled := not bReposicion;
end;

procedure TfrmMtoOpeTraspaso.InicializarRangoVentasReposicion;
var
  dtDia: TDateTime;
begin
  dtDia := Trunc(FFecha);
  if dtDia <= 0 then
    dtDia := Date;
  dteVentasDesde.Date := dtDia;
  if dtDia = Date then
    dteVentasHasta.Date := Now
  else
    dteVentasHasta.Date := dtDia + 1;
end;

procedure TfrmMtoOpeTraspaso.InvalidarVentasReposicion;
begin
  if (FModo = mtReposicion) and Assigned(FDatos) and
     Assigned(FDatos.cdsLineas) and FDatos.cdsLineas.Active then
  begin
    if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
      FDatos.cdsLineas.Cancel;
    FDatos.cdsLineas.EmptyDataSet;
    FReposicionCargada := False;
    btnF8.Enabled := PuedeBorrarLinea;
    btnF12.Enabled := False;
    ActualizarTotal;
  end;
end;

function TfrmMtoOpeTraspaso.FechaEditada(
  AEdit: TcxDateEdit): TDateTime;
begin
  if VarIsNull(AEdit.EditValue) or VarIsEmpty(AEdit.EditValue) then
    Result := 0
  else
    Result := AEdit.Date;
end;

function TfrmMtoOpeTraspaso.ObtenerOrigenReposicion(
  out AOrigen: string): Boolean;
begin
  AOrigen := DestinoSeleccionado;
  Result := AOrigen <> '';
  if not Result then
    ShowMessage(SErrorAlmacenOrigenReposicionNoSeleccionado);
end;

function TfrmMtoOpeTraspaso.ObtenerRangoReposicion(
  out ADesde, AHasta: TDateTime): Boolean;
begin
  ADesde := FechaEditada(dteVentasDesde);
  AHasta := FechaEditada(dteVentasHasta);
  Result := (ADesde > 0) and (AHasta > 0) and (ADesde < AHasta);
  if not Result then
    ShowMessage(SErrorRangoVentasReposicionNoValido);
end;

procedure TfrmMtoOpeTraspaso.CargarVentasReposicion;
var
  Filtro: TFiltroVentasReposicion;
  Lineas: TLineasVentaReposicion;
  sOrigen: string;
  dtDesde: TDateTime;
  dtHasta: TDateTime;
begin
  if (FModo = mtReposicion) and
     ObtenerOrigenReposicion(sOrigen) and
     ObtenerRangoReposicion(dtDesde, dtHasta) then
  begin
    if Assigned(FGridCtrl) then
      FGridCtrl.AlmacenStock := sOrigen;
    Filtro := Default(TFiltroVentasReposicion);
    Filtro.Empresa := FEmpresa;
    Filtro.AlmacenDestino := FAlmacen;
    Filtro.AlmacenOrigen := sOrigen;
    Filtro.Desde := dtDesde;
    Filtro.Hasta := dtHasta;
    Lineas := FRepositorioPersistencia.ListarVentasReposicion(Filtro);
    FCargandoVentasReposicion := True;
    try
      FDatos.cdsLineas.DisableControls;
      try
        FDatos.CargarVentasReposicion(Lineas);
        FReposicionCargada := Length(Lineas) > 0;
        btnF8.Enabled := PuedeBorrarLinea;
        btnF12.Enabled := FReposicionCargada;
        ActualizarTotal;
        if FReposicionCargada then
          FDatos.cdsLineas.First;
      finally
        FDatos.cdsLineas.EnableControls;
      end;
    finally
      FCargandoVentasReposicion := False;
    end;
    ActualizarStockYFoto;
    if not FReposicionCargada then
      ShowMessage(SInfoVentasReposicionNoEncontradas);
  end;
end;

procedure TfrmMtoOpeTraspaso.EmitirReposicion;
begin
  try
    EmitirReposicionInterna;
  except
    on E: EValidacionTraspaso do
      ShowMessage(E.Message);
  end;
end;

procedure TfrmMtoOpeTraspaso.EmitirReposicionInterna;
var
  sOrigen: string;
  sNumero: string;
  sSerie: string;
  dtDesde: TDateTime;
  dtHasta: TDateTime;
begin
  if not FReposicionCargada then
    ShowMessage(SErrorVentasReposicionNoCargadas)
  else if EmpleadoValido and
          ObtenerOrigenReposicion(sOrigen) and
          ObtenerRangoReposicion(dtDesde, dtHasta) and
           FDatos.GrabarReposicionAuto(
             sOrigen, dtDesde, dtHasta, sNumero, sSerie) then
  begin
    FReposicionCargada := False;
    btnF8.Enabled := PuedeBorrarLinea;
    btnF12.Enabled := False;
    try
      ShowMessage(Format(SInfoReposicionAutoEmitida, [sSerie, sNumero]));
      TTraspasoTicket.ImprimirSolicitud(
        PreviewTicket,
        FRepositorioTraspasoTicket,
        sNumero,
        sSerie,
        ParametrosCaja.ImpresoraCaja);
    finally
      AplicarModo(mtReposicion);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.AsegurarLineaNueva;
begin
  // Deja una linea en blanco al final para teclear/escanear el siguiente
  // articulo en el grid (sustituye a la NewItemRow).
  if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
    FDatos.cdsLineas.Post;
  if FDatos.cdsLineas.IsEmpty or
     (Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '') then
  begin
    FDatos.cdsLineas.Append;
    FDatos.cdsLineas.Post;
  end;
end;

procedure TfrmMtoOpeTraspaso.FormKeyPress(Sender: TObject; var Key: Char);
begin
  // Toda la deteccion (trama STX/ETX + rafaga por velocidad) la lleva el
  // lector; el codigo leido llega luego por OnCodigoLeido.
  FLector.KeyPress(Key);
end;

procedure TfrmMtoOpeTraspaso.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  ProcesarLecturaScanner(ACodigo);
end;

// El lector permanece pasivo si el foco esta en la rejilla de lineas (ahi la
// lectura la resuelve inLibGridArticulos a nivel de celda).
function TfrmMtoOpeTraspaso.LectorEsControlRejilla(AControl: TControl): Boolean;
var
  C: TControl;
begin
  Result := False;
  C := AControl;
  while (C <> nil) and (not Result) do
  begin
    if C = FGrid then
      Result := True;
    C := C.Parent;
  end;
end;

procedure TfrmMtoOpeTraspaso.ProcesarLecturaScanner(const ACodigo: string);
begin
  // Alta por lectura de pistola con framing STX/ETX. La consolidacion (sumar
  // si la SKU ya esta) la hace GridResuelto, que es el punto comun para todas
  // las vias de resolucion (celda Codigo+CR, STX/ETX o teclado).
  if ModoPermiteCargaManual and (Trim(ACodigo) <> '') and
     Assigned(FDatos) and
     Assigned(FDatos.cdsLineas) and FDatos.cdsLineas.Active then
  begin
    AsegurarLineaNueva;
    FDatos.cdsLineas.Last;
    ResolverEntradaModo(Trim(ACodigo));
    // Dejamos el grid enfocado y el editor de articulo abierto para encadenar
    // lecturas sin tener que pulsar Enter (el grid queda en modo edicion).
    if (FGrid <> nil) and FGrid.CanFocus then
      FGrid.SetFocus;
    MostrarEditorModo;
  end;
end;

function TfrmMtoOpeTraspaso.ConsolidarSiExiste(const ASku: string): Boolean;
var
  Clon: TClientDataSet;
begin
  // Si la SKU ya esta en una linea, le sumamos 1 a la cantidad y no creamos
  // otra (mismo comportamiento que caja). Clon para no mover el cursor visible.
  Result := False;
  if Trim(ASku) <> '' then
  begin
    Clon := TClientDataSet.Create(nil);
    try
      Clon.CloneCursor(FDatos.cdsLineas, True);
      Clon.First;
      while (not Clon.Eof) and (not Result) do
      begin
        // Saltamos la linea actual (la que se acaba de resolver) por RecNo:
        // solo sumamos sobre OTRA linea con la misma SKU ya grabada.
        if (Clon.FieldByName('CODIGO_UNIDAD').AsString = ASku) and
           (Clon.RecNo <> FDatos.cdsLineas.RecNo) then
        begin
          Clon.Edit;
          Clon.FieldByName('CANTIDAD').AsFloat :=
            Clon.FieldByName('CANTIDAD').AsFloat + 1;
          Clon.Post;
          ActualizarTotal;
          Result := True;
        end;
        Clon.Next;
      end;
    finally
      FreeAndNil(Clon);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.EnfocarSegunModo;
begin
  // Solicitar/Reposicion: foco en el origen elegido. Atender abre el modal de
  // solicitudes abiertas. Traspaso deja el foco en la rejilla.
  // Solo si el form ya es visible: AplicarModo se llama tambien desde
  // PrepararValores (antes del ShowModal), y enfocar/abrir modal sobre una
  // ventana invisible lanza EInvalidOperation.
  if Showing then
  begin
    case FModo of
      mtSolicitar, mtReposicion:
        if cboDestino.CanFocus then
          cboDestino.SetFocus;
      mtAtender:
        AbrirModalSolicitudes;
      mtTraspaso:
        if (FGrid <> nil) and FGrid.CanFocus then
        begin
          FGrid.SetFocus;
          MostrarEditorModo;
        end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnModoClick(Sender: TObject);
begin
  AplicarModo(TModoTraspaso((Sender as TComponent).Tag));
end;

procedure TfrmMtoOpeTraspaso.btnMisPeticionesClick(Sender: TObject);
begin
  AbrirMisPeticiones;
end;

procedure TfrmMtoOpeTraspaso.CargarCombo;
begin
  cboDestino.Properties.Items.Clear;
  FComboCodigos.Clear;
  // En Atender la solicitud se elige por el modal (F7); el desplegable solo
  // lista almacenes en Traspaso, Solicitar y Reposiciones.
  if FModo <> mtAtender then
    CargarAlmacenesDestino;
end;

procedure TfrmMtoOpeTraspaso.CargarAlmacenesDestino;
var
  Almacenes: TAlmacenesDestinoTraspaso;
  Almacen: TAlmacenDestinoTraspaso;
begin
  // Destinos: cualquier almacen ESTANDAR activo salvo el propio.
  Almacenes := FRepositorioPersistencia.ListarAlmacenesDestino(FAlmacen);
  for Almacen in Almacenes do
  begin
    FComboCodigos.Add(Almacen.Codigo);
    cboDestino.Properties.Items.Add(
      Almacen.Codigo + ' - ' + Almacen.Nombre);
  end;
end;

function TfrmMtoOpeTraspaso.DestinoSeleccionado: string;
var
  sTexto, sCodigo: string;
  i, iSep: Integer;
begin
  if (cboDestino.ItemIndex >= 0) and
     (cboDestino.ItemIndex < FComboCodigos.Count) then
    Result := FComboCodigos[cboDestino.ItemIndex]
  else
  begin
    Result := '';
    sTexto := Trim(cboDestino.Text);
    i := 0;
    while (i < cboDestino.Properties.Items.Count) and
          (i < FComboCodigos.Count) and (Result = '') do
    begin
      if SameText(sTexto, Trim(cboDestino.Properties.Items[i])) then
      begin
        cboDestino.ItemIndex := i;
        Result := FComboCodigos[i];
      end;
      Inc(i);
    end;
    if (Result = '') and (sTexto <> '') then
    begin
      iSep := Pos(' - ', sTexto);
      if iSep > 0 then
        sCodigo := Trim(Copy(sTexto, 1, iSep - 1))
      else
        sCodigo := sTexto;
      i := 0;
      while (i < FComboCodigos.Count) and (Result = '') do
      begin
        if SameText(sCodigo, FComboCodigos[i]) then
        begin
          cboDestino.ItemIndex := i;
          Result := FComboCodigos[i];
        end;
        Inc(i);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ActualizarTotal;
var
  cTotal: Currency;
  bm: TBookmark;
begin
  cTotal := 0;
  if not FDatos.cdsLineas.IsEmpty then
  begin
    FDatos.cdsLineas.DisableControls;
    bm := FDatos.cdsLineas.GetBookmark;
    try
      FDatos.cdsLineas.First;
      while not FDatos.cdsLineas.Eof do
      begin
        cTotal := cTotal +
          FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
          FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
        FDatos.cdsLineas.Next;
      end;
    finally
      FDatos.cdsLineas.GotoBookmark(bm);
      FDatos.cdsLineas.FreeBookmark(bm);
      FDatos.cdsLineas.EnableControls;
    end;
  end;
  // Sin permiso de ver coste, no se muestra el importe (revela coste).
  if FVerCoste and (FModo <> mtReposicion) then
    lblTotal.Caption := Format(SCaptionImporteTraspaso, [cTotal])
  else
    lblTotal.Caption := '';
end;

procedure TfrmMtoOpeTraspaso.cboDestinoPropertiesChange(Sender: TObject);
begin
  if FModo = mtReposicion then
    InvalidarVentasReposicion;
end;

procedure TfrmMtoOpeTraspaso.dteVentasPropertiesChange(Sender: TObject);
begin
  InvalidarVentasReposicion;
end;

procedure TfrmMtoOpeTraspaso.btnCargarVentasClick(Sender: TObject);
begin
  CargarVentasReposicion;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarModalSolicitudes(
  ADialogo: TForm);
begin
  ADialogo.Caption := STituloSolicitudesPendientesAtender;
  ADialogo.Font.Assign(Font);
  ADialogo.Position := poOwnerFormCenter;
  ADialogo.BorderStyle := bsDialog;
  ADialogo.ClientWidth := 760;
  ADialogo.ClientHeight := 440;
  ADialogo.KeyPreview := True;
  ADialogo.OnKeyDown := ModalSolicitudesKeyDown;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarModalMisPeticiones(
  ADialogo: TForm;
  const ATitulo: string);
begin
  ADialogo.Caption := ATitulo;
  ADialogo.Font.Assign(Font);
  ADialogo.Position := poOwnerFormCenter;
  ADialogo.BorderStyle := bsDialog;
  ADialogo.ClientWidth := 900;
  ADialogo.ClientHeight := 560;
  ADialogo.KeyPreview := True;
end;

function TfrmMtoOpeTraspaso.CrearPanelBotonesSolicitudes(
  ADialogo: TForm): TPanel;
begin
  Result := TPanel.Create(ADialogo);
  Result.Parent := ADialogo;
  Result.Align := alBottom;
  Result.Height := 60;
  Result.BevelOuter := bvNone;
end;

function TfrmMtoOpeTraspaso.CrearRejillaSolicitudes(
  ADialogo: TForm): TcxGrid;
var
  oFuente: TDataSource;
  oVista: TcxGridDBTableView;
begin
  Result := CrearRejillaDatos(
    ADialogo,
    ADialogo,
    FQModalSolic,
    oFuente,
    oVista);
  TitularColumnasSolicitudes(oVista);
end;

function TfrmMtoOpeTraspaso.CrearRejillaDatos(
  ADialogo: TForm;
  AParent: TWinControl;
  ADatos: TDataSet;
  out AFuente: TDataSource;
  out AVista: TcxGridDBTableView): TcxGrid;
begin
  Result := TcxGrid.Create(ADialogo);
  Result.Parent := AParent;
  Result.Align := alClient;
  AVista :=
    Result.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  Result.Levels.Add.GridView := AVista;
  AFuente := TDataSource.Create(ADialogo);
  AFuente.DataSet := ADatos;
  AVista.DataController.DataSource := AFuente;
  AVista.OptionsData.Editing := False;
  AVista.OptionsData.Inserting := False;
  AVista.OptionsData.Deleting := False;
  AVista.OptionsSelection.CellSelect := False;
  AVista.OptionsView.GroupByBox := False;
  AVista.OptionsView.ColumnAutoWidth := True;
  AVista.DataController.CreateAllItems;
end;

procedure TfrmMtoOpeTraspaso.TitularColumnasSolicitudes(
  AVista: TcxGridDBTableView);
var
  iColumna: Integer;
  sCampo: string;
begin
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    sCampo := AVista.Columns[iColumna].DataBinding.FieldName;
    if SameText(sCampo, 'NUMERO_TRSOL') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColNumeroSolicitud;
      AVista.Columns[iColumna].Width := 90;
    end
    else if SameText(sCampo, 'SERIE_TRSOL') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColSerieSolicitud;
      AVista.Columns[iColumna].Width := 60;
    end
    else if SameText(sCampo, 'FECHA_TRSOL') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColFechaSolicitud;
      AVista.Columns[iColumna].PropertiesClass := TcxDateEditProperties;
      TcxDateEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          'dd/mm/yyyy hh:nn:ss';
      AVista.Columns[iColumna].Width := 165;
    end
    else if SameText(sCampo, 'CODIGO_ALM_DESTINO_TRSOL') then
      AVista.Columns[iColumna].Caption := SCaptionColPideAlmacen
    else if SameText(sCampo, 'CODIGO_ALM_ORIGEN_TRSOL') then
      AVista.Columns[iColumna].Caption :=
        SCaptionAlmacenSolicitadoTraspaso
    else if SameText(sCampo, 'ESTADO_TRSOL') then
      AVista.Columns[iColumna].Caption := SCaptionColEstadoSolicitud
    else if SameText(sCampo, 'LINEAS_PEND_TRSOL') then
      AVista.Columns[iColumna].Caption :=
        SCaptionLineasPendientesTraspaso;
  end;
end;

procedure TfrmMtoOpeTraspaso.TitularColumnasLineasSolicitud(
  AVista: TcxGridDBTableView);
var
  iColumna: Integer;
  sCampo: string;
begin
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    sCampo := AVista.Columns[iColumna].DataBinding.FieldName;
    if SameText(sCampo, 'NUMERO_TRSOL_TRSOLLIN') or
       SameText(sCampo, 'SERIE_TRSOL_TRSOLLIN') or
       SameText(sCampo, 'ESATENDIDA_TRSOLLIN') then
      AVista.Columns[iColumna].Visible := False
    else if SameText(sCampo, 'LINEA_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionLineaPeticionTraspaso;
      AVista.Columns[iColumna].Width := 50;
    end
    else if SameText(sCampo, 'CODIGO_ART_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColArticulo;
      AVista.Columns[iColumna].Width := 100;
    end
    else if SameText(sCampo, 'CODIGO_UNIDAD_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColSku;
      AVista.Columns[iColumna].Width := 145;
    end
    else if SameText(sCampo, 'DESCRIPCION_ART') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionColDescripcionTraspaso;
      AVista.Columns[iColumna].Width := 220;
    end
    else if SameText(sCampo, 'CANTIDAD_PEDIDA_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColPedidasTraspaso;
      AVista.Columns[iColumna].PropertiesClass :=
        TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          '#,##0.###';
      AVista.Columns[iColumna].Width := 75;
    end
    else if SameText(sCampo, 'CANTIDAD_SERVIDA_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionServidasPeticionTraspaso;
      AVista.Columns[iColumna].PropertiesClass :=
        TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          '#,##0.###';
      AVista.Columns[iColumna].Width := 75;
    end
    else if SameText(sCampo, 'CANTIDAD_PENDIENTE_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionNoServidasPeticionTraspaso;
      AVista.Columns[iColumna].PropertiesClass :=
        TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          '#,##0.###';
      AVista.Columns[iColumna].Width := 85;
    end
    else if SameText(sCampo, 'MOTIVO_RECHAZO_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionColMotivoRechazoTraspaso;
      AVista.Columns[iColumna].Width := 190;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.CrearBotonesSolicitudes(
  ADialogo: TForm;
  APanel: TPanel);
var
  oAtender: TButton;
  oImprimir: TButton;
  oNoAtender: TButton;
  oSalir: TButton;
begin
  oAtender := TButton.Create(ADialogo);
  oAtender.Parent := APanel;
  oAtender.SetBounds(14, 12, 160, 36);
  oAtender.Caption := TextoBotonConAtajo(SCaptionAtender, 'F7');
  oAtender.ModalResult := mrYes;
  oAtender.Default := True;
  oNoAtender := TButton.Create(ADialogo);
  oNoAtender.Parent := APanel;
  oNoAtender.SetBounds(186, 12, 160, 36);
  oNoAtender.Caption := TextoBotonConAtajo(SCaptionNoAtender, 'F6');
  oNoAtender.ModalResult := mrNo;
  oImprimir := TButton.Create(ADialogo);
  oImprimir.Parent := APanel;
  oImprimir.SetBounds(358, 12, 160, 36);
  oImprimir.Caption := SCaptionImprimir;
  oImprimir.OnClick := ModalImprimirClick;
  oSalir := TButton.Create(ADialogo);
  oSalir.Parent := APanel;
  oSalir.SetBounds(606, 12, 140, 36);
  oSalir.Caption := 'ESC ' + Trim(
    StringReplace(SCaptionSalir, '&', '', [rfReplaceAll]));
  oSalir.Cancel := True;
  oSalir.ModalResult := mrCancel;
end;

procedure TfrmMtoOpeTraspaso.CrearBotonesMisPeticiones(
  ADialogo: TForm;
  APanel: TPanel);
var
  oReimprimir: TButton;
  oSalir: TButton;
begin
  oReimprimir := TButton.Create(ADialogo);
  oReimprimir.Parent := APanel;
  oReimprimir.SetBounds(14, 12, 160, 36);
  oReimprimir.Caption := 'Reimprimir';
  oReimprimir.OnClick := ModalReimprimirClick;
  oSalir := TButton.Create(ADialogo);
  oSalir.Parent := APanel;
  oSalir.SetBounds(746, 12, 140, 36);
  oSalir.Caption := 'ESC ' + Trim(
    StringReplace(SCaptionSalir, '&', '', [rfReplaceAll]));
  oSalir.Cancel := True;
  oSalir.ModalResult := mrCancel;
end;

procedure TfrmMtoOpeTraspaso.ModalSolicitudesKeyDown(
  Sender: TObject;
  var Key: Word;
  Shift: TShiftState);
begin
  if Shift = [] then
  begin
    case Key of
      VK_F6:
      begin
        Key := 0;
        TForm(Sender).ModalResult := mrNo;
      end;
      VK_F7:
      begin
        Key := 0;
        TForm(Sender).ModalResult := mrYes;
      end;
      VK_ESCAPE:
      begin
        Key := 0;
        TForm(Sender).ModalResult := mrCancel;
      end;
    end;
  end;
end;

function TfrmMtoOpeTraspaso.MostrarModalSolicitudes(
  out ANumero, ASerie: string): Integer;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oRejilla: TcxGrid;
begin
  ANumero := '';
  ASerie := '';
  oDialogo := TForm.CreateNew(Self);
  try
    ConfigurarModalSolicitudes(oDialogo);
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oRejilla := CrearRejillaSolicitudes(oDialogo);
    CrearBotonesSolicitudes(oDialogo, oPanelBotones);
    oDialogo.ActiveControl := oRejilla;
    Result := oDialogo.ShowModal;
    ANumero := FQModalSolic.FieldByName('NUMERO_TRSOL').AsString;
    ASerie := FQModalSolic.FieldByName('SERIE_TRSOL').AsString;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoOpeTraspaso.MostrarModalMisPeticiones(
  const ATitulo: string);
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oPanelMaestro: TPanel;
  oPanelDetalle: TPanel;
  oTituloMaestro: TPanel;
  oTituloDetalle: TPanel;
  oRejillaMaestro: TcxGrid;
  oRejillaDetalle: TcxGrid;
  oFuenteMaestro: TDataSource;
  oFuenteDetalle: TDataSource;
  oVistaMaestro: TcxGridDBTableView;
  oVistaDetalle: TcxGridDBTableView;
  DatosLineas: TDataSet;
begin
  DatosLineas := nil;
  oDialogo := TForm.CreateNew(Self);
  try
    ConfigurarModalMisPeticiones(oDialogo, ATitulo);
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oPanelMaestro := TPanel.Create(oDialogo);
    oPanelMaestro.Parent := oDialogo;
    oPanelMaestro.Align := alTop;
    oPanelMaestro.Height := 220;
    oPanelMaestro.BevelOuter := bvNone;
    oTituloMaestro := TPanel.Create(oDialogo);
    oTituloMaestro.Parent := oPanelMaestro;
    oTituloMaestro.Align := alTop;
    oTituloMaestro.Height := 28;
    oTituloMaestro.BevelOuter := bvNone;
    oTituloMaestro.Caption :=
      SCaptionPeticionesRealizadasTraspaso;
    oTituloMaestro.Font.Style :=
      oTituloMaestro.Font.Style + [fsBold];
    oRejillaMaestro := CrearRejillaDatos(
      oDialogo,
      oPanelMaestro,
      FQModalSolic,
      oFuenteMaestro,
      oVistaMaestro);
    TitularColumnasSolicitudes(oVistaMaestro);
    DatosLineas :=
      FDatos.QueryLineasSolicitud(oFuenteMaestro);
    try
      if not DatosLineas.Active then
        DatosLineas.Open;
      oPanelDetalle := TPanel.Create(oDialogo);
      oPanelDetalle.Parent := oDialogo;
      oPanelDetalle.Align := alClient;
      oPanelDetalle.BevelOuter := bvNone;
      oTituloDetalle := TPanel.Create(oDialogo);
      oTituloDetalle.Parent := oPanelDetalle;
      oTituloDetalle.Align := alTop;
      oTituloDetalle.Height := 28;
      oTituloDetalle.BevelOuter := bvNone;
      oTituloDetalle.Caption :=
        SCaptionArticulosPeticionTraspaso;
      oTituloDetalle.Font.Style :=
        oTituloDetalle.Font.Style + [fsBold];
      oRejillaDetalle := CrearRejillaDatos(
        oDialogo,
        oPanelDetalle,
        DatosLineas,
        oFuenteDetalle,
        oVistaDetalle);
      oRejillaDetalle.TabOrder := 0;
      TitularColumnasLineasSolicitud(oVistaDetalle);
      CrearBotonesMisPeticiones(oDialogo, oPanelBotones);
      oDialogo.ActiveControl := oRejillaMaestro;
      oDialogo.ShowModal;
    finally
      FreeAndNil(DatosLineas);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoOpeTraspaso.PonerCantidadesSolicitudACero;
begin
  FDatos.cdsLineas.DisableControls;
  try
    FDatos.cdsLineas.First;
    while not FDatos.cdsLineas.Eof do
    begin
      if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <>
         '' then
      begin
        FDatos.cdsLineas.Edit;
        FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := 0;
        FDatos.cdsLineas.Post;
      end;
      FDatos.cdsLineas.Next;
    end;
  finally
    FDatos.cdsLineas.EnableControls;
  end;
end;

procedure TfrmMtoOpeTraspaso.AplicarSolicitudSeleccionada(
  const ANumero, ASerie: string;
  AResultadoModal: Integer);
begin
  if (ANumero <> '') and
     ((AResultadoModal = mrYes) or (AResultadoModal = mrNo)) then
  begin
    if FDatos.CargarSolicitud(ANumero, ASerie) then
    begin
      txtOrigen.Text :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
      cboDestino.Text :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString;
      if AResultadoModal = mrNo then
        PonerCantidadesSolicitudACero;
      ActualizarTotal;
    end
    else
      ShowMessage(SErrorCargarSolicitudTraspaso);
  end;
end;

procedure TfrmMtoOpeTraspaso.AbrirModalSolicitudes;
var
  iResultado: Integer;
  sNumero: string;
  sSerie: string;
begin
  // Modal de solicitudes PENDIENTES que me toca atender. Tres acciones:
  //   Atender    -> trae la peticion con las cantidades pedidas (editables).
  //   No atender -> trae la peticion y la deniega entera (pide motivo).
  //   Imprimir   -> saca el ticket de la peticion seleccionada (sin cerrar).
  // Se construye en codigo (sin .dfm) porque el buscador generico no admite
  // botones de accion. FQModalSolic vive durante el modal para el boton
  // Imprimir y se libera al final.
  FQModalSolic := FDatos.QuerySolicitudesAbiertas;
  try
    if not FQModalSolic.Active then
      FQModalSolic.Open;
    if FQModalSolic.IsEmpty then
      ShowMessage(SErrorSolicitudesTraspasoPendientesNoEncontradas)
    else
    begin
      iResultado := MostrarModalSolicitudes(sNumero, sSerie);
      AplicarSolicitudSeleccionada(sNumero, sSerie, iResultado);
    end;
  finally
    FreeAndNil(FQModalSolic);
  end;
end;

procedure TfrmMtoOpeTraspaso.ModalImprimirClick(Sender: TObject);
begin
  ImprimirSolicitudModal(False);
end;

procedure TfrmMtoOpeTraspaso.ModalReimprimirClick(Sender: TObject);
begin
  ImprimirSolicitudModal(True);
end;

procedure TfrmMtoOpeTraspaso.ImprimirSolicitudModal(
  ADuplicado: Boolean);
var
  sNum, sSer: string;
begin
  if Assigned(FQModalSolic) and FQModalSolic.Active and
     (not FQModalSolic.IsEmpty) and
     Assigned(FRepositorioTraspasoTicket) then
  begin
    sNum := Trim(
      FQModalSolic.FieldByName('NUMERO_TRSOL').AsString);
    sSer := Trim(
      FQModalSolic.FieldByName('SERIE_TRSOL').AsString);
    if (sNum <> '') and (sSer <> '') then
    begin
      Screen.Cursor := crHourGlass;
      try
        TTraspasoTicket.ImprimirSolicitud(
          PreviewTicket,
          FRepositorioTraspasoTicket,
          sNum,
          sSer,
          ParametrosCaja.ImpresoraCaja,
          ADuplicado);
      finally
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.CerrarSolicitudCargada;
begin
  // Cierra la solicitud cargada (parcial) dejando lineas sin atender. Solo
  // tiene sentido en modo Atender con una solicitud traida.
  if FModo = mtAtender then
  begin
    if Trim(
      FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString) = '' then
      ShowMessage(StringReplace(
        SErrorSolicitudTraspasoCerrarNoCargada,
        'F8',
        'F7',
        [rfReplaceAll]))
    else if MessageDlg(SPreguntaCerrarSolicitudTraspaso,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if FDatos.CerrarSolicitud then
      begin
        ShowMessage(SInfoSolicitudTraspasoCerrada);
        AplicarModo(mtAtender);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.DenegarSolicitudCargada;
var
  sMotivo: string;
begin
  // Deniega TODA la solicitud cargada (atajo F4): pide un motivo, lo marca en
  // cada linea (servir 0) y la resuelve como DENEGADO TOTAL sin mover stock. El
  // solicitante lo vera en su historico (Mayus+F7). Para denegar solo algunas
  // lineas,// sirve unas con cantidad y deja otras a 0 con su motivo,y pulsa
  // F12.
  if FModo <> mtAtender then
    ShowMessage(SErrorDenegarSolicitudTraspasoModoNoValido)
  else if Trim(FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString) = '' then
    ShowMessage(StringReplace(
      SErrorSolicitudTraspasoDenegarNoCargada,
      'F8',
      'F7',
      [rfReplaceAll]))
  else
  begin
    sMotivo := '';
    if InputQuery(STituloDenegarSolicitudTraspaso,
                  SSolicitudMotivoRechazoTraspaso, sMotivo) then
    begin
      if Trim(sMotivo) = '' then
        ShowMessage(SErrorMotivoDenegacionTraspasoNoIndicado)
      else
      begin
        FDatos.cdsLineas.DisableControls;
        try
          FDatos.cdsLineas.First;
          while not FDatos.cdsLineas.Eof do
          begin
            if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
               <> '' then
            begin
              FDatos.cdsLineas.Edit;
              FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := 0;
              FDatos.cdsLineas.FieldByName('MOTIVO').AsString := sMotivo;
              FDatos.cdsLineas.Post;
            end;
            FDatos.cdsLineas.Next;
          end;
        finally
          FDatos.cdsLineas.EnableControls;
        end;
        try
          if FDatos.GrabarDenegacion then
          begin
            ShowMessage(SInfoPeticionTraspasoDenegada);
            AplicarModo(mtAtender);
          end;
        except
          // Validaciones de negocio: aviso normal (EValidacionTraspaso).
          on E: EValidacionTraspaso do
            ShowMessage(E.Message);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.AbrirMisPeticiones;
begin
  AbrirHistoricoSolicitudes(FAlmacen, STituloMisPeticionesTraspaso);
end;

procedure TfrmMtoOpeTraspaso.AbrirHistoricoSolicitudes(
  const AAlmacen, ATitulo: string);
begin
  // Histórico maestro/detalle de las peticiones hechas desde el almacén.
  FQModalSolic := FDatos.QueryMisPeticiones(AAlmacen);
  try
    if not FQModalSolic.Active then
      FQModalSolic.Open;
    if FQModalSolic.IsEmpty then
      ShowMessage(SInfoSinPeticionesTraspaso)
    else
      MostrarModalMisPeticiones(ATitulo);
  finally
    FreeAndNil(FQModalSolic);
  end;
end;

procedure TfrmMtoOpeTraspaso.MostrarHistoricoSolicitudes(
  const AAlmacen, ATitulo: string);
begin
  AbrirHistoricoSolicitudes(AAlmacen, ATitulo);
end;

procedure TfrmMtoOpeTraspaso.AvisarStockSolicitud(
  const AAlmacenOrigen: string);
var
  sAviso: string;
begin
  sAviso := FDatos.ObtenerAvisoStockOrigen(AAlmacenOrigen);
  if sAviso <> '' then
    MessageDlg(sAviso, mtWarning, [mbOK], 0);
end;

procedure TfrmMtoOpeTraspaso.EnviarSolicitud;
var
  sNum, sSer, sOrigen: string;
begin
  if EmpleadoValido then
  begin
    sOrigen := DestinoSeleccionado;
    if sOrigen = '' then
      ShowMessage(SErrorAlmacenOrigenSolicitudNoSeleccionado)
    else
    begin
      try
        // Una peticion puede enviarse aunque el almacen solicitado no tenga
        // stock en este momento; se informa sin impedir cerrar el ticket.
        AvisarStockSolicitud(sOrigen);
        if FDatos.GrabarSolicitud(sOrigen, sNum, sSer) then
        begin
          ShowMessage(Format(SInfoSolicitudTraspasoEnviada, [sSer, sNum]));
          // Ticket de la solicitud: cada SKU con stock origen / destino.
          TTraspasoTicket.ImprimirSolicitud(
                                            PreviewTicket,
                                            FRepositorioTraspasoTicket,
                                            sNum, sSer,
                                            ParametrosCaja.ImpresoraCaja);
          AplicarModo(mtSolicitar);
        end;
      except
        // Validaciones de negocio: aviso normal (vease EValidacionTraspaso).
        on E: EValidacionTraspaso do
          ShowMessage(E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoExit(Sender: TObject);
var
  bValido: Boolean;
  sCod, sNom: string;
begin
  bValido := ValidarEmpleadoActual(sCod, sNom);
  if Trim(txtEmpleado.Text) = '' then
    lblEmpleadoNombre.Caption := ''
  else if bValido then
    lblEmpleadoNombre.Caption := sNom
  else
    lblEmpleadoNombre.Caption := SCaptionEmpleadoNoEncontrado;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoButtonClick(Sender: TObject;
                                                    AButtonIndex: Integer);
begin
  // El boton "..." del editor abre el buscador de empleados.
  BuscarEmpleado;
end;

procedure TfrmMtoOpeTraspaso.BuscarEmpleado;
var
  Consulta: IResultadoConsultaCaja;
  Datos: TDataSet;
begin
  // Buscador de empleados (mismos datos y rejilla que la caja). Al elegir
  // uno,// su codigo va al campo y se valida para mostrar el nombre.
  Consulta := FRepositorioConsultas.ConsultarEmpleados;
  Datos := Consulta.DataSet;
  if BusquedaVisual.EjecutarBusquedaDataSet(
       STituloBusquedaEmpleadoTraspaso,
       Datos,
       'frmMtoEmpCajSearch') then
  begin
    txtEmpleado.Text := Datos.Fields[0].AsString;
    txtEmpleadoExit(nil);
  end;
end;

function TfrmMtoOpeTraspaso.ValidarEmpleadoActual(
  out ACodigo, ANombre: string): Boolean;
var
  sEntrada: string;
begin
  sEntrada := Trim(txtEmpleado.Text);
  if (not FEmpleadoConsultado) or
     (FEntradaEmpleadoConsultada <> sEntrada) then
  begin
    FEmpleadoConsultado := False;
    FEntradaEmpleadoConsultada := sEntrada;
    FCodigoEmpleadoConsultado := '';
    FNombreEmpleadoConsultado := '';
    FEmpleadoValidoConsultado := False;
    if sEntrada <> '' then
      FEmpleadoValidoConsultado := FDatos.ValidarEmpleado(
        sEntrada,
        FCodigoEmpleadoConsultado,
        FNombreEmpleadoConsultado);
    FEmpleadoConsultado := True;
  end;
  ACodigo := FCodigoEmpleadoConsultado;
  ANombre := FNombreEmpleadoConsultado;
  Result := FEmpleadoValidoConsultado;
end;

function TfrmMtoOpeTraspaso.EmpleadoValido: Boolean;
var
  bValido: Boolean;
  sCod, sNom: string;
begin
  bValido := ValidarEmpleadoActual(sCod, sNom);
  if Trim(txtEmpleado.Text) = '' then
  begin
    ShowMessage(SErrorEmpleadoTraspasoNoIndicado);
    Result := False;
  end
  else if bValido then
  begin
    lblEmpleadoNombre.Caption := sNom;
    if FDatos.cdsCabecera.State = dsBrowse then
      FDatos.cdsCabecera.Edit;
    FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString := sCod;
    FDatos.cdsCabecera.Post;
    Result := True;
  end
  else
  begin
    ShowMessage(Format(SErrorEmpleadoTraspasoNoEncontrado,
      [txtEmpleado.Text]));
    Result := False;
  end;
end;

// Envoltorio de la grabación: las validaciones de negocio del data module
// (stock insuficiente, líneas incompletas...) llegan como
// EValidacionTraspaso y se muestran como aviso normal, no como error no
// controlado.
procedure TfrmMtoOpeTraspaso.EjecutarTraspaso(AConTicket: Boolean);
begin
  try
    EjecutarTraspasoInterno(AConTicket);
  except
    on E: EValidacionTraspaso do
      ShowMessage(E.Message);
  end;
end;

procedure TfrmMtoOpeTraspaso.EjecutarTraspasoInterno(AConTicket: Boolean);
var
  sNumOp, sDestino, sOrigen, sEmpleado, sNumSol, sSerSol: string;
  iServidas: Integer;
  bFaltaMotivo: Boolean;
begin
  if EmpleadoValido then
  begin
    // Origen y empleado se capturan ya (la cabecera los tiene); el ticket se
    // imprime ANTES de AplicarModo, que reinicia el cds.
    sOrigen := FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    sEmpleado := FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
    if FModo = mtAtender then
    begin
      sDestino :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString;
      sNumSol := FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString;
      sSerSol := FDatos.cdsCabecera.FieldByName('SERIE_SOL').AsString;
      if sDestino = '' then
        ShowMessage(SErrorSolicitudTraspasoAtenderNoCargada)
      else
      begin
        // Reparto por linea: cuenta lo que se sirve (CANTIDAD>0) y exige motivo
        // en las que se deniegan (servir 0).
        iServidas := 0;
        bFaltaMotivo := False;
        FDatos.cdsLineas.DisableControls;
        try
          FDatos.cdsLineas.First;
          while not FDatos.cdsLineas.Eof do
          begin
            if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
               <> '' then
            begin
              if FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
                Inc(iServidas)
              else if Trim(FDatos.cdsLineas.FieldByName('MOTIVO').AsString)
                      = '' then
                bFaltaMotivo := True;
            end;
            FDatos.cdsLineas.Next;
          end;
        finally
          FDatos.cdsLineas.EnableControls;
        end;
        if bFaltaMotivo then
          ShowMessage(SErrorMotivoLineasTraspasoNoIndicado)
        else if iServidas > 0 then
        begin
          // Hay algo que servir: traspaso de lo servido; lo denegado queda
          // registrado con su motivo. Estado COMPLETADO TOTAL/PARCIAL.
          AvisarStockSolicitud(sOrigen);
          if FDatos.GrabarTraspaso(sDestino, sNumOp, sNumSol, sSerSol) then
          begin
            ShowMessage(Format(SInfoSolicitudTraspasoAtendida, [sNumOp]));
            if AConTicket then
              TTraspasoTicket.ImprimirTraspaso(
                PreviewTicket,
                FRepositorioTraspasoTicket,
                sNumOp,
                sOrigen,
                sDestino,
                sEmpleado, FDatos.cdsLineas, ParametrosCaja.ImpresoraCaja);
            AplicarModo(mtAtender);
          end;
        end
        else if MessageDlg(SPreguntaDenegarPeticionTraspasoCompleta,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          // Todo a 0: denegacion total (con el motivo por linea), sin traspaso.
          if FDatos.GrabarDenegacion then
          begin
            ShowMessage(SInfoPeticionTraspasoDenegada);
            AplicarModo(mtAtender);
          end;
        end;
      end;
    end
    else
    begin
      sDestino := DestinoSeleccionado;
      if sDestino = '' then
        ShowMessage(SErrorAlmacenDestinoTraspasoNoSeleccionado)
      else if FDatos.GrabarTraspaso(sDestino, sNumOp) then
      begin
        ShowMessage(Format(SInfoTraspasoGrabado, [sNumOp]));
        if AConTicket then
          TTraspasoTicket.ImprimirTraspaso(
            PreviewTicket,
            FRepositorioTraspasoTicket,
            sNumOp,
            sOrigen,
            sDestino,
            sEmpleado, FDatos.cdsLineas, ParametrosCaja.ImpresoraCaja);
        AplicarModo(mtTraspaso);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.QuitarLinea;
begin
  // En reposicion se permite retirar lineas cargadas antes de emitirla.
  if PuedeBorrarLinea and (not FDatos.cdsLineas.IsEmpty) then
  begin
    FDatos.cdsLineas.Delete;
    if FModo = mtReposicion then
    begin
      FReposicionCargada := not FDatos.cdsLineas.IsEmpty;
      btnF8.Enabled := PuedeBorrarLinea;
      btnF12.Enabled := FReposicionCargada;
    end
    else
      AsegurarLineaNueva;
    ActualizarTotal;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnF11Click(Sender: TObject);
begin
  if FModo in [mtTraspaso, mtAtender] then
    EjecutarTraspaso(False);
end;

procedure TfrmMtoOpeTraspaso.btnF8Click(Sender: TObject);
begin
  QuitarLinea;
end;

procedure TfrmMtoOpeTraspaso.btnF12Click(Sender: TObject);
begin
  if FModo = mtSolicitar then
    EnviarSolicitud
  else if FModo = mtReposicion then
    EmitirReposicion
  else
    EjecutarTraspaso(True);
end;

procedure TfrmMtoOpeTraspaso.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // El lector cierra la lectura por velocidad (rafaga + Enter rapido) y consume
  // el VK_RETURN si procede, antes de la gestion de teclas de funcion.
  FLector.KeyDown(Key, Shift);
  case Key of
    VK_F1:
      if Shift = [] then
      begin
        Key := 0;
        if ModoPermiteCargaManual then
          AlternarModoEntrada;
      end;
    VK_F3:
    begin
      Key := 0;
      BuscarContextual;
    end;
    VK_F4:
    begin
      Key := 0;
      DenegarSolicitudCargada;
    end;
    VK_F5:
    begin
      Key := 0;
      AplicarModo(mtReposicion);
    end;
    VK_F6:
    begin
      Key := 0;
      AplicarModo(mtSolicitar);
    end;
    VK_F7:
    begin
      Key := 0;
      if ssShift in Shift then
        AbrirMisPeticiones
      else if FModo = mtAtender then
        AbrirModalSolicitudes
      else
        AplicarModo(mtAtender);
    end;
    VK_F8:
    begin
      Key := 0;
      btnF8Click(nil);
    end;
    // F9 queda reservada en caja para abrir el cajon; cerrar la solicitud
    // cargada pasa de F9 a F10.
    VK_F10:
    begin
      Key := 0;
      CerrarSolicitudCargada;
    end;
    VK_F11:
    begin
      Key := 0;
      btnF11Click(nil);
    end;
    VK_F12:
    begin
      Key := 0;
      btnF12Click(nil);
    end;
    VK_ESCAPE:
    begin
      Key := 0;
      Close;
    end;
  end;
  inherited;
end;

end.
