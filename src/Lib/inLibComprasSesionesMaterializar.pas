unit inLibComprasSesionesMaterializar;

{
  Unidad: inLibComprasSesionesMaterializar
  Materialización transaccional de una sesión de compra.
  Centraliza artículos, SKUs, documentos y su reversión. Cada operación
  conserva una única transacción y deja el error en la sesión.
}

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, DBAccess, Uni,
  UniDataComprasSesiones;

type
  TParametrosMaterializacionSesion = record
    Usuario: string;
    SerieAlbaran: string;
    SeriePedido: string;
    UnDocumentoPorAlmacen: Boolean;
  end;

  TDocumentoMaterializado = record
    Tipo: string;
    Serie: string;
    Numero: string;
    Almacen: string;
  end;

  TDocumentosMaterializados = array of TDocumentoMaterializado;

  TResultadoMaterializacionSesion = record
    SeriePedido: string;
    NumeroPedido: string;
    SerieAlbaran: string;
    NumeroAlbaran: string;
    MensajeError: string;
    Documentos: TDocumentosMaterializados;
  end;

// Sanea un texto de color libre del proveedor para usarlo como segmento del
// CODIGO_UNIDAD_SKU y como valor (AV): mayusculas; espacios -> '-'; solo se
// conservan [A-Z0-9_-], el resto de simbolos se prohibe; sin separadores
// repetidos ni en los extremos. Expuesta para que el grid de compras la
// aplique al confirmar el color (que el usuario vea ya el token real).
function SanearColorSku(const ATexto: string): string;

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

