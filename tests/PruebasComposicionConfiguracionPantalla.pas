{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComposicionConfiguracionPantalla                      }
{    Tipo:       Pruebas                                                      }
{ Versión:       1.0.0                                                        }
{   Fecha:       03/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.    }
{                                                                              }
{  Descripción:                                                               }
{    Caracteriza la composición estrecha de configuración y auxiliares.       }
{******************************************************************************}
unit PruebasComposicionConfiguracionPantalla;

interface

uses
  System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasComposicionConfiguracionPantalla = class
  private
    FOrigen: TComponent;
    FArticulos: TObject;
    FConfiguracion: TObject;
    FDocumentos: TObject;
    FRemesas: TObject;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Componer_EnrutaCadaDependenciaPorSuCapacidad;
  end;

implementation

uses
  System.SysUtils, Uni,
  inLibRepositoriosPantallaIntf,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibArticulosPropiedadesPersistenciaIntf,
  inLibStockConsultaPersistenciaIntf,
  inLibGeneracionSkusPersistenciaIntf,
  inLibDistribuidorPersistenciaIntf,
  inLibMargenPersistenciaIntf,
  inLibFiltroArticulosPersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibAppParamPersistenciaIntf,
  inLibBusquedaDatosPersistenciaIntf,
  inLibDestinosFiltrosPersistenciaIntf,
  inLibGuiasPersistenciaIntf,
  inLibSeriesEmpresaPersistenciaIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  inLibImpresionPersistenciaIntf,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDestinoEnvioPersistenciaIntf,
  inLibSeleccionFamiliaPersistenciaIntf,
  inLibSerieFechaFacturaPersistenciaIntf,
  inLibSeleccionAlmacenPersistenciaIntf,
  inLibFacturacionAlbaranesFechasPersistenciaIntf,
  inLibFacturacionAlbaranesCompraPersistenciaIntf,
  inLibFacturacionTicketPersistenciaIntf,
  inLibDocumentosTrabajo,
  inLibCargaEfectosRemesaPersistenciaIntf,
  UniDataConfiguracionPantalla;

