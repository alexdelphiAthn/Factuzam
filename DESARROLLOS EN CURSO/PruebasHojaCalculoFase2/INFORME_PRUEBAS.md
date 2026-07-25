# Pruebas HojaCalculo — Fase 2 (piloto)

Fase 2 del refactor del subsistema Excel (ver
`../desacoplar_excel_hojacalculo.md`). Piloto: primer exportador migrado.

## Qué entra en la Fase 2

- Puerto `IEscritorHojaCalculo` **v1.1**: crece con las operaciones que usa un
  exportador real — `IniciarLote`/`FinalizarLote`, formato en `Escribir`,
  `BordeCelda(lado, estilo)`, `FondoCelda(color)`, `Negrita`, `TamanoFuente`,
  `AnchoColumna` y `CeldaExiste`. Color como `Cardinal` ($00BBGGRR), sin VCL.
- Adaptador `inLibHojaCalculoDevEx` y doble `inLibHojaCalculoFalso`
  actualizados a esa superficie.
- `src/Lib/inLibMovVentasArtExcel.pas` **migrado**: ya no referencia ningún
  tipo `dx*`; escribe todo por el puerto. Quedó libre de DevExpress.
- Call site `src/Modals/inMtoModalImpMovVentasArt.pas`:
  `ExportarMovVentasArtExcel(CrearEscritorDevEx(fPreview.dxSpreadSheet1), …)`.

## Qué se prueba aquí (automático, sin DevExpress)

`Snapshot_SinGrupos`: ejecuta el exportador contra el doble con un
`TClientDataSet` en memoria (1 artículo, sin agrupaciones) y afirma las celdas
clave del layout — hoja 'Ventas'; título en (1,0) con tamaño 14 y negrita;
cabecera 'Artículo' en (3,0) con fondo `$00EEEEEE` y borde inferior fino;
detalle en (4,0)/(4,1) con valor 10, formato `#,##0` y alineación a la
derecha; total 'TOTAL GENERAL' en (5,0) con fondo `$00EED7BD` y borde
superior; anchos 240 y 72.

Nota de ciclo de vida: el doble se sostiene por una referencia de interfaz
(`FEscritor`) y se libera poniéndola a `nil` en el `TearDown`; **no** se hace
`Free` manual, para no chocar con el recuento de referencias de la interfaz.

## Cómo ejecutar

```powershell
powershell -ExecutionPolicy Bypass -File .\ejecutar_pruebas.ps1
```

Compila `PruebasHojaCalculoFase2.dpr` (Win32/Win64) y vuelca a
`resultado_pruebas.txt`. El dataset usa `TClientDataSet` + `MidasLib` (sin
BBDD). El doble se referencia desde `..\PruebasHojaCalculoFase1\`.

## Estado

Pendiente de primera compilación/ejecución en el entorno con Delphi.

## Siguiente (Fase 2, resto)

Migrar los demás exportadores en orden de riesgo (Balance, Inventario,
Documentos, Factura, DocCompra) reutilizando este mismo patrón y ampliando el
puerto solo si aparece una operación nueva.
