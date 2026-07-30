{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasVerifactuColaRepositorio                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada de la cola fiscal mediante puertos sin BBDD.       }
{******************************************************************************}
unit PruebasVerifactuColaRepositorio;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasVerifactuColaRepositorio = class
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Liberar;
    [Test]
    procedure EncolarFactura_DelegaTodosLosDatos;
    [Test]
    procedure RegistrarNoVerifactu_DelegaOperacion;
    [Test]
    procedure MarcarSinVerifactu_DelegaTodosLosDatos;
    [Test]
    procedure BorrarMovimientos_DelegaDocumento;
    [Test]
    procedure Rectificativa_DelegaRelacionFiscal;
    [Test]
    procedure RelacionFactura_DelegaOrigen;
    [Test]
    procedure ServicioAusente_FallaDeFormaRuidosa;
    [Test]
    procedure Procesador_SeIniciaYDetieneUnaVez;
    [Test]
    procedure Procesador_ConservaElPrimeroYLaParadaEsIdempotente;
    [Test]
    procedure ProcesadorAusente_FallaDeFormaRuidosa;
    [Test]
    procedure ProcesadorUniDAC_SinConexionesFallaDeFormaRuidosa;
    [Test]
    procedure ServicioUniDAC_ConsultaNulaFallaDeFormaRuidosa;
    [Test]
    procedure ServicioUniDAC_ConsultaSinConexionFallaDeFormaRuidosa;
    [Test]
    procedure ServicioUniDAC_ConexionNulaFallaDeFormaRuidosa;
    [Test]
    procedure ServicioUniDAC_ConstruyeLosDosAdaptadores;
    [Test]
    procedure Reintento_CalculaEsperaExponencialConTope;
    [Test]
    procedure Reintento_SaturaEnElQuintoIntento;
    [Test]
    procedure Reintento_MarcaErrorAlAgotarIntentos;
    [Test]
    procedure Reintento_ConUnIntentoMaximoMarcaErrorEnElPrimero;
    [Test]
    procedure NoVerifactu_EstadoRegistroSegunOperacion;
    [Test]
    procedure Rectificativa_SinServicioEmisionFallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Uni, inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibVerifactuColaIntf, inLibVerifactuCola,
  UniDataVerifactuColaRepositorio,
  UniDataVerifactuColaProcesador, UniDataVerifactuColaResultados,
  UniDataVerifactuColaOperaciones;

type
  TOperacionColaFalsa = (
    ocfNinguna,
    ocfEncolar,
    ocfNoVerifactu,
    ocfSinVerifactu,
    ocfBorrarMovimientos,
    ocfRectificativa,
    ocfRelacion);
  TServicioVerifactuColaFalso = class(
    TInterfacedObject,
    IServicioVerifactuCola)
  public
    BorrarMovimientos: Boolean;
    Numero: string;
    NumeroOrigen: string;
    Operacion: TOperacionColaFalsa;
    Serie: string;
    SerieOrigen: string;
    TipoOperacion: string;
    Usuario: string;
    procedure EncolarFactura(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure RegistrarFacturaNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure MarcarFacturaSinVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure BorrarMovimientosFactura(
      const ASerie, ANumero: string);
    procedure EncolarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioEmision: IServicioEmisionFiscal;
      const AUsuario, ASerieOriginal, ANumeroOriginal,
      ASerieRect, ANumeroRect, ATipoRectificativa: string;
      ABorrarMovimientosOriginales: Boolean);
    procedure RegistrarRelacionFactura(
      const AUsuario, ASerie, ANumero, ASerieOrigen,
      ANumeroOrigen, ATipoRelacion: string);
  end;
  TProcesadorVerifactuColaFalso = class(
    TInterfacedObject,
    IProcesadorVerifactuCola)
  public
    Inicios: Integer;
    Paradas: Integer;
    procedure Iniciar;
    procedure Detener;
  end;

