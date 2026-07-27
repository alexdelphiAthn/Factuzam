# Plan de lo PENDIENTE — refactorización Factuzam

Fecha: 26/07/2026. Parte de `refactorizacion_estado.md` (grupos B a E) y
de la auditoría `refactorizacion_pendiente.md`. El grupo A ya está hecho
(`refactorizacion_bloqueA_resultados.md`), así que este plan cubre los
**19 puntos que quedan**, reordenados por lo que de verdad conviene hacer
antes.

Todas las cifras de aquí están medidas **hoy, sobre el código ya
commiteado** (`2561a179`), no copiadas de la auditoría inicial.

## Retrato actual del proyecto

| Métrica | Valor hoy |
|---|---|
| Unidades en `src` (sin `Lib3par`) | 277 |
| Ciclos de dependencias (SCC > 1 unidad) | 21 |
| Ciclo mayor | 18 unidades (Artículos/Clientes/Empresas/Familias/Proveedores/Tarifas y sus Mto) |
| Ciclo del núcleo | 13 unidades (`inMtoGen`, `inLibShowMto`, `inLibFormManager`, `UniDataGen`…) |
| Ciclo de librerías | 8 unidades (`inLibtb`, `inLibGlobalVar`, `inLibLog`, `inLibUser`…) |
| Infracciones «`inLib*`/`UniData*` no usa `inMto*`» | 33 (8 son `uses` muertos) |
| Fan-out de `inMtoPrincipal` | 47 unidades |
| Manejadores `OnClick` en `inMtoPrincipal` | 71, de ellos 54 de menú |
| Métodos de nivel superior > 200 líneas | 48 |
| Familia de documentos (6 formularios) | 16.335 líneas, **40 métodos con el mismo nombre en ≥3 de ellos** |
| Ficheros con EOL mixtos CRLF/LF | 128 de 278 |

## El orden que propongo, y por qué

La tentación es ir a por las clases dios, que es donde está el bulto.
Sería un error hacerlo ahora: `TfrmMtoGen` tiene 3.243 líneas y 29
dependencias, y partirlo sin red de seguridad significa comprobarlo todo
a mano cada vez. Antes conviene (1) terminar de desacoplar, que es barato
y reduce el radio de explosión de cualquier cambio posterior, y (2)
montar el proyecto de pruebas unitarias. Con eso hecho, trocear las
clases dios pasa de ser una apuesta a ser trabajo rutinario.

Así que: **Fase 3 (terminar) → Fase 4 (estado global) → Fase 5 (DUnitX) →
Fase 6 (clases dios) → Fase 7 (higiene)**. Las fases 1 a 3 originales ya
están hechas; mantengo la numeración para no romper las referencias de
los documentos anteriores.

---

# Fase 3 — terminar el desacoplamiento

Cuatro bloques. Es la fase con mejor relación valor/riesgo que queda.

## Bloque B1 — el `uses` invertido (½ día, riesgo muy bajo)

**Qué pasa.** 33 unidades de librería o de datos usan unidades de
formulario. Es la inversión de dependencias al revés: la capa de abajo
conoce la de arriba. Ocho de esas 33 son **`uses` muertos** (la unidad
está en la cláusula pero no se referencia ningún tipo suyo):
`UniDataAtributosBasicos`, `UniDataGrupos`, `UniDataProveedores`,
`UniDataTarifas`, `UniDataUsuariosPerfiles`, `inLibArticulosPropiedades`,
`inLibGenerarTicket` e `inLibGenerarTicketBD`. Se borran y ya.

De las 25 vivas, **18 son el mismo patrón repetido**: el data module
sube al formulario a buscar su `TDataSource` para el maestro-detalle.

```pascal
unqryLineas.MasterSource := (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
```

`dsTablaG` no es de `TfrmMtoEmpresas`: está declarado en `TfrmMtoGen`,
la base. Es decir, 18 dependencias concretas donde bastaba una genérica —
y ni siquiera hace falta esa, porque ya resolvimos este mismo caso en
`UniDataFacturas` durante la Fase 3: el formulario **empuja** el
DataSource al DM con `AsignarMaestroCabecera(dsTablaG)`.

