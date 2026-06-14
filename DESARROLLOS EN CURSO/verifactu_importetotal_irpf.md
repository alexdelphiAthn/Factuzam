# Verifactu: ImporteTotal con retención de IRPF (importe bruto)

Corrección del cálculo del campo `ImporteTotal` del `RegistroAlta` de
Verifactu cuando la factura lleva retención de IRPF.

## Problema

Verifactu informa **solo a efectos de IVA**. La retención de IRPF **no se
comunica** a la AEAT ni se descuenta del importe total: el `ImporteTotal`
que viaja en el registro es el **importe bruto** de la factura
(base + IVA + recargo de equivalencia), no el líquido a pagar.

El código enviaba como `ImporteTotal` el valor de `TOTAL_LIQUIDO_FAC`, que
ya tiene la retención **restada**:

```
TOTAL_LIQUIDO_FAC = TOTAL_BASES + TOTAL_IMPUESTOS - TOTAL_RETENCION
```

(ver `src/Lib/inLibFacturas.pas`, `CalcularTotalesFactura`). En facturas
con retención eso provoca que el `ImporteTotal` enviado quede **corto justo
por el importe de la retención** respecto a la suma del desglose
(Σ base + Σ cuota IVA + Σ cuota recargo), que es contra lo que la AEAT
valida el cuadre del total. Para retenciones grandes (p.ej. 15% de IRPF de
profesionales sobre bases altas) el descuadre supera el margen de
tolerancia y la AEAT puede rechazar el registro.

## Solución

`ImporteTotal` debe ser el **bruto**. Como
`bruto = líquido + retención`, basta con devolver la retención a la suma.
Se añade `TOTAL_RETENCION_FAC` al `SELECT` y se reconstruye el bruto en
`src/verifactu/inLibVerifactuEnvio.pas`
(`CargarDatosFacturaRegistro`):

```pascal
ADatos.ImporteTotal :=
  Qry.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency +
  Qry.FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
```

`CuotaTotal` (= `TOTAL_IMPUESTOS_FAC`, IVA + recargo) se deja igual: ya era
correcto y cuadra con Σ`CuotaRepercutida` + Σ`CuotaRecargoEquivalencia`.

## Efectos

- **Factura sin retención**: `TOTAL_RETENCION_FAC` = 0, así que
  `ImporteTotal` no cambia (sigue siendo bruto = líquido). Sin impacto.
- **Factura con retención**: `ImporteTotal` pasa a ser el bruto y cuadra
  con la suma del desglose. El líquido a pagar por el cliente sigue siendo
  distinto del `ImporteTotal` de Verifactu, que es lo esperado.

## Recomendación operativa

Conviene incluir en la factura (impresa o electrónica) una leyenda
aclaratoria, p.ej.: «El importe total comunicado a la AEAT (visible en el
QR) no incluye la retención de IRPF; el importe a pagar es el indicado en
esta factura.»

## Verificación pendiente

Probar en preproducción (`src/verifactu/entornopre`) una factura con
retención significativa y confirmar que la AEAT acepta el `ImporteTotal`
bruto sin descuadre.

## No requiere cambio de esquema

Las columnas (`TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC`,
`TOTAL_IMPUESTOS_FAC`) ya existen en `fza_facturas`. Solo cambia el código
Pascal del módulo de envío.
