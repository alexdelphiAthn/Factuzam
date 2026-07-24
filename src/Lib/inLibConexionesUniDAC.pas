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
  System.SysUtils;

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
    raise Exception.Create(
      'No hay conexión principal para crear una conexión de trabajo.');
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
