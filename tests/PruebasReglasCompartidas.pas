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
    procedure Perfil_DevuelveValorConfiguradoOPredeterminado;
  end;

implementation

uses
  System.SysUtils,
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

initialization
  TDUnitX.RegisterTestFixture(TPruebasReglasCompartidas);

end.
