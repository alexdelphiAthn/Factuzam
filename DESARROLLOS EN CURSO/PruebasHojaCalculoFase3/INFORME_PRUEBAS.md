# Pruebas HojaCalculo — Fase 3 (importación)

Fase 3 del refactor del subsistema Excel (ver
`../desacoplar_excel_hojacalculo.md`). Ruta de importación desacoplada.

## Qué entra en la Fase 3

- Adaptador `inLibHojaCalculoDevEx` **v1.2**: implementa también
  `ILectorHojaCalculo` (`LeerCelda`, `UltimaFila`, `UltimaColumna` sobre
  `Dimensions` del control) + factoría `CrearLectorDevEx(control)` que lee la
  primera hoja **sin limpiarla**.
- `ImportarInventarioDesdeSheet` **migrado**: recibe `ILectorHojaCalculo` en
  vez de `TdxSpreadSheet`; el cuerpo lee por `LeerCelda`/`UltimaFila`. La
  lógica de negocio (detección de columnas por cabecera, fallback
  A=SKU/B=Cantidad, PMP opcional, filas vacías) se conserva.
- Call site `src/Forms/inMtoInventarios.pas`:
  `ImportarInventarioDesdeSheet(CrearLectorDevEx(Sheet), …)`.

## Qué se prueba aquí

Round-trip contra el doble precargado como hoja de origen:
- `ConCabeceras_DetectaColumnasYLee`: cabeceras SKU/Cantidad/PMP en fila 0,
  dos filas de datos (una con PMP, otra sin) y una fila con SKU vacío que se
  ignora. Afirma `ALista` (`SKU=CANTIDAD`), el array de registros, la cantidad
  y el flag/valor de PMP.
- `SinCabeceras_UsaColumnasAyB`: sin cabeceras reconocibles, usa col A=SKU y
  col B=Cantidad desde la fila 0.

## Dependencia a tener en cuenta

A diferencia de las fases 1 y 2, este test **compila `inLibInventarioExcel`**,
que todavía arrastra DevExpress por su parte de **exportación** (aún no
migrada; solo se ha migrado la importación). Debería resolver igual que `Uni`
en tus otras carpetas de pruebas (la toolchain expone las rutas de librería
del IDE). Cuando se migre también `ExportarInventarioExcel` (paso siguiente de
la Fase 2 para inventario), la unidad quedará libre de DevExpress y este test
será igual de autocontenido que los de las fases 1 y 2.

## Cómo ejecutar

```powershell
powershell -ExecutionPolicy Bypass -File .\ejecutar_pruebas.ps1
```

Compila `PruebasHojaCalculoFase3.dpr` (Win32/Win64) y vuelca a
`resultado_pruebas.txt`. El doble se referencia desde
`..\PruebasHojaCalculoFase1\`.

## Estado

Pendiente de primera compilación/ejecución en el entorno con Delphi.
