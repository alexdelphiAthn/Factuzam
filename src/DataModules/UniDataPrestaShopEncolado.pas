{
  Encolado dirigido de cambios de catalogo para PrestaShop.
  Todas las llamadas usan la conexion que confirma el cambio de negocio.
}
unit UniDataPrestaShopEncolado;

interface

uses
  Uni, inLibPrestaShopColaIntf;

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
procedure EncolarVisibilidadPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  AAccion: TAccionVisibilidadPrestaShop;
  const AUsuario: string);
procedure RegistrarPublicacionAplazadaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  AAccion: TAccionVisibilidadPrestaShop;
  AAccionExplicita: Boolean;
  const AMensaje, AUsuario: string);
function ReanudarPublicacionAplazadaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string): Boolean;
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
  System.SysUtils, Data.DB, inLibPrestaCatalogo,
  inLibPrestaShopColaSenal;

const
  CMarcaGuardadoArticuloPrestaShop = '[GUARDADO_ARTICULO] ';

function Indicador(AValor: Boolean): string;
begin
  if AValor then
    Result := 'S'
  else
    Result := 'N';
end;

function AccionVisibilidad(
  AAccion: TAccionVisibilidadPrestaShop): string;
begin
  case AAccion of
    avpActivar:
      Result := 'A';
    avpDesactivar:
      Result := 'D';
  else
    Result := 'N';
  end;
end;

