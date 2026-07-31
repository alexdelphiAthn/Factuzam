# Fase 3, fascículo F3-1 — `inMtoCajaOpe`: cliente → cabecera de venta

Fecha: 31/07/2026. Sin commit.

**Estado: COMPILACIÓN Y DUNITX SUPERADOS. Trinquetes globales y prueba
funcional pendientes.** La aplicación y `FactuzamTests` compilan en
Release Win32 y Win64. La batería global pasa 500/500 en ambas
plataformas e incluye los 12 casos del foco, `PruebasCajaVenta`,
`PruebasEmisionFiscal` y `PruebasRectificativas` (PLAN_SOLID.md §7,
regla 7).

**Contexto:** `TfrmMtoOpeCaja` incumple el trinquete desde los commits
DIP del 30/07 (`180d09c4`/`95ecd9da`, +418/−63 dentro de cuerpos
existentes): medía **4.321/111** frente al tope congelado 4.060/104.
Este fascículo la baja a **4.186** y es el primero de una serie: no
basta por sí solo para reverdecer el trinquete.

---

## 1. Qué se ha extraído

`btnCodigoClientePropertiesValidate` tenía **232 líneas** (el método
más grande de la clase) y mezclaba el grid, las etiquetas y cuatro
bloques de reglas. Este fascículo saca **una** responsabilidad: el
cambio de cliente de la venta.

Nueva unidad `src\Caja\Lib\inLibCajaVentaCliente.pas`, sin
formularios, sin DevExpress, sin UniDAC y sin SQL:

| Función | Regla que fija |
|---|---|
| `EsLineaDeposito` | `VIENE_DE_DEPOSITO` ∈ {`S`, `A`} |
| `LimpiarLineasDeposito` | cierre de la línea pendiente + borrado de depósitos |
| `EscribirCabeceraVentaContado` | reset de 15 campos, tarifa por defecto, imp. incluidos |
| `EscribirCabeceraClienteVenta` | volcado de `TClienteCaja` (20 campos) |
| `DebeCargarDepositosCliente` | permite deuda (sin mayúsculas) + parámetro autocarga |

Trabaja sobre `TDataSet` y el record `TClienteCaja` de
`inLibCajaVentaIntf` (ya presente en el proyecto de pruebas), así que
no arrastra dependencias nuevas.

Reglas que estaban enterradas en la VCL y ahora son explícitas y
probadas:

1. **La línea pendiente se cierra según su contenido**: la inserción
   sin artículo se cancela (evita el `Abort` de `BeforePost`); la que
   tiene artículo se graba.
2. **Solo `S` y `A` son líneas de depósito.** La misma regla protege
   el borrado por atajo: `WMCancelarLinea` ahora consume
   `EsLineaDeposito` en vez de su copia local.
3. **La forma de pago del cliente solo pisa la de la cabecera si viene
   informada** (blancos incluidos: se comprueba con `Trim`).
4. **Los depósitos solo se cargan solos** si el cliente permite deuda
   (`SameText`) **y** el parámetro `vgerAutoLoadDepositos` está activo.

Diferencia consciente y sin efecto observable: el original abría
`BeginUpdate`/`FActualizandoDepositos` cuando el cliente permitía
deuda aunque la autocarga estuviera apagada (par vacío sin efecto); la
versión nueva solo envuelve la carga real.

## 2. Qué se queda en el formulario

Las guardas de reentrada (`FProcesandoLecturaScanner`,
`FValidandoCliente`), la búsqueda vía `FRepositorioConsultas`, las
etiquetas (`lblNombreCliente`, `lblTarifa`), el foco, la señalización
de error del editor y el recálculo de totales. La coordinación no se
mueve (PLAN_SOLID.md §4, método por formulario, punto 4).

En el método reescrito desaparecen los dos `Exit` del flujo original
(LIBRO_DE_ESTILO_DELPHI.md §8.1); el comportamiento no cambia.

## 3. Medición

| Objetivo | Antes | Después |
|---|---:|---:|
| `TfrmMtoOpeCaja` — líneas | 4.321 | **4.186** |
| `TfrmMtoOpeCaja` — métodos | 111 | 111 |
| `btnCodigoClientePropertiesValidate` — líneas | 232 | 97 |

El tope del trinquete (4.060/104) **no se toca**: sigue incumplido y
solo puede bajar. Faltan ~126 líneas y 7 métodos para reverdecerlo.

Revalidación del 31/07/2026 sobre el árbol compartido: el script mide
**4.187/111/40**. La línea adicional respecto a la tabla procede de la
migración concurrente de perfiles de usuario; no pertenece a esta
extracción. El incumplimiento esperado sigue siendo 4.187 líneas frente
al tope 4.060.

