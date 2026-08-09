{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataSeguridad                                              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Autorización por grupos, alcance de empresa y auditoría de listados.      }
{******************************************************************************}
unit UniDataSeguridad;

interface

uses
  Uni, inLibSeguridadIntf, inLibContadoresIntf;

function CrearServicioSeguridad(
  AConexion: TUniConnection;
  const AUsuario: string): IServicioSeguridadContazam;

implementation

uses
  System.SysUtils, Data.DB, UniDataContadoresRepositorio;

type
  TPermisoResuelto = record
    Permitido: Boolean;
    Grupo: string;
    Alcance: string;
  end;

  TServicioSeguridadContazam = class(
    TInterfacedObject,
    IServicioSeguridadContazam)
  private
    FConexion: TUniConnection;
    FUsuario: string;
    FContadores: IContadorDocumentos;
    procedure InicializarPrimerUsuario;
    function ResolverPermiso(
      const ARecurso: string;
      const AAccion: string;
      const AEmpresa: string): TPermisoResuelto;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AUsuario: string);
    destructor Destroy; override;
    function UsuarioActual: string;
    procedure ExigirPermiso(
      const ARecurso: string;
      const AAccion: string;
      const AEmpresa: string);
    procedure ExigirPermisoGlobal(
      const ARecurso: string;
      const AAccion: string);
    procedure RegistrarUsoListado(
      const ARecurso: string;
      const AAccion: string;
      const AEmpresa: string;
      AEjercicio: Integer;
      AFechaDesde: TDate;
      AFechaHasta: TDate;
      const ACuenta: string;
      ANumeroRegistros: Integer;
      const AArchivo: string);
  end;

function CrearServicioSeguridad(
  AConexion: TUniConnection;
  const AUsuario: string): IServicioSeguridadContazam;
begin
  Result := TServicioSeguridadContazam.Create(AConexion, AUsuario);
end;

constructor TServicioSeguridadContazam.Create(
  AConexion: TUniConnection;
  const AUsuario: string);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  if Trim(AUsuario) = '' then
  begin
    raise EArgumentException.Create(
      'El usuario de aplicación no puede estar vacío.');
  end;
  inherited Create;
  FConexion := AConexion;
  FUsuario := UpperCase(Trim(AUsuario));
  FContadores := CrearRepositorioContadores(FConexion);
  InicializarPrimerUsuario;
end;

destructor TServicioSeguridadContazam.Destroy;
begin
  FContadores := nil;
  inherited;
end;

procedure TServicioSeguridadContazam.ExigirPermiso(
  const ARecurso: string;
  const AAccion: string;
  const AEmpresa: string);
var
  oPermiso: TPermisoResuelto;
begin
  oPermiso := ResolverPermiso(ARecurso, AAccion, AEmpresa);
  if not oPermiso.Permitido then
  begin
    raise EAccesoContazamDenegado.CreateFmt(
      'El usuario %s no tiene permiso %s sobre %s para la empresa %s.',
      [FUsuario, AAccion, ARecurso, AEmpresa]);
  end;
end;

