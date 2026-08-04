{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRestauracionCopiasConexion                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verifica la frontera del caso de uso de restauración previa al acceso.    }
{******************************************************************************}
unit PruebasRestauracionCopiasConexion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRestauracionCopiasConexion = class
  public
    [Test]
    procedure Ejecutar_EntregaSolicitudAlRepositorio;
    [Test]
    procedure Ejecutar_SinRutaNoInvocaRepositorio;
    [Test]
    procedure Streaming_ErrorConexionSePropaga;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  Backup.Engine,
  inLibBackupPersistenciaIntf,
  inLibCopiasSeguridadIntf,
  inLibRestauracionCopiasConexion,
  inLibRestauracionCopiasConexionIntf;

type
  EConexionBackupPrueba = class(Exception);

  TRepositorioRestauracionConexionPrueba = class(
    TInterfacedObject,
    IRepositorioRestauracionConexion)
  private
    FInvocado: Boolean;
    FSolicitud: TSolicitudRestauracionConexion;
  public
    procedure Iniciar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
    property Invocado: Boolean read FInvocado;
    property Solicitud: TSolicitudRestauracionConexion read FSolicitud;
  end;
  TPersistenciaConexionFallida = class(
    TInterfacedObject,
    IPersistenciaRestauracionBackup)
  public
    procedure PrepararDestino;
    procedure EjecutarSentencia(const ASentencia: string);
    procedure NormalizarBaseDatos;
    function ObtenerTablasConColacionNoValida: TArray<string>;
    procedure NormalizarTabla(const ANombreTabla: string);
    procedure ValidarEstructura;
  end;

procedure TPersistenciaConexionFallida.PrepararDestino;
begin
  raise EConexionBackupPrueba.Create('Servidor no disponible');
end;

procedure TPersistenciaConexionFallida.EjecutarSentencia(
  const ASentencia: string);
begin
end;

procedure TPersistenciaConexionFallida.NormalizarBaseDatos;
begin
end;

function TPersistenciaConexionFallida.
  ObtenerTablasConColacionNoValida: TArray<string>;
begin
  Result := nil;
end;

procedure TPersistenciaConexionFallida.NormalizarTabla(
  const ANombreTabla: string);
begin
end;

procedure TPersistenciaConexionFallida.ValidarEstructura;
begin
end;

procedure TRepositorioRestauracionConexionPrueba.Iniciar(
  const ASolicitud: TSolicitudRestauracionConexion;
  AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent);
begin
  FInvocado := True;
  FSolicitud := ASolicitud;
end;

function CrearSolicitudValida: TSolicitudRestauracionConexion;
begin
  Result := Default(TSolicitudRestauracionConexion);
  Result.Host := 'localhost';
  Result.Puerto := 3306;
  Result.BaseDatos := 'factuzam';
  Result.Usuario := 'root';
  Result.ContrasenaConexion := 'clave';
  Result.RutaFichero := 'copia.crypt';
  Result.ContrasenaCopia := 'clave';
end;

procedure TPruebasRestauracionCopiasConexion.
  Ejecutar_EntregaSolicitudAlRepositorio;
var
  oCasoUso: ICasoUsoRestauracionConexion;
  oRepositorio: TRepositorioRestauracionConexionPrueba;
  oSolicitud: TSolicitudRestauracionConexion;
begin
  oRepositorio := TRepositorioRestauracionConexionPrueba.Create;
  oCasoUso := CrearCasoUsoRestauracionConexion(oRepositorio);
  oSolicitud := CrearSolicitudValida;
  oCasoUso.Ejecutar(oSolicitud, nil, nil, nil);
  Assert.IsTrue(oRepositorio.Invocado);
  Assert.AreEqual('localhost', oRepositorio.Solicitud.Host);
  Assert.AreEqual(3306, oRepositorio.Solicitud.Puerto);
  Assert.AreEqual('factuzam', oRepositorio.Solicitud.BaseDatos);
  Assert.AreEqual('copia.crypt', oRepositorio.Solicitud.RutaFichero);
end;

procedure TPruebasRestauracionCopiasConexion.
  Ejecutar_SinRutaNoInvocaRepositorio;
var
  bExcepcionCapturada: Boolean;
  oCasoUso: ICasoUsoRestauracionConexion;
  oRepositorio: TRepositorioRestauracionConexionPrueba;
  oSolicitud: TSolicitudRestauracionConexion;
begin
  oRepositorio := TRepositorioRestauracionConexionPrueba.Create;
  oCasoUso := CrearCasoUsoRestauracionConexion(oRepositorio);
  oSolicitud := CrearSolicitudValida;
  oSolicitud.RutaFichero := '';
  bExcepcionCapturada := False;
  try
    oCasoUso.Ejecutar(oSolicitud, nil, nil, nil);
  except
    on E: EArgumentException do
      bExcepcionCapturada := True;
  end;
  Assert.IsTrue(bExcepcionCapturada);
  Assert.IsFalse(oRepositorio.Invocado);
end;

procedure TPruebasRestauracionCopiasConexion.
  Streaming_ErrorConexionSePropaga;
var
  bExcepcionCapturada: Boolean;
  oEjecutor: TEjecutorRestauracionSQL;
  oFlujo: TStringStream;
  oLog: TStringList;
  oPersistencia: IPersistenciaRestauracionBackup;
begin
  oPersistencia := TPersistenciaConexionFallida.Create;
  oFlujo := TStringStream.Create(
    'CREATE TABLE TABLA (ID INTEGER);',
    TEncoding.UTF8);
  try
    oLog := TStringList.Create;
    try
      oEjecutor := TEjecutorRestauracionSQL.Create(
        oPersistencia,
        nil,
        nil,
        oLog);
      try
        bExcepcionCapturada := False;
        try
          oEjecutor.Ejecutar(oFlujo);
        except
          on E: EConexionBackupPrueba do
            bExcepcionCapturada := True;
        end;
        Assert.IsTrue(bExcepcionCapturada);
      finally
        FreeAndNil(oEjecutor);
      end;
    finally
      FreeAndNil(oLog);
    end;
  finally
    FreeAndNil(oFlujo);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasRestauracionCopiasConexion);

end.
