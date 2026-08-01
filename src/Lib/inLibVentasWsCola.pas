{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsCola                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola transaccional de eventos de venta y envío al webservice de respaldo. }
{    La persistencia entra por IRepositorioVentasWsCola.                       }
{******************************************************************************}
unit inLibVentasWsCola;

interface

uses
  System.SysUtils, System.Classes, inLibParametrosIntf,
  inLibContextoSesionIntf,
  inLibVentasWsJsonIntf, inLibVentasWsColaIntf;

type
  TVentasWsCola = class
  private
    FHilo: TThread;
    class function Activa(
      const AParametrosCaja: IParametrosCaja): Boolean; static;
    class procedure AdjuntarPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      AEsFactura: Boolean); static;
  public
    class procedure RegistrarFactura(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ATipoOperacion: string); static;
    class procedure RegistrarEventoSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ATipoEvento, ASerie, ANumero: string); static;
    class procedure AdjuntarTicketPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string); static;
    class procedure AdjuntarFacturaPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string); static;
    destructor Destroy; override;
    procedure IniciarHilo(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionVentasWs;
      const AUsuario: string);
    procedure DetenerHilo;
  end;

implementation

uses
  Winapi.Windows, System.Hash,
  inLibGlobalVar, inLibLog, inLibMsgIntegraciones,
  inLibVentasWsJson, inLibFactuzamApi;

type
  THiloVentasWsCola = class(TThread)
  private
    FSesion: ISesionVentasWs;
    FRepositorio: IRepositorioVentasWsCola;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FFabricaSesion: IFabricaSesionVentasWs;
    FUsuario: string;
    FAvisoConfiguracion: Boolean;
    procedure EsperarCiclo;
    procedure EsperarSegundos(ASegundos: Integer);
    procedure ProcesarPendientes;
    procedure ProcesarFila(AIdCola: Int64);
    procedure GuardarError(AIdCola: Int64; const AMensaje: string;
      AIntentos: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionVentasWs;
      const AUsuario: string); reintroduce;
    destructor Destroy; override;
  end;

function NuevoUuid: string;
var
  oGuid: TGUID;
  sGuid: string;
begin
  CreateGUID(oGuid);
  sGuid := GUIDToString(oGuid);
  Result := Copy(sGuid, 2, 36);
end;

class function TVentasWsCola.Activa(
  const AParametrosCaja: IParametrosCaja): Boolean;
begin
  Result := Assigned(AParametrosCaja) and
            AParametrosCaja.GetBool('vgerEnviarVentasWS', False);
end;

class procedure TVentasWsCola.RegistrarFactura(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ATipoOperacion: string);
var
  iIdCola: Int64;
  sTipoEvento: string;
begin
  if Activa(AParametrosCaja) then
  begin
    if SameText(ATipoOperacion, 'ANULACION') then
      sTipoEvento := 'VENTA_ANULADA'
    else if SameText(ATipoOperacion, 'SUSTITUCION') then
      sTipoEvento := 'VENTA_SUSTITUIDA'
    else if SameText(ATipoOperacion, 'SUBSANACION') then
      sTipoEvento := 'FISCAL_ACTUALIZADO'
    else
      sTipoEvento := 'VENTA_CONFIRMADA';
    // La cola se escribe dentro de la transacción del llamador: el
    // repositorio trabaja sobre la misma conexión de AQryTrx.
    iIdCola := ARepositorio.Encolar(
      NuevoUuid, sTipoEvento, ASerie, ANumero, AUsuario);
    if iIdCola = 0 then
      raise Exception.CreateFmt(SErrorEncolarVentaWebservice,
        [ASerie, ANumero]);
  end;
end;

