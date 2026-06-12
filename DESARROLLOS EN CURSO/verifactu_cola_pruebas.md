# Batería de pruebas: Verifactu en caja (QR + cola + hilo)

Pruebas de verificación del desarrollo descrito en `verifactu_cola.md`,
incluido el cliente de envío real a la AEAT (`inLibVerifactuEnvio`).

Convención: cada caso tiene ID, pasos y resultado esperado. El bloque F
(envío real) requiere certificado instalado y el entorno PRE de la AEAT;
el resto se puede pasar sin salir a internet.

---

## 0. Preparación

1. Compilar `fzam.dproj` (las 3 units nuevas están en `fzam.dpr`; no debe
   haber errores ni warnings nuevos).
2. Ejecutar `DESARROLLOS EN CURSO/verifactu_cola.sql`,
   `DESARROLLOS EN CURSO/verifactu_cadena.sql` y
   `DESARROLLOS EN CURSO/verifactu_menu.sql` en la BBDD de pruebas.
3. Datos mínimos: empresa con NIF real de pruebas (p. ej. `B12345678`),
   serie de facturación de caja (tipo `FC`), un artículo con tarifa y
   stock, cliente contado.
4. Impresora de caja en `DEBUG` (parámetro `vgerDefPrinter` vacío o
   DEBUG) para ver el ticket en el visualizador y en PDF sin gastar
   papel.
5. Para consultar el log de la aplicación: activar `appLogAvanzado` o
   revisar el fichero de log de `inLibLog`.
6. Para el bloque F (envío real): certificado FNMT (nominal o de
   representación) instalado en el almacén personal de Windows y
   **seleccionado en la ficha de la empresa** (botón de certificados de
   `inMtoEmpresas` → rellena `CODIGO_CERTIFICADO_EMP`), y el parámetro
   `appVerifactuSifNif` relleno con el NIF del productor del software.

---

## A. Script SQL idempotente

**A1 — Creación limpia.** Ejecutar `verifactu_cola.sql` en una BBDD sin
la tabla.
- `SHOW CREATE TABLE fza_verifactu_cola;` → existe, InnoDB,
  `utf8mb4_spanish_ci`, PK `ID_VFCOLA` AUTO_INCREMENT.
- `SHOW INDEX FROM fza_verifactu_cola;` → `UQ_VFCOLA_SERIE_NUMERO_TIPO`
  (único, 3 columnas) e `IDX_VFCOLA_ESTADO_PROXIMO`.

**A2 — Re-ejecución.** Ejecutarlo una segunda vez completo.
- No da error; devuelve los `SELECT '... ya existe, se omite'`.

**A3 — Unicidad.** Insertar dos veces a mano la misma
(serie, número, 'ALTA') con INSERT simple (sin ON DUPLICATE).
- La segunda falla con error 1062 (duplicado). Limpiar después.

---

## B. Parámetros

**B1 — Alta de categoría.** Abrir Parámetros de aplicación
(`inMtoAppParam`).
- Aparece la categoría **Verifactu** con 6 parámetros y estos defectos:
  `appVerifactuActivo=False`, `appVerifactuEntorno=PRE`,
  `appVerifactuUrlQRPre=https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR`,
  `appVerifactuUrlQRPro=https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR`,
  `appVerifactuSegundosCiclo=60`, `appVerifactuMaxIntentos=10`.

**B2 — Persistencia.** Poner `appVerifactuActivo=True`, guardar, cerrar
sesión y volver a entrar.
- El valor persiste (se guarda vía perfiles bajo `frmMtoAppParam`).

---

## C. QR tributario en el ticket de venta

Para C1-C5: `appVerifactuActivo=True`, `appVerifactuEntorno=PRE`.

**C1 — Venta simple.** Vender 1 artículo de 10,00 € y cobrar con ticket.
- El ticket (preview/PDF) muestra arriba: línea «QR tributario:», el QR,
  y debajo «VERI*FACTU - Factura verificable» / «en la sede electrónica
  de la AEAT».
- Escanear el QR con el móvil. URL exacta esperada:
  `https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR?nif=B12345678&numserie=<SERIE><NUMERO>&fecha=<dd-mm-aaaa>&importe=10.00`
  con el NIF de la empresa, serie+número concatenados de la factura
  grabada, la fecha de la factura y punto decimal en el importe.
