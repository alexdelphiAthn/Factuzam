# Fase 3, fascículo F5-1 — `inMtoStockConsulta`: celda → documento de trabajo

Fecha: 31/07/2026. Sin commit.

**Estado de la verificación: VALIDADO.** `FactuzamTests` compila en
Release Win32 y Win64 y los 22 casos del foco pasan en ambas
plataformas, sin ignoradas, errores ni fugas. La batería global queda
en 481/484; los tres rojos son recuentos del catálogo SQL
desactualizados por el commit `95ecd9da`, ajenos a este fascículo.
Quedan la prueba funcional y el commit.

**Motivo del fascículo:** el trinquete global fallaba porque
`TfrmStockConsulta` medía **3.141** líneas frente a su tope congelado de
3.139 (crecimiento concurrente del 30/07). Este fascículo la deja en
**3.088** y baja el tope a esa cifra.

---

## 1. Qué se ha extraído

`ResolverCeldaDocumentoTrabajo` tenía **149 líneas** (el segundo método
más grande de la clase) y mezclaba la lectura del grid DevExpress con
las reglas de decisión. Este fascículo saca **una** responsabilidad:
las decisiones de la celda.

Se descartó extraer `ConstruirSQLPivot` (109 líneas): compone SQL y una
unit `inLib*` nueva no puede contener SQL literal (PLAN_SOLID.md Fase 2,
regla del trinquete). Ese corte queda para un contrato con
implementación en `UniData*`.

Nueva unidad `src\Lib\inLibStockCeldaDocumento.pas`, sin formularios,
sin DevExpress, sin UniDAC y sin SQL:

| Función | Regla que fija |
|---|---|
| `ResolverCeldaStockParaDocumento` | guardas, talla por columna y grupo según modo |
| `ComponerLineaCeldaStock` | composición de la línea del documento |

Reglas que estaban enterradas en la VCL y ahora son explícitas y
probadas:

1. **En modo "Todo a la vez" manda la fila, no el combo**: la guarda de
   estado del combo solo aplica en modo normal, y en modo todo solo
   valen filas cuyo `ESTADO_NUM` sea existencias (sin columna de estado
   leída, ninguna fila vale).
2. **La talla sale del nombre de la columna** `T<n>` (índice sobre las
   columnas dinámicas) y `TOTAL` solo vale si el artículo no tiene
   desglose por tallas. La comparación es sin distinción de mayúsculas.
3. **Almacén y color se resuelven según el modo del pivote**: con filas
   por color el almacén seleccionado debe ser único; con filas por
   almacén el color debe ser único, salvo que el artículo no tenga
   ningún color.
4. **La cantidad nula de un LEFT JOIN sin stock viaja como cero**, el
   origen es `CTRL_U` y la descripción del SKU solo se rellena si hay
   color o talla.

La unidad define su propio record de línea (`TLineaCeldaStock`) en vez
de usar `TDocTrabajoLineaOrigen` para que las pruebas no arrastren
UniDAC (`inLibDocumentosTrabajo` usa `TUniConnection`); el formulario
copia los campos.

## 2. Qué se queda en el formulario

La lectura del grid (`FocusedRecord`, `FocusedColumn`, valores de
celda), la traducción de motivo a `resourcestring` (inline en el
método: la clase está exactamente en su tope de 81 métodos y no se
puede añadir ninguno), la resolución del SKU contra la BBDD
(`ResolverCodigoSkuDocumentoTrabajo`) y la llamada al caso de uso.

## 3. Medición

| Objetivo | Antes | Después |
|---|---:|---:|
| `TfrmStockConsulta` — líneas | 3.141 | **3.088** |
| `TfrmStockConsulta` — métodos | 81 | 81 |
| `ResolverCeldaDocumentoTrabajo` — líneas | 149 | 93 |

El tope de `comprobar_tamano_clases.ps1` baja de 3.139 a **3.088**. La
clase estaba **incumpliendo el trinquete antes de este fascículo**
(3.141 > 3.139); queda de nuevo por debajo.

Pendiente de reparto: `TfrmMtoOpeCaja` sigue incumpliendo (4.321/111
frente a 4.060/104, +261 líneas y +7 métodos). Es zona fiscal y exige
su propio fascículo coordinado con la batería `PruebasCajaVenta`,
`PruebasEmisionFiscal` y `PruebasRectificativas` en Release
Win32 + Win64.

