{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasAplicacion                                     }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica los colaboradores por capacidad de facturas.                    }
{******************************************************************************}
unit PruebasFacturasAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasAplicacion = class
  public
    [Test]
    procedure Consolidacion_OrquestaCasoUsoYVista;
    [Test]
    procedure OperacionFiscal_NoEmiteFacturaNoConsolidada;
    [Test]
    procedure Cobros_DelegaSolicitudCompleta;
    [Test]
    procedure Estado_BorradorPermiteEditarYConsolidar;
    [Test]
    procedure ModoEntrada_CiclaSinConocerFormulario;
    [Test]
    procedure Inyeccion_SinListadoFallaAlPreparar;
    [Test]
    procedure Inyeccion_SinLineasFallaAlPreparar;
    [Test]
    procedure InyeccionUniDAC_SinConexionFallaAlPreparar;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibEmisionFiscalIntf,
  inLibFacturasAplicacion,
  inLibFacturasAplicacionIntf,
  inLibFacturasOperacionFiscal,
  inLibFacturasInyeccion,
  inLibFacturasPresentadorListado,
  inLibFacturasServiciosIntf,
  inLibVerifactuTipos,
  UniDataFacturasInyeccion;

type
  TVistaFacturaPrueba = class(TInterfacedObject, IVistaFactura)
  private
    FArchivada: Boolean;
    FConfirmar: Boolean;
    FError: string;
    FEstado: TEstadoVisualFactura;
    FInformacion: string;
    FModo: TModoEntradaFactura;
    FRefrescosFactura: Integer;
    FRefrescosMovimientos: Integer;
  public
    function Confirmar(const APregunta: string): Boolean;
    procedure MostrarInformacion(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure RefrescarFactura;
    procedure RefrescarMovimientos;
    procedure ArchivarFactura(const ASerie, ANumero: string);
    procedure AplicarEstado(const AEstado: TEstadoVisualFactura);
    procedure AplicarModoEntrada(AModo: TModoEntradaFactura);
    property Archivada: Boolean read FArchivada;
    property ConfirmarRespuesta: Boolean read FConfirmar write FConfirmar;
    property Error: string read FError;
    property Estado: TEstadoVisualFactura read FEstado;
    property Informacion: string read FInformacion;
    property Modo: TModoEntradaFactura read FModo;
    property RefrescosFactura: Integer read FRefrescosFactura;
    property RefrescosMovimientos: Integer read FRefrescosMovimientos;
  end;
  TCasoUsoConsolidacionPrueba = class(
    TInterfacedObject,
    ICasoUsoConsolidacionFactura)
  private
    FEjecutado: Boolean;
    FNumero: string;
    FSerie: string;
    FUsuario: string;
  public
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    function Consolidar(
      const ASerie, ANumero, AUsuario: string
    ): TResultadoConsolidacionFactura;
    property Ejecutado: Boolean read FEjecutado;
    property Numero: string read FNumero;
    property Serie: string read FSerie;
    property Usuario: string read FUsuario;
  end;
  TServicioEmisionFiscalAplicacionPrueba = class(
    TInterfacedObject,
    IServicioEmisionFiscal)
  private
    FInvocado: Boolean;
  public
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
    property Invocado: Boolean read FInvocado;
  end;
  TServicioEfectosAplicacionPrueba = class(
    TInterfacedObject,
    IServicioEfectosFactura)
  private
    FSolicitudSerie: string;
    FSolicitudNumero: string;
    FSolicitudUsuario: string;
  public
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
    property SolicitudNumero: string read FSolicitudNumero;
    property SolicitudSerie: string read FSolicitudSerie;
    property SolicitudUsuario: string read FSolicitudUsuario;
  end;
  TPreparadorListadoFacturasPrueba = class(
    TInterfacedObject,
    IPreparadorListadoFacturas)
  public
    function EstadoColaDisponible(out AMensaje: string): Boolean;
    procedure PrepararListado(
      AConsulta: TDataSet;
      const AVista: string;
      AIncluirEstadoCola: Boolean);
  end;

function TPreparadorListadoFacturasPrueba.EstadoColaDisponible(
  out AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
end;

procedure TPreparadorListadoFacturasPrueba.PrepararListado(
  AConsulta: TDataSet;
  const AVista: string;
  AIncluirEstadoCola: Boolean);
begin
end;

function TVistaFacturaPrueba.Confirmar(
  const APregunta: string): Boolean;
begin
  Result := FConfirmar;
end;

procedure TVistaFacturaPrueba.MostrarInformacion(
  const AMensaje: string);
begin
  FInformacion := AMensaje;
end;

procedure TVistaFacturaPrueba.MostrarError(
  const AMensaje: string);
begin
  FError := AMensaje;
end;

procedure TVistaFacturaPrueba.RefrescarFactura;
begin
  Inc(FRefrescosFactura);
end;

procedure TVistaFacturaPrueba.RefrescarMovimientos;
begin
  Inc(FRefrescosMovimientos);
end;

procedure TVistaFacturaPrueba.ArchivarFactura(
  const ASerie, ANumero: string);
begin
  FArchivada := True;
end;

procedure TVistaFacturaPrueba.AplicarEstado(
  const AEstado: TEstadoVisualFactura);
begin
  FEstado := AEstado;
end;

procedure TVistaFacturaPrueba.AplicarModoEntrada(
  AModo: TModoEntradaFactura);
begin
  FModo := AModo;
end;

function TCasoUsoConsolidacionPrueba.Validar(
  const ASerie, ANumero: string
): TResultadoOperacionFactura;
begin
  Result := TResultadoOperacionFactura.Correcto;
end;

function TCasoUsoConsolidacionPrueba.Consolidar(
  const ASerie, ANumero, AUsuario: string
): TResultadoConsolidacionFactura;
begin
  FEjecutado := True;
  FSerie := ASerie;
  FNumero := ANumero;
  FUsuario := AUsuario;
  Result := Default(TResultadoConsolidacionFactura);
  Result.MensajeFiscal := 'Factura consolidada';
end;

function TServicioEmisionFiscalAplicacionPrueba.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal
): TResultadoEmisionFiscal;
begin
  FInvocado := True;
  Result := Default(TResultadoEmisionFiscal);
  Result.Mensaje := 'Emitida';
end;

function TServicioEmisionFiscalAplicacionPrueba.Modo: TModoVerifactu;
begin
  Result := mvVerifactu;
end;

procedure TServicioEfectosAplicacionPrueba.EstamparBancoRecibos(
  const ASerie, ANumero, ACodigoBanco, AIban: string);
begin
  FSolicitudSerie := ASerie;
  FSolicitudNumero := ANumero;
end;

function TServicioEfectosAplicacionPrueba.BancoDefectoCliente(
  const ACodigoCliente: string): string;
begin
  Result := 'BANCO';
end;

function TServicioEfectosAplicacionPrueba.Generar(
  const ASerie, ANumero, AUsuario,
  ACodigoBanco, AIban: string): Integer;
begin
  FSolicitudSerie := ASerie;
  FSolicitudNumero := ANumero;
  FSolicitudUsuario := AUsuario;
  Result := 2;
end;

function TServicioEfectosAplicacionPrueba.RegistrarCobro(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  AFecha: TDateTime;
  AImporte: Double;
  const ATipo, AReferencia: string): Integer;
begin
  FSolicitudSerie := ASerie;
  FSolicitudNumero := ANumero;
  FSolicitudUsuario := AUsuario;
  Result := 1;
end;

function TServicioEfectosAplicacionPrueba.CambiarEstado(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  const AEstado: string): Boolean;
begin
  FSolicitudSerie := ASerie;
  FSolicitudNumero := ANumero;
  FSolicitudUsuario := AUsuario;
  Result := True;
end;

procedure TPruebasFacturasAplicacion.Consolidacion_OrquestaCasoUsoYVista;
var
  Aplicacion: IAplicacionConsolidacionFactura;
  CasoUso: TCasoUsoConsolidacionPrueba;
  Vista: TVistaFacturaPrueba;
begin
  CasoUso := TCasoUsoConsolidacionPrueba.Create;
  Vista := TVistaFacturaPrueba.Create;
  Vista.ConfirmarRespuesta := True;
  Aplicacion := CrearAplicacionConsolidacionFactura(CasoUso, Vista);
  Aplicacion.Ejecutar('F', '42', 'USUARIO');
  Assert.IsTrue(CasoUso.Ejecutado);
  Assert.AreEqual('F', CasoUso.Serie);
  Assert.AreEqual('42', CasoUso.Numero);
  Assert.AreEqual('USUARIO', CasoUso.Usuario);
  Assert.AreEqual(1, Vista.RefrescosFactura);
  Assert.AreEqual(1, Vista.RefrescosMovimientos);
  Assert.IsTrue(Vista.Archivada);
  Assert.AreEqual('Factura consolidada', Vista.Informacion);
end;

procedure TPruebasFacturasAplicacion.
  OperacionFiscal_NoEmiteFacturaNoConsolidada;
var
  Aplicacion: IAplicacionOperacionFiscalFactura;
  Contexto: TContextoOperacionFiscalFactura;
  Servicio: TServicioEmisionFiscalAplicacionPrueba;
  Vista: TVistaFacturaPrueba;
begin
  Servicio := TServicioEmisionFiscalAplicacionPrueba.Create;
  Vista := TVistaFacturaPrueba.Create;
  Aplicacion := CrearAplicacionOperacionFiscalFactura(Servicio, Vista);
  Contexto := Default(TContextoOperacionFiscalFactura);
  Contexto.Serie := 'F';
  Contexto.Numero := '42';
  Contexto.Accion := 'Anular';
  Contexto.Consolidada := False;
  Aplicacion.Ejecutar(Contexto);
  Assert.IsFalse(Servicio.Invocado);
  Assert.IsNotEmpty(Vista.Error);
  Assert.AreEqual(0, Vista.RefrescosFactura);
end;

procedure TPruebasFacturasAplicacion.Cobros_DelegaSolicitudCompleta;
var
  Aplicacion: IAplicacionCobrosFactura;
  Servicio: TServicioEfectosAplicacionPrueba;
  Solicitud: TSolicitudGeneracionCobrosFactura;
begin
  Servicio := TServicioEfectosAplicacionPrueba.Create;
  Aplicacion := CrearAplicacionCobrosFactura(Servicio);
  Solicitud := Default(TSolicitudGeneracionCobrosFactura);
  Solicitud.Serie := 'F';
  Solicitud.Numero := '42';
  Solicitud.Usuario := 'USUARIO';
  Assert.AreEqual(2, Aplicacion.Generar(Solicitud));
  Assert.AreEqual('F', Servicio.SolicitudSerie);
  Assert.AreEqual('42', Servicio.SolicitudNumero);
  Assert.AreEqual('USUARIO', Servicio.SolicitudUsuario);
end;

procedure TPruebasFacturasAplicacion.
  Estado_BorradorPermiteEditarYConsolidar;
var
  Presentador: IPresentadorEstadoFactura;
  Solicitud: TSolicitudEstadoFactura;
  Vista: TVistaFacturaPrueba;
begin
  Vista := TVistaFacturaPrueba.Create;
  Presentador := CrearPresentadorEstadoFactura(Vista);
  Solicitud := Default(TSolicitudEstadoFactura);
  Solicitud.Fase := 'BORRADOR';
  Solicitud.EstadoDatos := edfConsultando;
  Presentador.Presentar(Solicitud);
  Assert.IsTrue(Vista.Estado.Editable);
  Assert.IsTrue(Vista.Estado.PuedeConsolidar);
  Assert.IsFalse(Vista.Estado.PuedeImprimir);
end;

procedure TPruebasFacturasAplicacion.
  ModoEntrada_CiclaSinConocerFormulario;
var
  Gestor: IGestorModoEntradaFactura;
  Vista: TVistaFacturaPrueba;
begin
  Vista := TVistaFacturaPrueba.Create;
  Gestor := CrearGestorModoEntradaFactura(Vista, mefAutomatico);
  Gestor.SeleccionarSiguiente;
  Assert.AreEqual(Ord(mefSku), Ord(Gestor.ModoActual));
  Assert.AreEqual(Ord(mefSku), Ord(Vista.Modo));
  Gestor.SeleccionarSiguiente;
  Assert.AreEqual(Ord(mefTallas), Ord(Vista.Modo));
end;

procedure TPruebasFacturasAplicacion.
  Inyeccion_SinListadoFallaAlPreparar;
var
  Dependencias: TDependenciasFacturas;
begin
  Dependencias := Default(TDependenciasFacturas);
  Assert.WillRaise(
    procedure
    begin
      Dependencias.Validar;
    end,
    EArgumentNilException);
end;

procedure TPruebasFacturasAplicacion.
  Inyeccion_SinLineasFallaAlPreparar;
var
  Dependencias: TDependenciasFacturas;
begin
  Dependencias := Default(TDependenciasFacturas);
  Dependencias.Listado := TPreparadorListadoFacturasPrueba.Create;
  Assert.WillRaise(
    procedure
    begin
      Dependencias.Validar;
    end,
    EArgumentNilException);
end;

procedure TPruebasFacturasAplicacion.
  InyeccionUniDAC_SinConexionFallaAlPreparar;
var
  Contexto: TContextoFacturasUniDAC;
begin
  Contexto := Default(TContextoFacturasUniDAC);
  Assert.WillRaise(
    procedure
    begin
      Contexto.Validar;
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasAplicacion);

end.
