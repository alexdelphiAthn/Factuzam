{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorCopiaLineasCompra                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona la copia comercial de líneas de sesiones de compra sin conocer  }
{    el formulario, el grid ni la persistencia de cantidades por talla.       }
{******************************************************************************}
unit inLibGestorCopiaLineasCompra;

interface

uses
  Data.DB;

type
  TModoCopiaLineaCompra = (
    mclOtroColor,
    mclOtroPrecio
  );

  TResultadoCopiaLineaCompra = record
    Aplicada: Boolean;
    LineaOrigen: Integer;
    LineaDestino: Integer;
    IdConjuntoPivot: Integer;
    CopiarCantidades: Boolean;
  end;

  TObtenerSiguienteLineaCompra = function(
    ALineaOrigen: Integer
  ): Integer of object;

  TDatosCopiaPendienteCompra = record
    Modelo: string;
    LineaOrigen: Integer;
    ColorTexto: string;
    ColorBasico: string;
    Margen: Double;
  end;

  TDatosLineaOrigenCompra = record
    Linea: Integer;
    CodigoFamilia: string;
    CodigoArticulo: string;
    ReferenciaProveedor: string;
    Descripcion: string;
    PrecioCompra: Double;
    PrecioVenta: Double;
    IdConjuntoPivot: Integer;
    Margen: Double;
    TipoIva: string;
    ColorTexto: string;
    ColorBasico: string;
  end;

  TGestorCopiaLineasCompra = class
  private
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FObtenerSiguienteLinea: TObtenerSiguienteLineaCompra;
    FDatosPendientes: TDatosCopiaPendienteCompra;
    FHayCopiaPendiente: Boolean;
    function PuedeDuplicar: Boolean;
    function PuedeAplicarPendiente: Boolean;
    function GetModeloPendiente: string;
    function GetLineaOrigenPendiente: Integer;
    function CapturarLineaActual: TDatosLineaOrigenCompra;
    procedure InsertarLineaCopiada(
      const ADatos: TDatosLineaOrigenCompra;
      AModo: TModoCopiaLineaCompra;
      ALineaSiguiente: Integer);
  public
    constructor Create(
      ACabecera: TDataSet;
      ALineas: TDataSet;
      AObtenerSiguienteLinea: TObtenerSiguienteLineaCompra);
    function DuplicarLineaActual(
      AModo: TModoCopiaLineaCompra
    ): TResultadoCopiaLineaCompra;
    procedure PrepararCopiaPendiente(
      const AModelo: string;
      ALineaOrigen: Integer;
      const AColorTexto: string;
      const AColorBasico: string;
      AMargen: Double);
    function AplicarCopiaPendiente(
      AModo: TModoCopiaLineaCompra
    ): TResultadoCopiaLineaCompra;
    procedure DescartarCopiaPendiente;
    property HayCopiaPendiente: Boolean read FHayCopiaPendiente;
    property ModeloPendiente: string read GetModeloPendiente;
    property LineaOrigenPendiente: Integer read GetLineaOrigenPendiente;
  end;

implementation

uses
  System.SysUtils;

constructor TGestorCopiaLineasCompra.Create(
  ACabecera: TDataSet;
  ALineas: TDataSet;
  AObtenerSiguienteLinea: TObtenerSiguienteLineaCompra);
begin
  inherited Create;
  FCabecera := ACabecera;
  FLineas := ALineas;
  FObtenerSiguienteLinea := AObtenerSiguienteLinea;
  DescartarCopiaPendiente;
end;

function TGestorCopiaLineasCompra.PuedeDuplicar: Boolean;
begin
  Result := Assigned(FCabecera) and Assigned(FLineas);
  if Result then
    Result := FCabecera.Active and FLineas.Active;
  if Result then
    Result := (not FCabecera.IsEmpty) and (not FLineas.IsEmpty);
end;

function TGestorCopiaLineasCompra.PuedeAplicarPendiente: Boolean;
begin
  Result := FHayCopiaPendiente and Assigned(FLineas);
  if Result then
    Result := FLineas.Active and (not FLineas.IsEmpty);
end;

function TGestorCopiaLineasCompra.GetModeloPendiente: string;
begin
  Result := FDatosPendientes.Modelo;
end;

function TGestorCopiaLineasCompra.GetLineaOrigenPendiente: Integer;
begin
  Result := FDatosPendientes.LineaOrigen;
end;

function TGestorCopiaLineasCompra.CapturarLineaActual:
  TDatosLineaOrigenCompra;
begin
  Result.Linea :=
    FLineas.FieldByName('LINEA_SESLIN').AsInteger;
  Result.CodigoFamilia :=
    FLineas.FieldByName('CODIGO_FAM_SESLIN').AsString;
  Result.CodigoArticulo :=
    FLineas.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
  Result.ReferenciaProveedor :=
    FLineas.FieldByName('REF_PRV_SESLIN').AsString;
  Result.Descripcion :=
    FLineas.FieldByName('DESCRIPCION_SESLIN').AsString;
  Result.PrecioCompra :=
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  Result.PrecioVenta :=
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
  Result.IdConjuntoPivot :=
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  Result.Margen :=
    FLineas.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  Result.TipoIva :=
    FLineas.FieldByName('TIPO_IVA_SESLIN').AsString;
  Result.ColorTexto :=
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString;
  Result.ColorBasico :=
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
end;

procedure TGestorCopiaLineasCompra.InsertarLineaCopiada(
  const ADatos: TDatosLineaOrigenCompra;
  AModo: TModoCopiaLineaCompra;
  ALineaSiguiente: Integer);
