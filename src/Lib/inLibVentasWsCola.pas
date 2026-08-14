{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsCola                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       14/08/2026                                                    }
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
  inLibVentasWsJsonIntf, inLibVentasWsColaIntf, inLibLogIntf;

type
  TVentasWsCola = class
  private
    FHilo: TThread;
    FRegistroLog: IRegistroLog;
    class function Activa(
      const AParametrosCaja: IParametrosCaja): Boolean; static;
    class procedure AdjuntarPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      AEsFactura: Boolean;
      const ARegistroLog: IRegistroLog); static;
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
      const ATipoEvento, ASerie, ANumero: string;
      const ARegistroLog: IRegistroLog); static;
    class procedure AdjuntarTicketPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      const ARegistroLog: IRegistroLog); static;
    class procedure AdjuntarFacturaPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IRepositorioVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      const ARegistroLog: IRegistroLog); static;
    constructor Create(const ARegistroLog: IRegistroLog);
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
  Winapi.Windows, System.Hash, System.JSON,
  System.Generics.Collections,
  inLibGlobalVar, inLibMsgIntegraciones,
  inLibVentasWsJson, inLibFactuzamApi,
  inLibColasHistorialIntf, inLibVentasWsColaHistorialIntf;

type
  THiloVentasWsCola = class(TThread)
  private
    FSesion: ISesionVentasWs;
    FRepositorio: IRepositorioVentasWsCola;
    FRegistradorIntentos: IRegistradorIntentosVentasWsCola;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FFabricaSesion: IFabricaSesionVentasWs;
    FRegistroLog: IRegistroLog;
    FUsuario: string;
    FAvisoConfiguracion: Boolean;
    procedure EsperarCiclo;
    procedure EsperarSegundos(ASegundos: Integer);
    procedure ProcesarPendientes;
    procedure ProcesarFila(AIdCola: Int64);
    function EnviarConHistorial(
      AIdCola: Int64;
      const AFila: TFilaVentasWsCola;
      const AContenido: string): TResultadoFactuzamApi;
    procedure RegistrarIntentoSeguro(
      const AIntento: TIntentoVentasWsCola);
    procedure GuardarError(AIdCola: Int64; const AMensaje: string;
      AIntentos: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionVentasWs;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog); reintroduce;
    destructor Destroy; override;
  end;

const
  cContenidoBase64Omitido =
    '[OMITIDO DEL HISTORIAL: CONTENIDO BINARIO/BASE64]';
  cContenidoSensibleOmitido =
    '[OMITIDO DEL HISTORIAL: CREDENCIAL O SECRETO]';
  cPeticionJsonNoDisponible =
    '[PETICIÓN OMITIDA DEL HISTORIAL: JSON NO VÁLIDO]';
  cRespuestaNoDisponible =
    '[RESPUESTA OMITIDA DEL HISTORIAL: NO SE PUDO SANEAR]';

function EsCampoBinarioHistorial(const ANombre: string): Boolean;
begin
  Result := SameText(ANombre, 'contenido_base64') or
            SameText(ANombre, 'DOCUMENTO_FAC') or
            SameText(ANombre, 'PDF_FAC') or
            SameText(ANombre, 'QRCODE_PNG_FACCON');
end;

function EsCampoSensibleHistorial(const ANombre: string): Boolean;
begin
  Result := SameText(ANombre, 'authorization') or
            SameText(ANombre, 'api_key') or
            SameText(ANombre, 'apikey') or
            SameText(ANombre, 'clave_api') or
            SameText(ANombre, 'password') or
            SameText(ANombre, 'contrasena') or
            SameText(ANombre, 'access_token') or
            SameText(ANombre, 'refresh_token') or
            SameText(ANombre, 'client_secret') or
            SameText(ANombre, 'secret');
end;

procedure OcultarContenidoNoPersistible(AValor: TJSONValue);
var
  iIndice: Integer;
  oObjeto: TJSONObject;
  oPar: TJSONPair;
