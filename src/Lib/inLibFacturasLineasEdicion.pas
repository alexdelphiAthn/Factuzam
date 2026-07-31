{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasLineasEdicion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Edición de artículos, SKU, fiscalidad y precios de líneas de factura.     }
{******************************************************************************}
unit inLibFacturasLineasEdicion;

interface

uses
  System.Generics.Collections, Data.DB, Uni,
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf;

type
  TResultadoEdicionLineaFactura = record
    Aplicado: Boolean;
    RequiereSku: Boolean;
    RecalcularDesdeEditor: Boolean;
    CodigoArticulo: string;
    CodigoSku: string;
  end;

  TEditorLineasFactura = class
  private
    FCabecera: TDataSet;
    FCacheMostrarSku: TDictionary<string, Boolean>;
    FConexion: TUniConnection;
    FLineas: TDataSet;
    FResolver: IArticulosResolver;
    FValidador: IArticulosValidador;
    FAplicando: Boolean;
    function AplicarEntradaComun(
      const AEntrada: string;
      APreservarSku: Boolean
    ): TResultadoEdicionLineaFactura;
    procedure AplicarDatosArticulo(
      const ADatos: TArticuloDatos;
      const APrecio: TArticuloPrecio;
      ARequiereSku: Boolean);
    procedure AplicarPrecio(
      const ADatos: TArticuloDatos;
      const APrecio: TArticuloPrecio);
    function FechaFactura: TDateTime;
    function TarifaFactura: string;
  public
    constructor Create(
      AConexion: TUniConnection;
      ACabecera, ALineas: TDataSet;
      const AValidador: IArticulosValidador;
      const AResolver: IArticulosResolver);
    destructor Destroy; override;
    function AplicarDesdeEditor(
      const AEntrada: string
    ): TResultadoEdicionLineaFactura;
    function AplicarEntrada(
      const AEntrada: string
    ): TResultadoEdicionLineaFactura;
    procedure AplicarLineaNoCatalogo(const ACodigoArticulo: string);
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
    function PorcentajeIva(const ATipoIva: string): Double;
    function PrecioSku(
      const ACodigoArticulo, ACodigoSku: string): Double;
    procedure VaciarCache;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, inLibFacturas,
  inLibImpuestosComun;

constructor TEditorLineasFactura.Create(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver);
begin
  inherited Create;
  FConexion := AConexion;
  FCabecera := ACabecera;
  FLineas := ALineas;
  FValidador := AValidador;
  FResolver := AResolver;
  FCacheMostrarSku := TDictionary<string, Boolean>.Create;
end;

destructor TEditorLineasFactura.Destroy;
begin
  FResolver := nil;
  FValidador := nil;
  FCacheMostrarSku.Free;
  inherited;
end;

function TEditorLineasFactura.FechaFactura: TDateTime;
begin
  Result := Date;
  if Assigned(FCabecera) and FCabecera.Active and
     (FCabecera.FindField('FECHA_FAC') <> nil) and
     (not FCabecera.FieldByName('FECHA_FAC').IsNull) then
    Result := FCabecera.FieldByName('FECHA_FAC').AsDateTime;
end;

function TEditorLineasFactura.TarifaFactura: string;
begin
  Result := '';
  if Assigned(FCabecera) and FCabecera.Active and
     (FCabecera.FindField('TARIFA_ARTICULO_CLIENTE_FAC') <> nil) then
    Result := FCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
end;

function TEditorLineasFactura.PorcentajeIva(
  const ATipoIva: string): Double;
begin
  Result := 0;
  if Assigned(FCabecera) and FCabecera.Active then
    Result := PorcentajeIvaCabecera(
      FCabecera,
      'FAC',
      ATipoIva);
end;

procedure TEditorLineasFactura.AplicarPrecio(
  const ADatos: TArticuloDatos;
  const APrecio: TArticuloPrecio);
var
  Porcentaje: Double;
begin
  FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat :=
    APrecio.PrecioSalida;
  FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
    APrecio.PorcentajeDto;
  FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat :=
    APrecio.PrecioDto;
  FLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
    IfThen(APrecio.EsImpIncl, 'S', 'N');
  Porcentaje := PorcentajeIva(ADatos.TipoIVA);
  if APrecio.EsImpIncl then
  begin
    FLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
        APrecio.PrecioFinal;
    FLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
        PrecioSinIvaDesdeConIva(APrecio.PrecioFinal, Porcentaje);
  end
  else
  begin
    FLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
        APrecio.PrecioFinal;
    FLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
        PrecioConIvaDesdeSinIva(APrecio.PrecioFinal, Porcentaje);
  end;
