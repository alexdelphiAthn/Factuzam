{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasInventariosAplicacion                                  }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica la entrada de inventario sin VCL ni datasets.                    }
{******************************************************************************}
unit PruebasInventariosAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInventariosAplicacion = class
  public
    [Test]
    procedure ArticuloDesconocidoNoModificaLaLinea;
    [Test]
    procedure ServicioSeRechazaAntesDeEditar;
    [Test]
    procedure PadreConAtributosExigeSkuEnModoUnificado;
    [Test]
    procedure SkuCargaStockYAtributos;
    [Test]
    procedure ArticuloSimpleCargaStockSinAtributos;
    [Test]
    procedure ContextoSinResolucionFallaAlPreparar;
    [Test]
    procedure ContextoSinAtributosFallaAlPreparar;
    [Test]
    procedure ContextoSinColumnasSkuFallaAlPreparar;
  end;

  [TestFixture]
  TPruebasInventariosImportacion = class
  public
    [Test]
    procedure LectorCsvAdmitePuntoYComaEIgual;
    [Test]
    procedure LectorCsvAsumeUnaUnidadSinCantidadLegible;
    [Test]
    procedure LectorCsvConservaElTextoNormalizado;
    [Test]
    procedure UnidadExistenteActualizaRecuentoYConsolida;
    [Test]
    procedure UnidadDesconocidaQuedaPendienteDeAlta;
    [Test]
    procedure PrecioMedioSoloSeEscribeCuandoLaLineaLoTrae;
    [Test]
    procedure ImportacionVaciaNoConsolidaCambios;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibColumnasDocumentoLecturasIntf,
  inLibInventariosAplicacion,
  inLibInventariosAplicacionIntf,
  inLibInventariosInyeccion;

type
  TValidadorEntradaInventarioFalso = class(
    TInterfacedObject,
    IArticulosValidador)
  private
    FResolucion: TArtResolucionEntrada;
  public
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
  end;

  TOperacionesEntradaInventarioFalsas = class(
    TInterfacedObject,
    IOperacionesEntradaInventario)
  private
    FMuestraAtributos: Boolean;
    FNumeroAtributos: Integer;
    FErrorEdicion: TErrorEntradaInventario;
    FArticulosEscritos: Integer;
    FUnidadesEscritas: Integer;
    FStocksCargados: Integer;
    FAtributosRellenados: Integer;
  public
    function MuestraAtributos: Boolean;
    function ObtenerNumeroAtributos(
      const ACodigoArticulo: string): Integer;
    function AsegurarEdicion: TErrorEntradaInventario;
    procedure EscribirArticulo(
      const ACodigoArticulo, ADescripcion: string);
    procedure ActualizarColumnas(const ACodigoArticulo: string);
    function NumeroAtributosActual: Integer;
    procedure EscribirUnidad(const ACodigoUnidad: string);
    procedure CargarStock(const ACodigoUnidad: string);
    procedure RellenarAtributos(const ACodigoSku: string);
  end;

  TLookupAtributosInventarioFalso = class(
    TInterfacedObject,
    IArticulosAtributosLookup)
  public
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

  TLecturasColumnasInventarioFalsas = class(
    TInterfacedObject,
    IColumnasDocumentoLecturas)
  public
    function ListarNombresAtributosGlobales: TArray<string>;
  end;

  TOperacionesImportacionFalsas = class(
    TInterfacedObject,
    IOperacionesImportacionInventario)
  private
    FUnidadesConocidas: string;
    FPendientes: string;
    FEdiciones: Integer;
    FConfirmaciones: Integer;
    FConsolidaciones: Integer;
    FPreciosEscritos: Integer;
    FPreciosHistoricos: Integer;
    FUltimaCantidad: Double;
    FUltimoPrecio: Double;
  public
    function LocalizarUnidad(const ACodigoUnidad: string): Boolean;
    procedure IniciarEdicionLinea;
    procedure EscribirCantidadFisica(ACantidad: Double);
    procedure EscribirPrecioMedioNuevo(APrecio: Double);
    procedure UsarPrecioMedioHistorico;
    procedure ConfirmarLinea;
    procedure ConsolidarCambios;
    procedure AnadirUnidadPendiente(const ATextoOriginal: string);
  end;

function LineasDePrueba(
  const ACodigoUnidad: string;
  ACantidad, APrecio: Double;
  ATienePrecio: Boolean): TLineasImportacionInventario;
begin
  SetLength(Result, 1);
  Result[0].CodigoUnidad := ACodigoUnidad;
  Result[0].Cantidad := ACantidad;
  Result[0].PrecioMedioNuevo := APrecio;
  Result[0].TienePrecioMedio := ATienePrecio;
  Result[0].TextoOriginal := ACodigoUnidad + '=' +
    FloatToStr(ACantidad);
