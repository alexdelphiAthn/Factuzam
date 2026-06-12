-- ============================================================================
-- Arqueo de Caja
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
--
-- Soporta el modal `TfrmModalArqueo` (src/Modals/inMtoModalArqueo.pas)
-- lanzado desde el menú de caja (F11). En este primer paso la pantalla es de
-- solo lectura y no inserta filas; la tabla queda lista para el futuro F5
-- Recuento (cierre Z), que persistirá una fila por arqueo y marcará
-- `CODIGO_ARQUEO_OPCAJA` en `fza_caja_operaciones` (FK lógica ya existente).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- IDEMPOTENCIA
-- ---------------------------------------------------------------------------
-- Re-ejecutable: DROP TABLE IF EXISTS + CREATE TABLE. Sin datos asociados.
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS `fza_caja_arqueos`;
CREATE TABLE `fza_caja_arqueos` (
  `CODIGO_ARQ`                       varchar(30)   NOT NULL
      COMMENT 'ID único del arqueo / cierre Z',
  `CODIGO_EMP_ARQ`                   varchar(10)   NOT NULL,
  `CODIGO_ALM_ARQ`                   varchar(10)   NOT NULL,
  `CODIGO_CAJA_ARQ`                  varchar(10)   NOT NULL
      COMMENT 'Terminal físico (TPV1, TPV2...)',
  `FECHA_DESDE_ARQ`                  date          NOT NULL,
  `FECHA_HASTA_ARQ`                  date          NOT NULL,
  `FASE_ARQ`                         varchar(15)   NOT NULL DEFAULT 'ABIERTO'
      COMMENT 'ABIERTO, CERRADO',
  `CODIGO_EMPLEADO_ARQ`              varchar(20)   NULL DEFAULT NULL,
  `CANTIDAD_VENTAS_ARQ`              int(11)       NOT NULL DEFAULT 0,
  `CANTIDAD_OPERACIONES_ARQ`         int(11)       NOT NULL DEFAULT 0,
  `TOTAL_BRUTO_LINEAS_ARQ`           decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_DESCUENTOS_LINEAS_ARQ`      decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_BRUTO_OPERACIONES_ARQ`      decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_DESCUENTOS_OPERACIONES_ARQ` decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_NETO_ARQ`                   decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'SUM IMPORTE_TOTAL_OPCAJA de VE en el rango (signed)',
  `TOTAL_PRESTAMOS_ARQ`              decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'SUM TIPO=DE en el rango (compromiso bruto)',
  `TOTAL_VENTAS_NORMALES_ARQ`        decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'VE > 0 sin DE en la misma operación',
  `TOTAL_VENTAS_PRESTAMOS_ARQ`       decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT '= TOTAL_PRESTAMOS_ARQ − TOTAL_COBROS_CLIENTES_ARQ',
  `TOTAL_DEVOLUCIONES_ARQ`           decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'ABS de VE < 0 (devoluciones a cliente)',
  `TOTAL_VENTAS_ARQ`                 decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT '= VentasNormales + VentasPrestamos − Devoluciones',
  `TOTAL_VALES_RECOGIDOS_ARQ`        decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_VALES_EMITIDOS_ARQ`         decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_COBROS_CLIENTES_ARQ`        decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_PENDIENTE_COBRO_ARQ`        decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_INGRESOS_CAJA_ARQ`          decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_EFECTIVO_INGRESOS_ARQ`      decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_EFECTIVO_ENTRADAS_ARQ`      decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_EFECTIVO_SALIDAS_ARQ`       decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_EFECTIVO_ANTERIOR_ARQ`      decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_EFECTIVO_CAJA_ARQ`          decimal(19,6) NOT NULL DEFAULT '0.000000',
  `TOTAL_OTROS_INGRESOS_ARQ`         decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'Suma de formas de pago sin cajón (tarjeta, bono, divisa, cripto...)',
  `TOTAL_SALDO_RECONTAR_ARQ`         decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'Saldo teórico efectivo + otros (lo que debe estar en caja + ext.)',
  `OBSERVACIONES_ARQ`                varchar(500)  NULL DEFAULT NULL,
  `INSTANTE_MODIF`                   timestamp     NOT NULL
      DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA`                    timestamp     NOT NULL
      DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`                     varchar(100)  NOT NULL,
  `USUARIO_MODIF`                    varchar(100)  NOT NULL,
  PRIMARY KEY (`CODIGO_ARQ`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

ALTER TABLE `fza_caja_arqueos`
  ADD INDEX `IDX_ARQ_CTX_FECHA`
      (`CODIGO_EMP_ARQ`, `CODIGO_ALM_ARQ`, `CODIGO_CAJA_ARQ`,
       `FECHA_DESDE_ARQ`);
ALTER TABLE `fza_caja_arqueos`
  ADD INDEX `IDX_ARQ_FECHA`
      (`FECHA_DESDE_ARQ`, `FECHA_HASTA_ARQ`);
ALTER TABLE `fza_caja_arqueos`
  ADD INDEX `IDX_ARQ_FASE`
      (`FASE_ARQ`);
