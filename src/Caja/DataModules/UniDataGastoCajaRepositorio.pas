{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataGastoCajaRepositorio                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia transaccional de gastos y retiradas de caja.                 }
{******************************************************************************}
unit UniDataGastoCajaRepositorio;

interface

uses
  Uni, inLibGastoCajaPersistenciaIntf, inLibParametrosIntf,
  inLibPreviewTicket, inLibContextoSesionIntf;

function CrearRepositorioGastoCajaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion
): IRepositorioGastoCaja;

implementation

uses
  System.SysUtils, UniDataCaja;

type
  TRepositorioGastoCajaUniDAC = class(
    TInterfacedObject,
    IRepositorioGastoCaja)
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
      const ASolicitud: TSolicitudGastoCaja): string;
  end;

function CrearRepositorioGastoCajaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion
): IRepositorioGastoCaja;
begin
  Result := TRepositorioGastoCajaUniDAC.Create(
    AConexion,
    AParametrosApp,
    AParametrosCaja,
    APreviewTicket,
    AContextoSesion);
end;

constructor TRepositorioGastoCajaUniDAC.Create(
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

function TRepositorioGastoCajaUniDAC.Registrar(
  const ASolicitud: TSolicitudGastoCaja): string;
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
          'GC',
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

end.