end;

function TOperacionesImportacionFalsas.LocalizarUnidad(
  const ACodigoUnidad: string): Boolean;
begin
  Result := (FUnidadesConocidas <> '') and
            (Pos(ACodigoUnidad, FUnidadesConocidas) > 0);
end;

procedure TOperacionesImportacionFalsas.IniciarEdicionLinea;
begin
  Inc(FEdiciones);
end;

procedure TOperacionesImportacionFalsas.EscribirCantidadFisica(
  ACantidad: Double);
begin
  FUltimaCantidad := ACantidad;
end;

procedure TOperacionesImportacionFalsas.EscribirPrecioMedioNuevo(
  APrecio: Double);
begin
  Inc(FPreciosEscritos);
  FUltimoPrecio := APrecio;
end;

procedure TOperacionesImportacionFalsas.UsarPrecioMedioHistorico;
begin
  Inc(FPreciosHistoricos);
end;

procedure TOperacionesImportacionFalsas.ConfirmarLinea;
begin
  Inc(FConfirmaciones);
end;

procedure TOperacionesImportacionFalsas.ConsolidarCambios;
begin
  Inc(FConsolidaciones);
end;

procedure TOperacionesImportacionFalsas.AnadirUnidadPendiente(
  const ATextoOriginal: string);
begin
  FPendientes := FPendientes + ATextoOriginal;
end;

function ResolucionBase: TArtResolucionEntrada;
begin
  Result.Clear;
  Result.Encontrado := True;
  Result.CodigoArticulo := 'ART1';
  Result.DescripcionArticulo := 'Articulo uno';
  Result.TipoArticulo := 'ESTANDAR';
end;

