# 12 · Changes and new features

[◀ Back to contents](README.md)

This chapter separates **recent new features** from functions that have now
been incorporated into the main manual. To learn about day-to-day use, always
go to the relevant menu chapter; this page is only a quick map of changes.

> **Documentation review:** 19 August 2026. A function's inclusion in this map
> does not replace checking the installed version or its production validation
> status.

---

## Recent new features

| New feature | Where to find it |
|-------------|------------------|
| Manual import of **PrestaShop** orders, with controlled creation of customers and items, and carriage recorded as the `GASTOS_T` service with standard VAT and no stock movement. Use remains restricted to a laboratory environment and a single controlled destination. | [Ventas Mayor ▸ Pedidos](04-menu-ventas-mayor.md#importar-pedidos-de-prestashop) · [PrestaShop integration](15-integracion-prestashop.md) |
| Central **Otros ▸ Colas de envíos** menu for monitoring Verifactu, PrestaShop and Web Service Fzam from their actual location. | [Otros ▸ Colas de envíos](07-menu-otros.md#colas-de-envios) |
| **Web Service Fzam** queue with sales and PDF events, statuses, HTTP history, exponential retries and access to the associated document. | [Otros ▸ Colas de envíos ▸ Web Service Fzam](07-menu-otros.md#web-service-fzam) |
| **Histórico de Solicitudes de Traspaso** with quantities fulfilled/not fulfilled, reasons, transfers and related stock movements. | [TPV ▸ Histórico de Solicitudes de Traspaso](05-menu-caja.md#historico-de-solicitudes-de-traspaso) |
| **Facturas proforma** by period: an internal, non-tax pro forma document for VE sales or Ventas Mayor drafts for TA transfers. | [TPV ▸ Facturas proforma](05-menu-caja.md#facturas-proforma) |
| **Procesos auxiliares BBDD** for inspecting the SQL structure and contents of tables. | [Otros ▸ Procesos auxiliares BBDD](07-menu-otros.md#procesos-auxiliares-bbdd) |
| `[F1]` changes the line presentation between Auto/breakdown, SKU and the size modes; the cycle adapts to each document type. | [Common concepts ▸ Line modes with F1](01-conceptos-comunes.md#cambiar-la-presentacion-de-las-lineas-con-f1) |
| Purchase orders with partial receipt by line or size, **Recibir Todo**, Pedido/A recibir/Pendiente bands and the option to add them to an existing delivery note. | [Compras ▸ Pedidos](03-menu-compras.md#pedidos) |
| **Consulta de stocks de Factuzam** with `[Ctrl]+[U]`: stock on hand and pending quantities by colour, size and warehouse, broken-down statuses, related photographs and sending to Documentos de Trabajo. | [Ayuda ▸ Consulta de stocks](08-menu-ayuda.md#consulta-de-stocks) |
| **Factuzam Fotos Nube** Android application for taking photographs by item/colour, queuing them and uploading them to the server in batches. | [Mobile applications ▸ Fotos Nube](13-aplicaciones-moviles.md#factuzam-fotos-nube-fotografiar-articulos-desde-android) |
| **Administration of errors sent to support**: protected evidence, conversation, tracking by user and verified script or update proposals. | [Ayuda ▸ Envío de errores](08-menu-ayuda.md#envio-de-errores-administracion-y-seguimiento) |
| Translatable interface backed by a central catalogue, downloadable `en-GB`, `ca-ES` and `zh-CN` packages, Spanish fallback and a standalone translation editor. | [Otros ▸ Parámetros del entorno ▸ Apariencia ▸ Idioma](07-menu-otros.md#idioma-y-traducciones) |
| Ticket correction **by differences** or by means of a **replacement** document, with tax traceability and consistent treatment of sales and stock. | [TPV ▸ Rectificar un ticket](05-menu-caja.md#rectificar-un-ticket-por-diferencias-o-sustitutiva) |
| Purchase sessions with a **provisional photograph**, preview and automatic migration of the image to the materialised item or SKU. | [Compras ▸ Fotos de la sesión](03-menu-compras.md#7-fotos-de-la-sesion) |
| **VentasFzam** mobile application for viewing the day's sales, photographs, cost, margin and discounts without modifying data. | [Mobile applications ▸ VentasFzam](13-aplicaciones-moviles.md#ventasfzam-ventas-del-dia-en-el-movil) |
| Layered architecture, progressive application of SOLID, and a catalogue of reviewable, configurable SQL queries with validation and fallback. | [Architecture and development](14-arquitectura-y-desarrollo.md) |
| **Listado de operaciones de venta del TPV** by date, with the base colour shown visually and cumulative selection of companies/warehouses/tills when the user is not restricted. | [TPV ▸ Listados](05-menu-caja.md#listados) |
| **Documentos de Trabajo**: item/SKU lists that can be shared, used to print labels and sent to a delivery note, POS, inventory or price-list change. | [Almacén ▸ Documentos de Trabajo](06-menu-almacen.md#documentos-de-trabajo) |
| **Búsqueda de datos de artículos** with `[Ctrl]+[E]` from any window: by size, colour, palette proximity, stock and saved profiles. | [Common concepts ▸ Data search](01-conceptos-comunes.md#busqueda-de-datos-de-articulos-ctrle) |
| **Customer account at the POS** (F2): loading deposits and payments on account, cancellation by sign and allocation of a partial payment across deposits. | [TPV ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| **Payment-effects report** with filters by due date, supplier, bank/remittance, type and status. | [Compras ▸ Listados](03-menu-compras.md#listados-listado-de-efectos-de-pago) |
| **Ayuda** menu with direct access to the **web manual** and **support forum**. | [Ayuda menu](08-menu-ayuda.md) |
| Issuing a signed Facturae eDoc from consolidated wholesale sales drafts. | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#efectos-y-edoc-en-el-borrador) |
| Customer eDoc parameters: DIR3 and natural-person details. | [Clientes](02-menu-archivo.md#clientes) |
| Facturae code in payment methods for reporting the official means of payment. | [Formas de pago documentos](07-menu-otros.md#formas-de-pago-documentos) |
| Customer collection effects and reconciliation of due amounts. | [Efectos de cobro](04-menu-ventas-mayor.md#efectos-de-cobro) |
| Collection remittances, loading effects and SEPA generation. | [Remesas de cobro](04-menu-ventas-mayor.md#remesas-de-cobro) |
| Purchase invoices/drafts created from delivery notes and available for addition to an existing document. | [Compras ▸ Crear borradores de albaranes](03-menu-compras.md#crear-borradores-de-albaranes) |
| Complete purchase migration: orders, delivery notes, returns, invoices, effects and remittances. | [Migration from legacy software](10-migracion-legacy.md#2-que-datos-migra) |

---

## Incorporated into the manual

The following functions are no longer treated as newly added. They are grouped
by working area and documented in the regular chapters of the manual.

### Archivo and catalogue

| Incorporated function | Where to find it |
|-----------------------|------------------|
| Bank accounts by company, with default collection and payment flags. | [Empresas](02-menu-archivo.md#empresas) |
| Default collection bank for customers. | [Clientes](02-menu-archivo.md#clientes) |
| Default payment method and payment bank for suppliers. | [Proveedores](02-menu-archivo.md#proveedores) |
| Quantity kits by size for purchase sessions. | [Proveedores ▸ Compras](02-menu-archivo.md#pestana-compras-parametros-de-compra-del-proveedor) |
| Photographs by item, colour or SKU, with a floating window and download from the server. | [Common concepts ▸ Floating photograph](01-conceptos-comunes.md#foto-flotante-del-articulo-sku) |
| Units of measure with decimal quantities by unit. | [Unidades de Medida](02-menu-archivo.md#unidades-de-medida) |
| Basic attributes and standard colour/size equivalents. | [Atributos básicos](02-menu-archivo.md#atributos-basicos) |
| Price-list change sessions and date windows for discounts. | [Tarifas](02-menu-archivo.md#tarifas) |

### Compras

| Incorporated function | Where to find it |
|-----------------------|------------------|
| Purchase sessions with kit application and supplier tab. | [Sesiones de compra](03-menu-compras.md#sesiones-crear-articulos-y-un-pedido-o-un-albaran) |
| Informational **Depósito** flag on purchase delivery notes. | [Albaranes de compra](03-menu-compras.md#albaranes) |
| Supplier returns as a separate document with stock issue. | [Devoluciones a Proveedor](03-menu-compras.md#devoluciones-a-proveedor) |
| Purchase drafts with effect generation. | [Borradores](03-menu-compras.md#borradores) |
| Supplier payment effects and remittances. | [Efectos de pago](03-menu-compras.md#efectos-de-pago) |

### Sales and Caja

| Incorporated function | Where to find it |
|-----------------------|------------------|
| **Borradores** terminology before tax closure. | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#borradores) |
| Creating sales drafts from delivery notes within a date range. | [Albaranes de venta](04-menu-ventas-mayor.md#albaranes) |
| Simplified till drafts and conversion to a normal draft. | [TPV ▸ Borradores Simplificados](05-menu-caja.md#borradores-simplificados) |
| POS with photograph, colour/size and SKU details on lines. | [TPV ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| Complete extension of the till flow: working day, tickets, vouchers, loans, transfers, cash count and till roll. | [TPV](05-menu-caja.md) |
| Details of all Caja parameters and their current operational effect. | [TPV ▸ Parámetros de Caja](05-menu-caja.md#parametros-de-caja) |
| Cash-count history from the POS, with duplicate ticket/closure. | [TPV ▸ Arqueo](05-menu-caja.md#arqueo-f11) |
| A4 cash-count history report. | [TPV ▸ Histórico de Arqueos](05-menu-caja.md#historico-de-arqueos) |

### Almacén and reports

| Incorporated function | Where to find it |
|-----------------------|------------------|
| Mobile stocktaking with an Android app and bridge server. | [Inventarios ▸ Recuento móvil](06-menu-almacen.md#recuento-movil) |
| Horizontal warehouse balance by size, with photographs, filters, bands and groups. | [Balance de Almacén Horizontal](06-menu-almacen.md#balance-de-almacen-horizontal) |
| Warehouse balance without sizes for the entire catalogue. | [Balance de Almacén sin tallas](06-menu-almacen.md#balance-de-almacen-sin-tallas) |
| Sales movements by item and date, with margins. | [Movimientos de ventas por artículos y fechas](06-menu-almacen.md#movimientos-de-ventas-por-articulos-y-fechas) |
| Tree-based family filter in reports. | [Informes de almacén](06-menu-almacen.md#informes) |

### Administration and taxation

| Incorporated function | Where to find it |
|-----------------------|------------------|
| Centralised Fotos, Recuentos and Verifactu parameters. | [Parámetros del entorno](07-menu-otros.md#parametros-del-entorno) |
| Tree-based permissions by menu and screen action. | [Permisos](07-menu-otros.md#permisos) |
| Employees kept separate from users for till operations, transfers and cash counts. | [Empleados](07-menu-otros.md#empleados) |
| `SIN`, `VERIFACTU` and `NO_VERIFACTU` tax modes. | [Verifactu ▸ Configuración](11-verifactu.md#2-configuracion-previa-administrador) |
| XML export of NO VERI*FACTU records. | [Verifactu Log](11-verifactu.md#verifactu-log) |
| Verifactu transaction type for intra-Community transactions, reverse charge and exports. | [Verifactu en la ficha](11-verifactu.md#4-verifactu-en-la-ficha-de-la-factura) |

---

[◀ Verifactu](11-verifactu.md) · [Contents](README.md) · [Next ▶ Mobile applications](13-aplicaciones-moviles.md)
