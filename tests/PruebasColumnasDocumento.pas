{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasColumnasDocumento                                     }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las columnas visuales comunes de los documentos.               }
{******************************************************************************}
unit PruebasColumnasDocumento;

interface

uses
  System.SysUtils, Vcl.Controls, DUnitX.TestFramework, cxEdit,
  cxGridCustomTableView, cxGridDBTableView;

type
  [TestFixture]
  TPruebasColumnasDocumento = class
  private
    FVista: TcxGridDBTableView;
    FAccionesAsegurar: Integer;
    FAccionesConstruir: Integer;
    FAccionesDesempaquetar: Integer;
    FBotonPulsado: Boolean;
    FEntroEnEdicion: Boolean;
    FResolvioSku: Boolean;
    FSalioDeEdicion: Boolean;
    procedure AccionAsegurar;
    procedure AccionConstruir;
    procedure AccionDesempaquetar;
    procedure CambiarValorTalla(Sender: TObject);
    procedure EntrarEnEdicion(Sender: TObject);
    procedure ObtenerTextoAtributo(Sender: TcxCustomGridTableItem;
      ARecordIndex: Integer; var AText: string);
    procedure ResolverSku(const ACodArt, ASku, ADescripcion: string;
      ACompleto: Boolean);
    procedure PulsarBoton(Sender: TObject; AButtonIndex: Integer);
    procedure SalirDeEdicion(Sender: TObject);
    procedure ValidarTalla(Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Tallas_CreaColumnasNumericasOcultas;
    [Test]
    procedure Atributos_CreaColumnasNoEditables;
    [Test]
    procedure Atributos_ConservaCallbackDeTexto;
    [Test]
    procedure VistaNula_NoModificaReferencias;
    [Test]
    procedure Visibilidad_ActualizaSoloColumnasAsignadas;
    [Test]
    procedure CaptionComun_ConservaModosYEspaciado;
    [Test]
    procedure CaptionConBandas_DistingueLosDosPivotes;
    [Test]
    procedure CaptionsAtributos_RestableceYAplicaNombres;
    [Test]
    procedure AtributosGlobales_AplicaSoloTagsPositivos;
    [Test]
    procedure AtributosGlobales_SinConexionConservaVista;
    [Test]
    procedure CargaCaptions_ConsultaNulaConservaCaption;
    [Test]
    procedure CargaCaptions_SinLineasSoloRestablece;
    [Test]
    procedure PrepararReconstruccion_LimpiaVistaYReferencias;
    [Test]
    procedure ConstruccionComun_CableaEventos;
    [Test]
    procedure ConstruccionComun_DegradaModoPermitido;
    [Test]
    procedure ConstruccionComun_PropagaModoNoDegradable;
    [Test]
    procedure ColumnaBusqueda_ConfiguraBotonYValidacion;
    [Test]
    procedure ColumnaColorPivote_AplicaConfiguracionBase;
    [Test]
    procedure NavegacionModo_DecideAccionComun;
    [Test]
    procedure EntradaGrid_ReconstruyeYAseguraLinea;
    [Test]
    procedure LiberacionComun_ToleraFalloDeDesmontaje;
    [Test]
    procedure Teclado_CiclaModosYReconstruye;
    [Test]
    procedure Teclado_IgnoraContextoTeclaOModificadores;
    [Test]
    procedure CambioModo_ReconstruyeSoloCuandoCambia;
    [Test]
    procedure PreferenciaPivote_PersisteValorValido;
    [Test]
    procedure PreferenciaPivote_IgnoraDataSetNoDisponible;
    [Test]
    procedure Foto_ResuelveArticuloSkuDeLaVista;
    [Test]
    procedure Foto_SeleccionaCabeceraYDetalleDeLaVista;
    [Test]
    procedure DataModule_ReutilizaOCreaInstancia;
    [Test]
    procedure DataModule_RechazaClaseIncompatible;
    [Test]
    procedure TablaPrincipal_CableaCabeceraLineasDetallesYClave;
    [Test]
    procedure ConfigSku_DerivaCamposPorPrefijo;
    [Test]
    procedure ColumnaHost_AplicaPropiedades;
    [Test]
    procedure ColumnasHostCompra_DerivaCamposPorPrefijo;
    [Test]
    procedure ColumnasHostCompra_BandasOmiteCantidad;
    [Test]
    procedure ConfigBandas_DerivaCamposBase;
    [Test]
    procedure ConfigTallas_DerivaCamposPorPrefijo;
    [Test]
    procedure ConfigPivote_DerivaCamposBasicos;
    [Test]
    procedure ConfigPivote_PedidoIncluyeRecepcionYColor;
    [Test]
    procedure EventosTallas_SeAsignanAColumnasNumericas;
  end;

implementation

uses
  System.Classes, Winapi.Windows, Vcl.Forms, Data.DB, Datasnap.DBClient, Uni,
  cxButtonEdit, cxDataStorage, cxCurrencyEdit,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibGridPivoteCompra,
  inLibGridPivoteVenta, inLibColumnasDocumento, UniDataGen;

type
  TdmDocumentoPrueba = class(TdmBase)
  protected
    procedure DoCreate; override;
  public
    property MaestroCabecera: TDataSource read FMaestroCabecera;
  end;

  TModoEntradaPrueba = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConstrucciones: Integer;
    FEditoresMostrados: Integer;
    FFallarAlConstruir: Boolean;
    FFallarAlDesmontar: Boolean;
    FOnEntrarEdicion: TNotifyEvent;
    FOnResuelto: TSkuResueltoEvent;
    FOnSalirEdicion: TNotifyEvent;
    function GetModo: TModoColumnasSku;
    function GetOnEntrarEdicion: TNotifyEvent;
    function GetOnResuelto: TSkuResueltoEvent;
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
  public
    constructor Create(AFallarAlConstruir: Boolean;
      AFallarAlDesmontar: Boolean = False);
    procedure Construir;
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
    procedure SetAlmacenStock(const AValue: string);
    property Construcciones: Integer read FConstrucciones;
    property EditoresMostrados: Integer read FEditoresMostrados;
  end;

procedure TdmDocumentoPrueba.DoCreate;
begin
end;

constructor TModoEntradaPrueba.Create(AFallarAlConstruir: Boolean;
  AFallarAlDesmontar: Boolean);
begin
  inherited Create;
  FFallarAlConstruir := AFallarAlConstruir;
  FFallarAlDesmontar := AFallarAlDesmontar;
end;

procedure TModoEntradaPrueba.Construir;
begin
  Inc(FConstrucciones);
  if FFallarAlConstruir then
    raise Exception.Create('Fallo controlado');
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Self);
  if Assigned(FOnResuelto) then
    FOnResuelto('ART', 'SKU', 'Artículo', True);
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Self);
end;

