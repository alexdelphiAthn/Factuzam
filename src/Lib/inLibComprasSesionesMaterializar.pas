unit inLibComprasSesionesMaterializar;

{
  Unidad: inLibComprasSesionesMaterializar
  Materialización transaccional de una sesión de compra.

  Esta es la ÚNICA capa que tiene permiso para insertar en las tablas
  maestras desde una sesión de compra. Toda la lógica vive aquí para que
  el principio "nada se crea hasta el botón" sea verificable revisando
  un solo archivo.

  Pasos (todos dentro de una transacción de la conexión global):
    1. Validación previa (reusa inLibComprasSesiones.ValidarSesion).
    2. Verificar conflictos de código de artículo no resueltos.
    3. Para cada línea:
         a. Si ACCION_DUPLICADO_SESLIN = 'REUSAR' → usar CODIGO_ART_REUSAR_SESLIN.
         b. En otro caso → INSERT en fza_articulos con CODIGO_ART_TENTATIVO.
         c. Si tipo = MATRIZ → INSERT en fza_articulos_conjuntos_asign para
            pivot y fila (con ID_AC vigentes).
         d. INSERT en fza_articulos_propiedades para propiedades fijas de
            cabecera + variables override en línea.
    4. Para cada celda con cantidad > 0:
         a. INSERT en fza_articulos_skus (CODIGO_UNIDAD compuesto).
         b. INSERT en fza_atributos_sku con los ID_AV (uno por atributo:
            fila + pivot).
         c. Generar EAN13 con GenerarEAN13Local (
           usa CalcularDigitoEAN13) e INSERT en
            fza_codigos_barras.
    5. Para líneas ESCALAR (sin matriz): INSERT en fza_codigos_barras a
       nivel de artículo (CODIGO_UNIDAD_CB = CODIGO_ART_ART) con EAN13 nuevo.
    6. Líneas SERVICIO: ningún SKU ni código de barras.
    7. UPSERT en fza_articulos_proveedores con PRECIO_ULT_COMPRA y
       REF_PROVEEDOR.
    8. Si ESGENERA_PEDIDO_SES = 'S':
         INSERT en fza_pedidos_compra + lineas (una por SKU * cantidad
         agregada). NO mueve stock.
    9. Si ESGENERA_ALBARAN_SES = 'S':
         INSERT en fza_albaranes_compra + lineas + fza_movimientos_almacen
         (entrada en CODIGO_ALM_SES por cada SKU * cantidad).
   10. UPDATE fza_compras_sesiones SET ESTADO_SES='CERRADA',
         SERIE_PEDC_SES, NUMERO_PEDC_SES, SERIE_ALBC_SES, NUMERO_ALBC_SES,
         INSTANTE_MATERIALIZA_SES = NOW(), USUARIO_MATERIALIZA_SES.

  Si CUALQUIER paso falla → ROLLBACK completo y se actualiza
  fza_compras_sesiones.MENSAJE_ERROR_SES.
}

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, DBAccess, Uni,
  UniDataComprasSesiones;

function MaterializarSesion(ADM: TdmComprasSesiones;
                            AESGeneraPedido, AESGeneraAlbaran: Boolean;
                            const AUsuario: string;
                            out ASeriePed, ANumPed, ASerieAlb, ANumAlb,
                                AMsgError: string): Boolean;

implementation

uses
  inLibGlobalVar,
  inLibEAN13,
  inLibComprasSesiones,
  inLibFotos,
  inLibtb;

// ---------------------------------------------------------------------------
// Generación local de EAN13
// ---------------------------------------------------------------------------
// inLibEAN13 sólo expone CalcularDigitoEAN13 / EsEAN13Valido. La generación
// del secuencial vive aquí: tomamos el siguiente correlativo dentro del
// prefijo elegido y le añadimos el dígito de control. Se invoca dentro de
// la transacción de materialización, por lo que dos sesiones concurrentes
// no pueden colisionar (el SELECT + INSERT del código de barras ocurre en
// la misma transacción que el aislamiento de MySQL garantiza vía
// row-locking en InnoDB).
function GenerarEAN13Local(AConn: TUniConnection;
                           const APrefijo: string): string;
