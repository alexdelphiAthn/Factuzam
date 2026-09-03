{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaParam                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de configuración del punto de venta.                           }
{    Definición, carga desde BBDD y acceso tipado a opciones de caja.          }
{******************************************************************************}
unit inLibCajaParam;

interface

uses
  inLibParametrosIntf, inLibParametrosBase, inLibPerfilesUsuarioIntf,
  inLibContextoSesionIntf;

type
  TParametrosCaja = class(
    TParametrosBase,
    IParametrosCaja
  )
  private
    FContextoSesion: IContextoSesionAplicacion;
    FEstadoDeteccionImpresora: IInterface;
    function SegundosEsperaDeteccionImpresora: Integer;
    procedure IniciarDeteccionImpresora;
    procedure RegistrarControlArticulos;
    procedure RegistrarConfiguracionCaja;
    procedure RegistrarDevolucionesYVales;
    procedure RegistrarAvisosYBusquedas;
    procedure RegistrarLectorCodigoBarras;
    procedure RegistrarImpresion;
    procedure RegistrarEmpleado;
    procedure RegistrarPermisosYArqueo;
    procedure InicializarParametrosCaja(
      const AUsuario, AGrupo: string);
  protected
    procedure DespuesDeRecargar; override;
  public
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const ACachePerfiles: ICachePerfilesUsuario;
      const AContextoSesion: IContextoSesionAplicacion);
    destructor Destroy; override;
    function ImpresoraCaja: string;
    function NivelesFamiliaArqueo: Integer;
    function TarifaDefecto: string;
  end;

function CrearParametrosCaja(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion;
  const AUsuario, AGrupo: string
): TServiciosParametrosCaja;

implementation

uses
  System.Classes, System.SyncObjs, System.SysUtils, Winapi.Windows,
  inLibArqueoDesglose, inLibBuscarImpresora, inLibMsgCaja;

const
  cIntervaloDeteccionImpresoraMs = 1000;
  cMaximoEsperaDeteccionImpresoraSegundos = 300;
  cParametroEsperaDeteccionImpresora =
    'vgerImpresoraEsperaSegundos';

procedure InformarFalloSecundarioEnDepurador(
  const AContexto: PChar;
  E: Exception);
begin
  try
    OutputDebugString(PChar(
      string(AContexto) + ': ' + E.ClassName + ': ' + E.Message));
  except
    OutputDebugString(AContexto);
  end;
end;

type
  IEstadoDeteccionImpresora = interface
    ['{0B5F543D-E73A-48FC-A7FD-91BD12E74B4A}']
    procedure Cancelar;
    procedure Completar(
      AGeneracion: Integer;
      const ANombreImpresora: string);
    function EstaVigente(AGeneracion: Integer): Boolean;
    procedure Preparar(
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer;
      out AIniciarTrasRecarga: Boolean);
    procedure RestablecerInicio(AGeneracion: Integer);
    procedure Solicitar(
      out AIniciar: Boolean;
      out AGeneracion: Integer;
      out APatronImpresora, AArchivoCache: string;
      out ASegundosEspera: Integer);
    function ValorActual: string;
  end;

  TEstadoDeteccionImpresora = class(
    TInterfacedObject,
    IEstadoDeteccionImpresora
  )
  private
    FArchivoCache: string;
    FBloqueo: TCriticalSection;
    FGeneracion: Integer;
    FIniciada: Boolean;
    FPatronImpresora: string;
    FPreparada: Boolean;
    FSegundosEspera: Integer;
    FValorActual: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancelar;
    procedure Completar(
      AGeneracion: Integer;
      const ANombreImpresora: string);
    function EstaVigente(AGeneracion: Integer): Boolean;
    procedure Preparar(
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer;
      out AIniciarTrasRecarga: Boolean);
    procedure RestablecerInicio(AGeneracion: Integer);
    procedure Solicitar(
      out AIniciar: Boolean;
      out AGeneracion: Integer;
      out APatronImpresora, AArchivoCache: string;
      out ASegundosEspera: Integer);
    function ValorActual: string;
  end;

  THiloDeteccionImpresora = class(TThread)
  private
    FArchivoCache: string;
    FEstado: IEstadoDeteccionImpresora;
    FGeneracion: Integer;
    FPatronImpresora: string;
    FSegundosEspera: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AEstado: IEstadoDeteccionImpresora;
      AGeneracion: Integer;
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer);
  end;

