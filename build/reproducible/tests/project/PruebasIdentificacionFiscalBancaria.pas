{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasIdentificacionFiscalBancaria                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de NIF, NIE, CIF, CCC e IBAN usadas por la aplicación.            }
{******************************************************************************}
unit PruebasIdentificacionFiscalBancaria;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasIdentificacionFiscalBancaria = class
  public
    [Test]
    procedure DocumentoFiscal_NifValidoAceptaSeparadores;
    [Test]
    procedure DocumentoFiscal_NieValido;
    [Test]
    procedure DocumentoFiscal_CifValido;
    [Test]
    procedure DocumentoFiscal_InvalidoInformaTipo;
    [Test]
    procedure Pais_EspanaReconoceCodigosYNombres;
    [Test]
    procedure IbanEspanol_Valido;
    [Test]
    procedure IbanInternacional_ValidoConLetras;
    [Test]
    procedure IbanInvalido_InformaError;
    [Test]
    procedure Ccc_ValidaFormatoSoloYConIban;
    [Test]
    procedure CccInvalido_InformaDigito;
    [Test]
    procedure GenerarIban_ProduceControlEsperado;
    [Test]
    procedure FormatoYExtraccion_NormalizanCuenta;
    [Test]
    procedure DescomponerCCC_DevuelveComponentes;
  end;

implementation

uses
  System.Classes, System.SysUtils,
  inLibDocumentoFiscal, inLibIBAN;

const
  cCccValido = '21000418450200051332';
  cIbanValido = 'ES9121000418450200051332';

procedure TPruebasIdentificacionFiscalBancaria.
  DocumentoFiscal_NifValidoAceptaSeparadores;
begin
  Assert.IsTrue(
    DocumentoFiscalValido('12.345.678-Z'));
  Assert.AreEqual(
    '12345678Z',
    LimpiarDocumentoFiscal(' 12.345.678-z '));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  DocumentoFiscal_NieValido;
begin
  Assert.IsTrue(
    DocumentoFiscalValido('X-2482300-W'));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  DocumentoFiscal_CifValido;
begin
  Assert.IsTrue(
    DocumentoFiscalValido('A58818501'));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  DocumentoFiscal_InvalidoInformaTipo;
begin
  Assert.IsFalse(
    DocumentoFiscalValido('12345678A'));
  Assert.IsTrue(
    Pos(
      'NIF invalido',
      MensajeDocumentoFiscalInvalido('12345678A')) > 0);
end;

procedure TPruebasIdentificacionFiscalBancaria.
  Pais_EspanaReconoceCodigosYNombres;
begin
  Assert.IsTrue(
    PaisEsEspana('724', ''));
  Assert.IsTrue(
    PaisEsEspana('ES', ''));
  Assert.IsTrue(
    PaisEsEspana('', 'España'));
  Assert.IsTrue(
    PaisEsEspana('', 'Spain'));
  Assert.IsFalse(
    PaisEsEspana('FR', 'Francia'));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  IbanEspanol_Valido;
begin
  Assert.IsTrue(
    TIBAN.ValidarIBAN(cIbanValido));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  IbanInternacional_ValidoConLetras;
begin
  Assert.IsTrue(
    TIBAN.ValidarIBAN('GB82 WEST 1234 5698 7654 32'));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  IbanInvalido_InformaError;
var
  oErrores: TStringList;
begin
  oErrores := TStringList.Create;
  try
    Assert.IsFalse(
      TIBAN.ValidarIBAN(
        'ES9121000418450200051333',
        oErrores));
    Assert.IsTrue(
      oErrores.Count > 0);
  finally
    FreeAndNil(oErrores);
  end;
end;

procedure TPruebasIdentificacionFiscalBancaria.
  Ccc_ValidaFormatoSoloYConIban;
begin
  Assert.IsTrue(
    TIBAN.ValidarCCC(cCccValido));
  Assert.IsTrue(
    TIBAN.ValidarCCC(cIbanValido));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  CccInvalido_InformaDigito;
var
  oErrores: TStringList;
begin
  oErrores := TStringList.Create;
  try
    Assert.IsFalse(
      TIBAN.ValidarCCC(
        '21000418440200051332',
        oErrores));
    Assert.IsTrue(
      oErrores.Count > 0);
  finally
    FreeAndNil(oErrores);
  end;
end;

procedure TPruebasIdentificacionFiscalBancaria.
  GenerarIban_ProduceControlEsperado;
begin
  Assert.AreEqual(
    cIbanValido,
    TIBAN.GenerarIBAN(
      'es',
      cCccValido));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  FormatoYExtraccion_NormalizanCuenta;
const
  cIbanConFormato = 'IBAN es91 2100-0418 4502 0005 1332';
begin
  Assert.AreEqual(
    cIbanValido,
    TIBAN.FormatearElectronico(cIbanConFormato));
  Assert.AreEqual(
    cCccValido,
    TIBAN.ExtraerCCC(cIbanConFormato));
end;

procedure TPruebasIdentificacionFiscalBancaria.
  DescomponerCCC_DevuelveComponentes;
var
  sBanco: string;
  sCuenta: string;
  sDc: string;
begin
  Assert.IsTrue(
    TIBAN.DescomponerCCC(
      '2100 0418 45 0200051332',
      sBanco,
      sDc,
      sCuenta));
  Assert.AreEqual(
    '21000418',
    sBanco);
  Assert.AreEqual(
    '45',
    sDc);
  Assert.AreEqual(
    '0200051332',
    sCuenta);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasIdentificacionFiscalBancaria);

end.
