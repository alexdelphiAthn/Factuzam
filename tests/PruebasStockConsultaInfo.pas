{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasStockConsultaInfo                                      }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del resumen de cabecera de la consulta de stock.                  }
{******************************************************************************}
unit PruebasStockConsultaInfo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasStockConsultaInfo = class
  public
    [Test]
    procedure Propiedades_FormateaListaBooleanoYTexto;
    [Test]
    procedure Tarifas_DestacaLaPredeterminada;
    [Test]
    procedure Proveedores_OcultaOMuestraElCoste;
  end;

  [TestFixture]
  TPruebasStockConsultaEstados = class
  public
    [Test]
    procedure ModoSimplificadoOfreceLosTotalesAgregados;
    [Test]
    procedure ModoDesglosadoSustituyeLosTotalesPorSusSubtipos;
    [Test]
    procedure LeyendaCambiaAModoSimplificadoParaEntradas;
    [Test]
    procedure LeyendaCambiaAModoDesglosadoParaVentas;
    [Test]
    procedure LeyendaNoCambiaElModoSiElEstadoYaEstaOfrecido;
    [Test]
    procedure CadaEstadoTieneNombreCortoYColorPropio;
  end;

  [TestFixture]
  TPruebasStockConsultaFotos = class
  public
    [Test]
    procedure PrimeraVisitaDeUnaDimensionObligaACargar;
    [Test]
    procedure CambioDeArticuloInvalidaLaCache;
    [Test]
    procedure AlternarFiltroObligaARecargarLaDimension;
    [Test]
    procedure CadaDimensionOfreceLasOtrasDosComoFiltro;
    [Test]
    procedure DisposicionDeTarjetasRespetaMargenesYColumnas;
  end;

  [TestFixture]
  TPruebasStockConsultaPropiedades = class
  public
    [Test]
    procedure SoloSeCantanLasPropiedadesQueDifierenDelArticulo;
    [Test]
    procedure LaMismaPropiedadRepetidaPorTallaNoSeDuplica;
    [Test]
    procedure ValorSegunTipoListaBooleanoOTexto;
  end;

  [TestFixture]
  TPruebasStockConsultaPivote = class
  public
    [Test]
    procedure ColumnasSinModoTodoNoIncluyenLaDeEstado;
    [Test]
    procedure ColumnasEnModoTodoIncluyenLaDeEstado;
    [Test]
    procedure AnchoDeLaColumnaDeGrupoDependeDelModoColor;
    [Test]
    procedure TallaDeColumnaTraduceElCampoDinamico;
    [Test]
    procedure SolicitudDePivoteTrasladaFiltrosYModo;
  end;

implementation

uses
  System.SysUtils,
  inLibStockConsultaInfo,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaPresentacionEstados,
  inLibStockConsultaPresentacionFotos,
  inLibStockConsultaPresentacionPivote,
  inLibStockConsultaPresentacionPropiedades;

procedure TPruebasStockConsultaInfo.
  Propiedades_FormateaListaBooleanoYTexto;
var
  Info: TInfoCabeceraStock;
  sTexto: string;
begin
  Info := Default(TInfoCabeceraStock);
  SetLength(Info.Propiedades, 3);
  Info.Propiedades[0].Nombre := 'Material';
  Info.Propiedades[0].TipoValor := 'LISTA';
  Info.Propiedades[0].ValorLista := 'Algodón';
  Info.Propiedades[1].Nombre := 'Lavable';
  Info.Propiedades[1].TipoValor := 'BOOLEANO';
  Info.Propiedades[1].ValorLibre := 'S';
  Info.Propiedades[2].Nombre := 'Nota';
  Info.Propiedades[2].TipoValor := 'TEXTO';
  Info.Propiedades[2].ValorLibre := 'Ligero';
  sTexto := FormatearInfoCabeceraStock(Info, 'PVP', False);
  Assert.IsTrue(Pos('Material: Algodón', sTexto) > 0);
  Assert.IsTrue(Pos('Lavable: Sí', sTexto) > 0);
  Assert.IsTrue(Pos('Nota: Ligero', sTexto) > 0);
