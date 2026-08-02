{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaProcesador                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Procesador UniDAC de la cola Verifactu y worker con conexión propia.      }
{******************************************************************************}
unit UniDataVerifactuColaProcesador;
interface
uses
  System.Classes, Uni, inLibConexionesIntf, inLibParametrosIntf,
  inLibContextoSesionIntf, inLibVerifactuColaIntf, inLibLogIntf;
type
  TContextoProcesadorVerifactuCola = record
    Conexiones: IServicioConexiones;
    ContextoSesion: IContextoSesionAplicacion;
    ParametrosApp: IParametrosAplicacion;
    ParametrosCaja: IParametrosCaja;
    RegistroLog: IRegistroLog;
    Usuario: string;
  end;
  THiloVerifactuCola = class(TThread)
  private
    FConn: TUniConnection;
    FContexto: TContextoProcesadorVerifactuCola;
    FAvisoNoDisponible: Boolean;
    function PuedeContinuar: Boolean;
    procedure ProcesarPendientes;
    function ProcesarFila(AIdCola: Int64;
      const ASerie, ANumero, ATipoOperacion: string;
      AIntentos: Integer): Integer;
    procedure EsperarCiclo;
    procedure EsperarSegundos(ASegundos: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContexto: TContextoProcesadorVerifactuCola); reintroduce;
    destructor Destroy; override;
  end;
function CrearProcesadorVerifactuColaUniDAC(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog = nil): IProcesadorVerifactuCola;
implementation
uses
  Winapi.Windows, System.SysUtils, inLibVerifactu,
  inLibVerifactuTipos, inLibVerifactuEnvio,
  UniDataVerifactuColaResultados;
const
  fidvfcola       = 'ID_VFCOLA';
  fserievfcola    = 'SERIE_FAC_VFCOLA';
  fnumerovfcola   = 'NUMERO_FAC_VFCOLA';
  ftipoopvfcola   = 'TIPO_OPERACION_VFCOLA';
  fintentosvfcola = 'CONTADOR_INTENTOS_VFCOLA';
type
  TProcesadorVerifactuColaUniDAC = class(
    TInterfacedObject,
    IProcesadorVerifactuCola)
  private
    FContexto: TContextoProcesadorVerifactuCola;
    FHilo: THiloVerifactuCola;
    FIniciado: Boolean;
  public
    constructor Create(
      const AContexto: TContextoProcesadorVerifactuCola);
    destructor Destroy; override;
    procedure Iniciar;
    procedure Detener;
  end;
function CrearProcesadorVerifactuColaUniDAC(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog): IProcesadorVerifactuCola;
var
  oContexto: TContextoProcesadorVerifactuCola;
begin
  oContexto := Default(TContextoProcesadorVerifactuCola);
  oContexto.Conexiones := AConexiones;
  oContexto.ContextoSesion := AContextoSesion;
  oContexto.ParametrosApp := AParametrosApp;
  oContexto.ParametrosCaja := AParametrosCaja;
  oContexto.Usuario := AUsuario;
  oContexto.RegistroLog := ARegistroLog;
  Result := TProcesadorVerifactuColaUniDAC.Create(oContexto);
end;
constructor TProcesadorVerifactuColaUniDAC.Create(
  const AContexto: TContextoProcesadorVerifactuCola);
