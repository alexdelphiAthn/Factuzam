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
  inLibConexionesIntf,
  inLibLogonAplicacionIntf;

procedure CrearRepositorioLogonUniDAC(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
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
  System.SysUtils, Data.DB, DBAccess,
  DAScript, UniScript, inLibMsgConexion, inLibMsgLogon,
  inLibProteccionDatosFacturacion, inLibWin;

const
  SQL_AUTENTICAR =
    'SELECT U.PASSWORD_USU, U.EMPRESA_DEFECTO_USU, ' +
    'U.ALMACEN_DEFECTO_USU, U.CAJA_DEFECTO_USU, ' +
    'V.GRUPO_USU, V.ESGRUPOADMINISTRADOR_USUGRP ' +
    'FROM fza_usuarios U LEFT JOIN VI_USUARIOS V ' +
    'ON V.USUARIO_USU = U.USUARIO_USU ' +
    'WHERE U.USUARIO_USU = :Usuario';
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
    FFabricaConexiones: IFabricaConexionesUniDAC;
    FConexion: TUniConnection;
  public
    constructor Create(
      const AFabricaConexiones: IFabricaConexionesUniDAC);
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
    raise EArgumentNilException.Create(
      SErrorConexionNoAsignada);
end;

procedure CrearRepositorioLogonUniDAC(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  out ARepositorio: IRepositorioLogon;
  out AConexion: TUniConnection);
var
  oRepositorio: TRepositorioLogonUniDAC;
begin
  oRepositorio := TRepositorioLogonUniDAC.Create(
    AFabricaConexiones);
  AConexion := oRepositorio.Conexion;
  ARepositorio := oRepositorio;
end;

constructor TRepositorioLogonUniDAC.Create(
  const AFabricaConexiones: IFabricaConexionesUniDAC);
begin
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  inherited Create;
  FFabricaConexiones := AFabricaConexiones;
  FConexion := FFabricaConexiones.CrearConexion(nil);
  ComprobarConexion(FConexion);
end;

destructor TRepositorioLogonUniDAC.Destroy;
begin
  FreeAndNil(FConexion);
  FFabricaConexiones := nil;
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
      SErrorBaseDatosAutenticacionNoDisponible);
  Result := TResultadoAutenticacionLogon.Crear(
    ealCredencialesInvalidas,
    SResultadoCredencialesInvalidas);
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        FFabricaConexiones.DialectoSql.AplicarLimiteOrdenado(
          SQL_AUTENTICAR, 'U.USUARIO_USU', 1);
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
            SResultadoAutenticacionCorrecta);
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
    ValidarSqlSinModificacionesFacturacion(oScript.SQL.Text);
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
