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
  System.Generics.Collections, System.SysUtils, Uni;

type
  TTipoParametro = (tpString, tpInteger, tpBoolean);

  TAppParamDef = class
  public
    Categoria      : string;
    Nombre         : string;
    Descripcion    : string;
    Tipo           : TTipoParametro;
    ValorPorDefecto: string;
    ValorActual    : string;
    constructor Create(const ACategoria, ANombre, ADesc: string;
                       ATipo: TTipoParametro; const ADefecto: string);
  end;

  TAppParams = class
  private
    FConexion: TUniConnection;
    FParams: TObjectDictionary<string, TAppParamDef>;
    procedure CargarDesdeDB(const AUsuario, AGrupo: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AsignarConexion(AConexion: TUniConnection);
    procedure RegistrarParametro(const ACategoria, ANombre, ADesc: string;
                                 ATipo: TTipoParametro; const ADefecto: string);
    procedure RegistrarDefectos;
    procedure InicializarParametrosApp(const AUsuario, AGrupo: string);
    procedure Inicializar(const AUsuario, AGrupo: string);
    procedure Recargar(const AUsuario, AGrupo: string);
    // Sincroniza los flags del singleton Log (inLibLog) con los parametros
    // booleanos appLogSQL / appLogAvanzado. Se llama tras Inicializar y
    // tras Recargar para aplicar los cambios sin reiniciar.
    procedure AplicarFlagsLog;
    function GetPath(const ANombre: string): string;
    function GetString(const AKey: string; const ADefault: string = '' ): string;
    function GetBool  (const AKey: string;
                       const ADefault: Boolean  = False): Boolean;
    function GetInt (const AKey: string; const ADefault: Integer = 0 ): Integer;

    property Params: TObjectDictionary<string, TAppParamDef> read FParams;
  end;

var
  oAppParams: TAppParams;

implementation

uses
  System.StrUtils, inLibPathTokens, inLibLog;

{ TAppParamDef }

constructor TAppParamDef.Create(const ACategoria, ANombre, ADesc: string;
                                ATipo: TTipoParametro; const ADefecto: string);
begin
  Categoria       := ACategoria;
  Nombre          := ANombre;
  Descripcion     := ADesc;
  Tipo            := ATipo;
  ValorPorDefecto := ADefecto;
  ValorActual     := ADefecto;
end;

{ TAppParams }

constructor TAppParams.Create;
begin
  inherited;
  FConexion := nil;
  FParams := TObjectDictionary<string, TAppParamDef>.Create([doOwnsValues]);
end;

destructor TAppParams.Destroy;
begin
  FreeAndNil(FParams);
  inherited;
end;

procedure TAppParams.RegistrarParametro(const ACategoria,
                                        ANombre,
                                        ADesc: string;
                                        ATipo: TTipoParametro;
                                        const ADefecto: string);
begin
  FParams.AddOrSetValue(ANombre,
    TAppParamDef.Create(ACategoria, ANombre, ADesc, ATipo, ADefecto));
end;

procedure TAppParams.RegistrarDefectos;
var
  Param: TAppParamDef;
begin
  for Param in FParams.Values do
    Param.ValorActual := Param.ValorPorDefecto;
end;

procedure TAppParams.AsignarConexion(AConexion: TUniConnection);
begin
  FConexion := AConexion;
end;

procedure TAppParams.CargarDesdeDB(const AUsuario, AGrupo: string);
var
  qry    : TUniQuery;
  KeyDB  : string;
  ValueDB: string;
  ParamObj: TAppParamDef;
begin
  RegistrarDefectos;
  if (FConexion = nil) or (not FConexion.Connected) then
    raise Exception.Create(
      'TAppParams requiere una conexión activa');
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := FConexion;
    qry.SQL.Text   :=
      'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := AUsuario;
    qry.ParamByName('p_grupo').AsString      := AGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoAppParam';
    qry.Open;
    while not qry.Eof do
    begin
      KeyDB   := qry.FieldByName('SUBKEY_USUPER').AsString;
      ValueDB := qry.FieldByName('VALUE_USUPER').AsString;
      // Las claves de geometría/layout (WindowState, Left, Top, Width,
      // Height, Divider) se persisten bajo el mismo KEY_USUPER que los
      // parámetros (véase inLibLayoutForm.TLayoutSaver). No son parámetros
      // configurables. appVerifactuIdInstalacion queda obsoleto: el número
      // de instalación SIF se guarda por empresa en fza_empresas.
      if not MatchText(KeyDB, ['WindowState', 'Left', 'Top', 'Width',
                               'Height', 'Divider',
                               'appVerifactuIdInstalacion',
                               'appVerifactuInstalacionUrl']) then
      begin
        if FParams.TryGetValue(KeyDB, ParamObj) then
          ParamObj.ValorActual := ValueDB
        else
        begin
          // Parámetro huérfano en BD → lo registramos para que siga visible
          RegistrarParametro('Otros (Heredados de BD)', KeyDB,
                             'Parámetro sin descripción', tpString, ValueDB);
          FParams.Items[KeyDB].ValorActual := ValueDB;
        end;
      end;
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TAppParams.Inicializar(const AUsuario, AGrupo: string);
begin
  CargarDesdeDB(AUsuario, AGrupo);
end;

procedure TAppParams.InicializarParametrosApp(const AUsuario, AGrupo: string);
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

  // --- Apariencia ---
  RegistrarParametro('Apariencia', 'appTema',
    'Tema de interfaz (DevExpress)', tpString, 'Office2019Colorful');
  RegistrarParametro('Apariencia', 'appPaleta',
    'Paleta de color del tema', tpString, 'Default');

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
  // es el parámetro de caja 'vgerDefTarifa' (inLibCajaParam.TarifaDefecto).
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
    'Calle Cascajal, 7 1ºB 49159 Villaralbo (Zamora)');
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
  AplicarFlagsLog;
