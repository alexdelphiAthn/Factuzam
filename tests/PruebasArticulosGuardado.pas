{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasArticulosGuardado                                      }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica el orden y las guardas del guardado coordinado de articulos.     }
{******************************************************************************}
unit PruebasArticulosGuardado;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosGuardado = class
  public
    [Test]
    procedure ValidacionDetieneTodosLosGuardados;
    [Test]
    procedure ErrorPropiedadesDetieneDatasetsYVariaciones;
    [Test]
    procedure ErrorVariacionesOcurreDespuesDeGuardarDatasets;
    [Test]
    procedure ExitoEjecutaTodasLasCapacidades;
    [Test]
    procedure AdaptadorDelegaCadaCapacidadEnSuCallback;
    [Test]
    procedure AdaptadorPropagaMensajeDeErrorDeVariaciones;
  end;

implementation

uses
  inLibArticulosGuardado,
  inLibArticulosGuardadoIntf,
  inMtoArticulosGuardadoVcl;

type
  TOperacionesGuardadoArticuloFalsas = class(
    TInterfacedObject,
    IOperacionesGuardadoArticulo)
  private
    FErrorValidacion: string;
    FPropiedadesCorrectas: Boolean;
    FVariacionesCorrectas: Boolean;
    FGuardadosPropiedades: Integer;
    FGuardadosEdiciones: Integer;
    FGuardadosVariaciones: Integer;
  public
    constructor Create;
    function ValidarPropiedades: string;
    function GuardarPropiedades(out AMensajeError: string): Boolean;
    procedure GuardarEdicionesPendientes;
    function GuardarVariaciones(out AMensajeError: string): Boolean;
  end;

constructor TOperacionesGuardadoArticuloFalsas.Create;
begin
  inherited Create;
  FPropiedadesCorrectas := True;
  FVariacionesCorrectas := True;
end;

function TOperacionesGuardadoArticuloFalsas.ValidarPropiedades: string;
begin
  Result := FErrorValidacion;
end;

function TOperacionesGuardadoArticuloFalsas.GuardarPropiedades(
  out AMensajeError: string): Boolean;
begin
  Inc(FGuardadosPropiedades);
  AMensajeError := 'Error de propiedades';
  Result := FPropiedadesCorrectas;
end;

procedure TOperacionesGuardadoArticuloFalsas.GuardarEdicionesPendientes;
begin
  Inc(FGuardadosEdiciones);
end;

function TOperacionesGuardadoArticuloFalsas.GuardarVariaciones(
  out AMensajeError: string): Boolean;
begin
  Inc(FGuardadosVariaciones);
  AMensajeError := 'Error de variaciones';
  Result := FVariacionesCorrectas;
end;

procedure TPruebasArticulosGuardado.ValidacionDetieneTodosLosGuardados;
var
  Aplicacion: IAplicacionGuardadoArticulo;
  Operaciones: TOperacionesGuardadoArticuloFalsas;
  Resultado: TResultadoGuardadoArticulo;
begin
  Operaciones := TOperacionesGuardadoArticuloFalsas.Create;
  Operaciones.FErrorValidacion := 'Falta TEMPORADA';
  Aplicacion := CrearAplicacionGuardadoArticulo(Operaciones);
  Resultado := Aplicacion.Ejecutar;
  Assert.AreEqual(Ord(egaRevisionPropiedades), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FGuardadosPropiedades);
  Assert.AreEqual(0, Operaciones.FGuardadosEdiciones);
  Assert.AreEqual(0, Operaciones.FGuardadosVariaciones);
end;

procedure TPruebasArticulosGuardado.
  ErrorPropiedadesDetieneDatasetsYVariaciones;
var
  Aplicacion: IAplicacionGuardadoArticulo;
  Operaciones: TOperacionesGuardadoArticuloFalsas;
  Resultado: TResultadoGuardadoArticulo;
begin
  Operaciones := TOperacionesGuardadoArticuloFalsas.Create;
  Operaciones.FPropiedadesCorrectas := False;
  Aplicacion := CrearAplicacionGuardadoArticulo(Operaciones);
  Resultado := Aplicacion.Ejecutar;
  Assert.AreEqual(Ord(egaGuardadoPropiedades), Ord(Resultado.Error));
  Assert.AreEqual(1, Operaciones.FGuardadosPropiedades);
  Assert.AreEqual(0, Operaciones.FGuardadosEdiciones);
  Assert.AreEqual(0, Operaciones.FGuardadosVariaciones);
end;

procedure TPruebasArticulosGuardado.
  ErrorVariacionesOcurreDespuesDeGuardarDatasets;
var
  Aplicacion: IAplicacionGuardadoArticulo;
  Operaciones: TOperacionesGuardadoArticuloFalsas;
  Resultado: TResultadoGuardadoArticulo;
