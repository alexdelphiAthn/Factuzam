{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComposicionComprasPantalla                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza los límites transaccionales de las pantallas de compras.      }
{******************************************************************************}
unit PruebasComposicionComprasPantalla;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasComposicionComprasPantalla = class
  public
    [Test]
    procedure RecepcionCreacion_RechazoRevierte;
    [Test]
    procedure RecepcionCreacion_ExcepcionRevierte;
    [Test]
    procedure RecepcionCreacion_ExitoConfirma;
    [Test]
    procedure RecepcionIncorporacion_RechazoRevierte;
    [Test]
    procedure RecepcionIncorporacion_ExcepcionRevierte;
    [Test]
    procedure RecepcionIncorporacion_ExitoConfirma;
    [Test]
    procedure DevolucionStock_RechazoRevierte;
    [Test]
    procedure DevolucionStock_ExcepcionRevierte;
    [Test]
    procedure DevolucionStock_ExitoConfirma;
    [Test]
    procedure Recepcion_TransaccionActivaNoAdministra;
    [Test]
    procedure DevolucionStock_TransaccionActivaNoAdministra;
    [Test]
    procedure ContextoAlbaran_ValidaCapacidadesConcretas;
    [Test]
    procedure ContextoFactura_ValidaCapacidadesConcretas;
    [Test]
    procedure ContextoPedido_ValidaCapacidadesConcretas;
    [Test]
    procedure ContextoDevolucion_ValidaCapacidadesConcretas;
    [Test]
    procedure ContextoDocumentosTrabajo_ValidaCapacidadesConcretas;
    [Test]
    procedure ContextoPlantillas_ValidaCapacidadesConcretas;
    [Test]
    procedure DependenciaAusente_FallaAlPrepararContexto;
  end;

implementation

uses
  System.SysUtils, Data.DB,
  inLibAplicacionArticuloCompraIntf,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibComprasPantallaIntf,
  inLibComprasPantallaTransaccion,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDevolucionesCompraStock,
  inLibDocumentosTrabajo,
  inLibPedidosCompraIntf,
  UniDataComprasPantallaComposicion;

