# Contrato ColumnSKUcxGrid en documentos de COMPRA

Port del sistema de presentación de tallas nuevo (F1 cicla
Auto/desglose → SKU → Tallas horizontal, pivote `inLibGridPivoteVenta`
sobre líneas SKU reales) a los documentos de compra. Decisión del
usuario 09/07/26: **todos los documentos de compra** salvo **sesiones
de compra**, que se queda como está.

## Estado

| Documento             | Estado                                        |
|-----------------------|-----------------------------------------------|
| Pedidos de compra     | HECHO (09/07/26, referencia del port)         |
| Albaranes de compra   | HECHO (este desarrollo)                       |
| Facturas de compra    | HECHO (este desarrollo)                       |
| Devoluciones de compra| HECHO (este desarrollo)                       |
| Sesiones de compra    | NO SE TOCA (decisión usuario)                 |

## Receta por documento (modelo: inMtoPedidosCompra)

1. **SQL idempotente** `<doc>_columnas_sku.sql`: columnas
   `ATTR1..5_VALOR_<suf>`, `ATTR1..5_NOMBRE_<suf>` y
   `NUM_ATRIBUTOS_<suf>` en la tabla de líneas (modelo
   `pedidos_compra_columnas_sku.sql`). Los documentos de banda única
   (albarán, factura, devolución) NO necesitan cantidad extra; pedidos
   añadió `CANTIDAD_A_RECIBIR_PEDCLIN` para su banda "A recibir".
   Sin tabla de celdas: el pivote es SOLO visual sobre líneas reales.
2. **DataModule**: `DesempaquetarAtributosLineas` (SKU → ATTRn por
   split de '/', idempotente por comparación; modelo
   `UniDataPedidosCompra.DesempaquetarAtributosLineas`).
3. **Form**:
   - uses interfaz: `inLibColumnasSkuIntf`, `inLibGridPivoteVenta`;
     uses implementación: `inLibColumnasSku` (factoría).
   - Campos privados `FModoEntrada` / `FModoEntradaSel` /
     `FColsModoConstruido` + `ConstruirModoEntrada`,
     `CrearColumnasHost<Doc>`, `ModoEntradaResuelto`,
     `PivoteVentaCrearLineaSku`, `PivoteVentaBandaCambiada`,
     `ActualizarCaptionModoLineas`; `KeyDown` protegido con F1.
   - Primera construcción al entrar al grid de líneas
     (`cxgrdLineas*Enter`); reconstrucción al navegar de documento
     (hook `dsTablaGDataChange`) si modo tallas, o
     `DesempaquetarAtributosLineas` si desglose.
   - `OnCrearLineaSku` / `ModoEntradaResuelto` reutilizan el
     `AplicarArticulo<Doc>` existente (acepta artículo o SKU: precio
     de compra del proveedor, IVA, modelo proveedor...).
   - Pivote de compras antiguo (`TGridPivoteCompra` + botón "Tallas
     horizontal" + preferencia `ESPIVOTE_HORIZONTAL_*`) RETIRADO de la
     pantalla: botones ocultos, preferencia ignorada, el objeto se crea
     pero nunca se activa (mismo criterio que pedidos de compra).
   - Teardown: `ClearItems` mata columnas del dfm y del pivote antiguo;
     poner a nil `FTallaColumns[]`, `FAtribColumns[]`, `FColColorPivot`
     ANTES de cualquier repintado.
4. **CfgPV por documento** (banda única):
   - Albarán:    SERIE_ALBC/NUMERO_ALBC, líneas `_ALBCLIN`,
     cantidad `CANTIDAD_ALBCLIN`, precio
     `PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN`, `BandaUnica=True`.
   - Factura:    SERIE_FACC/NUMERO_FACC, líneas `_FACCLIN`,
     cantidad `CANTIDAD_FACCLIN`, precio
     `PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN`, `BandaUnica=True`.
   - Devolución: SERIE_DEVC/NUMERO_DEVC, líneas `_DEVCLIN`,
     cantidad `CANTIDAD_DEVCLIN`, precio
     `PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN`, `BandaUnica=True`.

## Notas

- La librería ya está generalizada: `TextoBandaAAlbaranar` configurable
  y los literales `_PEDLIN` que quedan en `ObtenerInfoLinea` /
  `EsInsercionVacia` son fallbacks FindField-safe (código de barras /
  PrestaShop) que devuelven '' en datasets de compra.
- Las queries de líneas de los 3 DM son `SELECT * FROM fza_*_lineas`:
  las columnas ATTR nuevas entran solas y UniDAC genera el UPDATE.
- Pendiente de decisión posterior: limpieza del híbrido (retirar del
  código `TGridPivoteCompra`/`TGestorGridTallas` y las tablas de celdas
  de compra) cuando el contrato esté validado en producción.
