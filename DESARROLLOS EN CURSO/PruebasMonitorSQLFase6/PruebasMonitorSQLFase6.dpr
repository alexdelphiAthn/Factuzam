program PruebasMonitorSQLFase6;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UniSQLMonitor,
  inLibMonitorSQLIntf in
    '..\..\src\Lib\inLibMonitorSQLIntf.pas',
  inLibMonitorSQLUniDAC in
    '..\..\src\Lib\inLibMonitorSQLUniDAC.pas';

type
  TRegistroMonitorPrueba = class(
    TInterfacedObject,
    IRegistroMonitorSQL
  )
  private
    FActivo: Boolean;
    FRegistros: Integer;
    FVisualizaciones: Integer;
    FUltimoSQLRegistrado: string;
    FUltimoSQLMostrado: string;
    FUltimoError: string;
    FUltimoOk: Boolean;
    FUltimoTiempoMs: Int64;
    function GetMonitorizacionActiva: Boolean;
  public
    procedure RegistrarSQL(
      const ASQL: string;
      ATiempoMs: Int64;
      AOk: Boolean;
      const AError: string
    );
    procedure MostrarSQL(const ASQL: string);
    property Activo: Boolean read FActivo write FActivo;
    property Registros: Integer read FRegistros;
    property Visualizaciones: Integer read FVisualizaciones;
    property UltimoSQLRegistrado: string read FUltimoSQLRegistrado;
    property UltimoSQLMostrado: string read FUltimoSQLMostrado;
    property UltimoError: string read FUltimoError;
    property UltimoOk: Boolean read FUltimoOk;
    property UltimoTiempoMs: Int64 read FUltimoTiempoMs;
  end;

var
  Pruebas: Integer;
  Fallos: Integer;

function TRegistroMonitorPrueba.GetMonitorizacionActiva: Boolean;
begin
  Result := FActivo;
end;

procedure TRegistroMonitorPrueba.RegistrarSQL(
  const ASQL: string;
  ATiempoMs: Int64;
  AOk: Boolean;
  const AError: string);
begin
  Inc(FRegistros);
  FUltimoSQLRegistrado := ASQL;
  FUltimoTiempoMs := ATiempoMs;
  FUltimoOk := AOk;
  FUltimoError := AError;
end;

procedure TRegistroMonitorPrueba.MostrarSQL(const ASQL: string);
begin
  Inc(FVisualizaciones);
  FUltimoSQLMostrado := ASQL;
end;

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

procedure CrearServicio(
  AMonitor: TUniSQLMonitor;
  out ARegistroObjeto: TRegistroMonitorPrueba;
  out ARegistro: IRegistroMonitorSQL;
  out AServicio: IServicioMonitorSQL;
  out AReceptor: IReceptorEventosMonitorSQL);
begin
  ARegistroObjeto := TRegistroMonitorPrueba.Create;
  ARegistro := ARegistroObjeto;
  AServicio := TServicioMonitorSQLUniDAC.Create(
    AMonitor,
    ARegistro);
  AReceptor := AServicio as IReceptorEventosMonitorSQL;
end;

procedure ProbarEjecucionFinalizada;
var
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
begin
  CrearServicio(
    nil,
    RegistroObjeto,
    Registro,
    Servicio,
    Receptor);
  RegistroObjeto.Activo := True;
  Receptor.ProcesarEvento('SELECT 1', emsEjecutar);
  Comprobar(
    RegistroObjeto.Visualizaciones = 1,
    'La ejecución activa se muestra en el monitor');
  Comprobar(
    RegistroObjeto.Registros = 0,
    'La ejecución queda pendiente hasta recibir su final');
  Receptor.ProcesarEvento('', emsFinalizar);
  Comprobar(
    (RegistroObjeto.Registros = 1) and
    RegistroObjeto.UltimoOk and
    (RegistroObjeto.UltimoSQLRegistrado = 'SELECT 1'),
    'El evento final registra la sentencia correcta');
  Comprobar(
    RegistroObjeto.UltimoTiempoMs >= 0,
    'El tiempo registrado nunca es negativo');
end;

procedure ProbarError;
var
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
begin
  CrearServicio(
    nil,
    RegistroObjeto,
    Registro,
    Servicio,
    Receptor);
  RegistroObjeto.Activo := True;
  Receptor.ProcesarEvento('SELECT error', emsEjecutar);
  Receptor.ProcesarEvento('Error simulado', emsError);
  Comprobar(
    (RegistroObjeto.Registros = 1) and
    not RegistroObjeto.UltimoOk,
    'El error cierra la sentencia como fallida');
  Comprobar(
    RegistroObjeto.UltimoError = 'Error simulado',
    'El texto del error llega al registro');
