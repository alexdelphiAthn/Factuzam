{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasExcepcionesAplicacion                                  }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de clasificación y detalle de excepciones globales.               }
{******************************************************************************}
unit PruebasExcepcionesAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasExcepcionesAplicacion = class
  public
    [Test]
    procedure RuidoEditorInplace_SeIgnora;
    [Test]
    procedure ExcepcionNormal_NoSeIgnora;
    [Test]
    procedure Detalle_IncluyeContextoExcepcionYSender;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  inLibContextoSesionIntf,
  inLibExcepcionesAplicacionIntf;

procedure TPruebasExcepcionesAplicacion.
  RuidoEditorInplace_SeIgnora;
var
  Error: Exception;
begin
  Error := EInvalidOperation.Create(
    'El control no tiene ventana principal');
  try
    Assert.IsTrue(
      EsRuidoEditorInplace(Error));
  finally
    Error.Free;
  end;
end;

procedure TPruebasExcepcionesAplicacion.
  ExcepcionNormal_NoSeIgnora;
var
  Error: Exception;
begin
  Error := Exception.Create(
    'Fallo controlado');
  try
    Assert.IsFalse(
      EsRuidoEditorInplace(Error));
  finally
    Error.Free;
  end;
end;

procedure TPruebasExcepcionesAplicacion.
  Detalle_IncluyeContextoExcepcionYSender;
var
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
  Componente: TComponent;
  Error: Exception;
  Detalle: string;
begin
  Identidad := TIdentidadSesion.Crear(
    'usuario1',
    'grupo1',
    'N');
  Ubicacion := TUbicacionSesion.Crear(
    'EMP',
    'ALM',
    'CAJA');
  Componente := TComponent.Create(nil);
  Error := Exception.Create(
    'Fallo controlado');
  try
    Componente.Name := 'ComponentePrueba';
    Detalle := ConstruirDetalleExcepcionAplicacion(
      Componente,
      Error,
      Identidad,
      Ubicacion,
      'Factuzam',
      '1.2.3',
      'EQUIPO',
      EncodeDate(2026, 7, 29) +
        EncodeTime(18, 30, 15, 125),
      Pointer($1234));
    Assert.IsTrue(
      Pos('Factuzam 1.2.3', Detalle) > 0);
    Assert.IsTrue(
      Pos('usuario1 (grupo1)', Detalle) > 0);
    Assert.IsTrue(
      Pos('EMP', Detalle) > 0);
    Assert.IsTrue(
      Pos('ALM / CAJA', Detalle) > 0);
    Assert.IsTrue(
      Pos('EQUIPO', Detalle) > 0);
    Assert.IsTrue(
      Pos('Exception', Detalle) > 0);
    Assert.IsTrue(
      Pos('Fallo controlado', Detalle) > 0);
    Assert.IsTrue(
      Pos('TComponent', Detalle) > 0);
    Assert.IsTrue(
      Pos('ComponentePrueba', Detalle) > 0);
    Assert.IsTrue(
      Pos('1234', Detalle) > 0);
  finally
    Error.Free;
    Componente.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasExcepcionesAplicacion);

end.
