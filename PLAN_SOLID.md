# PLAN_SOLID — Hoja de ruta de desacoplamiento y optimización

Plan de ejecución para llevar Factuzam a un cumplimiento real de SOLID.
No sustituye a `LIBRO_DE_ESTILO_DELPHI.md` §14: **lo ejecuta**. El libro
de estilo dice *cómo debe quedar el código*; este documento dice *en qué
orden llegar hasta ahí, con qué métrica y con qué criterio de parada*.

Fecha de la línea base: 29/07/2026.

---

## 0. Premisa

El proyecto **no** parte de cero en arquitectura. Ya hay dirección de
capas documentada y verificada, contratos propios, colaboradores
`TGestor*`, red DUnitX y scripts de trinquete. El problema no es
*"no hay diseño"*, es que **el diseño nuevo convive con un núcleo
legado que concentra casi toda la masa del proyecto**.

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
renombrados masivos.

---

## 1. Línea base medida

Medido sobre `src/`, excluyendo `3rdpartyComp`, `vcl`, `vcl37`, las
carpetas de pruebas sueltas y los proyectos utilitarios independientes.

| Métrica                                          | Hoy     |
|--------------------------------------------------|---------|
| Units propias                                    | 457     |
| Líneas de código propio                          | 261.397 |
| Métodos detectados                               | 6.759   |
| Métodos > 80 líneas                              | 299     |
| Métodos > 120 líneas                             | 122     |
| Métodos > 200 líneas                             | 30      |
| Infracciones de dirección de capas               | 2       |
| Units `inLib*` que construyen SQL                | 79      |
| Sentencias SQL literales dentro de `inLib*`      | 471     |
| Llamadas `Supports(...)` como resolución         | 75      |
| `except` en el código                            | 403     |
| `except` aparentemente vacíos                    | 55      |
| Variables globales en sección `interface`        | 1.516   |
| ... de ellas en `inLibMsg`                       | 1.413   |
| `resourcestring` en todo el proyecto             | 5       |
| Contratos `I*` propios                           | 70      |
| Units de contratos `inLib*Intf.pas`              | 19      |
| Units de pruebas DUnitX                          | 30      |
| Tamaño de `fzam.exe`                             | 99,7 MB |

### 1.1 Acoplamiento eferente (fan-out): units que arrastran el proyecto

| Units usadas | Líneas | Métodos | Unidad                  |
|--------------|--------|---------|-------------------------|
| 101          | 233    | 0       | `inMtoCatalogoPantallas`|
| 69           | 2.580  | 171     | `inMtoPrincipal`        |
| 36           | 4.094  | 217     | `inMtoFacturasBase`     |
| 32           | 2.170  | 206     | `inMtoGen`              |
| 28           | 4.164  | 209     | `inMtoCajaOpe`          |
| 27           | 2.918  | 189     | `inMtoPedidosCompra`    |
| 26           | 2.597  | 190     | `inMtoDevolucionesCompra`|
| 25           | 3.495  | 196     | `inMtoArticulos`        |
| 25           | 3.840  | 202     | `inMtoComprasSesiones`  |

### 1.2 Acoplamiento aferente (fan-in): units que paralizan la compilación

| Units que la usan | Unidad            |
|-------------------|-------------------|
| 197               | `inLibMsg`        |
| 84                | `inLibUser`       |
| 67                | `inLibLog`        |
| 56                | `inMtoFrmBase`    |
| 52                | `UniDataGen`      |
| 52                | `inMtoGen`        |
| 49                | `inLibWin`        |
| 43                | `inLibParametrosIntf` |

Solo `inLibParametrosIntf` es un fan-in *sano*: es un contrato estable
sin implementación. Los otros siete son unidades con cuerpo que
recompilan medio proyecto cuando se tocan.

---

## 2. Lo que ya está resuelto — no reabrir

Estas decisiones están tomadas, verificadas y **no entran en el plan**:

