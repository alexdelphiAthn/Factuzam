# T1-T6 — modo de entrada de tallas (resultados)

Fecha: 30/07/2026. Fascículos T1 a T6 implementados. Sin commit.

## Nota de orden

`plan_srp_clases_dios_libreria.md` §6 fija el orden L0 → C1-C7 → V1-V5 →
T1-T6. **V1-V5 (pivote de venta) sigue pendiente**: `inLibGridPivoteVenta`
continúa en 3.100 líneas y `TGridPivoteVenta` en 2.971/86/49, sin tocar. Se
ha adelantado T1-T6 por petición expresa. Los dos focos son independientes
—unidades, modelos y ciclos de vida distintos— y ningún cambio de este
fascículo entra en `inLibGridPivoteVenta`, así que V1-V5 puede abrirse
después sin conflicto.

## Resultado

`TModoEntradaTallas` deja de ser la clase que lo hace todo. Pasa de
**2.481 líneas, 71 métodos y 29 campos** a un coordinador de
**498 líneas, 30 métodos y 12 campos**, y `inLibColumnasSkuModoTallas`
baja de **3.009 a 549 líneas**.

| Unidad | Líneas | Rutinas | Responsabilidad |
|---|---:|---:|---|
| `inLibColumnasSkuModoTallas` | 549 | 30 | coordinador de `IModoEntradaGrid` |
| `inLibModoTallasIntf` | 275 | 3 | contratos, tipos y fábrica |
| `inLibModoTallasModelo` | 364 | 16 | modelo de dominio |
| `inLibModoTallasConversion` | 394 | 15 | rederivación y des-pivote |
| `inLibModoTallasLineas` | 817 | 52 | adaptador del cds del documento |
| `inLibModoTallasBuscador` | 408 | 21 | desplegable de búsqueda y paleta |
| `inLibModoTallasPresentacion` | 767 | 38 | colaborador visual |
| `inLibDistribuidorTallas` | 75 | 2 | registro del ejecutor visual |
| `UniDataModoTallas` | 824 | 40 | adaptador UniDAC (todo el SQL) |

Clases resultantes, todas por debajo de 1.200 líneas, 40 métodos y
20 campos:

| Clase | Líneas | Métodos | Campos |
|---|---:|---:|---:|
| `TModoEntradaTallas` | 498 | 30 | 12 |
| `TModeloTallas` | 334 | 16 | 4 |
| `TRederivacionTallas` | 193 | 7 | 7 |
| `TDesmontajeTallas` | 169 | 8 | 8 |
| `TEscrituraLineasTallas` | 397 | 17 | 3 |
| `TLineasDocumentoTallasCds` | 391 | 35 | 10 |
| `TBuscadorSkusTallas` | 333 | 16 | 14 |
| `TPresentacionModoTallas` | 725 | 38 | 17 |
| `TPersistenciaModoTallasUniDAC` | 638 | 33 | 1 |
| `TBusquedaSkusTallasUniDAC` | 79 | 5 | 2 |

## SQL

**Las 18 sentencias que vivían en `inLibColumnasSkuModoTallas` han pasado
a `UniDataModoTallas`.** La unidad del modo, el modelo, las conversiones,
el adaptador de líneas y la presentación contienen **cero SQL**: ni
literales, ni fragmentos `WHERE`, ni listas de columnas de `INSERT`, ni
parámetros UniDAC.

`IPersistenciaModoTallas` expone operaciones con nombre de caso de uso
—`ConsultarTotalesPorLinea`, `ConsultarCeldasDocumento`, `SumarEnCelda`,
`MoverCeldasALinea`, `MigrarCeldasFormato`, `BorrarCeldasDocumento`,
`BuscarConjuntoParaAvs`, `ConjuntoCubreAvs`, `PrimerAlmacenEstandar`— y
nunca un `Ejecutar(ASql)`. El desplegable usa un puerto aparte,
`IBusquedaSkusTallas`, que devuelve un `TDataSet` porque el lookup de
DevExpress necesita un origen vivo; el SQL de la búsqueda vive en el
adaptador.

## Fascículos

### T1 — Caracterización de invariantes

