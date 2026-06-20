# 05 · Menú Caja

[◀ Volver al índice](README.md)

El menú **Caja** es el **punto de venta (TPV)** para la venta al detalle en
tienda: cobrar a clientes de mostrador, emitir tickets/facturas
simplificadas, gestionar el efectivo de la caja y cuadrarla (arqueo).

Estructura del menú:

```
Caja
├── Menú de Caja
├── Parámetros de Caja
├── Formas de Pago Caja
├── Depósitos de Clientes
├── Histórico de Pagos de Caja
├── Histórico de Vales
├── Histórico de Operaciones
├── Histórico de Arqueos
└── Borradores Simplificados
```

---

## Menú de Caja

**Atajo de menú:** `[F5]`

Es la **pantalla principal del TPV**, diseñada para trabajar con **teclado**
y rapidez en el mostrador. Muestra la **Empresa**, la **caja activa**
(empresa/almacén/caja) y la **Fecha de Caja** de la jornada, junto con el
reloj.

![Menú de Caja](img/05-menu-caja.png)
*▢ Captura pendiente — Menú de Caja con las opciones y sus teclas rápidas.*

Funciones y sus teclas rápidas:

| Tecla | Función | Descripción |
|-------|---------|-------------|
| **F3** | **Traspasos** | Traspaso de **mercancía** entre almacenes/tiendas (ver detalle más abajo). |
| **F5** | **Ventas** | Pantalla de venta/cobro (ver detalle más abajo). |
| **F6** | **Entrada de Cambio** | Registra el efectivo inicial (cambio) que se mete en el cajón. |
| **F7** | **Gastos por caja** | Registra pagos/gastos en efectivo realizados desde la caja. |
| **F10** | **Buscar / Modificar** | Localiza operaciones de la caja para consultarlas o modificarlas (ver detalle más abajo). |
| **F11** | **Arqueo** | Cierre y cuadre de caja (ver detalle más abajo). |
| — | **Fecha de Caja** | Fija/cambia la fecha de trabajo de la jornada. |
| **Esc** | **Salir** | Cierra el TPV y vuelve a la ventana principal. |

> El TPV está pensado para que un dependiente pueda vender, cobrar y cerrar
> caja sin usar el resto de menús. Antes de operar debe haber una **caja
> seleccionada** (empresa + almacén + caja).

---

### Ventas (F5) — la pantalla de venta

Es la pantalla donde se hace el ticket. Arriba se indica el **Empleado**
(vendedor) y, opcionalmente, el **Cliente**; debajo, la rejilla de
**líneas de venta** y el **Total** en grande.

![Pantalla de Ventas del TPV](img/05-caja-ventas.png)
*▢ Captura pendiente — Operación de venta con líneas y total.*

**Cómo se añaden líneas:**

- Pasando el **lector de código de barras** por el artículo (la pantalla
  está optimizada para ráfagas de lector).
- Buscando el artículo manualmente con **Buscar (F3)**.

Cada línea muestra: **Vend.** (vendedor de la línea), **Artículo**,
**Descripción**, **Color/Talla** cuando procede, **Uds.**, **Precio**,
**%** (descuento), **Menos** (importe descontado) y **Total**. Si el
artículo tiene foto, se muestra en el panel lateral de stock/foto.

**Teclas rápidas de la pantalla de Ventas:**

| Tecla | Función | Descripción |
|-------|---------|-------------|
| **F12** | **Cobro** | Pasa a la **fase de cobro** del ticket (ver abajo). |
| **F3** | **Buscar** | Busca artículos para añadirlos sin lector. |
| **F4** | **Búsq Tick** | Busca un ticket anterior (p. ej. para una devolución). |
| **F5** | **Otro** | Cambia a **otra operación en paralelo**: se pueden mantener hasta **5 tickets abiertos a la vez** (clientes simultáneos). |
| **F6** | **Tarifa** | Cambia la tarifa de precios aplicada. |
| **F7** | **Ind. IVA** | Cambia el indicador de IVA de la operación. |
| **F8** | **Eliminar** | Elimina la línea seleccionada. |
| **F2** | **Cargar cta.** | Carga los **depósitos/a cuenta** del cliente para aplicarlos. |
| **Ctrl+U** | **Consulta stock** | Consulta el stock del artículo de la línea en foco. |
| **Ctrl+A** | **Artículos** | Abre la consulta de artículos. |
| **Esc** | **Salir** | Abandona la operación. |

