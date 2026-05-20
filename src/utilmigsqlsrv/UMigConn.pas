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
                               sPwd: string);
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
                                  sPwd: string);
begin
  conSrv.Close;
  conSrv.ProviderName := 'SQL Server';
  conSrv.Server       := sHost;
  if sPort <> '' then
    conSrv.Port := StrToIntDef(sPort, 1433)
  else
    conSrv.Port := 1433;
  conSrv.Database    := sBase;
  conSrv.Username    := sUser;
  conSrv.Password    := sPwd;
  conSrv.LoginPrompt := False;
  // OLE DB nativo cuando el cliente de SQL Server está instalado.
  // Si falla, UniDAC cae al protocolo TDS interno automáticamente.
  conSrv.SpecificOptions.Values['Provider'] := 'Auto';
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
