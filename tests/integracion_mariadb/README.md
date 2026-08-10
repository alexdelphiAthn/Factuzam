# Integración real con MariaDB (IA-S30)

Esta suite crea un esquema `fzam_it_*` distinto para cada prueba. No acepta
un nombre de base de datos de negocio y solo elimina esquemas cuyo nombre
cumple el prefijo y el formato aleatorio de la suite.

## Ejecución local desechable

Requiere Python 3, PyMySQL y una instalación local de MariaDB. El runner
inicializa una instancia en `%TEMP%`, la limita a `127.0.0.1`, ejecuta las
pruebas y elimina el directorio de datos en un bloque `finally`.

```powershell
powershell -NoProfile -File tests/integracion_mariadb/ejecutar_integracion_mariadb.ps1
```

`FACTUZAM_MARIADB_BIN` permite indicar el directorio `bin` de MariaDB si no
está instalado bajo `Program Files\MariaDB *`.

## Ejecución contra un servidor del runner

Solo se leen credenciales de estas variables de entorno:

- `FACTUZAM_TEST_DB_HOST`
- `FACTUZAM_TEST_DB_PORT`
- `FACTUZAM_TEST_DB_USER`
- `FACTUZAM_TEST_DB_PASSWORD`
- `FACTUZAM_TEST_DB_ALLOW_DISPOSABLE=SI`

Después se ejecuta:

```powershell
powershell -NoProfile -File tests/integracion_mariadb/ejecutar_integracion_mariadb.ps1 `
  -UsarServidorExterno
```

El usuario del runner necesita `CREATE`, `DROP`, `ALTER`, `CREATE VIEW` y
`CREATE ROUTINE`, además de DML sobre los esquemas desechables. No se deben
usar credenciales de producción.

## Migraciones consumidas

La prueba de idempotencia ejecuta los artefactos reales de IA-S01:
`albaranes_facturacion_procs.sql` y `pedidos_albaran_procs.sql`. En este
equipo se resuelven por defecto desde el repositorio histórico auxiliar.
En CI se indica su ubicación, separada por `;`, mediante
`FACTUZAM_IA_S01_MIGRATIONS`. La migración real de la cola se puede indicar
con `FACTUZAM_VERIFACTU_MIGRATION`.

La suite falla, no omite pruebas, si falta cualquiera de esos artefactos.
Los casos cubren idempotencia DDL, commit/rollback de cabecera y líneas,
fallo intermedio, contador concurrente con `FOR UPDATE`, cola VeriFactu,
operación y pago de caja, tipos MariaDB y limpieza ante una aserción.
