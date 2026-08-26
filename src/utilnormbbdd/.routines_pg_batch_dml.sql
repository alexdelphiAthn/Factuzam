-- ============================================================================
-- Factuzam: rutinas PostgreSQL, fase 2 (lote DML)
-- Origen: las definiciones MariaDB de factuzam_original.sql.
--
-- Las rutinas no abren ni cierran transacciones. Toda la llamada participa en
-- la transaccion del llamador. Los EXIT HANDLER ... RESIGNAL del origen se
-- expresan mediante bloques EXCEPTION de PL/pgSQL, que revierten su subbloque
-- antes de propagar el error.
--
-- Los SELECT escalares de salida se exponen como parametros OUT. Por ejemplo:
--   CALL prc_realizar_traspaso(..., NULL);
-- ============================================================================

SET check_function_bodies = on;
SET search_path = public;

-- --------------------------------------------------------------------------
-- Dependencias de inventario y almacen
-- --------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS prc_fza_movimientos_almacen_insert(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, numeric, numeric, numeric, varchar, varchar, varchar,
  varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_movimientos_almacen_insert(
  IN p_numero_mov varchar(20),
  IN p_tipo_doc_mov varchar(20),
  IN p_serie_doc_mov varchar(20),
  IN p_nro_doc_mov varchar(20),
  IN p_linea_mov varchar(10),
  IN p_codigo_empresa_mov varchar(20),
  IN p_codigo_almacen_mov varchar(10),
  IN p_codigo_almacen_contra_mov varchar(10),
  IN p_codigo_unidad_mov varchar(50),
  IN p_tipo_movimiento_mov varchar(1),
  IN p_cantidad_mov numeric(19,6),
  IN p_precio_medio_mov numeric(19,6),
  IN p_total_coste_mov numeric(19,6),
  IN p_usuario varchar(100),
  IN p_almacen_doc varchar(10),
  IN p_numop_doc varchar(20),
  IN p_codigo_caja_doc_mov varchar(10),
  IN p_codcliente varchar(20),
  IN p_codarticulo varchar(20)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_pmp_actual numeric(19,6) := 0;
  v_precio_final numeric(19,6);
  v_coste_final numeric(19,6);
BEGIN
  SELECT COALESCE(
           (
             SELECT stk.precio_medio_stk
               FROM fza_articulos_stockactual AS stk
              WHERE stk.codigo_almacen_stk = p_codigo_almacen_mov
                AND stk.codigo_unidad_stk = p_codigo_unidad_mov
              LIMIT 1
           ),
           0
         )
    INTO v_pmp_actual;

  IF p_tipo_movimiento_mov = 'S' THEN
    v_precio_final := v_pmp_actual;
    v_coste_final := p_cantidad_mov * v_pmp_actual;
  ELSE
    v_precio_final := p_precio_medio_mov;
    v_coste_final := p_total_coste_mov;
  END IF;

  INSERT INTO fza_movimientos_almacen (
    numero_mov,
    tipo_doc_mov, serie_doc_mov, nro_doc_mov, linea_mov,
    codigo_empresa_mov, codigo_almacen_mov, codigo_almacen_contra_mov,
    codigo_unidad_mov, tipo_movimiento_mov, cantidad_mov,
    precio_medio_mov, total_coste_mov,
    fecha_mov, usuarioalta, usuariomodif,
    codigo_almacen_doc_mov, numero_operacion_doc_mov, codigo_caja_doc_mov,
    codigo_cliente_mov, codigo_articulo_mov
  ) VALUES (
    p_numero_mov,
    p_tipo_doc_mov, p_serie_doc_mov, p_nro_doc_mov, p_linea_mov,
    p_codigo_empresa_mov, p_codigo_almacen_mov, p_codigo_almacen_contra_mov,
    p_codigo_unidad_mov, p_tipo_movimiento_mov, p_cantidad_mov,
    v_precio_final, v_coste_final,
    statement_timestamp(), p_usuario, p_usuario,
    p_almacen_doc, p_numop_doc, p_codigo_caja_doc_mov,
    p_codcliente, p_codarticulo
  );

  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk,
    cantidad_stk, valor_total_stk, precio_medio_stk, instantemodif
  ) VALUES (
    p_codigo_almacen_mov,
    p_codigo_unidad_mov,
    CASE WHEN p_tipo_movimiento_mov = 'E'
         THEN p_cantidad_mov ELSE -p_cantidad_mov END,
    CASE WHEN p_tipo_movimiento_mov = 'E'
         THEN v_coste_final ELSE -v_coste_final END,
    v_precio_final,
    statement_timestamp()
  )
  ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
  DO UPDATE SET
    cantidad_stk = fza_articulos_stockactual.cantidad_stk
                   + EXCLUDED.cantidad_stk,
    valor_total_stk = fza_articulos_stockactual.valor_total_stk
                      + EXCLUDED.valor_total_stk,
    precio_medio_stk = CASE
      WHEN fza_articulos_stockactual.cantidad_stk + EXCLUDED.cantidad_stk > 0
      THEN (fza_articulos_stockactual.valor_total_stk
            + EXCLUDED.valor_total_stk)
           / (fza_articulos_stockactual.cantidad_stk
              + EXCLUDED.cantidad_stk)
      ELSE 0
    END,
    instantemodif = statement_timestamp();
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_inventarios_actualizar_teorico(
  varchar, varchar, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_inventarios_actualizar_teorico(
  IN p_empresa varchar(10),
  IN p_almacen varchar(10),
  IN p_serie varchar(20),
  IN p_nro varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_estado varchar(20);
  v_fecha_cabecera timestamp without time zone;
  v_linea record;
  v_fecha_recuento timestamp without time zone;
  v_stock_hist numeric(19,6);
  v_pmp_hist numeric(19,6);
  v_dif_cantidad numeric(19,6);
  v_pmp_nuevo numeric(19,6);
  v_total_coste_dif numeric(19,6);
BEGIN
  SELECT i.estado_inventario, i.fecha_inventario
    INTO v_estado, v_fecha_cabecera
    FROM fza_inventarios AS i
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro
   FOR UPDATE;

  IF v_estado <> 'ABIERTO' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: El inventario no está ABIERTO, no se puede recalcular.';
  END IF;

  FOR v_linea IN
    SELECT l.linea_inventario_linea,
           l.codigo_unidad_inventario_linea,
           l.cantidad_fisica_inventario_linea,
           l.precio_medio_nuevo_inventario_linea,
           l.fecha_recuento_inventario_linea
      FROM fza_inventarios_lineas AS l
     WHERE l.codigo_empresa_inventario_linea = p_empresa
       AND l.codigo_almacen_inventario_linea = p_almacen
       AND l.serie_inventario_linea = p_serie
       AND l.nro_inventario_linea = p_nro
  LOOP
    v_fecha_recuento := COALESCE(
      v_linea.fecha_recuento_inventario_linea,
      v_fecha_cabecera
    );

    SELECT COALESCE(
             SUM(
               CASE WHEN m.tipo_movimiento_mov = 'E'
                    THEN m.cantidad_mov ELSE -m.cantidad_mov END
             ),
             0
           )
      INTO v_stock_hist
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_almacen_mov = p_almacen
       AND m.codigo_unidad_mov = v_linea.codigo_unidad_inventario_linea
       AND m.fecha_mov <= v_fecha_recuento
       AND m.esactivo_mov = 'S';

    SELECT COALESCE(
             (
               SELECT m.precio_medio_mov
                 FROM fza_movimientos_almacen AS m
                WHERE m.codigo_almacen_mov = p_almacen
                  AND m.codigo_unidad_mov = v_linea.codigo_unidad_inventario_linea
                  AND m.fecha_mov <= v_fecha_recuento
                  AND m.esactivo_mov = 'S'
                ORDER BY m.fecha_mov DESC, m.numero_mov DESC
                LIMIT 1
             ),
             0
           )
      INTO v_pmp_hist;

    v_dif_cantidad := v_linea.cantidad_fisica_inventario_linea
                      - v_stock_hist;
    v_pmp_nuevo := v_linea.precio_medio_nuevo_inventario_linea;
    IF v_pmp_nuevo = 0 OR v_pmp_nuevo IS NULL THEN
      v_pmp_nuevo := v_pmp_hist;
    END IF;

    v_total_coste_dif :=
      (v_linea.cantidad_fisica_inventario_linea * v_pmp_nuevo)
      - (v_stock_hist * v_pmp_hist);

    UPDATE fza_inventarios_lineas AS l
       SET cantidad_teorica_inventario_linea = v_stock_hist,
           precio_medio_inventario_linea = v_pmp_hist,
           precio_medio_nuevo_inventario_linea = v_pmp_nuevo,
           cantidad_diferencia_inventario_linea = v_dif_cantidad,
           total_coste_diferencia_linea = v_total_coste_dif,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE l.codigo_empresa_inventario_linea = p_empresa
       AND l.codigo_almacen_inventario_linea = p_almacen
       AND l.serie_inventario_linea = p_serie
       AND l.nro_inventario_linea = p_nro
       AND l.linea_inventario_linea = v_linea.linea_inventario_linea;
  END LOOP;

  UPDATE fza_inventarios AS i
     SET total_unidades_diferencia_inventario = (
           SELECT COALESCE(SUM(l.cantidad_diferencia_inventario_linea), 0)
             FROM fza_inventarios_lineas AS l
            WHERE l.codigo_empresa_inventario_linea = p_empresa
              AND l.codigo_almacen_inventario_linea = p_almacen
              AND l.serie_inventario_linea = p_serie
              AND l.nro_inventario_linea = p_nro
         ),
         total_euros_diferencia_inventario = (
           SELECT COALESCE(SUM(l.total_coste_diferencia_linea), 0)
             FROM fza_inventarios_lineas AS l
            WHERE l.codigo_empresa_inventario_linea = p_empresa
              AND l.codigo_almacen_inventario_linea = p_almacen
              AND l.serie_inventario_linea = p_serie
              AND l.nro_inventario_linea = p_nro
         ),
         usuariomodif = p_usuario,
         instantemodif = statement_timestamp()
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_inventarios_aplicar(
  varchar, varchar, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_inventarios_aplicar(
  IN p_empresa varchar(10),
  IN p_almacen varchar(10),
  IN p_serie varchar(20),
  IN p_nro varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_estado varchar(20);
  v_linea record;
  v_mov_salida varchar(20);
  v_mov_entrada varchar(20);
BEGIN
  SELECT i.estado_inventario
    INTO v_estado
    FROM fza_inventarios AS i
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro
   FOR UPDATE;

  IF v_estado <> 'ABIERTO' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: El inventario ya fue aplicado o está cancelado.';
  END IF;

  FOR v_linea IN
    SELECT l.linea_inventario_linea,
           l.codigo_articulo_inventario_linea,
           l.codigo_unidad_inventario_linea,
           l.cantidad_teorica_inventario_linea,
           l.cantidad_fisica_inventario_linea,
           l.precio_medio_nuevo_inventario_linea,
           COALESCE(l.fecha_recuento_inventario_linea,
                    i.fecha_inventario) AS fecha_recuento
      FROM fza_inventarios_lineas AS l
      JOIN fza_inventarios AS i
        ON i.codigo_empresa_inventario = l.codigo_empresa_inventario_linea
       AND i.codigo_almacen_inventario = l.codigo_almacen_inventario_linea
       AND i.serie_inventario = l.serie_inventario_linea
       AND i.nro_inventario = l.nro_inventario_linea
     WHERE l.codigo_empresa_inventario_linea = p_empresa
       AND l.codigo_almacen_inventario_linea = p_almacen
       AND l.serie_inventario_linea = p_serie
       AND l.nro_inventario_linea = p_nro
  LOOP
    v_mov_salida := left(
      'IV-' || p_nro || '-' || v_linea.linea_inventario_linea || 'S',
      20
    );
    v_mov_entrada := left(
      'IV-' || p_nro || '-' || v_linea.linea_inventario_linea || 'E',
      20
    );

    IF v_linea.cantidad_teorica_inventario_linea > 0 THEN
      CALL prc_fza_movimientos_almacen_insert(
        v_mov_salida, 'IN', p_serie, p_nro,
        v_linea.linea_inventario_linea,
        p_empresa, p_almacen, NULL,
        v_linea.codigo_unidad_inventario_linea,
        'S', v_linea.cantidad_teorica_inventario_linea,
        0, 0, p_usuario, p_almacen, NULL, NULL, NULL,
        v_linea.codigo_articulo_inventario_linea
      );

      UPDATE fza_movimientos_almacen AS m
         SET fecha_mov = v_linea.fecha_recuento
       WHERE m.numero_mov = v_mov_salida;
    ELSIF v_linea.cantidad_teorica_inventario_linea < 0 THEN
      CALL prc_fza_movimientos_almacen_insert(
        v_mov_salida, 'IN', p_serie, p_nro,
        v_linea.linea_inventario_linea,
        p_empresa, p_almacen, NULL,
        v_linea.codigo_unidad_inventario_linea,
        'E', abs(v_linea.cantidad_teorica_inventario_linea),
        0, 0, p_usuario, p_almacen, NULL, NULL, NULL,
        v_linea.codigo_articulo_inventario_linea
      );

      UPDATE fza_movimientos_almacen AS m
         SET fecha_mov = v_linea.fecha_recuento
       WHERE m.numero_mov = v_mov_salida;
    END IF;

    IF v_linea.cantidad_fisica_inventario_linea > 0 THEN
      CALL prc_fza_movimientos_almacen_insert(
        v_mov_entrada, 'IN', p_serie, p_nro,
        v_linea.linea_inventario_linea,
        p_empresa, p_almacen, NULL,
        v_linea.codigo_unidad_inventario_linea,
        'E', v_linea.cantidad_fisica_inventario_linea,
        v_linea.precio_medio_nuevo_inventario_linea,
        v_linea.cantidad_fisica_inventario_linea
          * v_linea.precio_medio_nuevo_inventario_linea,
        p_usuario, p_almacen, NULL, NULL, NULL,
        v_linea.codigo_articulo_inventario_linea
      );

      UPDATE fza_movimientos_almacen AS m
         SET fecha_mov = v_linea.fecha_recuento
       WHERE m.numero_mov = v_mov_entrada;
    END IF;

    -- La fuente tiene dos llamadas de aridad 2. El contrato real es
    -- (empresa, sku, almacen); se corrige de forma deliberada.
    CALL sp_recalcular_pmp_sku_almacen(
      p_empresa,
      v_linea.codigo_unidad_inventario_linea,
      p_almacen
    );
  END LOOP;

  UPDATE fza_inventarios AS i
     SET estado_inventario = 'APLICADO',
         usuariomodif = p_usuario,
         instantemodif = statement_timestamp()
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_inventarios_eliminar_regul(
  varchar, varchar, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_inventarios_eliminar_regul(
  IN p_empresa varchar(10),
  IN p_almacen varchar(10),
  IN p_serie varchar(20),
  IN p_nro varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_estado varchar(20);
  v_patron varchar(50);
  v_sku varchar(50);
BEGIN
  SELECT i.estado_inventario
    INTO v_estado
    FROM fza_inventarios AS i
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro
   FOR UPDATE;

  IF v_estado IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: el inventario no existe.';
  END IF;

  IF v_estado <> 'APLICADO' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: el inventario debe estar APLICADO para eliminar la regularización.';
  END IF;

  v_patron := 'IV-' || p_nro || '-%';

  DROP TABLE IF EXISTS pg_temp.tmp_skus_afectados;
  CREATE TEMPORARY TABLE tmp_skus_afectados (
    sku varchar(50) PRIMARY KEY
  ) ON COMMIT DROP;

  INSERT INTO tmp_skus_afectados (sku)
  SELECT DISTINCT m.codigo_unidad_mov
    FROM fza_movimientos_almacen AS m
   WHERE m.codigo_almacen_mov = p_almacen
     AND m.numero_mov LIKE v_patron;

  DELETE FROM fza_movimientos_almacen AS m
   WHERE m.codigo_almacen_mov = p_almacen
     AND m.numero_mov LIKE v_patron;

  FOR v_sku IN
    SELECT t.sku FROM tmp_skus_afectados AS t
  LOOP
    -- Segunda llamada de aridad 2 corregida al contrato real.
    CALL sp_recalcular_pmp_sku_almacen(p_empresa, v_sku, p_almacen);
  END LOOP;

  UPDATE fza_inventarios AS i
     SET estado_inventario = 'ABIERTO',
         usuariomodif = p_usuario,
         instantemodif = statement_timestamp()
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro;

  DROP TABLE IF EXISTS pg_temp.tmp_skus_afectados;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS sp_recalcular_pmp_sku_almacen(varchar, varchar, varchar);
CREATE PROCEDURE sp_recalcular_pmp_sku_almacen(
  IN p_codigo_empresa varchar(20),
  IN p_codigo_sku varchar(50),
  IN p_codigo_almacen varchar(10)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_mov record;
  v_stock_acumulado numeric(19,6) := 0;
  v_valor_acumulado numeric(19,6) := 0;
  v_pmp_actual numeric(19,6) := 0;
BEGIN
  FOR v_mov IN
    SELECT m.tipo_doc_mov, m.serie_doc_mov, m.nro_doc_mov, m.linea_mov,
           m.tipo_movimiento_mov, m.cantidad_mov,
           m.precio_coste_unitario_mov
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_empresa_mov = p_codigo_empresa
       AND m.codigo_unidad_mov = p_codigo_sku
       AND m.codigo_almacen_mov = p_codigo_almacen
     ORDER BY m.fecha_mov ASC
     FOR UPDATE
  LOOP
    IF v_mov.tipo_movimiento_mov = 'E' THEN
      v_stock_acumulado := v_stock_acumulado + v_mov.cantidad_mov;
      v_valor_acumulado := v_valor_acumulado
                           + (v_mov.cantidad_mov
                              * v_mov.precio_coste_unitario_mov);

      IF v_stock_acumulado > 0 THEN
        v_pmp_actual := v_valor_acumulado / v_stock_acumulado;
      ELSE
        v_pmp_actual := v_mov.precio_coste_unitario_mov;
      END IF;
    ELSE
      v_valor_acumulado := v_valor_acumulado
                           - (v_mov.cantidad_mov * v_pmp_actual);
      v_stock_acumulado := v_stock_acumulado - v_mov.cantidad_mov;
    END IF;

    UPDATE fza_movimientos_almacen AS m
       SET precio_medio_mov = v_pmp_actual,
           total_coste_mov = CASE
             WHEN v_mov.tipo_movimiento_mov = 'E'
             THEN v_mov.cantidad_mov * v_mov.precio_coste_unitario_mov
             ELSE v_mov.cantidad_mov * v_pmp_actual
           END
     WHERE m.tipo_doc_mov = v_mov.tipo_doc_mov
       AND m.serie_doc_mov = v_mov.serie_doc_mov
       AND m.nro_doc_mov = v_mov.nro_doc_mov
       AND m.linea_mov = v_mov.linea_mov;
  END LOOP;

  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk, cantidad_stk,
    valor_total_stk, precio_medio_stk, instantemodif
  ) VALUES (
    p_codigo_almacen, p_codigo_sku, v_stock_acumulado,
    v_valor_acumulado, v_pmp_actual, statement_timestamp()
  )
  ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
  DO UPDATE SET
    cantidad_stk = EXCLUDED.cantidad_stk,
    valor_total_stk = EXCLUDED.valor_total_stk,
    precio_medio_stk = EXCLUDED.precio_medio_stk,
    instantemodif = statement_timestamp();
END;
$routine$;

DROP PROCEDURE IF EXISTS sp_recalcular_pmp_sku(varchar, varchar, timestamp without time zone);
CREATE PROCEDURE sp_recalcular_pmp_sku(
  IN p_codigo_empresa varchar(20),
  IN p_codigo_sku varchar(50),
  IN p_fecha_desde timestamp without time zone
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_mov record;
  v_stock_acumulado numeric(19,6) := 0;
  v_pmp_actual numeric(19,6) := 0;
BEGIN
  -- La fuente recibe p_fecha_desde pero recorre deliberadamente todo el kardex.
  FOR v_mov IN
    SELECT m.tipo_doc_mov, m.serie_doc_mov, m.nro_doc_mov, m.linea_mov,
           m.tipo_movimiento_mov, m.cantidad_mov,
           m.precio_coste_unitario_mov, m.fecha_mov
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_empresa_mov = p_codigo_empresa
       AND m.codigo_unidad_mov = p_codigo_sku
     ORDER BY m.fecha_mov ASC, m.instantealta ASC
  LOOP
    IF v_mov.tipo_movimiento_mov = 'E' THEN
      IF v_stock_acumulado <= 0 THEN
        v_pmp_actual := v_mov.precio_coste_unitario_mov;
      ELSE
        v_pmp_actual := (
          (v_stock_acumulado * v_pmp_actual)
          + (v_mov.cantidad_mov * v_mov.precio_coste_unitario_mov)
        ) / (v_stock_acumulado + v_mov.cantidad_mov);
      END IF;
      v_stock_acumulado := v_stock_acumulado + v_mov.cantidad_mov;
    ELSE
      v_stock_acumulado := v_stock_acumulado - v_mov.cantidad_mov;
    END IF;

    UPDATE fza_movimientos_almacen AS m
       SET precio_medio_mov = v_pmp_actual
     WHERE m.tipo_doc_mov = v_mov.tipo_doc_mov
       AND m.serie_doc_mov = v_mov.serie_doc_mov
       AND m.nro_doc_mov = v_mov.nro_doc_mov
       AND m.linea_mov = v_mov.linea_mov;
  END LOOP;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_depositos_insert(
  varchar, varchar, varchar, varchar, varchar, varchar, numeric, numeric,
  numeric, character, numeric, character, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_depositos_insert(
  IN p_id_dep varchar(20),
  IN p_emp varchar(20),
  IN p_alm_dep varchar(10),
  IN p_cli varchar(20),
  IN p_art varchar(50),
  IN p_sku varchar(50),
  IN p_precio numeric(19,6),
  IN p_cantidad numeric(19,6),
  IN p_anticipo numeric(19,6),
  IN p_tipoiva character(1),
  IN p_porciva numeric(19,6),
  IN p_incl character(1),
  IN p_caja varchar(10),
  IN p_numop varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_deuda_nueva numeric(19,6) := 0;
BEGIN
  INSERT INTO fza_depositos_cliente (
    id_deposito_dep, codigo_empresa_dep, codigo_almacen_dep,
    codigo_cliente_dep, codigo_articulo_dep, codigo_unidad_dep,
    estado_dep, precio_venta_dep, cantidad_pendiente_dep,
    importe_anticipo_dep, tipo_iva_dep, porcen_iva_dep, esimp_incl_dep,
    codigo_caja_dep, numero_operacion_dep,
    instantealta, usuarioalta, instantemodif, usuariomodif
  ) VALUES (
    p_id_dep, p_emp, p_alm_dep,
    p_cli, p_art, p_sku,
    'PENDIENTE', p_precio, p_cantidad,
    p_anticipo, p_tipoiva, p_porciva, p_incl,
    p_caja, p_numop,
    statement_timestamp(), p_usuario, statement_timestamp(), p_usuario
  );

  v_deuda_nueva := (p_precio * COALESCE(p_cantidad, 1))
                   - COALESCE(p_anticipo, 0);

  IF v_deuda_nueva > 0 AND p_cli IS NOT NULL THEN
    UPDATE fza_clientes AS c
       SET total_deuda_cliente = COALESCE(c.total_deuda_cliente, 0)
                                 + v_deuda_nueva
     WHERE c.codigo_cliente = p_cli;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_depositos_update(varchar, varchar, varchar, numeric, varchar);
CREATE PROCEDURE prc_fza_depositos_update(
  IN p_sku varchar(50),
  IN p_cli varchar(20),
  IN p_estado varchar(15),
  IN p_inc_anticipo numeric(19,6),
  IN p_usuario varchar(100),
  OUT p_id_deposito varchar(20)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_id_deposito varchar(20);
  v_old_estado varchar(15);
  v_old_precio numeric(19,6);
  v_old_cantidad_pte numeric(19,6);
  v_old_anticipo numeric(19,6);
  v_nuevo_estado varchar(15);
  v_nuevo_anticipo numeric(19,6);
  v_deuda_antigua numeric(19,6) := 0;
  v_deuda_nueva numeric(19,6) := 0;
  v_diferencia numeric(19,6) := 0;
BEGIN
  SELECT d.id_deposito_dep, d.estado_dep, d.precio_venta_dep,
         d.cantidad_pendiente_dep, d.importe_anticipo_dep
    INTO v_id_deposito, v_old_estado, v_old_precio,
         v_old_cantidad_pte, v_old_anticipo
    FROM fza_depositos_cliente AS d
   WHERE d.codigo_cliente_dep = p_cli
     AND d.codigo_unidad_dep = p_sku
     AND d.estado_dep = 'PENDIENTE'
   LIMIT 1
   FOR UPDATE;

  p_id_deposito := v_id_deposito;

  IF v_id_deposito IS NOT NULL THEN
    v_nuevo_anticipo := v_old_anticipo + COALESCE(p_inc_anticipo, 0);
    v_nuevo_estado := COALESCE(p_estado, v_old_estado);

    IF v_old_estado = 'PENDIENTE' THEN
      v_deuda_antigua := (v_old_precio * COALESCE(v_old_cantidad_pte, 1))
                         - v_old_anticipo;
    END IF;

    IF v_nuevo_estado = 'PENDIENTE' THEN
      v_deuda_nueva := (v_old_precio * COALESCE(v_old_cantidad_pte, 1))
                       - v_nuevo_anticipo;
    END IF;

    v_diferencia := v_deuda_nueva - v_deuda_antigua;

    UPDATE fza_depositos_cliente AS d
       SET importe_anticipo_dep = v_nuevo_anticipo,
           estado_dep = v_nuevo_estado,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE d.id_deposito_dep = v_id_deposito;

    IF v_diferencia <> 0 THEN
      UPDATE fza_clientes AS c
         SET total_deuda_cliente = COALESCE(c.total_deuda_cliente, 0)
                                   + v_diferencia
       WHERE c.codigo_cliente = p_cli;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

-- --------------------------------------------------------------------------
-- Altas y actualizaciones maestras
-- --------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS prc_crear_actualizar_articulo_proveedor(
  varchar, varchar, varchar, numeric, varchar
);
CREATE PROCEDURE prc_crear_actualizar_articulo_proveedor(
  IN p_codigo_articulo varchar(20),
  IN p_codigo_proveedor varchar(20),
  IN p_esproveedorprincipal varchar(1),
  IN p_precio_ult_compra numeric(19,6),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  IF trim(p_codigo_proveedor) <> ''
     AND trim(p_codigo_articulo) <> '' THEN
    IF EXISTS (
      SELECT 1
        FROM fza_articulos_proveedores AS ap
       WHERE ap.codigo_proveedor_articulo_proveedor = p_codigo_proveedor
         AND ap.codigo_articulo_articulo_proveedor = p_codigo_articulo
    ) THEN
      UPDATE fza_articulos_proveedores AS ap
         SET precio_ult_compra_articulo_proveedor = p_precio_ult_compra,
             esproveedorprincipal_articulo_proveedor = p_esproveedorprincipal,
             usuariomodif = p_usuario,
             instantemodif = statement_timestamp()
       WHERE ap.codigo_proveedor_articulo_proveedor = p_codigo_proveedor
         AND ap.codigo_articulo_articulo_proveedor = p_codigo_articulo;
    ELSE
      INSERT INTO fza_articulos_proveedores (
        codigo_proveedor_articulo_proveedor,
        codigo_articulo_articulo_proveedor,
        precio_ult_compra_articulo_proveedor,
        esproveedorprincipal_articulo_proveedor,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_proveedor, p_codigo_articulo,
        p_precio_ult_compra, p_esproveedorprincipal,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      );
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_familia(varchar, varchar, varchar);
CREATE PROCEDURE prc_crear_actualizar_familia(
  IN p_codigo_familia varchar(20),
  IN p_nombre_familia varchar(200),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  p_cont bigint;
BEGIN
  IF trim(p_codigo_familia) <> '' THEN
    IF EXISTS (
      SELECT 1
        FROM fza_articulos_familias AS f
       WHERE f.codigo_familia = p_codigo_familia
    ) THEN
      UPDATE fza_articulos_familias AS f
         SET nombre_familia = p_nombre_familia,
             descripcion_familia = p_nombre_familia,
             usuariomodif = p_usuario,
             instantemodif = statement_timestamp()
       WHERE f.codigo_familia = p_codigo_familia;
    ELSE
      CALL prc_fnc_get_next_nro_doc('FO', p_cont);

      INSERT INTO fza_articulos_familias (
        codigo_familia, orden_familia, nombre_familia, descripcion_familia,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_familia, p_cont, p_nombre_familia, p_nombre_familia,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      );
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_proveedor(varchar, varchar, varchar);
CREATE PROCEDURE prc_crear_actualizar_proveedor(
  IN p_codigo_proveedor varchar(20),
  IN p_razonsocial_proveedor varchar(200),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  p_cont bigint;
BEGIN
  IF trim(p_codigo_proveedor) <> '' THEN
    IF EXISTS (
      SELECT 1
        FROM fza_proveedores AS p
       WHERE p.codigo_proveedor = p_codigo_proveedor
    ) THEN
      UPDATE fza_proveedores AS p
         SET razonsocial_proveedor = p_razonsocial_proveedor,
             usuariomodif = p_usuario,
             instantemodif = statement_timestamp()
       WHERE p.codigo_proveedor = p_codigo_proveedor;
    ELSE
      CALL prc_fnc_get_next_nro_doc('PO', p_cont);

      INSERT INTO fza_proveedores (
        codigo_proveedor, orden_proveedor, razonsocial_proveedor,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_proveedor, p_cont, p_razonsocial_proveedor,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      );
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_tarifa(
  varchar, varchar, numeric, numeric, numeric, numeric, varchar
);
CREATE PROCEDURE prc_crear_actualizar_tarifa(
  IN p_codigo_articulo varchar(20),
  IN p_codigo_tarifa varchar(20),
  IN p_preciosalida_tarifa numeric(19,6),
  IN p_preciofinal_tarifa numeric(19,6),
  IN p_precio_dto_tarifa numeric(19,6),
  IN p_porcen_dto_tarifa numeric(19,6),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  pp_preciosalida_tarifa numeric(19,6);
  pp_preciofinal_tarifa numeric(19,6);
  pp_porcen_dto_tarifa numeric(19,6);
  pp_precio_dto_tarifa numeric(19,6);
BEGIN
  IF trim(p_codigo_tarifa) <> '' THEN
    CALL prc_fnc_get_precio_articulo_fecha(
      p_codigo_articulo,
      current_date,
      pp_preciosalida_tarifa,
      pp_preciofinal_tarifa,
      pp_porcen_dto_tarifa,
      pp_precio_dto_tarifa
    );

    IF pp_preciofinal_tarifa IS NOT NULL THEN
      UPDATE fza_articulos_tarifas AS t
         SET preciosalida_tarifa = p_preciosalida_tarifa,
             preciofinal_tarifa = p_preciofinal_tarifa,
             precio_dto_tarifa = p_precio_dto_tarifa,
             porcen_dto_tarifa = p_porcen_dto_tarifa,
             usuariomodif = p_usuario,
             instantemodif = statement_timestamp()
       WHERE t.codigo_articulo_tarifa = p_codigo_articulo
         AND t.codigo_tarifa = p_codigo_tarifa;
    ELSE
      INSERT INTO fza_articulos_tarifas (
        codigo_articulo_tarifa, codigo_tarifa,
        preciosalida_tarifa, preciofinal_tarifa,
        precio_dto_tarifa, porcen_dto_tarifa, fecha_desde_tarifa,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_articulo, p_codigo_tarifa,
        p_preciosalida_tarifa, p_preciofinal_tarifa,
        p_precio_dto_tarifa, p_porcen_dto_tarifa, current_date,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      );
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_articulo(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, numeric, varchar, numeric, numeric, numeric, numeric,
  varchar
);
CREATE PROCEDURE prc_crear_actualizar_articulo(
  IN p_codigo_articulo varchar(20),
  IN p_descripcion_articulo varchar(1000),
  IN p_tipoiva_articulo varchar(2),
  IN p_tipo_cantidad_articulo varchar(20),
  IN p_esactivo_fijo_articulo varchar(1),
  IN p_codigo_familia varchar(20),
  IN p_nombre_familia varchar(200),
  IN p_codigo_proveedor varchar(20),
  IN p_razonsocial_proveedor varchar(200),
  IN p_esproveedorprincipal varchar(1),
  IN p_precio_ult_compra numeric(19,6),
  IN p_codigo_tarifa varchar(20),
  IN p_preciosalida_tarifa numeric(19,6),
  IN p_preciofinal_tarifa numeric(19,6),
  IN p_precio_dto_tarifa numeric(19,6),
  IN p_porcen_dto_tarifa numeric(19,6),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  p_cont bigint;
BEGIN
  IF trim(p_codigo_articulo) <> '' THEN
    IF EXISTS (
      SELECT 1 FROM fza_articulos AS a
       WHERE a.codigo_articulo = p_codigo_articulo
    ) THEN
      UPDATE fza_articulos AS a
         SET descripcion_articulo = p_descripcion_articulo,
             esactivo_fijo_articulo = p_esactivo_fijo_articulo,
             tipoiva_articulo = p_tipoiva_articulo,
             tipo_cantidad_articulo = p_tipo_cantidad_articulo,
             codigo_familia_articulo = p_codigo_familia,
             usuariomodif = p_usuario,
             instantemodif = statement_timestamp()
       WHERE a.codigo_articulo = p_codigo_articulo;
    ELSE
      CALL prc_fnc_get_next_nro_doc('AO', p_cont);

      INSERT INTO fza_articulos (
        codigo_articulo, orden_articulo, descripcion_articulo,
        tipoiva_articulo, tipo_cantidad_articulo,
        codigo_familia_articulo, esactivo_fijo_articulo,
        -- MariaDB no estricto aporta la cadena vacia a esta columna NOT NULL
        -- omitida por la fuente. Se explicita para conservar ese resultado.
        esvariacion_articulo,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_articulo, p_cont, p_descripcion_articulo,
        p_tipoiva_articulo, p_tipo_cantidad_articulo,
        p_codigo_familia, p_esactivo_fijo_articulo,
        '',
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      );
    END IF;

    CALL prc_crear_actualizar_familia(
      p_codigo_familia, p_nombre_familia, p_usuario
    );
    CALL prc_crear_actualizar_proveedor(
      p_codigo_proveedor, p_razonsocial_proveedor, p_usuario
    );
    CALL prc_crear_actualizar_articulo_proveedor(
      p_codigo_articulo, p_codigo_proveedor,
      p_esproveedorprincipal, p_precio_ult_compra, p_usuario
    );
    CALL prc_crear_actualizar_tarifa(
      p_codigo_articulo, p_codigo_tarifa,
      p_preciosalida_tarifa, p_preciofinal_tarifa,
      p_precio_dto_tarifa, p_porcen_dto_tarifa, p_usuario
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_cliente(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, varchar
);
CREATE PROCEDURE prc_crear_actualizar_cliente(
  IN p_codigo_cliente varchar(20),
  IN p_razonsocial_cliente varchar(200),
  IN p_nif_cliente varchar(50),
  IN p_movil_cliente varchar(40),
  IN p_email_cliente varchar(200),
  IN p_direccion1_cliente varchar(200),
  IN p_direccion2_cliente varchar(200),
  IN p_poblacion_cliente varchar(200),
  IN p_provincia_cliente varchar(200),
  IN p_cpostal_cliente varchar(15),
  IN p_cod_pais_cliente varchar(3),
  IN p_pais_cliente varchar(150),
  IN p_esiva_exento_cliente varchar(1),
  IN p_esretenciones_cliente varchar(1),
  IN p_esiva_recargo_cliente varchar(1),
  IN p_esintracomunitario_cliente varchar(1),
  IN p_esregimenespecialagricola_cliente varchar(1),
  IN p_tarifa_articulo_cliente varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  IF EXISTS (
    SELECT 1 FROM fza_clientes AS c
     WHERE c.codigo_cliente = p_codigo_cliente
  ) THEN
    UPDATE fza_clientes AS c
       SET razonsocial_cliente = p_razonsocial_cliente,
           nif_cliente = p_nif_cliente,
           movil_cliente = p_movil_cliente,
           email_cliente = p_email_cliente,
           direccion1_cliente = p_direccion1_cliente,
           direccion2_cliente = p_direccion2_cliente,
           poblacion_cliente = p_poblacion_cliente,
           provincia_cliente = p_provincia_cliente,
           cpostal_cliente = p_cpostal_cliente,
           nombre_pais_cliente = p_pais_cliente,
           codigo_pais_cliente = p_cod_pais_cliente,
           esiva_exento_cliente = p_esiva_exento_cliente,
           esretenciones_cliente = p_esretenciones_cliente,
           esiva_recargo_cliente = p_esiva_recargo_cliente,
           esregimenespecialagricola_cliente = p_esregimenespecialagricola_cliente,
           esintracomunitario_cliente = p_esintracomunitario_cliente,
           tarifa_articulo_cliente = p_tarifa_articulo_cliente,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE c.codigo_cliente = p_codigo_cliente;
  ELSE
    INSERT INTO fza_clientes (
      codigo_cliente, razonsocial_cliente, nif_cliente, movil_cliente,
      email_cliente, direccion1_cliente, direccion2_cliente,
      poblacion_cliente, provincia_cliente, cpostal_cliente,
      nombre_pais_cliente, codigo_pais_cliente,
      esiva_exento_cliente, esretenciones_cliente, esiva_recargo_cliente,
      esregimenespecialagricola_cliente, esintracomunitario_cliente,
      tarifa_articulo_cliente,
      usuariomodif, usuarioalta, instantealta, instantemodif
    ) VALUES (
      p_codigo_cliente, p_razonsocial_cliente, p_nif_cliente, p_movil_cliente,
      p_email_cliente, p_direccion1_cliente, p_direccion2_cliente,
      p_poblacion_cliente, p_provincia_cliente, p_cpostal_cliente,
      p_pais_cliente, p_cod_pais_cliente,
      p_esiva_exento_cliente, p_esretenciones_cliente, p_esiva_recargo_cliente,
      p_esregimenespecialagricola_cliente, p_esintracomunitario_cliente,
      p_tarifa_articulo_cliente,
      p_usuario, p_usuario, statement_timestamp(), statement_timestamp()
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_empresa(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar
);
CREATE PROCEDURE prc_crear_actualizar_empresa(
  IN p_codigo_empresa varchar(10),
  IN p_razonsocial_empresa varchar(200),
  IN p_nif_empresa varchar(50),
  IN p_movil_empresa varchar(40),
  IN p_email_empresa varchar(200),
  IN p_direccion1_empresa varchar(200),
  IN p_direccion2_empresa varchar(200),
  IN p_poblacion_empresa varchar(200),
  IN p_provincia_empresa varchar(200),
  IN p_cpostal_empresa varchar(15),
  IN p_pais_empresa varchar(150),
  IN p_codpais_empresa varchar(150),
  IN p_retenciones_empresa varchar(1),
  IN p_iva_recargo_empresa varchar(1),
  IN p_regimenespecialagricola_empresa varchar(1),
  IN p_grupo_zona_iva_empresa varchar(10),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  -- p_iva_recargo_empresa tambien queda sin uso en la fuente MariaDB.
  IF EXISTS (
    SELECT 1 FROM fza_empresas AS e
     WHERE e.codigo_empresa = p_codigo_empresa
  ) THEN
    UPDATE fza_empresas AS e
       SET razonsocial_empresa = p_razonsocial_empresa,
           nif_empresa = p_nif_empresa,
           movil_empresa = p_movil_empresa,
           email_empresa = p_email_empresa,
           direccion1_empresa = p_direccion1_empresa,
           direccion2_empresa = p_direccion2_empresa,
           poblacion_empresa = p_poblacion_empresa,
           provincia_empresa = p_provincia_empresa,
           cpostal_empresa = p_cpostal_empresa,
           nombre_pais_empresa = p_pais_empresa,
           codigo_pais_empresa = p_codpais_empresa,
           esretenciones_empresa = p_retenciones_empresa,
           esregimenespecialagricola_empresa = p_regimenespecialagricola_empresa,
           grupo_zona_iva_empresa = p_grupo_zona_iva_empresa,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE e.codigo_empresa = p_codigo_empresa;
  ELSE
    INSERT INTO fza_empresas (
      codigo_empresa, razonsocial_empresa, nif_empresa, movil_empresa,
      email_empresa, direccion1_empresa, direccion2_empresa,
      poblacion_empresa, provincia_empresa, cpostal_empresa,
      nombre_pais_empresa, codigo_pais_empresa,
      esretenciones_empresa, esregimenespecialagricola_empresa,
      grupo_zona_iva_empresa,
      usuariomodif, usuarioalta, instantealta, instantemodif
    ) VALUES (
      p_codigo_empresa, p_razonsocial_empresa, p_nif_empresa, p_movil_empresa,
      p_email_empresa, p_direccion1_empresa, p_direccion2_empresa,
      p_poblacion_empresa, p_provincia_empresa, p_cpostal_empresa,
      p_pais_empresa, p_codpais_empresa,
      p_retenciones_empresa, p_regimenespecialagricola_empresa,
      p_grupo_zona_iva_empresa,
      p_usuario, p_usuario, statement_timestamp(), statement_timestamp()
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_key(
  varchar, varchar, varchar, varchar, text, varchar
);
CREATE PROCEDURE prc_crear_actualizar_key(
  IN p_usuario varchar(200),
  IN p_key varchar(100),
  IN p_subkey varchar(100),
  IN p_value varchar(200),
  IN p_value_text text,
  IN p_usuario_modif varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  IF EXISTS (
    SELECT 1
      FROM fza_usuarios_perfiles AS up
     WHERE up.usuario_grupo_perfiles = p_usuario
       AND up.key_perfiles = p_key
       AND up.subkey_perfiles = p_subkey
  ) THEN
    UPDATE fza_usuarios_perfiles AS up
       SET value_perfiles = p_value,
           value_text_perfiles = p_value_text,
           usuariomodif = p_usuario_modif
     WHERE up.usuario_grupo_perfiles = p_usuario
       AND up.key_perfiles = p_key
       AND up.subkey_perfiles = p_subkey;
  ELSE
    INSERT INTO fza_usuarios_perfiles (
      usuario_grupo_perfiles, key_perfiles, subkey_perfiles,
      value_perfiles, value_text_perfiles,
      instantealta, usuarioalta, usuariomodif
    ) VALUES (
      p_usuario, p_key, p_subkey, p_value, p_value_text,
      statement_timestamp(), p_usuario_modif, p_usuario_modif
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

-- --------------------------------------------------------------------------
-- Facturacion y operaciones auxiliares
-- --------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS prc_calcular_factura_netos(varchar, varchar);
CREATE PROCEDURE prc_calcular_factura_netos(
  IN p_serie_factura varchar(12),
  IN p_nro_factura varchar(12)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_zonaiva_re varchar(1) := '';
  v_aplica_re_cliente varchar(1) := '';
  v_iva_exento varchar(1) := '';
  v_reg_ag_emp varchar(1) := '';
  v_reg_ag_cli varchar(1) := '';
  v_intracomunitario varchar(1) := '';
  v_aplica_retenciones_cli varchar(1) := '';
  v_aplica_retenciones_emp varchar(1) := '';
  v_porcenren numeric(19,6) := 0;
  v_porcenrer numeric(19,6) := 0;
  v_porcenres numeric(19,6) := 0;
  v_porcenree numeric(19,6) := 0;
  v_sum_basen numeric(19,6) := 0;
  v_sum_baser numeric(19,6) := 0;
  v_sum_bases numeric(19,6) := 0;
  v_sum_basee numeric(19,6) := 0;
  v_tot_n numeric(19,6) := 0;
  v_tot_r numeric(19,6) := 0;
  v_tot_s numeric(19,6) := 0;
  v_tot_e numeric(19,6) := 0;
  v_tot_recn numeric(19,6) := 0;
  v_tot_recr numeric(19,6) := 0;
  v_tot_recs numeric(19,6) := 0;
  v_tot_rece numeric(19,6) := 0;
  v_sum_tot_rec numeric(19,6) := 0;
  v_sum_tot numeric(19,6) := 0;
  v_porcen_n numeric(19,6) := 0;
  v_tot_bases numeric(19,6) := 0;
  v_porcen_r numeric(19,6) := 0;
  v_porcen_s numeric(19,6) := 0;
  v_porcen_e numeric(19,6) := 0;
  v_porcen_ret numeric(19,6) := 0;
  v_grupo_zona_iva varchar(12);
  v_codigo_iva varchar(12);
  v_total_ret numeric(19,6) := 0;
  v_fecha timestamp without time zone;
  v_irpf_imp_incl varchar(1);
  v_venta_act_fij varchar(1);
  v_codigo_empresa varchar(8);
BEGIN
  -- La definicion fuente contiene literalmente dos huecos "resto de la
  -- logica". Se conserva ese comportamiento incompleto: no se inventa el
  -- recorrido ni el calculo de bases/impuestos ausentes.
  SELECT f.porcen_ivan_factura,
         f.porcen_ivar_factura,
         f.porcen_ivas_factura,
         f.porcen_ivae_factura,
         f.porcen_retencion_factura,
         f.esaplica_re_zona_iva_factura,
         f.esiva_recargo_cliente_factura,
         f.esiva_exento_cliente_factura,
         f.esretenciones_cliente_factura,
         f.esretenciones_empresa_factura,
         f.esirpf_imp_incl_zona_iva_factura,
         f.porcen_ren_factura,
         f.porcen_rer_factura,
         f.porcen_res_factura,
         f.porcen_ree_factura,
         f.esregimenespecialagricola_empresa_factura,
         f.esregimenespecialagricola_cliente_factura,
         f.grupo_zona_iva_empresa_factura,
         f.codigo_iva_factura,
         f.esintracomunitario_cliente_factura,
         f.fecha_factura,
         f.codigo_empresa_factura,
         f.esventa_activo_fijo_factura
    INTO v_porcen_n, v_porcen_r, v_porcen_s, v_porcen_e,
         v_porcen_ret, v_zonaiva_re, v_aplica_re_cliente, v_iva_exento,
         v_aplica_retenciones_cli, v_aplica_retenciones_emp,
         v_irpf_imp_incl, v_porcenren, v_porcenrer, v_porcenres,
         v_porcenree, v_reg_ag_emp, v_reg_ag_cli, v_grupo_zona_iva,
         v_codigo_iva, v_intracomunitario, v_fecha, v_codigo_empresa,
         v_venta_act_fij
    FROM fza_facturas AS f
   WHERE f.serie_factura = p_serie_factura
     AND f.nro_factura = p_nro_factura;

  IF v_zonaiva_re = 'S' AND v_aplica_re_cliente = 'S' THEN
    v_tot_recn := v_sum_basen * (1 + v_porcenren / 100) - v_sum_basen;
    v_tot_recr := v_sum_baser * (1 + v_porcenrer / 100) - v_sum_baser;
    v_tot_recs := v_sum_bases * (1 + v_porcenres / 100) - v_sum_bases;
    v_tot_rece := v_sum_basee * (1 + v_porcenree / 100) - v_sum_basee;
    v_sum_tot_rec := v_tot_recn + v_tot_recr + v_tot_recs + v_tot_rece;
  ELSE
    v_tot_recn := 0;
    v_tot_recr := 0;
    v_tot_recs := 0;
    v_tot_rece := 0;
    v_sum_tot_rec := 0;
  END IF;

  UPDATE fza_facturas AS f
     SET total_basei_ivan_factura = v_sum_basen,
         total_basei_ivar_factura = v_sum_baser,
         total_basei_ivas_factura = v_sum_bases,
         total_basei_ivae_factura = v_sum_basee,
         total_ivan_factura = v_tot_n,
         total_ivar_factura = v_tot_r,
         total_ivas_factura = v_tot_s,
         total_ivae_factura = v_tot_e,
         total_ren_factura = v_tot_recn,
         total_rer_factura = v_tot_recr,
         total_res_factura = v_tot_recs,
         total_ree_factura = v_tot_rece,
         total_bases_factura = v_tot_bases,
         total_retencion_factura = v_total_ret,
         total_liquido_factura = v_tot_bases + v_sum_tot
                                 - v_total_ret + v_sum_tot_rec,
         esiva_exento_cliente_factura = v_iva_exento,
         esretenciones_cliente_factura = v_aplica_retenciones_cli,
         esretenciones_empresa_factura = v_aplica_retenciones_emp,
         total_impuestos_factura = v_sum_tot_rec + v_sum_tot,
         grupo_zona_iva_empresa_factura = v_grupo_zona_iva,
         codigo_iva_factura = v_codigo_iva,
         porcen_ivan_factura = v_porcen_n,
         porcen_ivae_factura = v_porcen_e,
         porcen_ivar_factura = v_porcen_r,
         porcen_ivas_factura = v_porcen_s,
         porcen_retencion_factura = v_porcen_ret
   WHERE f.nro_factura = p_nro_factura
     AND f.serie_factura = p_serie_factura;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_test();
CREATE PROCEDURE prc_crear_actualizar_test(OUT p_mensaje text)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_precio_final numeric(19,6);
  v_precio_inicial numeric(19,6);
  v_porcen_dto numeric(19,6);
  v_precio_dto numeric(19,6);
BEGIN
  CALL prc_fnc_get_precio_articulo_fecha(
    'PAÑITOS', current_date,
    v_precio_final, v_precio_inicial, v_porcen_dto, v_precio_dto
  );

  IF v_precio_final IS NULL THEN
    p_mensaje := 'HOLA';
  ELSE
    p_mensaje := 'NO HAY';
  END IF;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_metadatos(varchar);
CREATE PROCEDURE prc_crear_metadatos(IN p_databasename varchar(100))
LANGUAGE plpgsql
AS $routine$
BEGIN
  DROP TABLE IF EXISTS fza_metadatos;
  CREATE TABLE fza_metadatos (
    codigo_metadato integer GENERATED BY DEFAULT AS IDENTITY (START WITH 4),
    nombre_metadato varchar(100) NOT NULL,
    parent_metadato varchar(20) NOT NULL,
    PRIMARY KEY (codigo_metadato)
  );

  INSERT INTO fza_metadatos (parent_metadato, nombre_metadato)
  SELECT '1', t.table_name
    FROM information_schema.tables AS t
   WHERE t.table_schema = p_databasename
     AND t.table_type = 'BASE TABLE';

  INSERT INTO fza_metadatos (parent_metadato, nombre_metadato)
  SELECT '2', t.table_name
    FROM information_schema.tables AS t
   WHERE t.table_schema = p_databasename
     AND t.table_type = 'VIEW';

  INSERT INTO fza_metadatos (parent_metadato, nombre_metadato)
  -- specific_name incorpora el OID en PostgreSQL; routine_name conserva el
  -- nombre que SPECIFIC_NAME representa en el origen MariaDB.
  SELECT '3', r.routine_name
    FROM information_schema.routines AS r
   WHERE r.routine_schema = p_databasename
     AND r.routine_type = 'PROCEDURE';

  INSERT INTO fza_metadatos (
    codigo_metadato, parent_metadato, nombre_metadato
  ) VALUES
    (1, '-1', 'Tablas'),
    (2, '-1', 'Vistas'),
    (3, '-1', 'Procedimientos');
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_recibos_factura(varchar, varchar, varchar);
CREATE PROCEDURE prc_crear_recibos_factura(
  IN p_serie_factura varchar(12),
  IN p_nro_factura varchar(12),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_codigo_formapago varchar(20);
  v_forma_pago_factura varchar(100);
  v_n_plazos integer;
  v_i integer;
  v_dias_entre_plazos integer;
  v_porcen_anticipo numeric(5,2);
  v_codigo_cliente varchar(20);
  v_iban varchar(34);
  v_razonsocial_cliente varchar(200);
  v_direccion1_cliente varchar(200);
  v_poblacion_cliente varchar(200);
  v_poblacion_empresa varchar(200);
  v_provincia_cliente varchar(200);
  v_cpostal_cliente varchar(15);
  v_importe_letra varchar(200);
  v_total_liquido_factura numeric(18,6);
  v_importe_recibo numeric(18,6);
  v_importe_resto numeric(18,6);
  v_importe_anticipo numeric(18,6);
  v_fecha_vencimiento date;
  v_fecha_factura date;
BEGIN
  DELETE FROM fza_recibos AS r
   WHERE r.nro_factura_recibo = p_nro_factura
     AND r.serie_factura_recibo = p_serie_factura;

  SELECT f.forma_pago_factura, f.codigo_cliente_factura,
         f.total_liquido_factura, f.razonsocial_cliente_factura,
         f.direccion1_cliente_factura, f.poblacion_cliente_factura,
         f.provincia_cliente_factura, f.cpostal_cliente_factura,
         f.fecha_factura, f.poblacion_empresa_factura
    INTO v_forma_pago_factura, v_codigo_cliente,
         v_total_liquido_factura, v_razonsocial_cliente,
         v_direccion1_cliente, v_poblacion_cliente,
         v_provincia_cliente, v_cpostal_cliente,
         v_fecha_factura, v_poblacion_empresa
    FROM fza_facturas AS f
   WHERE f.serie_factura = p_serie_factura
     AND f.nro_factura = p_nro_factura;

  SELECT c.iban_cliente
    INTO v_iban
    FROM fza_clientes AS c
   WHERE c.codigo_cliente = v_codigo_cliente;

  IF EXISTS (
    SELECT 1 FROM fza_formas_pago AS fp
     WHERE fp.codigo_formapago = v_forma_pago_factura
  ) THEN
    SELECT fp.codigo_formapago, fp.n_plazos_formapago,
           fp.n_dias_entre_plazos_formapago,
           fp.porcen_anticipo_formapago
      INTO v_codigo_formapago, v_n_plazos,
           v_dias_entre_plazos, v_porcen_anticipo
      FROM fza_formas_pago AS fp
     WHERE fp.codigo_formapago = v_forma_pago_factura;

    IF v_porcen_anticipo = 100 THEN
      CALL prc_get_numeros_a_letras(
        v_total_liquido_factura, v_importe_letra
      );

      INSERT INTO fza_recibos (
        nro_factura_recibo, serie_factura_recibo, nro_plazo_recibo,
        forma_pago_origen_recibo, forma_pago_descripcion_origen_recibo,
        euros_recibo, stado_recibo, fecha_expedicion_recibo,
        fecha_vencimiento_recibo, iban_cliente_recibo, fecha_pago_recibo,
        localidad_expedicion_recibo, codigo_cliente_recibo,
        razonsocial_cliente_recibo, direccion1_cliente_recibo,
        poblacion_cliente_recibo, provincia_cliente_recibo,
        cpostal_cliente_recibo, importe_letra_recibo,
        instantealta, instantemodif, usuarioalta, usuariomodif
      ) VALUES (
        p_nro_factura, p_serie_factura, 1,
        v_codigo_formapago, v_forma_pago_factura,
        v_total_liquido_factura, 'Pagado', v_fecha_factura,
        v_fecha_factura, v_iban, v_fecha_factura,
        v_poblacion_empresa, v_codigo_cliente,
        v_razonsocial_cliente, v_direccion1_cliente,
        v_poblacion_cliente, v_provincia_cliente,
        v_cpostal_cliente, v_importe_letra,
        statement_timestamp(), statement_timestamp(), p_usuario, p_usuario
      );
    ELSIF v_n_plazos >= 1 THEN
      v_i := 1;
      WHILE v_i <= v_n_plazos LOOP
        IF v_i = 1 THEN
          v_fecha_vencimiento := v_fecha_factura + v_dias_entre_plazos;
          v_importe_anticipo := v_total_liquido_factura
                                * (v_porcen_anticipo / 100);
          v_importe_resto := v_total_liquido_factura - v_importe_anticipo;
        END IF;

        IF v_i = 1 AND v_porcen_anticipo > 0 THEN
          v_importe_recibo := v_importe_anticipo;
        ELSIF v_n_plazos > 1 THEN
          v_importe_recibo := v_importe_resto / v_n_plazos;
        ELSE
          v_importe_recibo := v_importe_resto;
        END IF;

        CALL prc_get_numeros_a_letras(v_importe_recibo, v_importe_letra);

        IF v_i <> 1 THEN
          v_fecha_vencimiento := v_fecha_vencimiento + v_dias_entre_plazos;
        END IF;

        INSERT INTO fza_recibos (
          nro_factura_recibo, serie_factura_recibo, nro_plazo_recibo,
          forma_pago_origen_recibo, forma_pago_descripcion_origen_recibo,
          euros_recibo, stado_recibo, fecha_expedicion_recibo,
          fecha_vencimiento_recibo, iban_cliente_recibo, fecha_pago_recibo,
          localidad_expedicion_recibo, codigo_cliente_recibo,
          razonsocial_cliente_recibo, direccion1_cliente_recibo,
          poblacion_cliente_recibo, provincia_cliente_recibo,
          cpostal_cliente_recibo, importe_letra_recibo,
          instantealta, instantemodif, usuarioalta, usuariomodif
        ) VALUES (
          p_nro_factura, p_serie_factura, v_i,
          v_codigo_formapago, v_forma_pago_factura,
          v_importe_recibo, 'Emitido', v_fecha_factura,
          v_fecha_vencimiento, v_iban, NULL,
          v_poblacion_empresa, v_codigo_cliente,
          v_razonsocial_cliente, v_direccion1_cliente,
          v_poblacion_cliente, v_provincia_cliente,
          v_cpostal_cliente, v_importe_letra,
          statement_timestamp(), statement_timestamp(), p_usuario, p_usuario
        );

        v_i := v_i + 1;
      END LOOP;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_traspaso(
  varchar, varchar, varchar, varchar, varchar, numeric
);
CREATE PROCEDURE prc_crear_traspaso(
  IN p_usuario varchar(50),
  IN p_empresa varchar(20),
  IN p_almacen_origen varchar(10),
  IN p_almacen_destino varchar(10),
  IN p_sku varchar(50),
  IN p_cantidad numeric(19,6),
  OUT p_mensaje text
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_serie varchar(20) := 'TRAS';
  v_nro_doc varchar(20);
BEGIN
  v_nro_doc := to_char(statement_timestamp(), 'YYYYMMDDHH24MISS');

  -- La fuente no proporciona NUMERO_MOV, aunque la tabla actual lo exige.
  -- Se conserva la lista de columnas original sin inventar un identificador.
  INSERT INTO fza_movimientos_almacen (
    tipo_doc_mov, serie_doc_mov, nro_doc_mov, linea_mov,
    codigo_empresa_mov, codigo_almacen_mov, codigo_almacen_contra_mov,
    fecha_mov, codigo_unidad_mov, tipo_movimiento_mov, cantidad_mov,
    descripcion_articulo_mov, usuarioalta, usuariomodif
  ) VALUES (
    'TR', v_serie, v_nro_doc, '001',
    p_empresa, p_almacen_origen, p_almacen_destino,
    statement_timestamp(), p_sku, 'S', p_cantidad,
    'Traspaso a ' || p_almacen_destino, p_usuario, p_usuario
  );

  INSERT INTO fza_movimientos_almacen (
    tipo_doc_mov, serie_doc_mov, nro_doc_mov, linea_mov,
    codigo_empresa_mov, codigo_almacen_mov, codigo_almacen_contra_mov,
    fecha_mov, codigo_unidad_mov, tipo_movimiento_mov, cantidad_mov,
    descripcion_articulo_mov, usuarioalta, usuariomodif,
    tipo_doc_ref_mov, serie_doc_ref_mov, nro_doc_ref_mov, linea_ref_mov
  ) VALUES (
    'TR', v_serie, v_nro_doc, '002',
    p_empresa, p_almacen_destino, p_almacen_origen,
    statement_timestamp(), p_sku, 'E', p_cantidad,
    'Traspaso desde ' || p_almacen_origen, p_usuario, p_usuario,
    'TR', v_serie, v_nro_doc, '001'
  );

  p_mensaje := 'Traspaso realizado. Doc: ' || v_serie || '-' || v_nro_doc;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_realizar_traspaso(
  varchar, varchar, varchar, varchar, varchar, numeric
);
CREATE PROCEDURE prc_realizar_traspaso(
  IN p_usuario varchar(50),
  IN p_empresa varchar(20),
  IN p_almacen_origen varchar(10),
  IN p_almacen_destino varchar(10),
  IN p_sku varchar(50),
  IN p_cantidad numeric(19,6),
  OUT p_mensaje text
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_serie varchar(20) := 'TRAS';
  v_nro_doc varchar(20);
BEGIN
  v_nro_doc := to_char(statement_timestamp(), 'YYYYMMDDHH24MISS');

  -- Igual que PRC_CREAR_TRASPASO, la fuente omite NUMERO_MOV.
  INSERT INTO fza_movimientos_almacen (
    tipo_doc_mov, serie_doc_mov, nro_doc_mov, linea_mov,
    codigo_empresa_mov, codigo_almacen_mov, codigo_almacen_contra_mov,
    fecha_mov, codigo_unidad_mov, tipo_movimiento_mov, cantidad_mov,
    descripcion_articulo_mov, usuarioalta, usuariomodif
  ) VALUES (
    'TR', v_serie, v_nro_doc, '001',
    p_empresa, p_almacen_origen, p_almacen_destino,
    statement_timestamp(), p_sku, 'S', p_cantidad,
    'Traspaso a ' || p_almacen_destino, p_usuario, p_usuario
  );

  INSERT INTO fza_movimientos_almacen (
    tipo_doc_mov, serie_doc_mov, nro_doc_mov, linea_mov,
    codigo_empresa_mov, codigo_almacen_mov, codigo_almacen_contra_mov,
    fecha_mov, codigo_unidad_mov, tipo_movimiento_mov, cantidad_mov,
    descripcion_articulo_mov, usuarioalta, usuariomodif,
    tipo_doc_ref_mov, serie_doc_ref_mov, nro_doc_ref_mov, linea_ref_mov
  ) VALUES (
    'TR', v_serie, v_nro_doc, '002',
    p_empresa, p_almacen_destino, p_almacen_origen,
    statement_timestamp(), p_sku, 'E', p_cantidad,
    'Traspaso desde ' || p_almacen_origen, p_usuario, p_usuario,
    'TR', v_serie, v_nro_doc, '001'
  );

  p_mensaje := 'Traspaso realizado. Doc: ' || v_serie || '-' || v_nro_doc;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_recalcular_stock();
CREATE PROCEDURE prc_recalcular_stock(OUT p_mensaje text)
LANGUAGE plpgsql
AS $routine$
BEGIN
  DELETE FROM fza_articulos_stockactual;

  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk, cantidad_stk, instantemodif
  )
  SELECT m.codigo_almacen_mov,
         m.codigo_unidad_mov,
         SUM(CASE WHEN m.tipo_movimiento_mov = 'E'
                  THEN m.cantidad_mov ELSE -m.cantidad_mov END),
         statement_timestamp()
    FROM fza_movimientos_almacen AS m
   GROUP BY m.codigo_almacen_mov, m.codigo_unidad_mov;

  p_mensaje := 'Stock recalculado correctamente.';
EXCEPTION
  WHEN OTHERS THEN
    -- Un bloque EXCEPTION revierte automaticamente el DELETE/INSERT, como el
    -- handler con ROLLBACK del origen, pero mantiene el contrato de mensaje.
    p_mensaje := 'ERROR: No se pudo recalcular el stock';
END;
$routine$;
