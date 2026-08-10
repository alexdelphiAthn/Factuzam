{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGenerarTicketCaja                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza el modelo de tickets de operaciones de Caja sin UniDAC.       }
{******************************************************************************}
unit PruebasGenerarTicketCaja;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasGenerarTicketCaja = class
  public
    [Test]
    procedure EntradaCambioPreparaTituloYDatos;
    [Test]
    procedure OperacionInexistenteNoGeneraModelo;
  end;

implementation

uses
  System.SysUtils,
  inLibGenerarTicketCaja,
  inLibGenerarTicketCajaPersistenciaIntf,
  inLibGenerarTicketIntf,
  inLibMsgTickets;

type
  TLecturasTicketFalsas = class(
    TInterfacedObject,
    ILecturasImpresionTicket)
  private
    FDatos: TDatosOperacionTicketCaja;
  public
    function ListarPieCaja(
      const ACodigoEmpresa: string): TArray<string>;
    function ObtenerDiminutivoVendedor(
      const ACodigoEmpleado: string): string;
    function ObtenerCodigoBarras(
      const ASerie, ANumero: string): string;
    function ObtenerOperacion(
      const AClave: TClaveOperacionTicketCaja):
      TDatosOperacionTicketCaja;
  end;

function TLecturasTicketFalsas.ListarPieCaja(
  const ACodigoEmpresa: string): TArray<string>;
begin
  SetLength(Result, 0);
end;

function TLecturasTicketFalsas.ObtenerDiminutivoVendedor(
  const ACodigoEmpleado: string): string;
begin
  Result := ACodigoEmpleado;
end;

function TLecturasTicketFalsas.ObtenerCodigoBarras(
  const ASerie, ANumero: string): string;
begin
  Result := '';
end;

function TLecturasTicketFalsas.ObtenerOperacion(
  const AClave: TClaveOperacionTicketCaja):
  TDatosOperacionTicketCaja;
begin
  Result := FDatos;
end;

procedure PrepararClave(out AClave: TClaveOperacionTicketCaja);
begin
  AClave := Default(TClaveOperacionTicketCaja);
  AClave.Empresa := 'EMP-1';
  AClave.Almacen := 'ALM-1';
  AClave.Caja := 'CAJA-1';
  AClave.NumeroOperacion := '1';
end;

procedure TPruebasGenerarTicketCaja.EntradaCambioPreparaTituloYDatos;
var
  oLecturasObjeto: TLecturasTicketFalsas;
  oLecturas: ILecturasImpresionTicket;
  oClave: TClaveOperacionTicketCaja;
  oModelo: TModeloTicketOperacionCaja;
begin
  PrepararClave(oClave);
  oLecturasObjeto := TLecturasTicketFalsas.Create;
  oLecturasObjeto.FDatos.Encontrada := True;
  oLecturasObjeto.FDatos.TipoOperacion := 'EC';
  oLecturasObjeto.FDatos.FechaOperacion := EncodeDate(2026, 8, 4);
  oLecturasObjeto.FDatos.CodigoEmpleado := 'EMP-1';
  oLecturasObjeto.FDatos.Concepto := 'Entrada de cambio';
  oLecturasObjeto.FDatos.Importe := 50;
  oLecturas := oLecturasObjeto;
  oModelo := PrepararModeloTicketOperacionCaja(oLecturas, oClave);
  Assert.IsTrue(oModelo.Encontrada);
  Assert.AreEqual(STicketEntradaCambio, oModelo.Titulo);
  Assert.AreEqual('EMP-1', oModelo.CodigoEmpleado);
  Assert.AreEqual('Entrada de cambio', oModelo.Concepto);
  Assert.AreEqual(Double(50), Double(oModelo.Importe), 0.0001);
end;

procedure TPruebasGenerarTicketCaja.OperacionInexistenteNoGeneraModelo;
var
  oLecturas: ILecturasImpresionTicket;
  oClave: TClaveOperacionTicketCaja;
  oModelo: TModeloTicketOperacionCaja;
begin
  PrepararClave(oClave);
  oLecturas := TLecturasTicketFalsas.Create;
  oModelo := PrepararModeloTicketOperacionCaja(oLecturas, oClave);
  Assert.IsFalse(oModelo.Encontrada);
  Assert.AreEqual('', oModelo.Titulo);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasGenerarTicketCaja);

end.
