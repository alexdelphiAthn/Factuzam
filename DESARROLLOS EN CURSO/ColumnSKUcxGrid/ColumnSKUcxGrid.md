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

## Formulario de prueba

`inMtoPruebaColumnasSku` no hereda de `TfrmBase` a propósito
(prototipo aislado, fuera de `fzam.dproj`); usa `oConn` de
`inLibGlobalVar`, así que requiere sesión iniciada o asignar la
conexión antes. Las líneas viven en un `TClientDataSet` en memoria:
no escribe en ninguna tabla de documentos.

Flujo de prueba sugerido: construir en modo Desglose y escanear /
teclear un artículo con tallas → aparecen columnas Color/Talla con
paleta. Reconstruir en modo SKU → una sola columna; teclear 2-3
letras abre el desplegable incremental de SKUs; elegir un padre pide
color/talla con la paleta y compone `ART/COLOR/TALLA`.

## Pendiente / siguientes pasos

- Captura de trama STX/ETX del lector también en modo SKU (hoy solo
  Código+CR; el desglose ya la tiene vía `TGridArticulosLineas`).
- Decidir si `IModoEntradaGrid` debe exponer también el buscador
  completo (`TfrmMtoSearch`) del botón «…».
- Si la prueba convence, mover las units a `src/Lib/` e integrar en
  un Mto real (candidato: pedidos de venta).
- Valorar extender el patrón de interfaces al resto de
  controladoras de grid (criterio nuevo respecto al libro de estilo;
  documentarlo en `LIBRO_DE_ESTILO_DELPHI.md` si se adopta).
