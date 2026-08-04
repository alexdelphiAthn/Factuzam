# TAREAS IA SOLID — siguiente iteración

Catálogo para continuar mejorando Factuzam mediante varios hilos de IA sobre
el mismo repositorio. Esta versión sustituye por completo al catálogo
anterior: conserva lo resuelto, asigna propiedad exclusiva de archivos y
separa las tareas paralelas mediante barreras de integración.

Estado medido: **04/08/2026**, sobre una instantánea estable del árbol de
trabajo.

---

## 1. Resultado que persigue esta iteración

Al terminar esta hoja de ruta, el código debe haber mejorado de forma
observable en cuatro frentes:

1. Las pantallas reciben sus dependencias; no las buscan recorriendo `Owner`
   ni recurriendo a `Application.MainForm`.
2. Ninguna clase propia supera 2.000 líneas y las extracciones representan
   responsabilidades reales, no trozos del mismo formulario.
3. Los métodos de mayor riesgo quedan divididos por intención y su núcleo se
   puede probar sin VCL ni una conexión real.
4. Los trinquetes que ya están a cero permanecen a cero: estilo, SQL en
   dominio, consultas en UI, dependencias de capa y estado global.

No se busca aumentar el número de interfaces. Se busca que cada consumidor
conozca menos cosas y que las dependencias necesarias aparezcan en una firma,
un constructor o un contexto de feature pequeño.

---

## 2. Línea base real

`scripts/comprobar_calidad.ps1` termina correctamente con 17 comprobadores.
La situación actual que no se debe perder es:

| Indicador | Estado |
|-----------|-------:|
| Codificación y finales de línea fuera de norma | 0 |
| `Exit`, `Continue`, `with`, líneas anchas y tabuladores | 0 |
| Consultas, SQL, UniDAC o transacciones en UI | 0 |
| SQL literal en `inLib*` | 0 |
| Dependencias `inLib* -> UniData*` | 0 |
| Ciclo mayor entre unidades | 1 |
| Variables globales en `interface` y `except` vacíos | 0 |
| Métodos de más de 200 líneas | 0 |
| Métodos de más de 120 líneas | 67 |
| Riesgo acumulado de métodos largos | 13.134 |
| Riesgo individual máximo | 280 |
| Fan-out máximo | 72, en `inMtoFacturasBase` |
| Clases analizadas | 713 |
| Tamaño máximo de clase | 2.684 líneas |

Las mayores clases pendientes son:

| Clase | Líneas | Métodos | Motivo principal de cambio pendiente |
|-------|-------:|--------:|--------------------------------------|
| `TfrmMtoPedidosCompra` | 2.684 | 88 | Pedido, recepción y albarán |
| `TdmFacturas` | 2.529 | 71 | Dataset, validación y fiscalidad |
| `TfrmMtoDevolucionesCompra` | 2.259 | 84 | Edición, stock y devolución |
| `TEditorLineasCajaVcl` | 2.193 | 74 | Entrada, búsqueda, stock y renderizado |
| `TdmAlbaranes` | 2.176 | 43 | Persistencia y movimientos de salida |
| `TfrmMtoPrincipal` | 2.131 | 98 | Shell, arranque y composición |
| `TdmPedidos` | 2.057 | 43 | Persistencia y flujo de pedidos |
| `TfrmMtoGen` | 2.053 | 101 | Base visual con demasiadas capacidades |
| `TdmCajaOpe` | 2.033 | 31 | Persistencia y cierre de venta |

Quedan además dos unidades procedurales por encima de su objetivo de 30
rutinas:

- `UniDataArticulosVariaciones`: 43 rutinas.
- `UniDataFotosRepositorio`: 33 rutinas.

### Hallazgo arquitectónico principal

`inLibRepositoriosPantallaIntf` todavía contiene `BuscarCompositor` y nueve
funciones `ObtenerCompositor*Pantalla`. La resolución recorre la cadena de
propietarios y usa `Application.MainForm` como último recurso. Además, los
contratos de repositorios de pantalla exponen `TUniConnection` o `TDataSet`.

El mecanismo funciona, pero oculta dependencias y obliga a las pantallas a
conservar factorías más amplias que sus necesidades reales. La primera fase
de esta iteración lo reemplaza por composición explícita por feature.

### Trabajo local que se debe respetar

El árbol cambia mientras se prepara este catálogo, por lo que no se conserva
aquí una lista estática de archivos sucios. `IA-00` obtiene el `git status`
vigente y publica el mapa de propiedad para cada ejecución. Ningún archivo
modificado o sin seguimiento entra en una tarea hasta identificar a su
propietario o recibir una transferencia expresa del usuario.

Facturas e incidencias fiscales se consideran bloqueadas si `IA-00` encuentra
cambios locales en cualquiera de sus formularios, modales, data modules o
contratos.

---

## 3. Modelo de trabajo con varios hilos

Todos los hilos comparten el mismo árbol. La concurrencia se controla mediante
propiedad temporal de archivos, no mediante la confianza en resolver luego los
conflictos.

### 3.1 Coordinador e hilos de trabajo

Estados permitidos:

```text
PENDIENTE -> EN_CURSO -> LISTA_PARA_INTEGRAR -> INTEGRANDO -> CERRADA
                                                   \-> REABIERTA
```

Una tarea en `LISTA_PARA_INTEGRAR` ya no edita. La propiedad solo termina
cuando el coordinador la transfiere expresamente al integrador.

Hay un único coordinador por ola. El coordinador:

1. comprueba la barrera de entrada;
2. publica el arrendamiento de rutas de cada tarea;
3. reserva los nombres de unidades nuevas;
4. inicia los hilos de la ola;
5. espera a que todos queden en `LISTA_PARA_INTEGRAR`;
6. verifica que no existan archivos solapados;
7. integra manifiestos y ejecuta la barrera de salida.

Un hilo solo puede editar las rutas de su bloque **Propiedad exclusiva**. Un
`.pas` VCL y su `.dfm` homónimo forman una propiedad indivisible. Una unidad
nueva pertenece al hilo cuyo prefijo esté reservado.

### 3.2 Archivos compartidos reservados al integrador

Ningún hilo paralelo modifica:

- `fzam.dpr` y `fzam.dproj`;
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj` y
  `tests/FactuzamTests.res`;
- `src/Core/inMtoPrincipal.pas` y su DFM;
- `src/Lib/inLibShowMto.pas`;
- `src/Lib/inLibRegistroPantallas.pas`;
- `src/Lib/inLibRepositoriosPantallaIntf.pas`;
- `src/DataModules/UniDataComposicionAplicacion.pas`;
- `src/DataModules/UniDataRepositoriosPantalla.pas`;
- `scripts/`, documentos de planificación y baselines.

`IA-01`, `IA-06` e `IA-99` son barreras seriales y sí pueden recibir la
propiedad explícita de esos archivos.

### 3.3 Contrato que recibe cada hilo

```text
Trabaja en Factuzam y responde en español.

Antes de editar:
- Lee AGENTS.md y LIBRO_DE_ESTILO_DELPHI.md completos.
- Si hay SQL o esquema, lee también LIBRO_DE_ESTILO_BBDD.md completo.
- Lee la barrera de entrada, tu tarea y su Propiedad exclusiva.
- Ejecuta git status --short y no toques ningún cambio ajeno.
- Comprueba que ningún archivo arrendado está asignado a otro hilo.

Durante el trabajo:
- Edita solo las rutas arrendadas y unidades nuevas con tu prefijo reservado.
- Considera el PAS y su DFM una sola unidad de propiedad.
- Caracteriza el comportamiento antes de extraerlo.
- No mezcles refactor, cambio funcional y normalización mecánica.
- No pases un formulario completo a aplicación o dominio.
- Recibe y valida las dependencias obligatorias de forma explícita.
- Todo código nuevo cumple P5.
- No edites manifiestos, raíz, scripts, baselines ni planes compartidos.
- No modifiques factuzam_original.sql, no añadas dependencias y no hagas commit.

Si necesitas una ruta no arrendada:
- Detente antes de editarla.
- Informa de ruta, motivo y cambio mínimo.
- Espera a que el coordinador cambie el reparto o reserve una barrera serial.

Antes de entregar:
- Ejecuta pruebas y comprobadores limitados a tu alcance.
- No ejecutes la compilación global mientras otros hilos estén escribiendo.
- Informa de archivos, pruebas, métricas, altas de manifiesto y riesgos.
- Deja el estado LISTA_PARA_INTEGRAR.
```

Las pruebas completas usan salidas compartidas en `tests/bin` y `tests/dcu`.
Por eso calidad global, compilación y DUnitX en Win32/Win64 se ejecutan solo en
una mini-barrera con los demás escritores pausados o en la barrera de salida.
Un fallo observado mientras otro hilo edita no se atribuye a ninguna tarea.

Una prueba de caracterización se añade antes o en el mismo fascículo que la
extracción. No es válido mover código y escribir después una prueba que solo
reproduzca la nueva implementación.

### 3.4 Alta de unidades y pruebas nuevas

El hilo crea la unidad bajo su prefijo reservado, la referencia desde una
unidad propia cuando corresponda y solicita al integrador el alta. Solo el
integrador modifica los proyectos. La solicitud indica:

```text
Unidad nueva:
Proyecto de producción o pruebas:
Unidad que la consume:
Motivo del alta:
```

### 3.5 Barreras y olas

| Fase | Ejecución | Tareas | Barrera de salida |
|------|-----------|--------|-------------------|
| B0 | Serial | `IA-00` | Línea base y mapa de propiedad publicados |
| B1 | Serial | `IA-01` | Canal de inyección estable y congelado |
| O1 | Paralela | `IA-02C/V/M`, `IA-03A/I/S`, `IA-04` | Features sin búsqueda oculta |
| O1F | Aislada | `IA-05` | Facturas migradas tras cerrar su WIP |
| B2 | Serial | `IA-06` | Raíz cableada y localizador retirado |
| O3 | Paralela | subtareas `IA-10P` a `IA-16F` | Agregados grandes reducidos |
| B3 | Serial | `IA-14`; después `IA-18` | Bases y ola O3 integradas |
| O4 | Paralela | `IA-20A`, `IA-20B`, `IA-20C` | Ranking residual reducido |
| B4 | Serial | `IA-99` | Verificación final y nuevos trinquetes |

Las tareas de una ola se pueden ejecutar a la vez. Una ola no empieza hasta
que la barrera anterior esté verde. Si solo hay tres hilos disponibles, el
coordinador despacha la misma ola en tantas tandas como sean necesarias sin
introducir una barrera lógica entre ellas.

En este documento, **integrada** significa: todos los escritores están
detenidos, la propiedad se transfirió al integrador, las altas se aplicaron,
las pruebas están registradas y la barrera canónica quedó verde. No implica
que exista un commit.

---

## 4. Fase A — composición explícita

### [ ] IA-00 — confirmar una línea base estable

**Objetivo**

Evitar que una refactorización empiece sobre un fallo o sobre archivos que
otra sesión está editando.

**Acciones**

1. Ejecutar `git status --short`.
2. Identificar propietario de cada cambio local.
3. Comparar las unidades `tests/Pruebas*.pas` con
   `tests/FactuzamTests.dpr`.
4. Ejecutar `scripts/comprobar_calidad.ps1`.
5. Ejecutar `scripts/ejecutar_pruebas_delphi.ps1` si Delphi está disponible.
6. Guardar las cifras de acoplamiento, tamaño y métodos largos.
7. Publicar el mapa de rutas, pruebas y nombres reservados fuera del repo.

**Aceptación**

- Calidad verde.
- Compilación y DUnitX verdes en Win32 y Win64, o limitación de entorno
  documentada.
- Ningún archivo ajeno queda incluido en el alcance de la siguiente tarea.
- El inventario identifica toda prueba presente pero ausente del DPR.

En la auditoría del 04/08/2026 se detectaron seis unidades no registradas:
las cuatro `PruebasComposicion*Pantalla`, `PruebasModoTallas` y
`PruebasRepositoriosPantallaComposicion`. La barrera `IA-01` debe registrarlas
y ejecutarlas antes de congelar el canal de composición.

Esta tarea no modifica código ni documentos.

### [ ] IA-01 — crear el canal de composición explícita

**Objetivo**

Hacer que la raíz pueda entregar a una pantalla un contexto de feature ya
construido durante su creación. Probar el mecanismo con Stock Consulta, sin
retirar todavía la compatibilidad de los demás features.

**Propiedad exclusiva**

- `src/Lib/inLibShowMto.pas`;
- `src/Lib/inLibRegistroPantallas.pas`;
- `src/Core/inMtoPrincipal.pas`;
- `src/DataModules/UniDataComposicionAplicacion.pas`;
- `src/Lib/inLibRepositoriosPantallaIntf.pas`;
- `src/Forms/inMtoStockConsulta.pas`;
- `src/Forms/inMtoStockConsultaPresentacionComposicion.pas`;
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj` y
  `tests/FactuzamTests.res`;
