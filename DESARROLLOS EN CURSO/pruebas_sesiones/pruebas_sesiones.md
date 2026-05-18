# Pruebas — Sesiones de creación de artículos + pedido

Banco de pruebas para iterar variantes de UI sobre el módulo de
**sesiones de compra** (`inMtoComprasSesiones`). Cada prueba reutiliza
las tablas `fza_compras_sesiones*` y el DataModule `TdmComprasSesiones`
ya cableado; sólo cambia la pantalla.

Carpeta: `DESARROLLOS EN CURSO/pruebas_sesiones/`. El código Delphi
(`.pas` / `.dfm`) vive aquí mientras la prueba sea exploratoria; cuando
una variante se ascienda a definitiva, se mueve a `src/Forms/` y se
propaga su diseño a `compras_sesiones.md` (ver §13).

---

## Prueba 01 — Grid plano "todo en una línea" con tallas inline

Variante simplificada del Mto de sesiones: una **única pestaña** con la
cabecera arriba (los settings) y un **grid de líneas** donde cada
artículo es una fila con TODA su información — incluida la matriz de
tallas pivotada **inline** en columnas. Pensada para crear lotes
pequeños de artículos nuevos en una sola pasada visual, estilo
hoja de cálculo.

### 1. Alcance

- **Sí**: cabecera (settings), grid de líneas con tallas pivotadas
  inline, contador automático por familia, propuesta automática de PVP
  al teclear coste, selector de colores básicos con paleta, footer con
  el total de artículos del documento.
- **No** (fuera de esta prueba, por decisión expresa): kits,
  **propiedades fijas/variables**, generación de pedido/albarán,
  materialización a `fza_articulos`, **códigos de barras**, **fotos**,
  override de precios por SKU.

### 2. Cabecera (settings)

Todos los campos viven en `fza_compras_sesiones` (cabecera ya
existente). Sólo se exponen los necesarios para que la fórmula del PVP
y la generación funcionen:

| Etiqueta UI       | Columna BBDD             | Origen lookup                  |
|-------------------|--------------------------|--------------------------------|
| Serie / Número    | `SERIE_SES`/`NUMERO_SES` | Auto en `BeforePost` del DM    |
| Estado            | `ESTADO_SES`             | Read-only (`BORRADOR` inicial) |
| Empresa           | `CODIGO_EMP_SES`         | `fza_empresas`                 |
| Proveedor         | `CODIGO_PRV_SES`         | `fza_proveedores`              |
| Tarifa venta      | `CODIGO_TAR_SES`         | `vi_tarifas`                   |
| Margen (%)        | `PORCENTAJE_MARGEN_SES`  | numérico libre                 |
| Múltiplo redondeo | `MULTIPLO_REDONDEO_SES`  | numérico libre (0 = sin)       |
| Ajuste final      | `AJUSTE_FINAL_SES`       | numérico libre (puede ser <0)  |

Asunciones implícitas:
- `ESVAR_FIJA_SES = 'N'` — la variación se elige por línea.
- `ID_AC_FILA_SES = NULL` — modo "fila libre" (el color es texto + ATB
  básico por línea, sin sub-grid color×color).

### 3. Grid de líneas (1 línea = 1 artículo)

Orden visual final de las columnas:

| Col                  | Origen                                    | Notas                                                                                                       |
|----------------------|-------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| Familia (F3)         | `CODIGO_FAM_SESLIN`                       | F3 abre `TfrmModalSelFamilia`. Tecleo directo se trata igual que F3 (ver §3.1). `CharCase = ecUpperCase`.   |
| Cód. artículo        | `CODIGO_ART_TENTATIVO_SESLIN`             | Read-only. Lo rellena `ExpandirCodigoFamiliaActiva` con `FAMILIA + LPAD(contador, PAD_ART_FAM, '0')`.       |
| Modelo prov.         | `REF_PRV_SESLIN`                          | Código/referencia del proveedor para la prenda. Texto libre.                                                |
| Descripción          | `DESCRIPCION_SESLIN`                      | Prerellenada con `NOMBRE_FAM_FAM` cuando se asigna la familia; editable.                                    |
| Color                | `COLOR_TEXTO_SESLIN`                      | Texto libre del color del proveedor. NUEVA columna.                                                         |
| Color básico         | `CODIGO_ATB_COLOR_SESLIN`                 | Selector con paleta (mismo `TcxButtonEdit` + `SeleccionarAvConPaleta` que `inMtoInventarios`). NUEVA col.   |
| Pr. compra           | `PRECIO_COMPRA_SESLIN`                    | Al cambiar, propone Pr. venta vía `inLibComprasSesiones.CalcularPrecioVenta`.                               |
| Pr. venta            | `PRECIO_VENTA_SESLIN`                     | Calculado pero override-able.                                                                               |
| Sistema tallas       | `ID_AC_PIVOT_SESLIN`                      | Lookup `fza_atributos_conjuntos`. Validación: si tiene > `CANT_TALLAS_MAX` valores → `mtError` (ver §3.4).  |
| Talla 1..N           | No-bound → `fza_compras_sesiones_celdas`  | N = máximo de valores entre los conjuntos del documento. Captions siguen al sistema de la línea con foco.   |
| Total tallas         | `TOTAL_UNIDADES_SESLIN`                   | Read-only. Suma de cantidades en celdas. Lleva además footer summary (`skSum`) que muestra el total del documento al pie del grid (`OptionsView.Footer=True`). |
| Importe s/IVA        | `TOTAL_LINEA_SESLIN`                      | Read-only. = `TOTAL_UNIDADES × PRECIO_COMPRA`.                                                              |
| Línea                | `LINEA_SESLIN`                            | Editable, spin de paso 10. Permite intercalar (escribir 15 entre 10 y 20).                                  |

#### 3.1 Familia → código artículo (F3 y tecleo manual)

Tanto pulsar F3 sobre la columna Familia como teclear directamente el
código de la familia llaman al helper `ExpandirCodigoFamiliaActiva`,
que delega en `inLibComprasSesiones.ResolverCodigoFamilia`:

1. Verifica que la familia exista (`ESACTIVO_FAM = 'S'`) y tenga
   `ESCONTADOR_ART_FAM = 'S'`.
2. Bloquea la fila (`SELECT … FOR UPDATE`) e incrementa
   `CONTADOR_ART_FAM`.
3. Compone `CODIGO_ART = CODIGO_FAM + LPAD(CONTADOR, PAD_ART_FAM, '0')`.
4. Persiste `CODIGO_ART_TENTATIVO_SESLIN`.
5. Si la descripción está vacía, copia `NOMBRE_FAM_FAM` (consulta
   directa a `fza_articulos_familias` cuando el flujo no viene del
   modal F3).

La expansión ocurre **en vivo**, antes de que la línea posteie — el
usuario ve `BOLSOS00001` al instante. El `BeforePost` del DM repite
la llamada de forma idempotente: con un código ya expandido
(`BOLSOS00001`), `ResolverCodigoFamilia` no encuentra familia y no
vuelve a incrementar el contador.

Skip anti-doble-consumo: si el código tentativo ya empieza por la
familia actual (`BOLSOS00001` y la nueva familia es `BOLSOS`), no
volvemos a llamar a `ResolverCodigoFamilia`.

Consecuencia documentada (de `compras_sesiones.md §2.4-bis`): el
contador se quema al teclear/F3 aunque el usuario cancele luego la
línea. Gap aceptado a cambio de poder etiquetar/escanear desde el
primer momento.

#### 3.2 Propuesta automática de PVP

Cuando el usuario cambia `PRECIO_COMPRA_SESLIN` en una línea, el form
calcula y persiste `PRECIO_VENTA_SESLIN` aplicando la fórmula ya
existente (`inLibComprasSesiones.CalcularPrecioVenta`):

```
base   = coste × margen / 100                  -- margen de cabecera
venta  = ceil(base / múltiplo) × múltiplo − ajuste
```

