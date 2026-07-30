# Anexo SRP — Descomposición de las clases-dios de librería

Fecha de la línea base: 30/07/2026.

Este documento desarrolla la Fase 3 de
[`PLAN_SOLID.md`](../PLAN_SOLID.md) para los tres focos de librería que
no tenían fascículos, límites propios ni criterio de salida. Es un plan
de ejecución: no sustituye a
[`LIBRO_DE_ESTILO_DELPHI.md`](../LIBRO_DE_ESTILO_DELPHI.md) §14.4,
§14.5, §14.7 y §14.9.

Estado: **PLANIFICADO**. El piloto de compras descrito en §2 es trabajo
preparatorio; ningún fascículo de este anexo se considera cerrado sin la
evidencia exigida en §10.

---

## 1. Alcance

El anexo cubre:

1. la materialización de sesiones de compra, cuya fachada de dominio ya
   se ha reducido, pero cuya implementación sigue concentrada en
   `UniDataComprasSesionesMaterializar`;
2. `TGridPivoteVenta`, dentro de `inLibGridPivoteVenta`;
3. `TModoEntradaTallas`, dentro de
   `inLibColumnasSkuModoTallas`.

No cubre los seis formularios grandes de `PLAN_SOLID.md` §3.2, salvo el
cableado necesario para que deleguen en estas piezas. Tampoco autoriza a
unificar `inLibGridPivoteVenta` con `inLibGridPivoteCompra`: sus modelos
y ciclos de vida son distintos. Solo se compartirá una pieza cuando
exista un contrato y una prueba que demuestren comportamiento
equivalente.

---

## 2. Línea base medida

Las cifras siguientes se han medido sobre el árbol de trabajo del
30/07/2026. Las líneas de clase son las que calcula
`scripts/comprobar_tamano_clases.ps1`.

| Foco | Unidad | Líneas de unidad | Clase principal | Líneas | Métodos | Campos |
|---|---|---:|---|---:|---:|---:|
| Materialización | `UniDataComprasSesionesMaterializar` | 3.042 | procedural | — | 75 rutinas | — |
| Pivote de venta | `inLibGridPivoteVenta` | 3.100 | `TGridPivoteVenta` | 2.971 | 86 | 49 |
| Modo tallas | `inLibColumnasSkuModoTallas` | 3.009 | `TModoEntradaTallas` | 2.481 | 71 | 29 |

Estado particular de compras:

- `inLibComprasSesionesMaterializar` es ya una fachada de 68 líneas, sin
  SQL literal, que recibe `IRepositorioComprasSesiones`.
- `TServicioComprasSesiones` y el doble
  `TRepositorioComprasSesionesMemoria` ya existen.
- `PruebasComprasSesionesRepositorio` comprueba delegación sin conexión.
- El conjunto del piloto, incluidos contrato, adaptadores, doble y
  pruebas, ocupa 5.423 líneas frente a 5.527 de partida: reducción neta
  de 104 líneas. Una extracción futura no se cierra si este agregado
  aumenta sin una justificación y un nuevo límite aprobado.
- Las reglas, decisiones y escrituras de la materialización siguen
  juntas en las 3.042 líneas de
  `UniDataComprasSesionesMaterializar`. Se ha corregido la dirección de
  la dependencia, pero todavía no la responsabilidad única.

SQL literal todavía presente en los otros dos focos:

| Unidad `inLib*` | Sentencias |
|---|---:|
| `inLibGridPivoteVenta` | 13 |
| `inLibColumnasSkuModoTallas` | 18 |

La cobertura actual de `PruebasColumnasDocumento` fija configuraciones y
columnas anfitrionas, pero no prueba el modelo de bandas, la conversión
de celdas, el des-pivote ni los invariantes de unidades.

---

## 3. Responsabilidades mezcladas

### 3.1 Materialización de sesiones de compra

`UniDataComprasSesionesMaterializar` contiene al menos seis
responsabilidades separables:

