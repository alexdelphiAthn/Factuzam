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
  System.SysUtils;

type
  TMetadatosFotoPersistida = record
    CodigoArticulo: string;
    CodigoUnidad: string;
    Nombre: string;
    Extension: string;
  end;
  TMetadatosFotoSesion = record
    CodigoArticuloTentativo: string;
    CodigoUnidad: string;
    Nombre: string;
    Extension: string;
  end;
  TMetadatosFotoSesionLote = record
    Linea: Integer;
    CodigoArticuloTentativo: string;
    CodigoUnidad: string;
    Nombre: string;
    Extension: string;
  end;
  TMetadatosFotosSesionLote = TArray<TMetadatosFotoSesionLote>;
  IRepositorioConsultaFotos = interface
    ['{B7EF7B91-B01C-4B36-8D89-121B2E2628AF}']
    function BuscarFotoPorUnidades(
      const ACodigoArticulo: string;
      const AUnidades: TArray<string>;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotoArticulo(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarPrimeraFotoUnidad(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotosArticulos(
      const ACodigosArticulo: TArray<string>):
      TArray<TMetadatosFotoPersistida>;
  end;
  IRepositorioEdicionFotos = interface
    ['{52F8D4B6-F889-4663-B8FC-1C2E9A3DB102}']
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    procedure GuardarFoto(
      const AMetadatos: TMetadatosFotoPersistida;
      const AUsuario: string);
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string): string;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string);
  end;
  IRepositorioSesionFotos = interface
    ['{9639253C-FB16-4B89-AE95-9B90C33DA476}']
    function BuscarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoSesion): Boolean;
    procedure GuardarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
        AExtension, AUsuario: string);
    procedure GuardarFotosSesionLote(
      const ASerieSesion, ANumeroSesion: string;
      const AMetadatos: TMetadatosFotosSesionLote;
      const AUsuario: string);
    procedure EliminarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string);
    function BuscarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer): TArray<TMetadatosFotoSesion>;
    procedure GuardarFotoMigrada(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
        AUsuario: string);
    procedure EliminarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer);
  end;
  TRepositoriosFotos = record
    Consulta: IRepositorioConsultaFotos;
    Edicion: IRepositorioEdicionFotos;
    Sesion: IRepositorioSesionFotos;
  end;
implementation
end.
