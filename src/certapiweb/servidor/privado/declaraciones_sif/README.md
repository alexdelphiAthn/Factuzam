# Declaraciones responsables del SIF

El catálogo `catalogo.php` indica la versión de Factuzam desde la que entra en
vigor cada plantilla de declaración.

El nombre del archivo se obtiene automáticamente sustituyendo por guiones
bajos los separadores de la versión:

```text
1.0.15.202606260100
declaracion_1_0_15_202606260100.html
```

El servicio selecciona la declaración con la mayor `version_desde` que no
supere la versión solicitada. La plantilla debe contener:

```html
<meta name="sif-code" content="FZ">
<meta name="declaracion-code" content="1_0_15_202606260100">
<meta name="sif-version" content="{{VERSION_SIF}}">
```

`{{VERSION_SIF}}` se sustituye por la versión exacta del Factuzam instalado.
Para publicar una declaración posterior hay que añadir su `version_desde` al
catálogo y subir el HTML con el nombre derivado de esa versión.