class procedure TVentasWsCola.RegistrarEventoSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ATipoEvento, ASerie, ANumero: string);
begin
  if Activa(AParametrosCaja) then
  begin
    try
      ARepositorio.Encolar(
        NuevoUuid, ATipoEvento, ASerie, ANumero, AUsuario);
    except
      on E: Exception do
        Log.LogError('No se pudo encolar el evento ' + ATipoEvento +
          ' de ' + ASerie + '\' + ANumero + ': ' + E.Message);
    end;
  end;
end;

class procedure TVentasWsCola.AdjuntarTicketPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    ARepositorio,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    False);
end;

class procedure TVentasWsCola.AdjuntarFacturaPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    ARepositorio,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    True);
end;

class procedure TVentasWsCola.AdjuntarPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  AEsFactura: Boolean);
var
  iIdCola: Int64;
  sTipoEvento: string;
begin
  if Activa(AParametrosCaja) and FileExists(ARutaPdf) then
  begin
    if AEsFactura then
      sTipoEvento := 'FACTURA_PDF_ACTUALIZADO'
    else
      sTipoEvento := 'TICKET_PDF_ACTUALIZADO';
    try
      if not ARepositorio.ActualizarPdfVentaPendiente(
               AEsFactura, ASerie, ANumero, ARutaPdf, AUsuario) then
      begin
        iIdCola := ARepositorio.Encolar(
          NuevoUuid, sTipoEvento, ASerie, ANumero, AUsuario);
        if iIdCola > 0 then
          ARepositorio.ActualizarPdfPorId(
            AEsFactura, iIdCola, ARutaPdf, AUsuario);
      end;
    except
      on E: Exception do
        Log.LogError('No se pudo adjuntar el PDF de ' + ASerie + '\' +
          ANumero + ' a la cola de ventas: ' + E.Message);
    end;
  end;
end;

procedure TVentasWsCola.IniciarHilo(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionVentasWs;
  const AUsuario: string);
begin
  if FHilo = nil then
  begin
    FHilo := THiloVentasWsCola.Create(
      AContextoSesion,
      AParametrosApp,
      AFabricaSesion,
      AUsuario);
    FHilo.FreeOnTerminate := False;
    FHilo.Start;
    Log.LogInfo('Cola de ventas WS: hilo iniciado');
  end;
end;

procedure TVentasWsCola.DetenerHilo;
begin
  if FHilo <> nil then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    Log.LogInfo('Cola de ventas WS: hilo detenido');
  end;
end;

destructor TVentasWsCola.Destroy;
begin
  DetenerHilo;
  inherited;
end;

constructor THiloVentasWsCola.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionVentasWs;
  const AUsuario: string);
begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AFabricaSesion) then
    raise EArgumentNilException.Create('AFabricaSesion');
  inherited Create(True);
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FFabricaSesion := AFabricaSesion;
  FUsuario := AUsuario;
end;

destructor THiloVentasWsCola.Destroy;
begin
  FRepositorio := nil;
  FSesion := nil;
  FFabricaSesion := nil;
  FContextoSesion := nil;
  FParametrosApp := nil;
  inherited;
end;

procedure THiloVentasWsCola.Execute;
begin
  NameThreadForDebugging('VentasWsCola');
  FAvisoConfiguracion := False;
  while (not Terminated) and (not FContextoSesion.CerrandoAplicacion) do
  begin
    EsperarCiclo;
    if (not Terminated) and (not FContextoSesion.CerrandoAplicacion) then
    begin
      try
        ProcesarPendientes;
      except
        on E: Exception do
        begin
          Log.LogError('Cola de ventas WS: ' + E.Message);
          FRepositorio := nil;
          FSesion := nil;
        end;
      end;
    end;
  end;
end;

procedure THiloVentasWsCola.EsperarCiclo;
var
  iSegundos: Integer;
begin
  iSegundos :=
    FParametrosApp.GetInt('appVentasWsSegundosCiclo', 60);
  if iSegundos < 5 then
    iSegundos := 5;
  EsperarSegundos(iSegundos);
end;

procedure THiloVentasWsCola.EsperarSegundos(ASegundos: Integer);
var
  iPaso: Integer;
  iPasos: Integer;
