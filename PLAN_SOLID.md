# PLAN_SOLID — Hoja de ruta de desacoplamiento y optimización

Plan de ejecución para llevar Factuzam a un cumplimiento real de SOLID.
No sustituye a `LIBRO_DE_ESTILO_DELPHI.md` §14: **lo ejecuta**. El libro
de estilo dice *cómo debe quedar el código*; este documento dice *en qué
orden llegar hasta ahí, con qué métrica y con qué criterio de parada*.

Línea base: 30/07/2026. Esta versión sustituye a la del 29/07/2026 tras
una auditoría independiente del código: incorpora lo ya completado, un
hallazgo nuevo de dirección de capas (§3.3) y el reordenado de fases.

---

## 0. Premisa

El proyecto **no** parte de cero en arquitectura. Hay dirección de capas
documentada y verificada, contratos propios, colaboradores `TGestor*`,
red DUnitX y nueve scripts de trinquete. El problema no es *"no hay
diseño"*: es que **el diseño nuevo convive con un núcleo legado que
concentra casi toda la masa del proyecto**, y que ese núcleo sigue
hablando SQL directamente.

Por eso el plan no es una refactorización: es una **migración por
fascículos con trinquete**. Cada fase deja una métrica que ya no puede
empeorar, verificada por script en cada commit.

Regla del fascículo (no negociable):

1. Prueba DUnitX que fija el comportamiento actual (incluidos los bugs
   que deban conservarse).
2. Extraer **una** responsabilidad.
3. Compilar Win32 + Win64 y pasar `FactuzamTests.exe`.
4. Commit.

Un fascículo nunca mezcla cambio funcional, normalización de formato ni
renombrados masivos. La Fase 1 se ejecutó a mucha velocidad; la regla
sigue vigente precisamente porque las fases que quedan tocan
transacciones y zona fiscal, donde un fascículo sin red se paga caro.

---

## 1. Línea base medida (30/07/2026)

Medido sobre `src/`, excluyendo `3rdpartyComp`, `vcl`, `vcl37`, las
carpetas de pruebas sueltas y los proyectos utilitarios independientes.
Donde existe script de trinquete, manda la cifra del script.

| Métrica                                     | 29/07   | 30/07   |
|---------------------------------------------|---------|---------|
| Units propias                               | 457     | 452     |
| Líneas de código propio                     | 261.397 | ~250.000|
| `var` en sección `interface`                | 1.516   | **0**   |
| `except` vacíos                             | 55      | **0**   |
| `resourcestring`                            | 5       | **1.458**|
| Infracciones de capa `inLib*`→`inMto*`      | 2       | **0**   |
| Units `inLib*`→`UniData*` (§3.3, cerrado)   | —       | **0**   |
| Sentencias SQL literales en `inLib*`        | 471     | 469     |
| Units `inLib*` con SQL                      | 79      | 71      |
| `Supports(...)` totales                     | 75      | 70      |
| `Supports(...)` fuera de lista blanca       | —       | 5       |
| Units > 2.000 líneas (sin vendorizado)      | 20      | 20      |
| Métodos > 200 líneas                        | 30      | ≤38 (tope)|
| Fan-in de `inLibMsg` (fachada)              | 197     | 60      |
| Units de pruebas DUnitX                     | 30      | 38      |
| Contratos `I*` propios                      | 70      | >70     |
| Tamaño de `fzam.exe`                        | 99,7 MB | 99,7 MB |

### 1.1 Acoplamiento eferente (fan-out): units que arrastran el proyecto

| Units usadas | Unidad                    |
|--------------|---------------------------|
| 101          | `inMtoCatalogoPantallas`  |
| 70           | `inMtoPrincipal`          |
| 39           | `inMtoFacturasBase`       |
| 36           | `inMtoCajaOpe`            |
| 33           | `inMtoGen`                |
| 30           | `inMtoComprasSesiones`    |

### 1.2 Acoplamiento aferente (fan-in): units que paralizan la compilación

| Units que la usan | Unidad                |
|-------------------|-----------------------|
| 84                | `inLibUser`           |
| 81                | `inLibLog`            |
| 60                | `inMtoFrmBase`        |
| 60                | `inLibMsg` (fachada en retirada) |
| 52                | `UniDataGen`          |
| 52                | `inMtoGen`            |
| 49                | `inLibWin`            |
| 45                | `inLibParametrosIntf` |

