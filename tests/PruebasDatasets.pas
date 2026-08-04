{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDatasets                                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las utilidades de datasets.                                    }
{******************************************************************************}
unit PruebasDatasets;

interface

uses
  System.Classes, Data.DB, Datasnap.DBClient,
  DUnitX.TestFramework,
  inLibDatasetsPersistenciaIntf,
  inLibDBStructurePersistenciaIntf,
  inLibAlmacenesEmpresaPersistenciaIntf;

type
  TRepositorioMetadatosDoble = class(
    TInterfacedObject, IRepositorioMetadatosDatasets)
  public
    TablaSolicitada: string;
    Columnas: TArray<string>;
    function ObtenerColumnasClavePrimaria(
      const ATabla: string): TArray<string>;
  end;

  TRepositorioEstructuraDoble = class(
    TInterfacedObject, IRepositorioEstructuraBBDD)
  public
    EsquemaExiste: Boolean;
    TablaExiste: Boolean;
    VistaExiste: Boolean;
    ErrorLectura: Boolean;
    function ExisteEsquema(const AEsquema: string): Boolean;
    function ExisteTabla(const AEsquema, ATabla: string): Boolean;
    function ExisteVista(const AEsquema, AVista: string): Boolean;
  end;

  TRepositorioAlmacenesDoble = class(
    TInterfacedObject, IRepositorioAlmacenesEmpresa)
  public
    Pertenece: Boolean;
    PrimerAlmacen: string;
    AlmacenDeposito: string;
    function AlmacenPerteneceEmpresa(const AEmpresa,
      AAlmacen: string): Boolean;
    function PrimerAlmacenEmpresa(const AEmpresa: string): string;
    function ObtenerAlmacenDepositoEmpresa(
      const AEmpresa: string): string;
  end;

  [TestFixture]
  TPruebasDatasets = class
  private
    FModulo: TDataModule;
    FDataSet: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure ClaveSimple_ConvierteEnAmbosSentidos;
    [Test]
    procedure ClaveCompuesta_RoundTrip;
    [Test]
    procedure ClaveCompuesta_IncompletaRellenaNull;
    [Test]
    procedure ExtraerTabla_IgnoraSubconsultaYComillas;
    [Test]
    procedure ClavePrimaria_UsaProviderFlags;
    [Test]
    procedure ClavePrimaria_UsaRepositorioMetadatos;
    [Test]
    procedure Estructura_SeparaComprobacionYPresentacion;
    [Test]
    procedure Estructura_ErrorConservaTipo;
    [Test]
    procedure Almacen_ResuelveConRepositorioEspecifico;
    [Test]
    procedure EstadoDatasets_GrabaYCancela;
    [Test]
    procedure PeriodoUnico_UnRegistroEsValido;
    [Test]
    procedure PeriodoUnico_DetectaSolapamiento;
  end;

implementation

uses
  System.SysUtils, System.Variants,
  inLibDatasets, inLibDBStructure, inLibData;

function TRepositorioMetadatosDoble.ObtenerColumnasClavePrimaria(
  const ATabla: string): TArray<string>;
begin
  TablaSolicitada := ATabla;
  Result := Columnas;
end;

function TRepositorioEstructuraDoble.ExisteEsquema(
  const AEsquema: string): Boolean;
begin
  if ErrorLectura then
  begin
    raise ELecturaEstructuraBBDD.Create(
      eleConsultaFallida, 'fallo simulado');
  end;
  Result := EsquemaExiste;
end;

function TRepositorioEstructuraDoble.ExisteTabla(
  const AEsquema, ATabla: string): Boolean;
begin
  Result := TablaExiste;
end;

function TRepositorioEstructuraDoble.ExisteVista(
  const AEsquema, AVista: string): Boolean;
begin
  Result := VistaExiste;
end;

function TRepositorioAlmacenesDoble.AlmacenPerteneceEmpresa(
  const AEmpresa, AAlmacen: string): Boolean;
begin
  Result := Pertenece;
end;

function TRepositorioAlmacenesDoble.PrimerAlmacenEmpresa(
  const AEmpresa: string): string;
begin
  Result := PrimerAlmacen;
end;

function TRepositorioAlmacenesDoble.ObtenerAlmacenDepositoEmpresa(
  const AEmpresa: string): string;
begin
  Result := AlmacenDeposito;
end;

procedure TPruebasDatasets.Preparar;
begin
  FModulo := TDataModule.Create(nil);
  FDataSet := TClientDataSet.Create(FModulo);
  FDataSet.FieldDefs.Add('ID', ftInteger);
  FDataSet.FieldDefs.Add('SERIE', ftString, 10);
  FDataSet.FieldDefs.Add('NOMBRE', ftString, 40);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord([1, 'A', 'Inicial']);
