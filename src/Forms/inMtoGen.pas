{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGen                                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario base de los mantenimientos de Factuzam.                        }
{    Define grid, navegador, edicion CRUD y comportamiento heredable.          }
{******************************************************************************}
unit inMtoGen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxSkinsCore,
  dxSkinsDefaultPainters, cxPC, cxControls,
  Vcl.ExtCtrls, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxNavigator, cxDBNavigator, Vcl.StdCtrls, Vcl.Buttons,
  cxContainer, cxEdit, cxLabel, Vcl.Menus, cxButtons,
  dxSkinsLookAndFeelPainter, cxStyles, dxSkinscxPCPainter,
  dxSkinsForm, cxCustomData, cxFilter, cxData, cxDataStorage, dxDateRanges,
  Data.DB, cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridDBDataDefinitions, cxGrid, dxmdaset,
  cxTextEdit, dxBevel,
  inLibDevExp, cxGridExportLink, inLibUser, System.UITypes, System.Types,
  inLibPerfilesUsuarioIntf, inLibAnfitrionMtoIntf, Uni, inLibDir,
  inLibDatasets,
  Data.DBCommon, inLibWin,
  UniDataConn, cxBlobEdit, dxCore, dxScrollbarAnnotations, cxRadioGroup,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs, dxSkinBlue,
  cxDBEdit, dxSkinBasic, dxSkinBlack,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, System.Actions, Vcl.ActnList,
  inLibPermisosIntf, inLibVentanaEmbebidaIntf,
  inLibGestorFiltrosMto, inLibGestorPerfilesMto,
  inLibGestorGuiasGridMto, inLibGestorTareasMto,
  inLibGestorArticulosMto, inLibInteraccionDatosIntf,
  inLibMtoGenAplicacionIntf;
type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  THackWinControl = class(TWinControl);
  // Resultado del dialogo de borrado: cancelar, desactivar o borrar igual.
  TAccionBorrado = (abContinuar, abDesactivar, abCancelar);
  TfrmMtoGen = class(TfrmBase, IMantenimientoEmbebido)
    pButtonPage: TPanel;
    pButtonRightBar: TPanel;
    pButtonBDStat: TPanel;
    pButtonGen: TPanel;
    pnStateDataSet: TPanel;
    lblEditMode: TcxLabel;
    pcPantalla: TcxPageControl;
    tsLista: TcxTabSheet;
    tsFicha: TcxTabSheet;
    btnGrabar: TcxButton;
    btnCancelar: TcxButton;
    cxGrdDBTabPrin: TcxGridDBTableView;
    cxGrdLvPrin: TcxGridLevel;
    cxgrdPrincipal: TcxGrid;
    dsTablaG: TDataSource;
    pnlTopPage: TPanel;
    pnlTopGrid: TPanel;
    sbFiltros: TSpeedButton;
    sbExportExcel: TSpeedButton;
    edtBusqGlobal: TcxTextEdit;
    nvNavegador: TcxDBNavigator;
    lblTextoaBuscar: TcxLabel;
    tsPerfil: TcxTabSheet;
    pnlPerfilTop: TPanel;
    edtPerfilBusq: TcxTextEdit;
    lblTextoaBuscarPerfil: TcxLabel;
    pnlPerfilDetail: TPanel;
    cxgrdPerfil: TcxGrid;
    tvPerfil: TcxGridDBTableView;
    cxgrdlvlPerfil: TcxGridLevel;
    btnCargarColumnas: TcxButton;
    btnCargarCaptions: TcxButton;
    btnCargarVblesGlob: TcxButton;
    tvPerfilUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    tvPerfilKEY_PERFILES: TcxGridDBColumn;
    tvPerfilSUBKEY_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_TEXT_PERFILES: TcxGridDBColumn;
    tvPerfilTYPE_BLOB_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_BLOB_PERFILES: TcxGridDBColumn;
    rbBBDD: TcxRadioButton;
    rbGrid: TcxRadioButton;
    sbGrabarGrid: TSpeedButton;
    sbResetGrid: TSpeedButton;
    sbBestFit: TSpeedButton;
    pnlDataSetName: TPanel;
    lblTablaOrigen: TcxLabel;
    saveDialog: TdxSaveFileDialog;
    pmFiltros: TPopupMenu;
    tmrBusqGlobal: TTimer;
    alMtoGen: TActionList;
    actEliminarRegistro: TAction;
    actRegistroAnterior: TAction;
    actRegistroSiguiente: TAction;
    actInsertarRegistro: TAction;
    actPrimerRegistro: TAction;
    actUltimoRegistro: TAction;
    actEditarRegistro: TAction;
    actGrabarRegistro: TAction;
    actFotoArticulo: TAction;
    actConsultaStock: TAction;
    actRetrocederBloque: TAction;
    actAvanzarBloque: TAction;
    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinDblClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure sbExportExcelClick(Sender: TObject);
    procedure sbFiltrosClick(Sender: TObject);
    procedure btnCargarColumnasClick(Sender: TObject);
    procedure btnCargarCaptionsClick(Sender: TObject);
    procedure btnCargarVblesGlobClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rbGridClick(Sender: TObject);
    procedure rbBBDDClick(Sender: TObject);
    procedure pcPantallaPageChanging(Sender: TObject;
                                     NewPage: TcxTabSheet;
                                     var AllowChange: Boolean);
    procedure sbResetGridClick(Sender: TObject);
    procedure sbBestFitClick(Sender: TObject);
    procedure sbGrabarGridClick(Sender: TObject);
    procedure edtBusqGlobalPropertiesChange(Sender: TObject);
    procedure tmrBusqGlobalTimer(Sender: TObject);
    procedure tsFichaShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSalirClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actEliminarRegistroExecute(Sender: TObject);
    procedure actEliminarRegistroUpdate(Sender: TObject);
    procedure actNavBrowseUpdate(Sender: TObject);
    procedure actRegistroAnteriorExecute(Sender: TObject);
    procedure actRegistroSiguienteExecute(Sender: TObject);
    procedure actInsertarRegistroExecute(Sender: TObject);
    procedure actPrimerRegistroExecute(Sender: TObject);
    procedure actUltimoRegistroExecute(Sender: TObject);
    procedure actEditarRegistroExecute(Sender: TObject);
    procedure actGrabarRegistroExecute(Sender: TObject);
    procedure actGrabarRegistroUpdate(Sender: TObject);
    procedure actFotoArticuloExecute(Sender: TObject);
    procedure actConsultaStockExecute(Sender: TObject);
    procedure actAvanzarBloqueExecute(Sender: TObject);
    procedure actRetrocederBloqueExecute(Sender: TObject);
  private
    // Conexion propia solicitada al servicio al crear el data module. Se
    // reasigna a todas las queries/SPs via TdmBase.ReasignarConexion. Asi
    // dos pestañas dejan de serializarse sobre una misma TUniConnection.
    // Se libera en Destroy DESPUES del data module para que los Close
    // implicitos de las queries no queden colgando.
    FConn: TUniConnection;
    FCasoUsoGuardado: ICasoUsoGuardadoMtoGen;
    // Hooks del dataset principal original (en el data module).
    FBeforeInsertOrig: TDataSetNotifyEvent;
    FBeforeEditOrig: TDataSetNotifyEvent;
    FBeforePostOrig: TDataSetNotifyEvent;
    FBeforeDeleteOrig: TDataSetNotifyEvent;
    FGuardianBorradoInstalado: Boolean;
    FDesactivandoPorBorrado: Boolean;
    FGestorFiltros: TGestorFiltrosMto;
    FGestorPerfiles: TGestorPerfilesMto;
    FGestorGuias: TGestorGuiasGridMto;
    FGestorTareas: TGestorTareasMto;
    FGestorArticulos: TGestorArticulosMto;
    function GetConexionTrabajo: TUniConnection;
    function AplicacionCerrando: Boolean;
    function ObtenerConsultaGuias: TUniQuery;
    function FiltroGridActivo: Boolean;
    function FotoArticuloVisible: Boolean;
    function SolicitarDestinoPerfil(
      const ADescripcion: string;
      ADescripcionEditable: Boolean;
      out APermisos: string): Boolean;
    function SolicitarDatosFiltro: TDatosGuardadoFiltroMto;
    function EjecutarGestionFiltros(
      const AFiltroActualBase64: string
    ): TResultadoGestionFiltroMto;
    procedure MoverRegistroGridFiltrado(AAvanzar: Boolean);
    procedure NavegadorButtonClick(Sender: TObject;
                                   AButtonIndex: Integer;
                                   var ADone: Boolean);
    procedure InstalarGuardianBorrado;
    procedure GuardianBeforeInsert(DataSet: TDataSet);
    procedure GuardianBeforeEdit(DataSet: TDataSet);
    procedure GuardianBeforePost(DataSet: TDataSet);
    procedure GuardianBeforeDelete(DataSet: TDataSet);
    procedure OcultarComponentesPorTexto(
      const AFragmentos: array of string);
    procedure CancelarTareasActivas;
    procedure EjecutarModalGuias;
    procedure OcultarFotoArticulo;
    procedure MostrarFotoArticulo(const ACodArt, ACodSku: string);
    procedure VincularFotoArticulo(
      const ADataSources: TArray<TDataSource>);
    procedure MostrarStockArticulo(const ACodArt, ACodSku: string);
    procedure ResetearGridPerfil(
      const ANombreGrid, ANombreFormulario, APermisos: string);
    // Decide que dialogo mostrar al ejecutar actEliminarRegistro segun
    // NombreCampoESACTIVO y ContarHijosActivos.
    function PreguntarAccionBorrado: TAccionBorrado;
    function FocoEnEditorTexto: Boolean;
    function PuedeCambiarRegistroPorTecla: Boolean;
    // Mueve el foco del grid principal un bloque de filas (Ctrl+AvPag /
    // Ctrl+RePag). AAvanzar=True baja el bloque, False lo sube.
    procedure MoverFocoGridBloque(AAvanzar: Boolean);
    // Suscrito a TdmBase.OnActivarFicha: al insertar en la tabla
    // principal el form activa su pestania de ficha (el DM no toca UI).
    procedure ActivarFichaDesdeDM(Sender: TObject);
    procedure NotificarMensajeDesdeDM(Sender: TObject;
      const AMensaje: string; ASeveridad: TSeveridadMensajeDatos);
    function ConfirmarMensajeDesdeDM(Sender: TObject;
      const AMensaje: string): Boolean;
