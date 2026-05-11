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
         c. Generar EAN13 con GenerarEAN13Local (usa CalcularDigitoEAN13) e INSERT en
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
  inLibComprasSesiones;

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
      'SELECT IFNULL(MAX(CAST(SUBSTRING(CODIGO_BARRAS_CB, :pl + 1, :lq) AS UNSIGNED)), 0) + 1 AS N ' +
      '  FROM fza_codigos_barras ' +
      ' WHERE CODIGO_BARRAS_CB LIKE :pat ' +
      '   AND TIPO_CODIGO_CB = ''EAN13''';
    q.ParamByName('pl').AsInteger  := Length(sPref);
    q.ParamByName('lq').AsInteger  := iLenSeq;
    q.ParamByName('pat').AsString  := sPref + '%';
    q.Open;
    iNext := q.FieldByName('N').AsLargeInt;
  finally
    q.Free;
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
      'SELECT COALESCE(L.CODIGO_ART_REUSAR_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN), ' +
      '       ''S'', L.TIPO_ART_SESLIN, L.DESCRIPCION_SESLIN, ' +
      '       COALESCE(L.CODIGO_FAM_SESLIN, S.CODIGO_FAM_SES), ' +
      '       COALESCE(L.TIPO_IVA_SESLIN, S.TIPO_IVA_SES), ' +
      '       L.TIPO_CANTIDAD_SESLIN, ' +
      '       CASE WHEN L.TIPO_LINEA_SESLIN = ''MATRIZ'' THEN ''S'' ELSE ''N'' END, ' +
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
    q.Free;
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
    q.Free;
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
    q.Free;
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

    qC.SQL.Text :=
      'SELECT C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, C.CANTIDAD_SESCEL, ' +
      '       AVP.VALOR_AV AS VAL_PIVOT, ' +
      '       (SELECT GROUP_CONCAT(AV2.VALOR_AV SEPARATOR ''/'') ' +
      '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
      '          JOIN fza_atributos_valores AV2 ON AV2.ID_AV = FA.ID_AV_SESFILAT ' +
      '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
      '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
      '           AND FA.LINEA_SES_SESFILAT  = C.LINEA_SES_SESCEL ' +
      '           AND FA.ID_FILA_SESFILAT    = C.ID_FILA_SES_SESCEL) AS VAL_FILA, ' +
      '       (SELECT MIN(FA.ID_AV_SESFILAT) ' +
      '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
      '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
      '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
      '           AND FA.LINEA_SES_SESFILAT  = C.LINEA_SES_SESCEL ' +
      '           AND FA.ID_FILA_SESFILAT    = C.ID_FILA_SES_SESCEL) AS ID_AV_FILA ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  JOIN fza_atributos_valores AVP ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL = :s AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.LINEA_SES_SESCEL = :l AND C.CANTIDAD_SESCEL > 0';
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
    qC.Free;
    qIns.Free;
    qBar.Free;
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
    q.Free;
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
  conn      : TUniConnection;
  sSerieSes, sNumSes, sPrefijoEAN: string;
  sCodigoPrv: string;
  qLin      : TUniQuery;
  sError    : string;
  sCodigoArt: string;
  iLin      : Integer;
  rPrecio   : Double;
  bTxOwned  : Boolean;
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
  sSerieSes   := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumSes     := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sCodigoPrv  := ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
  sPrefijoEAN := ADM.unqryTablaG.FieldByName('PREFIJO_EAN_SES').AsString;

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
          sCodigoArt := qLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
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

        InsertarPropiedadesFijas(conn, sSerieSes, sNumSes, sCodigoArt, AUsuario);

        if qLin.FieldByName('TIPO_LINEA_SESLIN').AsString <> 'SERVICIO' then
          UpsertArticuloProveedor(conn, sCodigoArt, sCodigoPrv,
            qLin.FieldByName('REF_PRV_SESLIN').AsString,
            AUsuario, rPrecio);

        qLin.Next;
      end;
    finally
      qLin.Free;
    end;

    // Documentos resultantes
    if AESGeneraPedido then
    begin
      // TODO: insertar cabecera y líneas en fza_pedidos_compra.
      //   ASeriePed := 'PEC';
      //   ANumPed   := ProximoContador('PEDCOMPRA');
    end;
    if AESGeneraAlbaran then
    begin
      // TODO: insertar cabecera, líneas y fza_movimientos_almacen.
      //   ASerieAlb := 'ALC';
      //   ANumAlb   := ProximoContador('ALBCOMPRA');
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
      qLin.Free;
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
          qLin.Free;
        end;
      except
        // tragado: si esto también falla, no hay nada que hacer
      end;
    end;
  end;
end;

end.