end;

procedure TPruebasDatasets.Limpiar;
begin
  FDataSet := nil;
  FreeAndNil(FModulo);
end;

procedure TPruebasDatasets.ClaveSimple_ConvierteEnAmbosSentidos;
var
  vNueva: Variant;
begin
  Assert.AreEqual(
    'ABC', inLibDatasets.KeyValuesToStr('ABC'));
  vNueva := inLibDatasets.StrToKeyValues(
    'ABC', 'CODIGO');
  Assert.AreEqual('ABC', VarToStr(vNueva));
end;

procedure TPruebasDatasets.
  ClaveCompuesta_RoundTrip;
var
  sClave: string;
  vClave: Variant;
  vValores: Variant;
begin
  vValores := VarArrayCreate(
    [0, 2], varVariant);
  vValores[0] := 'EMP';
  vValores[1] := 'A';
  vValores[2] := 15;
  sClave := inLibDatasets.KeyValuesToStr(
    vValores);
  Assert.AreEqual('EMP|A|15', sClave);
  vClave := inLibDatasets.StrToKeyValues(
    sClave, 'EMPRESA;SERIE;NUMERO');
  Assert.AreEqual('EMP', VarToStr(vClave[0]));
  Assert.AreEqual('A', VarToStr(vClave[1]));
  Assert.AreEqual('15', VarToStr(vClave[2]));
end;

procedure TPruebasDatasets.
  ClaveCompuesta_IncompletaRellenaNull;
var
  vClave: Variant;
begin
  vClave := inLibDatasets.StrToKeyValues(
    'EMP|A', 'EMPRESA;SERIE;NUMERO');
  Assert.IsTrue(VarIsNull(vClave[2]));
end;

procedure TPruebasDatasets.
  ExtraerTabla_IgnoraSubconsultaYComillas;
const
  SQL_CON_SUBCONSULTA =
    'SELECT (SELECT COUNT(*) FROM secundaria) AS TOTAL ' +
    'FROM `principal` p WHERE p.ID = :ID';
begin
  Assert.AreEqual(
    'principal',
    inLibDatasets.ExtraerTablaDeSQL(
      SQL_CON_SUBCONSULTA));
end;

procedure TPruebasDatasets.
  ClavePrimaria_UsaProviderFlags;
begin
  FDataSet.FieldByName('ID').ProviderFlags :=
    [pfInUpdate, pfInWhere, pfInKey];
  FDataSet.FieldByName('SERIE').ProviderFlags :=
    [pfInUpdate, pfInWhere, pfInKey];
  Assert.AreEqual(
    'ID;SERIE',
    inLibDatasets.ObtenerClavePrimaria(
      FDataSet));
end;

procedure TPruebasDatasets.
  ClavePrimaria_UsaRepositorioMetadatos;
var
  oDoble: TRepositorioMetadatosDoble;
  oRepositorio: IRepositorioMetadatosDatasets;
begin
  oDoble := TRepositorioMetadatosDoble.Create;
  oRepositorio := oDoble;
  oDoble.Columnas := TArray<string>.Create(
    'CODIGO_EMP', 'CODIGO_DOC');
  Assert.AreEqual(
    'CODIGO_EMP;CODIGO_DOC',
    inLibDatasets.ObtenerClavePrimariaPorMetadatos(
      'fza_documentos', oRepositorio));
  Assert.AreEqual('fza_documentos', oDoble.TablaSolicitada);
end;

procedure TPruebasDatasets.
  Estructura_SeparaComprobacionYPresentacion;
var
  oDoble: TRepositorioEstructuraDoble;
  oRepositorio: IRepositorioEstructuraBBDD;
  oResultado: TDBStructureCheckResult;
  sPresentacion: string;
begin
  oDoble := TRepositorioEstructuraDoble.Create;
  oRepositorio := oDoble;
  oDoble.EsquemaExiste := True;
  oDoble.TablaExiste := True;
  oDoble.VistaExiste := False;
  oResultado := TDBStructureChecker.Check(
    oRepositorio, 'factuzam');
  Assert.AreEqual(
    Ord(dbsMissingObjects), Ord(oResultado.Status));
  sPresentacion := TDBStructureResultFormatter.Formatear(
    oResultado);
  Assert.IsTrue(Pos('Vista: VI_USUARIOS', sPresentacion) > 0);
end;

procedure TPruebasDatasets.
  Estructura_ErrorConservaTipo;
var
  oDoble: TRepositorioEstructuraDoble;
  oRepositorio: IRepositorioEstructuraBBDD;
  oResultado: TDBStructureCheckResult;
