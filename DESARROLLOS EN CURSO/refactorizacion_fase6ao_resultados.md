# Fase 6AO — factura Excel por pasos

Fecha: 29/07/2026. D4.5, quinta tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `ExportarFacturaADevExpress` | 388 | 15 | **-373** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibFacturaExcel` completa | 424 | 575 | **+151** |

La unidad crece un 35,6 %. D4.5 reduce complejidad, no volumen: el flujo
monolítico se convierte en una fachada y 22 operaciones internas con
nombre. Todas tienen consumidor, ninguna supera 60 líneas y no se añade
otra unidad ni una abstracción común artificial con los balances.

## Implementación

`TExportadorFacturaDevExpress` conserva en un contexto explícito el
control, los datasets, la conexión, los parámetros, la hoja y la fila
actual. El flujo queda separado en:

- nombre y título de la hoja;
- QR tributario opcional;
- emisor y receptor;
- cabecera y detalle de líneas;
- bases, IVA y recargo de equivalencia;
- retención, total, forma de pago y columnas.

La API pública y su único consumidor no cambian. Se conservan:

- los nombres de campos y los cuatro tipos fiscales `N/R/S/E`;
- las fórmulas `SUMIF`, base incluida/no incluida, IVA, RE y retención;
- los títulos normal, simplificado y rectificativo;
- el QR como mejor esfuerzo y el modo sin Verifactu;
- `DisableControls`/`EnableControls` y `BeginUpdate`/`EndUpdate`;
- tamaños, celdas combinadas, columnas técnicas ocultas y formatos.

Las dependencias visuales de DevExpress pasan de la sección `interface`
a `implementation` salvo `dxSpreadSheet`, necesario en la firma pública.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.5:

- `ExportarFacturaADevExpress` no puede superar 100 líneas;
- las 22 operaciones internas deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- deben conservarse lote de hoja, bloqueo del dataset y QR;
- se protegen los literales y campos fiscales principales;
- el límite global baja de 46 a 45 métodos mayores de 200 líneas.

Resultado: fachada de 15 líneas, colaborador máximo de 60 y 45 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La matriz DUnitX se recompiló con Delphi 37 en salida aislada:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 211/212 | 0 | 1 |
| Debug / Win32 | 0 errores | 211/212 | 0 | 1 |
| Release / Win64 | 0 errores | 211/212 | 0 | 1 |
| Release / Win32 | 0 errores | 211/212 | 0 | 1 |

La única roja sigue siendo ajena a D4.5:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original` después del cambio concurrente
que retiró esa responsabilidad del gestor de perfiles.

La batería general no enlaza `inLibFacturaExcel`, que depende del
runtime visual de DevExpress. La aplicación se reconstruyó con Delphi
37 en Release/Win64 dentro de `build/validacion_d45/Win64/Release`:
0 errores, 317.344 líneas y 11,41 segundos.

También pasan:

- el comprobador de flujos largos;
- el comprobador de dependencias: 403 unidades y ciclo mayor 1;
- `git diff --check` limitado al alcance;
- UTF-8 con BOM y CRLF en la unidad Pascal;
- ninguna línea de producción añadida por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido.

`factuzam_original.sql` sigue modificado (+95/-6) por trabajo concurrente.
D4.5 no lo ha tocado ni revertido.

## Validación funcional pendiente

Con una BBDD de pruebas:

1. Exportar una factura normal con impuestos incluidos y otra sin ellos.
2. Probar sin RE y con RE para los tipos `N`, `R`, `S` y `E`.
3. Probar una factura con retención y otra sin retención.
4. Comparar títulos normal, simplificado y rectificativo.
5. Comparar QR activo, modo sin Verifactu y datos fiscales incompletos.
6. Revisar emisor, receptor y números con caracteres no válidos en hoja.
7. Comprobar descripciones largas, formatos, columnas ocultas y pago.
8. Guardar el resultado como XLSX y compararlo con la versión anterior.

El siguiente fascículo es **D4.6**:
`TTiraCajaTicket.ExportarExcel`, actualmente con 438 líneas.
