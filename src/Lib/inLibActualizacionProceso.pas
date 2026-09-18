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
  inLibActualizacionScripts;

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

  TDecidirScriptsActualizacion = reference to function(
    const AFaltantes: TArray<TScriptFaltante>):
    TDecisionScriptsActualizacion;

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
  System.IOUtils,
  System.SysUtils,
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

function AplicarPendientes(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  aRestantes: TArray<TScriptPendienteActualizacion>;
  iIndice: Integer;
  iRestante: Integer;
  iTotal: Integer;
  sDetalle: string;
begin
  Result := True;
  AError := '';
  aRestantes := nil;
  iTotal := Length(AEstado.Pendientes);
  for iIndice := Low(AEstado.Pendientes) to High(AEstado.Pendientes) do
  begin
    if Result then
    begin
      AInteraccion.Progreso(
        Format(
          SInfoAplicandoScriptActualizacion,
          [AEstado.Pendientes[iIndice].Nombre, iIndice + 1, iTotal]),
        -1);
      Result := EjecutarScriptActualizacion(
        AConexion,
        AEstado.Pendientes[iIndice].Ruta,
        '',
        sDetalle);
      if Result then
        AEstado.AnadirAplicado(
          AEstado.Pendientes[iIndice].Nombre,
          AEstado.Pendientes[iIndice].Orden,
          cResultadoScriptActualizacionOk,
          '',
          AEstado.Pendientes[iIndice].RutaRollback)
      else
      begin
        AError := Format(
          SErrorAplicarScriptActualizacion,
          [AEstado.Pendientes[iIndice].Nombre, sDetalle]);
        AEstado.AnadirAplicado(
          AEstado.Pendientes[iIndice].Nombre,
          AEstado.Pendientes[iIndice].Orden,
          cResultadoScriptActualizacionError,
          sDetalle,
          AEstado.Pendientes[iIndice].RutaRollback);
      end;
    end;
    if not Result then
    begin
      // Lo que no ha llegado a aplicarse sigue pendiente.
      iRestante := Length(aRestantes);
      SetLength(aRestantes, iRestante + 1);
      aRestantes[iRestante] := AEstado.Pendientes[iIndice];
    end;
  end;
  if Result then
    AEstado.Pendientes := nil
  else
    AEstado.Pendientes := aRestantes;
end;

function ComprobarEInstalarActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  aFaltantes: TArray<TScriptFaltante>;
  Decision: TDecisionScriptsActualizacion;
  Estado: TEstadoActualizacion;
  Manifiesto: TManifiestoActualizacion;
  sError: string;
  sRutaComprobacion: string;
  sRutaEjecutable: string;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Manifiesto := AContexto.Servicio.ConsultarUltima(
    AContexto.VersionInstalada);
  Result.Version := Manifiesto.Version;
  if not Manifiesto.Ok then
    Result.Mensaje := Manifiesto.Mensaje
  else if not Manifiesto.HayVersion then
  begin
    Result.Ok := True;
    Result.Mensaje := SInfoSinVersionesPublicadas;
  end
  else if not VersionAplicacionEsMayor(
                Manifiesto.Version,
                AContexto.VersionInstalada) then
  begin
    Result.Ok := True;
    Result.Mensaje := Format(
      SInfoVersionInstaladaAlDia,
      [AContexto.VersionInstalada]);
  end
  else if not Manifiesto.Ejecutable.Declarada then
    Result.Mensaje := SErrorEntradaActualizacionNoDeclarada
  else
  begin
    Result.HayActualizacion := True;
    if not AInteraccion.ConfirmarInstalacion(Manifiesto) then
    begin
      Result.Ok := True;
      Result.Cancelado := True;
    end
    else
    begin
      Estado := Default(TEstadoActualizacion);
      Estado.VersionOrigen := AContexto.VersionInstalada;
      Estado.VersionDestino := Manifiesto.Version;
      Estado.Arquitectura := Manifiesto.Arquitectura;
      Estado.Instante := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
      TDirectory.CreateDirectory(
        CarpetaDescargasActualizacion(Manifiesto.Version));
      // Primero se descarga y se mira qué falta en la base: mientras no
      // esté todo en su sitio no se toca ningún ejecutable.
      if not DescargarEjecutables(
               AContexto,
               Manifiesto,
               sRutaEjecutable,
               sError) then
        Result.Mensaje := sError
      else
      begin
        sRutaComprobacion := RutaDescarga(
          Manifiesto.Version,
          Manifiesto.Comprobacion.Nombre);
        if not AContexto.Servicio.DescargarEntrada(
                 Manifiesto.Version,
                 cTipoActualizacionComprobacion,
                 Manifiesto.Comprobacion,
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
                        Manifiesto,
                        aFaltantes,
                        Estado,
                        sError) then
            Result.Mensaje := sError
          else if not SustituirEjecutables(
                        AContexto,
                        Manifiesto,
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
              Decision := AInteraccion.DecidirScripts(aFaltantes);
              if (Decision = dsaAhora) and
                 AInteraccion.SolicitarCopiaPrevia(
                   Estado.RutaCopiaPrevia) then
              begin
                Result.Ok := AplicarPendientes(
                  AContexto.Conexion,
                  AInteraccion,
                  Estado,
                  sError);
                Result.Mensaje := sError;
                Result.RequiereSalir := True;
              end;
              if Estado.HayScriptsPendientes then
                Estado.Estado := cEstadoActualizacionPendiente;
            end;
            if Result.Mensaje = '' then
              Result.Mensaje := Format(
                SInfoActualizacionInstalada,
                [Manifiesto.Version]);
            if not GuardarEstadoActualizacion(Estado, sError) then
              Result.Mensaje := Result.Mensaje + sLineBreak + sError;
          end;
        end;
      end;
    end;
  end;
end;

function AplicarScriptsPendientesActualizacion(
  AConexion: TUniConnection;
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
      sError);
    Result.Mensaje := sError;
    Result.RequiereSalir := True;
    if Estado.HayScriptsPendientes then
      Estado.Estado := cEstadoActualizacionPendiente
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
