# ColumnSKUcxGrid — entrada de artículos en cxGrid por contrato

Prueba de un conjunto de **clases e interfaces (con GUID)** para que
cualquier documento (pedido, albarán, factura, traspaso, sesión de
compra…) monte la entrada de artículos sobre su `TcxGridDBTableView`
sin conocer la implementación, eligiendo entre dos modos:

- **Modo SKU** (`mcsSku`): artículo/color/talla en **una columna**
  (el `CODIGO_UNIDAD_SKU` completo), con búsqueda incremental por
  código de SKU.
- **Modo desglose** (`mcsDesglose`): columna de artículo + columnas
  de color y talla, delegando en `inLibGridArticulos`
  (`TGridArticulosLineas`), ya en producción en caja y traspasos.

Es la primera unidad del repo que usa interfaces Pascal con GUID
(hasta ahora todo eran clases `TObject` + records). Decisión tomada a
propósito como prueba de concepto.

## Ficheros

**(07/07/2026) Units PROMOCIONADAS a `src/Lib/`** tras validar la
integración en Inventarios: `inLibColumnasSkuIntf`, `inLibColumnasSku`
y los tres modos compilan ya dentro de `fzam.dpr` (sin search path
extra). En esta carpeta quedan el banco de pruebas
(`ColumnSKUcxGridTest` + `inMtoPrueba*`), los SQL y este documento.

| Fichero | Contenido |
|---|---|
| `inLibColumnasSkuIntf.pas` | Contratos: `IModoEntradaGrid`, `IProveedorValoresSku`, records `TConfigColumnasSku` / `TCamposColumnasSku`, enum `TModoColumnasSku`, evento `TSkuResueltoEvent`. |
| `inLibColumnasSkuModoSku.pas` | `TModoEntradaSku`: una columna SKU con búsqueda incremental en servidor + paleta para elegir color/talla. |
| `inLibColumnasSkuModoDesglose.pas` | `TModoEntradaDesglose`: adaptador fino sobre `TGridArticulosLineas` (no duplica nada). |
| `inLibColumnasSkuModoTallas.pas` | `TModoEntradaTallas`: tallas en horizontal (pivote) sobre `TGestorGridTallas`, con distribuido por almacén y des-pivote (`Desmontar`). |
| `inLibColumnasSku.pas` | Factoría `CrearModoEntradaGrid` + detección `mcsAuto` + `CrearProveedorValoresSku`. |
| `inMtoPruebaColumnasSku.pas/.dfm` | Formulario de prueba: radio Auto/SKU/Tallas, almacén, check distribuido, grid con `TClientDataSet` en memoria, memo de log. |
| `prueba_columnas_sku.sql` | DDL de referencia de la tabla de celdas desechable `fza_prueba_skucel` (el banco la recrea por sesión). |
| `ColumnSKUcxGridTest.dpr/.dproj` | Proyecto independiente (no toca `fzam.dproj`): logon → banco de pruebas. |
| `inMtoPruebaColumnasSkuLogon.pas/.dfm` | Logon mínimo: conecta a MariaDB (UniDAC/MySQL) y asigna `inLibGlobalVar.oConn`. Recuerda los datos en `ColumnSKUcxGridTest.ini` junto al exe (contraseña en claro: no distribuir). |

No hay script SQL de esquema productivo: **no toca esquema**. Solo
consulta tablas ya existentes (`fza_articulos_skus`, `fza_articulos`,
`fza_articulos_stockactual`) y reutiliza los índices de
`indices_busqueda_skus.sql` (la tabla `fza_prueba_skucel` es
desechable y solo del banco de pruebas).

Ficheros de PRODUCCIÓN tocados durante la prueba (revisar antes de
commitear):

- `src/Lib/inLibGridArticulos.pas`: búsqueda incremental (UNION +
  INPUT_BUSQUEDA + limpieza de filtro + debounce por KeyDown + CAST),
  eventos `OnEntrarEdicion`/`OnSalirEdicion`, acumulación de
  cantidad, desenganche de eventos del repo en el destructor.
- `src/Lib/inLibGridTallasInline.pas`: `PersistirCantidad` soporta
  `FieldAlmacenCel` vacío.
