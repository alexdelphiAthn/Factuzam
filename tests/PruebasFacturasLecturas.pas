{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasLecturas                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la delegación de lecturas de facturas sin acceso a BBDD.      }
{******************************************************************************}
unit PruebasFacturasLecturas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasLecturas = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure MostrarSku_DelegaArticuloYResultado;
    [Test]
    procedure ContarLineas_DelegaDocumentoYResultado;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Data.DB, Uni, inLibFacturasLecturasIntf,
  UniDataFacturasLecturas, inLibFacturas;

type
  TRepositorioLecturasFacturaFalso = class(
    TInterfacedObject,
    IRepositorioLecturasFactura)
  public
    function ArticuloDebeMostrarSku(
      const ACodigoArticulo: string): Boolean;
    function ContarLineas(
      const ASerie, ANumero: string): Integer;
    function BuscarConfiguracionIva(
      const AGrupo: string;
      AFecha: TDateTime): TDataSet;
    function BuscarPorcentajeRetencion(
      const ACodigoEmpresa: string;
      AFecha: TDateTime): Currency;
    function BuscarDatosIvaAgricola(
      const ACodigoEmpresa: string;
      AFecha: TDateTime): TDataSet;
    function BuscarClienteConTarifa(
      const ACodigoCliente: string): TDataSet;
    function BuscarEmpresa(
      const ACodigoEmpresa: string): TDataSet;
  end;

var
  sArticuloRecibido: string;
  sNumeroRecibido: string;
  sSerieRecibida: string;

function CrearRepositorioLecturasFacturaFalso(
  AConexion: TUniConnection): IRepositorioLecturasFactura;
begin
  Result := TRepositorioLecturasFacturaFalso.Create;
end;

function TRepositorioLecturasFacturaFalso.ArticuloDebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  sArticuloRecibido := ACodigoArticulo;
  Result := False;
end;

function TRepositorioLecturasFacturaFalso.ContarLineas(
  const ASerie, ANumero: string): Integer;
begin
  sSerieRecibida := ASerie;
  sNumeroRecibido := ANumero;
  Result := 7;
end;

function TRepositorioLecturasFacturaFalso.BuscarConfiguracionIva(
  const AGrupo: string;
  AFecha: TDateTime): TDataSet;
begin
  Result := nil;
end;

function TRepositorioLecturasFacturaFalso.BuscarPorcentajeRetencion(
  const ACodigoEmpresa: string;
  AFecha: TDateTime): Currency;
begin
  Result := 0;
end;

function TRepositorioLecturasFacturaFalso.BuscarDatosIvaAgricola(
  const ACodigoEmpresa: string;
  AFecha: TDateTime): TDataSet;
begin
  Result := nil;
end;

function TRepositorioLecturasFacturaFalso.BuscarClienteConTarifa(
  const ACodigoCliente: string): TDataSet;
begin
  Result := nil;
end;

function TRepositorioLecturasFacturaFalso.BuscarEmpresa(
  const ACodigoEmpresa: string): TDataSet;
begin
  Result := nil;
end;

procedure TPruebasFacturasLecturas.Liberar;
begin
  TFabricaRepositorioLecturasFactura.Registrar(
    CrearRepositorioLecturasFacturaUniDAC);
  sArticuloRecibido := '';
  sNumeroRecibido := '';
  sSerieRecibida := '';
end;

procedure TPruebasFacturasLecturas.MostrarSku_DelegaArticuloYResultado;
begin
  TFabricaRepositorioLecturasFactura.Registrar(
    CrearRepositorioLecturasFacturaFalso);
  Assert.IsFalse(ArticuloFacturaDebeMostrarSku(nil, 'ART-001'));
  Assert.AreEqual('ART-001', sArticuloRecibido);
end;

procedure TPruebasFacturasLecturas.
  ContarLineas_DelegaDocumentoYResultado;
begin
  TFabricaRepositorioLecturasFactura.Registrar(
    CrearRepositorioLecturasFacturaFalso);
  Assert.AreEqual(7, ContarLineasFactura(nil, 'A', '42'));
  Assert.AreEqual('A', sSerieRecibida);
  Assert.AreEqual('42', sNumeroRecibido);
end;

procedure TPruebasFacturasLecturas.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaRepositorioLecturasFactura.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      ContarLineasFactura(nil, 'A', '42');
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasLecturas);

end.
