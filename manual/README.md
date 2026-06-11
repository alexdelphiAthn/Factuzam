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
| [03 · Menú Compras](03-menu-compras.md) | Sesiones de compra, Pedidos, Albaranes, Devoluciones a proveedor, Facturas de compra y Formas de pago. |
| [04 · Menú Ventas Mayor](04-menu-ventas-mayor.md) | Facturación a mayor: Facturas, Pedidos, Albaranes, Formas de pago y Listados de ventas. |
| [05 · Menú Caja](05-menu-caja.md) | Punto de venta (TPV): menú de caja, parámetros, depósitos, históricos, arqueos y facturas simplificadas. |
| [06 · Menú Almacén](06-menu-almacen.md) | Movimientos de almacén, Inventarios e Informes de stock. |
| [07 · Menú Otros](07-menu-otros.md) | Parámetros del entorno, IVA, Contadores, Usuarios/Permisos, Copias de seguridad y Generador de procesos. |
| [08 · Menú Ayuda](08-menu-ayuda.md) | Acerca de y datos de versión. |
| [09 · Instalación en Windows](09-instalacion-windows.md) | MariaDB, base de datos inicial, instalación por puesto y puesta en marcha. |
| [10 · Migración desde software legacy](10-migracion-legacy.md) | Traslado de datos del ERP anterior (SQL Server) con el Factuzam Migrator. |

---

## La barra de menú de un vistazo

```
Archivo        Compras        Ventas Mayor   Caja           Almacén        Otros          Ayuda
─────────      ─────────      ────────────   ─────          ────────       ─────          ─────
Empresas       Sesiones       Facturas       Menú de Caja   Movimientos    Parám. entorno Acerca de
Almacenes      Pedidos        Formas de pago Parám. de Caja Inventarios    Grupos de IVA
Clientes       Albaranes      Pedidos        Formas de Pago Informes       Impuesto IVA
Proveedores    Devoluciones   Albaranes      Depósitos                     Contadores
Artículos      Facturas       Listados       Históricos                    Usuarios y Perfiles
Tablas Aux.    Formas de pago                Fac. Simplif.                 Copias de Seguridad
Invocar login                                                              Generador de Procesos
Salir
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

## Capturas de pantalla

Los capítulos incluyen **huecos para capturas** marcados así:

```
![Descripción](img/NN-nombre.png)
*▢ Captura pendiente — Descripción de lo que debe verse.*
```

Para completar un hueco basta con **guardar la captura en `manual/img/`**
con el nombre indicado (formato PNG); la imagen se mostrará automáticamente.
Una vez colocada, puede borrarse la línea *«▢ Captura pendiente…»* o
sustituirse por un pie de foto definitivo. Para localizar los huecos que
faltan: buscar `Captura pendiente` en los `.md`.

## Versión HTML del manual

El manual también está disponible como **sitio web navegable** en
`manual/html/`. Para leerlo, abre **`manual/html/index.html`** en cualquier
navegador (no necesita servidor ni conexión a internet).

### Flujo de trabajo: editar y regenerar

El HTML **no se edita a mano**: se genera a partir de los `.md`. Para
mantenerlo al día:

1. Edita el capítulo que quieras en su fichero `NN-*.md` (o el `README.md`).
2. Si añades una captura, guárdala en `manual/img/` con el nombre indicado.
3. **Regenera el HTML.** Tienes dos formas:
   - **En Windows:** doble clic en **`generar_html.bat`** (busca Python e
     informa si no está instalado).
   - **Desde consola** (cualquier sistema), en la carpeta `manual/`:

     ```
     python generar_html.py
     ```

El generador `generar_html.py` **no requiere instalar nada**: usa solo la
librería estándar de Python 3. Vuelca el resultado en `manual/html/` (una
página por capítulo, el índice de navegación lateral, la hoja de estilo
`estilo.css` y una copia de las imágenes de `img/`), sobrescribiendo lo
anterior.

> Si añades un capítulo nuevo (`11-*.md`), regístralo en la lista `ORDEN`
> de la cabecera de `generar_html.py` para que aparezca en el menú lateral.