end;

procedure TPruebasStockConsultaInfo.Tarifas_DestacaLaPredeterminada;
var
  Info: TInfoCabeceraStock;
  sTexto: string;
begin
  Info := Default(TInfoCabeceraStock);
  SetLength(Info.Tarifas, 1);
  Info.Tarifas[0].Codigo := 'PVP';
  Info.Tarifas[0].Nombre := 'Venta';
  Info.Tarifas[0].PrecioFinal := 25;
  sTexto := FormatearInfoCabeceraStock(Info, 'PVP', False);
  Assert.IsTrue(Pos('Tarifa por defecto - Venta', sTexto) > 0);
end;

procedure TPruebasStockConsultaInfo.Proveedores_OcultaOMuestraElCoste;
var
  Info: TInfoCabeceraStock;
  sConCoste: string;
  sCoste: string;
  sSinCoste: string;
begin
  Info := Default(TInfoCabeceraStock);
  SetLength(Info.Proveedores, 1);
  Info.Proveedores[0].Codigo := 'P1';
  Info.Proveedores[0].RazonSocial := 'Proveedor Uno';
  Info.Proveedores[0].Referencia := 'R-1';
  Info.Proveedores[0].PrecioUltimaCompra := 10;
  Info.Proveedores[0].EsPrincipal := True;
  sCoste := FormatFloat('#,##0.00', 10);
  sSinCoste := FormatearInfoCabeceraStock(Info, 'PVP', False);
  sConCoste := FormatearInfoCabeceraStock(Info, 'PVP', True);
  Assert.IsTrue(Pos('Proveedor ppal. - Proveedor Uno (ref R-1)',
                    sSinCoste) > 0);
  Assert.IsFalse(Pos(sCoste, sSinCoste) > 0);
  Assert.IsTrue(Pos(sCoste, sConCoste) > 0);
end;

procedure TPruebasStockConsultaEstados.
  ModoSimplificadoOfreceLosTotalesAgregados;
var
  Seleccion: TSeleccionEstadosStock;
begin
  Seleccion := TSeleccionEstadosStock.Create;
  try
    Assert.AreEqual(6, Seleccion.Cuenta);
    Assert.IsTrue(Seleccion.IndiceDe(esEntradas) >= 0);
    Assert.IsTrue(Seleccion.IndiceDe(esSalidas) >= 0);
    Assert.AreEqual(-1, Seleccion.IndiceDe(esVentas));
    Assert.AreEqual(0, Seleccion.IndiceDe(esExistencias));
  finally
    Seleccion.Free;
  end;
end;

procedure TPruebasStockConsultaEstados.
  ModoDesglosadoSustituyeLosTotalesPorSusSubtipos;
var
  Seleccion: TSeleccionEstadosStock;
begin
  Seleccion := TSeleccionEstadosStock.Create;
  try
    Seleccion.FijarModo(True);
    Assert.AreEqual(-1, Seleccion.IndiceDe(esEntradas));
    Assert.AreEqual(-1, Seleccion.IndiceDe(esSalidas));
    Assert.IsTrue(Seleccion.IndiceDe(esEntradaCompra) >= 0);
    Assert.IsTrue(Seleccion.IndiceDe(esVentas) >= 0);
    Assert.IsTrue(Seleccion.IndiceDe(esPrestadas) >= 0);
    Assert.AreEqual(14, Seleccion.Cuenta);
  finally
    Seleccion.Free;
  end;
end;

procedure TPruebasStockConsultaEstados.
  LeyendaCambiaAModoSimplificadoParaEntradas;
var
  Resultado: TResultadoLeyendaStock;
  Seleccion: TSeleccionEstadosStock;
