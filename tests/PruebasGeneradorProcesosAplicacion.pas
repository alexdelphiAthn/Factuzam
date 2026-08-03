{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGeneradorProcesosAplicacion                            }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza ejecución y cancelación del generador sin VCL.                }
{******************************************************************************}
unit PruebasGeneradorProcesosAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasGeneradorProcesosAplicacion = class
  public
    [Test]
    procedure Generacion_EjecutaTodasLasSentencias;
    [Test]
    procedure Cancelacion_NoEjecutaSentenciasPosteriores;
    [Test]
    procedure Clasificacion_ReconoceConsultasYComandos;
  end;

implementation

uses
  System.SysUtils,
  inLibGeneradorProcesosAplicacion;

type
  TResultadoProcesoPrueba = class(
    TInterfacedObject,
    IResultadoSentenciaProceso)
  private
    FCorrecto: Boolean;
  public
    constructor Create(ACorrecto: Boolean);
    function Correcto: Boolean;
    function TieneDatos: Boolean;
    function Filas: Integer;
    function Milisegundos: Int64;
    function MensajeError: string;
  end;
  TRepositorioGeneradorPrueba = class(
    TInterfacedObject,
    IRepositorioGeneradorProcesos)
  private
    FEjecuciones: Integer;
    FIndiceError: Integer;
  public
    constructor Create(AIndiceError: Integer);
    function SepararSentencias(
      const AScript: string): TArray<string>;
    function EjecutarSentencia(
      const ASentencia: string;
      ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
    property Ejecuciones: Integer read FEjecuciones;
  end;
  TDecisionGeneradorPrueba = class
  public
    function Cancelar(
      const AResultado: IResultadoSentenciaProceso;
      AIndice: Integer): Boolean;
  end;

constructor TResultadoProcesoPrueba.Create(ACorrecto: Boolean);
begin
  inherited Create;
  FCorrecto := ACorrecto;
end;

function TResultadoProcesoPrueba.Correcto: Boolean;
begin
  Result := FCorrecto;
end;

function TResultadoProcesoPrueba.TieneDatos: Boolean;
begin
  Result := False;
end;

function TResultadoProcesoPrueba.Filas: Integer;
begin
  Result := 1;
end;

function TResultadoProcesoPrueba.Milisegundos: Int64;
begin
  Result := 1;
end;

function TResultadoProcesoPrueba.MensajeError: string;
begin
  if FCorrecto then
    Result := ''
  else
    Result := 'Error simulado';
end;

constructor TRepositorioGeneradorPrueba.Create(AIndiceError: Integer);
begin
  inherited Create;
  FIndiceError := AIndiceError;
end;

function TRepositorioGeneradorPrueba.SepararSentencias(
  const AScript: string): TArray<string>;
begin
  SetLength(Result, 3);
  Result[0] := 'UPDATE uno';
  Result[1] := 'UPDATE dos';
  Result[2] := 'UPDATE tres';
end;

function TRepositorioGeneradorPrueba.EjecutarSentencia(
  const ASentencia: string;
  ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
begin
  Inc(FEjecuciones);
  Result := TResultadoProcesoPrueba.Create(
    FEjecuciones <> FIndiceError);
end;

function TDecisionGeneradorPrueba.Cancelar(
  const AResultado: IResultadoSentenciaProceso;
  AIndice: Integer): Boolean;
begin
  Result := False;
end;

procedure TPruebasGeneradorProcesosAplicacion.
  Generacion_EjecutaTodasLasSentencias;
var
  Repositorio: TRepositorioGeneradorPrueba;
  Resultado: TResultadoEjecucionProceso;
  Servicio: TServicioGeneradorProcesos;
begin
  Repositorio := TRepositorioGeneradorPrueba.Create(0);
  Servicio := TServicioGeneradorProcesos.Create(Repositorio);
  try
    Resultado := Servicio.Ejecutar('script', nil);
    Assert.AreEqual(3, Repositorio.Ejecuciones);
    Assert.AreEqual(3, Integer(Length(Resultado.Resultados)));
    Assert.IsFalse(Resultado.Cancelada);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasGeneradorProcesosAplicacion.
  Cancelacion_NoEjecutaSentenciasPosteriores;
var
  Decision: TDecisionGeneradorPrueba;
  Repositorio: TRepositorioGeneradorPrueba;
  Resultado: TResultadoEjecucionProceso;
  Servicio: TServicioGeneradorProcesos;
begin
  Repositorio := TRepositorioGeneradorPrueba.Create(2);
  Servicio := TServicioGeneradorProcesos.Create(Repositorio);
  Decision := TDecisionGeneradorPrueba.Create;
  try
    Resultado := Servicio.Ejecutar('script', Decision.Cancelar);
    Assert.AreEqual(2, Repositorio.Ejecuciones);
    Assert.AreEqual(2, Integer(Length(Resultado.Resultados)));
    Assert.IsTrue(Resultado.Cancelada);
  finally
    Decision.Free;
    Servicio.Free;
  end;
end;

procedure TPruebasGeneradorProcesosAplicacion.
  Clasificacion_ReconoceConsultasYComandos;
begin
  Assert.AreEqual(
    Ord(tspConsulta),
    Ord(TipoSentenciaProceso('-- comentario' + sLineBreak + 'SELECT 1')));
  Assert.AreEqual(
    Ord(tspComando),
    Ord(TipoSentenciaProceso('UPDATE tabla SET campo = 1')));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasGeneradorProcesosAplicacion);

end.
