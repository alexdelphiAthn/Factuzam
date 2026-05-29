# Factuzam Fotos Nube (app FMX)

App **FireMonkey (FMX)** independiente para hacer fotos con la cámara del
dispositivo, reducirlas a una resolución máxima configurable (por defecto
**1000 px** en el lado mayor) y subirlas por lotes al webservice de fotos
de Factuzam (`upload_foto.php`, alias *fotosnube*).

Es un proyecto Delphi **independiente** (`SubirFotosFmx.dpr`), igual que
`utilnormbbdd` o `utilmigsqlsrv`: **no** se compila dentro de `fzam.dproj`.
El uploader VCL de escritorio que ya existía en `src/fotos_nube/`
(`SubirFotos.dpr`) sigue intacto; esta carpeta `fmx/` es la versión móvil.

## Estructura

```
fmx/
├── SubirFotosFmx.dpr      Proyecto FMX (Win32 + Android64).
├── SubirFotosFmx.dproj
├── UPrincipal.pas/.fmx    Form principal: captura, cola y configuración.
├── UConfigFotos.pas       Configuración persistente en INI local.
├── UImagenUtil.pas        Redimensionado de la foto al máximo (JPG).
├── UColaFotosNube.pas     Cola de subida por lotes (hilo de fondo).
└── LEEME_FMX.md           Este fichero.
```

## Flujo

1. **Configuración** (pestaña *Configuración*): URL del webservice, API
   key, cliente (obligatorio), SKU por defecto (opcional) y resolución
   máxima (por defecto 1000). Se guarda en `fotosnube.ini` dentro de la
   carpeta de documentos de la app (sandbox en Android; Documentos en
   Windows). La ruta exacta se muestra en pantalla.
2. **Capturar** (pestaña *Capturar*): *Hacer foto* abre la cámara;
   *Elegir de galería* permite tomarla del carrete. Cada foto se reduce
   al máximo configurado y se añade a la cola con estado *Pendiente*.
3. **Subir todas**: envía en segundo plano todas las fotos no subidas.
   Cada elemento pasa a *Subiendo…* → *Subida OK* / *Error*, y el log
   muestra el `hash` devuelto o el mensaje de error.

## Contrato del webservice (igual que el cliente VCL)

`POST` multipart/form-data a `upload_foto.php` con:

| Campo     | Obligatorio | Notas                                   |
|-----------|-------------|-----------------------------------------|
| `imagen`  | sí          | El JPG reducido.                        |
| `cliente` | sí          | Identificador de cliente/empresa.       |
| `sku`     | no          | SKU o referencia.                       |
| `api_key` | sí          | También se envía por cabecera `X-API-Key`. |

Respuesta JSON: `{ "ok": bool, "mensaje": str, "hash": str, "url": str }`.

## Compilación y despliegue (RAD Studio)

> No se puede compilar en este entorno (no hay Delphi/Windows). Abrir el
> `.dproj` en **RAD Studio 12 (Athens)** o superior.

- **Win32**: compila y ejecuta directamente para depurar la lógica. En
  escritorio la captura usa la cámara/galería del sistema si está
  disponible.
- **Android64**: requiere el SDK/NDK de Android configurado en el IDE.

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
