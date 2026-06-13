# Verifactu en caja: QR en el ticket + cola de envío

Aplicación a Factuzam del esquema de OdaVeriFactu: el ticket de venta sale
con el QR tributario de la AEAT y, tras grabar la venta, la factura queda
encolada para que un hilo en segundo plano la comunique a Verifactu.

## Flujo

1. **Venta en caja** (`UniDataCaja.GrabarFacturaSimplificada`): dentro de
   la transacción de la venta, si `appVerifactuActivo` está marcado, se
   inserta la factura en `fza_verifactu_cola` (PASO 4.6). Factura y cola
   se confirman o deshacen juntas.

   **Fases de la factura** (`FASE_FAC`): toda factura nace en `BORRADOR`
   (editable, sin imprimir). El *lanzamiento* (encolar el ALTA, sea
   desde la venta de caja, el botón Consolidar de Facturas, F3/F8 o una
   rectificativa) la pasa a `ONLINE` **en el acto**
   (`TVerifactuCola.EncolarFactura`): el QR es calculable en local y la
   petición al ws viaja asíncrona. Desde `ONLINE` ya puede imprimirse y
   deja de ser editable o borrable (solo Anular o Rectificar). Si el
   envío agota reintentos pasa a `ERROR` (relanzable desde la cola). El
   bloqueo de edición/impresión/borrado por fase vive en
   `TfrmMtoFacturasBase.ActualizarBloqueoEdicion`,
   `sbImprimirClick` y `unqryTablaGBeforeDelete`; aplica igual a
   normales y a simplificadas creadas a mano. El botón **Consolidar**
   lanza manualmente una factura en borrador (con líneas y, si es
   NORMAL, con NIF de cliente). «Convertir en normal» solo se muestra
   en el Mto de simplificadas.
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

## Menú Verifactu (inMtoPrincipal)

Menú principal nuevo «Verifactu» con tres opciones (alta de pantallas y
permisos en `verifactu_menu.sql`):

- **Declaración Responsable** (`inMtoModalVerifactuDecl`): modal con el
  texto de la declaración responsable del SIF (art. 13 RD 1007/2023),
  compuesto en tiempo real con el nombre del sistema, `IdSistemaInformatico`
  FZ, la versión (`oVersion`) y el productor/instalación de los
  parámetros Verifactu.
- **Cola de Envíos** (`inMtoVerifactuCola` + `UniDataVerifactuCola`):
  consulta de `fza_verifactu_cola` (estado, intentos, próximo intento,
  mensaje de error). Solo lista (sin ficha de detalle): se editan en el
  grid las columnas *Estado*, *Intentos* y *Próximo intento*; no se
  insertan ni se borran filas (la cola la alimenta el sistema). Ver
  «Reproceso manual».
- **Verifactu Log** (`inMtoVerifactuLog` + `UniDataVerifactuLog`):
  consulta de `fza_verifactu_eventos` con la cadena de hashes. Solo
  lectura.

Permisos: `menu.VerifactuCola`, `menu.VerifactuLog` y
`menu.mnuVerifactuDeclaracion` (visibles por defecto; ocultables por
grupo desde el mantenimiento de permisos).

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

### Diagnóstico rápido: «AEAT [1100] Valor o tipo incorrecto del campo: NIF»

Ese 1100 lo devuelve la AEAT cuando algún NIF del XML va vacío o mal
formado. Causas por orden de probabilidad:

1. `appVerifactuSifNif` sin rellenar (bloque `SistemaInformatico`). El
   cliente ahora lo valida antes de enviar y deja un mensaje claro en la
   cola.
2. NIF de la empresa con separadores o longitud distinta de 9. Los NIF
   se normalizan (mayúsculas, sin guiones/espacios) tanto en el QR como
   en el registro, y se validan antes del envío.
3. En PRE, además, el NIF del obligado debe ser un NIF real censado en
   el entorno de pruebas y guardar relación con el certificado usado
   (titular o apoderado); si no, la AEAT responde con errores de censo
   (no identificado / sin apoderamiento).