- `tests/PruebasRegistroPantallas.pas`;
- `tests/PruebasRepositoriosPantallaComposicion.pas`;
- una prueba nueva reservada como `PruebasInyeccionStockConsulta.pas`.

**Diseño exigido**

- La raíz crea las implementaciones concretas.
- Stock Consulta recibe un `record` o contrato propio con solo las
  capacidades que utiliza.
- La falta de una dependencia obligatoria falla al crear o preparar la
  pantalla, no al pulsar un botón.
- El núcleo de Stock Consulta no recibe `TComponent`, `TForm`,
  `TUniConnection` ni una factoría general.
- El mecanismo debe servir para pantallas creadas desde el registro sin
  introducir un diccionario de servicios por nombre.

**Aceptación**

- Stock Consulta no llama a ninguna función `ObtenerCompositor*Pantalla`.
- Sus pruebas construyen el feature con dobles y sin `Application.MainForm`.
- Abrir una pantalla registrada conserva su autorización, propietario y
  ciclo de vida.
- El localizador heredado no recibe lógica nueva.
- Las seis pruebas detectadas por `IA-00` están registradas y se han
  ejecutado realmente.
- La API de inyección queda congelada para las tareas de O1.

### [ ] IA-02C — composición de Configuración

**Depende de:** `IA-01`.

**Puede ejecutarse con:** `IA-02V`, `IA-02M`, `IA-03A`, `IA-03I`,
`IA-03S` e `IA-04`.

**Propiedad exclusiva**

- `src/DataModules/UniDataConfiguracionPantalla.pas`;
- `src/Core/inMtoAppParam.pas` y su DFM;
- `src/Forms/inMtoBusquedaDatos.pas` y su DFM;
- `src/Forms/inMtoEmpresas.pas` y su DFM;
- `src/Modals/inMtoModalAddBlockBase.pas` y su DFM;
- `src/Modals/inMtoModalCalcularMargen.pas` y su DFM;
- `src/Modals/inMtoModalCargarEfectosRemesa.pas` y su DFM;
- `src/Modals/inMtoModalDistribuidor.pas` y su DFM;
- `src/Modals/inMtoModalFiltroArt.pas` y su DFM;
- `src/Modals/inMtoModalGenerarSKUs.pas` y su DFM;
- `src/Modals/inMtoModalGestionFiltros.pas` y su DFM;
- `src/Modals/inMtoModalGuiasBase.pas` y su DFM;
- `src/Modals/inMtoModalSeleccionarBanco.pas` y su DFM;
- `tests/PruebasComposicionConfiguracionPantalla.pas`.

**Nombres nuevos reservados:** prefijos
`inLibConfiguracionPantallaInyeccion*` y
`UniDataConfiguracionPantallaInyeccion*`.

**Aceptación**

- La propiedad exclusiva contiene 0 llamadas `ObtenerCompositor*Pantalla`.
- `ComponerConfiguracionPantalla` no usa `AOrigen` para buscar servicios.
- Cada consumidor recibe solo el repositorio o servicio que necesita.
- La prueba se ejecuta con dobles y sin raíz visual.

### [ ] IA-02V — composición de Ventas

**Depende de:** `IA-01`.

**Puede ejecutarse con:** todas las tareas O1 salvo un refactor de las
mismas pantallas de venta.

**Propiedad exclusiva**

- `src/DataModules/UniDataVentasPantallaComposicion.pas`;
- `src/Forms/inMtoAlbaranes.pas` y su DFM;
- `src/Forms/inMtoClientes.pas` y su DFM;
- `src/Forms/inMtoFacturasSimplif.pas` y su DFM;
- `src/Forms/inMtoPedidos.pas` y su DFM;
- `src/Modals/inMtoModalEnviarDestino.pas` y su DFM;
- `src/Modals/inMtoModalFacturarTicket.pas` y su DFM;
- `src/Modals/inMtoModalFacturarAlbaranesFechas.pas` y su DFM;
- `src/Modals/inMtoModalFacturarAlbaranes.pas` y su DFM;
- `src/Modals/inMtoModalGenImp.pas` y su DFM;
- `src/Modals/inMtoModalListadoVentas.pas` y su DFM;
- `src/Modals/inMtoModalSelAlmacenAlbaran.pas` y su DFM;
- `src/Modals/inMtoModalSelAlmacenPedido.pas` y su DFM;
- `src/Modals/inMtoModalSelFamilia.pas` y su DFM;
- `src/Modals/inMtoModalSerieFechaFactura.pas` y su DFM;
- `tests/PruebasComposicionVentasPantalla.pas`.

**Nombres nuevos reservados:** prefijos `inLibVentasPantallaInyeccion*` y
`UniDataVentasPantallaInyeccion*`.

**Aceptación**

- La propiedad exclusiva contiene 0 llamadas `ObtenerCompositor*Pantalla`.
- Los contextos de albarán, pedido, cliente, factura simplificada e impresión
  reciben capacidades concretas.
- Ningún consumidor conserva una bolsa de artículos, documentos o ventas.
- La prueba cubre creación, dependencia ausente y liberación.

### [ ] IA-02M — composición de documentos de Compra

**Depende de:** `IA-01`.

**Puede ejecutarse con:** O1 salvo `IA-05`, `IA-10P` e `IA-10D`.

**Propiedad exclusiva**

- `src/DataModules/UniDataComprasPantallaComposicion.pas`;
- `src/Forms/inMtoAlbaranesCompra.pas` y su DFM;
- `src/Forms/inMtoComprasPlantillas.pas` y su DFM;
- `src/Forms/inMtoDevolucionesCompra.pas` y su DFM;
- `src/Forms/inMtoDocumentosTrabajo.pas` y su DFM;
- `src/Forms/inMtoFacturasCompra.pas` y su DFM;
- `src/Forms/inMtoPedidosCompra.pas` y su DFM;
- `tests/PruebasComposicionComprasPantalla.pas`.

