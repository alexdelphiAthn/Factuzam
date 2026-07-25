# Refactor del subsistema Excel — Fases y pruebas

> Documento de trabajo (previo a implementar). Define el **alcance**, el
> **puerto/adaptador**, el **plan por fases** y la **estrategia de pruebas**.
> Sigue el patrón del repo: `*Intf` + factoría + `IProveedor*`, sin globales
> (`LIBRO_DE_ESTILO_DELPHI.md` §14). Nada de código todavía.

---

## 1. Alcance

En el proyecto conviven **dos familias** de exportación a Excel; solo una es
objeto de este refactor:

- **(A) Export genérico de grid** — `inLibDevExp.ExportarExcel(ParametrosApp,
  cxGrid, nombre, …)`. Usado en ~10 Mtos (`inMtoArticulos`, `inMtoClientes`,
  `inMtoEmpresas`, `inMtoFacturasBase`, `inMtoFormasdePago`,
  `inMtoGeneradorProcesos`, `inMtoModalListadoVentas`…). Ya recibe
  `ParametrosApp` y delega en el volcado nativo del `cxGrid`. Acoplamiento
  fino y sin duplicación → **fuera de alcance** (posible fase posterior).

- **(B) Export de plantilla celda-a-celda** — `inLibDevExcel` (motor) + los
  exportadores de dominio que escriben un documento formateado sobre un
  `TdxSpreadSheet`. **Este es el objetivo.**

### 1.1 Unidades objetivo (familia B)

Motor: `Lib/inLibDevExcel.pas`. Exportadores:

| Unidad | Rutina pública | Call sites |
|---|---|---|
| `inLibMovVentasArtExcel` | `ExportarMovVentasArtExcel(Sheet; Q)` | `inMtoModalImpMovVentasArt:284` |
| `inLibBalanceTallasExcel` | `ExportarBalanceTallasExcel(Sheet; Q)` | `inMtoModalImpBalanceTallas:368` |
| `inLibBalanceSinTallasExcel` | `ExportarBalanceSinTallasExcel(Sheet; Q)` | modal balance sin tallas |
| `inLibInventarioExcel` | `ExportarInventarioExcel(Sheet; QMaster,QLineas)` **+** `ImportarInventarioDesdeSheet(Sheet; out …)` | `inMtoInventarios:2816` (export) y `:3048` (import) |
| `inLibDocumentosTrabajoExcel` | `ExportarDocumentoTrabajoExcel(…)` | `inMtoDocumentosTrabajo:490` |
| `inLibFacturaExcel` | `ExportarFacturaADevExpress(ParametrosApp; Conn; Sheet; QMaster,QLineas)` | `inMtoModalImpFac:106` |
| `inLibDocCompraExcel` | `ExportarDocCompraHorizontal/Vertical(Conn; Sheet; …)` | `inMtoModalImpDevCompra:102`, `…DevCompraV:101`, `…FacCompra:104`, `…FacCompraV:103`, `…Sesion:108` |

Métodos de formulario con el mismo patrón (a incluir al final):
`inMtoCajaOperacionesHist.ExportarResumenExcel/ExportarVistaExcel/ExportarOperacionExcel(ASheetControl: TdxSpreadSheet)`
y `inLibTiraCajaTicket.ExportarExcel(AOwner; …)`.

### 1.2 Host de previsualización

Todos comparten el patrón: un modal crea `fPreview: TfrmMtoPreviewExcel`
(`Core/inMtoPreviewExcel`), llama `ExportarXxx(fPreview.dxSpreadSheet1, …)` y
lo muestra; el botón *Guardar* hace `dxSpreadSheet1.SaveToFile(...xlsx)`. El
punto de cableado del adaptador es siempre `fPreview.dxSpreadSheet1`.

---

## 2. Superficie real a desacoplar

Del motor `inLibDevExcel`, **solo 4 rutinas tocan DevExpress**
(`TdxSpreadSheetTableView`): `Merge`, `W`, `WFormula`, `PintarCuadro`. Las
otras tres (`GetRef`, `ColToLetras`, `SepFormula`) son **puras** (solo
`FormatSettings`) y no necesitan interfaz. Esto hace el puerto muy pequeño.

### 2.1 Puerto de escritura — `IEscritorHojaCalculo`