Convención del margen (igual que `inMtoModalCalcularMargen`): el campo
es un multiplicador × 100. `margen = 100` deja el coste tal cual,
`margen = 250` lo multiplica por 2,5.

El **ajuste final se RESTA** del redondeado (convención descuento
final: introducir `0,01` para terminar en `.99`). Ejemplo:
coste 12 × margen 250 = `12 × 250 / 100 = 30,00` → ceil(30/1) × 1 =
30,00 → 30,00 − 0,01 = **29,99**.

El margen por línea puede sobreescribir el de cabecera vía
`PORCENTAJE_MARGEN_SESLIN` (no expuesto en esta prueba; queda para
una iteración posterior). El usuario puede a su vez editar
`PRECIO_VENTA_SESLIN` para fijar manualmente.

#### 3.3 Color básico — selector con paleta

La columna Color básico es un `TcxButtonEdit` con el mismo combo que
el grid de SKUs de `inMtoInventarios`:

- **Glyph dinámico**: el botón pinta un swatch (cuadradito coloreado)
  con el HEX del basico actual (`inLibAtributosPaleta.PintarSwatchEnBitmap`).
- **Custom draw**: la celda dibuja swatch + texto vía
  `PintarCeldaConCuadradoColor`.
- **Popup**: al pulsar el botón, `SeleccionarAvConPaleta` abre un
  dropdown owner-drawn con todos los `fza_atributos_basicos.CODIGO_ATB`
  donde `ID_VA_ATB = 'CO'` y `ESACTIVO_ATB = 'S'`.

Se guarda `CODIGO_ATB` (varchar) directamente — no el ID — porque el
selector trabaja con códigos y la caché de paleta resuelve el HEX por
`(ID_VA_ATB='CO', CODIGO_ATB)`.

#### 3.4 Validación del sistema de tallas (max 20)

`CANT_TALLAS_MAX = 20` (constante). Si el usuario elige un sistema con
más de 20 valores en `fza_atributos_conjuntos_det`,
`dbcLinTallasPropertiesEditValueChanged` muestra `mtError` con el
número real vs el máximo y limpia `ID_AC_PIVOT_SESLIN` **antes** de
postear/reasignar columnas — el grid no se reordena con un conjunto
que no cabe.

### 4. Edición inline de tallas

- **Edición INLINE** en la propia línea del artículo. No hay matriz
  debajo del grid: las cantidades se teclean directamente en cada
  celda de talla, dentro de la fila del artículo.
- **Número de columnas visibles = máximo** de valores entre todos los
  sistemas de tallas referenciados por alguna línea de la sesión.
  Recalculado al cambiar el conjunto pivot en cualquier línea (`MaxLongConjuntosSesion`).
- Las líneas con conjuntos más cortos tienen **columnas en blanco** al
  final de las tallas (no rotuladas, no editables — sus posiciones
  fuera del propio conjunto se descartan en `TallaCellEditValueChanged`).
- **Captions dinámicas**: al cambiar el foco de fila
  (`OnFocusedRecordChanged`), los rótulos de las columnas de talla se
  actualizan al sistema de esa línea (`ActualizarCaptionsTallasLineaActiva`).

### 5. Detalles técnicos de la edición inline

Las columnas de talla son **no-bound**
(`DataBinding.ValueTypeClass = TcxFloatValueType`, sin `FieldName`,
`PropertiesClass = TcxCurrencyEditProperties`). Se crean en runtime
(`CrearColumnasTallas`) entre `dbcLinTallas` (sistema) y
`dbcLinTotalTallas` para mantener el orden visual.

- **Lectura** (`CargarCantidadesTodasLineas` /
  `CargarCantidadesUnaLinea`): al abrir la sesión, recorre las celdas
  existentes en BBDD y las publica en las columnas no-bound vía
  `tvLineas.DataController.Values[record, col]`. La posición se
  calcula desde el conjunto pivot de la línea
  (`fza_atributos_conjuntos_det` ordenado por `ORDEN_ACD`).
