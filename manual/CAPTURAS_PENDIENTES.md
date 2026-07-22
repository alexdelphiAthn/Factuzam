# Capturas pendientes añadidas en esta revisión

Las capturas de esta revisión ya incorporadas se guardan en `manual/img/`.
Al regenerar el HTML, se copian automáticamente a `manual/html/img/`.

En la última tanda se incorporaron 20 capturas (Ctrl+E, Documentos de
Trabajo, menú Otros, Ventas Mayor, históricos de Caja, Inventarios,
Balance horizontal, Acerca de y acciones Verifactu) y se eliminaron sus
avisos «▢ Captura pendiente» de los capítulos.

Siguen pendientes (no se pudieron automatizar):

| Fichero | Qué debe verse | Motivo |
|---------|----------------|--------|
| `07-copia-seguridad.png` | Diálogo de copia de seguridad. | Diálogo estándar de Windows; el recortador lo enmascara. |
| `07-generador-listado.png` | Pestaña VistaDatos con un resultado. | Requiere ejecutar un proceso; no se ejecutó SQL por prudencia. |
| `09-primer-login.png` y `09-subir-script.png` | Pantalla de login. | Invocar el login podía cerrar la sesión de la app. |
| `10-migrator-preparar.png` | Sección Preparar BBDD destino del Migrator. | Es una aplicación aparte (utilmigsqlsrv). |
| `06-inventarios-recuento-movil.png` | *Colocada*: misma vista que `06-inventarios.png` (la ficha muestra los botones Enviar/Recoger recuento móvil). | — |

Para localizar los huecos restantes:

```bat
rg "Captura pendiente" manual\*.md
```
