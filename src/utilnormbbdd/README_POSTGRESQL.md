# Migración de Factuzam a PostgreSQL 16

Este directorio contiene una migración reproducible del volcado histórico de
Factuzam desde MariaDB a PostgreSQL. No es un conversor SQL universal. El
programa conoce deliberadamente el inventario y las particularidades de este
volcado: 66 tablas, 50 vistas, 7.063 filas de datos y 45 rutinas de negocio.
Si ese contrato cambia, la generación debe fallar para obligar a revisar la
conversión semántica.

## Archivos

- `factuzam_original.sql`: fuente MariaDB. Es la referencia histórica y no se
  modifica durante la generación.
- `convert_factuzam_to_postgresql.py`: generador específico de Factuzam.
- `factuzam_original_postgresql_routines.sql`: traducción PostgreSQL revisada
  de las 45 rutinas. Se mantiene separada porque no puede obtenerse mediante
  sustituciones mecánicas fiables.
- `factuzam_original_postgresql.sql`: bootstrap generado y versionado. Incluye
  esquema, datos, índices, comentarios, triggers, vistas y el módulo de
  rutinas. No debe editarse a mano.
- `validate_factuzam_postgresql.sql`: smoke test de catálogo para una base ya
  cargada. Solo lee metadatos y termina con `ROLLBACK`.

El generador conserva como datos los textos SQL MariaDB almacenados en tablas
de Factuzam; no intenta convertir ni ejecutar esos textos.

## Requisitos

- Python 3.
- PostgreSQL 16 o posterior, con las utilidades `createdb` y `psql`.
- Base de destino en UTF-8.
- Un rol capaz de crear tablas, vistas, secuencias, funciones, procedimientos
  y triggers en el esquema `public`.

La ordenación y la comparación textual dependen de la configuración regional
de la base de destino. Debe elegirse al crearla; el bootstrap no fuerza una
colación MariaDB equivalente.

## Regenerar y comprobar

Ejecutar desde la raíz del repositorio:

```console
python src/utilnormbbdd/convert_factuzam_to_postgresql.py
```

La salida se escribe con el formato estable esperado por el repositorio. Para
comprobar en CI que el SQL versionado corresponde exactamente al origen, al
generador y al módulo de rutinas:

```console
python src/utilnormbbdd/convert_factuzam_to_postgresql.py --check
```

`--check` no modifica archivos. Regenera en memoria, compara byte a byte y
devuelve un código distinto de cero si la salida está ausente o desactualizada.

## Carga segura

El bootstrap contiene `DROP ... CASCADE` para poder reconstruir sus propios
objetos. Por tanto, debe cargarse en una base nueva y vacía, nunca directamente
sobre una base de producción o una base que contenga objetos ajenos.

Ejemplo, adaptando el nombre y las opciones de conexión al entorno:

```console
createdb --template=template0 --encoding=UTF8 factuzam_pg16
psql -X -v ON_ERROR_STOP=1 -d factuzam_pg16 -f src/utilnormbbdd/factuzam_original_postgresql.sql
psql -X -v ON_ERROR_STOP=1 -d factuzam_pg16 -f src/utilnormbbdd/validate_factuzam_postgresql.sql
```

`-X` evita que una configuración personal de `psql` altere la carga y
`ON_ERROR_STOP=1` detiene el proceso ante el primer error. El bootstrap se
ejecuta dentro de una transacción: si `psql` termina por un error, el cierre de
la conexión revierte la transacción no confirmada. Aun así, antes de una
migración real se necesita copia de seguridad, ensayo de restauración y pruebas
funcionales de la aplicación.

## Contratos de llamada PostgreSQL

Las rutinas que solo modifican estado se exponen como procedimientos y se
invocan con `CALL`. Los resultados tabulares de forma fija se exponen como
funciones y se consultan con `SELECT`. Los parámetros `OUT` de un procedimiento
PostgreSQL forman una fila de resultado; el adaptador UniDAC no debe conservar
las variables de sesión `@salida` usadas por MariaDB.

`prc_get_caja_stock_pivotado` y
`prc_get_caja_stock_pivotado_withz` producen columnas cuyo número y nombre
dependen de los atributos del artículo. PostgreSQL no permite declarar ese
resultado como una tabla fija, por lo que el contrato usa `refcursor`:

1. Abrir una transacción.
2. Ejecutar `CALL` pasando la entrada y un nombre de cursor.
3. Ejecutar `FETCH ALL FROM nombre_cursor` en la misma conexión y transacción.
4. Confirmar o revertir la transacción.

Ejemplo del patrón, usando la firma versionada de la rutina como autoridad:

```sql
BEGIN;
CALL prc_get_caja_stock_pivotado('ARTICULO', 'factuzam_stock');
FETCH ALL FROM factuzam_stock;
COMMIT;
```

El cursor deja de existir al terminar la transacción. El código Pascal/PHP
debe encapsular las cuatro operaciones en un adaptador y no puede dejar el
`CALL` en modo autocommit. Debe usarse un nombre de cursor independiente por
operación cuando una conexión pueda tener más de una consulta activa.

## Transacciones: diferencia respecto a MariaDB

Las rutinas originales mezclaban `START TRANSACTION`, `COMMIT`, `ROLLBACK` y
handlers, incluso cuando eran llamadas por otra rutina o desde una transacción
de la aplicación. Esa semántica no tiene una traducción anidada directa en
PL/pgSQL.

En la versión PostgreSQL las rutinas participan en la transacción del llamador
y no hacen `COMMIT` ni `ROLLBACK` internos. Una excepción se propaga y deja la
transacción PostgreSQL en estado fallido hasta que el llamador ejecute
`ROLLBACK` o vuelva a un `SAVEPOINT`. Los contadores se reservan con bloqueo y
`UPDATE ... RETURNING`; si la transacción exterior se revierte, también se
revierte la reserva. Esto es más atómico, pero puede diferir del contador ya
confirmado por una rutina MariaDB.

## Decisiones y defectos conocidos

Correcciones deliberadas de la migración:

- Las fechas cero incompatibles se representan con el centinela
  `1970-01-01 00:00:00`; 213 `NULL` explícitos incompatibles con `NOT NULL` se
  sustituyen de forma dirigida por `DEFAULT`.
- Los BLOB se cargan como `bytea` y se conservan sus bytes; las barras
  invertidas de las rutas mantienen su valor, no su escape textual MariaDB.
- Los contadores evitan las carreras de `IF NOT EXISTS` más
  `INSERT/UPDATE` mediante primitivas atómicas de PostgreSQL.
- `prc_get_iva_zona_fecha` corrige los identificadores obsoletos del origen,
  aplica el intervalo de vigencia y asigna el indicador de encontrado.
- `prc_get_numero_menor_mil` conserva correctamente los casos especiales
  0, 1 y 100 que el `SET` final del origen sobrescribía.
- Las llamadas internas deben usar la aridad PostgreSQL completa; en
  particular, el origen llamaba dos veces a
  `sp_recalcular_pmp_sku_almacen` con dos argumentos aunque declaraba tres.

Deuda heredada que exige pruebas funcionales:

- `prc_calcular_factura_netos` está incompleta en el volcado fuente: declara
  un cursor que no usa y contiene marcadores de lógica omitida. La migración no
  puede reconstruir reglas de negocio ausentes; facturación y proformas deben
  compararse contra casos reales antes de pasar a producción.
- Algunas entradas se conservan por compatibilidad aunque el origen no las
  utiliza, como `p_usuario` en la generación de vales y el recargo en la rutina
  de empresa.
- La semántica histórica del PMP requiere contraste: el origen sobrescribe o
  ignora `p_fecha_desde` en una rutina y no siempre alimenta la misma columna de
  coste que después lee el recálculo.
- Las dos consultas pivotadas conservan un resultado dinámico mediante cursor;
  no son intercambiables con un dataset de forma fija.
- No se añaden claves foráneas que no existían en el volcado original y los
  `ORDER BY` superiores de las vistas se omiten; cada consumidor debe ordenar
  explícitamente.

El smoke test valida presencia e inventario, no la corrección económica de
estas reglas. La aceptación requiere pruebas de concurrencia, facturación,
inventarios, PMP, perfiles y ambos pivotes desde los adaptadores reales.
