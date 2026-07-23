{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPermisosUniDAC                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Carga desde MariaDB las reglas usadas por el servicio de permisos.        }
{******************************************************************************}
unit inLibPermisosUniDAC;

interface

uses
  Uni,
  inLibPermisosIntf;

type
  TCargadorPermisosUniDAC = class
  public
    class function Cargar(
      AConexion: TUniConnection;
      const AIdentidad: TIdentidadPermisos
    ): IPermisosAplicacion;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibPermisos;

class function TCargadorPermisosUniDAC.Cargar(
  AConexion: TUniConnection;
  const AIdentidad: TIdentidadPermisos): IPermisosAplicacion;
var
  qry: TUniQuery;
  Reglas: TList<TReglaPermiso>;
  Regla: TReglaPermiso;
begin
  if (AConexion = nil) or (not AConexion.Connected) then
    raise Exception.Create(
      'No hay conexión disponible para cargar los permisos.');
  Reglas := TList<TReglaPermiso>.Create;
  try
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConexion;
      qry.SQL.Text :=
        'SELECT USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM' +
        '  FROM fza_permisos' +
        ' WHERE USUARIO_GRUPO_PERM IN (:U, :G, :A)';
      qry.ParamByName('U').AsString := AIdentidad.Usuario;
      qry.ParamByName('G').AsString := AIdentidad.Grupo;
      qry.ParamByName('A').AsString := 'Todos';
      qry.Open;
      while not qry.Eof do
      begin
        Regla := TReglaPermiso.Crear(
          qry.FieldByName('USUARIO_GRUPO_PERM').AsString,
          qry.FieldByName('CODIGO_PERM').AsString,
          SameText(qry.FieldByName('VALOR_PERM').AsString, 'S'));
        Reglas.Add(Regla);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
    Result := TPermisosAplicacion.Create(
      AIdentidad,
      Reglas.ToArray,
      True);
  finally
    FreeAndNil(Reglas);
  end;
end;

end.
