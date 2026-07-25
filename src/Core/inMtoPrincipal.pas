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
  inLibContextoSesionIntf, inLibParametrosIntf;

const
  WM_FREECONTROL = WM_USER;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(
    TfrmBase,
    IProveedorParametrosEdicion
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
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuAlmacenesClick(Sender: TObject);
    procedure mnuInvocarLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure mnuParmetrosdeEntornoClick(Sender: TObject);
    procedure mnuInventariosClick(Sender: TObject);
    procedure mnuDocumentosTrabajoClick(Sender: TObject);
    procedure mnuPropiedadesClick(Sender: TObject);
//    procedure mnuPropiedadesValoresClick(Sender: TObject);
    procedure mnuVariacionesClick(Sender: TObject);
    procedure mnuAtributosConjuntosClick(Sender: TObject);
    procedure mnuAtributosBasicosClick(Sender: TObject);
    procedure mnuCajaPagosHistClick(Sender: TObject);
    procedure mnuCajaValesHistClick(Sender: TObject);
    procedure mnuCajaOperacionesHistClick(Sender: TObject);
    procedure mnuCajaArqueosHistClick(Sender: TObject);
    procedure FormasdePagoCaja1Click(Sender: TObject);
    procedure mnuFacturasSimplifClick(Sender: TObject);
    procedure mnuVerifactuDeclaracionClick(Sender: TObject);
    procedure mnuVerifactuColaClick(Sender: TObject);
    procedure mnuVerifactuLogClick(Sender: TObject);
    procedure Movimientosdealmacn1Click(Sender: TObject);
    procedure mnuBalanceAlmacenHorizontalClick(Sender: TObject);
    procedure mnuBalanceAlmacenSinTallasClick(Sender: TObject);
    procedure mnuMovVentasArtClick(Sender: TObject);
    procedure mnuListadoDocsProveedorClick(Sender: TObject);
    procedure mnuListadoEfectosPagoClick(Sender: TObject);
    procedure mnuDepositosClienteClick(Sender: TObject);
    procedure pcPrincipalChange(Sender: TObject);
  public
    // Re-vincula la pantalla flotante de fotos (si esta abierta) al
    // Mto recibido y refresca el articulo / SKU activo. NO la abre
    // automaticamente: para abrirla el usuario debe pulsar Ctrl+F
    // en el Mto activo. Llamado desde pcPrincipalChange (cambio de
    // pestana) y desde TfrmMtoGen.FormShow para mantener el contexto.
    procedure EngancharFotoAlMto(AMto: TObject);
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
    procedure mnuPedidosVentaClick(Sender: TObject);
    procedure mnuAlbaranesVentaClick(Sender: TObject);
    procedure EfectosVenta1Click(Sender: TObject);
    procedure RemesasVenta1Click(Sender: TObject);
    procedure CargarEfectosVenta1Click(Sender: TObject);
    procedure Sesiones1Click(Sender: TObject);
    procedure Albaranes1Click(Sender: TObject);
    procedure Devoluciones1Click(Sender: TObject);
    procedure FacturarAlbaranes1Click(Sender: TObject);
    procedure Facturas1Click(Sender: TObject);
    procedure EfectosCompra1Click(Sender: TObject);
    procedure RemesasCompra1Click(Sender: TObject);
    procedure CargarEfectos1Click(Sender: TObject);
    procedure Formasdepago2Click(Sender: TObject);
    procedure Pedidos1Click(Sender: TObject);
    procedure mnuEmpresasClick(Sender: TObject);
    procedure mnuClientesClick(Sender: TObject);
    procedure mnuProveedoresClick(Sender: TObject);
    procedure mnuArticulosClick(Sender: TObject);
    procedure mnuTarifasClick(Sender: TObject);
    procedure mnuFamiliasClick(Sender: TObject);
    procedure mnArchivoSalirClick(Sender: TObject);
    procedure mnuFacturasClick(Sender: TObject);
    procedure mnuGruposdeIVAClick(Sender: TObject);
    procedure mnuIvasClick(Sender: TObject);
    procedure mnuContadoresClick(Sender: TObject);
    procedure mnuUsuariosClick(Sender: TObject);
    procedure mnuEmpleadosClick(Sender: TObject);
    procedure mnuGruposClick(Sender: TObject);
    procedure mnuPerfilesClick(Sender: TObject);
    procedure mnuPermisosClick(Sender: TObject);
    procedure mnuPermisosTablaClick(Sender: TObject);
    procedure CopiasdeSeguridad1Click(Sender: TObject);
    procedure mnuEjecutarScriptClick(Sender: TObject);
    procedure mnuGeneradorProcesosClick(Sender: TObject);
    procedure mnuPaisesClick(Sender: TObject);
    procedure mnuUnidadesMedidaClick(Sender: TObject);
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
    procedure WMFreeControl(var Msg: TMessage); message WM_USER + 1;
  private
    FException: Boolean;
    FSavedNCMValid: Boolean;
    FExceptionDialogMemo: TcxMemo;
    FEnOperacionLarga: Boolean;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    FWorkerOperacion: TThread;
    FReiniciando: Boolean;
    FCancelaOperacionSolicitada: Boolean;
    FFalloCargaPermisosAvisado: Boolean;
    FParametrosAppEdicion: IParametrosEdicion;
    FParametrosCajaEdicion: IParametrosEdicion;
    // Handlers de aplicacion (OnException/OnIdle/OnMessage) registrados via
    // TApplicationEvents: una asignacion directa Application.OnX queda
    // anulada en cuanto cualquier form crea su propio TApplicationEvents
    // (multicaster de la VCL), p.ej. el generador de procesos.
    FAppEvents: TApplicationEvents;
    procedure AbrirUrlAyuda(const AUrl: string);
    procedure AplicarTituloVentana;
    procedure AppException(Sender: TObject; E: Exception);
    function ConstruirDetalleException(Sender: TObject; E: Exception): string;
    procedure MostrarDetalleExcepcion(const ATexto: string);
    procedure CopiarExceptionDialogClick(Sender: TObject);
    procedure AplicarPermisosMenu;
    procedure AvisarFalloCargaPermisos(const ADetalle: string);
    // Precarga de caches de arranque. El modo (serie / paralelo) lo decide
    // el parametro appArranqueEnParalelo.
    procedure PrecargarCachesSerie;
    procedure PrecargarCachesParalelo;
    function EjecutarCargaWorker(ACarga: TProc<TUniConnection>;
                                 out AError: string): Int64;
    function CopiaSeguridad: Boolean;
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
      const AContextoSesion: IContextoSesionAplicacion);
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
  inLibShowMto,
  inLibtb,
  inLibGlobalVar,
  inLibInformesGuiasCache,
  inLibConfigCampos,
  inLibPermisos,
  inLibPermisosIntf,
  inLibPermisosUniDAC,
  inLibConexionesIntf,
  inLibConexionesUniDAC,
  inLibAuditoriaDatosIntf,
  inLibAuditoriaDatos,
  inLibMonitorSQLIntf,
  inLibMonitorSQLUniDAC,
  inLibMonitorSQLLog,
  inLibLog,
  inLibDir,
  inMtoSplash,
  inMtoAppParam,
  inMtoCajaMenu,
  inMtoCajaParam,
  inMtoBusquedaDatos,
  inMtoModalVerifactuDecl,
  inLibGenerarTicketCaja,
  inMtoStockConsulta,
  inMtoModalListadoVentas,
  inMtoModalScriptLog,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inMtoModalImpMovVentasArt,
  inMtoModalImpDocsProveedor,
  inMtoModalImpEfectosPago,
  inMtoModalFacturarAlbaranes,
  inMtoModalCargarEfectosRemesa,
  inMtoModalCargarEfectosRemesaVenta,
  inLibCajaParam,
  inLibAppParam,
  inLibUnidadesMedida,
  inLibFotos,
  inLibBuscarImpresora,
  inLibVerifactu,
  inLibVerifactuInstalacion,
  inLibVerifactuCola,
  inLibVentasWsCola,
  inLibLicenciaAplicacion,
  inLibCertificates,
  inMtoGen,
  inMtoFotoArticulo,
  System.DateUtils,
  System.RegularExpressions,
  Vcl.StdCtrls,
  inLibBackupWorker,
  Vcl.Clipbrd;

