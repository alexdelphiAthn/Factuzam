# Fase 3, fascículos F3-2 y F3-3 — `inMtoCajaOpe`: cierre y helpers

Fecha: 31/07/2026. Sin commit. Continúa el F3-1
(`refactorizacion_fase3_f3_opecaja_resultados.md`).

**Estado de la verificación automática: COMPLETADA.** La aplicación y
`FactuzamTests` compilan en Release Win32 y Win64. La batería global
pasa 524/524 en ambas plataformas e incluye los 24 casos nuevos, los
12 del F3-1 y las suites fiscales `PruebasCajaVenta`,
`PruebasEmisionFiscal` y `PruebasRectificativas` (PLAN_SOLID.md §7,
regla 7). Queda la prueba funcional.

**Resultado clave: `TfrmMtoOpeCaja` queda en 3.981 / 104: las líneas
bajan respecto al tope congelado 4.060 y los métodos cumplen
exactamente el tope 104.** El tope de líneas baja a 3.981.

---

## 1. Qué se ha hecho

### F3-2 — reglas del cierre (`btnF12Click`, 130 → 97 líneas)

Nueva unidad `src\Caja\Lib\inLibCajaVentaOperacion.pas`, sin
formularios, sin DevExpress, sin UniDAC y sin SQL. Del cierre extrae:

- `CerrarLineaPendiente`: la inserción sin artículo se cancela; la que
  tiene artículo, y cualquier edición, se graban.
- `ResolverDocumentoCierreVenta`: factura completa → serie de factura,
  tipo `NORMAL` y su fecha; si no, serie simplificada; y la devolución
  con ticket rectificado que no acaba en factura → `RECTIFICATIVA`
  (conservando la serie simplificada). Regla fiscal que vivía en tres
  `if` encadenados con variables sueltas.

### F3-3 — siete métodos menos en la clase (111 → 104)

Cinco helpers que no tocaban ningún control se mueven **enteros** a la
misma unidad, con el dataset (y el lookup de atributos, por contrato)
como parámetros. La lógica del sexto, `OperacionVacia`, también pasa a
dominio, pero la compilación limpia detectó que el formulario debe
conservar el adaptador exigido por `IOperacionCaja`:

| Antes | Ahora |
|---|---|
| `HayLineasNegativas` | `HayLineasNegativasVenta` |
| `HayLineasConDeposito` | `HayLineasDepositoVenta` |
| `OperacionVacia` | Adaptador a `OperacionVentaVacia` |
| `SincronizarFechaCajaCabecera` | `EscribirFechaCabeceraVenta` |
| `EliminarLineaPorValidacion` | `EliminarLineaVentaPorValidacion` |
| `CargarAvsValidos` | `CargarAvsValidosArticulo` |

`LimpiarEstadoDevolucion` (un único punto de llamada) se
integra en línea en `ProcesarResultadoCierre` con un comentario que
conserva el paso con nombre.

Para mantener el descenso neto de siete métodos sin romper el contrato,
la acción de teclado F12 se conecta directamente a `btnF12Click`. Se
elimina así `actCobroExecute`, que solo reenviaba la llamada con la
misma firma y sin añadir comportamiento.

`RellenarAtributosDesdeSku` **no** desaparece: es el callback de
`DatosCaja.OnRellenarAtributos`, así que queda como pegamento de cinco
líneas que delega en `RellenarAtributosLineaDesdeSku` inyectando el
lookup (§14.1); la lógica sí es ahora de dominio y está probada.

Las funciones movidas consumen `EsLineaDeposito` de
`inLibCajaVentaCliente` (dependencia en una sola dirección:
Operación → Cliente), de modo que la regla `S`/`A` sigue viviendo en
un único sitio. `PoblarAtributosLineasDeposito` se queda en el
formulario: contiene SQL literal y una unit `inLib*` nueva no puede
llevarlo (Fase 2); su salida es un contrato en `UniData*`, otro día.

## 2. Medición

| Objetivo | F3-1 | Tras F3-2/F3-3 |
|---|---:|---:|
| `TfrmMtoOpeCaja` — líneas | 4.186 | **3.981** |
| `TfrmMtoOpeCaja` — métodos | 111 | **104** |
| `btnF12Click` — líneas | 130 | 97 |

El tope de `comprobar_tamano_clases.ps1` baja de 4.060 a **3.981**;
el de métodos se queda en 104, ahora exactamente cumplido.

## 3. Pruebas

`tests\PruebasCajaVentaOperacion.pas`, **24 casos**, sin BBDD y sin
VCL, con `TClientDataSet` y un `TLookupAtributosFalso` en memoria que
implementa `IArticulosAtributosLookup`:

