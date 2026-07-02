# Pruebas: restricción de consulta por empresa/almacén/caja

Ejecutadas el 02/07/2026 sobre `Win32\Debug\fzam.exe`
(1.0.15.202606260100.alpha), BBDD 127.0.0.1:3306 (Factuzam).
Usuarios: `Administrador` (Administradores, admin) y `Alfredo`
(Vendedores, no admin, defectos 012/GEN/1). Datos existentes:
empresas 012, MODAEJ y 1; documentos de 012 y de la empresa 1.

Preparación: `appRestringirEmpAlmCaja = True` para Alfredo y después
para Todos. A Alfredo se le concedieron todos los permisos de menú
(su grupo Vendedores tenía casi todo oculto y no se podían abrir las
pantallas afectadas).

## Resultados

| # | Prueba                                            | Resultado |
|---|---------------------------------------------------|-----------|
| 1 | Parámetro solo editable por admin                 | OK        |
| 2 | Pantallas filtradas con usuario restringido       | OK salvo Facturas (ver B1) |
| 3 | Selector / menú de caja restringido               | OK        |
| 4 | Búsqueda externa Ctrl+A                           | N/A (atajo anulado) |
| 5 | Admin exento con parámetro a True para Todos      | OK        |

Detalle:

- **P1**: como admin el valor se edita con desplegable True/False y se
  guarda ("Se guardaron 1 parámetros para: Alfredo/Todos"). Como
  Alfredo el parámetro se ve en Seguridad pero el editor no se abre
  (solo lectura). OK.
- **P2**: con Alfredo — Albaranes venta: solo el 000001/A1 de 012.
  Albaranes compra: 16 filas, todas 012. Histórico de operaciones,
  arqueos y facturas simplificadas: todo 012/GEN/1. Pedidos venta:
  vacío, correcto porque los 3 pedidos existentes son de la empresa 1
  (como admin sí se ven). Combo "Almacenes" de los filtros de carga:
  solo ofrece "GEN - Almacén Central". OK.
- **P3**: menú de caja (F5) entra directo con "Empresa 012 - Almacén
  GEN - Caja 1"; con "Presentar selección de caja" = True tampoco
  ofrece otras cajas al usuario restringido. OK.
- **P5**: admin con el parámetro a True para Todos sigue viendo
  facturas de 012 y de la empresa 1, y todos los pedidos. OK.

## Bugs / hallazgos

- **B1 — Facturas (venta mayor) vacía para el usuario restringido.**
  Como Alfredo `Ventas Mayor > Borradores` muestra "No hay datos",
  cuando como admin hay muchos borradores de 012. Las simplificadas
  (caja) sí salen. Sospecha: el override FAC filtra también
  `CODIGO_CAJA_FAC = '1'` y las facturas de mayor no llevan caja
  (NULL), con lo que el AND excluye todo. Un defecto de caja no vacío
  no debería filtrar documentos cuya columna caja es NULL, o la
  pantalla de mayor no debería filtrar por caja.
- **B2 — Alta de albarán de venta en otra empresa: clave duplicada.**
  Alta con Empresa Emisora = 1 → MySQL 1062 "Duplicate entry
  '000001-A1' for key 'PRIMARY'". O la PK de albaranes no incluye la
  empresa o el contador no es por empresa. (No relacionado con este
  desarrollo, pero bloquea crear documentos de prueba en otra empresa.)
- **B3 — `PRC_GET_CONTADOR_PEDIDO does not exist`** (MySQL 1305) al
  grabar un pedido nuevo. Falta aplicar algún script a esta BBDD
  (revisar con `comprobar_scripts_aplicados.sql`).
- **M1 — Efectos de cobro** muestran a Alfredo el efecto de la factura
  A1/000030 de la empresa 1. Entra en los "límites conocidos" del .md
  (sin dimensión en cabecera), pero el efecto conoce su empresa vía la
  factura: mejora posible.
- **M2 — UI**: el botón X de "Parámetros Generales" no cierra la
  ventana (hay que doble clic en el icono del sistema); el "Salir" del
  menú de caja necesita doble clic.

## Retest 02/07/2026 (tarde) tras los fixes

Fixes aplicados y recompilados: filtro tolerante a NULL en
`inLibFiltroUsuario` (B1) y contadores de `UniDataPedidos` apuntando a
`PRC_GET_NEXT_CONT_FACT_SERIE` / `PRC_GET_NEXT_CONT` (B3). Verificado
primero en MariaDB aislada (sandbox) y después en la app:

- **B1 CORREGIDO**: como Alfredo, `Ventas Mayor > Borradores` muestra
  los 13 borradores de 012 (antes "No hay datos"); los de la empresa 1
  siguen excluidos. Como admin se ven todos (exención intacta).
- **B3 CORREGIDO**: pedido nuevo de Alfredo (012/A1, cliente 313) se
  graba sin error 1305 y recibe el número 000001 del contador
  (PE, 012, A1) creado al vuelo. Queda en la BBDD como documento de
  prueba. Nota: `PRC_GET_CONTADOR_PEDIDO` no existía en ningún dump;
  no era un script sin aplicar sino una referencia huérfana del DFM.
- **B2 RESUELTO vía series por empresa** (desarrollo
  `series_por_almacen.md`, ya en el ejecutable): el combo Serie del
  alta carga las series AV/PE de la empresa emisora y, si no tiene,
  ofrece crearlas (Empresas > Series > "Añadir serie a todos").
  Probado: creadas 46 series AG1 para la empresa 1 y grabado el
  albarán 000001/AG1 (cliente 302) sin el 1062 — contador (AV, 1, AG1)
  propio, sin colisión con 000001/A1 de 012. **Limitación residual**:
  el AfterInsert sigue proponiendo 'A1' y al cambiar la empresa emisora
  no se repropone la serie; si el usuario deja 'A1' con otra empresa,
  el 1062 sigue siendo posible. Mejora sugerida: reproponer con
  `ObtenerSerieDefecto(empresa, 'AV'/'PE')` en BuscarEmpresa.
- **M1 implementado** (pendiente recompilar y probar): override de
  `SqlRestriccionUsuario` en efectos de venta (`CODIGO_EMP_EFV`) y de
  compra (`CODIGO_EMP_EFEC`). `PRC_EFV_GENERAR_DESDE_FACTURA` rellena
  la empresa al emitir, así que el efecto A1/000030 quedará oculto.
- **M2 parcial**: quitado el `Action := caFree` de
  `TfrmMtoAppParam.FormClose` (form modal liberado por el caller;
  el caFree provocaba Release + FreeAndNil dobles). Pendiente retest
  del botón X. El doble clic del "Salir" del menú de caja no se
  reproduce en estático: depurar en runtime.

## Estado en que queda la BBDD de pruebas

- `appRestringirEmpAlmCaja` = True para Alfredo y para Todos.
- Alfredo con todos los permisos de menú concedidos.
- "Presentar selección de caja" = True para Alfredo.
- Sesión de la app como Administrador. No se creó ningún documento
  (las dos altas fallaron y se cancelaron; un par de operaciones TPV
  se abrieron y cerraron vacías sin cobrar).
