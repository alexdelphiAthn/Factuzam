# Fase 6T — creación de la tabla principal

Fecha: 27/07/2026. D1.4 y vigésimo fascículo de D1 terminados.
Sin commit realizado por Codex.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Ocho `CrearTablaPrincipal` | 390 | 314 | -76 |
| Fachada `inLibColumnasDocumento` | 950 | 1.008 | +58 |
| Total productivo de 6T | 1.340 | 1.322 | **-18** |

La reducción neta del alcance es del 1,3 %. Aunque este fascículo añade
la abstracción reutilizable, no incrementa el código productivo. El
contador global de la aplicación pasa de 308.927 líneas al cerrar 6S a
308.785 líneas en el estado compilado de 6T. Esta diferencia global
incluye el estado concurrente del árbol; el balance atribuible y
reproducible de D1.4 es el de la tabla.

## Implementación

`inLibColumnasDocumento` incorpora dos colaboradores:

- `AsegurarDataModuleDocumento` reutiliza el DataModule creado por
  `TfrmMtoGen` o crea la instancia concreta cuando falta. También
  rechaza de forma explícita una clase incompatible;
- `ConfigurarTablaPrincipalDocumento` enlaza la cabecera con
  `unqryTablaG`, empuja su `DataSource` al DataModule, conecta la vista
  de líneas, configura los `MasterSource` adicionales y establece la
  clave de navegación cuando procede.

Pedidos, albaranes y facturas de venta, inventarios y pedidos,
albaranes, facturas y devoluciones de compra reutilizan ambos
colaboradores. Se conserva en cada formulario lo que no es común:

- callbacks, fuentes auxiliares, selección de vista y preparación
  fiscal/Verifactu de facturas de venta;
- actualización del lookup de empresa y su guarda de creación en
  inventarios;
- consultas de movimientos, efectos y documentos relacionados propias
  de cada familia;
- claves compuestas y prefijos de campos específicos de cada documento.

La extracción no modifica `SqlRestriccionUsuario` ni las reglas de
empresa y almacén. Ese comportamiento sigue siendo el siguiente y
último bloque delicado de D1.

## Pruebas automáticas

Se añaden tres pruebas DUnitX sin BBDD:

1. creación, propiedad y reutilización de una instancia concreta;
2. rechazo de un objeto de una clase incompatible;
3. cableado de cabecera, vista de líneas, consultas detalle y clave.

El proyecto de pruebas declara `UniDataGen` y su directorio de búsqueda
porque la fachada productiva usa ahora el tipo base `TdmBase`.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 73/73 | 0 | 0 |
| Debug / Win32 | 0 errores | 73/73 | 0 | 0 |
| Release / Win64 | 0 errores | 73/73 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de modificar las pruebas.
La aplicación principal Release/Win64 se reconstruyó con Delphi 37:
0 errores, 308.785 líneas y 26,44 segundos.

En las dos compilaciones Debug de DUnitX aparece el aviso previo H2077
de `inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6T no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas Pascal dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check` sin errores.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir los ocho documentos y confirmar que todos cargan sin error de
   clase del DataModule.
2. Navegar por cabeceras y comprobar que la vista de líneas sigue el
   documento activo.
3. Verificar en cada documento las consultas relacionadas: albaranes,
   facturas, movimientos, efectos o documentos de origen.
4. Probar búsqueda, alta y edición usando la clave compuesta propia de
   cada formulario.
5. En facturas de venta, repetir con los modos clásico, SKU y tallas y
   comprobar callbacks, series y preparación fiscal/Verifactu.
6. En inventarios, cambiar de empresa y confirmar que se actualizan el
   lookup, almacén y líneas sin refresco recursivo.
7. Repetir pedidos, albaranes, facturas y devoluciones de compra con un
   usuario restringido y confirmar que empresa y almacén visibles no
   cambian respecto a 6S.