```pascal
type
  TAlineacionCelda = (acIzquierda, acCentro, acDerecha);
  TEstiloBorde     = (ebNinguno, ebFino, ebMedio, ebGrueso);

  IEscritorHojaCalculo = interface
    ['{...GUID...}']
    procedure Combinar(AFila, ACol, ANumFilas, ANumCols: Integer);          // Merge
    procedure Escribir(AFila, ACol: Integer; const AValor: Variant;         // W
                       ANegrita: Boolean = False;
                       AAlineacion: TAlineacionCelda = acIzquierda);
    procedure EscribirFormula(AFila, ACol: Integer; const AFormula: string; // WFormula
                              const AFormato: string = '');
    procedure DibujarCuadro(AF1, AC1, AF2, AC2: Integer;                    // PintarCuadro
                            AEstilo: TEstiloBorde);
    procedure Guardar(const ARuta: string);                                // SaveToFile
  end;
```

### 2.2 Puerto de lectura — `ILectorHojaCalculo` (ruta de importación)

```pascal
  ILectorHojaCalculo = interface
    ['{...GUID...}']
    function LeerCelda(AFila, ACol: Integer): Variant;
    function UltimaFila: Integer;
    function UltimaColumna: Integer;
  end;
```

La lógica de `ImportarInventarioDesdeSheet` (buscar columnas por cabecera,
fallback A=SKU/B=Cantidad, construir `TLineasImportadas`) es **de negocio** y
se queda en `inLibInventarioExcel`, pero leyendo por el puerto en vez de por
el control.

### 2.3 Helpers puros — unidad neutra

`inLibHojaCalculoUtil.pas` (sin `Tdx*`): `ReferenciaCelda` (`GetRef`),
`ColumnaALetras` (`ColToLetras`), `SeparadorFormula` (`SepFormula`).
Reutilizada por todos los adaptadores y por los exportadores.

### 2.4 Adaptador y factoría

`inLibHojaCalculoDevEx.pas` — **única unidad que ve `Tdx*`**:

```pascal
  TEscritorHojaCalculoDevEx = class(TInterfacedObject,
                                    IEscritorHojaCalculo, ILectorHojaCalculo)
    // envuelve un TdxSpreadSheet; reubica el cuerpo de Merge/W/WFormula/
    // PintarCuadro; mapea TAlineacionCelda/TEstiloBorde -> tipos dx.
  end;

function CrearEscritorDevEx(
  const ASheet: TdxSpreadSheet): IEscritorHojaCalculo;
```

Cableado en los modales: `ExportarXxx(fPreview.dxSpreadSheet1, …)` pasa a
`ExportarXxx(CrearEscritorDevEx(fPreview.dxSpreadSheet1), …)`.

---

## 3. Plan por fases

Cada fase compila y deja el sistema funcionando (sin big-bang). Criterio de
"hecho" explícito por fase.

### Fase 0 — Puerto y helpers (sin tocar exportadores)
- Crear `inLibHojaCalculoIntf` (`IEscritorHojaCalculo`, `ILectorHojaCalculo`,
  tipos `TAlineacionCelda`, `TEstiloBorde`).
- Crear `inLibHojaCalculoUtil` con `ReferenciaCelda`/`ColumnaALetras`/
  `SeparadorFormula` (copiar cuerpos de `GetRef`/`ColToLetras`/`SepFormula`).
- **Hecho cuando**: compila; `inLibDevExcel` sigue intacto y en uso.

### Fase 1 — Adaptador DevExpress
- Crear `inLibHojaCalculoDevEx` con `TEscritorHojaCalculoDevEx` + factoría.
  Reubicar los cuerpos de `Merge/W/WFormula/PintarCuadro` a métodos (mapeando
  `TAlineacionCelda`→`ssah*`, `TEstiloBorde`→`TdxSpreadSheetCellBorderStyle`).
- Mantener `inLibDevExcel` como **shims deprecados** que delegan en el
  adaptador (`{$MESSAGE WARN 'deprecado, usar IEscritorHojaCalculo'}`), para
  no romper los exportadores aún no migrados.
- **Hecho cuando**: el adaptador reproduce 1:1 el comportamiento (verificado
  por las pruebas de la §4.2) y todo sigue compilando.

### Fase 2 — Migrar exportadores (uno a uno)
Por cada exportador, en el orden de la §5:
1. Cambiar la firma: `ASheetControl: TdxSpreadSheet` → `const AEscritor:
   IEscritorHojaCalculo`. Sustituir `W(Sheet,…)`→`AEscritor.Escribir(…)`, etc.
