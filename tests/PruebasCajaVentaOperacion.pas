{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasCajaVentaOperacion                                     }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fija el comportamiento de los helpers de la operacion de venta de         }
{    caja movidos desde TfrmMtoOpeCaja. Sin VCL y sin BBDD: datasets con       }
{    TClientDataSet y lookup de atributos falso en memoria.                    }
{******************************************************************************}
unit PruebasCajaVentaOperacion;

interface

uses
  DUnitX.TestFramework,
  inLibArticulosAtributosIntf;

type
  [TestFixture]
  TPruebasCajaVentaOperacion = class
  public
    // --- cierre de la linea pendiente ---
    [Test]
    procedure Pendiente_InsercionVaciaSeCancela;
    [Test]
    procedure Pendiente_InsercionConArticuloSeGraba;
    [Test]
    procedure Pendiente_EdicionSeGraba;
    [Test]
    procedure Pendiente_EnReposoNoHaceNada;

    // --- reinicio de la operacion ---
    [Test]
    procedure Reinicio_VaciaLineasYPreparaCabecera;
    [Test]
    procedure Reinicio_EscribeValoresBaseCabecera;

    // --- linea rechazada por validacion ---
    [Test]
    procedure Rechazo_InsercionSeCancelaSinBorrar;
    [Test]
    procedure Rechazo_EdicionSeCancelaYSeBorra;
    [Test]
    procedure Rechazo_NilOInactivoNoHaceNada;

    // --- devoluciones y depositos ---
    [Test]
    procedure Negativas_DetectaLaVentaEnNegativo;
    [Test]
    procedure Negativas_IgnoraLosDepositosInclusoConRelleno;
    [Test]
    procedure Negativas_TodoPositivoNoDetecta;
    [Test]
    procedure Depositos_DetectaPrendaYAbono;
    [Test]
    procedure Depositos_SinDepositosNoDetecta;

    // --- operacion vacia ---
    [Test]
    procedure Vacia_CancelaLaInsercionYMiraSiQuedaAlgo;
    [Test]
    procedure Vacia_ConLineasNoEstaVacia;

    // --- fecha de la cabecera ---
    [Test]
    procedure Fecha_EnReposoEditaYGraba;
    [Test]
    procedure Fecha_EnEdicionEscribeSinGrabar;

    // --- atributos por SKU ---
    [Test]
    procedure Atributos_EscribeLosValoresPorOrden;
    [Test]
    procedure Atributos_OrdenFueraDeRangoSeIgnora;
    [Test]
    procedure Atributos_SkuVacioNoTocaLaLinea;
    [Test]
    procedure Avs_DevuelveLosValoresDelLookup;
    [Test]
    procedure Avs_ArticuloVacioUOrdenInvalidoDevuelveVacio;

    // --- preparación del artículo de la línea ---
    [Test]
    procedure Articulo_EntradaManualUsaResolucionGeneral;
    [Test]
    procedure Articulo_EntradaScannerUsaCodigoBarras;
    [Test]
    procedure Articulo_SkuResueltoRellenaLineaYNotifica;
    [Test]
    procedure Articulo_PadreConSkuPendienteRellenaPrecioBase;
    [Test]
    procedure Articulo_SinSkuVendibleDevuelveMotivo;
    [Test]
    procedure Articulo_ActualizacionDepositoNoConsultaStock;

    // --- documento del cierre ---
    [Test]
    procedure Cierre_FacturaCompletaUsaSerieTipoYFecha;
    [Test]
    procedure Cierre_SimplificadaPorDefecto;
    [Test]
    procedure Cierre_RectificativaSiNoAcabaEnFactura;
  end;

  // Caracteriza el nucleo de teclado que antes vivia dentro de
  // TfrmMtoOpeCaja.cxGrid1DBTableView1EditKeyDown. Sin VCL: los cuatro
  // puertos se sustituyen por dobles en memoria.
  [TestFixture]
  TPruebasTeclaLineaCaja = class
  public
    // --- busqueda incremental ---
    [Test]
    procedure Busqueda_TeclaDeContenidoEnArticuloLaReactiva;
    [Test]
    procedure Busqueda_TeclaDeContenidoEnOtraColumnaNoLaReactiva;
    [Test]
    procedure Busqueda_TeclaDeNavegacionNoLaReactiva;
    [Test]
    procedure Busqueda_ConfirmarArticuloLaDetiene;

    // --- retirada de la linea en blanco ---
    [Test]
    procedure Arriba_LineaNuevaSinArticuloSeCancela;
    [Test]
    procedure Arriba_LineaConArticuloNoSeToca;
    [Test]
    procedure Arriba_LineaGrabadaNoSeToca;

    // --- entrada por el buscador de articulos ---
    [Test]
    procedure Intro_FueraDeLaColumnaArticuloNoHaceNada;
    [Test]
    procedure Intro_EditorVacioYBuscadorCanceladoConsumeLaTecla;
    [Test]
    procedure Intro_ArticuloRechazadoAvisaConSuMotivo;
    [Test]
    procedure Intro_ArticuloRechazadoSinMotivoAvisaGenerico;
    [Test]
    procedure Intro_CodigoDelBuscadorSeEscribeEnElEditor;

    // --- confirmacion de la linea ---
    [Test]
    procedure Intro_CierraElDesplegableYPublicaElEditor;
    [Test]
    procedure Intro_ArticuloResueltoRellenaLaLineaVacia;
    [Test]
    procedure Intro_SkuNoVendibleDescartaLaLinea;
    [Test]
    procedure Intro_SkuVendibleVuelcaAtributosYAbreLinea;
    [Test]
    procedure Intro_SinAvanceDeLineaDejaElFocoEnDescripcion;
    [Test]
    procedure Intro_SinAtributosAvanzaSinVolcarAtributos;
    [Test]
    procedure Intro_ConAtributosAbreLaPrimeraColumna;
    [Test]
    procedure Intro_SinColumnaDeAtributoNoConsumeLaTecla;
  end;

  // Decisiones de atributo dinamico (Color, Talla, ...) del nucleo.
  [TestFixture]
  TPruebasAtributosLineaCaja = class
  public
    [Test]
    procedure Sku_CuentaLosAtributosYaResueltos;
    [Test]
    procedure Sku_CompletoCuandoTraeTodosLosAtributos;
    [Test]
    procedure Sku_IgualAlPadreNoEstaCompleto;
    [Test]
    procedure Sku_LineaSinAtributosNoEstaCompleta;
    [Test]
    procedure Sku_AdmitePrecioSoloConLosAtributosCerrados;
    [Test]
    procedure Paso_UltimoAtributoFinalizaLaLinea;
    [Test]
    procedure Paso_AtributoIntermedioAvanza;
    [Test]
    procedure Paso_LineaSinAtributosSiempreAvanza;
  end;

  // Adaptador de la linea sobre su dataset, sin rejilla ni formulario.
  [TestFixture]
  TPruebasLineaVentaCajaDataSet = class
  public
    [Test]
    procedure Linea_InsercionSeReconoceYSeCancela;
    [Test]
    procedure Linea_GrabaYAbreLaSiguiente;
    [Test]
    procedure Linea_EscribeElArticuloSoloEnEdicion;
    [Test]
    procedure Linea_DescarteRetiraLaFilaRechazada;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibCajaVentaOperacion,
  inLibCajaOpePresentacionIntf,
  inLibCajaOpePresentacion,
  inLibMsgCaja,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf;

