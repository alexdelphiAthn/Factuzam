{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipal                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para presentar la pantalla    }
{    Principal de entrada al programa donde está el menú con todas las opcio-  }
{    nes disponibles. Guarda estructuras como Conexión a BBDD.                 }
{******************************************************************************}
unit inMtoPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils,
  System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxCore, cxContainer,
  cxEdit, dxSkinsForm, cxStyles, cxClasses, Vcl.ExtCtrls, cxLabel,
  Vcl.Menus, cxPC, cxTextEdit, cxMemo, inMtoFrmBase, UniDataConn,
  UniDataPerfiles, UniDataFiltros, cxLocalization, Vcl.Buttons,
  inLibUnitForm, JvMenus,
  System.UITypes, Uni, dxShellDialogs, dxSkinsCore, dxSkinBlue,
  JvComponentBase, JvEnterTab, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue,
  inLibFormManager, System.Actions,
  Vcl.ComCtrls, JvExComCtrls, JvStatusBar, Vcl.AppEvnts,
  System.Diagnostics,
  System.Threading,
  dxGDIPlusClasses, cxImage, Vcl.Imaging.pngimage,
  inLibContextoSesionIntf, inLibParametrosIntf, inLibShowMto,
  inLibLicenciaAplicacion, inLibAnfitrionMtoIntf,
  inLibCajaVentanasIntf, inLibPermisosIntf,
  inLibCopiasSeguridadIntf,
  inLibExcepcionesAplicacionIntf;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(
    TfrmBase,
    IProveedorParametrosEdicion,
    IAnfitrionPantallas,
    IAnfitrionMantenimiento,
    IProveedorMenuPantallas,
    IAnfitrionCajaVentanas
  )
    mnuCaja: TMenuItem;
    mnuMenuCaja: TMenuItem;
    mnuAlmacenes: TMenuItem;
    mnuInvocarLogin: TMenuItem;
    mnuCajaParam: TMenuItem;
    JvStatusBar1: TJvStatusBar;
    saveDialog: TFileSaveDialog;
    openDialog: TFileOpenDialog;
    mnuParmetrosdeEntorno: TMenuItem;
    N2: TMenuItem;
    Compras1: TMenuItem;
    FormasdePagoCaja1: TMenuItem;
    Pedidos1: TMenuItem;
    Albaranes1: TMenuItem;
    Devoluciones1: TMenuItem;
    FacturarAlbaranes1: TMenuItem;
    Facturas1: TMenuItem;
    EfectosCompra1: TMenuItem;
    RemesasCompra1: TMenuItem;
    CargarEfectos1: TMenuItem;
    Sesiones1: TMenuItem;
    mnuCrearArtculosyunpedidoounalbarn: TMenuItem;
    Formasdepago2: TMenuItem;
    mnuComprasListados: TMenuItem;
    mnuListadoDocsProveedor: TMenuItem;
    mnuListadoEfectosPago: TMenuItem;
    dxSkinController1: TdxSkinController;
    mnuAlmacen: TMenuItem;
    Movimientosdealmacn1: TMenuItem;
    mnuInventarios: TMenuItem;
    mnuDocumentosTrabajo: TMenuItem;
    mnuPropiedades: TMenuItem;
    mnuVariaciones: TMenuItem;
    mnuAtributosConjuntos: TMenuItem;
    mnuAtributosBasicos: TMenuItem;
    mnuCajaPagosHist: TMenuItem;
    mnuCajaValesHist: TMenuItem;
    mnuVerifactu: TMenuItem;
    mnuVerifactuDeclaracion: TMenuItem;
    mnuVerifactuCola: TMenuItem;
    mnuVerifactuLog: TMenuItem;
    mnuCajaOperacionesHist: TMenuItem;
    mnuDepositosCliente: TMenuItem;
    mnuFacturasSimplif: TMenuItem;
    mnuCajaArqueosHist: TMenuItem;
    mnuAlmacenInformes: TMenuItem;
    mnuBalanceAlmacenHorizontal: TMenuItem;
    mnuBalanceAlmacenSinTallas: TMenuItem;
    mnuMovVentasArt: TMenuItem;
    EfectosVenta1: TMenuItem;
    RemesasVenta1: TMenuItem;
    CargarEfectosVenta1: TMenuItem;
    mnuTPVListados: TMenuItem;
    mnuListadoOperacionesVenta: TMenuItem;
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuInvocarLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure mnuListadoOperacionesVentaClick(Sender: TObject);
    procedure mnuParmetrosdeEntornoClick(Sender: TObject);
//    procedure mnuPropiedadesValoresClick(Sender: TObject);
    procedure mnuVerifactuDeclaracionClick(Sender: TObject);
    procedure mnuBalanceAlmacenHorizontalClick(Sender: TObject);
    procedure mnuBalanceAlmacenSinTallasClick(Sender: TObject);
    procedure mnuMovVentasArtClick(Sender: TObject);
    procedure mnuListadoDocsProveedorClick(Sender: TObject);
    procedure mnuListadoEfectosPagoClick(Sender: TObject);
    procedure pcPrincipalChange(Sender: TObject);
  public
    // Re-vincula la pantalla flotante de fotos (si esta abierta) al
    // Mto recibido y refresca el articulo / SKU activo. NO la abre
    // automaticamente: para abrirla el usuario debe pulsar Ctrl+F
    // en el Mto activo. Llamado desde pcPrincipalChange (cambio de
    // pestana) y desde TfrmMtoGen.FormShow para mantener el contexto.
    procedure EngancharFotoAlMto(AMto: TObject);
    // IAnfitrionPantallas: lo que inLibShowMto necesita del principal
    // (asi la libreria ya no conoce TfrmMtoPrincipal).
    function GestorVentanas: TEmbeddedFormManager;
    function RegistroPantallas: TfzaWinF;
    procedure PrepararAperturaPantalla;
    function ResolverCallPantalla(const AUnidadClase: string): string;
    function ResolverDataModulePantalla(
      const AUnidadClase: string): string;
    procedure CancelarEdicionesPantallas;
    procedure VincularFotoMantenimiento(AMantenimiento: TObject);
    function MenuAplicacion: TMainMenu;
    function CrearOperacionCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IOperacionCaja;
    function CrearConsultaOperacionesCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
  published
    tmr1: TTimer;
    StyleRepository1: TcxStyleRepository;
    StylCab: TcxStyle;
    EditStyleController: TcxEditStyleController;
    LookAndFeelController1: TcxLookAndFeelController;
    Panel1: TPanel;
    pcPrincipal: TcxPageControl;
    imgFondoLogo: TImage;
    pnlPPBottom: TPanel;
    cxMemo1: TcxMemo;
    jvMnMenuPrin: TJvMainMenu;
    Archivo1: TMenuItem;
    Ventas1: TMenuItem;
    Utilidades1: TMenuItem;
    Ayuda1: TMenuItem;
    mnuEmpresas: TMenuItem;
    mnuClientes: TMenuItem;
    mnuProveedores: TMenuItem;
    mnuArticulos: TMenuItem;
    mnuFacturas: TMenuItem;
    ablasAuxiliares1: TMenuItem;
    mnuTarifas: TMenuItem;
    mnuFamilias: TMenuItem;
    Salir1: TMenuItem;
    mnuGruposdeIVA: TMenuItem;
    mnuIvas: TMenuItem;
    mnuContadores: TMenuItem;
    mnuPaises: TMenuItem;
    mnuUnidadesMedida: TMenuItem;
    N1: TMenuItem;
    UsuariosGruposyPerfiles1: TMenuItem;
    HacerCopiadeSeguridad1: TMenuItem;
    mnuEjecutarScript: TMenuItem;
    mnuGeneradorProcesos: TMenuItem;
    mnuUsuarios: TMenuItem;
    mnuEmpleados: TMenuItem;
    mnuGrupos: TMenuItem;
    mnuPerfiles: TMenuItem;
    mnuPermisos: TMenuItem;
    mnuPermisosTabla: TMenuItem;
    Acercade1: TMenuItem;
    mnuManualWeb: TMenuItem;
    mnuForoSoporte: TMenuItem;
    mnuConsultaStocks: TMenuItem;
    mnuArticulosSimilares: TMenuItem;
    Listados1: TMenuItem;
    mnuLisVentas: TMenuItem;
    mnuPedidosVenta: TMenuItem;
    mnuAlbaranesVenta: TMenuItem;
    procedure CargarEfectosVenta1Click(Sender: TObject);
    procedure Sesiones1Click(Sender: TObject);
    procedure FacturarAlbaranes1Click(Sender: TObject);
    procedure CargarEfectos1Click(Sender: TObject);
    procedure Formasdepago2Click(Sender: TObject);
    procedure mnuTarifasClick(Sender: TObject);
    procedure mnArchivoSalirClick(Sender: TObject);
    procedure CopiasdeSeguridad1Click(Sender: TObject);
    // Handler unico de los menus de apertura de pantalla: resuelve
    // el CALL del item (fza_winforms) y delega en ShowMto. Sustituye a
    // ~45 OnClick identicos. Pantalla nueva = fila en fza_winforms +
    // OnClick del item = MenuGenericoClick (sin handler nuevo).
    procedure MenuGenericoClick(Sender: TObject);
    procedure mnuEjecutarScriptClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure mnuAcercadeClick(Sender: TObject);
    procedure mnuManualWebClick(Sender: TObject);
    procedure mnuForoSoporteClick(Sender: TObject);
    procedure mnuConsultaStocksClick(Sender: TObject);
    procedure mnuArticulosSimilaresClick(Sender: TObject);
    function IsShortCut(var Message: TWMKey): Boolean; override;
