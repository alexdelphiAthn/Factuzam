{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArqueoTicketCatalogo                                  }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el catálogo de lecturas de presentación del arqueo.             }
{******************************************************************************}
unit PruebasArqueoTicketCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArqueoTicketCatalogo = class
  public
    [Test]
    procedure RegistraOnceLecturasValidas;
    [Test]
    procedure ResumenSeccion_UsaProfundidadParametrizada;
    [Test]
    procedure CierreHistorico_DeclaraCamposNucleo;
    [Test]
    procedure PerfilSinCampos_ResuelveSqlBase;
    [Test]
    procedure FalloDeEjecucion_ReintentaSqlBase;
    [Test]
    procedure PresentacionCierre_EsIdempotente;
    [Test]
    procedure DesgloseBilletes_DescartaEntradasInvalidas;
    [Test]
    procedure OpcionalesCierre_SePresentanCuandoExisten;
    [Test]
    procedure OpcionalesCierre_SeOmitenCuandoFaltan;
    [Test]
    procedure FilaRecuento_ConservaAnchoTermico;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  inLibCatalogoSqlIntf,
  inLibCatalogoSqlValidacion,
  inLibCatalogoSqlPerfiles,
  inLibCatalogoSqlEjecucion,
  inLibPerfilesUsuarioIntf,
  inLibArqueoPersistencia,
  inLibArqueoTicketPresentacion,
  inLibMsgTickets,
  UniDataArqueoTicketRepositorio;

type
  TCatalogoSqlArqueoTicketFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlArqueoTicketFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlArqueoTicketFijo.Resolver(
  const ADefinicion: TDefinicionSql): TSqlResuelto;
begin
  Result.Texto := FSqlPerfil;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := '';
  Result.Origen := osPerfil;
  Result.Politica := ADefinicion.Politica;
end;

function CrearCatalogoConPerfil(
  const ADefinicion: TDefinicionSql;
  const ASql: string): ICatalogoSql;
var
  oPerfil: TProfileDicc;
  oValor: TDictValue;
begin
  oValor.sValue := 'S;V=1';
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

function CrearDatosPresentacionMinimos:
  TDatosPresentacionCierreArqueo;
begin
  Result := Default(TDatosPresentacionCierreArqueo);
  Result.Arqueo.Empresa := 'E1';
  Result.Arqueo.Almacen := 'A1';
  Result.Arqueo.Caja := 'C1';
  Result.Arqueo.FechaDesde := EncodeDateTime(2026, 8, 6, 9, 0, 0, 0);
  Result.Arqueo.FechaHasta := EncodeDateTime(2026, 8, 6, 18, 0, 0, 0);
  Result.Arqueo.CantidadVentas := 3;
  Result.Usuario := 'PRUEBAS';
  Result.InstanteEmision := EncodeDateTime(2026, 8, 6, 18, 1, 0, 0);
end;

function ContieneTextoIzquierdo(
  const APresentacion: TPresentacionTicketArqueo;
  const ATexto: string): Boolean;
var
  iComando: Integer;
begin
  Result := False;
  iComando := 0;
  while (iComando < Length(APresentacion)) and not Result do
  begin
    Result := APresentacion[iComando].Texto = ATexto;
    Inc(iComando);
  end;
end;

function PresentacionesIguales(
  const AIzquierda: TPresentacionTicketArqueo;
  const ADerecha: TPresentacionTicketArqueo): Boolean;
var
  iComando: Integer;
begin
  Result := Length(AIzquierda) = Length(ADerecha);
  iComando := 0;
  while (iComando < Length(AIzquierda)) and Result do
  begin
    Result :=
      (AIzquierda[iComando].Tipo = ADerecha[iComando].Tipo) and
      (AIzquierda[iComando].Texto = ADerecha[iComando].Texto) and
      (AIzquierda[iComando].TextoDerecha =
       ADerecha[iComando].TextoDerecha) and
      (AIzquierda[iComando].Alineacion =
       ADerecha[iComando].Alineacion) and
      (AIzquierda[iComando].Caracter = ADerecha[iComando].Caracter) and
      (AIzquierda[iComando].Cantidad = ADerecha[iComando].Cantidad) and
      (AIzquierda[iComando].Activar = ADerecha[iComando].Activar);
    Inc(iComando);
  end;
end;

procedure TPruebasArqueoTicketCatalogo.
  RegistraOnceLecturasValidas;
var
  iDefinicion: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioArqueoTicket.DefinicionesSql;
  Assert.AreEqual(
    11,
    Integer(Length(oDefiniciones)));
  iDefinicion := 0;
  while iDefinicion < Length(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioArqueoTicket',
      oDefiniciones[iDefinicion].Repositorio);
    Assert.AreEqual(
      Ord(pesPerfilLecturaConFallback),
      Ord(oDefiniciones[iDefinicion].Politica));
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iDefinicion]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    Inc(iDefinicion);
  end;
end;

procedure TPruebasArqueoTicketCatalogo.
  ResumenSeccion_UsaProfundidadParametrizada;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[3];
  Assert.AreEqual(
    'ListarResumenSeccion',
    oDefinicion.Operacion);
  Assert.IsTrue(
    Pos('pNIVELES', oDefinicion.Parametros) > 0);
  Assert.IsTrue(
    Pos(':pNIVELES', oDefinicion.SqlBase) > 0);
  Assert.AreEqual(
    'FAMILIA,UDS,NETO',
    oDefinicion.CamposResultado);
