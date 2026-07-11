# Migración de fotos legacy (ocartcol → fza_articulos_fotos)

Dominio `fotos` del Factuzam Migrator (`src/utilmigsqlsrv/inLibMigFotos.pas`).
Importa las fotos por color del ERP legacy al sistema de fotos de Factuzam
descrito en `fotos_articulos.md` / `fotos_nube_descarga.md`.

## Origen

`dbo.ocartcol` (un registro por artículo + color). La columna
`ArchivoFoto` guarda la ruta **sin la carpeta raíz**, p.ej.:

```
\temp.34\85san francisco\3834.jpg
\temp.34\41 aire\lino amarillo.jpg
```

La raíz real (normalmente `C:\fotos`) no está en la BBDD: se indica en el
campo **"Raíz fotos legacy"** del migrador. Ruta final =
`<raíz>` + `<ArchivoFoto>`. Si alguna fila trae ya ruta absoluta
(`C:\...` o UNC `\\servidor\...`) se respeta tal cual.

## Destino

Campo **"Destino fotos (appDirFotos)"** del migrador, por defecto
`$(PUBLICO)\Factuzam\fotos` (el mismo default del parámetro `appDirFotos`
del exe principal). Los tokens `$(...)` se expanden con `inLibPathTokens`
antes de lanzar la migración. Debe apuntar a la MISMA carpeta que use el
Factuzam destino, o copiarse allí después.

Por cada foto se generan los tres PNG del esquema estándar:

```
<destino>\300\<nombre>.png    lado mayor 300 px
<destino>\600\<nombre>.png    lado mayor 600 px
<destino>\real\<nombre>.png   resolución original re-encodificada a PNG
```

(redimensionado GDI+ bicúbico de alta calidad, mismo pipeline que
`inLibFotos.Guardar`).

## Fila en fza_articulos_fotos

| Columna | Valor |
|---|---|
| `CODIGO_ART_FOT` | `Articulo` |
| `CODIGO_UNIDAD_FOT` | `ARTICULO/COLORSLOT` |
| `NOMBRE_FOT_FOT` | `saneado(ARTICULO/COLORSLOT)_001` (p.ej. `01011346_61_001`) |
| `EXTENSION_ORIGEN_FOT` | extensión real del fichero legacy (`jpg`...) |
| auditoría | usuario del migrador (`MIGRADOR`) + Now |

`COLORSLOT` se calcula con **exactamente el mismo CASE** que el mapper de
SKUs (`inLibMigArticulosSkus`): código legacy del color si viene relleno
(caso normal: `61`, `1`, `750`...); descripción del básico vía `occolor`
si no; `'0'` en último caso. Así `CODIGO_UNIDAD_FOT` es un **prefijo
exacto** del `CODIGO_UNIDAD_SKU` migrado (`ARTICULO/COLOR/TALLA`) y el
resolutor del exe (`inLibFotos.Resolver` + `GenerarPrefijosSku`) encuentra
la foto para cualquier talla de ese color. Es la misma clave por color que
usan las fotos descargadas del servidor de fotos_nube.

## Comportamiento

- **Idempotente**: si la pareja (`CODIGO_ART_FOT`, `CODIGO_UNIDAD_FOT`) ya
  existe en destino, se salta sin tocar ficheros ni fila.
- **Fichero origen inexistente**: la fila se cuenta como saltada y queda
  un aviso `- SALTO` en el log con la ruta que se buscó.
- **Imagen corrupta / formato sin codec**: error contabilizado y log
  `! ERROR`; la migración continúa con la siguiente foto.
- **Fotos grandes / memoria**: el original decodificado se vuelca UNA
  sola vez a un bitmap base del que salen los tres PNG y se libera
  antes de encodificar (las fotos de móvil de 12+ MP en varios hilos a
  la vez agotaban el espacio de direcciones del exe de 32 bits: errores
  "out of resources" en el log). Si aun así una conversión falla por
  falta de memoria o de recursos GDI, se reintenta una vez **en serie**
  (un solo hilo convirtiendo) antes de contarla como error. Las fotos
  que aun así fallen no se insertan, así que otra corrida las reintenta.
- **Fotos compartidas**: en el legacy es frecuente que varios colores de
  un artículo apunten al mismo fichero. Las claves se **agrupan por
  fichero**: el primer éxito del grupo genera el trío PNG y el resto lo
  copia en vez de re-decodificar la imagen (cada color conserva su
  propio juego de ficheros, como exige el esquema: un nombre por fila).
- **Formatos soportados**: png, jpg/jpeg, gif, bmp; cualquier otro se
  intenta vía WIC (tiff, webp... si el codec está instalado en Windows).
- **Hilo independiente + pool**: el dominio NO entra en las waves del
  migrador; se lanza en un hilo propio al arrancar la corrida y avanza
  en paralelo a toda la migración de datos (las FKs del destino son
  lógicas, no hace falta que existan los artículos antes). Dentro, la
  conversión (decodificar + 3 PNG) se reparte entre los hilos del pool
  del campo **"Hilos fotos"** (2-5 recomendado, tope 8). Los hilos del
  pool solo tocan ficheros y encolan las filas de INSERT; el hilo del
  dominio las drena al `TBulkInsert` (la conexión UniDAC no admite uso
  concurrente) y lleva la barra de progreso.
- No se crean fotos a nivel artículo (`CODIGO_UNIDAD_FOT = ''`): el
  legacy solo tiene foto por color. Sin un SKU activo, el resolutor muestra
  la primera foto del artículo ordenada por `CODIGO_UNIDAD_FOT`.

## Requisitos

- La tabla `fza_articulos_fotos` debe existir en el destino (está en
  `factuzam_original.sql` y en el esqueleto extraído de una BBDD viva;
  para BBDD antiguas, `DESARROLLOS EN CURSO/fotos_articulos.sql`).
- El equipo que ejecuta el migrador necesita ver la carpeta raíz legacy
  (`C:\fotos` o ruta de red) y poder escribir en la carpeta destino.