begin
  Seleccion := TSeleccionEstadosStock.Create;
  try
    Seleccion.FijarModo(True);
    Resultado := Seleccion.ResolverLeyenda(esEntradas);
    Assert.IsTrue(Resultado.ModoCambiado);
    Assert.IsFalse(Resultado.ModoDesglosado);
    Assert.IsTrue(Resultado.Indice >= 0);
    Assert.AreEqual(
      Ord(esEntradas), Ord(Seleccion.Estados[Resultado.Indice]));
  finally
    Seleccion.Free;
  end;
end;

procedure TPruebasStockConsultaEstados.
  LeyendaCambiaAModoDesglosadoParaVentas;
var
  Resultado: TResultadoLeyendaStock;
  Seleccion: TSeleccionEstadosStock;
begin
  Seleccion := TSeleccionEstadosStock.Create;
  try
    Resultado := Seleccion.ResolverLeyenda(esVentas);
    Assert.IsTrue(Resultado.ModoCambiado);
    Assert.IsTrue(Resultado.ModoDesglosado);
    Assert.AreEqual(
      Ord(esVentas), Ord(Seleccion.Estados[Resultado.Indice]));
  finally
    Seleccion.Free;
  end;
end;

procedure TPruebasStockConsultaEstados.
  LeyendaNoCambiaElModoSiElEstadoYaEstaOfrecido;
var
  Resultado: TResultadoLeyendaStock;
  Seleccion: TSeleccionEstadosStock;
begin
  Seleccion := TSeleccionEstadosStock.Create;
  try
    Resultado := Seleccion.ResolverLeyenda(esPdteRecibir);
    Assert.IsFalse(Resultado.ModoCambiado);
    Assert.IsFalse(Resultado.ModoDesglosado);
    Assert.AreEqual(
      Seleccion.IndiceDe(esPdteRecibir), Resultado.Indice);
  finally
    Seleccion.Free;
  end;
end;

procedure TPruebasStockConsultaEstados.
  CadaEstadoTieneNombreCortoYColorPropio;
begin
  Assert.AreEqual('Existencias', NombreEstadoStockCorto(esExistencias));
  Assert.AreEqual('Todos los estados',
    NombreEstadoStockCorto(esTodoAlaVez));
  Assert.AreEqual(COLOR_ESTADO_EXISTENCIAS,
    ColorEstadoStock(esExistencias));
  Assert.AreEqual(COLOR_ESTADO_PDTE_RECIBIR,
    ColorEstadoStock(esPdteRecibir));
  Assert.AreEqual(COLOR_ESTADO_NEUTRO, ColorEstadoStock(esTodoAlaVez));
  Assert.IsTrue(EsEstadoStockValido(Ord(esExistencias)));
  Assert.IsFalse(EsEstadoStockValido(-1));
  Assert.IsFalse(EsEstadoStockValido(Ord(High(TEstadoStock)) + 1));
end;

procedure TPruebasStockConsultaFotos.
  PrimeraVisitaDeUnaDimensionObligaACargar;
var
  Estado: TEstadoFotosRelacionadas;
begin
  Estado := TEstadoFotosRelacionadas.Create;
  try
    Assert.IsTrue(Estado.DebeRecargar(dfFamilia, 'ART1'));
    Estado.IniciarCarga(dfFamilia, 'ART1');
    Estado.MarcarCargada(dfFamilia);
    Assert.IsFalse(Estado.DebeRecargar(dfFamilia, 'ART1'));
    Assert.IsTrue(Estado.DebeRecargar(dfProveedor, 'ART1'));
  finally
    Estado.Free;
  end;
end;

procedure TPruebasStockConsultaFotos.CambioDeArticuloInvalidaLaCache;
var
  Estado: TEstadoFotosRelacionadas;