//    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
//      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure WMFreeControl(var Msg: TMessage); message WM_FREECONTROL;
  private
    FException: Boolean;
    FSavedNCMValid: Boolean;
    FEnOperacionLarga: Boolean;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    FWorkerOperacion: TThread;
    FReiniciando: Boolean;
    FCancelaOperacionSolicitada: Boolean;
    FFalloCargaPermisosAvisado: Boolean;
    FParametrosAppEdicion: IParametrosEdicion;
    FParametrosCajaEdicion: IParametrosEdicion;
    FServicioCopiasSeguridad: IServicioCopiasSeguridad;
    FGestorExcepciones: IGestorExcepcionesAplicacion;
    // Handlers de aplicacion (OnException/OnIdle/OnMessage) registrados via
    // TApplicationEvents: una asignacion directa Application.OnX queda
    // anulada en cuanto cualquier form crea su propio TApplicationEvents
    // (multicaster de la VCL), p.ej. el generador de procesos.
    FAppEvents: TApplicationEvents;
    procedure AbrirUrlAyuda(const AUrl: string);
    procedure AplicarTituloVentana;
    procedure AppException(Sender: TObject; E: Exception);
    procedure AplicarPermisosMenu;
    procedure AvisarFalloCargaPermisos(const ADetalle: string);
    // Precarga de caches de arranque. El modo (serie / paralelo) lo decide
    // el parametro appArranqueEnParalelo.
    procedure PrecargarCachesSerie;
    procedure PrecargarCachesParalelo;
    function EjecutarCargaWorker(ACarga: TProc<TUniConnection>;
                                 out AError: string): Int64;
    function SolicitarDestinoCopia(
      out ARutaFichero, AContrasena: string
    ): Boolean;
    function CrearCopiaPreviaScript: Boolean;
    function SolicitarOrigenRestauracion(
      out ARutaFichero, AContrasena: string
    ): Boolean;
    procedure WorkerProgreso(const AEtapa: string;
                              APaso, ATotal: Integer;
                              AFilaGlobal,
                              AFilasGlobalTotal: Integer);
    procedure BackupFinalizar(AExito: Boolean; const AError: string;
                               ALogBuffer: TStringList);
    procedure RestoreFinalizar(AExito: Boolean; const AError: string;
                                ALogBuffer: TStringList);
    function EsErrorCancelacion(const AError: string): Boolean;
    procedure SolicitarCancelarOperacionEnCurso;
    procedure MostrarBarraProgreso;
    procedure OcultarBarraProgreso;
    function ContieneDDL(const ASQL: string): Boolean;
    procedure ActualizarFondoLogo;
    procedure CargarFondoLogo;
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    function GetParametrosAppEdicion: IParametrosEdicion;
    function GetParametrosCajaEdicion: IParametrosEdicion;
    // Atajos globales capturados a nivel de aplicacion (las ventanas de caja
    // son top-level y no pasan por IsShortCut): F9 abre el cajon desde
    // cualquier ventana si hay impresora de tickets asignada y Ctrl+U abre
    // la consulta de stock; Ctrl+E abre la consulta de articulos similares.
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure MostrarAvisoCaducidadCertificado;
  public
    { Public declarations }
    FormManager : TEmbeddedFormManager;
    FDmConn: TdmConn;
    FdmDataPerfiles: TdmPerfiles;
    FdmDataFiltros: TdmFiltros;
    oFzaWinf: TfzaWinF;
    // Splash mostrado al arrancar; lo libera CerrarSplashInicio al final
    // del FormCreate, respetando un suelo minimo de visibilidad.
    FSplashInicio:    TObject;
    FSplashTimestamp: TDateTime;
    // Logo de fondo + nombre + version creados dinamicamente sobre Panel1.
    // Replica visual del splash; visibles cuando no hay pestañas abiertas
    // y ocultos en cuanto se abre cualquier mantenimiento.
    FLogoBgPanel:   TObject;
    FLogoBgImage:   TObject;
    FLogoBgNombre:  TObject;
    FLogoBgVersion: TObject;
    procedure InicializarAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure CerrarSplashInicio(aMinimoMs: Integer);
    procedure CrearLogoFondoBg;
    procedure CentrarLogoFondoBg;
    procedure FormResize(Sender: TObject);
  end;

var
  frmMtoPrincipal: TfrmMtoPrincipal;
  bIsConnected: Boolean;

implementation

uses inLibUser,
  inLibWin,
  inLibDevExp,
  inLibGlobalVar,
  inLibInformesGuiasCache,
  inLibConfigCampos,
  inLibPermisos,
  inLibPermisosUniDAC,
  inLibConexionesIntf,
  inLibConexionesUniDAC,
  inLibTraduccionesIntf,
  inLibTraducciones,
  inLibAuditoriaDatosIntf,
  inLibAuditoriaDatos,
  inLibMonitorSQLIntf,
  inLibMonitorSQLUniDAC,
  inLibMonitorSQLLog,
  inLibLog,
  inLibMsg,
  inLibDir,
  inMtoSplash,
  inMtoAppParam,
  inMtoCajaMenu,
  inMtoCajaOpe,
  inMtoConsultaOpe,
  inMtoCajaParam,
  inMtoBusquedaDatos,
  inMtoModalVerifactuDecl,
  inLibGenerarTicketCaja,
  inMtoStockConsulta,
  inMtoModalListadoVentas,
  inMtoModalImpOperacionesVenta,
  inMtoModalScriptLog,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inMtoModalImpMovVentasArt,
  inMtoModalImpDocsProveedor,
  inMtoModalImpEfectosPago,
  inMtoModalFacturarAlbaranes,
  inMtoModalCargarEfectosRemesa,
  inLibCajaParam,
  inLibAppParam,
  inLibUnidadesMedida,
  inLibFotos,
  inLibVerifactu,
  inLibVerifactuInstalacion,
  inLibVerifactuCola,
  inLibVentasWsCola,
  inLibCertificates,
  inMtoGen,
  inMtoFotoArticulo,
  System.DateUtils,
  System.RegularExpressions,
  inLibCopiasSeguridad,
  inLibExcepcionesAplicacion,
  inMtoModalContrasenaCopia;

{$R *.dfm}

const
  URL_MANUAL_WEB = 'https://www.veryverifactu.com/manual/index.html';
  URL_FORO_SOPORTE = 'https://foro.veryverifactu.com/';

type
  TVisorMonitorSQLMemo = class(
    TInterfacedObject,
    IVisorMonitorSQL
  )
  private
    FMemo: TcxMemo;
  public
    constructor Create(AMemo: TcxMemo);
    procedure EstablecerVisible(AVisible: Boolean);
    procedure MostrarSQL(const ASQL: string);
  end;

constructor TVisorMonitorSQLMemo.Create(AMemo: TcxMemo);
begin
  inherited Create;
  FMemo := AMemo;
end;

procedure TVisorMonitorSQLMemo.EstablecerVisible(AVisible: Boolean);
begin
  if Assigned(FMemo) then
  begin
    FMemo.Visible := AVisible;
    if Assigned(FMemo.Parent) then
      FMemo.Parent.Visible := AVisible;
  end;
end;

procedure TVisorMonitorSQLMemo.MostrarSQL(const ASQL: string);
begin
  if Assigned(FMemo) and FMemo.Visible then
    FMemo.Lines.Add(
      FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + ASQL);
end;

function EsEventoNoVerifactuArranqueCierre(ATipoEvento: Integer): Boolean;
begin
  Result := (ATipoEvento = cEventoNoVerifactuInicio) or
            (ATipoEvento = cEventoNoVerifactuFin);
end;

function PuedeRegistrarEventoFiscalSeguro(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          ATipoEvento: Integer;
                                          const ADescripcion: string):
                                          Boolean;
var
  sNifProductor: string;
begin
  Result := True;
  if EsEventoNoVerifactuArranqueCierre(ATipoEvento) then
  begin
    if not NoVerifactuActivo(AParametrosApp) then
      Result := False
    else
    begin
      sNifProductor := NormalizarNifVerifactu(
        AParametrosApp.GetString('appVerifactuSifNif', ''));
      if Length(sNifProductor) <> 9 then
      begin
        Result := False;
        inLibLog.Log.LogWarning('No se registra evento fiscal "' +
          ADescripcion + '": appVerifactuSifNif vacío o no válido para ' +
          'el perfil actual.');
      end;
    end;
  end;
end;

procedure RegistrarEventoFiscalSeguro(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      AConexion: TUniConnection;
                                      const AUsuario: string;
                                      ATipoEvento: Integer;
                                      const ADescripcion: string);
begin
  if PuedeRegistrarEventoFiscalSeguro(AParametrosApp, ATipoEvento,
     ADescripcion) then
  begin
    try
      if AConexion <> nil then
        RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
          ATipoEvento, ADescripcion);
    except
      on E: Exception do
        inLibLog.Log.LogError('No se pudo registrar evento fiscal "' +
          ADescripcion + '": ' + E.Message);
    end;
  end;
end;

procedure TfrmMtoPrincipal.MostrarAvisoCaducidadCertificado;
const
  DIAS_AVISO_CERTIFICADO = 5;
var
  Qry: TUniQuery;
  Avisos: TStringList;
  sEmpresa: string;
  sSerie: string;
  sTitular: string;
  sTitularReal: string;
  sPrefijo: string;
  dCaducidad: TDateTime;
  iDias: Integer;
  bHayCaducidad: Boolean;

  function TextoDias(ADias: Integer): string;
  begin
    if ADias <= 0 then
      Result := SCertificadoQuedaMenosUnDia
    else if ADias = 1 then
      Result := SCertificadoQuedaUnDia
    else
      Result := Format(SCertificadoQuedanDias, [ADias]);
  end;

  procedure AgregarAviso(const ATexto: string);
  begin
    sPrefijo := '- ' + sEmpresa + ': ';
    if Trim(sTitularReal) <> '' then
      sPrefijo := sPrefijo + Trim(sTitularReal) + ', ';
    Avisos.Add(sPrefijo + ATexto);
  end;

begin
  if ConexionPrincipal <> nil then
  begin
    Avisos := TStringList.Create;
    try
      Qry := TUniQuery.Create(nil);
      try
        try
          Qry.Connection := ConexionPrincipal;
          Qry.SQL.Text :=
            'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, ' +
            '       CODIGO_CERTIFICADO_EMP, TITULAR_CERTIFICADO_EMP, ' +
            '       FECHA_HASTA_CERTIFICADO_EMP ' +
            '  FROM fza_empresas ' +
            ' WHERE IFNULL(ESACTIVO_EMP, ''S'') = ''S'' ' +
            '   AND IFNULL(CODIGO_CERTIFICADO_EMP, '''') <> '''' ' +
            ' ORDER BY ORDEN_EMP, CODIGO_EMP_EMP';
          Qry.Open;
          while not Qry.Eof do
          begin
            sEmpresa := Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
            if sEmpresa = '' then
              sEmpresa := Trim(Qry.FieldByName('CODIGO_EMP_EMP').AsString);
            sSerie := Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
            sTitular :=
              Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
            sTitularReal := sTitular;
            bHayCaducidad := ObtenerCaducidadCertificado(sSerie, sTitular,
                                                         dCaducidad,
                                                         sTitularReal);
            if (not bHayCaducidad) and
               (not Qry.FieldByName(
                 'FECHA_HASTA_CERTIFICADO_EMP').IsNull) then
            begin
              dCaducidad := Qry.FieldByName(
                'FECHA_HASTA_CERTIFICADO_EMP').AsDateTime;
              bHayCaducidad := dCaducidad > 0;
            end;
            if sTitularReal = '' then
              sTitularReal := sTitular;
            if bHayCaducidad then
            begin
              if dCaducidad < Now then
              begin
                AgregarAviso(
                  Format(SAvisoCertificadoCaducado,
                         [FormatDateTime('dd/mm/yyyy hh:nn', dCaducidad)]));
              end
              else if dCaducidad < IncDay(Now, DIAS_AVISO_CERTIFICADO) then
              begin
                iDias := Trunc(dCaducidad - Now);
                AgregarAviso(
                  Format(SAvisoCertificadoProximoCaducar,
                         [FormatDateTime('dd/mm/yyyy hh:nn', dCaducidad),
                          TextoDias(iDias)]));
              end;
            end;
            Qry.Next;
          end;
          if Avisos.Count > 0 then
          begin
            MessageDlg(Format(SAvisoCertificadosCaducidad, [Avisos.Text]),
                       mtWarning, [mbOK], 0);
          end;
        except
          on E: Exception do
            inLibLog.Log.LogWarning('No se pudo comprobar la caducidad de ' +
              'certificados al arrancar: ' + E.Message);
        end;
      finally
        FreeAndNil(Qry);
      end;
    finally
      FreeAndNil(Avisos);
    end;
  end;
end;

procedure TfrmMtoPrincipal.AplicarTituloVentana;
var
  sTitulo: string;
