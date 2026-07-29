# Fase 6AP — tira de caja Excel por pasos

Fecha: 29/07/2026. D4.6, sexta tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `TTiraCajaTicket.ExportarExcel` | 438 | 22 | **-416** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibTiraCajaTicket` completa | 1.449 | 1.566 | **+117** |

La unidad crece un 8,1 %. D4.6 reduce complejidad, no volumen: el flujo
monolítico se convierte en una fachada y 18 operaciones internas con
nombre. Todas tienen consumidor y ninguna supera 40 líneas.

La asignación de empresa, almacén, caja y operación deja de estar
triplicada en las consultas de venta, traspaso y depósito. No se crea
otra unidad ni se mezcla el renderizado Excel con el ticket térmico.

## Implementación

`TExportadorTiraCajaExcel` conserva en un contexto explícito:

- selección de caja, fechas, series y tipos de operación;
- control de agrupación cronológica o por documento;
- permiso de valoración de traspasos;
- preview, hoja, cursor maestro, fila, contadores y acumulados.

El flujo queda separado en:

- cabecera y texto de series;
- apertura y parametrización común de consultas de detalle;
- ventas, traspasos, ingresos, gastos y depósitos;
- títulos, subtotales, resumen y cierre;
- ciclo de vida del preview.

Se conservan sin cambios:

- `SQLOperaciones` y `AsignarParamsOperaciones`, compartidos con la
  impresión térmica;
- los tres SQL de detalle y su orden;
- el documento formateado y el fallback al número de operación;
- venta, coste de traspaso, importe, cobrado y pendiente;
- títulos, subtotales y los dos modos de agrupación;
- `BeginUpdate`/`EndUpdate`, popup, nombre sugerido y presentación.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.6:

- `TTiraCajaTicket.ExportarExcel` no puede superar 100 líneas;
- las 18 operaciones internas deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- se protegen lote, cursor maestro y consulta de detalle común;
- se conservan literales, campos de coste y anticipos;
- el límite global baja de 45 a 44 métodos mayores de 200 líneas.

Resultado: fachada de 22 líneas, colaborador máximo de 40 y 44 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La unidad se compiló directamente con Delphi 37 en Win64 y Win32:
0 errores en ambas plataformas.

La matriz DUnitX se recompiló en salida aislada:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 214/215 | 0 | 1 |
| Debug / Win32 | 0 errores | 214/215 | 0 | 1 |
| Release / Win64 | 0 errores | 214/215 | 0 | 1 |
| Release / Win32 | 0 errores | 214/215 | 0 | 1 |

La única roja sigue siendo ajena a D4.6:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

La batería general no enlaza el exportador visual. La aplicación se
reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d46/Win64/Release`: 0 errores, 318.001 líneas y
24,56 segundos. Durante los primeros intentos estuvo bloqueada por una
edición concurrente incompleta de `UniDataFacturas`; al estabilizarse,
la compilación pasó sin cambios de D4.6.
Esa compilación mostró cinco `hint` concurrentes en
`inLibFacturasRepositorio` por no declarar `Data.DB`; D4.6 no los toca.

También pasan:

- el comprobador de flujos largos;
- el comprobador de dependencias: 407 unidades y ciclo mayor 1;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido.

`factuzam_original.sql` sigue modificado (+95/-6) por trabajo concurrente.
D4.6 no lo ha tocado ni revertido.

## Validación funcional pendiente

Con una BBDD de pruebas:

1. Exportar sin operaciones y con ventas de varias líneas.
2. Probar todas las series y una selección de varias series.
3. Probar traspasos con y sin permiso para ver coste.
4. Incluir ingresos y gastos y comparar sus subtotales.
5. Incluir depósitos y revisar venta, cobrado y pendiente.
6. Comparar orden cronológico con agrupación por tipo de documento.
7. Revisar títulos, subtotales, resumen y documentos formateados.
8. Guardar el XLSX desde el preview y compararlo con la versión anterior.

El siguiente fascículo es **D4.7**:
`TArqueoPersistencia.GrabarArqueo`, actualmente con 371 líneas.