end;

procedure TPruebasArqueoTicketCatalogo.
  CierreHistorico_DeclaraCamposNucleo;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[9];
  Assert.AreEqual(
    'ObtenerCierreHistorico',
    oDefinicion.Operacion);
  Assert.IsTrue(
    Pos(
      'TOTAL_EFECTIVO_CAJA_ARQ',
      oDefinicion.CamposResultado) > 0);
  Assert.IsTrue(
    Pos(
      'NOMBRE_VENDEDOR',
      oDefinicion.CamposResultado) > 0);
end;

procedure TPruebasArqueoTicketCatalogo.
  PerfilSinCampos_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[0];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT NIF_EMP FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :pEMPRESA');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasArqueoTicketCatalogo.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[8];
  oCatalogo := TCatalogoSqlArqueoTicketFijo.Create(
    'SELECT CODIGO_EMP_ARQ, CODIGO_ALM_ARQ, CODIGO_CAJA_ARQ, ' +
    'FECHA_DESDE_ARQ, FECHA_HASTA_ARQ FROM perfil ' +
    'WHERE :pARQ = :pARQ AND :pEMP = :pEMP ' +
    'AND :pALM = :pALM AND :pCAJA = :pCAJA');
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    oCatalogo,
    procedure(const ASql: string)
    begin
      Inc(iIntentos);
      if ASql <> oDefinicion.SqlBase then
        raise Exception.Create(
          'Fallo simulado del perfil');
    end);
  Assert.AreEqual(
    2,
    iIntentos);
end;

procedure TPruebasArqueoTicketCatalogo.
  PresentacionCierre_EsIdempotente;
var
  aPrimera: TPresentacionTicketArqueo;
  aSegunda: TPresentacionTicketArqueo;
  oDatos: TDatosPresentacionCierreArqueo;
begin
  oDatos := CrearDatosPresentacionMinimos;
  aPrimera := ConstruirPresentacionCierreArqueo(oDatos);
  aSegunda := ConstruirPresentacionCierreArqueo(oDatos);
  Assert.IsTrue(PresentacionesIguales(aPrimera, aSegunda));
end;

procedure TPruebasArqueoTicketCatalogo.
  DesgloseBilletes_DescartaEntradasInvalidas;
var
  aPresentacion: TPresentacionTicketArqueo;
  oDatos: TDatosPresentacionCierreArqueo;
begin
  oDatos := CrearDatosPresentacionMinimos;
  oDatos.DesgloseBilletes := '10:2;20:0;sin_separador;5:-1';
  aPresentacion := ConstruirPresentacionCierreArqueo(oDatos);
  Assert.IsTrue(
    ContieneTextoIzquierdo(aPresentacion, '  10 EUR x 2'));
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, '  20 EUR x 0'));
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, 'sin_separador'));
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, '  5 EUR x -1'));
end;

procedure TPruebasArqueoTicketCatalogo.
  OpcionalesCierre_SePresentanCuandoExisten;
var
  aPresentacion: TPresentacionTicketArqueo;
  oDatos: TDatosPresentacionCierreArqueo;
begin
  oDatos := CrearDatosPresentacionMinimos;
  oDatos.Duplicado := True;
  oDatos.Vendedor := 'VENDEDOR';
  oDatos.Retirada := 50;
  oDatos.ConceptoRetirada := 'BANCO';
  oDatos.Observaciones := 'SIN INCIDENCIAS';
  aPresentacion := ConstruirPresentacionCierreArqueo(oDatos);
  Assert.IsTrue(
    ContieneTextoIzquierdo(aPresentacion, STicketDuplicado));
  Assert.IsTrue(
    ContieneTextoIzquierdo(aPresentacion, STicketVendedor));
  Assert.IsTrue(
    ContieneTextoIzquierdo(aPresentacion, STicketRetirada));
  Assert.IsTrue(
    ContieneTextoIzquierdo(aPresentacion, STicketDestinoSangrado));
  Assert.IsTrue(
    ContieneTextoIzquierdo(
      aPresentacion,
      Format(STicketObservaciones, [oDatos.Observaciones])));
end;

procedure TPruebasArqueoTicketCatalogo.
  OpcionalesCierre_SeOmitenCuandoFaltan;
var
  aPresentacion: TPresentacionTicketArqueo;
  oDatos: TDatosPresentacionCierreArqueo;
begin
  oDatos := CrearDatosPresentacionMinimos;
  aPresentacion := ConstruirPresentacionCierreArqueo(oDatos);
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, STicketDuplicado));
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, STicketVendedor));
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, STicketRetirada));
  Assert.IsFalse(
    ContieneTextoIzquierdo(aPresentacion, STicketDestinoSangrado));
end;

procedure TPruebasArqueoTicketCatalogo.
  FilaRecuento_ConservaAnchoTermico;
var
  sFila: string;
begin
  sFila := FormatearImportesRecuentoPresentacion(10, 9, -1);
  Assert.AreEqual(42, Length(sFila));
  Assert.IsTrue(
    Pos(FormatearImportePresentacion(10), sFila) > 0);
  Assert.IsTrue(
    Pos(FormatearImportePresentacion(9), sFila) > 0);
  Assert.IsTrue(
    Pos(FormatearImportePresentacion(-1), sFila) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasArqueoTicketCatalogo);

end.
