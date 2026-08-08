{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesArticulos                              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de artículos y SKU de una sesión de compra.                  }
{******************************************************************************}
unit UniDataComprasSesionesArticulos;

interface

uses
  Uni,
  inLibFotos,
  inLibComprasSesionesLecturasIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesiones;

function SanearColorSku(const ATexto: string): string;
function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AColorTexto, ACodigoAtbColor, AUsuario: string;
  out AValor: string): Integer;
function ResolverCodigoSku(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArt: string;
  AIdAvPivot, AIdAvFila: Integer): string;
procedure MaterializarArticulosSesion(
  ADM: TdmComprasSesiones;
  AFotos: TFotosArticulos;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AUsuario: string);

implementation
uses
  System.SysUtils,
  Data.DB, DBAccess,
  inLibEAN13,
  inLibComprasSesionesReglas,
  UniDataValoresAutomaticosRepositorio,
  inLibMsgCompras;
function GenerarEAN13Local(
                           const ALecturas:
                           ILecturasArticulosMaterializacion;
                           const APrefijo: string): string;
var
  sPref   : string;
  iLenSeq : Integer;
  iNext   : Int64;
  sBase   : string;
  cCheck  : Char;
begin
  sPref := APrefijo;
  // Default '21' = GS1 in-store / uso interno.
  // Si la empresa tiene su propio prefijo GS1, ponerlo en
  // PREFIJO_EAN_SES de la cabecera de la sesion.
  if sPref = '' then
    sPref := '21';
  iLenSeq := 12 - Length(sPref);
  if iLenSeq <= 0 then
    raise Exception.Create(Format(SErrorPrefijoEanSesionLargo, [sPref]));
  iNext := ALecturas.ObtenerSiguienteSecuenciaEan(
    sPref,
    iLenSeq);
  sBase  := sPref + Format('%.*d', [iLenSeq, iNext]);
  cCheck := inLibEAN13.CalcularDigitoEAN13(sBase);
  Result := sBase + cCheck;
