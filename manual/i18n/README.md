# Traducciones del manual

El HTML multilingüe se genera a partir de los Markdown españoles de
`manual/` y de las traducciones disponibles en estas carpetas:

- `en-GB`: inglés británico;
- `ca-ES`: catalán;
- `zh-CN`: chino simplificado.

Cada traducción conserva el mismo nombre de archivo que su original. Si un
archivo todavía no existe, el generador publica esa página en español dentro
de la ruta del idioma y muestra un aviso de traducción pendiente. Así el
selector de idioma y todos los enlaces siguen funcionando mientras se
completa el catálogo por fases.

## Reglas de edición

1. Conserva la misma estructura y el mismo orden de encabezados que el
   original. El generador usa los identificadores canónicos españoles para
   que los enlaces con ancla funcionen en todos los idiomas.
2. No traduzcas nombres técnicos: parámetros, tablas, campos, SKU, estados,
   rutas, URL, nombres de archivo ni contenido de bloques de código.
3. Mantén intacto el destino de cada enlace Markdown. Se puede traducir su
   texto visible.
4. Conserva los nombres exactos de botones, campos y menús cuando se refieran
   literalmente a la interfaz todavía no traducida; añade la traducción
   narrativa alrededor si hace falta.
5. Después de editar, ejecuta `python manual/generar_html.py` y las pruebas
   `test_generador_manual.py` y `test_manual_html_generado.py`.

La primera tanda cubre la portada, **Menú Otros** y **Cambios y novedades**.
El resto se irá sustituyendo progresivamente sin cambiar las URL públicas.
