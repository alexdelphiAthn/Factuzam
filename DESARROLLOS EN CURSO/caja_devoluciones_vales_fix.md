# Corrección: devoluciones y emisión de vales en caja

Fecha: 25/07/2026

Hallazgo surgido durante la validación funcional de la Fase XII-D. No
pertenece a la retirada de parámetros; son defectos del subsistema de
caja (venta/devolución/vale) que se detectaron al probar el punto 5 de
la batería y que se han corregido y verificado contra la BBDD
`Factuzam` (`127.0.0.1:3306`).

## 1. La devolución se descartaba sin grabar

Síntoma: al hacer una devolución por cantidad negativa y confirmar, la
operación «desaparecía»: no se creaba nada en `fza_caja_operaciones`,
no se reponía stock y no salía ticket (salía un recordatorio).

Causa: en `TdmCajaOpe.GrabarFacturaSimplificada`
(`src/Caja/DataModules/UniDataCaja.pas`), el «FILTRO DE NOVEDAD»
consideraba que había algo que grabar solo si
`DatosCobro.ImporteEntregado > 0`. En una devolución el cliente no
entrega dinero (`ImporteEntregado` = 0), así que el filtro daba
`HayNovedad = False`, imprimía un recordatorio y devolvía `True` sin
grabar. El llamador cerraba la operación como si hubiera ido bien.

Corrección: el filtro ahora también reconoce como novedad una
devolución económica, la existencia de líneas devueltas o la emisión de
un vale:

```
if (DatosCobro.ImporteEntregado > 0) or
   DatosCobro.EsDevolucionEconomica or
   DatosCobro.TieneArticulosDevueltos or
   (DatosCobro.ImporteValeEmitido > 0) or
   (sAccion = 'CANCELAR') or
   (sAccion = 'NUEVO_DEP') then
```

Verificación: devolución en efectivo (factura 2026.A1.000168) grabada,
stock repuesto, `FASE_FAC = VERIFACTU_OK` y enviada a la AEAT
(el portal de pruebas la marcó «Encontrada»).

## 2. La emisión de vales no estaba implementada

Síntoma: al reembolsar una devolución como vale, el vale no se creaba
en ninguna parte; combinado con el fallo anterior, la operación entera
se perdía.

Causa: en todo el flujo de caja no existía ningún `INSERT INTO
fza_caja_vales`. `GrabarFacturaSimplificada` inicializaba
`ValeGenerado := ''` y nunca lo rellenaba. El único acceso de escritura
a la tabla era el `UPDATE` del canje.

Corrección: nuevo bloque «PASO 6.5: VALE EMITIDO» en
`GrabarFacturaSimplificada` que, cuando `ImporteValeEmitido > 0`:

- crea el vale en `fza_caja_vales` en estado `PENDIENTE`, con código
  `VALE_<emp>_<alm>_<caja>_<numOperacion>` (mismo formato que los vales
  ya existentes), importe nominal y caducidad según los parámetros de
  caja (`vgerCaducidadDefVale` / `vgerDiasCaducidadVale`; con la config
  actual, sin caducidad);
- inserta la línea de pago `VALE` en negativo con el código de vale como
  referencia (el reembolso entregado como vale);
- registra la operación de caja `VL`;
- devuelve el código en `ValeGenerado`.

Además, en `src/Caja/Forms/inMtoCajaOpe.pas` se propaga el código
generado a `DatosCobro.CodigoValeEmitido` antes de imprimir, y se activa
el aviso al cajero «Entregue el vale al cliente: <código>» (estaba
comentado).

Verificación (factura 2026.A1.000169, op 196): vale
`VALE_012_GEN_1_00000196` creado PENDIENTE por 149,95, línea de pago
`VALE` presente, operaciones `DV` + `VL`, `FASE_FAC = VERIFACTU_OK`, y
el arqueo lo cuenta en «Vales emitidos».

## 3. El código del vale en el ticket

El ticket imprimía «CÓDIGO VALE EMITIDO:» pero el código salía vacío
(usaba `DatosCobro.CodigoValeEmitido`, que no recibía el valor). Ya
corregido en el punto 2. Además:

- Si «CÓDIGO VALE EMITIDO: » + el código supera el ancho del ticket
  (42 caracteres), el código pasa a una línea propia debajo. Aplicado
  en el ticket en vivo (`src/Lib/inLibGenerarTicket.pas`) y en la
  reimpresión desde BBDD (`src/Lib/inLibGenerarTicketBD.pas`).
- La reimpresión desde BBDD no mostraba la sección del vale emitido
  (solo la línea de pago). Ahora la reconstruye leyendo el vale de
  `fza_caja_vales` por la operación.

## 4. El vale usado como moneda (canje)

Verificado que el canje ya funcionaba y deja su apunte de pago: venta
2026.A1.000171 (op 198) pagada con `VALE_012_GEN_1_00000197`; en
`fza_caja_pagos` queda la línea `VALE` por +149,95 con el código como
referencia, se registra la operación `VR`, y el vale pasa a `REDIMIDO`.

## 5. Arqueo

El arqueo de la caja 012/GEN/1 cuadra con todo lo anterior: Ventas
Normales 449,85 (dos ventas), Devoluciones 449,85 (las tres), Vales
emitidos 299,90 (los dos), Vales recogidos 149,95 (el canjeado),
Efectivo en caja 149,95. El desglose por familias respeta los niveles
configurados. No se ha grabado el arqueo (no se ha cerrado el día).

## Observación abierta (UI)

El campo «Vale Emitido» de la fase de cobro (`txtValeEmitido`,
`TcxCurrencyEdit`) lanza `EcxEditValidationError "Valor inválido"` al
teclear el importe, y con tecleo automatizado concatena en vez de
reemplazar. El valor acaba aplicándose tras cancelar la edición, pero
conviene revisar la validación/formato de ese control.

## Ficheros modificados

- `src/Caja/DataModules/UniDataCaja.pas` — filtro de novedad y PASO 6.5.
- `src/Caja/Forms/inMtoCajaOpe.pas` — propagación del código y aviso.
- `src/Lib/inLibGenerarTicket.pas` — salto de línea del código.
- `src/Lib/inLibGenerarTicketBD.pas` — sección de vale en la reimpresión.

Compilación Release Win64 tras los cambios: 0 errores, 109 avisos
(línea base).

## Datos generados en `Factuzam` durante la prueba (para limpieza)

- Facturas serie 2026.A1: 000167 (venta 299,90), 000168 (devol. efectivo
  -149,95), 000169 (devol. vale -149,95), 000170 (devol. vale -149,95),
  000171 (venta 149,95 pagada con vale).
- Vales: `VALE_012_GEN_1_00000196` (PENDIENTE),
  `VALE_012_GEN_1_00000197` (REDIMIDO).
- Operaciones de caja 194 a 198 (con sus DV/VL/VE/VR y pagos).
- Registros en `fza_verifactu_cadena` / `_cola` (encadenados: no se
  pueden retirar limpiamente).
- Stock de `CAMI-BASICA/BLANCO/M` en GEN: neto sin cambio (24),
  compensado entre ventas y devoluciones.
- Parámetros de API guardados en el perfil de Administrador para la
  prueba de servicios web: `appApiToken` y `appApiReferencia`
  (= `LosChicos`). Conviene vaciarlos si no se quieren dejar.

`limpieza_5_8.sql` (en `PruebasParametrosFase12D/`) borra de forma
acotada por instante lo generado, con los límites ya documentados
(no rebobina contadores, no repara la cadena Verifactu).
