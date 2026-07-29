{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEmisionFiscal                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selecciona y ejecuta la estrategia de emisión del modo fiscal activo.     }
{******************************************************************************}
unit inLibEmisionFiscal;

interface

uses
  Uni, inLibParametrosIntf, inLibVerifactu,
  inLibEmisionFiscalIntf;

function CrearServicioEmisionFiscal(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection
): IServicioEmisionFiscal;

function CrearServicioEmisionFiscalPorModo(
  AModo: TModoVerifactu;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection
): IServicioEmisionFiscal;

implementation

uses
  System.SysUtils, inLibVerifactuCola, inLibMsg;

type
  IEstrategiaEmisionFiscal = interface
    ['{08790CDF-5958-45D5-A3E7-15D11F100B29}']
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;
  TEstrategiaEmisionFiscalBase = class abstract(
    TInterfacedObject,
    IEstrategiaEmisionFiscal)
  private
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FConexion: TUniConnection;
    function CrearMensaje(
      const ASolicitud: TSolicitudEmisionFiscal): string;
  protected
    procedure Ejecutar(
      AQry: TUniQuery;
      const ASolicitud: TSolicitudEmisionFiscal); virtual; abstract;
    procedure RegistrarEvento(
      const ASolicitud: TSolicitudEmisionFiscal); virtual;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string;
      virtual; abstract;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string;
      virtual; abstract;
    property ParametrosApp: IParametrosAplicacion
      read FParametrosApp;
    property ParametrosCaja: IParametrosCaja
      read FParametrosCaja;
    property Conexion: TUniConnection
      read FConexion;
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConexion: TUniConnection);
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu; virtual; abstract;
  end;
  TEstrategiaEmisionVerifactu = class(
    TEstrategiaEmisionFiscalBase)
  protected
    procedure Ejecutar(
      AQry: TUniQuery;
      const ASolicitud: TSolicitudEmisionFiscal); override;
    procedure RegistrarEvento(
      const ASolicitud: TSolicitudEmisionFiscal); override;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  TEstrategiaEmisionNoVerifactu = class(
    TEstrategiaEmisionFiscalBase)
  protected
    procedure Ejecutar(
      AQry: TUniQuery;
      const ASolicitud: TSolicitudEmisionFiscal); override;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  TEstrategiaEmisionSinVerifactu = class(
    TEstrategiaEmisionFiscalBase)
  protected
    procedure Ejecutar(
      AQry: TUniQuery;
      const ASolicitud: TSolicitudEmisionFiscal); override;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  TServicioEmisionFiscal = class(
    TInterfacedObject,
    IServicioEmisionFiscal)
  private
    FEstrategia: IEstrategiaEmisionFiscal;
  public
    constructor Create(
      const AEstrategia: IEstrategiaEmisionFiscal);
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;

constructor TEstrategiaEmisionFiscalBase.Create(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FConexion := AConexion;
end;

procedure TEstrategiaEmisionFiscalBase.RegistrarEvento(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
end;

function TEstrategiaEmisionFiscalBase.CrearMensaje(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  case ASolicitud.Flujo of
    fefOperacion:
      Result := MensajeOperacion(ASolicitud);
    fefConsolidacion:
      Result := MensajeConsolidacion(ASolicitud);
  else
    raise EArgumentOutOfRangeException.Create(
      'Flujo de emisión fiscal no soportado.');
  end;
end;

function TEstrategiaEmisionFiscalBase.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal
): TResultadoEmisionFiscal;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Ejecutar(Qry, ASolicitud);
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEvento(ASolicitud);
  Result.Modo := Modo;
  Result.Mensaje := CrearMensaje(ASolicitud);
end;

procedure TEstrategiaEmisionVerifactu.Ejecutar(
  AQry: TUniQuery;
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  TVerifactuCola.EncolarFactura(
    ParametrosApp,
    ParametrosCaja,
    AQry,
    ASolicitud.Usuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.TipoOperacion,
    ASolicitud.BorrarMovimientos);
end;

procedure TEstrategiaEmisionVerifactu.RegistrarEvento(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  RegistrarEventoVerifactu(
    ParametrosApp,
    Conexion,
    ASolicitud.Usuario,
    cEventoVerifactuEncolado,
    ASolicitud.DescripcionEvento,
    '',
    ASolicitud.Serie,
    ASolicitud.Numero);
end;

function TEstrategiaEmisionVerifactu.MensajeOperacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoAccionFiscalEncolada,
    [ASolicitud.Accion]);
end;

function TEstrategiaEmisionVerifactu.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoBorradorVerifactuPendiente,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

function TEstrategiaEmisionVerifactu.Modo: TModoVerifactu;
begin
  Result := mvVerifactu;
end;

procedure TEstrategiaEmisionNoVerifactu.Ejecutar(
  AQry: TUniQuery;
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  TVerifactuCola.RegistrarFacturaNoVerifactu(
    ParametrosApp,
    ParametrosCaja,
    AQry,
    ASolicitud.Usuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.TipoOperacion,
    ASolicitud.BorrarMovimientos);
end;

function TEstrategiaEmisionNoVerifactu.MensajeOperacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoAccionFiscalNoVerifactu,
    [ASolicitud.Accion]);
end;

function TEstrategiaEmisionNoVerifactu.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoBorradorNoVerifactuRegistrado,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

function TEstrategiaEmisionNoVerifactu.Modo: TModoVerifactu;
begin
  Result := mvNoVerifactu;
end;

procedure TEstrategiaEmisionSinVerifactu.Ejecutar(
  AQry: TUniQuery;
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  TVerifactuCola.MarcarFacturaSinVerifactu(
    ParametrosApp,
    ParametrosCaja,
    AQry,
    ASolicitud.Usuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.TipoOperacion,
    ASolicitud.BorrarMovimientos);
end;

function TEstrategiaEmisionSinVerifactu.MensajeOperacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoAccionFiscalSinVerifactu,
    [ASolicitud.Accion]);
end;

function TEstrategiaEmisionSinVerifactu.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoBorradorSinVerifactuEmitido,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

function TEstrategiaEmisionSinVerifactu.Modo: TModoVerifactu;
begin
  Result := mvSinVerifactu;
end;

constructor TServicioEmisionFiscal.Create(
  const AEstrategia: IEstrategiaEmisionFiscal);
begin
  inherited Create;
  FEstrategia := AEstrategia;
end;

function TServicioEmisionFiscal.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal
): TResultadoEmisionFiscal;
begin
  Result := FEstrategia.Emitir(ASolicitud);
end;

function TServicioEmisionFiscal.Modo: TModoVerifactu;
begin
  Result := FEstrategia.Modo;
end;

function CrearServicioEmisionFiscalPorModo(
  AModo: TModoVerifactu;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection
): IServicioEmisionFiscal;
var
  Estrategia: IEstrategiaEmisionFiscal;
begin
  case AModo of
    mvVerifactu:
      Estrategia := TEstrategiaEmisionVerifactu.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion);
    mvNoVerifactu:
      Estrategia := TEstrategiaEmisionNoVerifactu.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion);
    mvSinVerifactu:
      Estrategia := TEstrategiaEmisionSinVerifactu.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion);
  else
    raise EArgumentOutOfRangeException.Create(
      'Modo de emisión fiscal no soportado.');
  end;
  Result := TServicioEmisionFiscal.Create(Estrategia);
end;

function CrearServicioEmisionFiscal(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection
): IServicioEmisionFiscal;
begin
  Result := CrearServicioEmisionFiscalPorModo(
    ModoVerifactu(AParametrosApp),
    AParametrosApp,
    AParametrosCaja,
    AConexion);
end;

end.
