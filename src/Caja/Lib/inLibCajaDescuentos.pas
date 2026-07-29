{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaDescuentos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reparte descuentos globales entre las líneas de una venta de caja.        }
{******************************************************************************}
unit inLibCajaDescuentos;

interface

uses
  Data.DB, inLibCajaVentaIntf;

type
  TRepartidorDescuento = class(TInterfacedObject, IRepartidorDescuento)
  public
    function Repartir(
      const ALineas: TArray<TLineaRepartoDescuento>;
      AImporteDescuento: Currency
    ): TArray<TResultadoLineaDescuento>;
  end;

procedure AplicarRepartoDescuentoDataSet(
  const ARepartidor: IRepartidorDescuento;
  ADataSet: TDataSet;
  AImporteDescuento: Currency);

implementation

uses
  System.Math;

function TRepartidorDescuento.Repartir(
  const ALineas: TArray<TLineaRepartoDescuento>;
  AImporteDescuento: Currency
): TArray<TResultadoLineaDescuento>;
var
  i: Integer;
  dCantidad: Double;
  dProporcion: Double;
  cDescuentoAcumulado: Currency;
  cDescuentoLinea: Currency;
  cDescuentoUnitario: Currency;
  cTotalBruto: Currency;
begin
  SetLength(Result, 0);
  cTotalBruto := 0;
  for i := 0 to High(ALineas) do
  begin
    cTotalBruto := cTotalBruto +
      (ALineas[i].Cantidad * ALineas[i].PrecioSalida);
  end;
  if (AImporteDescuento <> 0) and
     (cTotalBruto <> 0) and
     (Length(ALineas) > 0) then
  begin
    SetLength(Result, Length(ALineas));
    cDescuentoAcumulado := 0;
    for i := 0 to High(ALineas) do
    begin
      dCantidad := ALineas[i].Cantidad;
      if dCantidad = 0 then
        dCantidad := 1;
      dProporcion :=
        (dCantidad * ALineas[i].PrecioSalida) / cTotalBruto;
      if i = High(ALineas) then
      begin
        cDescuentoLinea :=
          AImporteDescuento - cDescuentoAcumulado;
      end
      else
      begin
        cDescuentoLinea :=
          SimpleRoundTo(AImporteDescuento * dProporcion, -2);
      end;
      cDescuentoUnitario := cDescuentoLinea / dCantidad;
      Result[i].ImporteDescuento := cDescuentoLinea;
      Result[i].PrecioConDescuento :=
        ALineas[i].PrecioSalida - cDescuentoUnitario;
      if ALineas[i].PrecioSalida <> 0 then
      begin
        Result[i].PorcentajeDescuento := SimpleRoundTo(
          (cDescuentoUnitario / ALineas[i].PrecioSalida) * 100,
          -2);
      end
      else
      begin
        Result[i].PorcentajeDescuento := 0;
      end;
      cDescuentoAcumulado :=
        cDescuentoAcumulado + cDescuentoLinea;
    end;
  end;
end;

procedure AplicarRepartoDescuentoDataSet(
  const ARepartidor: IRepartidorDescuento;
  ADataSet: TDataSet;
  AImporteDescuento: Currency);
var
  Lineas: TArray<TLineaRepartoDescuento>;
  Resultados: TArray<TResultadoLineaDescuento>;
  Marcador: TBookmark;
  i: Integer;
begin
  if Assigned(ARepartidor) and
     Assigned(ADataSet) and
     ADataSet.Active and
     (not ADataSet.IsEmpty) and
     (AImporteDescuento <> 0) then
  begin
    ADataSet.DisableControls;
    Marcador := ADataSet.GetBookmark;
    try
      SetLength(Lineas, ADataSet.RecordCount);
      i := 0;
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        Lineas[i].Cantidad :=
          ADataSet.FieldByName('CANTIDAD_FACLIN').AsFloat;
        Lineas[i].PrecioSalida :=
          ADataSet.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency;
        Inc(i);
        ADataSet.Next;
      end;
      Resultados := ARepartidor.Repartir(
        Lineas,
        AImporteDescuento);
      if Length(Resultados) = Length(Lineas) then
      begin
        i := 0;
        ADataSet.First;
        while not ADataSet.Eof do
        begin
          ADataSet.Edit;
          ADataSet.FieldByName(
            'PRECIO_DTO_FACLIN').AsCurrency :=
              Resultados[i].PrecioConDescuento;
          ADataSet.FieldByName(
            'PORCENTAJE_DTO_FACLIN').AsFloat :=
              Resultados[i].PorcentajeDescuento;
          ADataSet.Post;
          Inc(i);
          ADataSet.Next;
        end;
      end;
    finally
      if ADataSet.BookmarkValid(Marcador) then
        ADataSet.GotoBookmark(Marcador);
      ADataSet.FreeBookmark(Marcador);
      ADataSet.EnableControls;
    end;
  end;
end;

end.
