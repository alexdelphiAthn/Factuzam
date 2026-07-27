{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPresentacionDocumento                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Textos comunes de presentación para documentos de compra y venta.         }
{******************************************************************************}
unit inLibPresentacionDocumento;

interface

uses
  Data.DB;

type
  TObtenerTotalDocumento = function: Double of object;

function TextoProveedorDocumento(
  ACabecera, AProveedores: TDataSet;
  const ACampoCodigoProveedor: string): string;
function TextoTotalPrendasDocumento(
  ACabecera: TDataSet;
  AObtenerTotal: TObtenerTotalDocumento): string;

implementation

uses
  System.SysUtils;

function TextoProveedorDocumento(
  ACabecera, AProveedores: TDataSet;
  const ACampoCodigoProveedor: string): string;
var
  sCodigo: string;
  sNombre: string;
  sRazon: string;
begin
  Result := '';
  sCodigo := '';
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) then
    sCodigo := Trim(ACabecera.FieldByName(
      ACampoCodigoProveedor).AsString);
  if sCodigo <> '' then
  begin
    Result := sCodigo + ' - (proveedor no encontrado)';
    if Assigned(AProveedores) and AProveedores.Active and
       AProveedores.Locate(
         'CODIGO_PRV_PRV', sCodigo, []) then
    begin
      sRazon := AProveedores.FieldByName(
        'RAZON_SOCIAL_PRV').AsString;
      sNombre := AProveedores.FieldByName(
        'NOMBRE_PRV').AsString;
      if Trim(sNombre) = '' then
        Result := sCodigo + ' - ' + sRazon
      else if not SameText(Trim(sNombre), Trim(sRazon)) then
        Result := sCodigo + ' - ' + sNombre +
          '  (' + sRazon + ')'
      else
        Result := sCodigo + ' - ' + sNombre;
    end;
  end;
end;

function TextoTotalPrendasDocumento(
  ACabecera: TDataSet;
  AObtenerTotal: TObtenerTotalDocumento): string;
begin
  Result := '0';
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) and Assigned(AObtenerTotal) then
    Result := FormatFloat('#,##0', AObtenerTotal);
end;

end.
