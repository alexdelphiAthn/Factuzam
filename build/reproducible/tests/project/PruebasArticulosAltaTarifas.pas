{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasArticulosAltaTarifas                                   }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fija el comportamiento de las reglas del alta masiva de precios de        }
{    tarifa por SKU extraidas de TfrmMtoArticulos.btnAddSKUClick. Sin VCL      }
{    y sin BBDD: la traduccion del dataset se prueba con un                    }
{    TClientDataSet en memoria.                                                }
{******************************************************************************}
unit PruebasArticulosAltaTarifas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosAltaTarifas = class
  public
    // --- solapamiento de vigencias ---
    [Test]
    procedure Solapan_CerradasQueSeCruzan;
    [Test]
    procedure Solapan_ExistenteTerminaAntesDeEmpezarLaNueva;
    [Test]
    procedure Solapan_ContiguasEnElMismoDia;
    [Test]
    procedure Solapan_NuevaSinHastaAlcanzaCualquierFuturo;
    [Test]
    procedure Solapan_NuevaSinHastaNoAlcanzaElPasado;
    [Test]
    procedure Solapan_ExistenteSinHastaSegunElArranque;
    [Test]
    procedure Solapan_AmbasSinHastaSiempre;

    // --- llave de ocupacion ---
    [Test]
    procedure Llave_FilaDeArticuloUsaSkuVacio;
    [Test]
    procedure Llave_SkuYTarifaSeparadosPorBarra;

    // --- expansion de combinaciones ---
    [Test]
    procedure Combinaciones_SinExistentesGeneraTodasEnOrden;
    [Test]
    procedure Combinaciones_ExistenteSolapadaBloquea;
    [Test]
    procedure Combinaciones_ExistenteSinSolaparNoBloquea;
    [Test]
    procedure Combinaciones_DuplicadosDeLaSeleccionSoloUnaVez;
    [Test]
    procedure Combinaciones_FilaDeArticuloExistenteBloqueaAlArticulo;

    // --- composicion de la fila nueva ---
    [Test]
    procedure Fila_DeArticuloNaceACeroEInactiva;
    [Test]
    procedure Fila_DeSkuHeredaElPrecioDelPadreYSeActiva;
    [Test]
    procedure Fila_DeSkuSinPrecioDelPadreQuedaInactiva;
    [Test]
    procedure Fila_ConservaLaVigenciaElegida;

    // --- traduccion desde el dataset ---
    [Test]
    procedure Dataset_NilODesactivadoDevuelveVacio;
    [Test]
    procedure Dataset_LeeFilasConYSinFechaHasta;
    [Test]
    procedure Dataset_EscribeFilaDeSkuCompleta;
    [Test]
    procedure Dataset_EscribeFilaDeArticuloYDejaHastaNula;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibArticulosAltaTarifas;

function Vigencia(const ADesde: TDate; ATieneHasta: Boolean;
  const AHasta: TDate): TVigenciaTarifa;
begin
  Result.Desde := ADesde;
  Result.TieneHasta := ATieneHasta;
  Result.Hasta := AHasta;
end;

function Existente(const ASku, ATarifa: string;
  const AVigencia: TVigenciaTarifa): TFilaTarifaExistente;
begin
  Result.Sku := ASku;
  Result.Tarifa := ATarifa;
  Result.Vigencia := AVigencia;
end;

function CrearTarifas: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('CODIGO_UNIDAD_ARTTAR', ftString, 20);
  Result.FieldDefs.Add('CODIGO_TAR_ARTTAR', ftString, 10);
  Result.FieldDefs.Add('PRECIO_SALIDA_ARTTAR', ftFloat);
  Result.FieldDefs.Add('PRECIO_FINAL_ARTTAR', ftFloat);
  Result.FieldDefs.Add('ESACTIVO_ARTTAR', ftString, 1);
  Result.FieldDefs.Add('FECHA_DESDE_ARTTAR', ftDate);
  Result.FieldDefs.Add('FECHA_HASTA_ARTTAR', ftDate);
  Result.CreateDataSet;
end;

{ --- solapamiento de vigencias --- }

