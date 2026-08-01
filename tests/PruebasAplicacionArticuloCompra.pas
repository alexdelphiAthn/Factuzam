{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasAplicacionArticuloCompra                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la aplicación de artículos de compra sin VCL ni BBDD.         }
{******************************************************************************}
unit PruebasAplicacionArticuloCompra;

interface

uses
  DUnitX.TestFramework, inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibAplicacionArticuloCompraIntf;

type
  TRepositorioArticuloCompraFalso = class(
    TInterfacedObject,
    IRepositorioLecturasArticuloCompra)
  public
    Datos: TArticuloDatos;
    Resolucion: TArtResolucionEntrada;
    UltimoCoste: TArticuloCoste;
    IdConjuntoPivote: Integer;
    ModeloProveedor: string;
    VecesUltimoCoste: Integer;
    function ResolverEntrada(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverDatos(
      const ACodigoArticulo, ACodigoSku: string;
      const AFecha: TDateTime;
      const ACodigoAlmacen,
      ACodigoProveedor: string): TArticuloDatos;
    function ResolverUltimoCoste(
      const ACodigoArticulo,
      ACodigoProveedor: string): TArticuloCoste;
    function BuscarConjuntoPivote(
      const ACodigoArticulo: string): Integer;
    function BuscarModeloProveedor(
      const ACodigoArticulo,
      ACodigoProveedor: string): string;
  end;

  TPuertoLineaArticuloCompraFalso = class(
    TInterfacedObject,
    IPuertoLineaArticuloCompra)
  public
    Configuracion: TConfiguracionCamposArticuloCompra;
    Linea: TLineaArticuloCompra;
    CantidadActual: Double;
    Preparado: Boolean;
    Aplicaciones: Integer;
    function PrepararLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      out ACantidadActual: Double): Boolean;
    procedure AplicarLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      const ALinea: TLineaArticuloCompra);
  end;

  [TestFixture]
  TPruebasAplicacionArticuloCompra = class
  private
    FAplicacion: IAplicacionArticuloCompra;
    FRepositorio: TRepositorioArticuloCompraFalso;
    FPuerto: TPuertoLineaArticuloCompraFalso;
    procedure PrepararEntradaEncontrada;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Liberar;
    [Test]
    procedure Configuracion_DistingueCamposDeLosTresDocumentos;
    [Test]
    procedure Pedido_AplicaArticuloYActivaPivote;
    [Test]
    procedure Factura_ConservaCantidadYSincronizaTotalUnidades;
    [Test]
    procedure Albaran_SinSkuDejaCantidadCeroYUsaCostePadre;
    [Test]
    procedure EntradaNoEncontrada_PresentaMensajeSinAplicarLinea;
    [Test]
    procedure ListadoProveedor_ConservaTiposYParametros;
  end;

implementation

uses
  inLibAplicacionArticuloCompra, UniDataDocsProveedorSql;