begin
  Operaciones := TOperacionesGuardadoArticuloFalsas.Create;
  Operaciones.FVariacionesCorrectas := False;
  Aplicacion := CrearAplicacionGuardadoArticulo(Operaciones);
  Resultado := Aplicacion.Ejecutar;
  Assert.AreEqual(Ord(egaGuardadoVariaciones), Ord(Resultado.Error));
  Assert.AreEqual(1, Operaciones.FGuardadosPropiedades);
  Assert.AreEqual(1, Operaciones.FGuardadosEdiciones);
  Assert.AreEqual(1, Operaciones.FGuardadosVariaciones);
end;

procedure TPruebasArticulosGuardado.ExitoEjecutaTodasLasCapacidades;
var
  Aplicacion: IAplicacionGuardadoArticulo;
  Operaciones: TOperacionesGuardadoArticuloFalsas;
  Resultado: TResultadoGuardadoArticulo;
begin
  Operaciones := TOperacionesGuardadoArticuloFalsas.Create;
  Aplicacion := CrearAplicacionGuardadoArticulo(Operaciones);
  Resultado := Aplicacion.Ejecutar;
  Assert.AreEqual(Ord(egaNinguno), Ord(Resultado.Error));
  Assert.AreEqual(1, Operaciones.FGuardadosPropiedades);
  Assert.AreEqual(1, Operaciones.FGuardadosEdiciones);
  Assert.AreEqual(1, Operaciones.FGuardadosVariaciones);
end;

procedure TPruebasArticulosGuardado.
  AdaptadorDelegaCadaCapacidadEnSuCallback;
// El adaptador VCL no recibe el formulario: solo cuatro callbacks. Se
// prueba sin VCL ni BBDD comprobando que cada puerto llama al suyo.
var
  oCallbacks: TCallbacksGuardadoArticulo;
  oOperaciones: IOperacionesGuardadoArticulo;
  iValidaciones, iPropiedades, iEdiciones, iVariaciones: Integer;
  sMensaje: string;
begin
  iValidaciones := 0;
  iPropiedades := 0;
  iEdiciones := 0;
  iVariaciones := 0;
  oCallbacks := Default(TCallbacksGuardadoArticulo);
  oCallbacks.ValidarPropiedades :=
    function: string
    begin
      Inc(iValidaciones);
      Result := 'Falta TEMPORADA';
    end;
  oCallbacks.GuardarPropiedades :=
    function(out AMensajeError: string): Boolean
    begin
      Inc(iPropiedades);
      AMensajeError := '';
      Result := True;
    end;
  oCallbacks.GuardarEdicionesPendientes :=
    procedure
    begin
      Inc(iEdiciones);
    end;
  oCallbacks.GuardarVariaciones :=
    function(out AMensajeError: string): Boolean
    begin
      Inc(iVariaciones);
      AMensajeError := '';
      Result := True;
    end;
  oOperaciones := TAdaptadorGuardadoArticuloVcl.Create(oCallbacks);
  Assert.AreEqual('Falta TEMPORADA', oOperaciones.ValidarPropiedades);
  Assert.IsTrue(oOperaciones.GuardarPropiedades(sMensaje));
  oOperaciones.GuardarEdicionesPendientes;
  Assert.IsTrue(oOperaciones.GuardarVariaciones(sMensaje));
  Assert.AreEqual(1, iValidaciones);
  Assert.AreEqual(1, iPropiedades);
  Assert.AreEqual(1, iEdiciones);
  Assert.AreEqual(1, iVariaciones);
end;

procedure TPruebasArticulosGuardado.
  AdaptadorPropagaMensajeDeErrorDeVariaciones;
var
  oCallbacks: TCallbacksGuardadoArticulo;
  oOperaciones: IOperacionesGuardadoArticulo;
  oAplicacion: IAplicacionGuardadoArticulo;
  oResultado: TResultadoGuardadoArticulo;
begin
  oCallbacks := Default(TCallbacksGuardadoArticulo);
  oCallbacks.ValidarPropiedades :=
    function: string
    begin
      Result := '';
    end;
  oCallbacks.GuardarPropiedades :=
    function(out AMensajeError: string): Boolean
    begin
      AMensajeError := '';
      Result := True;
    end;
  oCallbacks.GuardarEdicionesPendientes :=
    procedure
    begin
    end;
  oCallbacks.GuardarVariaciones :=
    function(out AMensajeError: string): Boolean
    begin
      AMensajeError := 'Atributo repetido';
      Result := False;
    end;
  oOperaciones := TAdaptadorGuardadoArticuloVcl.Create(oCallbacks);
  oAplicacion := CrearAplicacionGuardadoArticulo(oOperaciones);
  oResultado := oAplicacion.Ejecutar;
  Assert.AreEqual(Ord(egaGuardadoVariaciones), Ord(oResultado.Error));
  Assert.AreEqual('Atributo repetido', oResultado.Mensaje);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosGuardado);

end.
