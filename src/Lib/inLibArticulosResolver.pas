{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosResolver                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resolución consolidada de datos de artículo y tarifa.                     }
{    Devuelve precios, IVA, último coste y PMP para un artículo o SKU.         }
{******************************************************************************}
unit inLibArticulosResolver;

{
  Unidad: inLibArticulosResolver
  Descripción:
    Capa común que, dado un (CODIGO_ART_ART, CODIGO_UNIDAD_SKU, CODIGO_TAR,
    fecha) ya canónicos, devuelve los datos consolidados del artículo:

      • Datos generales (descripción, familia, IVA, tipo, variación, …).
      • Tarifa solicitada y tarifa por defecto: PRECIO_SALIDA, PRECIO_FINAL,
        PRECIO_DTO, % DTO, % MARGEN, ajustes (múltiplo / menos), si es IVA
        incluido y si la fila está vigente en la fecha pedida.
      • Último precio de compra (proveedor principal o uno concreto).
      • Precio medio ponderado (PMP) por almacén o ponderado entre todos.

    El parseo de la entrada del usuario (artículo / SKU / código de barras /
    modelo de proveedor) se hace en `inLibArticulosValidador`. Las opciones
    de atributos y propiedades en `inLibArticulosAtributosLookup`. Esta unit
    sólo trabaja con códigos ya canónicos.

  Política sobre artículos con SKUs:
    • Si el artículo tiene >1 SKU activo y el llamante no pasa SKU,
      `ResolverDatos` devuelve Encontrado=False y Mensaje pidiendo SKU. El
      llamante debe seleccionarlo (apoyándose en `inLibArticulosAtributosLookup`
      para mostrar talla/color) y volver a llamar.
    • Si el artículo tiene 1 sólo SKU activo (servicios y artículos sin
      variación: SKU autocreado con el mismo código del artículo), se
      autoresuelve a ese SKU.
    • Si no tiene ningún SKU activo, se trabaja a nivel de padre.

  Limitación conocida sobre fecha:
    `vi_articulos_tarifas` filtra internamente con CURDATE(), por lo que
    sólo expone las filas vigentes hoy. La librería evalúa el flag Vigente
    contra la fecha pedida, pero si necesitas un precio histórico o futuro
    cuya FECHA_HASTA ya está vencida hoy, la vista no devolverá registro.
    En ese caso conviene consultar directamente `fza_articulos_tarifas`.

  Origen:
    fza_articulos              fza_articulos_skus
    vi_articulos_tarifas       (alimenta el bloque de precio + tarifa)
    fza_tarifas                (tarifa por defecto del cliente / sistema)
    fza_articulos_proveedores  (último coste)
    fza_articulos_stockactual  (PMP por almacén / ponderado)
    fza_ivas_tipos             (% iva del artículo, si se pidiera)
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, Uni;

type
  TArticuloOrigenPrecio = (
    aopSinPrecio,        // no hay registro vigente en fza_articulos_tarifas
    aopHeredadoPadre,    // sólo hay registro de padre, lo aplicamos al SKU
    aopEspecificoSku     // hay registro específico del SKU
  );

  TArticuloPrecio = record
    CodigoTarifa       : string;
    NombreTarifa       : string;
    Origen             : TArticuloOrigenPrecio;
    PrecioSalida       : Double;        // PRECIO_SALIDA_ARTTAR
    PrecioFinal        : Double;        // PRECIO_FINAL_ARTTAR
    PrecioDto          : Double;        // PRECIO_DTO_ARTTAR
    PorcentajeDto      : Double;        // PORCENTAJE_DTO_ARTTAR
    PorcentajeMargen   : Double;        // efectivo (override art-tar > tarifa)
    ValorMultiploAjuste: Double;        // efectivo
    ValorMenosAjuste   : Double;        // efectivo
    EsImpIncl          : Boolean;       // ESIMP_INCL_TAR
    EsTarifaDefault    : Boolean;       // appTarifaDefecto
    FechaDesde         : TDateTime;
    FechaHasta         : TDateTime;     // 0 si abierta
    Vigente            : Boolean;       // hay fila vigente en la fecha
    TieneRegistro      : Boolean;       // hay fila (vigente o no)
    DescuentoAplicable : Boolean;       // el descuento de la tarifa cae dentro
                                        //  de su ventana de aplicacion en la
                                        //  fecha pedida (ver ventana de dto)

    procedure Clear;
  end;

  TArticuloCoste = record
    CodigoProveedor      : string;
    RazonSocialProveedor : string;
    RefProveedor         : string;
    PrecioUltCompra      : Double;
    FechaValidezCompra   : TDateTime;
    EsProveedorPrincipal : Boolean;
    Encontrado           : Boolean;

    procedure Clear;
  end;

  TArticuloPMP = record
    PrecioMedio        : Double;
    CantidadTotal      : Double;
    ValorTotal         : Double;
    NumAlmacenes       : Integer;
    AlmacenConsultado  : string;       // '' si fue ponderado de todos
    Encontrado         : Boolean;

    procedure Clear;
  end;

  TArticuloSkuItem = record
    CodigoSku      : string;     // CODIGO_UNIDAD_SKU
    // GROUP_CONCAT de los AV del SKU (ej. "NEGRO / M")
    DescripcionSku : string;
    EsActivo       : Boolean;
  end;

  TArticuloDatos = record
    Encontrado          : Boolean;
    RequiereSku         : Boolean;       // tiene >1 SKU activo y no se pasó
                                         //  uno: descripción/IVA están
                                         //  rellenos pero precio/PMP no.
    Mensaje             : string;

    CodigoArticulo      : string;
    CodigoSku           : string;
    DescripcionArticulo : string;
    DescripcionSku      : string;       // GROUP_CONCAT de los AV del SKU
    TipoArticulo        : string;       // ESTANDAR / SERVICIO / KIT
    TipoCantidad        : string;       // Uds, Kg, ...
    EsActivoArticulo    : Boolean;
    EsActivoSku         : Boolean;
    EsVariacion         : Boolean;
    TieneSku            : Boolean;
    EsTrazable          : Boolean;
    NumAtributosReq     : Integer;
    CodigoFamilia       : string;
    DescripcionFamilia  : string;
    TipoIVA             : string;       // CODIGO_ABREVIATURA_IVA_IVATIP
    TipoVariacion       : string;

    PrecioPedido        : TArticuloPrecio;   // tarifa solicitada
    PrecioTarifaDefault : TArticuloPrecio;   // tarifa de appTarifaDefecto
    UltimoCoste         : TArticuloCoste;    // proveedor principal o el pedido
    PMP                 : TArticuloPMP;      // por almacén o ponderado

    procedure Clear;
  end;

  TArticulosResolver = class
  private
    FConexion: TUniConnection;
    procedure RellenarPrecioDesdeQry(const q: TUniQuery; var P: TArticuloPrecio;
                                     const AFecha: TDateTime);
    function  TarifaDefault: string;
    function  ContarSkusActivos(const ACodigoArt: string;
                                out AUnicoSku: string): Integer;
  public
    constructor Create(AConexion: TUniConnection);

    // Pipeline completo. Si ACodigoTarifa es '', usa appTarifaDefecto.
    // Si ACodigoAlmacen es '', el PMP es ponderado entre todos los almacenes.
    function ResolverDatos(const ACodigoArt, ACodigoSku: string;
                           const ACodigoTarifa: string = '';
                           const AFecha: TDateTime = 0;
                           const ACodigoAlmacen: string = '';
                           const ACodigoProveedor: string = ''): TArticuloDatos;

    // Sólo el bloque de precio. Útil cuando el llamante ya tiene los datos
    // del artículo y sólo necesita refrescar el precio.
    function ResolverPrecio(const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
                            const AFecha: TDateTime): TArticuloPrecio;

    // Sólo el último coste. Si ACodigoSku no es '', se busca primero en
    // fza_articulos_skus_costes (coste por SKU) y se cae a proveedor si no
    // hay fila. Si el artículo no tiene SKUs, se usa proveedor principal
    // (o ACodigoProveedor si se pasa).
    function ResolverUltimoCoste(const ACodigoArt: string;
                                 const ACodigoProveedor: string = '';
                                 const ACodigoSku: string = ''): TArticuloCoste;

    // PMP. Si ACodigoAlmacen='' devuelve el promedio ponderado entre todos
    // los almacenes con stock.
    function ResolverPMP(const ACodigoSku: string;
                         const ACodigoAlmacen: string = ''): TArticuloPMP;

    // Lista los SKUs de un artículo con su descripción legible. Por defecto
    // sólo SKUs activos; pasa AIncluirInactivos=True para listar todos.
    function ListarSkus(const ACodigoArt: string;
                        AIncluirInactivos: Boolean = False): TArray<TArticuloSkuItem>;
  end;

// Predicado puro: indica si una fecha cae dentro de la ventana de aplicacion
// del descuento de una tarifa. ADesde/AHasta = 0 -> cota abierta por ese lado.
// Ambas 0 -> sin ventana: el descuento se aplica siempre (compatibilidad).
function DescuentoEnVentana(const AFecha, ADesde, AHasta: TDateTime): Boolean;

// Resuelve la ventana de descuento de una tarifa (cabecera fza_tarifas) y
// evalua si en AFecha el descuento es aplicable. Si la BBDD no tiene aun las
// columnas de ventana (script no aplicado) devuelve True (comportamiento
// clasico: el descuento se aplica siempre).
function DescuentoTarifaVigente(AConexion: TUniConnection;
                                const ACodigoTarifa: string;
                                const AFecha: TDateTime): Boolean;

implementation

uses
  inLibAppParam;

{ Helpers de records ──────────────────────────────────────────────────────── }

procedure TArticuloPrecio.Clear;
begin
  CodigoTarifa        := '';
  NombreTarifa        := '';
  Origen              := aopSinPrecio;
  PrecioSalida        := 0;
  PrecioFinal         := 0;
  PrecioDto           := 0;
  PorcentajeDto       := 0;
  PorcentajeMargen    := 0;
  ValorMultiploAjuste := 0;
  ValorMenosAjuste    := 0;
  EsImpIncl           := False;
  EsTarifaDefault     := False;
  FechaDesde          := 0;
  FechaHasta          := 0;
  Vigente             := False;
  TieneRegistro       := False;
  DescuentoAplicable  := True;
end;

procedure TArticuloCoste.Clear;
begin
  CodigoProveedor      := '';
  RazonSocialProveedor := '';
  RefProveedor         := '';
  PrecioUltCompra      := 0;
  FechaValidezCompra   := 0;
  EsProveedorPrincipal := False;
  Encontrado           := False;
end;

procedure TArticuloPMP.Clear;
begin
  PrecioMedio       := 0;
  CantidadTotal     := 0;
  ValorTotal        := 0;
  NumAlmacenes      := 0;
  AlmacenConsultado := '';
  Encontrado        := False;
end;

procedure TArticuloDatos.Clear;
begin
  Encontrado          := False;
  RequiereSku         := False;
  Mensaje             := '';
  CodigoArticulo      := '';
  CodigoSku           := '';
  DescripcionArticulo := '';
  DescripcionSku      := '';
  TipoArticulo        := '';
  TipoCantidad        := '';
  EsActivoArticulo    := False;
  EsActivoSku         := False;
  EsVariacion         := False;
  TieneSku            := False;
  EsTrazable          := False;
  NumAtributosReq     := 0;
  CodigoFamilia       := '';
  DescripcionFamilia  := '';
  TipoIVA             := '';
  TipoVariacion       := '';
  PrecioPedido.Clear;
  PrecioTarifaDefault.Clear;
  UltimoCoste.Clear;
  PMP.Clear;
end;

{ Ventana de aplicacion del descuento ──────────────────────────────────────── }

function DescuentoEnVentana(const AFecha, ADesde, AHasta: TDateTime): Boolean;
var
  dDia: TDateTime;
begin
  if (ADesde = 0) and (AHasta = 0) then
    Result := True
  else
  begin
    if AFecha = 0 then
      dDia := Trunc(Now)
    else
      dDia := Trunc(AFecha);
    Result := True;
    if (ADesde > 0) and (dDia < Trunc(ADesde)) then
      Result := False;
    if (AHasta > 0) and (dDia > Trunc(AHasta)) then
      Result := False;
  end;
end;

function DescuentoTarifaVigente(AConexion: TUniConnection;
  const ACodigoTarifa: string; const AFecha: TDateTime): Boolean;
var
  q      : TUniQuery;
  dDesde : TDateTime;
  dHasta : TDateTime;
begin
  Result := True;
  if (AConexion <> nil) and (ACodigoTarifa <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'SELECT FECHA_DESDE_DTO_TAR, FECHA_HASTA_DTO_TAR ' +
        '  FROM fza_tarifas ' +
        ' WHERE CODIGO_TAR_ARTTAR = :tar LIMIT 1';
      q.ParamByName('tar').AsString := ACodigoTarifa;
      try
        q.Open;
        if not q.IsEmpty then
        begin
          dDesde := 0;
          dHasta := 0;
          if not q.FieldByName('FECHA_DESDE_DTO_TAR').IsNull then
            dDesde := q.FieldByName('FECHA_DESDE_DTO_TAR').AsDateTime;
          if not q.FieldByName('FECHA_HASTA_DTO_TAR').IsNull then
            dHasta := q.FieldByName('FECHA_HASTA_DTO_TAR').AsDateTime;
          Result := DescuentoEnVentana(AFecha, dDesde, dHasta);
        end;
      except
        // BBDD sin columnas de ventana (script no aplicado): comportamiento
        // clasico, el descuento se aplica siempre.
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

{ TArticulosResolver ──────────────────────────────────────────────────────── }

constructor TArticulosResolver.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TArticulosResolver.TarifaDefault: string;
begin
  Result := oAppParams.GetString('appTarifaDefecto', 'PVP');
end;

function TArticulosResolver.ContarSkusActivos(const ACodigoArt: string;
  out AUnicoSku: string): Integer;
var q: TUniQuery;
begin
  Result    := 0;
  AUnicoSku := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
      ' WHERE CODIGO_ART_SKU = :art AND ESACTIVO_SKU = ''S''';
    q.ParamByName('art').AsString := ACodigoArt;
    q.Open;
    while not q.Eof do
    begin
      Inc(Result);
      if Result = 1 then AUnicoSku :=
        q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      q.Next;
    end;
    if Result > 1 then AUnicoSku := '';
  finally
    FreeAndNil(q);
  end;
end;

procedure TArticulosResolver.RellenarPrecioDesdeQry(const q: TUniQuery;
  var P: TArticuloPrecio; const AFecha: TDateTime);
var
  sOrigen: string;
  dHasta : TDateTime;
begin
  P.TieneRegistro    := True;
  P.CodigoTarifa     := q.FieldByName('CODIGO_TAR_ARTTAR').AsString;
  P.NombreTarifa     := q.FieldByName('NOMBRE_TAR_TAR').AsString;
  P.PrecioSalida     := q.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
  P.PrecioFinal      := q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
  P.PrecioDto        := q.FieldByName('PRECIO_DTO_ARTTAR').AsFloat;
  P.PorcentajeDto    := q.FieldByName('PORCENTAJE_DTO_ARTTAR').AsFloat;
  P.PorcentajeMargen := q.FieldByName('PORCENTAJE_MARGEN_EFECTIVO').AsFloat;
  P.ValorMultiploAjuste :=
                       q.FieldByName('VALOR_MULTIPLO_AJUSTE_EFECTIVO').AsFloat;
  P.ValorMenosAjuste := q.FieldByName('VALOR_MENOS_AJUSTE_EFECTIVO').AsFloat;
  P.EsImpIncl        := q.FieldByName('ESIMP_INCL_TAR').AsString = 'S';
  P.EsTarifaDefault  := SameText(q.FieldByName('CODIGO_TAR_ARTTAR').AsString,
                                     oAppParams.GetString('appTarifaDefecto', 'PVP'));
  if not q.FieldByName('FECHA_DESDE_ARTTAR').IsNull then
    P.FechaDesde     := q.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime;
  if not q.FieldByName('FECHA_HASTA_ARTTAR').IsNull then
    P.FechaHasta     := q.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime;

  sOrigen := q.FieldByName('ORIGEN_PRECIO').AsString;
  if      sOrigen = 'ESPECIFICO_SKU' then P.Origen := aopEspecificoSku
  else if sOrigen = 'HEREDADO_PADRE' then P.Origen := aopHeredadoPadre
  else                                    P.Origen := aopSinPrecio;

  if AFecha = 0 then dHasta := Now else dHasta := AFecha;
  P.Vigente :=
    ((P.FechaDesde = 0) or (P.FechaDesde <= dHasta)) and
    ((P.FechaHasta = 0) or (P.FechaHasta >= dHasta));
end;

function TArticulosResolver.ResolverPrecio(const ACodigoArt, ACodigoSku,
  ACodigoTarifa: string; const AFecha: TDateTime): TArticuloPrecio;
var
  q      : TUniQuery;
  dFecha : TDateTime;
begin
  Result.Clear;
  if ACodigoArt = '' then
    Exit;
  Result.CodigoTarifa := ACodigoTarifa;
  if AFecha = 0 then
    dFecha := Now
  else
    dFecha := AFecha;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT t.CODIGO_TAR_ARTTAR, ' +
      '       tar.NOMBRE_TAR_TAR, ' +
      '       CASE WHEN t.CODIGO_UNIDAD_ARTTAR = :sku AND :sku <> '''' ' +
      '            THEN ''ESPECIFICO_SKU'' ELSE ''HEREDADO_PADRE'' END ' +
      '              AS ORIGEN_PRECIO, ' +
      '       t.PRECIO_SALIDA_ARTTAR, t.PRECIO_FINAL_ARTTAR, ' +
      '       t.PRECIO_DTO_ARTTAR, t.PORCENTAJE_DTO_ARTTAR, ' +
      '       COALESCE(t.PORCENTAJE_MARGEN_ARTTAR,    ' +
      'tar.PORCENTAJE_MARGEN_TAR) ' +
      '              AS PORCENTAJE_MARGEN_EFECTIVO, ' +
      '       COALESCE(t.VALOR_MULTIPLO_AJUSTE_ARTTAR, ' +
      'tar.VALOR_MULTIPLO_AJUSTE_TAR) ' +
      '              AS VALOR_MULTIPLO_AJUSTE_EFECTIVO, ' +
      '       COALESCE(t.VALOR_MENOS_AJUSTE_ARTTAR,    ' +
      'tar.VALOR_MENOS_AJUSTE_TAR) ' +
      '              AS VALOR_MENOS_AJUSTE_EFECTIVO, ' +
      '       tar.ESIMP_INCL_TAR, ' +
      '       t.FECHA_DESDE_ARTTAR, t.FECHA_HASTA_ARTTAR ' +
      '  FROM fza_articulos_tarifas t ' +
      '  JOIN fza_tarifas tar ON tar.CODIGO_TAR_ARTTAR = t.CODIGO_TAR_ARTTAR ' +
      ' WHERE t.CODIGO_ART_ARTTAR = :art ' +
      '   AND t.CODIGO_TAR_ARTTAR = :tar ' +
      '   AND t.ESACTIVO_ARTTAR   = ''S'' ' +
      '   AND (t.CODIGO_UNIDAD_ARTTAR = :sku ' +
      '        OR t.CODIGO_UNIDAD_ARTTAR IS NULL ' +
      '        OR t.CODIGO_UNIDAD_ARTTAR = '''') ' +
      '   AND (t.FECHA_DESDE_ARTTAR IS NULL OR t.FECHA_DESDE_ARTTAR <= :fec) ' +
      '   AND (t.FECHA_HASTA_ARTTAR IS NULL OR t.FECHA_HASTA_ARTTAR >= :fec) ' +
      ' ORDER BY CASE WHEN t.CODIGO_UNIDAD_ARTTAR = :sku AND :sku <> '''' ' +
      '               THEN 0 ELSE 1 END ' +
      ' LIMIT 1';
    q.ParamByName('art').AsString   := ACodigoArt;
    q.ParamByName('sku').AsString   := ACodigoSku;
    q.ParamByName('tar').AsString   := ACodigoTarifa;
    q.ParamByName('fec').AsDateTime := dFecha;
    q.Open;
    if not q.IsEmpty then
      RellenarPrecioDesdeQry(q, Result, AFecha);
  finally
    FreeAndNil(q);
  end;
  // Ventana de aplicacion del descuento (cabecera de tarifa). Si la linea
  // trae descuento pero la fecha pedida cae fuera de la ventana, se cobra el
  // precio de salida y se anula el descuento. Sin ventana -> aplica siempre.
  if Result.TieneRegistro and
     ((Result.PorcentajeDto <> 0) or (Result.PrecioDto <> 0)) then
  begin
    if not DescuentoTarifaVigente(FConexion, Result.CodigoTarifa, dFecha) then
    begin
      Result.PrecioFinal        := Result.PrecioSalida;
      Result.PrecioDto          := 0;
      Result.PorcentajeDto      := 0;
      Result.DescuentoAplicable := False;
    end;
  end;
end;

function TArticulosResolver.ResolverUltimoCoste(const ACodigoArt: string;
  const ACodigoProveedor: string;
  const ACodigoSku: string): TArticuloCoste;
var q: TUniQuery;
begin
  Result.Clear;
  if ACodigoArt = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    // 1. Si el llamante nos pasa un SKU concreto, el coste sale de la
    //    nueva tabla por SKU. Si la fila existe, devolvemos eso y punto.
    if ACodigoSku <> '' then
    begin
      q.SQL.Text :=
        'SELECT PRECIO_ULT_COMPRA_SKUC, FECHA_ULT_COMPRA_SKUC ' +
        '  FROM fza_articulos_skus_costes ' +
        ' WHERE CODIGO_UNIDAD_SKU_SKUC = :sku LIMIT 1';
      q.ParamByName('sku').AsString := ACodigoSku;
      q.Open;
      if not q.IsEmpty then
      begin
        if not q.FieldByName('PRECIO_ULT_COMPRA_SKUC').IsNull then
          Result.PrecioUltCompra    :=
            q.FieldByName('PRECIO_ULT_COMPRA_SKUC').AsFloat;
        if not q.FieldByName('FECHA_ULT_COMPRA_SKUC').IsNull then
          Result.FechaValidezCompra :=
            q.FieldByName('FECHA_ULT_COMPRA_SKUC').AsDateTime;
        Result.Encontrado := True;
        Exit;
      end;
      q.Close;
    end;

    // 2. Sin SKU (o sin fila por SKU): coste a nivel de artículo desde
    //    fza_articulos_proveedores. Esto sigue siendo válido para artículos
    //    sin SKUs y como fallback histórico.
    if ACodigoProveedor <> '' then
    begin
      q.SQL.Text :=
        'SELECT ap.CODIGO_PRV_AP, p.RAZON_SOCIAL_PRV, ap.REF_PROVEEDOR_AP, ' +
        '       ap.PRECIO_ULT_COMPRA_AP, ap.FECHA_VALIDEZ_AP, ' +
        '       ap.ESPROVEEDORPRINCIPAL_AP ' +
        '  FROM fza_articulos_proveedores ap ' +
        '  LEFT JOIN fza_proveedores p ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP '
          +
        ' WHERE ap.CODIGO_ART_AP = :art AND ap.CODIGO_PRV_AP = :prv LIMIT 1';
      q.ParamByName('art').AsString := ACodigoArt;
      q.ParamByName('prv').AsString := ACodigoProveedor;
    end
    else
    begin
      q.SQL.Text :=
        'SELECT ap.CODIGO_PRV_AP, p.RAZON_SOCIAL_PRV, ap.REF_PROVEEDOR_AP, ' +
        '       ap.PRECIO_ULT_COMPRA_AP, ap.FECHA_VALIDEZ_AP, ' +
        '       ap.ESPROVEEDORPRINCIPAL_AP ' +
        '  FROM fza_articulos_proveedores ap ' +
        '  LEFT JOIN fza_proveedores p ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP '
          +
        ' WHERE ap.CODIGO_ART_AP = :art ' +
        ' ORDER BY CASE ap.ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ELSE 1 ' +
        'END, ' +
        '          ap.FECHA_VALIDEZ_AP DESC ' +
        ' LIMIT 1';
      q.ParamByName('art').AsString := ACodigoArt;
    end;
    q.Open;
    if q.IsEmpty then Exit;
    Result.CodigoProveedor      := q.FieldByName('CODIGO_PRV_AP').AsString;
    Result.RazonSocialProveedor := q.FieldByName('RAZON_SOCIAL_PRV').AsString;
    Result.RefProveedor         := q.FieldByName('REF_PROVEEDOR_AP').AsString;
    if not q.FieldByName('PRECIO_ULT_COMPRA_AP').IsNull then
      Result.PrecioUltCompra := q.FieldByName('PRECIO_ULT_COMPRA_AP').AsFloat;
    if not q.FieldByName('FECHA_VALIDEZ_AP').IsNull then
      Result.FechaValidezCompra := q.FieldByName('FECHA_VALIDEZ_AP').AsDateTime;
    Result.EsProveedorPrincipal :=
                          q.FieldByName(
                            'ESPROVEEDORPRINCIPAL_AP').AsString = 'S';
    Result.Encontrado := True;
  finally
    FreeAndNil(q);
  end;
end;

function TArticulosResolver.ResolverPMP(const ACodigoSku: string;
  const ACodigoAlmacen: string): TArticuloPMP;
var q: TUniQuery;
begin
  Result.Clear;
  if ACodigoSku = '' then Exit;
  Result.AlmacenConsultado := ACodigoAlmacen;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    if ACodigoAlmacen <> '' then
    begin
      q.SQL.Text :=
        'SELECT SUM(CANTIDAD_STK)    AS QTY, ' +
        '       SUM(VALOR_TOTAL_STK) AS VAL, ' +
        '       COUNT(DISTINCT CODIGO_ALM_STK) AS NA ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :sku ' +
        '   AND CODIGO_ALM_STK    = :alm';
      q.ParamByName('sku').AsString := ACodigoSku;
      q.ParamByName('alm').AsString := ACodigoAlmacen;
    end
    else
    begin
      q.SQL.Text :=
        'SELECT SUM(CANTIDAD_STK)    AS QTY, ' +
        '       SUM(VALOR_TOTAL_STK) AS VAL, ' +
        '       COUNT(DISTINCT CODIGO_ALM_STK) AS NA ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :sku';
      q.ParamByName('sku').AsString := ACodigoSku;
    end;
    q.Open;
    if q.IsEmpty then Exit;
    if not q.FieldByName('QTY').IsNull then
      Result.CantidadTotal := q.FieldByName('QTY').AsFloat;
    if not q.FieldByName('VAL').IsNull then
      Result.ValorTotal    := q.FieldByName('VAL').AsFloat;
    Result.NumAlmacenes := q.FieldByName('NA').AsInteger;
    if Result.CantidadTotal > 0 then
      Result.PrecioMedio := Result.ValorTotal / Result.CantidadTotal;
    Result.Encontrado := Result.NumAlmacenes > 0;
  finally
    FreeAndNil(q);
  end;
end;

function TArticulosResolver.ResolverDatos(const ACodigoArt, ACodigoSku: string;
  const ACodigoTarifa: string; const AFecha: TDateTime;
  const ACodigoAlmacen: string;
  const ACodigoProveedor: string): TArticuloDatos;
var
  q       : TUniQuery;
  sTarifa : string;
  sTarDef : string;
  sSku    : string;
  sUnico  : string;
  iNumSkus: Integer;
begin
  Result.Clear;
  if ACodigoArt = '' then
  begin
    Result.Mensaje := 'Falta código de artículo.';
    Exit;
  end;

  iNumSkus := ContarSkusActivos(ACodigoArt, sUnico);
  sSku     := ACodigoSku;

  // Si el artículo tiene SKUs y el llamante no pasó uno: si hay un único
  // SKU activo (servicios / artículos sin variación), lo resolvemos solos;
  // si hay >1, marcamos RequiereSku — los datos básicos (descripción,
  // familia, IVA…) se llenan igual para que la UI pueda mostrarlos
  // mientras pide la talla/color, pero precio/PMP/coste se dejan a 0.
  if (sSku = '') and (iNumSkus = 1) then
    sSku := sUnico
  else if (sSku = '') and (iNumSkus > 1) then
    Result.RequiereSku := True;

  // Datos básicos del artículo + SKU si lo hay
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.TIPO_ART, ' +
      '       a.TIPO_CANTIDAD_ART, a.ESACTIVO_ART, a.ESVARIACION_ART, ' +
      '       a.ESTRAZABLE_ART, a.CODIGO_FAM_ART, a.TIPO_IVA_ART, ' +
      '       a.TIPO_VARIACION_ART, ' +
      '       fam.DESCRIPCION_FAM, ' +
      '       sk.CODIGO_UNIDAD_SKU, sk.ESACTIVO_SKU, ' +
      '       (SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV SEPARATOR '' / ' +
      ''') ' +
      '          FROM fza_atributos_sku sa ' +
      '          JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
      '         WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU) AS ' +
      'DESCRIPCION_SKU, ' +
      '       (SELECT COUNT(DISTINCT va.ID_ATB_VA) ' +
      '          FROM fza_articulos_skus s2 ' +
      '          JOIN fza_variaciones_atributos va ' +
      '            ON va.ID_VAR_VA = s2.CODIGO_VAR_SKU ' +
      '         WHERE s2.CODIGO_ART_SKU = a.CODIGO_ART_ART) AS NUM_ATR_REQ, ' +
      '       iv.CODIGO_ABREVIATURA_IVA_IVATIP ' +
      '  FROM fza_articulos a ' +
      '  LEFT JOIN fza_articulos_skus sk ' +
      '    ON sk.CODIGO_UNIDAD_SKU = :sku AND sk.CODIGO_ART_SKU = ' +
      'a.CODIGO_ART_ART ' +
      '  LEFT JOIN fza_articulos_familias fam ON fam.CODIGO_FAM_FAM = ' +
      'a.CODIGO_FAM_ART ' +
      '  LEFT JOIN fza_ivas_tipos iv ON iv.CODIGO_ABREVIATURA_IVA_IVATIP = ' +
      'a.TIPO_IVA_ART ' +
      ' WHERE a.CODIGO_ART_ART = :art LIMIT 1';
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('sku').AsString := sSku;
    q.Open;
    if q.IsEmpty then
    begin
      Result.Mensaje := 'No existe el artículo "' + ACodigoArt + '".';
      Exit;
    end;
    Result.CodigoArticulo      := q.FieldByName('CODIGO_ART_ART').AsString;
    Result.CodigoSku           := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    Result.DescripcionArticulo := q.FieldByName('DESCRIPCION_ART').AsString;
    Result.DescripcionSku      := q.FieldByName('DESCRIPCION_SKU').AsString;
    Result.TipoArticulo        := q.FieldByName('TIPO_ART').AsString;
    Result.TipoCantidad        := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
    Result.EsActivoArticulo    := q.FieldByName('ESACTIVO_ART').AsString = 'S';
    Result.EsActivoSku         := q.FieldByName('ESACTIVO_SKU').AsString = 'S';
    Result.EsVariacion := q.FieldByName('ESVARIACION_ART').AsString = 'S';
    Result.EsTrazable := q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
    Result.NumAtributosReq     := q.FieldByName('NUM_ATR_REQ').AsInteger;
    Result.CodigoFamilia       := q.FieldByName('CODIGO_FAM_ART').AsString;
    Result.DescripcionFamilia  := q.FieldByName('DESCRIPCION_FAM').AsString;
    Result.TipoIVA             := q.FieldByName('TIPO_IVA_ART').AsString;
    Result.TipoVariacion       := q.FieldByName('TIPO_VARIACION_ART').AsString;
    Result.TieneSku            := iNumSkus > 0;
  finally
    FreeAndNil(q);
  end;

  Result.Encontrado := Result.CodigoArticulo <> '';
  if not Result.Encontrado then Exit;

  // Si no tenemos SKU concreto (artículo padre con varios SKUs), dejamos
  // sin tocar precio/PMP/coste: el llamante pedirá talla/color y volverá.
  if Result.RequiereSku then
  begin
    Result.Mensaje :=
      'El artículo "' + ACodigoArt + '" tiene SKUs. ' +
      'Indica uno para obtener precio definitivo.';
    Exit;
  end;

  // Tarifa solicitada
  sTarifa := ACodigoTarifa;
  if sTarifa = '' then sTarifa := TarifaDefault;
  if sTarifa <> '' then
    Result.PrecioPedido := ResolverPrecio(ACodigoArt, sSku, sTarifa, AFecha);

  // Tarifa por defecto del sistema (si difiere)
  sTarDef := TarifaDefault;
  if (sTarDef <> '') and (sTarDef <> sTarifa) then
    Result.PrecioTarifaDefault :=
                          ResolverPrecio(ACodigoArt, sSku, sTarDef, AFecha)
  else
    Result.PrecioTarifaDefault := Result.PrecioPedido;

  // Coste y PMP. Si tenemos SKU resuelto, el coste sale de la tabla por SKU
  // (con fallback al proveedor); si no, del proveedor principal.
  Result.UltimoCoste := ResolverUltimoCoste(ACodigoArt, ACodigoProveedor,
                                            Result.CodigoSku);
  if Result.CodigoSku <> '' then
    Result.PMP := ResolverPMP(Result.CodigoSku, ACodigoAlmacen);
end;

function TArticulosResolver.ListarSkus(const ACodigoArt: string;
  AIncluirInactivos: Boolean): TArray<TArticuloSkuItem>;
var
  q     : TUniQuery;
  Lst   : TList<TArticuloSkuItem>;
  Item  : TArticuloSkuItem;
  sFiltroAct: string;
begin
  Result := nil;
  if ACodigoArt = '' then Exit;

  if AIncluirInactivos then sFiltroAct := ''
  else                      sFiltroAct := '   AND sk.ESACTIVO_SKU = ''S'' ';

  Lst := TList<TArticuloSkuItem>.Create;
  q   := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT sk.CODIGO_UNIDAD_SKU, sk.ESACTIVO_SKU, ' +
      '       (SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV SEPARATOR '' / ' +
      ''') ' +
      '          FROM fza_atributos_sku sa ' +
      '          JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
      '         WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU) AS ' +
      'DESCRIPCION_SKU ' +
      '  FROM fza_articulos_skus sk ' +
      ' WHERE sk.CODIGO_ART_SKU = :art ' +
      sFiltroAct +
      ' ORDER BY sk.CODIGO_UNIDAD_SKU';
    q.ParamByName('art').AsString := ACodigoArt;
    q.Open;
    while not q.Eof do
    begin
      Item := Default(TArticuloSkuItem);
      Item.CodigoSku      := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      Item.DescripcionSku := q.FieldByName('DESCRIPCION_SKU').AsString;
      Item.EsActivo       := q.FieldByName('ESACTIVO_SKU').AsString = 'S';
      Lst.Add(Item);
      q.Next;
    end;
    Result := Lst.ToArray;
  finally
    FreeAndNil(q);
    FreeAndNil(Lst);
  end;
end;

end.