{ TEstadoDeteccionImpresora }

constructor TEstadoDeteccionImpresora.Create;
begin
  inherited Create;
  FBloqueo := TCriticalSection.Create;
end;

destructor TEstadoDeteccionImpresora.Destroy;
begin
  FreeAndNil(FBloqueo);
  inherited;
end;

procedure TEstadoDeteccionImpresora.Cancelar;
begin
  FBloqueo.Acquire;
  try
    Inc(FGeneracion);
    FIniciada := True;
    FArchivoCache := '';
    FPatronImpresora := '';
    FValorActual := '';
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.Completar(
  AGeneracion: Integer;
  const ANombreImpresora: string);
begin
  FBloqueo.Acquire;
  try
    if FGeneracion = AGeneracion then
      FValorActual := ANombreImpresora;
  finally
    FBloqueo.Release;
  end;
end;

function TEstadoDeteccionImpresora.EstaVigente(
  AGeneracion: Integer): Boolean;
begin
  FBloqueo.Acquire;
  try
    Result := FIniciada and (FGeneracion = AGeneracion);
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.Preparar(
  const APatronImpresora, AArchivoCache: string;
  ASegundosEspera: Integer;
  out AIniciarTrasRecarga: Boolean);
begin
  FBloqueo.Acquire;
  try
    AIniciarTrasRecarga := FPreparada;
    FPreparada := True;
    Inc(FGeneracion);
    FArchivoCache := AArchivoCache;
    FIniciada := (APatronImpresora = '') or
      SameText(APatronImpresora, 'DEBUG');
    FPatronImpresora := APatronImpresora;
    FSegundosEspera := ASegundosEspera;
    if SameText(APatronImpresora, 'DEBUG') then
      FValorActual := 'DEBUG'
    else
      FValorActual := '';
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.RestablecerInicio(
  AGeneracion: Integer);
begin
  FBloqueo.Acquire;
  try
    if FGeneracion = AGeneracion then
      FIniciada := False;
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.Solicitar(
  out AIniciar: Boolean;
  out AGeneracion: Integer;
  out APatronImpresora, AArchivoCache: string;
  out ASegundosEspera: Integer);
begin
  FBloqueo.Acquire;
  try
    AIniciar := not FIniciada;
    if AIniciar then
      FIniciada := True;
    AGeneracion := FGeneracion;
    APatronImpresora := FPatronImpresora;
    AArchivoCache := FArchivoCache;
    ASegundosEspera := FSegundosEspera;
  finally
    FBloqueo.Release;
  end;
end;

function TEstadoDeteccionImpresora.ValorActual: string;
begin
  FBloqueo.Acquire;
  try
    Result := FValorActual;
  finally
    FBloqueo.Release;
  end;
end;

function EstadoDeteccionImpresora(
  const AEstado: IInterface): IEstadoDeteccionImpresora;
begin
  Result := AEstado as IEstadoDeteccionImpresora;
end;

function BuscarImpresoraSegura(
  const APatronImpresora, AArchivoCache: string): string;
begin
  try
    Result := ObtenerImpresoraPorPatronCached(
      APatronImpresora,
      AArchivoCache);
  except
    Result := '';
  end;
end;

procedure EjecutarDeteccionImpresora(
  const AEstado: IEstadoDeteccionImpresora;
  AGeneracion: Integer;
  const APatronImpresora, AArchivoCache: string;
  ASegundosEspera: Integer);
var
  iAhora: UInt64;
  iEsperaMs: Cardinal;
  iLimite: UInt64;
  iRestanteMs: UInt64;
  sImpresora: string;
begin
  sImpresora := '';
  iLimite := GetTickCount64 + UInt64(ASegundosEspera) * 1000;
  try
    TThread.NameThreadForDebugging('DetectorImpresoraTickets');
    // Winspool no permite cancelar una enumeración ya iniciada.
    if AEstado.EstaVigente(AGeneracion) then
      sImpresora := BuscarImpresoraSegura(
        APatronImpresora,
        AArchivoCache);
    iAhora := GetTickCount64;
    while (sImpresora = '') and
          AEstado.EstaVigente(AGeneracion) and
          (iAhora < iLimite) do
    begin
      iRestanteMs := iLimite - iAhora;
      if iRestanteMs > cIntervaloDeteccionImpresoraMs then
        iEsperaMs := cIntervaloDeteccionImpresoraMs
      else
        iEsperaMs := Cardinal(iRestanteMs);
      Sleep(iEsperaMs);
      if AEstado.EstaVigente(AGeneracion) and
         (GetTickCount64 <= iLimite) then
      begin
        sImpresora := BuscarImpresoraSegura(
          APatronImpresora,
          AArchivoCache);
      end;
      iAhora := GetTickCount64;
    end;
  finally
    if AEstado.EstaVigente(AGeneracion) then
      AEstado.Completar(AGeneracion, sImpresora);
  end;