// Caso de uso completo de materializacion. Decide si genera un unico
// documento o uno por almacen y conserva una sola transaccion para todo
// el proceso.
function EjecutarMaterializacionSesion(ADM: TdmComprasSesiones;
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;

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
  inLibLog,
  inLibEAN13,
  inLibComprasSesiones,
  inLibComprasSesionesReglas,
  inLibFotos,
  inLibValoresAutomaticos,
  inLibAlbaranesCompraMovimientos,
  inLibMsg;

// ---------------------------------------------------------------------------
// Soporte de reversion: tablas opcionales y avisos con rastro
// ---------------------------------------------------------------------------
// Antes cada paso de la reversion envolvia su DELETE en un try/except
// vacio "por si la tabla no existe en BBDD legacy". Eso tragaba tambien
// los fallos REALES (permisos, locks, FK) y dejaba la reversion a medias
// sin avisar. Ahora la existencia de tablas se comprueba UNA sola vez y
// un fallo real del DELETE aborta la reversion (rollback + AMsgError).
function TablaExiste(AConn: TUniConnection; const ATabla: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES ' +
      ' WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t';
    q.ParamByName('t').AsString := ATabla;
    q.Open;
    Result := q.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(q);
  end;
end;

// Aviso de paso omitido o degradado: rastro en el log tecnico y en la
// pestania Log de la pantalla de sesiones cuando esta activa.
procedure AvisoPaso(ADM: TdmComprasSesiones; const ATexto: string);
begin
  Log.LogWarning('inLibComprasSesionesMaterializar: ' + ATexto);
  if Assigned(ADM) and Assigned(ADM.ContextoSesion) then
    ADM.ContextoSesion.LogSesion('  AVISO: ' + ATexto);
end;

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
    raise Exception.Create(Format(SErrorPrefijoEanSesionLargo, [sPref]));

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

  // 1. Valor que llevará el SKU: texto del proveedor saneado y, si no hay,
  // el código del básico como compatibilidad.
  sAv := SanearColorSku(AColorTexto);
  if sAv = '' then
    sAv := SanearColorSku(ACodigoAtbColor);

  // Si no hay ningún texto útil para el color, salimos sin hacer nada.
  if sAv = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;

    // 2. Resolver primero el ID del color básico (ID_ATB) si viene informado.
    // Lo hacemos al principio porque nos servirá tanto si creamos el AV
    // como si lo actualizamos.
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

      // El básico es importante: si la línea referencia uno que no existe
      // en la paleta, fallar explícitamente en vez de clasificar mal en silencio.
      if idAtb = 0 then
        raise Exception.CreateFmt(SErrorColorBasicoMaterializacionNoExiste,
                                  [ACodigoAtbColor]);
    end;

    // 3. Comprobar si el color (AV) ya existe (identidad = valor del color).
    q.SQL.Text :=
      'SELECT ID_AV, ID_ATB_AV FROM fza_atributos_valores ' +
      ' WHERE ID_VA_AV = ''CO'' AND AV = :v LIMIT 1';
    q.ParamByName('v').AsString := sAv;
    q.Open;

    if not q.IsEmpty then
    begin
      // 4. El color ya existe: lo reusamos.
      Result := q.FieldByName('ID_AV').AsInteger;
      AValor := sAv;

      // FIX: Si el color existe pero NO tenía color básico asignado,
      // y la línea actual SÍ trae un básico, actualizamos el registro.
      if q.FieldByName('ID_ATB_AV').IsNull and (idAtb > 0) then
      begin
        q.Close;
        q.SQL.Text :=
          'UPDATE fza_atributos_valores ' +
          '   SET ID_ATB_AV = :ia ' +
          ' WHERE ID_AV = :idav';
        q.ParamByName('ia').AsInteger   := idAtb;
        q.ParamByName('idav').AsInteger := Result;
        q.ExecSQL;
      end;
    end
    else
    begin
      // 5. El color no existe: lo creamos.
      q.Close;

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

      // Recuperar el ID recién creado
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

procedure InsertarSkusYBarras(AConn: TUniConnection;
                              const ASerieSes, ANumSes, ACodigoArt,
                                    AUsuario, APrefijoEAN: string;
                              ALinea: Integer;
                              AIdPvTemporada: Integer);
var
  qC, qIns, qBar, qLin: TUniQuery;
  sCodigoSKU : string;
  sPrefColor : string;
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

      // Propagacion de temporada a nivel COLOR (Fase 4): cada color
      // comprado en la sesion recibe la temporada de cabecera en su
      // propio CODIGO_UNIDAD_ARTPROP (= ART/COLOR, los dos primeros
      // segmentos del SKU, igual que la vista efectiva). INSERT IGNORE:
      // no pisa la temporada de un color ya fijado en una sesion previa
      // y convive con la del articulo (InsertarTemporadaCabecera).
      sPrefColor := PrefijoColorSku(sCodigoSKU);
      if (AIdPvTemporada > 0) and (sPrefColor <> '') then
      begin
        qIns.SQL.Text :=
          'INSERT IGNORE INTO fza_articulos_propiedades ' +
          '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP, ' +
          '   ID_PV_ARTPROP, VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, ' +
          '   USUARIO_ALTA) ' +
          'VALUES (:art, ''TEMPORADA'', :uni, :pv, NULL, NOW(), :u)';
        qIns.ParamByName('art').AsString := ACodigoArt;
        qIns.ParamByName('uni').AsString := sPrefColor;
        qIns.ParamByName('pv').AsInteger := AIdPvTemporada;
        qIns.ParamByName('u').AsString   := AUsuario;
        qIns.ExecSQL;
      end;

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
      '   ESIVA_RECARGO_COMPRAS_ALBC, ' +
      '   ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '   CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC, ' +
      '   MOVIL_PRV_ALBC, EMAIL_PRV_ALBC, ' +
      '   DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, ' +
      '   POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC, ' +
      '   CODIGO_POSTAL_PRV_ALBC, ' +
      '   REF_PROVEEDOR_ALBC, FORMA_PAGO_ALBC, ' +
      '   ID_PV_TEMPORADA_ALBC, CODIGO_ALM_ALBC, ' +
      '   TOTAL_BRUTO_ALBC, PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      '   TOTAL_DTO_COMERCIAL_ALBC, PORCENTAJE_DTO_FINANCIERO_ALBC, ' +
      '   TOTAL_DTO_FINANCIERO_ALBC, TOTAL_BASES_ALBC, ' +
      '   TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC, ' +
      '   CONTADOR_LINEAS_ALBC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :nalbc, :salbc, S.FECHA_SES, ''ABIERTO'', ' +
      '       E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
      '       E.MOVIL_EMP, E.EMAIL_EMP, ' +
      '       E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
      '       E.POBLACION_EMP, E.PROVINCIA_EMP, ' +
      '       E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, ' +
      '       E.CODIGO_POSTAL_EMP, ' +
      '       IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
      '              IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')), ' +
      '       IFNULL(S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N''), ' +
      '       P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, P.NIF_PRV, ' +
      '       P.MOVIL_PRV, P.EMAIL_PRV, ' +
      '       P.DIRECCION1_PRV, P.DIRECCION2_PRV, ' +
      '       P.POBLACION_PRV, P.PROVINCIA_PRV, ' +
      '       P.CODIGO_POSTAL_PRV, ' +
      '       S.REF_PRV_SES, NULLIF(S.FORMA_PAGO_SES, ''''), ' +
      '       S.ID_PV_TEMPORADA_SES, ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ELSE S.CODIGO_ALM_SES END, ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0), ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_FINANCIERO_SES, 0), ' +
      '       0, 0, 0, 0, ''0'', ' +
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
      '   CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN, ' +
      '   TIPO_IVA_ARTICULO_ALBCLIN, ' +
      '   PORCENTAJE_IVA_ALBCLIN, ' +
      '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
      '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
      '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
      '   ESFACTURADA_ALBCLIN, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:n, :s, :l, :art, :sku, :refprv, :acpivot, ' +
      '        :fam, :nomfam, :desc, ''Uds'', ' +
      '        :cant, :cant, :tiva, :piva, :pre, :preciva, :tot, :alm, ' +
      '        ''N'', ' +
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
// El INSERT inicial deja esos campos a 0; la sesion aporta el tipo efectivo,
// pero los porcentajes se resuelven desde el IVA de cabecera.
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
      '       C.PORCENTAJE_IVAN_ALBC = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_NORMAL_IVA END, ' +
      '       C.PORCENTAJE_IVAR_ALBC = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_REDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAS_ALBC = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_SUPERREDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAE_ALBC = 0, ' +
      '       C.PORCENTAJE_REN_ALBC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_NORMAL_RE_IVA END, ' +
      '       C.PORCENTAJE_RER_ALBC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_REDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_RES_ALBC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_SUPERREDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_REE_ALBC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_EXENTO_RE_IVA END ' +
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
// por TIPO_IVA_ARTICULO_ALBCLIN. La sesion origen aporta el tipo efectivo,
// pero InsertarLineaAlbaranCompra inserta el porcentaje a 0 y aqui se
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
      '   SET L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' ' +
      '              THEN ''E'' ELSE L.TIPO_IVA_ARTICULO_ALBCLIN END, ' +
      '       L.PORCENTAJE_IVA_ALBCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' ' +
      '              THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_ALBCLIN ' +
      '          WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_ALBC, 0) ' +
      '          WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_ALBC, 0) ' +
      '          WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_ALBC, 0) ' +
      '          WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_ALBC, 0) ' +
      '          ELSE 0 END END, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN = ' +
      '         L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * (1 + ' +
      '           CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' ' +
      '                THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_ALBCLIN ' +
      '            WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_ALBC, 0) ' +
      '            WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_ALBC, 0) ' +
      '            WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_ALBC, 0) ' +
      '            WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_ALBC, 0) ' +
      '            ELSE 0 END END / 100) ' +
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
      '              IFNULL(SUM(L.TOTAL_ALBCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_E, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 END), 0) AS IVA_E, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_N, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_R, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_S, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_E, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_albaranes_compra_lineas L ' +
      '         JOIN fza_albaranes_compra H ' +
      '           ON H.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '          AND H.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
      '         LEFT JOIN fza_ivas V ON V.CODIGO_IVA = H.CODIGO_IVA_ALBC ' +
      '        WHERE L.NUMERO_ALBC_ALBCLIN = :n ' +
      '          AND L.SERIE_ALBC_ALBCLIN  = :s ' +
      '        GROUP BY NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN) AS T ' +
      '    ON T.NUMERO_ALBC_ALBCLIN = C.NUMERO_ALBC ' +
      '   AND T.SERIE_ALBC_ALBCLIN  = C.SERIE_ALBC ' +
      '   SET C.TOTAL_BASEI_IVAN_ALBC = T.BASE_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAR_ALBC = T.BASE_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAS_ALBC = T.BASE_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAE_ALBC = T.BASE_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAN_ALBC = T.IVA_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAR_ALBC = T.IVA_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAS_ALBC = T.IVA_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAE_ALBC = T.IVA_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REN_ALBC = T.RE_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RER_ALBC = T.RE_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RES_ALBC = T.RE_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REE_ALBC = T.RE_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BRUTO_ALBC = T.BASE, ' +
      '       C.TOTAL_DTO_COMERCIAL_ALBC = T.BASE - T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_DTO_FINANCIERO_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
      '       C.TOTAL_BASES_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RETENCION_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100, ' +
      '       C.TOTAL_IMPUESTOS_ALBC = (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_LIQUIDO_ALBC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '+ (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) - T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100 - T.BASE ' +
      '* GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
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
    raise Exception.Create(SErrorAlmacenSesionParaAlbaranCompra);

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
      '    CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '         THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                       NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '         ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '    END AS TIPO_IVA, ' +
      '    L.TIPO_LINEA_SESLIN, ' +
      '    IFNULL(L.REF_PRV_SESLIN, '''') AS REF_PRV ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      '  JOIN fza_compras_sesiones S ' +
      '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
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
      '   ESIVA_RECARGO_COMPRAS_PEDC, ' +
      '   ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' +
      '   CODIGO_PRV_PEDC, RAZON_SOCIAL_PRV_PEDC, NIF_PRV_PEDC, ' +
      '   MOVIL_PRV_PEDC, EMAIL_PRV_PEDC, ' +
      '   DIRECCION1_PRV_PEDC, DIRECCION2_PRV_PEDC, ' +
      '   POBLACION_PRV_PEDC, PROVINCIA_PRV_PEDC, ' +
      '   CODIGO_POSTAL_PRV_PEDC, ' +
      '   REF_PROVEEDOR_PEDC, FORMA_PAGO_PEDC, CODIGO_ALM_PEDC, ' +
      '   ID_PV_TEMPORADA_PEDC, FECHA_TOPE_RECEPCION_PEDC, ' +
      '   TOTAL_BRUTO_PEDC, PORCENTAJE_DTO_COMERCIAL_PEDC, ' +
      '   TOTAL_DTO_COMERCIAL_PEDC, PORCENTAJE_DTO_FINANCIERO_PEDC, ' +
      '   TOTAL_DTO_FINANCIERO_PEDC, TOTAL_BASES_PEDC, ' +
      '   TOTAL_IMPUESTOS_PEDC, TOTAL_LIQUIDO_PEDC, ' +
      '   CONTADOR_LINEAS_PEDC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :npedc, :spedc, S.FECHA_SES, ''ABIERTO'', ' +
      '       E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
      '       E.MOVIL_EMP, E.EMAIL_EMP, ' +
      '       E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
      '       E.POBLACION_EMP, E.PROVINCIA_EMP, ' +
      '       E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, ' +
      '       E.CODIGO_POSTAL_EMP, ' +
      '       IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
      '              IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')), ' +
      '       IFNULL(S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N''), ' +
      '       P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, P.NIF_PRV, ' +
      '       P.MOVIL_PRV, P.EMAIL_PRV, ' +
      '       P.DIRECCION1_PRV, P.DIRECCION2_PRV, ' +
      '       P.POBLACION_PRV, P.PROVINCIA_PRV, ' +
      '       P.CODIGO_POSTAL_PRV, ' +
      '       S.REF_PRV_SES, NULLIF(S.FORMA_PAGO_SES, ''''), ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ELSE S.CODIGO_ALM_SES END, ' +
      '       S.ID_PV_TEMPORADA_SES, S.FECHA_TOPE_RECEPCION_SES, ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0), ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_FINANCIERO_SES, 0), ' +
      '       0, 0, 0, 0, ''0'', ' +
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
    raise Exception.Create(SErrorAlmacenSesionParaPedidoCompra);
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
      '    CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '         THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                       NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '         ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '    END AS TIPO_IVA, ' +
      '    L.TIPO_LINEA_SESLIN, ' +
      '    IFNULL(L.REF_PRV_SESLIN, '''') AS REF_PRV ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      '  JOIN fza_compras_sesiones S ' +
      '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
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
      '       C.PORCENTAJE_IVAN_PEDC = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_NORMAL_IVA END, ' +
      '       C.PORCENTAJE_IVAR_PEDC = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_REDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAS_PEDC = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_SUPERREDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAE_PEDC = 0, ' +
      '       C.PORCENTAJE_REN_PEDC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_NORMAL_RE_IVA END, ' +
      '       C.PORCENTAJE_RER_PEDC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_REDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_RES_PEDC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_SUPERREDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_REE_PEDC  = CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ELSE V.PORCENTAJE_EXENTO_RE_IVA END ' +
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
      '   SET L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' ' +
      '              THEN ''E'' ELSE L.TIPO_IVA_ARTICULO_PEDCLIN END, ' +
      '       L.PORCENTAJE_IVA_PEDCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' ' +
      '              THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_PEDCLIN ' +
      '          WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_PEDC, 0) ' +
      '          WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_PEDC, 0) ' +
      '          WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_PEDC, 0) ' +
      '          WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_PEDC, 0) ' +
      '          ELSE 0 END END, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN = ' +
      '         L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN * (1 + ' +
      '           CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' ' +
      '                THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_PEDCLIN ' +
      '            WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_PEDC, 0) ' +
      '            WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_PEDC, 0) ' +
      '            WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_PEDC, 0) ' +
      '            WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_PEDC, 0) ' +
      '            ELSE 0 END END / 100) ' +
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
      '              IFNULL(SUM(L.TOTAL_PEDCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''N'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''R'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''S'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''E'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_E, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''N'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 END), 0) AS IVA_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''R'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 END), 0) AS IVA_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''S'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 END), 0) AS IVA_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ''E'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 END), 0) AS IVA_E, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_PEDCLIN = ''N'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_N, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_PEDCLIN = ''R'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_R, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_PEDCLIN = ''S'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_S, ' +
      '              IFNULL(SUM(CASE WHEN IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND L.TIPO_IVA_ARTICULO_PEDCLIN = ''E'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) / 100 ELSE 0 END), 0) AS RE_E, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_pedidos_compra_lineas L ' +
      '         JOIN fza_pedidos_compra H ' +
      '           ON H.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '          AND H.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
      '         LEFT JOIN fza_ivas V ON V.CODIGO_IVA = H.CODIGO_IVA_PEDC ' +
      '        WHERE L.NUMERO_PEDC_PEDCLIN = :n ' +
      '          AND L.SERIE_PEDC_PEDCLIN  = :s ' +
      '        GROUP BY NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN) AS T ' +
      '    ON T.NUMERO_PEDC_PEDCLIN = C.NUMERO_PEDC ' +
      '   AND T.SERIE_PEDC_PEDCLIN  = C.SERIE_PEDC ' +
      '   SET C.TOTAL_BASEI_IVAN_PEDC = T.BASE_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAR_PEDC = T.BASE_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAS_PEDC = T.BASE_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAE_PEDC = T.BASE_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAN_PEDC = T.IVA_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAR_PEDC = T.IVA_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAS_PEDC = T.IVA_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAE_PEDC = T.IVA_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_REN_PEDC = T.RE_N * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_RER_PEDC = T.RE_R * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_RES_PEDC = T.RE_S * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_REE_PEDC = T.RE_E * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BRUTO_PEDC = T.BASE, ' +
      '       C.TOTAL_DTO_COMERCIAL_PEDC = T.BASE - T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_DTO_FINANCIERO_PEDC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * IFNULL(C.PORCENTAJE_DTO_FINANCIERO_PEDC, 0) / 100, ' +
      '       C.TOTAL_BASES_PEDC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_RETENCION_PEDC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * IFNULL(C.PORCENTAJE_RETENCION_PEDC, 0) / 100, ' +
      '       C.TOTAL_IMPUESTOS_PEDC = (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_LIQUIDO_PEDC = T.BASE * GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) ' +
      '+ (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) - T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * IFNULL(C.PORCENTAJE_RETENCION_PEDC, 0) / 100 - T.BASE ' +
      '* GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_PEDC, 0) / 100, ' +
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
    raise Exception.Create(SErrorAlmacenSesionParaPendienteRecibir);

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
      '       CASE WHEN IFNULL(S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N'') <> ''S'' ' +
      '             AND IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
      '                        IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')) = ''S'' ' +
      '            THEN L.PRECIO_COMPRA_SESLIN * ' +
      '              (1 + (CASE (CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '                       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                                     NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '                       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
      '                       WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_IVA, 0) ' +
      '                       WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_IVA, 0) ' +
      '                       WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_IVA, 0) ' +
      '                       WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_IVA, 0) ' +
      '                       ELSE 0 END + ' +
      '                     CASE (CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '                       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                                     NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '                       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
      '                       WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
      '                       WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                       WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                       WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
      '                       ELSE 0 END) / 100) ' +
      '            ELSE L.PRECIO_COMPRA_SESLIN END AS PRECIO_COMPRA_SESLIN, ' +
      '       L.TIPO_LINEA_SESLIN, ' +
      '       L.ID_VA_FILA_SESLIN ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.SERIE_SES_SESLIN  = C.SERIE_SES_SESCEL ' +
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
      '   AND L.LINEA_SESLIN      = C.LINEA_SES_SESCEL ' +
      '  JOIN fza_compras_sesiones S ' +
      '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_empresas E ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '  LEFT JOIN vi_ivas_empresa V ' +
      '    ON V.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
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

