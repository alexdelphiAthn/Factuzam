{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPermisosAdmin                                            }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Administracion de permisos (fza_permisos) para la pantalla de gestion.    }
{    Listado de sujetos (Todos / grupos / usuarios), alta-baja de permisos     }
{    por sujeto y transferencia (copia) de permisos entre sujetos.             }
{    La consulta en runtime sigue en inLibPermisos; esta unit es la cara de    }
{    escritura que consume inMtoPermisosArbol.                                 }
{******************************************************************************}
unit inLibPermisosAdmin;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, Uni;

type
  // Tipo de sujeto sobre el que recaen los permisos.
  TTipoSujeto = (tsTodos, tsGrupo, tsUsuario);

  // Un sujeto editable: 'Todos', un grupo o un usuario.
  TPermisoSujeto = record
    Tipo   : TTipoSujeto;
    Nombre : string;   // 'Todos' / nombre de grupo / nombre de usuario
    Grupo  : string;   // para usuarios: su grupo; en otro caso ''
    EsAdmin: Boolean;  // grupo administrador (o usuario de grupo admin)
  end;

  // Un codigo de permiso conocido y su descripcion representativa.
  TPermisoCodigo = record
    Codigo      : string;
    Descripcion : string;
  end;

  TPermisosAdmin = class
  private
    class function NuevaQuery(AConn: TUniConnection): TUniQuery;
  public
    // Devuelve 'Todos' + todos los grupos + todos los usuarios.
    class function ListarSujetos(
      AConn: TUniConnection): TArray<TPermisoSujeto>;
    // Universo de codigos de permiso ya registrados en la tabla.
    class function CatalogoCodigos(
      AConn: TUniConnection): TArray<TPermisoCodigo>;
    // Filas explicitas (codigo -> 'S'/'N') de un sujeto concreto. El
    // diccionario devuelto es propiedad del llamador (debe liberarlo).
    class function CargarExplicitos(AConn: TUniConnection;
      const ASujeto: string): TDictionary<string, string>;
    // Alta o actualizacion de un permiso explicito del sujeto.
    class procedure Establecer(AConn: TUniConnection;
      const ASujeto, ACodigo, AValor, ADescripcion: string);
    // Borra la fila explicita: el sujeto vuelve a heredar.
    class procedure Heredar(AConn: TUniConnection;
      const ASujeto, ACodigo: string);
    // Copia los permisos de AOrigen a ADestino. Si AReemplazar, borra
    // antes los del destino (respetando el filtro ASoloMenu). Devuelve
    // el numero de permisos del origen volcados.
    class function Copiar(AConn: TUniConnection;
      const AOrigen, ADestino: string;
      AReemplazar, ASoloMenu: Boolean): Integer;
  end;

implementation

uses
  inLibGlobalVar;

class function TPermisosAdmin.NuevaQuery(AConn: TUniConnection): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := AConn;
end;

class function TPermisosAdmin.ListarSujetos(
  AConn: TUniConnection): TArray<TPermisoSujeto>;
var
  lst: TList<TPermisoSujeto>;
  qry: TUniQuery;
  reg: TPermisoSujeto;
