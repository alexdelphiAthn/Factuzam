{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPerfilesVentana                                       }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia MariaDB de perfiles de ventana por usuario y empresa.        }
{******************************************************************************}
unit UniDataPerfilesVentana;

interface

uses
  Data.DB, Uni, inLibPerfilesVentanaTipos;

type
  TRepositorioPerfilesVentana = class
  private
    FConexion: TUniConnection;
    FEmpresa: string;
    FUsuario: string;
    procedure BorrarColumnas(const AFormulario: string);
    procedure BorrarVentana(const AFormulario: string);
    procedure InsertarColumna(
      const AFormulario: string;
      const AColumna: TPerfilColumnaContazam);
    procedure InsertarVentana(
      const AFormulario: string;
      const APerfil: TPerfilVentanaContazam);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AEmpresa: string;
      const AUsuario: string);
    function Cargar(
      const AFormulario: string;
      out APerfil: TPerfilVentanaContazam;
      out AColumnas: TPerfilesColumnasContazam): Boolean;
    procedure Eliminar(const AFormulario: string);
    procedure Guardar(
      const AFormulario: string;
      const APerfil: TPerfilVentanaContazam;
      const AColumnas: TPerfilesColumnasContazam);
  end;

implementation

uses
  System.SysUtils;

constructor TRepositorioPerfilesVentana.Create(
  AConexion: TUniConnection;
  const AEmpresa: string;
  const AUsuario: string);
begin
  inherited Create;
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  FConexion := AConexion;
  FEmpresa := AEmpresa;
  FUsuario := AUsuario;
end;

