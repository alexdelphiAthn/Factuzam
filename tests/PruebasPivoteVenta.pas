{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPivoteVenta                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracterización del pivote de venta (fascículo V1 del anexo SRP):         }
{    claves, bandas, cantidades, conjuntos virtuales, volcado a albaranar      }
{    y resolución de SKU, sin conexión a la BBDD.                              }
{******************************************************************************}
unit PruebasPivoteVenta;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  inLibPivoteVentaCalculo, inLibPivoteVentaIntf,
  inLibPivoteVentaModelo, DoblesPivoteVenta;

type
  [TestFixture]
  TPruebasPivoteVenta = class
  private
    FRepositorio: TRepositorioPivoteVentaMemoria;
    FContrato: IRepositorioPivoteVenta;
    FModelo: TModeloPivoteVenta;
    function DatosLinea(const AArticulo: string; ALinea: Integer;
                        APrecio: Double; ATallaAv, AColorAv: Integer;
                        const ASku: string;
                        APedida, AEntregada, AAAlbaranar: Double;
                        const AAlmacen: string)
                        : TDatosLineaPivoteVenta;
    procedure CrearModelo(ABandaUnica: Boolean);
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Liberar;
    [Test]
    procedure ClaveGrupoSeparaArticuloColorPrecio;
    [Test]
    procedure ClaveGrupoSinTallaRecibeFilaPropia;
    [Test]
    procedure ClaveCeldaYLineaVistaSonReversibles;
    [Test]
    procedure PendientesNuncaNegativos;
    [Test]
    procedure AjusteAAlbaranarRespetaPendienteBase;
    [Test]
    procedure TextosDeBandaYTipoCantidad;
    [Test]
    procedure PrefijoSkuTalla;
    [Test]
    procedure AgrupaPorArticuloColorPrecio;
    [Test]
    procedure TresBandasFrenteABandaUnica;
    [Test]
    procedure CantidadesPorBandaYPendiente;
    [Test]
    procedure CorrespondenciaCeldaSkuLineaReal;
    [Test]
    procedure LineaSinTallaOcupaPrimeraPosicion;
    [Test]
    procedure ConjuntoVirtualCuandoNoHayReal;
    [Test]
    procedure ConjuntoVirtualAnexaTallasFaltantes;
    [Test]
    procedure GrupoSinConjuntoQuedaRegistrado;
    [Test]
    procedure CargaNormalizaAAlbaranarExcesivo;
    [Test]
    procedure MarcarYLimpiarAAlbaranarEnCache;
    [Test]
    procedure VolcarAAlbaranarInformaAlmacen;
    [Test]
    procedure LineasRealesDeGrupoParaBorrado;
    [Test]
    procedure MaxPosicionesVisiblesCapado;
    [Test]
    procedure UdsGrupoAcumulaPedidas;
    [Test]
    procedure TipoCantidadEspecialSeConserva;
    [Test]
    procedure ResolucionPorSkuDirecto;
    [Test]
    procedure ResolucionPorCodigoBarras;
    [Test]
    procedure ResolucionCompletaTallaPorBarras;
    [Test]
    procedure ResolucionPorArticuloConSkuUnico;
    [Test]
    procedure ResolucionSinExitoConservaFallback;
  end;

implementation

uses
  System.SysUtils;

function TPruebasPivoteVenta.DatosLinea(const AArticulo: string;
  ALinea: Integer; APrecio: Double; ATallaAv, AColorAv: Integer;
  const ASku: string; APedida, AEntregada, AAAlbaranar: Double;
  const AAlmacen: string): TDatosLineaPivoteVenta;
begin
  Result := Default(TDatosLineaPivoteVenta);
  Result.Articulo := AArticulo;
  Result.Linea := ALinea;
  Result.LineaTexto := Format('%.4d', [ALinea]);
  Result.Precio := APrecio;
  Result.Sku := ASku;
  Result.Info.Encontrado := ASku <> '';
  Result.Info.TallaAv := ATallaAv;
  Result.Info.ColorAv := AColorAv;
  Result.Pedida := APedida;
  Result.Entregada := AEntregada;
  Result.AAlbaranar := AAAlbaranar;
  Result.Almacen := AAlmacen;