procedure TPruebasArticulosAltaTarifas.Solapan_CerradasQueSeCruzan;
begin
  Assert.IsTrue(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 1, 10), True, EncodeDate(2026, 1, 20)),
    Vigencia(EncodeDate(2026, 1, 15), True, EncodeDate(2026, 1, 25))));
end;

procedure TPruebasArticulosAltaTarifas.
  Solapan_ExistenteTerminaAntesDeEmpezarLaNueva;
begin
  Assert.IsFalse(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 2, 1), True, EncodeDate(2026, 2, 28)),
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 31))));
end;

procedure TPruebasArticulosAltaTarifas.Solapan_ContiguasEnElMismoDia;
begin
  // El limite es inclusivo por ambos lados: coincidir un dia ya solapa.
  Assert.IsTrue(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 1, 31), True, EncodeDate(2026, 2, 28)),
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 31))));
end;

procedure TPruebasArticulosAltaTarifas.
  Solapan_NuevaSinHastaAlcanzaCualquierFuturo;
begin
  Assert.IsTrue(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 1, 1), False, 0),
    Vigencia(EncodeDate(2030, 6, 1), True, EncodeDate(2030, 6, 30))));
end;

procedure TPruebasArticulosAltaTarifas.
  Solapan_NuevaSinHastaNoAlcanzaElPasado;
begin
  // La existente termino antes de que arranque la nueva.
  Assert.IsFalse(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 3, 1), False, 0),
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 2, 28))));
end;

procedure TPruebasArticulosAltaTarifas.
  Solapan_ExistenteSinHastaSegunElArranque;
begin
  // Abierta desde antes del fin de la nueva: solapa.
  Assert.IsTrue(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 31)),
    Vigencia(EncodeDate(2026, 1, 20), False, 0)));
  // Abierta pero que arranca despues del fin de la nueva: no solapa.
  Assert.IsFalse(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 31)),
    Vigencia(EncodeDate(2026, 2, 1), False, 0)));
end;

procedure TPruebasArticulosAltaTarifas.Solapan_AmbasSinHastaSiempre;
begin
  Assert.IsTrue(VigenciasSeSolapan(
    Vigencia(EncodeDate(2026, 1, 1), False, 0),
    Vigencia(EncodeDate(2030, 1, 1), False, 0)));
end;

{ --- llave de ocupacion --- }

procedure TPruebasArticulosAltaTarifas.Llave_FilaDeArticuloUsaSkuVacio;
begin
  Assert.AreEqual('|T1', LlaveOcupacionTarifa('', 'T1'));
end;

procedure TPruebasArticulosAltaTarifas.
  Llave_SkuYTarifaSeparadosPorBarra;
begin
  Assert.AreEqual('S1|T1', LlaveOcupacionTarifa('S1', 'T1'));
end;

{ --- expansion de combinaciones --- }

procedure TPruebasArticulosAltaTarifas.
  Combinaciones_SinExistentesGeneraTodasEnOrden;
var
  C: TCombinacionesAltaTarifa;
begin
  C := CalcularCombinacionesAltaTarifas(
    [cSkuFilaArticulo, 'S1'], ['T1', 'T2'], nil,
    Vigencia(EncodeDate(2026, 1, 1), False, 0));
  Assert.AreEqual(4, Integer(Length(C)));
  Assert.IsTrue(C[0].EsFilaArticulo);
  Assert.AreEqual('', C[0].Sku);
  Assert.AreEqual('T1', C[0].Tarifa);
  Assert.IsTrue(C[1].EsFilaArticulo);
  Assert.AreEqual('T2', C[1].Tarifa);
  Assert.IsFalse(C[2].EsFilaArticulo);
  Assert.AreEqual('S1', C[2].Sku);
  Assert.AreEqual('T1', C[2].Tarifa);
  Assert.AreEqual('S1', C[3].Sku);
  Assert.AreEqual('T2', C[3].Tarifa);
end;

procedure TPruebasArticulosAltaTarifas.
  Combinaciones_ExistenteSolapadaBloquea;
var
  C: TCombinacionesAltaTarifa;
begin
  C := CalcularCombinacionesAltaTarifas(
    ['S1'], ['T1', 'T2'],
    [Existente('S1', 'T1',
       Vigencia(EncodeDate(2026, 1, 15), True, EncodeDate(2026, 1, 31)))],
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 20)));
  Assert.AreEqual(1, Integer(Length(C)));
  Assert.AreEqual('T2', C[0].Tarifa);
