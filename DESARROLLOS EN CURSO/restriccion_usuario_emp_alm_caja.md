# Restricción de consulta por empresa/almacén/caja del usuario

Parámetro que limita al usuario a consultar solo los documentos y
operaciones de su empresa/almacén/caja por defecto (`fza_usuarios`).
Cada pantalla consulta el parámetro antes de entrar y, si procede,
filtra la precarga o la selección de caja.

**No hay cambio de esquema**: el parámetro vive en
`fza_usuarios_perfiles` (formulario `frmMtoAppParam`) y los valores de
empresa/almacén/caja ya existen en `fza_usuarios`
(`EMPRESA_DEFECTO_USU`, `ALMACEN_DEFECTO_USU`, `CAJA_DEFECTO_USU`).

## Parámetro

- **Nombre**: `appRestringirEmpAlmCaja` (booleano, defecto `False`).
- **Categoría**: Seguridad (pantalla Parámetros, `inMtoAppParam`).
- Se asigna por usuario, por grupo o para Todos con el combo de la
  pantalla de Parámetros (jerarquía usuario > grupo > Todos, la de
  `PRC_GETPERFILFORMULARIO`).
- **Solo un administrador puede editarlo** (mismo mecanismo que los
  parámetros Verifactu: `UsuarioPuedeEditarParametro`). Si no, un
  usuario restringido podría quitarse la restricción.
- **Los administradores (`orootGroup = 'S'`) quedan siempre exentos**,
  igual que en `inLibPermisos`, aunque el parámetro esté a True para
  Todos o para su grupo.

## Librería central: `src/Lib/inLibFiltroUsuario.pas`

- `RestriccionEmpAlmCajaActiva`: parámetro activo y usuario no admin.
- `EmpresaRestringida` / `AlmacenRestringido` / `CajaRestringida`:
  devuelven el valor de `fza_usuarios` o `''` si no hay restricción.
  Un defecto vacío no filtra esa dimensión.
- `SqlFiltroEmpAlmCaja(colEmp, colAlm, colCaja)`: fragmento
  `' AND (col = ''valor'' OR col IS NULL)'` por cada dimensión con
  columna y valor. Columna `''` = esa pantalla no tiene esa dimensión.
  El `OR IS NULL` evita excluir documentos sin esa dimensión (p. ej.
  facturas de mayor con `CODIGO_CAJA_FAC` NULL — bug B1 de las pruebas).
- `SqlFiltroDocumento(prefijo, incluirCaja)`: deriva las columnas
  estándar `CODIGO_EMP_*`, `CODIGO_ALM_*` y, solo cuando se solicita,
  `CODIGO_CAJA_*`; lo usan los ocho documentos refactorizados.
- `InyectarFiltroSql(sql, filtro)`: mete el filtro en el WHERE de nivel
  superior de una SELECT (añade `WHERE 1 = 1` si no hay), insertando
  antes del primer GROUP BY / HAVING / ORDER BY / LIMIT de nivel
  superior. Ignora paréntesis de subconsultas y literales de cadena.

## Hook genérico en `TfrmMtoGen` (inMtoGen)

- `SqlRestriccionUsuario: string; virtual` — `''` por defecto; cada Mto
  de documentos lo sobreescribe con sus columnas.
- `AplicarRestriccionUsuario(unqry)` — se llama al principio de
  `AbrirTablaPrincipalAsync` y `AbrirTablaPrincipalSincrono` (todas las
  aperturas de pantalla pasan por ahí vía `ShowMto`). Idempotente: si el
  fragmento ya está en la SQL no toca nada; si la query venía activa del
  DFM streaming la cierra para reabrirla filtrada.

## Pantallas con override de `SqlRestriccionUsuario`

