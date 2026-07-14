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
  UniDataPerfiles, Uni, inLibDir, inLibtb, Data.DBCommon, inLibWin,
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
  dxSkinXmas2008Blue, System.Generics.Collections, System.Actions, Vcl.ActnList,
  System.Threading;
type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  THackWinControl = class(TWinControl);
  // Resultado del dialogo de borrado: cancelar, desactivar o borrar igual.
  TAccionBorrado = (abContinuar, abDesactivar, abCancelar);
  TfrmMtoGen = class(TfrmBase)
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
    // Conexion propia del Mto (Fase 1 multithreading). Se clona de `oConn`
    // global al crear el data module y se reasigna a todas las queries/SPs
    // via TdmBase.ReasignarConexion. Asi dos pestañas dejan de serializarse
    // sobre la misma TUniConnection — cada una agarra una conexion fisica
    // distinta del pool. Liberada en Destroy DESPUES del data module para
    // que los Close implicitos de las queries no queden colgando.
    FConn: TUniConnection;
    // Overlay para Fase 2 (background): panel que cubre el Mto entero
    // mientras corre una tarea en thread. Otros tabs siguen interactivos
    // porque cada Mto vive embebido en su propio TcxTabSheet.
    FOverlayOcupado: TPanel;
    FTareasEnCurso: Integer;
    // Lista de ITask vivos para poder esperarlos en Destroy. Sin esto,
    // cerrar un tab mientras un Open async sigue ejecutando provoca AV:
    // el thread accederia a la TUniQuery / FConn ya liberadas. La lista
    // se crea lazy en EjecutarEnBackground y se libera en Destroy
    // despues del WaitForAll.
    FTareasActivas: TList<ITask>;
    // Popup de selector de columnas (boton derecho en grid)
    FPopMenuColumnas: TPopupMenu;
    FSqlOriginalTablaG: string;
    FSqlBaseBusquedaExterna: string;
    FCamposGuia: TStringList;
    FCamposGuiaTabla: TStringList;
    FColumnasVisiblesGuia: TStringList;
    // Hook BeforeDelete del dataset principal original (en el data module).
    // Lo conservamos para reinvocarlo cuando la accion final sea Borrar; si
    // el usuario elige Desactivar o Cancelar lo saltamos.
    FBeforeDeleteOrig: TDataSetNotifyEvent;
    FGuardianBorradoInstalado: Boolean;
    FFiltroMenuBase64: string;
    FBusqGlobalMenu: string;
    // Filtros guardados (desplegable junto a "Guardar Excel"). Guardan y
    // comparten DataController.Filter de la lista principal con nombre
    // propio, independiente del layout de columnas.
    procedure CargarMenuFiltros;
    function SerializarFiltroActualBase64: string;
    function ExtraerBusquedaGlobalDelFiltro: string;
    procedure RestaurarFiltroCapturado;
    procedure AplicarFiltroDesdeBase64(const ABase64: string);
    procedure AplicarFiltroGuardadoClick(Sender: TObject);
    procedure GuardarFiltroActualClick(Sender: TObject);
    procedure GestionarFiltrosClick(Sender: TObject);
    procedure InstalarGuardianBorrado;
    procedure GuardianBeforeDelete(DataSet: TDataSet);
    procedure PopMenuColumnasPopup(Sender: TObject);
    procedure PopMenuColumnaClick(Sender: TObject);
    procedure PopMenuNuevaGuiaClick(Sender: TObject);
    procedure PopMenuRenombrarClick(Sender: TObject);
    procedure BorrarGuiasGrid;
    procedure CargarPerfilesComunes(sUser:string = 'Todos');
    // Decide que dialogo mostrar al ejecutar actEliminarRegistro segun
    // NombreCampoESACTIVO y ContarHijosActivos.
    function PreguntarAccionBorrado: TAccionBorrado;
    function FocoEnEditorTexto: Boolean;
    function PuedeCambiarRegistroPorTecla: Boolean;
    // Mueve el foco del grid principal un bloque de filas (Ctrl+AvPag /
    // Ctrl+RePag). AAvanzar=True baja el bloque, False lo sube.
    procedure MoverFocoGridBloque(AAvanzar: Boolean);
//    procedure CollectSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
//                                        const sName: string;
//                                        const sProfile: string;
//                                        AList: TPerfilList);
  protected
    procedure AplicarGuiasGrid(AQuery: TUniQuery);
    // Recorre los campos abiertos y deja en el log un error por cada
    // columna cuyo nombre empieza por `ES` (boolean por convencion del
    // proyecto) pero esta tipada como numerica. Sirve para cazar las
    // EConvertError 'X is not a valid floating point value' que se
    // disparan al fetch — la fuente real suele ser metadata de vista
    // desactualizada tras un ALTER TABLE.
    procedure DiagnosticarCamposBooleanos(AQuery: TUniQuery;
                                          const AContexto: string);
    // Indica si las teclas de navegacion (PgUp, PgDn, Home, End, Ins, F2)
    // deben activar las acciones del TActionList base. Los Mtos con
    // editores multilinea (SynEdit, etc.) sobreescriben para devolver
    // False cuando el editor tiene el foco.
    function PermitirNavegacionTeclas: Boolean; virtual;
    // Clona los params relevantes de `oConn` global y devuelve una nueva
    // TUniConnection ya conectada (usa el pool de UniDAC). Los Mtos
    // especializados pueden override para variantes (p.ej. una replica
    // de solo-lectura), aunque por defecto basta el clon plano.
    function CrearConexionPropia: TUniConnection; virtual;
    // Crea/oculta el overlay "Procesando..." sobre este Mto. Reentrante:
    // varias llamadas a Bloquear=True solo muestran el overlay una vez,
    // y solo se oculta cuando todas se compensan con un False.
    procedure BloquearTabPorOcupado(Bloquear: Boolean);
    // Inyecta SqlRestriccionUsuario en la SQL de la tabla principal antes
    // de abrirla (precarga). Idempotente: si el filtro ya esta en la SQL
    // (reapertura, o el propio Mto lo integro en su ConstruirWhere*) no
    // toca nada. Cierra la query si venia activa del DFM streaming.
    procedure AplicarRestriccionUsuario(unqry: TUniQuery);
  public
    tdmDataModule:TObject;
    sDataModuleName:string;
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
    procedure AplicarEtiquetas;     virtual;
    procedure CrearTablaPrincipal;  virtual;
    procedure ResetForm;  virtual;
    // Aplica los permisos por pantalla (<CALL>.consultar / insertar /
    // modificar / borrar / excel) ocultando o deshabilitando los
    // controles correspondientes. Las pantallas sin CALL no se tocan.
    procedure AplicarPermisosPantalla;
    // True si el usuario puede imprimir informes de esta pantalla. Los
    // Mtos con boton de impresion la consultan antes de imprimir.
    function PuedeImprimir: Boolean;
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
var
  frmMtoGen: TfrmMtoGen;
  sConsultaO:string;
  sConsultaP:string;

implementation

{$R *.dfm}

uses inMtoGenSearch,
     inLibGlobalVar,
     inLibPermisos,
     inLibUnitForm,
     inLibShowMto,
     inLibLog,
     inMtoModalGenImpSave,
     UniDataFiltros, inMtoModalGuardarFiltro, inMtoModalGestionFiltros,
     System.NetEncoding,
     UniDataGen, uGenericIfThen, inMtoPrincipal,
     inLibFotos, inMtoFotoArticulo, inMtoStockConsulta,
     inLibGridColumnChooser, inMtoModalGridGuias,
     inLibInformesGuiasCache,
     inLibFiltroUsuario,    // restricción por empresa/almacén/caja
     SQLBuilder4D, SQLBuilder4D.Parser, SQLBuilder4D.Parser.GaSQLParser,
     System.Diagnostics,    // TStopwatch para cronometrar carga inicial
     System.StrUtils,       // StartsText en DiagnosticarCamposBooleanos
     System.TypInfo,        // GetEnumName del TFieldType en el log
     Vcl.ComCtrls;          // TProgressBar marquee en overlay de carga
     // System.Threading ya esta en el interface (para TList<ITask>).

procedure TfrmMtoGen.AbrirPerfiles(bTabVisible:Boolean);
begin
  if (bTabVisible = true) then
  begin
    if (tdmDataModule = nil) then //es caja de busqueda modal
    begin
      with (Self as TfrmMtoSearch).unqryPerfiles do
      begin
        Connection := oConn;
        if ((Pos('Nothing', SQL.Text) > 0) or
            (Trim(SQL.Text) = '')
           ) then
        begin
          SQL.Text :='SELECT * '+
                     '  FROM fza_usuarios_perfiles ' +
                     ' WHERE (KEY_USUPER = :NameFormModule)';
          ParamByName('NameFormModule').AsString := Self.Name;
        end;
        if (Active = false) then
          Open;
      end;
    end
    else //es modulo mantenimiento
      begin
        with (tdmDataModule as TdmBase).unqryPerfiles do
        begin
          tvPerfil.DataController.DataSource :=
                                          (tdmDataModule as TdmBase).dsPerfiles;
          Connection := oConn;
          if ( (Pos('Nothing', SQL.Text) > 0) or
               (Trim(SQL.Text) = '') or
               (Pos(':NameDataModule', SQL.Text ) > 0)
             ) then
          begin
            SQL.Text :=   'SELECT * '+
                          '  FROM fza_usuarios_perfiles ' +
                          ' WHERE ((KEY_USUPER = :NameDataModule) ' +
                          '    OR  (KEY_USUPER = :NameFormModule)) ';
            ParamByName('NameDataModule').AsString := Self.Name;
            ParamByName('NameFormModule').AsString :=
                                                (tdmDataModule as TdmBase).Name;
          end;
          if (Active = false) then
            Open;
        end;
      end;
  end;
end;

procedure TfrmMtoGen.AplicarEtiquetas;
var
  i:integer;
  cxGrid: TcxCustomGridTableView;
  oGrids: TList<TcxCustomGridTableView>;
