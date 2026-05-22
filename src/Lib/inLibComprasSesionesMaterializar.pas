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

// Materializa la sesion. ASerieDocAlb / ASerieDocPed permiten elegir la
// serie del documento generado (movimientos / pedido pendiente); si
// llegan vacios se usa SERIE_SES como fallback. ANumPed/ASerieAlb/etc.
// devuelven los identificadores de los docs creados.
function MaterializarSesion(ADM: TdmComprasSesiones;
                            AESGeneraPedido, AESGeneraAlbaran: Boolean;
                            const AUsuario: string;
                            const ASerieDocAlb, ASerieDocPed: string;
                            out ASeriePed, ANumPed, ASerieAlb, ANumAlb,
                                AMsgError: string): Boolean;

// Revierte la materializacion: borra los movimientos de almacen que la
// sesion genero (TIPO_DOC_MOV='AC' apuntando a SERIE_SES/NUMERO_SES) y
// las filas de fza_articulos_pdte_recibir asociadas, y devuelve la
// cabecera a ESTADO_SES='BORRADOR'. Los articulos, SKUs y codigos de
// barras se conservan: re-materializar es idempotente porque los
// INSERTs auxiliares usan INSERT IGNORE / DUPLICATE KEY y la generacion
// de EAN13 ahora se salta si el SKU ya tiene uno.
// Devuelve True si todo OK, False si error (AMsgError lleva el detalle).
function RevertirMaterializacion(ADM: TdmComprasSesiones;
                                  const AUsuario: string;
                                  out AMsgError: string): Boolean;

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
  // Default '21' = GS1 in-store / uso interno (no se compra). NUNCA
  // usar '84x' aqui: son prefijos GS1 oficiales (Grecia y demas
  // empresas titulares) y emitirlos sin licencia es una infraccion.
  // Si la empresa tiene su propio prefijo GS1, ponerlo en
  // PREFIJO_EAN_SES de la cabecera de la sesion.
  if sPref = '' then sPref := '21';
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

// Devuelve el ID_AV asociado al color de la linea. Prioridad:
//   1. fza_atributos_valores via CODIGO_ATB_COLOR_SESLIN (la paleta basica).
//   2. fza_atributos_valores con AV = COLOR_TEXTO_SESLIN exacto.
//   3. Si no existe, crea un fza_atributos_valores nuevo (ID_VA_AV='CO').
// Devuelve 0 si no hay informacion de color en la linea.
function ResolverIdAvColorLinea(AConn: TUniConnection;
                                 const AColorTexto, ACodigoAtbColor,
                                       AUsuario: string;
                                 out AValor: string): Integer;
var
  q : TUniQuery;
  s : string;
begin
  Result := 0;
  AValor := '';
  if (Trim(AColorTexto) = '') and (Trim(ACodigoAtbColor) = '') then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;

    // 1. CODIGO_ATB → ID_ATB → ID_AV
    if Trim(ACodigoAtbColor) <> '' then
    begin
      q.SQL.Text :=
        'SELECT AV.ID_AV, AV.AV ' +
        '  FROM fza_atributos_valores AV ' +
        '  JOIN fza_atributos_basicos ATB ON ATB.ID_ATB = AV.ID_ATB_AV ' +
        ' WHERE AV.ID_VA_AV = ''CO'' ' +
        '   AND ATB.CODIGO_ATB = :cod ' +
        ' ORDER BY AV.ID_AV LIMIT 1';
      q.ParamByName('cod').AsString := ACodigoAtbColor;
      q.Open;
      if not q.IsEmpty then
      begin
        Result := q.FieldByName('ID_AV').AsInteger;
        AValor := q.FieldByName('AV').AsString;
        Exit;
      end;
      q.Close;
    end;

    // 2. Texto exacto
    if Trim(AColorTexto) <> '' then
    begin
      s := Trim(AColorTexto);
      q.SQL.Text :=
        'SELECT ID_AV, AV FROM fza_atributos_valores ' +
        ' WHERE ID_VA_AV = ''CO'' AND AV = :v LIMIT 1';
      q.ParamByName('v').AsString := s;
      q.Open;
      if not q.IsEmpty then
      begin
        Result := q.FieldByName('ID_AV').AsInteger;
        AValor := q.FieldByName('AV').AsString;
        Exit;
      end;
      q.Close;
    end;

    // 3. Crear un fza_atributos_valores nuevo. Usamos el CODIGO_ATB
    //    como valor (consistente con la paleta basica) si lo hay; si no,
    //    el texto libre tal cual.
    if Trim(ACodigoAtbColor) <> '' then s := ACodigoAtbColor
    else                                   s := Trim(AColorTexto);
    q.SQL.Text :=
      'INSERT INTO fza_atributos_valores ' +
      '  (ID_VA_AV, AV, ID_ATB_AV, ESACTIVO_AV, ORDEN_AV, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (''CO'', :v, ' +
      '        (SELECT ID_ATB FROM fza_atributos_basicos ' +
      '          WHERE CODIGO_ATB = :cod AND ID_VA_ATB = ''CO'' LIMIT 1), ' +
      '        ''S'', 0, NOW(), :u, NOW(), :u)';
    q.ParamByName('v').AsString   := s;
    q.ParamByName('cod').AsString := ACodigoAtbColor;
    q.ParamByName('u').AsString   := AUsuario;
    q.ExecSQL;

    q.SQL.Text :=
      'SELECT ID_AV FROM fza_atributos_valores ' +
      ' WHERE ID_VA_AV = ''CO'' AND AV = :v ORDER BY ID_AV DESC LIMIT 1';
    q.ParamByName('v').AsString := s;
    q.Open;
    if not q.IsEmpty then
    begin
      Result := q.FieldByName('ID_AV').AsInteger;
      AValor := s;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure InsertarSkusYBarras(AConn: TUniConnection;
                              const ASerieSes, ANumSes, ACodigoArt,
                                    AUsuario, APrefijoEAN: string;
                              ALinea: Integer);
