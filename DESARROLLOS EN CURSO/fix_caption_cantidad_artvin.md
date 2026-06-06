# Fix caption `CANTIDAD_ARTVIN` -> `Cantidad`

## Origen
El renombrado de columnas (`src/utilnormbbdd/cambios3`) usaba la regla
`CANTIDAD -> CANTIDAD_ARTVIN` para la columna real de `fza_articulos_vinculos`
(la unica tabla con una columna `CANTIDAD` sin sufijo). Esa regla se aplico de
mas sobre el literal `CANTIDAD` y quedo `CANTIDAD_ARTVIN` pegado en captions,
comentarios, variables locales, alias SQL y literales de varios sitios que en
realidad son de otra tabla (lineas de factura -> `FACLIN`, movimientos ->
`MOV`...) o simple texto.

## Que se ha corregido en codigo (rama)
- **Captions de rejilla / memo de informe** (`src/Forms/*.dfm`,
  `src/Modals/inMtoModalImpFac.dfm`): el `Caption` visible pasa a `Cantidad` /
  `Tipo Cantidad`. El `DataBinding.FieldName` ya era correcto y no se toca.
- **Codigo Pascal** (`inMtoCajaOpe.pas`, `UniDataCaja.pas`,
  `UniDataInventarios.pas`, `inLibGenerarTicketBD.pas`, `inLibFacturaExcel.pas`,
  `inLibInventarioExcel.pas`, `inLibGenerarTicket.pas`, `inLibPresta.pas`,
  `pruebas factura-e/*`): se deshace el renombrado erroneo. Identificadores y
  texto visible vuelven a `Cantidad`; alias/literales SQL y comparaciones de
  cabecera (`sHdr`) vuelven a `CANTIDAD` (estado previo a la migracion,
  confirmado en `src/utilnormbbdd/factuzam_original.sql`).

## Que NO se toca
- `factuzam_original.sql` (regla dura nº1). Sus 2 ocurrencias legitimas son la
  columna real `CANTIDAD_ARTVIN` de `fza_articulos_vinculos`.
- `src/utilnormbbdd/UNormalizerEngine.pas`: la *regla*
  `('fza_articulos_vinculos','CANTIDAD','CANTIDAD_ARTVIN')` es correcta; el bug
  fue aplicarla de mas, no la regla.
- `src/utilnormbbdd/cambios3/*`: logs/historico de la migracion.

## Este script (`fix_caption_cantidad_artvin.sql`)
Las rejillas guardan su layout por usuario en `fza_usuarios_perfiles`
(`SUBKEY_USUPER` = `tvXxx_COLUMNA_Caption`, valor en `VALUE_USUPER`). El dump
modelo trae 5 filas con el caption malo, pero cada BBDD de produccion acumula
una copia por usuario/grupo que haya abierto esos formularios. El `UPDATE`
filtra por el valor erroneo, asi que corrige todas las copias de una pasada.
Idempotente.

## Pendiente cosmetico (sin accion)
El SP que declara el cursor `CUR_LINEAS` (en `factuzam_original.sql`) usa
`CANTIDAD_FACLIN as CANTIDAD_ARTVIN`. El alias es **interno** y el `FETCH ...
INTO` es **posicional**, asi que no afecta a la ejecucion. Vive en
`factuzam_original.sql` (no se toca) y se corregira solo cuando el usuario
regenere el dump. No requiere script en produccion.
