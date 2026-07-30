{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasConsolidacion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consolida factura y coordina fiscalidad, stock y transacción.             }
{******************************************************************************}
unit inLibFacturasConsolidacion;

interface

uses
  Uni, inLibFacturasServiciosIntf, inLibEmisionFiscalIntf;

function CrearServicioConsolidacionFactura(
  AConexion: TUniConnection;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura
): IServicioConsolidacionFactura;

implementation

uses
  System.SysUtils, Data.DB, inLibMsgFacturas;

type
  TDatosConsolidacionFactura = record
    Encontrada: Boolean;
    Fase: string;
    TipoFactura: string;
    NifCliente: string;
    Empresa: string;
    Cliente: string;
    Caja: string;
    NumeroOperacion: string;
    MueveStock: Boolean;
    NumeroLineas: Integer;
  end;
  TServicioConsolidacionFactura = class(
    TInterfacedObject,
    IServicioConsolidacionFactura)
  private
    FConexion: TUniConnection;
    FServicioEmision: IServicioEmisionFiscal;
    FServicioMovimientos: IServicioMovimientosFactura;
    function CargarDatos(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosConsolidacionFactura;
    function Evaluar(
      const ASerie, ANumero: string;
      const ADatos: TDatosConsolidacionFactura
    ): TResultadoOperacionFactura;
    function CrearSolicitudMovimientos(
      const ASerie, ANumero, AUsuario: string;
      const ADatos: TDatosConsolidacionFactura
    ): TSolicitudMovimientosFactura;
  public
    constructor Create(
      AConexion: TUniConnection;
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
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  if not Assigned(AServicioMovimientos) then
    raise EArgumentNilException.Create('AServicioMovimientos');
  FConexion := AConexion;
  FServicioEmision := AServicioEmision;
  FServicioMovimientos := AServicioMovimientos;
end;

function TServicioConsolidacionFactura.CargarDatos(
  const ASerie, ANumero: string;
  ABloquear: Boolean): TDatosConsolidacionFactura;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosConsolidacionFactura);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'SELECT FASE_FAC, TIPO_FAC, NIF_CLIENTE_FAC, ' +
      '       CODIGO_EMP_FAC, CODIGO_CLI_FAC, CODIGO_CAJA_FAC, ' +
      '       NUMERO_OPERACION_FAC, ESMUEVE_STOCK_FAC, ' +
      '       (SELECT COUNT(*) ' +
      '          FROM fza_facturas_lineas l ' +
      '         WHERE l.SERIE_FAC_FACLIN = :serie_lineas ' +
      '           AND l.NUMERO_FAC_FACLIN = :numero_lineas) ' +
      '         AS NUMERO_LINEAS ' +
      '  FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :serie ' +
      '   AND NUMERO_FAC = :numero';
    if ABloquear then
      Qry.SQL.Add(' FOR UPDATE');
    Qry.ParamByName('serie_lineas').AsString := ASerie;
    Qry.ParamByName('numero_lineas').AsString := ANumero;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.Open;
    Result.Encontrada := not Qry.IsEmpty;
    if Result.Encontrada then
    begin
      Result.Fase := Qry.FieldByName('FASE_FAC').AsString;
      Result.TipoFactura := Qry.FieldByName('TIPO_FAC').AsString;
      Result.NifCliente :=
        Qry.FieldByName('NIF_CLIENTE_FAC').AsString;
      Result.Empresa := Qry.FieldByName('CODIGO_EMP_FAC').AsString;
      Result.Cliente := Qry.FieldByName('CODIGO_CLI_FAC').AsString;
      Result.Caja := Qry.FieldByName('CODIGO_CAJA_FAC').AsString;
      Result.NumeroOperacion :=
        Qry.FieldByName('NUMERO_OPERACION_FAC').AsString;
      Result.MueveStock := SameText(
        Qry.FieldByName('ESMUEVE_STOCK_FAC').AsString,
        'S');
      Result.NumeroLineas :=
        Qry.FieldByName('NUMERO_LINEAS').AsInteger;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function TServicioConsolidacionFactura.Evaluar(
  const ASerie, ANumero: string;
  const ADatos: TDatosConsolidacionFactura
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
  const ADatos: TDatosConsolidacionFactura
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
  Datos: TDatosConsolidacionFactura;
begin
  Datos := CargarDatos(ASerie, ANumero, False);
  Result := Evaluar(ASerie, ANumero, Datos);
end;

function TServicioConsolidacionFactura.Consolidar(
  const ASerie, ANumero, AUsuario: string
): TResultadoConsolidacionFactura;
var
  Datos: TDatosConsolidacionFactura;
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
    Datos := CargarDatos(ASerie, ANumero, True);
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
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura
): IServicioConsolidacionFactura;
begin
  Result := TServicioConsolidacionFactura.Create(
    AConexion,
    AServicioEmision,
    AServicioMovimientos);
end;

end.
