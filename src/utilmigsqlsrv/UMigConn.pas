{******************************************************************************}
{                                                                              }
{  Módulo:       UMigConn                                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Conexiones del programa de migración SQL Server → MariaDB.                }
{    Mantiene dos TUniConnection: una contra SQL Server (origen, lectura)      }
{    y otra contra MariaDB/MySQL (destino, escritura).                         }
{                                                                              }
{    No persiste credenciales: los parámetros (host, puerto, base, usuario,    }
{    clave) los rellena el formulario antes de conectar. Solo aquí vive la     }
{    configuración de pooling y opciones de UniDAC.                            }
{******************************************************************************}
unit UMigConn;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB,
  Uni, UniScript, UniProvider, MySQLUniProvider, SQLServerUniProvider;

type
  TdmMig = class(TDataModule)
    conSrv:        TUniConnection;
    conDst:        TUniConnection;
    prvSqlServer:  TSQLServerUniProvider;
    prvMySQL:      TMySQLUniProvider;
  public
    procedure ConfigurarOrigen(const sHost, sPort, sBase, sUser,
                               sPwd: string; bWindowsAuth: Boolean = False);
    procedure ConfigurarDestino(const sHost, sPort, sBase, sUser,
                                sPwd: string);
    procedure ProbarOrigen;
    procedure ProbarDestino;

    // Crea una BBDD vacia en el servidor destino con charset utf8mb4 y
    // collation utf8mb4_spanish_ci. Idempotente: si ya existe no hace
    // nada. Tras la llamada, conDst queda configurado con sNombre como
    // Database (pero cerrado).
    procedure CrearBBDDDestino(const sNombre: string);

    // Carga el contenido completo de un .sql (esquema + datos seed) en
    // la BBDD destino actualmente configurada. Usa TUniScript para
    // soportar multiples sentencias separadas por ;.
    procedure CargarEsquemaDestino(const sRutaFichero: string);

    // Borra del destino los datos demo identificados por
    // USUARIO_ALTA IN ('DEMO','Administrador') en las tablas de
    // negocio principales (empresas, almacenes, clientes,
    // proveedores, articulos y familias). NO toca tablas de sistema
    // (paises, ivas_tipos, winforms...). Devuelve cuantas filas
    // borro en total. Util tras cargar factuzam_original.sql.
    function LimpiarDatosDemoDestino: Integer;

    // Borra del destino TODO lo que haya creado una corrida previa
    // del migrador, identificado por USUARIO_ALTA = sUsuario (por
    // defecto 'MIGRADOR'). Procesa las tablas en orden inverso de
    // dependencias (hijos primero) para evitar dejar huerfanos.
    // Devuelve cuantas filas borro en total. Permite re-ejecutar la
    // migracion desde cero sin restos.
    function ResetearMigracionAnterior(const sUsuario: string): Integer;

    // Crea TUniConnection nuevas con los mismos parametros que
    // conSrv/conDst. Pensado para uso desde hilos de trabajo: cada
    // hilo necesita su propia conexion porque UniDAC no soporta uso
    // concurrente. El llamante es duenio del objeto y debe liberarlo.
    function ClonarConexionOrigen:  TUniConnection;
    function ClonarConexionDestino: TUniConnection;
  end;

var
  dmMig: TdmMig;

implementation

{$R *.dfm}

procedure TdmMig.ConfigurarOrigen(const sHost, sPort, sBase, sUser,
                                  sPwd: string;
                                  bWindowsAuth: Boolean = False);
