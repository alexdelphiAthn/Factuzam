{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAppParam                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de aplicación configurables.                                   }
{    Definición, carga desde BBDD y acceso tipado a opciones del programa.     }
{******************************************************************************}
unit inLibAppParam;

interface

uses
  System.SyncObjs,
  inLibParametrosIntf, inLibParametrosBase, inLibPerfilesUsuarioIntf,
  inLibLicenciaAplicacion, inLibLogIntf;

type
  TParametrosAplicacion = class(
    TParametrosBase,
    IParametrosAplicacion,
    IGestorLicenciaAplicacion
  )
  private
    FBloqueoLicencia: TCriticalSection;
    FRegistroLog: IRegistroLog;
    FResultadoLicencia: TResultadoLicenciaAplicacion;
    procedure InicializarParametrosApp(
      const AUsuario, AGrupo: string);
  protected
    procedure DespuesDeRecargar; override;
  public
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const ACachePerfiles: ICachePerfilesUsuario;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure EstablecerLicencia(
      const AResultado: TResultadoLicenciaAplicacion);
    function GetPath(const ANombre: string): string;
    function Licencia: TResultadoLicenciaAplicacion;
  end;

function CrearParametrosAplicacion(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const AUsuario, AGrupo: string
): TServiciosParametrosAplicacion;

implementation

uses
  System.SysUtils, inLibPathTokens,
  inLibMsgConfiguracion;

{ TParametrosAplicacion }

constructor TParametrosAplicacion.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  inherited Create(
    APerfilesLectura,
    ACachePerfiles,
    'frmMtoAppParam',
    TArray<string>.Create(
      'WindowState',
      'Left',
      'Top',
      'Width',
      'Height',
      'Divider',
      'appVerifactuIdInstalacion',
      'appVerifactuInstalacionUrl'
    )
  );
  FBloqueoLicencia := TCriticalSection.Create;
  FRegistroLog := ARegistroLog;
  FResultadoLicencia :=
    TResultadoLicenciaAplicacion.CrearNoComprobada;
end;

destructor TParametrosAplicacion.Destroy;
begin
  FRegistroLog := nil;
  FreeAndNil(FBloqueoLicencia);
  inherited;
end;

procedure TParametrosAplicacion.EstablecerLicencia(
  const AResultado: TResultadoLicenciaAplicacion);
begin
  FBloqueoLicencia.Acquire;
  try
    FResultadoLicencia := AResultado;
  finally
    FBloqueoLicencia.Release;
  end;
end;

function TParametrosAplicacion.Licencia:
  TResultadoLicenciaAplicacion;
begin
  FBloqueoLicencia.Acquire;
  try
    Result := FResultadoLicencia;
  finally
    FBloqueoLicencia.Release;
  end;
end;

procedure TParametrosAplicacion.InicializarParametrosApp(
  const AUsuario, AGrupo: string);
