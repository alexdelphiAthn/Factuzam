# Trinquetes graduales de estilo — métodos largos, Exit/Continue, ancho y tabuladores (resultados)

Fecha: 31/07/2026. Instrumentación nueva, sin cambios en producción.
Sin commit.

## Qué se añade

Dos scripts de trinquete en `scripts/`, con el mismo patrón que los
nueve existentes (tope como valor por defecto de `param()`, listado por
unidad, `exit 1` al superar cualquier tope):

| Script | Vigila | Topes congelados |
|---|---|---|
| `comprobar_metodos_largos.ps1` | métodos de más de 120 líneas (§14.5: "a partir de 120, revisar si mezcla pasos") | 124 métodos; 312 líneas el más largo |
| `comprobar_estilo_codigo.ps1` | `Exit`, `Continue`, líneas de más de 80 columnas y líneas con tabulador (§1 y §16) | 1.349 / 107 / 577 / 0 |

Reglas del libro de estilo que hasta hoy solo vivían en la lista de
comprobación (§13) y en la lista negra (§16), sin vigilancia por
script. El código legado queda congelado en su medida actual: ninguna
cifra puede subir, y el código nuevo entra limpio porque cualquier
infracción nueva supera el tope y falla el build.

## Línea base congelada (31/07/2026, 15:22 UTC)

Medida sobre las 528 unidades propias de `src/` (exclusiones de
`comprobar_estado_global.ps1`), con la refactorización ISP de tallas y
tickets de la sesión concurrente ya incorporada al árbol:

| Métrica | Valor | Tope |
|---|---:|---:|
| Métodos > 120 líneas (a mano) | 124 | 124 |
| Líneas del método más largo a mano (`TFormVisualizador.ProcesarComandosESCPOS`) | 312 | 312 |
| Llamadas a `Exit` | 1.349 | 1.349 |
| Llamadas a `Continue` | 107 | 107 |
| Líneas > 80 columnas | 577 | 577 |
| Líneas con tabulador | 0 | 0 |

Las 9 líneas con tabulador de la línea base (6 en `UniDataFacturas`,
1 en `UniDataCaja` y 2 en `inLibCertificates`) se corrigieron en esta
misma sesión: espacios en vez de tabuladores, alineando cada línea con
sus vecinas de bloque, y el tope quedó congelado en 0. Seis
tabuladores de `UniDataFacturas` estaban dentro de literales SQL; para
MariaDB son espacio en blanco, así que la sentencia resultante es
equivalente. Tras el fascículo el resto de métricas no varía
(Exit 1.349, Continue 107, anchas 577, métodos 124/312) y ninguna
línea corregida supera las 80 columnas.

## Decisiones de medida

- **Umbral de 120 líneas, no 200.** El tope de métodos de más de 200
  líneas ya existe en `comprobar_flujos_largos.ps1`
  (`MaximoMetodosMayoresDe200`, hoy 33) y no se duplica. El script
  nuevo aplica el escalón anterior del §14.5 y, además, congela la
  longitud del método más largo escrito a mano, de modo que el peor
  método no puede crecer aunque el recuento no cambie.
- **Rutinas generadas fuera de la deuda.** Igual que en
  `comprobar_flujos_largos.ps1`, `EnumerarResourcestringsTraduccion`
  (15.240 líneas) y `EnumerarParametrosTraduccion` quedan excluidas:
  crecen con cada mensaje traducible nuevo y romperían el trinquete en
  una regeneración legítima. El script comprueba que ambas siguen
  existiendo y falla si desaparecen sin actualizar la lista.
- **Columnas en caracteres, no en bytes.** Una línea con acentos en
  UTF-8 puede superar 80 bytes midiendo 79 caracteres; el libro habla
  de columnas visibles, así que se cuentan caracteres. (La medida en
  bytes daría 8.608 líneas "anchas": casi todas falsas.)
- **`Exit`/`Continue` sobre código ejecutable.** Se cuentan con límite
  de palabra tras vaciar cadenas y los tres tipos de comentario en una
  sola pasada, así que un `Exit` citado en un comentario o dentro de un
  literal no cuenta.
- **Exclusiones de árbol**: las mismas catorce carpetas que
  `comprobar_estado_global.ps1` (terceros, vendorizado y proyectos
  utilitarios).

## Verificación

- Batería automatizada en `tests/PruebasTrinquetesEstilo.ps1`: 13 casos,
  todos correctos. Comprueba la línea base real, la sintaxis y formato
  de ambos scripts, los límites exactos 80/81 y 120/130, bloques
  `case`/`try`/`repeat` anidados, comentarios y cadenas ignorados,
  cp1252, UTF-8 con BOM, CRLF, cada fallo de tope por separado, la
  integridad de las rutinas generadas y las exclusiones del árbol.
- Contraste independiente en Python (detección de codificación por
  fichero, mismo vaciado de comentarios): coincidencia exacta de las
  cuatro métricas de estilo sobre las 528 unidades.
- Árbol sintético con violaciones conocidas (UTF-8 con BOM, cp1252 y
  CRLF): 3 `Exit` reales contados y los de comentario/cadena ignorados;
  línea de 81 caracteres contada y la de 80 no; línea acentuada de 79
  caracteres y más de 80 bytes no contada; método de 130 líneas con
  `case`/`try` anidados medido exacto.
- Pruebas negativas: cada tope superado en una unidad devuelve
  `exit 1` con su mensaje; árbol sin las rutinas generadas devuelve
  `exit 1` por integridad; árbol limpio con topes a 0 devuelve
  `exit 0`.
- Con umbral 200, el script nuevo cuenta 30 métodos frente al tope 33
  de `comprobar_flujos_largos.ps1`: coherente (este script limpia
  comentarios antes de buscar cabeceras y excluye el árbol vendorizado
  completo).
- Ambos scripts respetan sus propias 80 columnas y corren en menos de
  7 segundos sobre el árbol completo.

## Uso

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\comprobar_metodos_largos.ps1
pwsh -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\comprobar_estilo_codigo.ps1
pwsh -NoProfile -ExecutionPolicy Bypass `
  -File .\tests\PruebasTrinquetesEstilo.ps1
```

`-MostrarTodos` lista todas las unidades con infracciones en vez de
las 20 peores. Para recongelar tras un fascículo que baje una métrica,
sustituir el valor por defecto del tope correspondiente en el
`param()` del script por la nueva medida (mismo procedimiento que el
resto de trinquetes: sin margen, y ninguna cifra vuelve a subir).
La batería acepta `-OmitirLineaBase` para ejecutar solo los casos
sintéticos y reducir el tiempo durante el desarrollo del analizador.

## Pendiente

- Añadir las seis métricas a la tabla de trinquetes de
  `PLAN_SOLID.md` §6 y, cuando toque, promover a §16 la entrada
  "línea nueva con tabulador". No se ha tocado `PLAN_SOLID.md` en esta
  sesión para no pisar la refactorización ISP concurrente.
- Incorporar los dos scripts a la batería que se ejecuta en cada
  commit, junto a los nueve existentes.
- Compilar Release Win32/Win64: el fascículo de tabuladores solo toca
  espacio en blanco y literales SQL equivalentes, pero la regla del
  fascículo exige compilar antes del commit.
- Borrar `_to_delete/factuzam_snap_trinquetes.tgz` (snapshot temporal
  usado para medir la línea base; el VM no puede borrarlo).
