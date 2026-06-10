# 02 · Menú Archivo

[◀ Volver al índice](README.md)

El menú **Archivo** contiene los **datos maestros** del negocio: la
información estable sobre la que se apoyan todos los documentos (empresas,
almacenes, clientes, proveedores, artículos) y las **tablas auxiliares**
que los clasifican. Es el primer menú que se configura al poner en marcha
la aplicación.

> Recuerda: todas estas pantallas comparten el funcionamiento descrito en
> [01 · Conceptos comunes](01-conceptos-comunes.md) (lista, ficha,
> navegador, búsqueda, grabar/cancelar). Aquí se describe solo lo propio de
> cada una.

Estructura del menú:

```
Archivo
├── Empresas
├── Almacenes
├── Clientes
├── Proveedores
├── Artículos
├── Tablas Auxiliares
│   ├── Tarifas
│   ├── Familias
│   ├── Paises
│   ├── Unidades de Medida
│   ├── Propiedades
│   ├── Tipos de Variaciones
│   ├── Colecciones de Atributos
│   └── Atributos básicos
├── Invocar login
└── Salir
```

---

## Empresas

![Ficha de Empresas con sus sub-pestañas (Series, Retenciones, Certificado)](img/02-empresas.png)
*▢ Captura pendiente — Ficha de Empresas con sus sub-pestañas (Series, Retenciones, Certificado).*

Mantiene las **empresas emisoras** que facturan desde Factuzam (puede haber
más de una). Cada empresa concentra sus datos fiscales y la configuración
de facturación.

**Datos principales:** Código, Orden, Activo, Razón Social, NIF, dirección
completa (dirección, población, provincia, código postal), Móvil, Email.

**Datos fiscales y de facturación** (en sub-pestañas):

- **Más datos** — contacto y datos complementarios.
- **Retenciones** — código y **% de retención** aplicable; marca *Aplica
  Retenciones* y *Es REAGP* (Régimen Especial Agricultura, Ganadería y
  Pesca).
- **Series** — **series de numeración** de los documentos de la empresa
  (puedes añadir varias series de facturación).
- **Certificado / Verifactu** — *Número de Serie* y *Tipo de Certificado*
  para la firma y el envío de facturas al sistema **Verifactu (AEAT)**.
- **Texto en Factura** — texto legal que se imprimirá en los documentos.
- **Zona de IVA principal** — régimen de IVA por defecto de la empresa.

> La configuración correcta de **NIF, series y certificado** es
> imprescindible para emitir facturas válidas y para la integración con
> Verifactu. Si tienes dudas fiscales, consúltalas con tu asesoría antes de
> facturar.

---

## Almacenes

![Ficha de Almacenes](img/02-almacenes.png)
*▢ Captura pendiente — Ficha de Almacenes.*

Mantiene los **almacenes** físicos o lógicos donde se ubica el stock. Cada
movimiento de stock, inventario o documento de mercancía referencia un
almacén.

Sub-pestañas de la ficha:

- **Dirección física** — ubicación del almacén.
- **Cajas de Venta** — cajas/TPV asociadas a este almacén (relación
  almacén ↔ caja para el módulo Caja).
- **Usos Almacén** — para qué se usa el almacén (venta, depósito, etc.).
- **Otros** — datos complementarios.

---

## Clientes

![Ficha de Clientes con los indicadores fiscales](img/02-clientes.png)
*▢ Captura pendiente — Ficha de Clientes con los indicadores fiscales.*

Mantiene la **ficha de clientes** a quienes se vende y factura.

**Datos generales:** Código, Activo, Razón Social, NIF/CIF, teléfonos
(móvil y fijo), Email, dirección completa, País, Observaciones, Referencia,
Contacto y teléfono de contacto, Nº de cuenta.

**Datos fiscales** que determinan cómo se calcula cada factura del cliente:

| Campo | Efecto |
|-------|--------|
| **Forma de pago por defecto** | Se propone automáticamente en sus documentos. |
| **Aplicar RE** | Aplica **Recargo de Equivalencia**. |
| **Aplicar Retenciones** | Aplica retención de IRPF. |
| **Tiene IVA exento** | El cliente no soporta IVA. |
| **Es Intracomunitario** | Operación intracomunitaria (IVA 0 con condiciones). |
| **Es Agricultor** | Régimen especial agrario. |
| **Razón Social Fiscal** | Nombre fiscal si difiere del comercial. |
| **Texto Legal Factura** | Texto específico para las facturas de este cliente. |

> Estos indicadores afectan directamente al **cálculo de impuestos** en
> ventas. Configúralos con cuidado al dar de alta el cliente.

---

## Proveedores

![Ficha de Proveedores](img/02-proveedores.png)
*▢ Captura pendiente — Ficha de Proveedores.*

Mantiene la **ficha de proveedores** a quienes se compra mercancía.
Estructura análoga a Clientes, orientada a compras.

