# Menú de Caja (TPV)

Mapa de los formularios, data modules y librerías que componen el módulo de caja
de Factuzam. Pensado como punto de entrada para quien tenga que tocar algo:
qué unidad abre qué pantalla, dónde vive cada parte del flujo (ventas, búsqueda
y modificación, fase de cobro, persistencia de la factura) y a qué tablas /
parámetros se está atacando en cada paso.

Las rutas son relativas a la raíz del repo (`/`).

---

## 1. Punto de entrada — abrir el menú de caja

El menú de caja se invoca desde la ventana principal:

- `src/Core/inMtoPrincipal.pas:861` — `TfrmMtoPrincipal.mnuMenuCajaClick`
  - Crea/levanta `frmMtoMenuCaja` y minimiza la ventana principal.
- Declarado en el proyecto: `fzam.dpr:86` (`inMtoCajaMenu`).

Una vez abierto el menú, todos los flujos siguientes salen de `frmMtoMenuCaja`.

---

## 2. Mapa de archivos

| Archivo (`.pas` + `.dfm`) | Clase | Función |
|---|---|---|
| `src/Caja/Forms/inMtoCajaMenu` | `TfrmMtoMenuCaja` | Menú principal del TPV (F5/F10/F3/F6/F7/F11/ESC) y calendario de ventas. |
| `src/Modals/inMtoModalCajDef` | `TfrmMtoModalCajDef` | Modal de selección de Empresa/Almacén/Caja al entrar. |
| `src/Caja/Forms/inMtoCajaOpe` | `TfrmMtoOpeCaja` | Operativa de venta: líneas, atributos, búsqueda de artículos, depósitos. |
| `src/Caja/Forms/inMtoCajaFaseCobro` | `TfrmMtoCajaFaseCobro` | Fase de cobro: formas de pago, vales, descuentos, dejar a cuenta. |
| `src/Caja/Forms/inMtoCajaReferenciaPago` | `TfrmCajaReferenciaPago` | Referencia/divisa/cripto para pagos no efectivo. |
| `src/Caja/Forms/inMtoCajaSeleccionVale` | `TfrmMtoCajaSeleccionVale` | Buscar y aplicar un vale pendiente en la fase de cobro. |
| `src/Forms/inMtoConsultaOpe` | `TfrmConsultaOpe` | **Buscar / Modificar** (F10): maestro-detalle de operaciones del día. |
| `src/Caja/Forms/inMtoCajaOperacionesHist` | `TfrmMtoCajaOperacionesHist` | Mantenimiento histórico de `fza_caja_operaciones` (vista admin). |
| `src/Caja/Forms/inMtoCajaPagosHist` | `TfrmMtoCajaPagosHist` | Mantenimiento histórico de `fza_caja_pagos`. |
| `src/Caja/Forms/inMtoCajaValesHist` | `TfrmMtoCajaValesHist` | Mantenimiento histórico de `fza_caja_vales`. |
| `src/Caja/DataModules/UniDataCaja` | `TdmCajaOpe` | Data module de la operativa (cdsCabecera, cdsLineas, grabar factura). |
| `src/Caja/DataModules/UniDataCajaOperacionesHist` | `TdmCajaOperacionesHist` | Data module del mantenimiento histórico de operaciones. |
| `src/Caja/DataModules/UniDataCajaPagosHist` | `TdmCajaPagosHist` | Data module del mantenimiento histórico de pagos. |
| `src/Caja/DataModules/UniDataCajaValesHist` | `TdmCajaValesHist` | Data module del mantenimiento histórico de vales. |
| `src/Caja/Lib/inLibCajaParam` | `TCajaParams` (`oCajaParams`) | Parámetros de comportamiento del TPV (vger*). |
| `src/Lib/inLibVentasCalendario` | `TVentasCalendarioCache` | Caché de días con ventas para pintar el calendario. |
| `src/Caja/Lib/inLibFaseCobro` | `TDatosFaseCobro` y records | Lógica de totales/validación de la fase de cobro. |
| `src/Lib/inLibFacturas` | `TFacturaTotales`, `TLinFac` | Cálculo de IVA / totales sobre cabecera y líneas. |

---

## 3. `inMtoCajaMenu` — menú principal (TPV)

Archivo: `src/Caja/Forms/inMtoCajaMenu.pas` (`src/Caja/Forms/inMtoCajaMenu.dfm`).

