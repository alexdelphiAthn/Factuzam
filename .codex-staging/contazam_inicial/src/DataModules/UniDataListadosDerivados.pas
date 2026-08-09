{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataListadosDerivados                                     }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia UniDAC de formatos FastReport derivados y sus versiones.    }
{******************************************************************************}
unit UniDataListadosDerivados;

interface

uses
  Uni, inLibListadosDerivadosIntf;

function CrearRepositorioListadosDerivados(
  AConexion: TUniConnection): IRepositorioListadosDerivados;

implementation

uses
  System.Classes, System.SysUtils, Data.DB, inLibContadoresIntf,
  UniDataContadoresRepositorio;

type
  TRepositorioListadosDerivados = class(
    TInterfacedObject,
    IRepositorioListadosDerivados)
  private
    FConexion: TUniConnection;
    FContadores: IContadorDocumentos;
    procedure AsignarAlcance(
      AConsulta: TUniQuery;
      const AAlcance: TAlcanceListadoDerivado);
    procedure AsignarContexto(
      AConsulta: TUniQuery;
      const AContexto: TContextoListadosDerivados);
    function NormalizarAlcance(
      const AContexto: TContextoListadosDerivados;
      const AAlcance: TAlcanceListadoDerivado):
      TAlcanceListadoDerivado;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function BuscarId(
      const AContexto: TContextoListadosDerivados;
      const ANombre: string;
      const AAlcance: TAlcanceListadoDerivado): Int64;
    function Guardar(
      const ASolicitud: TSolicitudGuardarListadoDerivado;
      AContenido: TStream): TListadoDerivado;
    function Leer(
      const AContexto: TContextoListadosDerivados;
      AId: Int64;
      AContenido: TStream): Boolean;
    function Listar(
      const AContexto: TContextoListadosDerivados): TListadosDerivados;
    function ListarGrupos(
      const AUsuario: string): TGruposListadoDerivado;
  end;

const
  SqlAccesoListado =
    ' AND (L.ALCANCE_LISDER = ''GLOBAL'' ' +
    'OR (L.ALCANCE_LISDER = ''EMPRESA'' ' +
    'AND L.CODIGO_EMP_LISDER = :EMPRESA) ' +
    'OR (L.ALCANCE_LISDER = ''USUARIO'' ' +
    'AND L.CODIGO_USU_LISDER = :USUARIO) ' +
    'OR (L.ALCANCE_LISDER = ''GRUPO'' AND EXISTS (' +
    'SELECT 1 FROM cza_usuarios_grupos UG ' +
    'WHERE UG.CODIGO_USU_UGR = :USUARIO ' +
    'AND UG.CODIGO_GRU_UGR = L.CODIGO_GRU_LISDER ' +
    'AND UG.ESACTIVO_UGR = ''S''))) ';

function CrearRepositorioListadosDerivados(
  AConexion: TUniConnection): IRepositorioListadosDerivados;
begin
  Result := TRepositorioListadosDerivados.Create(AConexion);
end;

constructor TRepositorioListadosDerivados.Create(
  AConexion: TUniConnection);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited Create;
  FConexion := AConexion;
  FContadores := CrearRepositorioContadores(FConexion);
end;

destructor TRepositorioListadosDerivados.Destroy;
begin
  FContadores := nil;
  inherited;
end;

procedure TRepositorioListadosDerivados.AsignarAlcance(
  AConsulta: TUniQuery;
  const AAlcance: TAlcanceListadoDerivado);
begin
  AConsulta.ParamByName('ALCANCE').AsString := AAlcance.Alcance;
  AConsulta.ParamByName('EMPRESA_ALCANCE').AsString := AAlcance.Empresa;
  AConsulta.ParamByName('GRUPO_ALCANCE').AsString := AAlcance.Grupo;
  AConsulta.ParamByName('USUARIO_ALCANCE').AsString := AAlcance.Usuario;
end;

procedure TRepositorioListadosDerivados.AsignarContexto(
  AConsulta: TUniQuery;
  const AContexto: TContextoListadosDerivados);
begin
  AConsulta.ParamByName('RECURSO').AsString :=
    UpperCase(Trim(AContexto.RecursoBase));
  AConsulta.ParamByName('EMPRESA').AsString :=
    UpperCase(Trim(AContexto.Empresa));
  AConsulta.ParamByName('USUARIO').AsString :=
    UpperCase(Trim(AContexto.Usuario));
end;

