{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidoOcr                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura del JSON de pedidos producido por el extractor OCR Delphi.        }
{    Consolida líneas equivalentes y conserva las referencias a fotos y TIFF.  }
{******************************************************************************}
unit inLibPedidoOcr;

interface

type
  TTallaPedidoOcr = record
    Talla: string;
    Cantidad: Double;
  end;
  TTallasPedidoOcr = TArray<TTallaPedidoOcr>;
  TLineaPedidoOcr = record
    Modelo: string;
    Descripcion: string;
    Color: string;
    ColorDetectado: string;
    CodigoFoto: string;
    Tallas: TTallasPedidoOcr;
    Cantidad: Double;
    PrecioCompra: Double;
    Pvp: Double;
    TienePvp: Boolean;
    Moneda: string;
  end;
  TLineasPedidoOcr = TArray<TLineaPedidoOcr>;
  TPedidoOcr = record
    RazonSocialProveedor: string;
    ReferenciaDocumento: string;
    FechaPedido: string;
    FechaTope: string;
    Lineas: TLineasPedidoOcr;
    PaginasOriginales: TArray<string>;
    FicheroJson: string;
  end;
  TLectorPedidoOcr = class
  private
    class function LeerTextoSeguro(AObjeto: TObject;
      const AClave: string): string; static;
    class function LeerLinea(AObjeto: TObject): TLineaPedidoOcr; static;
    class function SonEquivalentes(const APrimera,
      ASegunda: TLineaPedidoOcr): Boolean; static;
    class procedure SumarTalla(var ALinea: TLineaPedidoOcr;
      const ATalla: TTallaPedidoOcr); static;
    class procedure AnadirOConsolidar(var ALineas: TLineasPedidoOcr;
      const ALinea: TLineaPedidoOcr); static;
  public
    class function Cargar(const AFicheroJson: string): TPedidoOcr; static;
  end;

function NormalizarTallaPedido(const ATalla: string): string;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Math,
  System.Generics.Collections,
  inLibJsonSeguro;

function NormalizarTallaPedido(const ATalla: string): string;
var
  cCaracter: Char;
  iCaracter: Integer;