Pantalla con 6 opciones + ESC, todas accesibles por teclado (F-keys) y con
navegación arriba/abajo (flechas) + Enter. El estado actual está siempre en
`FSelectedIndex`.

### 3.1 Inicialización

`FormCreate` (`inMtoCajaMenu.pas:218`):
1. Crea la caché de calendario (`FVentasCal := TVentasCalendarioCache.Create`).
2. Si `oCajaParams.GetBool('vgerShowCajaSelection', True)` → abre
   `AbrirSelectorCaja` (modal de selección Empresa/Almacén/Caja). En caso
   contrario toma `oEmpresa/oAlmacen/oCaja` de `inLibGlobalVar`.
3. Pinta la cabecera "Empresa X - Almacén Y - Caja Z" en `lblEmpresa`.
4. Cachea los colores originales de cada etiqueta para los hover.
5. `InitMenuItems` rellena el array `FMenuItems` con los 7 elementos del menú.

### 3.2 Selector inicial de caja

`AbrirSelectorCaja` (`inMtoCajaMenu.pas:344`):
- Abre `TfrmMtoModalCajDef` (`src/Modals/inMtoModalCajDef.pas`).
- El modal lleva la `qrySeleccion` con la lista de Empresa/Almacén/Caja
  disponibles. Al aceptar pone `sFicha='S'` y devuelve los códigos.
- Si el usuario cancela, el menú se cierra (`PostMessage(WM_CLOSE)`).
- También se invoca por doble-clic en `lblEmpresa` (`lblEmpresaDblClick`).

### 3.3 Opciones del menú (teclas)

| Tecla | Etiqueta | Handler en `.pas` | Acción |
|---|---|---|---|
| F5  | Ventas              | `lblVentasClick:547`          | Crea `TfrmMtoOpeCaja`, asigna `Tag := 1` y llama `PrepararValores`. |
| F10 | Buscar / Modificar  | `lblBuscarModificarClick:592` → `AbrirBuscarModificar:323` | Abre `TfrmConsultaOpe`. |
| F6  | Entrada de Cambio   | `lblEntradaCambioClick:633`   | **TODO sin implementar.** |
| F7  | Gastos por Caja     | `lblGastosCajaClick:661`      | **TODO sin implementar.** |
| F11 | Arqueo              | `lblArqueoClick:700`          | Abre `TfrmModalArqueo.Ejecutar` (rango de fechas; solo lectura). |
| F3  | Traspasos           | `lblTraspasosClick:728`       | **TODO sin implementar.** |
| ESC | Salir               | `lblESCClick:767`             | `Close`. |

`FormShortCut` (`inMtoCajaMenu.pas:295`) intercepta ↑/↓/Enter antes que el
calendario para que la navegación por teclado siga funcionando con el foco en
él. La misma protección está duplicada en `JvMonthCalendar1KeyDown:409`.

### 3.4 Calendario de ventas

- Componente: `JvMonthCalendar1`.
- Días con ventas pintados en negrita por
  `JvMonthCalendar1GetMonthBoldInfo:385` → delega en
  `FVentasCal.MaskBoldDelMes`.
- Click simple actualiza `FFechaCaja` (`JvMonthCalendar1Click:391`).
- `cxButton1Click:435` ("Hoy") devuelve la fecha al día actual.
- Cuando cambia la caja, `RecargarCalendario:378` invalida el caché y repinta.

### 3.5 Cierre seguro

`FormCloseQuery` (`inMtoCajaMenu.pas:197`) recorre `Screen.Forms` y, por cada
`TfrmMtoOpeCaja` abierto, llama `IntentarCerrar`. Si una operación tiene líneas
pendientes y el usuario contesta NO, el menú no se cierra.

`FormClose` (`inMtoCajaMenu.pas:188`) restaura el formulario principal al
estado maximizado al salir.

---

## 4. `inMtoCajaOpe` — operativa de venta (F5)

Archivo: `src/Caja/Forms/inMtoCajaOpe.pas` (~2 680 líneas, el más grande del módulo).
Es donde se construye el ticket línea a línea. Tiene su propio data module:
`DatosCaja: TdmCajaOpe` creado en `FormCreate:2527`.

### 4.1 Estructura de datos (en memoria, antes de grabar)

Vienen de `UniDataCaja`:
- `DatosCaja.cdsCabecera` — `TClientDataSet` con los campos de `fza_facturas`
  (TIPO_FAC = `SIMPLIFICADA`, tarifa, cliente, vendedor, totales de IVA…).
