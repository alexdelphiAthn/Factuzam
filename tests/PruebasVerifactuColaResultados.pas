{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasVerifactuColaResultados                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza resultados y estados de la cola Verifactu sin BBDD.           }
{******************************************************************************}
unit PruebasVerifactuColaResultados;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasVerifactuColaResultados = class
  public
    [Test]
    procedure Alta_CreaEstadoProcesado;
    [Test]
    procedure AceptadoConErrores_ConservaAvisoComoEstado;
    [Test]
    procedure Anulacion_CreaPlanDeAnulacion;
    [Test]
    procedure Subsanacion_CreaPlanDeSubsanacion;
    [Test]
    procedure Duplicado_CreaEstadoDuplicado;
    [Test]
    procedure GuardadoOk_RespetaElOrdenAtomico;
    [Test]
    procedure GuardadoOk_RepetidoEsIdempotente;
    [Test]
    procedure ErrorParcial_ResultadoNoMarcaFacturaNiCola;
    [Test]
    procedure ErrorParcial_FacturaNoMarcaCola;
    [Test]
    procedure ErrorReintentable_ConservaEstadoPendiente;
    [Test]
    procedure ErrorFinal_MarcaFacturaFiscal;
    [Test]
    procedure DependenciaAusente_FallaTemprano;
  end;

implementation

uses
  System.SysUtils, System.Classes, inLibVerifactu,
  UniDataVerifactuResultadosEnvioOperacion;