- **Escritura** (`TallaCellEditValueChanged`): cuando el usuario
  teclea en una celda, leemos `LINEA_SESLIN` + `ID_AC_PIVOT_SESLIN`,
  resolvemos el `ID_AV` por posición (`Tag` de la columna) y
  persistimos vía upsert SQL (`INSERT … ON DUPLICATE KEY UPDATE` o
  `DELETE` si cantidad = 0).
- **Caché** (`FConjuntoPos: TDictionary<ID_AC, TArrPosConjunto>`):
  posiciones por conjunto para no reconsultar
  `fza_atributos_conjuntos_det` en cada edición.

### 6. UX del grid

- **Enter mueve de celda en celda** dentro del grid (no sale del
  control). Implementado vía dos vías redundantes:
  - `OptionsBehavior.FocusCellOnTab = True` + `FocusCellOnCycle = True`:
    si `TJvEnterAsTab` (heredado de `TfrmBase`) convierte Enter→Tab,
    el grid captura el Tab y va a la siguiente celda — patrón de
    `inMtoInventarios`.
  - `cxgrdLineas.OnEnter`/`OnExit` apagan/encienden `EnterAsTab` para
    todas las instancias de `TJvEnterAsTab` encontradas en `Self`,
    `Owner` y `Application.MainForm`. Cinturón y tirantes.
- **SelectAll al editar** (`tvLineasInitEdit`): estilo Excel — al
  entrar a una celda de texto el contenido queda seleccionado, así
  una pulsación lo sustituye y Tab/Enter lo deja como está.
- **F3 sobre Familia** abre el modal selector jerárquico
  (`TfrmModalSelFamilia`).
- **Total tallas** se ve por fila (= TOTAL_UNIDADES de la línea) y
  con `Kind = skSum` al pie del grid (`OptionsView.Footer = True`) —
  ahí se ve la suma de cantidades de todo el documento. Una sola
  columna; se intentó tener tambien una «Total artículos» separada
  pero al ser bound al mismo campo el guardado/restauración de
  perfiles del grid creaba duplicidades.
- **Línea editable** con spin de paso 10: si el usuario quiere
  intercalar una línea, edita el número a uno entre dos existentes
  (p.ej. 15 entre 10 y 20). `unqrySesionLinAfterInsert` ya numera de
  10 en 10 desde `CONTADOR_LINEAS_SES`.

### 7. Modelo de datos — qué cambia

#### 7.1 Tabla `fza_compras_sesiones_lineas`

Dos columnas nuevas en SESLIN para almacenar el "atributo no-pivot"
de cada línea de forma plana (en la prueba se cubre el caso de
**color** pero el patrón es genérico — se puede replicar para MATERIAL,
TEMPORADA, etc. con un nuevo par TEXTO+ATB o moviéndolo a una tabla
hija si el número crece).

```sql
ALTER TABLE fza_compras_sesiones_lineas
  ADD COLUMN COLOR_TEXTO_SESLIN       varchar(100) DEFAULT NULL,
  ADD COLUMN CODIGO_ATB_COLOR_SESLIN  varchar(100) DEFAULT NULL;
```

Se almacena `CODIGO_ATB` (varchar) en vez de `ID_ATB` (int) para que
el selector reutilizado de inventarios (`SeleccionarAvConPaleta` de
`inLibAtributosPaleta`) opere directamente: ese picker trabaja con
códigos de la paleta básica (`NEGRO`, `AZUL`, `AZUL_MARINO`…) y la
caché resuelve el HEX por `(ID_VA_ATB='CO', CODIGO_ATB)`.

Idempotente: en `pruebas_sesiones.sql` se envuelve en bloques
`INFORMATION_SCHEMA` (mismo patrón que `compras_sesiones.sql`).

#### 7.2 SESFIL no se usa en esta prueba