`inLibParametrosIntf` es fan-in *sano* (contrato sin cuerpo). Ojo con
`inLibLog`: ha subido de 67 a 81 porque los fascículos de `except` ahora
registran contexto. Es el precio correcto de no silenciar errores, pero
refuerza la necesidad de separar su contrato de su implementación
(Fase 6).

---

## 2. Lo que ya está resuelto — no reabrir

Decisiones tomadas, ejecutadas y verificadas sobre el código. **No
entran en el plan**; los trinquetes impiden que regresen.

- **Fase 0 — Instrumentación.** Nueve scripts en `scripts/` con tope
  congelado y salida no-cero: `comprobar_estado_global`,
  `comprobar_sql_en_dominio`, `comprobar_tamano_clases`,
  `comprobar_acoplamiento`, `comprobar_dependencias_capas`,
  `comprobar_supports`, `comprobar_flujos_largos`,
  `comprobar_formularios_delgados`, `comprobar_sql_transacciones`.
- **Fase 1 — Higiene, completada.**
  - `var` en sección `interface` = 0 (eran 1.516). Los 1.413 mensajes de
    `inLibMsg` son `resourcestring` repartidos en nueve catálogos de
    dominio (`inLibMsgComun`, `inLibMsgFacturas`, `inLibMsgCaja`…).
    Queda retirar la fachada (§3.7).
  - `except` vacíos = 0 (eran 55): propagan, registran en `inLibLog` y
    continúan, o usan `inLibJsonSeguro` con pruebas propias.
  - Variables `frmXxx` / `dmXxx` del IDE eliminadas.
  - Las 2 infracciones `inLib*`→`inMto*` de `inLibCajaOpeComposicion`
    cerradas mediante contratos.
- **Arranque de la Fase 4.** `Supports` sigue el patrón de creación
  `Heredar*`: se resuelve una vez, se guarda en campo y el fallo es
  ruidoso (`EServicioNoDisponible` en `inLibAnfitrionMtoIntf`, con
  prueba en `PruebasNavegacionDocumento`). `comprobar_supports.ps1`
  vigila con lista blanca y tope 5.
- **Catálogo SQL por perfiles (SQL-0 … SQL-2.3d).** 89 definiciones de
  once repositorios. Los resolutores de artículos, los tickets de
  traspaso, el arqueo, la tira y los documentos de Caja consumen contratos; sus
  implementaciones UniDAC viven en `DataModules`. Las librerías de
  presentación ya no contienen SQL. Detalle en `ISSUES PENDIENTES.txt`
  y `MANUAL_SQL_PERFILES.md`.
- **Piloto de repositorios de la Fase 2 conectado.**
  `TServicioComprasSesiones` consume `IRepositorioComprasSesiones` y la
  implementación `UniDataComprasSesionesRepositorio` se inyecta por
  constructor. C1-C7 separa además la materialización en puertos,
  orquestador puro, unidad de trabajo y adaptadores especializados.
  `inLibComprasSesiones*` ya no conoce UniDAC,
  `UniDataComprasSesiones` ni SQL.
- **Registro de pantallas por referencia de clase**, verificado por el
  compilador.
- **Red DUnitX**: 44 units de prueba, fixtures sin BBDD real.
- **UniDAC como acceso a datos.** No se sustituye: se envuelve.

---

## 3. Diagnóstico por principio, con evidencia

Ordenado por urgencia real, no por el orden del acrónimo.

### 3.1 DIP — Urgencia ALTA. El dominio sigue hablando SQL

La medición de partida, anterior al piloto activo de compras, encontró
469 sentencias SQL literales en 71 units `inLib*`
(`comprobar_sql_en_dominio.ps1`). La infraestructura de salida ya existe
(contratos, catálogo por perfiles, repositorio piloto), pero los focos
densos de esa línea base eran:

| Sentencias | Unidad                              | Naturaleza |
|-----------:|-------------------------------------|------------|
| 40         | `inLibComprasSesionesMaterializar`  | dominio + escrituras |
| 31         | `inLibComprasSesiones`              | dominio    |
| 26         | `inLibVerifactuCola`                | **fiscal** |
| 26         | `inLibAlbaranesCompraMovimientos`   | dominio + stock |
| 20         | `inLibFotos`                        | infraestructura |
| 20         | `inLibGridPivoteCompra`             | infraestructura |
| 20         | `inLibColumnasSkuModoTallas`        | infraestructura |
| 17         | `inLibVentasWsJson`                 | integración |
| 15         | `inLibPedidosCompra`                | dominio    |