function TRepositorioListadosDerivados.NormalizarAlcance(
  const AContexto: TContextoListadosDerivados;
  const AAlcance: TAlcanceListadoDerivado): TAlcanceListadoDerivado;
begin
  Result := Default(TAlcanceListadoDerivado);
  Result.Alcance := UpperCase(Trim(AAlcance.Alcance));
  Result.Empresa := '*';
  if Result.Alcance = 'USUARIO' then
  begin
    Result.Usuario := UpperCase(Trim(AContexto.Usuario));
  end
  else if Result.Alcance = 'GRUPO' then
  begin
    Result.Grupo := UpperCase(Trim(AAlcance.Grupo));
    if Result.Grupo = '' then
    begin
      raise EArgumentException.Create(
        'El alcance de grupo necesita un grupo válido.');
    end;
  end
  else if Result.Alcance = 'EMPRESA' then
  begin
    Result.Empresa := UpperCase(Trim(AContexto.Empresa));
  end
  else if Result.Alcance <> 'GLOBAL' then
  begin
    raise EArgumentException.CreateFmt(
      'El alcance %s no es válido para un listado derivado.',
      [AAlcance.Alcance]);
  end;
end;

function TRepositorioListadosDerivados.BuscarId(
  const AContexto: TContextoListadosDerivados;
  const ANombre: string;
  const AAlcance: TAlcanceListadoDerivado): Int64;
var
  oAlcance: TAlcanceListadoDerivado;
  oConsulta: TUniQuery;
begin
  Result := 0;
  oAlcance := NormalizarAlcance(AContexto, AAlcance);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ID_LISDER FROM cza_listados_derivados ' +
      'WHERE RECURSO_BASE_LISDER = :RECURSO ' +
      'AND NOMBRE_LISDER = :NOMBRE ' +
      'AND ALCANCE_LISDER = :ALCANCE ' +
      'AND CODIGO_EMP_LISDER = :EMPRESA_ALCANCE ' +
      'AND CODIGO_GRU_LISDER = :GRUPO_ALCANCE ' +
      'AND CODIGO_USU_LISDER = :USUARIO_ALCANCE ' +
      'AND ESACTIVO_LISDER = ''S'' LIMIT 1';
    oConsulta.ParamByName('RECURSO').AsString :=
      UpperCase(Trim(AContexto.RecursoBase));
    oConsulta.ParamByName('NOMBRE').AsString := Trim(ANombre);
    AsignarAlcance(oConsulta, oAlcance);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('ID_LISDER').AsLargeInt;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioListadosDerivados.Guardar(
  const ASolicitud: TSolicitudGuardarListadoDerivado;
  AContenido: TStream): TListadoDerivado;
var
  bTransaccionPropia: Boolean;
  iId: Int64;
  iVersion: Integer;
  oAlcance: TAlcanceListadoDerivado;
  oConsulta: TUniQuery;