begin
  if ASegundos > 300 then
    ASegundos := 300;
  iPasos := ASegundos * 10;
  iPaso := 0;
  while (iPaso < iPasos) and (not Terminated) and
        (not FContextoSesion.CerrandoAplicacion) do
  begin
    Sleep(100);
    Inc(iPaso);
  end;
end;

procedure THiloVentasWsCola.ProcesarPendientes;
var
  aPendientes: TArray<Int64>;
  iIndice: Integer;
begin
  if TClienteFactuzamApi.Configurada(FParametrosApp) then
  begin
    FAvisoConfiguracion := False;
    if FSesion = nil then
    begin
      FSesion := FFabricaSesion.CrearSesion;
      if not Assigned(FSesion) then
        raise Exception.Create('La fábrica no creó la sesión VentasWs');
      FRepositorio := FSesion.Repositorio;
      if not Assigned(FRepositorio) then
        raise Exception.Create('La sesión VentasWs no tiene repositorio');
      if not Assigned(FSesion.Json) then
        raise Exception.Create('La sesión VentasWs no tiene serializador');
    end;
    FRepositorio.ReencolarProcesandoCaducadas;
    aPendientes := FRepositorio.BuscarPendientes(10);
    iIndice := 0;
    while (iIndice <= High(aPendientes)) and (not Terminated) and
          (not FContextoSesion.CerrandoAplicacion) do
    begin
      ProcesarFila(aPendientes[iIndice]);
      Inc(iIndice);
    end;
  end
  else if not FAvisoConfiguracion then
  begin
    Log.LogWarning('Cola de ventas WS pendiente: falta URL, API key o ' +
      'referencia de instalación.');
    FAvisoConfiguracion := True;
  end;
end;

procedure THiloVentasWsCola.ProcesarFila(AIdCola: Int64);
var
  oFila: TFilaVentasWsCola;
  oResultado: TResultadoFactuzamApi;
  sContenido: string;
  sHuella: string;
begin
  if FRepositorio.MarcarProcesando(AIdCola, FUsuario) then
  begin
    oFila := FRepositorio.LeerFila(AIdCola);
    try
      sContenido := oFila.Contenido;
      if sContenido = '' then
      begin
        sContenido := TVentasWsJson.ConstruirEvento(
          FParametrosApp,
          oVersion,
          FSesion.Json,
          AIdCola,
          oFila.IdEvento, oFila.TipoEvento, oFila.Empresa,
          oFila.Serie, oFila.Numero);
        sHuella := UpperCase(THashSHA2.GetHashString(sContenido));
        FRepositorio.GuardarContenido(AIdCola, sContenido, sHuella);
      end;
      oResultado := TClienteFactuzamApi.EnviarJson(
        FParametrosApp,
        'ventas/eventos.php', sContenido);
      if oResultado.Ok then
        FRepositorio.MarcarEnviada(
          AIdCola, oResultado.IdPeticion, FUsuario)
      else
        GuardarError(AIdCola, oResultado.Mensaje, oFila.Intentos);
    except
      on E: Exception do
        GuardarError(AIdCola, E.Message, oFila.Intentos);
    end;
  end;
end;

procedure THiloVentasWsCola.GuardarError(AIdCola: Int64;
  const AMensaje: string; AIntentos: Integer);
var
  iEspera: Integer;
  iMaxIntentos: Integer;
  sEstado: string;
begin
  // Política de reintentos: espera exponencial con tope y paso a ERROR
  // al agotar los intentos configurados.
  iMaxIntentos :=
    FParametrosApp.GetInt('appVentasWsMaxIntentos', 20);
  if AIntentos > 6 then
    iEspera := 60 * 64
  else
    iEspera := 60 * (1 shl AIntentos);
  if (AIntentos + 1) >= iMaxIntentos then
    sEstado := 'ERROR'
  else
    sEstado := 'PENDIENTE';
  FRepositorio.GuardarErrorIntento(
    AIdCola, sEstado, iEspera, AMensaje, FUsuario);
end;

end.
