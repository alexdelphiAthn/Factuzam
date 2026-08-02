# PLAN SOLID — prioridades P0–P5

Hoja de ruta vigente para llevar Factuzam a un código que pueda defenderse
en una revisión de ingeniería exigente. El libro de estilo define cómo debe
quedar cada pieza; este plan decide qué corregir primero y cómo demostrar que
la mejora es real.

Estado medido: **02/08/2026**. La auditoría se ha realizado sobre el árbol de
trabajo actual, incluidos sus cambios sin confirmar. Commit de referencia:
`42be12feac6ddde6205c84ae3f53fb343041c3a5`.

Las tareas ejecutables y su reparto sin unidades Pascal concurrentes están en
[`TAREAS_IA_SOLID.md`](TAREAS_IA_SOLID.md).

---

## 1. Veredicto ejecutivo

Factuzam ya tiene una base de ingeniería seria: dirección de capas comprobada,
contratos propios, composición explícita en varios dominios, compilación
Win32/Win64 y 604 pruebas DUnitX que pasan en ambas plataformas. No es un
proyecto sin arquitectura.

Todavía no alcanza P5. Los cinco bloqueos principales son:

1. La comprobación global de calidad está roja por 44 infracciones nuevas de
   codificación y finales de línea.
2. Se ha reducido el acceso directo a datos, pero la UI conserva 35
   `TUniQuery.Create`, 68 asignaciones `SQL.Text`, 18 componentes UniDAC en
   DFM y 5 operaciones transaccionales.
3. Quedan 76 sentencias SQL en 33 unidades `inLib*`. La dirección de capas es
   correcta, pero una parte del dominio todavía conoce la persistencia.
4. El contexto general de repositorios se consulta 148 veces desde 55
   unidades. Sus interfaces individuales son pequeñas, pero el agregado actúa
   como localizador de servicios y permite que cualquier pantalla alcance
   capacidades que no declara.
5. Persisten clases y métodos demasiado grandes: cinco formularios vigilados
   superan 2.000 líneas, hay 101 métodos de más de 120 líneas y 20 de más de
   200.

La prioridad no es añadir más abstracciones. Es cerrar esos cinco huecos sin
perder el comportamiento ya protegido.

---

## 2. Evidencia reproducible

### 2.1 Estado de compilación y pruebas

Ejecutado el 02/08/2026:

- `fzam.dproj`, Release Win32: compila.
- DUnitX Win32: **604/604** pruebas, 0 fallos, 0 errores y 0 fugas.
- `fzam.dproj`, Release Win64: compila.
- DUnitX Win64: **604/604** pruebas, 0 fallos, 0 errores y 0 fugas.
- 87 unidades Pascal de pruebas presentes en `tests/`.

La red de regresión es una fortaleza real. No sustituye pruebas de integración
con MariaDB para adaptadores que escriben varias tablas.

### 2.2 Métricas actuales

| Métrica | Estado actual | Lectura |
|---------|--------------:|---------|
| Unidades analizadas por calidad | 706 | Cobertura amplia del código propio |
| Clases analizadas | 552 | Base suficiente para un trinquete útil |
| Ciclo mayor entre capas | 1 | Sin ciclos entre unidades propias |
| Aristas `inLib* -> UniData*` | 0 | Dirección de dependencia correcta |
| Variables `var` en `interface` | 0 | Cerrado |
| `except` vacíos | 0 | Cerrado |
| Miembros máximos por interfaz vigilada | 10 | ISP sintáctico correcto |
| SQL literal en `inLib*` | 76 en 33 unidades | DIP todavía incompleto |
| Valores externos concatenados en SQL | 0 | Seguridad SQL bien protegida |
| `TUniQuery.Create` en UI | 35 | Persistencia todavía visible en UI |
| `SQL.Text :=` en UI | 68 | Persistencia todavía visible en UI |
| Componentes UniDAC en DFM | 18 | Formularios aún propietarios de datos |
| Transacciones creadas/iniciadas en UI | 5 | Responsabilidad mal ubicada |
| Métodos de más de 120 líneas | 101 | Deuda SRP/Clean Code alta |
| Métodos de más de 200 líneas | 20 | Prioridad de extracción |
| Riesgo acumulado de métodos largos | 23.073 | Trinquete útil, todavía alto |
| Riesgo máximo | 417 | Restauración de copias |
| `Exit` / `Continue` / `with` | 1.062 / 60 / 322 | Deuda de lectura y control de flujo |
| Líneas de más de 80 columnas | 462 | Deuda de formato |
| Tabuladores | 0 | Cerrado |
| Excepciones heredadas de codificación | 542 | Deuda mecánica pendiente |
| Infracciones totales de codificación | 586 | 542 heredadas + 44 nuevas |
| Infracciones nuevas de codificación | 44 | **P0: calidad global roja** |

