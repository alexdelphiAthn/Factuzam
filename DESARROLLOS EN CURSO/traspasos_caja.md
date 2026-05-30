# Traspasos en Caja (TPV)

Diseño de la opción **F3 – Traspasos** del menú de caja
(`inMtoCajaMenu.pas:746`, hoy `// TODO`). Documenta las tres pantallas
del subsistema, su disposición, los flujos y cómo encajan en el modelo de
datos **que ya existe**. El traspaso ejecutado usa sólo
`fza_caja_operaciones` + `fza_movimientos_almacen`; las **solicitudes**
pendientes requieren **una tabla nueva con estados** (§7).

> Estado: **propuesta de diseño**. El **traspaso/atención** se graba sólo con
> `fza_caja_operaciones` (operación) + `fza_movimientos_almacen` (par S+E),
> sin tablas nuevas. Las **solicitudes** (peticiones pendientes) llevan
> **tabla nueva con estados** (`fza_traspasos_solicitudes` + líneas, §7); su
> `.sql` idempotente se entrega aparte.

---

## 1. Qué se quiere

Tres operativas, todas con almacén **origen** y **destino**, donde el
movimiento de stock real son **dos apuntes en pareja** (salida en origen +
entrada en destino) ya soportados por `fza_movimientos_almacen`:

| # | Pantalla / modo                         | Quién soy   | Origen        | Destino       | ¿Mueve stock al grabar? |
|---|-----------------------------------------|-------------|---------------|---------------|--------------------------|
| 1 | **Traspaso** (saliente)                 | el que envía| **propio**    | otro ESTANDAR | Sí (S origen + E destino)|
| 2 | **Solicitar** traspaso a otro almacén   | el que pide | otro almacén  | **propio**    | No: crea solicitud pendiente|
| 3 | **Atender** solicitudes de otros        | el que sirve| **propio**    | el solicitante| Sí, al cumplir la solicitud|

Reglas de negocio (del encargo):

- En el **traspaso** el origen es **siempre el almacén propio** de la caja;
  el destino se elige **sólo entre almacenes `TIPO_USO_ALM = 'ESTANDAR'`**.
- **Puede invertirse el orden** (origen ↔ destino) cuando *recibo* mercancía
  de otro almacén (cuando hay tránsito): en **Solicitar** y al recibir, el
  propio pasa a ser **destino**.
- Si no hay inversión, el traspaso **siempre** genera **salida del origen y
  entrada en el destino**.
- **Tránsito opcional**: por defecto el traspaso es directo origen→destino
  (2 movimientos). Si el destino es un almacén `TIPO_USO_ALM = 'TRÁNSITO'`
  (una furgoneta), se "carga" la furgoneta y la descarga se hace después al
  recibir (§8).

---

## 2. Punto de entrada y navegación

`F3` en el menú de caja (`TfrmMtoMenuCaja.lblTraspasosClick`) abre la
**operativa de traspaso** `TfrmMtoOpeTraspaso` directamente en modo
**Traspaso** (saliente), igual que `F5` abre `TfrmMtoOpeCaja`.

Las tres operativas son **el mismo formulario en tres modos**
(`TModoTraspaso = (mtTraspaso, mtSolicitar, mtAtender)`), seleccionables con
una barra superior de tres botones/solapas. Esto refleja "dos pantallas más
añadidas" sin triplicar código y reutiliza el grid de líneas:

```
inMtoCajaMenu  ──F3──>  inMtoTraspasoOpe (TfrmMtoOpeTraspaso)
                          ├─ modo Traspaso   (origen propio  → destino ESTANDAR)
                          ├─ modo Solicitar  (origen otro     → destino propio)
                          └─ modo Atender    (lista de solicitudes pendientes
                                              dirigidas a mi almacén)
```

> Alternativa válida: que `F3` abra un mini-selector (3 opciones tipo menú)
> y cada una lance el formulario ya en su modo. Se prefiere la barra de
> modos porque es un único `ShowModal`/MDI y conserva el ticket en curso.

---

## 3. Disposición de la pantalla (modo Traspaso)

Lo pedido: **origen y destino arriba**, **grid de líneas como
`inMtoCajaOpe`** debajo, y **F12 con ticket / F11 sin ticket** abajo.