begin
  if AContenido = nil then
  begin
    raise EArgumentNilException.Create('AContenido');
  end;
  if Trim(ASolicitud.Nombre) = '' then
  begin
    raise EArgumentException.Create(
      'El listado derivado necesita un nombre.');
  end;
  oAlcance := NormalizarAlcance(
    ASolicitud.Contexto,
    ASolicitud.Alcance);
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
  begin
    FConexion.StartTransaction;
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      iId := ASolicitud.Id;
      if iId = 0 then
      begin
        iId := FContadores.SiguienteNumero(
          'GLOBAL',
          0,
          'ID_LISTADO_DERIVADO',
          '-');
        iVersion := 1;
        oConsulta.SQL.Text :=
          'INSERT INTO cza_listados_derivados (' +
          'ID_LISDER, RECURSO_BASE_LISDER, NOMBRE_LISDER, ' +
          'DESCRIPCION_LISDER, ALCANCE_LISDER, ' +
          'CODIGO_EMP_LISDER, CODIGO_GRU_LISDER, ' +
          'CODIGO_USU_LISDER, CONTENIDO_FR3_LISDER, ' +
          'VERSION_LISDER, ESACTIVO_LISDER, ' +
          'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
          ':ID, :RECURSO, :NOMBRE, :DESCRIPCION, :ALCANCE, ' +
          ':EMPRESA_ALCANCE, :GRUPO_ALCANCE, ' +
          ':USUARIO_ALCANCE, :BLOB, :VERSION, ''S'', ' +
          'NOW(), :USUARIO_ACTUAL)';
      end
      else
      begin
        oConsulta.SQL.Text :=
          'SELECT VERSION_LISDER FROM cza_listados_derivados ' +
          'WHERE ID_LISDER = :ID AND RECURSO_BASE_LISDER = :RECURSO ' +
          'AND ESACTIVO_LISDER = ''S'' FOR UPDATE';
        oConsulta.ParamByName('ID').AsLargeInt := iId;
        oConsulta.ParamByName('RECURSO').AsString :=
          UpperCase(Trim(ASolicitud.Contexto.RecursoBase));
        oConsulta.Open;
        if oConsulta.IsEmpty then
        begin
          raise EInvalidOpException.Create(
            'El listado derivado que se quiere modificar no existe.');
        end;
        iVersion :=
          oConsulta.FieldByName('VERSION_LISDER').AsInteger + 1;
        oConsulta.Close;
        oConsulta.SQL.Text :=
          'UPDATE cza_listados_derivados SET ' +
          'NOMBRE_LISDER = :NOMBRE, ' +
          'DESCRIPCION_LISDER = :DESCRIPCION, ' +
          'ALCANCE_LISDER = :ALCANCE, ' +
          'CODIGO_EMP_LISDER = :EMPRESA_ALCANCE, ' +
          'CODIGO_GRU_LISDER = :GRUPO_ALCANCE, ' +
          'CODIGO_USU_LISDER = :USUARIO_ALCANCE, ' +
          'CONTENIDO_FR3_LISDER = :BLOB, ' +
          'VERSION_LISDER = :VERSION, INSTANTE_MODIF = NOW(), ' +
          'USUARIO_MODIF = :USUARIO_ACTUAL ' +
          'WHERE ID_LISDER = :ID ' +
          'AND RECURSO_BASE_LISDER = :RECURSO';
      end;
      oConsulta.ParamByName('ID').AsLargeInt := iId;
      oConsulta.ParamByName('RECURSO').AsString :=
        UpperCase(Trim(ASolicitud.Contexto.RecursoBase));
      oConsulta.ParamByName('NOMBRE').AsString :=
        Trim(ASolicitud.Nombre);
      oConsulta.ParamByName('DESCRIPCION').AsString :=
        Trim(ASolicitud.Descripcion);
      AsignarAlcance(oConsulta, oAlcance);
      oConsulta.ParamByName('VERSION').AsInteger := iVersion;
      oConsulta.ParamByName('USUARIO_ACTUAL').AsString :=
        UpperCase(Trim(ASolicitud.Contexto.Usuario));
      AContenido.Position := 0;
      oConsulta.ParamByName('BLOB').LoadFromStream(AContenido, ftBlob);
      oConsulta.ExecSQL;
      oConsulta.SQL.Text :=
        'INSERT INTO cza_listados_derivados_versiones (' +
        'ID_LISDER_LISVER, VERSION_LISVER, NOMBRE_LISVER, ' +
        'DESCRIPCION_LISVER, ALCANCE_LISVER, ' +
        'CODIGO_EMP_LISVER, CODIGO_GRU_LISVER, ' +
        'CODIGO_USU_LISVER, CONTENIDO_FR3_LISVER, ' +
        'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
        ':ID, :VERSION, :NOMBRE, :DESCRIPCION, :ALCANCE, ' +
        ':EMPRESA_ALCANCE, :GRUPO_ALCANCE, ' +
        ':USUARIO_ALCANCE, :BLOB, NOW(), :USUARIO_ACTUAL)';
      oConsulta.ParamByName('ID').AsLargeInt := iId;
      oConsulta.ParamByName('VERSION').AsInteger := iVersion;
      oConsulta.ParamByName('NOMBRE').AsString :=
        Trim(ASolicitud.Nombre);
      oConsulta.ParamByName('DESCRIPCION').AsString :=
        Trim(ASolicitud.Descripcion);
      AsignarAlcance(oConsulta, oAlcance);
      oConsulta.ParamByName('USUARIO_ACTUAL').AsString :=
        UpperCase(Trim(ASolicitud.Contexto.Usuario));
      AContenido.Position := 0;
      oConsulta.ParamByName('BLOB').LoadFromStream(AContenido, ftBlob);
      oConsulta.ExecSQL;
      if bTransaccionPropia then
      begin
        FConexion.Commit;
      end;
      Result := Default(TListadoDerivado);
      Result.Id := iId;
      Result.RecursoBase :=
        UpperCase(Trim(ASolicitud.Contexto.RecursoBase));
      Result.Nombre := Trim(ASolicitud.Nombre);
      Result.Descripcion := Trim(ASolicitud.Descripcion);
      Result.Alcance := oAlcance;
      Result.Version := iVersion;
      Result.UsuarioModificacion :=
        UpperCase(Trim(ASolicitud.Contexto.Usuario));
    except
      if bTransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioListadosDerivados.Leer(
  const AContexto: TContextoListadosDerivados;
  AId: Int64;
  AContenido: TStream): Boolean;