begin
  // El dataset puede ser TUniQuery (mantenimientos normales) o
  // TUniStoredProc (formularios de busqueda lanzados con un SP, p.ej.
  // F3 en caja -> BuscarArticulo -> PRC_BUSQUEDA_ARTICULOS). Si es
  // stored proc no hay tabla origen que mostrar: usamos el nombre del
  // SP. Antes hacia 'as TUniQuery' a secas y reventaba con EInvalidCast.
  if (DsTablaG.Dataset <> nil) then
  begin
    if DsTablaG.Dataset is TUniQuery then
      lblTablaOrigen.Caption :=
        GetTableNameFromQuery(TUniQuery(DsTablaG.Dataset).SQL.Text)
    else if DsTablaG.Dataset is TUniStoredProc then
      lblTablaOrigen.Caption := TUniStoredProc(DsTablaG.Dataset).StoredProcName
    else
      lblTablaOrigen.Caption := '';
  end;
  oGrids := TList<TcxCustomGridTableView>.Create;
  try
    for i := 0 to Self.ComponentCount - 1 do
      if Self.Components[i] is TcxCustomGridTableView then
        oGrids.Add(TcxCustomGridTableView(Self.Components[i]));
    if SameText(Trim(GetPerfilValueDef(oPerfilDic, 'oCreateItems', 'False')),
                'True') then
    begin
      for cxGrid in oGrids do
      begin
        if SameText(Trim(GetPerfilValueDef(oPerfilDic,
                          cxGrid.Name
                            + '__oCreateItems', 'False')), 'True') then
        begin
          // Creamos sólo las columnas para los Fields que aún no estén en
          // la vista. La llamada antigua a DataController.CreateAllItems
          // duplicaba todas las columnas existentes (del DFM y de la
          // ejecución previa de CrearTablaPrincipal) en cada apertura del
          // form, lo que descolocaba el orden tras Alt+F12.
          cxGrid.BeginUpdate;
          try
            CrearItemsFaltantes(cxGrid);
          finally
            cxGrid.EndUpdate;
          end;
        end;
      end;
    end;
    if SameText(Trim(GetPerfilValueDef(oPerfilDic, 'oApplyWidth', 'False')),
                'True') then
    begin
      for cxGrid in oGrids do
      begin
        // Segunda validación segura
        if SameText(Trim(GetPerfilValueDef(oPerfilDic,
                          cxGrid.Name + '__oApplyWidth', 'False')), 'True') then
        begin
          PonerAnchosTitulos(cxGrid, Self.Name, oPerfilDic);
          RestaurarFocoGrid(cxGrid, oPerfilDic);
        end;
      end;
    end;
  finally
    FreeAndNil(oGrids);
  end;
  Self.Caption := GetPerfilValueDef(oPerfilDic, 'Caption', Self.Caption);
  if SameText(Trim(GetPerfilValueDef(oPerfilDic, 'oRenameComponents', 'False')),
              'True') then
    SetLabelForm(Self, oPerfilDic);

end;

procedure TfrmMtoGen.btnCargarCaptionsClick(Sender: TObject);
begin
  inherited;
  CargarCaptions(Self, Self.Owner);
end;

procedure TfrmMtoGen.btnCargarColumnasClick(Sender: TObject);
var
  i:Integer;
  cxGrid : TcxCustomGridTableView;
begin
  inherited;
  for i:= 0 to Self.Componentcount - 1 do
  begin
      if (Self.Components[i] is TcxCustomGridTableView) then
    begin
      cxGrid := TcxCustomGridTableView(Self.Components[i]);
      GetSettingsColumn(cxGrid, Self.Name, Self.Owner);
    end;
  end;
end;

procedure TfrmMtoGen.btnCargarVblesGlobClick(Sender: TObject);
begin
  inherited;
  CargarPerfilesComunes;
  CargarPerfilesParticulares;
end;

procedure TfrmMtoGen.btnGrabarClick(Sender: TObject);
var
  ConnGrabar: TUniConnection;
begin
  inherited;
  if tdmDataModule = nil then
    Exit;
  // Si el Mto tiene conexion propia (Fase 1), la transaccion DEBE ir
  // contra ella: las queries del data module ya apuntan a FConn via
  // ReasignarConexion, asi que un StartTransaction sobre oConn no las
  // cubriria y el commit/rollback no afectaria a los ApplyUpdates.
  if Assigned(FConn) then
    ConnGrabar := FConn
  else
    ConnGrabar := oDmConn.conUni;
  Screen.Cursor := crHourGlass;
  try
    try
       if not ConnGrabar.InTransaction then
         ConnGrabar.StartTransaction;
      GrabarDatasets(tdmDataModule as TDataModule);
      if ConnGrabar.InTransaction then
        ConnGrabar.Commit;
      ShowMessage('Datos guardados correctamente');
    except
      on E: EAbort do
      begin
        // EAbort es la excepción silenciosa estándar (BeforePost que
        // llama a Abort cuando el dataset no debe persistirse por la
        // vía estándar, p. ej. vistas en JOIN que se actualizan a mano).
        // Cerramos la transacción y salimos sin mensaje.
        if ConnGrabar.InTransaction then
          ConnGrabar.Rollback;
      end;
      on E: Exception do
      begin
        if ConnGrabar.InTransaction then
          ConnGrabar.Rollback;
        raise Exception.Create('Error al grabar: ' + E.Message);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoGen.btnSalirClick(Sender: TObject);
const
  WM_FREECONTROL = WM_USER + 1;
var
  ts: TcxTabSheet;
  formMain: TCustomForm;
begin
  inherited;
  if not (Self.Parent is TcxTabSheet) then
    Exit;
  if (tdmDataModule <> nil) and
     CheckOpenDatasets(tdmDataModule as TDataModule) then
  begin
    if Application.MessageBox('Hay datos no grabados. ' +
                              '¿Desea grabar los cambios?',
                              'Mensaje de Advertencia',
                              MB_YESNO + MB_ICONQUESTION) = ID_YES then
    begin
      btnGrabarClick(Sender);
      ShowMessage('Cambios grabados');
    end
    else
    begin
      CancelarDatasets(tdmDataModule as TDataModule);
      ShowMessage('Cambios revertidos/cancelados');
    end;
  end;
  if (Self.Parent is TcxTabSheet) then
  begin
    ts := TcxTabSheet(Self.Parent);
    formMain := Application.MainForm;
    PostMessage(formMain.Handle, WM_FREECONTROL, 0, LParam(ts));
  end;
end;

procedure TfrmMtoGen.sbGrabarGridClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  bGuardar: Boolean;
  sPermisos: string;
  i: Integer;
  cxGrid: TcxCustomGridTableView;
  oList: TPerfilList;
  item: TPerfilItem;
begin
  inherited;
  bGuardar := False;

  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text   := Self.Name;
    formulario.edtDescripcion.Text    := 'Grabar Grids';
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
    begin
      bGuardar  := True;
      sPermisos := formulario.cbbPermisos.Text;
    end;
  finally
    FreeAndNil(formulario);
  end;

  if not bGuardar then Exit;

  Screen.Cursor := crHourGlass;
  (tdmDataModule as TdmBase).ResetGridsProfile('', Self.Name, sPermisos);
  oList := TPerfilList.Create;
  try
    // 1. Perfiles comunes
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    for var par in [
      TPair<string,string>.Create('oRenameComponents',
        GetPerfilValueDef(oPerfilDic, 'oRenameComponents', 'False')),
      TPair<string,string>.Create('oCreateItems',
        GetPerfilValueDef(oPerfilDic, 'oCreateItems',      'False')),
      TPair<string,string>.Create('oBusqGlobal',
        GetPerfilValueDef(oPerfilDic, 'oBusqGlobal',       'Grid')),
      TPair<string,string>.Create('oApplyWidth',       'True'),
      TPair<string,string>.Create('oMostrarPerfil',
        GetPerfilValueDef(oPerfilDic, 'oMostrarPerfil',    'False')),
      TPair<string,string>.Create('oGetSQLFromDB',
        GetPerfilValueDef(oPerfilDic, 'oGetSQLFromDB',     'False'))
    ] do
    begin
      item.SubKey := par.Key;
      item.Value  := par.Value;
      oList.Add(item);
    end;

    // 2. Ajustes de cada grid
    for i := 0 to Self.ComponentCount - 1 do
      if Self.Components[i] is TcxCustomGridTableView then
      begin
        cxGrid := TcxCustomGridTableView(Self.Components[i]);

        // reset sigue siendo su propia transacción (borra primero)


        item.SubKey := cxGrid.Name + '__oApplyWidth';
        item.Value  := 'True';
        oList.Add(item);

        item.SubKey := cxGrid.Name + '__oCreateItems';
        item.Value  := GetPerfilValueDef(oPerfilDic,
                                         cxGrid.Name + '__oCreateItems',
                                         'False');
        oList.Add(item);

        CollectSettingsColumnProfile(cxGrid, Self.Name, sPermisos, oList);
      end;

    // 3. Perfiles particulares del Mto (hook para descendientes — por
    // ejemplo TfrmMtoArticulos lo usa para grabar los filtros de carga
    // de la pestanya Lista).
    RecogerPerfilesParticulares(oList, sPermisos);

    oConn.StartTransaction;
    try
      odmPerfiles.GrabarPerfilesBatch(oList);
      // aquí puedes seguir llamando a GrabarPerfilDatam / CargarCaptions
      // si antes los refactorizas también para que acepten la lista
      oConn.Commit;
    except
      oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oList);
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoGen.sbResetGridClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  bGuardar: Boolean;
  sPermisos:String;
  i:Integer;
  cxGrid : TcxCustomGridTableView;
begin
  inherited;
  bGuardar := False;
  formulario := TfrmModalGenImpSave.Create(Self);
  try
    formulario.edtNombreOrigen.Text := Self.Name;
    formulario.edtDescripcion.Text := 'Reset Grids';
    formulario.ShowModal;
    if (formulario.sFicha = 'S') then
    begin
      bGuardar := True;
      sPermisos := formulario.cbbPermisos.Text;
    end;
  finally
    FreeAndNil(formulario);
  end;
  if bGuardar then
  begin
    for i:= 0 to Self.Componentcount - 1 do
    begin
      if (Self.Components[i] is TcxCustomGridTableView) then
      begin
        cxGrid := TcxCustomGridTableView(Self.Components[i]);
        (tdmDataModule as TdmBase).ResetGridsProfile(cxGrid.Name,
                                                     Self.Name,
                                                     sPermisos);
      end;
    end;
    // Borrar guias de grid asociadas al layout
    BorrarGuiasGrid;
  end;
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
  if FGuardianBorradoInstalado then
    Exit;
  ds := dsTablaG.DataSet;
  if ds = nil then
    Exit;
  // Encadenamos: el handler original (p.ej. cascada de DELETE de lineas y
  // recibos en facturas) sigue ejecutandose si la accion final es Borrar.
  FBeforeDeleteOrig := ds.BeforeDelete;
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

