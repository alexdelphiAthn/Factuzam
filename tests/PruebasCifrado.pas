{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCifrado                                                }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de compatibilidad del cifrado AES y su fachada histórica.         }
{******************************************************************************}
unit PruebasCifrado;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCifrado = class
  public
    [Test]
    procedure CredencialPersistida_SeDescifraSinCambios;
    [Test]
    procedure TextoConocido_ConservaElVectorCifrado;
    [Test]
    procedure Unicode_ConservaUTF8YBase64;
    [Test]
    procedure EntradaInvalida_DevuelveCadenaVacia;
    [Test]
    procedure DatosVacios_ConservanBloqueDeRelleno;
    [Test]
    procedure ClaveYVectorExplicitos_ConservanElFormato;
    [Test]
    procedure ContrasenaDeCopia_ConservaCompatibilidadHistorica;
    [Test]
    procedure Fachada_ConservaResultadosHistoricos;
  end;

implementation

uses
  inLibCifrado, inLibtb;

procedure TPruebasCifrado.
  CredencialPersistida_SeDescifraSinCambios;
const
  CIFRADO_PERSISTIDO = '2qJFaDfegP/9y6RDno1FRg==';
var
  sTextoClaro: string;
begin
  sTextoClaro := DescifrarAES(CIFRADO_PERSISTIDO);
  Assert.IsNotEmpty(sTextoClaro);
  Assert.AreEqual(
    CIFRADO_PERSISTIDO,
    CifrarAES(sTextoClaro));
end;

procedure TPruebasCifrado.
  TextoConocido_ConservaElVectorCifrado;
begin
  Assert.AreEqual(
    'OVwCB7+S5739/Z2iYHXc3w==',
    CifrarAES('texto de prueba'));
end;

procedure TPruebasCifrado.
  Unicode_ConservaUTF8YBase64;
const
  TEXTO_UNICODE = 'Contraseña ñá €';
  CIFRADO_UNICODE =
    'bkG/haAuwHBiGWNV+ef8bGny3BN79/30OhbLQ1Zretw=';
begin
  Assert.AreEqual(
    CIFRADO_UNICODE,
    CifrarAES(TEXTO_UNICODE));
  Assert.AreEqual(
    TEXTO_UNICODE,
    DescifrarAES(CIFRADO_UNICODE));
end;

procedure TPruebasCifrado.
  EntradaInvalida_DevuelveCadenaVacia;
begin
  Assert.AreEqual(
    '',
    DescifrarAES('NO ES BASE64'));
  Assert.AreEqual(
    '',
    DescifrarAES(''));
end;

procedure TPruebasCifrado.
  DatosVacios_ConservanBloqueDeRelleno;
const
  CIFRADO_VACIO = 'Bm3BSlGZMDIemIrsvh1cUg==';
begin
  Assert.AreEqual(
    CIFRADO_VACIO,
    CifrarAES(''));
  Assert.AreEqual(
    '',
    DescifrarAES(CIFRADO_VACIO));
end;

procedure TPruebasCifrado.
  ClaveYVectorExplicitos_ConservanElFormato;
const
  CLAVE = '0123456789ABCDEF0123456789ABCDEF';
  VECTOR = 'ABCDEF0123456789';
  TEXTO = 'dato explícito ñ';
  CIFRADO = 'IYQpmvICRbAD7FkFUOu4WkEGgL+Eyeqsnpa7bskLazk=';
begin
  Assert.AreEqual(
    CIFRADO,
    CifrarDatosAES(
      TEXTO,
      CLAVE,
      VECTOR));
  Assert.AreEqual(
    TEXTO,
    DescifrarDatosAES(
      CIFRADO,
      CLAVE,
      VECTOR));
end;

procedure TPruebasCifrado.
  ContrasenaDeCopia_ConservaCompatibilidadHistorica;
const
  CIFRADO_HISTORICO = 'OVwCB7+S5739/Z2iYHXc3w==';
begin
  Assert.AreEqual(
    CIFRADO_HISTORICO,
    CifrarAESConContrasena(
      'texto de prueba',
      'clave histórica'));
  Assert.AreEqual(
    'texto de prueba',
    DescifrarAESConContrasena(
      CIFRADO_HISTORICO,
      'clave histórica'));
end;

procedure TPruebasCifrado.
  Fachada_ConservaResultadosHistoricos;
const
  CLAVE = '0123456789ABCDEF0123456789ABCDEF';
  VECTOR = 'ABCDEF0123456789';
begin
  Assert.AreEqual(
    CifrarAES('texto de prueba'),
    inLibtb.EncriptAES('texto de prueba'));
  Assert.AreEqual(
    DescifrarAES('2qJFaDfegP/9y6RDno1FRg=='),
    inLibtb.DecriptAES('2qJFaDfegP/9y6RDno1FRg=='));
  Assert.AreEqual(
    CifrarAESConContrasena(
      'texto de prueba',
      'clave histórica'),
    inLibtb.EncriptAESPass(
      'texto de prueba',
      'clave histórica'));
  Assert.AreEqual(
    DescifrarAESConContrasena(
      'OVwCB7+S5739/Z2iYHXc3w==',
      'clave histórica'),
    inLibtb.DecriptAESPass(
      'OVwCB7+S5739/Z2iYHXc3w==',
      'clave histórica'));
  Assert.AreEqual(
    CifrarDatosAES(
      'dato explícito ñ',
      CLAVE,
      VECTOR),
    inLibtb.EncryptData(
      'dato explícito ñ',
      CLAVE,
      VECTOR));
  Assert.AreEqual(
    DescifrarDatosAES(
      'IYQpmvICRbAD7FkFUOu4WkEGgL+Eyeqsnpa7bskLazk=',
      CLAVE,
      VECTOR),
    inLibtb.DecryptData(
      'IYQpmvICRbAD7FkFUOu4WkEGgL+Eyeqsnpa7bskLazk=',
      CLAVE,
      VECTOR));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCifrado);

end.