procedure TRepositorioPerfilesVentana.BorrarColumnas(
  const AFormulario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'DELETE FROM cza_perfiles_ventanas_columnas ' +
      'WHERE CODIGO_EMP_PVC = :EMPRESA ' +
      'AND CODIGO_USU_PVC = :USUARIO ' +
      'AND FORMULARIO_PVC = :FORMULARIO';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPerfilesVentana.BorrarVentana(
  const AFormulario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'DELETE FROM cza_perfiles_ventanas ' +
      'WHERE CODIGO_EMP_PVE = :EMPRESA ' +
      'AND CODIGO_USU_PVE = :USUARIO ' +
      'AND FORMULARIO_PVE = :FORMULARIO';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPerfilesVentana.Cargar(
  const AFormulario: string;
  out APerfil: TPerfilVentanaContazam;
  out AColumnas: TPerfilesColumnasContazam): Boolean;
var
  iColumna: Integer;
  oConsulta: TUniQuery;
begin
  APerfil := Default(TPerfilVentanaContazam);
  SetLength(AColumnas, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT NOMBRE_PVE, POSICION_IZQUIERDA_PVE, ' +
      'POSICION_SUPERIOR_PVE, ANCHO_PVE, ALTO_PVE, ESTADO_PVE, ' +
      'PESTANA_ACTIVA_PVE FROM cza_perfiles_ventanas ' +
      'WHERE CODIGO_EMP_PVE = :EMPRESA ' +
      'AND CODIGO_USU_PVE = :USUARIO ' +
      'AND FORMULARIO_PVE = :FORMULARIO';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
    begin
      APerfil.Nombre := oConsulta.FieldByName('NOMBRE_PVE').AsString;
      APerfil.PosicionIzquierda :=
        oConsulta.FieldByName('POSICION_IZQUIERDA_PVE').AsInteger;
      APerfil.PosicionSuperior :=
        oConsulta.FieldByName('POSICION_SUPERIOR_PVE').AsInteger;
      APerfil.Ancho := oConsulta.FieldByName('ANCHO_PVE').AsInteger;
      APerfil.Alto := oConsulta.FieldByName('ALTO_PVE').AsInteger;
      APerfil.Estado := oConsulta.FieldByName('ESTADO_PVE').AsString;
      APerfil.PestanaActiva :=
        oConsulta.FieldByName('PESTANA_ACTIVA_PVE').AsString;
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'SELECT GRID_PVC, CAMPO_PVC, NOMBRE_PVC, ORDEN_PVC, ' +
        'ESVISIBLE_PVC, ANCHO_PVC ' +
        'FROM cza_perfiles_ventanas_columnas ' +
        'WHERE CODIGO_EMP_PVC = :EMPRESA ' +
        'AND CODIGO_USU_PVC = :USUARIO ' +
        'AND FORMULARIO_PVC = :FORMULARIO ' +
        'ORDER BY GRID_PVC, ORDEN_PVC';
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('USUARIO').AsString := FUsuario;
      oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
      oConsulta.Open;
      iColumna := 0;
      while not oConsulta.Eof do
      begin
        SetLength(AColumnas, iColumna + 1);
        AColumnas[iColumna].Grid :=
          oConsulta.FieldByName('GRID_PVC').AsString;
        AColumnas[iColumna].Campo :=
          oConsulta.FieldByName('CAMPO_PVC').AsString;
        AColumnas[iColumna].Nombre :=
          oConsulta.FieldByName('NOMBRE_PVC').AsString;
        AColumnas[iColumna].Orden :=
          oConsulta.FieldByName('ORDEN_PVC').AsInteger;
        AColumnas[iColumna].EsVisible :=
          oConsulta.FieldByName('ESVISIBLE_PVC').AsString = 'S';
        AColumnas[iColumna].Ancho :=
          oConsulta.FieldByName('ANCHO_PVC').AsInteger;
        Inc(iColumna);
        oConsulta.Next;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPerfilesVentana.Eliminar(
  const AFormulario: string);
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
  begin
    FConexion.StartTransaction;
  end;
  try
    BorrarColumnas(AFormulario);
    BorrarVentana(AFormulario);
    if bTransaccionPropia then
    begin
      FConexion.Commit;
    end;
  except
    if bTransaccionPropia and FConexion.InTransaction then
    begin
      FConexion.Rollback;
    end;
    raise;
  end;
end;

procedure TRepositorioPerfilesVentana.Guardar(
  const AFormulario: string;
  const APerfil: TPerfilVentanaContazam;
  const AColumnas: TPerfilesColumnasContazam);
var
  bTransaccionPropia: Boolean;
  iColumna: Integer;
begin
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
  begin
    FConexion.StartTransaction;
  end;
  try
    BorrarColumnas(AFormulario);
    BorrarVentana(AFormulario);
    InsertarVentana(AFormulario, APerfil);
    for iColumna := 0 to Length(AColumnas) - 1 do
    begin
      InsertarColumna(AFormulario, AColumnas[iColumna]);
    end;
    if bTransaccionPropia then
    begin
      FConexion.Commit;
    end;
  except
    if bTransaccionPropia and FConexion.InTransaction then
    begin
      FConexion.Rollback;
    end;
    raise;
  end;
end;

procedure TRepositorioPerfilesVentana.InsertarColumna(
  const AFormulario: string;
  const AColumna: TPerfilColumnaContazam);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO cza_perfiles_ventanas_columnas (' +
      'CODIGO_EMP_PVC, CODIGO_USU_PVC, FORMULARIO_PVC, GRID_PVC, ' +
      'CAMPO_PVC, NOMBRE_PVC, ORDEN_PVC, ESVISIBLE_PVC, ANCHO_PVC, ' +
      'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
      ':EMPRESA, :USUARIO, :FORMULARIO, :GRID, :CAMPO, :NOMBRE, ' +
      ':ORDEN, :VISIBLE, :ANCHO, NOW(), :USUARIO_ALTA)';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
    oConsulta.ParamByName('GRID').AsString := AColumna.Grid;
    oConsulta.ParamByName('CAMPO').AsString := AColumna.Campo;
    oConsulta.ParamByName('NOMBRE').AsString := AColumna.Nombre;
    oConsulta.ParamByName('ORDEN').AsInteger := AColumna.Orden;
    if AColumna.EsVisible then
    begin
      oConsulta.ParamByName('VISIBLE').AsString := 'S';
    end
    else
    begin
      oConsulta.ParamByName('VISIBLE').AsString := 'N';
    end;
    oConsulta.ParamByName('ANCHO').AsInteger := AColumna.Ancho;
    oConsulta.ParamByName('USUARIO_ALTA').AsString := FUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPerfilesVentana.InsertarVentana(
  const AFormulario: string;
  const APerfil: TPerfilVentanaContazam);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO cza_perfiles_ventanas (' +
      'CODIGO_EMP_PVE, CODIGO_USU_PVE, FORMULARIO_PVE, NOMBRE_PVE, ' +
      'POSICION_IZQUIERDA_PVE, POSICION_SUPERIOR_PVE, ANCHO_PVE, ' +
      'ALTO_PVE, ESTADO_PVE, PESTANA_ACTIVA_PVE, ' +
      'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
      ':EMPRESA, :USUARIO, :FORMULARIO, :NOMBRE, :IZQUIERDA, ' +
      ':SUPERIOR, :ANCHO, :ALTO, :ESTADO, :PESTANA, ' +
      'NOW(), :USUARIO_ALTA)';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
    oConsulta.ParamByName('NOMBRE').AsString := APerfil.Nombre;
    oConsulta.ParamByName('IZQUIERDA').AsInteger :=
      APerfil.PosicionIzquierda;
    oConsulta.ParamByName('SUPERIOR').AsInteger :=
      APerfil.PosicionSuperior;
    oConsulta.ParamByName('ANCHO').AsInteger := APerfil.Ancho;
    oConsulta.ParamByName('ALTO').AsInteger := APerfil.Alto;
    oConsulta.ParamByName('ESTADO').AsString := APerfil.Estado;
    oConsulta.ParamByName('PESTANA').AsString := APerfil.PestanaActiva;
    oConsulta.ParamByName('USUARIO_ALTA').AsString := FUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
