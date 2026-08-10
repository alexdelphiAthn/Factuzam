{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasValoresAutomaticos                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de series y valores automáticos sin acceso a la BBDD.             }
{******************************************************************************}
unit PruebasValoresAutomaticos;

interface

uses
  System.Classes, Data.DB, Datasnap.DBClient,
  DUnitX.TestFramework,
  inLibValoresAutomaticosPersistenciaIntf,
  inLibLicenciaAplicacionPersistenciaIntf,
  inLibPermisosPersistenciaIntf, inLibPermisosIntf,
  inLibConfigCamposPersistenciaIntf,
  inLibUnidadesMedidaPersistenciaIntf;

type
  TRepositorioValoresAutomaticosDoble = class(
    TInterfacedObject, IRepositorioValoresAutomaticos)
  public
    ConsultasSeriePropia: Integer;
    SeriePropia: string;
    ResultadoContador: TResultadoContadorAutomatico;
    Valores: TArray<TValorPorDefectoPersistido>;
    function ObtenerSeriePropiaAlmacen(const AEmpresa,
      ATipoDocumento, AAlmacen: string): string;
    function ObtenerSerieDefecto(const AEmpresa, ATipoDocumento,
      AAlmacen: string): string;
    procedure CargarSeriesEmpresa(const AEmpresa,
      ATipoDocumento: string; AElementos: TStrings);
    function ObtenerSiguienteContador(const ATipoDocumento,
      AUsuario: string): TResultadoContadorAutomatico;
    function ObtenerValorPorDefecto(const ATabla, ACampo,
      ACampoCondicion: string): string;
    function CargarValoresPorDefecto(const ANombreTabla: string):
      TArray<TValorPorDefectoPersistido>;
  end;

  TRepositorioLicenciaDoble = class(
    TInterfacedObject, IRepositorioLicenciaAplicacion)
  public
    ResultadoNifs: TResultadoNifsLicencia;
    ResultadoConteo: TResultadoConteoFacturas;
    function CargarNifsEmpresas: TResultadoNifsLicencia;
    function ContarFacturasDia(AFecha: TDateTime):
      TResultadoConteoFacturas;
  end;

  TRepositorioPermisosDoble = class(
    TInterfacedObject, IRepositorioPermisos)
  public
    Resultado: TResultadoLecturaPermisos;
    function CargarReglas(const AIdentidad: TIdentidadPermisos):
      TResultadoLecturaPermisos;
  end;

  TRepositorioConfigCamposDoble = class(
    TInterfacedObject, IRepositorioConfigCampos)
  public
    Resultado: TResultadoConfigCampos;
    function CargarCampos: TResultadoConfigCampos;
  end;

  TRepositorioUnidadesDoble = class(
    TInterfacedObject, IRepositorioUnidadesMedida)
  public
    Unidades: TArray<TUnidadMedidaPersistida>;
    function CargarUnidades:
      TArray<TUnidadMedidaPersistida>;
  end;

  [TestFixture]
  TPruebasValoresAutomaticos = class
  private
    FDataSet: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure SeriePropia_SinDatosNoConsulta;
    [Test]
    procedure SerieDefecto_SinDatosNoConsulta;
    [Test]
    procedure CargarSeries_SinDatosLimpiaLista;
    [Test]
    procedure SeriePropia_UsaRepositorioEspecifico;
    [Test]
    procedure Contador_ErrorConservaTipo;
    [Test]
    procedure AplicarValores_UsaDatosDelRepositorio;
    [Test]
    procedure Licencia_ErrorConservaTipo;
    [Test]
    procedure Permisos_ErrorConservaTipo;
    [Test]
    procedure ConfigCampos_CargaDesdeRepositorio;
    [Test]
    procedure Unidades_CargaDesdeRepositorio;
    [Test]
    procedure AsignarValor_ConvierteTipos;
    [Test]
    procedure AsignarValor_CampoInexistenteNoAltera;
    [Test]
    procedure AsignarValor_InvalidoUsaCero;
  end;

implementation

