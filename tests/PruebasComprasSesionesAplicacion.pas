{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasComprasSesionesAplicacion                              }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica la orquestacion de materializacion sin VCL ni base de datos     }
{    y el nucleo de presentacion de la sesion de compra (busqueda              }
{    incremental de modelos y lectura de teclas del selector de tallaje).      }
{******************************************************************************}
unit PruebasComprasSesionesAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasComprasSesionesAplicacion = class
  public
    [Test]
    procedure SinCabeceraNoGuardaNiMaterializa;
    [Test]
    procedure IncidenciasDetienenElFlujoAntesDelDialogo;
    [Test]
    procedure CancelarDialogoNoActualizaLaCabecera;
    [Test]
    procedure ExitoActualizaMaterializaRefrescaYPresenta;
    [Test]
    procedure ErrorDeMaterializacionSePresentaSinRefrescar;
  end;

  [TestFixture]
  TPruebasPresentacionComprasSesiones = class
  public
    [Test]
    procedure TecleoRearmaElDebounceDeBusqueda;
    [Test]
    procedure SeleccionVaciaNoArmaResolucion;
    [Test]
    procedure SeleccionEntregaModeloYArticuloUnaSolaVez;
    [Test]
    procedure ConfirmacionDelMismoTextoRespetaLaSeleccion;
    [Test]
    procedure ConfirmacionDeOtroTextoDescartaElArticulo;
    [Test]
    procedure LaListaSeRecargaAlCambiarProveedorOAlCerrarseElCursor;
    [Test]
    procedure LaTeclaAbreElSelectorDeTallajeSoloSinCtrlNiAlt;
  end;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  inLibComprasSesionesAplicacion,
  inLibComprasSesionesAplicacionIntf,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPresentacion,
  inLibComprasSesionesPresentacionIntf;

