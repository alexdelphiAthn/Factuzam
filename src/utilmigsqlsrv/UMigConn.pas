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

end.