begin
  if EstadoLicenciaEsDemo(ParametrosApp.Licencia.Estado) then
    sTitulo := oAppName + ' DEMO ' + oVersion
  else
    sTitulo := oAppName + ' ' + oVersion;
  Self.Caption := sTitulo;
  Application.Title := sTitulo;
end;

function TfrmMtoPrincipal.ContieneDDL(const ASQL: string): Boolean;
var
  Patron: string;
begin
  Patron := '\b(CREATE|ALTER|DROP|TRUNCATE|RENAME)\b';
  Result := TRegEx.IsMatch(ASQL, Patron, [roIgnoreCase]);
end;

procedure TfrmMtoPrincipal.ApplicationEvents1Idle(Sender: TObject;
                                                  var Done: Boolean);
var
  EstadoTeclas: string;
begin
  if FEnOperacionLarga then
  begin
    Done := True;
    Exit;
  end;
  EstadoTeclas := '';
  if (GetKeyState(VK_CAPITAL) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'CAPS  ';
  if (GetKeyState(VK_NUMLOCK) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'NUM  ';
  if (GetKeyState(VK_SCROLL) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'SCRL  ';
  if (GetKeyState(VK_INSERT) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'OVR'
  else
    EstadoTeclas := EstadoTeclas + 'INS';
  EstadoTeclas := Trim(EstadoTeclas);
  if jvStatusBar1.Panels[0].Text <> EstadoTeclas then
    jvStatusBar1.Panels[0].Text := EstadoTeclas;
  ActualizarFondoLogo;
end;

procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
begin
  // El proyecto inyecta el contexto antes de inicializar los servicios.
end;

function TfrmMtoPrincipal.GetParametrosAppEdicion: IParametrosEdicion;
begin
  Result := FParametrosAppEdicion;
end;

function TfrmMtoPrincipal.GetParametrosCajaEdicion: IParametrosEdicion;
begin
  Result := FParametrosCajaEdicion;
end;

procedure TfrmMtoPrincipal.InicializarAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
var
  sDis: string;
  ServicioMonitorSQL: IServicioMonitorSQL;
  RegistroMonitorSQL: IRegistroMonitorSQL;
  VisorMonitorSQL: IVisorMonitorSQL;
  IdentidadActual: TIdentidadSesion;
  UbicacionActual: TUbicacionSesion;
  ParametrosAppCreados: IParametrosAplicacion;
  ParametrosCajaCreados: IParametrosCaja;
  GestorLicencia: IGestorLicenciaAplicacion;

  procedure AplicarTema;
  var
    sTema, sPaleta: string;
  begin
    if not (Assigned(LookAndFeelController1) and
            Assigned(dxSkinController1)) then
      Exit;
    try
      sTema := ParametrosApp.GetString('appTema');
      if sTema = '' then
      begin
        if DarkModeIsEnabled then
          sTema := 'MetropolisDark'
        else
          sTema := 'Office2007Pink';
      end;
      LookAndFeelController1.SkinName := sTema;
      dxSkinController1.SkinName      := sTema;
      // Paleta de color (solo skins modernos la soportan)
      sPaleta := ParametrosApp.GetString('appPaleta');
      if sPaleta <> '' then
        TcxRootLookAndFeel.Instance.SkinPaletteName := sPaleta;
    except
      on E: Exception do
        inLibLog.Log.LogWarning('Error al establecer skin: ' + E.Message);
    end;
  end;

begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create(
      SErrorContextoInicioSesionNoProporcionado);
  AsignarContextoSesion(AContextoSesion);
  IdentidadActual := ContextoSesion.Identidad;
  UbicacionActual := ContextoSesion.Ubicacion;
  FGestorExcepciones :=
    CrearGestorExcepcionesAplicacion(
      ContextoSesion);
  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnException := AppException;
  FSavedNCMValid := False;
  FAppEvents.OnIdle := ApplicationEvents1Idle;
  FAppEvents.OnMessage := AppMessage;
  FWorkerOperacion := nil;
  FCancelaOperacionSolicitada := False;
  FEnOperacionLarga := False;
  sDis := '';
  // Splash no-modal al arrancar. Lo mantenemos visible mientras corre el
  // resto de la inicializacion y garantizamos un suelo de 1000 ms para
  // que la marca se lea aunque todo termine en 250 ms.
  FSplashInicio := nil;
  FSplashTimestamp := Now;
  try
    FSplashInicio := TfrmSplash.Create(nil);
    TfrmSplash(FSplashInicio).FormStyle := fsStayOnTop;
    TfrmSplash(FSplashInicio).btnAceptar.Visible := False;
    TfrmSplash(FSplashInicio).Show;
    Application.ProcessMessages;
  except
    // Si el splash falla por lo que sea, no rompemos el arranque.
    FreeAndNil(FSplashInicio);
  end;
  FormManager := TEmbeddedFormManager.Create(Self.pcPrincipal);
  FDmConn     := TdmConn.Create(Self);
  FServicioCopiasSeguridad := TServicioCopiasSeguridad.Create(
    ContextoSesion,
    FDmConn.conUni);
  VisorMonitorSQL := TVisorMonitorSQLMemo.Create(cxMemo1);
  RegistroMonitorSQL := TRegistroMonitorSQLLog.Create(
    inLibLog.Log,
    VisorMonitorSQL);
  ServicioMonitorSQL :=
    TServicioMonitorSQLUniDAC.Create(
      FDmConn.UniSQLMonitor1,
      RegistroMonitorSQL);
  FDmConn.AsignarReceptorMonitorSQL(
    ServicioMonitorSQL as IReceptorEventosMonitorSQL);
  AsignarMonitorSQL(ServicioMonitorSQL);
  inLibLog.Log.AsignarMonitorSQL(ServicioMonitorSQL);
  FDmConn.conUni.Connect;
  AsignarConexiones(
    TServicioConexionesUniDAC.Create(FDmConn.conUni));
  oUnidades.AsignarConexion(ConexionPrincipal);
  AsignarAuditoriaDatos(
    TServicioAuditoriaDatos.Create(ContextoSesion));
  tmr1Timer(nil);
  FdmDataPerfiles := TdmPerfiles.Create(Self);
  AsignarPerfilesUsuario(FdmDataPerfiles);
  inLibLog.Log.LogInfo('Arranque: creando parámetros de aplicación');
  ParametrosAppCreados := CrearParametrosAplicacion(
    PerfilesUsuario,
    IdentidadActual.Usuario,
    IdentidadActual.Grupo
  );
  if not Supports(
    ParametrosAppCreados,
    IGestorLicenciaAplicacion,
    GestorLicencia
  ) then
    raise Exception.Create(SErrorParametrosSinEstadoLicencia);
  GestorLicencia.EstablecerLicencia(AResultadoLicencia);
  inLibLog.Log.LogInfo('Arranque: creando parámetros de caja');
  ParametrosCajaCreados := CrearParametrosCaja(
    PerfilesUsuario,
    ContextoSesion,
    IdentidadActual.Usuario,
    IdentidadActual.Grupo
  );
  if not Supports(
    ParametrosAppCreados,
    IParametrosEdicion,
    FParametrosAppEdicion
  ) then
    raise Exception.Create(SErrorParametrosAplicacionSinContratoEdicion);
  if not Supports(
    ParametrosCajaCreados,
    IParametrosEdicion,
    FParametrosCajaEdicion
  ) then
    raise Exception.Create(SErrorParametrosCajaSinContratoEdicion);
  AsignarParametros(ParametrosAppCreados, ParametrosCajaCreados);
  FDmConn.AsignarParametrosApp(ParametrosAppCreados);
  AsignarTraducciones(
    TServicioTraducciones.Create(
      Conexiones,
      ParametrosApp.GetString('appIdioma', IDIOMA_ESPANOL)));
  Traducciones.Aplicar(Self);
  oFotos.AsignarConexion(ConexionPrincipal, ParametrosApp);
  FdmDataFiltros  := TdmFiltros.Create(Self);
  AsignarFiltrosGuardados(FdmDataFiltros);
  oFzaWinf := TfzaWinF.Create(Self);
  oFzaWinf.Charge(ConexionPrincipal);
  // Toda pantalla de fza_winforms debe tener su clase en el catalogo
  // (inMtoCatalogoPantallas); si falta alguna queda en el log desde el
  // arranque en vez de reventar al abrir el menu.
  oFzaWinf.ComprobarRegistradas;
  try
    SincronizarVersionInstalacionesSif(
      ParametrosApp,
      ConexionPrincipal,
      IdentidadSesion.Usuario);
  except
    on E: Exception do
      inLibLog.Log.LogWarning('No se pudo sincronizar la versión SIF: ' +
                              E.Message);
  end;
  try
    AsegurarDeclaracionResponsableSif(ParametrosApp, oVersion);
  except
    on E: Exception do
      inLibLog.Log.LogWarning('No se pudo disponer de la declaración ' +
                              'responsable de esta versión: ' + E.Message);
  end;
  if ParametrosApp.GetBool('appArranqueEnParalelo', False) then
    PrecargarCachesParalelo
  else
    PrecargarCachesSerie;
  // Cache de unidades de medida: decimales por unidad y factores de
  // conversion. La usan ficha de articulo, lineas de documento e informes.
  oUnidades.Cargar;
  // Trazar la impresora resuelta: si queda '' o 'DEBUG', el F9 global de
  // abrir cajon no se activa fuera de caja (ver ImpresoraCajaAsignada).
  inLibLog.Log.LogInfo('Arranque: impresora de caja resuelta = "' +
                       ParametrosCaja.ImpresoraCaja + '"');
  // Hilo de la cola Verifactu: arranca siempre; cada ciclo consulta el
  // parámetro appVerifactuActivo, así puede activarse sin reiniciar
  TVerifactuCola.IniciarHilo(
    Conexiones,
    ContextoSesion,
    ParametrosApp,
    ParametrosCaja,
    IdentidadSesion.Usuario);
  TVentasWsCola.IniciarHilo(
    Conexiones,
    ContextoSesion,
    ParametrosApp,
    IdentidadSesion.Usuario);
  jvStatusBar1.Panels[1].Text := FDmConn.conUni.Server + ':' +
    IntToStr(FDmConn.conUni.Port) + ' (' + FDmConn.conUni.Database + ')';
  if IdentidadActual.EsAdministrador then
    sDis := ' ✪';
  jvStatusBar1.Panels[2].Text := IdentidadActual.Usuario + ' (' +
    IdentidadActual.Grupo + ') ' + sDis;
  jvStatusBar1.Panels[3].Text := UbicacionActual.Empresa + '\' +
    UbicacionActual.Almacen + '\' + UbicacionActual.Caja;
  AplicarTituloVentana;
  // Aplicar permisos de menú: ocultar items sin acceso
  AplicarPermisosMenu;
  // Visibilidad inicial del panel de monitor SQL: ya no la decide solo el
  // {$IFDEF DEBUG}. AplicarModosDepuracion la sincronizará con los flags
  // appModoDebug / appModoDebugSQL que acaba de cargar el servicio.
  pnlPPBottom.Visible := False;
  cxMemo1.Visible     := False;
  inLibLog.AplicarModosDepuracion(ParametrosApp);
  AplicarTema;
  CargarFondoLogo;
  // pcPrincipal tiene Align=alClient en Panel1 y repinta su area cliente
  // encima de cualquier hermano. Reparentamos imgFondoLogo al propio
  // pcPrincipal: queda como hijo directo del PageControl (no en una
  // TabSheet), asi se pinta sobre su area cliente cuando no hay pestanas
  // y queda tapado automaticamente por el TcxTabSheet activo cuando si
  // las hay (sin invadir zonas fuera del PageControl).
  imgFondoLogo.Parent := pcPrincipal;
  imgFondoLogo.Anchors := [akTop, akRight];
  imgFondoLogo.Left := pcPrincipal.ClientWidth - imgFondoLogo.Width - 16;
  imgFondoLogo.Top := 16;
  imgFondoLogo.BringToFront;
  // Logo de fondo via TImage + labels dinamicos (replica del splash).
  // El imgFondoLogo del .dfm no termina de pintar por culpa del wrapper
  // TdxSmartImage que VCL no deserializa, asi que servimos la imagen
  // desde controles creados aqui.
  CrearLogoFondoBg;
  // OnResize lo bindeamos en codigo porque FormResize esta en public y
  // .dfm streaming solo encuentra event handlers en published; asi
  // evitamos un EReadError 'Invalid property value' al cargar el form.
  Self.OnResize := FormResize;
  ActualizarFondoLogo;
  inLibLog.Log.LogInfo('Arranque del sistema');
  RegistrarEventoFiscalSeguro(ParametrosApp,
    ConexionPrincipal,
    IdentidadSesion.Usuario,
    cEventoNoVerifactuInicio,
    'Inicio del sistema');
  // Suelo de visibilidad del splash: si la inicializacion fue mas rapida
  // de 1000 ms, esperamos a llegar a ese minimo para que el usuario
  // pueda leer la marca; si tardo mas, lo cerramos sin demora.
  CerrarSplashInicio(1000);
  MostrarAvisoCaducidadCertificado;
end;

procedure TfrmMtoPrincipal.CrearLogoFondoBg;
var
  oNombre:  TcxLabel;
  oVer:     TcxLabel;
begin
  FLogoBgPanel   := nil;
  FLogoBgImage   := nil;
  FLogoBgNombre  := nil;
  FLogoBgVersion := nil;
  // Truco del commit 2b39e93: TImage es TGraphicControl y NUNCA puede
  // pintarse encima de un TWinControl hermano (pcPrincipal alClient en
  // Panel1). La solucion es REPARENTAR imgFondoLogo al propio
  // pcPrincipal — queda como hijo directo del PageControl (no en una
  // TabSheet), se pinta sobre su area cliente vacia cuando no hay
  // pestanas, y la TcxTabSheet activa lo tapa automaticamente cuando
  // si las hay (z-order natural, sin tener que togglear Visible).
  imgFondoLogo.Parent  := pcPrincipal;
  imgFondoLogo.Anchors := [akTop, akRight];
  imgFondoLogo.Proportional := True;
  imgFondoLogo.Stretch      := True;
  imgFondoLogo.Center       := True;
  FLogoBgImage := imgFondoLogo;
  // Labels nombre+version tambien dentro de pcPrincipal para que
  // sigan el mismo destino: visibles sin pestanas, tapados por la
  // TabSheet activa cuando hay alguna abierta.
  oNombre := TcxLabel.Create(Self);
  oNombre.Parent  := pcPrincipal;
  oNombre.Caption := 'Alejandro Laorden Hidalgo';
  oNombre.AutoSize := False;
  oNombre.Style.Font.Name   := 'Lucida Sans';
  oNombre.Style.Font.Height := -17;
  oNombre.Style.Font.Style  := [fsBold];
  oNombre.Properties.Alignment.Horz := taCenter;
  oNombre.Transparent := True;
  FLogoBgNombre := oNombre;
  oVer := TcxLabel.Create(Self);
  oVer.Parent  := pcPrincipal;
  oVer.Caption := 'Versión ' + oVersion;
  oVer.AutoSize := False;
  oVer.Style.Font.Name   := 'Lucida Sans';
  oVer.Style.Font.Height := -14;
  oVer.Properties.Alignment.Horz := taCenter;
  oVer.Transparent := True;
  FLogoBgVersion := oVer;
  CentrarLogoFondoBg;
end;

procedure TfrmMtoPrincipal.CentrarLogoFondoBg;
var
  cw, ch, w, h, cx, cy: Integer;
begin
  if imgFondoLogo = nil then
    Exit;
  // Trabajamos sobre el cliente de pcPrincipal (donde reparentamos los
  // controles), no sobre Panel1. Asi al cambiar el tamano de la ventana
  // FormResize recoloca todo respecto al area cliente real.
  cw := pcPrincipal.ClientWidth;
  ch := pcPrincipal.ClientHeight;
  // Logo: ~33% del ancho, max 380, min 180, manteniendo aspect 520x130.
  w := cw div 3;
  if w > 380 then w := 380;
  if w < 180 then w := 180;
  h := Round(w * 130 / 520);
  cx := (cw - w) div 2;
  cy := (ch - h - 80) div 2;
  if cy < 20 then cy := 20;
  imgFondoLogo.Anchors := [];
  imgFondoLogo.SetBounds(cx, cy, w, h);
  if FLogoBgNombre <> nil then
    TcxLabel(FLogoBgNombre).SetBounds(0, cy + h + 8, cw, 26);
  if FLogoBgVersion <> nil then
    TcxLabel(FLogoBgVersion).SetBounds(0, cy + h + 38, cw, 20);
end;

procedure TfrmMtoPrincipal.FormResize(Sender: TObject);
begin
  CentrarLogoFondoBg;
end;

procedure TfrmMtoPrincipal.CerrarSplashInicio(aMinimoMs: Integer);
var
  iElapsedMs, iEsperaMs: Integer;
begin
  if FSplashInicio = nil then
    Exit;
  // Si ya ha pasado el suelo minimo, cierre inmediato. Si no, dormimos
  // lo que falte. Sleep simple: el splash no se anima durante la espera
  // pero la VCL no se cuelga porque estamos en el ultimo paso de
  // FormCreate; Application.Run procesara mensajes despues.
  iElapsedMs := Round((Now - FSplashTimestamp) * 86400000);
  if iElapsedMs < aMinimoMs then
  begin
    iEsperaMs := aMinimoMs - iElapsedMs;
    Application.ProcessMessages;
    Sleep(iEsperaMs);
  end;
  try
    TfrmSplash(FSplashInicio).Close;
  except
    // Si el form ya estaba liberado por algun motivo, lo ignoramos.
  end;
  FreeAndNil(FSplashInicio);
end;

// El Picture.Data del .dfm trae un envoltorio TdxSmartImage que el TImage
// de VCL no sabe deserializar (queda vacio al cargar el form). Cargamos
// fondo.png desde un recurso RCDATA incrustado en el .exe (ver fondo.rc
// + directiva $R en fzam.dpr) para no depender de archivos en disco.
procedure TfrmMtoPrincipal.CargarFondoLogo;
const
  // Rutas relativas al .exe donde buscar fondo.png si no hay recurso
  CRutas: array[0..1] of string = ('fondo.png', '..\..\fondo.png');
var
  sBase, sRuta: string;
  i: Integer;
  oRes: TResourceStream;
  oPng: TPngImage;
begin
  // 1) Recurso RCDATA 'FONDO' embebido en el .exe via {$R fondo.res} en
  //    fzam.dpr. Es el camino preferente porque no depende de tener el
  //    fichero al lado del .exe. Si el recurso no esta presente (porque
  //    se compilo sin fondo.res) caemos a las rutas relativas de disco.
  try
    oRes := TResourceStream.Create(HInstance, 'FONDO', RT_RCDATA);
    try
      oPng := TPngImage.Create;
      try
        oPng.LoadFromStream(oRes);
        imgFondoLogo.Picture.Assign(oPng);
        inLibLog.Log.LogInfo('CargarFondoLogo: OK desde recurso FONDO ' +
                             '(' + IntToStr(oRes.Size) + ' bytes)');
        Exit;
      finally
        oPng.Free;
      end;
    finally
      oRes.Free;
    end;
  except
    on E: Exception do
      inLibLog.Log.LogInfo('CargarFondoLogo: recurso FONDO no disponible ' +
                           '(' + E.Message + '); pruebo disco');
  end;
  // 2) Fallback a fichero suelto: para builds Debug donde fondo.png
  //    vive en la raiz del repo (..\..ondo.png desde Win32/Debug).
  sBase := inLibDir.DirApp;
  inLibLog.Log.LogInfo('CargarFondoLogo: base="' + sBase + '"');
  for i := 0 to High(CRutas) do
  begin
    sRuta := sBase + CRutas[i];
    if FileExists(sRuta) then
    begin
      try
        imgFondoLogo.Picture.LoadFromFile(sRuta);
        inLibLog.Log.LogInfo('CargarFondoLogo: OK desde "' + sRuta + '"');
        Exit;
      except
        on E: Exception do
          inLibLog.Log.LogWarning('No se pudo cargar fondo ' + sRuta +
                                  ': ' + E.Message);
      end;
    end
    else
      inLibLog.Log.LogInfo('CargarFondoLogo: no existe "' + sRuta + '"');
  end;
end;

procedure TfrmMtoPrincipal.ActualizarFondoLogo;
var
  bDebeVerse, bTieneImg: Boolean;
begin
  // Con imgFondoLogo y labels reparentados a pcPrincipal, la TcxTabSheet
  // activa los tapa por z-order automaticamente cuando hay pestanas
  // abiertas — pero togglear Visible es mas barato que dejarlos pintando
  // detras, asi que mantenemos la condicion PageCount=0 explicita.
  bTieneImg  := imgFondoLogo.Picture.Graphic <> nil;
  bDebeVerse := (pcPrincipal.PageCount = 0) and bTieneImg;
  if imgFondoLogo.Visible <> bDebeVerse then
    imgFondoLogo.Visible := bDebeVerse;
  if FLogoBgNombre <> nil then
    if TcxLabel(FLogoBgNombre).Visible <> bDebeVerse then
      TcxLabel(FLogoBgNombre).Visible := bDebeVerse;
  if FLogoBgVersion <> nil then
    if TcxLabel(FLogoBgVersion).Visible <> bDebeVerse then
      TcxLabel(FLogoBgVersion).Visible := bDebeVerse;
end;

procedure TfrmMtoPrincipal.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self, 'Tarifas');
end;

function TfrmMtoPrincipal.SolicitarDestinoCopia(
  out ARutaFichero, AContrasena: string): Boolean;
var
  bCifrada: Boolean;
  sExtension: string;
begin
  ARutaFichero := '';
  AContrasena := '';
  sExtension := FServicioCopiasSeguridad.ExtensionCreacion;
  bCifrada := FServicioCopiasSeguridad.ModoCreacion =
    mpcCifrada;
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultExtension := Copy(
    sExtension,
    2,
    MaxInt);
  saveDialog.DefaultFolder := ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  saveDialog.Options := saveDialog.Options +
    [fdoStrictFileTypes, fdoOverwritePrompt];
  saveDialog.FileTypes.Clear;
  with saveDialog.FileTypes.Add do
  begin
    if bCifrada then
    begin
      DisplayName := 'Copias cifradas';
      FileMask := '*.crypt';
    end
    else
    begin
      DisplayName := 'Archivos SQL';
      FileMask := '*.sql';
    end;
  end;
  saveDialog.FileName := 'copiaseguridad' +
    FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) +
    sExtension;
  Result := saveDialog.Execute;
  if Result then
  begin
    ARutaFichero := ChangeFileExt(
      saveDialog.FileName,
      sExtension);
    if bCifrada then
    begin
      Result := TfrmModalContrasenaCopia.SolicitarNueva(
        Self,
        AContrasena);
    end;
  end;
end;

procedure TfrmMtoPrincipal.CopiasdeSeguridad1Click(Sender: TObject);
var
  sContrasena: string;
  sRutaFichero: string;
begin
  if SolicitarDestinoCopia(
    sRutaFichero,
    sContrasena) then
  begin
    MostrarBarraProgreso;
    try
      FCancelaOperacionSolicitada := False;
      FServicioCopiasSeguridad.IniciarCopia(
        sRutaFichero,
        sContrasena,
        WorkerProgreso,
        BackupFinalizar,
        FWorkerOperacion);
    except
      OcultarBarraProgreso;
      raise;
    end;
  end;
end;

// validar iban online https://www.iban.com
// validar nif europeo https://ec.europa.eu/taxation_customs/tin/#/check-tin

procedure TfrmMtoPrincipal.PrecargarCachesSerie;
var
  swTotal: TStopwatch;
  Identidad: TIdentidadPermisos;
  IdentidadActual: TIdentidadSesion;
begin
  swTotal := TStopwatch.StartNew;
  Log.LogInfo('Arranque: PrecargarCachesSerie INICIO');
  PerfilesUsuario.PrecargarPerfilesUsuario;
  AsignarInformesGuiasCache(
    TInformesGuiasCache.Create(ConexionPrincipal));
  InformesGuiasCache.Precargar;
  FreeAndNil(oConfigCampos);
  oConfigCampos := TConfigCamposCache.Create(ConexionPrincipal);
  oConfigCampos.Precargar;
  IdentidadActual := ContextoSesion.Identidad;
  Identidad := TIdentidadPermisos.Crear(
    IdentidadActual.Usuario,
    IdentidadActual.Grupo,
    IdentidadActual.EsAdministrador);
  try
    AsignarPermisos(
      TCargadorPermisosUniDAC.Cargar(ConexionPrincipal, Identidad));
  except
    on E: Exception do
    begin
      AsignarPermisos(
        TPermisosAplicacion.CrearNoDisponible(Identidad));
      AvisarFalloCargaPermisos(E.ClassName + ': ' + E.Message);
    end;
  end;
  Log.LogInfo(
    Format('PrecargaSerie: total=%d ms', [swTotal.ElapsedMilliseconds]));
end;

function TfrmMtoPrincipal.EjecutarCargaWorker(ACarga: TProc<TUniConnection>;
                                              out AError: string): Int64;
var
  sw: TStopwatch;
  c: TUniConnection;
begin
  AError := '';
  sw := TStopwatch.StartNew;
  c := nil;
  try
    try
      if not Assigned(Conexiones) then
        raise Exception.Create(SErrorServicioConexionesNoDisponible);
      c := Conexiones.CrearConexion(
        nil,
        uctPrecarga);
      ACarga(c);
    except
      // Capturamos la excepcion en la tarea para que NO aborte el WaitForAll.
      // La cache afectada queda sin cargar y degrada sola (FCargada=False).
      on E: Exception do
        AError := E.ClassName + ': ' + E.Message;
    end;
  finally
    if c <> nil then
      FreeAndNil(c);
  end;
  Result := sw.ElapsedMilliseconds;
end;

procedure TfrmMtoPrincipal.PrecargarCachesParalelo;
var
  swTotal: TStopwatch;
  bEsAdmin: Boolean;
  Identidad: TIdentidadPermisos;
  IdentidadActual: TIdentidadSesion;
  PermisosCargados: IPermisosAplicacion;
  msPerfiles, msInfGuias, msConfig, msPermisos: Int64;
  errPerfiles, errInfGuias, errConfig, errPermisos: string;
  t1, t2, t3, t4: ITask;
begin
  swTotal := TStopwatch.StartNew;
  Log.LogInfo('Arranque: PrecargarCachesParalelo INICIO');
  IdentidadActual := ContextoSesion.Identidad;
  bEsAdmin := IdentidadActual.EsAdministrador;
  Identidad := TIdentidadPermisos.Crear(
    IdentidadActual.Usuario,
    IdentidadActual.Grupo,
    bEsAdmin);
  PermisosCargados := nil;
  msPerfiles := 0;
  msInfGuias := 0;
  msConfig := 0;
  msPermisos := 0;
  errPerfiles := '';
  errInfGuias := '';
  errConfig := '';
  errPermisos := '';
  AsignarInformesGuiasCache(
    TInformesGuiasCache.Create(ConexionPrincipal));
  FreeAndNil(oConfigCampos);
  oConfigCampos  := TConfigCamposCache.Create(ConexionPrincipal);
  // Cada tarea escribe solo en SUS variables (sin estado compartido) y captura
  // su excepcion (no se propaga al WaitForAll). El log es thread-safe (mutex).
  t1 := TTask.Run(
    procedure
    begin
      msPerfiles := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          FdmDataPerfiles.PrecargarPerfilesUsuario(c);
        end, errPerfiles);
    end);
  t2 := TTask.Run(
    procedure
    begin
      msInfGuias := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          InformesGuiasCache.Precargar(c);
        end, errInfGuias);
    end);
  t3 := TTask.Run(
    procedure
    begin
      msConfig := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          oConfigCampos.Precargar(c);
        end, errConfig);
    end);
  t4 := TTask.Run(
    procedure
    begin
      msPermisos := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          PermisosCargados :=
            TCargadorPermisosUniDAC.Cargar(c, Identidad);
        end, errPermisos);
    end);
  TTask.WaitForAll([t1, t2, t3, t4]);
  if Assigned(PermisosCargados) then
    AsignarPermisos(PermisosCargados)
  else
  begin
    AsignarPermisos(
      TPermisosAplicacion.CrearNoDisponible(Identidad));
    if errPermisos = '' then
      errPermisos := 'La carga no devolvió una caché de permisos';
  end;
  Log.LogInfo(Format('PrecargaParalela: total=%d ms || ' +
    'perfiles=%d infguias=%d config=%d permisos=%d',
    [swTotal.ElapsedMilliseconds,
     msPerfiles, msInfGuias, msConfig, msPermisos]));
  if (errPerfiles <> '') or (errInfGuias <> '') or
     (errConfig <> '') or (errPermisos <> '') then
    Log.LogError(Format('PrecargaParalela errores -> perfiles=[%s] ' +
      'infguias=[%s] config=[%s] permisos=[%s]',
      [errPerfiles, errInfGuias, errConfig, errPermisos]));
  if errPermisos <> '' then
    AvisarFalloCargaPermisos(errPermisos);
