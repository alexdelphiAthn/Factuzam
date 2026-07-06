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

| Fichero | Contenido |
|---|---|
| `inLibColumnasSkuIntf.pas` | Contratos: `IModoEntradaGrid`, `IProveedorValoresSku`, records `TConfigColumnasSku` / `TCamposColumnasSku`, enum `TModoColumnasSku`, evento `TSkuResueltoEvent`. |
| `inLibColumnasSkuModoSku.pas` | `TModoEntradaSku`: una columna SKU con búsqueda incremental en servidor + paleta para elegir color/talla. |
| `inLibColumnasSkuModoDesglose.pas` | `TModoEntradaDesglose`: adaptador fino sobre `TGridArticulosLineas` (no duplica nada). |
| `inLibColumnasSku.pas` | Factoría `CrearModoEntradaGrid` + detección `mcsAuto` + `CrearProveedorValoresSku`. |
| `inMtoPruebaColumnasSku.pas/.dfm` | Formulario de prueba: radio Auto/SKU/Desglose, almacén, grid con `TClientDataSet` en memoria. |
| `ColumnSKUcxGridTest.dpr/.dproj` | Proyecto independiente (no toca `fzam.dproj`): logon → banco de pruebas. |
| `inMtoPruebaColumnasSkuLogon.pas/.dfm` | Logon mínimo: conecta a MariaDB (UniDAC/MySQL) y asigna `inLibGlobalVar.oConn`. Recuerda los datos en `ColumnSKUcxGridTest.ini` junto al exe (contraseña en claro: no distribuir). |

No hay script SQL: **no toca esquema**. Solo consulta tablas ya
existentes (`fza_articulos_skus`, `fza_articulos`,
`fza_articulos_stockactual`) y reutiliza los índices de
`indices_busqueda_skus.sql`.

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
lanza excepción si se le pide `mcsTallasInline`. **No se puede probar
en el banco standalone** (cds en memoria, sin tabla de celdas): se
probará al integrarlo en un documento real.

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
- Decidir si `IModoEntradaGrid` debe exponer también el buscador
  completo (`TfrmMtoSearch`) del botón «…».
- Si la prueba convence, mover las units a `src/Lib/` e integrar en
  un Mto real (candidato: pedidos de venta).
- Valorar extender el patrón de interfaces al resto de
  controladoras de grid (criterio nuevo respecto al libro de estilo;
  documentarlo en `LIBRO_DE_ESTILO_DELPHI.md` si se adopta).