end;

procedure TPruebasPivoteVenta.CrearModelo(ABandaUnica: Boolean);
begin
  FreeAndNil(FModelo);
  FModelo := TModeloPivoteVenta.Create(FContrato, ABandaUnica,
                                       'A recibir');
  FModelo.IniciarCarga;
end;

procedure TPruebasPivoteVenta.Preparar;
begin
  FRepositorio := TRepositorioPivoteVentaMemoria.Create;
  FContrato := FRepositorio;
  CrearModelo(False);
end;

procedure TPruebasPivoteVenta.Liberar;
begin
  FreeAndNil(FModelo);
  FContrato := nil;
  FRepositorio := nil;
end;

procedure TPruebasPivoteVenta.ClaveGrupoSeparaArticuloColorPrecio;
begin
  Assert.AreEqual(
    ClaveGrupoPivoteVenta('ART', 5, 10.5, 7, '0001'),
    ClaveGrupoPivoteVenta('ART', 5, 10.5, 9, '0002'));
  Assert.AreNotEqual(
    ClaveGrupoPivoteVenta('ART', 5, 10.5, 7, '0001'),
    ClaveGrupoPivoteVenta('ART', 6, 10.5, 7, '0001'));
  Assert.AreNotEqual(
    ClaveGrupoPivoteVenta('ART', 5, 10.5, 7, '0001'),
    ClaveGrupoPivoteVenta('ART', 5, 12.0, 7, '0001'));
end;

procedure TPruebasPivoteVenta.ClaveGrupoSinTallaRecibeFilaPropia;
begin
  // Sin talla resoluble, cada línea real conserva fila propia: si
  // fusionaran, varias líneas sin SKU se machacarían en 'Cantidad'.
  Assert.AreNotEqual(
    ClaveGrupoPivoteVenta('ART', 0, 10, 0, '0001'),
    ClaveGrupoPivoteVenta('ART', 0, 10, 0, '0002'));
end;

procedure TPruebasPivoteVenta.ClaveCeldaYLineaVistaSonReversibles;
var
  iClave: Int64;
begin
  iClave := ClaveCeldaPivoteVenta(123, 45);
  Assert.AreEqual(123, LineaBaseDesdeClaveCelda(iClave));
  Assert.AreEqual(45, TallaAvDesdeClaveCelda(iClave));
  Assert.AreEqual(1230,
    LineaVistaBandaPivoteVenta(123, bpvPedida));
  Assert.AreEqual(1231,
    LineaVistaBandaPivoteVenta(123, bpvEntregada));
  Assert.AreEqual(1232,
    LineaVistaBandaPivoteVenta(123, bpvPendiente));
end;

procedure TPruebasPivoteVenta.PendientesNuncaNegativos;
begin
  Assert.AreEqual(Double(4), PendienteBasePivoteVenta(10, 6), 0.001);
  Assert.AreEqual(Double(0), PendienteBasePivoteVenta(5, 9), 0.001);
  Assert.AreEqual(Double(1), PendientePivoteVenta(10, 6, 3), 0.001);
  Assert.AreEqual(Double(0), PendientePivoteVenta(10, 6, 9), 0.001);
end;

procedure TPruebasPivoteVenta.AjusteAAlbaranarRespetaPendienteBase;
begin
  Assert.AreEqual(Double(4),
    AjustarAAlbaranarPivoteVenta(10, 6, 9), 0.001);
  Assert.AreEqual(Double(3),
    AjustarAAlbaranarPivoteVenta(10, 6, 3), 0.001);
  Assert.AreEqual(Double(0),
    AjustarAAlbaranarPivoteVenta(10, 6, -2), 0.001);
end;