`TModeloTallas` reúne, sin UI y sin UniDAC, la composición y
descomposición de SKU, la detección del atributo talla, la clave de
consolidación, el total estable del documento y la comprobación del
invariante de unidades. Todo lo que no necesita catálogo es `class
function` pura y se prueba sin dobles.

### T2 — Puerto de persistencia

`UniDataModoTallas` implementa la persistencia y la búsqueda. Se registra
a sí mismo en su `initialization` mediante `TFabricaModoTallas`, igual que
`inMtoModalDistribuidor` registra el ejecutor del distribuidor: el
coordinador `inLib*` no nombra ninguna unidad `UniData*` y la dirección de
la dependencia queda correcta.

Dos simplificaciones de SQL, equivalentes en resultado:

- la migración de celdas usa una única consulta con `SUM ... GROUP BY`
  para los dos formatos (antes había dos variantes; en distribuido el
  agrupado devuelve las mismas filas porque la clave es única);
- el `INSERT ... ON DUPLICATE KEY UPDATE` se construye una sola vez y la
  columna de almacén se intercala o no según el documento (antes eran dos
  sentencias completas duplicadas).

### T3 — Conversión y des-pivote

`TDesmontajeTallas` deja de conocer `TModoEntradaTallas`, el `cds` y la
conexión: recibe `ILineasDocumentoTallas`, `IPersistenciaModoTallas` y el
modelo. Abre transacción solo si no había una activa, cierra el proceso
antes de medir el invariante y notifica una sola vez los posts
silenciados. Se prueba entero con dobles en memoria.

### T4 — Modelo de tallas

`TRederivacionTallas` recoge la conversión de líneas heredadas: clave de
consolidación, fusión de duplicadas, traslado de celdas de una duplicada
ya convertida y volcado de la cantidad del SKU con talla a su celda. El
recorrido por posición —y no con `while not Eof`— se conserva tal cual: es
la protección contra el borrado en cascada del documento.

La elección del conjunto pivote (`ResolverConjuntoPivote`) queda aislada,
con su fallback cuando el conjunto asignado no cubre las tallas reales de
los SKUs.

### T5 — Presentación

`TPresentacionModoTallas` conserva columnas, editores, foco, dibujo,
captions, temporizadores y apertura del distribuidor.
`TBuscadorSkusTallas` se lleva el desplegable de búsqueda incremental y
`TSelectorAvPaleta` implementa `ISelectorValorAtributo` sobre la paleta de
swatches: el modelo pide un valor de atributo sin saber que detrás hay un
diálogo.

El adaptador del `cds` es dueño de los hooks `AfterPost` / `AfterScroll`,
del contador de posts silenciados y de la profundidad de proceso; avisa a
la presentación por callback para que rearme su recarga diferida.

### T6 — Fachada y trinquete

`TModoEntradaTallas` queda como coordinador: construye los colaboradores,
orquesta `Construir` (columnas → gestor → hooks → conversión atómica →
carga diferida), resuelve la entrada y delega el des-pivote. No contiene
SQL, no toca controles y no escribe campos del `cds` directamente.

## Cambios de comportamiento

Solo hay dos, ambos en casos límite:

1. Un artículo con **más de cinco atributos** ya no abre la paleta para el
   sexto y siguientes. Antes se abría y el valor elegido se descartaba,
   porque solo hay cinco columnas `ATTRn`.
2. Las lecturas de campo del `cds` son defensivas (`FindField`) donde
   antes eran `FieldByName` directo. Un documento sin el campo
   `CODIGO_UNIDAD` deja de lanzar excepción y se comporta como si viniera
   vacío.

El resto del flujo —consolidación, invariante de unidades, transacción,
tolerancia de 0,001, orden de carga diferida, tratamiento del residuo de
conversión rota en el refresco de totales— se conserva literalmente.

## Pruebas

`tests/PruebasModoTallas.pas` (878 líneas) y `tests/DoblesModoTallas.pas`
(875 líneas): 32 casos DUnitX sin BBDD, sin controles y sin UniDAC.

Modelo (20 casos):

- SKU con la talla en su posición real y SKU sin talla;
- troceado de un SKU cerrado y rechazo de un SKU de otro artículo;
- detección del atributo talla por nombre y por identificador;
- atributos tomados del SKU leído, valor único fijado solo y paleta
  únicamente cuando la conversión no es silenciosa;
