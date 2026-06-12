# Verifactu en caja: QR en el ticket + cola de envío

Aplicación a Factuzam del esquema de OdaVeriFactu: el ticket de venta sale
con el QR tributario de la AEAT y, tras grabar la venta, la factura queda
encolada para que un hilo en segundo plano la comunique a Verifactu.

## Flujo

1. **Venta en caja** (`UniDataCaja.GrabarFacturaSimplificada`): dentro de
   la transacción de la venta, si `appVerifactuActivo` está marcado, se
   inserta la factura en `fza_verifactu_cola` (PASO 4.6). Factura y cola
   se confirman o deshacen juntas.
2. **Ticket** (`inLibGenerarTicket.ImprimirT` y reimpresión en
   `inLibGenerarTicketBD.ImprimirTicketDesdeBD`): con Verifactu activo se
   imprime el QR tributario (URL de cotejo de la AEAT, nivel de
   corrección M) con la leyenda «VERI*FACTU - Factura verificable en la
   sede electrónica de la AEAT». La URL se genera en local con
   `inLibVerifactu.ConstruirUrlQR`; no depende de la respuesta de la
   AEAT. Sin Verifactu el ticket sale sin QR (antes llevaba un QR de
   relleno a `hacienda.com`).
3. **Hilo de envío** (`inLibVerifactuCola`): arranca en
   `inMtoPrincipal.FormCreate` y para en `FormClose` (consulta
   `oCerrandoApp`). Cada `appVerifactuSegundosCiclo` segundos reclama
   filas `PENDIENTE` (reclamo optimista multi-puesto vía `UPDATE ...
   WHERE ESTADO = 'PENDIENTE'`), delega el envío en
   `inLibVerifactuEnvio.EnviarRegistroFactura` y persiste el resultado:
   - Éxito → inserta en `fza_facturas_consolidaciones` (QR, hash de
     cadena, respuesta completa…), marca `fza_facturas`
     (`ESCONSOLIDADA_FAC='S'`, `INSTANTECONSO_FAC`, `FASE_FAC='ONLINE'` o
     `'CANCELADA'` si era anulación) y deja la fila en `ENVIADA`.
   - Error → reintento con backoff exponencial (60s · 2^intentos, techo
     32 min). Al agotar `appVerifactuMaxIntentos` pasa a `ERROR` y la
     factura a `FASE_FAC='ERROR'`.
   - Todo queda trazado en `fza_verifactu_eventos` (cadena de hashes
     SHA-256), visible en la pestaña Verifactu de Facturas.
   El hilo usa **conexión propia** clonada de `oConn` (patrón de
   `TfrmMtoGen.CrearConexionPropia`): `oConn` no se comparte entre hilos.

## Parámetros (inMtoAppParam → categoría «Verifactu»)

| Parámetro                   | Defecto | Uso                            |
|-----------------------------|---------|--------------------------------|
| `appVerifactuActivo`        | False   | Interruptor general            |
| `appVerifactuEntorno`       | PRE     | PRE (pruebas) / PRO            |
| `appVerifactuUrlQRPre`      | URL AEAT prewww2 | Cotejo QR en pruebas  |
| `appVerifactuUrlQRPro`      | URL AEAT www2    | Cotejo QR producción  |
| `appVerifactuSegundosCiclo` | 60      | Periodo del hilo de la cola    |
| `appVerifactuMaxIntentos`   | 10      | Reintentos antes de ERROR      |

El hilo lee los parámetros en caliente: se puede activar/desactivar sin
reiniciar la aplicación.

## BBDD

- `fza_verifactu_cola` (sufijo `VFCOLA`): ver `verifactu_cola.sql`
  (idempotente). Estados: `PENDIENTE`, `PROCESANDO`, `ENVIADA`, `ERROR`.
  Único por (serie, número, tipo de operación).
- Reutiliza tablas ya existentes en el modelo: `fza_verifactu_eventos`
  (log encadenado) y `fza_facturas_consolidaciones` (respuesta AEAT).

## PENDIENTE: integración de las librerías OdaVeriFactu

El repositorio OdaVeriFactu no era accesible desde esta sesión, así que
las librerías de envío NO están copiadas todavía. El hueco está aislado
en `src/verifactu/inLibVerifactuEnvio.pas`:

- `EnvioVerifactuDisponible` devuelve `False` → la cola acumula
  `PENDIENTE` sin intentar envíos (se anota un único evento informativo
  por sesión). Nada se pierde: al integrar el cliente, el hilo despacha
  todo lo pendiente.
- Al copiar las librerías: implementar `EnviarRegistroFactura`
  (XML del registro de alta/anulación, huella encadenada, envío SOAP con
  certificado a los endpoints PRE/PRO) y devolver `True` en
  `EnvioVerifactuDisponible`. El record `TResultadoEnvioVerifactu` calca
  las columnas de `fza_facturas_consolidaciones`.
- Revisar también al integrar:
  - `inLibVerifactu.ComponerNumSerieFactura`: hoy concatena
    serie+número; debe coincidir con el `NumSerieFactura` que envíe el
    cliente.
  - Los tipos de evento (`TIPO_EVENTO_LOG`) y la firma
    (`FIRMA_DIGITAL_LOG`, hoy provisional SHA-256 hash+versión) frente a
    lo que haga OdaVeriFactu.