type
  TRepositoriosArticulosFalsos = class(
    TInterfacedObject,
    IRepositoriosArticulosPantalla)
  public
    Resoluciones: Integer;
    GeneracionesSkus: Integer;
    Distribuciones: Integer;
    Margenes: Integer;
    Filtros: Integer;
    CargasMasivas: Integer;
    function CrearResolverArticulos(
      AConexion: TUniConnection): IArticulosResolver;
    function CrearValidadorArticulos(
      AConexion: TUniConnection): IArticulosValidador;
    function CrearLookupAtributosArticulos(
      AConexion: TUniConnection): IArticulosAtributosLookup;
    function CrearServiciosPropiedadesArticulo(
      AConexion: TUniConnection): TServiciosPropiedadesArticulo;
    function CrearServiciosStockConsulta(
      AConexion: TUniConnection): TServiciosStockConsulta;
    function CrearRepositorioGeneracionSkus(
      AConexion: TUniConnection): IRepositorioGeneracionSkus;
    function CrearRepositorioDistribuidor(
      AConexion: TUniConnection): IRepositorioDistribuidor;
    function CrearRepositorioMargen(
      AConexion: TUniConnection): IRepositorioMargen;
    function CrearRepositorioFiltroArticulos(
      AConexion: TUniConnection): IRepositorioFiltroArticulos;
    function CrearServicioCargaMasivaArticulos:
      TServiciosCargaMasivaArticulos;
  end;

  TRepositoriosConfiguracionFalsos = class(
    TInterfacedObject,
    IRepositoriosConfiguracionPantalla)
  public
    Parametros: Integer;
    Busquedas: Integer;
    DestinosFiltros: Integer;
    Guias: Integer;
    Series: Integer;
    Bancos: Integer;
    function CrearRepositorioAppParam(
      AConexion: TUniConnection): IRepositorioAppParam;
    function CrearRepositorioBusquedaDatos(
      AConexion: TUniConnection): IRepositorioBusquedaDatos;
    function CrearRepositorioDestinosFiltros(
      AConexion: TUniConnection): IRepositorioDestinosFiltros;
    function CrearRepositorioGuias(
      AConexion: TUniConnection): IRepositorioGuias;
    function CrearRepositorioSeriesEmpresa(
      AConexion: TUniConnection): IRepositorioSeriesEmpresa;
    function CrearRepositorioSeleccionBancoEmpresa(
      AConexion: TUniConnection): IRepositorioSeleccionBancoEmpresa;
  end;

  TRepositoriosDocumentosFalsos = class(
    TInterfacedObject,
    IRepositoriosDocumentosPantalla)
  public
    DocumentosTrabajo: Integer;
    function CrearServiciosPersistenciaImpresion(
      AConexion: TUniConnection): TServiciosPersistenciaImpresion;
    function CrearServiciosPersistenciaDevolucionCompra(
      AConexion: TUniConnection): TServiciosPersistenciaDevolucionCompra;
    function CrearRepositorioDestinoEnvio(
      AConexion: TUniConnection): IRepositorioDestinoEnvio;
    function CrearRepositorioSeleccionFamilia(
      AConexion: TUniConnection): IRepositorioSeleccionFamilia;
    function CrearRepositorioSerieFechaFactura(
      AConexion: TUniConnection): IRepositorioSerieFechaFactura;
    function CrearRepositorioSeleccionAlmacen(
      AConexion: TUniConnection): IRepositorioSeleccionAlmacen;
    function CrearRepositorioFacturacionAlbaranesFechas(
      AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;
    function CrearRepositorioFacturacionAlbaranesCompra(
      AConexion: TUniConnection): IRepositorioFacturacionAlbaranesCompra;
    function CrearServicioFacturacionTicket(
      AConexion: TUniConnection): IServicioFacturacionTicket;
    function CrearRepositoriosDocumentosTrabajo(
      AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;
  end;

  TRepositoriosRemesasFalsos = class(
    TInterfacedObject,
    IRepositoriosRemesasPantalla)
  public
    CargasEfectos: Integer;
    function CrearRepositorioCargaEfectosRemesa(
      AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;
  end;

  TOrigenContextoFalso = class(
    TComponent,
    ICompositorArticulosPantalla,
    ICompositorConfiguracionPantalla,
    ICompositorDocumentosPantalla,
    ICompositorRemesasPantalla)
  private
    FArticulos: IRepositoriosArticulosPantalla;
    FConfiguracion: IRepositoriosConfiguracionPantalla;
    FDocumentos: IRepositoriosDocumentosPantalla;
    FRemesas: IRepositoriosRemesasPantalla;
  public
    constructor Create(
      const AArticulos: IRepositoriosArticulosPantalla;
      const AConfiguracion: IRepositoriosConfiguracionPantalla;
      const ADocumentos: IRepositoriosDocumentosPantalla;
      const ARemesas: IRepositoriosRemesasPantalla); reintroduce;
    destructor Destroy; override;
    function CrearRepositoriosArticulosPantalla(
      const ANombrePantalla: string): IRepositoriosArticulosPantalla;
    function CrearRepositoriosConfiguracionPantalla(
      const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
    function CrearRepositoriosDocumentosPantalla(
      const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
    function CrearRepositoriosRemesasPantalla(
      const ANombrePantalla: string): IRepositoriosRemesasPantalla;
  end;

function TRepositoriosArticulosFalsos.CrearResolverArticulos(
  AConexion: TUniConnection): IArticulosResolver;
begin
  Inc(Resoluciones);
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearValidadorArticulos(
  AConexion: TUniConnection): IArticulosValidador;
begin
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearLookupAtributosArticulos(
  AConexion: TUniConnection): IArticulosAtributosLookup;
begin
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearServiciosPropiedadesArticulo(
  AConexion: TUniConnection): TServiciosPropiedadesArticulo;
begin
  Result := Default(TServiciosPropiedadesArticulo);
end;

function TRepositoriosArticulosFalsos.CrearServiciosStockConsulta(
  AConexion: TUniConnection): TServiciosStockConsulta;
begin
  Result := Default(TServiciosStockConsulta);
end;

function TRepositoriosArticulosFalsos.CrearRepositorioGeneracionSkus(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;
begin
  Inc(GeneracionesSkus);
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearRepositorioDistribuidor(
  AConexion: TUniConnection): IRepositorioDistribuidor;
begin
  Inc(Distribuciones);
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearRepositorioMargen(
  AConexion: TUniConnection): IRepositorioMargen;
begin
  Inc(Margenes);
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearRepositorioFiltroArticulos(
  AConexion: TUniConnection): IRepositorioFiltroArticulos;
begin
  Inc(Filtros);
  Result := nil;
end;

function TRepositoriosArticulosFalsos.CrearServicioCargaMasivaArticulos:
  TServiciosCargaMasivaArticulos;
begin
  Inc(CargasMasivas);
  Result := Default(TServiciosCargaMasivaArticulos);
end;

function TRepositoriosConfiguracionFalsos.CrearRepositorioAppParam(
  AConexion: TUniConnection): IRepositorioAppParam;
begin
  Inc(Parametros);
  Result := nil;
end;

function TRepositoriosConfiguracionFalsos.CrearRepositorioBusquedaDatos(
  AConexion: TUniConnection): IRepositorioBusquedaDatos;
begin
  Inc(Busquedas);
  Result := nil;
end;

function TRepositoriosConfiguracionFalsos.CrearRepositorioDestinosFiltros(
  AConexion: TUniConnection): IRepositorioDestinosFiltros;
begin
  Inc(DestinosFiltros);
  Result := nil;
end;

function TRepositoriosConfiguracionFalsos.CrearRepositorioGuias(
  AConexion: TUniConnection): IRepositorioGuias;
begin
  Inc(Guias);
  Result := nil;
end;

function TRepositoriosConfiguracionFalsos.CrearRepositorioSeriesEmpresa(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;
begin
  Inc(Series);
  Result := nil;
end;

function TRepositoriosConfiguracionFalsos.
  CrearRepositorioSeleccionBancoEmpresa(
  AConexion: TUniConnection): IRepositorioSeleccionBancoEmpresa;
begin
  Inc(Bancos);
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.CrearServiciosPersistenciaImpresion(
  AConexion: TUniConnection): TServiciosPersistenciaImpresion;
begin
  Result := Default(TServiciosPersistenciaImpresion);
end;

function TRepositoriosDocumentosFalsos.
  CrearServiciosPersistenciaDevolucionCompra(
  AConexion: TUniConnection): TServiciosPersistenciaDevolucionCompra;
begin
  Result := Default(TServiciosPersistenciaDevolucionCompra);
end;

function TRepositoriosDocumentosFalsos.CrearRepositorioDestinoEnvio(
  AConexion: TUniConnection): IRepositorioDestinoEnvio;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.CrearRepositorioSeleccionFamilia(
  AConexion: TUniConnection): IRepositorioSeleccionFamilia;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.CrearRepositorioSerieFechaFactura(
  AConexion: TUniConnection): IRepositorioSerieFechaFactura;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.CrearRepositorioSeleccionAlmacen(
  AConexion: TUniConnection): IRepositorioSeleccionAlmacen;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.
  CrearRepositorioFacturacionAlbaranesFechas(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.
  CrearRepositorioFacturacionAlbaranesCompra(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesCompra;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.CrearServicioFacturacionTicket(
  AConexion: TUniConnection): IServicioFacturacionTicket;
begin
  Result := nil;
end;

function TRepositoriosDocumentosFalsos.CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;
begin
  Inc(DocumentosTrabajo);
  Result := Default(TRepositoriosDocumentosTrabajo);
end;

function TRepositoriosRemesasFalsos.CrearRepositorioCargaEfectosRemesa(
  AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;
begin
  Inc(CargasEfectos);
  Result := nil;
end;

constructor TOrigenContextoFalso.Create(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AConfiguracion: IRepositoriosConfiguracionPantalla;
  const ADocumentos: IRepositoriosDocumentosPantalla;
  const ARemesas: IRepositoriosRemesasPantalla);
begin
  inherited Create(nil);
  FArticulos := AArticulos;
  FConfiguracion := AConfiguracion;
  FDocumentos := ADocumentos;
  FRemesas := ARemesas;
end;

destructor TOrigenContextoFalso.Destroy;
begin
  FRemesas := nil;
  FDocumentos := nil;
  FConfiguracion := nil;
  FArticulos := nil;
  inherited;
end;

function TOrigenContextoFalso.CrearRepositoriosArticulosPantalla(
  const ANombrePantalla: string): IRepositoriosArticulosPantalla;
begin
  Result := FArticulos;
end;

function TOrigenContextoFalso.CrearRepositoriosConfiguracionPantalla(
  const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
begin
  Result := FConfiguracion;
end;

function TOrigenContextoFalso.CrearRepositoriosDocumentosPantalla(
  const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
begin
  Result := FDocumentos;
end;

function TOrigenContextoFalso.CrearRepositoriosRemesasPantalla(
  const ANombrePantalla: string): IRepositoriosRemesasPantalla;
begin
  Result := FRemesas;
end;

procedure TPruebasComposicionConfiguracionPantalla.Preparar;
var
  oArticulos: IRepositoriosArticulosPantalla;
  oConfiguracion: IRepositoriosConfiguracionPantalla;
  oDocumentos: IRepositoriosDocumentosPantalla;
  oRemesas: IRepositoriosRemesasPantalla;
begin
  FArticulos := TRepositoriosArticulosFalsos.Create;
  FConfiguracion := TRepositoriosConfiguracionFalsos.Create;
  FDocumentos := TRepositoriosDocumentosFalsos.Create;
  FRemesas := TRepositoriosRemesasFalsos.Create;
  oArticulos := TRepositoriosArticulosFalsos(FArticulos);
  oConfiguracion := TRepositoriosConfiguracionFalsos(FConfiguracion);
  oDocumentos := TRepositoriosDocumentosFalsos(FDocumentos);
  oRemesas := TRepositoriosRemesasFalsos(FRemesas);
  FOrigen := TOrigenContextoFalso.Create(
    oArticulos,
    oConfiguracion,
    oDocumentos,
    oRemesas);
end;

procedure TPruebasComposicionConfiguracionPantalla.Limpiar;
begin
  FreeAndNil(FOrigen);
  FRemesas := nil;
  FDocumentos := nil;
  FConfiguracion := nil;
  FArticulos := nil;
end;

procedure TPruebasComposicionConfiguracionPantalla.
  Componer_EnrutaCadaDependenciaPorSuCapacidad;
var
  oAppParam: IRepositorioAppParam;
  oArticulosResolver: IArticulosResolver;
  oBusqueda: IRepositorioBusquedaDatos;
  oCargaMasiva: TServiciosCargaMasivaArticulos;
  oDestinos: IRepositorioDestinosFiltros;
  oDistribuidor: IRepositorioDistribuidor;
  oDocumentos: TRepositoriosDocumentosTrabajo;
  oFiltro: IRepositorioFiltroArticulos;
  oGuias: IRepositorioGuias;
  oMargen: IRepositorioMargen;
  oRemesas: IRepositorioCargaEfectosRemesa;
  oSeleccionBanco: IRepositorioSeleccionBancoEmpresa;
  oSeries: IRepositorioSeriesEmpresa;
  oSkus: IRepositorioGeneracionSkus;
begin
  ComponerConfiguracionPantalla(FOrigen, nil, oAppParam);
  ComponerConfiguracionPantalla(
    FOrigen, nil, oBusqueda, oDocumentos, oArticulosResolver);
  ComponerConfiguracionPantalla(FOrigen, nil, oSeries);
  ComponerConfiguracionPantalla(FOrigen, oCargaMasiva);
  ComponerConfiguracionPantalla(FOrigen, nil, oMargen);
  ComponerConfiguracionPantalla(FOrigen, nil, oRemesas);
  ComponerConfiguracionPantalla(FOrigen, nil, oDistribuidor);
  ComponerConfiguracionPantalla(FOrigen, nil, oFiltro);
  ComponerConfiguracionPantalla(FOrigen, nil, oSkus);
  ComponerConfiguracionPantalla(FOrigen, nil, oDestinos);
  ComponerConfiguracionPantalla(FOrigen, nil, oGuias);
  ComponerConfiguracionPantalla(FOrigen, nil, oSeleccionBanco);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracion).Parametros);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracion).Busquedas);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracion).Series);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracion).DestinosFiltros);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracion).Guias);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracion).Bancos);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulos).Resoluciones);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulos).CargasMasivas);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulos).Margenes);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulos).Distribuciones);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulos).Filtros);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulos).GeneracionesSkus);
  Assert.AreEqual(1, TRepositoriosDocumentosFalsos(
    FDocumentos).DocumentosTrabajo);
  Assert.AreEqual(1, TRepositoriosRemesasFalsos(
    FRemesas).CargasEfectos);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComposicionConfiguracionPantalla);

end.