type
  TDobleArticuloCompra = class(
    TInterfacedObject,
    IAplicacionArticuloCompra,
    IAplicacionArticuloDevolucionCompra,
    IArticulosValidador,
    IArticulosAtributosLookup)
  public
    function Ejecutar(
      const AEntrada: TEntradaAplicacionArticuloCompra;
      ATipoDocumento: TTipoDocumentoArticuloCompra):
      TResultadoAplicacionArticuloCompra; overload;
    function Ejecutar(
      const AEntrada: TEntradaArticuloDevolucionCompra):
      TResultadoArticuloDevolucionCompra; overload;
    function Resolver(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverCodigoBarras(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverConSku(
      const AEntrada, ACodigoSkuPreferido: string):
      TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function ObtenerAtributos(
      const ACodigoArticulo: string): TArray<TArticuloAtributo>;
    function ObtenerPropiedades(
      const ACodigoArticulo: string): TArray<TArticuloPropiedad>;
    function ObtenerAtributosDeSku(
      const ACodigoSku: string): TArray<TArticuloAtributoValor>;
    function ObtenerAvsEnSkus(
      const ACodigoArticulo: string;
      AOrdenAtributo: Integer): TArray<TArticuloAtributoValor>;
  end;

  TDobleBusquedasCompra = class(
    TInterfacedObject,
    IBusquedaEmpresasComprasPantalla,
    IBusquedaProveedoresComprasPantalla,
    IBusquedasCompraPersistencia)
  public
    function ConsultarEmpresas: IConsultaComprasPantalla;
    function ConsultarProveedores: IConsultaComprasPantalla;
    function ConsultarArticulosProveedor(
      const ACodigoProveedor: string): IConsultaBusquedaCompra;
    function ConsultarSkusArticulo(
      const ACodigoArticulo: string): IConsultaBusquedaCompra;
  end;

  TDoblePedidoCompra = class(
    TInterfacedObject,
    IRecepcionPedidoCompra,
    IConsultasPedidoCompraPantalla)
  public
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
    function ColumnaLineasExiste(
      const ANombreColumna: string): Boolean;
    function AlmacenEfectivoPrimeraLinea(
      const ASerie, ANumero: string): string;
  end;

  TDobleDevolucionCompra = class(
    TInterfacedObject,
    IRepositorioDatosDevolucionCompra,
    IPersistenciaStockDevolucionCompra)
  public
    function CodigoSkuRepresentanteColor(
      const ACodigoArticulo, AColor: string;
      AIdConjuntoPivot: Integer): string;
    function ListarColoresArticulo(
      const ACodigoArticulo: string):
      TColoresArticuloDevolucionCompra;
    function ObtenerColorLinea(
      const ASerie, ANumero, ALinea: string;
      out AIdColor: Integer): Boolean;
    function BorrarGrupoColor(
      const AGrupo: TGrupoColorDevolucionCompra): Integer;
    function ResolverConjuntoPivotArticulo(
      const ACodigoArticulo: string): Integer;
    function ModeloProveedorArticulo(
      const ACodigoArticulo, ACodigoProveedor: string): string;
    function EsCodigoArticuloExacto(
      const ACodigo: string): Boolean;
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
  end;

  TDobleDocumentosTrabajo = class(
    TInterfacedObject,
    ILecturasDocumentosTrabajo,
    IMaterializacionDocumentosTrabajo)
  public
    function ConsultaDocumentosAbiertos(
      const AUsuario: string): string;
    procedure CompletarDatosArticulo(
      var ALinea: TDocTrabajoLineaOrigen);
    function ConsultarDestinosCompartir: IConsultaDocumentoTrabajo;
    function ListarNombresAtributos:
      TNombresAtributosDocumentoTrabajo;
    function SiguienteContador(
      const ASerie, ATipoDocumento, AEmpresa,
      AUsuario: string): string;
    function CrearAlbaran(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearFacturaVenta(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearPedidoCompra(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearInventario(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearSesionTarifa(
      AIdDocumento: Int64;
      const AUsuario: string): Int64;
  end;

  TDoblePlantillasCompra = class(
    TInterfacedObject,
    IPersistenciaPlantillasCompraPantalla)
  public
    function DataSetPlantillas: TDataSet;
    function DataSourcePropiedades: TDataSource;
    function DataSourceKits: TDataSource;
    function DataSourceDetalleKits: TDataSource;
    procedure Abrir;
    procedure AnadirPropiedad;
    procedure BorrarPropiedad;
    procedure AnadirKit;
    procedure BorrarKit;
  end;

  TComportamientoColaborador = (
    ccExito,
    ccRechazo,
    ccExcepcion);

  EExcepcionColaboradorCompras = class(Exception);

  TUnidadTrabajoComprasFalsa = class(
    TInterfacedObject,
    IUnidadTrabajoComprasPantalla)
  private
    FActiva: Boolean;
    FConfirmaciones: Integer;
    FInicios: Integer;
    FReversiones: Integer;
  public
    constructor Create(AActiva: Boolean);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
    property Activa: Boolean read FActiva;
    property Confirmaciones: Integer read FConfirmaciones;
    property Inicios: Integer read FInicios;
    property Reversiones: Integer read FReversiones;
  end;

  TRecepcionPedidoCompraFalsa = class(
    TInterfacedObject,
    IRecepcionPedidoCompra)
  private
    FComportamiento: TComportamientoColaborador;
    FLlamadas: Integer;
    FUltimaIncorporacion: Boolean;
  public
    constructor Create(AComportamiento: TComportamientoColaborador);
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
    property Llamadas: Integer read FLlamadas;
    property UltimaIncorporacion: Boolean read FUltimaIncorporacion;
  end;

  TStockDevolucionCompraFalso = class(
    TInterfacedObject,
    IPersistenciaStockDevolucionCompra)
  private
    FComportamiento: TComportamientoColaborador;
    FLlamadas: Integer;
  public
    constructor Create(AComportamiento: TComportamientoColaborador);
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
    property Llamadas: Integer read FLlamadas;
  end;

function TDobleArticuloCompra.Ejecutar(
  const AEntrada: TEntradaAplicacionArticuloCompra;
  ATipoDocumento: TTipoDocumentoArticuloCompra):
  TResultadoAplicacionArticuloCompra;
begin
  Result := Default(TResultadoAplicacionArticuloCompra);
end;

function TDobleArticuloCompra.Ejecutar(
  const AEntrada: TEntradaArticuloDevolucionCompra):
  TResultadoArticuloDevolucionCompra;
begin
  Result := Default(TResultadoArticuloDevolucionCompra);
end;

function TDobleArticuloCompra.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
end;

function TDobleArticuloCompra.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
end;

function TDobleArticuloCompra.ResolverConSku(
  const AEntrada, ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
end;

function TDobleArticuloCompra.EsValido(const AEntrada: string): Boolean;
begin
  Result := True;
end;

function TDobleArticuloCompra.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := True;
end;

function TDobleArticuloCompra.ObtenerAtributos(
  const ACodigoArticulo: string): TArray<TArticuloAtributo>;
begin
  Result := nil;
end;

function TDobleArticuloCompra.ObtenerPropiedades(
  const ACodigoArticulo: string): TArray<TArticuloPropiedad>;
begin
  Result := nil;
end;

function TDobleArticuloCompra.ObtenerAtributosDeSku(
  const ACodigoSku: string): TArray<TArticuloAtributoValor>;
begin
  Result := nil;
end;

function TDobleArticuloCompra.ObtenerAvsEnSkus(
  const ACodigoArticulo: string;
  AOrdenAtributo: Integer): TArray<TArticuloAtributoValor>;
begin
  Result := nil;
end;

function TDobleBusquedasCompra.ConsultarEmpresas:
  IConsultaComprasPantalla;
begin
  Result := nil;
end;

function TDobleBusquedasCompra.ConsultarProveedores:
  IConsultaComprasPantalla;
begin
  Result := nil;
end;

function TDobleBusquedasCompra.ConsultarArticulosProveedor(
  const ACodigoProveedor: string): IConsultaBusquedaCompra;
begin
  Result := nil;
end;

function TDobleBusquedasCompra.ConsultarSkusArticulo(
  const ACodigoArticulo: string): IConsultaBusquedaCompra;
begin
  Result := nil;
end;

function TDoblePedidoCompra.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  AResultado := Default(TResultadoRecepcionPedidoCompra);
  Result := True;
end;

function TDoblePedidoCompra.ColumnaLineasExiste(
  const ANombreColumna: string): Boolean;
begin
  Result := True;
end;

function TDoblePedidoCompra.AlmacenEfectivoPrimeraLinea(
  const ASerie, ANumero: string): string;
begin
  Result := 'A1';
end;

function TDobleDevolucionCompra.CodigoSkuRepresentanteColor(
  const ACodigoArticulo, AColor: string;
  AIdConjuntoPivot: Integer): string;
begin
  Result := '';
end;

function TDobleDevolucionCompra.ListarColoresArticulo(
  const ACodigoArticulo: string): TColoresArticuloDevolucionCompra;
begin
  Result := nil;
end;

function TDobleDevolucionCompra.ObtenerColorLinea(
  const ASerie, ANumero, ALinea: string;
  out AIdColor: Integer): Boolean;
begin
  AIdColor := 0;
  Result := False;
end;

function TDobleDevolucionCompra.BorrarGrupoColor(
  const AGrupo: TGrupoColorDevolucionCompra): Integer;
begin
  Result := 0;
end;

function TDobleDevolucionCompra.ResolverConjuntoPivotArticulo(
  const ACodigoArticulo: string): Integer;
begin
  Result := 0;
end;

function TDobleDevolucionCompra.ModeloProveedorArticulo(
  const ACodigoArticulo, ACodigoProveedor: string): string;
begin
  Result := '';
end;

function TDobleDevolucionCompra.EsCodigoArticuloExacto(
  const ACodigo: string): Boolean;
begin
  Result := True;
end;

function TDobleDevolucionCompra.ConsultarEstado(
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
begin
  Result := esdcDisponible;
end;

function TDobleDevolucionCompra.DevolverTodoStock(
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
begin
  ALineas := 0;
  AEstado := esdcDisponible;
  Result := True;
end;

function TDobleDocumentosTrabajo.ConsultaDocumentosAbiertos(
  const AUsuario: string): string;
begin
  Result := '';
end;

procedure TDobleDocumentosTrabajo.CompletarDatosArticulo(
  var ALinea: TDocTrabajoLineaOrigen);
begin
end;

function TDobleDocumentosTrabajo.ConsultarDestinosCompartir:
  IConsultaDocumentoTrabajo;
begin
  Result := nil;
end;

function TDobleDocumentosTrabajo.ListarNombresAtributos:
  TNombresAtributosDocumentoTrabajo;
begin
  Result := nil;
end;

function TDobleDocumentosTrabajo.SiguienteContador(
  const ASerie, ATipoDocumento, AEmpresa, AUsuario: string): string;
begin
  Result := '';
end;

function TDobleDocumentosTrabajo.CrearAlbaran(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajo.CrearFacturaVenta(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajo.CrearPedidoCompra(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajo.CrearInventario(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajo.CrearSesionTarifa(
  AIdDocumento: Int64;
  const AUsuario: string): Int64;
begin
  Result := 0;
end;

function TDoblePlantillasCompra.DataSetPlantillas: TDataSet;
begin
  Result := nil;
end;

function TDoblePlantillasCompra.DataSourcePropiedades: TDataSource;
begin
  Result := nil;
end;

function TDoblePlantillasCompra.DataSourceKits: TDataSource;
begin
  Result := nil;
end;

function TDoblePlantillasCompra.DataSourceDetalleKits: TDataSource;
begin
  Result := nil;
end;

procedure TDoblePlantillasCompra.Abrir;
begin
end;

procedure TDoblePlantillasCompra.AnadirPropiedad;
begin
end;

procedure TDoblePlantillasCompra.BorrarPropiedad;
begin
end;

procedure TDoblePlantillasCompra.AnadirKit;
begin
end;

procedure TDoblePlantillasCompra.BorrarKit;
begin
end;

constructor TUnidadTrabajoComprasFalsa.Create(AActiva: Boolean);
begin
  inherited Create;
  FActiva := AActiva;
end;

function TUnidadTrabajoComprasFalsa.EstaActiva: Boolean;
begin
  Result := FActiva;
end;

procedure TUnidadTrabajoComprasFalsa.Iniciar;
begin
  Inc(FInicios);
  FActiva := True;
end;

procedure TUnidadTrabajoComprasFalsa.Confirmar;
begin
  Inc(FConfirmaciones);
  FActiva := False;
end;

procedure TUnidadTrabajoComprasFalsa.Revertir;
begin
  Inc(FReversiones);
  FActiva := False;
end;

constructor TRecepcionPedidoCompraFalsa.Create(
  AComportamiento: TComportamientoColaborador);
begin
  inherited Create;
  FComportamiento := AComportamiento;
end;

function TRecepcionPedidoCompraFalsa.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  Inc(FLlamadas);
  FUltimaIncorporacion := AParametros.Incorporar;
  AResultado := Default(TResultadoRecepcionPedidoCompra);
  if FComportamiento = ccExcepcion then
    raise EExcepcionColaboradorCompras.Create(
      'Error simulado en la recepción de compra');
  Result := FComportamiento = ccExito;
  if Result then
  begin
    AResultado.SerieAlbaran := 'AC';
    AResultado.NumeroAlbaran := '1';
  end
  else
    AResultado.Mensaje := 'Recepción rechazada';
end;

constructor TStockDevolucionCompraFalso.Create(
  AComportamiento: TComportamientoColaborador);
begin
  inherited Create;
  FComportamiento := AComportamiento;
end;

function TStockDevolucionCompraFalso.ConsultarEstado(
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
begin
  Result := esdcDisponible;
end;

function TStockDevolucionCompraFalso.DevolverTodoStock(
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
begin
  Inc(FLlamadas);
  ALineas := 0;
  AEstado := esdcSinStock;
  if FComportamiento = ccExcepcion then
    raise EExcepcionColaboradorCompras.Create(
      'Error simulado en la devolución de stock');
  Result := FComportamiento = ccExito;
  if Result then
  begin
    ALineas := 3;
    AEstado := esdcDisponible;
  end;
end;

procedure PrepararRecepcion(
  AComportamiento: TComportamientoColaborador;
  ATransaccionActiva: Boolean;
  out AUnidad: TUnidadTrabajoComprasFalsa;
  out ARecepcion: TRecepcionPedidoCompraFalsa;
  out AProtegida: IRecepcionPedidoCompra);
var
  oRecepcion: IRecepcionPedidoCompra;
  oUnidad: IUnidadTrabajoComprasPantalla;
begin
  AUnidad := TUnidadTrabajoComprasFalsa.Create(ATransaccionActiva);
  oUnidad := AUnidad;
  ARecepcion := TRecepcionPedidoCompraFalsa.Create(AComportamiento);
  oRecepcion := ARecepcion;
  AProtegida := ProtegerRecepcionPedidoCompra(oRecepcion, oUnidad);
end;

procedure PrepararStock(
  AComportamiento: TComportamientoColaborador;
  ATransaccionActiva: Boolean;
  out AUnidad: TUnidadTrabajoComprasFalsa;
  out AStock: TStockDevolucionCompraFalso;
  out AProtegido: IPersistenciaStockDevolucionCompra);
var
  oStock: IPersistenciaStockDevolucionCompra;
  oUnidad: IUnidadTrabajoComprasPantalla;
begin
  AUnidad := TUnidadTrabajoComprasFalsa.Create(ATransaccionActiva);
  oUnidad := AUnidad;
  AStock := TStockDevolucionCompraFalso.Create(AComportamiento);
  oStock := AStock;
  AProtegido := ProtegerStockDevolucionCompra(oStock, oUnidad);
end;

function CrearParametrosRecepcion(
  AIncorporar: Boolean): TParametrosRecepcionPedidoCompra;
begin
  Result := Default(TParametrosRecepcionPedidoCompra);
  Result.Incorporar := AIncorporar;
end;

procedure ComprobarTransaccion(
  AUnidad: TUnidadTrabajoComprasFalsa;
  AInicios, AConfirmaciones, AReversiones: Integer);
begin
  Assert.AreEqual(AInicios, AUnidad.Inicios);
  Assert.AreEqual(AConfirmaciones, AUnidad.Confirmaciones);
  Assert.AreEqual(AReversiones, AUnidad.Reversiones);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionCreacion_RechazoRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccRechazo, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.IsFalse(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsFalse(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionCreacion_ExcepcionRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccExcepcion, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.WillRaise(
    procedure
    begin
      oProtegida.EjecutarRecepcionPedidoCompra(Parametros, Resultado);
    end,
    EExcepcionColaboradorCompras);
  Assert.IsFalse(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionCreacion_ExitoConfirma;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(ccExito, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.IsTrue(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsFalse(oColaborador.UltimaIncorporacion);
  Assert.AreEqual('1', Resultado.NumeroAlbaran);
  ComprobarTransaccion(oUnidad, 1, 1, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionIncorporacion_RechazoRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccRechazo, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(True);
  Assert.IsFalse(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsTrue(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionIncorporacion_ExcepcionRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccExcepcion, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(True);
  Assert.WillRaise(
    procedure
    begin
      oProtegida.EjecutarRecepcionPedidoCompra(Parametros, Resultado);
    end,
    EExcepcionColaboradorCompras);
  Assert.IsTrue(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionIncorporacion_ExitoConfirma;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(ccExito, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(True);
  Assert.IsTrue(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsTrue(oColaborador.UltimaIncorporacion);
  Assert.AreEqual('1', Resultado.NumeroAlbaran);
  ComprobarTransaccion(oUnidad, 1, 1, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_RechazoRevierte;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(
    ccRechazo, False, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.IsFalse(oProtegido.DevolverTodoStock(
    Parametros,
    Lineas,
    Estado));
  Assert.AreEqual(1, oColaborador.Llamadas);
  Assert.AreEqual(0, Lineas);
  Assert.AreEqual(Ord(esdcSinStock), Ord(Estado));
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_ExcepcionRevierte;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(
    ccExcepcion, False, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.WillRaise(
    procedure
    begin
      oProtegido.DevolverTodoStock(Parametros, Lineas, Estado);
    end,
    EExcepcionColaboradorCompras);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_ExitoConfirma;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(ccExito, False, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.IsTrue(oProtegido.DevolverTodoStock(
    Parametros,
    Lineas,
    Estado));
  Assert.AreEqual(1, oColaborador.Llamadas);
  Assert.AreEqual(3, Lineas);
  Assert.AreEqual(Ord(esdcDisponible), Ord(Estado));
  ComprobarTransaccion(oUnidad, 1, 1, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  Recepcion_TransaccionActivaNoAdministra;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(ccExito, True, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.IsTrue(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsTrue(oUnidad.Activa);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 0, 0, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_TransaccionActivaNoAdministra;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(
    ccExcepcion, True, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.WillRaise(
    procedure
    begin
      oProtegido.DevolverTodoStock(Parametros, Lineas, Estado);
    end,
    EExcepcionColaboradorCompras);
  Assert.IsTrue(oUnidad.Activa);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 0, 0, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  ContextoAlbaran_ValidaCapacidadesConcretas;
var
  oArticulo: TDobleArticuloCompra;
  oBusquedas: TDobleBusquedasCompra;
  Contexto: TContextoAlbaranCompraPantalla;
begin
  oArticulo := TDobleArticuloCompra.Create;
  oBusquedas := TDobleBusquedasCompra.Create;
  Contexto := Default(TContextoAlbaranCompraPantalla);
  Contexto.AplicacionArticulo := oArticulo;
  Contexto.ValidadorArticulos := oArticulo;
  Contexto.LookupAtributos := oArticulo;
  Contexto.BusquedaEmpresas := oBusquedas;
  Contexto.BusquedaProveedores := oBusquedas;
  Contexto.BusquedasArticulos := oBusquedas;
  Assert.WillNotRaise(
    procedure
    begin
      Contexto.Validar;
    end);
end;

procedure TPruebasComposicionComprasPantalla.
  ContextoFactura_ValidaCapacidadesConcretas;
var
  oArticulo: TDobleArticuloCompra;
  oBusquedas: TDobleBusquedasCompra;
  Contexto: TContextoFacturaCompraPantalla;
begin
  oArticulo := TDobleArticuloCompra.Create;
  oBusquedas := TDobleBusquedasCompra.Create;
  Contexto := Default(TContextoFacturaCompraPantalla);
  Contexto.AplicacionArticulo := oArticulo;
  Contexto.ValidadorArticulos := oArticulo;
  Contexto.LookupAtributos := oArticulo;
  Contexto.BusquedaProveedores := oBusquedas;
  Contexto.BusquedasArticulos := oBusquedas;
  Assert.WillNotRaise(
    procedure
    begin
      Contexto.Validar;
    end);
end;

procedure TPruebasComposicionComprasPantalla.
  ContextoPedido_ValidaCapacidadesConcretas;
var
  oArticulo: TDobleArticuloCompra;
  oBusquedas: TDobleBusquedasCompra;
  oPedido: TDoblePedidoCompra;
  Contexto: TContextoPedidoCompraPantalla;
begin
  oArticulo := TDobleArticuloCompra.Create;
  oBusquedas := TDobleBusquedasCompra.Create;
  oPedido := TDoblePedidoCompra.Create;
  Contexto := Default(TContextoPedidoCompraPantalla);
  Contexto.AplicacionArticulo := oArticulo;
  Contexto.ValidadorArticulos := oArticulo;
  Contexto.LookupAtributos := oArticulo;
  Contexto.BusquedaEmpresas := oBusquedas;
  Contexto.BusquedaProveedores := oBusquedas;
  Contexto.BusquedasArticulos := oBusquedas;
  Contexto.Recepcion := oPedido;
  Contexto.Consultas := oPedido;
  Assert.WillNotRaise(
    procedure
    begin
      Contexto.Validar;
    end);
end;

procedure TPruebasComposicionComprasPantalla.
  ContextoDevolucion_ValidaCapacidadesConcretas;
var
  oArticulo: TDobleArticuloCompra;
  oBusquedas: TDobleBusquedasCompra;
  oDevolucion: TDobleDevolucionCompra;
  Contexto: TContextoDevolucionCompraPantalla;
begin
  oArticulo := TDobleArticuloCompra.Create;
  oBusquedas := TDobleBusquedasCompra.Create;
  oDevolucion := TDobleDevolucionCompra.Create;
  Contexto := Default(TContextoDevolucionCompraPantalla);
  Contexto.AplicacionArticulo := oArticulo;
  Contexto.ValidadorArticulos := oArticulo;
  Contexto.LookupAtributos := oArticulo;
  Contexto.Datos := oDevolucion;
  Contexto.Stock := oDevolucion;
  Contexto.BusquedaEmpresas := oBusquedas;
  Contexto.BusquedaProveedores := oBusquedas;
  Contexto.BusquedasArticulos := oBusquedas;
  Assert.WillNotRaise(
    procedure
    begin
      Contexto.Validar;
    end);
end;

procedure TPruebasComposicionComprasPantalla.
  ContextoDocumentosTrabajo_ValidaCapacidadesConcretas;
var
  oArticulo: TDobleArticuloCompra;
  oDocumentos: TDobleDocumentosTrabajo;
  Contexto: TContextoDocumentosTrabajoCompraPantalla;
begin
  oArticulo := TDobleArticuloCompra.Create;
  oDocumentos := TDobleDocumentosTrabajo.Create;
  Contexto := Default(TContextoDocumentosTrabajoCompraPantalla);
  Contexto.ValidadorArticulos := oArticulo;
  Contexto.LookupAtributos := oArticulo;
  Contexto.Lecturas := oDocumentos;
  Contexto.Materializacion := oDocumentos;
  Assert.WillNotRaise(
    procedure
    begin
      Contexto.Validar;
    end);
end;

procedure TPruebasComposicionComprasPantalla.
  ContextoPlantillas_ValidaCapacidadesConcretas;
var
  Contexto: TContextoPlantillasCompraPantalla;
begin
  Contexto := Default(TContextoPlantillasCompraPantalla);
  Contexto.Persistencia := TDoblePlantillasCompra.Create;
  Assert.WillNotRaise(
    procedure
    begin
      Contexto.Validar;
    end);
end;

procedure TPruebasComposicionComprasPantalla.
  DependenciaAusente_FallaAlPrepararContexto;
var
  oArticulo: TDobleArticuloCompra;
  oBusquedas: TDobleBusquedasCompra;
  Contexto: TContextoAlbaranCompraPantalla;
begin
  oArticulo := TDobleArticuloCompra.Create;
  oBusquedas := TDobleBusquedasCompra.Create;
  Contexto := Default(TContextoAlbaranCompraPantalla);
  Contexto.AplicacionArticulo := oArticulo;
  Contexto.ValidadorArticulos := oArticulo;
  Contexto.LookupAtributos := oArticulo;
  Contexto.BusquedaEmpresas := oBusquedas;
  Contexto.BusquedasArticulos := oBusquedas;
  Assert.WillRaise(
    procedure
    begin
      Contexto.Validar;
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComposicionComprasPantalla);

end.