type
  // Lookup falso: devuelve los valores fijados en el constructor.
  TLookupAtributosFalso = class(
    TInterfacedObject,
    IArticulosAtributosLookup)
  private
    FValores: TArray<TArticuloAtributoValor>;
  public
    constructor Create(
      const AValores: TArray<TArticuloAtributoValor>);
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

  TValidadorArticuloCajaFalso = class(
    TInterfacedObject,
    IArticulosValidador)
  private
    FResolucion: TArtResolucionEntrada;
    FEntradasGenerales: Integer;
    FEntradasCodigoBarras: Integer;
    FUltimaEntrada: string;
  public
    constructor Create(const AResolucion: TArtResolucionEntrada);
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
    property EntradasGenerales: Integer read FEntradasGenerales;
    property EntradasCodigoBarras: Integer read FEntradasCodigoBarras;
    property UltimaEntrada: string read FUltimaEntrada;
  end;

  TResolverArticuloCajaFalso = class(
    TInterfacedObject,
    IArticulosResolver)
  private
    FDatos: TArticuloDatos;
    FPrecio: TArticuloPrecio;
    FLlamadasDatos: Integer;
    FLlamadasPrecio: Integer;
  public
    function ResolverDatos(
      const ACodigoArt, ACodigoSku: string;
      const ACodigoTarifa: string = '';
      const AFecha: TDateTime = 0;
      const ACodigoAlmacen: string = '';
      const ACodigoProveedor: string = ''): TArticuloDatos;
    function ResolverPrecio(
      const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
      const AFecha: TDateTime): TArticuloPrecio;
    function ResolverUltimoCoste(
      const ACodigoArt: string;
      const ACodigoProveedor: string = '';
      const ACodigoSku: string = ''): TArticuloCoste;
    function ResolverPMP(
      const ACodigoSku: string;
      const ACodigoAlmacen: string = ''): TArticuloPMP;
    function ListarSkus(
      const ACodigoArt: string;
      AIncluirInactivos: Boolean = False):
      TArray<TArticuloSkuItem>;
    function DescuentoTarifaVigente(
      const ACodigoTarifa: string;
      const AFecha: TDateTime): Boolean;
    property Datos: TArticuloDatos read FDatos write FDatos;
    property Precio: TArticuloPrecio read FPrecio write FPrecio;
    property LlamadasDatos: Integer read FLlamadasDatos;
    property LlamadasPrecio: Integer read FLlamadasPrecio;
  end;

  TObservadorCodigoCaja = class
  private
    FConsultasStock: Integer;
    FRecalculosPrecio: Integer;
    FUltimoStock: string;
    FUltimoPrecio: string;
  public
    procedure ConsultarStock(const ACodigo: string);
    procedure RecalcularPrecio(const ACodigo: string);
    property ConsultasStock: Integer read FConsultasStock;
    property RecalculosPrecio: Integer read FRecalculosPrecio;
    property UltimoStock: string read FUltimoStock;
    property UltimoPrecio: string read FUltimoPrecio;
  end;

constructor TLookupAtributosFalso.Create(
  const AValores: TArray<TArticuloAtributoValor>);
begin
  inherited Create;
  FValores := AValores;
end;

function TLookupAtributosFalso.ObtenerAtributos(
  const ACodigoArticulo: string): TArray<TArticuloAtributo>;
begin
  Result := nil;
end;

function TLookupAtributosFalso.ObtenerPropiedades(
  const ACodigoArticulo: string): TArray<TArticuloPropiedad>;
begin
  Result := nil;
end;

function TLookupAtributosFalso.ObtenerAtributosDeSku(
  const ACodigoSku: string): TArray<TArticuloAtributoValor>;
begin
  Result := FValores;
end;

function TLookupAtributosFalso.ObtenerAvsEnSkus(
  const ACodigoArticulo: string;
  AOrdenAtributo: Integer): TArray<TArticuloAtributoValor>;
begin
  Result := FValores;
end;

constructor TValidadorArticuloCajaFalso.Create(
  const AResolucion: TArtResolucionEntrada);
begin
  inherited Create;
  FResolucion := AResolucion;
end;

function TValidadorArticuloCajaFalso.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Inc(FEntradasGenerales);
  FUltimaEntrada := AEntrada;
  Result := FResolucion;
end;

function TValidadorArticuloCajaFalso.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Inc(FEntradasCodigoBarras);
  FUltimaEntrada := AEntrada;
  Result := FResolucion;
end;

function TValidadorArticuloCajaFalso.ResolverConSku(
  const AEntrada, ACodigoSkuPreferido: string):
  TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorArticuloCajaFalso.EsValido(
  const AEntrada: string): Boolean;
begin
  Result := FResolucion.Encontrado;
end;

function TValidadorArticuloCajaFalso.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FResolucion.SkuActivo;
end;

function TResolverArticuloCajaFalso.ResolverDatos(
  const ACodigoArt, ACodigoSku: string;
  const ACodigoTarifa: string;
  const AFecha: TDateTime;
  const ACodigoAlmacen: string;
  const ACodigoProveedor: string): TArticuloDatos;
begin
  Inc(FLlamadasDatos);
  Result := FDatos;
end;

function TResolverArticuloCajaFalso.ResolverPrecio(
  const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
  const AFecha: TDateTime): TArticuloPrecio;
begin
  Inc(FLlamadasPrecio);
  Result := FPrecio;
end;

function TResolverArticuloCajaFalso.ResolverUltimoCoste(
  const ACodigoArt: string;
  const ACodigoProveedor: string;
  const ACodigoSku: string): TArticuloCoste;
begin
  Result := Default(TArticuloCoste);
end;

function TResolverArticuloCajaFalso.ResolverPMP(
  const ACodigoSku: string;
  const ACodigoAlmacen: string): TArticuloPMP;
begin
  Result := Default(TArticuloPMP);
end;

function TResolverArticuloCajaFalso.ListarSkus(
  const ACodigoArt: string;
  AIncluirInactivos: Boolean): TArray<TArticuloSkuItem>;
begin
  Result := nil;
end;

function TResolverArticuloCajaFalso.DescuentoTarifaVigente(
  const ACodigoTarifa: string;
  const AFecha: TDateTime): Boolean;
begin
  Result := False;
end;

procedure TObservadorCodigoCaja.ConsultarStock(
  const ACodigo: string);
begin
  Inc(FConsultasStock);
  FUltimoStock := ACodigo;
end;

procedure TObservadorCodigoCaja.RecalcularPrecio(
  const ACodigo: string);
begin
  Inc(FRecalculosPrecio);
  FUltimoPrecio := ACodigo;
end;

function Valor(AOrden: Integer; const AValor: string):
  TArticuloAtributoValor;
begin
  Result := Default(TArticuloAtributoValor);
  Result.Orden := AOrden;
  Result.Valor := AValor;
