# Proveedores — Defectos de compra (margen, tallas) y kits de cantidades

Extiende el proveedor para que las **Sesiones de Compra**
(`inMtoComprasSesiones`, "Crear artículos y un pedido o un albarán") hereden
sus valores por defecto y sus kits de cantidades por talla.

Script de esquema: `proveedores_compras_defectos.sql` (idempotente).

---

## 1. Qué guarda ahora el proveedor

| Campo                          | Significado                                                       |
|--------------------------------|-------------------------------------------------------------------|
| `PORCENTAJE_MARGEN_PRV`        | Margen comercial por defecto. Se copia a `PORCENTAJE_MARGEN_SES`. |
| `ID_AC_TALLAS_PRV`             | Sistema de tallas por defecto (FK lógica a `fza_atributos_conjuntos`, `ID_VA_AC='TAL'`). Se copia a `ID_AC_PIVOT_SES`. |
| `fza_proveedores_kits` (+`_det`)| Biblioteca de kits: patrones de cantidades por talla.            |

### Kits (`PRVKIT` / `PRVKITD`)

Un kit es un patrón de cantidades sobre tallas predefinidas (ver
`compras_sesiones.md` §2.2):

| Kit         | 38 | 39 | 40 | 41 | 42 |
|-------------|----|----|----|----|----|
| `CURVA-STD` | 1  | 2  | 3  | 2  | 1  |
| `MUESTRA`   | 1  | 1  | 1  | 1  | 1  |

- Cabecera (`fza_proveedores_kits`): código, nombre, descripción, sistema de
  tallas para el que se diseñó (`ID_AC_TALLAS_PRVKIT`, informativo) y orden.
- Detalle (`fza_proveedores_kits_det`): `VALOR_DESTINO_PRVKITD` (texto de la
  talla: «38», «M»…) y `CANTIDAD_PRVKITD`.
- El casado al aplicar es **por texto de talla** contra los valores del
  sistema de la línea (`fza_atributos_valores.AV`), así un kit definido para
  «38-46 Caballero» también sirve en otro sistema que comparta tallas.

## 2. Pantalla Proveedores (`inMtoProveedores`)

Pestaña nueva **«6_Compras»**:

- GroupBox «Defectos para sesiones de compra»: margen % (`spnMargenPrv`) y
  sistema de tallas (`cbbTallasPrv`, lookup sobre conjuntos `TAL` activos).
- GroupBox «Kits de cantidades por talla»: grid de kits + grid de detalle
  (talla / cantidad) con botones **+ Kit / − Kit / + Talla / − Talla** y
  **«Tallas del sistema»** (genera una fila de detalle por cada talla del
  sistema del kit con cantidad 0, vía `INSERT IGNORE`, para rellenar rápido).

Queries en `UniDataProveedores`: `unqryConjuntosTallas` (lookup),
`unqryKits` / `unqryKitsDet` (master/detail con la ficha y entre sí).
Carga perezosa al entrar a la pestaña (`AsegurarComprasAbierta`), mismo
patrón que Artículos / Ventas.

## 3. Pantalla Sesiones de Compra (`inMtoComprasSesiones`)

### 3.1 Pestaña nueva «3_Proveedor»

- Ficha del proveedor de la sesión en solo lectura (código, razón social,
  nombre comercial, NIF, teléfonos, email, dirección, contacto…) más sus
  defectos (margen y sistema de tallas). Query `unqryPrvFicha` con LEFT JOIN
  al conjunto para mostrar el nombre del sistema (`NOMBRE_TALLAS_PRV`).
- Grid de kits del proveedor + detalle (solo lectura) y botón
  **«Aplicar kit a la línea actual»**.
- Botón «Ir a proveedor» abre el mantenimiento de Proveedores.
- Se recarga al navegar de sesión o cambiar `CODIGO_PRV_SES`
  (`RecargarProveedorSesion`, con guard para no reabrir si no cambia).

### 3.2 Copia de defectos al elegir proveedor

Al cambiar `CODIGO_PRV_SES` con la cabecera en edición/inserción
(`CopiarDefectosProveedor` desde `dsTablaGDataChangeHook`):

- `PORCENTAJE_MARGEN_PRV` → `PORCENTAJE_MARGEN_SES` (si el proveedor lo tiene).
- `ID_AC_TALLAS_PRV` → `ID_AC_PIVOT_SES` (si el proveedor lo tiene).

Las **líneas nuevas** heredan `ID_AC_PIVOT_SESLIN` desde
`ID_AC_PIVOT_SES` de cabecera (en `unqrySesionLinAfterInsert` del DM), por
lo que las columnas de talla del grid muestran directamente el sistema del
proveedor sin tener que elegirlo línea a línea. El usuario puede cambiarlo
por línea como siempre (botón de la columna «Sistema tallas»).

### 3.3 Aplicar kit a la fila actual

Dos caminos, ambos sobre la **línea con foco** del grid de artículos:

1. Botón **«Aplicar kit»** en la barra de la pestaña Líneas → popup con los
   kits del proveedor; al elegir uno se aplica.
2. Botón **«Aplicar kit a la línea actual»** de la pestaña Proveedor → aplica
   el kit seleccionado en el grid de kits.

Lógica en `inLibComprasSesiones.AplicarKitProveedorALinea`:

- Lee `fza_proveedores_kits_det` del kit y casa cada
  `VALOR_DESTINO_PRVKITD` contra los valores del sistema de tallas de la
  línea (`TGestorGridTallas.GetPosicionesConjunto`).
- Cada talla casada se persiste con `TGestorGridTallas.PersistirCantidad`
  (mismo UPSERT/DELETE que el tecleo manual en la celda; cantidad 0 borra).
- Refresca totales y vuelve a pintar la fila
  (`RefrescarTotalesLineaActual` + `CargarCantidadesUnaLinea`).
- Si alguna talla del kit no existe en el sistema de la línea, se informa
  con el detalle de las no casadas (las demás sí se aplican).

## 4. Archivos tocados

| Archivo                                           | Cambio                                  |
|---------------------------------------------------|-----------------------------------------|
| `DESARROLLOS EN CURSO/proveedores_compras_defectos.sql` | Esquema (nuevo).                  |
| `LIBRO_DE_ESTILO_BBDD.md`                         | Sufijos `PRVKIT` / `PRVKITD`.           |
| `src/DataModules/UniDataProveedores.pas/.dfm`     | Queries kits + lookup tallas + handlers. |
| `src/Forms/inMtoProveedores.pas/.dfm`             | Pestaña «6_Compras».                    |
| `src/DataModules/UniDataComprasSesiones.pas/.dfm` | `unqryPrvFicha` / `unqryPrvKits[Det]` + herencia sistema en líneas. |
| `src/Lib/inLibComprasSesiones.pas`                | `AplicarKitProveedorALinea`.            |
| `src/Forms/inMtoComprasSesiones.pas/.dfm`         | Pestaña «3_Proveedor», copia de defectos, botón «Aplicar kit». |

## 5. Pendiente / fuera de alcance

- Promover un kit de proveedor a kit de sesión (`fza_compras_sesiones_kits`,
  `ImportarKitsDeProveedor`) sigue siendo un stub: hoy el kit se aplica
  directamente desde la biblioteca del proveedor y no se copia a la sesión.
- «Aplicar kit a todas las líneas» de la sesión.
- `vi_proveedores` no expone las columnas nuevas (ninguna pantalla las lee a
  través de la vista). Si un buscador las necesitara, recrear la vista como
  en `vi_proveedores_nombre.sql`.
