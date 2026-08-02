# TAREAS IA SOLID — ejecución sin unidades concurrentes

Catálogo listo para repartir el plan `PLAN_SOLID.md` entre sesiones de IA.
Las tareas están organizadas por olas. **Solo las tareas de una misma ola se
pueden ejecutar en paralelo.** Dentro de cada ola no se repite ninguna unidad
Pascal. Las tareas seriales actúan como barrera y nunca se ejecutan mientras
otra sesión esté editando el repositorio.

Estado de partida: 02/08/2026.

---

## 1. Cómo usar este catálogo

Para abrir una tarea, entregar a la IA:

1. el “Contrato común” de la sección 2;
2. el bloque completo de la tarea elegida;
3. la indicación de que lea `AGENTS.md`, `PLAN_SOLID.md`,
   `LIBRO_DE_ESTILO_DELPHI.md` y, si toca SQL,
   `LIBRO_DE_ESTILO_BBDD.md`.

No se inicia una ola hasta que la anterior está integrada y vuelve a estar
verde. Si una tarea descubre que necesita editar una unidad de otra tarea, se
detiene y lo informa; no amplía su alcance por su cuenta.

Cada `.pas` VCL asignado incluye automáticamente su `.dfm` homónimo. Una
unidad nueva pertenece a la tarea que la crea y debe tener un nombre específico
del feature; queda prohibido crear catálogos, `Utils`, `Common` o repositorios
genéricos para eludir la propiedad.

---

## 2. Contrato común para todas las IA

```text
Trabaja en el repositorio Factuzam y responde en español.

Antes de editar:
- Lee AGENTS.md y los libros de estilo aplicables completos.
- Conserva todos los cambios locales ajenos; el árbol puede estar sucio.
- Revisa PLAN_SOLID.md y esta tarea.

Límites:
- Edita únicamente las unidades asignadas y las unidades nuevas reservadas
  por esta tarea.
- Una unit VCL incluye su DFM homónimo.
- No edites fzam.dpr, fzam.dproj, tests/FactuzamTests.dpr,
  tests/FactuzamTests.dproj, .github/workflows/calidad.yml, scripts/,
  baselines ni documentos de planificación. Los integra IA-99.
- Nunca modifiques factuzam_original.sql.
- No introduzcas dependencias nuevas, no sustituyas UniDAC y no hagas commit.
- Si necesitas tocar una unidad no asignada, detente y entrega el motivo,
  la ruta y el cambio mínimo necesario.

Método:
1. Mide el estado inicial de tus unidades.
2. Añade o adapta pruebas de caracterización antes del refactor.
3. Extrae por comportamiento, no por tamaño ni por nombre de evento.
4. Las dependencias quedan visibles y mínimas; ningún colaborador conserva
   un formulario completo ni busca servicios globales.
5. Todo código nuevo cumple P5. No mezcles normalización masiva con lógica.
6. Ejecuta los comprobadores relevantes, compila Win32/Win64 y ejecuta DUnitX.

Entrega:
- Resultado funcional.
- Unidades editadas y creadas.
- Métricas antes/después.
- Pruebas ejecutadas y resultado.
- Riesgos pendientes o archivos compartidos que IA-99 debe integrar.
```

---

## 3. Calendario de olas

| Ola | Ejecución | Tareas | Barrera de salida |
|-----|-----------|--------|-------------------|
| 0 | Serial | `IA-00` | Calidad, Win32, Win64 y DUnitX verdes |
| 1 | Paralela | `IA-11` a `IA-16` | Seis features con núcleo comprobable |
| 2 | Paralela | `IA-21` a `IA-24` | Consumidores preparados para inyección estrecha |
| 3 | Serial | `IA-31` | Localizador general retirado y composición dividida |
| 4 | Paralela | `IA-41` a `IA-43` | Trinquete de persistencia UI a cero |
| 5 | Paralela | `IA-51` a `IA-56` | SQL en `inLib*` a cero |
| 6 | Paralela | `IA-61` a `IA-63` | Métodos >200 y data modules prioritarios divididos |
| 7 | Serial | `IA-98`, después `IA-99` | P5 mecánico y verificación final |

No deben lanzarse tareas de olas distintas a la vez, aunque sus listas
parezcan disjuntas: las tareas seriales cambian contratos de integración.

---

## 4. Ola 0 — línea base

### IA-00 — P0: normalizar codificación sin cambiar lógica

**Objetivo**

Dejar verde `comprobar_codificacion.ps1` corrigiendo solo las infracciones
nuevas que informe en el momento de ejecutar la tarea.

