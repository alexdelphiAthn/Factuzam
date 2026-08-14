{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasConsolidacion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consolida factura y coordina fiscalidad, stock y transacción.             }
{    La persistencia entra por IRepositorioConsolidacionFactura.               }
{******************************************************************************}
unit inLibFacturasConsolidacion;

interface

uses
  inLibFacturasServiciosIntf, inLibEmisionFiscalIntf,
  inLibFacturasPersistenciaIntf;

function CrearCasoUsoConsolidacionFactura(
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura
): ICasoUsoConsolidacionFactura;

implementation

uses
  System.SysUtils,
  inLibMsgFacturas,
  inLibPrestaShopColaSenal;

type
  TCasoUsoConsolidacionFactura = class(
    TInterfacedObject,
    ICasoUsoConsolidacionFactura)
  private
    FUnidadTrabajo: IUnidadTrabajoFacturas;
    FRepositorio: IRepositorioConsolidacionFactura;
    FServicioEmision: IServicioEmisionFiscal;
    FServicioMovimientos: IServicioMovimientosFactura;
    function Evaluar(
      const ASerie, ANumero: string;
      const ADatos: TDatosFacturaConsolidacion
    ): TResultadoOperacionFactura;
    function CrearSolicitudMovimientos(
      const ASerie, ANumero, AUsuario: string;
      const ADatos: TDatosFacturaConsolidacion
    ): TSolicitudMovimientosFactura;
  public
    constructor Create(
      const AUnidadTrabajo: IUnidadTrabajoFacturas;
      const ARepositorio: IRepositorioConsolidacionFactura;
      const AServicioEmision: IServicioEmisionFiscal;
      const AServicioMovimientos: IServicioMovimientosFactura);
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    function Consolidar(
      const ASerie, ANumero, AUsuario: string
    ): TResultadoConsolidacionFactura;
  end;

constructor TCasoUsoConsolidacionFactura.Create(
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura);
begin
  inherited Create;
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  if not Assigned(AServicioMovimientos) then
    raise EArgumentNilException.Create('AServicioMovimientos');
  FUnidadTrabajo := AUnidadTrabajo;
  FRepositorio := ARepositorio;
  FServicioEmision := AServicioEmision;
  FServicioMovimientos := AServicioMovimientos;
end;

function TCasoUsoConsolidacionFactura.Evaluar(
  const ASerie, ANumero: string;
  const ADatos: TDatosFacturaConsolidacion
): TResultadoOperacionFactura;
begin
  if not ADatos.Encontrada then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado);
  end
  else
  begin
    Result := EvaluarConsolidacionFactura(
      ASerie,
      ANumero,
      ADatos.Fase,
      ADatos.TipoFactura,
      ADatos.NifCliente,
      ADatos.NumeroLineas);
  end;
end;

function TCasoUsoConsolidacionFactura.CrearSolicitudMovimientos(
  const ASerie, ANumero, AUsuario: string;
  const ADatos: TDatosFacturaConsolidacion
): TSolicitudMovimientosFactura;
begin
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Empresa := ADatos.Empresa;
  Result.Cliente := ADatos.Cliente;
  Result.Caja := ADatos.Caja;
  Result.NumeroOperacion := ADatos.NumeroOperacion;
  Result.Fecha := ADatos.Fecha;
  Result.Usuario := AUsuario;
end;

function TCasoUsoConsolidacionFactura.Validar(
  const ASerie, ANumero: string
): TResultadoOperacionFactura;
var
  Datos: TDatosFacturaConsolidacion;
begin
  Datos := FRepositorio.CargarDatosConsolidacion(
    ASerie,
    ANumero,
    False);
  Result := Evaluar(ASerie, ANumero, Datos);
end;

function TCasoUsoConsolidacionFactura.Consolidar(
  const ASerie, ANumero, AUsuario: string
): TResultadoConsolidacionFactura;
var
  Datos: TDatosFacturaConsolidacion;
  ResultadoValidacion: TResultadoOperacionFactura;
  ResultadoFiscal: TResultadoEmisionFiscal;
  Resultado: TResultadoConsolidacionFactura;
  SolicitudFiscal: TSolicitudEmisionFiscal;
  SolicitudMovimientos: TSolicitudMovimientosFactura;
begin
  Resultado := Default(TResultadoConsolidacionFactura);
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      Datos := FRepositorio.CargarDatosConsolidacion(
        ASerie,
        ANumero,
        True);
      ResultadoValidacion := Evaluar(ASerie, ANumero, Datos);
      if not ResultadoValidacion.Exito then
        raise EConsolidacionFactura.Create(
          ResultadoValidacion.Mensaje);
      SolicitudFiscal := TSolicitudEmisionFiscal.ParaConsolidacion(
        ASerie,
        ANumero,
        AUsuario);
      ResultadoFiscal := FServicioEmision.Emitir(SolicitudFiscal);
      Resultado.MensajeFiscal := ResultadoFiscal.Mensaje;
      if FacturaDebeGenerarMovimientos(
           Datos.TipoFactura,
           Datos.MueveStock) then
      begin
        SolicitudMovimientos := CrearSolicitudMovimientos(
          ASerie,
          ANumero,
          AUsuario,
          Datos);
        Resultado.MovimientosGenerados :=
          FServicioMovimientos.GenerarSalidas(SolicitudMovimientos);
      end;
    end);
  if Resultado.MovimientosGenerados > 0 then
    SolicitarProcesadoPrestaShop;
  Result := Resultado;
end;

function CrearCasoUsoConsolidacionFactura(
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura
): ICasoUsoConsolidacionFactura;
begin
  Result := TCasoUsoConsolidacionFactura.Create(
    AUnidadTrabajo,
    ARepositorio,
    AServicioEmision,
    AServicioMovimientos);
end;

end.
