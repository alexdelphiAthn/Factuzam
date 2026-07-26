# Fase 2, bloque 1 — inLibImpuestosComun: fin de la duplicación compras/ventas

Fecha: 26/07/2026.

## Cambio

Nueva unidad `src/Lib/inLibImpuestosComun.pas` con las **14 funciones fiscales
que vivían duplicadas byte a byte** en `inLibComprasImpuestos` e
`inLibVentasImpuestos`: `CampoFloat`, `CampoString`, `CampoFloatDifiere`,
`CampoStringDifiere`, `PonerFloat`, `PonerString`, `TipoIvaValido`,
`NormalizarTipoIva`, `IndiceTipoIva`, `LeerPorcentajesIvaPorCodigo`,
`LeerPorcentajesIvaPorEmpresa`, `ObtenerTipoIvaArticulo`,
`PorcentajeIvaCabecera` y `SufijoLineaFiscalDesdeCampo`.

- Las dos unidades originales pierden las implementaciones y añaden
  `uses inLibImpuestosComun;` en implementation. Su API pública (los
  `CalcularTotalesDocumento*`, recargo/intracomunitario en compras, retención
  en ventas) queda intacta: esas partes divergen de verdad y NO se han tocado.
- `CODIGOS_IVA` se mantiene como const local en las tres unidades (las
  originales la siguen usando en su código propio; la común lleva copia
  privada). `CODIGOS_RE` no la usan las 14 y queda donde estaba.
- Unidad registrada en `fzam.dpr`.
- Cabecera de unidad con la caja de 80 columnas del libro de estilo §6.

Balance de líneas: compras 864→607, ventas 749→492 (−514), nueva unidad +327.
**Neto: −187 líneas y, sobre todo, una sola fuente de verdad fiscal común.**

## Verificación (extracción demostrada equivalente)

| Comprobación | Resultado |
|---|---|
| Cada una de las 14 funciones de la unidad nueva es idéntica (módulo finales de línea) a la versión de compras Y a la de ventas prístinas | **14/14** |
| Implementaciones residuales de las 14 en las unidades originales | 0 y 0 |
| `begin`/`end` extraídos de cada original = los de la unidad nueva (27/30+`end.`) | Cuadra |
| Líneas >80 columnas en la unidad nueva | 0 |
| BOM UTF-8 y CRLF en la unidad nueva | Sí |
| Referencias vivas a las 14 desde el código restante de ambas unidades (resueltas ahora vía uses) | 11 y 11 |

Al ser un movimiento de código byte-idéntico con la misma resolución de
nombres, la equivalencia funcional queda demostrada estructuralmente; no
necesita banco de BBDD.

## Hallazgo anotado para más adelante (no tocado)

Existen otras dos variantes LOCALES de `CampoFloat` con firma distinta en
`inLibDocCompraExcel.pas:87` y `inLibFacturae.pas:114`. No son idénticas a
estas (una lleva `const`, otras difieren en tolerancia a nil) — candidatas a
converger sobre `inLibImpuestosComun.CampoFloat` en una pasada posterior, con
revisión una a una.

## Pendiente manual

- Compilar (`fzam.dproj` incluye ya la unidad nueva vía `.dpr`).
- Smoke test fiscal: recalcular totales de una factura, un pedido y un albarán
  de venta, y de un documento de compra con recargo — los números deben ser
  idénticos a antes (mismo código, nueva ubicación).

## Siguiente bloque de la Fase 2

Modales de remesa (`inMtoModalCargarEfectosRemesa` vs `...Venta`, 99% clones):
unificación con record de configuración `TConfigRemesa`. Es el que más líneas
elimina (~370) pero toca `.dfm`, así que irá con plan de pruebas de UI propio.
