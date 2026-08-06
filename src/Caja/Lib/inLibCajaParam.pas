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
  System.SyncObjs,
  inLibParametrosIntf, inLibParametrosBase, inLibPerfilesUsuarioIntf,
  inLibContextoSesionIntf;

type
  TParametrosCaja = class(
    TParametrosBase,
    IParametrosCaja
  )
  private
    FBloqueoImpresora: TCriticalSection;
    FContextoSesion: IContextoSesionAplicacion;
    FImpresoraCaja: string;
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
  System.SysUtils, inLibBuscarImpresora, inLibMsgCaja;

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
  FBloqueoImpresora := TCriticalSection.Create;
  FContextoSesion := AContextoSesion;
  FImpresoraCaja := '';
end;

destructor TParametrosCaja.Destroy;
begin
  FContextoSesion := nil;
  FreeAndNil(FBloqueoImpresora);
  inherited;
end;

procedure TParametrosCaja.DespuesDeRecargar;
var
  sImpresora: string;
begin
  sImpresora := GetImpresoraCaja(
    Self as IParametrosCaja,
    FContextoSesion);
  FBloqueoImpresora.Acquire;
  try
    FImpresoraCaja := sImpresora;
  finally
    FBloqueoImpresora.Release;
  end;
end;

function TParametrosCaja.ImpresoraCaja: string;
begin
  FBloqueoImpresora.Acquire;
  try
    Result := FImpresoraCaja;
  finally
    FBloqueoImpresora.Release;
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
