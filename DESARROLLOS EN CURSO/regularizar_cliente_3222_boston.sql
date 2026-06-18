-- ============================================================================
--  regularizar_cliente_3222_boston.sql
--  Regulariza la deuda actual del cliente 3222 en la BBDD boston.
--  --------------------------------------------------------------------------
--  Motivo:
--  El saldo real por operaciones de caja DE-CB es 610,00, pero la cuenta F2
--  mostraba 1.242,60 por prestamos pendientes migrados con saldo inflado.
--  No crea cobros ni toca fza_caja_operaciones: solo ajusta anticipos
--  historicos en fza_depositos_cliente y recalcula TOTAL_DEUDA_CLI.
--  Idempotente: fija estados/importes finales por ID_DEPOSITO_DEP.
-- ============================================================================
USE boston;
START TRANSACTION;
SET @codigo_cliente := '3222';
SET @usuario_regulariza := 'REGULARIZA_3222';
SELECT 'ANTES' AS momento,
       ROUND(c.TOTAL_DEUDA_CLI, 2) AS deuda_ficha,
       ROUND(SUM(CASE
                   WHEN d.ESTADO_DEP = 'PENDIENTE'
                    AND d.CANTIDAD_PENDIENTE_DEP > 0
                   THEN (d.PRECIO_VENTA_DEP * COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1))
                        - d.IMPORTE_ANTICIPO_DEP
                   ELSE 0
                 END), 2) AS deuda_pendiente_depositos
  FROM fza_clientes c
  LEFT JOIN fza_depositos_cliente d
    ON d.CODIGO_CLI_DEP = c.CODIGO_CLI_CLI
 WHERE c.CODIGO_CLI_CLI = @codigo_cliente
 GROUP BY c.CODIGO_CLI_CLI,
          c.TOTAL_DEUDA_CLI;
UPDATE fza_depositos_cliente
   SET IMPORTE_ANTICIPO_DEP = PRECIO_VENTA_DEP,
       ESTADO_DEP = 'CERRADO',
       INSTANTE_MODIF = NOW(),
       USUARIO_MODIF = @usuario_regulariza
 WHERE CODIGO_CLI_DEP = @codigo_cliente
   AND ID_DEPOSITO_DEP IN (
       'DM3-3-1-258228-1',
       'DM3-3-1-258234-1',
       'DM3-3-1-258236-1',
       'DM3-3-1-258238-1',
       'DM3-3-1-258241-1',
       'DM3-3-1-258257-1',
       'DM3-3-1-258268-1',
       'DM3-3-1-258274-1')
   AND ESTADO_DEP = 'PENDIENTE'
   AND CANTIDAD_PENDIENTE_DEP > 0
   AND IMPORTE_ANTICIPO_DEP < PRECIO_VENTA_DEP;
UPDATE fza_depositos_cliente
   SET IMPORTE_ANTICIPO_DEP = 15.40,
       ESTADO_DEP = 'PENDIENTE',
       INSTANTE_MODIF = NOW(),
       USUARIO_MODIF = @usuario_regulariza
 WHERE CODIGO_CLI_DEP = @codigo_cliente
   AND ID_DEPOSITO_DEP = 'DM3-3-1-258276-1'
   AND ESTADO_DEP = 'PENDIENTE'
   AND CANTIDAD_PENDIENTE_DEP > 0
   AND IMPORTE_ANTICIPO_DEP < 15.40;
UPDATE fza_depositos_cliente
   SET ESTADO_DEP = 'CERRADO',
       INSTANTE_MODIF = NOW(),
       USUARIO_MODIF = @usuario_regulariza
 WHERE CODIGO_CLI_DEP = @codigo_cliente
   AND ID_DEPOSITO_DEP = 'DM3-3-1-252275-2'
   AND ESTADO_DEP = 'PENDIENTE'
   AND PRECIO_VENTA_DEP = 0
   AND IMPORTE_ANTICIPO_DEP = 0;
UPDATE fza_clientes c
  LEFT JOIN (
    SELECT CODIGO_CLI_DEP,
           SUM((PRECIO_VENTA_DEP * COALESCE(CANTIDAD_PENDIENTE_DEP, 1))
               - IMPORTE_ANTICIPO_DEP) AS deuda
      FROM fza_depositos_cliente
     WHERE CODIGO_CLI_DEP = @codigo_cliente
       AND ESTADO_DEP = 'PENDIENTE'
       AND CANTIDAD_PENDIENTE_DEP > 0
     GROUP BY CODIGO_CLI_DEP
  ) d
    ON d.CODIGO_CLI_DEP = c.CODIGO_CLI_CLI
   SET c.TOTAL_DEUDA_CLI = COALESCE(d.deuda, 0),
       c.INSTANTE_MODIF = NOW(),
       c.USUARIO_MODIF = @usuario_regulariza
 WHERE c.CODIGO_CLI_CLI = @codigo_cliente;
SELECT 'DESPUES' AS momento,
       ROUND(c.TOTAL_DEUDA_CLI, 2) AS deuda_ficha,
       ROUND(SUM(CASE
                   WHEN d.ESTADO_DEP = 'PENDIENTE'
                    AND d.CANTIDAD_PENDIENTE_DEP > 0
                   THEN (d.PRECIO_VENTA_DEP * COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1))
                        - d.IMPORTE_ANTICIPO_DEP
                   ELSE 0
                 END), 2) AS deuda_pendiente_depositos
  FROM fza_clientes c
  LEFT JOIN fza_depositos_cliente d
    ON d.CODIGO_CLI_DEP = c.CODIGO_CLI_CLI
 WHERE c.CODIGO_CLI_CLI = @codigo_cliente
 GROUP BY c.CODIGO_CLI_CLI,
          c.TOTAL_DEUDA_CLI;
SELECT ID_DEPOSITO_DEP,
       CODIGO_UNIDAD_DEP,
       ESTADO_DEP,
       ROUND(PRECIO_VENTA_DEP, 2) AS precio,
       ROUND(IMPORTE_ANTICIPO_DEP, 2) AS anticipo,
       ROUND((PRECIO_VENTA_DEP * COALESCE(CANTIDAD_PENDIENTE_DEP, 1))
             - IMPORTE_ANTICIPO_DEP, 2) AS pendiente
  FROM fza_depositos_cliente
 WHERE CODIGO_CLI_DEP = @codigo_cliente
   AND ESTADO_DEP = 'PENDIENTE'
 ORDER BY FECHA_CREACION_DEP,
          ID_DEPOSITO_DEP;
COMMIT;