---

### Fase de cobro (F12 desde Ventas)

Tras pulsar **Cobro (F12)** se entra en la **Fase de cobro**, donde se
liquida el ticket:

![Fase de cobro](img/05-caja-cobro.png)
*▢ Captura pendiente — Fase de cobro con formas de pago y cambio.*

**Zona de importes:**

- **Imp. TOTAL a pagar**, con posibilidad de aplicar un **% Descuento** o
  un **descuento lineal** al total.
- **Pendiente de cobro** — lo que falta por cubrir con formas de pago.
- **Importe a dejar A CUENTA** — parte que queda como depósito del cliente.
- **Vale Emitido / Vale Recogido** — vales generados (devoluciones) o
  canjeados en esta operación.
- **Devolución de cambio** — cambio a devolver al cliente.

**Rejilla de pagos:** se reparte el total entre una o varias **formas de
pago** (efectivo, tarjeta, vale…), indicando el **Importe Entregado** de
cada una. La aplicación calcula el cambio.

**Botones / teclas de la fase de cobro:**

| Tecla | Función | Descripción |
|-------|---------|-------------|
| **F12** | **Con ticket** | Cierra la venta **imprimiendo el ticket**. |
| **F11** | **Sin ticket** | Cierra la venta sin imprimir. |
| **F10** | **Sin precios** | Imprime el ticket **sin precios** (ticket regalo). |
| **F8** | **Factura** | Emite **factura nominativa** en lugar de ticket (pide los datos del cliente). |
| **F7** | **Préstamo** | Registra la salida como **préstamo/depósito** al cliente (si tiene crédito permitido). |
| **F6** | **Buscar Vale** | Localiza un **vale** emitido para canjearlo como pago. |
| **F3** | **Rellenar** | Rellena automáticamente el importe pendiente en la forma de pago seleccionada. |
| **F2** | **Más datos** | Datos adicionales de la operación. |
| **Esc** | **Atrás** | Vuelve a la pantalla de venta sin cerrar el cobro. |

