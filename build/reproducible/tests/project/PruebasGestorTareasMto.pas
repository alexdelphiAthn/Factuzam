{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGestorTareasMto                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del gestor de tareas y overlay de mantenimientos.                 }
{******************************************************************************}
unit PruebasGestorTareasMto;

interface

uses
  Vcl.Forms, DUnitX.TestFramework, inLibGestorTareasMto;

type
  [TestFixture]
  TPruebasGestorTareasMto = class
  private
    FFormulario: TForm;
    FGestor: TGestorTareasMto;
    FCerrando: Boolean;
    function AplicacionCerrando: Boolean;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Bloqueo_ReentranteMantieneOverlay;
    [Test]
    procedure DesbloqueoExtra_NoDejaContadorNegativo;
    [Test]
    procedure CierreAplicacion_NoIniciaTrabajo;
    [Test]
    procedure Espera_FinalizaTareaActiva;
    [Test]
    procedure Destruccion_SuprimeTrabajoNuevo;
  end;

implementation

uses
  System.SysUtils, System.SyncObjs;

procedure TPruebasGestorTareasMto.Preparar;
begin
  FFormulario := TForm.CreateNew(nil);
  FFormulario.Name := 'frmPrueba';
  FFormulario.ClientWidth := 800;
  FFormulario.ClientHeight := 600;
  FCerrando := False;
  FGestor := TGestorTareasMto.Create(
    FFormulario, AplicacionCerrando);
end;

procedure TPruebasGestorTareasMto.Limpiar;
begin
  FreeAndNil(FGestor);
  FreeAndNil(FFormulario);
end;

function TPruebasGestorTareasMto.AplicacionCerrando: Boolean;
begin
  Result := FCerrando;
end;

procedure TPruebasGestorTareasMto.
  Bloqueo_ReentranteMantieneOverlay;
begin
  FGestor.Bloquear(True);
  Assert.IsTrue(Assigned(FGestor.Overlay));
  Assert.IsTrue(FGestor.Overlay.Visible);
  Assert.AreEqual(1, FGestor.Bloqueos);
  FGestor.Bloquear(True);
  Assert.AreEqual(2, FGestor.Bloqueos);
  FGestor.Bloquear(False);
  Assert.AreEqual(1, FGestor.Bloqueos);
  Assert.IsTrue(FGestor.Overlay.Visible);
  FGestor.Bloquear(False);
  Assert.AreEqual(0, FGestor.Bloqueos);
  Assert.IsFalse(FGestor.Overlay.Visible);
end;

procedure TPruebasGestorTareasMto.
  DesbloqueoExtra_NoDejaContadorNegativo;
begin
  FGestor.Bloquear(False);
  Assert.AreEqual(0, FGestor.Bloqueos);
  Assert.IsFalse(Assigned(FGestor.Overlay));
  FGestor.Bloquear(True);
  FGestor.Bloquear(False);
  FGestor.Bloquear(False);
  Assert.AreEqual(0, FGestor.Bloqueos);
  Assert.IsFalse(FGestor.Overlay.Visible);
end;

procedure TPruebasGestorTareasMto.
  CierreAplicacion_NoIniciaTrabajo;
var
  oEvento: TEvent;
begin
  oEvento := TEvent.Create(nil, True, False, '');
  try
    FCerrando := True;
    FGestor.Ejecutar(
      procedure
      begin
        oEvento.SetEvent;
      end,
      nil);
    Assert.AreEqual(0, FGestor.CantidadTareas);
    Assert.AreEqual(
      wrTimeout, oEvento.WaitFor(0));
    Assert.IsFalse(Assigned(FGestor.Overlay));
  finally
    FreeAndNil(oEvento);
  end;
end;

procedure TPruebasGestorTareasMto.
  Espera_FinalizaTareaActiva;
var
  oEvento: TEvent;
  bTareaViva: Boolean;
begin
  oEvento := TEvent.Create(nil, True, False, '');
  try
    FGestor.Ejecutar(
      procedure
      begin
        oEvento.SetEvent;
      end,
      nil);
    bTareaViva := FGestor.EsperarFinalizacion(
      nil, False);
    Assert.IsFalse(bTareaViva);
    Assert.AreEqual(
      wrSignaled, oEvento.WaitFor(0));
    Assert.AreEqual(0, FGestor.CantidadTareas);
    Assert.IsTrue(FGestor.EnDestruccion);
  finally
    FreeAndNil(oEvento);
  end;
end;

procedure TPruebasGestorTareasMto.
  Destruccion_SuprimeTrabajoNuevo;
var
  oEvento: TEvent;
begin
  oEvento := TEvent.Create(nil, True, False, '');
  try
    Assert.IsFalse(
      FGestor.EsperarFinalizacion(nil, False));
    FGestor.Ejecutar(
      procedure
      begin
        oEvento.SetEvent;
      end,
      nil);
    Assert.AreEqual(0, FGestor.CantidadTareas);
    Assert.AreEqual(
      wrTimeout, oEvento.WaitFor(0));
  finally
    FreeAndNil(oEvento);
  end;
end;

end.