var
  qC, qIns, qBar, qLin: TUniQuery;
  sCodigoSKU : string;
  sEAN13     : string;
  sValPivot, sValFila: string;
  iAvPivot, iAvFila: Integer;
  sColorTexto, sCodigoAtbColor, sValColor: string;
  iAvColor: Integer;
begin
  qC   := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  qBar := TUniQuery.Create(nil);
  qLin := TUniQuery.Create(nil);
  try
    qC.Connection   := AConn;
    qIns.Connection := AConn;
    qBar.Connection := AConn;
    qLin.Connection := AConn;

    // Cargar color denormalizado de la linea (COLOR_TEXTO_SESLIN /
    // CODIGO_ATB_COLOR_SESLIN). El grid de la sesion no usa la tabla
    // fza_compras_sesiones_lineas_filas_atr para el color: lo guarda
    // plano en la linea. Si no hay color, iAvColor queda en 0 y los
    // SKUs salen sin color (escenario sin matriz color).
    qLin.SQL.Text :=
      'SELECT COLOR_TEXTO_SESLIN, CODIGO_ATB_COLOR_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s ' +
      '   AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN = :l';
    qLin.ParamByName('s').AsString  := ASerieSes;
    qLin.ParamByName('n').AsString  := ANumSes;
    qLin.ParamByName('l').AsInteger := ALinea;
    qLin.Open;
    sColorTexto     := '';
    sCodigoAtbColor := '';
    if not qLin.IsEmpty then
    begin
      sColorTexto     := qLin.FieldByName('COLOR_TEXTO_SESLIN').AsString;
      sCodigoAtbColor := qLin.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
    end;
    qLin.Close;
    iAvColor := ResolverIdAvColorLinea(AConn, sColorTexto, sCodigoAtbColor,
                                        AUsuario, sValColor);

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

      // Fallback al color denormalizado de la linea cuando no hay
      // fila formal en _filas_atr (caso del grid plano de muestrarios).
      if (iAvFila = 0) and (iAvColor > 0) then
      begin
        iAvFila  := iAvColor;
        sValFila := sValColor;
      end;

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

      // EAN13 — solo si el SKU no tiene ya un codigo de barras EAN13
      // (idempotencia entre materializaciones tras un Revertir).
      qBar.SQL.Text :=
        'SELECT COUNT(*) AS N FROM fza_codigos_barras ' +
        ' WHERE CODIGO_UNIDAD_CB = :sku AND TIPO_CODIGO_CB = ''EAN13''';
      qBar.ParamByName('sku').AsString := sCodigoSKU;
      qBar.Open;
      if qBar.FieldByName('N').AsInteger = 0 then
      begin
        qBar.Close;
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
      end
      else
        qBar.Close;

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
  bHayPrincipal: Boolean;
  sEsPrincipal: string;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // 1. Si el articulo ya tiene OTRO proveedor marcado como principal,
    //    el nuevo no se lo roba: se inserta con ESPRINCIPAL='N'. Si la
    //    fila ya existe (mismo prv+art) el flag no se toca en el UPDATE.
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_articulos_proveedores ' +
      ' WHERE CODIGO_ART_AP = :art ' +
      '   AND CODIGO_PRV_AP <> :prv ' +
      '   AND ESPROVEEDORPRINCIPAL_AP = ''S''';
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('prv').AsString := ACodigoPrv;
    q.Open;
    bHayPrincipal := q.FieldByName('N').AsInteger > 0;
    q.Close;
    if bHayPrincipal then sEsPrincipal := 'N' else sEsPrincipal := 'S';

    q.SQL.Text :=
      'INSERT INTO fza_articulos_proveedores ' +
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
  iCodigoUnico: Integer;
