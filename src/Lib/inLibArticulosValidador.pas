{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosValidador                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validador de entrada de artículo en caja y documentos.                    }
{    Resuelve código de artículo, SKU, código de barras o referencia de        }
{    proveedor.                                                                }
{******************************************************************************}
unit inLibArticulosValidador;

{
  Unidad: inLibArticulosValidador
  Descripción:
    Resuelve una cadena introducida por el usuario (caja, pedidos, albaranes,
    facturas, inventarios, movimientos de almacén, etiquetado, etc.) hasta el
    par canónico (CODIGO_ART_ART, CODIGO_UNIDAD_SKU). Acepta como entrada:

      • Código de artículo  → fza_articulos.CODIGO_ART_ART
      • Código de SKU       → fza_articulos_skus.CODIGO_UNIDAD_SKU
      • Código de barras    → fza_codigos_barras.CODIGO_BARRAS_CB
      • Modelo de proveedor → fza_articulos_proveedores.REF_PROVEEDOR_AP

    Apoyo: vista `vi_caja_busqueda_unificada` (definida en BBDD), que ya
    combina los cuatro orígenes.

  Política sobre artículos con SKUs:
    Si la coincidencia es contra el padre y el padre tiene SKUs activos, la
    librería marca RequiereSku = True y NO selecciona SKU por su cuenta.
    El llamante debe pedir el SKU al usuario (selector talla/color, etc.)
    y volver a llamar con el SKU explícito (o pasarlo a inLibArticulosResolver
    directamente), apoyándose en `inLibArticulosAtributosLookup` para construir
    los desplegables con los valores posibles.

  Uso típico:

      val := TArticulosValidador.Create(AConexion);
      try
        r := val.Resolver(InputUsuario);
        if not r.Encontrado then
          ShowMessage(r.Mensaje)
        else if r.RequiereSku then
          // pedir SKU al usuario y volver a resolver
        else
        begin
          // r.CodigoArticulo, r.CodigoSku, r.TipoCoincidencia
        end;
      finally
        FreeAndNil(val);
      end;
}

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.Variants,
  Data.DB, DBAccess, Uni;

type
  TArtTipoCoincidencia = (
    atcDesconocido,    // sin coincidencia o entrada vacía
    atcCodigoArt,      // hizo match con CODIGO_ART_ART
    atcCodigoSku,      // hizo match con CODIGO_UNIDAD_SKU
    atcCodigoBarras,   // hizo match con CODIGO_BARRAS_CB
    atcRefProveedor    // hizo match con REF_PROVEEDOR_AP
  );

  TArtResolucionEntrada = record
    EntradaOriginal     : string;
    Tipo                : TArtTipoCoincidencia;
    Encontrado          : Boolean;
    NumCoincidencias    : Integer;        // > 1 → entrada ambigua
    CodigoArticulo      : string;
    CodigoSku           : string;          // vacío si la coincidencia es de
                                           // padre y el padre no tiene SKUs
    DescripcionArticulo : string;
    TipoArticulo        : string;          // ESTANDAR / SERVICIO / KIT
    EsActivoArticulo    : Boolean;
    EsVariacion         : Boolean;         // S si tiene tallas/colores
    TieneSku            : Boolean;         // tiene >=1 SKU activo
    NumAtributosReq     : Integer;         // nº atributos del tipo de variación
                                           // (talla+color = 2). 0 si no varía.
    RequiereSku         : Boolean;         // tiene SKU pero la coincidencia no
                                           //  trajo uno → llamante debe elegir
    SkuActivo           : Boolean;         // sólo válido si CodigoSku <> ''
    CodigoBarrasMatch   : string;          // valor que coincidió si EAN
    RefProveedorMatch   : string;          // valor que coincidió si MODELO_PROV
    CodigoProveedorMatch: string;          // proveedor cuyo modelo coincidió
    Mensaje             : string;          // error / aviso

    procedure Clear;
    function ToReadable: string;
  end;

  TArticulosValidador = class
  private
    FConexion: TUniConnection;
    procedure RellenarDatosArticulo(var R: TArtResolucionEntrada);
    function  ContarCoincidencias(const sEntrada: string;
                                  ASoloCodigoBarras: Boolean = False): Integer;
    procedure RellenarProveedorMatch(var R: TArtResolucionEntrada;
                                     const sEntrada: string);
    // Nucleo de resolucion. ASoloCodigoBarras restringe la busqueda a la
    // fila EAN de la vista unificada (lectura con pistola).
    function ResolverInterno(const AEntrada: string;
                             ASoloCodigoBarras: Boolean): TArtResolucionEntrada;
  public
    constructor Create(AConexion: TUniConnection);
    function Resolver(const AEntrada: string): TArtResolucionEntrada;
    // Resuelve buscando UNICAMENTE en codigos de barras (TIPO_COINCIDENCIA
    // = 'EAN'). Pensado para la lectura con pistola en caja: ignora codigos
    // de articulo, SKU y modelos de proveedor aunque coincidan.
    function ResolverCodigoBarras(const AEntrada: string):
                                                       TArtResolucionEntrada;
    function ResolverConSku(const AEntrada, ACodigoSkuPreferido: string):
                                                       TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
  end;