function TRepositorioArticuloCompraFalso.ResolverEntrada(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := Resolucion;
end;

function TRepositorioArticuloCompraFalso.ResolverDatos(
  const ACodigoArticulo, ACodigoSku: string;
  const AFecha: TDateTime;
  const ACodigoAlmacen,
  ACodigoProveedor: string): TArticuloDatos;
begin
  Result := Datos;
end;

function TRepositorioArticuloCompraFalso.ResolverUltimoCoste(
  const ACodigoArticulo,
  ACodigoProveedor: string): TArticuloCoste;
begin
  Inc(VecesUltimoCoste);
  Result := UltimoCoste;
end;

function TRepositorioArticuloCompraFalso.BuscarConjuntoPivote(
  const ACodigoArticulo: string): Integer;
begin
  Result := IdConjuntoPivote;
end;

function TRepositorioArticuloCompraFalso.BuscarModeloProveedor(
  const ACodigoArticulo,
  ACodigoProveedor: string): string;
begin
  Result := ModeloProveedor;
end;

function TPuertoLineaArticuloCompraFalso.PrepararLinea(
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  out ACantidadActual: Double): Boolean;
begin
  Configuracion := AConfiguracion;
  ACantidadActual := CantidadActual;
  Result := Preparado;
end;

procedure TPuertoLineaArticuloCompraFalso.AplicarLinea(
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  const ALinea: TLineaArticuloCompra);
begin
  Configuracion := AConfiguracion;
  Linea := ALinea;
  Inc(Aplicaciones);
end;

procedure TPruebasAplicacionArticuloCompra.Preparar;
var
  oRepositorio: IRepositorioLecturasArticuloCompra;
  oPuerto: IPuertoLineaArticuloCompra;
begin
  FRepositorio := TRepositorioArticuloCompraFalso.Create;
  FPuerto := TPuertoLineaArticuloCompraFalso.Create;
  FPuerto.Preparado := True;
  oRepositorio := FRepositorio;
  oPuerto := FPuerto;
  FAplicacion := CrearAplicacionArticuloCompra(oRepositorio, oPuerto);
  PrepararEntradaEncontrada;
end;

procedure TPruebasAplicacionArticuloCompra.Liberar;
begin
  FAplicacion := nil;
  FRepositorio := nil;
  FPuerto := nil;
end;

procedure TPruebasAplicacionArticuloCompra.PrepararEntradaEncontrada;
begin
  FRepositorio.Resolucion.Clear;
  FRepositorio.Resolucion.Encontrado := True;
  FRepositorio.Resolucion.CodigoArticulo := 'ART-1';
  FRepositorio.Resolucion.CodigoSku := 'ART-1/42';
  FRepositorio.Datos.Clear;
  FRepositorio.Datos.Encontrado := True;
  FRepositorio.Datos.CodigoArticulo := 'ART-1';
  FRepositorio.Datos.CodigoSku := 'ART-1/42';
  FRepositorio.Datos.CodigoFamilia := 'FAM';
  FRepositorio.Datos.DescripcionFamilia := 'Familia';
  FRepositorio.Datos.DescripcionArticulo := 'Artículo uno';
  FRepositorio.Datos.TipoCantidad := 'UNIDADES';
  FRepositorio.Datos.TipoIVA := 'N';
  FRepositorio.Datos.UltimoCoste.PrecioUltCompra := 12.5;
  FRepositorio.Datos.UltimoCoste.RefProveedor := 'REF-COSTE';
end;

procedure TPruebasAplicacionArticuloCompra.
  Configuracion_DistingueCamposDeLosTresDocumentos;
var
  oPedido: TConfiguracionCamposArticuloCompra;
  oFactura: TConfiguracionCamposArticuloCompra;
  oAlbaran: TConfiguracionCamposArticuloCompra;
begin
  oPedido := ConfiguracionCamposArticuloCompra(tdacPedido);
  oFactura := ConfiguracionCamposArticuloCompra(tdacFactura);
  oAlbaran := ConfiguracionCamposArticuloCompra(tdacAlbaran);
  Assert.AreEqual('CODIGO_ART_PEDCLIN', oPedido.CampoCodigoArticulo);
  Assert.AreEqual('TOTAL_PEDCLIN', oPedido.CampoTotal);
  Assert.IsTrue(oPedido.GestionarPivoteAntiguo);
  Assert.AreEqual('NOMBRE_FAM_FACCLIN', oFactura.CampoNombreFamilia);
  Assert.IsTrue(oFactura.ActualizarTotalUnidadesSiempre);
  Assert.AreEqual('CODIGO_ART_ALBCLIN', oAlbaran.CampoCodigoArticulo);
  Assert.AreEqual('', oAlbaran.CampoNombreFamilia);
end;

procedure TPruebasAplicacionArticuloCompra.
  Pedido_AplicaArticuloYActivaPivote;
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
begin
  oEntrada := Default(TEntradaAplicacionArticuloCompra);
  oEntrada.CodigoIntroducido := ' ART-1/42 ';
  oEntrada.CodigoProveedor := 'PRV';
  oEntrada.CodigoAlmacen := 'ALM';
  oEntrada.PreferenciaPivoteHorizontal := 'S';
  FRepositorio.IdConjuntoPivote := 7;
  FRepositorio.ModeloProveedor := 'MODELO-PRV';
  oResultado := FAplicacion.Ejecutar(oEntrada, tdacPedido);
  Assert.IsTrue(oResultado.Aplicado);
  Assert.AreEqual(
    Ord(apacActivarYRecargar),
    Ord(oResultado.AccionPivote));
  Assert.AreEqual('ART-1', FPuerto.Linea.CodigoArticulo);
  Assert.AreEqual('ART-1/42', FPuerto.Linea.CodigoSku);
  Assert.AreEqual('MODELO-PRV', FPuerto.Linea.ReferenciaProveedor);
  Assert.AreEqual('ALM', FPuerto.Linea.CodigoAlmacen);
  Assert.AreEqual(7, FPuerto.Linea.IdConjuntoPivote);
  Assert.AreEqual(Double(1), FPuerto.Linea.Cantidad, 0.0001);
  Assert.AreEqual(Double(12.5), FPuerto.Linea.Total, 0.0001);
end;

procedure TPruebasAplicacionArticuloCompra.
  Factura_ConservaCantidadYSincronizaTotalUnidades;
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
begin
  oEntrada := Default(TEntradaAplicacionArticuloCompra);
  oEntrada.CodigoIntroducido := 'ART-1';
  FPuerto.CantidadActual := 3;
  oResultado := FAplicacion.Ejecutar(oEntrada, tdacFactura);
  Assert.IsTrue(oResultado.Aplicado);
  Assert.AreEqual('Familia', FPuerto.Linea.NombreFamilia);
  Assert.IsFalse(FPuerto.Linea.AsignarCantidad);
  Assert.IsTrue(FPuerto.Linea.AsignarTotalUnidades);
  Assert.AreEqual(Double(3), FPuerto.Linea.Cantidad, 0.0001);
  Assert.AreEqual(Double(3), FPuerto.Linea.TotalUnidades, 0.0001);
  Assert.AreEqual(Double(37.5), FPuerto.Linea.Total, 0.0001);
  Assert.AreEqual(
    Ord(apacNinguna),
    Ord(oResultado.AccionPivote));
end;

procedure TPruebasAplicacionArticuloCompra.
  Albaran_SinSkuDejaCantidadCeroYUsaCostePadre;
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
begin
  oEntrada := Default(TEntradaAplicacionArticuloCompra);
  oEntrada.CodigoIntroducido := 'ART-1';
  oEntrada.CodigoProveedor := 'PRV';
  FRepositorio.Datos.RequiereSku := True;
  FRepositorio.Datos.CodigoSku := '';
  FRepositorio.Datos.UltimoCoste.Clear;
  FRepositorio.UltimoCoste.Clear;
  FRepositorio.UltimoCoste.PrecioUltCompra := 8;
  FRepositorio.UltimoCoste.RefProveedor := 'REF-PADRE';
  FRepositorio.ModeloProveedor := '';
  FPuerto.CantidadActual := 4;
  oResultado := FAplicacion.Ejecutar(oEntrada, tdacAlbaran);
  Assert.IsTrue(oResultado.Aplicado);
  Assert.IsTrue(oResultado.RequiereSku);
  Assert.AreEqual(1, FRepositorio.VecesUltimoCoste);
  Assert.AreEqual('REF-PADRE', FPuerto.Linea.ReferenciaProveedor);
  Assert.AreEqual(Double(0), FPuerto.Linea.Cantidad, 0.0001);
  Assert.AreEqual(Double(0), FPuerto.Linea.TotalUnidades, 0.0001);
  Assert.AreEqual(Double(0), FPuerto.Linea.Total, 0.0001);
end;

procedure TPruebasAplicacionArticuloCompra.
  EntradaNoEncontrada_PresentaMensajeSinAplicarLinea;
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
begin
  oEntrada := Default(TEntradaAplicacionArticuloCompra);
  oEntrada.CodigoIntroducido := 'DESCONOCIDO';
  FRepositorio.Resolucion.Encontrado := False;
  FRepositorio.Resolucion.Mensaje := 'Artículo no encontrado';
  oResultado := FAplicacion.Ejecutar(oEntrada, tdacPedido);
  Assert.IsFalse(oResultado.Aplicado);
  Assert.AreEqual('Artículo no encontrado', oResultado.Mensaje);
  Assert.AreEqual(0, FPuerto.Aplicaciones);
end;

procedure TPruebasAplicacionArticuloCompra.
  ListadoProveedor_ConservaTiposYParametros;
var
  sSql: string;
begin
  sSql := SqlListadoDocumentosProveedor;
  Assert.IsTrue(Pos('''PED'' AS TIPO_DOC', sSql) > 0);
  Assert.IsTrue(Pos('''ALB'' AS TIPO_DOC', sSql) > 0);
  Assert.IsTrue(Pos('''FAC'' AS TIPO_DOC', sSql) > 0);
  Assert.IsTrue(Pos('''DEV'' AS TIPO_DOC', sSql) > 0);
  Assert.IsTrue(Pos(':pDESDE', sSql) > 0);
  Assert.IsTrue(Pos(':pHASTA', sSql) > 0);
  Assert.IsTrue(Pos(':pTIP', sSql) > 0);
  Assert.IsTrue(Pos(':pSER', sSql) > 0);
  Assert.IsTrue(Pos(':pALM', sSql) > 0);
  Assert.IsTrue(Pos(':pPRV', sSql) > 0);
  Assert.IsTrue(Pos(':pTMP', sSql) > 0);
end;

initialization

TDUnitX.RegisterTestFixture(TPruebasAplicacionArticuloCompra);

end.