end;

procedure TPruebasArticulosAltaTarifas.
  Combinaciones_ExistenteSinSolaparNoBloquea;
var
  C: TCombinacionesAltaTarifa;
begin
  C := CalcularCombinacionesAltaTarifas(
    ['S1'], ['T1'],
    [Existente('S1', 'T1',
       Vigencia(EncodeDate(2025, 1, 1), True, EncodeDate(2025, 12, 31)))],
    Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 31)));
  Assert.AreEqual(1, Integer(Length(C)));
end;

procedure TPruebasArticulosAltaTarifas.
  Combinaciones_DuplicadosDeLaSeleccionSoloUnaVez;
var
  C: TCombinacionesAltaTarifa;
begin
  C := CalcularCombinacionesAltaTarifas(
    ['S1', 'S1'], ['T1'], nil,
    Vigencia(EncodeDate(2026, 1, 1), False, 0));
  Assert.AreEqual(1, Integer(Length(C)));
end;

procedure TPruebasArticulosAltaTarifas.
  Combinaciones_FilaDeArticuloExistenteBloqueaAlArticulo;
var
  C: TCombinacionesAltaTarifa;
begin
  // La fila del articulo vive con CODIGO_UNIDAD_ARTTAR vacio.
  C := CalcularCombinacionesAltaTarifas(
    [cSkuFilaArticulo], ['T1'],
    [Existente('', 'T1',
       Vigencia(EncodeDate(2026, 1, 1), False, 0))],
    Vigencia(EncodeDate(2026, 6, 1), True, EncodeDate(2026, 6, 30)));
  Assert.AreEqual(0, Integer(Length(C)));
end;

{ --- composicion de la fila nueva --- }

procedure TPruebasArticulosAltaTarifas.Fila_DeArticuloNaceACeroEInactiva;
var
  Comb: TCombinacionAltaTarifa;
  F: TFilaNuevaTarifa;
begin
  Comb.Sku := '';
  Comb.EsFilaArticulo := True;
  Comb.Tarifa := 'T1';
  // El precio del padre se ignora en la fila del propio articulo.
  F := ComponerFilaNuevaTarifa(Comb, 99.9,
         Vigencia(EncodeDate(2026, 1, 1), False, 0));
  Assert.AreEqual(Double(0), F.PrecioSalida, 0.0001);
  Assert.AreEqual(Double(0), F.PrecioFinal, 0.0001);
  Assert.IsFalse(F.EsActiva);
  Assert.AreEqual('', F.Sku);
  Assert.AreEqual('T1', F.Tarifa);
end;

procedure TPruebasArticulosAltaTarifas.
  Fila_DeSkuHeredaElPrecioDelPadreYSeActiva;
var
  Comb: TCombinacionAltaTarifa;
  F: TFilaNuevaTarifa;
begin
  Comb.Sku := 'S1';
  Comb.EsFilaArticulo := False;
  Comb.Tarifa := 'T1';
  F := ComponerFilaNuevaTarifa(Comb, 12.5,
         Vigencia(EncodeDate(2026, 1, 1), False, 0));
  Assert.AreEqual(Double(12.5), F.PrecioSalida, 0.0001);
  Assert.AreEqual(Double(12.5), F.PrecioFinal, 0.0001);
  Assert.IsTrue(F.EsActiva);
end;

procedure TPruebasArticulosAltaTarifas.
  Fila_DeSkuSinPrecioDelPadreQuedaInactiva;
var
  Comb: TCombinacionAltaTarifa;
begin
  Comb.Sku := 'S1';
  Comb.EsFilaArticulo := False;
  Comb.Tarifa := 'T1';
  Assert.IsFalse(ComponerFilaNuevaTarifa(Comb, 0,
    Vigencia(EncodeDate(2026, 1, 1), False, 0)).EsActiva);
end;

procedure TPruebasArticulosAltaTarifas.Fila_ConservaLaVigenciaElegida;
var
  Comb: TCombinacionAltaTarifa;
  F: TFilaNuevaTarifa;
