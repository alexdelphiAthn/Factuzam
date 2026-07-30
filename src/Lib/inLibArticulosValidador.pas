{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosValidador                                       }
{    Tipo:       Fachada                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada temporal del contrato de validación de artículos.                 }
{******************************************************************************}
unit inLibArticulosValidador;

interface

uses
  Data.DB,
  Uni,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio;

type
  TArtTipoCoincidencia =
    inLibArticulosValidadorIntf.TArtTipoCoincidencia;
  TArtResolucionEntrada =
    inLibArticulosValidadorIntf.TArtResolucionEntrada;
  IArticulosValidador =
    inLibArticulosValidadorIntf.IArticulosValidador;
  TArticulosValidador =
    UniDataArticulosValidadorRepositorio.
      TRepositorioArticulosValidador;

function CrearValidadorArticulosBase(
  AConexion: TUniConnection): IArticulosValidador;
procedure NormalizarArticuloSkuEnDataSet(
  AConexion: TUniConnection;
  ADataSet: TDataSet;
  const ACampoArticulo, ACampoSku: string;
  const ACampoCodigoBarras: string = '');
function LineasSinSkuRequerido(
  AConexion: TUniConnection;
  ALineas: TDataSet;
  const ASufijo: string): string; overload;
function LineasSinSkuRequerido(
  const AValidador: IArticulosValidador;
  ALineas: TDataSet;
  const ASufijo: string): string; overload;

implementation

function CrearValidadorArticulosBase(
  AConexion: TUniConnection): IArticulosValidador;
begin
  Result := TRepositorioArticulosValidador.Create(
    AConexion);
end;

procedure NormalizarArticuloSkuEnDataSet(
  AConexion: TUniConnection;
  ADataSet: TDataSet;
  const ACampoArticulo, ACampoSku: string;
  const ACampoCodigoBarras: string);
begin
  UniDataArticulosValidadorRepositorio.
    NormalizarArticuloSkuEnDataSet(
      AConexion,
      ADataSet,
      ACampoArticulo,
      ACampoSku,
      ACampoCodigoBarras);
end;

function LineasSinSkuRequerido(
  AConexion: TUniConnection;
  ALineas: TDataSet;
  const ASufijo: string): string;
begin
  Result := UniDataArticulosValidadorRepositorio.
    LineasSinSkuRequerido(
      AConexion,
      ALineas,
      ASufijo);
end;

function LineasSinSkuRequerido(
  const AValidador: IArticulosValidador;
  ALineas: TDataSet;
  const ASufijo: string): string;
begin
  Result := UniDataArticulosValidadorRepositorio.
    LineasSinSkuRequerido(
      AValidador,
      ALineas,
      ASufijo);
end;

end.
