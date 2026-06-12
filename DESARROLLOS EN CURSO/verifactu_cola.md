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
- `fza_verifactu_cadena` (sufijo `VFCAD`): ver `verifactu_cadena.sql`.
  Último eslabón de la cadena de huellas por NIF emisor.
- Reutiliza tablas ya existentes en el modelo: `fza_verifactu_eventos`
  (log encadenado) y `fza_facturas_consolidaciones` (respuesta AEAT).

## Cliente de envío a la AEAT (`inLibVerifactuEnvio`)

Implementado según la especificación pública de Verifactu (Orden
HAC/1177/2024 y esquemas `SuministroLR.xsd` / `SuministroInformacion.xsd`):

- **Registro de alta / anulación**: XML `RegFactuSistemaFacturacion` con
  `RegistroAlta` (IDFactura, TipoFactura F1/F2/R5 según `TIPO_FAC`,
  desglose por bandas de IVA N/R/S con S1 y exenta E1, recargo de
  equivalencia si lo hay, CuotaTotal=`TOTAL_IMPUESTOS_FAC`,
  ImporteTotal=`TOTAL_LIQUIDO_FAC` — el mismo importe que lleva el QR) o
  `RegistroAnulacion`. `NumSerieFactura` sale de
  `inLibVerifactu.ComponerNumSerieFactura`, idéntico al del QR.
- **Huella SHA-256 encadenada** (TipoHuella 01, hex en mayúsculas) según
  la especificación técnica de la AEAT. El último eslabón por NIF emisor
  vive en `fza_verifactu_cadena` (ver `verifactu_cadena.sql`): el envío
  hace `SELECT ... FOR UPDATE` de esa fila dentro de la transacción del
  worker, serializando el encadenamiento entre puestos; la fila solo
  avanza al aceptar la AEAT el registro (commit).
- **Transporte**: SOAP 1.1 por `THTTPClient` (SChannel/WinHTTP) con
  certificado de cliente del almacén de Windows. El certificado se
  selecciona por el nº de serie guardado en la empresa
  (`fza_empresas.CODIGO_CERTIFICADO_EMP`, el que se elige en la ficha de
  Empresas), con respaldo por titular y, en última instancia, el único
  ofrecido. Endpoints en parámetros (`www1`/`prewww1`; con certificado
  de sello cambiar a `www10`/`prewww10`).
- **Respuesta**: se parsea `EstadoEnvio` / `EstadoRegistro`
  (`Correcto`, `AceptadoConErrores` → aceptado; `Incorrecto` → error con
  código y descripción AEAT), el `CSV` (se guarda en
  `REQUEST_ID_CONSOLIDACION_FACCON`) y `TiempoEsperaEnvio` (el hilo lo
  respeta entre envíos consecutivos). La petición y la respuesta
  completas quedan en la consolidación.
- **SistemaInformatico**: NombreSistemaInformatico=`Factuzam`,
  IdSistemaInformatico=`FZ`, Version=`oVersion`, productor e instalación
  en parámetros (`appVerifactuSifNombreRazon`, `appVerifactuSifNif`,
  `appVerifactuIdInstalacion`), IndicadorMultiplesOT según el nº de
  empresas activas.

Parámetros añadidos: `appVerifactuUrlEnvioPre/Pro`,
`appVerifactuSifNombreRazon`, `appVerifactuSifNif` (**obligatorio
rellenarlo**), `appVerifactuIdInstalacion`, `appVerifactuDescripcionOpe`.

### Notas y decisiones a validar en el entorno PRE de la AEAT

- Devoluciones de caja: hoy van como F2 con importes negativos (igual
  que la factura). Si la AEAT las rechaza, habrá que emitirlas como
  rectificativas R5.
- Banda exenta: motivo `E1` fijo. Rectificativas: `R5` por diferencias
  (`TipoRectificativa=I`) sin bloque de facturas rectificadas.
- La cadena solo avanza con registros aceptados; un registro rechazado
  se regenera entero (nueva huella y FechaHoraHuso) en el reintento.
- Si la AEAT acepta pero la persistencia local fallara justo después
  (caída de BBDD), el reintento reenviará el registro y la AEAT lo
  rechazará como duplicado: revisar ese caso a mano desde la pestaña
  Registro/Errores (entrega «al menos una vez»).
- Envío de uno en uno (sin lotes de hasta 1000 registros); suficiente
  para el volumen de caja, optimizable más adelante.
- La consolidación queda completa: `VERIFACTU_URL_FACCON` (URL de
  cotejo), `QRCODE_PNG_FACCON` (PNG generado en local con
  `GenerarQRPngVerifactu`) y `QRCODE_BASE64_FACCON` (ese PNG en base64),
  además de CSV en `REQUEST_ID_CONSOLIDACION_FACCON`, id de cola en
  `QUEUE_ID_CONSOLIDACION_FACCON` (o `QUEUE_ID_CANCEL_FACCON` en la
  anulación), cadena, petición y respuesta completas.
- Cuando haya acceso al repositorio OdaVeriFactu, cotejar:
  `ComponerNumSerieFactura`, los tipos de evento (`TIPO_EVENTO_LOG`), la
  firma (`FIRMA_DIGITAL_LOG`) y el criterio de avance de la cadena.