begin
  oDoble := TRepositorioEstructuraDoble.Create;
  oRepositorio := oDoble;
  oDoble.ErrorLectura := True;
  oResultado := TDBStructureChecker.Check(
    oRepositorio, 'factuzam');
  Assert.AreEqual(
    Ord(dbsConnectionError), Ord(oResultado.Status));
  Assert.AreEqual(
    Ord(eleConsultaFallida), Ord(oResultado.Error));
end;

procedure TPruebasDatasets.
  Almacen_ResuelveConRepositorioEspecifico;
var
  oDoble: TRepositorioAlmacenesDoble;
  oRepositorio: IRepositorioAlmacenesEmpresa;
begin
  oDoble := TRepositorioAlmacenesDoble.Create;
  oRepositorio := oDoble;
  oDoble.Pertenece := False;
  oDoble.PrimerAlmacen := 'A2';
  Assert.AreEqual(
    'A2',
    inLibData.ResolverAlmacenEmpresa(
      oRepositorio, 'EMP', 'A1'));
end;

procedure TPruebasDatasets.
  EstadoDatasets_GrabaYCancela;
begin
  FDataSet.Edit;
  FDataSet.FieldByName(
    'NOMBRE').AsString := 'Cancelado';
  Assert.IsTrue(
    inLibDatasets.CheckOpenDatasets(
      FModulo));
  inLibDatasets.CancelarDatasets(FModulo);
  Assert.AreEqual(
    'Inicial',
    FDataSet.FieldByName(
      'NOMBRE').AsString);
  FDataSet.Edit;
  FDataSet.FieldByName(
    'NOMBRE').AsString := 'Grabado';
  inLibDatasets.GrabarDatasets(FModulo);
  Assert.AreEqual(dsBrowse, FDataSet.State);
  Assert.AreEqual(
    'Grabado',
    FDataSet.FieldByName(
      'NOMBRE').AsString);
  Assert.IsFalse(
    inLibDatasets.CheckOpenDatasets(FModulo));
end;

procedure TPruebasDatasets.
  PeriodoUnico_UnRegistroEsValido;
var
  oCandidato: TClientDataSet;
  oPeriodos: TClientDataSet;
begin
  oCandidato := TClientDataSet.Create(nil);
  oPeriodos := TClientDataSet.Create(nil);
  try
    oCandidato.FieldDefs.Add(
      'FECHA_INICIO', ftDate);
    oCandidato.FieldDefs.Add(
      'FECHA_FIN', ftDate);
    oCandidato.CreateDataSet;
    oCandidato.AppendRecord([
      EncodeDate(2026, 2, 1),
      EncodeDate(2026, 2, 28)]);
    oPeriodos.FieldDefs.Assign(
      oCandidato.FieldDefs);
    oPeriodos.CreateDataSet;
    oPeriodos.AppendRecord([
      EncodeDate(2026, 1, 1),
      EncodeDate(2026, 1, 31)]);
    Assert.IsTrue(
      inLibDatasets.ExistePeriodoUnico(
        oPeriodos,
        oCandidato.FieldByName('FECHA_INICIO'),
        oCandidato.FieldByName('FECHA_FIN')));
  finally
    FreeAndNil(oPeriodos);
    FreeAndNil(oCandidato);
  end;
end;

procedure TPruebasDatasets.
  PeriodoUnico_DetectaSolapamiento;
var
  oCandidato: TClientDataSet;
  oPeriodos: TClientDataSet;
begin
  oCandidato := TClientDataSet.Create(nil);
  oPeriodos := TClientDataSet.Create(nil);
  try
    oCandidato.FieldDefs.Add(
      'FECHA_INICIO', ftDate);
    oCandidato.FieldDefs.Add(
      'FECHA_FIN', ftDate);
    oCandidato.CreateDataSet;
    oCandidato.AppendRecord([
      EncodeDate(2026, 1, 15),
      EncodeDate(2026, 2, 15)]);
    oPeriodos.FieldDefs.Assign(
      oCandidato.FieldDefs);
    oPeriodos.CreateDataSet;
    oPeriodos.AppendRecord([
      EncodeDate(2026, 1, 1),
      EncodeDate(2026, 1, 31)]);
    oPeriodos.AppendRecord([
      EncodeDate(2026, 3, 1),
      EncodeDate(2026, 3, 31)]);
    Assert.AreEqual(2, oPeriodos.RecordCount);
    oPeriodos.First;
    Assert.IsFalse(
      inLibDatasets.ExistePeriodoUnico(
        oPeriodos,
        oCandidato.FieldByName('FECHA_INICIO'),
        oCandidato.FieldByName('FECHA_FIN')));
  finally
    FreeAndNil(oPeriodos);
    FreeAndNil(oCandidato);
  end;
end;

end.