procedure TPruebasPivoteVenta.TextosDeBandaYTipoCantidad;
begin
  Assert.AreEqual('Cantidad',
    TextoBandaPivoteVenta(bpvEntregada, True, ''));
  Assert.AreEqual('Pedido',
    TextoBandaPivoteVenta(bpvPedida, False, ''));
  Assert.AreEqual('A recibir',
    TextoBandaPivoteVenta(bpvEntregada, False, 'A recibir'));
  Assert.AreEqual('A albaranar',
    TextoBandaPivoteVenta(bpvEntregada, False, ''));
  Assert.AreEqual('Pendiente',
    TextoBandaPivoteVenta(bpvPendiente, False, ''));
  Assert.IsTrue(EsTipoCantidadPredeterminadoPivote('Uds'));
  Assert.IsFalse(EsTipoCantidadPredeterminadoPivote('Cajas'));
  Assert.AreEqual('Pedido - Cajas',
    TextoTipoCantidadPivoteVenta('Cajas', bpvPedida, False, ''));
  Assert.AreEqual('Cajas',
    TextoTipoCantidadPivoteVenta('Cajas', bpvPedida, True, ''));
end;

procedure TPruebasPivoteVenta.PrefijoSkuTalla;
begin
  Assert.AreEqual('ART/ROJO',
    PrefijoSkuTallaPivoteVenta('ART/ROJO/M'));
  Assert.AreEqual('', PrefijoSkuTallaPivoteVenta('ART'));
end;

procedure TPruebasPivoteVenta.AgrupaPorArticuloColorPrecio;
var
  iRepr1, iRepr2, iRepr3: Integer;
  bNuevo1, bNuevo2, bNuevo3: Boolean;
begin
  Assert.IsTrue(FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 5, 'ART/R/M', 3, 0, 0, 'A1'),
    iRepr1, bNuevo1));
  Assert.IsTrue(FModelo.RegistrarLinea(
    DatosLinea('ART', 2, 10, 72, 5, 'ART/R/L', 2, 0, 0, 'A1'),
    iRepr2, bNuevo2));
  Assert.IsTrue(FModelo.RegistrarLinea(
    DatosLinea('ART', 3, 12, 71, 5, 'ART/R/M', 1, 0, 0, 'A1'),
    iRepr3, bNuevo3));
  Assert.IsTrue(bNuevo1);
  Assert.IsFalse(bNuevo2);
  Assert.IsTrue(bNuevo3);
  // Las dos tallas del mismo precio comparten línea representante.
  Assert.AreEqual(iRepr1, iRepr2);
  Assert.AreNotEqual(iRepr1, iRepr3);
end;

procedure TPruebasPivoteVenta.TresBandasFrenteABandaUnica;
var
  iRepr: Integer;
  bNuevo: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('ART', 7, 10, 71, 0, 'ART/M', 3, 1, 0, 'A1'),
    iRepr, bNuevo);
  Assert.AreEqual(3, Integer(FModelo.LineasVista.Count));
  Assert.AreEqual(Ord(bpvPedida),
    Ord(FModelo.BandaDesdeLinea(FModelo.LineasVista[0])));
  Assert.AreEqual(Ord(bpvEntregada),
    Ord(FModelo.BandaDesdeLinea(FModelo.LineasVista[1])));
  Assert.AreEqual(Ord(bpvPendiente),
    Ord(FModelo.BandaDesdeLinea(FModelo.LineasVista[2])));
  Assert.AreEqual(iRepr,
    FModelo.ObtenerLineaBase(FModelo.LineasVista[1]));
  CrearModelo(True);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 7, 10, 71, 0, 'ART/M', 3, 1, 0, 'A1'),
    iRepr, bNuevo);
  Assert.AreEqual(1, Integer(FModelo.LineasVista.Count));
end;