end;

{ THiloDeteccionImpresora }

constructor THiloDeteccionImpresora.Create(
  const AEstado: IEstadoDeteccionImpresora;
  AGeneracion: Integer;
  const APatronImpresora, AArchivoCache: string;
  ASegundosEspera: Integer);
begin
  inherited Create(True);
  FArchivoCache := AArchivoCache;
  FEstado := AEstado;
  FGeneracion := AGeneracion;
  FPatronImpresora := APatronImpresora;
  FSegundosEspera := ASegundosEspera;
  FreeOnTerminate := True;
end;

procedure THiloDeteccionImpresora.Execute;
begin
  EjecutarDeteccionImpresora(
    FEstado,
    FGeneracion,
    FPatronImpresora,
    FArchivoCache,
    FSegundosEspera);
end;

procedure LanzarDeteccionImpresora(
  const AEstado: IEstadoDeteccionImpresora;
  AGeneracion: Integer;
  const APatronImpresora, AArchivoCache: string;
  ASegundosEspera: Integer);
var
  oHilo: THiloDeteccionImpresora;
begin
  oHilo := THiloDeteccionImpresora.Create(
    AEstado,
    AGeneracion,
    APatronImpresora,
    AArchivoCache,
    ASegundosEspera);
  try
    oHilo.Start;
  except
    oHilo.Free;
    raise;
  end;
end;

{ TParametrosCaja }

constructor TParametrosCaja.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion);
begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create(
      SErrorContextoImpresoraCajaNoProporcionado);
  inherited Create(
    APerfilesLectura,
    ACachePerfiles,
    'frmMtoCajaParam',
    TArray<string>.Create(
      'WindowState',
      'Left',
      'Top',
      'Width',
      'Height',
      'Divider'
    )
  );
  FContextoSesion := AContextoSesion;
  FEstadoDeteccionImpresora := TEstadoDeteccionImpresora.Create;
end;

destructor TParametrosCaja.Destroy;
var
  oEstado: IEstadoDeteccionImpresora;
begin
  if Assigned(FEstadoDeteccionImpresora) then
  begin
    oEstado := EstadoDeteccionImpresora(FEstadoDeteccionImpresora);
    oEstado.Cancelar;
  end;
  FEstadoDeteccionImpresora := nil;
  FContextoSesion := nil;
  inherited;
end;

procedure TParametrosCaja.DespuesDeRecargar;
var
  bIniciarTrasRecarga: Boolean;
  oEstado: IEstadoDeteccionImpresora;
  sArchivoCache: string;
  sPatronImpresora: string;
begin
  sPatronImpresora := Trim(GetString('vgerDefPrinter', 'DEBUG'));
  sArchivoCache := Format('Caja_%s.cache',
    [FContextoSesion.Identidad.Usuario]);
  oEstado := EstadoDeteccionImpresora(FEstadoDeteccionImpresora);
  oEstado.Preparar(
    sPatronImpresora,
    sArchivoCache,
    SegundosEsperaDeteccionImpresora,
    bIniciarTrasRecarga);
  if bIniciarTrasRecarga then
    IniciarDeteccionImpresora;
end;

function TParametrosCaja.SegundosEsperaDeteccionImpresora: Integer;
begin
  Result := GetInt(cParametroEsperaDeteccionImpresora, 5);
  if Result < 0 then
    Result := 0;
  if Result > cMaximoEsperaDeteccionImpresoraSegundos then
    Result := cMaximoEsperaDeteccionImpresoraSegundos;
end;

procedure TParametrosCaja.IniciarDeteccionImpresora;
var
  bIniciar: Boolean;
  iGeneracion: Integer;
  iSegundosEspera: Integer;
  oEstado: IEstadoDeteccionImpresora;
  sArchivoCache: string;
  sPatronImpresora: string;
