{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosPantalla                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Composición de repositorios por capacidades para una pantalla.           }
{******************************************************************************}
unit UniDataRepositoriosPantalla;

interface

uses
  Uni, inLibRepositoriosPantallaIntf, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf, inLibLogIntf, inLibPreviewTicket;

type
  TFabricaContextosRepositoriosPantallaUniDAC = class(
    TInterfacedObject,
    IFabricaContextosRepositoriosPantalla)
  public
    function Crear(
      const ANombrePantalla: string;
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const APerfilesLectura: ILectorPerfilesUsuario;
      const APerfilesEscritura: IEscritorPerfilesUsuario;
      const ARegistroLog: IRegistroLog;
      const APreviewTicket: IPreviewTicket
    ): IContextoRepositoriosPantalla;
  end;

  TContextoRepositoriosPantallaUniDAC = class(
    TInterfacedObject,
    IContextoRepositoriosPantalla)
  private
    FNombrePantalla: string;
    FConexionPrincipal: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FContextoSesion: IContextoSesionAplicacion;
    FPerfilesLectura: ILectorPerfilesUsuario;
    FPerfilesEscritura: IEscritorPerfilesUsuario;
    FRegistroLog: IRegistroLog;
    FPreviewTicket: IPreviewTicket;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    FRepositoriosArticulos: IRepositoriosArticulosPantalla;
    FRepositoriosConfiguracion: IRepositoriosConfiguracionPantalla;
    FRepositoriosDocumentos: IRepositoriosDocumentosPantalla;
    FRepositoriosRemesas: IRepositoriosRemesasPantalla;
    FRepositoriosOperaciones: IRepositoriosOperacionesPantalla;
    FRepositoriosVentas: IRepositoriosVentasPantalla;
    FRepositoriosCaja: IRepositoriosCajaPantalla;
    FRepositoriosTicketsCaja: IRepositoriosTicketsCajaPantalla;
    FCatalogoInicializado: Boolean;
    procedure AsegurarCatalogoSql;
    procedure AsegurarRepositoriosGenerales;
    procedure AsegurarRepositoriosCaja;
  public
    constructor Create(
      const ANombrePantalla: string;
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const APerfilesLectura: ILectorPerfilesUsuario;
      const APerfilesEscritura: IEscritorPerfilesUsuario;
      const ARegistroLog: IRegistroLog;
      const APreviewTicket: IPreviewTicket);
    destructor Destroy; override;
    function CatalogoSql: ICatalogoSql;
    function IncidenciasSql: IRegistroIncidenciasSql;
    function Articulos: IRepositoriosArticulosPantalla;
    function Configuracion: IRepositoriosConfiguracionPantalla;
    function Documentos: IRepositoriosDocumentosPantalla;
    function Remesas: IRepositoriosRemesasPantalla;
    function Operaciones: IRepositoriosOperacionesPantalla;
    function Ventas: IRepositoriosVentasPantalla;
    function Caja: IRepositoriosCajaPantalla;
    function TicketsCaja: IRepositoriosTicketsCajaPantalla;
  end;

implementation

uses
  System.SysUtils, UniDataCatalogoSqlAplicacion,
  UniDataRepositoriosGeneralesPantalla,
  UniDataRepositoriosCajaPantalla;

function TFabricaContextosRepositoriosPantallaUniDAC.Crear(
  const ANombrePantalla: string;
  AConexionPrincipal: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const APreviewTicket: IPreviewTicket
): IContextoRepositoriosPantalla;
begin
  Result := TContextoRepositoriosPantallaUniDAC.Create(
    ANombrePantalla,
    AConexionPrincipal,
    AParametrosApp,
    AParametrosCaja,
    AContextoSesion,
    APerfilesLectura,
    APerfilesEscritura,
    ARegistroLog,
    APreviewTicket);
end;

constructor TContextoRepositoriosPantallaUniDAC.Create(
  const ANombrePantalla: string;
  AConexionPrincipal: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const APreviewTicket: IPreviewTicket);
begin
  inherited Create;
  FNombrePantalla := ANombrePantalla;
  FConexionPrincipal := AConexionPrincipal;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FContextoSesion := AContextoSesion;
  FPerfilesLectura := APerfilesLectura;
  FPerfilesEscritura := APerfilesEscritura;
  FRegistroLog := ARegistroLog;
  FPreviewTicket := APreviewTicket;
  FCatalogoInicializado := False;
end;

destructor TContextoRepositoriosPantallaUniDAC.Destroy;
begin
  FRepositoriosTicketsCaja := nil;
  FRepositoriosCaja := nil;
  FRepositoriosVentas := nil;
  FRepositoriosOperaciones := nil;
  FRepositoriosRemesas := nil;
  FRepositoriosDocumentos := nil;
  FRepositoriosConfiguracion := nil;
  FRepositoriosArticulos := nil;
  FIncidenciasSql := nil;
  FCatalogoSql := nil;
  FPreviewTicket := nil;
  FRegistroLog := nil;
  FPerfilesEscritura := nil;
  FPerfilesLectura := nil;
  FContextoSesion := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  FConexionPrincipal := nil;
  inherited;
