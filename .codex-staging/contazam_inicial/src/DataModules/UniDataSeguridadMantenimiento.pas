{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataSeguridadMantenimiento                                 }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mantenimiento de usuarios, grupos, permisos y auditoría de listados.      }
{******************************************************************************}
unit UniDataSeguridadMantenimiento;

interface

uses
  System.Classes, Data.DB, Uni;

type
  TdmSeguridadMantenimiento = class(TDataModule)
  private
    FConexion: TUniConnection;
    FUsuario: string;
    FUsuarios: TUniQuery;
    FGrupos: TUniQuery;
    FMembresias: TUniQuery;
    FPermisos: TUniQuery;
    FAuditoria: TUniQuery;
    procedure AntesDePublicar(DataSet: TDataSet);
    procedure ConfigurarGrupos;
    procedure ConfigurarMembresias;
    procedure ConfigurarPermisos;
    procedure ConfigurarUsuarios;
    procedure PrepararConsulta(
      AConsulta: TUniQuery;
      const ASqlConsulta: string;
      const ASqlInsertar: string;
      const ASqlModificar: string;
      const ASqlEliminar: string);
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AUsuario: string); reintroduce;
    procedure Abrir;
    property Auditoria: TUniQuery read FAuditoria;
    property Grupos: TUniQuery read FGrupos;
    property Membresias: TUniQuery read FMembresias;
    property Permisos: TUniQuery read FPermisos;
    property Usuarios: TUniQuery read FUsuarios;
  end;

implementation

uses
  System.SysUtils, System.StrUtils;

constructor TdmSeguridadMantenimiento.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AUsuario: string);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited CreateNew(AOwner);
  FConexion := AConexion;
  FUsuario := UpperCase(Trim(AUsuario));
  FUsuarios := TUniQuery.Create(Self);
  FGrupos := TUniQuery.Create(Self);
  FMembresias := TUniQuery.Create(Self);
  FPermisos := TUniQuery.Create(Self);
  FAuditoria := TUniQuery.Create(Self);
  ConfigurarUsuarios;
  ConfigurarGrupos;
  ConfigurarMembresias;
  ConfigurarPermisos;
  FAuditoria.Connection := FConexion;
  FAuditoria.ReadOnly := True;
  FAuditoria.SQL.Text :=
    'SELECT ID_AUL, CODIGO_USU_AUL, CODIGO_GRU_AUL, ' +
    'RECURSO_AUL, ACCION_AUL, ALCANCE_AUL, CODIGO_EMP_AUL, ' +
    'EJERCICIO_AUL, FECHA_DESDE_AUL, FECHA_HASTA_AUL, ' +
    'FILTRO_CUENTA_AUL, NUMERO_REGISTROS_AUL, ARCHIVO_AUL, ' +
    'INSTANTE_ALTA FROM cza_auditoria_listados ' +
    'ORDER BY ID_AUL DESC LIMIT 1000';
end;

procedure TdmSeguridadMantenimiento.Abrir;
begin
  FUsuarios.Close;
  FGrupos.Close;
  FMembresias.Close;
  FPermisos.Close;
  FAuditoria.Close;
  FUsuarios.Open;
  FGrupos.Open;
  FMembresias.Open;
  FPermisos.Open;
  FAuditoria.Open;
end;

procedure TdmSeguridadMantenimiento.AntesDePublicar(
  DataSet: TDataSet);
var
  oCampo: TField;
  sAlcance: string;