begin
  if not Assigned(AContexto.Conexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContexto.ContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AContexto.ParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AContexto.ParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create;
  FContexto := AContexto;
  FHilo := nil;
  FIniciado := False;
end;
destructor TProcesadorVerifactuColaUniDAC.Destroy;
begin
  Detener;
  FContexto := Default(TContextoProcesadorVerifactuCola);
  inherited;
end;
procedure TProcesadorVerifactuColaUniDAC.Iniciar;
begin
  if not FIniciado then
  begin
    FHilo := THiloVerifactuCola.Create(FContexto);
    try
      FHilo.FreeOnTerminate := False;
      FHilo.Start;
      FIniciado := True;
      if Assigned(FContexto.RegistroLog) then
        FContexto.RegistroLog.RegistrarInformacion(
          'Cola Verifactu: hilo iniciado');
    except
      FreeAndNil(FHilo);
      raise;
    end;
  end;
end;
procedure TProcesadorVerifactuColaUniDAC.Detener;
begin
  if FIniciado then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    FIniciado := False;
    if Assigned(FContexto.RegistroLog) then
      FContexto.RegistroLog.RegistrarInformacion(
        'Cola Verifactu: hilo detenido');
  end;
end;
// ===========================================================================
//   THiloVerifactuCola — worker en segundo plano
// ===========================================================================
constructor THiloVerifactuCola.Create(
  const AContexto: TContextoProcesadorVerifactuCola);
begin
  if not Assigned(AContexto.Conexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContexto.ContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AContexto.ParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AContexto.ParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create(True);
  FContexto := AContexto;
end;
destructor THiloVerifactuCola.Destroy;
begin
  FreeAndNil(FConn);
  FContexto := Default(TContextoProcesadorVerifactuCola);
  inherited;
end;
procedure THiloVerifactuCola.Execute;
begin
  NameThreadForDebugging('VerifactuCola');
  FAvisoNoDisponible := False;
  while (not Terminated) and
        (not FContexto.ContextoSesion.CerrandoAplicacion) do
  begin
    // La espera va primero: deja respirar el arranque de la app y
    // permite cerrar sin procesar nada a medias
    EsperarCiclo;
    if (not Terminated) and
       (not FContexto.ContextoSesion.CerrandoAplicacion) and
       (ModoVerifactu(FContexto.ParametrosApp) = mvVerifactu) then
    begin
      try
        ProcesarPendientes;
      except
        on E: Exception do
        begin
          if Assigned(FContexto.RegistroLog) then
            FContexto.RegistroLog.RegistrarError(
              'Cola Verifactu: ' + E.Message);
          // Si la conexión propia quedó inservible se recrea al
          // siguiente ciclo
          FreeAndNil(FConn);
        end;
      end;
    end;
  end;
end;
procedure THiloVerifactuCola.EsperarCiclo;
var
  iSegundos: Integer;
begin
  iSegundos := FContexto.ParametrosApp.GetInt('appVerifactuSegundosCiclo', 60);
  if iSegundos < 5 then
    iSegundos := 5;
  EsperarSegundos(iSegundos);
end;
function THiloVerifactuCola.PuedeContinuar: Boolean;
begin
  Result := not Terminated;
  if Result then
    Result := not FContexto.ContextoSesion.CerrandoAplicacion;
end;
procedure THiloVerifactuCola.EsperarSegundos(ASegundos: Integer);
var
  iPasos: Integer;
  iPaso:  Integer;
begin
  // Tope de cordura y espera troceada en pasos de 100 ms para
  // reaccionar rápido a la parada del hilo
  if ASegundos > 300 then
    ASegundos := 300;
  iPasos := ASegundos * 10;
  iPaso  := 0;
  while (iPaso < iPasos) and PuedeContinuar do
  begin
    Sleep(100);
    Inc(iPaso);
  end;
end;
procedure THiloVerifactuCola.ProcesarPendientes;
var
  Qry:     TUniQuery;
  iEspera: Integer;
begin
  if FConn = nil then
    FConn := FContexto.Conexiones.CrearConexion(
      nil,
      uctSegundoPlano);
  if not EnvioVerifactuDisponible then
  begin
    // Cliente de envío desactivado: la cola se acumula en PENDIENTE.
    // Se deja constancia una sola vez por sesión.
    if not FAvisoNoDisponible then
    begin
      RegistrarEventoVerifactu(
        FContexto.ParametrosApp, FConn, FContexto.Usuario,
        cEventoVerifactuInfo,
        'Cola Verifactu activa sin cliente de envío AEAT disponible: ' +
        'las facturas quedan en estado PENDIENTE');
      FAvisoNoDisponible := True;
    end;
  end
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConn;
      // Rescate de filas PROCESANDO huérfanas (cierre brusco de la app)
      Qry.SQL.Text :=
        ' UPDATE fza_verifactu_cola ' +
        ' SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
        '     INSTANTE_MODIF = NOW() ' +
        ' WHERE ESTADO_VFCOLA = ''PROCESANDO'' ' +
        '   AND INSTANTE_MODIF < DATE_SUB(NOW(), INTERVAL 10 MINUTE)';
      Qry.Execute;
      // Reproceso: filas en ERROR con menos intentos que el máximo
      // vigente vuelven a la cola (p.ej. tras corregir configuración,
      // resetear intentos a mano o subir appVerifactuMaxIntentos)
      Qry.SQL.Text :=
        ' UPDATE fza_verifactu_cola ' +
        ' SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
        '     INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
        '     INSTANTE_MODIF = NOW() ' +
        ' WHERE ESTADO_VFCOLA = ''ERROR'' ' +
        '   AND CONTADOR_INTENTOS_VFCOLA < :MAXINTENTOS';
      Qry.ParamByName('MAXINTENTOS').AsInteger :=
        FContexto.ParametrosApp.GetInt('appVerifactuMaxIntentos', 10);
      Qry.Execute;
      Qry.SQL.Text :=
        ' SELECT ID_VFCOLA, SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, ' +
        '        TIPO_OPERACION_VFCOLA, CONTADOR_INTENTOS_VFCOLA ' +
        ' FROM fza_verifactu_cola ' +
        ' WHERE ESTADO_VFCOLA = ''PENDIENTE'' ' +
        '   AND (INSTANTE_PROXIMO_INTENTO_VFCOLA IS NULL ' +
        '        OR INSTANTE_PROXIMO_INTENTO_VFCOLA <= NOW()) ' +
        ' ORDER BY ID_VFCOLA ' +
        ' LIMIT 25';
      Qry.Open;
      while (not Qry.Eof) and PuedeContinuar do
      begin
        iEspera := ProcesarFila(Qry.FieldByName(fidvfcola).AsLargeInt,
                                Qry.FieldByName(fserievfcola).AsString,
                                Qry.FieldByName(fnumerovfcola).AsString,
                                Qry.FieldByName(ftipoopvfcola).AsString,
                                Qry.FieldByName(fintentosvfcola).AsInteger);
        // Control de flujo de la AEAT entre envíos consecutivos
        if iEspera > 0 then
          EsperarSegundos(iEspera);
        Qry.Next;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;
function THiloVerifactuCola.ProcesarFila(AIdCola: Int64;
                                         const ASerie, ANumero,
                                         ATipoOperacion: string;
                                         AIntentos: Integer): Integer;
var
  Qry:        TUniQuery;
  bReclamada: Boolean;
  oResultado: TResultadoEnvioVerifactu;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    // Reclamo optimista: si otro puesto se adelantó, aquí no se procesa
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''PROCESANDO'', ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID ' +
      '   AND ESTADO_VFCOLA = ''PENDIENTE''';
    Qry.ParamByName('USUARIO').AsString := FContexto.Usuario;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
    bReclamada := (Qry.RowsAffected = 1);
  finally
    FreeAndNil(Qry);
  end;
  if bReclamada then
  begin
    // Transacción del envío: el FOR UPDATE de fza_verifactu_cadena que
    // toma EnviarRegistroFactura serializa el encadenamiento entre
    // puestos hasta el commit/rollback
    FConn.StartTransaction;
    try
      oResultado := EnviarRegistroFactura(FContexto.ParametrosApp, FConn,
        FContexto.Usuario, ASerie, ANumero, ATipoOperacion);
      if oResultado.Ok then
      begin
        // El registro YA está aceptado por la AEAT: si fallara la
        // persistencia local se anota la verdad y el reintento se
        // resolverá por la vía del registro duplicado
        try
          TResultadosVerifactuColaUniDAC.GuardarEnvioOk(
            FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
            FContexto.Usuario,
            AIdCola, ASerie, ANumero, ATipoOperacion, oResultado,
            FContexto.RegistroLog);
          FConn.Commit;
          Result := oResultado.EsperaSegundos;
        except
          on E: Exception do
          begin
            if FConn.InTransaction then
              FConn.Rollback;
            TResultadosVerifactuColaUniDAC.GuardarEnvioError(
              FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
              FContexto.Usuario,
              AIdCola, ASerie, ANumero,
              'Aceptado por la AEAT pero falló la persistencia ' +
              'local: ' + E.Message, AIntentos, FContexto.RegistroLog);
          end;
        end;
      end
      else
      begin
        FConn.Rollback;
        TResultadosVerifactuColaUniDAC.GuardarEnvioError(
          FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
          FContexto.Usuario,
          AIdCola, ASerie, ANumero, oResultado.MensajeError, AIntentos,
          FContexto.RegistroLog);
      end;
    except
      on E: Exception do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        TResultadosVerifactuColaUniDAC.GuardarEnvioError(
          FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
          FContexto.Usuario,
          AIdCola, ASerie, ANumero, E.Message, AIntentos,
          FContexto.RegistroLog);
      end;
    end;
  end;
end;
end.