**Nombres nuevos reservados:** prefijos `inLibComprasPantallaInyeccion*` y
`UniDataComprasPantallaInyeccion*`.

**Aceptación**

- La propiedad exclusiva contiene 0 llamadas `ObtenerCompositor*Pantalla`.
- `ComponerComprasPantalla` no descubre el repositorio de artículos.
- Albarán, factura, pedido, devolución y documento de trabajo reciben
  contextos distintos.
- La prueba cubre cada variante y una dependencia obligatoria ausente.

### [ ] IA-03A — inyección de Artículos

**Depende de:** `IA-01`.

**Puede ejecutarse con:** las demás tareas O1.

**Propiedad exclusiva**

- `src/Forms/inMtoArticulos.pas` y su DFM;
- `tests/PruebasArticulosGuardado.pas`;
- `tests/PruebasArticulosAtributosBasicos.pas`;
- `tests/PruebasArticulosVisibilidad.pas`;
- `tests/PruebasArticulosVariaciones.pas`.

**Nombres nuevos reservados:** prefijos `inLibArticulosInyeccion*` y
`UniDataArticulosInyeccion*`.

**Aceptación**

- El formulario no conserva `IRepositoriosArticulosPantalla`.
- Guardado, propiedades y variaciones entran como capacidades separadas.
- Ningún evento crea un repositorio.
- Las pruebas construyen el contexto sin raíz visual.

### [ ] IA-03I — inyección de Inventarios

**Depende de:** `IA-01`.

**Puede ejecutarse con:** las demás tareas O1.

**Propiedad exclusiva**

- `src/Forms/inMtoInventarios.pas` y su DFM;
- `tests/PruebasInventariosAplicacion.pas`;
- `tests/PruebasInventariosEntrada.pas`.

**Nombres nuevos reservados:** prefijos `inLibInventariosInyeccion*` y
`UniDataInventariosInyeccion*`.

**Aceptación**

- El formulario no conserva `IRepositoriosArticulosPantalla`.
- Resolución, validación y atributos son dependencias visibles y mínimas.
- Los modos Auto, SKU y Tallas se prueban sin raíz visual.

### [ ] IA-03S — inyección de Sesiones de compra

**Depende de:** `IA-01`.

**Puede ejecutarse con:** las demás tareas O1.

**Propiedad exclusiva**

- `src/Forms/inMtoComprasSesiones.pas` y su DFM;
- `tests/PruebasComprasSesionesAplicacion.pas`;
- `tests/PruebasComprasSesionesCreacion.pas`;
- `tests/PruebasComprasSesionesRepositorio.pas`.

**Nombres nuevos reservados:** prefijos
`inLibComprasSesionesInyeccion*` y
`UniDataComprasSesionesInyeccion*`.

**Aceptación**

- El formulario no llama a `ObtenerCompositorSqlPantalla`.
- Catálogo SQL e incidencias entran como capacidades explícitas.
- Creación, reutilización y error se prueban sin raíz visual.

### [ ] IA-04 — migrar composición de Caja

**Depende de:** `IA-01`.

**Puede ejecutarse con:** `IA-02C`, `IA-02V`, `IA-02M`, `IA-03A`,
`IA-03I` e `IA-03S`.

**No puede ejecutarse con:** ningún refactor `IA-13*`.

**Objetivo**

Sustituir las bolsas de artículos, caja, configuración, operaciones y tickets
por contextos mínimos para cada caso de uso de Caja.

**Propiedad exclusiva**

- `src/Caja/Forms/inMtoCajaOpe.pas`;
- `src/DataModules/UniDataCajaPantallaComposicion.pas`;
- `src/Forms/inMtoConsultaOpe.pas`;
- todos los `.pas` bajo `src/Caja/Forms/` que llaman a
  `ComponerCajaPantalla`;
- todos los `.pas` bajo `src/Caja/Modals/` que llaman a
  `ComponerCajaPantalla`;
- `src/Modals/inMtoModalCajDef.pas`;
- `src/Modals/inMtoModalEntradaCambio.pas`;
- `src/Modals/inMtoModalOperacionesCajaSku.pas`;
- el DFM homónimo de cada formulario o modal de esta lista;
- `tests/PruebasComposicionCajaPantalla.pas`.

La reserva se materializa antes de iniciar con la salida exacta de:

```powershell
rg -l "ComponerCajaPantalla" src -g "*.pas"
```

**Nombres nuevos reservados:** prefijos `inLibCajaPantallaInyeccion*` y
`UniDataCajaPantallaInyeccion*`.

**Aceptación**

- `inMtoCajaOpe` no almacena `IRepositoriosArticulosPantalla`,
  `IRepositoriosCajaPantalla` ni `IRepositoriosTicketsCajaPantalla`.
- `UniDataCajaPantallaComposicion` no busca compositores por propietario.
- Cierre, tickets, stock y arqueo reciben contratos separados.
- No se introduce un `TServiciosCaja` que vuelva a exponer todo el dominio.
- Éxito, cancelación, fallo y rollback permanecen caracterizados.

### [ ] IA-05 — migrar composición de Facturas

**Precondición**

Los cambios locales de Facturas indicados en la sección 2 están integrados o
el usuario ha cedido expresamente su propiedad a esta tarea.

**Depende de:** `IA-02M` en `LISTA_PARA_INTEGRAR`, con sus rutas liberadas.

**Ejecución:** aislada; no comparte ola con Compras ni con `IA-12*`.

**Objetivo**

Completar la inyección de Facturas para que listado, líneas, cobros,
consolidación, incidencia fiscal y artículos reciban capacidades concretas.

**Propiedad exclusiva**

- `src/Forms/inMtoFacturasBase.pas` y su DFM;
- `src/Forms/inMtoFacturasIncidenciaFiscalVcl.pas`;
- `src/DataModules/UniDataFacturasIncidenciaFiscal.pas`;
- `src/Modals/inMtoModalResolverIncidenciaVerifactu.pas` y su DFM;
- `tests/PruebasFacturasAplicacion.pas`;
- `tests/PruebasFacturasIncidenciaFiscal.pas`;
- `tests/PruebasFacturasServicios.pas`.