procedure TServicioSeguridadContazam.ExigirPermisoGlobal(
  const ARecurso: string;
  const AAccion: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM cza_usuarios U ' +
      'JOIN cza_usuarios_grupos UG ' +
      'ON UG.CODIGO_USU_UGR = U.CODIGO_USU ' +
      'AND UG.ESACTIVO_UGR = ''S'' JOIN cza_grupos G ' +
      'ON G.CODIGO_GRU = UG.CODIGO_GRU_UGR ' +
      'AND G.ESACTIVO_GRU = ''S'' JOIN cza_grupos_permisos P ' +
      'ON P.CODIGO_GRU_GPE = G.CODIGO_GRU ' +
      'AND P.ESACTIVO_GPE = ''S'' ' +
      'WHERE U.CODIGO_USU = :USUARIO ' +
      'AND U.ESACTIVO_USU = ''S'' ' +
      'AND (P.RECURSO_GPE = ''*'' OR P.RECURSO_GPE = :RECURSO) ' +
      'AND (P.ACCION_GPE = ''*'' OR P.ACCION_GPE = :ACCION) ' +
      'AND P.ALCANCE_GPE = ''GLOBAL'' LIMIT 1';
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('RECURSO').AsString := UpperCase(ARecurso);
    oConsulta.ParamByName('ACCION').AsString := UpperCase(AAccion);
    oConsulta.Open;
    if oConsulta.IsEmpty then
    begin
      raise EAccesoContazamDenegado.CreateFmt(
        'El usuario %s no tiene permiso global %s sobre %s.',
        [FUsuario, AAccion, ARecurso]);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSeguridadContazam.InicializarPrimerUsuario;
var
  oConsulta: TUniQuery;
  iUsuarios: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := 'SELECT COUNT(*) AS TOTAL FROM cza_usuarios';
    oConsulta.Open;
    iUsuarios := oConsulta.FieldByName('TOTAL').AsInteger;
    oConsulta.Close;
    if iUsuarios = 0 then
    begin
      FConexion.StartTransaction;
      try
        oConsulta.SQL.Text :=
          'INSERT IGNORE INTO cza_grupos (' +
          'CODIGO_GRU, NOMBRE_GRU, ESACTIVO_GRU, ' +
          'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
          '''ADMIN'', ''Administradores de Contazam'', ''S'', ' +
          'NOW(), :USUARIO)';
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.ExecSQL;
        oConsulta.SQL.Text :=
          'INSERT IGNORE INTO cza_grupos_permisos (' +
          'CODIGO_GRU_GPE, RECURSO_GPE, ACCION_GPE, ALCANCE_GPE, ' +
          'CODIGO_EMP_GPE, ESACTIVO_GPE, INSTANTE_ALTA, USUARIO_ALTA) ' +
          'VALUES (''ADMIN'', ''*'', ''*'', ''GLOBAL'', ''*'', ''S'', ' +
          'NOW(), :USUARIO)';
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.ExecSQL;
        oConsulta.SQL.Text :=
          'INSERT INTO cza_usuarios (' +
          'CODIGO_USU, NOMBRE_USU, ESACTIVO_USU, ' +
          'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
          ':CODIGO, :NOMBRE, ''S'', NOW(), :USUARIO)';
        oConsulta.ParamByName('CODIGO').AsString := FUsuario;
        oConsulta.ParamByName('NOMBRE').AsString := FUsuario;
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.ExecSQL;
        oConsulta.SQL.Text :=
          'INSERT INTO cza_usuarios_grupos (' +
          'CODIGO_USU_UGR, CODIGO_GRU_UGR, ESACTIVO_UGR, ' +
          'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
          ':USUARIO, ''ADMIN'', ''S'', NOW(), :USUARIO)';
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.ExecSQL;
        FConexion.Commit;
      except
        if FConexion.InTransaction then
        begin
          FConexion.Rollback;
        end;
        raise;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSeguridadContazam.RegistrarUsoListado(
  const ARecurso: string;
  const AAccion: string;
  const AEmpresa: string;
  AEjercicio: Integer;
  AFechaDesde: TDate;
  AFechaHasta: TDate;
  const ACuenta: string;
  ANumeroRegistros: Integer;
  const AArchivo: string);
var
  oConsulta: TUniQuery;
  oPermiso: TPermisoResuelto;
  iIdAuditoria: Int64;
begin
  oPermiso := ResolverPermiso(ARecurso, AAccion, AEmpresa);
  if not oPermiso.Permitido then
  begin
    ExigirPermiso(ARecurso, AAccion, AEmpresa);
  end;
  FConexion.StartTransaction;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      iIdAuditoria := FContadores.SiguienteNumero(
        'GLOBAL',
        0,
        'ID_AUDITORIA_LISTADO',
        '-');
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'INSERT INTO cza_auditoria_listados (' +
        'ID_AUL, CODIGO_USU_AUL, CODIGO_GRU_AUL, RECURSO_AUL, ' +
        'ACCION_AUL, ALCANCE_AUL, CODIGO_EMP_AUL, EJERCICIO_AUL, ' +
        'FECHA_DESDE_AUL, FECHA_HASTA_AUL, FILTRO_CUENTA_AUL, ' +
        'NUMERO_REGISTROS_AUL, ARCHIVO_AUL, ' +
        'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
        ':ID, :USUARIO, :GRUPO, :RECURSO, :ACCION, :ALCANCE, ' +
        ':EMPRESA, :EJERCICIO, :DESDE, :HASTA, :CUENTA, ' +
        ':REGISTROS, :ARCHIVO, NOW(), :USUARIO)';
      oConsulta.ParamByName('ID').AsLargeInt := iIdAuditoria;
      oConsulta.ParamByName('USUARIO').AsString := FUsuario;
      oConsulta.ParamByName('GRUPO').AsString := oPermiso.Grupo;
      oConsulta.ParamByName('RECURSO').AsString := UpperCase(ARecurso);
      oConsulta.ParamByName('ACCION').AsString := UpperCase(AAccion);
      oConsulta.ParamByName('ALCANCE').AsString := oPermiso.Alcance;
      oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := AEjercicio;
      oConsulta.ParamByName('DESDE').AsDate := AFechaDesde;
      oConsulta.ParamByName('HASTA').AsDate := AFechaHasta;
      oConsulta.ParamByName('CUENTA').AsString := Trim(ACuenta);
      oConsulta.ParamByName('REGISTROS').AsInteger := ANumeroRegistros;
      oConsulta.ParamByName('ARCHIVO').AsString := ExtractFileName(AArchivo);
      oConsulta.ExecSQL;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioSeguridadContazam.ResolverPermiso(
  const ARecurso: string;
  const AAccion: string;
  const AEmpresa: string): TPermisoResuelto;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TPermisoResuelto);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT P.CODIGO_GRU_GPE, P.ALCANCE_GPE ' +
      'FROM cza_usuarios U ' +
      'JOIN cza_usuarios_grupos UG ' +
      '  ON UG.CODIGO_USU_UGR = U.CODIGO_USU ' +
      ' AND UG.ESACTIVO_UGR = ''S'' ' +
      'JOIN cza_grupos G ON G.CODIGO_GRU = UG.CODIGO_GRU_UGR ' +
      ' AND G.ESACTIVO_GRU = ''S'' ' +
      'JOIN cza_grupos_permisos P ' +
      '  ON P.CODIGO_GRU_GPE = G.CODIGO_GRU ' +
      ' AND P.ESACTIVO_GPE = ''S'' ' +
      'WHERE U.CODIGO_USU = :USUARIO AND U.ESACTIVO_USU = ''S'' ' +
      'AND (P.RECURSO_GPE = ''*'' OR P.RECURSO_GPE = :RECURSO) ' +
      'AND (P.ACCION_GPE = ''*'' OR P.ACCION_GPE = :ACCION) ' +
      'AND (P.ALCANCE_GPE = ''GLOBAL'' OR (' +
      '  P.ALCANCE_GPE = ''EMPRESA'' AND P.CODIGO_EMP_GPE = :EMPRESA' +
      ')) ORDER BY (P.RECURSO_GPE <> ''*'') DESC, ' +
      '(P.ACCION_GPE <> ''*'') DESC, ' +
      '(P.ALCANCE_GPE = ''EMPRESA'') DESC LIMIT 1';
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('RECURSO').AsString := UpperCase(ARecurso);
    oConsulta.ParamByName('ACCION').AsString := UpperCase(AAccion);
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    Result.Permitido := not oConsulta.IsEmpty;
    if Result.Permitido then
    begin
      Result.Grupo := oConsulta.FieldByName('CODIGO_GRU_GPE').AsString;
      Result.Alcance := oConsulta.FieldByName('ALCANCE_GPE').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioSeguridadContazam.UsuarioActual: string;
begin
  Result := FUsuario;
end;

end.