procedure TPruebasPivoteVenta.CantidadesPorBandaYPendiente;
var
  iRepr: Integer;
  iClave: Int64;
  bNuevo: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('ART', 7, 10, 71, 0, 'ART/M', 10, 6, 3, 'A1'),
    iRepr, bNuevo);
  FModelo.CompletarCarga;
  iClave := ClaveCeldaPivoteVenta(iRepr, 71);
  Assert.AreEqual(Double(10),
    FModelo.ValorCantidadBanda(iClave, bpvPedida), 0.001);
  Assert.AreEqual(Double(3),
    FModelo.ValorCantidadBanda(iClave, bpvEntregada), 0.001);
  // Pendiente visual = pedida - entregada - a albaranar.
  Assert.AreEqual(Double(1),
    FModelo.ValorCantidadBanda(iClave, bpvPendiente), 0.001);
  Assert.AreEqual(Double(4), FModelo.PendienteBaseCelda(iClave),
                  0.001);
end;

procedure TPruebasPivoteVenta.CorrespondenciaCeldaSkuLineaReal;
var
  oCelda: TCeldaPivoteVenta;
  iRepr: Integer;
  bNuevo: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('ART', 9, 10, 71, 0, 'ART/M', 4, 0, 0, 'ALM2'),
    iRepr, bNuevo);
  Assert.IsTrue(FModelo.Celda(ClaveCeldaPivoteVenta(iRepr, 71),
                              oCelda));
  Assert.AreEqual('ART/M', oCelda.Sku);
  Assert.AreEqual('0009', oCelda.Linea);
  Assert.AreEqual('ALM2', oCelda.Almacen);
end;

procedure TPruebasPivoteVenta.LineaSinTallaOcupaPrimeraPosicion;
var
  oGrupo: TGrupoPivoteVenta;
  iRepr, iIdAv: Integer;
  bNuevo: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('SRV', 4, 10, 0, 0, '', 2, 0, 0, 'A1'),
    iRepr, bNuevo);
  Assert.IsTrue(FModelo.Grupo(iRepr, oGrupo));
  Assert.IsTrue(oGrupo.SinTalla);
  Assert.IsTrue(FModelo.TallaAvEnPosicion(iRepr, 1, iIdAv));
  Assert.AreEqual(ID_AV_SIN_TALLA_PIVOTE, iIdAv);
  Assert.IsFalse(FModelo.TallaAvEnPosicion(iRepr, 2, iIdAv));
end;

procedure TPruebasPivoteVenta.ConjuntoVirtualCuandoNoHayReal;
var
  oGrupo, oGrupo2: TGrupoPivoteVenta;
  aTallas: TValoresTallaPivoteVenta;
  iRepr, iRepr2: Integer;
  bNuevo: Boolean;
begin
  // Ningún conjunto real cubre las tallas y el artículo tiene tallas
  // en sus SKUs: conjunto VIRTUAL con id negativo.
  FRepositorio.ConjuntoQueCubre := 0;
  SetLength(aTallas, 2);
  aTallas[0].IdAv := 71;
  aTallas[0].Valor := 'M';
  aTallas[1].IdAv := 72;
  aTallas[1].Valor := 'L';
  FRepositorio.TallasPorArticulo.Add('ART', aTallas);
  FRepositorio.TallasPorArticulo.Add('ART2', aTallas);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 3, 0, 0, 'A1'),
    iRepr, bNuevo);
  FModelo.RegistrarLinea(
    DatosLinea('ART2', 5, 10, 72, 0, 'ART2/L', 3, 0, 0, 'A1'),
    iRepr2, bNuevo);
  FModelo.CompletarCarga;
  Assert.IsTrue(FModelo.Grupo(iRepr, oGrupo));
  Assert.IsTrue(oGrupo.IdAc < 0);
  Assert.AreEqual(2,
    Integer(Length(FModelo.PosicionesConjunto(oGrupo.IdAc))));
  Assert.AreEqual('M',
    FModelo.PosicionesConjunto(oGrupo.IdAc)[0].Valor);
  // Dos grupos con las MISMAS tallas comparten conjunto virtual.
  Assert.IsTrue(FModelo.Grupo(iRepr2, oGrupo2));
  Assert.AreEqual(oGrupo.IdAc, oGrupo2.IdAc);
end;

