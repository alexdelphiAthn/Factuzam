{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFusionEfectos                                         }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la frontera del caso de uso de fusión de efectos.                }
{******************************************************************************}
unit PruebasFusionEfectos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFusionEfectos = class
  public
    [Test]
    procedure Ejecutar_EntregaClavesYDevuelveResultado;
    [Test]
    procedure Ejecutar_UnaClaveNoInvocaRepositorio;
    [Test]
    procedure Validar_ResumenCorrectoEsValido;
    [Test]
    procedure Validar_CantidadDistintaRechazaLaFusion;
    [Test]
    procedure CrearReferencia_UsaElDestinoCalculado;
  end;

implementation

uses
  System.SysUtils,
  inLibEfectosCalculo,
  inLibFusionEfectos,
  inLibFusionEfectosIntf;

type
  TRepositorioFusionEfectosPrueba = class(
    TInterfacedObject,
    IRepositorioFusionEfectos)
  private
    FInvocado: Boolean;
    FClaves: TClavesFusionEfectos;
    FResultado: TResultadoFusionEfectos;
  public
    function Fusionar(
      const AClaves: TClavesFusionEfectos
    ): TResultadoFusionEfectos;
    property Invocado: Boolean read FInvocado;
    property Claves: TClavesFusionEfectos read FClaves;
    property Resultado: TResultadoFusionEfectos
      read FResultado write FResultado;
  end;

function TRepositorioFusionEfectosPrueba.Fusionar(
  const AClaves: TClavesFusionEfectos
): TResultadoFusionEfectos;
begin
  FInvocado := True;
  FClaves := Copy(AClaves);
  Result := FResultado;
end;

function CrearDosClaves: TClavesFusionEfectos;
begin
  SetLength(Result, 2);
  Result[0].SerieFactura := 'F';
  Result[0].NumeroFactura := '1';
  Result[0].NumeroEfecto := 1;
  Result[1].SerieFactura := 'F';
  Result[1].NumeroFactura := '2';
  Result[1].NumeroEfecto := 1;
end;

procedure TPruebasFusionEfectos.
  Ejecutar_EntregaClavesYDevuelveResultado;
var
  oCasoUso: ICasoUsoFusionEfectos;
  oRepositorio: TRepositorioFusionEfectosPrueba;
  oResultadoEsperado: TResultadoFusionEfectos;
  oResultado: TResultadoFusionEfectos;
begin
  oRepositorio := TRepositorioFusionEfectosPrueba.Create;
  oResultadoEsperado := Default(TResultadoFusionEfectos);
  oResultadoEsperado.Cantidad := 2;
  oResultadoEsperado.Referencia := 'CONC F/1/3';
  oRepositorio.Resultado := oResultadoEsperado;
  oCasoUso := CrearCasoUsoFusionEfectos(oRepositorio);
  oResultado := oCasoUso.Ejecutar(CrearDosClaves);
  Assert.IsTrue(oRepositorio.Invocado);
  Assert.AreEqual(2, Integer(Length(oRepositorio.Claves)));
  Assert.AreEqual('F', oRepositorio.Claves[0].SerieFactura);
  Assert.AreEqual('2', oRepositorio.Claves[1].NumeroFactura);
  Assert.AreEqual(2, oResultado.Cantidad);
  Assert.AreEqual('CONC F/1/3', oResultado.Referencia);
end;

procedure TPruebasFusionEfectos.
  Ejecutar_UnaClaveNoInvocaRepositorio;
var
  aClaves: TClavesFusionEfectos;
  bExcepcionCapturada: Boolean;
  oCasoUso: ICasoUsoFusionEfectos;
  oRepositorio: TRepositorioFusionEfectosPrueba;
begin
  oRepositorio := TRepositorioFusionEfectosPrueba.Create;
  oCasoUso := CrearCasoUsoFusionEfectos(oRepositorio);
  SetLength(aClaves, 1);
  bExcepcionCapturada := False;
  try
    oCasoUso.Ejecutar(aClaves);
  except
    on E: EArgumentException do
      bExcepcionCapturada := True;
  end;
  Assert.IsTrue(bExcepcionCapturada);
  Assert.IsFalse(oRepositorio.Invocado);
end;

procedure TPruebasFusionEfectos.Validar_ResumenCorrectoEsValido;
var
  oResumen: TResumenFusionEfectos;
begin
  oResumen := Default(TResumenFusionEfectos);
  oResumen.CantidadValidos := 2;
  oResumen.CantidadEmpresas := 1;
  oResumen.CantidadTerceros := 1;
  oResumen.ImportePendiente := 25.50;
  Assert.AreEqual(
    Integer(efeValida),
    Integer(TCalculoFusionEfectos.Validar(oResumen, 2)));
end;

procedure TPruebasFusionEfectos.
  Validar_CantidadDistintaRechazaLaFusion;
var
  oResumen: TResumenFusionEfectos;
begin
  oResumen := Default(TResumenFusionEfectos);
  oResumen.CantidadValidos := 1;
  oResumen.CantidadEmpresas := 1;
  oResumen.CantidadTerceros := 1;
  oResumen.ImportePendiente := 25.50;
  Assert.AreEqual(
    Integer(efeCantidadInvalida),
    Integer(TCalculoFusionEfectos.Validar(oResumen, 2)));
end;

procedure TPruebasFusionEfectos.
  CrearReferencia_UsaElDestinoCalculado;
begin
  Assert.AreEqual(
    'CONC F/42/3',
    TCalculoFusionEfectos.CrearReferencia('F', '42', 3));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFusionEfectos);

end.
