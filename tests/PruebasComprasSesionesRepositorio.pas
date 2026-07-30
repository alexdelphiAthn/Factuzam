{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComprasSesionesRepositorio                             }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza los casos de uso de sesiones sin conexión a la BBDD.          }
{******************************************************************************}
unit PruebasComprasSesionesRepositorio;

interface

uses
  DUnitX.TestFramework,
  inLibComprasSesiones,
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf,
  DoblesComprasSesiones;

type
  [TestFixture]
  TPruebasComprasSesionesRepositorio = class
  private
    FContrato: IRepositorioComprasSesiones;
    FMaterializacion:
      IPersistenciaMaterializacionComprasSesiones;
    FPersistencia: TPersistenciaMaterializacionMemoria;
    FRepositorio: TRepositorioComprasSesionesMemoria;
    FReversion: IPersistenciaReversionComprasSesiones;
    FServicio: TServicioComprasSesiones;
    FUnidadTrabajo: TUnidadTrabajoMaterializacionMemoria;
    FUnidadTrabajoContrato: IUnidadTrabajoMaterializacion;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Liberar;
    [Test]
    procedure ResolverDuplicadoNormalizaEntradas;
    [Test]
    procedure ContratoLecturasAdmiteRepositorioFalso;
    [Test]
    procedure ContratoLecturasMaterializacionAdmiteRepositorioFalso;
    [Test]
    procedure CalcularPrecioVentaConservaFormula;
    [Test]
    procedure ValidarSesionDevuelveTodasLasIncidencias;
    [Test]
    procedure MaterializarDocumentoUnicoAcumulaResultado;
    [Test]
    procedure MaterializarRespetaTiposConfigurados;
    [Test]
    procedure MaterializarPorAlmacenUsaArticulosUnaVez;
    [Test]
    procedure MaterializarSinAlmacenesConservaCasoVacio;
    [Test]
    procedure ValidacionFallidaRevierteYRegistraError;
    [Test]
    procedure FalloTrasEscrituraRevierteTodaLaTanda;
    [Test]
    procedure ReintentoTrasFalloPuedeCompletar;
    [Test]
    procedure UnidadTrabajoConfirmaORevierteSoloLaPropia;
    [Test]
    procedure UnidadTrabajoReutilizaTransaccionActiva;
    [Test]
    procedure ReversionConfirmaUnaSolaUnidadTrabajo;
    [Test]
    procedure ReversionFallidaEjecutaRollback;
  end;

implementation

uses
  System.Classes, System.SysUtils,
  UniDataComprasSesionesUnidadTrabajo;

procedure TPruebasComprasSesionesRepositorio.Preparar;
var
  oConfiguracion: TConfiguracionMaterializacionSesion;
begin
  FRepositorio := TRepositorioComprasSesionesMemoria.Create;
  FContrato := FRepositorio;
  FPersistencia := TPersistenciaMaterializacionMemoria.Create;
  FMaterializacion := FPersistencia;
  FReversion := FPersistencia;
  FUnidadTrabajo := TUnidadTrabajoMaterializacionMemoria.Create;
  FUnidadTrabajoContrato := FUnidadTrabajo;
  oConfiguracion :=
    Default(TConfiguracionMaterializacionSesion);
  oConfiguracion.GeneraPedido := True;
  oConfiguracion.GeneraAlbaran := True;
  oConfiguracion.Empresa := 'EMP';
  oConfiguracion.AlmacenCabecera := 'ALM';
  FPersistencia.Configuracion := oConfiguracion;
  FServicio := TServicioComprasSesiones.Create(
    FContrato,
    FMaterializacion,
    FReversion,
    FUnidadTrabajoContrato);
end;

procedure TPruebasComprasSesionesRepositorio.Liberar;
begin
  FreeAndNil(FServicio);
  FUnidadTrabajoContrato := nil;
  FReversion := nil;
  FMaterializacion := nil;
  FContrato := nil;
  FUnidadTrabajo := nil;
  FPersistencia := nil;
  FRepositorio := nil;
end;

procedure TPruebasComprasSesionesRepositorio.
  ResolverDuplicadoNormalizaEntradas;
var
  oEsperado: TResolverDuplicadoSesion;
  oResultado: TResolverDuplicadoSesion;