//    procedure CollectSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
//                                        const sName: string;
//                                        const sProfile: string;
//                                        AList: TPerfilList);
  protected
    // Anfitrion de mantenimiento (el principal). Se descubre UNA vez en
    // FormCreate (patron 5.3 del PLAN_SOLID); fuera de fzam queda a nil
    // y la pantalla degrada como siempre.
    FAnfitrionMto: IAnfitrionMantenimiento;
    property ConexionTrabajo: TUniConnection read GetConexionTrabajo;
    // Indica si las teclas de navegacion (PgUp, PgDn, Home, End, Ins, F2)
    // deben activar las acciones del TActionList base. Los Mtos con
    // editores multilinea (SynEdit, etc.) sobreescriben para devolver
    // False cuando el editor tiene el foco.
    function PermitirNavegacionTeclas: Boolean; virtual;
    // Crea/oculta el overlay "Procesando..." sobre este Mto. Reentrante:
    // varias llamadas a Bloquear=True solo muestran el overlay una vez,
    // y solo se oculta cuando todas se compensan con un False.
    procedure BloquearTabPorOcupado(Bloquear: Boolean);
    // Inyecta SqlRestriccionUsuario en la SQL de la tabla principal antes
    // de abrirla (precarga). Idempotente: si el filtro ya esta en la SQL
    // (reapertura, o el propio Mto lo integro en su ConstruirWhere*) no
    // toca nada. Cierra la query si venia activa del DFM streaming.
    function PuedeAccionMto(AAccion: TAccionPermisoMto): Boolean;
  public
    tdmDataModule:TObject;
    sDataModuleName:string;
    // Alias no propietario del perfil que conserva la API de descendientes.
    oPerfilDic : TProfileDicc;
    sUso:string;
    pkFieldName:string;
    tsFichCab:TcxTabSheet;
    tsFichBut:TcxTabSheet;
    // True cuando este Mto es la instancia 1 reservada para busquedas
    // externas (Ctrl+A desde otra pantalla, navegar a una factura, etc.).
    // Activa el layout reducido: sin Lista, sin Busqueda, sin Precarga,
    // sin Exportar a Excel, y navegador limitado a Edit/Post/Cancel/
    // Delete/Insert. Las shortcuts Alt+F12/Ctrl+F12/Ctrl+F10 siguen
    // funcionando porque viven en FormKeyDown, no dependen del boton.
    EsInstanciaBusqueda: Boolean;
    procedure SimulateTabKey;
    procedure ProcesarPerfiles;
    // Contrato de extensión: ContratoHookMtoGen documenta y prueba si
    // inherited es primero, obligatorio en otro punto, opcional o no aplica.
    procedure AplicarEtiquetas;     virtual;
    procedure CrearTablaPrincipal;  virtual;
    procedure ResetForm;  virtual;
    // Aplica permisos por pantalla (consultar, insertar, modificar,
    // borrar, excel e imprimir) ocultando o deshabilitando los controles.
    // Las pantallas sin CALL no se tocan.
    procedure AplicarPermisosPantalla;
    // True si el usuario puede imprimir informes de esta pantalla. Los
    // Mtos con boton de impresion la consultan antes de imprimir.
    function PuedeImprimir: Boolean;
    // True si el usuario puede exportar datos de esta pantalla.
    function PuedeExportar: Boolean;
    procedure AbrirPerfiles(bTabVisible:Boolean);
    procedure CargarPerfilesParticulares; virtual;
    // Hook que cada Mto puede sobreescribir para añadir entradas extra al
    // batch que sbGrabarGridClick volcara en fza_usuarios_perfiles (por
    // ejemplo: filtros de carga del Mto, opciones particulares...). Recibe
    // la lista de perfiles ya iniciada con KeyPerfil = Self.Name y
    // UserGroup = sPermisos: solo hay que rellenar SubKey + Value y
    // hacer Add. Por defecto no anyade nada.
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); virtual;
    // Hook para que descendientes amplíen filtros antes de una búsqueda
    // externa (Ctrl+A desde otra pantalla). Por defecto no hace nada.
    procedure PrepararBusquedaExterna(const ABusq: string); virtual;
    // IVentanaEmbebida / IMantenimientoEmbebido: contrato con
    // inLibFormManager e inLibShowMto, que ya no conocen TfrmMtoGen.
    function InterceptarCierre: Boolean;
    procedure ActivarModoBusqueda(AAplicarLayout: Boolean);
    procedure DesactivarModoBusqueda;
    procedure AbrirTablaPrincipal(ASincrono: Boolean);
    function LocalizarYEnfocar(const ABusq: string): Boolean;
    // Aplica el layout reducido propio de la instancia 1 (la reservada
    // para busquedas). Lo invoca inLibShowMto cuando crea la instancia
    // 1, antes del Show. Los descendientes pueden override (llamando a
    // inherited) para esconder controles propios — por ejemplo Articulos
    // oculta el panel pnlFiltrosArt de Filtros de carga (Precarga).
    procedure AplicarLayoutInstanciaBusqueda; virtual;
    // Resuelve los codigos ART y SKU del registro activo en `dsTablaG`.
    // Recorre la lista de alias habituales (CODIGO_ART_*, CODIGO_UNIDAD_*).
    // Los Mtos que necesiten otra fuente pueden sobreescribirlo (p.ej.
    // los que tienen el articulo activo en un sub-grid: facturas, pedidos,
    // albaranes, tarifas). Para esos casos basta llamar a
    // `inLibFotos.LeerArtSkuDeDataSet` pasando el DataSet del grid de
    // detalle.
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); virtual;
    // Hook de la consulta de stock global (Ctrl+U): en un Mto el articulo en
    // foco es el del grid, que ya resuelve ResolverArtSkuActivo.
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
    // Lista de DataSources que la pantalla flotante de fotos debe
    // engancharse para refrescar al cambiar de registro activo. Default
    // = [dsTablaG]. Los Mtos con sub-grids (lineas, SKUs, stock,
    // movimientos...) lo sobreescriben para incluir tambien esos
    // DataSources, asi la foto sigue al cursor en cualquier pestaña.
    function DataSourcesParaFoto: TArray<TDataSource>; virtual;
    // ----- Hooks para el flujo de Borrar -----------------------------------
    // Devuelve el nombre del campo ESACTIVO de la tabla principal si esta es
    // "desactivable" (ESACTIVO_CLI, ESACTIVO_ART, ESACTIVO_FAM...). Vacio
    // por defecto: el Mto solo permite borrar/cancelar sin opcion de
    // desactivar.
    function NombreCampoESACTIVO: string; virtual;
    // Cuenta los registros hijos "activos" del registro maestro actualmente
    // enfocado en dsTablaG (lineas de factura, albaranes del cliente, etc.).
    // 0 por defecto. Los Mtos con tablas dependientes lo sobreescriben.
    function ContarHijosActivos: Integer; virtual;
    // Texto descriptivo de los hijos para el dialogo de borrado
    // ("lineas de factura", "facturas y albaranes del cliente", ...). Solo
    // se usa cuando ContarHijosActivos > 0. Vacio por defecto.
    function DescripcionHijos: string; virtual;
    // -----------------------------------------------------------------------
    // Ejecuta `AccionBG` en un thread aparte (TTask.Run del RTL). Mientras
    // corre, este Mto queda bloqueado con overlay "Procesando...", pero
    // los demas tabs siguen 100% interactivos. Al terminar (OK o
    // excepcion) se invoca `AlTerminar` en el main thread: el parametro
    // es '' si todo fue bien, o el mensaje de la excepcion si hubo fallo.
    // OJO: `AccionBG` NO puede tocar la UI ni datasets vinculados a
    // grids. Solo operaciones BBDD puras (ExecProc, ExecSQL, calculos).
    procedure EjecutarEnBackground(AccionBG: TProc;
                                   AlTerminar: TProc<string>);
    // Carga inicial de la lista principal (unqryTablaG) en thread. El
    // grid se suelta del DataSource antes del Open y se revincula cuando
    // termina, evitando que cxGrid acceda al dataset durante el fetch.
    // Si la query ya esta activa o no hay data module, no hace nada.
    procedure AbrirTablaPrincipalAsync;
    // Variante sincrona (comportamiento clasico): bloquea hasta tener
    // los datos. La usa ShowMto cuando se invoca con parametro de
    // busqueda — BuscarTabla.Locate necesita la query activa al volver.
    procedure AbrirTablaPrincipalSincrono;
    // Hook que corre en el MAIN THREAD al terminar AbrirTablaPrincipalAsync
    // (es decir, solo en la apertura normal; la instancia de busqueda usa la
    // via sincrona y no pasa por aqui). Por defecto no hace nada. Articulos
    // lo usa para, si la precarga supero el umbral de filas, mostrar el
    // dialogo de filtrado y reabrir la lista ya acotada.
    procedure TrasPrecargaAsync; virtual;
    // ----- Restricción por empresa/almacén/caja del usuario ----------------
    // Fragmento WHERE (' AND col = valor') que acota la tabla principal a
    // la empresa/almacén/caja del usuario cuando el parámetro
    // appRestringirEmpAlmCaja está activo (véase inLibFiltroUsuario).
    // Vacío por defecto: cada Mto de documentos/operaciones lo
    // sobreescribe devolviendo SqlFiltroEmpAlmCaja con sus columnas. Las
    // pantallas que recomponen la SQL en runtime (facturas simplificadas,
    // históricos de caja con filtros propios) integran el filtro en su
    // ConstruirWhere* en lugar de este override.
    function SqlRestriccionUsuario: string; virtual;
  public
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses inLibData,
     inLibConexionesIntf,
     inLibUnitForm,
     inLibShowMto,

     inMtoModalGenImpSave,
     inMtoModalGuardarFiltro,
     inMtoModalGestionFiltros,
     UniDataGen, uGenericIfThen,
     UniDataGuiasGridRepositorio,
     UniDataPerfilesMtoRepositorio,
     inMtoFotoArticulo, inMtoStockConsulta,
     inMtoModalGridGuias,
     System.Diagnostics,    // TStopwatch para cronometrar carga inicial
     System.TypInfo, inLibDiag,
  inLibMsgComun, inLibMsgConfiguracion;