begin
  if (Trim(ACodigoTar) = '') or (APrecioVenta <= 0) then Exit;
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
    q.SQL.Text :=
      'SELECT CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas ' +
      ' WHERE CODIGO_ART_ARTTAR    = :art ' +
      '   AND CODIGO_UNIDAD_ARTTAR = '''' ' +
      '   AND CODIGO_TAR_ARTTAR    = :tar ' +
      ' LIMIT 1';
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('tar').AsString := ACodigoTar;
    q.Open;
    iCodigoUnico := 0;
    if not q.IsEmpty then
      iCodigoUnico := q.FieldByName('CODIGO_UNICO_ARTTAR').AsInteger;
    q.Close;

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
        'INSERT INTO fza_articulos_tarifas ' +
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

// Crea la cabecera del albaran de compra en fza_albaranes_compra y sus
// lineas (una por SKU + almacen con cantidad > 0). Devuelve el
// NUMERO_ALBC generado. Denormaliza datos de empresa y proveedor desde
// fza_empresas y fza_proveedores (mismo patron que albaranes de venta).
// La cabecera CODIGO_ALM_ALBC arranca con el almacen de la sesion;
// cada linea lleva su propio CODIGO_ALMACEN_ALBCLIN (puede diferir si
// la celda venia con almacen explicito).
procedure InsertarAlbaranCompraCabecera(AConn: TUniConnection;
                                         ADM: TdmComprasSesiones;
                                         const ASerieAlbc, ANumAlbc,
                                               AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_albaranes_compra ' +
      '  (NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC, ' +
      '   CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC, ' +
      '   MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, ' +
      '   DIRECCION1_EMPRESA_ALBC, DIRECCION2_EMPRESA_ALBC, ' +
      '   POBLACION_EMPRESA_ALBC, PROVINCIA_EMPRESA_ALBC, ' +
      '   CODIGO_PAI_EMPRESA_ALBC, NOMBRE_PAI_EMPRESA_ALBC, ' +
      '   CODIGO_POSTAL_EMPRESA_ALBC, ' +
      '   CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC, ' +
      '   MOVIL_PRV_ALBC, EMAIL_PRV_ALBC, ' +
      '   DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, ' +
      '   POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC, ' +
      '   CODIGO_POSTAL_PRV_ALBC, ' +
      '   REF_PROVEEDOR_ALBC, CODIGO_ALM_ALBC, ' +
      '   TOTAL_BASES_ALBC, TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC, ' +
      '   CONTADOR_LINEAS_ALBC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :nalbc, :salbc, S.FECHA_SES, ''ABIERTO'', ' +
      '       E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
      '       E.MOVIL_EMP, E.EMAIL_EMP, ' +
      '       E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
      '       E.POBLACION_EMP, E.PROVINCIA_EMP, ' +
      '       E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, ' +
      '       E.CODIGO_POSTAL_EMP, ' +
      '       P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, P.NIF_PRV, ' +
      '       P.MOVIL_PRV, P.EMAIL_PRV, ' +
      '       P.DIRECCION1_PRV, P.DIRECCION2_PRV, ' +
      '       P.POBLACION_PRV, P.PROVINCIA_PRV, ' +
      '       P.CODIGO_POSTAL_PRV, ' +
      '       S.REF_PRV_SES, S.CODIGO_ALM_SES, ' +
      '       0, 0, 0, ''0'', ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones S ' +
      '  LEFT JOIN fza_empresas E    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = S.CODIGO_PRV_SES ' +
      ' WHERE S.SERIE_SES = :s AND S.NUMERO_SES = :n';
    q.ParamByName('nalbc').AsString := ANumAlbc;
    q.ParamByName('salbc').AsString := ASerieAlbc;
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Inserta una linea en fza_albaranes_compra_lineas con SUM(CANTIDAD) por
// (SKU, almacen) agregando todas las celdas que aportan a esa combinacion
// dentro de la linea actual de la sesion. Devuelve la LINEA_ALBCLIN
// asignada (PK secundaria, 4 digitos LPAD).
procedure InsertarLineaAlbaranCompra(AConn: TUniConnection;
                                      const ASerieAlbc, ANumAlbc,
                                            ALineaAlbc, ACodigoArt,
                                            ACodigoSku, ACodigoFam,
                                            ANombreFam, ADescripcion,
                                            ACodigoAlm, ATipoIva,
                                            AUsuario: string;
                                      ACantidad, APrecio,
                                      APorcIva: Double);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_albaranes_compra_lineas ' +
      '  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
      '   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, ' +
      '   CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
      '   DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN, ' +
      '   CANTIDAD_ALBCLIN, TIPO_IVA_ARTICULO_ALBCLIN, ' +
      '   PORCENTAJE_IVA_ALBCLIN, ' +
      '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
      '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
      '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
      '   ESFACTURADA_ALBCLIN, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:n, :s, :l, :art, :sku, :fam, :nomfam, :desc, ''Uds'', ' +
      '        :cant, :tiva, :piva, :pre, :preciva, :tot, :alm, ''N'', ' +
      '        NOW(), :u, NOW(), :u)';
    q.ParamByName('n').AsString    := ANumAlbc;
    q.ParamByName('s').AsString    := ASerieAlbc;
    q.ParamByName('l').AsString    := ALineaAlbc;
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('sku').AsString  := ACodigoSku;
    q.ParamByName('fam').AsString  := ACodigoFam;
    q.ParamByName('nomfam').AsString := ANombreFam;
    q.ParamByName('desc').AsString := ADescripcion;
    q.ParamByName('cant').AsFloat  := ACantidad;
    q.ParamByName('tiva').AsString := ATipoIva;
    q.ParamByName('piva').AsFloat  := APorcIva;
    q.ParamByName('pre').AsFloat   := APrecio;
    q.ParamByName('preciva').AsFloat := APrecio * (1 + APorcIva / 100);
    q.ParamByName('tot').AsFloat   := ACantidad * APrecio;
    q.ParamByName('alm').AsString  := ACodigoAlm;
    q.ParamByName('u').AsString    := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Recalcula los totales de la cabecera del albaran a partir de sus
// lineas. Lo llamamos justo despues de insertar todas las lineas para
// no tener que mantener acumuladores en codigo cliente.
procedure RecalcularTotalesAlbaranCompra(AConn: TUniConnection;
                                          const ASerieAlbc, ANumAlbc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra C ' +
      '  JOIN ( ' +
      '       SELECT NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, ' +
      '              IFNULL(SUM(TOTAL_ALBCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(TOTAL_ALBCLIN * PORCENTAJE_IVA_ALBCLIN / 100), 0) AS IVA, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_albaranes_compra_lineas ' +
      '        WHERE NUMERO_ALBC_ALBCLIN = :n ' +
      '          AND SERIE_ALBC_ALBCLIN  = :s ' +
      '        GROUP BY NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN) AS T ' +
      '    ON T.NUMERO_ALBC_ALBCLIN = C.NUMERO_ALBC ' +
      '   AND T.SERIE_ALBC_ALBCLIN  = C.SERIE_ALBC ' +
      '   SET C.TOTAL_BASES_ALBC     = T.BASE, ' +
      '       C.TOTAL_IMPUESTOS_ALBC = T.IVA, ' +
      '       C.TOTAL_LIQUIDO_ALBC   = T.BASE + T.IVA, ' +
      '       C.CONTADOR_LINEAS_ALBC = LPAD(T.NLIN * 10, 8, ''0'') ' +
      ' WHERE C.NUMERO_ALBC = :n AND C.SERIE_ALBC = :s';
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Itera celdas de la sesion agrupadas por (SKU, almacen) y crea una
// linea en fza_albaranes_compra_lineas por cada combinacion con
// cantidad > 0. LINEA_ALBCLIN se asigna secuencial (010, 020, 030...).
procedure InsertarLineasAlbaranCompra(AConn: TUniConnection;
                                       ADM: TdmComprasSesiones;
                                       const ASerieSes, ANumSes,
                                             ASerieAlbc, ANumAlbc,
                                             AUsuario: string);
var
  qC : TUniQuery;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sDescripcion, sCodigoFam, sNombreFam, sTipoIva,
  sLineaAlbc: string;
  iIdAvPivot, iIdAvFila, iLineaSeq: Integer;
  rCantidad, rCoste, rPorIva: Double;
begin
  sCodigoAlmCab := ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  if sCodigoAlmCab = '' then
    raise Exception.Create('Falta CODIGO_ALM_SES en la cabecera de la sesion ' +
                           'para generar el albaran de compra.');

  iLineaSeq := 0;
  qC := TUniQuery.Create(nil);
  try
    qC.Connection := AConn;
    // Agrupamos por (sku-resolvable inputs, almacen). El SKU real se
    // resuelve por linea con ResolverCodigoSku, asi que aqui agrupamos
    // por los componentes (articulo, pivot, fila) + almacen y luego
    // pedimos el SKU una vez por grupo.
    qC.SQL.Text :=
      'SELECT  ' +
      '    CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
      '         THEN L.CODIGO_ART_REUSAR_SESLIN ' +
      '         ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
      '    C.ID_AV_PIVOT_SESCEL, ' +
      '    CAST(IFNULL(L.ID_VA_FILA_SESLIN, ''0'') AS UNSIGNED) AS AV_FILA, ' +
      '    IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), :alm_cab) AS ALM_EFE, ' +
      '    SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
      '    L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '    L.CODIGO_FAM_SESLIN, ' +
      '    IFNULL(L.TIPO_IVA_SESLIN, ''N'') AS TIPO_IVA, ' +
      '    L.TIPO_LINEA_SESLIN ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL  = :s ' +
      '   AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.CANTIDAD_SESCEL   > 0 ' +
      '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
      ' GROUP BY CODIGO_ART, C.ID_AV_PIVOT_SESCEL, AV_FILA, ALM_EFE, ' +
      '          L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '          L.CODIGO_FAM_SESLIN, TIPO_IVA, L.TIPO_LINEA_SESLIN ' +
      ' ORDER BY CODIGO_ART, AV_FILA, C.ID_AV_PIVOT_SESCEL, ALM_EFE';
    qC.ParamByName('alm_cab').AsString := sCodigoAlmCab;
    qC.ParamByName('s').AsString := ASerieSes;
    qC.ParamByName('n').AsString := ANumSes;
    qC.Open;

    while not qC.Eof do
    begin
      sCodigoArt := qC.FieldByName('CODIGO_ART').AsString;
      iIdAvPivot := qC.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
      iIdAvFila  := qC.FieldByName('AV_FILA').AsInteger;
      sCodigoAlm := qC.FieldByName('ALM_EFE').AsString;
      rCantidad  := qC.FieldByName('CANTIDAD_TOTAL').AsFloat;
      rCoste     := qC.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
      sDescripcion := qC.FieldByName('DESCRIPCION_SESLIN').AsString;
      sCodigoFam := qC.FieldByName('CODIGO_FAM_SESLIN').AsString;
      sTipoIva   := qC.FieldByName('TIPO_IVA').AsString;
      rPorIva    := 0;  // se podra cruzar con fza_ivas en hito posterior

      sCodigoSku := ResolverCodigoSku(AConn, sCodigoArt, iIdAvPivot, iIdAvFila);
      if sCodigoSku = '' then
      begin
        qC.Next;
        Continue;
      end;

      // El NOMBRE_FAM lo dejamos vacio aqui — se puede rellenar despues
      // con un JOIN si hace falta para reports. Lineas se numeran de 10
      // en 10 para permitir intercalado posterior si fuera necesario.
      sNombreFam := '';
      iLineaSeq := iLineaSeq + 1;
      sLineaAlbc := Format('%.4d', [iLineaSeq * 10]);

      InsertarLineaAlbaranCompra(AConn,
        ASerieAlbc, ANumAlbc, sLineaAlbc,
        sCodigoArt, sCodigoSku, sCodigoFam, sNombreFam, sDescripcion,
        sCodigoAlm, sTipoIva, AUsuario,
        rCantidad, rCoste, rPorIva);

      qC.Next;
    end;
  finally
    FreeAndNil(qC);
  end;
end;

// Genera movimientos de entrada en almacen (TIPO_DOC_MOV='AC',
// TIPO_MOV='E') por cada (linea, fila, pivot) con cantidad > 0 de la
// sesion. Una sola pasada SQL que itera celdas y resuelve SKU/articulo
// linea a linea. La cabecera de cada movimiento apunta al albaran de
// compra recien creado (SERIE_ALBC/NUMERO_ALBC).
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
// Pendiente de recibir (pedido de compra, no toca movimientos)
// ---------------------------------------------------------------------------
// Itera fza_compras_sesiones_celdas con cantidad > 0 y crea una fila por
// (SKU, almacen, doc) en fza_articulos_pdte_recibir. NO genera
// movimientos en fza_movimientos_almacen: el stock fisico no cambia,
// solo se acumula compromiso futuro. Cuando el pedido se reciba (futuro
// flujo de albaran), tocara borrar la fila correspondiente y entonces
// si crear el movimiento de entrada.
//
// ASerieSes/ANumSes son los de la sesion (para resolver lineas y celdas).
// ASerieDoc/ANumDoc son los del pedido generado (van como SERIE_DOC_PDR /
// NUMERO_DOC_PDR de la tabla).
procedure GenerarPedidoPdteRecibir(AConn: TUniConnection;
                                    ADM: TdmComprasSesiones;
                                    const ASerieSes, ANumSes,
                                          ASerieDoc, ANumDoc,
                                          AUsuario: string);
var
  qC, qIns: TUniQuery;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sCodigoEmp: string;
  iIdAvPivot, iIdAvFila, iLinea: Integer;
  rCantidad, rCoste: Double;
  dFechaPedido: TDateTime;
begin
  sCodigoAlmCab := ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  sCodigoEmp    := ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  dFechaPedido  := Date;
  if not ADM.unqryTablaG.FieldByName('FECHA_SES').IsNull then
    dFechaPedido := ADM.unqryTablaG.FieldByName('FECHA_SES').AsDateTime;
  if sCodigoAlmCab = '' then
    raise Exception.Create('Falta CODIGO_ALM_SES en la cabecera de la sesion ' +
                           'para generar el pedido pendiente de recibir.');

  qC   := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qC.Connection   := AConn;
    qIns.Connection := AConn;

    qC.SQL.Text :=
      'SELECT C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
      '       C.CANTIDAD_SESCEL, ' +
      '       IFNULL(NULLIF(C.CODIGO_ALM_SESCEL,''''), :alm_cab) AS ALM_EFE, ' +
      '       L.CODIGO_ART_TENTATIVO_SESLIN, L.CODIGO_ART_REUSAR_SESLIN, ' +
      '       L.ACCION_DUPLICADO_SESLIN, ' +
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
      rCoste     := qC.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;

      if qC.FieldByName('ACCION_DUPLICADO_SESLIN').AsString = 'REUSAR' then
        sCodigoArt := qC.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString
      else
        sCodigoArt := qC.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;

      // Lineas SERVICIO no tienen SKU ni stock pendiente.
      if qC.FieldByName('TIPO_LINEA_SESLIN').AsString = 'SERVICIO' then
      begin
        qC.Next;
        Continue;
      end;

      iIdAvFila := 0;
      if not qC.FieldByName('ID_VA_FILA_SESLIN').IsNull then
        iIdAvFila :=
                StrToIntDef(qC.FieldByName('ID_VA_FILA_SESLIN').AsString, 0);

      sCodigoSku := ResolverCodigoSku(AConn, sCodigoArt,
                                       iIdAvPivot, iIdAvFila);
      if sCodigoSku = '' then
      begin
        qC.Next;
        Continue;
      end;

      // UPSERT por PK (SKU, ALM, SERIE_DOC, NUMERO_DOC, LINEA): si por
      // alguna razon se materializa dos veces, suma cantidad y mantiene
      // ultimo precio / fechas.
      qIns.SQL.Text :=
        'INSERT INTO fza_articulos_pdte_recibir ' +
        '  (CODIGO_UNIDAD_PDR, CODIGO_ALM_PDR, SERIE_DOC_PDR, NUMERO_DOC_PDR, ' +
        '   LINEA_PDR, CODIGO_ART_PDR, CODIGO_PRV_PDR, CODIGO_EMP_PDR, ' +
        '   CANTIDAD_PDR, PRECIO_COMPRA_PDR, FECHA_PEDIDO_PDR, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :alm, :s, :n, :l, :art, :prv, :emp, ' +
        '        :qty, :pre, :fped, NOW(), :u, NOW(), :u) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  CANTIDAD_PDR      = :qty, ' +
        '  PRECIO_COMPRA_PDR = :pre, ' +
        '  FECHA_PEDIDO_PDR  = :fped, ' +
        '  INSTANTE_MODIF    = NOW(), ' +
        '  USUARIO_MODIF     = :u';
      qIns.ParamByName('sku').AsString  := sCodigoSku;
      qIns.ParamByName('alm').AsString  := sCodigoAlm;
      qIns.ParamByName('s').AsString    := ASerieDoc;
      qIns.ParamByName('n').AsString    := ANumDoc;
      qIns.ParamByName('l').AsInteger   := iLinea;
      qIns.ParamByName('art').AsString  := sCodigoArt;
      qIns.ParamByName('prv').AsString  :=
                          ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
      qIns.ParamByName('emp').AsString  := sCodigoEmp;
      qIns.ParamByName('qty').AsFloat   := rCantidad;
      qIns.ParamByName('pre').AsFloat   := rCoste;
      qIns.ParamByName('fped').AsDateTime := dFechaPedido;
      qIns.ParamByName('u').AsString    := AUsuario;
      qIns.ExecSQL;

      qC.Next;
    end;
  finally
    FreeAndNil(qC);
    FreeAndNil(qIns);
  end;
