# Resultado de la fase SQL-2.3c

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.3c extrae las diez construcciones SQL de
`src/Caja/Lib/inLibTiraCajaTicket.pas`. No modifica el esquema de la BBDD
ni `factuzam_original.sql`.

El registro central contiene 73 definiciones:

- 70 lecturas personalizables con fallback al SQL base;
- una comprobación técnica de esquema `pesSoloBase`;
- dos escrituras de Facturas `pesSoloBase`.

## Contrato y repositorio

El contrato `IRepositorioTiraCajaTicket` expone read models para:

- cabecera de empresa;
- líneas de venta y formas de pago;
- líneas de traspaso y depósitos;
- operaciones de la tira;
- series facturadas del rango.

La implementación `UniDataTiraCajaTicketRepositorio` registra siete
lecturas con política `pesPerfilLecturaConFallback`.

## Diez construcciones, siete definiciones

Las diez construcciones originales contenían tres duplicados: Excel repetía
las consultas de líneas de venta, traspasos y depósitos que ya utilizaba el
ticket térmico. Ambos formatos consumen ahora los mismos métodos del
repositorio.

El cursor maestro también es único. Sus variantes dejan de concatenar
placeholders y tipos de operación. La definición estable usa:

- `:pTODAS_SERIES` y `:pSERIES`;
- `:pINCLUIR_TRASPASOS`;
- `:pINCLUIR_INGRESOS`;
- `:pINCLUIR_GASTOS`;
- `:pINCLUIR_CREDITO`;
- `:pCRONOLOGICO`.

Por tanto, todas las combinaciones conservan una única clave:

```text
KEY_USUPER=SQL_REPOSITORIOS
SUBKEY_USUPER=SQL__RepositorioTiraCajaTicket__ListarOperaciones
```

## Separación de responsabilidades

`inLibTiraCajaTicket` conserva la composición del ticket térmico, la
previsualización y la exportación Excel. Ya no depende de `Uni`, `Data.DB`,
tablas ni campos físicos.

`TfrmModalArqueo` crea un repositorio con el catálogo de la pantalla y lo
reutiliza para listar series, imprimir y exportar. Las tres rutas respetan
el interruptor `oGetSQLFromDB` de la pantalla.

El formato de documento se incorpora al read model maestro. Así la librería
puede aplicar `FormatearDocumento` sin consultar la BBDD.

## Fallback

Las siete operaciones:

1. validan tipo, parámetros y campos obligatorios;
2. registran una incidencia si el perfil es inválido o falla;
3. repiten una sola vez con el SQL base;
4. propagan la excepción si también falla el SQL base.

## Reducción de SQL en dominio

| Métrica | SQL-2.3b2 | SQL-2.3c | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 67 | 66 | -1 |
| Construcciones SQL | 341 | 331 | -10 |
| `SELECT` | 234 | 224 | -10 |

El techo de `scripts/comprobar_sql_en_dominio.ps1` queda en 331
construcciones y 66 unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3c.csv`.

## Pruebas

SQL-2.3c añade cinco pruebas DUnitX para cubrir:

- las siete definiciones y sus políticas;
- los filtros estables del cursor maestro;
- la consolidación de detalles entre ticket y Excel;
- el rechazo de un perfil sin campos obligatorios;
- el reintento con SQL base ante un error de ejecución.

La aplicación y `FactuzamTests.dproj` compilan en Win64 Debug y Release.
Las dos ejecuciones DUnitX encuentran 304 pruebas y pasan las 304, sin
errores, fallos, ignoradas ni fugas.

También pasan los controles de SQL en dominio, dependencias de capa,
acoplamiento y flujos largos.

## Siguiente fase

SQL-2.3d debe continuar con las lecturas restantes de tickets y Caja. Las
escrituras de cierre y persistencia permanecen fuera de alcance hasta
definir límites transaccionales y pruebas de rollback.
