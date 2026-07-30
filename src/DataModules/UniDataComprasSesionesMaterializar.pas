{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesMaterializar                            }
{    Tipo:       Repositorio                                                   }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de persistencias del materializador de compras.          }
{******************************************************************************}
unit UniDataComprasSesionesMaterializar;

interface

uses
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesiones;

type
  TPersistenciaMaterializacionComprasSesiones = class(
    TInterfacedObject,
    IPersistenciaMaterializacionComprasSesiones,
    IPersistenciaReversionComprasSesiones)
  private
    FDataModule: TdmComprasSesiones;
    FLecturas: ILecturasMaterializacionComprasSesiones;
    FRepositorioSesiones: IRepositorioLecturasComprasSesiones;
  public
    constructor Create(
      ADataModule: TdmComprasSesiones;
      const ALecturas: ILecturasMaterializacionComprasSesiones;
      const ARepositorioSesiones:
        IRepositorioLecturasComprasSesiones);
    function ValidarMaterializacion(
      out AMensajeError: string): Boolean;
    function CargarConfiguracion:
      TConfiguracionMaterializacionSesion;
    function ConsultarAlmacenes: TArray<string>;
    function ResolverSerieDocumento(
      const AEmpresa, ATipoDocumento, AAlmacen,
      ASerieAlternativa: string): string;
    procedure MaterializarArticulos(
      const AUsuario: string);
    function MaterializarPedido(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    function MaterializarAlbaran(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    procedure CerrarSesion(
      const APedido, AAlbaran: TDocumentoMaterializado;
      const AUsuario: string);
    procedure RegistrarError(
      const AUsuario, AMensaje: string);
    function ValidarReversion(
      out AMensajeError: string): Boolean;
    procedure EjecutarReversion(
      const AUsuario: string);
  end;

implementation

uses
  System.SysUtils,
  UniDataComprasSesionesAlbaranes,
  UniDataComprasSesionesArticulos,
  UniDataComprasSesionesEstado,
  UniDataComprasSesionesPedidos,
  UniDataComprasSesionesReversion;

constructor TPersistenciaMaterializacionComprasSesiones.Create(
  ADataModule: TdmComprasSesiones;
  const ALecturas: ILecturasMaterializacionComprasSesiones;
  const ARepositorioSesiones:
    IRepositorioLecturasComprasSesiones);
begin
  inherited Create;
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  if not Assigned(ALecturas) then
    raise EArgumentNilException.Create('ALecturas');
  if not Assigned(ARepositorioSesiones) then
    raise EArgumentNilException.Create('ARepositorioSesiones');
  FDataModule := ADataModule;
  FLecturas := ALecturas;
  FRepositorioSesiones := ARepositorioSesiones;
end;

function TPersistenciaMaterializacionComprasSesiones.
  ValidarMaterializacion(
    out AMensajeError: string): Boolean;
begin
  Result := ValidarMaterializacionSesion(
    FDataModule,
    FRepositorioSesiones,
    AMensajeError);
end;

function TPersistenciaMaterializacionComprasSesiones.
  CargarConfiguracion:
    TConfiguracionMaterializacionSesion;
begin
  Result := CargarConfiguracionMaterializacion(
    FDataModule);
end;

function TPersistenciaMaterializacionComprasSesiones.
  ConsultarAlmacenes: TArray<string>;
begin
  Result := ConsultarAlmacenesMaterializacion(
    FDataModule,
    FLecturas);
end;

function TPersistenciaMaterializacionComprasSesiones.
  ResolverSerieDocumento(
    const AEmpresa, ATipoDocumento, AAlmacen,
    ASerieAlternativa: string): string;
begin
  Result := ResolverSerieMaterializacion(
    FDataModule,
    AEmpresa,
    ATipoDocumento,
    AAlmacen,
    ASerieAlternativa);
end;

procedure TPersistenciaMaterializacionComprasSesiones.
  MaterializarArticulos(
    const AUsuario: string);
begin
  MaterializarArticulosSesion(
    FDataModule,
    FLecturas,
    AUsuario);
end;

function TPersistenciaMaterializacionComprasSesiones.
  MaterializarPedido(
    const AUsuario, ASerie, AAlmacen: string):
    TDocumentoMaterializado;
begin
  Result := MaterializarPedidoSesion(
    FDataModule,
    FLecturas,
    AUsuario,
    ASerie,
    AAlmacen);
end;

function TPersistenciaMaterializacionComprasSesiones.
  MaterializarAlbaran(
    const AUsuario, ASerie, AAlmacen: string):
    TDocumentoMaterializado;
begin
  Result := MaterializarAlbaranSesion(
    FDataModule,
    FLecturas,
    AUsuario,
    ASerie,
    AAlmacen);
end;

procedure TPersistenciaMaterializacionComprasSesiones.
  CerrarSesion(
    const APedido, AAlbaran: TDocumentoMaterializado;
    const AUsuario: string);
begin
  CerrarSesionMaterializada(
    FDataModule,
    APedido,
    AAlbaran,
    AUsuario);
end;

procedure TPersistenciaMaterializacionComprasSesiones.
  RegistrarError(
    const AUsuario, AMensaje: string);
begin
  PersistirErrorMaterializacion(
    FDataModule,
    AUsuario,
    AMensaje);
end;

function TPersistenciaMaterializacionComprasSesiones.
  ValidarReversion(
    out AMensajeError: string): Boolean;
begin
  Result := ValidarReversionSesion(
    FDataModule,
    AMensajeError);
end;

procedure TPersistenciaMaterializacionComprasSesiones.
  EjecutarReversion(
    const AUsuario: string);
begin
  EjecutarReversionSesion(
    FDataModule,
    FLecturas,
    AUsuario);
end;

end.