begin
  oEsperado := Default(TResolverDuplicadoSesion);
  oEsperado.Encontrado := True;
  oEsperado.CodigoArt := 'ART-1';
  FRepositorio.Duplicado := oEsperado;
  oResultado := FServicio.ResolverDuplicado(
    '  ART-1  ',
    '  PRV-1  ',
    True,
    '  ART-PREF  ');
  Assert.IsTrue(oResultado.Encontrado);
  Assert.AreEqual('ART-1', oResultado.CodigoArt);
  Assert.AreEqual('ART-1', FRepositorio.CodigoBuscado);
  Assert.AreEqual('PRV-1', FRepositorio.CodigoProveedor);
  Assert.AreEqual(
    'ART-PREF',
    FRepositorio.CodigoArticuloPreferido);
  Assert.IsTrue(FRepositorio.SoloRefProveedor);
end;

procedure TPruebasComprasSesionesRepositorio.
  ContratoLecturasAdmiteRepositorioFalso;
var
  oDuplicado: TResolverDuplicadoSesion;
  oLecturas: IRepositorioLecturasComprasSesiones;
  oResultado: TResolverDuplicadoSesion;
begin
  oLecturas := FRepositorio;
  oDuplicado := Default(TResolverDuplicadoSesion);
  oDuplicado.Encontrado := True;
  oDuplicado.CodigoArt := 'ART-FALSO';
  FRepositorio.Duplicado := oDuplicado;
  oResultado := oLecturas.ResolverDuplicado(
    'ART-FALSO',
    'PRV',
    False,
    '');
  Assert.IsTrue(oResultado.Encontrado);
  Assert.AreEqual('ART-FALSO', oResultado.CodigoArt);
end;

procedure TPruebasComprasSesionesRepositorio.
  ContratoLecturasMaterializacionAdmiteRepositorioFalso;
var
  aAlmacenes: TArray<string>;
  oDoble: TLecturasMaterializacionComprasSesionesMemoria;
  oLecturas: ILecturasMaterializacionComprasSesiones;
begin
  oDoble :=
    TLecturasMaterializacionComprasSesionesMemoria.Create;
  SetLength(aAlmacenes, 2);
  aAlmacenes[0] := 'A1';
  aAlmacenes[1] := 'A2';
  oDoble.Almacenes := aAlmacenes;
  oLecturas := oDoble;
  aAlmacenes := oLecturas.ConsultarAlmacenes(
    'SES',
    '1',
    'A1');
  Assert.AreEqual(2, Integer(Length(aAlmacenes)));
  Assert.AreEqual('A2', aAlmacenes[1]);
end;

procedure TPruebasComprasSesionesRepositorio.
  CalcularPrecioVentaConservaFormula;
begin
  Assert.AreEqual(
    9.99,
    CalcularPrecioVenta(10, 100, 1, 0.01),
    0.0001);
  Assert.AreEqual(
    14.99,
    CalcularPrecioVenta(10, 120, 5, 0.01),
    0.0001);
  Assert.AreEqual(
    0.0,
    CalcularPrecioVenta(0, 100, 0, 0.01),
    0.0001);
end;

procedure TPruebasComprasSesionesRepositorio.
  ValidarSesionDevuelveTodasLasIncidencias;
var
  oIncidencias: TStringList;
  oValores: TIncidenciasSesionCompra;
begin
  SetLength(oValores, 2);
  oValores[0] := 'Falta proveedor';
  oValores[1] := 'Falta almacén';
  FRepositorio.Incidencias := oValores;
  oIncidencias := TStringList.Create;
  try
    Assert.IsFalse(
      FServicio.ValidarSesionDetallado(oIncidencias));
    Assert.AreEqual(2, oIncidencias.Count);
    Assert.AreEqual(
      'Falta proveedor',
      oIncidencias[0]);
    Assert.AreEqual(
      'Falta almacén',
      oIncidencias[1]);
  finally
    FreeAndNil(oIncidencias);
  end;
end;

procedure TPruebasComprasSesionesRepositorio.
  MaterializarDocumentoUnicoAcumulaResultado;