**Propiedad temporal**

- Todos y solo los archivos listados por el bloque “infracciones nuevas” del
  comprobador.
- Esta tarea es serial y termina antes de cualquier otra; por ello puede
  normalizar unidades que pertenecerán a olas posteriores.

**Instrucciones específicas**

- UTF-8 con BOM para Pascal/DFM y CRLF en los tipos exigidos por el libro.
- No cambiar espacios, nombres, comentarios ni lógica salvo lo imprescindible
  para conservar exactamente el texto.
- No añadir excepciones al baseline.
- Comparar el contenido lógico antes/después ignorando BOM y finales de línea.

**Aceptación**

- 0 infracciones nuevas de codificación.
- Calidad completa verde.
- 604/604 pruebas Win32 y 604/604 Win64.

---

## 5. Ola 1 — features críticos

### IA-11 — P1: Facturas sin controlador acoplado al formulario

**Objetivo**

Retirar el falso desacoplamiento de `TControladorFacturas`, convertir sus
responsabilidades en presentadores/casos de uso probables sin VCL y dejar el
formulario como adaptador de vista. El trabajo incluye eliminar su SQL UI
residual.

**Unidades exclusivas**

- `src\Forms\inMtoFacturasBase.pas`
- `src\Forms\inMtoFacturasConsolidacionVcl.pas`
- `src\Forms\inMtoFacturasCobrosVcl.pas`
- `tests\PruebasFacturasCobrosPresentacion.pas`
- `tests\PruebasFacturasConsolidacionPresentacion.pas`
- `tests\PruebasFacturasEstadoFiscalPresentacion.pas`
- `tests\PruebasFacturasOperacionFiscal.pas`

Se reservan nombres nuevos que empiecen por `inLibFacturasPresentador` o
`inMtoFacturasPresentador` y sus pruebas homónimas.

**Aceptación**

- No existe un colaborador con campo `TfrmMtoFacturasBase`.
- El formulario mantiene menos de 75 métodos y no crece en líneas.
- 0 `TUniQuery.Create` y 0 asignaciones SQL propias en estas unidades VCL.
- Estado fiscal, consolidación, cobros, SKU y errores conservan sus pruebas.

### IA-12 — P1: operación de Caja como caso de uso

**Objetivo**

Extraer del formulario el procesamiento de teclado/escáner, cálculo y cierre
de venta. El handler de riesgo 335 debe delegar en un objeto sin VCL. La
transacción queda en una unidad de trabajo y la UI no crea consultas ni SQL.

**Unidades exclusivas**

- `src\Caja\Forms\inMtoCajaOpe.pas`
- `src\Caja\Forms\inMtoCajaEntradaVcl.pas`
- `src\Caja\Lib\inLibCajaVentaIntf.pas`
- `src\Caja\Lib\inLibCajaVentaOperacion.pas`
- `src\Caja\Lib\inLibCajaOpeComposicion.pas`
- `tests\PruebasCajaEntrada.pas`
- `tests\PruebasCajaVentaOperacion.pas`

Se reservan unidades `inLibCajaOpePresentacion*` y
`inMtoCajaOpePresentacion*`.

**Aceptación**

- `TfrmMtoOpeCaja` baja de 2.000 líneas.
- El handler de teclado queda en hasta 15 líneas efectivas y 0 salidas.
- Las decisiones fiscales/de caja del nuevo núcleo no superan 10 por método.
- El núcleo se prueba sin formulario ni conexión real.

### IA-13 — P1: Compras Sesiones como orquestación explícita

**Objetivo**

Separar del formulario búsqueda incremental, edición de tallas, copia de
líneas y coordinación de materialización. Aprovechar el caso de uso existente
sin volver a introducir SQL ni UniDAC en `inLib*`.

**Unidades exclusivas**

- `src\Forms\inMtoComprasSesiones.pas`
- `src\Lib\inLibComprasSesionesAplicacionIntf.pas`
- `src\Lib\inLibComprasSesionesAplicacion.pas`
- `tests\PruebasComprasSesionesAplicacion.pas`
- `tests\PruebasGestorCopiaLineasCompra.pas`

Se reservan unidades `inLibComprasSesionesPresentacion*` y
`inMtoComprasSesionesPresentacion*`.

**Aceptación**

- El formulario baja de 2.000 líneas.
- Timers, búsqueda incremental y materialización son colaboradores separados.
- La aplicación no conoce controles VCL, `TUniQuery` ni nombres de componentes.
- Se conservan creación, reutilización, error y cancelación mediante pruebas.

