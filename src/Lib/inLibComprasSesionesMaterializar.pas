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
                                AMsgError: string;
                            const AFiltroAlmacen: string = '';
                            ASoloDocumentos: Boolean = False): Boolean;

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
  inLibtb,
  inLibAlbaranesCompraMovimientos;

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
      'INSERT IGNORE INTO fza_articulos ' +
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

// Sanea un texto de color libre del proveedor para usarlo como segmento del
// CODIGO_UNIDAD_SKU y como valor (AV) de fza_atributos_valores: mayusculas;
// los espacios pasan a '-'; se conservan letras, digitos, '-' y '_'; el resto
// de simbolos (/, %, EUR, ., :, ...) queda PROHIBIDO y se descarta. Sin
// separadores repetidos ni en los extremos. '' si no queda nada utilizable.
// IMPORTANTE: el servidor de fotos debe nombrar el token COLOR con esta MISMA
// regla (ver SanearColorFoto en inLibFotosNube) para que la foto case.
function SanearColorSku(const ATexto: string): string;
var
  i        : Integer;
  sParcial : string;
  c        : Char;
begin
  sParcial := UpperCase(Trim(ATexto));
  Result := '';
  for i := 1 to Length(sParcial) do
  begin
    c := sParcial[i];
    if c = ' ' then
      Result := Result + '-'
    else if CharInSet(c, ['A'..'Z', '0'..'9', '-', '_']) then
      Result := Result + c;
  end;
  while Pos('--', Result) > 0 do
    Result := StringReplace(Result, '--', '-', [rfReplaceAll]);
  while Pos('__', Result) > 0 do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);
  while (Result <> '') and CharInSet(Result[1], ['-', '_']) do
    Delete(Result, 1, 1);
  while (Result <> '') and CharInSet(Result[Length(Result)], ['-', '_']) do
    Delete(Result, Length(Result), 1);
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
function ResolverIdAvColorLinea(AConn: TUniConnection;
                                 const AColorTexto, ACodigoAtbColor,
                                       AUsuario: string;
                                 out AValor: string): Integer;
var
  q     : TUniQuery;
  idAtb : Integer;
  sAv   : string;
begin
  Result := 0;
  AValor := '';
  // Valor que llevara el SKU: texto del proveedor saneado y, si no hay, el
  // codigo del basico como compatibilidad.
  sAv := SanearColorSku(AColorTexto);
  if sAv = '' then
    sAv := SanearColorSku(ACodigoAtbColor);
  if sAv <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      // Reusar el AV si ya existe (identidad = valor del color).
      q.SQL.Text :=
        'SELECT ID_AV FROM fza_atributos_valores ' +
        ' WHERE ID_VA_AV = ''CO'' AND AV = :v LIMIT 1';
      q.ParamByName('v').AsString := sAv;
      q.Open;
      if not q.IsEmpty then
      begin
        Result := q.FieldByName('ID_AV').AsInteger;
        AValor := sAv;
      end
      else
      begin
        q.Close;
        // Helper opcional: ID_ATB del basico mapeado para clasificar el AV.
        // Si no hay basico o no existe, el AV queda sin clasificar
        // (ID_ATB_AV NULL); no se bloquea la materializacion, porque el SKU
        // lo define el texto del proveedor.
        idAtb := 0;
        if Trim(ACodigoAtbColor) <> '' then
        begin
          q.SQL.Text :=
            'SELECT ID_ATB FROM fza_atributos_basicos ' +
            ' WHERE ID_VA_ATB = ''CO'' AND CODIGO_ATB = :cod LIMIT 1';
          q.ParamByName('cod').AsString := ACodigoAtbColor;
          q.Open;
          if not q.IsEmpty then
            idAtb := q.FieldByName('ID_ATB').AsInteger;
          q.Close;
          // El basico es importante (clasificacion, HEX): si la linea
          // referencia uno que no existe en la paleta, fallar explicitamente
          // en vez de clasificar mal en silencio.
          if idAtb = 0 then
            raise Exception.CreateFmt(
              'No existe el color basico CODIGO_ATB=%s. Crealo en Mto ' +
              'Atributos Basicos antes de materializar.', [ACodigoAtbColor]);
        end;
        // Crear el AV: AV = token saneado (identidad que va al SKU);
        // DESCRIPCION_AV = texto original del proveedor (conserva la
        // referencia completa, util cuando el 'color' es una variacion de
        // diseno con simbolos que el saneo elimina). Enlazado al basico
        // (helper) cuando lo haya.
        if idAtb > 0 then
        begin
          q.SQL.Text :=
            'INSERT INTO fza_atributos_valores ' +
            '  (ID_VA_AV, AV, DESCRIPCION_AV, ID_ATB_AV, ESACTIVO_AV, ' +
            '   ORDEN_AV, INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
            '   USUARIO_MODIF) ' +
            'VALUES (''CO'', :v, :d, :ia, ''S'', 0, NOW(), :u, NOW(), :u)';
          q.ParamByName('ia').AsInteger := idAtb;
        end
        else
        begin
          q.SQL.Text :=
            'INSERT INTO fza_atributos_valores ' +
            '  (ID_VA_AV, AV, DESCRIPCION_AV, ESACTIVO_AV, ORDEN_AV, ' +
            '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
            'VALUES (''CO'', :v, :d, ''S'', 0, NOW(), :u, NOW(), :u)';
        end;
        q.ParamByName('v').AsString := sAv;
        q.ParamByName('d').AsString := Trim(AColorTexto);
        q.ParamByName('u').AsString := AUsuario;
        q.ExecSQL;
        q.SQL.Text :=
          'SELECT ID_AV FROM fza_atributos_valores ' +
          ' WHERE ID_VA_AV = ''CO'' AND AV = :v ' +
          ' ORDER BY ID_AV DESC LIMIT 1';
        q.ParamByName('v').AsString := sAv;
        q.Open;
        if not q.IsEmpty then
        begin
          Result := q.FieldByName('ID_AV').AsInteger;
          AValor := sAv;
        end;
      end;
    finally
      FreeAndNil(q);
    end;
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

    // Asociar el atributo basico (color) al articulo en
    // fza_articulos_atributos_basicos (AAB). Sin esto:
    //   - el panel "Atributos del SKU + Atributo basico" en la ficha
    //     del articulo sale vacio (su query JOINea AAB).
    //   - las etiquetas de articulo no encuentran el HEX del color.
    //   - el modal de "Atributo basico" del Mto no muestra el color.
    // El ID_ATB lo tomamos de fza_atributos_valores.ID_ATB_AV del propio
    // ID_AV resuelto. Idempotente: INSERT IGNORE por PK (CODIGO_ART, ID_AV).
    if iAvColor > 0 then
    begin
      qIns.SQL.Text :=
        'INSERT IGNORE INTO fza_articulos_atributos_basicos ' +
        '  (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'SELECT :art, AV.ID_AV, AV.ID_ATB_AV, NOW(), :u, NOW(), :u ' +
        '  FROM fza_atributos_valores AV ' +
        ' WHERE AV.ID_AV = :av ' +
        '   AND AV.ID_ATB_AV IS NOT NULL';
      qIns.ParamByName('art').AsString := ACodigoArt;
      qIns.ParamByName('av').AsInteger := iAvColor;
      qIns.ParamByName('u').AsString   := AUsuario;
      qIns.ExecSQL;
    end;

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
          'INSERT IGNORE INTO fza_codigos_barras ' +
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
                                               AUsuario: string;
                                         const ACodigoAlmOverride: string = '');
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
      '       S.REF_PRV_SES, ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ELSE S.CODIGO_ALM_SES END, ' +
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
    q.ParamByName('alm_ovr').AsString := ACodigoAlmOverride;
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
                                            ARefPrv,
                                            AUsuario: string;
                                      ACantidad, APrecio,
                                      APorcIva: Double;
                                      AIdAcPivot: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // ID_AC_PIVOT_ALBCLIN: sistema de tallas heredado de la linea de
    // sesion. Imprescindible para que el modo 'Tallas en horizontal'
    // del Mto sepa que conjunto pivot aplicar — sin el, todas las
    // columnas talla quedan ocultas. Si AIdAcPivot=0 va NULL (linea
    // escalar sin tallaje, p.ej. SERVICIO).
    q.SQL.Text :=
      'INSERT INTO fza_albaranes_compra_lineas ' +
      '  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
      '   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN, ' +
      '   ID_AC_PIVOT_ALBCLIN, ' +
      '   CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
      '   DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN, ' +
      '   CANTIDAD_ALBCLIN, TIPO_IVA_ARTICULO_ALBCLIN, ' +
      '   PORCENTAJE_IVA_ALBCLIN, ' +
      '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
      '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
      '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
      '   ESFACTURADA_ALBCLIN, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:n, :s, :l, :art, :sku, :refprv, :acpivot, ' +
      '        :fam, :nomfam, :desc, ''Uds'', ' +
      '        :cant, :tiva, :piva, :pre, :preciva, :tot, :alm, ''N'', ' +
      '        NOW(), :u, NOW(), :u)';
    q.ParamByName('n').AsString    := ANumAlbc;
    q.ParamByName('s').AsString    := ASerieAlbc;
    q.ParamByName('l').AsString    := ALineaAlbc;
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('sku').AsString  := ACodigoSku;
    if ARefPrv <> '' then
      q.ParamByName('refprv').AsString := ARefPrv
    else
      q.ParamByName('refprv').Clear;
    if AIdAcPivot > 0 then
      q.ParamByName('acpivot').AsInteger := AIdAcPivot
    else
      q.ParamByName('acpivot').Clear;
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

