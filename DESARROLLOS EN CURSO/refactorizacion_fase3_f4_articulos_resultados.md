# Fase 3, fascículo F4-1 — `inMtoArticulos`: alta de tarifas por SKU

Fecha: 31/07/2026. Sin commit.

**Estado de la verificación: AUTOMÁTICA COMPLETADA.** Release Win32 y
Win64 compilan, y las 22 pruebas del foco pasan en ambas plataformas.
Quedan la prueba funcional del modal y el commit. El trinquete confirma
la medida de `TfrmMtoArticulos`, aunque su ejecución global falla por
límites ajenos a este fascículo.

---

## 1. Qué se ha extraído

`btnAddSKUClick` tenía **193 líneas** (el método más grande de la
clase) y mezclaba dos SQL, un modal y las reglas del alta masiva de
precios de tarifa. Este fascículo saca **una** responsabilidad: las
decisiones del alta.

Nueva unidad `src\Lib\inLibArticulosAltaTarifas.pas`, sin formularios,
sin DevExpress, sin UniDAC y sin SQL:

| Función | Regla que fija |
|---|---|
| `VigenciasSeSolapan` | solapamiento con límites inclusivos y extremos abiertos |
| `LlaveOcupacionTarifa` | llave `sku\|tarifa`; la fila del artículo usa sku vacío |
| `CalcularCombinacionesAltaTarifas` | expansión skus × tarifas menos ocupadas y duplicados |
| `ComponerFilaNuevaTarifa` | herencia del precio del padre y activación |
| `LeerFilasTarifaExistentes` | dataset de tarifas → records |
| `EscribirFilaNuevaTarifa` | record → fila nueva del dataset |

Las dos últimas conocen `TDataSet` —igual que
`inLibComprasSesionesCreacion`— pero no UniDAC ni el formulario, y se
prueban con un `TClientDataSet`.

Cuatro reglas que estaban enterradas en la VCL y ahora son explícitas y
probadas:

1. **El solapamiento de vigencias es inclusivo por ambos lados** y un
   extremo sin "hasta" es abierto: coincidir un solo día ya ocupa la
   combinación. Vivía en las variables `Cond1`/`Cond2`.
2. **La fila del propio artículo viaja con SKU vacío**: el elemento
   `ARTÍCULO` del modal se traduce a `CODIGO_UNIDAD_ARTTAR = ''`, y su
   llave de ocupación es `|tarifa`.
3. **Los duplicados de la propia selección se crean una sola vez**: cada
   llave aceptada pasa a ocupar de inmediato.
4. **Solo la fila de SKU hereda el precio del padre** y solo queda
   `ESACTIVO_ARTTAR = 'S'` si ese precio es mayor que cero; la fila del
   artículo nace a cero e inactiva aunque haya precio padre.

## 2. Qué se queda en el formulario

El modal, las dos consultas de carga (SKUs del artículo y tarifas
activas), el bookmark del dataset, `DisableControls`/`EnableControls`,
el `Refresh` y la visibilidad de la columna SKU. La coordinación no se
mueve (PLAN_SOLID.md §4, método por formulario, punto 4). Los dos SQL
literales del formulario quedan como estaban: moverlos es asunto de la
Fase 2, no de este fascículo.

En el método reescrito desaparecen el `Exit` y el `Continue` del flujo
original (LIBRO_DE_ESTILO_DELPHI.md §8.1); el comportamiento no cambia.

## 3. Medición

| Objetivo | Antes | Después |
|---|---:|---:|
| `TfrmMtoArticulos` — líneas | 3.406 | **3.344** |
| `TfrmMtoArticulos` — métodos | 97 | 97 |
| `btnAddSKUClick` — líneas | 193 | **131** |

El tope de `comprobar_tamano_clases.ps1` baja de 3.406 a **3.344**.

### 3.1 Resultado del trinquete

Ejecutado el 31/07/2026 con PowerShell 7. La medida específica coincide
con el tope nuevo: `TfrmMtoArticulos` = **3.344 líneas / 97 métodos**.

La ejecución global termina con código 1 por límites ajenos a F4:

- `TfrmMtoOpeCaja`: 4.321 líneas frente al tope 4.060 y 111 métodos
  frente al tope 104;
- `TfrmStockConsulta`: 3.141 líneas frente al tope 3.139;
- el máximo global queda en 4.321 líneas frente al máximo 4.075.

`TfrmMtoFacturasBase` mide **3.860 líneas / 128 métodos** y sí coincide
con su tope actual.

