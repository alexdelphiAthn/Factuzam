{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasIncidenciaFiscal                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prueba la decisión entre subsanación y factura rectificativa R4.          }
{******************************************************************************}
unit PruebasFacturasIncidenciaFiscal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasIncidenciaFiscal = class
  public
    [Test]
    procedure Disponibilidad_SoloAceptadoConErroresSinSubsanacionActiva;
    [Test]
    procedure FacturaExpedidaCorrecta_EncolaSubsanacion;
    [Test]
    procedure NifEnFacturaIncorrecto_CreaRectificativaR4S;
    [Test]
    procedure EstadoCorrecto_RechazaResolucion;
  end;

implementation

uses
  System.SysUtils,
  inLibEmisionFiscalIntf,
  inLibFacturasIncidenciaFiscal,
  inLibFacturasIncidenciaFiscalIntf,
  inLibLicenciaAplicacion,
  inLibParametrosIntf,
  inLibVerifactuColaIntf,
  inLibVerifactuSubsanacionIntf,
  inLibVerifactuTipos;

type
  TRepositorioIncidenciaFalso = class(
    TInterfacedObject,
    IRepositorioIncidenciaFiscalFactura)
  public
    Datos: TDatosIncidenciaFiscal;
    Cliente: TDatosClienteIncidenciaFiscal;
    CreoRectificativa: Boolean;
    SolicitudRectificativa: TSolicitudResolucionIncidenciaFiscal;
    function CargarIncidencia(
      const ASerie, ANumero: string): TDatosIncidenciaFiscal;
    function CargarCliente(
      const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
    function CrearRectificativaR4(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const AUsuario: string): string;
  end;
  TColaIncidenciaFalsa = class(
    TInterfacedObject,
    IServicioVerifactuCola)
  public
    EncoloRectificativa: Boolean;
    TipoRectificativa: string;
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
    procedure BorrarMovimientosFactura(const ASerie, ANumero: string);
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
  TSubsanacionIncidenciaFalsa = class(
    TInterfacedObject,
    IServicioVerifactuSubsanacion)
  public
    Encolo: Boolean;
    Motivo: string;
    procedure Encolar(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, AMotivo: string);
  end;
  TEmisionFiscalFalsa = class(
    TInterfacedObject,
    IServicioEmisionFiscal)
  public
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;
  TParametrosAplicacionFalsos = class(
    TInterfacedObject,
    IParametrosAplicacion)
  public
    function GetString(
      const AKey: string;
      const ADefault: string = ''): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0): Integer;
    function GetPath(const ANombre: string): string;
    function Licencia: TResultadoLicenciaAplicacion;
  end;
  TParametrosCajaFalsos = class(
    TInterfacedObject,
    IParametrosCaja)
  public
    function GetString(
      const AKey: string;
      const ADefault: string = ''): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0): Integer;
    function ImpresoraCaja: string;
    function TarifaDefecto: string;
    function NivelesFamiliaArqueo: Integer;
  end;

function CrearDatosAceptadosConErrores: TDatosIncidenciaFiscal;
begin
  Result := Default(TDatosIncidenciaFiscal);
  Result.Serie := 'F';
  Result.Numero := '42';
  Result.TipoFactura := 'NORMAL';
  Result.EstadoRegistro := cEstadoVerifactuAceptadoErrores;
  Result.CodigoError := '1100';
  Result.DescripcionError := 'NIF no identificado';
end;

function CrearSolicitud(
  ATipo: TTipoResolucionIncidenciaFiscal):
  TSolicitudResolucionIncidenciaFiscal;
begin
  Result := Default(TSolicitudResolucionIncidenciaFiscal);
  Result.Serie := 'F';
  Result.Numero := '42';
  Result.TipoResolucion := ATipo;
  Result.Motivo := 'NIF del destinatario';
  Result.CodigoClienteCorrecto := 'CLI2';
  Result.SerieRectificativa := 'R';
  Result.FechaRectificativa := EncodeDate(2026, 8, 4);
end;

function CrearServicioPrueba(
  ARepositorio: TRepositorioIncidenciaFalso;
  ACola: TColaIncidenciaFalsa;
  ASubsanacion: TSubsanacionIncidenciaFalsa):
  IServicioIncidenciaFiscalFactura;