function TfrmMtoGen.GetConexionTrabajo: TUniConnection;
begin
  Result := FConn;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
  if not Assigned(Result) then
    raise Exception.Create(SErrorConexionTrabajoNoDisponible);
end;

function TfrmMtoGen.AplicacionCerrando: Boolean;
begin
  Result := ContextoSesion.CerrandoAplicacion;
end;

procedure TfrmMtoGen.CancelarTareasActivas;
begin
  if (tdmDataModule <> nil) and
     (tdmDataModule is TdmBase) then
    TdmBase(tdmDataModule).CancelarEjecucionActiva;
end;

function TfrmMtoGen.FotoArticuloVisible: Boolean;
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  Result := (FormularioFoto <> nil) and FormularioFoto.Visible;
end;

procedure TfrmMtoGen.OcultarFotoArticulo;
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  if FormularioFoto <> nil then
    FormularioFoto.Hide;
end;

procedure TfrmMtoGen.MostrarFotoArticulo(const ACodArt, ACodSku: string);
begin
  MostrarFotoFlotante(Self, ACodArt, ACodSku);
end;

procedure TfrmMtoGen.VincularFotoArticulo(
  const ADataSources: TArray<TDataSource>);
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  if FormularioFoto <> nil then
    FormularioFoto.VincularDataSources(ADataSources,
      ResolverArtSkuActivo);
end;

procedure TfrmMtoGen.MostrarStockArticulo(const ACodArt, ACodSku: string);
begin
  inMtoStockConsulta.MostrarStockConsulta(ACodArt, ACodSku);
end;

function TfrmMtoGen.ObtenerConsultaGuias: TUniQuery;
begin
  Result := nil;
  if (tdmDataModule <> nil) and
     (tdmDataModule is TdmBase) then
    Result := TdmBase(tdmDataModule).unqryTablaG
  else if Assigned(dsTablaG) and
          Assigned(dsTablaG.DataSet) and
          (dsTablaG.DataSet is TUniQuery) then
    Result := TUniQuery(dsTablaG.DataSet);
end;

procedure TfrmMtoGen.AbrirPerfiles(bTabVisible:Boolean);
begin
  if tdmDataModule <> nil then
  begin
    tvPerfil.DataController.DataSource :=
      (tdmDataModule as TdmBase).dsPerfiles;
    FGestorPerfiles.AbrirPerfiles(
      bTabVisible,
      (tdmDataModule as TdmBase).Name);
  end;
end;

procedure TfrmMtoGen.AplicarEtiquetas;
begin
  FGestorPerfiles.AplicarEtiquetas;
end;

procedure TfrmMtoGen.btnCargarCaptionsClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.CargarCaptions;
end;

procedure TfrmMtoGen.btnCargarColumnasClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.CargarColumnas;
end;

procedure TfrmMtoGen.btnCargarVblesGlobClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.CargarPerfilesComunes;
  CargarPerfilesParticulares;
end;

procedure TfrmMtoGen.btnGrabarClick(Sender: TObject);
var
  Resultado: TResultadoGuardadoMtoGen;
begin
  inherited;
  if tdmDataModule <> nil then
  begin
    if FCasoUsoGuardado = nil then
      FCasoUsoGuardado := CrearCasoUsoGuardadoMtoGenUniDAC(
        ConexionTrabajo);
    Screen.Cursor := crHourGlass;
    try
      try
        Resultado := FCasoUsoGuardado.Ejecutar(
          procedure
          begin
            GrabarDatasets(tdmDataModule as TDataModule);
          end);
        if Resultado = rgmGuardado then
          ShowMessage(SInfoDatosGuardados);
      except
        on E: Exception do
          raise Exception.Create(Format(SErrorGrabarDatos, [E.Message]));
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoGen.btnSalirClick(Sender: TObject);
var
  ts: TcxTabSheet;
  formMain: TCustomForm;
begin
  inherited;
  if Self.Parent is TcxTabSheet then
  begin
    if (tdmDataModule <> nil) and
       CheckOpenDatasets(tdmDataModule as TDataModule) then
    begin
      if Application.MessageBox(PChar(SPreguntaGrabarCambiosPendientes),
        PChar(STituloMensajeAdvertenciaGen),
        MB_YESNO + MB_ICONQUESTION) = ID_YES then
      begin
        btnGrabarClick(Sender);
        ShowMessage(SInfoCambiosGrabados);
      end
      else
      begin
        CancelarDatasets(tdmDataModule as TDataModule);
        ShowMessage(SInfoCambiosCancelados);
      end;
    end;
    ts := TcxTabSheet(Self.Parent);
    formMain := Application.MainForm;
    PostMessage(formMain.Handle, WM_FREECONTROL, 0, LParam(ts));
  end;
end;

procedure TfrmMtoGen.sbGrabarGridClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.GrabarLayout(
    'Grabar Grids');
end;

procedure TfrmMtoGen.sbResetGridClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.ResetearLayout('Reset Grids');
end;

procedure TfrmMtoGen.sbBestFitClick(Sender: TObject);
var
  i: Integer;
begin
  cxGrdDBTabPrin.BeginUpdate;
  try
    for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
      if cxGrdDBTabPrin.Columns[i].Visible then
        cxGrdDBTabPrin.Columns[i].ApplyBestFit;
  finally
    cxGrdDBTabPrin.EndUpdate;
  end;
end;

procedure TfrmMtoGen.tsFichaShow(Sender: TObject);
var
  FocusControl: TWinControl;
  function FindNextFocusableControl(AParent: TWinControl): TWinControl;
  var
    I: Integer;
    Control: TControl;
    MinTabOrder: Integer;
  begin
    Result := nil;
    MinTabOrder := High(Integer);
    for I := 0 to AParent.ControlCount - 1 do
    begin
      Control := AParent.Controls[I];
      if (Control is TWinControl) and
         not (Control is TPanel) and          // Excluir TPanels
         not (Control is TcxPageControl) and  // Excluir TcxPageControl
         not (Control is TcxTabSheet) and     // Excluir TcxTabSheet
         TWinControl(Control).CanFocus and
         (TWinControl(Control).TabOrder > AParent.TabOrder) and
         (TWinControl(Control).TabOrder < MinTabOrder) then
      begin
        Result := TWinControl(Control);
        MinTabOrder := Result.TabOrder;
      end;
      if (Control is TWinControl) and
         (TWinControl(Control).ControlCount > 0) then
      begin
        Control := FindNextFocusableControl(TWinControl(Control));
        if Assigned(Control) and
           (TWinControl(Control).TabOrder > AParent.TabOrder) and
           (TWinControl(Control).TabOrder < MinTabOrder) then
        begin
          Result := TWinControl(Control);
          MinTabOrder := Result.TabOrder;
        end;
      end;
    end;
  end;
begin
    InstalarGuardianBorrado;
    FocusControl := FindNextFocusableControl(tsFicha);
    if Assigned(FocusControl) then
    begin
      if FocusControl.CanFocus then
      begin
        FocusControl.SetFocus;
      end;
    end;
end;

procedure TfrmMtoGen.InstalarGuardianBorrado;
var
  ds: TDataSet;
begin
  if not FGuardianBorradoInstalado then
  begin
    ds := dsTablaG.DataSet;
    if ds <> nil then
    begin
  // Encadenamos los handlers originales del data module.
  FBeforeInsertOrig := ds.BeforeInsert;
  FBeforeEditOrig := ds.BeforeEdit;
  FBeforePostOrig := ds.BeforePost;
  FBeforeDeleteOrig := ds.BeforeDelete;
  ds.BeforeInsert := GuardianBeforeInsert;
  ds.BeforeEdit := GuardianBeforeEdit;
  ds.BeforePost := GuardianBeforePost;
  ds.BeforeDelete := GuardianBeforeDelete;
  // Desactivamos el dialogo nativo de confirmacion del navegador para no
  // mostrar dos popups en cascada (el nativo y el nuestro). El cxGrid del
  // listado tiene su propio mini navegador; lo cubrimos tambien si esta
  // presente.
  if Assigned(nvNavegador) then
    nvNavegador.Buttons.ConfirmDelete := False;
  if Assigned(cxGrdDBTabPrin) and Assigned(cxGrdDBTabPrin.Navigator) then
    cxGrdDBTabPrin.Navigator.Buttons.ConfirmDelete := False;
  FGuardianBorradoInstalado := True;
    end;
  end;
end;

procedure TfrmMtoGen.GuardianBeforeInsert(DataSet: TDataSet);
begin
  if not PuedeAccionMto(apmInsertar) then
  begin
    ShowMessage(SErrorPermisoInsertarRegistro);
    Abort;
  end
  else if Assigned(FBeforeInsertOrig) then
    FBeforeInsertOrig(DataSet);
end;

procedure TfrmMtoGen.GuardianBeforeEdit(DataSet: TDataSet);
begin
  if (not FDesactivandoPorBorrado) and
     (not PuedeAccionMto(apmModificar)) then
  begin
    ShowMessage(SErrorPermisoModificarRegistro);
    Abort;
  end
  else if Assigned(FBeforeEditOrig) then
    FBeforeEditOrig(DataSet);
end;

procedure TfrmMtoGen.GuardianBeforePost(DataSet: TDataSet);
var
  bPermitido: Boolean;
begin
  bPermitido :=
    FDesactivandoPorBorrado or
    ((DataSet.State = dsInsert) and
     PuedeAccionMto(apmInsertar)) or
    ((DataSet.State = dsEdit) and
     PuedeAccionMto(apmModificar));
  if not bPermitido then
  begin
    ShowMessage(SErrorPermisoGuardarRegistro);
    Abort;
  end
  else if Assigned(FBeforePostOrig) then
    FBeforePostOrig(DataSet);
end;

procedure TfrmMtoGen.GuardianBeforeDelete(DataSet: TDataSet);
var
  sCampoActivo: string;
