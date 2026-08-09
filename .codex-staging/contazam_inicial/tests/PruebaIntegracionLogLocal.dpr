program PruebaIntegracionLogLocal;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibDir in
    '..\src\Lib\inLibDir.pas',
  inLibLogIntf in
    '..\src\Lib\inLibLogIntf.pas',
  inLibLog in
    '..\src\Lib\inLibLog.pas';

var
  oRegistro: IRegistroLogContazam;
  sArchivo: string;

begin
  try
    oRegistro := CrearRegistroLogContazam;
    sArchivo := oRegistro.RutaArchivo;
    oRegistro.RegistrarInformacion(
      'Prueba de integración del registro local.');
    oRegistro := nil;
    if FileExists(sArchivo) and
      ExtractFileDir(sArchivo).StartsWith(GetLogFolder, True) then
    begin
      Writeln('LOG_LOCAL=OK');
      Writeln('ARCHIVO=', sArchivo);
      ExitCode := 0;
    end
    else
    begin
      Writeln('LOG_LOCAL=ERROR');
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