- conjunto pivote: asignado que cubre, fallback cuando no cubre,
  conservación del asignado cuando ninguno cubre y búsqueda cuando el
  artículo no tiene asignado;
- clave de consolidación: sin almacén en formato distribuido, con almacén
  fuera de él y separación por precio;
- unidades del documento y no doble conteo de una línea pivotada;
- invariante dentro y fuera de la tolerancia;
- resolución del `ID_AV` de una talla.

Conversiones (12 casos):

- fusión de duplicadas con volcado de la cantidad a la celda de su talla;
- conservación de las unidades al rederivar;
- líneas con precio distinto que no fusionan;
- fusión por almacén en formato distribuido, con una celda por almacén;
- traslado de las celdas de una duplicada ya convertida;
- reentrada al modo sin volver a volcar la cantidad de una línea con
  celdas;
- des-pivote: una línea por SKU, cantidad y precio conservados y celdas
  borradas;
- des-pivote sin celdas que no toca las líneas;
- conservación de las unidades al desmontar;
- una sola confirmación y un solo aviso de posts silenciados;
- **reversión con la conversión rota**: el invariante salta y el caso de
  uso revierte sin confirmar;
- **transacción ajena ya activa**: ni se abre, ni se confirma, ni se
  revierte.

## Trinquete

`scripts/comprobar_tamano_clases.ps1` sustituye la entrada única de
`TModoEntradaTallas` por las diez clases resultantes, cada una con su
medida actual como tope de no regresión y con los objetivos de §5.2. Se
añade además `src\DataModules\UniDataModoTallas.pas` a `LimitesUnidades`.

Ninguna dimensión sube: el tope anterior de 2.481/71/29 pasa a 498/30/12
y no queda margen.

Comando:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\comprobar_tamano_clases.ps1
```

Salida esperada de las clases del foco (medidas con la misma regla que
usa el script):

```text
TModoEntradaTallas
  ActualLineas=498   TopeAnteriorLineas=498   ObjetivoLineas=1500
  ActualMetodos=30   TopeAnteriorMetodos=30   ObjetivoMetodos=45
  ActualCampos=12    TopeAnteriorCampos=12    ObjetivoCampos=20
  EstadoObjetivo=ALCANZADO
TModeloTallas                  334 / 16 / 4    ALCANZADO
TRederivacionTallas            193 /  7 / 7    ALCANZADO
TDesmontajeTallas              169 /  8 / 8    ALCANZADO
TEscrituraLineasTallas         397 / 17 / 3    ALCANZADO
TLineasDocumentoTallasCds      391 / 35 / 10   ALCANZADO
TBuscadorSkusTallas            333 / 16 / 14   ALCANZADO
TPresentacionModoTallas        725 / 38 / 17   ALCANZADO
TPersistenciaModoTallasUniDAC  638 / 33 / 1    ALCANZADO
TBusquedaSkusTallasUniDAC       79 /  5 / 2    ALCANZADO

UniDataModoTallas
  ActualLineas=824   TopeAnteriorLineas=824   ObjetivoLineas=1200
  ActualRutinas=40   TopeAnteriorRutinas=40   ObjetivoRutinas=45
  EstadoObjetivo=ALCANZADO