### IA-14 — P1: Artículos con guardado y edición independientes

**Objetivo**

Separar propiedades, variaciones, atributos básicos, stock y guardado. El
formulario solo adapta controles y presenta resultados. Extraer también sus
consultas y la transacción que todavía viven en UI.

**Unidades exclusivas**

- `src\Forms\inMtoArticulos.pas`
- `src\Forms\inMtoArticulosGuardadoVcl.pas`
- `src\Lib\inLibArticulosGuardadoIntf.pas`
- `src\Lib\inLibArticulosGuardado.pas`
- `tests\PruebasArticulosGuardado.pas`
- `tests\PruebasArticulosAtributosBasicos.pas`
- `tests\PruebasArticulosVisibilidad.pas`

Se reservan unidades `inLibArticulosPresentacion*` y
`inMtoArticulosPresentacion*`.

**Aceptación**

- `TfrmMtoArticulos` baja de 2.000 líneas.
- 0 consultas, SQL y transacciones creadas por la UI asignada.
- Guardado, variaciones y atributos se prueban sin VCL ni BBDD.
- Ningún nuevo servicio recibe el formulario o un contexto general.

### IA-15 — P1: Inventarios con entrada y presentación separadas

**Objetivo**

Extraer resolución de SKU, columnas dinámicas, importación y aplicación de
líneas. El formulario coordina la vista y no ejecuta SQL.

**Unidades exclusivas**

- `src\Forms\inMtoInventarios.pas`
- `src\Lib\inLibInventariosAplicacionIntf.pas`
- `src\Lib\inLibInventariosAplicacion.pas`
- `tests\PruebasInventariosAplicacion.pas`
- `tests\PruebasInventariosEntrada.pas`

Se reservan unidades `inLibInventariosPresentacion*` y
`inMtoInventariosPresentacion*`.

**Aceptación**

- `TfrmMtoInventarios` baja de 2.000 líneas.
- 0 SQL/consultas en la UI asignada.
- Se reduce de forma material su deuda actual de 102 `Exit`.
- Modos Auto/SKU/Tallas, lector e importación quedan caracterizados.

### IA-16 — P1: Stock Consulta con estado de vista explícito

**Objetivo**

Separar lector, historial, fotos, tarjetas, pivote y carga de artículo en
presentadores cohesivos. El formulario no descubre repositorios durante un
evento.

**Unidades exclusivas**

- `src\Forms\inMtoStockConsulta.pas`
- `src\Forms\inMtoStockConsultaEntradaVcl.pas`
- `src\Lib\inLibStockConsultaEntradaIntf.pas`
- `src\Lib\inLibStockConsultaEntrada.pas`
- `tests\PruebasStockConsultaEntrada.pas`
- `tests\PruebasStockConsultaInfo.pas`

Se reservan unidades `inLibStockConsultaPresentacion*` y
`inMtoStockConsultaPresentacion*`.

**Aceptación**

- `TfrmStockConsulta` baja de 2.000 líneas y de 30 campos propios.
- No contiene acceso directo a repositorios generales ni SQL.
- Lector, historial y dimensiones de fotos se prueban como estados puros.

---

## 6. Ola 2 — consumidores del contexto general

El objetivo común de esta ola es concentrar la resolución actual en una única
rutina de composición por feature, inyectar campos estrechos y dejar toda la
lógica operativa libre de `ContextoRepositoriosPantalla`. La retirada final
del punto de compatibilidad corresponde a `IA-31`.

### IA-21 — P1/P2: ventas y documentos de salida

**Unidades exclusivas**

- `src\Forms\inMtoAlbaranes.pas`
- `src\Forms\inMtoPedidos.pas`
- `src\Forms\inMtoClientes.pas`
- `src\Forms\inMtoFacturasSimplif.pas`
- `src\Modals\inMtoModalEnviarDestino.pas`
- `src\Modals\inMtoModalFacturarAlbaranesFechas.pas`
- `src\Modals\inMtoModalFacturarAlbaranes.pas`
- `src\Modals\inMtoModalFacturarTicket.pas`
- `src\Modals\inMtoModalSerieFechaFactura.pas`
- `src\Modals\inMtoModalSelFamilia.pas`
- `src\Modals\inMtoModalSelAlmacenPedido.pas`
- `src\Modals\inMtoModalSelAlmacenAlbaran.pas`
- `src\Modals\inMtoModalListadoVentas.pas`
- `src\Modals\inMtoModalGenImp.pas`

Se reservan unidades nuevas con prefijo de feature
`inLibVentasPantalla*`/`UniDataVentasPantalla*` y una prueba
`PruebasComposicionVentasPantalla.pas`.