var
  oCampo: TBlobField;
  oConsulta: TUniQuery;
begin
  if AContenido = nil then
  begin
    raise EArgumentNilException.Create('AContenido');
  end;
  Result := False;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT L.CONTENIDO_FR3_LISDER ' +
      'FROM cza_listados_derivados L ' +
      'WHERE L.ID_LISDER = :ID ' +
      'AND L.RECURSO_BASE_LISDER = :RECURSO ' +
      'AND L.ESACTIVO_LISDER = ''S'' ' +
      SqlAccesoListado + 'LIMIT 1';
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    AsignarContexto(oConsulta, AContexto);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      oCampo := TBlobField(
        oConsulta.FieldByName('CONTENIDO_FR3_LISDER'));
      if not oCampo.IsNull then
      begin
        AContenido.Size := 0;
        oCampo.SaveToStream(AContenido);
        AContenido.Position := 0;
        Result := True;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioListadosDerivados.Listar(
  const AContexto: TContextoListadosDerivados): TListadosDerivados;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT L.ID_LISDER, L.RECURSO_BASE_LISDER, ' +
      'L.NOMBRE_LISDER, L.DESCRIPCION_LISDER, ' +
      'L.ALCANCE_LISDER, L.CODIGO_EMP_LISDER, ' +
      'L.CODIGO_GRU_LISDER, L.CODIGO_USU_LISDER, ' +
      'L.VERSION_LISDER, COALESCE(L.USUARIO_MODIF, ' +
      'L.USUARIO_ALTA) AS USUARIO_MODIFICACION ' +
      'FROM cza_listados_derivados L ' +
      'WHERE L.RECURSO_BASE_LISDER = :RECURSO ' +
      'AND L.ESACTIVO_LISDER = ''S'' ' +
      SqlAccesoListado +
      'ORDER BY L.NOMBRE_LISDER, L.ALCANCE_LISDER';
    AsignarContexto(oConsulta, AContexto);
    oConsulta.Open;
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iIndice + 1);
      Result[iIndice].Id :=
        oConsulta.FieldByName('ID_LISDER').AsLargeInt;
      Result[iIndice].RecursoBase :=
        oConsulta.FieldByName('RECURSO_BASE_LISDER').AsString;
      Result[iIndice].Nombre :=
        oConsulta.FieldByName('NOMBRE_LISDER').AsString;
      Result[iIndice].Descripcion :=
        oConsulta.FieldByName('DESCRIPCION_LISDER').AsString;
      Result[iIndice].Alcance.Alcance :=
        oConsulta.FieldByName('ALCANCE_LISDER').AsString;
      Result[iIndice].Alcance.Empresa :=
        oConsulta.FieldByName('CODIGO_EMP_LISDER').AsString;
      Result[iIndice].Alcance.Grupo :=
        oConsulta.FieldByName('CODIGO_GRU_LISDER').AsString;
      Result[iIndice].Alcance.Usuario :=
        oConsulta.FieldByName('CODIGO_USU_LISDER').AsString;
      Result[iIndice].Version :=
        oConsulta.FieldByName('VERSION_LISDER').AsInteger;
      Result[iIndice].UsuarioModificacion :=
        oConsulta.FieldByName('USUARIO_MODIFICACION').AsString;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioListadosDerivados.ListarGrupos(
  const AUsuario: string): TGruposListadoDerivado;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT UG.CODIGO_GRU_UGR FROM cza_usuarios_grupos UG ' +
      'JOIN cza_grupos G ON G.CODIGO_GRU = UG.CODIGO_GRU_UGR ' +
      'AND G.ESACTIVO_GRU = ''S'' ' +
      'WHERE UG.CODIGO_USU_UGR = :USUARIO ' +
      'AND UG.ESACTIVO_UGR = ''S'' ' +
      'ORDER BY UG.CODIGO_GRU_UGR';
    oConsulta.ParamByName('USUARIO').AsString :=
      UpperCase(Trim(AUsuario));
    oConsulta.Open;
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iIndice + 1);
      Result[iIndice] :=
        oConsulta.FieldByName('CODIGO_GRU_UGR').AsString;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