1. alta y actualización de artículos;
2. colores, atributos, SKU y EAN13;
3. cabeceras, líneas, IVA y totales de albaranes;
4. cabeceras, líneas, IVA, totales y pendientes de pedidos;
5. orquestación de documento único o por almacén;
6. reversión, limpieza e idempotencia.

El bloque transaccional es común al caso de uso, pero eso no obliga a
que todas las operaciones vivan en una sola unidad. Los adaptadores
pueden compartir la misma conexión y unidad de trabajo sin conocer las
decisiones del flujo.

### 3.2 `TGridPivoteVenta`

La clase concentra:

- modelo de grupos, bandas, celdas, cantidades y conjuntos virtuales;
- cachés de artículos, SKU, líneas, almacenes y cantidades;
- SQL y acceso a datasets reales;
- construcción y reconstrucción del `TClientDataSet` temporal;
- creación y colocación de columnas DevExpress;
- edición, validación, foco, dibujo y temporizadores;
- resolución por artículo, SKU y código de barras;
- persistencia, borrado de grupo y preparación para albaranar.

La API `IModoEntradaGrid` puede mantenerse estable mientras el interior
se divide.

### 3.3 `TModoEntradaTallas`

La clase concentra:

- búsqueda incremental, lookup, filtros y temporizadores;
- cálculo de atributos, conjuntos pivote y composición de SKU;
- consolidación, rederivación y des-pivote de líneas;
- migración de celdas entre formato distribuido y no distribuido;
- SQL de celdas, almacenes, atributos y totales;
- presentación, dibujo, foco, edición y distribuidor visual;
- conservación del invariante de unidades del documento.

`TDesmontajeTallas` ya marca una frontera útil, pero sigue acoplado al
objeto grande y vive en la misma unidad.

---

## 4. Arquitectura de salida

Cada foco terminará dividido en estas capas:

```text
Formulario / IModoEntradaGrid
              |
              v
Coordinador o presentador
              |
              v
Servicio y modelo de dominio ---> contratos pequeños
                                      |
                                      v
                              adaptadores UniData*
```

Reglas:

1. El dominio recibe datos simples, `record`, arrays e interfaces. No
   conoce VCL, DevExpress, UniDAC, `TDataSet` ni el formulario.
2. El presentador puede conocer controles y datasets de la vista, pero
   no contiene SQL ni decide reglas de negocio.
3. `UniData*` parametriza y ejecuta SQL. No decide qué documento crear,
   qué banda corresponde ni cómo consolidar una línea.
4. La transacción de compras conserva un único límite exterior para
   toda la materialización o reversión. Los repositorios interiores
   comparten esa unidad de trabajo y no hacen commits parciales.
5. Las fachadas compatibles no reciben lógica nueva y se eliminan al
   migrar el último consumidor.
6. Ningún contrato se convierte en un `Ejecutar(ASql)`. Las operaciones
   se nombran en términos del caso de uso.

Los nombres definitivos se decidirán en cada fascículo. Como guía:

- dominio: `TMaterializadorComprasSesiones`,
  `TModeloPivoteVenta`, `TModeloTallasDocumento`;
- contratos: puertos pequeños de artículos/SKU, documentos, celdas y
  unidad de trabajo;
- persistencia: `UniDataComprasSesionesArticulos`,
  `UniDataComprasSesionesDocumentos`,
  `UniDataComprasSesionesReversion`,
  `UniDataPivoteVenta` y `UniDataModoTallas`;
- presentación: colaboradores específicos del grid, no nuevas unidades
  cajón de sastre.

Estos nombres son orientativos. La responsabilidad y el sentido de la
dependencia son obligatorios.

---

## 5. Trinquetes

### 5.1 Instrumentación inicial

El primer fascículo amplía
`scripts/comprobar_tamano_clases.ps1`:

1. añade límites individuales para `TGridPivoteVenta` y
   `TModoEntradaTallas`;
2. añade límites de líneas y rutinas por unidad para código procedural,
   empezando por `UniDataComprasSesionesMaterializar`;