**Aceptación**

- Dependencias de artículos, documentos y ventas quedan en contextos mínimos.
- 0 SQL directo en las unidades asignadas.
- `btnCrearAlbaranClick` queda dividido y probado fuera de la VCL.
- La impresión no recibe una bolsa general de repositorios.

### IA-22 — P1/P2: documentos de compra

**Unidades exclusivas**

- `src\Forms\inMtoAlbaranesCompra.pas`
- `src\Forms\inMtoFacturasCompra.pas`
- `src\Forms\inMtoPedidosCompra.pas`
- `src\Forms\inMtoDevolucionesCompra.pas`
- `src\Forms\inMtoDocumentosTrabajo.pas`
- `src\Forms\inMtoComprasPlantillas.pas`

Se reservan `inLibComprasPantalla*`, `UniDataComprasPantalla*` y
`PruebasComposicionComprasPantalla.pas`.

**Aceptación**

- Cada formulario recibe solo validación, resolución y persistencia que usa.
- 0 SQL directo y 0 componentes UniDAC en sus DFM.
- `TfrmMtoPedidosCompra` inicia una reducción neta y ningún colaborador nuevo
  recibe el formulario completo.
- Devolución y creación/incorporación de albaranes conservan pruebas de error y
  rollback.

### IA-23 — P1/P2: Caja, históricos y arqueos

**Unidades exclusivas**

- `src\Forms\inMtoConsultaOpe.pas`
- `src\Caja\Forms\inMtoTraspasoOpe.pas`
- `src\Caja\Forms\inMtoCajaFaseCobro.pas`
- `src\Caja\Forms\inMtoCajaMenu.pas`
- `src\Caja\Forms\inMtoCajaOperacionesHist.pas`
- `src\Caja\Forms\inMtoCajaPagosHist.pas`
- `src\Caja\Forms\inMtoCajaParam.pas`
- `src\Caja\Forms\inMtoCajaSeleccionVale.pas`
- `src\Caja\Forms\inMtoCajaArqueosHist.pas`
- `src\Caja\Forms\inMtoCajaFormasPago.pas`
- `src\Caja\Forms\inMtoCajaImpresorVenta.pas`
- `src\Caja\Forms\inMtoCajaValesHist.pas`
- `src\Caja\Modals\inMtoModalGastoCaja.pas`
- `src\Caja\Modals\inMtoModalImpPagos.pas`
- `src\Caja\Modals\inMtoModalImpDepositos.pas`
- `src\Caja\Modals\inMtoModalImpArqueos.pas`
- `src\Caja\Modals\inMtoModalImpOperacionesVenta.pas`
- `src\Caja\Modals\inMtoModalArqueosHistCaja.pas`
- `src\Caja\Modals\inMtoModalImpOperaciones.pas`
- `src\Caja\Modals\inMtoModalArqueo.pas`
- `src\Modals\inMtoModalEntradaCambio.pas`
- `src\Modals\inMtoModalCajDef.pas`
- `src\Modals\inMtoModalOperacionesCajaSku.pas`

Se reservan `inLibCajaPantalla*`, `UniDataCajaPantalla*` y
`PruebasComposicionCajaPantalla.pas`.

**Aceptación**

- Consultas, tickets, arqueos e informes se inyectan por capacidades separadas.
- Las transacciones de históricos salen de los formularios.
- `CrearFichaDetalle` se divide en modelo, carga y renderizado.
- Operaciones de caja conservan éxito, cancelación, error y rollback.

### IA-24 — P1/P2: configuración y auxiliares de artículos

**Unidades exclusivas**

- `src\Core\inMtoAppParam.pas`
- `src\Forms\inMtoBusquedaDatos.pas`
- `src\Forms\inMtoEmpresas.pas`
- `src\Modals\inMtoModalAddBlockBase.pas`
- `src\Modals\inMtoModalCalcularMargen.pas`
- `src\Modals\inMtoModalCargarEfectosRemesa.pas`
- `src\Modals\inMtoModalDistribuidor.pas`
- `src\Modals\inMtoModalFiltroArt.pas`
- `src\Modals\inMtoModalGenerarSKUs.pas`
- `src\Modals\inMtoModalGestionFiltros.pas`
- `src\Modals\inMtoModalGuiasBase.pas`
- `src\Modals\inMtoModalSeleccionarBanco.pas`

Se reservan `inLibConfiguracionPantalla*`,
`UniDataConfiguracionPantalla*` y
`PruebasComposicionConfiguracionPantalla.pas`.

