# Mantenimiento del manual

Notas para quien **edita** el manual. Este fichero **no** forma parte del
manual publicado (no está en la lista `ORDEN` del generador, así que no
aparece ni en el menú lateral ni en `index.html`).

## Versión HTML del manual

El manual se publica como sitio web navegable en `manual/html/`. Para
leerlo en local, abre `manual/html/index.html` en cualquier navegador (no
necesita servidor ni conexión a internet).

### Flujo de trabajo: editar y regenerar

El HTML **no se edita a mano**: se genera a partir de los `.md`. Para
mantenerlo al día:

1. Edita el capítulo que quieras en su fichero `NN-*.md` (o el `README.md`).
2. Si añades una captura, guárdala en `manual/img/` con el nombre indicado.
3. **Regenera el HTML.** Tienes dos formas:
   - **En Windows:** doble clic en **`generar_html.bat`** (busca Python e
     informa si no está instalado).
   - **Desde consola** (cualquier sistema), en la carpeta `manual/`:

     ```
     python generar_html.py
     ```

El generador `generar_html.py` **no requiere instalar nada**: usa solo la
librería estándar de Python 3. Vuelca el resultado en `manual/html/` (una
página por capítulo, el índice de navegación lateral, la hoja de estilo
`estilo.css` y una copia de las imágenes de `img/`), sobrescribiendo lo
anterior.

> Si añades un capítulo nuevo (`NN-*.md`), regístralo en la lista `ORDEN`
> de la cabecera de `generar_html.py` para que aparezca en el menú lateral.

## Capturas de pantalla

Los capítulos incluyen **huecos para capturas** marcados así:

```
![Descripción](img/NN-nombre.png)
*▢ Captura pendiente — Descripción de lo que debe verse.*
```

Para completar un hueco basta con **guardar la captura en `manual/img/`**
con el nombre indicado (formato PNG); la imagen se mostrará automáticamente.
Una vez colocada, puede borrarse la línea *«▢ Captura pendiente…»* o
sustituirse por un pie de foto definitivo. Para localizar los huecos que
faltan: buscar `Captura pendiente` en los `.md`.

Las capturas nuevas añadidas en la última revisión están resumidas en
`CAPTURAS_PENDIENTES.md`.

## Publicar en la web

Sube **todo el contenido de `manual/html/`** (los `.html`, `estilo.css` y
la carpeta `img/`) respetando la estructura de carpetas. La página de
inicio es `index.html`. No subas los `.md` ni los scripts generadores.