// Normaliza campos de linea que admiten entrada libre: articulo, SKU,
// codigo de barras o referencia de proveedor. Si hay SKU resuelto, deja
// guardado el par canonico CODIGO_ART / CODIGO_UNIDAD.
procedure NormalizarArticuloSkuEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku: string;
  const ACampoCodigoBarras: string = '');

// Recorre el dataset de lineas de un documento (campos por convencion
// CODIGO_ART_ / CODIGO_UNIDAD_ / LINEA_ + sufijo de tabla) y devuelve
// los numeros de linea con articulo que exige SKU (tiene algun SKU
// activo, misma politica que RequiereSku) y sin SKU asignado, separados
// por comas. Cadena vacia si el documento esta completo.
function LineasSinSkuRequerido(AConexion: TUniConnection;
  ALineas: TDataSet; const ASufijo: string): string;

implementation

uses
  inLibMsg;

const
  TIPOS_LEGIBLES: array[TArtTipoCoincidencia] of string =
    ('Desconocido', 'CodigoArt', 'CodigoSku', 'CodigoBarras', 'RefProveedor');

function NormalizarEntradaLector(const AEntrada: string): string;
begin
  Result := Trim(AEntrada);
  Result := StringReplace(Result, #2, '', [rfReplaceAll]);
  Result := StringReplace(Result, #3, '', [rfReplaceAll]);
  if StartsText('STX', Result) then
    Delete(Result, 1, 3);
  if EndsText('ETX', Result) then
    Delete(Result, Length(Result) - 2, 3);
  Result := Trim(Result);
end;

function ValorCampoNormalizacion(ADataSet: TDataSet;
  const ACampo: string): string;
var
  Campo: TField;
begin
  Result := '';
  if Assigned(ADataSet) and (ACampo <> '') then
  begin
    Campo := ADataSet.FindField(ACampo);
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsString;
  end;
end;

function CampoNormalizacionCambiado(ADataSet: TDataSet;
  const ACampo: string): Boolean;
var
  Campo: TField;
begin
  Result := False;
  if Assigned(ADataSet) and (ACampo <> '') and (ADataSet.State = dsEdit) then
  begin
    Campo := ADataSet.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString) <> Trim(VarToStr(Campo.OldValue));
  end;
end;

function DebeNormalizarArticuloSku(ADataSet: TDataSet;
  const ACampoArticulo, ACampoSku, ACampoCodigoBarras: string): Boolean;
begin
  Result := True;
  if Assigned(ADataSet) and (ADataSet.State = dsEdit) then
    Result := CampoNormalizacionCambiado(ADataSet, ACampoArticulo) or
              CampoNormalizacionCambiado(ADataSet, ACampoSku) or
              CampoNormalizacionCambiado(ADataSet, ACampoCodigoBarras);
end;

procedure PonerCampoNormalizacion(ADataSet: TDataSet;
  const ACampo, AValor: string);
var
  Campo: TField;
begin
  if Assigned(ADataSet) and (ACampo <> '') then
  begin
    Campo := ADataSet.FindField(ACampo);
    if (Campo <> nil) and (not Campo.ReadOnly) and
       (Campo.AsString <> AValor) then
    begin
      if not (ADataSet.State in dsEditModes) then
        ADataSet.Edit;
      Campo.AsString := AValor;
    end;
  end;
end;

procedure ResolverEntradaNormalizacion(AValidador: TArticulosValidador;
  const AEntrada: string; out AResolucion: TArtResolucionEntrada);
begin
  AResolucion.Clear;
  if NormalizarEntradaLector(AEntrada) <> '' then
    AResolucion := AValidador.Resolver(AEntrada);
end;

procedure NormalizarArticuloSkuEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku: string;
  const ACampoCodigoBarras: string);