### 2.3 Concentraciones de riesgo

#### Fan-out

| Unidad | Fan-out |
|--------|--------:|
| `UniDataRepositoriosGeneralesPantalla` | 76 |
| `inMtoFacturasBase` | 64 |
| `inMtoFrmBase` | 63 |
| `inLibRepositoriosPantallaIntf` | 58 |
| `inMtoCajaOpe` | 54 |
| `inMtoPrincipal` | 52 |
| `UniDataComposicionAplicacion` | 47 |
| `UniDataRepositoriosCajaPantalla` | 39 |

`IContextoRepositoriosPantalla` agrupa diez familias de capacidades. El
comprobador de ISP pasa porque cada interfaz hija respeta diez miembros, pero
el diseño completo sigue permitiendo descubrimiento tardío de dependencias.
Es un caso en el que una métrica local verde no basta para declarar resuelto
el principio.

#### Clases grandes

| Clase | Líneas | Métodos | Campos |
|-------|-------:|--------:|-------:|
| `TfrmMtoOpeCaja` | 3.604 | 104 | 35 |
| `TfrmMtoComprasSesiones` | 3.425 | 99 | 28 |
| `TfrmMtoArticulos` | 2.971 | 97 | 16 |
| `TfrmMtoInventarios` | 2.886 | 76 | 13 |
| `TfrmStockConsulta` | 2.219 | 75 | 40 |
| `TdmFacturas` | 2.465 | 71 | 23 |
| `TfrmMtoGen` | 2.135 | 104 | 14 |
| `TfrmMtoPrincipal` | 2.037 | 87 | 21 |

`TfrmMtoFacturasBase` ya baja de 2.000 líneas, pero conserva 104 métodos. Su
`TControladorFacturas` mantiene una referencia al formulario y ejecuta gran
parte del trabajo mediante `with FAnfitrion`; eso desplaza métodos dentro de
la misma unidad, no crea una frontera comprobable.

#### Métodos de mayor riesgo

Los primeros focos medidos son:

- `TRestoreWorker.EjecutarSQLStreaming`: riesgo 417, 275 líneas y 32
  decisiones.
- `ExportarMovVentasArtExcel`: riesgo 409 y 285 líneas.
- `ImprimirTicketDesdeBD`: riesgo 363 y 271 líneas.
- `ExportarDocumentoTrabajoExcel`: riesgo 337 y 285 líneas.
- `TfrmMtoOpeCaja.cxGrid1DBTableView1EditKeyDown`: riesgo 335, 22
  decisiones y 8 salidas en zona de caja.
- `CargarDatosFactura`: riesgo 331 y 261 líneas en zona fiscal.
- `TdmArticulos.PoblarCdsEtiquetasArtDesdeUniQuery`: riesgo 331 y 223
  líneas.
- `TdmPedidos.ImportarPedidoPrestaShop`: riesgo 330 y tres escrituras.
- `TDatosFaseCobro.CalcularTotales`: riesgo 318 y 22 decisiones.

---

## 3. Análisis SOLID actual

### S — Responsabilidad única: cumplimiento parcial, prioridad alta

Los casos de uso nuevos y varios adaptadores ya son cohesivos. El problema
permanece en formularios, data modules y controladores que mezclan eventos
VCL, reglas, consultas, transacciones, impresión y navegación.

Una extracción cuenta como SRP solo si el colaborador:

- recibe dependencias mínimas;
- no conserva una referencia al formulario completo;
- se prueba sin crear la VCL;
- expone una intención de negocio, no una copia del nombre del evento.