La prueba inline edita cantidades directamente en
`fza_compras_sesiones_celdas` con `ID_FILA_SES_SESCEL = 1` fijo (una
fila lógica por línea — no hay sub-grid color×color). No se inserta
nada en `fza_compras_sesiones_lineas_filas` ni en `_filas_atr`: el
atributo libre + el ATB básico ya viven denormalizados en SESLIN
(`COLOR_TEXTO_SESLIN` y `CODIGO_ATB_COLOR_SESLIN`).

Si la prueba se promueve a Mto real, la materialización tendrá que
generar las filas SESFIL/SESFILAT correspondientes a partir de SESLIN
para que el flujo de `fza_articulos_skus` siga el patrón habitual.

#### 7.3 Genericidad — pensando en más atributos

El par `COLOR_TEXTO_SESLIN + CODIGO_ATB_COLOR_SESLIN` es el atributo
no-pivot principal. Si en el futuro se quieren manejar más
(MATERIAL+ATB, TEMPORADA+ATB, …) sin migrar de modelo:

- **Opción rápida**: añadir más pares de columnas a SESLIN
  (`MATERIAL_TEXTO_SESLIN`, `CODIGO_ATB_MATERIAL_SESLIN`, etc.).
- **Opción correcta**: migrar el par a una tabla hija
  `fza_compras_sesiones_lineas_atrib` con (`ID_VA`, `CODIGO_ATB`,
  `TEXTO`), PK por (SERIE,NUMERO,LINEA,ID_VA). Esta es la dirección
  que toma el schema final si se promueve la prueba.

### 8. Master-detail al añadir línea — detalle de implementación

`btnAddLineaClick` hace `unqryTablaG.Post` (para fijar SERIE+NUMERO si
veníamos de cabecera en `dsInsert`) y **vuelve a poner el master en
`Edit`** ANTES de `unqrySesionLin.Insert`. Sin ese segundo `Edit`, el
`AfterInsert` del DM se encuentra el master en `dsBrowse`, llama a
`Edit` desde dentro y la transición rompe el `dsInsert` del detail
master-detail — las asignaciones siguientes (`SERIE_SES_SESLIN`, …)
revientan con `'Dataset not in edit or insert mode'`.

### 9. Reuso de código (lo que la prueba **no** reinventa)

| Pieza ya existente                                                | Uso en la prueba                                       |
|-------------------------------------------------------------------|--------------------------------------------------------|
| `TdmComprasSesiones`                                              | DM completo: cabecera, líneas, celdas, lookups         |
| `inLibComprasSesiones.ResolverCodigoFamilia`                      | Familia → código autogenerado (F3 + tecleo manual)     |
| `inLibComprasSesiones.CalcularPrecioVenta`                        | Propuesta de PVP al cambiar coste                      |
| `inLibAtributosPaleta.SeleccionarAvConPaleta`                     | Selector dropdown con swatch (mismo que inventarios)   |
| `inLibAtributosPaleta.ObtenerInfoBasico` + `PintarSwatchEnBitmap` | Glyph del botón con el cuadradito del color actual     |
| `inLibAtributosPaleta.PintarCeldaConCuadradoColor`                | Custom-draw de la celda Color básico                   |
| `TfrmModalSelFamilia`                                             | Picker jerárquico con F3                               |
| `fza_winforms`                                                    | Mapeo form ↔ DM (entrada nueva «PruebaSesionGrid»)     |

### 10. Ficheros de la prueba

```
DESARROLLOS EN CURSO/pruebas_sesiones/
├── pruebas_sesiones.md          ← este documento
├── pruebas_sesiones.sql         ← ALTERs idempotentes + winform
├── inMtoPruebaSesionGrid.pas    ← TfrmMtoPruebaSesionGrid
└── inMtoPruebaSesionGrid.dfm
```

Registrado en `fzam.dpr` con el path largo
`'DESARROLLOS EN CURSO\pruebas_sesiones\inMtoPruebaSesionGrid.pas'`. El
DM lo aporta `UniDataComprasSesiones` (ya en el dpr).

### 11. Flujo del usuario

