# Mantenimiento de Formas de Pago de Caja

Pantalla de admin para `fza_caja_formas_pago`: los botones disponibles en la
fase de cobro (F12) del TPV. Cada fila representa un medio (efectivo, tarjeta,
divisa, cripto, bono…) con sus flags de comportamiento.

## Archivos

| Archivo | Función |
|---|---|
| `src/Caja/Forms/inMtoCajaFormasPago.pas/.dfm` | `TfrmMtoCajaFormasPago`. Lista + Ficha sobre `fza_caja_formas_pago`. |
| `src/Caja/DataModules/UniDataCajaFormasPago.pas/.dfm` | `TdmCajaFormasPago`. `unqryTablaG` con `SELECT * FROM fza_caja_formas_pago`. |

## Cableado

- **Registro `fzam.dpr`**: ambas unidades añadidas tras `inMtoCajaFaseCobro`.
- **Registro `fzam.dproj`**: igual.
- **Menú principal**: `FormasdePagoCaja1` (ya existía en `inMtoPrincipal.dfm`)
  ahora con `OnClick = FormasdePagoCaja1Click` y `ShortCut = Ctrl+Shift+Q`.
  Handler en `src/Core/inMtoPrincipal.pas` llama `ShowMto(Self,
  'CajaFormasPago')`.
- **`fza_winforms`**: ver `registro_caja_formas_pago.sql` (idempotente).

## Ficha

El formulario hereda de `TfrmMtoGen` y aprovecha sus pestañas `tsLista` y
`tsFicha`:

- **Lista** (`tsLista`): grid editable inline con todas las columnas de la
  tabla. Las de blockchain y auditoría empiezan ocultas.
- **Ficha** (`tsFicha`): cabecera con código + descripción + activo +
  orden visual F12, y `cxPageControl` con tres pestañas internas:
  - `Comportamiento`: checkboxes (referencia obligatoria, divisa, cripto,
    devuelve cambio, abre cajón) + comisión (% + incluida).
  - `Blockchain`: red y hash (solo relevantes si la forma es cripto).
  - `Auditoría`: usuario/instante alta y modificación, todo `ReadOnly`.

El código de forma de pago (`CODIGO_FP_CFP`) es PK y se bloquea fuera de
`dsInsert` (handler `dsTablaGStateChange`).

## Convención de shortcut

Los items del menú Caja usan `Ctrl+Shift+X` por convención. Se elige `Q`
para que case con `Ctrl+Q` que es el shortcut de `FormasdePago` (venta).