begin
  if AValor is TJSONObject then
  begin
    oObjeto := TJSONObject(AValor);
    iIndice := 0;
    while iIndice < oObjeto.Count do
    begin
      oPar := oObjeto.Pairs[iIndice];
      if EsCampoBinarioHistorial(oPar.JsonString.Value) then
        oPar.JsonValue := TJSONString.Create(cContenidoBase64Omitido)
      else if EsCampoSensibleHistorial(oPar.JsonString.Value) then
        oPar.JsonValue := TJSONString.Create(cContenidoSensibleOmitido)
      else
        OcultarContenidoNoPersistible(oPar.JsonValue);
      Inc(iIndice);
    end;
  end
  else if AValor is TJSONArray then
  begin
    iIndice := 0;
    while iIndice < TJSONArray(AValor).Count do
    begin
      OcultarContenidoNoPersistible(TJSONArray(AValor).Items[iIndice]);
      Inc(iIndice);
    end;
  end;
end;

function PeticionParaHistorial(const AContenido: string): string;
var
  oJson: TJSONValue;
begin
  Result := cPeticionJsonNoDisponible;
  oJson := nil;
  try
    try
      oJson := TJSONObject.ParseJSONValue(AContenido);
      if Assigned(oJson) then
      begin
        OcultarContenidoNoPersistible(oJson);
        Result := oJson.ToJSON;
      end;
    except
      on E: Exception do
        Result := cPeticionJsonNoDisponible + ' ' + E.ClassName;
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function RespuestaParaHistorial(const AContenido: string): string;
var
  oJson: TJSONValue;
begin
  Result := AContenido;
  oJson := nil;
  try
    try
      oJson := TJSONObject.ParseJSONValue(AContenido);
      if Assigned(oJson) then
      begin
        OcultarContenidoNoPersistible(oJson);
        Result := oJson.ToJSON;
      end;
    except
      on E: Exception do
        Result := AContenido;
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function OcultarSecretoLiteral(const AContenido, ASecreto: string): string;
begin
  Result := AContenido;
  if ASecreto <> '' then
    Result := StringReplace(
      Result, ASecreto, cContenidoSensibleOmitido, [rfReplaceAll]);
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
  const ATipoEvento, ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
begin
  if Activa(AParametrosCaja) then
  begin
    try
      ARepositorio.Encolar(
        NuevoUuid, ATipoEvento, ASerie, ANumero, AUsuario);
    except
      on E: Exception do
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarError(
            'No se pudo encolar el evento ' + ATipoEvento +
            ' de ' + ASerie + '\' + ANumero + ': ' + E.Message);
    end;
  end;
end;

class procedure TVentasWsCola.AdjuntarTicketPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  const ARegistroLog: IRegistroLog);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    ARepositorio,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    False,
    ARegistroLog);
end;

class procedure TVentasWsCola.AdjuntarFacturaPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  const ARegistroLog: IRegistroLog);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    ARepositorio,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    True,
    ARegistroLog);
end;

class procedure TVentasWsCola.AdjuntarPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IRepositorioVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  AEsFactura: Boolean;
  const ARegistroLog: IRegistroLog);
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
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarError(
            'No se pudo adjuntar el PDF de ' + ASerie + '\' +
            ANumero + ' a la cola de ventas: ' + E.Message);
    end;
  end;
end;

constructor TVentasWsCola.Create(const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
end;

procedure TVentasWsCola.IniciarHilo(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionVentasWs;
  const AUsuario: string);
var
  oHilo: TThread;
begin
  if FHilo = nil then
  begin
    oHilo := THiloVentasWsCola.Create(
      AContextoSesion,
      AParametrosApp,
      AFabricaSesion,
      AUsuario,
      FRegistroLog);
    try
      oHilo.FreeOnTerminate := False;
      oHilo.Start;
      if Assigned(FRegistroLog) then
        FRegistroLog.RegistrarInformacion(
          'Cola de ventas WS: hilo iniciado');
      FHilo := oHilo;
      oHilo := nil;
    finally
      FreeAndNil(oHilo);
    end;
  end;
end;

procedure TVentasWsCola.DetenerHilo;
begin
  if FHilo <> nil then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    if Assigned(FRegistroLog) then
      FRegistroLog.RegistrarInformacion(
        'Cola de ventas WS: hilo detenido');
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
  const AUsuario: string;
  const ARegistroLog: IRegistroLog);
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
  FRegistroLog := ARegistroLog;
