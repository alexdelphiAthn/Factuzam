# Fase 6AK — materialización de sesiones por pasos

Fecha: 29/07/2026. D4.1, primera tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibComprasSesionesMaterializar` | 2.781 | 2.752 | **-29** |
| `MaterializarSesion` | 370 | 52 | **-318** |
| `RevertirMaterializacion` | 424 | 58 | **-366** |
| Métodos del alcance por encima de 200 líneas | 2 | 0 | **-2** |

Los 19 colaboradores privados están usados. El mayor,
`MaterializarArticulos`, tiene 116 líneas; ninguno de los pasos nuevos
alcanza las 200.

D4 queda iniciado: **2 de los 48 métodos largos de partida tratados**.

## Implementación

`MaterializarSesion` conserva la API pública y pasa a coordinar pasos
pequeños:

- carga del contexto de sesión y resolución de las series;
- creación o reutilización de artículos, SKUs y códigos de barras;
- generación y registro del pedido;
- generación, cierre y registro del albarán;
- cierre de la sesión;
- persistencia del error tras el rollback.

`RevertirMaterializacion` separa validación, detección de tablas legacy,
borrado de artículos, albarán, documentos, movimientos, pedidos y reapertura
de la sesión. Los siete borrados repetitivos de dependencias del artículo
se expresan mediante una tabla declarativa y un único ejecutor.

Se conserva:

- la propiedad de la transacción cuando la conexión ya tenía una abierta;
- `ASoloDocumentos` para las iteraciones por almacén;
- el orden de creación y reversión;
- los documentos y contadores devueltos al llamante;
- los avisos cuando faltan tablas opcionales;
- el borrado de fotos como mejor esfuerzo;
- el rollback y `MENSAJE_ERROR_SES` ante un fallo.

Los cuatro `Exit` de los dos métodos de entrada desaparecen. No se añade
ningún `Exit` ni `Continue`.

## Pruebas automáticas

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 163/163 | 0 | 0 |
| Debug / Win32 | 0 errores | 163/163 | 0 | 0 |
| Release / Win64 | 0 errores | 163/163 | 0 | 0 |
| Release / Win32 | 0 errores | 163/163 | 0 | 0 |

La aplicación se reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d41/Win64/Release`: 0 errores, 311.517 líneas y
10,95 segundos.

También pasan:

- 26 comprobaciones del orden de los pasos y los contratos SQL críticos;
- el comprobador de dependencias de capa: 376 unidades y ciclo mayor 1;
- `git diff --check` limitado al alcance;
- UTF-8 con BOM y CRLF en la unidad Pascal;
- ninguna línea de producción añadida por encima de 80 columnas;
- los 19 colaboradores con al menos una llamada real;
- `factuzam_original.sql` intacto.

`test_revertir_sesion.py` no se ejecutó: el intérprete disponible no tiene
`PyMySQL` y la batería necesita además una BBDD de prueba recién cargada
porque modifica sesiones. No se instaló una dependencia temporal ni se tocó
ninguna BBDD para forzar esa pasada.

## Plan de comprobación funcional

Pendiente de ejecución manual con una BBDD de pruebas:

1. Materializar líneas nuevas, reutilizadas, de matriz y de servicio.
2. Generar pedido y albarán juntos y por separado.
3. Repetir con documentos separados por almacén.
4. Provocar un fallo y comprobar rollback y `MENSAJE_ERROR_SES`.
5. Revertir una sesión cerrada y comprobar artículos, documentos y stock.
6. Re-materializar y confirmar que no aparecen duplicados.
7. Repetir contra una BBDD legacy y revisar los avisos de tablas ausentes.

El siguiente fascículo es **D4.2**:
`CrearAlbaranDesdePedidoConCantidades`.