end;
// ---------------------------------------------------------------------------
// Auxiliares internas
// ---------------------------------------------------------------------------
procedure InsertarArticulo(AConn: TUniConnection;
                           ADM: TdmComprasSesiones;
                           const AUsuario, ASerieSes, ANumSes: string;
                           ALinea: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos ' +
      '  (CODIGO_ART_ART, ESACTIVO_ART, TIPO_ART, DESCRIPCION_ART, ' +
      '   CODIGO_FAM_ART, TIPO_IVA_ART, TIPO_CANTIDAD_ART, ESVARIACION_ART, ' +
      '   ESTRAZABLE_ART, TIPO_VARIACION_ART, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT COALESCE(L.CODIGO_ART_REUSAR_SESLIN, ' +
      'L.CODIGO_ART_TENTATIVO_SESLIN), ' +
      '       ''S'', L.TIPO_ART_SESLIN, ' +
      '       CASE WHEN IFNULL(S.ESCOPIAR_DESCRIPCION_FAM_SES, ''S'') = ' +
      '                      ''S'' ' +
      '            THEN COALESCE(NULLIF(F.DESCRIPCION_FAM, ''''), ' +
      '                          L.DESCRIPCION_SESLIN) ' +
      '            ELSE L.DESCRIPCION_SESLIN END, ' +
      '       COALESCE(L.CODIGO_FAM_SESLIN, S.CODIGO_FAM_SES), ' +
      '       CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '            THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                          NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '            ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '       END, ' +
      '       L.TIPO_CANTIDAD_SESLIN, ' +
      '       CASE WHEN L.TIPO_LINEA_SESLIN = ''MATRIZ'' THEN ''S'' ELSE ' +
      '''N'' END, ' +
      '       L.ESTRAZABLE_SESLIN, ' +
      '       COALESCE(L.CODIGO_VAR_SESLIN, S.CODIGO_VAR_SES), ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_articulos_familias F ' +
      '         ON F.CODIGO_FAM_FAM = ' +
      '            COALESCE(L.CODIGO_FAM_SESLIN, S.CODIGO_FAM_SES) ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN IS NULL)';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure InsertarConjuntosAtributos(AConn: TUniConnection;
                                     const ASerieSes, ANumSes,
                                           ACodigoArt, AUsuario: string;
                                     ALinea: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // Pivot. COALESCE en cascada para ID_VA_ACA:
    //   1) L.ID_VA_PIVOT_SESLIN (si el usuario lo seteo en la linea)
    //   2) S.ID_VA_PIVOT_SES    (si lo seteo en la cabecera)
    //   3) AC_P.ID_VA_AC        (del propio conjunto elegido por ID_AC)
    // Sin el fallback (3) las sesiones del flujo muestrario (combo
    // 'Sistema tallas' que solo guarda ID_AC_PIVOT_SESLIN) acababan con
    // ID_VA_ACA NULL -> INSERT IGNORE silenciaba el error NOT NULL y el
    // articulo se quedaba sin conjuntos asignados (Color/Talla "Sin
    // conjunto" en la ficha) y por tanto sin SKUs.
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ESGENERACION_AUTO_ACA, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :art, ' +
      '       COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES), ' +
      '       COALESCE(L.ID_VA_PIVOT_SESLIN, S.ID_VA_PIVOT_SES, ' +
      '                AC_P.ID_VA_AC), ' +
      '       ''S'', NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_atributos_conjuntos AC_P ' +
      '         ON AC_P.ID_AC = ' +
      '            COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES) ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l ' +
      '   AND COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES) IS NOT NULL';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
    // Fila — mismo fallback en cascada.
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ESGENERACION_AUTO_ACA, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :art, ' +
      '       COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES), ' +
      '       COALESCE(L.ID_VA_FILA_SESLIN, S.ID_VA_FILA_SES, ' +
      '                AC_F.ID_VA_AC), ' +
      '       ''S'', NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_atributos_conjuntos AC_F ' +
      '         ON AC_F.ID_AC = ' +
      '            COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES) ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l ' +
      '   AND COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES) IS NOT NULL';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure InsertarPropiedadesFijas(AConn: TUniConnection;
                                   const ASerieSes, ANumSes, ACodigoArt,
                                         AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_propiedades ' +
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
      '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT :art, P.CODIGO_PROP_SESPROP, P.ID_PV_DEFECTO_SESPROP, ' +
      '       P.VALOR_DEFECTO_SESPROP, NOW(), :u ' +
      '  FROM fza_compras_sesiones_props P ' +
      ' WHERE P.SERIE_SES_SESPROP = :s AND P.NUMERO_SES_SESPROP = :n ' +
      '   AND P.ESFIJO_SESPROP = ''S''';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Sanea un texto de color libre del proveedor para usarlo como segmento del
// CODIGO_UNIDAD_SKU y como valor (AV) de fza_atributos_valores: mayusculas;
// los espacios pasan a '-'; se conservan letras, digitos, '-' y '_'; el resto
// de simbolos (/, %, EUR, ., :, ...) queda PROHIBIDO y se descarta. Sin
// separadores repetidos ni en los extremos. '' si no queda nada utilizable.
// IMPORTANTE: el servidor de fotos debe nombrar el token COLOR con esta MISMA
// regla (ver SanearColorFoto en inLibFotosNube) para que la foto case.
function SanearColorSku(const ATexto: string): string;
begin
  Result := inLibComprasSesionesReglas.SanearColorSku(ATexto);
end;

// Devuelve el ID_AV que debe llevar el color del SKU. Modelo de negocio: el
// color del SKU es el TEXTO DEL PROVEEDOR (COLOR_TEXTO_SESLIN) saneado, que
// es la identidad real del color; el color basico (CODIGO_ATB_COLOR_SESLIN)
// es solo un helper de clasificacion que se guarda en
// fza_atributos_valores.ID_ATB_AV (HEX, agrupacion, etiquetas). Prioridad
// del valor que va al SKU:
//   1. Texto del proveedor saneado.
//   2. Si no hay texto, el codigo del basico (compatibilidad).
// El AV se identifica por (ID_VA_AV='CO', AV=valor): si ya existe se reusa,
// si no se crea enlazandolo al basico cuando este disponible. Devuelve 0 si
// la linea no tiene ninguna informacion de color (el SKU sale sin color).
// NOTA: dos proveedores con texto distinto para el mismo color basico
// generan AV/SKU distintos (identidad por proveedor, decision de negocio).
function ResolverIdColorBasico(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoAtbColor: string): Integer;
begin
  Result := 0;
  if Trim(ACodigoAtbColor) <> '' then
  begin
    Result := ALecturas.ObtenerIdColorBasico(ACodigoAtbColor);
    if Result = 0 then
      raise Exception.CreateFmt(
        SErrorColorBasicoMaterializacionNoExiste,
        [ACodigoAtbColor]);
  end;
end;

function BuscarValorColor(
  const ALecturas: ILecturasArticulosMaterializacion;
  const AValor: string;
  out ATieneColorBasico: Boolean): Integer;
var
  oValor: TValorColorMaterializacion;
begin
  oValor := ALecturas.BuscarValorColor(AValor);
  Result := oValor.IdValor;
  ATieneColorBasico := oValor.TieneColorBasico;
end;

procedure AsignarColorBasicoAValor(
  AQuery: TUniQuery;
  AIdValor, AIdColorBasico: Integer);
begin
  AQuery.SQL.Text :=
    'UPDATE fza_atributos_valores ' +
    '   SET ID_ATB_AV = :ia ' +
    ' WHERE ID_AV = :idav';
  AQuery.ParamByName('ia').AsInteger := AIdColorBasico;
  AQuery.ParamByName('idav').AsInteger := AIdValor;
  AQuery.ExecSQL;
end;

function CrearValorColor(
  AQuery: TUniQuery;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AValor, ADescripcion, AUsuario: string;
  AIdColorBasico: Integer): Integer;
var
  oValor: TValorColorMaterializacion;
begin
  if AIdColorBasico > 0 then
  begin
    AQuery.SQL.Text :=
      'INSERT INTO fza_atributos_valores ' +
      '  (ID_VA_AV, AV, DESCRIPCION_AV, ID_ATB_AV, ' +
      '   ESACTIVO_AV, ORDEN_AV, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (''CO'', :v, :d, :ia, ''S'', 0, ' +
      '        NOW(), :u, NOW(), :u)';
    AQuery.ParamByName('ia').AsInteger := AIdColorBasico;
  end
  else
    AQuery.SQL.Text :=
      'INSERT INTO fza_atributos_valores ' +
      '  (ID_VA_AV, AV, DESCRIPCION_AV, ESACTIVO_AV, ORDEN_AV, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (''CO'', :v, :d, ''S'', 0, NOW(), :u, NOW(), :u)';
  AQuery.ParamByName('v').AsString := AValor;
  AQuery.ParamByName('d').AsString := Trim(ADescripcion);
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
  oValor := ALecturas.BuscarValorColor(AValor);
  Result := oValor.IdValor;
end;

function ResolverIdAvColorLinea(AConn: TUniConnection;
                                 const ALecturas:
                                 ILecturasArticulosMaterializacion;
                                 const AColorTexto, ACodigoAtbColor,
                                       AUsuario: string;
                                 out AValor: string): Integer;
var
  q: TUniQuery;
  iIdColorBasico: Integer;
  sValor: string;
  bTieneColorBasico: Boolean;
begin
  Result := 0;
  AValor := '';
  sValor := SanearColorSku(AColorTexto);
  if sValor = '' then
    sValor := SanearColorSku(ACodigoAtbColor);
  if sValor <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      iIdColorBasico :=
        ResolverIdColorBasico(ALecturas, ACodigoAtbColor);
      Result := BuscarValorColor(
        ALecturas, sValor, bTieneColorBasico);
      if Result = 0 then
        Result := CrearValorColor(
          q, ALecturas, sValor, AColorTexto, AUsuario,
          iIdColorBasico)
      else if (not bTieneColorBasico) and
              (iIdColorBasico > 0) then
        AsignarColorBasicoAValor(
          q, Result, iIdColorBasico);
      if Result > 0 then
        AValor := sValor;
    finally
      FreeAndNil(q);
    end;
  end;
end;

// Devuelve el prefijo de COLOR (los dos primeros segmentos, ART/COLOR) de
// un CODIGO_UNIDAD_SKU, EXACTAMENTE como lo calcula la vista
// vi_articulos_propiedades_efectivas (SUBSTRING_INDEX(sku,'/',2)). Sirve
// para fijar la temporada a nivel color en la propagacion de la sesion.
// Devuelve '' si el SKU no llega a dos '/' (no tiene nivel color: el SKU
// es ART/TALLA y la temporada se queda a nivel articulo).
function PrefijoColorSku(const ASku: string): string;
var
  i, nBarras, posSegunda: Integer;
begin
  nBarras    := 0;
  posSegunda := 0;
  for i := 1 to Length(ASku) do
  begin
    if (ASku[i] = '/') and (posSegunda = 0) then
    begin
      Inc(nBarras);
      if nBarras = 2 then
        posSegunda := i;
    end;
  end;
  if posSegunda > 0 then
    Result := Copy(ASku, 1, posSegunda - 1)
  else
    Result := '';
end;

function CargarColorLineaSku(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ASerieSesion, ANumeroSesion, AUsuario: string;
  ALinea: Integer;
  out AValorColor: string): Integer;
var
  oColor: TColorLineaMaterializacion;
begin
  oColor := ALecturas.ObtenerColorLinea(
    ASerieSesion,
    ANumeroSesion,
    ALinea);
  Result := ResolverIdAvColorLinea(
    AConn,
    ALecturas,
    oColor.Texto,
    oColor.CodigoBasico,
    AUsuario,
    AValorColor);
end;

procedure AsociarColorBasicoArticulo(
  AQuery: TUniQuery;
  const ACodigoArticulo, AUsuario: string;
  AIdColor: Integer);
begin
  if AIdColor > 0 then
  begin
    AQuery.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_atributos_basicos ' +
      '  (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'SELECT :art, AV.ID_AV, AV.ID_ATB_AV, ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_atributos_valores AV ' +
      ' WHERE AV.ID_AV = :av ' +
      '   AND AV.ID_ATB_AV IS NOT NULL';
    AQuery.ParamByName('art').AsString := ACodigoArticulo;
    AQuery.ParamByName('av').AsInteger := AIdColor;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

procedure InsertarSkuMaterializado(
  AQuery: TUniQuery;
  const ACodigoSku, ACodigoArticulo, AUsuario: string);
begin
  AQuery.SQL.Text :=
    'INSERT IGNORE INTO fza_articulos_skus ' +
    '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
    '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:sku, :art, ''TC'', ''S'', NOW(), :u, NOW(), :u)';
  AQuery.ParamByName('sku').AsString := ACodigoSku;
  AQuery.ParamByName('art').AsString := ACodigoArticulo;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;

procedure InsertarAtributoSkuMaterializado(
  AQuery: TUniQuery;
  const ACodigoSku, AUsuario: string;
  AIdValor: Integer);
begin
  if AIdValor > 0 then
  begin
    AQuery.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_sku ' +
      '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
      '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
    AQuery.ParamByName('sku').AsString := ACodigoSku;
    AQuery.ParamByName('av').AsInteger := AIdValor;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

procedure InsertarTemporadaColorSku(
  AQuery: TUniQuery;
  const ACodigoArticulo, ACodigoSku, AUsuario: string;
  AIdPropiedadTemporada: Integer);
var
  sPrefijoColor: string;
begin
  sPrefijoColor := PrefijoColorSku(ACodigoSku);
  if (AIdPropiedadTemporada > 0) and
     (sPrefijoColor <> '') then
  begin
    AQuery.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_propiedades ' +
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ' +
      '   CODIGO_UNIDAD_ARTPROP, ID_PV_ARTPROP, ' +
      '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:art, ''TEMPORADA'', :uni, :pv, NULL, NOW(), :u)';
    AQuery.ParamByName('art').AsString := ACodigoArticulo;
    AQuery.ParamByName('uni').AsString := sPrefijoColor;
    AQuery.ParamByName('pv').AsInteger :=
      AIdPropiedadTemporada;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

procedure AsegurarEan13Sku(
  const ALecturas: ILecturasArticulosMaterializacion;
  AQuery: TUniQuery;
  const ACodigoSku, APrefijoEan, AUsuario: string);
var
  sEan13: string;
begin
  if not ALecturas.ExisteEan13Sku(ACodigoSku) then
  begin
    sEan13 := GenerarEAN13Local(ALecturas, APrefijoEan);
    AQuery.SQL.Text :=
      'INSERT IGNORE INTO fza_codigos_barras ' +
      '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
      '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:cb, :sku, ''EAN13'', ''S'', ' +
      '        NOW(), :u, NOW(), :u)';
    AQuery.ParamByName('cb').AsString := sEan13;
    AQuery.ParamByName('sku').AsString := ACodigoSku;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

procedure ProcesarSkuSesion(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ASku: TSkuSesionMaterializacion;
  AOperacion: TUniQuery;
  const ACodigoArticulo, AUsuario, APrefijoEan,
        AValorColor: string;
  AIdColor, AIdPropiedadTemporada: Integer);
var
  sCodigoSku: string;
  sValorPivot: string;
  sValorFila: string;
  iIdPivot: Integer;
  iIdFila: Integer;
begin
  sValorPivot := ASku.ValorPivot;
  sValorFila := ASku.ValorFila;
  iIdPivot := ASku.IdAvPivot;
  iIdFila := ASku.IdAvFila;
  if (iIdFila = 0) and (AIdColor > 0) then
  begin
    iIdFila := AIdColor;
    sValorFila := AValorColor;
  end;
  if sValorFila = '' then
    sCodigoSku := ACodigoArticulo + '/' + sValorPivot
  else
    sCodigoSku :=
      ACodigoArticulo + '/' + sValorFila + '/' + sValorPivot;
  InsertarSkuMaterializado(
    AOperacion, sCodigoSku, ACodigoArticulo, AUsuario);
  InsertarAtributoSkuMaterializado(
    AOperacion, sCodigoSku, AUsuario, iIdFila);
  InsertarAtributoSkuMaterializado(
    AOperacion, sCodigoSku, AUsuario, iIdPivot);
  InsertarTemporadaColorSku(
    AOperacion, ACodigoArticulo, sCodigoSku, AUsuario,
    AIdPropiedadTemporada);
  AsegurarEan13Sku(
    ALecturas, AOperacion, sCodigoSku, APrefijoEan, AUsuario);
end;

procedure InsertarSkusYBarras(AConn: TUniConnection;
                              const ALecturas:
                              ILecturasArticulosMaterializacion;
                              const ASerieSes, ANumSes, ACodigoArt,
                                    AUsuario, APrefijoEAN: string;
                              ALinea: Integer;
                              AIdPvTemporada: Integer);
var
  oSkus: TSkusSesionMaterializacion;
  qOperacion: TUniQuery;
  sValorColor: string;
  iIdColor: Integer;
  iSku: Integer;
begin
  iIdColor := CargarColorLineaSku(
    AConn, ALecturas, ASerieSes, ANumSes, AUsuario, ALinea,
    sValorColor);
  oSkus := ALecturas.ConsultarSkusSesion(
    ASerieSes,
    ANumSes,
    ALinea);
  qOperacion := TUniQuery.Create(nil);
  try
    qOperacion.Connection := AConn;
    AsociarColorBasicoArticulo(
      qOperacion, ACodigoArt, AUsuario, iIdColor);
    for iSku := 0 to High(oSkus) do
    begin
      ProcesarSkuSesion(
        ALecturas, oSkus[iSku], qOperacion, ACodigoArt, AUsuario,
        APrefijoEAN, sValorColor, iIdColor, AIdPvTemporada);
    end;
  finally
    FreeAndNil(qOperacion);
  end;
end;

procedure UpsertArticuloProveedor(AConn: TUniConnection;
                                  const ALecturas:
                                  ILecturasArticulosMaterializacion;
                                  const ACodigoArt, ACodigoPrv,
                                        ARefPrv, AUsuario: string;
                                  APrecio: Double);
var
  q: TUniQuery;
  bHayPrincipal: Boolean;
  sEsPrincipal: string;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // 1. Si el articulo ya tiene OTRO proveedor marcado como principal,
    //    el nuevo no se lo roba: se inserta con ESPRINCIPAL='N'. Si la
    //    fila ya existe (mismo prv+art) el flag no se toca en el UPDATE.
    bHayPrincipal :=
      ALecturas.ExisteProveedorPrincipalDistinto(
        ACodigoArt,
        ACodigoPrv);
    if bHayPrincipal then
      sEsPrincipal := 'N'
    else
      sEsPrincipal := 'S';

    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_proveedores ' +
      '  (CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
      '   PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ESPROVEEDORPRINCIPAL_AP, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:prv, :art, :ref, :pre, NOW(), :prin, NOW(), :u, NOW(), :u) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_AP = :pre, FECHA_VALIDEZ_AP = NOW(), ' +
      '  REF_PROVEEDOR_AP = :ref, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
    q.ParamByName('prv').AsString  := ACodigoPrv;
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('ref').AsString  := ARefPrv;
    q.ParamByName('pre').AsFloat   := APrecio;
    q.ParamByName('prin').AsString := sEsPrincipal;
    q.ParamByName('u').AsString    := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// que reusos (ACCION=REUSAR) que ya tienen TEMPORADA distinta no se
// pisen.
procedure InsertarTemporadaCabecera(AConn: TUniConnection;
                                     const ACodigoArt, AUsuario: string;
                                     AIdPvTemporada: Integer);
var
  q: TUniQuery;
begin
  if AIdPvTemporada > 0 then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'INSERT IGNORE INTO fza_articulos_propiedades ' +
        '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
        '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'VALUES (:art, ''TEMPORADA'', :pv, NULL, NOW(), :u)';
      q.ParamByName('art').AsString := ACodigoArt;
      q.ParamByName('pv').AsInteger := AIdPvTemporada;
      q.ParamByName('u').AsString   := AUsuario;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  end;
end;

// Crea (o actualiza) la fila de fza_articulos_tarifas para la tarifa de
// patron "padre" (CODIGO_UNIDAD_ARTTAR='') que el resto del sistema
// hereda al SKU si no hay override.
procedure UpsertArticuloTarifa(AConn: TUniConnection;
                               const ALecturas:
                               ILecturasArticulosMaterializacion;
                               const ACodigoArt, ACodigoTar,
                                     AUsuario: string;
                               APrecioVenta: Double);
var
  q: TUniQuery;
  iCodigoUnico: Integer;
begin
  if (Trim(ACodigoTar) <> '') and (APrecioVenta > 0) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
    // fza_articulos_tarifas tiene PK = CODIGO_UNICO_ARTTAR (autoincrement),
    // sin UNIQUE KEY logico sobre (CODIGO_ART, CODIGO_UNIDAD, CODIGO_TAR).
    // ON DUPLICATE KEY UPDATE nunca disparaba porque el autoincrement no
    // colisiona, asi que cada llamada (una por linea de la sesion)
    // inseraba una fila nueva: si la sesion tenia 2 lineas REUSAR del
    // mismo articulo, se acababan con 2 tarifas iguales. Hacemos upsert
    // manual: SELECT por (CODIGO_ART, CODIGO_UNIDAD='', CODIGO_TAR) ->
    // si existe UPDATE, si no existe INSERT.
    iCodigoUnico := ALecturas.ObtenerCodigoUnicoTarifa(
      ACodigoArt,
      ACodigoTar);

    if iCodigoUnico > 0 then
    begin
      q.SQL.Text :=
        'UPDATE fza_articulos_tarifas ' +
        '   SET PRECIO_SALIDA_ARTTAR = :pre, ' +
        '       PRECIO_FINAL_ARTTAR  = :pre, ' +
        '       ESACTIVO_ARTTAR      = ''S'', ' +
        '       INSTANTE_MODIF       = NOW(), ' +
        '       USUARIO_MODIF        = :u ' +
        ' WHERE CODIGO_UNICO_ARTTAR  = :cu';
      q.ParamByName('cu').AsInteger := iCodigoUnico;
    end
    else
    begin
      q.SQL.Text :=
        'INSERT IGNORE INTO fza_articulos_tarifas ' +
        '  (CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
        '   ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
        '   FECHA_DESDE_ARTTAR, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:art, '''', :tar, ''S'', :pre, :pre, CURDATE(), ' +
        '        NOW(), :u, NOW(), :u)';
      q.ParamByName('art').AsString := ACodigoArt;
      q.ParamByName('tar').AsString := ACodigoTar;
    end;
      q.ParamByName('pre').AsFloat  := APrecioVenta;
      q.ParamByName('u').AsString   := AUsuario;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  end;
end;

// Resuelve el CODIGO_UNIDAD_SKU para un articulo + ID_AV pivot
// (talla) y opcional ID_AV fila (color), en el orden estandar
// fza_articulos_skus + fza_atributos_sku. Devuelve '' si no se
// encuentra (puede pasar para articulos REUSAR cuyo SKU no existe
// todavia con ese par de atributos: en ese caso el llamante puede
// crearlo o saltarse el movimiento).
function ResolverCodigoSku(
                            const ALecturas:
                            ILecturasArticulosMaterializacion;
                            const ACodigoArt: string;
                            AIdAvPivot, AIdAvFila: Integer): string;
begin
  Result := ALecturas.ResolverCodigoSku(
    ACodigoArt,
    AIdAvPivot,
    AIdAvFila);
end;

// Crea la cabecera del albaran de compra en fza_albaranes_compra y sus
// lineas (una por SKU + almacen con cantidad > 0). Devuelve el
// NUMERO_ALBC generado. Denormaliza datos de empresa y proveedor desde
// fza_empresas y fza_proveedores (mismo patron que albaranes de venta).
// La cabecera CODIGO_ALM_ALBC arranca con el almacen de la sesion;
// cada linea lleva su propio CODIGO_ALMACEN_ALBCLIN (puede diferir si
// la celda venia con almacen explicito).

procedure MaterializarArticulosSesion(
  ADM: TdmComprasSesiones;
  AFotos: TFotosArticulos;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AUsuario: string);
var
  oLineas: TLineasArticuloMaterializacion;
  sCodigoArt: string;
  sCodigoProveedor: string;
  sCodigoTarifa: string;
  sNumeroSesion: string;
  sPrefijoEan: string;
  sSerieSesion: string;
  iIdPropiedadTemporada: Integer;
  iIndice: Integer;
  iLin: Integer;
  rPrecio: Double;
  rPrecioVta: Double;
begin
  sSerieSesion :=
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumeroSesion :=
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sCodigoProveedor :=
    ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
  sPrefijoEan :=
    ADM.unqryTablaG.FieldByName('PREFIJO_EAN_SES').AsString;
  sCodigoTarifa :=
    ADM.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString;
  iIdPropiedadTemporada := 0;
  if not ADM.unqryTablaG.FieldByName(
    'ID_PV_TEMPORADA_SES').IsNull then
    iIdPropiedadTemporada :=
      ADM.unqryTablaG.FieldByName(
        'ID_PV_TEMPORADA_SES').AsInteger;
  oLineas := ALecturas.ConsultarLineasArticulos(
    sSerieSesion,
    sNumeroSesion);
  for iIndice := 0 to High(oLineas) do
  begin
    iLin := oLineas[iIndice].Linea;
    rPrecio := oLineas[iIndice].PrecioCosteProveedor;
    if oLineas[iIndice].AccionDuplicado = 'REUSAR' then
      sCodigoArt := oLineas[iIndice].CodigoArticuloReusar
    else
    begin
      sCodigoArt := oLineas[iIndice].CodigoArticuloTentativo;
      InsertarArticulo(
        ADM.ConexionPrincipal,
        ADM,
        AUsuario,
        sSerieSesion,
        sNumeroSesion,
        iLin);
    end;
    if oLineas[iIndice].TipoLinea = 'MATRIZ' then
    begin
      InsertarConjuntosAtributos(
        ADM.ConexionPrincipal,
        sSerieSesion,
        sNumeroSesion,
        sCodigoArt,
        AUsuario,
        iLin);
      InsertarSkusYBarras(
        ADM.ConexionPrincipal,
        ALecturas,
        sSerieSesion,
        sNumeroSesion,
        sCodigoArt,
        AUsuario,
        sPrefijoEan,
        iLin,
        iIdPropiedadTemporada);
    end;
    InsertarPropiedadesFijas(
      ADM.ConexionPrincipal,
      sSerieSesion,
      sNumeroSesion,
      sCodigoArt,
      AUsuario);
    InsertarTemporadaCabecera(
      ADM.ConexionPrincipal,
      sCodigoArt,
      AUsuario,
      iIdPropiedadTemporada);
    if oLineas[iIndice].TipoLinea <> 'SERVICIO' then
    begin
      UpsertArticuloProveedor(
        ADM.ConexionPrincipal,
        ALecturas,
        sCodigoArt,
        sCodigoProveedor,
        oLineas[iIndice].ReferenciaProveedor,
        AUsuario,
        rPrecio);
      rPrecioVta := oLineas[iIndice].PrecioVenta;
      UpsertArticuloTarifa(
        ADM.ConexionPrincipal,
        ALecturas,
        sCodigoArt,
        sCodigoTarifa,
        AUsuario,
        rPrecioVta);
    end;
    if Assigned(AFotos) then
    begin
      AFotos.MigrarFotosSesion(
        sSerieSesion,
        sNumeroSesion,
        iLin,
        sCodigoArt,
        AUsuario);
    end;
  end;
end;

end.
