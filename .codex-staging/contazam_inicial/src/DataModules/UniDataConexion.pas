{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConexion                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Propietario de la conexión MariaDB independiente de Contazam.             }
{******************************************************************************}
unit UniDataConexion;

interface

uses
  System.Classes, Uni, MySQLUniProvider, inLibConfiguracion;

type
  TdmConexion = class(TDataModule)
  private
    FConexion: TUniConnection;
    FProveedor: TMySQLUniProvider;
  public
    constructor Create(
      AOwner: TComponent;
      const AConfiguracion: TConfiguracionContazam); reintroduce;
    property Conexion: TUniConnection read FConexion;
  end;

implementation

uses
  System.SysUtils, Data.DB;

constructor TdmConexion.Create(
  AOwner: TComponent;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited CreateNew(AOwner);
  FProveedor := TMySQLUniProvider.Create(Self);
  FConexion := TUniConnection.Create(Self);
  FConexion.ProviderName := 'MySQL';
  FConexion.Server := AConfiguracion.Servidor;
  FConexion.Port := AConfiguracion.Puerto;
  FConexion.Username := AConfiguracion.Usuario;
  FConexion.Password := AConfiguracion.Contrasena;
  FConexion.Database := AConfiguracion.BaseDatos;
  FConexion.Pooling := True;
  FConexion.Options.LocalFailover := True;
  FConexion.SpecificOptions.Values['MySQL.Interactive'] := 'True';
  FConexion.SpecificOptions.Values['ConnectionTimeout'] := '30';
  try
    FConexion.Connect;
  except
    on E: Exception do
    begin
      raise EDatabaseError.CreateFmt(
        'No se pudo conectar con MariaDB en %s:%d, base %s. ' +
        'Revisa %%LOCALAPPDATA%%\Contazam\contazam.ini o ' +
        'CONTAZAM_DB_PASSWORD. Detalle: %s',
        [AConfiguracion.Servidor,
         AConfiguracion.Puerto,
         AConfiguracion.BaseDatos,
         E.Message]);
    end;
  end;
  FConexion.ExecSQL(
    'SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
end;

end.
