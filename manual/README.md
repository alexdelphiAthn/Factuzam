# Manual de Usuario — Factuzam

Bienvenido al manual de usuario de **Factuzam**, la aplicación de gestión
comercial, facturación y punto de venta (TPV) para comercio de moda y
detalle (artículos con tallas, colores y atributos).

Este manual está organizado siguiendo la **barra de menú principal** de la
aplicación. Cada capítulo documenta un menú y, dentro de él, cada opción
(item de menú) una por una: qué hace, cuándo usarla y los campos o pasos
más relevantes.

## Descargar la demo

Para probar el programa puedes descargar la demo desde la raíz de la web:

[Descargar Factuzam_DEMO_1.0.15.202606240020.alpha.exe](/Factuzam_DEMO_1.0.15.202606240020.alpha.exe)

El fichero es `Factuzam_DEMO_1.0.15.202606240020.alpha.exe`.

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
| [05 · Menú TPV](05-menu-caja.md) | Punto de venta: listados, menú de caja, parámetros, depósitos, históricos, arqueos y facturas simplificadas. |
| [06 · Menú Almacén](06-menu-almacen.md) | Movimientos de almacén, Inventarios, Documentos de Trabajo e Informes de stock. |
| [07 · Menú Otros](07-menu-otros.md) | Parámetros del entorno, IVA, Contadores, Formas de pago documentos, Usuarios/Permisos, Copias de seguridad y Generador de procesos. |
| [08 · Menú Ayuda](08-menu-ayuda.md) | Consulta de stocks, Manual web, GitHub, licencia y administración de los errores enviados a soporte. |
| [09 · Instalación en Windows](09-instalacion-windows.md) | MariaDB, base de datos inicial, instalación por puesto y puesta en marcha. |
| [10 · Migración desde software legacy](10-migracion-legacy.md) | Traslado de datos del ERP anterior (SQL Server) con el Factuzam Migrator. |
| [11 · Verifactu (AEAT)](11-verifactu.md) | Sistema de facturación verificable: configuración, cola de envío, QR, y acciones fiscales (anular, rectificar, subsanar). |
| [12 · Cambios y novedades](12-cambios-y-novedades.md) | Resumen de las novedades recientes y dónde se documentan dentro del manual. |
| [13 · Aplicaciones móviles](13-aplicaciones-moviles.md) | Fotos de artículos, consulta de ventas diarias y recuento de inventarios desde Android. |
| [14 · Arquitectura y desarrollo](14-arquitectura-y-desarrollo.md) | Estilo de programación, principios SOLID, capas, pruebas y catálogo SQL configurable. |
| [15 · Integración con PrestaShop](15-integracion-prestashop.md) | Configuración por perfil, artículos y almacenes web, cola, precios por SKU y alta inactiva. |

---

## La barra de menú de un vistazo

```
Archivo        Compras        Ventas Mayor   TPV            Almacén        Otros          Verifactu      Ayuda
─────────      ─────────      ────────────   ─────          ────────       ─────          ─────────      ─────
Empresas       Sesiones       Pedidos        Menú de Caja   Movimientos    Parám. entorno Declaración    Consulta stocks
Almacenes      Pedidos        Albaranes      Listados       Inventarios    Grupos de IVA  Cola envíos    Art. similares
Clientes       Albaranes      Borradores     Formas Pago    Doc. Trabajo   Impuesto IVA   Log            Manual web
Proveedores    Devoluciones   Efectos cobro  Depósitos      Informes       Contadores
Artículos      Crear borrad.  Remesas cobro  Históricos                    Formas pago docs
Tablas Aux.    Borradores     Cargar efectos Borrad. Simplif.              Usuarios y Perfiles
Invocar login  Efectos pago   Listados                                     Copias de Seguridad
Salir          Remesas pago                                                Generador de Procesos
               Cargar efectos
               Listados                                                                  Foro soporte
                                                                                          Envío errores
                                                                                          Acerca de
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