- Cuadrar contra BBDD:
  ```sql
  SELECT SERIE_FAC, NUMERO_FAC, FECHA_FAC, TOTAL_LIQUIDO_FAC,
         NIF_EMPRESA_FAC
    FROM fza_facturas ORDER BY INSTANTE_ALTA DESC LIMIT 1;
  ```

**C2 — Caracteres reservados en la serie.** Usar una serie con `/`
(p. ej. `ANA/2026`).
- En la URL, el `/` va codificado como `%2F` y el QR escanea sin
  romperse.

**C3 — Formato de importe.** Venta de 1.234,56 €.
- En la URL: `importe=1234.56` (punto decimal, sin separador de miles).

**C4 — Devolución.** Operación con total negativo (p. ej. -5,00 €).
- `importe=-5.00`; el resto de la URL con el mismo formato.

**C5 — Cobro parcial.** Entregar menos del total para que la factura se
recuadre (`TransformarLineasParaCobroParcial`).
- El `importe` del QR coincide con el `TOTAL_LIQUIDO_FAC` realmente
  grabado en `fza_facturas` (no con el total original).

**C6 — Verifactu desactivado.** `appVerifactuActivo=False` y vender.
- El ticket NO lleva QR ni leyenda (y ya no aparece el antiguo QR de
  relleno `hacienda.com`). El resto del ticket es idéntico.

**C7 — Entorno producción.** `appVerifactuEntorno=PRO` y vender.
- La URL del QR empieza por
  `https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR`.
  Volver a PRE al terminar.

**C8 — PDF.** Comprobar el PDF que se genera en la carpeta de tickets.
- El QR se ve también en el PDF (el visualizador parsea el comando
  ESC/POS con nivel de corrección 49 = M).

**C9 — Cotejo AEAT (opcional, con red).** Abrir la URL del QR en un
navegador.
- El endpoint de la AEAT responde (página de cotejo). En PRE puede pedir
  certificado; basta verificar que no es un 404.

---

## D. Encolado al grabar la venta

**D1 — Alta en cola.** Con Verifactu activo, una venta con ticket.
- ```sql
  SELECT * FROM fza_verifactu_cola ORDER BY ID_VFCOLA DESC LIMIT 1;
  ```
  → fila con la serie/número de la factura, `TIPO_OPERACION='ALTA'`,
  `ESTADO='PENDIENTE'`, `CONTADOR_INTENTOS=0`, `INSTANTE_ALTA` y
  `USUARIO_ALTA` rellenos, `INSTANTE_ENVIO` NULL.

**D2 — ON DUPLICATE.** Repetir a mano el INSERT de la misma factura con
el SQL de `EncolarFactura` (con ON DUPLICATE KEY UPDATE).
- No se crea fila nueva: solo cambia `INSTANTE_MODIF`/`USUARIO_MODIF`.
  `CONTADOR_INTENTOS` y `ESTADO` no se resetean.

**D3 — Operación sin factura.** Hacer una operación que no requiere
factura (p. ej. solo cancelar un depósito sin importe).
- No se inserta nada en la cola (tampoco hay factura).

**D4 — Verifactu OFF.** `appVerifactuActivo=False` y vender.
- La venta se graba normal y NO hay fila nueva en la cola.

**D5 — Transaccionalidad (avanzado).** Forzar un fallo dentro de la
transacción DESPUÉS del encolado: desde otra sesión MySQL, `LOCK TABLES
fza_caja_pagos WRITE;` y lanzar el cobro (el PASO 5 quedará bloqueado
hasta timeout → rollback). Soltar el lock con `UNLOCK TABLES;`.
- El cobro da el error «No se ha registrado la operación» y NO queda ni
  factura ni fila en `fza_verifactu_cola` (se encolan/deshacen juntas).

**D6 — Conteo.** Hacer 3 ventas seguidas.
- `SELECT COUNT(*) FROM fza_verifactu_cola WHERE ESTADO_VFCOLA =
  'PENDIENTE';` crece exactamente en 3.

---

## E. Hilo de la cola (comportamiento con el stub actual)

**E1 — Arranque y parada.** Abrir la aplicación, esperar al principal, y
cerrarla.
- En el log: «Cola Verifactu: hilo iniciado» al arrancar y «Cola
  Verifactu: hilo detenido» al cerrar. Sin AVs ni cuelgues al salir.