begin
  // --- Directorios ---
  RegistrarParametro('Directorios', 'appDirPDF',
    'Carpeta donde se guardan los PDFs', tpString, '');
  RegistrarParametro('Directorios', 'appDirExcel',
    'Carpeta donde se guardan los Excels', tpString, '');
  RegistrarParametro('Directorios', 'appDirCopiasSeguridad',
    'Carpeta de Copias de seguridad', tpString, '');
  RegistrarParametro('Directorios', 'appDirHistoricoCaja',
    'Carpeta de Histórico de Caja', tpString, '');
  RegistrarParametro('Directorios', 'appDirFotos',
    'Carpeta de Fotos de Artículos / SKUs', tpString,
    '$(PUBLICO)\Factuzam\fotos');
  // Numero de atributos del SKU que componen la clave de foto. Vease
  // LIBRO_DE_ESTILO_DELPHI.md 18 ("Sistema de fotos").
  //   0 = una sola foto por articulo (CODIGO_UNIDAD_FOT = '')
  //   1 = una por (articulo, primer atributo).  Ej: ART/COLOR
  //   2 = una por (articulo, primer atributo, segundo atributo)
  //   ...
  // El usuario puede seguir asignando a otro nivel desde el combo del
  // form de fotos; este parametro solo fija el DEFAULT pre-seleccionado.
  RegistrarParametro('Fotos', 'appNumAtributosFoto',
    'Atributos del SKU que componen la clave de foto (0 = solo artículo)',
    tpInteger, '1');
  // Claves históricas ocultas. Se siguen cargando para que las instalaciones
  // existentes mantengan sus valores hasta guardar el conjunto unificado.
  RegistrarParametro('', 'appFotosUrlDescarga',
    'URL histórica del servicio de fotos', tpString,
    'https://webservice.veryverifactu.com/api/v1/');
  RegistrarParametro('', 'appFotosApiKey',
    'API key histórica del servicio de fotos', tpString, '');
  RegistrarParametro('', 'appFotosCarpetaCliente',
    'Referencia histórica del servicio de fotos', tpString, '');
  // --- Servicios web comunes ---
  RegistrarParametro('Servicios web', 'appApiUrl',
    'URL general del servicio web', tpString, '');
  RegistrarParametro('Servicios web', 'appApiToken',
    'API key / token de la instalación', tpString, '');
  RegistrarParametro('Servicios web', 'appApiReferencia',
    'Referencia global de la instalación', tpString, '');
  RegistrarParametro('Servicios web', 'appErroresUrl',
    'URL directa para enviar errores al desarrollador', tpString,
    'https://webservice.veryverifactu.com/error.php');
  RegistrarParametro('Servicios web', 'appVentasWsSegundosCiclo',
    'Segundos entre ciclos de la cola de ventas', tpInteger, '60');
  RegistrarParametro('Servicios web', 'appVentasWsMaxIntentos',
    'Reintentos antes de marcar un envío de venta en ERROR',
    tpInteger, '20');
  RegistrarParametro('', 'appRecuentoUrl',
    'URL histórica del servicio de recuentos', tpString, '');
  RegistrarParametro('', 'appRecuentoApiKey',
    'API key histórica del servicio de recuentos', tpString, '');
  RegistrarParametro('', 'appRecuentoCarpetaCliente',
    'Referencia histórica del servicio de recuentos', tpString, '');
  // --- Impresión ---
  RegistrarParametro('Impresión', 'appImpresoraInformes',
    'Impresora para informes', tpString, '');

  // --- Exportación ---
  RegistrarParametro('Exportación', 'appFormatoHojaCalculo',
    'Formato al guardar hojas de cálculo: xlsx o xls',
    tpString, 'xlsx');

  // --- Apariencia ---
  RegistrarParametro('Apariencia', 'appTema',
    'Tema de interfaz (DevExpress)', tpString, 'Office2019Colorful');
  RegistrarParametro('Apariencia', 'appPaleta',
    'Paleta de color del tema', tpString, 'Default');
  RegistrarParametro('Apariencia', 'appIdioma',
    SDescripcionParametroIdioma, tpString, 'es-ES');

  // --- Consulta de Stock ---
  // Aplica a la pestaña 8_Stock de la ficha de artículo y a la consulta de
  // stock (Ctrl+U). Oculta las líneas a cero para ver sólo lo que hay en
  // stock. En la ficha de artículo, las filas de grupo '-' (almacén sin
  // desglose / duplicado de sumatorio) se ocultan siempre, independientemente
  // de este parámetro.
  RegistrarParametro('Consulta de Stock', 'appStockOcultarCeros',
    'Ocultar líneas a cero en las consultas de stock',
    tpBoolean, 'True');

  // --- Valores por defecto ---
  // NOTA: la tarifa por defecto ya NO se define aquí. La única definición
  // es el parámetro de caja 'vgerDefTarifa', accesible por IParametrosCaja.
  RegistrarParametro('Valores por defecto', 'appTemporadaDefecto',
    'Temporada por defecto (ID de fza_propiedades_valores)',
    tpString, '');

  // --- Seguridad ---
  // Restringe las consultas de documentos y operaciones (facturas,
  // albaranes, pedidos, compras, cajas...) a la empresa/almacén/caja por
  // defecto del usuario (fza_usuarios). Lo consumen inLibFiltroUsuario y
  // las precargas de los Mto; los administradores quedan exentos y solo
  // ellos pueden editarlo (véase UsuarioPuedeEditarParametro).
  RegistrarParametro('Seguridad', 'appRestringirEmpAlmCaja',
    'Restringir consultas a la empresa/almacén/caja del usuario',
    tpBoolean, 'False');

  // --- Arranque ---
  // Precarga de caches de login en paralelo (perfiles, informes-guias,
  // config-campos, permisos), cada una con su propia conexion del pool.
  // Medido MAS LENTO que en serie en instalaciones locales: levantar hilos
  // + conexiones frias del pool cuesta mas que el trabajo real (pequeno).
  // Util solo si la latencia a BBDD fuese muy alta. Por defecto OFF.
  RegistrarParametro('Arranque', 'appArranqueEnParalelo',
    'Precargar las caches de login en paralelo (experimental, normalmente ' +
    'más lento; dejar en False salvo BBDD de muy alta latencia)',
    tpBoolean, 'False');

  // --- Verifactu ---
  // Subsistema Verifactu (AEAT). Los consumen el QR del ticket
  // (inLibVerifactu) y el hilo de la cola (inLibVerifactuCola); se leen
  // en caliente, así que puede activarse sin reiniciar la aplicación.
  RegistrarParametro('Verifactu', 'appVerifactuModo',
    'Modo fiscal: SIN, VERIFACTU o NO_VERIFACTU',
    tpString, 'SIN');
  RegistrarParametro('Verifactu', 'appVerifactuActivo',
    'Activar SIF (False fuerza modo SIN y no imprime QR)',
    tpBoolean, 'False');
  RegistrarParametro('Verifactu', 'appVerifactuFirmaCertificado',
    'Firmar registros y eventos con certificado de empresa',
    tpBoolean, 'False');
  RegistrarParametro('Verifactu', 'appVerifactuNtpServidores',
    'Servidores NTP para validar el reloj fiscal NO VERI*FACTU',
    tpString, 'time.google.com,time.windows.com,pool.ntp.org');
  RegistrarParametro('Verifactu', 'appVerifactuNtpTimeoutMs',
    'Timeout por servidor NTP para control del reloj fiscal',
    tpInteger, '1500');
  RegistrarParametro('Verifactu', 'appVerifactuNtpMargenSegundos',
    'Margen máximo admitido del reloj fiscal en segundos',
    tpInteger, '60');
  RegistrarParametro('Verifactu', 'appVerifactuEntorno',
    'Entorno AEAT: PRE (pruebas) o PRO (producción)', tpString, 'PRE');
  RegistrarParametro('Verifactu', 'appVerifactuUrlQRPre',
    'URL de cotejo del QR en preproducción', tpString,
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR');
  RegistrarParametro('Verifactu', 'appVerifactuUrlQRPro',
    'URL de cotejo del QR en producción', tpString,
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR');
  RegistrarParametro('Verifactu', 'appNoVerifactuUrlQRPre',
    'URL de remisión del QR NO VERI*FACTU en preproducción', tpString,
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQRNoVerifactu');
  RegistrarParametro('Verifactu', 'appNoVerifactuUrlQRPro',
    'URL de remisión del QR NO VERI*FACTU en producción', tpString,
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/' +
    'ValidarQRNoVerifactu');
  RegistrarParametro('Verifactu', 'appVerifactuSegundosCiclo',
    'Segundos entre ciclos del hilo de la cola Verifactu',
    tpInteger, '60');
  RegistrarParametro('Verifactu', 'appVerifactuMaxIntentos',
    'Reintentos de envío antes de marcar ERROR definitivo',
    tpInteger, '10');
  // Endpoints SOAP del envío de registros. Con certificado de sello
  // electrónico usar www10/prewww10 en lugar de www1/prewww1.
  RegistrarParametro('Verifactu', 'appVerifactuUrlEnvioPre',
    'URL del servicio SOAP de envío en preproducción', tpString,
    'https://prewww1.aeat.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/' +
    'VerifactuSOAP');
  RegistrarParametro('Verifactu', 'appVerifactuUrlEnvioPro',
    'URL del servicio SOAP de envío en producción', tpString,
    'https://www1.agenciatributaria.gob.es/wlpl/TIKE-CONT/ws/' +
    'SistemaFacturacion/VerifactuSOAP');
  // Bloque SistemaInformatico del registro (datos del productor del SIF)
  RegistrarParametro('Verifactu', 'appVerifactuSifNombreRazon',
    'Productor del software (SistemaInformatico.NombreRazon)', tpString,
    'Alejandro Laorden Hidalgo');
  RegistrarParametro('Verifactu', 'appVerifactuSifNif',
    'NIF del productor del software (SistemaInformatico.NIF)', tpString,
    '');
  RegistrarParametro('Verifactu', 'appVerifactuSifDireccion',
    'Dirección postal del productor del software', tpString,
    '');
  RegistrarParametro('Verifactu', 'appVerifactuDeclaracionLugar',
    'Lugar de suscripción de la declaración responsable', tpString, '');
  RegistrarParametro('Verifactu', 'appVerifactuDeclaracionFecha',
    'Fecha de suscripción de la declaración responsable', tpString, '');
  RegistrarParametro('Verifactu', 'appVerifactuDescripcionOpe',
    'Texto de DescripcionOperacion del registro de alta', tpString,
    'Venta');

  // --- Log --- (los 4 switches de depuración y traza, agrupados)
  // Modo debug general: activa LogPerf (cronómetros) y detalles MySQL en
  // el popup de error de conUniError. Implica también el modo SQL.
  RegistrarParametro('Log', 'appModoDebug',
    'Modo debug (cronómetros LogPerf + trazado SQL + detalles MySQL)',
    tpBoolean, 'False');
  // Modo debug SQL aislado: enciende UniSQLMonitor y traza cada sentencia
  // al log y al monitor en pantalla.
  RegistrarParametro('Log', 'appModoDebugSQL',
    'Modo debug SQL (traza todas las sentencias en el log)',
    tpBoolean, 'False');
  // Log SQL fino: registra cada consulta con tiempo de ejecución, filas
  // (cuando se conocen) y éxito/fallo. Los valores reales de :param se
  // incluyen porque UniSQLMonitor los entrega ya sustituidos.
  RegistrarParametro('Log', 'appLogSQL',
    'Log SQL (consultas, tiempo de ejecución, filas y parámetros)',
    tpBoolean, 'False');
  // Log avanzado: registra eventos de usuario significativos (apertura
  // / cierre de formularios, inserciones, modificaciones).
  RegistrarParametro('Log', 'appLogAvanzado',
    'Log avanzado (eventos de usuario: unidad, objeto, evento)',
    tpBoolean, 'False');

  Inicializar(AUsuario, AGrupo);
end;

procedure TParametrosAplicacion.DespuesDeRecargar;
begin
  FRegistroLog.AplicarModosDepuracion(
    Self as IParametrosAplicacion);
end;

function TParametrosAplicacion.GetPath(const ANombre: string): string;
begin
  Result := ExpandPathTokens(GetString(ANombre));
end;

function CrearParametrosAplicacion(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const AUsuario, AGrupo: string
): TServiciosParametrosAplicacion;
var
  Parametros: TParametrosAplicacion;
begin
  Parametros := TParametrosAplicacion.Create(
    APerfilesLectura,
    ACachePerfiles,
    ARegistroLog);
  // Los contratos gobiernan la vida del objeto antes de inicializar.
  Result.Lectura := Parametros;
  Result.Edicion := Parametros;
  Result.GestorLicencia := Parametros;
  Parametros.InicializarParametrosApp(AUsuario, AGrupo);
end;

end.