end;

procedure ProbarCierreExplicito;
var
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
begin
  CrearServicio(
    nil,
    RegistroObjeto,
    Registro,
    Servicio,
    Receptor);
  RegistroObjeto.Activo := True;
  Receptor.ProcesarEvento('SELECT modal', emsEjecutar);
  Servicio.CerrarPendiente;
  Comprobar(
    (RegistroObjeto.Registros = 1) and
    (RegistroObjeto.UltimoSQLRegistrado = 'SELECT modal'),
    'El cierre explícito vuelca la sentencia antes de un modal');
  Servicio.CerrarPendiente;
  Comprobar(
    RegistroObjeto.Registros = 1,
    'Cerrar sin sentencia pendiente no duplica el registro');
end;

procedure ProbarMonitorDesactivado;
var
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
begin
  CrearServicio(
    nil,
    RegistroObjeto,
    Registro,
    Servicio,
    Receptor);
  RegistroObjeto.Activo := False;
  Receptor.ProcesarEvento('SELECT oculto', emsEjecutar);
  Receptor.ProcesarEvento('', emsFinalizar);
  Comprobar(
    (RegistroObjeto.Registros = 0) and
    (RegistroObjeto.Visualizaciones = 0),
    'El monitor desactivado no registra ni muestra SQL');
end;

procedure ProbarDesactivacionDescartaPendiente;
var
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
begin
  CrearServicio(
    nil,
    RegistroObjeto,
    Registro,
    Servicio,
    Receptor);
  RegistroObjeto.Activo := True;
  Receptor.ProcesarEvento('SELECT descartado', emsEjecutar);
  Servicio.EstablecerActivo(False);
  Servicio.CerrarPendiente;
  Comprobar(
    RegistroObjeto.Registros = 0,
    'Desactivar el monitor descarta la sentencia pendiente');
end;

procedure ProbarSentenciasConsecutivas;
var
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
begin
  CrearServicio(
    nil,
    RegistroObjeto,
    Registro,
    Servicio,
    Receptor);
  RegistroObjeto.Activo := True;
  Receptor.ProcesarEvento('SELECT primero', emsEjecutar);
  Receptor.ProcesarEvento('SELECT segundo', emsEjecutar);
  Comprobar(
    (RegistroObjeto.Registros = 1) and
    (RegistroObjeto.UltimoSQLRegistrado = 'SELECT primero') and
    (RegistroObjeto.UltimoSQLMostrado = 'SELECT segundo'),
    'Una nueva ejecución cierra la sentencia anterior');
  Servicio.CerrarPendiente;
  Comprobar(
    (RegistroObjeto.Registros = 2) and
    (RegistroObjeto.UltimoSQLRegistrado = 'SELECT segundo'),
    'La segunda sentencia permanece como nuevo pendiente');
end;

procedure ProbarControlComponente;
var
  Monitor: TUniSQLMonitor;
  RegistroObjeto: TRegistroMonitorPrueba;
  Registro: IRegistroMonitorSQL;
  Servicio: IServicioMonitorSQL;
  Receptor: IReceptorEventosMonitorSQL;
  SinExcepcion: Boolean;
begin
  Monitor := TUniSQLMonitor.Create(nil);
  try
    CrearServicio(
      Monitor,
      RegistroObjeto,
      Registro,
      Servicio,
      Receptor);
    Servicio.EstablecerActivo(False);
    Comprobar(
      not Monitor.Active,
      'El servicio desactiva el componente UniDAC');
    Servicio.EstablecerActivo(True);
    Comprobar(
      Monitor.Active,
      'El servicio activa el componente UniDAC');
    Servicio.EstablecerActivo(False);
    Servicio.Invalidar;
    SinExcepcion := True;
    try
      Servicio.EstablecerActivo(True);
      Servicio.CerrarPendiente;
    except
      SinExcepcion := False;
    end;
    Comprobar(
      SinExcepcion,
      'El servicio invalidado ignora operaciones posteriores');
  finally
    FreeAndNil(Monitor);
  end;
end;

begin
  Pruebas := 0;
  Fallos := 0;
  try
    ProbarEjecucionFinalizada;
    ProbarError;
    ProbarCierreExplicito;
    ProbarMonitorDesactivado;
    ProbarDesactivacionDescartaPendiente;
    ProbarSentenciasConsecutivas;
    ProbarControlComponente;
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