procedure TPruebasPivoteVenta.ConjuntoVirtualAnexaTallasFaltantes;
var
  oGrupo: TGrupoPivoteVenta;
  aTallas, aPosiciones: TValoresTallaPivoteVenta;
  iRepr: Integer;
  bNuevo: Boolean;
begin
  // La talla 99 del grupo no sale por el artículo: se anexa al final
  // para que su celda tenga columna donde pintarse.
  FRepositorio.ConjuntoQueCubre := 0;
  SetLength(aTallas, 1);
  aTallas[0].IdAv := 71;
  aTallas[0].Valor := 'M';
  FRepositorio.TallasPorArticulo.Add('ART', aTallas);
  FRepositorio.TallasCatalogo.Add(99, 'XXL');
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 99, 0, 'ART/XXL', 3, 0, 0, 'A1'),
    iRepr, bNuevo);
  FModelo.CompletarCarga;
  Assert.IsTrue(FModelo.Grupo(iRepr, oGrupo));
  aPosiciones := FModelo.PosicionesConjunto(oGrupo.IdAc);
  Assert.AreEqual(2, Integer(Length(aPosiciones)));
  Assert.AreEqual('M', aPosiciones[0].Valor);
  Assert.AreEqual('XXL', aPosiciones[1].Valor);
end;

procedure TPruebasPivoteVenta.GrupoSinConjuntoQuedaRegistrado;
var
  iRepr: Integer;
  bNuevo: Boolean;
begin
  // Sin conjunto real ni tallas del artículo: el grupo queda avisado
  // y sus celdas sin columna.
  FRepositorio.ConjuntoQueCubre := 0;
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 3, 0, 0, 'A1'),
    iRepr, bNuevo);
  FModelo.CompletarCarga;
  Assert.AreEqual(1, Integer(Length(FModelo.GruposSinConjunto)));
  Assert.AreEqual(iRepr, FModelo.GruposSinConjunto[0]);
end;

procedure TPruebasPivoteVenta.CargaNormalizaAAlbaranarExcesivo;
var
  iRepr: Integer;
  iClave: Int64;
  bNuevo: Boolean;
begin
  // "A albaranar" cargado por encima del pendiente base se recorta.
  FModelo.RegistrarLinea(
    DatosLinea('ART', 7, 10, 71, 0, 'ART/M', 10, 6, 9, 'A1'),
    iRepr, bNuevo);
  FModelo.CompletarCarga;
  iClave := ClaveCeldaPivoteVenta(iRepr, 71);
  Assert.AreEqual(Double(4), FModelo.AAlbaranarCelda(iClave), 0.001);
end;

procedure TPruebasPivoteVenta.MarcarYLimpiarAAlbaranarEnCache;
var
  iRepr1, iRepr2: Integer;
  bNuevo: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 10, 6, 0, 'A1'),
    iRepr1, bNuevo);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 2, 10, 72, 0, 'ART/L', 5, 5, 0, 'A1'),
    iRepr2, bNuevo);
  // Solo la celda con pendiente > 0 se marca.
  Assert.AreEqual(1, FModelo.MarcarTodoAAlbaranarEnCache);
  Assert.AreEqual(Double(4),
    FModelo.AAlbaranarCelda(ClaveCeldaPivoteVenta(iRepr1, 71)),
    0.001);
  FModelo.LimpiarAAlbaranarEnCache;
  Assert.AreEqual(Double(0),
    FModelo.AAlbaranarCelda(ClaveCeldaPivoteVenta(iRepr1, 71)),
    0.001);
end;

procedure TPruebasPivoteVenta.VolcarAAlbaranarInformaAlmacen;
var
  oLineas: TList<TPair<string, Currency>>;
  sAlmacen: string;
  iRepr1, iRepr2: Integer;
  bNuevo, bUnico: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 10, 6, 3, 'A1'),
    iRepr1, bNuevo);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 2, 10, 72, 0, 'ART/L', 5, 0, 2, 'A2'),
    iRepr2, bNuevo);
  FModelo.CompletarCarga;
  oLineas := TList<TPair<string, Currency>>.Create;
  try
    Assert.AreEqual(2,
      FModelo.VolcarAAlbaranar(oLineas, sAlmacen, bUnico));
    Assert.AreEqual(2, Integer(oLineas.Count));
    Assert.IsFalse(bUnico);
  finally
    FreeAndNil(oLineas);
  end;