begin
  Comb.Sku := 'S1';
  Comb.EsFilaArticulo := False;
  Comb.Tarifa := 'T1';
  F := ComponerFilaNuevaTarifa(Comb, 5,
         Vigencia(EncodeDate(2026, 3, 1), True, EncodeDate(2026, 3, 31)));
  Assert.IsTrue(F.Vigencia.Desde = EncodeDate(2026, 3, 1));
  Assert.IsTrue(F.Vigencia.TieneHasta);
  Assert.IsTrue(F.Vigencia.Hasta = EncodeDate(2026, 3, 31));
end;

{ --- traduccion desde el dataset --- }

procedure TPruebasArticulosAltaTarifas.Dataset_NilODesactivadoDevuelveVacio;
begin
  Assert.AreEqual(0, Integer(Length(LeerFilasTarifaExistentes(nil))));
end;

procedure TPruebasArticulosAltaTarifas.Dataset_LeeFilasConYSinFechaHasta;
var
  cds: TClientDataSet;
  Filas: TFilasTarifaExistentes;
begin
  cds := CrearTarifas;
  try
    cds.Append;
    cds.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := 'S1';
    cds.FieldByName('CODIGO_TAR_ARTTAR').AsString := 'T1';
    cds.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime :=
      EncodeDate(2026, 1, 1);
    cds.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime :=
      EncodeDate(2026, 1, 31);
    cds.Post;
    cds.Append;
    cds.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := '';
    cds.FieldByName('CODIGO_TAR_ARTTAR').AsString := 'T2';
    cds.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime :=
      EncodeDate(2026, 2, 1);
    cds.Post;
    Filas := LeerFilasTarifaExistentes(cds);
    Assert.AreEqual(2, Integer(Length(Filas)));
    Assert.AreEqual('S1', Filas[0].Sku);
    Assert.AreEqual('T1', Filas[0].Tarifa);
    Assert.IsTrue(Filas[0].Vigencia.TieneHasta);
    Assert.IsTrue(Filas[0].Vigencia.Hasta = EncodeDate(2026, 1, 31));
    Assert.AreEqual('', Filas[1].Sku);
    Assert.IsFalse(Filas[1].Vigencia.TieneHasta);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasArticulosAltaTarifas.Dataset_EscribeFilaDeSkuCompleta;
var
  cds: TClientDataSet;
  F: TFilaNuevaTarifa;
begin
  cds := CrearTarifas;
  try
    F.Sku := 'S1';
    F.Tarifa := 'T1';
    F.PrecioSalida := 10;
    F.PrecioFinal := 10;
    F.EsActiva := True;
    F.Vigencia :=
      Vigencia(EncodeDate(2026, 1, 1), True, EncodeDate(2026, 1, 31));
    EscribirFilaNuevaTarifa(cds, F);
    Assert.AreEqual(1, cds.RecordCount);
    Assert.AreEqual('S1',
      cds.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString);
    Assert.AreEqual('T1', cds.FieldByName('CODIGO_TAR_ARTTAR').AsString);
    Assert.AreEqual(Double(10),
      cds.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat, 0.0001);
    Assert.AreEqual(Double(10),
      cds.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat, 0.0001);
    Assert.AreEqual('S', cds.FieldByName('ESACTIVO_ARTTAR').AsString);
    Assert.IsTrue(
      cds.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime =
        EncodeDate(2026, 1, 1));
    Assert.IsTrue(
      cds.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime =
        EncodeDate(2026, 1, 31));
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasArticulosAltaTarifas.
  Dataset_EscribeFilaDeArticuloYDejaHastaNula;
var
  cds: TClientDataSet;
  F: TFilaNuevaTarifa;
begin
  cds := CrearTarifas;
  try
    F.Sku := '';
    F.Tarifa := 'T2';
    F.PrecioSalida := 0;
    F.PrecioFinal := 0;
    F.EsActiva := False;
    F.Vigencia := Vigencia(EncodeDate(2026, 2, 1), False, 0);
    EscribirFilaNuevaTarifa(cds, F);
    Assert.AreEqual('',
      cds.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString);
    Assert.AreEqual('N', cds.FieldByName('ESACTIVO_ARTTAR').AsString);
    Assert.IsTrue(cds.FieldByName('FECHA_HASTA_ARTTAR').IsNull);
  finally
    FreeAndNil(cds);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosAltaTarifas);

end.
