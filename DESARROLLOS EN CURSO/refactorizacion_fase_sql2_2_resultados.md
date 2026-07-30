# Resultado de la fase SQL-2.2

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.2 está terminada. No modifica el esquema de la BBDD ni
`factuzam_original.sql`.

Las catorce lecturas que antes construían
`inLibArticulosValidador` e `inLibArticulosAtributosLookup` están detrás
de dos contratos sin dependencias de UniDAC:

- `IArticulosValidador`;
- `IArticulosAtributosLookup`.

El registro central contiene ahora 40 definiciones:

- 38 lecturas personalizables con fallback al SQL base;
- dos escrituras de Facturas que permanecen `pesSoloBase`.

## RepositorioArticulosValidador

La implementación concreta vive en
`src/DataModules/UniDataArticulosValidadorRepositorio.pas` y registra:

1. `ContarCoincidencias`;
2. `ObtenerDatosArticulo`;
3. `ListarSkusActivos`;
4. `ValidarSkuArticulo`;
5. `ObtenerProveedorMatch`;
6. `ResolverEntrada`;
7. `TieneSkuActivo`.

`ContarCoincidencias` y `ResolverEntrada` concatenaban un filtro cuando la
entrada procedía del lector de códigos de barras. Ambas operaciones tienen
ahora una estructura estable con el parámetro `:solo`:

- `S` restringe la búsqueda a coincidencias EAN;
- `N` admite artículo, SKU, EAN y referencia de proveedor.

La consulta de existencia de SKU activo mantiene su comportamiento, pero
el literal `SELECT 1` incorpora el alias `TIENE_SKU` para que el contrato
pueda validar también el dataset real.

## RepositorioArticulosAtributos

La implementación concreta vive en
`src/DataModules/UniDataArticulosAtributosRepositorio.pas` y registra:

1. `ValoresAtributoConjunto`;
2. `ValoresAtributoActivos`;
3. `ValoresPropiedad`;
4. `ObtenerAtributos`;
5. `ObtenerPropiedades`;
6. `ObtenerAtributosDeSku`;
7. `ObtenerAvsEnSkus`.

Se conservan como operaciones distintas la lectura de valores del conjunto
asignado y el fallback a todos los valores activos. Así cada consulta tiene
parámetros y campos de salida estables.

## Contratos y fachadas

Los tipos y contratos viven en:

- `src/Lib/inLibArticulosValidadorIntf.pas`;
- `src/Lib/inLibArticulosAtributosIntf.pas`.

Las antiguas unidades `inLibArticulosValidador` e
`inLibArticulosAtributosLookup` son fachadas de compatibilidad. No
contienen SQL.

Los consumidores utilizan interfaces. Los procesos que no tienen una
pantalla asociada disponen de factorías base explícitas, sin acceso a
perfiles.

## Activación por pantalla

`TfrmBase` ofrece:

- `CrearValidadorArticulos`;
- `CrearLookupAtributosArticulos`.

Ambas factorías reutilizan el catálogo perezoso de la pantalla. Los modos
reutilizables de SKU, desglose, tallas y pivote reciben también ambos
contratos dentro de `TConfigColumnasSku`.

Por tanto, una pantalla con `oGetSQLFromDB=True` conserva el catálogo al
delegar la entrada de artículos en esas librerías. Con el interruptor a
`False` utiliza siempre el SQL base y no carga `SQL_REPOSITORIOS`.

Las claves de operación continúan siendo compartidas:

```text
SQL__RepositorioArticulosValidador__<Operacion>
SQL__RepositorioArticulosAtributos__<Operacion>
```

No contienen el nombre del formulario, por lo que una corrección sirve
para todas las pantallas activadas que consuman la misma operación.

## Fallback

Las catorce operaciones son lecturas. Ante un perfil inválido, un error de
ejecución o la ausencia de campos obligatorios:

1. se registra la incidencia;
2. se descarta el resultado personalizado;
3. se reintenta una sola vez con el SQL base;
4. si falla también el SQL base, se propaga la excepción.

## Reducción de SQL en dominio

| Métrica | SQL-2.1 | SQL-2.2 | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 74 | 72 | -2 |
| Construcciones SQL | 489 | 475 | -14 |
| `SELECT` | 320 | 306 | -14 |
| `INSERT` | 66 | 66 | 0 |
| `UPDATE` | 48 | 48 | 0 |
| `DELETE` | 39 | 39 | 0 |
| `REPLACE` | 0 | 0 | 0 |
| `CALL` | 4 | 4 | 0 |
| DDL | 12 | 12 | 0 |

El techo predeterminado de
`scripts/comprobar_sql_en_dominio.ps1` queda en 475 construcciones y 72
unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_2.csv`.

## Pruebas y compilación

SQL-2.2 añade seis pruebas que cubren:

- las siete definiciones del validador;
- las siete definiciones de atributos;
- el parámetro estructural `:solo`;
- una personalización válida compartida;
- un perfil sin campos obligatorios;
- el reintento con SQL base ante un error de ejecución.

La ejecución Win64 Debug encuentra 266 pruebas y pasan las 266. La
aplicación y el proyecto de pruebas compilan en Win64 Debug y Release
usando salidas aisladas bajo `build/validacion_sql22`.

## Siguiente fase

SQL-2.3 debe continuar con consultas exclusivamente de lectura de arqueo y
tickets. Las materializaciones y escrituras de negocio continúan fuera de
alcance hasta definir límites transaccionales y pruebas de rollback.