Sub-pestañas de la ficha:

- **Domicilio fiscal** — datos fiscales y de dirección.
- **Artículos** — artículos que suministra el proveedor (con sus
  referencias y precios de compra).
- **Ventas** — histórico/relación comercial.
- **Más datos** y **Otros** — información complementaria.

---

## Artículos

![Ficha de Artículos con la pestaña SKUs](img/02-articulos.png)
*▢ Captura pendiente — Ficha de Artículos con la pestaña SKUs.*

Es la pantalla central del catálogo. Mantiene los **artículos** y sus
variantes (las distintas tallas/colores se denominan **SKU**).

Sub-pestañas de la ficha:

- **General** — datos básicos: descripción, familia, unidad de medida,
  IVA, etc.
- **SKUs** — las **variantes** del artículo (combinaciones de talla, color
  u otros atributos). Cada SKU es una referencia vendible con su propio
  stock y código de barras. Existe un asistente para **generar SKUs** a
  partir de las variaciones definidas.
- **Propiedades** — propiedades descriptivas asignadas al artículo.
- **CB** — **códigos de barras** del artículo y sus SKUs.
- **Tarifas** — precios del artículo en las distintas tarifas.
- **Proveedores** — proveedores que lo suministran y sus referencias.

Desde la lista/ficha puedes además consultar **stock** y la **foto** del
artículo con los botones del navegador.

> El concepto de **SKU** (variante de talla/color) es clave en Factuzam:
> el stock, los precios y los códigos de barras se llevan a nivel de SKU,
> no solo de artículo.

---

## Tablas Auxiliares

Submenú con los **catálogos de apoyo** que clasifican y describen a los
artículos. Conviene definirlos **antes** de cargar el catálogo de
artículos.

### Tarifas

![Mantenimiento de Tarifas con los precios por artículo](img/02-tarifas.png)
*▢ Captura pendiente — Mantenimiento de Tarifas con los precios por artículo.*

Define las **listas de precios** (tarifa general, ofertas, mayoristas…).
Cada tarifa contiene los precios de los artículos.

- **Artículos** — precios de cada artículo/SKU en esta tarifa. Incluye
  utilidades para **añadir precios** en bloque y **calcular márgenes**.
- **Otros** — parámetros de la tarifa (vigencia, redondeos, etc.).

### Familias

![Mantenimiento de Familias](img/02-familias.png)
*▢ Captura pendiente — Mantenimiento de Familias.*

**Clasificación jerárquica** de los artículos (familias y subfamilias).
Permite agrupar el catálogo para informes, filtros y precios.

- **Más Datos** — datos de la familia.
- **Artículos** — artículos pertenecientes a la familia.
- **Propiedades Artículos** — propiedades que heredan los artículos de la
  familia.
- **Otros**.

### Paises

Catálogo de **países** usado en las direcciones de clientes, proveedores y
empresas (y para la clasificación fiscal intracomunitaria/extracomunitaria).

### Unidades de Medida

Catálogo de **unidades** en que se compran/venden los artículos (unidad,
par, caja, metro, kilo…).

### Propiedades

Define **propiedades descriptivas** de artículos (p. ej. *Material*,
*Temporada*) y sus **valores disponibles**.

- **Valores Disponibles** — lista de valores posibles de la propiedad.
- **Artículos** — artículos que usan esta propiedad.

### Tipos de Variaciones

Define los **ejes de variación** que generan SKUs (p. ej. *Talla*,
*Color*) y sus atributos.

- **Atributos** — valores de la variación (S, M, L, XL… o la gama de
  colores).
- **Artículos** — artículos que usan este tipo de variación.
- **Otros**.

### Colecciones de Atributos

Define **conjuntos reutilizables de atributos** (p. ej. una colección de
tallas estándar) que luego se aplican a varios artículos para generar sus
SKUs sin redefinirlos cada vez.

- **Valores** — atributos que componen la colección.
- **Artículos** — artículos que la utilizan.
- **Otros**.

### Atributos básicos

Catálogo de los **atributos elementales** (los valores individuales de
talla, color, etc.) que componen las variaciones y colecciones.

> **Orden recomendado de configuración del catálogo:**
> Unidades de Medida y Países → Familias → Atributos básicos → Tipos de
> Variaciones / Colecciones de Atributos → Propiedades → Tarifas →
> finalmente, los **Artículos** y sus SKUs.

---

## Invocar login

Vuelve a mostrar la ventana de **Login** sin cerrar la aplicación. Sirve
para **cambiar de usuario** (por ejemplo, que entre otra persona con su
perfil) sin reiniciar el programa.

---

## Salir

**Cierra la aplicación.** Si hay cambios sin guardar, la aplicación avisará
antes de salir.

---

[◀ Conceptos comunes](01-conceptos-comunes.md) · [Índice](README.md) · [Siguiente ▶ Menú Compras](03-menu-compras.md)