end;

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function MaterializarSesion(ADM: TdmComprasSesiones;
                            AESGeneraPedido, AESGeneraAlbaran: Boolean;
                            const AUsuario: string;
                            const ASerieDocAlb, ASerieDocPed: string;
                            out ASeriePed, ANumPed, ASerieAlb, ANumAlb,
                                AMsgError: string): Boolean;
var
  conn       : TUniConnection;
  sSerieSes, sNumSes, sPrefijoEAN: string;
  sCodigoPrv : string;
  sCodigoTar : string;
  sSerieAlbReal, sSeriePedReal: string;
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

  // Si el llamante no fija serie, usamos la propia de la sesion como
  // fallback (preserva el comportamiento anterior cuando todavia no
  // existian las series independientes de albaran / pedido).
  sSerieAlbReal := Trim(ASerieDocAlb);
  if sSerieAlbReal = '' then sSerieAlbReal := sSerieSes;
  sSeriePedReal := Trim(ASerieDocPed);
  if sSeriePedReal = '' then sSeriePedReal := sSerieSes;

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
      // Pedido de compra: no toca fza_movimientos_almacen. Las
      // cantidades pendientes de recibir se acumulan en
      // fza_articulos_pdte_recibir para que el modulo de stock las
      // pueda consultar via vi_articulos_pdte_recibir sin contaminar
      // el stock fisico.
      GenerarPedidoPdteRecibir(conn, ADM, sSerieSes, sNumSes,
                                sSeriePedReal, sNumSes, AUsuario);
      ASeriePed := sSeriePedReal;
      ANumPed   := sNumSes;
    end;
    if AESGeneraAlbaran then
    begin
      // 1. Obtener NUMERO_ALBC del contador global (tipo 'AB').
      ANumAlb   := inLibtb.ObtenerSiguienteContador('AB');
      ASerieAlb := sSerieAlbReal;

      // 2. Crear cabecera en fza_albaranes_compra denormalizando
      //    empresa + proveedor desde la sesion.
      InsertarAlbaranCompraCabecera(conn, ADM, ASerieAlb, ANumAlb, AUsuario);

      // 3. Crear lineas: una por (SKU, almacen) con SUM(CANTIDAD).
      InsertarLineasAlbaranCompra(conn, ADM, sSerieSes, sNumSes,
                                  ASerieAlb, ANumAlb, AUsuario);

      // 4. Recalcular totales de la cabecera a partir de las lineas.
      RecalcularTotalesAlbaranCompra(conn, ASerieAlb, ANumAlb);

      // 5. Movimientos de entrada apuntando al albaran recien creado.
      GenerarMovimientosAlbaran(conn, ADM, ASerieAlb, ANumAlb, AUsuario);
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