```
┌─ TRASPASOS ──────────────────────────────────────────────────────────────┐
│ [ Traspaso ] [ Solicitar a otro almacén ] [ Atender solicitudes (3) ]     │ ← barra de modos
├───────────────────────────────────────────────────────────────────────────┤
│ ALMACÉN ORIGEN : [ GEN · Almacén Central        ▼]  (propio — bloqueado)   │
│ ALMACÉN DESTINO: [ BCN · Almacén Barcelona       ▼]  (sólo ESTANDAR)       │
├───────────────────────────────────────────────────────────────────────────┤
│ Artículo            │ Color  │ Talla │  Uds │  Coste │   Total │ Stock org │
│ ZAP-OXFORD Oxford…  │ NEGRO  │  42   │   3  │  40,00 │  120,00 │    10     │
│ [ escanea o teclea código… ]                                              │ ← fila de alta
│                                                                           │
│                                                                           │
├───────────────────────────────────────────────────────────────────────────┤
│   Líneas: 1        Total unidades: 3        Importe traspaso: 120,00 €     │
├───────────────────────────────────────────────────────────────────────────┤
│  F3 Eliminar   F6 Buscar   │   F11 Sin ticket   F12 Con ticket   │   ESC   │
└───────────────────────────────────────────────────────────────────────────┘
```

- **ALMACÉN ORIGEN**: `TcxLookupComboBox`/`TcxBarEditItem` precargado con el
  almacén de la caja (`FAlmacen`) y **bloqueado** en modo Traspaso (regla
  "origen siempre el propio").
- **ALMACÉN DESTINO**: lookup contra `fza_almacenes` filtrando
  `ESACTIVO_ALM='S'`, `CODIGO_EMP_ALM = empresa`, `TIPO_USO_ALM='ESTANDAR'`
  y excluyendo el propio. (En modo tránsito, §8, se permiten además los
  `TIPO_USO_ALM='TRÁNSITO'`.)
- **Cabecera de totales**: nº de líneas, total de unidades e **importe de
  traspaso** (Σ coste · uds), como en el ticket histórico "ALBARÁN DE
  TRASPASO" (`src/otras pruebas/arqueos/ticket traspaso.txt`).

En **modo Solicitar** se intercambian las etiquetas (ORIGEN = lookup de otro
almacén, DESTINO = propio bloqueado) y el botón pasa a *Enviar solicitud*.
En **modo Atender** aparece primero la lista de solicitudes pendientes (§6).

---

## 4. El grid de líneas (reutiliza el de `inMtoCajaOpe`)

Se reutiliza el patrón de `TfrmMtoOpeCaja` / `TdmCajaOpe`
(`src/Forms/inMtoCajaOpe.pas`, `src/DataModules/UniDataCaja.pas`), descrito
en `menu_caja.md` §4.3, **quitando lo de venta** (tarifa, descuento, precio
de venta, depósitos) y dejando lo de stock:

| Elemento reutilizado de caja            | En traspaso                                  |
|-----------------------------------------|----------------------------------------------|
| `txtEntradaArticulo` + escáner STX/ETX  | Igual: alta de línea por escáner o tecleo     |
| `tmrBusq` + `qryBusq` (búsqueda inline) | Igual                                        |
| `BuscarArticulo` (`PRC_BUSQUEDA_ARTICULOS`) | Igual, **filtrando por stock en el origen** |
| Columnas dinámicas de atributos `ATTR1..5` | Igual (talla/color para resolver el SKU)   |
| `GenerarSkuFinal` (concatena atributos) | Igual                                        |
| `ConsolidarSiExiste` (suma cantidades)  | Igual                                        |
| Columna **Uds** (`CANTIDAD`)            | Igual                                         |
| Columna Precio venta / Descuento        | **Se sustituye** por **Coste** (PMP), de sólo lectura |
| Total línea                             | Coste · Uds (informativo, no se cobra)        |
| Columna extra **Stock origen**          | `fza_articulos_stockactual.CANTIDAD_STK` del SKU en el origen, sólo lectura |

Estructura en memoria (data module `TdmTraspaso`, espejo reducido de
`TdmCajaOpe`):

- `cdsCabecera`: `CODIGO_EMP`, `CODIGO_ALM_ORIGEN`, `CODIGO_ALM_DESTINO`,
  `CODIGO_CAJA`, `FECHA`, `MODO`, totales.