procedure TModoEntradaPrueba.Desmontar;
begin
  if FFallarAlDesmontar then
    raise Exception.Create('Fallo de desmontaje controlado');
end;

function TModoEntradaPrueba.GetModo: TModoColumnasSku;
begin
  Result := mcsSku;
end;

function TModoEntradaPrueba.GetOnEntrarEdicion: TNotifyEvent;
begin
  Result := FOnEntrarEdicion;
end;

function TModoEntradaPrueba.GetOnResuelto: TSkuResueltoEvent;
begin
  Result := FOnResuelto;
end;

function TModoEntradaPrueba.GetOnSalirEdicion: TNotifyEvent;
begin
  Result := FOnSalirEdicion;
end;

procedure TModoEntradaPrueba.MostrarEditor;
begin
  Inc(FEditoresMostrados);
end;

function TModoEntradaPrueba.ResolverEntrada(
  const AEntrada: string): Boolean;
begin
  Result := False;
end;

procedure TModoEntradaPrueba.SetAlmacenStock(const AValue: string);
begin
end;

procedure TModoEntradaPrueba.SetOnEntrarEdicion(
  const AValue: TNotifyEvent);
begin
  FOnEntrarEdicion := AValue;
end;

procedure TModoEntradaPrueba.SetOnResuelto(
  const AValue: TSkuResueltoEvent);
begin
  FOnResuelto := AValue;
end;

procedure TModoEntradaPrueba.SetOnSalirEdicion(
  const AValue: TNotifyEvent);
begin
  FOnSalirEdicion := AValue;
end;

procedure TPruebasColumnasDocumento.Preparar;
begin
  FVista := TcxGridDBTableView.Create(nil);
  FAccionesAsegurar := 0;
  FAccionesConstruir := 0;
  FAccionesDesempaquetar := 0;
  FBotonPulsado := False;
  FEntroEnEdicion := False;
  FResolvioSku := False;
  FSalioDeEdicion := False;
end;

procedure TPruebasColumnasDocumento.AccionAsegurar;
begin
  Inc(FAccionesAsegurar);
end;

procedure TPruebasColumnasDocumento.AccionConstruir;
begin
  Inc(FAccionesConstruir);
end;

procedure TPruebasColumnasDocumento.AccionDesempaquetar;
begin
  Inc(FAccionesDesempaquetar);
end;

procedure TPruebasColumnasDocumento.Limpiar;
begin
  FreeAndNil(FVista);
end;

procedure TPruebasColumnasDocumento.CambiarValorTalla(Sender: TObject);
begin
end;

procedure TPruebasColumnasDocumento.EntrarEnEdicion(Sender: TObject);
begin
  FEntroEnEdicion := True;
end;

procedure TPruebasColumnasDocumento.ObtenerTextoAtributo(
  Sender: TcxCustomGridTableItem; ARecordIndex: Integer;
  var AText: string);
begin
  AText := IntToStr(ARecordIndex);
end;

procedure TPruebasColumnasDocumento.ResolverSku(
  const ACodArt, ASku, ADescripcion: string;
  ACompleto: Boolean);
begin
  FResolvioSku := (ACodArt = 'ART') and (ASku = 'SKU') and
    (ADescripcion = 'Artículo') and ACompleto;
end;

procedure TPruebasColumnasDocumento.PulsarBoton(
  Sender: TObject; AButtonIndex: Integer);
begin
  FBotonPulsado := AButtonIndex = 0;
end;

procedure TPruebasColumnasDocumento.SalirDeEdicion(Sender: TObject);
begin
  FSalioDeEdicion := True;
end;

procedure TPruebasColumnasDocumento.ValidarTalla(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
begin
  Error := False;
end;

procedure TPruebasColumnasDocumento.
  Tallas_CreaColumnasNumericasOcultas;
var
  aColumnas: TArray<TcxGridDBColumn>;
begin
  SetLength(aColumnas, 3);
  CrearColumnasTallasDocumento(FVista, 'dbcPruebaTalla', 55,
    aColumnas);
  Assert.AreEqual(3, FVista.ColumnCount);
  Assert.IsTrue(aColumnas[0] = FVista.Columns[0]);
  Assert.AreEqual('dbcPruebaTalla01', aColumnas[0].Name);
  Assert.AreEqual('dbcPruebaTalla03', aColumnas[2].Name);
  Assert.AreEqual('', aColumnas[0].Caption);
  Assert.AreEqual(55, aColumnas[0].Width);
  Assert.AreEqual(1, Integer(aColumnas[0].Tag));
  Assert.AreEqual(3, Integer(aColumnas[2].Tag));
  Assert.IsFalse(aColumnas[0].Visible);
  Assert.IsTrue(aColumnas[0].DataBinding.ValueTypeClass =
    TcxFloatValueType);
  Assert.IsTrue(aColumnas[0].Properties is
    TcxCurrencyEditProperties);
  Assert.AreEqual('#,##0',
    TcxCurrencyEditProperties(aColumnas[0].Properties).DisplayFormat);
end;

procedure TPruebasColumnasDocumento.
  Atributos_CreaColumnasNoEditables;
var
  aColumnas: TArray<TcxGridDBColumn>;
begin
  SetLength(aColumnas, 2);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnas);
  Assert.AreEqual(2, FVista.ColumnCount);
  Assert.IsTrue(aColumnas[1] = FVista.Columns[1]);
  Assert.AreEqual('dbcPruebaAtrib01', aColumnas[0].Name);
  Assert.AreEqual('dbcPruebaAtrib02', aColumnas[1].Name);
  Assert.AreEqual('', aColumnas[0].Caption);
  Assert.AreEqual(90, aColumnas[0].Width);
  Assert.AreEqual(-1, Integer(aColumnas[0].Tag));
  Assert.AreEqual(-2, Integer(aColumnas[1].Tag));
  Assert.IsFalse(aColumnas[0].Visible);
  Assert.IsFalse(aColumnas[0].Options.Editing);
  Assert.IsFalse(Assigned(aColumnas[0].OnGetDataText));
end;

procedure TPruebasColumnasDocumento.
  Atributos_ConservaCallbackDeTexto;
var
  aColumnas: TArray<TcxGridDBColumn>;
begin
  SetLength(aColumnas, 1);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnas, ObtenerTextoAtributo);
  Assert.IsTrue(Assigned(aColumnas[0].OnGetDataText));
end;

procedure TPruebasColumnasDocumento.
  VistaNula_NoModificaReferencias;
var
  aColumnas: TArray<TcxGridDBColumn>;