var
  ParametrosApp: IParametrosAplicacion;
  ParametrosCaja: IParametrosCaja;
  Emision: IServicioEmisionFiscal;
  Repositorio: IRepositorioIncidenciaFiscalFactura;
  Cola: IServicioVerifactuCola;
  Subsanacion: IServicioVerifactuSubsanacion;
begin
  Repositorio := ARepositorio;
  Cola := ACola;
  Subsanacion := ASubsanacion;
  ParametrosApp := TParametrosAplicacionFalsos.Create;
  ParametrosCaja := TParametrosCajaFalsos.Create;
  Emision := TEmisionFiscalFalsa.Create;
  Result := CrearServicioIncidenciaFiscalFactura(
    Repositorio,
    Cola,
    Subsanacion,
    Emision,
    ParametrosApp,
    ParametrosCaja,
    'PRUEBAS');
end;

function TRepositorioIncidenciaFalso.CargarIncidencia(
  const ASerie, ANumero: string): TDatosIncidenciaFiscal;
begin
  Result := Datos;
end;

function TRepositorioIncidenciaFalso.CargarCliente(
  const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
begin
  Result := Cliente;
end;

function TRepositorioIncidenciaFalso.CrearRectificativaR4(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
  const AUsuario: string): string;
begin
  CreoRectificativa := True;
  SolicitudRectificativa := ASolicitud;
  Result := '100';
end;

procedure TColaIncidenciaFalsa.EncolarFactura(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
end;

procedure TSubsanacionIncidenciaFalsa.Encolar(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, AMotivo: string);
begin
  Encolo := True;
  Motivo := AMotivo;
end;

procedure TColaIncidenciaFalsa.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
end;

procedure TColaIncidenciaFalsa.MarcarFacturaSinVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
end;

procedure TColaIncidenciaFalsa.BorrarMovimientosFactura(
  const ASerie, ANumero: string);
begin
end;

procedure TColaIncidenciaFalsa.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
begin
  EncoloRectificativa := True;
  TipoRectificativa := ATipoRectificativa;
end;

procedure TColaIncidenciaFalsa.RegistrarRelacionFactura(
  const AUsuario, ASerie, ANumero, ASerieOrigen,
  ANumeroOrigen, ATipoRelacion: string);
begin
end;

function TEmisionFiscalFalsa.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal): TResultadoEmisionFiscal;
begin
  Result := Default(TResultadoEmisionFiscal);
  Result.Modo := mvVerifactu;
end;

function TEmisionFiscalFalsa.Modo: TModoVerifactu;
begin
  Result := mvVerifactu;
end;

function TParametrosAplicacionFalsos.GetString(
  const AKey, ADefault: string): string;
begin
  Result := ADefault;
end;

function TParametrosAplicacionFalsos.GetBool(
  const AKey: string; const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
end;

function TParametrosAplicacionFalsos.GetInt(
  const AKey: string; const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosAplicacionFalsos.GetPath(
  const ANombre: string): string;
begin
  Result := '';
end;

function TParametrosAplicacionFalsos.Licencia:
  TResultadoLicenciaAplicacion;
begin
  Result := Default(TResultadoLicenciaAplicacion);
end;

function TParametrosCajaFalsos.GetString(
  const AKey, ADefault: string): string;
begin
  Result := ADefault;
end;

function TParametrosCajaFalsos.GetBool(
  const AKey: string; const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
end;

function TParametrosCajaFalsos.GetInt(
  const AKey: string; const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosCajaFalsos.ImpresoraCaja: string;
begin
  Result := '';
end;

function TParametrosCajaFalsos.TarifaDefecto: string;
begin
  Result := '';
end;

function TParametrosCajaFalsos.NivelesFamiliaArqueo: Integer;
begin
  Result := 0;
end;

procedure TPruebasFacturasIncidenciaFiscal.
  Disponibilidad_SoloAceptadoConErroresSinSubsanacionActiva;
begin
  Assert.IsTrue(PuedeResolverIncidenciaFiscal(
    cEstadoVerifactuAceptadoErrores,
    '',
    True));
  Assert.IsFalse(PuedeResolverIncidenciaFiscal(
    'VERIFACTU_PROCESADO',
    '',
    True));
  Assert.IsFalse(PuedeResolverIncidenciaFiscal(
    cEstadoVerifactuAceptadoErrores,
    'PENDIENTE',
    True));
  Assert.IsFalse(PuedeResolverIncidenciaFiscal(
    cEstadoVerifactuAceptadoErrores,
    '',
    False));
end;

procedure TPruebasFacturasIncidenciaFiscal.
  FacturaExpedidaCorrecta_EncolaSubsanacion;
var
  Cola: TColaIncidenciaFalsa;
  Repositorio: TRepositorioIncidenciaFalso;
  Servicio: IServicioIncidenciaFiscalFactura;
  Subsanacion: TSubsanacionIncidenciaFalsa;
  Resultado: TResultadoResolucionIncidenciaFiscal;
begin
  Repositorio := TRepositorioIncidenciaFalso.Create;
  Cola := TColaIncidenciaFalsa.Create;
  Subsanacion := TSubsanacionIncidenciaFalsa.Create;
  Repositorio.Datos := CrearDatosAceptadosConErrores;
  Servicio := CrearServicioPrueba(Repositorio, Cola, Subsanacion);
  Resultado := Servicio.Resolver(CrearSolicitud(trifSubsanarRegistro));
  Assert.IsTrue(Resultado.EsCorrecto);
  Assert.IsTrue(Subsanacion.Encolo);
  Assert.IsFalse(Repositorio.CreoRectificativa);
  Assert.AreEqual('NIF del destinatario', Subsanacion.Motivo);
end;

procedure TPruebasFacturasIncidenciaFiscal.
  NifEnFacturaIncorrecto_CreaRectificativaR4S;
var
  Cola: TColaIncidenciaFalsa;
  Repositorio: TRepositorioIncidenciaFalso;
  Servicio: IServicioIncidenciaFiscalFactura;
  Subsanacion: TSubsanacionIncidenciaFalsa;
  Resultado: TResultadoResolucionIncidenciaFiscal;
begin
  Repositorio := TRepositorioIncidenciaFalso.Create;
  Cola := TColaIncidenciaFalsa.Create;
  Subsanacion := TSubsanacionIncidenciaFalsa.Create;
  Repositorio.Datos := CrearDatosAceptadosConErrores;
  Servicio := CrearServicioPrueba(Repositorio, Cola, Subsanacion);
  Resultado := Servicio.Resolver(CrearSolicitud(trifRectificarFactura));
  Assert.IsTrue(Resultado.EsCorrecto);
  Assert.IsTrue(Repositorio.CreoRectificativa);
  Assert.IsTrue(Cola.EncoloRectificativa);
  Assert.AreEqual('S', Cola.TipoRectificativa);
  Assert.AreEqual(trifRectificarFactura,
    Repositorio.SolicitudRectificativa.TipoResolucion);
  Assert.AreEqual('R', Resultado.SerieRectificativa);
  Assert.AreEqual('100', Resultado.NumeroRectificativa);
end;

procedure TPruebasFacturasIncidenciaFiscal.
  EstadoCorrecto_RechazaResolucion;
var
  Cola: TColaIncidenciaFalsa;
  Repositorio: TRepositorioIncidenciaFalso;
  Servicio: IServicioIncidenciaFiscalFactura;
  Subsanacion: TSubsanacionIncidenciaFalsa;
  Resultado: TResultadoResolucionIncidenciaFiscal;
begin
  Repositorio := TRepositorioIncidenciaFalso.Create;
  Cola := TColaIncidenciaFalsa.Create;
  Subsanacion := TSubsanacionIncidenciaFalsa.Create;
  Repositorio.Datos := CrearDatosAceptadosConErrores;
  Repositorio.Datos.EstadoRegistro := 'VERIFACTU_PROCESADO';
  Servicio := CrearServicioPrueba(Repositorio, Cola, Subsanacion);
  Resultado := Servicio.Resolver(CrearSolicitud(trifSubsanarRegistro));
  Assert.IsFalse(Resultado.EsCorrecto);
  Assert.IsFalse(Subsanacion.Encolo);
  Assert.IsFalse(Repositorio.CreoRectificativa);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasIncidenciaFiscal);

end.
