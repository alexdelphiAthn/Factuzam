# Sistema de fotos por artículo / SKU

Análogo en concepto al de tarifas (`fza_articulos_tarifas`): un SKU sin foto
hereda la del artículo padre.  Se almacena en la carpeta de parámetros
`appDirFotos` en tres resoluciones:

```
<appDirFotos>/300/<fichero>.png    -> PNG redimensionado a 300 px (lado mayor)
<appDirFotos>/600/<fichero>.png    -> PNG redimensionado a 600 px (lado mayor)
<appDirFotos>/real/<fichero>.<ext> -> fichero original (sin tocar)
```

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

1. Si existe fila con `CODIGO_UNIDAD_FOT = CODIGO_UNIDAD_SKU`, usar esa.
2. En su defecto, fila con `CODIGO_UNIDAD_FOT = ''` y `CODIGO_ART_FOT =
   CODIGO_ART` (foto a nivel artículo).
3. Si nada de lo anterior, no hay foto.

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