function TValidadorEntradaInventarioFalso.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaInventarioFalso.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaInventarioFalso.ResolverConSku(
  const AEntrada, ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaInventarioFalso.EsValido(
  const AEntrada: string): Boolean;
begin
  Result := FResolucion.Encontrado;
end;

function TValidadorEntradaInventarioFalso.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FResolucion.CodigoSku <> '';
end;

function TOperacionesEntradaInventarioFalsas.MuestraAtributos: Boolean;
begin
  Result := FMuestraAtributos;
end;

function TLookupAtributosInventarioFalso.ObtenerAtributos(
  const ACodigoArticulo: string): TArray<TArticuloAtributo>;
begin
  SetLength(Result, 0);
end;

function TLecturasColumnasInventarioFalsas.
  ListarNombresAtributosGlobales: TArray<string>;
begin
  SetLength(Result, 0);
end;

function TLookupAtributosInventarioFalso.ObtenerPropiedades(
  const ACodigoArticulo: string): TArray<TArticuloPropiedad>;
begin
  SetLength(Result, 0);
end;

function TLookupAtributosInventarioFalso.ObtenerAtributosDeSku(
  const ACodigoSku: string): TArray<TArticuloAtributoValor>;
begin
  SetLength(Result, 0);
end;

function TLookupAtributosInventarioFalso.ObtenerAvsEnSkus(
  const ACodigoArticulo: string;
  AOrdenAtributo: Integer): TArray<TArticuloAtributoValor>;
begin
  SetLength(Result, 0);
end;

function TOperacionesEntradaInventarioFalsas.ObtenerNumeroAtributos(
  const ACodigoArticulo: string): Integer;
begin
  Result := FNumeroAtributos;
end;

function TOperacionesEntradaInventarioFalsas.AsegurarEdicion:
  TErrorEntradaInventario;
begin
  Result := FErrorEdicion;
end;

procedure TOperacionesEntradaInventarioFalsas.EscribirArticulo(
  const ACodigoArticulo, ADescripcion: string);
begin
  Inc(FArticulosEscritos);
end;

procedure TOperacionesEntradaInventarioFalsas.ActualizarColumnas(
  const ACodigoArticulo: string);
begin
end;

function TOperacionesEntradaInventarioFalsas.NumeroAtributosActual: Integer;
begin
  Result := FNumeroAtributos;
end;

procedure TOperacionesEntradaInventarioFalsas.EscribirUnidad(
  const ACodigoUnidad: string);
begin
  Inc(FUnidadesEscritas);
end;

procedure TOperacionesEntradaInventarioFalsas.CargarStock(
  const ACodigoUnidad: string);
begin
  Inc(FStocksCargados);
end;

procedure TOperacionesEntradaInventarioFalsas.RellenarAtributos(
  const ACodigoSku: string);
begin
  Inc(FAtributosRellenados);
end;

procedure TPruebasInventariosAplicacion.ArticuloDesconocidoNoModificaLaLinea;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion.Clear;
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('NO-EXISTE');
  Assert.AreEqual(Ord(eeiArticuloNoEncontrado), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FArticulosEscritos);
end;

procedure TPruebasInventariosAplicacion.ServicioSeRechazaAntesDeEditar;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Validador.FResolucion.TipoArticulo := 'SERVICIO';
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('ART1');
  Assert.AreEqual(Ord(eeiTipoArticuloSinStock), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FArticulosEscritos);
end;

procedure TPruebasInventariosAplicacion.
  PadreConAtributosExigeSkuEnModoUnificado;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Operaciones.FNumeroAtributos := 2;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('ART1');
  Assert.AreEqual(Ord(eeiAtributosRequierenSku), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FArticulosEscritos);
end;

procedure TPruebasInventariosAplicacion.SkuCargaStockYAtributos;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Validador.FResolucion.CodigoSku := 'SKU1';
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('SKU1');
  Assert.AreEqual(Ord(eeiNinguno), Ord(Resultado.Error));
  Assert.AreEqual('SKU1', Resultado.CodigoUnidad);
  Assert.AreEqual(1, Operaciones.FStocksCargados);
  Assert.AreEqual(1, Operaciones.FAtributosRellenados);
end;

procedure TPruebasInventariosAplicacion.ArticuloSimpleCargaStockSinAtributos;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('ART1');
  Assert.AreEqual(Ord(eeiNinguno), Ord(Resultado.Error));
  Assert.AreEqual('ART1', Resultado.CodigoUnidad);
  Assert.AreEqual(1, Operaciones.FStocksCargados);
  Assert.AreEqual(0, Operaciones.FAtributosRellenados);
end;

procedure TPruebasInventariosAplicacion.
  ContextoSinResolucionFallaAlPreparar;
var
  Contexto: TDependenciasInventarios;
begin
  Contexto := Default(TDependenciasInventarios);
  Assert.WillRaise(
    procedure
    begin
      Contexto.Validar;
    end,
    EArgumentNilException);
end;

procedure TPruebasInventariosAplicacion.
  ContextoSinAtributosFallaAlPreparar;
var
  Contexto: TDependenciasInventarios;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Contexto := Default(TDependenciasInventarios);
  Validador := TValidadorEntradaInventarioFalso.Create;
  Contexto.Articulos.ResolucionValidacion := Validador;
  Assert.WillRaise(
    procedure
    begin
      Contexto.Validar;
    end,
    EArgumentNilException);
end;

procedure TPruebasInventariosAplicacion.
  ContextoSinColumnasSkuFallaAlPreparar;
var
  Contexto: TDependenciasInventarios;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Contexto := Default(TDependenciasInventarios);
  Validador := TValidadorEntradaInventarioFalso.Create;
  Contexto.Articulos.ResolucionValidacion := Validador;
  Contexto.Articulos.Atributos :=
    TLookupAtributosInventarioFalso.Create;
  Contexto.Articulos.AtributosGlobales :=
    TLecturasColumnasInventarioFalsas.Create;
  Assert.WillRaise(
    procedure
    begin
      Contexto.Validar;
    end,
    EArgumentNilException);
end;

procedure TPruebasInventariosImportacion.LectorCsvAdmitePuntoYComaEIgual;
var
  Lineas: TLineasImportacionInventario;
begin
  Lineas := LeerLineasImportacionCsvInventario(
    TArray<string>.Create('SKU1;3', 'SKU2=4'));
  Assert.AreEqual(2, Integer(Length(Lineas)));
  Assert.AreEqual('SKU1', Lineas[0].CodigoUnidad);
  Assert.AreEqual(Double(3), Lineas[0].Cantidad, 0.0001);
  Assert.AreEqual('SKU2', Lineas[1].CodigoUnidad);
  Assert.AreEqual(Double(4), Lineas[1].Cantidad, 0.0001);
  Assert.IsFalse(Lineas[0].TienePrecioMedio);
end;

procedure TPruebasInventariosImportacion.
  LectorCsvAsumeUnaUnidadSinCantidadLegible;
var
  Lineas: TLineasImportacionInventario;
begin
  Lineas := LeerLineasImportacionCsvInventario(
    TArray<string>.Create('SKU1;', 'SKU2;XX'));
  Assert.AreEqual(Double(1), Lineas[0].Cantidad, 0.0001);
  Assert.AreEqual(Double(1), Lineas[1].Cantidad, 0.0001);
end;

procedure TPruebasInventariosImportacion.
  LectorCsvConservaElTextoNormalizado;
var
  Lineas: TLineasImportacionInventario;
begin
  // El texto que se guarda para el alta pendiente ya lleva el separador
  // normalizado a '=', como esperaba CargarDesdeListaSkus.
  Lineas := LeerLineasImportacionCsvInventario(
    TArray<string>.Create('SKU1;3'));
  Assert.AreEqual('SKU1=3', Lineas[0].TextoOriginal);
  // Una linea sin separador no aporta unidad y se ignora al aplicar.
  Lineas := LeerLineasImportacionCsvInventario(
    TArray<string>.Create('BASURA'));
  Assert.AreEqual('', Lineas[0].CodigoUnidad);
end;

procedure TPruebasInventariosImportacion.
  UnidadExistenteActualizaRecuentoYConsolida;
var
  Falsas: TOperacionesImportacionFalsas;
  Operaciones: IOperacionesImportacionInventario;
  Resumen: TResumenImportacionInventario;
begin
  Falsas := TOperacionesImportacionFalsas.Create;
  // La interfaz mantiene vivo el doble mientras se comprueba.
  Operaciones := Falsas;
  Falsas.FUnidadesConocidas := 'SKU1';
  Resumen := AplicarImportacionInventario(
    LineasDePrueba('SKU1', 5, 0, False), Operaciones);
  Assert.AreEqual(1, Resumen.Actualizadas);
  Assert.AreEqual(0, Resumen.Nuevas);
  Assert.AreEqual(1, Falsas.FEdiciones);
  Assert.AreEqual(1, Falsas.FConfirmaciones);
  Assert.AreEqual(1, Falsas.FConsolidaciones);
  Assert.AreEqual(Double(5), Falsas.FUltimaCantidad, 0.0001);
end;

procedure TPruebasInventariosImportacion.
  UnidadDesconocidaQuedaPendienteDeAlta;
var
  Falsas: TOperacionesImportacionFalsas;
  Operaciones: IOperacionesImportacionInventario;
  Resumen: TResumenImportacionInventario;
begin
  Falsas := TOperacionesImportacionFalsas.Create;
  Operaciones := Falsas;
  Resumen := AplicarImportacionInventario(
    LineasDePrueba('SKU9', 2, 0, False), Operaciones);
  Assert.AreEqual(0, Resumen.Actualizadas);
  Assert.AreEqual(1, Resumen.Nuevas);
  Assert.AreEqual('SKU9=2', Falsas.FPendientes);
  Assert.AreEqual(0, Falsas.FConsolidaciones);
end;

procedure TPruebasInventariosImportacion.
  PrecioMedioSoloSeEscribeCuandoLaLineaLoTrae;
var
  SinPrecio: TOperacionesImportacionFalsas;
  ConPrecio: TOperacionesImportacionFalsas;
  Operaciones: IOperacionesImportacionInventario;
begin
  SinPrecio := TOperacionesImportacionFalsas.Create;
  Operaciones := SinPrecio;
  SinPrecio.FUnidadesConocidas := 'SKU1';
  AplicarImportacionInventario(
    LineasDePrueba('SKU1', 5, 0, False), Operaciones);
  Assert.AreEqual(0, SinPrecio.FPreciosEscritos);
  Assert.AreEqual(1, SinPrecio.FPreciosHistoricos);
  ConPrecio := TOperacionesImportacionFalsas.Create;
  Operaciones := ConPrecio;
  ConPrecio.FUnidadesConocidas := 'SKU1';
  AplicarImportacionInventario(
    LineasDePrueba('SKU1', 5, 7.5, True), Operaciones);
  Assert.AreEqual(1, ConPrecio.FPreciosEscritos);
  Assert.AreEqual(0, ConPrecio.FPreciosHistoricos);
  Assert.AreEqual(Double(7.5), ConPrecio.FUltimoPrecio, 0.0001);
end;

procedure TPruebasInventariosImportacion.
  ImportacionVaciaNoConsolidaCambios;
var
  Falsas: TOperacionesImportacionFalsas;
  Operaciones: IOperacionesImportacionInventario;
  Resumen: TResumenImportacionInventario;
  SinLineas: TLineasImportacionInventario;
begin
  Falsas := TOperacionesImportacionFalsas.Create;
  Operaciones := Falsas;
  SetLength(SinLineas, 0);
  Resumen := AplicarImportacionInventario(SinLineas, Operaciones);
  Assert.AreEqual(0, Resumen.Actualizadas);
  Assert.AreEqual(0, Resumen.Nuevas);
  Assert.AreEqual(0, Falsas.FConsolidaciones);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInventariosAplicacion);
  TDUnitX.RegisterTestFixture(TPruebasInventariosImportacion);

end.
