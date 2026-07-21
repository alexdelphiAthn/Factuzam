# Archivado del PDF de la factura en fza_facturas (PDF_FAC)

Objetivo: al consolidar una factura, guardar el PDF generado por
FastReport en la propia fila de `fza_facturas`, para poder servir la
factura emitida tal cual se imprimió (reimpresión, envío, consulta
externa vía MCP) sin depender del ejecutable en el momento de la
consulta.

## Piezas

| Pieza | Fichero |
|-------|---------|
| Esquema (5 columnas nuevas)   | `facturas_pdf_blob.sql` (idempotente) |
| Volcado fichero→blob          | `src/Lib/inLibFacturaPdfBlob.pas` |
| Hook en toda exportación PDF  | `src/Modals/inMtoModalImpFac.pas` (`PdfExportado`) |
| Generación al consolidar      | `src/Forms/inMtoFacturasBase.pas` (`GenerarPdfFacturaConsolidada`) |
| Servicio externo              | `mcp/servidor_mcp.py` (herramienta `factura_pdf`) |

Columnas nuevas en `fza_facturas` (patrón de `fza_ventas_ws_cola`):
`PDF_FAC` (longblob), `NOMBRE_PDF_FAC`, `TAMANO_PDF_FAC`,
`HUELLA_PDF_FAC` (SHA-256 hex), `INSTANTE_PDF_FAC`.

## Flujo

1. **Consolidar** (`btnConsolidarClick` de Borradores): tras lanzar la
   factura (cualquier modo fiscal) se crea el modal de impresión sin
   mostrarlo, se selecciona el formato por defecto del usuario
   (`Consultar_Formularios`) y se exporta a un PDF temporal con
   `ExportarPdfActual`. El `PdfExportado` del modal vuelca el fichero al
   blob y el temporal se borra.
2. **Cualquier exportación manual a PDF** desde el modal de impresión
   refresca el blob. Guardas:
   - solo con `rbActual` (un rango de fechas mezcla varias facturas en
     un solo fichero y no debe archivarse en ninguna);
   - solo si la factura salió de borrador (`ESCONSOLIDADA_FAC = 'S'` o
     fase distinta de BORRADOR): en modo SIN se imprimen borradores y
     esos PDFs no se archivan.
3. El volcado es "seguro": un fallo se anota en el log y no interrumpe
   ni la consolidación ni la impresión.

## Decisiones

- **Modo VERIFACTU**: al consolidar, la factura queda en fase
  `VERIFACTU_PENDIENTE` (el alta viaja asíncrona a la AEAT), pero el QR
  tributario ya es imprimible —es el mismo criterio que usa el botón
  Imprimir—, así que el PDF se archiva en ese momento. Cualquier
  reimpresión posterior (p. ej. tras la aceptación) refresca el blob.
- **Formato**: si el usuario tiene formatos guardados pero ninguno por
  defecto, `Consultar_Formularios` muestra el selector una vez, igual
  que al imprimir. Con formato por defecto (o sin formatos guardados)
  el proceso es 100 % silencioso.
- El hook de `PdfExportado` reutiliza el mismo punto por el que ya se
  adjunta el PDF a la cola de ventas WS (`AdjuntarFacturaPdfSeguro`).

## Pendiente / fuera de alcance

- Consolidación desde Caja (facturas simplificadas / tickets): la caja
  archiva su ticket por su propio circuito; si se quiere el A4 en
  `PDF_FAC` para simplificadas, enganchar el mismo mecanismo en su
  flujo de consolidación.
- Refresco automático del blob cuando el hilo Verifactu recibe la
  aceptación de la AEAT (hoy: reimpresión manual). Generar FastReport
  desde ese hilo no es seguro; habría que delegarlo al hilo principal.
- Purga/compactación: los PDF rondan decenas–cientos de KB por factura.
  Vigilar el crecimiento de la tabla; si molesta, mover el archivado a
  tabla satélite `fza_facturas_pdf` 1:1 (el código solo cambia el
  UPDATE).

## Aplicación

```sql
SOURCE facturas_pdf_blob.sql;   -- en cada BBDD existente
```

`factuzam_original.sql` NO se toca: cuando el usuario regenere el dump
desde una BBDD con el script aplicado, las columnas saldrán solas.
