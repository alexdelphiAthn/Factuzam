{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGeneracionSkus                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reglas para generar los SKU de un artículo a partir de los valores        }
{    marcados en cada dimensión (color, talla...): combinaciones, códigos      }
{    que no caben en la columna y separación de los SKU que ya existen.        }
{******************************************************************************}
unit inLibGeneracionSkus;

interface

const
  // Ancho de fza_articulos_skus.CODIGO_UNIDAD_SKU. Un INSERT IGNORE no
  // falla con un código más largo: lo trunca en silencio.
  LONGITUD_MAXIMA_CODIGO_SKU = 50;

type
  TValorDimensionSku = record
    IdValor: Integer;
    Nombre: string;
  end;

  TDimensionSku = record
    IdAtributo: string;
    Nombre: string;
    Valores: TArray<TValorDimensionSku>;
  end;

  TSkuPropuesto = record
    Codigo: string;
    IdsValores: TArray<Integer>;
  end;

// Nombres de las dimensiones que no tienen ningún valor marcado.
function DimensionesSkuSinValores(
  const ADimensiones: TArray<TDimensionSku>): TArray<string>;

// Todas las combinaciones, en el orden de las dimensiones y de sus valores:
// ART/COLOR/TALLA. Sin dimensiones, o con alguna vacía, no hay ninguna.
function CombinarSkus(
  const ACodigoArticulo: string;
  const ADimensiones: TArray<TDimensionSku>): TArray<TSkuPropuesto>;

// Códigos que superan LONGITUD_MAXIMA_CODIGO_SKU.
function CodigosSkuDemasiadoLargos(
  const APropuestos: TArray<TSkuPropuesto>): TArray<string>;

// Propuestos que no figuran entre los existentes ni están repetidos. La
// comparación no distingue mayúsculas, como la clave de la tabla.
function FiltrarSkusNuevos(
  const APropuestos: TArray<TSkuPropuesto>;
  const ACodigosExistentes: TArray<string>): TArray<TSkuPropuesto>;

function CodigosDeSkus(
  const APropuestos: TArray<TSkuPropuesto>): TArray<string>;

// Un código por línea, como mucho AMaximo; el resto se resume con
// AFormatoResto, que recibe cuántos quedan sin listar ('... y %d más').
function ResumirCodigosSku(
  const ACodigos: TArray<string>;
  AMaximo: Integer;
  const AFormatoResto: string): string;

implementation

uses
  System.SysUtils, System.Classes, System.Math;

const
  SEPARADOR_ATRIBUTOS_SKU = '/';

function DimensionesSkuSinValores(
  const ADimensiones: TArray<TDimensionSku>): TArray<string>;
var
  oDimension: TDimensionSku;
begin
  Result := nil;
  for oDimension in ADimensiones do
  begin
    if Length(oDimension.Valores) = 0 then
      Result := Result + [oDimension.Nombre];
  end;
end;

function AmpliarConDimension(
  const AParciales: TArray<TSkuPropuesto>;
  const ADimension: TDimensionSku): TArray<TSkuPropuesto>;
var
  oParcial: TSkuPropuesto;
  oValor: TValorDimensionSku;
  iDestino: Integer;
begin
  SetLength(Result, Length(AParciales) * Length(ADimension.Valores));
  iDestino := 0;
  for oParcial in AParciales do
  begin
    for oValor in ADimension.Valores do
    begin
      Result[iDestino].Codigo :=
        oParcial.Codigo + SEPARADOR_ATRIBUTOS_SKU + oValor.Nombre;
      Result[iDestino].IdsValores := oParcial.IdsValores + [oValor.IdValor];
      Inc(iDestino);
    end;
  end;
end;

function CombinarSkus(
  const ACodigoArticulo: string;
  const ADimensiones: TArray<TDimensionSku>): TArray<TSkuPropuesto>;
var
  oDimension: TDimensionSku;
begin
  Result := nil;
  if Length(ADimensiones) > 0 then
  begin
    SetLength(Result, 1);
    Result[0].Codigo := ACodigoArticulo;
    Result[0].IdsValores := nil;
    for oDimension in ADimensiones do
      Result := AmpliarConDimension(Result, oDimension);
  end;
end;

function CodigosSkuDemasiadoLargos(
  const APropuestos: TArray<TSkuPropuesto>): TArray<string>;
var
  oPropuesto: TSkuPropuesto;
begin
  Result := nil;
  for oPropuesto in APropuestos do
  begin
    if Length(oPropuesto.Codigo) > LONGITUD_MAXIMA_CODIGO_SKU then
      Result := Result + [oPropuesto.Codigo];
  end;
end;

function FiltrarSkusNuevos(
  const APropuestos: TArray<TSkuPropuesto>;
  const ACodigosExistentes: TArray<string>): TArray<TSkuPropuesto>;
var
  stVistos: TStringList;
  oPropuesto: TSkuPropuesto;
begin
  Result := nil;
  stVistos := TStringList.Create;
  try
    stVistos.CaseSensitive := False;
    stVistos.Sorted := True;
    stVistos.Duplicates := dupIgnore;
    stVistos.AddStrings(ACodigosExistentes);
    for oPropuesto in APropuestos do
    begin
      if stVistos.IndexOf(oPropuesto.Codigo) < 0 then
      begin
        stVistos.Add(oPropuesto.Codigo);
        Result := Result + [oPropuesto];
      end;
    end;
  finally
    FreeAndNil(stVistos);
  end;
end;

function CodigosDeSkus(
  const APropuestos: TArray<TSkuPropuesto>): TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, Length(APropuestos));
  for i := 0 to High(APropuestos) do
    Result[i] := APropuestos[i].Codigo;
end;

function ResumirCodigosSku(
  const ACodigos: TArray<string>;
  AMaximo: Integer;
  const AFormatoResto: string): string;
var
  i, iMostrados: Integer;
begin
  Result := '';
  iMostrados := Min(Length(ACodigos), Max(AMaximo, 0));
  for i := 0 to iMostrados - 1 do
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + ACodigos[i];
  end;
  if Length(ACodigos) > iMostrados then
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result +
      Format(AFormatoResto, [Length(ACodigos) - iMostrados]);
  end;
end;

end.
