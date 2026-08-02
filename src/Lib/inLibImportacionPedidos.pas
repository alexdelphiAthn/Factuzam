{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImportacionPedidos                                      }
{    Tipo:       Caso de uso                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina la fuente externa y la persistencia de pedidos importados.       }
{******************************************************************************}
unit inLibImportacionPedidos;

interface

uses
  inLibImportacionPedidosIntf;

function CrearCasoUsoImportacionPedidos(
  const AFabricaFuente: IFabricaFuentePedidosImportacion;
  const ARepositorio: IRepositorioImportacionPedidos
): ICasoUsoImportacionPedidos;

implementation

uses
  System.SysUtils,
  inLibPresta;

type
  TCasoUsoImportacionPedidos = class(
    TInterfacedObject,
    ICasoUsoImportacionPedidos)
  private
    FFabricaFuente: IFabricaFuentePedidosImportacion;
    FRepositorio: IRepositorioImportacionPedidos;
    procedure Notificar(
      const AOnProgreso: TProgresoImportacionPedido;
      const AIdPedido: string;
      AEstado: TEstadoImportacionPedido;
      const AError: string);
  public
    constructor Create(
      const AFabricaFuente: IFabricaFuentePedidosImportacion;
      const ARepositorio: IRepositorioImportacionPedidos);
    function Listar(
      const ABaseURL, AApiKey: string;
      ALista: TResumenPedidosImportacion): Boolean;
    function EstaImportado(const AIdPedido: string): Boolean;
    function Ejecutar(
      const ASolicitud: TSolicitudImportacionPedidos;
      const AOnProgreso: TProgresoImportacionPedido
    ): TResultadoImportacionPedidos;
  end;

constructor TCasoUsoImportacionPedidos.Create(
  const AFabricaFuente: IFabricaFuentePedidosImportacion;
  const ARepositorio: IRepositorioImportacionPedidos);
begin
  inherited Create;
  if not Assigned(AFabricaFuente) then
    raise EArgumentNilException.Create('AFabricaFuente');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FFabricaFuente := AFabricaFuente;
  FRepositorio := ARepositorio;
end;

procedure TCasoUsoImportacionPedidos.Notificar(
  const AOnProgreso: TProgresoImportacionPedido;
  const AIdPedido: string;
  AEstado: TEstadoImportacionPedido;
  const AError: string);
begin
  if Assigned(AOnProgreso) then
    AOnProgreso(AIdPedido, AEstado, AError);
end;

function TCasoUsoImportacionPedidos.Listar(
  const ABaseURL, AApiKey: string;
  ALista: TResumenPedidosImportacion): Boolean;
var
  oFuente: IFuentePedidosImportacion;
begin
  if not Assigned(ALista) then
    raise EArgumentNilException.Create('ALista');
  oFuente := FFabricaFuente.Crear(ABaseURL, AApiKey);
  Result := oFuente.ListarResumen(ALista);
end;

function TCasoUsoImportacionPedidos.EstaImportado(
  const AIdPedido: string): Boolean;
begin
  Result := FRepositorio.Existe(AIdPedido);
end;

function TCasoUsoImportacionPedidos.Ejecutar(
  const ASolicitud: TSolicitudImportacionPedidos;
  const AOnProgreso: TProgresoImportacionPedido
): TResultadoImportacionPedidos;
var
  i: Integer;
  oFuente: IFuentePedidosImportacion;
  oPedido: TOrder;
  sIdPedido: string;
begin
  Result := Default(TResultadoImportacionPedidos);
  oFuente := FFabricaFuente.Crear(
    ASolicitud.BaseURL,
    ASolicitud.ApiKey);
  for i := 0 to Length(ASolicitud.IdsPedidos) - 1 do
  begin
    sIdPedido := ASolicitud.IdsPedidos[i];
    if FRepositorio.Existe(sIdPedido) then
      Notificar(AOnProgreso, sIdPedido, eipOmitido, '')
    else
    begin
      Notificar(AOnProgreso, sIdPedido, eipImportando, '');
      try
        oPedido := oFuente.CargarPedido(sIdPedido);
        try
          if FRepositorio.Importar(oPedido) then
          begin
            Inc(Result.Importados);
            Notificar(AOnProgreso, sIdPedido, eipImportado, '');
          end
          else
            Notificar(AOnProgreso, sIdPedido, eipOmitido, '');
        finally
          FreeAndNil(oPedido);
        end;
      except
        on E: Exception do
        begin
          Inc(Result.Errores);
          Notificar(AOnProgreso, sIdPedido, eipError, E.Message);
        end;
      end;
    end;
  end;
end;

function CrearCasoUsoImportacionPedidos(
  const AFabricaFuente: IFabricaFuentePedidosImportacion;
  const ARepositorio: IRepositorioImportacionPedidos
): ICasoUsoImportacionPedidos;
begin
  Result := TCasoUsoImportacionPedidos.Create(
    AFabricaFuente,
    ARepositorio);
end;

end.