**Nombres nuevos reservados:** prefijos `inLibFacturasInyeccion*` y
`UniDataFacturasInyeccion*`.

**Aceptación**

- `inMtoFacturasBase` no conserva `IRepositoriosArticulosPantalla`.
- No llama a `ObtenerCompositorSqlPantalla` ni a
  `ObtenerCompositorArticulosPantalla`.
- Ningún colaborador conserva el formulario completo para acceder a sus
  servicios.
- La incidencia fiscal recibe un servicio compuesto; su capa VCL no crea
  adaptadores UniDAC.
- El fan-out de `inMtoFacturasBase` baja de 72 a 50 o menos.

### [ ] IA-06 — retirar el localizador de repositorios de pantalla

**Ejecución:** serial, con todos los hilos de O1 y O1F detenidos.

**Objetivo**

Cerrar la migración y eliminar el mecanismo de compatibilidad. Esta tarea es
serial y no rediseña otra vez los features ya migrados.

**Propiedad exclusiva de la barrera**

- `src/Lib/inLibRepositoriosPantallaIntf.pas`;
- `src/Lib/inLibShowMto.pas`;
- `src/Lib/inLibRegistroPantallas.pas`;
- `src/DataModules/UniDataRepositoriosPantalla.pas`;
- adaptadores `UniDataRepositorios*Pantalla.pas`;
- `src/DataModules/UniDataComposicionAplicacion.pas`;
- `src/Core/inMtoPrincipal.pas`;
- `fzam.dpr` y `fzam.dproj`;
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj` y
  `tests/FactuzamTests.res`;
- `tests/PruebasRegistroPantallas.pas`;
- `tests/PruebasRepositoriosPantallaComposicion.pas`;
- `scripts/comprobar_dependencias_ocultas.ps1` y sus pruebas de trinquete.

**Aceptación**

- 0 símbolos `BuscarCompositor` y `ObtenerCompositor*Pantalla` en `src/`.
- 0 campos `IRepositorios*Pantalla` en formularios y colaboradores de
  presentación.
- `inLibRepositoriosPantallaIntf` desaparece o queda como un contrato puro:
  sin VCL, UniDAC, `TDataSet`, `TComponent` ni implementaciones concretas.
- `TfrmMtoPrincipal` deja de implementar los nueve compositores por familia.
- El comprobador bloquea la reaparición de búsqueda mediante `Owner`,
  `GetInterface` o `Application.MainForm` para repositorios de feature.
- El fan-out máximo del proyecto baja de 72 a 50 o menos.
- Todas las solicitudes de alta de O1/O1F están aplicadas.
- Calidad, compilación y DUnitX están verdes en Win32 y Win64.

No se prohíbe usar `Application.MainForm` para una operación estrictamente
visual, como enfocar o restaurar la ventana principal. Se prohíbe usarlo para
resolver una dependencia de negocio o persistencia.

---

## 5. Fase B — dividir por motivos de cambio

Estas tareas empiezan cuando `IA-06` está integrada. Cada extracción debe
reducir la pieza original y dejar la nueva pieza por debajo de los límites P5
que le correspondan. Trasladar el mismo monolito a otra unidad no cuenta.

Las firmas públicas entre dos subtareas de la misma ola quedan congeladas. Si
una extracción exige cambiar el contrato que consume un hilo hermano, ambos
se detienen y el coordinador crea primero una barrera de contrato; no adaptan
cada lado de forma independiente mientras siguen trabajando.

### [ ] IA-10P / IA-10D — documentos de compra

**Objetivo**

Separar la interacción VCL de la creación/recepción de albaranes y de la
devolución de stock.

**Ejecución:** dos hilos paralelos.

#### IA-10P — pedidos de compra

**Propiedad exclusiva**

- `src/Forms/inMtoPedidosCompra.pas` y su DFM;
- `src/Lib/inLibPedidosCompra.pas`;
- `src/Lib/inLibPedidosCompraIntf.pas`;
- `src/DataModules/UniDataPedidosCompraOperaciones.pas`;
- `src/DataModules/UniDataPedidosCompraPendientes.pas`;
- `src/DataModules/UniDataPedidosCompraAlbaranComun.pas`;
- `src/DataModules/UniDataPedidosCompraCreacionAlbaran.pas`;
- `src/DataModules/UniDataPedidosCompraIncorporacionAlbaran.pas`;
- `src/DataModules/UniDataPedidosCompraRecepcion.pas`;
- `tests/PruebasPedidosCompra.pas`;
- `tests/PruebasPivoteCompraCalculo.pas`;
- `tests/PruebasGridPivoteCompraPersistencia.pas`.

**Nombres nuevos reservados:** prefijos `inLibPedidosCompraPresentacion*` y
`UniDataPedidosCompraFlujo*`.

#### IA-10D — devoluciones de compra

**Propiedad exclusiva**

- `src/Forms/inMtoDevolucionesCompra.pas` y su DFM;
- `src/Lib/inLibDevolucionesCompraMovimientos.pas`;
- `src/Lib/inLibDevolucionesCompraMovimientosIntf.pas`;
- `src/DataModules/UniDataDevolucionesCompraMovimientos.pas`;
- `tests/PruebasDevolucionesCompraMovimientos.pas`.

**Nombres nuevos reservados:** prefijos
`inLibDevolucionesCompraPresentacion*` y
`UniDataDevolucionesCompraFlujo*`.

**Focos obligatorios**

- `btnCrearAlbaranClick`;
- `DevolverTodoStock`;
- `AplicarArticuloDevolucion`;
- propietario de transacción y rollback de movimientos.

**Aceptación**

- `IA-10P`: `TfrmMtoPedidosCompra` queda por debajo de 2.000 líneas y
  `btnCrearAlbaranClick` queda en 15 líneas efectivas o menos.
- `IA-10D`: `TfrmMtoDevolucionesCompra` queda por debajo de 2.000 líneas y
  el riesgo de `DevolverTodoStock` baja de 92 a 30 o menos.
- Cada hilo prueba su operación sin el formulario.
- Ambos cubren cancelación, cantidades parciales, fallo y rollback.

### [ ] IA-11P / IA-11A — documentos de venta

**Objetivo**

Separar edición/presentación, reglas de entrada y generación de movimientos
de la persistencia de pedidos y albaranes.

**Ejecución:** dos hilos paralelos, después de `IA-02V`.

#### IA-11P — pedidos de venta

**Propiedad exclusiva**

- `src/Forms/inMtoPedidos.pas` y su DFM;
- `src/DataModules/UniDataPedidos.pas` y su DFM;
- `tests/PruebasPivoteVenta.pas`;
- una prueba nueva reservada como `PruebasPedidosVentaPresentacion.pas`.

**Nombres nuevos reservados:** prefijos `inLibPedidosVentaPresentacion*` y
`UniDataPedidosVentaFlujo*`.

#### IA-11A — albaranes de venta

**Propiedad exclusiva**

- `src/Forms/inMtoAlbaranes.pas` y su DFM;
- `src/DataModules/UniDataAlbaranes.pas` y su DFM;
- una prueba nueva reservada como `PruebasAlbaranesVentaMovimientos.pas`.

**Nombres nuevos reservados:** prefijos `inLibAlbaranesVentaPresentacion*` y
`UniDataAlbaranesVentaMovimientos*`.

**Focos obligatorios**

- `ConstruirModoEntrada`;
- `AplicarArticuloAlbaran`;
- `GenerarMovimientosSalida`.

**Aceptación**

- `IA-11P`: `TdmPedidos` queda por debajo de 2.000 líneas y
  `ConstruirModoEntrada` queda en 60 líneas o menos.
- `IA-11A`: `TdmAlbaranes` queda por debajo de 2.000 líneas;
  `AplicarArticuloAlbaran` y `GenerarMovimientosSalida` quedan en 60 o menos.
- El evento de dataset delega; no coordina por sí solo varias escrituras.
- Las reglas extraídas trabajan con valores o records, no con controles.
- Movimientos de salida conservan atomicidad y pruebas de rollback.

### [ ] IA-12F / IA-12E / IA-12V / IA-12R — fiscalidad

**Precondición**

`IA-05` está cerrada y no hay trabajo local ajeno en las unidades fiscales.

**Objetivo**

Separar validación de cabecera, construcción del registro fiscal, registro de
eventos y persistencia de resultados.

**Ejecución:** cuatro hilos paralelos. Ninguno toca las unidades de incidencia
fiscal de `IA-05`.

| Tarea | Propiedad exclusiva | Prueba exclusiva |
|-------|---------------------|------------------|
| `IA-12F` | `src/DataModules/UniDataFacturas.pas` y DFM | `tests/PruebasFacturasLecturas.pas` |
| `IA-12E` | `src/verifactu/inLibVerifactuEnvio.pas` | `tests/PruebasEmisionFiscal.pas` |
| `IA-12V` | `src/verifactu/inLibVerifactu.pas` | nueva `PruebasRegistroEventosVerifactu.pas` |
| `IA-12R` | `src/verifactu/UniDataVerifactuColaResultados.pas` | nueva `PruebasVerifactuColaResultados.pas` |

**Nombres nuevos reservados**

- `IA-12F`: `inLibFacturasValidacion*`;
- `IA-12E`: `inLibVerifactuConstruccionEnvio*`;
- `IA-12V`: `inLibVerifactuRegistroEventos*`;
- `IA-12R`: `UniDataVerifactuResultadosEnvio*`.

**Focos obligatorios**

- `TdmFacturas.ValidarCabeceraBeforePost`;
- `ConstruirRegistroAlta`;
- `RegistrarEventoVerifactu`;
- `TResultadosVerifactuColaUniDAC.GuardarEnvioOk`;
- `EnviarRegistroFactura`.

**Aceptación**

- `IA-12F` deja `TdmFacturas` por debajo de 2.000 líneas.
- Cada hilo deja sus focos en 60 líneas o menos.
- Ningún método fiscal modificado supera 10 decisiones.
- Construcción y validación se prueban sin VCL y, cuando sean puras, sin BBDD.
- Idempotencia, error parcial y estado de cola quedan caracterizados.

### [ ] IA-13E / IA-13C / IA-13T / IA-13A — Caja

**Objetivo**

Dividir `TEditorLineasCajaVcl` por interacción, búsqueda/stock y renderizado;
separar en el data module la persistencia de la coordinación de cierre.

**Ejecución:** cuatro hilos paralelos, después de `IA-04`.

| Tarea | Propiedad exclusiva | Pruebas exclusivas |
|-------|---------------------|--------------------|
| `IA-13E` | `src/Caja/Forms/inMtoCajaOpe.pas` y DFM | `PruebasCajaEntrada`, `PruebasCajaVentaOperacion` |
| `IA-13C` | `src/Caja/DataModules/UniDataCaja.pas` y DFM | `PruebasCajaVenta`, `PruebasCajaStock` |
| `IA-13T` | `src/Caja/Lib/inLibArqueoTicket.pas` | `tests/PruebasArqueoTicketCatalogo.pas` |
| `IA-13A` | `src/Caja/Modals/inMtoModalArqueo.pas` y DFM, `src/Caja/DataModules/UniDataModalArqueoRepositorio.pas` | nueva `tests/PruebasModalArqueoPersistencia.pas` |

`PruebasArqueoTicketCatalogo.pas` pertenece solo a `IA-13T`; la prueba nueva
de `IA-13A` evita compartir archivos entre ambos hilos.

**Nombres nuevos reservados:** prefijos `inMtoCajaEditorLineas*`,
`UniDataCajaCierreVenta*`, `inLibArqueoTicketPresentacion*` y
`UniDataModalArqueoOperacion*`, respectivamente.

**Focos obligatorios**

- `TEditorLineasCajaVcl`;
- `TdmCajaOpe.GrabarFacturaSimplificada`;
- `TArqueoTicket.ImprimirCierre`;
- `TfrmModalArqueo.GrabarArqueo`.

**Aceptación**

- `IA-13E` deja `TEditorLineasCajaVcl` por debajo de 2.000 líneas.
- `IA-13C` deja `TdmCajaOpe` por debajo de 2.000 líneas.
- Cada colaborador nuevo tiene un único propietario y ciclo de vida.
- El cálculo y las decisiones se prueban sin rejilla ni controles DevExpress.
- Los handlers VCL modificados quedan en 15 líneas efectivas o menos.
- Los métodos de caja modificados no superan 10 decisiones.

### [ ] IA-14 — shell, arranque y bases VCL

**Ejecución:** serial después de que todos los hilos O3 estén detenidos y
antes de `IA-18`. No se ejecuta a la vez que ninguna tarea de feature.

**Objetivo**

Reducir responsabilidades de `TfrmMtoPrincipal` y `TfrmMtoGen` sin romper el
contrato de herencia de las pantallas existentes.

**Propiedad exclusiva**

- `src/Core/inMtoPrincipal.pas` y su DFM;
- `src/Core/inMtoLogon.pas` y su DFM;
- `src/Core/inMtoFrmBase.pas` y su DFM;
- `src/Forms/inMtoGen.pas` y su DFM;
- `tests/PruebasLogonAplicacion.pas`;
- `tests/PruebasMtoGenAplicacion.pas`;
- `tests/PruebasRegistroPantallas.pas`.

**Nombres nuevos reservados:** prefijos `inLibArranqueAplicacion*`,
`inMtoPrincipalPresentacion*` e `inLibContratoMtoGen*`.

**Focos obligatorios**

- `TfrmMtoPrincipal.InicializarAplicacion`;
- `TfrmLogon.FormCreate`;
- propagación de servicios heredados;
- hooks de `TfrmMtoGen` y orden de `inherited`.

**Aceptación**

- `TfrmMtoPrincipal` y `TfrmMtoGen` quedan por debajo de 2.000 líneas.
- Arranque y autenticación se coordinan mediante casos de uso comprobables.
- `FormCreate` queda limitado a preparar y delegar.
- Cada contrato heredado relevante tiene una batería compartida para sus
  descendientes.
- No se añade una capacidad a la clase base si solo la usa un feature.

### [ ] IA-15B / IA-15C / IA-15X — infraestructura

**Objetivo**

Dividir los algoritmos largos de infraestructura en lectura, transformación,
validación y escritura, preservando streaming y mensajes de error.

**Ejecución:** tres hilos paralelos.

| Tarea | Propiedad exclusiva | Pruebas exclusivas |
|-------|---------------------|--------------------|
| `IA-15B` | `src/Lib/backup/Backup.Engine.pas` | `tests/PruebasCopiasSeguridad.pas`, `tests/PruebasRestauracionCopiasConexion.pas` |
| `IA-15C` | `src/Lib/backup/Core_Engine.pas` | nueva `tests/PruebasComparacionCopias.pas` |
| `IA-15X` | `src/Lib/inLibVerifactuNoVerifactuVerify.pas` | nueva `tests/PruebasVerificacionXadesNoVerifactu.pas` |

**Nombres nuevos reservados:** prefijos `Backup.Lectura*`,
`Backup.Comparacion*` e `inLibVerificacionXades*`, respectivamente.

**Focos obligatorios**

- `TDBBackupEngine.BackupTableData`;
- `TDBComparerEngine.CompareData`;
- `VerificarPerfilXadesNoVerifactu`.

**Aceptación**

- Cada hilo deja su foco en 60 líneas o menos.
- Comparar no modifica y respaldar no valida reglas ajenas a su formato.
- La verificación devuelve un resultado tipado por causa de rechazo.
- Se prueban datos vacíos, lotes grandes, cancelación y entrada mal formada.
- No se carga en memoria completa una tabla que antes se procesaba en flujo.

### [ ] IA-16V / IA-16F — variaciones y fotos

**Objetivo**

Dividir los adaptadores pendientes según lectura/escritura y metadatos/blob,
sin crear un repositorio genérico.

**Ejecución:** dos hilos paralelos.

#### IA-16V — variaciones de artículos

**Propiedad exclusiva**

- `src/DataModules/UniDataArticulosVariaciones.pas`;
- `src/Lib/inLibArticulosVariaciones.pas`;
- `src/Lib/inLibArticulosVariacionesIntf.pas`;
- `tests/PruebasArticulosVariaciones.pas`.

**Nombres nuevos reservados:** prefijo `UniDataArticulosVariaciones*`.

#### IA-16F — fotos

**Propiedad exclusiva**

- `src/DataModules/UniDataFotosRepositorio.pas`;
- `src/Lib/inLibFotosPersistenciaIntf.pas`;
- `tests/PruebasFotosPersistencia.pas`.

**Nombres nuevos reservados:** prefijo `UniDataFotos*Repositorio`.

**Aceptación**

- `IA-16V` baja `UniDataArticulosVariaciones` de 43 a 30 rutinas o menos.
- `IA-16F` baja `UniDataFotosRepositorio` de 33 a 30 rutinas o menos.
- Lectura y escritura se segregan cuando tienen consumidores distintos.
- Los contratos no exponen UniDAC ni detalles de almacenamiento.
- Se prueban ausencia, fallback artículo/SKU, reemplazo y error de escritura.

### [ ] IA-18 — integrar la ola de refactorización

**Ejecución:** serial; empieza después de `IA-10*` a `IA-16*` y de `IA-14`.

**Propiedad exclusiva de la barrera**

- `fzam.dpr` y `fzam.dproj`;
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj` y
  `tests/FactuzamTests.res`;
