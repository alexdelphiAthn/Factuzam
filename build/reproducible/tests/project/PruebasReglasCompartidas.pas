{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasReglasCompartidas                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de reglas extraídas para eliminar dependencias circulares.        }
{******************************************************************************}
unit PruebasReglasCompartidas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasReglasCompartidas = class
  public
    [Test]
    procedure ColorSku_EliminaSimbolosYNormalizaSeparadores;
    [Test]
    procedure ColorBasico_ResuelveCodigoONombreNormalizado;
    [Test]
    procedure ColorBasico_SinCoincidenciaNoResuelve;
    [Test]
    procedure Perfil_DevuelveValorConfiguradoOPredeterminado;
    [Test]
    procedure FiltroArticulos_SeparaValoresCsv;
    [Test]
    procedure FiltroArticulos_IgnoraValoresVacios;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosFiltro,
  inLibComprasSesionesReglas,
  inLibPerfilesUsuarioIntf,
  inLibPerfilesUsuarioValores;

procedure TPruebasReglasCompartidas.
  ColorSku_EliminaSimbolosYNormalizaSeparadores;
begin
  Assert.AreEqual(
    'AZUL-MARINO',
    SanearColorSku('  azul / marino %__  '));
  Assert.AreEqual(
    '',
    SanearColorSku('-_ / %'));
end;

procedure TPruebasReglasCompartidas.
  ColorBasico_ResuelveCodigoONombreNormalizado;
var
  sCodigo: string;
begin
  Assert.IsTrue(ResolverCodigoColorBasico(
    ' negro ', ['NEGRO', 'AZM'], ['Negro', 'Azul marino'], sCodigo));
  Assert.AreEqual('NEGRO', sCodigo);
  Assert.IsTrue(ResolverCodigoColorBasico(
    ' azul / marino ', ['NEGRO', 'AZM'],
    ['Negro', 'Azul marino'], sCodigo));
  Assert.AreEqual('AZM', sCodigo);
end;

procedure TPruebasReglasCompartidas.
  ColorBasico_SinCoincidenciaNoResuelve;
var
  sCodigo: string;
begin
  sCodigo := 'ANTERIOR';
  Assert.IsFalse(ResolverCodigoColorBasico(
    'coral', ['NEGRO', 'AZM'], ['Negro', 'Azul marino'], sCodigo));
  Assert.AreEqual('', sCodigo);
end;

procedure TPruebasReglasCompartidas.
  Perfil_DevuelveValorConfiguradoOPredeterminado;
var
  oPerfil: TProfileDicc;
  oValor: TDictValue;
begin
  oPerfil := TProfileDicc.Create;
  try
    oValor.sValue := 'Cliente';
    oValor.sValueText := 'SELECT 1';
    oPerfil.Add('lblNombre_Caption', oValor);
    oPerfil.Add('unqryListado', oValor);
    Assert.AreEqual(
      'Cliente',
      GetPerfilSubKeyValueDef(
        oPerfil, 'lblNombre', 'Caption', 'Nombre'));
    Assert.AreEqual(
      'Nombre',
      GetPerfilSubKeyValueDef(
        oPerfil, 'lblAusente', 'Caption', 'Nombre'));
    Assert.AreEqual(
      'SELECT 1',
      string(GetPerfilValueTextDef(
        oPerfil, 'unqryListado', 'SELECT 0')));
    Assert.AreEqual(
      'SELECT 0',
      string(GetPerfilValueTextDef(
        oPerfil, 'unqryAusente', 'SELECT 0')));
  finally
    FreeAndNil(oPerfil);
  end;
end;

procedure TPruebasReglasCompartidas.FiltroArticulos_SeparaValoresCsv;
var
  aValores: TArray<string>;
begin
  aValores := SepararValoresFiltroArticulos(
    'VERANO; O''HARA ; ;');
  Assert.AreEqual(2, Integer(Length(aValores)));
  Assert.AreEqual('VERANO', aValores[0]);
  Assert.AreEqual('O''HARA', aValores[1]);
end;

procedure TPruebasReglasCompartidas.
  FiltroArticulos_IgnoraValoresVacios;
var
  aValores: TArray<string>;
begin
  aValores := SepararValoresFiltroArticulos(
    ' ;0101;; 0102;');
  Assert.AreEqual(2, Integer(Length(aValores)));
  Assert.AreEqual('0101', aValores[0]);
  Assert.AreEqual('0102', aValores[1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasReglasCompartidas);

end.
