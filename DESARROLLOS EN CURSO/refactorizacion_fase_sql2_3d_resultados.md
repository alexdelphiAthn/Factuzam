# Resultado de la fase SQL-2.3d

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.3d extrae las catorce construcciones SQL de lectura de
`src/Lib/inLibGenerarTicketBD.pas` y hace explícitas las dos consultas
auxiliares usadas para resolver el pie de ticket. No modifica el esquema de
la BBDD ni `factuzam_original.sql`.

El registro central contiene 89 definiciones:

- 85 lecturas personalizables con fallback al SQL base;
- dos comprobaciones técnicas de esquema `pesSoloBase`;
- dos escrituras de Facturas `pesSoloBase`.

## Contrato y repositorio

El contrato `IRepositorioTicketsCaja` expone read models para:

- datos de empresa y fecha del resguardo;
- depósitos nuevos, entregas y devoluciones del resguardo;
- total pagado;
- cabecera, líneas, pagos, vales y pie del ticket;
- empresa, anticipos y depósitos pendientes del recordatorio.

La implementación `UniDataTicketsCajaRepositorio` registra quince lecturas
con política `pesPerfilLecturaConFallback` y una comprobación técnica con
política `pesSoloBase`.

## Catorce construcciones y dos dependencias auxiliares

Las catorce construcciones directas de `inLibGenerarTicketBD` se convierten
en catorce operaciones del repositorio. Además, el anterior helper del pie
de ticket ocultaba dos accesos:

1. la comprobación de las cuatro columnas opcionales del pie;
2. la lectura de sus valores para la empresa.

La comprobación de esquema no es configurable. Se ejecuta siempre con el
SQL base para impedir que un perfil simule capacidades inexistentes en la
BBDD. La lectura del pie sí admite perfil y solo se ejecuta cuando la
comprobación técnica confirma que las columnas existen.

La cabecera del ticket incorpora `FORMATO_DOCUMENTO_EMP` y
`DIMINUTIVO_TICKET_EMPL`. De este modo, la librería ya no realiza consultas
indirectas para formatear el documento ni obtener el nombre corto del
vendedor.

## Separación de responsabilidades

`inLibGenerarTicketBD` conserva la composición de resguardos, copias de
ticket y recordatorios. Ya no depende de UniDAC, `Data.DB`, tablas, campos
físicos ni sentencias SQL.

Los formularios y servicios crean o reciben `IRepositorioTicketsCaja` y lo
reutilizan en las rutas de impresión y correo. El repositorio recibe el
catálogo de la pantalla, por lo que el interruptor `oGetSQLFromDB` sigue
decidiendo si esa pantalla puede usar perfiles. Una misma clave de operación
puede compartirse entre varias pantallas; cada pantalla conserva su propio
interruptor.

Ejemplo:

```text
KEY_USUPER=SQL_REPOSITORIOS
SUBKEY_USUPER=SQL__RepositorioTicketsCaja__ObtenerCabeceraTicket
```

## Fallback

Las quince operaciones perfilables:

1. validan tipo, parámetros y campos obligatorios;
2. registran una incidencia si el perfil es inválido o falla;
3. repiten una sola vez con el SQL base;
4. propagan la excepción si también falla el SQL base.

Por tanto, un SQL de perfil erróneo no deja la operación sin consulta: se
usa el SQL incluido en el ejecutable.

## Reducción de SQL en dominio

| Métrica | SQL-2.3c | SQL-2.3d | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 66 | 65 | -1 |
| Construcciones SQL | 331 | 317 | -14 |
| `SELECT` | 224 | 210 | -14 |

El techo de `scripts/comprobar_sql_en_dominio.ps1` queda en 317
construcciones y 65 unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3d.csv`.

## Pruebas

SQL-2.3d añade cinco pruebas DUnitX para cubrir:

- las quince lecturas y la comprobación técnica;
- los datos de formato y vendedor de la cabecera;
- la política `pesSoloBase` de la comprobación del pie;
- el rechazo de un perfil sin campos obligatorios;
- el reintento con SQL base ante un error de ejecución.

La validación específica Win64 comprueba que las 16 definiciones son
válidas: 15 perfilables y una `solo-base`. Las cinco pruebas DUnitX de la
fase pasan, sin fallos, errores ni fugas.

También compila en Win64 el conjunto de integración formado por el
repositorio, el compositor y sus consumidores de Caja, consulta de
operaciones y correo.

La compilación completa de `fzam.dproj` y `FactuzamTests.dproj` queda
temporalmente bloqueada por el cambio concurrente de traducciones:
`inLibTraducciones.pas(208)` produce E2035. La guarda global de flujos
también se detiene antes de llegar a SQL-2.3d porque la tanda concurrente de
Verifactu no ofrece una implementación única de
`GuardarRegistroNoVerifactu`. Ninguno de los dos bloqueos pertenece a esta
fase.

## Siguiente fase

SQL-2.4 puede continuar con focos pequeños de Facturas y exportaciones. Las
escrituras de cierre y persistencia permanecen fuera de alcance hasta
definir límites transaccionales y pruebas de rollback.
