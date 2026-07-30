{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasTraducciones                                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del fallback, pseudoidioma, herencia y colecciones traducibles.   }
{******************************************************************************}
unit PruebasTraducciones;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasTraducciones = class
  public
    [Test]
    procedure Pseudoidioma_TraduceRaizYComponenteHeredados;
    [Test]
    procedure Pseudoidioma_NoDuplicaMarcadorYConservaVacios;
    [Test]
    procedure Pseudoidioma_TraduceColeccionDevExpress;
    [Test]
    procedure SinCatalogo_ConservaTextoPredeterminado;
    [Test]
    procedure Idioma_NormalizaVacioYGuionBajo;
    [Test]
    procedure Clave_UsaClaseConcretaYNombreComponente;
  end;

implementation

uses
  System.Classes, System.SysUtils,
  cxRadioGroup,
  inLibTraduccionesIntf,
  inLibTraducciones;

type
  TComponenteTextoPrueba = class(TComponent)
  private
    FCaption: string;
    FDisplayName: string;
    FHint: string;
    FTitle: string;
  published
    property Caption: string read FCaption write FCaption;
    property DisplayName: string
      read FDisplayName write FDisplayName;
    property Hint: string read FHint write FHint;
    property Title: string read FTitle write FTitle;
  end;

  TRaizBasePrueba = class(TComponenteTextoPrueba)
  end;

  TRaizHeredadaPrueba = class(TRaizBasePrueba)
  end;

procedure TPruebasTraducciones.
  Pseudoidioma_TraduceRaizYComponenteHeredados;
var
  Componente: TComponenteTextoPrueba;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'Ventana';
    Componente := TComponenteTextoPrueba.Create(Raiz);
    Componente.Name := 'Texto';
    Componente.Caption := 'Aceptar';
    Componente.Hint := 'Ayuda';
    Componente.Title := 'Título';
    Componente.DisplayName := 'Visible';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      '[!! Ventana ~~~~ !!]',
      Raiz.Caption);
    Assert.AreEqual(
      '[!! Aceptar ~~~~ !!]',
      Componente.Caption);
    Assert.AreEqual(
      '[!! Ayuda ~~~~ !!]',
      Componente.Hint);
    Assert.AreEqual(
      '[!! Título ~~~~ !!]',
      Componente.Title);
    Assert.AreEqual(
      '[!! Visible ~~~~ !!]',
      Componente.DisplayName);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  Pseudoidioma_NoDuplicaMarcadorYConservaVacios;
var
  PrimeraAplicacion: string;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'Caja';
    Raiz.Hint := '';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    PrimeraAplicacion := Raiz.Caption;
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      PrimeraAplicacion,
      Raiz.Caption);
    Assert.AreEqual(
      '',
      Raiz.Hint);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  Pseudoidioma_TraduceColeccionDevExpress;
var
  Grupo: TcxRadioGroup;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Grupo := TcxRadioGroup.Create(Raiz);
    Grupo.Name := 'Grupo';
    Grupo.Properties.Items.Add.Caption := 'Primera';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      '[!! Primera ~~~~ !!]',
      Grupo.Properties.Items[0].Caption);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  SinCatalogo_ConservaTextoPredeterminado;
var
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'Original';
    Servicio := TServicioTraducciones.Create(
      nil,
      'en-GB');
    Assert.AreEqual(
      'Original',
      Servicio.Traducir(
        'Prueba.Clave.Caption',
        'Original'));
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      'Original',
      Raiz.Caption);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  Idioma_NormalizaVacioYGuionBajo;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := TServicioTraducciones.Create(
    nil,
    '');
  Assert.AreEqual(
    IDIOMA_ESPANOL,
    Servicio.Idioma);
  Servicio.EstablecerIdioma('en_GB');
  Assert.AreEqual(
    'en-GB',
    Servicio.Idioma);
  Servicio.EstablecerIdioma('  qps_ploc  ');
  Assert.AreEqual(
    IDIOMA_PSEUDO,
    Servicio.Idioma);
end;

procedure TPruebasTraducciones.
  Clave_UsaClaseConcretaYNombreComponente;
var
  Componente: TComponenteTextoPrueba;
  Raiz: TRaizHeredadaPrueba;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Componente := TComponenteTextoPrueba.Create(Raiz);
    Componente.Name := 'Texto';
    Assert.AreEqual(
      'PruebasTraducciones.TRaizHeredadaPrueba.Caption',
      ClaveTraduccionComponente(
        Raiz,
        Raiz,
        'Caption'));
    Assert.AreEqual(
      'PruebasTraducciones.TRaizHeredadaPrueba.Texto.Hint',
      ClaveTraduccionComponente(
        Raiz,
        Componente,
        'Hint'));
  finally
    FreeAndNil(Raiz);
  end;
end;

end.
