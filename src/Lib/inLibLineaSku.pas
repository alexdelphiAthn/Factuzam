{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLineaSku                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Sincroniza el SKU y sus atributos descompuestos en la línea actual.       }
{******************************************************************************}
unit inLibLineaSku;

interface

uses
  Data.DB, inLibArticulosAtributosIntf, inLibColumnasSkuIntf;

procedure SincronizarCamposLineaSku(
  ADataSet: TDataSet;
  const ACampos: TCamposColumnasSku;
  const ACodigoArticulo, ACodigoSku: string;
  const ALookup: IArticulosAtributosLookup);

implementation

uses
  System.StrUtils, System.SysUtils;

procedure PonerTexto(ADataSet: TDataSet; const ACampo,
  AValor: string);
var
  oCampo: TField;
begin
  if (ADataSet <> nil) and (ACampo <> '') then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.ReadOnly) then
      oCampo.AsString := AValor;
  end;
end;

procedure PonerEntero(ADataSet: TDataSet; const ACampo: string;
  AValor: Integer);
var
  oCampo: TField;
begin
  if (ADataSet <> nil) and (ACampo <> '') then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.ReadOnly) then
      oCampo.AsInteger := AValor;
  end;
end;

procedure SincronizarCamposLineaSku(
  ADataSet: TDataSet;
  const ACampos: TCamposColumnasSku;
  const ACodigoArticulo, ACodigoSku: string;
  const ALookup: IArticulosAtributosLookup);
var
  aAtributos: TArray<TArticuloAtributo>;
  aPartes: TArray<string>;
  sArticulo, sNombre, sSku, sValor: string;
  i, iNumeroAtributos: Integer;
begin
  if (ADataSet <> nil) and (ADataSet.State in dsEditModes) then
  begin
    sArticulo := Trim(ACodigoArticulo);
    sSku := Trim(ACodigoSku);
    PonerTexto(ADataSet, ACampos.CodigoArt, sArticulo);
    PonerTexto(ADataSet, ACampos.CodigoUnidad, sSku);
    aPartes := nil;
    if (sArticulo <> '') and StartsText(sArticulo + '/', sSku) then
      aPartes := Copy(sSku, Length(sArticulo) + 2, MaxInt).Split(['/']);
    iNumeroAtributos := Length(aPartes);
    if iNumeroAtributos > 5 then
      iNumeroAtributos := 5;
    aAtributos := nil;
    if Assigned(ALookup) and (sArticulo <> '') then
      aAtributos := ALookup.ObtenerAtributos(sArticulo);
    PonerEntero(ADataSet, ACampos.NumAtributos, iNumeroAtributos);
    for i := 1 to 5 do
    begin
      sValor := '';
      if i <= iNumeroAtributos then
        sValor := Trim(aPartes[i - 1]);
      sNombre := '';
      if i <= Length(aAtributos) then
        sNombre := Trim(aAtributos[i - 1].NombreAtributo);
      PonerTexto(ADataSet, ACampos.AttrValor[i], sValor);
      PonerTexto(ADataSet, ACampos.AttrNombre[i], sNombre);
    end;
  end;
end;

end.