- altas de unidades solicitadas por los hilos;
- manifiestos y archivos de proyecto afectados.

**Acciones**

1. Verificar que cada hilo entregó solo archivos de su reserva.
2. Aplicar altas de producción y pruebas.
3. Eliminar unidades nuevas huérfanas o no consumidas.
4. Ejecutar calidad, compilación y DUnitX en Win32 y Win64.
5. Medir tamaños, fan-out, métodos largos y riesgo.
6. Publicar la reserva exacta de `IA-20A`, `IA-20B` e `IA-20C`.

**Aceptación**

- Todas las tareas O3 quedan `CERRADA` o `REABIERTA` con un fallo concreto.
- Las pruebas nuevas están registradas y se han ejecutado realmente.
- La barrera queda verde antes de iniciar O4.

---

## 6. Fase C — métodos largos residuales

### [ ] IA-20A / IA-20B / IA-20C — métodos largos residuales

**Objetivo**

Después de `IA-18`, reducir en tres hilos los métodos de más de 120 líneas que
no hayan quedado cubiertos. Cada hilo recibe hasta cinco unidades completas.

**Selección de cada tanda**

1. `IA-18` ejecuta `scripts/comprobar_metodos_largos.ps1`.
2. Ordena primero por zona fiscal/caja, después por riesgo y luego por líneas.
3. Excluye unidades sucias, compartidas o ya reservadas.
4. Selecciona hasta quince unidades y mantiene cada unidad completa.
5. Asigna puestos 1, 4, 7... a `IA-20A`; 2, 5, 8... a `IA-20B`; y
   3, 6, 9... a `IA-20C`.