**Qué hacer.** Subir `AsignarMaestroCabecera` a `TdmBase` (virtual, con
implementación por defecto vacía) y que `TfrmMtoGen.CrearTablaPrincipal`
la llame siempre después de crear el DM. Cada DM sobreescribe el método y
cablea sus MasterSource ahí. Once data modules solo usan `.dsTablaG` y
salen con esto exactamente; dos tienen algo más (`UniDataArticulos` toca
además `tvStock`, `UniDataGeneradorProcesos` toca `SynEdit1`) y necesitan
un evento adicional cada uno, igual que hicimos con `OnCampoInvalido`.

Quedan siete casos sueltos que van uno a uno: `inLibDefaultValues` e
`inLibGenBusq` → `TfrmMtoSearch`, `inLibColumnasSkuModoTallas` →
`TfrmModalDistribuidor`, `inLibLayoutForm` → `TfrmModalGenImpSave`, y los
tres de `inLibShowMto`/`inLibFormManager` → `TfrmMtoGen`/`TfrmMtoPrincipal`,
que se resuelven solos en el bloque B2.

**Resultado esperado:** infracciones 33 → 6, el ciclo de 18 unidades
desarmado, y el `.dpr` deja de arrastrar formularios por culpa de los DM.

**Pruebas.** Compilación limpia y una pasada de apertura de las 13
pantallas afectadas comprobando que el detalle sigue a la cabecera al
navegar. Es la misma comprobación W1 que ya pasó en facturas (prueba #9
de `pruebas_ui_resultados.md`). Riesgo real: que un DM se quede sin
cablear y su grid de detalle salga vacío — se ve a simple vista.

## Bloque B2 — registro de pantallas por clase (2 días, riesgo medio)

**Qué pasa.** `inLibShowMto` resuelve la clase del formulario por
**nombre de unidad guardado en la base de datos**, vía RTTI
(`ctx.FindType(ofzaF.UnitForm)`), y el data module por `NewInstance`
sobre un tipo encontrado igual. Un error de tecleo en una fila de la
tabla de pantallas se convierte en un fallo en tiempo de ejecución, y
mantener el `.dpr` sincronizado a mano es obligatorio para que el
linker no elimine unidades «no usadas». Además la identidad de una
ventana abierta se decide **comparando captions** (`FindFormByCaption`,
con el truco de añadir ' 1', ' 2'…), lo que rompe en cuanto alguien
traduce o cambia un título.

**Qué hacer.** Auto-registro: cada unidad `inMto*` registra su clase en
su `initialization` contra un registro central (`TRegistroPantallas`),
y `ShowMto` busca por clave, no por cadena RTTI. La clave de identidad
de la ventana pasa del caption al `Tag` del formulario. Se saca el SQL
de facturas que hoy vive dentro del abridor. Y `inLibFormManager` deja
de conocer `TfrmMtoGen`: se declara `IVentanaCerrable` y el manager
habla con la interfaz.

**Resultado esperado:** muere el ciclo del núcleo (13 unidades), y los
errores de configuración pasan de fallo en runtime a fallo en el
registro, detectable al arrancar.

**Plan de pruebas** (esto sí toca algo delicado):

1. Script que recorra la tabla de pantallas y compruebe que **cada fila
   tiene clase registrada** — se ejecuta al arrancar en modo depuración y
   lista las que no. Es la red que sustituye al fallo silencioso actual.
2. Abrir las pantallas una por una desde el menú (hay que cubrir el 100 %,
   no una muestra: el riesgo es justo que una quede sin registrar).
3. Abrir la misma pantalla dos y tres veces: comprobar que la segunda
   instancia se identifica bien ahora que no se usa el caption.
4. Cerrar pestañas con carga asíncrona viva — el camino de `Release` que
   arreglamos en el bloque A no debe cambiar.
5. Usuario con permisos restringidos: las pantallas sin permiso siguen sin
   abrirse.

## Bloque B3 — un solo manejador de menú (1 día, riesgo medio)

**Qué pasa.** `inMtoPrincipal` implementa **71 manejadores `OnClick`**, de
los que **54 son entradas de menú** que son el mismo código con otro
literal, y de ahí sale buena parte de su fan-out de 47. Cada pantalla
nueva obliga a tocar el formulario principal.