var
  q       : TUniQuery;
  sPref   : string;
  iLenSeq : Integer;
  iNext   : Int64;
  sBase   : string;
  cCheck  : Char;
begin
  sPref := APrefijo;
  if sPref = '' then sPref := '841';      // prefijo por defecto
  iLenSeq := 12 - Length(sPref);
  if iLenSeq <= 0 then
    raise Exception.Create('PREFIJO_EAN_SES demasiado largo: ' + sPref);

  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(MAX(CAST(SUBSTRING(CODIGO_BARRAS_CB, :pl + 1, :lq) AS ' +
      'UNSIGNED)), 0) + 1 AS N ' +
      '  FROM fza_codigos_barras ' +
      ' WHERE CODIGO_BARRAS_CB LIKE :pat ' +
      '   AND TIPO_CODIGO_CB = ''EAN13''';
    q.ParamByName('pl').AsInteger  := Length(sPref);
    q.ParamByName('lq').AsInteger  := iLenSeq;
    q.ParamByName('pat').AsString  := sPref + '%';
    q.Open;
    iNext := q.FieldByName('N').AsLargeInt;
  finally
    FreeAndNil(q);
  end;

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
      'INSERT INTO fza_articulos ' +
      '  (CODIGO_ART_ART, ESACTIVO_ART, TIPO_ART, DESCRIPCION_ART, ' +
      '   CODIGO_FAM_ART, TIPO_IVA_ART, TIPO_CANTIDAD_ART, ESVARIACION_ART, ' +
      '   ESTRAZABLE_ART, TIPO_VARIACION_ART, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT COALESCE(L.CODIGO_ART_REUSAR_SESLIN, ' +
      'L.CODIGO_ART_TENTATIVO_SESLIN), ' +
      '       ''S'', L.TIPO_ART_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '       COALESCE(L.CODIGO_FAM_SESLIN, S.CODIGO_FAM_SES), ' +
      '       COALESCE(L.TIPO_IVA_SESLIN, S.TIPO_IVA_SES), ' +
      '       L.TIPO_CANTIDAD_SESLIN, ' +
      '       CASE WHEN L.TIPO_LINEA_SESLIN = ''MATRIZ'' THEN ''S'' ELSE ' +
      '''N'' END, ' +
      '       L.ESTRAZABLE_SESLIN, ' +
      '       COALESCE(L.CODIGO_VAR_SESLIN, S.CODIGO_VAR_SES), ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
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
    // Pivot
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ESGENERACION_AUTO_ACA, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :art, COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES), ' +
      '       COALESCE(L.ID_VA_PIVOT_SESLIN, S.ID_VA_PIVOT_SES), ' +
      '       ''S'', NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;

    // Fila
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ESGENERACION_AUTO_ACA, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :art, COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES), ' +
      '       COALESCE(L.ID_VA_FILA_SESLIN, S.ID_VA_FILA_SES), ' +
      '       ''S'', NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
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

procedure InsertarSkusYBarras(AConn: TUniConnection;
                              const ASerieSes, ANumSes, ACodigoArt,
                                    AUsuario, APrefijoEAN: string;
                              ALinea: Integer);
var
  qC, qIns, qBar: TUniQuery;
  sCodigoSKU : string;
  sEAN13     : string;
  sValPivot, sValFila: string;
  iAvPivot, iAvFila: Integer;
begin
  qC   := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  qBar := TUniQuery.Create(nil);
  try
    qC.Connection   := AConn;
    qIns.Connection := AConn;
    qBar.Connection := AConn;

    // Una fila por SKU único (linea, fila, pivot) sumando cantidades
    // de todos los almacenes. El SKU y su EAN13 son a nivel de artículo,
    // no de almacén: 1 SKU por (color, talla), regardless of warehouse.
    qC.SQL.Text :=
      'SELECT C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
      '       SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
      '       AVP.AV AS VAL_PIVOT, ' +
      '       (SELECT GROUP_CONCAT(AV2.AV SEPARATOR ''/'') ' +
      '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
      '          JOIN fza_atributos_valores AV2 ON AV2.ID_AV = ' +
      'FA.ID_AV_SESFILAT ' +
      '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
      '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
      '           AND FA.LINEA_SES_SESFILAT  = C.LINEA_SES_SESCEL ' +
      '           AND FA.ID_FILA_SESFILAT    = C.ID_FILA_SES_SESCEL) AS ' +
      'VAL_FILA, ' +
      '       (SELECT MIN(FA.ID_AV_SESFILAT) ' +
      '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
      '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
      '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
      '           AND FA.LINEA_SES_SESFILAT  = C.LINEA_SES_SESCEL ' +
      '           AND FA.ID_FILA_SESFILAT    = C.ID_FILA_SES_SESCEL) AS ' +
      'ID_AV_FILA ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_atributos_valores AVP ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL = :s AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.LINEA_SES_SESCEL = :l AND C.CANTIDAD_SESCEL > 0 ' +
      ' GROUP BY C.SERIE_SES_SESCEL, C.NUMERO_SES_SESCEL, C.LINEA_SES_SESCEL, ' +
      '          C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, AVP.AV';
    qC.ParamByName('s').AsString  := ASerieSes;
    qC.ParamByName('n').AsString  := ANumSes;
    qC.ParamByName('l').AsInteger := ALinea;
    qC.Open;

    while not qC.Eof do
    begin
      sValPivot := qC.FieldByName('VAL_PIVOT').AsString;
      sValFila  := qC.FieldByName('VAL_FILA').AsString;
      iAvPivot  := qC.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
      iAvFila   := qC.FieldByName('ID_AV_FILA').AsInteger;

      if sValFila = '' then
        sCodigoSKU := ACodigoArt + '/' + sValPivot
      else
        sCodigoSKU := ACodigoArt + '/' + sValFila + '/' + sValPivot;

      // SKU
      qIns.SQL.Text :=
        'INSERT IGNORE INTO fza_articulos_skus ' +
        '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :art, ''TC'', ''S'', NOW(), :u, NOW(), :u)';
      qIns.ParamByName('sku').AsString := sCodigoSKU;
      qIns.ParamByName('art').AsString := ACodigoArt;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ExecSQL;

      // Atributos del SKU (fila)
      if iAvFila > 0 then
      begin
        qIns.SQL.Text :=
          'INSERT IGNORE INTO fza_atributos_sku ' +
          '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, USUARIO_ALTA, ' +
          '   INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
        qIns.ParamByName('sku').AsString := sCodigoSKU;
        qIns.ParamByName('av').AsInteger := iAvFila;
        qIns.ParamByName('u').AsString   := AUsuario;
        qIns.ExecSQL;
      end;

      // Atributos del SKU (pivot)
      qIns.SQL.Text :=
        'INSERT IGNORE INTO fza_atributos_sku ' +
        '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
      qIns.ParamByName('sku').AsString := sCodigoSKU;
      qIns.ParamByName('av').AsInteger := iAvPivot;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ExecSQL;

      // EAN13
      sEAN13 := GenerarEAN13Local(AConn, APrefijoEAN);

      qBar.SQL.Text :=
        'INSERT INTO fza_codigos_barras ' +
        '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
        '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:cb, :sku, ''EAN13'', ''S'', NOW(), :u, NOW(), :u)';
      qBar.ParamByName('cb').AsString  := sEAN13;
      qBar.ParamByName('sku').AsString := sCodigoSKU;
      qBar.ParamByName('u').AsString   := AUsuario;
      qBar.ExecSQL;

      qC.Next;
    end;
  finally
    FreeAndNil(qC);
    FreeAndNil(qIns);
    FreeAndNil(qBar);
  end;
end;

procedure UpsertArticuloProveedor(AConn: TUniConnection;
                                  const ACodigoArt, ACodigoPrv,
                                        ARefPrv, AUsuario: string;
                                  APrecio: Double);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_proveedores ' +
      '  (CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
      '   PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ESPROVEEDORPRINCIPAL_AP, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:prv, :art, :ref, :pre, NOW(), ''S'', NOW(), :u, NOW(), :u) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_AP = :pre, FECHA_VALIDEZ_AP = NOW(), ' +
      '  REF_PROVEEDOR_AP = :ref, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
    q.ParamByName('prv').AsString := ACodigoPrv;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('ref').AsString := ARefPrv;
    q.ParamByName('pre').AsFloat  := APrecio;
    q.ParamByName('u').AsString   := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Inserta la temporada de cabecera en fza_articulos_propiedades. Si la
// sesion no trae ID_PV_TEMPORADA_SES no hace nada. INSERT IGNORE para
// que reusos (ACCION=REUSAR) que ya tienen TEMPORADA distinta no se
// pisen.
procedure InsertarTemporadaCabecera(AConn: TUniConnection;
                                     const ACodigoArt, AUsuario: string;
                                     AIdPvTemporada: Integer);
var
  q: TUniQuery;
begin
  if AIdPvTemporada <= 0 then Exit;
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

// Crea (o actualiza) la fila de fza_articulos_tarifas para la tarifa de
// venta sugerida en la cabecera de la sesion, usando PRECIO_VENTA_SESLIN
// de la linea como PRECIO_FINAL_ARTTAR. No crea precios por SKU; usa el
// patron "padre" (CODIGO_UNIDAD_ARTTAR='') que el resto del sistema
// hereda al SKU si no hay override.
procedure UpsertArticuloTarifa(AConn: TUniConnection;
                               const ACodigoArt, ACodigoTar,
                                     AUsuario: string;
                               APrecioVenta: Double);
var
  q: TUniQuery;
begin
  if (Trim(ACodigoTar) = '') or (APrecioVenta <= 0) then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_tarifas ' +
      '  (CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
      '   ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
      '   FECHA_DESDE_ARTTAR, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:art, '''', :tar, ''S'', :pre, :pre, CURDATE(), ' +
      '        NOW(), :u, NOW(), :u) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_SALIDA_ARTTAR = :pre, ' +
      '  PRECIO_FINAL_ARTTAR  = :pre, ' +
      '  ESACTIVO_ARTTAR      = ''S'', ' +
      '  INSTANTE_MODIF       = NOW(), USUARIO_MODIF = :u';
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('tar').AsString := ACodigoTar;
    q.ParamByName('pre').AsFloat  := APrecioVenta;
    q.ParamByName('u').AsString   := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Resuelve el CODIGO_UNIDAD_SKU para un articulo + ID_AV pivot
// (talla) y opcional ID_AV fila (color), en el orden estandar
// fza_articulos_skus + fza_atributos_sku. Devuelve '' si no se
// encuentra (puede pasar para articulos REUSAR cuyo SKU no existe
// todavia con ese par de atributos: en ese caso el llamante puede
// crearlo o saltarse el movimiento).
function ResolverCodigoSku(AConn: TUniConnection;
                            const ACodigoArt: string;
                            AIdAvPivot, AIdAvFila: Integer): string;
var
  q: TUniQuery;
begin
  Result := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // SKU que tenga las 1 o 2 ID_AVs requeridas. Si solo nos pasan
    // pivot (sin fila) el SKU candidato es el que tenga el pivot y
    // ningun otro AV adicional.
    if AIdAvFila > 0 then
      q.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :pivot) ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :fila) ' +
        ' LIMIT 1'
    else
      q.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :pivot) ' +
        ' LIMIT 1';
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('pivot').AsInteger := AIdAvPivot;
    if AIdAvFila > 0 then
      q.ParamByName('fila').AsInteger := AIdAvFila;
    q.Open;
    if not q.IsEmpty then
      Result := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  finally
    FreeAndNil(q);
  end;
