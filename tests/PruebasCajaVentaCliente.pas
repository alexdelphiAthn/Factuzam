{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasCajaVentaCliente                                       }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fija el comportamiento de las reglas del cambio de cliente en la          }
{    venta de caja, extraidas de                                               }
{    TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate. Sin VCL y sin          }
{    BBDD: cabecera y lineas se prueban con un TClientDataSet.                 }
{******************************************************************************}
unit PruebasCajaVentaCliente;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCajaVentaCliente = class
  public
    // --- regla de linea de deposito ---
    [Test]
    procedure Deposito_SoloSYASonDeDeposito;

    // --- limpieza de lineas ---
    [Test]
    procedure Limpiar_BorraLasLineasDeDepositoYConservaElResto;
    [Test]
    procedure Limpiar_CancelaLaInsercionVacia;
    [Test]
    procedure Limpiar_GrabaLaInsercionConArticulo;
    [Test]
    procedure Limpiar_GrabaLaEdicionPendiente;
    [Test]
    procedure Limpiar_DataSetNilOInactivoNoHaceNada;

    // --- cabecera de venta al contado ---
    [Test]
    procedure Contado_VaciaLosDatosDelCliente;
    [Test]
    procedure Contado_PoneTarifaDefaultEImpuestosIncluidos;

    // --- volcado del cliente ---
    [Test]
    procedure Cliente_VuelcaLosDatosCompletos;
    [Test]
    procedure Cliente_FormaPagoVaciaNoPisaLaExistente;
    [Test]
    procedure Cliente_FormaPagoInformadaSiPisa;

    // --- autocarga de depositos ---
    [Test]
    procedure Depositos_SoloConPermiteDeudaYAutocarga;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibCajaVentaIntf,
  inLibCajaVentaCliente;

function CrearLineas: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('CODIGO_ART_FACLIN', ftString, 20);
  Result.FieldDefs.Add('VIENE_DE_DEPOSITO', ftString, 1);
  Result.CreateDataSet;
end;

procedure AgregarLinea(ALineas: TClientDataSet;
  const AArticulo, AVieneDeDeposito: string);
begin
  ALineas.Append;
  ALineas.FieldByName('CODIGO_ART_FACLIN').AsString := AArticulo;
  ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString :=
    AVieneDeDeposito;
  ALineas.Post;
end;

function CrearCabecera: TClientDataSet;
const
  cCampos: array [0..16] of string = (
    'CODIGO_CLI_FAC', 'RAZON_SOCIAL_CLIENTE_FAC', 'NIF_CLIENTE_FAC',
    'MOVIL_CLIENTE_FAC', 'EMAIL_CLIENTE_FAC', 'DIRECCION1_CLIENTE_FAC',
    'DIRECCION2_CLIENTE_FAC', 'POBLACION_CLIENTE_FAC',
    'PROVINCIA_CLIENTE_FAC', 'CODIGO_POSTAL_CLIENTE_FAC',
    'CODIGO_PAI_CLIENTE_FAC', 'NOMBRE_PAI_CLIENTE_FAC',
    'CODIGO_OFICINA_CONTABLE_FAC', 'CODIGO_ORGANO_GESTOR_FAC',
    'CODIGO_UNIDAD_TRAMITADORA_FAC', 'TARIFA_ARTICULO_CLIENTE_FAC',
    'ESIMP_INCL_TARIFA_CLIENTE_FAC');
var
  i: Integer;
