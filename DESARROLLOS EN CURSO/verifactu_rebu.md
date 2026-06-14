# REBU — Regimen especial de bienes usados (IVA sobre el margen)

Tarea pendiente: calculo del IVA sobre el margen para el regimen especial de
bienes usados, objetos de arte, antiguedades y objetos de coleccion (REBU).
Hoy el tipo `BIENES_USADOS` del catalogo Verifactu esta **inactivo**
(`ESACTIVO_VFO = 'N'`) para que no se use hasta implementar esto: si se usara
tal cual, el envio emitiria el IVA sobre la base total y no sobre el margen,
declarando mal.

## Base legal

Ley 37/1992 del IVA (LIVA), arts. 135-139:

- **Base imponible** (art. 137): el **margen de beneficio de cada operacion**,
  minorado en la cuota del IVA correspondiente a dicho margen.
- **Margen de beneficio** = precio de venta − precio de compra, **ambos con el
  IVA incluido**.
- **Prohibicion de desglose** (art. 138): en la factura al cliente **no se
  puede consignar separadamente la cuota** de IVA. El cliente ve solo el precio.

## Formula (margen IVA incluido)

Por operacion/linea, con tipo `t` (p.ej. 21):

```
margen = max(0, precio_venta_civa - precio_compra)   ; nunca negativo
cuota  = margen * t / (100 + t)
base   = margen - cuota   (= margen * 100 / (100 + t))
```

- Margen 0 o negativo -> cuota 0 (operacion por operacion, art. 137.Uno).
- Existe ademas la modalidad de **margen global** (art. 137.Dos) para ciertos
  bienes de escaso valor; aqui se asume **operacion por operacion** (lo comun).

## Lo delicado: rompe el invariante del motor

Hoy el motor (`inLibFacturas.pas`) asume `TOTAL_LIQUIDO = bases + impuestos −
retencion` y reparte por bandas de IVA. En REBU:

- El **cliente paga el precio de venta** (sin IVA desglosado). El total de la
  factura **NO** es base+cuota.
- A la AEAT se reporta **base y cuota sobre el margen**.
- Por tanto, en Verifactu: `ImporteTotal` = **precio de venta** (lo que paga el
  cliente), mientras que el desglose lleva base+cuota del **margen**. Es decir
  `ImporteTotal` ≠ Σ(base+cuota). La AEAT valida la clave 03 de forma acorde.

## Datos disponibles

- Linea de factura `fza_facturas_lineas`:
  `PRECIO_ULT_COMPRA_FACTURA_LINEA` (coste), `PRECIOSALIDA_FACTURA_LINEA`
  (venta), cantidad y descuentos.
- Indicador: ya existe `fza_facturas.TIPO_OPER_VFACTU_FAC = 'BIENES_USADOS'`
  (no hace falta flag nuevo).

**Pendiente de confirmar**: que `PRECIO_ULT_COMPRA_FACTURA_LINEA` se rellene con
el **coste real de adquisicion del bien usado concreto** y no con un "ultimo
precio de compra" generico del articulo. De eso depende que el margen sea
correcto.

## Plan de implementacion (cuando se aborde)

1. `TLinFac` (`inLibFacturas.pas`): anadir campo coste y leerlo en
   `CopyToObjectLin` desde `PRECIO_ULT_COMPRA_FACTURA_LINEA`.
2. `TConfiguracionFactura`: flag `EsRegimenBienesUsados`, puesto desde
   `TIPO_OPER_VFACTU_FAC = 'BIENES_USADOS'`.
3. `AcumularTotalesPorTipoIVA`: si REBU, base/cuota por linea desde el margen
   (formula de arriba) en vez del precio completo; acumular en la banda del
   tipo aplicable.
4. Totales: el total al cliente sigue siendo el **precio de venta**; separar
   "base/cuota declarables" (margen) de "importe a cobrar" (venta).
5. Envio Verifactu: ya emite `ClaveRegimen=03`; ajustar para mandar la base y
   cuota del margen y `ImporteTotal` = precio de venta.
6. Reports: la factura al cliente **no** debe desglosar la cuota (art. 138).
7. Reactivar la fila `BIENES_USADOS` del catalogo (`ESACTIVO_VFO = 'S'`).

## Antes de activarlo

- Confirmar la fuente del coste por linea.
- Decidir si hace falta soportar margen global (probablemente no de inicio).
- Validar en preproduccion con un caso real (margen positivo y margen 0) y
  contraste con un asesor fiscal: REBU declara impuestos, un error aqui es
  serio.