begin
  SetLength(aColumnas, 2);
  CrearColumnasTallasDocumento(nil, 'dbcPruebaTalla', 50,
    aColumnas);
  CrearColumnasAtributosDocumento(nil, 'dbcPruebaAtrib', aColumnas);
  Assert.IsFalse(Assigned(aColumnas[0]));
  Assert.IsFalse(Assigned(aColumnas[1]));
end;

procedure TPruebasColumnasDocumento.
  Visibilidad_ActualizaSoloColumnasAsignadas;
var
  aColumnas: TArray<TcxGridDBColumn>;
begin
  SetLength(aColumnas, 3);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnas);
  aColumnas[1] := nil;
  EstablecerVisibilidadColumnasDocumento(aColumnas, True);
  Assert.IsTrue(aColumnas[0].Visible);
  Assert.IsFalse(FVista.Columns[1].Visible);
  Assert.IsTrue(aColumnas[2].Visible);
  EstablecerVisibilidadColumnasDocumento(aColumnas, False);
  Assert.IsFalse(aColumnas[0].Visible);
  Assert.IsFalse(aColumnas[2].Visible);
end;

procedure TPruebasColumnasDocumento.
  CaptionComun_ConservaModosYEspaciado;
begin
  Assert.AreEqual('Líneas ',
    CaptionModoLineasDocumento('Líneas', 'Líneas ', False,
      mcsSku, False));
  Assert.AreEqual('Líneas [SKU]',
    CaptionModoLineasDocumento('Líneas', 'Líneas ', True,
      mcsSku, False));
  Assert.AreEqual('Líneas [Tallas horiz.]',
    CaptionModoLineasDocumento('Líneas', 'Líneas ', True,
      mcsTallasHorPed, False));
  Assert.AreEqual('Líneas [Desglose]',
    CaptionModoLineasDocumento('Líneas', 'Líneas ', True,
      mcsTallasInline, False));
  Assert.AreEqual('Líneas [Desglose]',
    CaptionModoLineasDocumento('Líneas', 'Líneas ', True,
      mcsDesglose, False));
end;

procedure TPruebasColumnasDocumento.
  CaptionConBandas_DistingueLosDosPivotes;
begin
  Assert.AreEqual('Líneas',
    CaptionModoLineasDocumento('Líneas', 'Líneas', False,
      mcsTallasInline, True));
  Assert.AreEqual('Líneas [Tallas horiz.]',
    CaptionModoLineasDocumento('Líneas', 'Líneas', True,
      mcsTallasInline, True));
  Assert.AreEqual('Líneas [Tallas horiz. bandas]',
    CaptionModoLineasDocumento('Líneas', 'Líneas', True,
      mcsTallasHorPed, True));
end;

procedure TPruebasColumnasDocumento.
  CaptionsAtributos_RestableceYAplicaNombres;
var
  aColumnas: TArray<TcxGridDBColumn>;
  aNombres: TArray<string>;
begin
  SetLength(aColumnas, 3);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnas);
  aColumnas[0].Caption := 'Anterior';
  aColumnas[1].Caption := 'Anterior';
  aColumnas[2].Caption := 'Anterior';
  RestablecerCaptionsAtributosDocumento(aColumnas);
  Assert.AreEqual('Atributo 1', aColumnas[0].Caption);
  Assert.AreEqual('Atributo 2', aColumnas[1].Caption);
  Assert.AreEqual('Atributo 3', aColumnas[2].Caption);
  aNombres := ['Color', 'Talla'];
  AplicarNombresAtributosDocumento(aColumnas, aNombres);
  Assert.AreEqual('Color', aColumnas[0].Caption);
  Assert.AreEqual('Talla', aColumnas[1].Caption);
  Assert.AreEqual('Atributo 3', aColumnas[2].Caption);
end;

procedure TPruebasColumnasDocumento.
  AtributosGlobales_AplicaSoloTagsPositivos;
var
  oColumnaColor: TcxGridDBColumn;
  oColumnaColorDuplicada: TcxGridDBColumn;
  oColumnaPropia: TcxGridDBColumn;
  oColumnaTalla: TcxGridDBColumn;
begin
  oColumnaColor := FVista.CreateColumn;
  oColumnaColor.Tag := 1;
  oColumnaColor.Caption := 'Anterior';
  oColumnaColor.Visible := False;
  oColumnaTalla := FVista.CreateColumn;
  oColumnaTalla.Tag := 2;
  oColumnaTalla.Caption := 'Anterior';
  oColumnaTalla.Visible := False;
  oColumnaPropia := FVista.CreateColumn;
  oColumnaPropia.Tag := -1;
  oColumnaPropia.Caption := 'Propia';
  oColumnaPropia.Visible := False;
  oColumnaColorDuplicada := FVista.CreateColumn;
  oColumnaColorDuplicada.Tag := 1;
  oColumnaColorDuplicada.Caption := 'Anterior';
  oColumnaColorDuplicada.Visible := False;
  AplicarNombresAtributosGlobalesDocumento(
    FVista, ['Color', 'Talla']);
  Assert.AreEqual('Color', oColumnaColor.Caption);
  Assert.IsTrue(oColumnaColor.Visible);
  Assert.AreEqual('Color', oColumnaColorDuplicada.Caption);
  Assert.IsTrue(oColumnaColorDuplicada.Visible);
  Assert.AreEqual('Talla', oColumnaTalla.Caption);
  Assert.IsTrue(oColumnaTalla.Visible);
  Assert.AreEqual('Propia', oColumnaPropia.Caption);
  Assert.IsFalse(oColumnaPropia.Visible);
end;

procedure TPruebasColumnasDocumento.
  AtributosGlobales_SinConexionConservaVista;
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := FVista.CreateColumn;
  oColumna.Tag := 1;
  oColumna.Caption := 'Anterior';
  oColumna.Visible := False;
  MostrarColumnasAtributoGlobalesDocumento(nil, FVista);
  MostrarColumnasAtributoGlobalesDocumento(nil, nil);
  AplicarNombresAtributosGlobalesDocumento(nil, ['Color']);
  Assert.AreEqual('Anterior', oColumna.Caption);
  Assert.IsFalse(oColumna.Visible);
end;

procedure TPruebasColumnasDocumento.
  CargaCaptions_ConsultaNulaConservaCaption;
var
  aColumnas: TArray<TcxGridDBColumn>;
begin
  SetLength(aColumnas, 1);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnas);
  aColumnas[0].Caption := 'Sin consulta';
  CargarCaptionsAtributosDocumento(nil, nil, 'CODIGO_ART',
    aColumnas);
  Assert.AreEqual('Sin consulta', aColumnas[0].Caption);