3. falla si una unidad o clase vigilada desaparece sin que el mapa de
   límites se actualice expresamente;
4. muestra el valor anterior, el actual y el objetivo;
5. fija `TfrmMtoComprasSesiones` en su medida real de 3.660 líneas, no
   en el límite anterior de 3.663.

Límites iniciales:

| Objetivo vigilado | Líneas | Métodos | Campos |
|---|---:|---:|---:|
| `UniDataComprasSesionesMaterializar` | 3.042 | 75 rutinas | — |
| `TGridPivoteVenta` | 2.971 | 86 | 49 |
| `TModoEntradaTallas` | 2.481 | 71 | 29 |

Después de cada fascículo se sustituye el límite por la nueva medida.
No se conserva margen y ninguna dimensión puede volver a subir.

### 5.2 Objetivos de salida

| Objetivo | Resultado exigido |
|---|---|
| `UniDataComprasSesionesMaterializar` | eliminada o ≤ 600 líneas como fachada de infraestructura |
| Unidades resultantes de materialización | ninguna > 1.200 líneas ni > 30 rutinas |
| `TGridPivoteVenta` | ≤ 1.500 líneas, ≤ 45 métodos y ≤ 25 campos |
| `TModoEntradaTallas` | ≤ 1.500 líneas, ≤ 45 métodos y ≤ 20 campos |
| Colaboradores nuevos | cada clase ≤ 1.200 líneas, ≤ 40 métodos y ≤ 20 campos |
| Métodos y rutinas | ninguno nuevo > 120 líneas; ninguno > 200 |
| SQL en `inLibGridPivoteVenta` | 0 |
| SQL en `inLibColumnasSkuModoTallas` | 0 |

Estos valores son criterios de salida de la fase, no el tamaño que deba
alcanzarse en un único cambio.

---

## 6. Orden de ejecución

Orden vinculante:

1. **L0 — instrumentación.**
2. **C1-C7 — materialización de compras.** Cruza SRP y DIP, y desbloquea
   el adelgazamiento de `TfrmMtoComprasSesiones`.
3. **V1-V5 — pivote de venta.** Es la clase que marca el máximo global
   de 49 campos y tiene seis formularios consumidores directos.
4. **T1-T6 — modo tallas.**

No se abre un segundo foco mientras el fascículo anterior no compile,
no pase sus pruebas y no haya reducido su trinquete.

L0 es instrumentación y no mueve producción. C1, V1 y T1 incluyen la
primera extracción pura del foco además de las pruebas de
caracterización; no hay fascículos de pruebas que dejen intacto el
monolito.

---

## 7. Fascículos de materialización de compras

### C1 — Caracterización del caso de uso

Añadir pruebas antes de mover más código:

- documento único;
- un documento por almacén;
- generación de pedido, albarán o ambos;
- modo de solo documentos;
- resultado parcial y mensaje de error;
- repetición idempotente;
- reversión conservando artículos, SKU y EAN13;
- tablas opcionales de instalaciones antiguas.

Las pruebas puras usan dobles. Las pruebas de SQL y compatibilidad
MariaDB se mantienen como integración separada.

En este mismo fascículo se extraen la inicialización, agregación y
normalización de `TResultadoMaterializacionSesion` a una pieza pura. Es
la primera bajada del límite procedural y permite probar resultados de
uno o varios almacenes sin conexión.

### C2 — Límite transaccional

Declarar una unidad de trabajo pequeña y sustituible en pruebas. Debe
permitir demostrar:

- una confirmación al terminar todo el caso de uso;
- rollback ante cualquier fallo intermedio;
- ausencia de commits en adaptadores interiores;
- reutilización de una transacción ya activa.

No se migra otra escritura hasta que el rollback esté probado.

### C3 — Persistencia de artículos y SKU

Extraer el bloque de:

- artículos y propiedades fijas;
- colores y atributos;
- SKU;
- proveedor, tarifa y temporada;
- generación y asignación de EAN13.

