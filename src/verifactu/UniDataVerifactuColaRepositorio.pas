{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaRepositorio                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de la cola Verifactu: encolado con envío y emisión en    }
{    modo transitorio sin Verifactu. Las operaciones sin envío (NO             }
{    VERI*FACTU, rectificativas y relaciones) viven en                         }
{    UniDataVerifactuColaOperaciones.                                          }
{******************************************************************************}
unit UniDataVerifactuColaRepositorio;

interface

uses
  Uni, inLibVerifactuColaIntf;

function CrearServicioVerifactuColaUniDAC(
  AQry: TUniQuery): IServicioVerifactuCola; overload;
function CrearServicioVerifactuColaUniDAC(
  AConexion: TUniConnection): IServicioVerifactuCola; overload;

implementation
uses
  System.SysUtils, inLibLog, inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibVerifactu, inLibVentasWsCola, UniDataVerifactuColaOperaciones,
  UniDataVentasWsCola;
type
  TServicioVerifactuColaUniDAC = class(
    TInterfacedObject,
    IServicioVerifactuCola)
  private
    FConexion: TUniConnection;
    FQry: TUniQuery;
    FQryPropia: Boolean;
  public
    constructor Create(AQry: TUniQuery); overload;
    constructor Create(AConexion: TUniConnection); overload;
    destructor Destroy; override;
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
function CrearServicioVerifactuColaUniDAC(
  AQry: TUniQuery): IServicioVerifactuCola;
begin
  Result := TServicioVerifactuColaUniDAC.Create(AQry);
end;
function CrearServicioVerifactuColaUniDAC(
  AConexion: TUniConnection): IServicioVerifactuCola;
begin
  Result := TServicioVerifactuColaUniDAC.Create(AConexion);
end;
constructor TServicioVerifactuColaUniDAC.Create(AQry: TUniQuery);
begin
  if not Assigned(AQry) then
    raise EArgumentNilException.Create('AQry');
  if not Assigned(AQry.Connection) then
    raise EArgumentNilException.Create('AQry.Connection');
  inherited Create;
  FQry := AQry;
  FConexion := AQry.Connection;
  FQryPropia := False;
end;

constructor TServicioVerifactuColaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FQry := TUniQuery.Create(nil);
  FQry.Connection := FConexion;
  FQryPropia := True;
end;

destructor TServicioVerifactuColaUniDAC.Destroy;
begin
  if FQryPropia then
    FreeAndNil(FQry);
  FConexion := nil;
  inherited;
end;