begin
  if not PuedeAccionMto(apmBorrar) then
  begin
    ShowMessage(SErrorPermisoBorrarRegistro);
    Abort;
  end
  else
  begin
    case PreguntarAccionBorrado of
      abCancelar:
        Abort;
      abDesactivar:
        begin
          sCampoActivo := NombreCampoESACTIVO;
          if (sCampoActivo <> '') and
             (DataSet.FindField(sCampoActivo) <> nil) then
          begin
            FDesactivandoPorBorrado := True;
            try
              if not (DataSet.State in [dsEdit, dsInsert]) then
                DataSet.Edit;
              DataSet.FieldByName(sCampoActivo).AsString := 'N';
              DataSet.Post;
            finally
              FDesactivandoPorBorrado := False;
            end;
          end;
          Abort;
        end;
      abContinuar:
        if Assigned(FBeforeDeleteOrig) then
          FBeforeDeleteOrig(DataSet);
    end;
  end;
end;

procedure TfrmMtoGen.OcultarComponentesPorTexto(
  const AFragmentos: array of string);
var
  i: Integer;
  j: Integer;
  sTexto: string;
  bCoincide: Boolean;
  function TextoPublicado(AComponente: TComponent;
                          const APropiedad: string): string;
  begin
    Result := '';
    if IsPublishedProp(AComponente, APropiedad) then
      Result := GetStrProp(AComponente, APropiedad);
  end;
begin
  for i := 0 to Self.ComponentCount - 1 do
  begin
    sTexto := Self.Components[i].Name + ' ' +
              TextoPublicado(Self.Components[i], 'Caption') + ' ' +
              TextoPublicado(Self.Components[i], 'Hint');
    sTexto := LowerCase(sTexto);
    sTexto := StringReplace(sTexto, '&', '', [rfReplaceAll]);
    sTexto := StringReplace(sTexto, '.', '', [rfReplaceAll]);
    bCoincide := False;
    for j := Low(AFragmentos) to High(AFragmentos) do
      if Pos(LowerCase(AFragmentos[j]), sTexto) > 0 then
        bCoincide := True;
    if bCoincide then
    begin
      if Self.Components[i] is TControl then
        TControl(Self.Components[i]).Visible := False
      else if Self.Components[i] is TCustomAction then
        TCustomAction(Self.Components[i]).Enabled := False
      else if Self.Components[i] is TMenuItem then
      begin
        TMenuItem(Self.Components[i]).Visible := False;
        TMenuItem(Self.Components[i]).Enabled := False;
      end;
    end;
  end;
end;

function TfrmMtoGen.PuedeAccionMto(
  AAccion: TAccionPermisoMto): Boolean;
var
  sCall: string;
begin
  sCall := '';
  if Assigned(FAnfitrionMto) then
    sCall := FAnfitrionMto.ResolverCallPantalla(
      Self.UnitName + '.' + Self.ClassName);
  if sCall = '' then
    Result := True
  else
    Result := Assigned(Permisos) and
              Permisos.TienePermiso(
                CodigoPermisoMto(sCall, AAccion),
                paPermitir);
end;

procedure TfrmMtoGen.CargarPerfilesParticulares;
begin
  if (tdmDataModule <> nil) then
    GrabarPerfilDatam(
      tdmDataModule as TdmBase,
      Self.Owner,
      PerfilesEscritura);
end;

procedure TfrmMtoGen.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                 const sPermisos: string);
begin
end;

procedure TfrmMtoGen.ResetearGridPerfil(
  const ANombreGrid, ANombreFormulario, APermisos: string);
begin
  (tdmDataModule as TdmBase).ResetGridsProfile(
    ANombreGrid, ANombreFormulario, APermisos);
end;

procedure TfrmMtoGen.PrepararBusquedaExterna(const ABusq: string);
begin
  if (ABusq <> '') and (pkFieldName <> '') and
     (tdmDataModule is TdmBase) then
    TdmBase(tdmDataModule).PrepararBusquedaExterna(
      pkFieldName,
      ABusq);
end;

// La primera pulsacion de cierre desde la ficha vuelve a la lista; el
// gestor de ventanas pregunta por esta interfaz en vez de conocer la
// clase (antes ese if vivia en inLibFormManager con un cast directo).
function TfrmMtoGen.InterceptarCierre: Boolean;
begin
  Result := False;
  if pcPantalla.ActivePage = tsFicha then
  begin
    pcPantalla.ActivePage := tsLista;
    Result := True;
  end;
end;

procedure TfrmMtoGen.ActivarModoBusqueda(AAplicarLayout: Boolean);
begin
  EsInstanciaBusqueda := True;
  if AAplicarLayout then
    AplicarLayoutInstanciaBusqueda;
end;

procedure TfrmMtoGen.DesactivarModoBusqueda;
begin
  EsInstanciaBusqueda := False;
end;

procedure TfrmMtoGen.AbrirTablaPrincipal(ASincrono: Boolean);
begin
  if ASincrono then
    AbrirTablaPrincipalSincrono
  else
    AbrirTablaPrincipalAsync;
end;

// False SOLO si se busco y no se encontro (inLibShowMto avisa entonces
// al usuario); True si se encontro o si no procedia buscar.
function TfrmMtoGen.LocalizarYEnfocar(const ABusq: string): Boolean;
begin
  Result := True;
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    Result := BuscarTabla(TdmBase(tdmDataModule).unqryTablaG,
                          pkFieldName, ABusq);
    if Result then
    begin
      if (tsFicha <> nil) and tsFicha.TabVisible then
        pcPantalla.ActivePage := tsFicha;
      if CanFocus then
        SetFocus;
    end;
  end;
end;

procedure TfrmMtoGen.AplicarLayoutInstanciaBusqueda;
begin
  // Lista: la instancia de busqueda llega directa a la Ficha del registro
  // localizado, no se navega por el grid.
  tsLista.TabVisible := False;
  // Busqueda global: el filtro ya viene impuesto por PrepararBusquedaExterna.
  edtBusqGlobal.Visible    := False;
  lblTextoaBuscar.Visible  := False;
  rbBBDD.Visible           := False;
  rbGrid.Visible           := False;
  // Exportar a Excel y botones de configuracion de grid: no aplican sin
  // grid visible. Las shortcuts Alt+F12/Ctrl+F12/Ctrl+F10 siguen vivas en
  // FormKeyDown — disparan los handlers sin necesidad del boton visible.
  sbExportExcel.Visible := False;
  sbGrabarGrid.Visible  := False;
  sbResetGrid.Visible   := False;
  sbBestFit.Visible     := False;
  // Navegador reducido a Insert/Delete/Edit/Post/Cancel.
  nvNavegador.Buttons.First.Visible        := False;
  nvNavegador.Buttons.PriorPage.Visible    := False;
  nvNavegador.Buttons.Prior.Visible        := False;
  nvNavegador.Buttons.Next.Visible         := False;
  nvNavegador.Buttons.NextPage.Visible     := False;
  nvNavegador.Buttons.Last.Visible         := False;
  nvNavegador.Buttons.Insert.Visible       := True;
  nvNavegador.Buttons.Append.Visible       := False;
  nvNavegador.Buttons.Delete.Visible       := True;
  nvNavegador.Buttons.Edit.Visible         := True;
  nvNavegador.Buttons.Post.Visible         := True;
  nvNavegador.Buttons.Cancel.Visible       := True;
  nvNavegador.Buttons.Refresh.Visible      := False;
  nvNavegador.Buttons.SaveBookmark.Visible := False;
  nvNavegador.Buttons.GotoBookmark.Visible := False;
  nvNavegador.Buttons.Filter.Visible       := False;
  // Re-aplicar permisos de pantalla: este metodo acaba de volver a mostrar
  // Insert/Delete/Edit/Post, asi que hay que ocultarlos de nuevo si el
  // usuario no tiene insertar/modificar/borrar.
  AplicarPermisosPantalla;
end;

// El TdmBase avisa al insertar en la tabla principal; el form decide
// la pestania (antes TdmBase tocaba pcPantalla/tsFicha directamente).
procedure TfrmMtoGen.ActivarFichaDesdeDM(Sender: TObject);
begin
  if tsFicha.TabVisible then
    pcPantalla.ActivePage := tsFicha;
end;

procedure TfrmMtoGen.NotificarMensajeDesdeDM(Sender: TObject;
  const AMensaje: string; ASeveridad: TSeveridadMensajeDatos);
var
  eTipoDialogo: TMsgDlgType;
begin
  case ASeveridad of
    smdInformacion:
      eTipoDialogo := mtInformation;
    smdAdvertencia:
      eTipoDialogo := mtWarning;
  else
    eTipoDialogo := mtError;
  end;
  MessageDlg(AMensaje, eTipoDialogo, [mbOk], 0);
end;

function TfrmMtoGen.ConfirmarMensajeDesdeDM(Sender: TObject;
  const AMensaje: string): Boolean;