type
  // Sustituye al TTimer del adaptador VCL: el nucleo solo decide cuando
  // hay que diferir, nunca como.
  TDoblePlanificadorDiferido = class(
    TInterfacedObject,
    IPlanificadorDiferido)
  private
    FRearmes: Integer;
    FCancelaciones: Integer;
    FArmado: Boolean;
  public
    procedure Rearmar;
    procedure Cancelar;
    function Armado: Boolean;
  end;

  TDobleMaterializacionCompraSesion = class(
    TInterfacedObject,
    IOperacionesMaterializacionCompraSesion,
    IVistaMaterializacionCompraSesion)
  private
    FEstado: TEstadoSesionCreacion;
    FEsValida: Boolean;
    FAceptaAjustes: Boolean;
    FMaterializa: Boolean;
    FGuardados: Integer;
    FActualizaciones: Integer;
    FMaterializaciones: Integer;
    FRefrescos: Integer;
    FResultadosMostrados: Integer;
    FErroresMostrados: Integer;
    FIncidenciasMostradas: Integer;
    FBloqueosMostrados: Integer;
    FSolicitudesAjustes: Integer;
  public
    constructor Create;
    function LeerEstado: TEstadoSesionCreacion;
    procedure GuardarEdicion;
    function NormalizarDuplicados(
      const AEstado: TEstadoSesionCreacion): Integer;
    function Validar(
      out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
    function CalcularDefectos(
      const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
    procedure ActualizarCabecera(
      const AAjustes: TAjustesCreacionElegidos);
    function Materializar(
      const AAjustes: TAjustesCreacionElegidos;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    procedure Refrescar;
    procedure Registrar(const ATexto: string);
    procedure MostrarBloqueo(AMotivo: TMotivoBloqueoCreacion);
    procedure InformarDuplicados(ACantidad: Integer);
    procedure MostrarIncidencias(
      const AIncidencias: TIncidenciasMaterializacionSesion);
    function SolicitarAjustes(
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean;
    procedure MostrarResultado(
      const AResultado: TResultadoMaterializacionSesion);
    procedure MostrarError(const AMensaje: string);
  end;

procedure TDoblePlanificadorDiferido.Rearmar;
begin
  Inc(FRearmes);
  FArmado := True;
end;

procedure TDoblePlanificadorDiferido.Cancelar;
begin
  Inc(FCancelaciones);
  FArmado := False;
end;

function TDoblePlanificadorDiferido.Armado: Boolean;
begin
  Result := FArmado;
end;

constructor TDobleMaterializacionCompraSesion.Create;
begin
  inherited Create;
  FEstado := Default(TEstadoSesionCreacion);
  FEstado.HayCabecera := True;
  FEstado.Estado := 'ABIERTA';
  FEstado.Serie := 'S1';
  FEstado.Numero := '1';
  FEsValida := True;
  FAceptaAjustes := True;
  FMaterializa := True;
end;

function TDobleMaterializacionCompraSesion.LeerEstado:
  TEstadoSesionCreacion;
begin
  Result := FEstado;
end;

procedure TDobleMaterializacionCompraSesion.GuardarEdicion;
begin
  Inc(FGuardados);
end;

function TDobleMaterializacionCompraSesion.NormalizarDuplicados(
  const AEstado: TEstadoSesionCreacion): Integer;
begin
  Result := 0;
end;

function TDobleMaterializacionCompraSesion.Validar(
  out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
begin
  Result := FEsValida;
  if FEsValida then
    SetLength(AIncidencias, 0)
  else
    AIncidencias := ['Incidencia simulada'];
end;

function TDobleMaterializacionCompraSesion.CalcularDefectos(
  const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
begin
  Result := Default(TDefectosDialogoCreacion);
end;

procedure TDobleMaterializacionCompraSesion.ActualizarCabecera(
  const AAjustes: TAjustesCreacionElegidos);
begin
  Inc(FActualizaciones);
end;

function TDobleMaterializacionCompraSesion.Materializar(
  const AAjustes: TAjustesCreacionElegidos;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
begin
  Inc(FMaterializaciones);
  AResultado := Default(TResultadoMaterializacionSesion);
  AResultado.MensajeError := 'Error simulado';
  Result := FMaterializa;
end;

procedure TDobleMaterializacionCompraSesion.Refrescar;
begin
  Inc(FRefrescos);
end;

procedure TDobleMaterializacionCompraSesion.Registrar(
  const ATexto: string);
begin
end;

procedure TDobleMaterializacionCompraSesion.MostrarBloqueo(
  AMotivo: TMotivoBloqueoCreacion);
begin
  Inc(FBloqueosMostrados);
end;

procedure TDobleMaterializacionCompraSesion.InformarDuplicados(
  ACantidad: Integer);
begin
end;

procedure TDobleMaterializacionCompraSesion.MostrarIncidencias(
  const AIncidencias: TIncidenciasMaterializacionSesion);
begin
  Inc(FIncidenciasMostradas);
end;

function TDobleMaterializacionCompraSesion.SolicitarAjustes(
  const AEstado: TEstadoSesionCreacion;
  const ADefectos: TDefectosDialogoCreacion;
  out AAjustes: TAjustesCreacionElegidos): Boolean;
begin
  Inc(FSolicitudesAjustes);
  AAjustes := Default(TAjustesCreacionElegidos);
  Result := FAceptaAjustes;
end;

procedure TDobleMaterializacionCompraSesion.MostrarResultado(
  const AResultado: TResultadoMaterializacionSesion);
begin
  Inc(FResultadosMostrados);
end;

procedure TDobleMaterializacionCompraSesion.MostrarError(
  const AMensaje: string);
begin
  Inc(FErroresMostrados);
end;

procedure TPruebasComprasSesionesAplicacion.SinCabeceraNoGuardaNiMaterializa;
var
  Aplicacion: IAplicacionMaterializacionCompraSesion;
  Doble: TDobleMaterializacionCompraSesion;
begin
  Doble := TDobleMaterializacionCompraSesion.Create;
  Doble.FEstado.HayCabecera := False;
  Aplicacion := CrearAplicacionMaterializacionCompraSesion(Doble, Doble);
  Aplicacion.Ejecutar;
  Assert.AreEqual(1, Doble.FBloqueosMostrados);
  Assert.AreEqual(0, Doble.FGuardados);
  Assert.AreEqual(0, Doble.FMaterializaciones);
end;

procedure TPruebasComprasSesionesAplicacion.
  IncidenciasDetienenElFlujoAntesDelDialogo;
var
  Aplicacion: IAplicacionMaterializacionCompraSesion;
  Doble: TDobleMaterializacionCompraSesion;
begin
  Doble := TDobleMaterializacionCompraSesion.Create;
  Doble.FEsValida := False;
  Aplicacion := CrearAplicacionMaterializacionCompraSesion(Doble, Doble);
  Aplicacion.Ejecutar;
  Assert.AreEqual(1, Doble.FGuardados);
  Assert.AreEqual(1, Doble.FIncidenciasMostradas);
  Assert.AreEqual(0, Doble.FSolicitudesAjustes);
  Assert.AreEqual(0, Doble.FMaterializaciones);
end;

procedure TPruebasComprasSesionesAplicacion.
  CancelarDialogoNoActualizaLaCabecera;
var
  Aplicacion: IAplicacionMaterializacionCompraSesion;
  Doble: TDobleMaterializacionCompraSesion;
begin
  Doble := TDobleMaterializacionCompraSesion.Create;
  Doble.FAceptaAjustes := False;
  Aplicacion := CrearAplicacionMaterializacionCompraSesion(Doble, Doble);
  Aplicacion.Ejecutar;
  Assert.AreEqual(1, Doble.FSolicitudesAjustes);
  Assert.AreEqual(0, Doble.FActualizaciones);
  Assert.AreEqual(0, Doble.FMaterializaciones);
end;

procedure TPruebasComprasSesionesAplicacion.
  ExitoActualizaMaterializaRefrescaYPresenta;
var
  Aplicacion: IAplicacionMaterializacionCompraSesion;
  Doble: TDobleMaterializacionCompraSesion;
begin
  Doble := TDobleMaterializacionCompraSesion.Create;
  Aplicacion := CrearAplicacionMaterializacionCompraSesion(Doble, Doble);
  Aplicacion.Ejecutar;
  Assert.AreEqual(1, Doble.FActualizaciones);
  Assert.AreEqual(1, Doble.FMaterializaciones);
  Assert.AreEqual(1, Doble.FRefrescos);
  Assert.AreEqual(1, Doble.FResultadosMostrados);
  Assert.AreEqual(0, Doble.FErroresMostrados);
end;

procedure TPruebasComprasSesionesAplicacion.
  ErrorDeMaterializacionSePresentaSinRefrescar;
var
  Aplicacion: IAplicacionMaterializacionCompraSesion;
  Doble: TDobleMaterializacionCompraSesion;
begin
  Doble := TDobleMaterializacionCompraSesion.Create;
  Doble.FMaterializa := False;
  Aplicacion := CrearAplicacionMaterializacionCompraSesion(Doble, Doble);
  Aplicacion.Ejecutar;
  Assert.AreEqual(1, Doble.FErroresMostrados);
  Assert.AreEqual(0, Doble.FRefrescos);
  Assert.AreEqual(0, Doble.FResultadosMostrados);
end;

{ TPruebasPresentacionComprasSesiones }

procedure TPruebasPresentacionComprasSesiones.
  TecleoRearmaElDebounceDeBusqueda;
var
  Busqueda: TDoblePlanificadorDiferido;
  Resolucion: TDoblePlanificadorDiferido;
  Nucleo: TNucleoBusquedaModeloSesion;
begin
  Busqueda := TDoblePlanificadorDiferido.Create;
  Resolucion := TDoblePlanificadorDiferido.Create;
  Nucleo := TNucleoBusquedaModeloSesion.Create(Busqueda, Resolucion);
  try
    Nucleo.RegistrarTecleo;
    Nucleo.RegistrarTecleo;
    Assert.AreEqual(2, Busqueda.FRearmes);
    Assert.AreEqual(0, Resolucion.FRearmes);
  finally
    FreeAndNil(Nucleo);
  end;
end;

procedure TPruebasPresentacionComprasSesiones.SeleccionVaciaNoArmaResolucion;
var
  Busqueda: TDoblePlanificadorDiferido;
  Resolucion: TDoblePlanificadorDiferido;
  Nucleo: TNucleoBusquedaModeloSesion;
  sModelo: string;
  sArticulo: string;
begin
  Busqueda := TDoblePlanificadorDiferido.Create;
  Resolucion := TDoblePlanificadorDiferido.Create;
  Nucleo := TNucleoBusquedaModeloSesion.Create(Busqueda, Resolucion);
  try
    Nucleo.RegistrarSeleccion('   ', 'ART');
    Assert.AreEqual(0, Resolucion.FRearmes);
    Assert.IsFalse(Nucleo.TomarPendiente(sModelo, sArticulo));
    Assert.AreEqual('', sModelo);
  finally
    FreeAndNil(Nucleo);
  end;
end;

procedure TPruebasPresentacionComprasSesiones.
  SeleccionEntregaModeloYArticuloUnaSolaVez;
var
  Busqueda: TDoblePlanificadorDiferido;
  Resolucion: TDoblePlanificadorDiferido;
  Nucleo: TNucleoBusquedaModeloSesion;
  sModelo: string;
  sArticulo: string;
begin
  Busqueda := TDoblePlanificadorDiferido.Create;
  Resolucion := TDoblePlanificadorDiferido.Create;
  Nucleo := TNucleoBusquedaModeloSesion.Create(Busqueda, Resolucion);
  try
    Nucleo.RegistrarSeleccion('MOD-1', 'ART-1');
    Assert.AreEqual(1, Resolucion.FRearmes);
    Assert.IsTrue(Nucleo.TomarPendiente(sModelo, sArticulo));
    Assert.AreEqual('MOD-1', sModelo);
    Assert.AreEqual('ART-1', sArticulo);
    // Consumida: una segunda resolucion no repite el trabajo.
    Assert.IsFalse(Nucleo.TomarPendiente(sModelo, sArticulo));
  finally
    FreeAndNil(Nucleo);
  end;
end;

procedure TPruebasPresentacionComprasSesiones.
  ConfirmacionDelMismoTextoRespetaLaSeleccion;
var
  Busqueda: TDoblePlanificadorDiferido;
  Resolucion: TDoblePlanificadorDiferido;
  Nucleo: TNucleoBusquedaModeloSesion;
  sModelo: string;
  sArticulo: string;
begin
  Busqueda := TDoblePlanificadorDiferido.Create;
  Resolucion := TDoblePlanificadorDiferido.Create;
  Nucleo := TNucleoBusquedaModeloSesion.Create(Busqueda, Resolucion);
  try
    Nucleo.RegistrarSeleccion('MOD-1', 'ART-1');
    Resolucion.FArmado := True;
    // El desplegable ya armo esta resolucion y lleva el codigo de
    // articulo preferido: la confirmacion no debe pisarlo.
    Nucleo.RegistrarConfirmacion('MOD-1');
    Assert.AreEqual(1, Resolucion.FRearmes);
    Assert.IsTrue(Nucleo.TomarPendiente(sModelo, sArticulo));
    Assert.AreEqual('ART-1', sArticulo);
  finally
    FreeAndNil(Nucleo);
  end;
end;

procedure TPruebasPresentacionComprasSesiones.
  ConfirmacionDeOtroTextoDescartaElArticulo;
var
  Busqueda: TDoblePlanificadorDiferido;
  Resolucion: TDoblePlanificadorDiferido;
  Nucleo: TNucleoBusquedaModeloSesion;
  sModelo: string;
  sArticulo: string;
begin
  Busqueda := TDoblePlanificadorDiferido.Create;
  Resolucion := TDoblePlanificadorDiferido.Create;
  Nucleo := TNucleoBusquedaModeloSesion.Create(Busqueda, Resolucion);
  try
    Nucleo.RegistrarSeleccion('MOD-1', 'ART-1');
    Resolucion.FArmado := True;
    Nucleo.RegistrarConfirmacion('  MOD-2  ');
    Assert.AreEqual(2, Resolucion.FRearmes);
    Assert.IsTrue(Nucleo.TomarPendiente(sModelo, sArticulo));
    Assert.AreEqual('MOD-2', sModelo);
    Assert.AreEqual('', sArticulo);
  finally
    FreeAndNil(Nucleo);
  end;
end;

procedure TPruebasPresentacionComprasSesiones.
  LaListaSeRecargaAlCambiarProveedorOAlCerrarseElCursor;
var
  Busqueda: TDoblePlanificadorDiferido;
  Resolucion: TDoblePlanificadorDiferido;
  Nucleo: TNucleoBusquedaModeloSesion;
begin
  Busqueda := TDoblePlanificadorDiferido.Create;
  Resolucion := TDoblePlanificadorDiferido.Create;
  Nucleo := TNucleoBusquedaModeloSesion.Create(Busqueda, Resolucion);
  try
    // Sesion sin proveedor: la primera carga siempre se hace.
    Assert.IsTrue(Nucleo.DebeRecargarLista('', True));
    Nucleo.MarcarListaCargada('');
    Assert.IsFalse(Nucleo.DebeRecargarLista('', True));
    // Cursor cerrado tras un ResetForm.
    Assert.IsTrue(Nucleo.DebeRecargarLista('', False));
    Assert.IsTrue(Nucleo.DebeRecargarLista('PRV1', True));
    Nucleo.MarcarListaCargada('PRV1');
    Assert.AreEqual('PRV1', Nucleo.ProveedorCargado);
    Assert.IsFalse(Nucleo.DebeRecargarLista('PRV1', True));
  finally
    FreeAndNil(Nucleo);
  end;
end;

procedure TPruebasPresentacionComprasSesiones.
  LaTeclaAbreElSelectorDeTallajeSoloSinCtrlNiAlt;
begin
  Assert.AreEqual('A', TextoBusquedaTallaje(Ord('A'), []));
  Assert.AreEqual('7', TextoBusquedaTallaje(Ord('7'), []));
  Assert.AreEqual('3', TextoBusquedaTallaje(VK_NUMPAD3, []));
  Assert.AreEqual(' ', TextoBusquedaTallaje(VK_SPACE, []));
  Assert.AreEqual('', TextoBusquedaTallaje(Ord('A'), [ssCtrl]));
  Assert.AreEqual('', TextoBusquedaTallaje(Ord('A'), [ssAlt]));
  Assert.AreEqual('', TextoBusquedaTallaje(VK_RETURN, []));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComprasSesionesAplicacion);
  TDUnitX.RegisterTestFixture(TPruebasPresentacionComprasSesiones);

end.