// ---------------------------------------------------------------------------
// Revertir la materializacion
// ---------------------------------------------------------------------------

function RevertirMaterializacion(ADM: TdmComprasSesiones;
                                  const AUsuario: string;
                                  out AMsgError: string): Boolean;
var
  conn      : TUniConnection;
  sSerieSes, sNumSes: string;
  q         : TUniQuery;
  bTxOwned  : Boolean;
begin
  Result    := False;
  AMsgError := '';

  if ADM = nil then
  begin
    AMsgError := 'DataModule no inicializado.';
    Exit;
  end;
  if ADM.unqryTablaG.IsEmpty then
  begin
    AMsgError := 'No hay sesion activa.';
    Exit;
  end;
  if ADM.unqryTablaG.FieldByName('ESTADO_SES').AsString <> 'CERRADA' then
  begin
    AMsgError := 'La sesion no esta CERRADA, no hay nada que revertir.';
    Exit;
  end;

  conn      := inLibGlobalVar.oConn;
  sSerieSes := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumSes   := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;

  bTxOwned := not conn.InTransaction;
  if bTxOwned then conn.StartTransaction;
  try
    q := TUniQuery.Create(nil);
    try
      q.Connection := conn;

      // 0. Articulos creados por esta sesion (lineas no REUSAR) + todos
      //    sus dependientes. Sin esto, al re-materializar una sesion
      //    revertida choca contra la PK CODIGO_ART_ART en fza_articulos.
      //    Lineas con ACCION_DUPLICADO=REUSAR no entran aqui porque
      //    apuntan a articulos preexistentes que no debemos borrar.
      //
      //    Orden de borrado (no hay FK cascade): hijos del SKU primero,
      //    luego SKU, despues conjuntos/tarifas/proveedores/propiedades/
      //    fotos, finalmente la cabecera del articulo.

      // 0a. codigos_barras (EAN13 por SKU)
      q.SQL.Text :=
        'DELETE CB FROM fza_codigos_barras CB ' +
        '  JOIN fza_articulos_skus SK ON SK.CODIGO_UNIDAD_SKU = CB.CODIGO_UNIDAD_CB ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = SK.CODIGO_ART_SKU ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0b. atributos_sku
      q.SQL.Text :=
        'DELETE AS_X FROM fza_atributos_sku AS_X ' +
        '  JOIN fza_articulos_skus SK ' +
        '    ON SK.CODIGO_UNIDAD_SKU = AS_X.CODIGO_UNIDAD_SKU_SA ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = SK.CODIGO_ART_SKU ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0c. SKUs
      q.SQL.Text :=
        'DELETE SK FROM fza_articulos_skus SK ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = SK.CODIGO_ART_SKU ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0d. conjuntos asignados (CODIGO_ART_ACA)
      q.SQL.Text :=
        'DELETE ACA FROM fza_articulos_conjuntos_asign ACA ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = ACA.CODIGO_ART_ACA ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0e. tarifas (CODIGO_ART_ARTTAR)
      q.SQL.Text :=
        'DELETE T FROM fza_articulos_tarifas T ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = T.CODIGO_ART_ARTTAR ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0f. proveedores (CODIGO_ART_AP)
      q.SQL.Text :=
        'DELETE AP FROM fza_articulos_proveedores AP ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = AP.CODIGO_ART_AP ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0g. propiedades (CODIGO_ART_PRO)
      q.SQL.Text :=
        'DELETE P FROM fza_articulos_propiedades P ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = P.CODIGO_ART_PRO ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0h. fotos (CODIGO_ART_AFO). Si la tabla no existe en esta BBDD
      //     o no hubo fotos, no es critico — try/except con log.
      try
        q.SQL.Text :=
          'DELETE AFO FROM fza_articulos_fotos AFO ' +
          '  JOIN fza_compras_sesiones_lineas L ' +
          '    ON L.CODIGO_ART_TENTATIVO_SESLIN = AFO.CODIGO_ART_AFO ' +
          ' WHERE L.SERIE_SES_SESLIN  = :s ' +
          '   AND L.NUMERO_SES_SESLIN = :n ' +
          '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
          '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
        q.ParamByName('s').AsString := sSerieSes;
        q.ParamByName('n').AsString := sNumSes;
        q.ExecSQL;
      except
        // tragado: cleanup de fotos es best-effort
      end;

      // 0i. cabecera del articulo
      q.SQL.Text :=
        'DELETE A FROM fza_articulos A ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = A.CODIGO_ART_ART ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0j. Albaranes de compra creados por esta sesion + sus lineas.
      //     Identificados por SERIE_ALBC_SES/NUMERO_ALBC_SES en la
      //     cabecera de la sesion (apuntan al albaran creado).
      if ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString <> '' then
      begin
        try
          // Lineas primero (PK incluye albaran)
          q.SQL.Text :=
            'DELETE FROM fza_albaranes_compra_lineas ' +
            ' WHERE NUMERO_ALBC_ALBCLIN = :nalb ' +
            '   AND SERIE_ALBC_ALBCLIN  = :salb';
          q.ParamByName('nalb').AsString :=
                ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString;
          q.ParamByName('salb').AsString :=
                ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString;
          q.ExecSQL;
          // Cabecera
          q.SQL.Text :=
            'DELETE FROM fza_albaranes_compra ' +
            ' WHERE NUMERO_ALBC = :nalb AND SERIE_ALBC = :salb';
          q.ParamByName('nalb').AsString :=
                ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString;
          q.ParamByName('salb').AsString :=
                ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString;
          q.ExecSQL;
        except
          // tabla puede no existir en BBDD legacy — best effort
        end;
      end;

      // 1. Borrar los movimientos de almacen que esta sesion creo. Solo
      //    los TIPO_DOC_MOV='AC' cuyo NUMERO_DOC coincide con el de la
      //    sesion: los demas movimientos del articulo (anteriores o de
      //    otras sesiones) se preservan. Si la sesion uso serie de
      //    albaran distinta a la propia, tambien la borramos.
      q.SQL.Text :=
        'DELETE FROM fza_movimientos_almacen ' +
        ' WHERE TIPO_DOC_MOV   = ''AC'' ' +
        '   AND NUMERO_DOC_MOV = :n ' +
        '   AND (SERIE_DOC_MOV = :ses ' +
        '        OR (:salb <> '''' AND SERIE_DOC_MOV = :salb))';
      q.ParamByName('n').AsString    := sNumSes;
      q.ParamByName('ses').AsString  := sSerieSes;
      q.ParamByName('salb').AsString :=
                          ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString;
      q.ExecSQL;

      // 1b. Borrar las filas de pendiente de recibir generadas por
      //     esta sesion (si genero pedido). Mismo criterio: NUMERO_DOC
      //     coincide y SERIE_DOC es la de la sesion o la del pedido.
      //     try/except porque hay BBDD que aun no tienen la tabla creada
      //     (migracion pendiente en DESARROLLOS EN CURSO/) y no debe
      //     bloquear la reversion del resto.
      try
        q.SQL.Text :=
          'DELETE FROM fza_articulos_pdte_recibir ' +
          ' WHERE NUMERO_DOC_PDR = :n ' +
          '   AND (SERIE_DOC_PDR = :ses ' +
          '        OR (:sped <> '''' AND SERIE_DOC_PDR = :sped))';
        q.ParamByName('n').AsString    := sNumSes;
        q.ParamByName('ses').AsString  := sSerieSes;
        q.ParamByName('sped').AsString :=
                          ADM.unqryTablaG.FieldByName('SERIE_PEDC_SES').AsString;
        q.ExecSQL;
      except
        // tragado: tabla pdte_recibir puede no existir en esta BBDD si
        // no se ha aplicado la migracion correspondiente.
      end;

      // 2. Cabecera vuelve a BORRADOR + limpiamos referencias a docs.
      q.SQL.Text :=
        'UPDATE fza_compras_sesiones SET ' +
        '  ESTADO_SES                = ''BORRADOR'', ' +
        '  INSTANTE_MATERIALIZA_SES  = NULL, ' +
        '  USUARIO_MATERIALIZA_SES   = NULL, ' +
        '  SERIE_PEDC_SES            = NULL, ' +
        '  NUMERO_PEDC_SES           = NULL, ' +
        '  SERIE_ALBC_SES            = NULL, ' +
        '  NUMERO_ALBC_SES           = NULL, ' +
        '  MENSAJE_ERROR_SES         = NULL, ' +
        '  INSTANTE_MODIF            = NOW(), ' +
        '  USUARIO_MODIF             = :u ' +
        ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ParamByName('u').AsString := AUsuario;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;

    if bTxOwned and conn.InTransaction then conn.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      if bTxOwned and conn.InTransaction then conn.Rollback;
      AMsgError := E.Message;
    end;
  end;
end;

end.