end;

procedure TAppParams.Recargar(const AUsuario, AGrupo: string);
begin
  CargarDesdeDB(AUsuario, AGrupo);
  AplicarFlagsLog;
end;

procedure TAppParams.AplicarFlagsLog;
begin
  // Delegamos en inLibLog.AplicarModosDepuracion: es la unica fuente de
  // verdad para los 4 flags (appModoDebug, appModoDebugSQL, appLogSQL,
  // appLogAvanzado) y se ocupa tambien del UniSQLMonitor y del memo SQL.
  AplicarModosDepuracion;
end;

function TAppParams.GetString(const AKey: string; const ADefault: string): string;
var
  ParamObj: TAppParamDef;
begin
  if FParams.TryGetValue(AKey, ParamObj) then
    Result := ParamObj.ValorActual
  else
    Result := ADefault;
end;

function TAppParams.GetBool(const AKey: string; const ADefault: Boolean): Boolean;
var
  ParamObj: TAppParamDef;
  sVal: string;
begin
  if FParams.TryGetValue(AKey, ParamObj) then
  begin
    sVal   := ParamObj.ValorActual;
    Result := SameText(sVal, 'True') or (sVal = '1');
  end
  else
    Result := ADefault;
end;

function TAppParams.GetInt(const AKey: string; const ADefault: Integer): Integer;
var
  ParamObj: TAppParamDef;
begin
  if FParams.TryGetValue(AKey, ParamObj) then
  begin
    if not TryStrToInt(ParamObj.ValorActual, Result) then
      Result := ADefault;
  end
  else
    Result := ADefault;
end;

function TAppParams.GetPath(const ANombre: string): string;
begin
  Result := ExpandPathTokens(GetString(ANombre));
end;

initialization
  oAppParams := TAppParams.Create;

finalization
  FreeAndNil(oAppParams);

end.