procedure TServicioVerifactuColaFalso.EncolarFactura(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  Operacion := ocfEncolar;
  Usuario := AUsuario;
  Serie := ASerie;
  Numero := ANumero;
  TipoOperacion := ATipoOperacion;
  BorrarMovimientos := ABorrarMovimientos;
end;

procedure TServicioVerifactuColaFalso.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  Operacion := ocfNoVerifactu;
  Usuario := AUsuario;
  Serie := ASerie;
  Numero := ANumero;
  TipoOperacion := ATipoOperacion;
  BorrarMovimientos := ABorrarMovimientos;
end;

procedure TServicioVerifactuColaFalso.MarcarFacturaSinVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  Operacion := ocfSinVerifactu;
  Usuario := AUsuario;
  Serie := ASerie;
  Numero := ANumero;
  TipoOperacion := ATipoOperacion;
  BorrarMovimientos := ABorrarMovimientos;
end;

procedure TServicioVerifactuColaFalso.BorrarMovimientosFactura(
  const ASerie, ANumero: string);
begin
  Operacion := ocfBorrarMovimientos;
  Serie := ASerie;
  Numero := ANumero;
end;

procedure TServicioVerifactuColaFalso.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
begin
  Operacion := ocfRectificativa;
  Usuario := AUsuario;
  SerieOrigen := ASerieOriginal;
  NumeroOrigen := ANumeroOriginal;
  Serie := ASerieRect;
  Numero := ANumeroRect;
  TipoOperacion := ATipoRectificativa;
  BorrarMovimientos := ABorrarMovimientosOriginales;
end;

procedure TServicioVerifactuColaFalso.RegistrarRelacionFactura(
  const AUsuario, ASerie, ANumero, ASerieOrigen,
  ANumeroOrigen, ATipoRelacion: string);
begin
  Operacion := ocfRelacion;
  Usuario := AUsuario;
  Serie := ASerie;
  Numero := ANumero;
  SerieOrigen := ASerieOrigen;
  NumeroOrigen := ANumeroOrigen;
  TipoOperacion := ATipoRelacion;
end;

procedure TProcesadorVerifactuColaFalso.Iniciar;
begin
  Inc(Inicios);
end;

procedure TProcesadorVerifactuColaFalso.Detener;
begin
  Inc(Paradas);
end;

procedure TPruebasVerifactuColaRepositorio.Preparar;
begin
  TVerifactuCola.DetenerHilo;
end;

procedure TPruebasVerifactuColaRepositorio.Liberar;
begin
  TVerifactuCola.DetenerHilo;
end;

procedure TPruebasVerifactuColaRepositorio.
  EncolarFactura_DelegaTodosLosDatos;
var
  Contrato: IServicioVerifactuCola;
  Servicio: TServicioVerifactuColaFalso;
begin
  Servicio := TServicioVerifactuColaFalso.Create;
  Contrato := Servicio;
  TVerifactuCola.EncolarFactura(
    nil,
    nil,
    Contrato,
    'PRUEBAS',
    'F',
    '42',
    'ANULACION',
    False);
  Assert.AreEqual(ocfEncolar, Servicio.Operacion);
  Assert.AreEqual('PRUEBAS', Servicio.Usuario);
  Assert.AreEqual('F', Servicio.Serie);
  Assert.AreEqual('42', Servicio.Numero);
  Assert.AreEqual('ANULACION', Servicio.TipoOperacion);
  Assert.IsFalse(Servicio.BorrarMovimientos);
end;

procedure TPruebasVerifactuColaRepositorio.
  RegistrarNoVerifactu_DelegaOperacion;
var
  Contrato: IServicioVerifactuCola;
  Servicio: TServicioVerifactuColaFalso;
begin
  Servicio := TServicioVerifactuColaFalso.Create;
  Contrato := Servicio;
  TVerifactuCola.RegistrarFacturaNoVerifactu(
    nil,
    nil,
    Contrato,
    'PRUEBAS',
    'NV',
    '7',
    'SUBSANACION',
    True);
  Assert.AreEqual(ocfNoVerifactu, Servicio.Operacion);
  Assert.AreEqual('SUBSANACION', Servicio.TipoOperacion);
  Assert.IsTrue(Servicio.BorrarMovimientos);
end;

procedure TPruebasVerifactuColaRepositorio.
  MarcarSinVerifactu_DelegaTodosLosDatos;
var
  Contrato: IServicioVerifactuCola;
  Servicio: TServicioVerifactuColaFalso;
begin
  Servicio := TServicioVerifactuColaFalso.Create;
  Contrato := Servicio;
  TVerifactuCola.MarcarFacturaSinVerifactu(
    nil,
    nil,
    Contrato,
    'PRUEBAS',
    'SV',
    '8',
    'ANULACION',
    False);
  Assert.AreEqual(ocfSinVerifactu, Servicio.Operacion);
  Assert.AreEqual('PRUEBAS', Servicio.Usuario);
  Assert.AreEqual('SV', Servicio.Serie);
  Assert.AreEqual('8', Servicio.Numero);
  Assert.AreEqual('ANULACION', Servicio.TipoOperacion);
  Assert.IsFalse(Servicio.BorrarMovimientos);
end;

procedure TPruebasVerifactuColaRepositorio.
  BorrarMovimientos_DelegaDocumento;
var
  Contrato: IServicioVerifactuCola;
  Servicio: TServicioVerifactuColaFalso;
begin
  Servicio := TServicioVerifactuColaFalso.Create;
  Contrato := Servicio;
  TVerifactuCola.BorrarMovimientosFactura(
    Contrato,
    'BM',
    '19');
  Assert.AreEqual(ocfBorrarMovimientos, Servicio.Operacion);
  Assert.AreEqual('BM', Servicio.Serie);
  Assert.AreEqual('19', Servicio.Numero);
end;

procedure TPruebasVerifactuColaRepositorio.
  Rectificativa_DelegaRelacionFiscal;
var
  Contrato: IServicioVerifactuCola;
  Servicio: TServicioVerifactuColaFalso;
begin
  Servicio := TServicioVerifactuColaFalso.Create;
  Contrato := Servicio;
  TVerifactuCola.EncolarRectificativa(
    nil,
    nil,
    Contrato,
    nil,
    'PRUEBAS',
    'OR',
    '1',
    'RE',
    '2',
    'S',
    True);
  Assert.AreEqual(ocfRectificativa, Servicio.Operacion);
  Assert.AreEqual('OR', Servicio.SerieOrigen);
  Assert.AreEqual('1', Servicio.NumeroOrigen);
  Assert.AreEqual('RE', Servicio.Serie);
  Assert.AreEqual('2', Servicio.Numero);
  Assert.AreEqual('S', Servicio.TipoOperacion);
  Assert.IsTrue(Servicio.BorrarMovimientos);
end;

procedure TPruebasVerifactuColaRepositorio.
  RelacionFactura_DelegaOrigen;
var
  Contrato: IServicioVerifactuCola;
  Servicio: TServicioVerifactuColaFalso;
begin
  Servicio := TServicioVerifactuColaFalso.Create;
  Contrato := Servicio;
  TVerifactuCola.RegistrarRelacionFactura(
    Contrato,
    'PRUEBAS',
    'F',
    '3',
    'T',
    '9',
    'SUSTITUYE');
  Assert.AreEqual(ocfRelacion, Servicio.Operacion);
  Assert.AreEqual('T', Servicio.SerieOrigen);
  Assert.AreEqual('9', Servicio.NumeroOrigen);
  Assert.AreEqual('SUSTITUYE', Servicio.TipoOperacion);
end;

procedure TPruebasVerifactuColaRepositorio.
  ServicioAusente_FallaDeFormaRuidosa;
begin
  Assert.WillRaise(
    procedure
    begin
      TVerifactuCola.BorrarMovimientosFactura(
        nil,
        'F',
        '42');
    end,
    EArgumentNilException);
end;

procedure TPruebasVerifactuColaRepositorio.
  Procesador_SeIniciaYDetieneUnaVez;
var
  Contrato: IProcesadorVerifactuCola;
  Procesador: TProcesadorVerifactuColaFalso;
begin
  Procesador := TProcesadorVerifactuColaFalso.Create;
  Contrato := Procesador;
  TVerifactuCola.IniciarHilo(Contrato);
  TVerifactuCola.IniciarHilo(Contrato);
  Assert.AreEqual(1, Procesador.Inicios);
  TVerifactuCola.DetenerHilo;
  Assert.AreEqual(1, Procesador.Paradas);
end;

procedure TPruebasVerifactuColaRepositorio.
  Procesador_ConservaElPrimeroYLaParadaEsIdempotente;
var
  ContratoPrimero: IProcesadorVerifactuCola;
  ContratoSegundo: IProcesadorVerifactuCola;
  Primero: TProcesadorVerifactuColaFalso;
  Segundo: TProcesadorVerifactuColaFalso;
begin
  Primero := TProcesadorVerifactuColaFalso.Create;
  Segundo := TProcesadorVerifactuColaFalso.Create;
  ContratoPrimero := Primero;
  ContratoSegundo := Segundo;
  TVerifactuCola.IniciarHilo(ContratoPrimero);
  TVerifactuCola.IniciarHilo(ContratoSegundo);
  TVerifactuCola.DetenerHilo;
  TVerifactuCola.DetenerHilo;
  Assert.AreEqual(1, Primero.Inicios);
  Assert.AreEqual(1, Primero.Paradas);
  Assert.AreEqual(0, Segundo.Inicios);
  Assert.AreEqual(0, Segundo.Paradas);
end;

procedure TPruebasVerifactuColaRepositorio.
  ProcesadorAusente_FallaDeFormaRuidosa;
begin
  Assert.WillRaise(
    procedure
    begin
      TVerifactuCola.IniciarHilo(nil);
    end,
    EArgumentNilException);
end;

procedure TPruebasVerifactuColaRepositorio.
  ProcesadorUniDAC_SinConexionesFallaDeFormaRuidosa;
begin
  Assert.WillRaise(
    procedure
    begin
      CrearProcesadorVerifactuColaUniDAC(
        nil,
        nil,
        nil,
        nil,
        'PRUEBAS');
    end,
    EArgumentNilException);
end;

procedure TPruebasVerifactuColaRepositorio.
  ServicioUniDAC_ConsultaNulaFallaDeFormaRuidosa;
var
  Consulta: TUniQuery;
begin
  Consulta := nil;
  Assert.WillRaise(
    procedure
    begin
      CrearServicioVerifactuColaUniDAC(Consulta);
    end,
    EArgumentNilException);
end;

procedure TPruebasVerifactuColaRepositorio.
  ServicioUniDAC_ConsultaSinConexionFallaDeFormaRuidosa;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Assert.WillRaise(
      procedure
      begin
        CrearServicioVerifactuColaUniDAC(Consulta);
      end,
      EArgumentNilException);
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TPruebasVerifactuColaRepositorio.
  ServicioUniDAC_ConexionNulaFallaDeFormaRuidosa;
var
  Conexion: TUniConnection;
begin
  Conexion := nil;
  Assert.WillRaise(
    procedure
    begin
      CrearServicioVerifactuColaUniDAC(Conexion);
    end,
    EArgumentNilException);
end;

procedure TPruebasVerifactuColaRepositorio.
  ServicioUniDAC_ConstruyeLosDosAdaptadores;
var
  Conexion: TUniConnection;
  Consulta: TUniQuery;
  ServicioConexion: IServicioVerifactuCola;
  ServicioConsulta: IServicioVerifactuCola;
begin
  Conexion := TUniConnection.Create(nil);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := Conexion;
    ServicioConsulta := CrearServicioVerifactuColaUniDAC(Consulta);
    ServicioConexion := CrearServicioVerifactuColaUniDAC(Conexion);
    Assert.IsTrue(Assigned(ServicioConsulta));
    Assert.IsTrue(Assigned(ServicioConexion));
    ServicioConsulta := nil;
    Assert.IsTrue(Consulta.Connection = Conexion);
  finally
    ServicioConexion := nil;
    ServicioConsulta := nil;
    FreeAndNil(Consulta);
    FreeAndNil(Conexion);
  end;
end;

procedure TPruebasVerifactuColaRepositorio.
  Reintento_CalculaEsperaExponencialConTope;
begin
  Assert.AreEqual(60, CalcularEsperaReintentoVerifactu(0));
  Assert.AreEqual(120, CalcularEsperaReintentoVerifactu(1));
  Assert.AreEqual(1920, CalcularEsperaReintentoVerifactu(6));
end;

procedure TPruebasVerifactuColaRepositorio.
  Reintento_SaturaEnElQuintoIntento;
begin
  Assert.AreEqual(960, CalcularEsperaReintentoVerifactu(4));
  Assert.AreEqual(1920, CalcularEsperaReintentoVerifactu(5));
  Assert.AreEqual(1920, CalcularEsperaReintentoVerifactu(30));
end;

procedure TPruebasVerifactuColaRepositorio.
  Reintento_MarcaErrorAlAgotarIntentos;
begin
  Assert.AreEqual(
    'PENDIENTE',
    CalcularEstadoReintentoVerifactu(8, 10));
  Assert.AreEqual(
    'ERROR',
    CalcularEstadoReintentoVerifactu(9, 10));
end;

procedure TPruebasVerifactuColaRepositorio.
  Reintento_ConUnIntentoMaximoMarcaErrorEnElPrimero;
begin
  Assert.AreEqual(
    'ERROR',
    CalcularEstadoReintentoVerifactu(0, 1));
  Assert.AreEqual(
    'ERROR',
    CalcularEstadoReintentoVerifactu(3, 1));
end;

procedure TPruebasVerifactuColaRepositorio.
  NoVerifactu_EstadoRegistroSegunOperacion;
begin
  Assert.AreEqual(
    'NOVERIF_REGISTRADO',
    ObtenerEstadoRegistroNoVerifactu('ALTA'));
  Assert.AreEqual(
    'NOVERIF_ANULADO',
    ObtenerEstadoRegistroNoVerifactu('ANULACION'));
  Assert.AreEqual(
    'NOVERIF_SUBSANADO',
    ObtenerEstadoRegistroNoVerifactu('SUBSANACION'));
end;

procedure TPruebasVerifactuColaRepositorio.
  Rectificativa_SinServicioEmisionFallaDeFormaRuidosa;
begin
  Assert.WillRaise(
    procedure
    begin
      TOperacionesVerifactuColaUniDAC.EncolarRectificativa(
        nil,
        nil,
        nil,
        nil,
        'PRUEBAS',
        'OR',
        '1',
        'RE',
        '2',
        'I',
        False);
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasVerifactuColaRepositorio);

end.
