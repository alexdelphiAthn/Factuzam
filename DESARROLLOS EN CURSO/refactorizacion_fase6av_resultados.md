# Fase 6AV — aplicación de artículos en devoluciones de compra

Fecha: 29/07/2026. D4.12, duodécima tanda de métodos largos. Sin commit
manual.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `AplicarArticuloDevolucion` | 310 | 12 | **-298** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inMtoDevolucionesCompra` completa | 2.596 | 2.691 | **+95** |

La unidad crece un 3,7 %. D4.12 reduce complejidad, no volumen:
`AplicarArticuloDevolucion` queda como fachada y el colaborador privado
`TAplicacionArticuloDevolucion` reparte el flujo entre diecinueve
operaciones con nombre. Todas tienen consumidor y ninguna supera 29
líneas.

No cambia la API del formulario ni se crea otra unidad. El estado
temporal de la resolución y materialización queda encapsulado en el
colaborador.

## Implementación

`TAplicacionArticuloDevolucion` separa:

- lectura del proveedor, almacén y fecha de la cabecera;
- detección de un código de artículo exacto;
- resolución alternativa de artículo y SKU;
- obtención del coste del proveedor;
- búsqueda del conjunto de atributos que actúa como pivote;
- elección de la referencia del proveedor;
- escritura defensiva de campos opcionales del dataset;
- cálculo de cantidad, unidades y total;
- preparación del color pendiente;
- actualización de tallas, atributos y pivote horizontal;
- coordinación de edición y guarda contra reentrada.

Se conserva el orden crítico:

1. persistir la cabecera si es necesario;
2. abrir o editar la línea activa;
3. leer el contexto de proveedor, almacén y fecha;
4. resolver primero como artículo exacto y, si no lo es, como SKU;
5. completar el último coste cuando el artículo requiere SKU;
6. resolver pivote y referencia del proveedor;
7. materializar identificación, precio y cantidades;
8. preparar el color pendiente;
9. refrescar la presentación;
10. hacer `Post` cuando el pivote horizontal está activo.

También se conservan:

- las tres consultas SQL y sus prioridades;
- el fallback de la referencia al último coste;
- el mensaje del validador o el mensaje genérico;
- cantidad y unidades a cero para artículos con SKU y pivote;
- cantidad por defecto uno en el resto;
- enfoque y apertura diferidos de la búsqueda de SKU;
- restauración de `FAplicandoArticulo` mediante `finally`.

La operación diferida captura el formulario y la columna, no el
colaborador temporal que ya habrá sido liberado al ejecutarse la cola.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.12:

- la fachada no puede superar 100 líneas;
- las diecinueve operaciones deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- se protege el orden de persistencia, resolución, aplicación y
  liberación de la guarda;
- se protege la fachada y su `FreeAndNil`;
- se protegen consultas, costes, pivote, cantidades, totales,
  preparación de color y refresco;
- el límite global baja de 39 a 38 métodos mayores de 200 líneas.

Resultado: fachada de 12 líneas, colaborador máximo de 29 y 38 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La aplicación principal se reconstruyó con Delphi 37 en Release/Win32
y Release/Win64 dentro de `build/validacion_d412`. Ambas plataformas
compilan y enlazan el refactor sin errores.

La matriz DUnitX general no enlaza `inMtoDevolucionesCompra`, pero se
recompiló después de todas sus fuentes para controlar regresiones
concurrentes:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 227/228 | 0 | 1 |
| Release / Win64 | 0 errores | 227/228 | 0 | 1 |
| Debug / Win32 | 0 errores | 227/228 | 0 | 1 |
| Release / Win32 | 0 errores | 227/228 | 0 | 1 |

La única roja sigue siendo ajena a D4.12:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

También pasan:

- el comprobador de flujos largos;
- el comprobador de acoplamiento sobre 424 unidades;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido;
- `git diff --check`.

## Validación funcional pendiente

Con una BBDD y una devolución de compra de pruebas:

1. Introducir un código exacto de artículo sin SKU.
2. Introducir directamente un SKU y comprobar artículo y unidad.
3. Probar un artículo que requiera SKU con y sin pivote.
4. Verificar la referencia del proveedor activo y su fallback.
5. Comprobar familia, descripción, tipo de cantidad, IVA y último
   precio de compra.
6. Confirmar cantidad uno para artículo simple y cero para el pendiente
   de talla/color.
7. Comprobar `TOTAL_UNIDADES_DEVCLIN` y `TOTAL_DEVCLIN`.
8. Activar atributos y pivote horizontal y verificar el `Post`.
9. Dejar el SKU pendiente y comprobar el enfoque y apertura diferidos.
10. Introducir un código inexistente y verificar el aviso.
11. Forzar una excepción de resolución y confirmar que la guarda de
    reentrada se libera.

El siguiente fascículo es **D4.13**: `ImprimirTicketDesdeBD`,
actualmente con 309 líneas.
