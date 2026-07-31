{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaVentaOperacion                                       }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Operacion de venta de caja sobre sus datasets: cierre de la linea         }
{    pendiente, deteccion de devoluciones y depositos, fecha de la             }
{    cabecera, atributos de la linea por SKU y documento del cierre.           }
{                                                                              }
{    Reune helpers que vivian enteros en TfrmMtoOpeCaja y no tocaban           }
{    ningun control. No conoce formularios, DevExpress ni UniDAC: el           }
{    lookup de atributos entra por contrato                                    }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.1 y 14.4).            }
{******************************************************************************}
unit inLibCajaVentaOperacion;

interface

uses
  Data.DB,
  inLibArticulosAtributosIntf;

type
  // Serie, tipo y fecha del documento que nace al cerrar la venta.
  TDocumentoCierreVenta = record
    Serie: string;
    TipoFactura: string;
    FechaFactura: TDateTime;
  end;

// Cierra la linea pendiente: la insercion sin articulo se cancela; la
// que tiene articulo, y cualquier edicion, se graban.
procedure CerrarLineaPendiente(ALineas: TDataSet);

// Retira la linea rechazada por una validacion de SKU: la insercion se
// cancela; la edicion se cancela y la fila se borra.
procedure EliminarLineaVentaPorValidacion(ALineas: TDataSet);

// Devolucion de venta: hay lineas en negativo que no sean operaciones
// de deposito (esas llevan su propio circuito). El flag llega de un
// CHAR de BBDD y puede traer relleno: se compara con Trim.
function HayLineasNegativasVenta(ALineas: TDataSet): Boolean;

// La venta arrastra alguna linea de deposito (prenda apartada o abono).
function HayLineasDepositoVenta(ALineas: TDataSet): Boolean;

// La operacion esta vacia; una insercion o edicion pendiente se
// cancela antes de mirar.
function OperacionVentaVacia(ALineas: TDataSet): Boolean;

// Estampa la fecha de caja en la cabecera; si estaba en reposo, graba.
procedure EscribirFechaCabeceraVenta(
  ACabecera: TDataSet;
  const AFecha: TDateTime);

// Escribe en la linea los valores ATTR1..ATTR5 de los atributos del
// SKU, segun el orden que devuelva el lookup.
procedure RellenarAtributosLineaDesdeSku(
  ALineas: TDataSet;
  const ASku: string;
  const ALookup: IArticulosAtributosLookup);

// AVs (BLANCO, 42, ...) referenciados por los SKUs del articulo para
// la columna AOrden, en el orden del tallaje.
procedure CargarAvsValidosArticulo(
  const ACodArt: string;
  AOrden: Integer;
  const ALookup: IArticulosAtributosLookup;
  var AAvs: TArray<string>);

// Documento del cierre: factura completa -> serie de factura, tipo
// NORMAL y su fecha; si no, la serie simplificada; y una devolucion
// con ticket rectificado que no acaba en factura es RECTIFICATIVA.
function ResolverDocumentoCierreVenta(
  AEsFactura: Boolean;
  const ASerieSimplificada, ASerieFactura: string;
  const AFechaFactura: TDateTime;
  AHayRectificacion: Boolean): TDocumentoCierreVenta;

implementation

uses
  System.SysUtils,
  inLibCajaVentaCliente;

procedure CerrarLineaPendiente(ALineas: TDataSet);
begin
  if ALineas.State in [dsInsert, dsEdit] then
  begin
    if (ALineas.State = dsInsert) and
       (Trim(ALineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString) = '') then
      ALineas.Cancel
    else
      ALineas.Post;
  end;
end;

procedure EliminarLineaVentaPorValidacion(ALineas: TDataSet);
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    if ALineas.State = dsInsert then
      ALineas.Cancel
    else if ALineas.State = dsEdit then
    begin
      ALineas.Cancel;
      if not ALineas.IsEmpty then
        ALineas.Delete;
    end;
  end;
end;

function HayLineasNegativasVenta(ALineas: TDataSet): Boolean;
var
  Marcador: TBookmark;
  sVieneDeDep: string;
