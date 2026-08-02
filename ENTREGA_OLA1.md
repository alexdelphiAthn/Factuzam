# Entrega Ola 1 — features críticos (IA-11 … IA-16)

Fecha: 02/08/2026. Ejecutada en paralelo, una sesión por tarea, sobre listas
de unidades disjuntas. Integrada por el coordinador.

## Estado por tarea

| Tarea | Feature | Criterios cumplidos | Pendiente |
|---|---|---|---|
| IA-11 | Facturas | `TControladorFacturas` eliminada; 104 → 72 métodos; clase 1761 → 1595 líneas; 0 `TUniQuery.Create`; 0 SQL | 2 entradas obsoletas en `comprobar_formularios_delgados.ps1` |
| IA-12 | Caja | Handler 335: 154 → 12 líneas, 8 → 0 salidas, 22 → 1 decisión; núcleo probado sin VCL | `TfrmMtoOpeCaja` sigue en 3.872 líneas (objetivo 2.000) |
| IA-13 | Compras Sesiones | 3.756 → 1.959 líneas; 28 → 7 campos; 3 → 0 `TTimer`; 75 → 6 `Exit`; 0 SQL | 2 consultas siguen en capa UI (no en `UniData*`) |
| IA-14 | Artículos | Clase 2.971 → 1.806 líneas; 0 consultas, 0 SQL, 0 transacciones en UI; 57 → 19 `Exit` | — |
| IA-15 | Inventarios | Clase 2.881 → 1.991 líneas; **102 → 6 `Exit`**; 0 SQL/`TUniQuery` en UI | — |
| IA-16 | Stock Consulta | 2.508 → 1.214 líneas; 40 → 10 campos; 75 → 38 métodos; 13 → 0 `Exit`; 0 líneas anchas | 1 acceso a `ContextoRepositoriosPantalla` (composición; lo retira IA-31) |

## Trinquetes (`scripts/comprobar_*.ps1`, PowerShell 7 sobre Linux)

Comparados contra el árbol de partida para separar regresiones reales de
artefactos del entorno.

**Verdes y mejorando**

| Comprobador | Antes | Después |
|---|---|---|
| `comprobar_estilo_codigo` | Exit 1.060 / With 322 / anchas 462 | **Exit 818 / With 270 / anchas 404** |
| `comprobar_metodos_largos` | 101 métodos >120 líneas, riesgo 23.076 | **92, riesgo 21.475** |
| `comprobar_consultas_ui` | 5 transacciones | **4** |
| `comprobar_codificacion` | 0 nuevas | **0 nuevas** |
| `comprobar_dependencias_ocultas` | OK | OK |
| `comprobar_sql_transacciones`, `comprobar_supports`, `comprobar_registro_pantallas` | OK | OK |

**Falla solo `comprobar_formularios_delgados`** — ver más abajo.

**Fallos preexistentes, no atribuibles a la Ola 1**: `comprobar_acoplamiento`,
`comprobar_sql_en_dominio`, `comprobar_interfaces_segregadas`,
`comprobar_dependencias_capas`, `comprobar_flujos_largos`,
`comprobar_estado_global` y los máximos globales de `comprobar_tamano_clases`
fallan **idénticamente en el árbol original** al ejecutarse sobre Linux: sus
listas de exclusión usan rutas con barra invertida (`'\3rdpartyComp\'`), que
nunca casan con rutas POSIX, así que analizan `src/3rdpartyComp/` (SynEdit,
SynPDF, SQLBuilder4Delphi). En Windows no se dan.

## Decisión pendiente

`scripts/comprobar_formularios_delgados.ps1` exige que existan tres métodos
protegidos en `inMtoFacturasBase.pas`. Uno se ha restaurado
(`TfrmMtoFacturasBase.GuardarPendienteAntesDeImprimir`). Los otros dos exigen
la clase que IA-11 tenía que eliminar por contrato:

```
líneas 24-28:  @{ Ruta='src\Forms\inMtoFacturasBase.pas'
                  Clase='TControladorFacturas'
                  Metodo='GuardarPendienteAntesDeImprimir' },
líneas 29-33:  @{ Ruta='src\Forms\inMtoFacturasBase.pas'
                  Clase='TControladorFacturas'
                  Metodo='MostrarSkuArticulo' },
```

Satisfacerlas obliga a resucitar `TControladorFacturas` con campo
`TfrmMtoFacturasBase`, justo lo que prohíbe el criterio de aceptación de
IA-11. El comportamiento protegido sigue cubierto:
`GuardarPendienteAntesDeImprimir` vive en el formulario y `MostrarSkuArticulo`
en `TPresentadorLineasFacturaVcl`, con pruebas en
`PruebasFacturasPresentadorDetalle`. **IA-99 debe retirar esos dos bloques.**