**Aceptación**

- Cada modal recibe uno o dos contratos con intención, no un contexto general.
- Series, bancos, filtros, guías, margen y SKU conservan casos límite.
- 0 SQL y 0 creación de consultas en las unidades asignadas.

---

## 7. Ola 3 — raíz de composición

### IA-31 — P1: retirar el localizador de servicios de pantalla

Esta tarea es **serial** y se ejecuta cuando IA-11…IA-24 están integradas.
Puede hacer el cableado mínimo en las rutinas de composición creadas por esas
tareas, pero no rediseñar de nuevo sus features.

**Objetivo**

Eliminar el acceso general desde `TfrmBase`, dividir los mega-adaptadores por
capacidad y dejar `TfrmMtoPrincipal`/`UniDataComposicionAplicacion` como única
raíz que conoce las implementaciones.

**Unidades principales**

- `src\Core\inMtoFrmBase.pas`
- `src\Core\inMtoPrincipal.pas`
- `src\Lib\inLibRepositoriosPantallaIntf.pas`
- `src\DataModules\UniDataRepositoriosPantalla.pas`
- `src\DataModules\UniDataRepositoriosGeneralesPantalla.pas`
- `src\DataModules\UniDataRepositoriosCajaPantalla.pas`
- `src\DataModules\UniDataComposicionAplicacion.pas`
- `tests\PruebasRegistroPantallas.pas`

Se reservan adaptadores nuevos `UniDataRepositorios<Feature>Pantalla.pas` y
pruebas `PruebasRepositoriosPantallaComposicion.pas`.

**Aceptación**

- 0 accesos a `ContextoRepositoriosPantalla.` en `src/`.
- `TfrmBase` no expone el contexto ni una fábrica equivalente.
- Ninguna nueva interfaz/fábrica supera 10 miembros.
- Ninguna unidad de composición supera fan-out 40.
- `UniDataRepositoriosGeneralesPantalla` deja de implementar seis familias.
- No aparece un diccionario por nombre de formulario ni un service locator
  renombrado.

---

## 8. Ola 4 — persistencia UI residual

### IA-41 — P2: bases genéricas, búsqueda y logon

**Unidades exclusivas**

- `src\Forms\inMtoGen.pas`
- `src\Forms\inMtoGenSearch.pas`
- `src\Core\inMtoLogon.pas`
- `src\DataModules\UniDataGen.pas`

Se reservan `inLibMtoGenAplicacion*`, `inLibLogonAplicacion*`,
`UniDataLogonRepositorio*` y sus pruebas.

**Aceptación**

- 0 SQL, consultas y transacciones en las tres unidades VCL.
- 0 componentes UniDAC en `inMtoGenSearch.dfm` e `inMtoLogon.dfm`.
- `TfrmMtoGen` reduce métodos y deja documentado/probado el contrato de sus
  hooks para descendientes.
- Autenticación distingue credenciales inválidas, indisponibilidad y error.

### IA-42 — P2: generador de procesos y movimientos de almacén

**Unidades exclusivas**

- `src\Forms\inMtoGeneradorProcesos.pas`
- `src\Forms\inMtoMovimientosAlmacen.pas`

Se reservan `inLibGeneradorProcesosAplicacion*`,
`UniDataGeneradorProcesosRepositorio*`,
`inLibMovimientosAlmacenAplicacion*` y
`UniDataMovimientosAlmacenRepositorio*`.

**Aceptación**

- 0 de las 5 consultas y 15 asignaciones SQL actuales en estas pantallas.
- Generación, cancelación y movimientos parciales se prueban sin VCL.
- La escritura de almacén usa una unidad de trabajo explícita.

### IA-43 — P2: modales de informes e importación

**Unidades exclusivas**

- `src\Modals\inMtoModalImpEfectosPago.pas`
- `src\Modals\inMtoModalImpFac.pas`
- `src\Modals\inMtoModalImpMultiFiltro.pas`
- `src\Modals\inMtoModalImpRecFac.pas`
- `src\Modals\inMtoModalVerifactuDecl.pas`
- `src\Modals\inMtoModalWizardEditar.pas`
- `src\Modals\inMtoModalImpBalanceSinTallas.pas`
- `src\Modals\inMtoModalImpBalanceTallas.pas`
- `src\Modals\inMtoModalImpDocsProveedor.pas`
- `src\Modals\inMtoModalImpMovVentasArt.pas`
- `src\Modals\inMtoModalEtiqArt.pas`

Se reservan contratos y adaptadores con el nombre completo del informe, no
una fábrica genérica de SQL.

