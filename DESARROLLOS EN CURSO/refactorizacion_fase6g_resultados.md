# Fase 6G — configuración del pivote por bandas (resultados)

Fecha: 27/07/2026. Séptimo fascículo de D1 terminado. Sin commit.

## Selección del alcance

Los cuatro bloques `TGridPivoteVentaConfig` derivaban los mismos campos de
cabecera y línea. Sus diferencias reales son la semántica de las bandas y
se mantienen en cada formulario.

No se han movido:

- la elección entre bandas, tallas inline y modo genérico;
- la recepción de pedidos y el rótulo «A recibir»;
- la banda única y el campo de total de unidades;
- los callbacks de creación de línea y cambio de banda;
- las transacciones, la reentrada y la degradación a SKU.

## Implementación

`CrearConfigPivoteBandasDocumentoCompra` recibe conexión, usuario, fuentes,
prefijos, campo de precio y máximo de columnas. A partir de esos datos
genera:

- serie y número de cabecera;
- línea, artículo, SKU, descripción y tipo de cantidad;
- cantidad pedida y precio base;
- almacén de línea y almacén de cabecera;
- límite de columnas.

El registro se inicializa a cero. Por tanto, recepción, cantidad a servir,
texto de banda, total del grupo, modo de banda y callbacks solo aparecen
cuando el formulario los asigna expresamente.

Albaranes, devoluciones y facturas conservan `BandaUnica=True`,
`FieldTotalUdsGrupo` y sus callbacks. Pedidos conserva los campos de
cantidad recibida y a recibir, `BandaUnica=False`, el texto «A recibir» y
sus callbacks.

Los cuatro bloques pasan de 118 a 70 líneas: reducción de 48 líneas en los
formularios.

## Pruebas automáticas

Se añade un caso a `TPruebasColumnasDocumento` que comprueba:

1. derivación completa de los campos por prefijo;
2. conservación del campo de precio recibido;
3. máximo de columnas;
4. ausencia inicial de recepción, total de grupo y callbacks.

La batería DUnitX pasa de 35 a 36 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 36/36 | 0 | 0 |
| Debug / Win32 | 0 errores | 36/36 | 0 | 0 |
| Release / Win64 | 0 errores | 36/36 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.845
líneas en 11,48 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6G no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- asignaciones base anteriores dentro de los formularios: 0 referencias;
- reglas específicas y callbacks locales: presentes en los cuatro;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En albaranes, devoluciones y facturas de compra:

1. abrir tallas horizontales por bandas;
2. comprobar una sola banda de cantidad;
3. editar cantidades de varias tallas;
4. confirmar el total de unidades del grupo;
5. crear una combinación SKU desde el pivote;
6. volver a SKU y desglose sin dejar columnas o eventos anteriores.

En pedidos:

1. comprobar las bandas Pedido, A recibir y Pendiente;
2. editar «A recibir» y confirmar el límite por pendiente;
3. verificar cantidades recibidas y pendientes;
4. cambiar entre bandas e inline;
5. navegar entre cabeceras y comprobar la reconstrucción.

El siguiente candidato 6H es centralizar
`MostrarColumnasAtributoGlobales*`. Los cuatro métodos repiten la misma
consulta y el mismo recorrido por columnas; solo cambian la conexión y la
vista.
