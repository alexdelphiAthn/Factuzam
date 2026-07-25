# Pruebas HojaCalculo — Fase 0

Fase 0 del refactor del subsistema Excel (ver
`../desacoplar_excel_hojacalculo.md`).

## Qué se prueba

Helpers puros de `src/Lib/inLibHojaCalculoUtil.pas` (portados de
`inLibDevExcel`), sin dependencia de DevExpress ni de UI:

- `ColumnaALetras`: `0 -> 'A'`, `26 -> 'AA'`, `27 -> 'AB'`.
- `ReferenciaCelda`: relativa (`A1`, `D5`) y absoluta (`$AA$10`).
- `SeparadorFormula`: coma decimal ⇒ `';'`; punto decimal ⇒ `','`
  (restaura `FormatSettings` con `try..finally`).

En esta fase todavía **no** se prueban los métodos que tocan DevExpress
(`Combinar`, `Escribir`, `EscribirFormula`, `DibujarCuadro`); eso llega con
el adaptador (Fase 1) y el doble de prueba `TEscritorHojaCalculoFalso`.

## Cómo ejecutar

```powershell
powershell -ExecutionPolicy Bypass -File .\ejecutar_pruebas.ps1
```

Compila `PruebasHojaCalculoFase0.dpr` con `dcc32`/`dcc64` (vía `rsvars`),
ejecuta el binario en Win32 y Win64 y vuelca el resultado en
`resultado_pruebas.txt`. Código de salida 0 = todo correcto.

## Framework

DUnitX (elegido para el subsistema Excel). Nota: las demás carpetas
`Pruebas*Fase*` usan un harness propio `Comprobar([OK]/[ERROR])`; si se
prefiere unificar, este runner se adapta a ese estilo sin tocar la lógica.

## Estado

Pendiente de primera ejecución en el entorno con Delphi (este repo se editó
en remoto). Al ejecutar, adjuntar aquí el resumen `Pruebas: N | Fallos: 0`.