La medida vigilada baja a 223 sentencias en 59 units. Los dos focos de
sesiones de compra, `inLibVerifactuCola`,
`inLibAlbaranesCompraMovimientos`, `inLibPedidosCompra` e
`inLibVentasWsJson` ya están a cero SQL en `inLib*`. También queda
cerrado `inLibDevolucionesCompraMovimientos`, cuyas 9 sentencias viven
en `UniDataDevolucionesCompraMovimientos`. En pedidos de compra el
analizador vigente encontró 28 sentencias, frente a las 15 de la línea
base.

### 3.2 SRP — Urgencia ALTA. Las clases-dios siguen intactas

Estado con `scripts/comprobar_tamano_clases.ps1` (topes vigentes:
4.075 líneas / 133 métodos / 49 campos por clase):

| Clase                    | Líneas | Métodos | Primer alcance |
|--------------------------|-------:|--------:|----------------|
| `TfrmMtoOpeCaja`         | 4.060  | 104     | resolución de venta y escáner |
| `TfrmMtoFacturasBase`    | 4.000  | 133     | reglas fiscales y recibos |
| `TfrmMtoComprasSesiones` | 3.659  | 99      | creación/materialización |
| `TfrmMtoArticulos`       | 3.406  | 97      | alta y validación de SKU |
| `TfrmStockConsulta`      | 3.139  | 81      | consulta, pivote y tarjetas |
| `TfrmMtoInventarios`     | 3.069  | 77      | resolución de entradas y líneas |

Nada de eso se prueba sin levantar la VCL. El patrón de salida existe y
tiene pruebas: seis colaboradores `TGestor*` con dependencias por
constructor y callbacks tipados. **Falta escalarlo, no inventarlo.**

Atención a las clases-dios *de librería*, que el plan anterior no
listaba. En la línea base,
`inLibComprasSesionesMaterializar` tenía 3.060 líneas y era a la vez el
mayor foco de SQL; `inLibGridPivoteVenta` (3.100) y
`inLibColumnasSkuModoTallas` (3.010) le seguían. C1-C7 deja el
orquestador `inLib*` en 300 líneas y la fachada
`UniDataComprasSesionesMaterializar` en 189/12. Ninguna unidad
resultante supera 1.200 líneas ni 30 rutinas. El coste de separación y
el plan de reducción neta están medidos en el anexo.

El desglose operativo, los límites propios y las pruebas de estos tres
focos están en el
[anexo SRP de librerías](<DESARROLLOS EN CURSO/plan_srp_clases_dios_libreria.md>).
El anexo forma parte de esta fase y evita que una extracción de SQL se
dé por terminada si solo desplaza el monolito desde `inLib*` a
`UniData*`.

### 3.3 Capas — CERRADO. `inLib*` → `UniData*` a cero

Las infracciones hacia `inMto*` ya estaban cerradas. La auditoría
señaló además **6 units `inLib*` usando `UniData*`**, contra la
dirección del diagrama de §14.1. La medición sobre el árbol dio
**8 units y 10 aristas**: faltaban dos de `src\Caja\Lib`
(`inLibCajaOpeComposicion` y `inLibCajaConsultasRepositorio`).

Se ejecutó la **Opción A**: el cableado sube a la raíz de composición
real. Resultado, verificado por script y por compilación:

- **10 aristas → 0.** El tope de `comprobar_dependencias_capas.ps1`
  queda en 0 y ya solo puede quedarse ahí.
- Cuatro fachadas eliminadas: `inLibFacturasRepositorio` y
  `inLibCajaConsultasRepositorio` (cero consumidores),
  `inLibArticulosValidador` y `inLibArticulosAtributosLookup` (alias de
  tipo más factorías; 35 consumidores migrados a `*Intf` y a los
  repositorios `UniData*`).
- `inLibFacturasComposicion` y `inLibCajaOpeComposicion` reciben los
  adaptadores ya construidos en vez de fabricarlos.
- `inLibColumnasDocumento` pasa a un contrato (`IAnfitrionDatosDocumento`)
  e `inLibGridColumnChooser` pierde un `uses` de `UniDataConn` que
  estaba **muerto**.

El hallazgo más importante no estaba en el recuento: **cinco units
`inLib*` más** (`inLibFotos`, `inLibGridArticulos`,
`inLibGridPivoteVenta`, `inLibColumnasSkuModoSku`,
`inLibColumnasSkuModoTallas`) construían repositorios llamando a
`CrearValidadorArticulosBase` / `CrearLookupAtributosArticulosBase`. No
aparecían en ningún trinquete porque la fachada `inLib*` les escondía el
`uses UniData*`. Ahora exigen inyección con error explícito.

