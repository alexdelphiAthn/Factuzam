# Albarán de compra en depósito (check informativo)

## Objetivo

Poder marcar un **albarán de compra** como mercancía en **depósito**
mediante un check en la cabecera, y verlo como columna en el listado.
Es puramente **informativo**: no cambia stock, ni facturación, ni la
máquina de estados del albarán. Por defecto un albarán **no** es
depósito.

## Esquema

- `albaran_compra_deposito.sql` (idempotente):
  - `ESDEPOSITO_ALBC varchar(1) NOT NULL DEFAULT 'N'` en
    `fza_albaranes_compra`, tras `CODIGO_TAR_ALBC`. Booleano `'S'`/`'N'`
    con prefijo `ES` según `LIBRO_DE_ESTILO_BBDD.md`.
  - Recrea `vi_albaranes_compra` (definida con `a.*`; MariaDB congela la
    lista de columnas al crear la vista, igual que en
    `albc_pivote_tarifa.sql`).

## Pantalla

`src/Forms/inMtoAlbaranesCompra` (+ `.dfm`):

- **Cabecera**: `chkESDEPOSITO_ALBC` (`TcxDBCheckBox`, caption
  «Depósito») junto a «Almacén destino», enlazado a `ESDEPOSITO_ALBC`
  con `ValueChecked='S'` / `ValueUnchecked='N'`.
- **Listado** (`tsLista`): columna «Depósito» con
  `TcxCheckBoxProperties` tras «Total líquido». El grid del listado es
  de solo lectura (`OptionsData.Editing=False` en `TfrmMtoGen`), por lo
  que ahí solo se visualiza.

`src/DataModules/UniDataAlbaranesCompra.pas`:

- `unqryTablaGAfterInsert` fuerza `'N'` en alta (con `FindField` para
  tolerar BBDD sin la migración aplicada, mismo patrón que
  `ESTADO_ALBC`).

## Cómo aplicar

1. Ejecutar `albaran_compra_deposito.sql` sobre cada BBDD existente
   (después de `albaranes_compra.sql` y `albc_pivote_tarifa.sql`, que
   crean la tabla y `CODIGO_TAR_ALBC`).
2. Desplegar el binario con los cambios del Mto.

## Rollback

- `ALTER TABLE fza_albaranes_compra DROP COLUMN ESDEPOSITO_ALBC;` y
  re-ejecutar el `CREATE OR REPLACE VIEW vi_albaranes_compra` del
  script para refrescar la vista.
