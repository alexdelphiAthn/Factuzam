# Sistema de fotos por artículo / SKU

Análogo en concepto al de tarifas (`fza_articulos_tarifas`): un SKU sin foto
hereda la del artículo padre.  Se almacena en la carpeta de parámetros
`appDirFotos` en tres resoluciones:

```
<appDirFotos>/300/<fichero>.png   -> PNG redimensionado a 300 px (lado mayor)
<appDirFotos>/600/<fichero>.png   -> PNG redimensionado a 600 px (lado mayor)
<appDirFotos>/real/<fichero>.png  -> PNG en resolución original (sin redimensionar)
```

Los tres son PNG: el "real" no es una copia byte-a-byte del fichero
fuente, se re-encodifica a PNG manteniendo las dimensiones originales
para que las tres copias se traten igual.

El parámetro `appDirFotos` tiene valor por defecto
`$(PUBLICO)\Factuzam\fotos` (en Windows expande a
`C:\Users\Public\Documents\Factuzam\fotos`) para que la foto sea visible
por todos los usuarios del equipo. En instalaciones multi-puesto se
recomienda apuntarlo a una ruta UNC compartida en red.

`<fichero>` es el `NOMBRE_FOT_FOT` que la BBDD asigna al alta, único por fila
de `fza_articulos_fotos`.  La codificación impide colisiones cuando el SKU
contiene `/` o `\` (que son frecuentes: `BLUS-SEDA/BLANCO/L`).

## Resolución

Dado un par (CODIGO_ART, CODIGO_UNIDAD_SKU):

1. Si existe fila con `CODIGO_UNIDAD_FOT = CODIGO_UNIDAD_SKU` (o un prefijo
   del SKU partido por `/`, ganando el más específico), usar esa.
2. En su defecto, fila con `CODIGO_UNIDAD_FOT = ''` y `CODIGO_ART_FOT =
   CODIGO_ART` (foto a nivel artículo).
3. En su defecto, si el artículo tiene **exactamente una** foto (aunque sea a
   nivel color/SKU), usar esa. Con varias no se adivina. Es un fallback
   aditivo: solo actúa donde antes no se mostraba nada, sin alterar las
   resoluciones que ya funcionaban. Pensado para que una única foto por
   color descargada del servidor se vea aunque mires el artículo desnudo.
4. Si nada de lo anterior, no hay foto.

## Integración con FastReports

Cualquier `TfrxPictureView` cuyo `Name` sea `foto300`, `foto600` o `fotoReal`
es sustituido en tiempo de impresión por la foto resuelta del par
(CODIGO_ART, CODIGO_UNIDAD_SKU) que se obtenga de la banda padre del
componente.  Las columnas de búsqueda son `CODIGO_ART_FAC` /
`CODIGO_UNIDAD_FAC` (o cualquier alias terminado en `_ART` / `_SKU`).

## Pantalla flotante

`Ctrl + Alt + F` en cualquier mantenimiento abre `frmFotoArticulo`, un
formulario "top" (no modal, `FormStyle = fsStayOnTop`) que muestra la foto
del registro activo.  La pantalla detecta el código de artículo y de SKU a
partir del `DataSet` actual (campos `CODIGO_ART_*` / `CODIGO_UNIDAD_*`) y
ofrece un selector de resolución 300 / 600 / real.

Para usarse dentro de un formulario modal existe la variante
`TfrmModalFotoArticulo.Ejecutar(...)`, que abre la misma pantalla con
`ShowModal`.

### Comportamiento transversal

La pantalla flotante es **única en toda la sesión** (singleton
`frmFotoArticulo`) y sigue al Mto activo una vez abierta:

- **Apertura manual**: la ventana se abre únicamente cuando el usuario
  pulsa `Ctrl + Alt + F` en el Mto activo. No hay auto-show.
- Al **cambiar de pestaña** en `pcPrincipal`, si la flotante ya está
  abierta, el handler `pcPrincipalChange` llama a `EngancharFotoAlMto`,
  que re-vincula los `DataSources` y refresca la foto al artículo /
  SKU activo del nuevo Mto. Si la flotante no está abierta, no se
  abre sola.
- Al abrir un **nuevo Mto**, `TfrmMtoGen.FormShow` invoca igualmente
  `EngancharFotoAlMto(Self)` con la misma semántica: re-vincula si la
  ventana está abierta, no hace nada si no lo está.
- Al **moverse el cursor** dentro del Mto activo (cambio de fila en el
  grid principal o en cualquier sub-grid declarado en
  `DataSourcesParaFoto`) el hook `OnDataChange` dispara
  `SetArticuloSku` con el nuevo par.
- Cuando el usuario **cierra la ventana** la siguiente vez se crea una
  instancia limpia con el próximo `Ctrl + Alt + F`.

Los Mtos con sub-grids (Facturas, Pedidos, Albaranes, Tarifas,
ComprasSesiones, Inventarios) sobreescriben dos métodos virtuales de
`TfrmMtoGen`:

- `ResolverArtSkuActivo(out ACodArt, ACodSku: string)`: lee artículo /
  SKU del sub-grid donde vive el artículo activo (no de `dsTablaG`,
  que es la cabecera del documento).
- `DataSourcesParaFoto: TArray<TDataSource>`: lista de DataSources que
  la pantalla flotante engancha vía `VincularDataSources`. Por defecto
  `[dsTablaG]`; los Mtos con sub-grids devuelven
  `[dsTablaG, dmm*.dsSubGrid]` para que la foto siga al cursor en
  cualquier pestaña / grid.
