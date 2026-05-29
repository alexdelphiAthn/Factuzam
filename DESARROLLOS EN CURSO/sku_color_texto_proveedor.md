# Color del SKU = texto del proveedor (básico como helper)

Decisión de negocio sobre qué color llevan los SKU generados al materializar
una sesión de compra.

## Modelo

- El **color del SKU** (segmento de color de `CODIGO_UNIDAD_SKU`) es el
  **texto libre del proveedor saneado**, que es la **identidad real** del
  color. Se persiste como `fza_atributos_valores.AV`.
- El **color básico** (`fza_atributos_basicos`, con HEX) es un **helper de
  clasificación** — importante, pero helper. Se enlaza vía
  `fza_atributos_valores.ID_ATB_AV` y se asocia al artículo en
  `fza_articulos_atributos_basicos` (para HEX de etiquetas/fotos, agrupar
  "todos los azules", panel "Atributo básico").

Ejemplo: el proveedor llama al color `011-AZ`; se clasifica como básico
`AZUL`. Resultado: SKU `ARTICULO/011-AZ/talla`, `AV='011-AZ'` enlazado a
`AZUL`, foto `ARTICULO_011-AZ_1_real.png`.

## Antes vs ahora

| | Antes | Ahora |
|---|---|---|
| Color del SKU | código del **básico** (`AZUL`) | **texto del proveedor** (`011-AZ`) |
| Texto del proveedor | se descartaba | es la identidad del color |
| Básico | obligatorio, era el SKU | helper (clasifica, HEX) |
| Mismo color, 2 proveedores | 1 SKU (stock unido) | 2 SKU (stock por proveedor) |

## Decisiones tomadas

1. **Identidad por proveedor**: dos proveedores con texto distinto para el
   mismo básico generan AV/SKU distintos → **stock separado**. Aceptado.
2. **Solo SKU nuevos**: no se migran los SKU existentes (seguían el modelo
   antiguo con el básico). Sin renombrado masivo.
3. **El básico sigue importando**: si una línea referencia un `CODIGO_ATB`
   que no existe en la paleta, la materialización **falla** (no se clasifica
   mal en silencio). Si la línea no mapea ningún básico, el SKU sale con el
   color del proveedor pero sin clasificar (`ID_ATB_AV` NULL).

## Saneo del token de color

Regla única, idéntica en SKU y foto:
- `SanearColorSku` (`src/Lib/inLibComprasSesionesMaterializar.pas`).
- `SanearColorFoto` (`src/Lib/inLibFotosNube.pas`).
- Servidor de fotos (`upload_foto.php` / `download_foto.php`, referencia).

Regla: **mayúsculas**; **espacios → `-`**; se conservan letras, dígitos, `-`
y `_`; el resto de símbolos (`/`, `%`, `€`, …) se **prohíben** (se descartan);
sin separadores repetidos ni en los extremos. Así el color del SKU y el de la
foto casan exactamente.

## Implementación

- `ResolverIdAvColorLinea` (único punto que resuelve el color denormalizado;
  lo usan las 3 vías: SKU, pedido y albarán): el `AV` que va al SKU es el
  texto del proveedor saneado; se reusa el AV si ya existe (identidad por
  valor) y, si se crea, se enlaza al básico cuando esté mapeado.
- La vía de **matriz formal** usa el `AV` que el usuario elige en el grid de
  color; si ahí introduce el texto del proveedor, el SKU lo refleja igual.

## Pendiente / a vigilar

- El **servidor real** de fotos (y `ver_foto.php`) debe adoptar la misma
  regla de saneo para que el token `COLOR` del fichero case con el SKU.
- No se ha podido compilar Delphi en el entorno; conviene un *build* en el
  IDE de `inLibComprasSesionesMaterializar` e `inLibFotosNube`.
- `factuzam_original.sql` no se toca (sin cambios de esquema).