{$R *.dfm}

const
  URL_MANUAL_WEB = 'https://www.veryverifactu.com/manual/index.html';
  URL_FORO_SOPORTE = 'https://foro.veryverifactu.com/';

function EsEventoNoVerifactuArranqueCierre(ATipoEvento: Integer): Boolean;
begin
  Result := (ATipoEvento = cEventoNoVerifactuInicio) or
            (ATipoEvento = cEventoNoVerifactuFin);
end;

function PuedeRegistrarEventoFiscalSeguro(ATipoEvento: Integer;
                                          const ADescripcion: string):
                                          Boolean;
var
  sNifProductor: string;
begin
  Result := True;
  if EsEventoNoVerifactuArranqueCierre(ATipoEvento) then
  begin
    if not NoVerifactuActivo then
      Result := False
    else
    begin
      sNifProductor := NormalizarNifVerifactu(
        oAppParams.GetString('appVerifactuSifNif', ''));
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
                                      AConexion: TUniConnection;
                                      const AUsuario: string;
                                      ATipoEvento: Integer;
                                      const ADescripcion: string);
begin
  if PuedeRegistrarEventoFiscalSeguro(ATipoEvento, ADescripcion) then
  begin
    try
      if AConexion <> nil then
        RegistrarEventoVerifactu(AConexion, AUsuario, ATipoEvento,
          ADescripcion);
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
      Result := 'queda menos de 1 día'
    else if ADias = 1 then
      Result := 'queda 1 día'
    else
      Result := 'quedan ' + IntToStr(ADias) + ' días';
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
                AgregarAviso('certificado electrónico caducado el ' +
                  FormatDateTime('dd/mm/yyyy hh:nn', dCaducidad) + '.');
              end
              else if dCaducidad < IncDay(Now, DIAS_AVISO_CERTIFICADO) then
              begin
                iDias := Trunc(dCaducidad - Now);
                AgregarAviso('certificado electrónico caduca el ' +
                  FormatDateTime('dd/mm/yyyy hh:nn', dCaducidad) +
                  ' (' + TextoDias(iDias) + ').');
              end;
            end;
            Qry.Next;
          end;
          if Avisos.Count > 0 then
          begin
            MessageDlg('Atención: hay certificados electrónicos próximos a ' +
                       'caducar o ya caducados.' + sLineBreak + sLineBreak +
                       Avisos.Text + sLineBreak +
                       'Revise la ficha de empresa y renueve el certificado.',
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
  if EstadoLicenciaEsDemo(oLicenciaAplicacionEstado) then
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
  const AContextoSesion: IContextoSesionAplicacion);
