# Código de barras por ticket y devoluciones por ticket (F4)

Desarrollo del 30/07/2026. Tres piezas que van juntas:

1. **EAN-13 por ticket** (prefijo `29`) impreso en el ticket ESC/POS,
   gobernado por un parámetro nuevo de caja.
2. **F4 en operaciones de caja**: devolución cargando los artículos del
   ticket en negativo. El ticket se localiza escaneando su código de
   barras **o** buscando por EMPRESA/ALMACÉN/CAJA/Nº OPERACIÓN **o** por
   SERIE/Nº DOCUMENTO. Devolución sin código: al meter una prenda en
   negativo se propone la lista de ventas que la contienen (cancelable).
   En ambos casos se pide **motivo de devolución** al cobrar.
3. **Traspaso automático**: si el ticket de origen es de otra tienda, la
   entrada de stock de la devolución se hace en el almacén de ORIGEN y en
   la misma transacción se genera el traspaso automático origen → tienda
   actual (TR misma empresa / TA entre empresas).

> Estado: **implementado, pendiente de compilar y probar**. Ningún cambio
> toca `factuzam_original.sql`.

---

## 1. Esquema (script idempotente `codigo_barras_ticket.sql`)

| Cambio | Detalle |
|---|---|
| `fza_facturas.CODIGO_BARRAS_FAC` | `varchar(13) NULL`, EAN-13 del ticket |
| Índice `UQ_FAC_CODIGO_BARRAS` | único, resuelve el escaneo en O(1) |
| Contador `TK` en `fza_contadores` | global (`-`/`-`), 10 dígitos |

**Orden de despliegue**: aplicar el `.sql` ANTES de desplegar el ejecutable.
Aun así, el código degrada con elegancia: si la columna no existe, no se
genera ni imprime código (comprobación vía `INFORMATION_SCHEMA`, mismo
patrón que `CamposPieTicketCajaDisponibles`).

### Composición del EAN-13

`29` (uso interno tienda) + contador `TK` de 10 dígitos + dígito de
control (`inLibEAN13.CalcularDigitoEAN13`). Mismo patrón que los códigos
de barras internos de artículo (`inLibArticulosCodigosBarras`: prefijo
`21` + contador `BA`). Los códigos de almacén son alfanuméricos
(`GEN`, `BCN`…), por eso NO se codifican dentro del número: el código se
guarda en la factura y el escaneo la localiza por el índice único.

---

## 2. Generación y guardado (grabación de la venta)

`UniDataCaja.pas` → `TGrabacionFacturaCaja`:

- `CrearFacturaSiProcede` llama a `GenerarCodigoBarrasTicket` justo
  después de `InsertarCabeceraFactura`: obtiene el contador `TK`
  (`ObtenerSiguienteContador`, crea la fila si faltara), compone
  `29 + contador(10) + DC` y hace `UPDATE fza_facturas SET
  CODIGO_BARRAS_FAC`. Dentro de la transacción de la venta.
- Todas las facturas de caja llevan código (venta, regalo y
  rectificativa); el modal de F4 rechaza rectificativas como origen.

## 3. Impresión ESC/POS (parámetro de caja)

- Parámetro nuevo en `inLibCajaParam` (sección **Impresión**):
  `vgerImprimirCodBarrasTicket` — «Imprimir código de barras EAN13 del
  ticket» (booleano, por defecto `False`). El inspector de
  `inMtoCajaParam` lo pinta solo.
- `inLibFTicket.TTicketTermico.ImprimirEAN13Nativo`: comandos
  `GS h` (altura), `GS w` (módulo), `GS H 2` (HRI debajo), `GS f`,
  `GS k m=67` con los 13 dígitos.
- `inLibGenerarTicket.ImprimirT` (ticket en vivo y ticket regalo) e
  `inLibGenerarTicketBD.ImprimirTicketDesdeBD` (reimpresión / PDF de
  respaldo) reciben el parámetro nuevo opcional
  `AImprimirCodigoBarras: Boolean = False`; lo pasa
  `TImpresorVentaVcl` leyendo `GetBool('vgerImprimirCodBarrasTicket')`.
  El código se pinta al final del ticket, tras el pie.
- `inMtoPreviewTicket` (visor/PDF): el parser ESC/POS ahora entiende
  `GS h/w/H/f/k` y **dibuja el EAN-13 real** (tablas L/G/R estándar),
  con el HRI debajo; los PDFs archivados lo llevan.
- `IRepositorioTicketsCaja.ObtenerCodigoBarrasTicket(serie, numero)`
  nuevo (con guardia de columna), para la reimpresión desde BD.

