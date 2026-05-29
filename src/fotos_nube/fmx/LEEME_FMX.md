# Factuzam Fotos Nube (app FMX para Android)

App **FireMonkey (FMX)** independiente para **Android** que hace fotos con
la cámara del dispositivo, las reduce a una resolución máxima configurable
(por defecto **1000 px** en el lado mayor) y las sube **por lotes** al
webservice de fotos de Factuzam (`upload_foto.php`, alias *fotosnube*).

Cada foto se identifica por **código de artículo** y **color**; si se hacen
varias fotos del mismo artículo+color se les asigna un **índice
correlativo** automáticamente.

Es un proyecto Delphi **independiente** (`SubirFotosFmx.dpr`), igual que
`utilnormbbdd` o `utilmigsqlsrv`: **no** se compila dentro de `fzam.dproj`.
El uploader VCL de escritorio de `src/fotos_nube/oda/` (`Project1.dpr`,
`UFotoUploader`) sigue intacto; esta carpeta `fmx/` es la versión móvil que
habla con el mismo webservice.

## Estructura

```
fmx/
├── SubirFotosFmx.dpr      Proyecto FMX (Android64).
├── SubirFotosFmx.dproj
├── UPrincipal.pas/.fmx    Form principal: captura, cola y configuración.
├── UConfigFotos.pas       Configuración persistente en INI local.
├── UImagenUtil.pas        Redimensionado de la foto al máximo (JPG).
├── UColaFotosNube.pas     Cola de subida por lotes (hilo de fondo).
└── LEEME_FMX.md           Este fichero.
```

## Flujo

1. **Configuración** (pestaña *Configuración*): URL del webservice, API
   key, carpeta de cliente (`carpeta_cliente`, obligatoria) y resolución
   máxima (por defecto 1000). Se guarda en `fotosnube.ini` dentro de la
   carpeta de documentos de la app (sandbox). La ruta exacta se muestra en
   pantalla.
2. **Capturar** (pestaña *Capturar*): se teclea el **código de artículo**
   (obligatorio) y el **color** (opcional); *Hacer foto* abre la cámara y
   *Elegir de galería* la toma del carrete. Cada foto se reduce al máximo
   configurado y se añade a la cola con su artículo+color y estado
   *Pendiente*.
3. **Subir todas**: envía en segundo plano todas las fotos no subidas.
   Cada elemento pasa a *Subiendo…* → *Subida OK* / *Error*, y el log
   muestra el `sha1` devuelto o el mensaje de error.

## Índice por artículo+color

- Una sola foto de un artículo+color → se envía sin índice
  (`indice` vacío); el servidor la nombra `ARTICULO-COLOR_real.png`.
- Varias del mismo artículo+color → se envía `indice` = 1, 2, 3…; el
  servidor las nombra `ARTICULO-COLOR_1_real.png`, `_2_…`, etc.

El índice se calcula al subir, sobre el contenido final de la cola.

## Contrato del webservice (igual que el cliente VCL `oda`)

`POST` multipart/form-data a `upload_foto.php` con:

| Campo             | Obligatorio | Notas                                  |
|-------------------|-------------|----------------------------------------|
| `imagen`          | sí          | El JPG reducido.                       |
| `articulo`        | sí          | Código de artículo.                    |
| `carpeta_cliente` | sí          | Carpeta del cliente en el servidor.    |
| `color`           | no          | Color.                                 |
| `indice`          | no          | Sólo si hay varias del mismo art.+color. |
| `nombre_original` | no          | Nombre del fichero local.              |
| `osha1`           | no          | SHA1 local para verificación e2e.      |

API key también por cabecera `X-API-Key`. Respuesta JSON:
`{ "status": "success"|"error", "message": str, "sha1": str }`.

## Compilación y despliegue (RAD Studio)

> No se puede compilar en este entorno (no hay Delphi). Abrir el `.dproj`
> en **RAD Studio 12 (Athens)** o superior con el **SDK/NDK de Android**
> configurado.

### Permisos de Android

La app pide el permiso de **cámara** en tiempo de ejecución
(`PedirPermisoCamara` en `UPrincipal`). Además hay que **marcar los
permisos** en *Project ▸ Options ▸ Application ▸ Uses Permissions*:

- `Camera` (cámara).
- `Internet` (ya activo por defecto) — necesario para la subida.
- `Read external storage` / `Read media images` — para *Elegir de
  galería* según versión de Android.

## Nota sobre la versión (regla 6 de CLAUDE.md)

La regla de *pumpear la versión* aplica al binario principal (`fzam`) a
través de `inLibGlobalVar.pas`. Esta app FMX es un proyecto separado que
**no enlaza** esa unit, así que **no** se ha tocado la versión global de
`fzam`. La versión de esta app se define en `UPrincipal.pas`
(`cVersionApp`) y se muestra en el log al arrancar. Si se prefiere
unificar el versionado, indícalo y lo ajusto.