begin
  Estado := TEstadoFotosRelacionadas.Create;
  try
    Estado.IniciarCarga(dfFamilia, 'ART1');
    Estado.MarcarCargada(dfFamilia);
    Assert.IsTrue(Estado.DebeRecargar(dfFamilia, 'ART2'));
    Estado.Invalidar;
    Assert.IsTrue(Estado.DebeRecargar(dfFamilia, 'ART1'));
  finally
    Estado.Free;
  end;
end;

procedure TPruebasStockConsultaFotos.
  AlternarFiltroObligaARecargarLaDimension;
var
  Estado: TEstadoFotosRelacionadas;
begin
  Estado := TEstadoFotosRelacionadas.Create;
  try
    Estado.IniciarCarga(dfFamilia, 'ART1');
    Estado.MarcarCargada(dfFamilia);
    Estado.AlternarFiltro(dfFamilia, dfProveedor);
    Assert.IsTrue(Estado.FiltroActivo(dfFamilia, dfProveedor));
    Assert.IsTrue(Estado.DebeRecargar(dfFamilia, 'ART1'));
    Estado.IniciarCarga(dfFamilia, 'ART1');
    Estado.MarcarCargada(dfFamilia);
    Assert.IsFalse(Estado.DebeRecargar(dfFamilia, 'ART1'));
    Estado.AlternarFiltro(dfFamilia, dfProveedor);
    Assert.IsFalse(Estado.FiltroActivo(dfFamilia, dfProveedor));
    Estado.AlternarFiltro(dfFamilia, dfTemporada);
    Estado.Reiniciar(dfFamilia);
    Assert.IsFalse(Estado.FiltroActivo(dfFamilia, dfTemporada));
  finally
    Estado.Free;
  end;
end;

procedure TPruebasStockConsultaFotos.
  CadaDimensionOfreceLasOtrasDosComoFiltro;
var
  Estado: TEstadoFotosRelacionadas;
  Filtros: TArray<TDimensionFotos>;
begin
  Estado := TEstadoFotosRelacionadas.Create;
  try
    Filtros := Estado.FiltrosSecundarios(dfFamilia);
    Assert.AreEqual(2, Length(Filtros));
    Assert.AreEqual(Ord(dfProveedor), Ord(Filtros[0]));
    Assert.AreEqual(Ord(dfTemporada), Ord(Filtros[1]));
    Filtros := Estado.FiltrosSecundarios(dfTemporada);
    Assert.AreEqual(Ord(dfFamilia), Ord(Filtros[0]));
    Assert.AreEqual(Ord(dfProveedor), Ord(Filtros[1]));
  finally
    Estado.Free;
  end;
  Assert.AreEqual('[X] Familia', EtiquetaFiltroFotos(dfFamilia, True));
  Assert.AreEqual('[ ] Temporada',
    EtiquetaFiltroFotos(dfTemporada, False));
end;

procedure TPruebasStockConsultaFotos.
  DisposicionDeTarjetasRespetaMargenesYColumnas;
var
  iX: Integer;
  iY: Integer;
begin
  Assert.AreEqual(1, ColumnasTarjetasFotos(100));
  Assert.AreEqual(3, ColumnasTarjetasFotos(540));
  PosicionTarjetaFotos(0, 3, iX, iY);
  Assert.AreEqual(MARGEN_TARJETA_FOTO_STOCK, iX);
  Assert.AreEqual(
    TOP_TARJETAS_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK, iY);
  PosicionTarjetaFotos(4, 3, iX, iY);
  Assert.AreEqual(
    MARGEN_TARJETA_FOTO_STOCK +
    (ANCHO_TARJETA_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK), iX);
  Assert.AreEqual(
    TOP_TARJETAS_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK +
    (ALTO_TARJETA_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK), iY);
end;

function PropiedadColor(
  const AColor, ANombre, ANivel, ATipo, AValor,
        AValorArticulo: string): TPropiedadColorStock;