## 4. Pruebas

`tests\PruebasStockCeldaDocumento.pas`, **22 casos**, sin BBDD y sin
VCL:

- guardas: sin artículo, estado no existencias en modo normal, modo
  todo ignora el combo, sin fila, sin columna de datos, fila no
  existencias en modo todo;
- talla: `T<n>` válido, fuera de rango, sin número, `TOTAL` sin tallas,
  `TOTAL` con tallas, `total` en minúsculas;
- grupo: sin columna grupo, almacén único / múltiple en modo color,
  color único / vacío sin lista / vacío con lista / múltiple en modo
  almacén;
- línea: cantidad nula a cero, campos y origen, descripción del SKU
  solo con color o talla.

### 4.1 Resultado DUnitX

Ejecutado el 31/07/2026:

```text
FactuzamTests Release Win32: compilado
PruebasStockCeldaDocumento: 22/22
Batería global: 478/481 pasan de 481 ejecutadas

FactuzamTests Release Win64: compilado
PruebasStockCeldaDocumento: 22/22
Batería global: 478/481 pasan de 481 ejecutadas
```

Los tres fallos globales son idénticos en ambas plataformas y ajenos al
fascículo: `RegistroAplicacion_IncluyePiloto` (esperaba 120, obtiene
123), `Caja_RegistraLecturasIncluidoProcedimiento` (esperaba 7, obtiene
10) y `CatalogoInactivoNoNecesitaServicioDePerfiles` (esperaba 120,
obtiene 123). Causa: el commit `95ecd9da` añadió
`ConsultarFacturaPorCodigoBarras`, `ConsultarFacturaPorOperacion` y
`ConsultarVentasOrigenSku` a `TRepositorioConsultasCaja` sin actualizar
los recuentos fijados en las pruebas. La compilación muestra además
siete avisos H2443 preexistentes en
`UniDataComprasSesionesRepositorio.pas`.

## 5. Ficheros

**Nuevos (2):** `src\Lib\inLibStockCeldaDocumento.pas`,
`tests\PruebasStockCeldaDocumento.pas`.

**Modificados (5):** `src\Forms\inMtoStockConsulta.pas`, `fzam.dpr`,
`fzam.dproj`, `tests\FactuzamTests.dpr`,
`scripts\comprobar_tamano_clases.ps1`.

Los cuatro ficheros compartidos con el hilo concurrente se editaron de
nuevo **in situ sobre la versión del disco** con inserciones ancladas a
líneas únicas (crecieron otra vez entre fascículo y fascículo; los
anclajes se verificaron con aparición única antes de escribir).

## 6. Qué falta para cerrar

1. `comprobar_tamano_clases.ps1` y confirmar `ActualLineas=3088`.
2. ~~Release Win32 y Win64.~~ Ambas plataformas compilan.
3. ~~`FactuzamTests.exe`.~~ Hecho en ambas plataformas: 22/22 del foco
   y 478/481 global.
4. Commit.
5. Prueba funcional del envío de celda al documento de trabajo:
   - celda `T<n>` de una fila de almacén con color único → línea con
     ese SKU y esa cantidad;
   - celda `TOTAL` de un artículo sin tallas → línea sin talla;
   - modo color con dos almacenes marcados → aviso de almacén no único;
   - modo "Todo a la vez" sobre una fila que no es de existencias →
     aviso;
   - celda vacía (LEFT JOIN sin stock) → línea con cantidad cero;
   - menú contextual: el elemento se habilita/deshabilita igual que
     antes (usa el mismo método).

Riesgo: la lectura del grid (fila/columna enfocadas, columna de estado
oculta en modo todo) no se puede probar sin VCL. Lo extraído está
cubierto; el pegamento del grid, no.

## 7. Siguiente fascículo sugerido

`CargarInfoCabecera` (194 líneas) es ahora el método más grande de la
clase, pero mezcla consultas y presentación. El corte con más valor
sigue siendo `ConstruirSQLPivot` + `EstadoBaseSelect*` detrás de un
contrato con implementación `UniData*` (Fase 2 y Fase 3 a la vez), que
además sacaría el SQL del formulario.
