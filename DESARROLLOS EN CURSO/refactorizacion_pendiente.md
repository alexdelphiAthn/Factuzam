# Auditoría de código Factuzam — refactorización y reducción de acoplamiento

Fecha: 26/07/2026 · Alcance: 276 unidades `.pas` de `src/` (~104.000 líneas) + `fzam.dpr`.
Metodología: grafo completo de `uses` (fan-in/fan-out, ciclos), barrido automático de
smells (métodos gigantes, globales, SQL concatenado, `except` vacíos, duplicación por
similitud) y revisión manual en profundidad de los tres subsistemas mayores
(framework de formularios, documentos de venta, compras/sesiones). Todas las
afirmaciones llevan referencia `fichero:línea` verificable.

Lo primero: el proyecto ya tiene una dirección arquitectónica buena y a medio
ejecutar — las interfaces `inLib*Intf` (parámetros, conexiones, permisos, contexto de
sesión, auditoría, monitor SQL, filtros, hoja de cálculo), la familia estrategia
`inLibColumnasSku*` y la regla del §14 del libro de estilo ("no se crean nuevas
variables globales"). La mayor parte de lo que sigue no es introducir arquitectura
nueva, sino **terminar la migración que ya está empezada**.

---

## 1. El problema estructural nº 1: el ciclo de 44 unidades alrededor de `inMtoPrincipal`

El grafo de `uses` tiene un componente fuertemente conexo de **44 unidades** que
incluye `inMtoPrincipal`, `inMtoFrmBase`, `inMtoGen`, `UniDataConn`, `UniDataGen`,
`inLibLog`, `inLibUser`, `inLibtb`, `inLibGlobalVar`, `inLibShowMto`… Es decir: el
núcleo entero es un único nudo circular. Cualquier cambio en el form principal
"toca" potencialmente todo, y ninguna pieza del núcleo es compilable ni testeable
por separado.

Las aristas que sostienen el nudo son pocas y baratas de cortar:

1. **`inLibGlobalVar` → `inMtoPrincipal` por una variable muerta.**
   `inLibGlobalVar.pas:37` declara `ofrmMto2: TfrmMtoPrincipal`; se asigna en
   `inMtoPrincipal.pas:761` y **no se lee en ningún sitio** (verificado con grep en
   todo el árbol). Borrar la variable y el `uses inMtoPrincipal` del interface
   libera a las ~21 unidades que dependen de `inLibGlobalVar` de arrastrar toda la UI.
   Coste: 5 minutos. Es la arista central del ciclo.

2. **9 data modules importan `inMtoPrincipal` en `interface` sin usar ningún símbolo.**
   `UniDataFacturas`, `UniDataPedidos`, `UniDataAlbaranes`, `UniDataClientes`,
   `UniDataDevolucionesCompra`, `UniDataPedidosCompra`, `UniDataComprasSesiones`,
   `UniDataAlbaranesCompra`, `UniDataFacturasCompra` (p. ej.
   `UniDataFacturas.pas:22`). Cero referencias a `TfrmMtoPrincipal` en esos ficheros.
   Son `uses` muertos: se borran y ya.

3. **`inLibUnitForm` → `inMtoPrincipal` solo por un cast innecesario.**
   `inLibUnitForm.pas:102,115,127-128` hace `(AOwn as TfrmMtoPrincipal).FindComponent(...)`,
   pero `FindComponent` es de `TComponent`. Cambiar el cast a `TComponent` corta la arista.

4. **`inLibDevExp` → `inMtoPrincipal`** (`inLibDevExp.pas:31,1114-1117`): una librería
   de utilidades DevExpress no debería conocer el form principal; el cast que hace
   solo necesita `TForm`/`TcxPageControl`.

Con esos cuatro cortes (ninguno cambia comportamiento), el SCC se fragmenta y
`inMtoPrincipal` deja de ser dependencia de las librerías. La regla a fijar después
en el libro de estilo: **ninguna unidad `inLib*` ni `UniData*` puede usar unidades
`inMto*`** (hoy ocurre también al revés del flujo natural en
`UniDataFacturas.pas:216`, que usa `inMtoFacturasBase` en implementation).

Ciclos menores del mismo tipo (Mto ↔ UniData ↔ Modales): facturas/clientes/empresas
(8 unidades), devoluciones compra (5), albaranes compra (5), familias/tarifas (4),
pedidos compra (3). Todos se rompen con el mismo patrón: el modal no debe usar el
Mto que lo abre; lo que necesite se le pasa por parámetros del constructor.

---

## 2. Estado global mutable: terminar la migración a interfaces

El §14 del libro de estilo ya lo dice; falta ejecutarlo:

- **`inLibGlobalVar`**: además de `ofrmMto2` (muerta), `oLicenciaAplicacion*` (4
  variables) encajan en el contexto de sesión/parametrización; `oNomImpresoraCaja`
  en `IParametrosCaja`; `oLogSesion`/`LogSes` como receptor del log
  (`inLibMonitorSQLIntf`/`ILog` ya existen); `oCerrandoApp` como
  `IContextoSesion.EstaCerrando`. `TfrmBase` ya resuelve las interfaces por
  `Supports` en su constructor (`inMtoFrmBase.pas:166-199`): la infraestructura de
  inyección existe, estas rutas simplemente no la usan todavía.
- **`oMemoSQL` es un puntero colgante en potencia**: se asigna en
  `inMtoPrincipal.pas:694`, nunca se pone a `nil`, y `inLibLog.pas:223-225,833-837`
  lo usa tras `Assigned()` — si se loguea durante el cierre, acceso a memoria
  liberada. Sustituir por el monitor SQL por interfaz cierra el riesgo.
- **`oInfGuiasCache` se crea dos veces y no se libera nunca**
  (`inMtoPrincipal.pas:1099` y `:1181`, sin liberación en `FormClose`): fuga en cada
  re-login.
- **Globales muertas**: `sConsultaO`/`sConsultaP` (`inMtoGen.pas:384-385`) no tienen
  ni lecturas ni escrituras. Borrar.
- **`inMtoLogon.pas` declara `sPass, sPassEn, sUserPassOK` como globales de
  interface**: credenciales en variables globales; deberían ser campos privados del
  form o del contexto de sesión.

---

## 3. Las clases dios: `TfrmMtoGen`, `inMtoFacturasBase`, `inMtoPrincipal`

### 3.1 `TfrmMtoGen` (3.239 loc, 63 métodos, fan-in 49)

Acumula al menos seis responsabilidades extraíbles, varias con destino ya existente:

| Responsabilidad | Líneas | Destino propuesto |
|---|---|---|
| Perfiles/preferencias de pantalla | 423-577, 656-804, 2756-2808 | Servicio tras `IPerfilesUsuario` (ya inyectada en `inMtoFrmBase.pas:74`) |
| Guías de grid + column chooser | 1829-1942, 1981-2278 | `inLibGridColumnChooser` (ya existe) |
| Filtros guardados (Base64) | 2863-3238 | Clase tras `IFiltrosGuardados` (`inLibFiltrosGuardadosIntf` ya existe) |
| Tareas en background + overlay | 1285-1723 | `TEjecutorTareasMto` + control overlay reutilizable |
| Dominio "artículos" (fotos, stock, SKU) en la base | 2637-2691 | Un `TfrmMtoArticulosBase` intermedio: un Mto de Países no debe conocer SKUs |
| Diagnóstico de metadata BBDD | 1943-1980 | `inLibDiag` (ya existe) |

Problemas puntuales dentro de la misma unidad: fuga de `FCamposGuiaTabla` y
`FColumnasVisiblesGuia` (creadas en `:1930-1935`, no liberadas en `Destroy`);
cast `Owner as TfrmMtoPrincipal` sin `is` en `CrearTablaPrincipal` (`:1174-1177`)
mientras `AplicarPermisosPantalla` (`:1227`) sí comprueba; y el timeout de tareas
(`:1697-1722`) que "abandona" el `TdmBase` y la `TUniConnection` sin liberarlos —
acumula conexiones vivas contra MariaDB con servidor lento.

### 3.2 `inMtoFacturasBase` (4.261 loc, 252 métodos) y la familia de documentos

El hallazgo más rentable del análisis: **el patrón documento
(cabecera + líneas + totales + SKU/tallas) está clonado 4 veces** — Facturas,
FacturasCompra, Albaranes, Pedidos. Métodos casi idénticos salvo el sufijo de campo
(`_FAC`/`_ALB`/`_PED`): `ConstruirModoEntrada` (FacturasBase:3527, Pedidos:1383,
Albaranes:707, FacturasCompra:1276), `AplicarArticulo*`, `PrecioSkuTallas`,
`AsegurarCabeceraPersistidaParaLineas`, `CrearColumnasHost*`… Estimación de código
realmente común: **1.100–1.400 líneas**.

Refactor propuesto: un `TfrmMtoDocumentoBase` parametrizado con un descriptor
`TMapaCamposDoc` (tabla, prefijo de campos, contador, vista) + un motor de líneas
compartido. Los herederos quedarían en 300–500 líneas de especificidades (Verifactu
solo en facturas, albaranar solo en pedidos).

Lógica de negocio que vive en el form y debería bajar a `inLib*`/`UniData*`:

- Operaciones Verifactu completas en handlers de botón
  (`inMtoFacturasBase.pas:2297-2580`): transiciones de fase, `UPDATE fza_verifactu_cola`
  con `FOR UPDATE`… inaccesible desde caja o procesos batch.
- SQL crudo en 7 puntos del form (`:724-760`, `:1529-1570`, `:2084-2110`,
  `:2263-2278`, `:2494-2547`, `:3950-3965`).
- La conversión IVA incluido/excluido está implementada **tres veces** en el mismo
  form (`:4070-4092`, `:3144-3176`, `:4181-4222`), una de ellas con la guarda de
  división por cero y las otras dos sin ella. Y `:3149-3157` lee
  `PORCENTAJE_IVA?_FAC` con `AsInteger` (trunca IVAs decimales) mientras `:4172-4176`
  usa `AsFloat`: dos rutas del mismo dato con redondeo distinto → descuadres de céntimos.
- `PorcentajeIvaFactura` (`:4163-4180`) duplica `PorcentajeIvaCabecera` que ya
  existe en `inLibVentasImpuestos.pas:358`.

Y el acoplamiento invertido más grave del proyecto: **el data module manipula la UI
del form**. `UniDataFacturas.ValidarCabeceraBeforePost` (`:2502-2670`) hace
`frmFac.pcCab.ActivePage := ...` y `SetFocus` sobre controles concretos, y `:2368`
llama a `sbNuevaFacturaClick` desde un `AfterInsert`. Eso obliga al flag anti-reentrada
`FValidandoPost` (`:2483-2500`), que es el síntoma. La validación debe devolver un
`TResultadoValidacion` (campo culpable + mensaje) y que el form decida pestaña/foco.

Además hay **dos motores fiscales paralelos**: facturas usan `TFacturaTotales`
(`inLibFacturas.pas:641-1130`) y pedidos/albaranes usan
`CalcularTotalesDocumentoVenta` (`inLibVentasImpuestos.pas:609`). Mismas reglas
(bases por tipo, recargo, retención) mantenidas dos veces.

### 3.3 `inMtoPrincipal` (2.819 loc, fan-out 48)

52 handlers `OnClick` idénticos que solo hacen `ShowMto(Self, '<literal>')`: cada
pantalla nueva obliga a tocar el form principal. Un único handler compartido que
lea el `Call` desde el `Tag`/nombre del `TMenuItem` (la infraestructura
`oFzaWinf.CallRegistrado` de `inLibUnitForm.pas:292` ya existe y se usa en
`AplicarPermisosMenu`) elimina el grueso del fan-out.

Trampa latente detectada y verificada: `WM_FREECONTROL` está definida **dos veces
con valores distintos** — `inMtoPrincipal.pas:56` (`WM_USER`) y `inMtoGen.pas:623`
(`WM_USER + 1`). Hoy funciona porque inMtoGen postea su propia constante y el
handler escucha `WM_USER + 1`, pero la constante del Principal está mal y quien la
use "de buena fe" enviará un mensaje que nadie procesa. Definirla una sola vez en
una unidad común.

---

## 4. Apertura de pantallas: RTTI sobre strings de BBDD

`inLibShowMto.pas:122-128` resuelve la clase del form con
`ctx.FindType(ofzaF.UnitForm)` a partir del texto de la columna `UNITF_WINF`, y
`CrearDataModule` (`:206-266`) repite el patrón con el agravante de usar
`NewInstance` + llamada manual al constructor en lugar de la metaclase. Consecuencias:
un typo en la tabla o una unidad no enlazada en el `.dpr` solo revienta en runtime,
y las ~350 entradas del `.dpr` hay que mantenerlas sincronizadas a mano.

Propuesta: registro explícito por clase — cada Mto se auto-registra en su
`initialization` (`RegistrarPantalla('Clientes', TfrmMtoClientes, TdmClientes)`)
en un `TDictionary<string, TPantallaInfo>`; la BBDD aporta caption, shortcut y
permiso, no nombres de clase. Encaja con el `ForceReferenceToClass` que el libro de
estilo ya exige (§15.10). Otros puntos del mismo módulo: identidad de ventana
comparando `Trim(Caption)` (`inLibFormManager.pas:113-124`) — clave estable en el
`Tag` del tab; detección de la caja por `ClassName = 'TfrmMtoMenuCaja'` en texto
(`inLibShowMto.pas:72`); SQL de facturas dentro del abridor de pantallas
(`:268-295`); y `inLibFormManager.pas:166-174` conociendo `TfrmMtoGen` (debería ser
una interfaz `IVentanaCerrable`).

---

## 5. Duplicación compra/venta: dónde sí y dónde no

Medido por similitud + verificación función a función:

| Par | Similitud | Veredicto |
|---|---|---|
| `inMtoModalCargarEfectosRemesa` ↔ `...RemesaVenta` | 99% | **Unificar ya.** Difieren en sufijos EFEC/EFV, tabla, prefijo de SP `PRC_REMC_*`/`PRC_REMV_*` y un literal. Un record `TConfigRemesa` inyectado en `FormCreate` elimina ~370 líneas. |
| `inLibComprasImpuestos` ↔ `inLibVentasImpuestos` | 93% | **14 funciones byte-idénticas** (~350 líneas): `CampoFloat`, `NormalizarTipoIva`, `LeerPorcentajesIvaPorEmpresa`, `PorcentajeIvaCabecera`… → extraer a `inLibImpuestosComun`. Las `CalcularTotalesDocumento*` sí divergen de verdad (RE/intracomunitario vs IRPF): dejarlas separadas. |
| `CrearAlbaranDesdePedido` ↔ `...ConCantidades` (`inLibPedidosCompra.pas:443-792` y `794-1143`) | ~2/3 común | Unificar con `ACeldas: TArray<TCeldaARecibir>` donde `nil` = "todo lo pendiente". Elimina ~230 líneas. |
| `inLibGridPivoteCompra` ↔ `inLibGridPivoteVenta` | 95% textual | **NO unificar.** La similitud es engañosa: arquitecturas distintas (clase plana vs `TInterfacedObject/IModoEntradaGrid`), modelos distintos (líneas reales vs vista temporal en ClientDataSet con 3 bandas), APIs sin intersección. Extraer solo el núcleo común de caché de celdas (`TCachePivotTallas`) y hacer que la de Compra implemente `IModoEntradaGrid` para vivir bajo la misma factoría. |

---

## 6. Robustez: transacciones, excepciones y fugas

Esto es lo que puede costar dinero en producción, más allá de la estética:

1. **Borrado de factura sin transacción** (`UniDataFacturas.pas:2212-2337`): efectos,
   líneas, recibos y movimientos se borran en 4 pasos sueltos; un fallo intermedio
   deja cabecera con huérfanos o stock sin revertir. Además dos `with ... Free` sin
   `try/finally` (`:2290-2322`).
2. **Movimientos de almacén sin transacción y en `AfterPost`**
   (`UniDataFacturas.pas:2672-2838`, disparado desde `:2101-2122`): un corte a mitad
   deja stock descontado parcialmente. La idempotencia depende de un
   `SELECT ... LIMIT 1` sin bloqueo (`:2712-2727`): dos usuarios grabando a la vez
   pueden duplicar movimientos → índice único + `INSERT ... ON DUPLICATE KEY`.
3. **Asimetría**: `UniDataAlbaranes.pas:1715` sí usa el patrón `bTransPropia`;
   `UniDataPedidos.CrearAlbaranDesdePedido` (`:1582-1700`) encadena 3 `ExecProc` sin
   transacción. Aplicar el mismo patrón.
4. **Fallo de totales silenciado**: `ProcesarFacturaCompleta` devuelve `False` ante
   cualquier excepción (`inLibFacturas.pas:890-916`) y el llamante ignora el
   resultado (`inLibtb.pas:434-440`) → la factura puede grabarse con totales a 0.
5. **12 `except`/`end` vacíos** en el proyecto; los peores en
   `inLibComprasSesionesMaterializar.pas` (8 de 12 silenciados; el de `:2555` traga
   justo el fallo que, según su propio comentario en `:2541-2547`, provocaría
   duplicar documentos al re-materializar). Sustituir por log + lista de avisos
   devuelta al llamante.
6. **AV latente**: `ExistePeriodoUnico` (`inLibtb.pas:1432-1501`) usa un
   `TClientDataset` local sin inicializar a `nil` que solo se crea en una rama;
   las comprobaciones `Assigned(cli)` posteriores leen basura de pila.
7. **Fugas**: queries sin `try/finally` en `BuscarCliente` y
   `CalcularRetencionesEmpresa` (`UniDataFacturas.pas:600-624`, `:670-700`);
   `FreeAndNil` inline de forms dentro de un handler de mensaje
   (`inLibFormManager.pas:176-186`) — usar `Release`.
8. **Rendimiento en edición de líneas**: `ActualizarLineaFacturaGen` recalcula toda
   la factura en cada `EditValueChanged`, y cada línea resuelve ~12 campos con
   `FieldByName` (`inLibFacturas.pas:1171-1183`, `:411-431`). Con 200+ líneas se
   nota. Cachear `TField` y separar "recalcular línea" de "reagregar totales".

---

## 7. `inLibtb`: partir la caja de herramientas

1.514 líneas, 42 unidades dependientes, nueve dominios sin relación: cripto AES
(`:775-909`), NIF/IBAN (`:1197-1377`, que además **duplica** `inLibIBAN.pas`), INI y
rutas (`:1085-1196`), construcción de conexión con password en connection string
(`:704-756` — redundante: UniDAC ya recibe `Server/Username/Password` como
propiedades), utilidades de dataset (`:124-366`), búsqueda/filtros (`:910-1084`),
series y contadores (`:367-655`), split de strings (`:1383-1426`). Su `uses`
(`:19-26`) arrastra ADO, COM, Midas y SOAP a los 42 dependientes por una única
función. Partirla por esos cortes reduce el árbol de compilación del 95% del
proyecto y elimina la duplicación con `inLibIBAN`/`inLibDefaultValues`/`inLibDir`.

Métodos de más de 200 líneas en el proyecto: **37** (los mayores:
`RevertirMaterializacion` 394, `MaterializarSesion` 369,
`CrearAlbaranDesdePedido*` 351×2, `ImprimirResguardoDeposito` 340,
`TdmConsultaOpe.DataModuleCreate` 330). Para los dos de materialización, los
comentarios numerados que ya tienen son la especificación de los pasos a extraer;
`RevertirMaterializacion` es una lista de 19 DELETEs que cabe en una tabla
declarativa `array of record` recorrida en bucle (~40 líneas).

---

## 8. Plan de acción priorizado (valor/riesgo)

**Fase 0 — cortes sin riesgo (un día):**
borrar `ofrmMto2`, `sConsultaO/P` y los 9 `uses inMtoPrincipal` muertos de los
UniData*; cast de `inLibUnitForm` a `TComponent`; unificar `WM_FREECONTROL` en una
sola constante. Resultado: el ciclo de 44 unidades se desarma.

**Fase 1 — robustez de datos (una semana):**
transacciones en borrado de factura, movimientos de almacén y
`CrearAlbaranDesdePedido`; propagar el fallo de `ProcesarFacturaCompleta`;
`try/finally` en las queries sin protección; índice único en movimientos;
sustituir los `except` vacíos de materialización por log de avisos.

**Fase 2 — duplicación barata (una-dos semanas):**
`inLibImpuestosComun` (14 funciones idénticas), unificar modales de remesa
(`TConfigRemesa`), fusionar `CrearAlbaranDesdePedido` con su variante,
unificar la conversión IVA incl./excl. en una función única (y de paso el bug
`AsInteger`).

**Fase 3 — desacoplar UI ↔ datos (incremental, por pantalla):**
`ValidarCabeceraBeforePost` devuelve resultado en vez de tocar el form; sacar el
SQL y el Verifactu de `inMtoFacturasBase` a libs; registro de pantallas por clase
en `initialization` sustituyendo el RTTI por string; handler único de menú en
`inMtoPrincipal`; regla del libro de estilo: `inLib*`/`UniData*` no usan `inMto*`.

**Fase 4 — las clases dios (por fascículos, solo cuando toques esa zona):**
extraer de `TfrmMtoGen` los seis bloques de la tabla §3.1 (empezando por filtros
guardados y perfiles, que ya tienen interfaz destino); `TfrmMtoDocumentoBase` +
`TMapaCamposDoc` para la familia de documentos; partir `inLibtb`; trocear
`MaterializarSesion`/`RevertirMaterializacion`; extraer el dialecto SQL y el
buscador inline de `inLibColumnasSkuModoTallas`.

Como red de seguridad transversal: hoy no hay tests (no existe ningún proyecto
DUnit/DUnitX en el árbol). Las piezas que van quedando puras (impuestos, IBAN,
contadores, materialización por pasos, mapas de campos) son exactamente las
testeables sin UI ni BBDD; añadir un proyecto DUnitX e ir cubriendo cada pieza al
extraerla convierte el resto del plan en cambios seguros.

---

### Nota final

La familia `inLibColumnasSku*` (Intf + factoría + tres modos) es el patrón a imitar
en el resto del proyecto: contrato pequeño con GUID, configuración por record,
estrategias intercambiables. La dirección ya está marcada dentro del propio código;
esta auditoría solo señala dónde falta llegar.