end;

procedure TfrmMtoPrincipal.AvisarFalloCargaPermisos(
  const ADetalle: string);
begin
  if not FFalloCargaPermisosAvisado then
  begin
    FFalloCargaPermisosAvisado := True;
    Log.LogError('No se pudieron cargar los permisos: ' + ADetalle);
    MessageDlg(Format(SAvisoCargaPermisosRestringidos, [GetLogFolder]),
               mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoPrincipal.AplicarPermisosMenu;
var
  i: Integer;
  // Las pantallas registradas quedan visibles y desactivadas. Los menús
  // directos de la rama "Menús no visibles" se ocultan por completo.
  function ProcesarItem(AItem: TMenuItem): Boolean;
  var
    j: Integer;
    sCall, sCodigo: string;
    bHayHijoVisible: Boolean;
  begin
    if AItem.Caption = '-' then
      Result := False
    else if AItem.Count > 0 then
    begin
      bHayHijoVisible := False;
      for j := 0 to AItem.Count - 1 do
        if ProcesarItem(AItem.Items[j]) then
          bHayHijoVisible := True;
      if not bHayHijoVisible then
      begin
        AItem.Visible := False;
        AItem.Enabled := False;
      end;
      Result := AItem.Visible;
    end
    else
    begin
      sCodigo := oFzaWinf.CodigoMenu(AItem);
      if (sCodigo <> '') and
         (not Permisos.TienePermiso(sCodigo, paPermitir)) then
      begin
        sCall := oFzaWinf.CallRegistrado(AItem);
        AItem.Enabled := False;
        if sCall <> '' then
        begin
          AItem.Visible := True;
          Log.LogInfo(Format(
            'Permiso %s denegado: menú desactivado',
            [sCodigo]));
        end
        else
        begin
          AItem.Visible := False;
          Log.LogInfo(Format(
            'Permiso %s denegado: menú oculto',
            [sCodigo]));
        end;
      end;
      Result := AItem.Visible;
    end;
  end;
begin
  if Assigned(Permisos) and (Menu <> nil) then
    for i := 0 to Menu.Items.Count - 1 do
      ProcesarItem(Menu.Items[i]);
end;

procedure TfrmMtoPrincipal.WorkerProgreso(const AEtapa: string;
                                          APaso, ATotal: Integer;
                                          AFilaGlobal,
                                          AFilasGlobalTotal: Integer);
begin
  if (FProgressBar = nil) or (not FProgressBar.Visible) then
    Exit;
  if AFilasGlobalTotal > 0 then
  begin
    FProgressBar.Max := AFilasGlobalTotal;
    FProgressBar.Position := AFilaGlobal;
  end;
  if ATotal > 0 then
    FProgressLabel.Caption :=
      Format('%s  %d / %d', [AEtapa, APaso, ATotal])
  else
    FProgressLabel.Caption := AEtapa;
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmMtoPrincipal.BackupFinalizar(AExito: Boolean;
  const AError: string; ALogBuffer: TStringList);
var
  bCancelada: Boolean;
begin
  bCancelada := (not AExito) and EsErrorCancelacion(AError);
  FWorkerOperacion := nil;
  FCancelaOperacionSolicitada := False;
  OcultarBarraProgreso;
  if bCancelada then
    ShowMessage(SOperacionCancelada)
  else if AExito then
  begin
    inLibLog.Log.LogInfo('Copia de seguridad creada exitosamente');
    ShowMessage(SInfoCopiaSeguridadGuardada);
  end
  else
  begin
    inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' + AError);
    ShowMessage(Format(SErrorCrearCopiaSeguridad, [AError]));
  end;
end;

procedure TfrmMtoPrincipal.RestoreFinalizar(AExito: Boolean;
  const AError: string; ALogBuffer: TStringList);
var
  LogForm: TfrmMtoModalScriptLog;
  bCancelada: Boolean;
begin
  bCancelada := (not AExito) and EsErrorCancelacion(AError);
  FWorkerOperacion := nil;
  FCancelaOperacionSolicitada := False;
  OcultarBarraProgreso;
  if bCancelada then
  begin
    if ALogBuffer <> nil then
      FreeAndNil(ALogBuffer);
    ShowMessage(SAvisoRestauracionCancelada);
  end
  else
  begin
    // Mostrar log de ejecución
    LogForm := TfrmMtoModalScriptLog.Create(Self);
    LogForm.LogMemo.Lines.Add('-- RESTAURACIÓN DE COPIA DE SEGURIDAD --');
    LogForm.LogMemo.Lines.Add(
      '-------------------------------------------------');
    if ALogBuffer <> nil then
    begin
      LogForm.AppendLines(ALogBuffer);
      FreeAndNil(ALogBuffer);
    end;
    LogForm.Show;
    if AExito then
      ShowMessage(SScriptEjecutado)
    else
    begin
      inLibLog.Log.LogError('Error en restauración: ' + AError);
      ShowMessage(Format(SErrorEjecutarScript, [AError]));
    end;
  end;
end;

function TfrmMtoPrincipal.EsErrorCancelacion(const AError: string): Boolean;
begin
  Result := Pos('cancelada', LowerCase(AError)) > 0;
end;

procedure TfrmMtoPrincipal.SolicitarCancelarOperacionEnCurso;
begin
  if FEnOperacionLarga then
  begin
    if FCancelaOperacionSolicitada then
      ShowMessage(SCancelacionSolicitada)
    else if MessageDlg(SPreguntaCancelarOperacion,
                       mtWarning, [mbYes, mbNo], 0) = mrYes then
    begin
      FCancelaOperacionSolicitada := True;
      if Assigned(FWorkerOperacion) then
        FWorkerOperacion.Terminate;
      if FProgressLabel <> nil then
      begin
        FProgressLabel.Caption := 'Cancelando operación...';
        FProgressLabel.Update;
      end;
    end;
  end;
end;

procedure TfrmMtoPrincipal.MostrarBarraProgreso;
begin
  FEnOperacionLarga := True;
  if FProgressLabel = nil then
  begin
    FProgressLabel := TcxLabel.Create(Self);
    FProgressLabel.Parent := pnlPPBottom;
    FProgressLabel.Align := alTop;
    FProgressLabel.AutoSize := False;
    FProgressLabel.Height := 26;
    FProgressLabel.Caption := '';
    FProgressLabel.Transparent := True;
  end;
  if FProgressBar = nil then
  begin
    FProgressBar := TProgressBar.Create(Self);
    FProgressBar.Parent := pnlPPBottom;
    FProgressBar.Align := alTop;
    FProgressBar.Height := 18;
    FProgressBar.Min := 0;
    FProgressBar.Max := 100;
    FProgressBar.Position := 0;
    FProgressBar.Smooth := True;
  end;
  FProgressLabel.Visible := True;
  FProgressBar.Visible := True;
  pnlPPBottom.Visible := True;
  FProgressBar.Position := 0;
  FProgressLabel.Caption := 'Preparando...';
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmMtoPrincipal.OcultarBarraProgreso;
begin
  FEnOperacionLarga := False;
  if FProgressBar <> nil then
    FProgressBar.Visible := False;
  if FProgressLabel <> nil then
    FProgressLabel.Visible := False;
  pnlPPBottom.Visible := False;
end;

function TfrmMtoPrincipal.CrearCopiaPreviaScript: Boolean;
var
  sContrasena: string;
  sError: string;
  sRutaFichero: string;
begin
  Result := SolicitarDestinoCopia(
    sRutaFichero,
    sContrasena);
  if Result then
  begin
    MostrarBarraProgreso;
    try
      Result := FServicioCopiasSeguridad.CrearCopia(
        sRutaFichero,
        sContrasena,
        WorkerProgreso,
        sError);
      if Result then
      begin
        inLibLog.Log.LogInfo('Copia de seguridad creada en ' +
          sRutaFichero);
        ShowMessage(SInfoCopiaSeguridadGuardada);
      end
      else
      begin
        inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' +
                              sError);
        ShowMessage(Format(SErrorCrearCopiaSeguridad, [sError]));
      end;
    finally
      OcultarBarraProgreso;
    end;
  end;
