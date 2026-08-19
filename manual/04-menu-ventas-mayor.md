# 04 · Menú Ventas Mayor

[◀ Volver al índice](README.md)

El menú **Ventas Mayor** gestiona la **venta al por mayor** (B2B): ventas a
otros comercios o clientes con factura nominativa, a diferencia de la venta
al detalle en tienda, que se hace desde el módulo
[TPV](05-menu-caja.md).

Estructura del menú:

```
Ventas Mayor
├── Borradores
├── Efectos de cobro
├── Remesas de cobro
├── Cargar efectos en remesa...
├── Pedidos
├── Albaranes
└── Listados
    └── Ventas
```

> Flujo habitual de venta a mayor:
> **Pedido** del cliente → **Albarán** de salida (sale el stock) →
> **Borrador** de factura → **Consolidar** (registro fiscal). Se puede
> facturar albarán a albarán o agrupar varios albaranes en un solo
> borrador antes de emitirlo.

---

## Borradores

![Borrador de venta: cabecera, líneas y totales](img/04-borradores.png)

**Atajo de menú:** `[Ctrl]+[Alt]+[F]`

Mantenimiento de **Borradores de Venta Mayor**. Mientras el documento está
en fase **BORRADOR** se puede editar; al pulsar **Consolidar** se emite el
registro fiscal según el modo configurado en Verifactu.

Cada borrador lleva:

- **Cabecera**: cliente, fecha, **serie** y número, forma de pago y vencimientos.
- **Líneas**: artículos/SKU, cantidades, precio tomado de la **tarifa** del cliente y descuentos.
- **Totales e impuestos**: base, IVA por tipo, recargo de equivalencia y retenciones según cliente y empresa.
- **Efectos**: vencimientos de cobro generados desde la forma de pago, con importe, vencimiento, estado y banco asociado.

