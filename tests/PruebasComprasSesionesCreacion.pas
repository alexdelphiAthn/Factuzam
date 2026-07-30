{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasComprasSesionesCreacion                                }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fija el comportamiento de las reglas de creacion extraidas de             }
{    TfrmMtoComprasSesiones.btnCrearClick. Sin VCL y sin BBDD: la              }
{    traduccion desde la cabecera se prueba con un TClientDataSet.             }
{******************************************************************************}
unit PruebasComprasSesionesCreacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasComprasSesionesCreacion = class
  public
    // --- guardas ---
    [Test]
    procedure Bloqueo_SinCabecera;
    [Test]
    procedure Bloqueo_SesionCerrada;
    [Test]
    procedure Bloqueo_SesionCerradaConEspaciosYMinusculas;
    [Test]
    procedure Bloqueo_SesionAbiertaNoBloquea;

    // --- series propuestas ---
    [Test]
    procedure Serie_UsaLaDeLaEmpresaCuandoExiste;
    [Test]
    procedure Serie_CaeALaDeLaSesionSiLaEmpresaNoTiene;
    [Test]
    procedure Serie_CaeALaDeLaSesionSiLaEmpresaTraeBlancos;

    // --- defectos del dialogo ---
    [Test]
    procedure Defectos_AlbaranSeProponeSiHayAlmacenAunqueElFlagEsteApagado;
    [Test]
    procedure Defectos_SinAlmacenRespetaElFlagDeAlbaran;
    [Test]
    procedure Defectos_TemporadaAusenteQuedaACero;
    [Test]
    procedure Defectos_AgrupacionSoloConFormatoDistribuido;

    // --- mapeos ---
    [Test]
    procedure Cabecera_TemporadaCeroSeLimpia;
    [Test]
    procedure Cabecera_TemporadaPositivaSeConserva;
    [Test]
    procedure Parametros_LlevanUsuarioSeriesYAgrupacion;

    // --- traduccion desde el dataset ---
    [Test]
    procedure Dataset_NilNoTieneCabecera;
    [Test]
    procedure Dataset_VacioNoTieneCabecera;
    [Test]
    procedure Dataset_LeeLaCabeceraCompleta;
    [Test]
    procedure Dataset_EscribeYLimpiaTemporada;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibComprasSesionesIntf,
  inLibComprasSesionesCreacion;

function EstadoBase: TEstadoSesionCreacion;
begin
  Result := Default(TEstadoSesionCreacion);
  Result.HayCabecera := True;
  Result.Estado := 'ABIERTA';
  Result.Serie := 'S1';
  Result.Numero := '000001';
  Result.Empresa := 'E1';
  Result.Tarifa := 'T1';
end;

function CrearCabecera: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('ESTADO_SES', ftString, 10);
  Result.FieldDefs.Add('SERIE_SES', ftString, 10);
  Result.FieldDefs.Add('NUMERO_SES', ftString, 10);
  Result.FieldDefs.Add('CODIGO_EMP_SES', ftString, 10);
  Result.FieldDefs.Add('CODIGO_ALM_SES', ftString, 10);
  Result.FieldDefs.Add('CODIGO_TAR_SES', ftString, 10);
  Result.FieldDefs.Add('ID_PV_TEMPORADA_SES', ftInteger);
  Result.FieldDefs.Add('ESGENERA_PEDIDO_SES', ftString, 1);
  Result.FieldDefs.Add('ESGENERA_ALBARAN_SES', ftString, 1);
  Result.FieldDefs.Add('ESFORMATO_DISTRIBUIDO_SES', ftString, 1);
  Result.FieldDefs.Add('REF_PRV_SES', ftString, 30);
  Result.CreateDataSet;
end;

{ --- guardas --- }

procedure TPruebasComprasSesionesCreacion.Bloqueo_SinCabecera;
var
  E: TEstadoSesionCreacion;
begin
  E := EstadoBase;
  E.HayCabecera := False;
  Assert.IsTrue(
    EvaluarBloqueoCreacionSesion(E) = mbcSinCabecera);
end;

procedure TPruebasComprasSesionesCreacion.Bloqueo_SesionCerrada;
var
  E: TEstadoSesionCreacion;
begin
  E := EstadoBase;
  E.Estado := 'CERRADA';
  Assert.IsTrue(
    EvaluarBloqueoCreacionSesion(E) = mbcYaMaterializada);
end;

procedure TPruebasComprasSesionesCreacion.
  Bloqueo_SesionCerradaConEspaciosYMinusculas;
var
  E: TEstadoSesionCreacion;
begin
  // El estado llega de un CHAR de BBDD: puede traer relleno.
  E := EstadoBase;
  E.Estado := '  cerrada ';
  Assert.IsTrue(
    EvaluarBloqueoCreacionSesion(E) = mbcYaMaterializada);
end;

procedure TPruebasComprasSesionesCreacion.
  Bloqueo_SesionAbiertaNoBloquea;