La regla está promovida a §14.1 y a la lista negra de §16. Detalle en
`DESARROLLOS EN CURSO/refactorizacion_capas_inlib_unidata_resultados.md`.

### 3.4 OCP — Urgencia MEDIA. Las familias compra/venta están duplicadas

| Par                                       | Métodos comunes |
|-------------------------------------------|-----------------|
| `inMtoAlbaranes` / `inMtoAlbaranesCompra` | 20 (40 %)       |
| `inMtoPedidos` / `inMtoPedidosCompra`     | 21 (39 %)       |

Cerca de 9.000 líneas donde compra y venta divergen en tabla, campos y
signo del stock pero comparten el flujo. Añadir un tipo de documento hoy
significa copiar un formulario. Sigue pospuesto a la Fase 5: sin la
Fase 3 no hay donde apoyar la unificación.

Ojo: `inLibGridPivoteVenta` / `inLibGridPivoteCompra` solo comparten un
9 % de nombres. Ahí **no** se unifica (§14.6).

### 3.5 LSP — Urgencia MEDIA-BAJA, pero creciente

Cadena real: `TfrmBase` → `TfrmMtoGen` (fan-in 52) →
`TfrmMtoFacturasBase` → descendientes. 51 clases heredan de `TfrmMtoGen`
métodos que no todas honran; cada hook sobreescrito para "no hacer nada"
es una violación de LSP. La barrera es de crecimiento: los topes de
`comprobar_tamano_clases.ps1` impiden ampliar las bases, y §14.5 obliga
a decidir colaborador/estrategia antes de tocar `TfrmMtoGen`.

### 3.6 ISP — Residual de la Fase 4

Con `Supports` domado (5 fuera de lista blanca, objetivo 0), queda
partir los contratos gordos midiendo por consumidor:
`IEscritorHojaCalculo` (14 métodos), `IModoEntradaGrid` (12 + 4
propiedades), `IFiltrosGuardados` (11), `IPerfilesUsuario` (10).
`IAnfitrionMantenimiento` ya está delgado y no se toca.

### 3.7 Higiene residual — barato, cerrarlo pronto

- **Fachada `inLibMsg`**: 60 consumidores pendientes de migrar a los
  nueve catálogos y eliminarla (anotado en `ISSUES PENDIENTES.txt`).
  8.513 líneas que desaparecen enteras al retirarla.
- **`inMtoCatalogoPantallas`**: fan-out 101, intacto. Se resuelve en la
  Fase 6 con auto-registro.
- **Fan-in con cuerpo**: `inLibUser` 84, `inLibLog` 81, `inLibWin` 49.
  Separar contrato de implementación (Fase 6).

---

## 4. Fases

El orden ha cambiado respecto al plan del 29/07: la 1 está cerrada y la
decisión de capas (2b) se intercala porque es barata y congela un
problema que hoy crece sin vigilancia. Las fases 2 y 3 avanzan en
paralelo por dominios en cuanto el piloto esté rodado.

---

### Fase 2 — Repositorios: sacar el SQL del dominio (EN CURSO, prioridad máxima)

**Idea:** `inLib*` deja de conocer UniDAC y el esquema. Recibe el
contrato de persistencia por constructor; la implementación vive en
`UniData*` y la raíz de composición la inyecta.

**Acciones**

1. **Piloto de sesiones de compra terminado.** El contrato
   (`IRepositorioComprasSesiones`) lo consume
   `TServicioComprasSesiones`; la implementación
   (`UniDataComprasSesionesRepositorio`) se inyecta desde el formulario
   y `UniDataComprasSesiones` ha salido de las fachadas de dominio.
   - Lecturas primero. Los tipos que cruzan la frontera son `record`,
     nunca `TDataSet`.
   - Pruebas DUnitX del dominio con repositorio falso en memoria,
     sin BBDD.
2. **Límite transaccional de compras terminado.**
   `IUnidadTrabajoMaterializacion` demuestra confirmación única,
   rollback y reutilización de una transacción activa.
   `comprobar_sql_transacciones.ps1` vigila el orquestador.
3. **Materialización de sesiones de compra terminada.** Las 3.042
   líneas de la unidad procedural se reparten por responsabilidad; la
   fachada queda en 189/12 y el orquestador no conoce UniDAC. Resultado
   y reducción posterior en el anexo SRP.