**Aceptación**

- 0 consultas y 0 `SQL.Text` en los modales asignados.
- 0 componentes UniDAC en sus DFM.
- Cada informe recibe un dataset/DTO ya preparado o un contrato de lectura.
- El trinquete global de UI queda en 0 para todas sus categorías.

---

## 9. Ola 5 — SQL restante en dominio

Objetivo común: mover SQL a adaptadores `UniData*`, mantener
`inLib* -> UniData* = 0` y probar los contratos con dobles. Cada tarea debe
reducir a cero el SQL de todas sus unidades asignadas.

### IA-51 — P1/P3: copia y restauración segura

**Unidades exclusivas**

- `src\Lib\inLibBackupWorker.pas`
- `src\Lib\backup\Backup.Types.pas`
- `src\Lib\backup\Backup.Engine.pas`
- `tests\PruebasCopiasSeguridad.pas`
- `tests\PruebasRestauracionCopiasConexion.pas`

Se reservan `inLibBackupPersistenciaIntf.pas`,
`UniDataBackupRepositorio.pas` y pruebas homónimas.

**Aceptación**

- 0 SQL/DDL en `inLibBackupWorker`.
- `EjecutarSQLStreaming` queda por debajo de 120 líneas y riesgo 200.
- Se prueban delimitadores, comentarios, sentencias parciales, cancelación y
  error de conexión.
- No se promete rollback de DDL cuando MariaDB no lo ofrece.

### IA-52 — P3: artículos, grids y búsquedas de compra

**Unidades exclusivas**

- `src\Lib\inLibArticulosCodigosBarras.pas`
- `src\Lib\inLibGridTallasInline.pas`
- `src\Lib\inLibGridArticulos.pas`
- `src\Lib\inLibArticulosFiltro.pas`
- `src\Lib\inLibBusquedasCompra.pas`
- `src\Lib\inLibComprasSesionesReglas.pas`
- `tests\PruebasBusquedasCompra.pas`
- `tests\PruebasValidacionTallasCompra.pas`

Se reservan contratos/adaptadores que conserven el nombre de cada capacidad,
por ejemplo `inLibGridTallasInlinePersistenciaIntf` y su `UniData*Repositorio`.

**Aceptación**

- 0 SQL en las seis unidades `inLib*`.
- `TGridArticulosLineas` baja de 1.200 líneas y 30 métodos.
- Las búsquedas no devuelven `TUniQuery` salvo enlace de presentación
  expresamente justificado.

### IA-53 — P3: configuración e infraestructura de datos

**Unidades exclusivas**

- `src\Lib\inLibValoresAutomaticos.pas`
- `src\Lib\inLibDBStructure.pas`
- `src\Lib\inLibData.pas`
- `src\Lib\inLibUnidadesMedida.pas`
- `src\Lib\inLibDatasets.pas`
- `src\Lib\inLibPermisosUniDAC.pas`
- `src\Lib\inLibConfigCampos.pas`
- `src\Lib\inLibLicenciaAplicacion.pas`
- `tests\PruebasValoresAutomaticos.pas`
- `tests\PruebasDatasets.pas`

Se reservan contratos/adaptadores con el nombre de cada servicio; queda
prohibido un `IRepositorioGeneral`.

**Aceptación**

- 0 SQL en las ocho unidades de librería.
- Esquema, licencia, permisos y valores automáticos expresan errores con tipos
  o resultados, no con texto interpretado.
- Las comprobaciones de estructura se separan de su presentación.

### IA-54 — P3/P4: traducción, perfiles, guías y utilidades de pantalla

**Unidades exclusivas**

- `src\Lib\inLibTraduccionesDescarga.pas`
- `src\Lib\inLibTraducciones.pas`
- `src\Lib\inLibGridColumnChooser.pas`
- `src\Lib\inLibGestorGuiasGridMto.pas`
- `src\Lib\inLibGestorPerfilesMto.pas`
- `src\Lib\inLibUnitForm.pas`
- `src\Lib\inLibShowMto.pas`
- `tests\PruebasTraducciones.pas`
- `tests\PruebasGestorGuiasGridMto.pas`
- `tests\PruebasGestorPerfilesMto.pas`

Se reservan adaptadores `UniDataTraducciones*`, `UniDataGuias*` y
`UniDataPerfiles*` específicos.

**Aceptación**

- 0 SQL en las siete unidades.
- `EnriquecerQueryConGuias` y `ShowMto` quedan por debajo de 120 líneas.
- Navegación, perfiles y presentación no conocen la conexión.

