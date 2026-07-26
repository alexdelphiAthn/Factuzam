# Fase 3, bloque 1 — La validación del DM ya no toca la UI

Fecha: 26/07/2026. Ficheros: `src/DataModules/UniDataFacturas.pas`,
`src/Forms/inMtoFacturasBase.pas`. Compilado en tu máquina: **0 errores**
(307.603 líneas, 17,4 s).

## El problema

`TdmFacturas.ValidarCabeceraBeforePost` manipulaba directamente la UI del
form: 8 bloques con `frmFac.pcCab.ActivePage := ...` y `SetFocus` sobre 5
controles concretos, y el `AfterInsert` invocaba `sbNuevaFacturaClick` del
form. Ese acoplamiento invertido era el hallazgo nº 6 de la auditoría: el DM
no es reutilizable sin ese form exacto, y los bombeos de mensajes durante la
validación son la causa raíz del parche anti-reentrada `FValidandoPost`.

## El diseño nuevo

- **`TCampoValidacionFac`** (enum en la interface del DM): `cvfSerie`,
  `cvfRazonSocialCliente`, `cvfRazonSocialEmpresa`, `cvfFecha`,
  `cvfNifCliente`, `cvfNifEmpresa` — el campo LÓGICO que falló.
- El DM expone **`OnCampoInvalido: TCampoInvalidoEvent`** y
  **`OnNuevaFactura: TNotifyEvent`**. La validación llama a
  `SenalarCampoInvalido(cvfX)`; el alta encadenada dispara `OnNuevaFactura`.
  Cero referencias a controles: `frmFac` y `sbNuevaFacturaClick` han
  desaparecido del DM (grep = 0).
- El form se suscribe al asignar `dmmFacturas` (en `CrearTablaPrincipal`) y
  traduce campo → pestaña + foco en `SenalarCampoValidacion` (mapeo idéntico
  al que estaba incrustado en el DM).

Comportamiento visible: exactamente el mismo (mismos mensajes, misma pestaña,
mismo foco). Si nadie se suscribe (DM usado desde un proceso sin UI), la
validación sigue funcionando y simplemente no hay foco que mover.

## Lo que queda del acoplamiento DM→form (anotado, no tocado)

Quedan 12 referencias a `TfrmMtoFacturasBase` en el DM, agrupables para
próximos bloques de la Fase 3: el cableado de `MasterSource` a `dsTablaG`
(5), `ActualizarComboSeries` (2), `TipoFacturaFiltro` (1), dos accesos
directos (líneas ~1743/1837, uno de ellos redundante — accede a
`dmmFacturas.unqryTablaG` del form siendo el propio DM) y un comentario.
Cuando lleguen a 0, el `uses inMtoFacturasBase` desaparece y con él el ciclo
facturas del grafo.

## Pruebas manuales (UI)

| # | Prueba | Resultado esperado |
|---|---|---|
| V1 | Grabar factura sin razón social de cliente | Mensaje + pestaña Datos cliente + foco en razón social (igual que antes) |
| V2 | Sin serie / serie de otra empresa | Mensaje + pestaña Cabecera + foco en el combo de serie |
| V3 | NIF de cliente inválido (España) | Mensaje + pestaña Datos cliente + foco en NIF |
| V4 | Sin fecha | Mensaje + pestaña Cabecera |
| V5 | Alta automática encadenada (flujo que insertaba y llamaba a nueva factura) | Igual que antes (ahora vía OnNuevaFactura) |
| V6 | Grabación válida completa | Sin cambios; numeración y auditoría normales |
