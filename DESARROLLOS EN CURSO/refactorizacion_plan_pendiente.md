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

Estado a 28/07/2026: **D1 terminado; fascículos 6A a 6U cerrados**.
La creación,
visibilidad, captions de modo, carga de nombres de atributo por artículo y
globales, configuración del gestor/pivote, desmontaje del modo,
configuración base de columnas SKU, columnas host y configuración del
pivote por bandas están centralizados en
`inLibColumnasDocumento` para los cuatro documentos de compra que contenían
esa duplicación. Las búsquedas comunes de artículos y SKUs viven en
`inLibBusquedasCompra`. La validación previa a activar tallas en horizontal
y la persistencia de cabeceras de compra, pedidos y albaranes de venta viven
en `inLibValidacionDocumento`. La carga de básicos de color por artículo
vive en `inLibAtributosPaleta`. Pedidos, albaranes y facturas de venta e
inventarios reutilizan ya la configuración SKU y los nombres globales de
`inLibColumnasDocumento`. Los textos de proveedor y totales de prendas se
comparten mediante `inLibPresentacionDocumento`. La navegación común
entre mantenimientos vive en `inLibShowMto`.
La construcción y los callbacks de los ocho modos de documento, además
del desmontaje equivalente de venta e inventarios, se comparten mediante
`inLibColumnasDocumento`. La configuración de columnas en `FormCreate`,
el cierre defensivo y los hooks equivalentes de navegación, foco y
entrada al grid también se comparten en esa fachada. El teclado F1, los
ciclos y saltos de modo y la persistencia de la preferencia del pivote se
centralizan igualmente. La resolución del artículo/SKU activo y las
fuentes de refresco de la foto parten ya de la misma vista de líneas en
los ocho documentos. La creación o reutilización del DataModule, el
enlace de cabecera y líneas, los maestros de detalle y la clave de
navegación de `CrearTablaPrincipal` también se comparten, conservando
la preparación fiscal de facturas y el lookup de empresa de inventarios.
La restricción de consulta deriva ya las columnas estándar de empresa y
almacén para los ocho documentos y añade caja solo en facturas de venta,
sin cambiar la exención de administradores ni la tolerancia a `NULL`.
La batería DUnitX pasa 78/78. Detalles en
`refactorizacion_fase6a_resultados.md` y
`refactorizacion_fase6b_resultados.md` y
`refactorizacion_fase6c_resultados.md` y
`refactorizacion_fase6d_resultados.md` y
`refactorizacion_fase6e_resultados.md` y
`refactorizacion_fase6f_resultados.md` y
`refactorizacion_fase6g_resultados.md` y
`refactorizacion_fase6h_resultados.md` y
`refactorizacion_fase6i_resultados.md` y
`refactorizacion_fase6j_resultados.md` y
`refactorizacion_fase6k_resultados.md` y
`refactorizacion_fase6l_resultados.md` y
`refactorizacion_fase6m_resultados.md` y
`refactorizacion_fase6n_resultados.md` y
`refactorizacion_fase6o_resultados.md` y
`refactorizacion_fase6p_resultados.md` y
`refactorizacion_fase6q_resultados.md` y
`refactorizacion_fase6r_resultados.md` y
`refactorizacion_fase6s_resultados.md` y
`refactorizacion_fase6t_resultados.md` y
`refactorizacion_fase6u_resultados.md`.

Los ocho formularios de la familia suman **19.964 líneas** y comparten
**40 métodos con el mismo nombre en tres o más de ellos**:
`CrearTablaPrincipal`, `CrearColumnasTallas`, `CrearColumnasAtributos`,
`InicializarGestorYPivote`, `ConstruirModoEntrada`, `ResolverArtSkuActivo`,
`SqlRestriccionUsuario`, `RefrescarVisibilidadTallas`… La forma de trabajo
que ya funcionó con `inLibImpuestosComun`: extraer de dos en dos métodos,
compilar, y no seguir hasta que compile limpio.

