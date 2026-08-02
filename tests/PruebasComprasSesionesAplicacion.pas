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
{    Verifica la orquestacion de materializacion sin VCL ni base de datos.      }
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

implementation

uses
  inLibComprasSesionesAplicacion,
  inLibComprasSesionesAplicacionIntf,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf;

type
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

initialization
  TDUnitX.RegisterTestFixture(TPruebasComprasSesionesAplicacion);

end.
