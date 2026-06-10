# 03 · Menú Compras

[◀ Volver al índice](README.md)

El menú **Compras** gestiona todo el ciclo de **aprovisionamiento**: desde
el pedido al proveedor hasta la recepción de mercancía, las devoluciones y
las facturas de compra. Es el flujo que **da entrada de stock** al almacén.

Estructura del menú:

```
Compras
├── Sesiones
│   └── Crear artículos y un pedido o un albarán
├── Pedidos
├── Albaranes
├── Devoluciones a Proveedor
├── Facturas
└── Formas de pago
```

> Flujo habitual de compra:
> **Pedido de compra** → recepción como **Albarán de compra** (entra el
> stock) → **Factura de compra**. Las **Devoluciones** restan stock y
> generan el abono al proveedor.

---

## Sesiones ▸ Crear artículos y un pedido o un albarán

Asistente de **alta rápida de compra**. Pensado para cuando llega mercancía
nueva y hay que dar de alta artículos y registrar el documento de compra en
un solo paso.

Sub-pestañas:

- **Líneas de Artículos** — vas introduciendo las líneas (artículo,
  cantidades, tallas, precio de compra). Si el artículo no existe, se puede
  **crear sobre la marcha**.
- **Documentos creados** — al materializar la sesión, aquí aparecen los
  documentos generados (el **pedido** o el **albarán** de compra, y los
  artículos/SKUs creados).

Es la vía más ágil para cargar una entrada de género completa sin tener que
ir pantalla por pantalla.

---

## Pedidos

Mantenimiento de **Pedidos de Compra**. Registra lo que se ha **encargado**
a un proveedor (todavía no ha llegado, no mueve stock).

Un pedido tiene una **cabecera** (proveedor, fecha, almacén de destino,
forma de pago) y un **detalle de líneas** (artículo/SKU, cantidades por
talla, precio). Desde el pedido se puede generar el **albarán de compra**
cuando llega la mercancía.

---

## Albaranes

Mantenimiento de **Albaranes de Compra**. Registra la **recepción real** de
la mercancía: al confirmar el albarán **entra el stock** en el almacén
indicado.

Puede crearse:

- A partir de un **pedido** previo (recepción de lo pedido).
- Directamente (compra sin pedido previo).

El albarán es el documento que **mueve existencias**; la factura es solo el
documento contable/fiscal asociado.

---

## Devoluciones a Proveedor

Mantenimiento de **Devoluciones a Proveedor**. Registra la mercancía que se
**devuelve** al proveedor (defectos, exceso, etc.). Al confirmarla, **resta
stock** del almacén y sirve de base para el **abono** del proveedor.

---

## Facturas

**Facturas de compra**: el documento contable que el proveedor emite y que
se registra para control de gasto e IVA soportado. Se asocian a los
albaranes recibidos.

---

## Formas de pago

Catálogo de **formas de pago** aplicables a las compras (contado,
transferencia, giro a X días, etc.). Define el vencimiento y el
comportamiento de cobro/pago. El mismo catálogo de formas de pago se
utiliza también en ventas.

Sub-pestañas: **Más Datos**, **Ventas** (uso en ventas) y **Otros**.

---

[◀ Menú Archivo](02-menu-archivo.md) · [Índice](README.md) · [Siguiente ▶ Menú Ventas Mayor](04-menu-ventas-mayor.md)
