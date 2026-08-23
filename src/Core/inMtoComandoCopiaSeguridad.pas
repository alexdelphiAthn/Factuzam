{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComandoCopiaSeguridad                                   }
{    Tipo:       Coordinador de aplicación                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Ejecuta la copia de seguridad solicitada por línea de comandos.           }
{******************************************************************************}
unit inMtoComandoCopiaSeguridad;

interface

uses
  inLibLogIntf;

function EsProcesoComandoCopiaSeguridad: Boolean;
function EjecutarProcesoComandoCopiaSeguridad(
  const ARegistroLog: IRegistroLog
): Cardinal;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  Uni,
  UniDataConn,
  inLibCifrado,
  inLibCifradoCopias,
  inLibComandoCopiaSeguridad,
  inLibCopiasSeguridad,
  inLibCopiasSeguridadIntf,
  inLibMsgConfiguracion;

const
  SALIDA_COMANDO_ERROR_INESPERADO = 1;
  SALIDA_COMANDO_SINTAXIS = 2;
  SALIDA_COMANDO_RUTA = 3;
  SALIDA_COMANDO_CLAVE = 4;
  SALIDA_COMANDO_CONEXION = 5;
  SALIDA_COMANDO_COPIA = 6;
  SALIDA_COMANDO_PUBLICACION = 7;

type
  TResultadoComandoCopiaSeguridad = record
    CodigoSalida: Cardinal;
    EsError: Boolean;
    Mensaje: string;
  end;

function CrearResultadoComandoCopiaSeguridad(
  ACodigoSalida: Cardinal;
  const AMensaje: string
): TResultadoComandoCopiaSeguridad;
begin
  Result := Default(TResultadoComandoCopiaSeguridad);
  Result.CodigoSalida := ACodigoSalida;
  Result.EsError := ACodigoSalida <> 0;
  Result.Mensaje := AMensaje;
end;

function ObtenerParametrosProceso: TArray<string>;
var
  iIndice: Integer;
begin
  SetLength(Result, ParamCount);
  for iIndice := 1 to ParamCount do
  begin
    Result[iIndice - 1] := ParamStr(iIndice);
  end;
end;

function MensajeErrorSolicitudCopia(
  AError: TErrorComandoCopiaSeguridad): string;
begin
  case AError of
    eccsSintaxis:
      Result := SErrorSintaxisComandoCopiaSeguridad;
    eccsRuta:
      Result := SErrorRutaComandoCopiaSeguridad;
    eccsExtension:
      Result := SErrorExtensionComandoCopiaSeguridad;
    eccsClave:
      Result := SErrorClaveComandoCopiaSeguridad;
  else
    Result := SErrorCrearCopiaSeguridad;
  end;
end;

function CodigoErrorSolicitudCopia(
  AError: TErrorComandoCopiaSeguridad): Cardinal;
begin
  case AError of
    eccsSintaxis:
      Result := SALIDA_COMANDO_SINTAXIS;
    eccsRuta,
    eccsExtension:
      Result := SALIDA_COMANDO_RUTA;
    eccsClave:
      Result := SALIDA_COMANDO_CLAVE;
  else
    Result := SALIDA_COMANDO_ERROR_INESPERADO;
  end;
end;

procedure PrepararDirectorioCopia(const ARutaFichero: string);
var
  sDirectorio: string;
begin
  sDirectorio := ExcludeTrailingPathDelimiter(
    ExtractFilePath(ARutaFichero));
  if not DirectoryExists(sDirectorio) and
     not ForceDirectories(sDirectorio) then
  begin
    raise EInOutError.Create(sDirectorio);
  end;
end;

function CrearRutaTemporalCopia(const ARutaFichero: string): string;
begin
  Result := TPath.Combine(
    ExtractFilePath(ARutaFichero),
    'fzam_' + TPath.GetRandomFileName);
end;

