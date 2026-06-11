# Proveedores — Margen por defecto y kits de cantidades por talla

Extiende el proveedor para que las **Sesiones de Compra**
(`inMtoComprasSesiones`, "Crear artículos y un pedido o un albarán") hereden
su margen por defecto y dispongan de su biblioteca de kits de cantidades por
talla.

Script de esquema: `proveedores_compras_defectos.sql` (idempotente).

---

## 1. Qué guarda ahora el proveedor

| Campo                           | Significado                                                       |
|---------------------------------|-------------------------------------------------------------------|
| `PORCENTAJE_MARGEN_PRV`         | Margen comercial por defecto. Se copia a `PORCENTAJE_MARGEN_SES`. |
| `fza_proveedores_kits` (+`_det`)| Biblioteca de kits: patrones de cantidades por talla.            |

> El **sistema de tallas por defecto** del proveedor se descartó: cada kit
> lleva el suyo (`ID_AC_TALLAS_PRVKIT`) y las líneas de la sesión eligen el
> suyo en la columna «Sistema tallas». La columna `ID_AC_TALLAS_PRV` del
> primer borrador ya no se crea; si quedó en alguna BBDD migrada es un
> huérfano inocuo (no se lee).

### Kits (`PRVKIT` / `PRVKITD`)

Un kit es un patrón de cantidades sobre tallas predefinidas (ver
`compras_sesiones.md` §2.2):

| Kit         | 38 | 39 | 40 | 41 | 42 |
|-------------|----|----|----|----|----|
| `CURVA-STD` | 1  | 2  | 3  | 2  | 1  |
| `MUESTRA`   | 1  | 1  | 1  | 1  | 1  |

- Cabecera (`fza_proveedores_kits`): código, nombre, **sistema de tallas**
  (`ID_AC_TALLAS_PRVKIT`) y orden. (`DESCRIPCION_PRVKIT` existe en la tabla
  pero ya no se muestra ni se rellena: con código y nombre basta.)
- Detalle (`fza_proveedores_kits_det`): `VALOR_DESTINO_PRVKITD` (texto de la
  talla: «38», «M»…) y `CANTIDAD_PRVKITD`.
- Para aplicar un kit, su tallaje **debe coincidir** con el de la línea
  (`ID_AC_TALLAS_PRVKIT = ID_AC_PIVOT_SESLIN`); si no, se muestra una
  advertencia y no se aplica nada. Una vez validado, cada talla del kit se
  casa por texto contra los valores del sistema (`fza_atributos_valores.AV`)
  para mapear su columna.

## 2. Pantalla Proveedores (`inMtoProveedores`)

Pestaña nueva **«6_Compras»**:

- GroupBox «Defectos para sesiones de compra»: solo **margen %**
  (`spnMargenPrv`).
- GroupBox «Kits de cantidades por talla»: grid de kits (Código, Nombre,
  Sistema tallas) + grid de detalle (talla / cantidad) con botones
  **+ Kit / − Kit / + Talla / − Talla** y **«Añadir todas las tallas»**:
  si el kit tiene sistema de tallas, genera una fila de detalle por cada
  talla de ese sistema con cantidad 0 (vía `INSERT IGNORE`,
  `GenerarTallasKitActual`); el usuario solo edita las cantidades.

Queries en `UniDataProveedores`: `unqryConjuntosTallas` (lookup del sistema
de cada kit), `unqryKits` / `unqryKitsDet` (master/detail). Carga perezosa
al entrar a la pestaña (`AsegurarComprasAbierta`), mismo patrón que
Artículos / Ventas.

## 3. Pantalla Sesiones de Compra (`inMtoComprasSesiones`)

### 3.1 Desplegable «Aplicar kit» en la cabecera

En el GroupBox «Cabecera» hay un desplegable **«Kit a aplicar»**
(`cbbKitProv`) con los kits del proveedor de la sesión y un botón
**«Aplicar kit a la línea»** (`btnAplicarKitCab`). El desplegable muestra
una **etiqueta descriptiva** por kit:

```
NOMBRE  SISTEMA  primera_talla(cant)...última_talla(cant)
p. ej.  «OPC A  Calzado Hombre EU 39-44  39(1)...44(2)»
```

La etiqueta la calcula `unqryPrvKitsCombo` (SQL en `DataModuleCreate`):
nombre del kit + nombre del sistema de tallas + primera y última talla con
`CANTIDAD_PRVKITD > 0` (subconsultas con `ORDER BY ORDEN_PRVKITD
ASC/DESC LIMIT 1`); el formato de cantidad recorta ceros/decimales
sobrantes (`1`, `1.5`). `KeyFieldNames = CODIGO_PRVKIT`, columna visible
`ETIQUETA_KIT`.

### 3.2 Pestaña «3_Proveedor»

- Ficha del proveedor de la sesión en solo lectura (código, razón social,
  nombre comercial, NIF, teléfonos, email, dirección, contacto y **margen**).
  Query `unqryPrvFicha` (`SELECT * FROM fza_proveedores`).
- Grid de kits del proveedor + detalle (solo lectura) y botón
  **«Aplicar kit a la línea actual»** (aplica el kit seleccionado en el grid).
- Botón «Ir a proveedor» abre el mantenimiento de Proveedores.
- Ficha, kits y desplegable se recargan al navegar de sesión o cambiar
  `CODIGO_PRV_SES` (`RecargarProveedorSesion`, con guard para no reabrir si
  no cambia).