6. Publica rutas, pruebas y prefijos antes de iniciar los tres hilos.

No se permite seleccionar archivos dinámicamente después de empezar la ola.
Si un hilo termina antes, no toma una unidad de otro sin transferencia formal.

**Reglas de extracción**

- Extraer decisiones o pasos con nombre, no intervalos de líneas.
- Mantener un solo nivel de abstracción por método.
- Separar cálculo, decisión, persistencia y presentación.
- Usar estrategia solo cuando exista una variante de negocio real.
- No crear una clase que reciba el objeto original completo.

**Propiedad exclusiva**

La lista exacta publicada por `IA-18`. Cada hilo reserva además pruebas nuevas
con sufijo `Ola20A`, `Ola20B` u `Ola20C`. Manifiestos, scripts y métricas
globales siguen prohibidos durante la ola.

**Aceptación de la iteración**

| Indicador | Inicio | Objetivo máximo |
|-----------|-------:|----------------:|
| Métodos de más de 120 líneas | 67 | 40 |
| Riesgo acumulado | 13.134 | 9.000 |
| Riesgo individual máximo | 280 | 200 |
| Métodos de más de 200 líneas | 0 | 0 |

La siguiente versión de este documento continuará desde la nueva medición;
no se seleccionan unidades usando el ranking antiguo de la sección 2.

