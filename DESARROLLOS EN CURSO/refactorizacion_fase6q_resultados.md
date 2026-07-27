# Fase 6Q — construcción común de modos de documento (resultados)

Fecha: 27/07/2026. Decimoséptimo fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Ocho métodos `ConstruirModoEntrada` | 903 | 767 | -136 |
| Fachada `inLibColumnasDocumento` | 635 | 686 | +51 |
| Referencias `inLibLog` ya innecesarias | 2 | 0 | -2 |
| Total productivo de 6Q | 1.540 | 1.453 | **-87** |

El código productivo del alcance baja un 6 %. La batería DUnitX crece
para cubrir el contrato común, pero sus líneas quedan fuera de estas
cifras. El contador global del compilador tampoco se usa para medir la
fase porque el árbol contiene cambios concurrentes de traducción y
rectificativas.

## Implementación

`inLibColumnasDocumento` incorpora dos operaciones comunes:

- `DesmontarModoEntradaDocumento`, que cierra el editor, cancela una
  edición pendiente, desmonta el modo, libera sus eventos y columnas y
  anula la interfaz;
- `ConstruirModoEntradaDocumento`, que conecta los tres callbacks del
  host, construye el modo y solo transforma una excepción en degradación
  a SKU cuando el llamador ha declarado expresamente ese modo como
  degradable.

`PrepararReconstruccionModoDocumento` conserva su contrato para compra y
delega ahora el desmontaje en la primera operación.

Los ocho consumidores usan la construcción común:

- pedidos, albaranes y facturas de venta;
- inventarios;
- pedidos, albaranes, facturas y devoluciones de compra.

Albaranes y facturas de venta e inventarios reutilizan además el
desmontaje común. Pedidos de venta mantiene su variante defensiva porque
también suspende actualizaciones, desacopla temporalmente el `DataSource`
y tolera errores de foco y repintado.

Se conservan las diferencias reales:

- pedidos crea las columnas host antes del pivote por bandas y después
  en el resto de modos;
- facturas conserva la presentación clásica y el aislamiento temporal
  de los eventos del data module;
- inventarios conserva el guardián de conversión, sus campos especiales
  y la restauración del editor;
- pedidos de compra degrada tanto tallas inline como bandas;
- los otros tres documentos de compra solo degradan las bandas;
- las excepciones de modos no autorizados para degradar siguen
  propagándose.

## Pruebas automáticas

Se añaden tres pruebas sin BBDD:

1. la construcción común conecta y ejecuta los tres callbacks;
2. un fallo en un modo declarado degradable devuelve el control al host;
3. un fallo en un modo no degradable conserva la excepción.

La batería actual incluye además pruebas concurrentes ajenas a 6Q:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 57/57 | 0 | 0 |
| Debug / Win32 | 0 errores | 57/57 | 0 | 0 |
| Release / Win64 | 0 errores | 57/57 | 0 | 0 |

La aplicación principal Release/Win64 compila con Delphi 37 con 0
errores: 308.999 líneas en 11,00 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6Q no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes modificadas en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `git diff --check` sin errores en los archivos de la fase;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. En pedidos de venta, alternar SKU, desglose y bandas comprobando que
   no cambia el orden de las columnas host.
2. En albaranes de venta, alternar SKU, desglose y tallas inline.
3. En facturas normales y simplificadas, comprobar modos SKU, desglose,
   bandas y presentación clásica.
4. En inventarios, alternar SKU y desglose, editar una cantidad física y
   comprobar que el editor recupera el foco.
5. En los cuatro documentos de compra, alternar los modos admitidos y
   verificar que no se pierden cantidades al desmontar.
6. Confirmar que Enter llega a los editores de SKU y atributos y que al
   salir se restaura el comportamiento Enter-como-Tab.
7. Forzar, en un entorno de prueba, un fallo de construcción del pivote y
   comprobar la degradación a SKU y su entrada en el log.