- **Dirección de dependencias** (§14.1): solo 2 infracciones vivas, ambas
  en `inLibCajaOpeComposicion.pas` (usa `inMtoCajaImpresorVenta` y
  `inMtoCajaGrabadorVenta`). Se cierran en la Fase 1 y el script sigue
  siendo la barrera.
- **Registro de pantallas por referencia de clase**, verificado por el
  compilador. Correcto.
- **Red DUnitX** con 30 units de prueba y fixtures sin BBDD real.
- **Cuatro scripts de trinquete** en `scripts/`, con tope explícito
  (`MaximoMetodosMayoresDe200 = 42`). El mecanismo es el correcto; solo
  hay que ampliar la cobertura de métricas.
- **UniDAC como acceso a datos.** No se sustituye. El plan lo *envuelve*,
  no lo reemplaza.

---

## 3. Diagnóstico por principio, con evidencia

Ordenado por urgencia real, no por el orden del acrónimo.

### 3.1 SRP — Urgencia ALTA. Es el cuello de botella de todo lo demás

Seis formularios concentran la lógica de negocio del producto:

| Unidad                  | Líneas | Métodos | Campos `F*` |
|-------------------------|--------|---------|-------------|
| `inMtoCajaOpe`          | 4.164  | 209     | 47          |
| `inMtoFacturasBase`     | 4.094  | 217     | 19          |
| `inMtoComprasSesiones`  | 3.840  | 202     | 38          |
| `inMtoArticulos`        | 3.495  | 196     | 18          |
| `inMtoStockConsulta`    | 3.349  | 175     | 46          |
| `inMtoInventarios`      | 3.142  | 161     | 24          |

Una clase con 209 métodos y 47 campos no tiene "una razón para cambiar":
tiene cuarenta. Y como es un `TForm`, **nada de eso se puede probar sin
levantar la VCL**. Este es el motivo por el que las otras violaciones no
se pueden atacar primero: no hay dónde apoyarse.

El patrón de salida ya existe y funciona: `TGestorFiltrosMto`,
`TGestorArticulosMto`, `TGestorGuiasGridMto`, `TGestorPerfilesMto`,
`TGestorTareasMto` — cinco colaboradores con dependencias por
constructor y callbacks tipados en vez de conocer al formulario. **Falta
escalarlo**, no inventarlo.

### 3.2 DIP — Urgencia ALTA. El dominio habla SQL

79 units `inLib*` construyen 471 sentencias SQL literales. Según §14.1
`inLib*` es *"dominio y colaboradores"*, pero en la práctica es también
capa de persistencia: conoce UniDAC, conoce nombres de tabla y conoce el
esquema.

Consecuencias medibles:

- El dominio **no se puede probar sin BBDD**, lo que choca de frente con
  §14.9 ("los fixtures no dependen de una BBDD real").
- Un cambio de esquema se propaga a 79 units en vez de a un puñado.
- Los 19 `*Intf.pas` cubren servicios transversales (parámetros,
  conexiones, permisos, sesión, monitor SQL) pero **ninguno es un
  repositorio de un agregado de negocio**. Ese es el hueco exacto.

Peores focos: `inLibComprasSesiones` (32), `inLibVerifactuCola` (26),
`inLibComprasSesionesMaterializar` (24), `inLibAlbaranesCompraMovimientos`
(23), `inLibColumnasSkuModoTallas` (20), `inLibFotos` (20).

### 3.3 DIP/ISP — Urgencia MEDIA. `Supports()` es un localizador de servicios

75 usos de `Supports(...)`, 19 solo en `inMtoFrmBase`. §14.2 lo bendice
como mecanismo de propagación por el árbol de propietarios, y es cierto
que **no es un singleton global**. Pero tiene los tres defectos clásicos
del localizador:

1. Las dependencias de una clase **no son visibles en su firma**. Hay que
   leer el cuerpo para saber qué necesita.
2. El fallo es **en runtime**, no en compilación: si el `Owner` cambia o
   la pantalla se abre embebida, `Supports` devuelve `False` y la rama
   silenciosa se traga el caso.