var
  Validador: TArticulosValidador;
  RArt: TArtResolucionEntrada;
  RSku: TArtResolucionEntrada;
  RBarras: TArtResolucionEntrada;
  RElegida: TArtResolucionEntrada;
  sArticulo: string;
  sSku: string;
  sBarras: string;
  bElegida: Boolean;
begin
  if (AConexion <> nil) and Assigned(ADataSet) and ADataSet.Active then
  begin
    if DebeNormalizarArticuloSku(ADataSet, ACampoArticulo, ACampoSku,
                                 ACampoCodigoBarras) then
    begin
      sArticulo := Trim(ValorCampoNormalizacion(ADataSet, ACampoArticulo));
      sSku := Trim(ValorCampoNormalizacion(ADataSet, ACampoSku));
      sBarras := Trim(ValorCampoNormalizacion(ADataSet, ACampoCodigoBarras));
      if (sArticulo <> '') or (sSku <> '') or (sBarras <> '') then
      begin
        Validador := TArticulosValidador.Create(AConexion);
        try
          ResolverEntradaNormalizacion(Validador, sArticulo, RArt);
          ResolverEntradaNormalizacion(Validador, sSku, RSku);
          ResolverEntradaNormalizacion(Validador, sBarras, RBarras);
        finally
          FreeAndNil(Validador);
        end;
        RElegida.Clear;
        bElegida := False;
        if RArt.Encontrado and (RArt.Tipo <> atcCodigoArt) then
        begin
          RElegida := RArt;
          bElegida := True;
        end
        else if RSku.Encontrado and
                ((not RArt.Encontrado) or
                 SameText(RSku.CodigoArticulo, RArt.CodigoArticulo)) then
        begin
          RElegida := RSku;
          bElegida := True;
        end
        else if RBarras.Encontrado and
                ((not RArt.Encontrado) or
                 SameText(RBarras.CodigoArticulo, RArt.CodigoArticulo)) then
        begin
          RElegida := RBarras;
          bElegida := True;
        end
        else if RArt.Encontrado then
        begin
          RElegida := RArt;
          bElegida := True;
        end;
        if bElegida then
        begin
          PonerCampoNormalizacion(ADataSet, ACampoArticulo,
                                  RElegida.CodigoArticulo);
          if (RElegida.CodigoSku <> '') and (not RElegida.RequiereSku) then
            PonerCampoNormalizacion(ADataSet, ACampoSku, RElegida.CodigoSku)
          else if RArt.Encontrado and RSku.Encontrado and
                  (not SameText(RArt.CodigoArticulo,
                                RSku.CodigoArticulo)) then
            PonerCampoNormalizacion(ADataSet, ACampoSku, '');
          if RElegida.CodigoBarrasMatch <> '' then
            PonerCampoNormalizacion(ADataSet, ACampoCodigoBarras,
                                    RElegida.CodigoBarrasMatch);
        end;
      end;
    end;
  end;
end;

{ TArtResolucionEntrada ───────────────────────────────────────────────────── }

procedure TArtResolucionEntrada.Clear;
begin
  EntradaOriginal      := '';
  Tipo                 := atcDesconocido;
  Encontrado           := False;
  NumCoincidencias     := 0;
  CodigoArticulo       := '';
  CodigoSku            := '';
  DescripcionArticulo  := '';
  TipoArticulo         := '';
  EsActivoArticulo     := False;
  EsVariacion          := False;
  TieneSku             := False;
  NumAtributosReq      := 0;
  RequiereSku          := False;
  SkuActivo            := False;
  CodigoBarrasMatch    := '';
  RefProveedorMatch    := '';
  CodigoProveedorMatch := '';
  Mensaje              := '';
end;

function TArtResolucionEntrada.ToReadable: string;
begin
  if not Encontrado then
    Exit('[no encontrado: "' + EntradaOriginal + '"]');
  Result := Format('[%s "%s" → ART=%s SKU=%s%s]',
    [TIPOS_LEGIBLES[Tipo], EntradaOriginal, CodigoArticulo, CodigoSku,
     IfThen(RequiereSku, ' (requiere SKU)', '')]);