procedure EncolarVisibilidadPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  AAccion: TAccionVisibilidadPrestaShop;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(ACodigoArticulo) = '' then
    raise EArgumentException.Create('ACodigoArticulo');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_ENCOLAR_VISIBILIDAD(' +
      ':ARTICULO, :ACCION, :USUARIO)';
    oConsulta.ParamByName('ARTICULO').AsString :=
      Trim(ACodigoArticulo);
    oConsulta.ParamByName('ACCION').AsString :=
      AccionVisibilidad(AAccion);
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
    if not AConexion.InTransaction then
      SolicitarProcesadoPrestaShop;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EjecutarEncoladoVisibilidadPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AAccion, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_ENCOLAR_VISIBILIDAD(' +
      ':ARTICULO, :ACCION, :USUARIO)';
    oConsulta.ParamByName('ARTICULO').AsString :=
      Trim(ACodigoArticulo);
    oConsulta.ParamByName('ACCION').AsString := AAccion;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
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
      if not AConexion.InTransaction then
        SolicitarProcesadoPrestaShop;
      // La UoW transaccional debe señalizar después del Commit.
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

function ObtenerDestinoPublicacionPrestaShop(
  AConexion: TUniConnection;
  const AUsuario: string;
  out AClaveInstalacion: string;
  out AIdTienda: Integer): Boolean;
var
  sUrl: string;
begin
  sUrl := LeerParametroPerfilPrestaShop(
    AConexion,
    AUsuario,
    'appPrestaShopUrl',
    '');
  AIdTienda := StrToIntDef(
    LeerParametroPerfilPrestaShop(
      AConexion,
      AUsuario,
      'appPrestaShopIdTienda',
      '1'),
    0);
  Result := (sUrl <> '') and (AIdTienda > 0);
  if Result then
    AClaveInstalacion := CalcularClaveInstalacionPresta(sUrl)
  else
    AClaveInstalacion := '';
end;

procedure RegistrarPublicacionAplazadaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  AAccion: TAccionVisibilidadPrestaShop;
  AAccionExplicita: Boolean;
  const AMensaje, AUsuario: string);
var
  bTransaccionPropia: Boolean;
  iIdTienda: Integer;
  oConsulta: TUniQuery;
  sAccionAnterior: string;
  sClaveInstalacion: string;
  sMensaje: string;
  sUsuarioAuditoria: string;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(ACodigoArticulo) = '' then
    raise EArgumentException.Create('ACodigoArticulo');
  if AAccion = avpDesactivar then
    raise EArgumentException.Create(
      'Una publicacion aplazada no puede desactivar el articulo');
  sMensaje := Trim(AMensaje);
  if sMensaje = '' then
    sMensaje := 'No se completo el guardado del articulo';
  sMensaje := Copy(
    CMarcaGuardadoArticuloPrestaShop + sMensaje,
    1,
    4000);
  sUsuarioAuditoria := Copy(Trim(AUsuario), 1, 50);
  if sUsuarioAuditoria = '' then
    sUsuarioAuditoria := 'PRESTASHOP';
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    if not ObtenerDestinoPublicacionPrestaShop(
      AConexion,
      AUsuario,
      sClaveInstalacion,
      iIdTienda) then
      raise EDatabaseError.Create(
        'Faltan URL o tienda para aplazar la publicacion PrestaShop');
    if not AAccionExplicita then
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'SELECT ACCION_VISIBILIDAD_PSCOLA ' +
          'FROM fza_prestashop_cola ' +
          'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
          'AND ID_TIENDA_PSCOLA = :TIENDA ' +
          'AND CODIGO_ART_PSCOLA = :ARTICULO ' +
          'AND ESTADO_PSCOLA = ''ERROR'' ' +
          'AND LEFT(COALESCE(MENSAJE_ERROR_PSCOLA, ''''), 20) = ' +
          ':MARCA FOR UPDATE';
        oConsulta.ParamByName('INSTALACION').AsString :=
          sClaveInstalacion;
        oConsulta.ParamByName('TIENDA').AsInteger := iIdTienda;
        oConsulta.ParamByName('ARTICULO').AsString :=
          Trim(ACodigoArticulo);
        oConsulta.ParamByName('MARCA').AsString :=
          CMarcaGuardadoArticuloPrestaShop;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
        begin
          sAccionAnterior := UpperCase(Trim(
            oConsulta.FieldByName(
              'ACCION_VISIBILIDAD_PSCOLA').AsString));
          if sAccionAnterior = 'A' then
            AAccion := avpActivar
          else if sAccionAnterior <> 'N' then
            raise EDatabaseError.Create(
              'La publicacion aplazada de PrestaShop no es valida');
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end;
    EjecutarEncoladoVisibilidadPrestaShop(
      AConexion,
      ACodigoArticulo,
      AccionVisibilidad(AAccion),
      AUsuario);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'UPDATE fza_prestashop_cola SET ' +
        'ESTADO_PSCOLA = ''ERROR'', ' +
        'CONTADOR_INTENTOS_PSCOLA = 0, ' +
        'INSTANTE_PROXIMO_INTENTO_PSCOLA = NULL, ' +
        'MENSAJE_ERROR_PSCOLA = :MENSAJE, ' +
        'VERSION_RECLAMADA_PSCOLA = NULL, ' +
        'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
        'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
        'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = ''N'', ' +
        'ID_RECLAMACION_PSCOLA = NULL, ' +
        'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
        'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
        'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
        'AND ID_TIENDA_PSCOLA = :TIENDA ' +
        'AND CODIGO_ART_PSCOLA = :ARTICULO';
      oConsulta.ParamByName('MENSAJE').AsMemo := sMensaje;
      oConsulta.ParamByName('USUARIO').AsString :=
        sUsuarioAuditoria;
      oConsulta.ParamByName('INSTALACION').AsString :=
        sClaveInstalacion;
      oConsulta.ParamByName('TIENDA').AsInteger := iIdTienda;
      oConsulta.ParamByName('ARTICULO').AsString :=
        Trim(ACodigoArticulo);
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise EDatabaseError.Create(
          'No se pudo registrar la publicacion aplazada de PrestaShop');
    finally
      FreeAndNil(oConsulta);
    end;
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Commit;
  except
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

function ReanudarPublicacionAplazadaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string): Boolean;
var
  bTransaccionPropia: Boolean;
  iIdTienda: Integer;
  oConsulta: TUniQuery;
  sAccion: string;
  sClaveInstalacion: string;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(ACodigoArticulo) = '' then
    raise EArgumentException.Create('ACodigoArticulo');
  Result := False;
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    if ObtenerDestinoPublicacionPrestaShop(
         AConexion,
         AUsuario,
         sClaveInstalacion,
         iIdTienda) then
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'SELECT ACCION_VISIBILIDAD_PSCOLA ' +
          'FROM fza_prestashop_cola ' +
          'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
          'AND ID_TIENDA_PSCOLA = :TIENDA ' +
          'AND CODIGO_ART_PSCOLA = :ARTICULO ' +
          'AND ESTADO_PSCOLA = ''ERROR'' ' +
          'AND LEFT(COALESCE(MENSAJE_ERROR_PSCOLA, ''''), 20) = ' +
          ':MARCA FOR UPDATE';
        oConsulta.ParamByName('INSTALACION').AsString :=
          sClaveInstalacion;
        oConsulta.ParamByName('TIENDA').AsInteger := iIdTienda;
        oConsulta.ParamByName('ARTICULO').AsString :=
          Trim(ACodigoArticulo);
        oConsulta.ParamByName('MARCA').AsString :=
          CMarcaGuardadoArticuloPrestaShop;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
        begin
          sAccion := UpperCase(Trim(
            oConsulta.FieldByName(
              'ACCION_VISIBILIDAD_PSCOLA').AsString));
          if (sAccion <> 'A') and (sAccion <> 'N') then
            raise EDatabaseError.Create(
              'La publicacion aplazada de PrestaShop no es valida');
          oConsulta.Close;
          EjecutarEncoladoVisibilidadPrestaShop(
            AConexion,
            ACodigoArticulo,
            sAccion,
            AUsuario);
          Result := True;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end;
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Commit;
  except
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
  if Result and bTransaccionPropia then
    SolicitarProcesadoPrestaShop;
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
      if not AConexion.InTransaction then
        SolicitarProcesadoPrestaShop;
      // La UoW transaccional debe señalizar después del Commit.
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
      if not AConexion.InTransaction then
        SolicitarProcesadoPrestaShop;
      // La UoW transaccional debe señalizar después del Commit.
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