```

## Balance de código

Las nueve unidades de producción del foco suman **4.473 líneas** frente a
las 3.009 de la unidad original: **+1.464 líneas**. No se presenta como
reducción; es coste arquitectónico visible —contratos, dos adaptadores,
fábrica, cabeceras de unidad y firmas partidas a 80 columnas— y queda con
un plan medible:

1. **RT1 — colapsar `TEscrituraLineasTallas` en el adaptador** cuando el
   des-pivote deje de necesitar escritura campo a campo (el caso de uso
   podría devolver operaciones y el adaptador aplicarlas en bloque).
   Objetivo: -180 líneas.
2. **RT2 — contexto de documento único en el adaptador UniDAC.** Resolver
   serie, número y clave extra una vez por operación compuesta en vez de
   releerlos del master en cada consulta. Objetivo: -120 líneas.
3. **RT3 — unificar la construcción de la cláusula de celdas.** Las
   consultas de celdas comparten `WHERE` y agrupación; queda un solo
   generador parametrizado. Objetivo: -140 líneas.
4. **RT4 — compactar cabeceras y comentarios históricos.** Conservar solo
   decisiones vigentes. Objetivo: -100 líneas.

Primer objetivo acumulado: **3.933 líneas o menos** sin subir ningún tope.

## Consumidores

`inLibColumnasSku.CrearModoEntradaGridTallas` no cambia de firma:
`TModoEntradaTallas.Create(Cfg, CfgTallas)` sigue siendo el punto de
entrada y `IModoEntradaGrid` es idéntico. `inMtoModalDistribuidor` pasa a
usar `inLibDistribuidorTallas` en vez de `inLibColumnasSkuModoTallas`
(única línea tocada en un consumidor).

`fzam.dpr`, `fzam.dproj`, `tests/FactuzamTests.dpr` y
`tests/FactuzamTests.dproj` incorporan las unidades nuevas.

## Verificación de compilación y pruebas

Ejecutada el 30/07/2026 con Delphi 37.0. Se usaron salidas separadas
dentro de `build\validacion_t1t6` para no sustituir los ejecutables de
trabajo.

- [x] `.\scripts\comprobar_dependencias_capas.ps1`: correcto, 484
      unidades analizadas y ciclo mayor 1.
- [x] `.\scripts\comprobar_sql_en_dominio.ps1`: correcto.
- [x] `.\scripts\comprobar_sql_transacciones.ps1`: correcto, 98
      literales fijos, 3 identificadores con lista blanca y 0 valores
      externos concatenados.
- [x] Release Win32 y Release Win64 de `fzam.dproj`: 347.384 líneas y
      0 errores en ambas plataformas.
- [x] Release Win32 y Release Win64 de `FactuzamTests.dproj`: compila y
      ejecuta 386/386 pruebas en ambas plataformas, sin ignoradas,
      fugas, fallos ni errores. Las 32 pruebas T1-T6 están incluidas:
      antes de registrar `PruebasModoTallas` el ejecutable encontraba
      354 y después encuentra 386.
- [ ] `.\scripts\comprobar_tamano_clases.ps1`: las diez clases T1-T6 y
      `UniDataModoTallas` alcanzan sus objetivos y respetan sus topes.
      El script global termina con código 1 por una regresión ajena al
      foco: `TfrmMtoComprasSesiones` tiene 3.669 líneas frente al tope
      3.659.
- [ ] `.\scripts\comprobar_flujos_largos.ps1`: se detiene antes de
      comprobar el foco porque no encuentra una implementación única de
      `GuardarRegistroNoVerifactu`, afectada por la refactorización
      concurrente de Verifactu.
- [ ] Pruebas funcionales de §9: `inMtoAlbaranes` (entrada inline,
      consolidación y des-pivote), `inMtoPedidosCompra` (cambio entre
      modos y conservación de unidades), `inMtoDocumentosTrabajo` (clave
      de documento simple y celdas), `inMtoModalDistribuidor`
      (cantidades por almacén y cancelación)

Durante la verificación se corrigieron tres defectos de integración:

- las unidades T1-T6 estaban en los `.dproj`, pero no en el `uses` de
  `fzam.dpr`;
- `DoblesModoTallas` y `PruebasModoTallas` estaban en el `.dproj` de
  pruebas, pero no en el `uses` del ejecutable y, por tanto, sus 32 casos
  no se ejecutaban;
- el trinquete conservaba únicamente `TModoEntradaTallas` con su tope
  antiguo. Se restauraron las diez clases resultantes, sus topes actuales
  y `UniDataModoTallas`.

Comprobaciones que sí se han hecho desde esta sesión, con un verificador
estático propio:

- toda declaración de método tiene implementación y viceversa en las once
  unidades nuevas o tocadas;
- toda clase que declara implementar una interfaz declara sus métodos
  (`IModoEntradaGrid`, `IPersistenciaModoTallas`,
  `ILineasDocumentoTallas`, `IBusquedaSkusTallas`,
  `ISelectorValorAtributo`, `IArticulosAtributosLookup`);
- ninguna línea supera las 80 columnas;
- cero sentencias SQL en las unidades `inLib*` del foco;
- los símbolos del distribuidor solo se nombran en su unidad nueva, en la
  presentación y en `inMtoModalDistribuidor`.
