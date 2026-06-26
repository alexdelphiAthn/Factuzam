# Capturas pendientes faltantes en el manual

Documento generado comparando las referencias `img/...` de los capítulos del
manual con los ficheros existentes en `manual/img/`.

Solo se listan capturas que el manual referencia y cuyo fichero todavía no
existe en `manual/img/`. No incluye las capturas que ya están colocadas aunque
el texto del capítulo siga diciendo "Captura pendiente".

Resumen del cotejo:

| Métrica | Total |
|---------|-------|
| Imágenes referenciadas por el manual | 99 |
| Imágenes referenciadas que ya existen en `manual/img/` | 73 |
| Imágenes referenciadas que faltan en `manual/img/` | 26 |
| Ficheros de `manual/img/` sin referencia en el manual | 0 |

## Faltan todavía

| Capítulo | Línea | Fichero pendiente | Qué debe verse |
|----------|-------|-------------------|----------------|
| `04-menu-ventas-mayor.md` | 145 | `04-pedidos.png` | Pedidos de venta. |
| `04-menu-ventas-mayor.md` | 158 | `04-albaranes.png` | Albaranes de venta. |
| `04-menu-ventas-mayor.md` | 177 | `04-listado-ventas.png` | Filtros del listado de ventas. |
| `05-menu-caja.md` | 699 | `05-caja-formas-pago.png` | Mantenimiento de Formas de Pago Caja. |
| `05-menu-caja.md` | 738 | `05-caja-depositos.png` | Depósitos de Clientes. |
| `05-menu-caja.md` | 773 | `05-caja-hist-pagos.png` | Histórico de Pagos de Caja. |
| `05-menu-caja.md` | 790 | `05-caja-hist-vales.png` | Histórico de Vales. |
| `05-menu-caja.md` | 807 | `05-caja-hist-operaciones.png` | Histórico de Operaciones. |
| `05-menu-caja.md` | 824 | `05-caja-hist-arqueos.png` | Histórico de Arqueos. |
| `06-menu-almacen.md` | 30 | `06-movimientos.png` | Movimientos de almacén. |
| `06-menu-almacen.md` | 53 | `06-inventarios.png` | Inventario con su detalle de recuento. |
| `06-menu-almacen.md` | 85 | `06-inventarios-recuento-movil.png` | Inventarios con botones Enviar a recuento móvil y Recoger recuento móvil. |
| `06-menu-almacen.md` | 98 | `06-balance-horizontal.png` | Filtros e informe del balance con tallas. |
| `07-menu-otros.md` | 36 | `07-parametros.png` | Parámetros Generales de la Aplicación. |
| `07-menu-otros.md` | 73 | `07-iva.png` | Tipos de IVA y recargo de equivalencia. |
| `07-menu-otros.md` | 90 | `07-contadores.png` | Contadores de numeración por serie. |
| `07-menu-otros.md` | 123 | `03-formas-pago.png` | Catálogo de formas de pago. |
| `07-menu-otros.md` | 171 | `07-permisos.png` | Gestión de Permisos en árbol. |
| `07-menu-otros.md` | 203 | `07-copia-seguridad.png` | Diálogo de copia de seguridad. |
| `07-menu-otros.md` | 232 | `07-generador-procesos.png` | Generador de Procesos con la pestaña Código SQL. |
| `07-menu-otros.md` | 280 | `07-generador-listado.png` | Pestaña VistaDatos con un resultado y el botón Exp. Excel. |
| `08-menu-ayuda.md` | 18 | `08-acerca-de.png` | Pantalla Acerca de con la versión. |
| `09-instalacion-windows.md` | 94 | `09-subir-script.png` | Panel Configuración BBDD con el botón de carga de script. |
| `09-instalacion-windows.md` | 149 | `09-primer-login.png` | Primer login como Administrador. |
| `10-migracion-legacy.md` | 81 | `10-migrator-preparar.png` | Botones de extracción y carga del esqueleto. |
| `11-verifactu.md` | 219 | `11-acciones.png` | Botones Consolidar / Anular / Subsanar / Rectificar / Facturar ticket. |

## Ya cotejado

Las capturas que estaban en este documento y ya tienen fichero en `manual/img/`
se han eliminado del listado de faltantes. Si el texto del capítulo sigue
mostrando "Captura pendiente" junto a una imagen que ya existe, significa que
queda pendiente revisar el pie de foto, no que falte el fichero.

Cuando se añada una captura:

1. Guardar el fichero exacto en `manual/img/`.
2. Regenerar la web con `python generar_html.py` desde `manual/`.
3. Copiar `manual/html/` a `web/manual/`.
4. Eliminar la fila correspondiente de este documento.
