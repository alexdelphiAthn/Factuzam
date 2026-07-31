{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosPersistenciaIntf                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia del subsistema de fotos.                           }
{******************************************************************************}
unit inLibFotosPersistenciaIntf;

interface

uses
  System.SysUtils, Data.DB, Uni;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IRepositorioFotos = interface
    ['{C360C9AA-A8C3-4696-90CA-5EEAB982D577}']
    function BuscarFotoPorUnidades(
      const ACodigoArticulo: string;
      const AUnidades: TArray<string>): TDataSet;
    function BuscarFotoArticulo(
      const ACodigoArticulo: string): TDataSet;
    function BuscarPrimeraFotoUnidad(
      const ACodigoArticulo: string): TDataSet;
    function BuscarFotosArticulos(
      const ACodigosArticulo: TArray<string>): TDataSet;
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string): TDataSet;
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string): string;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string);
    function BuscarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string): TDataSet;
    procedure GuardarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
        AExtension, AUsuario: string);
    procedure EliminarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string);
    function BuscarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer): TDataSet;
    procedure GuardarFotoMigrada(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
        AUsuario: string);
    procedure EliminarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer);
  end;
  TFabricaCrearRepositorioFotos = function(
    AConexion: TUniConnection): IRepositorioFotos;
  TFabricaRepositorioFotos = class
  private
    class var FFabrica: TFabricaCrearRepositorioFotos;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearRepositorioFotos);
    class function Crear(
      AConexion: TUniConnection): IRepositorioFotos;
  end;

implementation

uses
  inLibMsgArticulos;

class procedure TFabricaRepositorioFotos.Registrar(
  AFabrica: TFabricaCrearRepositorioFotos);
begin
  FFabrica := AFabrica;
end;

class function TFabricaRepositorioFotos.Crear(
  AConexion: TUniConnection): IRepositorioFotos;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(SErrorPersistenciaFotosNoRegistrada);
  Result := FFabrica(AConexion);
end;

end.
