# Paquetes de traducción

Este directorio es privado y no debe publicarse directamente por el servidor
web. `catalogo.php` declara los idiomas disponibles, su versión y el orden en
que Factuzam debe ejecutar los SQL de cada paquete.

El endpoint público es:

```text
GET /api/v1/traducciones/descargar.php?idioma=zh-CN
Authorization: Bearer <token>
Ámbito requerido: descargar:traducciones
```

La respuesta correcta es un ZIP con los SQL y `manifiesto.json`. El
manifiesto incluye el orden, tamaño y SHA-256 de cada SQL. Los errores usan el
contrato JSON común del webservice.

Para publicar una versión nueva se añaden los SQL idempotentes al directorio
del idioma, se actualiza su lista en `catalogo.php` y se incrementa `version`.
