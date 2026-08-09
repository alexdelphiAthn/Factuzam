program PruebaIntegracionListados;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  inLibListadosTipos in
    '..\src\Lib\inLibListadosTipos.pas',
  UniDataConexion in
    '..\src\DataModules\UniDataConexion.pas',
  UniDataGen in
    '..\src\DataModules\UniDataGen.pas',
  UniDataListados in
    '..\src\DataModules\UniDataListados.pas';

procedure EjecutarPrueba;
var
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oListados: TdmListados;
  oTipo: TTipoListadoContable;
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
    oListados := TdmListados.Create(
      nil,
      oConexion.Conexion,
      '001',
      2026);
    try
      for oTipo := Low(TTipoListadoContable) to
        High(TTipoListadoContable) do
      begin
        oListados.Consultar(
          oTipo,
          EncodeDate(2026, 1, 1),
          EncodeDate(2026, 12, 31),
          '');
      end;
    finally
      FreeAndNil(oListados);
    end;
  finally
    FreeAndNil(oConexion);
  end;
end;

begin
  try
    EjecutarPrueba;
    Writeln('LISTADOS_SQL=OK');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