Los borradores se firman o comunican a **Verifactu (AEAT)** según la
configuración de certificado de la empresa (ver
[Empresas](02-menu-archivo.md#empresas)).

> Un borrador puede crearse manualmente o **a partir de albaranes**
> pendientes de facturar, incluso agrupando varios albaranes de un cliente
> en un rango de fechas.

Al consolidar, el documento deja de ser editable. Las correcciones
posteriores se hacen con **Anular**, **Rectificar** o **Subsanar**, según
el caso fiscal. La pestaña Verifactu muestra QR, URL de cotejo, estado y
registro asociado.

### Efectos y eDoc en el borrador

El botón **Generar efectos** reparte el total líquido en vencimientos según
la forma de pago. En facturas normales la pestaña 3 muestra **Efectos** de
cobro; en simplificadas mantiene el circuito de recibos.

Desde la pestaña de efectos se puede marcar un vencimiento como
**Cobrado** o **Devuelto**. Para gestionar muchos vencimientos juntos, usa
las opciones de menú **Efectos de cobro**, **Remesas de cobro** y
**Cargar efectos en remesa...**.

La pestaña **Parámetros eDoc** guarda la foto de emisión para Facturae:
DIR3 de oficina contable, órgano gestor y unidad tramitadora, además de
nombre y apellidos cuando el receptor es persona física. Se propone desde
la ficha del cliente y puede corregirse para esa factura concreta.

El botón **Emitir eDoc** genera un fichero Facturae firmado (`.xsig`) y
guarda el XML firmado en la factura. Solo se emite desde facturas normales
ya consolidadas, con certificado de empresa configurado y datos fiscales
completos.

![Parámetros eDoc del borrador](img/04-borradores-edoc.png)

---

## Efectos de cobro

Mantenimiento de vencimientos de cliente. Cada efecto representa un cobro
pendiente, cobrado, remesado o conciliado, generado desde un borrador de
venta mayor.

![Efectos de cobro](img/04-efectos-cobro.png)

Acciones principales:

- **Conciliar efecto** — registra un cobro total o parcial, con fecha, importe, tipo y referencia.
- **Fusionar efectos** — agrupa efectos pendientes cuando se necesita regularizar varios vencimientos en uno.

Estados habituales:

| Estado | Significado |
|--------|-------------|
| **PENDIENTE** | Vencimiento vivo, todavía no cobrado. |
| **COBRADO** | Cobrado total o parcialmente. |
| **REMESADO** | Incluido en una remesa de cobro. |
| **CONCILIADO** | Fusionado o regularizado con otro efecto. |

---

## Remesas de cobro

Agrupa efectos de cliente para gestionar cobros bancarios. La remesa
recoge empresa, banco de cobro, fecha, número de efectos, total, cobro
realizado y pendiente.

![Remesas de cobro](img/04-remesas-cobro.png)

Acciones principales:

- **Añadir efecto** — abre la selección de efectos pendientes.
- **Quitar efecto** — retira el efecto seleccionado de la remesa.
- **Conciliar efecto** — registra el cobro de un efecto concreto.
- **Conciliar remesa** — registra el cobro de todos los efectos de la remesa.
- **Asignar banco** — fija o cambia el banco de cobro de la empresa.
- **Fecha cobro** — actualiza la fecha de cobro de la remesa.
- **Generar SEPA** — crea el fichero bancario cuando la remesa tiene los datos SEPA necesarios.

---

## Cargar efectos en remesa...

Acceso directo al selector de efectos pendientes para crear una remesa
nueva o alimentar una remesa existente.

![Cargar efectos en remesa de cobro](img/04-cargar-efectos-remesa.png)

Filtra por empresa y vencimiento máximo. Marca los efectos que quieras
incluir y pulsa **Cargar en remesa**.

---

## Pedidos

![Pedidos de venta](img/04-pedidos.png)

**Atajo de menú:** `[Ctrl]+[Alt]+[P]`

Mantenimiento de **Pedidos de Venta**. Registra lo que un cliente
**encarga** (reserva de género). No mueve stock; sirve de base para generar
el **albarán** de salida cuando se sirve el pedido.

### Importar pedidos de PrestaShop

El botón **Importar de PrestaShop** abre una ventana para incorporar de forma
manual pedidos remotos. Esta función utiliza la URL y la clave API efectivas
de **Otros ▸ Parámetros del entorno ▸ PrestaShop**; la credencial no se muestra
en la ventana.

Antes de empezar:

1. Entra con la empresa y el almacén de salida correctos. La empresa y el
   almacén del pedido se toman de la sesión actual; sin almacén no se importa.
2. Configura una URL HTTPS y una clave API exclusiva de mínimo privilegio. La
   clave necesita lectura de `orders`, `customers`, `addresses`, `states`,
   `carriers`, `order_states`, `customer_threads` y `customer_messages`.
3. Comprueba que la empresa tenga una configuración de IVA vigente en la fecha
   del pedido y revisa que este sea fiscalmente compatible con ella. Sin esa
   configuración no se importa, aunque el pedido no tenga portes.
4. Usa una instalación de laboratorio o una clave limitada a una única
   tienda. La importación actual no aplica el **Id. tienda** al listar pedidos.

Procedimiento:

1. Pulsa **Conectar y listar**. Factuzam consulta PrestaShop y carga el resumen
   de los pedidos accesibles para esa clave. La consulta actual no limita por
   fecha ni por estado; en tiendas con mucho histórico puede tardar.
2. Revisa las columnas y contrasta el estado remoto antes de seleccionar:

   | Columna | Contenido |
   |---------|-----------|
   | **Sel.** | Marca los pedidos que se intentarán importar. |
   | **ID PS** | Identificador numérico del pedido en PrestaShop. |
   | **Referencia** | Referencia comercial asignada por PrestaShop. |
   | **Fecha** | Fecha comunicada por la tienda. |
   | **Cliente** | Nombre del cliente remoto. |
   | **Total** | Total con impuestos comunicado por PrestaShop. |
   | **Estado** | Nombre del estado remoto; es informativo. |
   | **Importado?** | `S` cuando Factuzam ya encuentra ese `ID PS`; `N` en caso contrario. |

3. No selecciones pedidos cancelados, reembolsados, de prueba ni cualquier
   estado que no deba servirse. La ventana todavía no bloquea automáticamente
   esos estados.
4. Marca las filas correctas y pulsa **Importar selección**.
5. Factuzam procesa los pedidos uno a uno. Si uno falla, muestra el error para
   ese identificador y continúa con los siguientes. Al terminar informa del
   número de pedidos importados y de errores.
6. Actualiza la lista de pedidos y revisa el documento local antes de crear el
   albarán. No des por correcta una importación solo porque el resumen termine
   sin errores.

La detección de duplicados comprueba actualmente el `ID PS`. Un pedido que ya
figure importado se omite también si vuelve a marcarse. Esta protección evita
la repetición ordinaria en una sola instalación, pero el identificador aún no
está ligado al destino PrestaShop ni protegido por una clave única de base de
datos. No deben ejecutarse dos importaciones concurrentes del mismo pedido.

Durante la importación:

- el pedido queda asociado a la empresa y al almacén de la sesión;
- el cliente se busca primero por NIF y después por correo electrónico; si no
  se encuentra, se crea una ficha con los datos recibidos;
- cada producto se intenta resolver por código de barras y por referencia;
  si no existe, puede crearse un artículo y un SKU locales;
- los mensajes del pedido se copian cuando PrestaShop los proporciona; un
  error aislado en un mensaje no invalida el resto del pedido;
- los importes de los productos se guardan con el tipo de IVA del artículo
  local y los porcentajes vigentes de la empresa.

#### Gastos de transporte `GASTOS_T`

Si el pedido tiene portes, Factuzam añade al final una línea de una unidad con
estas reglas:

- artículo y SKU: `GASTOS_T`;
- descripción: **GASTOS TRANSPORTE**;
- tipo de artículo: **SERVICIO**, sin variaciones, sin trazabilidad y con
  **En web = No**;
- IVA: tipo normal de la empresa, calculado a partir de su configuración;
- precio sin IVA, precio con IVA y base: los importes comunicados por
  PrestaShop.

El artículo y el SKU se crean la primera vez y se reutilizan después. Si alguno
de esos códigos ya existe con un tipo, IVA, padre o estado incompatible, se
cancela el pedido en lugar de transformar silenciosamente el maestro. También
se cancela si los portes con y sin IVA no corresponden al IVA normal de la
empresa. Cuando ambos importes son cero no se crea la línea.

`GASTOS_T` es un servicio: al pasar el pedido a albarán y después a factura
conserva su tipo y su importe, pero no genera un movimiento de almacén. Las
líneas de mercancía del mismo documento sí siguen el circuito normal de stock.

> **Límites actuales y uso en producción**
>
> - La importación solo transmite URL y clave al lector remoto: todavía no
>   filtra `orders` por **Id. tienda**. Una clave que abarque varias tiendas
>   puede mezclar pedidos y hace la función **NO-GO multitienda**.
> - La correspondencia exacta del SKU o combinación remota con el SKU local no
>   está cerrada para todos los casos. Deben revisarse especialmente productos
>   sin EAN y combinaciones de talla o color antes de servirlos.
> - Las altas automáticas de cliente y artículos de producto ocurren antes de
>   la transacción final del pedido. La atomicidad completa de todos los
>   maestros sigue pendiente.
> - El IVA se resuelve para el grupo fiscal de la empresa y la fecha comunicada
>   por PrestaShop. Revisa que los periodos fiscales no tengan huecos ni
>   solapamientos antes de incorporar pedidos antiguos.
> - El botón exige el permiso genérico **Insertar** del mantenimiento de
>   pedidos. No existe todavía una acción independiente para conceder solo la
>   importación. Ese permiso autoriza también las altas automáticas necesarias
>   de clientes, artículos, SKU/EAN y `GASTOS_T`, sin consultar por separado
>   los permisos de alta de esos maestros; concédelo solo a personal autorizado.
> - Solo se materializan productos y portes. Los cupones o descuentos globales
>   y el envoltorio no se convierten todavía en líneas locales; no importes un
>   pedido que los contenga si la suma de las líneas no coincide con el total
>   pagado en PrestaShop.
> - Importar un pedido no mueve ni descuenta stock físico y no sustituye una
>   ingestión o reserva automática. Mantén **Sincronizar stock y precios**
>   desmarcado en producción: una escritura absoluta podría reponer unidades
>   ya vendidas en la web.
> - La batería funcional de importación, concurrencia, servicio y ciclo
>   pedido → albarán → factura no está completada. Utiliza esta función en
>   laboratorio y valida manualmente cliente, SKU, impuestos, portes y totales.
>
> Consulta también [Integración con PrestaShop](15-integracion-prestashop.md),
> especialmente [Seguridad del stock](15-integracion-prestashop.md#11-seguridad-del-stock).

---

## Albaranes

![Albaranes de venta](img/04-albaranes.png)

**Atajo de menú:** `[Ctrl]+[Alt]+[A]`

Mantenimiento de **Albaranes de Venta**. Registra la **salida real** de
mercancía hacia el cliente: al confirmarlo **resta stock** del almacén. Es
el documento que después se **factura**.

Desde los albaranes se pueden crear borradores por rango de fechas. El
selector permite marcar varios albaranes pendientes y generar un borrador
agrupado para el mismo cliente.

![Crear borradores desde albaranes de venta](img/04-albaranes-crear-borradores.png)

---

## Listados ▸ Ventas

![Filtros del listado de ventas](img/04-listado-ventas.png)

**Atajo de menú:** `[Ctrl]+[Alt]+[V]`

Abre el **generador de listados de ventas**. Mediante un cuadro de
**filtros** (rango de fechas, cliente, artículo, familia, serie…) genera un
informe de las ventas realizadas, que se puede **previsualizar, imprimir o
exportar**.

Útil para análisis comercial: qué se ha vendido, a quién y en qué periodo.

---

[◀ Menú Compras](03-menu-compras.md) · [Índice](README.md) · [Siguiente ▶ Menú TPV](05-menu-caja.md)