begin
  oEstado := EstadoDeteccionImpresora(FEstadoDeteccionImpresora);
  oEstado.Solicitar(
    bIniciar,
    iGeneracion,
    sPatronImpresora,
    sArchivoCache,
    iSegundosEspera);
  if bIniciar then
  begin
    try
      LanzarDeteccionImpresora(
        oEstado,
        iGeneracion,
        sPatronImpresora,
        sArchivoCache,
        iSegundosEspera);
    except
      oEstado.RestablecerInicio(iGeneracion);
    end;
  end;
end;

function TParametrosCaja.ImpresoraCaja: string;
var
  oEstado: IEstadoDeteccionImpresora;
begin
  oEstado := EstadoDeteccionImpresora(FEstadoDeteccionImpresora);
  Result := oEstado.ValorActual;
  try
    IniciarDeteccionImpresora;
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inLibCajaParam.ImpresoraCaja.IniciarDeteccionImpresora', E);
  end;
end;

procedure TParametrosCaja.InicializarParametrosCaja(
  const AUsuario, AGrupo: string);
begin
  RegistrarControlArticulos;
  RegistrarConfiguracionCaja;
  RegistrarDevolucionesYVales;
  RegistrarAvisosYBusquedas;
  RegistrarLectorCodigoBarras;
  RegistrarImpresion;
  RegistrarEmpleado;
  RegistrarPermisosYArqueo;
  Inicializar(AUsuario, AGrupo);
end;

procedure TParametrosCaja.RegistrarControlArticulos;
begin
  RegistrarParametro('Control de Artículos',
                     'vgerChkExistOnly',
                     'Permitir sólo artículos que existan',
                     tpBoolean,
                     'True');
  RegistrarParametro('Control de Artículos',
                     'vgerChkStockOnly',
                     'Permitir sólo artículos con stock',
                     tpBoolean,
                     'False');
end;

procedure TParametrosCaja.RegistrarConfiguracionCaja;
begin
  RegistrarParametro('Configuración de Caja',
                     'vgerShowCajaSelection',
                     'Presentar selección de caja',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerFillEmpleadoDefecto',
                     'Rellenar empleado por defecto al abrir',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerDefTarifa',
                     'Tarifa por defecto en caja',
                     tpString,
                     'PVP');
  RegistrarParametro('Configuración de Caja',
                     'vgerMaxOpPending',
                     'Número de operaciones pendientes',
                     tpInteger,
                     '5');
  RegistrarParametro('Configuración de Caja',
                     'vgerAutoLoadDepositos',
                     'Cargar depósitos automáticamente al seleccionar cliente',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerAgruparUnidadesIguales',
                     'Agrupar unidades iguales en una sola línea',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerAplazarRecalculoMovimientos',
                     'Aplazar recálculos de stock de caja y albaranes',
                     tpBoolean,
                     'False');
  RegistrarParametro('Servicios web',
                     'vgerEnviarVentasWS',
                     'Enviar ventas completas al webservice de respaldo',
                     tpBoolean,
                     'False');
end;

procedure TParametrosCaja.RegistrarDevolucionesYVales;
begin
  RegistrarParametro('Devoluciones y Vales',
                     'vgerReqRefDevolucion',
                     'Pedir referencia en devoluciones',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerRecuperaValePIN',
                     'Recuperar Vale sólo con PIN',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerCaducidadDefVale',
                     'Caducidad por defecto en vale',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerDiasCaducidadVale',
                     'Días hasta caducidad en vale',
                     tpInteger,
                     '365');
end;

procedure TParametrosCaja.RegistrarAvisosYBusquedas;
begin
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerAvisoStockWarning',
                     'Aviso en artículos sin stock',
                     tpString,
                     'Artículo sin stock. Compruebe stock en almacén.');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerAvisoHuecosNumeracion',
                     'Avisar de huecos en la numeración de ventas',
                     tpBoolean,
                     'True');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtStockOnly',
                     'Búsqueda de artículos sólo con stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtTarifaOnly',
                     'Búsqueda de artículos sólo con tarifa',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerStockTodosColores',
                     'Mostrar todos los colores por separado en el stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerMoverLineaIdentif',
                     'Mover linea al identificar artículo',
                     tpBoolean,
                     'False');
end;

