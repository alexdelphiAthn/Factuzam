# Resultado de la fase SQL-2.3b2

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.3b2 está terminada. No modifica el esquema de la BBDD ni
`factuzam_original.sql`.

Los dos resúmenes SQL de `inLibArqueo` y las nueve construcciones literales
de `inLibArqueoTicket` han salido de la capa de dominio. El registro central
contiene ahora 66 definiciones:

- 63 lecturas personalizables con fallback al SQL base;
- una comprobación técnica de esquema `pesSoloBase`;
- dos escrituras de Facturas `pesSoloBase`.

## Contrato y repositorio

El contrato `IRepositorioArqueoTicket` vive en
`src/Caja/Lib/inLibArqueoTicketIntf.pas`. Expone records para:

- cabecera de empresa y contadores;
- devoluciones por forma de pago;
- resúmenes por sección, temporada, empleado, forma de pago y serie;
- rango y detalle de arqueos históricos;
- recuento histórico por forma de pago.

La implementación `UniDataArqueoTicketRepositorio` registra once lecturas,
todas con política `pesPerfilLecturaConFallback`.

## Resumen por sección

La consulta anterior se construía concatenando tantos `UNION ALL` como
niveles solicitaba la configuración. Esa forma no proporcionaba un SQL base
único que pudiera administrarse mediante perfiles.

La nueva definición contiene los nueve niveles admitidos y declara
`:pNIVELES`. El parámetro limita la profundidad en la unión con la jerarquía.
Así existe una sola clave estable:

```text
KEY_USUPER=SQL_REPOSITORIOS
SUBKEY_USUPER=SQL__RepositorioArqueoTicket__ListarResumenSeccion
```

El formulario y el ticket consumen la misma operación. El formulario carga
los records recibidos en un `TClientDataSet`, por lo que su grid ya no
necesita recibir texto SQL.

## Separación de responsabilidades

`inLibArqueo` queda como fachada de alias sin SQL.

`inLibArqueoTicket` conserva:

- formato y composición del ticket térmico;
- cálculos de presentación, porcentajes y anchos;
- impresión, previsualización y generación del PDF.

La unidad ya no depende de `Uni`, `Data.DB`, tablas ni campos físicos. La
impresión normal y las dos reimpresiones históricas reciben los repositorios
creados por la pantalla, por lo que respetan su `oGetSQLFromDB`.

## Fallback

Las once operaciones:

1. validan tipo, parámetros y campos de salida;
2. registran una incidencia si el perfil es inválido o falla;
3. repiten una sola vez con el SQL base;
4. propagan la excepción si también falla el SQL base.

Las columnas históricas opcionales introducidas por migraciones se siguen
leyendo de forma tolerante. Los campos nucleares del cierre sí forman parte
del contrato obligatorio.

## Reducción de SQL en dominio

La contribución directa de SQL-2.3b2 es:

| Métrica | Antes | Después aislado | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 71 | 69 | -2 |
| Construcciones SQL | 459 | 447 | -12 |
| `SELECT` | 290 | 278 | -12 |

Durante la misma tanda, el árbol compartido recibió otra refactorización
concurrente que eliminó 106 construcciones de
`inLibComprasSesionesMaterializar` e `inLibComprasSesiones`. Por eso la
medición reproducible final conjunta es:

| Métrica | SQL-2.3b1 | Estado conjunto | Variación total |
|---|---:|---:|---:|
| Unidades con SQL literal | 71 | 67 | -4 |
| Construcciones SQL | 459 | 341 | -118 |
| `SELECT` | 290 | 234 | -56 |
| `INSERT` | 66 | 40 | -26 |
| `UPDATE` | 48 | 33 | -15 |
| `DELETE` | 39 | 20 | -19 |
| `CALL` | 4 | 2 | -2 |
| DDL | 12 | 12 | 0 |

El techo predeterminado de `scripts/comprobar_sql_en_dominio.ps1` queda en
341 construcciones y 67 unidades. El inventario está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3b2.csv`.

## Pruebas y compilación

SQL-2.3b2 añade cinco pruebas para cubrir:

- las once definiciones y sus políticas;
- la parametrización de niveles;
- los campos nucleares del cierre histórico;
- el rechazo de un perfil sin campos obligatorios;
- el reintento con SQL base ante un error de ejecución.

La aplicación y el proyecto DUnitX compilan en Win64 Debug y Release. Las
dos ejecuciones encuentran 292 pruebas y pasan las 292. La cifra conjunta
incluye pruebas añadidas por otras tareas concurrentes.

## Siguiente fase

SQL-2.3c debe continuar con las diez lecturas de `inLibTiraCajaTicket`.
Las escrituras de cierre y persistencia permanecen fuera de alcance hasta
definir sus límites transaccionales y pruebas de rollback.
