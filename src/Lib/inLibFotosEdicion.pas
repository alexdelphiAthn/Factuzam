{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosEdicion                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Altas, sustituciones, rotaciones y bajas de fotografías de artículos.    }
{******************************************************************************}
unit inLibFotosEdicion;

interface

uses
  inLibFotosPersistenciaIntf, inLibFotosTipos,
  inLibFotosConsulta, inLibFotosAlmacenamiento;

type
  TEdicionFotos = class
  private
    FRepositorio   : IRepositorioEdicionFotos;
    FConsulta      : TConsultaFotos;
    FAlmacenamiento: TAlmacenamientoFotos;
  public
    constructor Create(AConsulta: TConsultaFotos;
      AAlmacenamiento: TAlmacenamientoFotos);
    procedure AsignarRepositorio(
      const ARepositorio: IRepositorioEdicionFotos);
    procedure LiberarServicios;
    function Guardar(const ACodigoArticulo, ACodigoSku,
      AFicheroOrigen, AUsuario: string): TFotoInfo;
    function Rotar(const ACodigoArticulo, ACodigoSku: string;
      AHorario: Boolean; const AUsuario: string): TFotoInfo;
    procedure Eliminar(const ACodigoArticulo,
      ACodigoUnidad: string);
  end;

implementation

uses
  System.SysUtils,
  inLibMsgArticulos;

constructor TEdicionFotos.Create(AConsulta: TConsultaFotos;
  AAlmacenamiento: TAlmacenamientoFotos);
begin
  inherited Create;
  FConsulta := AConsulta;
  FAlmacenamiento := AAlmacenamiento;
end;

procedure TEdicionFotos.AsignarRepositorio(
  const ARepositorio: IRepositorioEdicionFotos);
begin
  FRepositorio := ARepositorio;
end;

procedure TEdicionFotos.LiberarServicios;
begin
  FRepositorio := nil;
end;

function TEdicionFotos.Guardar(const ACodigoArticulo, ACodigoSku,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  oMetadatos     : TMetadatosFotoPersistida;
  sClave         : string;
  sExtension     : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  iIndice        : Integer;
  bExiste        : Boolean;
begin
  Result.Clear;
  if ACodigoArticulo = '' then
    raise Exception.Create(SErrorGuardarFotoSinCodigoArticulo);
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create(Format(SErrorFicheroOrigenFotoNoExiste,
      [AFicheroOrigen]));
  sClave := FAlmacenamiento.ClaveNombre(
    ACodigoArticulo, ACodigoSku);
  sExtension := FAlmacenamiento.ExtensionOrigen(AFicheroOrigen);
  sNombreAnterior := '';
  iIndice := 1;
  bExiste := FRepositorio.BuscarFotoEditable(
    ACodigoArticulo, ACodigoSku, oMetadatos);
  if bExiste then
  begin
    sNombreAnterior := oMetadatos.Nombre;
    iIndice := FAlmacenamiento.ExtraerIndice(sNombreAnterior) + 1;
    if iIndice < 1 then
      iIndice := 1;
  end;
  sNombreNuevo := FAlmacenamiento.ComponerNombre(
    sClave, iIndice);
  FAlmacenamiento.GuardarCopias(AFicheroOrigen, sNombreNuevo);
  try
    oMetadatos.CodigoArticulo := ACodigoArticulo;
    oMetadatos.CodigoUnidad := ACodigoSku;
    oMetadatos.Nombre := sNombreNuevo;
    oMetadatos.Extension := sExtension;
    FRepositorio.GuardarFoto(oMetadatos, AUsuario);
  except
    FAlmacenamiento.BorrarCopias(sNombreNuevo);
    raise;
  end;
  if (sNombreAnterior <> '') and
     (sNombreAnterior <> sNombreNuevo) then
    FAlmacenamiento.BorrarCopias(sNombreAnterior);
  Result.Encontrada := True;
  if ACodigoSku = '' then
    Result.Origen := foArticulo
  else
    Result.Origen := foSku;
  Result.CodigoArt := ACodigoArticulo;
  Result.CodigoSku := ACodigoSku;
  Result.ClaveResuelta := ACodigoSku;
  Result.NombreBase := sNombreNuevo;
  Result.ExtensionOrigen := sExtension;
end;

function TEdicionFotos.Rotar(const ACodigoArticulo,
  ACodigoSku: string; AHorario: Boolean;
  const AUsuario: string): TFotoInfo;
var
  oInfo          : TFotoInfo;
  sClave         : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  iIndice        : Integer;
begin
  Result.Clear;
  oInfo := FConsulta.Resolver(ACodigoArticulo, ACodigoSku);
  if not oInfo.Encontrada then
    raise Exception.Create(SErrorFotoNoRegistradaParaRotar);
  sClave := FAlmacenamiento.ClaveNombre(
    ACodigoArticulo, oInfo.ClaveResuelta);
  sNombreAnterior := oInfo.NombreBase;
  iIndice := FAlmacenamiento.ExtraerIndice(sNombreAnterior) + 1;
  if iIndice < 1 then
    iIndice := 1;
  sNombreNuevo := FAlmacenamiento.ComponerNombre(
    sClave, iIndice);
  FAlmacenamiento.RotarCopias(
    sNombreAnterior, sNombreNuevo, AHorario);
  FRepositorio.ActualizarNombreFoto(
    ACodigoArticulo, oInfo.ClaveResuelta, sNombreNuevo, AUsuario);
  Result.Encontrada := True;
  Result.Origen := oInfo.Origen;
  Result.CodigoArt := ACodigoArticulo;
  Result.CodigoSku := ACodigoSku;
  Result.ClaveResuelta := oInfo.ClaveResuelta;
  Result.NombreBase := sNombreNuevo;
  Result.ExtensionOrigen := oInfo.ExtensionOrigen;
end;

procedure TEdicionFotos.Eliminar(const ACodigoArticulo,
  ACodigoUnidad: string);
var
  sNombre: string;
begin
  sNombre := FRepositorio.BuscarNombreFoto(
    ACodigoArticulo, ACodigoUnidad);
  FAlmacenamiento.BorrarCopias(sNombre);
  FRepositorio.EliminarFoto(ACodigoArticulo, ACodigoUnidad);
end;

end.