Mover handlers a otra clase con `FAnfitrion: Tfrm...` no cierra SRP.

### O — Abierto/cerrado: cumplimiento medio

Los contratos de repositorio, políticas y casos de uso permiten sustituir
implementaciones. En los grandes handlers todavía se añaden variantes con
`case`, cadenas de `if`, nombres de campo y ramas por tipo de documento.

La mejora prioritaria es convertir variantes estables en estrategias o
políticas. No se crearán jerarquías para condicionales triviales: OCP se
aplica donde una variante obliga hoy a modificar un núcleo fiscal,
transaccional o reutilizado.

### L — Sustitución de Liskov: riesgo estructural, no fallo demostrado

No se ha encontrado una violación funcional reproducible de LSP. Sí existe
riesgo por la jerarquía VCL profunda (`TfrmBase`, `TfrmMtoGen`, documentos y
descendientes), por contratos implícitos de datasets y por hooks cuyo orden
depende de `inherited`.

La salida no es eliminar la herencia VCL. Es documentar y probar sus
precondiciones, dejar en la base solo comportamiento verdaderamente común y
mover reglas variables a colaboradores inyectados.

### I — Segregación de interfaces: correcta en tamaño, incompleta en uso

Todas las interfaces vigiladas respetan el máximo de diez miembros. Sin
embargo, el contexto general de pantalla ofrece diez puertas hacia decenas de
servicios. Un consumidor que recibe ese contexto depende potencialmente de
todo el catálogo.

El objetivo es que cada formulario declare un contexto de feature mínimo y
que solo la raíz de composición conozca implementaciones UniDAC. Una bolsa de
dependencias no se considera ISP aunque esté formada por interfaces pequeñas.

### D — Inversión de dependencias: avance fuerte, cierre pendiente

Está cerrado `inLib* -> UniData* = 0`, no hay ciclos de capa y los valores SQL
no se concatenan. Falta:

- sacar 76 sentencias de 33 unidades `inLib*`;
- sacar de la UI la creación de consultas, SQL, componentes UniDAC y
  transacciones;
- sustituir la resolución tardía desde el contexto general por inyección de
  capacidades concretas;
- probar adaptadores transaccionales críticos contra MariaDB controlada.

---

## 4. Análisis Clean Code actual

### Fortalezas que deben conservarse

- 0 globales `var` en interfaces y 0 `except` vacíos.
- 0 aristas prohibidas de capa y 0 ciclos mayores.
- contratos propios en lugar de `Supports` improvisado;
- SQL parametrizado y tres identificadores dinámicos protegidos por lista
  blanca;
- 604 pruebas verdes en Win32 y Win64;
- CI con calidad y Delphi obligatorios;
- tabuladores eliminados y topes de no regresión automatizados.

### Deuda que impide calificar el código como excelente

- Los topes actuales congelan legado, pero no son una definición de calidad.
  Que un script pase con 1.062 `Exit` o 101 métodos largos significa que no se
  ha empeorado, no que esté terminado.
- Hay nombres de campo, datasets y SQL atravesando presentación, aplicación y
  persistencia.
- Algunos “controladores” son extensiones privilegiadas del formulario y no
  objetos independientes.
- La prueba unitaria domina; falta una capa pequeña de pruebas de integración
  para escrituras y transacciones MariaDB.
- Las excepciones de codificación permiten mantener deuda histórica. P5 exige
  llevar esa lista a cero mediante cambios mecánicos separados.

---

## 5. Nueva escala de prioridades

P0–P4 expresan **orden de ejecución**. P5 expresa el **estado final de
excelencia**.

| Nivel | Significado | Puede esperar |
|-------|-------------|---------------|
| P0 | Rama no verificable, regresión o riesgo inmediato de datos | No |
| P1 | Bloqueo arquitectónico o complejidad en zona crítica | Solo detrás de P0 |
| P2 | Persistencia dentro de UI | Detrás de P1 del mismo feature |
| P3 | Persistencia dentro de dominio y servicios | Detrás de puertos estables |
| P4 | Complejidad, extensibilidad, pruebas de integración y deuda transversal | Tras cerrar fronteras |
| P5 | Código terminado: simple, explícito, probado y sin deuda aceptada | Es el destino |

