{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCatalogoSqlRepositorios                                }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los contratos SQL-1 de Facturas y Caja.                        }
{******************************************************************************}
unit PruebasCatalogoSqlRepositorios;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCatalogoSqlRepositorios = class
  public
    [Test]
    procedure Facturas_RegistraLecturasYEscriturasSoloBase;
    [Test]
    procedure Caja_RegistraLecturasIncluidoProcedimiento;
    [Test]
    procedure ComprasSesiones_RegistraDiecisieteLecturas;
    [Test]
    procedure MaterializacionCompras_RegistraDieciseisLecturas;
    [Test]
    procedure Facturas_PerfilSinCampoObligatorioVuelveBase;
    [Test]
    procedure Caja_PerfilConAliasIncompletosVuelveBase;
    [Test]
    procedure Caja_ProcedimientoDeLecturaAdmitePerfil;
    [Test]
    procedure DataSetSinCamposObligatoriosProvocaFallback;
    [Test]
    procedure CatalogoInactivoNoNecesitaServicioDePerfiles;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibCatalogoSqlIntf,
  inLibCatalogoSqlValidacion,
  inLibCatalogoSqlPerfiles,
  inLibPerfilesUsuarioIntf,
  UniDataCatalogoSqlValidacion,
  UniDataCatalogoSqlAplicacion,
  UniDataFacturasRepositorio,
  UniDataCajaConsultasRepositorio,
  UniDataComprasSesionesMaterializacionRepositorio,
  UniDataComprasSesionesRepositorio;

function BuscarDefinicion(
  const ADefiniciones: TDefinicionesSql;
  const AOperacion: string): TDefinicionSql;
var
  bEncontrada: Boolean;
  iIndice: Integer;
begin
  Result := Default(TDefinicionSql);
  bEncontrada := False;
  iIndice := 0;
  while (iIndice < Length(ADefiniciones)) and
        (not bEncontrada) do
  begin
    bEncontrada := SameText(
      ADefiniciones[iIndice].Operacion,
      AOperacion);
    if bEncontrada then
      Result := ADefiniciones[iIndice];
    Inc(iIndice);
  end;
  if not bEncontrada then
    raise Exception.CreateFmt(
      'No se encontró la definición SQL de %s.',
      [AOperacion]);
end;

function CrearCatalogoConPerfil(
  const ADefinicion: TDefinicionSql;
  const ASql: string): ICatalogoSql;
var
  oPerfil: TProfileDicc;
  oValor: TDictValue;
begin
  oValor.sValue := 'S;V=2';
  oValor.sValueText := ASql;
  oPerfil := TProfileDicc.Create;
  try
    oPerfil.Add(
      ClavePerfilSql(ADefinicion),
      oValor);
    Result := TCatalogoSqlPerfiles.Create(
      oPerfil);
  finally
    FreeAndNil(oPerfil);
  end;
end;

procedure TPruebasCatalogoSqlRepositorios.
  Facturas_RegistraLecturasYEscriturasSoloBase;
var
  iIndice: Integer;
  iLecturas: Integer;
  iSoloBase: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  iLecturas := 0;
  iSoloBase := 0;
  oDefiniciones :=
    TRepositorioFacturas.DefinicionesSql;
  Assert.AreEqual(
    7,
    Integer(Length(oDefiniciones)));
  for iIndice := 0 to High(oDefiniciones) do
  begin
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iIndice]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    if oDefiniciones[iIndice].Politica =
       pesPerfilLecturaConFallback then
      Inc(iLecturas);
    if oDefiniciones[iIndice].Politica =
       pesSoloBase then
      Inc(iSoloBase);
  end;
  Assert.AreEqual(5, iLecturas);
  Assert.AreEqual(2, iSoloBase);
end;

procedure TPruebasCatalogoSqlRepositorios.
  Caja_RegistraLecturasIncluidoProcedimiento;
var
  iIndice: Integer;
  iProcedimientos: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  iProcedimientos := 0;
  oDefiniciones :=
    TRepositorioConsultasCaja.DefinicionesSql;
  // 10 = 7 + las tres consultas de factura incorporadas en 95ecd9da.
  Assert.AreEqual(
    10,
    Integer(Length(oDefiniciones)));
  for iIndice := 0 to High(oDefiniciones) do
  begin
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iIndice]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    Assert.AreEqual(
      Ord(pesPerfilLecturaConFallback),
      Ord(oDefiniciones[iIndice].Politica));
    if oDefiniciones[iIndice].TipoSentencia =
       tssCall then
      Inc(iProcedimientos);
  end;
  Assert.AreEqual(1, iProcedimientos);