```
1. Menú → Compras → Sesiones → Prueba grid (Ctrl+Shift+S).
   ↓
2. Tab Lista: ver sesiones existentes o pulsar [+] para nueva.
   ↓
3. Tab Ficha: rellenar Empresa, Proveedor, Tarifa, Margen,
              Múltiplo, Ajuste. Grabar.
   ↓
4. Botón [+ Línea]: añade fila al grid de artículos.
   ↓
5. En la fila:
   - F3 (o teclea) Familia → BOLSOS → contador → BOLSOS00001
     y descripción «Bolsos y Mochilas» auto-rellenada
   - Modelo prov. = «EDT0003»
   - Color = «AZUL TURQUESA PROV-XYZ»
   - C. básico → selector paleta → AZUL
   - Pr. compra = 4,80 → se propone Pr. venta = 7,49 (vía fórmula)
   - Sistema tallas = «42-46 Caballero» → la fila despliega 5
     columnas TALLA con rótulos 42, 43, 44, 45, 46.
     (Si el sistema tuviera >20 valores → mtError y se descarta.)
   ↓
6. En la propia fila tecleas las cantidades 1, 2, 3, 2, 1 con Enter
   moviendo de celda en celda. Total tallas, Importe s/IVA y Total
   artículos se refrescan. El footer del grid muestra la suma total
   del documento.
   ↓
7. Repites pasos 4-6 para más artículos. Si una línea nueva usa un
   conjunto con más tallas, el grid amplía sus columnas TALLA; las
   líneas anteriores con conjuntos más cortos quedan con celdas en
   blanco al final. Grabar.
```

### 12. Patrón reutilizable a futuro — grid tallas inline en todo Compras

Esta prueba es el **banco de pruebas del patrón "grid de tallas
inline"**. Los clientes compran en **horizontal** (una fila por
artículo + cantidades por talla en columnas), no en vertical (una
fila por talla). Ese patrón aparece en todo el módulo de Compras:

| Documento                    | Mto actual / nuevo            | Tabla líneas              | Tabla celdas (necesaria)         |
|------------------------------|-------------------------------|---------------------------|----------------------------------|
| Sesión de compra             | `inMtoComprasSesiones` (prod) | `fza_compras_sesiones_lineas` | `fza_compras_sesiones_celdas`  |
| Pedido de compra (proveedor) | nuevo (`fza_pedidos_compra`)  | `fza_pedidos_compra_lineas`   | `fza_pedidos_compra_celdas` (a crear) |
| Albarán de compra            | nuevo (`fza_albaranes_compra`)| `fza_albaranes_compra_lineas` | `fza_albaranes_compra_celdas` (a crear) |
| Factura de compra            | `inMtoFacturas*` cuando `CODIGO_PRV_FAC` no NULL | `fza_facturas_lineas`     | `fza_facturas_celdas` (a crear)  |

Lo que esta prueba está estabilizando para reutilizarse en los demás:

- **Creación dinámica de N columnas no-bound** (`CrearColumnasTallas`)
  con `PropertiesClass = TcxCurrencyEditProperties`, `ValueTypeClass
  = TcxFloatValueType` y `Tag` como índice posicional.
- **Cálculo del máximo de tallas del documento**
  (`MaxLongConjuntosSesion`) para decidir cuántas columnas mostrar.
- **Captions dinámicos** al cambiar foco
  (`ActualizarCaptionsTallasLineaActiva`).
- **Caché del conjunto pivot** (`FConjuntoPos: TDictionary<ID_AC,
  TArrPosConjunto>`) para no reconsultar.
- **Persistencia upsert por celda**
  (`PersistirCantidad`, INSERT…ON DUPLICATE KEY UPDATE / DELETE si 0).
- **Carga inicial con `DisableControls`** para no perder filas tras
  Post/refresh (`CargarCantidadesTodasLineas`).
- **`FocusCellOnTab` + `GoToNextCellOnEnter`** para que Enter
  navegue celda a celda sin pelearse con `TJvEnterAsTab`.
- **`SelectAll` en `InitEdit`** estilo Excel.
- **Footer summary** (`Kind = skSum`) con el total del documento.

