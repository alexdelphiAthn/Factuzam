# Pruebas HojaCalculo — Fase 1

Fase 1 del refactor del subsistema Excel (ver
`../desacoplar_excel_hojacalculo.md`).

## Qué entra en la Fase 1

- `src/Lib/inLibHojaCalculoDevEx.pas`: adaptador `TEscritorHojaCalculoDevEx`
  del puerto `IEscritorHojaCalculo` sobre `TdxSpreadSheet`. **Única** unidad
  del subsistema que ve tipos `Tdx*`. Las 4 operaciones de bajo nivel
  (`MezclarDx`, `EscribirCeldaDx`, `EscribirFormulaDx`, `PintarCuadroDx`) son
  métodos de clase = fuente única.
- `src/Lib/inLibDevExcel.pas`: reconvertido a **shims** que delegan en esos
  métodos de clase (y en `inLibHojaCalculoUtil` para `GetRef`/`ColToLetras`/
  `SepFormula`). Firmas idénticas: los 8 exportadores siguen compilando sin
  tocarlos. Emite `{$MESSAGE HINT}` de transición. Se borra en Fase 4.
- `inLibHojaCalculoFalso.pas`: doble en memoria de `IEscritorHojaCalculo` e
  `ILectorHojaCalculo` (oráculo de las pruebas de snapshot de Fase 2).

Refinamiento del puerto: se añadió `NuevaHoja(const ANombre: string)` a
`IEscritorHojaCalculo`. Al construir el adaptador se vio que los exportadores
crean y nombran su hoja (`ClearAll` + `AddSheet('...', TdxSpreadSheetTableView)`)
en vez de usar la hoja activa; el puerto debe cubrir eso para que la Fase 2
pueda migrarlos. El adaptador lo implementa con `ClearAll`/`AddSheet`; el doble
lo modela como hoja fresca.

## Qué se prueba aquí (automático, sin DevExpress)

El doble `TEscritorHojaCalculoFalso`: que registra fielmente valor, negrita,
alineación, fórmula y formato; que cuenta combinaciones y cuadros; que
`Guardar` recuerda la ruta; y la lectura (`UltimaFila`/`UltimaColumna`,
celda vacía nula, `Precargar`). 8 pruebas.

## Qué NO se prueba aquí (y por qué)

El adaptador `TEscritorHojaCalculoDevEx` toca DevExpress, que no compila en
un runner de consola con sólo `-U src\Lib`. Su equivalencia con el código
original se valida de dos formas: (1) compilando la app principal (los shims
lo ejercitan en tiempo de ejecución) y (2) la prueba *golden-file* del primer
exportador migrado en Fase 2 (mismo `.xlsx` antes/después). La lógica de mapeo
(`MapAlineacion`/`MapBorde`) es trivial y directa.

## Cómo ejecutar

```powershell
powershell -ExecutionPolicy Bypass -File .\ejecutar_pruebas.ps1
```

Compila `PruebasHojaCalculoFase1.dpr` (Win32/Win64) y vuelca a
`resultado_pruebas.txt`. Código de salida 0 = correcto.

## Riesgo conocido a verificar en compilación

Los nombres de constantes de borde en `MapBorde` (`sscbsNone`, `sscbsThin`,
`sscbsMedium`, `sscbsThick`) deben coincidir con los de la versión de
DevExpress instalada. `sscbsThin` está confirmado por uso en el repo; los
otros tres son los estándar de la enumeración `TdxSpreadSheetCellBorderStyle`.
Si alguno difiere, es un cambio de una línea.

## Estado

Pendiente de primera compilación/ejecución en el entorno con Delphi.
