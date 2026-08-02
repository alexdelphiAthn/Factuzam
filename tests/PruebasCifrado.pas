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
{    Pruebas de compatibilidad del cifrado AES persistido.                     }
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
    procedure CopiaActual_ExigeContrasenaCorrecta;
    [Test]
    procedure CopiaActual_UsaSalAleatoria;
    [Test]
    procedure CopiaComprimida_RestauraYReduceContenidoRepetitivo;
    [Test]
    procedure CopiaHistorica_SigueRestaurandose;
  end;

implementation

uses
  inLibCifrado,
  inLibCifradoCopias;

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
  CopiaActual_ExigeContrasenaCorrecta;
const
  TEXTO = 'CREATE TABLE prueba (ID integer);';
var
  bRechazada: Boolean;
  sCifrado: string;
begin
  sCifrado := CifrarCopiaSeguridad(
    TEXTO,
    'contraseña correcta');
  Assert.IsTrue(EsFormatoCifradoActual(sCifrado));
  Assert.AreEqual(
    TEXTO,
    DescifrarCopiaSeguridad(
      sCifrado,
      'contraseña correcta'));
  bRechazada := False;
  try
    DescifrarCopiaSeguridad(
      sCifrado,
      'contraseña incorrecta');
  except
    on ECifradoCopia do
      bRechazada := True;
  end;
  Assert.IsTrue(bRechazada);
end;

procedure TPruebasCifrado.
  CopiaActual_UsaSalAleatoria;
var
  sPrimera: string;
  sSegunda: string;
begin
  sPrimera := CifrarCopiaSeguridad(
    'SELECT 1;',
    'misma contraseña');
  sSegunda := CifrarCopiaSeguridad(
    'SELECT 1;',
    'misma contraseña');
  Assert.AreNotEqual(sPrimera, sSegunda);
end;

procedure TPruebasCifrado.
  CopiaComprimida_RestauraYReduceContenidoRepetitivo;
var
  sCifrado: string;
  sOrigen: string;
begin
  sOrigen := StringOfChar('A', 100000);
  sCifrado := CifrarCopiaSeguridadComprimida(
    sOrigen,
    'contraseña comprimida');
  Assert.AreEqual(1, Pos('FZAM_COPIA_CIFRADA_V3', sCifrado));
  Assert.IsTrue(EsFormatoCifradoActual(sCifrado));
  Assert.IsTrue(Length(sCifrado) < Length(sOrigen));
  Assert.AreEqual(
    sOrigen,
    DescifrarCopiaSeguridad(
      sCifrado,
      'contraseña comprimida'));
end;

procedure TPruebasCifrado.
  CopiaHistorica_SigueRestaurandose;
const
  CIFRADO_HISTORICO = 'OVwCB7+S5739/Z2iYHXc3w==';
begin
  Assert.AreEqual(
    'texto de prueba',
    DescifrarCopiaSeguridad(
      CIFRADO_HISTORICO,
      'clave histórica'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCifrado);

end.
