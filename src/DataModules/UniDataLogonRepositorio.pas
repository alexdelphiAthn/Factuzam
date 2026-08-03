{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLogonRepositorio                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia y componentes UniDAC usados por la pantalla de logon.       }
{******************************************************************************}
unit UniDataLogonRepositorio;

interface

uses
  System.Classes, Uni,
  inLibLogonAplicacionIntf;

procedure CrearRepositorioLogonUniDAC(
  out ARepositorio: IRepositorioLogon;
  out AConexion: TUniConnection);
function ExisteEsquemaLogonUniDAC(
  AConexion: TUniConnection;
  const ABaseDatos: string): Boolean;
procedure EjecutarScriptLogonUniDAC(
  AConexion: TUniConnection;
  const ARuta: string;
  const AResolverError: TResolverErrorScriptLogon);

implementation

uses
  System.SysUtils, Data.DB, DBAccess, MySQLUniProvider,
  DAScript, UniScript, inLibWin;

const
  SQL_AUTENTICAR =
    'SELECT U.PASSWORD_USU, U.EMPRESA_DEFECTO_USU, ' +
    'U.ALMACEN_DEFECTO_USU, U.CAJA_DEFECTO_USU, ' +
    'V.GRUPO_USU, V.ESGRUPOADMINISTRADOR_USUGRP ' +
    'FROM fza_usuarios U LEFT JOIN VI_USUARIOS V ' +
    'ON V.USUARIO_USU = U.USUARIO_USU ' +
    'WHERE U.USUARIO_USU = :Usuario LIMIT 1';
  SQL_ULTIMO_LOGIN =
    'UPDATE fza_usuarios SET ULTIMO_LOGIN_USU = :Instante ' +
    'WHERE USUARIO_USU = :Usuario';
  SQL_EXISTE_ESQUEMA =
    'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA ' +
    'WHERE SCHEMA_NAME = :BBDD';

type
  TRepositorioLogonUniDAC = class(
    TInterfacedObject,
    IRepositorioLogon)
  private
    FProveedor: TMySQLUniProvider;
    FConexion: TUniConnection;
  public
    constructor Create;
    destructor Destroy; override;
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
    property Conexion: TUniConnection read FConexion;
  end;

  TEjecutorScriptLogonUniDAC = class
  private
    FResolverError: TResolverErrorScriptLogon;
    procedure ResolverError(
      Sender: TObject;
      E: Exception;
      SQL: string;
      var Action: TErrorAction);
  public
    procedure Ejecutar(
      AConexion: TUniConnection;
      const ARuta: string;
      const AResolverError: TResolverErrorScriptLogon);
  end;

procedure ComprobarConexion(AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
end;

procedure CrearRepositorioLogonUniDAC(
  out ARepositorio: IRepositorioLogon;
  out AConexion: TUniConnection);
var
  oRepositorio: TRepositorioLogonUniDAC;
begin
  oRepositorio := TRepositorioLogonUniDAC.Create;
  AConexion := oRepositorio.Conexion;
  ARepositorio := oRepositorio;
end;

constructor TRepositorioLogonUniDAC.Create;
begin
  inherited Create;
  FProveedor := TMySQLUniProvider.Create(nil);
  FConexion := TUniConnection.Create(nil);
  FConexion.ProviderName := 'MySQL';
  FConexion.LoginPrompt := False;
  FConexion.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
  FConexion.Pooling := True;
  FConexion.PoolingOptions.MinPoolSize := 1;
  FConexion.PoolingOptions.MaxPoolSize := 50;
  FConexion.PoolingOptions.ConnectionLifeTime := 3 * 60;
end;

destructor TRepositorioLogonUniDAC.Destroy;
begin
  FreeAndNil(FConexion);
  FreeAndNil(FProveedor);
  inherited;
end;

function TRepositorioLogonUniDAC.Autenticar(
  const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
var
  oConsulta: TUniQuery;
  sClaveEsperada: string;
  sClaveIntroducida: string;
begin
  if not FConexion.Connected then
    raise ERepositorioLogonNoDisponible.Create(
      'La base de datos de autenticación no está disponible.');
  Result := TResultadoAutenticacionLogon.Crear(
    ealCredencialesInvalidas,
    'Las credenciales no son válidas.');
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_AUTENTICAR;
      oConsulta.ParamByName('Usuario').AsString := AUsuario;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        sClaveEsperada := oConsulta.FieldByName('PASSWORD_USU').AsString;
        sClaveIntroducida := '';
        if AContrasena <> '' then
          sClaveIntroducida := sMd5(AContrasena);
        if sClaveIntroducida = sClaveEsperada then
        begin
          Result := TResultadoAutenticacionLogon.Crear(
            ealAutenticado,
            'Autenticación correcta.');
          Result.Usuario := AUsuario;
          Result.Grupo := oConsulta.FieldByName('GRUPO_USU').AsString;
          Result.EsGrupoAdministrador := oConsulta.FieldByName(
            'ESGRUPOADMINISTRADOR_USUGRP').AsString;
          Result.Empresa := oConsulta.FieldByName(
            'EMPRESA_DEFECTO_USU').AsString;
          Result.Almacen := oConsulta.FieldByName(
            'ALMACEN_DEFECTO_USU').AsString;
          Result.Caja := oConsulta.FieldByName('CAJA_DEFECTO_USU').AsString;
          oConsulta.Close;
          oConsulta.SQL.Text := SQL_ULTIMO_LOGIN;
          oConsulta.ParamByName('Instante').AsDateTime := Now;
          oConsulta.ParamByName('Usuario').AsString := AUsuario;
          oConsulta.ExecSQL;
        end;
      end;
    except
      on E: Exception do
      begin
        if not FConexion.Connected then
          raise ERepositorioLogonNoDisponible.Create(E.Message)
        else
          raise ERepositorioLogonError.Create(E.Message);
      end;
    end;
  finally
    oConsulta.Free;
  end;
end;

function ExisteEsquemaLogonUniDAC(
  AConexion: TUniConnection;
  const ABaseDatos: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  ComprobarConexion(AConexion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_EXISTE_ESQUEMA;
    oConsulta.ParamByName('BBDD').AsString := ABaseDatos;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    oConsulta.Free;
  end;
end;

procedure TEjecutorScriptLogonUniDAC.ResolverError(
  Sender: TObject;
  E: Exception;
  SQL: string;
  var Action: TErrorAction);
begin
  Action := eaFail;
  if Assigned(FResolverError) and
     (FResolverError(SQL, E.Message) = deslContinuar) then
    Action := eaContinue;
end;

procedure TEjecutorScriptLogonUniDAC.Ejecutar(
  AConexion: TUniConnection;
  const ARuta: string;
  const AResolverError: TResolverErrorScriptLogon);
var
  oScript: TUniScript;
begin
  ComprobarConexion(AConexion);
  FResolverError := AResolverError;
  oScript := TUniScript.Create(nil);
  try
    oScript.Connection := AConexion;
    oScript.NoPreconnect := True;
    oScript.OnError := ResolverError;
    oScript.SQL.LoadFromFile(ARuta);
    oScript.Execute;
  finally
    oScript.Free;
  end;
end;

procedure EjecutarScriptLogonUniDAC(
  AConexion: TUniConnection;
  const ARuta: string;
  const AResolverError: TResolverErrorScriptLogon);
var
  oEjecutor: TEjecutorScriptLogonUniDAC;
begin
  oEjecutor := TEjecutorScriptLogonUniDAC.Create;
  try
    oEjecutor.Ejecutar(AConexion, ARuta, AResolverError);
  finally
    oEjecutor.Free;
  end;
end;

end.