begin
  conSrv.Close;
  conSrv.ProviderName := 'SQL Server';
  conSrv.Server       := sHost;
  if sPort <> '' then
    conSrv.Port := StrToIntDef(sPort, 1433)
  else
    conSrv.Port := 1433;
  conSrv.Database    := sBase;
  conSrv.LoginPrompt := False;
  // Provider: dejamos el default de UniDAC (en general escoge OLE DB
  // nativo si esta el cliente de SQL Server instalado, o protocolo TDS
  // interno si no). Si tu version de UniDAC necesita uno concreto se
  // puede fijar via SpecificOptions['Provider'] (ej 'MSOLEDBSQL',
  // 'SNAC11', 'OLEDB', 'Direct'...).
  if bWindowsAuth then
  begin
    // Autenticación Windows (Integrated Security): el proceso que
    // ejecuta el migrator se identifica ante SQL Server con sus
    // credenciales del SO. No se rellenan Username/Password.
    conSrv.SpecificOptions.Values['Authentication'] := 'auWindows';
    conSrv.Username := '';
    conSrv.Password := '';
  end
  else
  begin
    conSrv.SpecificOptions.Values['Authentication'] := 'auServer';
    conSrv.Username := sUser;
    conSrv.Password := sPwd;
  end;
end;

procedure TdmMig.ConfigurarDestino(const sHost, sPort, sBase, sUser,
                                   sPwd: string);
begin
  conDst.Close;
  conDst.ProviderName := 'MySQL';
  conDst.Server       := sHost;
  if sPort <> '' then
    conDst.Port := StrToIntDef(sPort, 3306)
  else
    conDst.Port := 3306;
  conDst.Database    := sBase;
  conDst.Username    := sUser;
  conDst.Password    := sPwd;
  conDst.LoginPrompt := False;
  conDst.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
end;

procedure TdmMig.ProbarOrigen;
begin
  conSrv.Open;
  // ping mínimo
  conSrv.ExecSQL('SELECT 1');
end;

procedure TdmMig.ProbarDestino;
begin
  conDst.Open;
  conDst.ExecSQL('SELECT 1');
end;

// =========================================================================
//  Crear BBDD destino vacia
// =========================================================================

procedure TdmMig.CrearBBDDDestino(const sNombre: string);
var
  i: Integer;
  c: Char;
  sDbAnterior: string;
begin
  // Validamos el nombre. Solo a-z, A-Z, 0-9, _ — sin backticks, sin
  // espacios, sin acentos. Asi prevenimos inyeccion via identificador.
  if (sNombre = '') or (Length(sNombre) > 64) then
    raise Exception.Create('Nombre de BBDD invalido (vacio o > 64 chars).');
  for i := 1 to Length(sNombre) do
  begin
    c := sNombre[i];
    if not ((c in ['a'..'z']) or (c in ['A'..'Z'])
         or (c in ['0'..'9']) or (c = '_')) then
      raise Exception.CreateFmt(
        'Nombre de BBDD invalido (caracter "%s"). ' +
        'Solo a-z, A-Z, 0-9 y _.', [c]);
  end;

  sDbAnterior := conDst.Database;
  conDst.Close;
  try
    // Conectamos a la BBDD de sistema "mysql" que siempre existe; con
    // ese contexto podemos ejecutar CREATE DATABASE.
    conDst.Database := 'mysql';
    conDst.Open;
    try
      conDst.ExecSQL(Format(
        'CREATE DATABASE IF NOT EXISTS `%s` ' +
        'CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci',
        [sNombre]));
    finally
      conDst.Close;
    end;
  finally
    // Dejamos la conexion apuntando a la nueva BBDD para que el resto
    // del programa (probar, cargar esquema, ejecutar migraciones)
    // trabaje contra ella sin pasos extra.
    conDst.Database := sNombre;
  end;
end;

// =========================================================================
//  Cargar un .sql en el destino
// =========================================================================

procedure TdmMig.CargarEsquemaDestino(const sRutaFichero: string);
var
  oScript: TUniScript;
begin
  if not FileExists(sRutaFichero) then
    raise Exception.CreateFmt('No se encuentra el fichero "%s".',
                              [sRutaFichero]);
  if not conDst.Connected then
    conDst.Open;
  oScript := TUniScript.Create(nil);
  try
    oScript.Connection := conDst;
    oScript.SQL.LoadFromFile(sRutaFichero);
    oScript.Execute;
  finally
    oScript.Free;
  end;
end;

