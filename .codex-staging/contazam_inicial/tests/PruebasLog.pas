{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasLog                                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verifica escritura UTF-8, errores y rotación del registro local.          }
{******************************************************************************}
unit PruebasLog;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasLog = class
  public
    [Test]
    procedure EscribeInformacionYExcepcion;
    [Test]
    procedure ArchivaLosLogsQueSuperanLaRetencion;
    [Test]
    procedure CarpetaPredeterminadaEstaEnLocalAppData;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, inLibDir, inLibLogIntf, inLibLog;

function CrearCarpetaTemporalLog: string;
var
  oIdentificador: TGUID;
begin
  CreateGUID(oIdentificador);
  Result := TPath.Combine(
    TPath.GetTempPath,
    'contazam_log_' + GUIDToString(oIdentificador));
  TDirectory.CreateDirectory(Result);
end;

procedure TPruebasLog.ArchivaLosLogsQueSuperanLaRetencion;
var
  aLogs: TArray<string>;
  aZips: TArray<string>;
  oRegistro: IRegistroLogContazam;
  sCarpeta: string;
  sCarpetaArchivo: string;
begin
  sCarpeta := CrearCarpetaTemporalLog;
  sCarpetaArchivo := TPath.Combine(sCarpeta, 'archive');
  try
    TFile.WriteAllText(
      TPath.Combine(sCarpeta, 'LOG_2020_01_01_000001_{1}.log'),
      'uno');
    TFile.WriteAllText(
      TPath.Combine(sCarpeta, 'LOG_2020_01_01_000002_{2}.log'),
      'dos');
    TFile.WriteAllText(
      TPath.Combine(sCarpeta, 'LOG_2020_01_01_000003_{3}.log'),
      'tres');
    oRegistro := CrearRegistroLogContazam(sCarpeta, 2);
    oRegistro := nil;
    aLogs := TDirectory.GetFiles(sCarpeta, 'LOG_*.log');
    aZips := TDirectory.GetFiles(
      sCarpetaArchivo,
      '*.zip',
      TSearchOption.soAllDirectories);
    Assert.AreEqual(2, Length(aLogs));
    Assert.IsTrue(Length(aZips) > 0);
  finally
    if TDirectory.Exists(sCarpeta) and
      sCarpeta.StartsWith(TPath.GetTempPath, True) then
    begin
      TDirectory.Delete(sCarpeta, True);
    end;
  end;
end;

procedure TPruebasLog.EscribeInformacionYExcepcion;
var
  oError: Exception;
  oRegistro: IRegistroLogContazam;
  sArchivo: string;
  sCarpeta: string;
  sContenido: string;
begin
  sCarpeta := CrearCarpetaTemporalLog;
  try
    oRegistro := CrearRegistroLogContazam(sCarpeta, 3);
    sArchivo := oRegistro.RutaArchivo;
    oRegistro.RegistrarInformacion('Información con acento.');
    oError := EInvalidOpException.Create('Fallo de prueba.');
    try
      oRegistro.RegistrarExcepcion('Prueba controlada', oError);
    finally
      FreeAndNil(oError);
    end;
    oRegistro := nil;
    sContenido := TFile.ReadAllText(sArchivo, TEncoding.UTF8);
    Assert.IsTrue(Pos('INFO: Información con acento.', sContenido) > 0);
    Assert.IsTrue(Pos('EInvalidOpException', sContenido) > 0);
    Assert.IsTrue(Pos('Fin de sesión de log.', sContenido) > 0);
  finally
    if TDirectory.Exists(sCarpeta) and
      sCarpeta.StartsWith(TPath.GetTempPath, True) then
    begin
      TDirectory.Delete(sCarpeta, True);
    end;
  end;
end;

procedure TPruebasLog.CarpetaPredeterminadaEstaEnLocalAppData;
var
  sEsperada: string;
begin
  sEsperada := TPath.Combine(
    GetEnvironmentVariable('LOCALAPPDATA'),
    'Contazam');
  sEsperada := TPath.Combine(sEsperada, 'log');
  Assert.IsTrue(SameText(sEsperada, GetLogFolder));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasLog);

end.