- `DatosCaja.cdsLineas` — `TClientDataSet` con campos de `fza_factura_lineas`
  + extras de UI:
  - `CODIGO_ART_FACLIN`, `CODIGO_UNIDAD_FACLIN` (SKU).
  - `ATTR1_VALOR..ATTR5_VALOR` y `ATTR1_NOMBRE..ATTR5_NOMBRE` (columnas
    dinámicas de atributos).
  - `VIENE_DE_DEPOSITO` (`S` = prenda en depósito, `A` = abono, `''` = venta).
  - `ACCION_DEPOSITO` (`COBRAR`, `CANCELAR`, `NUEVO_DEP`, `AUMENTAR_DEP`).
- `DatosCaja.qryStock` y `DatosCaja.qryDefinicionArticulo` para los lookups.

### 4.2 Reentrada y reset al abrir/cambiar de operación

`PrepararValores` (`inMtoCajaOpe.pas:272`) es la única forma correcta de
recargar el formulario:
1. Guarda el empleado anterior.
2. Cancela ediciones en curso y vacía `cdsLineas` (`CancelUpdates + EmptyDataSet`).
3. Vacía y recrea la cabecera; aplica tarifa por defecto
   (`vgerDefTarifa`, def. `PVP`) y, si corresponde, empleado por defecto
   (`vgerFillEmpleadoDefecto` + `vgerCodEmpleadoDefecto`).
4. Pone "VENTA CONTADO" como cliente por defecto y resetea totales.

Se llama:
- Al abrir desde F5 (`inMtoCajaMenu.lblVentasClick:547`).
- Tras grabar una factura (`btnF12Click:2360`) para empezar la siguiente venta.
- Al saltar a otra operación con F5 dentro de caja (`btnF5Click:2435`).

### 4.3 Entrada de líneas

#### 4.3.1 Búsqueda / scanner

- Hook de lector a nivel de formulario (`KeyPreview` heredado de `TfrmBase`),
  venga de donde venga el foco. DOS detectores que confluyen en
  `WM_PROCESAR_SCANNER` → `ProcesarLecturaScanner` (resuelve SOLO contra códigos
  de barras vía `TArticulosValidador.ResolverCodigoBarras` y da de alta la línea
  automáticamente; única precondición: vendedor `CODIGO_CAJERO_FAC` dado de alta):
  1. **Trama STX/ETX**: `FormKeyPress` acumula entre `STX(#2)` y `ETX(#3)`
     consumiendo las teclas.
  2. **Por velocidad de tecleo (código de barras + CR, sin STX/ETX)**:
     `FormKeyPress` acumula la ráfaga (el buffer solo crece con caracteres
     rápidos y consecutivos; cualquier carácter lento lo reinicia) y `FormKeyDown`
     cierra en `VK_RETURN` si fue ráfaga + Enter rápido (se adelanta al editor del
     grid y a `jvEnterTab`). Parámetros: `vgerScanVelActivo` (bool, def. True),
     `vgerScanVelMs` (def. 40 ms entre teclas) y `vgerScanMinLong` (def. 4).
- `tvArticuloPropertiesChange:559` lanza el temporizador `tmrBusq` (debounce).
- `tmrBusqTimer:481` rellena `qryBusq` con `INPUT_BUSQUEDA LIKE %token%` y
  despliega el combo de búsqueda inline.
- `BuscarArticulo:592` lanza el diálogo completo (vía
  `TBusquedaUtils.EjecutarBusqueda`) con la SP `PRC_BUSQUEDA_ARTICULOS` y
  parametros: tarifa actual, almacén, fecha, solo-stock
  (`vgerBusqArtStockOnly`), solo-tarifa (`vgerBusqArtTarifaOnly`).

#### 4.3.2 Resolución del artículo

`tvArticuloPropertiesValidate:627` y `RellenarDatosArticuloEnDataset:812`
- Usan `TArticulosValidador` y `TArticulosResolver` (en `src/Lib/...`) para:
  - Validar que el código existe.
  - Rellenar descripción, tipo IVA, % dto, precio.
  - Detectar si el padre requiere SKU (talla/color) y cuántos atributos
    (`NUM_ATRIBUTOS_REQ_FACTURA_LINEA`).