end;

procedure TfrmMtoPrincipal.FormActivate(Sender: TObject);
begin
  inherited;
  // FormPaint(Sender);
end;

procedure TfrmMtoPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
var
  GestorContexto: IGestorContextoSesion;
begin
  // Señalar a las tareas de segundo plano que la app se esta cerrando, ANTES
  // de empezar a liberar formularios y conexiones. Asi no arrancan trabajo
  // nuevo ni tocan formularios en destruccion
  // (ver inMtoGen.EjecutarEnBackground
  // y el destructor de TfrmMtoGen).
  if Supports(
    ContextoSesion,
    IGestorContextoSesion,
    GestorContexto
  ) then
    GestorContexto.MarcarCierreAplicacion;
  RegistrarEventoFiscalSeguro(ParametrosApp,
    ConexionPrincipal,
    IdentidadSesion.Usuario,
    cEventoNoVerifactuFin,
    'Cierre del sistema');
  // Parar el hilo de la cola Verifactu antes de liberar las conexiones
  TVentasWsCola.DetenerHilo;
  TVerifactuCola.DetenerHilo;
  if Assigned(FAppEvents) then
  begin
    FAppEvents.OnException := nil;
    FAppEvents.OnMessage := nil;
  end;
  FGestorExcepciones := nil;
  inherited;
  try
    inLibLog.Log.LogInfo('Cerrando ventana principal');
    tmr1.Enabled := False;
    if Assigned(FormManager) then
    try
      FormManager.CloseAll;
    except
      on E: Exception do inLibLog.Log.LogError('Error en CloseAll: ' +
                                                                     E.Message);
    end;
    FreeAndNil(oFzaWinf);
    oFotos.LiberarServicios;
    if Assigned(FDmConn) then
      FDmConn.AsignarParametrosApp(nil);
    AsignarTraducciones(nil);
    AsignarParametros(nil, nil);
    FParametrosAppEdicion := nil;
    FParametrosCajaEdicion := nil;
    DesvincularPerfilesStockConsulta;
    AsignarPerfilesUsuario(nil);
    if (FdmDataPerfiles <> nil) then
      FreeAndNil(FdmDataPerfiles);
    AsignarFiltrosGuardados(nil);
    if (FdmDataFiltros <> nil) then
      FreeAndNil(FdmDataFiltros);
    AsignarAuditoriaDatos(nil);
    if Assigned(MonitorSQL) then
    begin
      MonitorSQL.CerrarPendiente;
      MonitorSQL.EstablecerActivo(False);
      MonitorSQL.Invalidar;
    end;
    if Assigned(FDmConn) then
      FDmConn.AsignarReceptorMonitorSQL(nil);
    inLibLog.Log.AsignarMonitorSQL(nil);
    AsignarMonitorSQL(nil);
    if Assigned(Conexiones) then
      Conexiones.Invalidar;
    AsignarConexiones(nil);
    // Caches de la sesión: liberarlas evita la fuga en re-login.
    AsignarInformesGuiasCache(nil);
    FreeAndNil(oConfigCampos);
    FreeAndNil(FDmConn);
  finally
    inLibLog.Log.LogInfo('Ventana principal Cerrada');
    Action := caFree;
  end;