begin
  lst := TList<TPermisoSujeto>.Create;
  try
    reg.Tipo    := tsTodos;
    reg.Nombre  := 'Todos';
    reg.Grupo   := '';
    reg.EsAdmin := False;
    lst.Add(reg);
    if (AConn <> nil) and (AConn.Connected) then
    begin
      qry := NuevaQuery(AConn);
      try
        qry.SQL.Text :=
          'SELECT GRUPO_USUGRP, ' +
          '       COALESCE(ESGRUPOADMINISTRADOR_USUGRP, ''N'') AS ADM ' +
          '  FROM fza_usuarios_grupos ' +
          ' ORDER BY GRUPO_USUGRP';
        qry.Open;
        while not qry.Eof do
        begin
          reg.Tipo    := tsGrupo;
          reg.Nombre  := qry.FieldByName('GRUPO_USUGRP').AsString;
          reg.Grupo   := '';
          reg.EsAdmin := (qry.FieldByName('ADM').AsString = 'S');
          lst.Add(reg);
          qry.Next;
        end;
        qry.Close;
        qry.SQL.Text :=
          'SELECT u.USUARIO_USU, ' +
          '       COALESCE(u.GRUPO_USU, '''') AS G, ' +
          '       COALESCE(g.ESGRUPOADMINISTRADOR_USUGRP, ''N'') AS ADM ' +
          '  FROM fza_usuarios u ' +
          '  LEFT JOIN fza_usuarios_grupos g ' +
          '    ON g.GRUPO_USUGRP = u.GRUPO_USU ' +
          ' ORDER BY u.USUARIO_USU';
        qry.Open;
        while not qry.Eof do
        begin
          reg.Tipo    := tsUsuario;
          reg.Nombre  := qry.FieldByName('USUARIO_USU').AsString;
          reg.Grupo   := qry.FieldByName('G').AsString;
          reg.EsAdmin := (qry.FieldByName('ADM').AsString = 'S');
          lst.Add(reg);
          qry.Next;
        end;
      finally
        FreeAndNil(qry);
      end;
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

class function TPermisosAdmin.CatalogoCodigos(
  AConn: TUniConnection): TArray<TPermisoCodigo>;
var
  lst: TList<TPermisoCodigo>;
  qry: TUniQuery;
  reg: TPermisoCodigo;
begin
  lst := TList<TPermisoCodigo>.Create;
  try
    if (AConn <> nil) and (AConn.Connected) then
    begin
      qry := NuevaQuery(AConn);
      try
        qry.SQL.Text :=
          'SELECT CODIGO_PERM, ' +
          '       MAX(COALESCE(DESCRIPCION_PERM, '''')) AS DESCR ' +
          '  FROM fza_permisos ' +
          ' GROUP BY CODIGO_PERM ' +
          ' ORDER BY CODIGO_PERM';
        qry.Open;
        while not qry.Eof do
        begin
          reg.Codigo      := qry.FieldByName('CODIGO_PERM').AsString;
          reg.Descripcion := qry.FieldByName('DESCR').AsString;
          lst.Add(reg);
          qry.Next;
        end;
      finally
        FreeAndNil(qry);
      end;
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

class function TPermisosAdmin.CargarExplicitos(AConn: TUniConnection;
  const ASujeto: string): TDictionary<string, string>;
var
  qry: TUniQuery;
begin
  Result := TDictionary<string, string>.Create;
  if (AConn <> nil) and (AConn.Connected) and (ASujeto <> '') then
  begin
    qry := NuevaQuery(AConn);
    try
      qry.SQL.Text :=
        'SELECT CODIGO_PERM, VALOR_PERM ' +
        '  FROM fza_permisos ' +
        ' WHERE USUARIO_GRUPO_PERM = :S';
      qry.ParamByName('S').AsString := ASujeto;
      qry.Open;
      while not qry.Eof do
      begin
        Result.AddOrSetValue(
          qry.FieldByName('CODIGO_PERM').AsString,
          qry.FieldByName('VALOR_PERM').AsString);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

class procedure TPermisosAdmin.Establecer(AConn: TUniConnection;
  const ASujeto, ACodigo, AValor, ADescripcion: string);
var
  qry: TUniQuery;