4. **`inLibVerifactuCola` tras contrato, terminado.**
   La fachada queda sin UniDAC ni SQL, con dobles sin BBDD; el adaptador
   y su plan de reducción están en el documento de resultados.
   `PruebasEmisionFiscal`, `PruebasRectificativas` y la batería completa
   pasaron en Release Win32 + Win64. La revalidación global del árbol
   concurrente queda pendiente por la ausencia ajena de
   `inLibMsgRegistroTraducciones.pas`.
5. Repetir el patrón por densidad. `inLibAlbaranesCompraMovimientos`
   `inLibPedidosCompra`, `inLibVentasWsJson` e
   `inLibDevolucionesCompraMovimientos` ya están cerrados; queda
   `inLibArticulosVariaciones`.
6. `inLibFotos`, `inLibGridPivoteCompra` y `inLibColumnasSkuModoTallas`
   son infraestructura, no dominio: basta aislar su SQL tras un contrato
   propio, sin forzar `record` de negocio.
7. **Regla para el trinquete:** ninguna unit `inLib*` **nueva** contiene
   SQL literal. Las existentes solo bajan
   (`comprobar_sql_en_dominio.ps1`, topes 469/71).

**Criterio de salida:** sentencias SQL en `inLib*` ≤ 250 y units con SQL
≤ 40; al menos 5 dominios con pruebas DUnitX que corren sin conexión.

---

### Fase 2b — Sellar la dirección de capas (COMPLETADA)

1. `comprobar_dependencias_capas.ps1` cuenta `inLib*` → `UniData*`.
   Hecho: cubre las dos direcciones, tope 0.
2. Opción A decidida y ejecutada; regla promovida a §14.1 y §16.
3. `inLibColumnasDocumento` e `inLibGridColumnChooser` corregidos.

**Criterio de salida cumplido:** el script cubre ambas direcciones y el
tope de `inLib*`→`UniData*` está en 0, sin lista blanca.

### Fase 3 — Descuartizar las clases-dios (esfuerzo: alto)

Los seis formularios de §3.2 más las clases-dios de librería. Topes
monotónicos vigentes: 4.075 líneas / 133 métodos / 49 campos; cada
fascículo de extracción baja al menos uno y ninguno vuelve a subir.

Para las clases-dios de librería manda el
[anexo SRP de librerías](<DESARROLLOS EN CURSO/plan_srp_clases_dios_libreria.md>):
instrumentación por clase y unidad procedural, fascículos C/V/T y
pruebas funcionales por consumidor.

**Método por formulario** (un fascículo por cambio revisable):

1. Inventariar los métodos por responsabilidad: cálculo, impresión,
   búsqueda, validación, stock, cobros/pagos, navegación, permisos y
   exportación.
2. Extraer primero la responsabilidad cohesiva de mayor tamaño que no
   necesite controles. La pieza de dominio recibe contratos y datos
   simples; no conoce VCL, DevExpress, UniDAC ni el formulario.
3. Lo estrictamente visual va a un colaborador de presentación: puede
   recibir vistas o controles, pero no contiene SQL ni decide negocio.
4. La coordinación queda en el formulario. El resultado vuelve como
   `record`, interfaz o callback tipado, sin cast al formulario.
5. Fijar el comportamiento antes de moverlo: cada regla extraída añade
   DUnitX sin BBDD.
6. No se crean clases para alcanzar una cuota: un `TGestor*` nuevo debe
   tener responsabilidad, consumidor y ciclo de vida explícitos.

**Orden sugerido** (cruza con la Fase 2 para rendir doble):

| # | Unidad                   | Primera responsabilidad | Riesgo |
|---|--------------------------|-------------------------|--------|
| 1 | `inMtoComprasSesiones`   | creación/materialización (tras el piloto de Fase 2) | transacciones |
| 2 | `inMtoFacturasBase`      | fiscalidad, recibos y consolidación | Verifactu |
| 3 | `inMtoCajaOpe`           | resolución de venta y escáner | caja activa |
| 4 | `inMtoArticulos`         | altas SKU y atributos básicos | alto reuso |
| 5 | `inMtoStockConsulta`     | consulta, pivote y tarjetas | presentación |
| 6 | `inMtoInventarios`       | resolución de entradas y líneas | stock |