end;

{ TArticulosValidador ─────────────────────────────────────────────────────── }

constructor TArticulosValidador.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TArticulosValidador.ContarCoincidencias(
  const sEntrada: string; ASoloCodigoBarras: Boolean): Integer;
var
  q: TUniQuery;
  sFiltroTipo: string;
begin
  // Si solo contamos codigos de barras, restringimos a la fila EAN para que
  // NumCoincidencias refleje las coincidencias reales de la lectura.
  if ASoloCodigoBarras then
    sFiltroTipo :=
      ' AND TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '''EAN'' COLLATE utf8mb4_spanish_ci '
  else
    sFiltroTipo := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'SELECT COUNT(*) AS N FROM vi_caja_busqueda_unificada ' +
      ' WHERE INPUT_BUSQUEDA = :inp' + sFiltroTipo;
    q.ParamByName('inp').AsString := sEntrada;
    q.Open;
    Result := q.FieldByName('N').AsInteger;
  finally
    FreeAndNil(q);
  end;
end;

procedure TArticulosValidador.RellenarDatosArticulo(
  var R: TArtResolucionEntrada);
var
  q       : TUniQuery;
  iNumSkus: Integer;
  sUnico  : string;
begin
  if R.CodigoArticulo = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'SELECT a.ESACTIVO_ART, a.ESVARIACION_ART, a.TIPO_VARIACION_ART, ' +
      '       (SELECT COUNT(*) FROM fza_variaciones_atributos va ' +
      '         WHERE va.ID_VAR_VA = a.TIPO_VARIACION_ART) AS NUM_ATR_REQ ' +
      '  FROM fza_articulos a ' +
      ' WHERE a.CODIGO_ART_ART = :art';
    q.ParamByName('art').AsString := R.CodigoArticulo;
    q.Open;
    if q.IsEmpty then
    begin
      R.Encontrado := False;
      R.Mensaje := Format(SErrorArticuloNoExiste, [R.CodigoArticulo]);
      Exit;
    end;
    R.EsActivoArticulo := q.FieldByName('ESACTIVO_ART').AsString = 'S';
    R.EsVariacion      := q.FieldByName('ESVARIACION_ART').AsString = 'S';
    R.NumAtributosReq  := q.FieldByName('NUM_ATR_REQ').AsInteger;
  finally
    FreeAndNil(q);
  end;

  // Contamos SKUs activos del artículo. Si hay sólo uno (caso típico de
  // servicios y artículos sin variación: SKU autocreado con mismo código),
  // lo resolvemos automáticamente y NO marcamos RequiereSku.
  iNumSkus := 0;
  sUnico   := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
      ' WHERE CODIGO_ART_SKU = :art AND ESACTIVO_SKU = ''S''';
    q.ParamByName('art').AsString := R.CodigoArticulo;
    q.Open;
    while not q.Eof do
    begin
      Inc(iNumSkus);
      if iNumSkus = 1 then sUnico :=
        q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
  R.TieneSku := iNumSkus > 0;
  if (iNumSkus = 1) and (R.CodigoSku = '') then
    R.CodigoSku := sUnico;

  // Validar que CodigoSku, si vino, pertenece al artículo
  if R.CodigoSku <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      q.SQL.Text   :=
        'SELECT ESACTIVO_SKU FROM fza_articulos_skus ' +
        ' WHERE CODIGO_UNIDAD_SKU = :sku ' +
        '   AND CODIGO_ART_SKU    = :art';
      q.ParamByName('sku').AsString := R.CodigoSku;
      q.ParamByName('art').AsString := R.CodigoArticulo;
      q.Open;
      if q.IsEmpty then
      begin
        // SKU no pertenece al artículo: lo desligamos
        R.CodigoSku := '';
        R.SkuActivo := False;
      end
      else
        R.SkuActivo := q.FieldByName('ESACTIVO_SKU').AsString = 'S';
    finally
      FreeAndNil(q);
    end;
  end;

  // Política: si el artículo tiene SKUs y todavía no hay uno → exige SKU.
  // (Si arriba autorresolvimos al único SKU, R.CodigoSku ya no estará vacío.)
  R.RequiereSku := R.TieneSku and (R.CodigoSku = '');