- `src/Modals/inMtoModalDistribuidor.pas`: tabla de celdas
  parametrizable (`ConfigurarCeldas`, defaults de sesiones).
- `src/Forms/inMtoGen.pas`: `btnCancelarClick` con guarda de Owner
  (fuera de fzam era EInvalidCast).

## Uso desde un documento

```pascal
var
  Cfg: TConfigColumnasSku;
begin
  Cfg.Conexion := oConn;
  Cfg.View := tvLineas;
  Cfg.Cds := FDatos.cdsLineas;
  Cfg.Modo := mcsAuto;                  // o forzar mcsSku / mcsDesglose
  Cfg.AlmacenStock := sAlmacenOrigen;
  Cfg.Campos.CodigoArt := 'CODIGO_ART';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD';
  // ... resto de campos; AttrValor[i] vacíos => no hay desglose
  FModo := CrearModoEntradaGrid(Cfg);   // devuelve IModoEntradaGrid
  FModo.OnResuelto := LineaResuelta;
  FModo.Construir;                      // crea SUS columnas en el View
  // el documento añade después sus columnas (cantidad, precio, ...)
end;
```

Con `mcsAuto` la factoría decide: si `Campos.AttrValor[1]` está
definido y existe en el cds → desglose; si no → SKU.

**UI de tres modos (07/07/2026):** el banco de pruebas ofrece solo
Auto / SKU / Tallas horizontal. El desglose NO es seleccionable a
mano: es el modo EFECTIVO al que resuelve Auto cuando el documento
tiene columnas de atributo (elegirlo explícitamente era redundante).
`mcsDesglose` sigue en el contrato como resultado y los documentos
pueden pedirlo por código. F1 cicla los tres modos y reconstruye; el
formato distribuido queda fuera del ciclo (se activa en cabecera).

## Modo SKU — detalle

Basado en el patrón de búsqueda incremental de
`inLibGridArticulos.CrearLookupBusqueda` (que a su vez replica
`inMtoCajaOpe.tmrBusq`):

- `TcxEditRepositoryExtLookupComboBoxItem` creado en runtime, con view
  en repositorio propio y `GridMode := True`.
- Filtrado **en servidor**: debounce de 350 ms; con ≥ 2 caracteres
  consulta el top-100 de `fza_articulos_skus` por
  `CODIGO_UNIDAD_SKU LIKE 'texto%'` (elección del usuario: incremental
  solo por código de unidad), con descripción y stock del almacén
  configurado. Nunca se precarga el catálogo (ver el incidente de
  ~700k SKUs documentado en `inLibGridArticulos`).
- Enter (tecleo o lector Código+CR) resuelve vía
  `TArticulosValidador.Resolver`, que acepta artículo, SKU, código de
  barras o referencia de proveedor.
- Si la entrada resuelve a un **padre con variaciones**
  (`RequiereSku`), se piden color y talla en cadena con
  `SeleccionarAvConPaleta` (`inLibAtributosPaleta`, el mismo selector
  de swatches de caja/inventarios) usando
  `ObtenerAvsEnSkus` (solo valores presentes en SKUs del artículo).
  Los atributos con un único valor se autocompletan. Cancelar la
  paleta cancela la línea.
- Swatch de color en la celda del SKU con
  `PintarCeldaSwatchSiAplica` (prueba el último segmento tras `/`).

## Modo desglose — detalle

Adaptador puro: traduce `TCamposColumnasSku` → `TCamposGridArt`, crea
`TGridArticulosLineas` y reexpone `Construir` /
`MostrarEditorArticulo` / `ResolverEntrada` / `OnResuelto` /
`AlmacenStock` bajo el contrato. Toda la operativa (incremental,
lector STX/ETX, paleta por columna, autocompletado, avance de foco) es
la ya probada en producción.

## IProveedorValoresSku

Interfaz para listar colores/tallas disponibles sin acoplarse a
`TArticulosAtributosLookup`:

```pascal
Prov := CrearProveedorValoresSku(oConn);
Nombres := Prov.ObtenerNombresAtributos('CAMISA01');   // Color, Talla
Colores := Prov.ObtenerValoresDisponibles('CAMISA01', 1);
```

