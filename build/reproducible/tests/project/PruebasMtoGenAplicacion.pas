{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasMtoGenAplicacion                                       }
{    Tipo:       Pruebas DUnitX                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza el guardado y el contrato de hooks de TfrmMtoGen.            }
{******************************************************************************}
unit PruebasMtoGenAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasMtoGenAplicacion = class
  public
    [Test]
    procedure GuardadoCorrecto_ConfirmaTransaccionPropia;
    [Test]
    procedure GuardadoAbortado_RevierteSinPropagar;
    [Test]
    procedure GuardadoConError_RevierteYPropaga;
    [Test]
    procedure GuardadoConTransaccionExterna_NoLaAdministra;
    [Test]
    procedure HooksHerencia_BateriaCompartidaCompleta;
  end;

implementation

uses
  System.SysUtils,
  inLibContratoMtoGenHerencia,
  inLibMtoGenAplicacion,
  inLibMtoGenAplicacionIntf;

type
  EErrorGuardadoSimulado = class(Exception);

  TUnidadTrabajoMtoGenFalsa = class(
    TInterfacedObject,
    IUnidadTrabajoMtoGen)
  private
    FActiva: Boolean;
    FInicios: Integer;
    FConfirmaciones: Integer;
    FReversiones: Integer;
  public
    constructor Create(AActiva: Boolean);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
    property Inicios: Integer read FInicios;
    property Confirmaciones: Integer read FConfirmaciones;
    property Reversiones: Integer read FReversiones;
  end;

constructor TUnidadTrabajoMtoGenFalsa.Create(AActiva: Boolean);
begin
  inherited Create;
  FActiva := AActiva;
end;

function TUnidadTrabajoMtoGenFalsa.EstaActiva: Boolean;
begin
  Result := FActiva;
end;

procedure TUnidadTrabajoMtoGenFalsa.Iniciar;
begin
  Inc(FInicios);
  FActiva := True;
end;

procedure TUnidadTrabajoMtoGenFalsa.Confirmar;
begin
  Inc(FConfirmaciones);
  FActiva := False;
end;

procedure TUnidadTrabajoMtoGenFalsa.Revertir;
begin
  Inc(FReversiones);
  FActiva := False;
end;

procedure TPruebasMtoGenAplicacion.
  GuardadoCorrecto_ConfirmaTransaccionPropia;
var
  oUnidad: TUnidadTrabajoMtoGenFalsa;
  oCasoUso: ICasoUsoGuardadoMtoGen;
  Resultado: TResultadoGuardadoMtoGen;
  iLlamadas: Integer;
begin
  oUnidad := TUnidadTrabajoMtoGenFalsa.Create(False);
  oCasoUso := CrearCasoUsoGuardadoMtoGen(oUnidad);
  iLlamadas := 0;
  Resultado := oCasoUso.Ejecutar(
    procedure
    begin
      Inc(iLlamadas);
    end);
  Assert.AreEqual(Ord(rgmGuardado), Ord(Resultado));
  Assert.AreEqual(1, iLlamadas);
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(1, oUnidad.Confirmaciones);
  Assert.AreEqual(0, oUnidad.Reversiones);
end;

procedure TPruebasMtoGenAplicacion.GuardadoAbortado_RevierteSinPropagar;
var
  oUnidad: TUnidadTrabajoMtoGenFalsa;
  oCasoUso: ICasoUsoGuardadoMtoGen;
  Resultado: TResultadoGuardadoMtoGen;
begin
  oUnidad := TUnidadTrabajoMtoGenFalsa.Create(False);
  oCasoUso := CrearCasoUsoGuardadoMtoGen(oUnidad);
  Resultado := oCasoUso.Ejecutar(
    procedure
    begin
      Abort;
    end);
  Assert.AreEqual(Ord(rgmAbortado), Ord(Resultado));
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(1, oUnidad.Reversiones);
end;

procedure TPruebasMtoGenAplicacion.GuardadoConError_RevierteYPropaga;
var
  oUnidad: TUnidadTrabajoMtoGenFalsa;
  oCasoUso: ICasoUsoGuardadoMtoGen;
begin
  oUnidad := TUnidadTrabajoMtoGenFalsa.Create(False);
  oCasoUso := CrearCasoUsoGuardadoMtoGen(oUnidad);
  Assert.WillRaise(
    procedure
    begin
      oCasoUso.Ejecutar(
        procedure
        begin
          raise EErrorGuardadoSimulado.Create('Error simulado');
        end);
    end,
    EErrorGuardadoSimulado);
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(1, oUnidad.Reversiones);
end;

procedure TPruebasMtoGenAplicacion.
  GuardadoConTransaccionExterna_NoLaAdministra;
var
  oUnidad: TUnidadTrabajoMtoGenFalsa;
  oCasoUso: ICasoUsoGuardadoMtoGen;
  Resultado: TResultadoGuardadoMtoGen;
begin
  oUnidad := TUnidadTrabajoMtoGenFalsa.Create(True);
  oCasoUso := CrearCasoUsoGuardadoMtoGen(oUnidad);
  Resultado := oCasoUso.Ejecutar(
    procedure
    begin
    end);
  Assert.AreEqual(Ord(rgmGuardado), Ord(Resultado));
  Assert.AreEqual(0, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(0, oUnidad.Reversiones);
end;

procedure TPruebasMtoGenAplicacion.
  HooksHerencia_BateriaCompartidaCompleta;
var
  Contrato: TContratoHookMtoGen;
  Familia: TFamiliaHookMtoGen;
  FamiliasCubiertas: set of TFamiliaHookMtoGen;
  Hook: THookMtoGen;
begin
  FamiliasCubiertas := [];
  for Hook := Low(THookMtoGen) to High(THookMtoGen) do
  begin
    Contrato := ContratoHookMtoGen(Hook);
    Familia := FamiliaHookMtoGen(Hook);
    Include(FamiliasCubiertas, Familia);
    Assert.IsNotEmpty(Contrato.Nombre);
    Assert.AreEqual(
      Ord(OrdenFamiliaHookMtoGen(Familia)),
      Ord(Contrato.OrdenInherited));
    Assert.IsTrue(Contrato.SeEjecutaEnHiloPrincipal);
  end;
  Assert.IsTrue(
    FamiliasCubiertas = [Low(TFamiliaHookMtoGen)..
      High(TFamiliaHookMtoGen)]);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasMtoGenAplicacion);

end.