begin
  Result := MessageDlg(
    AMensaje, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmMtoGen.CrearTablaPrincipal;
var
  sNameModule: string;
  swTotal, swTramo: TStopwatch;
  msCrearDM, msFConn, msReasignar: Int64;
begin
  swTotal := TStopwatch.StartNew;
  msCrearDM := 0; msFConn := 0; msReasignar := 0;
  tdmDataModule := nil;
  sNameModule := '';
  // Los proyectos independientes no implementan el contrato anfitrión.
  if Assigned(FAnfitrionMto) then
    sNameModule := FAnfitrionMto.ResolverDataModulePantalla(
      Self.UnitName + '.' + Self.ClassName);
  if (sNameModule <> '') then
  begin
    swTramo := TStopwatch.StartNew;
    tdmDataModule := CrearDataModule(sNameModule, Self);
    msCrearDM := swTramo.ElapsedMilliseconds;
    if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
    begin
      // Cableado que antes hacia inLibShowMto.CrearDataModule tocando
      // este form: ahora el form se cablea a si mismo.
      TdmBase(tdmDataModule).FCurrentForm := Self;
      if Assigned(dsTablaG) then
        dsTablaG.DataSet := TdmBase(tdmDataModule).unqryTablaG;
      if FGestorPerfiles.Valor(
           'oGetSQLFromDB', 'False') = 'True' then
      begin
        GetFormUserProfile(TdmBase(tdmDataModule).FoPerfilDic,
                           TdmBase(tdmDataModule).Name,
                           PerfilesLectura);
        LoadSQLFromProfile(TdmBase(tdmDataModule),
                           TdmBase(tdmDataModule).FoPerfilDic);
      end;
    end;
    // La conexión persistente dmConn.conUni mantiene operativos los DFM en
    // diseño. En ejecución el servicio crea la conexión propia del Mto y se
    // inyecta antes de abrir la tabla principal.
    if FConn = nil then
    try
      swTramo := TStopwatch.StartNew;
      if not Assigned(Conexiones) then
        raise Exception.Create(SErrorServicioConexionesNoDisponible);
      FConn := Conexiones.CrearConexion(
        Self,
        uctMantenimiento);
      msFConn := swTramo.ElapsedMilliseconds;
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarError('No se pudo crear conexión propia para ' +
          Self.Name + ': ' + E.Message +
          '. Se sigue usando dmConn.conUni.');
        FConn := nil;
      end;
    end;
    if Assigned(FConn) then
    begin
      swTramo := TStopwatch.StartNew;
      (tdmDataModule as TdmBase).ReasignarConexion(FConn);
      msReasignar := swTramo.ElapsedMilliseconds;
    end;
    if Assigned(tdmDataModule) then
    begin
      FGestorGuias.AsignarPersistencia(
        CrearPersistenciaGuiasGridUniDAC(
          ConexionTrabajo));
      FGestorPerfiles.AsignarPersistencia(
        CrearPersistenciaPerfilesMtoUniDAC(
          ConexionPrincipal,
          ConexionTrabajo,
          TdmBase(tdmDataModule).unqryPerfiles));
      // El DM ya no busca dsTablaG con GetOwnerForm: el form empuja el
      // maestro y se suscribe al aviso de insercion (misma pauta que
      // TdmFacturas en la Fase 3).
      (tdmDataModule as TdmBase).AsignarMaestroCabecera(dsTablaG);
      (tdmDataModule as TdmBase).OnActivarFicha := ActivarFichaDesdeDM;
      (tdmDataModule as TdmBase).OnNotificarMensaje :=
        NotificarMensajeDesdeDM;
      (tdmDataModule as TdmBase).OnConfirmarMensaje :=
        ConfirmarMensajeDesdeDM;
    end;
  end;
  inherited;
  RegistroLog.RegistrarRendimiento(Self.Name + '.CrearTablaPrincipal',
    Format('CrearDM=%d ms | FConn.Connect=%d ms | ReasignarConexion=%d ms',
           [msCrearDM, msFConn, msReasignar]),
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.AplicarPermisosPantalla;
var
  sCall: string;
begin
  InstalarGuardianBorrado;
  // CALL de la pantalla (Clientes, Articulos...). Los Mtos sin registro
  // en fza_winforms (p.ej. cajas de busqueda) no tienen CALL: todo activo.
  sCall := '';
  if Assigned(FAnfitrionMto) then
    sCall := FAnfitrionMto.ResolverCallPantalla(
      Self.UnitName + '.' + Self.ClassName);
  if sCall <> '' then
  begin
    // Consultar/buscar: solo se quita el buscador global. NO se bloquea la
    // apertura ni la carga, asi se puede llegar a una ficha navegando
    // desde otro Mto (Ctrl+A, ir a factura...).
    if not PuedeAccionMto(apmConsultar) then
    begin
      edtBusqGlobal.Visible   := False;
      lblTextoaBuscar.Visible := False;
      rbBBDD.Visible          := False;
      rbGrid.Visible          := False;
    end;
    // Alta. Enabled:=False en la accion neutraliza tambien su atajo.
    if not PuedeAccionMto(apmInsertar) then
    begin
      actInsertarRegistro.Enabled        := False;
      nvNavegador.Buttons.Insert.Visible := False;
      nvNavegador.Buttons.Append.Visible := False;
    end;
    // Modificacion.
    if not PuedeAccionMto(apmModificar) then
    begin
      actEditarRegistro.Enabled        := False;
      actGrabarRegistro.Enabled        := False;
      nvNavegador.Buttons.Edit.Visible := False;
      nvNavegador.Buttons.Post.Visible := False;
    end;
    // Borrado.
    if not PuedeAccionMto(apmBorrar) then
    begin
      actEliminarRegistro.Enabled        := False;
      nvNavegador.Buttons.Delete.Visible := False;
    end;
    // Exportar a Excel.
    if not PuedeExportar then
    begin
      sbExportExcel.Visible := False;
      OcultarComponentesPorTexto(['export', 'exp excel']);
    end;
    // Impresion.
    if not PuedeImprimir then
      OcultarComponentesPorTexto(['imprim', 'print', 'pegatin']);
  end;
end;

function TfrmMtoGen.PuedeImprimir: Boolean;
begin
  Result := PuedeAccionMto(apmImprimir);
end;

function TfrmMtoGen.PuedeExportar: Boolean;
begin
  Result := PuedeAccionMto(apmExcel);
end;

procedure TfrmMtoGen.BloquearTabPorOcupado(Bloquear: Boolean);
begin
  FGestorTareas.Bloquear(Bloquear);
end;

procedure TfrmMtoGen.EjecutarEnBackground(AccionBG: TProc;
                                          AlTerminar: TProc<string>);
begin
  FGestorTareas.Ejecutar(AccionBG, AlTerminar);
end;

procedure TfrmMtoGen.AbrirTablaPrincipalAsync;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  yaActiva: Boolean;
  bSinError: Boolean;
begin
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    dmDat := TdmBase(tdmDataModule);
    unqry := dmDat.unqryTablaG;
    if unqry <> nil then
    begin
  // Antes de entrar: restricción por empresa/almacén/caja del usuario.
  // Si cierra una query activa del DFM, el flujo normal de abajo la
  // reabre ya filtrada (yaActiva quedará False).
  if dmDat.AplicarRestriccionUsuario(SqlRestriccionUsuario) then
    RegistroLog.RegistrarInformacion(Self.Name +
      ': precarga restringida por usuario (appRestringirEmpAlmCaja)');
  // unqryTablaG puede llegar abierta por el DFM streaming (Active=True
  // en su DFM, es lo habitual para que componentes del form puedan
  // resolver el field 'CODIGO_ART_ART' en CrearTablaPrincipal). En ese
  // caso saltamos su Open pero seguimos para abrir AbrirDetalles, que
  // es donde realmente esta el grueso de la carga.
  yaActiva := unqry.Active;
  // Soltamos el grid del DataSource solo si vamos a (re)abrir. Si la
  // query ya esta activa con datos, mantener el grid vinculado evita
  // un parpadeo "<No hay datos a mostrar>" innecesario.
  if (not yaActiva) and Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  // El Open en hilo dispara AfterScroll EN EL HILO DE TRABAJO. Los
  // handlers pesados (p.ej. Articulos: CargarPropiedades toca VCL y
  // comparte lista/conexion) se autoprotegen con "if
  // DataSet.ControlsDisabled then Exit": deshabilitamos aqui y
  // reactivamos en el callback, ya en main thread. La ficha del
  // registro actual la carga RestaurarFocoGrid o TrasPrecargaAsync.
  unqry.DisableControls;
  sw := TStopwatch.StartNew;
  EjecutarEnBackground(
    procedure
    begin
      // Solo la lista principal en thread. Es rapido (~8 ms en
      // vi_articulos). Probamos a meter AbrirDetalles aqui tambien
      // pero los cxDBLookupComboBox (cbbFamilia y cia) se cuelgan al
      // recibir notificacion de Active=True desde un thread aparte —
      // DevExpress NO es thread-safe ni siquiera con TDataSource.Enabled
      // = False.
      if not unqry.Active then
        unqry.Open;
    end,
    procedure(ErrMsg: string)
    begin
      // El form puede haberse cerrado mientras carga (otro tab, btnSalir,
      // cierre de app). En csDestroying los componentes ya pueden estar
      // liberados; salir limpio sin tocar nada.
      if not (csDestroying in ComponentState) then
      begin
      // Reactivar SIEMPRE (tambien con error) para no dejar el contador
      // de DisableControls desbalanceado. Estamos en main thread.
      if Assigned(unqry) then
        unqry.EnableControls;
      bSinError := ErrMsg = '';
      if bSinError then
        RegistroLog.RegistrarRendimiento('Carga/async', Self.Name + ' | OK',
          sw.ElapsedMilliseconds)
      else
      begin
        RegistroLog.RegistrarRendimiento('Carga/async',
          Self.Name + ' | error=' + ErrMsg,
          sw.ElapsedMilliseconds);
      end;
      if bSinError then
      begin
      // (a) Detalles en MAIN thread con overlay aun visible. Bloquea
      // el main thread mientras corre (no podemos evitarlo: DevExpress
      // no permite operaciones de dataset en thread sin colgarse), pero
      // el usuario ve "Cargando datos..." y el overlay esta arriba;
      // otros tabs siguieron interactivos hasta que entramos aqui.
      if Assigned(dmDat) then
        try
          dmDat.AbrirDetalles;
        except
          on E: Exception do
            RegistroLog.RegistrarError(
              '[AbrirDetalles] ' + Self.Name + ': ' + E.Message);
        end;
      // Diagnostico defensivo: cazar columnas ES* tipadas como numericas
      // antes de que el Refresh del navegador rompa con EConvertError
      // 'N' is not a valid floating point value. Solo loguea, no aborta.
      inLibDiag.DiagnosticarCamposBooleanos(
        unqry, Self.Name, RegistroLog);
      // (b) Enriquecer query con guias de grid (LEFT JOIN runtime)
      FGestorGuias.Aplicar(unqry);
      // (c) Revincular grid solo si lo soltamos antes (yaActiva = False).
      // Si la query ya estaba activa al entrar, dsTablaG.DataSet sigue
      // apuntando al original y no tocamos.
      if (not yaActiva) and Assigned(dsTablaG) and Assigned(unqry) then
        dsTablaG.DataSet := unqry;
      // (d) Reactivar TDataSource del DM (los hayamos desactivado o no
      // en AbrirDetalles) y disparar AfterScroll del stock.
      if Assigned(dmDat) then
        try
          dmDat.ReactivarControlesTrasAbrir;
        except
          on E: Exception do
            RegistroLog.RegistrarError(
              '[ReactivarControlesTrasAbrir] ' + Self.Name + ': ' + E.Message);
        end;
      // (e) Restaurar posicion del cursor guardada en el perfil.
      // AplicarEtiquetas lo intenta en FormCreate pero el dataset
      // aun no tiene datos; aqui ya esta abierto y vinculado.
      FGestorPerfiles.RestaurarFoco(cxGrdDBTabPrin);
      // (f) Hook de borrar (Delete -> Desactivar). Idempotente.
      InstalarGuardianBorrado;
      // (g) Hook post-precarga (main thread): los Mtos que necesiten
      // intervenir tras la carga normal (p.ej. Articulos: dialogo de
      // filtrado si se supero el umbral de filas) lo hacen aqui.
      TrasPrecargaAsync;
      end;
      end;
    end);
    end;
  end;
end;

procedure TfrmMtoGen.TrasPrecargaAsync;
begin
  // Default: nada. Los Mtos que lo necesiten lo sobreescriben.
end;

function TfrmMtoGen.SqlRestriccionUsuario: string;
begin
  // Default: sin restricción. Los Mto de documentos/operaciones
  // sobreescriben devolviendo SqlFiltroEmpAlmCaja con sus columnas.
  Result := '';
end;

procedure TfrmMtoGen.AbrirTablaPrincipalSincrono;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  CursorPrev: TCursor;
begin
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    dmDat := TdmBase(tdmDataModule);
    unqry := dmDat.unqryTablaG;
    if unqry <> nil then
    begin
  // Antes de entrar: restricción por empresa/almacén/caja del usuario
  if dmDat.AplicarRestriccionUsuario(SqlRestriccionUsuario) then
    RegistroLog.RegistrarInformacion(Self.Name +
      ': precarga restringida por usuario (appRestringirEmpAlmCaja)');
  // Modo sincrono: la UI esta congelada durante el Open. Forzamos cursor
  // de reloj global (Screen.Cursor) para que el usuario sepa que la app
  // esta ocupada — no muerta. Self.Cursor solo afecta cuando el raton
  // esta sobre el form; Screen.Cursor lo cambia en toda la pantalla.
  CursorPrev := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  sw := TStopwatch.StartNew;
  try
    try
      if not unqry.Active then
        unqry.Open;
      // Sin abrir los detalles, los grids master/detail se quedan en
      // blanco aunque la BBDD tenga datos (la query detalle no esta
      // Active y MasterSource solo refresca params, no la activa). La
      // version async ya lo hace en su callback; en sync hay que
      // llamarlo aqui para que ShowMto(...,'<busqueda>') muestre las
      // lineas/celdas tras Locate sobre el master.
      dmDat.AbrirDetalles;
      // Diagnostico defensivo: cazar columnas ES* tipadas como numericas
      // antes de que el Refresh del navegador rompa con EConvertError.
      inLibDiag.DiagnosticarCamposBooleanos(
        unqry, Self.Name, RegistroLog);
      // Enriquecer con guias de grid (LEFT JOIN runtime)
      FGestorGuias.Aplicar(unqry);
      // Restaurar posicion del cursor guardada en el perfil
      FGestorPerfiles.RestaurarFoco(cxGrdDBTabPrin);
      // Hook de borrar (Delete -> Desactivar). Idempotente.
      InstalarGuardianBorrado;
      RegistroLog.RegistrarRendimiento('Carga/sync', Self.Name + ' | OK',
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Carga/sync',
          Self.Name + ' | error=' + E.Message,
          sw.ElapsedMilliseconds);
        raise;
      end;
    end;
  finally
    Screen.Cursor := CursorPrev;
  end;
    end;
  end;
end;

procedure TfrmMtoGen.cxGrdDBTabPrinDblClick(Sender: TObject);
begin
  inherited;
  if (tsFicha.TabVisible = True) then
    pcPantalla.ActivePage := tsFicha;
end;

destructor TfrmMtoGen.Destroy;
var
  bTareasVivas: Boolean;
begin
  bTareasVivas := False;
  FCasoUsoGuardado := nil;
  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  if Assigned(FGestorTareas) then
    bTareasVivas := FGestorTareas.EsperarFinalizacion(
      CancelarTareasActivas,
      ContextoSesion.CerrandoAplicacion);
  FreeAndNil(FGestorTareas);
  FreeAndNil(FGestorArticulos);
  oPerfilDic := nil;
  FreeAndNil(FGestorPerfiles);
  FreeAndNil(FGestorFiltros);
  FreeAndNil(FGestorGuias);
  if bTareasVivas then
  begin
    // Tarea de fondo aun bloqueada (p.ej. consulta MySQL atascada): la
    // tarea sigue usando el data module y FConn, y liberarlos provoca
    // AVs y cuelgues del cierre. Se sueltan del Owner y NO se liberan:
    // fuga controlada que el SO recupera al terminar el proceso.
    RegistroLog.RegistrarAviso('Tareas de fondo aun vivas al destruir "' +
                            Self.Name + '": se dejan sin liberar su ' +
                            'data module y su conexion.');
    // tdmDataModule esta declarado como TObject: cast a TComponent para
    // consultar el Owner y soltarlo del form (en runtime siempre es un
    // TDataModule creado por CrearDataModule).
    if (tdmDataModule is TComponent) and
       (TComponent(tdmDataModule).Owner = Self) then
      RemoveComponent(TComponent(tdmDataModule));
    tdmDataModule := nil;
    if Assigned(FConn) then
    begin
      if FConn.Owner = Self then
        RemoveComponent(FConn);
      FConn := nil;
    end;
  end;
  if (tdmDataModule <> nil) then
    FreeAndNil(tdmDataModule);
  // Liberar la conexion propia DESPUES del data module: las queries del
  // data module aun referencian FConn durante su destrucion para los Close
  // implicitos. Si soltamos antes, AVs garantizados.
  if Assigned(FConn) then
  begin
    try
      if FConn.Connected then
        FConn.Disconnect;
    except
      // Disconnect en pool no deberia fallar, pero si lo hace no queremos
      // que el destructor lance.
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'MtoGen.Destroy: Disconnect fallo: ' + E.Message);
    end;
    FreeAndNil(FConn);
  end;
  RegistroLog.RegistrarInformacion('Ventana de mantenimiento: ' +
                                                   Self.Caption + ' Cerrada');
  inherited;
end;

procedure TfrmMtoGen.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.Dataset <> nil) then
  begin
    if (dsTablaG.DataSet.State = dsInsert) then
    begin
      lblEditMode.Caption := SCaptionEstadoInsertando;
    end;
    if (dsTablaG.DataSet.State = dsEdit) then
    begin
      lblEditMode.Caption := SCaptionEstadoEditando;
    end;
    if (dsTablaG.DataSet.State = dsBrowse) then
    begin
      lblEditMode.Caption := SCaptionEstadoNavegando;
    end;
      if (dsTablaG.DataSet.State = dsInactive) then
    begin
      lblEditMode.Caption := SCaptionEstadoInactivo;
    end;
  end;