end;

procedure TPruebasColumnasDocumento.
  CargaCaptions_SinLineasSoloRestablece;
var
  aColumnas: TArray<TcxGridDBColumn>;
  oConsulta: TUniQuery;
begin
  SetLength(aColumnas, 2);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnas);
  aColumnas[0].Caption := 'Anterior';
  aColumnas[1].Caption := 'Anterior';
  oConsulta := TUniQuery.Create(nil);
  try
    CargarCaptionsAtributosDocumento(oConsulta, nil, 'CODIGO_ART',
      aColumnas);
    Assert.AreEqual('Atributo 1', aColumnas[0].Caption);
    Assert.AreEqual('Atributo 2', aColumnas[1].Caption);
    Assert.IsFalse(oConsulta.Active);
  finally
    oConsulta.Free;
  end;
end;

procedure TPruebasColumnasDocumento.
  PrepararReconstruccion_LimpiaVistaYReferencias;
var
  aColumnasTallas: TArray<TcxGridDBColumn>;
  aColumnasAtributos: TArray<TcxGridDBColumn>;
  oColColor: TcxGridDBColumn;
  oDataSet: TClientDataSet;
  oModoEntrada: IModoEntradaGrid;
begin
  SetLength(aColumnasTallas, 2);
  SetLength(aColumnasAtributos, 2);
  CrearColumnasTallasDocumento(FVista, 'dbcPruebaTalla', 50,
    aColumnasTallas);
  CrearColumnasAtributosDocumento(FVista, 'dbcPruebaAtrib',
    aColumnasAtributos);
  oColColor := FVista.CreateColumn;
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('ID', ftInteger);
    oDataSet.CreateDataSet;
    oDataSet.Append;
    PrepararReconstruccionModoDocumento(FVista, oDataSet,
      oModoEntrada, aColumnasTallas, aColumnasAtributos,
      oColColor);
    Assert.AreEqual(0, FVista.ColumnCount);
    Assert.IsTrue(oDataSet.State = dsBrowse);
    Assert.IsFalse(Assigned(oModoEntrada));
    Assert.IsFalse(Assigned(aColumnasTallas[0]));
    Assert.IsFalse(Assigned(aColumnasTallas[1]));
    Assert.IsFalse(Assigned(aColumnasAtributos[0]));
    Assert.IsFalse(Assigned(aColumnasAtributos[1]));
    Assert.IsFalse(Assigned(oColColor));
  finally
    oDataSet.Free;
  end;
end;

procedure TPruebasColumnasDocumento.
  ConstruccionComun_CableaEventos;
var
  oImplementacion: TModoEntradaPrueba;
  oModoEntrada: IModoEntradaGrid;
begin
  oImplementacion := TModoEntradaPrueba.Create(False);
  oModoEntrada := oImplementacion;
  Assert.IsTrue(ConstruirModoEntradaDocumento(
    oModoEntrada, ResolverSku, EntrarEnEdicion, SalirDeEdicion,
    mcsSku, [], 'Prueba'));
  Assert.AreEqual(1, oImplementacion.Construcciones);
  Assert.IsTrue(FEntroEnEdicion);
  Assert.IsTrue(FResolvioSku);
  Assert.IsTrue(FSalioDeEdicion);
end;

procedure TPruebasColumnasDocumento.
  ConstruccionComun_DegradaModoPermitido;
var
  oImplementacion: TModoEntradaPrueba;
  oModoEntrada: IModoEntradaGrid;
begin
  oImplementacion := TModoEntradaPrueba.Create(True);
  oModoEntrada := oImplementacion;
  Assert.IsFalse(ConstruirModoEntradaDocumento(
    oModoEntrada, ResolverSku, EntrarEnEdicion, SalirDeEdicion,
    mcsTallasHorPed, [mcsTallasHorPed], 'Prueba'));
  Assert.AreEqual(1, oImplementacion.Construcciones);
  Assert.IsFalse(FEntroEnEdicion);
  Assert.IsFalse(FResolvioSku);
  Assert.IsFalse(FSalioDeEdicion);
end;

procedure TPruebasColumnasDocumento.
  ConstruccionComun_PropagaModoNoDegradable;
var
  bPropagada: Boolean;
  oModoEntrada: IModoEntradaGrid;
begin
  oModoEntrada := TModoEntradaPrueba.Create(True);
  bPropagada := False;
  try
    ConstruirModoEntradaDocumento(
      oModoEntrada, ResolverSku, EntrarEnEdicion, SalirDeEdicion,
      mcsSku, [mcsTallasHorPed], 'Prueba');
  except
    on E: Exception do
      bPropagada := E.Message = 'Fallo controlado';
  end;
  Assert.IsTrue(bPropagada);
end;

procedure TPruebasColumnasDocumento.
  ColumnaBusqueda_ConfiguraBotonYValidacion;
var
  oColumna: TcxGridDBColumn;
  oResultado: TcxGridDBColumn;
  oPropiedades: TcxButtonEditProperties;
begin
  oColumna := FVista.CreateColumn;
  oColumna.DataBinding.FieldName := 'CODIGO';
  oResultado := ConfigurarColumnaBusquedaDocumento(
    FVista, 'CODIGO', PulsarBoton, ValidarTalla);
  Assert.IsTrue(oResultado = oColumna);
  Assert.IsTrue(oColumna.Properties is
    TcxButtonEditProperties);
  Assert.IsTrue(oColumna.Options.ShowEditButtons = isebAlways);
  oPropiedades := TcxButtonEditProperties(oColumna.Properties);
  Assert.AreEqual(1, oPropiedades.Buttons.Count);
  Assert.IsTrue(oPropiedades.Buttons[0].Kind = bkEllipsis);
  Assert.IsTrue(Assigned(oPropiedades.OnButtonClick));
  Assert.IsTrue(Assigned(oPropiedades.OnValidate));
  oPropiedades.OnButtonClick(oPropiedades, 0);
  Assert.IsTrue(FBotonPulsado);
end;

procedure TPruebasColumnasDocumento.
  ColumnaColorPivote_AplicaConfiguracionBase;
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := CrearColumnaColorPivoteDocumento(
    FVista, 'colColorPrueba', 130);
  Assert.IsTrue(Assigned(oColumna));
  Assert.AreEqual('colColorPrueba', oColumna.Name);
  Assert.AreEqual('Color', oColumna.Caption);
  Assert.AreEqual(130, oColumna.Width);
  Assert.IsFalse(oColumna.Visible);
  Assert.IsTrue(oColumna.Options.Editing);
end;

procedure TPruebasColumnasDocumento.
  NavegacionModo_DecideAccionComun;