| Pantalla                | Columnas filtradas                                  |
|-------------------------|-----------------------------------------------------|
| Facturas (base/normal)  | `CODIGO_EMP_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC` |
| Albaranes venta         | `CODIGO_EMP_ALB`, `CODIGO_ALM_ALB`                  |
| Pedidos venta           | `CODIGO_EMP_PED`, `CODIGO_ALM_PED`                  |
| Facturas compra         | `CODIGO_EMP_FACC`, `CODIGO_ALM_FACC`                |
| Albaranes compra        | `CODIGO_EMP_ALBC`, `CODIGO_ALM_ALBC`                |
| Pedidos compra          | `CODIGO_EMP_PEDC`, `CODIGO_ALM_PEDC`                |
| Devoluciones compra     | `CODIGO_EMP_DEVC`, `CODIGO_ALM_DEVC`                |
| Sesiones de compra      | `CODIGO_EMP_SES`, `CODIGO_ALM_SES`                  |
| Inventarios             | `CODIGO_EMP_INV`, `CODIGO_ALM_INV`                  |
| Histórico arqueos       | `CODIGO_EMP_ARQ`, `CODIGO_ALM_ARQ`, `CODIGO_CAJA_ARQ` |
| Histórico vales         | `CODIGO_EMP_EMI_VL`, `CODIGO_ALM_EMI_VL`, `CODIGO_CAJA_EMI_VL` (por emisión) |
| Efectos de cobro        | `CODIGO_EMP_EFV` (empresa de la factura origen; mejora M1) |
| Efectos de pago         | `CODIGO_EMP_EFEC` (empresa de la factura origen; mejora M1) |

## Pantallas que recomponen su SQL (filtro en su `ConstruirWhere*`)

Estas pantallas reconstruyen la SQL al cambiar sus filtros de carga
(años/almacenes), así que el filtro va integrado en su builder y no en
el override (el hook genérico lo detecta y no lo duplica):

- **Facturas simplificadas** (`ConstruirWhereFacturas`): FAC + caja.
- **Histórico operaciones caja** (`ConstruirWhereOperaciones`):
  `o.CODIGO_EMP_OPCAJA`, `o.CODIGO_ALM_OPCAJA`, `o.CODIGO_CAJA_OPCAJA`.
- **Histórico pagos caja** (`ConstruirWherePagos`): PAGO emp/alm/caja.
- **Movimientos de almacén** (`ConstruirWhereMovimientos`):
  `m.CODIGO_EMP_MOV`, `m.CODIGO_ALM_MOV`.

En las que tienen combo de almacenes (`CargarAlmacenesFiltro`), el combo
solo ofrece el almacén del usuario cuando la restricción está activa
(filtro sobre `fza_almacenes` por `CODIGO_EMP_ALM` + `CODIGO_ALM_ALM`).
Los contadores (`ContarOperaciones`, `ContarFacturas`...) usan el mismo
`ConstruirWhere*`, así que la barra de progreso cuadra con lo cargado.

## Selección de caja

`TfrmMtoModalCajDef` (selector `vi_cajasdef`, columnas `Empresa` /
`Almacen` / `Caja`) filtra su query en el `FormCreate` — los callers
(menú de caja, modales de impresión de arqueos/operaciones/pagos/
depósitos, mantenimiento de usuarios) abren `qrySeleccion` después del
`Create`, así que todos quedan cubiertos. Con la restricción activa el
selector ofrece una sola fila: la caja del usuario.

El menú de caja (`inMtoCajaMenu`) no necesita cambios: cuando
`vgerShowCajaSelection` es False ya usa `oEmpresa`/`oAlmacen`/`oCaja`
(los defectos del propio usuario), y cuando es True pasa por el
selector filtrado. La consulta de operaciones (F10, `inMtoConsultaOpe`)
hereda el contexto de la caja seleccionada.

## Límites conocidos

- Filtra la **consulta** (precarga de las pantallas). No impide altas:
  los documentos nuevos ya nacen con la empresa/almacén/caja del
  contexto del usuario.
- Pantallas sin dimensión en cabecera (efectos, remesas, depósitos de
  cliente, clientes, artículos...) no se filtran.
- Si un usuario guardó SQL propio del listado en su perfil con
  `oGetSQLFromDB`, el filtro se le inyecta encima al abrir; si el admin
  le cambia después la caja por defecto, conviene resetear ese perfil.

## Pruebas sugeridas

1. Admin: activar `appRestringirEmpAlmCaja` para un grupo (p. ej.
   Vendedores) en Parámetros; comprobar que un usuario del grupo no
   puede editar ese parámetro (solo lectura).
2. Con usuario restringido (defectos 012/GEN/1): abrir Facturas,
   Albaranes, Pedidos, compras, Inventarios, Movimientos e históricos
   de caja y verificar que solo salen filas de su ámbito; el combo de
   almacenes de los filtros de carga solo ofrece GEN.
3. Menú de caja con `vgerShowCajaSelection` = True: el selector solo
   muestra la caja 012/GEN/1.
4. Ctrl+A (búsqueda externa) hacia una factura de otra empresa: no debe
   encontrarla (el filtro también se inyecta en la instancia 1).
5. Admin con el parámetro a True para Todos: sigue viéndolo todo.
