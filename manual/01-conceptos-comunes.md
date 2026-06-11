# 01 · Conceptos comunes a todas las pantallas

[◀ Volver al índice](README.md)

Casi todas las opciones de menú abren una **pantalla de mantenimiento** con
la misma estructura. Si entiendes cómo funciona una, las entiendes todas.
Este capítulo explica esa estructura común; los capítulos siguientes solo
añaden lo específico de cada pantalla.

---

## 1. Estructura de una pantalla de mantenimiento

Una pantalla de mantenimiento típica tiene **dos pestañas principales**:

![Pestaña Lista de un mantenimiento](img/01-lista.png)
*▢ Captura pendiente — Pestaña Lista (rejilla) de un mantenimiento cualquiera.*

### Pestaña **Lista**

Muestra una **rejilla (grid)** con todos los registros de la tabla (clientes,
artículos, facturas…). Desde aquí puedes:

- **Ordenar** por cualquier columna pulsando en su cabecera.
- **Agrupar, filtrar y reorganizar** columnas (funciones del grid
  DevExpress).
- **Buscar** texto en la rejilla.
- Hacer **doble clic** en una fila para abrir su **Ficha**.

### Pestaña **Ficha**

Muestra el **detalle de un único registro** con todos sus campos
organizados en sub-pestañas (Datos principales, Más datos, etc.). Es donde
se **da de alta, se consulta y se edita** un registro concreto.

![Pestaña Ficha de un mantenimiento](img/01-ficha.png)
*▢ Captura pendiente — Pestaña Ficha con sus sub-pestañas.*

> Algunas pantallas tienen además una pestaña **Perfil** (visible solo para
> administradores) para configurar columnas, captions y comportamiento de
> la propia pantalla por usuario/perfil.

---

## 2. El navegador de registros

En la parte inferior (o lateral) de la pantalla hay una **barra de
navegación** con los botones estándar. Sus acciones son siempre las mismas:

![Barra del navegador de registros](img/01-navegador.png)
*▢ Captura pendiente — Barra de navegación con sus botones.*

| Botón | Atajo | Acción |
|-------|-------|--------|
| **Primer registro** | `[Ctrl]+[Inicio]` | Va al primer registro de la lista (respeta la ordenación del grid). |
| **Registro anterior** | `[RePág]` | Retrocede un registro. |
| **Registro siguiente** | `[AvPág]` | Avanza un registro. |
| **Último registro** | `[Ctrl]+[Fin]` | Va al último registro de la lista (respeta la ordenación del grid). |
| **Insertar registro** | `[Insert]` | Crea un registro nuevo en blanco para rellenar. |
| **Editar registro** | `[F2]` | Pone en modo edición el registro actual. |
| **Eliminar registro** | `[Ctrl]+[Supr]` | Borra el registro actual (pide confirmación). |
| **Grabar registro** | `[F12]` | Confirma y guarda los cambios en la base de datos. |
| **Retroceder bloque** | `[Ctrl]+[RePág]` | Retrocede un bloque de registros (paginación). |
| **Avanzar bloque** | `[Ctrl]+[AvPág]` | Avanza un bloque de registros (paginación). |

En artículos y documentos aparecen además botones específicos:

| Botón | Atajo | Acción |
|-------|-------|--------|
| **Foto artículo** | `[Ctrl]+[F]` | Muestra la foto del artículo. |
| **Consulta stock** | `[Ctrl]+[U]` | Consulta el stock del artículo actual. |

> Los atajos del navegador funcionan cuando la pantalla de mantenimiento
> tiene el foco. **Grabar** dispone de dos atajos equivalentes: `[F12]`
> (botón **Grabar registro** del navegador) y `[Alt]+[G]` (botón
> **Grabar** de acción, ver abajo).

---

## 3. Botones de acción

Independientemente del navegador, las pantallas suelen mostrar tres botones
de acción principales. La letra subrayada es su **mnemónico** (`[Alt]` +
esa letra):

- **Grabar** (`[Alt]+[G]`) — guarda los cambios del registro en edición.
- **Cancelar** (`[Alt]+[C]`) — descarta los cambios no guardados y vuelve
  al estado anterior.
- **Salir** (`[Alt]+[S]`) — cierra la pestaña de la pantalla.

---

## 4. Flujo de trabajo: alta, modificación y baja

**Dar de alta un registro nuevo:**

1. Pulsa **Insertar registro** (o el botón de alta).
2. Rellena los campos en la **Ficha**. Los campos obligatorios suelen estar
   marcados o se validan al grabar.
3. Pulsa **Grabar**.

**Modificar un registro existente:**

1. Localízalo en la **Lista** y ábrelo en la **Ficha** (doble clic).
2. Opcionalmente, puede omitirse, pulsa **Editar registro** ó F2.
3. Cambia lo necesario y pulsa **Grabar** ó F12.

**Dar de baja un registro:**

1. Sitúate sobre el registro.
2. Pulsa **Eliminar registro** y confirma o `[Ctrl]+[Supr]`.

> Muchas tablas no se borran realmente, sino que se **desactivan** mediante
> una marca **Activo (S/N)**. Así se conserva el histórico y la integridad
> de documentos antiguos. Cuando exista esa marca, prefiérela al borrado.

---

## 5. Búsquedas

Las pantallas ofrecen dos formas de buscar:

- **Buscar BBDD** — busca en **toda la base de datos** según el texto
  introducido en *Texto a buscar*. Útil para encontrar un registro que no
  está cargado en la página actual.
- **Buscar Grid** — busca **solo dentro de los datos ya cargados** en la
  rejilla.

Atajo rápido: en muchas pantallas, `[Ctrl]+[A]` abre la instancia de
búsqueda con el filtro «Todos» para localizar cualquier registro.

---

## 6. Exportar a Excel e imprimir

- La mayoría de listas permiten **exportar a Excel** el contenido de la
  rejilla (con los filtros y columnas visibles en ese momento).
- Los documentos (facturas, albaranes, pedidos…) y los informes generan
  **vistas previas imprimibles** (FastReport) desde las que se imprime o se
  exporta a PDF.

---

## 7. Campos de auditoría

Todos los registros guardan automáticamente **quién y cuándo** los creó y
los modificó por última vez (instante de alta/modificación y usuario). No
hay que rellenarlos: la aplicación los gestiona sola. Son útiles para
trazabilidad y soporte.

---

[◀ Acceso](00-acceso-y-primeros-pasos.md) · [Índice](README.md) · [Siguiente ▶ Menú Archivo](02-menu-archivo.md)