uses
  System.SysUtils,
  inLibValoresAutomaticos, inLibLicenciaAplicacion,
  inLibPermisosUniDAC, inLibConfigCampos,
  inLibUnidadesMedida, inLibRegistroLogNulo;

const
  MARGEN = 0.0001;

function TRepositorioValoresAutomaticosDoble.ObtenerSeriePropiaAlmacen(
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Inc(ConsultasSeriePropia);
  Result := SeriePropia;
end;

function TRepositorioValoresAutomaticosDoble.ObtenerSerieDefecto(
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := SeriePropia;
end;

procedure TRepositorioValoresAutomaticosDoble.CargarSeriesEmpresa(
  const AEmpresa, ATipoDocumento: string; AElementos: TStrings);
begin
  AElementos.Add(SeriePropia);
end;

function TRepositorioValoresAutomaticosDoble.ObtenerSiguienteContador(
  const ATipoDocumento, AUsuario: string): TResultadoContadorAutomatico;
begin
  Result := ResultadoContador;
end;

function TRepositorioValoresAutomaticosDoble.ObtenerValorPorDefecto(
  const ATabla, ACampo, ACampoCondicion: string): string;
begin
  Result := '';
end;

function TRepositorioValoresAutomaticosDoble.CargarValoresPorDefecto(
  const ANombreTabla: string): TArray<TValorPorDefectoPersistido>;
begin
  Result := Valores;
end;

function TRepositorioLicenciaDoble.CargarNifsEmpresas:
  TResultadoNifsLicencia;
begin
  Result := ResultadoNifs;
end;

function TRepositorioLicenciaDoble.ContarFacturasDia(
  AFecha: TDateTime): TResultadoConteoFacturas;
begin
  Result := ResultadoConteo;
end;

function TRepositorioPermisosDoble.CargarReglas(
  const AIdentidad: TIdentidadPermisos):
  TResultadoLecturaPermisos;
begin
  Result := Resultado;
end;

function TRepositorioConfigCamposDoble.CargarCampos:
  TResultadoConfigCampos;
begin
  Result := Resultado;
end;

function TRepositorioUnidadesDoble.CargarUnidades:
  TArray<TUnidadMedidaPersistida>;
begin
  Result := Unidades;
end;

procedure TPruebasValoresAutomaticos.Preparar;
begin
  FDataSet := TClientDataSet.Create(nil);
  FDataSet.FieldDefs.Add(
    'CODIGO', ftString, 20);
  FDataSet.FieldDefs.Add(
    'ENTERO', ftInteger);
  FDataSet.FieldDefs.Add(
    'DECIMAL', ftFloat);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord([
    'INICIAL',
    1,
    1.0]);
end;

procedure TPruebasValoresAutomaticos.Limpiar;
begin
  FreeAndNil(FDataSet);
end;

procedure TPruebasValoresAutomaticos.
  SeriePropia_SinDatosNoConsulta;
begin
  Assert.AreEqual(
    '',
    inLibValoresAutomaticos.
      ObtenerSeriePropiaAlmacen(
        nil, '', 'AV', 'A1'));
end;

procedure TPruebasValoresAutomaticos.
  SerieDefecto_SinDatosNoConsulta;
begin
  Assert.AreEqual(
    '',
    inLibValoresAutomaticos.ObtenerSerieDefecto(
      nil, '', 'AV'));
end;

procedure TPruebasValoresAutomaticos.
  CargarSeries_SinDatosLimpiaLista;
var
  oElementos: TStringList;
begin
  oElementos := TStringList.Create;
  try
    oElementos.Add('ANTERIOR');
    inLibValoresAutomaticos.CargarSeriesEmpresa(
      nil, '', 'AV', oElementos);
    Assert.AreEqual(0, oElementos.Count);
  finally
    FreeAndNil(oElementos);
  end;
end;

procedure TPruebasValoresAutomaticos.
  SeriePropia_UsaRepositorioEspecifico;
var
  oDoble: TRepositorioValoresAutomaticosDoble;
  oRepositorio: IRepositorioValoresAutomaticos;
begin
  oDoble := TRepositorioValoresAutomaticosDoble.Create;
  oRepositorio := oDoble;
  oDoble.SeriePropia := 'A-2026';
  Assert.AreEqual(
    'A-2026',
    inLibValoresAutomaticos.ObtenerSeriePropiaAlmacen(
      oRepositorio, 'EMP', 'AV', 'A1'));
  Assert.AreEqual(1, oDoble.ConsultasSeriePropia);
end;

procedure TPruebasValoresAutomaticos.
  Contador_ErrorConservaTipo;
var
  bLanzada: Boolean;
  oDoble: TRepositorioValoresAutomaticosDoble;
  oRepositorio: IRepositorioValoresAutomaticos;
begin
  bLanzada := False;
  oDoble := TRepositorioValoresAutomaticosDoble.Create;
  oRepositorio := oDoble;
  oDoble.ResultadoContador :=
    TResultadoContadorAutomatico.Fallido(
      evaGeneracionContadorFallida, 'detalle técnico');
  try
    inLibValoresAutomaticos.ObtenerSiguienteContador(
      oRepositorio, 'AV', 'usuario');
  except
    on E: EValoresAutomaticosPersistencia do
    begin
      bLanzada := True;
      Assert.AreEqual(
        Ord(evaGeneracionContadorFallida),
        Ord(E.Error));
    end;
  end;
  Assert.IsTrue(bLanzada);
end;

procedure TPruebasValoresAutomaticos.
  AplicarValores_UsaDatosDelRepositorio;
var
  oDoble: TRepositorioValoresAutomaticosDoble;
  oRepositorio: IRepositorioValoresAutomaticos;
begin
  oDoble := TRepositorioValoresAutomaticosDoble.Create;
  oRepositorio := oDoble;
  SetLength(oDoble.Valores, 2);
  oDoble.Valores[0].Campo := 'CODIGO';
  oDoble.Valores[0].Valor := 'AUTOMATICO';
  oDoble.Valores[0].TipoDato := 'STRING';
  oDoble.Valores[1].Campo := 'ENTERO';
  oDoble.Valores[1].Valor := '42';
  oDoble.Valores[1].TipoDato := 'INTEGER';
  inLibValoresAutomaticos.AplicarValoresPorDefecto(
    oRepositorio, FDataSet, 'fza_prueba');
  Assert.AreEqual(
    'AUTOMATICO',
    FDataSet.FieldByName('CODIGO').AsString);
  Assert.AreEqual(
    42,
    FDataSet.FieldByName('ENTERO').AsInteger);
end;

procedure TPruebasValoresAutomaticos.
  Licencia_ErrorConservaTipo;
var
  bLanzada: Boolean;
  oDoble: TRepositorioLicenciaDoble;
  oRepositorio: IRepositorioLicenciaAplicacion;
begin
  bLanzada := False;
  oDoble := TRepositorioLicenciaDoble.Create;
  oRepositorio := oDoble;
  oDoble.ResultadoConteo := TResultadoConteoFacturas.Fallido(
    eplConsultaFallida, 'fallo simulado');
  try
    inLibLicenciaAplicacion.ContarFacturasDemoDia(
      oRepositorio, EncodeDate(2026, 8, 4));
  except
    on E: EErrorPersistenciaLicenciaAplicacion do
    begin
      bLanzada := True;
      Assert.AreEqual(
        Ord(eplConsultaFallida), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(bLanzada);
end;

procedure TPruebasValoresAutomaticos.
  Permisos_ErrorConservaTipo;
var
  bLanzada: Boolean;
  oDoble: TRepositorioPermisosDoble;
  oIdentidad: TIdentidadPermisos;
  oRepositorio: IRepositorioPermisos;
begin
  bLanzada := False;
  oDoble := TRepositorioPermisosDoble.Create;
  oRepositorio := oDoble;
  oDoble.Resultado := TResultadoLecturaPermisos.Fallido(
    elpConsultaFallida, 'fallo simulado');
  oIdentidad := TIdentidadPermisos.Crear(
    'usuario', 'grupo', False);
  try
    inLibPermisosUniDAC.TCargadorPermisosUniDAC.Cargar(
      oRepositorio, oIdentidad);
  except
    on E: EErrorCargaPermisos do
    begin
      bLanzada := True;
      Assert.AreEqual(
        Ord(elpConsultaFallida), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(bLanzada);
end;

procedure TPruebasValoresAutomaticos.
  ConfigCampos_CargaDesdeRepositorio;
var
  oCache: TConfigCamposCache;
  oDoble: TRepositorioConfigCamposDoble;
  oElemento: TConfigCampoPersistido;
  oRepositorio: IRepositorioConfigCampos;
begin
  oDoble := TRepositorioConfigCamposDoble.Create;
  oRepositorio := oDoble;
  oElemento.Tabla := 'fza_clientes';
  oElemento.Campo := 'NOMBRE_CLI';
  oElemento.TituloVisual := 'Cliente';
  oElemento.AnchoColumna := 120;
  oElemento.OrdenVisual := 1;
  oElemento.Visible := True;
  oDoble.Resultado := TResultadoConfigCampos.Correcto(
    TArray<TConfigCampoPersistido>.Create(oElemento));
  oCache := TConfigCamposCache.Create(
    oRepositorio, CrearRegistroLogNulo);
  try
    oCache.Precargar;
    Assert.IsTrue(oCache.Cargada);
    Assert.AreEqual(
      'Cliente',
      oCache.ObtenerTitulo('NOMBRE_CLI', 'fza_clientes'));
  finally
    FreeAndNil(oCache);
  end;
end;

procedure TPruebasValoresAutomaticos.
  Unidades_CargaDesdeRepositorio;
var
  oDoble: TRepositorioUnidadesDoble;
  oRepositorio: IRepositorioUnidadesMedida;
  oUnidades: TUnidadesMedida;
begin
  oDoble := TRepositorioUnidadesDoble.Create;
  oRepositorio := oDoble;
  SetLength(oDoble.Unidades, 2);
  oDoble.Unidades[0].Codigo := 'M';
  oDoble.Unidades[0].Magnitud := 'LONGITUD';
  oDoble.Unidades[0].EsBase := True;
  oDoble.Unidades[0].FactorBase := 1;
  oDoble.Unidades[1].Codigo := 'CM';
  oDoble.Unidades[1].Magnitud := 'LONGITUD';
  oDoble.Unidades[1].FactorBase := 0.01;
  oUnidades := TUnidadesMedida.Create(
    oRepositorio, CrearRegistroLogNulo);
  try
    oUnidades.Cargar;
    Assert.AreEqual(
      Double(1),
      oUnidades.Convertir(100, 'CM', 'M'),
      MARGEN);
  finally
    FreeAndNil(oUnidades);
  end;
end;

procedure TPruebasValoresAutomaticos.
  AsignarValor_ConvierteTipos;
begin
  FDataSet.Edit;
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'CODIGO', 'NUEVO', 'STRING');
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'ENTERO', '25', 'INTEGER');
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'DECIMAL', '12', 'FLOAT');
  Assert.AreEqual(
    'NUEVO',
    FDataSet.FieldByName(
      'CODIGO').AsString);
  Assert.AreEqual(
    25,
    FDataSet.FieldByName(
      'ENTERO').AsInteger);
  Assert.AreEqual(
    Double(12),
    FDataSet.FieldByName(
      'DECIMAL').AsFloat,
    MARGEN);
end;

procedure TPruebasValoresAutomaticos.
  AsignarValor_CampoInexistenteNoAltera;
begin
  FDataSet.Edit;
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'DESCONOCIDO', 'OTRO', 'STRING');
  Assert.AreEqual(
    'INICIAL',
    FDataSet.FieldByName(
      'CODIGO').AsString);
end;

procedure TPruebasValoresAutomaticos.
  AsignarValor_InvalidoUsaCero;
begin
  FDataSet.Edit;
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'ENTERO', 'NO_NUMERO', 'INTEGER');
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'DECIMAL', 'NO_NUMERO', 'FLOAT');
  Assert.AreEqual(
    0,
    FDataSet.FieldByName(
      'ENTERO').AsInteger);
  Assert.AreEqual(
    Double(0),
    FDataSet.FieldByName(
      'DECIMAL').AsFloat,
    MARGEN);
end;

end.