// Rellena los % IVA en la CABECERA del albaran desde vi_ivas_empresa
// (resuelve el IVA por defecto del grupo de la empresa de la cabecera).
// El INSERT inicial deja esos campos a 0 porque la sesion origen no
// maneja IVA. Llamar antes de RellenarIvaLineasAlbaranCompra.
procedure AsignarIvaCabeceraAlbaranCompra(AConn: TUniConnection;
                                           const ASerieAlbc, ANumAlbc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra C ' +
      '  JOIN vi_ivas_empresa V ' +
      '    ON V.CODIGO_EMP_EMP = C.CODIGO_EMP_ALBC ' +
      '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
      '   SET C.CODIGO_IVA_ALBC      = V.CODIGO_IVA, ' +
      '       C.PORCENTAJE_IVAN_ALBC = V.PORCENTAJE_NORMAL_IVA, ' +
      '       C.PORCENTAJE_IVAR_ALBC = V.PORCENTAJE_REDUCIDO_IVA, ' +
      '       C.PORCENTAJE_IVAS_ALBC = V.PORCENTAJE_SUPERREDUCIDO_IVA, ' +
      '       C.PORCENTAJE_IVAE_ALBC = V.PORCENTAJE_EXENTO_IVA ' +
      ' WHERE C.NUMERO_ALBC = :n AND C.SERIE_ALBC = :s';
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Rellena PORCENTAJE_IVA_ALBCLIN y PRECIO_COMPRA_CIVA en las lineas
// del albaran a partir de los porcentajes que viven en la cabecera
// (PORCENTAJE_IVAN_ALBC, _IVAR_ALBC, _IVAS_ALBC, _IVAE_ALBC), mapeando
// por TIPO_IVA_ARTICULO_ALBCLIN. La sesion origen no maneja IVA, por
// eso InsertarLineaAlbaranCompra inserta el porcentaje a 0 y aqui se
// reconstruye. Llamar SIEMPRE antes de RecalcularTotalesAlbaranCompra
// — los totales suman IVA con este porcentaje. Requiere que la
// cabecera ya tenga los % asignados (AsignarIvaCabeceraAlbaranCompra).
procedure RellenarIvaLineasAlbaranCompra(AConn: TUniConnection;
                                          const ASerieAlbc, ANumAlbc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra_lineas L ' +
      '  JOIN fza_albaranes_compra C ' +
      '    ON C.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '   AND C.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '   SET L.PORCENTAJE_IVA_ALBCLIN = CASE L.TIPO_IVA_ARTICULO_ALBCLIN ' +
      '          WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_ALBC, 0) ' +
      '          WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_ALBC, 0) ' +
      '          WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_ALBC, 0) ' +
      '          WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_ALBC, 0) ' +
      '          ELSE 0 END, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN = ' +
      '         L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * (1 + ' +
      '           CASE L.TIPO_IVA_ARTICULO_ALBCLIN ' +
      '            WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_ALBC, 0) ' +
      '            WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_ALBC, 0) ' +
      '            WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_ALBC, 0) ' +
      '            WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_ALBC, 0) ' +
      '            ELSE 0 END / 100) ' +
      ' WHERE L.NUMERO_ALBC_ALBCLIN = :n AND L.SERIE_ALBC_ALBCLIN = :s';
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('s').AsString := ASerieAlbc;
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
                                             AUsuario: string;
                                       const AFiltroAlmacen: string = '');
var
  qC : TUniQuery;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sDescripcion, sCodigoFam, sNombreFam, sTipoIva,
  sLineaAlbc: string;
  iIdAvPivot, iIdAvFila, iIdAcPivot, iLineaSeq: Integer;
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
    // Agrupamos por (articulo, pivot=talla, color, almacen). El SKU real
    // se resuelve por grupo con ResolverCodigoSku. CLAVE: agrupamos por
    // CODIGO_ATB_COLOR_SESLIN (el atributo basico de color de la linea),
    // NO por ID_VA_FILA_SESLIN (que es 'CO', un position string). El
    // ID_AV numerico de cada color se resuelve dentro del bucle.
    qC.SQL.Text :=
      'SELECT  ' +
      '    CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
      '         THEN L.CODIGO_ART_REUSAR_SESLIN ' +
      '         ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
      '    C.ID_AV_PIVOT_SESCEL, ' +
      '    IFNULL(L.ID_AC_PIVOT_SESLIN, 0) AS ID_AC_PIVOT, ' +
      '    IFNULL(L.CODIGO_ATB_COLOR_SESLIN, '''') AS COD_COLOR, ' +
      '    IFNULL(L.COLOR_TEXTO_SESLIN, '''')     AS COLOR_TEXTO, ' +
      '    IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), :alm_cab) AS ALM_EFE, ' +
      '    SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
      '    L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '    L.CODIGO_FAM_SESLIN, ' +
      '    IFNULL(L.TIPO_IVA_SESLIN, ''N'') AS TIPO_IVA, ' +
      '    L.TIPO_LINEA_SESLIN, ' +
      '    IFNULL(L.REF_PRV_SESLIN, '''') AS REF_PRV ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL  = :s ' +
      '   AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.CANTIDAD_SESCEL   > 0 ' +
      '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
      '   AND (:falm = '''' OR IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), :alm_cab) = :falm) ' +
      ' GROUP BY CODIGO_ART, C.ID_AV_PIVOT_SESCEL, ID_AC_PIVOT, COD_COLOR, ' +
      '          COLOR_TEXTO, ALM_EFE, ' +
      '          L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '          L.CODIGO_FAM_SESLIN, TIPO_IVA, L.TIPO_LINEA_SESLIN, REF_PRV ' +
      ' ORDER BY CODIGO_ART, COD_COLOR, C.ID_AV_PIVOT_SESCEL, ALM_EFE';
    qC.ParamByName('alm_cab').AsString := sCodigoAlmCab;
    qC.ParamByName('falm').AsString := AFiltroAlmacen;
    qC.ParamByName('s').AsString := ASerieSes;
    qC.ParamByName('n').AsString := ANumSes;
    qC.Open;

    while not qC.Eof do
    begin
      sCodigoArt := qC.FieldByName('CODIGO_ART').AsString;
      iIdAvPivot := qC.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
      iIdAcPivot := qC.FieldByName('ID_AC_PIVOT').AsInteger;
      sCodigoAlm := qC.FieldByName('ALM_EFE').AsString;
      rCantidad  := qC.FieldByName('CANTIDAD_TOTAL').AsFloat;
      rCoste     := qC.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
      sDescripcion := qC.FieldByName('DESCRIPCION_SESLIN').AsString;
      sCodigoFam := qC.FieldByName('CODIGO_FAM_SESLIN').AsString;
      sTipoIva   := qC.FieldByName('TIPO_IVA').AsString;
      rPorIva    := 0;  // se podra cruzar con fza_ivas en hito posterior

      // Resolver ID_AV del color (fila) desde CODIGO_ATB_COLOR_SESLIN.
      // Si la linea no tiene color (ESCALAR), iIdAvFila queda 0 y
      // ResolverCodigoSku usa la query simple (solo pivot).
      iIdAvFila := 0;
      if Trim(qC.FieldByName('COD_COLOR').AsString) <> '' then
        iIdAvFila := ResolverIdAvColorLinea(
          AConn,
          qC.FieldByName('COLOR_TEXTO').AsString,
          qC.FieldByName('COD_COLOR').AsString,
          AUsuario, sCodigoSku);  // sCodigoSku se reusa como out, se sobreescribe abajo

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
        sCodigoAlm, sTipoIva,
        qC.FieldByName('REF_PRV').AsString,
        AUsuario,
        rCantidad, rCoste, rPorIva, iIdAcPivot);

      qC.Next;
    end;
  finally
    FreeAndNil(qC);
  end;
