# Capturas del manual completadas

Las capturas de esta revisión ya incorporadas se guardan en `manual/img/`.
Al regenerar el HTML, se copian automáticamente a `manual/html/img/`.

En esta revisión se incorporaron las 17 capturas que faltaban y, después,
las salidas reales del resumen de arqueo, la tira de caja y el listado de
documentos de proveedor. También se enlazó la captura de recuento que ya
existía, además de la salida del balance horizontal de almacén. El cotejo
actual contiene 118 referencias de imagen y las 118
existen en `manual/img/`.

Las pantallas de historial, seguimiento, script y actualización usan datos
ficticios marcados como demostración. No se ejecutó el script, no se descargó
ni instaló ninguna actualización y no se envió ninguna incidencia.

Para comprobar que no reaparecen huecos:

```bat
rg "▢ Captura pendiente" manual -g "*.md" -g "!MANTENIMIENTO.md" -g "!CAPTURAS_PENDIENTES.md"
```