var
  sDis: string;
  ServicioMonitorSQL: IServicioMonitorSQL;
  RegistroMonitorSQL: IRegistroMonitorSQL;
  IdentidadActual: TIdentidadSesion;
  UbicacionActual: TUbicacionSesion;
  ParametrosAppCreados: IParametrosAplicacion;
  ParametrosCajaCreados: IParametrosCaja;

  procedure AplicarTema;
  var
    sTema, sPaleta: string;
  begin
    if not (Assigned(LookAndFeelController1) and
            Assigned(dxSkinController1)) then
      Exit;
    try
      sTema := oAppParams.GetString('appTema');
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
      sPaleta := oAppParams.GetString('appPaleta');
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
      'No se ha proporcionado el contexto de inicio de sesión.');
  AsignarContextoSesion(AContextoSesion);
  IdentidadActual := ContextoSesion.Identidad;
  UbicacionActual := ContextoSesion.Ubicacion;
  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnException := AppException;
  FSavedNCMValid := False;
  FAppEvents.OnIdle := ApplicationEvents1Idle;
  FAppEvents.OnMessage := AppMessage;
  FWorkerOperacion := nil;
  FCancelaOperacionSolicitada := False;
  FEnOperacionLarga := False;
  sDis := '';
  oMemoSQL := cxMemo1;
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
  RegistroMonitorSQL := TRegistroMonitorSQLLog.Create(inLibLog.Log);
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
  oFotos.AsignarConexion(ConexionPrincipal);
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
  inLibLog.Log.LogInfo('Arranque: creando parámetros de caja');
  ParametrosCajaCreados := CrearParametrosCaja(
    PerfilesUsuario,
    IdentidadActual.Usuario,
    IdentidadActual.Grupo
  );
  if not Supports(
    ParametrosAppCreados,
    IParametrosEdicion,
    FParametrosAppEdicion
  ) then
    raise Exception.Create(
      'Los parámetros de aplicación no ofrecen el contrato de edición.');
  if not Supports(
    ParametrosCajaCreados,
    IParametrosEdicion,
    FParametrosCajaEdicion
  ) then
    raise Exception.Create(
      'Los parámetros de caja no ofrecen el contrato de edición.');
  AsignarParametros(ParametrosAppCreados, ParametrosCajaCreados);
  oAppParams := ParametrosAppCreados;
  oCajaParams := ParametrosCajaCreados;
  FdmDataFiltros  := TdmFiltros.Create(Self);
  AsignarFiltrosGuardados(FdmDataFiltros);
  ofrmMto2        := Self;
  oFzaWinf := TfzaWinF.Create(Self);
  oFzaWinf.Charge(ConexionPrincipal);
  try
    SincronizarVersionInstalacionesSif(ConexionPrincipal,
      IdentidadSesion.Usuario);
  except
    on E: Exception do
      inLibLog.Log.LogWarning('No se pudo sincronizar la versión SIF: ' +
                              E.Message);
  end;
  try
    AsegurarDeclaracionResponsableSif(oVersion);
  except
    on E: Exception do
      inLibLog.Log.LogWarning('No se pudo disponer de la declaración ' +
                              'responsable de esta versión: ' + E.Message);
  end;
  if oAppParams.GetBool('appArranqueEnParalelo', False) then
    PrecargarCachesParalelo
  else
    PrecargarCachesSerie;
  // Cache de unidades de medida: decimales por unidad y factores de
  // conversion. La usan ficha de articulo, lineas de documento e informes.
  oUnidades.Cargar;
  oNomImpresoraCaja := GetImpresoraCaja(ContextoSesion);
  // Trazar la impresora resuelta: si queda '' o 'DEBUG', el F9 global de
  // abrir cajon no se activa fuera de caja (ver ImpresoraCajaAsignada).
  inLibLog.Log.LogInfo('Arranque: impresora de caja resuelta = "' +
                       oNomImpresoraCaja + '"');
  // Hilo de la cola Verifactu: arranca siempre; cada ciclo consulta el
  // parámetro appVerifactuActivo, así puede activarse sin reiniciar
  TVerifactuCola.IniciarHilo(Conexiones, IdentidadSesion.Usuario);
  TVentasWsCola.IniciarHilo(Conexiones, IdentidadSesion.Usuario);
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
  RegistrarEventoFiscalSeguro(
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

procedure TfrmMtoPrincipal.CopiasdeSeguridad1Click(Sender: TObject);
var
  Worker: TBackupWorker;
begin
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultExtension := 'sql';
  saveDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  saveDialog.FileTypes.Clear;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  saveDialog.FileName := 'copiaseguridad' +
    FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) + '.sql';
  if saveDialog.Execute then
  begin
    MostrarBarraProgreso;
    Worker := TBackupWorker.Create(
      FDmConn.conUni.Server,
      FDmConn.conUni.Port,
      FDmConn.conUni.Database,
      FDmConn.conUni.Username,
      FDmConn.conUni.Password,
      saveDialog.FileName,
      False, '');
    Worker.OnProgreso := WorkerProgreso;
    Worker.OnFinalizar := BackupFinalizar;
    FCancelaOperacionSolicitada := False;
    FWorkerOperacion := Worker;
    Worker.Start;
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
  oInfGuiasCache := TInformesGuiasCache.Create(ConexionPrincipal);
  oInfGuiasCache.Precargar;
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
  Log.LogInfo(Format('PrecargaSerie: total=%d ms', [swTotal.ElapsedMilliseconds]));
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
        raise Exception.Create(
          'No está disponible el servicio de conexiones.');
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
  oInfGuiasCache := TInformesGuiasCache.Create(ConexionPrincipal);
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
          oInfGuiasCache.Precargar(c);
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
var
  sMensaje: string;
