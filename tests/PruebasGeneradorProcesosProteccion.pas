{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGeneradorProcesosProteccion                            }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba que el generador valida el script completo antes de ejecutar    }
{    la primera sentencia.                                                     }
{******************************************************************************}
unit PruebasGeneradorProcesosProteccion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasGeneradorProcesosProteccion = class
  public
    [Test]
    procedure RechazaTodoElScriptAntesDeEjecutarUnaSentenciaProtegida;
    [Test]
    procedure EjecutaLasSentenciasPermitidas;
  end;

implementation

uses
  System.SysUtils,
  inLibGeneradorProcesosAplicacion,
  inLibProteccionDatosFacturacion;

type
  TResultadoSentenciaFalso = class(
    TInterfacedObject,
    IResultadoSentenciaProceso)
  public
    function Correcto: Boolean;
    function TieneDatos: Boolean;
    function Filas: Integer;
    function Milisegundos: Int64;
    function MensajeError: string;
  end;

  TRepositorioGeneradorFalso = class(
    TInterfacedObject,
    IRepositorioGeneradorProcesos)
  private
    FNumeroEjecuciones: Integer;
    FSentencias: TArray<string>;
  public
    constructor Create(const ASentencias: array of string);
    function SepararSentencias(
      const AScript: string): TArray<string>;
    function EjecutarSentencia(
      const ASentencia: string;
      ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
    property NumeroEjecuciones: Integer read FNumeroEjecuciones;
  end;

function TResultadoSentenciaFalso.Correcto: Boolean;
begin
  Result := True;
end;

function TResultadoSentenciaFalso.TieneDatos: Boolean;
begin
  Result := False;
end;

function TResultadoSentenciaFalso.Filas: Integer;
begin
  Result := 0;
end;

function TResultadoSentenciaFalso.Milisegundos: Int64;
begin
  Result := 0;
end;

function TResultadoSentenciaFalso.MensajeError: string;
begin
  Result := '';
end;

constructor TRepositorioGeneradorFalso.Create(
  const ASentencias: array of string);
var
  I: Integer;
begin
  inherited Create;
  SetLength(FSentencias, Length(ASentencias));
  for I := Low(ASentencias) to High(ASentencias) do
    FSentencias[I] := ASentencias[I];
end;

function TRepositorioGeneradorFalso.SepararSentencias(
  const AScript: string): TArray<string>;
begin
  Result := Copy(FSentencias);
end;

function TRepositorioGeneradorFalso.EjecutarSentencia(
  const ASentencia: string;
  ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
begin
  Inc(FNumeroEjecuciones);
  Result := TResultadoSentenciaFalso.Create;
end;

procedure TPruebasGeneradorProcesosProteccion.
  RechazaTodoElScriptAntesDeEjecutarUnaSentenciaProtegida;
var
  Rechazada: Boolean;
  Repositorio: TRepositorioGeneradorFalso;
  Servicio: TServicioGeneradorProcesos;
begin
  Repositorio := TRepositorioGeneradorFalso.Create([
    'UPDATE fza_clientes SET NOMBRE = ''Permitido''',
    'DELETE FROM fza_facturas_lineas WHERE LINEA_FACLIN = 1']);
  Servicio := TServicioGeneradorProcesos.Create(Repositorio);
  try
    Rechazada := False;
    try
      Servicio.Ejecutar('script de prueba', nil);
    except
      on EModificacionTablaFacturacionProtegida do
        Rechazada := True;
    end;

    Assert.IsTrue(Rechazada);
    Assert.AreEqual(0, Repositorio.NumeroEjecuciones);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasGeneradorProcesosProteccion.
  EjecutaLasSentenciasPermitidas;
var
  Ejecucion: TResultadoEjecucionProceso;
  Repositorio: TRepositorioGeneradorFalso;
  Servicio: TServicioGeneradorProcesos;
begin
  Repositorio := TRepositorioGeneradorFalso.Create([
    'UPDATE fza_clientes SET NOMBRE = ''Permitido''',
    'SELECT * FROM fza_facturas']);
  Servicio := TServicioGeneradorProcesos.Create(Repositorio);
  try
    Ejecucion := Servicio.Ejecutar('script de prueba', nil);

    Assert.AreEqual(2, Repositorio.NumeroEjecuciones);
    Assert.AreEqual(2, Integer(Length(Ejecucion.Resultados)));
    Assert.IsFalse(Ejecucion.Cancelada);
  finally
    Servicio.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasGeneradorProcesosProteccion);

end.
