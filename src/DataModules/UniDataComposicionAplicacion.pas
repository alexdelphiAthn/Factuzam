{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComposicionAplicacion                                  }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Raíz de composición de servicios, adaptadores y procesos de Factuzam.     }
{    Su fan-out alto es intencionado porque construye implementaciones         }
{    concretas y las expone mediante contratos estrechos; no aloja navegación  }
{    ni lógica de pantallas. Los procesos en segundo plano se delegan en una   }
{    subraíz con dependencias explícitas y ciclo de vida propio.               }
{******************************************************************************}
unit UniDataComposicionAplicacion;

interface

uses
  System.Classes,
  System.SysUtils,
  Uni,
  inLibContextoSesionIntf,
  inLibLicenciaAplicacion,
  inLibExcepcionesAplicacionIntf,
  inLibEnvioErroresIntf,
  inLibCopiasSeguridadIntf,
  inLibOperacionesAplicacionIntf,
  inLibConexionesIntf,
  inLibAuditoriaDatosIntf,
  inLibMonitorSQLIntf,
  inLibLogIntf,
  inLibConfigCamposIntf,
  inLibConfigCampos,
  inLibRepositoriosPantallaIntf,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosConfiguracionPantalla,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosRemesasPantalla,
  UniDataRepositoriosOperacionesPantalla,
  UniDataRepositoriosVentasPantalla,
  UniDataRepositoriosCajaPantalla,
  UniDataRepositoriosTicketsCajaPantalla,
  inLibParametrosIntf,
  inLibPerfilesUsuarioIntf,
  inLibFiltrosGuardadosIntf,
  inLibInformesGuiasCache,
  inLibTraduccionesIntf,
  inLibPermisosIntf,
  inLibFotos,
  inLibUnidadesMedida,
  inLibPreviewTicket,
  inLibUnitForm,
  inLibPrestaShopCierre,
  UniDataConn,
  UniDataComposicionAplicacionProcesosSegundoPlano;

