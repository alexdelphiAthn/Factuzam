# Manual de Usuario — Factuzam

Bienvenido al manual de usuario de **Factuzam**, la aplicación de gestión
comercial, facturación y punto de venta (TPV) para comercio de moda y
detalle (artículos con tallas, colores y atributos).

Este manual está organizado siguiendo la **barra de menú principal** de la
aplicación. Cada capítulo documenta un menú y, dentro de él, cada opción
(item de menú) una por una: qué hace, cuándo usarla y los campos o pasos
más relevantes.

---

## Índice

| Capítulo | Contenido |
|----------|-----------|
| [00 · Acceso y primeros pasos](00-acceso-y-primeros-pasos.md) | Arranque, login, configuración de la conexión a la base de datos y la pantalla principal. |
| [01 · Conceptos comunes](01-conceptos-comunes.md) | Cómo funcionan las pantallas de mantenimiento: lista, ficha, búsqueda, navegador y exportación. **Léelo antes que los demás.** |
| [02 · Menú Archivo](02-menu-archivo.md) | Datos maestros: Empresas, Almacenes, Clientes, Proveedores, Artículos y Tablas Auxiliares. |
| [03 · Menú Compras](03-menu-compras.md) | Sesiones de compra, Pedidos, Albaranes, Devoluciones a proveedor y Facturas de compra. |
| [04 · Menú Ventas Mayor](04-menu-ventas-mayor.md) | Facturación a mayor: Facturas, Pedidos, Albaranes y Listados de ventas. |
| [05 · Menú Caja](05-menu-caja.md) | Punto de venta (TPV): menú de caja, parámetros, depósitos, históricos, arqueos y facturas simplificadas. |
| [06 · Menú Almacén](06-menu-almacen.md) | Movimientos de almacén, Inventarios e Informes de stock. |
| [07 · Menú Otros](07-menu-otros.md) | Parámetros del entorno, IVA, Contadores, Formas de pago documentos, Usuarios/Permisos, Copias de seguridad y Generador de procesos. |
| [08 · Menú Ayuda](08-menu-ayuda.md) | Acerca de y datos de versión. |
| [09 · Instalación en Windows](09-instalacion-windows.md) | MariaDB, base de datos inicial, instalación por puesto y puesta en marcha. |
| [10 · Migración desde software legacy](10-migracion-legacy.md) | Traslado de datos del ERP anterior (SQL Server) con el Factuzam Migrator. |
| [11 · Verifactu (AEAT)](11-verifactu.md) | Sistema de facturación verificable: configuración, cola de envío, QR, y acciones fiscales (anular, rectificar, subsanar). |
| [12 · Cambios y novedades](12-cambios-y-novedades.md) | Resumen de las novedades recientes y dónde se documentan dentro del manual. |

---

## La barra de menú de un vistazo

```
Archivo        Compras        Ventas Mayor   Caja           Almacén        Otros          Verifactu      Ayuda
─────────      ─────────      ────────────   ─────          ────────       ─────          ─────────     ─────
Empresas       Sesiones       Borradores     Menú de Caja   Movimientos    Parám. entorno Declaración   Acerca de
Almacenes      Pedidos        Pedidos        Parám. de Caja Inventarios    Grupos de IVA  Cola envíos
Clientes       Albaranes      Albaranes      Formas Pago    Informes       Impuesto IVA   Log
Proveedores    Devoluciones   Listados       Depósitos                     Contadores
Artículos      Crear borrad.                 Históricos                    Formas pago docs
Tablas Aux.    Borradores                    Borrad. Simplif.              Usuarios y Perfiles
Invocar login  Efectos pago                                                Copias de Seguridad
Salir          Remesas pago                                                Generador de Procesos
               Listados
```

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