end;

procedure TArticulosValidador.RellenarProveedorMatch(
  var R: TArtResolucionEntrada; const sEntrada: string);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'SELECT CODIGO_PRV_AP FROM fza_articulos_proveedores ' +
      ' WHERE CODIGO_ART_AP   = :art ' +
      '   AND REF_PROVEEDOR_AP = :ref ' +
      ' ORDER BY CASE ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ELSE 1 END ' +
      ' LIMIT 1';
    q.ParamByName('art').AsString := R.CodigoArticulo;
    q.ParamByName('ref').AsString := sEntrada;
    q.Open;
    if not q.IsEmpty then
      R.CodigoProveedorMatch := q.FieldByName('CODIGO_PRV_AP').AsString;
  finally
    FreeAndNil(q);
  end;
end;

function TArticulosValidador.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := ResolverInterno(AEntrada, False);
end;

function TArticulosValidador.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := ResolverInterno(AEntrada, True);
end;

function TArticulosValidador.ResolverInterno(const AEntrada: string;
  ASoloCodigoBarras: Boolean): TArtResolucionEntrada;
var
  q          : TUniQuery;
  sEnt       : string;
  sTipo      : string;
  sFiltroTipo: string;
begin
  Result.Clear;
  Result.EntradaOriginal := AEntrada;
  sEnt := NormalizarEntradaLector(AEntrada);
  if sEnt = '' then
  begin
    Result.Mensaje := SErrorEntradaArticuloVacia;
    Exit;
  end;
  // Lectura con pistola: restringimos a la fila EAN de la vista para que solo
  // resuelva contra fza_codigos_barras (ignora codigo de articulo, SKU y
  // modelo de proveedor aunque coincidan con la cadena leida).
  if ASoloCodigoBarras then
    sFiltroTipo :=
      ' AND TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '''EAN'' COLLATE utf8mb4_spanish_ci '
  else
    sFiltroTipo := '';
  // Orden de prioridad: SKU > CODIGO > EAN > MODELO_PROV
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'SELECT TIPO_COINCIDENCIA, CODIGO_PADRE, CODIGO_SKU, ' +
      '       DESCRIPCION_ART, TIPO_ART, INPUT_BUSQUEDA ' +
      '  FROM vi_caja_busqueda_unificada ' +
      ' WHERE INPUT_BUSQUEDA = :inp ' + sFiltroTipo +
      ' ORDER BY CASE ' +
      '            WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '                 ''SKU'' COLLATE utf8mb4_spanish_ci THEN 1 ' +
      '            WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '                 ''CODIGO'' COLLATE utf8mb4_spanish_ci THEN 2 ' +
      '            WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '                 ''EAN'' COLLATE utf8mb4_spanish_ci THEN 3 ' +
      '            WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '                 ''MODELO_PROV'' COLLATE utf8mb4_spanish_ci THEN 4 ' +
      '            ELSE 5 END LIMIT 1';
    q.ParamByName('inp').AsString := sEnt;
    q.Open;
    if q.IsEmpty then
    begin
      if ASoloCodigoBarras then
        Result.Mensaje := Format(SErrorCodigoBarrasNoEncontrado, [sEnt])
      else
        Result.Mensaje := Format(SErrorArticuloEntradaNoEncontrado, [sEnt]);
      Exit;
    end;
    Result.CodigoArticulo      := q.FieldByName('CODIGO_PADRE').AsString;
    Result.CodigoSku           := q.FieldByName('CODIGO_SKU').AsString;
    Result.DescripcionArticulo := q.FieldByName('DESCRIPCION_ART').AsString;
    Result.TipoArticulo        := q.FieldByName('TIPO_ART').AsString;
    sTipo                      := q.FieldByName('TIPO_COINCIDENCIA').AsString;
  finally
    FreeAndNil(q);
  end;

  if      sTipo = 'CODIGO'      then Result.Tipo := atcCodigoArt
  else if sTipo = 'SKU'         then Result.Tipo := atcCodigoSku
  else if sTipo = 'EAN'         then Result.Tipo := atcCodigoBarras
  else if sTipo = 'MODELO_PROV' then Result.Tipo := atcRefProveedor
  else                               Result.Tipo := atcDesconocido;

  case Result.Tipo of
    atcCodigoBarras: Result.CodigoBarrasMatch := sEnt;
    atcRefProveedor: Result.RefProveedorMatch := sEnt;
  end;

  Result.Encontrado       := Result.CodigoArticulo <> '';
  Result.NumCoincidencias := ContarCoincidencias(sEnt, ASoloCodigoBarras);

  RellenarDatosArticulo(Result);

  if Result.Tipo = atcRefProveedor then
    RellenarProveedorMatch(Result, sEnt);

  if Result.Encontrado and Result.RequiereSku then
    Result.Mensaje := Format(SAvisoArticuloRequiereSku,
                             [Result.CodigoArticulo])
  else if Result.Encontrado and (not Result.TieneSku) then
  begin
    // Localizado y activo pero sin ninguna unidad (SKU) activa que vender:
    // p. ej. variación sin tallas/colores. Motivo exacto, no "no encontrado".
    if Result.EsVariacion then
      Result.Mensaje := Format(SErrorArticuloVariacionSinSkusActivos,
                               [Result.CodigoArticulo])
    else
      Result.Mensaje := Format(SErrorArticuloSinSkusActivos,
                               [Result.CodigoArticulo]);
  end;