var
  oLineas: TClientDataSet;
  oMaster: TClientDataSet;
  oSourceMaster: TDataSource;
begin
  oLineas := TClientDataSet.Create(nil);
  oMaster := TClientDataSet.Create(nil);
  oSourceMaster := TDataSource.Create(nil);
  try
    oLineas.FieldDefs.Add('ID', ftInteger);
    oLineas.CreateDataSet;
    oMaster.FieldDefs.Add('ID', ftInteger);
    oMaster.CreateDataSet;
    oSourceMaster.DataSet := oMaster;
    ActualizarModoEntradaAlNavegarDocumento(
      nil, oLineas, oSourceMaster, False, mcsSku, False,
      AccionConstruir, AccionDesempaquetar);
    ActualizarModoEntradaAlNavegarDocumento(
      nil, oLineas, oSourceMaster, True, mcsAuto, False,
      AccionConstruir, AccionDesempaquetar);
    ActualizarModoEntradaAlNavegarDocumento(
      oLineas.FieldByName('ID'), oLineas, oSourceMaster,
      False, mcsSku, False,
      AccionConstruir, AccionDesempaquetar);
    ActualizarModoEntradaAlNavegarDocumento(
      nil, oLineas, oSourceMaster, True, mcsTallasHorPed, True,
      AccionConstruir, AccionDesempaquetar);
    oMaster.Append;
    ActualizarModoEntradaAlNavegarDocumento(
      nil, oLineas, oSourceMaster, False, mcsSku, False,
      AccionConstruir, AccionDesempaquetar);
    oMaster.Cancel;
    Assert.AreEqual(2, FAccionesConstruir);
    Assert.AreEqual(1, FAccionesDesempaquetar);
  finally
    FreeAndNil(oSourceMaster);
    FreeAndNil(oMaster);
    FreeAndNil(oLineas);
  end;
end;

procedure TPruebasColumnasDocumento.
  EntradaGrid_ReconstruyeYAseguraLinea;
var
  oFormulario: TForm;
  oImplementacion: TModoEntradaPrueba;
  oModoEntrada: IModoEntradaGrid;
begin
  oFormulario := TForm.Create(nil);
  try
    oImplementacion := TModoEntradaPrueba.Create(False);
    oModoEntrada := oImplementacion;
    EntrarGridLineasDocumento(
      oFormulario, False, False, oModoEntrada,
      AccionAsegurar, AccionConstruir);
    EntrarGridLineasDocumento(
      oFormulario, True, False, oModoEntrada,
      AccionAsegurar, AccionConstruir);
    Assert.AreEqual(3, FAccionesAsegurar);
    Assert.AreEqual(1, FAccionesConstruir);
    Assert.AreEqual(2, oImplementacion.EditoresMostrados);
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TPruebasColumnasDocumento.
  LiberacionComun_ToleraFalloDeDesmontaje;
var
  oGestorTallas: TGestorGridTallas;
  oModoEntrada: IModoEntradaGrid;
  oPivote: TGridPivoteCompra;
begin
  oGestorTallas := nil;
  oPivote := nil;
  oModoEntrada := TModoEntradaPrueba.Create(False, True);
  LiberarModoYGestoresDocumento(
    oModoEntrada, oPivote, oGestorTallas);
  Assert.IsFalse(Assigned(oModoEntrada));
  Assert.IsFalse(Assigned(oPivote));
  Assert.IsFalse(Assigned(oGestorTallas));
end;

procedure TPruebasColumnasDocumento.Teclado_CiclaModosYReconstruye;
var
  iTecla: Word;
  Modo: TModoColumnasSku;
begin
  Modo := mcsAuto;
  iTecla := VK_F1;
  Assert.IsTrue(ProcesarTeclaCambioModoDocumento(
    iTecla, [], True, Modo,
    [mcsAuto, mcsSku, mcsTallasInline, mcsTallasHorPed],
    AccionConstruir));
  Assert.AreEqual(Integer(mcsSku), Integer(Modo));
  Assert.AreEqual(0, Integer(iTecla));
  iTecla := VK_F1;
  ProcesarTeclaCambioModoDocumento(
    iTecla, [], True, Modo,
    [mcsAuto, mcsSku, mcsTallasInline, mcsTallasHorPed],
    AccionConstruir);
  Assert.AreEqual(Integer(mcsTallasInline), Integer(Modo));
  iTecla := VK_F1;
  ProcesarTeclaCambioModoDocumento(
    iTecla, [], True, Modo,
    [mcsAuto, mcsSku, mcsTallasInline, mcsTallasHorPed],
    AccionConstruir);
  Assert.AreEqual(Integer(mcsTallasHorPed), Integer(Modo));
  iTecla := VK_F1;
  ProcesarTeclaCambioModoDocumento(
    iTecla, [], True, Modo,
    [mcsAuto, mcsSku, mcsTallasInline, mcsTallasHorPed],
    AccionConstruir);
  Assert.AreEqual(Integer(mcsAuto), Integer(Modo));
  Assert.AreEqual(4, FAccionesConstruir);
end;

procedure TPruebasColumnasDocumento.
  Teclado_IgnoraContextoTeclaOModificadores;
var
  iTecla: Word;
  Modo: TModoColumnasSku;
begin
  Modo := mcsAuto;
  iTecla := VK_F1;
  Assert.IsFalse(ProcesarTeclaCambioModoDocumento(
    iTecla, [], False, Modo, [mcsAuto, mcsSku],
    AccionConstruir));
  Assert.AreEqual(Integer(VK_F1), Integer(iTecla));
  iTecla := VK_F1;
  Assert.IsFalse(ProcesarTeclaCambioModoDocumento(
    iTecla, [ssCtrl], True, Modo, [mcsAuto, mcsSku],
    AccionConstruir));
  iTecla := VK_F2;
  Assert.IsFalse(ProcesarTeclaCambioModoDocumento(
    iTecla, [], True, Modo, [mcsAuto, mcsSku],
    AccionConstruir));
  Assert.AreEqual(Integer(mcsAuto), Integer(Modo));
  Assert.AreEqual(0, FAccionesConstruir);
end;

procedure TPruebasColumnasDocumento.
  CambioModo_ReconstruyeSoloCuandoCambia;
var
  Modo: TModoColumnasSku;
begin
  Modo := mcsAuto;
  Assert.IsFalse(CambiarModoEntradaDocumento(
    Modo, mcsAuto, AccionConstruir));
  Assert.IsTrue(CambiarModoEntradaDocumento(
    Modo, mcsSku, AccionConstruir));
  Assert.AreEqual(Integer(mcsSku), Integer(Modo));
  Assert.AreEqual(1, FAccionesConstruir);