procedure TfrmMtoGen.GuardianBeforeDelete(DataSet: TDataSet);
var
  sCampoActivo: string;
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
          if not (DataSet.State in [dsEdit, dsInsert]) then
            DataSet.Edit;
          DataSet.FieldByName(sCampoActivo).AsString := 'N';
          DataSet.Post;
        end;
        Abort;
      end;
    abContinuar:
      if Assigned(FBeforeDeleteOrig) then
        FBeforeDeleteOrig(DataSet);
  end;
end;

procedure TfrmMtoGen.CargarPerfilesComunes(sUser:string = 'Todos');
begin
  with odmPerfiles do
  begin
    GrabarPerfil(sUser, Self.Name, 'oRenameComponents', 'False' );
    GrabarPerfil(sUser, Self.Name, 'oCreateItems', 'False' );
    GrabarPerfil(sUser, Self.Name, 'oBusqGlobal', 'Grid' );
    GrabarPerfil(sUser, Self.Name, 'oApplyWidth', 'True' );
    GrabarPerfil(sUser, Self.Name, 'oMostrarPerfil', 'False' );
    GrabarPerfil(sUser, Self.Name, 'oGetSQLFromDB', 'False' );
  end;
end;

procedure TfrmMtoGen.CargarPerfilesParticulares;
begin
  if (tdmDataModule <> nil) then
    GrabarPerfilDatam((tdmDataModule as TdmBase), Self.Owner);
end;

procedure TfrmMtoGen.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                 const sPermisos: string);
begin
end;

procedure TfrmMtoGen.PrepararBusquedaExterna(const ABusq: string);
var
  unqry: TUniQuery;
  aCampos, aValores: TArray<string>;
  i: Integer;
  sBase, sWhere: string;
begin
  if (ABusq = '') or (pkFieldName = '') then
    Exit;
  if (tdmDataModule = nil) or not (tdmDataModule is TdmBase) then
    Exit;
  unqry := TdmBase(tdmDataModule).unqryTablaG;
  if unqry = nil then
    Exit;
  unqry.Close;
  // Guardar SQL base la primera vez; restaurarla en llamadas siguientes
  // para que los WHERE de busquedas anteriores no se acumulen.
  if FSqlBaseBusquedaExterna = '' then
    FSqlBaseBusquedaExterna := unqry.SQL.Text
  else
    unqry.SQL.Text := FSqlBaseBusquedaExterna;
  // PK compuesta: pkFieldName usa ';' (convencion Locate de Delphi),
  // ABusq usa ',' como separador de valores.
  aCampos  := pkFieldName.Split([';']);
  aValores := ABusq.Split([',']);
  sWhere := '';
  for i := 0 to High(aCampos) do
  begin
    if (i <= High(aValores)) and (Trim(aCampos[i]) <> '') then
    begin
      if sWhere <> '' then
        sWhere := sWhere + ' AND ';
      sWhere := sWhere + Trim(aCampos[i]) + ' = ' +
        QuotedStr(Trim(aValores[i]));
    end;
  end;
  if sWhere <> '' then
  begin
    // Se envuelve la SELECT base como subconsulta y se filtra fuera, en vez
    // de parsearla con SQLBuilder4D para inyectarle el WHERE: ese parser no
    // traga algunas SELECT del modelo (p.ej. Facturas: subconsulta en la
    // lista de campos + ORDER BY) y lanzaba EgaSQLInvalidParseState — que,
    // aun capturada, hacia saltar el aviso del depurador. Asi vale para
    // cualquier SELECT, no se levanta ninguna excepcion y filtra a la fila
    // buscada. Se quita el ';' final de la SQL base por si lo trae.
    sBase := TrimRight(FSqlBaseBusquedaExterna);
    while (sBase <> '') and (sBase[Length(sBase)] = ';') do
      sBase := TrimRight(Copy(sBase, 1, Length(sBase) - 1));
    unqry.SQL.Text := 'SELECT * FROM (' + sLineBreak +
      sBase + sLineBreak + ') sub_busqueda WHERE ' + sWhere;
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
  if Self.Owner <> nil then
    sNameModule :=
     (Self.Owner as TfrmMtoPrincipal).oFzaWinf.GetDataModuleName(Self.UnitName +
                                                          '.' + Self.ClassName);
  if (sNameModule <> '') then
  begin
    swTramo := TStopwatch.StartNew;
    tdmDataModule := CrearDataModule(sNameModule, Self);
    msCrearDM := swTramo.ElapsedMilliseconds;
    // Conexion propia del Mto: la creamos si todavia no existe y la
    // inyectamos en todas las queries/SPs del data module recien creado.
    // El DataModule sigue arrancando con `oConn` en su DoCreate, lo cual
    // es necesario para que el .dfm streaming no se queje; aqui hacemos
    // el switch antes de cualquier Open real.
    if FConn = nil then
    try
      swTramo := TStopwatch.StartNew;
      FConn := CrearConexionPropia;
      msFConn := swTramo.ElapsedMilliseconds;
    except
      on E: Exception do
      begin
        inliblog.Log.LogError('No se pudo crear conexion propia para ' +
          Self.Name + ': ' + E.Message + '. Se sigue usando oConn global.');
        FConn := nil;
      end;
    end;
    if Assigned(FConn) then
    begin
      swTramo := TStopwatch.StartNew;
      (tdmDataModule as TdmBase).ReasignarConexion(FConn);
      msReasignar := swTramo.ElapsedMilliseconds;
    end;
  end;
  inherited;
  inLibLog.Log.LogPerf(Self.Name + '.CrearTablaPrincipal',
    Format('CrearDM=%d ms | FConn.Connect=%d ms | ReasignarConexion=%d ms',
           [msCrearDM, msFConn, msReasignar]),
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.AplicarPermisosPantalla;
var
  sCall: string;
  function Puede(const ASufijo: string): Boolean;
  begin
    Result := (oPermisos = nil) or
              oPermisos.TienePermiso(sCall + '.' + ASufijo, True);
  end;
begin
  // CALL de la pantalla (Clientes, Articulos...). Los Mtos sin registro
  // en fza_winforms (p.ej. cajas de busqueda) no tienen CALL: todo activo.
  sCall := '';
  if (Self.Owner is TfrmMtoPrincipal) then
    sCall := (Self.Owner as TfrmMtoPrincipal).oFzaWinf.CallDeUnit(
               Self.UnitName + '.' + Self.ClassName);
  if sCall <> '' then
  begin
    // Consultar/buscar: solo se quita el buscador global. NO se bloquea la
    // apertura ni la carga, asi se puede llegar a una ficha navegando
    // desde otro Mto (Ctrl+A, ir a factura...).
    if not Puede('consultar') then
    begin
      edtBusqGlobal.Visible   := False;
      lblTextoaBuscar.Visible := False;
      rbBBDD.Visible          := False;
      rbGrid.Visible          := False;
    end;
    // Alta. Enabled:=False en la accion neutraliza tambien su atajo.
    if not Puede('insertar') then
    begin
      actInsertarRegistro.Enabled        := False;
      nvNavegador.Buttons.Insert.Visible := False;
      nvNavegador.Buttons.Append.Visible := False;
    end;
    // Modificacion.
    if not Puede('modificar') then
    begin
      actEditarRegistro.Enabled        := False;
      actGrabarRegistro.Enabled        := False;
      nvNavegador.Buttons.Edit.Visible := False;
      nvNavegador.Buttons.Post.Visible := False;
    end;
    // Borrado.
    if not Puede('borrar') then
    begin
      actEliminarRegistro.Enabled        := False;
      nvNavegador.Buttons.Delete.Visible := False;
    end;
    // Exportar a Excel.
    if not Puede('excel') then
      sbExportExcel.Visible := False;
  end;
end;

function TfrmMtoGen.PuedeImprimir: Boolean;
var
  sCall: string;
begin
  sCall := '';
  if (Self.Owner is TfrmMtoPrincipal) then
    sCall := (Self.Owner as TfrmMtoPrincipal).oFzaWinf.CallDeUnit(
               Self.UnitName + '.' + Self.ClassName);
  if (sCall = '') or (oPermisos = nil) then
    Result := True
  else
    Result := oPermisos.TienePermiso(sCall + '.imprimir', True);
end;

procedure TfrmMtoGen.BloquearTabPorOcupado(Bloquear: Boolean);
var
  lblTexto: TLabel;
  bar: TProgressBar;
begin
  if Bloquear then
  begin
    Inc(FTareasEnCurso);
    if FOverlayOcupado = nil then
    begin
      FOverlayOcupado := TPanel.Create(Self);
      FOverlayOcupado.Parent := Self;
      // SetBounds + Anchors en vez de alClient: alClient compite con
      // otros controles alineados del Mto (pcPantalla, pButtonRightBar...)
      // y a veces el overlay quedaba con altura cero (no se veia nada).
      // Cubrimos manualmente todo el form y nos anclamos a los 4 bordes
      // para seguir el resize.
      FOverlayOcupado.SetBounds(0, 0, Self.ClientWidth, Self.ClientHeight);
      FOverlayOcupado.Anchors := [akLeft, akTop, akRight, akBottom];
      FOverlayOcupado.BevelOuter := bvNone;
      FOverlayOcupado.Color := $00F5E6CC;   // azul-crema claro, contrasta
      FOverlayOcupado.ParentBackground := False;
      FOverlayOcupado.Caption := '';

      // Label y barra los posicionamos con SetBounds (no alClient) para
      // que coexistan sin taparse — alClient en el label se comeria el
      // espacio de la barra.
      lblTexto := TLabel.Create(FOverlayOcupado);
      lblTexto.Parent := FOverlayOcupado;
      lblTexto.AutoSize := False;
      lblTexto.SetBounds(0,
                         (FOverlayOcupado.ClientHeight div 2) - 40,
                         FOverlayOcupado.ClientWidth,
                         30);
      lblTexto.Anchors := [akLeft, akTop, akRight];
      lblTexto.Alignment := taCenter;
      lblTexto.Layout := tlCenter;
      lblTexto.Caption := 'Cargando datos, espera por favor...';
      lblTexto.Font.Style := [fsBold];
      lblTexto.Font.Size := 11;
      lblTexto.Font.Color := clNavy;
      lblTexto.Transparent := True;

      // Barra "marquee": animacion continua sin necesitar %. La pinta
      // el message pump del main thread, asi que solo se ve cuando hay
      // pump corriendo (= camino async). Para el camino sincrono el
      // cursor global Screen.Cursor = crHourGlass cubre el feedback.
      bar := TProgressBar.Create(FOverlayOcupado);
      bar.Parent := FOverlayOcupado;
      bar.SetBounds((FOverlayOcupado.ClientWidth div 2) - 150,
                    (FOverlayOcupado.ClientHeight div 2) + 5,
                    300, 18);
      bar.Anchors := [];
      bar.Style := pbstMarquee;
      bar.MarqueeInterval := 30;
    end;
    // Asegurar que cubre el form aunque haya cambiado de tamaño desde
    // la ultima vez.
    FOverlayOcupado.SetBounds(0, 0, Self.ClientWidth, Self.ClientHeight);
    FOverlayOcupado.BringToFront;
    FOverlayOcupado.Visible := True;
    Self.Cursor := crHourGlass;
  end
  else
  begin
    if FTareasEnCurso > 0 then
      Dec(FTareasEnCurso);
    if (FTareasEnCurso = 0) and Assigned(FOverlayOcupado) then
    begin
      FOverlayOcupado.Visible := False;
      Self.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoGen.EjecutarEnBackground(AccionBG: TProc;
                                          AlTerminar: TProc<string>);
var
  LTask: ITask;
begin
  if not Assigned(AccionBG) then
    Exit;
  // Si la app se esta cerrando no arrancamos trabajo nuevo: la tarea quedaria
  // huerfana usando una conexion que el cierre esta a punto de liberar.
  if inLibGlobalVar.oCerrandoApp then
    Exit;
  if FTareasActivas = nil then
    FTareasActivas := TList<ITask>.Create;
  BloquearTabPorOcupado(True);
  LTask := TTask.Run(
    procedure
    var
      LErrMsg: string;
    begin
      LErrMsg := '';
      try
        AccionBG();
      except
        on E: Exception do
        begin
          // Logueamos el error real (con tipo) y propagamos solo el
          // mensaje al callback. Si necesitaramos el tipo de excepcion
          // tendriamos que envolverlo en una clase wrapper; para el
          // piloto basta con el mensaje.
          inLibLog.Log.LogError('[EjecutarEnBackground] ' +
            E.ClassName + ': ' + E.Message);
          LErrMsg := E.Message;
          if LErrMsg = '' then
            LErrMsg := E.ClassName;
        end;
      end;
      TThread.Queue(nil,
        procedure
        begin
          try
            // Si la app se esta cerrando, este callback puede llegar a
            // ejecutarse (via CheckSynchronize) cuando el form ya esta
            // liberado. Salimos sin tocar nada: leer oCerrandoApp es seguro
            // porque es una global, no un campo del form muerto.
            if inLibGlobalVar.oCerrandoApp then
              Exit;
            // Quitar esta tarea de la lista ANTES del callback (si el
            // callback lanza otra task, no queremos contar esta vez).
            // Si el form se esta destruyendo, FTareasActivas puede ser nil.
            if Assigned(FTareasActivas) then
              FTareasActivas.Remove(LTask);
            // Tambien comprobamos csDestroying: si el form se cerro
            // mientras la tarea corria, no hay UI que actualizar y los
            // componentes (FOverlayOcupado, dsTablaG...) ya estan
            // liberados.
            if not (csDestroying in ComponentState) then
            begin
              // OJO: el overlay se quita DESPUES del callback. Asi el
              // usuario no puede interactuar mientras AlTerminar
              // ejecuta trabajo pesado (p. ej. AbrirDetalles abre 11
              // queries detalle). Si lo quitamos antes, eventos del
              // form (cambio de cursor, click en pestaña, ...) se
              // disparan con queries aun cerradas -> "Cannot perform
              // operation on closed dataset".
              try
                if Assigned(AlTerminar) then
                  AlTerminar(LErrMsg);
              finally
                BloquearTabPorOcupado(False);
              end;
            end;
          except
            on E: Exception do
              inLibLog.Log.LogError(
                '[EjecutarEnBackground.AlTerminar] ' +
                E.ClassName + ': ' + E.Message);
          end;
        end);
    end);
  FTareasActivas.Add(LTask);
end;

procedure TfrmMtoGen.AbrirTablaPrincipalAsync;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  yaActiva: Boolean;
begin
  if (tdmDataModule = nil) or not (tdmDataModule is TdmBase) then
    Exit;
  dmDat := TdmBase(tdmDataModule);
  unqry := dmDat.unqryTablaG;
  if unqry = nil then
    Exit;
  // Antes de entrar: restricción por empresa/almacén/caja del usuario.
  // Si cierra una query activa del DFM, el flujo normal de abajo la
  // reabre ya filtrada (yaActiva quedará False).
  AplicarRestriccionUsuario(unqry);
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
      if csDestroying in ComponentState then
        Exit;
      if ErrMsg = '' then
        inLibLog.Log.LogPerf('Carga/async', Self.Name + ' | OK',
          sw.ElapsedMilliseconds)
      else
      begin
        inLibLog.Log.LogPerf('Carga/async',
          Self.Name + ' | error=' + ErrMsg,
          sw.ElapsedMilliseconds);
        // No mostramos ShowMessage aqui — molesta si pasa al abrir
        // varios tabs en cadena. El error queda en el log.
        Exit;
      end;
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
            inLibLog.Log.LogError(
              '[AbrirDetalles] ' + Self.Name + ': ' + E.Message);
        end;
      // Diagnostico defensivo: cazar columnas ES* tipadas como numericas
      // antes de que el Refresh del navegador rompa con EConvertError
      // 'N' is not a valid floating point value. Solo loguea, no aborta.
      DiagnosticarCamposBooleanos(unqry, Self.Name);
      // (b) Enriquecer query con guias de grid (LEFT JOIN runtime)
      AplicarGuiasGrid(unqry);
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
            inLibLog.Log.LogError(
              '[ReactivarControlesTrasAbrir] ' + Self.Name + ': ' + E.Message);
        end;
      // (e) Restaurar posicion del cursor guardada en el perfil.
      // AplicarEtiquetas lo intenta en FormCreate pero el dataset
      // aun no tiene datos; aqui ya esta abierto y vinculado.
      if oPerfilDic <> nil then
        RestaurarFocoGrid(cxGrdDBTabPrin, oPerfilDic);
      // (f) Hook de borrar (Delete -> Desactivar). Idempotente.
      InstalarGuardianBorrado;
      // (g) Hook post-precarga (main thread): los Mtos que necesiten
      // intervenir tras la carga normal (p.ej. Articulos: dialogo de
      // filtrado si se supero el umbral de filas) lo hacen aqui.
      TrasPrecargaAsync;
    end);
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