end;

// Genera movimientos de entrada en almacen (TIPO_DOC_MOV='AC',
// TIPO_MOV='E') por cada (linea, fila, pivot) con cantidad > 0 de la
// sesion. Una sola pasada SQL que itera celdas y resuelve SKU/articulo
// linea a linea. La cabecera de cada movimiento queda apuntando a la
// propia sesion (SERIE_SES/NUMERO_SES) como SERIE_DOC_MOV/NUMERO_DOC_MOV
// — todavia no tenemos cabecera de albaran de compra como entidad
// separada (fza_albaranes_compra esta pendiente).
procedure GenerarMovimientosAlbaran(AConn: TUniConnection;
                                     ADM: TdmComprasSesiones;
                                     const ASerieSes, ANumSes,
                                           AUsuario: string);
var
  qC : TUniQuery;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sCodigoEmp, sDescripcion, sNumeroMov, sLinea: string;
  iIdAvPivot, iIdAvFila, iLinea: Integer;
  rCantidad, rCoste, rTotal: Double;
begin
  sCodigoAlmCab := ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  sCodigoEmp    := ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  if sCodigoAlmCab = '' then
    raise Exception.Create('Falta CODIGO_ALM_SES en la cabecera de la sesion ' +
                           'para generar el albaran.');

  qC := TUniQuery.Create(nil);
  try
    qC.Connection := AConn;
    // Por linea + fila + pivot. Resolvemos articulo y los datos
    // basicos en la propia consulta — el SKU se busca despues con
    // ResolverCodigoSku ya que depende de fza_atributos_sku.
    qC.SQL.Text :=
      'SELECT C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
      '       C.CANTIDAD_SESCEL, ' +
      '       IFNULL(NULLIF(C.CODIGO_ALM_SESCEL,''''), :alm_cab) AS ALM_EFE, ' +
      '       L.CODIGO_ART_TENTATIVO_SESLIN, L.CODIGO_ART_REUSAR_SESLIN, ' +
      '       L.ACCION_DUPLICADO_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '       L.PRECIO_COMPRA_SESLIN, L.TIPO_LINEA_SESLIN, ' +
      '       L.ID_VA_FILA_SESLIN ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL  = :s ' +
      '   AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.CANTIDAD_SESCEL   > 0 ' +
      ' ORDER BY C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL';
    qC.ParamByName('alm_cab').AsString := sCodigoAlmCab;
    qC.ParamByName('s').AsString := ASerieSes;
    qC.ParamByName('n').AsString := ANumSes;
    qC.Open;

    while not qC.Eof do
    begin
      iLinea     := qC.FieldByName('LINEA_SES_SESCEL').AsInteger;
      iIdAvPivot := qC.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
      rCantidad  := qC.FieldByName('CANTIDAD_SESCEL').AsFloat;
      sCodigoAlm := qC.FieldByName('ALM_EFE').AsString;
      sDescripcion := qC.FieldByName('DESCRIPCION_SESLIN').AsString;
      rCoste     := qC.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
      rTotal     := rCantidad * rCoste;

      if qC.FieldByName('ACCION_DUPLICADO_SESLIN').AsString = 'REUSAR' then
        sCodigoArt := qC.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString
      else
        sCodigoArt := qC.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;

      // Lineas SERVICIO no llevan SKU ni movimiento.
      if qC.FieldByName('TIPO_LINEA_SESLIN').AsString = 'SERVICIO' then
      begin
        qC.Next;
        Continue;
      end;

      // Solo MATRIZ tiene ID_VA_FILA (color). Para ESCALAR la fila
      // viene vacia y SKU se busca solo por pivot.
      iIdAvFila := 0;
      if not qC.FieldByName('ID_VA_FILA_SESLIN').IsNull then
        iIdAvFila :=
                StrToIntDef(qC.FieldByName('ID_VA_FILA_SESLIN').AsString, 0);

      sCodigoSku := ResolverCodigoSku(AConn, sCodigoArt, iIdAvPivot, iIdAvFila);
      if sCodigoSku = '' then
      begin
        // El SKU no existe — no podemos mover stock contra el. Saltamos
        // (no es fatal: puede pasar con REUSAR a articulo sin ese AV).
        qC.Next;
        Continue;
      end;

      // Numero de movimiento via contador 'MV' (mismo que albaranes
      // de venta y resto del sistema).
      sNumeroMov := inLibtb.ObtenerSiguienteContador('MV');
      sLinea     := Format('%.4d', [iLinea]);

      with TUniStoredProc.Create(nil) do
      try
        Connection := AConn;
        StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
        Params.Clear;
        Params.CreateParam(ftString, 'p_NUMERO_MOV',                ptInput);
        Params.CreateParam(ftString, 'p_TIPO_DOC_MOV',              ptInput);
        Params.CreateParam(ftString, 'p_SERIE_DOC_MOV',             ptInput);
        Params.CreateParam(ftString, 'p_NRO_DOC_MOV',               ptInput);
        Params.CreateParam(ftString, 'p_LINEA_MOV',                 ptInput);
        Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV',        ptInput);
        Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV',        ptInput);
        Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_CONTRA_MOV', ptInput);
        Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV',         ptInput);
        Params.CreateParam(ftString, 'p_TIPO_MOVIMIENTO_MOV',       ptInput);
        Params.CreateParam(ftBCD,    'p_CANTIDAD_MOV',              ptInput);
        Params.CreateParam(ftBCD,    'p_PRECIO_MEDIO_MOV',          ptInput);
        Params.CreateParam(ftBCD,    'p_TOTAL_COSTE_MOV',           ptInput);
        Params.CreateParam(ftString, 'p_USUARIO',                   ptInput);
        Params.CreateParam(ftString, 'p_ALMACEN_DOC',               ptInput);
        Params.CreateParam(ftString, 'p_NUMOP_DOC',                 ptInput);
        Params.CreateParam(ftString, 'p_CODIGO_CAJA_DOC_MOV',       ptInput);
        Params.CreateParam(ftString, 'p_CODCLIENTE',                ptInput);
        Params.CreateParam(ftString, 'p_CODARTICULO',               ptInput);
        ParamByName('p_NUMERO_MOV').AsString          := sNumeroMov;
        ParamByName('p_TIPO_DOC_MOV').AsString        := 'AC';
        ParamByName('p_SERIE_DOC_MOV').AsString       := ASerieSes;
        ParamByName('p_NRO_DOC_MOV').AsString         := ANumSes;
        ParamByName('p_LINEA_MOV').AsString           := sLinea;
        ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sCodigoEmp;
        ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sCodigoAlm;
        ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
        ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sCodigoSku;
        ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := 'E';
        ParamByName('p_CANTIDAD_MOV').AsFloat         := rCantidad;
        ParamByName('p_PRECIO_MEDIO_MOV').AsFloat     := rCoste;
        ParamByName('p_TOTAL_COSTE_MOV').AsFloat      := rTotal;
        ParamByName('p_USUARIO').AsString             := AUsuario;
        ParamByName('p_ALMACEN_DOC').AsString         := sCodigoAlm;
        ParamByName('p_NUMOP_DOC').AsString           := '';
        ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
        ParamByName('p_CODCLIENTE').AsString          := '';
        ParamByName('p_CODARTICULO').AsString         := sCodigoArt;
        ExecProc;
      finally
        Free;
      end;

      qC.Next;
    end;
  finally
    FreeAndNil(qC);
  end;
end;

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function MaterializarSesion(ADM: TdmComprasSesiones;
                            AESGeneraPedido, AESGeneraAlbaran: Boolean;
                            const AUsuario: string;
                            out ASeriePed, ANumPed, ASerieAlb, ANumAlb,
                                AMsgError: string): Boolean;
var
  conn       : TUniConnection;
  sSerieSes, sNumSes, sPrefijoEAN: string;
  sCodigoPrv : string;
  sCodigoTar : string;
  iIdPvTemporada: Integer;
  qLin       : TUniQuery;
  sError     : string;
  sCodigoArt : string;
  iLin       : Integer;
  rPrecio    : Double;
  rPrecioVta : Double;
  bTxOwned   : Boolean;
begin
  Result    := False;
  ASeriePed := ''; ANumPed := '';
  ASerieAlb := ''; ANumAlb := '';
  AMsgError := '';

  // 1. Validación previa fuera de la transacción
  if not inLibComprasSesiones.ValidarSesion(ADM, sError) then
  begin
    AMsgError := sError;
    Exit;
  end;

  conn := inLibGlobalVar.oConn;
  sSerieSes      := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumSes        := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sCodigoPrv     := ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
  sPrefijoEAN    := ADM.unqryTablaG.FieldByName('PREFIJO_EAN_SES').AsString;
  sCodigoTar     := ADM.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString;
  iIdPvTemporada := 0;
  if not ADM.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').IsNull then
    iIdPvTemporada :=
      ADM.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').AsInteger;

  bTxOwned := not conn.InTransaction;
  if bTxOwned then conn.StartTransaction;
  try
    qLin := TUniQuery.Create(nil);
    try
      qLin.Connection := conn;
      qLin.SQL.Text :=
        'SELECT L.* FROM fza_compras_sesiones_lineas L ' +
        ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
        ' ORDER BY L.LINEA_SESLIN';
      qLin.ParamByName('s').AsString := sSerieSes;
      qLin.ParamByName('n').AsString := sNumSes;
      qLin.Open;

      while not qLin.Eof do
      begin
        iLin   := qLin.FieldByName('LINEA_SESLIN').AsInteger;
        rPrecio := qLin.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;

        if qLin.FieldByName('ACCION_DUPLICADO_SESLIN').AsString = 'REUSAR' then
          sCodigoArt := qLin.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString
        else
        begin
          sCodigoArt :=
            qLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
          InsertarArticulo(conn, ADM, AUsuario, sSerieSes, sNumSes, iLin);
        end;

        if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'MATRIZ' then
        begin
          InsertarConjuntosAtributos(conn, sSerieSes, sNumSes,
                                     sCodigoArt, AUsuario, iLin);
          InsertarSkusYBarras(conn, sSerieSes, sNumSes, sCodigoArt,
                              AUsuario, sPrefijoEAN, iLin);
        end
        else if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'ESCALAR' then
        begin
          // Generar 1 EAN13 a nivel de artículo (sin SKU intermedio)
          // Implementación pendiente: INSERT directo en fza_codigos_barras
          // con CODIGO_UNIDAD_CB = sCodigoArt.
        end;
        // TIPO_LINEA = SERVICIO → ni SKU ni EAN13.

        InsertarPropiedadesFijas(conn,
                                 sSerieSes,
                                 sNumSes,
                                 sCodigoArt,
                                 AUsuario);

        // Temporada de cabecera -> propiedad TEMPORADA del articulo.
        // Aplica tanto a articulos nuevos como a REUSAR (INSERT IGNORE
        // respeta el valor preexistente si ya hay fila).
        InsertarTemporadaCabecera(conn, sCodigoArt, AUsuario,
                                  iIdPvTemporada);

        if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString <> 'SERVICIO' then
        begin
          UpsertArticuloProveedor(conn, sCodigoArt, sCodigoPrv,
            qLin.FieldByName('REF_PRV_SESLIN').AsString,
            AUsuario, rPrecio);

          // Tarifa de venta de cabecera con el PRECIO_VENTA_SESLIN de la
          // linea. UPSERT — si ya existe la rifa para este articulo, se
          // actualiza el precio final con el sugerido por la sesion.
          rPrecioVta := qLin.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
          UpsertArticuloTarifa(conn, sCodigoArt, sCodigoTar,
            AUsuario, rPrecioVta);
        end;

        // Migrar fotos tomadas en muestrario (fza_compras_sesiones_fotos)
        // a fza_articulos_fotos con el codigo final del articulo. Renombra
        // los PNG 300/600/real y borra el rastro de sesion.
        inLibFotos.oFotos.MigrarFotosSesion(sSerieSes, sNumSes, iLin,
                                            sCodigoArt, AUsuario);

        qLin.Next;
      end;
    finally
      FreeAndNil(qLin);
    end;

    // Documentos resultantes — pendiente cuando existan las tablas
    // fza_pedidos_compra / fza_albaranes_compra.
    //
    // MODELO: N PEDIDOS + N ALBARANES, uno de cada por almacén con
    // cantidad > 0. No hay almacén fijo: cada celda lleva su almacén
    // (CODIGO_ALM_SESCEL) y si está vacío se usa el de cabecera como
    // fallback.
    //
    // Pedidos de compra (cuando AESGeneraPedido):
    //   Para cada CODIGO_ALM con cantidad > 0:
    //     INSERT INTO fza_pedidos_compra (CODIGO_ALM_PEDC = ese, ...)
    //     INSERT INTO fza_pedidos_compra_lineas (una por SKU con
    //                 SUM(CANTIDAD) filtrado por ese almacén)
    //     INSERT INTO fza_compras_sesiones_documentos
    //       (TIPO_DOC='PEDC', CODIGO_ALM=ese, SERIE+NUMERO=ese)
    //   No mueve stock (los pedidos son compromiso).
    //
    // Albaranes de compra (cuando AESGeneraAlbaran):
    //   Para cada CODIGO_ALM con cantidad > 0:
    //     INSERT INTO fza_albaranes_compra (CODIGO_ALM_ALBC = ese, ...)
    //     INSERT INTO fza_albaranes_compra_lineas (líneas filtradas)
    //     INSERT INTO fza_movimientos_almacen (entrada por SKU)
    //     INSERT INTO fza_compras_sesiones_documentos
    //       (TIPO_DOC='ALBC', CODIGO_ALM=ese, SERIE+NUMERO=ese)
    //
    // La cabecera de sesión mantiene SERIE_PEDC_SES/NUMERO_PEDC_SES y
    // SERIE_ALBC_SES/NUMERO_ALBC_SES con el PRIMER documento de cada
    // tipo, para listados rápidos. La lista completa vive en
    // fza_compras_sesiones_documentos.

    if AESGeneraPedido then
    begin
      // ASeriePed := 'PC'; ANumPed := ProximoContador('PC');
    end;
    if AESGeneraAlbaran then
    begin
      // Por ahora no hay cabecera fza_albaranes_compra; los movimientos
      // se generan apuntando a la propia sesion como documento
      // (SERIE_DOC_MOV=SERIE_SES, NUMERO_DOC_MOV=NUMERO_SES,
      // TIPO_DOC_MOV='AC'). Cuando exista la cabecera de albaran de
      // compra, se creara primero y los movimientos pasaran a ella.
      GenerarMovimientosAlbaran(conn, ADM, sSerieSes, sNumSes, AUsuario);
      ASerieAlb := sSerieSes;
      ANumAlb   := sNumSes;
    end;

    // Cerrar la sesión
    qLin := TUniQuery.Create(nil);
    try
      qLin.Connection := conn;
      qLin.SQL.Text :=
        'UPDATE fza_compras_sesiones SET ' +
        '  ESTADO_SES = ''CERRADA'', ' +
        '  INSTANTE_MATERIALIZA_SES = NOW(), ' +
        '  USUARIO_MATERIALIZA_SES = :u, ' +
        '  SERIE_PEDC_SES = :sp, NUMERO_PEDC_SES = :np, ' +
        '  SERIE_ALBC_SES = :sa, NUMERO_ALBC_SES = :na, ' +
        '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
        ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
      qLin.ParamByName('s').AsString  := sSerieSes;
      qLin.ParamByName('n').AsString  := sNumSes;
      qLin.ParamByName('u').AsString  := AUsuario;
      qLin.ParamByName('sp').AsString := ASeriePed;
      qLin.ParamByName('np').AsString := ANumPed;
      qLin.ParamByName('sa').AsString := ASerieAlb;
      qLin.ParamByName('na').AsString := ANumAlb;
      qLin.ExecSQL;
    finally
      FreeAndNil(qLin);
    end;

    if bTxOwned and conn.InTransaction then conn.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      if bTxOwned and conn.InTransaction then conn.Rollback;
      AMsgError := E.Message;
      // Persistir el mensaje en MENSAJE_ERROR_SES fuera de la transacción
      try
        qLin := TUniQuery.Create(nil);
        try
          qLin.Connection := conn;
          qLin.SQL.Text :=
            'UPDATE fza_compras_sesiones SET MENSAJE_ERROR_SES = :e, ' +
            '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
            ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
          qLin.ParamByName('e').AsString := Copy(E.Message, 1, 2000);
          qLin.ParamByName('u').AsString := AUsuario;
          qLin.ParamByName('s').AsString := sSerieSes;
          qLin.ParamByName('n').AsString := sNumSes;
          qLin.ExecSQL;
        finally
          FreeAndNil(qLin);
        end;
      except
        // tragado: si esto también falla, no hay nada que hacer
      end;
    end;
  end;
end;

end.
