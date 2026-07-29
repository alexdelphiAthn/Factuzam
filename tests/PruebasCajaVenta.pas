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
    [Test]
    procedure Rectificacion_DiferenciasCopiaClienteYNiegaLineas;
    [Test]
    procedure Rectificacion_SustitutivaMantieneLineasPositivas;
  end;

implementation

uses
  System.Classes, Data.DB, Datasnap.DBClient,
  inLibCajaTipos, inLibCajaVentaIntf,
  inLibCajaDescuentos, inLibCajaCierreVenta,
  inLibCajaRectificacion;

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
  TResultadoConsultaCajaFalso = class(
    TInterfacedObject,
    IResultadoConsultaCaja)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;
  TRepositorioConsultasCajaFalso = class(
    TInterfacedObject,
    IRepositorioConsultasCaja)
  private
    function CrearCabecera: TClientDataSet;
    function CrearLineas: TClientDataSet;
  public
    function ConsultarStock(
      const ACodigoArticulo: string): IResultadoConsultaCaja;
    function ConsultarClientes: IResultadoConsultaCaja;
    function ConsultarEmpleados: IResultadoConsultaCaja;
    function BuscarEmpleado(
      const ATexto: string;
      out AEmpleado: TEmpleadoCaja): Boolean;
    function ObtenerCliente(
      const ACodigo: string;
      out ACliente: TClienteCaja): Boolean;
    function ConsultarCabeceraFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
    function ConsultarLineasFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
  end;