## Unidades nuevas (41 en `fzam.dpr`, 2 en `FactuzamTests.dpr`)

Ya registradas en `fzam.dpr`, `fzam.dproj`, `tests\FactuzamTests.dpr` y
`tests\FactuzamTests.dproj` por el coordinador.

- **Facturas**: `inLibFacturasPresentadorDetalle`, `...Cabecera`, `...Listado`,
  `inMtoFacturasPresentadorLineasVcl`, `...CabeceraVcl`, `UniDataFacturasListado`
- **Caja**: `inLibCajaOpePresentacionIntf`, `inLibCajaOpePresentacion`,
  `inMtoCajaOpePresentacionVcl`
- **Compras Sesiones**: `inLibComprasSesionesPresentacionIntf`, `...Presentacion`,
  y `inMtoComprasSesionesPresentacion{Planificador,Materializacion,Tallas,Modelo,CopiaLineas,Proveedor}`
- **Artículos**: `inLibArticulosPresentacionIntf`, `...Presentacion`,
  `UniDataArticulosPresentacionRepositorio`,
  `inMtoArticulosPresentacion{Atributos,Stock,Tarifas,Filtros}`
- **Inventarios**: `inLibInventariosPresentacionIntf`, `...Presentacion`,
  `inMtoInventariosPresentacion{Columnas,Entrada,Busquedas}`,
  `UniDataInventariosBusquedas`
- **Stock Consulta**: `inLibStockConsultaPresentacion{Vista,Historial,Coincidencias,Estados,Fotos,Propiedades,Pivote}`,
  `inMtoStockConsultaPresentacion{ArticuloVcl,FotosVcl,PivoteVcl,Composicion}`

Tres unidades (`UniDataFacturasListado`, `UniDataArticulosPresentacionRepositorio`,
`UniDataInventariosBusquedas`) salen de los prefijos reservados: el criterio
"0 SQL en la UI" obliga a un adaptador de persistencia, y el SQL no puede
vivir en `inLib*` ni en `inMto*`. Son unidades nuevas; no se modificó ninguna
`UniData*` existente.

## Pruebas añadidas

Unas 130 pruebas DUnitX nuevas, todas sin VCL y sin conexión, con dobles de
las interfaces. Se conservan intactas las pruebas previas de las unidades
asignadas.

## Verificación pendiente (obligatoria)

Nada de esto se ha compilado: el entorno era Linux. Antes de dar la ola por
cerrada hay que ejecutar en Windows:

```
scripts\comprobar_calidad.ps1
compilar_release_win64.cmd          (y la compilación Win32)
scripts\ejecutar_pruebas_delphi.ps1 (DUnitX Win32 y Win64)
```

Puntos donde mirar primero si algo no compila, señalados por las sesiones:

- **IA-11**: unidades DevExpress en los registros de controles (`cxDBEdit`,
  `cxSpinEdit`, `cxCalendar`, `cxMemo`, `cxImage`).
- **IA-12**: `TcxGridTableView.Controller.FocusedColumn` y
  `EditingController.ShowEdit`; el `AKey in [VK_ESCAPE, ...]` de
  `TraducirTeclaLineaCaja`.
- **IA-15**: `TcxEditValidateEvent` como parámetro en
  `CrearColumnasDocumentoInventario`; `TArray<string>` sobre parámetro *open
  array* en `SeleccionarAvConPaleta`.

## Riesgos y cambios de comportamiento deliberados

- **IA-11**: se eliminan 2 enlaces del DFM a handlers cuyo cuerpo era
  `inherited;` vacío.
- **IA-12**: `Post` y escritura de código de artículo pasan a estar guardados
  por `State in [dsEdit, dsInsert]` (más defensivo que el original).
- **IA-13**: `TCoordinadorProveedorSesion` sigue recibiendo `TdmComprasSesiones`
  (dependencia ancha). Para cerrarla hay que cambiar
  `UniDataComprasSesionesOperaciones.ValidarKitSobreLineaActual` /
  `AplicarKitProveedorALinea` para que reciban los dos `TDataSet` en vez del
  data module. Unidad ajena: no se tocó.
- **IA-15**: los tooltips de `tvLineasGetCellHint` ahora sobreviven al
  `ClearItems` del contrato de entrada; se retiraron dos trazas de diagnóstico
  temporal marcadas como tales.
- **IA-16**: `Pos('varios SKUs', AMensaje)` sustituido por comparación contra
  el `resourcestring`; los `TcxStyle` por estado se crean antes de la primera
  recarga (antes llegaban `nil`).