### Buscar operaciones (caja): Rectificar, Anular y Convertir en normal

La consulta de operaciones de caja (`inMtoConsultaOpe`) lleva tres
botones que operan sobre la factura del ticket seleccionado:

- **Rectificar**: confirma y carga la venta en una ventana de caja
  libre (o nueva) con las **líneas del ticket en negativo**, editables
  (`TfrmMtoOpeCaja.CargarRectificacion`). La fase de cobro muestra en el
  título «RECTIFICA a la factura serie\número», el combo de series
  carga las de **subtipo RECTIFICATIVA** y el documento se graba como
  `TIPO_FAC='RECTIFICATIVA'`; al terminar se enlaza
  (original → `FASE_FAC='RECTIFICADA'` + columnas ABONO apuntando a la
  rectificativa, comentario «ESTA FACTURA ANULA Y RECTIFICA…») y se
  encola (registro R5/R1). En modo rectificación el F8 (factura
  completa) queda bloqueado.
- **Anular Factura Verifactu**: encola el `RegistroAnulacion` del
  ticket (exige que esté consolidado).
- **Convertir en normal**: la conversión del ticket en factura completa
  (modal de cliente/serie/fecha, registro **F3** con
  `FacturasSustituidas`).

Series rectificativas: el botón de crear series de Empresas → Series
genera, además de las habituales, una serie **R1** de subtipo
`RECTIFICATIVA` genérica por empresa (puede crearse a mano una por
empresa/almacén/caja). La consulta de series de fase de cobro acepta
ahora las series genéricas de empresa (almacén/caja vacíos) además de
las propias del puesto.

El botón **Subsanar** se ha retirado de la interfaz (el motor de la
cola y el envío siguen soportando el tipo `SUBSANACION` por si hiciera
falta reexponerlo, p. ej. ante «aceptado con errores»).

### Botones de cobro F10 / F11

- **F10 Sin precios**: imprime DOS tickets — primero el regalo (sin
  precios, sin totales/pagos/IVA y sin QR; rotulado «TICKET REGALO») y
  después el fiscal completo con precios y QR Verifactu. En modo DEBUG
  el PDF del regalo lleva sufijo `_regalo`.
- **F11 Sin ticket**: no imprime nada pero **abre la cajonera**
  (`AbrirCajonSinVenta`, mismo helper del F9 global, con su permiso
  `caja.abrirCajon` y aviso si no hay impresora configurada).

En Facturas (Buscar/Modificar) los botones «Anular Verifactu» y
«Convertir en normal» viven ahora en la columna derecha de botones,
debajo de Consolidar (se eliminó el panel inferior).

### Anular y convertir desde Facturas (Buscar / Modificar)

En la columna de botones de Facturas (normales y simplificadas)
operan sobre la factura seleccionada:

- **Consolidar**: lanza manualmente a Verifactu una factura en
  `BORRADOR` (pasa a `ONLINE` en el acto y encola el ALTA; ver
  «Fases» en el Flujo). Exige líneas y, en NORMAL, NIF de cliente.
- **Anular Verifactu** (solo consolidadas): encola un
  `RegistroAnulacion`. Al aceptarse, la factura pasa a
  `FASE_FAC='CANCELADA'` y la consolidación a `ESTADO='ANULADO'` (con
  `QUEUE_ID_CANCEL_FACCON`).
- **Convertir en normal** (solo en el Mto de simplificadas): crea la
  factura F3 en sustitución del ticket (modal
  `inMtoModalFacturarTicket`; el cliente se elige con el buscador
  genérico `TfrmMtoSearch`, no con un combo).
- **Volver a Borrador**: deshace un lanzamiento que la AEAT aún NO ha
  aceptado (p. ej. NIF erróneo detectado tras Consolidar). Aparca la
  fila ALTA de la cola (`ERROR` con intentos al tope y mensaje) y
  devuelve la factura a `BORRADOR` para corregir y relanzar. Guardas:
  bloquea si ya está consolidada o la fila está `ENVIADA` (el registro
  existe en la AEAT → Anular/Rectificar) y si el hilo la está enviando
  en ese momento (`PROCESANDO`, bloqueo `FOR UPDATE` contra la cola).
  Un Consolidar posterior reactiva la fila (ON DUPLICATE → PENDIENTE
  con intentos a 0).

