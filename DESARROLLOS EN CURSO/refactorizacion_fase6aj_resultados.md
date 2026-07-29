# Fase 6AJ — cálculo de líneas y cierre de `inLibtb`

Fecha: 29/07/2026. D3.9, noveno y último fascículo. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 377 | 0 | **-377** |
| `inLibFacturas` | 1.436 | 1.527 | +91 |
| `inLibDevExp` | 1.239 | 1.241 | +2 |
| Siete consumidores restantes | 9.885 | 9.878 | **-7** |
| Total productivo del alcance | 12.937 | 12.646 | **-291** |

El alcance productivo se reduce un **2,2 %**. Las modificaciones de
pruebas quedan excluidas.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 0 líneas, **-1.523 (-100 %)**;
- suma de los balances productivos declarados en D3.1-D3.9:
  **-912 líneas**;
- dependencias de unidad sobre `inLibtb`: 50 a 0;
- D3 queda terminado: 9 de 9 fascículos.

## Implementación

La única lógica propia que quedaba en la fachada,
`ActualizarLineaFacturaGen`, pasa a `inLibFacturas` con el nombre
`ActualizarLineaFactura`. Comparte ya la unidad con las dos clases que
realizan el trabajo:

- `TLinFac`, para recalcular la línea;
- `TFacturaTotales`, para reagregar y grabar los totales.

El callback se llama `TActualizarTotalFacturaEvent` y también vive en
`inLibFacturas`. `inLibDevExp.GridRecalc` conserva el contrato y delega
en la función especializada. Las dos llamadas directas de
`inMtoFacturasBase` usan igualmente la nueva ubicación.

Se conserva el comportamiento anterior:

- no se actúa sin dataset de líneas activo y modificable;
- la línea entra en edición si estaba en navegación;
- se admiten precio, cantidad, porcentaje o importe de descuento,
  precios con y sin IVA, tipo de IVA y totales editados;
- editar un total deriva el descuento unitario;
- la línea se copia al dataset antes de reagregar la cabecera;
- un fallo de `ProcesarFacturaCompleta` sigue lanzando una excepción;
- el callback recibe el nuevo total líquido.

## Retirada de la fachada

Se elimina `src/Lib/inLibtb.pas` y sus referencias de los proyectos.
También se retiran seis `uses` muertos de formularios y librerías.

No queda ninguna dependencia Pascal ni referencia de los proyectos
activos a la unidad. Se conserva únicamente el literal `'inLibtb'` dentro de
`inLibCadenas`: es la clave histórica usada para leer el perfil
persistido `oSimbolosProhibidos`, no una dependencia de código.
Cambiarla rompería configuraciones existentes.

Las pruebas dejan de duplicar aserciones contra la fachada eliminada.
Salen dos casos dedicados exclusivamente a compatibilidad de fachada y
se añade una salvaguarda de `ActualizarLineaFactura` sin dataset.

## Pruebas automáticas

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 161/161 | 0 | 0 |
| Debug / Win32 | 0 errores | 161/161 | 0 | 0 |
| Release / Win64 | 0 errores | 161/161 | 0 | 0 |
| Release / Win32 | 0 errores | 161/161 | 0 | 0 |

La aplicación se reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d39/Win64/Release`: 0 errores, 311.067 líneas y
11,02 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.9 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- ninguna referencia de unidad o proyecto a `inLibtb`;
- ninguna referencia a `ActualizarLineaFacturaGen`;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas añadidas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check` limitado al alcance de D3.9;
- comprobadores históricos actualizados para leer las unidades
  especializadas en lugar del fichero retirado;
- `factuzam_original.sql` intacto.

Los comprobadores históricos de contexto y conexión ya no fallan por
intentar abrir `inLibtb`; sus controles sobre el contador migrado pasan.
Esas baterías conservan fallos funcionales previos de sus propias fases
y no forman parte del criterio de aceptación de D3.9.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Editar precio, cantidad y descuentos en una factura de venta.
2. Editar los precios con y sin IVA y cambiar el tipo de IVA.
3. Editar el total con IVA y sin IVA y comprobar el descuento unitario.
4. Añadir una referencia de catálogo y otra no catalogada.
5. Repetir las ediciones de línea desde caja.
6. Comprobar que cabecera, pie y callback muestran el total líquido.
7. Guardar, cerrar y reabrir el documento para verificar persistencia.

D3 queda **cerrado: 9 de 9 fascículos**. El siguiente bloque es D4:
trocear los métodos largos.
