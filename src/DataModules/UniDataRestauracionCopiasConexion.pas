{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRestauracionCopiasConexion                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara UniDAC y crea el worker de restauración previo al acceso.         }
{******************************************************************************}
unit UniDataRestauracionCopiasConexion;

interface

uses
  Uni,
  inLibCopiasSeguridadIntf,
  inLibRestauracionCopiasConexionIntf;

function CrearRepositorioRestauracionConexionUniDAC(
  AConexion: TUniConnection): IRepositorioRestauracionConexion;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibBackupWorker,
  inLibConexionesUniDAC;

type
  TRepositorioRestauracionConexionUniDAC = class(
    TInterfacedObject,
    IRepositorioRestauracionConexion)
  private
    FConexion: TUniConnection;
    procedure PrepararConexion(
      const ASolicitud: TSolicitudRestauracionConexion);
  public
    constructor Create(AConexion: TUniConnection);
    procedure Iniciar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
  end;

constructor TRepositorioRestauracionConexionUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

procedure TRepositorioRestauracionConexionUniDAC.PrepararConexion(
  const ASolicitud: TSolicitudRestauracionConexion);
var
  oConsulta: TUniQuery;
begin
  ConfigurarYConectarMySQL(
    FConexion,
    ASolicitud.Usuario,
    ASolicitud.ContrasenaConexion,
    ASolicitud.Host,
    IntToStr(ASolicitud.Puerto),
    'information_schema');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT SCHEMA_NAME ' +
      'FROM INFORMATION_SCHEMA.SCHEMATA ' +
      'WHERE SCHEMA_NAME = :BBDD';
    oConsulta.ParamByName('BBDD').AsString :=
      ASolicitud.BaseDatos;
    oConsulta.Open;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioRestauracionConexionUniDAC.Iniciar(
  const ASolicitud: TSolicitudRestauracionConexion;
  AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent);
var
  bDesencriptar: Boolean;
  oWorker: TRestoreWorker;
begin
  PrepararConexion(ASolicitud);
  bDesencriptar := SameText(
    ExtractFileExt(ASolicitud.RutaFichero),
    '.crypt');
  oWorker := TRestoreWorker.Create(
    ASolicitud.Host,
    ASolicitud.Puerto,
    ASolicitud.BaseDatos,
    ASolicitud.Usuario,
    ASolicitud.ContrasenaConexion,
    ASolicitud.RutaFichero,
    ASolicitud.ContrasenaCopia,
    bDesencriptar);
  try
    oWorker.OnProgreso := AOnProgreso;
    oWorker.OnFinalizar := AOnFinalizar;
    if Assigned(AOnPrepararWorker) then
      AOnPrepararWorker(oWorker);
    oWorker.Start;
  except
    if Assigned(AOnPrepararWorker) then
      AOnPrepararWorker(nil);
    FreeAndNil(oWorker);
    raise;
  end;
end;

function CrearRepositorioRestauracionConexionUniDAC(
  AConexion: TUniConnection): IRepositorioRestauracionConexion;
begin
  Result := TRepositorioRestauracionConexionUniDAC.Create(AConexion);
end;

end.
