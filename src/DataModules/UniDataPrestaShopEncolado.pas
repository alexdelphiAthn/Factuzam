{
  Encolado dirigido de cambios de catalogo para PrestaShop.
  Todas las llamadas usan la conexion que confirma el cambio de negocio.
}
unit UniDataPrestaShopEncolado;

interface

uses
  Uni;

procedure EncolarCambioPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, ACodigoSku: string;
  AEsPrecio, AEsStock: Boolean;
  const AUsuario: string);
procedure EncolarPrecioPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
procedure EncolarArticuloPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
procedure OmitirArticuloPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
procedure EncolarStockAlmacenPrestaShop(
  AConexion: TUniConnection;
  const ACodigoAlmacen, AUsuario: string);
procedure EncolarTodosWebPrestaShop(
  AConexion: TUniConnection;
  AEsPrecio, AEsStock: Boolean;
  const AUsuario: string);
function LeerCodigoTarifaPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string): string;
function LeerCodigoEmpresaPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string): string;
function LeerGrupoIvaEmpresaPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string): string;

implementation

uses
  System.SysUtils, Data.DB;

function Indicador(AValor: Boolean): string;
begin
  if AValor then
    Result := 'S'
  else
    Result := 'N';
end;

procedure EncolarCambioPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, ACodigoSku: string;
  AEsPrecio, AEsStock: Boolean;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if (Trim(ACodigoArticulo) <> '') or
     (Trim(ACodigoSku) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'CALL PRC_PRESTASHOP_ENCOLAR_CAMBIO(' +
        ':ARTICULO, :SKU, :PRECIO, :STOCK, :USUARIO)';
      oConsulta.ParamByName('ARTICULO').AsString :=
        Trim(ACodigoArticulo);
      oConsulta.ParamByName('SKU').AsString := Trim(ACodigoSku);
      oConsulta.ParamByName('PRECIO').AsString := Indicador(AEsPrecio);
      oConsulta.ParamByName('STOCK').AsString := Indicador(AEsStock);
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function LeerParametroPerfilPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string;
  const AParametro, ADefecto: string): string;
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := ADefecto;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT P.VALUE_USUPER AS VALOR ' +
      'FROM fza_usuarios_perfiles P ' +
      'WHERE P.KEY_USUPER = ''frmMtoAppParam'' ' +
      'AND P.SUBKEY_USUPER = :PARAMETRO ' +
      'AND (P.USUARIO_GRUPO_USUPER = :USUARIO ' +
      'OR P.USUARIO_GRUPO_USUPER = ''Todos'' ' +
      'OR P.USUARIO_GRUPO_USUPER = (' +
      'SELECT U.GRUPO_USU FROM fza_usuarios U ' +
      'WHERE U.USUARIO_USU = :USUARIO)) ' +
      'ORDER BY CASE ' +
      'WHEN P.USUARIO_GRUPO_USUPER = :USUARIO THEN 1 ' +
      'WHEN P.USUARIO_GRUPO_USUPER = (' +
      'SELECT U.GRUPO_USU FROM fza_usuarios U ' +
      'WHERE U.USUARIO_USU = :USUARIO) THEN 2 ELSE 3 END ' +
      'LIMIT 1';
    oConsulta.ParamByName('PARAMETRO').AsString := AParametro;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Open;
    if not oConsulta.FieldByName('VALOR').IsNull then
      Result := Trim(oConsulta.FieldByName('VALOR').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function LeerCodigoTarifaPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string): string;
begin
  Result := LeerParametroPerfilPrestaShop(
    AConexion,
    AUsuario,
    'appPrestaShopTarifa',
    'PVP');
end;

function LeerCodigoEmpresaPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string): string;
begin
  Result := LeerParametroPerfilPrestaShop(
    AConexion,
    AUsuario,
    'appPrestaShopEmpresa',
    '1');
end;

function LeerGrupoIvaEmpresaPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string): string;
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT GRUPO_ZONA_IVA_EMP ' +
      'FROM fza_empresas ' +
      'WHERE CODIGO_EMP_EMP = :EMPRESA';
    oConsulta.ParamByName('EMPRESA').AsString :=
      LeerCodigoEmpresaPrestaShop(AConexion, AUsuario);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := Trim(
        oConsulta.FieldByName('GRUPO_ZONA_IVA_EMP').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EncolarStockAlmacenPrestaShop(
  AConexion: TUniConnection;
  const ACodigoAlmacen, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(ACodigoAlmacen) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'CALL PRC_PRESTASHOP_ENCOLAR_STOCK_ALMACEN(' +
        ':ALMACEN, :USUARIO)';
      oConsulta.ParamByName('ALMACEN').AsString :=
        Trim(ACodigoAlmacen);
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure EncolarTodosWebPrestaShop(
  AConexion: TUniConnection;
  AEsPrecio, AEsStock: Boolean;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if AEsPrecio or AEsStock then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'CALL PRC_PRESTASHOP_ENCOLAR_TODOS_WEB(' +
        ':PRECIO, :STOCK, :USUARIO)';
      oConsulta.ParamByName('PRECIO').AsString := Indicador(AEsPrecio);
      oConsulta.ParamByName('STOCK').AsString := Indicador(AEsStock);
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure EncolarPrecioPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
begin
  EncolarCambioPrestaShop(
    AConexion,
    ACodigoArticulo,
    '',
    True,
    False,
    AUsuario);
end;

procedure EncolarArticuloPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
begin
  EncolarCambioPrestaShop(
    AConexion,
    ACodigoArticulo,
    '',
    True,
    True,
    AUsuario);
end;

procedure OmitirArticuloPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
begin
  EncolarCambioPrestaShop(
    AConexion,
    ACodigoArticulo,
    '',
    False,
    False,
    AUsuario);
end;

end.