begin
  Assert.IsTrue(
    EvaluarBloqueoCreacionSesion(EstadoBase) = mbcNinguno);
end;

{ --- series propuestas --- }

procedure TPruebasComprasSesionesCreacion.
  Serie_UsaLaDeLaEmpresaCuandoExiste;
begin
  Assert.AreEqual('AB1', SerieCreacionPropuesta('AB1', 'S1'));
end;

procedure TPruebasComprasSesionesCreacion.
  Serie_CaeALaDeLaSesionSiLaEmpresaNoTiene;
begin
  Assert.AreEqual('S1', SerieCreacionPropuesta('', 'S1'));
end;

procedure TPruebasComprasSesionesCreacion.
  Serie_CaeALaDeLaSesionSiLaEmpresaTraeBlancos;
begin
  Assert.AreEqual('S1', SerieCreacionPropuesta('   ', 'S1'));
end;

{ --- defectos del dialogo --- }

procedure TPruebasComprasSesionesCreacion.
  Defectos_AlbaranSeProponeSiHayAlmacenAunqueElFlagEsteApagado;
var
  E: TEstadoSesionCreacion;
  D: TDefectosDialogoCreacion;
begin
  // Escenario de muestrarios: la cabecera trae almacen.
  E := EstadoBase;
  E.Almacen := 'ALM1';
  E.GeneraAlbaran := False;
  D := CalcularDefectosDialogoCreacion(E, 'AB1', 'PC1');
  Assert.IsTrue(D.GeneraAlbaran);
end;

procedure TPruebasComprasSesionesCreacion.
  Defectos_SinAlmacenRespetaElFlagDeAlbaran;
var
  E: TEstadoSesionCreacion;
begin
  E := EstadoBase;
  E.Almacen := '   ';
  E.GeneraAlbaran := False;
  Assert.IsFalse(
    CalcularDefectosDialogoCreacion(E, 'AB1', 'PC1').GeneraAlbaran);
  E.GeneraAlbaran := True;
  Assert.IsTrue(
    CalcularDefectosDialogoCreacion(E, 'AB1', 'PC1').GeneraAlbaran);
end;

procedure TPruebasComprasSesionesCreacion.
  Defectos_TemporadaAusenteQuedaACero;
var
  E: TEstadoSesionCreacion;
begin
  E := EstadoBase;
  E.TieneTemporada := False;
  E.Temporada := 77;
  Assert.AreEqual(0,
    CalcularDefectosDialogoCreacion(E, 'AB1', 'PC1').Temporada);
  E.TieneTemporada := True;
  Assert.AreEqual(77,
    CalcularDefectosDialogoCreacion(E, 'AB1', 'PC1').Temporada);
end;

procedure TPruebasComprasSesionesCreacion.
  Defectos_AgrupacionSoloConFormatoDistribuido;
var
  E: TEstadoSesionCreacion;
begin
  E := EstadoBase;
  E.FormatoDistribuido := False;
  Assert.IsFalse(CalcularDefectosDialogoCreacion(
    E, 'AB1', 'PC1').MostrarOpcionAgrupacion);
  E.FormatoDistribuido := True;
  Assert.IsTrue(CalcularDefectosDialogoCreacion(
    E, 'AB1', 'PC1').MostrarOpcionAgrupacion);
end;

{ --- mapeos --- }

procedure TPruebasComprasSesionesCreacion.
  Cabecera_TemporadaCeroSeLimpia;
var
  A: TAjustesCreacionElegidos;
  C: TCabeceraSesionActualizada;
begin
  A := Default(TAjustesCreacionElegidos);
  A.Temporada := 0;
  C := ComponerCabeceraActualizada(A);
  Assert.IsTrue(C.LimpiarTemporada);
end;

procedure TPruebasComprasSesionesCreacion.
  Cabecera_TemporadaPositivaSeConserva;
var
  A: TAjustesCreacionElegidos;
  C: TCabeceraSesionActualizada;
begin
  A := Default(TAjustesCreacionElegidos);
  A.Temporada := 5;
  A.Almacen := 'ALM1';
  A.Tarifa := 'T2';
  A.GeneraPedido := True;
  A.GeneraAlbaran := True;
  A.RefProveedor := 'REF-1';
  C := ComponerCabeceraActualizada(A);
  Assert.IsFalse(C.LimpiarTemporada);
  Assert.AreEqual(5, C.Temporada);
  Assert.AreEqual('ALM1', C.Almacen);
  Assert.AreEqual('T2', C.Tarifa);
  Assert.IsTrue(C.GeneraPedido);
  Assert.IsTrue(C.GeneraAlbaran);
  Assert.AreEqual('REF-1', C.RefProveedor);
end;

procedure TPruebasComprasSesionesCreacion.
  Parametros_LlevanUsuarioSeriesYAgrupacion;