El motor de subsanación (`SUBSANACION`, reenvío del `RegistroAlta` con
`<Subsanacion>S</Subsanacion>`) sigue disponible en la cola aunque ya
no tiene botón propio: la rectificativa es el camino preferido.

**Histórico de relaciones** (`fza_facturas_relaciones`, script
`verifactu_relaciones.sql`): cada rectificativa (RECTIFICA) y cada F3
(SUSTITUYE) guarda su factura de origen en esta tabla, de modo que una
factura puede rectificarse **varias veces** sin perder trazabilidad: el
envío Verifactu resuelve la antecesora primero por aquí (y solo si no
hay fila usa el enlace ABONO inverso, que muestra la última). Consulta
N:1:

```sql
SELECT * FROM fza_facturas_relaciones
 WHERE SERIE_FAC_ORIGEN_FACREL = :SERIE
   AND NUMERO_FAC_ORIGEN_FACREL = :NUMERO;
```

Re-encolar una operación ya existente la relanza (vuelve a PENDIENTE
con los intentos a cero). La lista lleva además la columna **«Cola
Verifactu»** con el último estado de la cola de cada factura
(PENDIENTE/PROCESANDO/ENVIADA/ERROR; vacío si nunca se encoló): el
SELECT del listado se recompone en `CrearTablaPrincipal` con un
subselect a `fza_verifactu_cola`, así que no hay que tocar vistas ni
perfiles.

**Pestañas de la ficha** (5_Verifactu, 6_Registro, 7_Movimientos): las
tres son detail con parámetros `:SERIE_FAC`/`:NUMERO_FAC` del maestro.
UniDAC solo rellena los parámetros al hacer scroll del maestro con el
detail abierto, así que la apertura perezosa los dejaba a NULL
(pestañas vacías): `TdmFacturas.RellenarParamsDesdeMaestro` los copia
a mano antes del `Open` en cada `AsegurarXxxAbierta`. Además:

- **7_Movimientos** filtraba por `TIPO_DOC_REF_MOV='FC'`, columnas que
  el SP nunca rellena: ahora filtra por `TIPO_DOC_MOV IN ('FC','VE')`
  + `SERIE/NUMERO_DOC_MOV` (caja graba 'VE', el Mto 'FC'). El control
  de duplicados de `GenerarMovimientosSalidaFactura` usaba las mismas
  columnas REF vacías y, una vez corregido, seguía sin contar las
  salidas 'VE' de caja: un Post de la cabecera de una simplificada
  nacida en caja duplicaba la salida de stock. Ahora cuenta
  `IN ('FC','VE')`; los duplicados ya creados se limpian (con
  reversión de stock) con `limpiar_movimientos_fac_duplicados.sql`.
- **6_Registro** listaba TODOS los eventos (SQL sin parámetros): ahora
  filtra por la factura activa (`NUMERO/SERIE_FAC_LOG`).
- **5_Verifactu**: el memo de URL apuntaba a `VERIFACTU_URL` (sin
  sufijo `_FACCON`) y `txtREQUEST_ID` no se reataba por instancia en
  `AsignarControles`.

### Rectificativas (botón Rectificar → Abonar)

El botón **Rectificar** de Facturas (modal Abonar/Duplicar, que ya
existía) queda integrado con Verifactu. Al crear el abono con
`PRC_CREAR_FACTURA_ABONO`, `TVerifactuCola.EncolarRectificativa`:

- Marca la nueva como `TIPO_FAC='RECTIFICATIVA'` y añade a sus
  comentarios «ESTA FACTURA ANULA Y RECTIFICA A LA serie\número».
- La **original** pasa a `FASE_FAC='RECTIFICADA'` y guarda en sus
  columnas `SERIE/NUMERO_FAC_ABONO_FAC` la rectificativa (el antecesor
  apunta a su sucesor).