end;

procedure TPruebasColumnasDocumento.
  PreferenciaPivote_PersisteValorValido;
var
  oDataSet: TClientDataSet;
begin
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('ESPIVOTE', ftString, 1);
    oDataSet.CreateDataSet;
    oDataSet.AppendRecord(['N']);
    PersistirPreferenciaPivoteDocumento(
      oDataSet, 'ESPIVOTE', True);
    Assert.AreEqual('S',
      oDataSet.FieldByName('ESPIVOTE').AsString);
    Assert.IsTrue(oDataSet.State = dsBrowse);
    PersistirPreferenciaPivoteDocumento(
      oDataSet, 'ESPIVOTE', False);
    Assert.AreEqual('N',
      oDataSet.FieldByName('ESPIVOTE').AsString);
  finally
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasColumnasDocumento.
  PreferenciaPivote_IgnoraDataSetNoDisponible;
var
  oDataSet: TClientDataSet;
begin
  PersistirPreferenciaPivoteDocumento(nil, 'ESPIVOTE', True);
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('OTRO_CAMPO', ftString, 1);
    PersistirPreferenciaPivoteDocumento(
      oDataSet, 'ESPIVOTE', True);
    oDataSet.CreateDataSet;
    oDataSet.AppendRecord(['N']);
    PersistirPreferenciaPivoteDocumento(
      oDataSet, 'ESPIVOTE', True);
    Assert.AreEqual('N',
      oDataSet.FieldByName('OTRO_CAMPO').AsString);
    Assert.IsTrue(oDataSet.State = dsBrowse);
  finally
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasColumnasDocumento.
  Foto_ResuelveArticuloSkuDeLaVista;
var
  oDataSet: TClientDataSet;
  oDataSource: TDataSource;
  sArticulo: string;
  sSku: string;
begin
  oDataSet := TClientDataSet.Create(nil);
  oDataSource := TDataSource.Create(nil);
  try
    ResolverArtSkuActivoDocumento(nil, sArticulo, sSku);
    Assert.AreEqual('', sArticulo);
    Assert.AreEqual('', sSku);
    oDataSet.FieldDefs.Add('CODIGO_ART_PEDLIN', ftString, 20);
    oDataSet.FieldDefs.Add('CODIGO_UNIDAD_PEDLIN', ftString, 40);
    oDataSet.CreateDataSet;
    oDataSet.AppendRecord(['ART-01', 'ART-01/ROJO/L']);
    oDataSource.DataSet := oDataSet;
    FVista.DataController.DataSource := oDataSource;
    ResolverArtSkuActivoDocumento(
      FVista, sArticulo, sSku);
    Assert.AreEqual('ART-01', sArticulo);
    Assert.AreEqual('ART-01/ROJO/L', sSku);
  finally
    FVista.DataController.DataSource := nil;
    FreeAndNil(oDataSource);
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasColumnasDocumento.
  Foto_SeleccionaCabeceraYDetalleDeLaVista;
var
  aDataSources: TArray<TDataSource>;
  oCabecera: TDataSource;
  oDetalle: TDataSource;
begin
  oCabecera := TDataSource.Create(nil);
  oDetalle := TDataSource.Create(nil);
  try
    aDataSources := DataSourcesParaFotoDocumento(
      oCabecera, FVista);
    Assert.AreEqual(1, Integer(Length(aDataSources)));
    Assert.IsTrue(aDataSources[0] = oCabecera);
    FVista.DataController.DataSource := oDetalle;
    aDataSources := DataSourcesParaFotoDocumento(
      oCabecera, FVista);
    Assert.AreEqual(2, Integer(Length(aDataSources)));
    Assert.IsTrue(aDataSources[0] = oCabecera);
    Assert.IsTrue(aDataSources[1] = oDetalle);
  finally
    FVista.DataController.DataSource := nil;
    FreeAndNil(oDetalle);
    FreeAndNil(oCabecera);
  end;
end;

procedure TPruebasColumnasDocumento.
  DataModule_ReutilizaOCreaInstancia;
var
  oActual: TObject;
  oPropietario: TComponent;
  oResultado: TdmBase;
begin
  oActual := nil;
  oPropietario := TComponent.Create(nil);
  try
    oResultado := AsegurarDataModuleDocumento(
      oPropietario, oActual, TdmDocumentoPrueba);
    Assert.IsTrue(oActual = oResultado);
    Assert.IsTrue(oResultado is TdmDocumentoPrueba);
    Assert.IsTrue(oResultado.Owner = oPropietario);
    Assert.AreEqual(1, oPropietario.ComponentCount);
    Assert.IsTrue(oResultado = AsegurarDataModuleDocumento(
      oPropietario, oActual, TdmDocumentoPrueba));
    Assert.AreEqual(1, oPropietario.ComponentCount);
  finally
    FreeAndNil(oPropietario);
  end;
end;

procedure TPruebasColumnasDocumento.
  DataModule_RechazaClaseIncompatible;
var
  bExcepcion: Boolean;
  oActual: TObject;
begin
  bExcepcion := False;
  oActual := TObject.Create;
  try
    try
      AsegurarDataModuleDocumento(
        nil, oActual, TdmDocumentoPrueba);
    except
      on EInvalidCast do
        bExcepcion := True;
    end;
    Assert.IsTrue(bExcepcion);
  finally
    FreeAndNil(oActual);
  end;
end;

procedure TPruebasColumnasDocumento.
  TablaPrincipal_CableaCabeceraLineasDetallesYClave;
var
  oCabecera: TDataSource;
  oDataModule: TdmDocumentoPrueba;
  oDetalle: TDataSource;
  oQueryUno: TUniQuery;
  oQueryDos: TUniQuery;
  sClave: string;
begin
  oCabecera := TDataSource.Create(nil);
  oDataModule := TdmDocumentoPrueba.Create(nil);
  oDetalle := TDataSource.Create(nil);
  oQueryUno := TUniQuery.Create(nil);
  oQueryDos := TUniQuery.Create(nil);
  try
    sClave := 'ANTERIOR';
    ConfigurarTablaPrincipalDocumento(
      oDataModule, oCabecera, FVista, oDetalle,
      [oQueryUno, oQueryDos], sClave, 'SERIE;NUMERO');
    Assert.IsTrue(oCabecera.DataSet = oDataModule.unqryTablaG);
    Assert.IsTrue(oDataModule.MaestroCabecera = oCabecera);
    Assert.IsTrue(FVista.DataController.DataSource = oDetalle);
    Assert.IsTrue(oQueryUno.MasterSource = oCabecera);
    Assert.IsTrue(oQueryDos.MasterSource = oCabecera);
    Assert.AreEqual('SERIE;NUMERO', sClave);
    ConfigurarTablaPrincipalDocumento(
      nil, nil, nil, nil, [], sClave, '');
    Assert.AreEqual('SERIE;NUMERO', sClave);
  finally
    FVista.DataController.DataSource := nil;
    oQueryDos.MasterSource := nil;
    oQueryUno.MasterSource := nil;
    oCabecera.DataSet := nil;
    FreeAndNil(oQueryDos);
    FreeAndNil(oQueryUno);
    FreeAndNil(oDetalle);
    FreeAndNil(oDataModule);
    FreeAndNil(oCabecera);
  end;
