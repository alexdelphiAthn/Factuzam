{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataEntradaCambioRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia transaccional de las entradas de cambio en caja.             }
{******************************************************************************}
unit UniDataEntradaCambioRepositorio;

interface

uses
  Uni, inLibEntradaCambioPersistenciaIntf, inLibParametrosIntf,
  inLibPreviewTicket, inLibContextoSesionIntf;

function CrearRepositorioEntradaCambioUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion
): IRepositorioEntradaCambio;

implementation

uses
  System.SysUtils, UniDataCaja;

type
  TRepositorioEntradaCambioUniDAC = class(
    TInterfacedObject,
    IRepositorioEntradaCambio)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FPreviewTicket: IPreviewTicket;
    FContextoSesion: IContextoSesionAplicacion;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const APreviewTicket: IPreviewTicket;
      const AContextoSesion: IContextoSesionAplicacion);
    function Registrar(
      const ASolicitud: TSolicitudEntradaCambio): string;
  end;

constructor TRepositorioEntradaCambioUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion);
begin
  inherited Create;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FPreviewTicket := APreviewTicket;
  FContextoSesion := AContextoSesion;
end;

function TRepositorioEntradaCambioUniDAC.Registrar(
  const ASolicitud: TSolicitudEntradaCambio): string;
var
  oDatosCaja: TdmCajaOpe;
  oConsulta: TUniQuery;
begin
  oDatosCaja := TdmCajaOpe.Create(
    nil,
    FConexion,
    FParametrosApp,
    FParametrosCaja,
    FPreviewTicket);
  try
    oDatosCaja.AsignarContextoSesion(FContextoSesion);
    Result := oDatosCaja.SiguienteOpCaja(
      ASolicitud.Empresa,
      ASolicitud.Almacen,
      ASolicitud.Caja,
      ASolicitud.Empleado);
    FConexion.StartTransaction;
    try
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oDatosCaja.InsertarOperacionCaja(
          oConsulta,
          ASolicitud.Empresa,
          ASolicitud.Almacen,
          ASolicitud.Caja,
          Result,
          'EC',
          ASolicitud.Importe,
          ASolicitud.Empleado,
          ASolicitud.FechaOperacion,
          '',
          '',
          '',
          ASolicitud.Concepto);
        oDatosCaja.InsertarPagoCaja(
          oConsulta,
          ASolicitud.Empresa,
          ASolicitud.Almacen,
          ASolicitud.Caja,
          '',
          Result,
          1,
          'EFE',
          ASolicitud.Importe,
          0);
      finally
        FreeAndNil(oConsulta);
      end;
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oDatosCaja);
  end;
end;

function CrearRepositorioEntradaCambioUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion
): IRepositorioEntradaCambio;
begin
  Result := TRepositorioEntradaCambioUniDAC.Create(
    AConexion,
    AParametrosApp,
    AParametrosCaja,
    APreviewTicket,
    AContextoSesion);
end;

end.