3. En pruebas hay que **fabricar un árbol de propietarios falso** para
   probar una regla de negocio.

No hay que eliminarlo — hay que **acotarlo**: `Supports` es aceptable en
las clases base para *descubrir* el servicio una sola vez, en creación, y
guardarlo en un campo. Nunca a mitad de un método de negocio.

### 3.4 OCP — Urgencia MEDIA. Las familias compra/venta están duplicadas

| Par                                          | Métodos comunes |
|----------------------------------------------|-----------------|
| `inMtoAlbaranes` / `inMtoAlbaranesCompra`    | 20 (40 %)       |
| `inMtoPedidos` / `inMtoPedidosCompra`        | 21 (39 %)       |

Cerca de 9.000 líneas de formularios de documento donde compra y venta
divergen en tabla, campos y signo del movimiento de stock, pero comparten
el flujo. Añadir un tipo de documento hoy significa **copiar un
formulario**, que es exactamente lo contrario de OCP.

Ojo: `inLibGridPivoteVenta` / `inLibGridPivoteCompra` solo comparten un
9 % de nombres. Ahí **no** hay que unificar: son modelos distintos, y
§14.6 ya avisa de no fusionar lo que solo se parece.

### 3.5 LSP — Urgencia MEDIA-BAJA, pero creciente

Cadena real: `TfrmBase` → `TfrmMtoGen` (206 métodos, fan-in 52) →
`TfrmMtoFacturasBase` (217 métodos) → descendientes concretos.