begin
  Result := '';
  for iCaracter := 1 to Length(ATalla) do
  begin
    cCaracter := UpCase(ATalla[iCaracter]);
    if not CharInSet(cCaracter, [#9, #10, #13, ' ']) then
    begin
      if cCaracter = ',' then
        Result := Result + '.'
      else
        Result := Result + cCaracter;
    end;
  end;
end;

class function TLectorPedidoOcr.LeerTextoSeguro(AObjeto: TObject;
  const AClave: string): string;
var
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result := '';
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    oValor := oJson.GetValue(AClave);
    if Assigned(oValor) and (not (oValor is TJSONNull)) then
      Result := Trim(oValor.Value);
  end;
end;

class function TLectorPedidoOcr.LeerLinea(
  AObjeto: TObject): TLineaPedidoOcr;
var
  iTalla: Integer;
  oJson: TJSONObject;
  oListaTallas: TJSONArray;
  oTalla: TJSONObject;
  oValorPvp: TJSONValue;
  TallaLeida: TTallaPedidoOcr;
begin
  Result := Default(TLineaPedidoOcr);
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    Result.Modelo := LeerTextoSeguro(oJson, 'modelo');
    Result.Descripcion := LeerTextoSeguro(oJson, 'descripcion');
    Result.Color := LeerTextoSeguro(oJson, 'color');
    Result.ColorDetectado := LeerTextoSeguro(
      oJson, 'color_detectado');
    Result.CodigoFoto := LeerTextoSeguro(oJson, 'codigo_foto');
    Result.PrecioCompra := JsonDoubleODefecto(
      oJson, 'precio_unitario', 0);
    Result.Pvp := JsonDoubleODefecto(oJson, 'pvp', 0);
    oValorPvp := oJson.GetValue('pvp');
    Result.TienePvp := Assigned(oValorPvp) and
      (not (oValorPvp is TJSONNull)) and (Result.Pvp > 0);
    Result.Moneda := LeerTextoSeguro(oJson, 'moneda');
    if oJson.GetValue('tallas') is TJSONArray then
    begin
      oListaTallas := TJSONArray(oJson.GetValue('tallas'));
      for iTalla := 0 to oListaTallas.Count - 1 do
      begin
        if oListaTallas.Items[iTalla] is TJSONObject then
        begin
          oTalla := TJSONObject(oListaTallas.Items[iTalla]);
          TallaLeida := Default(TTallaPedidoOcr);
          TallaLeida.Talla := LeerTextoSeguro(oTalla, 'talla');
          TallaLeida.Cantidad := JsonDoubleODefecto(
            oTalla, 'cantidad', 0);
          SumarTalla(Result, TallaLeida);
        end;
      end;
    end;
  end;
end;

class function TLectorPedidoOcr.SonEquivalentes(
  const APrimera, ASegunda: TLineaPedidoOcr): Boolean;
begin
  Result := SameText(Trim(APrimera.Modelo), Trim(ASegunda.Modelo)) and
    SameText(Trim(APrimera.Color), Trim(ASegunda.Color)) and
    SameValue(APrimera.PrecioCompra, ASegunda.PrecioCompra, 0.000001) and
    (APrimera.TienePvp = ASegunda.TienePvp);
  if Result and APrimera.TienePvp then
    Result := SameValue(APrimera.Pvp, ASegunda.Pvp, 0.000001);
end;

class procedure TLectorPedidoOcr.SumarTalla(
  var ALinea: TLineaPedidoOcr;
  const ATalla: TTallaPedidoOcr);
var
  bEncontrada: Boolean;
  iTalla: Integer;
  iNueva: Integer;
begin
  bEncontrada := False;
  iTalla := 0;
  while (iTalla <= High(ALinea.Tallas)) and (not bEncontrada) do
  begin
    if NormalizarTallaPedido(ALinea.Tallas[iTalla].Talla) =
       NormalizarTallaPedido(ATalla.Talla) then
    begin
      ALinea.Tallas[iTalla].Cantidad :=
        ALinea.Tallas[iTalla].Cantidad + ATalla.Cantidad;
      bEncontrada := True;
    end;
    Inc(iTalla);
  end;
  if (not bEncontrada) and (Trim(ATalla.Talla) <> '') and
     (ATalla.Cantidad > 0) then
  begin
    iNueva := Length(ALinea.Tallas);
    SetLength(ALinea.Tallas, iNueva + 1);
    ALinea.Tallas[iNueva] := ATalla;
  end;
  ALinea.Cantidad := 0;
  for iTalla := 0 to High(ALinea.Tallas) do
    ALinea.Cantidad := ALinea.Cantidad + ALinea.Tallas[iTalla].Cantidad;
end;

class procedure TLectorPedidoOcr.AnadirOConsolidar(
  var ALineas: TLineasPedidoOcr;
  const ALinea: TLineaPedidoOcr);
var
  bConsolidada: Boolean;
  iLinea: Integer;
  iNueva: Integer;
  iTalla: Integer;
begin
  bConsolidada := False;
  iLinea := 0;
  while (iLinea <= High(ALineas)) and (not bConsolidada) do
  begin
    if SonEquivalentes(ALineas[iLinea], ALinea) then
    begin
      for iTalla := 0 to High(ALinea.Tallas) do
        SumarTalla(ALineas[iLinea], ALinea.Tallas[iTalla]);
      if ALineas[iLinea].CodigoFoto = '' then
        ALineas[iLinea].CodigoFoto := ALinea.CodigoFoto;
      if ALineas[iLinea].Descripcion = '' then
        ALineas[iLinea].Descripcion := ALinea.Descripcion;
      if ALineas[iLinea].ColorDetectado = '' then
        ALineas[iLinea].ColorDetectado := ALinea.ColorDetectado;
      bConsolidada := True;
    end;
    Inc(iLinea);
  end;
  if not bConsolidada then
  begin
    iNueva := Length(ALineas);
    SetLength(ALineas, iNueva + 1);
    ALineas[iNueva] := ALinea;
  end;
end;

class function TLectorPedidoOcr.Cargar(
  const AFicheroJson: string): TPedidoOcr;
var
  iLinea: Integer;
  iPagina: Integer;
  oDetalle: TJSONArray;
  oPagina: TJSONValue;
  oPaginas: TJSONArray;
  oProveedor: TJSONObject;
  oRaiz: TJSONObject;
  oValor: TJSONValue;
  LineaLeida: TLineaPedidoOcr;
  sContenido: string;
begin
  Result := Default(TPedidoOcr);
  if not TFile.Exists(AFicheroJson) then
    raise Exception.CreateFmt(
      'No existe el JSON del pedido: %s', [AFicheroJson]);
  sContenido := TFile.ReadAllText(AFicheroJson, TEncoding.UTF8);
  oValor := TJSONObject.ParseJSONValue(sContenido);
  try
    if not (oValor is TJSONObject) then
      raise Exception.Create('El fichero no contiene un objeto JSON válido.');
    oRaiz := TJSONObject(oValor);
    Result.FicheroJson := TPath.GetFullPath(AFicheroJson);
    Result.ReferenciaDocumento := LeerTextoSeguro(
      oRaiz, 'referencia_doc');
    Result.FechaPedido := LeerTextoSeguro(oRaiz, 'fecha_pedido');
    Result.FechaTope := LeerTextoSeguro(oRaiz, 'fecha_tope');
    if oRaiz.GetValue('proveedor') is TJSONObject then
    begin
      oProveedor := TJSONObject(oRaiz.GetValue('proveedor'));
      Result.RazonSocialProveedor := LeerTextoSeguro(
        oProveedor, 'razon_social');
    end;
    if not (oRaiz.GetValue('detalle') is TJSONArray) then
      raise Exception.Create('El JSON no contiene el array detalle.');
    oDetalle := TJSONArray(oRaiz.GetValue('detalle'));
    for iLinea := 0 to oDetalle.Count - 1 do
    begin
      if oDetalle.Items[iLinea] is TJSONObject then
      begin
        LineaLeida := LeerLinea(oDetalle.Items[iLinea]);
        if LineaLeida.Cantidad > 0 then
          AnadirOConsolidar(Result.Lineas, LineaLeida);
      end;
    end;
    if Length(Result.Lineas) = 0 then
      raise Exception.Create('El pedido no contiene líneas importables.');
    if oRaiz.GetValue('paginas_originales') is TJSONArray then
    begin
      oPaginas := TJSONArray(oRaiz.GetValue('paginas_originales'));
      for iPagina := 0 to oPaginas.Count - 1 do
      begin
        oPagina := oPaginas.Items[iPagina];
        if Assigned(oPagina) and (not (oPagina is TJSONNull)) then
        begin
          SetLength(
            Result.PaginasOriginales,
            Length(Result.PaginasOriginales) + 1);
          Result.PaginasOriginales[
            High(Result.PaginasOriginales)] := oPagina.Value;
        end;
      end;
    end;
  finally
    oValor.Free;
  end;
end;

end.