- Si la línea ya está en el ticket: `ConsolidarSiExiste:1002` suma cantidades
  en lugar de duplicar (excepto en líneas de depósito).

#### 4.3.3 Atributos dinámicos (talla/color/...)

- `ConstruirColumnasDinamicas:1047` crea hasta 5 columnas `tvAtributoDynN` con
  `Tag = 1..5`, ligadas a `ATTRn_VALOR`.
- `ActualizarColumnasDinamicas:1770` consulta `vi_atributos_nombres` por
  el artículo padre y muestra/oculta columnas con sus etiquetas.
- `cxGrid1DBTableView1InitEdit:1403` rellena los combos con los valores
  posibles (`fza_atributos_valores` ⨝ `fza_atributos_sku`).
- `OnAtributoChanged:1082` reconstruye el SKU final
  (`DatosCaja.GenerarSkuFinal`) y, cuando los separadores `/` coinciden con
  `NUM_ATRIBUTOS_REQ_FACTURA_LINEA`, recalcula el precio.

#### 4.3.4 Cálculo de la línea

Los handlers `tvUds…/tvDescuento…/tvPrecioUni…/tvTotalPropertiesEditValueChanged`
llaman a `GridRecalc` (definido en `inLibtb`) pasando los dos cdsCalc + el
callback `ActualizarLabelTotal`. Antes de recalcular ponen a 0 los precios
finales (`PRECIO_VENTA_CIVA_/SIVA_ARTICULO_FACLIN`) para que el motor respete
descuentos editados a mano.

### 4.4 Cliente y empleado

- Empleado: `btnCodigoEmpleadoPropertiesValidate:2100` busca primero por
  `DatosCaja.BuscarYMostrarNombre('EMPLEADOS', ...)`, y si no, por
  `fza_usuarios` filtrando `CODIGO_EMPLEADO_USU` o `DIMINUTIVO_TICKET_USU`.
- Cliente: `btnCodigoClientePropertiesValidate:1875` lee `fza_clientes` y, si
  `ESPERMITE_DEUDA_CLI = 'S'` y `vgerAutoLoadDepositos`, carga los depósitos
  pendientes del cliente con `DatosCaja.CargarDepositosCliente`.
- Antes de cambiar de cliente se borran las líneas marcadas como depósito
  (`VIENE_DE_DEPOSITO in 'S','A'`) del cliente anterior.

### 4.5 Depósitos

- Las líneas con `VIENE_DE_DEPOSITO = 'S'` (prenda apartada) sólo permiten
  editar la cantidad y únicamente cambiando el signo (cancelación).
- Las líneas con `VIENE_DE_DEPOSITO = 'A'` (abono / anticipo) son
  completamente de solo lectura.
- F2 (`btnF2Click:2430` → `CargarDepositosF2:2370`) recarga los depósitos del
  cliente seleccionado.
- `tvUdsPropertiesValidate:758` aplica la regla: si la cantidad pasa a
  negativa, marca `ACCION_DEPOSITO := 'CANCELAR'` y pone los precios a 0.

### 4.6 Multi-operación (F5 dentro de caja)

`btnF5Click:2435`:
- Cada operación abierta tiene un `Tag` (1..`MAX_OPERACIONES = 5`).
- F5 oculta la operación actual y muestra la siguiente (o la crea si no
  existe). Por eso la caja puede aparcar hasta 5 tickets simultáneos.
- `IntentarCerrar:2633` se llama desde `frmMtoMenuCaja.FormCloseQuery`
  para no perder operaciones pendientes.

### 4.7 Atajos del formulario de venta

| Botón | Tecla | Acción |
|---|---|---|
| `btnF2`  | F2  | Cargar depósitos del cliente (`CargarDepositosF2`). |
| `btnF3`  | F3  | Eliminar línea (`actEliminarLineaExecute:1693`). |
| `btnF5`  | F5  | Aparcar y abrir siguiente operación (`btnF5Click`). |
| `btnF6`  | F6  | Buscar (artículos/empleados/clientes según foco), ver `actBuscarEmpleadosExecute:1559`. |
| `btnF7`  | F7  | Cargar a cuenta del cliente (`actCargarCtaExecute`). |
| `btnF8`  | F8  | Cancelar/eliminar línea (paralelo al F3). |
| `btnF12` | F12 | **Pasar a fase de cobro** (`btnF12Click:2276`). |
| `actAbrirArticulos` | — | Abre el mantenimiento de artículos sobre la línea actual. |
| `actGuardarLayout` | — | `GuardarLayoutCaja` (geometría + grid). |

