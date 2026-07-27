# Fase 6D — configuración común del gestor y pivote (resultados)

Fecha: 27/07/2026. Cuarto fascículo de D1 terminado. Sin commit.

## Selección del alcance

Se compararon los dos candidatos indicados al cerrar 6C:

- `InicializarGestorYPivote`, con 83–90 líneas por formulario y una estructura
  prácticamente idéntica;
- `ConstruirModoEntrada`, con 151–202 líneas y diferencias relevantes en
  transacciones, reentrada, degradación a SKU y tipos de pivote.

6D centraliza únicamente `InicializarGestorYPivote`. Extraer el segundo método
completo habría ocultado reglas específicas de cada documento.

## Implementación

`TConfigPivoteDocumentoCompra` recoge los objetos y prefijos que cambian entre
pedidos, albaranes, devoluciones y facturas. A partir de ellos,
`inLibColumnasDocumento` genera:

- `TGridTallasConfig`;
- `TGridPivoteCompraConfig`;
- nombres de tablas y campos de cabecera, línea y celda;
- campos ocultos del pivote;
- configuración opcional de cantidad recibida y color del proveedor;
- eventos de edición y validación de las columnas de talla.

Cada formulario conserva:

- la conexión y los data sources concretos;
- sus prefijos `PEDC`, `ALBC`, `DEVC` o `FACC`;
- la creación y propiedad de `TGestorGridTallas` y `TGridPivoteCompra`;
- la comprobación condicional de `COLOR_TEXTO_PEDCLIN`.

Se ha preservado la ausencia histórica de `ContextoSesion` en el pivote de
devoluciones mediante `AplicarContextoPivote=False`. Cambiar ese contrato
requiere una decisión separada.

La asignación repetida dos veces de `FieldCantidadRecibida` en pedidos se
reduce a una sola derivación, con el mismo valor final.

Respecto al cierre de 6C, los formularios pierden 321 líneas y reciben 139
líneas de configuración explícita: reducción neta de 182 líneas en las cuatro
clases.

## Pruebas automáticas

Se añaden cuatro casos a `TPruebasColumnasDocumento`:

1. derivación de campos y tabla de celdas para el gestor;
2. derivación de campos básicos y ocultos del pivote;
3. particularidades de recepción y color de pedidos;
4. asignación de eventos a las columnas numéricas.

La batería DUnitX pasa de 26 a 30 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 30/30 | 0 | 0 |
| Debug / Win32 | 0 errores | 30/30 | 0 | 0 |
| Release / Win64 | 0 errores | 30/30 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.788 líneas
en 10,89 segundos.

Al compilar DUnitX aparece el aviso previo H2077 de `inLibLog.pas`: el valor
asignado a `bSQLFinal` no se usa. La nueva dependencia del pivote hace que esa
unidad se compile dentro del proyecto de pruebas; 6D no modifica ese código.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- configuración duplicada anterior: 0 referencias;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En cada uno de los cuatro documentos:

1. abrir el modo de tallas y editar una cantidad;
2. comprobar validación, persistencia y recálculo de totales;
3. activar y desactivar el pivote varias veces;
4. navegar entre documentos y confirmar que no quedan eventos del gestor
   anterior;
5. cerrar y reabrir el formulario para verificar la liberación de ambos
   colaboradores.

En pedidos debe comprobarse además:

1. cantidades pedida, recibida y pendiente;
2. campos ocultos al expandir el pivote;
3. color del proveedor con y sin `COLOR_TEXTO_PEDCLIN`.

El siguiente candidato 6E es extraer las partes realmente comunes de
`ConstruirModoEntrada`: teardown del grid y configuración base de
`TConfigColumnasSku`. La transacción y la degradación a SKU deben permanecer
en cada formulario.