begin
  Result := False;
  if Assigned(ALineas) and ALineas.Active then
  begin
    ALineas.DisableControls;
    try
      Marcador := ALineas.GetBookmark;
      try
        ALineas.First;
        while (not ALineas.Eof) and (not Result) do
        begin
          sVieneDeDep := Trim(
            ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString);
          if (ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat < 0) and
             (not EsLineaDeposito(sVieneDeDep)) then
            Result := True
          else
            ALineas.Next;
        end;
        if ALineas.BookmarkValid(Marcador) then
          ALineas.GotoBookmark(Marcador);
      finally
        ALineas.FreeBookmark(Marcador);
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
end;

function HayLineasDepositoVenta(ALineas: TDataSet): Boolean;
var
  Bkm: TBookmark;
begin
  Result := False;
  ALineas.DisableControls;
  Bkm := ALineas.GetBookmark;
  try
    ALineas.First;
    while (not ALineas.Eof) and (not Result) do
    begin
      if EsLineaDeposito(
           ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) then
        Result := True
      else
        ALineas.Next;
    end;
  finally
    if ALineas.BookmarkValid(Bkm) then
      ALineas.GotoBookmark(Bkm);
    ALineas.FreeBookmark(Bkm);
    ALineas.EnableControls;
  end;
end;

function OperacionVentaVacia(ALineas: TDataSet): Boolean;
begin
  Result := True;
  if Assigned(ALineas) and ALineas.Active then
  begin
    if ALineas.State in [dsEdit, dsInsert] then
      ALineas.Cancel;
    Result := ALineas.IsEmpty;
  end;
end;

procedure EscribirFechaCabeceraVenta(
  ACabecera: TDataSet;
  const AFecha: TDateTime);
var
  bPost: Boolean;
begin
  bPost := False;
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) then
  begin
    if ACabecera.State = dsBrowse then
    begin
      ACabecera.Edit;
      bPost := True;
    end;
    ACabecera.FieldByName('FECHA_FAC').AsDateTime := AFecha;
    if bPost then
      ACabecera.Post;
  end;
end;

procedure RellenarAtributosLineaDesdeSku(
  ALineas: TDataSet;
  const ASku: string;
  const ALookup: IArticulosAtributosLookup);
var
  Valores: TArray<TArticuloAtributoValor>;
  V: TArticuloAtributoValor;
  i: Integer;
begin
  if (Trim(ASku) <> '') and Assigned(ALookup) then
  begin
    Valores := ALookup.ObtenerAtributosDeSku(ASku);
    if Length(Valores) > 0 then
    begin
      if not (ALineas.State in [dsEdit, dsInsert]) then
        ALineas.Edit;
      for V in Valores do
      begin
        i := V.Orden;
        if (i >= 1) and (i <= 5) then
          ALineas.FieldByName(
            'ATTR' + IntToStr(i) + '_VALOR').AsString := V.Valor;
      end;
    end;
  end;
end;

procedure CargarAvsValidosArticulo(
  const ACodArt: string;
  AOrden: Integer;
  const ALookup: IArticulosAtributosLookup;
  var AAvs: TArray<string>);
var
  Vals: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  SetLength(AAvs, 0);
  if (Trim(ACodArt) <> '') and (AOrden >= 1) and (AOrden <= 5) and
     Assigned(ALookup) then
  begin
    Vals := ALookup.ObtenerAvsEnSkus(ACodArt, AOrden);
    SetLength(AAvs, Length(Vals));
    for i := 0 to High(Vals) do
      AAvs[i] := Vals[i].Valor;
  end;
end;

function ResolverDocumentoCierreVenta(
  AEsFactura: Boolean;
  const ASerieSimplificada, ASerieFactura: string;
  const AFechaFactura: TDateTime;
  AHayRectificacion: Boolean): TDocumentoCierreVenta;
begin
  Result.Serie := ASerieSimplificada;
  Result.TipoFactura := 'SIMPLIFICADA';
  Result.FechaFactura := 0;
  if AEsFactura then
  begin
    Result.Serie := ASerieFactura;
    Result.TipoFactura := 'NORMAL';
    Result.FechaFactura := AFechaFactura;
  end
  else if AHayRectificacion then
    Result.TipoFactura := 'RECTIFICATIVA';
end;

end.