`FormShow:2563` llama a `RestaurarLayoutCaja` (`TLayoutLoader`).

---

## 5. `inMtoCajaFaseCobro` — fase de cobro

Archivo: `src/Caja/Forms/inMtoCajaFaseCobro.pas`.

Se invoca desde `inMtoCajaOpe.btnF12Click:2276`. Recibe:
- `TFacturaTotales` con cabecera + líneas y totales ya calculados.
- `FHayLineasDeposito`, `FCodigoEmpresa/Almacen/Caja/Cliente`, `FFecha`.

### 5.1 Estado interno

- `FDatosCobro: TDatosFaseCobro` (definido en `src/Caja/Lib/inLibFaseCobro.pas`)
  contiene la lógica pura: importes pendientes, vale recogido/emitido,
  dejar a cuenta, devolución económica, etc.
- `FMemTablePagos: TVirtualTable` es la rejilla de formas de pago. Cada fila
  representa una forma activa (`fza_caja_formas_pago`) con `IMPORTE_ENTREGADO`
  y campos extra (`REFERENCIA`, `FACTOR_CAMBIO`, `IMPORTE_DIVISA`…).

### 5.2 Apertura

`FormShow:896` carga los datos del cliente (deuda + límite de crédito),
`CargarComboSeries:186` (de `vi_empresas_series` filtrado por
`TIPO_DOC_EMPSER='FC'` y `SUBTIPO_EMPSER='SIMPLIFICADA'`) y `CargarFormasPago`.
`ActualizarInterfaz:710` decide qué se habilita según haya o no devolución,
crédito permitido, depósitos, etc.

### 5.3 Formas de pago

- `dbmImportePropertiesEditValueChanged:444` recoge el importe escrito por el
  cajero y llama a `EscribirImporteEnFormaActual:527`.
- Si la forma `RequiereReferencia`, `EsDivisa` o `EsCripto`, se abre
  `TfrmCajaReferenciaPago` (en `inMtoCajaReferenciaPago.pas`). Si el usuario
  cancela esa ventana, se revierte el importe a 0.
- `AjustarFormatoEditorActivo:473` cambia decimales/formato del editor según
  divisa (`'#,##0.######'` para cripto, `',0.00'` para divisa, `',0.00 €'`
  para euros).

### 5.4 Vales

- F6 (`actBuscarValeExecute` / `btnBuscarValeClick:864`) abre
  `TfrmMtoCajaSeleccionVale.Ejecutar` (`inMtoCajaSeleccionVale.pas:120`),
  que devuelve `TValeSeleccionado` (código, PIN, importe, descripción).
- `FDatosCobro.RegistrarValeRecogido` aplica el vale.
- Si el vale supera el pendiente, automáticamente se llama `EmitirVale(Exceso)`
  para generar un vale de cambio.
- Modo devolución (`EsDevolucionEconomica`): `txtValeEmitido` pasa a editable
  y el botón "Buscar vale" se deshabilita.

### 5.5 Atajos

| Botón | Tecla | Acción |
|---|---|---|
| `btnF12` | F12 | Cobrar con ticket (`actConTicketExecute`). |
| `btnF11` | F11 | Cobrar sin ticket (`actSinTicketExecute`). |
| `btnF10` | F10 | Ticket regalo / sin precios (`actSinPreciosExecute`). |
| `btnF7`  | F7  | Dejar a cuenta del cliente (crédito) — `btnF7Click:819`. |
| `btnF6`  | F6  | Buscar vale. |
| `btnF3`  | F3  | Rellenar pendiente en la forma actual. |
| `btnF2`  | F2  | "Más datos". |
| `btnESC` | ESC | Volver al ticket (`btnAtrasClick`). |

`ValidarYConfirmar:265` cierra cualquier edición en curso del grid, hace
`Post` en `FMemTablePagos`, recalcula y valida con
`FDatosCobro.ValidarParaCobro` antes de devolver `mrOk`.

### 5.6 Resultado

Al volver con `mrOk`, `inMtoCajaOpe.btnF12Click` lee:
- `frmFaseCobro.DatosCobro` → forma de pago, importes, descuento global,
  importe a dejar a cuenta, vale recogido/emitido…