end;

procedure TfrmMtoPrincipal.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  inherited;
  if FEnOperacionLarga then
  begin
    CanClose := False;
    SolicitarCancelarOperacionEnCurso;
  end
  // Cierre por reinicio de sesion ('Invocar login'): no preguntar.
  else if (FReiniciando) then
    CanClose := True
  else if (pcPrincipal.PageCount = 0) then
  begin
    if MessageDlg(SPreguntaSalirAplicacion,
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      CanClose := False; // Cancela el cierre
    end
    else
    begin
      CanClose := True;  // Permite el cierre
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmMtoPrincipal.FormShow(Sender: TObject);
begin
  if FException then
  begin
    PostMessage(Handle, wm_Close, 0, 0);
    Exit;
  end;
  // Defensivo: tras todo el init de FormCreate, garantizamos que el logo
  // este encima de pcPrincipal (z-order) y que ActualizarFondoLogo haya
  // decidido visibilidad ya con el form fisicamente visible en pantalla.
  // Si CargarFondoLogo no encontro el png, esto es no-op (Picture.Graphic
  // sigue nil y ActualizarFondoLogo deja Visible=False).
  imgFondoLogo.BringToFront;
  ActualizarFondoLogo;
end;

procedure TfrmMtoPrincipal.AppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  // Solo pulsaciones de tecla y descartando la autorrepeticion (bit 30).
  if (Msg.message = WM_KEYDOWN) and ((Msg.lParam and $40000000) = 0) then
  begin
    // F9: abrir el cajon portamonedas desde cualquier ventana del programa
    // (caja, mantenimientos o el propio principal) si hay impresora de
    // tickets asignada. Sin impresora solo responde con la sesion de caja
    // abierta (frmMtoMenuCaja vivo), para avisar de la falta de
    // configuracion. F9 sola, sin Ctrl/Alt/Mayus.
    if (Msg.wParam = WPARAM(VK_ESCAPE)) and FEnOperacionLarga then
    begin
      SolicitarCancelarOperacionEnCurso;
      Handled := True;
    end
    else if (Msg.wParam = WPARAM(VK_ESCAPE)) and
            (Application.ModalLevel > 0) and
            Assigned(Screen.ActiveForm) and
            (Screen.ActiveForm <> Self) then
    begin
      Screen.ActiveForm.Close;
      Handled := True;
    end
    else if (Msg.wParam = WPARAM(VK_F9)) and
       (ImpresoraCajaAsignada(ParametrosCaja) or
        Assigned(frmMtoMenuCaja)) and
       (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
       (GetKeyState(VK_SHIFT) >= 0) then
    begin
      AbrirCajonSinVenta(Permisos, ParametrosCaja);
      Handled := True;
    end
    // Ctrl+E: consulta de articulos similares desde cualquier ventana.
    else if (Msg.wParam = WPARAM(Ord('E'))) and
             (GetKeyState(VK_CONTROL) < 0) and
             (GetKeyState(VK_MENU) >= 0) and
             (GetKeyState(VK_SHIFT) >= 0) then
    begin
      mnuArticulosSimilaresClick(Self);
      Handled := True;
    end
    // Ctrl+U: consulta de stock global, precargando el articulo en foco.
    else if (Msg.wParam = WPARAM(Ord('U'))) and
             (GetKeyState(VK_CONTROL) < 0) and
             (GetKeyState(VK_MENU) >= 0) and (GetKeyState(VK_SHIFT) >= 0) then
    begin
      mnuConsultaStocksClick(Self);
      Handled := True;
    end;
  end;
end;

function TfrmMtoPrincipal.IsShortCut(var Message: TWMKey): Boolean;
var
  Component: TComponent;
  ActiveForm: TCustomForm;
  ts: TcxTabSheet;
  I: Integer;
  iPageActive: Integer;
  bFound: Boolean;
begin
  // F9 sola (sin Ctrl/Alt/Mayus ni autorrepeticion) -> abrir el cajon
  // portamonedas, mismo criterio que AppMessage. Via redundante: cubre el
  // foco en el principal y sus pestañas embebidas aunque Application.OnMessage
  // quede desenganchado; si AppMessage ya trato la tecla, el mensaje no se
  // despacha y este punto no llega a ejecutarse (no hay doble apertura).
  if (Message.CharCode = VK_F9) and
     (HiWord(Message.KeyData) and KF_REPEAT = 0) and
     (ImpresoraCajaAsignada(ParametrosCaja) or
      Assigned(frmMtoMenuCaja)) and
     (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
     (GetKeyState(VK_SHIFT) >= 0) then
  begin
    AbrirCajonSinVenta(Permisos, ParametrosCaja);
    Result := True;
    Exit;
  end;
  // Alt+F4 -> cerrar aplicacion
  if (Message.CharCode = VK_F4)
     and (HiWord(Message.KeyData) and KF_ALTDOWN <> 0) then
  begin
    Self.Close;
    Result := True;
    Exit;
  end;
  // Ctrl+F4 -> cerrar pestaña activa o ventana flotante
  if (Message.CharCode = VK_F4)
     and (GetKeyState(VK_CONTROL) < 0)
     and (HiWord(Message.KeyData) and KF_ALTDOWN = 0) then
  begin
    // Ventana flotante (no modal): cerrarla
    if Assigned(Screen.ActiveForm) and
       (Screen.ActiveForm <> Self) and
       (Screen.ActiveForm.Parent = nil) then
    begin
      Screen.ActiveForm.Close;
      Result := True;
      Exit;
    end;
    // Pestaña embebida
    if (pcPrincipal.PageCount > 0) then
      FormManager.CloseActiveForm;
    Result := True;
    Exit;
  end;
  // ESC -> cerrar pestaña activa o salir
  if (Message.CharCode = VK_ESCAPE) then
  begin
    if Application.ModalLevel > 0 then
    begin
      Result := inherited IsShortCut(Message);
      Exit;
    end;
    if Assigned(Screen.ActiveForm) and
       (Screen.ActiveForm <> Self) and
       (Screen.ActiveForm.Parent = nil) then
    begin
      Result := inherited IsShortCut(Message);
      Exit;
    end;
    if (pcPrincipal.PageCount = 0) then
    begin
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
      Result := True;
      Exit;
    end
    else
    begin
      FormManager.CloseActiveForm;
      Result := True;
      Exit;
    end;
  end;
  // Ventana no embebida (modal top-level) -> delegar a sus ActionLists
  ActiveForm := Screen.ActiveForm;
  if Assigned(ActiveForm) and
     (ActiveForm <> Self) and
     (ActiveForm.Parent = nil) then
  begin
    Result := False;
    for I := 0 to ActiveForm.ComponentCount - 1 do
    begin
      Component := ActiveForm.Components[I];
      if Component is TActionList then
      begin
        if TActionList(Component).IsShortCut(Message) then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
    Exit;
  end;
  // Enrutar a los TActionList del formulario hijo en la pestaña activa.
  // Recorre TODOS los ActionList del hijo (base + propios del Mto).
  bFound := False;
  if (Self.pcPrincipal.PageCount > 0) then
  begin
    iPageActive := pcPrincipal.ActivePageIndex;
    if (iPageActive >= 0) then
    begin
      ts := (Self.pcPrincipal.Pages[iPageActive] as TcxTabSheet);
      if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
      begin
        for I := 0 to (ts.Controls[0] as TForm).ComponentCount - 1 do
        begin
          Component := (ts.Controls[0] as TForm).Components[I];
          if (Component is TActionList) then
          begin
            if TActionList(Component).IsShortCut(Message) then
            begin
              bFound := True;
              Break;
            end;
          end;
        end;
      end;
    end;
  end;
  if bFound then
    Result := True
  else
    Result := inherited IsShortCut(Message);
end;

function TfrmMtoPrincipal.SolicitarOrigenRestauracion(
  out ARutaFichero, AContrasena: string): Boolean;
var
  bEsAdministrador: Boolean;
begin
  ARutaFichero := '';
  AContrasena := '';
  bEsAdministrador := FServicioCopiasSeguridad.ModoCreacion =
    mpcTextoPlano;
  openDialog.Title := 'Restaurar copia o ejecutar script';
  openDialog.FileTypes.Clear;
  with openDialog.FileTypes.Add do
  begin
    if bEsAdministrador then
    begin
      DisplayName := 'Copias SQL o cifradas';
      FileMask := '*.sql;*.crypt';
    end
    else
    begin
      DisplayName := 'Copias o scripts cifrados';
      FileMask := '*.crypt';
    end;
  end;
  if bEsAdministrador then
    openDialog.DefaultExtension := 'sql'
  else
    openDialog.DefaultExtension := 'crypt';
  openDialog.DefaultFolder := ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  openDialog.Options := openDialog.Options +
    [fdoStrictFileTypes, fdoFileMustExist];
  Result := openDialog.Execute;
  if Result then
  begin
    ARutaFichero := openDialog.FileName;
    Result := FServicioCopiasSeguridad.PuedeRestaurar(
      ARutaFichero);
    if not Result then
      ShowMessage(SErrorTipoRestauracionNoPermitido)
    else if FServicioCopiasSeguridad.RequiereContrasena(
      ARutaFichero) then
    begin
      Result := TfrmModalContrasenaCopia.SolicitarExistente(
        Self,
        AContrasena);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
var
  aBytes: TBytes;
  bCifrada: Boolean;
  bContinuar: Boolean;
  bRequiereCopia: Boolean;
  iRespuesta: Integer;
  iBytesALeer: Int64;
  oFichero: TFileStream;
  sContrasena: string;
  sPreguntaCopia: string;
  sRutaFichero: string;
  sSqlTexto: string;
begin
  if mnuEjecutarScript.Visible then
  begin
    bContinuar := SolicitarOrigenRestauracion(
      sRutaFichero,
      sContrasena);
    if bContinuar then
    begin
      bCifrada := FServicioCopiasSeguridad.RequiereContrasena(
        sRutaFichero);
      bRequiereCopia := bCifrada;
      sPreguntaCopia := SPreguntaCopiaAntesRestaurarCifrada;
      if not bCifrada then
      begin
        oFichero := TFileStream.Create(
          sRutaFichero,
          fmOpenRead or fmShareDenyNone);
        try
          iBytesALeer := oFichero.Size;
          if iBytesALeer > 65536 then
            iBytesALeer := 65536;
          SetLength(aBytes, iBytesALeer);
          oFichero.ReadBuffer(
            aBytes,
            iBytesALeer);
          sSqlTexto := TEncoding.UTF8.GetString(aBytes);
        finally
          FreeAndNil(oFichero);
        end;
        bRequiereCopia := ContieneDDL(sSqlTexto);
        sPreguntaCopia := SPreguntaCopiaSeguridadAntesDDL;
      end;
      if bRequiereCopia then
      begin
        iRespuesta := MessageDlg(
          sPreguntaCopia,
          mtWarning,
          [mbYes, mbNo, mbCancel],
          0);
        case iRespuesta of
          mrYes:
            bContinuar := CrearCopiaPreviaScript;
          mrCancel:
            bContinuar := False;
        end;
        if not bContinuar then
          ShowMessage(SInfoScriptCancelado);
      end;
      if bContinuar then
      begin
        MostrarBarraProgreso;
        try
          FCancelaOperacionSolicitada := False;
          FServicioCopiasSeguridad.IniciarRestauracion(
            sRutaFichero,
            sContrasena,
            WorkerProgreso,
            RestoreFinalizar,
            FWorkerOperacion);
        except
          OcultarBarraProgreso;
          raise;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoPrincipal.tmr1Timer(Sender: TObject);
var
  ADateStr          : string;
  ATimeStr          : string;
begin
  bIsConnected := False;
  ADateStr := DateToStr(Now);
  ATimeStr := FormatDateTime('hh:mm', Now);
  if FDmConn <> nil then
    if FDmConn.conUni.Connected then
    begin
      bIsConnected := True;
      jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + ' Conn';
    end
    else
      bIsConnected := False;
  if (FDmConn = nil) or (not bIsConnected) then
  begin
    jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + 'NO Conn';
    inLibLog.Log.LogError('Se ha perdido la conexión con la BBDD');
  end;

end;

procedure TfrmMtoPrincipal.WMFreeControl(var Msg: TMessage);
var
  TabACerrar: TcxTabSheet;
begin
  TabACerrar := TcxTabSheet(Msg.LParam);
  if FormManager <> nil then
  begin
    FormManager.CloseFormByCaption(TabACerrar.Caption);
  end
  else
  begin
    FreeAndNil(TabACerrar);
  end;
end;

procedure TfrmMtoPrincipal.mnuLisVentasClick(Sender: TObject);
var
  frmListadoVentas: TfrmModalListadoVentas;
begin
  inherited;
  try
    frmListadoVentas := TfrmModalListadoVentas.Create(Self);
    frmListadoVentas.ShowModal;
  finally
    FreeAndNil(frmListadoVentas);
  end;
end;

procedure TfrmMtoPrincipal.mnuListadoDocsProveedorClick(Sender: TObject);
var
  frmListadoDocsProveedor: TfrmPrintDocsProveedor;
begin
  inherited;
  try
    frmListadoDocsProveedor := TfrmPrintDocsProveedor.Create(Self);
    frmListadoDocsProveedor.ShowModal;
  finally
    FreeAndNil(frmListadoDocsProveedor);
  end;
end;

procedure TfrmMtoPrincipal.mnuListadoEfectosPagoClick(Sender: TObject);
var
  frmListadoEfectosPago: TfrmPrintEfectosPago;
begin
  inherited;
  try
    frmListadoEfectosPago := TfrmPrintEfectosPago.Create(Self);
    frmListadoEfectosPago.ShowModal;
  finally
    FreeAndNil(frmListadoEfectosPago);
  end;
end;

procedure TfrmMtoPrincipal.mnuMenuCajaClick(Sender: TObject);
begin
  inherited;
  if not mnuMenuCaja.Visible then Exit;
  if Assigned(frmMtoMenuCaja) then
  begin
    if frmMtoMenuCaja.WindowState = wsMinimized then
      frmMtoMenuCaja.WindowState := wsNormal;
    frmMtoMenuCaja.BringToFront;
  end
  else
  begin
    frmMtoMenuCaja := TfrmMtoMenuCaja.Create(Application, Permisos);
    frmMtoMenuCaja.Show;
  end;
  Self.WindowState := wsMinimized;
end;

procedure TfrmMtoPrincipal.AbrirUrlAyuda(const AUrl: string);
var
  Resultado: HINST;
begin
  Resultado := ShellExecute(0,
                            'open',
                            PChar(AUrl),
                            nil,
                            nil,
                            SW_SHOWNORMAL);
  if Resultado <= 32 then
    ShowMessage(Format(SErrorAbrirDireccion, [AUrl]));
end;

procedure TfrmMtoPrincipal.mnuAcercadeClick(Sender: TObject);
var
  frmSplash: TfrmSplash;
begin
  inherited;
  try
    frmSplash := TfrmSplash.Create(Self);
    frmSplash.ShowModal;
  finally
    FreeAndNil(frmSplash);
  end;
end;

procedure TfrmMtoPrincipal.mnuForoSoporteClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(URL_FORO_SOPORTE);
end;

procedure TfrmMtoPrincipal.mnuConsultaStocksClick(Sender: TObject);
var
  LForm: TForm;
  ts: TcxTabSheet;
  sArt, sSku: string;
begin
  if mnuConsultaStocks.Enabled then
  begin
    // Si el principal esta activo, el form logico es el de la pestaña activa.
    LForm := Screen.ActiveForm;
    if (LForm = Self) and (pcPrincipal.PageCount > 0) and
       (pcPrincipal.ActivePageIndex >= 0) then
    begin
      ts := pcPrincipal.Pages[pcPrincipal.ActivePageIndex] as TcxTabSheet;
      if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
      begin
        LForm := TForm(ts.Controls[0]);
      end;
    end;
    sArt := '';
    sSku := '';
    if LForm is TfrmBase then
    begin
      TfrmBase(LForm).ResolverArtSkuStock(sArt, sSku);
    end;
    MostrarStockConsulta(sArt, sSku);
  end;
end;

procedure TfrmMtoPrincipal.mnuArticulosSimilaresClick(Sender: TObject);
var
  LForm: TForm;
begin
  if mnuArticulosSimilares.Enabled then
  begin
    LForm := Screen.ActiveForm;
    if not (LForm is TfrmMtoBusquedaDatos) then
    begin
      TfrmMtoBusquedaDatos.Ejecutar(Self, LForm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuManualWebClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(URL_MANUAL_WEB);
end;

procedure TfrmMtoPrincipal.MenuGenericoClick(Sender: TObject);
var
  oItem: TMenuItem;
  sCall: string;
begin
  if (Sender is TMenuItem) then
  begin
    oItem := TMenuItem(Sender);
    // Mismo guardado que los handlers viejos: solo abre si el item
    // esta visible (permisos de menu ya aplicados).
    if oItem.Visible then
    begin
      sCall := oFzaWinf.CallRegistrado(oItem);
      if sCall <> '' then
        ShowMto(Self, sCall);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuCajaParamClick(Sender: TObject);
var
  frmMtoCajaParam: TfrmMtoCajaParam;
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    try
      frmMtoCajaParam := TfrmMtoCajaParam.Create(Self);
      frmMtoCajaParam.ShowModal;
    finally
      FreeAndNil(frmMtoCajaParam);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuListadoOperacionesVentaClick(
  Sender: TObject);
var
  frmListado: TfrmPrintOperacionesVenta;
begin
  inherited;
  if mnuListadoOperacionesVenta.Visible then
  begin
    frmListado := TfrmPrintOperacionesVenta.Create(Self);
    try
      frmListado.ShowModal;
    finally
      FreeAndNil(frmListado);
    end;
  end;
end;

procedure TfrmMtoPrincipal.CargarEfectosVenta1Click(Sender: TObject);
var
  f: TfrmModalCargarEfectosRemesa;
begin
  inherited;
  if CargarEfectosVenta1.Visible then
  begin
    f := TfrmModalCargarEfectosRemesa.CrearParaVenta(nil);
    try
      if f.ShowModal = mrOk then
        ShowMto(Self, 'RemesasVenta');
    finally
      f.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.Sesiones1Click(Sender: TObject);
begin
  inherited;
  if mnuCrearArtculosyunpedidoounalbarn.Visible then
    ShowMto(Self, 'ComprasSesiones');
end;

procedure TfrmMtoPrincipal.FacturarAlbaranes1Click(Sender: TObject);
var
  f: TfrmModalFacturarAlbaranes;
begin
  inherited;
  if FacturarAlbaranes1.Visible then
  begin
    f := TfrmModalFacturarAlbaranes.Create(nil);
    try
      if f.ShowModal = mrOk then
        ShowMto(Self, 'FacturasCompra');
    finally
      f.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.CargarEfectos1Click(Sender: TObject);
var
  f: TfrmModalCargarEfectosRemesa;
begin
  inherited;
  if CargarEfectos1.Visible then
  begin
    f := TfrmModalCargarEfectosRemesa.CrearParaCompra(nil);
    try
      if f.ShowModal = mrOk then
        ShowMto(Self, 'RemesasCompra');
    finally
      f.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.Formasdepago2Click(Sender: TObject);
begin
  inherited;
  if Formasdepago2.Visible then
    ShowMto(Self, 'FormasdePago');
end;

procedure TfrmMtoPrincipal.mnuInvocarLoginClick(Sender: TObject);
begin
  // Cerrar sesion: relanza Fzam con el conmutador /relogin (que ignora el
  // auto-login y la contrasena recordada para forzar la reidentificacion)
  // y cierra esta instancia.
  FReiniciando := True;
  ShellExecute(0,
               'open',
               PChar(Application.ExeName),
               PChar('/relogin'),
               nil,
               SW_SHOWNORMAL);
  Close;
end;

procedure TfrmMtoPrincipal.mnuParmetrosdeEntornoClick(Sender: TObject);
var
    frmMtoAppParam: TfrmMtoAppParam;
begin
  inherited;
  try
    frmMtoAppParam := TfrmMtoAppParam.Create(Self);
    frmMtoAppParam.ShowModal;
  finally
    FreeAndNil(frmMtoAppParam);
  end;
end;

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVerifactuDeclaracionClick(Sender: TObject);
begin
  if (mnuVerifactuDeclaracion.Visible) then
    TfrmModalVerifactuDecl.Ejecutar(Self);
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenHorizontalClick(Sender: TObject);
var
  frm: TfrmPrintBalanceTallas;
begin
  // Informe A4 horizontal (FastReport) del balance de almacén por tallas
  // con foto. El usuario filtra modo (entre fechas / acumulados), nivel de
  // detalle, fechas, almacén y familia en el propio modal.
  if mnuBalanceAlmacenHorizontal.Visible then
  begin
    frm := TfrmPrintBalanceTallas.Create(Application);
    try
      frm.ShowModal;
    finally
      FreeAndNil(frm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenSinTallasClick(Sender: TObject);
var
  frm: TfrmPrintBalanceSinTallas;
begin
  // Informe vertical (FastReport) del balance de almacén SIN tallas: una fila
  // por (artículo, color, banda). Incluye todos los artículos, también los no
  // tallables que el informe horizontal deja fuera. Mismos filtros, modos,
  // bandas y agrupaciones.
  if mnuBalanceAlmacenSinTallas.Visible then
  begin
    frm := TfrmPrintBalanceSinTallas.Create(Application);
    try
      frm.ShowModal;
    finally
      FreeAndNil(frm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuMovVentasArtClick(Sender: TObject);
var
  frm: TfrmPrintMovVentasArt;
begin
  // Informe A4 horizontal (FastReport) del ranking de ventas por artículos y
  // fechas: una fila por artículo (o por artículo+almacén si se agrupa por
  // almacén) con las magnitudes de compra/venta del periodo y dos márgenes.
  // Mismos filtros que el balance más la fecha "Inicio compras".
  if mnuMovVentasArt.Visible then
  begin
    frm := TfrmPrintMovVentasArt.Create(Application);
    try
      frm.ShowModal;
    finally
      FreeAndNil(frm);
    end;
  end;
end;

// Foto flotante transversal: cuando el usuario cambia de pestana
// (=Mto activo), si la pantalla flotante ya esta abierta la
// re-vincula al nuevo Mto. Si no esta abierta no hacemos nada: el
// usuario la abre manualmente con Ctrl+F cuando quiera.
procedure TfrmMtoPrincipal.pcPrincipalChange(Sender: TObject);
var
  ts: TcxTabSheet;
begin
  ActualizarFondoLogo;
  if pcPrincipal.ActivePageIndex < 0 then
  begin
    if Assigned(frmFotoArticulo) and frmFotoArticulo.Visible then
    begin
      frmFotoArticulo.VincularDataSources([], nil);
      frmFotoArticulo.SetArticuloSku('', '');
    end;
    Exit;
  end;
  ts := pcPrincipal.Pages[pcPrincipal.ActivePageIndex] as TcxTabSheet;
  if (ts.ControlCount = 0) or not (ts.Controls[0] is TfrmMtoGen) then
  begin
    if Assigned(frmFotoArticulo) and frmFotoArticulo.Visible then
      frmFotoArticulo.VincularDataSources([], nil);
    Exit;
  end;
  EngancharFotoAlMto(ts.Controls[0]);
end;

// --- IAnfitrionPantallas -------------------------------------------
function TfrmMtoPrincipal.GestorVentanas: TEmbeddedFormManager;
begin
  if FormManager = nil then
    FormManager := TEmbeddedFormManager.Create(pcPrincipal);
  Result := FormManager;
end;

function TfrmMtoPrincipal.RegistroPantallas: TfzaWinF;
begin
  Result := oFzaWinf;
end;

function TfrmMtoPrincipal.ResolverCallPantalla(
  const AUnidadClase: string): string;
begin
  Result := oFzaWinf.CallDeUnit(AUnidadClase);
end;

function TfrmMtoPrincipal.ResolverDataModulePantalla(
  const AUnidadClase: string): string;
begin
  Result := oFzaWinf.GetDataModuleName(AUnidadClase);
end;

procedure TfrmMtoPrincipal.CancelarEdicionesPantallas;
begin
  CancelarGrids(pcPrincipal);
end;

procedure TfrmMtoPrincipal.VincularFotoMantenimiento(
  AMantenimiento: TObject);
begin
  EngancharFotoAlMto(AMantenimiento);
end;

function TfrmMtoPrincipal.MenuAplicacion: TMainMenu;
begin
  Result := Menu;
end;

function TfrmMtoPrincipal.CrearOperacionCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IOperacionCaja;
var
  oFormulario: TfrmMtoOpeCaja;
begin
  oFormulario := TfrmMtoOpeCaja.Create(AOwner, APermisos);
  if not Supports(oFormulario, IOperacionCaja, Result) then
  begin
    FreeAndNil(oFormulario);
    raise EInvalidCast.Create(
      'La ventana de operación no implementa IOperacionCaja.');
  end;
end;

function TfrmMtoPrincipal.CrearConsultaOperacionesCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
var
  oFormulario: TfrmConsultaOpe;
begin
  oFormulario := TfrmConsultaOpe.Create(AOwner, APermisos);
  if not Supports(oFormulario, IConsultaOperacionesCaja, Result) then
  begin
    FreeAndNil(oFormulario);
    raise EInvalidCast.Create(
      'La ventana de consulta no implementa IConsultaOperacionesCaja.');
  end;
end;

// Restaurar la ventana principal y apartar el menu de caja antes de
// abrir una pantalla de gestion (antes lo hacia inLibShowMto tocando
// este form directamente).
procedure TfrmMtoPrincipal.PrepararAperturaPantalla;
var
  iForm: Integer;
begin
  if WindowState = wsMinimized then
    WindowState := wsMaximized;
  for iForm := 0 to Screen.FormCount - 1 do
  begin
    if (Screen.Forms[iForm].ClassName = 'TfrmMtoMenuCaja') and
       (Screen.Forms[iForm].WindowState <> wsMinimized) then
      Screen.Forms[iForm].WindowState := wsMinimized;
  end;
end;

procedure TfrmMtoPrincipal.EngancharFotoAlMto(AMto: TObject);
var
  frmActivo : TfrmMtoGen;
  sArt, sSku: string;
begin
  // Solo re-vincula si la flotante YA esta abierta (el usuario la
  // abrio con Ctrl+F en algun Mto y al cambiar a otro queremos
  // que siga el contexto). NO la abrimos automaticamente: el usuario
  // decide cuando aparece.
  if not Assigned(frmFotoArticulo) then Exit;
  if not frmFotoArticulo.Visible then Exit;
  if not (AMto is TfrmMtoGen) then Exit;
  frmActivo := TfrmMtoGen(AMto);
  frmActivo.ResolverArtSkuActivo(sArt, sSku);
  frmFotoArticulo.VincularDataSources(frmActivo.DataSourcesParaFoto,
                                      frmActivo.ResolverArtSkuActivo);
  frmFotoArticulo.SetArticuloSku(sArt, sSku);
end;

// Reenvío compatible con TApplicationEvents.OnException.
procedure TfrmMtoPrincipal.AppException(Sender: TObject; E: Exception);
begin
  FGestorExcepciones.Gestionar(Sender, E);
end;

end.