end;

procedure TPruebasColumnasDocumento.
  ConfigSku_DerivaCamposPorPrefijo;
var
  oConfig: TConfigColumnasSku;
begin
  oConfig := CrearConfigColumnasSkuDocumento(nil, nil, FVista, nil,
    mcsAuto, 'ALM01', 'ALBCLIN');
  Assert.IsTrue(oConfig.View = FVista);
  Assert.IsTrue(oConfig.Cds = nil);
  Assert.AreEqual(Integer(mcsAuto), Integer(oConfig.Modo));
  Assert.AreEqual('ALM01', oConfig.AlmacenStock);
  Assert.IsFalse(oConfig.Distribuido);
  Assert.IsFalse(oConfig.AceptarNoCatalogo);
  Assert.AreEqual('CODIGO_ART_ALBCLIN',
    oConfig.Campos.CodigoArt);
  Assert.AreEqual('CODIGO_UNIDAD_ALBCLIN',
    oConfig.Campos.CodigoUnidad);
  Assert.AreEqual('DESCRIPCION_ARTICULO_ALBCLIN',
    oConfig.Campos.Descripcion);
  Assert.AreEqual('CANTIDAD_ALBCLIN',
    oConfig.Campos.Cantidad);
  Assert.AreEqual('CODIGO_ALMACEN_ALBCLIN',
    oConfig.Campos.Almacen);
  Assert.AreEqual('NUM_ATRIBUTOS_ALBCLIN',
    oConfig.Campos.NumAtributos);
  Assert.AreEqual('ATTR1_VALOR_ALBCLIN',
    oConfig.Campos.AttrValor[1]);
  Assert.AreEqual('ATTR5_NOMBRE_ALBCLIN',
    oConfig.Campos.AttrNombre[5]);
end;

procedure TPruebasColumnasDocumento.
  ColumnaHost_AplicaPropiedades;
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := CrearColumnaHostDocumento(
    FVista, 'Importe', 'TOTAL_PRUEBA', 95, False);
  Assert.AreEqual(1, FVista.ColumnCount);
  Assert.AreEqual('Importe', oColumna.Caption);
  Assert.AreEqual('TOTAL_PRUEBA',
    oColumna.DataBinding.FieldName);
  Assert.AreEqual(95, oColumna.Width);
  Assert.IsFalse(oColumna.Options.Editing);
  Assert.IsFalse(Assigned(CrearColumnaHostDocumento(
    nil, '', '', 0, False)));
end;

procedure TPruebasColumnasDocumento.
  ColumnasHostCompra_DerivaCamposPorPrefijo;
var
  oColumnaModo: TcxGridDBColumn;
  oColumnas: TColumnasHostDocumentoCompra;
begin
  oColumnaModo := FVista.CreateColumn;
  oColumnaModo.Caption := 'Artículo';
  oColumnas := CrearColumnasHostDocumentoCompra(
    FVista, mcsSku, 'DEVCLIN');
  Assert.AreEqual(10, FVista.ColumnCount);
  Assert.AreEqual(0, oColumnas.ColLinea.Index);
  Assert.AreEqual(1, oColumnaModo.Index);
  Assert.AreEqual('LINEA_DEVCLIN',
    oColumnas.ColLinea.DataBinding.FieldName);
  Assert.AreEqual('CANTIDAD_DEVCLIN',
    oColumnas.ColCantidad.DataBinding.FieldName);
  Assert.IsTrue(oColumnas.ColCantidad.Options.Editing);
  Assert.AreEqual('TIPO_CANTIDAD_ARTICULO_DEVCLIN',
    oColumnas.ColTipoCantidad.DataBinding.FieldName);
  Assert.IsFalse(oColumnas.ColTipoCantidad.Options.Editing);
  Assert.AreEqual('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
    oColumnas.ColPrecioCompra.DataBinding.FieldName);
  Assert.AreEqual('Total', FVista.Columns[8].Caption);
  Assert.AreEqual('CODIGO_ALMACEN_DEVCLIN',
    FVista.Columns[9].DataBinding.FieldName);
end;

procedure TPruebasColumnasDocumento.
  ColumnasHostCompra_BandasOmiteCantidad;
var
  oColumnas: TColumnasHostDocumentoCompra;
begin
  oColumnas := CrearColumnasHostDocumentoCompra(
    FVista, mcsTallasHorPed, 'FACC');
  Assert.AreEqual(7, FVista.ColumnCount);
  Assert.IsFalse(Assigned(oColumnas.ColCantidad));
  Assert.IsFalse(Assigned(oColumnas.ColTipoCantidad));
  Assert.AreEqual('Total uds.', FVista.Columns[5].Caption);
  Assert.AreEqual('TOTAL_FACC',
    FVista.Columns[5].DataBinding.FieldName);
end;

procedure TPruebasColumnasDocumento.
  ConfigBandas_DerivaCamposBase;
var
  oConfig: TGridPivoteVentaConfig;
begin
  oConfig := CrearConfigPivoteBandasDocumentoCompra(
    nil, 'PRUEBAS', nil, nil, 'PEDC', 'PEDCLIN',
    'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN', 20);
  Assert.AreEqual('PRUEBAS', oConfig.Usuario);
  Assert.AreEqual('SERIE_PEDC', oConfig.FieldSerieMaster);
  Assert.AreEqual('NUMERO_PEDC', oConfig.FieldNumeroMaster);
  Assert.AreEqual('LINEA_PEDCLIN', oConfig.FieldLinea);
  Assert.AreEqual('CODIGO_ART_PEDCLIN', oConfig.FieldArt);
  Assert.AreEqual('CODIGO_UNIDAD_PEDCLIN', oConfig.FieldSku);
  Assert.AreEqual('DESCRIPCION_ARTICULO_PEDCLIN',
    oConfig.FieldDescripcion);
  Assert.AreEqual('TIPO_CANTIDAD_ARTICULO_PEDCLIN',
    oConfig.FieldTipoCantidad);
  Assert.AreEqual('CANTIDAD_PEDCLIN',
    oConfig.FieldCantidadPedida);
  Assert.AreEqual('PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN',
    oConfig.FieldPrecioBase);
  Assert.AreEqual('CODIGO_ALMACEN_PEDCLIN',
    oConfig.FieldAlmacen);
  Assert.AreEqual('CODIGO_ALM_PEDC',
    oConfig.FieldAlmacenMaster);
  Assert.AreEqual(20, oConfig.MaxColumnas);
  Assert.AreEqual('', oConfig.FieldCantidadEntregada);
  Assert.AreEqual('', oConfig.FieldCantidadAAlbaranar);
  Assert.AreEqual('', oConfig.FieldTotalUdsGrupo);
  Assert.IsFalse(oConfig.BandaUnica);
  Assert.IsFalse(Assigned(oConfig.OnCrearLineaSku));
  Assert.IsFalse(Assigned(oConfig.OnBandaCambiada));
