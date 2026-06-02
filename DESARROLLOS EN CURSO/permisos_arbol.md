# Permisos en árbol (pantalla profesional)

Pantalla `inMtoPermisosArbol.TfrmMtoPermisosArbol` que sustituye a la
rejilla simple de permisos como entrada principal del menú. Acompaña a
`permisos_arbol.sql`. Construida sobre el modelo de datos existente
(`fza_permisos`), **sin cambios de esquema**.

## Qué hace

- **Pinta el menú como un árbol.** Recorre el `TMainMenu` real del
  Principal (`jvMnMenuPrin`) y, vía el registro `oFzaWinf`
  (`inLibUnitForm`), mapea cada item de menú a su permiso. Mantiene la
  jerarquía (Archivo, Ventas, Caja…).
- **Controla TODO el menú, no solo lo registrado.** El código de cada
  hoja lo da `TfzaWinF.CodigoMenu`: `menu.<CALL>` si el item está en
  `fza_winforms`, o `menu.<Name>` si no (items que abren su formulario
  directamente sin pasar por `fza_winforms`/`ShowMto`, p.ej. *Parámetros
  de Caja*, las entradas de *Compras*, *Formas de pago* / *Listados* de
  *Ventas Mayor*, *Copias de Seguridad*…). Antes esos items no eran
  parametrizables; ahora sí. La misma regla la usa `AplicarPermisosMenu`,
  así que árbol y runtime quedan sincronizados.
- **Respeta los atajos de teclado.** Al denegar un item,
  `AplicarPermisosMenu` hace `Visible:=False` **y `Enabled:=False`**;
  esto último evita que su `ShortCut` (p.ej. *Ctrl+F5* de Parámetros de
  Caja) siga abriendo el formulario con el menú oculto. Además, un
  submenú se oculta si todas sus hojas quedan denegadas.
- **Añade categorías** para el resto de permisos de `fza_permisos`
  agrupados por prefijo: `accion.*` → *Acciones*, `caja.*` → *Caja
  (TPV)*, `arqueo.*` → *Arqueo*, `menu.*` no visibles → *Menús no
  visibles*, y el resto → *Otros*.
- **Edita por sujeto.** Un combo elige el sujeto (Todos / cada grupo /
  cada usuario). El árbol muestra el valor **efectivo** de cada permiso
  con su origen (Propio / Heredado de grupo / Heredado de Todos / Por
  defecto), resuelto igual que en runtime (`inLibPermisos`).
- **Conceder / denegar / heredar.** Doble clic o barra espaciadora
  alterna la hoja enfocada (crea regla propia `'S'`/`'N'`). Botones
  *Permitir rama* / *Denegar rama* aplican a todas las hojas del nodo;
  *Heredar (rama)* borra las reglas propias para volver a heredar.
- **Transferencia.** Bloque inferior: copia permisos de un sujeto a
  otro, en modo *combinar* (agrega/actualiza) o *reemplazar* (vacía
  antes el destino), con opción *solo permisos de menú*.

## Integración en el menú

`permisos_arbol.sql` repunta la fila `fza_winforms` con `CALL_WINF =
'Permisos'` a la nueva unit (`UNITF_WINF` =
`inMtoPermisosArbol.TfrmMtoPermisosArbol`, `DATAMODULE_WINF` vacío) y
da de alta `CALL_WINF = 'PermisosTabla'` (menú `mnuPermisosTabla`) para
la rejilla clásica `inMtoPermisos`. Así:

- **Otros ▸ Usuarios, Grupos y Perfiles ▸ Permisos** → pantalla de árbol
  (reusa `menu.Permisos`).
- **… ▸ Permisos (tabla)** → rejilla clásica (`menu.PermisosTabla`).

El item `mnuPermisosTabla` y su handler se añaden en `inMtoPrincipal`.

## Detalles técnicos

- Hereda de `TfrmMtoGen` (necesario: `inLibFormManager` castea a
  `TfrmMtoGen` al cerrar la pestaña embebida). Con `DATAMODULE_WINF`
  vacío, la apertura async/síncrona y `btnGrabar` quedan en no-op
  (todos protegen `tdmDataModule = nil`).
- El árbol es un `TcxTreeList` **no ligado** creado en código (columnas
  incluidas) para evitar fragilidad del `.dfm`. La columna *Permitido*
  es un checkbox de solo lectura; la edición pasa siempre por código.
- Lógica de escritura en `inLibPermisosAdmin` (`TPermisosAdmin`):
  `ListarSujetos`, `CatalogoCodigos`, `CargarExplicitos`, `Establecer`
  (upsert), `Heredar` (delete) y `Copiar` (transferencia, en
  transacción).

## Aplicar a una BBDD existente

```sql
SOURCE DESARROLLOS EN CURSO/permisos.sql;
SOURCE DESARROLLOS EN CURSO/permisos_arbol.sql;
```

Idempotente: se puede relanzar sin efectos secundarios. Los cambios de
permisos surten efecto en el **próximo login** del usuario afectado
(la caché `oPermisos` se precarga al entrar), igual que el resto del
subsistema de permisos.