end;

procedure TPruebasPivoteVenta.LineasRealesDeGrupoParaBorrado;
var
  aLineas: TArray<string>;
  iRepr1, iRepr2: Integer;
  bNuevo: Boolean;
begin
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 3, 0, 0, 'A1'),
    iRepr1, bNuevo);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 2, 10, 72, 0, 'ART/L', 2, 0, 0, 'A1'),
    iRepr1, bNuevo);
  FModelo.RegistrarLinea(
    DatosLinea('OTRO', 8, 10, 71, 0, 'OTRO/M', 2, 0, 0, 'A1'),
    iRepr2, bNuevo);
  aLineas := FModelo.LineasRealesDeGrupo(iRepr1);
  // Borrar el grupo debe alcanzar TODAS sus lineas reales, y solo
  // las suyas.
  Assert.AreEqual(2, Integer(Length(aLineas)));
end;

procedure TPruebasPivoteVenta.MaxPosicionesVisiblesCapado;
var
  aPosiciones: TValoresTallaPivoteVenta;
  iRepr: Integer;
  i: Integer;
  bNuevo: Boolean;
begin
  FRepositorio.ConjuntoQueCubre := 33;
  SetLength(aPosiciones, 6);
  for i := 0 to 5 do
  begin
    aPosiciones[i].IdAv := 70 + i;
    aPosiciones[i].Valor := 'T' + IntToStr(i);
  end;
  FRepositorio.PosicionesPorConjunto.Add(33, aPosiciones);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 3, 0, 0, 'A1'),
    iRepr, bNuevo);
  FModelo.CompletarCarga;
  Assert.AreEqual(6, FModelo.MaxPosicionesVisibles(20));
  // El máximo se capa al número de columnas del host.
  Assert.AreEqual(4, FModelo.MaxPosicionesVisibles(4));
end;

procedure TPruebasPivoteVenta.UdsGrupoAcumulaPedidas;
var
  iRepr: Integer;
  rUds: Double;
  bNuevo: Boolean;
begin
  CrearModelo(True);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 3, 0, 0, 'A1'),
    iRepr, bNuevo);
  FModelo.RegistrarLinea(
    DatosLinea('ART', 2, 10, 72, 0, 'ART/L', 2.5, 0, 0, 'A1'),
    iRepr, bNuevo);
  Assert.IsTrue(FModelo.UdsGrupoDeLineaVista(
    LineaVistaBandaPivoteVenta(iRepr, bpvPedida), rUds));
  Assert.AreEqual(Double(5.5), rUds, 0.001);
end;

procedure TPruebasPivoteVenta.TipoCantidadEspecialSeConserva;
var
  oDatos: TDatosLineaPivoteVenta;
  iRepr: Integer;
  bNuevo: Boolean;
begin
  oDatos := DatosLinea('ART', 1, 10, 71, 0, 'ART/M', 3, 0, 0, 'A1');
  oDatos.TipoCantidad := 'Uds';
  FModelo.RegistrarLinea(oDatos, iRepr, bNuevo);
  Assert.IsFalse(FModelo.HayTipoCantidadEspecial);
  oDatos := DatosLinea('ART', 2, 10, 72, 0, 'ART/L', 2, 0, 0, 'A1');
  oDatos.TipoCantidad := 'Cajas';
  FModelo.RegistrarLinea(oDatos, iRepr, bNuevo);
  Assert.IsTrue(FModelo.HayTipoCantidadEspecial);
  Assert.AreEqual('Pedido - Cajas',
    FModelo.TextoTipoCantidad(iRepr, bpvPedida));
end;