---

## 7. IA-99 — integración y cierre

### [ ] IA-99 — actualizar trinquetes y demostrar el resultado

**Ejecución:** serial, con `IA-20A`, `IA-20B` e `IA-20C` en
`LISTA_PARA_INTEGRAR` y sin ningún escritor activo.

**Objetivo**

Integrar las tareas terminadas, ajustar los límites exclusivamente a la baja
y dejar una fotografía reproducible para la siguiente iteración.

**Propiedad exclusiva durante esta tarea**

- `fzam.dpr` y `fzam.dproj`;
- manifiestos de `tests/`;
- `scripts/comprobar_*.ps1` y pruebas de trinquetes;
- `PLAN_SOLID.md` y `TAREAS_IA_SOLID.md`.

**Acciones**

1. Revisar que cada unidad nueva esté incluida en los proyectos adecuados.
2. Eliminar fachadas de migración sin consumidores.
3. Ejecutar `rg` para detectar contratos o métodos retirados.
4. Bajar topes individuales a las medidas reales conseguidas.
5. Ejecutar calidad, compilación y DUnitX en Win32 y Win64.
6. Actualizar la línea base y marcar únicamente tareas demostradas.

**Aceptación final**

- Calidad completa verde.
- Compilación y DUnitX verdes en Win32 y Win64.
- 0 localizadores de repositorios de pantalla.
- 0 clases propias por encima de 2.000 líneas.
- Fan-out máximo de 50 o menos.
- Como máximo 40 métodos de más de 120 líneas.
- Riesgo acumulado de 9.000 o menos y riesgo máximo de 200.
- Permanecen a cero estilo, consultas UI, SQL en dominio, ciclos de capa,
  globales y `except` vacíos.
- No se ha modificado `factuzam_original.sql`.

IA-99 no hace una refactorización nueva para maquillar una métrica. Si una
aceptación no se cumple, reabre la tarea responsable con el dato concreto.

---

## 8. Definición de terminado por tarea

Un hilo termina su edición en `LISTA_PARA_INTEGRAR`. La tarea solo pasa a
`CERRADA` después de la barrera. Para quedar lista debe entregar:

- comportamiento conservado o cambio funcional autorizado y documentado;
- archivos editados y creados;
- métrica antes y después de la pieza original y de las nuevas;
- pruebas añadidas o adaptadas, con casos de éxito y fallo relevantes;
- comprobadores ejecutados y resultado;
- pruebas realmente ejecutadas o la mini-barrera que falta para ejecutarlas;
- solicitudes de alta en manifiestos y de cableado en la raíz;
- confirmación de 0 archivos modificados fuera de su reserva;
- riesgos pendientes y decisiones que deba conocer la siguiente tarea.

No está terminada si:

- la nueva clase conserva el formulario completo;
- una dependencia se obtiene con un singleton, `Application.MainForm`,
  recorrido de propietarios o una factoría general;
- se ha movido el monolito sin reducir sus responsabilidades;
- un resultado de error se convierte en éxito aparente;
- se amplía un tope, baseline, exclusión o lista blanca;
- el diff incluye archivos ajenos o normalización masiva no solicitada.

Formato recomendado de entrega:

```text
Tarea:
Estado: LISTA_PARA_INTEGRAR
Reserva recibida:
Archivos editados:
Archivos creados y nombres de unidad reservados:
Archivos ajenos detectados y no tocados:
Responsabilidad extraída:
Comportamiento caracterizado:
Métricas locales antes/después:
Pruebas añadidas:
Pruebas realmente ejecutadas:
Compilación privada o mini-barrera utilizada:
Solicitudes de alta en manifiestos:
Solicitudes de cableado en la raíz:
Riesgos y dependencias pendientes:
```

---

## 9. Decisiones que no se reabren

- UniDAC sigue siendo el acceso a datos.
- `factuzam_original.sql` no se modifica.
- Todo cambio de esquema vive en un script idempotente dentro de
  `DESARROLLOS EN CURSO/`.
- `inLib* -> UniData*` permanece en cero.
- SQL y transacciones no vuelven a formularios.
- SQL literal no vuelve a unidades de dominio.
- No vuelven `Exit`, `Continue`, `with`, líneas anchas, tabuladores,
  globales de interfaz ni `except` vacíos.
- No se añade una interfaz por método ni un patrón por apariencia.
- La herencia VCL se conserva donde expresa una relación real, pero sus
  contratos se prueban y las capacidades opcionales se componen.
- No se hace commit ni push salvo petición expresa del usuario.

Esta hoja de ruta es un trinquete, no un registro histórico. Al cerrar
`IA-99`, Git conserva el pasado y el documento se vuelve a escribir con los
problemas que sigan siendo reales.