- `cdsLineas`: `CODIGO_ART`, `CODIGO_UNIDAD` (SKU), `DESCRIPCION`,
  `ATTR1..5_VALOR/NOMBRE`, `CANTIDAD`, `PRECIO_COSTE` (PMP capturado),
  `STOCK_ORIGEN`.

Validaciones de línea (`cdsLineasBeforePost`):

1. El SKU existe y es de tipo físico (`TIPO_ART='ESTANDAR'`; servicios/kits
   no se traspasan).
2. `CANTIDAD > 0`.
3. **Stock suficiente en el origen**: `CANTIDAD <= CANTIDAD_STK` del SKU en
   `CODIGO_ALM_ORIGEN` (avisar/bloquear según parámetro, ver §10).

---

## 5. Modo Traspaso (saliente) — grabación

Botonera (igual semántica que la fase de cobro de caja, `menu_caja.md` §5.5):

| Tecla | Acción                                                        |
|-------|---------------------------------------------------------------|
| F12   | **Grabar con ticket**: ejecuta el traspaso e imprime albarán   |
| F11   | **Grabar sin ticket**: ejecuta el traspaso, sin impresión      |
| F3    | Eliminar línea                                                |
| F6    | Buscar artículo                                               |
| ESC   | Salir (con confirmación si hay líneas pendientes)              |

Al grabar, **todo en una transacción** (espejo de
`TdmCajaOpe.GrabarFacturaSimplificada`, `UniDataCaja.pas:1158`):

1. `SiguienteOpCaja` (`UniDataCaja.pas:1794`) → `NUMERO_OPERACION_OPCAJA`.
2. Por cada línea, **dos** llamadas a `InsertarMovimientoAlmacen`
   (`UniDataCaja.pas:890`, que invoca `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` y
   mantiene solos los acumulados):

   | Apunte  | `TIPO_DOC_MOV` | `TIPO_MOV` | `CODIGO_ALM_MOV` | `CODIGO_ALM_CONTRA_MOV` |
   |---------|----------------|------------|------------------|--------------------------|
   | Salida  | `TR` (¹)       | `S`        | origen           | destino                  |
   | Entrada | `TR` (¹)       | `E`        | destino          | origen                   |

   - `PRECIO_COSTE_UNITARIO_MOV` / `PRECIO_MEDIO_MOV` = `PRECIO_MEDIO_STK`
     del SKU en el **origen** (mueve a coste, no revaloriza).
   - Ambos apuntes comparten `NUMERO_OPERACION_DOC_MOV`, `CODIGO_ALM_DOC_MOV`
     y `CODIGO_CAJA_DOC_MOV` (la operación que los causó).
   - (¹) `TR` = "TRASPASOS ALMACÉN" (mismo `CODIGO_EMP`); **`AT`** =
     "TRASPASOS EMPRESA" cuando el destino pertenece a otra empresa
     (`fza_tipos_documentos`). El código elige `TR`/`AT` comparando empresas.

3. `InsertarOperacionCaja` (`UniDataCaja.pas:1832`) →
   `fza_caja_operaciones` con:
   - `TIPO_OPERACION_OPCAJA = 'TR'` (o `'AT'`), `ESTRASPASO_OPCAJA = 'S'`.
   - `CODIGO_ALM_OPCAJA` = origen propio, `CODIGO_ALM_CONTRA_OPCAJA` = destino,
     `CODIGO_EMP_CONTRA_OPCAJA` si es entre empresas.
   - `IMPORTE_TOTAL_OPCAJA` = importe de traspaso (Σ coste·uds, informativo).
   - `CONCEPTO_GASTO_INGRESO_OPCAJA` = "Traspaso a {NOMBRE_ALM destino}".
4. `Commit` (o `Rollback` ante cualquier excepción).

Los acumulados `CANTIDAD_ENT_TRASPASO_STK` / `CANTIDAD_SAL_TRASPASO_STK` los
mantiene `PRC_FZA_AJUSTAR_ACUMULADO_STK` (ya contempla `TR`/`AT`,
`stocks_sps_movimientos.sql:40-43`). **No hay que tocar SQL** para esto.

### 5.1 Editar / anular un traspaso ya grabado — Buscar/Modificar (F10)

Un traspaso queda como una **operación `TR`/`AT`** del día, así que aparece
en **Buscar/Modificar** (`F10`, `inMtoConsultaOpe`/`TfrmConsultaOpe`,
`menu_caja.md` §7) como una operación más; su par de apuntes S+E se ve en la
pestaña **Movimientos**. Desde ahí se **edita** el traspaso:

- **Reabrir en la operativa**: doble clic / "Modificar" carga la operación en
  `TfrmMtoOpeTraspaso` en modo edición (origen, destino y líneas
  precargados); al regrabar **revierte y regenera** los movimientos.
- **Coherencia de stock**: usa los SPs que **ya existen**
  (`stocks_sps_movimientos.sql`): `PRC_FZA_MOVIMIENTOS_ALMACEN_UPDATE` (cambiar
  cantidad de un apunte), `..._DELETE` (un apunte) y `..._DELETE_DOC` (todos
  los de la operación), que ajustan stock y acumulados solos. Editar la
  pareja = editar **los dos** apuntes (S en origen y E en destino).
- **Anular**: borra/repone ambos apuntes; si el traspaso atendía una
  solicitud, su `ESTADO_TRSOL` vuelve a `PENDIENTE`/`PARCIAL`.
- **Permiso** `traspaso.editar`; conviene limitarlo a operaciones no incluidas
  en un arqueo/cierre Z (`CODIGO_ARQUEO_OPCAJA IS NULL`).

---

## 6. Modo Atender solicitudes

Cuando otro almacén me ha **solicitado** mercancía, aparezco como **origen**.
La pantalla abre con una **lista de solicitudes pendientes** (cabeceras de
`fza_traspasos_solicitudes` con `ESTADO_TRSOL IN ('PENDIENTE','PARCIAL')` y
`CODIGO_ALM_ORIGEN_TRSOL` = mi almacén; un `TfrmMtoGen` ligero,
`inMtoTraspasoSolicitudes`):

```
┌─ ATENDER SOLICITUDES (origen = GEN) ─────────────────────────────┐
│ Solicitud │ Fecha      │ Solicita (destino) │ Líneas │ Estado     │
│ 2026/TS/14│ 2026-05-30 │ BCN Barcelona      │   4    │ PENDIENTE  │
│ 2026/TS/15│ 2026-05-30 │ ALE Villaralbo     │   2    │ PARCIAL    │
└──────────────────────────────────────────────────────────────────┘
```

Al elegir una, sus líneas se cargan en el **mismo grid** (origen=propio,
destino=el solicitante, ambos bloqueados) y se cumple **total o
parcialmente** ajustando `Uds`. `F12`/`F11` ejecutan el traspaso igual que
§5 y además:

- Enlazan la operación de atención con la solicitud por
  `SERIE_REF_ORIGEN_OPCAJA = SERIE_TRSOL` /
  `NUMERO_REF_ORIGEN_OPCAJA = NUMERO_TRSOL`.
- Actualizan `CANTIDAD_SERVIDA_TRSOLLIN` por línea y `ESTADO_TRSOL` de la
  cabecera a `PARCIAL` o `ATENDIDA` según cubran o no todas las unidades.

---

## 7. Modo Solicitar y ciclo de vida (tabla nueva de solicitudes)

Reparto de persistencia:

- El **traspaso ejecutado** (§5) y la **atención** (§6) se graban **sólo** en
  `fza_caja_operaciones` (operación `TR`/`AT`) + `fza_movimientos_almacen`
  (par S+E). **Sin tablas nuevas.**
- La **solicitud pendiente** (petición que aún no mueve stock) vive en una
  **tabla nueva con estados**: necesita cabecera, líneas y estado propios
  antes de que exista ningún movimiento.

**Solicitar** (yo, almacén A, pido a B) **no mueve stock**: crea una solicitud
`PENDIENTE`. Al `ATENDER` (§6), B genera el traspaso real (operación +
movimientos) y la solicitud pasa a `PARCIAL`/`ATENDIDA`. Ciclo:
`PENDIENTE → PARCIAL → ATENDIDA`, con `RECHAZADA` / `CANCELADA` como salidas.

### 7.1 Tablas nuevas (diseño; el `.sql` idempotente va aparte)

Siguiendo `LIBRO_DE_ESTILO_BBDD.md`. Sufijos nuevos a registrar en el catálogo
§2 del libro y en `UNormalizerEngine.pas` (`InitDefaults`): `TRSOL`
(cabecera) y `TRSOLLIN` (líneas).

`fza_traspasos_solicitudes` — cabecera (`TRSOL`):

