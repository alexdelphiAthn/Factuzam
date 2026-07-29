{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCajaVenta                                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de políticas y servicios extraídos de la operativa de caja.       }
{******************************************************************************}
unit PruebasCajaVenta;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCajaVenta = class
  public
    [Test]
    procedure Stock_SkuInexistenteBloquea;
    [Test]
    procedure Stock_AvisoSinExistenciasPermiteVenta;
    [Test]
    procedure Stock_BloqueoSinExistenciasImpideVenta;
    [Test]
    procedure Descuento_ReparteYCuadraElUltimoCentimo;
    [Test]
    procedure Cierre_GrabaAntesDeImprimir;
  end;

implementation

uses
  System.Classes, inLibCajaTipos, inLibCajaVentaIntf,
  inLibCajaDescuentos, inLibCajaCierreVenta;

type
  TGrabadorVentaFalso = class(
    TInterfacedObject,
    IGrabadorVentaCaja)
  private
    FGrabado: Boolean;
  public
    function GrabarVenta(
      const ASolicitud: TSolicitudGrabacionVenta;
      out ANumeroGenerado, ACodigoValeGenerado: string
    ): Boolean;
    function UltimaSerieFacturaGrabada: string;
    function UltimoNumeroFacturaGrabada: string;
    function SerieFacturaImpresion: string;
    function NumeroFacturaImpresion: string;
    property Grabado: Boolean read FGrabado;
  end;
  TImpresorVentaFalso = class(
    TInterfacedObject,
    IImpresorVenta)
  private
    FGrabador: TGrabadorVentaFalso;
    FImpreso: Boolean;
    FGrabadoAntesDeImprimir: Boolean;
  public
    constructor Create(AGrabador: TGrabadorVentaFalso);
    procedure Imprimir(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
    procedure GenerarPdfRespaldo(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
    property Impreso: Boolean read FImpreso;
    property GrabadoAntesDeImprimir: Boolean
      read FGrabadoAntesDeImprimir;
  end;

function TGrabadorVentaFalso.GrabarVenta(
  const ASolicitud: TSolicitudGrabacionVenta;
  out ANumeroGenerado, ACodigoValeGenerado: string
): Boolean;
begin
  FGrabado := True;
  ANumeroGenerado := '000001';
  ACodigoValeGenerado := 'VALE-1';
  Result := True;
end;

function TGrabadorVentaFalso.UltimaSerieFacturaGrabada: string;
begin
  Result := 'T';
end;

function TGrabadorVentaFalso.UltimoNumeroFacturaGrabada: string;
begin
  Result := '000001';
end;

function TGrabadorVentaFalso.SerieFacturaImpresion: string;
begin
  Result := 'T';
end;

function TGrabadorVentaFalso.NumeroFacturaImpresion: string;
begin
  Result := '000001';
end;

constructor TImpresorVentaFalso.Create(
  AGrabador: TGrabadorVentaFalso);
begin
  inherited Create;
  FGrabador := AGrabador;
end;

procedure TImpresorVentaFalso.Imprimir(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings);
begin
  FImpreso := True;
  FGrabadoAntesDeImprimir := FGrabador.Grabado;
end;

procedure TImpresorVentaFalso.GenerarPdfRespaldo(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings);
begin
end;

procedure TPruebasCajaVenta.Stock_SkuInexistenteBloquea;
var
  Entrada: TEntradaPoliticaStockVenta;
  Resultado: TResultadoPoliticaStockVenta;
begin
  Entrada := Default(TEntradaPoliticaStockVenta);
  Entrada.VerificarExistencia := True;
  Entrada.Existe := False;
  Resultado := EvaluarPoliticaStockVenta(Entrada);
  Assert.IsFalse(Resultado.Permitida);
  Assert.IsTrue(Resultado.Motivo = msvSkuNoExiste);
end;

procedure TPruebasCajaVenta.Stock_AvisoSinExistenciasPermiteVenta;
var
  Entrada: TEntradaPoliticaStockVenta;
  Resultado: TResultadoPoliticaStockVenta;
begin
  Entrada := Default(TEntradaPoliticaStockVenta);
  Entrada.Existe := True;
  Entrada.Activo := True;
  Entrada.VerificarStock := True;
  Entrada.BloquearSinStock := False;
  Entrada.CantidadDisponible := 0;
  Resultado := EvaluarPoliticaStockVenta(Entrada);
  Assert.IsTrue(Resultado.Permitida);
  Assert.IsTrue(Resultado.Motivo = msvSinStock);
end;

procedure TPruebasCajaVenta.Stock_BloqueoSinExistenciasImpideVenta;
var
  Entrada: TEntradaPoliticaStockVenta;
  Resultado: TResultadoPoliticaStockVenta;
begin
  Entrada := Default(TEntradaPoliticaStockVenta);
  Entrada.Existe := True;
  Entrada.Activo := True;
  Entrada.VerificarStock := True;
  Entrada.BloquearSinStock := True;
  Entrada.CantidadDisponible := 0;
  Resultado := EvaluarPoliticaStockVenta(Entrada);
  Assert.IsFalse(Resultado.Permitida);
  Assert.IsTrue(Resultado.Motivo = msvSinStock);
end;

procedure TPruebasCajaVenta.Descuento_ReparteYCuadraElUltimoCentimo;
var
  Repartidor: IRepartidorDescuento;
  Lineas: TArray<TLineaRepartoDescuento>;
  Resultado: TArray<TResultadoLineaDescuento>;
begin
  Repartidor := TRepartidorDescuento.Create;
  SetLength(Lineas, 3);
  Lineas[0].Cantidad := 1;
  Lineas[0].PrecioSalida := 10;
  Lineas[1].Cantidad := 1;
  Lineas[1].PrecioSalida := 10;
  Lineas[2].Cantidad := 1;
  Lineas[2].PrecioSalida := 10;
  Resultado := Repartidor.Repartir(Lineas, 1);
  Assert.IsTrue(Length(Resultado) = 3);
  Assert.AreEqual(0.33, Double(Resultado[0].ImporteDescuento), 0.0001);
  Assert.AreEqual(0.33, Double(Resultado[1].ImporteDescuento), 0.0001);
  Assert.AreEqual(0.34, Double(Resultado[2].ImporteDescuento), 0.0001);
end;

procedure TPruebasCajaVenta.Cierre_GrabaAntesDeImprimir;
var
  GrabadorObjeto: TGrabadorVentaFalso;
  ImpresorObjeto: TImpresorVentaFalso;
  Grabador: IGrabadorVentaCaja;
  Impresor: IImpresorVenta;
  Servicio: IServicioCierreVenta;
  Solicitud: TSolicitudCierreVenta;
  Resultado: TResultadoCierreVenta;
begin
  GrabadorObjeto := TGrabadorVentaFalso.Create;
  Grabador := GrabadorObjeto;
  ImpresorObjeto := TImpresorVentaFalso.Create(GrabadorObjeto);
  Impresor := ImpresorObjeto;
  Servicio := TServicioCierreVenta.Create(
    Grabador,
    Impresor,
    nil,
    nil,
    nil);
  Solicitud := Default(TSolicitudCierreVenta);
  Solicitud.TipoImpresion := tiConTicket;
  Resultado := Servicio.Ejecutar(Solicitud);
  Assert.IsTrue(Resultado.Grabada);
  Assert.AreEqual('000001', Resultado.NumeroGenerado);
  Assert.AreEqual('VALE-1', Resultado.CodigoValeGenerado);
  Assert.IsTrue(ImpresorObjeto.Impreso);
  Assert.IsTrue(ImpresorObjeto.GrabadoAntesDeImprimir);
end;

end.