type
  TDatosMaterializacion = record
    DataModule: TdmComprasSesiones;
    Conexion: TUniConnection;
    SerieSesion: string;
    NumeroSesion: string;
    CodigoProveedor: string;
    PrefijoEan: string;
    CodigoTarifa: string;
    IdPropiedadTemporada: Integer;
    SerieAlbaran: string;
    SeriePedido: string;
  end;

procedure CargarDatosMaterializacion(ADM: TdmComprasSesiones;
                                     const ASerieDocAlb,
                                     ASerieDocPed: string;
                                     out ADatos: TDatosMaterializacion);
begin
  ADatos.DataModule := ADM;
  ADatos.Conexion := ADM.ConexionPrincipal;
  ADatos.SerieSesion :=
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  ADatos.NumeroSesion :=
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  ADatos.CodigoProveedor :=
    ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
  ADatos.PrefijoEan :=
    ADM.unqryTablaG.FieldByName('PREFIJO_EAN_SES').AsString;
  ADatos.CodigoTarifa :=
    ADM.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString;
  ADatos.IdPropiedadTemporada := 0;
  if not ADM.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').IsNull then
    ADatos.IdPropiedadTemporada :=
      ADM.unqryTablaG.FieldByName('ID_PV_TEMPORADA_SES').AsInteger;
  ADatos.SerieAlbaran := Trim(ASerieDocAlb);
  if ADatos.SerieAlbaran = '' then
    ADatos.SerieAlbaran := ADatos.SerieSesion;
  ADatos.SeriePedido := Trim(ASerieDocPed);
  if ADatos.SeriePedido = '' then
    ADatos.SeriePedido := ADatos.SerieSesion;