**E2 — Cierre inmediato.** Abrir la app y cerrarla a los pocos segundos
(durante la espera del primer ciclo).
- Cierra casi al instante (la espera está troceada en pasos de 100 ms).

**E3 — Error controlado sin configuración.** Con `appVerifactuActivo=True`,
una fila PENDIENTE y SIN certificado en la empresa ni red hacia la AEAT,
dejar pasar un ciclo.
- La fila pasa por `PROCESANDO` y vuelve a `PENDIENTE` con
  `CONTADOR_INTENTOS=1`, `MENSAJE_ERROR` relleno (fallo TLS/HTTP) e
  `INSTANTE_PROXIMO_INTENTO` a +60 s. En `fza_verifactu_eventos` hay un
  evento tipo 4 con el detalle. La app no se cuelga durante el intento.

**E4 — La venta no se bloquea.** Mientras el hilo está reintentando,
seguir vendiendo en caja.
- El cobro y el ticket no se ven afectados (el envío va en el hilo, con
  conexión propia).

**E5 — OFF en caliente.** Con la app abierta, poner
`appVerifactuActivo=False` (guardar parámetros) y esperar 2 ciclos.
- No aparecen eventos nuevos ni actividad del hilo (verificable con el
  monitor SQL / `appLogSQL`: ninguna consulta a `fza_verifactu_cola`).

**E6 — ON en caliente.** Volver a `True` sin reiniciar.
- Al ciclo siguiente vuelve la actividad (nuevo aviso E3 solo si la
  sesión es nueva; la marca de aviso es por sesión de aplicación).

**E7 — Caída de BBDD.** Con la app abierta y Verifactu ON, parar el
servicio MariaDB ~30 s y arrancarlo de nuevo.
- En el log aparece «Cola Verifactu: <error>»; la app no se cae y en
  ciclos posteriores el hilo se recupera (recrea su conexión propia).

**E8 — Cadena de hashes del log de eventos.**
```sql
SELECT a.ID_LOG,
       IF(a.HASH_ANTERIOR_LOG = IFNULL(
            (SELECT b.HASH_PROPIO_LOG FROM fza_verifactu_eventos b
              WHERE b.ID_LOG < a.ID_LOG
              ORDER BY b.ID_LOG DESC LIMIT 1),
            REPEAT('0', 64)),
          'OK', 'ROTA') AS CADENA
  FROM fza_verifactu_eventos a
 ORDER BY a.ID_LOG;
```
- Todas las filas `OK` (la primera encadena con 64 ceros). `HASH_PROPIO`
  y `FIRMA_DIGITAL` tienen 64 caracteres hex.

---

## F. Envío real a la AEAT (entorno PRE, con certificado)

Con la preparación del punto 0.6 hecha y `appVerifactuEntorno=PRE`:

**F1 — Envío OK.** Vender con ticket y esperar un ciclo.
- Cola: la fila pasa `PENDIENTE → PROCESANDO → ENVIADA`, con
  `INSTANTE_ENVIO_VFCOLA` relleno y `MENSAJE_ERROR` NULL.
- `fza_facturas_consolidaciones`: fila nueva con `ID_FACCON`
  correlativo, `ESTADO='PROCESADO'`, CSV de la AEAT en
  `REQUEST_ID_CONSOLIDACION_FACCON`, el ID de la cola en
  `QUEUE_ID_CONSOLIDACION_FACCON`, `CHAIN_NUMBER`/`CHAIN_HASH`, la URL
  de cotejo, el QR en PNG y base64 (`QRCODE_PNG_FACCON` /
  `QRCODE_BASE64_FACCON`) y los XML completos de petición y respuesta.
- `fza_verifactu_cadena`: la fila del NIF avanza (`CONTADOR_VFCAD`+1,
  `HUELLA_VFCAD` = `CHAIN_HASH_FACCON` de la consolidación nueva).
- `fza_facturas`: `ESCONSOLIDADA_FAC='S'`, `INSTANTECONSO_FAC` relleno,
  `FASE_FAC='ONLINE'`.
- `fza_verifactu_eventos`: evento tipo 3 con la serie/número y el CSV.
- La pestaña Verifactu de la ficha de factura muestra el QR (imagen) y
  el estado.