- Encola la rectificativa: el registro sale como **R5** si la original
  era simplificada o **R1** si era completa (con destinatario),
  `TipoRectificativa=I` (importes en negativo) y bloque
  `FacturasRectificadas` apuntando a la original (lookup inverso por
  `IDX_FAC_ABONO`).

Requiere ejecutar `verifactu_rectificativas.sql` (ensancha las columnas
de enlace a varchar(20) y crea el índice del lookup inverso).

### Facturar ticket (factura completa F3 en sustitución)

Botón **«Facturar ticket (F3)»** en Buscar/Modificar, solo para
facturas SIMPLIFICADAS. Abre `inMtoModalFacturarTicket`: pide
**cliente** (lookup de `fza_clientes`), **serie** de factura (por
defecto la ligada al almacén del ticket vía
`ObtenerSeriePropiaAlmacen`, si no la serie FC por defecto) y **fecha**
(por defecto la del ticket). Crea la factura NORMAL copiando cabecera y
líneas del ticket (importes en positivo), con la identidad del cliente
denormalizada desde su ficha, comentario «EMITIDA EN SUSTITUCIÓN DE LA
FACTURA SIMPLIFICADA serie\número», recalcula netos
(`PRC_CALCULAR_FACTURA_NETOS`) y deja el ticket apuntando a la nueva en
sus columnas ABONO. Se encola como alta y el registro sale como **F3**
con el bloque `FacturasSustituidas`; el ticket NO se anula (la F3 lo
sustituye declarativamente).

### Factura completa desde caja (botón Factura / F8 en fase de cobro)

En la fase de cobro, el botón **Factura (F8)** graba la venta
directamente como factura **NORMAL** en lugar de simplificada:

- Exige cliente asignado a la operación **con NIF** (si no, avisa y no
  sigue).
- Pide **serie** de factura completa (por defecto la ligada al almacén
  vía `ObtenerSeriePropiaAlmacen`, si no la serie FC por defecto) y
  **fecha** (por defecto hoy) en `inMtoModalSerieFechaFactura`.
- La venta se graba igual que siempre (stock, operación de caja,
  pagos, vales) pero con `TIPO_FAC='NORMAL'` y la serie/fecha
  elegidas; se encola en Verifactu y el registro sale como **F1** con
  destinatario.
- **No imprime ticket térmico**: abre el visor FastReport de facturas
  (`inMtoModalImpFac`) en A4 para imprimir o exportar a PDF.

### QR tributario en los formatos FastReport ('qrverifactu')

El QR del **ticket térmico** (ESC/POS nativo) y el del **Excel**
(`inLibFacturaExcel`, imagen incrustada en la columna H) funcionan y se
generan en local con `ConstruirUrlQR` + `GenerarQRPngVerifactu` (PNG
**RGB**). El QR de la **consolidación** (`fza_facturas_consolidaciones`,
visible en la pestaña 5 de la ficha) también.

En el **A4 (FastReport)** el QR NO se inyecta ni se mueve por código: el
framework solo **rellena** el `TfrxPictureView` llamado **`qrverifactu`**
si el formato lo trae (vía `FindObject` en `TfrmPrintFac.AfterReportLoaded`
y el `OnBeforePrint` encadenado en `TfrmPrint.ReportBeforePrintConQR`).
Decisión de diseño (el usuario coloca el hueco): los intentos de
inyectar/mover el QR por código rompían el layout y, además, un
`TfrxPictureView` rellenado en una **banda estática** (cabecera/pie de
página) no lo dibuja FastReport en esta versión —solo en **bandas de
datos**, como las fotos de tickets/etiquetas—.

**Cómo añadir el QR al A4** (una vez, en el diseñador de FastReport):

Hay dos formas; la **recomendada (A)** no necesita código de relleno.

