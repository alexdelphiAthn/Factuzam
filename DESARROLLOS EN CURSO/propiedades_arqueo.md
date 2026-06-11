# Propiedades en el arqueo (check "En arqueo" + Temporada)

## Qué

El bloque **"Neto ventas por propiedad"** del arqueo (pestaña Resúmenes y
ticket F11) ya no vuelca todas las propiedades: cada propiedad lleva un
check **`ESARQUEO_PROP`** ("En arqueo") en su mantenimiento, y solo salen las
marcadas. **Opt-in**: por defecto no sale ninguna; `TEMPORADA` se marca de
fábrica (es el caso de uso que lo motiva).

## Esquema

Script idempotente: **`propiedades_arqueo.sql`** (aplicar a las BBDD
existentes; `factuzam_original.sql` no se toca).

- `fza_propiedades` + columna `ESARQUEO_PROP varchar(1) NOT NULL DEFAULT 'N'`.
- `UPDATE` deja `TEMPORADA = 'S'` (idempotente, solo si seguía en `'N'`).

## App

- **`inMtoPropiedades`** (.pas + .dfm): columna de rejilla "En arqueo" y
  check `chkARQUEO` en la ficha, ambos a `ESARQUEO_PROP` (`S`/`N`). El DML de
  `UniDataPropiedades.dfm` (Insert/Update) incluye la columna con
  `IFNULL(:ESARQUEO_PROP,'N')`, igual que `NIVEL_PROP`.
- **Consulta**: `TArqueoCalculadora.SQLResumenPropiedad` (en `inLibArqueo`),
  compartida por la pantalla (`inMtoModalArqueo.qryResProp`) y el ticket
  (`inLibArqueoTicket.EscribirResumenPropiedades`).

## Valor EFECTIVO por SKU (clave con "propiedades por unidad")

Tras `propiedades_por_unidad`, una propiedad (p. ej. TEMPORADA) vive a nivel
**color**, y `fza_articulos_propiedades` tiene varias filas por artículo
(artículo / color / SKU). Un `JOIN` directo **duplicaría** importes. Por eso
la consulta une la línea vendida (`CODIGO_UNIDAD_FACLIN` = SKU) a la vista
**`vi_articulos_propiedades_efectivas`**, que devuelve el valor vigente por
SKU (SKU → COLOR → ARTÍCULO). Así la temporada de color sale en su valor de
color y no se duplica nada.

## Tolerante a migración pendiente

Mientras no se aplique el `.sql`, la consulta referencia una columna que no
existe. Para no romper el arqueo:

- En pantalla, `RefrescarResumenes` abre `qryResProp` dentro de `try/except`
  (si falla, el grid queda vacío y el resto del arqueo funciona).
- En el ticket, `EscribirResumenPropiedades` envuelve su bloque en
  `try/except` (se omite la sección sin abortar el ticket).

Tras aplicar la migración, ambos muestran las propiedades marcadas.
