# Series por almacén en documentos de compra

## Objetivo

Cuando se crean documentos desde una sesión de compras (pedido / albarán)
o un albarán desde un pedido de compra, la serie del documento debe
acompañar al almacén: por defecto se propone la serie que lleve el
almacén del documento, y el usuario puede cambiarla desde un combo con
las series disponibles (normalmente una serie por almacén).

## Modelo de datos

No hay cambio de esquema. Se apoya en columnas que ya existen en
`fza_empresas_series`:

- `CODIGO_ALM_EMPSER`: almacén al que va ligada la serie (NULL o vacío
  = serie genérica de la empresa).
- `TIPO_DOC_EMPSER`: tipo de documento de la serie. Se usan `AB`
  (albarán de compras) y `PC` (pedido de compras).
- `FECHA_DESDE_EMPSER` / `FECHA_HASTA_EMPSER`: vigencia.

La asociación serie ⇄ almacén se configura en el Mto de Empresas,
pestaña Series (la columna de almacén ya era editable).

## Comportamiento

### Resolución de serie (`inLibValoresAutomaticos`)

- `ObtenerSeriePropiaAlmacen(empresa, tipoDoc, almacén)`: devuelve la
  serie ligada en exclusiva a ese almacén ('' si no tiene).
- `ObtenerSerieDefecto(empresa, tipoDoc [, almacén])`: con almacén,
  prioridad 1) serie propia del almacén, 2) serie genérica (sin
  almacén; nunca la de OTRO almacén). Sin almacén, comportamiento
  histórico intacto (primera serie del tipo).
- `CargarSeriesEmpresa(empresa, tipoDoc, items)`: rellena los combos de
  serie de los modales con las series vigentes.

### Materializar sesión (inMtoComprasSesiones + modal CrearAlbaranSesion)

- Los campos de serie del modal pasan de texto libre a combo editable
  (`TcxComboBox`, estilo lsEditList) con las series `AB` / `PC` de la
  empresa. Se puede seguir tecleando una serie nueva.
- Al elegir almacén destino en el modal se re-propone la serie propia
  de ese almacén en ambos combos; si el almacén no lleva serie, queda
  el default anterior (serie genérica de la empresa o serie de la
  sesión). El usuario puede cambiarla.
- Modo "Un documento por almacén" (formato distribuido): cada
  pedido/albarán generado usa la serie propia de SU almacén; los
  almacenes sin serie propia usan la serie elegida en el modal.

### Albarán desde pedido de compra (inMtoPedidosCompra + modal SelAlmacenPedido)

- El campo de serie pasa a combo editable con las series `AB` de la
  empresa del pedido (el Mto ahora pasa `CODIGO_EMP_PEDC` al modal).
- Al cambiar el almacén destino se re-propone la serie propia del
  almacén; si no la tiene, se mantiene el default histórico (la serie
  del pedido). El usuario puede cambiarla en el combo.

## Ficheros tocados

- `src/Lib/inLibValoresAutomaticos.pas`
- `src/Modals/inMtoModalCrearAlbaranSesion.pas` / `.dfm`
- `src/Modals/inMtoModalSelAlmacenPedido.pas` / `.dfm`
- `src/Forms/inMtoComprasSesiones.pas`
- `src/Forms/inMtoPedidosCompra.pas`

## Ampliación (junio 2026): combos de serie en los Mtos + alta masiva

- Los campos Serie de las cabeceras de **Sesiones de compra**
  (`SERIE_SES`), **Pedidos de compra** (`SERIE_PEDC`) y **Albaranes de
  compra** (`SERIE_ALBC`) pasan de `TcxDBTextEdit` a `TcxDBComboBox`
  editable (`lsEditList`). Al desplegar (`OnInitPopup`) se recargan las
  series vigentes de la empresa por tipo de documento (`SE` / `PC` /
  `AB`) vía `CargarSeriesEmpresa`.
- Si la empresa no tiene ninguna serie del tipo, el combo avisa y
  ofrece abrir el Mto de Empresas (pestaña Series) para crearlas.
- En Empresas → Series hay un botón nuevo **"Crear series doc /
  almacén"** (`btnCrearSeriesDoc`): crea de golpe las series vigentes
  que falten para la empresa activa — una genérica por tipo (`SE1`,
  `PC1`, `AB1`, `DC1`, `FP1`, `IN1`) y una por almacén activo para los
  tipos que proponen serie por almacén (`AB-<ALM>`, `PC-<ALM>`).
  Idempotente; usa el contador `ES` para la PK, igual que el alta
  manual.

Ficheros: `inMtoComprasSesiones.pas/.dfm`, `inMtoPedidosCompra.pas/.dfm`,
`inMtoAlbaranesCompra.pas/.dfm`, `inMtoEmpresas.pas/.dfm`.

## Ampliación (julio 2026): serie por empresa en venta (AV / PE)

Repaso de todos los tipos de documento: compras (`AB`, `PC`, `DC`,
`FP`), sesiones (`SE`) e inventarios (`IN`) ya proponían la serie desde
`fza_empresas_series`; venta mayor no (hardcode 'A1'). Cambios:

- **Albaranes de venta** (`UniDataAlbaranes`): el AfterInsert propone
  `ObtenerSerieDefecto(oEmpresa, 'AV')` con fallback 'A1', y
  `CopiarEmpresaaAlbaran` repropone la serie de la empresa emisora al
  cambiarla (rutas teclado y modal) vía `ProponerSerieEmpresa` — solo
  en documentos nuevos sin numerar.
- **Pedidos de venta** (`UniDataPedidos`): idéntico con tipo `PE`
  (AfterInsert + `CopiarEmpresaaPedido`). El import de PrestaShop deja
  de machacar la serie con 'A1' (la propone el AfterInsert).
- **Facturas de venta** (`FC`): no se tocan; llevan su propio combo de
  series sobre contadores y el flujo Verifactu.

Esto cierra la limitación residual del bug B2 de
`restriccion_usuario_emp_alm_caja_pruebas.md`: con series por empresa
propuestas por defecto, dos empresas no comparten serie y la PK
(NUMERO, SERIE) no colisiona.

## Fuera de alcance

- Albaranes de venta desde pedidos de venta (`fza_albaranes` /
  `fza_pedidos`): la serie la resuelve un procedimiento almacenado
  propio y no se ha tocado.
- Series por defecto al insertar documentos a mano en los Mtos de
  albaranes/pedidos de compra: el almacén aún no se conoce en el
  AfterInsert, se mantiene la serie genérica (el combo permite
  cambiarla después).
