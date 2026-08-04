{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasIncidenciaFiscal                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decide entre subsanar el registro y emitir una rectificativa R4.          }
{******************************************************************************}
unit inLibFacturasIncidenciaFiscal;

interface

uses
  inLibParametrosIntf,
  inLibEmisionFiscalIntf,
  inLibFacturasIncidenciaFiscalIntf,
  inLibVerifactuColaIntf,
  inLibVerifactuSubsanacionIntf;

const
  cEstadoVerifactuAceptadoErrores = 'VERIFACTU_ACEPT_ERR';

function PuedeResolverIncidenciaFiscal(
  const AEstadoRegistro, AEstadoSubsanacion: string;
  AEsVentaMayor: Boolean): Boolean;
function CrearServicioIncidenciaFiscalFactura(
  const ARepositorio: IRepositorioIncidenciaFiscalFactura;
  const ACola: IServicioVerifactuCola;
  const ASubsanacion: IServicioVerifactuSubsanacion;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string): IServicioIncidenciaFiscalFactura;

implementation

uses
  System.SysUtils,
  inLibMsgVerifactu;

type
  TServicioIncidenciaFiscalFactura = class(
    TInterfacedObject,
    IServicioIncidenciaFiscalFactura)
  private
    FRepositorio: IRepositorioIncidenciaFiscalFactura;
    FCola: IServicioVerifactuCola;
    FSubsanacion: IServicioVerifactuSubsanacion;
    FEmision: IServicioEmisionFiscal;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FUsuario: string;
    function Validar(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const ADatos: TDatosIncidenciaFiscal): string;
    function ResolverSubsanacion(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
    function ResolverRectificativa(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
  public
    constructor Create(
      const ARepositorio: IRepositorioIncidenciaFiscalFactura;
      const ACola: IServicioVerifactuCola;
      const ASubsanacion: IServicioVerifactuSubsanacion;
      const AEmision: IServicioEmisionFiscal;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario: string);
    function CargarIncidencia(
      const ASerie, ANumero: string): TDatosIncidenciaFiscal;
    function CargarCliente(
      const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
    function Resolver(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
  end;

function EstadoSubsanacionActivo(const AEstado: string): Boolean;
begin
  Result := SameText(AEstado, 'PENDIENTE') or
    SameText(AEstado, 'PROCESANDO') or
    SameText(AEstado, 'ENVIADA');
end;

function PuedeResolverIncidenciaFiscal(
  const AEstadoRegistro, AEstadoSubsanacion: string;
  AEsVentaMayor: Boolean): Boolean;
begin
  Result := AEsVentaMayor and
    SameText(AEstadoRegistro, cEstadoVerifactuAceptadoErrores) and
    (not EstadoSubsanacionActivo(AEstadoSubsanacion));
end;

function CrearServicioIncidenciaFiscalFactura(
  const ARepositorio: IRepositorioIncidenciaFiscalFactura;
  const ACola: IServicioVerifactuCola;
  const ASubsanacion: IServicioVerifactuSubsanacion;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string): IServicioIncidenciaFiscalFactura;
begin
  Result := TServicioIncidenciaFiscalFactura.Create(
    ARepositorio,
    ACola,
    ASubsanacion,
    AEmision,
    AParametrosApp,
    AParametrosCaja,
    AUsuario);
end;

constructor TServicioIncidenciaFiscalFactura.Create(
  const ARepositorio: IRepositorioIncidenciaFiscalFactura;
  const ACola: IServicioVerifactuCola;
  const ASubsanacion: IServicioVerifactuSubsanacion;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(ACola) then
    raise EArgumentNilException.Create('ACola');
  if not Assigned(ASubsanacion) then
    raise EArgumentNilException.Create('ASubsanacion');
  if not Assigned(AEmision) then
    raise EArgumentNilException.Create('AEmision');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create;
  FRepositorio := ARepositorio;
  FCola := ACola;
  FSubsanacion := ASubsanacion;
  FEmision := AEmision;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FUsuario := AUsuario;
end;

function TServicioIncidenciaFiscalFactura.CargarIncidencia(
  const ASerie, ANumero: string): TDatosIncidenciaFiscal;
begin
  Result := FRepositorio.CargarIncidencia(ASerie, ANumero);
end;

function TServicioIncidenciaFiscalFactura.CargarCliente(
  const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
begin
  Result := FRepositorio.CargarCliente(ACodigoCliente);
end;

function TServicioIncidenciaFiscalFactura.Validar(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
  const ADatos: TDatosIncidenciaFiscal): string;
begin
  Result := '';
  if (Trim(ASolicitud.Serie) = '') or
     (Trim(ASolicitud.Numero) = '') then
    Result := SErrorIncidenciaFacturaNoSeleccionada
  else if not SameText(ADatos.TipoFactura, 'NORMAL') then
    Result := SErrorIncidenciaSoloVentaMayor
  else if not SameText(
    ADatos.EstadoRegistro, cEstadoVerifactuAceptadoErrores) then
    Result := SErrorIncidenciaNoAceptadaConErrores
  else if EstadoSubsanacionActivo(ADatos.EstadoSubsanacion) then
    Result := SErrorIncidenciaSubsanacionActiva
  else if Trim(ASolicitud.Motivo) = '' then
    Result := SErrorIncidenciaMotivoObligatorio
  else if ASolicitud.TipoResolucion = trifRectificarFactura then
  begin
    if Trim(ASolicitud.CodigoClienteCorrecto) = '' then
      Result := SErrorIncidenciaClienteObligatorio
    else if Trim(ASolicitud.SerieRectificativa) = '' then
      Result := SErrorIncidenciaSerieRectificativaObligatoria
    else if ASolicitud.FechaRectificativa <= 0 then
      Result := SErrorIncidenciaFechaRectificativaObligatoria;
  end;
end;

function TServicioIncidenciaFiscalFactura.ResolverSubsanacion(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
  TResultadoResolucionIncidenciaFiscal;
begin
  Result := Default(TResultadoResolucionIncidenciaFiscal);
  FSubsanacion.Encolar(
    FParametrosApp,
    FParametrosCaja,
    FUsuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.Motivo);
  Result.EsCorrecto := True;
  Result.Mensaje := SInfoIncidenciaSubsanacionEncolada;
end;

function TServicioIncidenciaFiscalFactura.ResolverRectificativa(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
  TResultadoResolucionIncidenciaFiscal;
begin
  Result := Default(TResultadoResolucionIncidenciaFiscal);
  Result.NumeroRectificativa := FRepositorio.CrearRectificativaR4(
    ASolicitud,
    FUsuario);
  Result.SerieRectificativa := ASolicitud.SerieRectificativa;
  FCola.EncolarRectificativa(
    FParametrosApp,
    FParametrosCaja,
    FEmision,
    FUsuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    Result.SerieRectificativa,
    Result.NumeroRectificativa,
    'S',
    False);
  Result.EsCorrecto := True;
  Result.Mensaje := Format(
    SInfoIncidenciaRectificativaCreada,
    [Result.SerieRectificativa, Result.NumeroRectificativa]);
end;

function TServicioIncidenciaFiscalFactura.Resolver(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
  TResultadoResolucionIncidenciaFiscal;
var
  Datos: TDatosIncidenciaFiscal;
  sError: string;
begin
  Result := Default(TResultadoResolucionIncidenciaFiscal);
  Datos := FRepositorio.CargarIncidencia(
    ASolicitud.Serie,
    ASolicitud.Numero);
  sError := Validar(ASolicitud, Datos);
  if sError <> '' then
    Result.Mensaje := sError
  else if ASolicitud.TipoResolucion = trifSubsanarRegistro then
    Result := ResolverSubsanacion(ASolicitud)
  else
    Result := ResolverRectificativa(ASolicitud);
end;

end.
