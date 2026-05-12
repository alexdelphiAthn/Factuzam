# Etiquetas de Artículo / SKU

Impresión de etiquetas desde la pestaña **Stock** del mantenimiento de
artículos. El usuario elige tarifa, fecha de aplicación y uno o varios
almacenes; la pantalla emite una etiqueta por SKU con stock en los almacenes
seleccionados.

---

## 1. Pieza de BBDD

Una sola vista, `vi_articulos_skus_etiquetas` (DDL en
`etiquetas_articulos.sql`), pensada para alimentar al FastReport del modal:

- Una fila por SKU.
- Atributos pivotados: `ATR_CO`, `ATR_TAL` + `ATRIBUTOS_TXT` agregado +
  `DESCRIPCION_SKU` con los valores concatenados.
- Propiedades pivotadas: `PROP_MARCA`, `PROP_MATERIAL`, `PROP_TEMPORADA`,
  `PROP_GENERO`, `PROP_ESTILO`, `PROP_ORIGEN`, `PROP_COMPOSICION` +
  `PROPIEDADES_TXT` con TODAS las propiedades del artículo.
- Proveedor principal: `CODIGO_PRV_PRV`, `RAZON_SOCIAL_PRV`, `REF_PROVEEDOR`.
- Código de barras principal del SKU.

La vista **no** trae tarifa ni stock: el modal los cruza en runtime para
poder filtrar por fecha y por la combinación de almacenes elegida sin tener
que regenerar la vista.

---

## 2. Pieza Delphi

- `src/Modals/inMtoModalEtiqArt.{pas,dfm}` — modal `TfrmPrintEtiqArt`,
  hereda de `TfrmPrint` (sistema genérico de impresión con FastReport).
  - Combo de tarifa (con la tarifa marcada por defecto preseleccionada).
  - `TcxDateEdit` de fecha de aplicación.
  - `TcxListView` multi-selección de almacenes activos.
  - Checkbox "Imprimir sólo este artículo" (marcado por defecto).
  - Geometría persistida con `inLibLayoutForm` (Alt+F12 para guardar).
- `src/DataModules/UniDataArticulos.{pas,dfm}` — datasets de impresión:
  `unqryArtPrint` → `dtstprvEtiquetasArt` → `cdsEtiquetasArt` →
  `fxdsEtiquetasArt`. Métodos `CargarTarifasEtiquetas`,
  `CargarAlmacenesEtiquetas` y `CrearDataSetEtiquetasArt`.
- `src/Forms/inMtoArticulos.{pas,dfm}` — botón **Imprimir Etiquetas** en el
  panel derecho de la pestaña Stock.
- `fzam.dpr` — alta del nuevo unit.

### Consulta runtime

`TdmArticulos.CrearDataSetEtiquetasArt` monta:

```
vi_articulos_skus_etiquetas
  LEFT JOIN fza_articulos_tarifas        (precio del SKU específico)
  LEFT JOIN fza_articulos_tarifas        (caída a tarifa de artículo)
  LEFT JOIN (SUM stock por SKU sobre almacenes seleccionados)
WHERE artículo (opcional)
  AND tarifa  activa, vigente en la fecha pedida
```

`COALESCE` elige el precio de SKU si existe, en otro caso el del artículo
padre. La lista IN(...) de almacenes se construye con `QuotedStr` sobre los
códigos validados del checklist; si no se marca ninguno, no se filtra
(suma todos los almacenes).

---

## 3. Despliegue

1. Ejecutar `etiquetas_articulos.sql` contra la BBDD.
2. Recompilar la aplicación.
3. Abrir Artículos → Stock → **Imprimir Etiquetas**.

El script es idempotente (`DROP VIEW IF EXISTS` + `CREATE VIEW`). No
modifica tablas existentes.