end;

// La generacion de movimientos del albaran de compra se ha movido a
// inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra,
// que lee del propio albaran (lineas + celdas) en vez de la sesion
// origen. Asi el flujo es identico tanto si el albaran viene de una
// sesion materializada como si se pica a mano y luego se cierra desde
// el Mto. MaterializarSesion (mas abajo) llama directamente a la nueva
// funcion despues de InsertarLineasAlbaranCompra y RecalcularTotales.

// ---------------------------------------------------------------------------
// Pedidos de compra — funciones espejo de las de albaran
// ---------------------------------------------------------------------------
// Mismo patron que InsertarAlbaranCompraCabecera/Lineas/Iva/Totales pero
// escribiendo en fza_pedidos_compra(_lineas). A diferencia del albaran,
// el pedido NO mueve stock fisico: la cantidad pendiente la deposita
// GenerarPedidoPdteRecibir en fza_articulos_pdte_recibir. Las cantidades
// de las lineas son las pedidas; CANTIDAD_RECIBIDA_PEDCLIN nace a 0 y se
// va incrementando cuando se generan albaranes desde el Mto de pedidos
// (inLibPedidosCompra.CrearAlbaranDesdePedido).

procedure InsertarPedidoCompraCabecera(AConn: TUniConnection;
                                        ADM: TdmComprasSesiones;
                                        const ASeriePedc, ANumPedc,
                                              AUsuario: string;
                                        const ACodigoAlmOverride: string = '');
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_pedidos_compra ' +
      '  (NUMERO_PEDC, SERIE_PEDC, FECHA_PEDC, ESTADO_PEDC, ' +
      '   CODIGO_EMP_PEDC, RAZON_SOCIAL_EMPRESA_PEDC, NIF_EMPRESA_PEDC, ' +
      '   MOVIL_EMPRESA_PEDC, EMAIL_EMPRESA_PEDC, ' +
      '   DIRECCION1_EMPRESA_PEDC, DIRECCION2_EMPRESA_PEDC, ' +
      '   POBLACION_EMPRESA_PEDC, PROVINCIA_EMPRESA_PEDC, ' +
      '   CODIGO_PAI_EMPRESA_PEDC, NOMBRE_PAI_EMPRESA_PEDC, ' +
      '   CODIGO_POSTAL_EMPRESA_PEDC, ' +
      '   CODIGO_PRV_PEDC, RAZON_SOCIAL_PRV_PEDC, NIF_PRV_PEDC, ' +
      '   MOVIL_PRV_PEDC, EMAIL_PRV_PEDC, ' +
      '   DIRECCION1_PRV_PEDC, DIRECCION2_PRV_PEDC, ' +
      '   POBLACION_PRV_PEDC, PROVINCIA_PRV_PEDC, ' +
      '   CODIGO_POSTAL_PRV_PEDC, ' +
      '   REF_PROVEEDOR_PEDC, CODIGO_ALM_PEDC, ' +
      '   ID_PV_TEMPORADA_PEDC, ' +
      '   TOTAL_BASES_PEDC, TOTAL_IMPUESTOS_PEDC, TOTAL_LIQUIDO_PEDC, ' +
      '   CONTADOR_LINEAS_PEDC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :npedc, :spedc, S.FECHA_SES, ''ABIERTO'', ' +
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
      '       S.REF_PRV_SES, ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ELSE S.CODIGO_ALM_SES END, ' +
      '       S.ID_PV_TEMPORADA_SES, ' +
      '       0, 0, 0, ''0'', ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones S ' +
      '  LEFT JOIN fza_empresas E    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = S.CODIGO_PRV_SES ' +
      ' WHERE S.SERIE_SES = :s AND S.NUMERO_SES = :n';
    q.ParamByName('npedc').AsString := ANumPedc;
    q.ParamByName('spedc').AsString := ASeriePedc;
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('alm_ovr').AsString := ACodigoAlmOverride;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure InsertarLineaPedidoCompra(AConn: TUniConnection;
                                     const ASeriePedc, ANumPedc,
                                           ALineaPedc, ACodigoArt,
                                           ACodigoSku, ACodigoFam,
                                           ANombreFam, ADescripcion,
                                           ACodigoAlm, ATipoIva,
                                           ARefPrv, AColorTexto,
                                           AUsuario: string;
                                     ACantidad, APrecio,
                                     APorIva: Double;
                                     AIdAcPivot: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_pedidos_compra_lineas ' +
      '  (NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN, ' +
      '   CODIGO_ART_PEDCLIN, CODIGO_UNIDAD_PEDCLIN, REF_PRV_PEDCLIN, ' +
      '   ID_AC_PIVOT_PEDCLIN, ' +
      '   CODIGO_FAM_PEDCLIN, NOMBRE_FAM_PEDCLIN, COLOR_TEXTO_PEDCLIN, ' +
      '   DESCRIPCION_ARTICULO_PEDCLIN, TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
      '   CANTIDAD_PEDCLIN, CANTIDAD_RECIBIDA_PEDCLIN, ' +
      '   TIPO_IVA_ARTICULO_PEDCLIN, PORCENTAJE_IVA_PEDCLIN, ' +
      '   PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
      '   PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
      '   TOTAL_PEDCLIN, CODIGO_ALMACEN_PEDCLIN, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:n, :s, :l, :art, :sku, :refprv, :acpivot, ' +
      '        :fam, :nomfam, :coltxt, :desc, ''Uds'', ' +
      '        :cant, 0, :tiva, :piva, :pre, :preciva, :tot, :alm, ' +
      '        NOW(), :u, NOW(), :u)';
    q.ParamByName('n').AsString    := ANumPedc;
    q.ParamByName('s').AsString    := ASeriePedc;
    q.ParamByName('l').AsString    := ALineaPedc;
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('sku').AsString  := ACodigoSku;
    if ARefPrv <> '' then
      q.ParamByName('refprv').AsString := ARefPrv
    else
      q.ParamByName('refprv').Clear;
    if AIdAcPivot > 0 then
      q.ParamByName('acpivot').AsInteger := AIdAcPivot
    else
      q.ParamByName('acpivot').Clear;
    q.ParamByName('fam').AsString  := ACodigoFam;
    q.ParamByName('nomfam').AsString := ANombreFam;
    if AColorTexto <> '' then
      q.ParamByName('coltxt').AsString := AColorTexto
    else
      q.ParamByName('coltxt').Clear;
    q.ParamByName('desc').AsString := ADescripcion;
    q.ParamByName('cant').AsFloat  := ACantidad;
    q.ParamByName('tiva').AsString := ATipoIva;
    q.ParamByName('piva').AsFloat  := APorIva;
    q.ParamByName('pre').AsFloat   := APrecio;
    q.ParamByName('preciva').AsFloat := APrecio * (1 + APorIva / 100);
    q.ParamByName('tot').AsFloat   := ACantidad * APrecio;
    q.ParamByName('alm').AsString  := ACodigoAlm;
    q.ParamByName('u').AsString    := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Espejo de InsertarLineasAlbaranCompra: itera celdas de la sesion
// agrupadas por (SKU, almacen) y crea una linea en
// fza_pedidos_compra_lineas por cada combinacion con cantidad > 0.
// LINEA_PEDCLIN se asigna secuencial (0010, 0020, ...).
procedure InsertarLineasPedidoCompra(AConn: TUniConnection;
                                      ADM: TdmComprasSesiones;
                                      const ASerieSes, ANumSes,
                                            ASeriePedc, ANumPedc,
                                            AUsuario: string;
                                      const AFiltroAlmacen: string = '');
var
  qC : TUniQuery;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sDescripcion, sCodigoFam, sNombreFam, sTipoIva,
  sLineaPedc: string;
  iIdAvPivot, iIdAvFila, iIdAcPivot, iLineaSeq: Integer;
  rCantidad, rCoste, rPorIva: Double;
begin
  sCodigoAlmCab := ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  if sCodigoAlmCab = '' then
    raise Exception.Create('Falta CODIGO_ALM_SES en la cabecera de la sesion ' +
                           'para generar el pedido de compra.');
  iLineaSeq := 0;
  qC := TUniQuery.Create(nil);
  try
    qC.Connection := AConn;
    qC.SQL.Text :=
      'SELECT  ' +
      '    CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
      '         THEN L.CODIGO_ART_REUSAR_SESLIN ' +
      '         ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
      '    C.ID_AV_PIVOT_SESCEL, ' +
      '    IFNULL(L.ID_AC_PIVOT_SESLIN, 0) AS ID_AC_PIVOT, ' +
      '    IFNULL(L.CODIGO_ATB_COLOR_SESLIN, '''') AS COD_COLOR, ' +
      '    IFNULL(L.COLOR_TEXTO_SESLIN, '''')     AS COLOR_TEXTO, ' +
      '    IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), :alm_cab) AS ALM_EFE, ' +
      '    SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
      '    L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '    L.CODIGO_FAM_SESLIN, ' +
      '    IFNULL(L.TIPO_IVA_SESLIN, ''N'') AS TIPO_IVA, ' +
      '    L.TIPO_LINEA_SESLIN, ' +
      '    IFNULL(L.REF_PRV_SESLIN, '''') AS REF_PRV ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL  = :s ' +
      '   AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.CANTIDAD_SESCEL   > 0 ' +
      '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
      '   AND (:falm = '''' OR IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), :alm_cab) = :falm) ' +
      ' GROUP BY CODIGO_ART, C.ID_AV_PIVOT_SESCEL, ID_AC_PIVOT, COD_COLOR, ' +
      '          COLOR_TEXTO, ALM_EFE, ' +
      '          L.PRECIO_COMPRA_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '          L.CODIGO_FAM_SESLIN, TIPO_IVA, L.TIPO_LINEA_SESLIN, REF_PRV ' +
      ' ORDER BY CODIGO_ART, COD_COLOR, C.ID_AV_PIVOT_SESCEL, ALM_EFE';
    qC.ParamByName('alm_cab').AsString := sCodigoAlmCab;
    qC.ParamByName('falm').AsString := AFiltroAlmacen;
    qC.ParamByName('s').AsString := ASerieSes;
    qC.ParamByName('n').AsString := ANumSes;
    qC.Open;
    while not qC.Eof do
    begin
      sCodigoArt := qC.FieldByName('CODIGO_ART').AsString;
      iIdAvPivot := qC.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
      iIdAcPivot := qC.FieldByName('ID_AC_PIVOT').AsInteger;
      sCodigoAlm := qC.FieldByName('ALM_EFE').AsString;
      rCantidad  := qC.FieldByName('CANTIDAD_TOTAL').AsFloat;
      rCoste     := qC.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
      sDescripcion := qC.FieldByName('DESCRIPCION_SESLIN').AsString;
      sCodigoFam := qC.FieldByName('CODIGO_FAM_SESLIN').AsString;
      sTipoIva   := qC.FieldByName('TIPO_IVA').AsString;
      rPorIva    := 0;
      iIdAvFila := 0;
      if Trim(qC.FieldByName('COD_COLOR').AsString) <> '' then
        iIdAvFila := ResolverIdAvColorLinea(
          AConn,
          qC.FieldByName('COLOR_TEXTO').AsString,
          qC.FieldByName('COD_COLOR').AsString,
          AUsuario, sCodigoSku);
      sCodigoSku := ResolverCodigoSku(AConn, sCodigoArt, iIdAvPivot, iIdAvFila);
      if sCodigoSku = '' then
      begin
        qC.Next;
        Continue;
      end;
      sNombreFam := '';
      iLineaSeq := iLineaSeq + 1;
      sLineaPedc := Format('%.4d', [iLineaSeq * 10]);
      InsertarLineaPedidoCompra(AConn,
        ASeriePedc, ANumPedc, sLineaPedc,
        sCodigoArt, sCodigoSku, sCodigoFam, sNombreFam, sDescripcion,
        sCodigoAlm, sTipoIva,
        qC.FieldByName('REF_PRV').AsString,
        qC.FieldByName('COLOR_TEXTO').AsString,
        AUsuario,
        rCantidad, rCoste, rPorIva, iIdAcPivot);
      qC.Next;
    end;
  finally
    FreeAndNil(qC);
  end;
end;

procedure AsignarIvaCabeceraPedidoCompra(AConn: TUniConnection;
                                          const ASeriePedc, ANumPedc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra C ' +
      '  JOIN vi_ivas_empresa V ' +
      '    ON V.CODIGO_EMP_EMP = C.CODIGO_EMP_PEDC ' +
      '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
      '   SET C.CODIGO_IVA_PEDC      = V.CODIGO_IVA, ' +
      '       C.PORCENTAJE_IVAN_PEDC = V.PORCENTAJE_NORMAL_IVA, ' +
      '       C.PORCENTAJE_IVAR_PEDC = V.PORCENTAJE_REDUCIDO_IVA, ' +
      '       C.PORCENTAJE_IVAS_PEDC = V.PORCENTAJE_SUPERREDUCIDO_IVA, ' +
      '       C.PORCENTAJE_IVAE_PEDC = V.PORCENTAJE_EXENTO_IVA ' +
      ' WHERE C.NUMERO_PEDC = :n AND C.SERIE_PEDC = :s';
    q.ParamByName('n').AsString := ANumPedc;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure RellenarIvaLineasPedidoCompra(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra C ' +
      '    ON C.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '   AND C.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   SET L.PORCENTAJE_IVA_PEDCLIN = CASE L.TIPO_IVA_ARTICULO_PEDCLIN ' +
      '          WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_PEDC, 0) ' +
      '          WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_PEDC, 0) ' +
      '          WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_PEDC, 0) ' +
      '          WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_PEDC, 0) ' +
      '          ELSE 0 END, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN = ' +
      '         L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN * (1 + ' +
      '           CASE L.TIPO_IVA_ARTICULO_PEDCLIN ' +
      '            WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_PEDC, 0) ' +
      '            WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_PEDC, 0) ' +
      '            WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_PEDC, 0) ' +
      '            WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_PEDC, 0) ' +
      '            ELSE 0 END / 100) ' +
      ' WHERE L.NUMERO_PEDC_PEDCLIN = :n AND L.SERIE_PEDC_PEDCLIN = :s';
    q.ParamByName('n').AsString := ANumPedc;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure RecalcularTotalesPedidoCompra(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra C ' +
      '  JOIN ( ' +
      '       SELECT NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, ' +
      '              IFNULL(SUM(TOTAL_PEDCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(TOTAL_PEDCLIN * PORCENTAJE_IVA_PEDCLIN / 100), 0) AS IVA, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_pedidos_compra_lineas ' +
      '        WHERE NUMERO_PEDC_PEDCLIN = :n ' +
      '          AND SERIE_PEDC_PEDCLIN  = :s ' +
      '        GROUP BY NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN) AS T ' +
      '    ON T.NUMERO_PEDC_PEDCLIN = C.NUMERO_PEDC ' +
      '   AND T.SERIE_PEDC_PEDCLIN  = C.SERIE_PEDC ' +
      '   SET C.TOTAL_BASES_PEDC     = T.BASE, ' +
      '       C.TOTAL_IMPUESTOS_PEDC = T.IVA, ' +
      '       C.TOTAL_LIQUIDO_PEDC   = T.BASE + T.IVA, ' +
      '       C.CONTADOR_LINEAS_PEDC = LPAD(T.NLIN * 10, 8, ''0'') ' +
      ' WHERE C.NUMERO_PEDC = :n AND C.SERIE_PEDC = :s';
    q.ParamByName('n').AsString := ANumPedc;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
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
        'INSERT IGNORE INTO fza_articulos_pdte_recibir ' +
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
                                AMsgError: string;
                            const AFiltroAlmacen: string = '';
                            ASoloDocumentos: Boolean = False): Boolean;
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
    // Creacion de articulos / SKUs / barras / proveedor / tarifa /
    // propiedades / fotos. Esta fase es global a la sesion (no depende
    // del almacen) y solo debe ejecutarse UNA vez aunque el caller
    // itere materializaciones por almacen (modo distribuido + 'un doc
    // por almacen'). El llamador pasa ASoloDocumentos=True en las
    // iteraciones 2..N para saltarla.
    if not ASoloDocumentos then
    begin
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
          end;
          InsertarPropiedadesFijas(conn, sSerieSes, sNumSes,
                                   sCodigoArt, AUsuario);
          InsertarTemporadaCabecera(conn, sCodigoArt, AUsuario,
                                    iIdPvTemporada);
          if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString <> 'SERVICIO' then
          begin
            UpsertArticuloProveedor(conn, sCodigoArt, sCodigoPrv,
              qLin.FieldByName('REF_PRV_SESLIN').AsString,
              AUsuario, rPrecio);
            rPrecioVta := qLin.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
            UpsertArticuloTarifa(conn, sCodigoArt, sCodigoTar,
              AUsuario, rPrecioVta);
          end;
          inLibFotos.oFotos.MigrarFotosSesion(sSerieSes, sNumSes, iLin,
                                              sCodigoArt, AUsuario);
          qLin.Next;
        end;
      finally
        FreeAndNil(qLin);
      end;
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
      // 1. Reservar NUMERO_PEDC del contador global (tipo 'PC'). En el
      //    modo "un doc por almacen" cada iteracion del bucle exterior
      //    pasa por aqui y obtiene su propio numero — antes se reusaba
      //    sNumSes y eso provocaba colisiones de PK entre almacenes.
      ANumPed   := inLibtb.ObtenerSiguienteContador('PC');
      ASeriePed := sSeriePedReal;
      // 2. Crear cabecera en fza_pedidos_compra denormalizando empresa
      //    y proveedor desde la sesion. AFiltroAlmacen viaja como
      //    almacen destino por defecto (override sobre CODIGO_ALM_SES).
      InsertarPedidoCompraCabecera(conn, ADM, ASeriePed, ANumPed, AUsuario,
                                    AFiltroAlmacen);
      // 3. Lineas agregadas por (SKU, almacen): una por combinacion con
      //    cantidad > 0. Misma logica que el albaran pero escribiendo en
      //    fza_pedidos_compra_lineas con CANTIDAD_RECIBIDA = 0.
      InsertarLineasPedidoCompra(conn, ADM, sSerieSes, sNumSes,
                                  ASeriePed, ANumPed, AUsuario,
                                  AFiltroAlmacen);
      // 4. IVA en cabecera + lineas y totales. Reusamos el patron del
      //    albaran porque la sesion origen no maneja IVA explicito.
      AsignarIvaCabeceraPedidoCompra(conn, ASeriePed, ANumPed);
      RellenarIvaLineasPedidoCompra(conn, ASeriePed, ANumPed);
      RecalcularTotalesPedidoCompra(conn, ASeriePed, ANumPed);
      // 5. Pendientes de recibir: una fila por (SKU, almacen, doc) en
      //    fza_articulos_pdte_recibir. Es lo que ve el modulo de stock
      //    via vi_articulos_pdte_recibir. NO mueve stock fisico.
      GenerarPedidoPdteRecibir(conn, ADM, sSerieSes, sNumSes,
                                ASeriePed, ANumPed, AUsuario);
      // 6. Registro en fza_compras_sesiones_documentos para la pestania
      //    'Documentos' del Mto. Usamos INSERT IGNORE para soportar
      //    re-materializacion sin chocar contra la PK.
      qLin := TUniQuery.Create(nil);
      try
        qLin.Connection := conn;
        qLin.SQL.Text :=
          'INSERT IGNORE INTO fza_compras_sesiones_documentos ' +
          '  (SERIE_SES_SESDOC, NUMERO_SES_SESDOC, TIPO_DOC_SESDOC, ' +
          '   CODIGO_ALM_SESDOC, CODIGO_EMP_SESDOC, ' +
          '   SERIE_SESDOC, NUMERO_SESDOC, ' +
          '   INSTANTE_ALTA, USUARIO_ALTA) ' +
          'SELECT :s, :n, ''PEDC'', ' +
          '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ' +
          '            ELSE S.CODIGO_ALM_SES END, ' +
          '       S.CODIGO_EMP_SES, :sd, :nd, NOW(), :u ' +
          '  FROM fza_compras_sesiones S ' +
          ' WHERE S.SERIE_SES = :s AND S.NUMERO_SES = :n';
        qLin.ParamByName('s').AsString  := sSerieSes;
        qLin.ParamByName('n').AsString  := sNumSes;
        qLin.ParamByName('alm_ovr').AsString := AFiltroAlmacen;
        qLin.ParamByName('sd').AsString := ASeriePed;
        qLin.ParamByName('nd').AsString := ANumPed;
        qLin.ParamByName('u').AsString  := AUsuario;
        qLin.ExecSQL;
      finally
        FreeAndNil(qLin);
      end;
    end;
    if AESGeneraAlbaran then
    begin
      // 1. Obtener NUMERO_ALBC del contador global (tipo 'AB').
      ANumAlb   := inLibtb.ObtenerSiguienteContador('AB');
      ASerieAlb := sSerieAlbReal;
      // 2. Crear cabecera en fza_albaranes_compra denormalizando
      //    empresa + proveedor desde la sesion.
      InsertarAlbaranCompraCabecera(conn, ADM, ASerieAlb, ANumAlb, AUsuario,
                                     AFiltroAlmacen);
      // 3. Crear lineas: una por (SKU, almacen) con SUM(CANTIDAD).
      InsertarLineasAlbaranCompra(conn, ADM, sSerieSes, sNumSes,
                                  ASerieAlb, ANumAlb, AUsuario,
                                  AFiltroAlmacen);
      // 4a. Asignar % IVA en la cabecera (desde vi_ivas_empresa).
      AsignarIvaCabeceraAlbaranCompra(conn, ASerieAlb, ANumAlb);
      // 4b. Rellenar IVA en lineas (sesion no maneja IVA, lo tomamos
      //     de la cabecera del albaran segun TIPO_IVA del articulo).
      RellenarIvaLineasAlbaranCompra(conn, ASerieAlb, ANumAlb);
      // 5. Recalcular totales de la cabecera a partir de las lineas.
      RecalcularTotalesAlbaranCompra(conn, ASerieAlb, ANumAlb);
      // 5. Movimientos de entrada leyendo del propio albaran. Asi el
      //    flujo es el mismo que cuando el albaran se cierra a mano
      //    desde el Mto, y la funcion vive en una sola unidad.
      inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
        conn, ASerieAlb, ANumAlb, AUsuario);
      // 6. Como ya tiene movimientos, marcamos el albaran como CERRADO
      //    para que el Mto no permita modificarlo sin reabrirlo (el
      //    AfterPost del data module se encarga de revertir/regenerar
      //    movimientos segun las transiciones de estado).
      qLin := TUniQuery.Create(nil);
      try
        qLin.Connection := conn;
        qLin.SQL.Text :=
          'UPDATE fza_albaranes_compra SET ' +
          '  ESTADO_ALBC    = ''CERRADO'', ' +
          '  INSTANTE_MODIF = NOW(), ' +
          '  USUARIO_MODIF  = :u ' +
          ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
        qLin.ParamByName('s').AsString := ASerieAlb;
        qLin.ParamByName('n').AsString := ANumAlb;
        qLin.ParamByName('u').AsString := AUsuario;
        qLin.ExecSQL;
      finally
        FreeAndNil(qLin);
      end;
      // Registro en fza_compras_sesiones_documentos (TIPO_DOC='ALBC')
      // para la pestania 'Documentos' del Mto. Tomamos el almacen
      // efectivo del albaran que acabamos de crear (CODIGO_ALM_ALBC),
      // que ya respeta el override por almacen si lo hay.
      qLin := TUniQuery.Create(nil);
      try
        qLin.Connection := conn;
        qLin.SQL.Text :=
          'INSERT IGNORE INTO fza_compras_sesiones_documentos ' +
          '  (SERIE_SES_SESDOC, NUMERO_SES_SESDOC, TIPO_DOC_SESDOC, ' +
          '   CODIGO_ALM_SESDOC, CODIGO_EMP_SESDOC, ' +
          '   SERIE_SESDOC, NUMERO_SESDOC, ' +
          '   INSTANTE_ALTA, USUARIO_ALTA) ' +
          'SELECT :s, :n, ''ALBC'', ' +
          '       A.CODIGO_ALM_ALBC, A.CODIGO_EMP_ALBC, ' +
          '       :sd, :nd, NOW(), :u ' +
          '  FROM fza_albaranes_compra A ' +
          ' WHERE A.SERIE_ALBC = :sd AND A.NUMERO_ALBC = :nd';
        qLin.ParamByName('s').AsString  := sSerieSes;
        qLin.ParamByName('n').AsString  := sNumSes;
        qLin.ParamByName('sd').AsString := ASerieAlb;
        qLin.ParamByName('nd').AsString := ANumAlb;
        qLin.ParamByName('u').AsString  := AUsuario;
        qLin.ExecSQL;
      finally
        FreeAndNil(qLin);
      end;
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

      // 0g. propiedades (CODIGO_ART_ART — el sufijo del FK reusa la PK
      //     del articulo, no el sufijo de la tabla)
      q.SQL.Text :=
        'DELETE P FROM fza_articulos_propiedades P ' +
        '  JOIN fza_compras_sesiones_lineas L ' +
        '    ON L.CODIGO_ART_TENTATIVO_SESLIN = P.CODIGO_ART_ART ' +
        ' WHERE L.SERIE_SES_SESLIN  = :s ' +
        '   AND L.NUMERO_SES_SESLIN = :n ' +
        '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
        '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
      q.ParamByName('s').AsString := sSerieSes;
      q.ParamByName('n').AsString := sNumSes;
      q.ExecSQL;

      // 0h. fotos (CODIGO_ART_FOT). Si la tabla no existe en esta BBDD
      //     o no hubo fotos, no es critico — try/except con log.
      try
        q.SQL.Text :=
          'DELETE F FROM fza_articulos_fotos F ' +
          '  JOIN fza_compras_sesiones_lineas L ' +
          '    ON L.CODIGO_ART_TENTATIVO_SESLIN = F.CODIGO_ART_FOT ' +
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
      // 0j-bis. Limpiar fza_compras_sesiones_documentos. Si se vuelve a
      //         materializar, los INSERT IGNORE meterian otra vez los
      //         mismos docs. Borramos siempre toda la lista de la
      //         sesion sin filtrar tipo, para vaciar tanto PEDC como
      //         ALBC. Best effort: si la tabla no existe (BBDD legacy
      //         pre-script) seguimos sin abortar.
      try
        q.SQL.Text :=
          'DELETE FROM fza_compras_sesiones_documentos ' +
          ' WHERE SERIE_SES_SESDOC  = :s ' +
          '   AND NUMERO_SES_SESDOC = :n';
        q.ParamByName('s').AsString := sSerieSes;
        q.ParamByName('n').AsString := sNumSes;
        q.ExecSQL;
      except
      end;

      // 1. Borrar los movimientos de almacen que esta sesion creo. Solo
      //    los TIPO_DOC_MOV='AC' cuyo NUMERO_DOC coincide con el de la
      //    sesion: los demas movimientos del articulo (anteriores o de
      //    otras sesiones) se preservan. Si la sesion uso serie de
      //    albaran distinta a la propia, tambien la borramos.
      // Borrar movimientos creados por la materializacion. Los inserta
      // GenerarMovimientosDesdeAlbaranCompra con TIPO_DOC_MOV='AC',
      // SERIE/NUMERO del ALBARAN y EMPRESA/ALMACEN de la cabecera. Sin
      // albaran materializado no hay nada que borrar (los pedidos
      // pendientes de recibir no generan movimientos, viven en
      // fza_articulos_pdte_recibir y se borran abajo).
      if (ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString <> '') and
         (ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString  <> '') then
      begin
        // Borrar movimientos via SP: decrementa stock + acumulados
        q.SQL.Text :=
          'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :salb, :nalb)';
        q.ParamByName('t').AsString := 'AC';
        q.ParamByName('salb').AsString :=
                          ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString;
        q.ParamByName('nalb').AsString :=
                          ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString;
        q.ExecSQL;
      end;
      // 1.ter Cleanup de movimientos AC huerfanos en la misma
      // empresa+almacen. Si la sesion se materializo varias veces sin
      // revertir o si versiones anteriores no limpiaban bien, quedan
      // movimientos cuyo albaran ya no existe en fza_albaranes_compra
      // (el albaran se borro en el paso 0j de esta o de una reversion
      // previa). Sin albaran que los respalde, son residuos.
      // Buscar huerfanos y borrarlos uno a uno via SP para mantener
      // los acumuladores sincronizados (DELETE masivo los dejaria atrás)
      var qHuerf := TUniQuery.Create(nil);
      try
        qHuerf.Connection := q.Connection;
        qHuerf.SQL.Text :=
          'SELECT MOV.NUMERO_MOV ' +
          '  FROM fza_movimientos_almacen MOV ' +
          '  LEFT JOIN fza_albaranes_compra ALBC ' +
          '         ON ALBC.SERIE_ALBC  = MOV.SERIE_DOC_MOV ' +
          '        AND ALBC.NUMERO_ALBC = MOV.NUMERO_DOC_MOV ' +
          ' WHERE MOV.TIPO_DOC_MOV   = ''AC'' ' +
          '   AND MOV.CODIGO_EMP_MOV = :emp ' +
          '   AND MOV.CODIGO_ALM_MOV = :alm ' +
          '   AND ALBC.NUMERO_ALBC IS NULL';
        qHuerf.ParamByName('emp').AsString :=
                          ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
        qHuerf.ParamByName('alm').AsString :=
                          ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
        qHuerf.Open;
        while not qHuerf.Eof do
        begin
          q.SQL.Text := 'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE(:m)';
          q.ParamByName('m').AsString :=
            qHuerf.FieldByName('NUMERO_MOV').AsString;
          q.ExecSQL;
          qHuerf.Next;
        end;
      finally
        FreeAndNil(qHuerf);
      end;

      // 1b. Borrar las filas de pendiente de recibir y los pedidos de
      //     compra generados por esta sesion. La fuente de verdad es
      //     fza_compras_sesiones_documentos (TIPO_DOC_SESDOC='PEDC')
      //     que lleva una fila por (sesion, almacen) con la SERIE y
      //     NUMERO del pedido realmente generado — mas robusto que
      //     deducirlo de la cabecera de sesion porque en modo "un doc
      //     por almacen" cada iteracion genero su propio numero.
      //     try/except porque hay BBDD que aun no tienen las tablas
      //     creadas (migraciones pendientes) y no debe bloquear la
      //     reversion del resto.
      try
        // 1b.1 Cantidades pendientes de recibir
        q.SQL.Text :=
          'DELETE PDR FROM fza_articulos_pdte_recibir PDR ' +
          '  JOIN fza_compras_sesiones_documentos D ' +
          '    ON D.SERIE_SESDOC  = PDR.SERIE_DOC_PDR ' +
          '   AND D.NUMERO_SESDOC = PDR.NUMERO_DOC_PDR ' +
          ' WHERE D.SERIE_SES_SESDOC  = :s ' +
          '   AND D.NUMERO_SES_SESDOC = :n ' +
          '   AND D.TIPO_DOC_SESDOC   = ''PEDC''';
        q.ParamByName('s').AsString := sSerieSes;
        q.ParamByName('n').AsString := sNumSes;
        q.ExecSQL;
      except
        // tabla pdte_recibir o sesiones_documentos puede no existir.
      end;
      // 1b.2 Lineas del pedido de compra
      try
        q.SQL.Text :=
          'DELETE PEDL FROM fza_pedidos_compra_lineas PEDL ' +
          '  JOIN fza_compras_sesiones_documentos D ' +
          '    ON D.SERIE_SESDOC  = PEDL.SERIE_PEDC_PEDCLIN ' +
          '   AND D.NUMERO_SESDOC = PEDL.NUMERO_PEDC_PEDCLIN ' +
          ' WHERE D.SERIE_SES_SESDOC  = :s ' +
          '   AND D.NUMERO_SES_SESDOC = :n ' +
          '   AND D.TIPO_DOC_SESDOC   = ''PEDC''';
        q.ParamByName('s').AsString := sSerieSes;
        q.ParamByName('n').AsString := sNumSes;
        q.ExecSQL;
      except
        // tabla fza_pedidos_compra_lineas puede no existir.
      end;
      // 1b.3 Cabeceras del pedido de compra
      try
        q.SQL.Text :=
          'DELETE PED FROM fza_pedidos_compra PED ' +
          '  JOIN fza_compras_sesiones_documentos D ' +
          '    ON D.SERIE_SESDOC  = PED.SERIE_PEDC ' +
          '   AND D.NUMERO_SESDOC = PED.NUMERO_PEDC ' +
          ' WHERE D.SERIE_SES_SESDOC  = :s ' +
          '   AND D.NUMERO_SES_SESDOC = :n ' +
          '   AND D.TIPO_DOC_SESDOC   = ''PEDC''';
        q.ParamByName('s').AsString := sSerieSes;
        q.ParamByName('n').AsString := sNumSes;
        q.ExecSQL;
      except
        // tabla fza_pedidos_compra puede no existir.
      end;
      // 1b.4 Fallback: tambien borramos por la ruta antigua (NUMERO_DOC_PDR
      // = sNumSes) por compatibilidad con sesiones materializadas antes de
      // este cambio, que usaban sNumSes como numero de pedido y no creaban
      // las cabeceras en fza_pedidos_compra.
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
