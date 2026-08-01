{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionesUniDAC                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio UniDAC compatible con la conexión principal existente.           }
{******************************************************************************}
unit inLibConexionesUniDAC;

interface

uses
  System.Classes,
  Uni,
  inLibConexionesIntf;

procedure ConfigurarConexionMySQL(
  AConexion: TUniConnection;
  const AUsuario, APassword, AServidor, APuerto, ABaseDatos: string);
procedure ConfigurarYConectarMySQL(
  AConexion: TUniConnection;
  const AUsuario, APassword, AServidor, APuerto, ABaseDatos: string);

type
  TServicioConexionesUniDAC = class(
    TInterfacedObject,
    IServicioConexiones
  )
  private
    FConexionPrincipal: TUniConnection;
    function GetConexionPrincipal: TUniConnection;
    function GetDisponible: Boolean;
    procedure CopiarConfiguracion(
      AConexion: TUniConnection;
      AUso: TUsoConexionTrabajo
    );
  public
    constructor Create(AConexionPrincipal: TUniConnection);
    function CrearConexion(
      AOwner: TComponent;
      AUso: TUsoConexionTrabajo
    ): TUniConnection;
    procedure Invalidar;
  end;

implementation

uses
  System.SysUtils, inLibMsgConfiguracion;

procedure ConfigurarCredencialesMySQL(
  AConexion: TUniConnection;
  const AUsuario, APassword, AServidor, APuerto, ABaseDatos: string);
begin
  AConexion.ConnectString :=
    'Provider Name=MySQL;User ID=' + AUsuario +
    ';Password=' + APassword +
    ';Data Source=' + AServidor +
    ';Database=' + ABaseDatos +
    ';Login Prompt=False';
  AConexion.Server := AServidor;
  AConexion.Database := ABaseDatos;
  AConexion.Username := AUsuario;
  AConexion.Password := APassword;
  AConexion.Port := StrToIntDef(
    APuerto, 3306);
  AConexion.SpecificOptions.Values[
    'MySQL.UseUnicode'] := 'True';
end;

procedure ConfigurarConexionMySQL(
  AConexion: TUniConnection;
  const AUsuario, APassword, AServidor, APuerto, ABaseDatos: string);
begin
  ConfigurarCredencialesMySQL(
    AConexion,
    AUsuario,
    APassword,
    AServidor,
    APuerto,
    ABaseDatos);
  AConexion.SpecificOptions.Values[
    'MySQL.Charset'] := 'utf8mb4';
  AConexion.SpecificOptions.Values[
    'MySQL.Protocol'] := 'mpDefault';
  AConexion.Pooling := True;
  AConexion.PoolingOptions.ConnectionLifetime := 0;
  AConexion.PoolingOptions.Validate := True;
  AConexion.PoolingOptions.MinPoolSize := 3;
  AConexion.PoolingOptions.MaxPoolSize := 20;
  AConexion.SpecificOptions.Values[
    'MySQL.Interactive'] := 'True';
  AConexion.SpecificOptions.Values[
    'ConnectionTimeout'] := '5';
  AConexion.Options.LocalFailover := True;
  AConexion.Options.DisconnectedMode := True;
end;

procedure ConfigurarYConectarMySQL(
  AConexion: TUniConnection;
  const AUsuario, APassword, AServidor, APuerto, ABaseDatos: string);
begin
  ConfigurarCredencialesMySQL(
    AConexion,
    AUsuario,
    APassword,
    AServidor,
    APuerto,
    ABaseDatos);
  if not AConexion.Connected then
  begin
    try
      AConexion.Connect;
    except
      on E: Exception do
      begin
        raise Exception.Create(
          Format(
            SErrorConexionBbddConExcepcion,
            [
              SConnFailBBDD,
              E.ClassName,
              E.Message
            ]));
      end;
    end;
  end;
end;

constructor TServicioConexionesUniDAC.Create(
  AConexionPrincipal: TUniConnection);
begin
  inherited Create;
  FConexionPrincipal := AConexionPrincipal;
end;

function TServicioConexionesUniDAC.GetConexionPrincipal: TUniConnection;
begin
  Result := FConexionPrincipal;
end;

function TServicioConexionesUniDAC.GetDisponible: Boolean;
begin
  Result := Assigned(FConexionPrincipal) and
            FConexionPrincipal.Connected;
end;

procedure TServicioConexionesUniDAC.CopiarConfiguracion(
  AConexion: TUniConnection;
  AUso: TUsoConexionTrabajo);
begin
  AConexion.LoginPrompt := False;
  AConexion.ProviderName := FConexionPrincipal.ProviderName;
  AConexion.Server := FConexionPrincipal.Server;
  AConexion.Port := FConexionPrincipal.Port;
  AConexion.Database := FConexionPrincipal.Database;
  AConexion.Username := FConexionPrincipal.Username;
  AConexion.Password := FConexionPrincipal.Password;
  AConexion.Pooling := True;
  AConexion.PoolingOptions.ConnectionLifetime := 0;
  AConexion.PoolingOptions.Validate := True;
  AConexion.SpecificOptions.Values['MySQL.Interactive'] := 'True';
  AConexion.SpecificOptions.Values['ConnectionTimeout'] := '30';
  AConexion.Options.LocalFailover := True;
  AConexion.Options.DisconnectedMode := True;
  case AUso of
    uctMantenimiento:
      begin
        AConexion.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
        AConexion.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
        AConexion.SpecificOptions.Values['MySQL.Protocol'] := 'mpDefault';
        AConexion.OnError := FConexionPrincipal.OnError;
        AConexion.AfterConnect := FConexionPrincipal.AfterConnect;
      end;
    uctSegundoPlano:
      AConexion.AfterConnect := FConexionPrincipal.AfterConnect;
  end;
end;

function TServicioConexionesUniDAC.CrearConexion(
  AOwner: TComponent;
  AUso: TUsoConexionTrabajo): TUniConnection;
begin
  if not Assigned(FConexionPrincipal) then
    raise Exception.Create(SErrorConexionPrincipalTrabajoNoDisponible);
  Result := TUniConnection.Create(AOwner);
  try
    CopiarConfiguracion(Result, AUso);
    Result.Connect;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TServicioConexionesUniDAC.Invalidar;
begin
  FConexionPrincipal := nil;
end;

end.