- `frmFaseCobro.TipoImpresion` (`tiConTicket`, `tiSinTicket`, `tiTicketRegalo`).
- `frmFaseCobro.cbbSerie1.Text` (serie elegida).

Si `ImporteDescuentoGlobal > 0`, se reparte línea a línea por
`RepartirDescuentoGlobalLinea:2160` antes de grabar.

---

## 6. Persistencia — `UniDataCaja.TdmCajaOpe`

Archivo: `src/Caja/DataModules/UniDataCaja.pas` (~2 650 líneas).

### 6.1 Estructura

- `cdsCabecera` / `cdsLineas` configurados por
  `ConfigurarEstructuraCabecera:2089` y `ConfigurarEstructuraLineas:2195`.
- Eventos:
  - `cdsLineasAfterInsert:2020` aplica valores por defecto.
  - `cdsLineasBeforePost:2073` valida la línea antes de persistirla en memoria.
  - `cdsLineasAfterPost:2064` y `cdsLineasAfterDelete:2008` recalculan totales.

### 6.2 Grabación de la factura — `GrabarFacturaSimplificada:1158`

Función llamada desde `inMtoCajaOpe.btnF12Click:2331`. Hace todo dentro de una
única transacción (`inLibGlobalVar.oConn.StartTransaction`):

1. **Filtro de "novedad"**: si no hay nada que cambiar (`ImporteEntregado=0`
   y no hay cancelaciones ni nuevos depósitos), sale sin tocar BD.
2. **Decide si requiere factura** (`RequiereFactura`). Hay flujos que sólo
   tocan depósitos (sin importe) y no generan ticket.
3. Llama a `SiguienteOpCaja:1794` para obtener `NUMERO_OPERACION_OPCAJA`.
4. Si requiere factura:
   - Pide número con la SP `PRC_GET_NEXT_CONT_FACT_SERIE`.
   - `InsertarCabeceraFactura:2324` → `fza_facturas`.
   - Por cada línea `InsertarLineaFactura:2534` → `fza_factura_lineas` +
     `InsertarMovimientoAlmacen:890` → `fza_movimientos_almacen`.
5. **Depósitos**:
   - `CrearNuevoDepositoCliente:1056` para `NUEVO_DEP`.
   - `AumentarAnticipoDeposito:948` para `AUMENTAR_DEP`.
   - `CerrarDepositoCliente:650` / `AnularDepositoCliente:970` para
     `COBRAR` / `CANCELAR`.
6. **Pagos**: por cada forma con importe distinto de 0,
   `InsertarPagoCaja:1719` → `fza_caja_pagos` (campos `CODIGO_FP_CFP`,
   `IMPORTE_ENTREGADO`, `IMPORTE_CAMBIO`, `REFERENCIA`, `FACTOR_CAMBIO`,
   `IMPORTE_DIVISA`, `RED_BLOCKCHAIN`).
7. **Operación de caja**: `InsertarOperacionCaja:1832` →
   `fza_caja_operaciones` con `TIPO_OPERACION_OPCAJA` en
   {`VE`, `VL`, `AL`, `CB`, `EC`, `GC`, `TR`, `AT`}.
8. **Vales**:
   - Si el cobro emitió un vale: `EmitirNuevoVale:1659` → fila en
     `fza_caja_vales` con estado `PENDIENTE`. Devuelve el código por
     `ValeGenerado`.
   - Si el cobro recogió uno: `MarcarValeComoCanjeado:2275` lo pasa a
     `CANJEADO`.
9. `Commit`. Cualquier excepción dispara `Rollback`.

Salidas:
- `NumeroGenerado` (string) — número de operación de caja.
- `ValeGenerado` (string) — código de vale emitido, vacío si no hay.

### 6.3 Funciones de apoyo

- `GenerarSkuFinal:1965`: concatena los atributos seleccionados con `/` sobre
  el código padre.
