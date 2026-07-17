# Descarga de fotos de artículo desde el servidor web

Permite traerse las fotos de un artículo desde el servidor de fotos en la
nube (`download_foto.php`), descomprimirlas en `appDirFotos` e integrarlas en
el sistema de fotos existente (`fza_articulos_fotos`). Complementa al sistema
local descrito en `fotos_articulos.md`; no lo sustituye.

Unidad principal: `src/Lib/inLibFotosNube.pas`.

## Parámetros (categoría "Servicios web")

| Parámetro | Para qué |
|---|---|
| `appApiUrl` | URL general de la API. |
| `appApiToken` | Credencial común; en fotos viaja como `X-API-Key`. |
| `appApiReferencia` | Referencia global que aísla cada instalación. |
| `appDirFotos` | Carpeta local destino (la misma del sistema de fotos). |

Si falta alguno, `FotosNubeConfigurado` devuelve `False` con la lista de lo
que falta y no se intenta la descarga.

## Contrato del servidor

Idéntico en estilo a `ver_foto.php` / `upload_foto.php`:

```
GET  ?carpeta_cliente=..&articulo=..&resolucion=real
Header: X-API-Key: <clave>
200 application/zip  -> PNG sueltos ARTICULO_COLOR_INDICE_<resolucion>.png
4xx application/json -> { "message": "..." }
```

`DescargarFotosArticulo` detecta el ZIP por la firma `PK`, lo descomprime en
`appDirFotos`, borra el ZIP temporal y devuelve las rutas de los PNG. Si el
servidor responde 4xx con JSON, muestra su `message`.

## Puntos de integración

- **Ficha de fotos (`inMtoFotoArticulo`)**: botón "Bajar fotos del servidor"
  en la barra superior. Integra al nivel del combo (profundidad
  `appNumAtributosFoto`, por defecto artículo/color) eligiendo el PNG por
  color con `ElegirFotoNubePorColor`, y refresca la vista.
- **Compras Sesiones (`inMtoComprasSesiones`)**: botón pequeño "Bajar fotos"
  que integra una foto en la línea de sesión (`oFotos.GuardarSesion`).
- **Atajo `Ctrl+F`**: abre la foto flotante del artículo activo (no descarga;
  la descarga vive en los botones).

## ¿Qué "color" lleva la foto? (importante)

El token `COLOR` del nombre del fichero (`ARTICULO_COLOR_INDICE_real.png`) y
el segmento de color de la clave de la foto (`CODIGO_UNIDAD_FOT`) son **el
mismo token que usa el SKU**, y ese token es el **TEXTO DEL PROVEEDOR saneado**.
El color básico es solo un *helper* de clasificación (importante, pero helper).

| Concepto | Dónde | Ejemplo | ¿En el SKU / nombre de foto? |
|---|---|---|---|
| Color de proveedor (texto libre, saneado) | `COLOR_TEXTO_SESLIN` → `fza_atributos_valores.AV` | `011-AZ` | **Sí** ← identidad del color |
| Color básico (helper, con HEX) | `fza_atributos_basicos.CODIGO_ATB` (vía `AV.ID_ATB_AV`) | `AZUL (#0066CC)` | Helper (HEX, agrupar, etiquetas) |

Ejemplo: el proveedor llama al color `011-AZ` y se clasifica como básico
`AZUL`. El SKU queda `ARTICULO/011-AZ/talla`, el `AV` es `011-AZ` (enlazado al
básico `AZUL` vía `ID_ATB_AV`) y la foto se nombra `ARTICULO_011-AZ_1_real.png`.

**Saneo del token COLOR** (idéntico en SKU y foto: `SanearColorSku` y
`SanearColorFoto`): mayúsculas; espacios → `-`; se conservan letras, dígitos,
`-` y `_`; el resto de símbolos (`/`, `%`, `€`, …) se **prohíben**; sin
separadores repetidos ni en los extremos.

Consecuencia: `ElegirFotoNubePorColor` casa el segmento de color del SKU (el
texto del proveedor saneado) contra el token `COLOR` del fichero. Funciona
**siempre que el servidor nombre las fotos con esa misma regla de saneo**.

> Modelo: el color del SKU es el texto del proveedor (identidad por
> proveedor), no el código del básico. El básico se mantiene como helper
> importante. Detalle en `sku_color_texto_proveedor.md`.

## Convención de nombre y sentinela `COLOR=NONE`

- De momento el servidor solo envía fotos por color (capa 2).
- Para fotos que **no** son por color se reserva el token `COLOR = NONE`: un
  PNG con `_NONE_` en el nombre se integra a nivel artículo
  (`CODIGO_UNIDAD_FOT = ''`) en vez de a nivel color. Así el resolutor la usa
  como foto del artículo y de todos sus SKU.
- Ampliación futura prevista: fotos a nivel artículo directamente desde el
  servidor (cuando se decida, sin tocar el cliente si se respeta `NONE`).

## Limitaciones

- El emparejamiento por color es heurístico (busca `_COLOR_` en el nombre del
  `_real`); si no casa, cae en la primera foto representativa (`_real`).
- No se ha podido compilar Delphi en el entorno (VCL + DevExpress / Windows);
  conviene un *build* en el IDE de la unit nueva (usa `System.Net.HttpClient`
  y `System.Zip`).
- Sin cambios de esquema: `factuzam_original.sql` no se toca; los parámetros
  se registran en código y se persisten por el formulario de parámetros.
