program PruebaIntegracionSeguridad;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Data.DB,
  Uni,
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  inLibSeguridadIntf in
    '..\src\Lib\inLibSeguridadIntf.pas',
  inLibContadoresIntf in
    '..\src\Lib\inLibContadoresIntf.pas',
  UniDataConexion in
    '..\src\DataModules\UniDataConexion.pas',
  UniDataContadoresRepositorio in
    '..\src\DataModules\UniDataContadoresRepositorio.pas',
  UniDataSeguridad in
    '..\src\DataModules\UniDataSeguridad.pas';

const
  UsuarioGlobal = 'TEST_GLOBAL';
  UsuarioEmpresa = 'TEST_EMPRESA';
  GrupoGlobal = 'TEST_GLOBAL';
  GrupoEmpresa = 'TEST_EMPRESA';

procedure EjecutarSql(
  AConexion: TUniConnection;
  const ASql: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure Limpiar(AConexion: TUniConnection);
begin
  EjecutarSql(
    AConexion,
    'DELETE FROM cza_auditoria_listados WHERE ' +
    'CODIGO_USU_AUL IN (''TEST_GLOBAL'', ''TEST_EMPRESA'')');
  EjecutarSql(
    AConexion,
    'DELETE FROM cza_usuarios_grupos WHERE ' +
    'CODIGO_USU_UGR IN (''TEST_GLOBAL'', ''TEST_EMPRESA'')');
  EjecutarSql(
    AConexion,
    'DELETE FROM cza_grupos_permisos WHERE ' +
    'CODIGO_GRU_GPE IN (''TEST_GLOBAL'', ''TEST_EMPRESA'')');
  EjecutarSql(
    AConexion,
    'DELETE FROM cza_grupos WHERE ' +
    'CODIGO_GRU IN (''TEST_GLOBAL'', ''TEST_EMPRESA'')');
  EjecutarSql(
    AConexion,
    'DELETE FROM cza_usuarios WHERE ' +
    'CODIGO_USU IN (''TEST_GLOBAL'', ''TEST_EMPRESA'')');
end;

procedure Preparar(AConexion: TUniConnection);
begin
  Limpiar(AConexion);
  EjecutarSql(
    AConexion,
    'INSERT INTO cza_usuarios (CODIGO_USU, NOMBRE_USU, ' +
    'ESACTIVO_USU, INSTANTE_ALTA, USUARIO_ALTA) VALUES ' +
    '(''TEST_GLOBAL'', ''Prueba global'', ''S'', NOW(), ''TEST''), ' +
    '(''TEST_EMPRESA'', ''Prueba empresa'', ''S'', NOW(), ''TEST'')');
  EjecutarSql(
    AConexion,
    'INSERT INTO cza_grupos (CODIGO_GRU, NOMBRE_GRU, ' +
    'ESACTIVO_GRU, INSTANTE_ALTA, USUARIO_ALTA) VALUES ' +
    '(''TEST_GLOBAL'', ''Prueba global'', ''S'', NOW(), ''TEST''), ' +
    '(''TEST_EMPRESA'', ''Prueba empresa'', ''S'', NOW(), ''TEST'')');
  EjecutarSql(
    AConexion,
    'INSERT INTO cza_usuarios_grupos (CODIGO_USU_UGR, ' +
    'CODIGO_GRU_UGR, ESACTIVO_UGR, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (''TEST_GLOBAL'', ''TEST_GLOBAL'', ''S'', NOW(), ''TEST''), ' +
    '(''TEST_EMPRESA'', ''TEST_EMPRESA'', ''S'', NOW(), ''TEST'')');
  EjecutarSql(
    AConexion,
    'INSERT INTO cza_grupos_permisos (CODIGO_GRU_GPE, ' +
    'RECURSO_GPE, ACCION_GPE, ALCANCE_GPE, CODIGO_EMP_GPE, ' +
    'ESACTIVO_GPE, INSTANTE_ALTA, USUARIO_ALTA) VALUES ' +
    '(''TEST_GLOBAL'', ''LISTADO_BALANCE'', ''CONSULTAR'', ' +
    '''GLOBAL'', ''*'', ''S'', NOW(), ''TEST''), ' +
    '(''TEST_EMPRESA'', ''LISTADO_BALANCE'', ''CONSULTAR'', ' +
    '''EMPRESA'', ''001'', ''S'', NOW(), ''TEST'')');
end;

procedure VerificarAuditoriaYContador(AConexion: TUniConnection);
var
  oConsulta: TUniQuery;
  sContador: string;
  iCeros: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_GRU_AUL, ALCANCE_AUL, CODIGO_EMP_AUL ' +
      'FROM cza_auditoria_listados WHERE ' +
      'CODIGO_USU_AUL = ''TEST_GLOBAL'' ' +
      'AND RECURSO_AUL = ''LISTADO_BALANCE'' ' +
      'ORDER BY ID_AUL DESC LIMIT 1';
    oConsulta.Open;
    if oConsulta.IsEmpty or
      not SameText(
        oConsulta.FieldByName('ALCANCE_AUL').AsString,
        'GLOBAL') then
    begin
      raise Exception.Create(
        'La auditoría no ha conservado el alcance global.');
    end;
    oConsulta.Close;
    oConsulta.SQL.Text :=
      'SELECT CONTADOR_CON, NUMERO_CEROS_CON ' +
      'FROM cza_contadores WHERE CODIGO_EMP_CON = ''GLOBAL'' ' +
      'AND EJERCICIO_CON = 0 ' +
      'AND TIPO_DOCUMENTO_CON = ''ID_AUDITORIA_LISTADO'' ' +
      'AND SERIE_CON = ''-''';
    oConsulta.Open;
    sContador := oConsulta.FieldByName('CONTADOR_CON').AsString;
    iCeros := oConsulta.FieldByName('NUMERO_CEROS_CON').AsInteger;
    if Length(sContador) <> 18 then
    begin
      raise Exception.Create(
        'El contador de auditoría no conserva sus 18 dígitos.');
    end;
    if iCeros <> Length(sContador) -
      Length(StringReplace(sContador, '0', '', [rfReplaceAll])) then
    begin
      raise Exception.Create(
        'NUMERO_CEROS_CON no cuenta todos los ceros del VARCHAR.');
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EjecutarPrueba;
var
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oSeguridadGlobal: IServicioSeguridadContazam;
  oSeguridadEmpresa: IServicioSeguridadContazam;
  bDenegado: Boolean;
begin
  oConfiguracion := Default(TConfiguracionContazam);
  oConfiguracion.Servidor := '127.0.0.1';
  oConfiguracion.Puerto := 3306;
  oConfiguracion.Usuario := 'root';
  oConfiguracion.Contrasena := GetEnvironmentVariable(
    'CONTAZAM_DB_PASSWORD');
  oConfiguracion.BaseDatos := 'contazam';
  oConexion := TdmConexion.Create(nil, oConfiguracion);
  try
    Preparar(oConexion.Conexion);
    try
      oSeguridadGlobal := CrearServicioSeguridad(
        oConexion.Conexion,
        UsuarioGlobal);
      oSeguridadEmpresa := CrearServicioSeguridad(
        oConexion.Conexion,
        UsuarioEmpresa);
      oSeguridadGlobal.ExigirPermiso(
        'LISTADO_BALANCE',
        'CONSULTAR',
        '002');
      oSeguridadEmpresa.ExigirPermiso(
        'LISTADO_BALANCE',
        'CONSULTAR',
        '001');
      bDenegado := False;
      try
        oSeguridadEmpresa.ExigirPermiso(
          'LISTADO_BALANCE',
          'CONSULTAR',
          '002');
      except
        on E: EAccesoContazamDenegado do
        begin
          bDenegado := True;
        end;
      end;
      if not bDenegado then
      begin
        raise Exception.Create(
          'Un permiso de empresa ha accedido a otra empresa.');
      end;
      oSeguridadGlobal.RegistrarUsoListado(
        'LISTADO_BALANCE',
        'CONSULTAR',
        '001',
        2026,
        EncodeDate(2026, 1, 1),
        EncodeDate(2026, 12, 31),
        '43',
        12,
        '');
      VerificarAuditoriaYContador(oConexion.Conexion);
    finally
      oSeguridadEmpresa := nil;
      oSeguridadGlobal := nil;
      Limpiar(oConexion.Conexion);
    end;
  finally
    FreeAndNil(oConexion);
  end;
end;

begin
  try
    EjecutarPrueba;
    Writeln('SEGURIDAD_ALCANCE_AUDITORIA=OK');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