### IA-55 — P3: documentos, impuestos y correo

**Unidades exclusivas**

- `src\Lib\inLibSepaRemesasVenta.pas`
- `src\Lib\inLibImpuestosComun.pas`
- `src\Lib\inLibComprasImpuestos.pas`
- `src\Lib\inLibVentasImpuestos.pas`
- `src\Lib\inLibValidacionDocumento.pas`
- `src\Lib\inLibFormatoDocumento.pas`
- `src\Lib\inLibCorreoTickets.pas`
- `src\Lib\inLibColumnasDocumento.pas`
- `tests\PruebasImpuestosComun.pas`
- `tests\PruebasColumnasDocumento.pas`

Se reservan contratos/adaptadores con prefijos `Sepa`, `Impuestos`,
`ValidacionDocumento`, `CorreoTickets` y `ColumnasDocumento`.

**Aceptación**

- 0 SQL en las ocho unidades.
- Cálculo de impuestos queda puro y separado de lecturas de tipos/zonas.
- SEPA, formato y correo reciben datos ya validados.

### IA-56 — P3: inventario y utilidades de Caja

**Unidades exclusivas**

- `src\Caja\Lib\inLibCajaStock.pas`
- `src\Lib\inLibInventarioNube.pas`
- `src\Caja\Lib\inLibGenerarTicketCaja.pas`

Se reservan `inLibCajaStockPersistenciaIntf`,
`UniDataCajaStockRepositorio`, `inLibInventarioNubePersistenciaIntf`,
`UniDataInventarioNubeRepositorio` y contratos homólogos de ticket.

**Aceptación**

- 0 SQL en las tres unidades.
- Política de stock, sincronización y generación de ticket se prueban sin
  UniDAC.
- Reintento de inventario nube y actualización de stock son idempotentes.

---

## 10. Ola 6 — complejidad residual

### IA-61 — P4: exportadores y presentación tabular

**Unidades exclusivas**

- `src\Lib\inLibMovVentasArtExcel.pas`
- `src\Lib\inLibDocumentosTrabajoExcel.pas`
- `src\Lib\inLibDocCompraExcel.pas`
- `src\Lib\inLibDevExp.pas`

Se reservan modelos/presentadores `inLibExportacion*` y
`PruebasExportadores.pas`.

**Aceptación**

- Los cuatro métodos señalados por riesgo quedan por debajo de 120 líneas.
- Cálculo de columnas/celdas es puro; DevExpress solo renderiza.
- Se prueban 0, 1 y muchas filas, nulos, tallas y formatos numéricos.

### IA-62 — P4: fiscalidad, factura y cálculo de cobro

**Unidades exclusivas**

- `src\Lib\inLibGenerarTicketBD.pas`
- `src\verifactu\inLibVerifactuEnvio.pas`
- `src\Caja\Lib\inLibFaseCobro.pas`
- `src\Caja\DataModules\UniDataCaja.pas`
- `src\DataModules\UniDataFacturas.pas`
- `tests\PruebasEmisionFiscal.pas`
- `tests\PruebasFacturasServicios.pas`

Se reservan colaboradores `inLibTicketDatos*`, `inLibVerifactuCarga*` y
`inLibFaseCobroCalculo*`.

**Aceptación**

- `ImprimirTicketDesdeBD`, `CargarDatosFactura`, `CalcularTotales` y
  `TransformarLineasParaCobroParcial` quedan por debajo de 120 líneas.
- Ningún método fiscal/caja modificado supera 10 decisiones.
- `TdmFacturas` y `TdmCajaOpe` dejan separados lectura, escritura y cálculo.
- Se prueban redondeo, pago parcial, rechazo fiscal, reintento y rollback.

### IA-63 — P4: data modules de artículos, pedidos y efectos

**Unidades exclusivas**

- `src\DataModules\UniDataArticulos.pas`
- `src\DataModules\UniDataPedidos.pas`
- `src\DataModules\UniDataEfectosCompra.pas`
- `src\DataModules\UniDataEfectosVenta.pas`
- `src\DataModules\UniDataTarifasCambios.pas`
- `src\DataModules\UniDataPedidosCompraIncorporacionAlbaran.pas`
- `src\DataModules\UniDataAlbaranes.pas`
- `src\DataModules\UniDataInventarios.pas`
- `src\DataModules\UniDataArticulosVariaciones.pas`
- `src\DataModules\UniDataFotosRepositorio.pas`
- `tests\PruebasFusionEfectos.pas`
- `tests\PruebasImportacionPedidos.pas`
- `tests\PruebasArticulosVariaciones.pas`