La nueva implementación vive en `UniData*` y expone operaciones con
nombre mediante contratos. Las normalizaciones y decisiones que no
dependan de la BBDD pasan a funciones puras con DUnitX.

### C4 — Persistencia de documentos

Extraer por separado:

- albarán de compra: cabecera, líneas, IVA, totales y cierre;
- pedido de compra: cabecera, líneas, IVA, totales y pendientes de
  recibir.

Los dos adaptadores comparten la unidad de trabajo, no SQL textual ni
una clase base artificial.

### C5 — Reversión

Extraer validación y ejecución de la reversión:

- documentos;
- movimientos;
- pendientes de recibir;
- reapertura de sesión;
- tratamiento explícito de tablas opcionales.

La prueba debe inyectar un fallo después de una escritura y demostrar
que todo el estado vuelve al punto inicial.

### C6 — Orquestador de dominio

Mover a `inLib*` la decisión de:

- qué materializar;
- documento único o por almacén;
- orden de los pasos;
- agregación de documentos generados;
- idempotencia y resultado del caso de uso.

El orquestador recibe puertos por constructor. No recibe
`TdmComprasSesiones`, `TUniConnection`, queries ni datasets. El
repositorio ya no expone una operación gorda que haga todo por dentro.

### C7 — Cierre y formulario

`TfrmMtoComprasSesiones` conserva confirmaciones, mensajes, foco y
refresco. La creación, materialización y reversión pasan por el
orquestador.

Al cerrar:

- la fachada temporal queda eliminada o anotada con su caducidad;
- el límite del formulario baja;
- `UniDataComprasSesionesMaterializar` cumple el objetivo de §5.2;
- pasan DUnitX, rollback, Release Win32 y Release Win64.

---

## 8. Fascículos de `TGridPivoteVenta`

### V1 — Caracterización del pivote

Fijar con pruebas:

- agrupación por artículo, color y precio;
- tres bandas frente a banda única;
- cantidades pedida, entregada, pendiente y a albaranar;
- línea representante y correspondencia celda/SKU/línea real;
- conjunto virtual cuando no existe uno asignado;
- borrado completo del grupo;
- resolución por artículo, SKU y código de barras.

En el mismo fascículo se extraen las claves de grupo/celda y el cálculo
puro de bandas y pendientes. `TGridPivoteVenta` debe bajar ya en V1.

### V2 — Puerto de persistencia

Mover las 13 sentencias SQL a un adaptador `UniData*`. El contrato
devuelve records de líneas, SKU, atributos y cantidades; no cruza
`TDataSet`, `TUniQuery` ni `TUniConnection`.

### V3 — Modelo de pivote

Extraer una clase sin UI que sea propietaria de:

- claves de grupo y celda;
- bandas y línea base;
- cantidades y pendientes;
- asociación de SKU, almacén y línea real;
- conjuntos virtuales;
- operaciones de marcar, limpiar y volcar a albaranar.

Los diccionarios del modelo dejan de ser campos de
`TGridPivoteVenta`.

### V4 — Presentación y ciclo de vida

Separar:

- `TClientDataSet` temporal;
- creación y visibilidad de columnas;
- dibujo;
- edición, foco y temporizadores;
- instalación y restauración de eventos.

Este colaborador puede conocer VCL y DevExpress. Recibe un modelo y
callbacks tipados, pero no contiene SQL ni recalcula reglas.

### V5 — Fachada y consumidores

`TGridPivoteVenta` queda como coordinador de `IModoEntradaGrid`. Se
conservan `IPivoteVentaAlbaranar` e `IPivoteVentaBorrarGrupo` mientras
tengan consumidores.

Pruebas funcionales mínimas:

