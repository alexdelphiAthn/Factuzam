# Fase 4 — ISP e inyección explícita

Fecha: 31/07/2026. Sin commit.

**Estado: implementada.** El trinquete de `Supports()` queda en 0 fuera
de lista blanca y los cuatro contratos grandes se han segregado por
consumidor real.

## 1. Inyección y `Supports`

- `ShowMto` resuelve `IMantenimientoEmbebido` una vez al crear el
  formulario. `TEmbeddedFormManager` conserva el contrato junto a la
  instancia y lo reutiliza al cerrar o reactivar la pantalla.
- `IMantenimientoEmbebido` hereda de `IVentanaEmbebida`; el
  mantenimiento publica un único contrato explícito.
- `TfrmMtoModalGenImpEle` recibe `IEliminadorFormatoImpresion` por
  constructor. El botón de borrado ya no inspecciona al propietario.
- `scripts\comprobar_supports.ps1` baja su tope de 5 a 0.

Resultado:

```text
Supports: OK. Fuera de lista blanca: 0 (tope 0).
```

## 2. Contratos segregados

| Contrato anterior | Contratos por consumidor |
|---|---|
| `IEscritorHojaCalculo` (14 métodos) | `IEscritorHojaCalculo` (7), `IFormateadorHojaCalculo` (8), `IGuardadorHojaCalculo` (1) |
| `IModoEntradaGrid` (12 métodos + 4 propiedades) | ciclo de vida de 3 métodos; los callbacks se inyectan en `Construir` |
| `IFiltrosGuardados` (11 métodos) | `ILectorFiltrosGuardados` (3), `IEscritorFiltrosGuardados` (4), `ICompartidorFiltrosGuardados` (3) |
| `IPerfilesUsuario` (10 métodos) | `ILectorPerfilesUsuario` (4), `IEscritorPerfilesUsuario` (3), `ICachePerfilesUsuario` (3) |

Los adaptadores que ofrecen varias capacidades se inyectan mediante
`TServiciosHojaCalculo`, `TServiciosFiltrosGuardados` y
`TServiciosPerfilesUsuario`. Cada consumidor conserva únicamente las
interfaces que utiliza.

En hoja de cálculo, escritura ya no recibe negrita, alineación ni
formato numérico: esas operaciones pertenecen exclusivamente a
`IFormateadorHojaCalculo`.

## 3. Verificación

- `comprobar_supports.ps1`: correcto, 0/0.
- `comprobar_dependencias_capas.ps1`: correcto, 0 infracciones.
- `comprobar_estado_global.ps1`: correcto, 0 variables globales y 0
  `except` vacíos.
- Compilación dirigida de las unidades de Fase 4 en Debug/Win64:
  correcta. Incluye formularios, modales, data modules, los cuatro
  modos de entrada y el adaptador de hoja de cálculo.
- `FactuzamTests` Debug/Win64 y Release/Win64: compilados; en cada
  configuración, 500 pruebas ejecutadas, 500 correctas, 0 ignoradas,
  0 errores y 0 fugas.
- `git diff --check` sobre los ficheros del fascículo: sin errores.

La compilación completa de `fzam.dproj` queda bloqueada por el trabajo
concurrente ya presente en `inMtoFacturasBase.pas` (primer error en la
línea 814, ajeno a esta fase). `FactuzamTests` Release/Win32 encuentra
además cambios concurrentes sin terminar en
`PruebasValidacionTallasCompra.pas`. No se han modificado esas zonas.

`comprobar_acoplamiento.ps1` también refleja una regresión concurrente
ajena a esta fase: `inLibLog` tiene fan-in 85 frente al tope 84.

## 4. Pendiente funcional

- Abrir, reutilizar y cerrar un mantenimiento desde el marco principal.
- Abrir el selector de formatos y eliminar uno.
- Exportar movimientos de ventas y comprobar valores, alineaciones,
  formatos numéricos y guardado del libro.
- Cargar, guardar y compartir filtros; cargar y grabar layouts y
  parámetros de usuario.
