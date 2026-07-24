program PruebasConexionesFase1;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Uni,
  inLibConexionesIntf in
    '..\..\src\Lib\inLibConexionesIntf.pas',
  inLibConexionesUniDAC in
    '..\..\src\Lib\inLibConexionesUniDAC.pas';

var
  Pruebas: Integer;
  Fallos: Integer;

procedure Comprobar(ACondicion: Boolean; const ANombre: string);
begin
  Inc(Pruebas);
  if ACondicion then
    Writeln('[OK] ', ANombre)
  else
  begin
    Inc(Fallos);
    Writeln('[ERROR] ', ANombre);
  end;
end;

procedure ProbarSinConexionPrincipal;
var
  Servicio: IServicioConexiones;
  ConexionTrabajo: TUniConnection;
  ExcepcionEsperada: Boolean;
begin
  Servicio := TServicioConexionesUniDAC.Create(nil);
  Comprobar(
    Servicio.ConexionPrincipal = nil,
    'El servicio admite una conexión principal ausente');
  Comprobar(
    not Servicio.Disponible,
    'El servicio sin conexión principal no está disponible');
  ConexionTrabajo := nil;
  ExcepcionEsperada := False;
  try
    ConexionTrabajo := Servicio.CrearConexion(
      nil,
      uctPrecarga);
  except
    on E: Exception do
      ExcepcionEsperada := True;
  end;
  Comprobar(
    ExcepcionEsperada,
    'No se crea trabajo sin conexión principal');
  FreeAndNil(ConexionTrabajo);
end;

procedure ProbarConexionPrincipal;
var
  Conexion: TUniConnection;
  Servicio: IServicioConexiones;
begin
  Conexion := TUniConnection.Create(nil);
  try
    Servicio := TServicioConexionesUniDAC.Create(Conexion);
    Comprobar(
      Servicio.ConexionPrincipal = Conexion,
      'El servicio publica la conexión persistente recibida');
    Comprobar(
      not Servicio.Disponible,
      'Una conexión principal cerrada no figura disponible');
    Servicio.Invalidar;
    Comprobar(
      Servicio.ConexionPrincipal = nil,
      'La invalidación elimina la referencia no propietaria');
    Servicio := nil;
  finally
    FreeAndNil(Conexion);
  end;
end;

begin
  Pruebas := 0;
  Fallos := 0;
  try
    ProbarSinConexionPrincipal;
    ProbarConexionPrincipal;
  except
    on E: Exception do
    begin
      Inc(Fallos);
      Writeln('[EXCEPCION] ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln;
  Writeln('Pruebas: ', Pruebas, ' | Fallos: ', Fallos);
  if Fallos = 0 then
    ExitCode := 0
  else
    ExitCode := 1;
end.