Se reservan colaboradores `UniData<Feature>Lecturas`,
`UniData<Feature>Escrituras` y contratos de resultado específicos.

**Aceptación**

- Los métodos señalados de etiquetas, PrestaShop, efectos, tarifas e
  incorporación quedan por debajo de 120 líneas.
- Ninguna extracción crea una clase con más de 30 métodos.
- Los efectos de compra y venta comparten cálculo puro, no SQL concatenado.
- Cada escritura múltiple declara propietario de transacción y rollback.

---

## 11. Ola 7 — acabado e integración serial

### IA-98 — P5: retirar deuda mecánica restante

Tarea serial posterior a todos los cambios lógicos.

**Objetivo**

Procesar el código propio por lotes pequeños hasta llevar a cero excepciones
de codificación, `Exit`, `Continue`, `with` y líneas anchas, sin alterar
comportamiento.

**Reglas**

- Un lote por dominio; caracterización y compilación entre lotes.
- No hacer sustituciones globales ciegas de control de flujo.
- Un `Exit` solo se retira reestructurando la intención y sin aumentar
  anidación.
- Separar cada lote mecánico de cualquier cambio funcional.

**Aceptación**

- 0 excepciones de codificación.
- 0 `Exit`, 0 `Continue`, 0 `with`, 0 tabuladores y 0 líneas anchas en código
  propio, salvo recurso generado documentado y excluido por regla explícita.
- Calidad, compilación y pruebas verdes tras cada lote y al final.

### IA-99 — integración final, manifiestos y trinquetes

Esta tarea es serial, no modifica lógica de unidades Pascal y se ejecuta la
última.

**Archivos compartidos reservados**

- `fzam.dpr`
- `fzam.dproj`
- `tests\FactuzamTests.dpr`
- `tests\FactuzamTests.dproj`
- `.github\workflows\calidad.yml`
- `scripts\*.ps1`
- baselines de calidad
- `PLAN_SOLID.md`, `TAREAS_IA_SOLID.md` y libros de estilo si una regla ha
  cambiado de forma aprobada

**Objetivo**

Registrar todas las unidades nuevas, eliminar referencias muertas, bajar cada
tope a la cifra alcanzada y verificar la solución completa.

**Aceptación**

- No hay unidades nuevas sin registrar ni unidades retiradas referenciadas.
- Los topes solo bajan; ninguna lista blanca se amplía sin justificación.
- `ContextoRepositoriosPantalla.` = 0.
- SQL en UI = 0 y SQL en `inLib*` = 0.
- Métodos >200 = 0.
- Calidad completa verde.
- `fzam` y DUnitX compilan y las pruebas pasan en Win32 y Win64.
- La CI obligatoria conserva jobs Windows/Delphi no opcionales.

---

## 12. Control de concurrencia

Antes de lanzar una ola:

1. Comprobar que ninguna sesión de la ola anterior sigue activa.
2. Asignar una tarea completa por sesión, nunca media tarea.
3. Publicar las unidades nuevas previstas antes de crearlas.
4. Rechazar cualquier edición fuera de la lista exclusiva.
5. Integrar una tarea cada vez, ejecutar calidad y solo entonces integrar la
   siguiente.

Matriz de conflictos deliberados:

- `IA-00` puede normalizar archivos de cualquier ola: siempre se ejecuta
  antes y en solitario.
- `IA-31` integra los puntos de composición preparados en olas 1 y 2: siempre
  se ejecuta después y en solitario.
- `IA-98` puede recorrer unidades ya refactorizadas: siempre se ejecuta al
  final y en solitario.
- `IA-99` es la única propietaria de manifiestos, scripts, workflow, baselines
  y documentación compartida.

Con estas barreras no existe edición concurrente de una misma unidad, aunque
una tarea serial posterior necesite realizar el cableado final de una unidad
ya integrada.

### Cobertura comprobada del reparto

La asignación se ha contrastado automáticamente contra el árbol actual:

- 0 unidades Pascal repetidas entre tareas de una misma ola;
- 55/55 unidades que consumen `ContextoRepositoriosPantalla` asignadas;
- 27/27 unidades con acceso directo a datos en UI o UniDAC en DFM asignadas;
- 33/33 unidades `inLib*` con SQL asignadas;
- 20/20 focos mostrados por el ranking actual de métodos largos asignados.

Estas cifras son una fotografía del 02/08/2026. Antes de iniciar una ola se
repiten los comprobadores, porque una integración anterior puede haber
retirado o creado focos.