type
  TPersistenciaResultadosFalsa = class(
    TInterfacedObject,
    IPersistenciaResultadoEnvioVerifactu)
  private
    FOrden: TStrings;
  public
    ActualizacionesCadena: Integer;
    FallarResultado: Boolean;
    ResultadosGuardados: Integer;
    constructor Create(AOrden: TStrings);
    procedure ActualizarCadena(
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure GuardarResultado(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
  end;
  TPersistenciaEstadosFalsa = class(
    TInterfacedObject,
    IPersistenciaEstadoEnvioVerifactu)
  private
    FOrden: TStrings;
  public
    ActualizacionesFactura: Integer;
    ColaEnviada: Boolean;
    ConsultasEstado: Integer;
    ErroresGuardados: Integer;
    FallarFactura: Boolean;
    MarcasCola: Integer;
    UltimoPlanError: TPlanErrorEnvioVerifactu;
    constructor Create(AOrden: TStrings);
    function EstaColaEnviada(AIdCola: Int64): Boolean;
    procedure ActualizarFactura(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure MarcarColaEnviada(
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure GuardarError(
      const AEntrada: TEntradaErrorEnvioVerifactu;
      const APlan: TPlanErrorEnvioVerifactu);
  end;

function CrearEntradaResultado(
  const ATipoOperacion: string;
  const AEstadoRegistro: string): TEntradaResultadoEnvioVerifactu;
begin
  Result := Default(TEntradaResultadoEnvioVerifactu);
  Result.IdCola := 42;
  Result.Serie := 'F';
  Result.Numero := '7';
  Result.TipoOperacion := ATipoOperacion;
  Result.Usuario := 'PRUEBAS';
  Result.Resultado.EstadoRegistro := AEstadoRegistro;
end;

function CrearEntradaError(
  AIntentos: Integer;
  AMaximoIntentos: Integer): TEntradaErrorEnvioVerifactu;
begin
  Result := Default(TEntradaErrorEnvioVerifactu);
  Result.IdCola := 42;
  Result.Serie := 'F';
  Result.Numero := '7';
  Result.Mensaje := 'Fallo simulado';
  Result.Usuario := 'PRUEBAS';
  Result.Intentos := AIntentos;
  Result.MaximoIntentos := AMaximoIntentos;
end;

function CrearOperacionFalsa(
  AOrden: TStrings;
  out AResultados: TPersistenciaResultadosFalsa;
  out AEstados: TPersistenciaEstadosFalsa):
  TOperacionResultadosEnvioVerifactu;
var
  oContratoEstados: IPersistenciaEstadoEnvioVerifactu;
  oContratoResultados: IPersistenciaResultadoEnvioVerifactu;
begin
  AResultados := TPersistenciaResultadosFalsa.Create(AOrden);
  AEstados := TPersistenciaEstadosFalsa.Create(AOrden);
  oContratoResultados := AResultados;
  oContratoEstados := AEstados;
  Result := TOperacionResultadosEnvioVerifactu.Create(
    oContratoResultados,
    oContratoEstados);
end;

constructor TPersistenciaResultadosFalsa.Create(AOrden: TStrings);
begin
  inherited Create;
  FOrden := AOrden;
end;

procedure TPersistenciaResultadosFalsa.ActualizarCadena(
  const AEntrada: TEntradaResultadoEnvioVerifactu);
begin
  Inc(ActualizacionesCadena);
  FOrden.Add('cadena');
end;

procedure TPersistenciaResultadosFalsa.GuardarResultado(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
begin
  Inc(ResultadosGuardados);
  FOrden.Add('resultado');
  if FallarResultado then
    raise EInvalidOpException.Create('Fallo de resultado simulado');
end;

constructor TPersistenciaEstadosFalsa.Create(AOrden: TStrings);
begin
  inherited Create;
  FOrden := AOrden;
end;

function TPersistenciaEstadosFalsa.EstaColaEnviada(
  AIdCola: Int64): Boolean;
begin
  Inc(ConsultasEstado);
  Result := ColaEnviada;
end;

procedure TPersistenciaEstadosFalsa.ActualizarFactura(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
begin
  Inc(ActualizacionesFactura);
  FOrden.Add('factura');
  if FallarFactura then
    raise EInvalidOpException.Create('Fallo de factura simulado');
end;

procedure TPersistenciaEstadosFalsa.MarcarColaEnviada(
  const AEntrada: TEntradaResultadoEnvioVerifactu);
begin
  Inc(MarcasCola);
  FOrden.Add('cola');
  ColaEnviada := True;
end;

procedure TPersistenciaEstadosFalsa.GuardarError(
  const AEntrada: TEntradaErrorEnvioVerifactu;
  const APlan: TPlanErrorEnvioVerifactu);
begin
  Inc(ErroresGuardados);
  UltimoPlanError := APlan;
  FOrden.Add('error');
end;

procedure TPruebasVerifactuColaResultados.Alta_CreaEstadoProcesado;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oPlan: TPlanResultadoEnvioVerifactu;
begin
  oEntrada := CrearEntradaResultado('ALTA', 'Correcto');
  oPlan := CrearPlanResultadoEnvioVerifactu(oEntrada);
  Assert.AreEqual(Integer(trevAlta), Integer(oPlan.TipoResultado));
  Assert.AreEqual(cFaseFacturaVerifactuOk, oPlan.FaseFactura);
  Assert.AreEqual('VERIFACTU_PROCESADO', oPlan.EstadoConsolidacion);
end;

procedure TPruebasVerifactuColaResultados.
  AceptadoConErrores_ConservaAvisoComoEstado;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oPlan: TPlanResultadoEnvioVerifactu;
begin
  oEntrada := CrearEntradaResultado('SUBSANACION',
    'AceptadoConErrores');
  oPlan := CrearPlanResultadoEnvioVerifactu(oEntrada);
  Assert.AreEqual('VERIFACTU_ACEPT_ERR', oPlan.EstadoConsolidacion);
end;

procedure TPruebasVerifactuColaResultados.Anulacion_CreaPlanDeAnulacion;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oPlan: TPlanResultadoEnvioVerifactu;
begin
  oEntrada := CrearEntradaResultado('ANULACION', 'Correcto');
  oPlan := CrearPlanResultadoEnvioVerifactu(oEntrada);
  Assert.AreEqual(Integer(trevAnulacion), Integer(oPlan.TipoResultado));
  Assert.AreEqual(cFaseFacturaVerifactuAnulada, oPlan.FaseFactura);
end;

procedure TPruebasVerifactuColaResultados.
  Subsanacion_CreaPlanDeSubsanacion;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oPlan: TPlanResultadoEnvioVerifactu;
begin
  oEntrada := CrearEntradaResultado('SUBSANACION', 'Correcto');
  oPlan := CrearPlanResultadoEnvioVerifactu(oEntrada);
  Assert.AreEqual(Integer(trevSubsanacion),
    Integer(oPlan.TipoResultado));
  Assert.AreEqual('VERIFACTU_SUBSANADO', oPlan.EstadoConsolidacion);
end;

procedure TPruebasVerifactuColaResultados.Duplicado_CreaEstadoDuplicado;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oPlan: TPlanResultadoEnvioVerifactu;
begin
  oEntrada := CrearEntradaResultado('ALTA', 'Duplicado');
  oPlan := CrearPlanResultadoEnvioVerifactu(oEntrada);
  Assert.AreEqual('VERIFACTU_DUPLICADO', oPlan.EstadoConsolidacion);
end;

procedure TPruebasVerifactuColaResultados.GuardadoOk_RespetaElOrdenAtomico;
var
  bAplicado: Boolean;
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oEstados: TPersistenciaEstadosFalsa;
  oOperacion: TOperacionResultadosEnvioVerifactu;
  oOrden: TStringList;
  oResultados: TPersistenciaResultadosFalsa;
begin
  oOrden := TStringList.Create;
  try
    oOperacion := CrearOperacionFalsa(
      oOrden,
      oResultados,
      oEstados);
    try
      oEntrada := CrearEntradaResultado('ALTA', 'Correcto');
      bAplicado := oOperacion.GuardarEnvioOk(oEntrada);
      Assert.IsTrue(bAplicado);
      Assert.AreEqual('cadena,resultado,factura,cola', oOrden.CommaText);
      Assert.AreEqual(1, oResultados.ResultadosGuardados);
      Assert.AreEqual(1, oEstados.MarcasCola);
    finally
      FreeAndNil(oOperacion);
    end;
  finally
    FreeAndNil(oOrden);
  end;
end;

procedure TPruebasVerifactuColaResultados.
  GuardadoOk_RepetidoEsIdempotente;
var
  bPrimero: Boolean;
  bSegundo: Boolean;
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oEstados: TPersistenciaEstadosFalsa;
  oOperacion: TOperacionResultadosEnvioVerifactu;
  oOrden: TStringList;
  oResultados: TPersistenciaResultadosFalsa;
begin
  oOrden := TStringList.Create;
  try
    oOperacion := CrearOperacionFalsa(
      oOrden,
      oResultados,
      oEstados);
    try
      oEntrada := CrearEntradaResultado('ALTA', 'Correcto');
      bPrimero := oOperacion.GuardarEnvioOk(oEntrada);
      bSegundo := oOperacion.GuardarEnvioOk(oEntrada);
      Assert.IsTrue(bPrimero);
      Assert.IsFalse(bSegundo);
      Assert.AreEqual(1, oResultados.ResultadosGuardados);
      Assert.AreEqual(1, oEstados.MarcasCola);
      Assert.AreEqual(2, oEstados.ConsultasEstado);
    finally
      FreeAndNil(oOperacion);
    end;
  finally
    FreeAndNil(oOrden);
  end;
end;

procedure TPruebasVerifactuColaResultados.
  ErrorParcial_ResultadoNoMarcaFacturaNiCola;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oEstados: TPersistenciaEstadosFalsa;
  oOperacion: TOperacionResultadosEnvioVerifactu;
  oOrden: TStringList;
  oResultados: TPersistenciaResultadosFalsa;
begin
  oOrden := TStringList.Create;
  try
    oOperacion := CrearOperacionFalsa(
      oOrden,
      oResultados,
      oEstados);
    try
      oResultados.FallarResultado := True;
      oEntrada := CrearEntradaResultado('ALTA', 'Correcto');
      Assert.WillRaise(
        procedure
        begin
          oOperacion.GuardarEnvioOk(oEntrada);
        end,
        EInvalidOpException);
      Assert.AreEqual(0, oEstados.ActualizacionesFactura);
      Assert.AreEqual(0, oEstados.MarcasCola);
    finally
      FreeAndNil(oOperacion);
    end;
  finally
    FreeAndNil(oOrden);
  end;
end;

procedure TPruebasVerifactuColaResultados.
  ErrorParcial_FacturaNoMarcaCola;
var
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oEstados: TPersistenciaEstadosFalsa;
  oOperacion: TOperacionResultadosEnvioVerifactu;
  oOrden: TStringList;
  oResultados: TPersistenciaResultadosFalsa;
begin
  oOrden := TStringList.Create;
  try
    oOperacion := CrearOperacionFalsa(
      oOrden,
      oResultados,
      oEstados);
    try
      oEstados.FallarFactura := True;
      oEntrada := CrearEntradaResultado('ALTA', 'Correcto');
      Assert.WillRaise(
        procedure
        begin
          oOperacion.GuardarEnvioOk(oEntrada);
        end,
        EInvalidOpException);
      Assert.AreEqual(1, oResultados.ResultadosGuardados);
      Assert.AreEqual(0, oEstados.MarcasCola);
    finally
      FreeAndNil(oOperacion);
    end;
  finally
    FreeAndNil(oOrden);
  end;
end;

procedure TPruebasVerifactuColaResultados.
  ErrorReintentable_ConservaEstadoPendiente;
var
  oEntrada: TEntradaErrorEnvioVerifactu;
  oEstados: TPersistenciaEstadosFalsa;
  oOperacion: TOperacionResultadosEnvioVerifactu;
  oOrden: TStringList;
  oResultados: TPersistenciaResultadosFalsa;
begin
  oOrden := TStringList.Create;
  try
    oOperacion := CrearOperacionFalsa(
      oOrden,
      oResultados,
      oEstados);
    try
      oEntrada := CrearEntradaError(2, 5);
      oOperacion.GuardarEnvioError(oEntrada);
      Assert.AreEqual('PENDIENTE', oEstados.UltimoPlanError.EstadoCola);
      Assert.AreEqual(240, oEstados.UltimoPlanError.EsperaSegundos);
      Assert.IsFalse(oEstados.UltimoPlanError.ActualizarFactura);
      Assert.AreEqual(0, oResultados.ActualizacionesCadena);
    finally
      FreeAndNil(oOperacion);
    end;
  finally
    FreeAndNil(oOrden);
  end;
end;

procedure TPruebasVerifactuColaResultados.ErrorFinal_MarcaFacturaFiscal;
var
  oEntrada: TEntradaErrorEnvioVerifactu;
  oEstados: TPersistenciaEstadosFalsa;
  oOperacion: TOperacionResultadosEnvioVerifactu;
  oOrden: TStringList;
  oResultados: TPersistenciaResultadosFalsa;
begin
  oOrden := TStringList.Create;
  try
    oOperacion := CrearOperacionFalsa(
      oOrden,
      oResultados,
      oEstados);
    try
      oEntrada := CrearEntradaError(4, 5);
      oOperacion.GuardarEnvioError(oEntrada);
      Assert.AreEqual('ERROR', oEstados.UltimoPlanError.EstadoCola);
      Assert.IsTrue(oEstados.UltimoPlanError.ActualizarFactura);
      Assert.AreEqual(1, oEstados.ErroresGuardados);
      Assert.AreEqual(0, oResultados.ActualizacionesCadena);
    finally
      FreeAndNil(oOperacion);
    end;
  finally
    FreeAndNil(oOrden);
  end;
end;

procedure TPruebasVerifactuColaResultados.
  DependenciaAusente_FallaTemprano;
begin
  Assert.WillRaise(
    procedure
    begin
      TOperacionResultadosEnvioVerifactu.Create(nil, nil);
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasVerifactuColaResultados);

end.