function TdmMig.ClonarConexionOrigen: TUniConnection;
var sAuth: string;
begin
  Result := TUniConnection.Create(nil);
  Result.ProviderName := conSrv.ProviderName;
  Result.Server       := conSrv.Server;
  Result.Port         := conSrv.Port;
  Result.Database     := conSrv.Database;
  Result.Username     := conSrv.Username;
  Result.Password     := conSrv.Password;
  Result.LoginPrompt  := False;
  // Preservar el modo de autenticacion (Windows / SQL).
  sAuth := conSrv.SpecificOptions.Values['Authentication'];
  if sAuth <> '' then
    Result.SpecificOptions.Values['Authentication'] := sAuth;
end;

function TdmMig.ClonarConexionDestino: TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  Result.ProviderName := conDst.ProviderName;
  Result.Server       := conDst.Server;
  Result.Port         := conDst.Port;
  Result.Database     := conDst.Database;
  Result.Username     := conDst.Username;
  Result.Password     := conDst.Password;
  Result.LoginPrompt  := False;
  Result.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
end;

function TdmMig.ResetearMigracionAnterior(
                                  const sUsuario: string): Integer;
const
  // Orden INVERSO de dependencias (hijos primero, padres despues)
  // para que los DELETE no dejen huerfanos en otras tablas.
  aTablas: array[0..22] of string = (
    'fza_inventarios_lineas',
    'fza_inventarios',
    'fza_codigos_barras',
    'fza_atributos_sku',
    'fza_articulos_skus',
    'fza_articulos_atributos_basicos',
    'fza_articulos_conjuntos_asign',
    'fza_articulos_propiedades',
    'fza_articulos_proveedores',
    'fza_propiedades_valores',
    'fza_propiedades',
    'fza_atributos_conjuntos_det',
    'fza_atributos_conjuntos',
    'fza_articulos',
    'fza_articulos_familias',
    'fza_atributos_basicos',
    'fza_atributos_valores',
    'fza_clientes',
    'fza_proveedores',
    'fza_almacenes',
    'fza_empresas',
    'fza_formas_pago',
    'fza_ivas',
    'fza_ivas_grupos'
  );
var
  i, iSub: Integer;
  qDel:    TUniQuery;
  sUser:   string;
begin
  sUser := Trim(sUsuario);
  if sUser = '' then sUser := 'MIGRADOR';
  if not conDst.Connected then conDst.Open;
  Result := 0;
  qDel := TUniQuery.Create(nil);
  try
    qDel.Connection := conDst;
    for i := Low(aTablas) to High(aTablas) do
    begin
      qDel.SQL.Text := Format(
        'DELETE FROM `%s` WHERE USUARIO_ALTA = :u', [aTablas[i]]);
      qDel.ParamByName('u').AsString := sUser;
      qDel.ExecSQL;
      iSub := qDel.RowsAffected;
      if iSub > 0 then
        Inc(Result, iSub);
    end;
  finally
    qDel.Free;
  end;
end;

function TdmMig.LimpiarDatosDemoDestino: Integer;
const
  // Orden importante: hijos primero (FK logicas), padres despues.
  // En cada tabla borramos solo lo que dejo el seed demo.
  aTablas: array[0..5] of string = (
    'fza_articulos',
    'fza_articulos_familias',
    'fza_almacenes',
    'fza_clientes',
    'fza_proveedores',
    'fza_empresas'
  );
var
  i, iSub: Integer;
  qDel:    TUniQuery;
begin
  if not conDst.Connected then conDst.Open;
  Result := 0;
  qDel := TUniQuery.Create(nil);
  try
    qDel.Connection := conDst;
    for i := Low(aTablas) to High(aTablas) do
    begin
      qDel.SQL.Text := Format(
        'DELETE FROM `%s` ' +
        'WHERE USUARIO_ALTA IN (''DEMO'', ''Administrador'', ' +
        '                       ''Sistema'', ''SISTEMA'')',
        [aTablas[i]]);
      qDel.ExecSQL;
      iSub := qDel.RowsAffected;
      if iSub > 0 then
        Inc(Result, iSub);
    end;
  finally
    qDel.Free;
  end;
end;

end.