procedure TServicioVerifactuColaUniDAC.EncolarFactura(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  // Encola el registro de una factura. FQry participa en la
  // transacción de la grabación de la venta: factura y cola se
  // confirman o deshacen juntas.
  ValidarRequisitosFiscalesEmision(AParametrosApp, FConexion,
    ASerie, ANumero);
  // ON DUPLICATE: si la operación ya estaba encolada se relanza
  // (vuelve a PENDIENTE con los intentos a cero)
  FQry.SQL.Text :=
    ' INSERT INTO fza_verifactu_cola ' +
    ' (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, TIPO_OPERACION_VFCOLA, ' +
    '  ESTADO_VFCOLA, CONTADOR_INTENTOS_VFCOLA, INSTANTE_ALTA, ' +
    '  USUARIO_ALTA) ' +
    ' VALUES ' +
    ' (:SERIE, :NUMERO, :TIPOOP, ''PENDIENTE'', 0, NOW(), :USUARIO) ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  ESTADO_VFCOLA = ''PENDIENTE'', ' +
    '  CONTADOR_INTENTOS_VFCOLA = 0, ' +
    '  INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
    '  MENSAJE_ERROR_VFCOLA = NULL, ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF  = :USUARIO';
  FQry.ParamByName('SERIE').AsString   := ASerie;
  FQry.ParamByName('NUMERO').AsString  := ANumero;
  FQry.ParamByName('TIPOOP').AsString  := ATipoOperacion;
  FQry.ParamByName('USUARIO').AsString := AUsuario;
  FQry.Execute;
  if ATipoOperacion = 'ANULACION' then
    TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
      FQry, ASerie, ANumero);
  // El lanzamiento saca la factura de BORRADOR en el acto: el QR es
  // calculable en local (ConstruirUrlQR) y la petición al ws viaja
  // asíncrona en el hilo de la cola.
  if SameText(ATipoOperacion, 'ALTA') then
  begin
    FQry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      '    SET FASE_FAC = :FASE, ' +
      '        INSTANTE_MODIF = NOW(), ' +
      '        USUARIO_MODIF  = :USUARIO ' +
      '  WHERE SERIE_FAC  = :SERIE ' +
      '    AND NUMERO_FAC = :NUMERO ' +
      '    AND (FASE_FAC IS NULL OR ' +
      '         FASE_FAC IN ('''', ''BORRADOR'', ''ERROR'', ' +
      '                       ''VERIFACTU_ERROR''))';
    FQry.ParamByName('SERIE').AsString   := ASerie;
    FQry.ParamByName('NUMERO').AsString  := ANumero;
    FQry.ParamByName('FASE').AsString    :=
      cFaseFacturaVerifactuPendiente;
    FQry.ParamByName('USUARIO').AsString := AUsuario;
    FQry.Execute;
  end;
  TVentasWsCola.RegistrarFactura(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(FQry.Connection),
    AUsuario, ASerie, ANumero, ATipoOperacion);
end;

procedure TServicioVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  TOperacionesVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
    AParametrosApp,
    AParametrosCaja,
    FQry,
    AUsuario,
    ASerie,
    ANumero,
    ATipoOperacion,
    ABorrarMovimientos);
end;

procedure TServicioVerifactuColaUniDAC.MarcarFacturaSinVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
var
  sFase: string;
begin
  // Modo transitorio sin Verifactu: emite la factura con fase propia,
  // sin cola AEAT y sin registro NO VERI*FACTU.
  ValidarRequisitosFiscalesEmision(AParametrosApp, FConexion,
    ASerie, ANumero);
  if ATipoOperacion = 'ANULACION' then
    sFase := cFaseFacturaSinVerifactuAnulada
  else
    sFase := cFaseFacturaSinVerifactu;
  FQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET ESCONSOLIDADA_FAC = ''S'', ' +
    '     INSTANTECONSO_FAC = NOW(), ' +
    '     FASE_FAC = :FASE, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  FQry.ParamByName('FASE').AsString := sFase;
  FQry.ParamByName('USUARIO').AsString := AUsuario;
  FQry.ParamByName('SERIE').AsString := ASerie;
  FQry.ParamByName('NUMERO').AsString := ANumero;
  FQry.Execute;
  if ATipoOperacion = 'ANULACION' then
    TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
      FQry, ASerie, ANumero);
  Log.LogInfo('Factura ' + ASerie + '\' + ANumero +
    ' emitida en modo SIN VERIFACTU. Operación: ' + ATipoOperacion);
  TVentasWsCola.RegistrarFactura(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(FQry.Connection),
    AUsuario, ASerie, ANumero, ATipoOperacion);
end;

procedure TServicioVerifactuColaUniDAC.BorrarMovimientosFactura(
  const ASerie, ANumero: string);
begin
  TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
    FQry,
    ASerie,
    ANumero);
end;

procedure TServicioVerifactuColaUniDAC.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
begin
  TOperacionesVerifactuColaUniDAC.EncolarRectificativa(
    AParametrosApp,
    AParametrosCaja,
    FConexion,
    AServicioEmision,
    AUsuario,
    ASerieOriginal,
    ANumeroOriginal,
    ASerieRect,
    ANumeroRect,
    ATipoRectificativa,
    ABorrarMovimientosOriginales);
end;

procedure TServicioVerifactuColaUniDAC.RegistrarRelacionFactura(
  const AUsuario, ASerie, ANumero, ASerieOrigen,
  ANumeroOrigen, ATipoRelacion: string);
begin
  TOperacionesVerifactuColaUniDAC.RegistrarRelacionFactura(
    FConexion,
    AUsuario,
    ASerie,
    ANumero,
    ASerieOrigen,
    ANumeroOrigen,
    ATipoRelacion);
end;

end.