procedure TfrmMtoGen.AplicarRestriccionUsuario(unqry: TUniQuery);
var
  sFiltro: string;
begin
  sFiltro := SqlRestriccionUsuario;
  // Idempotente: si el fragmento ya está en la SQL (reapertura del tab,
  // o el propio Mto lo integró al recomponer su SQL) no se toca nada.
  if (sFiltro <> '') and (Pos(sFiltro, unqry.SQL.Text) = 0) then
  begin
    // Si venía activa del DFM streaming hay que reabrirla ya filtrada
    if unqry.Active then
      unqry.Close;
    unqry.SQL.Text := InyectarFiltroSql(unqry.SQL.Text, sFiltro);
    inLibLog.Log.LogInfo(Self.Name +
      ': precarga restringida por usuario (appRestringirEmpAlmCaja)');
  end;
end;

procedure TfrmMtoGen.AbrirTablaPrincipalSincrono;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  CursorPrev: TCursor;
begin
  if (tdmDataModule = nil) or not (tdmDataModule is TdmBase) then
    Exit;
  dmDat := TdmBase(tdmDataModule);
  unqry := dmDat.unqryTablaG;
  if unqry = nil then
    Exit;
  // Antes de entrar: restricción por empresa/almacén/caja del usuario
  AplicarRestriccionUsuario(unqry);
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
      DiagnosticarCamposBooleanos(unqry, Self.Name);
      // Enriquecer con guias de grid (LEFT JOIN runtime)
      AplicarGuiasGrid(unqry);
      // Restaurar posicion del cursor guardada en el perfil
      if oPerfilDic <> nil then
        RestaurarFocoGrid(cxGrdDBTabPrin, oPerfilDic);
      // Hook de borrar (Delete -> Desactivar). Idempotente.
      InstalarGuardianBorrado;
      inLibLog.Log.LogPerf('Carga/sync', Self.Name + ' | OK',
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf('Carga/sync',
          Self.Name + ' | error=' + E.Message,
          sw.ElapsedMilliseconds);
        raise;
      end;
    end;
  finally
    Screen.Cursor := CursorPrev;
  end;
end;

function TfrmMtoGen.CrearConexionPropia: TUniConnection;
begin
  Result := TUniConnection.Create(Self);
  try
    Result.LoginPrompt := False;
    Result.ProviderName := oConn.ProviderName;
    Result.Server       := oConn.Server;
    Result.Port         := oConn.Port;
    Result.Database     := oConn.Database;
    Result.Username     := oConn.Username;
    Result.Password     := oConn.Password;
    // Mismos ajustes que la conexion global (UniDataConn.connBeforeConnect).
    // Con los mismos params, las conexiones fisicas salen del mismo pool.
    Result.Pooling := True;
    Result.PoolingOptions.ConnectionLifetime := 0;
    Result.PoolingOptions.Validate := True;
    Result.SpecificOptions.Values['MySQL.Interactive'] := 'True';
    Result.SpecificOptions.Values['ConnectionTimeout'] := '30';
    // El charset va como SpecificOption del clon, no solo en el SET NAMES
    // manual del AfterConnect: asi UniDAC reaplica "SET NAMES utf8mb4" en
    // cada reconexion fisica del LocalFailover. Sin esto, al reavivar una
    // conexion muerta el texto volvia ilegible (mojibake) hasta reiniciar.
    Result.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
    Result.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
    Result.SpecificOptions.Values['MySQL.Protocol'] := 'mpDefault';
    Result.Options.LocalFailover    := True;
    Result.Options.DisconnectedMode := True;
    // Reusamos el handler de errores y el AfterConnect (timeout extendido)
    // de la conexion global para mantener comportamiento consistente.
    Result.OnError       := oConn.OnError;
    Result.AfterConnect  := oConn.AfterConnect;
    Result.Connect;
  except
    FreeAndNil(Result);
    raise;
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
  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  // ANTES de liberar nada relacionado con BBDD (data module, FConn),
  // esperar a que terminen las tareas en background. Si quedaran tareas
  // vivas accederian a TUniQuery / TUniConnection ya liberadas → AV.
  bTareasVivas := False;
  if Assigned(FTareasActivas) then
  begin
    try
      if FTareasActivas.Count > 0 then
      begin
        if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
          TdmBase(tdmDataModule).CancelarEjecucionActiva;
        if inLibGlobalVar.oCerrandoApp then
          // Apagado de la app: BreakExec ya pedido y espera ACOTADA. Si
          // una consulta sigue atascada contra MySQL preferimos fugar
          // sus objetos (abajo) a dejar la app congelada cerrando o el
          // proceso en memoria (cuelgue visto en produccion 14/07/26:
          // vi_paises bloqueada 27,5 s al cerrar la pestaña).
          bTareasVivas :=
            not TTask.WaitForAll(FTareasActivas.ToArray, 15000)
        else
          // Cierre de una sola pestaña: si MySQL no responde en 5s
          // asumimos tarea atascada antes que dejar la app colgada
          // cerrando un tab.
          bTareasVivas :=
            not TTask.WaitForAll(FTareasActivas.ToArray, 5000);
      end;
    except
      // WaitForAll puede lanzar si alguna tarea fallo — lo ignoramos
      // porque solo queremos drenar, no propagar. Una tarea que lanzo
      // ya termino: no cuenta como viva.
    end;
    FreeAndNil(FTareasActivas);
  end;
  if (oPerfilDic <> nil) then
    FreeAndNil(oPerfilDic);
  if bTareasVivas then
  begin
    // Tarea de fondo aun bloqueada (p.ej. consulta MySQL atascada): la
    // tarea sigue usando el data module y FConn, y liberarlos provoca
    // AVs y cuelgues del cierre. Se sueltan del Owner y NO se liberan:
    // fuga controlada que el SO recupera al terminar el proceso.
    inliblog.Log.LogWarning('Tareas de fondo aun vivas al destruir "' +
                            Self.Name + '": se dejan sin liberar su ' +
                            'data module y su conexion.');
    if (tdmDataModule <> nil) and (tdmDataModule.Owner = Self) then
      RemoveComponent(tdmDataModule);
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
    end;
    FreeAndNil(FConn);
  end;
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                   Self.Caption + ' Cerrada');
  frmMtoGen := nil;
  inherited;
