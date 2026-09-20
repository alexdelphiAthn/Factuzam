{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionProceso                                     }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta comprobar, instalar, aplicar y revertir una actualización.       }
{******************************************************************************}
unit inLibActualizacionProceso;

interface

uses
  Uni,
  inLibActualizacionEstado,
  inLibActualizacionIntf,
  inLibActualizacionScriptsLectura,
  inLibActualizacionScripts,
  inLibVentanaEspera;

type
  // Qué se le pide al proceso: comprobar e instalar, aplicar lo que
  // quedó pendiente, o deshacer la última actualización.
  TModoPantallaActualizacion = (
    mpaComprobar,
    mpaAplicarPendientes,
    mpaRevertir);

  TDecisionScriptsActualizacion = (
    dsaAplazar,
    dsaAhora);

  TContextoActualizacion = record
    Servicio: IServicioActualizaciones;
    Conexion: TUniConnection;
    VersionInstalada: string;
    RutaEjecutable: string;
  end;

  TConfirmarInstalacionActualizacion = reference to function(
    const AManifiesto: TManifiestoActualizacion): Boolean;

  // AHayVersionNueva distingue las dos situaciones: acompañar a una
  // versión recién instalada, o poner al día la base sin cambiar el
  // programa (misma versión). Lo que se le advierte al usuario cambia.
  TDecidirScriptsActualizacion = reference to function(
    const AFaltantes: TArray<TScriptFaltante>;
    AHayVersionNueva: Boolean):
    TDecisionScriptsActualizacion;

  // La pantalla abre la ventana del proceso (la misma que el generador);
  // el dominio solo le va diciendo por dónde va. Puede no haberla: sin
  // ella los scripts se aplican igual, solo que sin nada que mirar.
  TCrearVentanaProcesoActualizacion = reference to function(
    const ATitulo: string): IVentanaEspera;

  TSolicitarCopiaPreviaActualizacion = reference to function(
    out ARutaCopia: string): Boolean;

  TConfirmarReversionActualizacion = reference to function(
    const AEstado: TEstadoActualizacion): Boolean;

  // Devuelve True si el usuario prefiere restaurar la copia previa en
  // lugar de conformarse con los rollbacks disponibles.
  TConsultarRestaurarCopiaActualizacion = reference to function(
    const ASinRollback: TArray<string>;
    const ARutaCopia: string): Boolean;

  // Todo lo que el proceso necesita preguntarle al usuario. Lo rellena
  // la pantalla; el dominio no sabe nada de la VCL.
  TInteraccionActualizacion = record
    Progreso: TProgresoActualizacion;
    ConfirmarInstalacion: TConfirmarInstalacionActualizacion;
    DecidirScripts: TDecidirScriptsActualizacion;
    SolicitarCopiaPrevia: TSolicitarCopiaPreviaActualizacion;
    ConfirmarReversion: TConfirmarReversionActualizacion;
    ConsultarRestaurarCopia: TConsultarRestaurarCopiaActualizacion;
    // Opcional: sin pantalla (las pruebas) no hay ventana que abrir.
    CrearVentanaProceso: TCrearVentanaProcesoActualizacion;
    function Completa: Boolean;
  end;

  TResultadoActualizacion = record
    Ok: Boolean;
    Cancelado: Boolean;
    HayActualizacion: Boolean;
    RequiereSalir: Boolean;
    SolicitaRestaurarCopia: Boolean;
    RutaCopiaPrevia: string;
    Version: string;
    Mensaje: string;
  end;

function ComprobarEInstalarActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
function AplicarScriptsPendientesActualizacion(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
function RevertirActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Threading,
  inLibActualizacionInstalacion,
  inLibActualizacionVersion,
  inLibMsgIntegraciones;

{ TInteraccionActualizacion }

function TInteraccionActualizacion.Completa: Boolean;
begin
  Result := Assigned(Progreso) and
    Assigned(ConfirmarInstalacion) and
    Assigned(DecidirScripts) and
    Assigned(SolicitarCopiaPrevia) and
    Assigned(ConfirmarReversion) and
    Assigned(ConsultarRestaurarCopia);
end;

function RutaDescarga(
  const AVersion, ANombre: string): string;
begin
  Result := TPath.Combine(
    CarpetaDescargasActualizacion(AVersion),
    ANombre);
end;

function DescargarScriptsFaltantes(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AFaltantes: TArray<TScriptFaltante>;
  var AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  iIndice: Integer;
  iPendiente: Integer;
  Script: TScriptActualizacion;
begin
  Result := True;
  AError := '';
  AEstado.Pendientes := nil;
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
  begin
    if Result and AManifiesto.BuscarScript(AFaltantes[iIndice].Nombre,
         Script) then
    begin
      iPendiente := Length(AEstado.Pendientes);
      SetLength(AEstado.Pendientes, iPendiente + 1);
      AEstado.Pendientes[iPendiente].Nombre := Script.Entrada.Nombre;
      AEstado.Pendientes[iPendiente].Orden := AFaltantes[iIndice].Orden;
      AEstado.Pendientes[iPendiente].Ruta := RutaDescarga(
        AManifiesto.Version,
        Script.Entrada.Nombre);
      AEstado.Pendientes[iPendiente].RutaRollback := '';
      Result := AContexto.Servicio.DescargarEntrada(
        AManifiesto.Version,
        cTipoActualizacionScript,
        Script.Entrada,
        AEstado.Pendientes[iPendiente].Ruta,
        AError);
      if Result and Script.Rollback.Declarada then
      begin
        AEstado.Pendientes[iPendiente].RutaRollback := RutaDescarga(
          AManifiesto.Version,
          Script.Rollback.Nombre);
        Result := AContexto.Servicio.DescargarEntrada(
          AManifiesto.Version,
          cTipoActualizacionRollback,
          Script.Rollback,
          AEstado.Pendientes[iPendiente].RutaRollback,
          AError);
      end;
    end
    else if Result then
    begin
      Result := False;
      AError := Format(
        SErrorScriptFaltanteNoPublicado,
        [AFaltantes[iIndice].Nombre, AManifiesto.Version]);
    end;
  end;
end;

function DescargarEjecutables(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  out ARutaEjecutable: string;
  out AError: string): Boolean;
var
  iIndice: Integer;
begin
  ARutaEjecutable := RutaDescarga(
    AManifiesto.Version,
    AManifiesto.Ejecutable.Nombre);
  Result := AContexto.Servicio.DescargarEntrada(
    AManifiesto.Version,
    cTipoActualizacionEjecutable,
    AManifiesto.Ejecutable,
    ARutaEjecutable,
    AError);
  for iIndice := Low(AManifiesto.Auxiliares) to
                 High(AManifiesto.Auxiliares) do
  begin
    if Result then
      Result := AContexto.Servicio.DescargarEntrada(
        AManifiesto.Version,
        cTipoActualizacionAuxiliar,
        AManifiesto.Auxiliares[iIndice],
        RutaDescarga(
          AManifiesto.Version,
          AManifiesto.Auxiliares[iIndice].Nombre),
        AError);
  end;
end;

function ComponerSustituciones(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const ARutaEjecutable: string): TArray<TSustitucionEjecutable>;
var
  iIndice: Integer;
begin
  SetLength(Result, Length(AManifiesto.Auxiliares) + 1);
  Result[0].Destino := AContexto.RutaEjecutable;
  Result[0].Origen := ARutaEjecutable;
  for iIndice := Low(AManifiesto.Auxiliares) to
                 High(AManifiesto.Auxiliares) do
  begin
    Result[iIndice + 1].Destino := TPath.Combine(
      ExtractFilePath(AContexto.RutaEjecutable),
      AManifiesto.Auxiliares[iIndice].Nombre);
    Result[iIndice + 1].Origen := RutaDescarga(
      AManifiesto.Version,
      AManifiesto.Auxiliares[iIndice].Nombre);
  end;
end;

{ El programa suele estar en Archivos de programa, donde no se puede
  escribir sin elevar: en ese caso la sustitución la hace una instancia
  del propio Factuzam lanzada con permisos de administrador. }
function SustituirEjecutables(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const ARutaEjecutable: string;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  aAnteriores: TArray<string>;
  aHuellas: TArray<string>;
  aSustituciones: TArray<TSustitucionEjecutable>;
  iIndice: Integer;
begin
  aSustituciones := ComponerSustituciones(
    AContexto,
    AManifiesto,
    ARutaEjecutable);
  SetLength(aHuellas, Length(aSustituciones));
  aHuellas[0] := AManifiesto.Ejecutable.Sha256;
  for iIndice := Low(AManifiesto.Auxiliares) to
                 High(AManifiesto.Auxiliares) do
    aHuellas[iIndice + 1] := AManifiesto.Auxiliares[iIndice].Sha256;
  if CarpetaEscribible(ExtractFilePath(AContexto.RutaEjecutable)) then
    Result := AplicarSustituciones(aSustituciones, aAnteriores, AError)
  else
  begin
    AInteraccion.Progreso(SAvisoSustitucionNecesitaElevacion, -1);
    Result := AplicarSustitucionesElevado(
      aSustituciones,
      CarpetaActualizaciones,
      aAnteriores,
      AError);
  end;
  for iIndice := Low(aSustituciones) to High(aSustituciones) do
  begin
    if iIndice <= High(aAnteriores) then
      AEstado.AnadirEjecutable(
        aSustituciones[iIndice].Destino,
        aAnteriores[iIndice],
        aHuellas[iIndice]);
  end;
end;

// La ventana del proceso es la del generador: cronómetro propio, se
// puede apartar y enseña el script que se está ejecutando.
function AbrirVentanaScripts(
  const AInteraccion: TInteraccionActualizacion): IVentanaEspera;
begin
  Result := nil;
  if Assigned(AInteraccion.CrearVentanaProceso) then
    Result := AInteraccion.CrearVentanaProceso(
      STituloProcesoScriptsActualizacion);
  if Assigned(Result) then
  begin
    Result.Mostrar(SFaseAplicandoScriptsActualizacion);
    Result.PermitirCancelar(True);
  end;
end;

function TextoScriptEnMarcha(const ARuta: string): string;
begin
  try
    Result := TextoScriptParaVentana(LeerTextoScriptSql(ARuta));
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

// El script corre en su propio hilo para que la ventana se mueva y el
// programa atienda lo que ese hilo le pida (el monitor SQL escribe en el
// principal); no se despacha teclado ni ratón, así que nadie puede
// reentrar en la pantalla mientras tanto.
function EjecutarScriptEnSuHilo(
  AConexion: TUniConnection;
  const ARuta: string;
  out AError: string): Boolean;
var
  bOk: Boolean;
  sError: string;
  Tarea: ITask;
begin
  bOk := False;
  sError := '';
  Tarea := TTask.Run(
    procedure
    begin
      bOk := EjecutarScriptActualizacion(AConexion, ARuta, '', sError);
    end);
  EsperarTareaAtendiendoMensajes(Tarea);
  AError := sError;
  Result := bOk;
end;

procedure AnunciarScriptEnMarcha(
  const AInteraccion: TInteraccionActualizacion;
  const AVentana: IVentanaEspera;
  const APendiente: TScriptPendienteActualizacion;
  AIndice, ATotal: Integer);
var
  sTexto: string;
begin
  sTexto := Format(
    SInfoAplicandoScriptActualizacion,
    [APendiente.Nombre, AIndice, ATotal]);
  AInteraccion.Progreso(sTexto, -1);
  if Assigned(AVentana) then
  begin
    AVentana.ActualizarDetalle(sTexto);
    AVentana.MostrarTexto(TextoScriptEnMarcha(APendiente.Ruta));
  end;
end;

procedure AnotarScriptAplicado(
  var AEstado: TEstadoActualizacion;
  AIndice: Integer;
  AOk: Boolean;
  const ADetalle: string;
  var AError: string);
begin
  if AOk then
    AEstado.AnadirAplicado(
      AEstado.Pendientes[AIndice].Nombre,
      AEstado.Pendientes[AIndice].Orden,
      cResultadoScriptActualizacionOk,
      '',
      AEstado.Pendientes[AIndice].RutaRollback)
  else
  begin
    AError := Format(
      SErrorAplicarScriptActualizacion,
      [AEstado.Pendientes[AIndice].Nombre, ADetalle]);
    AEstado.AnadirAplicado(
      AEstado.Pendientes[AIndice].Nombre,
      AEstado.Pendientes[AIndice].Orden,
      cResultadoScriptActualizacionError,
      ADetalle,
      AEstado.Pendientes[AIndice].RutaRollback);
  end;
end;

function AplicarPendientes(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  out ACancelado: Boolean;
  out AError: string): Boolean;
var
  aRestantes: TArray<TScriptPendienteActualizacion>;
  iIndice: Integer;
  iRestante: Integer;
  iTotal: Integer;
  sDetalle: string;
  Ventana: IVentanaEspera;
begin
  Result := True;
  ACancelado := False;
  AError := '';
  aRestantes := nil;
  iTotal := Length(AEstado.Pendientes);
  Ventana := AbrirVentanaScripts(AInteraccion);
  try
    for iIndice := Low(AEstado.Pendientes) to High(AEstado.Pendientes) do
    begin
      if Result and not ACancelado then
      begin
        // Cancelar no corta la sentencia en marcha: un cambio de esquema
        // a medias no se deshace. Lo que hace es no empezar el siguiente.
        ACancelado := Assigned(Ventana) and Ventana.Cancelado;
        if not ACancelado then
        begin
          AnunciarScriptEnMarcha(
            AInteraccion,
            Ventana,
            AEstado.Pendientes[iIndice],
            iIndice + 1,
            iTotal);
          Result := EjecutarScriptEnSuHilo(
            AConexion,
            AEstado.Pendientes[iIndice].Ruta,
            sDetalle);
          AnotarScriptAplicado(AEstado, iIndice, Result, sDetalle, AError);
        end;
      end;
      if not Result or ACancelado then
      begin
        // Lo que no ha llegado a aplicarse sigue pendiente.
        iRestante := Length(aRestantes);
        SetLength(aRestantes, iRestante + 1);
        aRestantes[iRestante] := AEstado.Pendientes[iIndice];
      end;
    end;
  finally
    if Assigned(Ventana) then
      Ventana.Ocultar;
    Ventana := nil;
  end;
  if Result and not ACancelado then
    AEstado.Pendientes := nil
  else
    AEstado.Pendientes := aRestantes;
end;

// Mensaje con el que se despide un intento de aplicar scripts que no
// llega a ejecutarlos todos.
function MensajeScriptsSinAplicar(
  ACancelado: Boolean;
  APendientes: Integer): string;
begin
  if ACancelado then
    Result := Format(SInfoScriptsActualizacionCancelados, [APendientes])
  else
    Result := Format(SInfoScriptsActualizacionAplazados, [APendientes]);
end;

procedure AplicarFaltantesSinInstalacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  const AFaltantes: TArray<TScriptFaltante>;
  var AEstado: TEstadoActualizacion;
  var AResultado: TResultadoActualizacion);
var
  bCancelado: Boolean;
  sError: string;
begin
  AResultado.Ok := True;
  bCancelado := False;
  if AInteraccion.DecidirScripts(AFaltantes, False) = dsaAplazar then
    AResultado.Mensaje := MensajeScriptsSinAplicar(
      False,
      Length(AEstado.Pendientes))
  else if not AInteraccion.SolicitarCopiaPrevia(AEstado.RutaCopiaPrevia) then
  begin
    AResultado.Cancelado := True;
    AResultado.Mensaje := MensajeScriptsSinAplicar(
      False,
      Length(AEstado.Pendientes));
  end
  else
  begin
    AResultado.Ok := AplicarPendientes(
      AContexto.Conexion,
      AInteraccion,
      AEstado,
      bCancelado,
      sError);
    AResultado.Cancelado := bCancelado;
    AResultado.Mensaje := sError;
    // Sin ejecutable nuevo no hace falta salir del programa: lo que ha
    // cambiado es la base de datos.
    if AResultado.Ok and (AResultado.Mensaje = '') then
    begin
      if bCancelado then
        AResultado.Mensaje := MensajeScriptsSinAplicar(
          True,
          Length(AEstado.Pendientes))
      else
        AResultado.Mensaje := SInfoScriptsPendientesAplicados;
    end;
  end;
  if AEstado.HayScriptsPendientes then
    AEstado.Estado := cEstadoActualizacionPendiente
  else
    AEstado.Estado := cEstadoActualizacionCompletada;
  if not GuardarEstadoActualizacion(AEstado, sError) then
    AResultado.Mensaje := AResultado.Mensaje + sLineBreak + sError;
end;

{ No hay versión nueva que instalar, pero la base de datos puede seguir
  sin los cambios de esquema de la última publicada: se comprueban igual
  y se ofrecen, que es la forma de poner al día una instalación sin
  esperar a que salga otra versión. }
function ComprobarScriptsSinInstalacion(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  aFaltantes: TArray<TScriptFaltante>;
  Estado: TEstadoActualizacion;
  sError: string;
  sRutaComprobacion: string;
begin
  Result := Default(TResultadoActualizacion);
  Result.Version := AManifiesto.Version;
  if not AManifiesto.Comprobacion.Declarada then
  begin
    Result.Ok := True;
    Result.Mensaje := Format(
      SInfoVersionInstaladaAlDia,
      [AContexto.VersionInstalada]);
  end
  else
  begin
    TDirectory.CreateDirectory(
      CarpetaDescargasActualizacion(AManifiesto.Version));
    sRutaComprobacion := RutaDescarga(
      AManifiesto.Version,
      AManifiesto.Comprobacion.Nombre);
    if not AContexto.Servicio.DescargarEntrada(
             AManifiesto.Version,
             cTipoActualizacionComprobacion,
             AManifiesto.Comprobacion,
             sRutaComprobacion,
             sError) then
      Result.Mensaje := sError
    else
    begin
      AInteraccion.Progreso(SInfoComprobandoScriptsAplicados, -1);
      if not ConsultarScriptsFaltantes(
               AContexto.Conexion,
               LeerTextoScriptSql(sRutaComprobacion),
               aFaltantes,
               sError) then
        Result.Mensaje := sError
      else if Length(aFaltantes) = 0 then
      begin
        Result.Ok := True;
        Result.Mensaje := Format(
          SInfoVersionAlDiaSinScripts,
          [AContexto.VersionInstalada]);
      end
      else
      begin
        // El estado que hubiera se conserva: aquí no se sustituye ningún
        // ejecutable, así que no hay por qué perder con qué revertir.
        Estado := EstadoParaScriptsSinInstalacion(
          LeerEstadoActualizacion,
          AContexto.VersionInstalada,
          AManifiesto.Version,
          AManifiesto.Arquitectura);
        Estado.RutaComprobacion := sRutaComprobacion;
        Estado.Instante := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
        if not DescargarScriptsFaltantes(
                 AContexto,
                 AManifiesto,
                 aFaltantes,
                 Estado,
                 sError) then
          Result.Mensaje := sError
        else
          AplicarFaltantesSinInstalacion(
            AContexto,
            AInteraccion,
            aFaltantes,
            Estado,
            Result);
      end;
    end;
  end;
end;

function InstalarVersionPublicada(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  aFaltantes: TArray<TScriptFaltante>;
  bCancelado: Boolean;
  Decision: TDecisionScriptsActualizacion;
  Estado: TEstadoActualizacion;
  sError: string;
  sRutaComprobacion: string;
  sRutaEjecutable: string;
begin
  Result := Default(TResultadoActualizacion);
  Result.Version := AManifiesto.Version;
  if not AManifiesto.Ejecutable.Declarada then
    Result.Mensaje := SErrorEntradaActualizacionNoDeclarada
  else
  begin
    Result.HayActualizacion := True;
    if not AInteraccion.ConfirmarInstalacion(AManifiesto) then
    begin
      Result.Ok := True;
      Result.Cancelado := True;
    end
    else
    begin
      Estado := Default(TEstadoActualizacion);
      Estado.VersionOrigen := AContexto.VersionInstalada;
      Estado.VersionDestino := AManifiesto.Version;
      Estado.Arquitectura := AManifiesto.Arquitectura;
      Estado.Instante := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
      TDirectory.CreateDirectory(
        CarpetaDescargasActualizacion(AManifiesto.Version));
      // Primero se descarga y se mira qué falta en la base: mientras no
      // esté todo en su sitio no se toca ningún ejecutable.
      if not DescargarEjecutables(
               AContexto,
               AManifiesto,
               sRutaEjecutable,
               sError) then
        Result.Mensaje := sError
      else
      begin
        sRutaComprobacion := RutaDescarga(
          AManifiesto.Version,
          AManifiesto.Comprobacion.Nombre);
        if not AContexto.Servicio.DescargarEntrada(
                 AManifiesto.Version,
                 cTipoActualizacionComprobacion,
                 AManifiesto.Comprobacion,
                 sRutaComprobacion,
                 sError) then
          Result.Mensaje := sError
        else
        begin
          Estado.RutaComprobacion := sRutaComprobacion;
          AInteraccion.Progreso(SInfoComprobandoScriptsAplicados, -1);
          if not ConsultarScriptsFaltantes(
                   AContexto.Conexion,
                   LeerTextoScriptSql(sRutaComprobacion),
                   aFaltantes,
                   sError) then
            Result.Mensaje := sError
          else if not DescargarScriptsFaltantes(
                        AContexto,
                        AManifiesto,
                        aFaltantes,
                        Estado,
                        sError) then
            Result.Mensaje := sError
          else if not SustituirEjecutables(
                        AContexto,
                        AManifiesto,
                        sRutaEjecutable,
                        AInteraccion,
                        Estado,
                        sError) then
            Result.Mensaje := sError
          else
          begin
            Result.Ok := True;
            Estado.Estado := cEstadoActualizacionCompletada;
            if Estado.HayScriptsPendientes then
            begin
              Decision := AInteraccion.DecidirScripts(aFaltantes, True);
              if (Decision = dsaAhora) and
                 AInteraccion.SolicitarCopiaPrevia(
                   Estado.RutaCopiaPrevia) then
              begin
                Result.Ok := AplicarPendientes(
                  AContexto.Conexion,
                  AInteraccion,
                  Estado,
                  bCancelado,
                  sError);
                Result.Cancelado := bCancelado;
                Result.Mensaje := sError;
                Result.RequiereSalir := True;
              end;
              if Estado.HayScriptsPendientes then
                Estado.Estado := cEstadoActualizacionPendiente;
            end;
            if Result.Mensaje = '' then
              Result.Mensaje := Format(
                SInfoActualizacionInstalada,
                [AManifiesto.Version]);
            if not GuardarEstadoActualizacion(Estado, sError) then
              Result.Mensaje := Result.Mensaje + sLineBreak + sError;
          end;
        end;
      end;
    end;
  end;
end;

function ComprobarEInstalarActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  Manifiesto: TManifiestoActualizacion;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Manifiesto := AContexto.Servicio.ConsultarUltima(
    AContexto.VersionInstalada);
  Result.Version := Manifiesto.Version;
  if not Manifiesto.Ok then
    Result.Mensaje := Manifiesto.Mensaje
  else
    case CaminoComprobacionActualizacion(
           Manifiesto.HayVersion,
           Manifiesto.Version,
           AContexto.VersionInstalada) of
      ccaSinVersiones:
        begin
          Result.Ok := True;
          Result.Mensaje := SInfoSinVersionesPublicadas;
        end;
      ccaSoloScripts:
        Result := ComprobarScriptsSinInstalacion(
          AContexto,
          Manifiesto,
          AInteraccion);
      ccaInstalarVersion:
        Result := InstalarVersionPublicada(
          AContexto,
          Manifiesto,
          AInteraccion);
    end;
end;

function AplicarScriptsPendientesActualizacion(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  bCancelado: Boolean;
  Estado: TEstadoActualizacion;
  sError: string;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Estado := LeerEstadoActualizacion;
  Result.Version := Estado.VersionDestino;
  if not Estado.Existe or not Estado.HayScriptsPendientes then
  begin
    Result.Ok := True;
    Result.Mensaje := SInfoSinScriptsPendientes;
  end
  else if not AInteraccion.SolicitarCopiaPrevia(Estado.RutaCopiaPrevia) then
  begin
    Result.Ok := True;
    Result.Cancelado := True;
  end
  else
  begin
    Result.Ok := AplicarPendientes(
      AConexion,
      AInteraccion,
      Estado,
      bCancelado,
      sError);
    Result.Cancelado := bCancelado;
    Result.Mensaje := sError;
    // Solo hay que salir si estos scripts acompañan a un ejecutable
    // nuevo; los de una base que se pone al día no obligan a nada.
    Result.RequiereSalir := Length(Estado.Ejecutables) > 0;
    if Estado.HayScriptsPendientes then
    begin
      Estado.Estado := cEstadoActualizacionPendiente;
      if bCancelado and (Result.Mensaje = '') then
        Result.Mensaje := MensajeScriptsSinAplicar(
          True,
          Length(Estado.Pendientes));
    end
    else
    begin
      Estado.Estado := cEstadoActualizacionCompletada;
      if Result.Mensaje = '' then
        Result.Mensaje := SInfoScriptsPendientesAplicados;
    end;
    if not GuardarEstadoActualizacion(Estado, sError) then
      Result.Mensaje := Result.Mensaje + sLineBreak + sError;
  end;
end;

function RevertirScripts(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  var AResultado: TResultadoActualizacion): Boolean;
var
  aSinRollback: TArray<string>;
  iIndice: Integer;
  iSin: Integer;
  sDetalle: string;
begin
  Result := True;
  aSinRollback := nil;
  for iIndice := High(AEstado.Aplicados) downto Low(AEstado.Aplicados) do
  begin
    if SameText(
         AEstado.Aplicados[iIndice].Resultado,
         cResultadoScriptActualizacionOk) then
    begin
      if (Trim(AEstado.Aplicados[iIndice].RutaRollback) = '') or
         not TFile.Exists(AEstado.Aplicados[iIndice].RutaRollback) then
      begin
        iSin := Length(aSinRollback);
        SetLength(aSinRollback, iSin + 1);
        aSinRollback[iSin] := AEstado.Aplicados[iIndice].Nombre;
      end
      else if Result then
      begin
        AInteraccion.Progreso(
          Format(
            SInfoRevirtiendoScriptActualizacion,
            [AEstado.Aplicados[iIndice].Nombre]),
          -1);
        Result := EjecutarScriptActualizacion(
          AConexion,
          AEstado.Aplicados[iIndice].RutaRollback,
          '',
          sDetalle);
        if not Result then
          AResultado.Mensaje := Format(
            SErrorRevertirScriptActualizacion,
            [AEstado.Aplicados[iIndice].Nombre, sDetalle]);
      end;
    end;
  end;
  if Result and (Length(aSinRollback) > 0) then
  begin
    AResultado.SolicitaRestaurarCopia := AInteraccion.ConsultarRestaurarCopia(
      aSinRollback,
      AEstado.RutaCopiaPrevia);
    AResultado.RutaCopiaPrevia := AEstado.RutaCopiaPrevia;
  end;
end;

function RevertirEjecutables(
  const AEstado: TEstadoActualizacion;
  var AResultado: TResultadoActualizacion): Boolean;
var
  iIndice: Integer;
  sDescartada: string;
  sError: string;
begin
  Result := True;
  for iIndice := High(AEstado.Ejecutables) downto
                 Low(AEstado.Ejecutables) do
  begin
    // Un auxiliar que antes no estaba instalado se retira sin mas.
    if (Trim(AEstado.Ejecutables[iIndice].RutaAnterior) = '') and
       TFile.Exists(AEstado.Ejecutables[iIndice].Ruta) then
      TFile.Delete(AEstado.Ejecutables[iIndice].Ruta);
    if not RestaurarEjecutableAnterior(
             AEstado.Ejecutables[iIndice].Ruta,
             AEstado.VersionDestino,
             sDescartada,
             sError) then
    begin
      Result := False;
      if AResultado.Mensaje <> '' then
        AResultado.Mensaje := AResultado.Mensaje + sLineBreak;
      AResultado.Mensaje := AResultado.Mensaje + sError;
    end;
  end;
end;

function RevertirActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  Estado: TEstadoActualizacion;
  sError: string;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Estado := LeerEstadoActualizacion;
  Result.Version := Estado.VersionDestino;
  if not Estado.SePuedeRevertir then
    Result.Mensaje := SErrorSinActualizacionRevertible
  else if not AInteraccion.ConfirmarReversion(Estado) then
  begin
    Result.Ok := True;
    Result.Cancelado := True;
  end
  else
  begin
    Result.Ok := RevertirScripts(
      AContexto.Conexion,
      AInteraccion,
      Estado,
      Result);
    if Result.Ok then
    begin
      Result.Ok := RevertirEjecutables(Estado, Result);
      Result.RequiereSalir := True;
      Estado.Estado := cEstadoActualizacionRevertida;
      Estado.Pendientes := nil;
      if not GuardarEstadoActualizacion(Estado, sError) then
        Result.Mensaje := Result.Mensaje + sLineBreak + sError;
      if Result.Ok and (Result.Mensaje = '') then
        Result.Mensaje := Format(
          SInfoActualizacionRevertida,
          [Estado.VersionOrigen]);
    end;
  end;
end;
end.