- Cotejo final: escanear el QR del ticket → la sede de la AEAT (PRE)
  encuentra la factura remitida.

**F2 — Coherencia QR/registro.** Comparar el `numserie` del QR del
ticket con el `NumSerieFactura` del XML guardado en
`PETICION_COMPLETA_FACCON`, y el `importe` del QR con `ImporteTotal`.
- Idénticos (ambos salen de `ComponerNumSerieFactura` /
  `TOTAL_LIQUIDO_FAC`). La huella del XML (`Huella`) coincide con
  `CHAIN_HASH_FACCON`.

**F3 — Error transitorio y backoff.** Cortar la red (o apuntar el
endpoint a una URL inválida) y vender.
- Por cada ciclo fallido: `CONTADOR_INTENTOS+1`, `MENSAJE_ERROR`
  relleno, `INSTANTE_PROXIMO_INTENTO` con backoff creciente
  (60 s, 120 s, 240 s… techo 32 min), `ESTADO` vuelve a `PENDIENTE`, y
  un evento tipo 4 por intento.

**F4 — Reintentos agotados.** Bajar `appVerifactuMaxIntentos=2` y
repetir F3.
- Al segundo fallo la fila pasa a `ESTADO='ERROR'` (ya no se reintenta)
  y la factura a `FASE_FAC='ERROR'`. Restaurar el parámetro.

**F5 — Anulación.** Encolar un `TIPO_OPERACION='ANULACION'` de una
factura enviada.
- Al confirmarse, `FASE_FAC='CANCELADA'`.

**F6 — Multi-puesto.** Dos equipos con la misma BBDD, ambos con
Verifactu ON, y una tanda de ventas en cada uno.
- Cada fila la procesa exactamente un puesto (reclamo optimista por
  `UPDATE … WHERE ESTADO='PENDIENTE'`). Sin filas duplicadas en
  consolidaciones (lo garantiza también `UK_FACTURA`).

**F7 — Rescate de huérfanas.** Matar el proceso (administrador de
tareas) con una fila en `PROCESANDO`, o simularla:
```sql
UPDATE fza_verifactu_cola
   SET ESTADO_VFCOLA = 'PROCESANDO',
       INSTANTE_MODIF = DATE_SUB(NOW(), INTERVAL 15 MINUTE)
 WHERE ID_VFCOLA = <id>;
```
- Al siguiente ciclo (con >10 min de antigüedad) vuelve a `PENDIENTE` y
  se reenvía.

---

## G. Regresión

**G1 — Ticket sin Verifactu.** Con `appVerifactuActivo=False`, comparar
un ticket con uno anterior al cambio.
- Única diferencia: desaparece el QR de relleno. Artículos, totales,
  IVAs, pagos, cambio, vales y pie intactos.

**G2 — Resto de tickets.** Resguardo de depósito, recordatorio, ticket
de arqueo y de traspaso.
- Imprimen igual que antes (no se han tocado).

**G3 — Venta fluida.** Tanda de ventas rápidas con Verifactu ON.
- Sin demora apreciable en el cobro (el encolado es un único INSERT
  dentro de la transacción ya existente).

**G4 — Ficha de facturas.** Abrir Facturas y la pestaña Verifactu de
una factura cualquiera.
- Sigue cargando en perezoso sin errores (consolidación vacía hasta que
  haya envíos reales).

**G5 — Arranque/cierre repetido.** Abrir y cerrar la aplicación 5 veces
seguidas.
- Sin bloqueos al salir (el hilo para en `FormClose` antes de liberar
  conexiones) y sin conexiones zombi en MariaDB
  (`SHOW PROCESSLIST;` vuelve al estado base tras cerrar).

---

## H. Menú Verifactu

**H1 — Menú visible.** Tras ejecutar `verifactu_menu.sql` y entrar en la
aplicación.
- Aparece el menú principal **Verifactu** (antes de Ayuda) con tres
  items: «Declaración Responsable», «Cola de Envíos» y «Verifactu Log».

**H2 — Declaración Responsable.** Abrirla.
- Modal de solo lectura con el texto de la declaración: nombre del
  sistema (Factuzam), Id FZ, la versión actual (`oVersion`), el
  productor y NIF de los parámetros, número de instalación, la
  referencia al RD 1007/2023 y Orden HAC/1177/2024 y la fecha de
  consulta. Aceptar/ESC la cierran.