begin
  if not FFalloCargaPermisosAvisado then
  begin
    FFalloCargaPermisosAvisado := True;
    Log.LogError('No se pudieron cargar los permisos: ' + ADetalle);
    sMensaje :=
      'No se pudieron cargar los permisos.' + sLineBreak +
      'El acceso se ha restringido por seguridad.' + sLineBreak +
      'Revise el registro de la aplicación en:' + sLineBreak +
      GetLogFolder;
    MessageDlg(sMensaje, mtWarning, [mbOK], 0);
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
    ShowMessage('Operación cancelada.')
  else if AExito then
  begin
    inLibLog.Log.LogInfo('Copia de seguridad creada exitosamente');
    ShowMessage('La copia se guardó exitosamente.');
  end
  else
  begin
    inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' + AError);
    ShowMessage('No se pudo crear la copia de seguridad.' +
                sLineBreak + AError);
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
    ShowMessage('Operación cancelada. La base de datos puede haber quedado ' +
                'parcialmente modificada.');
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
      ShowMessage('El script se ejecutó exitosamente')
    else
    begin
      inLibLog.Log.LogError('Error en restauración: ' + AError);
      ShowMessage('Hubo problemas al ejecutar el script.' +
                  sLineBreak + AError);
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
      ShowMessage('La cancelación ya está solicitada. Espere a que termine ' +
                  'la sentencia actual.')
    else if MessageDlg('Hay una operación en curso moviendo datos.' +
                       sLineBreak + sLineBreak +
                       '¿Desea abandonar la operación en curso?',
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

function TfrmMtoPrincipal.CopiaSeguridad: Boolean;
var
  sError: string;
begin
  Result := False;
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultExtension := 'sql';
  saveDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  saveDialog.FileTypes.Clear;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  saveDialog.FileName := 'copiaseguridad' +
                            FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) + '.sql';
  if saveDialog.Execute then
  begin
    MostrarBarraProgreso;
    try
      Result := CrearCopiaSeguridadBD(
        FDmConn.conUni.Server,
        FDmConn.conUni.Port,
        FDmConn.conUni.Database,
        FDmConn.conUni.Username,
        FDmConn.conUni.Password,
        saveDialog.FileName,
        False,
        '',
        WorkerProgreso,
        sError);
      if Result then
      begin
        inLibLog.Log.LogInfo('Copia de seguridad creada en ' +
                             saveDialog.FileName);
        ShowMessage('La copia se guardó exitosamente.');
      end
      else
      begin
        inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' +
                              sError);
        ShowMessage('No se pudo crear la copia de seguridad.' + sLineBreak +
                    sError);
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
//var
//  I: Integer;
begin
  // Señalar a las tareas de segundo plano que la app se esta cerrando, ANTES
  // de empezar a liberar formularios y conexiones. Asi no arrancan trabajo
  // nuevo ni tocan formularios en destruccion (ver inMtoGen.EjecutarEnBackground
  // y el destructor de TfrmMtoGen).
  inLibGlobalVar.oCerrandoApp := True;
  RegistrarEventoFiscalSeguro(
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
    oAppParams := nil;
    oCajaParams := nil;
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
    if MessageDlg('¿Quiere salir de la aplicación Fzam?',
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
       (ImpresoraCajaAsignada or Assigned(frmMtoMenuCaja)) and
       (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
       (GetKeyState(VK_SHIFT) >= 0) then
    begin
      AbrirCajonSinVenta(Permisos);
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
     (ImpresoraCajaAsignada or Assigned(frmMtoMenuCaja)) and
     (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
     (GetKeyState(VK_SHIFT) >= 0) then
  begin
    AbrirCajonSinVenta(Permisos);
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

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
var
  SqlTexto: string;
  FS: TFileStream;
  Bytes: TBytes;
  BytesToRead: Int64;
  Worker: TRestoreWorker;
begin
  if not mnuEjecutarScript.Visible then
    Exit;
  openDialog.Title := 'Cargar script';
  openDialog.FileTypes.Clear;
  with openDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with openDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  openDialog.DefaultExtension := 'sql';
  openDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  if openDialog.Execute then
  begin
    // Leer solo los primeros 64 KB para comprobar DDL sin cargar
    // todo el fichero en memoria (los backups pueden ser muy grandes).
    FS := TFileStream.Create(openDialog.FileName,
                             fmOpenRead or fmShareDenyNone);
    try
      BytesToRead := FS.Size;
      if BytesToRead > 65536 then
        BytesToRead := 65536;
      SetLength(Bytes, BytesToRead);
      FS.ReadBuffer(Bytes, BytesToRead);
      SqlTexto := TEncoding.UTF8.GetString(Bytes);
    finally
      FreeAndNil(FS);
    end;
    if ContieneDDL(SqlTexto) then
    begin
      var Respuesta := MessageDlg(
        'ATENCIÓN: El script contiene sentencias DDL (modifican la ' +
        'estructura de la base de datos).' + sLineBreak +
        'En MySQL/MariaDB, estos cambios provocan un guardado automático y ' +
        'NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
        '¿Deseas realizar una copia de seguridad antes de continuar?',
          mtWarning, [mbYes, mbNo, mbCancel], 0);
      case Respuesta of
        mrYes:
          begin
            if not CopiaSeguridad then
            begin
              ShowMessage('Operación cancelada. El script no se ejecutará.');
              Exit;
            end;
          end;
        mrCancel:
          Exit;
      end;
    end;
    // Lanzar ejecución en segundo plano
    MostrarBarraProgreso;
    Worker := TRestoreWorker.Create(
      FDmConn.conUni.Server,
      FDmConn.conUni.Port,
      FDmConn.conUni.Database,
      FDmConn.conUni.Username,
      FDmConn.conUni.Password,
      openDialog.FileName,
      '');
    Worker.OnProgreso := WorkerProgreso;
    Worker.OnFinalizar := RestoreFinalizar;
    FCancelaOperacionSolicitada := False;
    FWorkerOperacion := Worker;
    Worker.Start;
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
    ShowMessage('No se ha podido abrir la dirección: ' + AUrl);
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

procedure TfrmMtoPrincipal.mnuAlmacenesClick(Sender: TObject);
begin
  inherited;
  if mnuAlmacenes.Visible then
    ShowMto(Self, 'Almacenes');
end;

procedure TfrmMtoPrincipal.mnuArticulosClick(Sender: TObject);
begin
  if (mnuArticulos.Visible) then
    ShowMto(Self, 'Articulos');
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

procedure TfrmMtoPrincipal.mnuClientesClick(Sender: TObject);
begin
  if (mnuClientes.Visible) then
    ShowMto(Self, 'Clientes');
end;

procedure TfrmMtoPrincipal.mnuContadoresClick(Sender: TObject);
begin
  if (mnuContadores.Visible) then
    ShowMto(Self, 'Contadores');
end;

procedure TfrmMtoPrincipal.mnuFacturasClick(Sender: TObject);
begin
  if (mnuFacturas.Visible) then
    ShowMto(Self, 'Facturas');
end;

procedure TfrmMtoPrincipal.mnuFacturasSimplifClick(Sender: TObject);
begin
  if (mnuFacturasSimplif.Visible) then
    ShowMto(Self, 'FacturasSimplif');
end;

procedure TfrmMtoPrincipal.mnuFamiliasClick(Sender: TObject);
begin
  if (mnuFamilias.Visible) then
    ShowMto(Self, 'Familias');
end;

procedure TfrmMtoPrincipal.mnuPedidosVentaClick(Sender: TObject);
begin
  inherited;
  if mnuPedidosVenta.Visible then
    ShowMto(Self, 'Pedidos');
end;

procedure TfrmMtoPrincipal.mnuAlbaranesVentaClick(Sender: TObject);
begin
  inherited;
  if mnuAlbaranesVenta.Visible then
    ShowMto(Self, 'Albaranes');
end;

procedure TfrmMtoPrincipal.EfectosVenta1Click(Sender: TObject);
begin
  inherited;
  if EfectosVenta1.Visible then
    ShowMto(Self, 'EfectosVenta');
end;

procedure TfrmMtoPrincipal.RemesasVenta1Click(Sender: TObject);
begin
  inherited;
  if RemesasVenta1.Visible then
    ShowMto(Self, 'RemesasVenta');
end;

procedure TfrmMtoPrincipal.CargarEfectosVenta1Click(Sender: TObject);
var
  f: TfrmModalCargarEfectosRemesaVenta;
begin
  inherited;
  if CargarEfectosVenta1.Visible then
  begin
    f := TfrmModalCargarEfectosRemesaVenta.Create(nil);
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

procedure TfrmMtoPrincipal.Albaranes1Click(Sender: TObject);
begin
  inherited;
  if Albaranes1.Visible then
    ShowMto(Self, 'AlbaranesCompra');
end;

procedure TfrmMtoPrincipal.Devoluciones1Click(Sender: TObject);
begin
  inherited;
  if Devoluciones1.Visible then
    ShowMto(Self, 'DevolucionesCompra');
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

procedure TfrmMtoPrincipal.Facturas1Click(Sender: TObject);
begin
  inherited;
  if Facturas1.Visible then
    ShowMto(Self, 'FacturasCompra');
end;

procedure TfrmMtoPrincipal.EfectosCompra1Click(Sender: TObject);
begin
  inherited;
  if EfectosCompra1.Visible then
    ShowMto(Self, 'EfectosCompra');
end;

procedure TfrmMtoPrincipal.RemesasCompra1Click(Sender: TObject);
begin
  inherited;
  if RemesasCompra1.Visible then
    ShowMto(Self, 'RemesasCompra');
end;

procedure TfrmMtoPrincipal.CargarEfectos1Click(Sender: TObject);
var
  f: TfrmModalCargarEfectosRemesa;
begin
  inherited;
  if CargarEfectos1.Visible then
  begin
    f := TfrmModalCargarEfectosRemesa.Create(nil);
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

procedure TfrmMtoPrincipal.Pedidos1Click(Sender: TObject);
begin
  inherited;
  if Pedidos1.Visible then
    ShowMto(Self, 'PedidosCompra');
end;

procedure TfrmMtoPrincipal.mnuGeneradorProcesosClick(Sender: TObject);
begin
  if (mnuGeneradorProcesos.Visible) then
    ShowMto(Self, 'GeneradorProcesos');
end;

procedure TfrmMtoPrincipal.mnuGruposClick(Sender: TObject);
begin
  if (mnuGrupos.Visible) then
    ShowMto(Self, 'Grupos');
end;

procedure TfrmMtoPrincipal.mnuGruposdeIVAClick(Sender: TObject);
begin
  if (mnuGruposdeIVA.Visible) then
    ShowMto(Self, 'IvasGrupos');
end;

procedure TfrmMtoPrincipal.mnuInventariosClick(Sender: TObject);
begin
  inherited;
  if mnuInventarios.Visible then
    ShowMto(Self, 'Inventarios');
end;

procedure TfrmMtoPrincipal.mnuDocumentosTrabajoClick(Sender: TObject);
begin
  inherited;
  if mnuDocumentosTrabajo.Visible then
  begin
    ShowMto(Self, 'DocumentosTrabajo');
  end;
end;

procedure TfrmMtoPrincipal.mnuIvasClick(Sender: TObject);
begin
  if (mnuIvas.Visible) then
    ShowMto(Self, 'Ivas');
end;

procedure TfrmMtoPrincipal.mnuEmpresasClick(Sender: TObject);
begin
  if (mnuEmpresas.Visible) then
    ShowMto(Self,
            'Empresas');
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

procedure TfrmMtoPrincipal.mnuPaisesClick(Sender: TObject);
begin
  inherited;
  if (mnuPaises.Visible) then
    ShowMto(Self, 'Paises');
end;

procedure TfrmMtoPrincipal.mnuUnidadesMedidaClick(Sender: TObject);
begin
  inherited;
  if (mnuUnidadesMedida.Visible) then
    ShowMto(Self, 'UnidadesMedida');
end;

procedure TfrmMtoPrincipal.mnuPerfilesClick(Sender: TObject);
begin
  if (mnuPerfiles.Visible) then
    ShowMto(Self,
            'UsuariosPerfiles');
end;

procedure TfrmMtoPrincipal.mnuPermisosClick(Sender: TObject);
begin
  if (mnuPermisos.Visible) then
    ShowMto(Self, 'Permisos');
end;

procedure TfrmMtoPrincipal.mnuPermisosTablaClick(Sender: TObject);
begin
  if (mnuPermisosTabla.Visible) then
    ShowMto(Self, 'PermisosTabla');
end;

procedure TfrmMtoPrincipal.mnuProveedoresClick(Sender: TObject);
begin
  if (mnuProveedores.Visible) then
    ShowMto(Self, 'Proveedores');
end;

procedure TfrmMtoPrincipal.mnuUsuariosClick(Sender: TObject);
begin
  if (mnuUsuarios.Visible) then
    ShowMto(Self, 'Usuarios');
end;

procedure TfrmMtoPrincipal.mnuEmpleadosClick(Sender: TObject);
begin
  if (mnuEmpleados.Visible) then
    ShowMto(Self, 'Empleados');
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

procedure TfrmMtoPrincipal.mnuPropiedadesClick(Sender: TObject);
begin
  if (mnuPropiedades.Visible) then
    ShowMto(Self, 'Propiedades');
end;

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVariacionesClick(Sender: TObject);
begin
  if (mnuVariaciones.Visible) then
    ShowMto(Self, 'Variaciones');
end;

procedure TfrmMtoPrincipal.mnuAtributosConjuntosClick(Sender: TObject);
begin
  if (mnuAtributosConjuntos.Visible) then
    ShowMto(Self, 'AtributosConjuntos');
end;

procedure TfrmMtoPrincipal.mnuAtributosBasicosClick(Sender: TObject);
begin
  if (mnuAtributosBasicos.Visible) then
    ShowMto(Self, 'AtributosBasicos');
end;

procedure TfrmMtoPrincipal.mnuCajaPagosHistClick(Sender: TObject);
begin
  if (mnuCajaPagosHist.Visible) then
    ShowMto(Self, 'CajaPagosHist');
end;

procedure TfrmMtoPrincipal.FormasdePagoCaja1Click(Sender: TObject);
begin
  if (FormasdePagoCaja1.Visible) then
    ShowMto(Self, 'CajaFormasPago');
end;

procedure TfrmMtoPrincipal.mnuCajaValesHistClick(Sender: TObject);
begin
  if (mnuCajaValesHist.Visible) then
    ShowMto(Self, 'CajaValesHist');
end;

procedure TfrmMtoPrincipal.mnuCajaOperacionesHistClick(Sender: TObject);
begin
  if (mnuCajaOperacionesHist.Visible) then
    ShowMto(Self, 'CajaOperacionesHist');
end;

procedure TfrmMtoPrincipal.mnuVerifactuDeclaracionClick(Sender: TObject);
begin
  if (mnuVerifactuDeclaracion.Visible) then
    TfrmModalVerifactuDecl.Ejecutar(Self);
end;

procedure TfrmMtoPrincipal.mnuVerifactuColaClick(Sender: TObject);
begin
  if (mnuVerifactuCola.Visible) then
    ShowMto(Self, 'VerifactuCola');
end;

procedure TfrmMtoPrincipal.mnuVerifactuLogClick(Sender: TObject);
begin
  if (mnuVerifactuLog.Visible) then
    ShowMto(Self, 'VerifactuLog');
end;

procedure TfrmMtoPrincipal.mnuCajaArqueosHistClick(Sender: TObject);
begin
  if (mnuCajaArqueosHist.Visible) then
    ShowMto(Self, 'CajaArqueosHist');
end;

procedure TfrmMtoPrincipal.Movimientosdealmacn1Click(Sender: TObject);
begin
  if (Movimientosdealmacn1.Visible) then
    ShowMto(Self, 'MovimientosAlmacen');
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

procedure TfrmMtoPrincipal.mnuDepositosClienteClick(Sender: TObject);
begin
  if (mnuDepositosCliente.Visible) then
    ShowMto(Self, 'DepositosCliente');
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

// Captura cualquier excepción no atrapada por bloques try/except en la
// aplicación. Asignado a Application.OnException desde FormCreate. El
// objetivo es no perder NINGÚN detalle del fallo: registra todo al log
// y muestra al usuario un diálogo con la traza completa y un botón
// para copiarla al portapapeles (para que pueda pegarla en un reporte).
procedure TfrmMtoPrincipal.AppException(Sender: TObject; E: Exception);
var
  sDetalle: string;
  bRuidoEditorInplace: Boolean;
begin
  // Filtro: EInvalidOperation "no tiene ventana principal" disparado por
  // el editor inplace del cxGrid sin Parent durante transiciones de celda.
  // Es ruido benigno: el handle se acaba creando en la siguiente pasada,
  // el usuario no pierde datos. Solo lo registramos como warning, sin
  // diálogo modal. Patron mitigado tambien en inMtoCajaOpe e inLibDevExp.
  bRuidoEditorInplace := (E is EInvalidOperation) and
                         (Pos('no tiene ventana principal',
                              E.Message) > 0);
  if bRuidoEditorInplace then
  begin
    try
      inLibLog.Log.LogWarning('AppException ignorado (editor inplace sin ' +
                              'Parent): ' + E.Message);
    except
    end;
  end
  else
  begin
    try
      sDetalle := ConstruirDetalleException(Sender, E);
      try
        inLibLog.Log.LogError('AppException ' + E.ClassName + ': ' +
                              E.Message);
        inLibLog.Log.LogError('AppException detalle:' + sLineBreak + sDetalle);
      except
        // Si el log falla no podemos hacer mucho; seguimos para mostrarlo.
      end;
      MostrarDetalleExcepcion(sDetalle);
    except
      // Última red de seguridad: si la construcción del detalle o el
      // diálogo fallan, al menos mostramos lo básico para que el usuario
      // sepa que algo ha pasado.
      try
        Application.ShowException(E);
      except
      end;
    end;
  end;
end;

function TfrmMtoPrincipal.ConstruirDetalleException(Sender: TObject;
                                                   E: Exception): string;
var
  sSenderClass, sSenderName: string;
  pAddr: Pointer;
  Inner: Exception;
  iNivel: Integer;
  IdentidadActual: TIdentidadSesion;
  UbicacionActual: TUbicacionSesion;
begin
  IdentidadActual := ContextoSesion.Identidad;
  UbicacionActual := ContextoSesion.Ubicacion;
  if Assigned(Sender) then
  begin
    sSenderClass := Sender.ClassName;
    if (Sender is TComponent) and (TComponent(Sender).Name <> '') then
      sSenderName := TComponent(Sender).Name
    else
      sSenderName := '(sin nombre)';
  end
  else
  begin
    sSenderClass := '(nil)';
    sSenderName  := '(nil)';
  end;
  pAddr := ExceptAddr;
  Result :=
    '=== Detalle del error ===' + sLineBreak +
    'Aplicación   : ' + oAppName + ' ' + oVersion + sLineBreak +
    'Fecha / hora : ' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
                                                                  sLineBreak +
    'Usuario      : ' + IdentidadActual.Usuario + ' (' +
      IdentidadActual.Grupo + ')' + sLineBreak +
    'Empresa      : ' + UbicacionActual.Empresa + sLineBreak +
    'Almacén/Caja : ' + UbicacionActual.Almacen + ' / ' +
      UbicacionActual.Caja + sLineBreak +
    'Equipo       : ' + GetComputerName + sLineBreak +
    sLineBreak +
    '--- Excepción ---' + sLineBreak +
    'Clase        : ' + E.ClassName + sLineBreak +
    'Mensaje      : ' + E.Message + sLineBreak +
    'Dirección    : $' + IntToHex(NativeUInt(pAddr),
                                  SizeOf(Pointer) * 2) + sLineBreak +
    sLineBreak +
    '--- Sender ---' + sLineBreak +
    'Clase        : ' + sSenderClass + sLineBreak +
    'Nombre       : ' + sSenderName + sLineBreak;
  // Stack trace: solo aparece si hay un proveedor registrado (madExcept,
  // JCL, EurekaLog…). Si no, será cadena vacía: no es un fallo.
  if E.StackTrace <> '' then
    Result := Result + sLineBreak +
      '--- Stack ---' + sLineBreak + E.StackTrace + sLineBreak;
  // Excepciones encadenadas (raise … from). Limitamos profundidad
  // para evitar bucles infinitos por ciclos accidentales.
  Inner := E.InnerException;
  iNivel := 1;
  while Assigned(Inner) and (iNivel <= 5) do
  begin
    Result := Result + sLineBreak +
      Format('--- Inner exception #%d ---', [iNivel]) + sLineBreak +
      'Clase   : ' + Inner.ClassName + sLineBreak +
      'Mensaje : ' + Inner.Message + sLineBreak;
    if Inner.StackTrace <> '' then
      Result := Result + 'Stack   :' + sLineBreak + Inner.StackTrace +
                                                                  sLineBreak;
    Inner := Inner.InnerException;
    Inc(iNivel);
  end;
end;

procedure TfrmMtoPrincipal.MostrarDetalleExcepcion(const ATexto: string);
var
  Dialog    : TForm;
  pnlBotones: TPanel;
  btnCopiar : TButton;
  btnCerrar : TButton;
  lblCabec  : TLabel;
begin
  Dialog := TForm.Create(nil);
  try
    Dialog.Caption     := 'Se ha producido un error';
    Dialog.Position    := poScreenCenter;
    Dialog.Width       := 760;
    Dialog.Height      := 520;
    Dialog.BorderStyle := bsSizeable;
    Dialog.BorderIcons := [biSystemMenu];
    Dialog.KeyPreview  := True;

    lblCabec := TLabel.Create(Dialog);
    lblCabec.Parent    := Dialog;
    lblCabec.Align     := alTop;
    lblCabec.AutoSize  := False;
    lblCabec.Height    := 28;
    lblCabec.Layout    := tlCenter;
    lblCabec.Caption   := '  Detalle completo del error. Usa "Copiar al ' +
                          'portapapeles" para pegarlo en un reporte.';

    pnlBotones := TPanel.Create(Dialog);
    pnlBotones.Parent      := Dialog;
    pnlBotones.Align       := alBottom;
    pnlBotones.Height      := 48;
    pnlBotones.BevelOuter  := bvNone;

    btnCerrar := TButton.Create(Dialog);
    btnCerrar.Parent       := pnlBotones;
    btnCerrar.Caption      := 'Cerrar';
    btnCerrar.Width        := 100;
    btnCerrar.Height       := 32;
    btnCerrar.Top          := 8;
    btnCerrar.Anchors      := [akRight, akTop];
    btnCerrar.Left         := pnlBotones.ClientWidth - btnCerrar.Width - 12;
    btnCerrar.ModalResult  := mrOk;
    btnCerrar.Default      := True;
    btnCerrar.Cancel       := True;

    btnCopiar := TButton.Create(Dialog);
    btnCopiar.Parent       := pnlBotones;
    btnCopiar.Caption      := 'Copiar al portapapeles';
    btnCopiar.Width        := 190;
    btnCopiar.Height       := 32;
    btnCopiar.Top          := 8;
    btnCopiar.Anchors      := [akRight, akTop];
    btnCopiar.Left         := btnCerrar.Left - btnCopiar.Width - 8;
    btnCopiar.OnClick      := CopiarExceptionDialogClick;

    FExceptionDialogMemo := TcxMemo.Create(Dialog);
    FExceptionDialogMemo.Parent     := Dialog;
    FExceptionDialogMemo.Align      := alClient;
    FExceptionDialogMemo.Properties.ReadOnly   := True;
    FExceptionDialogMemo.Properties.ScrollBars := ssBoth;
    FExceptionDialogMemo.Properties.WordWrap   := False;
    FExceptionDialogMemo.Style.Font.Name  := 'Consolas';
    FExceptionDialogMemo.Style.Font.Size  := 9;
    FExceptionDialogMemo.Text       := ATexto;

    Dialog.ActiveControl := btnCerrar;
    Dialog.ShowModal;
  finally
    FExceptionDialogMemo := nil;
    FreeAndNil(Dialog);
  end;
end;

procedure TfrmMtoPrincipal.CopiarExceptionDialogClick(Sender: TObject);
begin
  if Assigned(FExceptionDialogMemo) then
  try
    Clipboard.AsText := FExceptionDialogMemo.Text;
  except
    on E: Exception do
      inLibLog.Log.LogWarning('No se pudo copiar al portapapeles: ' +
                                                                   E.Message);
  end;
end;

end.