end;

function ResolucionArticulo(
  const ACodigoArticulo, ACodigoSku: string;
  ARequiereSku: Boolean;
  const AMensaje: string = ''): TArtResolucionEntrada;
begin
  Result.Clear;
  Result.Encontrado := True;
  Result.CodigoArticulo := ACodigoArticulo;
  Result.CodigoSku := ACodigoSku;
  Result.DescripcionArticulo := 'ARTICULO DE PRUEBA';
  Result.TipoArticulo := 'NORMAL';
  Result.NumAtributosReq := 2;
  Result.RequiereSku := ARequiereSku;
  Result.SkuActivo := ACodigoSku <> '';
  Result.Mensaje := AMensaje;
end;

function CrearLineas: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('CODIGO_ART_FACLIN', ftString, 20);
  Result.FieldDefs.Add('CODIGO_UNIDAD_FACLIN', ftString, 40);
  Result.FieldDefs.Add('DESCRIPCION_ARTICULO_FACLIN', ftString, 80);
  Result.FieldDefs.Add('TIPO_ARTICULO_FACLIN', ftString, 20);
  Result.FieldDefs.Add(
    'NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger);
  Result.FieldDefs.Add('TIPO_IVA_ARTICULO_FACLIN', ftString, 20);
  Result.FieldDefs.Add('ESIMP_INCL_TARIFA_FACLIN', ftString, 1);
  Result.FieldDefs.Add('PORCENTAJE_DTO_FACLIN', ftFloat);
  Result.FieldDefs.Add('PRECIO_SALIDA_FACLIN', ftCurrency);
  Result.FieldDefs.Add('PRECIO_DTO_FACLIN', ftCurrency);
  Result.FieldDefs.Add(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN', ftCurrency);
  Result.FieldDefs.Add(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN', ftCurrency);
  Result.FieldDefs.Add('VIENE_DE_DEPOSITO', ftString, 3);
  Result.FieldDefs.Add('CANTIDAD_FACLIN', ftFloat);
  Result.FieldDefs.Add('ATTR1_VALOR', ftString, 20);
  Result.FieldDefs.Add('ATTR2_VALOR', ftString, 20);
  Result.FieldDefs.Add('ATTR3_VALOR', ftString, 20);
  Result.FieldDefs.Add('ATTR4_VALOR', ftString, 20);
  Result.FieldDefs.Add('ATTR5_VALOR', ftString, 20);
  Result.CreateDataSet;
end;

procedure AgregarLinea(ALineas: TClientDataSet;
  const AArticulo, AVieneDeDeposito: string; ACantidad: Double);
begin
  ALineas.Append;
  ALineas.FieldByName('CODIGO_ART_FACLIN').AsString := AArticulo;
  ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString :=
    AVieneDeDeposito;
  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := ACantidad;
  ALineas.Post;
end;

function CrearCabecera: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('FECHA_FAC', ftDateTime);
  Result.FieldDefs.Add('CODIGO_EMP_FAC', ftString, 10);
  Result.FieldDefs.Add('TIPO_FAC', ftString, 20);
  Result.FieldDefs.Add('TARIFA_ARTICULO_CLIENTE_FAC', ftString, 10);
  Result.CreateDataSet;
  Result.Append;
  Result.Post;
end;

{ --- cierre de la linea pendiente --- }

procedure TPruebasCajaVentaOperacion.Pendiente_InsercionVaciaSeCancela;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    cds.Append;
    CerrarLineaPendiente(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Pendiente_InsercionConArticuloSeGraba;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    cds.Append;
    cds.FieldByName('CODIGO_ART_FACLIN').AsString := 'ART1';
    CerrarLineaPendiente(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Pendiente_EdicionSeGraba;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    cds.Edit;
    cds.FieldByName('CODIGO_ART_FACLIN').AsString := '';
    CerrarLineaPendiente(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual('',
      cds.FieldByName('CODIGO_ART_FACLIN').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Pendiente_EnReposoNoHaceNada;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    CerrarLineaPendiente(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

{ --- reinicio de la operacion --- }

procedure TPruebasCajaVentaOperacion.
  Reinicio_VaciaLineasYPreparaCabecera;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  try
    AgregarLinea(Lineas, 'ART1', 'N', 1);
    ReiniciarDatosOperacionVenta(Lineas, Cabecera);
    Assert.AreEqual(0, Lineas.RecordCount);
    Assert.AreEqual(0, Cabecera.RecordCount);
    Assert.IsTrue(Cabecera.State = dsInsert);
  finally
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Reinicio_EscribeValoresBaseCabecera;
var
  Cabecera: TClientDataSet;
begin
  Cabecera := CrearCabecera;
  try
    Cabecera.Edit;
    EscribirCabeceraBaseOperacionVenta(
      Cabecera, 'E1', 'PVP', EncodeDate(2026, 7, 31));
    Assert.AreEqual('E1',
      Cabecera.FieldByName('CODIGO_EMP_FAC').AsString);
    Assert.AreEqual('SIMPLIFICADA',
      Cabecera.FieldByName('TIPO_FAC').AsString);
    Assert.AreEqual('PVP',
      Cabecera.FieldByName(
        'TARIFA_ARTICULO_CLIENTE_FAC').AsString);
    Assert.IsTrue(
      Cabecera.FieldByName('FECHA_FAC').AsDateTime =
        EncodeDate(2026, 7, 31));
  finally
    FreeAndNil(Cabecera);
  end;
end;

{ --- linea rechazada por validacion --- }

procedure TPruebasCajaVentaOperacion.
  Rechazo_InsercionSeCancelaSinBorrar;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    cds.Append;
    EliminarLineaVentaPorValidacion(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Rechazo_EdicionSeCancelaYSeBorra;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    AgregarLinea(cds, 'ART2', 'N', 1);
    cds.Edit;
    EliminarLineaVentaPorValidacion(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Rechazo_NilOInactivoNoHaceNada;
var
  cds: TClientDataSet;
begin
  EliminarLineaVentaPorValidacion(nil);
  cds := TClientDataSet.Create(nil);
  try
    EliminarLineaVentaPorValidacion(cds);
    Assert.IsFalse(cds.Active);
  finally
    FreeAndNil(cds);
  end;
end;

{ --- devoluciones y depositos --- }

procedure TPruebasCajaVentaOperacion.
  Negativas_DetectaLaVentaEnNegativo;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    AgregarLinea(cds, 'ART2', '', -1);
    Assert.IsTrue(HayLineasNegativasVenta(cds));
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Negativas_IgnoraLosDepositosInclusoConRelleno;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    // Cancelaciones de deposito: negativas pero con circuito propio.
    AgregarLinea(cds, 'ART1', 'S', -1);
    AgregarLinea(cds, 'ART2', ' A ', -2);
    Assert.IsFalse(HayLineasNegativasVenta(cds));
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Negativas_TodoPositivoNoDetecta;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    Assert.IsFalse(HayLineasNegativasVenta(cds));
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Depositos_DetectaPrendaYAbono;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    AgregarLinea(cds, 'ART2', 'A', 1);
    Assert.IsTrue(HayLineasDepositoVenta(cds));
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Depositos_SinDepositosNoDetecta;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    AgregarLinea(cds, 'ART2', '', 1);
    Assert.IsFalse(HayLineasDepositoVenta(cds));
  finally
    FreeAndNil(cds);
  end;
end;

{ --- operacion vacia --- }

procedure TPruebasCajaVentaOperacion.
  Vacia_CancelaLaInsercionYMiraSiQuedaAlgo;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    cds.Append;
    Assert.IsTrue(OperacionVentaVacia(cds));
    Assert.IsTrue(cds.State = dsBrowse);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Vacia_ConLineasNoEstaVacia;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    Assert.IsFalse(OperacionVentaVacia(cds));
  finally
    FreeAndNil(cds);
  end;
end;

{ --- fecha de la cabecera --- }

procedure TPruebasCajaVentaOperacion.Fecha_EnReposoEditaYGraba;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    EscribirFechaCabeceraVenta(cds, EncodeDate(2026, 7, 31));
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.IsTrue(
      cds.FieldByName('FECHA_FAC').AsDateTime =
        EncodeDate(2026, 7, 31));
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Fecha_EnEdicionEscribeSinGrabar;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    cds.Edit;
    EscribirFechaCabeceraVenta(cds, EncodeDate(2026, 7, 31));
    Assert.IsTrue(cds.State = dsEdit);
    Assert.IsTrue(
      cds.FieldByName('FECHA_FAC').AsDateTime =
        EncodeDate(2026, 7, 31));
  finally
    FreeAndNil(cds);
  end;
end;

{ --- atributos por SKU --- }

procedure TPruebasCajaVentaOperacion.Atributos_EscribeLosValoresPorOrden;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    RellenarAtributosLineaDesdeSku(cds, 'SKU1',
      TLookupAtributosFalso.Create(
        [Valor(1, 'ROJO'), Valor(2, '42')]));
    Assert.AreEqual('ROJO', cds.FieldByName('ATTR1_VALOR').AsString);
    Assert.AreEqual('42', cds.FieldByName('ATTR2_VALOR').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Atributos_OrdenFueraDeRangoSeIgnora;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    RellenarAtributosLineaDesdeSku(cds, 'SKU1',
      TLookupAtributosFalso.Create(
        [Valor(0, 'X'), Valor(6, 'Y'), Valor(5, 'AZUL')]));
    Assert.AreEqual('AZUL', cds.FieldByName('ATTR5_VALOR').AsString);
    Assert.AreEqual('', cds.FieldByName('ATTR1_VALOR').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Atributos_SkuVacioNoTocaLaLinea;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    RellenarAtributosLineaDesdeSku(cds, '  ',
      TLookupAtributosFalso.Create([Valor(1, 'ROJO')]));
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual('', cds.FieldByName('ATTR1_VALOR').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaOperacion.Avs_DevuelveLosValoresDelLookup;
var
  Avs: TArray<string>;
begin
  CargarAvsValidosArticulo('ART1', 1,
    TLookupAtributosFalso.Create(
      [Valor(1, 'S'), Valor(2, 'M'), Valor(3, 'L')]), Avs);
  Assert.AreEqual(3, Integer(Length(Avs)));
  Assert.AreEqual('S', Avs[0]);
  Assert.AreEqual('L', Avs[2]);
end;

procedure TPruebasCajaVentaOperacion.
  Avs_ArticuloVacioUOrdenInvalidoDevuelveVacio;
var
  Avs: TArray<string>;
begin
  CargarAvsValidosArticulo('', 1,
    TLookupAtributosFalso.Create([Valor(1, 'S')]), Avs);
  Assert.AreEqual(0, Integer(Length(Avs)));
  CargarAvsValidosArticulo('ART1', 6,
    TLookupAtributosFalso.Create([Valor(1, 'S')]), Avs);
  Assert.AreEqual(0, Integer(Length(Avs)));
end;

{ --- preparación del artículo de la línea --- }

procedure TPruebasCajaVentaOperacion.
  Articulo_EntradaManualUsaResolucionGeneral;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Observador: TObservadorCodigoCaja;
  ValidadorFalso: TValidadorArticuloCajaFalso;
  ResolverFalso: TResolverArticuloCajaFalso;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
  Resultado: TResultadoPreparacionArticuloVenta;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  Observador := TObservadorCodigoCaja.Create;
  ValidadorFalso := TValidadorArticuloCajaFalso.Create(
    ResolucionArticulo('ART1', 'ART1/ROJO/M', False));
  ResolverFalso := TResolverArticuloCajaFalso.Create;
  Validador := ValidadorFalso;
  Resolver := ResolverFalso;
  try
    Lineas.Append;
    Resultado := PrepararArticuloLineaVenta(
      Lineas, Cabecera, '  art1  ', False, False,
      Validador, Resolver, Observador.ConsultarStock,
      Observador.RecalcularPrecio);
    Assert.IsTrue(Resultado.Preparado);
    Assert.AreEqual(1, ValidadorFalso.EntradasGenerales);
    Assert.AreEqual(0, ValidadorFalso.EntradasCodigoBarras);
    Assert.AreEqual('ART1', ValidadorFalso.UltimaEntrada);
  finally
    Resolver := nil;
    Validador := nil;
    FreeAndNil(Observador);
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Articulo_EntradaScannerUsaCodigoBarras;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Observador: TObservadorCodigoCaja;
  ValidadorFalso: TValidadorArticuloCajaFalso;
  ResolverFalso: TResolverArticuloCajaFalso;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  Observador := TObservadorCodigoCaja.Create;
  ValidadorFalso := TValidadorArticuloCajaFalso.Create(
    ResolucionArticulo('ART1', 'ART1/ROJO/M', False));
  ResolverFalso := TResolverArticuloCajaFalso.Create;
  Validador := ValidadorFalso;
  Resolver := ResolverFalso;
  try
    Lineas.Append;
    PrepararArticuloLineaVenta(
      Lineas, Cabecera, 'ean-13', True, False,
      Validador, Resolver, Observador.ConsultarStock,
      Observador.RecalcularPrecio);
    Assert.AreEqual(0, ValidadorFalso.EntradasGenerales);
    Assert.AreEqual(1, ValidadorFalso.EntradasCodigoBarras);
    Assert.AreEqual('EAN-13', ValidadorFalso.UltimaEntrada);
  finally
    Resolver := nil;
    Validador := nil;
    FreeAndNil(Observador);
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Articulo_SkuResueltoRellenaLineaYNotifica;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Observador: TObservadorCodigoCaja;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  Observador := TObservadorCodigoCaja.Create;
  Validador := TValidadorArticuloCajaFalso.Create(
    ResolucionArticulo('ART1', 'ART1/ROJO/M', False));
  Resolver := TResolverArticuloCajaFalso.Create;
  try
    Lineas.Append;
    PrepararArticuloLineaVenta(
      Lineas, Cabecera, 'ART1', False, False,
      Validador, Resolver, Observador.ConsultarStock,
      Observador.RecalcularPrecio);
    Assert.AreEqual('ART1',
      Lineas.FieldByName('CODIGO_ART_FACLIN').AsString);
    Assert.AreEqual('ART1/ROJO/M',
      Lineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
    Assert.AreEqual('ARTICULO DE PRUEBA',
      Lineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString);
    Assert.AreEqual(2,
      Lineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger);
    Assert.AreEqual(1, Observador.ConsultasStock);
    Assert.AreEqual(1, Observador.RecalculosPrecio);
    Assert.AreEqual('ART1/ROJO/M', Observador.UltimoStock);
    Assert.AreEqual('ART1/ROJO/M', Observador.UltimoPrecio);
  finally
    Resolver := nil;
    Validador := nil;
    FreeAndNil(Observador);
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Articulo_PadreConSkuPendienteRellenaPrecioBase;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Observador: TObservadorCodigoCaja;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
  ResolverFalso: TResolverArticuloCajaFalso;
  Datos: TArticuloDatos;
  Precio: TArticuloPrecio;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  Observador := TObservadorCodigoCaja.Create;
  Validador := TValidadorArticuloCajaFalso.Create(
    ResolucionArticulo('ART1', '', True));
  ResolverFalso := TResolverArticuloCajaFalso.Create;
  Datos.Clear;
  Datos.TipoIVA := 'GENERAL';
  ResolverFalso.Datos := Datos;
  Precio.Clear;
  Precio.EsImpIncl := True;
  Precio.PorcentajeDto := 12.5;
  ResolverFalso.Precio := Precio;
  Resolver := ResolverFalso;
  try
    Cabecera.Edit;
    Cabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString := 'T1';
    Cabecera.FieldByName('FECHA_FAC').AsDateTime :=
      EncodeDate(2026, 8, 1);
    Cabecera.Post;
    Lineas.Append;
    PrepararArticuloLineaVenta(
      Lineas, Cabecera, 'ART1', False, False,
      Validador, Resolver, Observador.ConsultarStock,
      Observador.RecalcularPrecio);
    Assert.AreEqual('ART1',
      Lineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
    Assert.AreEqual('GENERAL',
      Lineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
    Assert.AreEqual('S',
      Lineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString);
    Assert.AreEqual(12.5,
      Lineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat, 0.001);
    Assert.AreEqual(1.0,
      Lineas.FieldByName('CANTIDAD_FACLIN').AsFloat, 0.001);
    Assert.AreEqual(1, ResolverFalso.LlamadasDatos);
    Assert.AreEqual(1, ResolverFalso.LlamadasPrecio);
    Assert.AreEqual('ART1', Observador.UltimoStock);
    Assert.AreEqual(0, Observador.RecalculosPrecio);
  finally
    Resolver := nil;
    Validador := nil;
    FreeAndNil(Observador);
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Articulo_SinSkuVendibleDevuelveMotivo;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Observador: TObservadorCodigoCaja;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
  Resultado: TResultadoPreparacionArticuloVenta;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  Observador := TObservadorCodigoCaja.Create;
  Validador := TValidadorArticuloCajaFalso.Create(
    ResolucionArticulo(
      'ART1', '', False, 'El artículo no tiene SKU vendible.'));
  Resolver := TResolverArticuloCajaFalso.Create;
  try
    Lineas.Append;
    Resultado := PrepararArticuloLineaVenta(
      Lineas, Cabecera, 'ART1', False, False,
      Validador, Resolver, Observador.ConsultarStock,
      Observador.RecalcularPrecio);
    Assert.IsFalse(Resultado.Preparado);
    Assert.AreEqual(
      'El artículo no tiene SKU vendible.',
      Resultado.MotivoRechazo);
    Assert.AreEqual('ART1',
      Lineas.FieldByName('CODIGO_ART_FACLIN').AsString);
    Assert.AreEqual(0, Observador.ConsultasStock);
  finally
    Resolver := nil;
    Validador := nil;
    FreeAndNil(Observador);
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

procedure TPruebasCajaVentaOperacion.
  Articulo_ActualizacionDepositoNoConsultaStock;
var
  Cabecera: TClientDataSet;
  Lineas: TClientDataSet;
  Observador: TObservadorCodigoCaja;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
begin
  Cabecera := CrearCabecera;
  Lineas := CrearLineas;
  Observador := TObservadorCodigoCaja.Create;
  Validador := TValidadorArticuloCajaFalso.Create(
    ResolucionArticulo('ART1', 'ART1/ROJO/M', False));
  Resolver := TResolverArticuloCajaFalso.Create;
  try
    Lineas.Append;
    PrepararArticuloLineaVenta(
      Lineas, Cabecera, 'ART1', False, True,
      Validador, Resolver, Observador.ConsultarStock,
      Observador.RecalcularPrecio);
    Assert.AreEqual(0, Observador.ConsultasStock);
    Assert.AreEqual(1, Observador.RecalculosPrecio);
  finally
    Resolver := nil;
    Validador := nil;
    FreeAndNil(Observador);
    FreeAndNil(Lineas);
    FreeAndNil(Cabecera);
  end;
end;

{ --- documento del cierre --- }

procedure TPruebasCajaVentaOperacion.
  Cierre_FacturaCompletaUsaSerieTipoYFecha;
var
  D: TDocumentoCierreVenta;
begin
  D := ResolverDocumentoCierreVenta(
    True, 'T', 'F', EncodeDate(2026, 7, 31), True);
  Assert.AreEqual('F', D.Serie);
  Assert.AreEqual('NORMAL', D.TipoFactura);
  Assert.IsTrue(D.FechaFactura = EncodeDate(2026, 7, 31));
end;

procedure TPruebasCajaVentaOperacion.Cierre_SimplificadaPorDefecto;
var
  D: TDocumentoCierreVenta;
begin
  D := ResolverDocumentoCierreVenta(
    False, 'T', 'F', EncodeDate(2026, 7, 31), False);
  Assert.AreEqual('T', D.Serie);
  Assert.AreEqual('SIMPLIFICADA', D.TipoFactura);
  Assert.IsTrue(D.FechaFactura = 0);
end;

procedure TPruebasCajaVentaOperacion.
  Cierre_RectificativaSiNoAcabaEnFactura;
var
  D: TDocumentoCierreVenta;
begin
  D := ResolverDocumentoCierreVenta(
    False, 'T', 'F', 0, True);
  Assert.AreEqual('T', D.Serie);
  Assert.AreEqual('RECTIFICATIVA', D.TipoFactura);
end;


type
  TRejillaLineaCajaFalsa = class(
    TInterfacedObject,
    IRejillaLineaCaja)
  private
    FRol: TRolColumnaLineaCaja;
    FTexto: string;
    FEscrito: string;
    FDesplegablesCerrados: Integer;
    FPublicaciones: Integer;
    FReactivaciones: Integer;
    FDetenciones: Integer;
    FDestinos: Integer;
    FUltimoDestino: TDestinoFocoLineaCaja;
    FHayColumnaAtributo: Boolean;
  public
    constructor Create;
    function RolColumnaActiva: TRolColumnaLineaCaja;
    function TextoEditor: string;
    procedure EscribirEditor(const AValor: string);
    procedure CerrarDesplegable;
    procedure PublicarValorEditor;
    procedure ReactivarBusquedaIncremental;
    procedure DetenerBusquedaIncremental;
    function EnfocarYEditar(
      ADestino: TDestinoFocoLineaCaja): Boolean;
    property Rol: TRolColumnaLineaCaja read FRol write FRol;
    property Texto: string read FTexto write FTexto;
    property Escrito: string read FEscrito;
    property DesplegablesCerrados: Integer
      read FDesplegablesCerrados;
    property Publicaciones: Integer read FPublicaciones;
    property Reactivaciones: Integer read FReactivaciones;
    property Detenciones: Integer read FDetenciones;
    property Destinos: Integer read FDestinos;
    property UltimoDestino: TDestinoFocoLineaCaja
      read FUltimoDestino;
    property HayColumnaAtributo: Boolean
      read FHayColumnaAtributo write FHayColumnaAtributo;
  end;

  TLineaVentaCajaFalsa = class(
    TInterfacedObject,
    ILineaVentaCaja)
  private
    FInsertando: Boolean;
    FArticulo: string;
    FSku: string;
    FEdiciones: Integer;
    FCancelaciones: Integer;
    FGrabaciones: Integer;
    FDescartes: Integer;
  public
    function EstaInsertando: Boolean;
    function CodigoArticulo: string;
    procedure EscribirCodigoArticulo(const ACodigo: string);
    function CodigoSku: string;
    procedure AsegurarEdicion;
    procedure CancelarLinea;
    procedure GrabarYAnadirLinea;
    procedure DescartarLineaRechazada;
    property Insertando: Boolean read FInsertando
                                 write FInsertando;
    property Articulo: string read FArticulo write FArticulo;
    property Sku: string read FSku write FSku;
    property Ediciones: Integer read FEdiciones;
    property Cancelaciones: Integer read FCancelaciones;
    property Grabaciones: Integer read FGrabaciones;
    property Descartes: Integer read FDescartes;
  end;

  // El doble conserva el articulo resuelto tras
  // OlvidarArticuloResuelto: en produccion lo repone la validacion
  // que dispara PostEditValue.
  TArticuloLineaCajaFalso = class(
    TInterfacedObject,
    IArticuloLineaCaja,
    IAvisosOperacionCaja)
  private
    FCodigoBuscador: string;
    FCargaCorrecta: Boolean;
    FMotivo: string;
    FResuelto: string;
    FAtributos: Integer;
    FVendible: Boolean;
    FAvanzar: Boolean;
    FOlvidos: Integer;
    FBusquedas: Integer;
    FArticuloPreparado: string;
    FVolcados: string;
    FAviso: string;
  public
    constructor Create;
    function BuscarArticulo: string;
    function CargarArticulo(const ACodigo: string): Boolean;
    function MotivoRechazo: string;
    function ArticuloResuelto: string;
    procedure OlvidarArticuloResuelto;
    function PrepararColumnasAtributos(
      const AArticulo: string): Integer;
    function SkuVendible(const ACodigoSku: string): Boolean;
    procedure VolcarAtributosDeSku(const ACodigoSku: string);
    function AvanzarDeLinea: Boolean;
    procedure Avisar(const AMensaje: string);
    property CodigoBuscador: string read FCodigoBuscador
                                    write FCodigoBuscador;
    property CargaCorrecta: Boolean read FCargaCorrecta
                                    write FCargaCorrecta;
    property Motivo: string read FMotivo write FMotivo;
    property Resuelto: string read FResuelto write FResuelto;
    property Atributos: Integer read FAtributos write FAtributos;
    property Vendible: Boolean read FVendible write FVendible;
    property Avanzar: Boolean read FAvanzar write FAvanzar;
    property Olvidos: Integer read FOlvidos;
    property Busquedas: Integer read FBusquedas;
    property ArticuloPreparado: string read FArticuloPreparado;
    property Volcados: string read FVolcados;
    property Aviso: string read FAviso;
  end;

constructor TRejillaLineaCajaFalsa.Create;
begin
  inherited Create;
  FRol := rclArticulo;
  FHayColumnaAtributo := True;
end;

function TRejillaLineaCajaFalsa.RolColumnaActiva:
  TRolColumnaLineaCaja;
begin
  Result := FRol;
end;

function TRejillaLineaCajaFalsa.TextoEditor: string;
begin
  Result := FTexto;
end;

procedure TRejillaLineaCajaFalsa.EscribirEditor(
  const AValor: string);
begin
  FEscrito := AValor;
  FTexto := AValor;
end;

procedure TRejillaLineaCajaFalsa.CerrarDesplegable;
begin
  Inc(FDesplegablesCerrados);
end;

procedure TRejillaLineaCajaFalsa.PublicarValorEditor;
begin
  Inc(FPublicaciones);
end;

procedure TRejillaLineaCajaFalsa.ReactivarBusquedaIncremental;
begin
  Inc(FReactivaciones);
end;

procedure TRejillaLineaCajaFalsa.DetenerBusquedaIncremental;
begin
  Inc(FDetenciones);
end;

function TRejillaLineaCajaFalsa.EnfocarYEditar(
  ADestino: TDestinoFocoLineaCaja): Boolean;
begin
  Result := (ADestino <> dflPrimerAtributo) or
            FHayColumnaAtributo;
  if Result then
  begin
    Inc(FDestinos);
    FUltimoDestino := ADestino;
  end;
end;

function TLineaVentaCajaFalsa.EstaInsertando: Boolean;
begin
  Result := FInsertando;
end;

function TLineaVentaCajaFalsa.CodigoArticulo: string;
begin
  Result := FArticulo;
end;

procedure TLineaVentaCajaFalsa.EscribirCodigoArticulo(
  const ACodigo: string);
begin
  FArticulo := ACodigo;
end;

function TLineaVentaCajaFalsa.CodigoSku: string;
begin
  Result := FSku;
end;

procedure TLineaVentaCajaFalsa.AsegurarEdicion;
begin
  Inc(FEdiciones);
end;

procedure TLineaVentaCajaFalsa.CancelarLinea;
begin
  Inc(FCancelaciones);
end;

procedure TLineaVentaCajaFalsa.GrabarYAnadirLinea;
begin
  Inc(FGrabaciones);
end;

procedure TLineaVentaCajaFalsa.DescartarLineaRechazada;
begin
  Inc(FDescartes);
end;

constructor TArticuloLineaCajaFalso.Create;
begin
  inherited Create;
  FCargaCorrecta := True;
  FVendible := True;
  FAvanzar := True;
end;

function TArticuloLineaCajaFalso.BuscarArticulo: string;
begin
  Inc(FBusquedas);
  Result := FCodigoBuscador;
end;

function TArticuloLineaCajaFalso.CargarArticulo(
  const ACodigo: string): Boolean;
begin
  Result := FCargaCorrecta;
end;

function TArticuloLineaCajaFalso.MotivoRechazo: string;
begin
  Result := FMotivo;
end;

function TArticuloLineaCajaFalso.ArticuloResuelto: string;
begin
  Result := FResuelto;
end;

procedure TArticuloLineaCajaFalso.OlvidarArticuloResuelto;
begin
  Inc(FOlvidos);
end;

function TArticuloLineaCajaFalso.PrepararColumnasAtributos(
  const AArticulo: string): Integer;
begin
  FArticuloPreparado := AArticulo;
  Result := FAtributos;
end;

function TArticuloLineaCajaFalso.SkuVendible(
  const ACodigoSku: string): Boolean;
begin
  Result := FVendible;
end;

procedure TArticuloLineaCajaFalso.VolcarAtributosDeSku(
  const ACodigoSku: string);
begin
  FVolcados := FVolcados + ACodigoSku + ';';
end;

function TArticuloLineaCajaFalso.AvanzarDeLinea: Boolean;
begin
  Result := FAvanzar;
end;

procedure TArticuloLineaCajaFalso.Avisar(const AMensaje: string);
begin
  FAviso := AMensaje;
end;

procedure PrepararTeclaLineaCaja(
  out ARejilla: TRejillaLineaCajaFalsa;
  out ALinea: TLineaVentaCajaFalsa;
  out AArticulo: TArticuloLineaCajaFalso;
  out AProcesador: IProcesadorTeclaLineaCaja);
var
  PuertoRejilla: IRejillaLineaCaja;
  PuertoLinea: ILineaVentaCaja;
  PuertoArticulo: IArticuloLineaCaja;
  PuertoAvisos: IAvisosOperacionCaja;
begin
  ARejilla := TRejillaLineaCajaFalsa.Create;
  PuertoRejilla := ARejilla;
  ALinea := TLineaVentaCajaFalsa.Create;
  PuertoLinea := ALinea;
  AArticulo := TArticuloLineaCajaFalso.Create;
  PuertoArticulo := AArticulo;
  PuertoAvisos := AArticulo;
  AProcesador := CrearProcesadorTeclaLineaCaja(
    PuertoRejilla,
    PuertoLinea,
    PuertoArticulo,
    PuertoAvisos);
end;

{ --- busqueda incremental --- }

procedure TPruebasTeclaLineaCaja.
  Busqueda_TeclaDeContenidoEnArticuloLaReactiva;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Rol := rclArticulo;
  Assert.IsFalse(Procesador.Procesar(tocOtra));
  Assert.AreEqual(1, Rejilla.Reactivaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Busqueda_TeclaDeContenidoEnOtraColumnaNoLaReactiva;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Rol := rclOtra;
  Assert.IsFalse(Procesador.Procesar(tocOtra));
  Assert.AreEqual(0, Rejilla.Reactivaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Busqueda_TeclaDeNavegacionNoLaReactiva;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Rol := rclArticulo;
  Assert.IsFalse(Procesador.Procesar(tocNavegacion));
  Assert.AreEqual(0, Rejilla.Reactivaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Busqueda_ConfirmarArticuloLaDetiene;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Rol := rclArticulo;
  Rejilla.Texto := 'ART1';
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual(1, Rejilla.Detenciones);
  Assert.AreEqual(0, Rejilla.Reactivaciones);
end;

{ --- retirada de la linea en blanco --- }

procedure TPruebasTeclaLineaCaja.
  Arriba_LineaNuevaSinArticuloSeCancela;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Linea.Insertando := True;
  Linea.Articulo := '   ';
  Assert.IsTrue(Procesador.Procesar(tocArriba));
  Assert.AreEqual(1, Linea.Cancelaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Arriba_LineaConArticuloNoSeToca;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Linea.Insertando := True;
  Linea.Articulo := 'ART1';
  Assert.IsFalse(Procesador.Procesar(tocArriba));
  Assert.AreEqual(0, Linea.Cancelaciones);
end;

procedure TPruebasTeclaLineaCaja.Arriba_LineaGrabadaNoSeToca;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Linea.Insertando := False;
  Linea.Articulo := '';
  Assert.IsFalse(Procesador.Procesar(tocArriba));
  Assert.AreEqual(0, Linea.Cancelaciones);
end;

{ --- entrada por el buscador de articulos --- }

procedure TPruebasTeclaLineaCaja.
  Intro_FueraDeLaColumnaArticuloNoHaceNada;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Rol := rclOtra;
  Assert.IsFalse(Procesador.Procesar(tocIntro));
  Assert.AreEqual(0, Rejilla.Detenciones);
  Assert.AreEqual(0, Rejilla.Publicaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_EditorVacioYBuscadorCanceladoConsumeLaTecla;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := '';
  Articulo.CodigoBuscador := '';
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual(1, Articulo.Busquedas);
  Assert.AreEqual(0, Rejilla.Publicaciones);
  Assert.AreEqual(0, Linea.Grabaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_ArticuloRechazadoAvisaConSuMotivo;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := '';
  Articulo.CodigoBuscador := 'ART9';
  Articulo.CargaCorrecta := False;
  Articulo.Motivo := 'Sin SKU vendible';
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual('Sin SKU vendible', Articulo.Aviso);
  Assert.AreEqual(0, Rejilla.Publicaciones);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_ArticuloRechazadoSinMotivoAvisaGenerico;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := '';
  Articulo.CodigoBuscador := 'ART9';
  Articulo.CargaCorrecta := False;
  Articulo.Motivo := '';
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual(
    SErrorArticuloVentaCajaNoEncontrado, Articulo.Aviso);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_CodigoDelBuscadorSeEscribeEnElEditor;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := '';
  Articulo.CodigoBuscador := 'ART9';
  Articulo.CargaCorrecta := True;
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual('ART9', Rejilla.Escrito);
  Assert.AreEqual(1, Rejilla.Publicaciones);
end;

{ --- confirmacion de la linea --- }

procedure TPruebasTeclaLineaCaja.
  Intro_CierraElDesplegableYPublicaElEditor;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual(1, Rejilla.DesplegablesCerrados);
  Assert.AreEqual(1, Rejilla.Publicaciones);
  Assert.AreEqual(1, Linea.Ediciones);
  Assert.AreEqual(1, Articulo.Olvidos);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_ArticuloResueltoRellenaLaLineaVacia;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Linea.Articulo := '';
  Articulo.Resuelto := 'ART1';
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual('ART1', Linea.Articulo);
  Assert.AreEqual('ART1', Articulo.ArticuloPreparado);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_SkuNoVendibleDescartaLaLinea;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Linea.Articulo := 'ART1';
  Linea.Sku := 'ART1/AZUL';
  Articulo.Vendible := False;
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual(1, Linea.Descartes);
  Assert.AreEqual(0, Linea.Grabaciones);
  Assert.AreEqual('', Articulo.Volcados);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_SkuVendibleVuelcaAtributosYAbreLinea;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Linea.Articulo := 'ART1';
  Linea.Sku := 'ART1/AZUL';
  Articulo.Vendible := True;
  Articulo.Avanzar := True;
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual('ART1/AZUL;', Articulo.Volcados);
  Assert.AreEqual(1, Linea.Grabaciones);
  Assert.IsTrue(Rejilla.UltimoDestino = dflArticulo);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_SinAvanceDeLineaDejaElFocoEnDescripcion;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Linea.Articulo := 'ART1';
  Linea.Sku := 'ART1/AZUL';
  Articulo.Avanzar := False;
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual(0, Linea.Grabaciones);
  Assert.IsTrue(Rejilla.UltimoDestino = dflDescripcion);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_SinAtributosAvanzaSinVolcarAtributos;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Linea.Articulo := 'ART1';
  Linea.Sku := '';
  Articulo.Atributos := 0;
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual('', Articulo.Volcados);
  Assert.AreEqual(1, Linea.Grabaciones);
  Assert.IsTrue(Rejilla.UltimoDestino = dflArticulo);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_ConAtributosAbreLaPrimeraColumna;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Rejilla.HayColumnaAtributo := True;
  Linea.Articulo := 'ART1';
  Linea.Sku := 'ART1';
  Articulo.Atributos := 2;
  Assert.IsTrue(Procesador.Procesar(tocIntro));
  Assert.AreEqual('ART1;', Articulo.Volcados);
  Assert.AreEqual(0, Linea.Grabaciones);
  Assert.IsTrue(Rejilla.UltimoDestino = dflPrimerAtributo);
end;

procedure TPruebasTeclaLineaCaja.
  Intro_SinColumnaDeAtributoNoConsumeLaTecla;
var
  Rejilla: TRejillaLineaCajaFalsa;
  Linea: TLineaVentaCajaFalsa;
  Articulo: TArticuloLineaCajaFalso;
  Procesador: IProcesadorTeclaLineaCaja;
begin
  PrepararTeclaLineaCaja(Rejilla, Linea, Articulo, Procesador);
  Rejilla.Texto := 'ART1';
  Rejilla.HayColumnaAtributo := False;
  Linea.Articulo := 'ART1';
  Linea.Sku := 'ART1';
  Articulo.Atributos := 2;
  Assert.IsFalse(Procesador.Procesar(tocIntro));
  Assert.AreEqual(0, Rejilla.Destinos);
end;

{ --- decisiones de atributo dinamico --- }

procedure TPruebasAtributosLineaCaja.
  Sku_CuentaLosAtributosYaResueltos;
begin
  Assert.AreEqual(0, AtributosResueltosSkuCaja('ART1'));
  Assert.AreEqual(1, AtributosResueltosSkuCaja('ART1/AZUL'));
  Assert.AreEqual(2, AtributosResueltosSkuCaja('ART1/AZUL/42'));
end;

procedure TPruebasAtributosLineaCaja.
  Sku_CompletoCuandoTraeTodosLosAtributos;
begin
  Assert.IsTrue(
    SkuLineaCajaCompleto('ART1', 'ART1/AZUL/42', 2));
  Assert.IsFalse(
    SkuLineaCajaCompleto('ART1', 'ART1/AZUL', 2));
end;

procedure TPruebasAtributosLineaCaja.
  Sku_IgualAlPadreNoEstaCompleto;
begin
  Assert.IsFalse(SkuLineaCajaCompleto('ART1', 'ART1', 2));
  Assert.IsFalse(SkuLineaCajaCompleto('', 'ART1/AZUL', 1));
end;

procedure TPruebasAtributosLineaCaja.
  Sku_LineaSinAtributosNoEstaCompleta;
begin
  Assert.IsFalse(SkuLineaCajaCompleto('ART1', 'ART1/AZUL', 0));
end;

procedure TPruebasAtributosLineaCaja.
  Sku_AdmitePrecioSoloConLosAtributosCerrados;
begin
  Assert.IsTrue(SkuLineaCajaAdmitePrecio('ART1/AZUL', 1));
  Assert.IsFalse(SkuLineaCajaAdmitePrecio('ART1', 1));
  Assert.IsFalse(SkuLineaCajaAdmitePrecio('ART1', 0));
end;

procedure TPruebasAtributosLineaCaja.
  Paso_UltimoAtributoFinalizaLaLinea;
begin
  Assert.IsTrue(
    PasoTrasAtributoLineaCaja(2, 2) = palFinalizar);
end;

procedure TPruebasAtributosLineaCaja.
  Paso_AtributoIntermedioAvanza;
begin
  Assert.IsTrue(
    PasoTrasAtributoLineaCaja(1, 2) = palAvanzar);
end;

procedure TPruebasAtributosLineaCaja.
  Paso_LineaSinAtributosSiempreAvanza;
begin
  Assert.IsTrue(
    PasoTrasAtributoLineaCaja(0, 0) = palAvanzar);
end;

{ --- adaptador de la linea sobre el dataset --- }

procedure TPruebasLineaVentaCajaDataSet.
  Linea_InsercionSeReconoceYSeCancela;
var
  cds: TClientDataSet;
  Linea: ILineaVentaCaja;
begin
  cds := CrearLineas;
  try
    Linea := CrearLineaVentaCajaDataSet(cds);
    Assert.IsFalse(Linea.EstaInsertando);
    cds.Append;
    Assert.IsTrue(Linea.EstaInsertando);
    Linea.CancelarLinea;
    Assert.IsFalse(Linea.EstaInsertando);
  finally
    Linea := nil;
    FreeAndNil(cds);
  end;
end;

procedure TPruebasLineaVentaCajaDataSet.
  Linea_GrabaYAbreLaSiguiente;
var
  cds: TClientDataSet;
  Linea: ILineaVentaCaja;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    Linea := CrearLineaVentaCajaDataSet(cds);
    cds.Append;
    cds.FieldByName('CODIGO_ART_FACLIN').AsString := 'ART2';
    Linea.GrabarYAnadirLinea;
    Assert.IsTrue(Linea.EstaInsertando);
    Linea.CancelarLinea;
    Assert.AreEqual(2, cds.RecordCount);
  finally
    Linea := nil;
    FreeAndNil(cds);
  end;
end;

procedure TPruebasLineaVentaCajaDataSet.
  Linea_EscribeElArticuloSoloEnEdicion;
var
  cds: TClientDataSet;
  Linea: ILineaVentaCaja;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    Linea := CrearLineaVentaCajaDataSet(cds);
    Linea.EscribirCodigoArticulo('ART9');
    Assert.AreEqual('ART1', Linea.CodigoArticulo);
    Linea.AsegurarEdicion;
    Linea.EscribirCodigoArticulo('ART9');
    Assert.AreEqual('ART9', Linea.CodigoArticulo);
  finally
    Linea := nil;
    FreeAndNil(cds);
  end;
end;

procedure TPruebasLineaVentaCajaDataSet.
  Linea_DescarteRetiraLaFilaRechazada;
var
  cds: TClientDataSet;
  Linea: ILineaVentaCaja;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N', 1);
    Linea := CrearLineaVentaCajaDataSet(cds);
    cds.Edit;
    Linea.DescartarLineaRechazada;
    Assert.IsTrue(cds.IsEmpty);
  finally
    Linea := nil;
    FreeAndNil(cds);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCajaVentaOperacion);
  TDUnitX.RegisterTestFixture(TPruebasTeclaLineaCaja);
  TDUnitX.RegisterTestFixture(TPruebasAtributosLineaCaja);
  TDUnitX.RegisterTestFixture(TPruebasLineaVentaCajaDataSet);

end.