function EsCopiaTemporalValida(const ARutaFichero: string): Boolean;
var
  oLector: TStreamReader;
  sCabecera: string;
begin
  Result := FileExists(ARutaFichero);
  if Result then
  begin
    oLector := TStreamReader.Create(
      ARutaFichero,
      TEncoding.UTF8,
      True);
    try
      sCabecera := oLector.ReadLine;
      Result := EsFormatoCifradoActual(sCabecera);
    finally
      FreeAndNil(oLector);
    end;
  end;
end;

function IntentarPublicarCopia(
  const ARutaTemporal, ARutaDestino: string;
  out AError: string): Boolean;
begin
  AError := '';
  Result := MoveFileEx(
    PChar(ARutaTemporal),
    PChar(ARutaDestino),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH);
  if not Result then
    AError := SysErrorMessage(GetLastError);
end;

function CrearErrorPublicacion(
  const ADetalle: string
): TResultadoComandoCopiaSeguridad;
begin
  Result := CrearResultadoComandoCopiaSeguridad(
    SALIDA_COMANDO_PUBLICACION,
    Format(
      SErrorPublicarComandoCopiaSeguridad,
      [ADetalle]));
end;

function PublicarCopiaTemporal(
  const ARutaTemporal: string;
  const ASolicitud: TSolicitudComandoCopiaSeguridad;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  sError: string;
begin
  if not EsCopiaTemporalValida(ARutaTemporal) then
  begin
    Result := CrearErrorPublicacion(
      SErrorFormatoComandoCopiaSeguridad);
  end
  else
  begin
    ARegistroLog.RegistrarInformacion(
      SInfoComandoCopiaSeguridadPublicacion);
    if IntentarPublicarCopia(
      ARutaTemporal,
      ASolicitud.RutaDestino,
      sError) then
    begin
      Result := CrearResultadoComandoCopiaSeguridad(
        0,
        Format(
          SInfoComandoCopiaSeguridadCompletado,
          [ASolicitud.RutaRegistro]));
    end
    else
      Result := CrearErrorPublicacion(sError);
  end;
end;

function EjecutarSolicitudCopiaSeguridad(
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudComandoCopiaSeguridad;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  oResultadoCopia: TResultadoCopiaSeguridad;
  sError: string;
  sRutaTemporal: string;
begin
  sRutaTemporal := '';
  try
    try
      ARegistroLog.RegistrarInformacion(
        Format(
          SInfoComandoCopiaSeguridadDestino,
          [ASolicitud.RutaRegistro]));
      PrepararDirectorioCopia(ASolicitud.RutaDestino);
      sRutaTemporal := CrearRutaTemporalCopia(
        ASolicitud.RutaDestino);
      ARegistroLog.RegistrarInformacion(
        SInfoComandoCopiaSeguridadGeneracion);
      oResultadoCopia := CrearCopiaProtegidaConexion(
        AConexion,
        sRutaTemporal,
        ASolicitud.Contrasena,
        nil,
        sError);
      if oResultadoCopia = rcsCompletada then
      begin
        Result := PublicarCopiaTemporal(
          sRutaTemporal,
          ASolicitud,
          ARegistroLog);
      end
      else
      begin
        Result := CrearResultadoComandoCopiaSeguridad(
          SALIDA_COMANDO_COPIA,
          Format(SErrorCrearCopiaSeguridad, [sError]));
      end;
    except
      on E: Exception do
        Result := CrearErrorPublicacion(E.Message);
    end;
  finally
    if (sRutaTemporal <> '') and
       FileExists(sRutaTemporal) then
    begin
      System.SysUtils.DeleteFile(sRutaTemporal);
    end;
  end;
end;

function EjecutarConConexion(
  AConexion: TdmConn;
  const AParametros: TArray<string>;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  oClaves: TClavesPredeterminadasCopiaSeguridad;
  oSolicitud: TSolicitudComandoCopiaSeguridad;
begin
  ARegistroLog.RegistrarInformacion(
    SInfoComandoCopiaSeguridadConexion);
  AConexion.conUni.Connect;
  ARegistroLog.RegistrarInformacion(
    SInfoComandoCopiaSeguridadConexionPreparada);
  oClaves := Default(TClavesPredeterminadasCopiaSeguridad);
  oClaves.Contrasena := AConexion.conUni.Password;
  oClaves.ClaveCifrada := CifrarAES(oClaves.Contrasena);
  oSolicitud := InterpretarComandoCopiaSeguridad(
    AParametros,
    Now,
    oClaves);
  if oSolicitud.EsValida then
  begin
    Result := EjecutarSolicitudCopiaSeguridad(
      AConexion.conUni,
      oSolicitud,
      ARegistroLog);
  end
  else
  begin
    Result := CrearResultadoComandoCopiaSeguridad(
      CodigoErrorSolicitudCopia(oSolicitud.Error),
      MensajeErrorSolicitudCopia(oSolicitud.Error));
  end;
end;

function EjecutarComandoCopiaSeguridad(
  const AParametros: TArray<string>;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  oConexion: TdmConn;
begin
  ARegistroLog.RegistrarInformacion(
    SInfoComandoCopiaSeguridadInicio);
  if not EsSintaxisComandoCopiaSeguridadValida(AParametros) then
  begin
    Result := CrearResultadoComandoCopiaSeguridad(
      SALIDA_COMANDO_SINTAXIS,
      SErrorSintaxisComandoCopiaSeguridad);
  end
  else
  begin
    oConexion := nil;
    try
      try
        oConexion := TdmConn.Create(nil);
        Result := EjecutarConConexion(
          oConexion,
          AParametros,
          ARegistroLog);
      except
        on E: Exception do
        begin
          Result := CrearResultadoComandoCopiaSeguridad(
            SALIDA_COMANDO_CONEXION,
            Format(
              SErrorConexionComandoCopiaSeguridad,
              [E.Message]));
        end;
      end;
    finally
      FreeAndNil(oConexion);
    end;
  end;
end;

procedure EscribirResultadoComando(
  const AResultado: TResultadoComandoCopiaSeguridad);
var
  aTexto: TBytes;
  hCanal: THandle;
  iEscritos: Cardinal;
begin
  if AResultado.EsError then
    hCanal := GetStdHandle(STD_ERROR_HANDLE)
  else
    hCanal := GetStdHandle(STD_OUTPUT_HANDLE);
  aTexto := TEncoding.UTF8.GetBytes(
    AResultado.Mensaje + sLineBreak);
  if (hCanal <> 0) and
     (hCanal <> INVALID_HANDLE_VALUE) and
     (Length(aTexto) > 0) then
  begin
    WriteFile(
      hCanal,
      aTexto[0],
      Length(aTexto),
      iEscritos,
      nil);
  end;
  OutputDebugString(PChar(AResultado.Mensaje));
end;

procedure RegistrarResultadoComando(
  const AResultado: TResultadoComandoCopiaSeguridad;
  const ARegistroLog: IRegistroLog);
begin
  if AResultado.EsError then
    ARegistroLog.RegistrarError(AResultado.Mensaje)
  else
    ARegistroLog.RegistrarInformacion(AResultado.Mensaje);
  EscribirResultadoComando(AResultado);
end;

function EsProcesoComandoCopiaSeguridad: Boolean;
begin
  Result := EsComandoCopiaSeguridad(
    ObtenerParametrosProceso);
end;

function EjecutarProcesoComandoCopiaSeguridad(
  const ARegistroLog: IRegistroLog
): Cardinal;
var
  oResultado: TResultadoComandoCopiaSeguridad;
begin
  oResultado := EjecutarComandoCopiaSeguridad(
    ObtenerParametrosProceso,
    ARegistroLog);
  RegistrarResultadoComando(
    oResultado,
    ARegistroLog);
  Result := oResultado.CodigoSalida;
end;

end.
