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
    [Test]
    procedure Contexto_SeConstruyeConCapacidadesSinRaizVisual;
    [Test]
    procedure Contexto_DependenciaAusenteFallaAlPrepararlo;
  end;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  inLibArticulosGuardado,
  inLibArticulosGuardadoIntf,
  inLibArticulosInyeccion,
  inLibArticulosPropiedadesPersistenciaIntf,
  inLibArticulosVariacionesIntf,
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
  TPropiedadesArticuloFalsas = class(
    TInterfacedObject,
    ILectorPropiedadesArticulo,
    IEscritorPropiedadesArticulo)
  public
    function ListarDisponibles: TArray<TDefinicionPropiedadArticulo>;
    function ListarAsignadas(
      const ACodigoArticulo: string
    ): TArray<TDefinicionPropiedadArticulo>;
    function ListarFamilia(
      const ACodigoFamilia: string
    ): TArray<TDefinicionPropiedadArticulo>;
    function Buscar(
      const ACodigoPropiedad: string;
      out APropiedad: TDefinicionPropiedadArticulo): Boolean;
    function ListarOpciones(
      const ACodigoPropiedad: string
    ): TArray<TOpcionPropiedadArticulo>;
    function ListarUnidades(
      const ACodigoArticulo, ANivel: string
    ): TArray<TUnidadPropiedadArticulo>;
    function ListarValoresUnidades(
      const ACodigoArticulo, ACodigoPropiedad: string
    ): TArray<TValorUnidadPropiedadArticulo>;
    procedure GuardarValor(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string;
      AIdValor: Integer;
      const AValorLibre, AUsuario: string);
    procedure EliminarPropiedad(
      const ACodigoArticulo, ACodigoPropiedad: string);
    procedure EliminarValorUnidad(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string);
  end;
  TArticulosVariacionesFalsas = class(
    TInterfacedObject,
    IArticulosVariaciones)
  public
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function CrearGestor(
      APanelAtributos: TScrollBox;
      const AUsuario: string): IGestorArticulosVariaciones;
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

function TPropiedadesArticuloFalsas.ListarDisponibles:
  TArray<TDefinicionPropiedadArticulo>;
begin
  SetLength(Result, 0);
end;

function TPropiedadesArticuloFalsas.ListarAsignadas(
  const ACodigoArticulo: string
): TArray<TDefinicionPropiedadArticulo>;
begin
  SetLength(Result, 0);
end;

function TPropiedadesArticuloFalsas.ListarFamilia(
  const ACodigoFamilia: string
): TArray<TDefinicionPropiedadArticulo>;
begin
  SetLength(Result, 0);
end;

function TPropiedadesArticuloFalsas.Buscar(
  const ACodigoPropiedad: string;
  out APropiedad: TDefinicionPropiedadArticulo): Boolean;
begin
  APropiedad := Default(TDefinicionPropiedadArticulo);
  Result := False;
end;

function TPropiedadesArticuloFalsas.ListarOpciones(
  const ACodigoPropiedad: string
): TArray<TOpcionPropiedadArticulo>;
begin
  SetLength(Result, 0);
end;

function TPropiedadesArticuloFalsas.ListarUnidades(
  const ACodigoArticulo, ANivel: string
): TArray<TUnidadPropiedadArticulo>;
begin
  SetLength(Result, 0);
end;

function TPropiedadesArticuloFalsas.ListarValoresUnidades(
  const ACodigoArticulo, ACodigoPropiedad: string
): TArray<TValorUnidadPropiedadArticulo>;
begin
  SetLength(Result, 0);
end;

procedure TPropiedadesArticuloFalsas.GuardarValor(
  const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string;
  AIdValor: Integer;
  const AValorLibre, AUsuario: string);
begin
end;

procedure TPropiedadesArticuloFalsas.EliminarPropiedad(
  const ACodigoArticulo, ACodigoPropiedad: string);
begin
end;

procedure TPropiedadesArticuloFalsas.EliminarValorUnidad(
  const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string);
begin
end;

procedure TArticulosVariacionesFalsas.AsegurarSkuSinVariaciones(
  const ACodigoArticulo, AUsuario: string);
begin
end;

procedure TArticulosVariacionesFalsas.AsegurarSkuActivo(
  const ACodigoArticulo, AUsuario: string);
begin
end;

function TArticulosVariacionesFalsas.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := False;
end;

function TArticulosVariacionesFalsas.CrearGestor(
  APanelAtributos: TScrollBox;
  const AUsuario: string): IGestorArticulosVariaciones;
begin
  Result := nil;
end;

function CrearContextoInyeccionArticulos: TContextoDependenciasArticulos;
var
  oPropiedades: TPropiedadesArticuloFalsas;
  ServiciosPropiedades: TServiciosPropiedadesArticulo;
begin
  oPropiedades := TPropiedadesArticuloFalsas.Create;
  ServiciosPropiedades.Lectura := oPropiedades;
  ServiciosPropiedades.Escritura := oPropiedades;
  Result := TContextoDependenciasArticulos.Crear(
    CrearCreadorGuardadoArticulo,
    ServiciosPropiedades,
    TArticulosVariacionesFalsas.Create);
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

procedure TPruebasArticulosGuardado.
  Contexto_SeConstruyeConCapacidadesSinRaizVisual;
var
  Contexto: TContextoDependenciasArticulos;
begin
  Contexto := CrearContextoInyeccionArticulos;
  try
    Assert.IsTrue(Assigned(Contexto.Guardado));
    Assert.IsTrue(Assigned(Contexto.Propiedades.Lectura));
    Assert.IsTrue(Assigned(Contexto.Propiedades.Escritura));
    Assert.IsTrue(Assigned(Contexto.Variaciones));
  finally
    Contexto.Liberar;
  end;
end;

procedure TPruebasArticulosGuardado.
  Contexto_DependenciaAusenteFallaAlPrepararlo;
var
  Contexto: TContextoDependenciasArticulos;
begin
  Contexto := CrearContextoInyeccionArticulos;
  try
    Contexto.Propiedades.Escritura := nil;
    Assert.WillRaise(
      procedure
      begin
        Contexto.Validar;
      end,
      EArgumentNilException);
  finally
    Contexto.Liberar;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosGuardado);

end.