| Columna | Tipo | Notas |
|---|---|---|
| `NUMERO_TRSOL` | varchar(20) | PK (con serie) |
| `SERIE_TRSOL` | varchar(20) | PK |
| `FECHA_TRSOL` | date | fecha de la solicitud |
| `ESTADO_TRSOL` | varchar(20) | `PENDIENTE`/`PARCIAL`/`ATENDIDA`/`RECHAZADA`/`CANCELADA` |
| `CODIGO_EMP_TRSOL` | varchar(20) | empresa solicitante |
| `CODIGO_ALM_ORIGEN_TRSOL` | varchar(10) | a quién se pide (origen del futuro traspaso) |
| `CODIGO_ALM_DESTINO_TRSOL` | varchar(10) | quién pide = almacén propio (destino) |
| `CODIGO_EMP_CONTRA_TRSOL` | varchar(20) | empresa del origen si difiere |
| `CODIGO_CAJA_TRSOL` | varchar(10) | caja que originó la solicitud |
| `OBSERVACIONES_TRSOL` | varchar(1000) | texto libre |
| auditoría | | `INSTANTE_ALTA/MODIF`, `USUARIO_ALTA/MODIF` |

`fza_traspasos_solicitudes_lineas` — líneas (`TRSOLLIN`):

| Columna | Tipo | Notas |
|---|---|---|
| `NUMERO_TRSOL_TRSOLLIN` / `SERIE_TRSOL_TRSOLLIN` | varchar(20) | FK a cabecera |
| `LINEA_TRSOLLIN` | varchar(4) | nº de línea |
| `CODIGO_ART_TRSOLLIN` | varchar(20) | artículo padre |
| `CODIGO_UNIDAD_TRSOLLIN` | varchar(50) | SKU |
| `DESCRIPCION_ARTICULO_TRSOLLIN` | varchar(100) | descripción capturada |
| `CANTIDAD_PEDIDA_TRSOLLIN` | decimal(19,6) | uds solicitadas |
| `CANTIDAD_SERVIDA_TRSOLLIN` | decimal(19,6) | uds ya atendidas (para `PARCIAL`) |
| `ESATENDIDA_TRSOLLIN` | varchar(1) | `S`/`N` |
| auditoría | | |

Índices: `IDX_TRSOL_ESTADO` (`ESTADO_TRSOL`) e `IDX_TRSOL_ORIGEN`
(`CODIGO_ALM_ORIGEN_TRSOL`, `ESTADO_TRSOL`) para que **Atender** liste rápido
las pendientes que me tocan.

### 7.2 Enlace solicitud ↔ traspaso ejecutado

La operación de atención (`fza_caja_operaciones`) referencia la solicitud por
`SERIE_REF_ORIGEN_OPCAJA = SERIE_TRSOL` / `NUMERO_REF_ORIGEN_OPCAJA =
NUMERO_TRSOL`. Al cubrir todas las líneas (`CANTIDAD_SERVIDA = CANTIDAD_PEDIDA`)
la cabecera pasa a `ATENDIDA`; si queda algo, `PARCIAL`.

---

## 8. Tránsito (opcional)

Modelo de furgoneta usando `TIPO_USO_ALM='TRÁNSITO'` y los campos ya
existentes `ORIGEN_ACTUAL_ALM` / `DESTINO_ACTUAL_ALM` de `fza_almacenes`
(ej. `DESTBCN` = "Furgoneta → BCN" en el dump):

1. **Cargar**: traspaso directo (§5) con **destino = almacén TRÁNSITO**. Se
   fija `ORIGEN_ACTUAL_ALM = origen` y `DESTINO_ACTUAL_ALM = destino final`
   en la furgoneta.
2. **Descargar / recibir**: en el almacén final se hace un segundo traspaso
   con **origen = la furgoneta** y **destino = el almacén final** (aquí es
   donde "se invierte el orden": el propio pasa a destino). Se limpian
   `ORIGEN_ACTUAL_ALM`/`DESTINO_ACTUAL_ALM`.

Cada tramo es un par S+E normal, así que **no hay lógica de stock nueva**:
sólo el relleno de los dos campos de la furgoneta. Queda fuera del MVP del
traspaso directo; se documenta para no cerrar la puerta.

---

## 9. Procedimiento almacenado unificador (opcional)

Como pediste, "quizás algún procedimiento almacenado si se desea unificar".
La grabación de §5 puede vivir en Delphi (transacción, como
`GrabarFacturaSimplificada`) **o** unificarse en un SP reutilizable por el
traspaso directo y por atender:

```
PRC_FZA_TRASPASO_EJECUTAR(
    IN p_EMP, p_ALM_ORIGEN, p_ALM_DESTINO, p_CAJA, p_USUARIO,
    IN p_NUM_OPERACION,                  -- de SiguienteOpCaja
    IN p_LINEAS  (SKU, cantidad, coste), -- tabla temporal o JSON
    IN p_NUM_SOLICITUD (NULL si directo) -- para enlazar y marcar estado
)
```

Responsabilidad: por línea, llamar a `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`
dos veces (S+E), insertar la `fza_caja_operaciones` `TR`/`AT`, y si viene
`p_NUM_SOLICITUD` actualizar `CANTIDAD_SERVIDA_TRSOLLIN` / `ESTADO_TRSOL` y
enlazar por `REF_ORIGEN`. Ventaja: una sola
verdad transaccional. **No es imprescindible**; el equivalente en Delphi es
igual de válido y reutiliza `InsertarMovimientoAlmacen`/`InsertarOperacionCaja`.

---

## 10. Parámetros, permisos e impresión

- **Parámetros** (`oCajaParams`, `inLibCajaParam.pas`), nuevos `vger*`:
  - `vgerTraspasoStockNegativo` (def. `False`): permitir traspasar más de lo
    que hay en origen (sólo aviso vs bloqueo).
  - `vgerTraspasoDestinoSoloEstandar` (def. `True`): si `False`, el destino
    admite también TRÁNSITO/otros.
  - `vgerTraspasoTicketDefecto` (def. `True`): F12/F11 por defecto.
- **Permisos** (`oPermisos`, patrón de `inMtoModalArqueo`): `traspaso.crear`,
  `traspaso.solicitar`, `traspaso.atender`, `traspaso.destinoOtraEmpresa`.
- **Impresión** (F12): reutilizar `inLibGenerarTicketBD` con un formato
  "ALBARÁN DE TRASPASO" (cabecera origen/destino + líneas SKU/uds + importe),
  según el modelo de `ticket traspaso.txt`.

---

## 11. Archivos a crear / tocar

| Archivo                                   | Qué                                            |
|-------------------------------------------|------------------------------------------------|
| `src/Forms/inMtoCajaMenu.pas:746`         | Implementar `lblTraspasosClick` → abre operativa|
| `src/Forms/inMtoTraspasoOpe.pas/.dfm`     | **Nuevo** `TfrmMtoOpeTraspaso` (3 modos), hereda `TfrmBase` |
| `src/DataModules/UniDataTraspaso.pas`     | **Nuevo** `TdmTraspaso` (cdsCabecera/cdsLineas, grabar) |
| `src/Forms/inMtoConsultaOpe.pas`          | **Tocar**: editar/anular la operación `TR`/`AT` desde Buscar/Modificar F10 (§5.1) |
| `src/Forms/inMtoTraspasoSolicitudes.pas`  | **Nuevo** `TfrmMtoTraspasoSolicitudes` (lista sobre `fza_traspasos_solicitudes`), hereda `TfrmMtoGen` |
| `src/Lib/inLibCajaParam.pas`              | Registrar parámetros `vgerTraspaso*`            |
| `fzam.dpr`                                | Alta de las units nuevas                        |
| `DESARROLLOS EN CURSO/traspasos_caja.sql` | **Nuevo** (idempotente): `fza_traspasos_solicitudes` + `…_lineas` (§7) |

Reutiliza directamente, sin tocar: `InsertarMovimientoAlmacen`,
`InsertarOperacionCaja`, `SiguienteOpCaja` (`UniDataCaja.pas`),
`PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` y `PRC_FZA_AJUSTAR_ACUMULADO_STK`.

---

## 12. Decisiones abiertas

1. **Persistencia**: **cerrado** — el traspaso/atención usa sólo
   `fza_caja_operaciones` + `fza_movimientos_almacen`; las **solicitudes** van
   en **tabla nueva** `fza_traspasos_solicitudes` (+ líneas) con estados (§7).
2. **Un formulario con 3 modos vs 3 formularios** (§2). Recomendado 1 con modos.
3. **Tránsito** (§8): ¿entra en esta entrega o se pospone? Recomendado posponer.
4. **SP unificador** (§9): ¿se hace en SP o en transacción Delphi? Indiferente
   funcionalmente.