**H3 — Cola de Envíos.** Abrirla con filas en la cola.
- Grid de solo lectura sobre `fza_verifactu_cola` ordenado por Id
  descendente: serie/número, operación, estado, intentos, próximo
  intento, instante de envío y mensaje de error. No deja editar celdas.

**H4 — Verifactu Log.** Abrirla con eventos registrados.
- Grid de solo lectura sobre `fza_verifactu_eventos`: fecha-hora, tipo,
  evento, datos adicionales, serie/número, usuario, versión y los tres
  hashes de la cadena.

**H5 — Permisos.** Poner a 'N' el permiso `menu.VerifactuCola` para un
grupo de prueba y entrar con un usuario de ese grupo.
- El item «Cola de Envíos» desaparece del menú; el resto sigue visible.
  Restaurar el permiso al terminar.

---

## I. Anular / Subsanar desde Facturas

**I1 — Columna «Cola Verifactu».** Abrir Facturas (normales o
simplificadas) tras encolar/enviar alguna factura.
- La lista muestra la columna «Cola Verifactu» con el último estado de
  la cola por factura (vacía en facturas nunca encoladas). Es de solo
  lectura y funciona en las dos variantes.

**I2 — Guardas.** Con una factura SIN consolidar seleccionada, pulsar
«Anular (Verifactu)» o «Subsanar (Verifactu)».
- Aviso «aún no está consolidada» y no se encola nada.

**I3 — Anulación.** Seleccionar una factura consolidada → «Anular
(Verifactu)» → confirmar. Esperar un ciclo del hilo.
- Aparece fila `ANULACION` en la cola (PENDIENTE → ENVIADA); la factura
  pasa a `FASE_FAC='CANCELADA'`; la consolidación queda en
  `ESTADO='ANULADO'` con `QUEUE_ID_CANCEL_FACCON` relleno; evento tipo 3
  en el log con la anulación; la columna «Cola Verifactu» refleja el
  estado.

**I4 — Subsanación.** Sobre una factura consolidada → «Subsanar
(Verifactu)» → confirmar. Esperar un ciclo.
- Fila `SUBSANACION` en la cola → ENVIADA; el XML enviado
  (`PETICION_COMPLETA_FACCON`) contiene `<Subsanacion>S</Subsanacion>`;
  la consolidación se reescribe con `ESTADO='SUBSANADO'` y nueva
  petición/respuesta; la factura sigue `FASE_FAC='ONLINE'`.

**I5 — Relanzar operación.** Repetir la subsanación de I4.
- No se duplica la fila: la misma fila `SUBSANACION` vuelve a
  `PENDIENTE` con intentos a 0 y se reenvía.

**I6 — Rectificativa.** (Tras ejecutar `verifactu_rectificativas.sql`.)
Seleccionar una factura simplificada consolidada → botón Rectificar →
marcar «Abonar» → Generar. Esperar un ciclo del hilo.
- Se crea el abono (líneas en negativo) con `TIPO_FAC='RECTIFICATIVA'`
  y el comentario «ESTA FACTURA ANULA Y RECTIFICA A LA serie\número».
- La ORIGINAL pasa a `FASE_FAC='RECTIFICADA'` y sus columnas
  `SERIE/NUMERO_FAC_ABONO_FAC` apuntan a la rectificativa.
- En `PETICION_COMPLETA_FACCON` de la rectificativa: `TipoFactura=R5`
  (R1 con destinatario si la original era completa),
  `TipoRectificativa=I` y bloque `FacturasRectificadas` con la
  original; `ImporteTotal` negativo.
- La rectificativa queda consolidada (`FASE_FAC='ONLINE'`) con su QR.

**I7 — Facturar ticket (F3).** Seleccionar un ticket (SIMPLIFICADA)
consolidado → «Facturar ticket (F3)» → elegir cliente, serie (viene la
del almacén del ticket o la FC por defecto) y fecha (viene la del
ticket) → Generar. Esperar un ciclo.
- Se crea una factura `NORMAL` con los mismos importes (en positivo),
  los datos del cliente elegido y el comentario «...EN SUSTITUCIÓN DE
  LA FACTURA SIMPLIFICADA serie\número»; el ticket guarda en sus
  columnas ABONO la factura nueva y NO se anula.