El recorrido D1 queda cerrado. La comprobación automatizada pasa 78/78
y cada informe 6A–6U conserva su plan manual. Para la restricción de
usuario falta repetir con BBDD la matriz descrita en
`restriccion_usuario_emp_alm_caja_pruebas.md`.

## D2 — partir `TfrmMtoGen` (3.243 líneas)

Seis colaboradores según la auditoría: filtros guardados, perfiles de
pantalla, guías de grid, tareas + overlay, dominio de artículos y
diagnóstico. Uno por sesión de trabajo, extrayendo a clase con su propia
unidad y dejando en `TfrmMtoGen` una referencia. Después de B1 y B2 su
fan-out habrá bajado bastante, lo que hace esto más llevadero.

Estado a 28/07/2026: **D2 terminado; 6 de 6 colaboradores**. Los
filtros guardados, perfiles de pantalla, guías, tareas y artículos viven
en sus cinco gestores. El diagnóstico de metadata vive en `inLibDiag`.
`TfrmMtoGen` baja de 3.346 a 2.156 líneas y la batería DUnitX pasa
109/109. Detalles en los resultados 6V, 6W, 6X, 6Y, 6Z y 6AA. El
siguiente bloque es D3: partir `inLibtb` manteniendo una fachada
compatible.

## D3 — partir `inLibtb` (1.524 líneas, **44 unidades dependientes**)

Nueve dominios mezclados y duplica `inLibIBAN`. Al tener 44 dependientes
es la unidad más arriesgada de tocar del proyecto: la partición debe
hacerse **manteniendo `inLibtb` como fachada** que reexporta, para que
ningún `uses` se rompa, y solo después ir migrando los `uses` de los
dependientes por tandas.

Estado a 29/07/2026: **D3 terminado; 9 de 9 fascículos**.

- D3.1 extrae a `inLibDatasets` las claves, la metadata, el estado de
  datasets y la validación de periodos.
- D3.2 extrae a `inLibValoresAutomaticos` las series, los contadores y
  los valores configurados por defecto.
- D3.3 extrae a `inLibCadenas` las coincidencias, los símbolos por
  perfil y las utilidades ANSI.
- D3.4 lleva la configuración y conexión heredadas a
  `inLibConexionesUniDAC`.
- D3.5 extrae a `inLibCifrado` el AES/Base64 compatible con las
  credenciales y las copias ya persistidas.
- D3.6 elimina cuatro prototipos de búsqueda y filtro sin consumidores,
  y reduce `inLibGenBusq` a sus cinco dependencias reales.
- D3.7 centraliza configuración y licencia en
  `inLibConfiguracionIni`, y poda los helpers y rutas sin consumidores.
- D3.8 consolida NIF, NIE y CIF en `inLibDocumentoFiscal`, y CCC e
  IBAN en `inLibIBAN`; elimina las API y la unidad duplicada sin uso.
- D3.9 mueve el cálculo de líneas a `inLibFacturas`, migra sus dos
  consumidores reales y elimina definitivamente la fachada.

`inLibtb` baja acumuladamente de 1.523 a 0 líneas
(-1.523; -100 %) y desaparece del proyecto. Sus dependencias directas
de producción bajan de 50 a 0. La batería DUnitX pasa 161/161 en
Debug y Release, tanto en
Win32 como en Win64. Resultados en `refactorizacion_fase6ab_resultados.md`,
`refactorizacion_fase6ac_resultados.md`,
`refactorizacion_fase6ad_resultados.md` y
`refactorizacion_fase6ae_resultados.md` y
`refactorizacion_fase6af_resultados.md` y
`refactorizacion_fase6ag_resultados.md` y
`refactorizacion_fase6ah_resultados.md` y
`refactorizacion_fase6ai_resultados.md` y
`refactorizacion_fase6aj_resultados.md`.

D3 queda cerrado. El siguiente bloque es **D4**, trocear los métodos
largos.

## D4 — trocear los métodos largos (48 por encima de 200 líneas)