**Criterio de salida:** los seis formularios por debajo de 2.000 líneas
y 120 métodos; los topes individuales solo bajan y se comprueban en la
compilación Release/Win64. Las clases y unidades de librería cumplen
además los límites específicos y el cero SQL definidos en el anexo.

---

### Fase 4 — Cierre de inyección explícita e ISP (esfuerzo: medio)

El arranque está hecho (ver §2). Queda:

1. Bajar el tope de `comprobar_supports.ps1` de 5 a 0: los 3 capability
   checks de `ShowMto` / `InternalCloseForm` y el modal `GenImpEle`
   pasan a resolución en creación o a un contrato explícito.
2. Partir los contratos gordos por consumidor real:
   `IEscritorHojaCalculo` (14) → escritura de celdas vs formato vs
   guardado; `IModoEntradaGrid` (12+4); `IFiltrosGuardados` (11);
   `IPerfilesUsuario` (10).

**Criterio de salida:** `Supports()` fuera de lista blanca = 0; ningún
consumidor obligado a implementar métodos que no usa.

---

### Fase 5 — OCP: una sola familia de documentos (esfuerzo: alto)

Solo abordable después de la Fase 3, con `inMtoFacturasBase` adelgazado.

1. `TConfiguracionDocumento` como `record`: tablas, prefijos, signo del
   stock, contador, serie, asiento, Verifactu.
2. `IEstrategiaDocumento` para lo que de verdad difiere: precios,
   impuestos, movimiento de stock y numeración.
3. Migrar en orden: `Albaranes` (40 % de solape) → `Pedidos` (39 %) →
   `Facturas` → `Devoluciones`.
4. **No tocar** los grids pivote (9 % de solape, §14.6).
5. Fachada temporal en las units antiguas, anotada en
   `ISSUES PENDIENTES.txt`, eliminada al migrar el último consumidor.

**Criterio de salida:** un tipo de documento nuevo = una configuración
y, como mucho, una estrategia. Nunca un formulario copiado.

---

### Fase 6 — Optimización (esfuerzo: medio)

**Compilación y arranque**

1. Retirar la fachada `inLibMsg`: migrar los 60 `uses` restantes por
   tandas a los catálogos de dominio y borrar la unidad (8.513 líneas).
2. `inMtoCatalogoPantallas` (fan-out 101) pasa a auto-registro: cada
   `inMto*` se registra en su `initialization` sobre
   `inLibRegistroPantallas`, manteniendo la referencia de clase
   verificada por el compilador. `ComprobarRegistradas` sigue avisando
   en el arranque.
3. Trocear los fan-in altos con cuerpo (`inLibUser` 84, `inLibLog` 81,
   `inLibWin` 49): contrato `*Intf` estable separado de la
   implementación.
4. Los 99,7 MB de `fzam.exe`: revisar símbolos de depuración, RTTI y
   enlace de paquetes DevExpress. Configuración, no arquitectura, pero
   afecta a despliegue y arranque.

**Ejecución (MariaDB / UniDAC)** — con los repositorios de la Fase 2 el
SQL queda concentrado y por fin auditable:

5. Detectar N+1 (bucles que abren consulta por fila) → `JOIN` o carga
   previa en `record`.
6. `Prepared := True` y reutilización de `TUniQuery` en bucles calientes
   (materialización de compras, movimientos, tira de tickets).
7. Revisar `SELECT *` sobre tablas anchas; pedir columnas.
8. Contrastar los `WHERE` reales contra índices con `EXPLAIN`; los que
   falten, como script idempotente en `DESARROLLOS EN CURSO/` (reglas
   duras 1 y 2 de `CLAUDE.md`).
9. Revisar `AfterPost` / `BeforePost` que encadenan escrituras (§14.7).

**Criterio de salida:** fan-out máximo ≤ 40; `inLibMsg` eliminada;
tiempos de build y arranque medidos antes/después; consultas calientes
sin `type = ALL` sobre tablas grandes.

---

## 5. Patrones de referencia

### 5.1 Repositorio tras contrato (Fase 2)

Contrato — sin UniDAC, sin VCL, sin DevExpress:

```pascal
unit inLibComprasSesionesIntf;
interface
type
  TLineaSesionCompra = record
    CodigoArticulo: string;
    Cantidad: Currency;
    PrecioCoste: Currency;
    EsBaja: Boolean;
  end;
  TLineasSesionCompra = TArray<TLineaSesionCompra>;
  IRepositorioComprasSesiones = interface
    ['{PONER-GUID-AQUI}']
    function CargarLineas(const ACodigoSesion: string):
                                              TLineasSesionCompra;
    procedure GuardarLineas(const ACodigoSesion: string;
                            const ALineas: TLineasSesionCompra);
    function ExisteSesion(const ACodigoSesion: string): Boolean;
  end;
implementation
end.
```

