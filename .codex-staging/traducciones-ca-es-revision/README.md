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

`zh-CN` versión 4 prepara primero la marca de descarga, ejecuta la prueba
revisada del menú principal, carga `002_catalogo_completo.sql`, con las 7.470
claves activas generadas desde `utlTraduc`, y aplica al final la revisión
visual de caja de `003_ajustes_interfaz_caja.sql`. Las filas se marcan como
descargadas para que la copia de seguridad pueda distinguirlas. El catálogo
automático restante queda pendiente de revisión visual.

`en-GB` versión 1 contiene las 6.961 filas inglesas. `ca-ES` versión 2 parte
de las 7.442 filas catalanas exportadas desde la BBDD y aplica después una
revisión lingüística incremental. Esta revisión incorpora las claves nuevas,
conserva los saltos de línea de los mensajes y cubre los textos de rejilla sin
datos. Ambos paquetes preparan primero la marca de descarga y aplican después
el catálogo. Al ejecutarlos, las filas quedan marcadas para incluirse en
futuras copias de seguridad.