Estado a 29/07/2026: **D4.12 terminado; 13 de los 48 objetivos de partida
tratados**. D4.1 reduce `MaterializarSesion` de 370 a 52 líneas y
`RevertirMaterializacion` de 424 a 58. D4.2 reduce
`CrearAlbaranDesdePedidoConCantidades` de 348 a 47 líneas. D4.3 reduce
`ExportarBalanceTallasExcel` de 436 a 5 líneas. D4.4 reduce
`ExportarBalanceSinTallasExcel` de 405 a 5 y unifica ambos exportadores
en `inLibBalanceExcelComun`. D4.5 reduce
`ExportarFacturaADevExpress` de 388 a 15 líneas; el mayor colaborador
extraído ocupa 60. D4.6 reduce `TTiraCajaTicket.ExportarExcel` de 438 a
22 líneas; su mayor colaborador ocupa 40. D4.7 reduce
`TArqueoPersistencia.GrabarArqueo` de 371 a 21 líneas; su mayor
colaborador ocupa 53. D4.8 reduce `ImprimirResguardoDeposito` de 339 a
23 líneas; su mayor colaborador ocupa 45. D4.9 reduce
`TdmConsultaOpe.DataModuleCreate` de 333 a 8 líneas; su mayor colaborador
ocupa 86. D4.10 reduce `TModoEntradaTallas.Desmontar` de 332 a 14
líneas; su mayor colaborador ocupa 58. D4.11 reduce
`TPrestaConn.CargarPedido` de 312 a 11 líneas; su mayor colaborador
ocupa 37. D4.12 reduce
`TfrmMtoDevolucionesCompra.AplicarArticuloDevolucion` de 310 a 12
líneas; su mayor colaborador ocupa 29. Los colaboradores extraídos
tienen consumidor y quedan por debajo de 116 líneas. La batería DUnitX
compila en las cuatro configuraciones y pasa 227/228 casos en todas.
La única roja es concurrente y ajena a D4.12:
`Carga_ExponeValoresYAplicaCaption` aún espera que los perfiles cambien
el título, mientras el cambio concurrente en `inLibGestorPerfilesMto`
acaba de desactivar esa responsabilidad. Detalles en
`refactorizacion_fase6ak_resultados.md` y
`refactorizacion_fase6al_resultados.md` y
`refactorizacion_fase6am_resultados.md` y
`refactorizacion_fase6an_resultados.md` y
`refactorizacion_fase6ao_resultados.md` y
`refactorizacion_fase6ap_resultados.md` y
`refactorizacion_fase6aq_resultados.md` y
`refactorizacion_fase6ar_resultados.md` y
`refactorizacion_fase6as_resultados.md` y
`refactorizacion_fase6at_resultados.md` y
`refactorizacion_fase6au_resultados.md` y
`refactorizacion_fase6av_resultados.md`.

Los peores al iniciar D4:

| Líneas | Unidad | Método |
|---|---|---|
| 436 | `inLibBalanceTallasExcel` | `ExportarBalanceTallasExcel` |
| 421 | `inLibComprasSesionesMaterializar` | `RevertirMaterializacion` |
| 405 | `inLibBalanceSinTallasExcel` | `ExportarBalanceSinTallasExcel` |
| 388 | `inLibFacturaExcel` | `ExportarFacturaADevExpress` |
| 378 | `inMtoDevolucionesCompra` | `DevolverTodoStock` |
| 373 | `inLibComprasSesionesMaterializar` | `MaterializarSesion` |
| 351 | `inLibPedidosCompra` | `CrearAlbaranDesdePedidoConCantidades` |

Las doce primeras tandas han troceado
`MaterializarSesion`/`RevertirMaterializacion` y
`CrearAlbaranDesdePedidoConCantidades` y
los dos exportadores de balance Excel, el exportador Excel de factura y
el exportador Excel de la tira de caja, la grabación del arqueo y el
resguardo de depósitos, la configuración de consulta de operaciones,
el des-pivote del modo de entrada por tallas y la carga de pedidos
PrestaShop, además de la aplicación de artículos y SKU en devoluciones
de compra.
El siguiente objetivo por tamaño actual es
`ImprimirTicketDesdeBD`, con 309 líneas.

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