## 4. Pruebas

`tests\PruebasArticulosAltaTarifas.pas`, **22 casos**, sin BBDD y sin
VCL:

- solapamiento: cerradas cruzadas, disjuntas, contiguas en el mismo
  día, nueva abierta hacia el futuro, nueva abierta que no alcanza el
  pasado, existente abierta según su arranque, ambas abiertas;
- llave: fila de artículo con sku vacío, sku|tarifa;
- combinaciones: expansión completa en orden, bloqueo por solapada,
  no bloqueo sin solape, duplicados de la selección, fila de artículo
  existente bloquea al artículo;
- fila nueva: artículo a cero e inactiva, SKU hereda y se activa, SKU
  sin precio queda inactiva, conservación de la vigencia;
- dataset: `nil` devuelve vacío, lectura con y sin `FECHA_HASTA`,
  escritura completa de SKU, escritura de artículo con hasta nula.

### 4.1 Resultado automático

Ejecutado el 31/07/2026 con Delphi 37.0:

```text
fzam Release Win32: compilado, 0 errores
fzam Release Win64: compilado, 0 errores

FactuzamTests Release Win32: compilado
PruebasArticulosAltaTarifas: 22/22
Batería global: 438/441, 3 fallos, 0 errores, 0 ignoradas y 0 fugas

FactuzamTests Release Win64: compilado
PruebasArticulosAltaTarifas: 22/22
Batería global: 438/441, 3 fallos, 0 errores, 0 ignoradas y 0 fugas
```

Las 22 pruebas de `TPruebasArticulosAltaTarifas` no figuran entre los
fallos notificados por DUnitX. Los tres fallos globales son idénticos en
ambas plataformas y ajenos al fascículo:

- `RegistroAplicacion_IncluyePiloto`: esperaba 120 registros y obtiene
  123;
- `Caja_RegistraLecturasIncluidoProcedimiento`: esperaba 7 lecturas y
  obtiene 10;
- `CatalogoInactivoNoNecesitaServicioDePerfiles`: esperaba 120
  registros y obtiene 123.

## 5. Ficheros

**Nuevos (2):** `src\Lib\inLibArticulosAltaTarifas.pas`,
`tests\PruebasArticulosAltaTarifas.pas`.

**Modificados (5):** `src\Forms\inMtoArticulos.pas`, `fzam.dpr`,
`fzam.dproj`, `tests\FactuzamTests.dpr`,
`scripts\comprobar_tamano_clases.ps1`.

Los cuatro ficheros compartidos con el hilo concurrente (`fzam.dpr`,
`fzam.dproj`, `tests\FactuzamTests.dpr` y el script del trinquete) se
editaron **in situ sobre la versión del disco** con inserciones
ancladas a líneas únicas, sin sobrescribir el fichero completo, para no
pisar los cambios del fascículo F2 en curso.

## 6. Qué falta para cerrar

1. ~~Confirmar `ActualLineas=3344`.~~ Confirmado. El trinquete global
   sigue fallando por límites ajenos indicados en §3.1.
2. ~~Release Win32 y Win64.~~ Ambas plataformas compilan.
3. ~~`FactuzamTests.exe`.~~ Hecho en ambas plataformas: 22/22 del foco
   y 438/441 global; los tres fallos son ajenos y preexistentes.
4. Commit.
5. Prueba funcional del alta, que es donde vive el riesgo real:
   - selección con combinaciones ya vigentes en fechas solapadas → no
     se duplican;
   - misma combinación con vigencia disjunta → sí se crea;
   - fila `ARTÍCULO` → se crea con SKU vacío, precio 0 e inactiva;
   - SKU con precio del padre en la tarifa → hereda y nace activa;
   - fecha hasta vacía en el modal → `FECHA_HASTA_ARTTAR` nula;
   - cancelar el modal → no se escribe nada.

Riesgo: el flujo completo pasa por el modal `AddPreciosTar` y no se
puede probar sin VCL. Lo extraído está cubierto; el pegamento que queda
en el formulario, no.

## 7. Siguiente fascículo sugerido

El siguiente corte natural de `inMtoArticulos` es el helper de
atributos básicos del SKU
(`tvSkuAtributosBasicosID_ATB_AVPropertiesValidate`, 125 líneas):
composición del código por ámbito (global / ad-hoc `AD_<art>_`,
truncado a 100) y prioridad del match por código sobre nombre. Después,
`OnAfterScrollArticulos` (123) y `AsegurarBasicoFilaActual` (121).