begin
  Result := Default(TPropiedadColorStock);
  Result.Color := AColor;
  Result.Nombre := ANombre;
  Result.Nivel := ANivel;
  Result.TipoValor := ATipo;
  Result.ValorLibre := AValor;
  Result.ValorLibreArticulo := AValorArticulo;
end;

procedure TPruebasStockConsultaPropiedades.
  SoloSeCantanLasPropiedadesQueDifierenDelArticulo;
var
  Propiedades: TPropiedadesPorColorStock;
begin
  Propiedades := TPropiedadesPorColorStock.Create;
  try
    Propiedades.Agregar(PropiedadColor(
      'AZUL', 'Temporada', 'COLOR', 'TEXTO', 'V26', 'I25'));
    Propiedades.Agregar(PropiedadColor(
      'ROJO', 'Temporada', 'COLOR', 'TEXTO', 'I25', 'I25'));
    Assert.IsTrue(Propiedades.TieneColor('AZUL'));
    Assert.IsFalse(Propiedades.TieneColor('ROJO'));
    Assert.AreEqual(
      'Temporada: V26 (color)', Propiedades.TextoDe('AZUL'));
    Assert.AreEqual('', Propiedades.TextoDe('ROJO'));
    Propiedades.Limpiar;
    Assert.IsFalse(Propiedades.TieneColor('AZUL'));
  finally
    Propiedades.Free;
  end;
end;

procedure TPruebasStockConsultaPropiedades.
  LaMismaPropiedadRepetidaPorTallaNoSeDuplica;
var
  Propiedades: TPropiedadesPorColorStock;
begin
  Propiedades := TPropiedadesPorColorStock.Create;
  try
    Propiedades.Agregar(PropiedadColor(
      'AZUL', 'Material', 'SKU', 'TEXTO', 'Lino', ''));
    Propiedades.Agregar(PropiedadColor(
      'AZUL', 'Material', 'SKU', 'TEXTO', 'Lino', ''));
    Propiedades.Agregar(PropiedadColor(
      'AZUL', 'Temporada', 'COLOR', 'TEXTO', 'V26', ''));
    Assert.AreEqual(
      'Material: Lino (SKU)   ·   Temporada: V26 (color)',
      Propiedades.TextoDe('AZUL'));
  finally
    Propiedades.Free;
  end;
end;

procedure TPruebasStockConsultaPropiedades.
  ValorSegunTipoListaBooleanoOTexto;
begin
  Assert.AreEqual('Algodón',
    ValorPropiedadColorStock('LISTA', ' Algodón ', 'x'));
  Assert.AreEqual('Sí', ValorPropiedadColorStock('BOOLEANO', '', 'S'));
  Assert.AreEqual('No', ValorPropiedadColorStock('BOOLEANO', '', 'N'));
  Assert.AreEqual('', ValorPropiedadColorStock('BOOLEANO', '', '  '));
  Assert.AreEqual('Nota', ValorPropiedadColorStock('TEXTO', '', ' Nota'));
  Assert.AreEqual('  AZUL →   Prop',
    LetreroPropiedadesColorStock('AZUL', 'Prop'));
end;

function TallasDePrueba: TArray<TInfoColumna>;
begin
  SetLength(Result, 2);
  Result[0].Codigo := 'S';
  Result[0].Texto := 'S';
  Result[1].Codigo := 'M';
  Result[1].Texto := 'M';
end;

procedure TPruebasStockConsultaPivote.
  ColumnasSinModoTodoNoIncluyenLaDeEstado;
var
  Columnas: TDefinicionesColumnasPivote;
begin
  Columnas := DefinirColumnasPivoteStock(
    TallasDePrueba, False, False, 'Almacén', 'Estado', 'Total');
  Assert.AreEqual(4, Length(Columnas));
  Assert.AreEqual(Ord(cpsGrupo), Ord(Columnas[0].Clase));
  Assert.AreEqual(CAMPO_GRUPO_PIVOTE_STOCK, Columnas[0].Campo);
  Assert.AreEqual(Ord(cpsTalla), Ord(Columnas[1].Clase));
  Assert.AreEqual('T0', Columnas[1].Campo);
  Assert.AreEqual('T1', Columnas[2].Campo);
  Assert.AreEqual(Ord(cpsTotal), Ord(Columnas[3].Clase));
  Assert.AreEqual(CAMPO_TOTAL_PIVOTE_STOCK, Columnas[3].Campo);