| Consumidor | Caso |
|---|---|
| `inMtoPedidos` | tres bandas, cantidades pendientes y a albaranar |
| `inMtoFacturasBase` | banda única y creación de línea SKU |
| `inMtoPedidosCompra` | rótulo a recibir y líneas reales |
| `inMtoAlbaranesCompra` | carga y edición del pivote |
| `inMtoFacturasCompra` | banda única de compra |
| `inMtoDevolucionesCompra` | signo, cantidad y borrado de grupo |

---

## 9. Fascículos de `TModoEntradaTallas`

### T1 — Caracterización de invariantes

Fijar con pruebas:

- composición de SKU con la talla en su posición real;
- cálculo de atributos no talla;
- elección y validación del conjunto pivote;
- consolidación de líneas;
- igualdad de unidades antes y después de migrar, rederivar o desmontar;
- formato distribuido y no distribuido;
- suma de cantidades y fusión de celdas.

En el mismo fascículo se extraen el cálculo del total estable y la
comprobación del invariante de unidades a una pieza sin UI ni UniDAC.
`TModoEntradaTallas` debe bajar ya en T1.

### T2 — Puerto de persistencia

Mover las 18 sentencias SQL a un adaptador `UniData*`. Separar
operaciones de:

- lectura y escritura de celdas;
- atributos y conjuntos;
- almacenes;
- totales;
- búsqueda de artículos y SKU.

El modo de entrada no construye fragmentos `WHERE`, columnas de `INSERT`
ni parámetros UniDAC.

### T3 — Conversión y des-pivote

Convertir `TDesmontajeTallas` en un caso de uso independiente. Recibe
records de líneas y celdas, devuelve las operaciones que deben
persistirse y prueba el invariante de unidades sin levantar controles.

### T4 — Modelo de tallas

Extraer:

- atributos y orden de talla;
- composición y descomposición de SKU;
- conjunto pivote;
- localización y consolidación;
- migración entre almacén vacío y distribuido;
- rederivación de líneas heredadas.

### T5 — Presentación

Dejar en un colaborador visual:

- lookup y búsqueda incremental;
- timers;
- foco y editores;
- dibujo y captions;
- apertura del distribuidor;
- instalación y restauración de eventos.

### T6 — Fachada y consumidores

`TModoEntradaTallas` queda como coordinador de `IModoEntradaGrid` y
cumple los límites de §5.2.

Pruebas funcionales mínimas:

| Consumidor | Caso |
|---|---|
| `inMtoAlbaranes` | entrada inline, consolidación y des-pivote |
| `inMtoPedidosCompra` | cambio entre modos y conservación de unidades |
| `inMtoDocumentosTrabajo` | clave de documento simple y celdas |
| `inMtoModalDistribuidor` | cantidades por almacén y cancelación |

---

## 10. Pruebas y evidencia por fascículo

Cada fascículo deja:

1. resultado antes/después de líneas, métodos, campos y SQL;
2. pruebas DUnitX nuevas o ampliadas;
3. salida de los scripts de trinquete afectados;
4. compilación Release Win32 y Win64;
5. `FactuzamTests.exe` correcto;
6. pruebas funcionales solo de los consumidores afectados;
7. un documento
   `DESARROLLOS EN CURSO/refactorizacion_srp_librerias_<codigo>_resultados.md`.

Los cambios de persistencia añaden además:

- prueba de parámetros y operación de repositorio;
- prueba de rollback con fallo inyectado;
- comprobación de reintento cuando el flujo deba ser idempotente.

---

## 11. Criterio de cierre del anexo

El anexo se considera terminado únicamente cuando:

- se cumplen todos los objetivos de §5.2;
- las dos unidades `inLib*` de grid contienen cero SQL;
- la orquestación de compras se prueba con repositorios falsos y sin
  conexión;
- los adaptadores UniDAC no deciden reglas de negocio;
- ningún formulario, librería o data module hace cast al consumidor;
- no quedan fachadas temporales sin caducidad documentada;
- todos los consumidores de §8 y §9 han pasado su prueba funcional;
- los límites finales quedan promovidos a
  `LIBRO_DE_ESTILO_DELPHI.md` §14.5 y a los scripts de build.
