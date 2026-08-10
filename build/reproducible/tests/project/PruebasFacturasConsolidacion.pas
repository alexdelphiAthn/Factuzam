{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasConsolidacion                                  }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la frontera transaccional del caso de uso de consolidación.      }
{******************************************************************************}
unit PruebasFacturasConsolidacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasConsolidacion = class
  public
    [Test]
    procedure Validar_ConsultaSinBloqueoNiUnidadTrabajo;
    [Test]
    procedure Consolidar_EjecutaDentroDeUnidadTrabajo;
    [Test]
    procedure Consolidar_DatoInvalidoCancelaUnidadTrabajo;
  end;

implementation

uses
  System.SysUtils,
  inLibFacturasConsolidacion,
  inLibFacturasPersistenciaIntf,
  inLibFacturasServiciosIntf,
  inLibEmisionFiscalIntf,
  inLibVerifactuTipos;

type
  TUnidadTrabajoFacturasPrueba = class(
    TInterfacedObject,
    IUnidadTrabajoFacturas)
  private
    FEjecutada: Boolean;
    FCompletada: Boolean;
    FCancelada: Boolean;
  public
    procedure Ejecutar(const ATrabajo: TProc);
    property Ejecutada: Boolean read FEjecutada;
    property Completada: Boolean read FCompletada;
    property Cancelada: Boolean read FCancelada;
  end;
  TRepositorioConsolidacionPrueba = class(
    TInterfacedObject,
    IRepositorioConsolidacionFactura)
  private
    FDatos: TDatosFacturaConsolidacion;
    FBloqueada: Boolean;
    FNumero: string;
    FSerie: string;
  public
    function CargarDatosConsolidacion(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosFacturaConsolidacion;
    property Datos: TDatosFacturaConsolidacion read FDatos write FDatos;
    property Bloqueada: Boolean read FBloqueada;
    property Numero: string read FNumero;
    property Serie: string read FSerie;
  end;
  TServicioEmisionFiscalPrueba = class(
    TInterfacedObject,
    IServicioEmisionFiscal)
  private
    FInvocado: Boolean;
    FMensaje: string;
    FSolicitud: TSolicitudEmisionFiscal;
  public
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
    property Invocado: Boolean read FInvocado;
    property Mensaje: string read FMensaje write FMensaje;
    property Solicitud: TSolicitudEmisionFiscal read FSolicitud;
  end;
  TServicioMovimientosFacturaPrueba = class(
    TInterfacedObject,
    IServicioMovimientosFactura)
  private
    FInvocado: Boolean;
    FCantidad: Integer;
    FSolicitud: TSolicitudMovimientosFactura;
  public
    function GenerarSalidas(
      const ASolicitud: TSolicitudMovimientosFactura): Integer;
    property Invocado: Boolean read FInvocado;
    property Cantidad: Integer read FCantidad write FCantidad;
    property Solicitud: TSolicitudMovimientosFactura read FSolicitud;
  end;

procedure TUnidadTrabajoFacturasPrueba.Ejecutar(
  const ATrabajo: TProc);
begin
  FEjecutada := True;
  try
    ATrabajo();
    FCompletada := True;
  except
    FCancelada := True;
    raise;
  end;
end;

function TRepositorioConsolidacionPrueba.CargarDatosConsolidacion(
  const ASerie, ANumero: string;
  ABloquear: Boolean): TDatosFacturaConsolidacion;
begin
  FSerie := ASerie;
  FNumero := ANumero;
  FBloqueada := ABloquear;
  Result := FDatos;
end;

function TServicioEmisionFiscalPrueba.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal
): TResultadoEmisionFiscal;
begin
  FInvocado := True;
  FSolicitud := ASolicitud;
  Result := Default(TResultadoEmisionFiscal);
  Result.Mensaje := FMensaje;
end;

function TServicioEmisionFiscalPrueba.Modo: TModoVerifactu;
begin
  Result := mvSinVerifactu;
end;

function TServicioMovimientosFacturaPrueba.GenerarSalidas(
  const ASolicitud: TSolicitudMovimientosFactura): Integer;
begin
  FInvocado := True;
  FSolicitud := ASolicitud;
  Result := FCantidad;
end;

function CrearDatosValidos: TDatosFacturaConsolidacion;
begin
  Result := Default(TDatosFacturaConsolidacion);
  Result.Encontrada := True;
  Result.Fase := 'BORRADOR';
  Result.TipoFactura := 'NORMAL';
  Result.NifCliente := '12345678Z';
  Result.Empresa := 'EMP';
  Result.Cliente := 'CLI';
  Result.Caja := 'CAJA';
  Result.NumeroOperacion := 'OPE';
  Result.MueveStock := True;
  Result.NumeroLineas := 1;
end;

procedure TPruebasFacturasConsolidacion.
  Validar_ConsultaSinBloqueoNiUnidadTrabajo;