- línea pendiente: inserción vacía / con artículo / edición / reposo;
- rechazo por validación: inserción, edición (cancela y borra), `nil`;
- devoluciones: negativa normal, depósitos ignorados incluso con
  relleno (la comparación original lleva `Trim`), todo positivo;
- depósitos: prenda y abono, sin depósitos;
- operación vacía: cancela la inserción y mira; con líneas no;
- fecha de cabecera: en reposo edita y graba; en edición escribe sin
  grabar;
- atributos: escribe `ATTR1..5` por orden, orden fuera de rango se
  ignora, SKU vacío no toca la línea;
- AVs: valores del lookup, artículo vacío u orden inválido → vacío;
- documento del cierre: factura completa, simplificada, rectificativa.

### 3.1 Resultados ejecutados el 31/07/2026

| Validación | Win32 Release | Win64 Release |
|---|---:|---:|
| Rebuild `fzam.dproj` | 0 errores | 0 errores |
| Rebuild `FactuzamTests.dproj` | 0 errores | 0 errores |
| Batería global DUnitX | **524/524** | **524/524** |
| Ignoradas / fallidas / errores / fugas | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| `PruebasCajaVentaOperacion` | **24/24** | **24/24** |
| `PruebasCajaVentaCliente` | **12/12** | **12/12** |
| Suites fiscales exigidas | **17/17** | **17/17** |

La primera recompilación limpia encontró el error E2291:
`TfrmMtoOpeCaja` ya no implementaba `IOperacionCaja.OperacionVacia`.
Se restauró el adaptador que delega en la función de dominio y se
eliminó el wrapper redundante de la acción F12. Las recompilaciones
posteriores de las dos plataformas quedaron correctas.

Los builds de pruebas muestran siete avisos H2443 ya existentes en
`UniDataComprasSesionesRepositorio`; la aplicación añade otro H2443 en
`inLibModoTallasPresentacion`. No hay errores de compilación.

El trinquete confirma **3.981 líneas / 104 métodos** para
`TfrmMtoOpeCaja`. El script global aún termina con código 1 por un
crecimiento concurrente ajeno a esta tanda:
`UniDataAlbaranesCompraMovimientos` tiene 672 líneas frente a su tope
657. No se ha modificado esa unidad.

## 4. Coordinación con los hilos concurrentes

Mientras se preparaba la tanda, un barrido concurrente tocó decenas de
formularios (05:03–05:22), `inMtoCajaOpe.pas` incluido (+117 bytes), y
`FactuzamTests.dpr` estuvo bloqueado unos instantes. Siguiendo la
consigna de esperar, la tanda se aplicó después **directamente sobre
la versión viva del disco** como una serie de sustituciones ancladas
todo-o-nada: cada bloque borrado se verificó contra su tamaño esperado
antes de escribir, así que el cambio del barrido quedó intacto. El
trinquete había sido regenerado con finales LF por el otro hilo; la
bajada de tope se aplicó respetando ese formato.

## 5. Ficheros

**Nuevos (2):** `src\Caja\Lib\inLibCajaVentaOperacion.pas`,
`tests\PruebasCajaVentaOperacion.pas`.

**Modificados (6):** `src\Caja\Forms\inMtoCajaOpe.pas` (editado in
situ), `src\Caja\Forms\inMtoCajaOpe.dfm`, `fzam.dpr`, `fzam.dproj`,
`tests\FactuzamTests.dpr`, `scripts\comprobar_tamano_clases.ps1`
(tope 4.060 → 3.981).

## 6. Qué falta para cerrar

1. Resolver el crecimiento concurrente de
   `UniDataAlbaranesCompraMovimientos` para que el trinquete global
   vuelva a verde; el objetivo propio 3.981/104 está cumplido.
2. Commit (F3-1 y esta tanda pueden ir en commits separados: cliente /
   cierre+helpers).
3. Prueba funcional, añadida a la del F3-1:
   - F12 con línea a medio meter → se cierra igual que antes;
   - cobro como factura completa → serie de factura, tipo NORMAL y
     fecha elegida;
   - ticket simplificado normal → serie del combo, sin fecha;
   - devolución de ticket rectificado cobrada como ticket →
     RECTIFICATIVA;
   - devolución en negativo → sigue pidiendo motivo antes del cobro;
   - depósitos cargados → el aviso de líneas de depósito llega igual a
     la fase de cobro;
   - escaneo de SKU con atributos → Color/Talla se rellenan como antes.
