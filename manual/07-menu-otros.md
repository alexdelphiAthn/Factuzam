# 07 · Menú Otros

[◀ Volver al índice](README.md)

El menú **Otros** agrupa la **administración y configuración** de la
aplicación: parámetros globales, impuestos, contadores de numeración,
seguridad (usuarios y permisos), copias de seguridad y herramientas
avanzadas. Son opciones que usa principalmente el **administrador**.

Estructura del menú:

```
Otros
├── Parámetros del entorno
├── Grupos de IVA
├── Impuesto IVA
├── Contadores
├── Usuarios, Grupos y Perfiles
│   ├── Usuarios
│   ├── Empleados
│   ├── Grupos
│   ├── Perfiles
│   ├── Permisos
│   └── Permisos (tabla)
├── Hacer Copia de Seguridad
├── Recuperar Copia de Seguridad
└── Generador de Procesos
```

---

## Parámetros del entorno

![Parámetros Generales de la Aplicación](img/07-parametros.png)
*▢ Captura pendiente — Parámetros Generales de la Aplicación.*

Pantalla de **Parámetros Generales de la Aplicación**. Centraliza la
configuración global de Factuzam: comportamiento por defecto, rutas,
opciones de impresión y de documentos, valores predeterminados de la
empresa de trabajo, etc.

> Son ajustes que afectan a **toda la instalación**. Cámbialos con
> conocimiento de causa; ante la duda, consulta con quien implantó la
> aplicación.

---

## Grupos de IVA

Define **agrupaciones de tipos de IVA** (zonas/regímenes de IVA). Sirve para
asociar a empresas, clientes y artículos el conjunto de tipos impositivos
que les corresponde (p. ej. IVA peninsular frente a otros regímenes).

---

## Impuesto IVA

![Tipos de IVA y recargo de equivalencia](img/07-iva.png)
*▢ Captura pendiente — Tipos de IVA y recargo de equivalencia.*

Mantiene los **tipos de IVA** concretos y sus porcentajes (general,
reducido, superreducido…), junto con el **recargo de equivalencia**
asociado a cada uno. Es la base del cálculo de impuestos en compras y
ventas.

> Los porcentajes de IVA los fija la normativa. No los cambies salvo que
> cambie la ley; un tipo mal configurado afecta a toda la facturación.

---

## Contadores

![Contadores de numeración por serie](img/07-contadores.png)
*▢ Captura pendiente — Contadores de numeración por serie.*

Gestiona los **contadores de numeración** de los documentos (facturas,
albaranes, pedidos…) por **serie** y empresa. Cada documento toma su número
correlativo del contador correspondiente.

> Los números de factura deben ser **correlativos y sin huecos** por
> exigencia legal. No retrocedas ni reutilices contadores de facturación.

---

## Usuarios, Grupos y Perfiles

Submenú de **seguridad**. Define quién entra a la aplicación y qué puede
hacer.

### Usuarios

Alta y mantenimiento de los **usuarios** que acceden a Factuzam (los que
introducen credenciales en el [login](00-acceso-y-primeros-pasos.md)).
Incluye su contraseña, estado y el **perfil/grupo** que determina sus
permisos.

### Empleados

Ficha de **empleados** del negocio (datos de personal). Puede vincularse a
usuarios y a operaciones de caja para saber **quién** realiza cada venta.

### Grupos

**Grupos de usuarios** para asignar permisos en bloque (p. ej. *Cajeros*,
*Administración*, *Encargados*). Un usuario hereda los permisos de su grupo.

### Perfiles

**Perfiles de configuración** que personalizan la apariencia y el
comportamiento de las pantallas (columnas visibles, captions, opciones)
para un usuario o grupo.

### Permisos

![Gestión de Permisos en árbol](img/07-permisos.png)
*▢ Captura pendiente — Gestión de Permisos en árbol.*

Pantalla de **Gestión de Permisos** en forma de **árbol**: activa o
desactiva, por grupo/usuario, el acceso a cada **menú y acción** de la
aplicación. Es la forma recomendada de configurar la seguridad de forma
visual.

### Permisos (tabla)

La misma información de permisos presentada en **formato tabla** (rejilla),
para edición masiva o revisión rápida de muchos permisos a la vez.

---

## Hacer Copia de Seguridad

![Diálogo de copia de seguridad](img/07-copia-seguridad.png)
*▢ Captura pendiente — Diálogo de copia de seguridad.*

Lanza una **copia de seguridad** de la base de datos. Genera un fichero de
respaldo con todos los datos (clientes, artículos, documentos, stock…).

> Realiza copias **con regularidad** y guárdalas en un lugar seguro y
> externo al equipo. Es tu única red de seguridad ante un fallo de disco o
> un borrado accidental.

---

## Recuperar Copia de Seguridad

Permite **restaurar** la base de datos a partir de un fichero de copia o
**ejecutar un script** de mantenimiento sobre la base de datos.

> ⚠️ **Operación delicada.** Restaurar una copia **sobrescribe los datos
> actuales**. Asegúrate de elegir el fichero correcto y de que nadie esté
> trabajando. Ante la duda, haz primero una copia del estado actual.

---

## Generador de Procesos

![Generador de Procesos con la pestaña Código SQL](img/07-generador-procesos.png)
*▢ Captura pendiente — Generador de Procesos con la pestaña Código SQL.*

Herramienta **avanzada** para administradores: permite definir y ejecutar
**procesos SQL** parametrizados sobre la base de datos (consultas,
correcciones masivas, informes a medida).

Sub-pestañas:

- **Código SQL** — la sentencia/proceso a ejecutar.
- **Metadatos** — parámetros y descripción del proceso.
- **VistaDatos** — previsualización del resultado.
- **Otros** — opciones complementarias.

> Pensado para usuarios técnicos. Una sentencia mal escrita puede modificar
> o borrar datos. Pruébala siempre sobre datos de prueba antes de ejecutarla
> en producción.

---

[◀ Menú Almacén](06-menu-almacen.md) · [Índice](README.md) · [Siguiente ▶ Menú Ayuda](08-menu-ayuda.md)