### 3.1 Hoja de ruta para reverdecer el trinquete

- **F3-2**: `cxGrid1DBTableView1EditKeyDown` (154 líneas) o
  `btnF12Click` (130): siguiente extracción de reglas (~100 líneas).
- **F3-3**: mover helpers privados **enteros** que no tocan controles
  (candidatos: `HayLineasNegativas`, parte de la cadena de atributos
  `RegistrarValorAtributo`/`FinalizarUltimoAtributo`) para recortar
  los 7 métodos sobrantes.

## 4. Pruebas

`tests\PruebasCajaVentaCliente.pas`, **12 casos**, sin BBDD y sin VCL:

- regla de depósito: solo `S` y `A` (sensible a mayúsculas, como el
  original);
- limpieza: borra depósitos y conserva el resto, cancela la inserción
  vacía, graba la inserción con artículo, graba la edición pendiente,
  `nil`/inactivo no hace nada;
- contado: vacía los datos del cliente, tarifa por defecto e impuestos
  incluidos;
- cliente: volcado completo, forma de pago vacía no pisa / informada
  sí pisa;
- depósitos: solo con permite deuda (`SameText`) y autocarga.

### 4.1 Resultados ejecutados el 31/07/2026

| Validación | Win32 Release | Win64 Release |
|---|---:|---:|
| Rebuild `fzam.dproj` | 0 errores, 355.920 líneas | 0 errores, 355.920 líneas |
| Rebuild `FactuzamTests.dproj` | 0 errores | 0 errores |
| Batería global DUnitX | **500/500** | **500/500** |
| Ignoradas / fallidas / errores / fugas | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| `PruebasCajaVentaCliente` | **12/12** | **12/12** |
| Suites fiscales exigidas | incluidas, correctas | incluidas, correctas |

Los builds de pruebas muestran siete avisos H2443 en
`UniDataComprasSesionesRepositorio`; la aplicación añade otro H2443 en
`inLibModoTallasPresentacion`. Son unidades ajenas a este fascículo y no
hay errores de compilación.

Trinquetes estructurales:

- correctos: estado global, SQL en dominio, dependencias de capas,
  `Supports` y SQL/transacciones;
- fallo esperado: tamaño de `TfrmMtoOpeCaja`, 4.187 líneas frente al
  tope 4.060;
- bloqueos concurrentes ajenos al foco: fan-in máximo 85 frente a 84,
  `comprobar_flujos_largos.ps1` aún busca
  `GuardarRegistroNoVerifactu` y
  `comprobar_formularios_delgados.ps1` aún busca
  `MostrarSkuArticulo` en su ubicación anterior.

## 5. Ficheros

**Nuevos (2):** `src\Caja\Lib\inLibCajaVentaCliente.pas`,
`tests\PruebasCajaVentaCliente.pas`.

**Modificados (5):** `src\Caja\Forms\inMtoCajaOpe.pas` (método
reescrito + dedup en `WMCancelarLinea` + `uses`), `fzam.dpr`,
`fzam.dproj`, `tests\FactuzamTests.dpr`. El trinquete no cambia.

Los ficheros compartidos con el hilo concurrente se editaron **in situ
sobre la versión del disco** con inserciones ancladas a líneas únicas.

## 6. Qué falta para cerrar

1. ~~Release Win32 y Win64.~~ Superado.
2. ~~`FactuzamTests.exe`: 12/12 del foco, batería global y, por zona
   fiscal, `PruebasCajaVenta`, `PruebasEmisionFiscal` y
   `PruebasRectificativas` en ambas plataformas.~~ Superado: 500/500.
3. Resolver los tres bloqueos concurrentes de trinquetes indicados en
   §4.1 antes de exigir una batería estructural completamente verde.
4. Commit.
5. Prueba funcional del cambio de cliente en caja, donde vive el
   riesgo real:
   - venta con líneas de depósito de un cliente → cambiar a otro
     cliente → los depósitos desaparecen y las líneas normales quedan;
   - cambiar a cliente vacío → venta al contado, tarifa por defecto y
     etiqueta actualizada;
   - cliente inexistente → error en el editor, sin tocar la cabecera;
   - cliente con forma de pago propia → la pisa; sin ella → conserva
     la de la cabecera;
   - cliente con deuda permitida y `vgerAutoLoadDepositos` activo →
     carga automática; con el parámetro apagado → no carga;
   - borrado por atajo de una línea de depósito → sigue bloqueado con
     su aviso;
   - lectura de escáner con texto a medias en el campo cliente → no
     valida ni molesta (guarda de ráfaga intacta).

Riesgo: el pegamento del grid y las guardas de reentrada no se pueden
probar sin VCL. Lo extraído está cubierto; el flujo completo depende
de la prueba funcional.