## 4. F4 — devolución por ticket

`inMtoCajaOpe`:

- `btnF61` (F4, etiqueta «Devolución») y `VK_F4` en `FormKeyDown` abren
  `TfrmModalDevolucionTicket` (modal nuevo) con tres vías:
  - **Escaneo/tecleo** del EAN-13 → `ConsultarFacturaPorCodigoBarras`.
  - **Empresa/Almacén/Caja/Nº operación** → `ConsultarFacturaPorOperacion`
    (índice `IDX_FACTURAS_OPERACION`).
  - **Serie/Nº documento** → `ConsultarCabeceraFactura`.
- Con el ticket localizado (guarda EMP/ALM/CAJA/OPERACIÓN de origen):
  - **Misma empresa** → `CargarRectificacion(trcDiferencias,
    tmrMantenerOriginales)`: los artículos se cargan en negativo y la
    operación queda como *factura rectificativa por diferencias*. El
    usuario borra las líneas que no se devuelvan.
  - **Otra empresa** → aviso y `CargarDevolucionOtraEmpresa`: mismas
    líneas en negativo pero SIN rectificativa fiscal (no se puede
    rectificar la factura de otra empresa); queda en modo **DV** con
    `SERIE/NUMERO_REF_ORIGEN_OPCAJA` apuntando al ticket original.
- Solo se permite con la operación vacía
  (`SErrorDevolucionTicketOperacionEnCurso`).

## 5. Devolución sin código (−1 manual)

- `tvUdsPropertiesValidate`: cantidad negativa en línea normal (no
  depósito) sin origen ya fijado → `PostMessage(WM_PREGUNTAR_VENTA_ORIGEN)`
  (diferido fuera del OnValidate, como el resto de mensajes WM_APP del
  formulario).
- `WMPreguntarVentaOrigen` abre `TfrmModalSeleccionVentaOrigen` (modal
  nuevo): ventas de los **últimos 12 meses, cualquier tienda de la
  empresa**, que contienen ese SKU (`ConsultarVentasOrigenSku`, LIMIT
  200, más recientes primero), con fecha/hora, serie\número, tienda,
  caja, uds y totales.
  - **Elegir venta** → misma lógica que F4 (rectificativa por
    diferencias si misma empresa; solo referencia si otra), pero sin
    recargar líneas: vale la línea en negativo ya tecleada.
  - **Cancelar** → devolución sin origen (modo **DV** puro).

## 6. Motivo de devolución (ambos flujos)

- Al pulsar **Cobro (F12)**, si hay líneas en negativo (excluidas
  cancelaciones de depósito) y aún no hay motivo, se abre
  `TfrmModalMotivoDevolucion` (combo editable: Talla incorrecta,
  Artículo defectuoso, No convence, Cambio por otro artículo, Otro, o
  texto libre; máx. 50). Cancelar aborta el cobro.
- El motivo viaja por `TSolicitudGrabacionVenta.MotivoDevolucion` hasta
  `MOTIVO_DEVOLUCION_OPCAJA` de la operación **DV**. La referencia del
  origen va en `SERIE/NUMERO_REF_ORIGEN_OPCAJA` (la rectificada si la
  hay; si no, el origen elegido).

## 7. Traspaso automático (devolución de otra tienda)

`TGrabacionFacturaCaja`, todo en la MISMA transacción de la venta:

- `ProcesarVenta`: si la línea es negativa, ESTANDAR, genera movimientos
  y el origen es de otra tienda, el movimiento `E` de la devolución se
  hace en el **almacén de ORIGEN** del ticket (y su empresa) en vez del
  actual, y la línea se apunta para el traspaso.
- `GenerarTraspasoAutomaticoDevolucion` (tras `RegistrarTotalesVenta`):
  - `TR` misma empresa / `TA` entre empresas (misma regla que
    `TdmTraspaso.GrabarTraspaso`).
  - Serie del documento por `fza_empresas_series` (espejo de
    `ObtenerSerieDocumento`), número por `PRC_GET_NEXT_CONT_FACT_SERIE`,
    operación por `PRC_GET_NEXT_OP_CAJA` del contexto de ORIGEN.
  - Por línea: par `S` (origen→actual) + `E` (actual←origen) vía
    `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`, a coste PMP del origen
    (espejo de `ObtenerCosteMedio`).
  - Operación `fza_caja_operaciones` registrada en el ORIGEN con
    `CODIGO_ALM_CONTRA` = almacén actual, `ESTRASPASO='S'`, concepto
    «Traspaso automático por devolución a {ALM}», y referencia al ticket
    devuelto.