procedure TParametrosCaja.RegistrarLectorCodigoBarras;
begin
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanVelActivo',
                     'Detectar lecturas por velocidad de tecleo (código + CR)',
                     tpBoolean,
                     'True');
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanVelMs',
                     'Máx. ms entre teclas para considerarlo lectura',
                     tpInteger,
                     '40');
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanMinLong',
                     'Longitud mínima del código para aceptar la lectura',
                     tpInteger,
                     '4');
end;

procedure TParametrosCaja.RegistrarImpresion;
begin
  RegistrarParametro('Impresión',
                     'vgerDefPrinter',
                     'Nombre impresora de tickets',
                     tpString,
                     '');
  RegistrarParametro('Impresión',
                     cParametroEsperaDeteccionImpresora,
                     'Espera para detectar la impresora al arrancar ' +
                     '(0-300 segundos)',
                     tpInteger,
                     '5');
  RegistrarParametro('Impresión',
                     'vgerTipoImpresion',
                     'Tipo de Impresión tickets',
                     tpString,
                     'ESC POS');
  RegistrarParametro('Impresión',
                     'vgerFormatoImpPredet',
                     'Formato de impresión predeterminado',
                     tpString,
                     '');
  RegistrarParametro('Impresión',
                     'vgerImprimirCodBarrasTicket',
                     'Imprimir código de barras EAN13 del ticket',
                     tpBoolean,
                     'False');
end;

procedure TParametrosCaja.RegistrarEmpleado;
begin
  RegistrarParametro('Empleado',
                     'vgerCodEmpleadoDefecto',
                     'Código de empleado por defecto',
                     tpString,
                     '');
  RegistrarParametro('Empleado',
                     'vgerShowEmpleadoLinea',
                     'Mostrar empleado en linea de caja',
                     tpBoolean,
                     'True');
end;

procedure TParametrosCaja.RegistrarPermisosYArqueo;
begin
  RegistrarParametro('Permisos Extra',
                     'vgerArqueoTarjetas',
                     'Permitir Arqueo de Tarjetas',
                     tpBoolean,
                     'False');
  RegistrarParametro('Permisos Extra',
                     'vgerVentasCredito',
                     'Permitir Ventas a Crédito',
                     tpBoolean,
                     'True');
  RegistrarParametro('Permisos Extra',
                     'vgerDescuentos',
                     'Permite descuentos en ventas',
                     tpBoolean,
                     'True');
  RegistrarParametro('Arqueo',
                     'vgerArqueoNivelesFamilia',
                     'Niveles de familia en resumen por sección (1=sección)',
                     tpInteger,
                     '2');
  RegistrarParametro('Arqueo',
                     'vgerArqueoEditarCambio',
                     'Permitir editar el cambio dejado para la ' +
                     'siguiente jornada',
                     tpBoolean,
                     'False');
  RegistrarParametro('Arqueo',
                     'vgerArqueoEmitirJustificante',
                     'Emitir justificante al grabar el cierre',
                     tpBoolean,
                     'True');
  RegistrarParametro('Arqueo',
                     'vgerArqueoRecuentoDetallado',
                     'Recuento detallado de billetes y monedas',
                     tpBoolean,
                     'False');
  RegistrarParametro('Arqueo',
                     'vgerArqueoDenominaciones',
                     'Denominaciones del recuento detallado ' +
                     'separadas por punto y coma',
                     tpString,
                     DenominacionesArqueoPorDefecto);
end;

function TParametrosCaja.NivelesFamiliaArqueo: Integer;
begin
  Result := GetInt('vgerArqueoNivelesFamilia', 2);
  if Result < 1 then
    Result := 1;
  if Result > 9 then
    Result := 9;
end;

function TParametrosCaja.TarifaDefecto: string;
begin
  Result := GetString('vgerDefTarifa', 'PVP');
end;

function CrearParametrosCaja(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion;
  const AUsuario, AGrupo: string
): TServiciosParametrosCaja;
var
  Parametros: TParametrosCaja;
begin
  Parametros := TParametrosCaja.Create(
    APerfilesLectura,
    ACachePerfiles,
    AContextoSesion);
  // Los contratos gobiernan la vida del objeto antes de inicializar.
  Result.Lectura := Parametros;
  Result.Edicion := Parametros;
  Parametros.InicializarParametrosCaja(AUsuario, AGrupo);
end;

end.
