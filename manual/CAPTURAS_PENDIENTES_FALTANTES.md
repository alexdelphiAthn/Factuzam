# Capturas pendientes faltantes en el manual

Documento generado comparando las referencias `img/...` de los capítulos del
manual con los ficheros existentes en `manual/img/`.

Solo se listan capturas que el manual referencia y cuyo fichero todavía no
existe en `manual/img/`. No incluye las capturas que ya están colocadas.

Resumen del cotejo:

| Métrica | Total |
|---------|-------|
| Imágenes referenciadas por el manual | 118 |
| Imágenes referenciadas que ya existen en `manual/img/` | 118 |
| Imágenes referenciadas que faltan en `manual/img/` | 0 |
| Imágenes de `manual/img/` sin referencia en el manual | 0 |

## Resultado

No falta ninguna imagen referenciada por los capítulos del manual.

## Pantallas aún sin referencia visual

El cotejo anterior no detecta una pantalla que nunca se haya incluido en un
capítulo. La revisión funcional mantiene pendientes estas capturas:

- modal y flujo de importación de pedidos de PrestaShop;
- parámetros y cola de PrestaShop con detalle HTTP;
- cola Web Service Fzam con detalle HTTP;
- Histórico de Solicitudes de Traspaso;
- Facturas proforma;
- Procesos auxiliares BBDD.

## Al incorporar una captura

1. Guardar el fichero exacto en `manual/img/`.
2. Regenerar la web con `python generar_html.py` desde `manual/`.
3. Copiar `manual/html/` a `web/manual/` cuando se vaya a publicar.
4. Volver a generar este cotejo o eliminar la fila correspondiente.
