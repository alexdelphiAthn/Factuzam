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
  Uni, inLibFacturasServiciosIntf, inLibEmisionFiscalIntf,
  inLibFacturasPersistenciaIntf;

function CrearServicioConsolidacionFactura(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura
): IServicioConsolidacionFactura;

implementation

uses
  System.SysUtils, inLibMsgFacturas;

type
  TServicioConsolidacionFactura = class(
    TInterfacedObject,
    IServicioConsolidacionFactura)
  private
    FConexion: TUniConnection;
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
      AConexion: TUniConnection;
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

constructor TServicioConsolidacionFactura.Create(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  if not Assigned(AServicioMovimientos) then
    raise EArgumentNilException.Create('AServicioMovimientos');
  FConexion := AConexion;
  FRepositorio := ARepositorio;
  FServicioEmision := AServicioEmision;
  FServicioMovimientos := AServicioMovimientos;
end;

function TServicioConsolidacionFactura.Evaluar(
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

function TServicioConsolidacionFactura.CrearSolicitudMovimientos(
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
  Result.Usuario := AUsuario;
end;

function TServicioConsolidacionFactura.Validar(
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

function TServicioConsolidacionFactura.Consolidar(
  const ASerie, ANumero, AUsuario: string
): TResultadoConsolidacionFactura;
var
  Datos: TDatosFacturaConsolidacion;
  ResultadoValidacion: TResultadoOperacionFactura;
  ResultadoFiscal: TResultadoEmisionFiscal;
  SolicitudFiscal: TSolicitudEmisionFiscal;
  SolicitudMovimientos: TSolicitudMovimientosFactura;
  TransaccionPropia: Boolean;
begin
  Result.MensajeFiscal := '';
  Result.MovimientosGenerados := 0;
  TransaccionPropia := not FConexion.InTransaction;
  if TransaccionPropia then
    FConexion.StartTransaction;
  try
    Datos := FRepositorio.CargarDatosConsolidacion(
      ASerie,
      ANumero,
      True);
    ResultadoValidacion := Evaluar(ASerie, ANumero, Datos);
    if not ResultadoValidacion.Exito then
    begin
      raise EConsolidacionFactura.Create(
        ResultadoValidacion.Mensaje);
    end;
    SolicitudFiscal := TSolicitudEmisionFiscal.ParaConsolidacion(
      ASerie,
      ANumero,
      AUsuario);
    ResultadoFiscal := FServicioEmision.Emitir(SolicitudFiscal);
    Result.MensajeFiscal := ResultadoFiscal.Mensaje;
    if FacturaDebeGenerarMovimientos(
         Datos.TipoFactura,
         Datos.MueveStock) then
    begin
      SolicitudMovimientos := CrearSolicitudMovimientos(
        ASerie,
        ANumero,
        AUsuario,
        Datos);
      Result.MovimientosGenerados :=
        FServicioMovimientos.GenerarSalidas(SolicitudMovimientos);
    end;
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Commit;
  except
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function CrearServicioConsolidacionFactura(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura
): IServicioConsolidacionFactura;
begin
  Result := TServicioConsolidacionFactura.Create(
    AConexion,
    ARepositorio,
    AServicioEmision,
    AServicioMovimientos);
end;

end.
