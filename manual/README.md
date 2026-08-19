# Manual de Usuario — Factuzam

Bienvenido al manual de usuario de **Factuzam**, la aplicación de gestión
comercial, facturación y punto de venta (TPV) para comercio de moda y
detalle (artículos con tallas, colores y atributos).

Este manual está organizado siguiendo la **barra de menú principal** de la
aplicación. Cada capítulo documenta un menú y, dentro de él, cada opción
(item de menú) una por una: qué hace, cuándo usarla y los campos o pasos
más relevantes.

## Obtener la demo

La demo se distribuye como un instalador versionado. Utiliza siempre el
enlace vigente facilitado por Factuzam o por el instalador; no reutilices la
URL de una compilación anterior. Si la web no muestra una descarga activa,
solicita el paquete actual al soporte antes de seguir este capítulo.

> **Práctica en programa DEMO:** al empezar, entra con el usuario
> administrador de la demo, crea un usuario propio con su contraseña en
> [Otros ▸ Usuarios, Grupos y Perfiles](07-menu-otros.md#usuarios-grupos-y-perfiles),
> asígnalo al grupo **Administradores** y vuelve a entrar desde
> *Archivo ▸ Invocar login* para trabajar ya con tu propio usuario.

## Proyecto y licencia

El código fuente de Factuzam está disponible en el
[repositorio oficial de GitHub](https://github.com/alexdelphiAthn/Factuzam).
El código original del proyecto se distribuye bajo la
[Mozilla Public License 2.0 (MPL-2.0)](https://www.mozilla.org/MPL/2.0/),
con las excepciones y condiciones explicadas en el
[capítulo de Ayuda](08-menu-ayuda.md#proyecto-en-github-y-licencia).

---

## Índice

| Capítulo | Contenido |
|----------|-----------|
| [00 · Acceso y primeros pasos](00-acceso-y-primeros-pasos.md) | Arranque, login, configuración de la conexión a la base de datos y la pantalla principal. |
| [01 · Conceptos comunes](01-conceptos-comunes.md) | Cómo funcionan las pantallas de mantenimiento: lista, ficha, búsqueda, navegador, modos de líneas con `[F1]` y exportación. **Léelo antes que los demás.** |
| [02 · Menú Archivo](02-menu-archivo.md) | Datos maestros: Empresas, Almacenes, Clientes, Proveedores, Artículos y Tablas Auxiliares. |
| [03 · Menú Compras](03-menu-compras.md) | Sesiones de compra, Pedidos, Albaranes, Devoluciones a proveedor y Facturas de compra. |
| [04 · Menú Ventas Mayor](04-menu-ventas-mayor.md) | Facturación a mayor: Borradores, cartera de cobro, Pedidos, Albaranes y Listados de ventas. |
| [05 · Menú TPV](05-menu-caja.md) | Punto de venta: caja, depósitos, históricos, solicitudes de traspaso, borradores simplificados y facturas proforma. |
| [06 · Menú Almacén](06-menu-almacen.md) | Movimientos de almacén, Inventarios, Documentos de Trabajo e Informes de stock. |
| [07 · Menú Otros](07-menu-otros.md) | Parámetros, IVA, usuarios/permisos, colas de envíos, copias de seguridad, Generador de procesos y procesos auxiliares BBDD. |
| [08 · Menú Ayuda](08-menu-ayuda.md) | Consulta de stocks, Manual web, GitHub, licencia y administración de los errores enviados a soporte. |
| [09 · Instalación en Windows](09-instalacion-windows.md) | MariaDB, base de datos inicial, instalación por puesto y puesta en marcha. |
| [10 · Migración desde software legacy](10-migracion-legacy.md) | Traslado de datos del ERP anterior (SQL Server) con el Factuzam Migrator. |
| [11 · Verifactu (AEAT)](11-verifactu.md) | Sistema de facturación verificable: configuración, cola accesible desde Otros, QR y acciones fiscales (anular, rectificar, subsanar). |
| [12 · Cambios y novedades](12-cambios-y-novedades.md) | Resumen de las novedades recientes y dónde se documentan dentro del manual. |
| [13 · Aplicaciones móviles](13-aplicaciones-moviles.md) | Fotos de artículos, consulta de ventas diarias y recuento de inventarios desde Android. |
| [14 · Arquitectura y desarrollo](14-arquitectura-y-desarrollo.md) | Estilo de programación, principios SOLID, capas, pruebas y catálogo SQL configurable. |
| [15 · Integración con PrestaShop](15-integracion-prestashop.md) | Configuración, catálogo y cola, importación de pedidos, precios por SKU y estado de validación. |

---

## La barra de menú de un vistazo

| Menú | Opciones principales |
|------|-----------------------|
| **Archivo** | Empresas, Almacenes, Clientes, Proveedores, Artículos, Tablas Auxiliares, Invocar login y Salir. |
| **Compras** | Sesiones, Pedidos, Albaranes, Devoluciones, Crear borradores, Borradores, Efectos y Remesas de pago, Cargar efectos y Listados. |
| **Ventas Mayor** | Pedidos, Albaranes, Borradores, Efectos y Remesas de cobro, Cargar efectos y Listados. |
| **TPV** | Menú de Caja, Listados, Parámetros, Formas de pago, Depósitos, históricos de caja, Histórico de Solicitudes de Traspaso, Borradores Simplificados y Facturas proforma. |
| **Almacén** | Movimientos, Inventarios, Documentos de Trabajo e Informes. |
| **Otros** | Parámetros del entorno, IVA, Contadores, Formas de pago documentos, Usuarios y Perfiles, **Colas de envíos** (Verifactu, PrestaShop y Web Service Fzam), Copias de Seguridad, Generador de Procesos y Procesos auxiliares BBDD. |
| **Verifactu** | Declaración Responsable y Verifactu Log. La cola está en **Otros ▸ Colas de envíos ▸ Verifactu**. |
| **Ayuda** | Consulta de stocks, Artículos similares, Manual web, Foro de soporte, Envío de errores y Acerca de. |

> **Nota:** las opciones visibles dependen de tu **perfil de usuario y de
> los permisos** asignados. Si una opción aparece deshabilitada o no
> aparece, consulta con el administrador (ver
> [Menú Otros → Usuarios, Grupos y Perfiles](07-menu-otros.md)).

---

## Convenciones de este manual

- **Negrita** para nombres de menús, botones y campos de pantalla.
- `Código` para nombres técnicos (tablas, ficheros, parámetros).
- Los iconos `▸` indican una ruta de menú, por ejemplo:
  *Archivo ▸ Tablas Auxiliares ▸ Tarifas*.
- Las teclas se muestran entre corchetes, p. ej. `[F12]`, `[Esc]`,
  `[Ctrl]+[A]`.