begin
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
  for oCampo in DataSet.Fields do
  begin
    if StartsText('ESACTIVO_', oCampo.FieldName) and
      (Trim(oCampo.AsString) = '') then
    begin
      oCampo.AsString := 'S';
    end;
  end;
  if DataSet.FindField('CODIGO_USU') <> nil then
  begin
    DataSet.FieldByName('CODIGO_USU').AsString := UpperCase(
      Trim(DataSet.FieldByName('CODIGO_USU').AsString));
  end;
  if DataSet.FindField('CODIGO_GRU') <> nil then
  begin
    DataSet.FieldByName('CODIGO_GRU').AsString := UpperCase(
      Trim(DataSet.FieldByName('CODIGO_GRU').AsString));
  end;
  if DataSet.FindField('CODIGO_USU_UGR') <> nil then
  begin
    DataSet.FieldByName('CODIGO_USU_UGR').AsString := UpperCase(
      Trim(DataSet.FieldByName('CODIGO_USU_UGR').AsString));
    DataSet.FieldByName('CODIGO_GRU_UGR').AsString := UpperCase(
      Trim(DataSet.FieldByName('CODIGO_GRU_UGR').AsString));
  end;
  if DataSet.FindField('RECURSO_GPE') <> nil then
  begin
    DataSet.FieldByName('CODIGO_GRU_GPE').AsString := UpperCase(
      Trim(DataSet.FieldByName('CODIGO_GRU_GPE').AsString));
    DataSet.FieldByName('RECURSO_GPE').AsString := UpperCase(
      Trim(DataSet.FieldByName('RECURSO_GPE').AsString));
    DataSet.FieldByName('ACCION_GPE').AsString := UpperCase(
      Trim(DataSet.FieldByName('ACCION_GPE').AsString));
    sAlcance := UpperCase(Trim(
      DataSet.FieldByName('ALCANCE_GPE').AsString));
    if not SameText(sAlcance, 'GLOBAL') and
      not SameText(sAlcance, 'EMPRESA') then
    begin
      raise EArgumentException.Create(
        'El alcance debe ser GLOBAL o EMPRESA.');
    end;
    DataSet.FieldByName('ALCANCE_GPE').AsString := sAlcance;
    if SameText(sAlcance, 'GLOBAL') then
    begin
      DataSet.FieldByName('CODIGO_EMP_GPE').AsString := '*';
    end
    else if Trim(DataSet.FieldByName('CODIGO_EMP_GPE').AsString) = '' then
    begin
      raise EArgumentException.Create(
        'Indica la empresa del permiso con alcance EMPRESA.');
    end;
  end;
end;

procedure TdmSeguridadMantenimiento.ConfigurarGrupos;
begin
  PrepararConsulta(
    FGrupos,
    'SELECT CODIGO_GRU, NOMBRE_GRU, ESACTIVO_GRU, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    'FROM cza_grupos ORDER BY CODIGO_GRU',
    'INSERT INTO cza_grupos (CODIGO_GRU, NOMBRE_GRU, ' +
    'ESACTIVO_GRU, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_MODIF) VALUES (:CODIGO_GRU, ' +
    ':NOMBRE_GRU, :ESACTIVO_GRU, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    ':INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_grupos SET NOMBRE_GRU = :NOMBRE_GRU, ' +
    'ESACTIVO_GRU = :ESACTIVO_GRU, INSTANTE_MODIF = :INSTANTE_MODIF, ' +
    'USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_GRU = :Old_CODIGO_GRU',
    'DELETE FROM cza_grupos WHERE CODIGO_GRU = :Old_CODIGO_GRU');
end;

procedure TdmSeguridadMantenimiento.ConfigurarMembresias;
begin
  PrepararConsulta(
    FMembresias,
    'SELECT CODIGO_USU_UGR, CODIGO_GRU_UGR, ESACTIVO_UGR, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    'FROM cza_usuarios_grupos ' +
    'ORDER BY CODIGO_USU_UGR, CODIGO_GRU_UGR',
    'INSERT INTO cza_usuarios_grupos (CODIGO_USU_UGR, ' +
    'CODIGO_GRU_UGR, ESACTIVO_UGR, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_MODIF) VALUES (:CODIGO_USU_UGR, ' +
    ':CODIGO_GRU_UGR, :ESACTIVO_UGR, :INSTANTE_ALTA, ' +
    ':USUARIO_ALTA, :INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_usuarios_grupos SET ESACTIVO_UGR = :ESACTIVO_UGR, ' +
    'INSTANTE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_USU_UGR = :Old_CODIGO_USU_UGR ' +
    'AND CODIGO_GRU_UGR = :Old_CODIGO_GRU_UGR',
    'DELETE FROM cza_usuarios_grupos ' +
    'WHERE CODIGO_USU_UGR = :Old_CODIGO_USU_UGR ' +
    'AND CODIGO_GRU_UGR = :Old_CODIGO_GRU_UGR');