**Qué hacer.** Un único `MenuGenericoClick` que lee la clave de la pantalla
del `Tag` o del `Hint` del `TMenuItem` y llama a
`TfzaWinF.CallRegistrado` (`inLibUnitForm`, que ya existe y ya se usa
desde `inMtoPermisosArbol`). Los 54 handlers de menú del `.dfm` apuntan al
mismo método. Depende de B2: sin el registro por clase esto no se
sostiene.

**Resultado esperado:** `inMtoPrincipal` baja de 2.825 líneas
sustancialmente y deja de crecer con cada pantalla nueva.

**Plan de pruebas.** Recorrer el menú entero entrada por entrada (son 72,
media hora) verificando que cada una abre la pantalla correcta; comparar
contra una captura previa del menú para no perder ninguna; repetir con
un usuario restringido para confirmar que el filtrado de permisos sigue
aplicándose antes de abrir, no después.

## Bloque B4 — ciclos Mto↔Modal de compras y la regla escrita (1 día, riesgo bajo)

Quedan tres ciclos claros, todos con la misma forma: el modal usa al Mto
que lo abrió.

- Devoluciones de compra: 5 unidades (`UniDataDevolucionesCompra`,
  `inMtoDevolucionesCompra`, `inMtoModalEtiqDev`, `inMtoModalImpDevCompra`,
  `inMtoModalImpDevCompraV`).
- Albaranes de compra: 5 unidades, patrón idéntico.
- Pedidos de compra: 3 unidades (`inMtoModalEtiqPed`).

El patrón de salida ya está probado en el modal de remesas: el modal
recibe por constructor lo que necesita y devuelve el resultado, sin
conocer a quien lo abre.

Y para que esto no vuelva: **codificar la regla en
`LIBRO_DE_ESTILO_DELPHI.md` §16** («ninguna unidad `inLib*` o `UniData*`
usa unidades `inMto*`») más un script corto que la comprueba y falla si
aparece una infracción nueva. Sin el script, la regla es decoración.

**Pruebas.** Imprimir etiquetas y documentos desde las tres pantallas de
compras, que es todo lo que hacen esos modales.

---

# Fase 4 — sacar el estado global (2 días, riesgo medio-alto)

Estado a 27/07/2026: C1 y C2 implementados y compilados. Pruebas funcionales
pendientes. Detalle en `refactorizacion_fase4_resultados.md`.

`inLibGlobalVar` tenía al iniciar esta fase 76 líneas y **12 variables
globales**, y participaba en el ciclo de 8 unidades de librería. La
infraestructura de
inyección de `TfrmBase` ya existe de fases anteriores, así que esto es
migrar, no diseñar: `IParametros`/`IParametrosAplicacion`/
`IParametrosCaja` están en `inLibParametrosIntf` y
`IContextoSesionAplicacion` en `inLibContextoSesionIntf`.

**C1 — parámetros y contexto.** `oLicenciaAplicacion*` (4 variables) a
`IParametrosAplicacion`; `oNomImpresoraCaja` a `IParametrosCaja`;
`oCerrandoApp` y `oLogSesion` a `IContextoSesionAplicacion`; `oMemoSQL` al
monitor SQL; `oInfGuiasCache` al colaborador de guías que sale de D2.
Quedarían solo `oAppName`, `oVersion` y `oAll`, que son constantes de
verdad y pueden pasar a `const`.

**C2 — credenciales.** `inMtoLogon` (línea 165) exponía `sPass`, `sPassEn`
y `sUserPassOK` como variables globales de la sección `interface`.
Cualquier unidad del proyecto puede leer la contraseña de la base de
datos. Encapsular en el propio formulario de logon y devolver solo el
resultado.

**Plan de pruebas** (aquí sí, porque toca licencia y acceso):

1. Arranque con licencia válida, con licencia caducada y sin licencia:
   los tres mensajes y comportamientos deben ser los de antes.
2. Login correcto, contraseña incorrecta, usuario inexistente.
3. Re-login 3 veces seguidas sin cerrar la aplicación (es donde estaban
   las fugas del bloque A; hay que confirmar que la migración no las
   reintroduce).
4. Cierre de la aplicación con el monitor SQL abierto y con una tarea
   asíncrona en curso — `oCerrandoApp` y `oMemoSQL` son justo los dos que
   se tocan al apagar.
5. Impresión por la impresora de caja tras cambiarla en parámetros.

---

# Fase 5 — la red de seguridad (2-3 días, riesgo nulo)

