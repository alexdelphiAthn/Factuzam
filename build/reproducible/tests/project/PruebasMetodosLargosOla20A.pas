{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasMetodosLargosOla20A                                  }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza filtros de búsqueda y el desglose fiscal de la ola IA-20A.    }
{******************************************************************************}
unit PruebasMetodosLargosOla20A;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasMetodosLargosOla20A = class
  public
    [Test]
    procedure Busqueda_TextoConFiltrosConservaSqlYParametros;
    [Test]
    procedure Busqueda_ProximidadConservaDistanciaYColor;
    [Test]
    procedure Desglose_ExportacionSumaBasesSinRepercutirIva;
    [Test]
    procedure Desglose_BandaSujetaConservaRecargo;
    [Test]
    procedure Desglose_TotalCeroConservaDetalleMinimo;
    [Test]
    procedure Recordatorio_CantidadCeroEquivaleAUnaUnidad;
    [Test]
    procedure Recordatorio_OrigenOmiteSegmentosVacios;
    [Test]
    procedure Recordatorio_TipoAnticipoConservaConcepto;
  end;

implementation

uses
  System.SysUtils, Uni,
  inLibBusquedaDatosPersistenciaIntf,
  UniDataBusquedaDatosRepositorio,
  inLibVerifactuDesgloseFiscal,
  inLibTicketRecordatorio,
  inLibTicketsCajaIntf,
  inLibMsgTickets;

procedure TPruebasMetodosLargosOla20A.
  Busqueda_TextoConFiltrosConservaSqlYParametros;
var
  oCriterios: TCriteriosBusquedaDatos;
  oRepositorio: IRepositorioBusquedaDatos;
  oResultado: IResultadoBusquedaDatos;
  oConsulta: TUniQuery;
  sSql: string;
begin
  oCriterios := Default(TCriteriosBusquedaDatos);
  oCriterios.Campo := CAMPO_DESCRIPCION;
  oCriterios.Coincidencia := 0;
  oCriterios.Estado := 0;
  oCriterios.Stock := 1;
  oCriterios.Limite := 25;
  oCriterios.Valor := ' Camiseta ';
  oCriterios.Familia := 'FAM';
  oCriterios.Proveedor := 'PRV';
  oCriterios.Temporada := 'VERANO';
  oCriterios.Almacen := 'ALM';
  oRepositorio := CrearRepositorioBusquedaDatosUniDAC(nil);
  oResultado := oRepositorio.PrepararBusqueda(oCriterios);
  oConsulta := oResultado.DataSet as TUniQuery;
  sSql := oConsulta.SQL.Text;
  Assert.IsTrue(Pos('eti.ESACTIVO_ART = ''S''', sSql) > 0);
  Assert.IsTrue(Pos('CANTIDAD_STOCK, 0) > 0', sSql) > 0);
  Assert.IsTrue(Pos('eti.CODIGO_FAM_ART = :FAMILIA', sSql) > 0);
  Assert.IsTrue(Pos('UPPER(COALESCE(eti.DESCRIPCION_ART', sSql) > 0);
  Assert.IsTrue(Pos('LIMIT 25', sSql) > 0);
  Assert.AreEqual('%CAMISETA%',
    oConsulta.ParamByName('BUSQUEDA').AsString);
  Assert.AreEqual('FAM', oConsulta.ParamByName('FAMILIA').AsString);
  Assert.AreEqual('PRV', oConsulta.ParamByName('PROVEEDOR').AsString);
  Assert.AreEqual('VERANO',
    oConsulta.ParamByName('TEMPORADA').AsString);
  Assert.AreEqual('ALM',
    oConsulta.ParamByName('ALMACEN_DOC').AsString);
end;

procedure TPruebasMetodosLargosOla20A.
  Busqueda_ProximidadConservaDistanciaYColor;
var
  oCriterios: TCriteriosBusquedaDatos;
  oRepositorio: IRepositorioBusquedaDatos;
  oResultado: IResultadoBusquedaDatos;
  oConsulta: TUniQuery;
  sSql: string;
begin
  oCriterios := Default(TCriteriosBusquedaDatos);
  oCriterios.Campo := CAMPO_PROXIMIDAD_COLOR;
  oCriterios.Estado := 1;
  oCriterios.Limite := 15;
  oCriterios.Almacen := 'CENTRAL';
  oCriterios.Rojo := 10;
  oCriterios.Verde := 20;
  oCriterios.Azul := 30;
  oRepositorio := CrearRepositorioBusquedaDatosUniDAC(nil);
  oResultado := oRepositorio.PrepararBusqueda(oCriterios);
  oConsulta := oResultado.DataSet as TUniQuery;
  sSql := oConsulta.SQL.Text;
  Assert.IsTrue(Pos('AS DISTANCIA_COLOR', sSql) > 0);
  Assert.IsTrue(Pos('pal.HEX_ATB REGEXP', sSql) > 0);
  Assert.IsTrue(Pos('ORDER BY DISTANCIA_COLOR', sSql) > 0);
  Assert.AreEqual(10, oConsulta.ParamByName('ROJO').AsInteger);
  Assert.AreEqual(20, oConsulta.ParamByName('VERDE').AsInteger);
  Assert.AreEqual(30, oConsulta.ParamByName('AZUL').AsInteger);