end;

procedure TPruebasStockConsultaPivote.
  ColumnasEnModoTodoIncluyenLaDeEstado;
var
  Columnas: TDefinicionesColumnasPivote;
begin
  Columnas := DefinirColumnasPivoteStock(
    TallasDePrueba, True, True, 'Color', 'Estado', 'Total');
  Assert.AreEqual(5, Length(Columnas));
  Assert.AreEqual(Ord(cpsEstado), Ord(Columnas[1].Clase));
  Assert.AreEqual(CAMPO_ESTADO_PIVOTE_STOCK, Columnas[1].Campo);
  Assert.AreEqual(ANCHO_COL_ESTADO_STOCK, Columnas[1].Ancho);
end;

procedure TPruebasStockConsultaPivote.
  AnchoDeLaColumnaDeGrupoDependeDelModoColor;
var
  Columnas: TDefinicionesColumnasPivote;
  Tallas: TArray<TInfoColumna>;
begin
  SetLength(Tallas, 0);
  Columnas := DefinirColumnasPivoteStock(
    Tallas, True, False, 'Color', 'Estado', 'Total');
  Assert.AreEqual(ANCHO_COL_COLOR_STOCK, Columnas[0].Ancho);
  Assert.AreEqual(2, Length(Columnas));
  Columnas := DefinirColumnasPivoteStock(
    Tallas, False, False, 'Almacén', 'Estado', 'Total');
  Assert.AreEqual(ANCHO_COL_ALMACEN_STOCK, Columnas[0].Ancho);
end;

procedure TPruebasStockConsultaPivote.
  TallaDeColumnaTraduceElCampoDinamico;
var
  sTalla: string;
  Tallas: TArray<TInfoColumna>;
begin
  Tallas := TallasDePrueba;
  Assert.IsTrue(TallaDeColumnaPivoteStock('T1', Tallas, sTalla));
  Assert.AreEqual('M', sTalla);
  Assert.IsFalse(TallaDeColumnaPivoteStock('T7', Tallas, sTalla));
  Assert.IsFalse(TallaDeColumnaPivoteStock('GRUPO', Tallas, sTalla));
  Assert.IsFalse(TallaDeColumnaPivoteStock('TOTAL', Tallas, sTalla));
  SetLength(Tallas, 0);
  Assert.IsTrue(TallaDeColumnaPivoteStock('TOTAL', Tallas, sTalla));
  Assert.AreEqual('', sTalla);
end;

procedure TPruebasStockConsultaPivote.
  SolicitudDePivoteTrasladaFiltrosYModo;
var
  Almacenes: TArray<string>;
  Colores: TArray<string>;
  Solicitud: TSolicitudPivoteStock;
begin
  Almacenes := ['ALM1', 'ALM2'];
  Colores := ['AZUL'];
  Solicitud := ComponerSolicitudPivoteStock(
    'ART1', esPdteRecibir, True, True, False, Almacenes, Colores);
  Assert.AreEqual('ART1', Solicitud.CodigoArticulo);
  Assert.AreEqual(Ord(esPdteRecibir), Ord(Solicitud.Estado));
  Assert.IsTrue(Solicitud.ModoDesglosado);
  Assert.IsTrue(Solicitud.PorColor);
  Assert.IsFalse(Solicitud.OcultarCeros);
  Assert.AreEqual(2, Length(Solicitud.Almacenes));
  Assert.AreEqual('AZUL', Solicitud.Colores[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaInfo);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaEstados);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaFotos);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaPropiedades);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaPivote);

end.