var
  oCasoUso: ICasoUsoConsolidacionFactura;
  oEmision: TServicioEmisionFiscalPrueba;
  oMovimientos: TServicioMovimientosFacturaPrueba;
  oRepositorio: TRepositorioConsolidacionPrueba;
  oUnidadTrabajo: TUnidadTrabajoFacturasPrueba;
  oResultado: TResultadoOperacionFactura;
begin
  oUnidadTrabajo := TUnidadTrabajoFacturasPrueba.Create;
  oRepositorio := TRepositorioConsolidacionPrueba.Create;
  oRepositorio.Datos := CrearDatosValidos;
  oEmision := TServicioEmisionFiscalPrueba.Create;
  oMovimientos := TServicioMovimientosFacturaPrueba.Create;
  oCasoUso := CrearCasoUsoConsolidacionFactura(
    oUnidadTrabajo,
    oRepositorio,
    oEmision,
    oMovimientos);
  oResultado := oCasoUso.Validar('F', '42');
  Assert.IsTrue(oResultado.Exito);
  Assert.IsFalse(oRepositorio.Bloqueada);
  Assert.IsFalse(oUnidadTrabajo.Ejecutada);
end;

procedure TPruebasFacturasConsolidacion.
  Consolidar_EjecutaDentroDeUnidadTrabajo;
var
  oCasoUso: ICasoUsoConsolidacionFactura;
  oEmision: TServicioEmisionFiscalPrueba;
  oMovimientos: TServicioMovimientosFacturaPrueba;
  oRepositorio: TRepositorioConsolidacionPrueba;
  oUnidadTrabajo: TUnidadTrabajoFacturasPrueba;
  oResultado: TResultadoConsolidacionFactura;
begin
  oUnidadTrabajo := TUnidadTrabajoFacturasPrueba.Create;
  oRepositorio := TRepositorioConsolidacionPrueba.Create;
  oRepositorio.Datos := CrearDatosValidos;
  oEmision := TServicioEmisionFiscalPrueba.Create;
  oEmision.Mensaje := 'Factura consolidada';
  oMovimientos := TServicioMovimientosFacturaPrueba.Create;
  oMovimientos.Cantidad := 3;
  oCasoUso := CrearCasoUsoConsolidacionFactura(
    oUnidadTrabajo,
    oRepositorio,
    oEmision,
    oMovimientos);
  oResultado := oCasoUso.Consolidar('F', '42', 'USUARIO');
  Assert.IsTrue(oUnidadTrabajo.Ejecutada);
  Assert.IsTrue(oUnidadTrabajo.Completada);
  Assert.IsTrue(oRepositorio.Bloqueada);
  Assert.IsTrue(oEmision.Invocado);
  Assert.IsTrue(oMovimientos.Invocado);
  Assert.AreEqual('F', oEmision.Solicitud.Serie);
  Assert.AreEqual('42', oEmision.Solicitud.Numero);
  Assert.AreEqual('USUARIO', oEmision.Solicitud.Usuario);
  Assert.AreEqual('EMP', oMovimientos.Solicitud.Empresa);
  Assert.AreEqual('CLI', oMovimientos.Solicitud.Cliente);
  Assert.AreEqual('Factura consolidada', oResultado.MensajeFiscal);
  Assert.AreEqual(3, oResultado.MovimientosGenerados);
end;

procedure TPruebasFacturasConsolidacion.
  Consolidar_DatoInvalidoCancelaUnidadTrabajo;
var
  bExcepcionCapturada: Boolean;
  oCasoUso: ICasoUsoConsolidacionFactura;
  oDatos: TDatosFacturaConsolidacion;
  oEmision: TServicioEmisionFiscalPrueba;
  oMovimientos: TServicioMovimientosFacturaPrueba;
  oRepositorio: TRepositorioConsolidacionPrueba;
  oUnidadTrabajo: TUnidadTrabajoFacturasPrueba;
begin
  oUnidadTrabajo := TUnidadTrabajoFacturasPrueba.Create;
  oRepositorio := TRepositorioConsolidacionPrueba.Create;
  oDatos := CrearDatosValidos;
  oDatos.NifCliente := '';
  oRepositorio.Datos := oDatos;
  oEmision := TServicioEmisionFiscalPrueba.Create;
  oMovimientos := TServicioMovimientosFacturaPrueba.Create;
  oCasoUso := CrearCasoUsoConsolidacionFactura(
    oUnidadTrabajo,
    oRepositorio,
    oEmision,
    oMovimientos);
  bExcepcionCapturada := False;
  try
    oCasoUso.Consolidar('F', '42', 'USUARIO');
  except
    on E: EConsolidacionFactura do
      bExcepcionCapturada := True;
  end;
  Assert.IsTrue(bExcepcionCapturada);
  Assert.IsTrue(oUnidadTrabajo.Ejecutada);
  Assert.IsTrue(oUnidadTrabajo.Cancelada);
  Assert.IsFalse(oUnidadTrabajo.Completada);
  Assert.IsFalse(oEmision.Invocado);
  Assert.IsFalse(oMovimientos.Invocado);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasFacturasConsolidacion);

end.
