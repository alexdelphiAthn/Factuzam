{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasMovimientosAlmacenAplicacion                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prueba carga parcial y escritura atómica sin VCL ni UniDAC.               }
{******************************************************************************}
unit PruebasMovimientosAlmacenAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasMovimientosAlmacenAplicacion = class
  public
    [Test]
    procedure CargaParcial_CancelaYFinalizaLector;
    [Test]
    procedure GeneracionCompleta_ConfirmaUnidadTrabajo;
    [Test]
    procedure GeneracionCancelada_RevierteMovimientosParciales;
    [Test]
    procedure ErrorDeEscritura_RevierteUnidadTrabajo;
  end;

implementation

uses
  System.SysUtils,
  inLibMovimientosAlmacenAplicacion;

type
  TLectorMovimientosPrueba = class(
    TInterfacedObject,
    ILectorMovimientosAlmacen)
  private
    FFinalizado: Boolean;
    FIndice: Integer;
    FTotal: Integer;
  public
    constructor Create(ATotal: Integer);
    function ObtenerAnyos: TArray<Integer>;
    function ObtenerAlmacenes: TArray<TAlmacenFiltroMovimiento>;
    procedure Preparar(const AFiltro: TFiltroMovimientosAlmacen);
    function Contar: Integer;
    procedure IniciarCarga(ATamanoBloque: Integer);
    function HayMovimiento: Boolean;
    procedure Siguiente;
    procedure FinalizarCarga;
    property Finalizado: Boolean read FFinalizado;
  end;
  TUnidadTrabajoMovimientosPrueba = class(
    TInterfacedObject,
    IUnidadTrabajoMovimientosAlmacen)
  private
    FConfirmaciones: Integer;
    FInicios: Integer;
    FReversiones: Integer;
  public
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
    property Confirmaciones: Integer read FConfirmaciones;
    property Inicios: Integer read FInicios;
    property Reversiones: Integer read FReversiones;
  end;
  TEscritorMovimientosPrueba = class(
    TInterfacedObject,
    IEscritorMovimientosAlmacen)
  private
    FGuardados: Integer;
    FFalloEn: Integer;
  public
    constructor Create(AFalloEn: Integer = 0);
    procedure Guardar(const AMovimiento: TMovimientoAlmacenEscritura);
    property Guardados: Integer read FGuardados;
  end;
  TCancelacionMovimientosPrueba = class
  public
    function CancelarCarga(ALeidos, ATotal: Integer): Boolean;
    function CancelarEscritura(AProcesados, ATotal: Integer): Boolean;
  end;

constructor TLectorMovimientosPrueba.Create(ATotal: Integer);
begin
  inherited Create;
  FTotal := ATotal;
end;

function TLectorMovimientosPrueba.ObtenerAnyos: TArray<Integer>;
begin
  Result := nil;
end;

function TLectorMovimientosPrueba.ObtenerAlmacenes:
  TArray<TAlmacenFiltroMovimiento>;
begin
  Result := nil;
end;

procedure TLectorMovimientosPrueba.Preparar(
  const AFiltro: TFiltroMovimientosAlmacen);
begin
end;

function TLectorMovimientosPrueba.Contar: Integer;
begin
  Result := FTotal;
end;

procedure TLectorMovimientosPrueba.IniciarCarga(ATamanoBloque: Integer);
begin
  FIndice := 0;
  FFinalizado := False;
end;

function TLectorMovimientosPrueba.HayMovimiento: Boolean;
begin
  Result := FIndice < FTotal;
end;

procedure TLectorMovimientosPrueba.Siguiente;
begin
  Inc(FIndice);
end;

procedure TLectorMovimientosPrueba.FinalizarCarga;
begin
  FFinalizado := True;
end;

procedure TUnidadTrabajoMovimientosPrueba.Iniciar;
begin
  Inc(FInicios);
end;

procedure TUnidadTrabajoMovimientosPrueba.Confirmar;
begin
  Inc(FConfirmaciones);
end;

procedure TUnidadTrabajoMovimientosPrueba.Revertir;
begin
  Inc(FReversiones);
end;

constructor TEscritorMovimientosPrueba.Create(AFalloEn: Integer);
begin
  inherited Create;
  FFalloEn := AFalloEn;
end;

procedure TEscritorMovimientosPrueba.Guardar(
  const AMovimiento: TMovimientoAlmacenEscritura);
begin
  Inc(FGuardados);
  if (FFalloEn > 0) and (FGuardados = FFalloEn) then
    raise Exception.Create('Fallo de escritura simulado');
end;

function TCancelacionMovimientosPrueba.CancelarCarga(
  ALeidos, ATotal: Integer): Boolean;
begin
  Result := ALeidos = 2;