var
  A: TAjustesCreacionElegidos;
  P: TParametrosMaterializacionSesion;
begin
  A := Default(TAjustesCreacionElegidos);
  A.SerieAlbaran := 'AB1';
  A.SeriePedido := 'PC1';
  A.UnDocumentoPorAlmacen := True;
  P := ComponerParametrosMaterializacion('USR', A);
  Assert.AreEqual('USR', P.Usuario);
  Assert.AreEqual('AB1', P.SerieAlbaran);
  Assert.AreEqual('PC1', P.SeriePedido);
  Assert.IsTrue(P.UnDocumentoPorAlmacen);
end;

{ --- traduccion desde el dataset --- }

procedure TPruebasComprasSesionesCreacion.
  Dataset_NilNoTieneCabecera;
begin
  Assert.IsFalse(LeerEstadoSesionCreacion(nil).HayCabecera);
end;

procedure TPruebasComprasSesionesCreacion.
  Dataset_VacioNoTieneCabecera;
var
  cds: TClientDataSet;
begin
  cds := CrearCabecera;
  try
    Assert.IsFalse(LeerEstadoSesionCreacion(cds).HayCabecera);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasComprasSesionesCreacion.
  Dataset_LeeLaCabeceraCompleta;
var
  cds: TClientDataSet;
  E: TEstadoSesionCreacion;
begin
  cds := CrearCabecera;
  try
    cds.Append;
    cds.FieldByName('ESTADO_SES').AsString := 'ABIERTA';
    cds.FieldByName('SERIE_SES').AsString := 'S1';
    cds.FieldByName('NUMERO_SES').AsString := '000007';
    cds.FieldByName('CODIGO_EMP_SES').AsString := 'E1';
    cds.FieldByName('CODIGO_ALM_SES').AsString := 'ALM1';
    cds.FieldByName('CODIGO_TAR_SES').AsString := 'T1';
    cds.FieldByName('ID_PV_TEMPORADA_SES').AsInteger := 8;
    cds.FieldByName('ESGENERA_PEDIDO_SES').AsString := 'S';
    cds.FieldByName('ESGENERA_ALBARAN_SES').AsString := 'N';
    cds.FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString := 'S';
    cds.FieldByName('REF_PRV_SES').AsString := 'ALB-99';
    cds.Post;
    E := LeerEstadoSesionCreacion(cds);
    Assert.IsTrue(E.HayCabecera);
    Assert.AreEqual('ABIERTA', E.Estado);
    Assert.AreEqual('S1', E.Serie);
    Assert.AreEqual('000007', E.Numero);
    Assert.AreEqual('E1', E.Empresa);
    Assert.AreEqual('ALM1', E.Almacen);
    Assert.AreEqual('T1', E.Tarifa);
    Assert.IsTrue(E.TieneTemporada);
    Assert.AreEqual(8, E.Temporada);
    Assert.IsTrue(E.GeneraPedido);
    Assert.IsFalse(E.GeneraAlbaran);
    Assert.IsTrue(E.FormatoDistribuido);
    Assert.AreEqual('ALB-99', E.RefProveedor);
    cds.Edit;
    cds.FieldByName('ID_PV_TEMPORADA_SES').Clear;
    cds.Post;
    E := LeerEstadoSesionCreacion(cds);
    Assert.IsFalse(E.TieneTemporada);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TPruebasComprasSesionesCreacion.
  Dataset_EscribeYLimpiaTemporada;
var
  cds: TClientDataSet;
  C: TCabeceraSesionActualizada;
begin
  cds := CrearCabecera;
  try
    cds.Append;
    cds.FieldByName('ID_PV_TEMPORADA_SES').AsInteger := 3;
    cds.Post;
    C := Default(TCabeceraSesionActualizada);
    C.Almacen := 'ALM2';
    C.Tarifa := 'T2';
    C.LimpiarTemporada := True;
    C.GeneraPedido := True;
    C.GeneraAlbaran := False;
    C.RefProveedor := 'REF-1';
    EscribirCabeceraSesionCreacion(cds, C);
    Assert.IsTrue(cds.FieldByName('ID_PV_TEMPORADA_SES').IsNull);
    Assert.AreEqual('ALM2',
      cds.FieldByName('CODIGO_ALM_SES').AsString);
    Assert.AreEqual('S',
      cds.FieldByName('ESGENERA_PEDIDO_SES').AsString);
    Assert.AreEqual('N',
      cds.FieldByName('ESGENERA_ALBARAN_SES').AsString);
    Assert.AreEqual('REF-1',
      cds.FieldByName('REF_PRV_SES').AsString);

    C.LimpiarTemporada := False;
    C.Temporada := 9;
    EscribirCabeceraSesionCreacion(cds, C);
    Assert.AreEqual(9,
      cds.FieldByName('ID_PV_TEMPORADA_SES').AsInteger);
  finally
    FreeAndNil(cds);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComprasSesionesCreacion);

end.
