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
  DUnitX.TestFramework,
  inLibRepositoriosPantallaIntf;

type
  [TestFixture]
  TPruebasComposicionConfiguracionPantalla = class
  private
    FArticulosObjeto: TObject;
    FConfiguracionObjeto: TObject;
    FDocumentosObjeto: TObject;
    FRemesasObjeto: TObject;
    FArticulos: IRepositoriosArticulosPantalla;
    FConfiguracion: IRepositoriosConfiguracionPantalla;
    FDocumentos: IRepositoriosDocumentosPantalla;
    FRemesas: IRepositoriosRemesasPantalla;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Componer_EnrutaCadaDependenciaPorSuCapacidad;
    [Test]
    procedure Componer_RechazaRepositorioAusente;
  end;

implementation

uses
  System.SysUtils, Uni,
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

procedure TPruebasComposicionConfiguracionPantalla.Preparar;
begin
  FArticulosObjeto := TRepositoriosArticulosFalsos.Create;
  FConfiguracionObjeto := TRepositoriosConfiguracionFalsos.Create;
  FDocumentosObjeto := TRepositoriosDocumentosFalsos.Create;
  FRemesasObjeto := TRepositoriosRemesasFalsos.Create;
  FArticulos := TRepositoriosArticulosFalsos(FArticulosObjeto);
  FConfiguracion := TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto);
  FDocumentos := TRepositoriosDocumentosFalsos(FDocumentosObjeto);
  FRemesas := TRepositoriosRemesasFalsos(FRemesasObjeto);
end;

procedure TPruebasComposicionConfiguracionPantalla.Limpiar;
begin
  FRemesas := nil;
  FDocumentos := nil;
  FConfiguracion := nil;
  FArticulos := nil;
  FRemesasObjeto := nil;
  FDocumentosObjeto := nil;
  FConfiguracionObjeto := nil;
  FArticulosObjeto := nil;
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
  ComponerConfiguracionPantalla(FConfiguracion, nil, oAppParam);
  ComponerConfiguracionPantalla(
    FConfiguracion,
    FDocumentos,
    FArticulos,
    nil,
    oBusqueda,
    oDocumentos,
    oArticulosResolver);
  ComponerConfiguracionPantalla(FConfiguracion, nil, oSeries);
  ComponerConfiguracionPantalla(FArticulos, oCargaMasiva);
  ComponerConfiguracionPantalla(FArticulos, nil, oMargen);
  ComponerConfiguracionPantalla(FRemesas, nil, oRemesas);
  ComponerConfiguracionPantalla(FArticulos, nil, oDistribuidor);
  ComponerConfiguracionPantalla(FArticulos, nil, oFiltro);
  ComponerConfiguracionPantalla(FArticulos, nil, oSkus);
  ComponerConfiguracionPantalla(FConfiguracion, nil, oDestinos);
  ComponerConfiguracionPantalla(FConfiguracion, nil, oGuias);
  ComponerConfiguracionPantalla(
    FConfiguracion,
    nil,
    oSeleccionBanco);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto).Parametros);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto).Busquedas);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto).Series);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto).DestinosFiltros);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto).Guias);
  Assert.AreEqual(1, TRepositoriosConfiguracionFalsos(
    FConfiguracionObjeto).Bancos);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulosObjeto).Resoluciones);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulosObjeto).CargasMasivas);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulosObjeto).Margenes);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulosObjeto).Distribuciones);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulosObjeto).Filtros);
  Assert.AreEqual(1, TRepositoriosArticulosFalsos(
    FArticulosObjeto).GeneracionesSkus);
  Assert.AreEqual(1, TRepositoriosDocumentosFalsos(
    FDocumentosObjeto).DocumentosTrabajo);
  Assert.AreEqual(1, TRepositoriosRemesasFalsos(
    FRemesasObjeto).CargasEfectos);
end;

procedure TPruebasComposicionConfiguracionPantalla.
  Componer_RechazaRepositorioAusente;
var
  oAppParam: IRepositorioAppParam;
  EsErrorEsperado: Boolean;
begin
  EsErrorEsperado := False;
  try
    ComponerConfiguracionPantalla(
      IRepositoriosConfiguracionPantalla(nil),
      nil,
      oAppParam);
  except
    on EArgumentNilException do
      EsErrorEsperado := True;
  end;
  Assert.IsTrue(EsErrorEsperado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComposicionConfiguracionPantalla);

end.
