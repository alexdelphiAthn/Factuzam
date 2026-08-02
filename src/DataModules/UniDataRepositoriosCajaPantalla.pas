{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosCajaPantalla                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Repositorios de caja y de impresión de tickets por pantalla.             }
{******************************************************************************}
unit UniDataRepositoriosCajaPantalla;

interface

uses
  Data.DB, Uni, inLibRepositoriosPantallaIntf, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibContextoSesionIntf, inLibPreviewTicket,
  inLibCajasDefectoPersistenciaIntf, inLibFaseCobroPersistenciaIntf,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPagosHistPersistenciaIntf, inLibCajaVentaIntf,
  inLibTraspasoOpePersistenciaIntf, inLibModalArqueoPersistenciaIntf,
  inLibInformesCajaPersistenciaIntf, inLibGastoCajaPersistenciaIntf,
  inLibEntradaCambioPersistenciaIntf, inLibGenerarTicketIntf,
  inLibTraspasoTicketIntf, inLibArqueoIntf, inLibArqueoPersistencia,
  inLibArqueoTicketIntf, inLibTiraCajaTicketIntf,
  inLibTicketsCajaIntf;

type
  TRepositoriosCajaPantallaUniDAC = class(
    TInterfacedObject,
    IRepositoriosCajaPantalla,
    IRepositoriosTicketsCajaPantalla)
  private
    FConexionPrincipal: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FContextoSesion: IContextoSesionAplicacion;
    FPreviewTicket: IPreviewTicket;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function Conexion(AConexion: TUniConnection): TUniConnection;
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const APreviewTicket: IPreviewTicket;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql);
    destructor Destroy; override;
    function CrearRepositorioCajasDefecto(
      AConexion: TUniConnection = nil): IRepositorioCajasDefecto;
    function CrearRepositorioFaseCobro(
      AConexion: TUniConnection = nil): IRepositorioFaseCobro;
    function CrearRepositorioCajaOperacionesHist(
      ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
    function CrearRepositorioCajaPagosHist(
      ADataSet: TDataSet): IRepositorioCajaPagosHist;
    function CrearRepositorioConsultasCaja(
      AConexion: TUniConnection = nil): IRepositorioConsultasCaja;
    function CrearRepositorioArticulosCaja(
      AConexion: TUniConnection = nil): IRepositorioArticulosCaja;
    function CrearRepositorioTraspasoOpe(
      AConexion: TUniConnection = nil): IRepositorioTraspasoOpe;
    function CrearRepositorioModalArqueo(
      AConexion: TUniConnection = nil): IRepositorioModalArqueo;
    function CrearPersistenciaArqueoCaja(
      AConexion: TUniConnection = nil): IArqueoPersistencia;
    function CrearRepositorioInformesCaja(
      AConexion: TUniConnection = nil): IRepositorioInformesCaja;
    function CrearRepositorioGastoCaja(
      AConexion: TUniConnection = nil): IRepositorioGastoCaja;
    function CrearRepositorioEntradaCambio(
      AConexion: TUniConnection = nil): IRepositorioEntradaCambio;
    function CrearLecturasImpresionTicketCaja(
      AConexion: TUniConnection = nil): ILecturasImpresionTicket;
    function CrearRepositorioTraspasoTicket(
      AConexion: TUniConnection = nil): IRepositorioTraspasoTicket;
    function CrearRepositorioArqueoCaja(
      AConexion: TUniConnection = nil): IRepositorioArqueoCaja;
    function CrearRepositorioArqueoTicket(
      AConexion: TUniConnection = nil): IRepositorioArqueoTicket;
    function CrearRepositorioTiraCajaTicket(
      AConexion: TUniConnection = nil): IRepositorioTiraCajaTicket;
    function CrearRepositorioTicketsCaja(
      AConexion: TUniConnection = nil): TRepositoriosTicketsCaja;
  end;

implementation

uses
  System.SysUtils,
  UniDataCajasDefectoRepositorio,
  UniDataFaseCobroRepositorio, UniDataCajaOperacionesHistRepositorio,
  UniDataCajaPagosHistRepositorio, UniDataCajaConsultasRepositorio,
  UniDataTraspasoOpeRepositorio, UniDataModalArqueoRepositorio,
  UniDataArqueoPersistencia, UniDataInformesCajaRepositorio,
  UniDataGastoCajaRepositorio, UniDataEntradaCambioRepositorio,
  UniDataGenerarTicketRepositorio, UniDataTraspasoTicketRepositorio,
  UniDataArqueoRepositorio, UniDataArqueoTicketRepositorio,
  UniDataTiraCajaTicketRepositorio, UniDataTicketsCajaRepositorio;

constructor TRepositoriosCajaPantallaUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const APreviewTicket: IPreviewTicket;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexionPrincipal := AConexionPrincipal;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FContextoSesion := AContextoSesion;
  FPreviewTicket := APreviewTicket;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

destructor TRepositoriosCajaPantallaUniDAC.Destroy;
begin
  FIncidenciasSql := nil;
  FCatalogoSql := nil;
  FPreviewTicket := nil;
  FContextoSesion := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  FConexionPrincipal := nil;
  inherited;
end;

function TRepositoriosCajaPantallaUniDAC.Conexion(
  AConexion: TUniConnection): TUniConnection;
begin
  Result := AConexion;
  if not Assigned(Result) then
    Result := FConexionPrincipal;
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioCajasDefecto(
  AConexion: TUniConnection): IRepositorioCajasDefecto;
begin
  Result := CrearRepositorioCajasDefectoUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioFaseCobro(
  AConexion: TUniConnection): IRepositorioFaseCobro;
begin
  Result := CrearRepositorioFaseCobroUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.
  CrearRepositorioCajaOperacionesHist(
  ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
begin
  if not (ADataSet is TUniQuery) then
    raise Exception.Create(
      'La consulta del histórico de caja no es compatible con UniDAC.');
  Result := CrearRepositorioCajaOperacionesHistUniDAC(TUniQuery(ADataSet));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioCajaPagosHist(
  ADataSet: TDataSet): IRepositorioCajaPagosHist;
begin
  if not (ADataSet is TUniQuery) then
    raise Exception.Create(
      'La consulta del histórico de pagos de caja no es compatible ' +
      'con UniDAC.');
  Result := CrearRepositorioCajaPagosHistUniDAC(TUniQuery(ADataSet));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioConsultasCaja(
  AConexion: TUniConnection): IRepositorioConsultasCaja;
begin
  Result := TRepositorioConsultasCaja.Create(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioArticulosCaja(
  AConexion: TUniConnection): IRepositorioArticulosCaja;
begin
  Result := CrearRepositorioArticulosCajaUniDAC(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioTraspasoOpe(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;
begin
  Result := CrearRepositorioTraspasoOpeUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioModalArqueo(
  AConexion: TUniConnection): IRepositorioModalArqueo;
begin
  Result := CrearRepositorioModalArqueoUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearPersistenciaArqueoCaja(
  AConexion: TUniConnection): IArqueoPersistencia;
begin
  Result := CrearPersistenciaArqueo(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioInformesCaja(
  AConexion: TUniConnection): IRepositorioInformesCaja;
begin
  Result := CrearRepositorioInformesCajaUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioGastoCaja(
  AConexion: TUniConnection): IRepositorioGastoCaja;
begin
  Result := CrearRepositorioGastoCajaUniDAC(
    Conexion(AConexion), FParametrosApp, FParametrosCaja,
    FPreviewTicket, FContextoSesion);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioEntradaCambio(
  AConexion: TUniConnection): IRepositorioEntradaCambio;
begin
  Result := CrearRepositorioEntradaCambioUniDAC(
    Conexion(AConexion), FParametrosApp, FParametrosCaja,
    FPreviewTicket, FContextoSesion);
end;

function TRepositoriosCajaPantallaUniDAC.CrearLecturasImpresionTicketCaja(
  AConexion: TUniConnection): ILecturasImpresionTicket;
begin
  Result := UniDataGenerarTicketRepositorio.CrearLecturasImpresionTicket(
    Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioTraspasoTicket(
  AConexion: TUniConnection): IRepositorioTraspasoTicket;
begin
  Result := TRepositorioTraspasoTicket.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioArqueoCaja(
  AConexion: TUniConnection): IRepositorioArqueoCaja;
begin
  Result := TRepositorioArqueoCaja.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioArqueoTicket(
  AConexion: TUniConnection): IRepositorioArqueoTicket;
begin
  Result := TRepositorioArqueoTicket.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioTiraCajaTicket(
  AConexion: TUniConnection): IRepositorioTiraCajaTicket;
begin
  Result := TRepositorioTiraCajaTicket.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioTicketsCaja(
  AConexion: TUniConnection): TRepositoriosTicketsCaja;
begin
  Result := UniDataTicketsCajaRepositorio.CrearRepositoriosTicketsCaja(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

end.