Estado a 27/07/2026: **terminada**. Proyecto DUnitX creado y validado en
Debug/Win64, Debug/Win32 y Release/Win64: 16/16 pruebas en verde y sin
fugas. Detalle en `refactorizacion_fase5_resultados.md`.

**Proyecto DUnitX.** Este es el punto 22 de la lista y lo subo aquí
arriba a propósito: es lo único que hace que la Fase 6 sea razonable.

Las piezas que ya extrajimos son testeables sin interfaz y sin base de
datos: `inLibImpuestosComun` (14 funciones), los dos helpers de
conversión de IVA, `PorcentajeIvaCabecera`, los cálculos de totales. Un
proyecto `FactuzamTests.dproj` con esos casos, más los que vayan saliendo
al partir las clases dios, ejecutable desde la línea de órdenes y desde
el IDE.

Las baterías de Python que hemos escrito (96 comprobaciones sobre datos)
se quedan como están: cubren SQL y contratos de procedimientos, que
DUnitX no cubre bien. Son complementarias, no sustitutas.

Criterio de terminado: `FactuzamTests.exe` pasa en verde y está en el
`.gitignore` de binarios pero no de fuentes.

---

# Fase 6 — las clases dios, por fascículos

Aquí no hay un «hecho» limpio: es trabajo que se hace mientras se toca
cada zona. Lo ordeno por retorno.

## D1 — `TfrmMtoDocumentoBase` (la mayor duplicación que queda)

Los seis formularios de la familia suman **16.335 líneas** y comparten
**40 métodos con el mismo nombre en tres o más de ellos**:
`CrearTablaPrincipal`, `CrearColumnasTallas`, `CrearColumnasAtributos`,
`InicializarGestorYPivote`, `ConstruirModoEntrada`, `ResolverArtSkuActivo`,
`SqlRestriccionUsuario`, `RefrescarVisibilidadTallas`… La forma de trabajo
que ya funcionó con `inLibImpuestosComun`: extraer de dos en dos métodos,
compilar, y no seguir hasta que compile limpio.

Empezar por los que no tocan datos: `CrearColumnasTallas`,
`CrearColumnasAtributos`, `RefrescarVisibilidadTallas`,
`RefrescarVisibilidadAtributos`, `ActualizarCaption*`. Dejar
`CrearTablaPrincipal` y `SqlRestriccionUsuario` para el final, que son los
que deciden qué ve cada usuario.

**Pruebas por fascículo:** abrir los seis documentos, comprobar columnas
de tallas y atributos, y una vez llegados a `SqlRestriccionUsuario`,
repetir con un usuario restringido a empresa/almacén (hay un documento
específico, `restriccion_usuario_emp_alm_caja_pruebas.md`, que sirve tal
cual).

## D2 — partir `TfrmMtoGen` (3.243 líneas)

Seis colaboradores según la auditoría: filtros guardados, perfiles de
pantalla, guías de grid, tareas + overlay, dominio de artículos y
diagnóstico. Uno por sesión de trabajo, extrayendo a clase con su propia
unidad y dejando en `TfrmMtoGen` una referencia. Después de B1 y B2 su
fan-out habrá bajado bastante, lo que hace esto más llevadero.

## D3 — partir `inLibtb` (1.524 líneas, **44 unidades dependientes**)

Nueve dominios mezclados y duplica `inLibIBAN`. Al tener 44 dependientes
es la unidad más arriesgada de tocar del proyecto: la partición debe
hacerse **manteniendo `inLibtb` como fachada** que reexporta, para que
ningún `uses` se rompa, y solo después ir migrando los `uses` de los
dependientes por tandas.

## D4 — trocear los métodos largos (48 por encima de 200 líneas)

Los peores, medidos hoy:

| Líneas | Unidad | Método |
|---|---|---|
| 436 | `inLibBalanceTallasExcel` | `ExportarBalanceTallasExcel` |
| 421 | `inLibComprasSesionesMaterializar` | `RevertirMaterializacion` |
| 405 | `inLibBalanceSinTallasExcel` | `ExportarBalanceSinTallasExcel` |
| 388 | `inLibFacturaExcel` | `ExportarFacturaADevExpress` |
| 378 | `inMtoDevolucionesCompra` | `DevolverTodoStock` |
| 373 | `inLibComprasSesionesMaterializar` | `MaterializarSesion` |
| 351 | `inLibPedidosCompra` | `CrearAlbaranDesdePedidoConCantidades` |