2. Actualizar su(s) call site(s) a `CrearEscritorDevEx(fPreview.dxSpreadSheet1)`.
3. Compilar + prueba de snapshot (§4.3) + revisión visual de 1 documento real.
- **Hecho cuando**: todos los de la tabla §1.1 aceptan el puerto y no
  referencian `Tdx*`.

### Fase 3 — Ruta de importación
- `ImportarInventarioDesdeSheet` pasa a recibir `ILectorHojaCalculo`. El call
  site `inMtoInventarios:3048` usa `CrearEscritorDevEx(Sheet)` (implementa
  ambos puertos) como lector.
- **Hecho cuando**: import por puerto + prueba round-trip (§4.4) en verde.

### Fase 4 — Métodos de formulario y limpieza
- Extraer `ExportarResumen/Vista/OperacionExcel` de `inMtoCajaOperacionesHist`
  y `inLibTiraCajaTicket.ExportarExcel` al puerto.
- Eliminar los shims deprecados. `inLibDevExcel` desaparece o queda como
  alias del adaptador.
- **Hecho cuando**: `grep TdxSpreadSheet` solo aparece en
  `inLibHojaCalculoDevEx`, en `inMtoPreviewExcel` y en los `.dfm`.

### Fase 5 — (opcional) Motor headless XLSX
- `inLibHojaCalculoXlsx` (`TEscritorHojaCalculoXlsx`) que escribe OOXML sin
  UI. Desbloquea export por correo/servidor y actúa como oráculo de las
  pruebas golden-file. Decisión de librería pendiente (ver §6).
- **Hecho cuando**: un exportador corre de punta a punta sin DevExpress.

---

## 4. Estrategia de pruebas

Hoy **no hay framework de tests** en el repo. Se introduce uno mínimo y
**aislado**, sin meterlo en `fzam.dproj` (mismo criterio que `utilnormbbdd`/
`utilmigsqlsrv`: proyecto Delphi independiente).

### 4.1 Infraestructura
- Framework: **DUnitX** (decidido). Se encaja en la convención de carpetas
  del repo: `DESARROLLOS EN CURSO/PruebasHojaCalculoFase<N>/` con un `.dpr`
  de consola compilado por `dcc32`/`dcc64` vía `ejecutar_pruebas.ps1`
  (modelado sobre `PruebasParametrosFase12A`), e `INFORME_PRUEBAS.md`.
  Referencia `src/Lib` por `-U`; no arrastra DevExpress salvo en las pruebas
  del adaptador (Fase 1+).
- Nota de consistencia: las demás carpetas `Pruebas*Fase*` usan un harness
  propio `Comprobar([OK]/[ERROR])` en vez de DUnitX. Si se prefiere unificar,
  el runner se adapta sin tocar la lógica de las pruebas.
- Regla clave: como el control DevExpress no corre cómodo *headless*, el
  **oráculo de las pruebas es el escritor falso**, no el control real.

