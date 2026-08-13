# 14 · Arquitectura, estilo de programación y SQL configurable

[◀ Volver al índice](README.md)

Este capítulo resume las reglas técnicas con las que evoluciona Factuzam.
Está dirigido a desarrollo, soporte avanzado e implantadores. La referencia
completa del repositorio se mantiene en `LIBRO_DE_ESTILO_DELPHI.md`,
`LIBRO_DE_ESTILO_BBDD.md`, `PLAN_SOLID.md` y `MANUAL_SQL_PERFILES.md`.

---

## 1. Estilo de programación

Factuzam está escrito en Object Pascal/Delphi VCL y prioriza código legible,
predecible y compatible con su base instalada.

Reglas principales:

- Código, nombres propios, comentarios y commits en **español**; se respetan
  los prefijos de Delphi y de componentes de terceros.
- Una instrucción por línea. `if`, `while` y `for` colocan la condición y la
  acción en líneas separadas.
- Se evitan `Exit` y `Continue` en código nuevo para mantener visible el
  flujo completo del método.
- En cada sección de una clase se declaran primero los **campos** y después
  los **métodos**, como exige Delphi.
- Los comentarios son breves y explican decisiones, límites o reglas de
  negocio; no repiten una línea evidente.
- Los métodos se nombran con verbos en español y deben representar un paso
  cohesivo. Antes de ampliar una clase grande se extrae un colaborador,
  estrategia o función de dominio.
- Los formularios de mantenimiento heredan de `TfrmMtoGen` y los modales de
  `TfrmBase`; las utilidades independientes conservan su propio proyecto.
- Se mantienen UniDAC, DevExpress, JEDI y FastReport como decisiones de
  arquitectura; no se sustituyen por dependencias nuevas sin justificación.

Los cambios de base de datos se entregan como scripts idempotentes en
`DESARROLLOS EN CURSO/`. El dump `factuzam_original.sql` no se modifica.

---

## 2. SOLID aplicado de forma progresiva

Factuzam está migrando por fascículos desde un núcleo legado hacia una
arquitectura SOLID. No se presenta como una reescritura terminada: cada
extracción fija primero el comportamiento con pruebas y reduce el
acoplamiento sin mezclar cambios funcionales.

| Principio | Aplicación en Factuzam |
|-----------|------------------------|
| **SRP — responsabilidad única** | El formulario coordina la interfaz, el data module persiste y las librerías ejecutan reglas de negocio. Las responsabilidades grandes se extraen a colaboradores `TGestor*` o servicios específicos. |
| **OCP — abierto/cerrado** | Las variaciones de compra, venta, impresión o documento se modelan con configuración y estrategias, evitando copiar formularios completos para cada caso. |
| **LSP — sustitución** | Las clases base publican contratos y hooks coherentes; se evita ampliar una base cuando sus descendientes tendrían que anular el comportamiento con métodos vacíos. |
| **ISP — interfaces pequeñas** | Cada consumidor recibe solo la capacidad que necesita. Las interfaces propias son pequeñas, tienen GUID y se agrupan únicamente cuando comparten una misma implementación. |
| **DIP — inversión de dependencias** | El dominio depende de contratos `inLib*Intf`; las implementaciones UniDAC se crean fuera y se inyectan desde la raíz de composición. |

La secuencia de un fascículo es: prueba que fija el comportamiento,
extracción de una responsabilidad, compilación Win32/Win64, batería DUnitX
y comprobación de los trinquetes automáticos de arquitectura.

---

## 3. Capas y dirección de dependencias

```text
fzam.dpr / Core (composición)
            |
            v
Forms / Modals (presentación y coordinación)
            |
            v
UniData* (persistencia) ---> inLib* (dominio y colaboradores)
                                  |
                                  v
                            inLib*Intf (contratos)
```

| Capa | Responsabilidad |
|------|-----------------|
| **Core / composición** | Crea conexiones, repositorios, servicios y formularios; conecta implementaciones con contratos. |
| **Forms / Modals** | Muestra datos, solicita confirmaciones, coordina pestañas y traduce resultados de negocio a acciones visuales. |
| **UniData / DataModules** | Consulta y persiste mediante UniDAC, controla datasets y límites transaccionales. |
| **inLib** | Cálculos, validaciones, transformaciones, orquestadores y colaboradores reutilizables. |
| **inLib*Intf** | Interfaces y tipos estables sin dependencias de VCL, formularios o implementaciones de persistencia. |