end;

procedure TfrmMtoGen.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  SendMessage(Self.Handle, WM_SETREDRAW, WPARAM(False), 0);
  // Si la pantalla flotante de fotos estaba enganchada a DataSources
  // de este Mto (vinculados con Ctrl+F), la desenganchamos antes
  // de que sus DataSources se liberen con el data module. Asi no
  // quedan punteros colgando en FHooksDataSource.
  if Assigned(FGestorArticulos) then
    FGestorArticulos.DesvincularFoto;
  if Assigned(cxGrdDBTabPrin) then
    cxGrdDBTabPrin.DataController.DataSource := nil;

  if Assigned(tvPerfil) then
    tvPerfil.DataController.DataSource := nil;

  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  Action := caFree;
end;

procedure TfrmMtoGen.FormCreate(Sender: TObject);
var
  sModoBusq: String;
  swTotal, swTramo: TStopwatch;
  msProcesarPerfiles: Int64;
begin
  swTotal := TStopwatch.StartNew;
  inherited;
  // Descubrir el anfitrion UNA vez; el resto de metodos usa el campo.
  // Fuera de fzam (pruebas, proyectos independientes) no existe.
  if not Supports(Self.Owner, IAnfitrionMantenimiento, FAnfitrionMto) then
    RegistroLog.RegistrarInformacion(
      'Sin anfitrion de mantenimiento (standalone): ' + Self.ClassName);
  FGestorTareas := TGestorTareasMto.Create(
    Self, AplicacionCerrando, RegistroLog);
  FGestorArticulos := TGestorArticulosMto.Create(
    dsTablaG, ResolverArtSkuActivo,
    DataSourcesParaFoto, FotoArticuloVisible,
    OcultarFotoArticulo, MostrarFotoArticulo,
    VincularFotoArticulo, MostrarStockArticulo);
  FGestorGuias := TGestorGuiasGridMto.Create(
    Self, cxgrdPrincipal, cxGrdDBTabPrin,
    InformesGuiasCache, ObtenerConsultaGuias,
    EjecutarModalGuias, RegistroLog);
  FGestorPerfiles := TGestorPerfilesMto.Create(
    Self, dsTablaG, lblTablaOrigen,
    PerfilesLectura, PerfilesEscritura,
    ConfiguracionCampos, RegistroLog,
    SolicitarDestinoPerfil, RecogerPerfilesParticulares,
    ResetearGridPerfil, FGestorGuias.BorrarGuias);
  FGestorFiltros := TGestorFiltrosMto.Create(
    Self, cxGrdDBTabPrin, edtBusqGlobal, tmrBusqGlobal,
    pmFiltros, FiltrosLectura, FiltrosEscritura,
    SolicitarDatosFiltro,
    EjecutarGestionFiltros);
  btnCargarCaptions.Enabled := False;
  Self.HandleNeeded; //da problemas
  nvNavegador.Buttons.OnButtonClick := NavegadorButtonClick;
  RegistroLog.RegistrarInformacion('Ventana de mantenimiento: ' +
                                                     Self.Caption + ' Abierta');
  tsFichCab := nil;
  tsFichBut := nil;
  Self.Position  := poScreenCenter;
  swTramo := TStopwatch.StartNew;
  ProcesarPerfiles;
  msProcesarPerfiles := swTramo.ElapsedMilliseconds;
  sModoBusq := FGestorPerfiles.Valor(
    'oBusqGlobal', 'Database');
  if sModoBusq = 'DataBase' then
  begin
    rbBBDD.Checked := true;
    rbGrid.Checked := false;
  end
  else
  begin
    rbBBDD.Checked := false;
    rbGrid.Checked := true;
  end;
  RegistroLog.RegistrarRendimiento(Self.Name + '.FormCreate',
    'ProcesarPerfiles=' + IntToStr(msProcesarPerfiles) + ' ms',
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  // ESC -> cancelar grids en edicion
  if (Key = VK_ESCAPE) then
  begin
    // Fuera de fzam no hay anfitrion: nada global que cancelar.
    if Assigned(FAnfitrionMto) then
      FAnfitrionMto.CancelarEdicionesPantallas;
    Key := 0;
  end
  // RETURN sin control activo -> simular Tab
  else if (Key = VK_RETURN) and (ActiveControl = nil) then
  begin
    Key := 0;
    SimulateTabKey;
  end
  // Ctrl+Inicio / Ctrl+Fin -> primer / ultimo registro del grid.
  // En editores de texto dejamos el comportamiento nativo del control.
  else if (Key in [VK_HOME, VK_END]) and (ssCtrl in Shift) and
     not (ssAlt in Shift) and PuedeCambiarRegistroPorTecla then
  begin
    // Usar DataController para respetar la ordenacion del grid
    if Key = VK_HOME then
      cxGrdDBTabPrin.DataController.FocusedRowIndex := 0
    else
      cxGrdDBTabPrin.DataController.FocusedRowIndex :=
        cxGrdDBTabPrin.DataController.RowCount - 1;
    Key := 0;
  end
  // Alt+F12 -> Guardar layout (equivalente al botón sbGrabarGrid)
  else if (Key = VK_F12) and (ssAlt in Shift) and
     not (ssCtrl in Shift) then
  begin
    sbGrabarGridClick(nil);
    Key := 0;
  end
  // Ctrl+F12 -> Resetear layout (equivalente al botón sbResetGrid)
  else if (Key = VK_F12) and (ssCtrl in Shift) and
     not (ssAlt in Shift) then
  begin
    sbResetGridClick(nil);
    Key := 0;
  end
  // Ctrl+F10 -> BestFit anchos de columna
  else if (Key = VK_F10) and (ssCtrl in Shift) and
     not (ssAlt in Shift) then
  begin
    sbBestFitClick(nil);
    Key := 0;
  end;
end;

// ---------------------------------------------------------------------------
// Acciones del TActionList base (alMtoGen)
// Sustituyen al antiguo FormKeyDown para que inMtoPrincipal.IsShortCut
// enrute siempre al formulario activo en la pestaña correcta.
// ---------------------------------------------------------------------------

function TfrmMtoGen.PermitirNavegacionTeclas: Boolean;
begin
  Result := True;
end;

function TfrmMtoGen.FocoEnEditorTexto: Boolean;
var
  sClase: string;
begin
  Result := False;
  if Assigned(ActiveControl) then
  begin
    sClase := ActiveControl.ClassName;
    Result := (ActiveControl is TCustomEdit) or
              (Pos('TextEdit', sClase) > 0) or
              (Pos('Memo', sClase) > 0) or
              (Pos('SynEdit', sClase) > 0) or
              (Pos('ComboBox', sClase) > 0) or
              (Pos('LookupComboBox', sClase) > 0) or
              (Pos('ButtonEdit', sClase) > 0) or
              (Pos('DateEdit', sClase) > 0) or
              (Pos('CurrencyEdit', sClase) > 0);
  end;
end;

function TfrmMtoGen.PuedeCambiarRegistroPorTecla: Boolean;
begin
  Result := Assigned(dsTablaG.DataSet) and
            dsTablaG.DataSet.Active and
            (dsTablaG.State = dsBrowse) and
            PermitirNavegacionTeclas and
            not FocoEnEditorTexto;
end;

function TfrmMtoGen.FiltroGridActivo: Boolean;
begin
  Result := Assigned(cxGrdDBTabPrin) and
            cxGrdDBTabPrin.DataController.Filter.Active and
            not cxGrdDBTabPrin.DataController.Filter.IsEmpty;
end;

procedure TfrmMtoGen.MoverRegistroGridFiltrado(AAvanzar: Boolean);
var
  iFila: Integer;
  iUltimaFila: Integer;
begin
  iUltimaFila := cxGrdDBTabPrin.DataController.RowCount - 1;
  if iUltimaFila >= 0 then
  begin
    iFila := cxGrdDBTabPrin.DataController.FocusedRowIndex;
    if iFila < 0 then
      iFila := 0
    else if AAvanzar then
      Inc(iFila)
    else
      Dec(iFila);
    if iFila < 0 then
      iFila := 0;
    if iFila > iUltimaFila then
      iFila := iUltimaFila;
    cxGrdDBTabPrin.DataController.FocusedRowIndex := iFila;
  end;
end;

procedure TfrmMtoGen.NavegadorButtonClick(Sender: TObject;
  AButtonIndex: Integer; var ADone: Boolean);
begin
  // El filtro pertenece al grid, no al dataset del navegador.
  if FiltroGridActivo and
     (AButtonIndex in [NBDI_PRIOR, NBDI_NEXT]) then
  begin
    MoverRegistroGridFiltrado(AButtonIndex = NBDI_NEXT);
    ADone := True;
  end;
end;

procedure TfrmMtoGen.actNavBrowseUpdate(Sender: TObject);
var
  bPermitido: Boolean;
begin
  bPermitido := True;
  if Sender = actInsertarRegistro then
    bPermitido := PuedeAccionMto(apmInsertar)
  else if Sender = actEditarRegistro then
    bPermitido := PuedeAccionMto(apmModificar);
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (dsTablaG.State = dsBrowse) and
    PermitirNavegacionTeclas and
    bPermitido;
end;

procedure TfrmMtoGen.actEliminarRegistroUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty and
    (dsTablaG.State = dsBrowse) and
    PuedeAccionMto(apmBorrar);
end;

procedure TfrmMtoGen.actEliminarRegistroExecute(Sender: TObject);
begin
  // El guardian BeforeDelete (GuardianBeforeDelete) hace la pregunta y, segun
  // la respuesta, aborta, desactiva o continua con el delete original. No
  // duplicamos aqui la logica para que el flujo sea identico cuando el
  // usuario pulsa el boton de borrar del navegador (que llama directamente
  // a DataSet.Delete sin pasar por esta accion).
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty and
     PuedeAccionMto(apmBorrar) then
    dsTablaG.DataSet.Delete;
end;

function TfrmMtoGen.PreguntarAccionBorrado: TAccionBorrado;
var
  sCampoActivo, sDescHijos, sMsg: string;
  iHijos: Integer;
  bDesactivable: Boolean;
  iResp: Integer;
begin
  sCampoActivo := NombreCampoESACTIVO;
  bDesactivable := (sCampoActivo <> '') and
                   Assigned(dsTablaG.DataSet) and
                   (dsTablaG.DataSet.FindField(sCampoActivo) <> nil);
  // Si el registro ya esta desactivado, no ofrecemos "desactivar" otra vez:
  // el usuario tendra solo Borrar/Cancelar.
  if bDesactivable and
     SameText(dsTablaG.DataSet.FieldByName(sCampoActivo).AsString, 'N') then
    bDesactivable := False;
  iHijos := ContarHijosActivos;
  sDescHijos := DescripcionHijos;
  if sDescHijos = '' then
    sDescHijos := SDescripcionHijosGenerica;
  // Caso 1: tabla no desactivable y sin hijos -> confirmacion simple Si/No.
  if (not bDesactivable) and (iHijos = 0) then
  begin
    if Application.MessageBox(
        PChar(SPreguntaEliminarRegistro),
        PChar(STituloConfirmarEliminacion),
        MB_YESNO + MB_ICONWARNING) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
  end
  // Caso 2: tabla no desactivable pero tiene hijos -> avisar y Si/No.
  else if not bDesactivable then
  begin
    sMsg := Format(SPreguntaEliminarRegistroConHijos,
                   [iHijos, sDescHijos]);
    if Application.MessageBox(PChar(sMsg),
        PChar(STituloConfirmarEliminacion),
        MB_YESNO + MB_ICONWARNING + MB_DEFBUTTON2) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
  end
  // Caso 3 y 4: tabla desactivable, con o sin hijos.
  else
  begin
    if iHijos > 0 then
      sMsg := Format(SAvisoDesactivarRegistroConHijos,
                     [iHijos, sDescHijos])
    else
      sMsg := SAvisoDesactivarRegistroSinHijos;
    sMsg := sMsg + STextoOpcionesBorradoRegistro;
    iResp := Application.MessageBox(PChar(sMsg),
               PChar(STituloConfirmarEliminacion),
               MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON1);
    case iResp of
      ID_YES: Result := abDesactivar;
      ID_NO: Result := abContinuar;
    else
      Result := abCancelar;
    end;
  end;
end;

procedure TfrmMtoGen.actRegistroAnteriorExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    nvNavegador.Buttons.Prior.Click;
end;

procedure TfrmMtoGen.actRegistroSiguienteExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    nvNavegador.Buttons.Next.Click;
end;

procedure TfrmMtoGen.actInsertarRegistroExecute(Sender: TObject);
begin
  if Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     PuedeAccionMto(apmInsertar) then
    dsTablaG.DataSet.Insert;
end;

procedure TfrmMtoGen.actPrimerRegistroExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    dsTablaG.DataSet.First;
end;

procedure TfrmMtoGen.actUltimoRegistroExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    dsTablaG.DataSet.Last;
end;

// Ctrl+AvPag / Ctrl+RePag: salto de bloque en el grid principal. Las teclas
// AvPag / RePag sueltas ya mueven de registro en registro
// (actRegistroSiguiente / actRegistroAnterior); con Ctrl saltan un bloque de
// SALTO_BLOQUE filas de una vez.
procedure TfrmMtoGen.actAvanzarBloqueExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    MoverFocoGridBloque(True);
end;

procedure TfrmMtoGen.actRetrocederBloqueExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    MoverFocoGridBloque(False);
end;

// Mueve el foco del grid principal un bloque de filas respetando la
// ordenacion visual del grid via FocusedRowIndex (igual que Ctrl+Inicio /
// Ctrl+Fin). Clampa a [0, ultima fila] para no salirse del dataset.
procedure TfrmMtoGen.MoverFocoGridBloque(AAvanzar: Boolean);
const
  SALTO_BLOQUE = 10;  // filas por pulsacion de Ctrl+AvPag / Ctrl+RePag
var
  iDelta  : Integer;
  iNuevo  : Integer;
  iUltimo : Integer;
begin
  if AAvanzar then
    iDelta := SALTO_BLOQUE
  else
    iDelta := -SALTO_BLOQUE;
  if Assigned(cxGrdDBTabPrin) then
  begin
    iUltimo := cxGrdDBTabPrin.DataController.RowCount - 1;
    if iUltimo >= 0 then
    begin
      iNuevo := cxGrdDBTabPrin.DataController.FocusedRowIndex + iDelta;
      if iNuevo < 0 then
        iNuevo := 0;
      if iNuevo > iUltimo then
        iNuevo := iUltimo;
      cxGrdDBTabPrin.DataController.FocusedRowIndex := iNuevo;
    end;
  end;
end;

procedure TfrmMtoGen.actEditarRegistroExecute(Sender: TObject);
begin
  if Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     PuedeAccionMto(apmModificar) then
    dsTablaG.DataSet.Edit;
end;

procedure TfrmMtoGen.actGrabarRegistroUpdate(Sender: TObject);
var
  bPermitido: Boolean;
begin
  bPermitido :=
    ((dsTablaG.State = dsInsert) and
     PuedeAccionMto(apmInsertar)) or
    ((dsTablaG.State = dsEdit) and
     PuedeAccionMto(apmModificar));
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    bPermitido;
end;

procedure TfrmMtoGen.actGrabarRegistroExecute(Sender: TObject);
begin
  if Assigned(dsTablaG.DataSet) and
     (((dsTablaG.State = dsInsert) and
       PuedeAccionMto(apmInsertar)) or
      ((dsTablaG.State = dsEdit) and
       PuedeAccionMto(apmModificar))) then
    dsTablaG.DataSet.Post;
end;

procedure TfrmMtoGen.actFotoArticuloExecute(Sender: TObject);
begin
  FGestorArticulos.AlternarFoto;
end;

procedure TfrmMtoGen.actConsultaStockExecute(Sender: TObject);
begin
  FGestorArticulos.ConsultarStock;
end;

procedure TfrmMtoGen.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
begin
  FGestorArticulos.ResolverPorDefecto(
    ACodArt, ACodSku);
end;

procedure TfrmMtoGen.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  ResolverArtSkuActivo(ACodArt, ACodSku);
end;

function TfrmMtoGen.DataSourcesParaFoto: TArray<TDataSource>;
begin
  Result := FGestorArticulos.DataSourcesPorDefecto;
end;

function TfrmMtoGen.NombreCampoESACTIVO: string;
begin
  Result := '';
end;

function TfrmMtoGen.ContarHijosActivos: Integer;
begin
  Result := 0;
end;

function TfrmMtoGen.DescripcionHijos: string;
begin
  Result := '';
end;

procedure TfrmMtoGen.SimulateTabKey;
var
  Inputs: array[0..1] of TInput;
begin
  ZeroMemory(@Inputs, SizeOf(Inputs));
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_TAB;
  Inputs[1].Itype := INPUT_KEYBOARD;
  Inputs[1].ki.wVk := VK_TAB;
  Inputs[1].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(2, Inputs[0], SizeOf(TInput));
end;

procedure TfrmMtoGen.FormShow(Sender: TObject);
begin
  inherited;
  ResetForm;
  // Si la pantalla flotante de fotos ya esta abierta (el usuario
  // pulso Ctrl+F en otro Mto), la re-vinculamos a este. Si no
  // esta abierta, no la abrimos: que aparezca solo cuando el usuario
  // lo pida con Ctrl+F.
  if Assigned(FAnfitrionMto) then
    FAnfitrionMto.VincularFotoMantenimiento(Self);
  // Foco inicial en la busqueda global del Mto. Se difiere con ForceQueue
  // porque el Mto se acaba de embeber en su TcxTabSheet (inLibFormManager)
  // y la cadena de foco aun no esta asentada: un SetFocus sincrono aqui no
  // "pega" (por eso seguia desactivado en ResetForm). La carga async de la
  // lista no roba el foco de ventana, asi que al drenar la cola el foco
  // queda en la busqueda. CanFocus salta la instancia de busqueda (Ctrl+A),
  // donde edtBusqGlobal va oculto.
  TThread.ForceQueue(nil,
    procedure
    begin
      if (not (csDestroying in ComponentState)) and
         edtBusqGlobal.CanFocus then
        edtBusqGlobal.SetFocus;
    end);
end;

procedure TfrmMtoGen.pcPantallaPageChanging(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);
begin
  inherited;
  if ( (not NewPage.Visible) and
       (not NewPage.Enabled) and
       (NewPage.Name = 'tsFicha')) then
    AllowChange := False;
end;

procedure TfrmMtoGen.ProcesarPerfiles;
begin
  FGestorPerfiles.CargarPerfil(
    IdentidadSesion.Usuario, IdentidadSesion.Grupo);
  oPerfilDic := FGestorPerfiles.Perfil;
  CrearTablaPrincipal;
  AplicarEtiquetas;
  FGestorGuias.ReaplicarVisibilidad;
  // Permisos por pantalla: ocultan/deshabilitan los controles segun
  // consultar, insertar, modificar, borrar, excel e imprimir.
  AplicarPermisosPantalla;
end;

procedure TfrmMtoGen.rbBBDDClick(Sender: TObject);
begin
  inherited;
  if (rbBBDD.Checked = true) then
    rbGrid.Checked := false
  else
    rbGrid.Checked := true;
end;

procedure TfrmMtoGen.rbGridClick(Sender: TObject);
begin
  inherited;
  if rbGrid.Checked = true then
    rbBBDD.Checked := false
  else
    rbBBDD.Checked := true;
end;

procedure TfrmMtoGen.ResetForm;
begin
  if ((pcPantalla.ActivePage <> tsLista) and (tsLista.TabVisible = true)) then
    pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoGen.edtBusqGlobalPropertiesChange(Sender: TObject);
begin
  inherited;
  tmrBusqGlobal.Enabled := False;
  tmrBusqGlobal.Enabled := True;
end;

procedure TfrmMtoGen.tmrBusqGlobalTimer(Sender: TObject);
begin
  inherited;
  tmrBusqGlobal.Enabled := False;
  BusqAllGrid(cxGrdDBTabPrin,
              edtBusqGlobal.Text);
  if ((pcPantalla.ActivePage <> tsLista) and (tsLista.TabVisible = true)) then
    pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoGen.btnCancelarClick(Sender: TObject);
var
  i: Integer;
begin
  inherited;
  // Flujo normal dentro de fzam: cancela el Mto activo del principal.
  if Assigned(FAnfitrionMto) then
    FAnfitrionMto.CancelarEdicionesPantallas
  else
    // Fuera de fzam (pruebas standalone, DESARROLLOS EN CURSO) Owner no
    // es el principal y no hay pcPrincipal al que cancelar:
    // se cancelan los datasets en edicion de los grids de ESTE form.
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TcxGridDBTableView then
        if (TcxGridDBTableView(Components[i]).DataController.DataSource <>
            nil) and
           (TcxGridDBTableView(Components[i]).DataController.DataSet <>
            nil) and
           (TcxGridDBTableView(Components[i]).DataController.DataSet.State in
            [dsEdit, dsInsert]) then
          TcxGridDBTableView(Components[i]).DataController.DataSet.Cancel;
end;

procedure TfrmMtoGen.sbExportExcelClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxGrdPrincipal, 'Listado');
end;

