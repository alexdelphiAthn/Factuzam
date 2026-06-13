-- Añade la consolidación Verifactu (fza_facturas_consolidaciones) a la
-- vista de impresión de facturas (vi_facturas_print) por LEFT JOIN.
--
-- Objetivo: exponer en la vista el QR tributario ya generado
-- (QRCODE_PNG_FACCON) y el resto de datos de la consolidación, para
-- poder enlazar en el diseñador de FastReport un Picture por DataField
-- (imagen ligada a dato) en lugar de rellenarla por código. Un
-- TfrxPictureView con DataField=QRCODE_PNG_FACCON lo dibuja FastReport
-- de forma nativa (igual que los memos [Facturas."..."]).
--
-- La relación es 1:1: fza_facturas_consolidaciones tiene UNIQUE
-- UK_FACTURA(SERIE_FAC_FACCON, NUMERO_FAC_FACCON), así que el LEFT JOIN
-- no multiplica filas (0 o 1 consolidación por factura).
--
-- Se usa `fza_facturas`.* (en vez de re-listar las columnas): añade de
-- paso TIPO_FAC y FASE_FAC, ya disponibles para el título y la lógica
-- del informe. Los nombres de columna de las otras tablas no colisionan
-- (sufijos _FP / _EMP / _CLI / _FACCON).
--
-- Idempotente: CREATE OR REPLACE VIEW deja siempre la misma definición.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_facturas_print` AS
SELECT `fza_facturas`.*,
       `fza_formas_pago`.`DESCRIPCION_FORMA_PAGO_FP`
              AS `DESCRIPCION_FORMA_PAGO_FP`,
       `fza_formas_pago`.`ESCONTADO_FORMA_PAGO_FP`
              AS `ESCONTADO_FORMA_PAGO_FP`,
       (select group_concat(' ',
                 date_format(`fza_recibos`.`FECHA_VENCIMIENTO_RECIBO_REC`,
                             '%d/%m/%Y'),
                 '=> ',
                 format(`fza_recibos`.`EUROS_RECIBO_REC`, 2),
                 '€' separator ',')
          from `fza_recibos`
         where `fza_recibos`.`NUMERO_FAC_REC` = `fza_facturas`.`NUMERO_FAC`
           and `fza_recibos`.`SERIE_FAC_REC`  = `fza_facturas`.`SERIE_FAC`)
              AS `VENCIMIENTOS_RECIBOS`,
       `fza_empresas`.`IBAN_EMP` AS `IBAN_EMP`,
       `fza_clientes`.`IBAN_CLI` AS `IBAN_CLI`,
       `fza_formas_pago`.`ESVERBANCOEMPRESA_FORMA_PAGO_FP`
              AS `ESVERBANCOEMPRESA_FORMA_PAGO_FP`,
       `c`.`ID_FACCON`                          AS `ID_FACCON`,
       `c`.`REQUEST_ID_CONSOLIDACION_FACCON`    AS `REQUEST_ID_CONSOLIDACION_FACCON`,
       `c`.`ISSUER_IRS_ID_CONSOLIDACION_FACCON` AS `ISSUER_IRS_ID_CONSOLIDACION_FACCON`,
       `c`.`ISSUED_TIME_FACCON`                 AS `ISSUED_TIME_FACCON`,
       `c`.`CHAIN_NUMBER_FACCON`                AS `CHAIN_NUMBER_FACCON`,
       `c`.`CHAIN_HASH_FACCON`                  AS `CHAIN_HASH_FACCON`,
       `c`.`VERIFACTU_URL_FACCON`               AS `VERIFACTU_URL_FACCON`,
       `c`.`QRCODE_BASE64_FACCON`               AS `QRCODE_BASE64_FACCON`,
       `c`.`QRCODE_PNG_FACCON`                  AS `QRCODE_PNG_FACCON`,
       `c`.`FECHA_PROCESAMIENTO_FACCON`         AS `FECHA_PROCESAMIENTO_FACCON`,
       `c`.`ESTADO_FACCON`                      AS `ESTADO_FACCON`
  from ((((`fza_facturas`
       left join `fza_formas_pago`
              on(`fza_facturas`.`FORMA_PAGO_FAC` =
                 `fza_formas_pago`.`CODIGO_FP_FP`))
       left join `fza_empresas`
              on(`fza_facturas`.`CODIGO_EMP_FAC` =
                 `fza_empresas`.`CODIGO_EMP_EMP`))
       left join `fza_clientes`
              on(`fza_facturas`.`CODIGO_CLI_FAC` =
                 `fza_clientes`.`CODIGO_CLI_CLI`))
       left join `fza_facturas_consolidaciones` `c`
              on(`c`.`SERIE_FAC_FACCON`  = `fza_facturas`.`SERIE_FAC`
             and `c`.`NUMERO_FAC_FACCON` = `fza_facturas`.`NUMERO_FAC`))
 order by `fza_facturas`.`FECHA_FAC` desc;