- `BuscarYMostrarNombre:1922`: lookup genérico (Empleados, Clientes,…).
- `GetTarifaDefault:1984`: tarifa por defecto vigente.
- `TransformarLineasParaCobroParcial:676`: si el cliente entrega menos del
  total, asigna desde el primer artículo el dinero y si se completa (el dinero es más que el precio de la prenda, lo vende, dejando el resto como anticipo del que no llegue al precio de la linea.
- `CuadrarFacturaEnMemoria:1639`: recalcula bases/IVAs antes de grabar.

---

## 7. `inMtoConsultaOpe` — Buscar / Modificar (F10)

Archivo: `src/Forms/inMtoConsultaOpe.pas`.

Se abre desde `inMtoCajaMenu.AbrirBuscarModificar:323`. Recibe Empresa/Almacén/
Caja/Fecha vía `PrepararValores:173`.

### 7.1 Layout

- `pnlFiltros` arriba: fecha (`dtpFecha` con `OnGetDayState` enchufado al
  caché de calendario) + cuadro de búsqueda (`edtBuscar`, con debounce
  `tmrBusqueda` de 400 ms).
- `pnlMaestro`: rejilla principal (`cxViewMaestro`) sobre
  `fza_caja_operaciones` del día.
- `pcHijos`: `TcxPageControl` con pestañas detalle:
  - `tsOperacion`  → datos de la operación.
  - `tsPagos`      → `fza_caja_pagos`.
  - `tsVales`      → vales emitidos / recogidos en la operación.
  - `tsMovimientos`→ `fza_movimientos_almacen`.
  - `tsCliente`    → ficha cliente (si la hay).
  - `tsDepositos`  → `fza_depositos_clientes`.
  - `tsFactura`    → cabecera + líneas (`cxGridFacCab` y `cxGridFacLin`).

### 7.2 Lógica

- `FdmConsulta: TdmConsultaOpe` (en `src/DataModules/UniDataConsultaOpe.pas`)
  expone las consultas y los datasources (uno por pestaña).
- `RecargarMaestro:252` → `FdmConsulta.CargarMaestro(fecha, empresa, almacen,
  caja, token)`.
- `OnMaestroDataChange:266` (con `Field=nil`, es decir, cambio de fila) llama
  a `FdmConsulta.RefrescarPestanasHijas` y `AjustarVisibilidadPestanas`.
- `AjustarVisibilidadPestanas:276` enciende/apaga pestañas según haya datos
  (`TienePagos`, `TieneVales`, etc.).

### 7.3 Reimprimir (`btnReimprimir` y `btnReimprimirOtros`)

Ambos botones reutilizan `ReimprimirOperacion`:
- `btnReimprimir` usa la impresora de tickets configurada en parámetros.
- `btnReimprimirOtros` abre la previsualización, que permite seleccionar otra
  impresora.
- Si hay factura → `ImprimirTicketDesdeBD(...)` (de
  `inLibGenerarTicketBD`).
- Si hay depósito → `ImprimirResguardoDeposito(...)`.
- Si hay cliente → `ImprimirRecordatorio(...)`.

### 7.4 Atajos / layout

- `FormKeyDown:196`: F5 recarga, ESC cierra, Alt+F12 guarda layout
  (`GuardarLayout`).
- `RestaurarLayout:206` y `GuardarLayout:228` usan `TLayoutLoader/Saver` de
  `inLibLayoutForm` con claves
  `Maestro`, `Operacion`, `Pagos`, `Vales`, `Movimientos`, `Cliente`,
  `Depositos`, `FacturaCab`, `FacturaLin`.

### 7.5 Mantenimiento histórico (administración)

Aparte del buscar-modificar de caja, hay tres mantenimientos clásicos
(`TfrmMtoGen`) dedicados a admin:
- `inMtoCajaOperacionesHist` → tabla `fza_caja_operaciones`.
- `inMtoCajaPagosHist` → tabla `fza_caja_pagos`.
- `inMtoCajaValesHist` → tabla `fza_caja_vales`.

Suelen colgar del menú de mantenimientos, no del menú de caja del TPV.

---

## 8. Parámetros de comportamiento (`oCajaParams`)

Definidos y leídos en `src/Caja/Lib/inLibCajaParam.pas`. Se cargan al iniciar la
aplicación. Usar siempre los getters: `GetBool`, `GetString`, `GetInt`.

| Clave | Default | Dónde se lee | Efecto |
|---|---|---|---|
| `vgerShowCajaSelection` | True | `inMtoCajaMenu.pas:235, 629` | Forzar selector de caja al entrar. |
| `vgerDefTarifa` | `PVP` | `inMtoCajaOpe.pas:339` | Tarifa por defecto en cabecera. |
| `vgerFillEmpleadoDefecto` | False | `inMtoCajaOpe.pas:350` | Auto-asignar empleado por defecto. |
| `vgerCodEmpleadoDefecto` | `''` | `inMtoCajaOpe.pas:352` | Código del empleado por defecto. |
| `vgerShowEmpleadoLinea` | True | `inMtoCajaOpe.pas:2536` | Mostrar columna empleado en líneas. |
| `vgerDescuentos` | True | `inMtoCajaOpe.pas:2537`, `inMtoCajaFaseCobro.pas:768` | Habilitar columnas/edits de descuento. |
| `vgerMoverLineaIdentif` | True | `inMtoCajaOpe.pas:1236, 1254, 1353, 1639` | Tras identificar el artículo, saltar a línea nueva. |
| `vgerBusqArtStockOnly` | False | `inMtoCajaOpe.pas:613` | Búsqueda de artículos: sólo con stock. |
| `vgerBusqArtTarifaOnly` | False | `inMtoCajaOpe.pas:615` | Búsqueda de artículos: sólo en la tarifa actual. |
| `vgerAutoLoadDepositos` | False | `inMtoCajaOpe.pas:1968` | Cargar automáticamente depósitos al elegir cliente. |
| `vgerVentasCredito` | True | `inMtoCajaFaseCobro.pas:734` | Permitir dejar a cuenta. |
| `vgerRecuperaValePIN` | False | `inMtoCajaSeleccionVale.pas:190, 332` | Pedir PIN al canjear vale. |
| `vgerCaducidadDefVale` | False | `inMtoCajaSeleccionVale.pas:217` | Filtrar vales caducados al buscar. |

Para añadir un parámetro nuevo: registrarlo en `TCajaParams.RegistrarDefectos`
e `InicializarParametrosCaja` (`inLibCajaParam.pas:120, 177`).

---

## 9. Diagrama rápido del flujo principal

```
inMtoPrincipal.mnuMenuCajaClick
   └── inMtoCajaMenu (TfrmMtoMenuCaja)
         ├── inMtoModalCajDef  (selección Empresa/Almacén/Caja)
         ├── F5 ──> inMtoCajaOpe (TfrmMtoOpeCaja)  [hasta 5 en paralelo]
         │             ├── DatosCaja: TdmCajaOpe (UniDataCaja)
         │             │     - cdsCabecera, cdsLineas
         │             │     - GrabarFacturaSimplificada
         │             ├── F2  CargarDepositosCliente
         │             ├── F6  BuscarArticulo / Empleado / Cliente
         │             └── F12 ──> inMtoCajaFaseCobro
         │                          ├── TDatosFaseCobro (inLibFaseCobro)
         │                          ├── F6 ──> inMtoCajaSeleccionVale
         │                          ├── tarjeta/cripto ──> inMtoCajaReferenciaPago
         │                          └── F12 OK ──> DatosCaja.GrabarFacturaSimplificada
         │                                          └── transacción única →
         │                                              fza_facturas
         │                                              fza_factura_lineas
         │                                              fza_caja_operaciones
         │                                              fza_caja_pagos
         │                                              fza_caja_vales
         │                                              fza_movimientos_almacen
         │                                              fza_depositos_clientes
         └── F10 ──> inMtoConsultaOpe (TfrmConsultaOpe)
                       └── TdmConsultaOpe (UniDataConsultaOpe)
                             ├── maestro: fza_caja_operaciones
                             └── pestañas: operación / pagos / vales /
                                 movimientos / cliente / depósitos / factura
```

---

## 10. Cosas pendientes / TODO en el código

Si vas a tocar el menú de caja, ten a mano que estos están explícitamente
marcados como TODO en `inMtoCajaMenu.pas` y siguen sin implementar:

- F6 — Entrada de Cambio (`lblEntradaCambioClick:633`).
- F7 — Gastos por Caja (`lblGastosCajaClick:661`).
- F3 — Traspasos (`lblTraspasosClick:728`).

F11 Arqueo ya está enganchado a `TfrmModalArqueo.Ejecutar`
(`src/Caja/Modals/inMtoModalArqueo.pas`, librería de cálculo
`src/Caja/Lib/inLibArqueo.pas`). En su primer paso muestra los totales del rango
seleccionado en modo solo lectura, sin recuento manual ni cierre Z; el
desglose por forma de pago se devuelve en `TArqueoCaja.PagosPorForma` pero
no se persiste todavía (tabla hija pendiente para el cierre Z futuro).

El resto del esqueleto (hover/colores/atajos) ya está cableado, sólo falta
encajar el formulario destino dentro de cada handler.