procedure TfrmMtoGen.EjecutarModalGuias;
var
  oFormulario: TfrmModalGridGuias;
begin
  oFormulario := TfrmModalGridGuias.Create(Application);
  try
    oFormulario.sFormulario := Self.Name;
    oFormulario.FDataSet := nil;
    if Assigned(dsTablaG) and
       Assigned(dsTablaG.DataSet) then
      oFormulario.FDataSet := dsTablaG.DataSet;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

function TfrmMtoGen.SolicitarDestinoPerfil(
  const ADescripcion: string;
  ADescripcionEditable: Boolean;
  out APermisos: string): Boolean;
var
  oFormulario: TfrmModalGenImpSave;
begin
  Result := False;
  APermisos := '';
  oFormulario := TfrmModalGenImpSave.Create(Application);
  try
    oFormulario.edtNombreOrigen.Text := Self.Name;
    oFormulario.edtDescripcion.Text := ADescripcion;
    oFormulario.edtDescripcion.Enabled :=
      ADescripcionEditable;
    oFormulario.ShowModal;
    if oFormulario.sFicha = 'S' then
    begin
      APermisos := oFormulario.cbbPermisos.Text;
      Result := True;
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

// ===========================================================================
//   Filtros guardados (desplegable junto a "Guardar Excel")
// ===========================================================================
// Guardan y comparten DataController.Filter de la lista principal con
// nombre propio. Independientes del filtro incidental que ya guarda
// "Grabar Grid" (sbGrabarGridClick) junto con el layout. Ver
// Los contratos de lectura, escritura y comparticion dan acceso a BBDD
// (fza_filtros_guardados / fza_filtros_guardados_compartidos).

procedure TfrmMtoGen.sbFiltrosClick(Sender: TObject);
begin
  FGestorFiltros.MostrarMenu(sbFiltros);
end;

function TfrmMtoGen.SolicitarDatosFiltro:
  TDatosGuardadoFiltroMto;
var
  oResultado: TGuardarFiltroResult;
begin
  oResultado := TfrmModalGuardarFiltro.Ejecutar(Self);
  Result.Aceptado := oResultado.Aceptado;
  Result.Nombre := oResultado.Nombre;
  Result.Descripcion := oResultado.Descripcion;
end;

function TfrmMtoGen.EjecutarGestionFiltros(
  const AFiltroActualBase64: string):
  TResultadoGestionFiltroMto;
var
  oResultado: TGestionFiltrosResult;
begin
  oResultado := TfrmModalGestionFiltros.Ejecutar(
    Self, Self.Name, cxGrdDBTabPrin.Name,
    cxGrdDBTabPrin, AFiltroActualBase64,
    FiltrosDestinos);
  Result.Aplicado := oResultado.Aplicado;
  Result.FiltroBase64 := oResultado.FiltroBase64;
end;

initialization

finalization

end.
