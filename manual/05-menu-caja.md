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
└── Facturas Simplificadas
```

---

## Menú de Caja

Es la **pantalla principal del TPV**, diseñada para trabajar con **teclado**
y rapidez en el mostrador. Antes de operar pide la **Empresa** y la **Fecha
de Caja** de la jornada.

Funciones principales (con sus teclas rápidas):

| Tecla | Función | Descripción |
|-------|---------|-------------|
| — | **Ventas** | Pantalla de cobro: se añaden artículos (por código de barras o búsqueda), se aplican formas de pago y se cierra el ticket. |
| **F3** | **Fecha de Caja** | Fija/cambia la fecha de trabajo de la caja. |
| **F5 / F10** | **Buscar / Modificar** | Localiza y modifica operaciones de la sesión de caja. |
| **F6** | **Traspasos** | Movimientos de efectivo entre cajas o a/desde banco. |
| **F7** | **Entrada de Cambio** | Registra el efectivo inicial (cambio) que se mete en la caja. |
| — | **Gastos por caja** | Registra pagos/gastos en efectivo realizados desde la caja. |
| **F11** | **Arqueo** | Cierra y **cuadra la caja**: cuenta el efectivo y compara con lo que debería haber. |
| **Esc** | **Salir** | Cierra el TPV y vuelve a la ventana principal. |

> El TPV está pensado para que un dependiente pueda vender, cobrar y cerrar
> caja sin usar el resto de menús. Las ventas de caja generan **facturas
> simplificadas** (tickets) y, opcionalmente, factura ordinaria si el
> cliente la solicita.

---

## Parámetros de Caja

Configuración del comportamiento del TPV: caja por defecto, impresora de
tickets, formas de pago habilitadas, textos del ticket, redondeos, etc.
Normalmente lo configura el responsable al instalar la tienda.

---

## Formas de Pago Caja

Define las **formas de pago admitidas en el TPV** (efectivo, tarjeta, vale,
mixto…) y cómo afecta cada una al arqueo de efectivo.

---

## Depósitos de Clientes

Gestiona los **depósitos/anticipos** de clientes: dinero entregado a cuenta
(señales, reservas) que luego se aplica a una venta. Lleva el saldo
disponible por cliente.

---

## Histórico de Pagos de Caja

Consulta de todos los **cobros y pagos** registrados en la caja, con sus
formas de pago e importes. Permite filtrar por fechas y revisar el detalle
del efectivo movido.

---

## Histórico de Vales

Consulta de los **vales** emitidos (por devoluciones de cliente sin
reembolso en efectivo) y su estado (pendiente, canjeado, caducado).

---

## Histórico de Operaciones

Consulta del **registro completo de operaciones** del TPV: ventas,
devoluciones, entradas de cambio, gastos, traspasos… con su trazabilidad.
Es la vista de auditoría de la actividad de caja.

---

## Histórico de Arqueos

Consulta de los **arqueos** (cierres de caja) realizados: efectivo contado,
descuadres, fecha, usuario. Permite revisar el cuadre de cada jornada.

---

## Facturas Simplificadas

Mantenimiento de las **Facturas Simplificadas (tickets)** generadas en
caja. Permite consultarlas, reimprimirlas y, cuando proceda, **convertir un
ticket en factura ordinaria** a nombre del cliente. Como el resto de
documentos de venta, se comunican a **Verifactu**.

---

[◀ Menú Ventas Mayor](04-menu-ventas-mayor.md) · [Índice](README.md) · [Siguiente ▶ Menú Almacén](06-menu-almacen.md)