Pensada para futuros consumidores (informes, etiquetado, web) que
solo necesiten los valores, no el grid.

## Proyecto independiente (ColumnSKUcxGridTest)

Abrir `ColumnSKUcxGridTest.dproj` en el IDE y compilar (Win32). El
`.dpr` muestra primero el logon, que crea la `TUniConnection`
(provider MySQL, vale para MariaDB) y la deja en
`inLibGlobalVar.oConn`; después abre el banco de pruebas. Notas:

- El `.dproj` resuelve las dependencias con rutas de búsqueda
  relativas a `..\..\src\...` (Lib, Core, Forms, Modals,
  DataModules, Caja, 3rdpartyComp…): **no se copia ninguna unidad**
  del proyecto principal.
- Aviso de tamaño: `inLibAtributosPaleta` e `inLibGridArticulos`
  usan `inLibGlobalVar`, cuyo `uses` arrastra `inMtoPrincipal` y los
  data modules; el linker compila buena parte de fzam aunque en
  ejecución solo se use `oConn`. Es el precio de reutilizar el
  código de producción tal cual.
- El primer build genera `ColumnSKUcxGridTest.res` (no está en el
  repo). DevExpress/UniDAC se toman del library path del IDE, como
  en `TestPerformanceConn`.

## Formulario de prueba

`inMtoPruebaColumnasSku` no hereda de `TfrmBase` a propósito
(prototipo aislado, fuera de `fzam.dproj`); usa `oConn` de
`inLibGlobalVar`, que en el proyecto independiente asigna el logon.
Las líneas viven en un `TClientDataSet` en memoria: no escribe en
ninguna tabla de documentos.

Flujo de prueba sugerido: construir en modo Desglose y escanear /
teclear un artículo con tallas → aparecen columnas Color/Talla con
paleta. Reconstruir en modo SKU → una sola columna; teclear 2-3
letras abre el desplegable incremental de SKUs; elegir un padre pide
color/talla con la paleta y compone `ART/COLOR/TALLA`.

## Modo Tallas en horizontal (mcsTallasInline)

Tercer modo del contrato: adaptador `TModoEntradaTallas`
(`inLibColumnasSkuModoTallas.pas`) sobre `TGestorGridTallas`
(`inLibGridTallasInline`), el pivote de tallas ya en producción en
compras. Crea la columna de artículo + N columnas de talla no-bound
(Tag 1..N, spin), monta el gestor y delega en él la persistencia de
celdas y el rotulado por conjunto de la línea activa.

A diferencia de los otros modos, necesita infraestructura del
documento: tabla de celdas (estilo `fza_compras_sesiones_celdas`),
campo de pivote en las líneas (`ID_AC_PIVOT_...`) y master/líneas
abiertos antes de `Construir`. Por eso tiene factoría propia
(`CrearModoEntradaGridTallas(Config, CfgTallas)`); la factoría normal
lanza excepción si se le pide `mcsTallasInline`. En el banco
standalone se prueba con la tabla de celdas desechable
`fza_prueba_skucel` (recreada al primer Construir de cada sesión).

## Evaluación de integración por documento (05/07/2026)

Análisis del código actual de cada Mto para adoptar el contrato:

| Documento | Estado actual | Esfuerzo | Notas |
|---|---|---|---|
| **Traspaso TPV** (`inMtoTraspasoOpe`) | Ya usa `TGridArticulosLineas` (`FGridCtrl`, cdsLineas de `UniDataTraspaso`) | **Nulo/bajo** | Referencia. Solo cambiar a `IModoEntradaGrid` vía factoría si se quiere elegir modo. |
| **Venta TPV** (`inMtoCajaOpe`) | Patrón equivalente propio (combo incremental, lector STX/ETX, ATTR1..5 dinámicas, paleta) sobre `cdsLineas` de `UniDataCaja` | **Medio-bajo** | La lógica es la misma que extrajo `inLibGridArticulos`; es sustituir su copia local por el contrato. Riesgo: es LA pantalla de producción. |
| **Inventarios** (`inMtoInventarios`) | `ResolverInputArticulo` modular + ATTR1..5 con toggle `chkVerColumnasAtributos`, cdsLineas de `UniDataInventarios` | **Medio** | Encaja natural: el toggle actual ES la elección mcsSku/mcsDesglose del contrato. Campos `CODIGO_ART_INVLIN` / `CODIGO_UNIDAD_INVLIN`. |
| **Pedidos venta** (`inMtoPedidos`) | Botón […] + `TArticulosValidador`/`TArticulosResolver`, columnas bound `CODIGO_ART_PEDLIN` / `CODIGOPRODPS_PEDLIN`, sin talla/color inline | **Alto** | `TUniQuery` de líneas (no cds): la controladora acepta `TDataSet`, pero hay que ceder el View a `Construir` (ClearItems) y remontar las columnas propias (precios, dtos). |
| **Albaranes venta** (`inMtoAlbaranes`) | Ídem pedidos + lógica de trazabilidad (LOTE/CADUCIDAD) y `DESCRIPCION_VARIACION` | **Alto** | Igual que pedidos; además re-enganchar la visibilidad condicional de columnas opcionales tras `Construir`. |
| **Facturas venta** (`inMtoFacturasBase` → Normal/Simplif) | Ídem + modo creación de artículos inline y recalculo fiscal | **Alto** | El de más riesgo de ventas; ir el último. |
| **Compras** (sesiones, pedidos/albaranes/facturas/devoluciones de compra) | Ya usan `inLibGridTallasInline` | **Bajo** (vía mcsTallasInline) | El adaptador nuevo les da el contrato sin cambiar el gestor. |

Orden propuesto: 1) Inventarios (encaje natural, valida el contrato
en un Mto real), 2) Pedidos venta, 3) Albaranes venta, 4) Facturas,
5) Caja (cuando el contrato esté rodado), 6) Compras al contrato
mcsTallasInline (cosmético, ya funcionan).

Patrón de integración en cada Mto: construir `TConfigColumnasSku` con
sus nombres de campo (`*_PEDLIN`, `*_ALBLIN`…), llamar a la factoría,
`Construir` (que hace `ClearItems`), volver a añadir las columnas
propias del documento (precio, dto, totales) y mover la lógica del
antiguo botón […] / validador local a `OnResuelto`. EnterAsTab queda
resuelto por `OnEntrarEdicion`/`OnSalirEdicion`.

## Resultado de pruebas en vivo (06/07/2026)

Verificado funcionando en el banco standalone contra BBDD real:

- Desglose: resolución, color único autocompletado, paleta de tallas,
  encadenado de líneas. F3 abre buscador de artículos.
- Tallas horizontal: pivote real (conjunto asignado o fallback al
  conjunto global más pequeño que cubre las tallas), rótulos reales,
  color con swatch por línea, celdas editables persistiendo en la
  tabla de celdas (UPSERT), lecturas de SKU completo sumando +1 en su
  celda con consolidación por artículo+color, y fusión de líneas
  heredadas de otros modos al Construir (sin diálogo de confirmación:
  el borrado programático puentea el guardián de TfrmMtoGen).