begin
  FLineas.Insert;
  FLineas.FieldByName('CODIGO_FAM_SESLIN').AsString :=
    ADatos.CodigoFamilia;
  FLineas.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString :=
    ADatos.CodigoArticulo;
  FLineas.FieldByName('REF_PRV_SESLIN').AsString :=
    ADatos.ReferenciaProveedor;
  FLineas.FieldByName('DESCRIPCION_SESLIN').AsString :=
    ADatos.Descripcion;
  if ADatos.IdConjuntoPivot > 0 then
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger :=
      ADatos.IdConjuntoPivot;
  if ADatos.Margen > 0 then
    FLineas.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat :=
      ADatos.Margen;
  if ADatos.TipoIva <> '' then
    FLineas.FieldByName('TIPO_IVA_SESLIN').AsString :=
      ADatos.TipoIva;
  if AModo = mclOtroPrecio then
  begin
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString :=
      ADatos.ColorTexto;
    if ADatos.ColorBasico <> '' then
      FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString :=
        ADatos.ColorBasico
    else
      FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat := 0;
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := 0;
  end
  else
  begin
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat :=
      ADatos.PrecioCompra;
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat :=
      ADatos.PrecioVenta;
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').Clear;
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
  end;
  FLineas.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
  FLineas.FieldByName('ACCION_DUPLICADO_SESLIN').AsString :=
    'REUSAR';
  FLineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString :=
    ADatos.CodigoArticulo;
  if (ALineaSiguiente > 0) and
     ((ALineaSiguiente - ADatos.Linea) > 1) then
    FLineas.FieldByName('LINEA_SESLIN').AsInteger :=
      (ADatos.Linea + ALineaSiguiente) div 2;
  FLineas.Post;
end;

function TGestorCopiaLineasCompra.DuplicarLineaActual(
  AModo: TModoCopiaLineaCompra): TResultadoCopiaLineaCompra;
var
  iLineaSiguiente: Integer;
  oDatos: TDatosLineaOrigenCompra;
begin
  Result.Aplicada := False;
  Result.LineaOrigen := 0;
  Result.LineaDestino := 0;
  Result.IdConjuntoPivot := 0;
  Result.CopiarCantidades := False;
  if PuedeDuplicar then
  begin
    oDatos := CapturarLineaActual;
    iLineaSiguiente := 0;
    if Assigned(FObtenerSiguienteLinea) then
      iLineaSiguiente := FObtenerSiguienteLinea(oDatos.Linea);
    if FCabecera.State in [dsInsert, dsEdit] then
      FCabecera.Post;
    if FLineas.State in [dsEdit, dsInsert] then
      FLineas.Post;
    FCabecera.Edit;
    InsertarLineaCopiada(oDatos, AModo, iLineaSiguiente);
    Result.Aplicada := True;
    Result.LineaOrigen := oDatos.Linea;
    Result.LineaDestino :=
      FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    Result.IdConjuntoPivot := oDatos.IdConjuntoPivot;
    Result.CopiarCantidades := AModo = mclOtroColor;
  end;
end;

procedure TGestorCopiaLineasCompra.PrepararCopiaPendiente(
  const AModelo: string;
  ALineaOrigen: Integer;
  const AColorTexto: string;
  const AColorBasico: string;
  AMargen: Double);
begin
  FDatosPendientes.Modelo := AModelo;
  FDatosPendientes.LineaOrigen := ALineaOrigen;
  FDatosPendientes.ColorTexto := AColorTexto;
  FDatosPendientes.ColorBasico := AColorBasico;
  FDatosPendientes.Margen := AMargen;
  FHayCopiaPendiente := ALineaOrigen > 0;
end;

function TGestorCopiaLineasCompra.AplicarCopiaPendiente(
  AModo: TModoCopiaLineaCompra): TResultadoCopiaLineaCompra;
begin
  Result.Aplicada := False;
  Result.LineaOrigen := 0;
  Result.LineaDestino := 0;
  Result.IdConjuntoPivot := 0;
  Result.CopiarCantidades := False;
  if PuedeAplicarPendiente then
  begin
    if not (FLineas.State in [dsEdit, dsInsert]) then
      FLineas.Edit;
    if FDatosPendientes.Margen > 0 then
      FLineas.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat :=
        FDatosPendientes.Margen;
    if AModo = mclOtroPrecio then
    begin
      FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString :=
        FDatosPendientes.ColorTexto;
      if FDatosPendientes.ColorBasico <> '' then
        FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString :=
          FDatosPendientes.ColorBasico
      else
        FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
      FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat := 0;
      FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := 0;
    end
    else
    begin
      FLineas.FieldByName('COLOR_TEXTO_SESLIN').Clear;
      FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
    end;
    FLineas.Post;
    Result.Aplicada := True;
    Result.LineaOrigen := FDatosPendientes.LineaOrigen;
    Result.LineaDestino :=
      FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    Result.IdConjuntoPivot :=
      FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    Result.CopiarCantidades := AModo = mclOtroColor;
  end;
end;

procedure TGestorCopiaLineasCompra.DescartarCopiaPendiente;
begin
  FDatosPendientes.Modelo := '';
  FDatosPendientes.LineaOrigen := 0;
  FDatosPendientes.ColorTexto := '';
  FDatosPendientes.ColorBasico := '';
  FDatosPendientes.Margen := 0;
  FHayCopiaPendiente := False;
end;

end.
