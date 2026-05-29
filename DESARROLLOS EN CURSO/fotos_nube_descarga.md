# Descarga de fotos de artículo desde el servidor web

Permite traerse las fotos de un artículo desde el servidor de fotos en la
nube (`download_foto.php`), descomprimirlas en `appDirFotos` e integrarlas en
el sistema de fotos existente (`fza_articulos_fotos`). Complementa al sistema
local descrito en `fotos_articulos.md`; no lo sustituye.

Unidad principal: `src/Lib/inLibFotosNube.pas`.

## Parámetros (categoría "Fotos")

| Parámetro | Para qué |
|---|---|
| `appFotosUrlDescarga` | URL del `download_foto.php`. |
| `appFotosApiKey` | Clave que viaja en la cabecera `X-API-Key`. |
| `appFotosCarpetaCliente` | `carpeta_cliente` del servidor (aísla cada cliente). |
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
el segmento de color de la clave de la foto (`CODIGO_UNIDAD_FOT`, p. ej.
`DEMO-CAMISA/COLORAO`) son **el mismo token que usa el SKU**, y ese token es
el **VALOR DE ATRIBUTO**, no el color de proveedor. En Factuzam el color vive
en tres capas:

| Capa | Tabla / columna | Ejemplo | ¿En el nombre de la foto? |
|---|---|---|---|
| 1. Color de proveedor (texto libre) | `COLOR_TEXTO_SESLIN` / `COLOR_PROV_TXT` | `011`, `988`, `AZUL TURQUESA PROV-XYZ` | **No** |
| 2. Valor de atributo (el del SKU) | `fza_atributos_valores.AV` | `COLORAO`, `AZUL_CIELO`, `NEGRO` | **Sí** ← este |
| 3. Atributo básico (catálogo, con HEX) | `fza_atributos_basicos.CODIGO_ATB` | `ROJO (#C60000)` | Indirecto |

El valor de atributo (capa 2) apunta a su básico vía
`fza_atributos_valores.ID_ATB_AV`. Coincide con el código básico cuando el
`AV` es "limpio" (`NEGRO`, `AZUL_CIELO`); cuando no (`COLORAO` → básico
`ROJO`), el SKU y la foto usan el `AV`, no el básico ni el texto del
proveedor.

Ejemplo en datos demo: SKU `DEMO-CAMISA/COLORAO/L`, foto
`DEMO-CAMISA_COLORAO_001` con `CODIGO_UNIDAD_FOT = 'DEMO-CAMISA/COLORAO'`.
`COLORAO` es `fza_atributos_valores.AV` (`ID_AV=9206`, `ID_VA='CO'`).

Consecuencia: `ElegirFotoNubePorColor` casa el segmento de color del SKU (el
`AV`) contra el token `COLOR` del fichero. Funciona **siempre que el servidor
nombre las fotos con ese mismo `AV`**. En compras, el texto libre del
proveedor (`988`) se mapea antes a un color (botón "Color básico") y es el
`AV` resultante el que acaba en el SKU y debe llevar la foto; el texto del
proveedor nunca interviene en el emparejamiento.

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