### 4.2 Doble de prueba — `TEscritorHojaCalculoFalso`
Implementa `IEscritorHojaCalculo` + `ILectorHojaCalculo` y **registra** todo
en memoria: matriz `(fila,col) → (valor, negrita, alineación, formato,
fórmula)`, lista de combinaciones y lista de cuadros. Permite:
- Aserciones directas ("la celda D5 es negrita, alineada a la derecha,
  formato `FMT_EUR`", "hay un merge 1×4 en A1").
- Servir de lector precargado para probar la importación.

### 4.3 Pruebas de regresión por snapshot (characterization-first)
El usuario pidió **pruebas primero**. Para cada exportador:
1. **Antes de migrar**: generar el documento con el código actual y **guardar
   el .xlsx** desde el preview → commit como
   `tests/golden/<exportador>_ref.xlsx` (oráculo de paridad de partida).
2. **Al migrar**: la prueba ejecuta el exportador contra el
   `TEscritorHojaCalculoFalso`, **serializa** la matriz de celdas a un texto
   canónico (CSV/JSON estable) y lo compara con `tests/golden/<exp>_snap.txt`.
3. El primer snapshot se genera y se revisa a mano una vez; a partir de ahí es
   red de seguridad ante cualquier cambio.
4. Comparación adicional del `.xlsx` (fase 5 o script externo con `openpyxl`)
   contra el `_ref.xlsx` para validar formato/fórmulas de verdad.

### 4.4 Prueba round-trip de importación
- Precargar un `TEscritorHojaCalculoFalso` con una hoja conocida (cabeceras
  SKU/Cantidad/PMP + filas), ejecutar `ImportarInventarioDesdeSheet` y afirmar
  el `TLineasImportadas` resultante (incluye el caso sin cabecera → A=SKU,
  B=Cantidad, y el caso con PMP).

### 4.5 Pruebas de los helpers puros
- `ReferenciaCelda`, `ColumnaALetras`, `SeparadorFormula`: tabla de casos
  (col 0→'A', 26→'AA', absoluta `$A$1`; separador ';' con coma decimal).
  Baratas y sin dependencias.

### 4.6 Prueba de paridad del adaptador
- Una única prueba con DevExpress real: escribir un patrón por el
  `TEscritorHojaCalculoDevEx`, guardar a `.xlsx` temporal y comparar con el
  `_ref.xlsx` del mismo patrón. Confirma que el adaptador ≡ código original.

### 4.7 Orden de las pruebas respecto al código
1. §4.5 helpers (Fase 0). 2. §4.2 fake + §4.3 snapshot del **primer**
exportador migrado (Fase 2, junto con la migración). 3. §4.4 round-trip
(Fase 3). 4. §4.6 paridad adaptador (Fase 1/2). El golden `.xlsx` de partida
(§4.3.1) se captura **antes** de tocar cada exportador.

---

## 5. Orden de migración (riesgo ascendente)

1. `inLibMovVentasArtExcel` — 1 call site, sin `Conn`. **Piloto**: valida
   puerto + fake + snapshot end-to-end.
2. `inLibBalanceTallasExcel` y `inLibBalanceSinTallasExcel` — 1 call site c/u.
3. `inLibInventarioExcel` (export) — luego su import en Fase 3.
4. `inLibDocumentosTrabajoExcel` — 1 call site (usa `inLibFotos`; ojo imágenes).
5. `inLibFacturaExcel` — ya recibe `ParametrosApp`; añade el puerto.
6. `inLibDocCompraExcel` (Horizontal/Vertical) — **5 call sites**, el más
   reutilizado: migrar con cuidado y snapshot por cada modal.
7. Métodos de `inMtoCajaOperacionesHist` + `inLibTiraCajaTicket.ExportarExcel`.

---

## 6. Riesgos y decisiones abiertas

- **Imágenes de celda** (`dxSmartImage`/logos en factura y documentos de
  trabajo): no están en el puerto mínimo. Decisión: añadir
  `procedure InsertarImagen(...)` al puerto **o** dejar un "escape hatch"
  `function ControlNativo: TObject` para esos pocos casos. Recomendado: escape
  hatch al principio, método formal si se generaliza.
- **`SeparadorFormula` depende de locale**: mantener el comentario de negocio
  (coma decimal ⇒ separador ';') tal cual está; es un bug sutil ya resuelto.
- **Alineación vertical**: hoy `W` fuerza `ssavCenter`. El puerto lo mantiene
  fijo salvo que aparezca necesidad; no exponerlo aún (YAGNI).
- **Motor headless (Fase 5)**: ¿librería OOXML (p.ej. generación propia mínima
  o componente existente) o diferirlo? No bloquea las fases 0-4. **Pendiente
  de tu decisión.**
- **Framework de test**: DUnitX (DECIDIDO). Las demás carpetas `Pruebas*`
  usan un harness propio; queda pendiente decidir si se unifican a futuro.

---

## 7. Arranque tangible (primeras 2 fases)

1. `src/Lib/inLibHojaCalculoIntf.pas` — puertos + tipos neutros.
2. `src/Lib/inLibHojaCalculoUtil.pas` — 3 helpers puros + sus pruebas.
3. `src/Lib/inLibHojaCalculoDevEx.pas` — adaptador + factoría; `inLibDevExcel`
   pasa a shims deprecados.
4. `tests/fzamTests.dproj` — DUnitX + `TEscritorHojaCalculoFalso` + pruebas de
   helpers.
5. Migrar `inLibMovVentasArtExcel` como piloto con snapshot.
```
```

Todo en español, ≤80 columnas, `FreeAndNil`, campos antes que métodos por
sección (E2169), `inherited;` en su línea.