- El registro de la nueva sale como `TipoFactura=F3` con
  `FacturasSustituidas` apuntando al ticket y destinatario relleno; la
  nueva queda consolidada con su QR.
- Con la factura nueva seleccionada, los botones Anular/Subsanar operan
  sobre ella con normalidad.

**I8 — Factura desde caja (F8).** En caja, con cliente CON NIF asignado
a la operación, cobrar con el botón **Factura** (o F8) → elegir serie
(viene la del almacén) y fecha (hoy) → Aceptar.
- No se imprime ticket: se abre el visor FastReport A4 de facturas para
  imprimir/exportar.
- La venta queda grabada como `TIPO_FAC='NORMAL'` con la serie y fecha
  elegidas; stock, operación de caja y pagos como en una venta normal.
- Se encola y el registro sale como `F1` con destinatario; queda
  consolidada con su QR.
- Sin cliente (o sin NIF), F8 avisa y no deja continuar; el resto de
  botones de cobro siguen funcionando como siempre.

**I10 — Rectificar desde Buscar operaciones.** (Antes: crear la serie
rectificativa con el botón de series de Empresas, o a mano con subtipo
`RECTIFICATIVA`.) En Buscar operaciones, seleccionar una venta con
ticket → **Rectificar** → confirmar.
- Se abre/reutiliza una ventana de ventas con las líneas del ticket en
  negativo y el cliente del original; el título indica «RECTIFICA a
  serie\número». Las líneas se pueden ajustar o borrar.
- Al cobrar (F12), la fase de cobro muestra la referencia en el título
  y el combo de series solo ofrece series de subtipo RECTIFICATIVA
  (p. ej. R1); el F8 está bloqueado en este modo.
- Tras grabar: el documento nuevo es `TIPO_FAC='RECTIFICATIVA'` con la
  serie R1; la original pasa a `FASE_FAC='RECTIFICADA'` con sus
  columnas ABONO apuntando a la rectificativa; la rectificativa lleva
  el comentario «ESTA FACTURA ANULA Y RECTIFICA A LA serie\número»; el
  registro sale como R5/R1 con `FacturasRectificadas`, y el ticket
  térmico se imprime con su QR.

**I11 — Botonera de Buscar operaciones.** Comprobar los tres botones:
Rectificar (I10), «Anular Factura Verifactu» (encola la anulación del
ticket consolidado, con guardas) y «Convertir en normal» (flujo F3 del
modal con cliente/serie/fecha). El botón Subsanar ya no existe en
ninguna pantalla.

**I13 — Rectificaciones múltiples.** (Tras ejecutar
`verifactu_relaciones.sql`.) Rectificar dos veces la misma factura
(p. ej. una prenda hoy y otra después), dejando o no pasar el ciclo del
hilo entre ambas.
- `fza_facturas_relaciones` tiene DOS filas RECTIFICA apuntando a la
  original; las columnas ABONO de la original muestran la última.
- El registro de CADA rectificativa sale con su bloque
  `FacturasRectificadas` apuntando a la original (aunque las dos se
  envíen en el mismo ciclo).
- La consulta N:1 del .md devuelve ambas rectificativas.

**I12 — F10 y F11 en fase de cobro.** Cobrar una venta con F10 («Sin
precios»).
- Salen DOS tickets: el regalo («TICKET REGALO», artículos y unidades
  sin importes, sin IVA y sin QR) y el fiscal completo con precios y
  QR. En DEBUG, dos PDFs (el regalo con sufijo `_regalo`).
- Cobrar otra venta con F11 («Sin ticket»): no se imprime nada y la
  cajonera se abre (con impresora real configurada); la venta queda
  grabada y encolada en Verifactu con normalidad.

**I9 — QR en el A4.** Con Verifactu activo, imprimir una factura (F8 de
caja o botón Imprimir de Facturas) con cada uno de los dos formatos
(normal y simplificada).
- La vista previa muestra el QR tributario (30×30 mm) arriba a la
  derecha aunque el formato no lo tuviera diseñado; escaneado coincide
  con la URL de cotejo de la factura del registro.
- En una impresión por rango, cada factura sale con SU QR.
- Recolocar en el diseñador un PictureView llamado `qrverifactu` y
  guardar el formato → la impresión respeta la nueva posición.
- Con Verifactu desactivado, el hueco sale vacío (sin QR de relleno).