var
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  oParametros := Default(TParametrosMaterializacionSesion);
  oParametros.Usuario := 'PRUEBAS';
  oParametros.SeriePedido := 'PC';
  oParametros.SerieAlbaran := 'AC';
  Assert.IsTrue(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(1, FPersistencia.Articulos);
  Assert.AreEqual(1, FPersistencia.Pedidos);
  Assert.AreEqual(1, FPersistencia.Albaranes);
  Assert.AreEqual(1, FPersistencia.Cierres);
  Assert.AreEqual(
    2,
    Integer(Length(oResultado.Documentos)));
  Assert.AreEqual(
    'Albaran',
    oResultado.Documentos[0].Tipo);
  Assert.AreEqual(
    'Pedido',
    oResultado.Documentos[1].Tipo);
  Assert.AreEqual('PC', oResultado.SeriePedido);
  Assert.AreEqual('AC', oResultado.SerieAlbaran);
  Assert.AreEqual(1, FUnidadTrabajo.Confirmaciones);
  Assert.AreEqual(0, FUnidadTrabajo.Reversiones);
end;

procedure TPruebasComprasSesionesRepositorio.
  MaterializarRespetaTiposConfigurados;
var
  oConfiguracion: TConfiguracionMaterializacionSesion;
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  oConfiguracion := FPersistencia.Configuracion;
  oConfiguracion.GeneraAlbaran := False;
  FPersistencia.Configuracion := oConfiguracion;
  oParametros := Default(TParametrosMaterializacionSesion);
  Assert.IsTrue(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(
    1,
    Integer(Length(oResultado.Documentos)));
  Assert.AreEqual(
    'Pedido',
    oResultado.Documentos[0].Tipo);
  oConfiguracion.GeneraPedido := False;
  oConfiguracion.GeneraAlbaran := True;
  FPersistencia.Configuracion := oConfiguracion;
  Assert.IsTrue(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(
    1,
    Integer(Length(oResultado.Documentos)));
  Assert.AreEqual(
    'Albaran',
    oResultado.Documentos[0].Tipo);
end;

procedure TPruebasComprasSesionesRepositorio.
  MaterializarPorAlmacenUsaArticulosUnaVez;
var
  aAlmacenes: TArray<string>;
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  SetLength(aAlmacenes, 2);
  aAlmacenes[0] := 'A1';
  aAlmacenes[1] := 'A2';
  FPersistencia.Almacenes := aAlmacenes;
  oParametros := Default(TParametrosMaterializacionSesion);
  oParametros.Usuario := 'PRUEBAS';
  oParametros.UnDocumentoPorAlmacen := True;
  Assert.IsTrue(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(1, FPersistencia.Articulos);
  Assert.AreEqual(2, FPersistencia.Pedidos);
  Assert.AreEqual(2, FPersistencia.Albaranes);
  Assert.AreEqual(1, FPersistencia.Cierres);
  Assert.AreEqual(
    4,
    Integer(Length(oResultado.Documentos)));
  Assert.AreEqual(
    'AB-A1',
    oResultado.SerieAlbaran);
  Assert.AreEqual(
    'PC-A1',
    oResultado.SeriePedido);
end;

procedure TPruebasComprasSesionesRepositorio.
  MaterializarSinAlmacenesConservaCasoVacio;
var
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  oParametros := Default(TParametrosMaterializacionSesion);
  oParametros.UnDocumentoPorAlmacen := True;
  Assert.IsTrue(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(0, FPersistencia.Articulos);
  Assert.AreEqual(0, FPersistencia.Cierres);
  Assert.AreEqual(
    0,
    Integer(Length(oResultado.Documentos)));
  Assert.AreEqual(1, FUnidadTrabajo.Confirmaciones);
end;

procedure TPruebasComprasSesionesRepositorio.
  ValidacionFallidaRevierteYRegistraError;
var
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  FPersistencia.ValidaMaterializacion := False;
  FPersistencia.MensajeError := 'Sesión incompleta';
  oParametros := Default(TParametrosMaterializacionSesion);
  Assert.IsFalse(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(
    'Sesión incompleta',
    oResultado.MensajeError);
  Assert.AreEqual(0, FUnidadTrabajo.Confirmaciones);
  Assert.AreEqual(1, FUnidadTrabajo.Reversiones);
  Assert.AreEqual(1, FPersistencia.Errores);
end;

procedure TPruebasComprasSesionesRepositorio.
  FalloTrasEscrituraRevierteTodaLaTanda;
var
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  FPersistencia.FalloEn := 'ALBARAN';
  oParametros := Default(TParametrosMaterializacionSesion);
  oParametros.Usuario := 'PRUEBAS';
  Assert.IsFalse(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(1, FPersistencia.Articulos);
  Assert.AreEqual(1, FPersistencia.Pedidos);
  Assert.AreEqual(1, FPersistencia.Albaranes);
  Assert.AreEqual(0, FPersistencia.Cierres);
  Assert.AreEqual(1, FUnidadTrabajo.Reversiones);
  Assert.AreEqual(0, FUnidadTrabajo.Confirmaciones);
  Assert.AreEqual(
    1,
    Integer(Length(oResultado.Documentos)));
  Assert.AreEqual(
    'Pedido',
    oResultado.Documentos[0].Tipo);
  Assert.IsTrue(
    Pos('ALBARAN', oResultado.MensajeError) > 0);
end;

procedure TPruebasComprasSesionesRepositorio.
  ReintentoTrasFalloPuedeCompletar;
var
  oParametros: TParametrosMaterializacionSesion;
  oResultado: TResultadoMaterializacionSesion;
begin
  FPersistencia.FalloEn := 'CERRAR';
  oParametros := Default(TParametrosMaterializacionSesion);
  Assert.IsFalse(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  FPersistencia.FalloEn := '';
  Assert.IsTrue(
    FServicio.EjecutarMaterializacion(
      oParametros,
      oResultado));
  Assert.AreEqual(2, FUnidadTrabajo.Inicios);
  Assert.AreEqual(1, FUnidadTrabajo.Reversiones);
  Assert.AreEqual(1, FUnidadTrabajo.Confirmaciones);
end;

procedure TPruebasComprasSesionesRepositorio.
  UnidadTrabajoConfirmaORevierteSoloLaPropia;
var
  oControl: IControlTransaccionMaterializacion;
  oControlMemoria: TControlTransaccionMaterializacionMemoria;
  oUnidadTrabajo: IUnidadTrabajoMaterializacion;
begin
  oControlMemoria :=
    TControlTransaccionMaterializacionMemoria.Create;
  oControl := oControlMemoria;
  oUnidadTrabajo :=
    TUnidadTrabajoMaterializacionUniDAC.Create(oControl);
  oUnidadTrabajo.Iniciar;
  oUnidadTrabajo.Confirmar;
  Assert.AreEqual(1, oControlMemoria.Inicios);
  Assert.AreEqual(1, oControlMemoria.Confirmaciones);
  Assert.AreEqual(0, oControlMemoria.Reversiones);
  oUnidadTrabajo.Iniciar;
  oUnidadTrabajo.Revertir;
  Assert.AreEqual(2, oControlMemoria.Inicios);
  Assert.AreEqual(1, oControlMemoria.Confirmaciones);
  Assert.AreEqual(1, oControlMemoria.Reversiones);
end;

procedure TPruebasComprasSesionesRepositorio.
  UnidadTrabajoReutilizaTransaccionActiva;
var
  oControl: IControlTransaccionMaterializacion;
  oControlMemoria: TControlTransaccionMaterializacionMemoria;
  oUnidadTrabajo: IUnidadTrabajoMaterializacion;
begin
  oControlMemoria :=
    TControlTransaccionMaterializacionMemoria.Create;
  oControlMemoria.EstadoTransaccion := True;
  oControl := oControlMemoria;
  oUnidadTrabajo :=
    TUnidadTrabajoMaterializacionUniDAC.Create(oControl);
  oUnidadTrabajo.Iniciar;
  oUnidadTrabajo.Confirmar;
  Assert.AreEqual(0, oControlMemoria.Inicios);
  Assert.AreEqual(0, oControlMemoria.Confirmaciones);
  Assert.AreEqual(0, oControlMemoria.Reversiones);
  Assert.IsTrue(oControlMemoria.EstadoTransaccion);
end;

procedure TPruebasComprasSesionesRepositorio.
  ReversionConfirmaUnaSolaUnidadTrabajo;
var
  sError: string;
begin
  Assert.IsTrue(
    FServicio.RevertirMaterializacion(
      '  PRUEBAS  ',
      sError));
  Assert.AreEqual('', sError);
  Assert.AreEqual(1, FPersistencia.Reversiones);
  Assert.AreEqual(1, FUnidadTrabajo.Confirmaciones);
  Assert.AreEqual(0, FUnidadTrabajo.Reversiones);
end;

procedure TPruebasComprasSesionesRepositorio.
  ReversionFallidaEjecutaRollback;
var
  sError: string;
begin
  FPersistencia.FalloEn := 'REVERSION';
  Assert.IsFalse(
    FServicio.RevertirMaterializacion(
      'PRUEBAS',
      sError));
  Assert.IsTrue(Pos('REVERSION', sError) > 0);
  Assert.AreEqual(0, FUnidadTrabajo.Confirmaciones);
  Assert.AreEqual(1, FUnidadTrabajo.Reversiones);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasComprasSesionesRepositorio);

end.
