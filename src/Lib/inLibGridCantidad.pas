{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridCantidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formato de columnas de CANTIDAD en grids cx con decimales POR FILA segun  }
{    la unidad de medida de la linea. Usa OnGetDisplayText (texto por fila,    }
{    respeta el editor) + permite teclear decimales en el spin. Apoyo de       }
{    inLibUnidadesMedida para las fases de documentos.                         }
{******************************************************************************}
unit inLibGridCantidad;

interface

uses
  cxGridDBTableView;

// Vincula una columna de cantidad a su columna de unidad de medida: la celda
// mostrara los decimales que correspondan a la unidad de esa fila y el editor
// admitira decimales. AColUnidad puede ser nil (entonces decimales por defecto).
procedure VincularCantidadGrid(AColCantidad, AColUnidad: TcxGridDBColumn);

implementation

uses
  System.Classes, System.SysUtils, System.Variants, System.Math,
  cxGridCustomTableView, cxSpinEdit, inLibUnidadesMedida;

type
  TFormatoCantidadGrid = class(TComponent)
  private
    FColCantidad: TcxGridDBColumn;
    FColUnidad: TcxGridDBColumn;
    procedure GetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
  end;

procedure TFormatoCantidadGrid.GetDisplayText(Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord; var AText: string);
var
  vVal: Variant;
  vUni: Variant;
  dVal: Double;
  sUni: string;
begin
  vVal := ARecord.Values[FColCantidad.Index];
  // Celda vacia: dejamos el texto por defecto (no formateamos null).
  if not (VarIsNull(vVal) or VarIsEmpty(vVal)) then
  begin
    dVal := vVal;
    sUni := '';
    if FColUnidad <> nil then
    begin
      vUni := ARecord.Values[FColUnidad.Index];
      if not (VarIsNull(vUni) or VarIsEmpty(vUni)) then
        sUni := VarToStr(vUni);
    end;
    AText := oUnidades.Formatear(dVal, sUni);
  end;
end;

procedure VincularCantidadGrid(AColCantidad, AColUnidad: TcxGridDBColumn);
var
  oFmt: TFormatoCantidadGrid;
begin
  if AColCantidad <> nil then
  begin
    // El spin que hoy solo admite enteros pasa a admitir decimales.
    if (AColCantidad.Properties <> nil) and
       (AColCantidad.Properties is TcxSpinEditProperties) then
      TcxSpinEditProperties(AColCantidad.Properties).ValueType := vtFloat;
    // El formateador vive ligado a la columna (se libera con ella).
    oFmt := TFormatoCantidadGrid.Create(AColCantidad);
    oFmt.FColCantidad := AColCantidad;
    oFmt.FColUnidad := AColUnidad;
    AColCantidad.OnGetDisplayText := oFmt.GetDisplayText;
  end;
end;

end.
