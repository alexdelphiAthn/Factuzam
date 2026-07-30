{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsCola                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola transaccional de eventos de venta y envío al webservice de respaldo. }
{******************************************************************************}
unit inLibVentasWsCola;

interface

uses
  System.SysUtils, System.Classes, Uni, inLibConexionesIntf,
  inLibParametrosIntf, inLibContextoSesionIntf;

type
  TVentasWsCola = class
  private
    class function Activa(
      const AParametrosCaja: IParametrosCaja): Boolean; static;
    class function EncolarInterno(AQry: TUniQuery;
      const AUsuario: string;
      const ATipoEvento, ASerie, ANumero: string): Int64; static;
    class procedure AdjuntarPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      AEsFactura: Boolean); static;
  public
    class procedure RegistrarFactura(
      const AParametrosCaja: IParametrosCaja;
      AQryTrx: TUniQuery;
      const AUsuario: string;
      const ASerie, ANumero, ATipoOperacion: string); static;
    class procedure RegistrarEventoSeguro(
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AUsuario: string;
      const ATipoEvento, ASerie, ANumero: string); static;
    class procedure AdjuntarTicketPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string); static;
    class procedure AdjuntarFacturaPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string); static;
    class procedure IniciarHilo(
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AUsuario: string); static;
    class procedure DetenerHilo; static;
  end;

implementation

uses
  Winapi.Windows, Data.DB, System.Hash, System.IOUtils,
  inLibGlobalVar, inLibLog, inLibMsgIntegraciones,
  inLibVentasWsJson, inLibFactuzamApi;

type
  THiloVentasWsCola = class(TThread)
  private
    FConn: TUniConnection;
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
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
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AUsuario: string); reintroduce;
    destructor Destroy; override;
  end;

var
  oHiloVentasWs: THiloVentasWsCola = nil;

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

class function TVentasWsCola.EncolarInterno(AQry: TUniQuery;
  const AUsuario: string;
  const ATipoEvento, ASerie, ANumero: string): Int64;
var
  sEmpresa: string;