Empezar por `MaterializarSesion`/`RevertirMaterializacion`, que ya tienen
pruebas de datos (`test_revertir_sesion.py`) y acabamos de tocarlos.
`CrearAlbaranDesdePedidoConCantidades` también está cubierto ahora
(`test_albaran_pedido_compra.py`, 38 comprobaciones), así que se puede
trocear con red. Los tres de Excel son los más largos pero los menos
delicados: no tocan datos.

## D5 — unificar los dos motores fiscales de venta

`TFacturaTotales` (`inLibFacturas`, usada desde `UniDataFacturas` e
`inLibtb`) y `CalcularTotalesDocumentoVenta` (`inLibVentasImpuestos`,
usada desde `UniDataPedidos` y `UniDataAlbaranes`) calculan lo mismo por
caminos distintos: las facturas van por una y los pedidos y albaranes por
otra. Es exactamente el mismo trabajo que
`inLibImpuestosComun` hizo con compra/venta, y ahora además con DUnitX
delante: escribir primero las pruebas que fijan el comportamiento actual
de los dos, y luego unificar hasta que ambas pasen.

---

# Fase 7 — higiene y varios

Trabajo suelto, sin dependencias entre sí, bueno para ratos cortos.

**SQL sin parametrizar.** La auditoría contó 54 concatenaciones en 26
ficheros. Mi recuento de hoy da entre 14 (criterio estricto) y 109
(criterio amplio, que incluye concatenación de literales, que es
inofensiva) en 35 ficheros, así que **el primer paso es una triaje
honesta**: separar las que interpolan un valor de usuario (riesgo de
inyección real) de las que solo pegan trozos de SQL fijo. Solo las
primeras hay que pasar a parámetros. Los casos que ya veo con nombre y
apellidos: `UniDataDocumentosTrabajo` líneas 447 y 536
(`CODIGO_ALM_DTL IN (' + sAlmacenes + ')`), `UniDataIvasGrupos` línea 89
y `UniDataFacturas` línea 1339 (`SELECT ' + sCampos`).

**`GenerarMovimientosSalidaFactura` fuera del `AfterPost`.** Sacarlo al
flujo de consolidación. Es una decisión de negocio, no técnica: hay que
tomarla contigo delante de la caja, y el comentario ya está puesto en el
código.

**Variantes locales de `CampoFloat`** en `inLibDocCompraExcel` e
`inLibFacturae` → converger sobre la común.

**Rendimiento del recálculo de líneas**: cachear los `TField` y separar
el cálculo de línea del de agregados. Se nota a partir de 200 líneas.

**EOLs mixtos: 128 de 278 ficheros.** Contra §1.9 del libro de estilo, y
me ha costado tiempo real en este refactor (los reemplazos byte a byte
fallaban por esto). Va en un commit aparte, sin mezclar con cambios
funcionales, y con `.gitattributes` para que no vuelva.

**Colación.** Los procedimientos de movimientos fallan si la base se crea
con una colación distinta de `utf8mb4_spanish_ci` — me pasó montando el
entorno de pruebas. Fijarlo en el instalador o en los propios
procedimientos.

---

# Resumen de esfuerzo

| Fase | Contenido | Días | Riesgo |
|---|---|---|---|
| 3 (B1–B4) | Terminar el desacoplamiento | 4-5 | bajo-medio |
| 4 (C1–C2) | Estado global y credenciales | 2 | medio-alto |
| 5 | Proyecto DUnitX | 2-3 | nulo |
| 6 (D1–D5) | Clases dios, por fascículos | por tandas | medio |
| 7 | Higiene y varios | ratos sueltos | bajo |

Lo que yo haría a continuación: **B1 ahora mismo**. Es medio día, quita
26 de las 33 infracciones, desarma el ciclo de 18 unidades y no cambia
comportamiento — el tipo de cambio que se comprueba compilando y abriendo
trece pantallas.

## Antes de arrancar

Sigue pendiente de tu lado: aplicar `movimientos_indice_unico_fcve.sql` a
la base real (tras la consulta de duplicados), la pasada de pantalla de
compras y del bloque A que quedó bloqueada, y borrar definitivamente
`_to_delete/inMtoModalCargarEfectosRemesaVenta.*`.
