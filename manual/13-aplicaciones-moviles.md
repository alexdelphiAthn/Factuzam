# 13 · Aplicaciones móviles

[◀ Volver al índice](README.md)

Factuzam dispone de aplicaciones móviles independientes para consultar
información o capturar datos fuera del puesto Windows. Cada app usa una
credencial y permisos propios; no se conecta directamente a MariaDB.

---

## VentasFzam: ventas del día en el móvil

**VentasFzam** es una aplicación de consulta en modo **solo lectura**. Permite
seguir las ventas diarias desde el teléfono sin abrir el TPV y sin riesgo de
modificar facturas, cobros o stock.

### Qué muestra

Cada línea de venta incluye:

- Hora, SKU y descripción.
- Temporada y proveedor.
- Importe vendido.
- Foto del artículo en resolución de 300 px, cuando está disponible.

Al tocar una línea se abre su detalle con familia, color, precio de coste,
PVP, descuento en porcentaje y euros, precio de venta y total.

La cabecera resume cuatro indicadores del día:

| Indicador | Contenido |
|-----------|-----------|
| **Venta** | Total vendido con IVA, para que cuadre con la caja. |
| **Coste** | Coste acumulado de los artículos mostrados. |
| **Margen** | Importe y porcentaje calculados sobre la base imponible, no sobre la venta con IVA. |
| **Descuento** | Descuento total aplicado. |

### Manejo diario

- **◀ / ▶** cambia al día anterior o siguiente.
- Tocar la **fecha** vuelve directamente a hoy.
- El **buscador** filtra en el teléfono sobre los datos descargados; el
  resultado aparece de inmediato y los cuatro totales se recalculan. La
  cabecera indica **(filtrado)** mientras haya una búsqueda activa.
- Las ventas anuladas o sustituidas no aparecen ni suman. La rectificativa
  sustitutiva correcta sí aparece; las rectificaciones por diferencias
  computan con su signo.

Las fotografías se descargan después de mostrar la lista para no retrasar
la consulta y quedan almacenadas en la caché del teléfono. Si se cambia de
día mientras se descargan, la app descarta las imágenes pendientes de la
consulta anterior.

> El día se determina por la **fecha de la factura**, no por el instante en
> que el servidor recibió el evento. Así los totales respetan el cierre del
> negocio y el huso horario de la instalación.

### Puesta en marcha (administrador)

La consulta móvil necesita que la instalación publique las ventas en el
servicio web:

1. Configurar en Factuzam la URL, credencial y referencia del servicio.
2. Activar **Enviar ventas al webservice** (`vgerEnviarVentasWS`) en los
   perfiles o cajas que correspondan.
3. Crear una credencial móvil con permiso de lectura de ventas.
4. En **VentasFzam ▸ Configuración (⚙)**, indicar URL base, token y
   referencia.

Factuzam guarda cada cambio de una venta como un evento en una cola local y
lo envía en segundo plano. La caja no espera a la red y la cola fiscal de
Verifactu funciona de forma independiente. Los eventos se reintentan con el
mismo identificador para evitar duplicados.

> Las ventas históricas sincronizadas antes de incorporar un dato nuevo —por
> ejemplo, la temporada— pueden mostrarlo vacío hasta que vuelvan a enviarse.
> Las ventas nuevas lo incluyen desde el primer envío.

---

## Recuento móvil de inventarios

La app de recuento permite escanear existencias desde terminales Android y
devolver las cantidades a un inventario abierto. El envío y la recogida se
controlan desde Factuzam; el móvil no regulariza el stock por sí solo.

Consulta el procedimiento completo en
[Almacén ▸ Inventarios ▸ Recuento móvil](06-menu-almacen.md#recuento-movil).

---

[◀ Cambios y novedades](12-cambios-y-novedades.md) · [Índice](README.md) · [Siguiente ▶ Arquitectura y desarrollo](14-arquitectura-y-desarrollo.md)
