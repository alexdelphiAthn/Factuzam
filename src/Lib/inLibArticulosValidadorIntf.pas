{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosValidadorIntf                                   }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de validación y resolución de entradas de artículo.              }
{******************************************************************************}
unit inLibArticulosValidadorIntf;

interface

type
  TArtTipoCoincidencia = (
    atcDesconocido,
    atcCodigoArt,
    atcCodigoSku,
    atcCodigoBarras,
    atcRefProveedor
  );

  TArtResolucionEntrada = record
    EntradaOriginal: string;
    Tipo: TArtTipoCoincidencia;
    Encontrado: Boolean;
    NumCoincidencias: Integer;
    CodigoArticulo: string;
    CodigoSku: string;
    DescripcionArticulo: string;
    TipoArticulo: string;
    EsActivoArticulo: Boolean;
    EsVariacion: Boolean;
    TieneSku: Boolean;
    NumAtributosReq: Integer;
    RequiereSku: Boolean;
    SkuActivo: Boolean;
    CodigoBarrasMatch: string;
    RefProveedorMatch: string;
    CodigoProveedorMatch: string;
    Mensaje: string;
    procedure Clear;
    function ToReadable: string;
  end;

  IArticulosValidador = interface
    ['{4507912B-3135-4EC7-B073-39B28233664D}']
    function Resolver(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverCodigoBarras(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverConSku(
      const AEntrada, ACodigoSkuPreferido: string):
      TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

const
  TIPOS_LEGIBLES: array[TArtTipoCoincidencia] of string = (
    'Desconocido',
    'CodigoArt',
    'CodigoSku',
    'CodigoBarras',
    'RefProveedor'
  );

procedure TArtResolucionEntrada.Clear;
begin
  EntradaOriginal := '';
  Tipo := atcDesconocido;
  Encontrado := False;
  NumCoincidencias := 0;
  CodigoArticulo := '';
  CodigoSku := '';
  DescripcionArticulo := '';
  TipoArticulo := '';
  EsActivoArticulo := False;
  EsVariacion := False;
  TieneSku := False;
  NumAtributosReq := 0;
  RequiereSku := False;
  SkuActivo := False;
  CodigoBarrasMatch := '';
  RefProveedorMatch := '';
  CodigoProveedorMatch := '';
  Mensaje := '';
end;

function TArtResolucionEntrada.ToReadable: string;
begin
  if Encontrado then
    Result := Format(
      '[%s "%s" → ART=%s SKU=%s%s]',
      [
        TIPOS_LEGIBLES[Tipo],
        EntradaOriginal,
        CodigoArticulo,
        CodigoSku,
        IfThen(RequiereSku, ' (requiere SKU)', '')
      ])
  else
    Result := '[no encontrado: "' + EntradaOriginal + '"]';
end;

end.
