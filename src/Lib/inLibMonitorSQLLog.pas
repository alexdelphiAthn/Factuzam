{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMonitorSQLLog                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador entre el servicio de monitor SQL y el registro TLog.            }
{******************************************************************************}
unit inLibMonitorSQLLog;

interface

uses
  inLibLog,
  inLibMonitorSQLIntf;

type
  TRegistroMonitorSQLLog = class(
    TInterfacedObject,
    IRegistroMonitorSQL
  )
  private
    FLog: TLog;
    function GetMonitorizacionActiva: Boolean;
  public
    constructor Create(ALog: TLog);
    procedure RegistrarSQL(
      const ASQL: string;
      ATiempoMs: Int64;
      AOk: Boolean;
      const AError: string
    );
    procedure MostrarSQL(const ASQL: string);
  end;

implementation

constructor TRegistroMonitorSQLLog.Create(ALog: TLog);
begin
  inherited Create;
  FLog := ALog;
end;

function TRegistroMonitorSQLLog.GetMonitorizacionActiva: Boolean;
begin
  Result := Assigned(FLog) and
            FLog.IsLogTypeEnabled(ltSQL);
end;

procedure TRegistroMonitorSQLLog.RegistrarSQL(
  const ASQL: string;
  ATiempoMs: Int64;
  AOk: Boolean;
  const AError: string);
begin
  if Assigned(FLog) then
    FLog.LogSQLExt(ASQL, ATiempoMs, -1, AOk, AError);
end;

procedure TRegistroMonitorSQLLog.MostrarSQL(const ASQL: string);
begin
  if Assigned(FLog) then
    FLog.MostrarSQLMonitor(ASQL);
end;

end.
