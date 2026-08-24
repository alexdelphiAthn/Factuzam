{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaResultados                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia UniDAC de resultados, consolidación y reintentos Verifactu.  }
{******************************************************************************}
unit UniDataVerifactuColaResultados;

interface

uses
  Uni, inLibParametrosIntf, inLibVerifactuEnvio, inLibLogIntf;
type
  TResultadosVerifactuColaUniDAC = class
  public
    class procedure GuardarEnvioOk(
      AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja; const AUsuario: string;
      AIdCola: Int64; const ASerie, ANumero, ATipoOperacion: string;
      const AResultado: TResultadoEnvioVerifactu;
      const ARegistroLog: IRegistroLog); static;
    class procedure GuardarEnvioError(
      AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja; const AUsuario: string;
      AIdCola: Int64; const ASerie, ANumero, AMensaje: string;
      AIntentos: Integer;
      const ARegistroLog: IRegistroLog;
      ANoConsumirIntento: Boolean = False;
      AEsperaSinIntentoSegundos: Integer = 0); static;
  end;
implementation
uses
  System.SysUtils, inLibVerifactu, inLibVentasWsCola,
  UniDataVentasWsCola, UniDataVerifactuResultadosEnvioOperacion,
  UniDataVerifactuResultadosEnvioPersistencia;

class procedure TResultadosVerifactuColaUniDAC.GuardarEnvioOk(
  AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja; const AUsuario: string;
  AIdCola: Int64; const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu;
  const ARegistroLog: IRegistroLog);
var
  bAplicado: Boolean;
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oOperacion: TOperacionResultadosEnvioVerifactu;
begin
  oEntrada := Default(TEntradaResultadoEnvioVerifactu);
  oEntrada.IdCola := AIdCola;
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.TipoOperacion := ATipoOperacion;
  oEntrada.Usuario := AUsuario;
  oEntrada.Resultado := AResultado;
  oOperacion := CrearOperacionResultadosEnvioVerifactuUniDAC(AConexion);
  try
    bAplicado := oOperacion.GuardarEnvioOk(oEntrada);
  finally
    FreeAndNil(oOperacion);
  end;
  if bAplicado then
  begin
    RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
      cEventoVerifactuEnvioOk,
      'Registro de facturación (' + ATipoOperacion + ') aceptado por la ' +
      'AEAT (' + AResultado.EstadoRegistro + ')',
      'CSV: ' + AResultado.RequestId, ASerie, ANumero);
    TVentasWsCola.RegistrarEventoSeguro(
      AParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(AConexion),
      AUsuario,
      'FISCAL_ACTUALIZADO', ASerie, ANumero, ARegistroLog);
  end;
end;

class procedure TResultadosVerifactuColaUniDAC.GuardarEnvioError(
  AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja; const AUsuario: string;
  AIdCola: Int64; const ASerie, ANumero, AMensaje: string;
  AIntentos: Integer;
  const ARegistroLog: IRegistroLog;
  ANoConsumirIntento: Boolean;
  AEsperaSinIntentoSegundos: Integer);
var
  oEntrada: TEntradaErrorEnvioVerifactu;
  oOperacion: TOperacionResultadosEnvioVerifactu;
begin
  oEntrada := Default(TEntradaErrorEnvioVerifactu);
  oEntrada.IdCola := AIdCola;
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.Mensaje := AMensaje;
  oEntrada.Usuario := AUsuario;
  oEntrada.Intentos := AIntentos;
  oEntrada.MaximoIntentos := AParametrosApp.GetInt(
    'appVerifactuMaxIntentos',
    10);
  oEntrada.NoConsumirIntento := ANoConsumirIntento;
  oEntrada.EsperaSinIntentoSegundos := AEsperaSinIntentoSegundos;
  oOperacion := CrearOperacionResultadosEnvioVerifactuUniDAC(AConexion);
  try
    oOperacion.GuardarEnvioError(oEntrada);
  finally
    FreeAndNil(oOperacion);
  end;
  if ANoConsumirIntento then
    RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
      cEventoVerifactuInfo,
      'Envío Verifactu aplazado por falta de conexión; ' +
      'el intento no se contabiliza: ' + AMensaje,
      '', ASerie, ANumero)
  else
  begin
    RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
      cEventoVerifactuEnvioError,
      'Error de envío Verifactu (intento ' + IntToStr(AIntentos + 1) +
      '): ' + AMensaje, '', ASerie, ANumero);
    TVentasWsCola.RegistrarEventoSeguro(
      AParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(AConexion),
      AUsuario,
      'FISCAL_ACTUALIZADO', ASerie, ANumero, ARegistroLog);
  end;
end;
end.