procedure TPruebasPivoteVenta.ResolucionPorSkuDirecto;
var
  oCampos: TCamposEntradaLineaPivote;
  oInfo: TInfoSkuPivoteVenta;
  sSku: string;
begin
  FRepositorio.DefinirSku('ART/R/M', 5, 71, 'Rojo', 'R', 'TC');
  oCampos := Default(TCamposEntradaLineaPivote);
  oCampos.Sku := 'ART/R/M';
  Assert.IsTrue(FModelo.ResolverInfoLinea(oCampos, sSku, oInfo));
  Assert.AreEqual('ART/R/M', sSku);
  Assert.AreEqual(71, oInfo.TallaAv);
  Assert.AreEqual('Rojo', oInfo.ColorTexto);
end;

procedure TPruebasPivoteVenta.ResolucionPorCodigoBarras;
var
  oCampos: TCamposEntradaLineaPivote;
  oInfo: TInfoSkuPivoteVenta;
  sSku: string;
begin
  FRepositorio.DefinirSku('ART/R/M', 5, 71, 'Rojo', 'R', 'TC');
  FRepositorio.SkuPorBarras.Add('843000111', 'ART/R/M');
  oCampos := Default(TCamposEntradaLineaPivote);
  oCampos.CodigoBarras := '843000111';
  Assert.IsTrue(FModelo.ResolverInfoLinea(oCampos, sSku, oInfo));
  Assert.AreEqual('ART/R/M', sSku);
end;

procedure TPruebasPivoteVenta.ResolucionCompletaTallaPorBarras;
var
  oCampos: TCamposEntradaLineaPivote;
  oInfo: TInfoSkuPivoteVenta;
  sSku: string;
begin
  // El SKU de la línea existe pero sin talla: el código de barras
  // escaneado aporta el SKU real con talla y debe prevalecer.
  FRepositorio.DefinirSku('ART', 0, 0, '', '', 'TC');
  FRepositorio.DefinirSku('ART/R/M', 5, 71, 'Rojo', 'R', 'TC');
  FRepositorio.SkuPorBarras.Add('843000111', 'ART/R/M');
  oCampos := Default(TCamposEntradaLineaPivote);
  oCampos.Sku := 'ART';
  oCampos.CodigoBarras := '843000111';
  Assert.IsTrue(FModelo.ResolverInfoLinea(oCampos, sSku, oInfo));
  Assert.AreEqual('ART/R/M', sSku);
  Assert.AreEqual(71, oInfo.TallaAv);
end;

procedure TPruebasPivoteVenta.ResolucionPorArticuloConSkuUnico;
var
  oCampos: TCamposEntradaLineaPivote;
  oInfo: TInfoSkuPivoteVenta;
  sSku: string;
begin
  FRepositorio.DefinirSku('ART/UNICO', 0, 71, '', '', 'TC');
  FRepositorio.SkuUnicoPorArticulo.Add('ART', 'ART/UNICO');
  oCampos := Default(TCamposEntradaLineaPivote);
  oCampos.Articulo := 'ART';
  Assert.IsTrue(FModelo.ResolverInfoLinea(oCampos, sSku, oInfo));
  Assert.AreEqual('ART/UNICO', sSku);
end;

procedure TPruebasPivoteVenta.ResolucionSinExitoConservaFallback;
var
  oCampos: TCamposEntradaLineaPivote;
  oInfo: TInfoSkuPivoteVenta;
  sSku: string;
begin
  oCampos := Default(TCamposEntradaLineaPivote);
  oCampos.CodigoProdPs := 'PS-77';
  Assert.IsFalse(FModelo.ResolverInfoLinea(oCampos, sSku, oInfo));
  // Sin resolución, el SKU visible conserva el código disponible.
  Assert.AreEqual('PS-77', sSku);
  oCampos.Sku := 'SKU-NO-CATALOGO';
  Assert.IsFalse(FModelo.ResolverInfoLinea(oCampos, sSku, oInfo));
  Assert.AreEqual('SKU-NO-CATALOGO', sSku);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPivoteVenta);

end.