end;

procedure TPruebasColumnasDocumento.
  ConfigTallas_DerivaCamposPorPrefijo;
var
  aColumnas: TArray<TcxGridDBColumn>;
  oBase: TConfigPivoteDocumentoCompra;
  oConfig: TGridTallasConfig;
begin
  SetLength(aColumnas, 2);
  CrearColumnasTallasDocumento(FVista, 'dbcPruebaTalla', 50,
    aColumnas);
  oBase := Default(TConfigPivoteDocumentoCompra);
  oBase.ColumnasTallas := CopiarColumnasDocumento(aColumnas);
  oBase.PrefijoCabecera := 'FACC';
  oBase.PrefijoLinea := 'FACCLIN';
  oBase.PrefijoCelda := 'FACCCEL';
  oBase.NombreTablaDocumento := 'facturas';
  oConfig := CrearConfigTallasDocumentoCompra(oBase);
  Assert.AreEqual('SERIE_FACC', oConfig.FieldSerieMaster);
  Assert.AreEqual('NUMERO_FACC', oConfig.FieldNumeroMaster);
  Assert.AreEqual('LINEA_FACCLIN', oConfig.FieldLinea);
  Assert.AreEqual('ID_AC_PIVOT_FACCLIN',
    oConfig.FieldConjuntoPivot);
  Assert.AreEqual('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN',
    oConfig.FieldPrecioBase);
  Assert.AreEqual('fza_facturas_compra_celdas',
    oConfig.TablaCeldas);
  Assert.AreEqual('LINEA_FACC_FACCCEL', oConfig.FieldLineaCel);
  Assert.AreEqual('ID_FILA_FACC_FACCCEL', oConfig.FieldFilaCel);
  Assert.AreEqual('ID_AV_PIVOT_FACCCEL',
    oConfig.FieldAvPivotCel);
  Assert.AreEqual(2, oConfig.MaxColumnas);
  Assert.IsTrue(oConfig.ColumnasTallas[0] = aColumnas[0]);
end;

procedure TPruebasColumnasDocumento.
  ConfigPivote_DerivaCamposBasicos;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfig: TGridPivoteCompraConfig;
begin
  oBase := Default(TConfigPivoteDocumentoCompra);
  SetLength(oBase.ColumnasTallas, 3);
  oBase.PrefijoCabecera := 'DEVC';
  oBase.PrefijoLinea := 'DEVCLIN';
  oBase.PrefijoCelda := 'DEVCCEL';
  oBase.NombreTablaDocumento := 'devoluciones';
  oConfig := CrearConfigPivoteDocumentoCompra(oBase, nil);
  Assert.AreEqual('fza_devoluciones_compra_lineas',
    oConfig.TablaLineas);
  Assert.AreEqual('SERIE_DEVC_DEVCLIN', oConfig.FieldSerieLin);
  Assert.AreEqual('CODIGO_ART_DEVCLIN', oConfig.FieldArt);
  Assert.AreEqual('CODIGO_UNIDAD_DEVCLIN', oConfig.FieldSku);
  Assert.AreEqual('TOTAL_UNIDADES_DEVCLIN',
    oConfig.FieldTotalUds);
  Assert.AreEqual('', oConfig.FieldCantidadRecibida);
  Assert.AreEqual(3,
    Integer(Length(oConfig.CamposOcultosEnPivote)));
  Assert.AreEqual('TOTAL_DEVCLIN',
    oConfig.CamposOcultosEnPivote[2]);
end;

procedure TPruebasColumnasDocumento.
  ConfigPivote_PedidoIncluyeRecepcionYColor;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfig: TGridPivoteCompraConfig;
begin
  oBase := Default(TConfigPivoteDocumentoCompra);
  SetLength(oBase.ColumnasTallas, 20);
  oBase.PrefijoCabecera := 'PEDC';
  oBase.PrefijoLinea := 'PEDCLIN';
  oBase.PrefijoCelda := 'PEDCCEL';
  oBase.NombreTablaDocumento := 'pedidos';
  oBase.TieneCantidadRecibida := True;
  oBase.CampoColorTexto := 'COLOR_TEXTO_PEDCLIN';
  oConfig := CrearConfigPivoteDocumentoCompra(oBase, nil);
  Assert.AreEqual('CANTIDAD_RECIBIDA_PEDCLIN',
    oConfig.FieldCantidadRecibida);
  Assert.AreEqual('COLOR_TEXTO_PEDCLIN',
    oConfig.FieldColorTexto);
  Assert.AreEqual(20, oConfig.MaxColumnasTallas);
  Assert.AreEqual(4,
    Integer(Length(oConfig.CamposOcultosEnPivote)));
  Assert.AreEqual('CANTIDAD_RECIBIDA_PEDCLIN',
    oConfig.CamposOcultosEnPivote[2]);
  Assert.AreEqual('TOTAL_PEDCLIN',
    oConfig.CamposOcultosEnPivote[3]);
end;

procedure TPruebasColumnasDocumento.
  EventosTallas_SeAsignanAColumnasNumericas;
var
  aColumnas: TArray<TcxGridDBColumn>;
  oPropiedades: TcxCurrencyEditProperties;
begin
  SetLength(aColumnas, 2);
  CrearColumnasTallasDocumento(FVista, 'dbcPruebaTalla', 50,
    aColumnas);
  ConfigurarEventosTallasDocumento(aColumnas, CambiarValorTalla,
    ValidarTalla);
  oPropiedades :=
    TcxCurrencyEditProperties(aColumnas[0].Properties);
  Assert.IsTrue(Assigned(oPropiedades.OnEditValueChanged));
  Assert.IsTrue(Assigned(oPropiedades.OnValidate));
end;

end.
