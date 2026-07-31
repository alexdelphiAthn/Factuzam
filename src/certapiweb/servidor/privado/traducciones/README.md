# Paquetes de traducción

Este directorio es privado y no debe publicarse directamente por el servidor
web. `catalogo.php` declara los idiomas disponibles, su versión y el orden en
que Factuzam debe ejecutar los SQL de cada paquete.

El endpoint público es:

```text
GET /api/v1/traducciones/descargar.php?idioma=en-GB
Authorization: Bearer <token>
Ámbito requerido: descargar:traducciones
```

La respuesta correcta es un ZIP con los SQL y `manifiesto.json`. El
manifiesto incluye el orden, tamaño y SHA-256 de cada SQL. Los errores usan el
contrato JSON común del webservice.

Para publicar una versión nueva se añaden los SQL idempotentes al directorio
del idioma, se actualiza su lista en `catalogo.php` y se incrementa `version`.
El primer archivo debe ser siempre `000_preparar_descarga.sql`; el cliente lo
comprueba antes de ejecutar el paquete. Los SQL posteriores contienen los
datos y se ejecutan dentro de una transacción.

`zh-CN` versión 3 prepara primero la marca de descarga, ejecuta la prueba
revisada del menú principal y termina con `002_catalogo_completo.sql`, que
contiene las 7.470 claves activas generadas desde `utlTraduc`. Las filas se
marcan como descargadas para que la copia de seguridad pueda distinguirlas.
El catálogo automático queda pendiente de revisión visual.

`en-GB` versión 1 contiene las 6.961 filas inglesas y `ca-ES` versión 1
contiene las 7.442 filas catalanas exportadas desde la BBDD. Ambos paquetes
preparan primero la marca de descarga y aplican después el catálogo completo.
Al ejecutarlos, las filas quedan marcadas para incluirse en futuras copias de
seguridad.
