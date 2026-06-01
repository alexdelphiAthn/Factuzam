{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPermisos                                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cache y consulta de permisos (fza_permisos).                              }
{    Resolucion: administradores siempre S; luego usuario, grupo y Todos.      }
{    Se precarga al login.                                                     }
{******************************************************************************}
unit inLibPermisos;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DBAccess, Uni;

type
  TPermisosCache = class
  private
    // Diccionario: 'GRUPO|CODIGO' -> 'S'/'N'
    FPermisos: TDictionary<string, string>;
    FCargada: Boolean;
    FEsAdmin: Boolean;
    function Clave(const AGrupo, ACodigo: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Precargar(AConn: TUniConnection;
                        const AUser, AGroup: string;
                        AEsAdmin: Boolean);
    procedure Invalidar;
    // Consulta un permiso. Prioridad:
    //   1. Administrador -> siempre True
    //   2. Grupo del usuario -> valor guardado
    //   3. 'Todos' -> valor guardado
    //   4. ADefault (si no existe la clave)
    function TienePermiso(const ACodigo: string;
                          ADefault: Boolean = True): Boolean;
    property Cargada: Boolean read FCargada;
  end;

var
  oPermisos: TPermisosCache;

implementation

uses
  inLibLog, inLibGlobalVar;

constructor TPermisosCache.Create;
begin
  inherited Create;
  FPermisos := TDictionary<string, string>.Create;
  FCargada := False;
  FEsAdmin := False;
end;

destructor TPermisosCache.Destroy;
begin
  FreeAndNil(FPermisos);
  inherited;
end;

function TPermisosCache.Clave(const AGrupo, ACodigo: string): string;
begin
  Result := LowerCase(AGrupo) + '|' + LowerCase(ACodigo);
end;

procedure TPermisosCache.Invalidar;
begin
  FPermisos.Clear;
  FCargada := False;
end;

procedure TPermisosCache.Precargar(AConn: TUniConnection;
                                   const AUser, AGroup: string;
                                   AEsAdmin: Boolean);
var
  qry: TUniQuery;
begin
  FPermisos.Clear;
  FCargada := False;
  FEsAdmin := AEsAdmin;
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  try
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConn;
      qry.SQL.Text :=
        'SELECT USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM ' +
        '  FROM fza_permisos ' +
        ' WHERE USUARIO_GRUPO_PERM IN (:u, :g, :a) ' +
        ' ORDER BY USUARIO_GRUPO_PERM';
      qry.ParamByName('u').AsString := AUser;
      qry.ParamByName('g').AsString := AGroup;
      qry.ParamByName('a').AsString := 'Todos';
      qry.Open;
      while not qry.Eof do
      begin
        FPermisos.AddOrSetValue(
          Clave(qry.FieldByName('USUARIO_GRUPO_PERM').AsString,
                qry.FieldByName('CODIGO_PERM').AsString),
          qry.FieldByName('VALOR_PERM').AsString);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
    FCargada := True;
    Log.LogInfo(Format('PermisosCache: precargados %d permisos, esAdmin=%s',
      [FPermisos.Count, BoolToStr(FEsAdmin, True)]));
  except
    on E: Exception do
    begin
      FPermisos.Clear;
      Log.LogError('PermisosCache.Precargar: ' + E.Message);
    end;
  end;
end;

function TPermisosCache.TienePermiso(const ACodigo: string;
                                     ADefault: Boolean): Boolean;
var
  sValor: string;
begin
  // Administradores: siempre permitido
  if FEsAdmin then
  begin
    Result := True;
    Exit;
  end;
  if not FCargada then
  begin
    Result := ADefault;
    Exit;
  end;
  // Resolucion por prioridad: usuario > grupo > Todos. La precarga trae las
  // tres si existen; aqui consultamos en ese orden y nos quedamos con el
  // primero que aparezca (el de mayor prioridad).
  if FPermisos.TryGetValue(Clave(inLibGlobalVar.oUser, ACodigo), sValor) then
    Result := (sValor = 'S')
  else if FPermisos.TryGetValue(Clave(inLibGlobalVar.oGroup, ACodigo), sValor) then
    Result := (sValor = 'S')
  else if FPermisos.TryGetValue(Clave('Todos', ACodigo), sValor) then
    Result := (sValor = 'S')
  else
    Result := ADefault;
end;

end.
