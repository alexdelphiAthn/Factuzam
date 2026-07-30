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
    [Test]
    procedure TextoInforme_PseudoidiomaSinCorchetes;
    [Test]
    procedure TextoInforme_SinCatalogoConservaTexto;
    [Test]
    procedure Idioma_PreservaEtiquetasCatalogadas;
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
    Assert.IsFalse(
      Servicio.ExisteTraduccion(
        'Prueba.Clave.Caption'));
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

procedure TPruebasTraducciones.
  TextoInforme_PseudoidiomaSinCorchetes;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := TServicioTraducciones.Create(
    nil,
    IDIOMA_PSEUDO);
  Assert.AreEqual(
    'Factura ~~~~',
    Servicio.TraducirTextoInforme('Factura'));
  // Un memo formado solo por expresiones no se alarga.
  Assert.AreEqual(
    '[Ventas."TOTAL"]',
    Servicio.TraducirTextoInforme('[Ventas."TOTAL"]'));
  // Una segunda pasada no duplica el relleno.
  Assert.AreEqual(
    'Factura ~~~~',
    Servicio.TraducirTextoInforme(
      Servicio.TraducirTextoInforme('Factura')));
end;

procedure TPruebasTraducciones.
  TextoInforme_SinCatalogoConservaTexto;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := TServicioTraducciones.Create(
    nil,
    'en-GB');
  Assert.AreEqual(
    'Factura',
    Servicio.TraducirTextoInforme('Factura'));
end;

procedure TPruebasTraducciones.
  Idioma_PreservaEtiquetasCatalogadas;
begin
  Assert.AreEqual(
    IDIOMA_CATALAN,
    NormalizarIdiomaAplicacion('ca_ES'));
  Assert.AreEqual(
    IDIOMA_INGLES,
    NormalizarIdiomaAplicacion('en-GB'));
  Assert.AreEqual(
    'fr-FR',
    NormalizarIdiomaAplicacion('fr-FR'));
  Assert.AreEqual(
    IDIOMA_PSEUDO,
    NormalizarIdiomaAplicacion(IDIOMA_PSEUDO));
end;

end.