end;

procedure TEditorLineasFactura.AplicarDatosArticulo(
  const ADatos: TArticuloDatos;
  const APrecio: TArticuloPrecio;
  ARequiereSku: Boolean);
begin
  FCacheMostrarSku.AddOrSetValue(
    ADatos.CodigoArticulo,
    ADatos.EsVariacion or ADatos.RequiereSku);
  FLineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
    ADatos.CodigoArticulo;
  if FLineas.FindField('CODIGO_UNIDAD_FACLIN') <> nil then
    FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
      ADatos.CodigoSku;
  if FLineas.FindField('DESCRIPCION_VARIACION_FACLIN') <> nil then
    FLineas.FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString :=
      ADatos.DescripcionSku;
  FLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    ADatos.DescripcionArticulo;
  if FLineas.FindField('TIPO_ARTICULO_FACLIN') <> nil then
    FLineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString :=
      ADatos.TipoArticulo;
  FLineas.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
    ADatos.TipoCantidad;
  FLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
    ADatos.TipoIVA;
  FLineas.FieldByName('CODIGO_FAM_FACLIN').AsString :=
    ADatos.CodigoFamilia;
  FLineas.FieldByName('NOMBRE_FAM_FACLIN').AsString :=
    ADatos.DescripcionFamilia;
  FLineas.FieldByName('CODIGO_TAR_FACLIN').AsString :=
    TarifaFactura;
  if ADatos.UltimoCoste.Encontrado then
  begin
    FLineas.FieldByName('ESPROVEEDORPRINCIPAL_FACLIN').AsString :=
      IfThen(ADatos.UltimoCoste.EsProveedorPrincipal, 'S', 'N');
    FLineas.FieldByName('CODIGO_PRV_FACLIN').AsString :=
      ADatos.UltimoCoste.CodigoProveedor;
    FLineas.FieldByName(
      'RAZON_SOCIAL_PROVEEDOR_FACLIN').AsString :=
        ADatos.UltimoCoste.RazonSocialProveedor;
    FLineas.FieldByName('PRECIO_ULT_COMPRA_FACLIN').AsFloat :=
      ADatos.UltimoCoste.PrecioUltCompra;
  end;
  if ARequiereSku then
  begin
    FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat := 0;
    FLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat := 0;
    FLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat := 0;
    FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
      APrecio.PorcentajeDto;
    FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat :=
      APrecio.PrecioDto;
    FLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
      IfThen(APrecio.EsImpIncl, 'S', 'N');
  end
  else
    AplicarPrecio(ADatos, APrecio);
end;

function TEditorLineasFactura.AplicarEntradaComun(
  const AEntrada: string;
  APreservarSku: Boolean): TResultadoEdicionLineaFactura;
var
  Datos: TArticuloDatos;
  DatosSku: TArticuloDatos;
  Precio: TArticuloPrecio;
  Resolucion: TArtResolucionEntrada;
  SkuAnterior: string;
