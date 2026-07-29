# Fase 6AL — albarán de compra desde pedido por pasos

Fecha: 29/07/2026. D4.2, segunda tanda de métodos largos. Sin commit.

## Estado encontrado

La extracción principal ya estaba incorporada en el `HEAD` actual
(`b217c1e4`) al comenzar esta tanda, aunque el plan todavía señalaba D4.2
como pendiente y no existía su informe ni una comprobación permanente.

Esta pasada revisa la equivalencia, completa la limpieza y deja la
refactorización validada y protegida frente a regresiones.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `CrearAlbaranDesdePedidoConCantidades` | 348 | 47 | **-301** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibPedidosCompra` completa | 1.496 | 1.695 | **+199** |

El volumen total de la unidad crece un 13,3 %. D4.2 reduce complejidad,
no volumen: el antiguo flujo monolítico se convierte en 18 operaciones
con nombre y contrato propios. Todas tienen consumidor y ninguna supera
65 líneas. No se oculta este crecimiento en el balance.

La limpieza final encapsula el contador de líneas dentro del procesador
de celdas y elimina el parámetro `var` que ningún llamante necesitaba.
Reduce dos líneas respecto a la extracción encontrada.

## Implementación revisada

El punto de entrada conserva su firma pública y coordina:

- validación de almacén y cantidades;
- reserva del contador `AB`;
- creación de la cabecera a partir del pedido;
- lectura y recepción limitada por el pendiente real de cada línea;
- inserción de líneas y actualización de cantidades recibidas;
- eliminación de la cabecera si no se pudo crear ninguna línea;
- totales, movimientos, cierre, pendientes y estado del pedido;
- propagación de la temporada a los artículos recibidos.

La consulta de línea enlaza explícitamente `fza_pedidos_compra P`.
El alias `P` es necesario para leer
`ESIVA_EXENTO_INTRACOMUNITARIO_PEDC`; sin ese `JOIN`, la consulta antigua
referenciaba una cabecera ausente.

La transacción continúa perteneciendo a
`EjecutarRecepcionPedidoCompra`. El motor no abre ni confirma una
transacción interna, por lo que crear o incorporar sigue siendo una
operación atómica para el llamante.

## Protección automática

`scripts/comprobar_flujos_largos.ps1` incorpora ahora D4.2:

- `CrearAlbaranDesdePedidoConCantidades` no puede superar 100 líneas;
- los 18 colaboradores deben existir una sola vez;
- cada colaborador debe tener al menos un consumidor;
- ninguno puede superar 100 líneas;
- el enlace fiscal con la cabecera del pedido es obligatorio;
- el límite de no regresión baja de 49 a 48 métodos largos.

Resultado actual: método objetivo de 47 líneas y 48 métodos productivos
por encima de 200, justo el nuevo límite.

## Pruebas automáticas

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 191/191 | 0 | 0 |
| Debug / Win32 | 0 errores | 191/191 | 0 | 0 |
| Release / Win64 | 0 errores | 191/191 | 0 | 0 |
| Release / Win32 | 0 errores | 191/191 | 0 | 0 |

La aplicación se reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d42/Win64/Release`: 0 errores, 314.993 líneas y
15,11 segundos.

También pasan:

- el comprobador de flujos largos;
- el comprobador de dependencias de capa;
- UTF-8 con BOM y CRLF en la unidad Pascal;
- ninguna línea de producción añadida por encima de 80 columnas;
- ningún `Exit` ni `Continue` nuevo;
- `git diff --check` limitado al alcance;
- `factuzam_original.sql` intacto.

`test_albaran_pedido_compra.py` conserva sus 38 comprobaciones de datos,
pero no se ejecutó: falta `PyMySQL` y la batería requiere una copia recién
cargada de `factuzam_test` porque modifica pedidos, albaranes y stock. No
se instaló una dependencia temporal ni se alteró una BBDD para forzarla.

## Plan de comprobación funcional

Pendiente de ejecución manual con una BBDD de pruebas:

1. Recibir todo lo pendiente de un almacén.
2. Recibir cantidades parciales desde el pivote.
3. Enviar varias celdas de una línea por encima de su pendiente.
4. Confirmar que otro almacén queda fuera del albarán.
5. Probar un pedido exento intracomunitario.
6. Comprobar estado parcial, recibido y cancelado.
7. Provocar un fallo posterior y verificar el rollback completo.
8. Revisar numeración, totales, movimientos, temporada y cierre.

El siguiente fascículo es **D4.3**: `ExportarBalanceTallasExcel`.