### P0 — Recuperar una línea base totalmente verde

**Problema actual:** `comprobar_codificacion.ps1` informa 44 infracciones
nuevas: 12 unidades sin BOM y con LF, además de archivos con finales de línea
mezclados.

Acciones:

1. Normalizar exclusivamente codificación y finales de línea, sin cambios
   lógicos.
2. No aumentar baselines ni máximos para ocultar el fallo.
3. Repetir calidad completa, compilación y 604 pruebas en Win32/Win64.

Criterio de salida:

- `scripts/comprobar_calidad.ps1` verde;
- 0 infracciones nuevas de codificación;
- compilación y 604/604 pruebas verdes en las dos plataformas.

### P1 — Romper los bloqueos arquitectónicos

Acciones:

1. Sustituir `IContextoRepositoriosPantalla` como localizador accesible desde
   cualquier formulario por contextos mínimos de feature.
2. Dividir `UniDataRepositoriosGeneralesPantalla` y
   `UniDataRepositoriosCajaPantalla` por capacidades cohesivas.
3. Convertir los contextos ya existentes de Facturas, Caja, Compras,
   Inventario, Artículos y Stock en dependencias inyectadas de verdad.
4. Retirar controladores con referencia al formulario completo, empezando por
   `TControladorFacturas`.
5. Bajar a menos de 2.000 líneas los cinco formularios vigilados todavía
   pendientes, sin crear un nuevo monolito en `UniData*`.
6. Caracterizar primero restauración, caja y fiscalidad, por su impacto.

Criterio de salida:

- 148 accesos desde 55 consumidores al contexto general pasan a 0;
- ninguna fábrica de pantalla supera 10 capacidades;
- las unidades de composición generales quedan por debajo de fan-out 40;
- las cinco clases vigiladas quedan por debajo de 2.000 líneas;
- ningún colaborador de presentación conserva un `Tfrm...` completo;
- los núcleos extraídos se prueban sin VCL y sin BBDD.

### P2 — UI sin persistencia

Acciones:

1. Extraer las consultas y escrituras de los 25 focos UI medidos.
2. Mover componentes UniDAC de DFM a data modules o adaptadores.
3. Mover las cinco transacciones a unidades de trabajo explícitas.
4. Dejar en cada handler: recoger entrada, invocar caso de uso y presentar
   resultado.

Criterio de salida del trinquete UI:

| Indicador | Actual | Objetivo |
|-----------|-------:|---------:|
| `TUniQuery.Create` | 35 | 0 |
| `SQL.Text :=` | 68 | 0 |
| Componentes UniDAC en DFM | 18 | 0 |
| Transacciones en UI | 5 | 0 |
| `SQL.Add` / `CommandText` / `TUniStoredProc.Create` | 0 | 0 |

### P3 — Dominio sin SQL ni detalles UniDAC

Acciones:

1. Extraer las 76 sentencias restantes de las 33 unidades `inLib*` a
   adaptadores `UniData*`.
2. Definir contratos por caso de uso; no crear un repositorio genérico ni una
   nueva bolsa de consultas.
3. Mantener resultados de negocio fuera de `TUniQuery` cuando no sea necesario
   enlazar un dataset de presentación.
4. Declarar propietario de transacción, commit, rollback e idempotencia en
   cada escritura de varias tablas.

Criterio de salida:

- SQL literal en `inLib*`: 76 -> 0;
- unidades `inLib*` con SQL: 33 -> 0;
- `inLib* -> UniData*`: permanece en 0;
- valores externos concatenados: permanece en 0;
- cada adaptador crítico tiene prueba contractual y transaccional.

### P4 — Reducir complejidad y demostrar extensibilidad

Acciones:

1. Dividir primero los 20 métodos de más de 200 líneas y después los de mayor
   riesgo.
2. Separar cálculo, decisión, persistencia y presentación; no crear métodos
   auxiliares que solo fragmenten texto.
3. Sustituir ramas repetidas por políticas cuando representen variantes de
   negocio estables.
4. Probar contratos de la jerarquía VCL y orden de hooks donde una omisión de
   `inherited` cambie el comportamiento.
