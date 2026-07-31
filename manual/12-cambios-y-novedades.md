# 12 · Cambios y novedades

[◀ Volver al índice](README.md)

Este capítulo separa las **novedades recientes** de las funciones que ya
han quedado incorporadas al manual normal. Para aprender el uso diario,
entra siempre en el capítulo de menú correspondiente; esta página es solo
un mapa rápido de cambios.

---

## Novedades recientes

| Novedad | Dónde verlo |
|---------|-------------|
| Interfaz traducible desde un catálogo central, selector por parámetro, respaldo en español y editor independiente de traducciones. | [Otros ▸ Idioma y traducciones](07-menu-otros.md#idioma-y-traducciones) |
| Rectificación de tickets **por diferencias** o mediante documento **sustitutivo**, con trazabilidad fiscal y tratamiento coherente de ventas y stock. | [Caja ▸ Rectificar un ticket](05-menu-caja.md#rectificar-un-ticket-por-diferencias-o-sustitutiva) |
| Sesiones de compra con **foto provisional**, vista previa y migración automática de la imagen al artículo o SKU materializado. | [Compras ▸ Fotos de la sesión](03-menu-compras.md#7-fotos-de-la-sesion) |
| Aplicación móvil **VentasFzam** para consultar ventas del día, fotografías, coste, margen y descuentos sin modificar datos. | [Aplicaciones móviles ▸ VentasFzam](13-aplicaciones-moviles.md#ventasfzam-ventas-del-dia-en-el-movil) |
| Arquitectura por capas, aplicación progresiva de SOLID y catálogo de consultas SQL revisables y configurables con validación y fallback. | [Arquitectura y desarrollo](14-arquitectura-y-desarrollo.md) |
| **Listado de operaciones de venta del TPV** por fechas, con color básico visual y selección acumulativa de empresas/almacenes/cajas cuando el usuario no está restringido. | [TPV ▸ Listados](05-menu-caja.md#listados) |
| **Documentos de Trabajo**: listas de artículos/SKUs para compartir, imprimir etiquetas y enviar a albarán, TPV, inventario o cambio de tarifas. | [Almacén ▸ Documentos de Trabajo](06-menu-almacen.md#documentos-de-trabajo) |
| **Búsqueda de datos de artículos** con `[Ctrl]+[E]` desde cualquier ventana: por talla, color, proximidad de paleta, stock y perfiles guardados. | [Conceptos comunes ▸ Búsqueda de datos](01-conceptos-comunes.md#busqueda-de-datos-de-articulos-ctrle) |
| **Cuenta de cliente en el TPV** (F2): carga de depósitos y abonos a cuenta, cancelación por signo y reparto del cobro parcial en depósitos. | [Caja ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| **Listado de efectos de pago** con filtros por vencimiento, proveedor, banco/remesa, tipo y situación. | [Compras ▸ Listados](03-menu-compras.md#listados-listado-de-efectos-de-pago) |
| Menú **Ayuda** con acceso directo al **manual web** y al **foro de soporte**. | [Menú Ayuda](08-menu-ayuda.md) |
| Emisión de eDoc Facturae firmado desde borradores de venta mayor consolidados. | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#efectos-y-edoc-en-el-borrador) |
| Parámetros eDoc del cliente: DIR3 y datos de persona física. | [Clientes](02-menu-archivo.md#clientes) |
| Código Facturae en formas de pago para informar el medio de pago oficial. | [Formas de pago documentos](07-menu-otros.md#formas-de-pago-documentos) |
| Efectos de cobro a cliente y conciliación de vencimientos. | [Efectos de cobro](04-menu-ventas-mayor.md#efectos-de-cobro) |
| Remesas de cobro, carga de efectos y generación SEPA. | [Remesas de cobro](04-menu-ventas-mayor.md#remesas-de-cobro) |
| Facturas/borradores de compra creados desde albaranes e incorporables a un documento existente. | [Compras ▸ Crear borradores de albaranes](03-menu-compras.md#crear-borradores-de-albaranes) |
| Migración de compras completa: pedidos, albaranes, devoluciones, facturas, efectos y remesas. | [Migración desde legacy](10-migracion-legacy.md#2-que-datos-migra) |

---

## Incorporado al manual

Las funciones siguientes ya no se tratan como recién añadidas; quedan
clasificadas por su área de trabajo y documentadas en los capítulos
normales del manual.

### Archivo y catálogo

| Función incorporada | Dónde verlo |
|---------------------|-------------|
| Cuentas bancarias por empresa, con marcas de cobro y pago por defecto. | [Empresas](02-menu-archivo.md#empresas) |
| Banco de cobro por defecto en clientes. | [Clientes](02-menu-archivo.md#clientes) |
| Forma de pago y banco de pago por defecto en proveedores. | [Proveedores](02-menu-archivo.md#proveedores) |
| Kits de cantidades por talla para sesiones de compra. | [Proveedores ▸ Compras](02-menu-archivo.md#pestana-compras-parametros-de-compra-del-proveedor) |
| Fotos por artículo, color o SKU, con ventana flotante y descarga desde servidor. | [Conceptos comunes ▸ Foto flotante](01-conceptos-comunes.md#foto-flotante-del-articulo-sku) |
| Unidades de medida con decimales por unidad. | [Unidades de Medida](02-menu-archivo.md#unidades-de-medida) |
| Atributos básicos y equivalencias estándar de color/talla. | [Atributos básicos](02-menu-archivo.md#atributos-basicos) |
| Sesiones de cambios de tarifa y ventana de fechas para descuentos. | [Tarifas](02-menu-archivo.md#tarifas) |

### Compras

| Función incorporada | Dónde verlo |
|---------------------|-------------|
| Sesiones de compra con aplicación de kits y pestaña proveedor. | [Sesiones de compra](03-menu-compras.md#sesiones-crear-articulos-y-un-pedido-o-un-albaran) |
| Pedidos con control de cantidades **A recibir** e incorporación a albarán existente. | [Pedidos de compra](03-menu-compras.md#pedidos) |
| Marca informativa **Depósito** en albaranes de compra. | [Albaranes de compra](03-menu-compras.md#albaranes) |
| Devoluciones a proveedor como documento propio con salida de stock. | [Devoluciones a Proveedor](03-menu-compras.md#devoluciones-a-proveedor) |
| Borradores de compra con generación de efectos. | [Borradores](03-menu-compras.md#borradores) |
| Efectos y remesas de pago a proveedor. | [Efectos de pago](03-menu-compras.md#efectos-de-pago) |

### Ventas y Caja

| Función incorporada | Dónde verlo |
|---------------------|-------------|
| Terminología de **Borradores** antes del cierre fiscal. | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#borradores) |
| Crear borradores de venta desde albaranes por rango de fechas. | [Albaranes de venta](04-menu-ventas-mayor.md#albaranes) |
| Borradores simplificados de caja y conversión a borrador normal. | [Caja ▸ Borradores Simplificados](05-menu-caja.md#borradores-simplificados) |
| TPV con foto, color/talla y datos de SKU en líneas. | [Caja ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| Ampliación completa del flujo de caja: jornada, tickets, vales, préstamos, traspasos, recuento y tira de caja. | [Caja](05-menu-caja.md) |
| Detalle de todos los parámetros de Caja y su efecto operativo actual. | [Caja ▸ Parámetros de Caja](05-menu-caja.md#parametros-de-caja) |
| Histórico de arqueos desde TPV con duplicado de ticket/cierre. | [Caja ▸ Arqueo](05-menu-caja.md#arqueo-f11) |
| Informe A4 de histórico de arqueos. | [Caja ▸ Histórico de Arqueos](05-menu-caja.md#historico-de-arqueos) |

### Almacén e informes

| Función incorporada | Dónde verlo |
|---------------------|-------------|
| Recuento móvil de inventarios mediante app Android y servidor puente. | [Inventarios ▸ Recuento móvil](06-menu-almacen.md#recuento-movil) |
| Balance de almacén horizontal por tallas, con fotos, filtros, bandas y agrupaciones. | [Balance de Almacén Horizontal](06-menu-almacen.md#balance-de-almacen-horizontal) |
| Balance de almacén sin tallas para todo el catálogo. | [Balance de Almacén sin tallas](06-menu-almacen.md#balance-de-almacen-sin-tallas) |
| Movimientos de ventas por artículos y fechas, con márgenes. | [Movimientos de ventas por artículos y fechas](06-menu-almacen.md#movimientos-de-ventas-por-articulos-y-fechas) |
| Filtro de familias como árbol en informes. | [Informes de almacén](06-menu-almacen.md#informes) |

### Administración y fiscalidad

| Función incorporada | Dónde verlo |
|---------------------|-------------|
| Parámetros de Fotos, Recuentos y Verifactu centralizados. | [Parámetros del entorno](07-menu-otros.md#parametros-del-entorno) |
| Permisos en árbol, por menú y por acción de pantalla. | [Permisos](07-menu-otros.md#permisos) |
| Empleados separados de usuarios para caja, traspasos y arqueos. | [Empleados](07-menu-otros.md#empleados) |
| Modos fiscales `SIN`, `VERIFACTU` y `NO_VERIFACTU`. | [Verifactu ▸ Configuración](11-verifactu.md#2-configuracion-previa-administrador) |
| Exportación XML de registros NO VERI*FACTU. | [Verifactu Log](11-verifactu.md#verifactu-log) |
| Tipo de operación Verifactu para intracomunitarias, inversión del sujeto pasivo y exportaciones. | [Verifactu en la ficha](11-verifactu.md#4-verifactu-en-la-ficha-de-la-factura) |

---

[◀ Verifactu](11-verifactu.md) · [Índice](README.md) · [Siguiente ▶ Aplicaciones móviles](13-aplicaciones-moviles.md)
