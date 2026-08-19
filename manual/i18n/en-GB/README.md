# Factuzam User Manual

Welcome to the **Factuzam** user manual. Factuzam is a business management,
invoicing and point-of-sale (POS) application for fashion and retail businesses
(items with sizes, colours and attributes).

This manual follows the application's **main menu bar**. Each chapter documents
one menu and, within it, each menu item in turn: what it does, when to use it and
the most relevant fields or steps.

## Getting the demo

The demo is distributed as a versioned installer. Always use the current link
provided by Factuzam or by the installer; do not reuse the URL for an earlier
build. If the website does not show an active download, ask support for the
current package before continuing with this chapter.

> **Practice in the DEMO program:** when you start, sign in with the demo
> administrator account, create your own user and password under
> [Otros ▸ Usuarios, Grupos y Perfiles](07-menu-otros.md#usuarios-grupos-y-perfiles),
> assign it to the **Administradores** group, then sign in again from
> *Archivo ▸ Invocar login* so that you can work with your own account.

## Project and licence

The Factuzam source code is available in the
[official GitHub repository](https://github.com/alexdelphiAthn/Factuzam).
The project's original code is distributed under the
[Mozilla Public License 2.0 (MPL-2.0)](https://www.mozilla.org/MPL/2.0/),
subject to the exceptions and conditions explained in the
[Ayuda chapter](08-menu-ayuda.md#proyecto-en-github-y-licencia).

---

## Contents

| Chapter | Contents |
|---------|----------|
| [00 · Access and first steps](00-acceso-y-primeros-pasos.md) | Starting the application, signing in, configuring the database connection and the main screen. |
| [01 · Common concepts](01-conceptos-comunes.md) | How maintenance screens work: list, record, search, navigator, line modes with `[F1]` and export. **Read this before the other chapters.** |
| [02 · Archivo menu](02-menu-archivo.md) | Master data: Empresas, Almacenes, Clientes, Proveedores, Artículos and Tablas Auxiliares. |
| [03 · Compras menu](03-menu-compras.md) | Purchase sessions, Pedidos, Albaranes, Devoluciones a proveedor and Facturas de compra. |
| [04 · Ventas Mayor menu](04-menu-ventas-mayor.md) | Wholesale invoicing: Borradores, receivables, Pedidos, Albaranes and sales reports. |
| [05 · TPV menu](05-menu-caja.md) | Point of sale: till, deposits, history, transfer requests, simplified drafts and pro forma invoices. |
| [06 · Almacén menu](06-menu-almacen.md) | Warehouse movements, Inventarios, Documentos de Trabajo and stock reports. |
| [07 · Otros menu](07-menu-otros.md) | Parameters, VAT, users/permissions, outbound queues, backups, Generador de procesos and Procesos auxiliares BBDD. |
| [08 · Ayuda menu](08-menu-ayuda.md) | Stock enquiry, web manual, GitHub, licence and administration of errors sent to support. |
| [09 · Installation on Windows](09-instalacion-windows.md) | MariaDB, initial database, workstation installation and getting started. |
| [10 · Migration from legacy software](10-migracion-legacy.md) | Moving data from the previous ERP (SQL Server) with Factuzam Migrator. |
| [11 · Verifactu (AEAT)](11-verifactu.md) | Verifiable invoicing system: configuration, the queue available from Otros, QR codes and tax actions (cancel, correct and remedy). |
| [12 · Changes and new features](12-cambios-y-novedades.md) | Summary of recent changes and where they are documented in the manual. |
| [13 · Mobile applications](13-aplicaciones-moviles.md) | Item photographs, daily sales enquiries and stocktaking from Android. |
| [14 · Architecture and development](14-arquitectura-y-desarrollo.md) | Programming style, SOLID principles, layers, tests and the configurable SQL catalogue. |
| [15 · PrestaShop integration](15-integracion-prestashop.md) | Configuration, catalogue and queue, order import, prices by SKU and validation status. |

---

## The menu bar at a glance

| Menu | Main options |
|------|--------------|
| **Archivo** | Empresas, Almacenes, Clientes, Proveedores, Artículos, Tablas Auxiliares, Invocar login and Salir. |
| **Compras** | Sesiones, Pedidos, Albaranes, Devoluciones, Crear borradores, Borradores, Efectos y Remesas de pago, Cargar efectos and Listados. |
| **Ventas Mayor** | Pedidos, Albaranes, Borradores, Efectos y Remesas de cobro, Cargar efectos and Listados. |
| **TPV** | Menú de Caja, Listados, Parámetros, Formas de pago, Depósitos, till history, Histórico de Solicitudes de Traspaso, Borradores Simplificados and Facturas proforma. |
| **Almacén** | Movimientos, Inventarios, Documentos de Trabajo and Informes. |
| **Otros** | Parámetros del entorno, IVA, Contadores, Formas de pago documentos, Usuarios y Perfiles, **Colas de envíos** (Verifactu, PrestaShop and Web Service Fzam), Copias de Seguridad, Generador de Procesos and Procesos auxiliares BBDD. |
| **Verifactu** | Declaración Responsable and Verifactu Log. The queue is under **Otros ▸ Colas de envíos ▸ Verifactu**. |
| **Ayuda** | Consulta de stocks, Artículos similares, Manual web, Foro de soporte, Envío de errores and Acerca de. |

> **Note:** the options shown depend on your **user profile and assigned
> permissions**. If an option is disabled or does not appear, ask the
> administrator (see
> [Otros menu → Usuarios, Grupos y Perfiles](07-menu-otros.md)).

---

## Conventions used in this manual

- **Bold** is used for the names of menus, buttons and on-screen fields.
- `Code` is used for technical names (tables, files and parameters).
- The `▸` icons indicate a menu path, for example:
  *Archivo ▸ Tablas Auxiliares ▸ Tarifas*.
- Keys are shown in square brackets, for example `[F12]`, `[Esc]` and
  `[Ctrl]+[A]`.
