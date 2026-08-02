{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCopiasSeguridad                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio de creación y restauración segura de copias de la BBDD.          }
{******************************************************************************}
unit inLibCopiasSeguridad;

interface

uses
  System.Classes,
  Uni,
  inLibContextoSesionIntf,
  inLibCopiasSeguridadIntf;

type
  TRepositorioCopiasSeguridadUniDAC = class(
    TInterfacedObject,
    IRepositorioCopiasSeguridad
  )
  private
    FContextoSesion: IContextoSesionAplicacion;
    FConexion: TUniConnection;
    function EsAdministrador: Boolean;
    procedure ValidarConexion;
    procedure ValidarContrasena(
      const AContrasena: string);
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      AConexion: TUniConnection);
    function ModoCreacion: TModoProteccionCopia;
    function ExtensionCreacion: string;
    function PuedeRestaurar(
      const ARutaFichero: string
    ): Boolean;
    function RequiereContrasena(
      const ARutaFichero: string
    ): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    function CrearCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string
    ): TResultadoCopiaSeguridad;
    function CrearCopiaProtegida(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string
    ): TResultadoCopiaSeguridad;
  end;

implementation

uses
  System.SysUtils,
  inLibBackupWorker,
  inLibCopiasSeguridadReglas;

constructor TRepositorioCopiasSeguridadUniDAC.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AContextoSesion) then
  begin
    raise EArgumentNilException.Create(
      'AContextoSesion');
  end;
  FContextoSesion := AContextoSesion;
  FConexion := AConexion;
end;

function TRepositorioCopiasSeguridadUniDAC.EsAdministrador: Boolean;
begin
  Result := FContextoSesion.Identidad.EsAdministrador;
end;

procedure TRepositorioCopiasSeguridadUniDAC.ValidarConexion;
begin
  if not Assigned(FConexion) then
  begin
    raise EInvalidOpException.Create(
      'No hay una conexión disponible para la copia de seguridad.');
  end;
end;

procedure TRepositorioCopiasSeguridadUniDAC.ValidarContrasena(
  const AContrasena: string);
begin
  if Trim(AContrasena) = '' then
  begin
    raise EArgumentException.Create(
      'La contraseña de la copia no puede estar vacía.');
  end;
end;

function TRepositorioCopiasSeguridadUniDAC.ModoCreacion:
  TModoProteccionCopia;
begin
  Result := TPoliticaCopiasSeguridad.ModoCreacion(
    EsAdministrador);
end;

function TRepositorioCopiasSeguridadUniDAC.ExtensionCreacion: string;
begin
  Result := TPoliticaCopiasSeguridad.ExtensionCreacion(
    EsAdministrador);
end;

function TRepositorioCopiasSeguridadUniDAC.PuedeRestaurar(
  const ARutaFichero: string): Boolean;
begin
  Result := TPoliticaCopiasSeguridad.PuedeRestaurar(
    EsAdministrador,
    ARutaFichero);
end;

function TRepositorioCopiasSeguridadUniDAC.RequiereContrasena(
  const ARutaFichero: string): Boolean;
begin
  Result := TPoliticaCopiasSeguridad.EsCopiaCifrada(
    ARutaFichero);
end;

procedure TRepositorioCopiasSeguridadUniDAC.IniciarCopia(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
var
  bEncriptar: Boolean;
  oWorker: TBackupWorker;
begin
  ValidarConexion;
  bEncriptar := ModoCreacion = mpcCifrada;
  if bEncriptar then
    ValidarContrasena(AContrasena);
  AWorker := nil;
  oWorker := TBackupWorker.Create(
    FConexion.Server,
    FConexion.Port,
    FConexion.Database,
    FConexion.Username,
    FConexion.Password,
    ARutaFichero,
    bEncriptar,
    AContrasena);
  try
    oWorker.OnProgreso := AOnProgreso;
    oWorker.OnFinalizar := AOnFinalizar;
    AWorker := oWorker;
    oWorker.Start;
  except
    AWorker := nil;
    FreeAndNil(oWorker);
    raise;
  end;
end;

procedure TRepositorioCopiasSeguridadUniDAC.IniciarRestauracion(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
var
  bDesencriptar: Boolean;
  oWorker: TRestoreWorker;
begin
  ValidarConexion;
  if not PuedeRestaurar(ARutaFichero) then
  begin
    raise EArgumentException.Create(
      'El usuario no puede restaurar este tipo de archivo.');
  end;
  bDesencriptar := RequiereContrasena(ARutaFichero);
  if bDesencriptar then
    ValidarContrasena(AContrasena);
  AWorker := nil;
  oWorker := TRestoreWorker.Create(
    FConexion.Server,
    FConexion.Port,
    FConexion.Database,
    FConexion.Username,
    FConexion.Password,
    ARutaFichero,
    AContrasena,
    bDesencriptar);
  try
    oWorker.OnProgreso := AOnProgreso;
    oWorker.OnFinalizar := AOnFinalizar;
    AWorker := oWorker;
    oWorker.Start;
  except
    AWorker := nil;
    FreeAndNil(oWorker);
    raise;
  end;
end;

function TRepositorioCopiasSeguridadUniDAC.CrearCopia(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
var
  bEncriptar: Boolean;
begin
  ValidarConexion;
  bEncriptar := ModoCreacion = mpcCifrada;
  if bEncriptar then
    ValidarContrasena(AContrasena);
  Result := CrearCopiaSeguridadBD(
    FConexion.Server,
    FConexion.Port,
    FConexion.Database,
    FConexion.Username,
    FConexion.Password,
    ARutaFichero,
    bEncriptar,
    AContrasena,
    AOnProgreso,
    AError);
end;

function TRepositorioCopiasSeguridadUniDAC.CrearCopiaProtegida(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
begin
  ValidarConexion;
  ValidarContrasena(AContrasena);
  Result := CrearCopiaSeguridadBD(
    FConexion.Server,
    FConexion.Port,
    FConexion.Database,
    FConexion.Username,
    FConexion.Password,
    ARutaFichero,
    True,
    AContrasena,
    AOnProgreso,
    AError,
    True);
end;

end.