end;

procedure MaterializarArticulos(const ADatos: TDatosMaterializacion;
                                const AUsuario: string);
var
  qLin: TUniQuery;
  sCodigoArt: string;
  iLin: Integer;
  rPrecio: Double;
  rPrecioVta: Double;
begin
  qLin := TUniQuery.Create(nil);
  try
    qLin.Connection := ADatos.Conexion;
    qLin.SQL.Text :=
      'SELECT L.*, ' +
      '       CASE WHEN ' +
      'IFNULL(S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N'') <> ''S'' ' +
      '             AND IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
      '             IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')) = ''S'' ' +
      '            THEN L.PRECIO_COMPRA_SESLIN * ' +
      '              (1 + (CASE (CASE WHEN ' +
      'IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '                       THEN COALESCE(' +
      'NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                       NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '                       ELSE COALESCE(' +
      'NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
      '                       WHEN ''N'' THEN ' +
      'IFNULL(V.PORCENTAJE_NORMAL_IVA, 0) ' +
      '                       WHEN ''R'' THEN ' +
      'IFNULL(V.PORCENTAJE_REDUCIDO_IVA, 0) ' +
      '                       WHEN ''S'' THEN ' +
      'IFNULL(V.PORCENTAJE_SUPERREDUCIDO_IVA, 0) ' +
      '                       WHEN ''E'' THEN ' +
      'IFNULL(V.PORCENTAJE_EXENTO_IVA, 0) ' +
      '                       ELSE 0 END + ' +
      '                     CASE (CASE WHEN ' +
      'IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '                       THEN COALESCE(' +
      'NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                       NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '                       ELSE COALESCE(' +
      'NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
      '                       WHEN ''N'' THEN ' +
      'IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
      '                       WHEN ''R'' THEN ' +
      'IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                       WHEN ''S'' THEN ' +
      'IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                       WHEN ''E'' THEN ' +
      'IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
      '                       ELSE 0 END) / 100) ' +
      '            ELSE L.PRECIO_COMPRA_SESLIN END ' +
      'AS PRECIO_COSTE_PROVEEDOR ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ' +
      '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_empresas E ' +
      '    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '  LEFT JOIN vi_ivas_empresa V ' +
      '    ON V.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
      ' WHERE L.SERIE_SES_SESLIN = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      ' ORDER BY L.LINEA_SESLIN';
    qLin.ParamByName('s').AsString := ADatos.SerieSesion;
    qLin.ParamByName('n').AsString := ADatos.NumeroSesion;
    qLin.Open;
    while not qLin.Eof do
    begin
      iLin := qLin.FieldByName('LINEA_SESLIN').AsInteger;
      rPrecio := qLin.FieldByName('PRECIO_COSTE_PROVEEDOR').AsFloat;
      if qLin.FieldByName(
        'ACCION_DUPLICADO_SESLIN').AsString = 'REUSAR' then
        sCodigoArt :=
          qLin.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString
      else
      begin
        sCodigoArt :=
          qLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
        InsertarArticulo(ADatos.Conexion, ADatos.DataModule, AUsuario,
          ADatos.SerieSesion, ADatos.NumeroSesion, iLin);
      end;
      if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'MATRIZ' then
      begin
        InsertarConjuntosAtributos(ADatos.Conexion,
          ADatos.SerieSesion, ADatos.NumeroSesion, sCodigoArt,
          AUsuario, iLin);
        InsertarSkusYBarras(ADatos.Conexion, ADatos.SerieSesion,
          ADatos.NumeroSesion, sCodigoArt, AUsuario,
          ADatos.PrefijoEan, iLin, ADatos.IdPropiedadTemporada);
      end;
      InsertarPropiedadesFijas(ADatos.Conexion, ADatos.SerieSesion,
        ADatos.NumeroSesion, sCodigoArt, AUsuario);
      InsertarTemporadaCabecera(ADatos.Conexion, sCodigoArt,
        AUsuario, ADatos.IdPropiedadTemporada);
      if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString <> 'SERVICIO' then
      begin
        UpsertArticuloProveedor(ADatos.Conexion, sCodigoArt,
          ADatos.CodigoProveedor,
          qLin.FieldByName('REF_PRV_SESLIN').AsString,
          AUsuario, rPrecio);
        rPrecioVta :=
          qLin.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
        UpsertArticuloTarifa(ADatos.Conexion, sCodigoArt,
          ADatos.CodigoTarifa, AUsuario, rPrecioVta);
      end;
      inLibFotos.oFotos.MigrarFotosSesion(ADatos.SerieSesion,
        ADatos.NumeroSesion, iLin, sCodigoArt, AUsuario);
      qLin.Next;
    end;
  finally
    FreeAndNil(qLin);
  end;
end;

procedure RegistrarPedidoSesion(const ADatos: TDatosMaterializacion;
                                const ASeriePedido, ANumeroPedido,
                                AFiltroAlmacen, AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADatos.Conexion;
    q.SQL.Text :=
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
    q.ParamByName('s').AsString := ADatos.SerieSesion;
    q.ParamByName('n').AsString := ADatos.NumeroSesion;
    q.ParamByName('alm_ovr').AsString := AFiltroAlmacen;
    q.ParamByName('sd').AsString := ASeriePedido;
    q.ParamByName('nd').AsString := ANumeroPedido;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure MaterializarPedido(const ADatos: TDatosMaterializacion;
                             const AUsuario, AFiltroAlmacen: string;
                             out ASeriePedido,
                             ANumeroPedido: string);
begin
  ANumeroPedido :=
    ObtenerSiguienteContador(ADatos.Conexion, 'PC', AUsuario);
  ASeriePedido := ADatos.SeriePedido;
  InsertarPedidoCompraCabecera(ADatos.Conexion, ADatos.DataModule,
    ASeriePedido, ANumeroPedido, AUsuario, AFiltroAlmacen);
  InsertarLineasPedidoCompra(ADatos.Conexion, ADatos.DataModule,
    ADatos.SerieSesion, ADatos.NumeroSesion, ASeriePedido,
    ANumeroPedido, AUsuario, AFiltroAlmacen);
  AsignarIvaCabeceraPedidoCompra(ADatos.Conexion, ASeriePedido,
    ANumeroPedido);
  RellenarIvaLineasPedidoCompra(ADatos.Conexion, ASeriePedido,
    ANumeroPedido);
  RecalcularTotalesPedidoCompra(ADatos.Conexion, ASeriePedido,
    ANumeroPedido);
  GenerarPedidoPdteRecibir(ADatos.Conexion, ADatos.DataModule,
    ADatos.SerieSesion, ADatos.NumeroSesion, ASeriePedido,
    ANumeroPedido, AUsuario);
  RegistrarPedidoSesion(ADatos, ASeriePedido, ANumeroPedido,
    AFiltroAlmacen, AUsuario);
end;

procedure RegistrarAlbaranSesion(const ADatos: TDatosMaterializacion;
                                 const ASerieAlbaran, ANumeroAlbaran,
                                 AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADatos.Conexion;
    q.SQL.Text :=
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
    q.ParamByName('s').AsString := ADatos.SerieSesion;
    q.ParamByName('n').AsString := ADatos.NumeroSesion;
    q.ParamByName('sd').AsString := ASerieAlbaran;
    q.ParamByName('nd').AsString := ANumeroAlbaran;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure CerrarAlbaranMaterializado(AConexion: TUniConnection;
                                     const ASerieAlbaran,
                                     ANumeroAlbaran,
                                     AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra SET ' +
      '  ESTADO_ALBC    = ''CERRADO'', ' +
      '  INSTANTE_MODIF = NOW(), ' +
      '  USUARIO_MODIF  = :u ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    q.ParamByName('s').AsString := ASerieAlbaran;
    q.ParamByName('n').AsString := ANumeroAlbaran;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure MaterializarAlbaran(const ADatos: TDatosMaterializacion;
                              const AUsuario, AFiltroAlmacen: string;
                              out ASerieAlbaran,
                              ANumeroAlbaran: string);
begin
  ANumeroAlbaran :=
    ObtenerSiguienteContador(ADatos.Conexion, 'AB', AUsuario);
  ASerieAlbaran := ADatos.SerieAlbaran;
  InsertarAlbaranCompraCabecera(ADatos.Conexion, ADatos.DataModule,
    ASerieAlbaran, ANumeroAlbaran, AUsuario, AFiltroAlmacen);
  InsertarLineasAlbaranCompra(ADatos.Conexion, ADatos.DataModule,
    ADatos.SerieSesion, ADatos.NumeroSesion, ASerieAlbaran,
    ANumeroAlbaran, AUsuario, AFiltroAlmacen);
  AsignarIvaCabeceraAlbaranCompra(ADatos.Conexion, ASerieAlbaran,
    ANumeroAlbaran);
  RellenarIvaLineasAlbaranCompra(ADatos.Conexion, ASerieAlbaran,
    ANumeroAlbaran);
  RecalcularTotalesAlbaranCompra(ADatos.Conexion, ASerieAlbaran,
    ANumeroAlbaran);
  inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
    ADatos.Conexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  CerrarAlbaranMaterializado(ADatos.Conexion, ASerieAlbaran,
    ANumeroAlbaran, AUsuario);
  RegistrarAlbaranSesion(ADatos, ASerieAlbaran, ANumeroAlbaran,
    AUsuario);
end;

procedure CerrarSesionMaterializada(const ADatos: TDatosMaterializacion;
                                    const ASeriePedido,
                                    ANumeroPedido,
                                    ASerieAlbaran,
                                    ANumeroAlbaran,
                                    AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADatos.Conexion;
    q.SQL.Text :=
      'UPDATE fza_compras_sesiones SET ' +
      '  ESTADO_SES = ''CERRADA'', ' +
      '  INSTANTE_MATERIALIZA_SES = NOW(), ' +
      '  USUARIO_MATERIALIZA_SES = :u, ' +
      '  SERIE_PEDC_SES = :sp, NUMERO_PEDC_SES = :np, ' +
      '  SERIE_ALBC_SES = :sa, NUMERO_ALBC_SES = :na, ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
      ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
    q.ParamByName('s').AsString := ADatos.SerieSesion;
    q.ParamByName('n').AsString := ADatos.NumeroSesion;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('sp').AsString := ASeriePedido;
    q.ParamByName('np').AsString := ANumeroPedido;
    q.ParamByName('sa').AsString := ASerieAlbaran;
    q.ParamByName('na').AsString := ANumeroAlbaran;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure PersistirErrorMaterializacion(
  const ADatos: TDatosMaterializacion;
  const AUsuario, AMensaje: string);
var
  q: TUniQuery;
begin
  try
    q := TUniQuery.Create(nil);
    try
      q.Connection := ADatos.Conexion;
      q.SQL.Text :=
        'UPDATE fza_compras_sesiones SET MENSAJE_ERROR_SES = :e, ' +
        '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
        ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
      q.ParamByName('e').AsString := Copy(AMensaje, 1, 2000);
      q.ParamByName('u').AsString := AUsuario;
      q.ParamByName('s').AsString := ADatos.SerieSesion;
      q.ParamByName('n').AsString := ADatos.NumeroSesion;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  except
    on E: Exception do
      AvisoPaso(ADatos.DataModule,
        'No se pudo persistir MENSAJE_ERROR_SES: ' + E.Message);
  end;
end;

function MaterializarSesion(ADM: TdmComprasSesiones;
                            AESGeneraPedido, AESGeneraAlbaran: Boolean;
                            const AUsuario: string;
                            const ASerieDocAlb, ASerieDocPed: string;
                            out ASeriePed, ANumPed, ASerieAlb, ANumAlb,
                                AMsgError: string;
                            const AFiltroAlmacen: string = '';
                            ASoloDocumentos: Boolean = False): Boolean;
var
  Datos: TDatosMaterializacion;
  sError: string;
  bTxOwned: Boolean;
begin
  Result := False;
  ASeriePed := '';
  ANumPed := '';
  ASerieAlb := '';
  ANumAlb := '';
  AMsgError := '';
  if inLibComprasSesiones.ValidarSesion(ADM, sError) then
  begin
    CargarDatosMaterializacion(ADM, ASerieDocAlb, ASerieDocPed, Datos);
    bTxOwned := not Datos.Conexion.InTransaction;
    if bTxOwned then
      Datos.Conexion.StartTransaction;
    try
      if not ASoloDocumentos then
        MaterializarArticulos(Datos, AUsuario);
      if AESGeneraPedido then
        MaterializarPedido(Datos, AUsuario, AFiltroAlmacen,
          ASeriePed, ANumPed);
      if AESGeneraAlbaran then
        MaterializarAlbaran(Datos, AUsuario, AFiltroAlmacen,
          ASerieAlb, ANumAlb);
      CerrarSesionMaterializada(Datos, ASeriePed, ANumPed,
        ASerieAlb, ANumAlb, AUsuario);
      if bTxOwned and Datos.Conexion.InTransaction then
        Datos.Conexion.Commit;
      Result := True;
    except
      on E: Exception do
      begin
        if bTxOwned and Datos.Conexion.InTransaction then
          Datos.Conexion.Rollback;
        AMsgError := E.Message;
        PersistirErrorMaterializacion(Datos, AUsuario, E.Message);
      end;
    end;
  end
  else
    AMsgError := sError;
end;

procedure AgregarDocumentoMaterializado(
  var ADocumentos: TDocumentosMaterializados;
  const ATipo, ASerie, ANumero, AAlmacen: string);
var
  iIndice: Integer;
begin
  iIndice := Length(ADocumentos);
  SetLength(ADocumentos, iIndice + 1);
  ADocumentos[iIndice].Tipo := ATipo;
  ADocumentos[iIndice].Serie := ASerie;
  ADocumentos[iIndice].Numero := ANumero;
  ADocumentos[iIndice].Almacen := AAlmacen;
end;

procedure GuardarPrimerDocumento(
  var AResultado: TResultadoMaterializacionSesion;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
        ANumeroAlbaran: string);
begin
  if AResultado.SerieAlbaran = '' then
  begin
    AResultado.SerieAlbaran := ASerieAlbaran;
    AResultado.NumeroAlbaran := ANumeroAlbaran;
  end;
  if AResultado.SeriePedido = '' then
  begin
    AResultado.SeriePedido := ASeriePedido;
    AResultado.NumeroPedido := ANumeroPedido;
  end;
end;

procedure AgregarDocumentosGenerados(
  var AResultado: TResultadoMaterializacionSesion;
  AGeneraPedido, AGeneraAlbaran: Boolean;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
        ANumeroAlbaran, AAlmacen: string);
begin
  if AGeneraAlbaran and (ASerieAlbaran <> '') then
    AgregarDocumentoMaterializado(AResultado.Documentos, 'Albaran',
      ASerieAlbaran, ANumeroAlbaran, AAlmacen);
  if AGeneraPedido and (ASeriePedido <> '') then
    AgregarDocumentoMaterializado(AResultado.Documentos, 'Pedido',
      ASeriePedido, ANumeroPedido, AAlmacen);
end;

function EjecutarMaterializacionSesion(ADM: TdmComprasSesiones;
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
var
  oConexion: TUniConnection;
  oQry: TUniQuery;
  bTxOwned: Boolean;
  bGeneraPedido: Boolean;
  bGeneraAlbaran: Boolean;
  bPrimera: Boolean;
  sAlmacen: string;
  sEmpresa: string;
  sSerieAlbaran: string;
  sSeriePedido: string;
  sSeriePedidoTmp: string;
  sNumeroPedidoTmp: string;
  sSerieAlbaranTmp: string;
  sNumeroAlbaranTmp: string;
begin
  Result := False;
  AResultado.SeriePedido := '';
  AResultado.NumeroPedido := '';
  AResultado.SerieAlbaran := '';
  AResultado.NumeroAlbaran := '';
  AResultado.MensajeError := '';
  AResultado.Documentos := nil;
  bGeneraPedido :=
    ADM.unqryTablaG.FieldByName('ESGENERA_PEDIDO_SES').AsString = 'S';
  bGeneraAlbaran :=
    ADM.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S';
  sEmpresa :=
    ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  oConexion := ADM.ConexionPrincipal;
  bTxOwned := not oConexion.InTransaction;
  if bTxOwned then
    oConexion.StartTransaction;
  try
    if AParametros.UnDocumentoPorAlmacen then
    begin
      oQry := TUniQuery.Create(nil);
      try
        oQry.Connection := oConexion;
        oQry.SQL.Text :=
          'SELECT DISTINCT IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
          '                       :alm_cab) AS ALM ' +
          '  FROM fza_compras_sesiones_celdas C ' +
          ' WHERE C.SERIE_SES_SESCEL = :s ' +
          '   AND C.NUMERO_SES_SESCEL = :n ' +
          '   AND C.CANTIDAD_SESCEL > 0 ' +
          ' ORDER BY ALM';
        oQry.ParamByName('alm_cab').AsString :=
          ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
        oQry.ParamByName('s').AsString :=
          ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
        oQry.ParamByName('n').AsString :=
          ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
        oQry.Open;
        bPrimera := True;
        while not oQry.Eof do
        begin
          sAlmacen := oQry.FieldByName('ALM').AsString;
          sSerieAlbaran := ObtenerSeriePropiaAlmacen(
            oConexion, sEmpresa, 'AB', sAlmacen);
          if sSerieAlbaran = '' then
            sSerieAlbaran := AParametros.SerieAlbaran;
          sSeriePedido := ObtenerSeriePropiaAlmacen(
            oConexion, sEmpresa, 'PC', sAlmacen);
          if sSeriePedido = '' then
            sSeriePedido := AParametros.SeriePedido;
          if not MaterializarSesion(
            ADM, bGeneraPedido, bGeneraAlbaran, AParametros.Usuario,
            sSerieAlbaran, sSeriePedido,
            sSeriePedidoTmp, sNumeroPedidoTmp,
            sSerieAlbaranTmp, sNumeroAlbaranTmp,
            AResultado.MensajeError, sAlmacen, not bPrimera) then
            raise Exception.Create(AResultado.MensajeError);
          bPrimera := False;
          GuardarPrimerDocumento(AResultado,
            sSeriePedidoTmp, sNumeroPedidoTmp,
            sSerieAlbaranTmp, sNumeroAlbaranTmp);
          AgregarDocumentosGenerados(AResultado,
            bGeneraPedido, bGeneraAlbaran,
            sSeriePedidoTmp, sNumeroPedidoTmp,
            sSerieAlbaranTmp, sNumeroAlbaranTmp, sAlmacen);
          oQry.Next;
        end;
      finally
        FreeAndNil(oQry);
      end;
    end
    else
    begin
      if not MaterializarSesion(
        ADM, bGeneraPedido, bGeneraAlbaran, AParametros.Usuario,
        AParametros.SerieAlbaran, AParametros.SeriePedido,
        AResultado.SeriePedido, AResultado.NumeroPedido,
        AResultado.SerieAlbaran, AResultado.NumeroAlbaran,
        AResultado.MensajeError) then
        raise Exception.Create(AResultado.MensajeError);
      sAlmacen :=
        ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
      AgregarDocumentosGenerados(AResultado,
        bGeneraPedido, bGeneraAlbaran,
        AResultado.SeriePedido, AResultado.NumeroPedido,
        AResultado.SerieAlbaran, AResultado.NumeroAlbaran, sAlmacen);
    end;
    if bTxOwned and oConexion.InTransaction then
      oConexion.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      if bTxOwned and oConexion.InTransaction then
        oConexion.Rollback;
      if AResultado.MensajeError = '' then
        AResultado.MensajeError := E.Message;
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Revertir la materializacion
// ---------------------------------------------------------------------------

type
  TTablasReversion = record
    TieneDocumentos: Boolean;
    TienePendienteRecibir: Boolean;
    TienePedidos: Boolean;
    TieneLineasPedido: Boolean;
    TieneAlbaranes: Boolean;
  end;

const
  CSqlBorrarArticulosSesion: array[0..6] of string = (
    'DELETE CB FROM fza_codigos_barras CB ' +
    '  JOIN fza_articulos_skus SK ' +
    '    ON SK.CODIGO_UNIDAD_SKU = CB.CODIGO_UNIDAD_CB ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = SK.CODIGO_ART_SKU ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    'DELETE AS_X FROM fza_atributos_sku AS_X ' +
    '  JOIN fza_articulos_skus SK ' +
    '    ON SK.CODIGO_UNIDAD_SKU = AS_X.CODIGO_UNIDAD_SKU_SA ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = SK.CODIGO_ART_SKU ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    'DELETE SK FROM fza_articulos_skus SK ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = SK.CODIGO_ART_SKU ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    'DELETE ACA FROM fza_articulos_conjuntos_asign ACA ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = ACA.CODIGO_ART_ACA ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    'DELETE T FROM fza_articulos_tarifas T ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = T.CODIGO_ART_ARTTAR ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    'DELETE AP FROM fza_articulos_proveedores AP ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = AP.CODIGO_ART_AP ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    'DELETE P FROM fza_articulos_propiedades P ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = P.CODIGO_ART_ART ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')'
  );

procedure EjecutarSqlSesion(AQuery: TUniQuery; const ASql,
                            ASerieSesion, ANumeroSesion: string);
begin
  AQuery.SQL.Text := ASql;
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.ExecSQL;
end;

procedure ConsultarTablasReversion(AConexion: TUniConnection;
                                   out ATablas: TTablasReversion);
begin
  ATablas.TieneDocumentos :=
    TablaExiste(AConexion, 'fza_compras_sesiones_documentos');
  ATablas.TienePendienteRecibir :=
    TablaExiste(AConexion, 'fza_articulos_pdte_recibir');
  ATablas.TienePedidos :=
    TablaExiste(AConexion, 'fza_pedidos_compra');
  ATablas.TieneLineasPedido :=
    TablaExiste(AConexion, 'fza_pedidos_compra_lineas');
  ATablas.TieneAlbaranes :=
    TablaExiste(AConexion, 'fza_albaranes_compra') and
    TablaExiste(AConexion, 'fza_albaranes_compra_lineas');
end;

function ValidarReversion(ADM: TdmComprasSesiones;
                          out AMsgError: string): Boolean;
begin
  Result := False;
  if ADM = nil then
    AMsgError := SErrorDataModuleSesionNoInicializado
  else if ADM.unqryTablaG.IsEmpty then
    AMsgError := SErrorSesionCompraNoActiva
  else if
    ADM.unqryTablaG.FieldByName('ESTADO_SES').AsString <> 'CERRADA' then
    AMsgError := SErrorSesionNoCerradaParaRevertir
  else
    Result := True;
end;

procedure BorrarArticulosSesion(ADM: TdmComprasSesiones;
                                AQuery: TUniQuery;
                                const ASerieSesion,
                                ANumeroSesion: string);
var
  sSql: string;
begin
  for sSql in CSqlBorrarArticulosSesion do
    EjecutarSqlSesion(AQuery, sSql, ASerieSesion, ANumeroSesion);
  try
    EjecutarSqlSesion(AQuery,
      'DELETE F FROM fza_articulos_fotos F ' +
      '  JOIN fza_compras_sesiones_lineas L ' +
      '    ON L.CODIGO_ART_TENTATIVO_SESLIN = F.CODIGO_ART_FOT ' +
      ' WHERE L.SERIE_SES_SESLIN = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
      ASerieSesion, ANumeroSesion);
  except
    on E: Exception do
      AvisoPaso(ADM, '0h fotos: ' + E.Message);
  end;
  EjecutarSqlSesion(AQuery,
    'DELETE A FROM fza_articulos A ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.CODIGO_ART_TENTATIVO_SESLIN = A.CODIGO_ART_ART ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')',
    ASerieSesion, ANumeroSesion);
end;

procedure BorrarAlbaranSesion(ADM: TdmComprasSesiones;
                              AQuery: TUniQuery;
                              const ASerieAlbaran,
                              ANumeroAlbaran: string;
                              ATieneAlbaranes: Boolean);
begin
  if ANumeroAlbaran <> '' then
  begin
    if ATieneAlbaranes then
    begin
      AQuery.SQL.Text :=
        'DELETE FROM fza_albaranes_compra_lineas ' +
        ' WHERE NUMERO_ALBC_ALBCLIN = :nalb ' +
        '   AND SERIE_ALBC_ALBCLIN = :salb';
      AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
      AQuery.ParamByName('salb').AsString := ASerieAlbaran;
      AQuery.ExecSQL;
      AQuery.SQL.Text :=
        'DELETE FROM fza_albaranes_compra ' +
        ' WHERE NUMERO_ALBC = :nalb AND SERIE_ALBC = :salb';
      AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
      AQuery.ParamByName('salb').AsString := ASerieAlbaran;
      AQuery.ExecSQL;
    end
    else
      AvisoPaso(ADM,
        '0j omitido: fza_albaranes_compra(_lineas) no existe');
  end;
end;

procedure BorrarDocumentosSesion(ADM: TdmComprasSesiones;
                                 AQuery: TUniQuery;
                                 const ASerieSesion,
                                 ANumeroSesion: string;
                                 ATieneDocumentos: Boolean);
begin
  if ATieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE FROM fza_compras_sesiones_documentos ' +
      ' WHERE SERIE_SES_SESDOC = :s ' +
      '   AND NUMERO_SES_SESDOC = :n',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '0j-bis omitido: fza_compras_sesiones_documentos no existe');
end;

procedure BorrarMovimientosAlbaran(AQuery: TUniQuery;
                                   const ASerieAlbaran,
                                   ANumeroAlbaran: string);
begin
  if (ANumeroAlbaran <> '') and (ASerieAlbaran <> '') then
  begin
    AQuery.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :salb, :nalb)';
    AQuery.ParamByName('t').AsString := 'AC';
    AQuery.ParamByName('salb').AsString := ASerieAlbaran;
    AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
    AQuery.ExecSQL;
  end;
end;

procedure BorrarMovimientosHuerfanos(ADM: TdmComprasSesiones;
                                     AQuery: TUniQuery);
var
  qHuerfanos: TUniQuery;
begin
  qHuerfanos := TUniQuery.Create(nil);
  try
    qHuerfanos.Connection := AQuery.Connection;
    qHuerfanos.SQL.Text :=
      'SELECT MOV.NUMERO_MOV ' +
      '  FROM fza_movimientos_almacen MOV ' +
      '  LEFT JOIN fza_albaranes_compra ALBC ' +
      '         ON ALBC.SERIE_ALBC = MOV.SERIE_DOC_MOV ' +
      '        AND ALBC.NUMERO_ALBC = MOV.NUMERO_DOC_MOV ' +
      ' WHERE MOV.TIPO_DOC_MOV = ''AC'' ' +
      '   AND MOV.CODIGO_EMP_MOV = :emp ' +
      '   AND MOV.CODIGO_ALM_MOV = :alm ' +
      '   AND ALBC.NUMERO_ALBC IS NULL';
    qHuerfanos.ParamByName('emp').AsString :=
      ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
    qHuerfanos.ParamByName('alm').AsString :=
      ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
    qHuerfanos.Open;
    while not qHuerfanos.Eof do
    begin
      AQuery.SQL.Text :=
        'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE(:m)';
      AQuery.ParamByName('m').AsString :=
        qHuerfanos.FieldByName('NUMERO_MOV').AsString;
      AQuery.ExecSQL;
      qHuerfanos.Next;
    end;
  finally
    FreeAndNil(qHuerfanos);
  end;
end;

procedure BorrarPedidosSesion(ADM: TdmComprasSesiones;
                              AQuery: TUniQuery;
                              const ASerieSesion,
                              ANumeroSesion,
                              ASeriePedido: string;
                              const ATablas: TTablasReversion);
begin
  if ATablas.TienePendienteRecibir and ATablas.TieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE PDR FROM fza_articulos_pdte_recibir PDR ' +
      '  JOIN fza_compras_sesiones_documentos D ' +
      '    ON D.SERIE_SESDOC = PDR.SERIE_DOC_PDR ' +
      '   AND D.NUMERO_SESDOC = PDR.NUMERO_DOC_PDR ' +
      ' WHERE D.SERIE_SES_SESDOC = :s ' +
      '   AND D.NUMERO_SES_SESDOC = :n ' +
      '   AND D.TIPO_DOC_SESDOC = ''PEDC''',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '1b.1 omitido: falta fza_articulos_pdte_recibir ' +
      'o fza_compras_sesiones_documentos');
  if ATablas.TieneLineasPedido and ATablas.TieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE PEDL FROM fza_pedidos_compra_lineas PEDL ' +
      '  JOIN fza_compras_sesiones_documentos D ' +
      '    ON D.SERIE_SESDOC = PEDL.SERIE_PEDC_PEDCLIN ' +
      '   AND D.NUMERO_SESDOC = PEDL.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE D.SERIE_SES_SESDOC = :s ' +
      '   AND D.NUMERO_SES_SESDOC = :n ' +
      '   AND D.TIPO_DOC_SESDOC = ''PEDC''',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '1b.2 omitido: falta fza_pedidos_compra_lineas ' +
      'o fza_compras_sesiones_documentos');
  if ATablas.TienePedidos and ATablas.TieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE PED FROM fza_pedidos_compra PED ' +
      '  JOIN fza_compras_sesiones_documentos D ' +
      '    ON D.SERIE_SESDOC = PED.SERIE_PEDC ' +
      '   AND D.NUMERO_SESDOC = PED.NUMERO_PEDC ' +
      ' WHERE D.SERIE_SES_SESDOC = :s ' +
      '   AND D.NUMERO_SES_SESDOC = :n ' +
      '   AND D.TIPO_DOC_SESDOC = ''PEDC''',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '1b.3 omitido: falta fza_pedidos_compra ' +
      'o fza_compras_sesiones_documentos');
  if ATablas.TienePendienteRecibir then
  begin
    AQuery.SQL.Text :=
      'DELETE FROM fza_articulos_pdte_recibir ' +
      ' WHERE NUMERO_DOC_PDR = :n ' +
      '   AND (SERIE_DOC_PDR = :ses ' +
      '        OR (:sped <> '''' AND SERIE_DOC_PDR = :sped))';
    AQuery.ParamByName('n').AsString := ANumeroSesion;
    AQuery.ParamByName('ses').AsString := ASerieSesion;
    AQuery.ParamByName('sped').AsString := ASeriePedido;
    AQuery.ExecSQL;
  end
  else
    AvisoPaso(ADM,
      '1b.4 omitido: fza_articulos_pdte_recibir no existe');
end;

procedure ReabrirSesion(AQuery: TUniQuery;
                        const ASerieSesion,
                        ANumeroSesion,
                        AUsuario: string);
begin
  AQuery.SQL.Text :=
    'UPDATE fza_compras_sesiones SET ' +
    '  ESTADO_SES = ''BORRADOR'', ' +
    '  INSTANTE_MATERIALIZA_SES = NULL, ' +
    '  USUARIO_MATERIALIZA_SES = NULL, ' +
    '  SERIE_PEDC_SES = NULL, ' +
    '  NUMERO_PEDC_SES = NULL, ' +
    '  SERIE_ALBC_SES = NULL, ' +
    '  NUMERO_ALBC_SES = NULL, ' +
    '  MENSAJE_ERROR_SES = NULL, ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF = :u ' +
    ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;

function RevertirMaterializacion(ADM: TdmComprasSesiones;
                                  const AUsuario: string;
                                  out AMsgError: string): Boolean;
var
  conn: TUniConnection;
  sSerieSes, sNumSes: string;
  q: TUniQuery;
  bTxOwned: Boolean;
  Tablas: TTablasReversion;
begin
  Result := False;
  AMsgError := '';
  if ValidarReversion(ADM, AMsgError) then
  begin
    conn := ADM.ConexionPrincipal;
    sSerieSes :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    sNumSes :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    ConsultarTablasReversion(conn, Tablas);
    bTxOwned := not conn.InTransaction;
    if bTxOwned then
      conn.StartTransaction;
    try
      q := TUniQuery.Create(nil);
      try
        q.Connection := conn;
        BorrarArticulosSesion(ADM, q, sSerieSes, sNumSes);
        BorrarAlbaranSesion(ADM, q,
          ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString,
          ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString,
          Tablas.TieneAlbaranes);
        BorrarDocumentosSesion(ADM, q, sSerieSes, sNumSes,
          Tablas.TieneDocumentos);
        BorrarMovimientosAlbaran(q,
          ADM.unqryTablaG.FieldByName('SERIE_ALBC_SES').AsString,
          ADM.unqryTablaG.FieldByName('NUMERO_ALBC_SES').AsString);
        BorrarMovimientosHuerfanos(ADM, q);
        BorrarPedidosSesion(ADM, q, sSerieSes, sNumSes,
          ADM.unqryTablaG.FieldByName('SERIE_PEDC_SES').AsString,
          Tablas);
        ReabrirSesion(q, sSerieSes, sNumSes, AUsuario);
      finally
        FreeAndNil(q);
      end;
      if bTxOwned and conn.InTransaction then
        conn.Commit;
      Result := True;
    except
      on E: Exception do
      begin
        if bTxOwned and conn.InTransaction then
          conn.Rollback;
        AMsgError := E.Message;
      end;
    end;
  end;
end;

end.
