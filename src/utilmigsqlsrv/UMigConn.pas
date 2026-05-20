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
  Uni, UniProvider, MySQLUniProvider, SQLServerUniProvider;

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

end.