### 3.3 Copia del margen al elegir proveedor

Al cambiar `CODIGO_PRV_SES` con la cabecera en edición/inserción
(`CopiarDefectosProveedor` desde `dsTablaGDataChangeHook`):

- `PORCENTAJE_MARGEN_PRV` → `PORCENTAJE_MARGEN_SES` (si el proveedor lo tiene;
  alimenta el PVP propuesto al teclear el coste).

El sistema de tallas se elige por línea (columna «Sistema tallas»), no se
hereda del proveedor.

### 3.4 Aplicar kit a la fila actual

Tres caminos, todos sobre la **línea con foco** del grid de artículos y todos
vía `AplicarKitALineaActual`:

1. Desplegable **«Kit a aplicar»** + botón **«Aplicar kit a la línea»** de la
   cabecera (con etiqueta descriptiva).
2. Botón **«Aplicar kit»** de la barra de la pestaña Líneas → popup con los
   kits del proveedor.
3. Botón **«Aplicar kit a la línea actual»** de la pestaña Proveedor → aplica
   el kit seleccionado en el grid de kits.

Lógica en `inLibComprasSesiones.AplicarKitProveedorALinea`:

- La línea debe tener **sistema de tallas** (`ID_AC_PIVOT_SESLIN`); si no, se
  avisa para que el usuario lo asigne primero.
- **Validación de tallaje**: el sistema del kit (`ID_AC_TALLAS_PRVKIT`) debe
  coincidir con el de la línea. Si el kit no tiene sistema o es distinto, se
  muestra una **advertencia** con ambos nombres («kit = X, línea = Y») y no
  se aplica nada.
- Validado el tallaje, lee `fza_proveedores_kits_det` y casa cada
  `VALOR_DESTINO_PRVKITD` por texto contra los valores del sistema
  (`TGestorGridTallas.GetPosicionesConjunto`) para mapear su columna.
- Cada talla casada se persiste con `TGestorGridTallas.PersistirCantidad`
  (mismo UPSERT/DELETE que el tecleo manual en la celda; cantidad 0 borra).
- Refresca totales y vuelve a pintar la fila
  (`RefrescarTotalesLineaActual` + `CargarCantidadesUnaLinea`).
- Red de seguridad: si una talla tecleada a mano en el kit no existe en el
  conjunto, se informa con el detalle de las no casadas (las demás sí se
  aplican).

### 3.5 Formato distribuido: kit por almacén

Si la sesión es de **formato distribuido** (`ESFORMATO_DISTRIBUIDO_SES =
'S'`, cantidades por almacén), «Aplicar kit» no vuelca inline: tras validar
el tallaje (misma regla que §3.4) abre el **distribuidor en modo kit**
(`AbrirDistribuidor(ACodigoKit)` → `TfrmModalDistribuidor.Preparar` con
proveedor + kit):

- La matriz almacenes × tallas de siempre, más una columna de acciones
  «Kit CODIGO» con dos botones **siempre visibles** por almacén
  (`Options.ShowEditButtons = isebAlways`):
  - **Aplicar** — vuelca la curva del kit sobre ese almacén (solo las
    tallas que el kit define; las demás se conservan).
  - **Limpiar** — pone a 0 todas las tallas de ese almacén.
- Botón de cabecera **«Aplicar kit en todos los almacenes»**
  (`btnKitTodos`) que recorre el cuadrante aplicando la curva a cada fila.
- Nada se persiste hasta **Aceptar**: el modal sigue comparando contra su
  snapshot (`PersistirCambios`), así que Cancelar descarta también lo
  aplicado por el kit, y el usuario puede retocar cantidades a mano antes
  de confirmar.

## 4. Archivos tocados

| Archivo                                           | Cambio                                  |
|---------------------------------------------------|-----------------------------------------|
| `DESARROLLOS EN CURSO/proveedores_compras_defectos.sql` | Esquema (margen + tablas kits).   |
| `LIBRO_DE_ESTILO_BBDD.md`                         | Sufijos `PRVKIT` / `PRVKITD`.           |
| `src/DataModules/UniDataProveedores.pas/.dfm`     | Queries kits + lookup tallas + handlers. |
| `src/Forms/inMtoProveedores.pas/.dfm`             | Pestaña «6_Compras».                    |
| `src/DataModules/UniDataComprasSesiones.pas/.dfm` | `unqryPrvFicha` / `unqryPrvKits[Det]` / `unqryPrvKitsCombo`. |
| `src/Lib/inLibComprasSesiones.pas`                | `ValidarKitSobreLineaActual` + `AplicarKitProveedorALinea`. |
| `src/Forms/inMtoComprasSesiones.pas/.dfm`         | Desplegable + botón en cabecera, pestaña «3_Proveedor», copia de margen. |
| `src/Modals/inMtoModalDistribuidor.pas/.dfm`      | Modo kit: botones Aplicar/Limpiar por almacén + «en todos». |

## 5. Pendiente / fuera de alcance

- Promover un kit de proveedor a kit de sesión (`fza_compras_sesiones_kits`,
  `ImportarKitsDeProveedor`) sigue siendo un stub: hoy el kit se aplica
  directamente desde la biblioteca del proveedor y no se copia a la sesión.
- «Aplicar kit a todas las líneas» de la sesión.
- `vi_proveedores` no expone la columna nueva (ninguna pantalla la lee a
  través de la vista). Si un buscador la necesitara, recrear la vista como
  en `vi_proveedores_nombre.sql`.
