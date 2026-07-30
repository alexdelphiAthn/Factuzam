# Resultado de la fase SQL-2.3a

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.3a está terminada. No modifica el esquema de la BBDD ni
`factuzam_original.sql`.

Las seis construcciones SQL que utilizaba `inLibTraspasoTicket` han
salido de la capa de dominio. Las dos copias de la lectura de stock se
han unificado, por lo que el registro central incorpora cinco
operaciones nuevas y contiene ahora 45 definiciones:

- 43 lecturas personalizables con fallback al SQL base;
- dos escrituras de Facturas que permanecen `pesSoloBase`.

## Contrato y repositorio

El contrato `IRepositorioTraspasoTicket` vive en
`src/Caja/Lib/inLibTraspasoTicketIntf.pas`. No expone conexiones,
consultas UniDAC ni nombres de tabla.

La implementación concreta vive en
`src/Caja/DataModules/UniDataTraspasoTicketRepositorio.pas` y registra:

1. `ObtenerSolicitud`;
2. `ListarLineasSolicitud`;
3. `ObtenerStock`;
4. `ObtenerTraspasoHistorico`;
5. `ListarLineasTraspaso`.

Todas son lecturas con política `pesPerfilLecturaConFallback`.

La consulta histórica incorpora el formato de documento de la empresa
en la misma lectura. Así la composición del ticket puede utilizar la
función pura `FormatearDocumento` sin recibir una conexión ni hacer una
segunda consulta fuera del repositorio.

## Separación de responsabilidades

`inLibTraspasoTicket` conserva exclusivamente:

- la composición visual del ticket térmico;
- el recorrido de las líneas que ya están en memoria;
- la impresión, previsualización y generación del PDF.

La unidad ya no contiene SQL ni depende de UniDAC. Recibe
`IRepositorioTraspasoTicket` y trabaja con records y arrays del contrato.

Los consumidores migrados son:

- mantenimiento de traspasos;
- consulta y reimpresión de operaciones;
- envío por correo desde la consulta de operaciones;
- envío por correo desde Caja.

## Activación por pantalla

`TfrmBase` ofrece `CrearRepositorioTraspasoTicket`. La factoría reutiliza
el catálogo y el registro de incidencias de la pantalla consumidora.

Con `oGetSQLFromDB=True`, las cinco operaciones buscan sus definiciones
compartidas bajo:

```text
KEY_USUPER=SQL_REPOSITORIOS
SUBKEY_USUPER=SQL__RepositorioTraspasoTicket__<Operacion>
```

Con `oGetSQLFromDB=False`, no se carga `SQL_REPOSITORIOS` y las cinco
operaciones usan directamente el SQL base incluido en el ejecutable.

La ruta de correo recibe el mismo repositorio creado por la pantalla. No
decide por sí sola si debe utilizar perfiles.

## Fallback

Ante un perfil inválido, un error al abrir la consulta o la ausencia de
campos obligatorios:

1. se registra la incidencia;
2. se descarta el resultado personalizado;
3. se repite una sola vez con el SQL base;
4. si falla también el SQL base, se propaga la excepción.

La regla es segura porque las cinco operaciones son de lectura.

## Reducción de SQL en dominio

| Métrica | SQL-2.2 | SQL-2.3a | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 72 | 71 | -1 |
| Construcciones SQL | 475 | 469 | -6 |
| `SELECT` | 306 | 300 | -6 |
| `INSERT` | 66 | 66 | 0 |
| `UPDATE` | 48 | 48 | 0 |
| `DELETE` | 39 | 39 | 0 |
| `REPLACE` | 0 | 0 | 0 |
| `CALL` | 4 | 4 | 0 |
| DDL | 12 | 12 | 0 |

El techo predeterminado de
`scripts/comprobar_sql_en_dominio.ps1` queda en 469 construcciones y 71
unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3a.csv`.

## Pruebas y compilación

SQL-2.3a añade pruebas para cubrir:

- las cinco definiciones y sus políticas;
- el alias estable de la lectura de stock;
- una personalización válida con clave compartida;
- el rechazo de un perfil sin campos obligatorios;
- el reintento con SQL base ante un error de ejecución.

Las ejecuciones Win64 Debug y Release encuentran 272 pruebas y pasan las
272. La aplicación y el proyecto de pruebas compilan en ambas
configuraciones usando salidas aisladas bajo `build/validacion_sql23`.

## Siguiente fase

SQL-2.3b debe continuar con las consultas de arqueo y tira de caja. Las
escrituras de cierre y persistencia permanecen fuera de alcance hasta
definir sus límites transaccionales y pruebas de rollback.