end;

destructor THiloVentasWsCola.Destroy;
begin
  FRegistradorIntentos := nil;
  FRepositorio := nil;
  FSesion := nil;
  FFabricaSesion := nil;
  FContextoSesion := nil;
  FParametrosApp := nil;
  FRegistroLog := nil;
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
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarError(
              'Cola de ventas WS: ' + E.Message);
          FRegistradorIntentos := nil;
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
      FRegistradorIntentos := FSesion.RegistradorIntentos;
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
    if Assigned(FRegistroLog) then
      FRegistroLog.RegistrarAviso(
        'Cola de ventas WS pendiente: falta URL, API key o ' +
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
      oResultado := EnviarConHistorial(AIdCola, oFila, sContenido);
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

function THiloVentasWsCola.EnviarConHistorial(
  AIdCola: Int64;
  const AFila: TFilaVentasWsCola;
  const AContenido: string): TResultadoFactuzamApi;
var
  iInicioMs: UInt64;
  oIntento: TIntentoVentasWsCola;
  sToken: string;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.Respuesta := '';
  Result.IdPeticion := '';
  Result.Mensaje := '';
  oIntento := Default(TIntentoVentasWsCola);
  oIntento.IdCola := AIdCola;
  oIntento.IdEvento := AFila.IdEvento;
  oIntento.NumeroIntento := AFila.Intentos + 1;
  oIntento.MetodoHttp := 'POST';
  oIntento.RecursoHttp := 'ventas/eventos.php';
  oIntento.Peticion := PeticionParaHistorial(AContenido);
  oIntento.Usuario := FUsuario;
  oIntento.InstanteInicio := Now;
  iInicioMs := GetTickCount64;
  try
    try
      Result := TClienteFactuzamApi.EnviarJson(
        FParametrosApp,
        oIntento.RecursoHttp,
        AContenido);
    except
      on E: Exception do
        Result.Mensaje := E.Message;
    end;
  finally
    oIntento.InstanteFin := Now;
    if oIntento.InstanteFin < oIntento.InstanteInicio then
      oIntento.InstanteFin := oIntento.InstanteInicio;
    oIntento.DuracionMs := Int64(GetTickCount64 - iInicioMs);
    oIntento.IdPeticion := Result.IdPeticion;
    oIntento.EstadoHttp := Result.EstadoHttp;
    try
      sToken := TClienteFactuzamApi.Token(FParametrosApp);
      oIntento.Respuesta := OcultarSecretoLiteral(
        RespuestaParaHistorial(Result.Respuesta), sToken);
      oIntento.Mensaje := OcultarSecretoLiteral(Result.Mensaje, sToken);
    except
      on E: Exception do
      begin
        oIntento.Respuesta := cRespuestaNoDisponible;
        oIntento.Mensaje :=
          'No se pudo sanear la respuesta: ' + E.ClassName;
      end;
    end;
    if Result.Ok then
      oIntento.Resultado := rccCorrecto
    else
      oIntento.Resultado := rccError;
    RegistrarIntentoSeguro(oIntento);
  end;
end;

procedure THiloVentasWsCola.RegistrarIntentoSeguro(
  const AIntento: TIntentoVentasWsCola);
var
  bRegistrado: Boolean;
  sError: string;
begin
  sError := '';
  if Assigned(FRegistradorIntentos) then
  begin
    try
      bRegistrado :=
        FRegistradorIntentos.IntentarRegistrar(AIntento, sError);
      if (not bRegistrado) and (sError = '') then
        sError := 'El registrador no confirmó la escritura.';
    except
      on E: Exception do
        sError := E.Message;
    end;
  end
  else
    sError := 'No hay registrador de intentos disponible.';
  if (sError <> '') and Assigned(FRegistroLog) then
  begin
    try
      FRegistroLog.RegistrarAviso(
        'Cola de ventas WS: no se guardó el historial: ' + sError);
    except
      on E: Exception do
        sError := E.Message;
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
