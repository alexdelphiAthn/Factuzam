{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPreviewExcel                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato neutral para preparar y mostrar una hoja de cálculo.             }
{    La capa de formularios registra la implementación visual al arrancar.     }
{******************************************************************************}
unit inLibPreviewExcel;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, dxSpreadSheet;

type
  TSesionPreviewExcel = class
  public
    function HojaCalculo: TdxSpreadSheet; virtual; abstract;
    procedure AsignarPopupParent(APadre: TCustomForm); virtual; abstract;
    procedure AsignarNombreArchivo(const ANombre: string); virtual; abstract;
    procedure Mostrar; virtual; abstract;
  end;

  TProveedorPreviewExcel = class
  public
    class function Crear(AOwner: TComponent): TSesionPreviewExcel;
      virtual; abstract;
  end;

  TClaseProveedorPreviewExcel = class of TProveedorPreviewExcel;

  TPreviewExcel = class
  private
    class var FClaseProveedor: TClaseProveedorPreviewExcel;
  public
    class procedure RegistrarProveedor(
      AClase: TClaseProveedorPreviewExcel);
    class function Crear(AOwner: TComponent): TSesionPreviewExcel;
  end;

implementation

uses
  inLibMsg;

class procedure TPreviewExcel.RegistrarProveedor(
  AClase: TClaseProveedorPreviewExcel);
begin
  FClaseProveedor := AClase;
end;

class function TPreviewExcel.Crear(
  AOwner: TComponent): TSesionPreviewExcel;
begin
  if not Assigned(FClaseProveedor) then
    raise Exception.Create(SErrorPreviewExcelNoRegistrado);
  Result := FClaseProveedor.Crear(AOwner);
end;

end.