Una librería de dominio no crea un repositorio, no conoce un formulario y
no obtiene una conexión global. Recibe por constructor o parámetro el
contrato que necesita. Las conexiones, la identidad y las credenciales
tienen propietario y ciclo de vida explícitos.

Las escrituras que afectan a varias tablas son atómicas: respetan una
transacción existente o realizan `Commit`/`Rollback` en el mismo nivel. Los
hilos no comparten datasets ni conexiones con la interfaz.

---

## 4. Consultas SQL configurables y consultables

El **catálogo SQL por perfiles** permite corregir determinadas consultas de
lectura sin recompilar ni sustituir `fzam.exe`. El dominio solicita una
operación de negocio a un repositorio; la implementación de persistencia
elige entre:

1. El **SQL base**, incluido y probado con el ejecutable.
2. Un **SQL personalizado** activo en `fza_usuarios_perfiles`.

El dominio no recibe texto SQL y no ofrece un método genérico
`Ejecutar(SQL)`. Cada operación mantiene una clave estable con la forma:

```text
KEY_USUPER    = SQL_REPOSITORIOS
SUBKEY_USUPER = SQL__Repositorio__Operacion
```

### Activación por pantalla

La propiedad de perfil `oGetSQLFromDB` activa el catálogo para cada
formulario consumidor. Al abrir la pantalla:

1. Factuzam carga las definiciones del catálogo compartido.
2. Publica las operaciones base que todavía falten, sin sobrescribir una
   personalización existente.
3. Resuelve cada lectura contra el perfil activo o contra el SQL base.

Desactivar el interruptor en un formulario no cambia los demás consumidores
de la misma operación.

El inventario de unidades que leen el interruptor, publican perfiles o
aportan definiciones al catálogo, junto con el recorrido histórico de los
data modules, está en
[`MANUAL_SQL_PERFILES.md`](../MANUAL_SQL_PERFILES.md#21-unidades-que-leen-ogetsqlfromdb-y-publican-perfiles).

### Validación y fallback seguro

Antes de ejecutar una personalización se comprueba que:

- no esté vacía;
- sea una lectura válida (`SELECT` o `CALL` con dataset);
- conserve exactamente los parámetros declarados;
- devuelva todos los campos y alias obligatorios;
- no contenga varias sentencias;
- no incluya `DROP`, `ALTER` ni `TRUNCATE`.

Si la validación falla, la consulta personalizada se descarta, se registra
la causa y se ejecuta el SQL base. Si pasa la validación pero falla al abrir
o devuelve una estructura incorrecta, Factuzam reintenta una vez con el SQL
base. Si también falla la base, el error se muestra de forma normal.

Las escrituras no usan este reintento automático: cualquier futura
personalización de escritura debe estar protegida por transacción y hacer
`Rollback` antes de cambiar de implementación.

### Revisión, auditoría y vuelta atrás

El administrador del catálogo permite **publicar**, **revisar** y
**exportar** las definiciones base y de perfil. La revisión muestra estado,
política, versión, huellas, validación y última causa de fallback. Cada fila
guarda además instante y usuario de modificación.

Para volver inmediatamente al comportamiento incluido en el ejecutable se
puede:

1. Desactivar una operación cambiando su estado de `S` a `N`.
2. Eliminar únicamente su fila personalizada.
3. Establecer `oGetSQLFromDB=False` para toda la pantalla.

No es necesario desplegar otro ejecutable. Antes de editar una consulta se
hace copia del SQL y de sus metadatos; nunca se cambian los parámetros ni
los alias exigidos por el contrato.

---

## 5. Pruebas y reglas de no regresión

- DUnitX cubre funciones de dominio, colaboradores y repositorios falsos sin
  necesidad de una base de datos real.
- Las pruebas de integración cubren procedimientos, SQL y transacciones.
- Los scripts de trinquete impiden reintroducir dependencias de capas, SQL
  nuevo en el dominio, variables globales o crecimiento de clases y métodos
  por encima de los topes vigentes.
- Un refactor no mezcla cambios funcionales, renombrados masivos ni
  normalizaciones de formato.
- Antes de cerrar un cambio transversal se validan las plataformas Win32 y
  Win64 afectadas.

La finalidad es que cada mejora deje una barrera automática que el código
posterior no pueda volver a cruzar.

---

[◀ Aplicaciones móviles](13-aplicaciones-moviles.md) · [Índice](README.md) · [Siguiente ▶ Integración con PrestaShop](15-integracion-prestashop.md)
