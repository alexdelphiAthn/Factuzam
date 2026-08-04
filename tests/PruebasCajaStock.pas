{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCajaStock                                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la política de stock de Caja mediante dobles en memoria.      }
{******************************************************************************}
unit PruebasCajaStock;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCajaStock = class
  public
    [Test]
    procedure SkuInexistenteNoConsultaCantidad;
    [Test]
    procedure AvisoSinStockPermiteVentaYConservaMensaje;
    [Test]
    procedure ValidacionRepetidaConservaElResultado;
    [Test]
    procedure CodigoVacioNoConsultaPersistencia;
  end;

implementation

uses
  inLibCajaStock,
  inLibCajaStockPersistenciaIntf,
  inLibCajaVentaIntf,
  inLibParametrosIntf;

type
  TParametrosCajaFalsos = class(TInterfacedObject, IParametrosCaja)
  private
    FVerificarExistencia: Boolean;
    FBloquearSinStock: Boolean;
    FMensajeStock: string;
  public
    function GetString(
      const AKey: string;
      const ADefault: string = ''): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0): Integer;
    function ImpresoraCaja: string;
    function TarifaDefecto: string;
    function NivelesFamiliaArqueo: Integer;
  end;
  TCajaStockPersistenciaFalsa = class(
    TInterfacedObject,
    ICajaStockPersistencia)
  private
    FEstado: TEstadoSkuCajaStock;
    FCantidad: Double;
    FConsultasEstado: Integer;
    FConsultasCantidad: Integer;
  public
    function ObtenerEstadoSku(
      const ACodigoSku: string): TEstadoSkuCajaStock;
    function ObtenerCantidadDisponible(
      const ACodigoSku, ACodigoAlmacen: string): Double;
  end;

function TParametrosCajaFalsos.GetString(
  const AKey, ADefault: string): string;
begin
  Result := ADefault;
  if AKey = 'vgerAvisoStockWarning' then
    Result := FMensajeStock;
end;

function TParametrosCajaFalsos.GetBool(
  const AKey: string;
  const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
  if AKey = 'vgerChkExistOnly' then
    Result := FVerificarExistencia
  else if AKey = 'vgerChkStockOnly' then
    Result := FBloquearSinStock;
end;

function TParametrosCajaFalsos.GetInt(
  const AKey: string;
  const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosCajaFalsos.ImpresoraCaja: string;
begin
  Result := '';
end;

function TParametrosCajaFalsos.TarifaDefecto: string;
begin
  Result := '';
end;

function TParametrosCajaFalsos.NivelesFamiliaArqueo: Integer;
begin
  Result := 0;
end;

function TCajaStockPersistenciaFalsa.ObtenerEstadoSku(
  const ACodigoSku: string): TEstadoSkuCajaStock;
begin
  Inc(FConsultasEstado);
  Result := FEstado;
end;

function TCajaStockPersistenciaFalsa.ObtenerCantidadDisponible(
  const ACodigoSku, ACodigoAlmacen: string): Double;
begin
  Inc(FConsultasCantidad);
  Result := FCantidad;
end;

procedure TPruebasCajaStock.SkuInexistenteNoConsultaCantidad;
var
  oParametros: TParametrosCajaFalsos;
  oPersistencia: TCajaStockPersistenciaFalsa;
  oPolitica: IPoliticaStockVenta;
  oResultado: TResultadoPoliticaStockVenta;
begin
  oParametros := TParametrosCajaFalsos.Create;
  oParametros.FVerificarExistencia := True;
  oPersistencia := TCajaStockPersistenciaFalsa.Create;
  oPersistencia.FEstado.Existe := False;
  oPolitica := TPoliticaStockVenta.Create(oPersistencia, oParametros);
  oResultado := oPolitica.Validar('SKU-1', 'ALM-1');
  Assert.IsFalse(oResultado.Permitida);
  Assert.IsTrue(oResultado.Motivo = msvSkuNoExiste);
  Assert.AreEqual(1, oPersistencia.FConsultasEstado);
  Assert.AreEqual(0, oPersistencia.FConsultasCantidad);
end;

procedure TPruebasCajaStock.AvisoSinStockPermiteVentaYConservaMensaje;
var
  oParametros: TParametrosCajaFalsos;
  oPersistencia: TCajaStockPersistenciaFalsa;
  oPolitica: IPoliticaStockVenta;
  oResultado: TResultadoPoliticaStockVenta;
begin
  oParametros := TParametrosCajaFalsos.Create;
  oParametros.FMensajeStock := 'Sin existencias disponibles';
  oPersistencia := TCajaStockPersistenciaFalsa.Create;
  oPersistencia.FEstado.Existe := True;
  oPersistencia.FEstado.Activo := True;
  oPolitica := TPoliticaStockVenta.Create(oPersistencia, oParametros);
  oResultado := oPolitica.Validar('SKU-1', 'ALM-1');
  Assert.IsTrue(oResultado.Permitida);
  Assert.IsTrue(oResultado.Motivo = msvSinStock);
  Assert.AreEqual('Sin existencias disponibles', oResultado.Mensaje);
end;

procedure TPruebasCajaStock.ValidacionRepetidaConservaElResultado;
var
  oParametros: TParametrosCajaFalsos;
  oPersistencia: TCajaStockPersistenciaFalsa;
  oPolitica: IPoliticaStockVenta;
  oPrimero: TResultadoPoliticaStockVenta;
  oSegundo: TResultadoPoliticaStockVenta;
begin
  oParametros := TParametrosCajaFalsos.Create;
  oParametros.FVerificarExistencia := True;
  oParametros.FBloquearSinStock := True;
  oPersistencia := TCajaStockPersistenciaFalsa.Create;
  oPersistencia.FEstado.Existe := True;
  oPersistencia.FEstado.Activo := True;
  oPersistencia.FCantidad := 3;
  oPolitica := TPoliticaStockVenta.Create(oPersistencia, oParametros);
  oPrimero := oPolitica.Validar('SKU-1', 'ALM-1');
  oSegundo := oPolitica.Validar('SKU-1', 'ALM-1');
  Assert.AreEqual(oPrimero.Permitida, oSegundo.Permitida);
  Assert.IsTrue(oPrimero.Motivo = oSegundo.Motivo);
  Assert.AreEqual(oPrimero.Mensaje, oSegundo.Mensaje);
  Assert.AreEqual(2, oPersistencia.FConsultasEstado);
  Assert.AreEqual(2, oPersistencia.FConsultasCantidad);
end;

procedure TPruebasCajaStock.CodigoVacioNoConsultaPersistencia;
var
  oParametros: TParametrosCajaFalsos;
  oPersistencia: TCajaStockPersistenciaFalsa;
  oPolitica: IPoliticaStockVenta;
  oResultado: TResultadoPoliticaStockVenta;
begin
  oParametros := TParametrosCajaFalsos.Create;
  oPersistencia := TCajaStockPersistenciaFalsa.Create;
  oPolitica := TPoliticaStockVenta.Create(oPersistencia, oParametros);
  oResultado := oPolitica.Validar('  ', 'ALM-1');
  Assert.IsTrue(oResultado.Permitida);
  Assert.AreEqual(0, oPersistencia.FConsultasEstado);
  Assert.AreEqual(0, oPersistencia.FConsultasCantidad);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCajaStock);

end.