end;

procedure TdmSeguridadMantenimiento.ConfigurarPermisos;
begin
  PrepararConsulta(
    FPermisos,
    'SELECT CODIGO_GRU_GPE, RECURSO_GPE, ACCION_GPE, ' +
    'ALCANCE_GPE, CODIGO_EMP_GPE, ESACTIVO_GPE, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    'FROM cza_grupos_permisos ORDER BY CODIGO_GRU_GPE, ' +
    'RECURSO_GPE, ACCION_GPE, ALCANCE_GPE, CODIGO_EMP_GPE',
    'INSERT INTO cza_grupos_permisos (CODIGO_GRU_GPE, ' +
    'RECURSO_GPE, ACCION_GPE, ALCANCE_GPE, CODIGO_EMP_GPE, ' +
    'ESACTIVO_GPE, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_MODIF) VALUES (:CODIGO_GRU_GPE, ' +
    ':RECURSO_GPE, :ACCION_GPE, :ALCANCE_GPE, :CODIGO_EMP_GPE, ' +
    ':ESACTIVO_GPE, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    ':INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_grupos_permisos SET ESACTIVO_GPE = :ESACTIVO_GPE, ' +
    'INSTANTE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_GRU_GPE = :Old_CODIGO_GRU_GPE ' +
    'AND RECURSO_GPE = :Old_RECURSO_GPE ' +
    'AND ACCION_GPE = :Old_ACCION_GPE ' +
    'AND ALCANCE_GPE = :Old_ALCANCE_GPE ' +
    'AND CODIGO_EMP_GPE = :Old_CODIGO_EMP_GPE',
    'DELETE FROM cza_grupos_permisos ' +
    'WHERE CODIGO_GRU_GPE = :Old_CODIGO_GRU_GPE ' +
    'AND RECURSO_GPE = :Old_RECURSO_GPE ' +
    'AND ACCION_GPE = :Old_ACCION_GPE ' +
    'AND ALCANCE_GPE = :Old_ALCANCE_GPE ' +
    'AND CODIGO_EMP_GPE = :Old_CODIGO_EMP_GPE');
end;

procedure TdmSeguridadMantenimiento.ConfigurarUsuarios;
begin
  PrepararConsulta(
    FUsuarios,
    'SELECT CODIGO_USU, NOMBRE_USU, EMAIL_USU, ESACTIVO_USU, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    'FROM cza_usuarios ORDER BY CODIGO_USU',
    'INSERT INTO cza_usuarios (CODIGO_USU, NOMBRE_USU, EMAIL_USU, ' +
    'ESACTIVO_USU, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_MODIF) VALUES (:CODIGO_USU, ' +
    ':NOMBRE_USU, :EMAIL_USU, :ESACTIVO_USU, :INSTANTE_ALTA, ' +
    ':USUARIO_ALTA, :INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_usuarios SET NOMBRE_USU = :NOMBRE_USU, ' +
    'EMAIL_USU = :EMAIL_USU, ESACTIVO_USU = :ESACTIVO_USU, ' +
    'INSTANTE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_USU = :Old_CODIGO_USU',
    'DELETE FROM cza_usuarios WHERE CODIGO_USU = :Old_CODIGO_USU');
end;

procedure TdmSeguridadMantenimiento.PrepararConsulta(
  AConsulta: TUniQuery;
  const ASqlConsulta: string;
  const ASqlInsertar: string;
  const ASqlModificar: string;
  const ASqlEliminar: string);
begin
  AConsulta.Connection := FConexion;
  AConsulta.ReadOnly := False;
  AConsulta.SQL.Text := ASqlConsulta;
  AConsulta.SQLInsert.Text := ASqlInsertar;
  AConsulta.SQLUpdate.Text := ASqlModificar;
  AConsulta.SQLDelete.Text := ASqlEliminar;
  AConsulta.BeforePost := AntesDePublicar;
end;

end.