begin
  Result := 0;
  AQry.Close;
  AQry.SQL.Text :=
    ' SELECT CODIGO_EMP_FAC FROM fza_facturas ' +
    ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.Open;
  if not AQry.IsEmpty then
  begin
    sEmpresa := AQry.FieldByName('CODIGO_EMP_FAC').AsString;
    AQry.Close;
    AQry.SQL.Text :=
      ' INSERT INTO fza_ventas_ws_cola ' +
      ' (ID_EVENTO_VWSC, CODIGO_EMP_VWSC, SERIE_FAC_VWSC, ' +
      '  NUMERO_FAC_VWSC, TIPO_EVENTO_VWSC, ' +
      '  VERSION_CONTRATO_VWSC, ESTADO_VWSC, ' +
      '  CONTADOR_INTENTOS_VWSC, INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' VALUES (:EVENTO, :EMPRESA, :SERIE, :NUMERO, :TIPO, 1, ' +
      '         ''PENDIENTE'', 0, NOW(), :USUARIO)';
    AQry.ParamByName('EVENTO').AsString := NuevoUuid;
    AQry.ParamByName('EMPRESA').AsString := sEmpresa;
    AQry.ParamByName('SERIE').AsString := ASerie;
    AQry.ParamByName('NUMERO').AsString := ANumero;
    AQry.ParamByName('TIPO').AsString := ATipoEvento;
    AQry.ParamByName('USUARIO').AsString := AUsuario;
    AQry.Execute;
    AQry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    AQry.Open;
    Result := AQry.FieldByName('ID').AsLargeInt;
    AQry.Close;
  end;
end;

class procedure TVentasWsCola.RegistrarFactura(
  const AParametrosCaja: IParametrosCaja;
  AQryTrx: TUniQuery;
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
    iIdCola := EncolarInterno(AQryTrx, AUsuario, sTipoEvento, ASerie,
      ANumero);
    if iIdCola = 0 then
      raise Exception.CreateFmt(SErrorEncolarVentaWebservice,
        [ASerie, ANumero]);
  end;
end;

class procedure TVentasWsCola.RegistrarEventoSeguro(
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AUsuario: string;
  const ATipoEvento, ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  if Activa(AParametrosCaja) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      try
        Qry.Connection := AConn;
        EncolarInterno(Qry, AUsuario, ATipoEvento, ASerie, ANumero);
      except
        on E: Exception do
          Log.LogError('No se pudo encolar el evento ' + ATipoEvento +
            ' de ' + ASerie + '\' + ANumero + ': ' + E.Message);
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

class procedure TVentasWsCola.AdjuntarTicketPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    AConn,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    False);
end;

class procedure TVentasWsCola.AdjuntarFacturaPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    AConn,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    True);
end;

class procedure TVentasWsCola.AdjuntarPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  AEsFactura: Boolean);
var
  iIdCola: Int64;
  iTamano: Int64;
  Qry: TUniQuery;
  sCampoContenido: string;
  sCampoHuella: string;
  sCampoNombre: string;
  sCampoTamano: string;
  sHuella: string;
  sTipoEvento: string;

  procedure AsignarParametrosPdf;
  begin
    Qry.ParamByName('NOMBRE').AsString := ExtractFileName(ARutaPdf);
    Qry.ParamByName('PDF').LoadFromFile(ARutaPdf, ftBlob);
    Qry.ParamByName('TAMANO').AsLargeInt := iTamano;
    Qry.ParamByName('HUELLA').AsString := sHuella;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
  end;

begin
  if Activa(AParametrosCaja) and FileExists(ARutaPdf) then
  begin
    if AEsFactura then
    begin
      sCampoNombre := 'NOMBRE_FACTURA_PDF_VWSC';
      sCampoContenido := 'FACTURA_PDF_VWSC';
      sCampoTamano := 'TAMANO_FACTURA_PDF_VWSC';
      sCampoHuella := 'HUELLA_FACTURA_PDF_VWSC';
      sTipoEvento := 'FACTURA_PDF_ACTUALIZADO';
    end
    else
    begin
      sCampoNombre := 'NOMBRE_PDF_VWSC';
      sCampoContenido := 'TICKET_PDF_VWSC';
      sCampoTamano := 'TAMANO_PDF_VWSC';
      sCampoHuella := 'HUELLA_PDF_VWSC';
      sTipoEvento := 'TICKET_PDF_ACTUALIZADO';
    end;
    Qry := TUniQuery.Create(nil);
    try
      try
        iTamano := TFile.GetSize(ARutaPdf);
        sHuella := UpperCase(THashSHA2.GetHashStringFromFile(ARutaPdf));
        Qry.Connection := AConn;
        Qry.SQL.Text :=
          ' UPDATE fza_ventas_ws_cola ' +
          ' SET ' + sCampoNombre + ' = :NOMBRE, ' +
          '     ' + sCampoContenido + ' = :PDF, ' +
          '     ' + sCampoTamano + ' = :TAMANO, ' +
          '     ' + sCampoHuella + ' = :HUELLA, ' +
          '     CONTENIDO_JSON_VWSC = NULL, ' +
          '     HUELLA_CONTENIDO_VWSC = NULL, ' +
          '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
          ' WHERE SERIE_FAC_VWSC = :SERIE ' +
          '   AND NUMERO_FAC_VWSC = :NUMERO ' +
          '   AND TIPO_EVENTO_VWSC = ''VENTA_CONFIRMADA'' ' +
          '   AND ESTADO_VWSC = ''PENDIENTE'' ' +
          '   AND CONTENIDO_JSON_VWSC IS NULL ' +
          ' ORDER BY ID_VWSC DESC LIMIT 1';
        AsignarParametrosPdf;
        Qry.ParamByName('SERIE').AsString := ASerie;
        Qry.ParamByName('NUMERO').AsString := ANumero;
        Qry.Execute;
        if Qry.RowsAffected = 0 then
        begin
          iIdCola := EncolarInterno(Qry, AUsuario, sTipoEvento, ASerie,
            ANumero);
          if iIdCola > 0 then
          begin
            Qry.SQL.Text :=
              ' UPDATE fza_ventas_ws_cola ' +
              ' SET ' + sCampoNombre + ' = :NOMBRE, ' +
              '     ' + sCampoContenido + ' = :PDF, ' +
              '     ' + sCampoTamano + ' = :TAMANO, ' +
              '     ' + sCampoHuella + ' = :HUELLA, ' +
              '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
              ' WHERE ID_VWSC = :ID';
            AsignarParametrosPdf;
            Qry.ParamByName('ID').AsLargeInt := iIdCola;
            Qry.Execute;
          end;
        end;
      except
        on E: Exception do
          Log.LogError('No se pudo adjuntar el PDF de ' + ASerie + '\' +
            ANumero + ' a la cola de ventas: ' + E.Message);
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

class procedure TVentasWsCola.IniciarHilo(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AUsuario: string);
begin
  if oHiloVentasWs = nil then
  begin
    oHiloVentasWs := THiloVentasWsCola.Create(
      AConexiones,
      AContextoSesion,
      AParametrosApp,
      AUsuario);
    oHiloVentasWs.FreeOnTerminate := False;
    oHiloVentasWs.Start;
    Log.LogInfo('Cola de ventas WS: hilo iniciado');
  end;
end;

class procedure TVentasWsCola.DetenerHilo;
begin
  if oHiloVentasWs <> nil then
  begin
    oHiloVentasWs.Terminate;
    oHiloVentasWs.WaitFor;
    FreeAndNil(oHiloVentasWs);
    Log.LogInfo('Cola de ventas WS: hilo detenido');
  end;
end;

constructor THiloVentasWsCola.Create(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AUsuario: string);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  inherited Create(True);
  FConexiones := AConexiones;
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FUsuario := AUsuario;
end;

destructor THiloVentasWsCola.Destroy;
begin
  FreeAndNil(FConn);
  FConexiones := nil;
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
          FreeAndNil(FConn);
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
  Qry: TUniQuery;
begin
  if TClienteFactuzamApi.Configurada(FParametrosApp) then
  begin
    FAvisoConfiguracion := False;
    if FConn = nil then
      FConn := FConexiones.CrearConexion(
        nil,
        uctSegundoPlano);
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConn;
      Qry.SQL.Text :=
        ' UPDATE fza_ventas_ws_cola SET ESTADO_VWSC = ''PENDIENTE'', ' +
        ' INSTANTE_MODIF = NOW() WHERE ESTADO_VWSC = ''PROCESANDO'' ' +
        ' AND INSTANTE_MODIF < DATE_SUB(NOW(), INTERVAL 10 MINUTE)';
      Qry.Execute;
      Qry.SQL.Text :=
        ' SELECT ID_VWSC FROM fza_ventas_ws_cola ' +
        ' WHERE ESTADO_VWSC = ''PENDIENTE'' ' +
        '   AND (INSTANTE_PROXIMO_INTENTO_VWSC IS NULL ' +
        '        OR INSTANTE_PROXIMO_INTENTO_VWSC <= NOW()) ' +
        ' ORDER BY ID_VWSC LIMIT 10';
      Qry.Open;
      while (not Qry.Eof) and (not Terminated) and
            (not FContextoSesion.CerrandoAplicacion) do
      begin
        ProcesarFila(Qry.FieldByName('ID_VWSC').AsLargeInt);
        Qry.Next;
      end;
    finally
      FreeAndNil(Qry);
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
  iIntentos: Integer;
  oResultado: TResultadoFactuzamApi;
  Qry: TUniQuery;
  sContenido: string;
  sEmpresa: string;
  sEvento: string;
  sHuella: string;
  sNumero: string;
  sSerie: string;
  sTipo: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola SET ESTADO_VWSC = ''PROCESANDO'', ' +
      ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VWSC = :ID AND ESTADO_VWSC = ''PENDIENTE''';
    Qry.ParamByName('USUARIO').AsString := FUsuario;
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
    if Qry.RowsAffected = 1 then
    begin
      Qry.SQL.Text :=
        ' SELECT ID_EVENTO_VWSC, CODIGO_EMP_VWSC, SERIE_FAC_VWSC, ' +
        ' NUMERO_FAC_VWSC, TIPO_EVENTO_VWSC, ' +
        ' CONTADOR_INTENTOS_VWSC, CONTENIDO_JSON_VWSC ' +
        ' FROM fza_ventas_ws_cola WHERE ID_VWSC = :ID';
      Qry.ParamByName('ID').AsLargeInt := AIdCola;
      Qry.Open;
      sEvento := Qry.FieldByName('ID_EVENTO_VWSC').AsString;
      sEmpresa := Qry.FieldByName('CODIGO_EMP_VWSC').AsString;
      sSerie := Qry.FieldByName('SERIE_FAC_VWSC').AsString;
      sNumero := Qry.FieldByName('NUMERO_FAC_VWSC').AsString;
      sTipo := Qry.FieldByName('TIPO_EVENTO_VWSC').AsString;
      iIntentos := Qry.FieldByName('CONTADOR_INTENTOS_VWSC').AsInteger;
      sContenido := Qry.FieldByName('CONTENIDO_JSON_VWSC').AsString;
      Qry.Close;
      try
        if sContenido = '' then
        begin
          sContenido := TVentasWsJson.ConstruirEvento(
            FParametrosApp,
            oVersion,
            FConn,
            AIdCola,
            sEvento, sTipo, sEmpresa, sSerie, sNumero);
          sHuella := UpperCase(THashSHA2.GetHashString(sContenido));
          Qry.SQL.Text :=
            ' UPDATE fza_ventas_ws_cola ' +
            ' SET CONTENIDO_JSON_VWSC = :CONTENIDO, ' +
            '     HUELLA_CONTENIDO_VWSC = :HUELLA, ' +
            '     INSTANTE_MODIF = NOW() WHERE ID_VWSC = :ID';
          Qry.ParamByName('CONTENIDO').AsMemo := sContenido;
          Qry.ParamByName('HUELLA').AsString := sHuella;
          Qry.ParamByName('ID').AsLargeInt := AIdCola;
          Qry.Execute;
        end;
        oResultado := TClienteFactuzamApi.EnviarJson(
          FParametrosApp,
          'ventas/eventos.php', sContenido);
        if oResultado.Ok then
        begin
          Qry.SQL.Text :=
            ' UPDATE fza_ventas_ws_cola ' +
            ' SET ESTADO_VWSC = ''ENVIADA'', INSTANTE_ENVIO_VWSC = NOW(), ' +
            ' ID_PETICION_VWSC = :PETICION, MENSAJE_ERROR_VWSC = NULL, ' +
            ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
            ' WHERE ID_VWSC = :ID';
          Qry.ParamByName('PETICION').AsString := oResultado.IdPeticion;
          Qry.ParamByName('USUARIO').AsString := FUsuario;
          Qry.ParamByName('ID').AsLargeInt := AIdCola;
          Qry.Execute;
        end
        else
          GuardarError(AIdCola, oResultado.Mensaje, iIntentos);
      except
        on E: Exception do
          GuardarError(AIdCola, E.Message, iIntentos);
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure THiloVentasWsCola.GuardarError(AIdCola: Int64;
  const AMensaje: string; AIntentos: Integer);
var
  iEspera: Integer;
  iMaxIntentos: Integer;
  Qry: TUniQuery;
  sEstado: string;
begin
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
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola SET ESTADO_VWSC = :ESTADO, ' +
      ' CONTADOR_INTENTOS_VWSC = CONTADOR_INTENTOS_VWSC + 1, ' +
      ' INSTANTE_PROXIMO_INTENTO_VWSC = ' +
      ' DATE_ADD(NOW(), INTERVAL :ESPERA SECOND), ' +
      ' MENSAJE_ERROR_VWSC = :MENSAJE, INSTANTE_MODIF = NOW(), ' +
      ' USUARIO_MODIF = :USUARIO WHERE ID_VWSC = :ID';
    Qry.ParamByName('ESTADO').AsString := sEstado;
    Qry.ParamByName('ESPERA').AsInteger := iEspera;
    Qry.ParamByName('MENSAJE').AsString := AMensaje;
    Qry.ParamByName('USUARIO').AsString := FUsuario;
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

end.