> El **Nº de documento de venta** generado se muestra al cerrar. Las ventas
> de caja generan **borradores simplificados** que se consolidan según el
> modo fiscal configurado (consultables en
> [Borradores Simplificados](#borradores-simplificados)).

---

### Traspasos (F3)

Gestiona los **traspasos de mercancía entre almacenes** (entre tiendas, o
tienda ↔ almacén central). El stock sale del almacén origen y entra en el
destino.

![Traspasos entre almacenes](img/05-caja-traspasos.png)
*▢ Captura pendiente — Pantalla de Traspasos con origen, destino y líneas.*

| Elemento | Descripción |
|----------|-------------|
| **Almacén origen / Almacén destino** | De dónde sale y a dónde va la mercancía. |
| **Empleado (responsable)** | Quién realiza el traspaso. |
| **Líneas de artículos** | Se añaden con el lector o búsqueda, igual que en Ventas. |
| **Importe traspaso** | Valoración de la mercancía traspasada. |

**Modos de trabajo:**

- **F6 — Solicitar a otro almacén:** crea una **solicitud** de género a
  otra tienda/almacén (pendiente de que la atiendan).
- **F8 — Atender solicitudes:** muestra las solicitudes recibidas para
  **prepararlas y enviarlas**.

**Cierre:** **F12 Con ticket** (imprime justificante del traspaso) o
**F11 Sin ticket**.

---

### Entrada de Cambio (F6)

Registra el **efectivo de cambio** que se introduce en el cajón al empezar
la jornada (o un refuerzo de cambio a mitad de día). Este importe se tiene
en cuenta en el arqueo como entrada de efectivo.

![Entrada de cambio](img/05-caja-entrada-cambio.png)
*▢ Captura pendiente — Modal de Entrada de Cambio.*

---

### Gastos por caja (F7)

Registra **pagos en efectivo** hechos desde el cajón (mensajería, compras
menores…). Restan efectivo en el arqueo y quedan en el histórico de pagos.

![Gastos por caja](img/05-caja-gastos.png)
*▢ Captura pendiente — Modal de Gastos por caja.*

---

### Buscar / Modificar (F10)

Abre la pantalla **«Buscar operaciones»** para localizar cualquier
operación de la caja y revisarla o corregirla.

![Buscar operaciones](img/05-caja-buscar.png)
*▢ Captura pendiente — Buscar operaciones con el detalle de pagos.*

**Filtros:** **Fecha** de caja y campo **Buscar** (texto libre: cliente,
importe, nº de documento…).

**Rejilla de resultados:** Fecha/Hora, **Nº Operación**, **Tipos** (venta,
devolución, gasto, traspaso…), **Serie** y **Nº Factura**, **Cliente** y
Razón social, **Importe**, **Empleado** y **Conceptos**.

**Detalle de la operación seleccionada**, en dos pestañas:

- **Operación** — tipo, importe, concepto, id de depósito, documento de
  referencia (serie/nº), y en devoluciones el **motivo** y su estado.
- **Pagos** — desglose por forma de pago: línea, código, forma de pago,
  **Entregado**, **Cambio** y **Neto**.

> Requiere tener una **caja seleccionada** (empresa/almacén/caja); si no,
> la aplicación pide seleccionarla antes de buscar.

---

### Arqueo (F11)

El **arqueo** es el cierre y cuadre de la caja: calcula lo que **debería
haber** en el cajón y lo compara con lo que se cuenta físicamente.

![Arqueo de caja](img/05-caja-arqueo.png)
*▢ Captura pendiente — Arqueo de caja con el desglose en cascada.*

**Periodo:** se arquea entre **Fecha desde (F10)** y **Fecha hasta (F6)**
(normalmente la jornada en curso).

**El desglose en cascada** muestra cómo se llega al saldo:

```
Líneas artículos      + Bruto − Descuento                = Bruto
Operaciones           Ventas Normales + Ventas Préstamos
                      − Devoluciones                     = Total Ventas
Cobros                − Vales recogidos + Vales emitidos
                      + Cobros clientes − Pendiente cobro = Ingresos caja
Efectivo              + Efectivo entradas − Efectivo salidas
                      + Efectivo anterior                = Efectivo en caja
                      + Otros (tarjetas, bonos, divisa, cripto)
                                                         = Saldo a recontar
```

**Pestaña «Resúmenes»:** neto de ventas **por empleado** (unidades y neto)
y **por forma de pago** (unidades e importe) — útil para comisiones y para
cuadrar el datáfono.

**Botones:**

| Tecla | Función |
|-------|---------|
| **F5** | **Recalcular** el arqueo tras cambiar fechas. |
| **F11** | **Imprimir** el arqueo. |
| **F8** | **Histórico** de arqueos anteriores. |

> Haz el arqueo **al cierre de cada jornada**. El «Efectivo anterior» enlaza
> con el arqueo previo, de modo que los descuadres no se arrastran sin ser
> detectados.

Desde **Histórico (F8)** puedes reimprimir duplicados del ticket de arqueo
o del justificante de cierre ya grabado.

![Histórico de arqueos desde el TPV](img/05-caja-arqueo-historico-tpv.png)
*▢ Captura pendiente — Histórico de arqueos dentro del TPV con Duplicado ticket y Duplicado cierre.*

---

## Parámetros de Caja

**Atajo de menú:** `[Ctrl]+[F5]`

Configuración del comportamiento del TPV: caja por defecto, impresora de
tickets, formas de pago habilitadas, textos del ticket, redondeos, etc.
Normalmente lo configura el responsable al instalar la tienda.

![Parámetros de Caja](img/05-caja-parametros.png)
*▢ Captura pendiente — Parámetros de Caja.*

---

## Formas de Pago Caja

**Atajo de menú:** `[Shift]+[Ctrl]+[Q]`

Define las **formas de pago admitidas en el TPV** y cómo se comporta cada
una en el cobro y en el arqueo.

![Formas de Pago Caja](img/05-caja-formas-pago.png)
*▢ Captura pendiente — Mantenimiento de Formas de Pago Caja.*

Campos de cada forma de pago:

| Campo | Descripción |
|-------|-------------|
| **Código / Descripción / Activo** | Identificación de la forma de pago. |
| **Orden F12** | Posición en la pantalla de cobro (la primera es la que se propone al pulsar F12). |
| **Pide Referencia** | Al cobrar exige una referencia (nº de bono, autorización de tarjeta…). |
| **Devuelve Cambio** | Permite dar cambio (típico del efectivo; una tarjeta no lo permite). |
| **Abre Cajón** | Abre el cajón portamonedas al cobrar. |
| **% Comisión / Comisión Incl.** | Comisión de la forma de pago (p. ej. TPV bancario) y si está incluida. |
| **Divisa** | Es una moneda extranjera (USD, GBP…). |
| **Cripto / Red y Hash Blockchain** | Es una criptomoneda; registra la red y el hash de la transacción. |

> En el arqueo, las formas que no son efectivo se agrupan en
> **«Otros (tarjetas, bonos, divisa, cripto)»** para el recuento.

---

## Depósitos de Clientes

**Atajo de menú:** `[Ctrl]+[D]`

Gestiona los **depósitos/anticipos** de clientes: dinero entregado a cuenta
(señales, reservas) que luego se aplica a una venta (tecla **F2 Cargar
cta.** en el TPV). Lleva el saldo disponible por cliente.

![Depósitos de clientes](img/05-caja-depositos.png)
*▢ Captura pendiente — Depósitos de Clientes.*

---

## Histórico de Pagos de Caja

**Atajo de menú:** `[Shift]+[Ctrl]+[J]`

Consulta de todos los **cobros y pagos** registrados en la caja, con sus
formas de pago e importes. Permite filtrar por fechas y revisar el detalle
del efectivo movido.

![Histórico de pagos](img/05-caja-hist-pagos.png)
*▢ Captura pendiente — Histórico de Pagos de Caja.*

---

## Histórico de Vales

**Atajo de menú:** `[Shift]+[Ctrl]+[V]`

Consulta de los **vales** emitidos (por devoluciones de cliente sin
reembolso en efectivo) y su estado (pendiente, canjeado, caducado).

![Histórico de vales](img/05-caja-hist-vales.png)
*▢ Captura pendiente — Histórico de Vales.*

---

## Histórico de Operaciones

**Atajo de menú:** `[Shift]+[Ctrl]+[O]`

Consulta del **registro completo de operaciones** del TPV: ventas,
devoluciones, entradas de cambio, gastos, traspasos… con su trazabilidad.
Es la vista de auditoría de la actividad de caja.

![Histórico de operaciones](img/05-caja-hist-operaciones.png)
*▢ Captura pendiente — Histórico de Operaciones.*

---

## Histórico de Arqueos

**Atajo de menú:** `[Shift]+[Ctrl]+[A]`

Consulta de los **arqueos** (cierres de caja) realizados: efectivo contado,
descuadres, fecha, usuario. Permite revisar el cuadre de cada jornada.
También accesible desde el propio arqueo con **F8**.

![Histórico de arqueos](img/05-caja-hist-arqueos.png)
*▢ Captura pendiente — Histórico de Arqueos.*

Incluye el botón **Imprimir Informe A4**, que genera un informe horizontal
por empresa, almacén, caja y rango de fechas. El formato se puede editar y
guardar desde el diseñador de informes.

![Informe A4 de histórico de arqueos](img/05-caja-hist-arqueos-informe.png)
*▢ Captura pendiente — Filtro del informe A4 de arqueos con rango de fechas.*

---

## Borradores Simplificados

**Atajo de menú:** `[Shift]+[Ctrl]+[F]`

Mantenimiento de los **Borradores Simplificados (tickets)** generados en
caja. Permite consultarlos, reimprimirlos y, cuando proceda, **convertir un
ticket en borrador normal** a nombre del cliente. Como el resto de
documentos de venta, se consolidan según el modo fiscal configurado.

![Borradores simplificados](img/05-caja-borradores-simplificados.png)
*▢ Captura pendiente — Mantenimiento de Borradores Simplificados.*

---

[◀ Menú Ventas Mayor](04-menu-ventas-mayor.md) · [Índice](README.md) · [Siguiente ▶ Menú Almacén](06-menu-almacen.md)