end;

function TCancelacionMovimientosPrueba.CancelarEscritura(
  AProcesados, ATotal: Integer): Boolean;
begin
  Result := AProcesados = 2;
end;

procedure TPruebasMovimientosAlmacenAplicacion.
  CargaParcial_CancelaYFinalizaLector;
var
  Cancelacion: TCancelacionMovimientosPrueba;
  Lector: TLectorMovimientosPrueba;
  Resultado: TResultadoCargaMovimientos;
  Servicio: TServicioCargaMovimientosAlmacen;
begin
  Lector := TLectorMovimientosPrueba.Create(5);
  Servicio := TServicioCargaMovimientosAlmacen.Create(Lector);
  Cancelacion := TCancelacionMovimientosPrueba.Create;
  try
    Resultado := Servicio.Cargar(100, 20, 1, Cancelacion.CancelarCarga);
    Assert.AreEqual(Ord(ecmCancelada), Ord(Resultado.Estado));
    Assert.AreEqual(2, Resultado.Leidos);
    Assert.IsTrue(Lector.Finalizado);
  finally
    Cancelacion.Free;
    Servicio.Free;
  end;
end;

procedure TPruebasMovimientosAlmacenAplicacion.
  GeneracionCompleta_ConfirmaUnidadTrabajo;
var
  Escritor: TEscritorMovimientosPrueba;
  Movimientos: TArray<TMovimientoAlmacenEscritura>;
  Servicio: TServicioEscrituraMovimientosAlmacen;
  UnidadTrabajo: TUnidadTrabajoMovimientosPrueba;
begin
  SetLength(Movimientos, 3);
  Escritor := TEscritorMovimientosPrueba.Create;
  UnidadTrabajo := TUnidadTrabajoMovimientosPrueba.Create;
  Servicio := TServicioEscrituraMovimientosAlmacen.Create(
    Escritor,
    UnidadTrabajo);
  try
    Servicio.Generar(Movimientos, nil);
    Assert.AreEqual(3, Escritor.Guardados);
    Assert.AreEqual(1, UnidadTrabajo.Inicios);
    Assert.AreEqual(1, UnidadTrabajo.Confirmaciones);
    Assert.AreEqual(0, UnidadTrabajo.Reversiones);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasMovimientosAlmacenAplicacion.
  GeneracionCancelada_RevierteMovimientosParciales;
var
  Cancelacion: TCancelacionMovimientosPrueba;
  Escritor: TEscritorMovimientosPrueba;
  Movimientos: TArray<TMovimientoAlmacenEscritura>;
  Resultado: TResultadoEscrituraMovimientos;
  Servicio: TServicioEscrituraMovimientosAlmacen;
  UnidadTrabajo: TUnidadTrabajoMovimientosPrueba;
begin
  SetLength(Movimientos, 3);
  Escritor := TEscritorMovimientosPrueba.Create;
  UnidadTrabajo := TUnidadTrabajoMovimientosPrueba.Create;
  Servicio := TServicioEscrituraMovimientosAlmacen.Create(
    Escritor,
    UnidadTrabajo);
  Cancelacion := TCancelacionMovimientosPrueba.Create;
  try
    Resultado := Servicio.Generar(
      Movimientos,
      Cancelacion.CancelarEscritura);
    Assert.AreEqual(2, Resultado.Generados);
    Assert.IsTrue(Resultado.Cancelada);
    Assert.AreEqual(0, UnidadTrabajo.Confirmaciones);
    Assert.AreEqual(1, UnidadTrabajo.Reversiones);
  finally
    Cancelacion.Free;
    Servicio.Free;
  end;
end;

procedure TPruebasMovimientosAlmacenAplicacion.
  ErrorDeEscritura_RevierteUnidadTrabajo;
var
  Escritor: TEscritorMovimientosPrueba;
  Movimientos: TArray<TMovimientoAlmacenEscritura>;
  Servicio: TServicioEscrituraMovimientosAlmacen;
  UnidadTrabajo: TUnidadTrabajoMovimientosPrueba;
begin
  SetLength(Movimientos, 3);
  Escritor := TEscritorMovimientosPrueba.Create(2);
  UnidadTrabajo := TUnidadTrabajoMovimientosPrueba.Create;
  Servicio := TServicioEscrituraMovimientosAlmacen.Create(
    Escritor,
    UnidadTrabajo);
  try
    Assert.WillRaise(
      procedure
      begin
        Servicio.Generar(Movimientos, nil);
      end,
      Exception);
    Assert.AreEqual(1, UnidadTrabajo.Reversiones);
    Assert.AreEqual(0, UnidadTrabajo.Confirmaciones);
  finally
    Servicio.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasMovimientosAlmacenAplicacion);

end.