El dominio consume el contrato y no sabe que hay una BBDD detrás:

```pascal
constructor TMaterializadorCompras.Create(
  const ARepositorio: IRepositorioComprasSesiones);
begin
  inherited Create;
  FRepositorio := ARepositorio;
end;
```

En pruebas se inyecta un `TRepositorioComprasSesionesMemoria`. Sin
conexión, sin fixture de BBDD.

### 5.2 Colaborador extraído (Fase 3)

El molde ya está escrito: `inLibGestorFiltrosMto.pas`. Dependencias por
constructor, callbacks tipados y `record` de resultado. Ningún cast al
formulario. **Copiar esa estructura literalmente** para cada colaborador
nuevo.

### 5.3 Descubrir una vez, no en cada método (Fase 4)

```pascal
{ En la creación de la clase base — una sola vez }
procedure TfrmBase.ResolverServicios;
begin
  inherited;
  if not Supports(Self.Owner, IAnfitrionMantenimiento, FAnfitrion) then
    raise EServicioNoDisponible.Create(SAnfitrionMtoNoDisponible);
end;
```

En el resto de la clase se usa `FAnfitrion`. Nunca se vuelve a llamar a
`Supports`.

### 5.4 Configuración + estrategia (Fase 5)

```pascal
type
  TConfiguracionDocumento = record
    TablaCabecera: string;
    TablaLineas: string;
    SufijoCabecera: string;
    SufijoLineas: string;
    SignoStock: Integer;      { +1 entrada, -1 salida }
    EsCompra: Boolean;
    EmiteVerifactu: Boolean;
  end;
```

Un tipo de documento nuevo = una constante de configuración. Si además
cambia una regla, una implementación de `IEstrategiaDocumento`. Nunca un
formulario copiado.

---

## 6. Trinquetes: métrica, tope actual, objetivo

Ninguna cifra puede subir. El script correspondiente falla el build.

| Métrica                                  | Tope hoy | Fase | Objetivo |
|------------------------------------------|----------|------|----------|
| `var` en sección `interface`             | 0        | ✔    | 0        |
| `except` vacíos                          | 0        | ✔    | 0        |
| Infracciones `inLib*`→`inMto*`           | 0        | ✔    | 0        |
| `inLib*`→`UniData*`                      | 0        | ✔    | 0        |
| Sentencias SQL en `inLib*`               | 223      | 2    | ≤ 250    |
| Units `inLib*` con SQL                   | 59       | 2    | ≤ 40     |
| Líneas por clase                         | 4.075    | 3    | ≤ 2.000  |
| `TfrmMtoComprasSesiones` — líneas        | 3.634    | 3    | ≤ 2.000  |
| Métodos por clase                        | 133      | 3    | ≤ 120    |
| Campos por clase                         | 49       | 3    | solo baja|
| Líneas de unit procedural vigilada       | 3.042    | 3    | ≤ 1.200  |
| Rutinas de unit procedural vigilada      | 75       | 3    | ≤ 30     |
| Métodos > 200 líneas                     | 38       | 3    | ≤ 10     |
| `Supports()` fuera de lista blanca       | 5        | 4    | 0        |
| Fan-in de `inLibMsg`                     | 60       | 6    | 0 (unidad eliminada) |
| Fan-in con cuerpo                        | 84       | 6    | solo baja|
| Fan-out máximo por unidad                | 101      | 6    | ≤ 40     |
| Units de prueba DUnitX                   | 44       | 2-3  | ≥ 50     |

---

## 7. Riesgos y reglas de no regresión

1. **No hacer big bang.** Un fascículo por commit. Si un commit toca más
   de dos units de producción, probablemente sea dos commits. La
   velocidad de la Fase 1 fue posible porque era mecánica; las fases 2 y
   3 no lo son.
2. **No mezclar formato con estructura.** Un refactor no reindenta.
3. **Fachadas temporales con fecha de caducidad.** Toda fachada se anota
   en `ISSUES PENDIENTES.txt` con la unidad que la sustituye y no recibe
   lógica nueva (§14.6).
4. **La red primero.** Si un flujo no tiene prueba, la prueba se escribe
   *antes* de tocarlo, aunque solo fije el comportamiento actual.