begin
  Result := Default(TResultadoEdicionLineaFactura);
  if (not FAplicando) and (Trim(AEntrada) <> '') and
     Assigned(FLineas) and FLineas.Active then
  begin
    if not (FLineas.State in dsEditModes) then
    begin
      if FLineas.CanModify then
        FLineas.Edit;
    end;
    if FLineas.State in dsEditModes then
    begin
      FAplicando := True;
      try
        SkuAnterior := '';
        if APreservarSku and
           (FLineas.FindField('CODIGO_UNIDAD_FACLIN') <> nil) then
          SkuAnterior := Trim(
            FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
        Resolucion := FValidador.Resolver(Trim(AEntrada));
        if Resolucion.Encontrado then
        begin
          Datos := FResolver.ResolverDatos(
            Resolucion.CodigoArticulo,
            Resolucion.CodigoSku,
            TarifaFactura,
            FechaFactura);
          if Datos.Encontrado and Datos.RequiereSku and
             (Resolucion.CodigoSku = '') and (SkuAnterior <> '') then
          begin
            DatosSku := FResolver.ResolverDatos(
              Resolucion.CodigoArticulo,
              SkuAnterior,
              TarifaFactura,
              FechaFactura);
            if DatosSku.Encontrado and (DatosSku.CodigoSku <> '') then
              Datos := DatosSku;
          end;
          if Datos.Encontrado then
          begin
            Result.RequiereSku :=
              Datos.RequiereSku and (Datos.CodigoSku = '');
            if Result.RequiereSku then
              Precio := FResolver.ResolverPrecio(
                Resolucion.CodigoArticulo,
                '',
                TarifaFactura,
                FechaFactura)
            else
              Precio := Datos.PrecioPedido;
            AplicarDatosArticulo(Datos, Precio, Result.RequiereSku);
            Result.Aplicado := True;
            Result.RecalcularDesdeEditor := not Result.RequiereSku;
            Result.CodigoArticulo := Datos.CodigoArticulo;
            Result.CodigoSku := Datos.CodigoSku;
          end;
        end;
      finally
        FAplicando := False;
      end;
    end;
  end;
end;

function TEditorLineasFactura.AplicarDesdeEditor(
  const AEntrada: string): TResultadoEdicionLineaFactura;
begin
  Result := AplicarEntradaComun(AEntrada, True);
end;

function TEditorLineasFactura.AplicarEntrada(
  const AEntrada: string): TResultadoEdicionLineaFactura;
begin
  Result := AplicarEntradaComun(AEntrada, False);
  if Result.Aplicado and Result.RecalcularDesdeEditor then
    ActualizarLineaFactura(
      FConexion,
      FLineas,
      FCabecera,
      'PRECIO_SALIDA_FACLIN',
      FLineas.FieldByName('PRECIO_SALIDA_FACLIN').Value);
end;

procedure TEditorLineasFactura.AplicarLineaNoCatalogo(
  const ACodigoArticulo: string);
var
  Codigo: string;
begin
  Codigo := Trim(ACodigoArticulo);
  if (not FAplicando) and (Codigo <> '') and Assigned(FLineas) and
     FLineas.Active then
  begin
    if not (FLineas.State in dsEditModes) then
    begin
      if FLineas.CanModify then
        FLineas.Edit;
    end;
    if FLineas.State in dsEditModes then
    begin
      FAplicando := True;
      try
        FLineas.FieldByName('CODIGO_ART_FACLIN').AsString := Codigo;
        if FLineas.FindField('CODIGO_UNIDAD_FACLIN') <> nil then
          FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := '';
        if FLineas.FindField('DESCRIPCION_VARIACION_FACLIN') <> nil then
          FLineas.FieldByName(
            'DESCRIPCION_VARIACION_FACLIN').AsString := '';
        if Trim(FLineas.FieldByName(
             'DESCRIPCION_ARTICULO_FACLIN').AsString) = '' then
          FLineas.FieldByName(
            'DESCRIPCION_ARTICULO_FACLIN').AsString := Codigo;
        if Trim(FLineas.FieldByName(
             'TIPO_IVA_ARTICULO_FACLIN').AsString) = '' then
          FLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
            'N';
        FLineas.FieldByName('CODIGO_TAR_FACLIN').AsString :=
          TarifaFactura;
        FLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
          FCabecera.FieldByName(
            'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
        FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
        FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat := 0;
        FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat := 0;
        FLineas.FieldByName(
          'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat := 0;
        FLineas.FieldByName(
          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat := 0;
        if FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat = 0 then
          FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := 1;
        ActualizarLineaFactura(
          FConexion,
          FLineas,
          FCabecera,
          'PRECIO_SALIDA_FACLIN',
          FLineas.FieldByName('PRECIO_SALIDA_FACLIN').Value);
      finally
        FAplicando := False;
      end;
    end;
  end;
end;

function TEditorLineasFactura.DebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := True;
  if (ACodigoArticulo <> '') and
     (not FCacheMostrarSku.TryGetValue(ACodigoArticulo, Result)) then
  begin
    try
      Result := ArticuloFacturaDebeMostrarSku(
        FConexion,
        ACodigoArticulo);
      FCacheMostrarSku.AddOrSetValue(ACodigoArticulo, Result);
    except
      Result := True;
    end;
  end;
end;

function TEditorLineasFactura.PrecioSku(
  const ACodigoArticulo, ACodigoSku: string): Double;
var
  Datos: TArticuloDatos;
  Precio: TArticuloPrecio;
begin
  Result := 0;
  if Assigned(FCabecera) and FCabecera.Active then
  begin
    Datos := FResolver.ResolverDatos(
      ACodigoArticulo,
      ACodigoSku,
      TarifaFactura,
      FechaFactura);
    if Datos.Encontrado then
    begin
      Precio := Datos.PrecioPedido;
      if Precio.EsImpIncl then
        Result := Precio.PrecioFinal
      else
        Result := PrecioConIvaDesdeSinIva(
          Precio.PrecioFinal,
          PorcentajeIva(Datos.TipoIVA));
    end;
  end;
end;

procedure TEditorLineasFactura.VaciarCache;
begin
  FCacheMostrarSku.Clear;
end;

end.