end;

procedure TPruebasMetodosLargosOla20A.
  Desglose_ExportacionSumaBasesSinRepercutirIva;
var
  oEntrada: TEntradaDesgloseFiscal;
  sDesglose: string;
begin
  oEntrada := Default(TEntradaDesgloseFiscal);
  oEntrada.Operacion.EsClienteExtranjero := True;
  oEntrada.Bandas[0].Base := 50;
  oEntrada.Bandas[1].Base := 25;
  sDesglose := ConstruirDesgloseFiscal(oEntrada);
  Assert.IsTrue(Pos('<sum1:OperacionExenta>E2', sDesglose) > 0);
  Assert.IsTrue(Pos('>75.00</sum1:BaseImponible', sDesglose) > 0);
  Assert.IsTrue(Pos('<sum1:TipoImpositivo>', sDesglose) = 0);
end;

procedure TPruebasMetodosLargosOla20A.
  Desglose_BandaSujetaConservaRecargo;
var
  oEntrada: TEntradaDesgloseFiscal;
  sDesglose: string;
begin
  oEntrada := Default(TEntradaDesgloseFiscal);
  oEntrada.Operacion.Definida := True;
  oEntrada.Operacion.ClaveRegimen := '03';
  oEntrada.Operacion.Calificacion := 'S1';
  oEntrada.Operacion.RepercuteIva := True;
  oEntrada.Bandas[0].Porcentaje := 21;
  oEntrada.Bandas[0].Base := 100;
  oEntrada.Bandas[0].Cuota := 21;
  oEntrada.Bandas[0].PorcentajeRecargo := 5.2;
  oEntrada.Bandas[0].CuotaRecargo := 5.2;
  sDesglose := ConstruirDesgloseFiscal(oEntrada);
  Assert.IsTrue(Pos('<sum1:ClaveRegimen>03', sDesglose) > 0);
  Assert.IsTrue(Pos('<sum1:TipoImpositivo>21.00', sDesglose) > 0);
  Assert.IsTrue(Pos('<sum1:TipoRecargoEquivalencia>5.20',
    sDesglose) > 0);
  Assert.IsTrue(Pos('<sum1:CuotaRecargoEquivalencia>5.20',
    sDesglose) > 0);
end;

procedure TPruebasMetodosLargosOla20A.
  Desglose_TotalCeroConservaDetalleMinimo;
var
  oEntrada: TEntradaDesgloseFiscal;
  sDesglose: string;
begin
  oEntrada := Default(TEntradaDesgloseFiscal);
  sDesglose := ConstruirDesgloseFiscal(oEntrada);
  Assert.IsTrue(Pos('<sum1:TipoImpositivo>0.00', sDesglose) > 0);
  Assert.IsTrue(Pos('<sum1:CuotaRepercutida>0.00', sDesglose) > 0);
end;

procedure TPruebasMetodosLargosOla20A.
  Recordatorio_CantidadCeroEquivaleAUnaUnidad;
var
  oDeposito: TDepositoPendienteTicketCaja;
begin
  oDeposito := Default(TDepositoPendienteTicketCaja);
  oDeposito.PrecioVenta := 40;
  oDeposito.ImporteAnticipo := 15;
  Assert.AreEqual(
    Currency(40),
    CalcularTotalDepositoRecordatorio(oDeposito));
  Assert.AreEqual(
    Currency(25),
    CalcularPendienteDepositoRecordatorio(oDeposito));
end;

procedure TPruebasMetodosLargosOla20A.
  Recordatorio_OrigenOmiteSegmentosVacios;
begin
  Assert.AreEqual(
    'EMP/CAJ',
    ConstruirOrigenRecordatorio('EMP', '', 'CAJ'));
  Assert.AreEqual(
    'EMP/ALM',
    ConstruirOrigenRecordatorio('EMP', 'ALM', ''));
end;

procedure TPruebasMetodosLargosOla20A.
  Recordatorio_TipoAnticipoConservaConcepto;
begin
  Assert.AreEqual(
    STicketEntregaInicial,
    ConceptoAnticipoRecordatorio('DE'));
  Assert.AreEqual(
    STicketACuenta,
    ConceptoAnticipoRecordatorio('CB'));
  Assert.AreEqual('', ConceptoAnticipoRecordatorio('XX'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasMetodosLargosOla20A);

end.