begin
  Result := TClientDataSet.Create(nil);
  for i := Low(cCampos) to High(cCampos) do
    Result.FieldDefs.Add(cCampos[i], ftString, 60);
  Result.FieldDefs.Add('ESIVA_RECARGO_CLIENTE_FAC', ftString, 1);
  Result.FieldDefs.Add('ESIVA_EXENTO_CLIENTE_FAC', ftString, 1);
  Result.FieldDefs.Add(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC', ftString, 1);
  Result.FieldDefs.Add('ESRETENCIONES_CLIENTE_FAC', ftString, 1);
  Result.FieldDefs.Add('ESINTRACOMUNITARIO_CLIENTE_FAC', ftString, 1);
  Result.FieldDefs.Add('FORMA_PAGO_FAC', ftString, 10);
  Result.CreateDataSet;
  Result.Append;
  Result.Post;
end;

function ClienteCompleto: TClienteCaja;
begin
  Result := Default(TClienteCaja);
  Result.Codigo := 'C1';
  Result.RazonSocial := 'CLIENTE UNO SL';
  Result.Nif := '12345678Z';
  Result.Movil := '600000001';
  Result.Email := 'uno@cliente.es';
  Result.Direccion1 := 'CALLE 1';
  Result.Direccion2 := 'PISO 2';
  Result.Poblacion := 'MADRID';
  Result.Provincia := 'MADRID';
  Result.CodigoPostal := '28001';
  Result.CodigoPais := 'ES';
  Result.NombrePais := 'ESPAÑA';
  Result.CodigoOficinaContable := 'OC1';
  Result.CodigoOrganoGestor := 'OG1';
  Result.CodigoUnidadTramitadora := 'UT1';
  Result.EsIvaRecargo := 'N';
  Result.EsIvaExento := 'N';
  Result.EsRegimenEspecialAgricola := 'N';
  Result.EsRetenciones := 'S';
  Result.EsIntracomunitario := 'N';
  Result.CodigoFormaPago := 'FP1';
  Result.TarifaArticulo := 'T2';
  Result.EsPermiteDeuda := 'S';
end;

{ --- regla de linea de deposito --- }

procedure TPruebasCajaVentaCliente.Deposito_SoloSYASonDeDeposito;
begin
  Assert.IsTrue(EsLineaDeposito('S'));
  Assert.IsTrue(EsLineaDeposito('A'));
  Assert.IsFalse(EsLineaDeposito('N'));
  Assert.IsFalse(EsLineaDeposito(''));
  Assert.IsFalse(EsLineaDeposito('s'));
end;

{ --- limpieza de lineas --- }

procedure TPruebasCajaVentaCliente.
  Limpiar_BorraLasLineasDeDepositoYConservaElResto;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N');
    AgregarLinea(cds, 'ART2', 'S');
    AgregarLinea(cds, 'ART3', 'A');
    AgregarLinea(cds, 'ART4', '');
    LimpiarLineasDeposito(cds);
    Assert.AreEqual(2, cds.RecordCount);
    cds.First;
    Assert.AreEqual('ART1',
      cds.FieldByName('CODIGO_ART_FACLIN').AsString);
    cds.Next;
    Assert.AreEqual('ART4',
      cds.FieldByName('CODIGO_ART_FACLIN').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.Limpiar_CancelaLaInsercionVacia;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N');
    cds.Append;
    LimpiarLineasDeposito(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.Limpiar_GrabaLaInsercionConArticulo;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    cds.Append;
    cds.FieldByName('CODIGO_ART_FACLIN').AsString := 'ART9';
    cds.FieldByName('VIENE_DE_DEPOSITO').AsString := 'N';
    LimpiarLineasDeposito(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual(1, cds.RecordCount);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.Limpiar_GrabaLaEdicionPendiente;
var
  cds: TClientDataSet;
begin
  cds := CrearLineas;
  try
    AgregarLinea(cds, 'ART1', 'N');
    cds.Edit;
    cds.FieldByName('CODIGO_ART_FACLIN').AsString := 'ART1BIS';
    LimpiarLineasDeposito(cds);
    Assert.IsTrue(cds.State = dsBrowse);
    Assert.AreEqual('ART1BIS',
      cds.FieldByName('CODIGO_ART_FACLIN').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.
  Limpiar_DataSetNilOInactivoNoHaceNada;
var
  cds: TClientDataSet;
begin
  LimpiarLineasDeposito(nil);
  cds := TClientDataSet.Create(nil);
  try
    LimpiarLineasDeposito(cds);
    Assert.IsFalse(cds.Active);
  finally
    FreeAndNil(cds);
  end;
end;

{ --- cabecera de venta al contado --- }

procedure TPruebasCajaVentaCliente.Contado_VaciaLosDatosDelCliente;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    EscribirCabeceraClienteVenta(cds, ClienteCompleto);
    cds.Post;
    EscribirCabeceraVentaContado(cds, 'T1');
    cds.Post;
    Assert.AreEqual('', cds.FieldByName('CODIGO_CLI_FAC').AsString);
    Assert.AreEqual('',
      cds.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
    Assert.AreEqual('', cds.FieldByName('NIF_CLIENTE_FAC').AsString);
    Assert.AreEqual('',
      cds.FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.
  Contado_PoneTarifaDefaultEImpuestosIncluidos;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    EscribirCabeceraVentaContado(cds, 'T1');
    cds.Post;
    Assert.AreEqual('T1',
      cds.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString);
    Assert.AreEqual('S',
      cds.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

{ --- volcado del cliente --- }

procedure TPruebasCajaVentaCliente.Cliente_VuelcaLosDatosCompletos;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    EscribirCabeceraClienteVenta(cds, ClienteCompleto);
    cds.Post;
    Assert.AreEqual('C1', cds.FieldByName('CODIGO_CLI_FAC').AsString);
    Assert.AreEqual('CLIENTE UNO SL',
      cds.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
    Assert.AreEqual('12345678Z',
      cds.FieldByName('NIF_CLIENTE_FAC').AsString);
    Assert.AreEqual('ES',
      cds.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString);
    Assert.AreEqual('OC1',
      cds.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString);
    Assert.AreEqual('S',
      cds.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString);
    Assert.AreEqual('FP1',
      cds.FieldByName('FORMA_PAGO_FAC').AsString);
    Assert.AreEqual('T2',
      cds.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.
  Cliente_FormaPagoVaciaNoPisaLaExistente;
var
  cds: TClientDataSet;
  Cliente: TClienteCaja;
begin
  cds := CrearCabecera;
  try
    cds.Edit;
    cds.FieldByName('FORMA_PAGO_FAC').AsString := 'FP0';
    cds.Post;
    Cliente := ClienteCompleto;
    Cliente.CodigoFormaPago := '   ';
    EscribirCabeceraClienteVenta(cds, Cliente);
    cds.Post;
    Assert.AreEqual('FP0',
      cds.FieldByName('FORMA_PAGO_FAC').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasCajaVentaCliente.Cliente_FormaPagoInformadaSiPisa;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    cds.Edit;
    cds.FieldByName('FORMA_PAGO_FAC').AsString := 'FP0';
    cds.Post;
    EscribirCabeceraClienteVenta(cds, ClienteCompleto);
    cds.Post;
    Assert.AreEqual('FP1',
      cds.FieldByName('FORMA_PAGO_FAC').AsString);
  finally
    FreeAndNil(cds);
  end;
end;

{ --- autocarga de depositos --- }

procedure TPruebasCajaVentaCliente.
  Depositos_SoloConPermiteDeudaYAutocarga;
begin
  Assert.IsTrue(DebeCargarDepositosCliente('S', True));
  Assert.IsTrue(DebeCargarDepositosCliente('s', True));
  Assert.IsFalse(DebeCargarDepositosCliente('S', False));
  Assert.IsFalse(DebeCargarDepositosCliente('N', True));
  Assert.IsFalse(DebeCargarDepositosCliente('', True));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCajaVentaCliente);

end.