51 clases descienden de `TfrmMtoGen` y heredan 206 métodos que **no
todas honran**. Cada hook que un descendiente sobreescribe para "no hacer
nada" o para desactivar comportamiento del ancestro es una violación de
LSP en toda regla. §14.5 ya lo dice ("las clases base no son el destino
automático de todo comportamiento común"); la métrica que falta es
impedir que sigan creciendo.

### 3.6 Higiene — barato y de alto retorno

- **`inLibMsg` declara 1.413 mensajes como `var` de sección `interface`.**
  Es decir: **1.413 variables globales mutables**, justo lo que §16
  prohíbe en su lista negra. Cualquier unidad de las 197 que la usan
  puede reasignar un mensaje en runtime. Deben ser `resourcestring`
  (traducibles, inmutables) o `const`. Hoy solo hay 5 `resourcestring` en
  todo el proyecto.
- **55 `except` aparentemente vacíos** de 403. Cada uno es un fallo
  convertido en éxito silencioso — §14.7 y §16 lo prohíben.
- **~99 units conservan una variable global de formulario/data module**
  (`frmXxx: TfrmXxx;`), la que genera el IDE. Legado, pero es la puerta
  de entrada a que alguien la use.
- **`inMtoCatalogoPantallas` arrastra 101 units.** Es la unidad más
  acoplada del proyecto y toca en cada pantalla nueva.

---

## 4. Fases

Seis fases. Cada una tiene objetivo, acciones sobre ficheros reales y
**criterio de salida medible**. Las fases 1 y 2 pueden solaparse; el
resto es secuencial porque cada una se apoya en la anterior.

---

### Fase 0 — Instrumentar (esfuerzo: bajo)

No se toca código de producción. Se hace visible el estado.

**Acciones**

1. Añadir cuatro scripts en `scripts/`, mismo estilo que los existentes
   (parámetro `$Raiz`, tope numérico, salida no-cero al superarlo):
   - `comprobar_tamano_clases.ps1` — líneas, métodos y campos por clase.
   - `comprobar_sql_en_dominio.ps1` — sentencias SQL literales dentro de
     `src/Lib` y `src/Caja/Lib`.
   - `comprobar_acoplamiento.ps1` — fan-out por unidad y fan-in de las
     unidades con cuerpo.
   - `comprobar_estado_global.ps1` — `var` en sección `interface` y
     `except` vacíos.
2. Congelar los topes con los valores de §1 (trinquete: solo bajan).
3. Encadenarlos en `compilar_release_win64.cmd` o en el hook de commit
   que ya se use.

**Criterio de salida:** los cuatro scripts pasan en verde contra la línea
base actual y fallan si se les baja el tope a mano.

---

### Fase 1 — Higiene de alto retorno (esfuerzo: bajo, impacto: alto)

Cambios mecánicos, verificables, sin riesgo de diseño. Ganan credibilidad
y desbloquean la compilación incremental.

**Acciones**

1. **`inLibMsg`: `var` → `resourcestring`.** 1.413 declaraciones. Es
   sustitución mecánica salvo donde el valor se compone con `+` en
   tiempo de declaración (`resourcestring` admite concatenación de
   literales, así que la mayoría pasa tal cual). Beneficio doble: elimina
   1.413 globales mutables y habilita traducción vía recursos.
2. **Trocear `inLibMsg` por dominio.** Con fan-in 197, tocar un mensaje
   recompila 197 units. Partir en `inLibMsgComun`, `inLibMsgFacturas`,
   `inLibMsgCaja`, `inLibMsgCompras`, `inLibMsgVerifactu`… dejando
   `inLibMsg` como fachada temporal de migración (§14.6) que se elimina
   cuando el último consumidor migre.
3. **Cerrar las 2 infracciones de capa** de `inLibCajaOpeComposicion`:
   declarar `IImpresorVenta` e `IGrabadorVenta` en un `inLib*Intf` y que
   `inMtoCajaImpresorVenta` / `inMtoCajaGrabadorVenta` los implementen y
   se registren desde la raíz de composición.
4. **Los 55 `except` vacíos**, uno a uno, con tres salidas posibles:
   propagar, registrar contexto y propagar, o devolver un resultado que
   el llamador debe atender. Ninguno se queda mudo.
5. **Eliminar las variables globales `frmXxx` / `dmXxx`** que ya no tenga
   consumidores (la mayoría son residuo del IDE).

**Criterio de salida:** `var` en sección `interface` = 0.
`except` vacíos = 0. Infracciones de capa = 0.

---

### Fase 2 — Repositorios: sacar el SQL del dominio (esfuerzo: alto)

Es la fase que más desbloquea. Sin ella, el dominio no es probable y el
resto de fases se quedan a medias.

**Idea:** `inLib*` deja de conocer UniDAC y el esquema. Recibe un
contrato de persistencia por constructor. La implementación concreta vive
en `UniData*` o en un `inLibRepo*`, y la raíz de composición la inyecta.

**Acciones**

1. **Piloto: sesiones de compra.** Es el foco más denso (32 + 24
   sentencias entre `inLibComprasSesiones` e
   `inLibComprasSesionesMaterializar`) y ya tiene pruebas
   (`PruebasBusquedasCompra`, `PruebasValidacionTallasCompra`).
   - Declarar `inLibComprasSesionesIntf.pas` con
     `IRepositorioComprasSesiones`: operaciones de negocio con nombre
     (`CargarSesion`, `MaterializarLineas`, `ExisteTablaTemporal`), no
     métodos genéricos tipo `Ejecutar(const ASql: string)` — eso sería
     mover el acoplamiento, no eliminarlo (ISP).
   - Los tipos que cruzan la frontera son `record`, nunca `TDataSet`.
     Un `TDataSet` en la firma vuelve a atar el dominio a UniDAC.
   - Implementación en `UniDataComprasSesiones`; el dominio pasa a
     funciones puras sobre los `record`.
   - Pruebas DUnitX del dominio **con un repositorio falso en memoria**,
     sin BBDD.
2. Repetir el patrón, en este orden (por densidad y por riesgo fiscal):
   `inLibVerifactuCola` (26) → `inLibAlbaranesCompraMovimientos` (23) →
   `inLibPedidosCompra` (15) → `inLibArticulosResolver` (10) →
   `inLibArticulosVariaciones` (11).
3. `inLibFotos` (20 sentencias, fan-in 31) y `inLibColumnasSkuModoTallas`
   (20) se tratan aparte: son infraestructura, no dominio. Basta con
   aislar su SQL tras un contrato propio.
4. **Regla nueva para el trinquete:** ninguna unit `inLib*` **nueva**
   puede contener SQL literal. Las existentes solo bajan.

**Criterio de salida:** sentencias SQL en `inLib*` ≤ 250 (de 471), y al
menos 5 dominios con pruebas DUnitX que corren sin conexión.

---

### Fase 3 — Descuartizar las clases-dios (esfuerzo: alto)

**Método por formulario** (aplicar en fascículos, uno por commit):

1. Listar los métodos de la clase y agruparlos por *tema*, no por orden.
   Los grupos típicos que aparecen: totales y cálculo, impresión, filtros
   y búsqueda, validación de líneas, stock, cobros/pagos, navegación,
   permisos, exportación.
2. El grupo más grande que **no toque controles VCL** sale primero: es
   una función pura o un colaborador `TGestorXxx`.
3. El colaborador recibe por constructor lo que necesita (contratos,
   vistas concretas, callbacks tipados), **exactamente como
   `TGestorFiltrosMto`**. No conoce al formulario ni hace cast a él.
4. La reacción visual vuelve por callback o por `record` de resultado
   (§14.4), nunca manipulando controles desde abajo.

**Orden de ataque**

| # | Unidad                 | Por qué primero                       |
|---|------------------------|---------------------------------------|
| 1 | `inMtoComprasSesiones` | Ya tiene repositorio de la Fase 2 y pruebas |
| 2 | `inMtoFacturasBase`    | Raíz de la familia; bloquea la Fase 5 |
| 3 | `inMtoCajaOpe`         | 47 campos, el estado más enredado      |
| 4 | `inMtoArticulos`       | Alto reuso desde otras pantallas      |
| 5 | `inMtoStockConsulta`   | 46 campos, mayormente presentación    |
| 6 | `inMtoInventarios`     | El más contenido de los seis          |

**Criterio de salida:** los seis formularios de §3.1 por debajo de 2.000
líneas y 120 métodos; al menos 12 colaboradores `TGestor*` con pruebas
DUnitX propias.

---

### Fase 4 — Inyección explícita en lugar de resolución (esfuerzo: medio)

**Acciones**

1. Regla: `Supports()` **solo** en construcción/inicialización de las
   clases base, y el resultado se guarda en un campo `F*`. Prohibido en
   métodos de negocio.
2. Los colaboradores y librerías reciben los contratos **por
   constructor** (§14.2 ya lo dice para objetos sin propietario; ahora
   pasa a ser la vía por defecto).
3. Cuando la clase base descubre un servicio y no lo encuentra, **falla
   ruidosamente** con una excepción de dominio
   (`EServicioNoDisponible`), no con una rama silenciosa.
4. Revisar la granularidad de los contratos gordos (ISP): si un
   consumidor solo usa 2 de los 15 métodos de `IAnfitrionMantenimiento`,
   se parte el contrato.

**Criterio de salida:** llamadas `Supports()` fuera de constructores e
inicializadores = 0. Ningún `Supports` seguido de rama vacía.

---

### Fase 5 — OCP: una sola familia de documentos (esfuerzo: alto)

Solo es abordable después de la Fase 3, cuando `inMtoFacturasBase` esté
adelgazado.

**Acciones**

1. Definir `TConfiguracionDocumento` como `record`: tabla de cabecera,
   tabla de líneas, prefijos de columna, signo del movimiento de stock,
   contador, serie, si genera asiento, si va a Verifactu.
2. Definir `IEstrategiaDocumento` para lo que **de verdad** difiere entre
   compra y venta: resolución de precios, impuestos, movimiento de stock
   y numeración.
3. Migrar en este orden: `Albaranes` (40 % de solape, el más simple) →
   `Pedidos` (39 %) → `Facturas` → `Devoluciones`.
4. **No tocar** `inLibGridPivoteVenta` / `inLibGridPivoteCompra`: 9 % de
   solape, son modelos distintos (§14.6).
5. Fachada temporal en las units antiguas mientras quede algún consumidor;
   se borra al migrar el último.

**Criterio de salida:** añadir un tipo de documento nuevo no requiere
crear un `TfrmMto*` nuevo, solo una configuración y, como mucho, una
estrategia.

---

### Fase 6 — Optimización (esfuerzo: medio)

Dos ejes: tiempo de compilación y tiempo de ejecución.

**Compilación y arranque**

1. `inMtoCatalogoPantallas` (101 units) pasa a **auto-registro**: cada
   `inMto*` se registra en su propio `initialization` sobre
   `inLibRegistroPantallas`. Se mantiene el registro por referencia de
   clase verificada por el compilador (§15.10) y se elimina la unidad
   más acoplada del proyecto. `ComprobarRegistradas` sigue avisando en el
   arranque de lo que falte en `fza_winforms`.
2. Trocear los fan-in altos con cuerpo (`inLibUser` 84, `inLibLog` 67,
   `inLibWin` 49): separar contrato (`*Intf`) de implementación, para que
   los consumidores dependan del contrato estable.
3. Los 99,7 MB de `fzam.exe` merecen una revisión de opciones de enlace
   (símbolos de depuración, RTTI, paquetes DevExpress enlazados
   completos). Es un problema de configuración, no de arquitectura, pero
   afecta a despliegue y arranque.

**Ejecución (MariaDB / UniDAC)**

4. Con los repositorios de la Fase 2 ya en su sitio, **el SQL queda
   concentrado y por fin es auditable**. Ese es el momento de:
   - Detectar N+1: bucles sobre un dataset que abren otra consulta por
     fila. Sustituir por un `JOIN` o una carga previa en `record`.
   - `Prepared := True` y reutilización de `TUniQuery` en los bucles
     calientes (materialización de compras, generación de movimientos,
     tira de tickets).
   - Revisar `SELECT *` sobre tablas anchas; pedir columnas.
   - Contrastar los `WHERE` reales contra los índices existentes con
     `EXPLAIN`, y añadir los que falten como script idempotente en
     `DESARROLLOS EN CURSO/` (regla dura nº 1 y 2 de `CLAUDE.md`).
5. Revisar los `AfterPost` / `BeforePost` que encadenan escrituras: §14.7
   ya pide delegar en una operación explícita; además suelen ser el
   origen de aperturas repetidas de dataset.

**Criterio de salida:** fan-out máximo por unidad ≤ 40; tiempo de build
completo y tiempo de arranque medidos antes/después; consultas calientes
con `EXPLAIN` sin `type = ALL` sobre tablas grandes.

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
constructor, callbacks tipados
(`TSolicitarDatosFiltroMto`, `TEjecutarGestionFiltroMto`) y `record` de
resultado (`TResultadoGestionFiltroMto`). Ningún cast al formulario.
**Copiar esa estructura literalmente** para cada colaborador nuevo.

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

## 6. Trinquetes: métrica, hoy, objetivo

Ninguna cifra puede subir. El script correspondiente falla el build.

| Métrica                                  | Hoy   | Fase | Objetivo |
|------------------------------------------|-------|------|----------|
| `var` en sección `interface`             | 1.516 | 1    | 0        |
| `except` vacíos                          | 55    | 1    | 0        |
| Infracciones de capa                     | 2     | 1    | 0        |
| Sentencias SQL en `inLib*`               | 471   | 2    | ≤ 250    |
| Units `inLib*` con SQL                   | 79    | 2    | ≤ 40     |
| Units > 2.000 líneas *(1)*               | 20    | 3    | ≤ 5      |
| Units > 120 métodos *(1)*                | 19    | 3    | ≤ 5      |
| Métodos > 200 líneas                     | 30    | 3    | ≤ 10     |
| Métodos > 120 líneas                     | 122   | 3    | ≤ 60     |
| `Supports()` fuera de inicialización     | ~60   | 4    | 0        |
| Fan-out máximo por unidad                | 101   | 6    | ≤ 40     |
| Units de prueba DUnitX                   | 30    | 2-3  | ≥ 50     |

*(1)* Excluido el código de terceros vendorizado
(`ts.core.sqlparser`, `ts.core.sqltree`, `DelphiZXIngQRCode`), que no se
refactoriza. `inLibMsg` sale de la lista en la Fase 1 al trocearse.

---

## 7. Riesgos y reglas de no regresión

1. **No hacer big bang.** Un fascículo por commit. Si un commit toca más
   de dos units de producción, probablemente sea dos commits.
2. **No mezclar formato con estructura.** Un refactor no reindenta.
3. **Fachadas temporales con fecha de caducidad.** Toda fachada de
   migración se anota en `ISSUES PENDIENTES.txt` con la unidad que la
   sustituye. La fachada no recibe lógica nueva (§14.6).
4. **La red primero.** Si un flujo no tiene prueba, la prueba se escribe
   *antes* de tocarlo, aunque solo fije el comportamiento actual.
5. **No introducir dependencias nuevas** (§ stack técnico de
   `CLAUDE.md`). Los repositorios envuelven UniDAC; no lo sustituyen.
6. **Verifactu y caja son zona fiscal.** Cualquier fascículo que toque
   `inLibVerifactu*` o `inMtoCajaOpe` se valida además contra
   `PruebasEmisionFiscal`, `PruebasRectificativas` y
   `PruebasCajaVenta`, y en Release Win32 + Win64.
7. **Cuidado con unificar lo que solo se parece.** El 9 % de solape de
   los grids pivote es la señal de aviso: si el modelo difiere, se
   comparte solo el núcleo común.

---

## 8. Arranque: los primeros doce commits

Ordenados para que cada uno sea pequeño, verificable y deje algo medido.

1. `scripts/comprobar_estado_global.ps1` + tope congelado.
2. `scripts/comprobar_sql_en_dominio.ps1` + tope congelado.
3. `scripts/comprobar_tamano_clases.ps1` + tope congelado.
4. `scripts/comprobar_acoplamiento.ps1` + tope congelado.
5. `inLibMsg`: `var` → `resourcestring` (bloque 1 de 3).
6. `inLibMsg`: bloques 2 y 3.
7. Partir `inLibMsg` en `inLibMsgComun` + `inLibMsgFacturas`, dejando
   fachada.
8. Cerrar las 2 infracciones de capa de `inLibCajaOpeComposicion`.
9. `except` vacíos: bloque de `src/Lib` (con prueba por cada rama que
   cambie de comportamiento).
10. `except` vacíos: bloque de `src/Forms` y `src/Caja`.
11. `inLibComprasSesionesIntf` + `TRepositorioComprasSesionesMemoria` +
    pruebas DUnitX sin BBDD (el contrato aún sin consumidores).
12. `inLibComprasSesiones` consume el repositorio; implementación real en
    `UniDataComprasSesiones`.

A partir del commit 12 el patrón está rodado y las fases 2 y 3 avanzan en
paralelo por dominios.

---

## 9. Qué añadir al libro de estilo cuando el plan avance

Al cerrar cada fase, promover su regla a `LIBRO_DE_ESTILO_DELPHI.md`:

- Fase 1 → §14.3: *"los textos de UI son `resourcestring`, nunca `var`"*.
- Fase 2 → §14.7: *"una unit `inLib*` nueva no contiene SQL literal; la
  persistencia entra por contrato"*.
- Fase 3 → §14.5: los topes de 2.000 líneas / 120 métodos por clase.
- Fase 4 → §14.2: *"`Supports` solo en inicialización; el resultado se
  guarda en un campo"*.
- Fase 5 → §14.6: el patrón configuración + estrategia como vía única
  para un tipo de documento nuevo.
- Fase 6 → §14.1: auto-registro de pantallas en `initialization`.

Y añadir a §16 (lista negra): `var` en sección `interface`,
`Supports` dentro de un método de negocio, SQL literal en `inLib*` nueva,
formulario de documento copiado de otro.