- Correcciones que salieron de la prueba: ValueTypeClass float +
  CurrencyEdit en columnas de talla (sin eso el view DB descarta lo
  tecleado — copiado de sesiones); carga inicial de celdas diferida un
  tick (crear columnas del host resetea Values[] no-bound); EnterAsTab
  activo en celdas de talla y desactivado solo en la de artículo;
  `PersistirCantidad` de inLibGridTallasInline soporta ahora
  FieldAlmacenCel vacío (antes #42000); limpieza de celdas PRU/1 al
  primer Construir de cada sesión.

## Distribución por almacén (modo tallas)

Copiado el modelo de `inLibGridPivoteCompra` (albaranes/pedidos de
compra): el almacén es un **campo de la línea** (`Campos.Almacen`,
opcional en el contrato) y la distribución por almacén se hace con
**una línea horizontal por artículo+color+almacén** — las celdas no
llevan almacén. La clave de consolidación (Locate al leer) y la de
fusión (rederivar) incluyen el almacén. En la prueba: columna
"Almacén" editable; la línea en blanco hereda el del edit "Almacén
stock" (fallback de cabecera, como en compras) y cambiarlo antes de
leer manda esa lectura a otra línea/almacén.

## Formato distribuido (check "Almacenes distribuidos")

Equivalente al `ESFORMATO_DISTRIBUIDO_SES` de sesiones: la edición
inline de celdas de talla se bloquea y las cantidades se reparten por
almacén con el modal `TfrmModalDistribuidor` (ahora parametrizable en
tabla de celdas vía `ConfigurarCeldas`, con defaults de sesiones — su
comportamiento allí no cambia). El grid muestra la SUMA por talla.
Reglas: en distribuido el almacén por defecto es OBLIGATORIO (si el
documento no lo trae se asume el primer almacén activo estándar,
avisando; sin almacenes definidos → excepción); al cambiar de formato
las celdas MIGRAN (sin almacén → almacén por defecto al activar;
colapso de almacenes → '' al desactivar), fusionando cantidades. Las
líneas sin almacén asumen el del documento (fallback de cabecera,
como albaranes) tanto al resolver como en la clave de fusión.

La distribución PERSISTE al salir del modo tallas: `Desmontar`
expande por talla Y almacén (una línea por SKU+almacén con su columna
Almacén rellena) y el re-pivote devuelve cada reparto a la celda de
su almacén (`SumarEnCelda` con upsert atómico por almacén). Ciclo
distribuido ↔ Desglose/SKU validado en vivo (11 celdas → líneas por
partida con ALE/BCN/GEN correctos).

Validado en vivo (06/07/2026): distribuidor por línea con su sistema,
migración al activar/desactivar el check, almacén por defecto
garantizado y navegación entre líneas sin perder el pintado de
celdas. Lección adicional: los Values[] no-bound también se pierden
con el Post implícito y el scroll — la recarga va SIEMPRE diferida un
tick (timer) armada desde AfterPost/AfterScroll, nunca dentro del
propio evento.

## Cierre del banco de pruebas (06/07/2026)

Ciclo completo VALIDADO en vivo por el usuario: alta de SKUs en
SKU/Desglose → Tallas (fusión por artículo+color+almacén, cantidades
en su celda, totales por línea, rótulos reales) → vuelta a
SKU/Desglose (des-pivote: una línea por SKU con talla visible y
cantidad, línea en blanco única al final) → re-pivote. Sin diálogos
espurios y con todo trazado en el memo de log.

Lecciones clave para la integración real (todas ya aplicadas aquí):
ValueTypeClass en columnas no-bound; toda carga de Values[] no-bound
debe ser LO ULTIMO que toque el grid (crear columnas, EnableControls
y hasta un ds.First los resetean); EnterAsTab activo en celdas de
talla y desactivado solo donde el Enter resuelve; el guardián de
BeforeDelete de TfrmMtoGen se puentea en borrados programáticos.

## Búsqueda incremental en la celda de artículo (07/07/2026)

Los tres modos abren un desplegable de sugerencias a los ~350 ms de
teclear (≥ 3 letras) en la celda de artículo/SKU, filtrado EN
SERVIDOR con una UNION por prefijo de SKU, código de barras y
referencia/modelo de proveedor, y por contenido en la descripción
(cada rama ataca su índice; barras/referencias/stock se calculan solo
para las ≤100 filas devueltas, orden stock DESC).

Lecciones del `TcxExtLookupComboBox` (todas con sangre, patrón final
calcado de `inMtoCajaOpe`):

- **Eventos en el ITEM del repositorio, no en el editor**: con
  `AlwaysShowEditor` el grid re-clona las properties y un hook por
  instancia muere en un clon; los clones sí heredan los eventos del
  repositorio.
- **`OnChange` del lookup NO es fiable**: deja de disparar tras el
  primer autocompletado. El debounce se rearma desde el
  `OnEditKeyDown` del VIEW (teclas de texto + Back/Delete), que llega
  siempre. El `OnChange` queda de refuerzo.
- **El texto tecleado no es `EditingValue` ni `Text` a secas**: el
  texto libre no llega a `EditingValue`, y si el combo autocompletó,
  lo tecleado es solo la parte ANTERIOR a la selección
  (`Copy(Text, 1, SelStart)` si `SelLength > 0`).
- **La lista se queda "pegada" al autocompletado** si el lookup puede
  filtrar: se neutraliza con la infraestructura de caja — columna
  OCULTA `INPUT_BUSQUEDA` (duplicado del SKU en el SQL) como
  `ListFieldItem`, con `IncrementalSearch`/`Options.Filtering`/
  `IncSearch` a False; `IncrementalFiltering := False` y
  `AutoSearchOnPopup := False` en las properties;
  `SyncMode := False` en el DataController del view del desplegable;
  y limpieza de `IncSearchingText` + `DataController.Filter`
  TERMINADA EN `Refresh` antes de cada recarga y en el `CloseUp`
  (sin el Refresh la vista sigue mostrando el conjunto filtrado
  viejo). Durante la recarga, el view se desengancha del DataSource.
- **`GROUP_CONCAT` en subquery trunca**: el metadato de longitud que
  declara MariaDB se queda corto y UniDAC dimensiona el campo con él
  (EAN13 recortados a 11 caracteres). Siempre
  `CAST(... AS CHAR(120))` explícito.

## Robustez y ergonomía (07/07/2026)

- **Borrado en bucle SIEMPRE por `RecNo`**, nunca `while not Eof` con
  `Delete`: al borrar el ÚLTIMO registro el cursor cae en el anterior
  (no en Eof) y el bucle reprocesa filas ya vistas — en el rederivar
  de tallas cada línea "casaba consigo misma" en el diccionario y se
  borraba el documento entero. Aplicado en rederivar y en la
  normalización de línea en blanco.
- **Destructor de los modos: desenganchar los eventos del
  repositorio ANTES del primer `FreeAndNil`**. Liberar el view del
  desplegable dispara `SetView(nil)` → `PropertiesChanged` en el
  editor cacheado del grid → `Change` → handler del modo en plena
  destrucción tocando un timer ya liberado (AV nil+$50, cazado con
  call stack real al cambiar de modo). Guarda `FTimerBusq <> nil` en
  los Change como cinturón.
- **Acumulación de cantidad**: leer dos veces el mismo SKU cerrado
  suma +1 en la línea que ya lo tiene (Locate por `CODIGO_UNIDAD`)
  en desglose y SKU; tallas ya lo hacía en su celda. Sin líneas
  duplicadas al escanear.
- **EnterAsTab**: el host restaura al salir del grid
  (`cxgrdLineas.OnExit`); el `TcxRadioGroup` consume el Enter y no
  llega al JvEnterAsTab — se convierte en Tab desde el `KeyDown` del
  form (KeyPreview de TfrmBase). F1 = toggle de modo.
- **Ancho de columnas de atributo (tallas)**: `ApplyBestFit` NO vale
  (mide sin el swatch del custom draw y con el grid a medio pintar
  encoge). Ancho SOLO creciente medido con `cxTextWidth` sobre el
  valor real + 44 px (swatch + márgenes) en cada escritura de
  atributos.

## Integración en INVENTARIOS (07/07/2026)

Primera integración del contrato en un Mto real (sustitución
completa). Estado: SKU y Desglose FUNCIONANDO en vivo; el modo tallas
en horizontal se probó y se DESCARTÓ para inventarios — cada línea
lleva DOS cantidades (teórica y recuento) y una celda de pivote solo
puede representar una. La infraestructura queda hecha para el
siguiente candidato (albaranes/pedidos, una cantidad por línea):

- `inventarios_tallas_horizontal.sql`: tabla `fza_inventarios_celdas`
  + `ID_AC_PIVOT_INVLIN` en líneas (aplicado en BBDD de pruebas).
- `TGridTallasConfig.CamposDocExtraMaster/Cel`: clave de documento
  extra opcional (inventarios: EMP+ALM además de SERIE+NUMERO) que
  gestor y modo anexan a todos sus SQL de celdas. Vacía en sesiones.
- `UniDataInventarios`: campo persistente `ID_AC_PIVOT_INVLIN`
  (pas+dfm+SQLUpdate) y `ModoPivoteActivo` — exención del backstop de
  atributos/SKU de `cdsLineasBeforePost` para líneas pivotadas o
  conversiones en curso (hoy inerte).

Detalles del encaje en `inMtoInventarios` (patrón para el resto):

- `FModoEntrada: IModoEntradaGrid` + F1 alternando Auto (desglose) ↔
  SKU; Auto por defecto; caption de la pestaña = modo efectivo; el
  check "Ver atributos en columnas" queda oculto (era la misma
  elección).
- `ConstruirModoEntrada` tras cada `CargarLineasYRefrescar`: teardown
  estilo banco + desempaquetado SKU→ATTR cuando el modo enseña
  atributos + `CrearColumnasHostInventario` (las columnas del dfm
  mueren en el ClearItems del Construir y las numéricas se recrean en
  runtime, reusando el Validate de recuento).
- Rutas legacy de columnas cortocircuitadas con `FColsModoConstruido`
  (activado ANTES del Construir: si algo aborta a medias, nadie toca
  columnas muertas).
- `OnResuelto` → `RellenarDatosSku` (teórica/física/PMPs + fecha de
  recuento), la misma rama del flujo clásico.
- Lección: los guardianes de BeforePost del documento SON parte de la
  integración — el de inventarios abortaba el Construir de tallas a
  mitad y dejaba el grid a medio montar.

## Integración en FACTURAS DE VENTA (08/07/2026)

Aplicado el contrato a `inMtoFacturasBase` (cubre **venta mayor
normal** y **simplificadas**, que solo cambian vista/TIPO_FAC). F1
cicla `Auto (desglose) -> SKU -> Tallas horizontal`; Auto por defecto.

- **SQL**: `facturas_columnas_sku.sql` — ATTR1..5 + NUM_ATRIBUTOS en
  `fza_facturas_lineas` y regeneración de `vi_facturas_lineas` con
  `fl.*`. Sin tabla de celdas y sin ID_AC_PIVOT. **Obligatorio
  aplicarlo antes de desplegar**: los SQLInsert/Update de `unqryLinFac`
  se reescriben en `TdmFacturas.DataModuleCreate` con las columnas
  nuevas (mismo criterio que pedidos).
- **Modo tallas** = `inLibGridPivoteVenta` (mcsTallasHorPed) con el
  flag nuevo **`BandaUnica`**: una factura tiene UNA cantidad por
  línea, así que cada grupo artículo+color+precio pinta UNA fila
  (banda pedida rotulada `Cantidad`) en vez de las 3 bandas de
  pedidos. El pivot sigue siendo SOLO visual: las líneas fiscales no
  se consolidan ni se transforman (Verifactu intacto).
- `TdmFacturas.DesempaquetarAtributosLineas` (clon del de pedidos
  sobre `_FACLIN`, defensivo si la migración no está aplicada).
- `ConstruirModoEntrada` en la base: teardown estilo pedidos +
  `CrearColumnasHostFactura`, que recrea las columnas del documento y
  **reasigna las referencias `ctb*` del dfm** para que la lógica
  existente (dsLinFacStateChange/ImpIncl, visibilidad de creación,
  toggles de cabecera, recalculo fiscal) siga funcionando. Durante el
  rebuild se desenganchan `dsLinFac.OnStateChange/OnDataChange` (tocan
  columnas muertas en el ClearItems).
- `AplicarArticuloFactura(entrada)`: núcleo compartido del flujo
  fiscal clásico (validador + resolver + tarifa + IVA inc/exc +
  `ActualizarLineaFacturaGen`); lo usan `OnResuelto` del contrato y
  `OnCrearLineaSku` del pivote.
- **Modo creación de artículos** (`ESCREARARTICULOS_FAC='S'`): el
  contrato no cubre el alta inline, así que se reconstruye una
  presentación **[Clásico]** (artículo botón […] + combo SKU con sus
  handlers legacy). F1 queda inerte con creación activa; al alternar
  el check o navegar a una factura con creación se reconstruye.
- Navegación entre facturas: se desempaqueta SKU->ATTR (desglose), se
  re-pivota (tallas) o se alterna clásico<->contrato según la
  cabecera, desde `dsTablaGDataChange`.

Pendiente de validación funcional en vivo (alta de líneas en los tres
modos, edición de celdas de talla, totales fiscales y Verifactu).

## Contrato COMPLETO en PEDIDOS DE COMPRA (09/07/2026)

(Sustituye al plan intermedio de "ciclo F1 sobre los toggles":
el usuario pidió el MISMO tallashorped de ventas.)

`inMtoPedidosCompra` adopta el contrato entero con CUATRO modos
(10/07/2026): F1 cicla Auto (desglose) → SKU → **Tallas horiz.**
(mcsTallasInline: líneas consolidadas por artículo+color, cantidades
PEDIDAS por celda en `fza_pedidos_compra_celdas`, sufijo PEDCCEL) →
**Tallas horiz. bandas = `inLibGridPivoteVenta`** (mcsTallasHorPed,
bandas **Pedido / A recibir / Pendiente** mapeadas a
`CANTIDAD_PEDCLIN` / `CANTIDAD_A_RECIBIR_PEDCLIN` (nueva) /
`CANTIDAD_RECIBIDA_PEDCLIN`; rótulo de banda configurable en la lib,
`TextoBandaAAlbaranar` = 'A recibir').

- **SQL**: `pedidos_compra_columnas_sku.sql` — ATTR1..5 +
  NUM_ATRIBUTOS + CANTIDAD_A_RECIBIR en `fza_pedidos_compra_lineas`.
  Obligatorio antes de usar (el DM lee `SELECT *`, sin vistas).
- **El pivote de compras (`inLibGridPivoteCompra`) queda RETIRADO de
  esta pantalla** (sigue en albaranes de compra): botones Tallas en
  horizontal / Expandir recibidos / Recibir fila entera ocultos y la
  preferencia `ESPIVOTE_HORIZONTAL_PEDC` se ignora (decisión
  09/07/26).
- "A recibir" pasa de columna no-bound a CAMPO: columna editable con
  clamp en SKU/Desglose, banda en tallas. `Recibir todo`, el total de
  cabecera y `Crear albarán` (recogida y limpieza por almacén) leen y
  escriben el campo; los flujos antiguos se conservan solo para el
  estado pre-contrato (dfm intacto hasta el primer Construir).
- `TdmPedidosCompra.DesempaquetarAtributosLineas` (clon defensivo).

## Pendiente / siguientes pasos

- ~~Totales no se refrescan tras Construir~~ → RESUELTO
  (RefrescarTotalesTodasLineas en la carga diferida).
- Borrar una línea no borra sus celdas (huérfanas en la tabla PSC);
  en un documento real debe ir en el flujo de borrado del Mto.
- ~~El viaje Tallas→Desglose no reconstruye líneas por SKU~~ →
  RESUELTO: `IModoEntradaGrid.Desmontar` (no-op en SKU/Desglose; el
  modo tallas des-pivota al abandonar: cada celda con cantidad se
  expande a una línea por SKU con cantidad plana y las celdas se
  limpian). El ciclo SKU↔Desglose↔Tallas ya es sin pérdidas. La
  numeración de líneas pasa a max(LINEA)+1 compartida.

- Captura de trama STX/ETX del lector también en modo SKU (hoy solo
  Código+CR; el desglose ya la tiene vía `TGridArticulosLineas`).
- Retirar las trazas de diagnóstico (`GridArt.*`, `ModoTallas.*`,
  `Rederivar MASTER/BORRA`, `Normalizar`, `Grid.OnExit`,
  `CODBARRAS size`) cuando el usuario dé por cerrada la validación.
- Decidir si `IModoEntradaGrid` debe exponer también el buscador
  completo (`TfrmMtoSearch`) del botón «…».
- ~~Si la prueba convence, mover las units a `src/Lib/` e integrar en
  un Mto real~~ → HECHO (07/07/2026): units en `src/Lib/`, dentro de
  `fzam.dpr`, e Inventarios integrado y validado. Siguiente Mto
  candidato: pedidos de venta.
- Las trazas de diagnostico (GridArt.*, ModoTallas.*,
  [ConstruirModoEntrada]...) se CONSERVAN a proposito durante la fase
  de integracion; retirarlas cuando el contrato ruede en produccion.
- Valorar extender el patrón de interfaces al resto de
  controladoras de grid (criterio nuevo respecto al libro de estilo;
  documentarlo en `LIBRO_DE_ESTILO_DELPHI.md` si se adopta).
