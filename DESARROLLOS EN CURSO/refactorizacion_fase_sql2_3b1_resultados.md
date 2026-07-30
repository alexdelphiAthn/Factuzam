# Resultado de la fase SQL-2.3b1

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.3b1 está terminada. No modifica el esquema de la BBDD ni
`factuzam_original.sql`.

Las diez lecturas ejecutadas por el cálculo principal de arqueo han salido
de `inLibArqueo`. El registro central contiene ahora 55 definiciones:

- 52 lecturas personalizables con fallback al SQL base;
- una comprobación técnica de esquema `pesSoloBase`;
- dos escrituras de Facturas `pesSoloBase`.

## Contrato y repositorio

El contrato `IRepositorioArqueoCaja` vive en
`src/Caja/Lib/inLibArqueoIntf.pas`. Expone el cálculo mediante records de
dominio y no conoce UniDAC, consultas ni nombres de tabla.

La implementación concreta vive en
`src/Caja/DataModules/UniDataArqueoRepositorio.pas` y registra:

1. contadores de ventas y operaciones;
2. importes bruto y neto de líneas;
3. ventas, devoluciones, entradas y salidas;
4. préstamos y cobros de clientes;
5. vales emitidos y recogidos;
6. pagos agrupados por forma;
7. comprobación y obtención del efectivo del arqueo anterior.

Nueve operaciones usan `pesPerfilLecturaConFallback`. La consulta de
`INFORMATION_SCHEMA` que comprueba si existe la columna histórica usa
`pesSoloBase`, porque es una operación técnica ligada al esquema.

## Separación y composición

`inLibArqueo` conserva temporalmente los generadores dinámicos de resumen
por sección y temporada. Ya no calcula el arqueo ni depende de UniDAC.

El formulario base ofrece `CrearRepositorioArqueoCaja`. El formulario de
arqueo, la impresión normal y la reimpresión histórica reciben la misma
implementación creada por la pantalla consumidora. De este modo:

- con `oGetSQLFromDB=True`, las nueve lecturas buscan el catálogo
  compartido `SQL_REPOSITORIOS`;
- con `oGetSQLFromDB=False`, usan directamente el SQL base del ejecutable;
- la reimpresión histórica no abre una ruta de configuración distinta.

Las claves publicables siguen el patrón:

```text
KEY_USUPER=SQL_REPOSITORIOS
SUBKEY_USUPER=SQL__RepositorioArqueoCaja__<Operacion>
```

## Fallback

Ante un perfil inválido, un error al abrir la consulta o la ausencia de
campos obligatorios:

1. se registra la incidencia;
2. se descarta el resultado personalizado;
3. se repite una sola vez con el SQL base;
4. si falla también el SQL base, se propaga la excepción.

La comprobación técnica de esquema no consulta perfiles y ejecuta siempre
el SQL base.

## Reducción de SQL en dominio

| Métrica | SQL-2.3a | SQL-2.3b1 | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 71 | 71 | 0 |
| Construcciones SQL | 469 | 459 | -10 |
| `SELECT` | 300 | 290 | -10 |
| `INSERT` | 66 | 66 | 0 |
| `UPDATE` | 48 | 48 | 0 |
| `DELETE` | 39 | 39 | 0 |
| `REPLACE` | 0 | 0 | 0 |
| `CALL` | 4 | 4 | 0 |
| DDL | 12 | 12 | 0 |

El número de unidades no baja todavía porque `inLibArqueo` conserva tres
construcciones asociadas a los dos resúmenes dinámicos. El techo
predeterminado de `scripts/comprobar_sql_en_dominio.ps1` queda en 459
construcciones y 71 unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3b1.csv`.

## Pruebas y compilación

SQL-2.3b1 añade cinco pruebas para cubrir:

- las diez definiciones y sus contratos;
- la política base de la comprobación de esquema;
- una personalización sin campos obligatorios;
- el reintento con SQL base ante un error de ejecución.

La aplicación y el proyecto DUnitX compilan en Win64 Debug y Release. Las
dos ejecuciones encuentran 277 pruebas y pasan las 277.

## Siguiente fase

SQL-2.3b2 debe extraer los resúmenes dinámicos por sección y temporada y
las consultas adicionales de `inLibArqueoTicket`. Las escrituras de cierre
y persistencia permanecen fuera de alcance hasta definir sus límites
transaccionales y pruebas de rollback.