end;

procedure TPruebasCatalogoSqlRepositorios.
  ComprasSesiones_RegistraDiecisieteLecturas;
var
  iIndice: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioComprasSesiones.DefinicionesSql;
  Assert.AreEqual(
    17,
    Integer(Length(oDefiniciones)));
  for iIndice := 0 to High(oDefiniciones) do
  begin
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iIndice]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    Assert.AreEqual(
      Ord(pesPerfilLecturaConFallback),
      Ord(oDefiniciones[iIndice].Politica));
  end;
end;

procedure TPruebasCatalogoSqlRepositorios.
  MaterializacionCompras_RegistraDieciseisLecturas;
var
  iIndice: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioLecturasMaterializacionComprasSesiones.
      DefinicionesSql;
  Assert.AreEqual(
    16,
    Integer(Length(oDefiniciones)));
  for iIndice := 0 to High(oDefiniciones) do
  begin
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iIndice]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    Assert.AreEqual(
      Ord(pesPerfilLecturaConFallback),
      Ord(oDefiniciones[iIndice].Politica));
  end;
end;

procedure TPruebasCatalogoSqlRepositorios.
  Facturas_PerfilSinCampoObligatorioVuelveBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion := BuscarDefinicion(
    TRepositorioFacturas.DefinicionesSql,
    'EsPaisUE');
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT OTRO FROM fza_paises ' +
    'WHERE CODIGO_PAI_PAI = :PAIS');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.IsTrue(
    Pos(
      'Campos de salida',
      oResultado.MotivoSqlBase) > 0);
end;

procedure TPruebasCatalogoSqlRepositorios.
  Caja_PerfilConAliasIncompletosVuelveBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion := BuscarDefinicion(
    TRepositorioConsultasCaja.DefinicionesSql,
    'ConsultarClientes');
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT CODIGO_CLI_CLI AS `Código` ' +
    'FROM fza_clientes');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.IsNotEmpty(
    oResultado.MotivoSqlBase);
end;

procedure TPruebasCatalogoSqlRepositorios.
  Caja_ProcedimientoDeLecturaAdmitePerfil;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
  sSqlPerfil: string;
begin
  oDefinicion := BuscarDefinicion(
    TRepositorioConsultasCaja.DefinicionesSql,
    'ConsultarStock');
  sSqlPerfil :=
    'CALL PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ(:ARTICULO)';
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    sSqlPerfil);
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osPerfil),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    sSqlPerfil,
    oResultado.Texto);
end;

procedure TPruebasCatalogoSqlRepositorios.
  DataSetSinCamposObligatoriosProvocaFallback;
var
  oDataSet: TClientDataSet;
  oDefinicion: TDefinicionSql;
begin
  oDefinicion := BuscarDefinicion(
    TRepositorioFacturas.DefinicionesSql,
    'EsPaisUE');
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add(
      'OTRO',
      ftString,
      10);
    oDataSet.CreateDataSet;
    Assert.WillRaise(
      procedure
      begin
        ValidarCamposResultadoSql(
          oDefinicion,
          oDataSet);
      end,
      ECamposResultadoSql);
  finally
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasCatalogoSqlRepositorios.
  CatalogoInactivoNoNecesitaServicioDePerfiles;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oIncidencias: IRegistroIncidenciasSql;
  oResultado: TSqlResuelto;
  oRegistro: IRegistroDefinicionesSql;
begin
  CrearCatalogoSqlAplicacion(
    nil,
    nil,
    False,
    oCatalogo,
    oIncidencias);
  Assert.IsTrue(Assigned(oCatalogo));
  Assert.IsTrue(Assigned(oIncidencias));
  oRegistro :=
    CrearRegistroDefinicionesSqlAplicacion;
  // 123: ver el recuento de RegistroAplicacion_IncluyePiloto.
  Assert.AreEqual(
    123,
    oRegistro.Cantidad);
  oDefinicion := BuscarDefinicion(
    TRepositorioConsultasCaja.DefinicionesSql,
    'ConsultarStock');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
end;

initialization

TDUnitX.RegisterTestFixture(
  TPruebasCatalogoSqlRepositorios);

end.
