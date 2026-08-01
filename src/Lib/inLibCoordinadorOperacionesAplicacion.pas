{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCoordinadorOperacionesAplicacion                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina workers, cancelación y ciclo de vida de copias y restauraciones.}
{******************************************************************************}
unit inLibCoordinadorOperacionesAplicacion;

interface

uses
  System.Classes,
  inLibCopiasSeguridadIntf,
  inLibOperacionesAplicacionIntf;

type
  TCoordinadorOperacionesAplicacion = class(
    TInterfacedObject,
    ICoordinadorOperacionesAplicacion)
  private
    FServicioCopias: IServicioCopiasSeguridad;
    FPresentacion: IPresentacionOperacionesAplicacion;
    FWorker: TThread;
    FEnCurso: Boolean;
    FCancelacionSolicitada: Boolean;
    FTipoOperacion: TTipoOperacionAplicacion;
    procedure ComenzarOperacion(ATipo: TTipoOperacionAplicacion);
    procedure AbortarInicioOperacion;
    procedure ProgresoWorker(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure FinalizarWorker(
      AExito: Boolean;
      const AError: string;
      ALogBuffer: TStringList);
    function EsErrorCancelacion(const AError: string): Boolean;
  public
    constructor Create(
      const AServicioCopias: IServicioCopiasSeguridad;
      const APresentacion: IPresentacionOperacionesAplicacion);
    function EnCurso: Boolean;
    function ModoCreacionCopia: TModoProteccionCopia;
    function ExtensionCreacionCopia: string;
    function PuedeRestaurar(const ARutaFichero: string): Boolean;
    function RequiereContrasena(const ARutaFichero: string): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string);
    function CrearCopia(
      const ARutaFichero, AContrasena: string): Boolean;
    function CancelacionSolicitada: Boolean;
    function SolicitarCancelacion: Boolean;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorServicioCopiasNoProporcionado =
    'No se ha proporcionado el servicio de copias de seguridad.';
  SErrorPresentacionOperacionesNoProporcionada =
    'No se ha proporcionado la presentación de operaciones largas.';
  SErrorOperacionAplicacionEnCurso =
    'Ya hay una operación larga en curso.';

constructor TCoordinadorOperacionesAplicacion.Create(
  const AServicioCopias: IServicioCopiasSeguridad;
  const APresentacion: IPresentacionOperacionesAplicacion);
begin
  inherited Create;
  if not Assigned(AServicioCopias) then
  begin
    raise EArgumentNilException.Create(
      SErrorServicioCopiasNoProporcionado);
  end;
  if not Assigned(APresentacion) then
  begin
    raise EArgumentNilException.Create(
      SErrorPresentacionOperacionesNoProporcionada);
  end;
  FServicioCopias := AServicioCopias;
  FPresentacion := APresentacion;
end;

procedure TCoordinadorOperacionesAplicacion.ComenzarOperacion(
  ATipo: TTipoOperacionAplicacion);
begin
  if FEnCurso then
  begin
    raise EInvalidOpException.Create(
      SErrorOperacionAplicacionEnCurso);
  end;
  FTipoOperacion := ATipo;
  FWorker := nil;
  FCancelacionSolicitada := False;
  FEnCurso := True;
  FPresentacion.MostrarOperacion;
end;

procedure TCoordinadorOperacionesAplicacion.AbortarInicioOperacion;
begin
  FWorker := nil;
  FCancelacionSolicitada := False;
  FEnCurso := False;
  FPresentacion.FinalizarOperacion(
    FTipoOperacion,
    False,
    False,
    '',
    nil);
end;

function TCoordinadorOperacionesAplicacion.EnCurso: Boolean;
begin
  Result := FEnCurso;
end;

function TCoordinadorOperacionesAplicacion.ModoCreacionCopia:
  TModoProteccionCopia;
begin
  Result := FServicioCopias.ModoCreacion;
end;

function TCoordinadorOperacionesAplicacion.ExtensionCreacionCopia: string;
begin
  Result := FServicioCopias.ExtensionCreacion;
end;

function TCoordinadorOperacionesAplicacion.PuedeRestaurar(
  const ARutaFichero: string): Boolean;
begin
  Result := FServicioCopias.PuedeRestaurar(ARutaFichero);
end;

function TCoordinadorOperacionesAplicacion.RequiereContrasena(
  const ARutaFichero: string): Boolean;
begin
  Result := FServicioCopias.RequiereContrasena(ARutaFichero);
end;

procedure TCoordinadorOperacionesAplicacion.IniciarCopia(
  const ARutaFichero, AContrasena: string);
begin
  ComenzarOperacion(toaCopiaSeguridad);
  try
    FServicioCopias.IniciarCopia(
      ARutaFichero,
      AContrasena,
      ProgresoWorker,
      FinalizarWorker,
      FWorker);
  except
    AbortarInicioOperacion;
    raise;
  end;
end;

procedure TCoordinadorOperacionesAplicacion.IniciarRestauracion(
  const ARutaFichero, AContrasena: string);
begin
  ComenzarOperacion(toaRestauracion);
  try
    FServicioCopias.IniciarRestauracion(
      ARutaFichero,
      AContrasena,
      ProgresoWorker,
      FinalizarWorker,
      FWorker);
  except
    AbortarInicioOperacion;
    raise;
  end;
end;

function TCoordinadorOperacionesAplicacion.CrearCopia(
  const ARutaFichero, AContrasena: string): Boolean;
var
  sError: string;
begin
  ComenzarOperacion(toaCopiaSeguridad);
  sError := '';
  try
    Result := FServicioCopias.CrearCopia(
      ARutaFichero,
      AContrasena,
      ProgresoWorker,
      sError);
    FinalizarWorker(Result, sError, nil);
  except
    AbortarInicioOperacion;
    raise;
  end;
end;

function TCoordinadorOperacionesAplicacion.CancelacionSolicitada: Boolean;
begin
  Result := FCancelacionSolicitada;
end;

function TCoordinadorOperacionesAplicacion.SolicitarCancelacion: Boolean;
begin
  Result := FEnCurso and not FCancelacionSolicitada;
  if Result then
  begin
    FCancelacionSolicitada := True;
    if Assigned(FWorker) then
      FWorker.Terminate;
    FPresentacion.MostrarCancelando;
  end;
end;

procedure TCoordinadorOperacionesAplicacion.ProgresoWorker(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if FEnCurso then
  begin
    FPresentacion.ActualizarProgreso(
      AEtapa,
      APaso,
      ATotal,
      AFilaGlobal,
      AFilasGlobalTotal);
  end;
end;

procedure TCoordinadorOperacionesAplicacion.FinalizarWorker(
  AExito: Boolean;
  const AError: string;
  ALogBuffer: TStringList);
var
  bCancelada: Boolean;
begin
  bCancelada := (not AExito) and EsErrorCancelacion(AError);
  FWorker := nil;
  FCancelacionSolicitada := False;
  FEnCurso := False;
  FPresentacion.FinalizarOperacion(
    FTipoOperacion,
    AExito,
    bCancelada,
    AError,
    ALogBuffer);
end;

function TCoordinadorOperacionesAplicacion.EsErrorCancelacion(
  const AError: string): Boolean;
begin
  Result := Pos('cancelada', LowerCase(AError)) > 0;
end;

end.
