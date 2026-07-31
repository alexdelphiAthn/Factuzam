# Fase 2 — Persistencia de exportaciones

Fecha de validación: 31/07/2026.

## Alcance

- `inLibVerifactuNoVerifactuExport` conserva la validación, la
  construcción del XML y la escritura del fichero.
- Sus seis lecturas pasan por `IRepositorioExportacionNoVerifactu` y
  se ejecutan en `UniDataVerifactuNoVerifactuExport`.
- `inLibFacturae` conserva la construcción, firma y exportación del
  documento.
- Sus cuatro lecturas y la escritura del XML pasan por
  `IRepositorioFacturae` y se ejecutan en
  `UniDataFacturaeRepositorio`.
- Los contratos usan tipos de infraestructura adecuados al consumidor
  y no introducen records de negocio artificiales.

## Resultado

- Ambas fachadas quedan sin SQL literal ni dependencia de `TUniQuery`.
- La medida global baja a 158 sentencias SQL en 53 units `inLib*`.
- Se añaden cuatro pruebas de fábrica y delegación sin BBDD real.
- La escritura del XML de Facturae conserva exactamente el alcance
  anterior; no se amplía ni se redefine su transacción.
- Las escrituras de cierre permanecen bloqueadas hasta fijar el límite
  transaccional y disponer de una prueba de rollback.

La matriz final de compilación y DUnitX se registra en la validación
global de la fase.

## Validación global

- `fzam.dproj`: Release Win32 y Win64 compilados.
- `FactuzamTests.dproj`: Release Win32 y Win64 compilados.
- DUnitX en ambas plataformas: 488 encontradas y 488 superadas.
- SQL en dominio: 158 sentencias en 53 units.
- Dependencias `inLib*` → `UniData*`: 0.
- Estado global, clasificación SQL, transacciones y `Supports`: sin
  regresiones.
- La ausencia de `inLibMsgRegistroTraducciones.pas` deja de bloquear:
  no quedan referencias activas a esa unidad.