end;

procedure TContextoRepositoriosPantallaUniDAC.AsegurarCatalogoSql;
var
  bActivo: Boolean;
begin
  if not FCatalogoInicializado then
  begin
    bActivo := False;
    if Assigned(FPerfilesLectura) then
    begin
      try
        bActivo := SameText(
          FPerfilesLectura.ObtenerValorPerfil(
            FNombrePantalla, 'oGetSQLFromDB', 'False'),
          'True');
      except
        on E: Exception do
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarAviso(
              'No se pudo leer oGetSQLFromDB de ' +
              FNombrePantalla + ': ' + E.Message);
      end;
    end;
    CrearCatalogoSqlAplicacion(
      FPerfilesLectura,
      FPerfilesEscritura,
      bActivo,
      FCatalogoSql,
      FIncidenciasSql,
      FRegistroLog);
    FCatalogoInicializado := True;
  end;
end;

procedure TContextoRepositoriosPantallaUniDAC.
  AsegurarRepositoriosGenerales;
var
  oRepositorios: TRepositoriosGeneralesPantallaUniDAC;
begin
  if not Assigned(FRepositoriosArticulos) then
  begin
    AsegurarCatalogoSql;
    oRepositorios := TRepositoriosGeneralesPantallaUniDAC.Create(
      FConexionPrincipal,
      FParametrosApp,
      FParametrosCaja,
      FRegistroLog,
      FCatalogoSql,
      FIncidenciasSql);
    FRepositoriosArticulos := oRepositorios;
    FRepositoriosConfiguracion := oRepositorios;
    FRepositoriosDocumentos := oRepositorios;
    FRepositoriosRemesas := oRepositorios;
    FRepositoriosOperaciones := oRepositorios;
    FRepositoriosVentas := oRepositorios;
  end;
end;

procedure TContextoRepositoriosPantallaUniDAC.AsegurarRepositoriosCaja;
var
  oRepositorios: TRepositoriosCajaPantallaUniDAC;
begin
  if not Assigned(FRepositoriosCaja) then
  begin
    AsegurarCatalogoSql;
    oRepositorios := TRepositoriosCajaPantallaUniDAC.Create(
      FConexionPrincipal,
      FParametrosApp,
      FParametrosCaja,
      FContextoSesion,
      FPreviewTicket,
      FCatalogoSql,
      FIncidenciasSql);
    FRepositoriosCaja := oRepositorios;
    FRepositoriosTicketsCaja := oRepositorios;
  end;
end;

function TContextoRepositoriosPantallaUniDAC.CatalogoSql: ICatalogoSql;
begin
  AsegurarCatalogoSql;
  Result := FCatalogoSql;
end;

function TContextoRepositoriosPantallaUniDAC.IncidenciasSql:
  IRegistroIncidenciasSql;
begin
  AsegurarCatalogoSql;
  Result := FIncidenciasSql;
end;

function TContextoRepositoriosPantallaUniDAC.Articulos:
  IRepositoriosArticulosPantalla;
begin
  AsegurarRepositoriosGenerales;
  Result := FRepositoriosArticulos;
end;

function TContextoRepositoriosPantallaUniDAC.Configuracion:
  IRepositoriosConfiguracionPantalla;
begin
  AsegurarRepositoriosGenerales;
  Result := FRepositoriosConfiguracion;
end;

function TContextoRepositoriosPantallaUniDAC.Documentos:
  IRepositoriosDocumentosPantalla;
begin
  AsegurarRepositoriosGenerales;
  Result := FRepositoriosDocumentos;
end;

function TContextoRepositoriosPantallaUniDAC.Remesas:
  IRepositoriosRemesasPantalla;
begin
  AsegurarRepositoriosGenerales;
  Result := FRepositoriosRemesas;
end;

function TContextoRepositoriosPantallaUniDAC.Operaciones:
  IRepositoriosOperacionesPantalla;
begin
  AsegurarRepositoriosGenerales;
  Result := FRepositoriosOperaciones;
end;

function TContextoRepositoriosPantallaUniDAC.Ventas:
  IRepositoriosVentasPantalla;
begin
  AsegurarRepositoriosGenerales;
  Result := FRepositoriosVentas;
end;

function TContextoRepositoriosPantallaUniDAC.Caja:
  IRepositoriosCajaPantalla;
begin
  AsegurarRepositoriosCaja;
  Result := FRepositoriosCaja;
end;

function TContextoRepositoriosPantallaUniDAC.TicketsCaja:
  IRepositoriosTicketsCajaPantalla;
begin
  AsegurarRepositoriosCaja;
  Result := FRepositoriosTicketsCaja;
end;

end.