end;

function TArticulosValidador.ResolverConSku(const AEntrada,
  ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := Resolver(AEntrada);
  if Result.Encontrado and (ACodigoSkuPreferido <> '') and
     ((Result.CodigoSku = '') or Result.RequiereSku) then
  begin
    // Probar a ligar el SKU sugerido por el llamante
    Result.CodigoSku := ACodigoSkuPreferido;
    Result.RequiereSku := False;
    RellenarDatosArticulo(Result);
    if Result.RequiereSku then
      Result.Mensaje := Format(SErrorSkuNoPerteneceArticulo,
        [ACodigoSkuPreferido, Result.CodigoArticulo]);
  end;
end;

function TArticulosValidador.EsValido(const AEntrada: string): Boolean;
var R: TArtResolucionEntrada;
begin
  R := Resolver(AEntrada);
  Result := R.Encontrado and (not R.RequiereSku);
end;

function LineasSinSkuRequerido(AConexion: TUniConnection;
  ALineas: TDataSet; const ASufijo: string): string;
var
  qry: TUniQuery;
  slCache: TStringList;
  Bm: TBookmark;
  sArt, sTiene: string;
  fldArt, fldSku, fldLinea: TField;
begin
  Result := '';
  if (AConexion <> nil) and (ALineas <> nil) and ALineas.Active then
  begin
    fldArt   := ALineas.FindField('CODIGO_ART_' + ASufijo);
    fldSku   := ALineas.FindField('CODIGO_UNIDAD_' + ASufijo);
    fldLinea := ALineas.FindField('LINEA_' + ASufijo);
    if (fldArt <> nil) and (fldSku <> nil) and (fldLinea <> nil) and
       (not ALineas.IsEmpty) then
    begin
      qry := TUniQuery.Create(nil);
      slCache := TStringList.Create;
      Bm := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        qry.Connection := AConexion;
        qry.SQL.Text :=
          'SELECT 1 FROM fza_articulos_skus ' +
          ' WHERE CODIGO_ART_SKU = :art ' +
          '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S'' LIMIT 1';
        ALineas.First;
        while not ALineas.Eof do
        begin
          sArt := Trim(fldArt.AsString);
          if (sArt <> '') and (Trim(fldSku.AsString) = '') then
          begin
            // Cache por articulo: las lineas repiten articulo y evita
            // una consulta por linea.
            sTiene := slCache.Values[sArt];
            if sTiene = '' then
            begin
              qry.Close;
              qry.ParamByName('art').AsString := sArt;
              qry.Open;
              if qry.IsEmpty then
                sTiene := 'N'
              else
                sTiene := 'S';
              slCache.Values[sArt] := sTiene;
            end;
            if sTiene = 'S' then
            begin
              if Result <> '' then
                Result := Result + ', ';
              Result := Result + fldLinea.AsString;
            end;
          end;
          ALineas.Next;
        end;
        if ALineas.BookmarkValid(Bm) then
          ALineas.GotoBookmark(Bm);
      finally
        ALineas.EnableControls;
        ALineas.FreeBookmark(Bm);
        FreeAndNil(slCache);
        FreeAndNil(qry);
      end;
    end;
  end;
end;

end.