type
  TComposicionAplicacion = class
  private
    FOwner: TComponent;
    FFabricaConexiones: IFabricaConexionesUniDAC;
    FContextoSesion: IContextoSesionAplicacion;
    FRegistroLog: IRegistroLog;
    FPreviewTicket: IPreviewTicket;
    FRegistroMonitorSQL: IRegistroMonitorSQL;
    FConfigCampos: IConfiguracionCampos;
    FConfigCamposCarga: TConfigCamposCache;
    FDmConn: TdmConn;
    FDmPerfiles: TDataModule;
    FDmFiltros: TDataModule;
    FConexiones: IServicioConexiones;
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FMonitorSQL: IServicioMonitorSQL;
    FServiciosParametrosApp: TServiciosParametrosAplicacion;
    FServiciosParametrosCaja: TServiciosParametrosCaja;
    FServiciosPerfiles: TServiciosPerfilesUsuario;
    FServiciosFiltros: TServiciosFiltrosGuardados;
    FInformesGuias: IInformesGuiasCache;
    FTraducciones: IServicioTraducciones;
    FPermisos: IPermisosAplicacion;
    FFotos: TFotosArticulos;
    FUnidades: TUnidadesMedida;
    FRegistroPantallas: TfzaWinF;
    FGestorExcepciones: IGestorExcepcionesAplicacion;
    FServicioEnvioErrores: IServicioEnvioErrores;
    FRepositorioCopias: IRepositorioCopiasSeguridad;
    FOperaciones: ICasoUsoCopiasSeguridad;
    FProcesosSegundoPlano: TProcesosSegundoPlanoAplicacion;
    FCerrada: Boolean;
    function EjecutarCargaWorker(
      ACarga: TProc<TUniConnection>;
      out AError: string): Int64;
    function PrecargarCachesSerie: string;
    function PrecargarCachesParalelo: string;
    function CrearSqlPantalla(
      const ANombrePantalla: string): TServiciosSqlPantalla;
    procedure LiberarRegistrosServicios;
  public
    constructor Create(
      AOwner: TComponent;
      const AFabricaConexiones: IFabricaConexionesUniDAC;
      const AContextoSesion: IContextoSesionAplicacion;
      const ARegistroLog: IRegistroLog;
      const APreviewTicket: IPreviewTicket;
      const ARegistroMonitorSQL: IRegistroMonitorSQL;
      const AGestorExcepciones: IGestorExcepcionesAplicacion;
      const APresentacionOperaciones:
        IPresentacionOperacionesAplicacion);
    destructor Destroy; override;
    procedure CrearInfraestructura;
    procedure CrearPerfiles;
    procedure CrearParametros(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure CrearServiciosSesion;
    procedure ComprobarConfiguracionFiscal(const AVersion: string);
    function CargarDatosArranque: string;
    procedure IniciarProcesosSegundoPlano;
    function PrepararCierrePrestaShop(
      const AConsultarDecision:
        TConsultarDecisionCierrePrestaShop): Boolean;
    procedure RegistrarInicioFiscal;
    procedure RegistrarCierreFiscal;
    procedure DetenerProcesosSegundoPlano;
    procedure Cerrar;
    function CrearServiciosSqlPantalla(
      const ANombrePantalla: string): TServiciosSqlPantalla;
    function CrearRepositoriosArticulosPantalla(
      const ANombrePantalla: string): IRepositoriosArticulosPantalla;
    function CrearRepositoriosConfiguracionPantalla(
      const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
    function CrearRepositoriosDocumentosPantalla(
      const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
    function CrearRepositoriosRemesasPantalla(
      const ANombrePantalla: string): IRepositoriosRemesasPantalla;
    function CrearRepositoriosOperacionesPantalla(
      const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
    function CrearRepositoriosVentasPantalla(
      const ANombrePantalla: string): IRepositoriosVentasPantalla;
    function CrearRepositoriosCajaPantalla(
      const ANombrePantalla: string): IRepositoriosCajaPantalla;
    function CrearRepositoriosTicketsCajaPantalla(
      const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
    property DmConn: TdmConn read FDmConn;
    property Conexiones: IServicioConexiones read FConexiones;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read FAuditoriaDatos;
    property MonitorSQL: IServicioMonitorSQL read FMonitorSQL;
    property ConfiguracionCampos: IConfiguracionCampos
      read FConfigCampos;
    property ParametrosApp: IParametrosAplicacion
      read FServiciosParametrosApp.Lectura;
    property ParametrosCaja: IParametrosCaja
      read FServiciosParametrosCaja.Lectura;
    property ParametrosAppEdicion: IParametrosEdicion
      read FServiciosParametrosApp.Edicion;
    property ParametrosCajaEdicion: IParametrosEdicion
      read FServiciosParametrosCaja.Edicion;
    property ServiciosPerfiles: TServiciosPerfilesUsuario
      read FServiciosPerfiles;
    property ServiciosFiltros: TServiciosFiltrosGuardados
      read FServiciosFiltros;
    property InformesGuias: IInformesGuiasCache read FInformesGuias;
    property Traducciones: IServicioTraducciones read FTraducciones;
    property Permisos: IPermisosAplicacion read FPermisos;
    property Fotos: TFotosArticulos read FFotos;
    property Unidades: TUnidadesMedida read FUnidades;
    property RegistroPantallas: TfzaWinF read FRegistroPantallas;
    property GestorExcepciones: IGestorExcepcionesAplicacion
      read FGestorExcepciones;
    property Operaciones: ICasoUsoCopiasSeguridad
      read FOperaciones;
    property ContextoSesion: IContextoSesionAplicacion
      read FContextoSesion;
    property RegistroLog: IRegistroLog read FRegistroLog;
  end;

implementation

uses
  System.Diagnostics,
  System.Threading,
  inLibConexionesUniDAC,
  inLibAuditoriaDatos,
  inLibMonitorSQLUniDAC,
  inLibVerifactu,
  inLibVerifactuInstalacion,
  UniDataConfigCamposRepositorio,
  UniDataUnidadesMedidaRepositorio,
  UniDataRegistroPantallasRepositorio,
  UniDataRepositoriosConfiguracionAplicacionPantalla,
  UniDataRepositoriosOperacionesAplicacionPantalla,
  UniDataRepositoriosPantalla,
  inLibMsgConexion;

resourcestring
  SErrorServicioConexionesComposicionNoDisponible =
    'El servicio de conexiones no está disponible.';

function EsEventoNoVerifactuArranqueCierre(
  ATipoEvento: Integer): Boolean;
begin
  Result := (ATipoEvento = cEventoNoVerifactuInicio) or
            (ATipoEvento = cEventoNoVerifactuFin);
end;

function PuedeRegistrarEventoFiscalSeguro(
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  ATipoEvento: Integer;
  const ADescripcion: string): Boolean;
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
        ARegistroLog.RegistrarAviso(
          'No se registra evento fiscal "' + ADescripcion +
          '": appVerifactuSifNif vacío o no válido para el perfil ' +
          'actual.');
      end;
    end;
  end;
end;

constructor TComposicionAplicacion.Create(
  AOwner: TComponent;
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog;
  const APreviewTicket: IPreviewTicket;
  const ARegistroMonitorSQL: IRegistroMonitorSQL;
  const AGestorExcepciones: IGestorExcepcionesAplicacion;
  const APresentacionOperaciones:
    IPresentacionOperacionesAplicacion);
begin
  inherited Create;
  if not Assigned(AOwner) then
    raise EArgumentNilException.Create('AOwner');
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  if not Assigned(ARegistroMonitorSQL) then
    raise EArgumentNilException.Create('ARegistroMonitorSQL');
  if not Assigned(AGestorExcepciones) then
    raise EArgumentNilException.Create('AGestorExcepciones');
  FOwner := AOwner;
  FFabricaConexiones := AFabricaConexiones;
  FContextoSesion := AContextoSesion;
  FRegistroLog := ARegistroLog;
  FPreviewTicket := APreviewTicket;
  FRegistroMonitorSQL := ARegistroMonitorSQL;
  FGestorExcepciones := AGestorExcepciones;
  FDmConn := TdmConn.Create(FOwner);
  FDmConn.AsignarFabrica(AFabricaConexiones);
  FRepositorioCopias := CrearRepositorioCopiasAplicacionPantalla(
    FContextoSesion,
    FDmConn.conUni);
  FOperaciones := CrearOperacionesCopiasAplicacionPantalla(
    FRepositorioCopias,
    APresentacionOperaciones);
  CrearInfraestructura;
  FCerrada := False;
end;

destructor TComposicionAplicacion.Destroy;
begin
  Cerrar;
  inherited;
end;

procedure TComposicionAplicacion.CrearInfraestructura;
begin
  FMonitorSQL := TServicioMonitorSQLUniDAC.Create(
    FDmConn.UniSQLMonitor1,
    FRegistroMonitorSQL);
  FDmConn.AsignarReceptorMonitorSQL(
    FMonitorSQL as IReceptorEventosMonitorSQL);
  FDmConn.conUni.Connect;
  FConexiones := TServicioConexionesUniDAC.Create(
    FDmConn.conUni,
    FFabricaConexiones);
  FConfigCamposCarga := TConfigCamposCache.Create(
    TRepositorioConfigCamposUniDAC.Create(FDmConn.conUni),
    FRegistroLog);
  FConfigCampos := FConfigCamposCarga;
  FUnidades := TUnidadesMedida.Create(
    TRepositorioUnidadesMedidaUniDAC.Create(FDmConn.conUni),
    FRegistroLog);
  FAuditoriaDatos := TServicioAuditoriaDatos.Create(FContextoSesion);
end;

function TComposicionAplicacion.CrearSqlPantalla(
  const ANombrePantalla: string): TServiciosSqlPantalla;
begin
  Result := CrearServiciosSqlPantallaUniDAC(
    ANombrePantalla,
    FServiciosPerfiles.Lectura,
    FServiciosPerfiles.Escritura,
    FRegistroLog,
    FFabricaConexiones.Perfil.Motor);
end;

function TComposicionAplicacion.CrearServiciosSqlPantalla(
  const ANombrePantalla: string): TServiciosSqlPantalla;
begin
  Result := CrearSqlPantalla(ANombrePantalla);
end;

function TComposicionAplicacion.CrearRepositoriosArticulosPantalla(
  const ANombrePantalla: string): IRepositoriosArticulosPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosArticulosPantallaUniDAC(
    FDmConn.conUni, FServiciosParametrosCaja.Lectura, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosConfiguracionPantalla(
  const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosConfiguracionPantallaUniDAC(
    FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosDocumentosPantalla(
  const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosDocumentosPantallaUniDAC(
    FDmConn.conUni,
    FServiciosParametrosApp.Lectura,
    FServiciosParametrosCaja.Lectura,
    FRegistroLog,
    oSql);
end;

function TComposicionAplicacion.CrearRepositoriosRemesasPantalla(
  const ANombrePantalla: string): IRepositoriosRemesasPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosRemesasPantallaUniDAC(
    FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosOperacionesPantalla(
  const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosOperacionesPantallaUniDAC(
    FDmConn.conUni,
    FServiciosParametrosApp.Lectura,
    FServiciosParametrosCaja.Lectura,
    FRegistroLog,
    oSql);
end;

function TComposicionAplicacion.CrearRepositoriosVentasPantalla(
  const ANombrePantalla: string): IRepositoriosVentasPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosVentasPantallaUniDAC(FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosCajaPantalla(
  const ANombrePantalla: string): IRepositoriosCajaPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosCajaPantallaUniDAC(FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosTicketsCajaPantalla(
  const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosTicketsCajaPantallaUniDAC(
    FDmConn.conUni,
    FServiciosParametrosApp.Lectura,
    FServiciosParametrosCaja.Lectura,
    FContextoSesion,
    FPreviewTicket,
    oSql);
end;

procedure TComposicionAplicacion.CrearPerfiles;
var
  oComposicion: TComposicionPerfilesAplicacionPantalla;
begin
  oComposicion := CrearPerfilesAplicacionPantalla(FOwner);
  FDmPerfiles := oComposicion.DataModule;
  FServiciosPerfiles := oComposicion.Servicios;
end;

procedure TComposicionAplicacion.CrearParametros(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
var
  Identidad: TIdentidadSesion;
begin
  Identidad := FContextoSesion.Identidad;
  FRegistroLog.RegistrarInformacion(
    'Arranque: creando parámetros de aplicación');
  FServiciosParametrosApp := CrearParametrosAplicacionPantalla(
    FServiciosPerfiles,
    FRegistroLog,
    Identidad);
  FServiciosParametrosApp.GestorLicencia.EstablecerLicencia(
    AResultadoLicencia);
  FServicioEnvioErrores := CrearServicioEnvioErroresAplicacionPantalla(
    FContextoSesion,
    FServiciosParametrosApp.Lectura,
    FRegistroLog,
    FRepositorioCopias,
    FDmConn.conUni);
  FGestorExcepciones.AsignarServicioEnvioErrores(
    FServicioEnvioErrores);
  FRegistroLog.RegistrarInformacion(
    'Arranque: creando parámetros de caja');
  FServiciosParametrosCaja := CrearParametrosCajaPantalla(
    FServiciosPerfiles,
    FContextoSesion,
    Identidad);
  FDmConn.AsignarParametrosApp(FServiciosParametrosApp.Lectura);
  FTraducciones := CrearTraduccionesAplicacionPantalla(
    FConexiones,
    FRegistroLog,
    FServiciosParametrosApp.Lectura);
  FConfigCamposCarga.AsignarTraducciones(FTraducciones);
end;

procedure TComposicionAplicacion.CrearServiciosSesion;
var
  bCatalogoActivo: Boolean;
  oComposicionFiltros: TComposicionFiltrosAplicacionPantalla;
begin
  bCatalogoActivo := False;
  try
    bCatalogoActivo := SameText(
      FServiciosPerfiles.Lectura.ObtenerValorPerfil(
        FOwner.Name,
        'oGetSQLFromDB',
        'False'),
      'True');
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo leer oGetSQLFromDB de ' + FOwner.Name + ': ' +
        E.Message);
  end;
  FFotos := CrearFotosAplicacionPantalla(
    FDmConn.conUni,
    FServiciosPerfiles,
    FServiciosParametrosApp.Lectura,
    FRegistroLog,
    bCatalogoActivo,
    FFabricaConexiones.Perfil.Motor);
  oComposicionFiltros := CrearFiltrosAplicacionPantalla(FOwner);
  FDmFiltros := oComposicionFiltros.DataModule;
  FServiciosFiltros := oComposicionFiltros.Servicios;
  FServiciosFiltros.Destinos :=
    CrearRepositoriosConfiguracionPantalla('GestionFiltros').
    CrearRepositorioDestinosFiltros;
  FServiciosFiltros.Guias :=
    CrearRepositoriosConfiguracionPantalla('Guias').
    CrearRepositorioGuias;
  FRegistroPantallas := TfzaWinF.Create(
    FOwner,
    FRegistroLog,
    CrearLectorRegistroPantallasUniDAC(FDmConn.conUni));
  FRegistroPantallas.Charge;
  FRegistroPantallas.ComprobarRegistradas;
end;

procedure TComposicionAplicacion.ComprobarConfiguracionFiscal(
  const AVersion: string);
begin
  try
    SincronizarVersionInstalacionesSif(
      FServiciosParametrosApp.Lectura,
      FDmConn.conUni,
      FContextoSesion.Identidad.Usuario);
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo sincronizar la versión SIF: ' + E.Message);
  end;
  try
    AsegurarDeclaracionResponsableSif(
      FServiciosParametrosApp.Lectura,
      AVersion,
      FRegistroLog);
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo disponer de la declaración responsable de esta ' +
        'versión: ' + E.Message);
  end;
end;

function TComposicionAplicacion.EjecutarCargaWorker(
  ACarga: TProc<TUniConnection>;
  out AError: string): Int64;
var
  oConexion: TUniConnection;
  sw: TStopwatch;
begin
  AError := '';
  sw := TStopwatch.StartNew;
  oConexion := nil;
  try
    try
      if not Assigned(FConexiones) then
      begin
        raise EInvalidOpException.Create(
          SErrorServicioConexionesComposicionNoDisponible);
      end;
      oConexion := FConexiones.CrearConexion(nil, uctPrecarga);
      ACarga(oConexion);
    except
      on E: Exception do
        AError := E.ClassName + ': ' + E.Message;
    end;
  finally
    FreeAndNil(oConexion);
  end;
  Result := sw.ElapsedMilliseconds;
end;

function TComposicionAplicacion.PrecargarCachesSerie: string;
var
  IdentidadSesion: TIdentidadSesion;
  swTotal: TStopwatch;
begin
  Result := '';
  swTotal := TStopwatch.StartNew;
  FRegistroLog.RegistrarInformacion(
    'Arranque: PrecargarCachesSerie INICIO');
  FServiciosPerfiles.Cache.PrecargarPerfilesUsuario;
  FInformesGuias := CrearInformesGuiasAplicacionPantalla(
    FDmConn.conUni);
  FInformesGuias.Precargar;
  FConfigCamposCarga.Precargar;
  IdentidadSesion := FContextoSesion.Identidad;
  try
    FPermisos := CargarPermisosAplicacionPantalla(
      FDmConn.conUni,
      IdentidadSesion);
  except
    on E: Exception do
    begin
      FPermisos := CrearPermisosNoDisponiblesPantalla(
        IdentidadSesion);
      Result := E.ClassName + ': ' + E.Message;
    end;
  end;
  FRegistroLog.RegistrarInformacion(
    Format(
      'PrecargaSerie: total=%d ms',
      [swTotal.ElapsedMilliseconds]));
end;

function TComposicionAplicacion.PrecargarCachesParalelo: string;
var
  IdentidadSesion: TIdentidadSesion;
  PermisosCargados: IPermisosAplicacion;
  swTotal: TStopwatch;
  msPerfiles: Int64;
  msInformes: Int64;
  msConfig: Int64;
  msPermisos: Int64;
  sErrorPerfiles: string;
  sErrorInformes: string;
  sErrorConfig: string;
  sErrorPermisos: string;
  tPerfiles: ITask;
  tInformes: ITask;
  tConfig: ITask;
  tPermisos: ITask;
begin
  Result := '';
  swTotal := TStopwatch.StartNew;
  FRegistroLog.RegistrarInformacion(
    'Arranque: PrecargarCachesParalelo INICIO');
  IdentidadSesion := FContextoSesion.Identidad;
  PermisosCargados := nil;
  msPerfiles := 0;
  msInformes := 0;
  msConfig := 0;
  msPermisos := 0;
  sErrorPerfiles := '';
  sErrorInformes := '';
  sErrorConfig := '';
  sErrorPermisos := '';
  FInformesGuias := CrearInformesGuiasAplicacionPantalla(
    FDmConn.conUni);
  tPerfiles := TTask.Run(
    procedure
    begin
      msPerfiles := EjecutarCargaWorker(
        procedure(AConexion: TUniConnection)
        begin
          PrecargarPerfilesAplicacionPantalla(
            FDmPerfiles,
            AConexion);
        end,
        sErrorPerfiles);
    end);
  tInformes := TTask.Run(
    procedure
    begin
      msInformes := EjecutarCargaWorker(
        procedure(AConexion: TUniConnection)
        begin
          PrecargarInformesGuiasAplicacionPantalla(
            FInformesGuias,
            AConexion);
        end,
        sErrorInformes);
    end);
  tConfig := TTask.Run(
    procedure
    begin
      msConfig := EjecutarCargaWorker(
        procedure(AConexion: TUniConnection)
        begin
          FConfigCamposCarga.Precargar(
            TRepositorioConfigCamposUniDAC.Create(AConexion));
        end,
        sErrorConfig);
    end);
  tPermisos := TTask.Run(
    procedure
    begin
      msPermisos := EjecutarCargaWorker(
        procedure(AConexion: TUniConnection)
        begin
          PermisosCargados := CargarPermisosAplicacionPantalla(
            AConexion,
            IdentidadSesion);
        end,
        sErrorPermisos);
    end);
  TTask.WaitForAll([tPerfiles, tInformes, tConfig, tPermisos]);
  if Assigned(PermisosCargados) then
    FPermisos := PermisosCargados
  else
  begin
    FPermisos := CrearPermisosNoDisponiblesPantalla(
      IdentidadSesion);
    if sErrorPermisos = '' then
      sErrorPermisos := 'La carga no devolvió una caché de permisos';
  end;
  FRegistroLog.RegistrarInformacion(
    Format(
      'PrecargaParalela: total=%d ms || ' +
      'perfiles=%d infguias=%d config=%d permisos=%d',
      [swTotal.ElapsedMilliseconds,
       msPerfiles, msInformes, msConfig, msPermisos]));
  if (sErrorPerfiles <> '') or (sErrorInformes <> '') or
     (sErrorConfig <> '') or (sErrorPermisos <> '') then
  begin
    FRegistroLog.RegistrarError(
      Format(
        'PrecargaParalela errores -> perfiles=[%s] ' +
        'infguias=[%s] config=[%s] permisos=[%s]',
        [sErrorPerfiles, sErrorInformes,
         sErrorConfig, sErrorPermisos]));
  end;
  Result := sErrorPermisos;
end;

function TComposicionAplicacion.CargarDatosArranque: string;
begin
  if FServiciosParametrosApp.Lectura.GetBool(
       'appArranqueEnParalelo',
       False) then
  begin
    Result := PrecargarCachesParalelo;
  end
  else
    Result := PrecargarCachesSerie;
  FUnidades.Cargar;
  FRegistroLog.RegistrarInformacion(
    'Arranque: detección diferida de impresora de caja; valor actual = "' +
    FServiciosParametrosCaja.Lectura.ImpresoraCaja + '"');
  FRegistroLog.RegistrarInformacion(
    'Arranque: detección diferida de impresora de documentos; ' +
    'valor actual = "' +
    FServiciosParametrosApp.Lectura.ImpresoraDocumentos + '"');
end;

procedure TComposicionAplicacion.IniciarProcesosSegundoPlano;
begin
  if not Assigned(FProcesosSegundoPlano) then
    FProcesosSegundoPlano := TProcesosSegundoPlanoAplicacion.Create(
      FConexiones,
      FContextoSesion,
      FServiciosParametrosApp.Lectura,
      FServiciosParametrosCaja.Lectura,
      FRegistroLog);
  FProcesosSegundoPlano.Iniciar;
end;

function TComposicionAplicacion.PrepararCierrePrestaShop(
  const AConsultarDecision:
    TConsultarDecisionCierrePrestaShop): Boolean;
begin
  Result := True;
  if Assigned(FProcesosSegundoPlano) then
    Result := FProcesosSegundoPlano.PrepararCierrePrestaShop(
      AConsultarDecision);
end;

procedure TComposicionAplicacion.RegistrarInicioFiscal;
begin
  FRegistroLog.RegistrarInformacion('Arranque del sistema');
  if PuedeRegistrarEventoFiscalSeguro(
       FServiciosParametrosApp.Lectura,
       FRegistroLog,
       cEventoNoVerifactuInicio,
       'Inicio del sistema') then
  begin
    try
      RegistrarEventoVerifactu(
        FServiciosParametrosApp.Lectura,
        FDmConn.conUni,
        FContextoSesion.Identidad.Usuario,
        cEventoNoVerifactuInicio,
        'Inicio del sistema');
    except
      on E: Exception do
        FRegistroLog.RegistrarError(
          'No se pudo registrar el inicio fiscal: ' + E.Message);
    end;
  end;
end;

procedure TComposicionAplicacion.RegistrarCierreFiscal;
begin
  if PuedeRegistrarEventoFiscalSeguro(
       FServiciosParametrosApp.Lectura,
       FRegistroLog,
       cEventoNoVerifactuFin,
       'Cierre del sistema') then
  begin
    try
      RegistrarEventoVerifactu(
        FServiciosParametrosApp.Lectura,
        FDmConn.conUni,
        FContextoSesion.Identidad.Usuario,
        cEventoNoVerifactuFin,
        'Cierre del sistema');
    except
      on E: Exception do
        FRegistroLog.RegistrarError(
          'No se pudo registrar el cierre fiscal: ' + E.Message);
    end;
  end;
end;

procedure TComposicionAplicacion.DetenerProcesosSegundoPlano;
begin
  if Assigned(FProcesosSegundoPlano) then
    FProcesosSegundoPlano.Detener;
end;

procedure TComposicionAplicacion.LiberarRegistrosServicios;
begin
  FServiciosFiltros := CrearServiciosFiltrosGuardados(nil, nil, nil);
  FServiciosPerfiles := CrearServiciosPerfilesUsuario(nil, nil, nil);
  FServiciosParametrosApp.Lectura := nil;
  FServiciosParametrosApp.Edicion := nil;
  FServiciosParametrosApp.GestorLicencia := nil;
  FServiciosParametrosCaja.Lectura := nil;
  FServiciosParametrosCaja.Edicion := nil;
end;

procedure TComposicionAplicacion.Cerrar;
begin
  if not FCerrada then
  begin
    FCerrada := True;
    DetenerProcesosSegundoPlano;
    FreeAndNil(FProcesosSegundoPlano);
    FreeAndNil(FRegistroPantallas);
    if Assigned(FFotos) then
      FFotos.LiberarServicios;
    FreeAndNil(FFotos);
    FreeAndNil(FUnidades);
    if Assigned(FDmConn) then
      FDmConn.AsignarParametrosApp(nil);
    FTraducciones := nil;
    FPermisos := nil;
    FInformesGuias := nil;
    FOperaciones := nil;
    if Assigned(FGestorExcepciones) then
      FGestorExcepciones.AsignarServicioEnvioErrores(nil);
    FServicioEnvioErrores := nil;
    FRepositorioCopias := nil;
    LiberarRegistrosServicios;
    FreeAndNil(FDmFiltros);
    FreeAndNil(FDmPerfiles);
    FAuditoriaDatos := nil;
    if Assigned(FMonitorSQL) then
    begin
      FMonitorSQL.CerrarPendiente;
      FMonitorSQL.EstablecerActivo(False);
      FMonitorSQL.Invalidar;
    end;
    if Assigned(FDmConn) then
      FDmConn.AsignarReceptorMonitorSQL(nil);
    FMonitorSQL := nil;
    if Assigned(FConexiones) then
      FConexiones.Invalidar;
    FConexiones := nil;
    FConfigCampos := nil;
    FConfigCamposCarga := nil;
    FreeAndNil(FDmConn);
    FFabricaConexiones := nil;
    FGestorExcepciones := nil;
    FRegistroMonitorSQL := nil;
    FPreviewTicket := nil;
    FRegistroLog := nil;
    FContextoSesion := nil;
    FOwner := nil;
  end;
end;

end.