5. **Escrituras solo con transacción y rollback probado.** Ninguna
   materialización migra a repositorio sin límites transaccionales
   fijados y prueba de rollback (§14.7, SQL-2.3b).
6. **No introducir dependencias nuevas.** Los repositorios envuelven
   UniDAC; no lo sustituyen.
7. **Verifactu y caja son zona fiscal.** Cualquier fascículo que toque
   `inLibVerifactu*` o `inMtoCajaOpe` se valida además contra
   `PruebasEmisionFiscal`, `PruebasRectificativas` y `PruebasCajaVenta`,
   en Release Win32 + Win64.
8. **Cuidado con unificar lo que solo se parece.** El 9 % de solape de
   los grids pivote es la señal: si el modelo difiere, se comparte solo
   el núcleo común.

---

## 8. Arranque: los próximos doce commits

Ordenados para que cada uno sea pequeño, verificable y deje algo medido.

1. ~~`comprobar_dependencias_capas.ps1` cuenta `inLib*`→`UniData*`.~~
   **Hecho**, tope 0.
2. ~~Decisión de capas promovida a §14.1.~~ **Hecho**: Opción A, con
   `inLibColumnasDocumento` e `inLibGridColumnChooser` tras contrato.
3. `inLibComprasSesiones` consume `IRepositorioComprasSesiones` en
   lecturas; `UniDataComprasSesiones` sale del `uses` de `interface`.
4. Pruebas DUnitX del dominio de compras con
   `TRepositorioComprasSesionesMemoria`, sin BBDD.
5. Límites transaccionales de materialización fijados + prueba de
   rollback (amplía `comprobar_sql_transacciones.ps1` si hace falta).
6. `inLibComprasSesionesMaterializar`: primera operación de escritura
   tras el contrato, transaccional e idempotente.
7. `inLibVerifactuCola` tras contrato; las baterías fiscales pasaron en
   Release Win32 + Win64. Revalidación global pendiente por la unidad
   concurrente `inLibMsgRegistroTraducciones.pas` ausente.
8. `inLibAlbaranesCompraMovimientos` tras contrato.
9. `inLibPedidosCompra` tras contrato; sus 28 sentencias viven en
   `UniDataPedidosCompraOperaciones`.
10. `inLibVentasWsJson` tras contrato; sus 17 sentencias viven en
    `UniDataVentasWsJson`.
11. `inLibDevolucionesCompraMovimientos` tras contrato; sus 9
    sentencias viven en `UniDataDevolucionesCompraMovimientos`.
12. Fachada `inLibMsg`: primera tanda de migración de `uses` (60 → ~40).
13. ~~Fase 3, fascículo 1: `inMtoComprasSesiones`.~~ **Hecho**: las
    reglas de creación salen a `inLibComprasSesionesCreacion` con 18
    pruebas sin BBDD; la clase baja de 3.669 a 3.634 líneas.
14. Fase 3, fascículo 2: `inMtoFacturasBase` extrae reglas fiscales y
    recibos a colaborador con pruebas.
15. ISP: partir `IEscritorHojaCalculo` por consumidor real.

A partir de aquí las fases 2 y 3 avanzan en paralelo por dominios.

---

## 9. Qué promover al libro de estilo cuando el plan avance

La Fase 1 está cerrada: sus reglas se promueven **ya**.

- Fase 1 (ya) → §14.3: *"los textos de UI son `resourcestring`, nunca
  `var`"*; y a §16: `var` en sección `interface`.
- Fase 2 → §14.7: *"una unit `inLib*` nueva no contiene SQL literal; la
  persistencia entra por contrato"*.
- ~~Fase 2b → §14.1~~: **promovido**. Opción A, doble dirección
  vigilada por script y cuatro entradas nuevas en la lista negra.
- Fase 3 → §14.5: topes de 2.000 líneas / 120 métodos por clase.
- Fase 4 → §14.2: *"`Supports` solo en inicialización; el resultado se
  guarda en un campo"*.
- Fase 5 → §14.6: configuración + estrategia como vía única para un tipo
  de documento nuevo.
- Fase 6 → §14.1: auto-registro de pantallas en `initialization`.

Y a §16 (lista negra), según se cierren: `Supports` dentro de un método
de negocio, SQL literal en `inLib*` nueva, formulario de documento
copiado de otro, `inLib*` que usa `UniData*` fuera de la regla de
composición elegida.