end;

procedure TfrmMtoGen.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.Dataset <> nil) then
  begin
    if (dsTablaG.DataSet.State = dsInsert) then
    begin
      lblEditMode.Caption := 'Insertando';
    end;
    if (dsTablaG.DataSet.State = dsEdit) then
    begin
      lblEditMode.Caption := 'Editando';
    end;
    if (dsTablaG.DataSet.State = dsBrowse) then
    begin
      lblEditMode.Caption := 'Navegando';
    end;
      if (dsTablaG.DataSet.State = dsInactive) then
    begin
      lblEditMode.Caption := 'Inactivo';
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
  if Assigned(frmFotoArticulo) then
    frmFotoArticulo.VincularDataSources([], nil);
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
  Self.HandleNeeded; //da problemas
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                     Self.Caption + ' Abierta');
  tsFichCab := nil;
  tsFichBut := nil;
  FCamposGuia := nil;
  FSqlOriginalTablaG := '';
  FSqlBaseBusquedaExterna := '';
  Self.Position  := poScreenCenter;
  // Popup de columnas: boton derecho en el grid principal
  FPopMenuColumnas := TPopupMenu.Create(Self);
  FPopMenuColumnas.OnPopup := PopMenuColumnasPopup;
  cxgrdPrincipal.PopupMenu := FPopMenuColumnas;
  swTramo := TStopwatch.StartNew;
  ProcesarPerfiles;
  msProcesarPerfiles := swTramo.ElapsedMilliseconds;
  sModoBusq := GetPerfilValueDef(oPerfilDic, 'oBusqGlobal', 'Database');
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
  inLibLog.Log.LogPerf(Self.Name + '.FormCreate',
    'ProcesarPerfiles=' + IntToStr(msProcesarPerfiles) + ' ms',
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.BorrarGuiasGrid;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'DELETE FROM fza_informes_guias ' +
      ' WHERE INFORME_INFGUI = :INF';
    qry.ParamByName('INF').AsString := 'GRID:' + Self.Name;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  // Invalidar cache para que la proxima apertura no use guias borradas
  if oInfGuiasCache <> nil then
    oInfGuiasCache.Invalidar;
end;

procedure TfrmMtoGen.AplicarGuiasGrid(AQuery: TUniQuery);
var
  guiaResult: TGridGuiaResult;
  i: Integer;
  col: TcxGridDBColumn;
  sField: string;
  bYaExiste: Boolean;
  j: Integer;
begin
  if AQuery = nil then
    Exit;
  guiaResult := EnriquecerQueryConGuias(Self.Name, AQuery);
  try
    if not guiaResult.Exito then
    begin
      FreeAndNil(guiaResult.CamposNuevos);
      Exit;
    end;
    if guiaResult.CamposNuevos.Count = 0 then
    begin
      FreeAndNil(guiaResult.CamposNuevos);
      Exit;
    end;
    FSqlOriginalTablaG := guiaResult.SqlOriginal;
    // Reabrir query con SQL enriquecido
    try
      AQuery.Open;
    except
      on E: Exception do
      begin
        inLibLog.Log.LogError(
          'AplicarGuiasGrid: error al reabrir query enriquecida: ' +
          E.Message);
        // Restaurar el SQL original y reabrir. Si no, el dataset queda
        // cerrado con el SQL roto y cualquier Refresh posterior del
        // navegador dispara el mismo error al usuario.
        try
          AQuery.Close;
          AQuery.SQL.Text := guiaResult.SqlOriginal;
          AQuery.Open;
        except
          on E2: Exception do
            inLibLog.Log.LogError(
              'AplicarGuiasGrid: tampoco abre el SQL original tras ' +
              'restaurar: ' + E2.Message);
        end;
        Exit;
      end;
    end;
    // Crear columnas dinamicas en el grid para los campos nuevos
    cxGrdDBTabPrin.BeginUpdate;
    try
      for i := 0 to guiaResult.CamposNuevos.Count - 1 do
      begin
        sField := guiaResult.CamposNuevos[i];
        // No duplicar si ya existe
        bYaExiste := False;
        for j := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
          if SameText(
            (cxGrdDBTabPrin.Columns[j] as TcxGridDBColumn)
              .DataBinding.FieldName, sField) then
          begin
            bYaExiste := True;
            Break;
          end;
        if bYaExiste then
          Continue;
        col := cxGrdDBTabPrin.CreateColumn as TcxGridDBColumn;
        col.DataBinding.FieldName := sField;
        col.Caption := sField;
        // Visible solo si está en la lista guardada de columnas visibles
        col.Visible :=
          guiaResult.ColumnasVisibles.IndexOf(sField) >= 0;
      end;
    finally
      cxGrdDBTabPrin.EndUpdate;
    end;
    // Guardar listas para re-aplicar visibilidad tras AplicarEtiquetas
    FreeAndNil(FCamposGuia);
    FCamposGuia := TStringList.Create;
    FCamposGuia.Assign(guiaResult.CamposNuevos);
    FreeAndNil(FCamposGuiaTabla);
    FCamposGuiaTabla := TStringList.Create;
    FCamposGuiaTabla.Assign(guiaResult.CamposTabla);
    FreeAndNil(FColumnasVisiblesGuia);
    FColumnasVisiblesGuia := TStringList.Create;
    FColumnasVisiblesGuia.Assign(guiaResult.ColumnasVisibles);
  finally
    FreeAndNil(guiaResult.CamposNuevos);
    FreeAndNil(guiaResult.CamposTabla);
    FreeAndNil(guiaResult.ColumnasVisibles);
  end;
end;

procedure TfrmMtoGen.DiagnosticarCamposBooleanos(AQuery: TUniQuery;
                                                 const AContexto: string);
var
  i: Integer;
  f: TField;
  sTipo: string;
begin
  if (AQuery = nil) or (not AQuery.Active) then
    Exit;
  for i := 0 to AQuery.FieldCount - 1 do
  begin
    f := AQuery.Fields[i];
    if not StartsText('ES', f.FieldName) then
      Continue;
    // Tipos que disparan ConvertToFloat / ConvertToInteger en MyDAC al
    // intentar leer una columna varchar(1) con 'S' / 'N'. Cualificamos
    // con Data.DB porque System.TypInfo.TFloatType tambien declara
    // ftSingle y ftExtended y choca al estar mas abajo en el uses.
    if f.DataType in [Data.DB.ftFloat, Data.DB.ftCurrency, Data.DB.ftBCD,
                      Data.DB.ftFMTBcd, Data.DB.ftSingle, Data.DB.ftExtended,
                      Data.DB.ftInteger, Data.DB.ftSmallint,
                      Data.DB.ftLargeint, Data.DB.ftWord, Data.DB.ftByte] then
    begin
      sTipo := GetEnumName(TypeInfo(TFieldType), Ord(f.DataType));
      inLibLog.Log.LogError(Format(
        '[DiagnosticarCamposBooleanos] %s: campo "%s" tipado como %s ' +
        'pero por convencion deberia ser varchar(1) S/N. Causa probable: ' +
        'metadata de vista desactualizada tras ALTER TABLE. ' +
        'Solucion: DROP VIEW + CREATE VIEW de la vista usada por el grid.',
        [AContexto, f.FieldName, sTipo]));
    end;
  end;
end;

// ============================================================================
// Popup de selector de columnas (boton derecho en grid)
// ============================================================================

procedure TfrmMtoGen.PopMenuColumnasPopup(Sender: TObject);
var
  i: Integer;
  col: TcxGridDBColumn;
  mi, miSep, miGuia, miSub: TMenuItem;
  sCaption, sField, sTabla: string;
  dicSubMenus: TDictionary<string, TMenuItem>;
begin
  FPopMenuColumnas.Items.Clear;
  dicSubMenus := TDictionary<string, TMenuItem>.Create;
  try
    for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
    begin
      col := cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn;
      sField := col.DataBinding.FieldName;
      if sField = '' then
        Continue;
      mi := TMenuItem.Create(FPopMenuColumnas);
      sCaption := col.Caption;
      if sCaption = '' then
        sCaption := sField;
      mi.Caption := sCaption;
      mi.Checked := col.Visible;
      mi.AutoCheck := False;
      mi.Tag := i;
      mi.OnClick := PopMenuColumnaClick;
      // Determinar si es columna guía y a qué tabla pertenece
      sTabla := '';
      if (FCamposGuiaTabla <> nil) then
        sTabla := FCamposGuiaTabla.Values[sField];
      if sTabla <> '' then
      begin
        if not dicSubMenus.TryGetValue(sTabla, miSub) then
        begin
          miSub := TMenuItem.Create(FPopMenuColumnas);
          miSub.Caption := 'Guía: ' + sTabla;
          dicSubMenus.Add(sTabla, miSub);
        end;
        miSub.Add(mi);
      end
      else
        FPopMenuColumnas.Items.Add(mi);
    end;
    // Separador + submenús por tabla + acciones
    miSep := TMenuItem.Create(FPopMenuColumnas);
    miSep.Caption := '-';
    FPopMenuColumnas.Items.Add(miSep);
    for miSub in dicSubMenus.Values do
      FPopMenuColumnas.Items.Add(miSub);
  finally
    FreeAndNil(dicSubMenus);
  end;
  miGuia := TMenuItem.Create(FPopMenuColumnas);
  miGuia.Caption := 'Renombrar columna...';
  miGuia.OnClick := PopMenuRenombrarClick;
  FPopMenuColumnas.Items.Add(miGuia);
  miGuia := TMenuItem.Create(FPopMenuColumnas);
  miGuia.Caption := 'Nueva guía...';
  miGuia.OnClick := PopMenuNuevaGuiaClick;
  FPopMenuColumnas.Items.Add(miGuia);
end;

procedure TfrmMtoGen.PopMenuColumnaClick(Sender: TObject);
var
  mi: TMenuItem;
  col: TcxGridDBColumn;
begin
  mi := TMenuItem(Sender);
  if (mi.Tag >= 0) and (mi.Tag < cxGrdDBTabPrin.ColumnCount) then
  begin
    col := cxGrdDBTabPrin.Columns[mi.Tag] as TcxGridDBColumn;
    col.Visible := not col.Visible;
  end;
end;

procedure TfrmMtoGen.PopMenuRenombrarClick(Sender: TObject);
var
  frm: TForm;
  pnlBot: TPanel;
  btnOK, btnCancel: TButton;
  i, iTop: Integer;
  col: TcxGridDBColumn;
  lblAntiguo: TLabel;
  edtNuevo: TEdit;
  edits: TStringList;
begin
  edits := TStringList.Create;
  frm := TForm.Create(Self);
  try
    frm.Caption := 'Renombrar columnas';
    frm.Width := 620;
    frm.Position := poMainFormCenter;
    frm.BorderStyle := bsDialog;
    // Crear pares (antiguo -> nuevo) para cada columna visible
    iTop := 12;
    for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
    begin
      col := cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn;
      if (col.DataBinding.FieldName = '') or (not col.Visible) then
        Continue;
      lblAntiguo := TLabel.Create(frm);
      lblAntiguo.Parent := frm;
      lblAntiguo.Left := 12;
      lblAntiguo.Top := iTop + 3;
      lblAntiguo.Width := 250;
      lblAntiguo.Caption := col.DataBinding.FieldName;
      lblAntiguo.Font.Color := clGray;
      edtNuevo := TEdit.Create(frm);
      edtNuevo.Parent := frm;
      edtNuevo.Left := 270;
      edtNuevo.Top := iTop;
      edtNuevo.Width := 320;
      edtNuevo.Text := col.Caption;
      edtNuevo.Tag := i;
      edits.AddObject(col.DataBinding.FieldName, edtNuevo);
      iTop := iTop + 30;
    end;
    frm.ClientHeight := iTop + 55;
    pnlBot := TPanel.Create(frm);
    pnlBot.Parent := frm;
    pnlBot.Align := alBottom;
    pnlBot.Height := 45;
    pnlBot.BevelOuter := bvNone;
    btnOK := TButton.Create(pnlBot);
    btnOK.Parent := pnlBot;
    btnOK.Caption := 'Aplicar';
    btnOK.ModalResult := mrOk;
    btnOK.Left := 370;
    btnOK.Top := 8;
    btnOK.Width := 110;
    btnOK.Height := 30;
    btnCancel := TButton.Create(pnlBot);
    btnCancel.Parent := pnlBot;
    btnCancel.Caption := 'Cancelar';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := 490;
    btnCancel.Top := 8;
    btnCancel.Width := 110;
    btnCancel.Height := 30;
    if frm.ShowModal = mrOk then
    begin
      for i := 0 to edits.Count - 1 do
      begin
        edtNuevo := TEdit(edits.Objects[i]);
        col := cxGrdDBTabPrin.Columns[edtNuevo.Tag] as TcxGridDBColumn;
        if edtNuevo.Text <> col.Caption then
          col.Caption := edtNuevo.Text;
      end;
    end;
  finally
    FreeAndNil(frm);
    FreeAndNil(edits);
  end;
end;

procedure TfrmMtoGen.PopMenuNuevaGuiaClick(Sender: TObject);
var
  frm: TfrmModalGridGuias;
  oDS: TDataSet;
  guiaResult: TGridGuiaResult;
  camposElegidos: TStringList;
  i: Integer;
  col: TcxGridDBColumn;
  unqry: TUniQuery;
begin
  // Abrir mantenimiento de guias del grid
  frm := TfrmModalGridGuias.Create(Application);
  try
    frm.sFormulario := Self.Name;
    oDS := nil;
    if Assigned(dsTablaG) and Assigned(dsTablaG.DataSet) then
      oDS := dsTablaG.DataSet;
    frm.FDataSet := oDS;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
  // Recargar cache de guias
  if oInfGuiasCache <> nil then
  begin
    oInfGuiasCache.Invalidar;
    oInfGuiasCache.Precargar;
  end;
  // Obtener TUniQuery: del data module o del DataSource (búsquedas)
  unqry := nil;
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
    unqry := TdmBase(tdmDataModule).unqryTablaG
  else if Assigned(dsTablaG) and Assigned(dsTablaG.DataSet) and
          (dsTablaG.DataSet is TUniQuery) then
    unqry := TUniQuery(dsTablaG.DataSet);
  if (unqry <> nil) and (unqry.Active) then
    begin
      // Limpiar columnas de guías anteriores del grid
      if (FCamposGuia <> nil) and (FCamposGuia.Count > 0) then
      begin
        cxGrdDBTabPrin.BeginUpdate;
        try
          for i := cxGrdDBTabPrin.ColumnCount - 1 downto 0 do
          begin
            if FCamposGuia.IndexOf(
              (cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn)
                .DataBinding.FieldName) >= 0 then
              cxGrdDBTabPrin.Columns[i].Free;
          end;
        finally
          cxGrdDBTabPrin.EndUpdate;
        end;
        FreeAndNil(FCamposGuia);
      end;
      // Restaurar SQL original si ya estaba enriquecido
      if FSqlOriginalTablaG <> '' then
      begin
        unqry.Close;
        unqry.SQL.Text := FSqlOriginalTablaG;
      end;
      guiaResult := EnriquecerQueryConGuias(Self.Name, unqry);
      try
        if guiaResult.Exito and (guiaResult.CamposNuevos.Count > 0) then
        begin
          FSqlOriginalTablaG := guiaResult.SqlOriginal;
          // Dejar elegir columnas al usuario
          camposElegidos := ElegirColumnasNuevas(Self,
                                                 guiaResult.CamposNuevos);
          try
            // Reabrir query con SQL enriquecido
            unqry.Open;
            // Crear o actualizar columnas en el grid
            cxGrdDBTabPrin.BeginUpdate;
            try
              for i := 0 to guiaResult.CamposNuevos.Count - 1 do
              begin
                var sField := guiaResult.CamposNuevos[i];
                var bVisible :=
                  camposElegidos.IndexOf(sField) >= 0;
                var bYaExiste := False;
                var j: Integer;
                for j := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
                begin
                  if SameText(
                    (cxGrdDBTabPrin.Columns[j] as TcxGridDBColumn)
                      .DataBinding.FieldName, sField) then
                  begin
                    cxGrdDBTabPrin.Columns[j].Visible := bVisible;
                    bYaExiste := True;
                    Break;
                  end;
                end;
                if not bYaExiste then
                begin
                  col := cxGrdDBTabPrin.CreateColumn as TcxGridDBColumn;
                  col.DataBinding.FieldName := sField;
                  col.Caption := sField;
                  col.Visible := bVisible;
                end;
              end;
            finally
              cxGrdDBTabPrin.EndUpdate;
            end;
            // Guardar nombres de campos guia para limpieza
            FreeAndNil(FCamposGuia);
            FCamposGuia := TStringList.Create;
            FCamposGuia.Assign(guiaResult.CamposNuevos);
            // Persistir columnas visibles en fza_informes_guias
            var qryVis := TUniQuery.Create(nil);
            try
              qryVis.Connection := oConn;
              qryVis.SQL.Text :=
                'UPDATE fza_informes_guias ' +
                '   SET COLUMNAS_VISIBLES_INFGUI = :VIS ' +
                ' WHERE INFORME_INFGUI = :INF';
              camposElegidos.StrictDelimiter := True;
              camposElegidos.Delimiter := ';';
              qryVis.ParamByName('VIS').AsString :=
                camposElegidos.DelimitedText;
              qryVis.ParamByName('INF').AsString :=
                'GRID:' + Self.Name;
              qryVis.Execute;
            finally
              FreeAndNil(qryVis);
            end;
          finally
            FreeAndNil(camposElegidos);
          end;
        end
        else
        begin
          // No hay guias o fallo: reabrir con SQL original si lo cerramos
          if not unqry.Active then
            unqry.Open;
        end;
      finally
        FreeAndNil(guiaResult.CamposNuevos);
        FreeAndNil(guiaResult.CamposTabla);
        FreeAndNil(guiaResult.ColumnasVisibles);
      end;
    end;
end;

procedure TfrmMtoGen.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  // ESC -> cancelar grids en edicion
  if (Key = VK_ESCAPE) then
  begin
    CancelarGrids(Owner);
    Key := 0;
  end;
  // RETURN sin control activo -> simular Tab
  if ((Key = VK_RETURN) and (ActiveControl = nil)) then
  begin
    Key := 0;
    SimulateTabKey;
    Exit;
  end;
  // Ctrl+Inicio / Ctrl+Fin -> primer / ultimo registro del grid.
  // En editores de texto dejamos el comportamiento nativo del control.
  if (Key in [VK_HOME, VK_END]) and (ssCtrl in Shift) and
     not (ssAlt in Shift) and PuedeCambiarRegistroPorTecla then
  begin
    // Usar DataController para respetar la ordenacion del grid
    if Key = VK_HOME then
      cxGrdDBTabPrin.DataController.FocusedRowIndex := 0
    else
      cxGrdDBTabPrin.DataController.FocusedRowIndex :=
        cxGrdDBTabPrin.DataController.RowCount - 1;
    Key := 0;
    Exit;
  end;
  // Alt+F12 -> Guardar layout (equivalente al botón sbGrabarGrid)
  if (Key = VK_F12) and (ssAlt in Shift) and not (ssCtrl in Shift) then
  begin
    sbGrabarGridClick(nil);
    Key := 0;
    Exit;
  end;
  // Ctrl+F12 -> Resetear layout (equivalente al botón sbResetGrid)
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    sbResetGridClick(nil);
    Key := 0;
    Exit;
  end;
  // Ctrl+F10 -> BestFit anchos de columna
  if (Key = VK_F10) and (ssCtrl in Shift) and not (ssAlt in Shift) then
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

procedure TfrmMtoGen.actNavBrowseUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (dsTablaG.State = dsBrowse) and
    PermitirNavegacionTeclas;
end;

procedure TfrmMtoGen.actEliminarRegistroUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty and
    (dsTablaG.State = dsBrowse);
end;

procedure TfrmMtoGen.actEliminarRegistroExecute(Sender: TObject);
begin
  // El guardian BeforeDelete (GuardianBeforeDelete) hace la pregunta y, segun
  // la respuesta, aborta, desactiva o continua con el delete original. No
  // duplicamos aqui la logica para que el flujo sea identico cuando el
  // usuario pulsa el boton de borrar del navegador (que llama directamente
  // a DataSet.Delete sin pasar por esta accion).
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
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
    sDescHijos := 'registros asociados';
  // Caso 1: tabla no desactivable y sin hijos -> confirmacion simple Si/No.
  if (not bDesactivable) and (iHijos = 0) then
  begin
    if Application.MessageBox(
        '¿Estás seguro de que deseas eliminar este registro?',
        'Confirmar eliminación',
        MB_YESNO + MB_ICONWARNING) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
    Exit;
  end;
  // Caso 2: tabla no desactivable pero tiene hijos -> avisar y Si/No.
  if not bDesactivable then
  begin
    sMsg := Format('Hay %d %s vinculados a este registro.',
                   [iHijos, sDescHijos]) + sLineBreak + sLineBreak +
            'No se recomienda eliminarlo: se rompera la relacion con' +
            sLineBreak + 'los registros hijos.' + sLineBreak + sLineBreak +
            '¿Deseas eliminarlo de todas formas?';
    if Application.MessageBox(PChar(sMsg),
        'Confirmar eliminación',
        MB_YESNO + MB_ICONWARNING + MB_DEFBUTTON2) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
    Exit;
  end;
  // Caso 3 y 4: tabla desactivable, con o sin hijos.
  if iHijos > 0 then
    sMsg := Format('Hay %d %s vinculados a este registro.',
                   [iHijos, sDescHijos]) + sLineBreak + sLineBreak +
            'No se recomienda eliminarlo. Te sugerimos DESACTIVARLO' +
            sLineBreak + 'para conservar el historico.'
  else
    sMsg := 'Este registro puede DESACTIVARSE en lugar de eliminarse' +
            sLineBreak + 'para conservar el historico.';
  sMsg := sMsg + sLineBreak + sLineBreak +
          'Sí       = Desactivar (recomendado)' + sLineBreak +
          'No       = Eliminar definitivamente' + sLineBreak +
          'Cancelar = No hacer nada';
  iResp := Application.MessageBox(PChar(sMsg),
             'Confirmar eliminación',
             MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON1);
  case iResp of
    ID_YES:    Result := abDesactivar;
    ID_NO:     Result := abContinuar;
  else
    Result := abCancelar;
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
  dsTablaG.DataSet.Edit;
end;

procedure TfrmMtoGen.actGrabarRegistroUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    ((dsTablaG.State = dsEdit) or (dsTablaG.State = dsInsert));
end;

procedure TfrmMtoGen.actGrabarRegistroExecute(Sender: TObject);
begin
  dsTablaG.DataSet.Post;
end;

procedure TfrmMtoGen.actFotoArticuloExecute(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  // Toggle: si la foto ya está visible, ocultarla
  if Assigned(frmFotoArticulo) and frmFotoArticulo.Visible then
  begin
    frmFotoArticulo.Hide;
    Exit;
  end;
  sArt := '';
  sSku := '';
  ResolverArtSkuActivo(sArt, sSku);
  if sArt <> '' then
  begin
    MostrarFotoFlotante(Self, sArt, sSku);
    if Assigned(frmFotoArticulo) then
      frmFotoArticulo.VincularDataSources(DataSourcesParaFoto,
                                          ResolverArtSkuActivo);
  end;
end;

procedure TfrmMtoGen.actConsultaStockExecute(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  sArt := '';
  sSku := '';
  ResolverArtSkuActivo(sArt, sSku);
  inMtoStockConsulta.MostrarStockConsulta(Self, sArt, sSku);
end;

procedure TfrmMtoGen.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if (dsTablaG <> nil) and (dsTablaG.DataSet <> nil) then
    inLibFotos.LeerArtSkuDeDataSet(dsTablaG.DataSet, ACodArt, ACodSku);
end;

procedure TfrmMtoGen.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  ResolverArtSkuActivo(ACodArt, ACodSku);
end;

function TfrmMtoGen.DataSourcesParaFoto: TArray<TDataSource>;
begin
  // Default: solo el data source principal. Los Mtos que tengan
  // sub-grids con articulo / SKU activo sobreescriben para anadir
  // tambien esos DataSources.
  Result := [dsTablaG];
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
  if (Self.Owner is TfrmMtoPrincipal) then
    TfrmMtoPrincipal(Self.Owner).EngancharFotoAlMto(Self);
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
  inLibUser.GetFormUserProfile(oPerfilDic,
                               Self.Name,
                               inLibGlobalVar.oUser,
                               inLibGlobalVar.oGroup);
  CrearTablaPrincipal;
  AplicarEtiquetas;
  // Re-aplicar visibilidad de columnas guía: CreateAllItems y
  // AplicarEtiquetas/PonerAnchosTitulos pueden haberlas hecho visibles
  if (FCamposGuia <> nil) and (FColumnasVisiblesGuia <> nil) then
  begin
    var k: Integer;
    for k := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
    begin
      var sFld :=
        (cxGrdDBTabPrin.Columns[k] as TcxGridDBColumn)
          .DataBinding.FieldName;
      if FCamposGuia.IndexOf(sFld) >= 0 then
        cxGrdDBTabPrin.Columns[k].Visible :=
          FColumnasVisiblesGuia.IndexOf(sFld) >= 0;
    end;
  end;
  // Permisos por pantalla: ocultan/deshabilitan los controles segun
  // <CALL>.consultar / insertar / modificar / borrar / excel.
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
  if Owner is TfrmMtoPrincipal then
    CancelarGrids(Owner)
  else
    // Fuera de fzam (pruebas standalone, DESARROLLOS EN CURSO) Owner no
    // es el principal y el cast de CancelarGrids lanzaria EInvalidCast:
    // se cancelan los datasets en edicion de los grids de ESTE form.
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TcxGridDBTableView then
        with TcxGridDBTableView(Components[i]).DataController do
        begin
          if (DataSource <> nil) and (DataSet <> nil) and
             (DataSet.State in [dsEdit, dsInsert]) then
            DataSet.Cancel;
        end;
end;

procedure TfrmMtoGen.sbExportExcelClick(Sender: TObject);
begin
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.InitialDir :=  GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
  saveDialog.Filter := 'Archivo Excel|*.xlsx';
  saveDialog.DefaultExt := 'xlsx';
  saveDialog.FilterIndex := 1;
  if ( saveDialog.Execute ) then
    ExportGridToXLSX(saveDialog.FileName, cxGrdPrincipal);
end;

// ===========================================================================
//   Filtros guardados (desplegable junto a "Guardar Excel")
// ===========================================================================
// Guardan y comparten DataController.Filter de la lista principal con
// nombre propio. Independientes del filtro incidental que ya guarda
// "Grabar Grid" (sbGrabarGridClick) junto con el layout. Ver
// UniDataFiltros.pas para el acceso a BBDD (fza_filtros_guardados /
// fza_filtros_guardados_compartidos).

procedure TfrmMtoGen.sbFiltrosClick(Sender: TObject);
var
  pt: TPoint;
begin
  tmrBusqGlobal.Enabled := False;
  if edtBusqGlobal.Text <> '' then
  begin
    BusqAllGrid(cxGrdDBTabPrin,
                edtBusqGlobal.Text);
  end;
  FBusqGlobalMenu := edtBusqGlobal.Text;
  if cxGrdDBTabPrin.DataController.Filter.IsEmpty then
  begin
    FFiltroMenuBase64 := '';
  end
  else
  begin
    FFiltroMenuBase64 := SerializarFiltroActualBase64;
  end;
  CargarMenuFiltros;
  pt := sbFiltros.ClientToScreen(Point(0, sbFiltros.Height));
  pmFiltros.Popup(pt.X, pt.Y);
end;

procedure TfrmMtoGen.CargarMenuFiltros;
var
  oLista: TFiltrosGuardadosList;
  info: TFiltroGuardadoInfo;
  oItem: TMenuItem;
  oSeparador: TMenuItem;
begin
  pmFiltros.Items.Clear;
  if Assigned(odmFiltros) then
  begin
    oLista := odmFiltros.ListarFiltros(Self.Name, cxGrdDBTabPrin.Name);
    try
      if oLista.Count = 0 then
      begin
        oItem := TMenuItem.Create(pmFiltros);
        oItem.Caption := '(Sin filtros guardados)';
        oItem.Enabled := False;
        pmFiltros.Items.Add(oItem);
      end
      else
      begin
        for info in oLista do
        begin
          oItem := TMenuItem.Create(pmFiltros);
          if info.EsPropio then
            oItem.Caption := info.Nombre
          else
            oItem.Caption := info.Nombre + ' (' + info.Propietario + ')';
          oItem.Tag := info.Id;
          oItem.OnClick := AplicarFiltroGuardadoClick;
          pmFiltros.Items.Add(oItem);
        end;
      end;
    finally
      FreeAndNil(oLista);
    end;
  end;
  oSeparador := TMenuItem.Create(pmFiltros);
  oSeparador.Caption := '-';
  pmFiltros.Items.Add(oSeparador);
  oItem := TMenuItem.Create(pmFiltros);
  oItem.Caption := 'Guardar filtro actual...';
  oItem.OnClick := GuardarFiltroActualClick;
  pmFiltros.Items.Add(oItem);
  oItem := TMenuItem.Create(pmFiltros);
  oItem.Caption := 'Gestionar y compartir filtros...';
  oItem.OnClick := GestionarFiltrosClick;
  pmFiltros.Items.Add(oItem);
end;

function TfrmMtoGen.SerializarFiltroActualBase64: string;
var
  oStreamBin: TMemoryStream;
  oStreamB64: TStringStream;
begin
  Result := '';
  oStreamBin := TMemoryStream.Create;
  oStreamB64 := TStringStream.Create('');
  try
    cxGrdDBTabPrin.DataController.Filter.SaveToStream(oStreamBin);
    oStreamBin.Position := 0;
    TNetEncoding.Base64.Encode(oStreamBin, oStreamB64);
    Result := oStreamB64.DataString;
  finally
    FreeAndNil(oStreamB64);
    FreeAndNil(oStreamBin);
  end;
end;

function TfrmMtoGen.ExtraerBusquedaGlobalDelFiltro: string;
  function TextoDesdeLike(const AValor: string): string;
  var
    sValor: string;
  begin
    Result := '';
    sValor := Trim(AValor);
    if (Length(sValor) >= 2) and
       (sValor[1] = '%') and
       (sValor[Length(sValor)] = '%') then
    begin
      Result := Copy(sValor, 2, Length(sValor) - 2);
    end;
  end;
  function TextoBusquedaLista(
    ALista: TcxFilterCriteriaItemList): string;
  var
    i: Integer;
    bValido: Boolean;
    oItemBase: TcxCustomFilterCriteriaItem;
    oItem: TcxFilterCriteriaItem;
    sTexto: string;
    sTextoItem: string;
  begin
    Result := '';
    sTexto := '';
    bValido := Assigned(ALista) and
               (ALista.BoolOperatorKind = fboOr) and
               (ALista.Count > 0);
    i := 0;
    oItem := nil;
    while bValido and (i < ALista.Count) do
    begin
      oItemBase := ALista.Items[i];
      bValido := (not oItemBase.IsItemList) and
                 (oItemBase is TcxFilterCriteriaItem);
      if bValido then
      begin
        oItem := TcxFilterCriteriaItem(oItemBase);
        bValido := oItem.OperatorKind = foLike;
      end;
      if bValido then
      begin
        sTextoItem := TextoDesdeLike(VarToStr(oItem.Value));
        if sTextoItem = '' then
        begin
          sTextoItem := TextoDesdeLike(oItem.DisplayValue);
        end;
        bValido := sTextoItem <> '';
      end;
      if bValido then
      begin
        if sTexto = '' then
        begin
          sTexto := sTextoItem;
        end
        else
        begin
          bValido := SameText(sTexto, sTextoItem);
        end;
      end;
      Inc(i);
    end;
    if bValido then
    begin
      Result := sTexto;
    end;
  end;
var
  i: Integer;
  oItemBase: TcxCustomFilterCriteriaItem;
  oRaiz: TcxFilterCriteriaItemList;
begin
  Result := '';
  oRaiz := cxGrdDBTabPrin.DataController.Filter.Root;
  if oRaiz.BoolOperatorKind = fboOr then
  begin
    Result := TextoBusquedaLista(oRaiz);
  end;
  if (Result = '') and (oRaiz.BoolOperatorKind = fboAnd) then
  begin
    i := 0;
    while (Result = '') and (i < oRaiz.Count) do
    begin
      oItemBase := oRaiz.Items[i];
      if oItemBase.IsItemList then
      begin
        Result := TextoBusquedaLista(
          TcxFilterCriteriaItemList(oItemBase));
      end;
      Inc(i);
    end;
  end;
end;

procedure TfrmMtoGen.RestaurarFiltroCapturado;
begin
  if not (csDestroying in ComponentState) then
  begin
    tmrBusqGlobal.Enabled := False;
    if edtBusqGlobal.Text <> FBusqGlobalMenu then
    begin
      edtBusqGlobal.Text := FBusqGlobalMenu;
    end;
    tmrBusqGlobal.Enabled := False;
    if FBusqGlobalMenu <> '' then
    begin
      BusqAllGrid(cxGrdDBTabPrin,
                  FBusqGlobalMenu);
    end
    else if FFiltroMenuBase64 <> '' then
    begin
      AplicarFiltroDesdeBase64(FFiltroMenuBase64);
    end;
  end;
end;

procedure TfrmMtoGen.AplicarFiltroDesdeBase64(const ABase64: string);
var
  oStreamBin: TMemoryStream;
  oStreamB64: TStringStream;
  sBusqGlobal: string;
begin
  if ABase64 = '' then
  begin
    ShowMessage('El filtro seleccionado no tiene condiciones guardadas.');
  end
  else
  begin
    oStreamB64 := TStringStream.Create(ABase64);
    oStreamBin := TMemoryStream.Create;
    try
      oStreamB64.Position := 0;
      TNetEncoding.Base64.Decode(oStreamB64, oStreamBin);
      oStreamBin.Position := 0;
      cxGrdDBTabPrin.DataController.Filter.LoadFromStream(oStreamBin);
      cxGrdDBTabPrin.DataController.Filter.Active :=
        not cxGrdDBTabPrin.DataController.Filter.IsEmpty;
      sBusqGlobal := ExtraerBusquedaGlobalDelFiltro;
      tmrBusqGlobal.Enabled := False;
      if edtBusqGlobal.Text <> sBusqGlobal then
      begin
        edtBusqGlobal.Text := sBusqGlobal;
      end;
      tmrBusqGlobal.Enabled := False;
      FBusqGlobalMenu := sBusqGlobal;
      FFiltroMenuBase64 := ABase64;
    finally
      FreeAndNil(oStreamBin);
      FreeAndNil(oStreamB64);
    end;
  end;
end;

procedure TfrmMtoGen.AplicarFiltroGuardadoClick(Sender: TObject);
var
  sFiltroBase64: string;
begin
  tmrBusqGlobal.Enabled := False;
  sFiltroBase64 := odmFiltros.CargarFiltroBase64((Sender as TMenuItem).Tag);
  AplicarFiltroDesdeBase64(sFiltroBase64);
  tmrBusqGlobal.Enabled := False;
end;

procedure TfrmMtoGen.GuardarFiltroActualClick(Sender: TObject);
var
  res: TGuardarFiltroResult;
  sFiltroBase64: string;
  sBusqGlobal: string;
  iIdFiltro: Int64;
begin
  if tmrBusqGlobal.Enabled then
  begin
    tmrBusqGlobal.Enabled := False;
    BusqAllGrid(cxGrdDBTabPrin,
                edtBusqGlobal.Text);
  end;
  sFiltroBase64 := '';
  sBusqGlobal := edtBusqGlobal.Text;
  if (sBusqGlobal = '') and (FBusqGlobalMenu <> '') then
  begin
    sBusqGlobal := FBusqGlobalMenu;
  end;
  tmrBusqGlobal.Enabled := False;
  if edtBusqGlobal.Text <> sBusqGlobal then
  begin
    edtBusqGlobal.Text := sBusqGlobal;
  end;
  tmrBusqGlobal.Enabled := False;
  if sBusqGlobal <> '' then
  begin
    BusqAllGrid(cxGrdDBTabPrin,
                sBusqGlobal);
    sFiltroBase64 := SerializarFiltroActualBase64;
    BusqAllGrid(cxGrdDBTabPrin,
                sBusqGlobal);
  end
  else if not cxGrdDBTabPrin.DataController.Filter.IsEmpty then
  begin
    sFiltroBase64 := SerializarFiltroActualBase64;
  end
  else if FFiltroMenuBase64 <> '' then
  begin
    sFiltroBase64 := FFiltroMenuBase64;
    AplicarFiltroDesdeBase64(sFiltroBase64);
  end;
  if sFiltroBase64 = '' then
  begin
    ShowMessage('No hay ningun filtro aplicado en la lista para guardar.');
  end
  else
  begin
    try
      FFiltroMenuBase64 := sFiltroBase64;
      FBusqGlobalMenu := sBusqGlobal;
      RestaurarFiltroCapturado;
      TThread.ForceQueue(nil,
        procedure
        begin
          RestaurarFiltroCapturado;
        end);
      res := TfrmModalGuardarFiltro.Ejecutar(Self);
      if res.Aceptado then
      begin
        iIdFiltro := odmFiltros.BuscarFiltroPropio(Self.Name,
                                                   cxGrdDBTabPrin.Name,
                                                   res.Nombre);
        if iIdFiltro > 0 then
        begin
          if Application.MessageBox(
              'Ya existe un filtro propio con ese nombre. ' +
              'Desea sobrescribirlo?',
              'Sobrescribir filtro',
              MB_YESNO + MB_ICONQUESTION) = ID_YES then
          begin
            odmFiltros.SobrescribirFiltro(iIdFiltro, res.Nombre,
                                          res.Descripcion, sFiltroBase64);
            ShowMessage('Filtro sobrescrito correctamente.');
          end;
        end
        else
        begin
          odmFiltros.GuardarFiltroNuevo(Self.Name, cxGrdDBTabPrin.Name,
                                        res.Nombre, res.Descripcion,
                                        sFiltroBase64);
          ShowMessage('Filtro guardado correctamente.');
        end;
      end;
    finally
      RestaurarFiltroCapturado;
    end;
  end;
end;

procedure TfrmMtoGen.GestionarFiltrosClick(Sender: TObject);
var
  res: TGestionFiltrosResult;
begin
  res := TfrmModalGestionFiltros.Ejecutar(Self, Self.Name,
                                          cxGrdDBTabPrin.Name,
                                          cxGrdDBTabPrin,
                                          FFiltroMenuBase64);
  if res.Aplicado then
  begin
    AplicarFiltroDesdeBase64(res.FiltroBase64);
  end;
end;

initialization

finalization

end.
