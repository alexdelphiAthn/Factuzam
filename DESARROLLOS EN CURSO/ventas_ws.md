# Copia de ventas en el webservice

## Objetivo

Cuando el parámetro de caja `vgerEnviarVentasWS` está activo, cada factura
emitida genera eventos en `fza_ventas_ws_cola`. Un hilo independiente envía
los eventos al endpoint autenticado `ventas/eventos.php` sin bloquear la caja
ni la cola de VeriFactu.

## Eventos

- `VENTA_CONFIRMADA`: el documento abandona el estado de borrador.
- `FISCAL_ACTUALIZADO`: cambia el resultado fiscal o de VeriFactu.
- `VENTA_ANULADA`: se solicita o confirma la anulación fiscal.
- `VENTA_SUSTITUIDA`: una rectificativa `S` sustituye al documento original.
- `VENTA_REABIERTA`: un lanzamiento pendiente vuelve a borrador.
- `TICKET_PDF_ACTUALIZADO`: incorpora un ticket PDF generado después del
  evento inicial.
- `FACTURA_PDF_ACTUALIZADO`: incorpora una factura A4 PDF generada después
  del evento inicial.

Cada evento tiene UUID propio y una secuencia local creciente. El JSON se
congela durante el primer intento; todos los reintentos reutilizan exactamente
el mismo contenido. El servidor ignora eventos antiguos que lleguen después de
una secuencia más reciente.

## Contenido respaldado

El evento contiene la fila completa de la factura, sus líneas, pagos de
factura y caja, recibos, efectos de venta, operaciones de caja, movimientos de
almacén, vales, depósitos, relaciones entre facturas, cola y consolidación
VeriFactu y eventos fiscales.
Los tickets PDF y las facturas A4 PDF se incluyen en Base64 con nombre, MIME,
tamaño y huella SHA-256. La cola conserva también el binario original; el
servidor lo valida, lo decodifica y lo almacena como documento independiente.
El servidor conserva el JSON original y proyecta cabecera, líneas, pagos y
estado fiscal para las consultas de la futura aplicación.
Las ventas anuladas o sustituidas se conservan como histórico, pero el
endpoint de líneas no las incluye por defecto en ventas ni totales.

## Parámetros

- Caja: `vgerEnviarVentasWS`, desactivado por defecto.
- Aplicación: `appApiUrl`, `appApiToken`, `appApiReferencia`,
  `appVentasWsSegundosCiclo` y `appVentasWsMaxIntentos`.

Desactivar `vgerEnviarVentasWS` impide crear eventos nuevos, pero el hilo sigue
procesando los que ya estaban en cola.

## Despliegue

1. Aplicar `ventas_ws_cola.sql` en cada base de datos Factuzam.
2. Aplicar `ventas_ws_servidor.sql` en la base de datos de CertApiWeb.
3. Publicar `publico/api/v1/ventas/eventos.php` y actualizar el esquema base.
4. Crear o ampliar una credencial con el ámbito `ventas:escribir`.
5. Configurar URL, token y referencia; después activar
   `vgerEnviarVentasWS` para las cajas o perfiles deseados.

Para admitir PDFs en Base64, PHP y el proxy web deben aceptar al menos el
tamaño configurado en `CFG_VENTAS_EVENTO_MAX_BYTES`. Los límites por defecto
son 64 MiB para el evento completo y 20 MiB para cada PDF.