**(A) Picture ligado a dato (recomendada).** Tras ejecutar
`vi_facturas_print_consolidaciones.sql`, la vista `vi_facturas_print`
trae por LEFT JOIN el QR ya generado en `QRCODE_PNG_FACCON` (y TIPO_FAC,
FASE_FAC, VERIFACTU_URL_FACCON…). En el diseñador:
1. Crear un **Picture** (`TfrxPictureView`).
2. Enlazarlo a datos: `DataSet = Facturas`,
   `DataField = QRCODE_PNG_FACCON`.
3. Colocarlo donde se quiera (incluida la cabecera: al ser imagen
   ligada a dato, FastReport la pinta por el motor de datos, igual que
   los memos `[Facturas."..."]`). Tamaño mínimo 30×30 mm.
4. Guardar. No hace falta nada más: el blob de la vista es el PNG.

**(B) Picture llamado `qrverifactu` (relleno por código).** Crear un
Picture y renombrarlo exactamente `qrverifactu`, colocándolo en una
**banda de datos** (no en cabecera de página: ahí un picture rellenado
por código no se dibuja). El framework lo rellena en
`TfrmPrintFac.AfterReportLoaded` / `OnBeforePrint`.

**Título por tipo**: el memo de título (texto exacto `FACTURA`) se
reescribe por registro a `FACTURA SIMPLIFICADA` / `FACTURA RECTIFICATIVA`
según `TIPO_FAC` (la consulta de `TfrmPrintFac.preparar_consulta` añade
`TIPO_FAC` con un JOIN a `fza_facturas`). Esto sí funciona en la
cabecera porque es texto, no imagen.

**Excel** (botón Excel de `TfrmPrintFac`, `inLibFacturaExcel`): la hoja
lleva el QR tributario incrustado a la derecha (columna H) y el título
según el tipo. La incrustación va envuelta en `try/except`: si fallara,
la factura sale a Excel sin QR en vez de reventar.

Resumen de caminos: registro mal comunicado → **Subsanar**; precios o
conceptos mal → **Rectificar** (o devolución en caja); cliente pide
factura nominativa de su ticket ya emitido → **Facturar ticket (F3)**;
cliente identificado en el momento de la venta → **Factura (F8)** en
fase de cobro; venta inexistente → **Anular**.

### Reintentos, duplicados y reproceso manual

- Si la AEAT **acepta** pero la persistencia local falla (caída de BBDD
  justo después del envío), la fila vuelve a la cola con el mensaje
  «Aceptado por la AEAT pero falló la persistencia local: …». En el
  reintento la AEAT responderá *registro duplicado* (err. 3000) y el
  cliente lo da por aceptado: consolida (estado `DUPLICADO`), genera el
  QR y marca la factura como consolidada. El sistema se autocura.
- **Reproceso automático**: en cada ciclo, las filas en `ERROR` con
  `CONTADOR_INTENTOS < appVerifactuMaxIntentos` vuelven a `PENDIENTE`
  (sirve para revivir colas tras corregir configuración o tras subir el
  parámetro de máximo de intentos).
- **Reproceso manual**: en el menú Verifactu → Cola de Envíos (pantalla
  solo-lista, sin ficha de detalle) se pueden editar las columnas
  *Estado* (combo PENDIENTE/PROCESANDO/ENVIADA/ERROR), *Intentos* y
  *Próximo intento*; al grabar, el hilo la retoma en el siguiente ciclo.
  El resto de columnas son de solo lectura. No se pueden **borrar** ni
  **insertar** filas (la cola la alimenta el sistema; el data module solo
  define `SQLUpdate`): el navegador no muestra esos botones y los atajos
  Ins / Ctrl+Supr quedan anulados.
- **Ir a la factura**: con **Ctrl+Alt+F** o **Ctrl+Mayús+F**, o con el
  botón lateral **«Ir a Documento»**, se salta a la factura de la fila
  activa. `inLibShowMto.ResolverCallFactura` mira `TIPO_FAC` en
  `fza_facturas` y abre la pantalla correcta —Facturas o
  FacturasSimplif— posicionada en serie\número, así se llega a la
  factura aunque no se sepa si es simplificada o normal.

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