#### Plan de extracción cuando la prueba estabilice

Cuando se consolide la UX y el modelo de datos, extraer todo el
montaje a una unidad reutilizable, p.ej. `inLibGridTallasInline`:

```pascal
TGridTallasInline = class
public
  constructor Create(AOwnerForm: TForm;
                     AGrid: TcxGridDBTableView;
                     ASourceLineas: TDataSource;
                     ATablaCeldas: string;     // 'fza_compras_sesiones_celdas'
                     APrefijoCeldas: string;   // 'SESCEL'
                     APrefijoLineas: string);  // 'SESLIN'
  procedure MontarColumnas(ARefIndex: TcxGridDBColumn;
                           ANombreCampoConjunto: string;  // 'ID_AC_PIVOT_SESLIN'
                           ANombreCampoLinea: string;     // 'LINEA_SESLIN'
                           ANombreCampoCantidad: string;  // 'CANTIDAD_SESCEL'
                           AColumnaFooter: TcxGridDBColumn = nil);
  procedure CargarTodasLineas;
  procedure RefrescarMaxColumnas;
end;
```

Cada Mto que quiera adoptar el patrón crearía una instancia del
gestor en su `FormCreate` apuntando a las tablas/campos de su
documento. La generalización valdrá tanto para Sesiones (ya
hecho) como para los Pedidos/Albaranes/Facturas que vendrán.

A nivel de BBDD habrá que crear las tablas paralelas
`fza_<doc>_celdas` con la misma estructura (`SERIE`, `NUMERO`,
`LINEA`, `ID_AV_PIVOT`, `CODIGO_ALM`, `CANTIDAD`) y la
materialización entre documentos (Sesión → Pedido → Albarán →
Factura) tendrá que arrastrar también las celdas.

### 13. Limitaciones reconocidas

- Sin materialización: la sesión vive en `BORRADOR`. Promoverla a
  pedido/albarán es el flujo del Mto real, no de esta prueba.
- Sin foto, sin código de barras, sin propiedades de familia
  (fijas/variables) — a propósito; el Mto real cubre todos esos
  casos. Esta prueba se centra en el flujo «coste + tallas →
  artículos».
- Una sola fila lógica por línea (`ID_FILA_SES_SESCEL = 1`). Para
  artículos con multi-color cada color requeriría su propia línea
  con su propio código.
- Un solo almacén por documento (`CODIGO_ALM_SES` de cabecera, sin
  capas multi-almacén como sí hay en el Mto real).

### 14. Cambios a propagar a `compras_sesiones.md` cuando la prueba estabilice

Estos puntos van al doc de producción si la variante se asciende:

1. **DDL**: añadir `COLOR_TEXTO_SESLIN` y `CODIGO_ATB_COLOR_SESLIN` (o
   la versión normalizada en tabla hija — §7.3) al schema oficial.
2. **Materialización**: extender `InLibComprasSesionesMaterializar`
   para generar `fza_articulos_atributos_basicos` desde
   `CODIGO_ATB_COLOR_SESLIN` (mapear el ATB básico al SKU creado).
3. **Helper compartido**: extraer `ExpandirCodigoFamiliaActiva` a
   `inLibComprasSesiones` (hoy vive en el form) si se reutiliza desde
   el Mto real para que el código en vivo aparezca al pulsar F3.
4. **UX**: `FocusCellOnTab = True` + `FocusCellOnCycle = True` +
   `SelectAll` en `InitEdit` son patrones que el Mto real debería
   adoptar también para que Enter navegue las celdas y la edición sea
   estilo Excel.
5. **Validación**: documentar el límite `CANT_TALLAS_MAX = 20` como
   constante global (o configurable por instalación) y propagarla a
   las pantallas del Mto real que pintan matriz pivotada.
6. **Footer**: añadir `FooterSummaryItems` en `Total tallas` del
   grid de líneas del Mto real (suma del documento).
7. **Línea editable**: el spin de paso 10 en `LINEA_SESLIN` para
   intercalar es trasplantable tal cual al Mto real.