5. Añadir una suite reducida de integración MariaDB para repositorios,
   rollback, idempotencia y errores parciales.
6. Medir tiempos de los caminos interactivos y usar `EXPLAIN` en consultas
   nuevas o modificadas de gran volumen.

Criterio de salida:

- métodos de más de 200 líneas: 20 -> 0;
- riesgo máximo de método: 417 -> menor o igual a 200;
- ningún método fiscal/caja modificado supera 10 decisiones;
- ninguna clase/data module nuevo supera los límites P5;
- pruebas de integración críticas ejecutables de forma repetible.

### P5 — Excelencia mantenible

P5 no se alcanza porque los topes no crezcan. Se alcanza cuando no queda
deuda aceptada en código propio modificado y el legado completo ha pasado por
fascículos seguros.

Objetivo final:

- 0 excepciones de codificación; UTF-8 con BOM y CRLF en todo archivo propio;
- 0 `Exit`, `Continue` y `with` en código propio escrito o refactorizado;
- 0 líneas de más de 80 columnas fuera de recursos inevitables documentados;
- handlers VCL de hasta 15 líneas efectivas;
- métodos normales de hasta 60 líneas, objetivo menor de 40;
- dependencias visibles en constructor, método o contexto mínimo;
- SQL solo en adaptadores de persistencia y scripts idempotentes;
- errores expresados y registrados, nunca convertidos en éxito;
- éxito, límites y fallos relevantes cubiertos por pruebas;
- CI obligatoria verde en calidad, Win32, Win64, DUnitX e integración crítica.

---

## 6. Orden de ejecución y regla de fascículo

Cada tarea sigue esta secuencia:

1. Medir la unidad y fijar el comportamiento con pruebas de caracterización.
2. Extraer una sola responsabilidad o frontera.
3. Aplicar P5 a todo código nuevo y a la zona modificada.
4. Ejecutar los comprobadores específicos del riesgo.
5. Compilar Win32 y Win64 y ejecutar DUnitX.
6. Mostrar métricas antes/después y el diff limitado a las unidades asignadas.

No se mezclan en un mismo fascículo:

- cambio funcional y normalización masiva;
- extracción de persistencia y rediseño visual;
- cambio fiscal y limpieza cosmética;
- varias transacciones sin una prueba por cada contrato.

La ejecución paralela usa las olas de `TAREAS_IA_SOLID.md`. Dentro de una ola
no se repite ninguna unidad Pascal. Los manifiestos Delphi, scripts, workflow,
baselines y documentos son propiedad exclusiva de tareas seriales de
integración.

---

## 7. Definición de terminado por tarea

Una tarea solo se cierra cuando:

- conserva el comportamiento visible o documenta expresamente el cambio;
- añade o adapta pruebas antes de retirar el código anterior;
- no amplía listas blancas, baselines ni máximos sin una reducción neta
  explicada;
- no introduce dependencias nuevas ni acceso global;
- no crea una interfaz de más de diez miembros ni una bolsa de servicios;
- no deja SQL, transacciones o `TUniQuery` en UI o dominio cuando ese sea su
  objetivo;
- pasa los comprobadores de calidad relevantes;
- compila y pasa las pruebas en Win32 y Win64;
- informa de unidades creadas, métricas antes/después y riesgos pendientes;
- no modifica `factuzam_original.sql` y no hace commit salvo petición expresa.

---

## 8. Decisiones cerradas que no deben reabrirse

- UniDAC sigue siendo la tecnología de acceso a datos.
- `factuzam_original.sql` no se modifica.
- Los cambios de esquema viven en scripts idempotentes de
  `DESARROLLOS EN CURSO/`.
- `inLib* -> UniData*` debe permanecer en 0.
- No vuelven globales `var`, `except` vacíos, `Supports` improvisado ni
  catálogos agregadores de formularios.
- No se relajan topes para hacer verde una regresión.
- Una clase extraída con referencia al formulario completo no se contabiliza
  como desacoplamiento.

Este documento se vuelve a medir al terminar cada prioridad. Las cifras
históricas se conservan en Git; aquí solo permanece la foto útil para decidir
el siguiente trabajo.
