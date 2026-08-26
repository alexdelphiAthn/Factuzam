program BenchmarkBBDD;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MySQLUniProvider,
  PostgreSQLUniProvider,
  Uni;

procedure Probar(const AMotor, AHost, APuerto, ABase, AUsuario,
  AClave: string);
var
  Conexion: TUniConnection;
  Consulta: TUniQuery;
begin
  Conexion := TUniConnection.Create(nil);
  Consulta := TUniQuery.Create(nil);
  try
    if SameText(AMotor, 'mariadb') then
      Conexion.ProviderName := 'MySQL'
    else
      Conexion.ProviderName := 'PostgreSQL';
    Conexion.LoginPrompt := False;
    Conexion.Server := AHost;
    Conexion.Port := StrToInt(APuerto);
    Conexion.Database := ABase;
    Conexion.Username := AUsuario;
    Conexion.Password := AClave;
    if SameText(AMotor, 'mariadb') then
    begin
      Conexion.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
      Conexion.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
    end
    else
    begin
      Conexion.SpecificOptions.Values['PostgreSQL.UseUnicode'] := 'True';
      Conexion.SpecificOptions.Values['PostgreSQL.Charset'] := 'UTF8';
      Conexion.SpecificOptions.Values['PostgreSQL.SSLMode'] := 'smDisable';
    end;
    Conexion.Connect;
    Consulta.Connection := Conexion;
    Consulta.SQL.Text := 'select version()';
    Consulta.Open;
    Writeln(Consulta.Fields[0].AsString);
  finally
    Consulta.Free;
    Conexion.Free;
  end;
end;

begin
  try
    if ParamCount <> 5 then
      raise Exception.Create('Uso: motor host puerto base usuario');
    Probar(ParamStr(1), ParamStr(2), ParamStr(3), ParamStr(4), ParamStr(5),
      GetEnvironmentVariable('FACTUZAM_BENCH_PASSWORD'));
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
