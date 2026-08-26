# Benchmark MariaDB frente a PostgreSQL

Fecha: 2026-08-26 07:30:18 +02:00

Carga por motor y pasada: 1000 articulos + 1000 movimientos. Pasadas: 1; rondas de lectura: 1.

El runner usa UniDAC Win64, una conexion persistente sin pooling para las operaciones y SSL desactivado en ambos motores. Las bases son temporales y el esquema, indices y datos son equivalentes.

| Metrica | MariaDB us/op | PostgreSQL us/op | Mejor | Factor |
| --- | ---: | ---: | --- | ---: |
| actualizacion_stock | 61.980 | 71.510 | MariaDB | 1.154x |
| agregado_ventas | 591.000 | 769.000 | MariaDB | 1.301x |
| busqueda_pk | 95.960 | 172.890 | MariaDB | 1.802x |
| carga_articulos | 65.279 | 70.905 | MariaDB | 1.086x |
| carga_movimientos | 58.309 | 101.547 | MariaDB | 1.742x |
| conexion | 534.900 | 45939.300 | MariaDB | 85.884x |
| listado_filtrado | 193.700 | 223.700 | MariaDB | 1.155x |

## Configuracion observada

- MariaDB: buffer=2095054848 bytes; innodb_flush_log_at_trx_commit=1;sync_binlog=0.
- PostgreSQL: buffer=134217728 bytes; fsync=on;synchronous_commit=on;full_page_writes=on.

Advertencia: esta primera prueba refleja la configuracion instalada. MariaDB y PostgreSQL no tienen asignada la misma memoria de cache, por lo que los numeros no deben interpretarse como una comparacion absoluta de los motores.

Duracion total: 1.67 s.