constructor TResultadoConsultaCajaFalso.Create(
  ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoConsultaCajaFalso.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TResultadoConsultaCajaFalso.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

function TRepositorioConsultasCajaFalso.CrearCabecera:
  TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add(
    'CODIGO_CLI_FAC',
    ftString,
    20);
  Result.FieldDefs.Add(
    'RAZON_SOCIAL_CLIENTE_FAC',
    ftString,
    100);
  Result.CreateDataSet;
  Result.Append;
  Result.FieldByName('CODIGO_CLI_FAC').AsString := 'C1';
  Result.FieldByName(
    'RAZON_SOCIAL_CLIENTE_FAC').AsString :=
    'Cliente original';
  Result.Post;
end;

function TRepositorioConsultasCajaFalso.CrearLineas:
  TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add(
    'LINEA_FACLIN',
    ftInteger);
  Result.FieldDefs.Add(
    'CANTIDAD_FACLIN',
    ftFloat);
  Result.FieldDefs.Add(
    'TOTAL_FACLIN',
    ftCurrency);
  Result.FieldDefs.Add(
    'TOTAL_FAC_SIVA_FACLIN',
    ftCurrency);
  Result.CreateDataSet;
  Result.Append;
  Result.FieldByName('LINEA_FACLIN').AsInteger := 1;
  Result.FieldByName('CANTIDAD_FACLIN').AsFloat := 2;
  Result.FieldByName('TOTAL_FACLIN').AsCurrency := 24.2;
  Result.FieldByName(
    'TOTAL_FAC_SIVA_FACLIN').AsCurrency := 20;
  Result.Post;
end;

function TRepositorioConsultasCajaFalso.ConsultarStock(
  const ACodigoArticulo: string): IResultadoConsultaCaja;
begin
  Result := nil;
end;

function TRepositorioConsultasCajaFalso.ConsultarClientes:
  IResultadoConsultaCaja;
begin
  Result := nil;
end;

function TRepositorioConsultasCajaFalso.ConsultarEmpleados:
  IResultadoConsultaCaja;
begin
  Result := nil;
end;

function TRepositorioConsultasCajaFalso.BuscarEmpleado(
  const ATexto: string;
  out AEmpleado: TEmpleadoCaja): Boolean;
begin
  AEmpleado := Default(TEmpleadoCaja);
  Result := False;
end;

function TRepositorioConsultasCajaFalso.ObtenerCliente(
  const ACodigo: string;
  out ACliente: TClienteCaja): Boolean;
begin
  ACliente := Default(TClienteCaja);
  Result := False;
end;

function TRepositorioConsultasCajaFalso.ConsultarCabeceraFactura(
  const ASerie, ANumero: string): IResultadoConsultaCaja;
begin
  Result := TResultadoConsultaCajaFalso.Create(
    CrearCabecera);
end;

function TRepositorioConsultasCajaFalso.ConsultarLineasFactura(
  const ASerie, ANumero: string): IResultadoConsultaCaja;
begin
  Result := TResultadoConsultaCajaFalso.Create(
    CrearLineas);
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

procedure CrearDatosRectificacionDestino(
  out ACabecera, ALineas: TClientDataSet);
begin
  ACabecera := TClientDataSet.Create(nil);
  ALineas := TClientDataSet.Create(nil);
  ACabecera.FieldDefs.Add(
    'CODIGO_CLI_FAC',
    ftString,
    20);
  ACabecera.FieldDefs.Add(
    'RAZON_SOCIAL_CLIENTE_FAC',
    ftString,
    100);
  ACabecera.CreateDataSet;
  ACabecera.Append;
  ALineas.FieldDefs.Add(
    'LINEA_FACLIN',
    ftInteger);
  ALineas.FieldDefs.Add(
    'CANTIDAD_FACLIN',
    ftFloat);
  ALineas.FieldDefs.Add(
    'TOTAL_FACLIN',
    ftCurrency);
  ALineas.FieldDefs.Add(
    'TOTAL_FAC_SIVA_FACLIN',
    ftCurrency);
  ALineas.CreateDataSet;
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

procedure TPruebasCajaVenta.
  Rectificacion_DiferenciasCopiaClienteYNiegaLineas;
var
  Repositorio: IRepositorioConsultasCaja;
  Servicio: IServicioRectificacionCaja;
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Resultado: TResultadoRectificacionCaja;
begin
  Repositorio := TRepositorioConsultasCajaFalso.Create;
  Servicio := TServicioRectificacionCaja.Create(
    Repositorio);
  CrearDatosRectificacionDestino(
    Cabecera,
    Lineas);
  try
    Resultado := Servicio.Cargar(
      'T',
      '1',
      trcDiferencias,
      tmrMantenerOriginales,
      Cabecera,
      Lineas);
    Assert.AreEqual(
      'C1',
      Cabecera.FieldByName(
        'CODIGO_CLI_FAC').AsString);
    Assert.AreEqual(
      'Cliente original',
      Cabecera.FieldByName(
        'RAZON_SOCIAL_CLIENTE_FAC').AsString);
    Assert.AreEqual(
      -2.0,
      Lineas.FieldByName(
        'CANTIDAD_FACLIN').AsFloat,
      0.0001);
    Assert.AreEqual(
      -24.2,
      Double(
        Lineas.FieldByName(
          'TOTAL_FACLIN').AsCurrency),
      0.0001);
    Assert.AreEqual(
      'POR DIFERENCIAS',
      Resultado.DescripcionTipo);
  finally
    Cabecera.Free;
    Lineas.Free;
  end;
end;

procedure TPruebasCajaVenta.
  Rectificacion_SustitutivaMantieneLineasPositivas;
var
  Repositorio: IRepositorioConsultasCaja;
  Servicio: IServicioRectificacionCaja;
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Resultado: TResultadoRectificacionCaja;
begin
  Repositorio := TRepositorioConsultasCajaFalso.Create;
  Servicio := TServicioRectificacionCaja.Create(
    Repositorio);
  CrearDatosRectificacionDestino(
    Cabecera,
    Lineas);
  try
    Resultado := Servicio.Cargar(
      'T',
      '1',
      trcSustitutiva,
      tmrReemplazarOriginales,
      Cabecera,
      Lineas);
    Assert.AreEqual(
      2.0,
      Lineas.FieldByName(
        'CANTIDAD_FACLIN').AsFloat,
      0.0001);
    Assert.AreEqual(
      'SUSTITUTIVA',
      Resultado.DescripcionTipo);
    Assert.IsTrue(
      Resultado.TratamientoMovimientos =
        tmrReemplazarOriginales);
  finally
    Cabecera.Free;
    Lineas.Free;
  end;
end;

end.
