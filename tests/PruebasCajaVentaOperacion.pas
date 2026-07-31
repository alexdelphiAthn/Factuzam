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

    // --- documento del cierre ---
    [Test]
    procedure Cierre_FacturaCompletaUsaSerieTipoYFecha;
    [Test]
    procedure Cierre_SimplificadaPorDefecto;
    [Test]
    procedure Cierre_RectificativaSiNoAcabaEnFactura;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibCajaVentaOperacion;

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

function Valor(AOrden: Integer; const AValor: string):
  TArticuloAtributoValor;
begin
  Result := Default(TArticuloAtributoValor);
  Result.Orden := AOrden;
  Result.Valor := AValor;
end;

function CrearLineas: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('CODIGO_ART_FACLIN', ftString, 20);
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

initialization
  TDUnitX.RegisterTestFixture(TPruebasCajaVentaOperacion);

end.