- Resultado neto de stock: origen 0 (entra devolución, sale traspaso),
  tienda actual +N (donde está físicamente la prenda). Con rastro
  documental completo y acumulados de traspaso cuadrados.

---

## 8. Ficheros tocados

| Fichero | Cambio |
|---|---|
| `DESARROLLOS EN CURSO/codigo_barras_ticket.sql` | **nuevo** — DDL idempotente |
| `src/Lib/inLibFTicket.pas` | `ImprimirEAN13Nativo` |
| `src/Core/inMtoPreviewTicket.pas` | parser GS h/w/H/f/k + `DibujarEAN13` |
| `src/Caja/Lib/inLibCajaParam.pas` | parámetro `vgerImprimirCodBarrasTicket` |
| `src/Lib/inLibGenerarTicket.pas` | imprime EAN-13 (param. opcional) |
| `src/Lib/inLibGenerarTicketBD.pas` | ídem en reimpresión desde BD |
| `src/Caja/Lib/inLibTicketsCajaIntf.pas` | `ObtenerCodigoBarrasTicket` |
| `src/Caja/DataModules/UniDataTicketsCajaRepositorio.pas` | ídem (impl.) |
| `src/Caja/Forms/inMtoCajaImpresorVenta.pas` | pasa el parámetro |
| `src/Caja/DataModules/UniDataCaja.pas` | genera/guarda EAN-13; motivo y ref. en DV; entrada en origen + `GenerarTraspasoAutomaticoDevolucion` |
| `src/Caja/Lib/inLibCajaVentaIntf.pas` | solicitud (motivo/origen) + 3 consultas nuevas |
| `src/Caja/DataModules/UniDataCajaConsultasRepositorio.pas` | 3 consultas nuevas (catálogo SQL) |
| `src/Caja/Forms/inMtoCajaGrabadorVenta.pas` | pasa los campos nuevos |
| `src/Caja/Forms/inMtoCajaOpe.pas` + `.dfm` | F4, selector −1, motivo, estado devolución |
| `src/Caja/Modals/inMtoModalDevolucionTicket.pas/.dfm` | **nuevo** |
| `src/Caja/Modals/inMtoModalSeleccionVentaOrigen.pas/.dfm` | **nuevo** |
| `src/Caja/Modals/inMtoModalMotivoDevolucion.pas/.dfm` | **nuevo** |
| `src/Lib/inLibMsgCaja.pas` | mensajes R15 |
| `fzam.dpr` / `fzam.dproj` | alta de los 3 modales |
| `tests/PruebasCajaVenta.pas` | fake del repositorio ampliado |

## 9. Pruebas manuales sugeridas

1. Aplicar `codigo_barras_ticket.sql` (dos veces: debe ser inocuo).
2. Activar el parámetro en Parámetros de caja → Impresión y hacer una
   venta: el ticket (impreso y PDF de respaldo) lleva el EAN-13 y
   `fza_facturas.CODIGO_BARRAS_FAC` queda relleno (29…, 13 dígitos,
   DC válido).
3. F4 + escanear ese código: líneas en negativo, título RECTIFICATIVA
   POR DIFERENCIAS; borrar una línea, cobrar → pide motivo → DV con
   `MOTIVO_DEVOLUCION_OPCAJA` y `SERIE/NUMERO_REF_ORIGEN_OPCAJA`.
4. F4 por operación y por serie/número (las otras dos vías).
5. Devolución en tienda B de ticket de tienda A: comprobar en
   `fza_movimientos_almacen` la `E` en A + par `S`(A)/`E`(B) del
   traspaso, la operación TR con `ESTRASPASO='S'`, y stock neto A=0,
   B=+1.
6. Prenda en −1 sin código: sale el selector con ventas de 12 meses;
   elegir una y cancelar (ambos caminos).
7. Ticket regalo: también imprime el código de barras.
8. Con el `.sql` SIN aplicar: la venta no falla (no genera código).

## 10. Notas

- El traspaso automático usa la CAJA actual como caja de la operación
  del origen (no existe caja «remota» implicada).
- `PRC_GET_NEXT_CONT*` hacen COMMIT interno (patrón ya existente en la
  grabación de ventas); no se ha cambiado ese comportamiento.
- Pendiente valorar: imprimir el código también en reimpresiones desde
  los modales de histórico (hoy solo ticket en vivo, regalo y PDF de
  respaldo).