begin
  if (AConn <> nil) and (AConn.Connected) and
     (ASujeto <> '') and (ACodigo <> '') then
  begin
    qry := NuevaQuery(AConn);
    try
      qry.SQL.Text :=
        'INSERT INTO fza_permisos ' +
        '  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, ' +
        '   DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'VALUES (:S, :C, :V, :D, NOW(), :UA) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  VALOR_PERM       = :V2, ' +
        '  DESCRIPCION_PERM = COALESCE(:D2, DESCRIPCION_PERM), ' +
        '  INSTANTE_MODIF   = NOW(), ' +
        '  USUARIO_MODIF    = :UM';
      qry.ParamByName('S').AsString  := ASujeto;
      qry.ParamByName('C').AsString  := ACodigo;
      qry.ParamByName('V').AsString  := AValor;
      qry.ParamByName('D').AsString  := ADescripcion;
      qry.ParamByName('UA').AsString := inLibGlobalVar.oUser;
      qry.ParamByName('V2').AsString := AValor;
      qry.ParamByName('D2').AsString := ADescripcion;
      qry.ParamByName('UM').AsString := inLibGlobalVar.oUser;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

class procedure TPermisosAdmin.Heredar(AConn: TUniConnection;
  const ASujeto, ACodigo: string);
var
  qry: TUniQuery;
begin
  if (AConn <> nil) and (AConn.Connected) and
     (ASujeto <> '') and (ACodigo <> '') then
  begin
    qry := NuevaQuery(AConn);
    try
      qry.SQL.Text :=
        'DELETE FROM fza_permisos ' +
        ' WHERE USUARIO_GRUPO_PERM = :S ' +
        '   AND CODIGO_PERM = :C';
      qry.ParamByName('S').AsString := ASujeto;
      qry.ParamByName('C').AsString := ACodigo;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

class function TPermisosAdmin.Copiar(AConn: TUniConnection;
  const AOrigen, ADestino: string;
  AReemplazar, ASoloMenu: Boolean): Integer;
var
  qry: TUniQuery;
  sFiltro: string;
begin
  Result := 0;
  if (AConn <> nil) and (AConn.Connected) and
     (AOrigen <> '') and (ADestino <> '') and
     (not SameText(AOrigen, ADestino)) then
  begin
    if ASoloMenu then
      sFiltro := ' AND CODIGO_PERM LIKE ''menu.%'' '
    else
      sFiltro := ' ';
    if not AConn.InTransaction then
      AConn.StartTransaction;
    qry := NuevaQuery(AConn);
    try
      try
        qry.SQL.Text :=
          'SELECT COUNT(*) AS N FROM fza_permisos ' +
          ' WHERE USUARIO_GRUPO_PERM = :O' + sFiltro;
        qry.ParamByName('O').AsString := AOrigen;
        qry.Open;
        Result := qry.FieldByName('N').AsInteger;
        qry.Close;
        if AReemplazar then
        begin
          qry.SQL.Text :=
            'DELETE FROM fza_permisos ' +
            ' WHERE USUARIO_GRUPO_PERM = :D' + sFiltro;
          qry.ParamByName('D').AsString := ADestino;
          qry.ExecSQL;
        end;
        qry.SQL.Text :=
          'INSERT INTO fza_permisos ' +
          '  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, ' +
          '   DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA) ' +
          'SELECT :D2, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, ' +
          '       NOW(), :UA ' +
          '  FROM fza_permisos ' +
          ' WHERE USUARIO_GRUPO_PERM = :O2' + sFiltro +
          'ON DUPLICATE KEY UPDATE ' +
          '  VALOR_PERM       = VALUES(VALOR_PERM), ' +
          '  DESCRIPCION_PERM = VALUES(DESCRIPCION_PERM), ' +
          '  INSTANTE_MODIF   = NOW(), ' +
          '  USUARIO_MODIF    = :UM';
        qry.ParamByName('D2').AsString := ADestino;
        qry.ParamByName('UA').AsString := inLibGlobalVar.oUser;
        qry.ParamByName('O2').AsString := AOrigen;
        qry.ParamByName('UM').AsString := inLibGlobalVar.oUser;
        qry.ExecSQL;
        if AConn.InTransaction then
          AConn.Commit;
      except
        on E: Exception do
        begin
          if AConn.InTransaction then
            AConn.Rollback;
          raise;
        end;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

end.
